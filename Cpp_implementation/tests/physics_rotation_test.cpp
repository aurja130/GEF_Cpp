// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// T1 tests of physics/rotation (U_Ired, U_IredFF, U_I_Shell, E0_GDR, Width_GDR, Efac_def_GDR,
// u_accel) against the driver m5_rotation (golden m5-rotation) and the arglog captures. The grids
// repeat the driver's (harness/drivers/m5_rotation.bas).

#include "fbrt/rng.hpp"
#include "physics/rotation.hpp"
#include "support/m5.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace {

namespace m5 = gef::test::m5;
namespace physics = gef::physics;

constexpr std::string_view s_za = "Z:f32 A:f32 result:f32";
constexpr std::string_view s_e0 = "E0:f32 result:f32";
constexpr std::string_view s_efac = "Beta:f32 Gamma:f32 K:f32 result:f32";
constexpr std::string_view s_uacc = "A1:f32 Z1:f32 A2:f32 Z2:f32 TKE:f32 E0:f32 Tn:f32 result:f32";
constexpr int n_random = 100000;

using Nuclide = float (*)(float, float) noexcept;

std::string nuclide_line(Nuclide f, float z, float a) {
    return m5::join({m5::f32(z), m5::f32(a), m5::f32(f(z, a))});
}

std::string width_line(float e0) {
    return m5::join({m5::f32(e0), m5::f32(physics::width_gdr(e0))});
}

std::string efac_line(float bv, float gv, float k) {
    return m5::join(
        {m5::f32(bv), m5::f32(gv), m5::f32(k), m5::f32(physics::efac_def_gdr(bv, gv, k))});
}

std::string uacc_line(float a1, float z1, float a2, float z2, float tke, float e0, float tn) {
    return m5::join({m5::f32(a1), m5::f32(z1), m5::f32(a2), m5::f32(z2), m5::f32(tke), m5::f32(e0),
                     m5::f32(tn), m5::f32(physics::u_accel(a1, z1, a2, z2, tke, e0, tn))});
}

// The nuclide grid (Z = 1..120, N = 0..200, quarter steps) and the seeded random draws of the
// driver's blocks for U_Ired, U_IredFF, U_I_Shell and E0_GDR.
void check_nuclide(std::string_view fn, Nuclide f, double seed, double z_lo, double z_hi,
                   double a_lo, double a_hi) {
    m5::GridFile grid(std::string(fn) + "_grid.txt", fn, s_za);
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 200; ++ni) {
            for (std::int64_t i = 0; i <= 3; ++i) {
                for (std::int64_t j = 0; j <= 3; ++j) {
                    float const z = static_cast<float>(zi) + (0.25F * static_cast<float>(i));
                    float const a = static_cast<float>(zi + ni) + (0.25F * static_cast<float>(j));
                    grid.add(nuclide_line(f, z, a));
                }
            }
        }
    }
    m5::check_grid("m5-rotation", grid);

    gef::fb::FbMtRng rng(seed);
    m5::GridFile random(std::string(fn) + "_random.txt", fn, s_za);
    for (int i = 0; i < n_random; ++i) {
        float const z = m5::draw(rng, z_lo, z_hi);
        float const a = m5::draw(rng, a_lo, a_hi);
        random.add(nuclide_line(f, z, a));
    }
    m5::check_grid("m5-rotation", random);
}

} // namespace

TEST_CASE("physics: U_Ired equals BASIC on the driver grids", "[T1][physics]") {
    check_nuclide("U_Ired", physics::u_ired, 5101, 31, 92, 77, 236);
}

TEST_CASE("physics: U_IredFF equals BASIC on the driver grids", "[T1][physics]") {
    check_nuclide("U_IredFF", physics::u_iredff, 5102, 30, 73, 77, 180);
}

TEST_CASE("physics: U_I_Shell equals BASIC on the driver grids", "[T1][physics]") {
    check_nuclide("U_I_Shell", physics::u_i_shell, 5103, 29, 74, 72, 181);
}

TEST_CASE("physics: E0_GDR equals BASIC on the driver grids", "[T1][physics]") {
    check_nuclide("E0_GDR", physics::e0_gdr, 5104, 29, 92, 73, 236);
}

