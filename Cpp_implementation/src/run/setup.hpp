// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Per-round, per-system and per-step set-up of GEF's batch mode (M6.3, M6.4), ported statement
// by statement from the C fbc emits. Console text goes to ProcessState::console. The run driver
// (run/driver.hpp) reaches them through SetupStages; M6.3 and M6.4 add the implementation of
// SetupStages that calls them. Contract header: not yet implemented.

#pragma once

#include "run/state.hpp"
#include "run/workdir.hpp"

namespace gef::run {

// GEF.bas:2555 (FitparRead: params::fitpar_read) and 2575-2624 (the Var_* widths with the
// working copy ProcessState::pz_s3_olap_curv, params::update_widths; `Clocal = "localoff"`).
void begin_round(ProcessState& process, WorkDir const& workdir);

// GEF.bas:3313-3440, one pass of `For I_Double_Covar` after the driver set the system's CN
// (3301-3305): Clocal (3313-3315), the `Parameters.bas` reset when B_Fit = 0 (3317-3321,
// params::load_parameters_bas), the local-parameter stub (3323-3344), the barrier and mass
// printout with BFC (3346-3375), the unbound check (3377-3390: Flow::NextLine, BASIC's
// `Goto Next_Iline_label`) and the file names CFileout_Single, CFileout (first system only),
// CFileout_full (3393-3439). Flow::Proceed otherwise.
[[nodiscard]] Flow begin_system(ProcessState& process, InputRoundState& round,
                                SequenceFileState& file);

// GEF.bas:3499-3880 and the run-control lines of the multi-chance block (3914-3972), after the
// driver set the step's energy and B_Error_On (3444-3497): Csystem (3500-3529), the batch-mode
// lmd name (3531-3540), isomer energy (3542-3590; Flow::Restart at 3567, BASIC's
// `Goto RepeatInput`), the CN line, the E* spectrum (3593-3692), `Fenhance` (3694-3696), spins
// and kinematics for every Emode (3698-3843), the range checks (3844-3874, Flow::End at
// 3836-3839 and 3869-3873), the trailing "Please wait" lines (3876-3880), probe P1, then `step`
// reset to StepState{} and `If Fenhance = 0 Then Fenhance = 1` (3922), `N_multi_sample` (3926),
// the threshold `Eexc_min_multi` (3947-3966), probe P1b and the decision of 3967 (step.prepass,
// and step.bmulti = 1 as at 3972). The rest of 3882-4800 is the pre-pass (M9). Flow::Proceed
// otherwise.
[[nodiscard]] Flow set_up_step(ProcessState& process, InputRoundState& round,
                               SequenceFileState& file, StepState& step, WorkDir const& workdir);

} // namespace gef::run
