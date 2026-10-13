// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// T1 tests of physics/shape (Getyield, F1, F2, Masscurv, Masscurv1, Masscurv2,
// De_Saddle_Scission, beta_light, beta_heavy, Z_equi, Beta_Equi) against the driver m5_shape
// (golden m5-shape-2) and the arglog captures. The grids repeat the driver's
// (harness/drivers/m5_shape.bas).

#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "fbrt/rng.hpp"
#include "fbrt/text.hpp"
#include "physics/shape.hpp"
#include "support/m5.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace {

namespace m5 = gef::test::m5;
namespace physics = gef::physics;
namespace fb = gef::fb;

constexpr std::string_view s_f = "Z_S_A:f32 result:f32";
constexpr std::string_view s_getyield = "E_rel:f32 E:f32 E_shell:f32 dE_defo:f32 T_low:f32 "
                                        "T_high:f32 T_high_mac:f32 Imode:i64 result:f32";
constexpr std::string_view s_masscurv = "Z:f32 A:f32 RL:f32 kappa:f32 kappa4:f32 result:f32";
constexpr std::string_view s_de_saddle = "Z_CN_in:f32 A_CN_in:f32 ESHIFTSASCI:f32 result:f32";
constexpr std::string_view s_beta_light = "Z:i64 betaL0:f32 betaL1:f32 result:f32";
constexpr std::string_view s_beta_heavy = "Z:i64 betaH0:f32 betaH1:f32 result:f32";
constexpr std::string_view s_z_equi =
    "ZCN:i64 A1:i64 A2:i64 beta1:f32 beta2:f32 d:f32 Imode:i64 result:f32";
constexpr std::string_view s_beta_equi =
    "A1:f32 A2:f32 Z1:f32 Z2:f32 d:f32 beta1prev:f32 beta2prev:f32 beta1opt.in:f32 "
    "beta1opt.out:f32 beta2opt.in:f32 beta2opt.out:f32 global.f:i64";
constexpr std::string_view s_beta_equi_grid =
    "A1:f32 A2:f32 Z1:f32 Z2:f32 d:f32 beta1prev:f32 beta2prev:f32 beta1opt.in:f32 "
    "beta1opt.out:f32 beta2opt.in:f32 beta2opt.out:f32 printed:i64";
constexpr int n_random = 100000;
constexpr int n_beta_random = 2000;
constexpr std::string_view golden = "m5-shape-2";

// A BASIC decimal literal assigned to a Single: the Double literal narrowed.
float sg(double x) noexcept {
    return static_cast<float>(x);
}

// Int(Single) assigned to an Integer: floor in Single, then CInt.
std::int64_t int_of(float x) noexcept {
    return fb::f2l(fb::floor(x));
}

std::string line_f1(float x) {
    return m5::join({m5::f32(x), m5::f32(physics::f1(x))});
}
std::string line_f2(float x) {
    return m5::join({m5::f32(x), m5::f32(physics::f2(x))});
}

std::string line_getyield(float e_rel, float e, float e_shell, float de_defo, float t_low,
                          float t_high, float t_high_mac, std::int64_t imode) {
    float const y = physics::getyield(e_rel, e, e_shell, de_defo, t_low, t_high, t_high_mac, imode);
    return m5::join({m5::f32(e_rel), m5::f32(e), m5::f32(e_shell), m5::f32(de_defo), m5::f32(t_low),
                     m5::f32(t_high), m5::f32(t_high_mac), m5::i64(imode), m5::f32(y)});
}

float masscurv_value(int which, float z, float a, float rl, float kappa, float kappa4) {
    if (which == 0) {
        return physics::masscurv(z, a, rl, kappa, kappa4);
    }
    if (which == 1) {
        return physics::masscurv1(z, a, rl, kappa, kappa4);
    }
    return physics::masscurv2(z, a, rl, kappa, kappa4);
}

std::string line_masscurv(int which, float z, float a, float rl, float kappa, float kappa4) {
    return m5::join({m5::f32(z), m5::f32(a), m5::f32(rl), m5::f32(kappa), m5::f32(kappa4),
                     m5::f32(masscurv_value(which, z, a, rl, kappa, kappa4))});
}

