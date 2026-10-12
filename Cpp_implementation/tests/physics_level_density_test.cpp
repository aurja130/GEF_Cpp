// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// T1 tests of physics/level_density (U_alev_ld, U_levdens, U_levdens_Egidy, U_levdens_FG, U_Temp,
// U_Temp2, TEgidy, TRusanov) against the driver m5_level_density (golden m5-level_density) and
// the arglog captures. The grids repeat the driver's (harness/drivers/m5_level_density.bas).

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "fbrt/rng.hpp"
#include "physics/level_density.hpp"
#include "support/m5.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace {

namespace m5 = gef::test::m5;
namespace physics = gef::physics;

constexpr std::string_view s_alev = "Z:f32 A:f32 result:f32";
constexpr std::string_view s_levdens =
    "Z:i64 A:i64 E:f32 Ishell:i64 Ipair:i64 Tscale:f32 Econd:f32 Etrans:f32 af_an:f32 result:f64";
constexpr std::string_view s_temp =
    "Z:f32 A:f32 E:f32 Ishell:i64 Ipair:i64 Tscale:f32 Econd:f32 Etrans:f32 result:f32";
constexpr std::string_view s_temp2 =
    "Z:f32 A:f32 E:f32 Rshell:f32 Rpair:f32 Tscale:f32 Econd:f32 Etrans:f32 result:f32";
constexpr std::string_view s_tegidy = "A:f32 DU:f32 Fred:f32 result:f32";
constexpr std::string_view s_trusanov = "E:f32 A:f32 result:f32";

constexpr float f32_nan = std::bit_cast<float>(std::uint32_t{0x7FC00000U});
constexpr float f32_inf = std::bit_cast<float>(std::uint32_t{0x7F800000U});

using LdFn = double (*)(gef::data::TableSet const&, std::int64_t, std::int64_t, float, std::int64_t,
                        std::int64_t, float, float, float, float);

struct LdCase {
    LdFn fn;
    std::string_view name;
    int seed;
};

constexpr std::array<LdCase, 3> ld_cases = {{
    {.fn = physics::u_levdens, .name = "U_levdens", .seed = 5102},
    {.fn = physics::u_levdens_egidy, .name = "U_levdens_Egidy", .seed = 5103},
    {.fn = physics::u_levdens_fg, .name = "U_levdens_FG", .seed = 5104},
}};

constexpr int n_random = 100000;

// Driver constants (harness/drivers/m5_level_density.bas).
constexpr std::array<float, 2> alev_zs = {10.0F, 92.0F};
constexpr std::array<std::uint32_t, 5> alev_sp = {0x3F000000U, 0x0D800000U, 0x71800000U,
                                                  0x7F7FFFFFU, 0x7FC00000U};
constexpr std::array<std::int64_t, 3> ld_zs = {91, 92, 93};
constexpr std::array<std::int64_t, 2> ld_ais = {233, 236};
constexpr std::array<float, 3> e3_list = {-1.0F, 9.5F, 100.0F};
constexpr std::array<float, 9> ld_ev = {-1.0F, 1.0F, 9.0F,    9.5F,   10.0F,
                                        16.0F, 0.0F, f32_nan, f32_inf};
constexpr std::array<float, 2> ld_etv = {9.5F, 4.0F};
constexpr std::array<float, 3> ld_afv = {1.0F, 0.75F, 1.25F};
constexpr std::array<float, 2> tsv_list = {1.0F, 0.5F};
constexpr std::array<float, 3> cov_list = {0.0F, 2.0F, 4.0F};
constexpr std::array<float, 8> temp_zq = {10.0F, 10.25F, 10.5F, 10.75F,
                                          92.0F, 92.25F, 92.5F, 92.75F};
constexpr std::array<float, 6> temp_pz = {10.0F, 50.0F, 88.0F, 92.0F, 92.0F, 96.0F};
constexpr std::array<float, 6> temp_pa = {20.0F, 110.0F, 226.0F, 233.0F, 236.0F, 240.0F};
constexpr std::array<float, 7> temp_ev = {-1.0F, 0.5F, 1.0F, 5.0F, 9.5F, 20.0F, f32_nan};
constexpr std::array<float, 2> temp_etv = {9.5F, 0.0F};
constexpr std::array<float, 3> temp2_rsv = {0.0F, -2.5F, 1.5F};
constexpr std::array<float, 3> temp2_rpv = {0.0F, 0.5F, -1.0F};
constexpr std::array<float, 2> temp2_rqv = {0.0F, 0.5F};
constexpr std::array<float, 3> tegidy_fv = {0.8F, 1.0F, 1.25F};

