// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF.bas:6063-6558, transcribed from the C fbc 1.10.1 emits for it. Comparisons keep the C's
// form (`goto` on the negated condition), so that a NaN takes the branch it takes in BASIC.

#include "physics/barriers.hpp"

#include "data/tables.hpp"
#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "physics/helpers.hpp"
#include "physics/level_density.hpp"
#include "physics/masses.hpp"
#include "physics/shape.hpp"
#include "tables/builder.hpp"

#include <cmath>
#include <cstdint>
#include <stdexcept>

namespace gef::tables {

namespace {

// BFTF/BFTFA/BFTFB's value. The switches this block passes (0, 1) are always defined cases of
// their `Select Case`, so `print_undefined_option` never triggers; `run::barrier_value` does the
// same check, but gef_tables cannot depend on gef_run.
float barrier_value(physics::BftfResult const& result) {
    if (result.print_undefined_option) {
        throw std::logic_error("BFTF: the table builder passed an undefined switch");
    }
    return result.value;
}

// GEF.bas:6063-6075: energy transformation (`R_E_exc_Eb`, `R_E_exc_GS`) and fission barriers.
void energy_and_barriers(BinInput const& bin, data::TableSet const& tables, BinTables& t) {
    auto const z_cn = static_cast<float>(bin.i_z_cn);
    auto const a_cn = static_cast<float>(bin.i_a_cn);
    // 6064
    float const vr1 = barrier_value(physics::bftfb(tables, z_cn, a_cn, 1));
    t.r_e_exc_eb = bin.r_e_exc_used - vr1;
    // 6065
    t.r_e_exc_gs = bin.r_e_exc_used;
    // 6070-6075
    t.b_f = barrier_value(physics::bftf(tables, z_cn, a_cn, 1));
    t.b_f_ld = barrier_value(physics::bftf(tables, z_cn, a_cn, 0));
    t.e_b = barrier_value(physics::bftfb(tables, z_cn, a_cn, 1));
    t.e_b_ld = barrier_value(physics::bftfb(tables, z_cn, a_cn, 0));
    t.e_a = barrier_value(physics::bftfa(tables, z_cn, a_cn, 1));
    t.de_ab = t.e_b - t.e_a;
}

// Lymass(Z, A, beta) - Lymass(Z, A, 0): the deformation energy of 6149 (as deformations.cpp's
// `deformation_energy`, duplicated because the two files do not share a helper header).
float deformation_energy(float z, float a, float beta) {
    float const deformed = physics::ly_mass(z, a, beta);
    float const spherical = physics::ly_mass(z, a, 0x0p+0F);
    return deformed - spherical;
}

// E_ld, DZ_asym, B and E_exc_prov of one barrier mode (GEF.bas:6191-6213, modes 1-4: the shape
// differs for mode 5, which uses R_A_Curv2_S0 and an extra R_Shell_S5_eff correction, and for
// mode 0, which has no E_ld/B/E_exc_prov of its own).
void mode_barrier(BinInput const& bin, float r_a_curv1_s0, float zc_mode, float zc_mode_0,
                  float shell_eff, float e_exc_s0_prov, float& e_ld, float& dz_asym, float& b,
                  float& e_exc_prov) {
    auto const ratio = static_cast<float>(static_cast<double>(static_cast<float>(bin.i_a_cn)) /
                                          static_cast<double>(static_cast<float>(bin.i_z_cn)));
    float const diff = zc_mode - zc_mode_0;
    double const vr = std::pow(static_cast<double>(ratio * diff), 0x1.p+1);
    e_ld = static_cast<float>(static_cast<double>(r_a_curv1_s0) * vr);
    dz_asym = std::fabs(diff);
    if (!(dz_asym <= 0x1.8p+3F)) {
        e_ld = static_cast<float>(
            (static_cast<double>(e_ld) + (static_cast<double>(dz_asym) * 0x1.p+0)) + -0x1.9p+3);
    }
    b = e_ld + shell_eff;
    e_exc_prov = e_exc_s0_prov - b;
}

// GEF.bas:6077-6305: barriers and excitation energies of the fission modes. `p_a_cn` is
// BinPlanInput::p_a_cn (6158 reads it directly, not the bin's `I_A_CN`).
void mode_shell_effects_and_barriers(BinInput const& bin, std::int64_t p_a_cn,
                                     WorkingParameters const& w, params::Parameters const& p,
                                     BinTables& t, Temporaries& tmp) {
    // 6079
    t.e_exc_s0_prov = t.r_e_exc_eb;
    // 6082: additional influence of N = 82 assumed
    t.delta_nz_pol = static_cast<float>(-static_cast<double>(static_cast<float>(
                                            static_cast<double>(static_cast<float>(t.i_n_cn)) /
                                            static_cast<double>(static_cast<float>(bin.i_z_cn)))) +
                                        0x1.A3D70A3D70A3Dp+0);
    // 6083
    float const att = w.p_att_rel * w.p_att_pol;
    t.r_shell_s1_eff =
        static_cast<float>(static_cast<double>(w.p_shell_s1) *
                           (-static_cast<double>(att * std::fabs(t.delta_nz_pol)) + 0x1.p+0));
    // 6084: adjusted to U238F
    if (!(static_cast<double>(t.r_shell_s1_eff) >= -0x1.07AE147AE147Bp+1)) {
        t.r_shell_s1_eff = -0x1.07AE14p+1F;
    }
    // 6086: contribution of Z = 50
    t.r_shell_s1_eff =
        fb::min(t.r_shell_s1_eff, static_cast<float>(static_cast<double>(w.p_shell_s1) * 0x1.p-1));

    // 6116: the Z = 44 shell enhancing S1 near Pu
    double const vr8 = std::pow(((static_cast<double>(static_cast<float>(bin.i_z_cn)) -
                                  static_cast<double>(p.zc_mode_sl5)) +
                                 static_cast<double>(w.p_dz_mean_sl5)) +
                                    -0x1.9p+5,
                                0x1.p+1);
    t.s1_enhance = static_cast<float>(static_cast<double>(w.p_shell_sl5) +
                                      (vr8 * static_cast<double>(w.p_z_curv_sl5)));
    // 6126
    if (!(t.s1_enhance <= 0x0p+0F)) {
        t.s1_enhance = 0x0p+0F;
    }
    // 6137: special treatment for nuclei with low E* at scission
    t.r_shell_s1_eff = t.r_shell_s1_eff + t.s1_enhance;

    // 6142-6151: the Z = 44 shell reduces the deformation of the light fragment
    std::int64_t const last = fb::sub(bin.i_z_cn, std::int64_t{10});
    for (std::int64_t i = 10; i <= last; ++i) {
        tmp.z1 = static_cast<float>(i);
        tmp.a1 = static_cast<float>(((static_cast<double>(tmp.z1) + -0x1.p-1) /
                                     static_cast<double>(static_cast<float>(bin.i_z_cn))) *
                                    static_cast<double>(static_cast<float>(bin.i_a_cn)));
        float const exp_enh = std::exp(t.s1_enhance);
        float& beta = t.beta(1, 1, i);
        beta = static_cast<float>(
            static_cast<double>(exp_enh * beta) +
            ((-static_cast<double>(exp_enh) + 0x1.p+0) * (static_cast<double>(beta) + -0x1.p-2)));
        beta = fb::max(beta, 0x0p+0F);
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, beta);
        t.edefo(1, 1, i) = tmp.e_defo;
    }

