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

// GEF.bas:2699-2763: the `If Bfilein Then` block. Bfilein is -1 when file.in was found and 0
// otherwise; the driver calls this unconditionally and it returns at once when Bfilein is 0.
// Reads file.in into round.cfilein(1..nfilein). `FIT` sets process.b_fit, process.bplot = -1 and
// file.b_error_on = 1 (B_Error_On is read through `file` by the step code, GEF.bas:4805 and
// later); `NITER(n)` sets process.n_iter.
void read_file_in(ProcessState& process, InputRoundState& round, SequenceFileState& file,
                  WorkDir const& workdir);

// GEF.bas:2770-3128 for sequence file round.ifilein (`If Nfilein > 0`): line 1 (Fenhance),
// line 2 (energy table or spectrum file), the per-file reset (2827-2842: `file` is assigned a
// fresh SequenceFileState there), Options/FIT/NITER/MODE/END and the system lines into
// process.s_par(1..iline_tot), then `Fenhance = Fenhance_global`.
// Returns Flow::End where BASIC prints an error, `Sleep`s and `End`s (missing file, energies not
// ascending, E/spin with a channel other than CN fission, spectrum file with a channel other
// than ES/EM, two-system line with several energies); Flow::Proceed otherwise.
// Throws params::GefHangs where BASIC never returns (a `Line Input` loop whose EOF() stays
// false).
[[nodiscard]] Flow read_sequence_file(ProcessState& process, InputRoundState& round,
                                      SequenceFileState& file, WorkDir const& workdir);

} // namespace gef::run
