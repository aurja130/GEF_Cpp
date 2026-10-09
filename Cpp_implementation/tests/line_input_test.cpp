// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for fb::InputFile::line_input() and eof() (fbrt/input.hpp) against the FreeBASIC driver
// golden m4-line-input: each in_<case>.bin is read with `Line Input #f, s` / EOF(f) by fbc 1.10.1,
// and lines_<case>.txt holds the result (index, length, hex). The formats are defined by
// harness/drivers/line_input.bas.

#include "fbrt/input.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <cstddef>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace {

using gef::fb::InputFile;
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

std::string read_bytes(std::filesystem::path const& path) {
    std::ifstream in(path, std::ios::binary);
    REQUIRE(in.good());
    return {std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>()};
}

// The cases of the golden: each name stands for in_<name>.bin and lines_<name>.txt.
constexpr std::array<std::string_view, 22> cases{
    "empty",    "lf",         "crlf",   "lone_cr",  "cr_eof", "no_final_lf", "blank", "nul_mid",
    "nul_only", "cr_nul_eof", "nul511", "cr511",    "lf510",  "crlf510",     "lf511", "crlf511",
    "lf512",    "crlf512",    "lf1022", "crlf1022", "lf1023", "crlf1023",
};

} // namespace

TEST_CASE("Line Input and EOF reproduce fbc 1.10.1 on the m4-line-input cases", "[fbrt]") {
    for (auto const name : cases) {
        INFO("case " << name);
        std::string const bytes =
            read_bytes(golden_file(golden, "in_" + std::string(name) + ".bin"));

        std::vector<std::string> expected;
        for (auto const& line :
             read_lines(golden_file(golden, "lines_" + std::string(name) + ".txt"))) {
            std::istringstream in(line);
            std::string index;
            std::string length;
            std::string hex;
            in >> index >> length >> hex;
            REQUIRE(!hex.empty());
            std::string const text = bytes_of(hex);
            REQUIRE(std::to_string(text.size()) == length);
            expected.push_back(text);
        }

        InputFile file(bytes);
        std::vector<std::string> actual;
        while (!file.eof()) {
            actual.push_back(file.line_input());
            REQUIRE(actual.size() <= expected.size() + 1);
        }
        CHECK(actual == expected);
    }
}
