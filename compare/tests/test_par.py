# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for compare.parsers.par: synthetic files and the real ``*.par`` files (gate G1)."""

from __future__ import annotations

from pathlib import Path

import pytest

from compare.model import Key, ObservableTable
from compare.parsers import ParseError, par

_ROOT = Path(__file__).resolve().parents[2]
_TEST_RUN = _ROOT / "validation" / "test_run"
_CAPTURES = _ROOT / "validation" / "reference_store" / "captures"

_HEADER = """\
*
* This file provides the values of the disturbed parameters
* which are used for the calculation of uncertainties,
* variances and correlations.
* ~
* Output written on 30.12.1899, 00:00:00
* ~
* Calculation for the nucleus Z =   86 , A =  215
* formed by (n,f) with En =  {en} MeV.
* Spin of target nucleus =  0.5
*
""".replace("~", "")

_SET = """\
* Perturbed parameter set #{k}
*
P_DZ_Mean_S1 =              -0.3755407
P_corr_S1 =                 -0.05473639
P_att_rel =                  1
""".replace("~", "")

_SEP = """\
*
""".replace("~", "")


def _step(en: str, sets: int = 2) -> str:
    body = ""
    for k in range(1, sets + 1):
        body += (_HEADER.format(en=en) if k == 1 else _SEP) + _SET.format(k=k)
    return body


def test_roundtrip_synthetic() -> None:
    text = _step("0.1") + _step("0.2")
    assert par.render(par.parse_text(text)) == text
    assert par.render(par.parse_text(text.rstrip("\n"))) == text.rstrip("\n")
    crlf = text.replace("\n", "\r\n")
    assert par.render(par.parse_text(crlf)) == crlf
    odd = text.replace("P_att_rel =                  1\n", "P_att_rel =  1   \n")
    assert par.render(par.parse_text(odd)) == odd
    trailing = text + "*\n* trailing remark\n"
    assert par.render(par.parse_text(trailing)) == trailing


def test_structure() -> None:
    f = par.parse_text(_step("0.1") + _step("0.2", 3))
    assert [s.number for s in f.sets] == [1, 2, 1, 2, 3]
    assert [s.is_step_start for s in f.sets] == [True, False, True, False, False]
    assert [p.name for p in f.sets[0].params] == ["P_DZ_Mean_S1", "P_corr_S1", "P_att_rel"]


def test_observables_synthetic(tmp_path: Path) -> None:
    p = tmp_path / "GEF_86_215_n.par"
    p.write_text(_step("2.53e-08") + _step("0.1") + _step("2.53e-08"))
    rel = "work/tmp/GEF_86_215_n.par"
    obs = dict(par.observables(p, rel))
    g1, g2, g3 = "E=2.53e-08MeV#1", "E=0.1MeV#1", "E=2.53e-08MeV#2"
    for g in (g1, g2, g3):
        assert obs[Key(rel, "params", g, "P_DZ_Mean_S1", (1,))] == -0.3755407
        assert obs[Key(rel, "params", g, "P_att_rel", (2,))] == 1.0
        assert obs[Key(rel, "header", g, "Z")] == 86
        assert obs[Key(rel, "header", g, "A")] == 215
        assert obs[Key(rel, "header", g, "spin")] == 0.5
    assert obs[Key(rel, "header", g1, "En")] == 2.53e-8
    assert obs[Key(rel, "header", g2, "En")] == 0.1
    # the 1899 time stamp is data, not a mask
    assert obs[Key(rel, "header", g1, "text", (6,))] == "* Output written on 30.12.1899, 00:00:00"
    # bare "*" lines and the set marker are not emitted
    assert Key(rel, "header", g1, "text", (1,)) not in obs
    assert not any(isinstance(v, str) and "Perturbed parameter" in v for v in obs.values())


def test_repeated_parameter_name(tmp_path: Path) -> None:
    p = tmp_path / "x.par"
    p.write_text(_step("0.1", 1) + "P_att_rel =                  2\n")
    obs = dict(par.observables(p, "f"))
    assert obs[Key("f", "params", "E=0.1MeV#1", "P_att_rel", (1,))] == 1.0
    assert obs[Key("f", "params", "E=0.1MeV#1", "P_att_rel", (1, 2))] == 2.0


def test_errors() -> None:
    with pytest.raises(ParseError, match=r"a\.par:2: parameter line outside a parameter set"):
        par.parse_text("*\nP =  1\n", "a.par")
    with pytest.raises(ParseError, match=r"a\.par:4: not a 'NAME = value' line"):
        par.parse_text("*\n* Perturbed parameter set #1\n*\nbroken line\n", "a.par")
    with pytest.raises(ParseError, match=r"a\.par:4: value is not a number"):
        par.parse_text("*\n* Perturbed parameter set #1\n*\nP =  abc\n", "a.par")


@pytest.mark.validation
def test_roundtrip_real_files() -> None:
    files = [
        *sorted(_TEST_RUN.glob("tmp/*.par")),
        *sorted(_CAPTURES.glob("*/work/tmp/*.par")),
    ]
    if not _TEST_RUN.is_dir():
        pytest.skip("validation/test_run is not available")
    assert len(files) >= 10
    bad = [str(p) for p in files if par.roundtrip(p) != p.read_bytes()]
    assert bad == []


@pytest.mark.validation
def test_real_file_observables() -> None:
    path = _TEST_RUN / "tmp" / "GEF_86_215_n.par"
    if not path.is_file():
        pytest.skip("validation/test_run is not available")
    parsed = par.read(path)
    assert len(parsed.sets) == 60 * 31
    tb = ObservableTable()
    tb.extend(par.observables(path, "work/tmp/GEF_86_215_n.par"))
    params = {k.family for k in tb if k.block == "params"}
    assert len(params) == 60
    # thermal appears twice in the file (earlier partial run and the real run)
    assert {f.group for f in params if f.group.startswith("E=2.53e-08MeV")} == {
        "E=2.53e-08MeV#1",
        "E=2.53e-08MeV#2",
    }
    assert {k.index[0] for k in tb if k.block == "params"} == set(range(1, 32))


@pytest.mark.validation
def test_real_file_keys_stable_between_runs() -> None:
    a = _CAPTURES / "m1-g1-rn215-ref1" / "work" / "tmp" / "GEF_86_215_n.par"
    b = _CAPTURES / "m1-g23-rn215-n-a" / "work" / "tmp" / "GEF_86_215_n.par"
    if not (a.is_file() and b.is_file()):
        pytest.skip("reference-store captures are not available")
    ta, tb = ObservableTable(), ObservableTable()
    ta.extend(par.observables(a, "f"))
    tb.extend(par.observables(b, "f"))
    assert set(ta) == set(tb)
    assert len(ta) > 10000
