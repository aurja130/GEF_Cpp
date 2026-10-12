// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Moments of inertia, GDR helpers and kinematics (MILESTONE_5_PLAN.md section 3, group
// "rotation"), namespace gef::physics.

#pragma once

namespace gef::physics {

// U_Ired (GEF.bas:17094-17108), U_IredFF (17110-17118), U_I_Shell (17120-17170).
[[nodiscard]] float u_ired(float z, float a) noexcept;
[[nodiscard]] float u_iredff(float z, float a) noexcept;
[[nodiscard]] float u_i_shell(float z, float a) noexcept;

// E0_GDR (GEF.bas:17439-17459), Width_GDR (17461-17464), Efac_def_GDR (17466-17475).
[[nodiscard]] float e0_gdr(float z, float a) noexcept;
[[nodiscard]] float width_gdr(float e0) noexcept;
[[nodiscard]] float efac_def_gdr(float beta, float gamma, float k) noexcept;

// u_accel (GEF.bas:16907-16959): fragment acceleration.
[[nodiscard]] float u_accel(float a1, float z1, float a2, float z2, float tke, float e0,
                            float tn) noexcept;

} // namespace gef::physics
