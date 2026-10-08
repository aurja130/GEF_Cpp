# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

# FreeBASIC runtime emulation (namespace gef::fb).
add_library(gef_fbrt STATIC
    convert.cpp
    fp_environment.cpp
    reseed.cpp
    rng.cpp)
target_include_directories(gef_fbrt PUBLIC "${PROJECT_SOURCE_DIR}/Cpp_implementation/src")
gef_apply_policy(gef_fbrt)
