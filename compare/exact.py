# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Exact comparison of two observable tables (M2.3).

    python3 -m compare.exact <runA> <runB> [--ulp N] [--json OUT]

Rules: a float equals another only when the bit patterns match (so ``-0.0 != 0.0`` and a NaN
equals a NaN only with the same payload); with ``ulp > 0`` two finite or infinite floats are
equal when their distance in the total order of representable values is at most ``ulp``
(``-0.0`` and ``0.0`` are one step apart). ``Single`` values (from probes) are measured in
binary32 steps, everything else in binary64 steps. ``ulp_by_label`` overrides the tolerance for
keys with a given label. Ints and strs compare with ``==``; values of different kinds differ.

Exit status: 0 identical, 1 different, 2 error.
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from compare.loader import load_run
from compare.model import Family, Key, ObservableTable, Value
from compare.parsers.probe import Single

__all__ = ["ExactReport", "FamilySummary", "Mismatch", "compare_exact", "main", "ulp_distance"]

_SIGN64 = 1 << 63
_SIGN32 = 1 << 31


def _ordered64(x: float) -> tuple[int, int]:
    bits: int = struct.unpack("<Q", struct.pack("<d", x))[0]
    return bits, (-(bits & ~_SIGN64) - 1 if bits & _SIGN64 else bits)


def _ordered32(x: float) -> tuple[int, int]:
    bits: int = struct.unpack("<I", struct.pack("<f", x))[0]
    return bits, (-(bits & ~_SIGN32) - 1 if bits & _SIGN32 else bits)


def ulp_distance(a: float, b: float, *, single: bool = False) -> int | None:
    """Distance in representable values (binary32 if ``single``); None if either is NaN."""
    if math.isnan(a) or math.isnan(b):
        return None
    ordered = _ordered32 if single else _ordered64
    return abs(ordered(a)[1] - ordered(b)[1])


@dataclass(frozen=True, slots=True)
class Mismatch:
    key: Key
    a: Value
    b: Value
    ulp64: int | None = None
    ulp32: int | None = None


@dataclass
class FamilySummary:
    compared: int = 0
    mismatched: int = 0
    only_a: int = 0
    only_b: int = 0
    first: Mismatch | None = None
    max_ulp: int = 0


@dataclass
class ExactReport:
    compared: int = 0
    only_in_a: list[Key] = field(default_factory=lambda: [])
    only_in_b: list[Key] = field(default_factory=lambda: [])
    mismatches: list[Mismatch] = field(default_factory=lambda: [])
    families: dict[Family, FamilySummary] = field(default_factory=lambda: {})
    unparsed_only_a: list[str] = field(default_factory=lambda: [])
    unparsed_only_b: list[str] = field(default_factory=lambda: [])

    @property
    def identical(self) -> bool:
        return not (
            self.only_in_a
            or self.only_in_b
            or self.mismatches
            or self.unparsed_only_a
            or self.unparsed_only_b
        )

    def first_difference(self, family: Family) -> Mismatch | None:
        return self.families[family].first if family in self.families else None

    def differing_families(self) -> list[Family]:
        return [f for f, s in self.families.items() if s.mismatched or s.only_a or s.only_b]


def _compare_values(key: Key, a: Value, b: Value, tol: int) -> Mismatch | None:
    if isinstance(a, float) and isinstance(b, float):
        single = isinstance(a, Single) and isinstance(b, Single)
        d64 = ulp_distance(a, b)
        if single:
            d32 = ulp_distance(a, b, single=True)
            same = d32 is not None and d32 <= tol
            if tol == 0:
                same = _ordered32(a)[0] == _ordered32(b)[0]
            return None if same else Mismatch(key, a, b, d64, d32)
        same = d64 is not None and d64 <= tol
        if tol == 0:
            same = _ordered64(a)[0] == _ordered64(b)[0]
        return None if same else Mismatch(key, a, b, d64, None)
    if type(a) is type(b) and a == b:
        return None
    return Mismatch(key, a, b)


def compare_exact(
    a: ObservableTable,
    b: ObservableTable,
    ulp: int = 0,
    ulp_by_label: Mapping[str, int] | None = None,
) -> ExactReport:
    """Compare two tables key by key; see the module docstring for the rules."""
    report = ExactReport()
    overrides = ulp_by_label or {}

    def summary(key: Key) -> FamilySummary:
        return report.families.setdefault(key.family, FamilySummary())

    for key, va in a.items():
        vb = b.values.get(key)
        if vb is None:
            report.only_in_a.append(key)
            summary(key).only_a += 1
            continue
        report.compared += 1
        fam = summary(key)
        fam.compared += 1
        miss = _compare_values(key, va, vb, overrides.get(key.label, ulp))
        if miss is not None:
            report.mismatches.append(miss)
            fam.mismatched += 1
            fam.first = fam.first or miss
            dist = miss.ulp32 if miss.ulp32 is not None else miss.ulp64
            fam.max_ulp = max(fam.max_ulp, dist or 0)
    for key in b.values:
        if key not in a.values:
            report.only_in_b.append(key)
            summary(key).only_b += 1
    report.unparsed_only_a = sorted(set(a.unparsed) - set(b.unparsed))
    report.unparsed_only_b = sorted(set(b.unparsed) - set(a.unparsed))
    return report


