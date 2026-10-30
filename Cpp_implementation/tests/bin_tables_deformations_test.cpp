// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// The table builder's first blocks (GEF.bas:5584-6062: bin entry, mode centres, deformations,
// mean Z as a function of A, Z-A relations, curvatures) run from every P3in record of the M7
// captures and compared with the P3 record of the same bin, per MILESTONE_7_PLAN.md D9: every
// P3 variable whose last writer in a bin is one of these blocks, and every variable the builder
// does not write, must equal BASIC's bits.

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "fbrt/text.hpp"
#include "params/parameters.hpp"
#include "physics/masses.hpp"
#include "support/bin_tables_p3.hpp"
#include "support/golden.hpp"
#include "support/probe_dump.hpp"
#include "support/probe_records.hpp"
#include "tables/bin_plan.hpp"
#include "tables/builder.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <set>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace {

// Elements of `name` that a later block writes last in every bin, so that M7.1 cannot be
// compared on them: Beta(1,1,I) and Edefo(1,1,I) for I = 10 .. I_Z_CN - 10 (GEF.bas:6142-6151,
// M7.2) and Zshift(J,K,I) for J = 1 .. 5, K = 1 .. 2, I = 10 .. I_A_CN - 10 (6788-6795, M7.3).
bool later_element(std::string_view name, std::array<std::int64_t, 3> const& index,
                   std::int64_t i_z_cn, std::int64_t i_a_cn) {
    if (name == "beta" || name == "Edefo") {
        return index.at(0) == 1 && index.at(1) == 1 && index.at(2) >= 10 &&
               index.at(2) <= i_z_cn - 10;
    }
    if (name == "Zshift") {
        return index.at(0) >= 1 && index.at(0) <= 5 && index.at(2) >= 10 &&
               index.at(2) <= i_a_cn - 10;
    }
    return false;
}

// The bit patterns of a C++ array against the array of BASIC's record (same bounds), except, with
// `partial`, the elements later blocks write. Returns a description of the first difference.
std::string array_difference(gef::fb::Array<float, 3> const& cpp, gef::test::ProbeRecord const& out,
                             std::string_view name, bool partial, std::int64_t i_z_cn,
                             std::int64_t i_a_cn) {
    gef::fb::Array<float, 3> const basic = gef::test::read_single_array<3>(out, name);
    for (std::int64_t d = 1; d <= 3; ++d) {
        if (cpp.lbound(d) != basic.lbound(d) || cpp.ubound(d) != basic.ubound(d)) {
            return "bounds differ in dimension " + std::to_string(d);
        }
    }
    for (std::int64_t i = cpp.lbound(1); i <= cpp.ubound(1); ++i) {
        for (std::int64_t j = cpp.lbound(2); j <= cpp.ubound(2); ++j) {
            for (std::int64_t k = cpp.lbound(3); k <= cpp.ubound(3); ++k) {
                if (partial && later_element(name, {i, j, k}, i_z_cn, i_a_cn)) {
                    continue;
                }
                auto const want = std::bit_cast<std::uint32_t>(basic(i, j, k));
                auto const got = std::bit_cast<std::uint32_t>(cpp(i, j, k));
                if (want != got) {
                    return "element " + std::to_string(i) + "," + std::to_string(j) + "," +
                           std::to_string(k) + ": C++ " + std::to_string(got) + ", BASIC " +
                           std::to_string(want);
                }
            }
        }
    }
    return {};
}

// GEF.bas:16628 `Print #f,"Beta_Equi not converged: ",Z1,N` on the console (f = 0).
std::vector<std::string>
beta_equi_lines(std::vector<gef::tables::BetaEquiMessage> const& messages) {
    gef::fb::PrintFile console = gef::fb::PrintFile::console();
    for (gef::tables::BetaEquiMessage const& m : messages) {
        console.print("Beta_Equi not converged: ", gef::fb::PrintEnd::Pad);
        console.print(m.z1, gef::fb::PrintEnd::Pad);
        console.print(m.n, gef::fb::PrintEnd::Newline);
    }
    std::vector<std::string> lines;
    std::string const& text = console.text();
    for (std::size_t start = 0; start < text.size();) {
        std::size_t const end = text.find('\n', start);
        lines.push_back(text.substr(start, end - start));
        start = end + 1;
    }
    return lines;
}

} // namespace

