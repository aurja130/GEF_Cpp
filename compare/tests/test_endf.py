# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for compare.parsers.endf: synthetic edge formats and the real tapes (M2.2, gate G1)."""

from __future__ import annotations

import os
import random
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import pytest

from compare.model import Key, ObservableTable
from compare.parsers import ParseError
from compare.parsers import endf as ep

_ROOT = Path(__file__).resolve().parents[2]
_VALIDATION = _ROOT / "validation"
_TEST_RUN = _VALIDATION / "test_run"
_CAPTURES = _VALIDATION / "reference_store" / "captures"
_LIBRARY = _VALIDATION / "reference"

_MAT = 3332


def _f(x: float) -> str:
    """Independent ENDF float writer for the fixtures (one-digit exponent only)."""
    if x == 0:
        return " 0.000000+0"
    mant, exp = f"{abs(x):.6e}".split("e")
    sign = "-" if x < 0 else " "
    return f"{sign}{mant}{int(exp):+d}"


def _i(n: int) -> str:
    return f"{n:>11d}"


def _rec(fields: list[str], mat: int, mf: int, mt: int, ns: int) -> str:
    return "".join(fields).ljust(66) + f"{mat:4d}{mf:2d}{mt:3d}{ns:5d}"


def _yield_section(
    mt: int, spec: dict[str, list[tuple[int, int, float, float]]], le: int = 1
) -> list[str]:
    """``{energy text: [(ZA, FPS, Y, DY)]}`` as MF8 records, SEND included."""
    rows = [[_f(86214.0), _f(212.157), _i(le), _i(0), _i(0), _i(0)]]
    for energy, nucs in spec.items():
        rows.append([energy, _f(0), _i(7), _i(0), _i(4 * len(nucs)), _i(len(nucs))])
        vals: list[str] = []
        for za, st, y, dy in nucs:
            vals += [_f(float(za)), _f(float(st)), _f(y), _f(dy)]
        for k in range(0, len(vals), 6):
            chunk = vals[k : k + 6]
            rows.append(chunk + ["           "] * (6 - len(chunk)))
    lines = [_rec(r, _MAT, 8, mt, n) for n, r in enumerate(rows, 1)]
    lines.append(_rec([_f(0), _f(0), _i(0), _i(0), _i(0), _i(0)], _MAT, 8, 0, 99999))
    return lines


def _mt451() -> list[str]:
    text = ["TEXT LINE ONE".ljust(66), "second line".ljust(66)]
    dictionary = [(1, 451, 4, 0), (8, 454, 5, 0)]
    rows = [
        [_f(86214.0), _f(212.157), _i(-1), _i(1), _i(99), _i(1)],
        [_f(0), _f(1.0), _i(0), _i(0), _i(0), _i(6)],
        [_f(1.0), _f(3.0e7), _i(1), _i(0), _i(11), _i(1)],
        [_f(0), _f(0), _i(0), _i(0), _i(len(text)), _i(len(dictionary))],
    ]
    lines = [_rec(r, _MAT, 1, 451, n) for n, r in enumerate(rows, 1)]
    n = len(rows)
    for t in text:
        n += 1
        lines.append(t + f"{_MAT:4d}{1:2d}{451:3d}{n:5d}")
    for mf, mt, nc, mod in dictionary:
        n += 1
        lines.append(
            _rec(["           ", "           ", _i(mf), _i(mt), _i(nc), _i(mod)], _MAT, 1, 451, n)
        )
    lines.append(_rec([_f(0), _f(0), _i(0), _i(0), _i(0), _i(0)], _MAT, 1, 0, 99999))
    return lines


def _tape(sections: list[list[str]] | None = None, tpid: str = "TAPE IDENTIFICATION") -> list[str]:
    spec454 = {
        _f(2.53e-2): [(30080, 0, 1.0, 0.1), (30081, 0, 0.5, 0.05), (30081, 1, 0.25, 0.0)],
        _f(1.0e6): [(30080, 0, 0.9, 0.2)],
    }
    spec459 = {_f(2.53e-2): [(30080, 0, 1.2, 0.3)]}
    if sections is None:
        sections = [_mt451(), _yield_section(454, spec454), _yield_section(459, spec459)]
    lines = [tpid.ljust(66) + f"{_MAT:4d}{0:2d}{0:3d}{0:5d}"]
    for sec in sections:
        lines += sec
    lines.append(_rec([], _MAT, 0, 0, 0))
    lines.append(_rec([], 0, 0, 0, 0))
    lines.append(_rec([], -1, 0, 0, 0))
    return lines


