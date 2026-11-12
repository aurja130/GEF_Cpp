// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF.bas:6561-7036 and 7920, transcribed from the C fbc 1.10.1 emits for them. Comparisons of
// Singles keep the C's form (`goto` on the negated condition), so that a NaN takes the branch it
// takes in BASIC.

#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "fbrt/text.hpp"
#include "physics/level_density.hpp"
#include "physics/masses.hpp"
#include "physics/shape.hpp"
#include "tables/builder.hpp"
#include "tables/fragment_memory.hpp"
#include "tables/z_a_relation.hpp"

#include <cmath>
#include <cstdint>
#include <numbers>

namespace gef::tables {

namespace {

// The bracket of 6575-6589: P*R_Att / (R_Z_Curv_S0 + P*R_Att) - P / (R_Z_Curv_S0 + P), with
// P = P_Z_Curv_Sk_eff.
float shift_fraction(float p_eff, float r_att, float r_z_curv_s0) {
    return static_cast<float>(static_cast<double>(p_eff * r_att) /
                              static_cast<double>(r_z_curv_s0 + (p_eff * r_att))) -
           static_cast<float>(static_cast<double>(p_eff) /
                              static_cast<double>(r_z_curv_s0 + p_eff));
}

// GEF.bas:6561-6609: energy-dependent shift of the modes' Z centres.
void energy_dependent_shifts(WorkingParameters const& w, params::Parameters const& p,
                             BinTables& t) {
    // 6565-6573
    float const p_z_curv_s1_eff = w.p_z_curv_s1 * p.p_z_curvmod_s1;
    float const p_z_curv_s2_eff = w.p_z_curv_s2 * p.p_z_curvmod_s2;
    float const p_z_curv_s3_eff = w.p_z_curv_s3 * p.p_z_curvmod_s3;
    float const p_z_curv_s4_eff = w.p_z_curv_s4 * p.p_z_curvmod_s4;
    float const p_z_curv_s5_eff = w.p_z_curv_s5 * p.p_z_curvmod_s5;
    // 6575-6586
    float const dz_s1 = t.zc_mode_1 * shift_fraction(p_z_curv_s1_eff, t.r_att(1), t.r_z_curv_s0);
    float const dz_s2 = t.zc_mode_2 * shift_fraction(p_z_curv_s2_eff, t.r_att(2), t.r_z_curv_s0);
    float const dz_s3 = t.zc_mode_3 * shift_fraction(p_z_curv_s3_eff, t.r_att(3), t.r_z_curv_s0);
    float const dz_s4 = t.zc_mode_4 * shift_fraction(p_z_curv_s4_eff, t.r_att(4), t.r_z_curv_s0);
    // 6587
    std::int32_t const vr1 = fb::sgn(t.zc_mode_5 - t.zc_mode_0);
    float const dz_s5 = (static_cast<float>(static_cast<std::int64_t>(vr1)) * t.zc_mode_5) *
                        shift_fraction(p_z_curv_s5_eff, t.r_att(5), t.r_z_curv_s0);
    // 6598-6608
    t.p_z_mean_s0 = t.zc_mode_0;
    t.zc_mode_1 = t.zc_mode_1 + dz_s1;
    t.p_z_mean_s1 = t.zc_mode_1;
    t.zc_mode_2 = t.zc_mode_2 + dz_s2;
    t.p_z_mean_s2 = t.zc_mode_2;
    t.zc_mode_3 = t.zc_mode_3 + dz_s3;
    t.p_z_mean_s3 = t.zc_mode_3;
    t.zc_mode_4 = t.zc_mode_4 + dz_s4;
    t.p_z_mean_s4 = t.zc_mode_4;
    t.zc_mode_5 = t.zc_mode_5 + dz_s5;
    t.p_z_mean_s5 = t.zc_mode_5;
}

// SNmac, SPmac of 6655-6656: the liquid-drop neutron and proton separation energies of the
// compound nucleus.
struct SeparationEnergies {
    float sn_mac;
    float sp_mac;
};
SeparationEnergies separation_energies(BinInput const& bin) {
    float const vr2 =
        physics::ly_mass(static_cast<float>(bin.i_z_cn),
                         static_cast<float>(static_cast<double>(bin.i_a_cn) + -0x1.p+0), 0x0p+0F);
    float const vr3 =
        physics::ly_mass(static_cast<float>(bin.i_z_cn), static_cast<float>(bin.i_a_cn), 0x0p+0F);
    float const sn_mac = vr2 - vr3;
    float const vr4 =
        physics::ly_mass(static_cast<float>(static_cast<double>(bin.i_z_cn) + -0x1.p+0),
                         static_cast<float>(static_cast<double>(bin.i_a_cn) + -0x1.p+0), 0x0p+0F);
    float const vr5 =
        physics::ly_mass(static_cast<float>(bin.i_z_cn), static_cast<float>(bin.i_a_cn), 0x0p+0F);
    return {.sn_mac = sn_mac, .sp_mac = vr4 - vr5};
}

// GEF.bas:6614-6635: the excitation energies at scission. Every mode adds mode 0's
// E_diss_Scission (MILESTONE_7_PLAN.md §4 candidate (f)).
void scission_energies(BinTables& t) {
    // 6614-6619
    t.escis0 = t.e_exc_s0 + t.e_diss_scission;
    t.escis1 = t.e_exc_s1 + t.e_diss_scission;
    t.escis2 = t.e_exc_s2 + t.e_diss_scission;
    t.escis3 = t.e_exc_s3 + t.e_diss_scission;
    t.escis4 = t.e_exc_s4 + t.e_diss_scission;
    t.escis5 = t.e_exc_s5 + t.e_diss_scission;
    // 6626-6629: the N/Z dependence is switched off (DS = 0); the LyMass terms BASIC computes
    // for it change no state and are left out
    float const ds = 0x0p+0F;
    // 6630-6634
    t.escis1 = t.escis1 + ds;
    t.escis2 = t.escis2 + ds;
    t.escis3 = t.escis3 + ds;
    t.escis4 = t.escis4 + ds;
    t.escis5 = t.escis5 + ds;
}

// GEF.bas:6645-6706: suppression of the modes at low excitation energy (`B_supp`, cleared by
// Options(NOSUPP)). Without suppression R_slope_S2 keeps the value of the previous bin.
void mode_suppression(BinInput const& bin, std::uint8_t b_supp, BinTables& t) {
    // 6645-6646
    t.desupp = 0x1.8p+1F;
    if (bin.i_z_cn > 92) {
        double const vr7 = std::pow(static_cast<double>(bin.i_z_cn + -92), 0x1.p+1);
        t.desupp = static_cast<float>(static_cast<double>(t.desupp) - (vr7 * 0x1.3333333333333p-2));
    }
    // 6648-6651
    t.r_supp_s0 = 0x1.p+0F;
    t.r_supp_s1 = 0x1.p+0F;
    t.r_supp_s2 = 0x1.p+0F;
    t.r_supp_s3 = 0x1.p+0F;
    // 6653
    if (b_supp != 1) {
        return;
    }
    // 6655-6656
    SeparationEnergies const s = separation_energies(bin);
    // 6663-6666
    if ((bin.i_z_cn + -50) > 36) {
        t.r_supp_s0 = static_cast<float>(
            0x1.p+0 /
            (std::exp((((static_cast<double>(t.de_ab) * 0x1.p+0) - static_cast<double>(t.escis0)) -
                       static_cast<double>(t.e_tunn)) +
                      static_cast<double>(t.desupp)) +
             0x1.p+0));
    }
    // 6668
    t.r_supp_s1 = static_cast<float>(
        0x1.p+0 /
        (static_cast<double>(std::exp(((t.de_ab - t.escis1) - t.e_tunn_s1) + t.desupp)) + 0x1.p+0));
    // 6677
    t.r_supp_s3 = static_cast<float>(
        0x1.p+0 /
        (static_cast<double>(std::exp(((t.de_ab - t.escis3) - t.e_tunn_s3) + t.desupp)) + 0x1.p+0));
    // 6679
    t.r_slope_s2 = std::exp(((t.de_ab - t.escis0) - t.e_tunn) + t.desupp);
    // 6684
    t.r_slope_s2 = static_cast<float>(
        static_cast<double>(t.r_slope_s2) *
        std::exp(static_cast<double>(s.sn_mac - s.sp_mac) * 0x1.4CCCCCCCCCCCDp+1));
    // 6696
    double const vr12 = std::pow(static_cast<double>(t.r_slope_s2), 0x1.8p+0);
    float const vr13 =
        fb::min(0x1.p+0F, static_cast<float>(std::exp(vr12 * -0x1.ECCCCCCCCCCCDp+2)));
    t.r_supp_s3 = t.r_supp_s3 * vr13;
}

// EMpot(k, I) of 6747-6769, k = 1 .. 5: the mode's distance from mode 0 plus the lower of the
// two shell valleys (light and heavy fragment).
float mode_potential(BinInput const& bin, BinTables const& t, std::int64_t i, float zc_mode,
                     float r_shell_eff, float p_z_curv) {
    double const vr_mode = std::pow(static_cast<double>(zc_mode - t.zc_mode_0), 0x1.p+1);
    double const vr_partner =
        std::pow(static_cast<double>(static_cast<float>(bin.i_z_cn - i) - zc_mode), 0x1.p+1);
    double const vr_i = std::pow(static_cast<double>(static_cast<float>(i) - zc_mode), 0x1.p+1);
    float const valley =
        fb::min(static_cast<float>(static_cast<double>(r_shell_eff) +
                                   (static_cast<double>(p_z_curv + t.r_z_curv1_s0) * vr_i)),
                static_cast<float>(static_cast<double>(r_shell_eff) +
                                   (static_cast<double>(p_z_curv + t.r_z_curv1_s0) * vr_partner)));
    return static_cast<float>((static_cast<double>(t.r_z_curv1_s0) * vr_mode) +
                              static_cast<double>(valley));
}

// EMpot(6, I), EMpot(7, I) of 6772-6779 (modes 1 and 2): both shell valleys are added, where
// modes 1-5 take the lower one (MILESTONE_7_PLAN.md §4 candidate (b)).
float double_shell_potential(BinInput const& bin, BinTables const& t, std::int64_t i, float zc_mode,
                             float r_shell_eff, float p_z_curv) {
    double const vr_mode = std::pow(static_cast<double>(zc_mode - t.zc_mode_0), 0x1.p+1);
    double const vr_i = std::pow(static_cast<double>(static_cast<float>(i) - zc_mode), 0x1.p+1);
    double const vr_partner =
        std::pow(static_cast<double>(static_cast<float>(bin.i_z_cn - i) - zc_mode), 0x1.p+1);
    return static_cast<float>(
        ((((static_cast<double>(t.r_z_curv1_s0) * vr_mode) + static_cast<double>(r_shell_eff)) +
          (static_cast<double>(p_z_curv + t.r_z_curv1_s0) * vr_i)) +
         static_cast<double>(r_shell_eff)) +
        (static_cast<double>(p_z_curv + t.r_z_curv1_s0) * vr_partner));
}

// GEF.bas:6736-6783: potential energies of the modes as a function of Z, written only in bin
// (1, 0, 0, 0) (MILESTONE_7_PLAN.md §4 candidate (e)).
void potential_energies(BinInput const& bin, WorkingParameters const& w, BinTables& t) {
    // 6738-6741
    if (bin.i_e_distr != 1 || bin.i_n_multi != 0 || bin.i_z_multi != 0 || bin.i_e_multi != 0) {
        return;
    }
    // 6742-6744
    std::int64_t const i_first = 20;
    std::int64_t const i_last = bin.i_z_cn + -20;
    for (std::int64_t i = i_first; i <= i_last; ++i) {
        // 6745
        double const vr1 =
            std::pow(static_cast<double>(static_cast<float>(i) - t.zc_mode_0), 0x1.p+1);
        t.empot(0, i) = static_cast<float>(static_cast<double>(t.r_z_curv1_s0) * vr1);
        // 6747-6769
        t.empot(1, i) = mode_potential(bin, t, i, t.zc_mode_1, t.r_shell_s1_eff, w.p_z_curv_s1);
        t.empot(2, i) = mode_potential(bin, t, i, t.zc_mode_2, t.r_shell_s2_eff, w.p_z_curv_s2);
        t.empot(3, i) = mode_potential(bin, t, i, t.zc_mode_3, t.r_shell_s3_eff, w.p_z_curv_s3);
        t.empot(4, i) = mode_potential(bin, t, i, t.zc_mode_4, t.r_shell_s4_eff, w.p_z_curv_s4);
        t.empot(5, i) = mode_potential(bin, t, i, t.zc_mode_5, t.r_shell_s5_eff, w.p_z_curv_s5);
        // 6772-6779
        t.empot(6, i) =
            double_shell_potential(bin, t, i, t.zc_mode_1, t.r_shell_s1_eff, w.p_z_curv_s1);
        t.empot(7, i) =
            double_shell_potential(bin, t, i, t.zc_mode_2, t.r_shell_s2_eff, w.p_z_curv_s2);
    }
}

// GEF.bas:6789-6795: the charge polarisation of modes 1-5 fades towards mode 0's as the shells
// wash out. I passes 350 from A_CN 361 on; the accesses go where BASIC's go (QUIRK(Q-061)).
void polarisation_energy_dependence(BinInput const& bin, BinTables& t) {
    for (std::int64_t i = 10; i <= bin.i_a_cn + -10; ++i) {
        for (std::int64_t j = 1; j <= 5; ++j) {
            for (std::int64_t k = 1; k <= 2; ++k) {
                // 6792
                float const shift_0 = fragment_element(t, FragmentTable::Zshift, 0, k, i);
                float const shift_j = fragment_element(t, FragmentTable::Zshift, j, k, i);
                fragment_element(t, FragmentTable::Zshift, j, k, i) =
                    shift_0 + ((shift_j - shift_0) * t.r_att(j));
            }
        }
    }
}

// GEF.bas:6824-6870: Z-A relations of the modes, 2nd iteration (heavy fragment for modes 0-4,
// light fragment for mode 5).
void mass_centres(BinInput const& bin, BinTables& t) {
    z_a_relation(bin, t, t.zc_mode_0, 0, 2, t.ac_mode_0, t.nc_mode_0); // 6824-6830
    z_a_relation(bin, t, t.zc_mode_1, 1, 2, t.ac_mode_1, t.nc_mode_1); // 6832-6838
    z_a_relation(bin, t, t.zc_mode_2, 2, 2, t.ac_mode_2, t.nc_mode_2); // 6840-6846
    z_a_relation(bin, t, t.zc_mode_3, 3, 2, t.ac_mode_3, t.nc_mode_3); // 6848-6854
    z_a_relation(bin, t, t.zc_mode_4, 4, 2, t.ac_mode_4, t.nc_mode_4); // 6856-6862
    z_a_relation(bin, t, t.zc_mode_5, 5, 1, t.ac_mode_5, t.nc_mode_5); // 6864-6870
}

// Getyield of mode `imode` = 1 .. 5 (6879-6905): shell plus deformation energy; the TEgidy of
// the last argument is evaluated first, as in the C.
float mode_yield(BinInput const& bin, params::Parameters const& p, float e_exc, float e_exc_s0,
                 float r_shell_eff, float de_defo, float t_low, std::int64_t imode) {
    auto const a_cn = static_cast<float>(bin.i_a_cn);
    float const t_mac = physics::tegidy(a_cn, 0x0p+0F, p.tscale);
    float const t_shell = physics::tegidy(a_cn, r_shell_eff + de_defo, p.tscale);
    return physics::getyield(e_exc, e_exc_s0, r_shell_eff + de_defo, de_defo, t_low, t_shell, t_mac,
                             imode);
}

// Getyield of the overlap modes 11 and 22 (6907-6920), with twice the deformation energy.
float overlap_yield(BinInput const& bin, params::Parameters const& p, float e_exc, float e_exc_s0,
                    float r_shell_eff, float de_defo, float t_low, std::int64_t imode) {
    auto const a_cn = static_cast<float>(bin.i_a_cn);
    float const t_mac = physics::tegidy(a_cn, 0x0p+0F, p.tscale);
    float const t_shell =
        physics::tegidy(a_cn,
                        static_cast<float>(static_cast<double>(r_shell_eff) +
                                           (static_cast<double>(de_defo) * 0x1.p+1)),
                        p.tscale);
    return physics::getyield(e_exc, e_exc_s0, r_shell_eff + (de_defo * 0x1.p+1F),
                             de_defo * 0x1.p+1F, t_low, t_shell, t_mac, imode);
}

// GEF.bas:6875-6925: the yields of the modes before normalisation.
void mode_yields(BinInput const& bin, WorkingParameters const& w, params::Parameters const& p,
                 BinTables& t) {
    auto const a_cn = static_cast<float>(bin.i_a_cn);
    // 6875-6877
    float const vr28 = physics::tegidy(a_cn, 0x0p+0F, p.tscale);
    float const vr29 = physics::tegidy(a_cn, 0x0p+0F, p.tscale);
    t.yield_mode_0 =
        physics::getyield(t.e_exc_s0, t.e_exc_s0, 0x0p+0F, 0x0p+0F, w.t_low_sl, vr29, vr28, 0);
    t.yield_mode_0 = t.yield_mode_0 * t.r_supp_s0;
    // 6879-6883
    t.yield_mode_1 = mode_yield(bin, p, t.e_exc_s1, t.e_exc_s0, t.r_shell_s1_eff, w.de_defo_s1,
                                t.t_low_s1_used, 1);
    t.yield_mode_1 = t.yield_mode_1 * t.r_supp_s1;
    // 6885-6889
    t.yield_mode_2 =
        mode_yield(bin, p, t.e_exc_s2, t.e_exc_s0, t.r_shell_s2_eff, w.de_defo_s2, w.t_low_s2, 2);
    t.yield_mode_2 = t.yield_mode_2 * t.r_supp_s2;
    // 6891-6895
    t.yield_mode_3 =
        mode_yield(bin, p, t.e_exc_s3, t.e_exc_s0, t.r_shell_s3_eff, w.de_defo_s3, w.t_low_s3, 3);
    t.yield_mode_3 = t.yield_mode_3 * t.r_supp_s3;
    // 6897-6905
    t.yield_mode_4 =
        mode_yield(bin, p, t.e_exc_s4, t.e_exc_s0, t.r_shell_s4_eff, w.de_defo_s4, w.t_low_s4, 4);
    t.yield_mode_5 =
        mode_yield(bin, p, t.e_exc_s5, t.e_exc_s0, t.r_shell_s5_eff, w.de_defo_s5, w.t_low_s5, 5);
    // 6907-6915
    t.yield_mode_11 = overlap_yield(bin, p, t.e_exc_s11, t.e_exc_s0, t.r_shell_s1_eff, w.de_defo_s1,
                                    p.t_low_s11, 11);
    if (!(t.yield_mode_11 <= t.yield_mode_1)) {
        t.yield_mode_1 = 0x0p+0F;
    } else {
        t.yield_mode_11 = 0x0p+0F;
    }
    // 6917-6925
    t.yield_mode_22 = overlap_yield(bin, p, t.e_exc_s22, t.e_exc_s0, t.r_shell_s2_eff, w.de_defo_s2,
                                    p.t_low_s22, 22);
    if (!(t.yield_mode_22 <= t.yield_mode_2)) {
        t.yield_mode_2 = 0x0p+0F;
    } else {
        t.yield_mode_22 = 0x0p+0F;
    }
}

// Yield / Yield_Norm of 6982-6989, without a guard against Yield_Norm = 0
// (MILESTONE_7_PLAN.md §4 candidate (c)).
float normalised(float yield, float yield_norm) {
    return static_cast<float>(static_cast<double>(yield) / static_cast<double>(yield_norm));
}

// GEF.bas:6980-7018: normalisation of the yields and the share of the mode MODE(i) selects.
void normalise_and_select(std::int64_t i_mode_selected, BinTables& t, fb::PrintFile& console) {
    // 6980-6989
    t.yield_norm = ((((((t.yield_mode_0 + t.yield_mode_1) + t.yield_mode_2) + t.yield_mode_3) +
                      t.yield_mode_4) +
                     t.yield_mode_5) +
                    t.yield_mode_11) +
                   t.yield_mode_22;
    t.yield_mode_0 = normalised(t.yield_mode_0, t.yield_norm);
    t.yield_mode_1 = normalised(t.yield_mode_1, t.yield_norm);
    t.yield_mode_2 = normalised(t.yield_mode_2, t.yield_norm);
    t.yield_mode_3 = normalised(t.yield_mode_3, t.yield_norm);
    t.yield_mode_4 = normalised(t.yield_mode_4, t.yield_norm);
    t.yield_mode_5 = normalised(t.yield_mode_5, t.yield_norm);
    t.yield_mode_11 = normalised(t.yield_mode_11, t.yield_norm);
    t.yield_mode_22 = normalised(t.yield_mode_22, t.yield_norm);
    // 6991-7012: any other I_Mode_selected keeps 1.0
    t.p_selected = 0x1.p+0F;
    switch (i_mode_selected) {
    case 0:
        t.p_selected = t.yield_mode_0;
        break;
    case 1:
        t.p_selected = t.yield_mode_1;
        break;
    case 2:
        t.p_selected = t.yield_mode_2;
        break;
    case 3:
        t.p_selected = t.yield_mode_3;
        break;
    case 4:
        t.p_selected = t.yield_mode_4;
        break;
    case 5:
        t.p_selected = t.yield_mode_5;
        break;
    case 6:
        t.p_selected = t.yield_mode_11;
        break;
    case 7:
        t.p_selected = t.yield_mode_22;
        break;
    case -1:
        t.p_selected = 0x1.p+0F;
        break;
    default:
        break;
    }
    // 7015-7018
    if (!(t.p_selected != 0x0p+0F)) {
        console.print("<I> Yield of the selected fission mode too low.", fb::PrintEnd::Newline);
        console.print("    No calculation performed.", fb::PrintEnd::Newline);
    }
}

// SigZ * Csng(I_A_CN) / Csng(I_Z_CN), the mass width of 7022-7035.
float mass_width(BinInput const& bin, float sigz) {
    return static_cast<float>(static_cast<double>(sigz * static_cast<float>(bin.i_a_cn)) /
                              static_cast<double>(static_cast<float>(bin.i_z_cn)));
}

// GEF.bas:7022-7036: mass widths of the modes, none broader than mode 0's.
void mass_widths(BinInput const& bin, BinTables& t) {
    t.siga_mode_0 = mass_width(bin, t.sigz_mode_0); // 7022
    t.siga_mode_1 = mass_width(bin, t.sigz_mode_1); // 7023-7024
    t.siga_mode_1 = fb::min(t.siga_mode_1, t.siga_mode_0);
    t.siga_mode_2 = mass_width(bin, t.sigz_mode_2); // 7025-7026
    t.siga_mode_2 = fb::min(t.siga_mode_2, t.siga_mode_0);
    t.siga_mode_3 = mass_width(bin, t.sigz_mode_3); // 7027-7028
    t.siga_mode_3 = fb::min(t.siga_mode_3, t.siga_mode_0);
    t.siga_mode_4 = mass_width(bin, t.sigz_mode_4); // 7029-7030
    t.siga_mode_4 = fb::min(t.siga_mode_4, t.siga_mode_0);
    t.siga_mode_5 = mass_width(bin, t.sigz_mode_5); // 7031-7032
    t.siga_mode_5 = fb::min(t.siga_mode_5, t.siga_mode_0);
    // 7033-7034: the C's constant is the Double nearest to sqrt(2)
    t.siga_mode_11 = static_cast<float>(((static_cast<double>(t.sigz_mode_1) *
                                          static_cast<double>(static_cast<float>(bin.i_a_cn))) *
                                         std::numbers::sqrt2) /
                                        static_cast<double>(static_cast<float>(bin.i_z_cn)));
    t.siga_mode_11 = fb::min(t.siga_mode_11, t.siga_mode_0);
    t.siga_mode_22 = mass_width(bin, t.sigz_mode_2); // 7035-7036
    t.siga_mode_22 = fb::min(t.siga_mode_22, t.siga_mode_0);
}

} // namespace

void shifts_polarisation_and_yields(BinInput const& bin, std::uint8_t b_supp,
                                    std::int64_t i_mode_selected, WorkingParameters const& w,
                                    params::Parameters const& p, BinTables& t,
                                    fb::PrintFile& console) {
    energy_dependent_shifts(w, p, t);                  // 6561-6609
    scission_energies(t);                              // 6614-6635
    mode_suppression(bin, b_supp, t);                  // 6645-6706
    potential_energies(bin, w, t);                     // 6736-6783
    polarisation_energy_dependence(bin, t);            // 6789-6795
    mass_centres(bin, t);                              // 6824-6870
    mode_yields(bin, w, p, t);                         // 6875-6925
    normalise_and_select(i_mode_selected, t, console); // 6980-7018
    mass_widths(bin, t);                               // 7022-7036
}

void spectra_normalisation(std::int64_t nevttot, BinTables& t) {
    // 7920
    t.racc = static_cast<float>((0x1.9p+6 / static_cast<double>(nevttot)) *
                                static_cast<double>(t.p_selected));
}

} // namespace gef::tables
