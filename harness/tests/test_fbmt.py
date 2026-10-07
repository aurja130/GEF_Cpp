# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Known-answer tests for ``harness.fbmt`` (values from the real ``rnd_stream`` driver)."""

from __future__ import annotations

import pytest

from harness.fbmt import FbMtRng

# `Randomize 42, 3` then Rnd, as u32 hex, from fbc 1.10.1 (rnd_stream_42.txt, 1-based lines).
FIRST_8 = [
    "ddd3aaa9",
    "20375d07",
    "60e5a046",
    "a015a7ca",
    "3dd3afb2",
    "afbcbe56",
    "23c546ec",
    "544de98b",
]
LINES_624_626 = ["bf531ccb", "650dc6d1", "10d8be9d"]  # first draws after the first re-twist
LINE_1000000 = "d2e1d5f4"


def test_known_answers_seed_42() -> None:
    rng = FbMtRng(42)
    values = [f"{rng.next_u32():08x}" for _ in range(1_000_000)]
    assert values[:8] == FIRST_8
    assert values[623:626] == LINES_624_626
    assert values[-1] == LINE_1000000


def test_rnd_is_u32_over_2_pow_32() -> None:
    a, b = FbMtRng(42), FbMtRng(42)
    for _ in range(50):
        u = a.next_u32()
        r = b.rnd()
        assert r == u / 2**32
        assert 0.0 <= r < 1.0
        assert round(r * 4294967296.0) == u


def test_seed_zero_differs_and_is_deterministic() -> None:
    assert FbMtRng(0).u32_stream(5) == FbMtRng(0).u32_stream(5)
    assert FbMtRng(0).u32_stream(5) != FbMtRng(1).u32_stream(5)


@pytest.mark.parametrize("seed", [-1, 2**32])
def test_seed_out_of_range(seed: int) -> None:
    with pytest.raises(ValueError, match="seed"):
        FbMtRng(seed)
