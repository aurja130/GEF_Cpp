// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

#include "fbrt/rng.hpp"

#include <cmath>
#include <stdexcept>

namespace gef::fb {

namespace {

constexpr std::size_t period = 397;
constexpr std::uint32_t matrix_a = 0x9908B0DFU;
constexpr std::uint32_t upper_mask = 0x80000000U;
constexpr std::uint32_t lower_mask = 0x7FFFFFFFU;

std::uint32_t mix(std::uint32_t a, std::uint32_t b, std::uint32_t far) noexcept {
    std::uint32_t const v = (a & upper_mask) | (b & lower_mask);
    return far ^ (v >> 1U) ^ ((v & 1U) != 0U ? matrix_a : 0U);
}

} // namespace

std::uint32_t randomize_seed_bits(double seed) noexcept {
    // cvttsd2si with a 64-bit destination: in range it truncates, otherwise (and for NaN)
    // it yields the "integer indefinite" 0x8000000000000000, whose low half is 0.
    if (std::isnan(seed) || seed < -0x1p63 || seed >= 0x1p63) {
        return 0U;
    }
    return static_cast<std::uint32_t>(static_cast<std::uint64_t>(static_cast<std::int64_t>(seed)));
}

FbMtRng::FbMtRng() noexcept {
    seed_state(0U);
}

FbMtRng::FbMtRng(double seed) {
    randomize(seed);
}

// math_rnd.c fb_Randomize (FB_RND_MTWIST case) -> hRndCtxInitMTWIST32
void FbMtRng::randomize(double seed) {
    if (seed == -1.0) {
        throw std::invalid_argument("Randomize -1 requests a clock seed; pass the seed instead");
    }
    seed_state(randomize_seed_bits(seed));
}

// NOLINTBEGIN(cppcoreguidelines-pro-bounds-avoid-unchecked-container-access): every index
// below is bounded by state_size through its loop limits or the index_ check; at() would
// add a check to each of the generator's per-draw accesses.
// math_rnd.c hRnd_FillFAST32: an LCG fill, not MT19937's init_genrand.
void FbMtRng::seed_state(std::uint32_t seed) noexcept {
    state_[0] = seed;
    for (std::size_t i = 1; i < state_size; ++i) {
        state_[i] = state_[i - 1] * 1664525U + 1013904223U;
    }
    index_ = state_size;
}

// math_rnd.c hRnd_MTWIST32, regeneration branch.
void FbMtRng::twist() noexcept {
    std::size_t i = 0;
    for (; i < state_size - period; ++i) {
        state_[i] = mix(state_[i], state_[i + 1], state_[i + period]);
    }
    for (; i < state_size - 1; ++i) {
        state_[i] = mix(state_[i], state_[i + 1], state_[i + period - state_size]);
    }
    state_[state_size - 1] = mix(state_[state_size - 1], state_[0], state_[period - 1]);
    index_ = 0;
}

// math_rnd.c hRnd_MTWIST32, tempering.
std::uint32_t FbMtRng::next_u32() noexcept {
    if (index_ >= state_size) {
        twist();
    }
    std::uint32_t v = state_[index_++];
    v ^= v >> 11U;
    v ^= (v << 7U) & 0x9D2C5680U;
    v ^= (v << 15U) & 0xEFC60000U;
    v ^= v >> 18U;
    return v;
}
// NOLINTEND(cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)

// math_rnd.c fb_Rnd -> hRnd_MTWIST
double FbMtRng::rnd(float n) noexcept {
    if (n != 0.0F) {
        last_ = static_cast<double>(next_u32()) / 4294967296.0;
    }
    return last_;
}

} // namespace gef::fb
