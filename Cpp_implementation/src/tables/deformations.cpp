// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF.bas:5609-6058, transcribed from the C fbc 1.10.1 emits for it (GEF.c:59061-60564). The
// comparisons keep the C's form (`goto` on the negated condition), so that a NaN takes the
// branch it takes in BASIC. Array accesses in the C go through the descriptors without bound
// checks. For the Z and A that U_Valid admits (Z 76-120, A/Z up to 289/90) every index stays
// inside the declared bounds except the A index of Zmean and Zshift when A_CN > 360
// (QUIRK(Q-061), mean_z). `I_short` (GEF.bas:1747, a main-level Integer that every loop
// re-initialises) is a local loop counter.

#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "physics/helpers.hpp"
#include "physics/masses.hpp"
#include "physics/shape.hpp"
#include "tables/builder.hpp"

#include <cmath>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <vector>

namespace gef::tables {

namespace {

constexpr std::int64_t ten = 10;

// GEF.bas:5609-5617: neutrons emitted between saddle and scission.
void scission_limit(BinInput const& bin, BinTables& t) {
    // 5610 `Dim As Single Escission_lim` (zeroed in every bin)
    t.escission_lim = 0.0F;
    // 5614: I_Z_CN^2 is a Double product, Csng'ed
    auto const zsqra_fis =
        static_cast<float>(static_cast<double>(static_cast<float>(
                               static_cast<double>(bin.i_z_cn) * static_cast<double>(bin.i_z_cn))) /
                           static_cast<double>(static_cast<float>(bin.i_a_cn)));
    // 5616
    t.escission_lim =
        static_cast<float>(std::exp(static_cast<double>(-zsqra_fis) / 0x1.Ap+3) * 0x1.C2p+9);
}

// GEF.bas:5631-5694: central Z of the fission modes (Boeckstiegel et al., 2008), copied to the
// global P_Z_Mean_S*, and N of the CN.
void mode_centres(BinInput const& bin, WorkingParameters const& w, BinTables& t) {
    // 5633-5637
    auto const r_z_mod = static_cast<float>(bin.i_z_cn);
    auto const r_a_mod = static_cast<float>(bin.i_a_cn);
    auto const r_corr1 = static_cast<float>(static_cast<double>(w.p_corr_s1) *
                                            (static_cast<double>(r_z_mod) + -0x1.7p+6));
    auto const r_corr2 = static_cast<float>(
        (static_cast<double>(r_a_mod) - (static_cast<double>(r_z_mod * 0x1.D8p+7F) / 0x1.7p+6)) *
        0x1.C28F5C28F5C29p-5);
    // 5640
    t.zc_mode_0 = static_cast<float>(static_cast<double>(r_z_mod) * 0x1.p-1);
    // 5643-5645 (fbc folds the constant factors and terms)
    double const vr4 = std::pow(static_cast<double>(r_z_mod), 0x1.4CCCCCCCCCCCDp+0);
    t.zc_mode_1 =
        static_cast<float>(((((vr4 / static_cast<double>(r_a_mod)) * 0x1.5AAAAAAAAAA98p+4) +
                             static_cast<double>(w.p_dz_mean_s1)) +
                            static_cast<double>(r_corr1)) +
                           0x1.300000000001Cp+4);
    // 5648-5650
    double const vr5 = std::pow(static_cast<double>(r_z_mod), 0x1.4CCCCCCCCCCCDp+0);
    t.zc_mode_2 =
        static_cast<float>(((((vr5 / static_cast<double>(r_a_mod)) * 0x1.5AAAAAAAAAA98p+4) +
                             static_cast<double>(w.p_dz_mean_s2)) +
                            static_cast<double>(r_corr2)) +
                           0x1.600000000001Cp+4);
    // 5658-5661
    t.zc_mode_3 = static_cast<float>(
        (static_cast<double>(t.zc_mode_2) + static_cast<double>(w.p_dz_mean_s3)) + 0x1.6p+2);
    t.zc_mode_3_shift =
        static_cast<float>(static_cast<double>(t.zc_mode_3 - t.zc_mode_0) * -0x1.1EB851EB851ECp-5);
    t.zc_mode_3 = t.zc_mode_3 + t.zc_mode_3_shift;
    // 5665
    t.zc_mode_4 = 0x1.5p+6F;
    // 5677
    t.zc_mode_5 = static_cast<float>(((static_cast<double>(static_cast<float>(fb::add(
                                           fb::sub(bin.i_a_cn, bin.i_z_cn), std::int64_t{-100}))) *
                                       0x1.C28F5C28F5C29p-4) +
                                      static_cast<double>(w.p_dz_mean_s5)) +
                                     0x1.1Cp+5);
    // 5688-5692
    t.p_z_mean_s1 = t.zc_mode_1;
    t.p_z_mean_s2 = t.zc_mode_2;
    t.p_z_mean_s3 = t.zc_mode_3;
    t.p_z_mean_s4 = t.zc_mode_4;
    t.p_z_mean_s5 = t.zc_mode_5;
    // 5694
    t.i_n_cn = fb::sub(bin.i_a_cn, bin.i_z_cn);
}

// `If rbeta < 0 Then rbeta = 0` as fbc compiles it (`if (RBETA >= 0) goto skip`): NaN becomes 0.
float not_negative(float rbeta) {
    return rbeta >= 0x0p+0F ? rbeta : 0x0p+0F;
}

// Lymass(Z, A, beta) - Lymass(Z, A, 0): the deformation energy of 5716-5852.
float deformation_energy(float z, float a, float beta) {
    float const deformed = physics::ly_mass(z, a, beta);
    float const spherical = physics::ly_mass(z, a, 0x0p+0F);
    return deformed - spherical;
}

// (Z1 -/+ 0.5) / Z_CN * A_CN, the A of a fragment with charge polarisation roughly considered
// (5748, 5779, 5797, 5807, 5821, 5833).
float polarised_a(float z1, double half, BinInput const& bin) {
    return static_cast<float>(
        ((static_cast<double>(z1) + half) / static_cast<double>(static_cast<float>(bin.i_z_cn))) *
        static_cast<double>(static_cast<float>(bin.i_a_cn)));
}

// GEF.bas:5699-5741: mode 0, liquid drop with the influence of shells at low E*.
void deformations_mode0(BinInput const& bin, WorkingParameters const& w,
                        params::Parameters const& p, BinTables& t, Temporaries& tmp,
                        std::vector<BetaEquiMessage>& messages) {
    // 5700-5703
    tmp.beta1_prev = 0x1.333334p-2F;
    tmp.beta2_prev = 0x1.333334p-2F;
    tmp.beta1_opt = tmp.beta1_prev;
    tmp.beta2_opt = tmp.beta2_prev;
    std::int64_t const last = fb::sub(bin.i_z_cn, ten);
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        // 5705-5710
        tmp.iz1 = i_short;
        tmp.z1 = static_cast<float>(tmp.iz1);
        tmp.iz2 = fb::sub(bin.i_z_cn, tmp.iz1);
        tmp.z2 = static_cast<float>(tmp.iz2);
        tmp.a1 = static_cast<float>(static_cast<double>(tmp.z1) /
                                    static_cast<double>(static_cast<float>(bin.i_z_cn))) *
                 static_cast<float>(bin.i_a_cn);
        tmp.a2 = static_cast<float>(bin.i_a_cn) - tmp.a1;
        // 5713-5719
        t.beta(-1, 1, tmp.iz1) = static_cast<float>(
            static_cast<double>(physics::beta_light(tmp.iz1, w.betal0, w.betal1)) +
            -0x1.999999999999Ap-4);
        t.beta(-1, 2, tmp.iz2) = static_cast<float>(
            static_cast<double>(physics::beta_light(tmp.iz2, w.betal0, w.betal1)) +
            -0x1.999999999999Ap-4);
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, t.beta(-1, 1, tmp.iz1));
        t.edefo(-1, 1, tmp.iz1) = tmp.e_defo;
        tmp.e_defo = deformation_energy(tmp.z2, tmp.a2, t.beta(-1, 2, tmp.iz2));
        t.edefo(-1, 2, tmp.iz2) = tmp.e_defo;
        // 5722: beta1_opt, beta2_opt ByRef, changed only on improvement
        physics::BetaEquiResult const equi =
            physics::beta_equi(tmp.a1, tmp.a2, tmp.z1, tmp.z2, p.dneck, tmp.beta1_prev,
                               tmp.beta2_prev, tmp.beta1_opt, tmp.beta2_opt);
        tmp.beta1_opt = equi.beta1opt;
        tmp.beta2_opt = equi.beta2opt;
        if (equi.print_not_converged) {
            // QUIRK(Q-041): BASIC prints to file number f; the caller decides (plan D6)
            messages.push_back(BetaEquiMessage{.z1 = tmp.z1, .n = equi.n});
        }
        // 5728-5738
        t.beta(0, 1, tmp.iz1) = tmp.beta1_opt;
        t.beta(0, 2, tmp.iz2) = tmp.beta2_opt;
        tmp.beta1_prev = tmp.beta1_opt;
        tmp.beta2_prev = tmp.beta2_opt;
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, tmp.beta1_opt);
        t.edefo(0, 1, tmp.iz1) = tmp.e_defo;
        tmp.e_defo = deformation_energy(tmp.z2, tmp.a2, tmp.beta2_opt);
        t.edefo(0, 2, tmp.iz2) = tmp.e_defo;
    }
}

