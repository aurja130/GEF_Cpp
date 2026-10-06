// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Aurora Jahan
// See LICENSE.txt in the repository root for the full license text.

// Facts about how this gef binary was built, reported by `gef --version`.
// Defined in generated sources: build_info.cpp (from build_info.cpp.in, at configure time)
// and git_revision.cpp (from cmake/GefGitRevision.cmake, refreshed on every build).

#pragma once

#include <string_view>

namespace gef::app {

struct BuildInfo {
    std::string_view project_version;
    std::string_view compiler_id;
    std::string_view compiler_version;
    std::string_view build_preset;
    std::string_view build_type;
    std::string_view exact_fp_flags;    // the gef_exact_fp interface flags
    std::string_view general_cxx_flags; // CMAKE_CXX_FLAGS plus the build type's flags
};

// Configure-time facts.
[[nodiscard]] BuildInfo build_info() noexcept;

// `git describe --always --dirty` of the repository at build time, or "unknown" when the
// source tree is not a git checkout.
[[nodiscard]] std::string_view git_revision() noexcept;

} // namespace gef::app
