// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Reads of GEF's mass, deformation and shell tables as the program built by fbc performs them
// (QUIRK(Q-042)). fbc compiles GEF without -exx, so `BEexp(N, Z)` is the Single at
// `data + (N * 137 + Z) * 4` whatever N and Z are. The five tables are allocated one after the
// other at start-up (GEF.bas:1222-1266, `ReDim Shared` in this order, nothing allocated between
// them), each a glibc malloc chunk, so an index past the end of one table reads the next table,
// or the chunk header between them:
//
//   BEldmTF | 16 bytes | BEexp | 16 bytes | DEFOtab | 12 bytes | ShellMO | 16 bytes | EVOD
//
// A gap is the zero-filled end of the previous chunk (libfb's ReDim allocates with calloc, which
// clears the chunk up to the next one's size word), then the next chunk's 8-byte size word (its
// chunk size with bit 0, PREV_INUSE, set). Established on the reference binary with gdb
// (Planning/QUIRKS.md Q-042: the memory from BEldmTF's first element to EVOD's last equals this
// layout byte for byte, and three builds place the tables at the same relative offsets).

#pragma once

#include "data/tables.hpp"

#include <cstdint>

namespace gef::data {

// The tables of the contiguous block, in allocation order.
enum class MassTable : std::uint8_t {
    BeldmTf, // BEldmTF(0 To 203, 0 To 136)
    BeExp,   // BEexp(0 To 203, 0 To 136)
    DefoTab, // DEFOtab(0 To 236, 0 To 136)
    ShellMo, // ShellMO(0 To 203, 0 To 136)
    Evod,    // EVOD(0 To 203, 0 To 136), never filled
};

// `table(i, j)` as GEF reads it. Inside the bounds: the element. Outside: with
// `tables.fix_table_overrun` false (reproduce, the default), the Single the reference binary
// finds at that address in the block above; with it true, std::out_of_range. An address before
// BEldmTF or after EVOD lies outside the known memory and throws std::out_of_range either way.
[[nodiscard]] float read_mass_table(TableSet const& tables, MassTable table, std::int64_t i,
                                    std::int64_t j);

} // namespace gef::data
