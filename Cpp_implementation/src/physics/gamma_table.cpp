// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"
#include "physics/gamma.hpp"
#include "physics/level_density.hpp"
#include "physics/rotation.hpp"

#include <cmath>
#include <cstddef>

namespace gef::physics {

// GEF.bas:16980-17037: the P_Egamma_low table builder; its locals are GEF.bas:16966-16976.
// Each expression keeps the association of the compiled code, which the arglog replays.
// Branch 1 (GEF.bas:17006-17007) divides the whole numerator. Branch 2 (GEF.bas:17028-17031)
// divides (G0 * Eg) by its denominator, then multiplies by exp(-Eg/Tm) * Eg^3. The sigMax test
// is `not (sigma <= sigMax)`, as compiled; the source's `sigma > sigMax` differs only for NaN.
PEgammaLowTable p_egamma_low_table(data::TableSet const& tables, float zi, float ai, float ei,
                                   float tscale, float econd, float etrans) {
    PEgammaLowTable out;

    // GEF.bas:16980-16982: N = Int(Ei*10 + 0.5); If N <= 0 Then N = 1; ReDim sigma(N), zeroed.
    // Ei*10 is Single; the +0.5 and Int are Double (floor, then fb_D2L).
    out.n = fb::d2l(std::floor(static_cast<double>(ei * 10.0F) + 0.5));
    if (out.n <= 0) {
        out.n = 1;
    }
    out.sigma.redim({fb::Bounds{0, out.n}});

    // GEF.bas:16985
    out.tm = u_temp(tables, zi, ai, ei, 1, 1, tscale, econd, etrans);

    // GEF.bas:16987: DEFOtab(Ai-Zi, Zi); the Single indices convert with CInt (round half to even).
    out.betadef = tables.defo_tab(fb::f2l(ai - zi), fb::f2l(zi));

    // GEF.bas:16988: -120 * betadef in Single, + 47.4 in Double, then Single.
    out.gammadef = static_cast<float>(static_cast<double>(out.betadef * -120.0F) + 47.4);

    // GEF.bas:16997: If betadef = 0 And gammadef = 0. Never true: gammadef is 0 only if
    // float(-120 * betadef) equals -47.4 as a Double, and no Single does.
    if (out.betadef == 0.0F && out.gammadef == 0.0F) {
        // GEF.bas:16998-16999
        out.e0.at(2) = e0_gdr(zi, ai);
        out.g0.at(2) = width_gdr(out.e0.at(2));
        // GEF.bas:17002
        out.sig_max = 0.0F;
        // GEF.bas:17003-17011: For Eg = 0.1 To Ei Step 0.1; Eg is Single and steps by Single 0.1.
        for (out.eg = 0.1F; out.eg <= ei; out.eg += 0.1F) {
            // GEF.bas:17004
            out.n = fb::f2l(out.eg * 10.0F);
            // GEF.bas:17006: Eg^3 and (Eg^2 - E0^2)^2 through pow in Double (exponents 3 and 2).
            double const vr52 = std::pow(static_cast<double>(out.eg), 3.0);
            double const vr60 = std::pow(static_cast<double>(out.eg * out.eg) -
                                             static_cast<double>(out.e0.at(2) * out.e0.at(2)),
                                         2.0);
            // exp(-Eg/Tm) is Single; numerator (exp*Eg^3)*(G0*Eg), denominator
            // (Eg^2-E0^2)^2 + G0^2*E0^2, in Double; the stored value is Single.
            auto const ex = static_cast<double>(std::exp(
                static_cast<float>(static_cast<double>(-out.eg) / static_cast<double>(out.tm))));
            double const num = (ex * vr52) * static_cast<double>(out.g0.at(2) * out.eg);
            double const den = vr60 + ((static_cast<double>(out.g0.at(2) * out.g0.at(2)) *
                                        static_cast<double>(out.e0.at(2))) *
                                       static_cast<double>(out.e0.at(2)));
            out.sigma(out.n) = static_cast<float>(num / den);
            // GEF.bas:17010
            if (!(out.sigma(out.n) <= out.sig_max)) {
                out.sig_max = out.sigma(out.n);
            }
        }
    } else {
        // GEF.bas:17018
        out.sig_max = 0.0F;
        // GEF.bas:17019-17036: For I = 1 To 3
        for (out.i = 1; out.i <= 3; ++out.i) {
            auto const k = static_cast<std::size_t>(out.i);
            // GEF.bas:17020-17021: E0(I) = E0_GDR(Zi,Ai) * Efac_def_GDR(betadef,gammadef,I); G0(I)
            float const gdr = e0_gdr(zi, ai);
            float const efac = efac_def_gdr(out.betadef, out.gammadef, static_cast<float>(out.i));
            out.e0.at(k) = gdr * efac;
            out.g0.at(k) = width_gdr(out.e0.at(k));
            // GEF.bas:17023-17035: For Eg = 0.1 To Ei Step 0.1 (restarted for each I)
            for (out.eg = 0.1F; out.eg <= ei; out.eg += 0.1F) {
                // GEF.bas:17024
                out.n = fb::f2l(out.eg * 10.0F);
                // GEF.bas:17028: the same pow exponents as the first branch.
                double const vr94 = std::pow(static_cast<double>(out.eg), 3.0);
                double const vr104 = std::pow(static_cast<double>(out.eg * out.eg) -
                                                  static_cast<double>(out.e0.at(k) * out.e0.at(k)),
                                              2.0);
                auto const ex = static_cast<double>(std::exp(static_cast<float>(
                    static_cast<double>(-out.eg) / static_cast<double>(out.tm))));
                // The quotient (G0*Eg)/(...) is formed first and then multiplied by exp*Eg^3
                // (GEF.c:15243); the first branch divides the whole product instead.
                double const quot = static_cast<double>(out.g0.at(k) * out.eg) /
                                    (vr104 + ((static_cast<double>(out.g0.at(k) * out.g0.at(k)) *
                                               static_cast<double>(out.e0.at(k))) *
                                              static_cast<double>(out.e0.at(k))));
                float& s = out.sigma(out.n);
                s = static_cast<float>(static_cast<double>(s) + ((ex * vr94) * quot));
                // GEF.bas:17034
                if (!(s <= out.sig_max)) {
                    out.sig_max = s;
                }
            }
        }
    }
    return out;
}

} // namespace gef::physics
