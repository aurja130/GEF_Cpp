// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#ifndef GEF_FBRT_FORMAT_HPP
#define GEF_FBRT_FORMAT_HPP

#include <string>
#include <string_view>

namespace gef::fb {

// str_format.c fb_StrFormat / fb_hStrFormat: BASIC Format(value, mask).
// An empty mask builds the default number text. An invalid mask yields "".
// The locale is fixed to the runtime defaults (I18n off): '.', ',', '/', ':',
// date format MM/dd/yyyy, time format HH:mm:ss, English month and weekday names.
[[nodiscard]] std::string format(double value, std::string_view mask);

} // namespace gef::fb

#endif // GEF_FBRT_FORMAT_HPP
