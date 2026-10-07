# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""fbdef: symbol definitions and references, checked against facts from planning."""

from __future__ import annotations

import pytest

from tools.fbsrc import fbdef
from tools.fbsrc.common import basic_source_files
from tools.fbsrc.fbdef import (
    find_definitions,
    find_references,
    load_index,
    scan_declarations,
    strip_comments,
)


def _definition_sites(name: str) -> list[tuple[str, str, int]]:
    return [(t.kind, t.path, t.line) for t in find_definitions(name) if t.role == "def"]


def test_index_covers_all_38_basic_files() -> None:
    files = basic_source_files()
    assert len(files) == 38
    assert {t.path for t in load_index()} <= {p.name for p in files}


@pytest.mark.parametrize(
    ("name", "kind", "site"),
    [
        ("PGauss", "function", ("GEF.bas", 17956)),
        ("calcstart", "label", ("GEF.bas", 4811)),
        ("E_tunn", "variable", ("GEF.bas", 791)),
    ],
)
def test_planning_definitions(name: str, kind: str, site: tuple[str, int]) -> None:
    assert _definition_sites(name) == [(kind, *site)]
    assert _definition_sites(name.upper()) == _definition_sites(name.lower())


def test_declarations_are_reported_separately() -> None:
    tags = find_definitions("pgauss")
    assert [(t.role, t.line) for t in tags] == [("def", 17956), ("decl", 676)]


def test_index_corrections_for_ctags_gaps() -> None:
    # Missed by ctags: Static, Const (tagged as "As"), ReDim-only arrays, #Define.
    assert _definition_sites("E_MIN") == [("variable", "GEF.bas", 16662)]
    assert _definition_sites("pi") == [("constant", "GEF.bas", 760)]
    assert [(t.role, t.path, t.line) for t in find_definitions("_EGamma")] == [
        ("redim", "Spectra.bas", 1496)
    ]
    assert _definition_sites("Compilationstamp") == [("macro", "GEF.bas", 17)]
    assert find_definitions("As") == []
    # ctags reads "/' Definition of Emode values: '/" as a label; it must be gone.
    assert not any(t.path == "GEF.bas" and t.line == 5534 for t in load_index())


def test_references_are_case_insensitive_and_skip_comments() -> None:
    upper = find_references("E_MIN")
    assert upper == find_references("e_min")
    lines = {(r.path, r.line) for r in upper}
    assert {("GEF.bas", 16662), ("GEF.bas", 16682), ("GEF.bas", 16806)} <= lines
    delta = {(r.path, r.line) for r in find_references("Delta_E_Q")}
    assert ("GEF.bas", 8392) in delta
    assert ("GEF.bas", 8386) not in delta  # only inside a ' comment there
    # whole words only: _Egamma is not a reference to Egamma
    egamma = {(r.path, r.line) for r in find_references("Egamma")}
    assert ("GEF.bas", 9417) in egamma
    assert ("CLEARspectra.bas", 379) not in egamma  # "_Egamma(I) = 0"


def test_strip_comments() -> None:
    lines = [
        "x = 1 ' comment E_min",
        "Print \"it's E_min\" ' trailing",
        "a = 2 /' block E_min '/ + b",
        "/' multi",
        "  E_min still comment /' nested '/",
        "'/ c = 3",
        "Rem E_min",
        "If a Then Rem E_min",
        'Print !"esc\\"aped" \' E_min',
    ]
    code = strip_comments(lines)
    assert code[0] == "x = 1 "
    assert code[1] == 'Print "it\'s E_min" '
    assert code[2].replace(" ", "") == "a=2+b"
    assert code[3].strip() == "" and code[4].strip() == ""
    assert code[5].strip() == "c = 3"
    assert code[6] == "" and code[7] == "If a Then "
    assert code[8] == 'Print !"esc\\"aped" '


def test_scan_declarations() -> None:
    code = [
        "Static Shared As String C_GEF_Version",
        "Static As Single E_EXC_TRUE,E_EXC_ISO",
        "Static Shared CElement(1 To 120)   As String",
        "Const As Single pi = 3.14159",
        "ReDim Shared _EGamma(1000) As Double",
        "#define B_delayed",
        "x = 1 : Static As Integer I_MAT",
    ]
    found = [(t.name, t.kind, t.line, t.role) for t in scan_declarations("t.bas", code)]
    assert found == [
        ("C_GEF_Version", "variable", 1, "def"),
        ("E_EXC_TRUE", "variable", 2, "def"),
        ("E_EXC_ISO", "variable", 2, "def"),
        ("CElement", "variable", 3, "def"),
        ("pi", "constant", 4, "def"),
        ("_EGamma", "variable", 5, "redim"),
        ("B_delayed", "macro", 6, "def"),
        ("I_MAT", "variable", 7, "def"),
    ]


def test_cli(capsys: pytest.CaptureFixture[str]) -> None:
    assert fbdef.main(["pgauss"]) == 0
    out = capsys.readouterr().out
    assert out.splitlines()[0].startswith("GEF.bas:17956  function")
    assert fbdef.main(["E_min", "--refs"]) == 0
    out = capsys.readouterr().out
    assert "GEF.bas:16806: IF Ei-Sn <= E_MIN THEN" in out
    assert fbdef.main(["NoSuchSymbolAnywhere"]) == 1
