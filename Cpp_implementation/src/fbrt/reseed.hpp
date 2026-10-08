// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Per-scope reseed mode (harness/RESEED_SPEC.md; Python reference harness/reseed.py).

#pragma once

#include "fbrt/rng.hpp"

#include <cstdint>
#include <span>

namespace gef::fb {

// RESEED_SPEC.md section 4.
enum class ReseedScope : std::uint8_t {
    PrepassHistory = 1,
    Perturbation = 2,
    Event = 3,
};

// One SplitMix64 step: the output for state x.
[[nodiscard]] std::uint64_t splitmix64(std::uint64_t x) noexcept;

// RESEED_SPEC.md section 3: h = splitmix64(master); h = splitmix64(h ^ v) for v in
// (scope, tuple...), each as 64-bit two's complement; the seed is h >> 32.
[[nodiscard]] std::uint32_t derive_seed(std::uint32_t master, ReseedScope scope,
                                        std::span<std::int64_t const> tuple) noexcept;

// `Randomize derive_seed(...), 3` at the start of a scope instance. The caller must also
// clear any cached sampler value (the PGauss cache, M8), as the spec requires.
void reseed(FbMtRng& rng, std::uint32_t master, ReseedScope scope,
            std::span<std::int64_t const> tuple);

} // namespace gef::fb