// GEF.bas:5744-5873: modes 1-7.
void deformations_modes(BinInput const& bin, WorkingParameters const& w, BinTables& t,
                        Temporaries& tmp) {
    std::int64_t const last = fb::sub(bin.i_z_cn, ten);
    // 5745-5772, mode 1: deformed shells (light) and spherical (heavy)
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        tmp.z1 = static_cast<float>(i_short);
        tmp.z2 = static_cast<float>(bin.i_z_cn) - tmp.z1;
        tmp.a1 = polarised_a(tmp.z1, -0x1.p-1, bin);
        tmp.a2 = static_cast<float>(bin.i_a_cn) - tmp.a1;
        if (!(static_cast<double>(bin.i_z_cn) * 0x1.p-1 >= static_cast<double>(t.zc_mode_1))) {
            // 5756-5758
            tmp.rbeta = physics::beta_light(i_short, w.betal0, w.betal1);
            tmp.rbeta = not_negative(tmp.rbeta);
        } else {
            // 5760-5761
            tmp.rbeta = physics::beta_heavy(i_short, w.betah0, w.betah1);
            tmp.rbeta = not_negative(tmp.rbeta);
        }
        // 5763-5765
        t.beta(1, 1, i_short) = tmp.rbeta;
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, tmp.rbeta);
        t.edefo(1, 1, i_short) = tmp.e_defo;
        // 5768-5771. MILESTONE_7_PLAN.md §4 candidate (d): Edefo(1,2,·) of the heavy fragment is
        // computed with the light fragment's A1 = (Z1 - 0.5)/Z_CN*A_CN.
        tmp.rbeta = 0x1.A9FBE8p-3F;
        t.beta(1, 2, i_short) = tmp.rbeta;
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, tmp.rbeta);
        t.edefo(1, 2, i_short) = tmp.e_defo;
    }

    // 5776-5791, mode 2: deformed shells (light and heavy), light fragment
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        tmp.z1 = static_cast<float>(i_short);
        tmp.z2 = static_cast<float>(bin.i_z_cn) - tmp.z1;
        tmp.a1 = polarised_a(tmp.z1, -0x1.p-1, bin);
        tmp.a2 = static_cast<float>(bin.i_a_cn) - tmp.a1;
        if (!(static_cast<double>(bin.i_z_cn) * 0x1.p-1 >= static_cast<double>(t.zc_mode_2))) {
            // 5783-5784
            tmp.rbeta = physics::beta_light(i_short, w.betal0, w.betal1);
            tmp.rbeta = not_negative(tmp.rbeta);
        } else {
            // 5786
            tmp.rbeta = physics::beta_heavy(i_short, w.betah0, w.betah1);
        }
        // 5788-5790
        t.beta(2, 1, i_short) = tmp.rbeta;
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, tmp.rbeta);
        t.edefo(2, 1, i_short) = tmp.e_defo;
    }
    // 5792-5801, mode 2, heavy fragment (at the S2 shell)
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        tmp.rbeta = physics::beta_heavy(i_short, w.betah0, w.betah1);
        tmp.rbeta = not_negative(tmp.rbeta);
        t.beta(2, 2, i_short) = tmp.rbeta;
        tmp.z1 = static_cast<float>(i_short);
        tmp.a1 = polarised_a(tmp.z1, 0x1.p-1, bin);
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, tmp.rbeta);
        if (!(tmp.z1 <= 0x1.Dp+5F)) {
            tmp.e_defo = static_cast<float>(
                static_cast<double>(tmp.e_defo) +
                (static_cast<double>(tmp.z1 + -0x1.Dp+5F) * 0x1.2666666666666p+1));
        }
        t.edefo(2, 2, i_short) = tmp.e_defo;
    }

    // 5804-5815, mode 3, light fragment
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        tmp.z1 = static_cast<float>(i_short);
        tmp.z2 = static_cast<float>(bin.i_z_cn) - tmp.z1;
        tmp.a1 = polarised_a(tmp.z1, -0x1.p-1, bin);
        tmp.a2 = static_cast<float>(bin.i_a_cn) - tmp.a1;
        tmp.rbeta = physics::beta_light(i_short, w.betal0, w.betal1);
        tmp.rbeta = fb::max(
            static_cast<float>(static_cast<double>(tmp.rbeta) + -0x1.999999999999Ap-4), 0x0p+0F);
        t.beta(3, 1, i_short) = tmp.rbeta;
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, tmp.rbeta);
        t.edefo(3, 1, i_short) = tmp.e_defo;
    }
    // 5816-5825, mode 3, heavy fragment
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        tmp.rbeta = physics::beta_heavy(i_short, w.betah0, w.betah1) + w.dbeta_s3;
        tmp.rbeta = not_negative(tmp.rbeta);
        t.beta(3, 2, i_short) = tmp.rbeta;
        tmp.z1 = static_cast<float>(i_short);
        tmp.a1 = polarised_a(tmp.z1, 0x1.p-1, bin);
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, tmp.rbeta);
        if (!(tmp.z1 <= 0x1.Dp+5F)) {
            tmp.e_defo = static_cast<float>(
                static_cast<double>(tmp.e_defo) +
                (static_cast<double>(tmp.z1 + -0x1.Dp+5F) * 0x1.2666666666666p+1));
        }
        t.edefo(3, 2, i_short) = tmp.e_defo;
    }

    // 5828-5840, mode 4 (S4, Z around 84)
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        tmp.rbeta = physics::beta_light(i_short, w.betal0, w.betal1);
        tmp.rbeta = not_negative(tmp.rbeta);
        // 5831. QUIRK(Q-009): writes Beta(5,1,·), so Beta(4,1,·) keeps its 0 (5848 overwrites
        // this element)
        t.beta(5, 1, i_short) = tmp.rbeta;
        tmp.z1 = static_cast<float>(i_short);
        tmp.a1 = polarised_a(tmp.z1, -0x1.p-1, bin);
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, tmp.rbeta);
        t.edefo(4, 1, i_short) = tmp.e_defo;
        // 5836-5839: heavy fragment near Pb
        tmp.rbeta = 0x0p+0F;
        t.beta(4, 2, i_short) = tmp.rbeta;
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, tmp.rbeta);
        t.edefo(4, 2, i_short) = tmp.e_defo;
    }

    // 5843-5853, mode 5 (S5, fissioning nucleus around Z = 80, Z of the fragments around 38)
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        tmp.z1 = static_cast<float>(i_short);
        tmp.a1 = static_cast<float>(static_cast<double>(tmp.z1) /
                                    static_cast<double>(static_cast<float>(bin.i_z_cn))) *
                 static_cast<float>(bin.i_a_cn);
        tmp.rbeta = t.beta(2, 1, i_short);
        tmp.rbeta = not_negative(tmp.rbeta);
        t.beta(5, 1, i_short) = tmp.rbeta;
        t.beta(5, 2, i_short) = tmp.rbeta;
        tmp.e_defo = deformation_energy(tmp.z1, tmp.a1, tmp.rbeta);
        t.edefo(5, 1, i_short) = tmp.e_defo;
        t.edefo(5, 2, i_short) = tmp.e_defo;
    }

    // 5856-5863, mode 6 (ST1 in both fragments)
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        tmp.z1 = static_cast<float>(i_short);
        tmp.z2 = static_cast<float>(bin.i_z_cn) - tmp.z1;
        tmp.rbeta = t.beta(1, 2, i_short);
        tmp.rbeta = not_negative(tmp.rbeta);
        std::int64_t const iz = fb::f2l(std::floor(tmp.z1)); // Int(Z1)
        t.beta(6, 1, iz) = tmp.rbeta;
        t.beta(6, 2, iz) = tmp.rbeta;
    }

    // 5866-5873, mode 7 (ST2 in both fragments)
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        tmp.z1 = static_cast<float>(i_short);
        tmp.z2 = static_cast<float>(bin.i_z_cn) - tmp.z1;
        tmp.rbeta = t.beta(2, 2, i_short);
        tmp.rbeta = not_negative(tmp.rbeta);
        std::int64_t const iz = fb::f2l(std::floor(tmp.z1)); // Int(Z1)
        t.beta(7, 1, iz) = tmp.rbeta;
        t.beta(7, 2, iz) = tmp.rbeta;
    }
}

