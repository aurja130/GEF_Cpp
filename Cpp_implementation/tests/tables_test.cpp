// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "support/golden.hpp"
#include "support/probe_dump.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <cstddef>
#include <string>
#include <string_view>

namespace {

using gef::data::BranchRecord;
using gef::data::IsoProp;
using gef::data::NuclideData;
using gef::data::NucProp;
using gef::data::ProgramData;
using gef::data::TableSet;
using gef::test::ProbeDump;

// The T0 dump (harness/patches/probes.patch, harness_probe_t0.bi), variable by variable.
// `n_mat_max_name` is the record label: the legacy files print N_MAT_MAX under its literal value.
ProbeDump dump_t0(TableSet const& t, std::string_view n_mat_max_name) {
    ProbeDump dump;
    dump.scalar(n_mat_max_name, t.n_mat_max);
    dump.scalar("N_ISO_TOT", t.n_iso_tot);
    dump.scalar("Z_min_branching", t.z_min_branching);
    dump.scalar("Z_max_branching", t.z_max_branching);
    dump.scalar("A_max_branching", t.a_max_branching);
    dump.array("BEldmTF", t.beldm_tf);
    dump.array("BEexp", t.be_exp);
    dump.array("DEFOtab", t.defo_tab);
    dump.array("ShellMO", t.shell_mo);
    dump.array("EVOD", t.evod, true);
    dump.array("CElement", t.c_element);
    dump.array("ENfrvar_lim", t.enfrvar_lim);
    dump.array("MAT_for_ISO", t.mat_for_iso);
    dump.field("NucTab.I_Z", t.nuc_tab, [](NucProp const& r) { return r.i_z; });
    dump.field("NucTab.I_A", t.nuc_tab, [](NucProp const& r) { return r.i_a; });
    dump.field("NucTab.I_ISO", t.nuc_tab, [](NucProp const& r) { return r.i_iso; });
    dump.field("NucTab.R_SPI", t.nuc_tab, [](NucProp const& r) { return r.r_spi; });
    dump.field("NucTab.I_PAR", t.nuc_tab, [](NucProp const& r) { return r.i_par; });
    dump.field("NucTab.R_AWR", t.nuc_tab, [](NucProp const& r) { return r.r_awr; });
    dump.field("NucTab.R_EXC", t.nuc_tab, [](NucProp const& r) { return r.r_exc; });
    dump.field("Isotab.I_MAT", t.isotab, [](IsoProp const& r) { return r.i_mat; });
    dump.field("Isotab.I_Z", t.isotab, [](IsoProp const& r) { return r.i_z; });
    dump.field("Isotab.I_A", t.isotab, [](IsoProp const& r) { return r.i_a; });
    dump.field("Isotab.N_STATES", t.isotab, [](IsoProp const& r) { return r.n_states; });
    dump.array_field("Isotab.I_ISO", t.isotab,
                     [](IsoProp const& r) -> auto const& { return r.i_iso; });
    dump.array_field("Isotab.R_SPI", t.isotab,
                     [](IsoProp const& r) -> auto const& { return r.r_spi; });
    dump.array_field("Isotab.I_PAR", t.isotab,
                     [](IsoProp const& r) -> auto const& { return r.i_par; });
    dump.array_field("Isotab.R_EXC", t.isotab,
                     [](IsoProp const& r) -> auto const& { return r.r_exc; });
    dump.array_field("Isotab.R_Lim", t.isotab,
                     [](IsoProp const& r) -> auto const& { return r.r_lim; });
    dump.array_field("Isotab.R_Prob", t.isotab,
                     [](IsoProp const& r) -> auto const& { return r.r_prob; });
    dump.field("BranchData.I_Z", t.branch_data, [](BranchRecord const& r) { return r.i_z; });
    dump.field("BranchData.I_A", t.branch_data, [](BranchRecord const& r) { return r.i_a; });
    dump.field("BranchData.I_ISO", t.branch_data, [](BranchRecord const& r) { return r.i_iso; });
    dump.field("BranchData.R_Life", t.branch_data, [](BranchRecord const& r) { return r.r_life; });
    dump.field("BranchData.R_beta", t.branch_data, [](BranchRecord const& r) { return r.r_beta; });
    dump.field("BranchData.R_beta_plus", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_plus; });
    dump.field("BranchData.R_beta_n", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_n; });
    dump.field("BranchData.R_beta_2n", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_2n; });
    dump.field("BranchData.R_beta_p", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_p; });
    dump.field("BranchData.R_beta_2p", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_2p; });
    dump.field("BranchData.R_IT", t.branch_data, [](BranchRecord const& r) { return r.r_it; });
    dump.field("BranchData.R_alpha", t.branch_data,
               [](BranchRecord const& r) { return r.r_alpha; });
    dump.field("BranchData.R_beta_m", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_m; });
    dump.field("BranchData.R_beta_plus_m", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_plus_m; });
    dump.field("BranchData.R_beta_n_m", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_n_m; });
    dump.field("BranchData.R_beta_2n_m", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_2n_m; });
    dump.field("BranchData.R_beta_p_m", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_p_m; });
    dump.field("BranchData.R_beta_2p_m", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_2p_m; });
    dump.field("BranchData.R_IT_m", t.branch_data, [](BranchRecord const& r) { return r.r_it_m; });
    dump.field("BranchData.R_alpha_m", t.branch_data,
               [](BranchRecord const& r) { return r.r_alpha_m; });
    dump.field("BranchData.R_beta_mm", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_mm; });
    dump.field("BranchData.R_beta_plus_mm", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_plus_mm; });
    dump.field("BranchData.R_beta_n_mm", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_n_mm; });
    dump.field("BranchData.R_beta_2n_mm", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_2n_mm; });
    dump.field("BranchData.R_beta_p_mm", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_p_mm; });
    dump.field("BranchData.R_beta_2p_mm", t.branch_data,
               [](BranchRecord const& r) { return r.r_beta_2p_mm; });
    dump.field("BranchData.R_IT_mm", t.branch_data,
               [](BranchRecord const& r) { return r.r_it_mm; });
    dump.field("BranchData.R_alpha_mm", t.branch_data,
               [](BranchRecord const& r) { return r.r_alpha_mm; });
    dump.array("INlast", t.in_last);
    return dump;
}

