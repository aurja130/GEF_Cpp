// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// The table builder's blocks through M7.2 (GEF.bas:5584-6560: bin entry, mode centres,
// deformations, mean Z as a function of A, Z-A relations, curvatures, barriers, energies,
// temperatures and widths) run from every P3in record of the M7 captures. Each run is compared
// with the P3 record of the same bin, per MILESTONE_7_PLAN.md D9: every P3 variable whose last
// writer in a bin is one of these blocks, and every variable the builder does not write, must
// equal BASIC's bits.

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "fbrt/array.hpp"
#include "fbrt/text.hpp"
#include "params/parameters.hpp"
#include "support/bin_tables_p3.hpp"
#include "support/golden.hpp"
#include "support/probe_dump.hpp"
#include "support/probe_records.hpp"
#include "tables/bin_plan.hpp"
#include "tables/builder.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <set>
#include <string>
#include <string_view>
#include <tuple>
#include <vector>

namespace {

// Elements of `name` that a block after M7.2 writes last, so that the blocks through M7.2 cannot
// be compared on them: Zshift(J,K,I) for J = 1 .. 5, K = 1 .. 2 and I = 10 .. I_A_CN - 10
// (GEF.bas:6788-6795, M7.3). From A_CN 361 on, I passes the bound 350 and, as in the reference
// binary (QUIRK(Q-061)), the write lands on the element that many places further in storage, so
// the test compares storage positions: Zshift(0 To 5, 1 To 2, 0 To 350) has rows of 351.
template <std::size_t rank>
bool later_element(std::string_view name, std::array<std::int64_t, rank> const& index,
                   std::int64_t i_a_cn) {
    if constexpr (rank == 3) {
        if (name != "Zshift") {
            return false;
        }
        constexpr std::int64_t row = 351;
        std::int64_t const position =
            ((std::get<0>(index) * 2) + (std::get<1>(index) - 1)) * row + std::get<2>(index);
        for (std::int64_t j = 1; j <= 5; ++j) {
            for (std::int64_t k = 1; k <= 2; ++k) {
                std::int64_t const start = ((j * 2) + (k - 1)) * row;
                if (position >= start + 10 && position <= start + i_a_cn - 10) {
                    return true;
                }
            }
        }
    }
    return false;
}

// The indices of every element of `array`, the first index running fastest. Empty when the array
// has no elements.
template <std::size_t rank>
std::vector<std::array<std::int64_t, rank>>
element_indices(gef::fb::Array<float, rank> const& array) {
    std::vector<std::array<std::int64_t, rank>> indices;
    if (array.elements().empty()) {
        return indices;
    }
    std::array<std::int64_t, rank> index{};
    for (std::size_t dimension = 0; dimension < rank; ++dimension) {
        index.at(dimension) = array.lbound(static_cast<std::int64_t>(dimension) + 1);
    }
    while (true) {
        indices.push_back(index);
        std::size_t dimension = 0;
        while (dimension < rank &&
               index.at(dimension) == array.ubound(static_cast<std::int64_t>(dimension) + 1)) {
            index.at(dimension) = array.lbound(static_cast<std::int64_t>(dimension) + 1);
            ++dimension;
        }
        if (dimension == rank) {
            return indices;
        }
        ++index.at(dimension);
    }
}

// An element index as text, for example `3,1,47`.
template <std::size_t rank>
std::string index_text(std::array<std::int64_t, rank> const& index) {
    std::string text;
    for (std::size_t dimension = 0; dimension < rank; ++dimension) {
        if (dimension > 0) {
            text += ",";
        }
        text += std::to_string(index.at(dimension));
    }
    return text;
}

// Compares `cpp` with the array `name` of BASIC's record `out`, element by element and by bit
// pattern; the elements `later_element` names are skipped. Returns the first difference, or an
// empty string when there is none.
template <std::size_t rank>
std::string array_difference(gef::fb::Array<float, rank> const& cpp,
                             gef::test::ProbeRecord const& out, std::string_view name,
                             std::int64_t i_a_cn) {
    gef::fb::Array<float, rank> const basic = gef::test::read_single_array<rank>(out, name);
    for (std::size_t d = 1; d <= rank; ++d) {
        auto const dimension = static_cast<std::int64_t>(d);
        if (cpp.lbound(dimension) != basic.lbound(dimension) ||
            cpp.ubound(dimension) != basic.ubound(dimension)) {
            return "bounds differ in dimension " + std::to_string(dimension);
        }
    }
    for (auto const& index : element_indices(cpp)) {
        if (later_element(name, index, i_a_cn)) {
            continue;
        }
        auto const want = std::bit_cast<std::uint32_t>(std::apply(basic, index));
        auto const got = std::bit_cast<std::uint32_t>(std::apply(cpp, index));
        if (want != got) {
            return "element " + index_text(index) + ": C++ " + std::to_string(got) + ", BASIC " +
                   std::to_string(want);
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

TEST_CASE("tables: the later writers of beta, Edefo and Zshift are those after M7.2",
          "[unit][tables]") {
    auto const& map = gef::test::last_writer_map();
    auto later = [&](std::string_view name) {
        std::vector<std::string> out;
        for (std::string const& writer : map.at(std::string(name)).writers) {
            if (!writer.contains(":M7.1") && !writer.contains(":M7.2")) {
                out.push_back(writer);
            }
        }
        return out;
    };
    CHECK(later("beta").empty());
    CHECK(later("Edefo").empty());
    CHECK(later("Zshift") == std::vector<std::string>{"6792:M7.3=Zshift(J,K,I)"});
}

namespace {

// D9: the variables the blocks through M7.2 write last, and those no block writes (BASIC's P3
// equals its P3in for those).
std::set<std::string, std::less<>> whole_variables() {
    auto const& registered = gef::test::builder_variable_names();
    std::set<std::string, std::less<>> whole;
    for (auto const& [name, row] : gef::test::last_writer_map()) {
        if (row.part == "M7.1" || row.part == "M7.2") {
            INFO("variable " << name);
            REQUIRE(registered.contains(name));
            whole.insert(name);
        } else if (row.part == "input" && registered.contains(name)) {
            whole.insert(name);
        }
    }
    return whole;
}

// The Jeff33 nuclear tables, loaded once for all bins.
gef::data::TableSet const& jeff33() {
    static gef::data::TableSet const tables =
        gef::data::load_tables(gef::data::ProgramData(gef::data::NuclideData::Jeff33));
    return tables;
}

// The builder arrays, which are compared element by element rather than as P3 lines.
bool is_builder_array(std::string_view name) {
    constexpr std::array<std::string_view, 6> arrays{"Zmean",  "beta",  "Edefo",
                                                     "Zshift", "R_Att", "R_Att_Sad"};
    return std::ranges::find(arrays, name) != arrays.end();
}

// One builder array of a bin, compared bit by bit with BASIC's P3 record.
template <std::size_t rank>
void check_array(std::string_view name, gef::fb::Array<float, rank> const& cpp,
                 gef::test::ProbeRecord const& out, std::int64_t i_a_cn) {
    INFO("variable " << name);
    std::string const difference = array_difference(cpp, out, name, i_a_cn);
    INFO(difference);
    CHECK(difference.empty());
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
                                             .e_defo = poison,
                                             .rz = poison};
    c.z = poison;
    // D7: the blocks through M7.2 zero these in every bin (GEF.bas:6326, 6478-6481); poisoned,
    // a missing zeroing would show in the comparison.
    c.tables.t_rusanov = poison;
    c.tables.r_e_intr_s1 = poison;
    c.tables.r_e_intr_s2 = poison;
    c.tables.r_e_intr_s3 = poison;
    c.tables.r_e_intr_s4 = poison;
    c.tables.r_e_intr_s5 = poison;
    for (gef::fb::Array<float, 1>* const array : {&c.tables.r_att, &c.tables.r_att_sad}) {
        array->redim({gef::fb::Bounds{0, 7}});
        std::ranges::fill(array->elements(), poison);
    }
    gef::fb::PrintFile console = gef::fb::PrintFile::console();
    gef::tables::enter_bin(c.bin, c.params.emode, c.spin_cn, console);
    std::vector<gef::tables::BetaEquiMessage> messages;
    gef::tables::mode_centres_and_deformations(c.bin, c.working, c.params, c.spin_cn, c.tables,
                                               c.temporaries, c.z, messages);
    gef::tables::barriers_temperatures_and_widths(c.bin, c.plan.p_a_cn, c.working, c.params,
                                                  jeff33(), c.tables, c.temporaries);
    // Scalars as P3 lines; the arrays element by element (bit patterns).
    gef::test::ProbeDump const dump =
        gef::test::dump_builder_case(c, "P3", out.context, /*with_arrays=*/false);
    for (std::string const& name : whole) {
        if (!is_builder_array(name)) {
            INFO("variable " << name);
            CHECK(dump.lines(name) == out.lines(name));
        }
    }
    check_array("Zmean", c.tables.zmean, out, c.bin.i_a_cn);
    check_array("beta", c.tables.beta, out, c.bin.i_a_cn);
    check_array("Edefo", c.tables.edefo, out, c.bin.i_a_cn);
    check_array("Zshift", c.tables.zshift, out, c.bin.i_a_cn);
    check_array("R_Att", c.tables.r_att, out, c.bin.i_a_cn);
    check_array("R_Att_Sad", c.tables.r_att_sad, out, c.bin.i_a_cn);
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
std::size_t check_capture(std::string const& capture,
                          std::set<std::string, std::less<>> const& whole) {
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
    if (capture == "m7-p3-fm212-sf" || capture == "m7-p3-ds270-sf") {
        CHECK_FALSE(messages.empty());
    }
    return records;
}

} // namespace

TEST_CASE("tables: blocks through M7.2 equal BASIC from P3in", "[T1][tables]") {
    std::set<std::string, std::less<>> const whole = whole_variables();
    std::size_t captures = 0;
    std::size_t records = 0;
    for (std::string const& id : gef::test::m7_corpus_ids()) {
        if (gef::test::store_file("m7-p3-" + id, "work/probes/P3in.txt")) {
            ++captures;
            records += check_capture("m7-p3-" + id, whole);
        }
    }
    // QUIRK(Q-061): A_CN 385 at Z 120, where the Z(A) loops write past Zmean and Zshift; BASIC
    // writes P3 of the bin before its run dies.
    if (gef::test::store_file("m7-q061-z120a385", "work/probes/P3in.txt")) {
        ++captures;
        records += check_capture("m7-q061-z120a385", whole);
    }
    if (captures == 0) {
        SKIP("the reference store has no M7 capture");
    }
    CHECK(captures == gef::test::m7_corpus_ids().size() + 1);
    CHECK(records > 0);
}
