// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <charconv>
#include <fstream>
#include <memory>
#include <system_error>

namespace gef::test {

namespace {

// Set by Cpp_implementation/tests/CMakeLists.txt.
constexpr std::string_view golden_root = GEF_TEST_GOLDEN_DIR;
constexpr std::string_view store_captures_root = GEF_TEST_STORE_CAPTURES_DIR;

} // namespace

std::filesystem::path golden_file(std::string_view name, std::string_view file) {
    std::filesystem::path path = std::filesystem::path(golden_root) / name / file;
    INFO("golden file " << path.string());
    REQUIRE(std::filesystem::is_regular_file(path));
    return path;
}

std::optional<std::filesystem::path> store_file(std::string_view id, std::string_view file) {
    std::filesystem::path path = std::filesystem::path(store_captures_root) / id / file;
    if (!std::filesystem::is_regular_file(path)) {
        return std::nullopt;
    }
    return path;
}

std::vector<std::string> read_lines(std::filesystem::path const& path) {
    std::ifstream in(path, std::ios::binary);
    INFO("reading " << path.string());
    REQUIRE(in.is_open());
    std::vector<std::string> lines;
    std::string line;
    while (std::getline(in, line)) {
        if (!line.empty() && line.back() == '\r') {
            line.pop_back();
        }
        lines.push_back(std::move(line));
        line.clear();
    }
    return lines;
}

std::uint64_t parse_hex(std::string_view text) {
    std::uint64_t value = 0;
    char const* const last = std::to_address(text.end());
    auto const [end, error] = std::from_chars(std::to_address(text.begin()), last, value, 16);
    if (error != std::errc{} || end != last || text.empty()) {
        FAIL("not a hex field: '" << text << "'");
    }
    return value;
}

} // namespace gef::test
