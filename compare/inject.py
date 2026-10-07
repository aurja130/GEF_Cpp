# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Synthetic faults for the sensitivity gate G5 (plan M2.9).

    python3 -m compare.inject --run RUN --out DIR --fault FAULT --at SPEC [--factor F]
    python3 -m compare.inject --run RUN --fault FAULT --list-sites

A fault is applied to the *extracted* table of a run (``compare.extract``), in one fixed primary
representation, and written as a new extract directory that ``compare.verdict
--candidate-extract DIR`` accepts. The run directory itself is never modified. Everything but the
one changed file is hard-linked to the source extract.

Faults (``FAULT``) and what ``--at`` selects:

``yield2pct``
    ENDF MF8/MT454 ``Y`` of one ``(ZA, state)`` at one energy, multiplied by ``--factor``
    (default 1.02). ``--at E=<MeV>,nuclide=max|mid|<ZA>:<state>``.
``massbin``
    The content of one bin of the ``dmp`` ``APOST`` analyzer of one energy step (block ``APOST``,
    label ``y``) moved to the neighbouring bin ``bin + step`` (default 1; ``-1`` the other way).
    ``--at E=<MeV>,bin=max|mid|<A>[,step=-1]``.
``isomer``
    ENDF MF8/MT454 ``Y`` of isomeric state 1 of one ZA added to state 0 and set to 0.
    ``--at E=<MeV>,nuclide=max|mid|<ZA>``, ``max``/``mid`` over the ZA with a positive state 1.

``max`` is the largest value among the candidates of the fault and ``mid`` the one at the median
of the sorted positive values (ties by key order). ENDF files with several tapes
(``validation/test_run``) need ``tape=tapeN``; ``file=<run-relative path>`` overrides the file.

The change is recorded in ``<DIR>/manifest.json`` under ``injection`` (file, block, group, keys,
values before and after) so a report can be checked against the true location.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np

from compare.calibrate import Calibration
from compare.extract import (
    DEFAULT_CACHE,
    EXTRACT_VERSION,
    PAD,
    FamilyData,
    RunExtract,
    key_label,
    load_extract,
    match_rows,
)
from compare.verdict import family_energy

__all__ = ["FAULTS", "Injection", "Site", "inject", "list_sites", "main", "parse_spec"]

FAULTS = ("yield2pct", "massbin", "isomer")
ENDF_BLOCK = "MF8/MT454"


@dataclass(frozen=True)
class Site:
    """One resolved injection target."""

    fault: str
    spec: str  # a complete ``--at`` string that reproduces this site
    rel: str
    block: str
    group: str
    keys: tuple[str, ...]
    values: tuple[float, ...]
    after: tuple[float, ...]
    mde_abs: tuple[float | None, ...] = ()  # per key, when a calibration is given
    delta_over_mde: tuple[float | None, ...] = ()  # |after - before| / MDE of the key


@dataclass
class Injection:
    """What was changed (also written to the extract manifest)."""

    fault: str
    spec: str
    rel: str
    block: str
    group: str
    keys: list[str]
    before: list[float]
    after: list[float]

    def to_json(self) -> dict[str, Any]:
        return {
            "fault": self.fault, "spec": self.spec, "file": self.rel, "block": self.block,
            "group": self.group, "keys": self.keys, "before": self.before, "after": self.after,
        }  # fmt: skip


def parse_spec(spec: str) -> dict[str, str]:
    """``E=14.5,nuclide=max`` as a dict."""
    out: dict[str, str] = {}
    for item in spec.split(","):
        key, sep, value = item.partition("=")
        if not sep or not key:
            raise ValueError(f"--at expects key=value pairs, got {item!r}")
        out[key.strip()] = value.strip()
    return out


def _same_energy(a: str, b: float) -> bool:
    return bool(a) and abs(float(a) - b) <= 1e-9 * max(1.0, abs(b))


def _row_label(fd: FamilyData, label: str) -> tuple[np.ndarray[Any, Any], int] | None:
    if label not in fd.labels:
        return None
    lid = fd.labels.index(label)
    return np.flatnonzero(fd.kmat[:, 0] == lid), lid


