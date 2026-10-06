# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aurora Jahan
# See LICENSE.txt in the repository root for the full license text.

# Configure-time build facts: version, compiler, preset, build type, compile flags.
string(TOUPPER "${CMAKE_BUILD_TYPE}" gef_build_type_upper)
list(JOIN GEF_EXACT_FP_FLAGS " " GEF_EXACT_FP_FLAGS_TEXT)
string(STRIP "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_${gef_build_type_upper}}"
       GEF_GENERAL_CXX_FLAGS_TEXT)
set(gef_generated_dir "${CMAKE_CURRENT_BINARY_DIR}/generated")
configure_file(build_info.cpp.in "${gef_generated_dir}/build_info.cpp" @ONLY)

# Build-time git revision, refreshed on every build (not frozen at configure time).
find_package(Git QUIET)
set(gef_git_revision_file "${gef_generated_dir}/git_revision.cpp")
add_custom_target(gef_git_revision
    COMMAND "${CMAKE_COMMAND}"
            "-DGEF_SOURCE_DIR=${PROJECT_SOURCE_DIR}"
            "-DGEF_OUTPUT_FILE=${gef_git_revision_file}"
            "-DGEF_GIT_EXECUTABLE=${GIT_EXECUTABLE}"
            -P "${PROJECT_SOURCE_DIR}/Cpp_implementation/cmake/GefGitRevision.cmake"
    BYPRODUCTS "${gef_git_revision_file}"
    COMMENT "Reading git revision"
    VERBATIM)

add_executable(gef
    main.cpp
    "${gef_generated_dir}/build_info.cpp"
    "${gef_git_revision_file}")
add_dependencies(gef gef_git_revision)
set_target_properties(gef PROPERTIES OUTPUT_NAME gef)
target_include_directories(gef PRIVATE "${PROJECT_SOURCE_DIR}/Cpp_implementation/src")
target_link_libraries(gef PRIVATE gef_fbrt)
gef_apply_policy(gef)

# The CLI self-check runs under CTest in every preset. A failing fp_environment verdict makes
# `gef --version` exit non-zero and print FAIL; the regexes check the printed verdict (CTest
# ignores the exit code once PASS_REGULAR_EXPRESSION is set). Unknown arguments must be rejected.
add_test(NAME "app: gef --version reports a passing fp_environment" COMMAND gef --version)
set_tests_properties("app: gef --version reports a passing fp_environment" PROPERTIES
    LABELS "unit;app"
    PASS_REGULAR_EXPRESSION "fp_environment verdict: PASS"
    FAIL_REGULAR_EXPRESSION "FAIL")
add_test(NAME "app: gef rejects unknown arguments" COMMAND gef --no-such-option)
set_tests_properties("app: gef rejects unknown arguments" PROPERTIES
    LABELS "unit;app"
    WILL_FAIL TRUE)
