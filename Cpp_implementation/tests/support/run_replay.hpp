// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Replaying the BASIC runs of the M6 captures in C++: the run list of the golden m6-p0
// (tests/golden/m6-p0/plan.txt, harness/p0_golden.py), the modes and ends of m6-plan, the working
// directory of a run (the store's work/ directory, or a scratch copy filled from the repository)
// and GEF's start-up. Shared by the run_*_test.cpp files.

#pragma once

#include "run/driver.hpp"
#include "run/state.hpp"
#include "run/workdir.hpp"

#include <cstdint>
#include <filesystem>
#include <map>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace gef::test {

struct PlanFile {
    std::string dest;   // relative to the run's work/ directory
    std::string source; // repository-relative; empty when the plan says `-`
};

struct PlanParse {
    enum class Outcome : std::uint8_t { P0, End, Hang };

    bool restart = false;
    std::int64_t ifilein = 0;
    std::optional<std::int64_t> emode; // nullopt: no probe dumped it before the parse (`-`)
    std::string cfileoutlmd_full;      // decoded bytes
    Outcome outcome = Outcome::End;
    std::int64_t rec = 0; // the record of a `p0=<rec>` outcome
};

struct PlanRun {
    std::int64_t number = 0;
    std::string capture;
    std::string run_dir;
    std::string filein;             // decoded contents of file.in
    std::vector<std::int64_t> work; // ids of the `file` lines copied into work/
    std::vector<PlanParse> parses;
};

struct Plan {
    std::map<std::int64_t, PlanFile> files;
    std::vector<PlanRun> runs;
};

// Throws std::runtime_error(message) unless `ok`.
void plan_check(bool ok, std::string const& message);

// Splits a line on single spaces; empty fields are dropped.
[[nodiscard]] std::vector<std::string_view> split_fields(std::string_view line);

// A decimal integer, optionally negative.
[[nodiscard]] std::int64_t to_int(std::string_view text);

// A hex field of a plan: `-` is empty, otherwise two hex digits per byte.
[[nodiscard]] std::string decode_hex(std::string_view hex);

// tests/golden/m6-p0/plan.txt, read from its lines.
[[nodiscard]] Plan read_plan(std::vector<std::string> const& lines);

// Empties a scratch directory on construction and removes it on destruction.
class ScopedDir {
public:
    explicit ScopedDir(std::filesystem::path path);
    ~ScopedDir();
    ScopedDir(ScopedDir const&) = delete;
    ScopedDir& operator=(ScopedDir const&) = delete;
    ScopedDir(ScopedDir&&) = delete;
    ScopedDir& operator=(ScopedDir&&) = delete;

private:
    void remove();

    std::filesystem::path path_;
};

// This test process's scratch root for one test file: the process id in the name keeps test
// processes apart.
[[nodiscard]] std::filesystem::path process_scratch_root(std::string_view tag);

void write_bytes(std::filesystem::path const& path, std::string const& bytes);
[[nodiscard]] std::string read_bytes(std::filesystem::path const& path);

// A run is replayable from the repository when every file it copies has a source present there.
[[nodiscard]] bool replayable(PlanRun const& run, std::map<std::int64_t, PlanFile> const& files,
                              std::filesystem::path const& repo);

// The run's directory in the reference store, when the store holds it.
[[nodiscard]] std::optional<std::filesystem::path> store_run(PlanRun const& run);

// Fills a scratch work/ directory from the repository: file.in, then each copied source.
void fill_scratch(PlanRun const& run, std::filesystem::path const& repo,
                  std::map<std::int64_t, PlanFile> const& files, std::filesystem::path const& root);

// Start-up as BASIC runs it before file.in is read: Parameters.bas and
// ParameterManipulation.mac (GEF.bas:1015-1017; FitparRead applies Fitpar.dat when present,
// which sets D_Par_Fac and EOscale), then the initial widths (GEF.bas:1347-1394). Sets
// bfilein = -1 (file.in exists, GEF.bas:1821-1822).
void start_up(run::ProcessState& process, run::WorkDir const& workdir,
              std::vector<std::string>& parameter_console);

// The first offset at or after `from` where `prefix` begins a line of `text`, or npos.
[[nodiscard]] std::size_t find_line_start(std::string const& text, std::string_view prefix,
                                          std::size_t from);

// Names the first line where the two texts differ (1-based), or says that only the line endings
// differ.
[[nodiscard]] std::string first_line_difference(std::string_view basic, std::string_view printed);

// The lines of `text` without their '\n'; a final '\n' does not begin another line.
[[nodiscard]] std::vector<std::string_view> split_lines(std::string_view text);

// A run of m6-plan: its capture and run directory, whether its passes are taken (`mode full`) and
// how BASIC's run ended (`exit`).
struct PlanMode {
    std::string capture;
    std::string run_dir;
    bool full = false;
    std::string exit;
};

// tests/golden/m6-plan/plan.txt: `run <n> <capture> <run_dir>`, `mode setup|full`, `exit <how>`,
// `endrun`, by run number. The plan's other lines are not read.
[[nodiscard]] std::map<std::int64_t, PlanMode>
read_plan_modes(std::vector<std::string> const& lines);

// How a C++ run ended, in m6-plan's words (harness/plan_golden.py `_exit_state`).
[[nodiscard]] std::string describe_end(run::RunEnd end);

// The working directory a replayed run reads: the store's work/ when the store holds the run,
// else a scratch directory under process_scratch_root(tag), filled from the repository and
// removed with this object.
class RunRoot {
public:
    RunRoot(PlanRun const& run, std::filesystem::path const& repo,
            std::map<std::int64_t, PlanFile> const& files, std::string_view tag);

    [[nodiscard]] std::filesystem::path const& root() const noexcept { return root_; }
    // The run's directory in the store, when the store holds it.
    [[nodiscard]] std::optional<std::filesystem::path> const& stored() const noexcept {
        return stored_;
    }

private:
    std::optional<std::filesystem::path> stored_;
    std::filesystem::path root_;
    std::optional<ScopedDir> scratch_;
};

// The std::logic_error message of `call`, or "" when it throws none (D10 tests).
template <typename Call>
[[nodiscard]] std::string logic_error_of(Call call) {
    try {
        call();
    } catch (std::logic_error const& error) {
        return error.what();
    }
    return {};
}

} // namespace gef::test
