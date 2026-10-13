# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Check that fbc's C for a standalone driver equals its C for GEF (M5.1, D1).

``--function NAME``
    The definition of NAME (header through closing brace) in the driver's kept C must equal
    the definition in GEF.c. Temporaries (``vr$N``, ``tmp$N``, ``tmp$N$M``, ``TMP$N$M``) and
    labels (``label$N``) are renumbered in order of first appearance on each side. Other names
    are compared exactly: both functions are module-level, so their scope suffixes agree.

``--piece CUTFILE=SRCFILE:FIRST-LAST``
    A driver ``Sub`` whose body is BASIC lines FIRST..LAST of SRCFILE, included from CUTFILE
    (line k of CUTFILE is line FIRST+k-1). Statements are grouped by the BASIC line they come
    from; each group must equal GEF.c's group for that line. Locals are renamed per base name
    in order of first appearance (``NAME@k``), because a Sub's scope suffixes differ from
    module level; globals (``NAME$``) are compared by name. The driver's statements are mapped
    to BASIC lines by re-emitting the driver with ``fbc -gen gcc -R -g -c`` in a scratch copy of
    its directory. The kept C must match that re-emission once ``#line`` and ``//`` lines are
    dropped; otherwise the mapping describes other code and the check fails.

Exit status: 0 all equivalent, 1 a difference was found, 2 the check could not run.
"""

from __future__ import annotations

import argparse
import difflib
import re
import shutil
import subprocess
import sys
import tempfile
from collections.abc import Iterable, Iterator, Sequence
from dataclasses import dataclass
from pathlib import Path

from tools.fbsrc.common import FBSRC_BUILD_DIR, FbsrcError, display_path, read_source_lines
from tools.fbsrc.emit_c import emit
from tools.toolchain.fbc import FbcError, filter_fbc_stderr, resolve_fbc

EXIT_OK = 0
EXIT_MISMATCH = 1
EXIT_ERROR = 2

FN_EQUIV_BUILD_DIR = FBSRC_BUILD_DIR / "fn_c_equiv"
_FBC_ARGS = ("-gen", "gcc", "-R", "-g", "-c")
_FBC_TIMEOUT_S = 900
_MAX_REPORT_LINES = 120

# ``#line N "file"`` as fbc writes it (leading tabs allowed).
_DIRECTIVE = re.compile(r'\s*#line\s+(\d+)\s+"([^"]*)"')
_PIECE = re.compile(r"([^=:]+)=([^=:]+):(\d+)-(\d+)")
# A temporary or label (kind, counter, optional second counter), or a local NAME$depth, or a
# global NAME$. The temporary branch comes first so that vr$3 is never read as a variable.
_NAME = re.compile(
    r"(?<![\w$])(?:(?P<kind>label|vr|tmp|TMP)\$\d+(?:\$\d+)?"
    r"|(?P<var>[A-Za-z_]\w*)\$(?P<depth>\d*))(?![\w$])"
)


@dataclass(frozen=True)
class EquivResult:
    """Outcome of one comparison. ``diff`` is empty when ``ok``."""

    subject: str
    ok: bool
    compared: int
    unit: str
    diff: str = ""

    @property
    def summary(self) -> str:
        verdict = "ok" if self.ok else "MISMATCH"
        return f"{verdict}: {self.subject} ({self.compared} {self.unit} compared)"


@dataclass(frozen=True)
class PieceSpec:
    """Driver piece: BASIC lines FIRST..LAST of ``src_file``, included from ``cut_file``."""

    cut_file: str
    src_file: str
    first: int
    last: int

    @property
    def label(self) -> str:
        return f"{self.cut_file} = {self.src_file}:{self.first}-{self.last}"


def parse_piece(text: str) -> PieceSpec:
    """Parse ``CUTFILE=SRCFILE:FIRST-LAST``."""
    match = _PIECE.fullmatch(text)
    if match is None:
        raise FbsrcError(f"bad piece {text!r}: expected CUTFILE=SRCFILE:FIRST-LAST")
    first, last = int(match.group(3)), int(match.group(4))
    if not 1 <= first <= last:
        raise FbsrcError(f"bad piece {text!r}: need 1 <= FIRST <= LAST")
    return PieceSpec(match.group(1), match.group(2), first, last)


class _Names:
    """Renames one side's fbc names in order of first appearance.

    Temporaries and labels become ``vr$1``, ``tmp$2``, ... with one counter per kind. With
    ``rename_locals``, a local ``NAME$depth`` becomes ``NAME@k``, where k numbers the distinct
    locals called NAME on this side. Globals (``NAME$``) and all other text are unchanged.
    """

    def __init__(self, *, rename_locals: bool) -> None:
        self._rename_locals = rename_locals
        self._temps: dict[str, str] = {}
        self._counts: dict[str, int] = {}
        self._locals: dict[str, dict[str, str]] = {}

    def __call__(self, text: str) -> str:
        return _NAME.sub(self._replace, text)

    def _replace(self, match: re.Match[str]) -> str:
        token = match.group(0)
        kind = match.group("kind")
        if kind is not None:
            if token not in self._temps:
                count = self._counts.get(kind, 0) + 1
                self._counts[kind] = count
                self._temps[token] = f"{kind}${count}"
            return self._temps[token]
        base = match.group("var")
        if not self._rename_locals or not match.group("depth"):
            return token
        names = self._locals.setdefault(base, {})
        if token not in names:
            names[token] = f"{base}@{len(names) + 1}"
        return names[token]


def _rename(lines: Iterable[str], *, rename_locals: bool) -> list[str]:
    names = _Names(rename_locals=rename_locals)
    return [names(text) for text in lines]


def _skipped(text: str) -> bool:
    """Lines that carry no statement: blank, ``//`` echoes and ``#line`` directives."""
    stripped = text.strip()
    return not stripped or stripped.startswith(("//", "#line"))


