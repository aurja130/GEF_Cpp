// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// M4.5: the analyzer registry against probe T0 (group "analyzer registry Anl_Par(0..N_Anl)",
// harness/PROBES.md) of every certified nuclide-data variant.

#include "analysis/analyzer_registry.hpp"
#include "support/probe_dump.hpp"

#include <catch2/catch_test_macros.hpp>

#include <cstdint>
#include <string_view>

namespace {

using gef::analysis::AnalyzerAttributes;

} // namespace

TEST_CASE("Analyzer registry equals T0", "[analysis][T0]") {
    gef::analysis::AnalyzerRegistry const reg = gef::analysis::build_analyzer_registry();
    CHECK(reg.anl_par.lbound() == 0);
    CHECK(reg.anl_par.ubound() == 1000);

    // The probe writes entries 0..N_Anl.
    gef::fb::Array<AnalyzerAttributes, 1> dumped({gef::fb::Bounds{0, reg.n_anl}});
    for (std::int64_t i = 0; i <= reg.n_anl; ++i) {
        dumped(i) = reg.anl_par(i);
    }
    gef::test::ProbeDump dump;
    dump.scalar("N_Anl", reg.n_anl);
    dump.field("Anl_Par.C_Name", dumped, [](AnalyzerAttributes const& a) { return a.c_name; });
    dump.field("Anl_Par.C_Title", dumped, [](AnalyzerAttributes const& a) { return a.c_title; });
    dump.field("Anl_Par.C_xaxis", dumped, [](AnalyzerAttributes const& a) { return a.c_xaxis; });
    dump.field("Anl_Par.C_yaxis", dumped, [](AnalyzerAttributes const& a) { return a.c_yaxis; });
    dump.field("Anl_Par.C_Linesymbol", dumped,
               [](AnalyzerAttributes const& a) { return a.c_linesymbol; });
    dump.field("Anl_Par.C_Type", dumped, [](AnalyzerAttributes const& a) { return a.c_type; });
    dump.field("Anl_Par.I_Dim", dumped, [](AnalyzerAttributes const& a) { return a.i_dim; });
    dump.array_field("Anl_Par.R_ALim", dumped,
                     [](AnalyzerAttributes const& a) -> auto const& { return a.r_alim; });

    for (std::string_view const variant : {"m4-t0-jeff33", "m4-t0-jeff311", "m4-t0-nubase2016",
                                           "m4-t0-legacy-x", "m4-t0-legacy-mf", "m4-t0-legacy-f"}) {
        auto const expected = gef::test::read_fingerprints(variant, "T0.txt");
        for (std::string_view const name :
             {"N_Anl", "Anl_Par.C_Name", "Anl_Par.C_Title", "Anl_Par.C_xaxis", "Anl_Par.C_yaxis",
              "Anl_Par.C_Linesymbol", "Anl_Par.C_Type", "Anl_Par.I_Dim", "Anl_Par.R_ALim"}) {
            INFO(variant << " " << name);
            auto const it = expected.find(name);
            REQUIRE(it != expected.end());
            CHECK(dump.fingerprint(name) == it->second);
        }
    }
}
