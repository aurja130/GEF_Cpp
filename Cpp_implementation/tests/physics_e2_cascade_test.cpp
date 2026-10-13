// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// T1 tests of physics::e2_cascade against both BASIC copies (light GEF.bas:9309-9368, heavy
// 9430-9484): the driver m5_e2_cascade (golden m5-e2_cascade) and the arglog sites e2_light and
// e2_heavy. The grids repeat the driver's (harness/drivers/m5_e2_cascade.bas). The caller's part
// of the BASIC (N_ISO_MAT / ISO_for_MAT at 9318-9321, the counters at 9354-9358) is reproduced
// here as M10 will do it.

#include "data/lookups.hpp"
#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "fbrt/rng.hpp"
#include "physics/gamma.hpp"
#include "support/m5.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace {

namespace data = gef::data;
namespace fb = gef::fb;
namespace m5 = gef::test::m5;
namespace physics = gef::physics;

constexpr std::string_view s_grid_light =
    "in.I_Z_light_sci:i64 in.I_A_light_post:i64 in.I_MAT:i64 in.Jfrag:f32 in.J_frag_light:f32 "
    "in.Spin_gs_light:f32 out.E_E2_tot:f32 out.IfragEff_light:f32 out.beta1:f32 out.alph:f32 "
    "out.N_iso:i64 out.I_iso:i64 out.C_iso_lmd_light:str out.Nglight:i64 out.Ngtot:i64 "
    "out.Egtot1000:f32 out.Ig2_light:i64 out.Array_Eg2_light(1..Ig2_light):f32[]";
constexpr std::string_view s_grid_heavy =
    "in.I_Z_heavy_sci:i64 in.I_A_heavy_post:i64 in.I_MAT:i64 in.Jfrag:f32 in.J_frag_heavy:f32 "
    "in.Spin_gs_heavy:f32 out.E_E2_tot:f32 out.IfragEff_heavy:f32 out.beta1:f32 out.alph:f32 "
    "out.N_iso:i64 out.I_iso:i64 out.C_iso_lmd_heavy:str out.Ngheavy:i64 out.Ngtot:i64 "
    "out.Egtot1000:f32 out.Ig2_heavy:i64 out.Array_Eg2_heavy(1..Ig2_heavy):f32[]";
constexpr std::string_view s_light =
    "in.I_Z_light_sci:i64 in.I_A_light_post:i64 in.I_MAT:i64 in.I_DelGam:i64 in.Jfrag:f32 "
    "in.J_frag_light:f32 in.Spin_gs_light:f32 in.N_iso:i64 in.I_iso:i64 in.Nglight:i64 "
    "in.Ngtot:i64 in.Egtot1000:f32 in.Ig2_light:i64 out.E_E2_tot:f32 out.IfragEff_light:f32 "
    "out.beta1:f32 out.alph:f32 out.N_iso:i64 out.I_iso:i64 out.C_iso_lmd_light:str out.J:f32 "
    "out.K:f32 out.RJeff:f32 out.Eg:f32 out.Nspectrum:i64 out.Nglight:i64 out.Ngtot:i64 "
    "out.Egtot1000:f32 out.Ig2_light:i64 out.Array_Eg2_light(1..Ig2_light):f32[]";
constexpr std::string_view s_heavy =
    "in.I_Z_heavy_sci:i64 in.I_A_heavy_post:i64 in.I_MAT:i64 in.I_DelGam:i64 in.Jfrag:f32 "
    "in.J_frag_heavy:f32 in.Spin_gs_heavy:f32 in.N_iso:i64 in.I_iso:i64 in.Ngheavy:i64 "
    "in.Ngtot:i64 in.Egtot1000:f32 in.Ig2_heavy:i64 in.E_E2_tot:f32 out.E_E2_tot:f32 "
    "out.IfragEff_heavy:f32 out.beta1:f32 out.alph:f32 out.N_iso:i64 out.I_iso:i64 "
    "out.C_iso_lmd_heavy:str out.J:f32 out.K:f32 out.RJeff:f32 out.Eg:f32 out.Nspectrum:i64 "
    "out.Ngheavy:i64 out.Ngtot:i64 out.Egtot1000:f32 out.Ig2_heavy:i64 "
    "out.Array_Eg2_heavy(1..Ig2_heavy):f32[]";
