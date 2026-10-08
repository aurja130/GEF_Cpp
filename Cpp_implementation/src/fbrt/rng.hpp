// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

// FbMtRng: the fbc 1.10.1 runtime generator behind `Randomize seed, 3` and `Rnd`
// (src/rtlib/math_rnd.c, FB_RND_MTWIST). Python reference: harness/fbmt.py.

#pragma once

#include <array>
#include <cstddef>
#include <cstdint>

namespace gef::fb {

// The 32-bit seed that fb_Randomize derives from its Double argument: the C cast
// `(uint32_t)seed`, which x86-64 gcc compiles to a truncating conversion to int64 followed
// by keeping the low 32 bits. Fractions truncate towards zero, negative values wrap
// (-2 -> 0xFFFFFFFE), and values outside the int64 range (and NaN) give 0.
[[nodiscard]] std::uint32_t randomize_seed_bits(double seed) noexcept;

class FbMtRng {
public:
    // The state of a program that has not executed Randomize: the runtime seeds lazily
    // with fb_Randomize(0.0) on the first Rnd, which is the same stream as seed 0.
    FbMtRng() noexcept;
    explicit FbMtRng(double seed);

    // `Randomize seed, 3`: replaces the whole state; the value Rnd(0) repeats is kept.
    // seed == -1.0 is the runtime's request for a clock seed, which is not reproducible;
    // pass the seed itself instead (throws std::invalid_argument).
    void randomize(double seed);

    // `Rnd(n)`: n == 0 repeats the last value returned by Rnd (0.0 before the first);
    // any other n, including negative ones, draws the next value u32 / 2^32.
    [[nodiscard]] double rnd(float n = 1.0F) noexcept;

    // The next 32-bit output (fb_Rnd32); does not change the value Rnd(0) repeats.
    [[nodiscard]] std::uint32_t next_u32() noexcept;

private:
    static constexpr std::size_t state_size = 624;

    void seed_state(std::uint32_t seed) noexcept;
    void twist() noexcept;

    std::array<std::uint32_t, state_size> state_{};
    std::size_t index_ = state_size;
    double last_ = 0.0;
};

} // namespace gef::fb
