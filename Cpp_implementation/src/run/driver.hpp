// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The control flow of GEF's batch mode (M6.2, MILESTONE_6_PLAN.md D5): BASIC's loops and GoTos
// from file.in detection (GEF.bas:1821) to the end of the program (15669), as a state machine
// that stops at every energy step once its set-up is done. The caller then runs the step body
// (pre-pass, passes, events, writers: M9-M13) and asks for the next step; with an empty step
// body the driver does what the harness's GEF_SETUP_ONLY build does.
//
// Not ported (vision §3): the dialogue and GUI (a working directory without file.in), the ctl/
// coordination (await, thread.ctl, sync.ctl; done.ctl is kept in memory, D2), plotting.

#pragma once

#include "run/state.hpp"
#include "run/workdir.hpp"

#include <cstdint>

namespace gef::run {

// Why the run is over.
enum class RunEnd : std::uint8_t {
    None,         // not over
    Finished,     // the last file was done (GEF.bas:15613-15669: "GEF is terminated.")
    EndStatement, // a `Sleep : End` after an error message
    FitBackEdge,  // fit mode without the end of NITER: `GoTo Nextfitloop` (15610), M16
};

// One pass of the error analysis (GEF.bas:4811 calcstart, 5055-5091).
struct PassInfo {
    std::int64_t i_error = 0;
    std::uint8_t b_error_analysis = 0;
    std::int64_t n_error_max = 0;
    std::int64_t nevttot = 0;
};

class RunDriver {
public:
    // `process` holds the state after start-up (tables, Parameters.bas and
    // ParameterManipulation.mac, the initial widths: GEF.bas:1015-1017, 1347-1394).
    RunDriver(ProcessState& process, WorkDir workdir);

    // Runs until the next energy step is set up (the point of probes P1 and P1b) and returns
    // true, or until the run is over and returns false (end() says why). Calling it again
    // without begin_pass() leaves the step as the GEF_SETUP_ONLY build does (`Continue For`).
    // Throws params::GefHangs where BASIC never ends; std::runtime_error without file.in.
    bool next_step();

    // GEF.bas:4805-4809 at the first pass of a step, then 5055-5091 (pass header and event
    // count). Valid after next_step() returned true.
    PassInfo begin_pass();

    // GEF.bas:15527-15551 after a pass: true when another pass follows (`GoTo calcstart`).
    bool end_pass();

    [[nodiscard]] RunEnd end() const noexcept { return end_; }
    [[nodiscard]] ProcessState& process() noexcept { return *process_; }
    [[nodiscard]] InputRoundState const& round() const noexcept { return round_; }
    [[nodiscard]] SequenceFileState const& file() const noexcept { return file_; }
    [[nodiscard]] StepState const& step() const noexcept { return step_; }

private:
    // Where next_step() resumes.
    enum class Resume : std::uint8_t {
        Start,    // GEF.bas:1821, not yet run
        NextStep, // after a step: `Next I_E_step`
    };

    ProcessState* process_;
    WorkDir workdir_;
    InputRoundState round_;
    SequenceFileState file_;
    StepState step_;
    RunEnd end_ = RunEnd::None;
    Resume resume_ = Resume::Start;
    bool pass_started_ = false;
};

} // namespace gef::run