// ZUCD = I_short / A_CN * Z_CN (5880, 5892, 5917, 5938, 5956, 5970).
float unchanged_charge_density(std::int64_t i_short, BinInput const& bin) {
    return static_cast<float>(static_cast<double>(static_cast<float>(i_short)) /
                              static_cast<double>(static_cast<float>(bin.i_a_cn))) *
           static_cast<float>(bin.i_z_cn);
}

// Zmean and Zshift of mode `m` for the fragment with A = i_short and its partner (5884-5887 and
// the five copies after it).
void store_mean_z(BinTables& t, std::int64_t m, std::int64_t k_short, std::int64_t k_partner,
                  std::int64_t i_short, BinInput const& bin, float zf) {
    std::int64_t const partner = fb::sub(bin.i_a_cn, i_short);
    t.zmean(m, k_short, i_short) = zf;
    t.zshift(m, k_short, i_short) = zf - t.zucd;
    t.zmean(m, k_partner, partner) = static_cast<float>(bin.i_z_cn) - zf;
    t.zshift(m, k_partner, partner) = t.zucd - zf;
}

// Z1 - 0.55 * Bell(I_short - Z1, 45, 49.5): polarisation by the N = 50 shell (5925, 5945).
float n50_polarisation(std::int64_t i_short, float z1) {
    float const bell = physics::bell(static_cast<float>(i_short) - z1, 0x1.68p+5F, 0x1.8Cp+5F);
    return static_cast<float>(static_cast<double>(z1) -
                              (static_cast<double>(bell) * 0x1.199999999999Ap-1));
}

