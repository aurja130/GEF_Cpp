// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "support/probe_dump.hpp"

#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <map>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace gef::test {

namespace {

// FNV-1a 64 step over one byte (the multiplication wraps modulo 2^64).
void fnv_step(std::uint64_t& hash, unsigned char byte) {
    hash = (hash ^ byte) * 0x100000001B3ULL;
}

// Upper-case hexadecimal of `bits`, left-padded with zeros to `width` digits (`width` <= 16).
std::string hex_text(std::uint64_t bits, std::size_t width) {
    constexpr std::string_view digits = "0123456789ABCDEF";
    std::string text(width, '0');
    for (std::size_t i = 0; i < width; ++i) {
        text.at(width - 1 - i) = digits.at((bits >> (4 * i)) & 0xFU);
    }
    return text;
}

} // namespace

namespace detail {

std::string single_bits(float value) {
    return hex_text(std::bit_cast<std::uint32_t>(value), 8);
}

std::string double_bits(double value) {
    return hex_text(std::bit_cast<std::uint64_t>(value), 16);
}

std::string quoted(std::string_view text) {
    std::string out = "\"";
    for (char const ch : text) {
        auto const byte = static_cast<unsigned char>(ch);
        if (ch == '\\') {
            out += "\\\\";
        } else if (ch == '"') {
            out += "\\\"";
        } else if (byte >= 32 && byte <= 126) {
            out += ch;
        } else {
            out += "\\x";
            out += hex_text(byte, 2);
        }
    }
    out += '"';
    return out;
}

std::string dump_line(std::string_view id, std::string_view context, std::string_view name,
                      std::string_view index, std::string_view type, std::string_view value) {
    std::string line(id);
    line += ' ';
    line += context;
    line += ' ';
    line += name;
    line += ' ';
    line += index;
    line += ' ';
    line += type;
    line += ' ';
    line += value;
    return line;
}

std::string range_text(std::int64_t lower, std::int64_t upper) {
    return std::to_string(lower) + ':' + std::to_string(upper);
}

} // namespace detail

ProbeDump::ProbeDump(std::string id, std::string context)
    : id_(std::move(id)), context_(std::move(context)) {}

void ProbeDump::scalar(std::string_view name, float value) {
    lines_[std::string(name)].push_back(
        detail::dump_line(id_, context_, name, "-", "S", detail::element_text(value)));
}

void ProbeDump::scalar(std::string_view name, double value) {
    lines_[std::string(name)].push_back(
        detail::dump_line(id_, context_, name, "-", "D", detail::element_text(value)));
}

void ProbeDump::scalar(std::string_view name, std::int64_t value) {
    lines_[std::string(name)].push_back(
        detail::dump_line(id_, context_, name, "-", "I", detail::element_text(value)));
}

void ProbeDump::scalar(std::string_view name, std::string_view value) {
    lines_[std::string(name)].push_back(
        detail::dump_line(id_, context_, name, "-", "Z", detail::quoted(value)));
}

std::vector<std::string> const& ProbeDump::lines(std::string_view name) const {
    auto const found = lines_.find(name);
    if (found == lines_.end()) {
        throw std::out_of_range("probe_dump: no variable " + std::string(name));
    }
    return found->second;
}

ProbeFingerprint fingerprint_lines(std::vector<std::string> const& lines) {
    ProbeFingerprint fingerprint;
    for (std::string const& line : lines) {
        for (char const ch : line) {
            fnv_step(fingerprint.fnv, static_cast<unsigned char>(ch));
        }
        fnv_step(fingerprint.fnv, '\n');
        ++fingerprint.lines;
    }
    return fingerprint;
}

ProbeFingerprint ProbeDump::fingerprint(std::string_view name) const {
    return fingerprint_lines(lines(name));
}

std::map<std::string, ProbeFingerprint, std::less<>> read_fingerprints(std::string_view golden_name,
                                                                       std::string_view file) {
    std::map<std::string, ProbeFingerprint, std::less<>> fingerprints;
    for (std::string const& line : read_lines(golden_file(golden_name, file))) {
        if (line.empty() || line.front() == '#') {
            continue;
        }
        auto const first = line.find(' ');
        auto const second = first == std::string::npos ? first : line.find(' ', first + 1);
        if (second == std::string::npos || line.find(' ', second + 1) != std::string::npos) {
            FAIL("malformed fingerprint line: '" << line << "'");
        }
        std::string const name = line.substr(0, first);
        std::string_view const count = std::string_view(line).substr(first + 1, second - first - 1);
        std::string_view const digest = std::string_view(line).substr(second + 1);

        if (count.empty() ||
            !std::ranges::all_of(count, [](char ch) { return ch >= '0' && ch <= '9'; })) {
            FAIL("bad line count in fingerprint line: '" << line << "'");
        }
        ProbeFingerprint fingerprint;
        fingerprint.lines =
            static_cast<decltype(fingerprint.lines)>(std::stoull(std::string(count)));
        if (digest.size() != 16) {
            FAIL("fingerprint digest is not 16 hex digits: '" << line << "'");
        }
        fingerprint.fnv = parse_hex(digest);
        if (!fingerprints.emplace(name, fingerprint).second) {
            FAIL("duplicate fingerprint for " << name);
        }
    }
    return fingerprints;
}

} // namespace gef::test
