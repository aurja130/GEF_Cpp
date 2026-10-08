// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for the libm intrinsics as called from C++ and GEF's maths helpers (fbrt/gef_math.hpp)
// against the FreeBASIC driver goldens m3-math-single, m3-math-double and m3-gef-math2.

#include "fbrt/gef_math.hpp"
#include "fbrt/rng.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <array>
#include <atomic>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <sstream>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

namespace {

using gef::test::parse_hex;
using gef::test::read_lines;

constexpr std::uint64_t fnv_offset = 0xCBF29CE484222325ULL;
constexpr std::uint64_t fnv_prime = 0x100000001B3ULL;

// The drivers' hash over raw result bits: h = (h ^ v) * prime, uint64 wrap.
struct Hash {
    std::uint64_t value = fnv_offset;

    void add(std::uint64_t v) noexcept { value = (value ^ v) * fnv_prime; }
};

std::vector<std::string> fields(std::string const& line) {
    std::istringstream in(line);
    std::vector<std::string> out;
    std::string field;
    while (in >> field) {
        out.push_back(field);
    }
    return out;
}

// NaN results compare equal regardless of sign and payload (user decision 2026-10-08, QUIRKS.md
// B-001). Hashed bits of a Single result: every NaN maps to the canonical NaN 0x7FC00000.
std::uint64_t float_bits(float x) noexcept {
    return std::isnan(x) ? 0x7FC00000ULL : std::bit_cast<std::uint32_t>(x);
}

float float_from_u32(std::uint32_t bits) noexcept {
    return std::bit_cast<float>(bits);
}

float float_from_hex(std::string_view text) {
    return float_from_u32(static_cast<std::uint32_t>(parse_hex(text)));
}

// Hashed bits of a Double result: every NaN maps to the canonical NaN 0x7FF8000000000000.
std::uint64_t double_bits(double x) noexcept {
    return std::isnan(x) ? 0x7FF8000000000000ULL : std::bit_cast<std::uint64_t>(x);
}

// Golden raw bits `expected` against a computed result; any two NaNs compare equal.
bool same_f32(std::uint64_t expected, float actual) noexcept {
    if (std::isnan(actual)) {
        return std::isnan(float_from_u32(static_cast<std::uint32_t>(expected)));
    }
    return expected == std::bit_cast<std::uint32_t>(actual);
}

bool same_f64(std::uint64_t expected, double actual) noexcept {
    if (std::isnan(actual)) {
        return std::isnan(std::bit_cast<double>(expected));
    }
    return expected == std::bit_cast<std::uint64_t>(actual);
}

// The six Double results of the Double driver at x, in its order: Exp, Log, Sqr, Int, Abs, Cos.
std::array<double, 6> double_results(double x) {
    return {std::exp(x), std::log(x), std::sqrt(x), std::floor(x), std::fabs(x), std::cos(x)};
}

// The generator of `Randomize seed, 3` after `draws` 32-bit outputs have been taken. Each Rnd
// draw and each next_u32 consumes one output, so the drivers' streams are reached this way.
gef::fb::FbMtRng stream_after(double seed, std::uint64_t draws) {
    gef::fb::FbMtRng rng(seed);
    for (std::uint64_t i = 0; i < draws; ++i) {
        (void)rng.next_u32();
    }
    return rng;
}

constexpr std::uint32_t single_block_count = 256U;
constexpr std::uint32_t single_low_count = 1U << 24U;

// Hashes of the 14 Single functions over block b of bit patterns, in the driver's order.
std::array<std::uint64_t, 14> single_block_hashes(std::uint32_t block) {
    Hash h_exp;
    Hash h_log;
    Hash h_sqrt;
    Hash h_floor;
    Hash h_fabs;
    Hash h_sin;
    Hash h_acos;
    Hash h_erf;
    Hash h_erfc;
    Hash h_tanh;
    Hash h_coth;
    Hash h_log10;
    Hash h_gef_floor;
    Hash h_ceil;
    std::uint32_t const base = block << 24U;
    for (std::uint32_t low = 0; low < single_low_count; ++low) {
        auto const x = std::bit_cast<float>(base | low);
        h_exp.add(float_bits(std::exp(x)));
        h_log.add(float_bits(std::log(x)));
        h_sqrt.add(float_bits(std::sqrt(x)));
        h_floor.add(float_bits(std::floor(x)));
        h_fabs.add(float_bits(std::fabs(x)));
        h_sin.add(float_bits(std::sin(x)));
        h_acos.add(float_bits(std::acos(x)));
        h_erf.add(float_bits(gef::fb::erf(x)));
        h_erfc.add(float_bits(gef::fb::erfc(x)));
        h_tanh.add(float_bits(gef::fb::tanh(x)));
        h_coth.add(float_bits(gef::fb::coth(x)));
        h_log10.add(float_bits(gef::fb::log10(x)));
        h_gef_floor.add(float_bits(gef::fb::floor(x)));
        h_ceil.add(float_bits(gef::fb::ceil(x)));
    }
    return {h_exp.value,  h_log.value,   h_sqrt.value,      h_floor.value, h_fabs.value,
            h_sin.value,  h_acos.value,  h_erf.value,       h_erfc.value,  h_tanh.value,
            h_coth.value, h_log10.value, h_gef_floor.value, h_ceil.value};
}

} // namespace

