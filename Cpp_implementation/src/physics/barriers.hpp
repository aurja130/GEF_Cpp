// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Fission barriers (MILESTONE_5_PLAN.md section 3, group "barriers"), namespace gef::physics.

#pragma once

#include "data/tables.hpp"

#include <cstdint>

namespace gef::physics {

// BFTF (GEF.bas:17657-17750): fission barrier from the Thomas-Fermi model with shell and
// pairing corrections; I_Switch selects the quantity. An undefined option prints
// "Undefined option in BFTF" in BASIC (GEF.bas:17731); `print_undefined_option` reports it.
struct BftfResult {
    float value = 0.0F;
    bool print_undefined_option = false;
};
[[nodiscard]] BftfResult bftf(data::TableSet const& tables, float rz, float ra,
                              std::int64_t i_switch);

// BFTFA (GEF.bas:17752-17773) and BFTFB (GEF.bas:17775-17796): inner and outer barrier.
[[nodiscard]] BftfResult bftfa(data::TableSet const& tables, float rz, float ra,
                               std::int64_t i_switch);
[[nodiscard]] BftfResult bftfb(data::TableSet const& tables, float rz, float ra,
                               std::int64_t i_switch);

} // namespace gef::physics
