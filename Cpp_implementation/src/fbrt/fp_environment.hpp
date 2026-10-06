// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aurora Jahan
// See LICENSE.txt in the repository root for the full license text.

// Runtime self-check of the floating-point assumptions exact mode depends on
// (Planning/MILESTONE_0_PLAN.md §2, M0.4). The checks evaluate their probes in this
// library's translation unit, which is compiled with the gef_exact_fp flags; a build with
// different floating-point flags fails the corresponding check.

#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>

namespace gef::fb {

enum class FpCheckId : std::uint8_t {
    FltEvalMethod,    // FLT_EVAL_METHOD == 0: float/double evaluate at their own precision
    Iec559,           // float and double are IEEE 754 binary32/binary64 with NaN semantics
    RoundToNearest,   // the rounding mode at start-up is round-to-nearest-even
    NoFmaContraction, // a*b+c is computed as two rounded operations, never one fused one
};

inline constexpr std::size_t fp_check_count = 4;

struct FpCheckResult {
    FpCheckId id{};
    std::string_view name;    // short stable identifier, e.g. "no_fma_contraction"
    std::string_view summary; // the assumption, in words
    bool passed{false};
    std::string observation; // what was measured, including the observed values
};

struct FpEnvironmentReport {
    std::array<FpCheckResult, fp_check_count> checks;
    bool passed{false}; // true exactly when every check passed
};

[[nodiscard]] FpCheckResult check_flt_eval_method();
[[nodiscard]] FpCheckResult check_iec559();
[[nodiscard]] FpCheckResult check_round_to_nearest();
[[nodiscard]] FpCheckResult check_no_fma_contraction();

// Runs all checks in FpCheckId order and combines them into one verdict.
[[nodiscard]] FpEnvironmentReport check_fp_environment();

} // namespace gef::fb
