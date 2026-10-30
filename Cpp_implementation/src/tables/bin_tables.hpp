// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The per-nucleus model tables of one bin (MILESTONE_7_PLAN.md D7): the builder's arrays and
// shared scalars, held in run::ProcessState because BASIC never re-dimensions or clears the
// arrays, so every bin, pass, step and system starts from what the previous bin left (QUIRKS
// Q-010). Members keep the BASIC name in snake_case with the declaring line; each sub-milestone
// of M7 adds the members its blocks write.

#pragma once

#include "fbrt/array.hpp"

#include <cstdint>

namespace gef::tables {

struct BinTables {
    // --- persistent per-fragment tables (`ReDim Shared` once at start-up, never cleared)
    // GEF.bas:1084 ReDim Shared Beta(-1 To 7,1 To 2,150): deformation per mode, fragment, Z
    fb::Array<float, 3> beta{{fb::Bounds{-1, 7}, fb::Bounds{1, 2}, fb::Bounds{0, 150}}};
    // GEF.bas:1097 ReDim Shared Edefo(-1 To 5,1 To 2,150): deformation energy per mode, fragment, Z
    fb::Array<float, 3> edefo{{fb::Bounds{-1, 5}, fb::Bounds{1, 2}, fb::Bounds{0, 150}}};
    // GEF.bas:1109 ReDim Shared Zmean(0 To 5,1 To 2,350): mean Z per mode, fragment, A
    fb::Array<float, 3> zmean{{fb::Bounds{0, 5}, fb::Bounds{1, 2}, fb::Bounds{0, 350}}};
    // GEF.bas:1121 ReDim Shared Zshift(0 To 5,1 To 2,350): charge polarisation per mode, fragment,
    // A
    fb::Array<float, 3> zshift{{fb::Bounds{0, 5}, fb::Bounds{1, 2}, fb::Bounds{0, 350}}};

    // --- bin-local (GEF.bas:5610 `Dim As Single Escission_lim` inside the bin's `If`)
    float escission_lim = 0.0F;

    // --- mode centres (GEF.bas:5621-5694)
    float zc_mode_0 = 0.0F;             // 767 Shared
    float zc_mode_1 = 0.0F;             // 767
    float zc_mode_2 = 0.0F;             // 767
    float zc_mode_3 = 0.0F;             // 767
    float zc_mode_4 = 0.0F;             // 767
    float zc_mode_5 = 0.0F;             // 767
    float zc_mode_3_shift = 0.0F;       // 769
    float p_z_mean_s1 = 0x1.A66666p+5F; // 1508 `Dim Shared As Single P_Z_Mean_S1 = 52.8`
    float p_z_mean_s2 = 0x1.B8p+5F;     // 1509 `= 55`
    float p_z_mean_s3 = 0x1.04p+6F;     // 1510 `= 65`
    float p_z_mean_s4 = 0x1.5p+6F;      // 1511 `= 84`
    float p_z_mean_s5 = 0x1.3p+5F;      // 1512 `= 38`
    std::int64_t i_n_cn = 0;            // 761 Shared Integer

    // --- mean Z as a function of A, Z-A relations, curvatures (GEF.bas:5876-6058)
    float zucd = 0.0F;         // 789
    float rzpol = 0.0F;        // 807
    float ra = 0.0F;           // 803
    float ac_mode_0 = 0.0F;    // 805
    float ac_mode_1 = 0.0F;    // 805
    float ac_mode_2 = 0.0F;    // 805
    float ac_mode_3 = 0.0F;    // 805
    float ac_mode_4 = 0.0F;    // 805
    float ac_mode_5 = 0.0F;    // 805
    float nc_mode_0 = 0.0F;    // 1513
    float nc_mode_1 = 0.0F;    // 1514
    float nc_mode_2 = 0.0F;    // 1515
    float nc_mode_3 = 0.0F;    // 1516
    float nc_mode_4 = 0.0F;    // 1517
    float nc_mode_5 = 0.0F;    // 1518
    float r_z_curv_s0 = 0.0F;  // 766
    float r_z_curv1_s0 = 0.0F; // 766
    float r_a_curv1_s0 = 0.0F; // 766
    float r_z_curv2_s0 = 0.0F; // 766
    float r_a_curv2_s0 = 0.0F; // 766
};

// The builder's shared scratch variables (P3 group "stale temporaries"). The builder writes
// each of them before reading it in a bin (`tools.fbsrc.rbw reads GEF.bas:5578-7920`), and later
// code writes them before it reads them (MILESTONE_7_PLAN.md §9, M7.0), so they carry nothing:
// the caller owns them per bin (D7: locals). They are a struct so that tests can observe them.
// The global `Z` (read by the next step's pre-pass, Q-007) and `T` are run::ProcessState fields.
struct Temporaries {
    float rbeta = 0.0F;      // 787
    float beta1 = 0.0F;      // 787
    float beta2 = 0.0F;      // 787
    float beta1_opt = 0.0F;  // 796
    float beta2_opt = 0.0F;  // 796
    float beta1_prev = 0.0F; // 796
    float beta2_prev = 0.0F; // 796
    float z1 = 0.0F;         // 797
    float z2 = 0.0F;         // 797
    std::int64_t iz1 = 0;    // 798 Shared Integer
    std::int64_t iz2 = 0;    // 798
    float a1 = 0.0F;         // 799
    float a2 = 0.0F;         // 799
    float e_defo = 0.0F;     // 801
};

} // namespace gef::tables
