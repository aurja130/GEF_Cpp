# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for ``harness.probe_fingerprints``: grouping, hashing and golden rendering."""

from __future__ import annotations

import pytest

from harness.common import HarnessError
from harness.probe_fingerprints import (
    Fingerprint,
    fingerprints,
    fnv1a64,
    split_lines,
)

SYNTHETIC = (
    b"T0 - A - B S 0:1\n"
    b"T0 - A 0 S 00000000\n"
    b"T0 - A 1 S 3F800000\n"
    b"T0 - B - D 3FF0000000000000\n"
    b'T0 - C - Z "x"\n'
)


def test_fnv_empty_is_offset_basis() -> None:
    assert fnv1a64([]) == 0xCBF29CE484222325


def test_fnv_single_line_matches_reference() -> None:
    # FNV-1a 64 of b"T0 - X - I 1\n" (computed independently).
    assert fnv1a64([b"T0 - X - I 1"]) == 0x4082451E44ADCB29


def test_fnv_two_lines_are_chained() -> None:
    assert fnv1a64([b"T0 - X - I 1", b"T0 - X - I 2"]) == 0x8FBC97249931DE12


def test_groups_lines_by_name_in_order() -> None:
    rows = fingerprints(SYNTHETIC, "T0")
    assert [row.name for row in rows] == ["A", "B", "C"]
    assert [row.lines for row in rows] == [3, 1, 1]
    assert rows[1] == Fingerprint("B", 1, fnv1a64([b"T0 - B - D 3FF0000000000000"]))


def test_non_contiguous_variable_is_an_error() -> None:
    data = b"T0 - A - I 1\nT0 - B - I 2\nT0 - A 1 I 3\n"
    with pytest.raises(HarnessError, match="not contiguous"):
        fingerprints(data, "T0")


def test_wrong_probe_or_missing_record_is_an_error() -> None:
    with pytest.raises(HarnessError, match="not a T0 line"):
        fingerprints(b"T1 - A - I 1\n", "T0")
    with pytest.raises(HarnessError, match="no T0 record"):
        fingerprints(b"T0 step=1 A - I 1\n", "T0")


def test_context_selects_one_record() -> None:
    data = (
        b"P1 step=1 pass=- bin=- rec=1 A - I 1\n"
        b"P1 step=1 pass=- bin=- rec=1 B - I 2\n"
        b"P1 step=8 pass=- bin=- rec=2 A - I 3\n"
        b"P1 step=8 pass=- bin=- rec=2 B - I 4\n"
    )
    rows = fingerprints(data, "P1", "step=8 pass=- bin=- rec=2")
    assert rows == [
        Fingerprint("A", 1, fnv1a64([b"P1 step=8 pass=- bin=- rec=2 A - I 3"])),
        Fingerprint("B", 1, fnv1a64([b"P1 step=8 pass=- bin=- rec=2 B - I 4"])),
    ]


def test_split_lines_drops_only_the_final_newline() -> None:
    assert split_lines(b"a\nb\n") == [b"a", b"b"]
    assert split_lines(b"a\n\nb") == [b"a", b"", b"b"]
