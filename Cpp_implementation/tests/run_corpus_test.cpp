// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// M6.3: the batch-mode set-up of every run of the M6 captures, replayed in C++ and checked against
// BASIC's probes P0 (each sequence file), P1 (each energy step's set-up) and P1b (each channel's
// threshold). A record is checked as the run writes it: its digest against the golden rows (m6-p0
// and m6-setup fingerprints.txt) and, where the reference store holds the run, each of its
// variables against BASIC's stored probe file. A full run (`mode full`) takes its passes after each
// step, as run_driver_test.cpp does.

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "params/parameter_files.hpp"
#include "run/driver.hpp"
#include "run/probes.hpp"
#include "run/setup.hpp"
#include "run/state.hpp"
#include "run/workdir.hpp"
#include "support/golden.hpp"
#include "support/probe_dump.hpp"
#include "support/run_p0.hpp"
#include "support/run_p1.hpp"
#include "support/run_replay.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <filesystem>
#include <map>
#include <optional>
#include <set>
#include <stdexcept>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

namespace data = gef::data;
namespace fs = std::filesystem;

namespace {

using gef::run::BatchSetup;
using gef::run::InputRoundState;
using gef::run::ProbeSink;
using gef::run::ProcessState;
using gef::run::RunDriver;
using gef::run::SequenceFileState;
using gef::run::StepState;
using gef::run::WorkDir;
using gef::test::PlanMode;
using gef::test::PlanRun;
using gef::test::ProbeDump;
using gef::test::ProbeFingerprint;

// A golden row's key: the run, the probe ("P0", "P1" or "P1b") and the record's number.
using GoldenKey = std::tuple<std::int64_t, std::string, std::int64_t>;
using GoldenMap = std::map<GoldenKey, ProbeFingerprint>;

// BASIC's records of one probe file, by record number. A record maps each NAME to its lines (an
// array's bounds line and its elements share one NAME).
using BasicRecord = std::map<std::string, std::vector<std::string>>;
using BasicRecords = std::map<std::int64_t, BasicRecord>;

// BASIC's stored probe files of one run (nullopt where the store does not hold the file).
struct StoredProbes {
    std::optional<BasicRecords> p0;
    std::optional<BasicRecords> p1;
    std::optional<BasicRecords> p1b;
};

// Whether NAME takes part in the digest and in the store comparison of a record of `probe`. A
// full run leaves the full_run_excluded_p1 NAMEs out of P1.
bool compared(std::string_view probe, std::string_view name, bool full) {
    auto const& excluded = gef::test::full_run_excluded_p1;
    bool const left_out = std::ranges::find(excluded, name) != excluded.end();
    return !(full && probe == "P1" && left_out);
}

// The digest of one record: the lines of its compared NAMEs in the dump's NAME order, hashed as
// fingerprint_lines hashes a probe (run_input_test.cpp digests P0 the same way).
ProbeFingerprint record_fingerprint(ProbeDump const& dump, std::string_view probe, bool full) {
    std::vector<std::string> lines;
    for (std::string const& name : dump.names()) {
        if (compared(probe, name, full)) {
            std::vector<std::string> const& name_lines = dump.lines(name);
            lines.insert(lines.end(), name_lines.begin(), name_lines.end());
        }
    }
    return gef::test::fingerprint_lines(lines);
}

// The first NAME, in ascending order, whose lines differ from BASIC's lines of that NAME (a NAME
// that only one side has differs too), with the first differing line of each side, or nullopt
// when every compared NAME matches.
std::optional<std::string> first_difference(BasicRecord const& basic, ProbeDump const& dump,
                                            std::string_view probe, bool full) {
    std::vector<std::string> const dump_names = dump.names();
    std::set<std::string> const in_dump(dump_names.begin(), dump_names.end());
    std::set<std::string> names = in_dump;
    for (auto const& entry : basic) {
        names.insert(entry.first);
    }
    std::vector<std::string> const none;
    for (std::string const& name : names) {
        if (!compared(probe, name, full)) {
            continue;
        }
        auto const stored = basic.find(name);
        std::vector<std::string> const& want = stored == basic.end() ? none : stored->second;
        std::vector<std::string> const& got = in_dump.contains(name) ? dump.lines(name) : none;
        if (want == got) {
            continue;
        }
        std::size_t i = 0;
        while (i < want.size() && i < got.size() && want.at(i) == got.at(i)) {
            ++i;
        }
        return name + ": BASIC '" + (i < want.size() ? want.at(i) : "<none>") + "', C++ '" +
               (i < got.size() ? got.at(i) : "<none>") + "'";
    }
    return std::nullopt;
}

// Adds one golden row; a repeated (run, probe, record) would hide a broken file.
void add_golden(GoldenMap& golden, GoldenKey const& key, std::string_view lines,
                std::string_view fnv, std::string const& line) {
    gef::test::plan_check(!golden.contains(key), "repeated fingerprints row: '" + line + "'");
    ProbeFingerprint const fingerprint{.lines = static_cast<std::size_t>(gef::test::to_int(lines)),
                                       .fnv = gef::test::parse_hex(fnv)};
    golden.emplace(key, fingerprint);
}

// The golden rows. m6-p0's fingerprints.txt holds `<run> <rec> <lines> <fnv>` rows of P0.
// m6-setup's opens with its `exclude-full` line and then holds `<run> <P1|P1b> <rec> <lines> <fnv>`
// rows.
GoldenMap read_golden(std::vector<std::string> const& p0_lines,
                      std::vector<std::string> const& setup_lines) {
    GoldenMap golden;
    for (std::string const& line : p0_lines) {
        std::vector<std::string_view> const fields = gef::test::split_fields(line);
        if (fields.empty() || fields.front().starts_with('#')) {
            continue;
        }
        gef::test::plan_check(fields.size() == 4, "m6-p0 fingerprints.txt: bad row '" + line + "'");
        add_golden(golden,
                   GoldenKey{gef::test::to_int(fields.at(0)), std::string{"P0"},
                             gef::test::to_int(fields.at(1))},
                   fields.at(2), fields.at(3), line);
    }
    bool opened = false;
    for (std::string const& line : setup_lines) {
        std::vector<std::string_view> const fields = gef::test::split_fields(line);
        if (fields.empty() || fields.front().starts_with('#')) {
            continue;
        }
        if (fields.front() == "exclude-full") {
            gef::test::plan_check(!opened, "m6-setup fingerprints.txt: repeated exclude-full");
            opened = true;
            std::vector<std::string_view> const names(fields.begin() + 1, fields.end());
            gef::test::plan_check(std::ranges::equal(names, gef::test::full_run_excluded_p1),
                                  "m6-setup fingerprints.txt: exclude-full is not the full-run "
                                  "exclusion of run_p1.hpp");
            continue;
        }
        gef::test::plan_check(opened, "m6-setup fingerprints.txt: a row precedes exclude-full");
        gef::test::plan_check(fields.size() == 5 && (fields.at(1) == "P1" || fields.at(1) == "P1b"),
                              "m6-setup fingerprints.txt: bad row '" + line + "'");
        add_golden(golden,
                   GoldenKey{gef::test::to_int(fields.at(0)), std::string{fields.at(1)},
                             gef::test::to_int(fields.at(2))},
                   fields.at(3), fields.at(4), line);
    }
    gef::test::plan_check(opened, "m6-setup fingerprints.txt: no exclude-full line");
    return golden;
}

// BASIC's records of `probe` in one probe file. A record's lines read `<ID> step=.. pass=..
// bin=.. rec=<k> NAME ...`; lines of other probes are skipped.
BasicRecords read_basic(fs::path const& file, std::string_view probe) {
    BasicRecords records;
    for (std::string const& line : gef::test::read_lines(file)) {
        std::vector<std::string_view> const fields = gef::test::split_fields(line);
        if (fields.size() < 6 || fields.front() != probe) {
            continue;
        }
        gef::test::plan_check(fields.at(4).starts_with("rec="),
                              std::string{probe} + ".txt: bad line '" + line + "'");
        BasicRecord& record = records[gef::test::to_int(fields.at(4).substr(4))];
        record[std::string{fields.at(5)}].push_back(line);
    }
    return records;
}

// BASIC's stored probe file `probe` of a run; nullopt when the store does not hold the run or file.
std::optional<BasicRecords> read_stored(std::optional<fs::path> const& stored,
                                        std::string_view probe) {
    if (!stored.has_value()) {
        return std::nullopt;
    }
    fs::path const file = *stored / "work" / "probes" / (std::string{probe} + ".txt");
    if (!fs::is_regular_file(file)) {
        return std::nullopt;
    }
    return read_basic(file, probe);
}

// The probe sink of one replayed run. It checks each record as the driver writes it: its digest
// against the golden row of (run, probe, record), and, where the store holds the run, each of its
// compared variables against BASIC's record of the same number.
class CorpusProbes final : public ProbeSink {
public:
    CorpusProbes(std::int64_t number, bool full, GoldenMap const& golden, StoredProbes stored)
        : number_{number}, full_{full}, stored_{std::move(stored)} {
        for (GoldenMap::value_type const& row : golden) {
            if (std::get<0>(row.first) == number_) {
                expected_.insert(row);
            }
        }
    }

