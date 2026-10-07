# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Show the C that fbc generates from given BASIC lines (M0.7).

Usage (from the repository root)::

    python3 -m tools.fbsrc.fbline <file>:<line>[-<line>] [--context N] [--raw] [--symbols]
                                  [--patch-dir DIR]

The C comes from ``build/fbsrc/<key>/src/GEF.c`` (emitted on demand by ``emit_c``); it is
located through fbc's ``#line`` directives. A directive covers the C lines after it up
to the next directive (or a blank line / top-level type definition). The BASIC text
comes from the submodule, or from the patched copy when ``--patch-dir`` is given.

Default output: one C statement per line with indentation removed; lone braces and
fbc's ``//`` echo of the BASIC text are dropped; fbc temporaries are renamed in order
of appearance (``vr$19562`` -> ``vr1``, ``TMP$57454$22``/``tmp$66811`` -> ``tmp1``),
never inlined, so evaluation order stays visible. ``--raw`` prints the C lines exactly
as generated, ``#line`` directives and echo comments included. ``--symbols`` adds a
legend mapping fbc-mangled names (``E_INTR_HEAVY$``) to their BASIC spelling and
definition site.

Exit status: 0 when C was found, 1 when the lines generated no C, 2 on errors (bad
location, unknown file, emission failure).
"""

from __future__ import annotations

import argparse
import re
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from functools import cache
from pathlib import Path

from tools.fbsrc.common import (
    FbsrcError,
    display_path,
    read_source_lines,
    resolve_source_name,
)
from tools.fbsrc.emit_c import Emission, emit
from tools.fbsrc.fbdef import Tag, load_index, strip_comments
from tools.toolchain.fbc import GEF_SOURCE_DIR

EXIT_FOUND = 0
EXIT_NO_C = 1
EXIT_ERROR = 2

_LINE_DIRECTIVE = re.compile(r'\s*#line\s+(\d+)\s+"([^"]*)"')
_TOP_LEVEL_TYPE = re.compile(r"(?:struct|union|typedef|enum)\b")
_LOCATION = re.compile(r"(?P<file>.+):(?P<first>\d+)(?:-(?P<last>\d+))?")
_TEMPORARY = re.compile(r"(?<![\w$])(?:(vr)\$\d+|(TMP)\$\d+\$\d+|(tmp)\$\d+(?:\$\d+)?)(?![\w$])")
_MANGLED = re.compile(r"(?<![\w$])([A-Z_][A-Z0-9_]*)(\$\d*)?(?![\w$])")
_BASIC_WORD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


@dataclass(frozen=True)
class Directive:
    """``#line`` directive at 0-based C line ``index``; covers C lines ``index+1 .. end-1``."""

    index: int
    file: str
    line: int
    end: int


@dataclass(frozen=True)
class CIndex:
    lines: tuple[str, ...]
    directives: tuple[Directive, ...]

    @property
    def files(self) -> frozenset[str]:
        return frozenset(d.file for d in self.directives)


@dataclass(frozen=True)
class CStatement:
    c_line: int  # 1-based line in GEF.c
    basic_line: int
    text: str  # as generated


@dataclass(frozen=True)
class CRegion:
    """A run of consecutive ``#line`` directives that all point into the requested lines."""

    statements: tuple[CStatement, ...]
    raw: tuple[tuple[int, str], ...]  # (1-based C line, text) exactly as generated


@dataclass(frozen=True)
class Lookup:
    file: str
    first: int
    last: int
    context: int
    source_dir: Path
    basic: tuple[tuple[int, str], ...]  # (line, text) including context lines
    regions: tuple[CRegion, ...]
    emission: Emission
    file_compiled: bool

    def statements(self) -> list[CStatement]:
        return [s for r in self.regions for s in r.statements]


def source_file_name(path: str, src_dir: Path) -> str:
    """Map a ``#line`` path back to a source-relative name.

    fbc writes the main file as given (``GEF.bas``) and included files with absolute
    paths inside the emission directory.
    """
    p = Path(path)
    if not p.is_absolute():
        return path
    try:
        return str(p.relative_to(src_dir))
    except ValueError:
        return p.name


def _segment_end(lines: Sequence[str], start: int, limit: int) -> int:
    for i in range(start, limit):
        text = lines[i]
        if not text.strip() or _TOP_LEVEL_TYPE.match(text):
            return i
    return limit