std::string line_de_saddle(float z, float a, float e) {
    return m5::join(
        {m5::f32(z), m5::f32(a), m5::f32(e), m5::f32(physics::de_saddle_scission(z, a, e))});
}

std::string line_beta(bool heavy, std::int64_t z, float b0, float b1) {
    float const beta = heavy ? physics::beta_heavy(z, b0, b1) : physics::beta_light(z, b0, b1);
    return m5::join({m5::i64(z), m5::f32(b0), m5::f32(b1), m5::f32(beta)});
}

std::string line_z_equi(std::int64_t zcn, std::int64_t a1, std::int64_t a2, float b1, float b2,
                        float d, std::int64_t imode) {
    return m5::join({m5::i64(zcn), m5::i64(a1), m5::i64(a2), m5::f32(b1), m5::f32(b2), m5::f32(d),
                     m5::i64(imode), m5::f32(physics::z_equi(zcn, a1, a2, b1, b2, d, imode))});
}

// The driver's LineBetaEquiGrid (last token: 1 if the call printed) and LineBetaEquiReplay
// (last token: the logged global.f, echoed).
std::string line_beta_equi(physics::BetaEquiResult const& r, float a1, float a2, float z1, float z2,
                           float d, float b1p, float b2p, float b1i, float b2i,
                           std::string const& last) {
    return m5::join({m5::f32(a1), m5::f32(a2), m5::f32(z1), m5::f32(z2), m5::f32(d), m5::f32(b1p),
                     m5::f32(b2p), m5::f32(b1i), m5::f32(r.beta1opt), m5::f32(b2i),
                     m5::f32(r.beta2opt), last});
}

// The driver's LineBetaEquiGrid. When the search does not converge, BASIC prints
// `Print #f,"Beta_Equi not converged: ",Z1,N` (GEF.c:13806-13814) to the driver's
// Beta_Equi_print.txt; the same line goes to `print_file`.
std::string line_beta_equi_grid(fb::PrintFile& print_file, float a1, float a2, float z1, float z2,
                                float d, float b1p, float b2p, float b1i, float b2i) {
    auto const r = physics::beta_equi(a1, a2, z1, z2, d, b1p, b2p, b1i, b2i);
    if (r.print_not_converged != (r.n > 998)) {
        FAIL("Beta_Equi print flag " << r.print_not_converged << " with N " << r.n);
    }
    if (r.print_not_converged) {
        print_file.print("Beta_Equi not converged: ", fb::PrintEnd::Pad);
        print_file.print(z1, fb::PrintEnd::Pad);
        print_file.print(r.n, fb::PrintEnd::Newline);
    }
    return m5::join({m5::f32(a1), m5::f32(a2), m5::f32(z1), m5::f32(z2), m5::f32(d), m5::f32(b1p),
                     m5::f32(b2p), m5::f32(b1i), m5::f32(r.beta1opt), m5::f32(b2i),
                     m5::f32(r.beta2opt), m5::i64(r.print_not_converged ? 1 : 0)});
}

} // namespace

TEST_CASE("physics: Getyield equals BASIC on the driver grids", "[T1][physics]") {
    std::array<float, 5> const erefv = {sg(-2.33), sg(0.0), sg(2.5), sg(6.0), sg(12.6)};
    std::array<float, 4> const tlov = {sg(0.2436), sg(0.3), sg(0.3799), sg(0.25)};
    std::array<float, 4> const thiv = {sg(0.4594), sg(0.5), sg(0.6525), sg(0.25)};
    m5::GridFile grid("Getyield_grid.txt", "Getyield", s_getyield);
    for (std::int64_t i = 0; i <= 2560; ++i) {
        for (float const e_ref : erefv) {
            for (std::size_t k = 0; k < 4; ++k) {
                grid.add(line_getyield(m5::axis(-20, 0.015625, i), e_ref, sg(-5.0), sg(0.5),
                                       tlov.at(k), thiv.at(k), sg(0.46), 0));
            }
        }
    }
    m5::check_grid(golden, grid);

    fb::FbMtRng rng(6001);
    m5::GridFile random("Getyield_random.txt", "Getyield", s_getyield);
    for (int i = 0; i < n_random; ++i) {
        float const e_rel = m5::draw(rng, -60, 20);
        float const e_ref = m5::draw(rng, -3, 14);
        float const e_shell = m5::draw(rng, -12, 1);
        float const de_defo = m5::draw(rng, -9, 2);
        float const t_low = m5::draw(rng, 0.2, 0.4);
        float const t_high = m5::draw(rng, 0.4, 0.7);
        float const t_high_mac = m5::draw(rng, 0.4, 0.5);
        std::int64_t const imode = int_of(m5::draw(rng, 0, 23));
        random.add(line_getyield(e_rel, e_ref, e_shell, de_defo, t_low, t_high, t_high_mac, imode));
    }
    m5::check_grid(golden, random);
}

