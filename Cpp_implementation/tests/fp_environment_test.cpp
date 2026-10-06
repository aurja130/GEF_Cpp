// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aurora Jahan
// See LICENSE.txt in the repository root for the full license text.

// Tests for gef::fb fp_environment. Each test checks one exact-mode assumption twice: through
// the library check (compiled in gef_fbrt) and through an independent probe compiled in this
// translation unit. Every test also requires IEEE (non-fast-math) semantics, so each one
// fails on a fast-math build; the FMA test additionally fails on a contracting build.

#include "fbrt/fp_environment.hpp"

#include <catch2/catch_test_macros.hpp>

#include <cfenv>
#include <cfloat>
#include <cstddef>
#include <limits>
#include <set>
#include <string_view>

namespace {

#ifdef __FAST_MATH__
constexpr bool fast_math_defined = true;
#else
constexpr bool fast_math_defined = false;
#endif

// Fails on any fast-math build: the macro is set by -ffast-math, and -ffinite-math-only
// lets the compiler fold `x != x` to false for a NaN. Checked at run time (not with
// STATIC_REQUIRE) so a fast-math build still compiles and reports every failing test.
void require_ieee_semantics() {
    REQUIRE_FALSE(fast_math_defined);
    volatile double nan_source = std::numeric_limits<double>::quiet_NaN();
    double const nan = nan_source;
    REQUIRE(nan != nan);
    REQUIRE_FALSE(nan == nan);
}

} // namespace

TEST_CASE("fbrt: FLT_EVAL_METHOD is 0", "[unit][fbrt]") {
    require_ieee_semantics();
    STATIC_REQUIRE(FLT_EVAL_METHOD == 0);

    gef::fb::FpCheckResult const result = gef::fb::check_flt_eval_method();
    INFO(result.observation);
    CHECK(result.id == gef::fb::FpCheckId::FltEvalMethod);
    CHECK(result.passed);

    // Independent probe: in float, 1 + 2^-24 is a tie that rounds to 1.
    volatile float one = 1.0F;
    volatile float tiny = 0x1p-24F;
    float const probe = one + tiny - one;
    REQUIRE(probe == 0.0F);
}

TEST_CASE("fbrt: float and double are IEEE 754", "[unit][fbrt]") {
    require_ieee_semantics();
    STATIC_REQUIRE(std::numeric_limits<float>::is_iec559);
    STATIC_REQUIRE(std::numeric_limits<double>::is_iec559);
    STATIC_REQUIRE(std::numeric_limits<float>::digits == 24);
    STATIC_REQUIRE(std::numeric_limits<double>::digits == 53);

    gef::fb::FpCheckResult const result = gef::fb::check_iec559();
    INFO(result.observation);
    CHECK(result.id == gef::fb::FpCheckId::Iec559);
    CHECK(result.passed);

    // Independent probe: infinities propagate (fast-math may assume they never occur).
    volatile double huge = std::numeric_limits<double>::max();
    double const overflow = huge * 2.0;
    REQUIRE(overflow == std::numeric_limits<double>::infinity());
}

TEST_CASE("fbrt: rounding mode is round-to-nearest at start-up", "[unit][fbrt]") {
    require_ieee_semantics();
    REQUIRE(std::fegetround() == FE_TONEAREST);

    gef::fb::FpCheckResult const result = gef::fb::check_round_to_nearest();
    INFO(result.observation);
    CHECK(result.id == gef::fb::FpCheckId::RoundToNearest);
    CHECK(result.passed);

    // Independent probe: ties go to even, both upwards and downwards.
    volatile double one = 1.0;
    volatile double half_ulp = 0x1p-53;
    volatile double one_plus_ulp = 1.0 + 0x1p-52;
    double const tie_down = one + half_ulp;
    double const tie_up = one_plus_ulp + half_ulp;
    REQUIRE(tie_down == 1.0);
    REQUIRE(tie_up == 1.0 + 0x1p-51);
}

TEST_CASE("fbrt: a*b+c is not contracted to a fused multiply-add", "[unit][fbrt]") {
    require_ieee_semantics();

    gef::fb::FpCheckResult const result = gef::fb::check_no_fma_contraction();
    INFO(result.observation);
    CHECK(result.id == gef::fb::FpCheckId::NoFmaContraction);
    CHECK(result.passed);

    // Independent probe in this translation unit: (1 + 2^-27)(1 - 2^-27) = 1 - 2^-54 rounds
    // to 1 when the product is rounded, so the sum is 0; fused it would be -2^-54.
    volatile double a = 1.0 + 0x1p-27;
    volatile double b = 1.0 - 0x1p-27;
    volatile double c = -1.0;
    double const unfused = a * b + c;
    REQUIRE(unfused == 0.0);
}

TEST_CASE("fbrt: fp_environment report combines all checks", "[unit][fbrt]") {
    require_ieee_semantics();

    gef::fb::FpEnvironmentReport const report = gef::fb::check_fp_environment();
    REQUIRE(report.checks.size() == gef::fb::fp_check_count);

    std::set<std::string_view> names;
    bool all_passed = true;
    for (std::size_t i = 0; i < report.checks.size(); ++i) {
        gef::fb::FpCheckResult const& check = report.checks.at(i);
        INFO(check.name << ": " << check.observation);
        CHECK(static_cast<std::size_t>(check.id) == i);
        CHECK_FALSE(check.name.empty());
        CHECK_FALSE(check.summary.empty());
        CHECK_FALSE(check.observation.empty());
        CHECK(check.passed);
        names.insert(check.name);
        all_passed = all_passed && check.passed;
    }
    CHECK(names.size() == report.checks.size());
    REQUIRE(report.passed == all_passed);
    REQUIRE(report.passed);
}