    // 6155-6164: influence of the S2 shell in the complementary fragment ("S12 fission channel")
    t.t_asym_mode_2 = 0x1.p-1F;
    t.sigz_mode_2 = static_cast<float>(std::sqrt((static_cast<double>(t.t_asym_mode_2) * 0x1.p-1) /
                                                 static_cast<double>(w.p_z_curv_s2)));
    t.siga_mode_2 =
        static_cast<float>(static_cast<double>(t.sigz_mode_2 * static_cast<float>(bin.i_a_cn)) /
                           static_cast<double>(static_cast<float>(bin.i_z_cn)));
    float const vr12 = physics::u_box((static_cast<float>(p_a_cn) - t.ac_mode_2) - t.ac_mode_1,
                                      t.siga_mode_2, w.p_a_width_s2);
    t.s1_enhance_s2 = (w.p_shell_s2 * vr12) * w.p_a_width_s2;
    if (!(static_cast<double>(t.s1_enhance_s2) >= 0x1.47AE147AE147Bp-7)) {
        t.r_shell_s1_eff = t.r_shell_s1_eff + t.s1_enhance_s2;
    }

    // 6166-6188: shell effects of modes 2-5
    t.r_shell_s2_eff = w.p_shell_s2;
    t.r_shell_s3_eff = w.p_shell_s3;
    // 6177: R_Shell_S3_eff not above 0 (the S3 overlap formula of 6169-6176 is commented out)
    t.r_shell_s3_eff = fb::min(t.r_shell_s3_eff, 0x0p+0F);
    t.r_shell_s4_eff = w.p_shell_s4; // Z around 82
    double const vr14 = std::pow(static_cast<double>(t.zc_mode_5 - t.zc_mode_0), 0x1.p+1);
    t.r_shell_s5_eff = static_cast<float>(
        (static_cast<double>(w.p_shell_s5) + (static_cast<double>(w.p_z_curv_s5) * vr14)) *
        0x1.p+1);
    // 6188: no overlap at large distance
    if (!(t.r_shell_s5_eff <= w.p_shell_s5)) {
        t.r_shell_s5_eff = w.p_shell_s5;
    }

