// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// T1 tests of physics/barriers (BFTF, BFTFA, BFTFB) against the driver m5_barriers (golden
// m5-barriers-2) and the arglog captures. The grids repeat the driver's
// (harness/drivers/m5_barriers.bas).

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "fbrt/rng.hpp"
#include "fbrt/text.hpp"
#include "physics/barriers.hpp"
#include "support/m5.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace {

namespace m5 = gef::test::m5;
namespace physics = gef::physics;

constexpr std::string_view s_barrier = "RZ:f32 RA:f32 I_Switch:i64 result:f32";
constexpr int n_random = 100000;

// The undefined options of the driver: (RZ, RA) with I_Switch -1 and 7.
constexpr std::array<std::pair<float, float>, 3> undefined_points = {
    {{60.0F, 120.0F}, {92.0F, 236.0F}, {135.0F, 336.0F}}};
constexpr std::array<std::int64_t, 2> undefined_switches = {-1, 7};

using BarrierFn = physics::BftfResult (*)(gef::data::TableSet const&, float, float, std::int64_t);

// The barrier tables (BEldmTF, BEexp, ShellMO): GEF's table files, as the driver includes them.
gef::data::TableSet barrier_tables() {
    return gef::data::load_tables(gef::data::ProgramData(gef::data::NuclideData::Jeff33));
}

// One line of the driver's LineOf: the inputs echoed, then the result recomputed.
std::string line_barrier(BarrierFn barrier, gef::data::TableSet const& tables, float rz, float ra,
                         std::int64_t i_switch) {
    auto const r = barrier(tables, rz, ra, i_switch);
    // GEF.bas:17730-17731: `Case Else` prints "Undefined option in BFTF" (I_Switch outside 0..6);
    // BFTFA and BFTFB pass the switch to BFTF unchanged.
    if (r.print_undefined_option != (i_switch < 0 || i_switch > 6)) {
        FAIL("BFTF print flag " << r.print_undefined_option << " for I_Switch " << i_switch);
    }
    return m5::join({m5::f32(rz), m5::f32(ra), m5::i64(i_switch), m5::f32(r.value)});
}

// The driver's Structured, in its loop order: the integer grid, the undefined options, the quarter
// steps and the RX boundary.
void add_structured(m5::GridFile& grid, BarrierFn barrier, gef::data::TableSet const& tables) {
    // Integer grid: RZ = Z, RA = Z + N with Z = 1..135 (outer), N = 1..202, I_Switch = 0..6.
    for (std::int64_t iz = 1; iz <= 135; ++iz) {
        for (std::int64_t kn = 1; kn <= 202; ++kn) {
            for (std::int64_t isw = 0; isw <= 6; ++isw) {
                grid.add(line_barrier(barrier, tables, static_cast<float>(iz),
                                      static_cast<float>(iz + kn), isw));
            }
        }
    }
    // Undefined options; (60, 120) also has RX = 30 exactly (quirk Q-037).
    for (auto const& [rz, ra] : undefined_points) {
        for (std::int64_t const isw : undefined_switches) {
            grid.add(line_barrier(barrier, tables, rz, ra, isw));
        }
    }
    // Quarter steps: RZ = M5_Axis(84, 0.25, K) (K = 0..48, outer), RA = M5_Axis(225, 0.25, J)
    // (J = 0..80), I_Switch = 0..6.
    for (std::int64_t k = 0; k <= 48; ++k) {
        for (std::int64_t j = 0; j <= 80; ++j) {
            for (std::int64_t isw = 0; isw <= 6; ++isw) {
                grid.add(line_barrier(barrier, tables, m5::axis(84, 0.25, k),
                                      m5::axis(225, 0.25, j), isw));
            }
        }
    }
    // RX boundary: RZ = M5_Axis(59.5, 0.25, K) (K = 0..4, outer), RA = M5_Axis(119.25, 0.25, J)
    // (J = 0..6), I_Switch = 0..6.
    for (std::int64_t k = 0; k <= 4; ++k) {
        for (std::int64_t j = 0; j <= 6; ++j) {
            for (std::int64_t isw = 0; isw <= 6; ++isw) {
                grid.add(line_barrier(barrier, tables, m5::axis(59.5, 0.25, k),
                                      m5::axis(119.25, 0.25, j), isw));
            }
        }
    }
}

