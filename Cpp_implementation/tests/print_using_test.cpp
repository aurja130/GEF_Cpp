// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for `Print Using` (fbrt/text.hpp) against the FreeBASIC driver golden m3-print-using:
// every template of GEF's Print Using statements and the runtime's generic cases, each with a
// grid of Single, Double, LongInt and String items.

#include "fbrt/text.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <bit>
#include <cstddef>
#include <cstdint>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace {

using gef::test::golden_file;
using gef::test::parse_hex;
using gef::test::read_lines;

// Decodes a hex string of bytes ("" gives an empty string).
std::string decode_bytes(std::string_view hex) {
    REQUIRE(hex.size() % 2 == 0);
    std::string out;
    for (std::size_t i = 0; i < hex.size(); i += 2) {
        out.push_back(static_cast<char>(parse_hex(hex.substr(i, 2))));
    }
    return out;
}

// One item of a statement, as calls.txt writes it.
struct Item {
    char kind = 'f';
    std::uint64_t bits = 0;
    std::string text;
};

// One line of calls.txt: template index, item count, then the items.
struct Call {
    std::size_t tid = 0;
    std::vector<Item> items;
};

Call parse_call(std::string const& line) {
    std::istringstream in(line);
    Call call;
    std::size_t count = 0;
    in >> call.tid >> count;
    for (std::size_t k = 0; k < count; ++k) {
        std::string token;
        in >> token;
        REQUIRE(token.size() >= 2);
        REQUIRE(token.at(1) == ':');
        Item item;
        item.kind = token.at(0);
        std::string_view const value = std::string_view(token).substr(2);
        if (item.kind == 's') {
            item.text = decode_bytes(value);
        } else {
            item.bits = parse_hex(value);
        }
        call.items.push_back(item);
    }
    return call;
}

} // namespace

TEST_CASE("Print Using reproduces every statement of the driver golden", "[T1][fbrt]") {
    auto const templates = read_lines(golden_file("m3-print-using", "templates.txt"));
    auto const calls = read_lines(golden_file("m3-print-using", "calls.txt"));
    auto const outputs = read_lines(golden_file("m3-print-using", "print_using.txt"));
    REQUIRE(calls.size() == outputs.size());

    for (std::size_t n = 0; n < calls.size(); ++n) {
        INFO("statement " << n);
        Call const call = parse_call(calls.at(n));
        std::string const format = decode_bytes(templates.at(call.tid));

        gef::fb::PrintFile file;
        file.using_init(format);
        for (std::size_t k = 0; k < call.items.size(); ++k) {
            Item const& item = call.items.at(k);
            bool const last = k + 1 == call.items.size();
            auto const end = last ? gef::fb::PrintEnd::Newline : gef::fb::PrintEnd::None;
            switch (item.kind) {
            case 'f':
                file.using_print(std::bit_cast<float>(static_cast<std::uint32_t>(item.bits)), end,
                                 last);
                break;
            case 'd':
                file.using_print(std::bit_cast<double>(item.bits), end, last);
                break;
            case 'l':
                file.using_print(std::bit_cast<std::int64_t>(item.bits), end, last);
                break;
            case 's':
                file.using_print(std::string_view(item.text), end, last);
                break;
            default:
                FAIL("unknown item kind in calls.txt");
            }
        }
        file.using_end();

        // The driver's Print # ends each statement with a newline.
        CHECK(file.text() == outputs.at(n) + "\n");
    }
}
