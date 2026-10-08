// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

#include "fbrt/convert.hpp"

#include <bit>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace gef::fb {

namespace {

// cvttss2si/cvttsd2si: truncate; NaN and values whose truncation does not fit give the
// minimum of the destination type. Called only with integral values (after nearbyint) or
// with the operands of the unsigned sequence below.
template <typename Int, typename Real>
Int truncate_indefinite(Real v) noexcept {
    constexpr Real lower =
        -static_cast<Real>(std::numeric_limits<Int>::digits == 31 ? 0x1p31 : 0x1p63);
    if (!(v >= lower && v < -lower)) {
        return std::numeric_limits<Int>::min();
    }
    return static_cast<Int>(v);
}

// gcc's real -> uint64 sequence: below 2^63 (or unordered) a signed conversion; otherwise
// subtract 2^63, convert signed, and flip bit 63.
template <typename Real>
std::uint64_t to_uint64(Real v) noexcept {
    constexpr Real two_63 = static_cast<Real>(0x1p63);
    if (!(v >= two_63)) {
        return static_cast<std::uint64_t>(truncate_indefinite<std::int64_t>(v));
    }
    return static_cast<std::uint64_t>(truncate_indefinite<std::int64_t>(v - two_63)) ^
           (std::uint64_t{1} << 63U);
}

} // namespace

std::int32_t f2i(float x) noexcept {
    return truncate_indefinite<std::int32_t>(std::nearbyint(x));
}

std::int64_t f2l(float x) noexcept {
    return truncate_indefinite<std::int64_t>(std::nearbyint(x));
}

std::uint64_t f2ul(float x) noexcept {
    return to_uint64(std::nearbyint(x));
}

std::int32_t d2i(double x) noexcept {
    return truncate_indefinite<std::int32_t>(std::nearbyint(x));
}

std::int64_t d2l(double x) noexcept {
    return truncate_indefinite<std::int64_t>(std::nearbyint(x));
}

std::uint64_t d2ul(double x) noexcept {
    return to_uint64(std::nearbyint(x));
}

// libfb fb_FIXSingle / fb_FIXDouble compute truncf(fabsf(x)) * (float)fb_SGNSingle(x). Written
// out case by case, because at -O3 gcc folds the multiplication by -1 into a negation, which
// for NaN keeps the sign and does not quiet a signalling NaN (QUIRKS.md B-001). The libfb
// result for NaN is |x| quieted: trunc quiets it and clears the sign, and the multiplication
// returns that NaN operand unchanged.
float fix(float x) noexcept {
    if (std::isnan(x)) {
        return std::bit_cast<float>((std::bit_cast<std::uint32_t>(x) & 0x7FFFFFFFU) | 0x00400000U);
    }
    float const t = std::trunc(std::fabs(x));
    if (x == 0.0F) {
        return 0.0F;
    }
    return x > 0.0F ? t : -t;
}

double fix(double x) noexcept {
    if (std::isnan(x)) {
        return std::bit_cast<double>((std::bit_cast<std::uint64_t>(x) & 0x7FFFFFFFFFFFFFFFULL) |
                                     0x0008000000000000ULL);
    }
    double const t = std::trunc(std::fabs(x));
    if (x == 0.0) {
        return 0.0;
    }
    return x > 0.0 ? t : -t;
}

// libfb fb_SGNSingle / fb_SGNDouble: 0 when x == 0, else (x > 0 ? 1 : -1); NaN gives -1.
std::int32_t sgn(float x) noexcept {
    if (x == 0.0F) {
        return 0;
    }
    return x > 0.0F ? 1 : -1;
}

std::int32_t sgn(double x) noexcept {
    if (x == 0.0) {
        return 0;
    }
    return x > 0.0 ? 1 : -1;
}

std::int32_t sgn(std::int64_t x) noexcept {
    if (x == 0) {
        return 0;
    }
    return x > 0 ? 1 : -1;
}

// Two's complement wrapping (-fwrapv): unsigned arithmetic, converted back modulo 2^N.
std::int64_t add(std::int64_t a, std::int64_t b) noexcept {
    return static_cast<std::int64_t>(static_cast<std::uint64_t>(a) + static_cast<std::uint64_t>(b));
}

std::int64_t sub(std::int64_t a, std::int64_t b) noexcept {
    return static_cast<std::int64_t>(static_cast<std::uint64_t>(a) - static_cast<std::uint64_t>(b));
}

std::int64_t mul(std::int64_t a, std::int64_t b) noexcept {
    return static_cast<std::int64_t>(static_cast<std::uint64_t>(a) * static_cast<std::uint64_t>(b));
}

std::int64_t neg(std::int64_t a) noexcept {
    return static_cast<std::int64_t>(std::uint64_t{0} - static_cast<std::uint64_t>(a));
}

std::int64_t abs(std::int64_t a) noexcept {
    return a < 0 ? neg(a) : a;
}

std::int32_t add(std::int32_t a, std::int32_t b) noexcept {
    return static_cast<std::int32_t>(static_cast<std::uint32_t>(a) + static_cast<std::uint32_t>(b));
}

std::int32_t sub(std::int32_t a, std::int32_t b) noexcept {
    return static_cast<std::int32_t>(static_cast<std::uint32_t>(a) - static_cast<std::uint32_t>(b));
}

std::int32_t mul(std::int32_t a, std::int32_t b) noexcept {
    return static_cast<std::int32_t>(static_cast<std::uint32_t>(a) * static_cast<std::uint32_t>(b));
}

namespace {

void check_division(std::int64_t a, std::int64_t b) {
    if (b == 0) {
        throw std::domain_error("integer division by zero (SIGFPE in the compiled BASIC)");
    }
    if (a == std::numeric_limits<std::int64_t>::min() && b == -1) {
        throw std::domain_error("integer division overflow (SIGFPE in the compiled BASIC)");
    }
}

} // namespace

std::int64_t idiv(std::int64_t a, std::int64_t b) {
    check_division(a, b);
    return a / b;
}

std::int64_t imod(std::int64_t a, std::int64_t b) {
    check_division(a, b);
    return a % b;
}

} // namespace gef::fb
