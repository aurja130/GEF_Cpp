// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Internal: the per-file table loaders that `load_tables` (tables.cpp) runs in BASIC's order.
// Every loader restores the DATA reader to its own label first, as BASIC's `Restore` does.
#pragma once

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "fbrt/data_reader.hpp"

namespace gef::data {

// Spectra.bas:798 `Dim As Double ENfrvar_lim(303) = {...}` (static initialiser).
void load_enfrvar_lim(TableSet& tables);

// BEldmTF.bas, BEexp.bas, DEFO.bas, ShellMO.bas, ElmtNames.bas (and the EVOD ReDim).
void load_mass_tables(ProgramData const& data, fb::DataReader& reader, TableSet& tables);

// Branchings.bas:44-252 over DCLbranchingJEFF33.bas (the Dim Shared values and the ReDims).
void load_branchings(ProgramData const& data, fb::DataReader& reader, TableSet& tables);

} // namespace gef::data
