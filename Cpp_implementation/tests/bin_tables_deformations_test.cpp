// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// T1, gate G3: the whole table builder (GEF.bas:5584-7507 and 7920: bin entry, mode centres,
// deformations, mean Z as a function of A, Z-A relations, curvatures, barriers, energies,
// temperatures and widths, energy-dependent shifts, EMpot, polarisation, yields, mass widths,
// shell effects, temperatures, even-odd effect, energy sorting, fragment spins and Racc) runs from
// every P3in record of the M7 captures. Each run is compared with the P3 record of the same bin,
// per MILESTONE_7_PLAN.md D9: every P3 variable must equal BASIC's bits.

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
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace {

// The index of the element `linear` places after the first one (row-major, the last index
// running fastest), as text, for example `3,1,47`.
template <std::size_t rank>
std::string index_text(gef::fb::Array<float, rank> const& array, std::size_t linear) {
    std::array<std::int64_t, rank> index{};
    for (std::size_t d = rank; d-- > 0;) {
        auto const dimension = static_cast<std::int64_t>(d) + 1;
        auto const extent =
            static_cast<std::size_t>(array.ubound(dimension) - array.lbound(dimension) + 1);
        index.at(d) = array.lbound(dimension) + static_cast<std::int64_t>(linear % extent);
        linear /= extent;
    }
    std::string text;
    for (std::size_t d = 0; d < rank; ++d) {
        if (d > 0) {
            text += ",";
        }
        text += std::to_string(index.at(d));
    }
    return text;
}

// Compares `cpp` with the array `name` of BASIC's record `out`, element by element and by bit
// pattern. Returns the first difference, or an empty string when there is none.
template <std::size_t rank>
std::string array_difference(gef::fb::Array<float, rank> const& cpp,
                             gef::test::ProbeRecord const& out, std::string_view name) {
    gef::fb::Array<float, rank> const basic = gef::test::read_single_array<rank>(out, name);
    for (std::size_t d = 1; d <= rank; ++d) {
        auto const dimension = static_cast<std::int64_t>(d);
        if (cpp.lbound(dimension) != basic.lbound(dimension) ||
            cpp.ubound(dimension) != basic.ubound(dimension)) {
            return "bounds differ in dimension " + std::to_string(dimension);
        }
    }
    // Equal bounds: both arrays hold their elements in the same order.
    std::span<float const> const want = basic.elements();
    std::span<float const> const got = cpp.elements();
    auto const [want_at, got_at] = std::ranges::mismatch(want, got, [](float a, float b) {
        return std::bit_cast<std::uint32_t>(a) == std::bit_cast<std::uint32_t>(b);
    });
    if (want_at != want.end()) {
        auto const linear = static_cast<std::size_t>(want_at - want.begin());
        return "element " + index_text(cpp, linear) + ": C++ " +
               std::to_string(std::bit_cast<std::uint32_t>(*got_at)) + ", BASIC " +
               std::to_string(std::bit_cast<std::uint32_t>(*want_at));
    }
    return {};
}

// The lines of console text.
std::vector<std::string> text_lines(std::string const& text) {
    std::vector<std::string> lines;
    for (std::size_t start = 0; start < text.size();) {
        std::size_t const end = text.find('\n', start);
        lines.push_back(text.substr(start, end - start));
        start = end + 1;
    }
    return lines;
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
    return text_lines(console.text());
}

// GEF.bas:7016-7017, the builder's print when the selected mode's yield is 0, in the order of
// `lines` (C++ console text or BASIC's stdout).
std::vector<std::string> selected_mode_lines(std::vector<std::string> const& lines) {
    std::vector<std::string> out;
    for (std::string const& line : lines) {
        if (line == "<I> Yield of the selected fission mode too low." ||
            line == "    No calculation performed.") {
            out.push_back(line);
        }
    }
    return out;
}

} // namespace

// D9 compares the whole P3, so every P3 variable must be an input of the builder or written by
// one of its parts M7.1-M7.4, and BuilderCase must hold it.
TEST_CASE("tables: the builder writes or carries every P3 variable", "[unit][tables]") {
    auto const& registered = gef::test::builder_variable_names();
    std::set<std::string_view> const parts{"input", "M7.1", "M7.2", "M7.3", "M7.4"};
    for (auto const& [name, row] : gef::test::last_writer_map()) {
        INFO("variable " << name << ", part " << row.part);
        CHECK(parts.contains(row.part));
        CHECK(registered.contains(name));
    }
    CHECK(gef::test::last_writer_map().at("SpinRMSNZ").part == "M7.4");
}

