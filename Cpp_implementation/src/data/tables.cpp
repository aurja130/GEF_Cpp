// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Loads every static table in BASIC's order (tables.hpp). The per-file loaders are in
// mass_tables.cpp and branchings.cpp; the nuclide tables are in nuclide_tables.cpp.
#include "data/tables.hpp"

#include "data/nuclide_tables.hpp"
#include "data/table_loaders.hpp"
#include "fbrt/data_reader.hpp"

#include <string>
#include <utility>
#include <vector>

namespace gef::data {

GefStopped::GefStopped(std::vector<std::string> console_lines)
    : std::runtime_error("GEF stopped"), lines_(std::move(console_lines)) {}

TableSet load_tables(ProgramData const& data) {
    TableSet tables;
    tables.variant = data.variant();
    fb::DataReader reader(data.items());

    // GEF.bas:1052-1278: NucProp / IsoProp tables (NucLoad).
    load_nuclide_tables(data, tables);
    // Spectra.bas:798: ENfrvar_lim, initialised before the mass tables.
    load_enfrvar_lim(tables);
    // GEF.bas:1222-1570: BEldmTF, BEexp, DEFOtab, ShellMO, EVOD, CElement.
    load_mass_tables(data, reader, tables);
    // Branchings.bas (GEF's post-pass): BranchData and INlast.
    load_branchings(data, reader, tables);
    return tables;
}

} // namespace gef::data