// FillE bit-pattern edge values: EAx(2001..2014) in the driver.
constexpr std::array<std::uint32_t, 14> energy_bits = {
    0x80000001U, 0x00000001U, 0x3EFFFFFFU, 0x3F000001U, 0x3FFFFFFFU, 0x40000001U, 0x401FFFFFU,
    0x40200001U, 0x407FFFFFU, 0x40800001U, 0x408FFFFFU, 0x40900001U, 0x4117FFFFU, 0x41180001U};

gef::data::TableSet level_density_tables() {
    return gef::data::load_tables(gef::data::ProgramData(gef::data::NuclideData::Jeff33));
}

// Driver LdDrawI(Lo, Hi): floor of the uniform draw, so integer ranges are [Lo, Hi).
std::int64_t draw_int(gef::fb::FbMtRng& rng, double lo, double hi) {
    return static_cast<std::int64_t>(std::floor(m5::draw(rng, lo, hi)));
}

std::string line_alev(float z, float a) {
    return m5::join({m5::f32(z), m5::f32(a), m5::f32(physics::u_alev_ld(z, a))});
}

std::string line_ld(LdFn fn, gef::data::TableSet const& tables, std::int64_t z, std::int64_t a,
                    float e, std::int64_t ishell, std::int64_t ipair, float tscale, float econd,
                    float etrans, float af_an) {
    return m5::join({m5::i64(z), m5::i64(a), m5::f32(e), m5::i64(ishell), m5::i64(ipair),
                     m5::f32(tscale), m5::f32(econd), m5::f32(etrans), m5::f32(af_an),
                     m5::f64(fn(tables, z, a, e, ishell, ipair, tscale, econd, etrans, af_an))});
}

std::string line_temp(gef::data::TableSet const& tables, float z, float a, float e,
                      std::int64_t ishell, std::int64_t ipair, float tscale, float econd,
                      float etrans) {
    return m5::join(
        {m5::f32(z), m5::f32(a), m5::f32(e), m5::i64(ishell), m5::i64(ipair), m5::f32(tscale),
         m5::f32(econd), m5::f32(etrans),
         m5::f32(physics::u_temp(tables, z, a, e, ishell, ipair, tscale, econd, etrans))});
}

std::string line_temp2(float z, float a, float e, float rshell, float rpair, float tscale,
                       float econd, float etrans) {
    return m5::join({m5::f32(z), m5::f32(a), m5::f32(e), m5::f32(rshell), m5::f32(rpair),
                     m5::f32(tscale), m5::f32(econd), m5::f32(etrans),
                     m5::f32(physics::u_temp2(z, a, e, rshell, rpair, tscale, econd, etrans))});
}

std::string line_tegidy(float a, float du, float fred) {
    return m5::join(
        {m5::f32(a), m5::f32(du), m5::f32(fred), m5::f32(physics::tegidy(a, du, fred))});
}

std::string line_trusanov(float e, float a) {
    return m5::join({m5::f32(e), m5::f32(a), m5::f32(physics::trusanov(e, a))});
}

std::string replay_ld(LdFn fn, gef::data::TableSet const& tables,
                      std::vector<std::string> const& t) {
    return line_ld(fn, tables, m5::parse_i64(t.at(0)), m5::parse_i64(t.at(1)),
                   m5::parse_f32(t.at(2)), m5::parse_i64(t.at(3)), m5::parse_i64(t.at(4)),
                   m5::parse_f32(t.at(5)), m5::parse_f32(t.at(6)), m5::parse_f32(t.at(7)),
                   m5::parse_f32(t.at(8)));
}

std::string replay_temp(gef::data::TableSet const& tables, std::vector<std::string> const& t) {
    return line_temp(tables, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)), m5::parse_f32(t.at(2)),
                     m5::parse_i64(t.at(3)), m5::parse_i64(t.at(4)), m5::parse_f32(t.at(5)),
                     m5::parse_f32(t.at(6)), m5::parse_f32(t.at(7)));
}

// FillE of the driver: 1100 points from -1 in steps of 0.01, then 901 points from 10 in steps of
// 0.1, then the 14 bit-pattern edge values. Indices 0..2014 (EAx).
std::vector<float> energy_axis() {
    std::vector<float> ea;
    ea.reserve(2015);
    for (std::int64_t k = 0; k < 1100; ++k) {
        ea.push_back(m5::axis(-1.0, 0.01, k));
    }
    for (std::int64_t k = 1100; k <= 2000; ++k) {
        ea.push_back(m5::axis(10.0, 0.1, k - 1100));
    }
    for (std::uint32_t const bits : energy_bits) {
        ea.push_back(std::bit_cast<float>(bits));
    }
    return ea;
}

