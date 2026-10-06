# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aurora Jahan
# See LICENSE.txt in the repository root for the full license text.

# FreeBASIC runtime emulation (namespace gef::fb).
add_library(gef_fbrt STATIC
    fp_environment.cpp)
target_include_directories(gef_fbrt PUBLIC "${PROJECT_SOURCE_DIR}/Cpp_implementation/src")
gef_apply_policy(gef_fbrt)
