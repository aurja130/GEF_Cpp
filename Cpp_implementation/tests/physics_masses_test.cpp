// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// T1 tests of physics/masses (LyMass, LyPair, FEDEFOLys, LDMass, AME2020, U_SHELL, U_SHELL_exp,
// U_SHELL_EO_exp, U_MASS, ECOUL, U_Valid, U_Delta_S0, U_Q_beta_minus) against the driver
// m5_masses (golden m5-masses-2) and the arglog captures. The grids repeat the driver's
// (harness/drivers/m5_masses.bas).

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "fbrt/rng.hpp"
#include "fbrt/text.hpp"
#include "physics/masses.hpp"
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

namespace m5 = gef::test::m5;
namespace physics = gef::physics;

constexpr std::string_view s_lymass = "Z:f32 A:f32 beta:f32 result:f32";
constexpr std::string_view s_lypair = "Z:i64 A:i64 result:f32";
constexpr std::string_view s_fedefolys = "Z:f32 A:f32 beta:f32 result:f32";
constexpr std::string_view s_ldmass = "Z:f32 A:f32 beta:f32 result:f32";
constexpr std::string_view s_ame2020 = "Z:i64 A:i64 result:f32";
constexpr std::string_view s_u_shell = "Z:i64 A:i64 result:f32";
constexpr std::string_view s_u_shell_exp = "Z:i64 A:i64 result:f32";
constexpr std::string_view s_u_shell_eo_exp = "Z:i64 A:i64 result:f32";
constexpr std::string_view s_u_mass = "Z:f32 A:f32 result:f32";
constexpr std::string_view s_ecoul =
    "Z1:f32 A1:f32 beta1:f32 Z2:f32 A2:f32 beta2:f32 d:f32 result:f32";
constexpr std::string_view s_u_valid = "I_Z:i64 I_A:i64 result:u8";
constexpr std::string_view s_u_delta_s0 = "I_Z:i64 I_A:i64 result:f32";
constexpr std::string_view s_u_q_beta_minus = "IZ:i64 IA:i64 result:f32";
constexpr int n_random = 100000;

// BetaList and DList of the driver (Single).
constexpr std::array<float, 7> beta_list = {-0.5F, -0.25F, 0.0F, 0.25F, 0.5F, 1.0F, 2.0F};
constexpr std::array<float, 8> d_list = {-1.0F, 0.0F, 0.5F, 1.0F, 2.0F, 5.0F, 10.0F, 20.0F};

// The tables of the masses, from the JEFF-3.3 program data (NucPropJEFF33.bas), the variant the
// M5 driver builds with.
gef::data::TableSet masses_tables() {
    return gef::data::load_tables(gef::data::ProgramData(gef::data::NuclideData::Jeff33));
}

// The driver's RandInt: CLngInt(Int(M5_Draw(Lo, Hi + 0.5))), uniform on the integers [Lo, Hi].
std::int64_t rand_int(gef::fb::FbMtRng& rng, int lo, int hi) {
    return static_cast<std::int64_t>(std::floor(m5::draw(rng, lo, hi + 0.5)));
}

std::string line_ly_mass(float z, float a, float beta) {
    return m5::join({m5::f32(z), m5::f32(a), m5::f32(beta), m5::f32(physics::ly_mass(z, a, beta))});
}

std::string line_ly_pair(std::int64_t z, std::int64_t a) {
    return m5::join({m5::i64(z), m5::i64(a), m5::f32(physics::ly_pair(z, a))});
}

std::string line_fedefo_lys(float z, float a, float beta) {
    return m5::join(
        {m5::f32(z), m5::f32(a), m5::f32(beta), m5::f32(physics::fedefo_lys(z, a, beta))});
}

std::string line_ld_mass(gef::data::TableSet const& tables, float z, float a, float beta) {
    return m5::join(
        {m5::f32(z), m5::f32(a), m5::f32(beta), m5::f32(physics::ld_mass(tables, z, a, beta))});
}

std::string line_ame2020(gef::data::TableSet const& tables, std::int64_t z, std::int64_t a) {
    return m5::join({m5::i64(z), m5::i64(a), m5::f32(physics::ame2020(tables, z, a))});
}

