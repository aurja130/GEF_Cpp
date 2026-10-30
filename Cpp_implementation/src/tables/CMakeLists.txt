# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

# GEF's per-nucleus model tables (M7, namespace gef::tables): the bins of a pass and the table
# builder of each bin (MILESTONE_7_PLAN.md D8).
add_library(gef_tables STATIC
    bin_plan.cpp
    deformations.cpp
    working_parameters.cpp)
target_include_directories(gef_tables PUBLIC "${PROJECT_SOURCE_DIR}/Cpp_implementation/src")
target_link_libraries(gef_tables PUBLIC gef_physics gef_params gef_fbrt)
gef_apply_policy(gef_tables)