    void sequence_file(ProcessState const& process, InputRoundState const& round,
                       SequenceFileState const& file) override {
        std::int64_t const rec = ++p0_;
        check("P0", rec, gef::test::dump_p0(process, round, file, rec), stored_.p0);
    }

    void step_setup(ProcessState const& process, InputRoundState const& round,
                    SequenceFileState const& file) override {
        std::int64_t const rec = ++p1_;
        check("P1", rec, gef::test::dump_p1(process, round, file, rec), stored_.p1);
    }

    void step_threshold(ProcessState const& process, StepState const& step, bool prepass) override {
        std::int64_t const rec = ++p1b_;
        check("P1b", rec, gef::test::dump_p1b(process, step, prepass, rec), stored_.p1b);
        prepass_ = prepass;
    }

    // GEF's condition of 3967 at the last P1b point (false for the channels outside 3948).
    [[nodiscard]] bool last_prepass() const noexcept { return prepass_; }

    // The golden rows of this run that no record has reached.
    [[nodiscard]] GoldenMap const& unreached() const { return expected_; }

    // The records that matched BASIC's stored probe files.
    [[nodiscard]] std::size_t store_matches() const { return store_matches_; }

private:
    // Checks record `rec` of `probe`: its digest against the golden row, then each compared
    // variable against BASIC's record `rec` of the stored probe file (when the store holds it).
    // After the first failing record of a probe, the probe's later records only use up their rows.
    void check(std::string_view probe, std::int64_t rec, ProbeDump const& dump,
               std::optional<BasicRecords> const& basic) {
        std::string const row = "run " + std::to_string(number_) + " " + std::string{probe} +
                                " record " + std::to_string(rec);
        GoldenKey const key{number_, std::string{probe}, rec};
        auto const expected = expected_.find(key);
        bool const known = expected != expected_.end();
        bool const digest_equal =
            known && record_fingerprint(dump, probe, full_) == expected->second;
        if (known) {
            expected_.erase(expected);
        }
        if (failed_.contains(std::string{probe})) {
            return;
        }
        std::optional<std::string> failure;
        if (!known) {
            failure = "no fingerprints.txt row for " + row;
        } else if (!digest_equal) {
            failure = "the variables of " + row + " differ from the golden fingerprint";
        }
        if (basic.has_value()) {
            auto const record = basic->find(rec);
            if (record == basic->end()) {
                failure = "BASIC's " + std::string{probe} + ".txt has no record for " + row;
            } else if (auto const difference = first_difference(record->second, dump, probe, full_);
                       difference.has_value()) {
                failure =
                    row + " differs from BASIC's " + std::string{probe} + ".txt: " + *difference;
            } else if (!failure.has_value()) {
                ++store_matches_;
            }
        }
        if (failure.has_value()) {
            failed_.insert(std::string{probe});
            FAIL_CHECK(*failure);
        }
    }

