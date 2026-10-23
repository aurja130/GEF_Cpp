// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// M6.2: the run driver against the BASIC runs of the M6 captures. The set-up stages (M6.3,
// M6.4) are replaced by ReplayStages, which answers each stage call with what BASIC's stdout
// shows that stage decided (tests/golden/m6-plan, harness/plan_golden.py): the driver's own
// decisions (file, line, covariance and step loops, done.ctl, U_Valid, Emode, N_E_steps, the
// step schedule, the restart, the pass schedule, the end of the run) are what is checked.

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "params/parameter_files.hpp"
#include "run/driver.hpp"
#include "run/state.hpp"
#include "run/workdir.hpp"
#include "support/golden.hpp"
#include "support/probe_dump.hpp"
#include "support/run_replay.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <bit>
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
#include <utility>
#include <vector>

namespace data = gef::data;
namespace fs = std::filesystem;

namespace {

using gef::run::Flow;
using gef::run::InputRoundState;
using gef::run::ProcessState;
using gef::run::RunDriver;
using gef::run::RunEnd;
using gef::run::SequenceFileState;
using gef::run::SetupStages;
using gef::run::StepState;
using gef::run::WorkDir;
using gef::test::plan_check;
using gef::test::PlanRun;
using gef::test::ProbeDump;
using gef::test::ScopedDir;
using gef::test::split_fields;
using gef::test::to_int;

// ---- The golden m6-plan (harness/plan_golden.py) ----------------------------------------------

// One set-up stage call BASIC made, and what it decided.
struct StageEvent {
    enum class Kind : std::uint8_t { System, Step };

