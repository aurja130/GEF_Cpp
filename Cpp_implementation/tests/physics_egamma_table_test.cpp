// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// T1 tests of physics/gamma (the P_Egamma_low table) against the driver m5_egamma_table (golden
// m5-egamma_table) and the arglog captures. The grids repeat the driver's
// (harness/drivers/m5_egamma_table.bas).

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "fbrt/gef_math.hpp"
#include "fbrt/rng.hpp"
#include "physics/gamma.hpp"
#include "support/m5.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace {

namespace data = gef::data;
namespace m5 = gef::test::m5;
namespace physics = gef::physics;

// S_PEGL of the driver: the arglog header of the site pegl_table.
constexpr std::string_view s_pegl =
    "in.Zi:f32 in.Ai:f32 in.Ei:f32 in.Tscale:f32 in.Econd:f32 in.Etrans:f32 out.N:i64 "
    "out.Tm:f32 out.betadef:f32 out.gammadef:f32 out.sigMax:f32 out.Eg:f32 out.I:i64 "
    "out.E0(0):f32 out.E0(1):f32 out.E0(2):f32 out.E0(3):f32 out.G0(0):f32 out.G0(1):f32 "
    "out.G0(2):f32 out.G0(3):f32 out.UBound(sigma):i64 out.sigma(0..UBound):f32hash";
constexpr int n_random = 100000;

// The driver's parameter sets: (Tscale, Econd, Etrans).
struct ParamSet {
    float tscale;
    float econd;
    float etrans;
};

// The driver's (TieZ, TieA) pairs.
struct TiePair {
    float zi;
    float ai;
};

// The 23 tokens of one call, as the driver's PEglLine logs them: the six inputs echoed, then the
// 17 outputs.
std::string line_pegl(data::TableSet const& tables, float zi, float ai, float ei, float tscale,
                      float econd, float etrans) {
    auto const t = physics::p_egamma_low_table(tables, zi, ai, ei, tscale, econd, etrans);
    return m5::join({m5::f32(zi),
                     m5::f32(ai),
                     m5::f32(ei),
                     m5::f32(tscale),
                     m5::f32(econd),
                     m5::f32(etrans),
                     m5::i64(t.n),
                     m5::f32(t.tm),
                     m5::f32(t.betadef),
                     m5::f32(t.gammadef),
                     m5::f32(t.sig_max),
                     m5::f32(t.eg),
                     m5::i64(t.i),
                     m5::f32(t.e0[0]),
                     m5::f32(t.e0[1]),
                     m5::f32(t.e0[2]),
                     m5::f32(t.e0[3]),
                     m5::f32(t.g0[0]),
                     m5::f32(t.g0[1]),
                     m5::f32(t.g0[2]),
                     m5::f32(t.g0[3]),
                     m5::i64(t.sigma.ubound()),
                     m5::f32_hash(t.sigma.elements())});
}

} // namespace

TEST_CASE("physics: P_Egamma_low table equals BASIC on the driver grids", "[T1][physics]") {
    data::TableSet const tables = data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    constexpr std::array<float, 7> zs = {20.0F, 26.0F, 37.0F, 50.0F, 64.0F, 82.0F, 99.0F};
    constexpr std::array<float, 9> ds = {31.0F, 46.0F,  55.0F,  66.0F, 77.0F,
                                         91.0F, 105.0F, 120.0F, 149.0F};
    constexpr std::array<ParamSet, 3> params = {{
        {.tscale = 1.0F, .econd = 2.0F, .etrans = 9.5F},
        {.tscale = 0.9F, .econd = 1.0F, .etrans = 5.0F},
        {.tscale = 1.2F, .econd = 3.0F, .etrans = 12.0F},
    }};
    constexpr std::array<TiePair, 4> ties = {{
        {.zi = 37.5F, .ai = 92.0F},
        {.zi = 37.0F, .ai = 91.5F},
        {.zi = 37.5F, .ai = 91.5F},
        {.zi = 36.5F, .ai = 91.5F},
    }};

    // EDGE: a running Single sum of 0.1 (K = 1..100), then 0, 0.001, 0.05, 0.1, 25.
    std::array<float, 105> edge{};
    float acc = 0.0F;
    for (std::size_t k = 0; k < 100; ++k) {
        acc += 0.1F;
        edge.at(k) = acc;
    }
    edge.at(100) = 0.0F;
    edge.at(101) = 0.001F;
    edge.at(102) = 0.05F;
    edge.at(103) = 0.1F;
    edge.at(104) = 25.0F;
    ParamSet const& first = params.front();

    m5::GridFile grid("pegl_table_grid.txt", "pegl_table", s_pegl);
    // A: Zi x (Ai - Zi) x parameter set x Ei = 0.05 .. 10.00.
    for (float const zi : zs) {
        for (float const d : ds) {
            for (ParamSet const& p : params) {
                for (std::int64_t ie = 0; ie <= 199; ++ie) {
                    grid.add(line_pegl(tables, zi, zi + d, m5::axis(0.05, 0.05, ie), p.tscale,
                                       p.econd, p.etrans));
                }
            }
        }
    }
    // B: Zi x (Ai - Zi) x EDGE, with the first parameter set.
    for (float const zi : zs) {
        for (float const d : ds) {
            for (float const e : edge) {
                grid.add(line_pegl(tables, zi, zi + d, e, first.tscale, first.econd, first.etrans));
            }
        }
    }
    // C: (Zi, Ai) x parameter set x Ei.
    for (TiePair const& tie : ties) {
        for (ParamSet const& p : params) {
            for (std::int64_t ie = 0; ie <= 199; ++ie) {
                grid.add(line_pegl(tables, tie.zi, tie.ai, m5::axis(0.05, 0.05, ie), p.tscale,
                                   p.econd, p.etrans));
            }
        }
    }
    m5::check_grid("m5-egamma_table", grid);

    gef::fb::FbMtRng rng(6001);
    m5::GridFile random("pegl_table_random.txt", "pegl_table", s_pegl);
    for (int i = 0; i < n_random; ++i) {
        float const zi = gef::fb::floor(m5::draw(rng, 20, 100));
        float const ai = zi + gef::fb::floor(m5::draw(rng, 30, 150));
        float const ei = m5::draw(rng, 0.05, 10);
        float const tscale = m5::draw(rng, 0.8, 1.2);
        float const econd = m5::draw(rng, 0.5, 3);
        float const etrans = m5::draw(rng, 5, 12);
        random.add(line_pegl(tables, zi, ai, ei, tscale, econd, etrans));
    }
    m5::check_grid("m5-egamma_table", random);
}

TEST_CASE("physics: P_Egamma_low table replays the captured GEF calls", "[T1][physics]") {
    data::TableSet const tables = data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    std::size_t const n =
        m5::check_replay("pegl_table", s_pegl, [&tables](std::vector<std::string> const& t) {
            return line_pegl(tables, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)),
                             m5::parse_f32(t.at(2)), m5::parse_f32(t.at(3)), m5::parse_f32(t.at(4)),
                             m5::parse_f32(t.at(5)));
        });
    if (n == 0) {
        SKIP("reference store with the M5 arglog captures not available");
    }
}