def _endf_families(ex: RunExtract, opts: dict[str, str]) -> list[tuple[str, str, float]]:
    """``(rel, group, MeV)`` of the MT454 energy families of the selected ENDF file/tape."""
    rels = [opts["file"]] if "file" in opts else [r for r in ex.rels if r.startswith("work/ENDF/")]
    found: list[tuple[str, str, float]] = []
    for rel in rels:
        data = ex.file(rel)
        if data is None:
            raise ValueError(f"{rel}: no such parsed file in the extract")
        for (block, group), _ in data.layout.index.items():
            energy = family_energy(rel, group)
            if (
                block == ENDF_BLOCK
                and energy
                and ("tape" not in opts or group.startswith(opts["tape"] + "/"))
            ):
                found.append((rel, group, float(energy)))
    if not found:
        raise ValueError("no MF8/MT454 energy family found (check file= and tape=)")
    if "tape" not in opts and len({g.split("/")[0] for _, g, _ in found}) > 1:
        raise ValueError("the ENDF file holds several tapes: give tape=tapeN")
    return sorted(found, key=lambda t: (t[0], t[2], t[1]))


def _dmp_apost(ex: RunExtract) -> list[tuple[str, float]]:
    """``(rel, MeV)`` of every ``Apost.dmp`` of the run."""
    out: list[tuple[str, float]] = []
    for rel in ex.rels:
        if rel.endswith("/Apost.dmp"):
            m = re.search(r"_E([0-9.eE+-]+?)MeV", rel)
            if m:
                out.append((rel, float(m.group(1))))
    if not out:
        raise ValueError("the run has no Apost.dmp")
    return sorted(out, key=lambda t: t[1])