// U_alev_ld grid. Block 1: Z 1..120 x J 0..812, A = M5_Axis(Z, 0.25, J). Block 2: Iz x K over the
// Sp bit patterns.
void alev_grid(m5::GridFile& grid) {
    for (std::int64_t z = 1; z <= 120; ++z) {
        for (std::int64_t j = 0; j <= 812; ++j) {
            grid.add(line_alev(static_cast<float>(z), m5::axis(static_cast<double>(z), 0.25, j)));
        }
    }
    for (float const zs : alev_zs) {
        for (std::uint32_t const bits : alev_sp) {
            grid.add(line_alev(zs, std::bit_cast<float>(bits)));
        }
    }
}

// LdSweepE: one (Z, A, Ishell, Ipair, Tscale, Econd, Etrans, af_an) over the EAx energy axis.
void ld_sweep(m5::GridFile& grid, LdFn fn, gef::data::TableSet const& tables, std::int64_t z,
              std::int64_t a, std::int64_t ishell, std::int64_t ipair, float tscale, float econd,
              float etrans, float af_an, std::vector<float> const& ea) {
    for (float const e : ea) {
        grid.add(line_ld(fn, tables, z, a, e, ishell, ipair, tscale, econd, etrans, af_an));
    }
}

// Driver GridLD block 1: Zi 1..120 x Ni 1..202 x E3, A = Zi + Ni, Ishell 1, Ipair 0.
void ld_block1(m5::GridFile& grid, LdFn fn, gef::data::TableSet const& tables) {
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 1; ni <= 202; ++ni) {
            for (float const e : e3_list) {
                grid.add(line_ld(fn, tables, zi, zi + ni, e, 1, 0, 1.0F, 2.0F, 9.5F, 1.0F));
            }
        }
    }
}

// Driver GridLD block 2: Ia x Iz x Ish x Ipr, each swept over EAx.
void ld_block2(m5::GridFile& grid, LdFn fn, gef::data::TableSet const& tables,
               std::vector<float> const& ea) {
    for (std::int64_t const a : ld_ais) {
        for (std::int64_t const z : ld_zs) {
            for (std::int64_t ish = 0; ish <= 1; ++ish) {
                for (std::int64_t ipr = 0; ipr <= 2; ++ipr) {
                    ld_sweep(grid, fn, tables, z, a, ish, ipr, 1.0F, 2.0F, 9.5F, 1.0F, ea);
                }
            }
        }
    }
}

// Driver GridLD block 3 inner: Its x Ico x Iet x Iaf at fixed (Z, A = 236, E, Ish, Ipr).
void ld_block3_inner(m5::GridFile& grid, LdFn fn, gef::data::TableSet const& tables, std::int64_t z,
                     float e, std::int64_t ish, std::int64_t ipr) {
    for (float const ts : tsv_list) {
        for (float const co : cov_list) {
            for (float const et : ld_etv) {
                for (float const af : ld_afv) {
                    grid.add(line_ld(fn, tables, z, 236, e, ish, ipr, ts, co, et, af));
                }
            }
        }
    }
}

// Driver GridLD block 3: Iz (Z = 92 + Iz) x Ie x Ish x Ipr x Its x Ico x Iet x Iaf.
void ld_block3(m5::GridFile& grid, LdFn fn, gef::data::TableSet const& tables) {
    for (std::int64_t z = 92; z <= 93; ++z) {
        for (float const e : ld_ev) {
            for (std::int64_t ish = 0; ish <= 1; ++ish) {
                for (std::int64_t ipr = 0; ipr <= 2; ++ipr) {
                    ld_block3_inner(grid, fn, tables, z, e, ish, ipr);
                }
            }
        }
    }
}

