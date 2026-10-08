// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for `Str` and `Print #` formatting (fbrt/text.hpp) against the FreeBASIC driver goldens
// m3-str-single, m3-str-numbers and m3-print-file.

#include "fbrt/rng.hpp"
#include "fbrt/text.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <atomic>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <sstream>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace {

using gef::test::parse_hex;
using gef::test::read_lines;

constexpr std::uint64_t fnv_offset = 0xCBF29CE484222325ULL;
constexpr std::uint64_t fnv_prime = 0x100000001B3ULL;

// The drivers' hash over the bytes of Str texts: each byte, then one LF byte per text.
struct Hash {
    std::uint64_t value = fnv_offset;

    void add_byte(unsigned char b) noexcept {
        value = (value ^ static_cast<std::uint64_t>(b)) * fnv_prime;
    }

    void add_text(std::string_view s) noexcept {
        for (char c : s) {
            add_byte(static_cast<unsigned char>(c));
        }
        add_byte('\n');
    }
};

// A golden line "<key> <rest>": the key is everything before the first space, the rest is the
// text after it (Str results never start with a blank, so this split is exact).
struct Entry {
    std::string key;
    std::string rest;
};

Entry split_entry(std::string const& line) {
    std::size_t const sp = line.find(' ');
    REQUIRE(sp != std::string::npos);
    return {.key = line.substr(0, sp), .rest = line.substr(sp + 1)};
}

float float_from_u32(std::uint32_t bits) noexcept {
    return std::bit_cast<float>(bits);
}

// The generator of `Randomize seed, 3` after `draws` 32-bit outputs have been taken.
gef::fb::FbMtRng stream_after(double seed, std::uint64_t draws) {
    gef::fb::FbMtRng rng(seed);
    for (std::uint64_t i = 0; i < draws; ++i) {
        (void)rng.next_u32();
    }
    return rng;
}

// The bytes of a file, read in binary mode.
std::string read_bytes(std::filesystem::path const& path) {
    std::ifstream in(path, std::ios::binary);
    REQUIRE(in.is_open());
    return {std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>()};
}

// Quoted text with control characters escaped, for failure messages.
std::string show(std::string_view s) {
    std::ostringstream out;
    out << '"';
    for (char c : s) {
        auto const u = static_cast<unsigned char>(c);
        if (c == '\n') {
            out << "\\n";
        } else if (u < 0x20U || u > 0x7EU) {
            out << "\\x" << std::hex << static_cast<unsigned>(u) << std::dec;
        } else {
            out << c;
        }
    }
    out << '"';
    return out.str();
}

constexpr std::uint32_t single_block_count = 256U;
constexpr std::uint32_t single_low_count = 1U << 24U;

// Hash of Str over block b of Single bit patterns b * 2^24 + low.
std::uint64_t single_block_hash(std::uint32_t block) {
    Hash h;
    std::uint32_t const base = block << 24U;
    for (std::uint32_t low = 0; low < single_low_count; ++low) {
        h.add_text(gef::fb::str(float_from_u32(base | low)));
    }
    return h.value;
}

} // namespace

TEST_CASE("fbrt: exhaustive Single Str matches the FreeBASIC driver", "[T1][fbrt][slow]") {
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-str-single", "str_single.txt"));
    REQUIRE(lines.size() == single_block_count);

    // Blocks are independent: workers take block indices from a shared counter and each writes
    // only its own slot. No Catch2 macros run on the worker threads.
    std::vector<std::uint64_t> results(single_block_count);
    std::atomic<std::uint32_t> next_block{0};
    {
        unsigned const workers = std::max(1U, std::thread::hardware_concurrency());
        std::vector<std::jthread> threads;
        threads.reserve(workers);
        for (unsigned w = 0; w < workers; ++w) {
            threads.emplace_back([&results, &next_block]() {
                std::uint32_t block = next_block.fetch_add(1U);
                while (block < single_block_count) {
                    results.at(block) = single_block_hash(block);
                    block = next_block.fetch_add(1U);
                }
            });
        }
    } // jthreads join here

    for (std::uint32_t block = 0; block < single_block_count; ++block) {
        Entry const e = split_entry(lines.at(block));
        REQUIRE(parse_hex(e.key) == block);
        INFO("block " << e.key);
        CHECK(results.at(block) == parse_hex(e.rest));
    }
}