// The driver's Randoms: Randomize Seed, 3; per tuple RZ = M5_Draw(84, 107), RA = M5_Draw(210, 265),
// then I_Switch = ILo + Int(Rnd * INum) over the captured range (i_lo, i_count).
void add_random(m5::GridFile& random, BarrierFn barrier, gef::data::TableSet const& tables,
                int seed, std::int64_t i_lo, std::int64_t i_count) {
    gef::fb::FbMtRng rng(seed);
    for (int i = 0; i < n_random; ++i) {
        float const rz = m5::draw(rng, 84, 107);
        float const ra = m5::draw(rng, 210, 265);
        auto const pick =
            static_cast<std::int64_t>(std::floor(rng.rnd() * static_cast<double>(i_count)));
        random.add(line_barrier(barrier, tables, rz, ra, i_lo + pick));
    }
}

} // namespace

TEST_CASE("physics: BFTF equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = barrier_tables();
    m5::GridFile grid("BFTF_grid.txt", "BFTF", s_barrier);
    add_structured(grid, &physics::bftf, tables);
    m5::check_grid("m5-barriers-2", grid);

    m5::GridFile random("BFTF_random.txt", "BFTF", s_barrier);
    add_random(random, &physics::bftf, tables, 5101, 0, 6);
    m5::check_grid("m5-barriers-2", random);
}

TEST_CASE("physics: BFTFA equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = barrier_tables();
    m5::GridFile grid("BFTFA_grid.txt", "BFTFA", s_barrier);
    add_structured(grid, &physics::bftfa, tables);
    m5::check_grid("m5-barriers-2", grid);

    m5::GridFile random("BFTFA_random.txt", "BFTFA", s_barrier);
    add_random(random, &physics::bftfa, tables, 5102, 1, 3);
    m5::check_grid("m5-barriers-2", random);
}

TEST_CASE("physics: BFTFB equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = barrier_tables();
    m5::GridFile grid("BFTFB_grid.txt", "BFTFB", s_barrier);
    add_structured(grid, &physics::bftfb, tables);
    m5::check_grid("m5-barriers-2", grid);

    m5::GridFile random("BFTFB_random.txt", "BFTFB", s_barrier);
    add_random(random, &physics::bftfb, tables, 5103, 0, 4);
    m5::check_grid("m5-barriers-2", random);
}

TEST_CASE("physics: BFTF prints for undefined options as BASIC does", "[T1][physics]") {
    // The driver's console output: the structured grids of BFTF, BFTFA, BFTFB in that order, of
    // which only the undefined options print `Print "Undefined option in BFTF"` (GEF.bas:17731).
    auto const tables = barrier_tables();
    gef::fb::PrintFile console;
    for (BarrierFn const barrier : {&physics::bftf, &physics::bftfa, &physics::bftfb}) {
        for (auto const& [rz, ra] : undefined_points) {
            for (std::int64_t const isw : undefined_switches) {
                REQUIRE(barrier(tables, rz, ra, isw).print_undefined_option);
                console.print("Undefined option in BFTF", gef::fb::PrintEnd::Newline);
            }
        }
    }
    m5::check_text("m5-barriers-2", "stdout.txt", m5::text_lines(console.text()));
}

TEST_CASE("physics: barriers replay the captured GEF calls", "[T1][physics]") {
    auto const tables = barrier_tables();
    std::size_t n = 0;
    n += m5::check_replay("BFTF", s_barrier, [&tables](std::vector<std::string> const& t) {
        return line_barrier(&physics::bftf, tables, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)),
                            m5::parse_i64(t.at(2)));
    });
    n += m5::check_replay("BFTFA", s_barrier, [&tables](std::vector<std::string> const& t) {
        return line_barrier(&physics::bftfa, tables, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)),
                            m5::parse_i64(t.at(2)));
    });
    n += m5::check_replay("BFTFB", s_barrier, [&tables](std::vector<std::string> const& t) {
        return line_barrier(&physics::bftfb, tables, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)),
                            m5::parse_i64(t.at(2)));
    });
    if (n == 0) {
        SKIP("reference store with the M5 arglog captures not available");
    }
}

TEST_CASE("physics: with fix_table_overrun barrier table reads outside the tables throw",
          "[T1][physics]") {
    auto tables = barrier_tables();
    tables.fix_table_overrun = true;
    // I_Switch 1..5 read BEexp (N 0..203 x Z 0..136, as in the masses test) through ame2020; with
    // the fix of QUIRK(Q-042) a read outside it throws std::out_of_range.
    REQUIRE_THROWS_AS(physics::bftf(tables, 137.0F, 137.0F, 1), std::out_of_range);
    REQUIRE_THROWS_AS(physics::bftf(tables, 137.0F, 137.0F, 2), std::out_of_range);
    REQUIRE_THROWS_AS(physics::bftf(tables, 1.0F, 300.0F, 2), std::out_of_range);
    REQUIRE_THROWS_AS(physics::bftfa(tables, 100.0F, 304.0F, 2), std::out_of_range);
    REQUIRE_THROWS_AS(physics::bftfb(tables, 100.0F, 304.0F, 2), std::out_of_range);
}