TEST_CASE("fbrt: exhaustive Single maths match the FreeBASIC driver", "[T1][fbrt][slow]") {
    // Block b covers the float bit patterns b * 2^24 + low, low = 0 .. 2^24 - 1.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-math-single", "math_single.txt"));
    REQUIRE(lines.size() == single_block_count);
    constexpr std::array<std::string_view, 14> names{"exp",  "log",   "sqrt",      "floor", "fabs",
                                                     "sin",  "acos",  "erf",       "erfc",  "tanh",
                                                     "coth", "log10", "gef floor", "ceil"};

    // Blocks are independent: workers take block indices from a shared counter and each writes
    // only its own slot. No Catch2 macros run on the worker threads.
    std::vector<std::array<std::uint64_t, 14>> results(single_block_count);
    std::atomic<std::uint32_t> next_block{0};
    {
        unsigned const workers = std::max(1U, std::thread::hardware_concurrency());
        std::vector<std::jthread> threads;
        threads.reserve(workers);
        for (unsigned w = 0; w < workers; ++w) {
            threads.emplace_back([&results, &next_block]() {
                std::uint32_t block = next_block.fetch_add(1U);
                while (block < single_block_count) {
                    results.at(block) = single_block_hashes(block);
                    block = next_block.fetch_add(1U);
                }
            });
        }
    } // jthreads join here

    for (std::uint32_t block = 0; block < single_block_count; ++block) {
        std::vector<std::string> const row = fields(lines.at(block));
        REQUIRE(row.size() == 15U);
        REQUIRE(parse_hex(row.at(0)) == block);
        for (std::size_t k = 0; k < names.size(); ++k) {
            INFO("block " << row.at(0) << ", function " << names.at(k));
            CHECK(results.at(block).at(k) == parse_hex(row.at(k + 1)));
        }
    }
}

TEST_CASE("fbrt: Double grid maths match the FreeBASIC driver", "[T1][fbrt]") {
    // Fields: input bits, exp, log, sqrt, floor, fabs, cos.
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-math-double", "math_double_grid.txt"))) {
        INFO(line);
        std::vector<std::string> const row = fields(line);
        REQUIRE(row.size() == 7U);
        auto const x = std::bit_cast<double>(parse_hex(row.at(0)));
        std::array<double, 6> const got = double_results(x);
        for (std::size_t k = 0; k < got.size(); ++k) {
            CHECK(same_f64(parse_hex(row.at(k + 1)), got.at(k)));
        }
    }
}

