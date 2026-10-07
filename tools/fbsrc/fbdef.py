# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Case-insensitive symbol lookup in the GEF BASIC source (M0.7).

Usage (from the repository root)::

    python3 -m tools.fbsrc.fbdef <name> [--refs]

Definitions come from a Universal Ctags index of every ``.bas``/``.bi``/``.mac`` file in
``Reference/GEF_code/source/`` (``--map-Basic=+.bi --map-Basic=+.mac``), cached under
``build/fbsrc/ctags/`` and rebuilt when a source file, the file set or ctags changes.

The ctags Basic parser is incomplete for GEF, so the index is corrected with a scan of
the code (comments removed):

* tags that ctags finds inside comments (it reads ``/' Note: '/`` as a label) or that
  name a keyword (it tags ``Const As Single pi`` as constant ``As``) are dropped;
* ``Static`` and ``Const`` declarators and ``#Define``/``#Macro`` names are added
  (ctags misses them);
* ``ReDim`` declarators are added, with role ``redim``, for arrays that have no other
  definition (ctags misses them; for such arrays ``ReDim`` is the definition).

``--refs`` adds every case-insensitive whole-word occurrence of the name outside
comments (``'``, ``Rem`` and nested ``/' ... '/`` blocks); string literals and code in
inactive ``#If`` branches are still searched.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from functools import cache
from pathlib import Path
from typing import Any

from tools.fbsrc.common import (
    FBSRC_BUILD_DIR,
    FbsrcError,
    basic_source_files,
    read_source_lines,
    sha256_file,
)
from tools.toolchain.fbc import GEF_SOURCE_DIR

INDEX_DIR = FBSRC_BUILD_DIR / "ctags"
CTAGS_ARGS = (
    "--map-Basic=+.bi",
    "--map-Basic=+.mac",
    "--output-format=json",
    "--fields=+nKr",
    "--extras=+r",
    "--sort=no",
)
INDEX_SCHEMA = 2

_IDENT = re.compile(r"[A-Za-z0-9_]+")
_TIMEOUT_S = 120


@dataclass(frozen=True)
class Tag:
    """An index entry. ``role``: ``def`` (definition), ``decl`` (``Declare`` statement) or
    ``redim`` (``ReDim`` of an array that has no other definition)."""

    name: str
    kind: str
    path: str
    line: int
    role: str

    @property
    def label(self) -> str:
        """``kind``, with the role appended unless it is a plain definition."""
        suffix = {"decl": " (declaration)", "redim": " (ReDim)"}.get(self.role, "")
        return self.kind + suffix


@dataclass(frozen=True)
class Reference:
    path: str
    line: int
    text: str


def strip_comments(lines: Sequence[str]) -> list[str]:
    """The code part of each line: ``'`` and ``Rem`` comments and ``/' '/`` blocks removed.

    Follows the FreeBASIC lexer: block comments nest and may span lines; ``"..."``
    strings use ``""`` for a quote, ``!"..."`` strings also allow backslash escapes;
    ``Rem`` only counts at the start of a statement.
    """
    out: list[str] = []
    depth = 0
    for line in lines:
        buf: list[str] = []
        i, n = 0, len(line)
        statement_start = True
        while i < n:
            if depth > 0:
                if line.startswith("/'", i):
                    depth += 1
                    i += 2
                elif line.startswith("'/", i):
                    depth -= 1
                    i += 2
                    buf.append(" ")
                else:
                    i += 1
                continue
            c = line[i]
            if c == '"':
                escaped = i > 0 and line[i - 1] == "!"
                j = i + 1
                while j < n:
                    if escaped and line[j] == "\\":
                        j += 2
                        continue
                    if line[j] == '"':
                        if j + 1 < n and line[j + 1] == '"':
                            j += 2
                            continue
                        break
                    j += 1
                buf.append(line[i : j + 1])
                i = j + 1
                statement_start = False
                continue
            if line.startswith("/'", i):
                depth = 1
                i += 2
                continue
            if c == "'":
                break
            word = _IDENT.match(line, i) if (c.isalpha() or c == "_") else None
            if word is not None:
                text = word.group().lower()
                if statement_start and text == "rem":
                    break
                buf.append(word.group())
                i = word.end()
                statement_start = text in ("then", "else")
                continue
            if c == ":":
                statement_start = True
            elif not c.isspace():
                statement_start = False
            buf.append(c)
            i += 1
        out.append("".join(buf))
    return out


def word_pattern(name: str) -> re.Pattern[str]:
    """Case-insensitive whole-word match of a BASIC identifier."""
    return re.compile(rf"(?<![A-Za-z0-9_]){re.escape(name)}(?![A-Za-z0-9_])", re.IGNORECASE)


def ctags_executable() -> tuple[str, str]:
    """Path and version line of Universal Ctags."""
    exe = shutil.which("ctags")
    if exe is None:
        raise FbsrcError("Universal Ctags (ctags) is not on PATH")
    proc = subprocess.run(
        [exe, "--version"], capture_output=True, text=True, check=False, timeout=_TIMEOUT_S
    )
    first = proc.stdout.splitlines()[0] if proc.stdout else ""
    if "Universal Ctags" not in first:
        raise FbsrcError(f"{exe} is not Universal Ctags: {first!r}")
    return exe, first


def _fingerprint(files: Sequence[Path], ctags_version: str) -> str:
    digest = hashlib.sha256()
    digest.update(f"schema {INDEX_SCHEMA}\n{ctags_version}\n{' '.join(CTAGS_ARGS)}\n".encode())
    for path in files:
        digest.update(f"{path.name} {sha256_file(path)}\n".encode())
    return digest.hexdigest()


_KEYWORDS = frozenset(
    {"as", "byref", "byval", "common", "const", "dim", "preserve", "redim", "shared", "static"}
)
_DECLARATION = re.compile(r"\s*(static|const|redim)\b(.*)", re.IGNORECASE)
_PREPROCESSOR = re.compile(r"\s*#\s*(define|macro)\s+([A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)
_SHARED_PRESERVE = re.compile(r"\s*(?:(?:shared|preserve)\b\s*)*", re.IGNORECASE)
_AS = re.compile(r"as\b", re.IGNORECASE)
_NAME = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def _split_top_level(text: str, separator: str) -> list[str]:
    """Split at ``separator`` outside strings and brackets."""
    parts: list[str] = []
    depth = 0
    start = 0
    i = 0
    while i < len(text):
        c = text[i]
        if c == '"':
            end = text.find('"', i + 1)
            i = len(text) if end < 0 else end + 1
            continue
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == separator and depth == 0:
            parts.append(text[start:i])
            start = i + 1
        i += 1
    parts.append(text[start:])
    return parts


def _declarators(rest: str) -> list[str]:
    """Names declared by the text after ``Static``/``Const``/``ReDim``."""
    rest = rest[_SHARED_PRESERVE.match(rest).end() :]  # pyright: ignore[reportOptionalMemberAccess]
    names: list[str] = []
    if _AS.match(rest):  # Static As Single a, b(3) = ..., c
        for index, chunk in enumerate(_split_top_level(rest[2:], ",")):
            head = chunk.split("=", 1)[0].split("(", 1)[0]
            found = _NAME.findall(head)
            if found:
                names.append(found[-1] if index == 0 else found[0])
    else:  # Static a(3) As Single, b As Integer = 1
        for chunk in _split_top_level(rest, ","):
            found = _NAME.match(chunk.strip())
            if found:
                names.append(found.group())
    return [n for n in names if n.lower() not in _KEYWORDS]


def scan_declarations(path: str, code: Sequence[str]) -> list[Tag]:
    """``Static``/``Const``/``ReDim`` declarators and ``#Define``/``#Macro`` names."""
    tags: list[Tag] = []
    for number, line in enumerate(code, start=1):
        macro = _PREPROCESSOR.match(line)
        if macro is not None:
            tags.append(Tag(macro.group(2), "macro", path, number, "def"))
            continue
        for statement in _split_top_level(line, ":"):
            match = _DECLARATION.match(statement)
            if match is None:
                continue
            keyword = match.group(1).lower()
            kind = "constant" if keyword == "const" else "variable"
            role = "redim" if keyword == "redim" else "def"
            tags.extend(Tag(n, kind, path, number, role) for n in _declarators(match.group(2)))
    return tags


def _parse_ctags(text: str, code_by_path: dict[str, list[str]]) -> list[Tag]:
    tags: list[Tag] = []
    for raw_line in text.splitlines():
        raw: Any = json.loads(raw_line)
        if not isinstance(raw, dict) or raw.get("_type") != "tag":  # pyright: ignore[reportUnknownMemberType]
            continue
        entry: dict[str, Any] = raw  # pyright: ignore[reportUnknownVariableType]
        name = str(entry["name"])
        path = str(entry["path"])
        line = int(entry["line"])
        code = code_by_path[path]
        if name.lower() in _KEYWORDS or not (
            0 < line <= len(code) and word_pattern(name).search(code[line - 1])
        ):
            continue
        tags.append(Tag(name, str(entry["kind"]), path, line, str(entry.get("roles", "def"))))
    return tags


def _merge(ctags: list[Tag], scanned: list[Tag]) -> list[Tag]:
    seen = {(t.path, t.line, t.name.lower()) for t in ctags}
    merged = list(ctags)
    redims: list[Tag] = []
    for tag in scanned:
        if (tag.path, tag.line, tag.name.lower()) in seen:
            continue
        seen.add((tag.path, tag.line, tag.name.lower()))
        (redims if tag.role == "redim" else merged).append(tag)
    defined = {t.name.lower() for t in merged}
    merged.extend(t for t in redims if t.name.lower() not in defined)
    return merged


def build_index(source_dir: Path = GEF_SOURCE_DIR, index_dir: Path = INDEX_DIR) -> list[Tag]:
    """Run ctags over all BASIC files, correct it, and write the cache; returns the tags."""
    exe, version = ctags_executable()
    files = basic_source_files(source_dir)
    proc = subprocess.run(
        [exe, *CTAGS_ARGS, "-f", "-", *(p.name for p in files)],
        cwd=source_dir,
        capture_output=True,
        text=True,
        check=False,
        timeout=_TIMEOUT_S,
    )
    if proc.returncode != 0:
        raise FbsrcError(f"ctags failed: {proc.stderr.strip()}")
    code_by_path = {p.name: strip_comments(read_source_lines(p)) for p in files}
    scanned = [t for path, code in code_by_path.items() for t in scan_declarations(path, code)]
    tags = _merge(_parse_ctags(proc.stdout, code_by_path), scanned)
    index_dir.mkdir(parents=True, exist_ok=True)
    payload = {
        "schema": INDEX_SCHEMA,
        "fingerprint": _fingerprint(files, version),
        "ctags": version,
        "files": [p.name for p in files],
        "tags": [[t.name, t.kind, t.path, t.line, t.role] for t in tags],
    }
    tmp = index_dir / "index.json.tmp"
    tmp.write_text(json.dumps(payload) + "\n", encoding="utf-8")
    tmp.replace(index_dir / "index.json")
    return tags


@cache
def load_index(source_dir: Path = GEF_SOURCE_DIR, index_dir: Path = INDEX_DIR) -> tuple[Tag, ...]:
    """The cached tags, rebuilt first if the sources or ctags changed."""
    _, version = ctags_executable()
    fingerprint = _fingerprint(basic_source_files(source_dir), version)
    try:
        payload: Any = json.loads((index_dir / "index.json").read_text(encoding="utf-8"))
        if payload["fingerprint"] == fingerprint:
            return tuple(
                Tag(str(n), str(k), str(p), int(ln), str(r)) for n, k, p, ln, r in payload["tags"]
            )
    except OSError, ValueError, KeyError, TypeError:
        pass
    return tuple(build_index(source_dir, index_dir))


def find_definitions(name: str, source_dir: Path = GEF_SOURCE_DIR) -> list[Tag]:
    """Tags named ``name`` (case-insensitive): definitions, then ReDims, then declarations."""
    wanted = name.lower()
    found = [t for t in load_index(source_dir) if t.name.lower() == wanted]
    order = {"def": 0, "redim": 1, "decl": 2}
    return sorted(found, key=lambda t: (order.get(t.role, 3), t.path != "GEF.bas", t.path, t.line))


def find_references(name: str, source_dir: Path = GEF_SOURCE_DIR) -> list[Reference]:
    """Whole-word, case-insensitive occurrences of ``name`` outside comments."""
    pattern = word_pattern(name)
    refs: list[Reference] = []
    for path in basic_source_files(source_dir):
        lines = read_source_lines(path)
        for number, code in enumerate(strip_comments(lines), start=1):
            if pattern.search(code):
                refs.append(Reference(path.name, number, lines[number - 1].strip()))
    return refs


def source_line(path: str, line: int, source_dir: Path = GEF_SOURCE_DIR) -> str:
    lines = read_source_lines(source_dir / path)
    return lines[line - 1].strip() if 0 < line <= len(lines) else ""


def format_tag(tag: Tag, source_dir: Path = GEF_SOURCE_DIR) -> str:
    location = f"{tag.path}:{tag.line}"
    text = source_line(tag.path, tag.line, source_dir)
    return f"{location}  {tag.label:<22} {tag.name:<20} {text}"


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.fbsrc.fbdef",
        description="Find where a GEF BASIC symbol is defined (case-insensitive).",
    )
    parser.add_argument("name", help="symbol name, any letter case")
    parser.add_argument(
        "--refs", action="store_true", help="also list whole-word references outside comments"
    )
    args = parser.parse_args(argv)
    name: str = args.name
    refs_wanted: bool = args.refs
    try:
        tags = find_definitions(name)
        refs = find_references(name) if refs_wanted else []
    except FbsrcError as exc:
        print(f"fbdef: {exc}", file=sys.stderr)
        return 2
    if tags:
        for tag in tags:
            print(format_tag(tag))
    else:
        print(f"fbdef: no definition of {name!r} in the ctags index", file=sys.stderr)
    if refs_wanted:
        print(f"references ({len(refs)}):")
        for ref in refs:
            print(f"{ref.path}:{ref.line}: {ref.text}")
    return 0 if tags or refs else 1


if __name__ == "__main__":
    sys.exit(main())
