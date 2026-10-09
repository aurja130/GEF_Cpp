# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

# GEF's analyzers (gef::analysis): the analyzer registry (M4.5); histograms follow in M13.
add_library(gef_analysis STATIC
    analyzer_registry.cpp)
target_include_directories(gef_analysis PUBLIC "${PROJECT_SOURCE_DIR}/Cpp_implementation/src")
target_link_libraries(gef_analysis PUBLIC gef_fbrt)
gef_apply_policy(gef_analysis)