TEST_CASE("fbrt: random Double maths match the FreeBASIC driver", "[T1][fbrt]") {
    // 2^20 inputs from FbMtRng(777), two draws each (hi first); block = index / 2^16.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-math-double", "math_double_random.txt"));
    REQUIRE(lines.size() == 16U);
    constexpr std::array<std::string_view, 6> names{"exp", "log", "sqrt", "floor", "fabs", "cos"};
    constexpr std::uint32_t block_size = 1U << 16U;

    gef::fb::FbMtRng rng(777.0);
    for (std::uint32_t block = 0; block < 16U; ++block) {
        std::vector<std::string> const row = fields(lines.at(block));
        REQUIRE(row.size() == 7U);

        std::array<Hash, 6> hashes{};
        for (std::uint32_t i = 0; i < block_size; ++i) {
            std::uint32_t const hi = rng.next_u32();
            std::uint32_t const lo = rng.next_u32();
            auto const x = std::bit_cast<double>((static_cast<std::uint64_t>(hi) << 32U) | lo);
            std::array<double, 6> const r = double_results(x);
            for (std::size_t k = 0; k < hashes.size(); ++k) {
                hashes.at(k).add(double_bits(r.at(k)));
            }
        }

        for (std::size_t k = 0; k < names.size(); ++k) {
            INFO("block " << row.at(0) << ", function " << names.at(k));
            CHECK(hashes.at(k).value == parse_hex(row.at(k + 1)));
        }
    }
}

TEST_CASE("fbrt: moderate Double maths match the FreeBASIC driver", "[T1][fbrt]") {
    // Continues the FbMtRng(777) stream of the random test: 2^20 values x = (Rnd - 0.5) * 1500.
    // The driver's `Rnd - 0.5` is `Rnd + -0.5` bit for bit; the form below is what fbc emits.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-math-double", "math_double_moderate.txt"));
    REQUIRE(lines.size() == 16U);
    constexpr std::array<std::string_view, 6> names{"exp", "log", "sqrt", "floor", "fabs", "cos"};
    constexpr std::uint32_t block_size = 1U << 16U;

    gef::fb::FbMtRng rng = stream_after(777.0, 1ULL << 21U);
    for (std::uint32_t block = 0; block < 16U; ++block) {
        std::vector<std::string> const row = fields(lines.at(block));
        REQUIRE(row.size() == 7U);

        std::array<Hash, 6> hashes{};
        for (std::uint32_t i = 0; i < block_size; ++i) {
            double const x = (rng.rnd() + -0.5) * 1500.0;
            std::array<double, 6> const r = double_results(x);
            for (std::size_t k = 0; k < hashes.size(); ++k) {
                hashes.at(k).add(double_bits(r.at(k)));
            }
        }

        for (std::size_t k = 0; k < names.size(); ++k) {
            INFO("block " << row.at(0) << ", function " << names.at(k));
            CHECK(hashes.at(k).value == parse_hex(row.at(k + 1)));
        }
    }
}

TEST_CASE("fbrt: Double pow grid matches the FreeBASIC driver", "[T1][fbrt]") {
    // Fields: base bits, exponent bits, base ^ exponent bits.
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-math-double", "pow_grid.txt"))) {
        INFO(line);
        std::vector<std::string> const row = fields(line);
        REQUIRE(row.size() == 3U);
        auto const base = std::bit_cast<double>(parse_hex(row.at(0)));
        auto const exponent = std::bit_cast<double>(parse_hex(row.at(1)));
        CHECK(same_f64(parse_hex(row.at(2)), std::pow(base, exponent)));
    }
}

TEST_CASE("fbrt: random Double pow matches the FreeBASIC driver", "[T1][fbrt]") {
    // Continues the FbMtRng(777) stream after the random and moderate tests (3 * 2^20 draws):
    // 2^20 pairs b = Rnd * 20 (drawn first), e = (Rnd - 0.5) * 40; hash of b ^ e.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-math-double", "pow_random.txt"));
    REQUIRE(lines.size() == 16U);
    constexpr std::uint32_t block_size = 1U << 16U;

    gef::fb::FbMtRng rng = stream_after(777.0, (1ULL << 21U) + (1ULL << 20U));
    for (std::uint32_t block = 0; block < 16U; ++block) {
        std::vector<std::string> const row = fields(lines.at(block));
        REQUIRE(row.size() == 2U);

        Hash hash;
        for (std::uint32_t i = 0; i < block_size; ++i) {
            double const b = rng.rnd() * 20.0;
            double const e = (rng.rnd() + -0.5) * 40.0;
            hash.add(double_bits(std::pow(b, e)));
        }

        INFO("block " << row.at(0));
        CHECK(hash.value == parse_hex(row.at(1)));
    }
}

