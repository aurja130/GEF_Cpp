// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The two deterministic pieces M5 extracts from larger BASIC code (MILESTONE_5_PLAN.md D5, D6),
// namespace gef::physics: the P_Egamma_low cross-section table and the E2 rotational cascade
// of one fragment.

#pragma once

#include "data/tables.hpp"

#include <array>
#include <cstdint>
#include <string>
#include <vector>

namespace gef::physics {

// P_Egamma_low table (GEF.bas:16980-17037): built on every call of P_Egamma_low before its
// rejection sampler (M8). Tscale, Econd and Etrans are GEF's shared variables, passed
// explicitly (plan D8). `sigma` holds sigma(0..UBound); the remaining fields are the values the
// locals have after GEF.bas:17037 (the arglog site pegl_table logs them).
struct PEgammaLowTable {
    std::int64_t n = 0;       // N
    std::vector<float> sigma; // sigma(0 To UBound)
    float sig_max = 0.0F;     // sigMax
    float tm = 0.0F;          // Tm
    float betadef = 0.0F;
    float gammadef = 0.0F;
    float eg = 0.0F;     // Eg after the last For loop
    std::int64_t i = 0;  // I after For I = 1 To 3
    std::array<float, 4> e0{}; // E0(0 To 3)
    std::array<float, 4> g0{}; // G0(0 To 3)
};
[[nodiscard]] PEgammaLowTable p_egamma_low_table(data::TableSet const& tables, float zi, float ai,
                                                 float ei, float tscale, float econd,
                                                 float etrans);

// E2 rotational cascade of one fragment (light copy GEF.bas:9309-9368, heavy copy 9430-9484;
// both are checked against this function). Inputs: the fragment's Z at scission and A after
// emission, Jfrag, J_frag_<side>, Spin_gs_<side>, and N_iso / I_iso as the caller found them
// with N_ISO_MAT / ISO_for_MAT (M4); I_iso is only read when N_iso > 0. I_DelGam is a module
// variable that GEF never assigns (GEF.bas:876, always 0), so the isomer search always runs
// when N_iso > 0. The histogram fills and the counters Ng<side>, Ngtot, Egtot1000 stay with the
// caller (M10), which walks `gammas` in order.
struct E2Cascade {
    float e_e2_tot = 0.0F;
    float ifrag_eff = 0.0F;   // IfragEff_<side>
    float beta1 = 0.0F;       // beta1 (DEFOtab of the fragment)
    float alph = 0.0F;
    std::string c_iso_lmd;    // C_iso_lmd_<side>: "GS" or "M(<spin>/<energy>)"
    std::vector<float> gammas; // Array_Eg2_<side>(1 To Ig2_<side>)
};
[[nodiscard]] E2Cascade e2_cascade(data::TableSet const& tables, std::int64_t i_z_sci,
                                   std::int64_t i_a_post, float jfrag, float j_frag,
                                   float spin_gs, std::int64_t n_iso, std::int64_t i_iso);

} // namespace gef::physics