// Every T0 variable, in the order of the dump; N_MAT_MAX is the label `golden_name` gives it.
constexpr auto t0_names = std::to_array<std::string_view>({"N_MAT_MAX",
                                                           "N_ISO_TOT",
                                                           "Z_min_branching",
                                                           "Z_max_branching",
                                                           "A_max_branching",
                                                           "BEldmTF",
                                                           "BEexp",
                                                           "DEFOtab",
                                                           "ShellMO",
                                                           "EVOD",
                                                           "CElement",
                                                           "ENfrvar_lim",
                                                           "MAT_for_ISO",
                                                           "NucTab.I_Z",
                                                           "NucTab.I_A",
                                                           "NucTab.I_ISO",
                                                           "NucTab.R_SPI",
                                                           "NucTab.I_PAR",
                                                           "NucTab.R_AWR",
                                                           "NucTab.R_EXC",
                                                           "Isotab.I_MAT",
                                                           "Isotab.I_Z",
                                                           "Isotab.I_A",
                                                           "Isotab.N_STATES",
                                                           "Isotab.I_ISO",
                                                           "Isotab.R_SPI",
                                                           "Isotab.I_PAR",
                                                           "Isotab.R_EXC",
                                                           "Isotab.R_Lim",
                                                           "Isotab.R_Prob",
                                                           "BranchData.I_Z",
                                                           "BranchData.I_A",
                                                           "BranchData.I_ISO",
                                                           "BranchData.R_Life",
                                                           "BranchData.R_beta",
                                                           "BranchData.R_beta_plus",
                                                           "BranchData.R_beta_n",
                                                           "BranchData.R_beta_2n",
                                                           "BranchData.R_beta_p",
                                                           "BranchData.R_beta_2p",
                                                           "BranchData.R_IT",
                                                           "BranchData.R_alpha",
                                                           "BranchData.R_beta_m",
                                                           "BranchData.R_beta_plus_m",
                                                           "BranchData.R_beta_n_m",
                                                           "BranchData.R_beta_2n_m",
                                                           "BranchData.R_beta_p_m",
                                                           "BranchData.R_beta_2p_m",
                                                           "BranchData.R_IT_m",
                                                           "BranchData.R_alpha_m",
                                                           "BranchData.R_beta_mm",
                                                           "BranchData.R_beta_plus_mm",
                                                           "BranchData.R_beta_n_mm",
                                                           "BranchData.R_beta_2n_mm",
                                                           "BranchData.R_beta_p_mm",
                                                           "BranchData.R_beta_2p_mm",
                                                           "BranchData.R_IT_mm",
                                                           "BranchData.R_alpha_mm",
                                                           "INlast"});

