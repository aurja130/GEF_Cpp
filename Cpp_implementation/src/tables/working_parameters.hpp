// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The working copies of the 47 parameters GEF perturbs (`Dim Shared As Single P_DZ_Mean_S1`
// ... `Jscaling`, GEF.bas:1399-1445, all 0 at start-up): every pass assigns them, from the
// nominal values (GEF.bas:5432-5484, this file) or from `PGauss` draws (GEF.bas:5095-5431, M12),
// and the table builder and the event loop read them. They are shared globals, so the last
// pass's values carry into later code: GEF.bas:2610 reads `PZ_S3_olap_curv` when the next input
// round recomputes the widths (QUIRK(Q-019)). One owner therefore, run::ProcessState::working
// (MILESTONE_7_PLAN.md §8). Members in declaration order, which is also the order of the P3
// group "working parameter set".

#pragma once

#include "params/parameters.hpp"

namespace gef::tables {

struct WorkingParameters {
    float p_dz_mean_s1 = 0.0F;    // 1399 P_DZ_Mean_S1
    float p_corr_s1 = 0.0F;       // 1400 P_corr_S1
    float p_dz_mean_s2 = 0.0F;    // 1401 P_DZ_Mean_S2
    float p_dz_mean_s3 = 0.0F;    // 1402 P_DZ_Mean_S3
    float p_dz_mean_s4 = 0.0F;    // 1403 P_DZ_Mean_S4
    float p_dz_mean_sl5 = 0.0F;   // 1404 P_DZ_Mean_SL5
    float p_dz_mean_s5 = 0.0F;    // 1405 P_DZ_Mean_S5
    float p_z_curv_s1 = 0.0F;     // 1406 P_Z_Curv_S1
    float p_z_curv_s2 = 0.0F;     // 1407 P_Z_Curv_S2
    float s2leftmod = 0.0F;       // 1408 S2leftmod
    float p_a_width_s2 = 0.0F;    // 1409 P_A_Width_S2
    float p_z_curv_s3 = 0.0F;     // 1410 P_Z_Curv_S3
    float p_z_curv_s4 = 0.0F;     // 1411 P_Z_Curv_S4
    float p_z_curv_sl5 = 0.0F;    // 1412 P_Z_Curv_SL5
    float p_z_curv_s5 = 0.0F;     // 1413 P_Z_Curv_S5
    float pz_s3_olap_pos = 0.0F;  // 1414 PZ_S3_olap_pos
    float pz_s3_olap_curv = 0.0F; // 1415 PZ_S3_olap_curv
    float delta_s0 = 0.0F;        // 1416 Delta_S0
    float p_shell_s1 = 0.0F;      // 1417 P_Shell_S1
    float p_shell_s2 = 0.0F;      // 1418 P_Shell_S2
    float p_shell_s3 = 0.0F;      // 1419 P_Shell_S3
    float p_shell_s4 = 0.0F;      // 1420 P_Shell_S4
    float p_shell_sl5 = 0.0F;     // 1421 P_Shell_SL5
    float p_shell_s5 = 0.0F;      // 1422 P_Shell_S5
    float de_defo_s1 = 0.0F;      // 1423 dE_Defo_S1
    float de_defo_s2 = 0.0F;      // 1424 dE_Defo_S2
    float de_defo_s3 = 0.0F;      // 1425 dE_Defo_S3
    float de_defo_s4 = 0.0F;      // 1426 dE_Defo_S4
    float de_defo_s5 = 0.0F;      // 1427 dE_Defo_S5
    float betal0 = 0.0F;          // 1428 betaL0
    float betal1 = 0.0F;          // 1429 betaL1
    float betah0 = 0.0F;          // 1430 betaH0
    float betah1 = 0.0F;          // 1431 betaH1
    float dbeta_s3 = 0.0F;        // 1432 dbeta_S3
    float t_low_s1 = 0.0F;        // 1433 T_low_S1
    float t_low_s2 = 0.0F;        // 1434 T_low_S2
    float t_low_s3 = 0.0F;        // 1435 T_low_S3
    float t_low_s4 = 0.0F;        // 1436 T_low_S4
    float t_low_s5 = 0.0F;        // 1437 T_low_S5
    float t_low_sl = 0.0F;        // 1438 T_low_SL
    float ecollfrac = 0.0F;       // 1439 ECOLLFRAC
    float edissfrac = 0.0F;       // 1440 EDISSFRAC
    float p_att_pol = 0.0F;       // 1441 P_att_pol
    float p_att_rel = 0.0F;       // 1442 P_att_rel
    float hompol = 0.0F;          // 1443 HOMPOL
    float polaradd = 0.0F;        // 1444 POLARadd
    float jscaling = 0.0F;        // 1445 Jscaling
};

// GEF.bas:5432-5484, the `Else` branch of the pass set-up: every working copy takes its nominal
// value (`P_DZ_Mean_S1 = _P_DZ_Mean_S1`, ...).
void assign_nominal(WorkingParameters& w, params::Parameters const& p) noexcept;

} // namespace gef::tables
