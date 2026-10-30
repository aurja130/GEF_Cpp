// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// The bins of a pass (tables::BinPlan, GEF.bas:5490-5577 and 10001-10004) and the bin entry
// (tables::enter_bin, 5584-5598): MILESTONE_7_PLAN.md D4, gate G4.

#include "fbrt/array.hpp"
#include "fbrt/text.hpp"
#include "support/bin_tables_p3.hpp"
#include "support/golden.hpp"
#include "support/probe_records.hpp"
#include "tables/bin_plan.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <limits>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace {

using gef::fb::Array;
using gef::fb::Bounds;
using gef::tables::BinInput;
using gef::tables::BinPlan;
using gef::tables::BinPlanInput;

// The variables BinPlan and enter_bin write that P3in records at the bin entry (IEVTtot, which
// the event loop counts, is compared at the first bin of a pass only).
constexpr std::array<std::string_view, 20> plan_variables{
    "I_E_distr", "I_N_Multi",     "I_Z_Multi", "I_E_Multi",     "N_E_distr",
    "N_N_Multi", "N_Z_Multi",     "N_E_Multi", "I_N_Multi_Max", "I_Z_Multi_Max",
    "I_A_Multi", "I_Z_CN",        "I_A_CN",    "R_E_exc_used",  "R_NEVTspectrum",
    "Spin_CN",   "I_rigid_spher", "I_eff_CN",  "E_rot_CN",      "NEVTused",
};

std::string bin_label(BinInput const& bin) {
    return std::to_string(bin.i_e_distr) + ":" + std::to_string(bin.i_n_multi) + ":" +
           std::to_string(bin.i_z_multi) + ":" + std::to_string(bin.i_e_multi);
}

struct Bin {
    std::int64_t e_distr = 0;
    std::int64_t n = 0;
    std::int64_t z = 0;
    std::int64_t e = 0;
    std::int64_t a = 0; // I_A_Multi
    std::int64_t i_z_cn = 0;
    std::int64_t i_a_cn = 0;
    float r_e_exc_used = 0.0F;
    std::int64_t nevtused = 0;
    float spin_cn = 0.0F;
    std::int64_t i_n_multi_max = 0;
    std::int64_t i_z_multi_max = 0;
};

struct Pass {
    std::vector<Bin> bins;
    std::string console; // what enter_bin printed
};

// Runs a whole pass: every bin with NEVTused > 0, entered as the builder enters it.
Pass run_pass(BinPlanInput const& in, float& spin_cn) {
    BinInput bin;
    BinPlan plan(in, bin);
    gef::fb::PrintFile console = gef::fb::PrintFile::console();
    std::vector<Bin> bins;
    while (plan.next(bin, spin_cn)) {
        gef::tables::enter_bin(bin, in.emode, spin_cn, console);
        bins.push_back(Bin{.e_distr = bin.i_e_distr,
                           .n = bin.i_n_multi,
                           .z = bin.i_z_multi,
                           .e = bin.i_e_multi,
                           .a = bin.i_a_multi,
                           .i_z_cn = bin.i_z_cn,
                           .i_a_cn = bin.i_a_cn,
                           .r_e_exc_used = bin.r_e_exc_used,
                           .nevtused = bin.nevtused,
                           .spin_cn = spin_cn,
                           .i_n_multi_max = bin.i_n_multi_max,
                           .i_z_multi_max = bin.i_z_multi_max});
    }
    CHECK_FALSE(plan.next(bin, spin_cn)); // stays ended
    return Pass{.bins = bins, .console = console.text()};
}

} // namespace

