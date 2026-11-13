// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF.bas:7040-7507, transcribed from the C fbc 1.10.1 emits for them: shell effects,
// temperatures, the intrinsic excitation energy at scission per mode, the even-odd effect, the
// energy sorting and the fragments' RMS spins. Comparisons of Singles keep the C's form (`goto`
// on the negated condition), so that a NaN takes the branch it takes in BASIC. Every access of
// the eight A-indexed tables goes through fragment_element (QUIRK(Q-061)).

#include "data/tables.hpp"
#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "params/parameters.hpp"
#include "physics/helpers.hpp"
#include "physics/level_density.hpp"
#include "physics/shape.hpp"
#include "tables/bin_plan.hpp"
#include "tables/bin_tables.hpp"
#include "tables/builder.hpp"
#include "tables/fragment_memory.hpp"
#include "tables/working_parameters.hpp"

#include <cmath>
#include <cstdint>
#include <utility>

namespace gef::tables {

namespace {

using FT = FragmentTable;

// GEF.bas:7044-7070: Eshell(J, 1, I) = 0 and Eshell(J, 2, I) = DUJ, the shell effect of mode J
// at the fragment's deformation, for I = 1 .. A_CN - 1.
void shell_effects(BinInput const& bin, WorkingParameters const& w, BinTables& t) {
    std::int64_t const last = bin.i_a_cn + -1;
    for (std::int64_t i = 1; i <= last; ++i) {
        // 7045-7047
        for (std::int64_t j = 0; j <= 4; ++j) {
            fragment_element(t, FT::Eshell, j, 1, i) = 0.0F;
        }
        // 7048-7069
        t.du0 = 0.0F;
        fragment_element(t, FT::Eshell, 0, 2, i) = 0.0F;
        t.du1 = fb::min(t.r_shell_s1_eff + w.de_defo_s1, 0.0F);
        fragment_element(t, FT::Eshell, 1, 2, i) = t.du1;
        t.du2 = fb::min(t.r_shell_s2_eff + w.de_defo_s2, 0.0F);
        fragment_element(t, FT::Eshell, 2, 2, i) = t.du2;
        t.du3 = fb::min(t.r_shell_s3_eff + w.de_defo_s3, 0.0F);
        fragment_element(t, FT::Eshell, 3, 2, i) = t.du3;
        t.du4 = fb::min(t.r_shell_s4_eff + w.de_defo_s4, 0.0F);
        fragment_element(t, FT::Eshell, 4, 2, i) = t.du4;
        t.du5 = fb::min(t.r_shell_s5_eff + w.de_defo_s5, 0.0F);
        fragment_element(t, FT::Eshell, 5, 2, i) = t.du5;
    }
}

// GEF.bas:7076-7086: the mean intrinsic temperatures of the heavy and the light fragment.
void intrinsic_temperatures(BinInput const& bin, WorkingParameters const& w,
                            params::Parameters const& p, BinTables& t) {
    auto const a_cn = static_cast<float>(bin.i_a_cn);
    t.t_intr_mode_0 = physics::tegidy(t.ac_mode_0, 0.0F, 0x1.99999Ap-1F);
    t.t_intr_mode_1_heavy = physics::tegidy(t.ac_mode_1, t.r_shell_s1_eff + w.de_defo_s1, p.tscale);
    t.t_intr_mode_1_light = physics::tegidy(a_cn - t.ac_mode_1, 0.0F, p.tscale);
    t.t_intr_mode_2_heavy = physics::tegidy(t.ac_mode_2, t.r_shell_s2_eff + w.de_defo_s2, p.tscale);
    t.t_intr_mode_2_light = physics::tegidy(a_cn - t.ac_mode_2, 0.0F, p.tscale);
    t.t_intr_mode_3_heavy = physics::tegidy(t.ac_mode_3, t.r_shell_s3_eff + w.de_defo_s3, p.tscale);
    t.t_intr_mode_3_light = physics::tegidy(a_cn - t.ac_mode_3, 0.0F, p.tscale);
    t.t_intr_mode_4_heavy = physics::tegidy(t.ac_mode_4, t.r_shell_s4_eff + w.de_defo_s4, p.tscale);
    t.t_intr_mode_4_light = physics::tegidy(a_cn - t.ac_mode_4, 0.0F, p.tscale);
    t.t_intr_mode_5_heavy = physics::tegidy(t.ac_mode_5, t.r_shell_s5_eff + w.de_defo_s5, p.tscale);
    t.t_intr_mode_5_light = physics::tegidy(a_cn - t.ac_mode_5, 0.0F, p.tscale);
}

// GEF.bas:7091-7170: Temp and TempFF per mode 0-5, fragment and A; every value passes through the
// global T. Modes 0-2 first take the shell effect Eshell; mode 2 then overwrites Temp with the
// shell-free temperature (7126-7129), and modes 3-5 take only that.
void temperatures(BinInput const& bin, params::Parameters const& p, BinTables& t,
                  float& temperature) {
    std::int64_t const last = bin.i_a_cn + -1;
    for (std::int64_t mode = 0; mode <= 5; ++mode) {
        for (std::int64_t i = 1; i <= last; ++i) {
            auto const a = static_cast<float>(i);
            if (mode <= 2) {
                for (std::int64_t k = 1; k <= 2; ++k) {
                    temperature =
                        physics::tegidy(a, fragment_element(t, FT::Eshell, mode, k, i), p.tscale);
                    fragment_element(t, FT::Temp, mode, k, i) = temperature;
                }
            }
            if (mode >= 2) {
                for (std::int64_t k = 1; k <= 2; ++k) {
                    temperature = physics::tegidy(a, 0.0F, p.tscale);
                    fragment_element(t, FT::Temp, mode, k, i) = temperature;
                }
            }
            temperature = physics::tegidy(a, 0.0F, 0x1.p+0F);
            fragment_element(t, FT::TempFF, mode, 1, i) = temperature;
            fragment_element(t, FT::TempFF, mode, 2, i) = temperature;
        }
    }
}

// The locals of 7175-7177 (zeroed once before the mode loop; E1, E1ES and E1FG carry over from
// one A or mode to the next when no branch assigns them).
struct SortingLocals {
    float etot = 0.0F;
    float e1fg = 0.0F;
    float e1es = 0.0F;
    float t1 = 0.0F;
    float t2 = 0.0F;
    float e1 = 0.0F;
};

// GEF.bas:7184-7226: the intrinsic excitation energy at scission of mode `mode`.
float scission_energy(BinInput const& bin, WorkingParameters const& w, params::Parameters const& p,
                      BinTables& t, std::int64_t mode) {
    float etot = 0.0F;
    // 7184-7191 (the C assigns Etot only in its mode's branch; every mode 0-7 has one)
    switch (mode) {
    case 0:
        etot = t.e_exc_s0;
        break;
    case 1:
        etot = t.e_exc_s1;
        break;
    case 2:
        etot = t.e_exc_s2;
        break;
    case 3:
        etot = t.e_exc_s3;
        break;
    case 4:
        etot = t.e_exc_s4;
        break;
    case 5:
        etot = t.e_exc_s5;
        break;
    case 6:
        etot = t.e_exc_s11;
        break;
    default:
        etot = t.e_exc_s22;
        break;
    }
    // 7193
    etot = etot - bin.e_rot_cn;
    // 7195-7201: even-even CN, a small excitation energy goes into collective excitation.
    if (((bin.i_z_cn % 2) + (t.i_n_cn % 2)) == 0) {
        if (etot > 0.0F &&
            static_cast<double>(etot) <
                0x1.Cp+4 / static_cast<double>(std::sqrt(static_cast<float>(bin.i_a_cn)))) {
            t.e_coll_saddle(mode) = etot;
            etot = 0.0F;
        }
    }
    // 7213
    if (etot >= 0.0F) {
        t.e_tunn = 0.0F;
    } else {
        t.e_tunn = -etot;
    }
    // 7214-7220 (QUIRK(Q-008): E_tunn, E_pot_scission and E_diss_Scission are shared and keep
    // mode 7's values after the mode loop)
    etot = fb::max(etot, 0.0F);
    t.e_pot_scission = physics::de_saddle_scission(
        static_cast<float>(bin.i_z_cn), static_cast<float>(bin.i_a_cn), p.eshiftsasci_intr);
    t.e_diss_scission = (w.edissfrac * (t.e_pot_scission - t.e_tunn)) + p.epot_shift;
    if (!(t.e_diss_scission >= 0.0F)) {
        t.e_diss_scission = 0.0F;
    }
    etot = etot + t.e_diss_scission;
    // 7224-7226
    if (mode == 2) {
        t.eintr_scission = etot;
    }
    return etot;
}

// GEF.bas:7233-7243: the temperatures of the two fragments; mode 6 (S11) takes those of mode 1,
// mode 7 (S22) those of mode 2, both of fragment 2.
void fragment_temperatures(BinTables const& t, std::int64_t mode, std::int64_t ia1,
                           std::int64_t ia2, SortingLocals& l) {
    if (mode <= 5) {
        l.t1 = fragment_element(t, FT::Temp, mode, 1, ia1);
        l.t2 = fragment_element(t, FT::Temp, mode, 2, ia2);
    }
    if (mode == 6) {
        l.t1 = fragment_element(t, FT::Temp, 1, 2, ia1);
        l.t2 = fragment_element(t, FT::Temp, 1, 2, ia2);
    }
    if (mode == 7) {
        l.t1 = fragment_element(t, FT::Temp, 2, 2, ia1);
        l.t2 = fragment_element(t, FT::Temp, 2, 2, ia2);
    }
}

// GEF.bas:7248-7325: the even-odd effect of the light (IA1) and heavy (IA2) fragment.
// QUIRK(Q-010): PEOZ/PEON are written only for A 40 .. A_CN - 40 and keep their other values.
// QUIRK(Q-011): the mirror branch copies values 7322-7325 already scaled by EOscale, and scales
// them again.
void even_odd(BinInput const& bin, params::Parameters const& p, BinTables& t, std::int64_t mode,
              std::int64_t ia1, std::int64_t ia2, float etot, float dt) {
    // 7248-7257
    float rincr1p = 0.0F;
    if ((bin.i_z_cn % 2) == 0) {
        rincr1p = std::exp(
            static_cast<float>(static_cast<double>(-etot) / static_cast<double>(p.pz_eo_symm)));
    }
    float rincr1n = 0.0F;
    if ((t.i_n_cn % 2) == 0) {
        rincr1n = std::exp(
            static_cast<float>(static_cast<double>(-etot) / static_cast<double>(p.pn_eo_symm)));
    }
    float& peoz_1 = fragment_element(t, FT::Peoz, mode, 1, ia1);
    float& peoz_2 = fragment_element(t, FT::Peoz, mode, 2, ia2);
    float& peon_1 = fragment_element(t, FT::Peon, mode, 1, ia1);
    float& peon_2 = fragment_element(t, FT::Peon, mode, 2, ia2);
    // 7259-7262
    peoz_1 = rincr1p;
    peoz_2 = rincr1p;
    peon_1 = rincr1n;
    peon_2 = rincr1n;
    // 7264-7272
    float rincr2 = 0.0F;
    if (!(etot <= 0.0F)) {
        rincr2 = physics::gaussintegral(
            static_cast<float>(static_cast<double>(dt) / static_cast<double>(etot)) - p.r_eo_thresh,
            static_cast<float>(static_cast<double>(p.r_eo_sigma) *
                               (static_cast<double>(dt) + 0x1.A36E2EB1C432Dp-14)));
    }
    float const rincr2p = (p.r_eo_max - rincr1p) * rincr2;
    float const rincr2n = (p.r_eo_max - rincr1n) * rincr2;
    if (ia1 <= ia2) {
        // 7275-7292
        peoz_1 = peoz_1 + rincr2p;
        if ((bin.i_z_cn % 2) == 0) {
            peoz_2 = peoz_2 + rincr2p;
        } else {
            peoz_2 = peoz_2 - rincr2p;
        }
        peon_1 = peon_1 + rincr2n;
        if ((t.i_n_cn % 2) == 0) {
            peon_2 = peon_2 + rincr2n;
        } else {
            peon_2 = peon_2 - rincr2n;
        }
    } else {
        // 7294-7297: the mirror of the values written for the lighter fragment.
        peoz_1 = fragment_element(std::as_const(t), FT::Peoz, mode, 2, ia1);
        peon_1 = fragment_element(std::as_const(t), FT::Peon, mode, 2, ia1);
        peoz_2 = fragment_element(std::as_const(t), FT::Peoz, mode, 1, ia2);
        peon_2 = fragment_element(std::as_const(t), FT::Peon, mode, 1, ia2);
    }
    // 7322-7325
    peoz_1 = peoz_1 * p.eoscale;
    peoz_2 = peoz_2 * p.eoscale;
    peon_1 = peon_1 * p.eoscale;
    peon_2 = peon_2 * p.eoscale;
}

// GEF.bas:7338-7377: the sorting of the excitation energy Etot between the light (IA1) and the
// heavy (IA2) fragment (QUIRK(Q-010)).
void energy_sorting(BinInput const& bin, params::Parameters const& p, BinTables& t,
                    std::int64_t mode, std::int64_t ia1, std::int64_t ia2, SortingLocals& l) {
    float const etot = l.etot;
    if (!(static_cast<double>(std::fabs(l.t1 - l.t2)) >= 0x1.0C6F7A0B5ED8Dp-20)) {
        // 7339
        l.e1 = static_cast<float>(static_cast<double>(etot) * 0x1.p-1);
    } else {
        // 7343-7355
        if (mode == 0) {
            l.e1es = etot * physics::gaussintegral(l.t2 - l.t1, p.esort_slope_s0);
            l.e1es = fb::min(l.e1es, static_cast<float>(static_cast<double>(etot) * 0x1.p-1));
        } else if (mode == 1) {
            l.e1es =
                etot * fb::min(0x1.p+0F, static_cast<float>(-std::exp(-(static_cast<double>(etot) +
                                                                        -0x1.1333333333333p+2) /
                                                                      0x1.p+1) +
                                                            0x1.p+0));
            l.e1es = fb::max(
                l.e1es, static_cast<float>((static_cast<double>(ia1) / static_cast<double>(ia2)) *
                                           static_cast<double>(etot)));
        } else {
            l.e1es = etot * physics::gaussintegral(l.t2 - l.t1, p.esort_slope);
            l.e1es = fb::min(l.e1es, static_cast<float>(static_cast<double>(etot) * 0x1.p-1));
        }
        // 7357
        l.e1fg = static_cast<float>(static_cast<double>(etot * static_cast<float>(ia1)) /
                                    static_cast<double>(bin.i_a_cn));
        // 7367-7371
        float const from = p.esort_extend * 0x1.Ap+3F;
        float const to = p.esort_extend * 0x1.4p+4F;
        if (!(etot >= from)) {
            l.e1 = l.e1es;
        }
        if (etot >= from && etot <= to) {
            l.e1 = static_cast<float>(static_cast<double>(l.e1es) +
                                      ((static_cast<double>(etot - from) / 0x1.Cp+2) *
                                       static_cast<double>(l.e1fg - l.e1es)));
        }
        if (!(etot <= to)) {
            l.e1 = l.e1fg;
        }
    }
    // 7374-7377
    float const e2 = etot - l.e1;
    fragment_element(t, FT::Epart, mode, 1, ia1) = fb::max(l.e1, 0.0F);
    fragment_element(t, FT::Epart, mode, 2, ia2) = fb::max(e2, 0.0F);
}

// GEF.bas:7433-7464 and 7471-7499: the RMS spin of fragment `k` (Z IZ1, A IA1) in mode `mode`.
float rms_spin(BinInput const& bin, WorkingParameters const& w, params::Parameters const& p,
               data::TableSet const& tables, BinTables const& t, std::int64_t mode, std::int64_t k,
               std::int64_t iz1, std::int64_t in1, std::int64_t ia1, float beta, float spin_cn,
               float& temperature) {
    // 7434-7435
    auto const alph = static_cast<float>(static_cast<double>(beta) / 0x1.95D834874E488p+0);
    auto const i_rigid =
        static_cast<float>(static_cast<double>(bin.i_rigid_spher) *
                           (((static_cast<double>(alph) * 0x1.p-1) +
                             (static_cast<double>(alph * alph) * 0x1.4924924924925p+0)) +
                            0x1.p+0));
    // 7437-7438 (QUIRK(Q-061): at A_CN 385, EPART(7, 2, 351 ..) reads the mass tables)
    // QUIRK(Q-010): EPART(I_Mode, k, IA1) outside A 40 .. A_CN - 40 holds what earlier bins left
    float e_exc = fragment_element(t, tables, FT::Epart, mode, k, ia1);
    if (!(e_exc >= 0.0F)) {
        e_exc = 0.0F;
    }
    // 7439-7445
    temperature = physics::u_temp(tables, static_cast<float>(iz1), static_cast<float>(ia1), e_exc,
                                  1, 1, p.tscale, p.econd, p.etrans);
    if (!(static_cast<double>(p.t_orbital) <= 0x1.999999999999Ap-4)) {
        float const coth_arg = fb::tanh(static_cast<float>(static_cast<double>(p.t_orbital) /
                                                           static_cast<double>(temperature)));
        temperature =
            static_cast<float>(static_cast<double>(p.t_orbital) / static_cast<double>(coth_arg));
    }
    // 7446-7449
    auto const i_eff = static_cast<float>(
        static_cast<double>(i_rigid) *
        // NOLINTNEXTLINE(modernize-use-std-numbers): -0.693E0 as in GEF.c, not ln 2
        (-(std::exp((static_cast<double>(e_exc) * -0x1.62D0E56041893p-1) / 0x1.4p+2) *
           0x1.999999999999Ap-1) +
         0x1.p+0));
    auto j_rms = static_cast<float>(
        std::sqrt((static_cast<double>(i_eff) * static_cast<double>(temperature)) * 0x1.p+1));
    j_rms = j_rms * w.jscaling;
    // 7451
    if ((iz1 % 2) == 1 || (in1 % 2) == 1) {
        j_rms =
            static_cast<float>(static_cast<double>(j_rms) +
                               (static_cast<double>(p.spin_odd) *
                                std::pow(static_cast<double>(static_cast<float>(ia1)) / 0x1.18p+7,
                                         0x1.5555C52E72DA1p-1)));
    }
    // 7460
    double const orbital = std::pow(((static_cast<double>(ia1) / static_cast<double>(bin.i_a_cn)) *
                                     static_cast<double>(spin_cn)) *
                                        0x1.p-1,
                                    0x1.p+1);
    return static_cast<float>(std::sqrt(static_cast<double>(j_rms * j_rms) + orbital));
}

} // namespace

void shells_temperatures_and_energy_sorting(BinInput const& bin, WorkingParameters const& w,
                                            params::Parameters const& p, BinTables& t,
                                            Temporaries& tmp, float& temperature) {
    shell_effects(bin, w, t);
    intrinsic_temperatures(bin, w, p, t);
    temperatures(bin, p, t, temperature);
    // 7175-7178: `Redim E_coll_saddle(0 To 7)` zero-fills it in every bin.
    SortingLocals l;
    t.e_coll_saddle.redim({fb::Bounds{0, 7}});
    // 7182-7379
    for (std::int64_t mode = 0; mode <= 7; ++mode) {
        t.e_coll_saddle(mode) = 0.0F;
        l.etot = scission_energy(bin, w, p, t, mode);
        // 7230-7378
        std::int64_t const last = bin.i_a_cn + -40;
        for (tmp.ia1 = 40; tmp.ia1 <= last; ++tmp.ia1) {
            tmp.ia2 = bin.i_a_cn - tmp.ia1;
            fragment_temperatures(t, mode, tmp.ia1, tmp.ia2, l);
            float const dt = std::fabs(l.t2 - l.t1);
            even_odd(bin, p, t, mode, tmp.ia1, tmp.ia2, l.etot, dt);
            energy_sorting(bin, p, t, mode, tmp.ia1, tmp.ia2, l);
        }
    }
}

void fragment_spins(BinInput& bin, WorkingParameters const& w, params::Parameters const& p,
                    data::TableSet const& tables, BinTables& t, Temporaries& tmp, float spin_cn,
                    float& temperature) {
    // 7421-7506
    std::int64_t const z_last = bin.i_z_cn + -10;
    for (tmp.iz1 = 10; tmp.iz1 <= z_last; ++tmp.iz1) {
        // 7422-7423
        float const aucd = std::floor(static_cast<float>(
            static_cast<double>(static_cast<float>(tmp.iz1) * static_cast<float>(bin.i_a_cn)) /
            static_cast<double>(static_cast<float>(bin.i_z_cn))));
        tmp.ia1 = fb::f2l(std::floor(aucd + -0x1.Ep+3F));
        std::int64_t const a_last = fb::f2l(std::floor(aucd + 0x1.Ep+3F));
        for (; tmp.ia1 <= a_last; ++tmp.ia1) {
            // 7424-7425
            tmp.in1 = tmp.ia1 - tmp.iz1;
            if (tmp.ia1 - tmp.iz1 < 10) {
                continue;
            }
            // 7427
            bin.i_rigid_spher = static_cast<float>(
                (std::pow(static_cast<double>(static_cast<float>(tmp.ia1)), 0x1.AAACD9E83E426p+0) *
                 0x1.58793DD97F62Bp+0) /
                0x1.9F5DB22D0E56p+6);
            // 7429-7503
            for (std::int64_t mode = 0; mode <= 7; ++mode) {
                // 7433-7464
                tmp.beta1 = t.beta(mode, 1, tmp.iz1);
                float const j1 = rms_spin(bin, w, p, tables, t, mode, 1, tmp.iz1, tmp.in1, tmp.ia1,
                                          tmp.beta1, spin_cn, temperature);
                store_spin_rms(t, mode, 1, tmp.ia1 - tmp.iz1, tmp.iz1, j1);
                // 7471-7499
                tmp.beta2 = t.beta(mode, 2, tmp.iz1);
                float const j2 = rms_spin(bin, w, p, tables, t, mode, 2, tmp.iz1, tmp.in1, tmp.ia1,
                                          tmp.beta2, spin_cn, temperature);
                store_spin_rms(t, mode, 2, tmp.ia1 - tmp.iz1, tmp.iz1, j2);
            }
        }
    }
}

} // namespace gef::tables
