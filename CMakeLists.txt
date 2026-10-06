# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aurora Jahan
# See LICENSE.txt in the repository root for the full license text.

cmake_minimum_required(VERSION 4.0)

project(GEF_Cpp
    VERSION 0.1.0
    DESCRIPTION "C++ port of the GEF fission code"
    LANGUAGES CXX)

if(NOT PROJECT_IS_TOP_LEVEL)
    message(FATAL_ERROR "GEF_Cpp must be built as the top-level project")
endif()

# C++23 in ISO mode (-std=c++23, not gnu++23): no GNU floating-point defaults.
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# The project uses no C++20 modules; skip the per-file dependency scan CMake 4 enables for C++23.
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

if(NOT CMAKE_BUILD_TYPE)
    message(FATAL_ERROR "CMAKE_BUILD_TYPE is not set; configure through a preset "
                        "(cmake --preset dev-gcc|dev-clang|asan-ubsan|release-exact)")
endif()

set(GEF_BUILD_PRESET "none" CACHE STRING
    "Name of the CMake preset this build tree was configured with (reported by gef --version)")

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/Cpp_implementation/cmake")
include(GefCompilerPolicy)

enable_testing()

add_subdirectory(Cpp_implementation)
