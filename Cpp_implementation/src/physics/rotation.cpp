// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "physics/rotation.hpp"

#include "fbrt/gef_math.hpp"

#include <array>
#include <cmath>
#include <cstddef>

namespace gef::physics {

namespace {

// fbc folds `0.666667 * pi` and `sqr(5/(4*pi))` into the emitted C (GEF.c:16718), with pi the
// Single 3.14159 (GEF.bas:760). Hex, because std::sqrt is not constexpr.
constexpr double c_gamma = 0x1.0C151E1E2BCF9p+1; // 0.666667 * (double)3.14159F
constexpr double c_beta = 0x1.42F60A3305EC5p-1;  // sqrt(5.0 / (4.0 * (double)3.14159F))

// GEF.bas:16914 (GEF.c:14678): static Single, never reassigned.
constexpr float e2_coulomb = 0x1.70A3D8p+0F; // 1.44 (Single)

// State carried across the three time segments of u_accel (GEF.c:14698-14731).
struct AccelState {
    float ared;
    float ez; // E2*Z1*Z2 in Single (GEF.c:14756)
    float e0;
    float d0;
    float tn;
    float d;
    float v;
};

// One `For t = start To end Step dt` loop of u_accel.
struct Segment {
    float start;
    float dt;
    float end;
};

// GEF.bas:16935-16955 (GEF.c:14768-14942): three loops, in this order.
constexpr std::array<Segment, 3> accel_segments{{
    {.start = 0.0F, .dt = 0x1.47AE14p-7F, .end = 1.0F},            // GEF.bas:16935-16936 (dt 0.01)
    {.start = 0x1.19999Ap+0F, .dt = 0x1.99999Ap-4F, .end = 10.0F}, // GEF.bas:16942-16943 (1.1)
    {.start = 11.0F, .dt = 1.0F, .end = 100.0F},                   // GEF.bas:16949-16950
}};

// One loop of u_accel. Returns true when the BASIC `Goto match` fires (t >= Tn), leaving s.v as
// the value reached so far.
bool accel_segment(AccelState& s, Segment const& seg) noexcept {
    // The loop runs on a Single counter, as compiled.
    float t = seg.start;
    while (t <= seg.end) {
        // GEF.bas:16937 `if t >= Tn Then Goto match`, emitted as !(t < Tn) (GEF.c:14788), so a
        // NaN Tn takes the match branch.
        if (!(t < s.tn)) {
            return true;
        }
        // GEF.bas:16938 (GEF.c:14797): E = E0 + e2*Z1*Z2*(1/d0 - 1/d), Double arithmetic.
        auto const e =
            static_cast<float>(static_cast<double>(s.e0) +
                               (static_cast<double>(s.ez) * ((1.0 / static_cast<double>(s.d0)) -
                                                             (1.0 / static_cast<double>(s.d)))));
        // GEF.bas:16939 (GEF.c:14800): v = sqr(E/Ared)
        s.v = std::sqrt(static_cast<float>(static_cast<double>(e) / static_cast<double>(s.ared)));
        // GEF.bas:16940 (GEF.c:14803): d = d + v*14*dt
        s.d = s.d + ((s.v * seg.dt) * 14.0F);
        t = t + seg.dt;
    }
    return false;
}

} // namespace

// GEF.bas:16907-16959 (GEF.c:14667-14957): fragment acceleration.
float u_accel(float a1, float z1, float a2, float z2, float tke, float e0, float tn) noexcept {
    // GEF.bas:16923 (GEF.c:14734): the product A1*A2 is Single; the quotient is Double.
    auto const ared =
        static_cast<float>(static_cast<double>(a1 * a2) / static_cast<double>(a1 + a2));
    // GEF.bas:16924 (GEF.c:14737): vinf = sqr(TKE/Ared)
    float const vinf =
        std::sqrt(static_cast<float>(static_cast<double>(tke) / static_cast<double>(ared)));
    float v = 0.0F;
    // GEF.bas:16925 `If t > 100 or TKE < E0 Then` (GEF.c:14740). T is zero here (memset at
    // GEF.c:14706, first assigned at 14772), so `t > 100` is never true and only TKE < E0 remains.
    if (tke < e0) {
        v = vinf; // GEF.bas:16926
    } else {
        // GEF.bas:16930 (GEF.c:14756): d0 = e2*Z1*Z2/(TKE-E0), Single products, Double quotient.
        float const ez = (e2_coulomb * z1) * z2;
        auto const d0 = static_cast<float>(static_cast<double>(ez) / static_cast<double>(tke - e0));
        // GEF.bas:16933-16934: d = d0, v = 0
        AccelState s{.ared = ared, .ez = ez, .e0 = e0, .d0 = d0, .tn = tn, .d = d0, .v = 0.0F};
        for (Segment const& seg : accel_segments) {
            if (accel_segment(s, seg)) {
                break;
            }
        }
        v = s.v;
    }
    // GEF.bas:16957-16958 (GEF.c:14948): v1 = v*A2/(A1+A2), u_accel = v1
    return static_cast<float>(static_cast<double>(v * a2) / static_cast<double>(a1 + a2));
}

// GEF.bas:17120-17170 (GEF.c:15554-15774): U_I_shell, the shell-correction factor.
float u_i_shell(float z, float a) noexcept {
    // GEF.bas:17121, 17129-17134 (GEF.c:15628-15643): N_shells(1..6), zero-based here.
    constexpr std::array<float, 6> n_shells{20.0F, 28.0F, 50.0F, 82.0F, 126.0F, 56.0F};
    // GEF.bas:17135-17136 (GEF.c:15646-15649). dNsubmin = 100 (GEF.bas:17137, GEF.c:15650) is
    // overwritten at GEF.bas:17146 before any read and is not reproduced.
    float dnmin = 100.0F;
    float dzmin = 100.0F;
    // GEF.bas:17138-17141 (GEF.c:15655-15676): dZmin = Min(dZmin, Abs(N_shells(I) - Z)), I = 1..5
    for (std::size_t i = 0; i < 5; ++i) {
        dzmin = fb::min(dzmin, std::fabs(n_shells.at(i) - z));
    }
    // GEF.bas:17142-17145 (GEF.c:15680-15701): dNmin = Min(dNmin, Abs(N_shells(I) - (A-Z))),
    // emitted as (N - A) + Z in Single (GEF.c:15687).
    for (std::size_t i = 0; i < 5; ++i) {
        dnmin = fb::min(dnmin, std::fabs((n_shells.at(i) - a) + z));
    }
    // GEF.bas:17146 (GEF.c:15705): dNsubmin = Abs(N_shells(6) - (A-Z))
    float const dnsubmin = std::fabs((n_shells.at(5) - a) + z);
    // GEF.c:15714: sqr(A/140.0) in Double
    double const sa = std::sqrt(static_cast<double>(a) / 140.0);
    // GEF.bas:17126-17128 (GEF.c:15613-15625)
    float i_z = 0.0F;
    float i_n = 0.0F;
    float i_nsub = 0.0F;
    // GEF.bas:17149 `If dZmin < 10.0` (GEF.c:15708). `!(x >= c)` also takes the branch for NaN.
    if (!(static_cast<double>(dzmin) >= 10.0)) {
        // GEF.bas:17151 (GEF.c:15712-15714): 0.33*(6.0*sqr(A/140)-dZmin)*(140/A)^1.5
        double const vr34 = std::pow(140.0 / static_cast<double>(a), 1.5);
        i_z = static_cast<float>((((sa * 6.0) - static_cast<double>(dzmin)) * vr34) *
                                 0x1.51EB851EB851Fp-2); // 0.33
        // GEF.bas:17155 (GEF.c:15717-15719)
        i_z = fb::max(i_z, 0.0F);
    }
    // GEF.bas:17157 `If dNmin < 10.0` (GEF.c:15728)
    if (!(static_cast<double>(dnmin) >= 10.0)) {
        // GEF.bas:17159 (GEF.c:15732-15734): 0.42*(8.0*sqr(A/140)-dNmin)*(140/A)^1.5
        double const vr48 = std::pow(140.0 / static_cast<double>(a), 1.5);
        i_n = static_cast<float>((((sa * 8.0) - static_cast<double>(dnmin)) * vr48) *
                                 0x1.AE147AE147AE1p-2); // 0.42
        // GEF.bas:17160 (GEF.c:15737-15739)
        i_n = fb::max(i_n, 0.0F);
    }
    // GEF.bas:17162 `If DNsubmin < 6.0` (GEF.c:15748)
    if (!(static_cast<double>(dnsubmin) >= 6.0)) {
        // GEF.bas:17164 (GEF.c:15752): 1.7*(4.0-dNsubmin)*(1.0-0.18*Abs(40.0-Z)), folded by fbc
        // as (-dNsubmin*1.7 + 6.8) * (1.0 - 0.18*Abs(-Z + 40.0)).
        i_nsub = static_cast<float>(
            ((-static_cast<double>(dnsubmin) * 0x1.B333333333333p+0) +
             0x1.B333333333333p+2) * // 1.7, 6.8
            ((-(std::fabs((-static_cast<double>(z)) + 40.0) * 0x1.70A3D70A3D70Ap-3)) +
             1.0)); // 0.18
        // GEF.bas:17166 (GEF.c:15755-15757)
        i_nsub = fb::max(i_nsub, 0.0F);
    }
    // GEF.bas:17168 (GEF.c:15766-15768): U_I_shell = 1.0/(1.0 + Max(I_N,I_Nsub) + I_Z), emitted
    // as ((M + Z) + 1.0).
    float const vr68 = fb::max(i_n, i_nsub);
    return static_cast<float>(1.0 / ((static_cast<double>(vr68) + static_cast<double>(i_z)) + 1.0));
}

// GEF.bas:17094-17108 (GEF.c:15493-15527): U_Ired. Z is unused, as in the BASIC.
float u_ired([[maybe_unused]] float z, float a) noexcept {
    // GEF.bas:17100 (GEF.c:15513-15515): IU_rigid_spher = 1.16^2 * A^1.6667 / 103.8415, with
    // 1.16^2 folded by fbc (0x1.58793DD97F62Bp+0).
    double const vr4 = std::pow(static_cast<double>(a), 0x1.AAACD9E83E426p+0); // 1.6667
    auto const iu =
        static_cast<float>((vr4 * 0x1.58793DD97F62Bp+0) / 0x1.9F5DB22D0E56p+6); // 103.8415
    // GEF.bas:17104 (GEF.c:15518): IfragEff = 0.45 * IU_rigid_spher (superfluidity)
    return static_cast<float>(static_cast<double>(iu) * 0x1.CCCCCCCCCCCCDp-2); // 0.45
}

// GEF.bas:17110-17118 (GEF.c:15530-15551): U_IredFF = U_Ired(Z,A) * U_I_Shell(Z,A), Single.
float u_iredff(float z, float a) noexcept {
    float const vr1 = u_ired(z, a);
    float const vr2 = u_i_shell(z, a);
    return vr1 * vr2;
}

// GEF.bas:17439-17459 (GEF.c:16612-16668): E0_GDR. Z is unused. The statics and locals of the
// BASIC (epsilon, J, Q, R0, mstar, hbar, Aonethird, u, N, E0) are dead in the emitted C.
float e0_gdr([[maybe_unused]] float z, float a) noexcept {
    // GEF.bas:17451 (GEF.c:16658-16662): 18.0/A^0.333333 + 25.0/A^0.1666667
    double const vr6 = std::pow(static_cast<double>(a), 0x1.55553EF6B5D46p-2); // 0.333333
    double const vr9 = std::pow(static_cast<double>(a), 0x1.555559CEA86F2p-3); // 0.1666667
    return static_cast<float>((18.0 / vr6) + (25.0 / vr9));
}

// GEF.bas:17461-17464 (GEF.c:16671-16690): Width_GDR = 1.99 * (E0/10)^1.6
float width_gdr(float e0) noexcept {
    // GEF.bas:17463 (GEF.c:16682-16684)
    double const vr3 = std::pow(static_cast<double>(e0) / 10.0, 0x1.999999999999Ap+0); // 1.6
    return static_cast<float>(vr3 * 0x1.FD70A3D70A3D7p+0);                             // 1.99
}

// GEF.bas:17466-17475 (GEF.c:16693-16728): Efac_def_GDR
float efac_def_gdr(float beta, float gamma_def, float k) noexcept {
    // GEF.bas:17470-17471 (GEF.c:16704-16708): if beta = 0 and gamma = 0 then 1
    if (beta == 0.0F && gamma_def == 0.0F) {
        return 1.0F;
    }
    // GEF.bas:17473 (GEF.c:16718): 1/exp(sqr(5/(4*pi))*Beta*cos(gamma - 0.666667*(K-2)*pi)).
    // K-2 is Single (`K + -2.0f`); the cos argument and the rest are Double.
    double const arg =
        ((static_cast<double>(beta) *
          std::cos(static_cast<double>(gamma_def) - (static_cast<double>(k - 2.0F) * c_gamma))) *
         c_beta);
    return static_cast<float>(1.0 / std::exp(arg));
}

} // namespace gef::physics
