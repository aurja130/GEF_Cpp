// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF's array growth helpers (utilities.bi:269-372, M3.7). Each widens a Double array to cover
// the union of its current bounds and the requested ones, keeping the old values at their
// indices and zeroing the rest. The bounds pass through GEF's Single `Min`/`Max` and back to
// Integer (fb_F2L), as in the generated C. An unallocated array counts as bounds 0 To -1, so
// the result always includes index 0 below the requested range when that lies above 0.

#pragma once

#include "fbrt/array.hpp"

#include <cstdint>

namespace gef::fb {

void extend_1dim(Array<double, 1>& array, std::int64_t inew_low, std::int64_t inew_high);

void extend_2dim(Array<double, 2>& array, std::int64_t inew_low, std::int64_t inew_high,
                 std::int64_t jnew_low, std::int64_t jnew_high);

void extend_3dim(Array<double, 3>& array, std::int64_t inew_low, std::int64_t inew_high,
                 std::int64_t jnew_low, std::int64_t jnew_high, std::int64_t knew_low,
                 std::int64_t knew_high);

} // namespace gef::fb
