// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "util/utilities.hpp"

#include "fbrt/strings.hpp"

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace gef::util {

// utilities.bi ConvTab
std::string conv_tab(std::string_view s) {
    std::string out(s);
    for (char& c : out) {
        if (c == '\t') {
            c = ' ';
        }
    }
    return out;
}

// utilities.bi CC_Count
std::int64_t cc_count(std::string_view in, std::string_view div) {
    std::string crest = conv_tab(fb::trim(in)); // remove leading and trailing blanks
    if (crest.empty()) {
        return 0;
    }
    std::int64_t i = fb::instr(crest, div);
    if (i == 0) {
        return 1;
    }
    std::int64_t n = 0;
    while (i > 0) {
        ++n;
        crest = fb::trim(fb::mid(crest, i + static_cast<std::int64_t>(div.size())));
        i = fb::instr(crest, div);
    }
    return n + 1;
}

// utilities.bi CC_Cut
void cc_cut(std::string_view in, std::string_view div, fb::Array<std::string, 1>& out,
            std::int64_t& n, std::vector<std::string>& console) {
    std::string crest = conv_tab(fb::trim(in)); // remove leading and trailing blanks
    n = 0;
    if (crest.empty()) {
        return;
    }
    std::int64_t i = fb::instr(crest, div);
    if (i == 0) {
        n = 1;
        out(std::int64_t{1}) = std::string(in); // the untrimmed CIn
        return;
    }
    auto const div_len = static_cast<std::int64_t>(div.size());
    auto const too_small = [&] {
        console.push_back("<E> Dimension of COut too small in CC_cut(" + std::string(in) + ")");
    };
    while (i > 0) {
        ++n;
        if (n > out.ubound(1)) {
            --n;
            too_small();
        }
        out(n) = fb::mid(crest, 1, i - 1);
        crest = fb::trim(fb::mid(crest, i + div_len));
        i = fb::instr(crest, div);
    }
    ++n;
    if (n > out.ubound(1)) {
        --n;
        too_small();
    }
    out(n) = crest;
}

} // namespace gef::util