def _pick(values: np.ndarray[Any, Any], which: str) -> int:
    """Index (into ``values``) of the ``max`` or ``mid`` (median of the positive ones) entry."""
    positive = np.flatnonzero(values > 0.0)
    if not len(positive):
        raise ValueError("no positive value to inject into")
    if which == "max":
        return int(np.argmax(values))
    order = positive[np.argsort(values[positive], kind="stable")]
    return int(order[len(order) // 2])


def _rows_y(fd: FamilyData) -> tuple[np.ndarray[Any, Any], np.ndarray[Any, Any]]:
    """Row indices of ``Y`` and their ``(ZA, state)`` index matrix."""
    found = _row_label(fd, "Y")
    if found is None:
        raise ValueError("the MT454 family has no Y field")
    rows, _ = found
    return rows, fd.kmat[rows, 1:3]


def _key(fd: FamilyData, row: int) -> str:
    label, index = key_label(fd.labels, fd.kmat[row].tolist())
    return f"{label}[{','.join(map(str, index))}]" if index else label


def _resolve(
    ex: RunExtract, fault: str, opts: dict[str, str]
) -> tuple[str, str, str, list[int], list[float]]:
    """``(rel, block, group, row indices, new values)`` of one fault; reads the family."""
    if fault in ("yield2pct", "isomer"):
        families = _endf_families(ex, opts)
        if "E" not in opts:
            raise ValueError("--at needs E=<MeV>")
        energy = float(opts["E"])
        hit = [f for f in families if _same_energy(f"{f[2]:.12g}", energy)]
        if len(hit) != 1:
            raise ValueError(f"E={opts['E']}: {len(hit)} matching energy families (need exactly 1)")
        rel, group, _ = hit[0]
        data = ex.file(rel)
        assert data is not None
        fd = data.get(ENDF_BLOCK, group)
        assert fd is not None
        rows, idx = _rows_y(fd)
        y = fd.vals[rows]
        which = opts.get("nuclide", "max")
        if fault == "yield2pct":
            if which in ("max", "mid"):
                pick = _pick(np.asarray(y), which)
            else:
                za, _, state = which.partition(":")
                match = np.flatnonzero((idx[:, 0] == int(za)) & (idx[:, 1] == int(state)))
                if len(match) != 1:
                    raise ValueError(f"nuclide {which} not found in {rel} {group}")
                pick = int(match[0])
            factor = float(opts.get("factor", "1.02"))
            row = int(rows[pick])
            return rel, ENDF_BLOCK, group, [row], [float(fd.vals[row]) * factor]
        # isomer: state 1 into state 0 of one ZA
        state1 = np.flatnonzero(idx[:, 1] == 1)
        by_za = {int(idx[i, 0]): i for i in state1.tolist() if y[i] > 0.0}
        if which in ("max", "mid"):
            zas = sorted(by_za)
            if not zas:
                raise ValueError("no ZA with a positive isomeric (state 1) yield")
            sub = np.array([y[by_za[z]] for z in zas])
            za = zas[_pick(sub, which)]
        else:
            za = int(which)
        if za not in by_za:
            raise ValueError(f"ZA {za} has no positive state-1 yield in {rel} {group}")
        zero = np.flatnonzero((idx[:, 0] == za) & (idx[:, 1] == 0))
        if len(zero) != 1:
            raise ValueError(f"ZA {za}: no state-0 entry to move the yield into")
        r1, r0 = int(rows[by_za[za]]), int(rows[zero[0]])
        return rel, ENDF_BLOCK, group, [r0, r1], [float(fd.vals[r0] + fd.vals[r1]), 0.0]
    if fault == "massbin":
        if "E" not in opts:
            raise ValueError("--at needs E=<MeV>")
        energy = float(opts["E"])
        hit = [r for r, e in _dmp_apost(ex) if _same_energy(f"{e:.12g}", energy)]
        if len(hit) != 1:
            raise ValueError(f"E={opts['E']}: {len(hit)} Apost.dmp files match (need exactly 1)")
        data = ex.file(hit[0])
        assert data is not None
        fd = data.get("APOST", "#1")
        if fd is None:
            raise ValueError(f"{hit[0]}: no APOST block")
        found = _row_label(fd, "y")
        if found is None:
            raise ValueError(f"{hit[0]}: APOST has no y values")
        rows, _ = found
        bins = fd.kmat[rows, 1]
        y = fd.vals[rows]
        which = opts.get("bin", "max")
        pick = (
            _pick(np.asarray(y), which)
            if which in ("max", "mid")
            else int(np.flatnonzero(bins == int(which))[0])
        )
        step = int(opts.get("step", "1"))
        neighbour = np.flatnonzero(bins == bins[pick] + step)
        if len(neighbour) != 1:
            raise ValueError(f"bin {bins[pick]} has no neighbour at step {step} in {hit[0]}")
        r_from, r_to = int(rows[pick]), int(rows[neighbour[0]])
        return hit[0], "APOST", "#1", [r_to, r_from], [float(fd.vals[r_to] + fd.vals[r_from]), 0.0]
    raise ValueError(f"unknown fault {fault!r}; choose from {', '.join(FAULTS)}")


def _spec_string(fault: str, opts: dict[str, str]) -> str:
    return ",".join(f"{k}={v}" for k, v in opts.items())


def _site_mde(
    cal: Calibration,
    rel: str,
    block: str,
    group: str,
    fd: FamilyData,
    rows: Sequence[int],
    candidate_runs: int,
    group_map: dict[str, str],
) -> tuple[float | None, ...]:
    """The single-field MDE (value units) of each changed key in the calibration."""
    head, sep, rest = group.partition("/")
    cal_group = group_map[head] + sep + rest if head in group_map else group
    calfile = cal.file(rel)
    fam = calfile.family(block, cal_group) if calfile is not None else None
    if fam is None:
        return tuple(None for _ in rows)
    mde = cal.mde(fam, candidate_runs)
    out: list[float | None] = []
    for r in rows:
        label, index = key_label(fd.labels, fd.kmat[r].tolist())
        if label not in mde.labels:
            out.append(None)
            continue
        probe = np.full((1, mde.kmat.shape[1]), PAD, dtype=np.int64)
        probe[0, 0] = mde.labels.index(label)
        probe[0, 1 : 1 + len(index)] = index
        hit = int(match_rows(mde.kmat, probe)[0])
        out.append(float(mde.absolute[hit]) if hit >= 0 else None)
    return tuple(out)


def list_sites(
    ex: RunExtract,
    fault: str,
    opts: dict[str, str] | None = None,
    *,
    cal: Calibration | None = None,
    candidate_runs: int = 1,
    group_map: dict[str, str] | None = None,
) -> list[Site]:
    """``max`` and ``mid`` sites of a fault at every energy (G5 injects at all of them).

    With a calibration each site also carries the MDE of its changed keys and the size of the
    change in units of it (G5 records where the fault lies relative to the MDE).
    """
    base = dict(opts or {})
    if fault in ("yield2pct", "isomer"):
        energies = sorted({(f[2], f[1].split("/")[0]) for f in _endf_families(ex, base)})
        tapes = len({t for _, t in energies}) > 1
        steps = [(e, t) for e, t in energies]
    else:
        steps = [(e, "") for _, e in _dmp_apost(ex)]
        tapes = False
    sites: list[Site] = []
    for energy, tape in steps:
        for which in ("max", "mid"):
            spec = {
                **base,
                "E": f"{energy:.12g}",
                ("bin" if fault == "massbin" else "nuclide"): which,
            }
            if tapes:
                spec["tape"] = tape
            try:
                rel, block, group, rows, after = _resolve(ex, fault, spec)
            except ValueError:
                continue
            data = ex.file(rel)
            assert data is not None
            fd = data.get(block, group)
            assert fd is not None
            before = tuple(float(fd.vals[r]) for r in rows)
            mde: tuple[float | None, ...] = ()
            ratio: tuple[float | None, ...] = ()
            if cal is not None:
                mde = _site_mde(cal, rel, block, group, fd, rows, candidate_runs, group_map or {})
                ratio = tuple(
                    abs(a - b) / m if m else None
                    for a, b, m in zip(after, before, mde, strict=True)
                )
            sites.append(
                Site(
                    fault, _spec_string(fault, spec), rel, block, group,
                    tuple(_key(fd, r) for r in rows), before, tuple(after), mde, ratio,
                )
            )  # fmt: skip
    return sites


def inject(ex: RunExtract, fault: str, spec: str, out: Path, cache_note: str = "") -> Injection:
    """Write the extract of ``ex`` with one fault applied to ``out``."""
    opts = parse_spec(spec)
    rel, block, group, rows, after = _resolve(ex, fault, opts)
    data = ex.file(rel)
    assert data is not None
    fd = data.get(block, group)
    assert fd is not None
    before = [float(fd.vals[r]) for r in rows]
    keys = [_key(fd, r) for r in rows]
    fam = data.layout.families[data.layout.index[block, group]]
    absolute = [fam.voff + r for r in rows]
    new_vals = np.array(data.vals, copy=True)
    for at, value in zip(absolute, after, strict=True):
        new_vals[at] = value
    entry = ex.entries[rel]
    if out.exists():
        shutil.rmtree(out)
    for sub in ("layouts", "vals", "text"):
        (out / sub).mkdir(parents=True)
    for e in ex.manifest["files"]:
        if e.get("unparsed"):
            continue
        for suffix in (".k.npy", ".t.npy", ".json"):
            name = f"{e['layout']}{suffix}"
            _link(ex.root / "layouts" / name, out / "layouts" / name)
        if e["rel"] != rel:
            _link(ex.root / "vals" / f"{e['idx']}.npy", out / "vals" / f"{e['idx']}.npy")
        text = ex.root / "text" / f"{e['idx']}.json"
        if text.is_file():
            _link(text, out / "text" / f"{e['idx']}.json")
    np.save(out / "vals" / f"{entry['idx']}.npy", new_vals)
    record = Injection(fault, spec, rel, block, group, keys, before, after)
    manifest = dict(ex.manifest)
    manifest["injection"] = record.to_json()
    manifest["derived_from"] = ex.manifest.get("fingerprint")
    manifest["fingerprint"] = hashlib.sha256(
        json.dumps([ex.manifest.get("fingerprint"), record.to_json()], sort_keys=True).encode()
    ).hexdigest()
    manifest["version"] = EXTRACT_VERSION
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1, sort_keys=True))
    return record


