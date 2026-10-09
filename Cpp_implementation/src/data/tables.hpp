// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The static tables GEF loads before it computes anything (M4.3), with BASIC's bounds and
// types: Single -> float, Double -> double, Integer -> std::int64_t, String -> std::string.
// Loaded once per process (ProcessState, strategy §2.4) by load_tables().

#pragma once

#include "data/program_data.hpp"
#include "fbrt/array.hpp"

#include <cstdint>
#include <stdexcept>
#include <string>
#include <vector>

namespace gef::data {

// NucProp* `Type NucProp`. The NUBASE files declare two extra fields; they stay zero/empty
// for the other variants.
struct NucProp {
    std::int64_t i_z = 0;
    std::int64_t i_a = 0;
    std::int64_t i_iso = 0;
    float r_spi = 0.0F;
    std::int64_t i_par = 0;
    double r_awr = 0.0;
    float r_exc = 0.0F;
    double r_excess = 0.0;  // NUBASE only (R_Excess)
    std::string c_lifetime; // NUBASE only (C_Lifetime)
};

// NucProp* `Type Isoprop`: the states of one nuclide with isomers, sorted by spin, with the
// spin windows R_Lim. The member arrays are `(10)`, i.e. indices 0..10.
struct IsoProp {
    std::int64_t i_mat = 0;
    std::int64_t i_z = 0;
    std::int64_t i_a = 0;
    std::int64_t n_states = 0;
    fb::Array<std::int64_t, 1> i_iso{{fb::Bounds{0, 10}}};
    fb::Array<float, 1> r_spi{{fb::Bounds{0, 10}}};
    fb::Array<std::int64_t, 1> i_par{{fb::Bounds{0, 10}}};
    fb::Array<float, 1> r_exc{{fb::Bounds{0, 10}}};
    fb::Array<float, 1> r_lim{{fb::Bounds{0, 10}}};
    fb::Array<float, 1> r_prob{{fb::Bounds{0, 10}}};
};

// DCLbranchingJEFF33.bas `BranchData` record (the fields T0 dumps).
struct BranchRecord {
    std::int64_t i_z = 0;
    std::int64_t i_a = 0;
    std::int64_t i_iso = 0;
    float r_life = 0.0F;
    float r_beta = 0.0F;
    float r_beta_plus = 0.0F;
    float r_beta_n = 0.0F;
    float r_beta_2n = 0.0F;
    float r_beta_p = 0.0F;
    float r_beta_2p = 0.0F;
    float r_it = 0.0F;
    float r_alpha = 0.0F;
    float r_beta_m = 0.0F;
    float r_beta_plus_m = 0.0F;
    float r_beta_n_m = 0.0F;
    float r_beta_2n_m = 0.0F;
    float r_beta_p_m = 0.0F;
    float r_beta_2p_m = 0.0F;
    float r_it_m = 0.0F;
    float r_alpha_m = 0.0F;
    float r_beta_mm = 0.0F;
    float r_beta_plus_mm = 0.0F;
    float r_beta_n_mm = 0.0F;
    float r_beta_2n_mm = 0.0F;
    float r_beta_p_mm = 0.0F;
    float r_beta_2p_mm = 0.0F;
    float r_it_mm = 0.0F;
    float r_alpha_mm = 0.0F;
};

struct TableSet {
    NuclideData variant = NuclideData::Jeff33;

    // Lines the loaders printed to the console and continued after (e.g. JEFF-3.1.1's
    // "<E> Nucprop: N_MAT_MAX too large, should be  3878"), in order, without line ends, with
    // BASIC's Print formatting.
    std::vector<std::string> console;

    // NucProp*.bas
    std::int64_t n_mat_max = 0;
    std::int64_t n_iso_tot = 0;
    fb::Array<NucProp, 1> nuc_tab;
    fb::Array<std::int64_t, 1> mat_for_iso;
    fb::Array<IsoProp, 1> isotab;

    // Mass, shell and deformation tables
    fb::Array<float, 2> beldm_tf; // BEldmTF.bas
    fb::Array<float, 2> be_exp;   // BEexp.bas
    fb::Array<float, 2> defo_tab; // DEFO.bas
    fb::Array<float, 2> shell_mo; // ShellMO.bas
    fb::Array<float, 2> evod;     // declared, never filled

    fb::Array<std::string, 1> c_element; // ElmtNames.bas
    fb::Array<double, 1> enfrvar_lim;    // Spectra.bas:798

    // Branchings.bas loader over DCLbranchingJEFF33.bas (GEF runs it in the post-pass)
    std::int64_t z_min_branching = 0;
    std::int64_t z_max_branching = 0;
    std::int64_t a_max_branching = 0;
    fb::Array<BranchRecord, 1> branch_data;
    fb::Array<std::int64_t, 1> in_last;
};

// GEF ended the program while loading (`Print …: Sleep: End`, e.g. QUIRKS.md Q-032). The
// console lines BASIC printed are kept in order.
class GefStopped : public std::runtime_error {
public:
    explicit GefStopped(std::vector<std::string> console_lines);
    [[nodiscard]] std::vector<std::string> const& console_lines() const noexcept { return lines_; }

private:
    std::vector<std::string> lines_;
};

// Loads every table from the program's DATA in BASIC's order. Throws GefStopped where BASIC
// stops.
[[nodiscard]] TableSet load_tables(ProgramData const& data);

} // namespace gef::data
