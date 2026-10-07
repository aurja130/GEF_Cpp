# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Multi-variate yield distributions (``tmp/*_Single.mvd``): parser, observables, round-trip.

One file per energy step (``GEF.bas:10429-10700``). It holds one header, then for each
perturbed parameter set ``k = 1..N`` (N = 31 at production ``Fenhance``) two groups of tables
introduced by a ``* Perturbed parameter set #k`` comment:

* ``*Z*``, ``*A*``, ``*AZ*``: independent yields by element, by mass (pre- and post-neutron) and
  by nuclide (pre- and post-neutron);
* ``*AZcumu*``, ``*AZIcumu*``: cumulative yields by nuclide and by nuclide and isomer.

Lines that start with ``*`` are comments, except that a ``*<Tag>*`` line names the table whose
data rows follow. A data row is whitespace-separated: the set number, the identifiers and the
values. The yields are in percent, written with five decimals (``Z``, ``A``) or seven digits
(nuclide tables).

======== ============ =====================
tag      identifiers  values (labels)
======== ============ =====================
Z        Z            ``Y``
A        A            ``Ypre``, ``Ypost``
AZ       A, Z         ``Ypre``, ``Ypost``
AZcumu   A, Z         ``Ycumu``
AZIcumu  A, Z, I      ``Ycumu``
======== ============ =====================

Parsed form: every line as written. A data row keeps the text of its tokens and the whitespace
between them (the layout is the writer's ``Print`` zone logic, which the M13 writer will
reproduce); ``render`` writes the file back from these.

Observables (``Key.file`` = run-relative path)
----------------------------------------------
``group`` is ``#k``: the occurrence of a header in the file (one per file in practice).

``block`` ``header``: ``text`` (index = (line number,)) for every comment line before the first
``Perturbed parameter set`` marker, except the ``* Output written on <stamp>`` line (mask
``mvd_written``: parsed, not emitted); ``Z`` and ``A`` (``int``), ``En`` (``float``, MeV, as
written) and ``spin`` (``float``) from the calculation lines.

