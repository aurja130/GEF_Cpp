# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Perturbed parameter sets (``tmp/<system>.par``): parser, observables, round-trip.

One file per system (``GEF.bas:5165-5200``) that is opened for appending: it holds one *step*
per energy step (and per appended earlier run). A step is a header and ``N`` sets (N = 31 at
production ``Fenhance``). Lines that start with ``*`` are comments; any other line is
``NAME =<blanks><value>`` (``Str(Single)`` text, left-aligned from column 29, with a leading
blank where the sign would be).

A *set* is a run of comment lines that contains ``* Perturbed parameter set #k`` followed by its
parameter lines. The run of the first set of a step also carries the step header (description,
``* Output written on ...``, ``* Calculation for the nucleus Z = .. , A = ..``, ``* formed by
(n,f) with En = .. MeV.``, ``* Spin of target nucleus = ..``); that is the comment run that
contains the ``Calculation for the nucleus`` line.

The ``Output written on`` line prints a local ``Rdatetime`` that GEF never assigns, i.e.
``30.12.1899, 00:00:00`` in every run (``harness/masks.toml``), so it is not masked and is
emitted as text.

Parsed form: ``ParFile.sets``, each ``ParSet`` with its comment run (verbatim lines),
the set number and its ``ParLine`` parameters (name, the blanks between ``=`` and the value,
the value text, trailing blanks); ``trailer`` is a comment run without a following set.
``render`` writes the file back from these.

