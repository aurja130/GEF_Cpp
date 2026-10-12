# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for tools.fbsrc.fn_c_equiv: function and piece comparisons, and the CLI.

Hand-written C covers the comparison rules without fbc. Programs compiled with fbc (marker
``fbc``) cover real fbc output. The GEF test (``slow``) compares the real U_SHELL.
"""

from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path

import pytest

from tools.fbsrc.common import FbsrcError, read_source_lines
from tools.fbsrc.emit_c import Emission
from tools.fbsrc.fn_c_equiv import (
    EXIT_ERROR,
    EXIT_MISMATCH,
    EXIT_OK,
    EquivResult,
    PieceSpec,
    compare_function,
    compare_piece,
    main,
    parse_piece,
)
from tools.toolchain.fbc import GEF_SOURCE_DIR, FbcError, filter_fbc_stderr, resolve_fbc

GEF_BAS = GEF_SOURCE_DIR / "GEF.bas"
# U_SHELL is GEF.bas lines 16261-16271; the ShellMO declaration is line 1255.
U_SHELL_FIRST = 16261
U_SHELL_LAST = 16271
SHELL_MO_DECL = 1255
needs_source = pytest.mark.skipif(
    shutil.which("patch") is None or not GEF_BAS.is_file(),
    reason="needs GEF.bas and the patch tool",
)

PRELUDE_BAS = """\
Function PRELUDE(X As Single) As Single
    Dim As Single Y
    Y = X * 2.0
    PRELUDE = Y + 1.0
End Function
"""
MYFUNC_BAS = """\
Function MYFUNC(Z As Integer, A As Integer) As Single
    Dim As Integer N
    Dim As Single Res
    N = A - Z
    Res = N * 3.0 + Z
    If Res > 0.0 Then Res = 0.5 * Res
    MYFUNC = Res
End Function
"""

# Piece: lines 4-8 of PIECE_REF_BAS. As in the driver, the piece sits in a Sub: fbc emits
# different scope labels for module-level loops (observed: an extra label at Next).
PIECE_REF_BAS = """\
Dim Shared ACC As Single
Sub RunPiece()
    Dim As Integer I
    For I = 1 To 3
        Dim As Single Q
        Q = I * 1.5
        ACC = ACC + Q
    Next I
End Sub
ACC = 0.0
RunPiece()
Print ACC
"""
PIECE_SPEC = PieceSpec("piece.bi", "ref.bas", 4, 8)
PIECE_DRIVER_BAS = """\
Dim Shared ACC As Single
Sub RunPiece()
    Dim As Integer I
#include "piece.bi"
End Sub
ACC = 0.0
RunPiece()
Print ACC
"""


def _sample_c(temp: str, literal: str) -> str:
    """A MYFUNC definition as fbc -R -g writes it, with temporary ``temp`` and ``literal``."""
    return (
        "float MYFUNC( float X$1 )\n"
        '#line 3 "a.bas"\n'
        "{\n"
        '\t#line 4 "a.bas"\n'
        f"\tfloat {temp};\n"
        '\t#line 4 "a.bas"\n'
        f"\t{temp} = X$1 * {literal}f;\n"
        '\t#line 5 "a.bas"\n'
        f"\treturn {temp};\n"
        "}\n"
    )


def _piece_cut(text: str) -> str:
    """The BASIC lines PIECE_SPEC names, taken from ``text``, as an include file."""
    return "".join(
        line + "\n" for line in text.splitlines()[PIECE_SPEC.first - 1 : PIECE_SPEC.last]
    )


def _put(path: Path, text: str) -> Path:
    path.write_text(text, encoding="utf-8")
    return path


def _build(fbc: Path, directory: Path, stem: str, text: str, *flags: str) -> Path:
    """Write ``stem.bas`` into ``directory``, compile it with ``fbc -gen gcc -R``, and return
    the kept C path. ``flags`` are added to the command (``-g`` adds line directives)."""
    directory.mkdir(parents=True, exist_ok=True)
    _put(directory / f"{stem}.bas", text)
    proc = subprocess.run(
        [str(fbc), "-gen", "gcc", "-R", *flags, "-c", f"{stem}.bas"],
        cwd=directory,
        capture_output=True,
        text=True,
        check=False,
    )
    assert proc.returncode == 0, filter_fbc_stderr(proc.stderr)
    return directory / f"{stem}.c"


@pytest.fixture(scope="module")
def real_fbc() -> Path:
    try:
        return resolve_fbc()
    except FbcError as exc:
        pytest.skip(f"fbc unavailable: {exc}")


@pytest.fixture
def func_pair(real_fbc: Path, tmp_path: Path) -> tuple[Path, Path]:
    """(driver C, reference C) for MYFUNC. The reference also has PRELUDE first, so its
    temporaries are numbered differently from the driver's."""
    ref_c = _build(real_fbc, tmp_path / "ref", "ref", PRELUDE_BAS + "\n" + MYFUNC_BAS, "-g")
    drv_c = _build(real_fbc, tmp_path / "drv", "drv", MYFUNC_BAS + "\nPrint MYFUNC(1, 2)\n")
    return drv_c, ref_c


