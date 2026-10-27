// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "run/driver.hpp"

#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "fbrt/input.hpp"
#include "fbrt/strings.hpp"
#include "fbrt/text.hpp"
#include "params/parameter_files.hpp"
#include "physics/masses.hpp"
#include "run/input_files.hpp"
#include "run/run_util.hpp"

#include <algorithm>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>

namespace gef::run {

namespace {

// `Energy_table(i)` and `Spin_table(i)` as the step schedule (GEF.bas:3451-3495) reads them. The
// emitted C indexes both arrays without a bound check.
// QUIRK(candidate): with N_E_values 0 (an empty energy line, `Redim Energy_Table(0)` and
// `Redim Spin_Table(0)`), FC, IS, ES, EM and the single-step ENDF schedule read element 1, past
// the bounds. BASIC reads +0.0F there, as GEF.bas:2824 does (captures edge-e_energy_empty,
// edge-e_is_energy_empty, edge-e_fc_energy_empty, edge-e_endf_energy_empty); the port returns
// +0.0F for that one read and throws for any other.
float table_at(fb::Array<float, 1> const& table, std::int64_t i) {
    if (i == 1 && table.ubound(1) == 0) {
        return 0.0F;
    }
    return table(i);
}

float energy_table_at(InputRoundState const& round, std::int64_t i) {
    return table_at(round.energy_table, i);
}

float spin_table_at(InputRoundState const& round, std::int64_t i) {
    return table_at(round.spin_table, i);
}

// GEF.bas:3253-3255, 3258-3260, 3264-3266:
// `If Val(Mid(CEref,3)) > 0 Then I_E_iso = Val(Mid(CEref,3))`.
void set_positive_isomer(ProcessState& process) {
    if (fb::val(fb::mid(process.ceref, 3)) > 0.0) {
        process.i_e_iso = fb::d2l(fb::val(fb::mid(process.ceref, 3)));
    }
}

} // namespace

RunDriver::RunDriver(ProcessState& process, WorkDir workdir, SetupStages& stages)
    : process_{&process}, workdir_{std::move(workdir)}, stages_{&stages} {}

bool RunDriver::next_step() {
    ProcessState& p = *process_;
    switch (resume_) {
    case Resume::Over:
        return false;
    case Resume::Start:
        // GEF.bas:1821-1822. Without file.in GEF takes its input from the dialogue (not ported).
        if (!workdir_.exists("file.in")) {
            throw std::runtime_error(
                "GEF.bas:1821: no file.in in the working directory; the dialogue is not ported");
        }
        p.bfilein = -1;
        // GEF.bas:1832-1905 (ctl/thread.ctl, I_thread) are not ported: a clean run is thread 1.
        // GEF.bas:1908
        p.ivalid = 1;
        round_starts_.push_back(round_start());
        break;
    case Resume::InStep:
        if (pass_ == Pass::Running || pass_ == Pass::Continues) {
            throw std::logic_error("next_step: the passes of the step are not done");
        }
        // GEF.bas:15564-15579: in batch mode only plotting (not ported) and ctl/sync.ctl
        // (in memory: not kept). Then `Next I_E_step` (15582).
        p.i_e_step = fb::add(p.i_e_step, std::int64_t{1});
        loop_ = Loop::Step;
        break;
    }
    bool const start = resume_ == Resume::Start;
    pass_ = Pass::None;
    resume_ = Resume::Over; // until advance() stops at a step
    bool ready = false;
    try {
        if (start) {
            // GEF.bas:1909 RepeatInput, then Nextfitloop, whose stage (begin_round) may hang too.
            repeat_input();
        }
        ready = advance();
    } catch (params::GefHangs const&) {
        // The parser (GEF.bas:2843), a stage or the driver found that BASIC never ends here.
        stop(RunEnd::Hang);
        throw;
    }
    if (!ready) {
        return false;
    }
    resume_ = Resume::InStep;
    return true;
}

// GEF.bas:1909-1910 `RepeatInput: P_I_rms_CN = 0`. In batch mode on Linux 1911-2513 is the
// Windows GUI (`#ifdef __FB_WIN32__`) and the dialogue (`If Bfilein = 0 And BGUI = 0`): neither is
// compiled or entered. Then GEF.bas:2515-2517 and Nextfitloop.
void RunDriver::repeat_input() {
    ProcessState& p = *process_;
    p.p_i_rms_cn = 0.0F;
    // GEF.bas:2515-2517
    p.params.chisqr_fit_min = 0x1.2A05F2p+33F;
    p.i_fitloop = 0;
    p.chisqr_fit_present = 0.0;
    next_fit_loop();
}

// GEF.bas:2519-2768 `Nextfitloop:` up to the head of `For Ifilein`.
void RunDriver::next_fit_loop() {
    ProcessState& p = *process_;
    // GEF.bas:2522 (2524 await: not ported)
    p.b_new_fit_parameters = 1;
    // GEF.bas:2526-2554: Fitlog and FitparWrite after a fit iteration (M16). I_Fitloop is 0 at
    // every pass through Nextfitloop in M6: 2516 sets it before the first pass and before each
    // restart, and the fit back edge (15610), the only other way here, is not followed (D4).
    if (p.b_fit == 1 && p.i_fitloop >= 1) {
        throw std::logic_error("GEF.bas:2527: a fit iteration after the first is M16's");
    }
    // GEF.bas:2570, done before the stage's 2555 (FitparRead), which does not read I_Fitloop.
    p.i_fitloop = fb::add(p.i_fitloop, std::int64_t{1});
    // GEF.bas:2555, 2575-2624
    stages_->begin_round(p, workdir_);
    // GEF.bas:2626-2639 `If Bfilein = 0`: Bfilein is -1 at every pass through Nextfitloop in M6.
    // 1822 sets it before the first pass; only 3130 clears it, when file.in names no sequence
    // file, and then no system line exists to restart from and the back edge is not followed.
    if (p.bfilein == 0) {
        throw std::logic_error("GEF.bas:2626: Nextfitloop reached in dialogue mode");
    }
    // GEF.bas:2647-2684: the Dims after Nextfitloop start afresh.
    round_ = InputRoundState{};
    // GEF.bas:2699-2764
    read_file_in(p, round_, file_, workdir_);
    // GEF.bas:2768 `For Ifilein = 1 To Max(Nfilein,1)`: GEF's Single Max, converted with fb_F2L.
    round_.ifilein = 1;
    ifilein_end_ = fb::f2l(fb::max(static_cast<float>(round_.nfilein), 1.0F));
    loop_ = Loop::File;
}

// The loops of GEF.bas:2768-15596, from the top of the iteration loop_ names, until a step is
// set up (true) or the run is over (false).
bool RunDriver::advance() {
    for (;;) {
        Advance next = Advance::Continue;
        switch (loop_) {
        case Loop::File:
            next = file_iteration();
            break;
        case Loop::Line:
            next = line_iteration();
            break;
        case Loop::System:
            next = system_iteration();
            break;
        case Loop::Step:
            next = step_iteration();
            break;
        }
        if (next != Advance::Continue) {
            return next == Advance::StepReady;
        }
    }
}

// One iteration of `For Ifilein` (GEF.bas:2768-3141), or its end.
RunDriver::Advance RunDriver::file_iteration() {
    ProcessState& p = *process_;
    if (round_.ifilein > ifilein_end_) {
        // GEF.bas:15596 `Next Ifilein` done
        finish();
        return Advance::Over;
    }
    // GEF.bas:2769-3133
    if (read_sequence_file(p, round_, file_, workdir_) == Flow::End) {
        stop(RunEnd::EndStatement);
        return Advance::Over;
    }
    // GEF.bas:3138 (await: not ported), 3141 `For Iline = 1 To Iline_tot`
    p.iline = 1;
    iline_end_ = p.iline_tot;
    loop_ = Loop::Line;
    return Advance::Continue;
}

// One iteration of `For Iline` (GEF.bas:3141-3294), or its end.
RunDriver::Advance RunDriver::line_iteration() {
    ProcessState& p = *process_;
    if (p.iline > iline_end_) {
        // GEF.bas:15596 `Next Ifilein`
        round_.ifilein = fb::add(round_.ifilein, std::int64_t{1});
        loop_ = Loop::File;
        return Advance::Continue;
    }
    Flow const flow = begin_line();
    if (flow == Flow::End) {
        stop(RunEnd::EndStatement);
        return Advance::Over;
    }
    if (flow == Flow::NextLine) {
        // GEF.bas:3222 `Continue For`, then 15594 `Next Iline`
        p.iline = fb::add(p.iline, std::int64_t{1});
        return Advance::Continue;
    }
    // GEF.bas:3288-3292
    p.n_double_covar = p.b_double_covar == 1 ? 2 : 1;
    // GEF.bas:3294 `For I_Double_Covar = 1 To N_Double_Covar`
    p.i_double_covar = 1;
    covar_end_ = p.n_double_covar;
    loop_ = Loop::System;
    return Advance::Continue;
}

// One iteration of `For I_Double_Covar` (GEF.bas:3294-3442), or its end.
RunDriver::Advance RunDriver::system_iteration() {
    ProcessState& p = *process_;
    if (p.i_double_covar > covar_end_) {
        // GEF.bas:15591 `Next I_Double_Covar` done, 15594 `Next Iline`
        p.iline = fb::add(p.iline, std::int64_t{1});
        loop_ = Loop::Line;
        return Advance::Continue;
    }
    // GEF.bas:3296-3300 (plotting: not ported), 3301-3305
    // QUIRK(candidate): the energy of a two-system line (P_E_exc_Double) is set here and
    // overwritten by the step schedule (3449-3497) for every Emode, so it has no effect.
    if (p.i_double_covar == 2) {
        p.p_z_cn = p.p_z_cn_double;
        p.p_a_cn = p.p_a_cn_double;
        p.p_e_exc = p.p_e_exc_double;
    }
    // GEF.bas:3313-3440
    Flow const flow = stages_->begin_system(p, round_, file_);
    if (flow == Flow::NextLine) {
        // GEF.bas:3384 `Goto Next_Iline_label` (15593): the second system of a line is skipped
        // with the first.
        p.iline = fb::add(p.iline, std::int64_t{1});
        loop_ = Loop::Line;
        return Advance::Continue;
    }
    if (flow != Flow::Proceed) {
        throw std::logic_error(
            "GEF.bas:3313-3440 in batch mode either proceeds or leaves the system line");
    }
    // GEF.bas:3442 `For I_E_step = 1 To N_E_steps`
    p.i_e_step = 1;
    step_end_ = p.n_e_steps;
    loop_ = Loop::Step;
    return Advance::Continue;
}

// One iteration of `For I_E_step` up to the end of the step's set-up (GEF.bas:3442-3972), or the
// end of the loop.
RunDriver::Advance RunDriver::step_iteration() {
    ProcessState& p = *process_;
    if (p.i_e_step > step_end_) {
        // GEF.bas:15582 `Next I_E_step` done, 15591 `Next I_Double_Covar`
        p.i_double_covar = fb::add(p.i_double_covar, std::int64_t{1});
        loop_ = Loop::System;
        return Advance::Continue;
    }
    // GEF.bas:3444-3497
    step_energy();
    // GEF.bas:3499-3972
    switch (stages_->set_up_step(p, round_, file_, step_, workdir_)) {
    case Flow::Proceed:
        return Advance::StepReady;
    case Flow::Restart:
        restart();
        return Advance::Continue;
    case Flow::End:
        stop(RunEnd::EndStatement);
        return Advance::Over;
    case Flow::NextLine:
        break;
    }
    throw std::logic_error("GEF.bas:3499-3972 proceeds, restarts the input or ends GEF; it never "
                           "leaves the system line");
}

// GEF.bas:3142-3223, the head of one system line. Flow::End where BASIC prints an error and
// ends, Flow::NextLine for `Continue For` (3222), Flow::Proceed otherwise.
Flow RunDriver::begin_line() {
    ProcessState& p = *process_;
    // GEF.bas:3142 `If Bfilein = -1`. Iline_tot > 0 means a sequence file was parsed in this
    // round, and parsing one sets Bfilein = -1 (2772); 3130 sets 0 only when no file is named,
    // and then Iline_tot is still its start value 0 (`Static`, 1738), because file.in is the same
    // in every round.
    if (p.bfilein != -1) {
        throw std::logic_error("GEF.bas:3142: a system line without a sequence file");
    }
    SystemLine const& line = p.s_par(p.iline);
    // GEF.bas:3143-3150
    p.b_double_covar = 0;
    p.p_z_cn = line.z;
    p.p_a_cn = line.a;
    if (line.z_double > 0) {
        p.b_double_covar = 1;
        p.p_z_cn_double = line.z_double;
        p.p_a_cn_double = line.a_double;
        p.p_e_exc_double = line.e_double;
        // GEF.bas:3152-3160 never ends GEF: N_E_values is written only at 2650 and 2794, both
        // before the file's system lines, and the parse already ends at 3072 for a two-system
        // line when N_E_values > 1 (its text is 3073-3080); Z_double > 0 is set only after that
        // check (3090).
        if (round_.n_e_values > 1) {
            throw std::logic_error("GEF.bas:3152: a two-system line with several energies");
        }
    }
    // GEF.bas:3164 (3168 await: not ported)
    p.ceref = fb::ucase(line.ce);
    // GEF.bas:3173-3203
    std::int64_t ifound = 0;
    if (p.b_fit == 0) {
        ifound = find_done();
    }
    // GEF.bas:3205-3209
    if (physics::u_valid(*p.tables, p.p_z_cn, p.p_a_cn) == 0) {
        ifound = 1;
        print_part(p, "Nucleus Z =");
        p.console.print(p.p_z_cn, fb::PrintEnd::None);
        print_part(p, ", A =");
        p.console.print(p.p_a_cn, fb::PrintEnd::None);
        print_line(p, " out of supported range, will be skipped.");
    }
    // GEF.bas:3213-3220
    if (ifound == 0) {
        register_done();
    }
    // GEF.bas:3221-3223
    if (ifound == 1) {
        return Flow::NextLine;
    }
    return select_channel();
}

// GEF.bas:3224-3283: Emode, N_E_steps and I_E_iso from the entrance channel. Flow::End for an
// invalid channel (3278-3282), Flow::Proceed otherwise.
Flow RunDriver::select_channel() {
    ProcessState& p = *process_;
    // GEF.bas:3224-3226
    p.n_e_steps = 1;
    p.p_e_exc = p.en_max;
    p.i_e_iso = 0;
    // GEF.bas:3227 `Select Case Left(CEref,2)`
    std::string const kind = fb::left(p.ceref, 2);
    if (kind == "EB") {
        // GEF.bas:3228-3230
        p.params.emode = 0;
        p.n_e_steps = round_.n_e_values;
    } else if (kind == "GS") {
        // GEF.bas:3231-3233
        p.params.emode = 1;
        p.n_e_steps = round_.n_e_values;
    } else if (kind == "FC") {
        // GEF.bas:3234-3235
        p.params.emode = -1;
    } else if (kind == "IS") {
        // GEF.bas:3236-3238
        p.params.emode = 1;
        p.i_e_iso = fb::d2l(fb::val(fb::mid(p.ceref, 3)));
    } else if (kind == "EN") {
        // GEF.bas:3239-3255
        p.params.emode = 2;
        p.n_e_steps = neutron_steps();
        set_positive_isomer(p);
    } else if (kind == "EP") {
        // GEF.bas:3256-3261
        p.params.emode = 12;
        set_positive_isomer(p);
        p.n_e_steps = round_.n_e_values;
    } else if (kind == "EA") {
        // GEF.bas:3262-3267
        p.params.emode = 22;
        set_positive_isomer(p);
        p.n_e_steps = round_.n_e_values;
    } else if (kind == "ES") {
        // GEF.bas:3268-3275
        // QUIRK(candidate): clearing B_ENDF and B_random_on here holds for the rest of the file.
        p.params.emode = 3;
        if (file_.b_endf == 1) {
            print_line(p, "<W> ENDF output not available for option 'ES'.");
            print_line(p, "    ENDF output suspended.");
            file_.b_endf = 0;
            file_.b_random_on = 0;
        }
    } else if (kind == "EM") {
        // GEF.bas:3276-3277
        p.params.emode = 13;
    } else {
        // GEF.bas:3278-3282
        print_part(p, "<E> Option ");
        print_part(p, p.ceref);
        print_line(p, " is not valid.");
        print_line(p, "Press Enter key to leave GEF!");
        return Flow::End;
    }
    return Flow::Proceed;
}

// GEF.bas:3241-3252: N_E_steps of an EN line.
std::int64_t RunDriver::neutron_steps() const {
    std::int64_t n_e_steps = 1;
    if (file_.b_endf == 1) {
        if (round_.n_e_values > 1) {
            n_e_steps = fb::add(round_.n_e_values, std::int64_t{3});
        } else {
            n_e_steps = 1;
        }
        if (file_.b_random_on != 0) {
            if (round_.n_e_values == 1) {
                n_e_steps = 2;
            }
        }
    } else {
        n_e_steps = round_.n_e_values;
    }
    return n_e_steps;
}

// GEF.bas:3175-3202: the records of ctl/done.ctl (D2: ProcessState::done_ctl, empty while the
// file does not exist) that match the system; prints a line for each. Returns Ifound.
// QUIRK(candidate): the key is Z, A, En_max, Fenhance and I_Mode_selected, not the channel; a
// Fenhance that is not exact in Single (0.1) never matches, since Fenhance_done is read back as
// Single and compared with the Double Fenhance (GEF.c:40727); a record of the first line of a
// file with Fenhance 0 holds 0 (3217 comes before 3922), so a repeat of that line is computed
// again.
std::int64_t RunDriver::find_done() {
    ProcessState& p = *process_;
    std::int64_t ifound = 0;
    // GEF.bas:3176 `If Fileexists(CFdone)`: the file exists once a record was appended (3216).
    if (p.done_ctl.empty()) {
        return ifound;
    }
    // GEF.bas:3178-3199 `Do : Input #Fdone, ... : Loop Until EOF(Fdone)`
    fb::InputFile done{p.done_ctl};
    for (;;) {
        float const zdone = done.input_single();
        float const adone = done.input_single();
        float const edone = done.input_single();
        float const fenhance_done = done.input_single();
        std::int64_t const imode_done = done.input_longint();
        // GEF.bas:3181-3188, compared as GEF.c:40715-40731 does
        if (zdone == static_cast<float>(p.p_z_cn) && adone == static_cast<float>(p.p_a_cn) &&
            edone == p.en_max && static_cast<double>(fenhance_done) == p.fenhance &&
            imode_done == file_.i_mode_selected) {
            // GEF.bas:3189-3191
            ifound = 1;
            print_part(p, "Z = ");
            p.console.print(p.p_z_cn, fb::PrintEnd::None);
            print_part(p, " A = ");
            p.console.print(p.p_a_cn, fb::PrintEnd::None);
            print_part(p, " E = ");
            p.console.print(p.en_max, fb::PrintEnd::None);
            print_part(p, " Fenhance = ");
            p.console.print(p.fenhance, fb::PrintEnd::None);
            print_part(p, " I_Mode_selected = ");
            p.console.print(file_.i_mode_selected, fb::PrintEnd::None);
            print_line(p, " skipped (already in done.ctl).");
        }
        // GEF.bas:3199 `Loop Until EOF(Fdone)`
        if (done.eof()) {
            break;
        }
    }
    return ifound;
}

// GEF.bas:3214-3219: `Open CFdone For Append`, then
// `Print #Fdone, P_Z_CN,P_A_CN,En_max,Fenhance,I_Mode_selected` (GEF.c:40884-40894).
void RunDriver::register_done() {
    ProcessState& p = *process_;
    fb::PrintFile record;
    record.print(p.p_z_cn, fb::PrintEnd::Pad);
    record.print(p.p_a_cn, fb::PrintEnd::Pad);
    record.print(p.en_max, fb::PrintEnd::Pad);
    record.print(p.fenhance, fb::PrintEnd::Pad);
    record.print(file_.i_mode_selected, fb::PrintEnd::Newline);
    p.done_ctl += record.text();
}

// GEF.bas:3444-3497, the head of one energy step. CLEARerrors.bas (3446) clears arrays of the
// error analysis (M12).
void RunDriver::step_energy() {
    ProcessState& p = *process_;
    // GEF.bas:3444-3447
    p.c_pfis.clear();
    p.c_pfis2.clear();
    p.i_error = 0;
    // GEF.bas:3449 `If BFilein Then`: always taken (begin_line's check of 3142).
    std::int64_t const emode = p.params.emode;
    std::int64_t const step = p.i_e_step;
    // GEF.bas:3450-3457: two Ifs with the same body, for Emode 0 and for Emode 1. IS (Emode 1,
    // N_E_steps 1) reads element 1 also after an empty energy line.
    if (emode == 0 || emode == 1) {
        p.p_e_exc = energy_table_at(round_, step);
        p.p_i_rms_cn = spin_table_at(round_, step);
    }
    if (emode == 2) {
        // GEF.bas:3458-3493
        if (file_.b_endf == 1) {
            endf_step_energy();
        } else {
            // GEF.bas:3491-3492
            p.p_e_exc = round_.energy_table(step);
        }
    } else {
        // GEF.bas:3494-3495
        // QUIRK(candidate): FC, IS, ES and EM run Energy_table(1) (N_E_steps 1) while CFileout
        // and done.ctl use En_max (3225, 3413); a spectrum-file line reads the round's table.
        p.p_e_exc = energy_table_at(round_, step);
    }
}

// GEF.bas:3459-3490: the energy and B_Error_On of an EN step with ENDF output.
void RunDriver::endf_step_energy() {
    ProcessState& p = *process_;
    std::int64_t const step = p.i_e_step;
    if (p.n_e_steps == 1) {
        // GEF.bas:3460-3462
        file_.b_error_on = 1;
        p.p_e_exc = energy_table_at(round_, 1);
    } else if (p.n_e_steps == 2) {
        // GEF.bas:3463-3475. N_E_steps is 2 only from 3248, which needs B_random_on. Within the
        // line only the step body changes B_random_on (ENDF.bas:81-89), and only for Emode 1 or
        // N_E_steps 1, never on this path; so the Else of 3472-3474 (which reads Energy_table(I)
        // with the shared I of GEF.bas:762, C `I$`, not the scope-local I of 3171) is never taken.
        if (file_.b_random_on == 0) {
            throw std::logic_error("GEF.bas:3472: N_E_steps = 2 without RANDOM");
        }
        if (step == 1) {
            // GEF.bas:3465-3467
            file_.b_error_on = 0;
            p.p_e_exc = energy_table_at(round_, 1);
        } else if (step == 2) {
            // GEF.bas:3468-3470
            file_.b_error_on = 1;
            p.p_e_exc = energy_table_at(round_, 1);
        }
    } else if (p.n_e_steps > 3) {
        // GEF.bas:3476-3489
        // QUIRK(candidate): the last step leaves B_Error_On 0 for the rest of the file.
        // NOLINTNEXTLINE(bugprone-branch-clone): BASIC's branches, in the order of 3477-3489
        if (step == 1) {
            p.p_e_exc = p.en_min;
            file_.b_error_on = 0;
        } else if (step == 2) {
            p.p_e_exc = p.en_max;
            file_.b_error_on = 0;
        } else if (step >= 3 && step < p.n_e_steps) {
            p.p_e_exc = round_.energy_table(fb::sub(step, std::int64_t{2}));
            file_.b_error_on = 1;
        } else if (step == p.n_e_steps) {
            p.p_e_exc = p.en_min;
            file_.b_error_on = 0;
        }
    }
}

// The state restart() compares: what a round starts from (RoundStart).
RunDriver::RoundStart RunDriver::round_start() const {
    ProcessState const& p = *process_;
    RoundStart start{.b_fit = p.b_fit,
                     .emode = p.params.emode,
                     .en_min_bits = std::bit_cast<std::uint32_t>(p.en_min),
                     .en_max_bits = std::bit_cast<std::uint32_t>(p.en_max),
                     .eabsgs_bits = std::bit_cast<std::uint32_t>(p.eabsgs),
                     .c_espectrum2 = p.c_espectrum2,
                     .done_records = {}};
    std::string_view rest = p.done_ctl;
    while (!rest.empty()) {
        std::size_t const end = rest.find('\n');
        std::size_t const length = end == std::string_view::npos ? rest.size() : end + 1;
        start.done_records.emplace(rest.substr(0, length));
        rest.remove_prefix(length);
    }
    return start;
}

// GEF.bas:3567 `Goto RepeatInput`.
// QUIRK(candidate): the missing-isomer restart reads file.in again. It ends only when done.ctl
// holds every restarting line, or when a value left by the earlier round (Emode at the E/spin
// check of 2801, En_max in the done.ctl key) leads to a fatal end; in fit mode only the latter.
// Proof of the hang, for the step body M6 runs (none: the GEF_SETUP_ONLY program): a round's
// decisions read the files and tables (unchanged), the RoundStart state, and step-body writes
// that the same round makes again: B_Random_On (ENDF.bas:81-89, from Emode and N_E_steps); the
// MAT numbers of the M6.0 patch check do not change a decision (N_ISO_MAT of a number I_MAT_ENDF
// assigns to a nuclide missing from NucTab is 0, whatever the number); 1909-3972 draw no random
// number. A round that starts from a state an earlier round started from therefore repeats that
// round and every round after it: BASIC restarts for ever. With real step bodies (M9-M13) this
// no longer holds (the pre-pass draws Eabsgs, 4243-4252; `Static Ntimes`, 8735, counts events
// across rounds): MILESTONE_6_PLAN.md records the obligation for M9.
void RunDriver::restart() {
    RoundStart start = round_start();
    if (std::ranges::find(round_starts_, start) != round_starts_.end()) {
        hang("GEF.bas:3567: the missing-isomer restart repeats an earlier round for ever");
    }
    round_starts_.push_back(std::move(start));
    repeat_input();
}

// GEF.bas:15597-15669, after `Next Ifilein`.
void RunDriver::finish() {
    ProcessState& p = *process_;
    // GEF.bas:15597-15612
    if (p.b_fit != 0) {
        // GEF.bas:15598 `If N_iter > 0 And I_Fitloop = N_iter Then` (end) `Else`
        if (p.n_iter <= 0 || p.i_fitloop != p.n_iter) {
            // GEF.bas:15602-15610 (ctl/sync.ctl: not kept), `GoTo Nextfitloop`: M16.
            stop(RunEnd::FitBackEdge);
            return;
        }
    }
    // GEF.bas:15618-15631. Bfilein is 0 only when file.in names no sequence file (3130).
    if (p.bfilein == 0) {
        hang("GEF.bas:15621: file.in names no sequence file; GEF waits for a key for ever");
    }
    // GEF.bas:15619 `kin = "Q"`, so 15654-15660 is skipped. GEF.bas:15664-15668 (Sleep returns
    // at once with stdin at EOF, M6.0)
    print_line(p, "GEF is terminated.");
    print_line(p, "Press ENTER to close this window!");
    stop(RunEnd::Finished);
}

void RunDriver::stop(RunEnd why) {
    end_ = why;
    resume_ = Resume::Over;
}

void RunDriver::hang(char const* what) {
    stop(RunEnd::Hang);
    throw params::GefHangs{what};
}

PassInfo RunDriver::begin_pass() {
    ProcessState& p = *process_;
    if (resume_ != Resume::InStep || pass_ == Pass::Running || pass_ == Pass::Done) {
        throw std::logic_error("begin_pass: no pass of a set-up step is due");
    }
    if (pass_ == Pass::None) {
        // GEF.bas:4805, 4809
        p.b_error_analysis = file_.b_error_on;
        p.chisqr_min = 0x1.2A05F2p+33;
    }
    pass_ = Pass::Running;
    // GEF.bas:5055-5058
    if (p.fenhance < 1.0 && p.b_error_analysis == 0) {
        print_part(p, "<W> The calculation with ");
        p.console.print(static_cast<float>(p.fenhance * 0x1.86Ap+16), fb::PrintEnd::None);
        print_line(p, " events will be subject");
        print_line(p, "    to grave statistical fluctuations!");
    }
    std::int64_t nevttot = 0;
    if (p.b_error_analysis == 1) {
        if (p.b_fit == 1) {
            // GEF.bas:5060-5062
            nevttot = fb::d2l(p.fenhance * 0x1.86Ap+16);
            p.n_error_max = 1;
        } else {
            // GEF.bas:5063-5070
            p.n_error_max = fb::d2l(std::floor(std::sqrt(p.fenhance * 0x1.9p+6)));
            nevttot = fb::d2l((p.fenhance * 0x1.86Ap+16) / static_cast<double>(p.n_error_max));
            print_part(p, "Calculation (");
            p.console.print(fb::add(p.i_error, std::int64_t{1}), fb::PrintEnd::None);
            print_part(p, " of ");
            p.console.print(p.n_error_max, fb::PrintEnd::None);
            print_line(p, ") with perturbed model parameters.");
        }
    } else {
        // GEF.bas:5078-5083
        nevttot = fb::d2l(p.fenhance * 0x1.86Ap+16);
        print_line(p, "Calculation with nominal model parameters.");
    }
    // GEF.bas:5091
    if (nevttot > 0) {
        p.console.print(nevttot, fb::PrintEnd::None);
        print_line(p, " events will be calculated.");
    }
    return PassInfo{.i_error = p.i_error,
                    .b_error_analysis = p.b_error_analysis,
                    .n_error_max = p.n_error_max,
                    .nevttot = nevttot};
}

bool RunDriver::end_pass() {
    ProcessState& p = *process_;
    if (resume_ != Resume::InStep || pass_ != Pass::Running) {
        throw std::logic_error("end_pass: no pass is running");
    }
    // GEF.bas:15474-15502 `NewPlot:` is the dialogue's (`If Bfilein = 0`). GEF.bas:15503
    // `If B_fit = 0`: the plotting of 15504-15525 is not ported, and the loop of the error
    // analysis runs only outside fit mode.
    bool again = false;
    if (p.b_fit == 0) {
        // GEF.bas:15506-15524: with Bplot set (Options(PLOT)), Plotting.bas, then
        // `Input " ",Icontinue` (15522; 15512 before it at the nominal pass of the last step).
        // With stdin at EOF a console Input never returns (fb_ConReadLine waits for ever; M6.2,
        // a full run of Options(PLOT, ERR) stopped there after its first pass).
        if (p.bplot != 0) {
            hang("GEF.bas:15522: Input from the console never returns with stdin at EOF");
        }
        // GEF.bas:15528-15551 (15541-15547 ctl/sync.ctl: not kept)
        if (file_.b_error_on == 1) {
            p.i_error = fb::add(p.i_error, std::int64_t{1});
            if (p.i_error == p.n_error_max) {
                p.b_error_analysis = 0;
            }
            again = p.i_error <= p.n_error_max;
        }
    }
    pass_ = again ? Pass::Continues : Pass::Done;
    return again;
}

} // namespace gef::run
