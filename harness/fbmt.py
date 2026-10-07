# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Pure-Python reference of the fbc 1.10.1 ``Randomize seed, 3`` + ``Rnd`` generator.

Transcribed from ``src/rtlib/math_rnd.c`` and ``fb_math.h`` at fbc tag ``1.10.1``:

* ``fb_Randomize(seed, 3)`` calls ``hRndCtxInitMTWIST32((uint32_t)seed)``, which fills
  the 624-word state with ``hRnd_FillFAST32``: ``s[0] = seed``,
  ``s[i] = s[i-1] * 1664525 + 1013904223 (mod 2^32)``, and sets the read index to the
  end of the state, so the first draw triggers a twist.
* ``hRnd_MTWIST32`` regenerates the state (MT19937 twist, ``PERIOD`` 397) when it is
  exhausted, then tempers one word (shifts 11, 7/0x9D2C5680, 15/0xEFC60000, 18).
* ``Rnd`` is ``(double)u32 / 4294967296.0``.

Note the seeding is *not* the reference MT19937 ``init_genrand`` (1812433253); it is the
LCG fill above. The twist and tempering are standard MT19937.

Usage::

    from harness.fbmt import FbMtRng
    rng = FbMtRng(42)
    rng.next_u32()   # first u32 of Randomize 42,3 : Rnd
    rng.rnd()        # next value as float, u32 / 2**32
"""

from __future__ import annotations

_MASK32 = 0xFFFFFFFF
_STATE_SIZE = 624
_PERIOD = 397
_MATRIX_A = 0x9908B0DF
_UPPER = 0x80000000
_LOWER = 0x7FFFFFFF
_LCG_MUL = 1664525
_LCG_ADD = 1013904223
_TWO32 = 4294967296.0


class FbMtRng:
    """The generator state after ``Randomize seed, 3``.

    ``seed`` is truncated to 32 bits like the C cast ``(uint32_t)seed``; it must be an
    integer in ``0 .. 2**32 - 1``.
    """

    __slots__ = ("_index", "_state")

    def __init__(self, seed: int) -> None:
        if not 0 <= seed <= _MASK32:
            raise ValueError(f"seed must be in 0..{_MASK32}, got {seed}")
        state = [seed]
        for _ in range(1, _STATE_SIZE):
            state.append((state[-1] * _LCG_MUL + _LCG_ADD) & _MASK32)
        self._state = state
        self._index = _STATE_SIZE

    def _twist(self) -> None:
        s = self._state
        n = _STATE_SIZE
        for i in range(n - 1):
            v = (s[i] & _UPPER) | (s[i + 1] & _LOWER)
            s[i] = s[(i + _PERIOD) % n] ^ (v >> 1) ^ (_MATRIX_A if v & 1 else 0)
        v = (s[n - 1] & _UPPER) | (s[0] & _LOWER)
        s[n - 1] = s[_PERIOD - 1] ^ (v >> 1) ^ (_MATRIX_A if v & 1 else 0)
        self._index = 0

    def next_u32(self) -> int:
        """The next 32-bit output (``hRnd_MTWIST32``)."""
        if self._index >= _STATE_SIZE:
            self._twist()
        v = self._state[self._index]
        self._index += 1
        v ^= v >> 11
        v ^= (v << 7) & 0x9D2C5680
        v ^= (v << 15) & 0xEFC60000
        v ^= v >> 18
        return v & _MASK32

    def rnd(self) -> float:
        """The next ``Rnd`` value, ``u32 / 2**32`` (exact in binary64)."""
        return self.next_u32() / _TWO32

    def u32_stream(self, count: int) -> list[int]:
        """The next ``count`` outputs as a list."""
        return [self.next_u32() for _ in range(count)]