    Kind kind = Kind::System;
    std::string outcome; // system: ok, unbound; step: ok, restart, end
    bool has_cn = false; // z and a are known (all but `step restart`)
    std::int64_t z = 0;
    std::int64_t a = 0;
    std::uint64_t fenhance_bits = 0; // `step ok`: Fenhance after GEF.bas:3922 (probe P1b)
};

struct DriverRun {
    std::int64_t number = 0;
    std::string capture;
    std::string run_dir;
    bool full = false; // passes ran (no GEF_SETUP_ONLY)
    std::vector<StageEvent> events;
    std::vector<std::string> pass_lines; // decoded
    std::int64_t p1_records = 0;
    std::uint64_t p1_fnv = 0;
    std::string exit; // terminated, end, hang
};

struct DriverPlan {
    std::vector<std::string> names; // the P1 variables the driver owns, in dump order
    std::vector<DriverRun> runs;
};

StageEvent read_system_event(std::vector<std::string_view> const& fields) {
    plan_check(fields.size() == 4, "m6-plan: bad system line");
    StageEvent event;
    event.kind = StageEvent::Kind::System;
    event.has_cn = true;
    event.z = to_int(fields.at(1));
    event.a = to_int(fields.at(2));
    event.outcome = std::string(fields.at(3));
    plan_check(event.outcome == "ok" || event.outcome == "unbound", "m6-plan: bad system outcome");
    return event;
}

StageEvent read_step_event(std::vector<std::string_view> const& fields) {
    plan_check(fields.size() >= 2, "m6-plan: bad step line");
    StageEvent event;
    event.kind = StageEvent::Kind::Step;
    event.outcome = std::string(fields.at(1));
    if (event.outcome == "restart") {
        plan_check(fields.size() == 2, "m6-plan: bad step restart line");
        return event;
    }
    bool const ok = event.outcome == "ok";
    plan_check(ok ? fields.size() == 5 : (event.outcome == "end" && fields.size() == 4),
               "m6-plan: bad step line");
    event.has_cn = true;
    event.z = to_int(fields.at(2));
    event.a = to_int(fields.at(3));
    if (ok) {
        event.fenhance_bits = gef::test::parse_hex(fields.at(4));
    }
    return event;
}

// Reads the lines of one run block after its `run` line.
void read_run_line(std::vector<std::string_view> const& fields, DriverRun& run) {
    std::string_view const kind = fields.front();
    if (kind == "mode") {
        plan_check(fields.size() == 2, "m6-plan: bad mode line");
        run.full = fields.at(1) == "full";
    } else if (kind == "system") {
        run.events.push_back(read_system_event(fields));
    } else if (kind == "step") {
        run.events.push_back(read_step_event(fields));
    } else if (kind == "pass") {
        plan_check(fields.size() == 2, "m6-plan: bad pass line");
        run.pass_lines.push_back(gef::test::decode_hex(fields.at(1)));
    } else if (kind == "p1") {
        plan_check(fields.size() == 3, "m6-plan: bad p1 line");
        run.p1_records = to_int(fields.at(1));
        run.p1_fnv = gef::test::parse_hex(fields.at(2));
    } else if (kind == "exit") {
        plan_check(fields.size() == 2, "m6-plan: bad exit line");
        run.exit = std::string(fields.at(1));
    } else {
        throw std::runtime_error("m6-plan: unknown line kind '" + std::string(kind) + "'");
    }
}

// The run open at a line of the plan; `message` is thrown when no run is open.
DriverRun& open_run(std::optional<DriverRun>& open, std::string const& message) {
    if (!open.has_value()) {
        throw std::runtime_error(message);
    }
    return *open;
}

DriverPlan read_driver_plan(std::vector<std::string> const& lines) {
    DriverPlan plan;
    std::optional<DriverRun> open;
    for (std::string const& line : lines) {
        std::vector<std::string_view> const fields = split_fields(line);
        if (fields.empty() || fields.front().starts_with('#')) {
            continue;
        }
        std::string_view const kind = fields.front();
        if (kind == "names") {
            for (std::size_t i = 1; i < fields.size(); ++i) {
                plan.names.emplace_back(fields.at(i));
            }
        } else if (kind == "run") {
            plan_check(!open.has_value() && fields.size() == 4,
                       "m6-plan: bad run line '" + line + "'");
            open.emplace();
            open->number = to_int(fields.at(1));
            open->capture = std::string(fields.at(2));
            open->run_dir = std::string(fields.at(3));
        } else if (kind == "endrun") {
            plan.runs.push_back(std::move(open_run(open, "m6-plan: endrun without run")));
            open.reset();
        } else {
            read_run_line(fields, open_run(open, "m6-plan: '" + line + "' outside a run"));
        }
    }
    plan_check(!open.has_value(), "m6-plan: run without endrun");
    plan_check(!plan.names.empty(), "m6-plan: no names line");
    return plan;
}

// ---- The set-up stages, replayed from BASIC ---------------------------------------------------

// The driver called a stage BASIC did not call at that point.
class StageMismatch : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

class ReplayStages final : public SetupStages {
public:
    explicit ReplayStages(std::vector<StageEvent> const& events) : events_{&events} {}

    // GEF.bas:2555, 2575-2624 (M6.3): FitparRead and the widths. No driver decision reads them.
    void begin_round(ProcessState& /*process*/, WorkDir const& /*workdir*/) override {}

    Flow begin_system(ProcessState& process, InputRoundState& /*round*/,
                      SequenceFileState& /*file*/) override {
        StageEvent const& event = take(StageEvent::Kind::System, process);
        return event.outcome == "unbound" ? Flow::NextLine : Flow::Proceed;
    }

    Flow set_up_step(ProcessState& process, InputRoundState& /*round*/, SequenceFileState& /*file*/,
                     StepState& /*step*/, WorkDir const& /*workdir*/) override {
        StageEvent const& event = take(StageEvent::Kind::Step, process);
        if (event.outcome == "restart") {
            return Flow::Restart;
        }
        if (event.outcome == "end") {
            return Flow::End;
        }
        // GEF.bas:3695 and 3922 set Fenhance, which the pass schedule and the next system
        // line's done.ctl record read.
        process.fenhance = std::bit_cast<double>(event.fenhance_bits);
        return Flow::Proceed;
    }

