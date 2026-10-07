# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Null calibration from a seeded ensemble (STATISTICS.md §1, §2, §4, §6).

    python3 -m compare.calibrate --ensemble ID_OR_PREFIX [ID_OR_PREFIX ...] \\
        [--exclude ID ...] [--leave-out ID] --out DIR [--jobs N] [--mde FILEGLOB::BLOCKGLOB ...]
    python3 -m compare.calibrate --mde-from DIR --mde FILEGLOB::BLOCKGLOB ... [--candidate-runs M]

``--ensemble`` takes capture ids (or run directories) and/or a prefix such as
``m2-ens-m1-rn215-short``, which selects every stored capture ``<prefix>-s<seed>``.
``--exclude`` / ``--leave-out`` drop members (gate G3 calibrates on K - 1 and judges the one left
out); they are recorded in the manifest.

Artifact layout (a directory, storable with ``harness.store add DIR --id ID --kind calibration``):

``manifest.json``
    ``kind: "calibration"``, ensemble member ids, excluded ids, the common input sha256, code
    version (git revision), K, alpha, the family count and the number of families with numeric
    fields (``stat_families``, the Holm F), the pooled local nulls of the families without a
    global test per file kind (``local_pool``), the typical variance floor of each label
    (``label_floor_pool``), parameters, and the index ``files: {run-relative path: {idx,
    families}}``.
``diagnostics.json`` / ``diagnostics.txt``
    Field-class counts, count-like and degenerate families, families with large phi.
``files/<idx>.npz``
    One per source file: the union key layout (``extract.write_layout_npz``) and, per numeric field,
    ``cls`` / ``mean`` / ``v`` (class, ensemble mean or deterministic value, variance model),
    per label ``lfloor`` (variance floor of fields not seen nonzero), ``lquantum`` / ``lfano`` /
    ``lpsi`` (event quantum, phi / q and quadratic dispersion of discrete count columns),
    per text key ``tcls`` (0 deterministic, 1 stochastic) and ``tvals`` (JSON list, the value of
    deterministic text), per family ``fparams`` (columns ``PARAM_COLS``), ``nruns`` (runs that
    had the family) and the K leave-one-out draws ``loo_d`` / ``loo_m``.
``mde/``
    Minimum detectable effects (§6) of the selected families: ``index.json`` and
    ``<k>.npz``.