// Driver GridLD block 4: (Z, A) = (92, 236), one parameter changed per EAx sweep, in this order.
void ld_block4(m5::GridFile& grid, LdFn fn, gef::data::TableSet const& tables,
               std::vector<float> const& ea) {
    ld_sweep(grid, fn, tables, 92, 236, 1, 0, 1.0F, 2.0F, 9.5F, 1.0F, ea);
    ld_sweep(grid, fn, tables, 92, 236, 0, 1, 1.0F, 2.0F, 9.5F, 1.0F, ea);
    ld_sweep(grid, fn, tables, 92, 236, 0, 2, 1.0F, 2.0F, 9.5F, 1.0F, ea);
    ld_sweep(grid, fn, tables, 92, 236, 0, 0, 0.5F, 2.0F, 9.5F, 1.0F, ea);
    ld_sweep(grid, fn, tables, 92, 236, 0, 0, 1.0F, 0.0F, 9.5F, 1.0F, ea);
    ld_sweep(grid, fn, tables, 92, 236, 0, 0, 1.0F, 4.0F, 9.5F, 1.0F, ea);
    ld_sweep(grid, fn, tables, 92, 236, 0, 0, 1.0F, 2.0F, 4.0F, 1.0F, ea);
    ld_sweep(grid, fn, tables, 92, 236, 0, 0, 1.0F, 2.0F, 0.0F, 1.0F, ea);
    ld_sweep(grid, fn, tables, 92, 236, 0, 0, 1.0F, 2.0F, 9.5F, 0.75F, ea);
    ld_sweep(grid, fn, tables, 92, 236, 0, 0, 1.0F, 2.0F, 9.5F, 1.25F, ea);
}

// Driver GridLD random: Randomize Sd, 3; Zr, Ar, Er, Ir, Pr, Tr, Cr, Hr, Fr per record.
void ld_random(m5::GridFile& random_grid, LdFn fn, gef::data::TableSet const& tables,
               gef::fb::FbMtRng& rng) {
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const zr = draw_int(rng, 88.0, 97.0);
        std::int64_t const ar = draw_int(rng, 226.0, 241.0);
        float const er = m5::draw(rng, -10.0, 25.0);
        std::int64_t const ir = draw_int(rng, 0.0, 2.0);
        std::int64_t const pr = draw_int(rng, 0.0, 3.0);
        float const tr = m5::draw(rng, 0.5, 1.5);
        float const cr = m5::draw(rng, 0.0, 4.0);
        float const hr = m5::draw(rng, 0.0, 15.0);
        float const fr = m5::draw(rng, 0.9, 1.1);
        random_grid.add(line_ld(fn, tables, zr, ar, er, ir, pr, tr, cr, hr, fr));
    }
}

// Grid and random checks shared by U_levdens, U_levdens_Egidy and U_levdens_FG.
void check_ld_grid(LdCase const& c) {
    auto const tables = level_density_tables();
    auto const ea = energy_axis();
    std::string const grid_file = std::string(c.name) + "_grid.txt";
    m5::GridFile grid(grid_file, c.name, s_levdens);
    ld_block1(grid, c.fn, tables);
    ld_block2(grid, c.fn, tables, ea);
    ld_block3(grid, c.fn, tables);
    ld_block4(grid, c.fn, tables, ea);
    m5::check_grid("m5-level_density", grid);

    std::string const random_file = std::string(c.name) + "_random.txt";
    m5::GridFile random_grid(random_file, c.name, s_levdens);
    gef::fb::FbMtRng rng(c.seed);
    ld_random(random_grid, c.fn, tables, rng);
    m5::check_grid("m5-level_density", random_grid);
}

// Driver GridTemp block 1: Zi 1..120 x Ni 0..203 x E3, A = Zi + Ni, Ishell 1, Ipair 0.
void temp_block1(m5::GridFile& grid, gef::data::TableSet const& tables) {
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 203; ++ni) {
            for (float const e : e3_list) {
                grid.add(line_temp(tables, static_cast<float>(zi), static_cast<float>(zi + ni), e,
                                   1, 0, 1.0F, 2.0F, 9.5F));
            }
        }
    }
}

// Driver GridTemp block 2: Iq x J 0..811 x E3, A = M5_Axis(Zq, 0.25, J), Ishell 1, Ipair 1.
void temp_block2(m5::GridFile& grid, gef::data::TableSet const& tables) {
    for (float const zq : temp_zq) {
        for (std::int64_t j = 0; j <= 811; ++j) {
            float const a = m5::axis(static_cast<double>(zq), 0.25, j);
            for (float const e : e3_list) {
                grid.add(line_temp(tables, zq, a, e, 1, 1, 1.0F, 2.0F, 9.5F));
            }
        }
    }
}

// TempSweepE: one (Z, A, Ishell, Ipair, Tscale, Econd, Etrans) over EAx.
void temp_sweep(m5::GridFile& grid, gef::data::TableSet const& tables, float z, float a,
                std::int64_t ishell, std::int64_t ipair, float tscale, float econd, float etrans,
                std::vector<float> const& ea) {
    for (float const e : ea) {
        grid.add(line_temp(tables, z, a, e, ishell, ipair, tscale, econd, etrans));
    }
}

