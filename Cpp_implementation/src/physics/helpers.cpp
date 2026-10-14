// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "physics/helpers.hpp"

#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"

#include <cmath>
#include <cstdint>

namespace gef::physics {

// GEF.bas:17808-17816
float gaussintegral(float r_x, float r_sigma) noexcept {
    // GEF.bas:17814: the quotient in Double, narrowed for Erf; 0.5 + 0.5 * vr in Double.
    float const vr1 =
        fb::erf(static_cast<float>(static_cast<double>(r_x) / static_cast<double>(r_sigma)));
    return static_cast<float>((static_cast<double>(vr1) * 0.5) + 0.5);
}

// GEF.bas:17818-17828
float bell(float xpos, float xleft, float xright) noexcept {
    float y = 0.0F;
    // GEF.bas:17821: both differences in Single, compared in Double with 1.E-3.
    if (static_cast<double>(xpos - xleft) > 1.0E-3 && static_cast<double>(xright - xpos) > 1.0E-3) {
        // GEF.bas:17822
        auto const x = static_cast<float>(static_cast<double>(xpos - xleft) /
                                          static_cast<double>(xright - xleft));
        // GEF.bas:17823: x^2 as x * x in Single; (1-x)^2 through pow in Double.
        double const vr2 = std::pow(static_cast<double>(1.0F - x), 2.0);
        y = static_cast<float>((static_cast<double>(x * x) * vr2) / 0.0625);
    }
    // GEF.bas:17827
    return y;
}

// GEF.bas:17830-17837
float u_box(float x, float sigma, float length) noexcept {
    // GEF.bas:17835
    float const vr3 = gaussintegral(
        static_cast<float>(static_cast<double>(x) + (static_cast<double>(length) * 0.5)), sigma);
    float const vr4 = gaussintegral(
        static_cast<float>(static_cast<double>(x) - (static_cast<double>(length) * 0.5)), sigma);
    float const y = vr3 - vr4;
    // GEF.bas:17836
    return static_cast<float>(static_cast<double>(y) / static_cast<double>(length));
}

// GEF.bas:17593-17653
std::int64_t even_odd(float r_origin, float r_even_odd) noexcept {
    // GEF.bas:17631-17633 (R_EVEN_ODD is a ByVal copy)
    r_even_odd = fb::min(r_even_odd, 1.0F);
    auto const r_in = static_cast<float>(static_cast<double>(r_origin) + 0.5);
    float const r_floor = fb::floor(r_in);
    // GEF.bas:17634: Abs in Single, compared in Double with 1.E-3; compiled as
    // `if (... >= 1E-3) goto else-branch`, so a NaN R_EVEN_ODD takes this branch.
    if (!(static_cast<double>(std::fabs(r_even_odd)) >= 1.0E-3)) {
        // GEF.bas:17635
        return fb::f2l(r_floor);
    }
    // GEF.bas:17637-17638
    float const r_rest = r_in - r_floor;
    auto const r_middle = static_cast<float>(static_cast<double>(r_floor) + 0.5);
    float r_help = 0.0F;
    // GEF.bas:17639: CInt(R_FLOOR) Mod 2
    if (fb::imod(fb::f2l(r_floor), 2) == 0) {
        // GEF.bas:17640-17643: 0.01 is the Single 0x1.47AE14p-7f; (R_REST * 1.E0 - 0.5) in Double.
        float const vr3 = fb::max(0.01F, static_cast<float>(static_cast<double>(r_even_odd) + 1.0));
        r_help = static_cast<float>(
            static_cast<double>(r_middle) +
            (((static_cast<double>(r_rest) * 1.0) + -0.5) / static_cast<double>(vr3)));
        r_help = fb::min(r_help, r_middle + 1.0F);
        r_help = fb::max(r_help, r_middle + -1.0F);
    } else {
        // GEF.bas:17645-17648
        float const vr6 =
            fb::max(0.01F, static_cast<float>(-static_cast<double>(r_even_odd) + 1.0));
        r_help = static_cast<float>(
            static_cast<double>(r_middle) +
            (((static_cast<double>(r_rest) * 1.0) + -0.5) / static_cast<double>(vr6)));
        r_help = fb::min(r_help, r_middle + 1.0F);
        r_help = fb::max(r_help, r_middle + -1.0F);
    }
    // GEF.bas:17650
    return fb::f2l(fb::floor(r_help));
}

} // namespace gef::physics
