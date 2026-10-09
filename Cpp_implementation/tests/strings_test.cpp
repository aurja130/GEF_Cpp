// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for the FreeBASIC string runtime (fbrt/strings.hpp): fb_TRIM, fb_StrUcase2, fb_StrInstr
// and fb_StrMid, against the FreeBASIC driver golden m4-line-input (strings.txt). The formats
// of the golden lines are defined by harness/drivers/line_input.bas.

#include "fbrt/strings.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <cstddef>
#include <cstdint>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace {

using gef::fb::instr;
using gef::fb::mid;
using gef::fb::trim;
using gef::fb::ucase;
using gef::test::golden_file;
using gef::test::parse_hex;
using gef::test::read_lines;

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

} // namespace

TEST_CASE("TRIM, UCASE, InStr and Mid reproduce fbc 1.10.1 output", "[fbrt]") {
    auto const lines = read_lines(golden_file(golden, "strings.txt"));
    REQUIRE(!lines.empty());
    for (auto const& line : lines) {
        INFO(line);
        auto const f = fields(line);
        REQUIRE(!f.empty());
        std::string const& kind = f.at(0);
        if (kind == "TRIM") {
            REQUIRE(f.size() == 3);
            CHECK(hex_of(trim(bytes_of(f.at(1)))) == f.at(2));
        } else if (kind == "UCASE") {
            REQUIRE(f.size() == 3);
            CHECK(hex_of(ucase(bytes_of(f.at(1)))) == f.at(2));
        } else if (kind == "INSTR") {
            REQUIRE(f.size() == 4);
            CHECK(instr(bytes_of(f.at(1)), bytes_of(f.at(2))) == std::stoll(f.at(3)));
        } else if (kind == "INSTRS") {
            REQUIRE(f.size() == 5);
            CHECK(instr(std::stoll(f.at(1)), bytes_of(f.at(2)), bytes_of(f.at(3))) ==
                  std::stoll(f.at(4)));
        } else if (kind == "MID2") {
            REQUIRE(f.size() == 4);
            CHECK(hex_of(mid(bytes_of(f.at(1)), std::stoll(f.at(2)))) == f.at(3));
        } else if (kind == "MID3") {
            REQUIRE(f.size() == 5);
            CHECK(hex_of(mid(bytes_of(f.at(1)), std::stoll(f.at(2)), std::stoll(f.at(3)))) ==
                  f.at(4));
        } else {
            FAIL("unknown golden line kind: " << kind);
        }
    }
}