// Driver GridTemp block 3: (PZ, PA) x Ish x Ipr, each swept over EAx.
void temp_block3(m5::GridFile& grid, gef::data::TableSet const& tables,
                 std::vector<float> const& ea) {
    for (std::size_t ip = 0; ip < temp_pz.size(); ++ip) {
        for (std::int64_t ish = 0; ish <= 1; ++ish) {
            for (std::int64_t ipr = 0; ipr <= 2; ++ipr) {
                temp_sweep(grid, tables, temp_pz[ip], temp_pa[ip], ish, ipr, 1.0F, 2.0F, 9.5F, ea);
            }
        }
    }
}

// Driver GridTemp block 4 inner: Ie x Ish x Ipr at fixed (Z, A, Its, Ico, Iet).
void temp_block4_inner(m5::GridFile& grid, gef::data::TableSet const& tables, float z, float a,
                       float ts, float co, float et) {
    for (float const e : temp_ev) {
        for (std::int64_t ish = 0; ish <= 1; ++ish) {
            for (std::int64_t ipr = 0; ipr <= 2; ++ipr) {
                grid.add(line_temp(tables, z, a, e, ish, ipr, ts, co, et));
            }
        }
    }
}

// Driver GridTemp block 4: (PZ, PA) x Its x Ico x Iet x Ie x Ish x Ipr.
void temp_block4(m5::GridFile& grid, gef::data::TableSet const& tables) {
    for (std::size_t ip = 0; ip < temp_pz.size(); ++ip) {
        for (float const ts : tsv_list) {
            for (float const co : cov_list) {
                for (float const et : temp_etv) {
                    temp_block4_inner(grid, tables, temp_pz[ip], temp_pa[ip], ts, co, et);
                }
            }
        }
    }
}

// Driver GridTemp block 5: (Z, A) = (92, 236), one parameter changed per EAx sweep, in this order.
void temp_block5(m5::GridFile& grid, gef::data::TableSet const& tables,
                 std::vector<float> const& ea) {
    temp_sweep(grid, tables, 92.0F, 236.0F, 1, 0, 1.0F, 2.0F, 9.5F, ea);
    temp_sweep(grid, tables, 92.0F, 236.0F, 0, 1, 1.0F, 2.0F, 9.5F, ea);
    temp_sweep(grid, tables, 92.0F, 236.0F, 0, 2, 1.0F, 2.0F, 9.5F, ea);
    temp_sweep(grid, tables, 92.0F, 236.0F, 0, 0, 0.5F, 2.0F, 9.5F, ea);
    temp_sweep(grid, tables, 92.0F, 236.0F, 0, 0, 1.0F, 0.0F, 9.5F, ea);
    temp_sweep(grid, tables, 92.0F, 236.0F, 0, 0, 1.0F, 4.0F, 9.5F, ea);
}

// Driver GridTemp random: Randomize 5105, 3; Zr, Ar = Zr + [0, 141), Er, Ir, Pr, Tr, Cr, Hr.
void temp_random(m5::GridFile& random_grid, gef::data::TableSet const& tables,
                 gef::fb::FbMtRng& rng) {
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const zr = draw_int(rng, 10.0, 97.0);
        std::int64_t const ar = zr + draw_int(rng, 0.0, 141.0);
        float const er = m5::draw(rng, -12.0, 95.0);
        std::int64_t const ir = draw_int(rng, 0.0, 2.0);
        std::int64_t const pr = draw_int(rng, 0.0, 3.0);
        float const tr = m5::draw(rng, 0.5, 1.5);
        float const cr = m5::draw(rng, 0.0, 4.0);
        float const hr = m5::draw(rng, 0.0, 15.0);
        random_grid.add(line_temp(tables, static_cast<float>(zr), static_cast<float>(ar), er, ir,
                                  pr, tr, cr, hr));
    }
}

// Driver GridTemp2 block 1: Zi 1..120 x Ni 0..203 x E3, A = Zi + Ni, Rshell 0, Rpair 0.
void temp2_block1(m5::GridFile& grid) {
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 203; ++ni) {
            for (float const e : e3_list) {
                grid.add(line_temp2(static_cast<float>(zi), static_cast<float>(zi + ni), e, 0.0F,
                                    0.0F, 1.0F, 2.0F, 9.5F));
            }
        }
    }
}

