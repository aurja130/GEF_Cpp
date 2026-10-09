// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

// fb::DataReader: BASIC `DATA` / `READ` / `RESTORE` (data.c, data_read*.c; M3.8).
//
// fbc stores every DATA item as its source text, in DATA blocks chained in program order
// (each block ends with a link to the next one, the last with a null link). The reader is
// given that chain flattened into one item list; a label is the index of its block's first
// item. M4's converter produces the list from the GEF sources.

#pragma once

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>

namespace gef::fb {

class DataReader {
public:
    // `items` must outlive the reader. It starts at the first item: a BASIC program's first
    // Read without a Restore reads the first DATA block (M3.8 driver).
    //
    // The item texts must be the ones fbc stored (the GEF.c tables), not the BASIC source:
    // fbc rewrites unquoted numbers at compile time (to 15 significant digits, `1.E-3` →
    // `0.001`, `1D2` → `100`, `-0` → `0`, `&H1F` → `31`); quoted items stay as written.
    explicit DataReader(std::span<std::string_view const> items) noexcept;

    // `Restore label`: continue reading at item `index` (items.size() means the end).
    void restore(std::size_t index) noexcept;

    // `Read x`: convert the next item and advance. Past the end every read gives 0 or "".
    [[nodiscard]] float read_single();         // fb_DataReadSingle: Val as Double, then narrowed
    [[nodiscard]] double read_double();        // fb_DataReadDouble
    [[nodiscard]] std::int64_t read_longint(); // fb_DataReadLongint: ValLng
    [[nodiscard]] std::string read_string();   // fb_DataReadStr

    [[nodiscard]] std::size_t position() const noexcept { return pos_; }

private:
    std::span<std::string_view const> items_;
    std::size_t pos_ = 0;
};

} // namespace gef::fb