namespace {

// D9: every P3 variable (the last-writer map holds them all).
std::set<std::string, std::less<>> whole_variables() {
    auto const& registered = gef::test::builder_variable_names();
    std::set<std::string, std::less<>> whole;
    for (auto const& [name, row] : gef::test::last_writer_map()) {
        INFO("variable " << name);
        REQUIRE(registered.contains(name));
        whole.insert(name);
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
    constexpr std::array<std::string_view, 15> arrays{
        "Zmean",  "beta",   "Edefo", "Zshift", "R_Att", "R_Att_Sad", "EMpot",        "Temp",
        "TempFF", "Eshell", "PEOZ",  "PEON",   "EPART", "SpinRMSNZ", "E_coll_saddle"};
    return std::ranges::find(arrays, name) != arrays.end();
}

// One builder array of a bin, compared bit by bit with BASIC's P3 record.
template <std::size_t rank>
void check_array(std::string_view name, gef::fb::Array<float, rank> const& cpp,
                 gef::test::ProbeRecord const& out) {
    INFO("variable " << name);
    std::string const difference = array_difference(cpp, out, name);
    INFO(difference);
    CHECK(difference.empty());
}

// One bin: the C++ from its P3in record against its P3 record. Returns the Beta_Equi messages
// and appends the bin's console lines to `console_lines`.
std::vector<gef::tables::BetaEquiMessage> check_bin(gef::test::ProbeRecord const& in,
                                                    gef::test::ProbeRecord const& out,
                                                    std::set<std::string, std::less<>> const& whole,
                                                    std::vector<std::string>& console_lines) {
    gef::test::BuilderCase c;
    gef::test::load_builder_case(in, c);
    // D7: the builder's temporaries and the globals Z and T carry nothing into a bin; poisoned, a
    // read before write would show in the comparison.
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
                                             .in1 = -1000000,
                                             .ia1 = -1000000,
                                             .ia2 = -1000000,
                                             .a1 = poison,
                                             .a2 = poison,
                                             .e_defo = poison,
                                             .rz = poison};
    c.z = poison;
    c.t = poison;
    // D7: the blocks through M7.2 zero these in every bin (GEF.bas:6326, 6478-6481); poisoned,
    // a missing zeroing would show in the comparison.
    c.tables.t_rusanov = poison;
    c.tables.r_e_intr_s1 = poison;
    c.tables.r_e_intr_s2 = poison;
    c.tables.r_e_intr_s3 = poison;
    c.tables.r_e_intr_s4 = poison;
    c.tables.r_e_intr_s5 = poison;
    // GEF.bas:7178 `Redim E_coll_saddle(0 To 7)` zero-fills it in every bin.
    for (gef::fb::Array<float, 1>* const array :
         {&c.tables.r_att, &c.tables.r_att_sad, &c.tables.e_coll_saddle}) {
        array->redim({gef::fb::Bounds{0, 7}});
        std::ranges::fill(array->elements(), poison);
    }
    // D7: GEF.bas:7040-7507 rewrite these in every bin, many with values that depend only on A
    // (equal in every bin of a capture) or are 0; poisoned over the range each block writes (inside
    // the array), a missing write would show in the comparison.
    for (float* const scalar :
         {&c.tables.du0, &c.tables.du1, &c.tables.du2, &c.tables.du3, &c.tables.du4, &c.tables.du5,
          &c.tables.t_intr_mode_0, &c.tables.t_intr_mode_1_heavy, &c.tables.t_intr_mode_1_light,
          &c.tables.t_intr_mode_2_heavy, &c.tables.t_intr_mode_2_light,
          &c.tables.t_intr_mode_3_heavy, &c.tables.t_intr_mode_3_light,
          &c.tables.t_intr_mode_4_heavy, &c.tables.t_intr_mode_4_light,
          &c.tables.t_intr_mode_5_heavy, &c.tables.t_intr_mode_5_light, &c.tables.eintr_scission,
          &c.bin.i_rigid_spher}) {
        *scalar = poison;
    }
    std::int64_t const a_last = std::min<std::int64_t>(c.bin.i_a_cn - 1, 350);
    for (std::int64_t a = 1; a <= a_last; ++a) {
        for (std::int64_t k = 1; k <= 2; ++k) {
            for (std::int64_t mode = 0; mode <= 5; ++mode) {
                if (mode <= 4 || k == 2) {
                    c.tables.eshell(mode, k, a) = poison;
                }
                c.tables.temp(mode, k, a) = poison;
                c.tables.tempff(mode, k, a) = poison;
            }
        }
    }
    std::int64_t const sorted_last = std::min<std::int64_t>(c.bin.i_a_cn - 40, 350);
    for (std::int64_t a = 40; a <= sorted_last; ++a) {
        for (std::int64_t k = 1; k <= 2; ++k) {
            for (std::int64_t mode = 0; mode <= 7; ++mode) {
                c.tables.epart(mode, k, a) = poison;
                c.tables.peoz(mode, k, a) = poison;
                c.tables.peon(mode, k, a) = poison;
            }
        }
    }
    gef::fb::PrintFile console = gef::fb::PrintFile::console();
    gef::tables::enter_bin(c.bin, c.params.emode, c.spin_cn, console);
    std::vector<gef::tables::BetaEquiMessage> messages;
    gef::tables::mode_centres_and_deformations(c.bin, c.working, c.params, c.spin_cn, c.tables,
                                               c.temporaries, c.z, messages);
    gef::tables::barriers_temperatures_and_widths(c.bin, c.plan.p_a_cn, c.working, c.params,
                                                  jeff33(), c.tables, c.temporaries);
    // D7: without suppression (B_supp <> 1) BASIC keeps the previous bin's R_slope_S2 (6653);
    // the NOSUPP records enter with 0, so a copy with a sentinel shows a reset.
    if (c.b_supp != 1) {
        gef::tables::BinTables kept = c.tables;
        kept.r_slope_s2 = 0x1.8p+0F;
        gef::fb::PrintFile sink = gef::fb::PrintFile::console();
        gef::tables::shifts_polarisation_and_yields(c.bin, c.b_supp, c.i_mode_selected, c.working,
                                                    c.params, kept, sink);
        CHECK(kept.r_slope_s2 == 0x1.8p+0F);
    }
    gef::tables::shifts_polarisation_and_yields(c.bin, c.b_supp, c.i_mode_selected, c.working,
                                                c.params, c.tables, console);
    gef::tables::shells_temperatures_and_energy_sorting(c.bin, c.working, c.params, c.tables,
                                                        c.temporaries, c.t);
    gef::tables::fragment_spins(c.bin, c.working, c.params, jeff33(), c.tables, c.temporaries,
                                c.spin_cn, c.t);
    gef::tables::spectra_normalisation(c.plan.nevttot, c.tables);
    std::vector<std::string> const lines = text_lines(console.text());
    console_lines.insert(console_lines.end(), lines.begin(), lines.end());
    // Scalars as P3 lines; the arrays element by element (bit patterns).
    gef::test::ProbeDump const dump =
        gef::test::dump_builder_case(c, "P3", out.context, /*with_arrays=*/false);
    for (std::string const& name : whole) {
        if (!is_builder_array(name)) {
            INFO("variable " << name);
            CHECK(dump.lines(name) == out.lines(name));
        }
    }
    check_array("Zmean", c.tables.zmean, out);
    check_array("beta", c.tables.beta, out);
    check_array("Edefo", c.tables.edefo, out);
    check_array("Zshift", c.tables.zshift, out);
    check_array("R_Att", c.tables.r_att, out);
    check_array("R_Att_Sad", c.tables.r_att_sad, out);
    check_array("EMpot", c.tables.empot, out);
    check_array("Temp", c.tables.temp, out);
    check_array("TempFF", c.tables.tempff, out);
    check_array("Eshell", c.tables.eshell, out);
    check_array("PEOZ", c.tables.peoz, out);
    check_array("PEON", c.tables.peon, out);
    check_array("EPART", c.tables.epart, out);
    check_array("SpinRMSNZ", c.tables.spinrmsnz, out);
    check_array("E_coll_saddle", c.tables.e_coll_saddle, out);
    return messages;
}

// QUIRK(Q-041): BASIC printed the builder's Beta_Equi messages to the console (f = 0 in every
// P3in record of the captures that reach it), all of them in a traced bin. The same holds for the
// print 7016-7017 of a selected mode without yield.
void check_console(std::string const& capture,
                   std::vector<gef::tables::BetaEquiMessage> const& messages,
                   std::vector<std::string> const& console_lines) {
    std::vector<std::string> const stdout_lines =
        gef::test::read_lines(gef::test::capture_file(capture, "stdout.log"));
    std::vector<std::string> printed;
    for (std::string const& line : stdout_lines) {
        if (line.starts_with("Beta_Equi not converged")) {
            printed.push_back(line);
        }
    }
    CHECK(beta_equi_lines(messages) == printed);
    CHECK(selected_mode_lines(console_lines) == selected_mode_lines(stdout_lines));
    if (capture == "m7-p3-u236-mode11") {
        CHECK_FALSE(selected_mode_lines(console_lines).empty());
    }
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
    std::vector<std::string> console_lines;
    gef::test::ProbeRecord in;
    gef::test::ProbeRecord out;
    std::size_t records = 0;
    while (p3in.next(in)) {
        REQUIRE(p3.next(out));
        REQUIRE(in.context == out.context);
        ++records;
        INFO("record " << out.context);
        // QUIRK(Q-011): the capture whose Fitpar.dat sets EOscale = 0.5 runs with it.
        if (capture == "m7-p3-u236-eoscale") {
            CHECK(gef::test::single_value(in, "EOscale") == 0.5F);
        }
        std::vector<gef::tables::BetaEquiMessage> const bin_messages =
            check_bin(in, out, whole, console_lines);
        messages.insert(messages.end(), bin_messages.begin(), bin_messages.end());
    }
    CHECK_FALSE(p3.next(out));
    check_console(capture, messages, console_lines);
    if (capture == "m7-p3-fm212-sf" || capture == "m7-p3-ds270-sf") {
        CHECK_FALSE(messages.empty());
    }
    return records;
}

} // namespace