def _link(src: Path, dst: Path) -> None:
    if dst.exists():
        return
    try:
        os.link(src, dst)
    except OSError:
        shutil.copy2(src, dst)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m compare.inject", description=__doc__)
    parser.add_argument("--run", required=True, help="run directory, capture id or extract dir")
    parser.add_argument("--fault", required=True, choices=FAULTS)
    parser.add_argument("--at", help="site, see the module docstring")
    parser.add_argument("--out", type=Path, help="extract directory to write")
    parser.add_argument("--factor", type=float, help="yield2pct: multiplier (default 1.02)")
    parser.add_argument("--list-sites", action="store_true", help="print max/mid sites per energy")
    parser.add_argument("--calibration", help="with --list-sites: add the MDE of each site")
    parser.add_argument("--candidate-runs", type=int, default=1, help="candidate runs for the MDE")
    parser.add_argument(
        "--group-map", action="append", default=[], metavar="FROM=TO",
        help="with --calibration: the run's group FROM is the calibration's TO (tape2=tape1)",
    )  # fmt: skip
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    args = parser.parse_args(argv)
    try:
        ex = load_extract(args.run, args.cache)
        if args.list_sites:
            base = parse_spec(args.at) if args.at else {}
            gmap = dict(item.partition("=")[::2] for item in args.group_map)
            cal = Calibration.open(args.calibration) if args.calibration else None
            for site in list_sites(
                ex, args.fault, base, cal=cal, candidate_runs=args.candidate_runs, group_map=gmap
            ):
                print(json.dumps(site.__dict__, sort_keys=True))
            return 0
        if not args.at or not args.out:
            parser.error("--at and --out are required (or use --list-sites)")
        spec = args.at + (f",factor={args.factor}" if args.factor is not None else "")
        record = inject(ex, args.fault, spec, args.out)
    except (OSError, ValueError, KeyError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(record.to_json(), sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