// Driver GridTemp2 block 2: Iq x J 0..811 x E3, A = M5_Axis(Zq, 0.25, J), Rshell 0, Rpair 0.
void temp2_block2(m5::GridFile& grid) {
    for (float const zq : temp_zq) {
        for (std::int64_t j = 0; j <= 811; ++j) {
            float const a = m5::axis(static_cast<double>(zq), 0.25, j);
            for (float const e : e3_list) {
                grid.add(line_temp2(zq, a, e, 0.0F, 0.0F, 1.0F, 2.0F, 9.5F));
            }
        }
    }
}

// Temp2SweepE: one (Z, A, Rshell, Rpair, Tscale, Econd, Etrans) over EAx.
void temp2_sweep(m5::GridFile& grid, float z, float a, float rs, float rp, float ts, float co,
                 float et, std::vector<float> const& ea) {
    for (float const e : ea) {
        grid.add(line_temp2(z, a, e, rs, rp, ts, co, et));
    }
}

// Driver GridTemp2 block 3: (PZ, PA) x Irs x Irp, each swept over EAx.
void temp2_block3(m5::GridFile& grid, std::vector<float> const& ea) {
    for (std::size_t ip = 0; ip < temp_pz.size(); ++ip) {
        for (float const rs : temp2_rsv) {
            for (float const rp : temp2_rpv) {
                temp2_sweep(grid, temp_pz[ip], temp_pa[ip], rs, rp, 1.0F, 2.0F, 9.5F, ea);
            }
        }
    }
}

// Driver GridTemp2 block 4 inner: Ie x Irs x Irq at fixed (Z, A, Its, Ico).
void temp2_block4_inner(m5::GridFile& grid, float z, float a, float ts, float co) {
    for (float const e : temp_ev) {
        for (float const rs : temp2_rsv) {
            for (float const rq : temp2_rqv) {
                grid.add(line_temp2(z, a, e, rs, rq, ts, co, 9.5F));
            }
        }
    }
}

// Driver GridTemp2 block 4: (PZ, PA) x Its x Ico x Ie x Irs x Irq (Rqv passed as Rpair).
void temp2_block4(m5::GridFile& grid) {
    for (std::size_t ip = 0; ip < temp_pz.size(); ++ip) {
        for (float const ts : tsv_list) {
            for (float const co : cov_list) {
                temp2_block4_inner(grid, temp_pz[ip], temp_pa[ip], ts, co);
            }
        }
    }
}

// Driver GridTemp2 block 5: (Z, A) = (92, 236), one parameter changed per EAx sweep, in this order.
void temp2_block5(m5::GridFile& grid, std::vector<float> const& ea) {
    temp2_sweep(grid, 92.0F, 236.0F, 0.0F, 0.0F, 0.5F, 2.0F, 9.5F, ea);
    temp2_sweep(grid, 92.0F, 236.0F, 0.0F, 0.0F, 1.0F, 0.0F, 9.5F, ea);
    temp2_sweep(grid, 92.0F, 236.0F, 0.0F, 0.0F, 1.0F, 4.0F, 9.5F, ea);
    temp2_sweep(grid, 92.0F, 236.0F, -2.5F, 0.0F, 1.0F, 2.0F, 9.5F, ea);
    temp2_sweep(grid, 92.0F, 236.0F, 1.5F, 0.0F, 1.0F, 2.0F, 9.5F, ea);
    temp2_sweep(grid, 92.0F, 236.0F, 0.0F, 0.5F, 1.0F, 2.0F, 9.5F, ea);
    temp2_sweep(grid, 92.0F, 236.0F, 0.0F, -1.0F, 1.0F, 2.0F, 9.5F, ea);
}

// Driver GridTemp2 random: Randomize 5106, 3; Zr, Ar, Er, Rs, Rp, Tr, Cr, Hr.
void temp2_random(m5::GridFile& random_grid, gef::fb::FbMtRng& rng) {
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const zr = draw_int(rng, 10.0, 97.0);
        std::int64_t const ar = draw_int(rng, 20.0, 237.0);
        float const er = m5::draw(rng, -12.0, 40.0);
        float const rs = m5::draw(rng, -10.0, 5.0);
        float const rp = m5::draw(rng, -2.0, 2.0);
        float const tr = m5::draw(rng, 0.5, 1.5);
        float const cr = m5::draw(rng, 0.0, 4.0);
        float const hr = m5::draw(rng, 0.0, 15.0);
        random_grid.add(
            line_temp2(static_cast<float>(zr), static_cast<float>(ar), er, rs, rp, tr, cr, hr));
    }
}