TEST_CASE("tables: the whole P3 of every bin equals BASIC from P3in", "[T1][tables]") {
    std::set<std::string, std::less<>> const whole = whole_variables();
    std::size_t captures = 0;
    std::size_t records = 0;
    for (std::string const& id : gef::test::m7_corpus_ids()) {
        if (gef::test::store_file("m7-p3-" + id, "work/probes/P3in.txt")) {
            ++captures;
            records += check_capture("m7-p3-" + id, whole);
        }
    }
    // QUIRK(Q-061): A_CN 385 at Z 120, where the Z(A) loops write past Zmean and Zshift, the
    // spins read past EPART and write past SpinRMSNZ; BASIC writes P3 of the bin before its run
    // dies.
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

// GEF.bas:7338 `If Abs(T1 - T2) < 1.E-6`, compiled as `if (|T1 - T2| >= 1E-6) goto else`: a NaN
// temperature difference takes the Then branch, which gives each fragment half of Etot. A NaN
// Tscale makes every Temp NaN; the record is the first bin of a U-236 capture.
TEST_CASE("tables: energy sorting gives each fragment half of Etot when a temperature is NaN",
          "[unit][tables]") {
    std::string const capture = "m7-p3-u236-n";
    if (!gef::test::store_file(capture, "work/probes/P3in.txt")) {
        SKIP("the reference store has no capture " << capture);
    }
    gef::test::ProbeRecordReader p3in(gef::test::capture_file(capture, "work/probes/P3in.txt"),
                                      gef::test::builder_variable_names());
    gef::test::ProbeRecord in;
    REQUIRE(p3in.next(in));
    gef::test::BuilderCase c;
    gef::test::load_builder_case(in, c);
    gef::fb::PrintFile console = gef::fb::PrintFile::console();
    gef::tables::enter_bin(c.bin, c.params.emode, c.spin_cn, console);
    std::vector<gef::tables::BetaEquiMessage> messages;
    gef::tables::mode_centres_and_deformations(c.bin, c.working, c.params, c.spin_cn, c.tables,
                                               c.temporaries, c.z, messages);
    gef::tables::barriers_temperatures_and_widths(c.bin, c.plan.p_a_cn, c.working, c.params,
                                                  jeff33(), c.tables, c.temporaries);
    gef::tables::shifts_polarisation_and_yields(c.bin, c.b_supp, c.i_mode_selected, c.working,
                                                c.params, c.tables, console);
    c.params.tscale = std::numeric_limits<float>::quiet_NaN();
    gef::tables::shells_temperatures_and_energy_sorting(c.bin, c.working, c.params, c.tables,
                                                        c.temporaries, c.t);
    std::int64_t const a_cn = c.bin.i_a_cn;
    std::size_t positive = 0;
    for (std::int64_t mode = 0; mode <= 7; ++mode) {
        for (std::int64_t a1 = 40; a1 <= a_cn - 40; ++a1) {
            INFO("mode " << mode << ", A " << a1);
            float const e1 = c.tables.epart(mode, 1, a1);
            float const e2 = c.tables.epart(mode, 2, a_cn - a1);
            CHECK(e1 == e2);
            positive += e1 > 0.0F ? 1U : 0U;
        }
    }
    // With an Etot of 0 in every mode, mode 1 would split evenly on either branch.
    CHECK(positive > 0);
}