TEST_CASE("fbrt: Str of the Single grid matches the FreeBASIC driver", "[T1][fbrt]") {
    // Fields: bit pattern (8 hex digits), Str text.
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-str-numbers", "str_single_grid.txt"))) {
        INFO(line);
        Entry const e = split_entry(line);
        auto const x = float_from_u32(static_cast<std::uint32_t>(parse_hex(e.key)));
        CHECK(gef::fb::str(x) == e.rest);
    }
}

TEST_CASE("fbrt: Str of the Double grid matches the FreeBASIC driver", "[T1][fbrt]") {
    // Fields: bit pattern (16 hex digits), Str text.
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-str-numbers", "str_double_grid.txt"))) {
        INFO(line);
        Entry const e = split_entry(line);
        auto const x = std::bit_cast<double>(parse_hex(e.key));
        CHECK(gef::fb::str(x) == e.rest);
    }
}

TEST_CASE("fbrt: random Double Str matches the FreeBASIC driver", "[T1][fbrt]") {
    // FbMtRng(99): 2^20 bit patterns, two draws each (hi first); block = index / 2^16.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-str-numbers", "str_double_random.txt"));
    REQUIRE(lines.size() == 16U);
    constexpr std::uint32_t block_size = 1U << 16U;

    gef::fb::FbMtRng rng(99.0);
    for (std::uint32_t block = 0; block < 16U; ++block) {
        Entry const e = split_entry(lines.at(block));
        Hash h;
        for (std::uint32_t i = 0; i < block_size; ++i) {
            std::uint32_t const hi = rng.next_u32();
            std::uint32_t const lo = rng.next_u32();
            auto const x = std::bit_cast<double>((static_cast<std::uint64_t>(hi) << 32U) | lo);
            h.add_text(gef::fb::str(x));
        }
        INFO("block " << e.key);
        CHECK(h.value == parse_hex(e.rest));
    }
}

TEST_CASE("fbrt: moderate Double Str matches the FreeBASIC driver", "[T1][fbrt]") {
    // Continues the FbMtRng(99) stream of the random test: 2^20 values (Rnd - 0.5) * 2000.
    // fbc compiles that expression as Rnd * 2000 + -1000 (see the driver's generated C), so the
    // same operations are used here.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-str-numbers", "str_double_moderate.txt"));
    REQUIRE(lines.size() == 16U);
    constexpr std::uint32_t block_size = 1U << 16U;

    gef::fb::FbMtRng rng = stream_after(99.0, 1ULL << 21U);
    for (std::uint32_t block = 0; block < 16U; ++block) {
        Entry const e = split_entry(lines.at(block));
        Hash h;
        for (std::uint32_t i = 0; i < block_size; ++i) {
            double const x = rng.rnd() * 2000.0 + -1000.0;
            h.add_text(gef::fb::str(x));
        }
        INFO("block " << e.key);
        CHECK(h.value == parse_hex(e.rest));
    }
}

TEST_CASE("fbrt: LongInt Str matches the FreeBASIC driver", "[T1][fbrt]") {
    // Lines 1..10: a fixed grid; then 4096 values from the FbMtRng(99) stream after the random
    // and moderate tests (hi drawn first). Fields: bit pattern (16 hex digits), Str text.
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-str-numbers", "str_longint.txt"));
    constexpr std::size_t grid_count = 10;
    constexpr std::size_t random_count = 4096;
    REQUIRE(lines.size() == grid_count + random_count);

    for (std::size_t k = 0; k < grid_count; ++k) {
        Entry const e = split_entry(lines.at(k));
        INFO(lines.at(k));
        CHECK(gef::fb::str(std::bit_cast<std::int64_t>(parse_hex(e.key))) == e.rest);
    }

    gef::fb::FbMtRng rng = stream_after(99.0, (1ULL << 21U) + (1ULL << 20U));
    for (std::size_t k = grid_count; k < lines.size(); ++k) {
        Entry const e = split_entry(lines.at(k));
        std::uint32_t const hi = rng.next_u32();
        std::uint32_t const lo = rng.next_u32();
        auto const bits = (static_cast<std::uint64_t>(hi) << 32U) | lo;
        INFO(lines.at(k));
        CHECK(parse_hex(e.key) == bits);
        CHECK(gef::fb::str(std::bit_cast<std::int64_t>(bits)) == e.rest);
    }
}