# --------------------------------------------------------------------------- reporting

_LISTED = 1000


def _jsonable(value: Value) -> Any:
    if isinstance(value, float) and not math.isfinite(value):
        return repr(value)
    return value


def _key_json(key: Key) -> dict[str, Any]:
    return {
        "file": key.file,
        "block": key.block,
        "group": key.group,
        "label": key.label,
        "index": list(key.index),
    }


def _mismatch_json(m: Mismatch) -> dict[str, Any]:
    return {
        "key": _key_json(m.key),
        "a": _jsonable(m.a),
        "b": _jsonable(m.b),
        "ulp64": m.ulp64,
        "ulp32": m.ulp32,
    }


def report_json(report: ExactReport) -> dict[str, Any]:
    """JSON-ready dict; listings are capped at 1000 entries (totals are exact)."""
    return {
        "identical": report.identical,
        "compared": report.compared,
        "n_only_in_a": len(report.only_in_a),
        "n_only_in_b": len(report.only_in_b),
        "n_mismatches": len(report.mismatches),
        "only_in_a": [_key_json(k) for k in report.only_in_a[:_LISTED]],
        "only_in_b": [_key_json(k) for k in report.only_in_b[:_LISTED]],
        "mismatches": [_mismatch_json(m) for m in report.mismatches[:_LISTED]],
        "unparsed_only_a": report.unparsed_only_a,
        "unparsed_only_b": report.unparsed_only_b,
        "families": [
            {
                "file": f.file,
                "block": f.block,
                "group": f.group,
                "compared": s.compared,
                "mismatched": s.mismatched,
                "only_a": s.only_a,
                "only_b": s.only_b,
                "max_ulp": s.max_ulp,
                "first": _mismatch_json(s.first) if s.first else None,
            }
            for f, s in report.families.items()
            if s.mismatched or s.only_a or s.only_b
        ],
    }


def format_report(report: ExactReport, limit: int = 20) -> str:
    lines = [
        f"compared {report.compared} keys: {len(report.mismatches)} mismatches, "
        f"{len(report.only_in_a)} only in A, {len(report.only_in_b)} only in B"
    ]
    lines += [f"unparsed only in A: {p}" for p in report.unparsed_only_a]
    lines += [f"unparsed only in B: {p}" for p in report.unparsed_only_b]
    families = report.differing_families()
    lines.append(f"{len(families)} differing families")
    for fam in families[:limit]:
        s = report.families[fam]
        text = (
            f"  {fam.file} | {fam.block} | {fam.group}: {s.mismatched} mismatched, "
            f"{s.only_a} only A, {s.only_b} only B"
        )
        if s.first:
            text += f"; first: {s.first.key.label} {list(s.first.key.index)}"
            text += f" A={s.first.a!r} B={s.first.b!r}"
            if s.first.ulp64 is not None:
                text += f" ulp64={s.first.ulp64}"
            if s.first.ulp32 is not None:
                text += f" ulp32={s.first.ulp32}"
        lines.append(text)
    if len(families) > limit:
        lines.append(f"  ... {len(families) - limit} more families")
    return "\n".join(lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="compare.exact", description="Exact comparison of runs")
    parser.add_argument("run_a", type=Path)
    parser.add_argument("run_b", type=Path)
    parser.add_argument("--ulp", type=int, default=0, help="tolerance in ULPs (default 0)")
    parser.add_argument("--json", type=Path, default=None, metavar="OUT")
    try:
        args = parser.parse_args(argv)
    except SystemExit as exc:
        return 2 if exc.code else 0
    run_a: Path = args.run_a
    run_b: Path = args.run_b
    ulp: int = args.ulp
    out: Path | None = args.json
    if ulp < 0:
        print("error: --ulp must be >= 0", file=sys.stderr)
        return 2
    try:
        report = compare_exact(load_run(run_a), load_run(run_b), ulp=ulp)
        if out is not None:
            out.write_text(json.dumps(report_json(report), indent=1) + "\n", encoding="utf-8")
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    print(format_report(report))
    return 0 if report.identical else 1


if __name__ == "__main__":
    sys.exit(main())
