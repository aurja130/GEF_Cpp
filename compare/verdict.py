# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Suite verdict of candidate runs against a calibration (STATISTICS.md §1 to §5).

    python3 -m compare.verdict --calibration DIR --candidate RUN [--candidate RUN ...]
        [--candidate-extract DIR ...] [--json OUT] [--text OUT] [--input FILE | --input-sha256 H]

Exit status: 0 the suite passes, 1 it fails, 2 an error (unreadable input, input hash mismatch).

Candidates are run directories (or reference-store capture ids), or extract directories made by
``compare.inject`` (``--candidate-extract``). Several candidates are one candidate *set*: the
statistic uses their mean and the variance is scaled by ``1/m + 1/K`` (D9).

Input hash: the calibration records the sha256 of the input file of its ensemble. A candidate with
a ``run.json`` must carry the same hash. A plain GEF directory has none: pass ``--input FILE``
(hashed) or ``--input-sha256 HASH``, which applies to every candidate without a ``run.json``.

Selecting what to compare:

``--group-map FROM=TO``
    Candidate families whose group starts with ``FROM`` (the part before the first ``/``, e.g.
    ``run2`` or ``tape2``) are judged as ``TO``, and candidate families already named ``TO`` are
    dropped. ``--group-map run2=run1 --group-map tape2=tape1`` selects the second (real) run and
    tape of a ``validation/test_run`` directory that holds an appended partial earlier run.