// GEF.bas:5876-5991: mean Z as a function of A for modes 0-5; writes the global Z.
void mean_z(BinInput const& bin, WorkingParameters const& w, params::Parameters const& p,
            BinTables& t, Temporaries& tmp, float& z) {
    std::int64_t const last = fb::sub(bin.i_a_cn, ten);
    // QUIRK(Q-061): with A_CN > 360 the loops below index Zmean and Zshift beyond 350, which
    // BASIC does not check: the first writes alias other rows, those of mode 5 run past the end of
    // both arrays (heap corruption; the reference binary writes P3 and dies with SIGSEGV later in
    // the bin, capture m7-q061-z120a385). Undefined behaviour is not reproduced (as Q-039, Q-053).
    if (last > t.zmean.ubound(3)) {
        throw std::out_of_range("GEF.bas:5879-5991: Zmean/Zshift index " + std::to_string(last) +
                                " beyond 350 for A_CN " + std::to_string(bin.i_a_cn) +
                                " (QUIRKS Q-061)");
    }
    auto const z_cn = static_cast<float>(bin.i_z_cn);
    auto partner = [&](std::int64_t i_short) { return fb::sub(bin.i_a_cn, i_short); };

    // 5879-5888, mode 0
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        t.zucd = unchanged_charge_density(i_short, bin);
        tmp.beta1 = t.beta(0, 1, fb::d2l(std::floor(static_cast<double>(t.zucd) + 0x1.p-1)));
        tmp.beta2 = t.beta(0, 2, fb::d2l(std::floor(static_cast<double>(z_cn - t.zucd) + 0x1.p-1)));
        tmp.z1 = physics::z_equi(bin.i_z_cn, i_short, partner(i_short), tmp.beta1, tmp.beta2,
                                 p.dneck, 0);
        store_mean_z(t, 0, 1, 2, i_short, bin, tmp.z1);
    }

    // 5891-5913, mode 1
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        t.zucd = unchanged_charge_density(i_short, bin);
        z = t.zucd + p.zpol1;
        tmp.beta1 = t.beta(1, 1, fb::f2l(z));
        z = t.zucd - p.zpol1;
        tmp.beta2 = t.beta(1, 2, fb::f2l(z_cn - z));
        if (!(static_cast<double>(z_cn) * 0x1.p-1 >= static_cast<double>(t.zc_mode_1))) {
            // 5898-5899
            tmp.z1 = physics::z_equi(bin.i_z_cn, i_short, partner(i_short), tmp.beta1, tmp.beta2,
                                     p.dneck, 1);
            tmp.z1 = tmp.z1 + w.polaradd;
        } else {
            // 5901
            tmp.z1 = physics::z_equi(bin.i_z_cn, i_short, partner(i_short), tmp.beta1, tmp.beta2,
                                     p.dneck, 1);
        }
        // 5903
        tmp.z1 = tmp.z1 + p.zpol1;
        // 5905-5907: both operands evaluated (no short circuit), no side effects
        if (static_cast<double>(z_cn - tmp.z1) < 0x1.9p+5 && (z_cn - tmp.z1) > tmp.z1) {
            tmp.z1 = static_cast<float>(static_cast<double>(z_cn) + -0x1.9p+5);
        }
        // 5909-5912
        store_mean_z(t, 1, 1, 2, i_short, bin, tmp.z1);
    }

    // 5916-5934, mode 2
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        t.zucd = unchanged_charge_density(i_short, bin);
        z = t.zucd;
        tmp.beta1 = t.beta(2, 1, fb::f2l(z));
        tmp.beta2 = t.beta(2, 2, fb::f2l(z_cn - z));
        if (!(static_cast<double>(z_cn) * 0x1.p-1 >= static_cast<double>(t.zc_mode_2))) {
            // 5922-5925
            tmp.z1 = physics::z_equi(bin.i_z_cn, i_short, partner(i_short), tmp.beta1, tmp.beta2,
                                     p.dneck, 2);
            tmp.z1 = tmp.z1 + w.polaradd;
            tmp.z1 = n50_polarisation(i_short, tmp.z1);
        } else {
            // 5927
            tmp.z1 = physics::z_equi(bin.i_z_cn, i_short, partner(i_short), tmp.beta1, tmp.beta2,
                                     p.dneck, 2);
        }
        // 5930-5933
        store_mean_z(t, 2, 1, 2, i_short, bin, tmp.z1);
    }

    // 5937-5952, mode 3
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        t.zucd = unchanged_charge_density(i_short, bin);
        z = t.zucd;
        tmp.beta1 = t.beta(3, 1, fb::f2l(z));
        tmp.beta2 = t.beta(3, 2, fb::sub(bin.i_z_cn, fb::f2l(z)));
        tmp.z1 = physics::z_equi(bin.i_z_cn, i_short, partner(i_short), tmp.beta1, tmp.beta2,
                                 p.dneck, 3);
        tmp.z1 = tmp.z1 + w.polaradd;
        tmp.z1 = n50_polarisation(i_short, tmp.z1);
        store_mean_z(t, 3, 1, 2, i_short, bin, tmp.z1);
    }

    // 5955-5966, mode 4. Beta(4,1,·) is 0 (QUIRK(Q-009), 5831).
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        t.zucd = unchanged_charge_density(i_short, bin);
        z = t.zucd;
        tmp.beta1 = t.beta(4, 1, fb::f2l(z));
        tmp.beta2 = t.beta(4, 2, fb::sub(bin.i_z_cn, fb::f2l(z)));
        tmp.z1 = physics::z_equi(bin.i_z_cn, i_short, partner(i_short), tmp.beta1, tmp.beta2,
                                 p.dneck, 4);
        tmp.z1 = tmp.z1 + w.polaradd;
        store_mean_z(t, 4, 1, 2, i_short, bin, tmp.z1);
    }

    // 5969-5991, mode 5: the loop runs over the heavy fragment
    for (std::int64_t i_short = 10; i_short <= last; ++i_short) {
        t.zucd = unchanged_charge_density(i_short, bin);
        z = t.zucd;
        tmp.beta1 = t.beta(5, 1, fb::f2l(z_cn - z)); // light fragment
        tmp.beta2 = t.beta(5, 2, fb::f2l(z));        // heavy fragment
        tmp.z2 = physics::z_equi(bin.i_z_cn, i_short, partner(i_short), tmp.beta2, tmp.beta1,
                                 p.dneck, 5);
        tmp.z2 = tmp.z2 + w.polaradd;
        store_mean_z(t, 5, 2, 1, i_short, bin, tmp.z2);
    }
}

