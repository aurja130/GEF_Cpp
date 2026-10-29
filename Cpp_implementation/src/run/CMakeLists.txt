# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

# GEF's batch input, run control and system/step set-up (M6, namespace gef::run).
add_library(gef_run STATIC
    driver.cpp
    input_files.cpp
    step_setup.cpp
    system_setup.cpp
    workdir.cpp)
target_include_directories(gef_run PUBLIC "${PROJECT_SOURCE_DIR}/Cpp_implementation/src")
target_link_libraries(gef_run PUBLIC gef_physics gef_params gef_data gef_util gef_fbrt)
gef_apply_policy(gef_run)
