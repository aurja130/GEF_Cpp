// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Each function follows its generated C (python3 -m tools.fbsrc.fbline <location>), including
// fbc's branch polarity, which decides what happens for NaN.

#include "fbrt/gef_math.hpp"

#include "fbrt/convert.hpp"

#include <cmath>
#include <stdexcept>

namespace gef::fb {

// utilities.bi:18-26 (GEF.c: if (R1 >= R2) Rmin = R2 else Rmin = R1)
float min(float r1, float r2) noexcept {
    return r1 >= r2 ? r2 : r1;
}

// utilities.bi:28-36 (GEF.c: if (R1 <= R2) Rmax = R2 else Rmax = R1)
float max(float r1, float r2) noexcept {
    return r1 <= r2 ? r2 : r1;
}

// utilities.bi:47
float erf(float x) noexcept {
    float const vr1 = erfc(x);
    return static_cast<float>(-static_cast<double>(vr1) + 0x1.p+0);
}

// utilities.bi:53-62 (Numerical Recipes erfc; polynomial nested as in GEF.c)
float erfc(float x) noexcept {
    auto const z = static_cast<double>(std::fabs(x));
    double const t = 0x1.p+0 / ((z * 0x1.p-1) + 0x1.p+0);
    double inner = (t * 0x1.5DF28AF76A5A4p-3) + -0x1.A4F123185DEFDp-1;
    inner = (t * inner) + 0x1.7D0F60453A1BEp+0;
    inner = (t * inner) + -0x1.229CBA606398p+0;
    inner = (t * inner) + 0x1.1D8F976231CE6p-2;
    inner = (t * inner) + -0x1.7D84982AAEAA5p-3;
    inner = (t * inner) + 0x1.8C6D917DEC3Fp-4;
    inner = (t * inner) + 0x1.7F11F677960EAp-2;
    inner = (t * inner) + 0x1.00018D48D3588p+0;
    double const r = t * std::exp(((-z * z) + (t * inner)) + -0x1.43F89C0889BC5p+0);
    // GEF.c: if (X >= 0) result = R else result = 2 - R; NaN takes the 2 - R branch.
    if (x >= 0x0p+0F) {
        return static_cast<float>(r);
    }
    return static_cast<float>(0x1.p+1 - r);
}

// utilities.bi:66-72 (GEF.c: if (X < 0) negative branch; NaN takes the positive one)
float tanh(float x) noexcept {
    if (x < 0x0p+0F) {
        return static_cast<float>(static_cast<double>(std::exp(x * 0x1.p+1F) + -0x1.p+0F) /
                                  static_cast<double>(std::exp(x * 0x1.p+1F) + 0x1.p+0F));
    }
    return static_cast<float>(static_cast<double>(-(std::exp(x * -0x1.p+1F)) + 0x1.p+0F) /
                              static_cast<double>(std::exp(x * -0x1.p+1F) + 0x1.p+0F));
}

// utilities.bi:76-82 (same branch polarity as Tanh)
float coth(float x) noexcept {
    if (x < 0x0p+0F) {
        return static_cast<float>(static_cast<double>(std::exp(x * 0x1.p+1F) + 0x1.p+0F) /
                                  static_cast<double>(std::exp(x * 0x1.p+1F) + -0x1.p+0F));
    }
    return static_cast<float>(static_cast<double>(std::exp(x * -0x1.p+1F) + 0x1.p+0F) /
                              static_cast<double>(-(std::exp(x * -0x1.p+1F)) + 0x1.p+0F));
}

// utilities.bi:86: Log(10) is folded by fbc to ln 10 in Double.
float log10(float r) noexcept {
    // NOLINTNEXTLINE(modernize-use-std-numbers): the literal is the one in GEF.c
    return static_cast<float>(static_cast<double>(std::log(r)) / 0x1.26BB1BBB55516p+1);
}

// GEF.bas:18053
float floor(float r) noexcept {
    return std::floor(r);
}

// GEF.bas:18057-18061 (GEF.c: if (R <= Floor(R)) result = R else result = Floor(R) + 1)
float ceil(float r) noexcept {
    if (r <= floor(r)) {
        return r;
    }
    return floor(r) + 0x1.p+0F;
}

// GEF.bas:18069-18081 (GEF.c: if (R != 0) compute, else 0; NaN computes)
float round(float r, std::int64_t n) noexcept {
    if (!(r != 0x0p+0F)) {
        return 0x0p+0F;
    }
    auto const isign = static_cast<std::int64_t>(sgn(r));
    float const rabs = std::fabs(r);
    std::int64_t const n10 = f2l(std::floor(log10(rabs)));
    auto const rn10 = static_cast<float>(std::pow(0x1.4p+3, static_cast<double>(n10)));
    auto const rred = static_cast<float>(static_cast<double>(rabs) / static_cast<double>(rn10));
    double const scale = std::pow(0x1.4p+3, static_cast<double>(add(n, std::int64_t{-1})));
    auto const rextended = static_cast<float>(static_cast<double>(rred) * scale);
    auto const rrounded = static_cast<float>(fix(static_cast<double>(rextended) + 0x1.p-1));
    double const unscale = std::pow(0x1.4p+3, static_cast<double>(add(n, std::int64_t{-1})));
    auto const rout =
        static_cast<float>((static_cast<double>(rrounded) / unscale) * static_cast<double>(rn10));
    return static_cast<float>(isign) * rout;
}

// GEF.bas:18086-18088 (unsigned arithmetic, result reinterpreted as LongInt)
std::int64_t modulo(std::uint64_t i, std::uint64_t j) {
    if (j == 0) {
        throw std::domain_error("Modulo by zero (SIGFPE in the compiled BASIC)");
    }
    std::uint64_t const iratio = i / j;
    std::uint64_t const iresult = i - (j * iratio);
    return static_cast<std::int64_t>(iresult);
}

} // namespace gef::fb
