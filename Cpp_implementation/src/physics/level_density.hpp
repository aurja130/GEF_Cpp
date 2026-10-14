// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Level densities and temperatures (MILESTONE_5_PLAN.md section 3, group "level_density"),
// namespace gef::physics. Tscale, Econd and Etrans are parameters in BASIC already.

#pragma once

#include "data/tables.hpp"

#include <cstdint>

namespace gef::physics {

// U_alev_ld (GEF.bas:17173-17177): level-density parameter.
[[nodiscard]] float u_alev_ld(float z, float a) noexcept;

// U_levdens (GEF.bas:17205-17223), U_levdens_Egidy (17225-17259), U_levdens_FG (17261-17331).
[[nodiscard]] double u_levdens(data::TableSet const& tables, std::int64_t z, std::int64_t a,
                               float e, std::int64_t ishell, std::int64_t ipair, float tscale,
                               float econd, float etrans, float af_an);
[[nodiscard]] double u_levdens_egidy(data::TableSet const& tables, std::int64_t z, std::int64_t a,
                                     float e, std::int64_t ishell, std::int64_t ipair, float tscale,
                                     float econd, float etrans, float af_an);
[[nodiscard]] double u_levdens_fg(data::TableSet const& tables, std::int64_t z, std::int64_t a,
                                  float e, std::int64_t ishell, std::int64_t ipair, float tscale,
                                  float econd, float etrans, float af_an);

// U_Temp (GEF.bas:17335-17385) and U_Temp2 (GEF.bas:17388-17420): nuclear temperature.
[[nodiscard]] float u_temp(data::TableSet const& tables, float z, float a, float e,
                           std::int64_t ishell, std::int64_t ipair, float tscale, float econd,
                           float etrans);
[[nodiscard]] float u_temp2(float z, float a, float e, float rshell, float rpair, float tscale,
                            float econd, float etrans);

// TEgidy (GEF.bas:16072-16095) and TRusanov (GEF.bas:16098-16108).
[[nodiscard]] float tegidy(float a, float du, float fred) noexcept;
[[nodiscard]] float trusanov(float e, float a) noexcept;

} // namespace gef::physics
