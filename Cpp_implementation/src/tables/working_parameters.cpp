// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "tables/working_parameters.hpp"

namespace gef::tables {

// GEF.bas:5435-5481 (plain Single copies, GEF.c:58603-58741)
void assign_nominal(WorkingParameters& w, params::Parameters const& p) noexcept {
    w.p_dz_mean_s1 = p.p_dz_mean_s1;       // 5435
    w.p_corr_s1 = p.p_corr_s1;             // 5436
    w.p_dz_mean_s2 = p.p_dz_mean_s2;       // 5437
    w.p_dz_mean_s3 = p.p_dz_mean_s3;       // 5438
    w.p_dz_mean_s4 = p.p_dz_mean_s4;       // 5439
    w.p_dz_mean_sl5 = p.p_dz_mean_sl5;     // 5440
    w.p_dz_mean_s5 = p.p_dz_mean_s5;       // 5441
    w.p_z_curv_s1 = p.p_z_curv_s1;         // 5442
    w.p_z_curv_s2 = p.p_z_curv_s2;         // 5443
    w.s2leftmod = p.s2leftmod;             // 5444
    w.p_a_width_s2 = p.p_a_width_s2;       // 5445
    w.p_z_curv_s3 = p.p_z_curv_s3;         // 5446
    w.p_z_curv_s4 = p.p_z_curv_s4;         // 5447
    w.p_z_curv_sl5 = p.p_z_curv_sl5;       // 5448
    w.p_z_curv_s5 = p.p_z_curv_s5;         // 5449
    w.pz_s3_olap_pos = p.pz_s3_olap_pos;   // 5450
    w.pz_s3_olap_curv = p.pz_s3_olap_curv; // 5451
    w.delta_s0 = p.delta_s0;               // 5452
    w.p_shell_s1 = p.p_shell_s1;           // 5453
    w.p_shell_s2 = p.p_shell_s2;           // 5454
    w.p_shell_s3 = p.p_shell_s3;           // 5455
    w.p_shell_s4 = p.p_shell_s4;           // 5456
    w.p_shell_sl5 = p.p_shell_sl5;         // 5457
    w.p_shell_s5 = p.p_shell_s5;           // 5458
    w.de_defo_s1 = p.de_defo_s1;           // 5459
    w.de_defo_s2 = p.de_defo_s2;           // 5460
    w.de_defo_s3 = p.de_defo_s3;           // 5461
    w.de_defo_s4 = p.de_defo_s4;           // 5462
    w.de_defo_s5 = p.de_defo_s5;           // 5463
    w.betal0 = p.betal0;                   // 5464
    w.betal1 = p.betal1;                   // 5465
    w.betah0 = p.betah0;                   // 5466
    w.betah1 = p.betah1;                   // 5467
    w.dbeta_s3 = p.dbeta_s3;               // 5468
    w.t_low_s1 = p.t_low_s1;               // 5469
    w.t_low_s2 = p.t_low_s2;               // 5470
    w.t_low_s3 = p.t_low_s3;               // 5471
    w.t_low_s4 = p.t_low_s4;               // 5472
    w.t_low_s5 = p.t_low_s5;               // 5473
    w.t_low_sl = p.t_low_sl;               // 5474
    w.ecollfrac = p.ecollfrac;             // 5475
    w.edissfrac = p.edissfrac;             // 5476
    w.p_att_pol = p.p_att_pol;             // 5477
    w.p_att_rel = p.p_att_rel;             // 5478
    w.hompol = p.hompol;                   // 5479
    w.polaradd = p.polaradd;               // 5480
    w.jscaling = p.jscaling;               // 5481
}

} // namespace gef::tables
