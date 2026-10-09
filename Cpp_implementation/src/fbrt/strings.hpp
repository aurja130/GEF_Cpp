// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

// The string functions of the FreeBASIC runtime used by GEF (M4.4): Trim, UCase, InStr and Mid.
// Strings are byte strings; embedded NULs are ordinary characters.

#pragma once

#include <cstdint>
#include <string>
#include <string_view>

namespace gef::fb {

// fb_TRIM (str_trim.c): strips trailing ASCII 32 and NUL, leading ASCII 32 only.
[[nodiscard]] std::string trim(std::string_view s);

// UCase(s): fb_StrUcase2(s, 0) (str_ucase.c); only the C-locale letters a-z change.
[[nodiscard]] std::string ucase(std::string_view s);

// InStr(s, p) = fb_StrInstr(1, s, p); 1-based position, 0 when not found.
[[nodiscard]] std::int64_t instr(std::string_view s, std::string_view pattern);

// fb_StrInstr (str_instr.c): search from the 1-based position start.
[[nodiscard]] std::int64_t instr(std::int64_t start, std::string_view s, std::string_view pattern);

// Mid(s, start) = fb_StrMid(s, start, -1) (str_mid.c): from the 1-based start to the end.
[[nodiscard]] std::string mid(std::string_view s, std::int64_t start);

// fb_StrMid (str_mid.c): len characters from the 1-based start (clipped to the string).
[[nodiscard]] std::string mid(std::string_view s, std::int64_t start, std::int64_t len);

} // namespace gef::fb