def _text(lines: list[str], eol: str = "\n") -> str:
    return eol.join(lines) + eol


# --------------------------------------------------------------------------------------------
# number formats
# --------------------------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("value", "text"),
    [
        (0.0, " 0.000000+0"),
        (1.0, " 1.000000+0"),
        (2.53e-2, " 2.530000-2"),
        (-1.234567e-5, "-1.234567-5"),
        (86214.0, " 8.621400+4"),
        (9.999993e-7, " 9.999993-7"),
        (1.0e-9, " 1.000000-9"),
        (1.0e10, " 1.00000+10"),
        (3.0e7, " 3.000000+7"),
        (1.23456e-12, " 1.23456-12"),
        (-4.5e30, "-4.50000+30"),
        (9.9999999e9, " 1.00000+10"),
        (9.9999999e-10, " 1.000000-9"),
    ],
)
def test_format_float(value: float, text: str) -> None:
    assert ep.format_float(value) == text
    assert len(text) == 11


def test_format_parse_property() -> None:
    rng = random.Random(7)
    for _ in range(20000):
        x = rng.uniform(1.0, 9.9999) * 10.0 ** rng.randint(-40, 40) * rng.choice((-1, 1))
        text = ep.format_float(x)
        assert len(text) == 11
        value, canonical = ep._float_field(text)  # pyright: ignore[reportPrivateUsage]
        assert canonical
        assert value == pytest.approx(x, rel=6e-6)
        assert ep.format_float(value) == text


@pytest.mark.parametrize(
    ("text", "value"),
    [
        ("1.234567-5", 1.234567e-5),
        ("-1.234567-5", -1.234567e-5),
        (" 2.506200+4", 25062.0),
        ("1.5E+3", 1500.0),
        ("1.5E-3", 1.5e-3),
        ("           ", 0.0),
        ("         59", 59.0),
    ],
)
def test_parse_endf_float(text: str, value: float) -> None:
    assert ep.parse_endf_float(text) == pytest.approx(value, rel=1e-12, abs=0)


def test_parse_endf_float_rejects_garbage() -> None:
    with pytest.raises(ValueError, match="not an ENDF number"):
        ep.parse_endf_float("abc")


# --------------------------------------------------------------------------------------------
# structure and round trip
# --------------------------------------------------------------------------------------------


def test_synthetic_roundtrip_and_structure() -> None:
    text = _text(_tape())
    endf = ep.parse_text(text)
    assert ep.render(endf) == text
    (tape,) = endf.tapes
    kinds = [
        (type(e).__name__, getattr(e, "mf", None), getattr(e, "mt", None)) for e in tape.entries
    ]
    assert kinds == [
        ("Card", 0, 0),
        ("Section", 1, 451),
        ("Section", 8, 454),
        ("Section", 8, 459),
        ("Card", 0, 0),
        ("Card", 0, 0),
        ("Card", 0, 0),
    ]
    (sec,) = tape.sections(8, 454)
    assert isinstance(sec.content, ep.Yields)
    assert [lst.head.values[4] for lst in sec.content.lists] == [12, 4]
    assert sec.send is not None
    assert sec.content.lists[0].pad == ""  # 12 values fill two lines exactly
    assert sec.content.lists[1].pad == " " * 22


def test_crlf_and_missing_final_newline() -> None:
    lines = _tape()
    for text in (_text(lines, "\r\n"), "\n".join(lines)):
        assert ep.render(ep.parse_text(text)) == text


def test_empty_file() -> None:
    endf = ep.parse_text("")
    assert endf.tapes == []
    assert ep.render(endf) == ""


def test_noncanonical_fields_keep_their_text() -> None:
    spec = {_f(1.0e6): [(30080, 0, 1.0, 0.1), (30081, 0, 0.5, 0.05)]}
    lines = _yield_section(454, spec)
    # list data line 1: ZA as plain integer text, FPS blank, Y with a two-digit exponent for 1e-9,
    # DY negative zero, then a normal field and a 0.5 written as " 0.500000+0"
    lines[2] = _rec(
        ["         30", "           ", " 1.00000-09", "-0.000000+0", _f(30081.0), _f(0.0)],
        _MAT,
        8,
        454,
        3,
    )
    text = _text(_tape([lines]))
    endf = ep.parse_text(text)
    assert ep.render(endf) == text
    sec = endf.tapes[0].sections(8, 454)[0]
    assert isinstance(sec.content, ep.Yields)
    lst = sec.content.lists[0]
    assert lst.over == {0: "         30", 1: "           ", 2: " 1.00000-09", 3: "-0.000000+0"}
    assert lst.values[:3] == [30.0, 0.0, 1e-9]
    assert str(lst.values[3]) == "-0.0"
    tb = ObservableTable()
    tb.extend(ep.observables_from(endf, "f"))
    assert tb.values[Key("f", "MF8/MT454", "tape1/E=1.000000+6#1", "Y", (30, 0))] == 1e-9