constexpr int n_random = 100000;
constexpr std::string_view golden = "m5-e2_cascade";

data::TableSet const& jeff33() {
    static data::TableSet const tables =
        data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    return tables;
}

// One copy as GEF runs it, with the caller's parts: GEF.bas:9318-9321 (I_iso is only assigned
// when N_iso > 0, otherwise the incoming value remains) and the counters of 9354-9358.
struct Call {
    std::int64_t n_iso = 0;
    std::int64_t i_iso = 0;
    physics::E2Cascade r;
    std::int64_t ng = 0;
    std::int64_t ngtot = 0;
    float egtot1000 = 0.0F;
};

Call run(data::TableSet const& tables, std::int64_t iz, std::int64_t ia, std::int64_t imat,
         float jfrag, float j_frag, float spin_gs, std::int64_t i_iso_in, std::int64_t ng,
         std::int64_t ngtot, float egtot1000) {
    Call c;
    c.n_iso = data::n_iso_mat(tables, imat);
    c.i_iso = c.n_iso > 0 ? data::iso_for_mat(tables, imat) : i_iso_in;
    c.r = physics::e2_cascade(tables, iz, ia, jfrag, j_frag, spin_gs, c.n_iso, c.i_iso);
    c.ng = ng;
    c.ngtot = ngtot;
    c.egtot1000 = egtot1000;
    for (float const eg : c.r.gammas) {
        // GEF.bas:9354-9358: Nspectrum = Int(Eg*1000 + 0.5); counted when > 0.
        std::int64_t const nspectrum = fb::d2l(std::floor(static_cast<double>(eg * 1000.0F) + 0.5));
        if (nspectrum > 0) {
            ++c.ng;
            ++c.ngtot;
            c.egtot1000 = c.egtot1000 + (eg * 1000.0F);
        }
    }
    return c;
}

std::string live_outs(Call const& c) {
    return m5::join({m5::f32(c.r.e_e2_tot), m5::f32(c.r.ifrag_eff), m5::f32(c.r.beta1),
                     m5::f32(c.r.alph), m5::i64(c.n_iso), m5::i64(c.i_iso),
                     m5::str(c.r.c_iso_lmd)});
}

std::string counters(Call const& c) {
    return m5::join({m5::i64(c.ng), m5::i64(c.ngtot), m5::f32(c.egtot1000),
                     m5::i64(static_cast<std::int64_t>(c.r.gammas.size())),
                     m5::f32_list(c.r.gammas)});
}

// The driver's GridLine: counters and I_iso start at 0.
std::string grid_line(data::TableSet const& tables, std::int64_t iz, std::int64_t ia,
                      std::int64_t imat, float jf, float jfr, float sg) {
    Call const c = run(tables, iz, ia, imat, jf, jfr, sg, 0, 0, 0, 0.0F);
    return m5::join({m5::i64(iz), m5::i64(ia), m5::i64(imat), m5::f32(jf), m5::f32(jfr),
                     m5::f32(sg), live_outs(c), counters(c)});
}

// The driver's SynthSet.
void synth_set(data::IsoProp& iso, int pattern) {
    std::array<float, 11> spi{};
    std::array<float, 11> exc{};
    std::int64_t ns = 0;
    auto const sg = [](double x) { return static_cast<float>(x); };
    switch (pattern) {
    case 0:
        ns = 2;
        spi = {0, 0, 4};
        exc = {0, 0, sg(0.5)};
        break;
    case 1:
        ns = 3;
        spi = {0, sg(1.5), sg(5.5), sg(10.5)};
        exc = {0, 0, sg(0.1), sg(1.25)};
        break;
    case 2:
        ns = 10;
        for (std::size_t i = 1; i <= 10; ++i) {
            spi.at(i) = static_cast<float>(2 * (i - 1));
            exc.at(i) = static_cast<float>(0.1 * static_cast<double>(i - 1));
        }
        break;
    case 3:
        ns = 1;
        spi = {0, 6};
        exc = {0, 0};
        break;
    default:
        ns = 4;
        spi = {0, 2, 2, 7, sg(7.5)};
        exc = {0, 0, sg(0.2), sg(0.3), sg(2.5)};
        break;
    }
    iso.n_states = ns;
    for (std::int64_t i = 1; i <= 10; ++i) {
        iso.r_spi(i) = spi.at(static_cast<std::size_t>(i));
        iso.r_exc(i) = exc.at(static_cast<std::size_t>(i));
    }
}