    // 6191-6213: barriers and provisional excitation energies of modes 1-4
    mode_barrier(bin, t.r_a_curv1_s0, t.zc_mode_1, t.zc_mode_0, t.r_shell_s1_eff, t.e_exc_s0_prov,
                 t.e_ld_s1, t.dz_asym, t.b_s1, t.e_exc_s1_prov);
    mode_barrier(bin, t.r_a_curv1_s0, t.zc_mode_2, t.zc_mode_0, t.r_shell_s2_eff, t.e_exc_s0_prov,
                 t.e_ld_s2, t.dz_asym, t.b_s2, t.e_exc_s2_prov);
    mode_barrier(bin, t.r_a_curv1_s0, t.zc_mode_3, t.zc_mode_0, t.r_shell_s3_eff, t.e_exc_s0_prov,
                 t.e_ld_s3, t.dz_asym, t.b_s3, t.e_exc_s3_prov);
    mode_barrier(bin, t.r_a_curv1_s0, t.zc_mode_4, t.zc_mode_0, t.r_shell_s4_eff, t.e_exc_s0_prov,
                 t.e_ld_s4, t.dz_asym, t.b_s4, t.e_exc_s4_prov);

    // 6215-6223: only here (A_CN < 220) is S5 close enough to symmetry to have a chance
    if (bin.i_a_cn < 220) {
        auto const ratio = static_cast<float>(static_cast<double>(static_cast<float>(bin.i_a_cn)) /
                                              static_cast<double>(static_cast<float>(bin.i_z_cn)));
        double const vr19 =
            std::pow(static_cast<double>(ratio * (t.zc_mode_5 - t.zc_mode_0)), 0x1.p+1);
        t.e_ld_s5 = static_cast<float>(static_cast<double>(t.r_a_curv2_s0) * vr19);
        // 6217: variation with N (the C computes I_A_CN - I_Z_CN, not I_N_CN)
        t.r_shell_s5_eff = static_cast<float>(
            static_cast<double>(t.r_shell_s5_eff) *
            (static_cast<double>(
                 p.p_s5_mod * (static_cast<float>(fb::sub(bin.i_a_cn, bin.i_z_cn)) + -0x1.Cp+6F)) +
             0x1.p+0));
        t.b_s5 = t.e_ld_s5 + t.r_shell_s5_eff;
        t.e_exc_s5_prov = t.e_exc_s0_prov - t.b_s5;
    } else {
        t.b_s5 = 0x1.3878p+13F; // 9999
        t.e_exc_s5_prov = -0x1.3878p+13F;
    }

    // 6225-6249: mode 11 (overlap of channel 1 in light and heavy fragment)
    double const vr20 = std::pow(static_cast<double>(t.zc_mode_1 - t.zc_mode_0), 0x1.p+1);
    t.b_s11 = static_cast<float>(
        (static_cast<double>(t.r_shell_s1_eff) + (static_cast<double>(w.p_z_curv_s1) * vr20)) *
        0x1.p+1);
    t.des11zpm = 0x0p+0F;
    // 6234: the S1 shells in the two fragments must be rather close to form one pocket
    if (!(t.b_s11 >= (t.r_shell_s1_eff + p.level_s11))) {
        // 6236: fits the mass distribution of 258Fm(sf)
        t.des11zpm = static_cast<float>(static_cast<double>(std::fabs(t.zc_mode_1 - t.zc_mode_0)) *
                                        -0x1.7333333333333p+0);
    }
    t.b_s11 = t.b_s11 + t.des11zpm;
    t.e_exc_s11_prov = t.e_exc_s0_prov - t.b_s11;