def _next_code(lines: Sequence[str], start: int) -> int | None:
    for index in range(start, len(lines)):
        if not _skipped(lines[index]):
            return index
    return None


def _function_lines(lines: Sequence[str], name: str, path: Path) -> list[str]:
    """Header through closing brace of the definition of ``name``, without directives."""
    where = display_path(path)
    header = re.compile(rf"[A-Za-z_][\w \t*]*\b{re.escape(name)}\s*\(", re.IGNORECASE)
    starts = [
        index
        for index, text in enumerate(lines)
        if header.match(text) and not text.rstrip().endswith(";")
    ]
    if not starts:
        raise FbsrcError(f"no definition of {name!r} in {where}")
    if len(starts) > 1:
        raise FbsrcError(f"{name!r} has {len(starts)} definitions in {where}")
    start = starts[0]
    opening = _next_code(lines, start + 1)
    if opening is None or lines[opening] != "{":
        raise FbsrcError(f"{name!r} in {where}: no column-0 '{{' after the header")
    closing = next((index for index in range(opening + 1, len(lines)) if lines[index] == "}"), None)
    if closing is None:
        raise FbsrcError(f"{name!r} in {where}: no column-0 '}}' closes the body")
    return [text.strip() for text in lines[start : closing + 1] if not _skipped(text)]


def _statements(lines: Sequence[str]) -> Iterator[tuple[str, int, str]]:
    """Statements of function bodies, as ``(file, line, text)``.

    ``file`` is the lower-cased basename and ``line`` the number of the ``#line`` directive that
    governs the statement. A body runs from a column-0 ``{`` that follows a function header
    (a line ending in ``)``) to the next column-0 ``}``; initialiser braces are not bodies.
    Bare braces are not statements: fbc attaches them to neighbouring lines.
    """
    governing_file = ""
    governing_line = 0
    previous = ""
    in_body = False
    for text in lines:
        stripped = text.strip()
        if stripped.startswith("#line"):
            directive = _DIRECTIVE.match(text)
            if directive is None:
                raise FbsrcError(f"unrecognised #line directive: {stripped!r}")
            governing_line = int(directive.group(1))
            governing_file = Path(directive.group(2)).name.casefold()
            continue
        if not stripped or stripped.startswith("//"):
            continue
        if text == "{":
            in_body = previous.endswith(")")
        elif text == "}":
            in_body = False
        elif in_body and stripped not in ("{", "}"):
            yield governing_file, governing_line, stripped
        previous = stripped


def _driver_groups(lines: Sequence[str], spec: PieceSpec) -> dict[int, list[str]]:
    """Driver statements from the cut file, keyed by the BASIC line they come from."""
    cut = Path(spec.cut_file).name.casefold()
    groups: dict[int, list[str]] = {}
    for file, cut_line, text in _statements(lines):
        if file == cut:
            groups.setdefault(spec.first + cut_line - 1, []).append(text)
    return groups