TEST_CASE("fbrt: Print # file matches the FreeBASIC driver", "[T1][fbrt]") {
    // The statement sequence of the print_file driver, one call per item, with the mask of each
    // item (0 `;`, 1 end of statement, 2 `,`) as PrintEnd::None, Newline and Pad.
    std::string const expected =
        read_bytes(gef::test::golden_file("m3-print-file", "print_file.txt"));
    using gef::fb::PrintEnd;

    float const s1 = 1.5F;
    float const s2 = -2.25F;
    float const s3 = 0.0F;
    float const s4 = 3.4028235e38F;
    float const s5 = 1e-8F;
    double const d1 = 0.1;
    double const d2 = -1e300;
    double const d3 = 2.5;
    std::int64_t const i1 = 42;
    std::int64_t const i2 = -7;
    std::int64_t const i3 = 0;
    std::string const t1 = "abc";
    std::string const t2;
    std::string const t3 = "exactly14chars";
    std::string const t4 = std::string("line1") + '\n' + "xy";

    gef::fb::PrintFile pf;
    pf.print(std::string_view(t1), PrintEnd::Newline);
    pf.print(std::string_view(t1), PrintEnd::None);
    pf.print(std::string_view(t2), PrintEnd::None);
    pf.print(std::string_view(t1), PrintEnd::Newline);
    pf.print(s1, PrintEnd::None);
    pf.print(s2, PrintEnd::None);
    pf.print(s3, PrintEnd::None);
    pf.print(s4, PrintEnd::None);
    pf.print(s5, PrintEnd::Newline);
    pf.print(d1, PrintEnd::None);
    pf.print(d2, PrintEnd::None);
    pf.print(d3, PrintEnd::Newline);
    pf.print(i1, PrintEnd::None);
    pf.print(i2, PrintEnd::None);
    pf.print(i3, PrintEnd::Newline);
    pf.print(s1, PrintEnd::Pad);
    pf.print(s2, PrintEnd::Pad);
    pf.print(d1, PrintEnd::Pad);
    pf.print(i1, PrintEnd::Pad);
    pf.print(std::string_view(t1), PrintEnd::Newline);
    pf.print(std::string_view(t3), PrintEnd::Pad);
    pf.print(std::string_view(t1), PrintEnd::Newline);
    pf.print(std::string_view(t3), PrintEnd::None);
    pf.print(std::string_view(t3), PrintEnd::Pad);
    pf.print(std::string_view(t1), PrintEnd::Newline);
    pf.print(std::string_view(t1), PrintEnd::Pad);
    pf.print(i2, PrintEnd::Newline);
    pf.print(std::string_view(t1), PrintEnd::None);
    pf.print(s1, PrintEnd::Pad);
    pf.print_void(PrintEnd::Newline);
    pf.tab(10);
    pf.print(std::string_view(t1), PrintEnd::None);
    pf.tab(5);
    pf.print(std::string_view(t1), PrintEnd::None);
    pf.tab(20);
    pf.print(i1, PrintEnd::Newline);
    pf.print(std::string_view(t4), PrintEnd::None);
    pf.tab(5);
    pf.print(std::string_view("z"), PrintEnd::Pad);
    pf.print(std::string_view(t1), PrintEnd::Newline);
    pf.tab(60);
    pf.print(d3, PrintEnd::Newline);
    pf.print(std::string_view(""), PrintEnd::Newline);
    pf.print(std::string_view(t2), PrintEnd::Newline);
    pf.print(s1, PrintEnd::None);
    pf.tab(3);
    pf.print(s2, PrintEnd::Newline);

    std::string const& actual = pf.text();
    if (actual != expected) {
        auto const at =
            static_cast<std::size_t>(std::ranges::mismatch(actual, expected).in1 - actual.begin());
        FAIL("print_file.txt differs at byte " << at << "\n  expected: " << show(expected)
                                               << "\n  actual:   " << show(actual));
    }
}
