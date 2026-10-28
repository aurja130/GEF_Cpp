// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// QUIRK(Q-042): reads of the mass, deformation and shell tables outside their bounds. The
// expected bit patterns were read from the reference binary (build seed-probes-32c3cfccb98c,
// capture edge-f_second_system_outside_table, gdb at the first AME2020(82, 300) call: the memory
// from BEldmTF's first element to EVOD's last).

#include "data/program_data.hpp"
#include "data/table_memory.hpp"
#include "data/tables.hpp"

#include <catch2/catch_test_macros.hpp>

#include <bit>
#include <cstdint>
#include <stdexcept>

namespace {

using gef::data::MassTable;
using gef::data::read_mass_table;
using gef::data::TableSet;

TableSet const& jeff33() {
    static TableSet const tables =
        gef::data::load_tables(gef::data::ProgramData(gef::data::NuclideData::Jeff33));
    return tables;
}

std::uint32_t bits(float x) {
    return std::bit_cast<std::uint32_t>(x);
}

} // namespace

TEST_CASE("data: mass-table reads inside the bounds return the element", "[T1][data]") {
    TableSet const& t = jeff33();
    CHECK(bits(read_mass_table(t, MassTable::BeExp, 146, 92)) == bits(t.be_exp(146, 92)));
    CHECK(bits(read_mass_table(t, MassTable::DefoTab, 236, 136)) == bits(t.defo_tab(236, 136)));
    CHECK(bits(read_mass_table(t, MassTable::ShellMo, 0, 0)) == bits(t.shell_mo(0, 0)));
}

TEST_CASE("data: mass-table reads past the bounds read the next table, as GEF does", "[T1][data]") {
    TableSet const& t = jeff33();
    // AME2020(82, 300) at GEF.bas:16253: BEexp(218, 82) lies in DEFOtab (its element (14, 78)).
    CHECK(bits(read_mass_table(t, MassTable::BeExp, 218, 82)) == 0x00000000U);
    // BEldmTF(218, 82) lies in BEexp (element (14, 78)), which holds the fill value -1.E11.
    CHECK(bits(read_mass_table(t, MassTable::BeldmTf, 218, 82)) == 0xD1BA43B7U);
    // BEldmTF(204, 4) is BEexp(0, 0); DEFOtab(237, 3) is ShellMO(0, 0).
    CHECK(bits(read_mass_table(t, MassTable::BeldmTf, 204, 4)) == bits(t.be_exp(0, 0)));
    CHECK(bits(read_mass_table(t, MassTable::DefoTab, 237, 3)) == bits(t.shell_mo(0, 0)));
    // Reads that land on filled elements, so a wrong row/column split of the landing offset
    // fails: U-238 (N 146, Z 92) in the next table, and a column past 136 within BEexp itself.
    CHECK(bits(read_mass_table(t, MassTable::BeldmTf, 350, 96)) == 0xC4E13613U); // BEexp(146, 92)
    CHECK(bits(read_mass_table(t, MassTable::BeExp, 350, 96)) == 0x3E5C28F6U);   // DEFOtab(146, 92)
    CHECK(bits(read_mass_table(t, MassTable::DefoTab, 383, 95)) == 0xBFA28F5CU); // ShellMO(146, 92)
    CHECK(bits(read_mass_table(t, MassTable::BeExp, 145, 229)) == 0xC4E13613U);  // BEexp(146, 92)
}

TEST_CASE("data: mass-table reads between two tables read the malloc chunk header", "[T1][data]") {
    TableSet const& t = jeff33();
    // After BEexp: 8 zero bytes, then DEFOtab's chunk size word 0x1FB61 (129888 | PREV_INUSE).
    CHECK(bits(read_mass_table(t, MassTable::BeExp, 204, 0)) == 0x00000000U);
    CHECK(bits(read_mass_table(t, MassTable::BeExp, 204, 1)) == 0x00000000U);
    CHECK(bits(read_mass_table(t, MassTable::BeExp, 204, 2)) == 0x0001FB61U);
    CHECK(bits(read_mass_table(t, MassTable::BeExp, 204, 3)) == 0x00000000U);
    // After DEFOtab (129876 bytes in a 129888-byte chunk): 4 zero bytes, then ShellMO's size word.
    CHECK(bits(read_mass_table(t, MassTable::DefoTab, 237, 0)) == 0x00000000U);
    CHECK(bits(read_mass_table(t, MassTable::DefoTab, 237, 1)) == 0x0001B4C1U);
    CHECK(bits(read_mass_table(t, MassTable::DefoTab, 237, 2)) == 0x00000000U);
    // After BEldmTF and after ShellMO: 8 zero bytes, then a 204 x 137 table's size word 0x1B4C1.
    CHECK(bits(read_mass_table(t, MassTable::BeldmTf, 204, 2)) == 0x0001B4C1U);
    CHECK(bits(read_mass_table(t, MassTable::ShellMo, 204, 2)) == 0x0001B4C1U);
}

TEST_CASE("data: mass-table reads before BEldmTF or after EVOD throw", "[T1][data]") {
    TableSet const& t = jeff33();
    // Neither memory is known: the chunk before BEldmTF and the one after EVOD hold other data.
    CHECK_THROWS_AS(read_mass_table(t, MassTable::BeldmTf, -1, 136), std::out_of_range);
    CHECK_THROWS_AS(read_mass_table(t, MassTable::Evod, 204, 0), std::out_of_range);
    CHECK(bits(read_mass_table(t, MassTable::BeldmTf, 0, 0)) == bits(t.beldm_tf(0, 0)));
    CHECK(bits(read_mass_table(t, MassTable::Evod, 203, 136)) == bits(t.evod(203, 136)));
}

TEST_CASE("data: with fix_table_overrun a mass-table read outside the bounds throws",
          "[T1][data]") {
    TableSet t = jeff33();
    t.fix_table_overrun = true;
    CHECK_THROWS_AS(read_mass_table(t, MassTable::BeExp, 218, 82), std::out_of_range);
    CHECK_THROWS_AS(read_mass_table(t, MassTable::BeExp, 204, 2), std::out_of_range);
    CHECK(bits(read_mass_table(t, MassTable::BeExp, 146, 92)) == bits(t.be_exp(146, 92)));
}