def _gef_groups(lines: Sequence[str], spec: PieceSpec) -> dict[int, list[str]]:
    """GEF.c statements for BASIC lines FIRST..LAST of the source file, keyed by BASIC line."""
    src = Path(spec.src_file).name.casefold()
    groups: dict[int, list[str]] = {}
    for file, line, text in _statements(lines):
        if file == src and spec.first <= line <= spec.last:
            groups.setdefault(line, []).append(text)
    return groups


def _canonical(groups: dict[int, list[str]]) -> dict[int, list[str]]:
    """Every group renamed with one naming state, so numbering follows line order."""
    names = _Names(rename_locals=True)
    return {line: [names(text) for text in groups[line]] for line in sorted(groups)}


def _fbc_debug_c(driver_bas: Path) -> list[str]:
    """``driver_bas`` compiled with ``fbc -gen gcc -R -g -c -m <stem>``, as lines of C.

    Runs in a scratch copy of the driver's directory (kept ``.c`` and ``.o`` files left out),
    so the driver's own build products are never touched. ``-m`` keeps the driver the main
    module: with ``-c`` alone fbc emits its module-level code as a constructor, not as ``main``.
    """
    fbc = resolve_fbc()
    FN_EQUIV_BUILD_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=FN_EQUIV_BUILD_DIR) as scratch:
        work = Path(scratch) / "src"
        shutil.copytree(driver_bas.parent, work, ignore=shutil.ignore_patterns("*.c", "*.o"))
        try:
            proc = subprocess.run(
                [str(fbc), *_FBC_ARGS, "-m", driver_bas.stem, driver_bas.name],
                cwd=work,
                capture_output=True,
                text=True,
                check=False,
                timeout=_FBC_TIMEOUT_S,
            )
        except subprocess.TimeoutExpired as exc:
            raise FbsrcError(f"fbc timed out on {driver_bas.name}") from exc
        if proc.returncode != 0:
            detail = filter_fbc_stderr(proc.stderr)
            raise FbsrcError(f"fbc failed on {driver_bas.name}:\n{detail}")
        return read_source_lines(work / driver_bas.with_suffix(".c").name)


def _clip(lines: Sequence[str]) -> str:
    """Join report lines, capped at ``_MAX_REPORT_LINES``."""
    if len(lines) > _MAX_REPORT_LINES:
        hidden = len(lines) - _MAX_REPORT_LINES
        return "\n".join([*lines[:_MAX_REPORT_LINES], f"... {hidden} more lines"])
    return "\n".join(lines)


def compare_function(driver_c: Path, gef_c: Path, name: str) -> EquivResult:
    """Compare the definition of function ``name`` in the driver's C with GEF.c's (D1)."""
    driver = _rename(
        _function_lines(read_source_lines(driver_c), name, driver_c), rename_locals=False
    )
    gef = _rename(_function_lines(read_source_lines(gef_c), name, gef_c), rename_locals=False)
    subject = f"function {name}"
    if driver == gef:
        return EquivResult(subject, ok=True, compared=len(driver), unit="lines")
    diff = difflib.unified_diff(
        driver,
        gef,
        fromfile=f"driver {display_path(driver_c)}",
        tofile=f"GEF.c {display_path(gef_c)}",
        lineterm="",
    )
    return EquivResult(
        subject, ok=False, compared=len(driver), unit="lines", diff=_clip(list(diff))
    )


def compare_piece(driver_c: Path, driver_bas: Path, gef_c: Path, spec: PieceSpec) -> EquivResult:
    """Compare the statements of a driver piece with GEF.c's for the same BASIC lines (D5, D6).

    ``driver_bas`` is the driver's source, re-emitted with ``-g`` to map its C to BASIC lines.
    """
    subject = f"piece {spec.label}"
    kept = read_source_lines(driver_c)
    regenerated = _fbc_debug_c(driver_bas)
    kept_core = [text for text in kept if not _skipped(text)]
    regen_core = [text for text in regenerated if not _skipped(text)]
    if kept_core != regen_core:
        diff = difflib.unified_diff(
            kept_core,
            regen_core,
            fromfile=f"kept {display_path(driver_c)}",
            tofile=f"fbc -gen gcc -R -g -c {driver_bas.name}",
            n=2,
            lineterm="",
        )
        report = [
            "kept C is not what fbc -R -g emits for the driver, so its statements cannot be "
            "mapped to BASIC lines:",
            *diff,
        ]
        return EquivResult(subject, ok=False, compared=0, unit="statements", diff=_clip(report))
    driver = _canonical(_driver_groups(regenerated, spec))
    if not driver:
        raise FbsrcError(
            f"no statements from {spec.cut_file} in {display_path(driver_c)}: "
            "is the piece inside a Sub?"
        )
    gef = _canonical(_gef_groups(read_source_lines(gef_c), spec))
    if not gef:
        raise FbsrcError(
            f"no statements for {spec.src_file} lines {spec.first}-{spec.last} "
            f"in {display_path(gef_c)}"
        )
    compared = sum(len(texts) for texts in driver.values())
    keys = sorted(set(driver) | set(gef))
    differing = [line for line in keys if driver.get(line, []) != gef.get(line, [])]
    if not differing:
        return EquivResult(subject, ok=True, compared=compared, unit="statements")
    report = [f"{len(differing)} of {len(keys)} BASIC lines differ (driver vs GEF.c, renamed):"]
    for line in differing:
        report.append(f"line {line}:")
        report.extend(
            difflib.unified_diff(
                driver.get(line, []),
                gef.get(line, []),
                fromfile="driver",
                tofile="GEF.c",
                n=1,
                lineterm="",
            )
        )
    return EquivResult(subject, ok=False, compared=compared, unit="statements", diff=_clip(report))


