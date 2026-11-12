// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The blocks of the table builder (GEF.bas:5584-7511), one function per block group of
// MILESTONE_7_PLAN.md §3, called in BASIC's order for every bin with NEVTused > 0. Each takes
// the bin's inputs, the working and nominal parameters, and writes BinTables, the builder's
// temporaries and the run::ProcessState fields it names.

#pragma once

#include "data/tables.hpp"
#include "fbrt/text.hpp"
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
// For A_CN > 360 the Z(A) loops index past Zmean and Zshift and reach the next table or gap as
// the reference binary's memory does (QUIRK(Q-061); BinTables::fix_fragment_table_overrun throws).
void mode_centres_and_deformations(BinInput const& bin, WorkingParameters const& w,
                                   params::Parameters const& p, float spin_cn, BinTables& t,
                                   Temporaries& tmp, float& z,
                                   std::vector<BetaEquiMessage>& messages);

// GEF.bas:6063-6558: the energy transformation and fission barriers (`B_F`, `E_B`, ...), the
// barriers and excitation energies of the fission modes 0-5, S11 and S22 (updates the light
// fragment's `Beta(1,1,·)`/`Edefo(1,1,·)` with the S1 shell enhancement, GEF.bas:6142-6151), the
// collective temperatures, the stiffness in polarization and the mean values and standard
// deviations (widths, shell attenuation) of the modes. `p_a_cn` is BinPlanInput::p_a_cn (the A
// of the input compound nucleus, i.e. of the first chance; 6158 reads it directly instead of the
// bin's `I_A_CN`).
void barriers_temperatures_and_widths(BinInput const& bin, std::int64_t p_a_cn,
                                      WorkingParameters const& w, params::Parameters const& p,
                                      data::TableSet const& tables, BinTables& t, Temporaries& tmp);

// GEF.bas:6561-7036: the energy-dependent shifts of the mode centres (`ZC_Mode_1..5`,
// `P_Z_Mean_S0..5`), the mode energies at scission (`EsciS0..5`), the suppression of modes 0-3
// at low energy (`R_supp_S*`, `R_slope_S2`; only with `b_supp` 1, cleared by Options(NOSUPP)), the
// potential energy per mode and Z (`EMpot`, only in bin (1, 0, 0, 0)), the energy dependence of
// the charge polarisation (`Zshift(1..5, ·, ·)`, through the QUIRK(Q-061) emulation), the Z-A
// relations of the modes (2nd iteration), the mode yields normalised to 1, the selected mode's
// yield `P_selected` (`i_mode_selected`, MODE(i); -1 selects all) and the mass widths
// `SigA_Mode_*`. Prints 7016-7017 to `console` when `P_selected` is 0. `b_supp` and
// `i_mode_selected` are the sequence file's run::SequenceFileState fields.
void shifts_polarisation_and_yields(BinInput const& bin, std::uint8_t b_supp,
                                    std::int64_t i_mode_selected, WorkingParameters const& w,
                                    params::Parameters const& p, BinTables& t,
                                    fb::PrintFile& console);

// GEF.bas:7920 `Racc = 100.E0 / NEVTtot * P_selected` (normalisation of the spectra), the last
// statement before the event loop; `nevttot` is BinPlanInput::nevttot.
void spectra_normalisation(std::int64_t nevttot, BinTables& t);

} // namespace gef::tables
