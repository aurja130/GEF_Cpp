// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The Z-A relation of one mode, which the builder computes twice: from the mean charges
// (GEF.bas:5995-6048) and after the energy-dependent polarisation (6824-6870).

#pragma once

#include "tables/bin_plan.hpp"
#include "tables/bin_tables.hpp"

#include <cstdint>

namespace gef::tables {

// RZpol and RA iterated three times on Zshift(m, k, ·) (through fragment_element, QUIRK(Q-061)),
// then the mean A and N of the mode with centre `zc`.
void z_a_relation(BinInput const& bin, BinTables& t, float zc, std::int64_t m, std::int64_t k,
                  float& ac, float& nc);

} // namespace gef::tables