TEST_CASE("physics: F1 and F2 equal BASIC on the driver grids", "[T1][physics]") {
    m5::GridFile g1("F1_grid.txt", "F1", s_f);
    m5::GridFile g2("F2_grid.txt", "F2", s_f);
    for (std::int64_t i = 0; i <= 25600; ++i) {
        g1.add(line_f1(m5::axis(-5, 1.0 / 128.0, i)));
        g2.add(line_f2(m5::axis(-5, 1.0 / 128.0, i)));
    }
    m5::check_grid(golden, g1);
    m5::check_grid(golden, g2);

    fb::FbMtRng rng1(6002);
    m5::GridFile r1("F1_random.txt", "F1", s_f);
    for (int i = 0; i < n_random; ++i) {
        r1.add(line_f1(m5::draw(rng1, -5, 200)));
    }
    m5::check_grid(golden, r1);
    fb::FbMtRng rng2(6003);
    m5::GridFile r2("F2_random.txt", "F2", s_f);
    for (int i = 0; i < n_random; ++i) {
        r2.add(line_f2(m5::draw(rng2, -5, 200)));
    }
    m5::check_grid(golden, r2);
}

namespace {

// One of Masscurv (0), Masscurv1 (1), Masscurv2 (2): the driver's GridMasscurv.
void check_masscurv(int which) {
    std::array<float, 3> const rlv = {sg(0), sg(3.5), sg(5.3)};
    std::array<float, 2> const kv = {sg(0), sg(0.3)};
    std::array<float, 2> const k4v = {sg(0), sg(0.05)};
    std::array<float, 3> const edv = {sg(0), sg(1), sg(2)};
    constexpr std::array<std::string_view, 3> names = {"Masscurv", "Masscurv1", "Masscurv2"};
    std::string const name(names.at(static_cast<std::size_t>(which)));
    m5::GridFile grid(name + "_grid.txt", name, s_masscurv);
    for (std::int64_t j = 0; j <= 50; ++j) {
        for (std::int64_t i = 0; i <= 100; ++i) {
            for (float const rl : rlv) {
                for (float const k : kv) {
                    for (float const k4 : k4v) {
                        grid.add(line_masscurv(which, m5::axis(60, 1, j), m5::axis(150, 1, i), rl,
                                               k, k4));
                    }
                }
            }
        }
    }
    for (float const z : edv) {
        for (float const a : edv) {
            grid.add(line_masscurv(which, z, a, sg(3.5), sg(0.3), sg(0.05)));
        }
    }
    m5::check_grid(golden, grid);

    fb::FbMtRng rng(6004 + which);
    m5::GridFile random(name + "_random.txt", name, s_masscurv);
    for (int i = 0; i < n_random; ++i) {
        float const z = m5::draw(rng, 1, 120);
        float const a = m5::draw(rng, 1, 280);
        float const rl = m5::draw(rng, 0, 8);
        float const kappa = m5::draw(rng, -1, 1);
        float const kappa4 = m5::draw(rng, -0.1, 0.1);
        random.add(line_masscurv(which, z, a, rl, kappa, kappa4));
    }
    m5::check_grid(golden, random);
}

} // namespace

TEST_CASE("physics: Masscurv, Masscurv1, Masscurv2 equal BASIC on the driver grids",
          "[T1][physics]") {
    for (int which = 0; which < 3; ++which) {
        check_masscurv(which);
    }
}

