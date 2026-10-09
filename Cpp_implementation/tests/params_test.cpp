// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// M4.4: nominal parameters, perturbation widths and the parameter files against the BASIC
// program: probe T0 (after ParameterManipulation.mac, GEF.bas:1017), probe P1 (after the
// width update GEF.bas:2575-2620 and the per-system Parameters.bas, GEF.bas:3320), the
// console lines of FitparRead and tmp/ParameterUpdate.dat.

#include "params/parameter_files.hpp"
#include "params/parameters.hpp"
#include "support/golden.hpp"
#include "support/probe_dump.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>
#include <variant>
#include <vector>

namespace {

using gef::params::Parameters;
using gef::params::PerturbationWidths;
using gef::test::ProbeDump;

// The probe groups "nominal parameters" and "perturbation widths" (harness/PROBES.md).
ProbeDump dump_parameters(Parameters const& p, PerturbationWidths const& w, std::string id,
                          std::string context) {
    ProbeDump dump(std::move(id), std::move(context));
    for (auto const& par : gef::params::nominal_parameters) {
        std::visit(
            [&](auto member) {
                auto const value = p.*member;
                if constexpr (std::is_same_v<decltype(value), float const>) {
                    dump.scalar(par.name, value);
                } else {
                    dump.scalar(par.name, static_cast<std::int64_t>(value));
                }
            },
            par.member);
    }
    for (auto const& width : gef::params::width_parameters) {
        dump.scalar(width.name, w.*width.member);
    }
    return dump;
}

// `skip`: variables of the probe group that the run flow, not the parameter files, sets before
// the probe (M6).
void check_against(ProbeDump const& dump, std::string_view golden, std::string_view file,
                   std::span<std::string_view const> skip = {}) {
    auto const expected = gef::test::read_fingerprints(golden, file);
    auto check = [&](std::string_view name) {
        INFO(golden << " " << name);
        auto const it = expected.find(name);
        REQUIRE(it != expected.end());
        CHECK(dump.fingerprint(name) == it->second);
    };
    for (auto const& par : gef::params::nominal_parameters) {
        if (std::ranges::find(skip, par.name) == skip.end()) {
            check(par.name);
        }
    }
    for (auto const& width : gef::params::width_parameters) {
        check(width.name);
    }
}

// Set between T0 and P1 by the input and the system set-up: `Emode` (GEF.bas:1968-1996, from
// the input), `Eexc_min_multi` (multi-chance threshold of the system) and `BFC` (third-saddle
// estimate, GEF.bas:3354).
constexpr std::array<std::string_view, 3> p1_run_flow{"Emode", "Eexc_min_multi", "BFC"};

// The `Now` serial (days since 1899-12-30 plus the fraction of the day, fb_DateSerial +
// fb_TimeSerial) of the stamp "dd.mm.yyyy, hh:mm:ss" in line 4 of ParameterUpdate.dat.
double stamp_serial(std::string const& line) {
    std::string_view const prefix = "' This update was written on ";
    REQUIRE(line.starts_with(prefix));
    std::string const s = line.substr(prefix.size());
    REQUIRE(s.size() == 20);
    auto num = [&](std::size_t pos, std::size_t len) { return std::stoi(s.substr(pos, len)); };
    using namespace std::chrono;
    auto const day = year_month_day{year{num(6, 4)}, month{static_cast<unsigned>(num(3, 2))},
                                    std::chrono::day{static_cast<unsigned>(num(0, 2))}};
    auto const days = (sys_days{day} - sys_days{1899y / December / 30}).count();
    int const seconds = (num(12, 2) * 3600) + (num(15, 2) * 60) + num(18, 2);
    return static_cast<double>(days) + (static_cast<double>(seconds) / 86400.0);
}

std::vector<std::string> split_text(std::string const& text) {
    std::vector<std::string> lines;
    std::size_t start = 0;
    while (start < text.size()) {
        std::size_t const end = text.find('\n', start);
        lines.push_back(text.substr(start, end - start));
        start = end + 1;
    }
    return lines;
}

std::optional<std::string> fitpar_dat() {
    return gef::params::read_input_file(gef::test::golden_file("m4-fitpar-files", "Fitpar.dat"));
}

// GEF.bas:1015-1017 and 1347-1394 without input files: the state probe T0 sees.
struct Startup {
    Parameters p;
    PerturbationWidths w;
    std::vector<std::string> console;
    std::string update_text;
};

Startup start_up(std::optional<std::string> const& fitpar) {
    Startup s;
    gef::params::load_parameters_bas(s.p);
    s.update_text = gef::params::parameter_manipulation(std::nullopt, fitpar, 0.0, s.p, s.console);
    s.w = gef::params::initial_widths(s.p);
    return s;
}

// From T0 to P1 of the first system: GEF.bas:2515 `Chisqr_Fit_min = 1.E10`, FitparRead at
// GEF.bas:2555, the widths of GEF.bas:2575-2620 (PZ_S3_olap_curv still 0, Q-019), and
// `If B_Fit = 0 Then #include "Parameters.bas"` at GEF.bas:3320 (QUIRK(Q-018)).
void to_first_system(Startup& s, std::optional<std::string> const& fitpar) {
    s.p.chisqr_fit_min = 0x1.2A05F2p+33F; // GEF.c: 1.E10
    gef::params::fitpar_read(fitpar, s.p, s.console);
    gef::params::update_widths(s.w, s.p, 0.0F);
    gef::params::load_parameters_bas(s.p);
}

} // namespace