// Driver GridTrusanov block 1: Ai 1..240 x Ie 0..2000 (EAx), E first, A = Ai.
void trusanov_block1(m5::GridFile& grid, std::vector<float> const& ea) {
    for (std::int64_t ai = 1; ai <= 240; ++ai) {
        for (std::size_t ie = 0; ie <= 2000; ++ie) {
            grid.add(line_trusanov(ea[ie], static_cast<float>(ai)));
        }
    }
}

// Driver GridTrusanov block 2: J 0..956 with J mod 4 = 0 skipped, A = M5_Axis(1, 0.25, J);
// Ime 0..100, E = EAx(20 * Ime).
void trusanov_block2(m5::GridFile& grid, std::vector<float> const& ea) {
    for (std::int64_t j = 0; j <= 956; ++j) {
        if (j % 4 == 0) {
            continue;
        }
        float const a = m5::axis(1.0, 0.25, j);
        for (std::size_t ime = 0; ime <= 100; ++ime) {
            grid.add(line_trusanov(ea[20 * ime], a));
        }
    }
}

} // namespace

TEST_CASE("physics: U_alev_ld equals BASIC on the driver grids", "[T1][physics][slow]") {
    m5::GridFile grid("U_alev_ld_grid.txt", "U_alev_ld", s_alev);
    alev_grid(grid);
    m5::check_grid("m5-level_density", grid);

    m5::GridFile random_grid("U_alev_ld_random.txt", "U_alev_ld", s_alev);
    gef::fb::FbMtRng rng(5101);
    for (int i = 0; i < n_random; ++i) {
        float const zr = m5::draw(rng, 0.0, 300.0);
        float const ar = m5::draw(rng, 0.0, 300.0);
        random_grid.add(line_alev(zr, ar));
    }
    m5::check_grid("m5-level_density", random_grid);
}

TEST_CASE("physics: U_levdens equals BASIC on the driver grids", "[T1][physics][slow]") {
    check_ld_grid(ld_cases[0]);
}

TEST_CASE("physics: U_levdens_Egidy equals BASIC on the driver grids", "[T1][physics][slow]") {
    check_ld_grid(ld_cases[1]);
}

TEST_CASE("physics: U_levdens_FG equals BASIC on the driver grids", "[T1][physics][slow]") {
    check_ld_grid(ld_cases[2]);
}

TEST_CASE("physics: U_Temp equals BASIC on the driver grids", "[T1][physics][slow]") {
    auto const tables = level_density_tables();
    auto const ea = energy_axis();
    m5::GridFile grid("U_Temp_grid.txt", "U_Temp", s_temp);
    temp_block1(grid, tables);
    temp_block2(grid, tables);
    temp_block3(grid, tables, ea);
    temp_block4(grid, tables);
    temp_block5(grid, tables, ea);
    m5::check_grid("m5-level_density", grid);

    m5::GridFile random_grid("U_Temp_random.txt", "U_Temp", s_temp);
    gef::fb::FbMtRng rng(5105);
    temp_random(random_grid, tables, rng);
    m5::check_grid("m5-level_density", random_grid);
}

TEST_CASE("physics: U_Temp2 equals BASIC on the driver grids", "[T1][physics][slow]") {
    auto const ea = energy_axis();
    m5::GridFile grid("U_Temp2_grid.txt", "U_Temp2", s_temp2);
    temp2_block1(grid);
    temp2_block2(grid);
    temp2_block3(grid, ea);
    temp2_block4(grid);
    temp2_block5(grid, ea);
    m5::check_grid("m5-level_density", grid);

    m5::GridFile random_grid("U_Temp2_random.txt", "U_Temp2", s_temp2);
    gef::fb::FbMtRng rng(5106);
    temp2_random(random_grid, rng);
    m5::check_grid("m5-level_density", random_grid);
}

TEST_CASE("physics: TEgidy equals BASIC on the driver grids", "[T1][physics][slow]") {
    m5::GridFile grid("TEgidy_grid.txt", "TEgidy", s_tegidy);
    for (std::int64_t ia = 0; ia <= 960; ++ia) {
        for (std::int64_t idu = 0; idu <= 30; ++idu) {
            for (float const fred : tegidy_fv) {
                grid.add(line_tegidy(m5::axis(0.0, 0.25, ia), m5::axis(-13.0, 0.5, idu), fred));
            }
        }
    }
    m5::check_grid("m5-level_density", grid);

    m5::GridFile random_grid("TEgidy_random.txt", "TEgidy", s_tegidy);
    gef::fb::FbMtRng rng(5107);
    for (int i = 0; i < n_random; ++i) {
        float const ar = m5::draw(rng, 1.0, 240.0);
        float const dr = m5::draw(rng, -13.0, 2.0);
        float const fr = m5::draw(rng, 0.5, 1.5);
        random_grid.add(line_tegidy(ar, dr, fr));
    }
    m5::check_grid("m5-level_density", random_grid);
}

