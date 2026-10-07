# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Adapter over ``harness.probes``: probe files as observables (M2.1).

Key: ``block`` = probe id (``T0``, ``P1``, ...), ``group`` = the record context as written
(``step=3 pass=- bin=- rec=1``; empty for T0; a repeated identical context gets ``#<n>``,
n >= 2), ``label`` = variable name, ``index`` = element indices.

Values are exact: ``S`` (Single) values are ``Single`` instances (a ``float`` subclass holding
the exactly widened binary32 value, so comparators can measure binary32 ULP distance), ``D``
values are ``float``, ``I`` are ``int``, ``Z`` are ``str``. Only elements present in the file
are emitted; omitted elements of a sparse array are zero by definition and are not keys, but
the bounds of every array are emitted as ``<NAME>.bounds`` strings so extent changes show.

``work/rnd.log`` (draw log, up to hundreds of MB) is not parsed: it is compared byte-exact
elsewhere.
"""

from __future__ import annotations

from collections import Counter
from collections.abc import Iterator
from pathlib import Path

from compare.model import Key, Value
from compare.parsers import ParseError
from harness.probes import ProbeFormatError, read_probe_file

__all__ = ["PATTERNS", "UNPARSED_BY_DESIGN", "Single", "observables"]

PATTERNS: tuple[str, ...] = ("work/probes/*.txt",)
UNPARSED_BY_DESIGN: tuple[str, ...] = ("work/rnd.log",)


class Single(float):
    """A binary32 value stored exactly as a Python float."""

    __slots__ = ()


def observables(path: Path, rel: str) -> Iterator[tuple[Key, Value]]:
    try:
        records = read_probe_file(path)
    except ProbeFormatError as exc:
        raise ParseError(f"{rel}: {exc}") from exc
    seen: Counter[tuple[str, str]] = Counter()
    for record in records:
        group = " ".join(f"{k}={v}" for k, v in record.context.items())
        seen[record.probe, group] += 1
        if seen[record.probe, group] > 1:
            group += f"#{seen[record.probe, group]}"
        for name, var in record.variables.items():
            if var.bounds is not None:
                text = ",".join(f"{lo}:{hi}" for lo, hi in var.bounds)
                yield (
                    Key(rel, record.probe, group, f"{name}.bounds"),
                    f"{'sparse' if var.sparse else 'dense'} {var.type} {text}",
                )
            for index, value in var.items():
                out: Value = (
                    Single(value) if var.type == "S" and isinstance(value, float) else value
                )
                yield Key(rel, record.probe, group, name, index), out