def test_integer_in_float_field_and_blank_control() -> None:
    lines = _yield_section(454, {_f(1.0): [(30080, 0, 1.0, 0.0)]})
    # HEAD fields: AWR written as an integer, L1 blank
    lines[0] = _rec(
        [_f(86214.0), "        212", "           ", _i(0), _i(0), _i(0)], _MAT, 8, 454, 1
    )
    text = _text(_tape([lines]))
    endf = ep.parse_text(text)
    assert ep.render(endf) == text
    sec = endf.tapes[0].sections(8, 454)[0]
    assert isinstance(sec.content, ep.Yields)
    assert sec.content.head.over == {1: "        212", 2: "           "}
    assert sec.content.head.values[1] == 212.0


def test_noncanonical_ns_and_extra_cards() -> None:
    lines = _yield_section(454, {_f(1.0): [(30080, 0, 1.0, 0.0)]})
    lines[1] = lines[1][:75] + "   17"
    text = _text(_tape([lines]))
    endf = ep.parse_text(text)
    sec = endf.tapes[0].sections(8, 454)[0]
    assert set(sec.ns_over) == {1}
    assert ep.render(endf) == text
    # a section without SEND followed directly by another section; unknown MF3 kept as raw lines
    raw = [_rec(["ABC".ljust(11)], _MAT, 3, 1, n) for n in (1, 2)]
    text2 = _text(_tape([raw, _yield_section(454, {_f(1.0): [(30080, 0, 1.0, 0.0)]})]))
    endf2 = ep.parse_text(text2)
    assert ep.render(endf2) == text2
    assert isinstance(endf2.tapes[0].entries[1], ep.Section)
    assert endf2.tapes[0].entries[1].send is None
    assert isinstance(endf2.tapes[0].entries[1].content, ep.RawLines)


def test_multi_tape_and_fragment() -> None:
    two = _text(_tape() + _tape(tpid="SECOND"))
    endf = ep.parse_text(two)
    assert len(endf.tapes) == 2
    assert ep.render(endf) == two
    keys = {k.group for k, _ in ep.observables_from(endf, "f")}
    assert {"tape1", "tape2"} <= {g.split("/")[0] for g in keys}
    # fragment: SEND, MT459, SEND, FEND, MEND, no TEND
    frag_lines = [
        _rec([_f(0), _f(0), _i(0), _i(0), _i(0), _i(0)], 0, 8, 0, 99999),
        *_yield_section(459, {_f(1.0): [(30080, 0, 1.0, 0.0)]}),
        _rec([], 0, 0, 0, 0),
    ]
    frag = ep.parse_text(_text(frag_lines))
    assert len(frag.tapes) == 1
    assert ep.render(frag) == _text(frag_lines)
    assert isinstance(frag.tapes[0].entries[0], ep.Card)


# --------------------------------------------------------------------------------------------
# observables
# --------------------------------------------------------------------------------------------


def _table(text: str) -> dict[Key, object]:
    return dict(ep.observables_from(ep.parse_text(text), "f"))


def test_observables_content() -> None:
    obs = _table(_text(_tape()))
    g = "tape1/E=2.530000-2#1"
    assert obs[Key("f", "TPID", "tape1", "text")] == "TAPE IDENTIFICATION"
    assert obs[Key("f", "MF1/MT451", "tape1", "ZA")] == 86214.0
    assert obs[Key("f", "MF1/MT451", "tape1", "NWD")] == 2
    assert obs[Key("f", "MF1/MT451", "tape1", "TEXT", (2,))] == "second line"
    assert obs[Key("f", "MF1/MT451", "tape1", "NC", (8, 454))] == 5
    assert obs[Key("f", "MF8/MT454", "tape1", "LE")] == 1
    assert obs[Key("f", "MF8/MT454", g, "NFP")] == 3
    assert obs[Key("f", "MF8/MT454", g, "Y", (30080, 0))] == pytest.approx(1.0)
    assert obs[Key("f", "MF8/MT454", g, "DY", (30081, 1))] == 0.0
    assert obs[Key("f", "MF8/MT454", "tape1/E=1.000000+6#1", "Y", (30080, 0))] == pytest.approx(0.9)
    assert obs[Key("f", "MF8/MT459", g, "Y", (30080, 0))] == pytest.approx(1.2)
    assert not any(k.block == "MF8/MT454" and "MT459" in k.group for k in obs)


