# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

# Catch2 v3, pinned by release tag and archive SHA-256. Downloaded once at first configure.
# SYSTEM: Catch2 headers are system headers for our targets, so our warning set does not
# apply to them; Catch2 itself is built without gef_warnings.
include(FetchContent)
FetchContent_Declare(Catch2
    URL https://github.com/catchorg/Catch2/archive/refs/tags/v3.16.0.tar.gz
    URL_HASH SHA256=0957cae5821b17ce07f0833aaa52b5137643a8382203221f363a8303c109af34
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    SYSTEM
    EXCLUDE_FROM_ALL)
FetchContent_MakeAvailable(Catch2)
list(APPEND CMAKE_MODULE_PATH "${catch2_SOURCE_DIR}/extras")
include(Catch)
find_package(Threads REQUIRED)

add_executable(gef_tests
    analyzer_registry_test.cpp
    array_test.cpp
    conversion_test.cpp
    data_input_test.cpp
    fbc_arithmetic_test.cpp
    format_test.cpp
    fp_environment_test.cpp
    line_input_test.cpp
    lookups_test.cpp
    maths_test.cpp
    nuclide_tables_test.cpp
    params_test.cpp
    print_using_test.cpp
    probe_dump_test.cpp
    program_data_test.cpp
    rng_test.cpp
    strings_test.cpp
    tables_test.cpp
    text_test.cpp
    utilities_test.cpp
    support/golden.cpp
    support/probe_dump.cpp)
target_include_directories(gef_tests PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
# Driver goldens (M3 plan D1): committed ones, and the reference store for large ones.
target_compile_definitions(gef_tests PRIVATE
    GEF_TEST_GOLDEN_DIR="${CMAKE_CURRENT_SOURCE_DIR}/golden"
    GEF_TEST_STORE_CAPTURES_DIR="${PROJECT_SOURCE_DIR}/validation/reference_store/captures")
target_link_libraries(gef_tests PRIVATE gef_analysis gef_data gef_fbrt gef_params gef_util
    Catch2::Catch2WithMain Threads::Threads)
gef_apply_policy(gef_tests)

# Test tags become CTest labels ([unit] -> unit, [T1] -> T1), so `ctest -L T1` runs one tier.
# PRE_TEST discovery lists the tests when CTest runs, not as a build step.
catch_discover_tests(gef_tests
    ADD_TAGS_AS_LABELS
    DISCOVERY_MODE PRE_TEST)
