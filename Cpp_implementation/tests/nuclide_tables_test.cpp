// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for gef::data::load_nuclide_tables (NucTab, MAT_for_ISO, Isotab; M4.3) against the T0
// probe dumps of the BASIC programs. Each variable's fingerprint must match the committed one
// (m4-t0-<variant>, T0.txt). NUBASE 2020 stops in its loader (QUIRKS Q-032).

#include "data/nuclide_tables.hpp"
#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "support/golden.hpp"
#include "support/probe_dump.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <array>
#include <cstddef>
#include <map>
#include <string>
#include <string_view>
#include <vector>

namespace {

using gef::data::GefStopped;
using gef::data::IsoProp;
using gef::data::load_nuclide_tables;
using gef::data::NuclideData;
using gef::data::NucProp;
using gef::data::ProgramData;
using gef::data::TableSet;
using gef::test::ProbeDump;
using gef::test::ProbeFingerprint;

// The variables this loader owns, in the order of the dump (harness_probe_t0.bi).
ProbeDump dump_nuclide(TableSet const& t, std::string_view n_mat_max_label) {
    ProbeDump dump;
    dump.scalar(n_mat_max_label, t.n_mat_max);
    dump.scalar("N_ISO_TOT", t.n_iso_tot);
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
    return dump;
}

constexpr std::array<std::string_view, 20> nuclide_names{
    "N_MAT_MAX",    "N_ISO_TOT",    "MAT_for_ISO",  "NucTab.I_Z",      "NucTab.I_A",
    "NucTab.I_ISO", "NucTab.R_SPI", "NucTab.I_PAR", "NucTab.R_AWR",    "NucTab.R_EXC",
    "Isotab.I_MAT", "Isotab.I_Z",   "Isotab.I_A",   "Isotab.N_STATES", "Isotab.I_ISO",
    "Isotab.R_SPI", "Isotab.I_PAR", "Isotab.R_EXC", "Isotab.R_Lim",    "Isotab.R_Prob",
};

// The first line of `name` in the BASIC dump that differs from ours (INFO aid for debugging).
void report_first_difference(std::string_view id, std::string_view name, ProbeDump const& dump) {
    auto const store = gef::test::store_file(id, "work/probes/T0.txt");
    if (!store) {
        return;
    }
    std::string const prefix = "T0 - " + std::string{name} + " ";
    std::vector<std::string> theirs;
    for (std::string const& line : gef::test::read_lines(*store)) {
        if (line.starts_with(prefix)) {
            theirs.push_back(line);
        }
    }
    std::vector<std::string> const& ours = dump.lines(name);
    for (std::size_t k = 0; k < std::max(ours.size(), theirs.size()); ++k) {
        std::string const& a = k < ours.size() ? ours.at(k) : std::string{"<missing>"};
        std::string const& b = k < theirs.size() ? theirs.at(k) : std::string{"<missing>"};
        if (a != b) {
            INFO("first differing line of " << name << " (line " << k << "): BASIC `" << b
                                            << "`, C++ `" << a << "`");
            return;
        }
    }
}

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
    ProgramData const data{variant};
    TableSet tables;
    load_nuclide_tables(data, tables);
    ProbeDump const dump = dump_nuclide(tables, golden_name(variant, "N_MAT_MAX"));

    std::map<std::string, ProbeFingerprint, std::less<>> const expected =
        gef::test::read_fingerprints(id, "T0.txt");
    for (std::string_view name : nuclide_names) {
        DYNAMIC_SECTION(name) {
            std::string const label = golden_name(variant, name);
            auto const it = expected.find(label);
            REQUIRE(it != expected.end());
            ProbeFingerprint const got = dump.fingerprint(label);
            CAPTURE(got.lines, it->second.lines);
            if (got != it->second) {
                report_first_difference(id, label, dump);
            }
            CHECK(got == it->second);
        }
    }
}

} // namespace

TEST_CASE("NucTab, MAT_for_ISO and Isotab match the BASIC dump, jeff33", "[T0][data]") {
    check_variant(NuclideData::Jeff33, "m4-t0-jeff33");
}

TEST_CASE("NucTab, MAT_for_ISO and Isotab match the BASIC dump, jeff311", "[T0][data]") {
    check_variant(NuclideData::Jeff311, "m4-t0-jeff311");
}

TEST_CASE("NucTab, MAT_for_ISO and Isotab match the BASIC dump, nubase2016", "[T0][data]") {
    check_variant(NuclideData::Nubase2016, "m4-t0-nubase2016");
}

TEST_CASE("NucTab, MAT_for_ISO and Isotab match the BASIC dump, legacy-x", "[T0][data]") {
    check_variant(NuclideData::LegacyX, "m4-t0-legacy-x");
}

TEST_CASE("NucTab, MAT_for_ISO and Isotab match the BASIC dump, legacy-mf", "[T0][data]") {
    check_variant(NuclideData::LegacyMf, "m4-t0-legacy-mf");
}

TEST_CASE("NucTab, MAT_for_ISO and Isotab match the BASIC dump, legacy-f", "[T0][data]") {
    check_variant(NuclideData::LegacyF, "m4-t0-legacy-f");
}

TEST_CASE("NUBASE 2020 loader stops with the BASIC stop lines (Q-032)", "[T0][data]") {
    ProgramData const data{NuclideData::Nubase2020};
    TableSet tables;
    std::vector<std::string> stop_lines;
    try {
        load_nuclide_tables(data, tables);
        FAIL("the NUBASE 2020 loader must stop");
    } catch (GefStopped const& stop) {
        stop_lines = stop.console_lines();
    }
    REQUIRE(stop_lines.size() >= 2);
    CHECK(stop_lines.at(stop_lines.size() - 2) == "<E> Error in NucProp");
    CHECK(stop_lines.back() == "GEF stopped.");
    if (auto const store = gef::test::store_file("m4-t0-nubase2020", "stdout.log")) {
        std::vector<std::string> expected;
        for (std::string const& line : gef::test::read_lines(*store)) {
            if (line.starts_with("<E>") || line == "GEF stopped.") {
                expected.push_back(line);
            }
        }
        CHECK(stop_lines == expected);
    }
}

TEST_CASE("N_MAT_MAX too large message, jeff311", "[T0][data]") {
    ProgramData const data{NuclideData::Jeff311};
    TableSet tables;
    load_nuclide_tables(data, tables);
    std::string expected = "<E> Nucprop: N_MAT_MAX too large, should be  3878";
    if (auto const store = gef::test::store_file("m4-t0-jeff311", "stdout.log")) {
        for (std::string const& line : gef::test::read_lines(*store)) {
            if (line.starts_with("<E> Nucprop: N_MAT_MAX too large")) {
                expected = line;
            }
        }
    }
    CHECK(tables.console == std::vector<std::string>{expected});
}

TEST_CASE("loaders of the other certified variants print nothing to the console", "[T0][data]") {
    for (NuclideData const variant :
         {NuclideData::Jeff33, NuclideData::Nubase2016, NuclideData::LegacyX, NuclideData::LegacyMf,
          NuclideData::LegacyF}) {
        ProgramData const data{variant};
        TableSet tables;
        load_nuclide_tables(data, tables);
        CHECK(tables.console.empty());
    }
}
