// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

#include "fbrt/strings.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <vector>

namespace gef::fb {

namespace {

// FB_CHAR_TO_INT (fb.h): the byte as an unsigned value, 0..255.
std::size_t char_index(char c) noexcept {
    return static_cast<std::size_t>(static_cast<unsigned char>(c));
}

// str_instr.c fb_hFindBM: Boyer-Moore search, literal port. Returns the 1-based position or 0.
std::int64_t find_bm(std::int64_t start, std::string_view text, std::string_view pattern) {
    auto const len_text = static_cast<std::int64_t>(text.size());
    auto const len_pattern = static_cast<std::int64_t>(pattern.size());
    auto const len_max = len_text - len_pattern;
    auto const pat = [&pattern](std::int64_t k) { return pattern.at(static_cast<std::size_t>(k)); };
    auto const txt = [&text](std::int64_t k) { return text.at(static_cast<std::size_t>(k)); };

    std::array<std::int64_t, 256> bm_bc{};
    bm_bc.fill(-1);
    std::vector<std::int64_t> bm_gc(static_cast<std::size_t>(len_pattern + 1), 0);
    std::vector<std::int64_t> suffixes(static_cast<std::size_t>(len_pattern + 1), 0);

    // create "bad character" shifts
    for (std::int64_t i = 0; i != len_pattern; ++i) {
        bm_bc.at(char_index(pat(i))) = i;
    }

    // preprocessing for "good end strategy" case 1
    std::int64_t i = len_pattern;
    std::int64_t j = len_pattern + 1;
    suffixes.at(static_cast<std::size_t>(i)) = j;
    while (i != 0) {
        char const ch1 = pat(i - 1);
        while (j <= len_pattern && ch1 != pat(j - 1)) {
            if (bm_gc.at(static_cast<std::size_t>(j)) == 0) {
                bm_gc.at(static_cast<std::size_t>(j)) = j - i;
            }
            j = suffixes.at(static_cast<std::size_t>(j));
        }
        --i;
        --j;
        suffixes.at(static_cast<std::size_t>(i)) = j;
    }

    // preprocessing for "good end strategy" case 2
    j = suffixes.at(0);
    for (i = 0; i <= len_pattern; ++i) {
        if (bm_gc.at(static_cast<std::size_t>(i)) == 0) {
            bm_gc.at(static_cast<std::size_t>(i)) = j;
        }
        if (i == j) {
            j = suffixes.at(static_cast<std::size_t>(j));
        }
    }

    std::int64_t ret = 0;
    i = start;
    while (i <= len_max) {
        j = len_pattern;
        while (j != 0 && pat(j - 1) == txt(i + j - 1)) {
            --j;
        }
        if (j == 0) {
            ret = i + 1;
            break;
        }
        char const ch_text = txt(i + j - 1);
        std::int64_t const shift_gc = bm_gc.at(static_cast<std::size_t>(j));
        std::int64_t const shift_bc = j - 1 - bm_bc.at(char_index(ch_text));
        i += (shift_gc > shift_bc) ? shift_gc : shift_bc;
    }
    return ret;
}

} // namespace

// str_trim.c fb_TRIM: fb_hStrSkipCharRev strips the trailing run of ASCII 32 and NUL (fixed-length
// padding); fb_hStrSkipChar then strips the leading run of ASCII 32 only (str_hskip.c).
std::string trim(std::string_view s) {
    std::size_t last = s.size();
    while (last > 0 && (s.at(last - 1) == ' ' || s.at(last - 1) == '\0')) {
        --last;
    }
    std::size_t first = 0;
    while (first < last && s.at(first) == ' ') {
        ++first;
    }
    return std::string(s.substr(first, last - first));
}

std::string ucase(std::string_view s) {
    std::string out(s);
    for (char& c : out) {
        if (c >= 'a' && c <= 'z') {
            c = static_cast<char>(c - ('a' - 'A'));
        }
    }
    return out;
}

std::int64_t instr(std::string_view s, std::string_view pattern) {
    return instr(1, s, pattern);
}

// str_instr.c fb_StrInstr
std::int64_t instr(std::int64_t start, std::string_view s, std::string_view pattern) {
    auto const size_src = static_cast<std::int64_t>(s.size());
    auto const size_patt = static_cast<std::int64_t>(pattern.size());
    if (size_src == 0 || size_patt == 0 || start < 1 || start > size_src || size_patt > size_src) {
        return 0;
    }
    if (size_patt == 1) {
        auto const found = s.find(pattern.front(), static_cast<std::size_t>(start - 1));
        return found == std::string_view::npos ? 0 : static_cast<std::int64_t>(found) + 1;
    }
    return find_bm(start - 1, s, pattern);
}

std::string mid(std::string_view s, std::int64_t start) {
    return mid(s, start, -1);
}

// str_mid.c fb_StrMid: the 1-based start is converted to 0-based first, then len is clipped to
// the end of the string. A negative len means "to the end" (len = src_len, then clipped).
std::string mid(std::string_view s, std::int64_t start, std::int64_t len) {
    auto const src_len = static_cast<std::int64_t>(s.size());
    if (src_len == 0 || start < 1 || start > src_len || len == 0) {
        return {};
    }
    --start;
    if (len < 0) {
        len = src_len;
    }
    // start + len > src_len, without overflowing for huge len
    len = std::min(len, src_len - start);
    return std::string(s.substr(static_cast<std::size_t>(start), static_cast<std::size_t>(len)));
}

} // namespace gef::fb
