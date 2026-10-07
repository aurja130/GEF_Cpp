# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Reference implementation of the per-event reseed seed derivation (``RESEED_SPEC.md``).

``derive_seed(master, scope_id, *tuple)`` returns the 32-bit argument of
``Randomize <seed>, 3`` that the ``reseed`` harness patch uses at the start of a scope
instance. The same function, with the same test vectors, is what the C++ port reproduces.
"""

from __future__ import annotations

__all__ = [
    "DERIVE_VECTORS",
    "SCOPE_EVENT",
    "SCOPE_NAMES",
    "SCOPE_PERTURBATION",
    "SCOPE_PREPASS_HISTORY",
    "SPLITMIX64_VECTORS",
    "TUPLE_FIELDS",
    "derive_seed",
    "splitmix64",
]

_MASK64 = 0xFFFFFFFFFFFFFFFF
_GAMMA = 0x9E3779B97F4A7C15
_MUL1 = 0xBF58476D1CE4E5B9
_MUL2 = 0x94D049BB133111EB

SCOPE_PREPASS_HISTORY = 1
SCOPE_PERTURBATION = 2
SCOPE_EVENT = 3

SCOPE_NAMES: dict[int, str] = {
    SCOPE_PREPASS_HISTORY: "prepass-history",
    SCOPE_PERTURBATION: "perturbation-block",
    SCOPE_EVENT: "event",
}

# BASIC loop counters that identify a scope instance, in hashing order.
TUPLE_FIELDS: dict[int, tuple[str, ...]] = {
    SCOPE_PREPASS_HISTORY: ("Ifilein", "Iline", "I_Double_Covar", "I_E_step", "K"),
    SCOPE_PERTURBATION: ("Ifilein", "Iline", "I_Double_Covar", "I_E_step", "I_Error"),
    SCOPE_EVENT: (
        "Ifilein",
        "Iline",
        "I_Double_Covar",
        "I_E_step",
        "I_Error",
        "I_E_Distr",
        "I_N_Multi",
        "I_Z_Multi",
        "I_E_Multi",
        "ILoop",
    ),
}


def splitmix64(x: int) -> int:
    """One SplitMix64 step: the output for state ``x`` (all arithmetic mod 2**64)."""
    x = (x + _GAMMA) & _MASK64
    z = x
    z = ((z ^ (z >> 30)) * _MUL1) & _MASK64
    z = ((z ^ (z >> 27)) * _MUL2) & _MASK64
    return z ^ (z >> 31)


def derive_seed(master: int, scope_id: int, *tuple_values: int) -> int:
    """The ``Randomize`` seed (0 .. 2**32 - 1) of one scope instance.

    ``h = splitmix64(master)``; then for ``v`` in ``scope_id, *tuple_values`` (each as a
    64-bit two's-complement integer) ``h = splitmix64(h ^ v)``; the result is ``h >> 32``.
    """
    if not 0 <= master <= 0xFFFFFFFF:
        raise ValueError(f"master seed must be in 0..4294967295, got {master}")
    h = splitmix64(master)
    for value in (scope_id, *tuple_values):
        if not -(1 << 63) <= value < (1 << 63):
            raise ValueError(f"tuple element does not fit a signed 64-bit integer: {value}")
        h = splitmix64(h ^ (value & _MASK64))
    return h >> 32


# (master, scope_id, tuple, seed). Generated once from the definition above; every implementation
# (this module, the BASIC harness_reseed.bi, the C++ port) must reproduce them.
SPLITMIX64_VECTORS: tuple[tuple[int, int], ...] = (
    (0x0000000000000000, 0xE220A8397B1DCDAF),
    (0x0000000000000001, 0x910A2DEC89025CC1),
    (0x0000000000000002, 0x975835DE1C9756CE),
    (0x123456789ABCDEF0, 0x161922C645CE50E8),
    (0xFFFFFFFFFFFFFFFF, 0xE4D971771B652C20),
)

DERIVE_VECTORS: tuple[tuple[int, int, tuple[int, ...], int], ...] = (
    (0, 1, (), 146079144),
    (0, 1, (0, 0, 0, 0, 0), 3023585711),
    (1, 3, (1, 1, 0, 1, 0, 0, 0, 0, 0, 1), 1149470725),
    (42, 3, (1, 1, 1, 1, 0, 1, 0, 0, 1000, 1), 2490878954),
    (42, 3, (1, 1, 1, 1, 0, 1, 0, 0, 1000, 2), 4268762869),
    (4294967295, 3, (1, 1, 1, 1, 0, 1, 0, 0, 1000, 316228), 70534132),
    (4294967295, 2, (1, 1, 1, 1, 31), 1098892256),
    (12345, 1, (1, 1, 1, 1, 0), 4271272159),
    (12345, 1, (1, 1, 1, 1, 316227), 237973617),
    (12345, 3, (-1, -2, -3, -4, -5, -6, -7, -8, -9, -10), 2360404655),
    (2147483648, 1, (-9223372036854775808, 9223372036854775807, 0, 1, -1), 824028776),
    (987654321, 2, (2, 7, 1, 4, 12), 2980720164),
    (7, 3, (), 1806334056),
    (0, 3, (1099511627776, -1099511627776), 1991928469),
)
