# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Parser for GEF ENDF-6 tapes: MF8/MT454 independent fission-product yields.

A file may hold several concatenated tapes, each closed by a TEND record
(MAT = -1). :func:`parse_file` returns every tape; :func:`parse_tape` parses
one. Per incident energy the result is a list of :class:`Nuclide` records.

Record layout (ENDF-6): six 11-character fields in columns 1-66, then
MAT (67-70), MF (71-72), MT (73-75), NS (76-80). A HEAD record opens the
section (ZA, AWR, ...); each energy then has a LIST record
``E, 0, L1, L2, NPL, NFP`` followed by ``NPL = 4*NFP`` values
``ZAFP, FPS, Y, DY`` packed six per line.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from harness.common import HarnessError

__all__ = ["Nuclide", "Tape", "parse_endf_float", "parse_file", "parse_text"]

_FIELD_WIDTH = 11
_NFIELDS = 6
_FLOAT_RE = re.compile(r"^([+-]?(?:\d+\.?\d*|\.\d+))(?:[eEdD]?([+-]?\d+))?$")
_TARGET_MF = 8
_TARGET_MT = 454


@dataclass(frozen=True)
class Nuclide:
    """One fission product: ``za`` = 1000*Z + A, isomeric ``state`` (FPS), yield, uncertainty."""

    za: int
    state: int
    y: float
    dy: float

    @property
    def z(self) -> int:
        return self.za // 1000

    @property
    def a(self) -> int:
        return self.za % 1000


# energy [eV] -> nuclides, in file order
Tape = dict[float, list[Nuclide]]


def parse_endf_float(field: str) -> float:
    """Parse an ENDF number: ``1.234567-5`` (no ``E``), ``1.2E-5``, plain, or blank (0)."""
    s = field.strip()
    if not s:
        return 0.0
    m = _FLOAT_RE.match(s)
    if m is None:
        raise ValueError(f"not an ENDF number: {field!r}")
    mant, exp = m.groups()
    return float(mant + ("e" + exp if exp else ""))


def _fields(line: str) -> list[float]:
    padded = line.ljust(66)
    return [
        parse_endf_float(padded[i * _FIELD_WIDTH : (i + 1) * _FIELD_WIDTH]) for i in range(_NFIELDS)
    ]


def _control(line: str) -> tuple[int, int, int]:
    """(MAT, MF, MT) of a record line; (0, 0, 0) when the columns are blank."""
    try:
        mat = int(line[66:70])
        mf = int(line[70:72] or 0)
        mt = int(line[72:75] or 0)
    except ValueError:
        return (0, 0, 0)
    return (mat, mf, mt)


def _split_tapes(lines: list[str]) -> list[list[str]]:
    tapes: list[list[str]] = []
    cur: list[str] = []
    for line in lines:
        cur.append(line)
        if _control(line.ljust(80))[0] == -1:
            tapes.append(cur)
            cur = []
    if any(ln.strip() for ln in cur):
        tapes.append(cur)
    return tapes


def _parse_section(rows: list[str], where: str) -> Tape:
    tape: Tape = {}
    if not rows:
        return tape
    pos = 1  # row 0 is the HEAD record
    while pos < len(rows):
        head = _fields(rows[pos])
        energy = head[0]
        npl, nfp = int(head[4]), int(head[5])
        if npl != 4 * nfp:
            raise HarnessError(f"{where}: LIST at E={energy:g} has NPL={npl} != 4*NFP={4 * nfp}")
        nlines = -(-npl // _NFIELDS)
        body = rows[pos + 1 : pos + 1 + nlines]
        if len(body) < nlines:
            raise HarnessError(f"{where}: truncated LIST at E={energy:g}")
        vals = [v for row in body for v in _fields(row)][:npl]
        if energy in tape:
            raise HarnessError(f"{where}: duplicate energy {energy:g}")
        tape[energy] = [
            Nuclide(int(vals[i]), int(vals[i + 1]), vals[i + 2], vals[i + 3])
            for i in range(0, npl, 4)
        ]
        pos += 1 + nlines
    return tape


def parse_text(text: str, where: str = "<text>") -> list[Tape]:
    """Parse every tape in ``text``; each tape is ``{energy: [Nuclide, ...]}``."""
    lines = text.splitlines()
    out: list[Tape] = []
    for idx, tape_lines in enumerate(_split_tapes(lines)):
        rows: list[str] = []
        for ln in tape_lines:
            _mat, mf, mt = _control(ln.ljust(80))
            if mf == _TARGET_MF and mt == _TARGET_MT:
                rows.append(ln)
        try:
            out.append(_parse_section(rows, f"{where} tape {idx}"))
        except ValueError as exc:
            raise HarnessError(f"{where} tape {idx}: {exc}") from exc
    return out


def parse_file(path: Path) -> list[Tape]:
    """Parse every tape of an ENDF file (latin-1 text)."""
    try:
        text = path.read_text(encoding="latin-1")
    except OSError as exc:
        raise HarnessError(f"cannot read {path}: {exc}") from exc
    return parse_text(text, str(path))