TEST_CASE("fbrt: Min and Max grid match the FreeBASIC driver", "[T1][fbrt]") {
    // Fields: a bits, b bits, Min(a, b) bits, Max(a, b) bits; all ordered pairs of the grid.
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-gef-math2", "minmax_grid.txt"))) {
        INFO(line);
        std::vector<std::string> const row = fields(line);
        REQUIRE(row.size() == 4U);
        float const a = float_from_hex(row.at(0));
        float const b = float_from_hex(row.at(1));
        CHECK(same_f32(parse_hex(row.at(2)), gef::fb::min(a, b)));
        CHECK(same_f32(parse_hex(row.at(3)), gef::fb::max(a, b)));
    }
}

TEST_CASE("fbrt: random Min and Max match the FreeBASIC driver", "[T1][fbrt]") {
    // FbMtRng(4242); 2^20 pairs a, b of random Single bit patterns (a drawn first); block = index
    // / 2^16.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-gef-math2", "minmax_random.txt"));
    REQUIRE(lines.size() == 16U);
    constexpr std::uint32_t block_size = 1U << 16U;

    gef::fb::FbMtRng rng(4242.0);
    for (std::uint32_t block = 0; block < 16U; ++block) {
        std::vector<std::string> const row = fields(lines.at(block));
        REQUIRE(row.size() == 3U);

        Hash h_min;
        Hash h_max;
        for (std::uint32_t i = 0; i < block_size; ++i) {
            float const a = float_from_u32(rng.next_u32());
            float const b = float_from_u32(rng.next_u32());
            h_min.add(float_bits(gef::fb::min(a, b)));
            h_max.add(float_bits(gef::fb::max(a, b)));
        }

        INFO("block " << row.at(0));
        CHECK(h_min.value == parse_hex(row.at(1)));
        CHECK(h_max.value == parse_hex(row.at(2)));
    }
}

TEST_CASE("fbrt: Round grid matches the FreeBASIC driver", "[T1][fbrt]") {
    // Fields: N (decimal), R bits, Round(R, N) bits.
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-gef-math2", "round_grid.txt"))) {
        INFO(line);
        std::vector<std::string> const row = fields(line);
        REQUIRE(row.size() == 3U);
        auto const n = static_cast<std::int64_t>(std::stoll(row.at(0)));
        float const r = float_from_hex(row.at(1));
        CHECK(same_f32(parse_hex(row.at(2)), gef::fb::round(r, n)));
    }
}

TEST_CASE("fbrt: random Round matches the FreeBASIC driver", "[T1][fbrt]") {
    // Continues the FbMtRng(4242) stream after the Min/Max test (2^21 draws): 2^20 random Single
    // bit patterns R, each rounded with N in {1, 2, 3, 4, 5, 7}; one hash per N; block = index /
    // 2^16.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-gef-math2", "round_random.txt"));
    REQUIRE(lines.size() == 16U);
    constexpr std::array<std::int64_t, 6> digits{1, 2, 3, 4, 5, 7};
    constexpr std::uint32_t block_size = 1U << 16U;

    gef::fb::FbMtRng rng = stream_after(4242.0, 1ULL << 21U);
    for (std::uint32_t block = 0; block < 16U; ++block) {
        std::vector<std::string> const row = fields(lines.at(block));
        REQUIRE(row.size() == 7U);

        std::array<Hash, 6> hashes{};
        for (std::uint32_t i = 0; i < block_size; ++i) {
            float const r = float_from_u32(rng.next_u32());
            for (std::size_t k = 0; k < hashes.size(); ++k) {
                hashes.at(k).add(float_bits(gef::fb::round(r, digits.at(k))));
            }
        }

        INFO("block " << row.at(0));
        for (std::size_t k = 0; k < hashes.size(); ++k) {
            CHECK(hashes.at(k).value == parse_hex(row.at(k + 1)));
        }
    }
}

TEST_CASE("fbrt: Modulo matches the FreeBASIC driver", "[T1][fbrt]") {
    // Fields: i bits, j bits, Modulo(i, j) bits; i and j are read from the file.
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-gef-math2", "modulo.txt"))) {
        INFO(line);
        std::vector<std::string> const row = fields(line);
        REQUIRE(row.size() == 3U);
        std::uint64_t const i = parse_hex(row.at(0));
        std::uint64_t const j = parse_hex(row.at(1));
        auto const want = static_cast<std::int64_t>(parse_hex(row.at(2)));
        CHECK(want == gef::fb::modulo(i, j));
    }
}
