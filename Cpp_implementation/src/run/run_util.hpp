// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Helpers shared by the sources of the run module (input parser, driver, set-up): the console
// Print forms and the barrier functions' values. Internal to gef_run.

#pragma once

#include "fbrt/text.hpp"
#include "physics/barriers.hpp"
#include "run/state.hpp"

#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace gef::run {

// `Print text;`
inline void print_part(ProcessState& process, std::string_view text) {
    process.console.print(text, fb::PrintEnd::None);
}

// `Print text`
inline void print_line(ProcessState& process, std::string_view text) {
    process.console.print(text, fb::PrintEnd::Newline);
}

// The console lines an M4/M5 function returns (std::vector<std::string>), each printed as BASIC
// printed it: one `Print line` per line (MILESTONE_6_PLAN.md D3).
inline void print_lines(ProcessState& process, std::vector<std::string> const& lines) {
    for (std::string const& line : lines) {
        print_line(process, line);
    }
}

// The value of BFTF, BFTFA or BFTFB. They print "Undefined option in BFTF" (GEF.bas:17731) only
// for a switch outside their Select Case; the set-up passes the defined switches 0, 1 and 5, so a
// reported message would mean a wrong switch in the port.
inline float barrier_value(physics::BftfResult const& result) {
    if (result.print_undefined_option) {
        throw std::logic_error("BFTF: the set-up passed an undefined switch");
    }
    return result.value;
}

// A `Bfilein = 0` branch of the set-up, reached only from the dialogue (MILESTONE_6_PLAN.md D10).
// Proof that a batch run never takes one: Bfilein is -1 at every system and step. The driver sets
// it at GEF.bas:1822 before the first round, and only GEF.bas:3130 clears it, when file.in names
// no sequence file; then no system line exists (RunDriver::begin_line).
[[noreturn]] inline void dialogue_only(char const* where) {
    throw std::logic_error(std::string(where) + ": Bfilein = 0 in the set-up of a batch run");
}

} // namespace gef::run
