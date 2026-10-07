# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""The observable model shared by every parser and comparator in ``compare`` (M2).

Every parser turns one GEF output file into ``(Key, Value)`` pairs. A run directory becomes
an ``ObservableTable``: the union over all its files. Two tables from runs of the same input
have the same keys for the same quantities, so comparators work key by key.

``Key`` fields:

``file``
    POSIX path relative to the run directory (``stdout.log``, ``work/dmp/<step dir>/Apost.dmp``,
    ``work/ENDF/GEFY_86_214_n.dat``, ...).
``block``
    The named unit inside the file: an analyzer (``APOST``), an ``out/`` section
    (``Mass_yields``), an ENDF section (``MF8/MT454``), a probe (``P3``), ...
``group``
    Distinguishes repeated blocks in one file, as a deterministic string built from what the
    file itself says, e.g. ``E=18.5MeV#1`` (energy label as written plus a 1-based occurrence
    counter for that label) or ``tape2``. Empty when the block occurs once.
``label``
    The field inside the block (column or row name, record name). Empty when unnamed.
``index``
    Integer indices inside the field (array position, bin number, ZA and state, ...).

``Value`` is ``int``, ``float`` or ``str``. Text values are compared exactly (after masks);
numeric values are compared exactly or statistically depending on their class.

The **family** of a key (``Key.family``) is ``(file, block, group)``: the unit a statistical
test and a report line refer to (plan D7).
"""

from __future__ import annotations

from collections.abc import Iterable, Iterator, Mapping
from dataclasses import dataclass, field
from typing import NamedTuple

__all__ = ["Family", "Key", "ObservableTable", "Value"]

type Value = int | float | str


class Family(NamedTuple):
    file: str
    block: str
    group: str


@dataclass(frozen=True, slots=True, order=True)
class Key:
    file: str
    block: str
    group: str
    label: str
    index: tuple[int, ...] = ()

    @property
    def family(self) -> Family:
        return Family(self.file, self.block, self.group)

    def __str__(self) -> str:
        idx = ",".join(str(i) for i in self.index)
        parts = [self.file, self.block, self.group, self.label]
        return " | ".join(parts) + (f" [{idx}]" if idx else "")


@dataclass
class ObservableTable:
    """All observables of one run (or one file), keyed by ``Key``.

    ``unparsed`` lists files of the run that no parser claimed (relative paths); comparators
    report them instead of silently ignoring them.
    """

    values: dict[Key, Value] = field(default_factory=lambda: {})
    unparsed: list[str] = field(default_factory=lambda: [])

    def add(self, key: Key, value: Value) -> None:
        if key in self.values:
            raise ValueError(f"duplicate observable key: {key}")
        self.values[key] = value

    def extend(self, pairs: Iterable[tuple[Key, Value]]) -> None:
        for key, value in pairs:
            self.add(key, value)

    def families(self) -> dict[Family, list[Key]]:
        grouped: dict[Family, list[Key]] = {}
        for key in sorted(self.values):
            grouped.setdefault(key.family, []).append(key)
        return grouped

    def __len__(self) -> int:
        return len(self.values)

    def __iter__(self) -> Iterator[Key]:
        return iter(self.values)

    def items(self) -> Iterable[tuple[Key, Value]]:
        return self.values.items()

    @classmethod
    def from_mapping(cls, values: Mapping[Key, Value]) -> ObservableTable:
        return cls(dict(values))