TEST_CASE("Nominal parameters and initial widths equal T0", "[params][T0]") {
    Startup const s = start_up(std::nullopt);
    CHECK(s.console.empty());
    ProbeDump const dump = dump_parameters(s.p, s.w, "T0", "-");
    for (std::string_view const variant : {"m4-t0-jeff33", "m4-t0-jeff311", "m4-t0-nubase2016",
                                           "m4-t0-legacy-x", "m4-t0-legacy-mf", "m4-t0-legacy-f"}) {
        check_against(dump, variant, "T0.txt");
    }
}

TEST_CASE("Final widths and per-system parameters equal P1", "[params][T0]") {
    Startup s = start_up(std::nullopt);
    to_first_system(s, std::nullopt);
    CHECK(s.console.empty());
    check_against(dump_parameters(s.p, s.w, "P1", "step=2 pass=- bin=- rec=1"), "m4-p1-rn215",
                  "P1.txt", p1_run_flow);
}

TEST_CASE("Fitpar.dat at start-up equals T0 and the console", "[params][T0]") {
    auto const fitpar = fitpar_dat();
    REQUIRE(fitpar.has_value());
    Startup const s = start_up(fitpar);
    check_against(dump_parameters(s.p, s.w, "T0", "-"), "m4-t0-fitpar", "T0.txt");

    // The first FitparRead block of stdout.log (GEF.bas:1017).
    auto const stdout_lines =
        gef::test::read_lines(gef::test::golden_file("m4-fitpar-files", "stdout.log"));
    auto const first = std::ranges::find(stdout_lines, "File Fitpar.dat found.");
    REQUIRE(first != stdout_lines.end());
    REQUIRE(std::cmp_less_equal(s.console.size(), stdout_lines.end() - first));
    CHECK(std::vector<std::string>(first, first + static_cast<std::ptrdiff_t>(s.console.size())) ==
          s.console);
}

TEST_CASE("Fitpar.dat again at GEF.bas:2555 equals P1 and the console", "[params][T0]") {
    auto const fitpar = fitpar_dat();
    Startup s = start_up(fitpar);
    std::size_t const block = s.console.size();
    to_first_system(s, fitpar);
    check_against(dump_parameters(s.p, s.w, "P1", "step=1 pass=- bin=- rec=1"), "m4-p1-fitpar",
                  "P1.txt", p1_run_flow);

    // Both FitparRead blocks of stdout.log, the second identical to the first.
    REQUIRE(s.console.size() == 2 * block);
    auto const stdout_lines =
        gef::test::read_lines(gef::test::golden_file("m4-fitpar-files", "stdout.log"));
    auto const first = std::ranges::find(stdout_lines, "File Fitpar.dat found.");
    REQUIRE(first != stdout_lines.end());
    auto const second = std::find(first + 1, stdout_lines.end(), "File Fitpar.dat found.");
    REQUIRE(std::cmp_greater_equal(stdout_lines.end() - second, block));
    CHECK(std::vector<std::string>(second, second + static_cast<std::ptrdiff_t>(block)) ==
          std::vector<std::string>(s.console.begin() + static_cast<std::ptrdiff_t>(block),
                                   s.console.end()));
}

TEST_CASE("ParameterUpdate.dat equals the BASIC file", "[params][T0]") {
    for (bool const with_fitpar : {false, true}) {
        INFO("with Fitpar.dat: " << with_fitpar);
        auto const expected = gef::test::read_lines(
            with_fitpar ? gef::test::golden_file("m4-fitpar-files", "ParameterUpdate.dat")
                        : gef::test::golden_file("m4-parameter-update", "ParameterUpdate.dat"));
        REQUIRE(expected.size() > 4);
        Startup s = start_up(with_fitpar ? fitpar_dat() : std::nullopt);
        CHECK(split_text(gef::params::parameter_update_text(s.p, stamp_serial(expected.at(3)))) ==
              expected);
    }
}

TEST_CASE("MyParameters.dat is read only with B_MyParameters", "[params]") {
    std::string const mypar = "_P_Shell_S1 = -2.5\n";
    Parameters p;
    gef::params::load_parameters_bas(p);
    std::vector<std::string> console;
    gef::params::mypar_read(mypar, p, console);
    CHECK(console.empty());
    CHECK(p.p_shell_s1 == -0x1.266666p+1F);

    p.b_myparameters = 1;
    gef::params::mypar_read(std::nullopt, p, console);
    CHECK(console == std::vector<std::string>{"File MyParameters.dat not found."});
    console.clear();
    gef::params::mypar_read(mypar, p, console);
    CHECK(console == std::vector<std::string>{"File MyParameters.dat found.",
                                              "Parameter values from file 'MyParameters.dat' "
                                              "are used.",
                                              "_P_Shell_S1 = -2.5"});
    CHECK(p.p_shell_s1 == -2.5F);
}

TEST_CASE("An unterminated /' comment is the BASIC endless loop", "[params]") {
    Parameters p;
    std::vector<std::string> console;
    for (std::string const line : {"_P_Shell_S1 = 1 /' open", "_P_Shell_S1 = 1 '/ x /'"}) {
        INFO(line);
        gef::fb::InputFile file{line};
        CHECK_THROWS_AS(gef::params::read_parameters(file, p, console), gef::params::GefHangs);
    }
}