    // 6252-6268: mode 22 (overlap of channel 2 in light and heavy fragment)
    double const vr21 = std::pow(static_cast<double>(t.zc_mode_2 - t.zc_mode_0), 0x1.p+1);
    t.b_s22 = static_cast<float>((static_cast<double>(t.r_shell_s2_eff) +
                                  ((static_cast<double>(w.p_z_curv_s2) * vr21) * 0x1.p+1)) *
                                 0x1.p+1);
    t.e_exc_s22_prov = t.e_exc_s0_prov - t.b_s22;

    // 6270-6276
    t.e_min_barr = fb::min(0x0p+0F, t.b_s1);
    t.e_min_barr = fb::min(t.e_min_barr, t.b_s2);
    t.e_min_barr = fb::min(t.e_min_barr, t.b_s3);
    t.e_min_barr = fb::min(t.e_min_barr, t.b_s4);
    t.e_min_barr = fb::min(t.e_min_barr, t.b_s5);
    t.e_min_barr = fb::min(t.e_min_barr, t.b_s11);
    t.e_min_barr = fb::min(t.e_min_barr, t.b_s22);

    // 6279-6287: energy minus the height of the respective fission saddle
    t.e_exc_s0 = (t.e_exc_s0_prov + t.e_min_barr) - w.delta_s0;
    t.e_exc_s1 = t.e_exc_s1_prov + t.e_min_barr;
    t.e_exc_s2 = t.e_exc_s2_prov + t.e_min_barr;
    t.e_exc_s3 = t.e_exc_s3_prov + t.e_min_barr;
    t.e_exc_s4 = t.e_exc_s4_prov + t.e_min_barr;
    t.e_exc_s5 = t.e_exc_s5_prov + t.e_min_barr;
    t.e_exc_s11 = t.e_exc_s11_prov + t.e_min_barr;
    t.e_exc_s22 = t.e_exc_s22_prov + t.e_min_barr;

