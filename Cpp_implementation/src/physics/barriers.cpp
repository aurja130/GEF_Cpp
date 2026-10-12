// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "physics/barriers.hpp"

#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "physics/masses.hpp"

#include <cmath>
#include <cstdint>

namespace gef::physics {

namespace {

// The four corrections of RB in cases 1, 2 and 3 (GEF.bas:17700-17705, 17712-17715, 17718-17721).
// Each `If` is emitted as a skip (`if (cond) goto skip`): the body runs when the condition is
// false, so a NaN RZ takes every body. The first test is in Double, the others in Single.
float corrected_rb(float rz, float rb) noexcept {
    float corrected = rb;
    if (!(static_cast<double>(rz) <= 0x1.5Ap+6)) {
        corrected = static_cast<float>(
            static_cast<double>(corrected) -
            ((static_cast<double>(rz) * 0x1.3333333333333p-3) + -0x1.9F33333333333p+3));
    }
    if (!(rz <= 0x1.68p+6F)) {
        corrected = static_cast<float>(
            (static_cast<double>(corrected) + (static_cast<double>(rz) * 0x1.6666666666666p-2)) +
            -0x1.F7FFFFFFFFFFFp+4);
    }
    if (!(rz <= 0x1.74p+6F)) {
        corrected = static_cast<float>(
            (static_cast<double>(corrected) + (static_cast<double>(rz) * 0x1.3333333333333p-3)) +
            -0x1.BE66666666666p+3);
    }
    if (!(rz <= 0x1.7Cp+6F)) {
        corrected = static_cast<float>(static_cast<double>(corrected) -
                                       ((static_cast<double>(rz) * 0x1.p-2) + -0x1.7Cp+4));
    }
    return corrected;
}

// DB of BFTFA and BFTFB (GEF.bas:17765-17766 and 17788-17789), the Dahlinger fit whose comment
// reads EB - EA. The cube goes through pow in Double; Z3A * Z3A is a Single product.
float dahlinger_db(float rz, float ra) noexcept {
    // GEF.bas:17765: Z3A = RZ^3 / RA; the quotient in Double, narrowed to Single.
    auto const z3a =
        static_cast<float>(std::pow(static_cast<double>(rz), 0x1.8p+1) / static_cast<double>(ra));
    // GEF.bas:17766: DB = -(5.40101 - 0.00666175 Z3A + 1.52531E-6 Z3A^2), in Double.
    double const poly = (-(static_cast<double>(z3a) * 0x1.B4959E6256367p-8) +
                         (static_cast<double>(z3a * z3a) * 0x1.9972814B9FDEBp-20)) +
                        0x1.59AA25D8D79D1p+2;
    return static_cast<float>(-poly);
}

} // namespace

// GEF.bas:17657-17750. The emitted C runs the Select Case with no fall-through; the message of
// the Case Else is reported through print_undefined_option, and the value stays 0.
BftfResult bftf(data::TableSet const& tables, float rz, float ra, std::int64_t i_switch) {
    // GEF.bas:17663-17664: RX0 and RX1 are Single constants.
    constexpr float rx0 = 0x1.8457A8p+5F;
    constexpr float rx1 = 0x1.113334p+5F;
    // GEF.bas:17672-17673: CInt rounds to nearest, ties to even (fb_F2L).
    std::int64_t const iz = fb::f2l(rz);
    std::int64_t const ia = fb::f2l(ra);

    // GEF.bas:17674
    float const rn = ra - rz;
    // GEF.bas:17675: RN - RZ in Single; the quotient by RA in Double.
    auto const ri = static_cast<float>(static_cast<double>(rn - rz) / static_cast<double>(ra));
    // GEF.bas:17676: Rkappa = 1.9 + (RZ - 80) / 75 in Double.
    auto const rkappa = static_cast<float>(((static_cast<double>(rz) + -0x1.4p+6) / 0x1.2Cp+6) +
                                           0x1.E666666666666p+0);
    // GEF.bas:17677: RS = RA^0.666667 * (1 - Rkappa * RI^2); the factor is in Double.
    double const ra_pow = std::pow(static_cast<double>(ra), 0x1.55556084A515Dp-1);
    double const kappa_ri2 =
        (static_cast<double>(rkappa) * static_cast<double>(ri)) * static_cast<double>(ri);
    double const factor = -kappa_ri2 + 0x1.p+0;
    auto const rs = static_cast<float>(ra_pow * factor);
    // GEF.bas:17678: RX = RZ^2 / (RA * factor); RZ * RZ is a Single product.
    auto const rx =
        static_cast<float>(static_cast<double>(rz * rz) / (static_cast<double>(ra) * factor));

    // GEF.bas:17679-17690: the four range tests on RX, each emitted as a skip (see
    // corrected_rb). RX = 30 exactly satisfies none of them, so RF stays 0 (quirk Q-037).
    float rf = 0.0F;
    if (!(rx >= 0x1.Ep+4F)) {
        rf = 0x1.2A05F2p+33F; // 1E10
    }
    if (!(rx <= rx0)) {
        rf = 0.0F;
    }
    if (rx < rx1 && rx > 0x1.Ep+4F) {
        rf = static_cast<float>(-(static_cast<double>(rx - rx1) * 0x1.FC7607C4199FEp-4) +
                                0x1.30EC52A411C2Ap-1);
    }
    if (rx >= rx1 && rx <= rx0) {
        double const cube = std::pow(static_cast<double>(rx0 - rx), 0x1.8p+1);
        rf = static_cast<float>(cube * 0x1.A2E76D845F422p-13);
    }
    // GEF.bas:17691
    float rb = rf * rs;

    BftfResult result;
    switch (i_switch) {
    case 0: // GEF.bas:17694-17695: no shell, no pairing
        result.value = rb;
        break;
    case 1: { // GEF.bas:17696-17708: shell and even-odd staggering, with the pairing gap
        float const corrected = corrected_rb(rz, rb);
        float const vr3 = u_shell_eo_exp(tables, iz, ia);
        float const vr4 = ly_pair(iz, ia);
        result.value = static_cast<float>(static_cast<double>(corrected - vr3) +
                                          ((static_cast<double>(vr4) * 0x1.Cp+3) / 0x1.8p+3));
        break;
    }
    case 2: { // GEF.bas:17711-17716: averaged over the even-odd staggering
        float const corrected = corrected_rb(rz, rb);
        float const vr5 = u_shell_exp(tables, iz, ia);
        result.value = corrected - vr5;
        break;
    }
    case 3: { // GEF.bas:17717-17722: as case 1, without the pairing gap at the barrier
        float const corrected = corrected_rb(rz, rb);
        float const vr6 = u_shell_eo_exp(tables, iz, ia);
        result.value = corrected - vr6;
        break;
    }
    case 4: { // GEF.bas:17723-17725: shell only, no Z correction
        float const vr7 = u_shell_exp(tables, iz, ia);
        result.value = rb - vr7;
        break;
    }
    case 5: { // GEF.bas:17726-17727: shell and enhanced pairing, no Z correction
        float const vr8 = u_shell_exp(tables, iz, ia);
        float const vr9 = ly_pair(iz, ia);
        result.value = static_cast<float>(static_cast<double>(rb - vr8) +
                                          ((static_cast<double>(vr9) * 0x1.p+1) / 0x1.8p+3));
        break;
    }
    case 6: { // GEF.bas:17728-17729: macroscopic with enhanced pairing, not below 0
        float const vr10 = ly_pair(iz, ia);
        result.value =
            fb::max(static_cast<float>(static_cast<double>(rb) +
                                       ((static_cast<double>(vr10) * 0x1.p+1) / 0x1.8p+3)),
                    0.0F);
        break;
    }
    default: // GEF.bas:17730-17731: the message is printed by the caller; the value stays 0
        result.print_undefined_option = true;
        break;
    }
    return result;
}

// GEF.bas:17752-17773
BftfResult bftfa(data::TableSet const& tables, float rz, float ra, std::int64_t i_switch) {
    // GEF.bas:17757
    BftfResult const inner = bftf(tables, rz, ra, i_switch);
    float const bf0 = inner.value;
    float const db = dahlinger_db(rz, ra);
    // GEF.bas:17767-17771: EA = BF0 - DB where DB > 0, else BF0; emitted as a DB <= 0 test.
    float const ea = static_cast<double>(db) <= 0.0 ? bf0 : bf0 - db;

    BftfResult result;
    result.value = ea;
    result.print_undefined_option = inner.print_undefined_option;
    return result;
}

// GEF.bas:17775-17796
BftfResult bftfb(data::TableSet const& tables, float rz, float ra, std::int64_t i_switch) {
    // GEF.bas:17780
    BftfResult const inner = bftf(tables, rz, ra, i_switch);
    float const bf0 = inner.value;
    float const db = dahlinger_db(rz, ra);
    // GEF.bas:17790-17794: EB = BF0 + DB where DB < 0, else BF0; emitted as a DB >= 0 test.
    float const eb = static_cast<double>(db) >= 0.0 ? bf0 : bf0 + db;

    BftfResult result;
    result.value = eb;
    result.print_undefined_option = inner.print_undefined_option;
    return result;
}

} // namespace gef::physics
