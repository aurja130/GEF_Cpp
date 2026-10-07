// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// gef command-line entry point. M0 provides build and floating-point environment
// information only.

#include "app/build_info.hpp"
#include "fbrt/fp_environment.hpp"

#include <cstddef>
#include <cstdio>
#include <exception>
#include <print>
#include <span>
#include <string_view>

namespace {

constexpr int exit_ok = 0;
constexpr int exit_fp_environment_failed = 1;
constexpr int exit_usage_error = 2;
constexpr int exit_internal_error = 3;

void print_usage(std::FILE* stream) {
    std::println(stream, "Usage: gef <option>\n"
                         "\n"
                         "Options:\n"
                         "  --version   print build information and the floating-point\n"
                         "              environment self-check; exits 1 if the check fails\n"
                         "  -h, --help  print this help\n"
                         "\n"
                         "Exit status: 0 success, 1 floating-point environment check failed,\n"
                         "2 usage error, 3 internal error.");
}

std::string_view verdict_text(bool passed) {
    return passed ? "PASS" : "FAIL";
}

int print_version() {
    gef::app::BuildInfo const info = gef::app::build_info();
    gef::fb::FpEnvironmentReport const report = gef::fb::check_fp_environment();

    std::println("gef {}", info.project_version);
    std::println("Copyright (C) 2026 Aurora Jahan. A port of GEF, "
                 "Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.");
    std::println("License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.");
    std::println("This is free software: you are free to change and redistribute it. "
                 "There is NO WARRANTY.");
    std::println("git revision:        {}", gef::app::git_revision());
    std::println("compiler:            {} {}", info.compiler_id, info.compiler_version);
    std::println("build preset:        {}", info.build_preset);
    std::println("build type:          {}", info.build_type);
    std::println("exact-mode FP flags: {}", info.exact_fp_flags);
    std::println("general CXX flags:   {}", info.general_cxx_flags);
    std::println("fp_environment checks:");
    for (gef::fb::FpCheckResult const& check : report.checks) {
        std::println("  [{}] {}: {}", verdict_text(check.passed), check.name, check.summary);
        std::println("         {}", check.observation);
    }
    std::println("fp_environment verdict: {}", verdict_text(report.passed));
    return report.passed ? exit_ok : exit_fp_environment_failed;
}

int run(std::span<char* const> args) {
    if (args.size() <= 1) {
        print_usage(stdout);
        return exit_ok;
    }
    if (args.size() > 2) {
        std::println(stderr, "gef: expected exactly one option, got {}", args.size() - 1);
        print_usage(stderr);
        return exit_usage_error;
    }
    // args is {program, option} here.
    std::string_view const option = args.back();
    if (option == "--version") {
        return print_version();
    }
    if (option == "--help" || option == "-h") {
        print_usage(stdout);
        return exit_ok;
    }
    std::println(stderr, "gef: unknown option '{}'", option);
    print_usage(stderr);
    return exit_usage_error;
}

} // namespace

int main(int argc, char* argv[]) {
    try {
        return run(std::span<char* const>(argv, static_cast<std::size_t>(argc)));
    } catch (std::exception const& error) {
        static_cast<void>(std::fputs("gef: internal error: ", stderr));
        static_cast<void>(std::fputs(error.what(), stderr));
        static_cast<void>(std::fputs("\n", stderr));
        return exit_internal_error;
    } catch (...) {
        static_cast<void>(std::fputs("gef: internal error: unknown exception\n", stderr));
        return exit_internal_error;
    }
}
