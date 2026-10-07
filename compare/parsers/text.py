# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Generic template-keyed text parser: the lowest-priority fallback (M2.1).

Used for every file no specific parser claims (``stdout.log``, ``stderr.log``,
``work/tmp/ParameterUpdate.dat``, ``work/ctl/*``, ``work/file.in``, ``work/in/*``, ...).

Each non-blank line becomes a *template* (the line with every number token replaced by ``#``).
The k-th occurrence of a template in the file (1-based) gives the key label ``"<template> #<k>"``:

* ``index == ()``: the template text itself (``str``), so changed wording is visible;
* ``index == (p,)``: the p-th number token (1-based) of that line, as ``int`` or ``float``.

Keys do not depend on line numbers, so inserted or removed lines do not shift unrelated keys.
Time-dependent fields of ``harness/masks.toml`` are replaced by ``<MASK:id>`` before templating
and are not emitted. Blank lines carry no information and are not emitted; the round trip keeps
every line.
"""

from __future__ import annotations

import re
from collections import Counter
from collections.abc import Iterator
from functools import cache
from pathlib import Path

import harness
from compare.model import Key, Value
from harness.compare_runs import Mask, load_masks

__all__ = ["PATTERNS", "observables", "roundtrip", "template_of"]

PATTERNS: tuple[str, ...] = ("*",)

_NUMBER = re.compile(r"(?:(?<![\w.])[-+])?(?:\d+\.\d*|\.\d+|\d+)(?:[eEdD][-+]?\d+)?")
_INTEGER = re.compile(r"[-+]?\d+")
_BLOCK = "text"


@cache
def _masks() -> tuple[Mask, ...]:
    return tuple(load_masks(Path(harness.__file__).resolve().parent / "masks.toml"))


def _apply_masks(line: str, masks: list[Mask]) -> str:
    for mask in masks:
        line = mask.pattern.sub(f"<MASK:{mask.id}>", line)
    return line


def _number(token: str) -> Value:
    if _INTEGER.fullmatch(token):
        return int(token)
    return float(token.replace("d", "e").replace("D", "e"))


def template_of(line: str) -> tuple[str, list[Value]]:
    """Template of one (already masked) line and its number tokens."""
    numbers: list[Value] = [_number(m.group()) for m in _NUMBER.finditer(line)]
    return _NUMBER.sub("#", line), numbers


def _lines(path: Path) -> list[str]:
    text = path.read_bytes().decode("latin-1")
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    return lines


def observables(path: Path, rel: str) -> Iterator[tuple[Key, Value]]:
    masks = [m for m in _masks() if m.applies_to(rel)]
    seen: Counter[str] = Counter()
    for raw in _lines(path):
        template, numbers = template_of(_apply_masks(raw, masks))
        if not template.strip() and not numbers:
            continue
        seen[template] += 1
        label = f"{template} #{seen[template]}"
        yield Key(rel, _BLOCK, "", label), template
        for position, number in enumerate(numbers, start=1):
            yield Key(rel, _BLOCK, "", label, (position,)), number


def roundtrip(path: Path) -> bytes:
    """Rebuild the file from its lines (trivial: the text parser keeps every line)."""
    data = path.read_bytes()
    lines = data.decode("latin-1").split("\n")
    return "\n".join(lines).encode("latin-1")