    // 6298-6305: energy above the lowest fission saddle
    t.e_exc_barr = fb::max(t.e_exc_s0, t.e_exc_s1);
    t.e_exc_barr = fb::max(t.e_exc_barr, t.e_exc_s2);
    t.e_exc_barr = fb::max(t.e_exc_barr, t.e_exc_s3);
    t.e_exc_barr = fb::max(t.e_exc_barr, t.e_exc_s4);
    t.e_exc_barr = fb::max(t.e_exc_barr, t.e_exc_s5);
    t.e_exc_barr = fb::max(t.e_exc_barr, t.e_exc_s11);
    t.e_exc_barr = fb::max(t.e_exc_barr, t.e_exc_s22);
}

// E_tunn{,_S1..S4} = -E_exc if E_exc < 0 else 0, as fbc compiles it (`if (E >= 0) goto
// zero-branch`): a NaN E_exc takes the "-E_exc" branch (GEF.bas:6311-6315).
float tunnelling(float e_exc) {
    if (!(e_exc >= 0x0p+0F)) {
        return -e_exc;
    }
    return 0x0p+0F;
}

// T_Coll_Mode_i = Max(TFCOLL * Max(E_exc, 0) + TCOLLFRAC * (De_Saddle_Scission(Z, A,
// ESHIFTSASCI_coll) - E_tunn), 0) (GEF.bas:6381-6384, 6389-6392, 6433-6436, 6441-6444: modes 1,
// 2, 4, 5; mode 3's formula differs and is not ported through this helper).
float mode_coll_temperature(BinInput const& bin, params::Parameters const& p, float e_exc,
                            float e_tunn) {
    float const vr_max = fb::max(e_exc, 0x0p+0F);
    float const vr_saddle = physics::de_saddle_scission(
        static_cast<float>(bin.i_z_cn), static_cast<float>(bin.i_a_cn), p.eshiftsasci_coll);
    float const t_coll = (p.tfcoll * vr_max) + (p.tcollfrac * (vr_saddle - e_tunn));
    return fb::max(t_coll, 0x0p+0F);
}

// GEF.bas:6307-6447: collective temperature used for calculating the widths in mass asymmetry
// and charge polarization.
void collective_temperatures(BinInput const& bin, params::Parameters const& p,
                             WorkingParameters const& w, data::TableSet const& tables,
                             BinTables& t) {
    t.e_tunn = tunnelling(t.e_exc_s0);
    t.e_tunn_s1 = tunnelling(t.e_exc_s1);
    t.e_tunn_s2 = tunnelling(t.e_exc_s2);
    t.e_tunn_s3 = tunnelling(t.e_exc_s3);
    t.e_tunn_s4 = tunnelling(t.e_exc_s4);
    t.r_e_exc_eff = fb::max(0x1.99999Ap-4F, t.e_exc_s0); // 0.1

    // 6317-6320: empirical, replaced by TRusanov
    float const vr37 = physics::de_saddle_scission(
        static_cast<float>(bin.i_z_cn), static_cast<float>(bin.i_a_cn), p.eshiftsasci_coll);
    t.t_coll_mode_0 = p.tcollfrac * (vr37 - t.e_tunn);
    t.t_coll_mode_0 = fb::max(t.t_coll_mode_0, 0x0p+0F);

    // 6326-6327 `Dim As Single T_Rusanov` (bin-local, zeroed in every bin): empirical description
    // from Ye. N. Gruzintsev et al., Z. Phys. A 323 (1986) 307
    t.t_rusanov = 0x0p+0F;
    t.t_rusanov = physics::trusanov(t.r_e_exc_eff, static_cast<float>(bin.i_a_cn));
    // 6331: transition from const. temp. to Fermi gas occurs around 20 MeV by Max
    t.t_coll_mode_0 = fb::max(t.t_coll_mode_0, t.t_rusanov);

    // 6336: application of the statistical model, intrinsic temperature at saddle
    auto const half_z =
        static_cast<float>(static_cast<double>(static_cast<float>(bin.i_z_cn)) * 0x1.p-1);
    auto const half_a =
        static_cast<float>(static_cast<double>(static_cast<float>(bin.i_a_cn)) * 0x1.p-1);
    t.t_pol_mode_0 =
        physics::u_temp(tables, half_z, half_a, t.r_e_exc_eff, 0, 0, p.tscale, p.econd, p.etrans);
    double const vr42 = std::pow(static_cast<double>(p.tcollmin) * 0x1.p+0, 0x1.p+1);
    t.t_asym_mode_0 = static_cast<float>(
        std::sqrt(static_cast<double>(t.t_coll_mode_0 * t.t_coll_mode_0) + vr42));

    // 6342-6344
    float const vr43 = physics::de_saddle_scission(
        static_cast<float>(bin.i_z_cn), static_cast<float>(bin.i_a_cn), p.eshiftsasci_intr);
    t.e_pot_scission = (vr43 - t.e_tunn) + p.epot_shift;
    t.e_diss_scission = w.edissfrac * t.e_pot_scission;

    // 6376: variation of "thickness" of outer barrier (values between 238U and 252Cf)
    double const vr44 = std::pow(static_cast<double>(static_cast<float>(bin.i_z_cn)), 0x1.p+1);
    t.t_low_s1_used = static_cast<float>(
        (static_cast<double>(w.t_low_s1) +
         (-(vr44 / static_cast<double>(static_cast<float>(bin.i_a_cn))) * 0x1.C21C21C21C22Dp-6)) +
        0x1.0C088D55A2279p+0);

    // 6381-6387: mode 1
    t.t_coll_mode_1 = mode_coll_temperature(bin, p, t.e_exc_s1, t.e_tunn);
    t.t_pol_mode_1 = t.t_pol_mode_0;
    double const vr48 = std::pow(static_cast<double>(p.tcollmin) * 0x1.p+2, 0x1.p+1);
    t.t_asym_mode_1 = static_cast<float>(
        std::sqrt(static_cast<double>(t.t_coll_mode_1 * t.t_coll_mode_1) + vr48));

    // 6389-6396: mode 2
    t.t_coll_mode_2 = mode_coll_temperature(bin, p, t.e_exc_s2, t.e_tunn);
    t.t_pol_mode_2 = t.t_pol_mode_0;
    t.t_asym_mode_2 =
        static_cast<float>(std::sqrt(static_cast<double>(t.t_coll_mode_2 * t.t_coll_mode_2) +
                                     (static_cast<double>(p.tcollmin * p.tcollmin) * 0x1.p+2)));

    // 6414-6421: mode 3, fit to 239Pu(nth,f) and 252Cf(sf)
    float const vr52 = fb::max(t.e_exc_s3, 0x0p+0F);
    float const vr53 = physics::de_saddle_scission(
        static_cast<float>(bin.i_z_cn), static_cast<float>(bin.i_a_cn), p.eshiftsasci_coll);
    double const vr54 = std::pow(static_cast<double>(vr53), 0x1.p+1);
    t.t_coll_mode_3 = static_cast<float>(
        static_cast<double>(p.tfcoll * vr52) +
        ((static_cast<double>(p.tcollfrac) * vr54) * 0x1.EB851EB851EB8p-6)); // 0.03
    t.t_coll_mode_3 = fb::max(t.t_coll_mode_3, 0x0p+0F);
    t.t_pol_mode_3 = t.t_pol_mode_0;
    t.t_asym_mode_3 =
        static_cast<float>(std::sqrt(static_cast<double>(t.t_coll_mode_3 * t.t_coll_mode_3) +
                                     static_cast<double>(p.tcollmin * p.tcollmin)));

    // 6433-6439: mode 4
    t.t_coll_mode_4 = mode_coll_temperature(bin, p, t.e_exc_s4, t.e_tunn);
    t.t_pol_mode_4 = t.t_pol_mode_0;
    t.t_asym_mode_4 =
        static_cast<float>(std::sqrt(static_cast<double>(t.t_coll_mode_4 * t.t_coll_mode_4) +
                                     (static_cast<double>(p.tcollmin * p.tcollmin) * 0x1.p+2)));

    // 6441-6447: mode 5
    t.t_coll_mode_5 = mode_coll_temperature(bin, p, t.e_exc_s5, t.e_tunn);
    t.t_pol_mode_5 = t.t_pol_mode_0;
    t.t_asym_mode_5 =
        static_cast<float>(std::sqrt(static_cast<double>(t.t_coll_mode_5 * t.t_coll_mode_5) +
                                     (static_cast<double>(p.tcollmin * p.tcollmin) * 0x1.p+2)));
}

// GEF.bas:6449-6473: stiffness in polarization.
void polarisation_stiffness(BinInput const& bin, params::Parameters const& p, BinTables& t,
                            Temporaries& tmp) {
    // 6450-6451
    tmp.rz = static_cast<float>(static_cast<double>(static_cast<float>(bin.i_z_cn)) * 0x1.p-1);
    t.ra = static_cast<float>(static_cast<double>(static_cast<float>(bin.i_a_cn)) * 0x1.p-1);
    // 6452-6453
    tmp.beta1 = t.beta(0, 1, fb::f2l(tmp.rz));
    tmp.beta2 = t.beta(0, 2, fb::f2l(tmp.rz));
    // 6454: assumption: stiffness is dominated (and thus well represented) by the macroscopic
    // potential
    auto const rz_minus1 = static_cast<float>(static_cast<double>(tmp.rz) + -0x1.p+0);
    auto const rz_plus1 = static_cast<float>(static_cast<double>(tmp.rz) + 0x1.p+0);
    float const vr62 = physics::ly_mass(rz_minus1, t.ra, tmp.beta1);
    float const vr63 = physics::ly_mass(rz_plus1, t.ra, tmp.beta2);
    float const vr64 = physics::ly_mass(rz_plus1, t.ra, tmp.beta1);
    float const vr65 = physics::ly_mass(rz_minus1, t.ra, tmp.beta2);
    float const vr66 =
        physics::ecoul(rz_minus1, t.ra, tmp.beta1, rz_plus1, t.ra, tmp.beta2, p.dneck);
    float const vr67 =
        physics::ecoul(rz_plus1, t.ra, tmp.beta1, rz_minus1, t.ra, tmp.beta2, p.dneck);
    float const vr68 = physics::ecoul(tmp.rz, t.ra, tmp.beta1, tmp.rz, t.ra, tmp.beta2, p.dneck);
    float const vr69 = physics::ly_mass(tmp.rz, t.ra, tmp.beta1);
    float const vr70 = physics::ly_mass(tmp.rz, t.ra, tmp.beta2);
    float const sum6 = ((((vr62 + vr63) + vr64) + vr65) + vr66) + vr67;
    t.r_pol_curv_s0 =
        static_cast<float>((((static_cast<double>(sum6) - (static_cast<double>(vr68) * 0x1.p+1)) -
                             (static_cast<double>(vr69) * 0x1.p+1)) -
                            (static_cast<double>(vr70) * 0x1.p+1)) *
                           0x1.p-1);

    t.p_pol_curv_s0 = t.r_pol_curv_s0;
    t.r_pol_curv_s1 = t.r_pol_curv_s0;
    t.r_pol_curv_s2 = t.r_pol_curv_s0;
    t.r_pol_curv_s3 = t.r_pol_curv_s0;
    t.r_pol_curv_s4 = t.r_pol_curv_s0;
    t.r_pol_curv_s5 = t.r_pol_curv_s0;
}

// SIGZ_Mode_0 = Sqr(0.5 * T_Asym / Curv): modes without a shell-attenuation factor (6486).
float sigz_plain(float t_asym, float curv) {
    return static_cast<float>(
        std::sqrt((static_cast<double>(t_asym) * 0x1.p-1) / static_cast<double>(curv)));
}

// SIGZ_Mode_i = Sqr(0.5 * T_Asym / (Curv * Sqr(R_Att))): modes 1-5 (6503, 6516, 6518, 6530,
// 6541, 6552). `Sqr(R_Att)` is a Single sqrtf, so the product with `curv` stays Single before the
// division is widened.
float sigz_with_attenuation(float t_asym, float curv, float r_att) {
    float const sqrt_att = std::sqrt(r_att);
    float const denom = curv * sqrt_att;
    return static_cast<float>(
        std::sqrt((static_cast<double>(t_asym) * 0x1.p-1) / static_cast<double>(denom)));
}

// SigPol_Mode_i (6490-6496 and its five copies): above 1.E-2 the zero-point motion of the
// polarization oscillation is included via `Tanh` (GEF's own wrapper, not libm's). The C jumps to
// the `Else` on `<=`, so a NaN T_Pol takes the `Tanh` branch.
float mode_sigpol(float t_pol, float r_pol_curv, float hompol) {
    if (!(static_cast<double>(t_pol) <= 0x1.47AE147AE147Bp-7)) { // 1.E-2
        float const vr = fb::tanh(static_cast<float>(static_cast<double>(hompol) /
                                                     (static_cast<double>(t_pol) * 0x1.p+1)));
        return static_cast<float>(
            std::sqrt(((static_cast<double>(hompol) * 0x1.p-2) / static_cast<double>(r_pol_curv)) /
                      static_cast<double>(vr)));
    }
    // including influence of zero-point motion
    return static_cast<float>(
        std::sqrt((static_cast<double>(hompol) * 0x1.p-2) / static_cast<double>(r_pol_curv)));
}

// R_E_intr_Si and the R_Att/R_Att_Sad element(s) of mode `i` (the common head of 6498-6552's
// per-mode blocks): Max(E_exc_Si + Lypair(Z_CN, A_CN), 0), then exp(-R_E_intr_Si/Shell_fading)
// computed once for R_Att and once for R_Att_Sad.
float mode_intrinsic_energy(BinInput const& bin, float e_exc) {
    return fb::max(e_exc + physics::ly_pair(bin.i_z_cn, bin.i_a_cn), 0x0p+0F);
}
float shell_attenuation(float r_e_intr, float shell_fading) {
    return std::exp(
        static_cast<float>(static_cast<double>(-r_e_intr) / static_cast<double>(shell_fading)));
}

// GEF.bas:6476-6558: mean values and standard deviations of the fission modes.
void mode_widths_and_attenuation(BinInput const& bin, WorkingParameters const& w,
                                 params::Parameters const& p, BinTables& t) {
    // 6478-6479 `Dim As Single R_E_intr_S1, ..., R_E_intr_S5` (bin-local, zeroed in every bin)
    t.r_e_intr_s1 = 0x0p+0F;
    t.r_e_intr_s2 = 0x0p+0F;
    t.r_e_intr_s3 = 0x0p+0F;
    t.r_e_intr_s4 = 0x0p+0F;
    t.r_e_intr_s5 = 0x0p+0F;
    // 6480-6481 `ReDim As Single R_Att(7)`, `R_Att_Sad(7)` (bin-local, zero-filled every bin)
    t.r_att.redim({fb::Bounds{0, 7}});
    t.r_att_sad.redim({fb::Bounds{0, 7}});

    // 6486
    t.sigz_mode_0 = sigz_plain(t.t_asym_mode_0, t.r_z_curv_s0);
    // 6490-6496
    t.sigpol_mode_0 = mode_sigpol(t.t_pol_mode_0, t.r_pol_curv_s0, w.hompol);

    // 6498-6509: mode 1
    t.r_e_intr_s1 = mode_intrinsic_energy(bin, t.e_exc_s1);
    t.r_att(1) = shell_attenuation(t.r_e_intr_s1, p.shell_fading);
    t.r_att(6) = t.r_att(1);
    t.r_att_sad(1) = shell_attenuation(t.r_e_intr_s1, p.shell_fading);
    t.r_att_sad(6) = t.r_att_sad(1);
    t.sigz_mode_1 = sigz_with_attenuation(t.t_asym_mode_1, w.p_z_curv_s1, t.r_att(1));
    t.sigpol_mode_1 = mode_sigpol(t.t_pol_mode_1, t.r_pol_curv_s1, w.hompol);

    // 6511-6525: mode 2
    t.r_e_intr_s2 = mode_intrinsic_energy(bin, t.e_exc_s2);
    t.r_att(2) = shell_attenuation(t.r_e_intr_s2, p.shell_fading);
    t.r_att(7) = t.r_att(2);
    t.r_att_sad(2) = shell_attenuation(t.r_e_intr_s2, p.shell_fading);
    t.r_att_sad(7) = t.r_att_sad(2);
    t.sigz_mode_2 = sigz_with_attenuation(t.t_asym_mode_2, w.p_z_curv_s2, t.r_att(2));
    t.sigz_sl5 = sigz_with_attenuation(t.t_asym_mode_2, w.p_z_curv_sl5, t.r_att(2));
    t.sigpol_mode_2 = mode_sigpol(t.t_pol_mode_2, t.r_pol_curv_s2, w.hompol);

    // 6527-6536: mode 3
    t.r_e_intr_s3 = mode_intrinsic_energy(bin, t.e_exc_s3);
    t.r_att(3) = shell_attenuation(t.r_e_intr_s3, p.shell_fading);
    t.r_att_sad(3) = shell_attenuation(t.r_e_intr_s3, p.shell_fading);
    t.sigz_mode_3 = sigz_with_attenuation(t.t_asym_mode_3, w.p_z_curv_s3, t.r_att(3));
    t.sigpol_mode_3 = mode_sigpol(t.t_pol_mode_3, t.r_pol_curv_s3, w.hompol);

    // 6538-6547: mode 4
    t.r_e_intr_s4 = mode_intrinsic_energy(bin, t.e_exc_s4);
    t.r_att(4) = shell_attenuation(t.r_e_intr_s4, p.shell_fading);
    t.r_att_sad(4) = shell_attenuation(t.r_e_intr_s4, p.shell_fading);
    t.sigz_mode_4 = sigz_with_attenuation(t.t_asym_mode_4, w.p_z_curv_s4, t.r_att(4));
    t.sigpol_mode_4 = mode_sigpol(t.t_pol_mode_4, t.r_pol_curv_s4, w.hompol);

    // 6549-6558: mode 5. MILESTONE_7_PLAN.md §4 candidate (a): R_Att_Sad(5) uses R_E_intr_S4, not
    // R_E_intr_S5 (ported faithfully).
    t.r_e_intr_s5 = mode_intrinsic_energy(bin, t.e_exc_s5);
    t.r_att(5) = shell_attenuation(t.r_e_intr_s5, p.shell_fading);
    t.r_att_sad(5) = shell_attenuation(t.r_e_intr_s4, p.shell_fading);
    t.sigz_mode_5 = sigz_with_attenuation(t.t_asym_mode_5, w.p_z_curv_s5, t.r_att(5));
    t.sigpol_mode_5 = mode_sigpol(t.t_pol_mode_5, t.r_pol_curv_s5, w.hompol);
}

} // namespace

void barriers_temperatures_and_widths(BinInput const& bin, std::int64_t p_a_cn,
                                      WorkingParameters const& w, params::Parameters const& p,
                                      data::TableSet const& tables, BinTables& t,
                                      Temporaries& tmp) {
    energy_and_barriers(bin, tables, t);
    mode_shell_effects_and_barriers(bin, p_a_cn, w, p, t, tmp);
    collective_temperatures(bin, p, w, tables, t);
    polarisation_stiffness(bin, p, t, tmp);
    mode_widths_and_attenuation(bin, w, p, t);
}

} // namespace gef::tables
