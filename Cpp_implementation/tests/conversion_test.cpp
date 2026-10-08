// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for gef::fb conversions (fbrt/convert.hpp) and integer arithmetic against the
// FreeBASIC driver goldens m3-conv-single, m3-conv-double and m3-int-ops.

#include "fbrt/convert.hpp"
#include "fbrt/rng.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
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

std::int32_t to_i32(std::string_view text) {
    return static_cast<std::int32_t>(static_cast<std::uint32_t>(parse_hex(text)));
}

std::int64_t to_i64(std::string_view text) {
    return static_cast<std::int64_t>(parse_hex(text));
}

std::vector<std::string> fields(std::string const& line) {
    std::istringstream in(line);
    std::vector<std::string> out;
    std::string field;
    while (in >> field) {
        out.push_back(field);
    }
    return out;
}

} // namespace

TEST_CASE("fbrt: exhaustive Single conversions match the FreeBASIC driver", "[T1][fbrt][slow]") {
    // Block b covers the float bit patterns b * 2^24 + low, low = 0 .. 2^24 - 1.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-conv-single", "conv_single.txt"));
    REQUIRE(lines.size() == 256U);
    constexpr std::array<std::string_view, 5> names{"f2i", "f2l", "f2ul", "fix", "sgn"};
    constexpr std::uint32_t low_count = 1U << 24U;

    for (std::uint32_t block = 0; block < 256U; ++block) {
        std::vector<std::string> const row = fields(lines.at(block));
        REQUIRE(row.size() == 6U);

        // Kept as separate locals so the inner loop contains no bounds-checked accesses.
        Hash h_f2i;
        Hash h_f2l;
        Hash h_f2ul;
        Hash h_fix;
        Hash h_sgn;
        std::uint32_t const base = block << 24U;
        for (std::uint32_t low = 0; low < low_count; ++low) {
            auto const x = std::bit_cast<float>(base | low);
            h_f2i.add(static_cast<std::uint32_t>(gef::fb::f2i(x)));
            h_f2l.add(static_cast<std::uint64_t>(gef::fb::f2l(x)));
            h_f2ul.add(gef::fb::f2ul(x));
            h_fix.add(std::bit_cast<std::uint32_t>(gef::fb::fix(x)));
            h_sgn.add(static_cast<std::uint32_t>(gef::fb::sgn(x)));
        }

        std::array<std::uint64_t, 5> const got{h_f2i.value, h_f2l.value, h_f2ul.value, h_fix.value,
                                               h_sgn.value};
        for (std::size_t k = 0; k < names.size(); ++k) {
            INFO("block " << row.at(0) << ", function " << names.at(k));
            CHECK(got.at(k) == parse_hex(row.at(k + 1)));
        }
    }
}

TEST_CASE("fbrt: Double grid conversions match the FreeBASIC driver", "[T1][fbrt]") {
    // Fields: input bits, d2i, d2l, d2ul, fix, sgn.
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-conv-double", "conv_double_grid.txt"))) {
        INFO(line);
        std::vector<std::string> const row = fields(line);
        REQUIRE(row.size() == 6U);
        auto const x = std::bit_cast<double>(parse_hex(row.at(0)));
        CHECK(to_i32(row.at(1)) == gef::fb::d2i(x));
        CHECK(to_i64(row.at(2)) == gef::fb::d2l(x));
        CHECK(parse_hex(row.at(3)) == gef::fb::d2ul(x));
        CHECK(parse_hex(row.at(4)) == std::bit_cast<std::uint64_t>(gef::fb::fix(x)));
        CHECK(to_i32(row.at(5)) == gef::fb::sgn(x));
    }
}

