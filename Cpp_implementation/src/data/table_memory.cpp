// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "data/table_memory.hpp"

#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"

#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>

namespace gef::data {
namespace {

constexpr std::int64_t single_bytes = 4;

// glibc malloc: the chunk for a request of n bytes is n + 8 rounded up to 16, and its user data
// starts 16 bytes after the chunk. fbc's ReDim allocates a table's elements with one request.
constexpr std::int64_t chunk_size(std::int64_t bytes) {
    return (bytes + 8 + 15) / 16 * 16;
}

// The size word of a chunk in use, as glibc writes it: the chunk size with PREV_INUSE (bit 0)
// set, the previous chunk being in use.
constexpr std::uint32_t size_word(std::int64_t bytes) {
    return static_cast<std::uint32_t>(chunk_size(bytes)) | 1U;
}

constexpr std::array<MassTable, 5> block_order{
    MassTable::BeldmTf, MassTable::BeExp, MassTable::DefoTab, MassTable::ShellMo, MassTable::Evod};

fb::Array<float, 2> const& array_of(TableSet const& tables, MassTable table) {
    switch (table) {
    case MassTable::BeldmTf:
        return tables.beldm_tf;
    case MassTable::BeExp:
        return tables.be_exp;
    case MassTable::DefoTab:
        return tables.defo_tab;
    case MassTable::ShellMo:
        return tables.shell_mo;
    case MassTable::Evod:
        break;
    }
    return tables.evod;
}

std::int64_t columns(fb::Array<float, 2> const& a) {
    return a.ubound(2) - a.lbound(2) + 1;
}

std::int64_t data_bytes(fb::Array<float, 2> const& a) {
    return (a.ubound(1) - a.lbound(1) + 1) * columns(a) * single_bytes;
}

bool inside(fb::Array<float, 2> const& a, std::int64_t i, std::int64_t j) {
    return i >= a.lbound(1) && i <= a.ubound(1) && j >= a.lbound(2) && j <= a.ubound(2);
}

// One table of the block: where its elements start, relative to BEldmTF's first element.
struct Placed {
    fb::Array<float, 2> const* array = nullptr;
    std::int64_t start = 0;
    std::int64_t bytes = 0;
};

std::array<Placed, block_order.size()> place(TableSet const& tables) {
    std::array<Placed, block_order.size()> placed{};
    std::int64_t start = 0;
    for (std::size_t k = 0; k < block_order.size(); ++k) {
        fb::Array<float, 2> const& a = array_of(tables, block_order.at(k));
        placed.at(k) = Placed{.array = &a, .start = start, .bytes = data_bytes(a)};
        start += chunk_size(placed.at(k).bytes);
    }
    return placed;
}

} // namespace

float read_mass_table(TableSet const& tables, MassTable table, std::int64_t i, std::int64_t j) {
    fb::Array<float, 2> const& a = array_of(tables, table);
    // QUIRK(Q-042): with the fix, a read outside the bounds throws (fb::Array).
    if (inside(a, i, j) || tables.fix_table_overrun) {
        return a(i, j);
    }
    // The address fbc computes: `data + (i * columns + j) * 4`, data being the address of the
    // element (0, 0); relative to the first element that is ((i - lb1) * columns + j - lb2) * 4.
    std::int64_t const linear =
        fb::add(fb::mul(fb::sub(i, a.lbound(1)), columns(a)), fb::sub(j, a.lbound(2)));
    std::array<Placed, block_order.size()> const placed = place(tables);
    std::int64_t own_start = 0;
    for (Placed const& p : placed) {
        if (p.array == &a) {
            own_start = p.start;
        }
    }
    std::int64_t const offset = fb::add(own_start, fb::mul(linear, single_bytes));
    Placed const& last = placed.back();
    if (offset < 0 || offset >= last.start + last.bytes) {
        throw std::out_of_range("table read (" + std::to_string(i) + ", " + std::to_string(j) +
                                ") outside the memory of GEF's mass tables");
    }
    for (Placed const& p : placed) {
        if (offset < p.start + p.bytes) {
            if (offset < p.start) {
                // The gap before this table: the zero-filled end of the previous chunk, then
                // this chunk's size word (low half at start - 8, high half 0 at start - 4).
                return offset == p.start - 8 ? std::bit_cast<float>(size_word(p.bytes)) : 0.0F;
            }
            std::int64_t const element = (offset - p.start) / single_bytes;
            fb::Array<float, 2> const& other = *p.array;
            return other(other.lbound(1) + element / columns(other),
                         other.lbound(2) + element % columns(other));
        }
    }
    throw std::logic_error("read_mass_table: the offset lies in no part of the block");
}

} // namespace gef::data
