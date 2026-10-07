# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""SATAN analyzer dumps (``dmp/<step dir>/*.dmp``): parser, observables, round-trip (M2.2).

File layout (writers: ``U_DMP_1D`` at ``GEF.bas:15709`` and the hand-written ``ZApre`` /
``ZApost`` loops at ``GEF.bas:15019-15160``)
------------------------------------------------------------------------------------------
A file is a sequence of *segments*. A segment is some *pre* lines followed by one analyzer
*block*; a file may end with pre lines that have no block (``Multichance.dmp`` without
multi-chance fission is only ``C: Only first-chance fission occured.``).

pre lines
    Blank lines (``" "`` after every 1-D block), ``C:`` comments (the masked
    ``C: Written on <stamp>``, ``C: Calculation performed with GEF...``, section remarks of
    ``ZApre``, ``C: Relative probability for fission after the emission of I neutrons and J
    protons: P`` of ``Multichance``) and the file title ``GEF analyzer dump: ...`` (written
    once per ``Open ... For Append``, so a file holds several when a step directory is
    revisited).
block
    ``S: ANALYZER(name)`` (``Analyzer`` in the hand-written parts), then ``S: TITLE(...)``,
    ``S: COMMENT(...)`` (two), optional ``C:`` notes, ``X:`` and ``Y:`` axis labels, then
    ``A: ...`` and the data:

    * ``A: (X = lo TO hi BY step) Y,<symbols>``: one run of comma-separated ``Single`` texts
      (``Str(Csng(..))``), wrapped after the first element that brings the line to 128
      characters. Value ``i`` belongs to array bin ``lo/step + i``. A trailing comma ends
      every line except possibly the last.
    * ``A:  X[+Z]     Y,LTR1``: one row per line, ``Print Using "####    ###.######"``:
      integer ``X`` and a fixed-point ``Y``.

Observables (``Key.file`` = run-relative path)
----------------------------------------------
``block``
    The analyzer name as written inside ``S: ANALYZER(...)``, e.g. ``APOST``, ``AMPOST(0)``,
    ``Zpre(61)``, ``Emultichance(1,0)``.
``group``
    ``#k``: occurrence counter of that analyzer name in the file (1-based). It is always
    present, so a file with an appended second block has keys ``#1`` and ``#2``.
