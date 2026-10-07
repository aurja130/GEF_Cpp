# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
#
# Project-wide compiler policy as interface targets:
#   gef_exact_fp  exact-mode floating-point flags (Planning/MILESTONE_0_PLAN.md §2). Every GEF
#                 target links it, so all code shares fbc's floating-point code generation.
#   gef_warnings  the project warning set, applied to our targets only (never to Catch2).
# gef_apply_policy(<target>) links both; use it for every target the project defines. The FP
# flags are linked PUBLIC so anything consuming a GEF library is compiled the same way.

if(NOT CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang)$")
    message(FATAL_ERROR "Unsupported compiler '${CMAKE_CXX_COMPILER_ID}': exact mode is "
                        "defined for GCC and Clang only")
endif()

# Mirrors fbc's gcc backend flags (-march=x86-64 -frounding-math -fno-math-errno) and rules
# out FMA contraction and fast-math. Accepted by GCC 16 and Clang 22. On Clang,
# -fexcess-precision=standard only governs _Float16/__bf16 arithmetic; float/double already
# evaluate at their own precision on x86-64 SSE (FLT_EVAL_METHOD == 0, checked at run time).
set(GEF_EXACT_FP_FLAGS
    -march=x86-64
    -ffp-contract=off
    -fno-fast-math
    -frounding-math
    -fno-math-errno
    -fexcess-precision=standard)

add_library(gef_exact_fp INTERFACE)
target_compile_options(gef_exact_fp INTERFACE ${GEF_EXACT_FP_FLAGS})

add_library(gef_warnings INTERFACE)
target_compile_options(gef_warnings INTERFACE
    -Wall
    -Wextra
    -Wpedantic
    -Wconversion
    -Wsign-conversion
    -Wdouble-promotion
    -Wshadow
    -Werror)

function(gef_apply_policy target)
    target_link_libraries(${target} PUBLIC gef_exact_fp PRIVATE gef_warnings)
endfunction()