std::string line_u_shell(gef::data::TableSet const& tables, std::int64_t z, std::int64_t a) {
    return m5::join({m5::i64(z), m5::i64(a), m5::f32(physics::u_shell(tables, z, a))});
}

std::string line_u_shell_exp(gef::data::TableSet const& tables, std::int64_t z, std::int64_t a) {
    return m5::join({m5::i64(z), m5::i64(a), m5::f32(physics::u_shell_exp(tables, z, a))});
}

std::string line_u_shell_eo_exp(gef::data::TableSet const& tables, std::int64_t z, std::int64_t a) {
    return m5::join({m5::i64(z), m5::i64(a), m5::f32(physics::u_shell_eo_exp(tables, z, a))});
}

// One U_MASS line. The flag must be set exactly when BASIC prints (GEF.bas:16315); the print
// itself, `Print "U_Mass: Z, A",Z,A` (GEF.c:12736-12742), goes to `console` when given.
std::string line_u_mass(gef::data::TableSet const& tables, float z, float a,
                        gef::fb::PrintFile* console = nullptr) {
    auto const r = physics::u_mass(tables, z, a);
    if (r.print_negative_input != (z < 0.0F || a < 0.0F)) {
        FAIL("U_MASS print flag " << r.print_negative_input << " for Z " << z << ", A " << a);
    }
    if (r.print_negative_input && console != nullptr) {
        console->print("U_Mass: Z, A", gef::fb::PrintEnd::Pad);
        console->print(z, gef::fb::PrintEnd::Pad);
        console->print(a, gef::fb::PrintEnd::Newline);
    }
    return m5::join({m5::f32(z), m5::f32(a), m5::f32(r.value)});
}

std::string line_ecoul(float z1, float a1, float beta1, float z2, float a2, float beta2, float d) {
    return m5::join({m5::f32(z1), m5::f32(a1), m5::f32(beta1), m5::f32(z2), m5::f32(a2),
                     m5::f32(beta2), m5::f32(d),
                     m5::f32(physics::ecoul(z1, a1, beta1, z2, a2, beta2, d))});
}

std::string line_u_valid(gef::data::TableSet const& tables, std::int64_t iz, std::int64_t ia) {
    return m5::join({m5::i64(iz), m5::i64(ia), m5::u8(physics::u_valid(tables, iz, ia))});
}

std::string line_u_delta_s0(std::int64_t iz, std::int64_t ia) {
    return m5::join({m5::i64(iz), m5::i64(ia), m5::f32(physics::u_delta_s0(iz, ia))});
}

std::string line_u_q_beta_minus(gef::data::TableSet const& tables, std::int64_t iz,
                                std::int64_t ia) {
    return m5::join({m5::i64(iz), m5::i64(ia), m5::f32(physics::u_q_beta_minus(tables, iz, ia))});
}

} // namespace

