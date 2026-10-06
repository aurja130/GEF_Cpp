#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aurora Jahan
# See LICENSE.txt in the repository root for the full license text.
#
# Single local CI entry point (Planning/MILESTONE_0_PLAN.md, M0.10).
#
# Usage: scripts/ci.sh [--quick]
#   (default)  toolchain check; configure, build and test dev-gcc, dev-clang
#              and asan-ubsan; clang-tidy; clang-format; ruff lint and format
#              check; basedpyright; pytest; validation-manifest verification.
#   --quick    dev-gcc configure/build/test and the Python steps only.
#
# Every step runs even if an earlier one failed, except steps that need a
# build that failed. Each step's output goes to build/ci/<step>.log; the tail
# of the log is shown when the step fails. A one-line summary per step is
# printed at the end. The exit status is non-zero if any step failed.

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

quick=0
case "${1:-}" in
    "") ;;
    --quick) quick=1 ;;
    -h | --help)
        sed -n '8,17p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *)
        echo "ci.sh: unknown argument '$1' (use --quick or --help)" >&2
        exit 2
        ;;
esac
if [[ $# -gt 1 ]]; then
    echo "ci.sh: too many arguments" >&2
    exit 2
fi

log_dir="build/ci"
mkdir -p "$log_dir"

summary=()
failed=0
declare -A step_ok=()

# run_step NAME COMMAND...: run a command, log it, record PASS/FAIL.
run_step() {
    local name="$1"
    shift
    local log="$log_dir/$name.log"
    local start end status
    start=$(date +%s)
    printf '==> %s\n' "$name"
    "$@" >"$log" 2>&1
    status=$?
    end=$(date +%s)
    if [[ $status -eq 0 ]]; then
        summary+=("$(printf 'PASS  %-26s %4ss' "$name" "$((end - start))")")
        step_ok[$name]=1
    else
        summary+=("$(printf 'FAIL  %-26s %4ss  (exit %s, log: %s)' "$name" "$((end - start))" "$status" "$log")")
        step_ok[$name]=0
        failed=1
        echo "---- last 40 lines of $log ----"
        tail -n 40 "$log"
        echo "----"
    fi
}

skip_step() {
    local name="$1" reason="$2"
    printf '==> %s (skipped: %s)\n' "$name" "$reason"
    summary+=("$(printf 'SKIP  %-26s        %s' "$name" "$reason")")
}

preset_pipeline() {
    local preset="$1"
    cmake --preset "$preset" && cmake --build --preset "$preset" && ctest --preset "$preset"
}

cpp_files() {
    # Tracked and untracked-but-not-ignored C++ sources and headers.
    git ls-files --cached --others --exclude-standard -- "$@"
}

clang_tidy_step() {
    local files
    mapfile -t files < <(cpp_files 'Cpp_implementation/src/*.cpp' 'Cpp_implementation/tests/*.cpp')
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "no C++ sources found" >&2
        return 1
    fi
    clang-tidy -p build/dev-clang --quiet "${files[@]}"
}

clang_format_step() {
    local files
    mapfile -t files < <(cpp_files 'Cpp_implementation/*.cpp' 'Cpp_implementation/*.hpp')
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "no C++ sources found" >&2
        return 1
    fi
    clang-format --dry-run --Werror "${files[@]}" &&
        clang-format --dry-run --Werror --assume-filename=build_info.cpp \
            <Cpp_implementation/src/app/build_info.cpp.in
}

# 1. Toolchain check.
if [[ $quick -eq 0 ]]; then
    run_step toolchain python3 -m tools.toolchain.check_toolchain
fi

# 2. Configure, build and test.
if [[ $quick -eq 1 ]]; then
    presets=(dev-gcc)
else
    presets=(dev-gcc dev-clang asan-ubsan)
fi
for preset in "${presets[@]}"; do
    run_step "build-test-$preset" preset_pipeline "$preset"
done

if [[ $quick -eq 0 ]]; then
    # 3. clang-tidy (needs the dev-clang compilation database).
    if [[ ${step_ok[build-test-dev-clang]} -eq 1 ]]; then
        run_step clang-tidy clang_tidy_step
    else
        skip_step clang-tidy "dev-clang build failed"
        failed=1
    fi
    # 4. clang-format.
    run_step clang-format clang_format_step
fi

# 5.-7. Python.
run_step ruff-check ruff check
run_step ruff-format ruff format --check
run_step basedpyright basedpyright
run_step pytest python3 -m pytest

# 8. Validation manifests.
if [[ $quick -eq 0 ]]; then
    printf '==> validation-manifests\n'
    manifest_log="$log_dir/validation-manifests.log"
    start=$(date +%s)
    # Exit 77 means validation/ is absent: the manifests cannot be checked here.
    python3 -m tools.toolchain.manifest_validation verify >"$manifest_log" 2>&1
    status=$?
    end=$(date +%s)
    if [[ $status -eq 0 ]]; then
        summary+=("$(printf 'PASS  %-26s %4ss' validation-manifests "$((end - start))")")
    elif [[ $status -eq 77 ]]; then
        echo "notice: validation/ is absent; manifest verification skipped"
        skip_step validation-manifests "validation/ absent"
    else
        summary+=("$(printf 'FAIL  %-26s %4ss  (exit %s, log: %s)' validation-manifests "$((end - start))" "$status" "$manifest_log")")
        failed=1
        tail -n 40 "$manifest_log"
    fi
fi

echo
echo "CI summary ($([[ $quick -eq 1 ]] && echo quick || echo full)):"
printf '  %s\n' "${summary[@]}"
if [[ $failed -ne 0 ]]; then
    echo "CI FAILED"
    exit 1
fi
echo "CI PASSED"
