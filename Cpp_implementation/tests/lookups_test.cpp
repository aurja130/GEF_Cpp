// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// M4.6: the nuclide lookup functions against the harness patch "lookups" (harness/patches/
// lookups.patch): every certified nuclide-data variant, the same (Z, A) grid in the same order
// from a fresh ctl/, compared through whole-file fingerprints (goldens m4-lookups-<variant>);
// with the reference store, the console lines are also found in the run's stdout.log.

#include "data/lookups.hpp"
#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "fbrt/text.hpp"
#include "support/golden.hpp"
#include "support/probe_dump.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <array>
#include <bit>
#include <cstdint>
#include <format>
#include <string>
#include <string_view>
#include <vector>

namespace {

using gef::data::NuclideData;
using gef::data::TableSet;

// FreeBASIC `Str` of an Integer (no leading blank), as `&` concatenates it.
std::string str(std::int64_t x) {
    return gef::fb::str(x);
}

// `Hex(*Cast(ULong Ptr, @x), 8)`.
std::string hex8(float x) {
    return std::format("{:08X}", std::bit_cast<std::uint32_t>(x));
}

// The A range of the grid for every Z 0..120 (harness_lookups.bi).
struct Band {
    std::int64_t lo = 0;
    std::int64_t hi = 0;
};

std::array<Band, 121> grid(TableSet const& t) {
    std::array<std::int64_t, 121> amin{};
    std::array<std::int64_t, 121> amax{};
    amin.fill(-1);
    amax.fill(-1);
    for (std::int64_t i = t.nuc_tab.lbound(); i <= t.nuc_tab.ubound(); ++i) {
        std::int64_t const z = t.nuc_tab(i).i_z;
        std::int64_t const a = t.nuc_tab(i).i_a;
        if (z >= 0 && z <= 120) {
            auto const k = static_cast<std::size_t>(z);
            if (amin.at(k) < 0 || a < amin.at(k)) {
                amin.at(k) = a;
            }
            amax.at(k) = std::max(amax.at(k), a);
        }
    }
    std::array<Band, 121> bands{};
    for (std::size_t z = 0; z <= 120; ++z) {
        if (amax.at(z) >= 0) {
            bands.at(z) = {.lo = std::max<std::int64_t>(amin.at(z) - 3, 0), .hi = amax.at(z) + 3};
        } else {
            auto const centre = static_cast<std::int64_t>(2.5 * static_cast<double>(z));
            bands.at(z) = {.lo = std::max<std::int64_t>(centre - 2, 0), .hi = centre + 2};
        }
    }
    return bands;
}

struct Run {
    std::vector<std::string> lookups;
    std::vector<std::string> branch;
    std::vector<std::string> console;
    gef::data::MatNumberState state;
};

// harness_lookups.bi and harness_lookups_branch.bi, statement by statement.
Run evaluate(TableSet const& t) {
    Run run;
    auto const bands = grid(t);
    std::int64_t const ub = t.nuc_tab.ubound();
    for (std::int64_t z = 0; z <= 120; ++z) {
        Band const band = bands.at(static_cast<std::size_t>(z));
        for (std::int64_t a = band.lo; a <= band.hi; ++a) {
            std::int64_t const imat = gef::data::i_mat_endf(t, z, a, run.state, run.console);
            float const awr = gef::data::r_awr_endf(t, z, a, run.state, run.console);
            std::int64_t const iso = gef::data::iso_for_za(t, z, a);
            std::int64_t const nst = gef::data::nstates_for_za(t, z, a);
            std::string niso = "-";
            if (imat <= ub - 6 || imat > ub) {
                niso = str(gef::data::n_iso_mat(t, imat));
            }
            run.lookups.push_back("N " + str(z) + " " + str(a) + " " + str(imat) + " " + hex8(awr) +
                                  " " + str(iso) + " " + str(nst) + " " + niso + " " +
                                  str(gef::data::iso_for_mat(t, imat)));
        }
    }
    for (std::int64_t m = t.nuc_tab.lbound(); m <= ub - 6; ++m) {
        run.lookups.push_back("M " + str(m) + " " + str(gef::data::n_iso_mat(t, m)) + " " +
                              str(gef::data::iso_for_mat(t, m)));
    }
    for (std::int64_t z = 0; z <= 120; ++z) {
        Band const band = bands.at(static_cast<std::size_t>(z));
        for (std::int64_t a = band.lo; a <= band.hi; ++a) {
            for (std::int64_t iso = 0; iso <= 3; ++iso) {
                run.branch.push_back("B " + str(z) + " " + str(a) + " " + str(iso) + " " +
                                     str(gef::data::ibranch_for_zai(t, z, a, iso)));
            }
        }
    }
    return run;
}

std::vector<std::string> split(std::string const& text) {
    std::vector<std::string> lines;
    std::size_t start = 0;
    while (start < text.size()) {
        std::size_t const end = text.find('\n', start);
        lines.push_back(text.substr(start, end - start));
        start = end + 1;
    }
    return lines;
}

void check_variant(NuclideData variant, std::string_view golden, bool imatmax_file) {
    INFO(golden);
    TableSet const tables = gef::data::load_tables(gef::data::ProgramData(variant));
    Run const run = evaluate(tables);
    auto const expected = gef::test::read_fingerprints(golden, "files.txt");
    CHECK(gef::test::fingerprint_lines(run.lookups) == expected.at("work/probes/lookups.txt"));
    CHECK(gef::test::fingerprint_lines(run.branch) ==
          expected.at("work/probes/lookups_branch.txt"));
    REQUIRE(run.state.imatmax_ctl.has_value() == imatmax_file);
    if (run.state.imatmax_ctl.has_value()) {
        CHECK(gef::test::fingerprint_lines(split(*run.state.imatmax_ctl)) ==
              expected.at("work/ctl/IMATmax.ctl"));
    }

    // The console lines of the lookups, one block in the run's stdout.log.
    auto const stdout_log = gef::test::store_file(golden, "stdout.log");
    if (!stdout_log) {
        SKIP("reference store absent: console not compared");
    }
    auto const lines = gef::test::read_lines(*stdout_log);
    if (run.console.empty()) {
        CHECK(std::ranges::find(lines, "    Please extend table!") == lines.end());
        return;
    }
    auto const found = std::ranges::search(lines, run.console);
    CHECK(!found.empty());
}

} // namespace

TEST_CASE("Lookups of JEFF-3.3 equal the BASIC run", "[data][T1]") {
    check_variant(NuclideData::Jeff33, "m4-lookups-jeff33", true);
}

TEST_CASE("Lookups of JEFF-3.1.1 equal the BASIC run", "[data][T1]") {
    check_variant(NuclideData::Jeff311, "m4-lookups-jeff311", false);
}

TEST_CASE("Lookups of NUBASE 2016 equal the BASIC run", "[data][T1]") {
    check_variant(NuclideData::Nubase2016, "m4-lookups-nubase2016", true);
}

TEST_CASE("Lookups of NucPropx equal the BASIC run", "[data][T1]") {
    check_variant(NuclideData::LegacyX, "m4-lookups-legacy-x", false);
}

TEST_CASE("Lookups of NucPropmf equal the BASIC run", "[data][T1]") {
    check_variant(NuclideData::LegacyMf, "m4-lookups-legacy-mf", false);
}

TEST_CASE("Lookups of NucPropf equal the BASIC run", "[data][T1]") {
    check_variant(NuclideData::LegacyF, "m4-lookups-legacy-f", false);
}