    std::int64_t number_;
    bool full_;
    StoredProbes stored_;
    GoldenMap expected_;
    std::set<std::string> failed_;
    std::size_t store_matches_ = 0;
    std::int64_t p0_ = 0;
    std::int64_t p1_ = 0;
    std::int64_t p1b_ = 0;
    bool prepass_ = false;
};

// Takes the passes of the current step to the end, as run_driver_test.cpp does: begin_pass and
// end_pass until end_pass reports the last one.
void run_passes(RunDriver& driver) {
    for (;;) {
        static_cast<void>(driver.begin_pass());
        if (!driver.end_pass()) {
            break;
        }
    }
}

// Replays one run and checks each of its records as the driver writes it, the pre-pass decision
// each step stores, and how the run ends; returns the number of records that matched BASIC's
// stored probe files. The run's inputs come from the reference store when it holds the run (its
// work directory), else from the repository.
std::size_t replay_run(PlanRun const& source, PlanMode const& mode, fs::path const& repo,
                       std::map<std::int64_t, gef::test::PlanFile> const& files,
                       data::TableSet const& tables, GoldenMap const& golden) {
    INFO("run " + std::to_string(source.number) + " " + source.capture + " " + source.run_dir);
    gef::test::RunRoot const run_root{source, repo, files, "m6-setup"};
    std::optional<fs::path> const& stored = run_root.stored();
    WorkDir const workdir{run_root.root()};
    ProcessState process{tables};
    std::vector<std::string> parameter_console;
    gef::test::start_up(process, workdir, parameter_console);
    // start_up leaves bfilein at -1 (GEF.bas:1821-1822); the batch loop starts at 0, as in
    // run_driver_test.cpp.
    process.bfilein = 0;
    CorpusProbes probes{source.number, mode.full, golden,
                        StoredProbes{.p0 = read_stored(stored, "P0"),
                                     .p1 = read_stored(stored, "P1"),
                                     .p1b = read_stored(stored, "P1b")}};
    process.probes = &probes;
    BatchSetup stages;
    RunDriver driver{process, workdir, stages};
    std::string exit;
    try {
        while (driver.next_step()) {
            // GEF.bas:3967-3972: the decision the step keeps is the one probe P1b saw.
            StepState const& step = driver.step();
            CHECK(step.prepass == probes.last_prepass());
            CHECK(step.bmulti == (probes.last_prepass() ? 1 : 0));
            if (mode.full) {
                run_passes(driver);
            }
        }
        exit = gef::test::describe_end(driver.end());
    } catch (gef::params::GefHangs const&) {
        // BASIC never ends here; the records written so far are still checked below.
        exit = "hang";
    }
    CHECK(exit == mode.exit);
    GoldenMap const& unreached = probes.unreached();
    if (!unreached.empty()) {
        auto const& [number, probe, rec] = unreached.begin()->first;
        FAIL_CHECK(std::to_string(unreached.size()) + " golden records of run " +
                   std::to_string(number) + " were not written, the first " + probe + " record " +
                   std::to_string(rec));
    }
    return probes.store_matches();
}

} // namespace

