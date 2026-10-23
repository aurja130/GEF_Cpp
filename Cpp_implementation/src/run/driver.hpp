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
// The set-up of a round, a system and a step (M6.3, M6.4) is reached through SetupStages, so the
// driver's own decisions can be checked on their own (user decision 2026-10-19).
//
// Not ported (vision §3): the dialogue and GUI (a working directory without file.in), the ctl/
// coordination (await, thread.ctl, sync.ctl; done.ctl is kept in memory, D2), plotting.

#pragma once

#include "run/state.hpp"
#include "run/workdir.hpp"

#include <cstdint>
#include <set>
#include <string>
#include <vector>

namespace gef::run {

// The set-up blocks of BASIC's batch loops that the driver runs but does not own. Each reads
// and writes the state it is given; console text goes to ProcessState::console.
class SetupStages {
public:
    SetupStages() = default;
    SetupStages(SetupStages const&) = default;
    SetupStages(SetupStages&&) = default;
    SetupStages& operator=(SetupStages const&) = default;
    SetupStages& operator=(SetupStages&&) = default;
    virtual ~SetupStages() = default;

    // GEF.bas:2555 (FitparRead) and 2575-2624 (the Var_* widths, Clocal), at every pass through
    // Nextfitloop. The driver has already done 2570 (`I_Fitloop = I_Fitloop + 1`), which neither
    // block reads.
    virtual void begin_round(ProcessState& process, WorkDir const& workdir) = 0;

    // GEF.bas:3313-3440, once per pass of `For I_Double_Covar`, after the driver has set the
    // system's CN (3301-3305). Returns Flow::Proceed, or Flow::NextLine where BASIC leaves the
    // system line (`Goto Next_Iline_label`, 3384: unbound CN).
    [[nodiscard]] virtual Flow begin_system(ProcessState& process, InputRoundState& round,
                                            SequenceFileState& file) = 0;

    // GEF.bas:3499-3880 and the run-control lines of 3914-3972, after the driver has set the
    // step's energy and B_Error_On (3444-3497). Returns Flow::Proceed, Flow::Restart (`Goto
    // RepeatInput`, 3567: missing isomer) or Flow::End (`Sleep : End` at 3674-3677, 3836-3839,
    // 3870-3873, after their text).
    [[nodiscard]] virtual Flow set_up_step(ProcessState& process, InputRoundState& round,
                                           SequenceFileState& file, StepState& step,
                                           WorkDir const& workdir) = 0;
};

// Why the run is over.
enum class RunEnd : std::uint8_t {
    None,         // not over
    Finished,     // after the last file (GEF.bas:15613-15669: "GEF is terminated.")
    EndStatement, // a `Sleep : End` after an error message
    FitBackEdge,  // fit mode without the end of NITER: `GoTo Nextfitloop` (15610), M16
    Hang,         // BASIC never ends here: next_step() or end_pass() threw params::GefHangs
};

// One pass of the error analysis (GEF.bas:4811 calcstart, 5055-5091).
struct PassInfo {
    std::int64_t i_error = 0;          // I_Error
    std::uint8_t b_error_analysis = 0; // B_Error_Analysis: 1 perturbed, 0 nominal
    std::int64_t n_error_max = 0;      // N_Error_Max
    std::int64_t nevttot = 0;          // NEVTtot (GEF.bas:5051 Dim As LongInt)
};

class RunDriver {
public:
    // `process` holds the state after start-up (tables, Parameters.bas and
    // ParameterManipulation.mac, the initial widths: GEF.bas:1015-1017, 1347-1394). `process`
    // and `stages` must outlive the driver.
    RunDriver(ProcessState& process, WorkDir workdir, SetupStages& stages);

    // Runs until the next energy step is set up (the point of probes P1 and P1b) and returns
    // true, or until the run is over and returns false (end() says why). Calling it again
    // without begin_pass() leaves the step as the GEF_SETUP_ONLY build does (`Continue For`);
    // once a pass has begun, the passes must run until end_pass() returns false. Throws
    // params::GefHangs where BASIC never ends (the run is then over), std::runtime_error without
    // file.in, and std::logic_error when a stage returns a Flow its BASIC block cannot produce.
    bool next_step();

    // GEF.bas:4805-4809 at the first pass of a step, then 5055-5091 (pass header and event
    // count). Valid after next_step() returned true, for the first pass and after end_pass()
    // returned true. The step body's 3882-4800 (pre-pass, M9) comes before the first call and its
    // 4811-5054 (CLEARspectra, the lmd header: M10, M15) after each call: in batch mode 4811-5054
    // prints nothing and shares no variable with 5055-5091, so the order of the two is free.
    PassInfo begin_pass();

