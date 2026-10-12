// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// T1 tests of physics/helpers (Gaussintegral, Bell, U_Box, EVEN_ODD) against the driver
// m5_helpers (golden m5-helpers) and the arglog captures. The grids repeat the driver's
// (harness/drivers/m5_helpers.bas).

#include "fbrt/rng.hpp"
#include "physics/helpers.hpp"
#include "support/m5.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <cstdint>
#include <string>
#include <vector>

namespace {

namespace m5 = gef::test::m5;
namespace physics = gef::physics;

constexpr std::string_view s_gauss = "R_x:f32 R_sigma:f32 result:f32";
constexpr std::string_view s_bell = "xpos:f32 xleft:f32 xright:f32 result:f32";
constexpr std::string_view s_box = "x:f32 sigma:f32 width:f32 result:f32";
constexpr std::string_view s_eo = "R_ORIGIN:f32 R_EVEN_ODD:f32 result:i64";
constexpr int n_random = 100000;

std::string line_gauss(float x, float s) {
    return m5::join({m5::f32(x), m5::f32(s), m5::f32(physics::gaussintegral(x, s))});
}

std::string line_bell(float x, float l, float r) {
    return m5::join({m5::f32(x), m5::f32(l), m5::f32(r), m5::f32(physics::bell(x, l, r))});
}

std::string line_box(float x, float s, float w) {
    return m5::join({m5::f32(x), m5::f32(s), m5::f32(w), m5::f32(physics::u_box(x, s, w))});
}

std::string line_eo(float x, float e) {
    return m5::join({m5::f32(x), m5::f32(e), m5::i64(physics::even_odd(x, e))});
}

} // namespace

TEST_CASE("physics: Gaussintegral equals BASIC on the driver grids", "[T1][physics]") {
    constexpr std::array<float, 12> sig = {0.0F, -0.0F, -1.0F, 1E-30F, 2E-4F, 0.01F,
                                           0.1F, 0.5F,  1.0F,  2.0F,   5.0F,  100.0F};
    m5::GridFile grid("Gaussintegral_grid.txt", "Gaussintegral", s_gauss);
    for (float const s : sig) {
        for (std::int64_t i = 0; i <= 2000; ++i) {
            grid.add(line_gauss(m5::axis(-10, 0.01, i), s));
        }
    }
    m5::check_grid("m5-helpers", grid);

    gef::fb::FbMtRng rng(5001);
    m5::GridFile random("Gaussintegral_random.txt", "Gaussintegral", s_gauss);
    for (int i = 0; i < n_random; ++i) {
        float const x = m5::draw(rng, -50, 80);
        float const s = m5::draw(rng, 0, 6);
        random.add(line_gauss(x, s));
    }
    m5::check_grid("m5-helpers", random);
}

TEST_CASE("physics: Bell equals BASIC on the driver grids", "[T1][physics]") {
    constexpr std::array<float, 6> bl = {45.0F, 0.0F, 10.0F, 10.0F, 5.0F, 45.0001F};
    constexpr std::array<float, 6> br = {49.5F, 1.0F, 10.0F, 10.001F, 4.0F, 45.0021F};
    m5::GridFile grid("Bell_grid.txt", "Bell", s_bell);
    for (std::size_t j = 0; j < bl.size(); ++j) {
        for (std::int64_t i = 0; i <= 3100; ++i) {
            grid.add(line_bell(m5::axis(-5, 0.05, i), bl.at(j), br.at(j)));
        }
    }
    m5::check_grid("m5-helpers", grid);

    gef::fb::FbMtRng rng(5002);
    m5::GridFile random("Bell_random.txt", "Bell", s_bell);
    for (int i = 0; i < n_random; ++i) {
        float const x = m5::draw(rng, 0, 150);
        float const l = m5::draw(rng, 0, 100);
        // CSng(L + 20 * Rnd): L widened to Double.
        auto const r = static_cast<float>(static_cast<double>(l) + (20.0 * rng.rnd()));
        random.add(line_bell(x, l, r));
    }
    m5::check_grid("m5-helpers", random);
}

TEST_CASE("physics: U_Box equals BASIC on the driver grids", "[T1][physics]") {
    constexpr std::array<float, 6> xs = {4.2F, 1.0F, 0.0F, 1.0F, 0.1F, 4.3F};
    constexpr std::array<float, 6> xw = {11.5F, 1.0F, 1.0F, 0.0F, 20.0F, 12.2F};
    m5::GridFile grid("U_Box_grid.txt", "U_Box", s_box);
    for (std::size_t j = 0; j < xs.size(); ++j) {
        for (std::int64_t i = 0; i <= 2000; ++i) {
            grid.add(line_box(m5::axis(-50, 0.05, i), xs.at(j), xw.at(j)));
        }
    }
    m5::check_grid("m5-helpers", grid);

    gef::fb::FbMtRng rng(5003);
    m5::GridFile random("U_Box_random.txt", "U_Box", s_box);
    for (int i = 0; i < n_random; ++i) {
        float const x = m5::draw(rng, -60, 60);
        float const s = m5::draw(rng, 0, 6);
        float const w = m5::draw(rng, 0, 20);
        random.add(line_box(x, s, w));
    }
    m5::check_grid("m5-helpers", random);
}

TEST_CASE("physics: EVEN_ODD equals BASIC on the driver grids", "[T1][physics]") {
    constexpr std::array<float, 14> eo = {0.0F,  1E-3F, -1E-3F, 9.99E-4F, -9.99E-4F, 0.1F,  0.3F,
                                          -0.3F, 0.99F, 1.0F,   2.0F,     -0.99F,    -1.0F, -2.0F};
    m5::GridFile grid("EVEN_ODD_grid.txt", "EVEN_ODD", s_eo);
    for (float const e : eo) {
        for (std::int64_t i = 0; i <= 13200; ++i) {
            grid.add(line_eo(m5::axis(-2, 0.01, i), e));
        }
    }
    m5::check_grid("m5-helpers", grid);

    gef::fb::FbMtRng rng(5004);
    m5::GridFile random("EVEN_ODD_random.txt", "EVEN_ODD", s_eo);
    for (int i = 0; i < n_random; ++i) {
        float const x = m5::draw(rng, 0, 130);
        float const e = m5::draw(rng, -1.5, 1.5);
        random.add(line_eo(x, e));
    }
    m5::check_grid("m5-helpers", random);
}

TEST_CASE("physics: helpers replay the captured GEF calls", "[T1][physics]") {
    std::size_t n = 0;
    n += m5::check_replay("Gaussintegral", s_gauss, [](std::vector<std::string> const& t) {
        return line_gauss(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)));
    });
    n += m5::check_replay("Bell", s_bell, [](std::vector<std::string> const& t) {
        return line_bell(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)), m5::parse_f32(t.at(2)));
    });
    n += m5::check_replay("U_Box", s_box, [](std::vector<std::string> const& t) {
        return line_box(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)), m5::parse_f32(t.at(2)));
    });
    n += m5::check_replay("EVEN_ODD", s_eo, [](std::vector<std::string> const& t) {
        return line_eo(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)));
    });
    if (n == 0) {
        SKIP("reference store with the M5 arglog captures not available");
    }
}
