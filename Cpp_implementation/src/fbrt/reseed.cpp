// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "fbrt/reseed.hpp"

namespace gef::fb {

std::uint64_t splitmix64(std::uint64_t x) noexcept {
    std::uint64_t z = x + 0x9E3779B97F4A7C15ULL;
    z = (z ^ (z >> 30U)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27U)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31U);
}

std::uint32_t derive_seed(std::uint32_t master, ReseedScope scope,
                          std::span<std::int64_t const> tuple) noexcept {
    std::uint64_t h = splitmix64(master);
    h = splitmix64(h ^ static_cast<std::uint64_t>(scope));
    for (std::int64_t const value : tuple) {
        h = splitmix64(h ^ static_cast<std::uint64_t>(value));
    }
    return static_cast<std::uint32_t>(h >> 32U);
}

void reseed(FbMtRng& rng, std::uint32_t master, ReseedScope scope,
            std::span<std::int64_t const> tuple) {
    rng.randomize(static_cast<double>(derive_seed(master, scope, tuple)));
}

} // namespace gef::fb