@cache
def _index_for(gef_c: Path, sha256: str, src_dir: Path) -> CIndex:
    del sha256  # part of the cache key only
    lines = gef_c.read_bytes().decode("utf-8", errors="replace").split("\n")
    found: list[tuple[int, str, int]] = []
    for i, text in enumerate(lines):
        if "#line" in text:
            m = _LINE_DIRECTIVE.match(text)
            if m is not None:
                found.append((i, source_file_name(m.group(2), src_dir), int(m.group(1))))
    directives: list[Directive] = []
    for k, (i, file, line) in enumerate(found):
        limit = found[k + 1][0] if k + 1 < len(found) else len(lines)
        directives.append(Directive(i, file, line, _segment_end(lines, i + 1, limit)))
    return CIndex(tuple(lines), tuple(directives))


def c_index(emission: Emission) -> CIndex:
    """The ``#line`` index of an emission's ``GEF.c`` (cached per process)."""
    return _index_for(emission.gef_c, emission.manifest.gef_c_sha256, emission.src_dir)


def _is_noise(text: str) -> bool:
    s = text.strip()
    return s in ("", "{", "}") or s.startswith("//")


def _region(index: CIndex, run: Sequence[Directive]) -> CRegion:
    lines = index.lines
    statements = [
        CStatement(i + 1, d.line, lines[i])
        for d in run
        for i in range(d.index + 1, d.end)
        if not _is_noise(lines[i])
    ]
    start = run[0].index
    while start > 0 and lines[start - 1].strip().startswith("//"):
        start -= 1
    end = run[-1].end
    while end > run[-1].index + 1 and _is_noise(lines[end - 1]):
        end -= 1
    raw = tuple((i + 1, lines[i]) for i in range(start, end))
    return CRegion(tuple(statements), raw)


def parse_location(location: str) -> tuple[str, int, int]:
    """``"GEF.bas:8392"`` -> ``("GEF.bas", 8392, 8392)``; ``"X.bas:5-7"`` -> ``(..., 5, 7)``."""
    m = _LOCATION.fullmatch(location)
    if m is None:
        raise FbsrcError(f"location {location!r} is not <file>:<line>[-<line>]")
    first = int(m.group("first"))
    last = int(m.group("last") or first)
    if first < 1 or last < first:
        raise FbsrcError(f"bad line range in {location!r}")
    return m.group("file"), first, last


def lookup(
    file: str, first: int, last: int | None = None, context: int = 0, patch_dir: Path | None = None
) -> Lookup:
    """BASIC lines ``first..last`` of ``file`` and the C generated from them."""
    last = first if last is None else last
    emission = emit(patch_dir)
    source_dir = emission.src_dir if patch_dir is not None else GEF_SOURCE_DIR
    name = resolve_source_name(file, source_dir)
    source = read_source_lines(source_dir / name)
    if last > len(source):
        raise FbsrcError(f"{name} has {len(source)} lines; {last} is out of range")
    lo, hi = max(1, first - context), min(len(source), last + context)
    basic = tuple((n, source[n - 1]) for n in range(lo, hi + 1))

    index = c_index(emission)
    regions: list[CRegion] = []
    run: list[Directive] = []
    for d in index.directives:
        if d.file == name and first <= d.line <= last:
            run.append(d)
        elif run:
            regions.append(_region(index, run))
            run = []
    if run:
        regions.append(_region(index, run))
    return Lookup(
        name, first, last, context, source_dir, basic, tuple(regions), emission,
        name in index.files,
    )  # fmt: skip


class _TemporaryNames:
    """Renames fbc temporaries to short names in order of first appearance."""

    def __init__(self) -> None:
        self._names: dict[str, str] = {}
        self._counts: dict[str, int] = {"vr": 0, "tmp": 0}

    def _replace(self, m: re.Match[str]) -> str:
        original = m.group(0)
        if original not in self._names:
            prefix = "vr" if m.group(1) else "tmp"
            self._counts[prefix] += 1
            self._names[original] = f"{prefix}{self._counts[prefix]}"
        return self._names[original]

    def __call__(self, text: str) -> str:
        return _TEMPORARY.sub(self._replace, text)


def _dedent(texts: Sequence[str]) -> list[str]:
    expanded = [t.expandtabs(8).rstrip() for t in texts]
    indents = [len(t) - len(t.lstrip()) for t in expanded if t.strip()]
    cut = min(indents, default=0)
    return [t[cut:] for t in expanded]


