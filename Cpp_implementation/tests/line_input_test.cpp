// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for fb::InputFile::line_input(), eof() and data_at_end() (fbrt/input.hpp) against the
// FreeBASIC driver golden m4-line-input: each in_<case>.bin is read with `Line Input #f, s` and
// EOF(f) by fbc 1.10.1, and lines_<case>.txt holds the result (index, length, hex). The formats
// are defined by harness/drivers/line_input.bas. The m6-strings golden hang.txt adds
// `Input #f, D` before the steps (harness/drivers/m6_strings.bas).

#include "fbrt/input.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <optional>
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

// The m6-strings golden hang.txt: per case, `Input #f, D` (one Double), then six steps of
// `If EOF(f) = 0 Then Line Input #f, s`, the shape of GEF's `Do Until EOF` loops, cut to six
// steps; each INPUT and LINE record gives EOF(f) before the step. The driver's at-end column
// (`Seek(f) > LOF(f)`) counts the putback buffer as unread, so it always equals EOF(f) and is
// not data_at_end(). What the parser relies on (run/input_files.cpp, GEF.bas:2843): once
// data_at_end() holds while eof() does not, every Line Input returns "", and a case whose EOF
// stays 0 to the last step has reached that state.
TEST_CASE("Input #, EOF and Line Input reproduce fbc 1.10.1 on the m6-strings hang", "[fbrt]") {
    auto const lines = read_lines(golden_file("m6-strings", "hang.txt"));
    REQUIRE(!lines.empty());
    std::optional<InputFile> file;
    int last_eof = 1;
    auto finish_case = [&] {
        if (file.has_value() && last_eof == 0) {
            CHECK(file->data_at_end());
            CHECK(!file->eof());
        }
    };
    for (auto const& line : lines) {
        INFO(line);
        std::istringstream in(line);
        std::string kind;
        std::string name;
        in >> kind >> name;
        if (kind == "INPUT") {
            finish_case();
            std::string bits;
            int eof_flag = 0;
            int at_end_flag = 0;
            in >> bits >> eof_flag >> at_end_flag;
            file.emplace(read_bytes(golden_file("m6-strings", "in_" + name + ".bin")));
            CHECK(std::bit_cast<std::uint64_t>(file->input_double()) == parse_hex(bits));
            CHECK(file->eof() == (eof_flag == 1));
            last_eof = eof_flag;
        } else if (kind == "LINE") {
            if (!file.has_value()) {
                FAIL("a LINE record before any INPUT record");
                break;
            }
            InputFile& open = *file;
            std::string index;
            std::string hex;
            int eof_flag = 0;
            int at_end_flag = 0;
            in >> index >> eof_flag >> at_end_flag >> hex;
            CHECK(open.eof() == (eof_flag == 1));
            if (eof_flag == 0) {
                bool const stuck = open.data_at_end();
                CHECK(open.line_input() == bytes_of(hex));
                if (stuck) {
                    CHECK(hex == "-");
                    CHECK(open.data_at_end());
                }
            }
            last_eof = eof_flag;
        } else {
            FAIL("unknown golden line kind: " << kind);
        }
    }
    finish_case();
}