def test_observables_repeated_energies_and_nuclides() -> None:
    spec = [(30080, 0, 1.0, 0.1), (30080, 0, 2.0, 0.2)]
    lines = _yield_section(454, {_f(1.0): spec})
    # second LIST with the same energy label follows the first
    second = _yield_section(454, {_f(1.0): [(30081, 0, 3.0, 0.3)]})[1:-1]
    lines = lines[:-1] + [ln[:75] + f"{100 + n:5d}" for n, ln in enumerate(second)] + lines[-1:]
    obs = _table(_text(_tape([lines])))
    g1, g2 = "tape1/E=1.000000+0#1", "tape1/E=1.000000+0#2"
    assert obs[Key("f", "MF8/MT454", g1, "Y", (30080, 0))] == pytest.approx(1.0)
    assert obs[Key("f", "MF8/MT454", g1, "Y", (30080, 0, 2))] == pytest.approx(2.0)
    assert obs[Key("f", "MF8/MT454", g2, "Y", (30081, 0))] == pytest.approx(3.0)


def test_repeated_section_gets_group_suffix() -> None:
    spec = {_f(1.0): [(30080, 0, 1.0, 0.1)]}
    obs = _table(_text(_tape([_yield_section(454, spec), _yield_section(454, spec)])))
    groups = {k.group for k in obs if k.block == "MF8/MT454"}
    assert groups == {"tape1", "tape1/E=1.000000+0#1", "tape1#2", "tape1#2/E=1.000000+0#1"}


def test_observables_stable_across_values() -> None:
    a = _tape([_yield_section(454, {_f(1.0): [(30080, 0, 1.0, 0.1)]})])
    b = _tape([_yield_section(454, {_f(1.0): [(30080, 0, 2.0, 0.3)]})])
    ka, kb = _table(_text(a)), _table(_text(b))
    assert set(ka) == set(kb)
    assert ka != kb


# --------------------------------------------------------------------------------------------
# errors
# --------------------------------------------------------------------------------------------


def test_errors_name_file_and_line() -> None:
    good = _tape()
    short = [*good]
    short[3] = short[3][:70]
    with pytest.raises(ParseError, match=r"x\.dat:4: line has 70 characters"):
        ep.parse_text(_text(short), "x.dat")
    bad_ctl = [*good]
    bad_ctl[-3] = bad_ctl[-3][:66] + "33a2 1451    2"
    with pytest.raises(ParseError, match=rf"x\.dat:{len(good) - 2}: MAT/MF/MT"):
        ep.parse_text(_text(bad_ctl), "x.dat")
    with pytest.raises(ParseError, match="stray carriage return"):
        ep.parse_text("A\rB\n", "x.dat")


def test_list_errors() -> None:
    lines = _yield_section(454, {_f(1.0): [(30080, 0, 1.0, 0.1)]})
    lines[1] = _rec([_f(1.0), _f(0), _i(7), _i(0), _i(5), _i(1)], _MAT, 8, 454, 2)
    with pytest.raises(ParseError, match=r"y\.dat:3: LIST at E=1.000000\+0 has NPL=5 != 4\*NFP=4"):
        ep.parse_text(_text(_tape([lines])), "y.dat")
    trunc = _yield_section(454, {_f(1.0): [(30080, 0, 1.0, 0.1)] * 3})
    del trunc[-2]
    with pytest.raises(ParseError, match="truncated LIST"):
        ep.parse_text(_text(_tape([trunc])), "y.dat")
    garbage = _yield_section(454, {_f(1.0): [(30080, 0, 1.0, 0.1)]})
    garbage[2] = _rec(["abcdefghijk"] + ["           "] * 5, _MAT, 8, 454, 3)
    with pytest.raises(ParseError, match=r"y\.dat:\d+: not a number"):
        ep.parse_text(_text(_tape([garbage])), "y.dat")
    sec451 = _mt451()
    del sec451[-3]
    with pytest.raises(ParseError, match="MF1/MT451 announces"):
        ep.parse_text(_text(_tape([sec451])), "y.dat")


# --------------------------------------------------------------------------------------------
# real data (gate G1)
# --------------------------------------------------------------------------------------------