@dataclass(frozen=True)
class SymbolNote:
    mangled: str
    basic: str
    where: str


def symbol_notes(result: Lookup, c_texts: Sequence[str]) -> list[SymbolNote]:
    """BASIC spelling and definition site for each fbc-mangled BASIC name in ``c_texts``."""
    spelled: dict[str, str] = {}
    for code in strip_comments([text for _, text in result.basic]):
        for word in _BASIC_WORD.findall(code):
            spelled.setdefault(word.upper(), word)
    by_name: dict[str, list[Tag]] = {}
    for tag in load_index():
        by_name.setdefault(tag.name.upper(), []).append(tag)
    notes: dict[str, SymbolNote] = {}
    for text in c_texts:
        for m in _MANGLED.finditer(text):
            mangled, base = m.group(0), m.group(1)
            if mangled in notes:
                continue
            tags = sorted(by_name.get(base, []), key=lambda t: (t.role != "def", t.path, t.line))
            if base not in spelled and not tags:
                continue
            basic = spelled.get(base) or tags[0].name
            where = ""
            if tags:
                where = f"{tags[0].label} {tags[0].path}:{tags[0].line}"
                if len(tags) > 1:
                    where += f" (+{len(tags) - 1} more)"
            notes[mangled] = SymbolNote(mangled, basic, where)
    return list(notes.values())


def render(result: Lookup, raw: bool = False, symbols: bool = False) -> str:
    out: list[str] = []
    span = f"{result.first}" if result.first == result.last else f"{result.first}-{result.last}"
    out.append(f"BASIC {result.file}:{span}  ({display_path(result.source_dir / result.file)})")
    width = len(str(result.basic[-1][0]))
    for (number, _), text in zip(result.basic, _dedent([t for _, t in result.basic]), strict=True):
        mark = ">" if result.first <= number <= result.last else " "
        out.append(f"{mark} {number:>{width}}  {text}".rstrip())
    out.append(f"C {display_path(result.emission.gef_c)}")
    shown: list[str] = []
    if not result.regions:
        out.append(
            "  (no C generated from these lines: comment, declaration without code, "
            "or inactive #If branch)"
            if result.file_compiled
            else f"  (no C: {result.file} is not part of the {result.emission.key} compilation)"
        )
    rename = _TemporaryNames()
    for k, region in enumerate(result.regions):
        if k:
            out.append("  ...")
        if raw:
            for c_line, text in region.raw:
                out.append(f"{c_line:>7}: {text}")
                shown.append(text)
        else:
            for st in region.statements:
                text = rename(st.text.strip())
                out.append(f"{st.c_line:>7}  [{st.basic_line}]  {text}")
                shown.append(text)
    if symbols:
        notes = symbol_notes(result, shown)
        out.append("Symbols")
        if not notes:
            out.append("  (none)")
        mw = max((len(n.mangled) for n in notes), default=0)
        bw = max((len(n.basic) for n in notes), default=0)
        out.extend(f"  {n.mangled:<{mw}}  {n.basic:<{bw}}  {n.where}".rstrip() for n in notes)
    return "\n".join(out) + "\n"


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.fbsrc.fbline",
        description="Show BASIC source lines and the C that fbc generates from them.",
    )
    parser.add_argument("location", help="<file>:<line>[-<line>], e.g. GEF.bas:8392")
    parser.add_argument("--context", type=int, default=0, metavar="N", help="BASIC lines around")
    parser.add_argument("--raw", action="store_true", help="print the C exactly as generated")
    parser.add_argument("--symbols", action="store_true", help="legend of fbc-mangled names")
    parser.add_argument("--patch-dir", type=Path, help="look in the emission of this patch dir")
    args = parser.parse_args(argv)
    location: str = args.location
    context: int = args.context
    patch_dir: Path | None = args.patch_dir
    if context < 0:
        parser.error("--context must be >= 0")
    try:
        file, first, last = parse_location(location)
        result = lookup(file, first, last, context, patch_dir)
    except FbsrcError as exc:
        print(f"fbline: {exc}", file=sys.stderr)
        return EXIT_ERROR
    sys.stdout.write(render(result, raw=args.raw, symbols=args.symbols))
    return EXIT_FOUND if result.regions else EXIT_NO_C


if __name__ == "__main__":
    sys.exit(main())