TEST_CASE("tables: the later writers of beta, Edefo and Zshift are those the M7.1 test excludes",
          "[unit][tables]") {
    auto const& map = gef::test::last_writer_map();
    auto later = [&](std::string_view name) {
        std::vector<std::string> out;
        for (std::string const& writer : map.at(std::string(name)).writers) {
            if (!writer.contains(":M7.1")) {
                out.push_back(writer);
            }
        }
        return out;
    };
    CHECK(later("beta") ==
          std::vector<std::string>{"6146:M7.2=Beta(1,1,I)", "6148:M7.2=Beta(1,1,I)"});
    CHECK(later("Edefo") == std::vector<std::string>{"6150:M7.2=Edefo(1,1,I)"});
    CHECK(later("Zshift") == std::vector<std::string>{"6792:M7.3=Zshift(J,K,I)"});
}

namespace {

// D9: the variables M7.1 writes last, and those no block writes (BASIC's P3 equals its P3in).
std::set<std::string, std::less<>> whole_variables() {
    auto const& registered = gef::test::builder_variable_names();
    std::set<std::string, std::less<>> whole;
    for (auto const& [name, row] : gef::test::last_writer_map()) {
        if (row.part == "M7.1") {
            INFO("variable " << name);
            REQUIRE(registered.contains(name));
            whole.insert(name);
        } else if (row.part == "input" && registered.contains(name)) {
            whole.insert(name);
        }
    }
    return whole;
}

// One bin: the C++ from its P3in record against its P3 record. Returns the Beta_Equi messages.
std::vector<gef::tables::BetaEquiMessage>
check_bin(gef::test::ProbeRecord const& in, gef::test::ProbeRecord const& out,
          std::set<std::string, std::less<>> const& whole) {
    gef::test::BuilderCase c;
    gef::test::load_builder_case(in, c);
    // D7: the builder's temporaries and the global Z carry nothing into a bin; poisoned, a read
    // before write would show in the comparison.
    float const poison = std::numeric_limits<float>::quiet_NaN();
    c.temporaries = gef::tables::Temporaries{.rbeta = poison,
                                             .beta1 = poison,
                                             .beta2 = poison,
                                             .beta1_opt = poison,
                                             .beta2_opt = poison,
                                             .beta1_prev = poison,
                                             .beta2_prev = poison,
                                             .z1 = poison,
                                             .z2 = poison,
                                             .iz1 = -1000000,
                                             .iz2 = -1000000,
                                             .a1 = poison,
                                             .a2 = poison,
                                             .e_defo = poison};
    c.z = poison;
    gef::fb::PrintFile console = gef::fb::PrintFile::console();
    gef::tables::enter_bin(c.bin, c.params.emode, c.spin_cn, console);
    std::vector<gef::tables::BetaEquiMessage> messages;
    gef::tables::mode_centres_and_deformations(c.bin, c.working, c.params, c.spin_cn, c.tables,
                                               c.temporaries, c.z, messages);
    // Scalars as P3 lines; the four arrays element by element (bit patterns).
    gef::test::ProbeDump const dump =
        gef::test::dump_builder_case(c, "P3", out.context, /*with_arrays=*/false);
    for (std::string const& name : whole) {
        if (name != "Zmean") {
            INFO("variable " << name);
            CHECK(dump.lines(name) == out.lines(name));
        }
    }
    std::string const zmean = array_difference(c.tables.zmean, out, "Zmean", false, 0, 0);
    INFO("Zmean: " << zmean);
    CHECK(zmean.empty());
    for (auto const& [name, array] :
         {std::pair<std::string_view, gef::fb::Array<float, 3> const*>{"beta", &c.tables.beta},
          {"Edefo", &c.tables.edefo},
          {"Zshift", &c.tables.zshift}}) {
        INFO("variable " << name << " (elements M7.1 writes last)");
        std::string const difference =
            array_difference(*array, out, name, true, c.bin.i_z_cn, c.bin.i_a_cn);
        INFO(difference);
        CHECK(difference.empty());
    }
    return messages;
}

// QUIRK(Q-041): BASIC printed the builder's Beta_Equi messages to the console (f = 0 in every
// P3in record of the captures that reach it), all of them in a traced bin.
void check_beta_equi(std::string const& capture,
                     std::vector<gef::tables::BetaEquiMessage> const& messages) {
    std::vector<std::string> printed;
    for (std::string const& line :
         gef::test::read_lines(gef::test::capture_file(capture, "stdout.log"))) {
        if (line.starts_with("Beta_Equi not converged")) {
            printed.push_back(line);
        }
    }
    CHECK(beta_equi_lines(messages) == printed);
}

// Every record pair of one capture; returns the number of pairs.
std::size_t check_capture(std::string const& id, std::set<std::string, std::less<>> const& whole) {
    std::string const capture = "m7-p3-" + id;
    INFO("capture " << capture);
    auto const& registered = gef::test::builder_variable_names();
    gef::test::ProbeRecordReader p3in(gef::test::capture_file(capture, "work/probes/P3in.txt"),
                                      registered);
    gef::test::ProbeRecordReader p3(gef::test::capture_file(capture, "work/probes/P3.txt"),
                                    registered);
    std::vector<gef::tables::BetaEquiMessage> messages;
    gef::test::ProbeRecord in;
    gef::test::ProbeRecord out;
    std::size_t records = 0;
    while (p3in.next(in)) {
        REQUIRE(p3.next(out));
        REQUIRE(in.context == out.context);
        ++records;
        INFO("record " << out.context);
        std::vector<gef::tables::BetaEquiMessage> const bin_messages = check_bin(in, out, whole);
        messages.insert(messages.end(), bin_messages.begin(), bin_messages.end());
    }
    CHECK_FALSE(p3.next(out));
    check_beta_equi(capture, messages);
    if (id == "fm212-sf" || id == "ds270-sf") {
        CHECK_FALSE(messages.empty());
    }
    return records;
}

} // namespace