TEST_CASE("fbrt: random Double conversions match the FreeBASIC driver", "[T1][fbrt]") {
    // 2^20 inputs from FbMtRng(12345); block = index / 2^16.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-conv-double", "conv_double_random.txt"));
    REQUIRE(lines.size() == 16U);
    constexpr std::array<std::string_view, 5> names{"d2i", "d2l", "d2ul", "fix", "sgn"};
    constexpr std::uint32_t block_size = 1U << 16U;

    gef::fb::FbMtRng rng(12345.0);
    for (std::uint32_t block = 0; block < 16U; ++block) {
        std::vector<std::string> const row = fields(lines.at(block));
        REQUIRE(row.size() == 6U);

        Hash h_d2i;
        Hash h_d2l;
        Hash h_d2ul;
        Hash h_fix;
        Hash h_sgn;
        for (std::uint32_t i = 0; i < block_size; ++i) {
            std::uint32_t const hi = rng.next_u32();
            std::uint32_t const lo = rng.next_u32();
            auto const x = std::bit_cast<double>((static_cast<std::uint64_t>(hi) << 32U) | lo);
            h_d2i.add(static_cast<std::uint32_t>(gef::fb::d2i(x)));
            h_d2l.add(static_cast<std::uint64_t>(gef::fb::d2l(x)));
            h_d2ul.add(gef::fb::d2ul(x));
            h_fix.add(std::bit_cast<std::uint64_t>(gef::fb::fix(x)));
            h_sgn.add(static_cast<std::uint32_t>(gef::fb::sgn(x)));
        }

        std::array<std::uint64_t, 5> const got{h_d2i.value, h_d2l.value, h_d2ul.value, h_fix.value,
                                               h_sgn.value};
        for (std::size_t k = 0; k < names.size(); ++k) {
            INFO("block " << row.at(0) << ", function " << names.at(k));
            CHECK(got.at(k) == parse_hex(row.at(k + 1)));
        }
    }
}

TEST_CASE("fbrt: Integer unary and binary operations match the FreeBASIC driver", "[T1][fbrt]") {
    // int_unary: a, -a, Abs(a), Sgn(a).
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-int-ops", "int_unary.txt"))) {
        INFO(line);
        std::vector<std::string> const row = fields(line);
        REQUIRE(row.size() == 4U);
        std::int64_t const a = to_i64(row.at(0));
        CHECK(to_i64(row.at(1)) == gef::fb::neg(a));
        CHECK(to_i64(row.at(2)) == gef::fb::abs(a));
        CHECK(to_i32(row.at(3)) == gef::fb::sgn(a));
    }

    // int_binary: a, b, a+b, a-b, a*b, a\b, a Mod b; "-" where the division traps.
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-int-ops", "int_binary.txt"))) {
        INFO(line);
        std::vector<std::string> const row = fields(line);
        REQUIRE(row.size() == 7U);
        std::int64_t const a = to_i64(row.at(0));
        std::int64_t const b = to_i64(row.at(1));
        CHECK(to_i64(row.at(2)) == gef::fb::add(a, b));
        CHECK(to_i64(row.at(3)) == gef::fb::sub(a, b));
        CHECK(to_i64(row.at(4)) == gef::fb::mul(a, b));
        if (row.at(5) == "-") {
            CHECK_THROWS_AS(gef::fb::idiv(a, b), std::domain_error);
        } else {
            CHECK(to_i64(row.at(5)) == gef::fb::idiv(a, b));
        }
        if (row.at(6) == "-") {
            CHECK_THROWS_AS(gef::fb::imod(a, b), std::domain_error);
        } else {
            CHECK(to_i64(row.at(6)) == gef::fb::imod(a, b));
        }
    }
}

TEST_CASE("fbrt: Long binary operations match the FreeBASIC driver", "[T1][fbrt]") {
    // long_binary: a, b, a+b, a-b, a*b as int32.
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-int-ops", "long_binary.txt"))) {
        INFO(line);
        std::vector<std::string> const row = fields(line);
        REQUIRE(row.size() == 5U);
        std::int32_t const a = to_i32(row.at(0));
        std::int32_t const b = to_i32(row.at(1));
        CHECK(to_i32(row.at(2)) == gef::fb::add(a, b));
        CHECK(to_i32(row.at(3)) == gef::fb::sub(a, b));
        CHECK(to_i32(row.at(4)) == gef::fb::mul(a, b));
    }
}
