// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Shape and yields (MILESTONE_5_PLAN.md section 3, group "shape"), namespace gef::physics.

#pragma once

#include <cstdint>

namespace gef::physics {

// Getyield (GEF.bas:15862-15920): yield of a fission channel. Divides by T_high - T_low.
[[nodiscard]] float getyield(float e_rel, float e, float e_shell, float de_defo, float t_low,
                             float t_high, float t_high_mac, std::int64_t imode) noexcept;

// F1 (GEF.bas:15923-15928), F2 (GEF.bas:15929-15934).
[[nodiscard]] float f1(float z_s_a) noexcept;
[[nodiscard]] float f2(float z_s_a) noexcept;

// Masscurv (GEF.bas:15936-15963), Masscurv1 (15965-16003), Masscurv2 (16005-16045).
[[nodiscard]] float masscurv(float z, float a, float rl, float kappa, float kappa4) noexcept;
[[nodiscard]] float masscurv1(float z, float a, float rl, float kappa, float kappa4) noexcept;
[[nodiscard]] float masscurv2(float z, float a, float rl, float kappa, float kappa4) noexcept;

// De_Saddle_Scission (GEF.bas:16047-16063).
[[nodiscard]] float de_saddle_scission(float z_cn_in, float a_cn_in, float eshiftsasci) noexcept;

// beta_light (GEF.bas:16358-16365), beta_heavy (GEF.bas:16368-16375).
[[nodiscard]] float beta_light(std::int64_t z, float betal0, float betal1) noexcept;
[[nodiscard]] float beta_heavy(std::int64_t z, float betah0, float betah1) noexcept;

// Z_equi (GEF.bas:16379-16426): charge equilibrium at scission.
[[nodiscard]] float z_equi(std::int64_t zcn, std::int64_t a1, std::int64_t a2, float beta1,
                           float beta2, float d, std::int64_t imode) noexcept;

// Beta_Equi (GEF.bas:16480-16646): deformations of minimum energy. BASIC assigns the ByRef
// outputs beta1opt/beta2opt only on improvement, so the incoming values are parameters and the
// outgoing ones the result (plan D8). When the diagonal search does not converge (N > 998)
// BASIC prints `Print #f,"Beta_Equi not converged: ",Z1,N` (GEF.bas:16628); the function
// reports it with N, the caller prints (plan D7).
struct BetaEquiResult {
    float beta1opt = 0.0F;
    float beta2opt = 0.0F;
    bool print_not_converged = false;
    std::int64_t n = 0; // N of the message
};
[[nodiscard]] BetaEquiResult beta_equi(float a1, float a2, float z1, float z2, float d,
                                       float beta1prev, float beta2prev, float beta1opt_in,
                                       float beta2opt_in) noexcept;

} // namespace gef::physics
