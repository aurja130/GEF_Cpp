# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""The last-writer map of the P3 variables over the table-builder blocks (M7.0, plan D9).

``MILESTONE_7_PLAN.md`` D9: sub-milestone M7.k compares, from each record's P3in state, every P3
variable whose last writer in a bin lies in M7.1 ... M7.k. This module derives the map from the C
that fbc emits for GEF.bas:5578-7920 (``tools.fbsrc.rbw writers``) and the block cut of plan
section 3, and writes ``harness/inputs/m7/last_writer.tsv``::

    # m7 last-writer map 1
    # <name> <kind> <last part> <writers>
    <name> <S|I|D|A> <M7.1|...|M7.4|input> <line>:<part>[=<target>][@<procedure>] ...

- One line per P3 variable, in P3's order (``harness_probe_p3.bi``).
- ``kind``: ``A`` for an array, else the scalar's probe type.
- ``writers``: every BASIC line of the stretch that writes the variable, in program (C) order;
  for an array the BASIC text of the written element follows ``=`` (``Beta(1,1,IZ1)``); a write
  made inside a procedure called at the line carries ``@<procedure>``; a scalar passed ``ByRef``
  counts as written at the call. ``-`` when nothing in the stretch writes it.
- ``last part``: the part of the last writer in program order, i.e. of the block that writes it
  last in a bin (the blocks run in program order, loops stay inside their block). ``input`` when
  nothing in the stretch writes the variable (P3in holds its value, P3 must equal it).
  An array written by several parts lists each writer's part; which elements a part writes is
  read from the targets.

Usage from the repository root: ``python3 -m harness.last_writer [--check]``
(``--check`` exits 1 when the committed map differs from a fresh derivation).
"""

from __future__ import annotations

import argparse
import re
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import Final

from harness.common import INPUTS_DIR, PATCHES_DIR, HarnessError
from tools.fbsrc.common import FbsrcError
from tools.fbsrc.fbdef import find_definitions, source_line
from tools.fbsrc.rbw import analyse, program_for, writers

MAP_PATH: Final[Path] = INPUTS_DIR / "m7" / "last_writer.tsv"
HEADER: Final[tuple[str, str]] = (
    "# m7 last-writer map 1",
    "# <name> <kind> <last part> <writers>",
)
STRETCH: Final[str] = "GEF.bas:5578-7920"
# MILESTONE_7_PLAN.md section 3: the parts of the table builder by BASIC line.
BLOCKS: Final[tuple[tuple[int, int, str], ...]] = (
    (5578, 6062, "M7.1"),
    (6063, 6560, "M7.2"),
    (6561, 7039, "M7.3"),
    (7040, 7511, "M7.4"),
    (7920, 7920, "M7.3"),
)
_HP_LINE: Final = re.compile(r"\s*HP_(V|A1|S[1-4])\((\w+)\)")


def part_of(line: int) -> str:
    for first, last, part in BLOCKS:
        if first <= line <= last:
            return part
    raise HarnessError(f"GEF.bas:{line} is in no block of the plan")


def p3_variables() -> list[tuple[str, bool]]:
    """(name, is_array) of every P3 variable, in dump order."""
    text = (PATCHES_DIR / "probes.patch").read_text(encoding="latin-1")
    body = text.split("+++ b/harness_probe_p3.bi", 1)[1].split("\n--- ", 1)[0]
    out: list[tuple[str, bool]] = []
    for line in body.splitlines():
        m = _HP_LINE.match(line[1:]) if line.startswith("+") else None
        if m is not None:
            out.append((m.group(2), m.group(1) != "V"))
    return out


_BASIC_TYPE: Final = re.compile(r"\bAs\s+(Single|Double|Integer|LongInt|Long)\b", re.IGNORECASE)
_TYPE_CODE: Final = {"single": "S", "double": "D", "integer": "I", "longint": "I", "long": "I"}


def _declared_kind(name: str) -> str:
    """The probe type of a variable from its BASIC declaration (``Dim Shared As Single x``)."""
    for tag in find_definitions(name):
        if tag.kind == "variable":
            m = _BASIC_TYPE.search(source_line(tag.path, tag.line))
            if m is not None:
                return _TYPE_CODE[m.group(1).lower()]
    raise HarnessError(f"{name}: no BASIC declaration with a numeric type")


def derive() -> str:
    analysis = analyse(STRETCH)
    program = program_for()
    written = writers(analysis, program)
    in_stretch: dict[str, set[str]] = {}
    for node in analysis.nodes:
        for v in node.uses | node.defs | node.element_writes | node.byref:
            in_stretch.setdefault(v.split("$", 1)[0], set()).add(v)
    for v in written:
        in_stretch.setdefault(v.split("$", 1)[0], set()).add(v)

    def resolve(name: str) -> str | None:
        """The fbc variable of a P3 name; None when the program never uses it."""
        found = in_stretch.get(name.upper(), set())
        if not found:  # not mentioned in the stretch: a module or step-body variable
            found = {
                v for v in (f"{name.upper()}${s}" for s in ("", "0", "8")) if v in program.types
            }
            found = set(sorted(found, key=len)[:1])
        if not found:
            return None
        if len(found) != 1:
            raise HarnessError(f"{name}: {len(found)} variables of that name in {STRETCH}")
        return next(iter(found))

    lines: list[str] = list(HEADER)
    for name, is_array in p3_variables():
        var = resolve(name)
        ws = written.get(var, []) if var is not None else []
        if is_array:
            kind = "A"
        elif var is None:  # never used by the program, so fbc emits no C for it
            kind = _declared_kind(name)
        else:
            kind = program.type_code(var)
        if not ws:
            lines.append(f"{name} {kind} input -")
            continue
        cells = [
            f"{w.basic_line}:{part_of(w.basic_line)}"
            + (f"={w.target}" if w.target else "")
            + (f"@{w.via}" if w.via else "")
            for w in ws
        ]
        lines.append(f"{name} {kind} {part_of(ws[-1].basic_line)} {' '.join(cells)}")
    return "".join(f"{line}\n" for line in lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Derive the M7 last-writer map.")
    parser.add_argument("--check", action="store_true", help="compare with the committed map")
    args = parser.parse_args(argv)
    try:
        text = derive()
    except (HarnessError, FbsrcError) as exc:
        print(f"last_writer: {exc}", file=sys.stderr)
        return 2
    if args.check:
        if not MAP_PATH.is_file() or MAP_PATH.read_text(encoding="utf-8") != text:
            print(f"last_writer: {MAP_PATH} is stale", file=sys.stderr)
            return 1
        return 0
    MAP_PATH.write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote {MAP_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