TEST_CASE("tables: multi-chance bins run N, Z up and E* down, with protons emitted",
          "[unit][tables]") {
    // Bins with I_Z_Multi 2 and 10, beyond the captures (cm232-gs25 reaches 1, plan §8), and
    // weights on the boundary of CLngInt's rounding (NEVTtot * w = 0.5 is 0, 1.5 is 2).
    Array<float, 3> chances{{Bounds{0, 10}, Bounds{0, 10}, Bounds{0, 1000}}};
    chances(0, 0, 70) = 0.25F;
    chances(0, 0, 69) = 0x1.p-11F;  // 1024 * w = 0.5: CLngInt rounds to even, 0, skipped
    chances(0, 2, 30) = 0x1.8p-10F; // 1024 * w = 1.5: rounds to 2
    chances(1, 1, 50) = 0.25F;
    chances(10, 10, 0) = 0.125F;
    BinPlanInput in;
    in.emode = 2;
    in.inofirst = 3;
    in.p_z_cn = 94;
    in.p_a_cn = 240;
    in.p_e_exc = 6.5F;
    in.eabsgs = 7.0F;
    in.nevttot = 1024;
    in.e_multi_chance = &chances;
    float spin_cn = 2.5F;
    Pass const pass = run_pass(in, spin_cn);
    std::vector<Bin> const& bins = pass.bins;

    REQUIRE(bins.size() == 4);
    // I_A_Multi = I_N_Multi + I_Z_Multi (5530), the emitted nucleons the event loop reads
    CHECK((bins.at(0).a == 0 && bins.at(1).a == 2 && bins.at(2).a == 2 && bins.at(3).a == 20));
    CHECK(
        (bins.at(0).e_distr == 1 && bins.at(0).n == 0 && bins.at(0).z == 0 && bins.at(0).e == 70));
    CHECK((bins.at(0).i_z_cn == 94 && bins.at(0).i_a_cn == 240 && bins.at(0).nevtused == 256));
    CHECK(bins.at(0).r_e_exc_used == 7.0F);
    CHECK((bins.at(1).n == 0 && bins.at(1).z == 2 && bins.at(1).e == 30));
    CHECK((bins.at(1).i_z_cn == 92 && bins.at(1).i_a_cn == 238 && bins.at(1).nevtused == 2));
    CHECK(bins.at(1).r_e_exc_used == 3.0F);
    CHECK((bins.at(1).i_n_multi_max == 0 && bins.at(1).i_z_multi_max == 2));
    CHECK((bins.at(2).n == 1 && bins.at(2).z == 1 && bins.at(2).e == 50));
    CHECK((bins.at(2).i_z_cn == 93 && bins.at(2).i_a_cn == 238 && bins.at(2).nevtused == 256));
    CHECK((bins.at(2).i_n_multi_max == 1 && bins.at(2).i_z_multi_max == 2));
    CHECK((bins.at(3).n == 10 && bins.at(3).z == 10 && bins.at(3).e == 0));
    CHECK((bins.at(3).i_z_cn == 84 && bins.at(3).i_a_cn == 220 && bins.at(3).nevtused == 128));
    CHECK(bins.at(3).r_e_exc_used == 0.0F);
    CHECK(spin_cn == 2.5F);      // only Emode 13 and 3 write Spin_CN
    CHECK(pass.console.empty()); // 5584: the bin line is printed for Emode 3 only
}

