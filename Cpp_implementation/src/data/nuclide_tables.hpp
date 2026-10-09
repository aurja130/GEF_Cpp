// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
#pragma once

#include "data/program_data.hpp"
#include "data/tables.hpp"

namespace gef::data {

// NucTab, MAT_for_ISO, Isotab, N_MAT_MAX, N_ISO_TOT (owned by the nuclide loader).
void load_nuclide_tables(ProgramData const& data, TableSet& tables);

} // namespace gef::data