    [[nodiscard]] std::size_t consumed() const noexcept { return next_; }

private:
    StageEvent const& take(StageEvent::Kind kind, ProcessState const& process) {
        std::string const called = kind == StageEvent::Kind::System ? "system" : "step";
        std::string const call = "set-up call " + std::to_string(next_ + 1) + " (" + called + ")";
        if (next_ >= events_->size()) {
            throw StageMismatch(call + ": BASIC made only " + std::to_string(events_->size()) +
                                " set-up calls");
        }
        StageEvent const& event = events_->at(next_);
        if (event.kind != kind) {
            throw StageMismatch(call + ": BASIC set up a " +
                                (event.kind == StageEvent::Kind::System ? "system" : "step") +
                                " here");
        }
        if (event.has_cn && (event.z != process.p_z_cn || event.a != process.p_a_cn)) {
            throw StageMismatch(call + ": the driver's CN is Z=" + std::to_string(process.p_z_cn) +
                                " A=" + std::to_string(process.p_a_cn) + ", BASIC's Z=" +
                                std::to_string(event.z) + " A=" + std::to_string(event.a));
        }
        ++next_;
        return event;
    }

    std::vector<StageEvent> const* events_;
    std::size_t next_ = 0;
};

// ---- The driver's part of probe P1 ------------------------------------------------------------

// The P1 lines (harness/PROBES.md) of the variables in `names` that the driver sets, as BASIC
// writes them before GEF.bas:3882. E_EXC_TRUE is BASIC's copy of P_E_exc before the isomer energy
// is added (3549), i.e. the energy of the step schedule (3449-3497).
void dump_driver_p1(RunDriver& driver, std::int64_t rec, std::vector<std::string> const& names,
                    std::vector<std::string>& out) {
    ProcessState const& p = driver.process();
    InputRoundState const& round = driver.round();
    SequenceFileState const& file = driver.file();
    ProbeDump dump("P1", "step=" + std::to_string(p.i_e_step) +
                             " pass=- bin=- rec=" + std::to_string(rec));
    dump.scalar("Iline", p.iline);
    dump.scalar("Ifilein", round.ifilein);
    dump.scalar("I_Double_Covar", p.i_double_covar);
    dump.scalar("N_Double_Covar", p.n_double_covar);
    dump.scalar("I_E_step", p.i_e_step);
    dump.scalar("N_E_steps", p.n_e_steps);
    dump.scalar("N_E_values", round.n_e_values);
    dump.scalar("I_E_iso", p.i_e_iso);
    dump.scalar("Bfilein", std::int64_t{p.bfilein});
    dump.scalar("B_ENDF", std::int64_t{file.b_endf});
    dump.scalar("B_Random_on", std::int64_t{file.b_random_on});
    dump.scalar("B_Error_On", std::int64_t{file.b_error_on});
    dump.scalar("I_Error", p.i_error);
    dump.scalar("En_min", p.en_min);
    dump.scalar("En_max", p.en_max);
    dump.scalar("P_Z_CN", p.p_z_cn);
    dump.scalar("P_A_CN", p.p_a_cn);
    dump.scalar("P_I_rms_CN", p.p_i_rms_cn);
    dump.scalar("P_Z_CN_Double", p.p_z_cn_double);
    dump.scalar("P_A_CN_Double", p.p_a_cn_double);
    dump.scalar("P_E_exc_Double", p.p_e_exc_double);
    dump.scalar("E_EXC_TRUE", p.p_e_exc);
    dump.scalar("Emode", p.params.emode);
    for (std::string const& name : names) {
        std::vector<std::string> const& lines = dump.lines(name);
        out.insert(out.end(), lines.begin(), lines.end());
    }
}

// BASIC's P1.txt lines of the variables in `names`, in file order.
std::vector<std::string> basic_p1_lines(fs::path const& path,
                                        std::vector<std::string> const& names) {
    std::set<std::string, std::less<>> const wanted(names.begin(), names.end());
    std::vector<std::string> lines;
    for (std::string const& line : gef::test::read_lines(path)) {
        std::vector<std::string_view> const fields = split_fields(line);
        if (fields.size() >= 6 && fields.at(0) == "P1" && wanted.contains(fields.at(5))) {
            lines.push_back(line);
        }
    }
    return lines;
}

// ---- One run ----------------------------------------------------------------------------------

std::string describe_end(RunEnd end) {
    switch (end) {
    case RunEnd::Finished:
        return "terminated";
    case RunEnd::EndStatement:
        return "end";
    case RunEnd::FitBackEdge:
        return "fit back edge";
    case RunEnd::Hang:
        return "hang";
    case RunEnd::None:
        break;
    }
    return "not over";
}

// What the driver did in one run.
struct DriverResult {
    std::int64_t steps = 0;
    std::vector<std::string> p1_lines;
    std::vector<std::string> pass_lines;
    std::string exit;
};

// The passes of one step, as a full run makes them: the console lines each begin_pass() printed.
void run_passes(RunDriver& driver, std::vector<std::string>& pass_lines) {
    ProcessState& process = driver.process();
    for (;;) {
        std::size_t const mark = process.console.text().size();
        static_cast<void>(driver.begin_pass());
        std::string_view const printed = std::string_view{process.console.text()}.substr(mark);
        for (std::string_view const line : gef::test::split_lines(printed)) {
            pass_lines.emplace_back(line);
        }
        if (!driver.end_pass()) {
            break;
        }
    }
}

DriverResult drive(RunDriver& driver, DriverRun const& run, std::vector<std::string> const& names) {
    DriverResult result;
    try {
        while (driver.next_step()) {
            ++result.steps;
            dump_driver_p1(driver, result.steps, names, result.p1_lines);
            if (run.full) {
                run_passes(driver, result.pass_lines);
            }
        }
        result.exit = describe_end(driver.end());
    } catch (gef::params::GefHangs const&) {
        result.exit = "hang";
    }
    return result;
}

// The first line of `printed` that is not found, in order, among the lines of BASIC's stdout
// from `File 'file.in' found.` on (MILESTONE_6_PLAN.md D3), or nullopt.
std::optional<std::string> missing_console_line(std::string const& basic,
                                                std::string const& printed) {
    std::size_t const start = gef::test::find_line_start(basic, "File 'file.in' found.", 0);
    if (start == std::string::npos) {
        return "the D3 start line 'File 'file.in' found.'";
    }
    std::vector<std::string_view> const expected =
        gef::test::split_lines(std::string_view{basic}.substr(start));
    std::size_t next = 0;
    for (std::string_view const line : gef::test::split_lines(printed)) {
        while (next < expected.size() && expected.at(next) != line) {
            ++next;
        }
        if (next == expected.size()) {
            return std::string(line);
        }
        ++next;
    }
    return std::nullopt;
}

// Lines only the parser and the driver print (GEF.bas:2700, 2771, 3073 and 3153, 3190, 3207,
// 3271-3272, 3279 and 2906, 2979, 15665-15666): in a run they must occur as often in the C++
// console as in BASIC's stdout. The ordered subsequence check alone would miss a line the C++
// leaves out, e.g. a skipped restart.
constexpr std::array<std::string_view, 10> driver_markers{
    "File 'file.in' found.",
    "Sequence of nuclei given in ",
    "<E> Calculation of correlations between two systems is supported",
    " skipped (already in done.ctl).",
    " out of supported range, will be skipped.",
    "<W> ENDF output not available for option 'ES'.",
    "    ENDF output suspended.",
    "<E> Option ",
    "GEF is terminated.",
    "Press ENTER to close this window!",
};

// The last `count` lines of BASIC's stdout and of the C++ console, when the run ended in text
// the parser or the driver prints: its exit text, an End or a hang in the input. A run that ended
// in a stage (`step end`) or in a step body (a hang in a full run) ends in text M6.2 does not
// print.
std::optional<std::string> tail_difference(DriverRun const& run, std::string const& basic,
                                           std::string const& printed) {
    bool const stage_end = !run.events.empty() &&
                           run.events.back().kind == StageEvent::Kind::Step &&
                           run.events.back().outcome == "end";
    std::size_t count = 0;
    if (run.exit == "terminated") {
        count = 2;
    } else if ((run.exit == "end" && !stage_end) || (run.exit == "hang" && !run.full)) {
        count = 1;
    }
    std::vector<std::string_view> const expected = gef::test::split_lines(basic);
    std::vector<std::string_view> const actual = gef::test::split_lines(printed);
    if (count > expected.size() || count > actual.size()) {
        return "fewer than " + std::to_string(count) + " lines";
    }
    for (std::size_t i = 1; i <= count; ++i) {
        std::string_view const want = expected.at(expected.size() - i);
        std::string_view const got = actual.at(actual.size() - i);
        if (want != got) {
            return "line " + std::to_string(i) + " from the end: BASIC '" + std::string(want) +
                   "', C++ '" + std::string(got) + "'";
        }
    }
    return std::nullopt;
}

std::size_t count_lines_with(std::string_view text, std::string_view marker) {
    std::size_t count = 0;
    for (std::string_view const line : gef::test::split_lines(text)) {
        if (line.contains(marker)) {
            ++count;
        }
    }
    return count;
}

// The first driver marker whose count differs between BASIC's stdout and the C++ console.
std::optional<std::string> marker_count_difference(std::string const& basic,
                                                   std::string const& printed) {
    for (std::string_view const marker : driver_markers) {
        std::size_t const want = count_lines_with(basic, marker);
        std::size_t const got = count_lines_with(printed, marker);
        if (want != got) {
            return "'" + std::string(marker) + "': BASIC " + std::to_string(want) + ", C++ " +
                   std::to_string(got);
        }
    }
    return std::nullopt;
}

void check_run(DriverRun const& run, PlanRun const& source, fs::path const& repo,
               std::map<std::int64_t, gef::test::PlanFile> const& files,
               data::TableSet const& tables, std::vector<std::string> const& names) {
    INFO("run " + std::to_string(run.number) + " " + run.capture + " " + run.run_dir);
    std::optional<fs::path> const stored = gef::test::store_run(source);
    std::optional<ScopedDir> scratch;
    fs::path root;
    if (stored.has_value()) {
        root = *stored / "work";
    } else {
        root = gef::test::process_scratch_root("m6-plan") / ("run-" + std::to_string(run.number));
        scratch.emplace(root);
        gef::test::fill_scratch(source, repo, files, root);
    }
    WorkDir const workdir{root};

    ProcessState process{tables};
    std::vector<std::string> parameter_console;
    gef::test::start_up(process, workdir, parameter_console);
    process.bfilein = 0; // the driver finds file.in itself (GEF.bas:1821-1822)
    ReplayStages stages{run.events};
    RunDriver driver{process, workdir, stages};

    DriverResult result;
    try {
        result = drive(driver, run, names);
    } catch (StageMismatch const& mismatch) {
        FAIL_CHECK(std::string("stage calls differ from BASIC's: ") + mismatch.what());
        return;
    }

    CHECK(result.exit == run.exit);
    CHECK(stages.consumed() == run.events.size());
    CHECK(result.steps == run.p1_records);
    CHECK(result.pass_lines == run.pass_lines);
    gef::test::ProbeFingerprint const p1 = gef::test::fingerprint_lines(result.p1_lines);
    if (p1.fnv != run.p1_fnv) {
        std::string message = "the driver's P1 variables differ from BASIC's";
        if (stored.has_value() && fs::is_regular_file(*stored / "work/probes/P1.txt")) {
            std::vector<std::string> const basic =
                basic_p1_lines(*stored / "work/probes/P1.txt", names);
            std::size_t i = 0;
            while (i < basic.size() && i < result.p1_lines.size() &&
                   basic.at(i) == result.p1_lines.at(i)) {
                ++i;
            }
            message += ": first at line " + std::to_string(i + 1) + ", BASIC '" +
                       (i < basic.size() ? basic.at(i) : "<none>") + "', C++ '" +
                       (i < result.p1_lines.size() ? result.p1_lines.at(i) : "<none>") + "'";
        }
        FAIL_CHECK(message);
    }
    if (stored.has_value()) {
        std::string const basic = gef::test::read_bytes(*stored / "stdout.log");
        if (auto const missing = missing_console_line(basic, process.console.text());
            missing.has_value()) {
            FAIL_CHECK("C++ console line not in BASIC's stdout (in order): '" + *missing + "'");
        }
        if (auto const difference = marker_count_difference(basic, process.console.text());
            difference.has_value()) {
            FAIL_CHECK("lines with " + *difference);
        }
        if (auto const difference = tail_difference(run, basic, process.console.text());
            difference.has_value()) {
            FAIL_CHECK("the end of the console differs from BASIC's stdout: " + *difference);
        }
    }
}

} // namespace

