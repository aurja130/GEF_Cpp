// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The parameter files of `ParameterManipulation.mac` (GEF.bas:1017) and GEF.bas:2555 (M4.4):
// `MyparRead.bas`, `FitparRead.bas` (both through `ReadParameters.mac`) and
// `ParameterUpdate.mac`. File access is the caller's: the functions take a file's contents
// (`read_input_file`) and return what BASIC prints (`console`) or writes.

#pragma once

#include "fbrt/input.hpp"
#include "params/parameters.hpp"

#include <filesystem>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

namespace gef::params {

// Thrown where the BASIC program never returns (an endless loop, QUIRK(Q-035)).
class GefHangs : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

// `Fileexists(path)` then `Open path For Input`: std::nullopt when fopen(path, "r") fails
// (fb_FileExists), otherwise every byte that can be read (none for a directory, which fopen
// opens but cannot read).
[[nodiscard]] std::optional<std::string> read_input_file(std::filesystem::path const& path);

// `Do Until EOF(f) : Line Input #f, Cline : #Include "ReadParameters.mac" : Loop`, the loop
// FitparRead.bas:21-25 and MyparRead.bas:20-24 run over one file. Lines that set a parameter
// are echoed to `console`, as are the error messages.
void read_parameters(fb::InputFile& file, Parameters& p, std::vector<std::string>& console);

// FitparRead.bas: with `fitpar_dat` (the contents of Fitpar.dat when it exists) prints the
// notice and applies the file.
void fitpar_read(std::optional<std::string> const& fitpar_dat, Parameters& p,
                 std::vector<std::string>& console);

// MyparRead.bas: only when `p.b_myparameters` is set, which it never is where GEF includes the
// file (QUIRK(Q-018)).
void mypar_read(std::optional<std::string> const& myparameters_dat, Parameters& p,
                std::vector<std::string>& console);

// ParameterUpdate.mac: the text of tmp/ParameterUpdate.dat. `now` is the `Now` serial date
// stamped into its fourth line.
[[nodiscard]] std::string parameter_update_text(Parameters const& p, double now);

// ParameterManipulation.mac (GEF.bas:1017): MyparRead, FitparRead, then the ParameterUpdate
// text (returned; the caller writes tmp/ParameterUpdate.dat).
[[nodiscard]] std::string parameter_manipulation(std::optional<std::string> const& myparameters_dat,
                                                 std::optional<std::string> const& fitpar_dat,
                                                 double now, Parameters& p,
                                                 std::vector<std::string>& console);

} // namespace gef::params