TEST_CASE("physics: De_Saddle_Scission equals BASIC on the driver grids", "[T1][physics]") {
    std::array<float, 8> const esv = {sg(-100), sg(-90), sg(-80), sg(-67),
                                      sg(-50),  sg(-30), sg(0),   sg(10)};
    m5::GridFile grid("De_Saddle_Scission_grid.txt", "De_Saddle_Scission", s_de_saddle);
    for (std::int64_t j = 0; j <= 60; ++j) {
        for (std::int64_t i = 0; i <= 110; ++i) {
            for (float const e : esv) {
                grid.add(line_de_saddle(m5::axis(60, 1, j), m5::axis(150, 1, i), e));
            }
        }
    }
    m5::check_grid(golden, grid);

    fb::FbMtRng rng(6007);
    m5::GridFile random("De_Saddle_Scission_random.txt", "De_Saddle_Scission", s_de_saddle);
    for (int i = 0; i < n_random; ++i) {
        float const z = m5::draw(rng, 1, 120);
        float const a = m5::draw(rng, 1, 260);
        float const e = m5::draw(rng, -120, 40);
        random.add(line_de_saddle(z, a, e));
    }
    m5::check_grid(golden, random);
}

TEST_CASE("physics: beta_light and beta_heavy equal BASIC on the driver grids", "[T1][physics]") {
    std::array<float, 4> const bkv = {sg(0.6127), sg(0.65), sg(0.6522), sg(0.7)};
    for (int heavy = 0; heavy < 2; ++heavy) {
        std::string const name = heavy == 0 ? "beta_light" : "beta_heavy";
        std::string_view const schema = heavy == 0 ? s_beta_light : s_beta_heavy;
        m5::GridFile grid(name + "_grid.txt", name, schema);
        for (std::int64_t j = 0; j <= 124; ++j) {
            for (std::int64_t i = 0; i <= 200; ++i) {
                for (float const b1 : bkv) {
                    grid.add(line_beta(heavy != 0, -2 + j, m5::axis(10, 0.1, i), b1));
                }
            }
        }
        m5::check_grid(golden, grid);

        fb::FbMtRng rng(6008 + heavy);
        m5::GridFile random(name + "_random.txt", name, schema);
        for (int i = 0; i < n_random; ++i) {
            std::int64_t const z = int_of(m5::draw(rng, 0, 121));
            float const b0 = m5::draw(rng, 10, 30);
            float const b1 = m5::draw(rng, 0.5, 0.8);
            random.add(line_beta(heavy != 0, z, b0, b1));
        }
        m5::check_grid(golden, random);
    }
}

TEST_CASE("physics: Z_equi equals BASIC on the driver grids", "[T1][physics]") {
    constexpr std::array<std::int64_t, 5> zsv = {20, 50, 80, 92, 110};
    std::array<float, 4> const pb1v = {sg(0), sg(0.3), sg(1.0), sg(1.9)};
    std::array<float, 4> const pb2v = {sg(0), sg(0.6), sg(1.5), sg(0.2)};
    std::array<float, 3> const dsv = {sg(0.5), sg(1.0), sg(2.0)};
    m5::GridFile grid("Z_equi_grid.txt", "Z_equi", s_z_equi);
    for (std::int64_t const zcn : zsv) {
        for (std::int64_t i = 0; i <= 36; ++i) {
            for (std::int64_t j = 0; j <= 36; ++j) {
                for (std::size_t p = 0; p < 4; ++p) {
                    for (float const d : dsv) {
                        grid.add(line_z_equi(zcn, 10 + (6 * i), 10 + (6 * j), pb1v.at(p),
                                             pb2v.at(p), d, 0));
                    }
                }
            }
        }
    }
    m5::check_grid(golden, grid);

    fb::FbMtRng rng(6010);
    m5::GridFile random("Z_equi_random.txt", "Z_equi", s_z_equi);
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const zcn = int_of(m5::draw(rng, 1, 121));
        std::int64_t const a1 = int_of(m5::draw(rng, 1, 241));
        std::int64_t const a2 = int_of(m5::draw(rng, 1, 241));
        float const b1 = m5::draw(rng, 0, 2);
        float const b2 = m5::draw(rng, 0, 2);
        float const d = m5::draw(rng, 0.5, 2);
        std::int64_t const imode = int_of(m5::draw(rng, 0, 6));
        random.add(line_z_equi(zcn, a1, a2, b1, b2, d, imode));
    }
    m5::check_grid(golden, random);
}

