# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

# GEF's string utilities from utilities.bi (namespace gef::util).
add_library(gef_util STATIC
    utilities.cpp)
target_include_directories(gef_util PUBLIC "${PROJECT_SOURCE_DIR}/Cpp_implementation/src")
target_link_libraries(gef_util PUBLIC gef_fbrt)
gef_apply_policy(gef_util)