// One mode of GEF.bas:5995-6048: RZpol and RA iterated three times on the Zshift of fragment
// `k`, then the mean A and N of the mode.
void z_a_relation(BinInput const& bin, BinTables& t, float zc, std::int64_t m, std::int64_t k,
                  float& ac, float& nc) {
    auto ra_of = [&] {
        return static_cast<float>(
            static_cast<double>((zc - t.rzpol) * static_cast<float>(bin.i_a_cn)) /
            static_cast<double>(static_cast<float>(bin.i_z_cn)));
    };
    t.rzpol = 0x0p+0F;
    for (int i_short = 1; i_short <= 3; ++i_short) {
        t.ra = ra_of();
        t.rzpol = t.zshift(m, k, fb::f2l(t.ra));
    }
    ac = ra_of();
    nc = ac - zc;
}

// GEF.bas:5995-6048: general relations between Z and A of the modes.
void z_a_relations(BinInput const& bin, BinTables& t) {
    z_a_relation(bin, t, t.zc_mode_0, 0, 2, t.ac_mode_0, t.nc_mode_0); // 5997-6003
    z_a_relation(bin, t, t.zc_mode_1, 1, 2, t.ac_mode_1, t.nc_mode_1); // 6006-6012
    z_a_relation(bin, t, t.zc_mode_2, 2, 2, t.ac_mode_2, t.nc_mode_2); // 6015-6021
    z_a_relation(bin, t, t.zc_mode_3, 3, 2, t.ac_mode_3, t.nc_mode_3); // 6024-6030
    z_a_relation(bin, t, t.zc_mode_4, 4, 1, t.ac_mode_4, t.nc_mode_4); // 6033-6039
    z_a_relation(bin, t, t.zc_mode_5, 5, 1, t.ac_mode_5, t.nc_mode_5); // 6042-6048
}

