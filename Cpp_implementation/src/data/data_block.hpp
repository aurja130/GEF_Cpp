// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The records the generated DATA sources (generated/) are written in. A DataBlock is some of the
// items of one DATA table of fbc's emitted C, each followed by a newline, in one string. A table
// longer than one block's size limit spans several DataBlocks, in chain order.

#pragma once

#include <cstddef>
#include <span>
#include <string_view>

namespace gef::data {

// One run of DATA items: `text` holds each item followed by '\n'; `items` is the number of items.
struct DataBlock {
    std::string_view text;
    std::size_t items;
};

// A BASIC label that Restore uses, and the index in the variant's chain of its table's first block.
struct LabelEntry {
    std::string_view name;
    std::size_t block;
};

// One nuclide-data variant: its ISOSOURCE, its DATA blocks in chain order, its labels.
struct VariantTables {
    std::string_view isosource;
    std::span<DataBlock const* const> chain;
    std::span<LabelEntry const> labels;
};

} // namespace gef::data