TEST_CASE("run: the driver repeats BASIC's files, lines, systems, steps and passes", "[T1][run]") {
    DriverPlan const plan =
        read_driver_plan(gef::test::read_lines(gef::test::golden_file("m6-plan", "plan.txt")));
    gef::test::Plan const sources =
        gef::test::read_plan(gef::test::read_lines(gef::test::golden_file("m6-p0", "plan.txt")));
    std::map<std::int64_t, PlanRun const*> by_number;
    for (PlanRun const& run : sources.runs) {
        by_number.emplace(run.number, &run);
    }
    fs::path const repo{GEF_TEST_REPO_DIR};
    data::TableSet const tables = data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    ScopedDir const scratch{gef::test::process_scratch_root("m6-plan")};

    std::size_t replayed = 0;
    for (DriverRun const& run : plan.runs) {
        auto const source = by_number.find(run.number);
        if (source == by_number.end() || source->second->capture != run.capture ||
            source->second->run_dir != run.run_dir) {
            FAIL_CHECK("run " + std::to_string(run.number) + " is not the same run in m6-p0");
            continue;
        }
        if (!gef::test::store_run(*source->second).has_value() &&
            !gef::test::replayable(*source->second, sources.files, repo)) {
            continue;
        }
        ++replayed;
        try {
            check_run(run, *source->second, repo, sources.files, tables, plan.names);
        } catch (std::exception const& error) {
            FAIL_CHECK("run " + std::to_string(run.number) + " aborted: " + error.what());
        }
    }
    if (replayed < plan.runs.size()) {
        WARN(std::to_string(plan.runs.size() - replayed) + " of " +
             std::to_string(plan.runs.size()) +
             " runs are not replayed: the store lacks them and a source they copy is absent "
             "from the repository");
    }
}

