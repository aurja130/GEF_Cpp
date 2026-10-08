// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Run-time evidence for Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md: each expression of
// harness/drivers/arith_rules.bas is written here the way the rules say fbc compiles it, and
// must reproduce the driver's result bits in every preset, including -O3.

#include "fbrt/rng.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <sstream>
#include <string>
#include <vector>

namespace {

constexpr std::size_t expression_count = 18;

struct Row {
    float s, t, u;
    double d, e;
    std::int64_t i;
    std::array<std::uint64_t, expression_count> results;
};

std::uint64_t b32(float x) {
    return std::bit_cast<std::uint32_t>(x);
}

std::uint64_t b64(double x) {
    return std::bit_cast<std::uint64_t>(x);
}

// The C that fbc 1.10.1 generates for each expression (rule numbers of FBC_ARITHMETIC.md).
std::array<std::uint64_t, expression_count> evaluate(float s, float t, float u, double d, double e,
                                                     std::int64_t i) {
    auto const ds = static_cast<double>(s);
    auto const dt = static_cast<double>(t);
    auto const du = static_cast<double>(u);
    return {
        // E1 s * 0.1 * t (R4: literal moved last, operands keep their Double conversion)
        b32(static_cast<float>((ds * dt) * 0.1)),
        // E2 0.1 * s * t * u
        b32(static_cast<float>(((ds * dt) * du) * 0.1)),
        // E3 s + 0.1 + t
        b32(static_cast<float>((ds + dt) + 0.1)),
        // E4 s * 0.1 * t * 0.2 * u (R4: literals folded in Double, 0.1 * 0.2)
        b32(static_cast<float>(((ds * dt) * du) * 0x1.47AE147AE147Cp-6)),
        // E5 s * (t * u) (R5: parentheses of a * chain are dropped)
        b32((s * t) * u),
        // E6 s - (t - u) (R5)
        b32((s - t) + u),
        // E7 s * t * (u * 0.1): s * t stays Single (R2), then the chain is flattened
        b32(static_cast<float>((static_cast<double>(s * t) * du) * 0.1)),
        // E8 s / 0.5 * t: a literal does not move across /
        b32(static_cast<float>((ds / 0.5) * dt)),
        // E9 s * t / 2 * u: an integer literal divisor is Double, so the quotient is Double
        b32(static_cast<float>((static_cast<double>(s * t) / 2.0) * du)),
        // E10 s / t * u: Single / Single is a Single quotient (R3)
        b32(static_cast<float>(ds / dt) * u),
        // E11 s * t + u * 0.5
        b32(static_cast<float>(static_cast<double>(s * t) + (du * 0.5))),
        // E12 s ^ 2 (R6: a variable squared is a product in its own type)
        b32(s * s),
        // E13 s ^ 3 (R6: other powers are pow in Double)
        b32(static_cast<float>(std::pow(ds, 3.0))),
        // E14 d * 0.1 * e
        b64((d * e) * 0.1),
        // E15 d + 0.1 + e + 0.2 (literals folded: 0.1 + 0.2 in Double)
        b64((d + e) + 0x1.3333333333334p-2),
        // E16 i * s * 0.1 (R1: Integer to Single next to a Single)
        b32(static_cast<float>(static_cast<double>(static_cast<float>(i) * s) * 0.1)),
        // E17 Exp(-u * 0.5) (R7: a Double argument selects the Double function)
        b32(static_cast<float>(std::exp(static_cast<double>(-u) * 0.5))),
        // E18 s - 0.1 - t (R4: a subtracted literal becomes an added negative literal)
        b32(static_cast<float>((ds + -0.1) - dt)),
    };
}

std::vector<Row> read_rows() {
    std::vector<Row> rows;
    for (std::string const& line :
         gef::test::read_lines(gef::test::golden_file("m3-arith-rules", "arith_rules.txt"))) {
        std::istringstream in(line);
        std::string s;
        std::string t;
        std::string u;
        std::string d;
        std::string e;
        Row row{};
        in >> s >> t >> u >> d >> e >> row.i;
        row.s = std::bit_cast<float>(static_cast<std::uint32_t>(gef::test::parse_hex(s)));
        row.t = std::bit_cast<float>(static_cast<std::uint32_t>(gef::test::parse_hex(t)));
        row.u = std::bit_cast<float>(static_cast<std::uint32_t>(gef::test::parse_hex(u)));
        row.d = std::bit_cast<double>(gef::test::parse_hex(d));
        row.e = std::bit_cast<double>(gef::test::parse_hex(e));
        for (std::uint64_t& result : row.results) {
            std::string field;
            in >> field;
            result = gef::test::parse_hex(field);
        }
        REQUIRE_FALSE(in.fail());
        rows.push_back(row);
    }
    return rows;
}

} // namespace

TEST_CASE("fbrt: the driver's inputs are reproduced from FbMtRng", "[T1][fbrt]") {
    // arith_rules.bas draws its inputs after Randomize 1, 3; the generated C is
    // s = (float)((rnd * 1000.0) + -500.0), u = (float)(rnd + -0.5),
    // i = fb_D2L(floor(rnd * 2000.0) + -1000.0).
    std::vector<Row> const rows = read_rows();
    REQUIRE(rows.size() == 2000U);
    gef::fb::FbMtRng rng(1.0);
    for (Row const& row : rows) {
        CHECK(row.s == static_cast<float>((rng.rnd() * 1000.0) + -500.0));
        CHECK(row.t == static_cast<float>((rng.rnd() * 1000.0) + -500.0));
        CHECK(row.u == static_cast<float>(rng.rnd() + -0.5));
        CHECK(row.d == (rng.rnd() * 1000.0) + -500.0);
        CHECK(row.e == rng.rnd() + -0.5);
        CHECK(row.i ==
              static_cast<std::int64_t>(std::nearbyint(std::floor(rng.rnd() * 2000.0) + -1000.0)));
    }
}

TEST_CASE("fbrt: fbc arithmetic rules reproduce the driver bit for bit", "[T1][fbrt]") {
    std::vector<Row> const rows = read_rows();
    REQUIRE(rows.size() == 2000U);
    std::array<std::size_t, expression_count> mismatches{};
    for (Row const& row : rows) {
        std::array<std::uint64_t, expression_count> const got =
            evaluate(row.s, row.t, row.u, row.d, row.e, row.i);
        for (std::size_t k = 0; k < expression_count; ++k) {
            mismatches.at(k) += got.at(k) != row.results.at(k) ? 1U : 0U;
        }
    }
    for (std::size_t k = 0; k < expression_count; ++k) {
        INFO("expression E" << k + 1);
        CHECK(mismatches.at(k) == 0U);
    }
}
