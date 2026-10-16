// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF's batch input (M6.1): `file.in` and the sequence files it lists, ported statement by
// statement from the C fbc emits for GEF.bas:2699-2763 and 2768-3133. Every console line goes
// to ProcessState::console exactly as BASIC prints it (MILESTONE_6_PLAN.md D3).

#pragma once

#include "run/state.hpp"
#include "run/workdir.hpp"

namespace gef::run {

// GEF.bas:2699-2763: the `If Bfilein Then` block. Bfilein is -1 when file.in was found
// (GEF.bas:1821-1822) and 0 otherwise; the function returns at once when Bfilein is 0.
// It reads file.in into round.cfilein(1..nfilein). `FIT` sets process.b_fit, process.bplot = -1,
// and file.b_error_on = 1 (B_Error_On, set at GEF.bas:2730 and read at 4805). `NITER(n)` sets
// process.n_iter.
void read_file_in(ProcessState& process, InputRoundState& round, SequenceFileState& file,
                  WorkDir const& workdir);

// GEF.bas:2768-3133, the body of `For Ifilein`. The caller owns the loop and sets round.ifilein.
// Nfilein <= 0 takes the Else branch (GEF.bas:3129-3132). Otherwise the energy line is parsed
// (2779-2826: a quoted spectrum file or a numeric table), the per-file options are reset
// (2827-2842). Option lines set process and file state; data lines fill process.s_par(1..iline).
// Then iline_tot and fenhance are set (3120, 3128), and the probe hook runs if one is set.
// Returns Flow::End where BASIC prints an error and ends: a missing file or spectrum, average
// spins on a channel other than CN fission or ES, energies that are not ascending, a spectrum on
// a channel other than ES or EM, or a two-system line with several energies. `Sleep` is not
// ported. Throws params::GefHangs where `Do Until EOF` cannot end (no data is left, EOF() false).
[[nodiscard]] Flow read_sequence_file(ProcessState& process, InputRoundState& round,
                                      SequenceFileState& file, WorkDir const& workdir);

} // namespace gef::run