TEST_CASE("tables: EM and ES passes leave the last iteration's spin, populated or not",
          "[unit][tables]") {
    // QUIRK(Q-054): the next step's set-up reads Spin_CN as the last loop iteration left it.
    SECTION("EM: Spin_CN = 0 in every multi-chance iteration") {
        Array<float, 3> const chances{{Bounds{0, 10}, Bounds{0, 10}, Bounds{0, 1000}}};
        BinPlanInput in;
        in.emode = 13;
        in.p_z_cn = 94;
        in.p_a_cn = 240;
        in.nevttot = 1000;
        in.e_multi_chance = &chances;
        float spin_cn = 3.5F;
        CHECK(run_pass(in, spin_cn).bins.empty());
        CHECK(spin_cn == 0.0F);
    }
    SECTION("ES: one bin per spectrum point with weight, the spin of the last point stays") {
        Array<float, 1> e_spectrum{{Bounds{0, 3}}};
        Array<float, 1> l_spectrum{{Bounds{0, 3}}};
        Array<float, 1> w_spectrum{{Bounds{0, 3}}};
        for (std::int64_t i = 1; i <= 3; ++i) {
            e_spectrum(i) = static_cast<float>(i) * 2.0F;
            l_spectrum(i) = static_cast<float>(i);
        }
        w_spectrum(2) = 0.5F;
        BinPlanInput in;
        in.emode = 3;
        in.p_z_cn = 92;
        in.p_a_cn = 236;
        in.nevttot = 100;
        in.e_spectrum = &e_spectrum;
        in.l_spectrum = &l_spectrum;
        in.w_spectrum = &w_spectrum;
        float spin_cn = 0.0F;
        Pass const pass = run_pass(in, spin_cn);
        std::vector<Bin> const& bins = pass.bins;
        REQUIRE(bins.size() == 1);
        CHECK((bins.at(0).e_distr == 2 && bins.at(0).nevtused == 50));
        CHECK(bins.at(0).r_e_exc_used == 4.0F);
        CHECK(bins.at(0).spin_cn == 2.0F);
        CHECK(spin_cn == 3.0F);
        // 5585, one line per bin entered: Single fields as fb_PrintSingle writes them, `,` pads
        // to the next 14-column zone
        CHECK(pass.console == "E_exc:  4     , spin:  2    , normalized weight:  0.5\n");
    }
}

namespace {

// The P1 record of the step a P3in record belongs to: the first one, from `from` on, with the
// record's step and CN (systems that share a step number differ in their CN in the corpus).
std::size_t step_setup(std::vector<gef::test::ProbeRecord> const& p1, std::size_t from,
                       gef::test::ProbeRecord const& record) {
    std::int64_t const z = gef::test::integer_value(record, "P_Z_CN");
    std::int64_t const a = gef::test::integer_value(record, "P_A_CN");
    std::size_t found = from;
    while (found < p1.size() && (p1.at(found).step() != record.step() ||
                                 gef::test::integer_value(p1.at(found), "P_Z_CN") != z ||
                                 gef::test::integer_value(p1.at(found), "P_A_CN") != a)) {
        ++found;
    }
    REQUIRE(found < p1.size());
    return found;
}

// The P1/P2 records of a capture's traced steps and the BinPlan input of the pass the current
// P3in records belong to.
class CapturePasses {
public:
    explicit CapturePasses(std::string const& capture)
        : p1_{gef::test::read_probe_records(
              gef::test::capture_file(capture, "work/probes/P1.txt"))},
          p2_{gef::test::read_probe_records(
              gef::test::capture_file(capture, "work/probes/P2.txt"))} {
        REQUIRE(p1_.size() == p2_.size());
        for (std::size_t i = 0; i < p1_.size(); ++i) {
            REQUIRE(p1_.at(i).step() == p2_.at(i).step());
        }
    }

    // The next bin of the record's pass, starting the pass when the record opens one.
    void next_bin(gef::test::ProbeRecord const& record) {
        std::size_t const found = step_setup(p1_, setup_, record);
        if (plan_ && found == setup_ && record.pass() == pass_) {
            REQUIRE(plan_->next(bin_, spin_cn_));
            return;
        }
        end_pass();
        setup_ = found;
        pass_ = record.pass();
        start_pass(record);
    }

    // After the last record of a pass: the loops end there.
    void end_pass() {
        if (plan_) {
            CHECK_FALSE(plan_->next(bin_, spin_cn_));
        }
    }