Observables (``Key.file`` = run-relative path)
----------------------------------------------
``group`` is ``E=<energy as written>MeV#<n>``: the energy of the step header's ``En =`` line and
the occurrence of that label in the file (a step repeated by an appended run gets ``#2``).

``block`` ``header``: ``text`` (index = (line number in the header run,)) for every
header line except bare ``*`` lines and the set marker; ``Z`` and ``A`` (``int``), ``En``
(``float``, MeV) and ``spin`` (``float``).
``block`` ``params``: ``label`` = the parameter name, ``index`` = (set number,), value ``float``
(a name repeated in one set gets a second index ``2, 3, ...``).
"""

from __future__ import annotations

import re
from collections import Counter
from collections.abc import Iterator
from dataclasses import dataclass, field
from pathlib import Path

from compare.model import Key, Value
from compare.parsers import ParseError

__all__ = [
    "PATTERNS",
    "ParFile",
    "ParLine",
    "ParSet",
    "observables",
    "parse_text",
    "read",
    "render",
    "roundtrip",
]

PATTERNS: tuple[str, ...] = ("work/tmp/*.par",)

_MARKER = re.compile(r"\* Perturbed parameter set #(\d+)\s*")
_NUCLEUS = re.compile(r"\* Calculation for the nucleus Z =\s*(\d+)\s*,\s*A =\s*(\d+)")
_ENERGY = re.compile(r"\* formed by .* with En =\s*(\S+)\s*MeV")
_SPIN = re.compile(r"\* Spin of target nucleus =\s*(\S+)")
_PARAM = re.compile(r"(\S+) =( +)(\S+)( *)")


@dataclass(slots=True)
class ParLine:
    """``NAME =<gap><value>`` with the blanks after the value."""

    name: str
    gap: str
    value: str
    tail: str

    def text(self) -> str:
        return f"{self.name} ={self.gap}{self.value}{self.tail}"


@dataclass(slots=True)
class ParSet:
    run: list[str]
    number: int
    params: list[ParLine] = field(default_factory=lambda: [])

    @property
    def is_step_start(self) -> bool:
        return any(_NUCLEUS.match(line) for line in self.run)


@dataclass(slots=True)
class ParFile:
    """A parsed file. ``render`` writes exactly the bytes ``parse_text`` read."""

    sets: list[ParSet] = field(default_factory=lambda: [])
    trailer: list[str] = field(default_factory=lambda: [])
    eol: str = "\n"
    final_newline: bool = True


def _fail(name: str, lineno: int, message: str) -> ParseError:
    return ParseError(f"{name}:{lineno}: {message}")


def parse_text(text: str, name: str = "<par>") -> ParFile:
    """Parse the text of a par file (``name`` is only used in error messages)."""
    eol = "\r\n" if "\r\n" in text else "\n"
    if "\r" in text.replace("\r\n", ""):
        raise _fail(name, 1, "stray carriage return")
    lines = text.split(eol)
    final_newline = True
    if lines[-1] == "":
        lines.pop()
    else:
        final_newline = False
    par = ParFile(eol=eol, final_newline=final_newline)
    run: list[str] = []
    cur: ParSet | None = None
    for i, line in enumerate(lines):
        if line.startswith("*") or not line.strip():
            if cur is not None:
                cur = None
                run = []
            run.append(line)
            continue
        if cur is None:
            number = next((int(m.group(1)) for r in run if (m := _MARKER.fullmatch(r))), None)
            if number is None:
                raise _fail(name, i + 1, f"parameter line outside a parameter set: {line[:60]!r}")
            cur = ParSet(run, number)
            par.sets.append(cur)
        pm = _PARAM.fullmatch(line)
        if pm is None:
            raise _fail(name, i + 1, f"not a 'NAME = value' line: {line[:60]!r}")
        try:
            float(pm.group(3))
        except ValueError:
            raise _fail(name, i + 1, f"value is not a number: {pm.group(3)!r}") from None
        cur.params.append(ParLine(pm.group(1), pm.group(2), pm.group(3), pm.group(4)))
    if cur is None:
        # a comment run that ends the file; a run with a set marker and no parameters is a set
        number = next((int(m.group(1)) for r in run if (m := _MARKER.fullmatch(r))), None)
        if number is not None:
            par.sets.append(ParSet(run, number))
        else:
            par.trailer = run
    return par


def read(path: Path) -> ParFile:
    """Parse the par file at ``path``."""
    return parse_text(path.read_bytes().decode("utf-8", errors="surrogateescape"), str(path))


def render(par: ParFile) -> str:
    """The text of a parsed file, written back from the parsed form."""
    out: list[str] = []
    for s in par.sets:
        out.extend(s.run)
        out.extend(p.text() for p in s.params)
    out.extend(par.trailer)
    text = par.eol.join(out)
    if par.final_newline and out:
        text += par.eol
    return text


def roundtrip(path: Path) -> bytes:
    """Parse ``path`` and write it back; equals the file bytes."""
    return render(read(path)).encode("utf-8", errors="surrogateescape")


def _header_observables(run: list[str], rel: str, group: str) -> Iterator[tuple[Key, Value]]:
    for i, line in enumerate(run, 1):
        if line.strip() != "*" and _MARKER.fullmatch(line) is None:
            yield Key(rel, "header", group, "text", (i,)), line
        if (m := _NUCLEUS.match(line)) is not None:
            yield Key(rel, "header", group, "Z"), int(m.group(1))
            yield Key(rel, "header", group, "A"), int(m.group(2))
        elif (m := _ENERGY.match(line)) is not None:
            yield Key(rel, "header", group, "En"), float(m.group(1))
        elif (m := _SPIN.match(line)) is not None:
            yield Key(rel, "header", group, "spin"), float(m.group(1))


def _step_label(run: list[str]) -> str:
    for line in run:
        if (m := _ENERGY.match(line)) is not None:
            return f"E={m.group(1)}MeV"
    return "E=?"


def observables(path: Path, rel: str) -> Iterator[tuple[Key, Value]]:
    """All observables of the par file at ``path``; ``rel`` is the run-relative path."""
    par = read(path)
    labels: Counter[str] = Counter()
    group = ""
    names: Counter[tuple[str, int]] = Counter()
    for k, s in enumerate(par.sets):
        if k == 0 or s.is_step_start:
            label = _step_label(s.run)
            labels[label] += 1
            group = f"{label}#{labels[label]}"
            names.clear()
            yield from _header_observables(s.run, rel, group)
        for p in s.params:
            names[p.name, s.number] += 1
            n = names[p.name, s.number]
            index = (s.number,) if n == 1 else (s.number, n)
            yield Key(rel, "params", group, p.name, index), float(p.value)
