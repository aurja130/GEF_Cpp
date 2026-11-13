// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Accesses to GEF's eight A-indexed tables as the program built by fbc performs them
// (QUIRK(Q-061)). fbc compiles GEF without -exx, so `Zmean(M, K, I)` is the Single at
// `data + ((M * 2 + K) * 351 + I) * 4` whatever M, K and I are. The eight tables are allocated
// one after the other at start-up (GEF.bas:1109-1193, `ReDim Shared` in this order), each a glibc
// malloc chunk, so an index past the end of a row reaches the next row, and one past the end of a
// table reaches the gap and then the next table:
//
//   Zmean | 16 | Zshift | 16 | Temp | 16 | TempFF | 16 | Eshell | 16 | PEOZ | 16 | PEON | 16 |
//   EPART
//
// A gap is the zero-filled end of the previous chunk (8 bytes, libfb's ReDim allocates with
// calloc), then the next chunk's size word (8 bytes: the chunk size with PREV_INUSE set, high half
// 0). The gaps are state (BinTables::fragment_gaps): GEF's out-of-bound writes change them.
// EPART's chunk is followed by BEldmTF's (data/table_memory.hpp): GEF.bas:7475 reads past EPART
// into it. Established on both reference binaries with gdb (Planning/QUIRKS.md Q-061).

#pragma once

#include "data/tables.hpp"
#include "tables/bin_tables.hpp"

#include <cstdint>

namespace gef::tables {

// The tables of the contiguous block, in allocation order.
enum class FragmentTable : std::uint8_t {
    Zmean,  // Zmean(0 To 5, 1 To 2, 350)
    Zshift, // Zshift(0 To 5, 1 To 2, 350)
    Temp,   // Temp(0 To 5, 1 To 2, 350)
    TempFF, // TempFF(0 To 5, 1 To 2, 350)
    Eshell, // Eshell(0 To 5, 1 To 2, 350)
    Peoz,   // PEOZ(0 To 7, 1 To 2, 350)
    Peon,   // PEON(0 To 7, 1 To 2, 350)
    Epart,  // EPART(0 To 7, 1 To 2, 350)
};

// `table(m, k, i)` as GEF accesses it. Inside the bounds: the element. Outside: with
// `t.fix_fragment_table_overrun` false (reproduce, the default), the element or gap Single the
// reference binary reaches at that address in the block above; with it true, std::out_of_range.
// An address before Zmean or after EPART lies outside the known memory and throws
// std::out_of_range either way.
[[nodiscard]] float& fragment_element(BinTables& t, FragmentTable table, std::int64_t m,
                                      std::int64_t k, std::int64_t i);
[[nodiscard]] float fragment_element(BinTables const& t, FragmentTable table, std::int64_t m,
                                     std::int64_t k, std::int64_t i);
// The same read, except that an address after EPART reads the memory that follows it in the
// reference binary: 8 zero bytes, BEldmTF's size word, then the mass tables
// (data::read_mass_memory).
[[nodiscard]] float fragment_element(BinTables const& t, data::TableSet const& tables,
                                     FragmentTable table, std::int64_t m, std::int64_t k,
                                     std::int64_t i);

// GEF.bas:7464/7499 `SpinRMSNZ(m, k, n, z) = value` as the reference binary performs it
// (QUIRK(Q-061)): fbc writes the Single at `(((m * 2 + k - 1) * 200 + n - 1) * 150 + z - 1)`
// from the first element, so an N past 200 lands in the next fragment's or mode's block. With
// `t.fix_fragment_table_overrun` false (the default) a write past the array's end is dropped:
// SpinRMSNZ is a mmap chunk of its own, and what follows it depends on the address-space layout
// (the reference run lives in 15 of 20 runs, Planning/QUIRKS.md Q-061). With the switch true, any
// write outside the bounds throws std::out_of_range. An address before the first element throws
// either way.
void store_spin_rms(BinTables& t, std::int64_t m, std::int64_t k, std::int64_t n, std::int64_t z,
                    float value);

} // namespace gef::tables