TEST_CASE("physics: LyMass equals BASIC on the driver grids", "[T1][physics]") {
    m5::GridFile grid("LyMass_grid.txt", "LyMass", s_lymass);
    for (float const beta : beta_list) {
        for (std::int64_t zi = 1; zi <= 120; ++zi) {
            for (std::int64_t ni = 0; ni <= 203; ++ni) {
                auto const z = static_cast<float>(zi);
                auto const a = static_cast<float>(zi + ni);
                grid.add(line_ly_mass(z, a, beta));
            }
        }
    }
    for (std::int64_t k = 0; k <= 476; ++k) {
        for (std::int64_t j = 0; j <= 406; ++j) {
            float const z = m5::axis(1, 0.25, k);
            float const n = m5::axis(0, 0.5, j);
            grid.add(line_ly_mass(z, z + n, 0.25F));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6009);
    m5::GridFile random("LyMass_random.txt", "LyMass", s_lymass);
    for (int i = 0; i < n_random; ++i) {
        float const z = m5::draw(rng, 1, 120);
        float const n = m5::draw(rng, 0, 203);
        float const b = m5::draw(rng, -0.5, 2.5);
        random.add(line_ly_mass(z, z + n, b));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: LyPair equals BASIC on the driver grids", "[T1][physics]") {
    m5::GridFile grid("LyPair_grid.txt", "LyPair", s_lypair);
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 203; ++ni) {
            grid.add(line_ly_pair(zi, zi + ni));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6002);
    m5::GridFile random("LyPair_random.txt", "LyPair", s_lypair);
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const z = rand_int(rng, 10, 107);
        std::int64_t const a = rand_int(rng, 20, 265);
        random.add(line_ly_pair(z, a));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: FEDEFOLys equals BASIC on the driver grids", "[T1][physics]") {
    m5::GridFile grid("FEDEFOLys_grid.txt", "FEDEFOLys", s_fedefolys);
    for (float const beta : beta_list) {
        for (std::int64_t zi = 1; zi <= 120; ++zi) {
            for (std::int64_t ni = 0; ni <= 203; ++ni) {
                auto const z = static_cast<float>(zi);
                auto const a = static_cast<float>(zi + ni);
                grid.add(line_fedefo_lys(z, a, beta));
            }
        }
    }
    for (std::int64_t k = 0; k <= 476; ++k) {
        for (std::int64_t j = 0; j <= 406; ++j) {
            float const z = m5::axis(1, 0.25, k);
            float const n = m5::axis(0, 0.5, j);
            grid.add(line_fedefo_lys(z, z + n, 0.25F));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6010);
    m5::GridFile random("FEDEFOLys_random.txt", "FEDEFOLys", s_fedefolys);
    for (int i = 0; i < n_random; ++i) {
        float const z = m5::draw(rng, 1, 120);
        float const n = m5::draw(rng, 0, 203);
        float const b = m5::draw(rng, -0.5, 2.5);
        random.add(line_fedefo_lys(z, z + n, b));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: LDMass equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = masses_tables();
    m5::GridFile grid("LDMass_grid.txt", "LDMass", s_ldmass);
    for (float const beta : beta_list) {
        for (std::int64_t zi = 1; zi <= 120; ++zi) {
            for (std::int64_t ni = 0; ni <= 203; ++ni) {
                auto const z = static_cast<float>(zi);
                auto const a = static_cast<float>(zi + ni);
                grid.add(line_ld_mass(tables, z, a, beta));
            }
        }
    }
    for (std::int64_t k = 0; k <= 476; ++k) {
        for (std::int64_t j = 0; j <= 406; ++j) {
            float const z = m5::axis(1, 0.25, k);
            float const n = m5::axis(0, 0.5, j);
            grid.add(line_ld_mass(tables, z, z + n, 0.25F));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6011);
    m5::GridFile random("LDMass_random.txt", "LDMass", s_ldmass);
    for (int i = 0; i < n_random; ++i) {
        float const z = m5::draw(rng, 1, 120);
        float const n = m5::draw(rng, 0, 203);
        float const b = m5::draw(rng, -0.5, 2.5);
        random.add(line_ld_mass(tables, z, z + n, b));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: AME2020 equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = masses_tables();
    m5::GridFile grid("AME2020_grid.txt", "AME2020", s_ame2020);
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 203; ++ni) {
            grid.add(line_ame2020(tables, zi, zi + ni));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6001);
    m5::GridFile random("AME2020_random.txt", "AME2020", s_ame2020);
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const z = rand_int(rng, 30, 107);
        std::int64_t const n = rand_int(rng, 0, 203);
        random.add(line_ame2020(tables, z, z + n));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: U_SHELL equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = masses_tables();
    m5::GridFile grid("U_SHELL_grid.txt", "U_SHELL", s_u_shell);
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 203; ++ni) {
            grid.add(line_u_shell(tables, zi, zi + ni));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6003);
    m5::GridFile random("U_SHELL_random.txt", "U_SHELL", s_u_shell);
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const z = rand_int(rng, 10, 106);
        std::int64_t const n = rand_int(rng, 0, 203);
        random.add(line_u_shell(tables, z, z + n));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: U_SHELL_exp equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = masses_tables();
    m5::GridFile grid("U_SHELL_exp_grid.txt", "U_SHELL_exp", s_u_shell_exp);
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 1; ni <= 202; ++ni) {
            grid.add(line_u_shell_exp(tables, zi, zi + ni));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6005);
    m5::GridFile random("U_SHELL_exp_random.txt", "U_SHELL_exp", s_u_shell_exp);
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const z = rand_int(rng, 91, 106);
        std::int64_t const n = rand_int(rng, 127, 173);
        random.add(line_u_shell_exp(tables, z, z + n));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: U_SHELL_EO_exp equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = masses_tables();
    m5::GridFile grid("U_SHELL_EO_exp_grid.txt", "U_SHELL_EO_exp", s_u_shell_eo_exp);
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 203; ++ni) {
            grid.add(line_u_shell_eo_exp(tables, zi, zi + ni));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6004);
    m5::GridFile random("U_SHELL_EO_exp_random.txt", "U_SHELL_EO_exp", s_u_shell_eo_exp);
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const z = rand_int(rng, 91, 106);
        std::int64_t const n = rand_int(rng, 127, 173);
        random.add(line_u_shell_eo_exp(tables, z, z + n));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: U_MASS equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = masses_tables();
    m5::GridFile grid("U_MASS_grid.txt", "U_MASS", s_u_mass);
    for (std::int64_t k = 0; k <= 476; ++k) {
        for (std::int64_t j = 0; j <= 811; ++j) {
            float const z = m5::axis(1, 0.25, k);
            float const n = m5::axis(0, 0.25, j);
            grid.add(line_u_mass(tables, z, z + n));
        }
    }
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 203; ++ni) {
            grid.add(line_u_mass(tables, static_cast<float>(zi), static_cast<float>(zi + ni)));
        }
    }
    // Negative inputs: U_MASS prints; these are the driver's only console lines (stdout.txt).
    constexpr std::array<float, 4> neg_z = {-0.25F, 0.0F, -0.25F, -0.5F};
    constexpr std::array<float, 4> neg_a = {10.0F, -0.25F, -0.25F, 0.5F};
    gef::fb::PrintFile console;
    for (std::size_t i = 0; i < neg_z.size(); ++i) {
        grid.add(line_u_mass(tables, neg_z.at(i), neg_a.at(i), &console));
    }
    m5::check_grid("m5-masses-2", grid);
    m5::check_text("m5-masses-2", "stdout.txt", m5::text_lines(console.text()));

    gef::fb::FbMtRng rng(6012);
    m5::GridFile random("U_MASS_random.txt", "U_MASS", s_u_mass);
    for (int i = 0; i < n_random; ++i) {
        float const z = m5::draw(rng, 29, 93);
        float const n = m5::draw(rng, 0, 203);
        random.add(line_u_mass(tables, z, z + n));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: ECOUL equals BASIC on the driver grids", "[T1][physics]") {
    m5::GridFile grid("ECOUL_grid.txt", "ECOUL", s_ecoul);
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 203; ++ni) {
            grid.add(line_ecoul(static_cast<float>(zi), static_cast<float>(zi + ni), 0.0F, 50.0F,
                                120.0F, 0.0F, 1.0F));
        }
    }
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 203; ++ni) {
            grid.add(line_ecoul(50.0F, 120.0F, 0.0F, static_cast<float>(zi),
                                static_cast<float>(zi + ni), 0.0F, 1.0F));
        }
    }
    for (float const beta1 : beta_list) {
        for (float const beta2 : beta_list) {
            for (float const d : d_list) {
                grid.add(line_ecoul(50.0F, 120.0F, beta1, 50.0F, 120.0F, beta2, d));
            }
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6013);
    m5::GridFile random("ECOUL_random.txt", "ECOUL", s_ecoul);
    for (int i = 0; i < n_random; ++i) {
        float const z1 = m5::draw(rng, 2.5, 105);
        float const n1 = m5::draw(rng, 5, 150);
        float const b1 = m5::draw(rng, -0.2, 2.4);
        float const z2 = m5::draw(rng, 2.5, 105);
        float const n2 = m5::draw(rng, 5, 150);
        float const b2 = m5::draw(rng, -0.2, 2.4);
        float const d = m5::draw(rng, 0, 10);
        random.add(line_ecoul(z1, z1 + n1, b1, z2, z2 + n2, b2, d));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: U_Valid equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = masses_tables();
    m5::GridFile grid("U_Valid_grid.txt", "U_Valid", s_u_valid);
    for (std::int64_t zi = 0; zi <= 136; ++zi) {
        for (std::int64_t ni = 1; ni <= 203; ++ni) {
            grid.add(line_u_valid(tables, zi, zi + ni));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6007);
    m5::GridFile random("U_Valid_random.txt", "U_Valid", s_u_valid);
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const iz = rand_int(rng, 0, 136);
        std::int64_t const n = rand_int(rng, 1, 203);
        random.add(line_u_valid(tables, iz, iz + n));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: U_Delta_S0 equals BASIC on the driver grids", "[T1][physics]") {
    m5::GridFile grid("U_Delta_S0_grid.txt", "U_Delta_S0", s_u_delta_s0);
    for (std::int64_t zi = 1; zi <= 120; ++zi) {
        for (std::int64_t ni = 0; ni <= 203; ++ni) {
            grid.add(line_u_delta_s0(zi, zi + ni));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6008);
    m5::GridFile random("U_Delta_S0_random.txt", "U_Delta_S0", s_u_delta_s0);
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const iz = rand_int(rng, 1, 120);
        std::int64_t const ia = rand_int(rng, 1, 300);
        random.add(line_u_delta_s0(iz, ia));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: U_Q_beta_minus equals BASIC on the driver grids", "[T1][physics]") {
    auto const tables = masses_tables();
    m5::GridFile grid("U_Q_beta_minus_grid.txt", "U_Q_beta_minus", s_u_q_beta_minus);
    for (std::int64_t iz = 1; iz <= 120; ++iz) {
        for (std::int64_t n = 1; n <= 203; ++n) {
            grid.add(line_u_q_beta_minus(tables, iz, iz + n));
        }
    }
    m5::check_grid("m5-masses-2", grid);

    gef::fb::FbMtRng rng(6006);
    m5::GridFile random("U_Q_beta_minus_random.txt", "U_Q_beta_minus", s_u_q_beta_minus);
    for (int i = 0; i < n_random; ++i) {
        std::int64_t const iz = rand_int(rng, 25, 74);
        std::int64_t const n = rand_int(rng, 1, 203);
        random.add(line_u_q_beta_minus(tables, iz, iz + n));
    }
    m5::check_grid("m5-masses-2", random);
}

TEST_CASE("physics: masses replay the captured GEF calls", "[T1][physics]") {
    auto const tables = masses_tables();
    std::size_t n = 0;
    n += m5::check_replay("LyMass", s_lymass, [](std::vector<std::string> const& t) {
        return line_ly_mass(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)), m5::parse_f32(t.at(2)));
    });
    n += m5::check_replay("LyPair", s_lypair, [](std::vector<std::string> const& t) {
        return line_ly_pair(m5::parse_i64(t.at(0)), m5::parse_i64(t.at(1)));
    });
    n += m5::check_replay("FEDEFOLys", s_fedefolys, [](std::vector<std::string> const& t) {
        return line_fedefo_lys(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)),
                               m5::parse_f32(t.at(2)));
    });
    n += m5::check_replay("LDMass", s_ldmass, [&tables](std::vector<std::string> const& t) {
        return line_ld_mass(tables, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)),
                            m5::parse_f32(t.at(2)));
    });
    n += m5::check_replay("AME2020", s_ame2020, [&tables](std::vector<std::string> const& t) {
        return line_ame2020(tables, m5::parse_i64(t.at(0)), m5::parse_i64(t.at(1)));
    });
    n += m5::check_replay("U_SHELL", s_u_shell, [&tables](std::vector<std::string> const& t) {
        return line_u_shell(tables, m5::parse_i64(t.at(0)), m5::parse_i64(t.at(1)));
    });
    n += m5::check_replay(
        "U_SHELL_exp", s_u_shell_exp, [&tables](std::vector<std::string> const& t) {
            return line_u_shell_exp(tables, m5::parse_i64(t.at(0)), m5::parse_i64(t.at(1)));
        });
    n += m5::check_replay(
        "U_SHELL_EO_exp", s_u_shell_eo_exp, [&tables](std::vector<std::string> const& t) {
            return line_u_shell_eo_exp(tables, m5::parse_i64(t.at(0)), m5::parse_i64(t.at(1)));
        });
    n += m5::check_replay("U_MASS", s_u_mass, [&tables](std::vector<std::string> const& t) {
        return line_u_mass(tables, m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)));
    });
    n += m5::check_replay("ECOUL", s_ecoul, [](std::vector<std::string> const& t) {
        return line_ecoul(m5::parse_f32(t.at(0)), m5::parse_f32(t.at(1)), m5::parse_f32(t.at(2)),
                          m5::parse_f32(t.at(3)), m5::parse_f32(t.at(4)), m5::parse_f32(t.at(5)),
                          m5::parse_f32(t.at(6)));
    });
    n += m5::check_replay("U_Valid", s_u_valid, [&tables](std::vector<std::string> const& t) {
        return line_u_valid(tables, m5::parse_i64(t.at(0)), m5::parse_i64(t.at(1)));
    });
    n += m5::check_replay(
        "U_Q_beta_minus", s_u_q_beta_minus, [&tables](std::vector<std::string> const& t) {
            return line_u_q_beta_minus(tables, m5::parse_i64(t.at(0)), m5::parse_i64(t.at(1)));
        });
    if (n == 0) {
        SKIP("reference store with the M5 arglog captures not available");
    }
}

