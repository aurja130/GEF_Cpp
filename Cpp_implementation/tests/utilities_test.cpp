// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Tests for GEF's string utilities (util/utilities.hpp): ConvTab, CC_Count and CC_Cut, against the
// FreeBASIC driver golden m4-line-input (utilities.txt and the "<E> Dimension of COut too small"
// lines in stdout.txt). The formats are defined by harness/drivers/line_input.bas.

#include "fbrt/array.hpp"
#include "support/golden.hpp"
#include "util/utilities.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <cstddef>
#include <cstdint>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace {

using gef::fb::Array;
using gef::fb::Bounds;
using gef::test::golden_file;
using gef::test::parse_hex;
using gef::test::read_lines;
using gef::util::cc_count;
using gef::util::cc_cut;
using gef::util::conv_tab;

constexpr std::string_view golden = "m4-line-input";

// The bytes a golden hex string stands for; "-" is the empty string.
std::string bytes_of(std::string_view hex) {
    if (hex == "-") {
        return {};
    }
    REQUIRE(hex.size() % 2 == 0);
    std::string out;
    for (std::size_t i = 0; i < hex.size(); i += 2) {
        out.push_back(static_cast<char>(parse_hex(hex.substr(i, 2))));
    }
    return out;
}

// The golden hex string of some bytes; "-" for the empty string.
std::string hex_of(std::string_view s) {
    if (s.empty()) {
        return "-";
    }
    constexpr std::string_view digits = "0123456789abcdef";
    std::string out;
    for (char const ch : s) {
        auto const b = static_cast<unsigned char>(ch);
        out.push_back(digits.at(b >> 4));
        out.push_back(digits.at(b & 0xF));
    }
    return out;
}

// The whitespace-separated fields of a golden line.
std::vector<std::string> fields(std::string const& line) {
    std::istringstream in(line);
    std::vector<std::string> out;
    std::string f;
    while (in >> f) {
        out.push_back(f);
    }
    return out;
}

// Checks one CUT or CUTS golden line against cc_cut with a COut of the given upper bound.
void check_cut(std::string const& line, std::int64_t ubound, std::vector<std::string>& console) {
    auto const f = fields(line);
    REQUIRE(f.size() >= 4);
    std::string const cin = bytes_of(f.at(1));
    std::string const div = bytes_of(f.at(2));
    auto const expected_n = std::stoll(f.at(3));
    REQUIRE(static_cast<std::int64_t>(f.size()) == 4 + expected_n);

    Array<std::string, 1> out(std::array<Bounds, 1>{Bounds{0, ubound}});
    std::int64_t n = 0;
    cc_cut(cin, div, out, n, console);
    CHECK(n == expected_n);
    for (std::int64_t k = 1; k <= n; ++k) {
        CHECK(hex_of(out(k)) == f.at(static_cast<std::size_t>(3 + k)));
    }
}

} // namespace

TEST_CASE("ConvTab, CC_Count and CC_Cut reproduce fbc 1.10.1 output", "[util]") {
    auto const lines = read_lines(golden_file(golden, "utilities.txt"));
    REQUIRE(!lines.empty());
    std::vector<std::string> console;
    for (auto const& line : lines) {
        INFO(line);
        auto const f = fields(line);
        REQUIRE(!f.empty());
        std::string const& kind = f.at(0);
        if (kind == "CONVTAB") {
            REQUIRE(f.size() == 3);
            CHECK(hex_of(conv_tab(bytes_of(f.at(1)))) == f.at(2));
        } else if (kind == "COUNT") {
            REQUIRE(f.size() == 4);
            CHECK(cc_count(bytes_of(f.at(1)), bytes_of(f.at(2))) == std::stoll(f.at(3)));
        } else if (kind == "CUT") {
            check_cut(line, 9, console);
        } else if (kind == "CUTS") {
            check_cut(line, 2, console);
        } else {
            FAIL("unknown golden line kind: " << kind);
        }
    }

    // The overflow messages are the stdout of the driver, in the order the calls were made.
    auto const stdout_lines = read_lines(golden_file(golden, "stdout.txt"));
    CHECK(console == stdout_lines);
}
