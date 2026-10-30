// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The bins of one pass (MILESTONE_7_PLAN.md D4): GEF.bas:5490-5577 and the loop closers
// 10001-10004. Four nested loops (spectrum point, emitted neutrons, emitted protons, E* in
// 100 keV steps counting down) visit every bin; each iteration computes the bin's inputs, and
// only bins with NEVTused > 0 enter the table builder and the event loop. First-chance steps
// have one bin per spectrum point (one for every channel but `ES`), multi-chance steps
// (Inofirst > 0 or Emode 13) 11 x 11 x 1001 per spectrum point.

#pragma once

#include "fbrt/array.hpp"
#include "fbrt/text.hpp"

#include <cstdint>

namespace gef::tables {

// What the bin loops read. Every value is fixed before the pass's bin loop starts.
struct BinPlanInput {
    std::int64_t emode = 0;    // Emode (params::Parameters::emode)
    std::int64_t inofirst = 0; // GEF.bas:3918 Inofirst (pre-pass result, M9)
    std::int64_t p_z_cn = 0;   // P_Z_CN
    std::int64_t p_a_cn = 0;   // P_A_CN
    float p_e_exc = 0.0F;      // P_E_exc
    float eabsgs = 0.0F;       // GEF.bas:1742 Eabsgs
    std::int64_t nevttot = 0;  // GEF.bas:5051 NEVTtot (LongInt)
    // GEF.bas:2669-2671 E_spectrum, L_spectrum, W_spectrum (run::InputRoundState); read for
    // Emode 3 only.
    fb::Array<float, 1> const* e_spectrum = nullptr;
    fb::Array<float, 1> const* l_spectrum = nullptr;
    fb::Array<float, 1> const* w_spectrum = nullptr;
    // GEF.bas:3914 `ReDim E_multi_chance(10,10,1000)` (the pre-pass's bin weights, M9); read for
    // multi-chance passes only.
    fb::Array<float, 3> const* e_multi_chance = nullptr;
};

// The loop counters, limits and bin inputs (P3 groups "bin loop counters and limits" and "bin
// inputs"), as the iteration that reached the current bin left them.
struct BinInput {
    // GEF.bas:5503-5507, `Dim` once per pass
    std::int64_t n_e_distr = 0;
    std::int64_t n_e_multi = 0;
    std::int64_t n_n_multi = 0;
    std::int64_t n_z_multi = 0;
    std::int64_t i_e_distr = 0;
    std::int64_t i_e_multi = 0;
    std::int64_t i_n_multi = 0;
    std::int64_t i_z_multi = 0;
    std::int64_t i_a_multi = 0;
    std::int64_t i_n_multi_max = 0; // 5506, raised at bin entry (5597)
    std::int64_t i_z_multi_max = 0; // 5507, raised at bin entry (5598)
    // CN of the bin
    std::int64_t i_z_cn = 0; // GEF.bas:848 Shared Integer
    std::int64_t i_a_cn = 0; // GEF.bas:848 Shared Integer
    // GEF.bas:5490-5491, `Dim` once per pass
    float r_e_exc_used = 0.0F;
    float i_rigid_spher = 0.0F;
    float i_eff_cn = 0.0F;
    float r_nevtspectrum = 0.0F; // GEF.bas:1758
    float e_rot_cn = 0.0F;       // GEF.bas:1746
    // GEF.bas:5051 `Dim As LongInt NEVTused,NEVTtot,IEVTtot`; IEVTtot is reset per pass (5497)
    // and counted by the event loop (M10).
    std::int64_t nevtused = 0;
    std::int64_t ievttot = 0;
};

class BinPlan {
public:
    // GEF.bas:5490-5519: the bin inputs a pass starts from and the loop limits. `in` must outlive
    // the plan.
    BinPlan(BinPlanInput const& in, BinInput& bin);

    // GEF.bas:5522-5577 and 10001-10004: runs the loops on to the next bin with NEVTused > 0 and
    // returns true, or returns false when the loops end. Every iteration, skipped or not, writes
    // `bin` and, for the channels that set it (5552 Emode 13, 5558 Emode 3), `spin_cn`
    // (run::ProcessState::spin_cn; the next step's set-up reads what the last iteration left,
    // QUIRK(Q-054)).
    [[nodiscard]] bool next(BinInput& bin, float& spin_cn);

private:
    void inputs(BinInput& bin, float& spin_cn) const;

    BinPlanInput const* in_;
    bool multi_ = false;   // the condition of 5515 and 5546
    bool started_ = false; // the loops have been entered
    bool done_ = false;
};

// GEF.bas:5584-5598, at the entry of a bin with NEVTused > 0: the `Emode = 3` console line
// (D10) and the highest emitted-neutron and -proton numbers of the pass.
void enter_bin(BinInput& bin, std::int64_t emode, float spin_cn, fb::PrintFile& console);

} // namespace gef::tables
