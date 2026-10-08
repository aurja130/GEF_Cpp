// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Access to FreeBASIC driver goldens (M3 plan D1): committed ones under
// Cpp_implementation/tests/golden/<name>/, large ones in the reference store as capture <name>.

#pragma once

#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace gef::test {

// Cpp_implementation/tests/golden/<name>/<file>; fails the test when it does not exist.
[[nodiscard]] std::filesystem::path golden_file(std::string_view name, std::string_view file);

// validation/reference_store/captures/<id>/<file>, or nothing when the store (or that
// capture) is absent; callers SKIP in that case.
[[nodiscard]] std::optional<std::filesystem::path> store_file(std::string_view id,
                                                              std::string_view file);

// The lines of a text file, without line terminators (LF or CRLF).
[[nodiscard]] std::vector<std::string> read_lines(std::filesystem::path const& path);

// A hexadecimal number as written by the drivers (no prefix, either case); fails the test
// on anything else.
[[nodiscard]] std::uint64_t parse_hex(std::string_view text);

} // namespace gef::test
