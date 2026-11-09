// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// QUIRK(Q-061): accesses of the eight A-indexed tables outside their bounds. The layout and the
// gap words were read from both reference binaries with gdb (MILESTONE_7_PLAN.md §5, M7.2): the
// tables lie 16 bytes apart, and each gap holds 0, 0, the next chunk's size word, 0.

#include "tables/bin_tables.hpp"
#include "tables/fragment_memory.hpp"

#include <catch2/catch_test_macros.hpp>

#include <bit>
#include <cstdint>
#include <memory>
#include <stdexcept>

namespace {

using gef::tables::BinTables;
using gef::tables::fragment_element;
using gef::tables::FragmentTable;

std::uint32_t bits(float x) {
    return std::bit_cast<std::uint32_t>(x);
}

// Every element of the eight tables holds a value unique to its table and position, so a wrong
// landing element shows.
std::unique_ptr<BinTables> marked() {
    auto t = std::make_unique<BinTables>();
    float table_base = 0.0F;
    for (auto* a :
         {&t->zmean, &t->zshift, &t->temp, &t->tempff, &t->eshell, &t->peoz, &t->peon, &t->epart}) {
        table_base += 100000.0F;
        float n = table_base;
        for (float& x : a->elements()) {
            x = n;
            n += 1.0F;
        }
    }
    return t;
}

} // namespace

TEST_CASE("tables: fragment-table accesses inside the bounds reach the element", "[unit][tables]") {
    auto const t = marked();
    BinTables const& c = *t;
    CHECK(bits(fragment_element(c, FragmentTable::Zmean, 0, 1, 0)) == bits(c.zmean(0, 1, 0)));
    CHECK(bits(fragment_element(c, FragmentTable::Zshift, 5, 2, 350)) == bits(c.zshift(5, 2, 350)));
    CHECK(bits(fragment_element(c, FragmentTable::Epart, 7, 2, 350)) == bits(c.epart(7, 2, 350)));
    fragment_element(*t, FragmentTable::Peoz, 3, 1, 200) = -1.5F;
    CHECK(t->peoz(3, 1, 200) == -1.5F);
}

TEST_CASE("tables: fragment-table indices past a row reach the next row of the table",
          "[unit][tables]") {
    auto const t = marked();
    BinTables const& c = *t;
    // Zmean(M, 1, 351 + J) is Zmean(M, 2, J); Zmean(M, 2, 351 + J) is Zmean(M + 1, 1, J).
    CHECK(bits(fragment_element(c, FragmentTable::Zmean, 0, 1, 351)) == bits(c.zmean(0, 2, 0)));
    CHECK(bits(fragment_element(c, FragmentTable::Zshift, 2, 1, 375)) == bits(c.zshift(2, 2, 24)));
    CHECK(bits(fragment_element(c, FragmentTable::Zshift, 2, 2, 375)) == bits(c.zshift(3, 1, 24)));
    // A write lands there too (Zmean(4, 2, 360) of the Z(A) loop at A_CN 370).
    fragment_element(*t, FragmentTable::Zmean, 4, 2, 360) = 42.0F;
    CHECK(t->zmean(5, 1, 9) == 42.0F);
}

TEST_CASE("tables: fragment-table indices past a table reach the gap, then the next table",
          "[unit][tables]") {
    auto const t = marked();
    BinTables const& c = *t;
    // After Zmean(5, 2, 350): 0, 0, Zshift's size word 0x41E1, 0, then Zshift(0, 1, 0).
    CHECK(bits(fragment_element(c, FragmentTable::Zmean, 5, 2, 351)) == 0x00000000U);
    CHECK(bits(fragment_element(c, FragmentTable::Zmean, 5, 2, 352)) == 0x00000000U);
    CHECK(bits(fragment_element(c, FragmentTable::Zmean, 5, 2, 353)) == 0x000041E1U);
    CHECK(bits(fragment_element(c, FragmentTable::Zmean, 5, 2, 354)) == 0x00000000U);
    CHECK(bits(fragment_element(c, FragmentTable::Zmean, 5, 2, 355)) == bits(c.zshift(0, 1, 0)));
    // Zshift's overrun reaches Temp; Eshell's reaches PEOZ, whose size word is 0x57D1.
    CHECK(bits(fragment_element(c, FragmentTable::Zshift, 5, 2, 375)) == bits(c.temp(0, 1, 20)));
    CHECK(bits(fragment_element(c, FragmentTable::Eshell, 5, 2, 353)) == 0x000057D1U);
    CHECK(bits(fragment_element(c, FragmentTable::Peon, 7, 2, 355)) == bits(c.epart(0, 1, 0)));
    // A negative index of the next table reaches the same gap Singles.
    CHECK(bits(fragment_element(c, FragmentTable::Zshift, 0, 1, -2)) == 0x000041E1U);
    CHECK(bits(fragment_element(c, FragmentTable::Epart, 0, 1, -2)) == 0x000057D1U);
}

TEST_CASE("tables: a fragment-table write into a gap stays in the gap", "[unit][tables]") {
    auto const t = marked();
    // Zshift(5, 2, 353) overwrites Temp's size word, as the A_CN 385 bin of capture
    // m7-q061-z120a385 does; later accesses through any table see the written Single.
    fragment_element(*t, FragmentTable::Zshift, 5, 2, 353) = 113.25F;
    BinTables const& c = *t;
    CHECK(fragment_element(c, FragmentTable::Temp, 0, 1, -2) == 113.25F);
    CHECK(c.fragment_gaps.at(6) == 113.25F);
    // The other gaps keep their start-up words, and a copy of BinTables carries the gap.
    BinTables const copy = c;
    CHECK(bits(fragment_element(copy, FragmentTable::Zmean, 5, 2, 353)) == 0x000041E1U);
    CHECK(fragment_element(copy, FragmentTable::Zshift, 5, 2, 353) == 113.25F);
}

TEST_CASE("tables: fragment-table accesses before Zmean or after EPART throw", "[unit][tables]") {
    auto const t = marked();
    BinTables const& c = *t;
    // Neither memory is known: the chunks next to the block hold other data.
    CHECK_THROWS_AS(fragment_element(c, FragmentTable::Zmean, 0, 1, -1), std::out_of_range);
    CHECK_THROWS_AS(fragment_element(*t, FragmentTable::Epart, 7, 2, 351), std::out_of_range);
    CHECK_THROWS_AS(fragment_element(c, FragmentTable::Zshift, 0, 1, -100000), std::out_of_range);
    // Zshift(0, 1, -4215): back over the 4 gap Singles and 4,211 Zmean Singles, Zmean(0, 1, 1).
    CHECK(bits(fragment_element(c, FragmentTable::Zshift, 0, 1, -4215)) == bits(c.zmean(0, 1, 1)));
}

TEST_CASE("tables: with fix_fragment_table_overrun an access outside the bounds throws",
          "[unit][tables]") {
    auto const t = marked();
    t->fix_fragment_table_overrun = true;
    BinTables const& c = *t;
    CHECK_THROWS_AS(fragment_element(c, FragmentTable::Zmean, 0, 1, 351), std::out_of_range);
    CHECK_THROWS_AS(fragment_element(*t, FragmentTable::Zmean, 5, 2, 353), std::out_of_range);
    CHECK(bits(fragment_element(c, FragmentTable::Zmean, 0, 1, 350)) == bits(c.zmean(0, 1, 350)));
}
