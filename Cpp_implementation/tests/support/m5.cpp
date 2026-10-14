// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "support/m5.hpp"

#include "support/golden.hpp"
#include "support/probe_dump.hpp"

#include <catch2/catch_message.hpp>
#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <array>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <optional>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace gef::test::m5 {

namespace {

std::string hex(std::uint64_t v, int digits) {
    std::string out(static_cast<std::size_t>(digits), '0');
    for (int i = digits - 1; i >= 0; --i) {
        out.at(static_cast<std::size_t>(i)) = std::string_view("0123456789abcdef").at(v & 0xFU);
        v >>= 4U;
    }
    return out;
}

std::uint64_t bits_of(std::string_view token, std::size_t digits) {
    if (token.size() != digits) {
        FAIL("token '" << token << "' does not have " << digits << " hex digits");
    }
    return parse_hex(token);
}

// The schema of a header "# <kind> 1 <fn> <field>:<type> ...": the type of every field.
std::vector<std::string> field_types(std::string_view header) {
    std::vector<std::string> types;
    auto const parts = split(header);
    for (std::size_t i = 4; i < parts.size(); ++i) {
        auto const colon = parts.at(i).rfind(':');
        types.push_back(colon == std::string::npos ? std::string() : parts.at(i).substr(colon + 1));
    }
    return types;
}

bool is_nan_token(std::string_view type, std::string_view token) {
    if (type == "f32" && token.size() == 8) {
        return std::isnan(parse_f32(token));
    }
    if (type == "f64" && token.size() == 16) {
        return std::isnan(parse_f64(token));
    }
    return false;
}

// ULP distance of two finite tokens of the same floating type (sign-magnitude ordering).
std::uint64_t ulp_distance(std::string_view type, std::string_view a, std::string_view b) {
    auto const ordered = [](std::uint64_t bits, std::uint64_t sign) -> std::int64_t {
        auto const magnitude = static_cast<std::int64_t>(bits & (sign - 1));
        return (bits & sign) != 0 ? -magnitude : magnitude;
    };
    std::uint64_t const sign = type == "f32" ? 0x80000000ULL : 0x8000000000000000ULL;
    std::size_t const digits = type == "f32" ? 8 : 16;
    std::int64_t const x = ordered(bits_of(a, digits), sign);
    std::int64_t const y = ordered(bits_of(b, digits), sign);
    return x > y ? static_cast<std::uint64_t>(x - y) : static_cast<std::uint64_t>(y - x);
}

// Equal token lists, NaN tokens of a floating type equal regardless of sign and payload.
bool same_tokens(std::vector<std::string> const& types, std::vector<std::string> const& a,
                 std::vector<std::string> const& b, bool& nan_only) {
    if (a.size() != b.size()) {
        nan_only = false;
        return false;
    }
    bool same = true;
    for (std::size_t i = 0; i < a.size(); ++i) {
        if (a.at(i) == b.at(i)) {
            continue;
        }
        std::string const& type = i < types.size() ? types.at(i) : std::string();
        if (is_nan_token(type, a.at(i)) && is_nan_token(type, b.at(i))) {
            continue;
        }
        same = false;
        nan_only = false;
    }
    return same;
}

std::string describe(std::vector<std::string> const& names, std::vector<std::string> const& types,
                     std::vector<std::string> const& expected,
                     std::vector<std::string> const& got) {
    std::ostringstream out;
    for (std::size_t i = 0; i < std::max(expected.size(), got.size()); ++i) {
        std::string const e = i < expected.size() ? expected.at(i) : "<none>";
        std::string const g = i < got.size() ? got.at(i) : "<none>";
        std::string const& type = i < types.size() ? types.at(i) : std::string();
        out << "\n  " << (i < names.size() ? names.at(i) : "?") << ": BASIC " << e << ", C++ " << g;
        if (e != g && (type == "f32" || type == "f64") && !is_nan_token(type, e) &&
            !is_nan_token(type, g) && e.size() == g.size()) {
            out << " (" << ulp_distance(type, e, g) << " ULP)";
        } else if (e != g) {
            out << " (differs)";
        }
    }
    return out.str();
}

std::vector<std::string> field_names(std::string_view header) {
    std::vector<std::string> names;
    auto const parts = split(header);
    for (std::size_t i = 4; i < parts.size(); ++i) {
        names.push_back(parts.at(i).substr(0, parts.at(i).rfind(':')));
    }
    return names;
}

constexpr std::array<std::string_view, 4> captures = {"m5-arglog-rn215", "m5-arglog-cf252",
                                                      "m5-arglog-u235", "m5-arglog-sh264"};

} // namespace