Families are processed file by file in worker processes (``--jobs``, default 4 at most), each
reading the K extracts of that file only.
"""

from __future__ import annotations

import argparse
import dataclasses
import fnmatch
import json
import re
import subprocess
import sys
import time
from collections import Counter
from collections.abc import Callable, Sequence
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
from numpy.typing import NDArray

from compare.extract import (
    DEFAULT_CACHE,
    PAD,
    FamilyData,
    FileLayout,
    RunExtract,
    align_numeric,
    build_layout,
    load_extract,
    read_layout_npz,
    resolve_run,
    text_map,
    write_layout_npz,
)
from compare.stats import (
    ALPHA,
    CLS_DET,
    CLS_IGN,
    CLS_STOCH,
    CLS_ZERO,
    COUNT_LIKE_MIN_FIELDS,
    DERIVED_LABELS,
    UNTESTED_KINDS,
    LocalNull,
    NullParams,
    critical_z,
    file_kind,
    fit_family,
    local_null,
    mde_values,
)
from harness.common import REPO_ROOT, STORE_CAPTURES

__all__ = [
    "PARAM_COLS",
    "SCHEMA",
    "CalFamily",
    "CalFile",
    "Calibration",
    "MdeResult",
    "calibrate",
    "main",
    "resolve_ensemble",
]

SCHEMA = 1
DEFAULT_MDE = ("work/dmp/*/Apost.dmp::APOST", "work/ENDF/*::MF8/MT454")
MAX_JOBS = 4
MIN_POOL_DRAWS = 500  # z values needed to pool the families without a global test

PARAM_COLS: tuple[str, ...] = (
    "n_stoch", "count_like", "phi", "vfloor", "n_draws", "d_mean", "d_var", "a", "nu",
    "kappa2", "nu_local", "degenerate", "z2_sum", "z4_sum", "z2_count", "n_empirical",
    "mode_var", "psi", "mode_dof", "n_sparse", "od_num", "od_den",
    "n_zero", "n_det", "n_ign", "n_tdet", "n_tstoch", "n_numeric",
)  # fmt: skip
_COL = {name: i for i, name in enumerate(PARAM_COLS)}
_NULL_COLS = tuple(f.name for f in dataclasses.fields(NullParams))

type FloatArray = NDArray[np.float64]


def null_from_row(row: FloatArray) -> NullParams:
    """The ``NullParams`` stored in one ``fparams`` row."""
    return NullParams(
        n_stoch=int(row[_COL["n_stoch"]]),
        count_like=bool(row[_COL["count_like"]]),
        phi=float(row[_COL["phi"]]),
        vfloor=float(row[_COL["vfloor"]]),
        n_draws=int(row[_COL["n_draws"]]),
        d_mean=float(row[_COL["d_mean"]]),
        d_var=float(row[_COL["d_var"]]),
        a=float(row[_COL["a"]]),
        nu=float(row[_COL["nu"]]),
        kappa2=float(row[_COL["kappa2"]]),
        nu_local=float(row[_COL["nu_local"]]),
        degenerate=bool(row[_COL["degenerate"]]),
        z2_sum=float(row[_COL["z2_sum"]]),
        z4_sum=float(row[_COL["z4_sum"]]),
        z2_count=int(row[_COL["z2_count"]]),
        n_empirical=int(row[_COL["n_empirical"]]),
        mode_var=float(row[_COL["mode_var"]]),
        psi=float(row[_COL["psi"]]),
        mode_dof=float(row[_COL["mode_dof"]]),
        n_sparse=int(row[_COL["n_sparse"]]),
        od_num=float(row[_COL["od_num"]]),
        od_den=float(row[_COL["od_den"]]),
    )


# --------------------------------------------------------------------------------------------
# Reading a calibration
# --------------------------------------------------------------------------------------------


@dataclass
class CalFamily:
    """One calibrated family."""

    rel: str
    block: str
    group: str
    labels: tuple[str, ...]
    kmat: NDArray[np.int64]
    cls: NDArray[np.int8]
    mean: FloatArray
    v: FloatArray
    label_floor: FloatArray
    label_quantum: FloatArray
    label_fano: FloatArray
    label_psi: FloatArray
    mode: FloatArray
    tlabels: tuple[str, ...]
    tkmat: NDArray[np.int64]
    tcls: NDArray[np.int8]
    tvals: list[str]
    null: NullParams
    n_runs: int
    loo_d: FloatArray
    loo_m: FloatArray


class CalFile:
    """One source file of a calibration artifact."""

    def __init__(self, rel: str, layout: FileLayout, extra: dict[str, Any]) -> None:
        self.rel = rel
        self.layout = layout
        self.extra = extra
        self.tvals: list[str] = json.loads(str(extra["tvals"]))
        self._noff = np.concatenate([[0], np.cumsum([f.n for f in layout.families])])
        self._loff = np.concatenate([[0], np.cumsum([len(f.labels) for f in layout.families])])
        self._toff = np.concatenate([[0], np.cumsum([f.nt for f in layout.families])])

    @property
    def families(self) -> list[tuple[str, str]]:
        return [(f.block, f.group) for f in self.layout.families]

    def family(self, block: str, group: str) -> CalFamily | None:
        i = self.layout.index.get((block, group))
        if i is None:
            return None
        f = self.layout.families[i]
        n0, n1 = int(self._noff[i]), int(self._noff[i + 1])
        t0, t1 = int(self._toff[i]), int(self._toff[i + 1])
        l0, l1 = int(self._loff[i]), int(self._loff[i + 1])
        e = self.extra
        return CalFamily(
            self.rel,
            block,
            group,
            f.labels,
            self.layout.kmat[f.kpos : f.kpos + f.n * (1 + f.width)].reshape(f.n, 1 + f.width),
            e["cls"][n0:n1],
            e["mean"][n0:n1],
            e["v"][n0:n1],
            e["lfloor"][l0:l1],
            e["lquantum"][l0:l1],
            e["lfano"][l0:l1],
            e["lpsi"][l0:l1],
            e["mode"][n0:n1],
            f.tlabels,
            self.layout.tkmat[f.tkpos : f.tkpos + f.nt * (1 + f.twidth)].reshape(
                f.nt, 1 + f.twidth
            ),
            e["tcls"][t0:t1],
            self.tvals[t0:t1],
            null_from_row(e["fparams"][i]),
            int(e["nruns"][i]),
            e["loo_d"][i],
            e["loo_m"][i],
        )


class Calibration:
    """An opened calibration artifact."""

    def __init__(self, root: Path, manifest: dict[str, Any]) -> None:
        self.root = root
        self.manifest = manifest
        self._files: dict[str, CalFile] = {}

    @classmethod
    def open(cls, spec: str | Path) -> Calibration:
        """Open a calibration directory, or a ``calibration`` capture id of the store."""
        root = Path(spec)
        if not (root / "manifest.json").is_file():
            root = STORE_CAPTURES / str(spec)
        manifest = json.loads((root / "manifest.json").read_text())
        if manifest.get("kind") != "calibration" or manifest.get("schema") != SCHEMA:
            raise ValueError(f"{root} is not a calibration artifact (schema {SCHEMA})")
        return cls(root, manifest)

    @property
    def runs(self) -> int:
        return int(self.manifest["runs"])

    @property
    def alpha(self) -> float:
        return float(self.manifest["alpha"])

    @property
    def stat_families(self) -> int:
        return int(self.manifest["stat_families"])

    @property
    def input_sha256(self) -> str | None:
        return self.manifest.get("input_sha256")

    @property
    def rels(self) -> list[str]:
        return sorted(self.manifest["files"])

    def local_pool(self, kind: str) -> LocalNull:
        """Pooled local null of a file kind (for degenerate families); ``*`` is all kinds."""
        pool: dict[str, dict[str, float | None]] = self.manifest["local_pool"]
        entry = pool.get(kind, pool["*"])
        nu = entry["nu"]
        return LocalNull(float(entry["kappa2"] or 1.0), float("inf") if nu is None else float(nu))

    def clustering(self, kind: str) -> float:
        """Clustering of low-count events in a file kind (1: Poisson), from the ensemble."""
        pool: dict[str, float] = self.manifest.get("clustering", {})
        return float(pool.get(kind, pool.get("*", 1.0)))

    def label_floor_pool(self, kind: str, label: str) -> float:
        """Typical variance floor of a label over the calibration (NaN if unknown)."""
        pool: dict[str, dict[str, float]] = self.manifest.get("label_floor_pool", {})
        return pool.get(kind, {}).get(label, float("nan"))

    def file(self, rel: str) -> CalFile | None:
        hit = self._files.get(rel)
        if hit is not None:
            return hit
        entry = self.manifest["files"].get(rel)
        if entry is None:
            return None
        layout, extra = read_layout_npz(self.root / "files" / f"{entry['idx']}.npz")
        cal = CalFile(rel, layout, extra)
        self._files = {rel: cal}  # keep one file: calibrations of full runs are large
        return cal

    def local_of(self, fam: CalFamily) -> LocalNull:
        """The local null of a family: its own fit, or the pool of its file kind."""
        if fam.null.degenerate:
            return self.local_pool(file_kind(fam.rel))
        return LocalNull(fam.null.kappa2, fam.null.nu_local)

    def mde(self, fam: CalFamily, candidate_runs: int = 1) -> MdeResult:
        """§6: the minimum detectable single-field shift of a family, for every field."""
        return mde_of_family(self, fam, candidate_runs)


@dataclass
class MdeResult:
    """Minimum detectable effect of every numeric field of one family."""

    rel: str
    block: str
    group: str
    labels: tuple[str, ...]
    kmat: NDArray[np.int64]
    mean: FloatArray
    absolute: FloatArray  # 0 for deterministic fields (any difference fails)
    relative: FloatArray  # NaN where the mean is 0
    t_star: float
    kappa2: float
    nu: float  # Student dof of the local tail (inf: Gaussian)
    n_fields: int
    candidate_runs: int


def mde_of_family(cal: Calibration, fam: CalFamily, candidate_runs: int) -> MdeResult:
    """MDE of a family (§6), with the Holm first step ``alpha / F`` for F statistical families."""
    local = cal.local_of(fam)
    n = fam.null.n_stoch
    t_star = critical_z(cal.alpha / max(cal.stat_families, 1), n, local)
    stat = (fam.cls == CLS_STOCH) | (fam.cls == CLS_ZERO)
    absolute = np.zeros(len(fam.mean))
    relative = np.zeros(len(fam.mean))
    if n and stat.any():
        a, r = mde_values(fam.v[stat], fam.mean[stat], cal.runs, candidate_runs, t_star)
        absolute[stat] = a
        relative[stat] = r
    ign = fam.cls == CLS_IGN
    absolute[ign] = np.nan
    relative[ign] = np.nan
    return MdeResult(
        fam.rel, fam.block, fam.group, fam.labels, fam.kmat, fam.mean, absolute, relative,
        t_star, local.kappa2, local.nu, n, candidate_runs,
    )  # fmt: skip


# --------------------------------------------------------------------------------------------
# Ensemble resolution
# --------------------------------------------------------------------------------------------


def resolve_ensemble(specs: Sequence[str], excluded: Sequence[str] = ()) -> list[str]:
    """Expand capture ids, run directories and prefixes into an ordered member list.

    A spec that is an existing directory or capture id is one member; otherwise it is a prefix
    selecting the captures named ``<prefix>-s<digits>``, sorted by seed.
    """
    members: list[str] = []
    for spec in specs:
        if Path(spec).is_dir() or (STORE_CAPTURES / spec).is_dir():
            members.append(spec)
            continue
        pattern = re.compile(re.escape(spec) + r"-s(\d+)$")
        found = sorted(
            (int(m.group(1)), p.name)
            for p in STORE_CAPTURES.iterdir()
            if (m := pattern.match(p.name))
        )
        if not found:
            raise FileNotFoundError(f"no capture or prefix matches {spec!r}")
        members.extend(name for _, name in found)
    drop = set(excluded)
    unknown = drop - set(members)
    if unknown:
        raise ValueError(f"excluded ids are not ensemble members: {sorted(unknown)}")
    kept = [m for m in dict.fromkeys(members) if m not in drop]
    return kept


# --------------------------------------------------------------------------------------------
# Calibration of one file (worker)
# --------------------------------------------------------------------------------------------


_EXTRACTS: dict[str, RunExtract] = {}


def _extract(root: str) -> RunExtract:
    ex = _EXTRACTS.get(root)
    if ex is None:
        ex = _EXTRACTS[root] = RunExtract.open(Path(root))
    return ex


def _fit_text(
    fds: Sequence[FamilyData | None],
) -> tuple[tuple[str, ...], NDArray[np.int64], NDArray[np.int8], list[str]]:
    """Union text keys of the runs with their class (0 deterministic, 1 stochastic) and value."""
    maps: list[dict[tuple[str, tuple[int, ...]], str]] = [
        text_map(f.tlabels, f.tkmat, f.tvals) if f is not None else {} for f in fds
    ]
    keys = sorted(set[tuple[str, tuple[int, ...]]]().union(*maps))
    labels = tuple(sorted({k[0] for k in keys}))
    lid = {name: i for i, name in enumerate(labels)}
    width = max((len(k[1]) for k in keys), default=0)
    kmat = np.full((len(keys), 1 + width), PAD, dtype=np.int64)
    tcls = np.ones(len(keys), dtype=np.int8)
    tvals: list[str] = []
    for r, (label, index) in enumerate(keys):
        kmat[r, 0] = lid[label]
        kmat[r, 1 : 1 + len(index)] = index
        values = [m.get((label, index)) for m in maps]
        first = values[0]
        if first is not None and all(v == first for v in values):
            tcls[r] = 0
            tvals.append(first)
        else:
            tvals.append("")
    return labels, kmat, tcls, tvals


type FileResult = tuple[str, int, FloatArray, list[tuple[str, str]], dict[str, float]]


def _calibrate_file(job: tuple[str, int, list[str], str]) -> FileResult:
    rel, idx, roots, out_dir = job
    datas = [_extract(r).file(rel) for r in roots]
    keys = sorted({k for d in datas if d is not None for k in d.layout.index})
    derived_set = DERIVED_LABELS.get(file_kind(rel), frozenset())
    specs: list[tuple[str, str, tuple[str, ...], int, int, tuple[str, ...], int, int]] = []
    kparts: list[NDArray[np.int64]] = []
    tkparts: list[NDArray[np.int64]] = []
    cls_parts: list[NDArray[np.int8]] = []
    mean_parts: list[FloatArray] = []
    v_parts: list[FloatArray] = []
    lfloor_parts: list[FloatArray] = []
    lquantum_parts: list[FloatArray] = []
    lfano_parts: list[FloatArray] = []
    lpsi_parts: list[FloatArray] = []
    mode_parts: list[FloatArray] = []
    tcls_parts: list[NDArray[np.int8]] = []
    tvals: list[str] = []
    rows: list[FloatArray] = []
    nruns: list[int] = []
    loo_d: list[FloatArray] = []
    loo_m: list[FloatArray] = []
    floors: dict[str, list[float]] = {}
    hints: dict[str, list[float]] = {}  # label -> quanta of the families done so far
    done: dict[tuple[str, str], tuple[Any, ...]] = {}

    def size(key: tuple[str, str]) -> int:
        return max(
            d.layout.families[d.layout.index[key]].n
            for d in datas
            if d is not None and key in d.layout.index
        )

    for block, group in sorted(keys, key=lambda k: (-size(k), k)):  # big families first
        fds = [d.get(block, group) if d is not None else None for d in datas]
        parts = [
            (f.labels, f.kmat, f.vals)
            if f is not None
            else ((), np.zeros((0, 1), np.int64), np.zeros(0))
            for f in fds
        ]
        aligned = align_numeric(parts)
        derived = np.array([name in derived_set for name in aligned.labels], dtype=bool)
        fit = fit_family(
            aligned.vals,
            aligned.present,
            aligned.kmat[:, 0].copy(),
            len(aligned.labels),
            derived[aligned.kmat[:, 0]],
            untested=file_kind(rel) in UNTESTED_KINDS,
            quantum_hint=np.array(
                [
                    float(np.median(hints[name])) if name in hints else np.nan
                    for name in aligned.labels
                ]
            ),
        )
        for g in np.flatnonzero(np.isfinite(fit.label_quantum)).tolist():
            hints.setdefault(aligned.labels[g], []).append(float(fit.label_quantum[g]))
        tlabels, tkmat, tcls, tv = _fit_text(fds)
        done[block, group] = (aligned, fit, tlabels, tkmat, tcls, tv, fds)
    for block, group in keys:
        aligned, fit, tlabels, tkmat, tcls, tv, fds = done[block, group]
        tdet = int((tcls == 0).sum())
        cls = fit.cls
        nu = fit.null
        specs.append(
            (block, group, aligned.labels, len(aligned.kmat), aligned.kmat.shape[1] - 1,
             tlabels, len(tkmat), tkmat.shape[1] - 1)
        )  # fmt: skip
        kparts.append(aligned.kmat.ravel())
        tkparts.append(tkmat.ravel())
        cls_parts.append(cls)
        mean_parts.append(fit.mean)
        v_parts.append(fit.v)
        lfloor_parts.append(fit.label_floor)
        lquantum_parts.append(fit.label_quantum)
        lfano_parts.append(fit.label_fano)
        lpsi_parts.append(fit.label_psi)
        mode_parts.append(fit.mode)
        for g in map(int, np.unique(aligned.kmat[cls == CLS_STOCH, 0]).tolist()):
            if np.isfinite(fit.label_floor[g]):
                floors.setdefault(aligned.labels[g], []).append(float(fit.label_floor[g]))
        tcls_parts.append(tcls)
        tvals.extend(tv)
        nruns.append(sum(f is not None for f in fds))
        loo_d.append(fit.loo_d)
        loo_m.append(fit.loo_m)
        rows.append(_param_row(nu, cls, tdet, len(tcls) - tdet, len(aligned.kmat)))
    layout = build_layout(specs, _cat(kparts, np.int64), _cat(tkparts, np.int64))
    fparams = np.array(rows).reshape(len(rows), len(PARAM_COLS))
    extra: dict[str, Any] = {
        "cls": _cat(cls_parts, np.int8),
        "mean": _cat(mean_parts, np.float64),
        "v": _cat(v_parts, np.float64),
        "lfloor": _cat(lfloor_parts, np.float64),
        "lquantum": _cat(lquantum_parts, np.float64),
        "lfano": _cat(lfano_parts, np.float64),
        "lpsi": _cat(lpsi_parts, np.float64),
        "mode": _cat(mode_parts, np.float64),
        "tcls": _cat(tcls_parts, np.int8),
        "tvals": np.array(json.dumps(tvals)),
        "fparams": fparams,
        "nruns": np.array(nruns, dtype=np.int64),
        "loo_d": np.array(loo_d).reshape(len(loo_d), len(roots)),
        "loo_m": np.array(loo_m).reshape(len(loo_m), len(roots)),
    }
    write_layout_npz(Path(out_dir) / "files" / f"{idx}.npz", layout, extra)
    return rel, idx, fparams, keys, {k: float(np.median(v)) for k, v in floors.items()}


def _param_row(
    nu: NullParams, cls: NDArray[np.int8], n_tdet: int, n_tstoch: int, n_numeric: int
) -> FloatArray:
    """The ``fparams`` row (columns ``PARAM_COLS``) of one family."""
    values: dict[str, float] = {
        **{name: float(getattr(nu, name)) for name in _NULL_COLS},
        "n_zero": float((cls == CLS_ZERO).sum()),
        "n_det": float((cls == CLS_DET).sum()),
        "n_ign": float((cls == CLS_IGN).sum()),
        "n_tdet": float(n_tdet),
        "n_tstoch": float(n_tstoch),
        "n_numeric": float(n_numeric),
    }
    return np.array([values[name] for name in PARAM_COLS])


def _cat(parts: list[Any], dtype: Any) -> Any:
    return np.concatenate(parts).astype(dtype, copy=False) if parts else np.zeros(0, dtype=dtype)


# --------------------------------------------------------------------------------------------
# Calibration
# --------------------------------------------------------------------------------------------


def _quiet(_message: str) -> None:
    return None


def _stderr(message: str) -> None:
    print(message, file=sys.stderr)


def _git_version() -> dict[str, Any]:
    def run(*args: str) -> str:
        return subprocess.run(
            ["git", *args], cwd=REPO_ROOT, capture_output=True, text=True, check=True
        ).stdout.strip()

    try:
        return {
            "rev": run("rev-parse", "HEAD"),
            "dirty": bool(run("status", "--porcelain", "--", "compare")),
        }
    except OSError, subprocess.CalledProcessError:
        return {"rev": "unknown", "dirty": True}


def calibrate(
    members: Sequence[str],
    out: Path,
    *,
    excluded: Sequence[str] = (),
    cache: Path = DEFAULT_CACHE,
    jobs: int = MAX_JOBS,
    mde: Sequence[str] = DEFAULT_MDE,
    alpha: float = ALPHA,
    input_sha256: str | None = None,
    log: Callable[[str], None] | None = None,
) -> dict[str, Any]:
    """Calibrate on ``members`` and write the artifact to ``out``; returns the manifest."""
    say: Callable[[str], None] = log or _quiet
    if len(members) < 4:
        raise ValueError(f"a calibration needs at least 4 ensemble runs, got {len(members)}")
    start = time.perf_counter()
    jobs = max(1, min(jobs, MAX_JOBS))
    todo = [str(Path(m) if Path(m).is_dir() else resolve_run(m)) for m in members]
    if jobs > 1:
        with ProcessPoolExecutor(max_workers=jobs) as pool:
            extracts = list(pool.map(_extract_job, [(t, str(cache)) for t in todo]))
    else:
        extracts = [_extract_job((t, str(cache))) for t in todo]
    shas = {e.input_sha256 for e in extracts}
    if input_sha256 is not None:
        shas.discard(None)
        shas.add(input_sha256)
    if len(shas) != 1 or None in shas:
        raise ValueError(
            "ensemble members must all have the same known input sha256, found "
            f"{sorted(map(str, shas))}; pass --input-sha256 for runs without run.json"
        )
    (sha,) = shas
    assert sha is not None
    t_extract = time.perf_counter() - start
    say(f"extracted {len(extracts)} runs in {t_extract:.1f} s")
    rels = sorted({rel for e in extracts for rel in e.rels})
    out.mkdir(parents=True, exist_ok=True)
    (out / "files").mkdir(exist_ok=True)
    roots = [str(e.root) for e in extracts]
    work = [(rel, i, roots, str(out)) for i, rel in enumerate(rels)]
    results: list[FileResult]
    if jobs > 1:
        with ProcessPoolExecutor(max_workers=jobs) as pool:
            results = list(pool.map(_calibrate_file, work, chunksize=4))
    else:
        results = [_calibrate_file(w) for w in work]
    t_fit = time.perf_counter() - start - t_extract
    say(f"fitted {sum(len(r[3]) for r in results)} families in {t_fit:.1f} s")
    manifest = _finish(
        out,
        members,
        excluded,
        extracts,
        sha,
        results,
        alpha,
        {"extract_s": t_extract, "fit_s": t_fit},
    )
    if mde:
        write_mde(Calibration.open(out), mde, 1)
    manifest["mde_selectors"] = list(mde)
    _write_json(out / "manifest.json", manifest)
    say(f"done in {time.perf_counter() - start:.1f} s")
    return manifest


def _extract_job(job: tuple[str, str]) -> RunExtract:
    return load_extract(job[0], Path(job[1]))


def _write_json(path: Path, data: object) -> None:
    path.write_text(json.dumps(data, indent=1, sort_keys=True) + "\n")


def _finish(
    out: Path,
    members: Sequence[str],
    excluded: Sequence[str],
    extracts: Sequence[RunExtract],
    input_sha: str,
    results: list[FileResult],
    alpha: float,
    timing: dict[str, float],
) -> dict[str, Any]:
    """Pooled kappa^2, diagnostics and the manifest."""
    kappa_by_kind: dict[str, list[float]] = {}
    nu_by_kind: dict[str, list[float]] = {}
    deg_sums: dict[str, list[float]] = {}  # z2, z4, count, empirical fields, stochastic fields
    n_fam = n_stat = 0
    fields: Counter[str] = Counter()
    per_kind: dict[str, Counter[str]] = {}
    listing: list[tuple[float, str, str, str, int]] = []
    degenerate: list[tuple[str, str, str, int]] = []
    kappas: list[tuple[float, str, str, str, int]] = []
    col = _COL
    for rel, _idx, fp, keys, _floors in results:
        kind = file_kind(rel)
        pk = per_kind.setdefault(kind, Counter())
        for row, (block, group) in zip(fp, keys, strict=True):
            n_fam += 1
            pk["families"] += 1
            nst = int(row[col["n_stoch"]])
            if row[col["z2_count"]]:
                empirical = 2 * row[col["n_empirical"]] > row[col["n_stoch"]]
                own = local_null(
                    float(row[col["z2_sum"]]),
                    float(row[col["z4_sum"]]),
                    int(row[col["z2_count"]]),
                    float(len(members) - 2) if empirical else float("inf"),
                )
                kappa_by_kind.setdefault(kind, []).append(own.kappa2)
                nu_by_kind.setdefault(kind, []).append(own.nu)
                if row[col["degenerate"]]:
                    for key in (kind, "*"):
                        acc = deg_sums.setdefault(key, [0.0, 0.0, 0.0, 0.0, 0.0])
                        acc[0] += float(row[col["z2_sum"]])
                        acc[1] += float(row[col["z4_sum"]])
                        acc[2] += float(row[col["z2_count"]])
                        acc[3] += float(row[col["n_empirical"]])
                        acc[4] += float(row[col["n_stoch"]])
            for name in ("n_stoch", "n_zero", "n_det", "n_ign", "n_tdet", "n_tstoch"):
                fields[name] += int(row[col[name]])
                pk[name] += int(row[col[name]])
            if row[col["n_numeric"]]:
                n_stat += 1
            if nst:
                pk["statistical"] += 1
                if row[col["count_like"]]:
                    pk["count_like"] += 1
                    listing.append((float(row[col["phi"]]), rel, block, group, nst))
                if row[col["degenerate"]]:
                    pk["degenerate"] += 1
                    degenerate.append((rel, block, group, nst))
                else:
                    kappas.append((float(row[col["kappa2"]]), rel, block, group, nst))
            else:
                pk["deterministic_only"] += 1
    pool = {k: float(np.median(v)) for k, v in kappa_by_kind.items()}
    every = [x for v in kappa_by_kind.values() for x in v]
    pool["*"] = float(np.median(every)) if every else 1.0
    nu_pool = {k: float(np.median(v)) for k, v in nu_by_kind.items()}
    every_nu = [x for v in nu_by_kind.values() for x in v]
    nu_pool["*"] = float(np.median(every_nu)) if every_nu else float("inf")
    local_pool: dict[str, dict[str, float | None]] = {}
    for k in pool:
        z2, z4, cnt, emp, stoch_n = deg_sums.get(k, [0.0, 0.0, 0.0, 0.0, 0.0])
        if cnt >= MIN_POOL_DRAWS:  # families without a global test are pooled among themselves
            cap = float(len(members) - 2) if 2 * emp > stoch_n else float("inf")
            fitted = local_null(z2, z4, int(cnt), cap)
            kappa2, nu = fitted.kappa2, fitted.nu
        else:
            kappa2, nu = pool[k], nu_pool[k]
        local_pool[k] = {"kappa2": kappa2, "nu": None if np.isinf(nu) else nu}
    listing.sort(reverse=True)
    kappas.sort(reverse=True)
    low_kappas = sorted(kappas)[:20]
    diagnostics = {
        "families": n_fam,
        "statistical_families": n_stat,
        "fields": dict(fields),
        "per_kind": {k: dict(v) for k, v in sorted(per_kind.items())},
        "kappa2_pool": pool,
        "largest_phi": [
            {"phi": p, "file": r, "block": b, "group": g, "n_stoch": n}
            for p, r, b, g, n in listing[:50]
        ],
        "phi_quantiles": _quantiles([p for p, *_ in listing]),
        "highest_kappa2": [
            {"kappa2": k, "file": r, "block": b, "group": g, "n_stoch": n}
            for k, r, b, g, n in kappas[:20]
        ],
        "lowest_kappa2": [
            {"kappa2": k, "file": r, "block": b, "group": g, "n_stoch": n}
            for k, r, b, g, n in low_kappas
        ],
        "degenerate_count": len(degenerate),
        "degenerate_sample": [
            {"file": r, "block": b, "group": g, "n_stoch": n} for r, b, g, n in degenerate[:50]
        ],
        "deterministic_fields_must_match": int(fields["n_det"]),
    }
    _write_json(out / "diagnostics.json", diagnostics)
    (out / "diagnostics.txt").write_text(_diagnostics_text(diagnostics))
    manifest: dict[str, Any] = {
        "schema": SCHEMA,
        "kind": "calibration",
        "ensemble": list(members),
        "excluded": list(excluded),
        "runs": len(members),
        "input_sha256": input_sha,
        "extract_fingerprints": [e.manifest.get("fingerprint") for e in extracts],
        "code": _git_version(),
        "alpha": alpha,
        "families": n_fam,
        "stat_families": n_stat,
        "parameters": {
            "count_like_min_fields": COUNT_LIKE_MIN_FIELDS,
            "variance": "count-like: phi*mean, phi=median(s2/mean); else s2; floored",
            "null": "scaled chi2 moment matching on leave-one-out D; Sidak local with kappa2",
            "param_cols": list(PARAM_COLS),
        },
        "kappa2_pool": pool,
        "local_pool": local_pool,
        "clustering": _clustering(results),
        "timing_s": {k: round(v, 2) for k, v in timing.items()},
        "label_floor_pool": _pool_floors(results),
        "files": {rel: {"idx": idx, "families": len(keys)} for rel, idx, _, keys, _ in results},
    }
    _write_json(out / "manifest.json", manifest)
    return manifest


def _clustering(results: list[FileResult]) -> dict[str, float]:
    """Per file kind: squared deviations of the low-count fields over their Poisson expectation."""
    sums: dict[str, list[float]] = {}
    for rel, _, fp, _, _ in results:
        for key in (file_kind(rel), "*"):
            acc = sums.setdefault(key, [0.0, 0.0])
            acc[0] += float(fp[:, _COL["od_num"]].sum())
            acc[1] += float(fp[:, _COL["od_den"]].sum())
    return {k: max(1.0, num / den) for k, (num, den) in sums.items() if den > 0.0}


def _pool_floors(results: list[FileResult]) -> dict[str, dict[str, float]]:
    """Per file kind and label: the median over files of the family-median variance floor."""
    by_kind: dict[str, dict[str, list[float]]] = {}
    for rel, _, _, _, floors in results:
        slot = by_kind.setdefault(file_kind(rel), {})
        for label, value in floors.items():
            slot.setdefault(label, []).append(value)
    return {
        kind: {label: float(np.median(v)) for label, v in sorted(labels.items())}
        for kind, labels in sorted(by_kind.items())
    }


def _quantiles(values: list[float]) -> dict[str, float]:
    if not values:
        return {}
    arr = np.array(values)
    return {f"q{q}": float(np.quantile(arr, q / 100)) for q in (0, 10, 50, 90, 99, 100)}


def _diagnostics_text(d: dict[str, Any]) -> str:
    lines = [
        f"families: {d['families']}  statistical: {d['statistical_families']}",
        f"fields: {d['fields']}",
        f"degenerate families: {d['degenerate_count']}",
        f"phi quantiles (count-like families): {d['phi_quantiles']}",
        f"kappa2 pool: {d['kappa2_pool']}",
        "",
        "per file kind:",
    ]
    lines += [f"  {k}: {v}" for k, v in d["per_kind"].items()]
    lines.append("")
    lines.append("largest phi:")
    lines += [
        f"  {e['phi']:.4g}  {e['file']} | {e['block']} | {e['group']}  n={e['n_stoch']}"
        for e in d["largest_phi"][:20]
    ]
    lines.append("highest kappa2:")
    lines += [
        f"  {e['kappa2']:.4g}  {e['file']} | {e['block']} | {e['group']}  n={e['n_stoch']}"
        for e in d["highest_kappa2"][:10]
    ]
    lines.append("lowest kappa2:")
    lines += [
        f"  {e['kappa2']:.4g}  {e['file']} | {e['block']} | {e['group']}  n={e['n_stoch']}"
        for e in d["lowest_kappa2"][:10]
    ]
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------------------------
# MDE tables
# --------------------------------------------------------------------------------------------


def write_mde(cal: Calibration, selectors: Sequence[str], candidate_runs: int) -> Path:
    """Write the MDE of every field of the selected families to ``<calibration>/mde``.

    A selector is ``FILEGLOB::BLOCKGLOB`` (fnmatch on the run-relative file path and the block).
    """
    root = cal.root / "mde"
    root.mkdir(exist_ok=True)
    patterns = [tuple(s.split("::", 1)) for s in selectors]
    index: list[dict[str, Any]] = []
    for k, rel in enumerate(cal.rels):
        sel = [(f, b) for f, b in patterns if fnmatch.fnmatchcase(rel, f)]
        cf = cal.file(rel)
        if not sel or cf is None:
            continue
        arrays: dict[str, Any] = {}
        for block, group in cf.families:
            if not any(fnmatch.fnmatchcase(block, b) for _, b in sel):
                continue
            fam = cf.family(block, group)
            if fam is None or fam.null.n_stoch == 0:
                continue
            res = cal.mde(fam, candidate_runs)
            tag = len(index)
            arrays[f"kmat_{tag}"] = res.kmat
            arrays[f"mean_{tag}"] = res.mean
            arrays[f"abs_{tag}"] = res.absolute
            arrays[f"rel_{tag}"] = res.relative
            stat = fam.cls == CLS_STOCH
            rel_stat = res.relative[stat]
            rel_stat = rel_stat[np.isfinite(rel_stat)]
            index.append(
                {
                    "file": rel, "block": block, "group": group, "tag": tag, "npz": k,
                    "labels": list(res.labels), "t_star": res.t_star, "kappa2": res.kappa2,
                    "n_stoch": res.n_fields, "candidate_runs": candidate_runs,
                    "median_rel_mde": float(np.median(rel_stat)) if len(rel_stat) else None,
                    "min_rel_mde": float(rel_stat.min()) if len(rel_stat) else None,
                }
            )  # fmt: skip
        if arrays:
            np.savez_compressed(root / f"{k}.npz", **arrays)
    _write_json(root / "index.json", index)
    return root


# --------------------------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------------------------


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m compare.calibrate", description=__doc__)
    parser.add_argument("--ensemble", nargs="+", help="capture ids, run dirs or an id prefix")
    parser.add_argument("--exclude", nargs="*", default=[], metavar="ID", help="drop members")
    parser.add_argument("--leave-out", metavar="ID", help="drop one member (gate G3)")
    parser.add_argument("--out", type=Path, help="artifact directory")
    parser.add_argument("--jobs", type=int, default=MAX_JOBS, help=f"processes (max {MAX_JOBS})")
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--alpha", type=float, default=ALPHA)
    parser.add_argument("--input-sha256", help="input hash for ensemble runs without run.json")
    parser.add_argument(
        "--mde", action="append", metavar="FILEGLOB::BLOCKGLOB",
        help=f"families whose MDE is written (default {', '.join(DEFAULT_MDE)})",
    )  # fmt: skip
    parser.add_argument("--mde-from", type=Path, help="only (re)write MDE tables of this artifact")
    parser.add_argument("--candidate-runs", type=int, default=1, help="candidate runs for the MDE")
    args = parser.parse_args(argv)
    selectors = args.mde if args.mde else list(DEFAULT_MDE)
    try:
        if args.mde_from:
            root = write_mde(Calibration.open(args.mde_from), selectors, args.candidate_runs)
            print(f"wrote MDE tables to {root}")
            return 0
        if not args.ensemble or not args.out:
            parser.error("--ensemble and --out are required")
        excluded = [*args.exclude, *([args.leave_out] if args.leave_out else [])]
        members = resolve_ensemble(args.ensemble, excluded)
        manifest = calibrate(
            members, args.out, excluded=excluded, cache=args.cache, jobs=args.jobs, mde=selectors,
            alpha=args.alpha, input_sha256=args.input_sha256,
            log=_stderr,
        )  # fmt: skip
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    print(
        f"calibrated {manifest['families']} families "
        f"({manifest['stat_families']} with numeric fields) "
        f"from {manifest['runs']} runs -> {args.out}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
