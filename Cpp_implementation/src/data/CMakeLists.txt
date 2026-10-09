# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

# GEF's DATA items per nuclide-data variant (namespace gef::data). generated/ is written by
# python3 -m tools.fbsrc.gen_gef_data.
add_library(gef_data STATIC
    branchings.cpp
    generated/shared_tables.cpp
    generated/variant_jeff33.cpp
    generated/variant_jeff311.cpp
    generated/variant_nubase2016.cpp
    generated/variant_nubase2020.cpp
    generated/variant_legacy_x.cpp
    generated/variant_legacy_mf.cpp
    generated/variant_legacy_f.cpp
    mass_tables.cpp
    nuclide_tables.cpp
    program_data.cpp
    tables.cpp)
target_include_directories(gef_data PUBLIC "${PROJECT_SOURCE_DIR}/Cpp_implementation/src")
target_link_libraries(gef_data PUBLIC gef_fbrt)
gef_apply_policy(gef_data)
