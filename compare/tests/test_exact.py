# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the exact comparator."""

from __future__ import annotations

import importlib.util
import math
import struct
from pathlib import Path

import pytest

from compare.exact import compare_exact, main, ulp_distance
from compare.loader import PARSER_NAMES
from compare.model import Key, ObservableTable, Value
from compare.parsers.probe import Single

_ROOT = Path(__file__).resolve().parents[2]
_CAPTURES = _ROOT / "validation" / "reference_store" / "captures"
_ALL_PARSERS = all(importlib.util.find_spec(f"compare.parsers.{n}") for n in PARSER_NAMES)


def _k(label: str, *index: int, block: str = "B") -> Key:
    return Key("f", block, "g", label, index)


def _table(**values: Value) -> ObservableTable:
    return ObservableTable.from_mapping({_k(n): v for n, v in values.items()})


def _next_up(x: float) -> float:
    bits: int = struct.unpack("<q", struct.pack("<d", x))[0]
    return struct.unpack("<d", struct.pack("<q", bits + 1))[0]


def test_identical() -> None:
    a = _table(x=1.5, n=3, s="t")
    report = compare_exact(a, _table(x=1.5, n=3, s="t"))
    assert report.identical
    assert report.compared == 3


def test_one_ulp() -> None:
    x = 0.1
    y = _next_up(x)
    a, b = _table(x=x), _table(x=y)
    assert ulp_distance(x, y) == 1
    report = compare_exact(a, b)
    assert not report.identical
    assert report.mismatches[0].ulp64 == 1
    assert compare_exact(a, b, ulp=1).identical
    assert compare_exact(a, b, ulp_by_label={"x": 1}).identical
    assert not compare_exact(a, b, ulp_by_label={"y": 1}).identical


def test_single_measured_in_binary32() -> None:
    a, b = _table(x=Single(1.0)), _table(x=Single(1.0000001192092896))
    report = compare_exact(a, b)
    assert report.mismatches[0].ulp32 == 1
    assert compare_exact(a, b, ulp=1).identical


def test_nan_and_signed_zero() -> None:
    nan = float("nan")
    other_nan = struct.unpack("<d", struct.pack("<Q", 0x7FF8000000000001))[0]
    assert compare_exact(_table(x=nan), _table(x=nan)).identical
    assert not compare_exact(_table(x=nan), _table(x=other_nan)).identical
    assert not compare_exact(_table(x=nan), _table(x=1.0), ulp=10).identical
    assert not compare_exact(_table(x=0.0), _table(x=-0.0)).identical
    assert ulp_distance(0.0, -0.0) == 1
    assert compare_exact(_table(x=0.0), _table(x=-0.0), ulp=1).identical
    assert ulp_distance(-1.0, -_next_up(1.0)) == 1
    assert ulp_distance(math.inf, math.inf) == 0


def test_kinds_differ() -> None:
    assert not compare_exact(_table(x=1), _table(x=1.0)).identical
    assert not compare_exact(_table(x="1"), _table(x=1)).identical


def test_only_in_a_b_and_first_difference() -> None:
    a = ObservableTable.from_mapping({_k("p", 1): 1, _k("p", 2): 2, _k("only_a"): 0})
    b = ObservableTable.from_mapping({_k("p", 1): 1, _k("p", 2): 9, _k("only_b"): 0})
    report = compare_exact(a, b)
    assert report.only_in_a == [_k("only_a")]
    assert report.only_in_b == [_k("only_b")]
    assert len(report.mismatches) == 1
    family = _k("p").family
    first = report.first_difference(family)
    assert first is not None
    assert (first.a, first.b) == (2, 9)
    assert report.families[family].compared == 2
    assert report.differing_families() == [family]


def test_unparsed_difference_is_not_identical() -> None:
    a, b = ObservableTable(), ObservableTable(unparsed=["x"])
    report = compare_exact(a, b)
    assert report.unparsed_only_b == ["x"]
    assert not report.identical


@pytest.mark.skipif(not _ALL_PARSERS, reason="not all parser modules exist yet")
def test_cli_text_runs(tmp_path: Path) -> None:
    runs: list[Path] = []
    for name, number in (("a", 1), ("b", 1), ("c", 2)):
        run = tmp_path / name
        (run / "work").mkdir(parents=True)
        (run / "stdout.log").write_text(f"value {number}\n")
        runs.append(run)
    out = tmp_path / "r.json"
    assert main([str(runs[0]), str(runs[1])]) == 0
    assert main([str(runs[0]), str(runs[2]), "--json", str(out)]) == 1
    assert '"n_mismatches": 1' in out.read_text()
    assert main([str(runs[0]), str(tmp_path / "nope")]) == 2
    assert main([str(runs[0])]) == 2


@pytest.mark.validation
@pytest.mark.skipif(not _ALL_PARSERS, reason="not all parser modules exist yet")
def test_store_same_seed_identical_and_reseed_different() -> None:
    names = ("m1-g23-rn215-n-a", "m1-g23-rn215-n-b", "m1-g23-rn215-r-a")
    if not all((_CAPTURES / n).is_dir() for n in names):
        pytest.skip("reference-store captures absent")
    n_a, n_b, r_a = (_CAPTURES / n for n in names)
    assert main([str(n_a), str(n_b)]) == 0
    assert main([str(n_a), str(r_a)]) == 1