``--files GLOB``
    Only judge families of files matching the glob (repeatable), e.g. ``'work/ENDF/*'`` for a
    library tape. Holm then runs over the judged families only (``--holm-total calibration``
    keeps the calibration's family count instead).
``--allow-extra``
    Unknown text keys inside known families are listed, not failed. (A family the calibration
    never had is judged numerically against the typical floors of its labels and its text is
    listed; it never fails for its existence alone.)

A family of the calibration that the candidate lacks fails the suite unless some ensemble run
lacked it too. Every family with numeric fields gets a p-value (1 if nothing in it is
testable) and enters Holm; see ``STATISTICS.md`` §1 to §5 for the rules.
"""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import re
import sys
from collections.abc import Sequence
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from numpy.typing import NDArray

from compare.calibrate import CalFamily, CalFile, Calibration
from compare.extract import (
    DEFAULT_CACHE,
    PAD,
    Aligned,
    FamilyData,
    FileData,
    RunExtract,
    align_numeric,
    key_label,
    load_extract,
    match_rows,
    pad_width,
    remap_labels,
    text_map,
)
from compare.report import render_json, render_pvalues, render_text
from compare.stats import (
    CLS_DET,
    CLS_STOCH,
    CLS_ZERO,
    DERIVED_LABELS,
    INTEGRAL_TOL,
    SPARSE_MEAN,
    UNTESTED_KINDS,
    NullParams,
    discrete_z,
    file_kind,
    holm,
    judge_values,
    print_quantum,
)

__all__ = [
    "DETAIL_P",
    "DetMismatch",
    "FamilyResult",
    "TopBin",
    "VerdictResult",
    "judge",
    "main",
    "remap_groups",
    "sha256_file",
]

DETAIL_P = 0.05  # families at or below this p keep their top bins for the report
TOP_BINS = 10
MAX_MISMATCHES = 25  # deterministic mismatches listed per family (all are counted)

type FloatArray = NDArray[np.float64]


@dataclass
class TopBin:
    """One field that contributes most to a family's statistic."""

    key: str
    candidate: float
    mean: float
    z: float


@dataclass
class DetMismatch:
    """A deterministic field (or text key) the candidate does not reproduce."""

    key: str
    expected: str
    got: str


@dataclass
class FamilyResult:
    """The outcome for one family."""

    file: str
    block: str
    group: str
    status: str  # "tested", "deterministic" (no numeric fields), "missing"
    n_stoch: int = 0
    d: float = float("nan")
    m: float = float("nan")
    n_test: int = 0
    p_global: float = float("nan")
    p_local: float = float("nan")
    p: float = float("nan")
    n_mismatch: int = 0
    mismatches: list[DetMismatch] = field(default_factory=lambda: [])
    listed_text: int = 0  # stochastic text keys of the family (not tested)
    top: list[TopBin] = field(default_factory=lambda: [])
    rank: int = 0  # Holm rank (1-based, by p) of a tested family
    threshold: float = float("nan")
    rejected: bool = False

    @property
    def failed_exactly(self) -> bool:
        return self.status == "missing" or self.n_mismatch > 0


@dataclass
class VerdictResult:
    """A suite verdict; ``families`` keeps the families that failed exactly or have low p."""

    calibration: str
    candidates: list[str]
    runs_calibration: int
    runs_candidate: int
    alpha: float
    holm_total: int
    tested: int  # statistical families judged
    exact_only: int  # families with only deterministic fields judged
    families: list[FamilyResult]
    kinds: dict[str, dict[str, int]]  # per-file-kind counts
    energies: dict[str, dict[str, float | int]]  # per (kind, energy) summary
    p_index: list[tuple[str, str, str]]
    p_values: FloatArray  # of every tested family, aligned with p_index
    unparsed_candidate: list[str]
    unparsed_calibration_note: str = ""

    @property
    def rejected(self) -> list[FamilyResult]:
        return [f for f in self.families if f.rejected or f.failed_exactly]

    @property
    def passed(self) -> bool:
        return not self.rejected


# --------------------------------------------------------------------------------------------
# One family
# --------------------------------------------------------------------------------------------

_EMPTY = ((), np.zeros((0, 1), dtype=np.int64), np.zeros(0))


def _fmt(x: float) -> str:
    return repr(float(x))


def _row_key(labels: tuple[str, ...], row: Sequence[int]) -> str:
    label, index = key_label(labels, row)
    return f"{label}[{','.join(map(str, index))}]" if index else label


def _judge_text(
    fam: CalFamily, fds: Sequence[FamilyData | None], allow_extra: bool
) -> tuple[list[DetMismatch], int]:
    """Deterministic text keys must match; unknown text keys fail unless ``allow_extra``."""
    cal: dict[tuple[str, tuple[int, ...]], tuple[int, str]] = {}
    for row, cls, value in zip(fam.tkmat.tolist(), fam.tcls.tolist(), fam.tvals, strict=True):
        cal[fam.tlabels[row[0]], tuple(i for i in row[1:] if i != PAD)] = (cls, value)
    out: list[DetMismatch] = []
    total = 0
    cand_maps = [text_map(f.tlabels, f.tkmat, f.tvals) if f is not None else {} for f in fds]
    for key, (cls, value) in cal.items():
        if cls != 0:
            continue
        for cmap in cand_maps:
            got = cmap.get(key)
            if got is None and file_kind(fam.rel) in UNTESTED_KINDS:
                continue  # a log line that did not occur
            if got != value:
                total += 1
                if len(out) < MAX_MISMATCHES:
                    out.append(
                        DetMismatch(_text_key(key), value, "<absent>" if got is None else got)
                    )
                break
    if not allow_extra and file_kind(fam.rel) not in UNTESTED_KINDS:
        # log lines (text files) come and go between runs: unknown ones are normal there
        for cmap in cand_maps:
            for key, got in cmap.items():
                if key not in cal:
                    total += 1
                    if len(out) < MAX_MISMATCHES:
                        out.append(DetMismatch(_text_key(key), "<unknown key>", got))
    return out, total


def _text_key(key: tuple[str, tuple[int, ...]]) -> str:
    label, index = key
    return f"{label}[{','.join(map(str, index))}]" if index else label


def _positions(
    fam: CalFamily, fds: Sequence[FamilyData | None]
) -> tuple[NDArray[np.int64], NDArray[np.int64], tuple[str, ...], Aligned]:
    """Align the candidate runs among themselves and onto the calibrated fields.

    Returns ``(pos, kmat_c, labels_c, aligned)``: per candidate key the index of the calibrated
    field or -1, the candidate key matrix in the calibration's label table (extended by unknown
    labels), and the candidate runs' common alignment.
    """
    parts = [(f.labels, f.kmat, f.vals) if f is not None else _EMPTY for f in fds]
    al = align_numeric(parts)
    kmat_c, labels_c = remap_labels(al.labels, al.kmat, fam.labels)
    width = max(fam.kmat.shape[1], kmat_c.shape[1])
    pos = match_rows(pad_width(fam.kmat, width), pad_width(kmat_c, width))
    return pos, kmat_c, labels_c, al


def _mismatch(
    res: FamilyResult, mism: list[DetMismatch], key: str, expected: str, got: str
) -> None:
    res.n_mismatch += 1
    if len(mism) < MAX_MISMATCHES:
        mism.append(DetMismatch(key, expected, got))


def judge_family(
    cal: Calibration,
    fam: CalFamily,
    fds: Sequence[FamilyData | None],
    allow_extra: bool,
    detail_p: float,
) -> tuple[FamilyResult, float]:
    """Judge one family; returns the result and its p-value.

    Every family with numeric fields gets a p-value (1 when nothing in it is testable
    statistically); ``res.status`` is ``"tested"`` for those and ``"deterministic"`` for a family
    without numeric fields (text only).
    """
    runs_c = len(fds)
    k = cal.runs
    kind = file_kind(fam.rel)
    res = FamilyResult(fam.rel, fam.block, fam.group, "deterministic")
    pos, kmat_c, labels_c, al = _positions(fam, fds)
    n_cal = len(fam.mean)
    matched = pos >= 0
    cand_idx = np.flatnonzero(matched)
    cal_idx = pos[cand_idx]
    cmean_c = al.vals.mean(axis=0) if al.vals.shape[1] else np.zeros(0)
    # per calibrated field: candidate values and presence of every candidate run
    got = np.zeros((runs_c, n_cal))
    got_present = np.zeros((runs_c, n_cal), dtype=bool)
    got[:, cal_idx] = al.vals[:, cand_idx]
    got_present[:, cal_idx] = al.present[:, cand_idx]
    cm = got.mean(axis=0)
    present_all: NDArray[np.bool_] = np.all(got_present, axis=0)
    mism: list[DetMismatch] = []

    def key_of(i: int) -> str:
        return _row_key(fam.labels, fam.kmat[i].tolist())

    # deterministic fields. Inside a table (a family with stochastic fields) rows appear and
    # disappear and values are rounded when printed: an absent field is accepted and a present
    # one may differ by one printed digit (of a decimal fraction). Elsewhere (headers,
    # parameters) the match is exact.
    det = fam.cls == CLS_DET
    moved_idx = np.zeros(0, dtype=np.int64)
    pinned = np.zeros(n_cal, dtype=bool)
    if det.any():
        if fam.null.n_stoch == 0 and kind not in UNTESTED_KINDS:
            expected = fam.mean.view(np.uint64)
            equal = np.all(got.view(np.uint64) == expected[None, :], axis=0)
            # absent means zero (dmp trims zero bins): only a nonzero value must be present
            bad = det & ~(equal & (present_all | (fam.mean == 0.0)))
        else:
            quantum = print_quantum(fam.mean)
            # integers were printed exactly; only a fraction can hide below the last digit
            tol = np.where(quantum < 1.0, quantum, 0.0) * (1.0 + 1e-9)
            within = ~got_present | (np.abs(got - fam.mean[None, :]) <= tol[None, :])
            bad = det & ~within.all(axis=0)
        if fam.null.n_stoch:
            # a constant in a column that has stochastic fields is table content that happened to
            # be identical in K runs (an edge bin, a conditional mean): judged statistically
            has_stoch = np.zeros(len(fam.labels), dtype=bool)
            has_stoch[fam.kmat[fam.cls == CLS_STOCH, 0]] = True
            pinned = det & has_stoch[fam.kmat[:, 0]]
            bad &= ~pinned
        # a zero that became nonzero is a bin that received an event: judged like a new key
        moved = bad & (fam.mean == 0.0) & np.isfinite(cm) & (cm != 0.0)
        bad &= ~moved
        moved_idx = np.flatnonzero(moved)
        for i in np.flatnonzero(bad).tolist():
            _mismatch(
                res,
                mism,
                key_of(i),
                _fmt(fam.mean[i]),
                _fmt(cm[i]) if present_all[i] else "<absent>",
            )
    v_eff = fam.v.copy()
    zero_idx = np.flatnonzero(fam.cls == CLS_ZERO)
    if len(zero_idx) and fam.null.n_stoch:
        # a zero field has no variance of its own: the floor of its label, else the typical
        # floor of the label over the calibration, else one occupancy event of the observed size
        for i in zero_idx.tolist():
            lid = int(fam.kmat[i, 0])
            own = float(fam.label_floor[lid]) if lid < len(fam.label_floor) else float("nan")
            if not own > 0.0:
                own = cal.label_floor_pool(kind, fam.labels[lid])
            if not own > 0.0:
                own = float(cm[i] ** 2 / k)
            v_eff[i] = own
    for i in np.flatnonzero(pinned).tolist():
        lid = int(fam.kmat[i, 0])
        own = float(fam.label_floor[lid]) if lid < len(fam.label_floor) else float("nan")
        v_eff[i] = own if own > 0.0 else cal.label_floor_pool(kind, fam.labels[lid])
    usable_v = np.isfinite(v_eff) & (v_eff > 0.0)
    stat_fields = ((fam.cls == CLS_STOCH) | (fam.cls == CLS_ZERO) | pinned) & usable_v
    exact_zero = (fam.cls == CLS_ZERO) & ~usable_v
    bad = exact_zero & np.any(got != 0.0, axis=0)
    nonfinite = stat_fields & ~np.isfinite(cm)
    bad |= nonfinite
    stat_fields &= ~nonfinite
    # the candidate's histogram may be larger or smaller than the ensemble's (shared normalization)
    weight = float(runs_c)
    if len(fam.label_quantum):
        nlab0 = len(fam.label_quantum)
        q0 = fam.label_quantum[np.minimum(fam.kmat[:, 0], nlab0 - 1)]
        known = np.isfinite(q0) & stat_fields
        total_e = float(np.sum(fam.mean[known] / q0[known]))
        if total_e > 0.0:
            weight = runs_c * float(
                np.clip(float(np.sum(cm[known] / q0[known])) / total_e, 0.2, 5.0)
            )
    for i in np.flatnonzero(bad).tolist():
        _mismatch(res, mism, key_of(i), _fmt(fam.mean[i]), _fmt(cm[i]))
    # never-seen fields with a nonzero value: keys new in the candidate, and deterministic zeros
    # that received an event. Scale: the label's floor in this family, else the label's typical
    # floor in the calibration, else one occupancy event of the observed size per K runs (only in
    # a family with stochastic fields; elsewhere there is no evidence of the scale: exact failure).
    derived = DERIVED_LABELS.get(kind, frozenset())
    untested = kind in UNTESTED_KINDS
    cal_lid = {name: i for i, name in enumerate(fam.labels)}
    entries: list[tuple[str, float, str]] = []
    new_rows = np.flatnonzero(~matched)
    changed_rows: list[int] = new_rows[cmean_c[new_rows] != 0.0].tolist() if len(new_rows) else []
    for r in changed_rows:
        label = labels_c[int(kmat_c[r, 0])]
        if label not in derived and not untested:
            entries.append((_row_key(labels_c, kmat_c[r].tolist()), float(cmean_c[r]), label))
    for i in moved_idx.tolist():
        entries.append((key_of(i), float(cm[i]), fam.labels[int(fam.kmat[i, 0])]))
    new_sparse: list[bool] = []
    z_new: FloatArray = np.zeros(0)
    new_mean: FloatArray = np.zeros(0)
    new_keys: list[str] = []
    if entries:
        zs: list[float] = []
        for key, value, label in entries:
            lid = cal_lid.get(label, -1)
            quantum = float(fam.label_quantum[lid]) if 0 <= lid < len(fam.label_quantum) else 0.0
            if quantum > 0.0 and np.isfinite(value):
                ratio = value / quantum
                if abs(ratio - np.rint(ratio)) <= INTEGRAL_TOL + 1e-5 * abs(ratio):
                    # a whole number of events in a count column: exact discrete p, no events seen
                    z_one = discrete_z(
                        np.array([runs_c * ratio]), np.zeros(1), weight, k,
                        fam.label_fano[lid : lid + 1],
                    )  # fmt: skip
                    zs.append(float(z_one[0]))
                    new_sparse.append(True)
                    new_mean = np.append(new_mean, value)
                    new_keys.append(key)
                    continue
            floor = float(fam.label_floor[lid]) if 0 <= lid < len(fam.label_floor) else float("nan")
            if not floor > 0.0:
                floor = cal.label_floor_pool(kind, label)
            if not floor > 0.0 and fam.null.n_stoch:
                floor = value * value / k
            if np.isfinite(value) and floor > 0.0:
                zs.append(value / float(np.sqrt(floor * (1.0 / runs_c + 1.0 / k))))
                new_sparse.append(False)
                new_mean = np.append(new_mean, value)
                new_keys.append(key)
            else:
                _mismatch(res, mism, key, "<unknown key>" if lid < 0 else "0.0", _fmt(value))
        z_new = np.array(zs)
    # statistics over the stochastic fields, zero fields that became nonzero, and new keys
    if len(fam.mean) or len(new_mean):
        res.status = "tested"
        res.n_stoch = fam.null.n_stoch
        scale = np.sqrt(np.where(stat_fields, v_eff, 1.0) * (1.0 / runs_c + 1.0 / k))
        z_field = np.where(stat_fields, (cm - fam.mean) / scale, 0.0)
        disc = np.zeros(n_cal, dtype=bool)
        nlab = len(fam.label_quantum)
        if nlab:  # low counts of a discrete column: exact discrete p as a normal-equivalent score
            qf = fam.label_quantum[np.minimum(fam.kmat[:, 0], nlab - 1)]
            ff = fam.label_fano[np.minimum(fam.kmat[:, 0], nlab - 1)]
            disc = (
                stat_fields
                & np.isfinite(qf)
                & (fam.mean <= SPARSE_MEAN * np.where(np.isfinite(qf), qf, 1.0))
            )
            if disc.any():
                z_field[disc] = discrete_z(
                    runs_c * cm[disc] / qf[disc], k * fam.mean[disc] / qf[disc], weight, k, ff[disc]
                )
        zero_nonzero = stat_fields & ((fam.cls == CLS_ZERO) | pinned) & (cm != fam.mean)
        test = ((fam.cls == CLS_STOCH) & stat_fields) | zero_nonzero
        z_test = np.concatenate([z_field[test], z_new])
        flags = np.concatenate([disc[test], np.array(new_sparse, dtype=bool)])
        n_extra = int(zero_nonzero.sum()) + len(z_new)
        n_extra_sparse = int((zero_nonzero & disc).sum()) + int(sum(new_sparse))
        j = judge_values(
            fam.null, z_test, cal.local_pool(kind), n_extra=n_extra, sparse=flags,
            n_extra_sparse=n_extra_sparse,
            clustering=cal.clustering(kind),
        )  # fmt: skip
        res.d, res.m, res.n_test = j.d, j.m, j.n_test
        res.p_global, res.p_local, res.p = j.p_global, j.p_local, j.p
        if j.p <= detail_p:
            order = np.argsort(-np.abs(z_test), kind="stable")[:TOP_BINS]
            idx_test = np.flatnonzero(test)
            for o in order.tolist():
                if o < len(idx_test):
                    i = int(idx_test[o])
                    res.top.append(
                        TopBin(key_of(i), float(cm[i]), float(fam.mean[i]), float(z_test[o]))
                    )
                else:
                    n = int(o) - len(idx_test)
                    res.top.append(TopBin(new_keys[n], float(new_mean[n]), 0.0, float(z_test[o])))
    # a family the candidate lacks entirely (Bernoulli presence) says nothing about its text
    text_bad, text_total = (
        _judge_text(fam, fds, allow_extra) if any(f is not None for f in fds) else ([], 0)
    )
    res.n_mismatch += text_total
    mism.extend(text_bad[: max(0, MAX_MISMATCHES - len(mism))])
    res.mismatches = mism
    res.listed_text = int((fam.tcls == 1).sum())
    return res, res.p


# --------------------------------------------------------------------------------------------
# Suite
# --------------------------------------------------------------------------------------------


def family_energy(rel: str, group: str) -> str:
    """Neutron energy label (MeV) of a family, or ``""``: from the group or the file name."""
    m = re.search(r"E=([0-9.]+)([+-][0-9]+)#", group)
    if m:
        return f"{float(m.group(1)) * 10 ** int(m.group(2)) / 1e6:g}"
    m = re.match(r"run\d+/([^#]+)#", group)
    if m:
        return m.group(1)
    m = re.search(r"_E([0-9.eE+-]+?)MeV", rel)
    if m:
        return f"{float(m.group(1)):g}"
    return ""


def _unseen_family(rel: str, block: str, group: str) -> CalFamily:
    """A family no ensemble run had: no fields, so every candidate value is a new key."""
    empty_i = np.zeros((0, 1), dtype=np.int64)
    null = NullParams(
        0, False, float("nan"), float("nan"), 0, float("nan"), float("nan"), float("nan"),
        float("nan"), float("nan"), float("nan"), True, 0.0, 0.0, 0, 0, 0, 0.0, 0.0, 0.0,
    )  # fmt: skip
    return CalFamily(
        rel, block, group, (), empty_i, np.zeros(0, np.int8), np.zeros(0), np.zeros(0), np.zeros(0),
        np.zeros(0), np.zeros(0),
        (), empty_i, np.zeros(0, np.int8), [], null, 0, np.zeros(0), np.zeros(0),
    )  # fmt: skip


def remap_groups(fd: FileData, group_map: dict[str, str]) -> dict[tuple[str, str], int]:
    """``(block, group)`` -> family index of a candidate file, after ``--group-map``."""
    if not group_map:
        return dict(fd.layout.index)
    heads = {group.partition("/")[0] for _, group in fd.layout.index}
    # a target is shadowed only in a file that has the family it is replaced by
    shadowed = {to for src, to in group_map.items() if src in heads}
    out: dict[tuple[str, str], int] = {}
    for (block, group), i in fd.layout.index.items():
        head, sep, rest = group.partition("/")
        if head in group_map:
            out[block, group_map[head] + sep + rest] = i
        elif head in shadowed:
            continue
        else:
            out[block, group] = i
    return out


def judge(
    cal: Calibration,
    candidates: Sequence[RunExtract],
    *,
    names: Sequence[str] = (),
    group_map: dict[str, str] | None = None,
    files: Sequence[str] = (),
    allow_extra: bool = False,
    holm_total: str = "tested",
    alpha: float | None = None,
) -> VerdictResult:
    """Judge a candidate set against a calibration; see the module docstring."""
    a = cal.alpha if alpha is None else alpha
    detail_p = max(DETAIL_P, a)
    gmap = group_map or {}
    rels = sorted(set(cal.rels) | {r for ex in candidates for r in ex.rels})
    results: list[FamilyResult] = []
    p_index: list[tuple[str, str, str]] = []
    p_list: list[float] = []
    kinds: dict[str, dict[str, int]] = {}
    exact_only = 0
    for rel in rels:
        if files and not any(fnmatch.fnmatchcase(rel, g) for g in files):
            continue
        kind = file_kind(rel)
        ks = kinds.setdefault(kind, {"tested": 0, "exact_only": 0, "missing": 0, "extra": 0})
        cf: CalFile | None = cal.file(rel)
        cds = [ex.file(rel) for ex in candidates]
        maps = [remap_groups(d, gmap) if d is not None else {} for d in cds]
        cand_keys = {key for m in maps for key in m}
        # a file whose set of families differs between ensemble runs (data-dependent analyzers
        # such as Zpre(A)) has Bernoulli family presence: a missing family is not evidence
        variable_file = cf is not None and bool(np.any(cf.extra["nruns"] < cal.runs))
        cal_keys: set[tuple[str, str]] = set(cf.families) if cf is not None else set()
        for block, group in sorted(cal_keys | cand_keys):
            if (block, group) not in cal_keys:
                ks["extra"] += 1
                fam = _unseen_family(rel, block, group)
                allow = True  # text of a family nobody has seen is listed, not judged
            else:
                assert cf is not None
                known = cf.family(block, group)
                assert known is not None
                fam = known
                allow = allow_extra
            fds: list[FamilyData | None] = []
            for d, m in zip(cds, maps, strict=True):
                i = m.get((block, group))
                fds.append(d.family_at(i) if d is not None and i is not None else None)
            if all(f is None for f in fds) and fam.n_runs == cal.runs and not variable_file:
                ks["missing"] += 1
                results.append(FamilyResult(rel, block, group, "missing"))
                continue
            res, p = judge_family(cal, fam, fds, allow, detail_p)
            if res.status == "tested":
                ks["tested"] += 1
                p_index.append((rel, block, group))
                p_list.append(p)
            else:
                ks["exact_only"] += 1
                exact_only += 1
            if res.failed_exactly or res.p <= detail_p:
                results.append(res)
    p_arr = np.array(p_list)
    tested = len(p_arr)
    total = cal.stat_families if holm_total == "calibration" else tested
    rejected_ids: set[int] = set()
    if tested:
        by_key = {(f.file, f.block, f.group): f for f in results if f.status == "tested"}
        order, threshold, rejected = holm(p_arr, a, max(total, tested))
        for rank, (o, thr, rej) in enumerate(
            zip(order.tolist(), threshold.tolist(), rejected.tolist(), strict=True), 1
        ):
            if p_arr[o] > detail_p:
                break
            f = by_key[p_index[o]]
            f.rank, f.threshold, f.rejected = rank, thr, bool(rej)
            rejected_ids.add(id(f))
    results.sort(key=lambda f: (f.file, f.block, f.group))
    energies = _energy_summary(results, p_index, p_arr)
    unparsed = sorted({u for ex in candidates for u in ex.unparsed})
    return VerdictResult(
        calibration=str(cal.root),
        candidates=list(names) if names else [str(ex.root) for ex in candidates],
        runs_calibration=cal.runs,
        runs_candidate=len(candidates),
        alpha=a,
        holm_total=max(total, tested),
        tested=tested,
        exact_only=exact_only,
        families=results,
        kinds=kinds,
        energies=energies,
        p_index=p_index,
        p_values=p_arr,
        unparsed_candidate=unparsed,
    )


def _energy_summary(
    results: list[FamilyResult], p_index: list[tuple[str, str, str]], p_arr: FloatArray
) -> dict[str, dict[str, float | int]]:
    """Per ``kind @ energy``: tested families, smallest p, rejected and exactly failed counts."""
    summary: dict[str, dict[str, float | int]] = {}

    def slot(rel: str, group: str) -> dict[str, float | int]:
        label = f"{file_kind(rel)} @ {family_energy(rel, group) or '-'}"
        return summary.setdefault(
            label, {"tested": 0, "min_p": 1.0, "rejected": 0, "exact_failed": 0}
        )

    for (rel, _block, group), p in zip(p_index, p_arr.tolist(), strict=True):
        s = slot(rel, group)
        s["tested"] = int(s["tested"]) + 1
        s["min_p"] = min(float(s["min_p"]), p)
    for f in results:
        s = slot(f.file, f.group)
        if f.rejected:
            s["rejected"] = int(s["rejected"]) + 1
        if f.failed_exactly:
            s["exact_failed"] = int(s["exact_failed"]) + 1
    return summary


# --------------------------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------------------------


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def check_inputs(cal: Calibration, candidates: Sequence[RunExtract], override: str | None) -> None:
    """Raise ``ValueError`` unless every candidate is known to share the calibration's input."""
    want = cal.input_sha256
    if want is None:
        raise ValueError("the calibration records no input sha256")
    for ex in candidates:
        got = ex.input_sha256 or override
        if got is None:
            raise ValueError(
                f"{ex.manifest.get('source', ex.root)} has no run.json: pass --input FILE or "
                "--input-sha256 to state which input it was run with"
            )
        if got != want:
            raise ValueError(
                f"input hash mismatch for {ex.manifest.get('source', ex.root)}: candidate {got}, "
                f"calibration {want}"
            )


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m compare.verdict", description=__doc__)
    parser.add_argument("--calibration", required=True, help="calibration directory or store id")
    parser.add_argument("--candidate", action="append", default=[], help="run dir or capture id")
    parser.add_argument("--candidate-extract", action="append", default=[], type=Path)
    parser.add_argument("--json", type=Path)
    parser.add_argument("--text", type=Path)
    parser.add_argument("--pvalues", type=Path, help="write the p-value of every tested family")
    parser.add_argument("--input", type=Path, help="input file of plain-GEF-directory candidates")
    parser.add_argument("--input-sha256")
    parser.add_argument("--group-map", action="append", default=[], metavar="FROM=TO")
    parser.add_argument("--files", action="append", default=[], metavar="GLOB")
    parser.add_argument("--allow-extra", action="store_true")
    parser.add_argument("--holm-total", choices=("tested", "calibration"), default="tested")
    parser.add_argument("--alpha", type=float, default=None)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--quiet", action="store_true", help="print only the verdict line")
    args = parser.parse_args(argv)
    try:
        if not args.candidate and not args.candidate_extract:
            parser.error("give at least one --candidate or --candidate-extract")
        gmap: dict[str, str] = {}
        for item in args.group_map:
            src, sep, dst = item.partition("=")
            if not sep or not src or not dst:
                parser.error(f"--group-map expects FROM=TO, got {item!r}")
            gmap[src] = dst
        cal = Calibration.open(args.calibration)
        specs = [*args.candidate, *map(str, args.candidate_extract)]
        candidates = [load_extract(s, args.cache) for s in specs]
        override = args.input_sha256 or (sha256_file(args.input) if args.input else None)
        check_inputs(cal, candidates, override)
        result = judge(
            cal,
            candidates,
            names=specs,
            group_map=gmap,
            files=args.files,
            allow_extra=args.allow_extra,
            holm_total=args.holm_total,
            alpha=args.alpha,
        )
    except (OSError, ValueError, KeyError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    text = render_text(result)
    if args.text:
        args.text.write_text(text)
    if args.json:
        args.json.write_text(render_json(result))
    if args.pvalues:
        args.pvalues.write_text(render_pvalues(result))
    head = "PASS" if result.passed else "FAIL"
    if args.quiet:
        print(f"{head}: {result.tested} families tested, {len(result.rejected)} rejected")
    else:
        print(text if not args.text else "\n".join(text.splitlines()[:30]))
    return 0 if result.passed else 1


if __name__ == "__main__":
    sys.exit(main())