namespace {

// The driver's structured Beta_Equi grid.
void add_beta_equi_grid(m5::GridFile& grid, fb::PrintFile& print_file) {
    std::array<float, 9> const z1v = {sg(10), sg(20), sg(30), sg(40), sg(46),
                                      sg(52), sg(62), sg(72), sg(82)};
    std::array<float, 6> const a1v = {sg(25), sg(60), sg(100), sg(140), sg(180), sg(210)};
    std::array<float, 3> const pb1v = {sg(0.3), sg(0.45), sg(0.584)};
    std::array<float, 3> const pb2v = {sg(0.3), sg(0.5), sg(0.583)};
    for (float const z1 : z1v) {
        for (float const a1 : a1v) {
            for (float const b1p : pb1v) {
                for (float const b2p : pb2v) {
                    // Opt-in variant 0: the previous values; variant 1: (0, 0).
                    grid.add(line_beta_equi_grid(print_file, a1, 236.0F - a1, z1, 92.0F - z1,
                                                 sg(1.0), b1p, b2p, b1p, b2p));
                    grid.add(line_beta_equi_grid(print_file, a1, 236.0F - a1, z1, 92.0F - z1,
                                                 sg(1.0), b1p, b2p, 0.0F, 0.0F));
                }
            }
        }
    }
    // Edge rows: (a) no improvement, the incoming opt values pass through (D8); (b) exits at
    // N = 996 .. 1001 around the print condition N > 998.
    float const p1 = m5::parse_f32("3f0c28f6");
    float const p2 = m5::parse_f32("3f0c6a7f");
    auto const r = physics::beta_equi(118, 118, 46, 46, 1, p1, p2, 0.25F, 0.75F);
    CHECK(r.beta1opt == 0.25F);
    CHECK(r.beta2opt == 0.75F);
    grid.add(
        line_beta_equi_grid(print_file, 118, 118, 46, 46, sg(1.0), p1, p2, sg(0.25), sg(0.75)));
    constexpr std::array<std::string_view, 6> edge_p2 = {"3e77ced8", "3e774bc6", "3e76c8b4",
                                                         "3e7645a0", "3e75c28e", "3e753f7c"};
    std::int64_t expected_n = 996;
    for (std::string_view const t : edge_p2) {
        float const b1p = m5::parse_f32("3eb70a3e");
        float const b2p = m5::parse_f32(t);
        CHECK(physics::beta_equi(118, 118, 46, 46, 1, b1p, b2p, b1p, b2p).n == expected_n);
        ++expected_n;
        grid.add(line_beta_equi_grid(print_file, 118, 118, 46, 46, sg(1.0), b1p, b2p, b1p, b2p));
    }
}

} // namespace

TEST_CASE("physics: Beta_Equi equals BASIC on the driver grids", "[T1][physics][slow]") {
    fb::PrintFile print_file;
    m5::GridFile grid("Beta_Equi_grid.txt", "Beta_Equi", s_beta_equi_grid);
    add_beta_equi_grid(grid, print_file);
    m5::check_grid(golden, grid);

    fb::FbMtRng rng(6011);
    m5::GridFile random("Beta_Equi_random.txt", "Beta_Equi", s_beta_equi_grid);
    for (int i = 0; i < n_beta_random; ++i) {
        float const a1 = m5::draw(rng, 20, 215);
        float const a2 = m5::draw(rng, 20, 215);
        float const z1 = fb::floor(m5::draw(rng, 8, 85));
        float const z2 = fb::floor(m5::draw(rng, 8, 85));
        float const d = m5::draw(rng, 0.8, 1.2);
        float const b1p = m5::draw(rng, 0.1, 0.9);
        float const b2p = m5::draw(rng, 0.1, 0.9);
        float const b1i = m5::draw(rng, 0, 1);
        float const b2i = m5::draw(rng, 0, 1);
        random.add(line_beta_equi_grid(print_file, a1, a2, z1, z2, d, b1p, b2p, b1i, b2i));
    }
    m5::check_grid(golden, random);
    m5::check_text(golden, "Beta_Equi_print.txt", m5::text_lines(print_file.text()));
}

