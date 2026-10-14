// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF's small deterministic helpers (MILESTONE_5_PLAN.md section 3, group "helpers"), namespace
// gef::physics. Bit-exact ports of the C fbc 1.10.1 emits for GEF.bas.

#pragma once

#include <cstdint>

namespace gef::physics {

// Gaussintegral (GEF.bas:17808-17816): 0.5 + 0.5 * Erf(R_x / R_sigma), a smoothed step.
[[nodiscard]] float gaussintegral(float r_x, float r_sigma) noexcept;

// Bell (GEF.bas:17818-17828): x^2 (1 - x)^2 / 0.0625 with x = (xpos - xleft) / (xright - xleft)
// inside (xleft, xright), 0 elsewhere.
[[nodiscard]] float bell(float xpos, float xleft, float xright) noexcept;

// U_Box (GEF.bas:17830-17837): a box of the given length folded with Gaussintegral.
[[nodiscard]] float u_box(float x, float sigma, float length) noexcept;

// EVEN_ODD (GEF.bas:17593-17653): rounds R_ORIGIN to an integer with the even-odd effect
// R_EVEN_ODD.
[[nodiscard]] std::int64_t even_odd(float r_origin, float r_even_odd) noexcept;

} // namespace gef::physics