@pytest.fixture
def piece_pair(real_fbc: Path, tmp_path: Path) -> tuple[Path, Path, Path]:
    """(driver C, driver BAS, reference C) for PIECE_SPEC."""
    drv_dir = tmp_path / "drv"
    drv_dir.mkdir()
    _put(drv_dir / "piece.bi", _piece_cut(PIECE_REF_BAS))
    drv_c = _build(real_fbc, drv_dir, "drv", PIECE_DRIVER_BAS)
    ref_c = _build(real_fbc, tmp_path / "ref", "ref", PIECE_REF_BAS, "-g")
    return drv_c, drv_dir / "drv.bas", ref_c


def test_parse_piece_reads_fields() -> None:
    spec = parse_piece("piece.bi=GEF.bas:16980-17037")
    assert spec == PieceSpec("piece.bi", "GEF.bas", 16980, 17037)
    assert spec.label == "piece.bi = GEF.bas:16980-17037"


@pytest.mark.parametrize(
    "text",
    [
        "piece.bi GEF.bas 1-2",
        "piece.bi=GEF.bas:5-3",
        "piece.bi=GEF.bas:0-3",
        "=GEF.bas:1-2",
        "piece.bi=GEF.bas:1-2 ",
    ],
)
def test_parse_piece_rejects_malformed(text: str) -> None:
    with pytest.raises(FbsrcError, match="bad piece"):
        _ = parse_piece(text)


def test_summary_wording() -> None:
    ok = EquivResult("function F", ok=True, compared=3, unit="lines")
    bad = EquivResult("function F", ok=False, compared=3, unit="lines", diff="-a\n+b")
    assert ok.summary == "ok: function F (3 lines compared)"
    assert bad.summary == "MISMATCH: function F (3 lines compared)"


def test_function_renames_temporaries(tmp_path: Path) -> None:
    driver = _put(tmp_path / "drv.c", _sample_c("vr$3", "2.0"))
    gef = _put(tmp_path / "GEF.c", _sample_c("vr$7", "2.0"))
    result = compare_function(driver, gef, "MYFUNC")
    assert result.ok, result.diff
    assert result.compared == 6


def test_function_reports_difference(tmp_path: Path) -> None:
    driver = _put(tmp_path / "drv.c", _sample_c("vr$1", "2.0"))
    gef = _put(tmp_path / "GEF.c", _sample_c("vr$1", "3.0"))
    result = compare_function(driver, gef, "MYFUNC")
    assert not result.ok
    assert result.summary.startswith("MISMATCH: function MYFUNC")
    changed = result.diff.splitlines()
    assert "-vr$1 = X$1 * 2.0f;" in changed
    assert "+vr$1 = X$1 * 3.0f;" in changed