namespace {

using Tokens = std::vector<std::string>;

float tf32(Tokens const& t, std::size_t i) {
    return m5::parse_f32(t.at(i));
}
std::int64_t ti64(Tokens const& t, std::size_t i) {
    return m5::parse_i64(t.at(i));
}

// Getyield, F1, F2, De_Saddle_Scission.
std::size_t replay_scalars() {
    std::size_t n = 0;
    n += m5::check_replay("Getyield", s_getyield, [](Tokens const& t) {
        return line_getyield(tf32(t, 0), tf32(t, 1), tf32(t, 2), tf32(t, 3), tf32(t, 4), tf32(t, 5),
                             tf32(t, 6), ti64(t, 7));
    });
    n += m5::check_replay("F1", s_f, [](Tokens const& t) { return line_f1(tf32(t, 0)); });
    n += m5::check_replay("F2", s_f, [](Tokens const& t) { return line_f2(tf32(t, 0)); });
    n += m5::check_replay("De_Saddle_Scission", s_de_saddle, [](Tokens const& t) {
        return line_de_saddle(tf32(t, 0), tf32(t, 1), tf32(t, 2));
    });
    return n;
}

// Masscurv, Masscurv1, Masscurv2, beta_light, beta_heavy, Z_equi.
std::size_t replay_shapes() {
    std::size_t n = 0;
    constexpr std::array<std::string_view, 3> names = {"Masscurv", "Masscurv1", "Masscurv2"};
    for (int which = 0; which < 3; ++which) {
        n += m5::check_replay(names.at(static_cast<std::size_t>(which)), s_masscurv,
                              [which](Tokens const& t) {
                                  return line_masscurv(which, tf32(t, 0), tf32(t, 1), tf32(t, 2),
                                                       tf32(t, 3), tf32(t, 4));
                              });
    }
    n += m5::check_replay("beta_light", s_beta_light, [](Tokens const& t) {
        return line_beta(false, ti64(t, 0), tf32(t, 1), tf32(t, 2));
    });
    n += m5::check_replay("beta_heavy", s_beta_heavy, [](Tokens const& t) {
        return line_beta(true, ti64(t, 0), tf32(t, 1), tf32(t, 2));
    });
    n += m5::check_replay("Z_equi", s_z_equi, [](Tokens const& t) {
        return line_z_equi(ti64(t, 0), ti64(t, 1), ti64(t, 2), tf32(t, 3), tf32(t, 4), tf32(t, 5),
                           ti64(t, 6));
    });
    return n;
}

} // namespace

TEST_CASE("physics: shape functions replay the captured GEF calls", "[T1][physics]") {
    std::size_t const n = replay_scalars() + replay_shapes();
    if (n == 0) {
        SKIP("reference store with the M5 arglog captures not available");
    }
}

TEST_CASE("physics: Beta_Equi replays the captured GEF calls", "[T1][physics]") {
    std::size_t printed = 0;
    std::size_t const n =
        m5::check_replay("Beta_Equi", s_beta_equi, [&](std::vector<std::string> const& t) {
            auto const f = [&t](std::size_t i) { return m5::parse_f32(t.at(i)); };
            auto const r = physics::beta_equi(f(0), f(1), f(2), f(3), f(4), f(5), f(6), f(7), f(9));
            printed += r.print_not_converged ? 1U : 0U;
            // global.f is echoed: it is an input the function only prints to.
            return line_beta_equi(r, f(0), f(1), f(2), f(3), f(4), f(5), f(6), f(7), f(9),
                                  t.at(11));
        });
    if (n == 0) {
        SKIP("reference store with the M5 arglog captures not available");
    }
    // No captured call reaches the non-convergence print (plan D7).
    CHECK(printed == 0);
}