std::string f32(float x) {
    return hex(std::bit_cast<std::uint32_t>(x), 8);
}
std::string f64(double x) {
    return hex(std::bit_cast<std::uint64_t>(x), 16);
}
std::string i64(std::int64_t x) {
    return hex(static_cast<std::uint64_t>(x), 16);
}
std::string u8(std::uint8_t x) {
    return hex(x, 2);
}

std::string str(std::string_view s) {
    if (s.empty()) {
        return "-";
    }
    std::string out;
    for (char const c : s) {
        out += hex(static_cast<unsigned char>(c), 2);
    }
    return out;
}

std::string f32_list(std::span<float const> v) {
    std::string out = std::to_string(v.size());
    char sep = ':';
    for (float const x : v) {
        out += sep;
        out += f32(x);
        sep = ',';
    }
    return out;
}

std::string f32_hash(std::span<float const> v) {
    std::uint64_t h = 0xCBF29CE484222325ULL;
    for (float const x : v) {
        h = (h ^ std::bit_cast<std::uint32_t>(x)) * 0x100000001B3ULL;
    }
    return hex(h, 16);
}

float parse_f32(std::string_view token) {
    return std::bit_cast<float>(static_cast<std::uint32_t>(bits_of(token, 8)));
}
double parse_f64(std::string_view token) {
    return std::bit_cast<double>(bits_of(token, 16));
}
std::int64_t parse_i64(std::string_view token) {
    return static_cast<std::int64_t>(bits_of(token, 16));
}
std::uint8_t parse_u8(std::string_view token) {
    return static_cast<std::uint8_t>(bits_of(token, 2));
}

std::string parse_str(std::string_view token) {
    if (token == "-") {
        return {};
    }
    std::string out;
    for (std::size_t i = 0; i < token.size(); i += 2) {
        out += static_cast<char>(bits_of(token.substr(i, 2), 2));
    }
    return out;
}

std::string join(std::initializer_list<std::string> tokens) {
    std::string out;
    for (std::string const& t : tokens) {
        if (!out.empty()) {
            out += ' ';
        }
        out += t;
    }
    return out;
}

std::vector<std::string> split(std::string_view line) {
    std::vector<std::string> out;
    std::size_t start = 0;
    while (true) {
        std::size_t const space = line.find(' ', start);
        out.emplace_back(line.substr(start, space - start));
        if (space == std::string_view::npos) {
            return out;
        }
        start = space + 1;
    }
}

float axis(double lo, double step, std::int64_t i) noexcept {
    return static_cast<float>(lo + (static_cast<double>(i) * step));
}

float draw(fb::FbMtRng& rng, double lo, double hi) noexcept {
    return static_cast<float>(lo + ((hi - lo) * rng.rnd()));
}

GridFile::GridFile(std::string file_name, std::string_view fn, std::string_view schema)
    : file(std::move(file_name)),
      header("# m5grid 1 " + std::string(fn) + " " + std::string(schema)) {}

void check_grid(std::string_view golden, GridFile const& grid) {
    std::vector<std::string> all;
    all.reserve(grid.lines.size() + 1);
    all.push_back(grid.header);
    all.insert(all.end(), grid.lines.begin(), grid.lines.end());
    INFO("golden " << golden << ", file " << grid.file);

    bool nan_only = true;
    bool compared = false;
    // Development override: GEF_TEST_M5_DIR=<dir> compares with <dir>/<golden>/<file> (a local
    // driver run) instead of the store, and skips the committed fingerprint.
    std::optional<std::filesystem::path> path;
    char const* const local =
        std::getenv("GEF_TEST_M5_DIR"); // NOLINT(concurrency-mt-unsafe): read-only
    if (local != nullptr) {
        path = std::filesystem::path(local) / golden / grid.file;
        REQUIRE(std::filesystem::is_regular_file(*path));
    } else {
        path = store_file(golden, grid.file);
    }
    if (path) {
        compared = true;
        auto const expected = read_lines(*path);
        REQUIRE(!expected.empty());
        REQUIRE(expected.front() == grid.header);
        auto const types = field_types(grid.header);
        auto const names = field_names(grid.header);
        if (expected.size() != all.size()) {
            FAIL("BASIC wrote " << expected.size() << " lines, C++ " << all.size());
        }
        for (std::size_t i = 1; i < all.size(); ++i) {
            auto const e = split(expected.at(i));
            auto const g = split(all.at(i));
            if (!same_tokens(types, e, g, nan_only)) {
                FAIL("first difference at line " << i + 1 << describe(names, types, e, g));
            }
        }
    }
    if (local != nullptr) {
        return;
    }
    auto const committed = read_fingerprints(golden, "files.txt");
    auto const it = committed.find(grid.file);
    REQUIRE(it != committed.end());
    auto const actual = fingerprint_lines(all);
    if (compared && actual != it->second) {
        // The store comparison passed: only NaN payloads or signs differ (B-001).
        REQUIRE(nan_only);
        WARN(grid.file << ": fingerprint differs only in NaN tokens (B-001)");
        return;
    }
    CHECK(actual.lines == it->second.lines);
    CHECK(actual == it->second);
}

