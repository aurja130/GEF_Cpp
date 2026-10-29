// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// MILESTONE_6_PLAN.md D10: the branches of the input parser and the set-up that a batch run
// cannot take throw std::logic_error. The corpus cannot reach them; each test builds the state
// that would. Not reachable even so: GEF.bas:3852-3866 (the `Bfilein = 0` check of 3844 comes
// first) and 2527 (a fit iteration after the first: every way to Nextfitloop in M6 resets
// I_Fitloop at 2516).

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "physics/barriers.hpp"
#include "run/driver.hpp"
#include "run/input_files.hpp"
#include "run/run_util.hpp"
#include "run/setup.hpp"
#include "run/state.hpp"
#include "run/workdir.hpp"
#include "support/run_replay.hpp"

#include <catch2/catch_test_macros.hpp>

#include <filesystem>
#include <stdexcept>
#include <string>
#include <string_view>

namespace data = gef::data;
namespace fs = std::filesystem;

namespace {

using gef::run::InputRoundState;
using gef::run::ProcessState;
using gef::run::SequenceFileState;
using gef::run::StepState;
using gef::run::WorkDir;
using gef::test::logic_error_of;
using gef::test::ScopedDir;

data::TableSet const& jeff33() {
    static data::TableSet const tables =
        data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    return tables;
}

// A process in dialogue mode (Bfilein 0) with the CN (z, a) set, as the driver sets it.
ProcessState dialogue_process(std::int64_t z, std::int64_t a) {
    ProcessState process{jeff33()};
    process.bfilein = 0;
    process.p_z_cn = z;
    process.p_a_cn = a;
    process.i_double_covar = 1;
    return process;
}

// The end of a run of the batch set-up on a scratch directory: the logic_error it throws.
std::string batch_run_error(fs::path const& root) {
    ProcessState process{jeff33()};
    gef::run::BatchSetup stages;
    gef::run::RunDriver driver{process, WorkDir{root}, stages};
    return logic_error_of([&driver] {
        while (driver.next_step()) {
        }
    });
}

} // namespace

TEST_CASE("run: the set-up's dialogue branches throw logic_error", "[run]") {
    InputRoundState round;
    SequenceFileState file;
    SECTION("the lmd name outside batch mode (GEF.bas:3430-3439)") {
        ProcessState process = dialogue_process(92, 236);
        CHECK(logic_error_of([&] {
                  static_cast<void>(gef::run::begin_system(process, round, file));
              }).starts_with("GEF.bas:3430-3439"));
    }
    SECTION("an unbound CN outside batch mode (GEF.bas:3386-3388)") {
        ProcessState process = dialogue_process(76, 241);
        CHECK(logic_error_of([&] {
                  static_cast<void>(gef::run::begin_system(process, round, file));
              }).starts_with("GEF.bas:3386-3388"));
    }
    SECTION("the energy lines outside batch mode (GEF.bas:3844-3848)") {
        ProcessState process = dialogue_process(92, 236);
        ScopedDir const scratch{gef::test::process_scratch_root("m6-setup-d10")};
        StepState step;
        WorkDir const workdir{gef::test::process_scratch_root("m6-setup-d10")};
        CHECK(logic_error_of([&] {
                  static_cast<void>(gef::run::set_up_step(process, round, file, step, workdir));
              }).starts_with("GEF.bas:3844-3848"));
    }
}

TEST_CASE("run: a barrier switch outside BFTF's cases is a logic_error", "[run]") {
    gef::physics::BftfResult const undefined{.value = 0.0F, .print_undefined_option = true};
    CHECK_THROWS_AS(gef::run::barrier_value(undefined), std::logic_error);
    gef::physics::BftfResult const defined{.value = 2.5F, .print_undefined_option = false};
    CHECK(gef::run::barrier_value(defined) == 2.5F);
}

TEST_CASE("run: an input file that exists but cannot be opened is a logic_error", "[run]") {
    // `Fileexists` takes the name as given and `Open` turns `\` into `/` (WorkDir): a file
    // literally named with a backslash exists while the name Open reads does not.
    fs::path const root = gef::test::process_scratch_root("m6-setup-open");
    ScopedDir const scratch{root};
    static_cast<void>(fs::create_directories(root / "in"));
    SECTION("a sequence file (GEF.bas:2776)") {
        gef::test::write_bytes(root / "file.in", "\"in\\a.in\"\nEND\n");
        gef::test::write_bytes(root / "in\\a.in", " 1\n0.0253E-6\n 92, 236, \"EN\"\n");
        CHECK(batch_run_error(root).starts_with("GEF.bas:2776"));
    }
    SECTION("a spectrum file (GEF.bas:3625)") {
        gef::test::write_bytes(root / "file.in", "\"in/a.in\"\nEND\n");
        gef::test::write_bytes(root / "in" / "a.in", " 1\n\"in\\x.dat\"\n 92, 236, \"ES\"\n");
        gef::test::write_bytes(root / "in\\x.dat", " 5.0 0.5\n 6.0 0.5\n");
        CHECK(batch_run_error(root).starts_with("GEF.bas:3625"));
    }
    SECTION("file.in found at GEF.bas:1821 and gone when 2723 opens it") {
        // read_file_in runs with Bfilein -1 only after file.in was found; here it is not there.
        ProcessState process{jeff33()};
        process.bfilein = -1;
        InputRoundState round;
        SequenceFileState file;
        CHECK(logic_error_of([&] {
                  gef::run::read_file_in(process, round, file, WorkDir{root});
              }).starts_with("GEF.bas:2723"));
    }
}
