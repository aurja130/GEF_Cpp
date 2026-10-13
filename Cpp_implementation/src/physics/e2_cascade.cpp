// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The E2 rotational cascade of one fragment. Ported from the C fbc 1.10.1 emits for the light
// copy (GEF.bas:9309-9368); the heavy copy (GEF.bas:9430-9484) compiles to the same statements
// with the heavy variables (checked by normalising the emitted C of both ranges; the only
// difference is the Dim of E_E2_tot at GEF.bas:9310, which the heavy copy reuses).

#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "fbrt/strings.hpp"
#include "fbrt/text.hpp"
#include "physics/gamma.hpp"
#include "physics/rotation.hpp"

#include <cmath>
#include <cstdint>
#include <stdexcept>

namespace gef::physics {

E2Cascade e2_cascade(data::TableSet const& tables, std::int64_t i_z_sci, std::int64_t i_a_post,
                     float jfrag, float j_frag, float spin_gs, std::int64_t n_iso,
                     std::int64_t i_iso) {
    E2Cascade out;
    // GEF.bas:9312-9315: moment of inertia with the deformation factor of Hasse & Myers.
    out.ifrag_eff = u_iredff(static_cast<float>(i_z_sci), static_cast<float>(i_a_post));
    out.beta1 = tables.defo_tab(i_a_post - i_z_sci, i_z_sci);
    // alph = beta1 / Sqr(4 pi / 5), the divisor folded to the Double 0x1.95D834874E488p+0.
    out.alph = static_cast<float>(static_cast<double>(out.beta1) / 0x1.95D834874E488p+0);
    out.ifrag_eff =
        static_cast<float>(static_cast<double>(out.ifrag_eff) *
                           (((static_cast<double>(out.alph) * 0.5) +
                             (static_cast<double>(out.alph * out.alph) * 0x1.4924924924925p+0)) +
                            1.0));
    // GEF.bas:9322
    out.c_iso_lmd = "GS";

    // GEF.bas:9323-9368: For J = Jfrag To 2 Step -2 in Single. `Exit For, For` (9332, 9339) leaves
    // the J loop as well: the J of the stop emits no gamma.
    // The loop runs on a Single counter, as compiled (`J = J + -2; if (J >= 2) goto body`).
    float j = jfrag;
    while (j >= 2.0F) {
        // GEF.bas:9325: If N_iso > 0 And I_DelGam = 0. I_DelGam is 0 (GEF.bas:876, never
        // assigned), so only N_iso decides.
        if (n_iso > 0) {
            data::IsoProp const& iso = tables.isotab(i_iso);
            // GEF.bas:9329: For K = 1 To Isotab(I_iso).N_STATES, K Single, the bound converted to
            // Single once.
            auto const k_last = static_cast<float>(iso.n_states);
            bool stop = false;
            float k = 1.0F;
            while (k <= k_last) {
                float const spin = iso.r_spi(fb::f2l(k));
                // GEF.bas:9330-9333: at the first J, a state with spin CInt(J_frag) stops the
                // cascade (ground-state stop).
                // QUIRK(Q-038): the comparison is with CInt(J_frag), not CInt(J_frag + Spin_gs).
                if (j == jfrag && spin == static_cast<float>(fb::f2l(j_frag))) {
                    stop = true;
                    break;
                }
                // GEF.bas:9335-9341: a state between J + spin_gs and Jfrag + spin_gs (0.01
                // tolerance, compared in Double) is the isomer the cascade stops at.
                if (!(static_cast<double>(spin) >
                      (static_cast<double>(jfrag + spin_gs) + 0x1.47AE147AE147Bp-7)) &&
                    !(static_cast<double>(spin) <
                      (static_cast<double>(j + spin_gs) + -0x1.47AE147AE147Bp-7))) {
                    // GEF.bas:9337-9338: "M(" + Trim(Str(R_SPI)) + "/" + Trim(Str(R_EXC)) + ")"
                    std::string const exc = fb::trim(fb::str(iso.r_exc(fb::f2l(k))));
                    std::string const spi = fb::trim(fb::str(spin));
                    out.c_iso_lmd = "M(";
                    out.c_iso_lmd.append(spi).append("/").append(exc).append(")");
                    stop = true;
                    break;
                }
                k = k + 1.0F;
            }
            if (stop) {
                break;
            }
        }
        // GEF.bas:9346: shell effect, rotation to vibration: 2 + (J - 2) * U_I_Shell^2.
        float const vr12 = u_i_shell(static_cast<float>(i_z_sci), static_cast<float>(i_a_post));
        double const vr13 = std::pow(static_cast<double>(vr12), 2.0);
        auto rjeff = static_cast<float>((static_cast<double>(j + -2.0F) * vr13) + 2.0);
        // GEF.bas:9348: pairing, irrotational flow to rigid body.
        float const vr14 =
            fb::max(static_cast<float>((-static_cast<double>(rjeff) + 12.0) / 12.0), 0.0F);
        rjeff = static_cast<float>(
            (static_cast<double>(rjeff) * 0x1.CCCCCCCCCCCCDp-2) +
            ((static_cast<double>(rjeff) * static_cast<double>(vr14)) * 0x1.4CCCCCCCCCCCDp-1));
        // GEF.bas:9349: Eg = RJeff(RJeff+1)/(2 I) - (RJeff-2)(RJeff-1)/(2 I), each quotient a
        // Single.
        float const two_i = out.ifrag_eff * 2.0F;
        float const eg = static_cast<float>(static_cast<double>(rjeff * (rjeff + 1.0F)) /
                                            static_cast<double>(two_i)) -
                         static_cast<float>(static_cast<double>((rjeff + -2.0F) * (rjeff + -1.0F)) /
                                            static_cast<double>(two_i));
        // GEF.bas:9350
        out.e_e2_tot = out.e_e2_tot + eg;
        // GEF.bas:9352-9353: Array_Eg2_<side>(Ig2) is ReDim (100) (GEF.bas:1342); BASIC does not
        // check the index. Not reached in the M5 captures (-exx runs, MILESTONE_5_PLAN.md M5.2).
        // QUIRK(Q-039): Array_Eg2_<side>(100) has no bound check in BASIC.
        if (out.gammas.size() >= 100) {
            throw std::out_of_range("Array_Eg2 index above 100 (GEF.bas:9353, 9469)");
        }
        out.gammas.push_back(eg);
        j = j + -2.0F;
    }
    return out;
}

} // namespace gef::physics