    // GEF.bas:15503-15551 after a pass: true when another pass follows (`GoTo calcstart`).
    bool end_pass();

    [[nodiscard]] RunEnd end() const noexcept { return end_; }
    [[nodiscard]] ProcessState& process() noexcept { return *process_; }
    [[nodiscard]] InputRoundState const& round() const noexcept { return round_; }
    [[nodiscard]] SequenceFileState const& file() const noexcept { return file_; }
    [[nodiscard]] StepState const& step() const noexcept { return step_; }

private:
    // Where next_step() resumes.
    enum class Resume : std::uint8_t {
        Start,  // GEF.bas:1821, not yet run
        InStep, // a step is set up; next comes the rest of its body and `Next I_E_step`
        Over,   // the run is over
    };
    // The loop the state machine is at: the top of one iteration of it.
    enum class Loop : std::uint8_t {
        File,   // `For Ifilein` (GEF.bas:2768)
        Line,   // `For Iline` (3141)
        System, // `For I_Double_Covar` (3294)
        Step,   // `For I_E_step` (3442)
    };
    // Where a pass of the current step stands.
    enum class Pass : std::uint8_t {
        None,      // no pass begun
        Running,   // begin_pass() called, end_pass() not yet
        Continues, // end_pass() returned true
        Done,      // end_pass() returned false
    };
    // The state a round of the input starts from (`RepeatInput:`, GEF.bas:1909) that the round's
    // decisions read, besides the files and tables: B_Fit (the done.ctl check, 3174), Emode (read
    // stale by the E/spin check, 2801), En_max (part of the done.ctl key; En_min with it), both
    // kept by a spectrum energy line (2780-2787), C_Espectrum2 (set only by a two-system line with
    // a spectrum, 3093, and read stale at 3603 for the second system of a later ES or EM line;
    // C_Espectrum1 is cleared by every energy line, 2779, before any read), Eabsgs (read stale by
    // the check of 3869 for ES and EM steps) and the distinct records of done.ctl.
    // Emode alone separates two rounds in capture edge-l_restart_emode (test "rounds that differ
    // only in the stale Emode"). No input is known where B_Fit, En_min/En_max, C_Espectrum2 or
    // Eabsgs alone does (B_Fit changes once, from 0 to 1; the En_max changes found also add a
    // done.ctl record); they stay in the key because the round reads them.
    struct RoundStart {
        std::uint8_t b_fit = 0;
        std::int64_t emode = 0;
        std::uint32_t en_min_bits = 0;
        std::uint32_t en_max_bits = 0;
        std::uint32_t eabsgs_bits = 0;
        std::string c_espectrum2;
        std::set<std::string> done_records;

        friend bool operator==(RoundStart const&, RoundStart const&) = default;
    };

    // What one pass of advance() over a loop led to.
    enum class Advance : std::uint8_t {
        Continue,  // go on at loop_
        StepReady, // a step is set up
        Over,      // the run is over
    };

    void repeat_input();
    void next_fit_loop();
    [[nodiscard]] bool advance();
    [[nodiscard]] Advance file_iteration();
    [[nodiscard]] Advance line_iteration();
    [[nodiscard]] Advance system_iteration();
    [[nodiscard]] Advance step_iteration();
    [[nodiscard]] Flow begin_line();
    [[nodiscard]] Flow select_channel();
    [[nodiscard]] std::int64_t neutron_steps() const;
    [[nodiscard]] std::int64_t find_done();
    void register_done();
    void step_energy();
    void endf_step_energy();
    [[nodiscard]] RoundStart round_start() const;
    void restart();
    void finish();
    void stop(RunEnd why);
    // stop(RunEnd::Hang), then throws params::GefHangs(what): BASIC never ends here.
    [[noreturn]] void hang(char const* what);

    ProcessState* process_;
    WorkDir workdir_;
    SetupStages* stages_;
    InputRoundState round_;
    SequenceFileState file_;
    StepState step_;
    RunEnd end_ = RunEnd::None;
    Resume resume_ = Resume::Start;
    Loop loop_ = Loop::File;
    Pass pass_ = Pass::None;
    // The end values of the For loops, evaluated once at loop entry as BASIC does.
    std::int64_t ifilein_end_ = 0;
    std::int64_t iline_end_ = 0;
    std::int64_t covar_end_ = 0;
    std::int64_t step_end_ = 0;
    // The state each round of the run started from (restart()).
    std::vector<RoundStart> round_starts_;
};

} // namespace gef::run