``label`` / ``index`` (``str`` unless noted)
    ``(file)`` / ``version`` (k,): the distinct texts after ``C: Calculation performed with
    GEF`` in order of first appearance (written before every analyzer, so not attached to one).
    ``chance_probability`` (I, J): ``float`` from the ``C: Relative probability for fission
    after the emission of I neutrons and J protons`` line that precedes an ``Emultichance`` block.
    The time-stamp line (``dmp_written`` of ``harness/masks.toml``) is parsed, not emitted.
    Every other line before a block (and a file's trailing lines) is a *section remark*: the
    file title ``GEF analyzer dump: ...``, ``C: Z distributions for fixed Ap$r$e$``, ``C: Only
    first-chance fission occured.``. It is a presence marker ``Key(file, "(pre)", "#k", <line
    text>) = 1``, with ``k`` the occurrence counter of that exact text in the file. The remark is
    not attached to the block that follows it, because that block (the first Z or A with data)
    varies between runs.
    ``title``, ``xaxis``, ``yaxis``: payload of ``S: TITLE``, ``X:``, ``Y:``.
    ``comment`` (k,): the k-th ``S: COMMENT``. The event count of a ``N fission events`` phrase
    is stochastic (it carries the pre-pass statistics), so it is replaced by ``#`` in the text and
    emitted as ``int`` ``events`` (k,). ``note`` (k,): the k-th ``C:`` line in the block.
    ``range``: text of the ``A:`` line. For a 1-D block only the deterministic part
    ``BY <step> Y,<line symbols>`` (a changed step or symbol set is visible); the limits are
    separate ``float`` observables ``lo`` and ``hi``. GEF trims leading and trailing zero bins
    before writing (``GEF.bas:15716-15737``), so ``lo``, ``hi`` and the set of ``y`` keys of an
    analyzer vary between runs of the same input; **a bin that is absent from one run and present
    in another is zero in the former**. Comparators must zero-fill within a family. The same
    holds for row blocks (zero rows are not written).
    ``y`` (bin,): ``float`` data value. ``bin`` is the array bin ``lo/step + i`` of a 1-D
    block (equal to the X value for the usual unit step) and the ``X`` integer of a row.
    If ``lo/step`` is not an integer, the 0-based ordinal is used instead.

Time stamps are parsed but not emitted. Anything the grammar does not know is a
``ParseError`` naming file and line.
"""

from __future__ import annotations

import re
from collections.abc import Iterator
from dataclasses import dataclass, field
from functools import cache
from pathlib import Path

import harness
from compare.model import Key, Value
from compare.parsers import ParseError
from harness.compare_runs import load_masks

__all__ = [
    "FILE_BLOCK",
    "PATTERNS",
    "PRE_BLOCK",
    "Block",
    "DmpFile",
    "RowData",
    "Segment",
    "SeriesData",
    "observables",
    "parse_text",
    "read",
    "render",
    "roundtrip",
]

PATTERNS: tuple[str, ...] = ("work/dmp/*/*.dmp",)

PRE_BLOCK = "(pre)"
FILE_BLOCK = "(file)"

_ANALYZER = re.compile(r"S: ANALYZER\((.*)\)", re.IGNORECASE)
_TITLE = re.compile(r"S: TITLE\((.*)\)")
_COMMENT = re.compile(r"S: COMMENT\((.*)\)")
_A_SERIES = re.compile(r"A: \(X = (\S+) TO (\S+) BY (\S+)\) Y,(\S+)")
_A_ROWS = re.compile(r"A: +X(?:\+\d+)? +Y,\S+")
_SERIES_LINE = re.compile(r"[-+0-9.eE,]+")
_ROW_LINE = re.compile(r"( *)(-?\d+)( +)(\S+)")
_CHANCE = re.compile(
    r"C: Relative probability for fission after the emission of +(\d+) neutrons"
    r" and +(\d+) protons: +(\S+)"
)
_VERSION = re.compile(r"C: Calculation performed with GEF(.*)")
_EVENTS = re.compile(r"(?<![\w.])(\d+)( fission events)")
_ID_DMP_WRITTEN = "dmp_written"


class SeriesData:
    """Comma-separated values of a 1-D analyzer: the token text of every output line."""

    __slots__ = ("lines", "lo", "step")

    def __init__(self, lo: str, step: str, lines: list[list[str]]) -> None:
        self.lo = lo
        self.step = step
        self.lines = lines


@dataclass(slots=True)
class RowData:
    """One ``(lead, x, separator, y)`` text tuple per output line of a row-style block."""

    rows: list[tuple[str, str, str, str]]


@dataclass(slots=True)
class Block:
    """One analyzer: header lines as written, the ``A:`` line and the parsed data."""

    name_line: str
    name: str
    header: list[str]
    a_line: str
    data: SeriesData | RowData


@dataclass(slots=True)
class Segment:
    pre: list[str]
    block: Block | None


@dataclass(slots=True)
class DmpFile:
    """A parsed dump. ``render`` writes exactly the bytes ``parse_text`` read."""

    segments: list[Segment] = field(default_factory=lambda: [])
    eol: str = "\n"
    final_newline: bool = True


@cache
def _stamp_pattern() -> re.Pattern[str]:
    masks = load_masks(Path(harness.__file__).resolve().parent / "masks.toml")
    for mask in masks:
        if mask.id == _ID_DMP_WRITTEN:
            return mask.pattern
    raise ParseError(f"mask {_ID_DMP_WRITTEN} missing from harness/masks.toml")


# --------------------------------------------------------------------------------------------
# parsing
# --------------------------------------------------------------------------------------------


def _fail(name: str, lineno: int, message: str) -> ParseError:
    return ParseError(f"{name}:{lineno}: {message}")


def _parse_a_line(line: str, name: str, lineno: int) -> tuple[bool, str, str, str]:
    """(is_series, lo, hi, step) of an ``A:`` line."""
    m = _A_SERIES.fullmatch(line)
    if m is not None:
        return True, m.group(1), m.group(2), m.group(3)
    if _A_ROWS.fullmatch(line) is not None:
        return False, "", "", ""
    raise _fail(name, lineno, f"unknown data definition: {line!r}")


def _float(text: str, name: str, lineno: int) -> float:
    try:
        return float(text)
    except ValueError:
        raise _fail(name, lineno, f"not a number: {text!r}") from None


def _bin_offset(lo: float, step: float) -> int | None:
    """Array bin of the first value (``lo/step``), or None when it is not an integer."""
    if step <= 0.0:
        return None
    ratio = lo / step
    nearest = round(ratio)
    if abs(ratio - nearest) > 1e-6 * max(1.0, abs(ratio)):
        return None
    return nearest


def parse_text(text: str, name: str = "<dmp>") -> DmpFile:
    """Parse the text of a dump file (``name`` is only used in error messages)."""
    eol = "\r\n" if "\r\n" in text else "\n"
    lines = text.split(eol)
    final_newline = True
    if lines[-1] == "":
        lines.pop()
    else:
        final_newline = False
    if "\r" in text.replace("\r\n", ""):
        raise _fail(name, 1, "stray carriage return")
    dmp = DmpFile(eol=eol, final_newline=final_newline)
    n = len(lines)
    pre: list[str] = []
    i = 0
    while i < n:
        line = lines[i]
        m = _ANALYZER.fullmatch(line)
        if m is None:
            if line.strip() and not line.startswith(("C:", "GEF analyzer dump")):
                raise _fail(name, i + 1, f"unexpected line: {line[:60]!r}")
            pre.append(line)
            i += 1
            continue
        start = i
        header: list[str] = []
        i += 1
        while True:
            if i >= n:
                raise _fail(name, start + 1, "analyzer block without an A: line")
            current = lines[i]
            if current.startswith("A:"):
                break
            if not (
                current.startswith(("C:", "X:", "Y:"))
                or _TITLE.fullmatch(current)
                or _COMMENT.fullmatch(current)
            ):
                raise _fail(name, i + 1, f"unexpected line in analyzer header: {current[:60]!r}")
            header.append(current)
            i += 1
        a_line = lines[i]
        is_series, lo, hi, step = _parse_a_line(a_line, name, i + 1)
        i += 1
        data: SeriesData | RowData
        if is_series:
            first = i
            token_lines: list[list[str]] = []
            while i < n and _SERIES_LINE.fullmatch(lines[i]) is not None:
                tokens = lines[i].split(",")
                for k, token in enumerate(tokens):
                    if token == "" and k != len(tokens) - 1:
                        raise _fail(name, i + 1, "empty value in data line")
                    if token:
                        _float(token, name, i + 1)
                token_lines.append(tokens)
                i += 1
            count = sum(len(t) - (1 if t[-1] == "" else 0) for t in token_lines)
            lo_f, hi_f, step_f = (
                _float(lo, name, i),
                _float(hi, name, i),
                _float(step, name, i),
            )
            if step_f <= 0.0:
                raise _fail(name, start + 1, f"non-positive step {step!r}")
            expected = round((hi_f - lo_f) / step_f) + 1
            if count != expected:
                raise _fail(
                    name, first + 1, f"{count} values for the range {a_line!r} ({expected} bins)"
                )
            data = SeriesData(lo, step, token_lines)
        else:
            rows: list[tuple[str, str, str, str]] = []
            while i < n:
                rm = _ROW_LINE.fullmatch(lines[i])
                if rm is None:
                    break
                _float(rm.group(4), name, i + 1)
                rows.append((rm.group(1), rm.group(2), rm.group(3), rm.group(4)))
                i += 1
            data = RowData(rows)
        dmp.segments.append(Segment(pre, Block(lines[start], m.group(1), header, a_line, data)))
        pre = []
    if pre:
        dmp.segments.append(Segment(pre, None))
    return dmp


def read(path: Path) -> DmpFile:
    """Parse the dump file at ``path``."""
    text = path.read_bytes().decode("utf-8", errors="surrogateescape")
    return parse_text(text, str(path))


# --------------------------------------------------------------------------------------------
# writing
# --------------------------------------------------------------------------------------------


def render(dmp: DmpFile) -> str:
    """The text of a parsed dump, written back from the parsed form."""
    out: list[str] = []
    for seg in dmp.segments:
        out.extend(seg.pre)
        block = seg.block
        if block is None:
            continue
        out.append(block.name_line)
        out.extend(block.header)
        out.append(block.a_line)
        data = block.data
        if isinstance(data, SeriesData):
            out.extend(",".join(tokens) for tokens in data.lines)
        else:
            out.extend(f"{lead}{x}{sep}{y}" for lead, x, sep, y in data.rows)
    text = dmp.eol.join(out)
    if dmp.final_newline and out:
        text += dmp.eol
    return text


def roundtrip(path: Path) -> bytes:
    """Parse ``path`` and write it back; equals the file bytes."""
    return render(read(path)).encode("utf-8", errors="surrogateescape")


# --------------------------------------------------------------------------------------------
# observables
# --------------------------------------------------------------------------------------------


def _payload(line: str, tag: str) -> str:
    """Text after the ``X:``-style tag (one separating space is dropped)."""
    rest = line[len(tag) :]
    return rest[1:] if rest.startswith(" ") else rest


def observables(path: Path, rel: str) -> Iterator[tuple[Key, Value]]:
    """The observables of one dump file; see the module docstring for the key scheme."""
    dmp = read(path)
    stamp = _stamp_pattern()
    seen: dict[str, int] = {}
    text_seen: dict[str, int] = {}
    versions: list[str] = []
    for seg in dmp.segments:
        block = seg.block
        name = PRE_BLOCK if block is None else block.name
        if block is not None:
            seen[name] = seen.get(name, 0) + 1
        group = f"#{seen.get(name, 0)}"

        def key(
            label: str, index: tuple[int, ...] = (), name: str = name, group: str = group
        ) -> Key:
            return Key(rel, name, group, label, index)

        for line in seg.pre:
            if not line.strip() or stamp.search(line) is not None:
                continue
            version = _VERSION.fullmatch(line)
            if version is not None:
                if version.group(1) not in versions:
                    versions.append(version.group(1))
                    yield Key(rel, FILE_BLOCK, "", "version", (len(versions) - 1,)), versions[-1]
                continue
            if block is not None:
                chance = _CHANCE.fullmatch(line)
                if chance is not None:
                    yield (
                        key("chance_probability", (int(chance.group(1)), int(chance.group(2)))),
                        _float(chance.group(3), rel, 0),
                    )
                    continue
            repeat = text_seen.get(line, 0) + 1
            text_seen[line] = repeat
            yield Key(rel, PRE_BLOCK, f"#{repeat}", line), 1
        if block is None:
            continue
        comments = 0
        notes = 0
        for line in block.header:
            if stamp.search(line) is not None:
                continue
            if line.startswith("C:"):
                yield key("note", (notes,)), _payload(line, "C:")
                notes += 1
            elif line.startswith("X:"):
                yield key("xaxis"), _payload(line, "X:")
            elif line.startswith("Y:"):
                yield key("yaxis"), _payload(line, "Y:")
            elif (m := _TITLE.fullmatch(line)) is not None:
                yield key("title"), m.group(1)
            elif (m := _COMMENT.fullmatch(line)) is not None:
                text = m.group(1)
                events = _EVENTS.search(text)
                if events is not None:
                    yield key("events", (comments,)), int(events.group(1))
                    text = text[: events.start(1)] + "#" + text[events.end(1) :]
                yield key("comment", (comments,)), text
                comments += 1
        series = _A_SERIES.fullmatch(block.a_line)
        if series is None:
            yield key("range"), _payload(block.a_line, "A:")
        else:
            yield key("range"), f"BY {series.group(3)} Y,{series.group(4)}"
            yield key("lo"), float(series.group(1))
            yield key("hi"), float(series.group(2))
        data = block.data
        if isinstance(data, SeriesData):
            offset = _bin_offset(float(data.lo), float(data.step))
            base = 0 if offset is None else offset
            position = 0
            for tokens in data.lines:
                for token in tokens:
                    if token:
                        yield key("y", (base + position,)), float(token)
                        position += 1
        else:
            seen_x: set[int] = set()
            for _lead, x, _sep, y in data.rows:
                xi = int(x)
                if xi in seen_x:
                    raise ParseError(f"{rel}: block {name} {group}: duplicate row X={xi}")
                seen_x.add(xi)
                yield key("y", (xi,)), float(y)
