// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF's nuclide lookup functions (M4.6), as the selected nuclide-data file defines them:
// NucProp_Functions.mac (included by NucPropJEFF33, NucPropNUBASE2016, NucPropNUBASE2020), the
// own versions of NucPropJEFF311.bas and of the legacy NucPropx/mf/f.bas, and Ibranch_for_ZAI
// of DCLbranchingJEFF33.bas.

#pragma once

#include "data/tables.hpp"

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace gef::data {

// What I_MAT_ENDF keeps between calls (QUIRK(Q-021)): its `Static I_message` and, for the
// NucProp_Functions.mac form, the file ctl/IMATmax.ctl, which outlives the process. GEF
// creates ctl/ at start-up, so the file is always looked for there.
struct MatNumberState {
    bool message_shown = false;             // Static I_message
    std::optional<std::string> imatmax_ctl; // the bytes of ctl/IMATmax.ctl; nullopt: no file
};

// I_MAT_ENDF(IZ, IA): the ENDF MAT number (the NucTab index) of the nuclide. What happens to a
// nuclide that is not in NucTab depends on the variant (lookups.cpp). Console lines go to
// `console`.
[[nodiscard]] std::int64_t i_mat_endf(TableSet const& tables, std::int64_t iz, std::int64_t ia,
                                      MatNumberState& state, std::vector<std::string>& console);

// N_ISO_MAT(IMAT): the number of isomers of the nuclide at NucTab index `imat`.
[[nodiscard]] std::int64_t n_iso_mat(TableSet const& tables, std::int64_t imat);

// R_AWR_ENDF(IZ, IA): NucTab's AWR of the nuclide, as Single. Calls I_MAT_ENDF.
[[nodiscard]] float r_awr_endf(TableSet const& tables, std::int64_t iz, std::int64_t ia,
                               MatNumberState& state, std::vector<std::string>& console);

// ISO_for_MAT(IMAT): the index in MAT_for_ISO of `imat`, 0 when absent.
[[nodiscard]] std::int64_t iso_for_mat(TableSet const& tables, std::int64_t imat);

// ISO_for_ZA(IZ, IA): the Isotab index of the nuclide, 0 when absent.
[[nodiscard]] std::int64_t iso_for_za(TableSet const& tables, std::int64_t iz, std::int64_t ia);

// NStates_for_ZA(IZ, IA): the number of states from Isotab, 1 when absent.
[[nodiscard]] std::int64_t nstates_for_za(TableSet const& tables, std::int64_t iz, std::int64_t ia);

// Ibranch_for_ZAI(IZ, IA, ISO) (DCLbranchingJEFF33.bas:146-169): the BranchData index of the
// state, or -1 (β+ assumed) / -2 (β- assumed) / 0 when it is missing.
[[nodiscard]] std::int64_t ibranch_for_zai(TableSet const& tables, std::int64_t iz, std::int64_t ia,
                                           std::int64_t iso);

} // namespace gef::data