TEST_CASE("physics: mass table reads outside the tables throw", "[T1][physics]") {
    auto const tables = masses_tables();
    // BEldmTF, BEexp and ShellMO are (N 0..203) x (Z 0..136) (data/mass_tables.cpp). Reads outside
    // them throw std::out_of_range (plan D3); the port keeps that behavior.
    REQUIRE_THROWS_AS(physics::ame2020(tables, 137, 137), std::out_of_range);
    REQUIRE_THROWS_AS(physics::ame2020(tables, 1, 300), std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_shell(tables, 1, 300), std::out_of_range);
    // LDMass reads BEexp(CInt(A - Z), CInt(Z)): N = 203.5 rounds to 204 (half to even), 203.25
    // to 203.
    REQUIRE_THROWS_AS(physics::ld_mass(tables, 1.0F, 204.5F, 0.0F), std::out_of_range);
    REQUIRE_NOTHROW(physics::ld_mass(tables, 1.0F, 204.25F, 0.0F));
    // U_SHELL_exp reads AME2020 at (Z, A +- 1) and (Z +- 1, A +- 1): one cell inside the tables.
    REQUIRE_THROWS_AS(physics::u_shell_exp(tables, 50, 50), std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_shell_exp(tables, 50, 253), std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_shell_exp(tables, 0, 100), std::out_of_range);
    REQUIRE_NOTHROW(physics::u_shell_exp(tables, 50, 51));
    REQUIRE_NOTHROW(physics::u_shell_exp(tables, 50, 252));
    // U_MASS: LDMass uses CInt(A - Z), U_SHELL CInt(A) - CInt(Z). At Z = 2.5, A = 205.5 the first
    // is 203 (inside) and the second 206 - 2 = 204 (outside ShellMO).
    REQUIRE_THROWS_AS(physics::u_mass(tables, 2.5F, 205.5F), std::out_of_range);
    REQUIRE_NOTHROW(physics::u_mass(tables, 2.5F, 205.25F));
    REQUIRE_THROWS_AS(physics::u_valid(tables, 80, 80), std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_q_beta_minus(tables, 50, 50), std::out_of_range);
    REQUIRE_THROWS_AS(physics::u_shell_eo_exp(tables, 1, 205), std::out_of_range);
}