// 8 / x^2 * curvature (6053-6058).
float scaled_curvature(std::int64_t n, float curvature) {
    double const square = std::pow(static_cast<double>(static_cast<float>(n)), 0x1.p+1);
    return static_cast<float>((0x1.p+3 / square) * static_cast<double>(curvature));
}

// GEF.bas:6050-6058: potential curvatures of the fission modes.
void curvatures(BinInput const& bin, params::Parameters const& p, float spin_cn, BinTables& t) {
    auto const z_cn = static_cast<float>(bin.i_z_cn);
    auto const a_cn = static_cast<float>(bin.i_a_cn);
    // 6053: the width of the mass distribution (potential between saddle and scission)
    t.r_z_curv_s0 =
        scaled_curvature(bin.i_z_cn, physics::masscurv(z_cn, a_cn, spin_cn, p.kappa, p.kappa4));
    // 6055-6058: the yields of the modes (potential near the saddle)
    t.r_z_curv1_s0 =
        scaled_curvature(bin.i_z_cn, physics::masscurv1(z_cn, a_cn, 0x0p+0F, p.kappa, p.kappa4));
    t.r_a_curv1_s0 =
        scaled_curvature(bin.i_a_cn, physics::masscurv1(z_cn, a_cn, 0x0p+0F, p.kappa, p.kappa4));
    t.r_z_curv2_s0 =
        scaled_curvature(bin.i_z_cn, physics::masscurv2(z_cn, a_cn, 0x0p+0F, p.kappa, p.kappa4));
    t.r_a_curv2_s0 =
        scaled_curvature(bin.i_a_cn, physics::masscurv2(z_cn, a_cn, 0x0p+0F, p.kappa, p.kappa4));
}

} // namespace

void mode_centres_and_deformations(BinInput const& bin, WorkingParameters const& w,
                                   params::Parameters const& p, float spin_cn, BinTables& t,
                                   Temporaries& tmp, float& z,
                                   std::vector<BetaEquiMessage>& messages) {
    scission_limit(bin, t);
    mode_centres(bin, w, t);
    deformations_mode0(bin, w, p, t, tmp, messages);
    deformations_modes(bin, w, t, tmp);
    mean_z(bin, w, p, t, tmp, z);
    z_a_relations(bin, t);
    curvatures(bin, p, spin_cn, t);
}

} // namespace gef::tables