def _resolve_driver_bas(driver_c: Path, given: Path | None) -> Path:
    """The driver's ``.bas``: ``given`` (a file, or a directory holding ``<stem>.bas``), else
    the ``.bas`` next to ``driver_c``."""
    if given is None:
        path = driver_c.with_suffix(".bas")
    elif given.is_dir():
        path = given / f"{driver_c.stem}.bas"
    else:
        path = given
    if not path.is_file():
        raise FbsrcError(f"driver source not found: {display_path(path)}")
    return path


def _run(
    driver_c: Path,
    driver_bas: Path | None,
    gef_c: Path | None,
    functions: Sequence[str],
    pieces: Sequence[str],
) -> list[EquivResult]:
    specs = [parse_piece(text) for text in pieces]
    if not driver_c.is_file():
        raise FbsrcError(f"driver C not found: {display_path(driver_c)}")
    bas = _resolve_driver_bas(driver_c, driver_bas) if specs else None
    gef = gef_c if gef_c is not None else emit().gef_c
    if not gef.is_file():
        raise FbsrcError(f"GEF C not found: {display_path(gef)}")
    results = [compare_function(driver_c, gef, name) for name in functions]
    if bas is not None:
        results += [compare_piece(driver_c, bas, gef, spec) for spec in specs]
    return results


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.fbsrc.fn_c_equiv",
        description="Check that fbc's C for a standalone driver equals its C for GEF (M5.1).",
    )
    parser.add_argument(
        "--driver-c",
        type=Path,
        required=True,
        metavar="PATH",
        help="the driver's C as kept by fbc -R",
    )
    parser.add_argument(
        "--driver-bas",
        type=Path,
        metavar="PATH",
        help="the driver's .bas, or a directory holding <driver-c stem>.bas; for --piece "
        "(default: the .bas next to --driver-c)",
    )
    parser.add_argument(
        "--gef-c",
        type=Path,
        metavar="PATH",
        help="GEF.c to compare with (default: the current emission, built if needed)",
    )
    parser.add_argument(
        "--function",
        action="append",
        metavar="NAME",
        help="compare the definition of function NAME (repeatable)",
    )
    parser.add_argument(
        "--piece",
        action="append",
        metavar="CUTFILE=SRCFILE:FIRST-LAST",
        help="compare driver piece CUTFILE with GEF.c's statements for SRCFILE lines "
        "FIRST-LAST (repeatable)",
    )
    args = parser.parse_args(argv)
    driver_c: Path = args.driver_c
    driver_bas: Path | None = args.driver_bas
    gef_c: Path | None = args.gef_c
    functions: list[str] = args.function or []
    pieces: list[str] = args.piece or []
    if not functions and not pieces:
        parser.error("give at least one --function NAME or --piece CUTFILE=SRCFILE:FIRST-LAST")
    try:
        results = _run(driver_c, driver_bas, gef_c, functions, pieces)
    except (FbcError, FbsrcError) as exc:
        print(f"fn_c_equiv: {exc}", file=sys.stderr)
        return EXIT_ERROR
    for result in results:
        print(result.summary)
        if result.diff:
            print(result.diff)
    return EXIT_OK if all(result.ok for result in results) else EXIT_MISMATCH


if __name__ == "__main__":
    sys.exit(main())