@pytest.mark.parametrize(
    ("text", "message"),
    [
        ("float MYFUNC( float X$1 );\n", "no definition of 'MYFUNC'"),
        (_sample_c("vr$1", "2.0") * 2, "has 2 definitions"),
        ("float MYFUNC( float X$1 )\nfloat Y$1;\n", "no column-0 '{'"),
        ("float MYFUNC( float X$1 )\n{\n\treturn X$1;\n", "no column-0 '}'"),
    ],
)
def test_function_definition_errors(tmp_path: Path, text: str, message: str) -> None:
    driver = _put(tmp_path / "drv.c", text)
    gef = _put(tmp_path / "GEF.c", _sample_c("vr$1", "2.0"))
    with pytest.raises(FbsrcError, match=re.escape(message)):
        _ = compare_function(driver, gef, "MYFUNC")


def test_cli_compares_functions(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    driver = _put(tmp_path / "drv.c", _sample_c("vr$3", "2.0"))
    gef = _put(tmp_path / "GEF.c", _sample_c("vr$7", "2.0"))
    argv = ["--driver-c", str(driver), "--gef-c", str(gef), "--function", "MYFUNC"]
    assert main(argv) == EXIT_OK
    assert "ok: function MYFUNC (6 lines compared)" in capsys.readouterr().out
    other = _put(tmp_path / "other.c", _sample_c("vr$7", "3.0"))
    argv = ["--driver-c", str(driver), "--gef-c", str(other), "--function", "MYFUNC"]
    assert main(argv) == EXIT_MISMATCH
    out = capsys.readouterr().out
    assert "MISMATCH: function MYFUNC" in out
    assert "-vr$1 = X$1 * 2.0f;" in out


def test_cli_setup_errors_exit_2(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    driver = _put(tmp_path / "drv.c", _sample_c("vr$1", "2.0"))
    gef = _put(tmp_path / "GEF.c", _sample_c("vr$1", "2.0"))
    missing = tmp_path / "missing.c"
    cases = [
        (
            ["--driver-c", str(driver), "--gef-c", str(gef), "--function", "NOSUCH"],
            "no definition of 'NOSUCH'",
        ),
        (
            ["--driver-c", str(missing), "--gef-c", str(gef), "--function", "MYFUNC"],
            "driver C not found",
        ),
        (
            ["--driver-c", str(driver), "--gef-c", str(missing), "--function", "MYFUNC"],
            "GEF C not found",
        ),
        (["--driver-c", str(driver), "--gef-c", str(gef), "--piece", "nonsense"], "bad piece"),
        (
            ["--driver-c", str(driver), "--gef-c", str(gef), "--piece", "piece.bi=ref.bas:4-8"],
            "driver source not found",
        ),
    ]
    for argv, message in cases:
        assert main(argv) == EXIT_ERROR
        assert message in capsys.readouterr().err


def test_cli_needs_a_selector(tmp_path: Path) -> None:
    driver = _put(tmp_path / "drv.c", "")
    gef = _put(tmp_path / "GEF.c", "")
    with pytest.raises(SystemExit) as exc:
        _ = main(["--driver-c", str(driver), "--gef-c", str(gef)])
    assert exc.value.code == 2


@pytest.mark.fbc
def test_function_matches_across_builds(func_pair: tuple[Path, Path]) -> None:
    driver_c, ref_c = func_pair
    result = compare_function(driver_c, ref_c, "MYFUNC")
    assert result.ok, result.diff
    assert result.summary.startswith("ok: function MYFUNC (")


@pytest.mark.fbc
def test_function_flags_changed_literal(
    real_fbc: Path, tmp_path: Path, func_pair: tuple[Path, Path]
) -> None:
    _, ref_c = func_pair
    altered = MYFUNC_BAS.replace("0.5 * Res", "0.6 * Res") + "\nPrint MYFUNC(1, 2)\n"
    driver_c = _build(real_fbc, tmp_path / "alt", "drv", altered)
    result = compare_function(driver_c, ref_c, "MYFUNC")
    assert not result.ok
    changed = result.diff.splitlines()
    assert any(line.startswith("-RES$1 = ") for line in changed), result.diff
    assert any(line.startswith("+RES$1 = ") for line in changed), result.diff


@pytest.mark.fbc
def test_function_missing_name_is_error(func_pair: tuple[Path, Path]) -> None:
    driver_c, ref_c = func_pair
    with pytest.raises(FbsrcError, match="no definition of 'NOSUCH'"):
        _ = compare_function(driver_c, ref_c, "NOSUCH")


@pytest.mark.fbc
def test_piece_matches_reference_lines(piece_pair: tuple[Path, Path, Path]) -> None:
    driver_c, driver_bas, ref_c = piece_pair
    result = compare_piece(driver_c, driver_bas, ref_c, PIECE_SPEC)
    assert result.ok, result.diff
    assert result.compared > 0
    assert result.summary.startswith("ok: piece piece.bi = ref.bas:4-8 (")


@pytest.mark.fbc
def test_piece_reports_changed_line(
    real_fbc: Path, tmp_path: Path, piece_pair: tuple[Path, Path, Path]
) -> None:
    driver_c, driver_bas, _ = piece_pair
    altered = PIECE_REF_BAS.replace("ACC + Q", "ACC + Q * 2.0")
    ref_c = _build(real_fbc, tmp_path / "alt", "ref", altered, "-g")
    result = compare_piece(driver_c, driver_bas, ref_c, PIECE_SPEC)
    assert not result.ok
    assert result.summary.startswith("MISMATCH: piece ")
    assert "line 7:" in result.diff


@pytest.mark.fbc
def test_piece_rejects_kept_c_fbc_would_not_emit(piece_pair: tuple[Path, Path, Path]) -> None:
    driver_c, driver_bas, ref_c = piece_pair
    kept = driver_c.read_text(encoding="utf-8")
    _ = driver_c.write_text(kept + "static int tampered$ = 0;\n", encoding="utf-8")
    result = compare_piece(driver_c, driver_bas, ref_c, PIECE_SPEC)
    assert not result.ok
    assert result.compared == 0
    assert "kept C is not what fbc" in result.diff


@pytest.mark.fbc
def test_cli_piece_takes_driver_bas_directory(
    piece_pair: tuple[Path, Path, Path], capsys: pytest.CaptureFixture[str]
) -> None:
    driver_c, driver_bas, ref_c = piece_pair
    argv = [
        "--driver-c",
        str(driver_c),
        "--driver-bas",
        str(driver_bas.parent),
        "--gef-c",
        str(ref_c),
        "--piece",
        "piece.bi=ref.bas:4-8",
    ]
    assert main(argv) == EXIT_OK
    assert "ok: piece piece.bi = ref.bas:4-8" in capsys.readouterr().out


@needs_source
@pytest.mark.fbc
@pytest.mark.slow
def test_u_shell_matches_gef(real_fbc: Path, emission: Emission, tmp_path: Path) -> None:
    lines = read_source_lines(GEF_BAS)
    shell_mo = lines[SHELL_MO_DECL - 1].strip()
    assert shell_mo.startswith("ReDim Shared ShellMO"), shell_mo
    shell = "".join(line + "\n" for line in lines[U_SHELL_FIRST - 1 : U_SHELL_LAST])
    driver = shell_mo + "\n" + shell + "Print U_SHELL(1, 2)\n"
    driver_c = _build(real_fbc, tmp_path / "drv", "drv", driver)
    result = compare_function(driver_c, emission.gef_c, "U_SHELL")
    assert result.ok, result.diff
    altered = driver.replace("0.3 * Res", "0.4 * Res")
    assert altered != driver
    altered_c = _build(real_fbc, tmp_path / "alt", "drv", altered)
    assert not compare_function(altered_c, emission.gef_c, "U_SHELL").ok
