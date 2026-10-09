// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "params/parameters.hpp"

namespace gef::params {

void load_parameters_bas(Parameters& p) {
    // The literals are those of the emitted C (GEF.c), which narrows each Double literal to Single.
    p.p_dz_mean_s1 = -0x1.BA5CA2p-3F;   // Parameters.bas:12
    p.p_dz_mean_s1 = -0x1.666666p-2F;   // Parameters.bas:13
    p.p_corr_s1 = -0x1.99999Ap-5F;      // Parameters.bas:14
    p.p_dz_mean_s2 = -0x1.1A3E2Cp-1F;   // Parameters.bas:15
    p.p_dz_mean_s2 = -0x1.8p-1F;        // Parameters.bas:16
    p.p_dz_mean_s3 = 0x1.5D58FEp-2F;    // Parameters.bas:17
    p.p_dz_mean_s4 = -0x1.9E5A1Ep-7F;   // Parameters.bas:18
    p.p_dz_mean_sl5 = 0x1.27141Ep-8F;   // Parameters.bas:19
    p.p_dz_mean_s5 = 0x1.81862Cp-5F;    // Parameters.bas:20
    p.zc_mode_sl5 = 0x1.633334p+5F;     // Parameters.bas:21
    p.p_z_curv_s1 = 0x1.7969C8p-2F;     // Parameters.bas:22
    p.p_z_curvmod_s1 = 0x1.Cp+0F;       // Parameters.bas:23
    p.p_z_curv_s2 = 0x1.6D7E2Ep-4F;     // Parameters.bas:24
    p.p_z_curv_s3 = 0x1.74BC6Ap-4F;     // Parameters.bas:25
    p.s2leftmod = 0x1.943B92p-1F;       // Parameters.bas:26
    p.p_z_curvmod_s2 = 0x1.4p+3F;       // Parameters.bas:27
    p.p_a_width_s2 = 0x1.78DEp+3F;      // Parameters.bas:28
    p.fmod_slope_s2 = 0x1.p+0F;         // Parameters.bas:29
    p.p_z_curv_s3 = 0x1.26E978p-4F;     // Parameters.bas:30
    p.p_z_curvmod_s3 = 0x1.4p+3F;       // Parameters.bas:31
    p.p_z_curv_s4 = 0x1.843448p-2F;     // Parameters.bas:32
    p.p_z_curvmod_s4 = 0x1.Cp+0F;       // Parameters.bas:33
    p.p_z_curv_sl5 = 0x1.1B0D1Ep-4F;    // Parameters.bas:34
    p.p_z_curv_sl5 = 0x1.47AE14p-7F;    // Parameters.bas:35
    p.p_z_curv_s5 = 0x1.B30F8Cp-5F;     // Parameters.bas:38
    p.p_z_curvmod_s5 = 0x1.4p+3F;       // Parameters.bas:39
    p.p_shell_s1 = -0x1.A66666p+1F;     // Parameters.bas:40
    p.p_shell_s1 = -0x1.266666p+1F;     // Parameters.bas:41
    p.p_shell_s2 = -0x1.D9999Ap+1F;     // Parameters.bas:42
    p.p_shell_s3 = -0x1.266666p+2F;     // Parameters.bas:43
    p.p_shell_s4 = -0x1.4AAF7Ep+2F;     // Parameters.bas:45
    p.p_shell_sl5 = -0x1.333334p-2F;    // Parameters.bas:46
    p.p_shell_sl5 = -0x1.C28F5Cp-3F;    // Parameters.bas:47
    p.p_shell_sl5 = -0x1.CCCCCCp-2F;    // Parameters.bas:48
    p.p_shell_s5 = -0x1.29701Ep+0F;     // Parameters.bas:49
    p.p_s5_mod = -0x1.1EB852p-5F;       // Parameters.bas:50
    p.pz_s3_olap_pos = 0x1.3D71DEp+5F;  // Parameters.bas:51
    p.pz_s3_olap_curv = 0x1.0BEE98p-8F; // Parameters.bas:52
    p.ethreshsupps1 = 0x1.5B3334p+3F;   // Parameters.bas:53
    p.esigsupps1 = 0x1.p+0F;            // Parameters.bas:54
    p.level_s11 = -0x1.99999Ap-4F;      // Parameters.bas:55
    p.shell_fading = 0x1.9p+5F;         // Parameters.bas:56
    p.t_low_s1 = 0x1.3D70A4p-2F;        // Parameters.bas:57
    p.t_low_s2 = 0x1.527F5Ep-2F;        // Parameters.bas:60
    p.t_low_s3 = 0x1.51EB86p-2F;        // Parameters.bas:61
    p.t_low_s4 = 0x1.FC71D6p-3F;        // Parameters.bas:62
    p.t_low_s5 = 0x1.374A12p-2F;        // Parameters.bas:63
    p.t_low_sl = 0x1.332074p-2F;        // Parameters.bas:64
    p.t_low_s11 = 0x1.p-2F;             // Parameters.bas:65
    p.t_low_s22 = 0x1.333334p-2F;       // Parameters.bas:66
    p.p_att_pol = 0x1.4F0386p+1F;       // Parameters.bas:67
    p.p_att_pol = 0x1.8p+0F;            // Parameters.bas:68
    p.p_att_pol2 = 0x0p+0F;             // Parameters.bas:69
    p.p_att_pol3 = 0x0p+0F;             // Parameters.bas:70
    p.p_att_rel = 0x1.p+0F;             // Parameters.bas:71
    p.de_defo_s1 = -0x1.036266p+2F;     // Parameters.bas:72
    p.de_defo_s2 = -0x1.9F85E4p-1F;     // Parameters.bas:73
    p.de_defo_s3 = 0x1.A11A7Cp-1F;      // Parameters.bas:74
    p.de_defo_s4 = -0x1.49CB32p+2F;     // Parameters.bas:75
    p.de_defo_s5 = -0x1.6A1FD8p-1F;     // Parameters.bas:76
    p.betal0 = 0x1.65EB86p+4F;          // Parameters.bas:78
    p.betal0 = 0x1.633334p+4F;          // Parameters.bas:79
    p.betal1 = 0x1.428F5Cp-1F;          // Parameters.bas:81
    p.betah0 = 0x1.81999Ap+5F;          // Parameters.bas:82
    p.betah1 = 0x1.666666p-1F;          // Parameters.bas:83
    p.dbeta_s3 = 0x0p+0F;               // Parameters.bas:84
    p.kappa = 0x0p+0F;                  // Parameters.bas:85
    p.tcollfrac = 0x1.47AE14p-5F;       // Parameters.bas:86
    p.ecollfrac = 0x1.47AE14p-7F;       // Parameters.bas:88
    p.tfcoll = 0x1.16872Cp-5F;          // Parameters.bas:89
    p.tcollmin = 0x1.EB851Ep-4F;        // Parameters.bas:90
    p.eshiftsasci_intr = -0x1.0Cp+6F;   // Parameters.bas:91
    p.eshiftsasci_coll = -0x1.68p+6F;   // Parameters.bas:92
    p.edissfrac = 0x1.A49F5Ep-2F;       // Parameters.bas:93
    p.epot_shift = 0x0p+0F;             // Parameters.bas:94
    p.sigdefo = 0x1.51EB86p-3F;         // Parameters.bas:95
    p.sigdefo_0 = 0x1.51EB86p-3F;       // Parameters.bas:96
    p.sigdefo_slope = 0x0p+0F;          // Parameters.bas:97
    p.sigeneck = 0x1.4p+2F;             // Parameters.bas:98
    p.eexcsigrel = 0x1.666666p-1F;      // Parameters.bas:99
    p.dneck = 0x1.p+0F;                 // Parameters.bas:100
    p.ftrunc50 = 0x1.p+0F;              // Parameters.bas:101
    p.ztrunc50 = 0x1.9p+5F;             // Parameters.bas:102
    p.ftrunc28 = 0x1.1EB852p-1F;        // Parameters.bas:103
    p.ztrunc28 = 0x1.E8p+4F;            // Parameters.bas:104
    p.zmax_s2 = 0x1.Ep+5F;              // Parameters.bas:105
    p.ntransfereo = 0x1.8p+2F;          // Parameters.bas:106
    p.ntransfere = 0x1.8p+3F;           // Parameters.bas:107
    p.csort = 0x1.p-1F;                 // Parameters.bas:108
    p.pz_eo_symm = 0x1.4CCCCCp+1F;      // Parameters.bas:109
    p.pn_eo_symm = 0x1.4CCCCCp+1F;      // Parameters.bas:110
    p.r_eo_thresh = 0x1.978D5p-2F;      // Parameters.bas:111
    p.r_eo_sigma = 0x1.p+1F;            // Parameters.bas:112
    p.r_eo_max = 0x1.333334p-1F;        // Parameters.bas:113
    p.polaradd = 0x1.AA93BCp-2F;        // Parameters.bas:114
    p.polarfac = 0x1.p+0F;              // Parameters.bas:115
    p.t_pol_red = 0x1.47AE14p-7F;       // Parameters.bas:116
    // NOLINTNEXTLINE(modernize-use-std-numbers): the fitted _HOMPOL = 1.61765, not phi
    p.hompol = 0x1.9E1E5p+0F;          // Parameters.bas:117
    p.zpol1 = 0x0p+0F;                 // Parameters.bas:118
    p.p_n_x = 0x0p+0F;                 // Parameters.bas:119
    p.tscale = 0x1.p+0F;               // Parameters.bas:120
    p.econd = 0x1.p+1F;                // Parameters.bas:121
    p.etrans = 0x1.3p+3F;              // Parameters.bas:123
    p.t_orbital = 0x0p+0F;             // Parameters.bas:124
    p.jscaling = 0x1.0096EEp+0F;       // Parameters.bas:125
    p.spin_odd = 0x1.99999Ap-2F;       // Parameters.bas:126
    p.esort_extend = 0x1.8p+0F;        // Parameters.bas:128
    p.esort_slope = 0x1.47AE14p-5F;    // Parameters.bas:129
    p.esort_slope_s0 = 0x1.99999Ap-3F; // Parameters.bas:130
}

PerturbationWidths initial_widths(Parameters const& p) {
    // Each line is the expression fbc emits: Double products in fbc's order, literal last
    // (B-004), narrowed to Single. GEF.bas:1356 `0 * Fred_par` is folded to a Single product.
    PerturbationWidths w;
    w.fred_par = 0x1.p-1F; // GEF.bas:1348
    w.var_p_dz_mean_s1 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1349
    w.var_p_corr_s1 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.47AE147AE147Bp-7); // GEF.bas:1350
    w.var_p_dz_mean_s2 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1351
    w.var_p_a_width_s2 =
        static_cast<float>((static_cast<double>(p.p_a_width_s2) * static_cast<double>(w.fred_par)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:1352
    w.var_p_dz_mean_s3 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1353
    w.var_p_dz_mean_s4 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1354
    w.var_p_dz_mean_sl5 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1355
    w.var_p_dz_mean_s5 = w.fred_par * 0x0p+0F;                                      // GEF.bas:1356
    w.var_delta_s0 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1357
    w.var_p_shell_s1 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1358
    w.var_p_shell_s2 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1359
    w.var_p_shell_s3 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.3333333333333p-2); // GEF.bas:1360
    w.var_p_shell_s4 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1361
    w.var_p_shell_sl5 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1362
    w.var_p_shell_s5 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-6); // GEF.bas:1363
    w.var_p_z_curv_s1 =
        static_cast<float>((static_cast<double>(p.p_z_curv_s1) * static_cast<double>(w.fred_par)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:1364
    w.var_p_z_curv_s2 =
        static_cast<float>((static_cast<double>(p.p_z_curv_s2) * static_cast<double>(w.fred_par)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:1365
    w.var_s2leftmod =
        static_cast<float>((static_cast<double>(p.s2leftmod) * static_cast<double>(w.fred_par)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:1366
    w.var_p_z_curv_s3 =
        static_cast<float>((static_cast<double>(p.p_z_curv_s3) * static_cast<double>(w.fred_par)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:1367
    w.var_p_z_curv_s4 =
        static_cast<float>((static_cast<double>(p.p_z_curv_s4) * static_cast<double>(w.fred_par)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:1368
    w.var_p_z_curv_sl5 =
        static_cast<float>((static_cast<double>(p.p_z_curv_sl5) * static_cast<double>(w.fred_par)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:1369
    w.var_p_z_curv_s5 =
        static_cast<float>((static_cast<double>(p.p_z_curv_s5) * static_cast<double>(w.fred_par)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:1370
    w.var_pz_s3_olap_pos =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.999999999999Ap-4); // GEF.bas:1371
    w.var_pz_s3_olap_curv =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.A36E2EB1C432Dp-13); // GEF.bas:1372
    w.var_de_defo_s1 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.p-2); // GEF.bas:1373
    w.var_de_defo_s2 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.p-2); // GEF.bas:1374
    w.var_de_defo_s3 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.p-2); // GEF.bas:1375
    w.var_de_defo_s4 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.p-2); // GEF.bas:1376
    w.var_de_defo_s5 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.p-2);            // GEF.bas:1377
    w.var_betal0 = static_cast<float>(static_cast<double>(w.fred_par) * 0x1.p+1); // GEF.bas:1378
    w.var_betal1 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.47AE147AE147Bp-6); // GEF.bas:1379
    w.var_betah0 = static_cast<float>(static_cast<double>(w.fred_par) * 0x1.p+1);   // GEF.bas:1380
    w.var_betah1 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.47AE147AE147Bp-6); // GEF.bas:1381
    w.var_dbeta_s3 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.999999999999Ap-4); // GEF.bas:1382
    w.var_t_low_s1 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.89374BC6A7EFAp-8); // GEF.bas:1383
    w.var_t_low_s2 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.89374BC6A7EFAp-8); // GEF.bas:1384
    w.var_t_low_s3 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.89374BC6A7EFAp-8); // GEF.bas:1385
    w.var_t_low_s4 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.89374BC6A7EFAp-8); // GEF.bas:1386
    w.var_t_low_s5 =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.89374BC6A7EFAp-8); // GEF.bas:1387
    w.var_t_low_sl =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.89374BC6A7EFAp-8); // GEF.bas:1388
    w.var_ecollfrac =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.999999999999Ap-5); // GEF.bas:1389
    w.var_edissfrac =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.999999999999Ap-5); // GEF.bas:1390
    w.var_p_att_pol =
        static_cast<float>((static_cast<double>(p.p_att_pol) * static_cast<double>(w.fred_par)) *
                           0x1.EB851EB851EB8p-4); // GEF.bas:1391
    w.var_hompol =
        static_cast<float>((static_cast<double>(p.hompol) * static_cast<double>(w.fred_par)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:1392
    w.var_polaradd =
        static_cast<float>(static_cast<double>(w.fred_par) * 0x1.EB851EB851EB8p-5); // GEF.bas:1393
    w.var_jscaling =
        static_cast<float>((static_cast<double>(p.jscaling) * static_cast<double>(w.fred_par)) *
                           0x0p+0); // GEF.bas:1394
    return w;
}

void update_widths(PerturbationWidths& w, Parameters const& p, float pz_s3_olap_curv) {
    w.var_p_dz_mean_s1 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2575
    w.var_p_corr_s1 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.47AE147AE147Bp-7); // GEF.bas:2576
    w.var_p_dz_mean_s2 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2577
    w.var_p_a_width_s2 = static_cast<float>(
        ((static_cast<double>(p.p_a_width_s2) * static_cast<double>(w.fred_par)) *
         static_cast<double>(p.d_par_fac)) *
        0x1.EB851EB851EB8p-6); // GEF.bas:2578
    w.var_p_dz_mean_s3 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2579
    w.var_p_dz_mean_s4 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2580
    w.var_p_dz_mean_sl5 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2581
    w.var_p_dz_mean_s5 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2582
    w.var_delta_s0 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2583
    w.var_p_shell_s1 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2584
    w.var_p_shell_s2 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2585
    w.var_p_shell_s3 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-4); // GEF.bas:2586
    w.var_p_shell_s4 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2587
    w.var_p_shell_sl5 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:2588
    w.var_p_shell_s5 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:2589
    w.var_de_defo_s1 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.p-2); // GEF.bas:2590
    w.var_de_defo_s2 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.p-2); // GEF.bas:2591
    w.var_de_defo_s3 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.p-2); // GEF.bas:2592
    w.var_de_defo_s4 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.p-2); // GEF.bas:2593
    w.var_de_defo_s5 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.p-2); // GEF.bas:2594
    w.var_betal0 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.p+1); // GEF.bas:2595
    w.var_betal1 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.47AE147AE147Bp-6); // GEF.bas:2596
    w.var_betah0 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.p+1); // GEF.bas:2597
    w.var_betah1 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.47AE147AE147Bp-6); // GEF.bas:2598
    w.var_dbeta_s3 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.999999999999Ap-5); // GEF.bas:2599
    w.var_ecollfrac =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.999999999999Ap-5); // GEF.bas:2600
    w.var_edissfrac =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.999999999999Ap-5); // GEF.bas:2601
    w.var_p_z_curv_s1 =
        static_cast<float>(((static_cast<double>(p.p_z_curv_s1) * static_cast<double>(w.fred_par)) *
                            static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:2602
    w.var_p_z_curv_s2 =
        static_cast<float>(((static_cast<double>(p.p_z_curv_s2) * static_cast<double>(w.fred_par)) *
                            static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:2603
    w.var_s2leftmod =
        static_cast<float>(((static_cast<double>(p.s2leftmod) * static_cast<double>(w.fred_par)) *
                            static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:2604
    w.var_p_z_curv_s3 =
        static_cast<float>(((static_cast<double>(p.p_z_curv_s3) * static_cast<double>(w.fred_par)) *
                            static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:2605
    w.var_p_z_curv_s4 =
        static_cast<float>(((static_cast<double>(p.p_z_curv_s4) * static_cast<double>(w.fred_par)) *
                            static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:2606
    w.var_p_z_curv_sl5 = static_cast<float>(
        ((static_cast<double>(p.p_z_curv_sl5) * static_cast<double>(w.fred_par)) *
         static_cast<double>(p.d_par_fac)) *
        0x1.EB851EB851EB8p-6); // GEF.bas:2607
    w.var_p_z_curv_s5 =
        static_cast<float>(((static_cast<double>(p.p_z_curv_s5) * static_cast<double>(w.fred_par)) *
                            static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-6); // GEF.bas:2608
    w.var_pz_s3_olap_pos =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.999999999999Ap-4); // GEF.bas:2609
    // QUIRK(Q-019): the working copy PZ_S3_olap_curv, not the nominal _PZ_S3_olap_curv
    w.var_pz_s3_olap_curv = static_cast<float>(
        ((static_cast<double>(w.fred_par) * static_cast<double>(pz_s3_olap_curv)) *
         static_cast<double>(p.d_par_fac)) *
        0x1.EB851EB851EB8p-6); // GEF.bas:2610
    w.var_t_low_s1 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.89374BC6A7EFAp-8); // GEF.bas:2611
    w.var_t_low_s2 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.89374BC6A7EFAp-8); // GEF.bas:2612
    w.var_t_low_s3 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.89374BC6A7EFAp-8); // GEF.bas:2613
    w.var_t_low_s4 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.89374BC6A7EFAp-8); // GEF.bas:2614
    w.var_t_low_s5 =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.89374BC6A7EFAp-8); // GEF.bas:2615
    w.var_t_low_sl =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.89374BC6A7EFAp-8); // GEF.bas:2616
    w.var_p_att_pol =
        static_cast<float>(((static_cast<double>(p.p_att_pol) * static_cast<double>(w.fred_par)) *
                            static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-4); // GEF.bas:2617
    w.var_hompol =
        static_cast<float>(((static_cast<double>(p.hompol) * static_cast<double>(w.fred_par)) *
                            static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2618
    w.var_polaradd =
        static_cast<float>((static_cast<double>(w.fred_par) * static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2619
    w.var_jscaling =
        static_cast<float>(((static_cast<double>(p.jscaling) * static_cast<double>(w.fred_par)) *
                            static_cast<double>(p.d_par_fac)) *
                           0x1.EB851EB851EB8p-5); // GEF.bas:2620
}

std::array<NominalParameter, 111> const nominal_parameters{{
    NominalParameter{.name = "Emax_valid", .member = &Parameters::emax_valid},
    NominalParameter{.name = "Eexc_min_multi", .member = &Parameters::eexc_min_multi},
    NominalParameter{.name = "_Delta_S0", .member = &Parameters::delta_s0},
    NominalParameter{.name = "EOscale", .member = &Parameters::eoscale},
    NominalParameter{.name = "Emode", .member = &Parameters::emode},
    NominalParameter{.name = "D_Par_Fac", .member = &Parameters::d_par_fac},
    NominalParameter{.name = "Chisqr_Fit_min", .member = &Parameters::chisqr_fit_min},
    NominalParameter{.name = "_P_DZ_Mean_S1", .member = &Parameters::p_dz_mean_s1},
    NominalParameter{.name = "_P_corr_S1", .member = &Parameters::p_corr_s1},
    NominalParameter{.name = "_P_DZ_Mean_S2", .member = &Parameters::p_dz_mean_s2},
    NominalParameter{.name = "_P_DZ_Mean_S3", .member = &Parameters::p_dz_mean_s3},
    NominalParameter{.name = "_P_DZ_Mean_S4", .member = &Parameters::p_dz_mean_s4},
    NominalParameter{.name = "_P_DZ_Mean_SL5", .member = &Parameters::p_dz_mean_sl5},
    NominalParameter{.name = "_P_DZ_Mean_S5", .member = &Parameters::p_dz_mean_s5},
    NominalParameter{.name = "ZC_Mode_SL5", .member = &Parameters::zc_mode_sl5},
    NominalParameter{.name = "_P_Z_Curv_S1", .member = &Parameters::p_z_curv_s1},
    NominalParameter{.name = "P_Z_Curvmod_S1", .member = &Parameters::p_z_curvmod_s1},
    NominalParameter{.name = "_P_Z_CurV_S2", .member = &Parameters::p_z_curv_s2},
    NominalParameter{.name = "_S2leftmod", .member = &Parameters::s2leftmod},
    NominalParameter{.name = "P_Z_Curvmod_S2", .member = &Parameters::p_z_curvmod_s2},
    NominalParameter{.name = "_P_A_Width_S2", .member = &Parameters::p_a_width_s2},
    NominalParameter{.name = "P_Cut_S2", .member = &Parameters::p_cut_s2},
    NominalParameter{.name = "Fmod_slope_S2", .member = &Parameters::fmod_slope_s2},
    NominalParameter{.name = "_P_Z_Curv_S3", .member = &Parameters::p_z_curv_s3},
    NominalParameter{.name = "P_Z_Curvmod_S3", .member = &Parameters::p_z_curvmod_s3},
    NominalParameter{.name = "_P_Z_Curv_S4", .member = &Parameters::p_z_curv_s4},
    NominalParameter{.name = "_P_Z_Curv_SL5", .member = &Parameters::p_z_curv_sl5},
    NominalParameter{.name = "_P_Z_Curv_S5", .member = &Parameters::p_z_curv_s5},
    NominalParameter{.name = "P_Z_Curvmod_S4", .member = &Parameters::p_z_curvmod_s4},
    NominalParameter{.name = "P_Z_Curvmod_S5", .member = &Parameters::p_z_curvmod_s5},
    NominalParameter{.name = "_P_Shell_S1", .member = &Parameters::p_shell_s1},
    NominalParameter{.name = "_P_Shell_S2", .member = &Parameters::p_shell_s2},
    NominalParameter{.name = "_P_Shell_S3", .member = &Parameters::p_shell_s3},
    NominalParameter{.name = "_P_Shell_S4", .member = &Parameters::p_shell_s4},
    NominalParameter{.name = "_P_Shell_SL5", .member = &Parameters::p_shell_sl5},
    NominalParameter{.name = "_P_Shell_S5", .member = &Parameters::p_shell_s5},
    NominalParameter{.name = "P_S5_mod", .member = &Parameters::p_s5_mod},
    NominalParameter{.name = "_PZ_S3_olap_pos", .member = &Parameters::pz_s3_olap_pos},
    NominalParameter{.name = "_PZ_S3_olap_curv", .member = &Parameters::pz_s3_olap_curv},
    NominalParameter{.name = "ETHRESHSUPPS1", .member = &Parameters::ethreshsupps1},
    NominalParameter{.name = "ESIGSUPPS1", .member = &Parameters::esigsupps1},
    NominalParameter{.name = "Level_S11", .member = &Parameters::level_s11},
    NominalParameter{.name = "Shell_fading", .member = &Parameters::shell_fading},
    NominalParameter{.name = "_T_low_S1", .member = &Parameters::t_low_s1},
    NominalParameter{.name = "_T_low_S2", .member = &Parameters::t_low_s2},
    NominalParameter{.name = "_T_low_S3", .member = &Parameters::t_low_s3},
    NominalParameter{.name = "_T_low_S4", .member = &Parameters::t_low_s4},
    NominalParameter{.name = "_T_low_S5", .member = &Parameters::t_low_s5},
    NominalParameter{.name = "_T_low_SL", .member = &Parameters::t_low_sl},
    NominalParameter{.name = "T_low_S11", .member = &Parameters::t_low_s11},
    NominalParameter{.name = "T_low_S22", .member = &Parameters::t_low_s22},
    NominalParameter{.name = "_P_att_pol", .member = &Parameters::p_att_pol},
    NominalParameter{.name = "P_att_pol2", .member = &Parameters::p_att_pol2},
    NominalParameter{.name = "P_att_pol3", .member = &Parameters::p_att_pol3},
    NominalParameter{.name = "_P_att_rel", .member = &Parameters::p_att_rel},
    NominalParameter{.name = "_dE_Defo_S1", .member = &Parameters::de_defo_s1},
    NominalParameter{.name = "_dE_Defo_S2", .member = &Parameters::de_defo_s2},
    NominalParameter{.name = "_dE_Defo_S3", .member = &Parameters::de_defo_s3},
    NominalParameter{.name = "_dE_Defo_S4", .member = &Parameters::de_defo_s4},
    NominalParameter{.name = "_dE_Defo_S5", .member = &Parameters::de_defo_s5},
    NominalParameter{.name = "_betaL0", .member = &Parameters::betal0},
    NominalParameter{.name = "_betaL1", .member = &Parameters::betal1},
    NominalParameter{.name = "_betaH0", .member = &Parameters::betah0},
    NominalParameter{.name = "_betaH1", .member = &Parameters::betah1},
    NominalParameter{.name = "_dbeta_S3", .member = &Parameters::dbeta_s3},
    NominalParameter{.name = "kappa", .member = &Parameters::kappa},
    NominalParameter{.name = "kappa4", .member = &Parameters::kappa4},
    NominalParameter{.name = "BFC", .member = &Parameters::bfc},
    NominalParameter{.name = "TCOLLFRAC", .member = &Parameters::tcollfrac},
    NominalParameter{.name = "_ECOLLFRAC", .member = &Parameters::ecollfrac},
    NominalParameter{.name = "TFCOLL", .member = &Parameters::tfcoll},
    NominalParameter{.name = "TCOLLMIN", .member = &Parameters::tcollmin},
    NominalParameter{.name = "ESHIFTSASCI_intr", .member = &Parameters::eshiftsasci_intr},
    NominalParameter{.name = "ESHIFTSASCI_coll", .member = &Parameters::eshiftsasci_coll},
    NominalParameter{.name = "_EDISSFRAC", .member = &Parameters::edissfrac},
    NominalParameter{.name = "Epot_shift", .member = &Parameters::epot_shift},
    NominalParameter{.name = "SIGDEFO", .member = &Parameters::sigdefo},
    NominalParameter{.name = "SIGDEFO_0", .member = &Parameters::sigdefo_0},
    NominalParameter{.name = "SIGDEFO_slope", .member = &Parameters::sigdefo_slope},
    NominalParameter{.name = "SIGENECK", .member = &Parameters::sigeneck},
    NominalParameter{.name = "EexcSIGrel", .member = &Parameters::eexcsigrel},
    NominalParameter{.name = "DNECK", .member = &Parameters::dneck},
    NominalParameter{.name = "FTRUNC50", .member = &Parameters::ftrunc50},
    NominalParameter{.name = "ZTRUNC50", .member = &Parameters::ztrunc50},
    NominalParameter{.name = "FTRUNC28", .member = &Parameters::ftrunc28},
    NominalParameter{.name = "ZTRUNC28", .member = &Parameters::ztrunc28},
    NominalParameter{.name = "ZMAX_S2", .member = &Parameters::zmax_s2},
    NominalParameter{.name = "NTRANSFEREO", .member = &Parameters::ntransfereo},
    NominalParameter{.name = "NTRANSFERE", .member = &Parameters::ntransfere},
    NominalParameter{.name = "Csort", .member = &Parameters::csort},
    NominalParameter{.name = "PZ_EO_symm", .member = &Parameters::pz_eo_symm},
    NominalParameter{.name = "PN_EO_Symm", .member = &Parameters::pn_eo_symm},
    NominalParameter{.name = "R_EO_THRESH", .member = &Parameters::r_eo_thresh},
    NominalParameter{.name = "R_EO_SIGMA", .member = &Parameters::r_eo_sigma},
    NominalParameter{.name = "R_EO_MAX", .member = &Parameters::r_eo_max},
    NominalParameter{.name = "_POLARadd", .member = &Parameters::polaradd},
    NominalParameter{.name = "POLARfac", .member = &Parameters::polarfac},
    NominalParameter{.name = "T_POL_RED", .member = &Parameters::t_pol_red},
    NominalParameter{.name = "_HOMPOL", .member = &Parameters::hompol},
    NominalParameter{.name = "ZPOL1", .member = &Parameters::zpol1},
    NominalParameter{.name = "P_n_x", .member = &Parameters::p_n_x},
    NominalParameter{.name = "Tscale", .member = &Parameters::tscale},
    NominalParameter{.name = "Econd", .member = &Parameters::econd},
    NominalParameter{.name = "Etrans", .member = &Parameters::etrans},
    NominalParameter{.name = "T_orbital", .member = &Parameters::t_orbital},
    NominalParameter{.name = "_Jscaling", .member = &Parameters::jscaling},
    NominalParameter{.name = "Spin_odd", .member = &Parameters::spin_odd},
    NominalParameter{.name = "Esort_extend", .member = &Parameters::esort_extend},
    NominalParameter{.name = "Esort_slope", .member = &Parameters::esort_slope},
    NominalParameter{.name = "Esort_slope_S0", .member = &Parameters::esort_slope_s0},
    NominalParameter{.name = "B_MyParameters", .member = &Parameters::b_myparameters},
}};

std::array<WidthParameter, 47> const width_parameters{{
    WidthParameter{.name = "Fred_par", .member = &PerturbationWidths::fred_par},
    WidthParameter{.name = "Var_P_DZ_Mean_S1", .member = &PerturbationWidths::var_p_dz_mean_s1},
    WidthParameter{.name = "Var_P_Corr_S1", .member = &PerturbationWidths::var_p_corr_s1},
    WidthParameter{.name = "Var_P_DZ_Mean_S2", .member = &PerturbationWidths::var_p_dz_mean_s2},
    WidthParameter{.name = "Var_P_A_Width_S2", .member = &PerturbationWidths::var_p_a_width_s2},
    WidthParameter{.name = "Var_P_DZ_Mean_S3", .member = &PerturbationWidths::var_p_dz_mean_s3},
    WidthParameter{.name = "Var_P_DZ_Mean_S4", .member = &PerturbationWidths::var_p_dz_mean_s4},
    WidthParameter{.name = "Var_P_DZ_Mean_SL5", .member = &PerturbationWidths::var_p_dz_mean_sl5},
    WidthParameter{.name = "Var_P_DZ_Mean_S5", .member = &PerturbationWidths::var_p_dz_mean_s5},
    WidthParameter{.name = "Var_Delta_S0", .member = &PerturbationWidths::var_delta_s0},
    WidthParameter{.name = "Var_P_Shell_S1", .member = &PerturbationWidths::var_p_shell_s1},
    WidthParameter{.name = "Var_P_Shell_S2", .member = &PerturbationWidths::var_p_shell_s2},
    WidthParameter{.name = "Var_P_Shell_S3", .member = &PerturbationWidths::var_p_shell_s3},
    WidthParameter{.name = "Var_P_Shell_S4", .member = &PerturbationWidths::var_p_shell_s4},
    WidthParameter{.name = "Var_P_Shell_SL5", .member = &PerturbationWidths::var_p_shell_sl5},
    WidthParameter{.name = "Var_P_Shell_S5", .member = &PerturbationWidths::var_p_shell_s5},
    WidthParameter{.name = "Var_P_Z_Curv_S1", .member = &PerturbationWidths::var_p_z_curv_s1},
    WidthParameter{.name = "Var_P_Z_Curv_S2", .member = &PerturbationWidths::var_p_z_curv_s2},
    WidthParameter{.name = "Var_S2leftmod", .member = &PerturbationWidths::var_s2leftmod},
    WidthParameter{.name = "Var_P_Z_Curv_S3", .member = &PerturbationWidths::var_p_z_curv_s3},
    WidthParameter{.name = "Var_P_Z_Curv_S4", .member = &PerturbationWidths::var_p_z_curv_s4},
    WidthParameter{.name = "Var_P_Z_Curv_SL5", .member = &PerturbationWidths::var_p_z_curv_sl5},
    WidthParameter{.name = "Var_P_Z_Curv_S5", .member = &PerturbationWidths::var_p_z_curv_s5},
    WidthParameter{.name = "Var_PZ_S3_olap_pos", .member = &PerturbationWidths::var_pz_s3_olap_pos},
    WidthParameter{.name = "Var_PZ_S3_olap_curv",
                   .member = &PerturbationWidths::var_pz_s3_olap_curv},
    WidthParameter{.name = "Var_dE_Defo_S1", .member = &PerturbationWidths::var_de_defo_s1},
    WidthParameter{.name = "Var_dE_Defo_S2", .member = &PerturbationWidths::var_de_defo_s2},
    WidthParameter{.name = "Var_dE_Defo_S3", .member = &PerturbationWidths::var_de_defo_s3},
    WidthParameter{.name = "Var_dE_Defo_S4", .member = &PerturbationWidths::var_de_defo_s4},
    WidthParameter{.name = "Var_dE_Defo_S5", .member = &PerturbationWidths::var_de_defo_s5},
    WidthParameter{.name = "Var_betaL0", .member = &PerturbationWidths::var_betal0},
    WidthParameter{.name = "Var_betaL1", .member = &PerturbationWidths::var_betal1},
    WidthParameter{.name = "Var_betaH0", .member = &PerturbationWidths::var_betah0},
    WidthParameter{.name = "Var_betaH1", .member = &PerturbationWidths::var_betah1},
    WidthParameter{.name = "Var_dbeta_S3", .member = &PerturbationWidths::var_dbeta_s3},
    WidthParameter{.name = "Var_T_low_S1", .member = &PerturbationWidths::var_t_low_s1},
    WidthParameter{.name = "Var_T_low_S2", .member = &PerturbationWidths::var_t_low_s2},
    WidthParameter{.name = "Var_T_low_S3", .member = &PerturbationWidths::var_t_low_s3},
    WidthParameter{.name = "Var_T_low_S4", .member = &PerturbationWidths::var_t_low_s4},
    WidthParameter{.name = "Var_T_low_S5", .member = &PerturbationWidths::var_t_low_s5},
    WidthParameter{.name = "Var_T_low_SL", .member = &PerturbationWidths::var_t_low_sl},
    WidthParameter{.name = "Var_ECOLLFRAC", .member = &PerturbationWidths::var_ecollfrac},
    WidthParameter{.name = "Var_EDISSFRAC", .member = &PerturbationWidths::var_edissfrac},
    WidthParameter{.name = "Var_P_att_pol", .member = &PerturbationWidths::var_p_att_pol},
    WidthParameter{.name = "Var_HOMPOL", .member = &PerturbationWidths::var_hompol},
    WidthParameter{.name = "Var_POLARadd", .member = &PerturbationWidths::var_polaradd},
    WidthParameter{.name = "Var_Jscaling", .member = &PerturbationWidths::var_jscaling},
}};

std::array<PerturbedParameter, 46> const perturbation_order{{
    // GEF.bas:5112
    PerturbedParameter{.working_name = "P_DZ_Mean_S1",
                       .nominal_name = "_P_DZ_Mean_S1",
                       .nominal = &Parameters::p_dz_mean_s1,
                       .width_name = "Var_P_DZ_Mean_S1",
                       .width = &PerturbationWidths::var_p_dz_mean_s1},
    // GEF.bas:5113
    PerturbedParameter{.working_name = "P_corr_S1",
                       .nominal_name = "_P_corr_S1",
                       .nominal = &Parameters::p_corr_s1,
                       .width_name = "Var_P_Corr_S1",
                       .width = &PerturbationWidths::var_p_corr_s1},
    // GEF.bas:5114
    PerturbedParameter{.working_name = "P_DZ_Mean_S2",
                       .nominal_name = "_P_DZ_Mean_S2",
                       .nominal = &Parameters::p_dz_mean_s2,
                       .width_name = "Var_P_DZ_Mean_S2",
                       .width = &PerturbationWidths::var_p_dz_mean_s2},
    // GEF.bas:5115
    PerturbedParameter{.working_name = "P_DZ_Mean_S3",
                       .nominal_name = "_P_DZ_Mean_S3",
                       .nominal = &Parameters::p_dz_mean_s3,
                       .width_name = "Var_P_DZ_Mean_S3",
                       .width = &PerturbationWidths::var_p_dz_mean_s3},
    // GEF.bas:5116
    PerturbedParameter{.working_name = "P_DZ_Mean_S4",
                       .nominal_name = "_P_DZ_Mean_S4",
                       .nominal = &Parameters::p_dz_mean_s4,
                       .width_name = "Var_P_DZ_Mean_S4",
                       .width = &PerturbationWidths::var_p_dz_mean_s4},
    // GEF.bas:5117
    PerturbedParameter{.working_name = "P_DZ_Mean_SL5",
                       .nominal_name = "_P_DZ_Mean_SL5",
                       .nominal = &Parameters::p_dz_mean_sl5,
                       .width_name = "Var_P_DZ_Mean_SL5",
                       .width = &PerturbationWidths::var_p_dz_mean_sl5},
    // GEF.bas:5118
    PerturbedParameter{.working_name = "P_DZ_Mean_S5",
                       .nominal_name = "_P_DZ_Mean_S5",
                       .nominal = &Parameters::p_dz_mean_s5,
                       .width_name = "Var_P_DZ_Mean_S5",
                       .width = &PerturbationWidths::var_p_dz_mean_s5},
    // GEF.bas:5119
    PerturbedParameter{.working_name = "P_Z_Curv_S1",
                       .nominal_name = "_P_Z_Curv_S1",
                       .nominal = &Parameters::p_z_curv_s1,
                       .width_name = "Var_P_Z_Curv_S1",
                       .width = &PerturbationWidths::var_p_z_curv_s1},
    // GEF.bas:5120
    PerturbedParameter{.working_name = "P_Z_Curv_S2",
                       .nominal_name = "_P_Z_CurV_S2",
                       .nominal = &Parameters::p_z_curv_s2,
                       .width_name = "Var_P_Z_Curv_S2",
                       .width = &PerturbationWidths::var_p_z_curv_s2},
    // GEF.bas:5121
    PerturbedParameter{.working_name = "S2leftmod",
                       .nominal_name = "_S2leftmod",
                       .nominal = &Parameters::s2leftmod,
                       .width_name = "Var_S2leftmod",
                       .width = &PerturbationWidths::var_s2leftmod},
    // GEF.bas:5122
    PerturbedParameter{.working_name = "P_A_Width_S2",
                       .nominal_name = "_P_A_Width_S2",
                       .nominal = &Parameters::p_a_width_s2,
                       .width_name = "Var_P_A_Width_S2",
                       .width = &PerturbationWidths::var_p_a_width_s2},
    // GEF.bas:5123
    PerturbedParameter{.working_name = "P_Z_Curv_S3",
                       .nominal_name = "_P_Z_Curv_S3",
                       .nominal = &Parameters::p_z_curv_s3,
                       .width_name = "Var_P_Z_Curv_S3",
                       .width = &PerturbationWidths::var_p_z_curv_s3},
    // GEF.bas:5124
    PerturbedParameter{.working_name = "P_Z_Curv_S4",
                       .nominal_name = "_P_Z_Curv_S4",
                       .nominal = &Parameters::p_z_curv_s4,
                       .width_name = "Var_P_Z_Curv_S4",
                       .width = &PerturbationWidths::var_p_z_curv_s4},
    // GEF.bas:5125
    PerturbedParameter{.working_name = "P_Z_Curv_SL5",
                       .nominal_name = "_P_Z_Curv_SL5",
                       .nominal = &Parameters::p_z_curv_sl5,
                       .width_name = "Var_P_Z_Curv_SL5",
                       .width = &PerturbationWidths::var_p_z_curv_sl5},
    // GEF.bas:5126
    PerturbedParameter{.working_name = "P_Z_Curv_S5",
                       .nominal_name = "_P_Z_Curv_S5",
                       .nominal = &Parameters::p_z_curv_s5,
                       .width_name = "Var_P_Z_Curv_S5",
                       .width = &PerturbationWidths::var_p_z_curv_s5},
    // GEF.bas:5127
    PerturbedParameter{.working_name = "PZ_S3_olap_pos",
                       .nominal_name = "_PZ_S3_olap_pos",
                       .nominal = &Parameters::pz_s3_olap_pos,
                       .width_name = "Var_PZ_S3_olap_pos",
                       .width = &PerturbationWidths::var_pz_s3_olap_pos},
    // GEF.bas:5128
    PerturbedParameter{.working_name = "PZ_S3_olap_curv",
                       .nominal_name = "_PZ_S3_olap_curv",
                       .nominal = &Parameters::pz_s3_olap_curv,
                       .width_name = "Var_PZ_S3_olap_curv",
                       .width = &PerturbationWidths::var_pz_s3_olap_curv},
    // GEF.bas:5129
    PerturbedParameter{.working_name = "Delta_S0",
                       .nominal_name = "_Delta_S0",
                       .nominal = &Parameters::delta_s0,
                       .width_name = "Var_Delta_S0",
                       .width = &PerturbationWidths::var_delta_s0},
    // GEF.bas:5130
    PerturbedParameter{.working_name = "P_Shell_S1",
                       .nominal_name = "_P_Shell_S1",
                       .nominal = &Parameters::p_shell_s1,
                       .width_name = "Var_P_Shell_S1",
                       .width = &PerturbationWidths::var_p_shell_s1},
    // GEF.bas:5131
    PerturbedParameter{.working_name = "P_Shell_S2",
                       .nominal_name = "_P_Shell_S2",
                       .nominal = &Parameters::p_shell_s2,
                       .width_name = "Var_P_Shell_S2",
                       .width = &PerturbationWidths::var_p_shell_s2},
    // GEF.bas:5132
    PerturbedParameter{.working_name = "P_Shell_S3",
                       .nominal_name = "_P_Shell_S3",
                       .nominal = &Parameters::p_shell_s3,
                       .width_name = "Var_P_Shell_S3",
                       .width = &PerturbationWidths::var_p_shell_s3},
    // GEF.bas:5133
    PerturbedParameter{.working_name = "P_Shell_S4",
                       .nominal_name = "_P_Shell_S4",
                       .nominal = &Parameters::p_shell_s4,
                       .width_name = "Var_P_Shell_S4",
                       .width = &PerturbationWidths::var_p_shell_s4},
    // GEF.bas:5134
    PerturbedParameter{.working_name = "P_Shell_SL5",
                       .nominal_name = "_P_Shell_SL5",
                       .nominal = &Parameters::p_shell_sl5,
                       .width_name = "Var_P_Shell_SL5",
                       .width = &PerturbationWidths::var_p_shell_sl5},
    // GEF.bas:5135
    PerturbedParameter{.working_name = "P_Shell_S5",
                       .nominal_name = "_P_Shell_S5",
                       .nominal = &Parameters::p_shell_s5,
                       .width_name = "Var_P_Shell_S5",
                       .width = &PerturbationWidths::var_p_shell_s5},
    // GEF.bas:5136
    PerturbedParameter{.working_name = "dE_Defo_S1",
                       .nominal_name = "_dE_Defo_S1",
                       .nominal = &Parameters::de_defo_s1,
                       .width_name = "Var_dE_Defo_S1",
                       .width = &PerturbationWidths::var_de_defo_s1},
    // GEF.bas:5137
    PerturbedParameter{.working_name = "dE_Defo_S2",
                       .nominal_name = "_dE_Defo_S2",
                       .nominal = &Parameters::de_defo_s2,
                       .width_name = "Var_dE_Defo_S2",
                       .width = &PerturbationWidths::var_de_defo_s2},
    // GEF.bas:5138
    PerturbedParameter{.working_name = "dE_Defo_S3",
                       .nominal_name = "_dE_Defo_S3",
                       .nominal = &Parameters::de_defo_s3,
                       .width_name = "Var_dE_Defo_S3",
                       .width = &PerturbationWidths::var_de_defo_s3},
    // GEF.bas:5139
    PerturbedParameter{.working_name = "dE_Defo_S4",
                       .nominal_name = "_dE_Defo_S4",
                       .nominal = &Parameters::de_defo_s4,
                       .width_name = "Var_dE_Defo_S4",
                       .width = &PerturbationWidths::var_de_defo_s4},
    // GEF.bas:5140
    PerturbedParameter{.working_name = "dE_Defo_S5",
                       .nominal_name = "_dE_Defo_S5",
                       .nominal = &Parameters::de_defo_s5,
                       .width_name = "Var_dE_Defo_S5",
                       .width = &PerturbationWidths::var_de_defo_s5},
    // GEF.bas:5141
    PerturbedParameter{.working_name = "betaL0",
                       .nominal_name = "_betaL0",
                       .nominal = &Parameters::betal0,
                       .width_name = "Var_betaL0",
                       .width = &PerturbationWidths::var_betal0},
    // GEF.bas:5142
    PerturbedParameter{.working_name = "betaL1",
                       .nominal_name = "_betaL1",
                       .nominal = &Parameters::betal1,
                       .width_name = "Var_betaL1",
                       .width = &PerturbationWidths::var_betal1},
    // GEF.bas:5143
    PerturbedParameter{.working_name = "betaH0",
                       .nominal_name = "_betaH0",
                       .nominal = &Parameters::betah0,
                       .width_name = "Var_betaH0",
                       .width = &PerturbationWidths::var_betah0},
    // GEF.bas:5144
    PerturbedParameter{.working_name = "betaH1",
                       .nominal_name = "_betaH1",
                       .nominal = &Parameters::betah1,
                       .width_name = "Var_betaH1",
                       .width = &PerturbationWidths::var_betah1},
    // GEF.bas:5145
    PerturbedParameter{.working_name = "dbeta_S3",
                       .nominal_name = "_dbeta_S3",
                       .nominal = &Parameters::dbeta_s3,
                       .width_name = "Var_dbeta_S3",
                       .width = &PerturbationWidths::var_dbeta_s3},
    // GEF.bas:5146
    PerturbedParameter{.working_name = "T_low_SL",
                       .nominal_name = "_T_low_SL",
                       .nominal = &Parameters::t_low_sl,
                       .width_name = "Var_T_low_SL",
                       .width = &PerturbationWidths::var_t_low_sl},
    // GEF.bas:5147
    PerturbedParameter{.working_name = "T_low_S1",
                       .nominal_name = "_T_low_S1",
                       .nominal = &Parameters::t_low_s1,
                       .width_name = "Var_T_low_S1",
                       .width = &PerturbationWidths::var_t_low_s1},
    // GEF.bas:5148
    PerturbedParameter{.working_name = "T_low_S2",
                       .nominal_name = "_T_low_S2",
                       .nominal = &Parameters::t_low_s2,
                       .width_name = "Var_T_low_S2",
                       .width = &PerturbationWidths::var_t_low_s2},
    // GEF.bas:5149
    PerturbedParameter{.working_name = "T_low_S3",
                       .nominal_name = "_T_low_S3",
                       .nominal = &Parameters::t_low_s3,
                       .width_name = "Var_T_low_S3",
                       .width = &PerturbationWidths::var_t_low_s3},
    // GEF.bas:5150
    PerturbedParameter{.working_name = "T_low_S4",
                       .nominal_name = "_T_low_S4",
                       .nominal = &Parameters::t_low_s4,
                       .width_name = "Var_T_low_S4",
                       .width = &PerturbationWidths::var_t_low_s4},
    // GEF.bas:5151
    PerturbedParameter{.working_name = "T_low_S5",
                       .nominal_name = "_T_low_S5",
                       .nominal = &Parameters::t_low_s5,
                       .width_name = "Var_T_low_S5",
                       .width = &PerturbationWidths::var_t_low_s5},
    // GEF.bas:5152
    PerturbedParameter{.working_name = "ECOLLFRAC",
                       .nominal_name = "_ECOLLFRAC",
                       .nominal = &Parameters::ecollfrac,
                       .width_name = "Var_ECOLLFRAC",
                       .width = &PerturbationWidths::var_ecollfrac},
    // GEF.bas:5153
    PerturbedParameter{.working_name = "EDISSFRAC",
                       .nominal_name = "_EDISSFRAC",
                       .nominal = &Parameters::edissfrac,
                       .width_name = "Var_EDISSFRAC",
                       .width = &PerturbationWidths::var_edissfrac},
    // GEF.bas:5154
    PerturbedParameter{.working_name = "P_att_pol",
                       .nominal_name = "_P_att_pol",
                       .nominal = &Parameters::p_att_pol,
                       .width_name = "Var_P_att_pol",
                       .width = &PerturbationWidths::var_p_att_pol},
    // GEF.bas:5158
    PerturbedParameter{.working_name = "HOMPOL",
                       .nominal_name = "_HOMPOL",
                       .nominal = &Parameters::hompol,
                       .width_name = "Var_HOMPOL",
                       .width = &PerturbationWidths::var_hompol},
    // GEF.bas:5159
    PerturbedParameter{.working_name = "POLARadd",
                       .nominal_name = "_POLARadd",
                       .nominal = &Parameters::polaradd,
                       .width_name = "Var_POLARadd",
                       .width = &PerturbationWidths::var_polaradd},
    // GEF.bas:5160
    PerturbedParameter{.working_name = "Jscaling",
                       .nominal_name = "_Jscaling",
                       .nominal = &Parameters::jscaling,
                       .width_name = "Var_Jscaling",
                       .width = &PerturbationWidths::var_jscaling},
}};

} // namespace gef::params