TEST_CASE("tables: mode centres and deformations equal BASIC from P3in", "[T1][tables]") {
    std::set<std::string, std::less<>> const whole = whole_variables();
    std::size_t captures = 0;
    std::size_t records = 0;
    for (std::string const& id : gef::test::m7_corpus_ids()) {
        if (gef::test::store_file("m7-p3-" + id, "work/probes/P3in.txt")) {
            ++captures;
            records += check_capture(id, whole);
        }
    }
    if (captures == 0) {
        SKIP("the reference store has no M7 capture");
    }
    CHECK(captures == gef::test::m7_corpus_ids().size());
    CHECK(records > 0);
}

TEST_CASE("tables: a CN with A above 360 stops at the bound of Zmean and Zshift",
          "[unit][tables]") {
    // QUIRK(Q-061): U_Valid admits A/Z up to 289/90, so A up to 385 at Z 120; the Z(A) loops
    // index Zmean and Zshift up to A_CN - 10, beyond their bound 350 from A_CN 361 on (BASIC writes
    // past the arrays and its run dies, capture m7-q061-z120a385).
    gef::data::TableSet const tables =
        gef::data::load_tables(gef::data::ProgramData(gef::data::NuclideData::Jeff33));
    gef::params::Parameters p;
    gef::params::load_parameters_bas(p);
    gef::tables::WorkingParameters w;
    gef::tables::assign_nominal(w, p);
    std::vector<gef::tables::BetaEquiMessage> messages;
    auto build = [&](std::int64_t z, std::int64_t a) {
        REQUIRE(gef::physics::u_valid(tables, z, a) == 1);
        gef::tables::BinInput bin;
        bin.i_z_cn = z;
        bin.i_a_cn = a;
        gef::tables::BinTables t;
        gef::tables::Temporaries tmp;
        float global_z = 0.0F;
        messages.clear();
        gef::tables::mode_centres_and_deformations(bin, w, p, 0.0F, t, tmp, global_z, messages);
    };
    CHECK_NOTHROW(build(118, 360));
    CHECK_THROWS_AS(build(118, 361), std::out_of_range);
    CHECK_THROWS_AS(build(120, 385), std::out_of_range);
    // The messages of the deformation loop before the stop stay with the caller: BASIC printed
    // `Beta_Equi not converged:     10            1001` before it (capture m7-q061-z120a385).
    CHECK(messages == std::vector<gef::tables::BetaEquiMessage>{{.z1 = 10.0F, .n = 1001}});
}