namespace {

// Stages that set up every system, and restart at every step of a CN in `restart_cns`
// (Z * 1000 + A; every step when it is empty): a missing isomer. A step that proceeds sets
// Fenhance as BASIC's set-up does (GEF.bas:3695, 3922).
class RestartStages final : public SetupStages {
public:
    explicit RestartStages(std::set<std::int64_t> restart_cns = {})
        : restart_cns_{std::move(restart_cns)} {}

    void begin_round(ProcessState& /*process*/, WorkDir const& /*workdir*/) override { ++rounds_; }
    Flow begin_system(ProcessState& /*process*/, InputRoundState& /*round*/,
                      SequenceFileState& /*file*/) override {
        return Flow::Proceed;
    }
    Flow set_up_step(ProcessState& process, InputRoundState& /*round*/, SequenceFileState& /*file*/,
                     StepState& /*step*/, WorkDir const& /*workdir*/) override {
        if (restart_cns_.empty() ||
            restart_cns_.contains((process.p_z_cn * 1000) + process.p_a_cn)) {
            return Flow::Restart;
        }
        process.fenhance = process.fenhance_global;
        if (process.fenhance == 0.0) {
            process.fenhance = 1.0;
        }
        return Flow::Proceed;
    }

    [[nodiscard]] std::int64_t rounds() const noexcept { return rounds_; }

private:
    std::set<std::int64_t> restart_cns_;
    std::int64_t rounds_ = 0;
};

// Stages that set up every system and step with Fenhance 1.
class PlainStages final : public SetupStages {
public:
    void begin_round(ProcessState& /*process*/, WorkDir const& /*workdir*/) override {}
    Flow begin_system(ProcessState& /*process*/, InputRoundState& /*round*/,
                      SequenceFileState& /*file*/) override {
        return Flow::Proceed;
    }
    Flow set_up_step(ProcessState& process, InputRoundState& /*round*/, SequenceFileState& /*file*/,
                     StepState& /*step*/, WorkDir const& /*workdir*/) override {
        process.fenhance = 1.0;
        return Flow::Proceed;
    }
};

// A scratch working directory with file.in and in/a.in.
struct SmallRun {
    SmallRun(std::string_view name, std::string const& filein, std::string const& sequence)
        : root{gef::test::process_scratch_root("m6-driver") / std::string(name)}, dir{root} {
        static_cast<void>(fs::create_directories(root / "in"));
        gef::test::write_bytes(root / "file.in", filein);
        gef::test::write_bytes(root / "in" / "a.in", sequence);
    }