void check_text(std::string_view golden, std::string_view file,
                std::vector<std::string> const& lines) {
    INFO("golden " << golden << ", file " << file);
    char const* const local =
        std::getenv("GEF_TEST_M5_DIR"); // NOLINT(concurrency-mt-unsafe): read-only
    std::optional<std::filesystem::path> const path =
        local != nullptr ? std::optional(std::filesystem::path(local) / golden / file)
                         : store_file(golden, file);
    if (path) {
        auto const expected = read_lines(*path);
        for (std::size_t i = 0; i < std::min(expected.size(), lines.size()); ++i) {
            if (expected.at(i) != lines.at(i)) {
                FAIL("first difference at line " << i + 1 << ": BASIC '" << expected.at(i)
                                                 << "', C++ '" << lines.at(i) << "'");
            }
        }
        REQUIRE(expected.size() == lines.size());
    }
    if (local != nullptr) {
        return;
    }
    auto const committed = read_fingerprints(golden, "files.txt");
    auto const it = committed.find(file);
    REQUIRE(it != committed.end());
    CHECK(fingerprint_lines(lines) == it->second);
}

std::vector<std::string> text_lines(std::string const& text) {
    std::vector<std::string> out;
    std::size_t start = 0;
    while (start < text.size()) {
        std::size_t const lf = text.find('\n', start);
        if (lf == std::string::npos) {
            out.push_back(text.substr(start));
            break;
        }
        out.push_back(text.substr(start, lf - start));
        start = lf + 1;
    }
    return out;
}

std::optional<std::vector<ArglogRecord>> read_arglog(std::string_view capture, std::string_view fn,
                                                     std::string_view schema) {
    auto const path = store_file(capture, "work/probes/arglog/" + std::string(fn) + ".txt");
    if (!path) {
        return std::nullopt;
    }
    auto const lines = read_lines(*path);
    REQUIRE(!lines.empty());
    REQUIRE(lines.front() == "# arglog 1 " + std::string(fn) + " " + std::string(schema));
    std::size_t const n_fields = split(schema).size();
    std::vector<ArglogRecord> records;
    records.reserve(lines.size() - 1);
    for (std::size_t i = 1; i < lines.size(); ++i) {
        auto parts = split(lines.at(i));
        REQUIRE(parts.size() == n_fields + 5);
        ArglogRecord rec;
        rec.seq = std::stoll(parts.at(0));
        rec.site = parts.at(4);
        rec.tokens.assign(parts.begin() + 5, parts.end());
        records.push_back(std::move(rec));
    }
    return records;
}

std::span<std::string_view const> arglog_captures() noexcept {
    return captures;
}

std::size_t
check_replay(std::string_view fn, std::string_view schema,
             std::function<std::string(std::vector<std::string> const&)> const& recompute) {
    std::string const header = "# arglog 1 " + std::string(fn) + " " + std::string(schema);
    auto const types = field_types(header);
    auto const names = field_names(header);
    std::size_t replayed = 0;
    for (std::string_view const capture : captures) {
        auto const records = read_arglog(capture, fn, schema);
        if (!records) {
            continue;
        }
        for (ArglogRecord const& rec : *records) {
            auto const got = split(recompute(rec.tokens));
            bool nan_only = true;
            if (!same_tokens(types, rec.tokens, got, nan_only)) {
                FAIL(capture << " " << fn << " seq " << rec.seq << " at " << rec.site
                             << describe(names, types, rec.tokens, got));
            }
            ++replayed;
        }
    }
    return replayed;
}

} // namespace gef::test::m5