``block`` = tag: ``Y`` / ``Ypre`` / ``Ypost`` / ``Ycumu`` (``float``) with ``index`` = (set,
identifiers...) as written in the row (a repeated identifier tuple gets a last index ``2, 3, ...``),
and ``columns`` (``str``, index = (set, line number among the table's column-heading
comments)) for the column-heading comments that precede the tag line. The number of rows of a
table is stochastic (nuclides with no yield are not written); comparators zero-fill.
"""

from __future__ import annotations

import re
from collections import Counter
from collections.abc import Iterator
from dataclasses import dataclass, field
from functools import cache
from pathlib import Path

import harness
from compare.model import Key, Value
from compare.parsers import ParseError
from harness.compare_runs import load_masks

__all__ = [
    "PATTERNS",
    "Comment",
    "MvdFile",
    "Row",
    "TagLine",
    "observables",
    "parse_text",
    "read",
    "render",
    "roundtrip",
]

PATTERNS: tuple[str, ...] = ("work/tmp/*_Single.mvd",)

_ID_STAMP = "mvd_written"
_TAG = re.compile(r"\*([A-Za-z]+)\*")
_MARKER = re.compile(r"\* Perturbed parameter set #(\d+)\s*")
_HEADER_START = re.compile(r"\* This file provides")
_NUCLEUS = re.compile(r"\* Calculation for the nucleus Z =\s*(\d+)\s*,\s*A =\s*(\d+)")
_ENERGY = re.compile(r"\* formed by .* with En =\s*(\S+)\s*MeV")
_SPIN = re.compile(r"\* Spin of target nucleus =\s*(\S+)")
_TOKEN = re.compile(r"(\s*)(\S+)")

# tag -> (number of identifier columns after the set number, value labels)
_TABLES: dict[str, tuple[int, tuple[str, ...]]] = {
    "Z": (1, ("Y",)),
    "A": (1, ("Ypre", "Ypost")),
    "AZ": (2, ("Ypre", "Ypost")),
    "AZcumu": (2, ("Ycumu",)),
    "AZIcumu": (3, ("Ycumu",)),
}


@dataclass(slots=True)
class Comment:
    """A line that starts with ``*`` (or is blank), verbatim."""

    text: str


@dataclass(slots=True)
class TagLine:
    """A ``*<name>*`` line that opens a table."""

    text: str
    name: str


@dataclass(slots=True)
class Row:
    """A data row: token texts and the whitespace before each token plus the trailing blanks."""

    tag: str
    gaps: tuple[str, ...]
    tokens: tuple[str, ...]


type Item = Comment | TagLine | Row


@dataclass(slots=True)
class MvdFile:
    """A parsed file. ``render`` writes exactly the bytes ``parse_text`` read."""

    items: list[Item] = field(default_factory=lambda: [])
    eol: str = "\n"
    final_newline: bool = True


@cache
def _stamp_pattern() -> re.Pattern[str]:
    for mask in load_masks(Path(harness.__file__).resolve().parent / "masks.toml"):
        if mask.id == _ID_STAMP:
            return mask.pattern
    raise ParseError(f"mask {_ID_STAMP} missing from harness/masks.toml")


def _fail(name: str, lineno: int, message: str) -> ParseError:
    return ParseError(f"{name}:{lineno}: {message}")


def parse_text(text: str, name: str = "<mvd>") -> MvdFile:
    """Parse the text of an mvd file (``name`` is only used in error messages)."""
    eol = "\r\n" if "\r\n" in text else "\n"
    if "\r" in text.replace("\r\n", ""):
        raise _fail(name, 1, "stray carriage return")
    lines = text.split(eol)
    final_newline = True
    if lines[-1] == "":
        lines.pop()
    else:
        final_newline = False
    mvd = MvdFile(eol=eol, final_newline=final_newline)
    tag: str | None = None
    nid, nval = 0, 0
    for i, line in enumerate(lines):
        if line.startswith("*"):
            m = _TAG.fullmatch(line)
            if m is None:
                mvd.items.append(Comment(line))
                continue
            tag = m.group(1)
            if tag not in _TABLES:
                raise _fail(name, i + 1, f"unknown table tag {line!r}")
            nid, vals = _TABLES[tag]
            nval = len(vals)
            mvd.items.append(TagLine(line, tag))
            continue
        if not line.strip():
            mvd.items.append(Comment(line))
            continue
        if tag is None:
            raise _fail(name, i + 1, f"data row before any table tag: {line[:60]!r}")
        gaps: list[str] = []
        tokens: list[str] = []
        end = 0
        for tm in _TOKEN.finditer(line):
            gaps.append(tm.group(1))
            tokens.append(tm.group(2))
            end = tm.end()
        gaps.append(line[end:])
        if len(tokens) != 1 + nid + nval:
            raise _fail(
                name, i + 1, f"table {tag} has {1 + nid + nval} columns, row has {len(tokens)}"
            )
        try:
            for t in tokens[: 1 + nid]:
                int(t)
            for t in tokens[1 + nid :]:
                float(t)
        except ValueError:
            raise _fail(name, i + 1, f"malformed number in row {line[:60]!r}") from None
        mvd.items.append(Row(tag, tuple(gaps), tuple(tokens)))
    return mvd


def read(path: Path) -> MvdFile:
    """Parse the mvd file at ``path``."""
    return parse_text(path.read_bytes().decode("utf-8", errors="surrogateescape"), str(path))


def render(mvd: MvdFile) -> str:
    """The text of a parsed file, written back from the parsed form."""
    out: list[str] = []
    for item in mvd.items:
        if isinstance(item, Row):
            out.append(
                "".join(g + t for g, t in zip(item.gaps, item.tokens, strict=False)) + item.gaps[-1]
            )
        else:
            out.append(item.text)
    text = mvd.eol.join(out)
    if mvd.final_newline and out:
        text += mvd.eol
    return text


def roundtrip(path: Path) -> bytes:
    """Parse ``path`` and write it back; equals the file bytes."""
    return render(read(path)).encode("utf-8", errors="surrogateescape")


def _header_observables(lines: list[str], rel: str, group: str) -> Iterator[tuple[Key, Value]]:
    stamp = _stamp_pattern()
    for i, line in enumerate(lines, 1):
        if stamp.search(line) is None:
            yield Key(rel, "header", group, "text", (i,)), line
        if (m := _NUCLEUS.match(line)) is not None:
            yield Key(rel, "header", group, "Z"), int(m.group(1))
            yield Key(rel, "header", group, "A"), int(m.group(2))
        elif (m := _ENERGY.match(line)) is not None:
            yield Key(rel, "header", group, "En"), float(m.group(1))
        elif (m := _SPIN.match(line)) is not None:
            yield Key(rel, "header", group, "spin"), float(m.group(1))


def observables(path: Path, rel: str) -> Iterator[tuple[Key, Value]]:
    """All observables of the mvd file at ``path``; ``rel`` is the run-relative path."""
    mvd = read(path)
    header: list[str] = []
    in_header = True
    occurrence = 1
    group = "#1"
    cur_set = 0
    run: list[str] = []
    seen: Counter[tuple[str, tuple[int, ...]]] = Counter()
    for item in mvd.items:
        if isinstance(item, Comment):
            text = item.text
            if not in_header and _HEADER_START.match(text):
                occurrence += 1
                group = f"#{occurrence}"
                in_header = True
                header = []
                seen.clear()
            if (m := _MARKER.fullmatch(text)) is not None:
                if in_header:
                    yield from _header_observables(header, rel, group)
                    in_header = False
                cur_set = int(m.group(1))
                run = []
            elif in_header:
                header.append(text)
            elif text.strip() not in ("", "*"):
                run.append(text)
            continue
        if isinstance(item, TagLine):
            seen[item.name, (cur_set,)] += 1
            n = seen[item.name, (cur_set,)]
            for j, text in enumerate(run, 1):
                index = (cur_set, j) if n == 1 else (cur_set, j, n)
                yield Key(rel, item.name, group, "columns", index), text
            run = []
            continue
        run = []
        nid, labels = _TABLES[item.tag]
        index = tuple(int(t) for t in item.tokens[: 1 + nid])
        seen[item.tag, index] += 1
        if seen[item.tag, index] > 1:
            index = (*index, seen[item.tag, index])
        for label, tok in zip(labels, item.tokens[1 + nid :], strict=True):
            yield Key(rel, item.tag, group, label, index), float(tok)
    if in_header and header:
        yield from _header_observables(header, rel, group)
