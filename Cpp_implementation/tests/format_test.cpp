// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for `Format$` (fbrt/format.hpp) against the FreeBASIC driver golden m3-format.

#include "fbrt/format.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <bit>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace {

using gef::test::parse_hex;
using gef::test::read_lines;

// Lowercase or uppercase hex digit pairs to bytes; fails the test on odd length.
std::string decode_bytes(std::string_view hex) {
    REQUIRE(hex.size() % 2 == 0);
    std::string out;
    out.reserve(hex.size() / 2);
    for (std::size_t i = 0; i < hex.size(); i += 2) {
        out.push_back(static_cast<char>(parse_hex(hex.substr(i, 2))));
    }
    return out;
}

// One golden line: "<value bits> <mask hex> <result hex>".
struct Case {
    double value;
    std::string mask;
    std::string expected;
    std::string line;
};

Case parse_line(std::string const& line) {
    const auto first = line.find(' ');
    const auto second = line.find(' ', first + 1);
    REQUIRE(first != std::string::npos);
    REQUIRE(second != std::string::npos);
    const auto bits = parse_hex(std::string_view{line}.substr(0, first));
    return Case{
        .value = std::bit_cast<double>(bits),
        .mask = decode_bytes(std::string_view{line}.substr(first + 1, second - first - 1)),
        .expected = decode_bytes(std::string_view{line}.substr(second + 1)),
        .line = line,
    };
}

} // namespace

TEST_CASE("Format$ matches the m3-format golden byte for byte", "[T1][fbrt]") {
    const auto lines = read_lines(gef::test::golden_file("m3-format", "format.txt"));
    REQUIRE(!lines.empty());

    std::vector<std::string> failures;
    std::size_t total = 0;
    for (auto const& raw : lines) {
        const Case c = parse_line(raw);
        ++total;
        const std::string actual = gef::fb::format(c.value, c.mask);
        if (actual != c.expected) {
            failures.push_back("value bits " + c.line.substr(0, c.line.find(' ')) + " mask " +
                               c.mask + ": expected " + c.expected + " actual " + actual);
        }
    }
    INFO("lines checked: " << total);
    INFO("first mismatches:");
    for (std::size_t k = 0; k < failures.size() && k < 10; ++k) {
        INFO(failures.at(k));
    }
    CHECK(failures.empty());
}