TEST_CASE("physics: Width_GDR equals BASIC on the driver grids", "[T1][physics]") {
    constexpr std::array<float, 6> we = {0.0F, -0.0F, 1.4E-45F, -1.4E-45F, 9.999999F, 10.000001F};
    m5::GridFile grid("Width_GDR_grid.txt", "Width_GDR", s_e0);
    for (std::int64_t i = 0; i <= 1099; ++i) {
        grid.add(width_line(m5::axis(-1, 0.01, i)));
    }
    for (std::int64_t i = 0; i <= 900; ++i) {
        grid.add(width_line(m5::axis(10, 0.1, i)));
    }
    for (float const e0 : we) {
        grid.add(width_line(e0));
    }
    m5::check_grid("m5-rotation", grid);

    gef::fb::FbMtRng rng(5105);
    m5::GridFile random("Width_GDR_random.txt", "Width_GDR", s_e0);
    for (int i = 0; i < n_random; ++i) {
        float const e0 = m5::draw(rng, 11.66, 19.6);
        random.add(width_line(e0));
    }
    m5::check_grid("m5-rotation", random);
}

TEST_CASE("physics: Efac_def_GDR equals BASIC on the driver grids", "[T1][physics]") {
    constexpr std::array<float, 8> kb = {1.0F, 2.0F, 3.0F, 0.0F, -1.0F, 0.5F, 4.0F, 2.5F};
    constexpr std::array<float, 2> bc = {0.0F, -0.0F};
    m5::GridFile grid("Efac_def_GDR_grid.txt", "Efac_def_GDR", s_efac);
    for (std::int64_t i = 0; i <= 200; ++i) {
        float const bv = m5::axis(-0.5, 0.01, i);
        // CSng(-120.0# * Bv + 47.4#): Bv widened to Double.
        auto const gv = static_cast<float>((-120.0 * static_cast<double>(bv)) + 47.4);
        for (int kl = 1; kl <= 3; ++kl) {
            grid.add(efac_line(bv, gv, static_cast<float>(kl)));
        }
    }
    for (std::int64_t i = 0; i <= 8; ++i) {
        float const bv = m5::axis(-0.5, 0.25, i);
        for (std::int64_t j = 0; j <= 800; ++j) {
            float const gv = m5::axis(-200, 0.5, j);
            for (float const k : kb) {
                grid.add(efac_line(bv, gv, k));
            }
        }
    }
    for (float const bi : bc) {
        for (float const bj : bc) {
            for (int kl = 1; kl <= 3; ++kl) {
                grid.add(efac_line(bi, bj, static_cast<float>(kl)));
            }
        }
    }
    m5::check_grid("m5-rotation", grid);

    gef::fb::FbMtRng rng(5106);
    m5::GridFile random("Efac_def_GDR_random.txt", "Efac_def_GDR", s_efac);
    for (int i = 0; i < n_random; ++i) {
        float const bv = m5::draw(rng, -0.26, 0.4);
        float const gv = m5::draw(rng, 0.4, 78.5);
        float const k = m5::draw(rng, 1, 3);
        random.add(efac_line(bv, gv, k));
    }
    m5::check_grid("m5-rotation", random);
}

