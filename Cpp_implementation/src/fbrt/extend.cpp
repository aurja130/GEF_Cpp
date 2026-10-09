// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "fbrt/extend.hpp"

#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"

namespace gef::fb {

namespace {

// Isafe_low = Min(Iold_low, Inew_low): both Integers go through Single, the result back
// through fb_F2L (utilities.bi:273, GEF.c MIN((float)…, (float)…)).
std::int64_t safe_low(std::int64_t old_low, std::int64_t new_low) noexcept {
    return f2l(min(static_cast<float>(old_low), static_cast<float>(new_low)));
}

std::int64_t safe_high(std::int64_t old_high, std::int64_t new_high) noexcept {
    return f2l(max(static_cast<float>(old_high), static_cast<float>(new_high)));
}

} // namespace

// utilities.bi:269-286
void extend_1dim(Array<double, 1>& array, std::int64_t inew_low, std::int64_t inew_high) {
    std::int64_t const iold_low = array.lbound(1);
    std::int64_t const iold_high = array.ubound(1);
    std::int64_t const isafe_low = safe_low(iold_low, inew_low);
    std::int64_t const isafe_high = safe_high(iold_high, inew_high);
    Array<double, 1> work({{{iold_low, iold_high}}});
    for (std::int64_t i = iold_low; i <= iold_high; ++i) {
        work(i) = array(i);
    }
    array.redim({{{isafe_low, isafe_high}}});
    for (std::int64_t i = isafe_low; i <= isafe_high; ++i) {
        array(i) = 0x0p+0;
    }
    for (std::int64_t i = iold_low; i <= iold_high; ++i) {
        array(i) = work(i);
    }
}

// utilities.bi:291-322
void extend_2dim(Array<double, 2>& array, std::int64_t inew_low, std::int64_t inew_high,
                 std::int64_t jnew_low, std::int64_t jnew_high) {
    std::int64_t const iold_low = array.lbound(1);
    std::int64_t const iold_high = array.ubound(1);
    std::int64_t const jold_low = array.lbound(2);
    std::int64_t const jold_high = array.ubound(2);
    std::int64_t const isafe_low = safe_low(iold_low, inew_low);
    std::int64_t const isafe_high = safe_high(iold_high, inew_high);
    std::int64_t const jsafe_low = safe_low(jold_low, jnew_low);
    std::int64_t const jsafe_high = safe_high(jold_high, jnew_high);
    Array<double, 2> work({{{iold_low, iold_high}, {jold_low, jold_high}}});
    for (std::int64_t i = iold_low; i <= iold_high; ++i) {
        for (std::int64_t j = jold_low; j <= jold_high; ++j) {
            work(i, j) = array(i, j);
        }
    }
    array.redim({{{isafe_low, isafe_high}, {jsafe_low, jsafe_high}}});
    for (std::int64_t i = isafe_low; i <= isafe_high; ++i) {
        for (std::int64_t j = jsafe_low; j <= jsafe_high; ++j) {
            array(i, j) = 0x0p+0;
        }
    }
    for (std::int64_t i = iold_low; i <= iold_high; ++i) {
        for (std::int64_t j = jold_low; j <= jold_high; ++j) {
            array(i, j) = work(i, j);
        }
    }
}

// utilities.bi:327-372
void extend_3dim(Array<double, 3>& array, std::int64_t inew_low, std::int64_t inew_high,
                 std::int64_t jnew_low, std::int64_t jnew_high, std::int64_t knew_low,
                 std::int64_t knew_high) {
    std::int64_t const iold_low = array.lbound(1);
    std::int64_t const iold_high = array.ubound(1);
    std::int64_t const jold_low = array.lbound(2);
    std::int64_t const jold_high = array.ubound(2);
    std::int64_t const kold_low = array.lbound(3);
    std::int64_t const kold_high = array.ubound(3);
    std::int64_t const isafe_low = safe_low(iold_low, inew_low);
    std::int64_t const isafe_high = safe_high(iold_high, inew_high);
    std::int64_t const jsafe_low = safe_low(jold_low, jnew_low);
    std::int64_t const jsafe_high = safe_high(jold_high, jnew_high);
    std::int64_t const ksafe_low = safe_low(kold_low, knew_low);
    std::int64_t const ksafe_high = safe_high(kold_high, knew_high);
    Array<double, 3> work({{{iold_low, iold_high}, {jold_low, jold_high}, {kold_low, kold_high}}});
    for (std::int64_t i = iold_low; i <= iold_high; ++i) {
        for (std::int64_t j = jold_low; j <= jold_high; ++j) {
            for (std::int64_t k = kold_low; k <= kold_high; ++k) {
                work(i, j, k) = array(i, j, k);
            }
        }
    }
    array.redim({{{isafe_low, isafe_high}, {jsafe_low, jsafe_high}, {ksafe_low, ksafe_high}}});
    for (std::int64_t i = isafe_low; i <= isafe_high; ++i) {
        for (std::int64_t j = jsafe_low; j <= jsafe_high; ++j) {
            for (std::int64_t k = ksafe_low; k <= ksafe_high; ++k) {
                array(i, j, k) = 0x0p+0;
            }
        }
    }
    for (std::int64_t i = iold_low; i <= iold_high; ++i) {
        for (std::int64_t j = jold_low; j <= jold_high; ++j) {
            for (std::int64_t k = kold_low; k <= kold_high; ++k) {
                array(i, j, k) = work(i, j, k);
            }
        }
    }
}

} // namespace gef::fb