    fs::path root;
    ScopedDir dir;
};

} // namespace

TEST_CASE("run: a restart that repeats its round hangs, as in BASIC", "[run]") {
    data::TableSet const tables = data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    ScopedDir const scratch{gef::test::process_scratch_root("m6-driver")};

    SECTION("fit mode: done.ctl is not consulted, every round is the same") {
        SmallRun const small{"fit", "FIT\nNITER(1)\n\"in/a.in\"\nEND\n",
                             " 1\n0.0253E-6\n 92, 236, \"EN\"\n"};
        ProcessState process{tables};
        RestartStages stages;
        RunDriver driver{process, WorkDir{small.root}, stages};
        CHECK_THROWS_AS(driver.next_step(), gef::params::GefHangs);
        CHECK(stages.rounds() == 2);
        CHECK(driver.end() == RunEnd::Hang);
        CHECK_FALSE(driver.next_step());
    }
    SECTION("Fenhance 0.1: the done.ctl record never matches") {
        SmallRun const small{"fen01", "\"in/a.in\"\nEND\n", " 0.1\n0.0253E-6\n 92, 236, \"EN\"\n"};
        ProcessState process{tables};
        RestartStages stages;
        RunDriver driver{process, WorkDir{small.root}, stages};
        CHECK_THROWS_AS(driver.next_step(), gef::params::GefHangs);
        CHECK(stages.rounds() == 2);
    }
    SECTION("Fenhance 1: the second round skips the line and the run ends") {
        SmallRun const small{"fen1", "\"in/a.in\"\nEND\n", " 1\n0.0253E-6\n 92, 236, \"EN\"\n"};
        ProcessState process{tables};
        RestartStages stages;
        RunDriver driver{process, WorkDir{small.root}, stages};
        CHECK_FALSE(driver.next_step());
        CHECK(driver.end() == RunEnd::Finished);
        CHECK(stages.rounds() == 2);
    }
    SECTION("Fenhance 1, two missing isomers: each round adds a record, the third one ends") {
        SmallRun const small{"two", "\"in/a.in\"\nEND\n",
                             " 1\n0.0253E-6\n 92, 236, \"EN\"\n 94, 240, \"EN\"\n"};
        ProcessState process{tables};
        RestartStages stages;
        RunDriver driver{process, WorkDir{small.root}, stages};
        CHECK_FALSE(driver.next_step());
        CHECK(driver.end() == RunEnd::Finished);
        CHECK(stages.rounds() == 3);
    }
    SECTION("Fenhance 0: the restarting line's records differ in Fenhance, the third round ends") {
        // Round 1 registers line 2 with the Fenhance its step left (1, GEF.bas:3922), round 2
        // with the file's 0, which round 3 matches.
        SmallRun const small{"fen0", "\"in/a.in\"\nEND\n",
                             " 0\n0.0253E-6\n 92, 236, \"EN\"\n 94, 240, \"EN\"\n"};
        ProcessState process{tables};
        RestartStages stages{{94240}};
        RunDriver driver{process, WorkDir{small.root}, stages};
        CHECK(driver.next_step());
        CHECK_FALSE(driver.next_step());
        CHECK(driver.end() == RunEnd::Finished);
        CHECK(stages.rounds() == 3);
    }
    SECTION(
        "fit mode, Emode left by the restarting line: the next round ends at the E/spin check") {
        // Round 1 parses a.in with the start-up Emode 1, so its E/spin line passes; the EN9 line of
        // b.in restarts and leaves Emode 2, so round 2's parse of a.in ends (GEF.bas:2801).
        SmallRun const small{"fit-stale", "FIT\n\"in/a.in\"\n\"in/b.in\"\nEND\n",
                             " 1\n5/10\n 92, 236, \"GS\"\n"};
        gef::test::write_bytes(small.root / "in" / "b.in", " 1\n0\n 95, 243, \"EN9\"\n");
        ProcessState process{tables};
        RestartStages stages{{95243}};
        RunDriver driver{process, WorkDir{small.root}, stages};
        CHECK(driver.next_step());
        CHECK_FALSE(driver.next_step());
        CHECK(driver.end() == RunEnd::EndStatement);
        CHECK(stages.rounds() == 2);
        CHECK(process.console.text().ends_with("Press Enter key to leave GEF!\n"));
    }
    SECTION("rounds that differ only in the stale Emode are not the same round") {
        // Capture edge-l_restart_emode: the starts of rounds 4 and 5 hold the same done.ctl records
        // and differ in Emode (1, 2); round 5 ends at the E/spin check of e.in (GEF.bas:2801).
        SmallRun const small{"emode", "\"in/a.in\"\n\"in/e.in\"\n\"in/b.in\"\nEND\n",
                             " 0\n5\n 92, 236, \"FC\"\n 94, 240, \"FC\"\n 95, 242, \"IS9\"\n"};
        gef::test::write_bytes(small.root / "in" / "e.in", " 1\n5/10\n 90, 232, \"FC\"\n");
        gef::test::write_bytes(small.root / "in" / "b.in", " 0.1\n5\n 95, 243, \"EN9\"\n");
        ProcessState process{tables};
        RestartStages stages{{95242, 95243}};
        RunDriver driver{process, WorkDir{small.root}, stages};
        std::int64_t steps = 0;
        while (driver.next_step()) {
            ++steps;
        }
        CHECK(steps == 4);
        CHECK(driver.end() == RunEnd::EndStatement);
        CHECK(stages.rounds() == 5);
    }
}

