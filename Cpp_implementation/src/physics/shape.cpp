// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Ported from the C fbc 1.10.1 emits (python3 -m tools.fbsrc.fbline GEF.bas:<lines>). Where the
// C branches on the negated BASIC comparison, the C++ writes `!(a >= b)` etc., so that NaN takes
// the same path as in BASIC.

#include "physics/shape.hpp"

#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "physics/masses.hpp"

#include <cmath>
#include <cstdint>

namespace gef::physics {

namespace {

// 7/3 as the Double literal of GEF.bas:15954, 15991, 16033.
constexpr double seven_thirds = 0x1.2AAAAAAAAAAABp+1;
// C_rot = 600 (GEF.bas:15947, 15977, 16018).
constexpr float c_rot = 600.0F;

// Z_square_over_A = Z^2 / A (GEF.bas:15951, 15986, 16027).
float z_square_over_a(float z, float a) noexcept {
    return static_cast<float>(static_cast<double>(z * z) / static_cast<double>(a));
}

// RI = (A - 2 * Z) / A (GEF.bas:15952, 15987, 16028).
float ri_of(float z, float a) noexcept {
    return static_cast<float>(static_cast<double>(a - (z * 2.0F)) / static_cast<double>(a));
}

// 1 - kappa * RI^2 in Double, as compiled: -((kappa * RI) * RI) + 1.
double one_minus_kappa_ri2(float kappa, float ri) noexcept {
    return -((static_cast<double>(kappa) * static_cast<double>(ri)) * static_cast<double>(ri)) +
           1.0;
}

// C_rot * RL^2 / A^(7/3) in Double.
double rotation_term(float rl, float a) noexcept {
    double const vr = std::pow(static_cast<double>(a), seven_thirds);
    return ((static_cast<double>(c_rot) * static_cast<double>(rl)) * static_cast<double>(rl)) / vr;
}

// GEF.bas:15993-15995, 16035-16037: If ZsqrA < 36 Then ZsqrA = ZsqrA + 0.9 * (36 - ZsqrA),
// compiled as `if ((double)ZsqrA >= 36) skip` and (ZsqrA + -ZsqrA * 0.9) + 32.4.
float approach_36(float zsqra) noexcept {
    if (!(static_cast<double>(zsqra) >= 36.0)) {
        zsqra = static_cast<float>(
            (static_cast<double>(zsqra) + (-static_cast<double>(zsqra) * 0x1.CCCCCCCCCCCCDp-1)) +
            0x1.0333333333333p+5);
    }
    return zsqra;
}

// LyMass(Z1,A1,beta1) + LyMass(Z2,A2,beta2) + ECoul(Z1,A1,beta1,Z2,A2,beta2,d), left to right
// in Single (GEF.bas:16516 and every energy of Beta_Equi).
float scission_energy(float z1, float a1, float beta1, float z2, float a2, float beta2,
                      float d) noexcept {
    float const vr1 = ly_mass(z1, a1, beta1);
    float const vr2 = ly_mass(z2, a2, beta2);
    float const vr3 = ecoul(z1, a1, beta1, z2, a2, beta2, d);
    return (vr1 + vr2) + vr3;
}

} // namespace

// GEF.bas:15862-15920. The commented-out block GEF.bas:15883-15917 leaves E_shell, dE_defo,
// T_high_mac and Imode unread; they stay parameters so that call sites keep BASIC's argument
// list.
float getyield(float e_rel, float e, [[maybe_unused]] float e_shell, [[maybe_unused]] float de_defo,
               float t_low, float t_high, [[maybe_unused]] float t_high_mac,
               [[maybe_unused]] std::int64_t imode) noexcept {
    // GEF.bas:15877: Exp1 = E_rel / T_low - E / 0.4 (0.4 is the Double 0x1.999999999999Ap-2).
    auto const exp1 =
        static_cast<float>(static_cast<double>(static_cast<float>(static_cast<double>(e_rel) /
                                                                  static_cast<double>(t_low))) -
                           (static_cast<double>(e) / 0x1.999999999999Ap-2));
    float yield = 0.0F;
    // GEF.bas:15879-15882: compiled as `if (Exp1 >= -50) goto else-branch`.
    if (!(exp1 >= -50.0F)) {
        yield = 0.0F;
    } else {
        // Exp(E_rel/T_high - E/0.4) / (Exp(-E_rel / (T_high*T_low/(T_high-T_low))) + 1); the
        // inner Exp is Single (expf), the quotient T_high*T_low/(T_high-T_low) a Single.
        double const num = std::exp(static_cast<double>(static_cast<float>(
                                        static_cast<double>(e_rel) / static_cast<double>(t_high))) -
                                    (static_cast<double>(e) / 0x1.999999999999Ap-2));
        auto const t_eff = static_cast<float>(static_cast<double>(t_high * t_low) /
                                              static_cast<double>(t_high - t_low));
        float const den_exp =
            std::exp(static_cast<float>(static_cast<double>(-e_rel) / static_cast<double>(t_eff)));
        yield = static_cast<float>((num * 1.0) / (static_cast<double>(den_exp) + 1.0));
    }
    // GEF.bas:15918
    return fb::max(yield, 0.0F);
}

// GEF.bas:15923-15928: exp(-9.05 + 4.58 * Log(Z_S_A / 2.3)), as (log * 4.58) + -9.05.
float f1(float z_s_a) noexcept {
    return static_cast<float>(std::exp(
        (std::log(static_cast<double>(z_s_a) / 0x1.2666666666666p+1) * 0x1.251EB851EB852p+2) +
        -0x1.219999999999Ap+3));
}

// GEF.bas:15929-15934: exp(12.08 - 3.27 * Log(Z_S_A / 2.3)), as -(log * 3.27) + 12.08.
float f2(float z_s_a) noexcept {
    return static_cast<float>(std::exp(
        -(std::log(static_cast<double>(z_s_a) / 0x1.2666666666666p+1) * 0x1.A28F5C28F5C29p+1) +
        0x1.828F5C28F5C29p+3));
}

// GEF.bas:15936-15963
float masscurv(float z, float a, float rl, float kappa, float kappa4) noexcept {
    // GEF.bas:15951-15953
    float const z2a = z_square_over_a(z, a);
    float const ri = ri_of(z, a);
    constexpr float riref = 0x1.8EB9C6p-3F;
    // GEF.bas:15954: ZsqrA = Z2A * (1 - k RI^2 - k4 RI^4) / (1 - k RIref^2 - k4 RIref^4)
    //                        + C_rot RL^2 / A^(7/3), in Double.
    double const vr2 = std::pow(static_cast<double>(ri), 4.0);
    double const vr3 = std::pow(static_cast<double>(riref), 4.0);
    auto const zsqra = static_cast<float>(
        ((static_cast<double>(z2a) *
          (one_minus_kappa_ri2(kappa, ri) - (static_cast<double>(kappa4) * vr2))) /
         (one_minus_kappa_ri2(kappa, riref) - (static_cast<double>(kappa4) * vr3))) +
        rotation_term(rl, a));
    // GEF.bas:15959-15962
    float const result1 = f1(zsqra);
    float const result2 = f2(zsqra);
    return fb::min(result1, result2);
}

// GEF.bas:15965-16003. kappa4 is not read (GEF.bas:15988 has no RI^4 term).
float masscurv1(float z, float a, float rl, float kappa, [[maybe_unused]] float kappa4) noexcept {
    // GEF.bas:15986-15988
    float const z2a = z_square_over_a(z, a);
    float const ri = ri_of(z, a);
    auto zsqra = static_cast<float>(static_cast<double>(z2a) * one_minus_kappa_ri2(kappa, ri));
    // GEF.bas:15989-15990: macroscopic neutron and proton separation energies.
    auto const a_minus_1 = static_cast<float>(static_cast<double>(a) + -1.0);
    float const vr8 = ly_mass(z, a_minus_1, 0.0F);
    float const vr9 = ly_mass(z, a, 0.0F);
    float const snmac = vr8 - vr9;
    float const vr10 = ly_mass(static_cast<float>(static_cast<double>(z) + -1.0), a_minus_1, 0.0F);
    float const vr11 = ly_mass(z, a, 0.0F);
    float const spmac = vr10 - vr11;
    // GEF.bas:15991
    zsqra = static_cast<float>(static_cast<double>(zsqra) + rotation_term(rl, a));
    // GEF.bas:15993-15995
    zsqra = approach_36(zsqra);
    // GEF.bas:15997-16000: F2 takes ZsqrA recomputed without rotation and without the 36 limit.
    float const result1 = f1(zsqra);
    zsqra = static_cast<float>(static_cast<double>(z2a) * one_minus_kappa_ri2(kappa, ri));
    float const result2 = f2(zsqra);
    float result = fb::min(result1, result2);
    // GEF.bas:16001: Result * Exp(0.26 * Abs(SNmac - SPmac)); Abs in Single.
    result = static_cast<float>(
        static_cast<double>(result) *
        std::exp(static_cast<double>(std::fabs(snmac - spmac)) * 0x1.0A3D70A3D70A4p-2));
    return result;
}

// GEF.bas:16005-16045. kappa4 is not read.
float masscurv2(float z, float a, float rl, float kappa, [[maybe_unused]] float kappa4) noexcept {
    // GEF.bas:16027-16029
    float const z2a = z_square_over_a(z, a);
    float const ri = ri_of(z, a);
    auto zsqra = static_cast<float>(static_cast<double>(z2a) * one_minus_kappa_ri2(kappa, ri));
    // GEF.bas:16033-16037 (SNmac, SPmac are declared but not computed here)
    zsqra = static_cast<float>(static_cast<double>(zsqra) + rotation_term(rl, a));
    zsqra = approach_36(zsqra);
    // GEF.bas:16039-16043
    float const result1 = f1(zsqra);
    zsqra = static_cast<float>(static_cast<double>(z2a) * one_minus_kappa_ri2(kappa, ri));
    float const result2 = f2(zsqra) * 2.0F;
    return fb::min(result1, result2);
}

// GEF.bas:16047-16063
float de_saddle_scission(float z_cn_in, float a_cn_in, float eshiftsasci) noexcept {
    // GEF.bas:16054: Z^2 / A^0.333333 (the Single-precision literal 0.333333 as a Double).
    double const vr20 = std::pow(static_cast<double>(a_cn_in), 0x1.55553EF6B5D46p-2);
    auto const zsquare_over_athird =
        static_cast<float>(static_cast<double>(z_cn_in * z_cn_in) / vr20);
    // GEF.bas:16055-16056, compiled as (Z2A3 + Eshift) * 0.08 + -93.
    auto const result = static_cast<float>(
        ((static_cast<double>(zsquare_over_athird) + static_cast<double>(eshiftsasci)) *
         0x1.47AE147AE147Bp-4) +
        -0x1.74p+6);
    // GEF.bas:16061
    return fb::max(result, 0.0F);
}

// GEF.bas:16358-16365
float beta_light(std::int64_t z, float betal0, float betal1) noexcept {
    return static_cast<float>(static_cast<double>((static_cast<float>(z) - betal0) * betal1) /
                              20.0);
}

// GEF.bas:16368-16375
float beta_heavy(std::int64_t z, float betah0, float betah1) noexcept {
    return static_cast<float>(static_cast<double>((static_cast<float>(z) - betah0) * betah1) /
                              20.0);
}

// GEF.bas:16379-16426. Imode is not read.
float z_equi(std::int64_t zcn, std::int64_t a1, std::int64_t a2, float beta1, float beta2, float d,
             [[maybe_unused]] std::int64_t imode) noexcept {
    // GEF.bas:16400-16405: UCD charge of fragment 1.
    auto const ra1 = static_cast<float>(a1);
    auto const ra2 = static_cast<float>(a2);
    auto const rzcn = static_cast<float>(zcn);
    float const z1ucd =
        static_cast<float>(static_cast<double>(ra1) / static_cast<double>(ra1 + ra2)) * rzcn;
    float const z2ucd = rzcn - z1ucd;
    auto const plus1 = [](float x) { return static_cast<float>(static_cast<double>(x) + 1.0); };
    auto const minus1 = [](float x) { return static_cast<float>(static_cast<double>(x) + -1.0); };
    // GEF.bas:16406-16416: energies at Z1UCD - 1, Z1UCD, Z1UCD + 1.
    float const re1 = scission_energy(minus1(z1ucd), ra1, beta1, plus1(z2ucd), ra2, beta2, d);
    float const re2 = scission_energy(z1ucd, ra1, beta1, z2ucd, ra2, beta2, d);
    float const re3 = scission_energy(plus1(z1ucd), ra1, beta1, minus1(z2ucd), ra2, beta2, d);
    // GEF.bas:16418-16420: parabola through the three energies.
    auto const eps2 = static_cast<float>(
        ((static_cast<double>(re1) - (static_cast<double>(re2) * 2.0)) + static_cast<double>(re3)) /
        2.0);
    auto const eps1 = static_cast<float>(static_cast<double>(re3 - re1) / 2.0);
    auto dz_pol =
        static_cast<float>(static_cast<double>(-eps1) / (static_cast<double>(eps2) * 2.0));
    // GEF.bas:16422
    if (dz_pol > 2.0F || dz_pol < -2.0F) {
        dz_pol = 0.0F;
    }
    // GEF.bas:16424
    return z1ucd + dz_pol;
}

// GEF.bas:16480-16646. B_analytical = 0 (GEF.bas:16487) is never changed, so only the numerical
// branch runs (the analytic branch GEF.bas:16631-16644 is not ported). Ubest starts at 0 (the
// Dim of GEF.bas:16496) and is not reset between the four slope probes; beta1 keeps
// beta1prev + eps from the first probe in the second (GEF.bas:16520-16558).
BetaEquiResult beta_equi(float a1, float a2, float z1, float z2, float d, float beta1prev,
                         float beta2prev, float beta1opt_in, float beta2opt_in) noexcept {
    BetaEquiResult out{.beta1opt = beta1opt_in, .beta2opt = beta2opt_in};
    constexpr float eps = 0x1.0624DEp-11F;     // GEF.bas:16506: 5.E-4 as a Single
    constexpr float u_start = 0x1.93E594p+99F; // 1.E30 as a Single
    float ubest = 0.0F;
    float sbeta1 = 0.0F;
    float sbeta2 = 0.0F;

    // GEF.bas:16514-16517
    float const uprev = scission_energy(z1, a1, beta1prev, z2, a2, beta2prev, d);
    float uopt = uprev;

    // One slope probe (GEF.bas:16523-16534 and the three copies): beta2 walks from beta2prev in
    // steps of `step` for Int(span / eps) steps while U does not rise; Ubest is the last U that
    // did not rise. `span` is beta2prev or 1 - beta2prev in Single.
    auto probe = [&](float beta1, float step, float span) {
        float u = u_start;
        float beta2 = beta2prev;
        // For I = 1 To Int(span / eps): the bound is floorf of the Single quotient, then CInt.
        std::int64_t const n_steps = fb::f2l(
            std::floor(static_cast<float>(static_cast<double>(span) / static_cast<double>(eps))));
        for (std::int64_t i = 1; i <= n_steps; ++i) {
            beta2 = beta2 + step;
            float const ulast = u;
            u = scission_energy(z1, a1, beta1, z2, a2, beta2, d);
            // If U > Ulast Then Exit For Else Ubest = U (compiled as `if (U <= Ulast)`).
            if (!(u <= ulast)) {
                break;
            }
            ubest = u;
        }
    };
    // If Ubest < Uopt Then ... (compiled as `if (Ubest >= Uopt) skip`).
    auto take = [&](float s1, float s2) {
        if (!(ubest >= uopt)) {
            uopt = ubest;
            sbeta1 = s1;
            sbeta2 = s2;
        }
    };

    // GEF.bas:16520-16539
    float beta1 = beta1prev + eps;
    probe(beta1, -eps, beta2prev);
    take(eps, -eps);
    // GEF.bas:16541-16558 (beta1 unchanged)
    probe(beta1, eps, 1.0F - beta2prev);
    take(eps, eps);
    // GEF.bas:16560-16578
    beta1 = beta1prev - eps;
    probe(beta1, -eps, beta2prev);
    take(-eps, -eps);
    // GEF.bas:16580-16597
    probe(beta1, eps, 1.0F - beta2prev);
    take(-eps, eps);

    // GEF.bas:16600-16601
    ubest = scission_energy(z1, a1, beta1prev, z2, a2, beta2prev, d);
    // GEF.bas:16602-16604 computes U at (beta1prev + sbeta1, beta2prev + sbeta2); the value is
    // overwritten in the first N1 iteration before any read, and LyMass/ECoul are pure, so it is
    // not evaluated here.

    // GEF.bas:16607-16626: For N = 1 To 1000 / For N1 = 1 To N; Exit For leaves N as it is,
    // a completed loop leaves N = 1001.
    std::int64_t nopt = 0;
    std::int64_t n = 1;
    for (; n <= 1000; ++n) {
        for (std::int64_t n1 = 1; n1 <= n; ++n1) {
            std::int64_t const n2 = n - n1;
            float const b1 = beta1prev + (sbeta1 * static_cast<float>(n1));
            float const b2 = beta2prev + (sbeta2 * static_cast<float>(n2));
            float const u = scission_energy(z1, a1, b1, z2, a2, b2, d);
            // If U < Ubest (compiled as `if (U >= Ubest) skip`).
            if (!(u >= ubest)) {
                ubest = u;
                out.beta1opt = b1;
                out.beta2opt = b2;
                nopt = n;
            }
        }
        // If N - Nopt > 2 Then Exit For
        if (!(n - nopt <= 2)) {
            break;
        }
    }
    // GEF.bas:16628: If N > 998 Then Print #f,"Beta_Equi not converged: ",Z1,N (plan D7: the
    // caller prints).
    out.print_not_converged = n > 998;
    out.n = n;
    return out;
}

} // namespace gef::physics
