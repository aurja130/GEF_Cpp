# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the probe adapter."""

from __future__ import annotations

import math
import struct
from pathlib import Path

import pytest

from compare.model import Key
from compare.parsers import ParseError, probe
from compare.parsers.probe import Single
from harness.probes import encode_double, encode_single

_X = 0.1
_S = 1.0000001192092896  # 0x3F800001


def _write(tmp_path: Path, lines: list[str]) -> Path:
    path = tmp_path / "P1.txt"
    path.write_text("\n".join(lines) + "\n", encoding="latin-1")
    return path


def test_exact_values_and_keys(tmp_path: Path) -> None:
    ctx = "step=2 pass=- bin=- rec=1"
    path = _write(
        tmp_path,
        [
            f"P1 {ctx} N - I 11",
            f'P1 {ctx} Name - Z "a\\x41b"',
            f"P1 {ctx} D - D {encode_double(_X)}",
            f"P1 {ctx} S - S 3F800001",
            f"P1 {ctx} T - BS S 0:1,1:2",
            f"P1 {ctx} T 0,1 S {encode_single(1.5)}",
            f"P1 {ctx} T 1,2 S 80000000",
            f"P1 {ctx} Q - BS D 1:3",
            f"P1 {ctx} Q 2 D {encode_double(-2.5)}",
        ],
    )
    obs = dict(probe.observables(path, "work/probes/P1.txt"))
    g = ctx
    f = "work/probes/P1.txt"
    assert obs[Key(f, "P1", g, "N")] == 11
    assert obs[Key(f, "P1", g, "Name")] == "aAb"
    d = obs[Key(f, "P1", g, "D")]
    assert isinstance(d, float)
    assert d.hex() == _X.hex()
    assert not isinstance(d, Single)
    s = obs[Key(f, "P1", g, "S")]
    assert isinstance(s, Single)
    assert struct.pack("<f", s).hex() == "0100803f"
    assert s == _S
    neg_zero = obs[Key(f, "P1", g, "T", (1, 2))]
    assert isinstance(neg_zero, Single)
    assert math.copysign(1.0, neg_zero) == -1.0
    assert obs[Key(f, "P1", g, "T", (0, 1))] == 1.5
    assert obs[Key(f, "P1", g, "T.bounds")] == "sparse S 0:1,1:2"
    assert obs[Key(f, "P1", g, "Q.bounds")] == "sparse D 1:3"
    assert obs[Key(f, "P1", g, "Q", (2,))] == -2.5
    assert Key(f, "P1", g, "Q", (1,)) not in obs


def test_t0_context_and_repeated_context(tmp_path: Path) -> None:
    path = _write(tmp_path, ["T0 - A - I 1", 'T0 - C 1 Z "H"'])
    obs = dict(probe.observables(path, "work/probes/T0.txt"))
    assert obs[Key("work/probes/T0.txt", "T0", "", "A")] == 1
    assert obs[Key("work/probes/T0.txt", "T0", "", "C", (1,))] == "H"


def test_bad_file_raises_parse_error(tmp_path: Path) -> None:
    path = _write(tmp_path, ["garbage"])
    with pytest.raises(ParseError):
        list(probe.observables(path, "work/probes/P1.txt"))


def test_rnd_log_unparsed_by_design() -> None:
    assert "work/rnd.log" in probe.UNPARSED_BY_DESIGN
