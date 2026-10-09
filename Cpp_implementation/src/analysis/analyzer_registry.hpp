// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The analyzer registry `Anl_Par` (M4.5): the attributes (name, title, axes, line symbol,
// type, limits, dimension) of every histogram GEF can write, set up once at start-up
// (GEF.bas:1076-1311 with the included Spectra.bas and DCLbranchingJEFF33.bas sections).
// The histogram arrays that BASIC dimensions between the entries belong to the analysis
// milestones (M13); only the registry is here.

#pragma once

#include "fbrt/array.hpp"

#include <cstdint>
#include <string>

namespace gef::analysis {

// GEF.bas:714-739 `Type Analyzer_Attributes` and its constructor. The strings are fixed-length
// in BASIC (`String*128`, `C_Type` `String*20`); every value the registry assigns fits.
struct AnalyzerAttributes {
    AnalyzerAttributes();

    std::string c_name;               // String*128
    std::string c_title;              // String*128
    std::string c_xaxis = "Channel";  // String*128
    std::string c_yaxis = "Counts";   // String*128
    std::string c_linesymbol = "HT0"; // String*128
    std::string c_type = "analog";    // String*20
    fb::Array<float, 2> r_alim;       // R_ALim(1 to 4, 1 to 3)
    std::int64_t i_dim = 1;           // dimension of the analyzer
};

struct AnalyzerRegistry {
    fb::Array<AnalyzerAttributes, 1> anl_par; // Anl_Par(0 To 1000)
    std::int64_t n_anl = 0;                   // N_Anl, the number of registered analyzers
};

// The registry as GEF sets it up (GEF.bas:1076-1311).
[[nodiscard]] AnalyzerRegistry build_analyzer_registry();

} // namespace gef::analysis
