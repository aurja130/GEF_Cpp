# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for compare.parsers.mvd: synthetic files and the real ``*_Single.mvd`` files (G1)."""

from __future__ import annotations

import os
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import pytest

from compare.model import Key, ObservableTable
from compare.parsers import ParseError, mvd

_ROOT = Path(__file__).resolve().parents[2]
_TEST_RUN = _ROOT / "validation" / "test_run"
_CAPTURES = _ROOT / "validation" / "reference_store" / "captures"

_HEADER = """\
* This file provides the multi-variate distributions of GEF
* yields, which form the raw data for determining covariance data
*
* Output written on 15.09.2026, 18:23:38
* ~
* Calculation for the nucleus Z =   86 , A =  215
* formed by (n,f) with En =  0.1 MeV.
* Spin of target nucleus =  0
*
""".replace("~", "")

_SET = """\
* Perturbed parameter set #{k}
*
* Set     Z         Y(Z)
*Z*
   {k}      26      0.04030
   {k}      28      1.57170
*
* Set         A              Y(A)             Y(A) ~
*                            pre-neutron      post-neutron
*A*
   {k}          63           0.00310          0.00310
*
* Set          A             Z            Y(A,Z)pre        Y(A,Z)post
*AZ*
 {k}             63            26            0.003100006      0.003100006
 {k}             64            26            0.009300019      0
*
*
* Perturbed parameter set #{k}
*
*
* Set          A             Z            Ycumu(A,Z) ~
*AZcumu*
 {k}             63            26            0.003100006
*
* Set          A             Z            Isomer       Ycumu(A,Z,I)
*AZIcumu*
* ~
 {k}             68            27            0             0.003208506
 {k}             68            27            1             0.006417013
* ~
 {k}             69            26            0             0.003100006
""".replace("~", "")


def _file(sets: int = 2) -> str:
    return _HEADER + "".join(_SET.format(k=k) for k in range(1, sets + 1))


def test_roundtrip_synthetic() -> None:
    text = _file()
    assert mvd.render(mvd.parse_text(text)) == text
    assert mvd.render(mvd.parse_text(text.rstrip("\n"))) == text.rstrip("\n")
    crlf = text.replace("\n", "\r\n")
    assert mvd.render(mvd.parse_text(crlf)) == crlf


def test_observables_synthetic(tmp_path: Path) -> None:
    p = tmp_path / "Z86_A215_n_E0.1MeV_Single.mvd"
    p.write_text(_file())
    rel = "work/tmp/" + p.name
    obs = dict(mvd.observables(p, rel))
    assert obs[Key(rel, "header", "#1", "Z")] == 86
    assert obs[Key(rel, "header", "#1", "A")] == 215
    assert obs[Key(rel, "header", "#1", "En")] == 0.1
    assert obs[Key(rel, "header", "#1", "spin")] == 0.0
    first = obs[Key(rel, "header", "#1", "text", (1,))]
    assert isinstance(first, str)
    assert first.startswith("* This file provides")
    assert not any("Output written" in str(v) for v in obs.values())  # stamp masked
    assert obs[Key(rel, "Z", "#1", "Y", (1, 26))] == 0.04030
    assert obs[Key(rel, "A", "#1", "Ypost", (2, 63))] == 0.00310
    assert obs[Key(rel, "AZ", "#1", "Ypre", (1, 64, 26))] == 0.009300019
    assert obs[Key(rel, "AZ", "#1", "Ypost", (1, 64, 26))] == 0.0
    assert obs[Key(rel, "AZcumu", "#1", "Ycumu", (2, 63, 26))] == 0.003100006
    assert obs[Key(rel, "AZIcumu", "#1", "Ycumu", (1, 68, 27, 1))] == 0.006417013
    assert (
        obs[Key(rel, "A", "#1", "columns", (1, 2))]
        == "*                            pre-neutron      post-neutron"
    )
    assert (
        obs[Key(rel, "AZcumu", "#1", "columns", (2, 1))]
        == "* Set          A             Z            Ycumu(A,Z) "
    )
    # the separator comments inside AZIcumu are not data and not columns
    assert not any(k.block == "AZIcumu" and k.label == "columns" and k.index[1] > 1 for k in obs)


