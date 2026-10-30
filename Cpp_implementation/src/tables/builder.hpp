// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The blocks of the table builder (GEF.bas:5584-7511), one function per block group of
// MILESTONE_7_PLAN.md §3, called in BASIC's order for every bin with NEVTused > 0. Each takes
// the bin's inputs, the working and nominal parameters, and writes BinTables, the builder's
// temporaries and the run::ProcessState fields it names.

#pragma once

#include "params/parameters.hpp"
#include "tables/bin_plan.hpp"
#include "tables/bin_tables.hpp"
#include "tables/working_parameters.hpp"

#include <cstdint>
#include <vector>

namespace gef::tables {

// GEF.bas:16628 `Print #f,"Beta_Equi not converged: ",Z1,N`, as the builder's call at 5722
// reaches it (QUIRK(Q-041)): BASIC prints to whatever file number `f` holds; where the C++
// prints it is M13's decision (plan D6), so the builder hands the messages to its caller.
struct BetaEquiMessage {
    float z1 = 0.0F;
    std::int64_t n = 0;

    friend bool operator==(BetaEquiMessage const&, BetaEquiMessage const&) = default;
};

// GEF.bas:5609-6058: neutrons between saddle and scission (`Escission_lim`), the mode centres,
// the deformations of modes 0-7 (`Beta`, `Edefo`), the mean Z as a function of A (`Zmean`,
// `Zshift`; writes the global `z`, run::ProcessState::z), the Z-A relations of the modes and the
// potential curvatures. Appends the bin's Beta_Equi messages to `messages` as BASIC prints them.
// Throws std::out_of_range for A_CN > 360 (QUIRK(Q-061)) when it reaches the Z(A) loops, with
// BinTables, the temporaries and `messages` written as far as the deformations.
void mode_centres_and_deformations(BinInput const& bin, WorkingParameters const& w,
                                   params::Parameters const& p, float spin_cn, BinTables& t,
                                   Temporaries& tmp, float& z,
                                   std::vector<BetaEquiMessage>& messages);

} // namespace gef::tables