// The driver's nuclide lists: ground states inside DEFOtab, with (A) and without (B) isomers,
// and the nuclide whose Isotab entry grid C overwrites.
struct Nuclides {
    std::vector<std::int64_t> iso_list;
    std::vector<std::int64_t> plain_list;
    std::int64_t synth_mat = 0;
};

Nuclides nuclides(data::TableSet const& tables) {
    Nuclides out;
    for (std::int64_t m = 1; m <= tables.nuc_tab.ubound() - 6; ++m) {
        data::NucProp const& n = tables.nuc_tab(m);
        if (n.i_iso == 0 && n.i_z >= 1 && n.i_z <= 136 && n.i_a - n.i_z >= 0 &&
            n.i_a - n.i_z <= 236) {
            (data::n_iso_mat(tables, m) > 0 ? out.iso_list : out.plain_list).push_back(m);
        }
    }
    for (std::int64_t const m : out.iso_list) {
        if (tables.nuc_tab(m).i_z >= 30) {
            out.synth_mat = m;
            break;
        }
    }
    return out;
}

constexpr std::array<float, 4> offs = {0.0F, 0.3F, 0.5F, 1.0F};

// Grids A and B.
void add_real(m5::GridFile& grid, data::TableSet const& tables, Nuclides const& nuc) {
    for (std::int64_t const m : nuc.iso_list) {
        data::NucProp const& n = tables.nuc_tab(m);
        for (std::int64_t i = 0; i <= 80; ++i) {
            for (std::size_t o = 0; o < 2; ++o) {
                float const jf = m5::axis(0, 0.5, i);
                grid.add(
                    grid_line(tables, n.i_z, n.i_a, m, jf, jf + n.r_spi + offs.at(2 * o), n.r_spi));
            }
        }
    }
    for (std::size_t l = 0; l < nuc.plain_list.size(); l += 10) {
        std::int64_t const m = nuc.plain_list.at(l);
        data::NucProp const& n = tables.nuc_tab(m);
        for (std::int64_t i = 0; i <= 40; ++i) {
            float const jf = m5::axis(0, 2, i);
            grid.add(grid_line(tables, n.i_z, n.i_a, m, jf, jf + n.r_spi, n.r_spi));
        }
    }
}

// Grid C: the synthetic Isotab states.
void add_synthetic(m5::GridFile& grid, data::TableSet const& tables, Nuclides const& nuc) {
    constexpr std::array<float, 3> sgs = {0.0F, 0.5F, 1.5F};
    data::TableSet synth = tables;
    std::int64_t const ii = data::iso_for_mat(tables, nuc.synth_mat);
    data::NucProp const& sn = tables.nuc_tab(nuc.synth_mat);
    for (int p = 0; p <= 4; ++p) {
        synth_set(synth.isotab(ii), p);
        for (std::int64_t i = 0; i <= 62; ++i) {
            for (float const off : offs) {
                for (float const sg : sgs) {
                    float const jf = m5::axis(-1, 0.5, i);
                    grid.add(grid_line(synth, sn.i_z, sn.i_a, nuc.synth_mat, jf, jf + off, sg));
                }
            }
        }
    }
}