    [[nodiscard]] BinInput& bin() { return bin_; }
    [[nodiscard]] float spin_cn() const { return spin_cn_; }
    [[nodiscard]] std::int64_t emode() const { return in_.emode; }

private:
    void start_pass(gef::test::ProbeRecord const& record) {
        e_spectrum_ = gef::test::read_single_array<1>(p1_.at(setup_), "E_spectrum");
        l_spectrum_ = gef::test::read_single_array<1>(p1_.at(setup_), "L_spectrum");
        w_spectrum_ = gef::test::read_single_array<1>(p1_.at(setup_), "W_spectrum");
        e_multi_chance_ = gef::test::read_single_array<3>(p2_.at(setup_), "E_multi_chance");
        in_ = BinPlanInput{.emode = gef::test::integer_value(record, "Emode"),
                           .inofirst = gef::test::integer_value(record, "Inofirst"),
                           .p_z_cn = gef::test::integer_value(record, "P_Z_CN"),
                           .p_a_cn = gef::test::integer_value(record, "P_A_CN"),
                           .p_e_exc = gef::test::single_value(record, "P_E_exc"),
                           .eabsgs = gef::test::single_value(record, "Eabsgs"),
                           .nevttot = gef::test::integer_value(record, "NEVTtot"),
                           .e_spectrum = &e_spectrum_,
                           .l_spectrum = &l_spectrum_,
                           .w_spectrum = &w_spectrum_,
                           .e_multi_chance = &e_multi_chance_};
        // Spin_CN as the pass starts matters only for the channels that do not set it per bin.
        spin_cn_ = gef::test::single_value(record, "Spin_CN");
        plan_.emplace(in_, bin_);
        REQUIRE(plan_->next(bin_, spin_cn_));
        // IEVTtot is reset per pass (5497); later bins see the event loop's count (M10).
        CHECK(bin_.ievttot == gef::test::integer_value(record, "IEVTtot"));
    }

    std::vector<gef::test::ProbeRecord> p1_;
    std::vector<gef::test::ProbeRecord> p2_;
    std::size_t setup_ = 0;
    std::optional<std::int64_t> pass_;
    Array<float, 1> e_spectrum_;
    Array<float, 1> l_spectrum_;
    Array<float, 1> w_spectrum_;
    Array<float, 3> e_multi_chance_;
    BinPlanInput in_;
    BinInput bin_;
    float spin_cn_ = 0.0F;
    std::optional<BinPlan> plan_;
};

// D10: the `Emode = 3` lines (5585) appear in BASIC's console output, in this order.
void check_console(std::string const& capture, std::string const& text) {
    std::vector<std::string> const out =
        gef::test::read_lines(gef::test::capture_file(capture, "stdout.log"));
    std::size_t at = 0;
    for (std::size_t start = 0; start < text.size();) {
        std::size_t const end = text.find('\n', start);
        std::string const line = text.substr(start, end - start);
        while (at < out.size() && out.at(at) != line) {
            ++at;
        }
        INFO("console line " << line);
        CHECK(at < out.size());
        ++at;
        start = end + 1;
    }
}

// Every P3in record of one capture against the bins C++ plans; returns the number of records.
std::size_t check_capture(std::string const& capture,
                          std::set<std::string, std::less<>> const& keep) {
    INFO("capture " << capture);
    CapturePasses passes(capture);
    gef::fb::PrintFile console = gef::fb::PrintFile::console();
    gef::test::ProbeRecordReader reader(gef::test::capture_file(capture, "work/probes/P3in.txt"),
                                        keep);
    gef::test::ProbeRecord record;
    std::size_t records = 0;
    std::size_t es_bins = 0; // bins of Emode 3 passes: one console line each (5585)
    while (reader.next(record)) {
        ++records;
        INFO("record " << record.context);
        passes.next_bin(record);
        REQUIRE(bin_label(passes.bin()) == record.bin());
        gef::test::BuilderCase c;
        c.bin = passes.bin();
        c.spin_cn = passes.spin_cn();
        gef::test::ProbeDump const dump = gef::test::dump_builder_case(c, "P3in", record.context);
        for (std::string_view name : plan_variables) {
            INFO("variable " << name);
            CHECK(dump.lines(name) == record.lines(name));
        }
        if (passes.emode() == 3) {
            ++es_bins;
        }
        gef::tables::enter_bin(passes.bin(), passes.emode(), passes.spin_cn(), console);
    }
    passes.end_pass();
    std::string const& text = console.text();
    CHECK(std::cmp_equal(std::ranges::count(text, '\n'), es_bins));
    if (capture == "m7-p3-spectra") {
        CHECK(es_bins > 0); // its ES part (plan §9, M7.0)
    }
    if (es_bins > 0) {
        check_console(capture, text);
    }
    return records;
}

} // namespace

