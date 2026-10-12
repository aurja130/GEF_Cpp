// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Masses and energies (MILESTONE_5_PLAN.md section 3, group "masses"), namespace gef::physics.
// Parameters keep their BASIC types (Single -> float, Integer -> std::int64_t); callers convert
// as the generated C does. Table reads go through fb::Array and throw outside the table
// (plan D3).

#pragma once

#include "data/tables.hpp"

#include <cstdint>

namespace gef::physics {

// LyMass (GEF.bas:16110-16137): Lysekil macroscopic mass with deformation beta.
[[nodiscard]] float ly_mass(float z, float a, float beta) noexcept;

// LyPair (GEF.bas:16140-16151): Lysekil pairing energy.
[[nodiscard]] float ly_pair(std::int64_t z, std::int64_t a) noexcept;

// FEDEFOLys (GEF.bas:16211-16214): LyMass(Z,A,beta) - LyMass(Z,A,0).
[[nodiscard]] float fedefo_lys(float z, float a, float beta) noexcept;

// LDMass (GEF.bas:16217-16236): BEldmTF/BEexp table mass plus the Lysekil deformation energy.
[[nodiscard]] float ld_mass(data::TableSet const& tables, float z, float a, float beta);

// AME2020 (GEF.bas:16238-16259).
[[nodiscard]] float ame2020(data::TableSet const& tables, std::int64_t iz, std::int64_t ia);

// U_SHELL (GEF.bas:16261-16271): ShellMO(N, Z), positive values scaled by 0.3.
[[nodiscard]] float u_shell(data::TableSet const& tables, std::int64_t z, std::int64_t a);

// U_SHELL_exp (GEF.bas:16273-16292).
[[nodiscard]] float u_shell_exp(data::TableSet const& tables, std::int64_t iz, std::int64_t ia);

// U_SHELL_EO_exp (GEF.bas:16294-16306).
[[nodiscard]] float u_shell_eo_exp(data::TableSet const& tables, std::int64_t iz,
                                   std::int64_t ia);

// U_MASS (GEF.bas:16310-16323). With Z < 0 or A < 0 BASIC first prints
// `Print "U_Mass: Z, A",Z,A` to the console (GEF.bas:16316); here the function only reports
// that in `print_negative_input` and the caller prints (plan D7).
struct UMassResult {
    float value = 0.0F;
    bool print_negative_input = false;
};
[[nodiscard]] UMassResult u_mass(data::TableSet const& tables, float z, float a);

// ECOUL (GEF.bas:16326-16355): Coulomb energy of two deformed fragments at tip distance d.
[[nodiscard]] float ecoul(float z1, float a1, float beta1, float z2, float a2, float beta2,
                          float d) noexcept;

// U_Q_beta_minus (DCLbranchingJEFF33.bas:112-115).
[[nodiscard]] float u_q_beta_minus(data::TableSet const& tables, std::int64_t iz,
                                   std::int64_t ia);

// U_Valid (GEF.bas:15814-15832). BASIC returns a UByte.
[[nodiscard]] std::uint8_t u_valid(data::TableSet const& tables, std::int64_t i_z,
                                   std::int64_t i_a);

// U_Delta_S0 (GEF.bas:15836-15859): the body is commented out; 0 for every input.
[[nodiscard]] float u_delta_s0(std::int64_t i_z, std::int64_t i_a) noexcept;

} // namespace gef::physics