TEST_CASE("physics: TRusanov equals BASIC on the driver grids", "[T1][physics][slow]") {
    auto const ea = energy_axis();
    m5::GridFile grid("TRusanov_grid.txt", "TRusanov", s_trusanov);
    trusanov_block1(grid, ea);
    trusanov_block2(grid, ea);
    m5::check_grid("m5-level_density", grid);

    m5::GridFile random_grid("TRusanov_random.txt", "TRusanov", s_trusanov);
    gef::fb::FbMtRng rng(5108);
    for (int i = 0; i < n_random; ++i) {
        float const er = m5::draw(rng, 0.0, 15.0);
        float const ar = m5::draw(rng, 1.0, 240.0);
        random_grid.add(line_trusanov(er, ar));
    }
    m5::check_grid("m5-level_density", random_grid);
}

// Table reads outside the table throw std::out_of_range (fb::Array). Every point that the grid
// excludes for this reason is listed here; the in-table neighbours must not throw.
TEST_CASE("physics: level_density rejects table reads outside the table", "[T1][physics]") {
    auto const tables = level_density_tables();
    REQUIRE_THROWS_AS(physics::u_levdens_fg(tables, 137, 233, 0.0F, 0, 0, 1.0F, 2.0F, 9.5F, 1.0F),
                      std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_levdens_fg(tables, 92, 296, 0.0F, 0, 0, 1.0F, 2.0F, 9.5F, 1.0F),
                      std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_levdens_fg(tables, 92, 91, 0.0F, 0, 0, 1.0F, 2.0F, 9.5F, 1.0F),
                      std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_levdens_fg(tables, 92, 295, 0.0F, 0, 0, 1.0F, 2.0F, 9.5F, 1.0F),
                      std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_levdens(tables, 137, 233, 0.0F, 1, 0, 1.0F, 2.0F, 9.5F, 1.0F),
                      std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_levdens_egidy(tables, 92, 296, 0.0F, 1, 0, 1.0F, 2.0F, 9.5F, 1.0F),
                      std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_temp(tables, 137.0F, 233.0F, 0.0F, 1, 0, 1.0F, 2.0F, 9.5F),
                      std::out_of_range);
    REQUIRE_NOTHROW(physics::u_levdens_fg(tables, 92, 294, 0.0F, 0, 0, 1.0F, 2.0F, 9.5F, 1.0F));
    REQUIRE_NOTHROW(physics::u_temp(tables, 92.0F, 295.0F, 0.0F, 1, 0, 1.0F, 2.0F, 9.5F));
}

TEST_CASE("physics: level_density replays the captured GEF calls", "[T1][physics]") {
    auto const tables = level_density_tables();
    std::size_t n = 0;
    n += m5::check_replay("U_alev_ld", s_alev, [](std::vector<std::string> const& t) {
        return line_alev(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)));
    });
    n += m5::check_replay("U_levdens", s_levdens, [&tables](std::vector<std::string> const& t) {
        return replay_ld(physics::u_levdens, tables, t);
    });
    n += m5::check_replay("U_levdens_Egidy", s_levdens,
                          [&tables](std::vector<std::string> const& t) {
                              return replay_ld(physics::u_levdens_egidy, tables, t);
                          });
    n += m5::check_replay("U_levdens_FG", s_levdens, [&tables](std::vector<std::string> const& t) {
        return replay_ld(physics::u_levdens_fg, tables, t);
    });
    n += m5::check_replay("U_Temp", s_temp, [&tables](std::vector<std::string> const& t) {
        return replay_temp(tables, t);
    });
    n += m5::check_replay("U_Temp2", s_temp2, [](std::vector<std::string> const& t) {
        return line_temp2(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)), m5::parse_f32(t.at(2)),
                          m5::parse_f32(t.at(3)), m5::parse_f32(t.at(4)), m5::parse_f32(t.at(5)),
                          m5::parse_f32(t.at(6)), m5::parse_f32(t.at(7)));
    });
    n += m5::check_replay("TEgidy", s_tegidy, [](std::vector<std::string> const& t) {
        return line_tegidy(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)), m5::parse_f32(t.at(2)));
    });
    n += m5::check_replay("TRusanov", s_trusanov, [](std::vector<std::string> const& t) {
        return line_trusanov(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)));
    });
    if (n == 0) {
        SKIP("reference store with the M5 arglog captures not available");
    }
}