def test_stamp_not_emitted_but_other_text_is(tmp_path: Path) -> None:
    a, b = tmp_path / "a.mvd", tmp_path / "b.mvd"
    a.write_text(_file(1))
    b.write_text(_file(1).replace("15.09.2026, 18:23:38", "01.01.2030, 00:00:01"))
    assert dict(mvd.observables(a, "f")) == dict(mvd.observables(b, "f"))
    c = tmp_path / "c.mvd"
    c.write_text(_file(1).replace("  0.1 MeV", "  0.2 MeV"))
    assert dict(mvd.observables(a, "f")) != dict(mvd.observables(c, "f"))


def test_repeated_identifier_and_second_header(tmp_path: Path) -> None:
    extra = "   1      26      0.5\n"
    text = _file(1).replace("   1      26      0.04030\n", "   1      26      0.04030\n" + extra)
    p = tmp_path / "d.mvd"
    p.write_text(text)
    obs = dict(mvd.observables(p, "f"))
    assert obs[Key("f", "Z", "#1", "Y", (1, 26))] == 0.0403
    assert obs[Key("f", "Z", "#1", "Y", (1, 26, 2))] == 0.5
    appended = tmp_path / "e.mvd"
    appended.write_text(_file(1) + _file(1))
    keys = set(dict(mvd.observables(appended, "f")))
    assert Key("f", "Z", "#2", "Y", (1, 26)) in keys
    assert mvd.roundtrip(appended) == appended.read_bytes()


def test_errors() -> None:
    with pytest.raises(ParseError, match=r"a\.mvd:3: data row before any table tag"):
        mvd.parse_text("*\n*\n   1  2  3\n", "a.mvd")
    with pytest.raises(ParseError, match=r"a\.mvd:2: unknown table tag"):
        mvd.parse_text("*\n*Q*\n", "a.mvd")
    with pytest.raises(ParseError, match=r"a\.mvd:2: table Z has 3 columns, row has 2"):
        mvd.parse_text("*Z*\n   1  2\n", "a.mvd")
    with pytest.raises(ParseError, match=r"a\.mvd:2: malformed number"):
        mvd.parse_text("*Z*\n   1  2  x\n", "a.mvd")


def _roundtrip_ok(path: str) -> bool:
    p = Path(path)
    return mvd.roundtrip(p) == p.read_bytes()


@pytest.mark.validation
def test_roundtrip_real_files() -> None:
    files = [
        *sorted(_TEST_RUN.glob("tmp/*_Single.mvd")),
        *sorted(_CAPTURES.glob("*/work/tmp/*_Single.mvd")),
    ]
    if not _TEST_RUN.is_dir():
        pytest.skip("validation/test_run is not available")
    assert len(files) >= 59
    names = [str(p) for p in files]
    with ProcessPoolExecutor(max(1, min(8, (os.cpu_count() or 2) // 2))) as pool:
        results = list(pool.map(_roundtrip_ok, names, chunksize=4))
    assert [n for n, ok in zip(names, results, strict=True) if not ok] == []


@pytest.mark.validation
def test_real_file_observables_and_stability() -> None:
    name = "Z86_A215_n_E18.5MeV_Single.mvd"
    a = _CAPTURES / "m1-g1-rn215-ref1" / "work" / "tmp" / name
    b = _CAPTURES / "m1-g23-rn215-n-a" / "work" / "tmp" / name
    if not (a.is_file() and b.is_file()):
        pytest.skip("reference-store captures are not available")
    ta, tb = ObservableTable(), ObservableTable()
    ta.extend(mvd.observables(a, "f"))
    tb.extend(mvd.observables(b, "f"))
    assert {k.block for k in ta} == {"header", "Z", "A", "AZ", "AZcumu", "AZIcumu"}
    assert {k for k in ta if k.block == "header"} == {k for k in tb if k.block == "header"}
    assert {k for k in ta if k.block == "Z"}
    assert {k.index[0] for k in ta if k.block == "Z"} == set(range(1, 32))
    assert any(ta.values[k] != tb.values[k] for k in ta if k.block == "Z" and k in tb.values)
    assert {k.family for k in ta} == {k.family for k in tb}