// The legacy files define N_MAT_MAX with `#DEFINE`, so the BASIC probe labels that line with the
// literal value (3897, 3889, 3885) instead of the name.
std::string golden_name(NuclideData variant, std::string_view name) {
    if (name != "N_MAT_MAX") {
        return std::string(name);
    }
    switch (variant) {
    case NuclideData::LegacyX:
        return "3897";
    case NuclideData::LegacyMf:
        return "3889";
    case NuclideData::LegacyF:
        return "3885";
    default:
        return std::string(name);
    }
}

void check_variant(NuclideData variant, std::string_view id) {
    INFO("golden " << id);
    TableSet const tables = gef::data::load_tables(ProgramData(variant));
    std::string const n_mat_max = golden_name(variant, "N_MAT_MAX");
    ProbeDump const dump = dump_t0(tables, n_mat_max);
    auto const expected = gef::test::read_fingerprints(id, "T0.txt");
    auto const store = gef::test::store_file(id, "work/probes/T0.txt");

    for (std::string_view name : t0_names) {
        std::string const label = golden_name(variant, name);
        INFO("variable " << label);
        auto const it = expected.find(label);
        REQUIRE(it != expected.end());
        auto const got = dump.fingerprint(label);
        CHECK(got == it->second);
        if (got != it->second && store) {
            // First differing record of this variable against the store's dump.
            std::string first = "(no record)";
            for (auto const& line : gef::test::read_lines(*store)) {
                if (line.contains(label + " ")) {
                    first = line;
                    break;
                }
            }
            INFO("first store line for " << label << ": " << first);
        }
    }
}

} // namespace

TEST_CASE("T0 probe tables match the BASIC dump, jeff33", "[T0][data]") {
    check_variant(NuclideData::Jeff33, "m4-t0-jeff33");
}

TEST_CASE("T0 probe tables match the BASIC dump, jeff311", "[T0][data]") {
    check_variant(NuclideData::Jeff311, "m4-t0-jeff311");
}

TEST_CASE("T0 probe tables match the BASIC dump, nubase2016", "[T0][data]") {
    check_variant(NuclideData::Nubase2016, "m4-t0-nubase2016");
}

TEST_CASE("T0 probe tables match the BASIC dump, legacy-x", "[T0][data]") {
    check_variant(NuclideData::LegacyX, "m4-t0-legacy-x");
}

TEST_CASE("T0 probe tables match the BASIC dump, legacy-mf", "[T0][data]") {
    check_variant(NuclideData::LegacyMf, "m4-t0-legacy-mf");
}

TEST_CASE("T0 probe tables match the BASIC dump, legacy-f", "[T0][data]") {
    check_variant(NuclideData::LegacyF, "m4-t0-legacy-f");
}

TEST_CASE("Branchings print no warning for the shipped data", "[data]") {
    for (NuclideData const variant :
         {NuclideData::Jeff33, NuclideData::Jeff311, NuclideData::Nubase2016, NuclideData::LegacyX,
          NuclideData::LegacyMf, NuclideData::LegacyF}) {
        TableSet const tables = gef::data::load_tables(ProgramData(variant));
        for (std::string const& line : tables.console) {
            INFO("variant " << static_cast<int>(variant) << ": " << line);
            CHECK_FALSE(line.contains("Error in branching table"));
            CHECK_FALSE(line.contains("Error in time unit"));
        }
    }
}