TEST_CASE("run: fit mode ends after NITER fit iterations", "[run]") {
    data::TableSet const tables = data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    ScopedDir const scratch{gef::test::process_scratch_root("m6-driver")};
    std::string const sequence = " 1\n0.0253E-6\nFIT(APOST)\n 92, 236, \"EN\"\n";
    auto const end_of = [&](std::string_view name, std::string const& filein) {
        SmallRun const small{name, filein, sequence};
        ProcessState process{tables};
        PlainStages stages;
        RunDriver driver{process, WorkDir{small.root}, stages};
        REQUIRE(driver.next_step());
        CHECK_FALSE(driver.next_step());
        return driver.end();
    };
    CHECK(end_of("niter1", "FIT\nNITER(1)\n\"in/a.in\"\nEND\n") == RunEnd::Finished);
    CHECK(end_of("niter2", "FIT\nNITER(2)\n\"in/a.in\"\nEND\n") == RunEnd::FitBackEdge);
}

TEST_CASE("run: fit mode without the end of NITER takes the fit back edge", "[run]") {
    data::TableSet const tables = data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    ScopedDir const scratch{gef::test::process_scratch_root("m6-driver")};
    SmallRun const small{"back-edge", "FIT\n\"in/a.in\"\nEND\n",
                         " 1\n0.0253E-6\nFIT(APOST)\n 92, 236, \"EN\"\n"};
    ProcessState process{tables};
    PlainStages stages;
    RunDriver driver{process, WorkDir{small.root}, stages};
    REQUIRE(driver.next_step());
    gef::run::PassInfo const pass = driver.begin_pass();
    CHECK(pass.n_error_max == 1);
    CHECK(pass.b_error_analysis == 1);
    CHECK(pass.nevttot == 100000);
    CHECK_FALSE(driver.end_pass());
    CHECK_FALSE(driver.next_step());
    CHECK(driver.end() == RunEnd::FitBackEdge);
    CHECK_FALSE(process.console.text().contains("GEF is terminated."));
}
