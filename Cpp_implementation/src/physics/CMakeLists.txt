# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

# GEF's deterministic physics functions (M5, namespace gef::physics).
add_library(gef_physics STATIC
    helpers.cpp
    rotation.cpp
    level_density.cpp
    masses.cpp)
target_include_directories(gef_physics PUBLIC "${PROJECT_SOURCE_DIR}/Cpp_implementation/src")
target_link_libraries(gef_physics PUBLIC gef_data gef_fbrt)
gef_apply_policy(gef_physics)
