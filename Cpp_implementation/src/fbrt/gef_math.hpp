// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF's own maths helpers (utilities.bi, GEF.bas), ported from the C that fbc 1.10.1
// generates for them (M3.4). They are GEF functions, not FreeBASIC intrinsics: `Min`/`Max`
// take Single, so integer arguments pass through float; `Tanh` and `Log10` are not libm's.
// BASIC intrinsics need no wrapper: the std:: overload for the argument type is the libm
// function fbc emits (FBC_ARITHMETIC.md, R7).

#pragma once

#include <cstdint>

namespace gef::fb {

[[nodiscard]] float min(float r1, float r2) noexcept;        // utilities.bi:18-26
[[nodiscard]] float max(float r1, float r2) noexcept;        // utilities.bi:28-36
[[nodiscard]] float erf(float x) noexcept;                   // utilities.bi:38-48
[[nodiscard]] float erfc(float x) noexcept;                  // utilities.bi:50-63
[[nodiscard]] float tanh(float x) noexcept;                  // utilities.bi:65-73
[[nodiscard]] float coth(float x) noexcept;                  // utilities.bi:75-83
[[nodiscard]] float log10(float r) noexcept;                 // utilities.bi:85-87
[[nodiscard]] float floor(float r) noexcept;                 // GEF.bas:18052-18054
[[nodiscard]] float ceil(float r) noexcept;                  // GEF.bas:18056-18062
[[nodiscard]] float round(float r, std::int64_t n) noexcept; // GEF.bas:18064-18082
// GEF.bas:18084-18089. j == 0 traps in BASIC; throws std::domain_error here.
[[nodiscard]] std::int64_t modulo(std::uint64_t i, std::uint64_t j);

} // namespace gef::fb