TEST_CASE("physics: u_accel equals BASIC on the driver grids", "[T1][physics]") {
    constexpr std::array<float, 8> pa1 = {140.0F, 150.0F, 110.0F, 118.0F,
                                          140.0F, 0.0F,   120.0F, 236.0F};
    constexpr std::array<float, 8> pz1 = {56.0F, 60.0F, 40.0F, 46.0F, 0.0F, 30.0F, 50.0F, 92.0F};
    constexpr std::array<float, 8> pa2 = {96.0F, 114.0F, 126.0F,  118.0F,
                                          96.0F, 236.0F, -120.0F, 0.0F};
    constexpr std::array<float, 8> pz2 = {36.0F, 50.0F, 52.0F, 46.0F, 92.0F, 92.0F, 50.0F, 0.0F};
    constexpr std::array<float, 20> qe = {0.0F,  0.0F,  0.0F,  0.0F,  0.0F,  5.0F,  5.0F,
                                          5.0F,  5.0F,  5.0F,  20.0F, 20.0F, 20.0F, 20.0F,
                                          20.0F, 50.0F, 50.0F, 50.0F, 50.0F, 50.0F};
    constexpr std::array<float, 20> qt = {
        -1.4E-45F,  0.0F,  1.4E-45F,   0.5F,  100.0F, 4.9999995F, 5.0F,  5.0000005F, 5.5F,  105.0F,
        19.999998F, 20.0F, 20.000002F, 20.5F, 120.0F, 49.999996F, 50.0F, 50.000004F, 50.5F, 150.0F};
    constexpr std::array<float, 14> tnl = {0.0F,  1.4E-45F, 0.0001F, 0.01F, 0.010000001F,
                                           0.1F,  0.5F,     1.0F,    1.1F,  2.0F,
                                           10.0F, 11.0F,    100.0F,  100.5F};
    m5::GridFile grid("u_accel_grid.txt", "u_accel", s_uacc);
    for (std::size_t p = 0; p < pa1.size(); ++p) {
        for (std::size_t q = 0; q < qt.size(); ++q) {
            for (float const tn : tnl) {
                grid.add(
                    uacc_line(pa1.at(p), pz1.at(p), pa2.at(p), pz2.at(p), qt.at(q), qe.at(q), tn));
            }
        }
    }
    for (std::int64_t i = 0; i <= 10000; ++i) {
        grid.add(uacc_line(140.0F, 56.0F, 96.0F, 36.0F, 150.0F, 20.0F, m5::axis(0, 0.01, i)));
    }
    for (std::int64_t i = 0; i <= 10000; ++i) {
        grid.add(uacc_line(110.0F, 40.0F, 126.0F, 52.0F, 120.0F, 5.0F, m5::axis(0, 0.01, i)));
    }
    for (std::int64_t i = 0; i <= 10000; ++i) {
        grid.add(uacc_line(150.0F, 60.0F, 114.0F, 50.0F, 200.0F, 50.0F, m5::axis(0, 0.01, i)));
    }
    m5::check_grid("m5-rotation", grid);

    gef::fb::FbMtRng rng(5107);
    m5::GridFile random("u_accel_random.txt", "u_accel", s_uacc);
    for (int i = 0; i < n_random; ++i) {
        float const a1 = m5::draw(rng, 74, 184);
        float const z1 = m5::draw(rng, 30, 73);
        float const a2 = m5::draw(rng, 68, 177);
        float const z2 = m5::draw(rng, 28, 70);
        float const tke = m5::draw(rng, 108, 276);
        float const e0 = m5::draw(rng, 0, 85);
        float const tn = m5::draw(rng, 0, 100);
        random.add(uacc_line(a1, z1, a2, z2, tke, e0, tn));
    }
    m5::check_grid("m5-rotation", random);
}

TEST_CASE("physics: rotation replays the captured GEF calls", "[T1][physics]") {
    std::size_t n = 0;
    n += m5::check_replay("U_Ired", s_za, [](std::vector<std::string> const& t) {
        return nuclide_line(physics::u_ired, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)));
    });
    n += m5::check_replay("U_IredFF", s_za, [](std::vector<std::string> const& t) {
        return nuclide_line(physics::u_iredff, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)));
    });
    n += m5::check_replay("U_I_Shell", s_za, [](std::vector<std::string> const& t) {
        return nuclide_line(physics::u_i_shell, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)));
    });
    n += m5::check_replay("E0_GDR", s_za, [](std::vector<std::string> const& t) {
        return nuclide_line(physics::e0_gdr, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)));
    });
    n += m5::check_replay("Width_GDR", s_e0, [](std::vector<std::string> const& t) {
        return width_line(m5::parse_f32(t.at(0)));
    });
    n += m5::check_replay("Efac_def_GDR", s_efac, [](std::vector<std::string> const& t) {
        return efac_line(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)), m5::parse_f32(t.at(2)));
    });
    n += m5::check_replay("u_accel", s_uacc, [](std::vector<std::string> const& t) {
        return uacc_line(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)), m5::parse_f32(t.at(2)),
                         m5::parse_f32(t.at(3)), m5::parse_f32(t.at(4)), m5::parse_f32(t.at(5)),
                         m5::parse_f32(t.at(6)));
    });
    if (n == 0) {
        SKIP("reference store with the M5 arglog captures not available");
    }
}
