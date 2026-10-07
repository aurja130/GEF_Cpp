// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "fbrt/fp_environment.hpp"

#include <algorithm>
#include <cfenv>
#include <cfloat>
#include <cmath>
#include <format>
#include <limits>

// Every probe below reads its operands through `volatile` locals. The compiler must then
// perform the arithmetic at run time with the flags this file was compiled with, instead of
// constant-folding it with its own (exact) arithmetic.

namespace gef::fb {

namespace {

#ifdef __FAST_MATH__
constexpr bool fast_math_defined = true;
#else
constexpr bool fast_math_defined = false;
#endif

#if defined(__FINITE_MATH_ONLY__) && __FINITE_MATH_ONLY__
constexpr bool finite_math_only_defined = true;
#else
constexpr bool finite_math_only_defined = false;
#endif

std::string_view rounding_mode_name(int mode) {
    switch (mode) {
    case FE_TONEAREST:
        return "FE_TONEAREST";
    case FE_UPWARD:
        return "FE_UPWARD";
    case FE_DOWNWARD:
        return "FE_DOWNWARD";
    case FE_TOWARDZERO:
        return "FE_TOWARDZERO";
    default:
        return "unknown";
    }
}

// C99-style hexadecimal floating-point text (0x1.8p+0), exact for every double.
std::string hexfloat(double value) {
    if (!std::isfinite(value)) {
        return std::format("{}", value);
    }
    return std::format("{}0x{:a}", std::signbit(value) ? "-" : "", std::fabs(value));
}

} // namespace

FpCheckResult check_flt_eval_method() {
    // With FLT_EVAL_METHOD == 0, (1 + 2^-24) rounds to 1 in float (a tie, to even) and the
    // probe yields 0. Evaluating in double or x87 extended precision keeps the 2^-24.
    volatile float one_f = 1.0F;
    volatile float tiny_f = 0x1p-24F;
    float const probe_f = one_f + tiny_f - one_f;
    // The same at double precision: (1 + 2^-53) rounds to 1 unless evaluated wider.
    volatile double one_d = 1.0;
    volatile double tiny_d = 0x1p-53;
    double const probe_d = one_d + tiny_d - one_d;

    bool const passed = FLT_EVAL_METHOD == 0 && probe_f == 0.0F && probe_d == 0.0;
    return FpCheckResult{
        .id = FpCheckId::FltEvalMethod,
        .name = "flt_eval_method",
        .summary = "FLT_EVAL_METHOD == 0 (float and double evaluate at their own precision)",
        .passed = passed,
        .observation =
            std::format("FLT_EVAL_METHOD = {}; float (1 + 2^-24) - 1 = {}; "
                        "double (1 + 2^-53) - 1 = {} (expected 0, 0x0p+0, 0x0p+0)",
                        FLT_EVAL_METHOD, hexfloat(static_cast<double>(probe_f)), hexfloat(probe_d)),
    };
}

FpCheckResult check_iec559() {
    constexpr bool float_iec559 = std::numeric_limits<float>::is_iec559;
    constexpr bool double_iec559 = std::numeric_limits<double>::is_iec559;
    // Fast-math (-ffinite-math-only) lets the compiler assume no NaN exists and fold
    // `x != x` to false; IEEE semantics require it to be true for a NaN.
    volatile double nan_source = std::numeric_limits<double>::quiet_NaN();
    double const nan = nan_source;
    bool const nan_unordered = nan != nan;

    bool const passed = float_iec559 && double_iec559 && nan_unordered && !fast_math_defined &&
                        !finite_math_only_defined;
    return FpCheckResult{
        .id = FpCheckId::Iec559,
        .name = "iec559",
        .summary = "float and double are IEEE 754 binary32/binary64 with IEEE semantics "
                   "(no fast-math)",
        .passed = passed,
        .observation = std::format("is_iec559 float = {}, double = {}; NaN != NaN = {}; "
                                   "__FAST_MATH__ defined = {}; __FINITE_MATH_ONLY__ = {} "
                                   "(expected true, true, true, false, false)",
                                   float_iec559, double_iec559, nan_unordered, fast_math_defined,
                                   finite_math_only_defined),
    };
}

FpCheckResult check_round_to_nearest() {
    int const mode = std::fegetround();
    // Under round-to-nearest-even: 1 + 2^-53 is a tie and rounds down to 1;
    // 1 + 1.5 * 2^-53 is above the midpoint and rounds up to 1 + 2^-52.
    volatile double one = 1.0;
    volatile double tie = 0x1p-53;
    volatile double above_tie = 0x1.8p-53;
    double const tie_sum = one + tie;
    double const above_tie_sum = one + above_tie;

    bool const passed = mode == FE_TONEAREST && tie_sum == 1.0 && above_tie_sum == 1.0 + 0x1p-52;
    return FpCheckResult{
        .id = FpCheckId::RoundToNearest,
        .name = "round_to_nearest",
        .summary = "the rounding mode at start-up is round-to-nearest-even (fegetround())",
        .passed = passed,
        .observation =
            std::format("fegetround() = {} ({}); 1 + 2^-53 = {}; 1 + 1.5*2^-53 = {} "
                        "(expected FE_TONEAREST, 0x1p+0, 0x1.0000000000001p+0)",
                        rounding_mode_name(mode), mode, hexfloat(tie_sum), hexfloat(above_tie_sum)),
    };
}

FpCheckResult check_no_fma_contraction() {
    // (1 + 2^-27)(1 - 2^-27) = 1 - 2^-54 exactly. Rounded separately the product is a tie
    // that rounds to 1, so a*b + c = 0. A fused multiply-add keeps the exact product and
    // gives -2^-54. Written as one expression so that even -ffp-contract=on could fuse it.
    volatile double a_d = 1.0 + 0x1p-27;
    volatile double b_d = 1.0 - 0x1p-27;
    volatile double c_d = -1.0;
    double const result_d = a_d * b_d + c_d;
    // Single precision: (1 + 2^-13)(1 - 2^-13) = 1 - 2^-26 rounds to 1; fused gives -2^-26.
    volatile float a_f = 1.0F + 0x1p-13F;
    volatile float b_f = 1.0F - 0x1p-13F;
    volatile float c_f = -1.0F;
    float const result_f = a_f * b_f + c_f;

    bool const passed = result_d == 0.0 && result_f == 0.0F;
    return FpCheckResult{
        .id = FpCheckId::NoFmaContraction,
        .name = "no_fma_contraction",
        .summary = "a*b + c rounds the product before the addition (no FMA contraction)",
        .passed = passed,
        .observation = std::format("double (1+2^-27)(1-2^-27) - 1 = {}; "
                                   "float (1+2^-13)(1-2^-13) - 1 = {} "
                                   "(expected 0x0p+0, 0x0p+0; fused gives -0x1p-54, -0x1p-26)",
                                   hexfloat(result_d), hexfloat(static_cast<double>(result_f))),
    };
}

FpEnvironmentReport check_fp_environment() {
    FpEnvironmentReport report{
        .checks = {check_flt_eval_method(), check_iec559(), check_round_to_nearest(),
                   check_no_fma_contraction()},
        .passed = false,
    };
    report.passed = std::ranges::all_of(report.checks, &FpCheckResult::passed);
    return report;
}

} // namespace gef::fb
