// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for fb::DataReader (fbrt/data_reader.hpp), fb::val, fb::vallng and fb::valint, and
// fb::InputFile (fbrt/input.hpp) against the FreeBASIC driver golden m3-data-input. The formats of
// the golden files are defined by harness/drivers/data_input.bas.

#include "fbrt/data_reader.hpp"
#include "fbrt/input.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <bit>
#include <cstddef>
#include <cstdint>
#include <fstream>
#include <iterator>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace {

using gef::fb::DataReader;
using gef::fb::InputFile;
using gef::fb::val;
using gef::fb::valint;
using gef::fb::vallng;
using gef::test::golden_file;
using gef::test::parse_hex;
using gef::test::read_lines;

constexpr std::string_view golden = "m3-data-input";

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

// The flat DATA item list: the items as fbc stores them (data_items.txt).
std::vector<std::string> load_items() {
    std::vector<std::string> items;
    for (std::string const& line : read_lines(golden_file(golden, "data_items.txt"))) {
        items.push_back(bytes_of(line));
    }
    return items;
}

// Item index of each label (data_labels.txt).
struct Labels {
    std::size_t l1 = 0;
    std::size_t l2 = 0;
    std::size_t l3 = 0;
};

Labels load_labels() {
    Labels out;
    for (std::string const& line : read_lines(golden_file(golden, "data_labels.txt"))) {
        std::vector<std::string> const f = fields(line);
        REQUIRE(f.size() == 2);
        auto const index = static_cast<std::size_t>(std::stoull(f.at(1)));
        if (f.at(0) == "L1") {
            out.l1 = index;
        } else if (f.at(0) == "L2") {
            out.l2 = index;
        } else if (f.at(0) == "L3") {
            out.l3 = index;
        } else {
            FAIL("unknown label " << f.at(0));
        }
    }
    return out;
}

} // namespace

TEST_CASE("fbrt: DataReader replays the FreeBASIC DATA, READ and RESTORE of the driver",
          "[T1][fbrt]") {
    std::vector<std::string> const text = load_items();
    std::vector<std::string_view> items;
    items.reserve(text.size());
    for (std::string const& s : text) {
        items.push_back(s);
    }
    REQUIRE(items.size() == 39);

    Labels const labels = load_labels();
    CHECK(labels.l1 == 0);
    CHECK(labels.l2 == 33);
    CHECK(labels.l3 == 36);

    SECTION("the first Read of a fresh reader starts at the first item") {
        DataReader fresh(items);
        std::vector<std::string> const first = read_lines(golden_file(golden, "data_first.txt"));
        REQUIRE(first.size() == 1);
        CHECK(std::bit_cast<std::uint64_t>(fresh.read_double()) == parse_hex(first.at(0)));
    }

    DataReader reader(items);

    SECTION("every item of L1, L2, L3 reads as String in one run") {
        std::vector<std::string> const lines = read_lines(golden_file(golden, "data_items.txt"));
        REQUIRE(lines.size() == items.size());
        reader.restore(labels.l1);
        for (std::size_t i = 0; i < lines.size(); ++i) {
            INFO("item " << i);
            CHECK(reader.read_string() == bytes_of(lines.at(i)));
        }
    }

    SECTION("each item reads as Single, Double and LongInt from L1") {
        std::vector<std::string> const lines = read_lines(golden_file(golden, "data_values.txt"));
        REQUIRE(lines.size() == items.size());

        reader.restore(labels.l1);
        for (std::size_t i = 0; i < lines.size(); ++i) {
            std::vector<std::string> const f = fields(lines.at(i));
            REQUIRE(f.size() == 4);
            INFO("single of item " << i);
            CHECK(std::bit_cast<std::uint32_t>(reader.read_single()) ==
                  static_cast<std::uint32_t>(parse_hex(f.at(1))));
        }

        reader.restore(labels.l1);
        for (std::size_t i = 0; i < lines.size(); ++i) {
            std::vector<std::string> const f = fields(lines.at(i));
            INFO("double of item " << i);
            CHECK(std::bit_cast<std::uint64_t>(reader.read_double()) == parse_hex(f.at(2)));
        }

        reader.restore(labels.l1);
        for (std::size_t i = 0; i < lines.size(); ++i) {
            std::vector<std::string> const f = fields(lines.at(i));
            INFO("longint of item " << i);
            CHECK(std::bit_cast<std::uint64_t>(reader.read_longint()) == parse_hex(f.at(3)));
        }
    }

    SECTION("RESTORE to L2 crosses into L3 and reads 0 past the end") {
        std::vector<std::string> const lines = read_lines(golden_file(golden, "data_chain.txt"));
        REQUIRE(lines.size() == 14);

        reader.restore(labels.l2);
        for (std::size_t i = 0; i < 8; ++i) {
            INFO("double " << i);
            CHECK(std::bit_cast<std::uint64_t>(reader.read_double()) == parse_hex(lines.at(i)));
        }

        reader.restore(labels.l3);
        INFO("string 0 of L3");
        CHECK(reader.read_string() == bytes_of(lines.at(8)));
        INFO("string 1 of L3");
        CHECK(reader.read_string() == bytes_of(lines.at(9)));
        INFO("longint 0 of L3");
        CHECK(std::bit_cast<std::uint64_t>(reader.read_longint()) == parse_hex(lines.at(10)));
        INFO("longint 1 past the end");
        CHECK(std::bit_cast<std::uint64_t>(reader.read_longint()) == parse_hex(lines.at(11)));
        INFO("string 0 past the end");
        CHECK(reader.read_string() == bytes_of(lines.at(12)));
        INFO("string 1 past the end");
        CHECK(reader.read_string() == bytes_of(lines.at(13)));
    }
}

