// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "physics/masses.hpp"

#include "fbrt/convert.hpp"

#include <cmath>
#include <cstdint>

namespace gef::physics {

// Each function follows the C that fbc generates for GEF.bas (the statement lines are cited per
// group): Single stays float, every Double step is an explicit cast, pow and sqrt are the libm
// calls fbc emits, and Integer arithmetic that can overflow goes through fb::add/sub.

// GEF.bas:16110-16137. BASIC's `N = A - Z` is dead code and is not ported.
float ly_mass(float z, float a, float beta) noexcept {
    // GEF.bas:16126: sqr(5/(4 pi)) * beta, the constant folded by fbc
    auto const alpha = static_cast<float>(static_cast<double>(beta) * 0x1.42F60A3305EC5p-1);
    // GEF.bas:16127
    double const vr1 = std::pow(
        (static_cast<double>(a) - (static_cast<double>(z) * 2.0)) / static_cast<double>(a), 2.0);
    auto const xcom = static_cast<float>(-(vr1 * 0x1.C858793DD97F6p+0) + 1.0);
    // GEF.bas:16129-16130
    double const vr2 = std::pow(static_cast<double>(a), 0x1.5555555555555p-1);
    auto const xvs = static_cast<float>(
        static_cast<double>(-xcom) *
        ((static_cast<double>(a) * 0x1.EFCFAACD9E83Ep+3) -
         ((vr2 * ((static_cast<double>(alpha * alpha) * 0x1.999999999999Ap-2) + 1.0)) *
          0x1.1F1A36E2EB1C4p+4)));
    // GEF.bas:16132-16133
    double const vr3 = std::pow(static_cast<double>(a), 0x1.5555555555555p-2);
    auto const xe =
        static_cast<float>(static_cast<double>(z * z) *
                           (((0x1.691D14E3BCD36p-1 / vr3) *
                             (-(static_cast<double>(alpha * alpha) * 0x1.999999999999Ap-3) + 1.0)) -
                            (0x1.272474538EF35p+0 / static_cast<double>(a))));
    // GEF.bas:16134, 16136
    float const el = xvs + xe;
    return el;
}

// GEF.bas:16140-16151. (Z + 1) Mod 2 + (A - Z + 1) Mod 2 with the truncating Mod.
float ly_pair(std::int64_t z, std::int64_t a) noexcept {
    // GEF.bas:16147
    std::int64_t const parity = fb::imod(fb::add(z, std::int64_t{1}), 2) +
                                fb::imod(fb::add(fb::sub(a, z), std::int64_t{1}), 2);
    auto const e_pair =
        static_cast<float>((-0x1.8p+3 / static_cast<double>(std::sqrt(static_cast<float>(a)))) *
                           static_cast<double>(static_cast<float>(parity)));
    // GEF.bas:16150-16151
    return e_pair;
}

// GEF.bas:16211-16214
float fedefo_lys(float z, float a, float beta) noexcept {
    // GEF.bas:16213
    float const vr1 = ly_mass(z, a, beta);
    float const vr2 = ly_mass(z, a, 0.0F);
    return vr1 - vr2;
}

// GEF.bas:16217-16236
float ld_mass(data::TableSet const& tables, float z, float a, float beta) {
    // GEF.bas:16223
    float const n = a - z;
    float betab = 0.0F;
    // GEF.bas:16224: the generated test is `BEexp <= -1.E10`, so a NaN table entry takes the
    // table branch (BASIC's `>` test would take the LyMass branch)
    if (static_cast<double>(tables.be_exp(fb::f2l(n), fb::f2l(z))) <= -0x1.2A05F2p+33) {
        // GEF.bas:16232
        betab = ly_mass(z, a, beta);
    } else {
        // GEF.bas:16227: BEtab = BEldmTF(CInt(N), CInt(Z))
        betab = tables.beldm_tf(fb::f2l(n), fb::f2l(z));
        // GEF.bas:16230
        float const vr19 = fedefo_lys(z, a, beta);
        betab = betab + vr19;
    }
    // GEF.bas:16234: Betab + 2.0 * 12.0 / sqr(A) - 0.00001433 * Z^2.39
    double const vr28 = std::pow(static_cast<double>(z), 0x1.31EB851EB851Fp+1);
    betab = static_cast<float>(
        (static_cast<double>(betab) + (0x1.8p+4 / static_cast<double>(std::sqrt(a)))) -
        (vr28 * 0x1.E0D5C3408703Cp-17));
    // GEF.bas:16235
    return betab;
}

// GEF.bas:16238-16259
float ame2020(data::TableSet const& tables, std::int64_t iz, std::int64_t ia) {
    // GEF.bas:16249, 16253
    std::int64_t const ineu = fb::sub(ia, iz);
    float const beexpval = tables.be_exp(ineu, iz);
    // GEF.bas:16254: `<= -1.E10` as in the generated C (a NaN entry is returned unchanged)
    if (static_cast<double>(beexpval) <= -0x1.2A05F2p+33) {
        // GEF.bas:16250-16252, 16257
        auto const z = static_cast<float>(iz);
        auto const a = static_cast<float>(ia);
        float const vr16 = ld_mass(tables, z, a, 0.0F);
        float const vr17 = u_shell(tables, iz, ia);
        float const vr19 = ly_pair(iz, ia);
        return (vr16 + vr17) + vr19;
    }
    // GEF.bas:16255
    return beexpval;
}

// GEF.bas:16261-16271
float u_shell(data::TableSet const& tables, std::int64_t z, std::int64_t a) {
    // GEF.bas:16265-16266
    std::int64_t const n = fb::sub(a, z);
    float res = tables.shell_mo(n, z);
    // GEF.bas:16267: Res = 0.3 * Res for Res > 0. The generated test is `Res <= 0`, so a NaN
    // Res is scaled as well.
    if (!(static_cast<double>(res) <= 0.0)) {
        res = static_cast<float>(static_cast<double>(res) * 0x1.3333333333333p-2);
    }
    // GEF.bas:16270
    return res;
}

// GEF.bas:16273-16292
float u_shell_exp(data::TableSet const& tables, std::int64_t iz, std::int64_t ia) {
    // GEF.bas:16279-16280
    auto const z = static_cast<float>(iz);
    auto const a = static_cast<float>(ia);
    // GEF.bas:16286: the five terms in BASIC order, each (AME2020 - Lypair) - LDMass in Single
    float const vr6 = ame2020(tables, iz, ia);
    float const vr7 = ly_pair(iz, ia);
    float const vr9 = ld_mass(tables, z, a, 0.0F);
    float const vr14 = ame2020(tables, iz, fb::sub(ia, std::int64_t{1}));
    float const vr16 = ly_pair(iz, fb::sub(ia, std::int64_t{1}));
    float const vr21 = ld_mass(tables, z, static_cast<float>(static_cast<double>(a) + -1.0), 0.0F);
    float const vr27 = ame2020(tables, iz, fb::add(ia, std::int64_t{1}));
    float const vr29 = ly_pair(iz, fb::add(ia, std::int64_t{1}));
    float const vr34 = ld_mass(tables, z, static_cast<float>(static_cast<double>(a) + 1.0), 0.0F);
    float const vr41 = ame2020(tables, fb::add(iz, std::int64_t{1}), fb::add(ia, std::int64_t{1}));
    float const vr44 = ly_pair(fb::add(iz, std::int64_t{1}), fb::add(ia, std::int64_t{1}));
    float const vr52 = ld_mass(tables, static_cast<float>(static_cast<double>(z) + 1.0),
                               static_cast<float>(static_cast<double>(a) + 1.0), 0.0F);
    float const vr59 = ame2020(tables, fb::sub(iz, std::int64_t{1}), fb::sub(ia, std::int64_t{1}));
    float const vr62 = ly_pair(fb::sub(iz, std::int64_t{1}), fb::sub(ia, std::int64_t{1}));
    float const vr70 = ld_mass(tables, static_cast<float>(static_cast<double>(z) + -1.0),
                               static_cast<float>(static_cast<double>(a) + -1.0), 0.0F);
    // The weighted sum, left to right as the generated C adds the Double terms
    double const t1 = static_cast<double>((vr6 - vr7) - vr9) * 0x1.p-1;
    double const t2 = static_cast<double>((vr14 - vr16) - vr21) * 0x1.p-3;
    double const t3 = static_cast<double>((vr27 - vr29) - vr34) * 0x1.p-3;
    double const t4 = static_cast<double>((vr41 - vr44) - vr52) * 0x1.p-3;
    double const t5 = static_cast<double>((vr59 - vr62) - vr70) * 0x1.p-3;
    auto const res = static_cast<float>((((t1 + t2) + t3) + t4) + t5);
    // GEF.bas:16291
    return res;
}

// GEF.bas:16294-16306
float u_shell_eo_exp(data::TableSet const& tables, std::int64_t iz, std::int64_t ia) {
    // GEF.bas:16302-16303
    auto const z = static_cast<float>(iz);
    auto const a = static_cast<float>(ia);
    // GEF.bas:16304-16305
    float const vr1 = ame2020(tables, iz, ia);
    float const vr2 = ld_mass(tables, z, a, 0.0F);
    float const res = vr1 - vr2;
    return res;
}

// GEF.bas:16310-16323
UMassResult u_mass(data::TableSet const& tables, float z, float a) {
    UMassResult result;
    // GEF.bas:16315-16316: the caller prints `U_Mass: Z, A` when this is set
    result.print_negative_input = (z < 0.0F) || (a < 0.0F);
    // GEF.bas:16318
    float const vr6 = ld_mass(tables, z, a, 0.0F);
    float const vr9 = u_shell(tables, fb::f2l(z), fb::f2l(a));
    result.value = vr6 + vr9;
    // GEF.bas:16322
    return result;
}

// GEF.bas:16326-16355
float ecoul(float z1, float a1, float beta1, float z2, float a2, float beta2, float d) noexcept {
    // GEF.bas:16345
    float const r0 = 0x1.28F5C2p+0F;
    // GEF.bas:16347-16348
    float const n1 = a1 - z1;
    float const n2 = a2 - z2;
    // GEF.bas:16349
    double const vr10 = std::pow(static_cast<double>(z1 + n1), 0x1.55555318ABC87p-2);
    double const vr17 = std::pow(static_cast<double>(z2 + n2), 0x1.55555318ABC87p-2);
    auto const dtot = static_cast<float>(
        (static_cast<double>(r0) *
         ((vr10 * ((static_cast<double>(beta1) * 0x1.55555673AA1BCp-1) + 1.0)) +
          (vr17 * ((static_cast<double>(beta2) * 0x1.55555673AA1BCp-1) + 1.0)))) +
        static_cast<double>(d));
    // GEF.bas:16352-16354
    auto const recoul = static_cast<float>((static_cast<double>(z1 * z2) * 0x1.70A3D70A3D70Ap+0) /
                                           static_cast<double>(dtot));
    return recoul;
}

// DCLbranchingJEFF33.bas:112-115
float u_q_beta_minus(data::TableSet const& tables, std::int64_t iz, std::int64_t ia) {
    // DCLbranchingJEFF33.bas:113
    float const vr1 = ame2020(tables, fb::add(iz, std::int64_t{1}), ia);
    float const vr2 = ame2020(tables, iz, ia);
    return -(vr1 - vr2);
}

// GEF.bas:15814-15832
std::uint8_t u_valid(data::TableSet const& tables, std::int64_t i_z, std::int64_t i_a) {
    // GEF.bas:15817
    std::uint8_t ivalid = 1;
    // GEF.bas:15818-15821. A NaN ratio (I_Z = I_A = 0) fails both comparisons and stays valid.
    double const ratio = static_cast<double>(i_a) / static_cast<double>(i_z);
    if (ratio < 0x1.0D79435E50D79p+1 || ratio > 0x1.9B05B05B05B06p+1) {
        ivalid = 0;
    }
    // GEF.bas:15823-15824
    if (i_z < 76 || i_z > 120) {
        ivalid = 0;
    }
    // GEF.bas:15826-15828: `AME2020(I_Z,I_A-1) - AME2020(I_Z,I_A) < 0` invalidates; the generated
    // test is `>= 0`, so a NaN difference invalidates as well
    float const vr15 = ame2020(tables, i_z, fb::sub(i_a, std::int64_t{1}));
    float const vr16 = ame2020(tables, i_z, i_a);
    if (!(static_cast<double>(vr15 - vr16) >= 0.0)) {
        ivalid = 0;
    }
    // GEF.bas:15830
    return ivalid;
}

// GEF.bas:15836-15859. The BASIC body below `Delta = 0` is commented out, so the result is 0.
float u_delta_s0(std::int64_t /*i_z*/, std::int64_t /*i_a*/) noexcept {
    // GEF.bas:15838, 15858
    return 0.0F;
}

} // namespace gef::physics
