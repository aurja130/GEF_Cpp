// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF's string utilities from utilities.bi (ConvTab, CC_Count, CC_Cut), namespace gef::util.

#pragma once

#include "fbrt/array.hpp"

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace gef::util {

// ConvTab: every Chr(9) becomes " ".
[[nodiscard]] std::string conv_tab(std::string_view s);

// CC_Count: the number of pieces of CIn separated by CDiv.
[[nodiscard]] std::int64_t cc_count(std::string_view in, std::string_view div);

// CC_Cut: cuts CIn into COut(1..N). When COut is too small, the BASIC runtime prints
// "<E> Dimension of COut too small in CC_cut(<CIn>)" (the Print line, without its newline),
// which is appended to console, and the last element is overwritten.
void cc_cut(std::string_view in, std::string_view div, fb::Array<std::string, 1>& out,
            std::int64_t& n, std::vector<std::string>& console);

} // namespace gef::util