TEST_CASE("fbrt: val, vallng and valint replay the FreeBASIC Val, ValLng and ValInt of the driver",
          "[T1][fbrt]") {
    std::vector<std::string> const lines = read_lines(golden_file(golden, "val.txt"));
    REQUIRE(lines.size() == 34);
    for (std::size_t i = 0; i < lines.size(); ++i) {
        std::vector<std::string> const f = fields(lines.at(i));
        REQUIRE(f.size() == 4);
        std::string const s = bytes_of(f.at(0));
        INFO("line " << i << " input hex " << f.at(0));
        CHECK(std::bit_cast<std::uint64_t>(val(s)) == parse_hex(f.at(1)));
        CHECK(std::bit_cast<std::uint64_t>(vallng(s)) == parse_hex(f.at(2)));
        CHECK(std::bit_cast<std::uint32_t>(valint(s)) ==
              static_cast<std::uint32_t>(parse_hex(f.at(3))));
    }
}

TEST_CASE("fbrt: Input # replays the FreeBASIC tokens and conversions of the driver",
          "[T1][fbrt]") {
    std::string bytes;
    {
        std::ifstream in(golden_file(golden, "input.txt"), std::ios::binary);
        REQUIRE(in.good());
        bytes.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
    }
    InputFile file(bytes);

    std::vector<std::string> const ops = read_lines(golden_file(golden, "input_ops.txt"));
    std::vector<std::string> const results = read_lines(golden_file(golden, "input_results.txt"));
    REQUIRE(ops.size() >= 60);
    REQUIRE(results.size() == ops.size());

    for (std::size_t i = 0; i < ops.size(); ++i) {
        std::vector<std::string> const f = fields(results.at(i));
        REQUIRE(f.size() == 3);
        std::string const& op = ops.at(i);
        INFO("op " << i + 1 << " type " << op);
        CHECK(f.at(0) == std::to_string(i + 1));
        CHECK(f.at(1) == op);
        if (op == "S") {
            CHECK(std::bit_cast<std::uint32_t>(file.input_single()) ==
                  static_cast<std::uint32_t>(parse_hex(f.at(2))));
        } else if (op == "D") {
            CHECK(std::bit_cast<std::uint64_t>(file.input_double()) == parse_hex(f.at(2)));
        } else if (op == "L") {
            CHECK(std::bit_cast<std::uint64_t>(file.input_longint()) == parse_hex(f.at(2)));
        } else if (op == "$") {
            CHECK(file.input_string() == bytes_of(f.at(2)));
        } else {
            FAIL("unknown op " << op);
        }
    }
}
