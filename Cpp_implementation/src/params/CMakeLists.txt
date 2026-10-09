# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

# GEF's model parameters: nominal values, perturbation widths, parameter files (gef::params).
add_library(gef_params STATIC
    parameter_files.cpp
    parameters.cpp)
target_include_directories(gef_params PUBLIC "${PROJECT_SOURCE_DIR}/Cpp_implementation/src")
target_link_libraries(gef_params PUBLIC gef_fbrt gef_util)
gef_apply_policy(gef_params)