TEST_CASE("tables: the bins and bin inputs of every M7 capture equal BASIC's", "[T1][tables]") {
    std::set<std::string, std::less<>> keep(plan_variables.begin(), plan_variables.end());
    for (std::string_view name :
         {"P_Z_CN", "P_A_CN", "P_E_exc", "Eabsgs", "Emode", "Inofirst", "NEVTtot", "IEVTtot"}) {
        keep.emplace(name);
    }
    std::size_t captures = 0;
    std::size_t records = 0;
    for (std::string const& id : gef::test::m7_corpus_ids()) {
        std::string const capture = "m7-p3-" + id;
        if (gef::test::store_file(capture, "work/probes/P3in.txt")) {
            ++captures;
            records += check_capture(capture, keep);
        }
    }
    if (captures == 0) {
        SKIP("the reference store has no M7 capture");
    }
    CHECK(captures == gef::test::m7_corpus_ids().size());
    CHECK(records > 0);
}

TEST_CASE("tables: nominal passes copy the nominal parameters into the working copies",
          "[T1][tables]") {
    // GEF.bas:5432-5484 (tables::assign_nominal): in a step without Options(ERR) (B_Error_On 0
    // at P1; B_Error_Analysis = B_Error_On at 4805) every pass takes the nominal branch, so the
    // working copies in P3in are the nominal values P1 recorded for the system.
    std::set<std::string, std::less<>> keep{"P_Z_CN", "P_A_CN"};
    for (std::string_view name : gef::test::working_parameter_names()) {
        keep.emplace(name);
    }
    std::size_t captures = 0;
    std::size_t compared = 0;
    for (std::string const& id : gef::test::m7_corpus_ids()) {
        std::string const capture = "m7-p3-" + id;
        if (!gef::test::store_file(capture, "work/probes/P3in.txt")) {
            continue;
        }
        ++captures;
        INFO("capture " << capture);
        auto const p1 =
            gef::test::read_probe_records(gef::test::capture_file(capture, "work/probes/P1.txt"));
        gef::test::ProbeRecordReader reader(
            gef::test::capture_file(capture, "work/probes/P3in.txt"), keep);
        gef::test::ProbeRecord record;
        std::size_t setup = 0;
        while (reader.next(record)) {
            setup = step_setup(p1, setup, record);
            if (gef::test::integer_value(p1.at(setup), "B_Error_On") != 0) {
                continue; // perturbed passes: M8, M12 (plan D3)
            }
            INFO("record " << record.context);
            gef::test::BuilderCase c;
            gef::test::load_builder_case(p1.at(setup), c); // the nominal `_P_DZ_Mean_S1`, ...
            // Poisoned, so that a missing copy shows also for a nominal value of 0.
            gef::test::fill_working(c.working, std::numeric_limits<float>::quiet_NaN());
            gef::tables::assign_nominal(c.working, c.params);
            gef::test::ProbeDump const dump =
                gef::test::dump_builder_case(c, "P3in", record.context);
            for (std::string_view name : gef::test::working_parameter_names()) {
                INFO("variable " << name);
                CHECK(dump.lines(name) == record.lines(name));
            }
            ++compared;
        }
    }
    if (captures == 0) {
        SKIP("the reference store has no M7 capture");
    }
    CHECK(compared > 0);
}
