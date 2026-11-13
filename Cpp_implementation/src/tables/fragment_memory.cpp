// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "tables/fragment_memory.hpp"

#include "data/table_memory.hpp"
#include "data/tables.hpp"
#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"
#include "tables/bin_tables.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <stdexcept>
#include <string>

namespace gef::tables {
namespace {

constexpr std::int64_t single_bytes = 4;
// Data end of one table to data start of the next: 8 bytes of chunk slack, 8 of size word.
constexpr std::int64_t gap_bytes = 16;
constexpr std::size_t table_count = 8;

constexpr std::array<FragmentTable, table_count> block_order{
    FragmentTable::Zmean,  FragmentTable::Zshift, FragmentTable::Temp, FragmentTable::TempFF,
    FragmentTable::Eshell, FragmentTable::Peoz,   FragmentTable::Peon, FragmentTable::Epart};

template <typename Tables>
auto& array_of(Tables& t, FragmentTable table) {
    switch (table) {
    case FragmentTable::Zmean:
        return t.zmean;
    case FragmentTable::Zshift:
        return t.zshift;
    case FragmentTable::Temp:
        return t.temp;
    case FragmentTable::TempFF:
        return t.tempff;
    case FragmentTable::Eshell:
        return t.eshell;
    case FragmentTable::Peoz:
        return t.peoz;
    case FragmentTable::Peon:
        return t.peon;
    case FragmentTable::Epart:
        break;
    }
    return t.epart;
}

bool inside(fb::Array<float, 3> const& a, std::int64_t m, std::int64_t k, std::int64_t i) {
    return m >= a.lbound(1) && m <= a.ubound(1) && k >= a.lbound(2) && k <= a.ubound(2) &&
           i >= a.lbound(3) && i <= a.ubound(3);
}

std::int64_t extent(fb::Array<float, 3> const& a, int dimension) {
    return a.ubound(dimension) - a.lbound(dimension) + 1;
}

std::int64_t data_bytes(fb::Array<float, 3> const& a) {
    return static_cast<std::int64_t>(a.elements().size()) * single_bytes;
}

// Where an out-of-bound access lands: the element `element` of table `table` (row-major, from
// its first element), the Single `gap_single` of BinTables::fragment_gaps, or `past_end` bytes
// after EPART's last element.
struct Location {
    bool in_gap = false;
    bool after_epart = false;
    std::size_t table = 0;
    std::size_t element = 0;
    std::size_t gap_single = 0;
    std::int64_t past_end = 0;
};

[[noreturn]] void throw_outside(std::int64_t m, std::int64_t k, std::int64_t i) {
    throw std::out_of_range("GEF.bas: fragment table index (" + std::to_string(m) + ", " +
                            std::to_string(k) + ", " + std::to_string(i) +
                            ") outside the memory of GEF's A-indexed tables (QUIRKS Q-061)");
}

Location locate(BinTables const& t, FragmentTable table, std::int64_t m, std::int64_t k,
                std::int64_t i) {
    fb::Array<float, 3> const& a = array_of(t, table);
    // The address fbc computes, relative to the table's first element:
    // (((m - lb1) * extent2 + k - lb2) * extent3 + i - lb3) * 4.
    std::int64_t const linear = fb::add(
        fb::mul(fb::add(fb::mul(fb::sub(m, a.lbound(1)), extent(a, 2)), fb::sub(k, a.lbound(2))),
                extent(a, 3)),
        fb::sub(i, a.lbound(3)));
    // Each table's first element, relative to Zmean's.
    std::array<std::int64_t, table_count> start{};
    std::int64_t end = 0;
    for (std::size_t n = 0; n < table_count; ++n) {
        start.at(n) = end;
        end += data_bytes(array_of(t, block_order.at(n))) + gap_bytes;
    }
    end -= gap_bytes; // EPART's last byte + 1
    auto const own = static_cast<std::size_t>(table);
    std::int64_t const offset = fb::add(start.at(own), fb::mul(linear, single_bytes));
    if (offset < 0) {
        throw_outside(m, k, i);
    }
    if (offset >= end) {
        return Location{.after_epart = true, .past_end = offset - end};
    }
    for (std::size_t n = 0; n < table_count; ++n) {
        std::int64_t const table_end = start.at(n) + data_bytes(array_of(t, block_order.at(n)));
        if (offset < table_end) {
            if (offset < start.at(n)) {
                // The gap before table n (n >= 1): four Singles.
                std::int64_t const in_gap = (offset - (start.at(n) - gap_bytes)) / single_bytes;
                return Location{.in_gap = true,
                                .gap_single = ((n - 1) * 4) + static_cast<std::size_t>(in_gap)};
            }
            return Location{.table = n,
                            .element =
                                static_cast<std::size_t>((offset - start.at(n)) / single_bytes)};
        }
    }
    throw std::logic_error("fragment_element: the offset lies in no part of the block");
}

// The table element or gap Single at `at`; an access past EPART throws.
template <typename Tables>
auto& landing(Tables& t, Location const& at, std::int64_t m, std::int64_t k, std::int64_t i) {
    if (at.after_epart) {
        throw_outside(m, k, i);
    }
    if (at.in_gap) {
        return t.fragment_gaps.at(at.gap_single);
    }
    return array_of(t, block_order.at(at.table)).elements().subspan(at.element, 1).front();
}

} // namespace

float& fragment_element(BinTables& t, FragmentTable table, std::int64_t m, std::int64_t k,
                        std::int64_t i) {
    fb::Array<float, 3>& a = array_of(t, table);
    // QUIRK(Q-061): with the fix, an access outside the bounds throws (fb::Array).
    if (inside(a, m, k, i) || t.fix_fragment_table_overrun) {
        return a(m, k, i);
    }
    return landing(t, locate(t, table, m, k, i), m, k, i);
}

float fragment_element(BinTables const& t, FragmentTable table, std::int64_t m, std::int64_t k,
                       std::int64_t i) {
    fb::Array<float, 3> const& a = array_of(t, table);
    if (inside(a, m, k, i) || t.fix_fragment_table_overrun) {
        return a(m, k, i);
    }
    return landing(t, locate(t, table, m, k, i), m, k, i);
}

float fragment_element(BinTables const& t, data::TableSet const& tables, FragmentTable table,
                       std::int64_t m, std::int64_t k, std::int64_t i) {
    fb::Array<float, 3> const& a = array_of(t, table);
    if (inside(a, m, k, i) || t.fix_fragment_table_overrun) {
        return a(m, k, i);
    }
    Location const at = locate(t, table, m, k, i);
    if (at.after_epart) {
        // EPART's chunk is followed by BEldmTF's: its last 16 bytes before BEldmTF's first
        // element are read_mass_memory's offsets -16 to -1.
        return data::read_mass_memory(tables, at.past_end - gap_bytes);
    }
    return landing(t, at, m, k, i);
}

void store_spin_rms(BinTables& t, std::int64_t m, std::int64_t k, std::int64_t n, std::int64_t z,
                    float value) {
    fb::Array<float, 4>& a = t.spinrmsnz;
    bool const in_bounds = m >= a.lbound(1) && m <= a.ubound(1) && k >= a.lbound(2) &&
                           k <= a.ubound(2) && n >= a.lbound(3) && n <= a.ubound(3) &&
                           z >= a.lbound(4) && z <= a.ubound(4);
    // QUIRK(Q-061): with the fix, a write outside the bounds throws (fb::Array).
    if (in_bounds || t.fix_fragment_table_overrun) {
        a(m, k, n, z) = value;
        return;
    }
    auto extent4 = [&a](int dimension) { return a.ubound(dimension) - a.lbound(dimension) + 1; };
    // The element fbc addresses, relative to the first one.
    std::int64_t const linear =
        fb::add(fb::mul(fb::add(fb::mul(fb::add(fb::mul(fb::sub(m, a.lbound(1)), extent4(2)),
                                                fb::sub(k, a.lbound(2))),
                                        extent4(3)),
                                fb::sub(n, a.lbound(3))),
                        extent4(4)),
                fb::sub(z, a.lbound(4)));
    if (linear < 0) {
        throw std::out_of_range("GEF.bas: SpinRMSNZ index (" + std::to_string(m) + ", " +
                                std::to_string(k) + ", " + std::to_string(n) + ", " +
                                std::to_string(z) + ") before the array (QUIRKS Q-061)");
    }
    std::span<float> const elements = a.elements();
    if (static_cast<std::uint64_t>(linear) < elements.size()) {
        elements.subspan(static_cast<std::size_t>(linear), 1).front() = value;
    }
    // Past the end: dropped (the user's decision of 2026-11-12, QUIRKS Q-061).
}

} // namespace gef::tables