TEST_CASE("run: every set-up of the M6 captures equals BASIC's P0, P1 and P1b", "[T1][run]") {
    gef::test::Plan const sources =
        gef::test::read_plan(gef::test::read_lines(gef::test::golden_file("m6-p0", "plan.txt")));
    std::map<std::int64_t, PlanMode> const modes = gef::test::read_plan_modes(
        gef::test::read_lines(gef::test::golden_file("m6-plan", "plan.txt")));
    GoldenMap const golden =
        read_golden(gef::test::read_lines(gef::test::golden_file("m6-p0", "fingerprints.txt")),
                    gef::test::read_lines(gef::test::golden_file("m6-setup", "fingerprints.txt")));
    fs::path const repo{GEF_TEST_REPO_DIR};
    data::TableSet const tables = data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    gef::test::ScopedDir const scratch{gef::test::process_scratch_root("m6-setup")};

    std::size_t replayed = 0;
    std::size_t store_matches = 0;
    for (PlanRun const& source : sources.runs) {
        auto const mode = modes.find(source.number);
        if (mode == modes.end() || mode->second.capture != source.capture ||
            mode->second.run_dir != source.run_dir) {
            FAIL_CHECK("run " + std::to_string(source.number) + " is not the same run in m6-plan");
            continue;
        }
        if (!gef::test::store_run(source).has_value() &&
            !gef::test::replayable(source, sources.files, repo)) {
            continue;
        }
        ++replayed;
        try {
            store_matches += replay_run(source, mode->second, repo, sources.files, tables, golden);
        } catch (std::exception const& error) {
            FAIL_CHECK("run " + std::to_string(source.number) + " aborted: " + error.what());
        }
    }
    if (replayed < sources.runs.size()) {
        WARN(std::to_string(sources.runs.size() - replayed) + " of " +
             std::to_string(sources.runs.size()) +
             " runs are not replayed: the store lacks them and a source they copy is absent "
             "from the repository");
    }
    if (store_matches == 0) {
        WARN("no record was compared with BASIC's stored probe files: the store lacks the runs");
    }
}