void check_grids(int heavy) {
    data::TableSet const& tables = jeff33();
    Nuclides const nuc = nuclides(tables);
    std::string const side = heavy == 0 ? "e2_light" : "e2_heavy";
    std::string_view const schema = heavy == 0 ? s_grid_light : s_grid_heavy;

    m5::GridFile grid(side + "_grid.txt", side, schema);
    add_real(grid, tables, nuc);
    add_synthetic(grid, tables, nuc);
    m5::check_grid(golden, grid);

    fb::FbMtRng rng(7001 + heavy);
    m5::GridFile random(side + "_random.txt", side, schema);
    auto const n_iso_list = static_cast<double>(nuc.iso_list.size());
    for (int r = 0; r < n_random; ++r) {
        std::int64_t const idx = fb::f2l(fb::floor(m5::draw(rng, 0, n_iso_list)));
        float const jf = fb::floor(m5::draw(rng, -4, 24));
        float const off = m5::draw(rng, -1, 4);
        std::int64_t const m = nuc.iso_list.at(static_cast<std::size_t>(idx));
        data::NucProp const& n = tables.nuc_tab(m);
        random.add(grid_line(tables, n.i_z, n.i_a, m, jf, jf + off, n.r_spi));
    }
    m5::check_grid(golden, random);
}

// Replay: the dead scope locals J, K, RJeff, Eg, Nspectrum are echoed (written before they are
// read on every path through GEF.bas:9240-9486, heavy Nspectrum at 9390, and invisible after
// End Scope at 9486); every other token is recomputed.
std::size_t check_replay(int heavy) {
    data::TableSet const& tables = jeff33();
    std::size_t const o = heavy == 0 ? 13 : 14; // first out.* token
    return m5::check_replay(heavy == 0 ? "e2_light" : "e2_heavy", heavy == 0 ? s_light : s_heavy,
                            [&](std::vector<std::string> const& t) {
                                Call const c =
                                    run(tables, m5::parse_i64(t.at(0)), m5::parse_i64(t.at(1)),
                                        m5::parse_i64(t.at(2)), m5::parse_f32(t.at(4)),
                                        m5::parse_f32(t.at(5)), m5::parse_f32(t.at(6)),
                                        m5::parse_i64(t.at(8)), m5::parse_i64(t.at(9)),
                                        m5::parse_i64(t.at(10)), m5::parse_f32(t.at(11)));
                                std::string line = t.at(0);
                                for (std::size_t i = 1; i < o; ++i) {
                                    line += " " + t.at(i);
                                }
                                line += " " + live_outs(c);
                                for (std::size_t i = o + 7; i <= o + 11; ++i) {
                                    line += " " + t.at(i);
                                }
                                return line + " " + counters(c);
                            });
}

} // namespace

TEST_CASE("physics: E2 cascade equals the light copy on the driver grids", "[T1][physics]") {
    check_grids(0);
}

TEST_CASE("physics: E2 cascade equals the heavy copy on the driver grids", "[T1][physics]") {
    check_grids(1);
}

TEST_CASE("physics: E2 cascade replays the captured light and heavy cascades", "[T1][physics]") {
    std::size_t const n = check_replay(0) + check_replay(1);
    if (n == 0) {
        SKIP("reference store with the M5 arglog captures not available");
    }
}

TEST_CASE("physics: E2 cascade reads outside DEFOtab throw", "[T1][physics]") {
    data::TableSet const& tables = jeff33();
    // DEFOtab is (N 0..236) x (Z 0..136).
    REQUIRE_THROWS_AS(physics::e2_cascade(tables, 137, 250, 4.0F, 4.0F, 0.0F, 0, 0),
                      std::out_of_range);
    REQUIRE_THROWS_AS(physics::e2_cascade(tables, 50, 287, 4.0F, 4.0F, 0.0F, 0, 0),
                      std::out_of_range);
    REQUIRE_NOTHROW(physics::e2_cascade(tables, 136, 372, 4.0F, 4.0F, 0.0F, 0, 0));
}

TEST_CASE("physics: E2 cascade throws beyond Array_Eg2(100)", "[T1][physics]") {
    data::TableSet const& tables = jeff33();
    // Jfrag = 202 would store gamma 101 (J = 202 .. 2): beyond Array_Eg2_<side>(100).
    REQUIRE_NOTHROW(physics::e2_cascade(tables, 50, 120, 200.0F, 200.0F, 0.0F, 0, 0));
    REQUIRE_THROWS_AS(physics::e2_cascade(tables, 50, 120, 202.0F, 202.0F, 0.0F, 0, 0),
                      std::out_of_range);
}
