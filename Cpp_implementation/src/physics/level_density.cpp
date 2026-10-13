// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "physics/level_density.hpp"

#include "fbrt/convert.hpp"
#include "physics/masses.hpp"

#include <cmath>
#include <cstdint>

namespace gef::physics {

namespace {

// Constants as emitted by fbc in GEF.c (build ba9f0aa). The hex-float literals keep the exact bit
// patterns: tegidy_f_damping and fg_gamma are Single in the C source, the others are Double.
constexpr float tegidy_f_damping = 0x1.99999Ap-1F;      // TEGIDY F_DAMPING, 0.8
constexpr double tegidy_tg = 0x1.F9F01B866E43Bp-10;     // TEGIDY 0.00193
constexpr double tegidy_tc = 0x1.D2F1A9FBE76C9p-5;      // TEGIDY 0.057
constexpr double exponent_2_3 = 0x1.55555673AA1BCp-1;   // exponent 2/3 as Double
constexpr double trusanov_coeff = 0x1.810624DD2F1AAp-4; // TRUSANOV 0.094
constexpr double alev_a1 = 0x1.3F7CED916872Bp-4;        // U_alev_ld 0.078
constexpr double alev_a2 = 0x1.D70A3D70A3D71p-4;        // U_alev_ld 0.115
constexpr double tenth = 0x1.999999999999Ap-4;          // 0.1
constexpr double twenty_four = 0x1.8p+4;                // 24.0
constexpr float fg_gamma = 0x1.C28F5Cp-5F;              // FGAMMA 0.055
constexpr double alev_scale = 0x1.E666666666666p-1;     // 0.95
constexpr double exponent_1_25 = 0x1.4p+0;              // 1.25
constexpr double exponent_0_25 = 0x1.p-2;               // 0.25
constexpr double half = 0x1.p-1;                        // 0.5
constexpr double two = 0x1.p+1;                         // 2.0
constexpr double sqrt_pi = 0x1.C5B4941584F18p+0;        // sqrt(3.141)
constexpr double two_sqrt_pi = 0x1.C5B4941584F18p+1;    // 2 * sqrt(3.141)

// (double)(Z + -92) * 0.1: the shell shift applied for Z > 92 in U_levdens_Egidy and _FG.
double z_shift(std::int64_t z) noexcept {
    return static_cast<double>(fb::add(z, std::int64_t{-92})) * tenth;
}

// EEFF of U_Temp and U_Temp2 (GEF.bas:17335-17420): Double sum, narrowed to Single.
float eeff_of(float e, float econd, float rpair, float rshell) noexcept {
    return static_cast<float>(
        static_cast<double>((e - econd) + rpair) +
        (static_cast<double>(rshell) * (-static_cast<double>(std::exp(-fg_gamma * e)) + 1.0)));
}

// TFG of U_Temp and U_Temp2 for EEFF0 above 0.5: RHO0 and RHO1 are narrowed to Single, the log
// difference is taken in Single and the quotient in Double.
float tfg_from(float alev, float eeff0, float eeff1) noexcept {
    auto const rho0 =
        static_cast<float>((1.0 / std::pow(static_cast<double>(eeff0), exponent_1_25)) *
                           std::exp(static_cast<double>(std::sqrt(alev * eeff0)) * two));
    auto const rho1 =
        static_cast<float>((1.0 / std::pow(static_cast<double>(eeff1), exponent_1_25)) *
                           std::exp(static_cast<double>(std::sqrt(alev * eeff1)) * two));
    return static_cast<float>(tenth / static_cast<double>(std::log(rho1) - std::log(rho0)));
}

// RES of U_Temp and U_Temp2: Res = TCT, replaced by TFG unless TFG <= Res. Written as the emitted
// C writes it, so a NaN TFG replaces Res and a finite TFG replaces a NaN Res.
float pick_res(float tct, float tfg) noexcept {
    float res = tct;
    if (!(tfg <= res)) {
        res = tfg;
    }
    return res;
}

// RSHELL of U_levdens_Egidy and U_levdens_FG: -U_SHELL_exp(Z,A), less 0.1 * (Z - 92) for Z > 92.
float rshell_term(data::TableSet const& tables, std::int64_t z, std::int64_t a) {
    float rshell = -u_shell_exp(tables, z, a);
    if (z > 92) {
        rshell = static_cast<float>(static_cast<double>(rshell) - z_shift(z));
    }
    return rshell;
}

// RMICRO of U_levdens_Egidy and U_levdens_FG: -U_SHELL_EO_exp(Z,A), less 0.1 * (Z - 92)
// for Z > 92.
float rmicro_term(data::TableSet const& tables, std::int64_t z, std::int64_t a) {
    float rmicro = -u_shell_eo_exp(tables, z, a);
    if (z > 92) {
        rmicro = static_cast<float>(static_cast<double>(rmicro) - z_shift(z));
    }
    return rmicro;
}

// ERED of U_levdens_Egidy for IPAIR = 1: Ered = E + Rshell - Rmicro + 2.0 * 12.0 / sqr(A).
float ered_pair(data::TableSet const& tables, std::int64_t z, std::int64_t a, float e) {
    float const rshell = rshell_term(tables, z, a);
    float const rmicro = rmicro_term(tables, z, a);
    return static_cast<float>(static_cast<double>((e + rshell) - rmicro) +
                              (twenty_four / std::sqrt(static_cast<double>(a))));
}

} // namespace

// GEF.bas:17173-17177 (Z is not used).
float u_alev_ld([[maybe_unused]] float z, float a) noexcept {
    double const vr4 = std::pow(static_cast<double>(a), exponent_2_3);
    return static_cast<float>((static_cast<double>(a) * alev_a1) + (vr4 * alev_a2));
}

// GEF.bas:17205-17223. The emitted C takes the FG arm for E >= ETRANS, so a NaN E takes the
// Egidy arm.
double u_levdens(data::TableSet const& tables, std::int64_t z, std::int64_t a, float e,
                 std::int64_t ishell, std::int64_t ipair, float tscale, float econd, float etrans,
                 float af_an) {
    if (e >= etrans) {
        return u_levdens_fg(tables, z, a, e, ishell, ipair, tscale, econd, etrans, af_an);
    }
    return u_levdens_egidy(tables, z, a, e, ishell, ipair, tscale, econd, etrans, af_an);
}

// GEF.bas:17225-17259. TSCALE, ECOND, ETRANS and AF_AN are not read by this function.
double u_levdens_egidy(data::TableSet const& tables, std::int64_t z, std::int64_t a, float e,
                       std::int64_t ishell, std::int64_t ipair, [[maybe_unused]] float tscale,
                       [[maybe_unused]] float econd, [[maybe_unused]] float etrans,
                       [[maybe_unused]] float af_an) {
    // DU: shell term for ISHELL = 1, shifted for Z > 92.
    float du = 0.0F;
    if (ishell == 1) {
        du = u_shell_exp(tables, z, a);
        if (z > 92) {
            du = static_cast<float>(static_cast<double>(du) + z_shift(z));
        }
    }
    // ERED: the pairing terms for IPAIR = 1 (ered_pair), else E + 2.0 * 12.0 / sqr(A).
    float const ered = (ipair == 1)
                           ? ered_pair(tables, z, a, e)
                           : static_cast<float>(static_cast<double>(e) +
                                                (twenty_four / std::sqrt(static_cast<double>(a))));
    // TEMP, and the density (1/TEMP) * exp(ERED / TEMP).
    double const vr47 = std::pow(static_cast<double>(a), exponent_2_3);
    auto const temp =
        static_cast<float>(1.0 / ((static_cast<double>(du) * tegidy_tg + tegidy_tc) * vr47));
    return (1.0 / static_cast<double>(temp)) *
           static_cast<double>(
               std::exp(static_cast<float>(static_cast<double>(ered) / static_cast<double>(temp))));
}

// GEF.bas:17261-17331. The ISHELL = 1 and ISHELL <> 1 arms of the BASIC source compute the same
// RMICRO and RSHELL; they differ only in the order of the ERED assignments, so one body is used.
double u_levdens_fg(data::TableSet const& tables, std::int64_t z, std::int64_t a, float e,
                    std::int64_t ishell, std::int64_t ipair, float tscale, float econd,
                    float etrans, float af_an) {
    float const f_enhance = 1.0F;
    float const alev = u_alev_ld(static_cast<float>(z), static_cast<float>(a));
    // RSHELL and RMICRO. RMICRO = RSHELL unless IPAIR != 0 (the pairing terms).
    float const rshell = rshell_term(tables, z, a);
    float const rmicro = (ipair != 0) ? rmicro_term(tables, z, a) : rshell;
    float const ered_trans = ((etrans + rshell) - rmicro) - econd;
    float const ered = ((e + rshell) - rmicro) - econd;
    // RHO1_TRANS: the Egidy density at E = ETRANS.
    double const rho1_trans =
        u_levdens_egidy(tables, z, a, etrans, ishell, ipair, tscale, econd, etrans, af_an);
    double const vr49 = std::pow(static_cast<double>(ered_trans), exponent_1_25);
    double const vr55 = std::pow(static_cast<double>(alev * af_an), exponent_0_25);
    double const vr58 = (((rho1_trans * vr49) * half) / sqrt_pi) * vr55;
    double const vr59 = std::pow(std::log(vr58) / two, two);
    auto const du = static_cast<float>(
        (static_cast<double>(ered_trans) - ((1.0 / static_cast<double>(alev * af_an)) * vr59)) /
        static_cast<double>(-std::exp(-fg_gamma * etrans) + 1.0F));
    auto const eshift_shell = static_cast<float>(
        static_cast<double>(du) * (-static_cast<double>(std::exp(-fg_gamma * e)) + 1.0));
    double const vr81 = std::pow(static_cast<double>(alev * af_an), exponent_0_25);
    double const vr83 = std::pow(static_cast<double>(ered), exponent_1_25);
    double const rho1 =
        (two_sqrt_pi / (vr81 * vr83)) *
        std::exp(static_cast<double>(std::sqrt((alev * af_an) * (ered - eshift_shell))) * two);
    return static_cast<double>(f_enhance) * rho1;
}

// GEF.bas:17335-17385. ETRANS is not read by this function.
float u_temp(data::TableSet const& tables, float z, float a, float e, std::int64_t ishell,
             std::int64_t ipair, float tscale, float econd, [[maybe_unused]] float etrans) {
    auto const alev = static_cast<float>(static_cast<double>(u_alev_ld(z, a)) * alev_scale);
    // RSHELL: shell correction for ISHELL = 1 only.
    float rshell = 0.0F;
    if (ishell == 1) {
        rshell = u_shell(tables, fb::f2l(z), fb::f2l(a));
    }
    float const tct = tegidy(a, rshell, tscale);
    // RPAIR: pairing energy for IPAIR = 1 only.
    float rpair = 0.0F;
    if (ipair == 1) {
        rpair = ly_pair(fb::f2l(z), fb::f2l(a));
    }
    float const eeff0 = eeff_of(e, econd, rpair, rshell);
    auto const e1 = static_cast<float>(static_cast<double>(e) + tenth);
    float const eeff1 = eeff_of(e1, econd, rpair, rshell);
    // The emitted C takes the zero arm for (double)EEFF0 <= 0.5; a NaN EEFF0 takes the FG arm.
    float const tfg = (static_cast<double>(eeff0) <= half) ? 0.0F : tfg_from(alev, eeff0, eeff1);
    return pick_res(tct, tfg);
}

// GEF.bas:17388-17420. ETRANS is not read by this function.
float u_temp2(float z, float a, float e, float rshell, float rpair, float tscale, float econd,
              [[maybe_unused]] float etrans) {
    auto const alev = static_cast<float>(static_cast<double>(u_alev_ld(z, a)) * alev_scale);
    float const tct = tegidy(a, rshell, tscale);
    float const eeff0 = eeff_of(e, econd, rpair, rshell);
    auto const eeff1 = static_cast<float>(static_cast<double>(eeff0) + tenth);
    // The emitted C takes the zero arm for (double)EEFF0 <= 0.5; a NaN EEFF0 takes the FG arm.
    float const tfg = (static_cast<double>(eeff0) <= half) ? 0.0F : tfg_from(alev, eeff0, eeff1);
    return pick_res(tct, tfg);
}

// GEF.bas:16072-16095. TEMP_SMOOTH and T_FAC do not feed the result and are not computed.
float tegidy(float a, float du, float fred) noexcept {
    double const vr15 = std::pow(static_cast<double>(a), exponent_2_3);
    auto const temp = static_cast<float>(
        1.0 / (((static_cast<double>(tegidy_f_damping) * static_cast<double>(du)) * tegidy_tg +
                tegidy_tc) *
               vr15));
    return temp * fred;
}

// GEF.bas:16098-16108. EMIN and EEFF do not feed the result and are not computed.
// QUIRK(Q-040): the pairing floor Eeff = Max(E, Emin) is computed in BASIC but the result uses E.
float trusanov(float e, float a) noexcept {
    return static_cast<float>(
        std::sqrt(static_cast<double>(e) / (static_cast<double>(a) * trusanov_coeff)));
}

} // namespace gef::physics
