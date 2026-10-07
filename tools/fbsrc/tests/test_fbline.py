# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""fbline: BASIC line -> generated C, checked against facts established during planning."""

from __future__ import annotations

import re
from pathlib import Path

import pytest

from tools.fbsrc import fbline
from tools.fbsrc.common import FbsrcError
from tools.fbsrc.emit_c import Emission
from tools.fbsrc.fbline import lookup, parse_location, render, source_file_name


def test_parse_location() -> None:
    assert parse_location("GEF.bas:8392") == ("GEF.bas", 8392, 8392)
    assert parse_location("Spectra.bas:10-12") == ("Spectra.bas", 10, 12)
    for bad in ("GEF.bas", "GEF.bas:0", "GEF.bas:9-3", "GEF.bas:x"):
        with pytest.raises(FbsrcError):
            parse_location(bad)


def test_source_file_name_maps_absolute_include_paths(tmp_path: Path) -> None:
    src = tmp_path / "src"
    assert source_file_name("GEF.bas", src) == "GEF.bas"
    assert source_file_name(str(src / "Spectra.bas"), src) == "Spectra.bas"
    assert source_file_name("/elsewhere/ENDF.bas", src) == "ENDF.bas"


@pytest.mark.fbc
def test_8392_division_in_double_narrowed_to_float(emission: Emission) -> None:
    # E_intr_heavy = E_intr_heavy - I_A_heavy_sci/I_A_sci * (Delta_E_Q)
    result = lookup("GEF.bas", 8392)
    assert "I_A_heavy_sci/I_A_sci" in result.basic[0][1]
    texts = [s.text.strip() for s in result.statements()]
    assert len(texts) == 1
    stmt = texts[0]
    assert stmt.startswith("E_INTR_HEAVY$ = (float)(")
    assert re.search(r"\(double\)I_A_HEAVY_SCI\$\d+ / \(double\)I_A_SCI\$\d+", stmt)
    assert all(s.basic_line == 8392 for s in result.statements())


@pytest.mark.fbc
def test_9417_discards_egamma_call_with_comparison_argument(emission: Emission) -> None:
    # Egamma(Nspectrum) = Egamma(Nspectrum) + 1 : EGamma is a function, so this is a
    # comparison passed to a call whose result is thrown away.
    result = lookup("GEF.bas", 9417)
    texts = [s.text.strip() for s in result.statements()]
    discarded = [t for t in texts if re.fullmatch(r"EGAMMA\( .*==.* \);", t)]
    assert len(discarded) == 1
    assert re.search(r"\(double\)NSPECTRUM\$\d+ == \(vr\$\d+ \+ 0x1\.p\+0\)", discarded[0])
    assert not any("_EGAMMA$" in t for t in texts)  # the array is never stored to
    out = render(result)
    assert "EGAMMA( (int64)-((double)NSPECTRUM$20 == (vr1 + 0x1.p+0)) );" in out


@pytest.mark.fbc
@pytest.mark.parametrize(
    ("file", "line", "expected"),
    [("Spectra.bas", 1505, "double EGAMMA( int64 I_EKEV$1 )"), ("ENDF.bas", 1170, "B_IY$")],
)
def test_included_files_produce_c(emission: Emission, file: str, line: int, expected: str) -> None:
    result = lookup(file, line)
    assert result.file_compiled
    assert any(expected in s.text for s in result.statements())


@pytest.mark.fbc
def test_range_context_and_raw(emission: Emission) -> None:
    result = lookup("gef.bas", 8391, 8393, context=2)
    assert result.file == "GEF.bas"
    assert [n for n, _ in result.basic] == list(range(8389, 8396))
    assert {s.basic_line for s in result.statements()} == {8391, 8392, 8393}
    raw = render(result, raw=True)
    assert '#line 8392 "GEF.bas"' in raw
    assert "// E_intr_heavy = E_intr_heavy - I_A_heavy_sci/I_A_sci * (Delta_E_Q)" in raw
    default = render(result)
    assert "#line" not in default and "\t" not in default
    assert "float vr1 = MAX(" in default


@pytest.mark.fbc
def test_symbols_legend(emission: Emission) -> None:
    out = render(lookup("GEF.bas", 8392), symbols=True)
    legend = out.split("Symbols\n", 1)[1]
    assert re.search(r"E_INTR_HEAVY\$\s+E_intr_heavy\s+variable GEF\.bas:826", legend)
    assert re.search(r"I_A_HEAVY_SCI\$\d+\s+I_A_heavy_sci\s", legend)


@pytest.mark.fbc
def test_lines_without_c(emission: Emission) -> None:
    comment = lookup("GEF.bas", 8386)  # a ' comment line
    assert comment.regions == () and comment.file_compiled
    not_included = lookup("NucPropJEFF311.bas", 63)
    assert not_included.regions == () and not not_included.file_compiled
    with pytest.raises(FbsrcError):
        lookup("GEF.bas", 10**7)


@pytest.mark.fbc
def test_cli_exit_codes(emission: Emission, capsys: pytest.CaptureFixture[str]) -> None:
    assert fbline.main(["GEF.bas:9417"]) == fbline.EXIT_FOUND
    assert "EGAMMA(" in capsys.readouterr().out
    assert fbline.main(["GEF.bas:8386"]) == fbline.EXIT_NO_C
    assert fbline.main(["nosuchfile.bas:1"]) == fbline.EXIT_ERROR