def _roundtrip_ok(path: str) -> tuple[str, bool]:
    p = Path(path)
    return path, ep.roundtrip(p) == p.read_bytes()


def _all_round_trip(files: list[Path], workers: int) -> list[str]:
    names = [str(p) for p in files]
    if workers <= 1:
        return [n for n, ok in map(_roundtrip_ok, names) if not ok]
    with ProcessPoolExecutor(workers) as pool:
        return [n for n, ok in pool.map(_roundtrip_ok, names, chunksize=4) if not ok]


def _workers() -> int:
    return max(1, min(8, (os.cpu_count() or 2) // 2))


@pytest.mark.validation
def test_roundtrip_library_tapes() -> None:
    files = sorted(_LIBRARY.glob("gefy_*_ENDF/*.dat"))
    if not files:
        pytest.skip("validation/reference is not available")
    assert len(files) == 382
    assert _all_round_trip(files, _workers()) == []


@pytest.mark.validation
def test_roundtrip_test_run_and_captures() -> None:
    files = [
        *sorted(_TEST_RUN.glob("ENDF/*.dat")),
        *sorted(_TEST_RUN.glob("tmp/CUMU*.dat")),
        *sorted(_CAPTURES.glob("*/work/ENDF/*.dat")),
        *sorted(_CAPTURES.glob("*/work/tmp/CUMU*.dat")),
    ]
    if not _TEST_RUN.is_dir():
        pytest.skip("validation/test_run is not available")
    assert len(files) >= 3
    assert _all_round_trip(files, _workers()) == []


@pytest.mark.validation
def test_test_run_tapes() -> None:
    path = _TEST_RUN / "ENDF" / "GEFY_86_214_n.dat"
    if not path.is_file():
        pytest.skip("validation/test_run is not available")
    endf = ep.read(path)
    assert len(endf.tapes) == 2
    energies = [
        len(s.content.lists)
        for t in endf.tapes
        for s in t.sections(8, 454)
        if isinstance(s.content, ep.Yields)
    ]
    assert energies == [1, 59]
    first = endf.tapes[0].entries[0]
    assert isinstance(first, ep.Card)
    assert first.body.startswith(" GEFY-10.1")
    tb = ObservableTable()
    tb.extend(ep.observables(path, "work/ENDF/GEFY_86_214_n.dat"))
    fams = {f for f in tb.families() if f.block == "MF8/MT454"}
    assert len({f.group for f in fams if f.group.startswith("tape2/")}) == 59


@pytest.mark.validation
def test_observable_keys_stable_between_runs() -> None:
    a = _CAPTURES / "m1-g1-rn215-ref1" / "work" / "ENDF" / "GEFY_86_214_n.dat"
    b = _CAPTURES / "m1-g23-rn215-n-a" / "work" / "ENDF" / "GEFY_86_214_n.dat"
    if not (a.is_file() and b.is_file()):
        pytest.skip("reference-store captures are not available")
    ta, tb = ObservableTable(), ObservableTable()
    ta.extend(ep.observables(a, "f"))
    tb.extend(ep.observables(b, "f"))
    for block in ("MF8/MT454", "MF8/MT459"):
        ka = {k for k in ta if k.block == block and k.label in ("Y", "DY")}
        kb = {k for k in tb if k.block == block and k.label in ("Y", "DY")}
        assert ka
        # the nuclide lists of two different seeds agree except for rare low-yield nuclides
        common = ka & kb
        assert len(common) > 0.95 * len(ka)
        assert any(ta.values[k] != tb.values[k] for k in common)
    # MF1 (header, description, dictionary) and every HEAD/LIST-head number have identical keys;
    # only the low-yield nuclide lists differ between seeds (GEF writes a nuclide above 1.5 events)
    assert {k for k in ta if k.block == "MF1/MT451"} == {k for k in tb if k.block == "MF1/MT451"}
    fa = {k.family for k in ta}
    fb = {k.family for k in tb}
    assert fa == fb
    heads = {k for k in ta if k.label in ("E", "NPL", "LE", "ZA")}
    assert heads - {k for k in tb} == set()


@pytest.mark.validation
def test_cumu_fragment_observables() -> None:
    path = _TEST_RUN / "tmp" / "CUMU2.dat"
    if not path.is_file():
        pytest.skip("validation/test_run is not available")
    tb = ObservableTable()
    tb.extend(ep.observables(path, "work/tmp/CUMU2.dat"))
    assert {k.block for k in tb} == {"MF8/MT459"}
    assert len({k.group for k in tb if k.label == "NFP"}) == 59
