// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "run/input_files.hpp"

#include "fbrt/convert.hpp"
#include "fbrt/input.hpp"
#include "fbrt/strings.hpp"
#include "fbrt/text.hpp"
#include "params/parameter_files.hpp"
#include "util/utilities.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace gef::run {

namespace {

std::int64_t len_of(std::string_view s) {
    return static_cast<std::int64_t>(s.size());
}

// BASIC Left(s, n) and Right(s, n): n is clipped to 0..Len(s).
std::string left(std::string_view s, std::int64_t n) {
    auto const count = static_cast<std::size_t>(std::clamp(n, std::int64_t{0}, len_of(s)));
    return std::string{s.substr(0, count)};
}

std::string right(std::string_view s, std::int64_t n) {
    auto const count = static_cast<std::size_t>(std::clamp(n, std::int64_t{0}, len_of(s)));
    return std::string{s.substr(s.size() - count)};
}

// fb_RTRIM. Assumed to strip the trailing characters fb::trim strips (ASCII 32 and NUL). The
// FreeBASIC runtime source is not on this machine, so the NUL case is unverified.
std::string rtrim(std::string_view s) {
    auto end = s.size();
    while (end > 0 && (s[end - 1] == ' ' || s[end - 1] == '\0')) {
        --end;
    }
    return std::string{s.substr(0, end)};
}

// fb_TrimEx(s, chars): removes every leading and trailing character that occurs in chars.
// Assumed from the two-argument Trim; the FreeBASIC runtime source is not on this machine.
std::string trim_chars(std::string_view s, std::string_view chars) {
    auto const first = s.find_first_not_of(chars);
    if (first == std::string_view::npos) {
        return {};
    }
    auto const last = s.find_last_not_of(chars);
    return std::string{s.substr(first, last - first + 1)};
}

} // namespace

// GEF.bas:2699-2763 (`If Bfilein Then` through `Close #Ffilein`).
void read_file_in(ProcessState& process, InputRoundState& round, SequenceFileState& file,
                  WorkDir const& workdir) {
    // GEF.bas:2699 `If Bfilein Then`. Bfilein is -1 when file.in exists (GEF.bas:1821-1822).
    if (process.bfilein == 0) {
        return;
    }
    // GEF.bas:2700-2701
    process.console.print("File 'file.in' found.", fb::PrintEnd::Newline);
    process.console.print("Manual input suspended, input will be taken from file.",
                          fb::PrintEnd::Newline);
    // GEF.bas:2718-2719 (the `#ifdef __FB_WIN32__` lines 2710-2716 are not in the Linux C)
    process.console.print("Number of running processes:", fb::PrintEnd::None);
    process.console.print(process.i_thread, fb::PrintEnd::Newline);
    process.console.print("Maximum number of parallel processes:", fb::PrintEnd::None);
    process.console.print(process.i_thread_max, fb::PrintEnd::Newline);
    // GEF.bas:2721
    process.bplot = 0;
    // GEF.bas:2722-2723 `Ffilein = Freefile`, `Open "file.in" for input`: the file is read whole.
    auto contents = workdir.read("file.in");
    if (!contents) {
        // Unreachable: Bfilein is -1 only when WorkDir::exists("file.in") was true (GEF.bas:1821),
        // and read() opens the same path as exists() does.
        throw std::logic_error("GEF.bas:2723: file.in was found but cannot be opened");
    }
    fb::InputFile input{std::move(*contents)};
    // GEF.bas:2724 `Do Until EOF(Ffilein)`
    while (!input.eof()) {
        // GEF.bas:2725-2726
        round.chelp = input.line_input();
        round.chelp = fb::trim(round.chelp);
        if (fb::ucase(round.chelp) == "FIT") {
            // GEF.bas:2727-2731 (2732 is a comment)
            process.console.print("<I> Fit option specified in file.in.", fb::PrintEnd::Newline);
            process.b_fit = 1;
            file.b_error_on = 1;
            process.bplot = -1;
        } else if (fb::ucase(left(round.chelp, 6)) == "NITER(" && right(round.chelp, 1) == ")") {
            // GEF.bas:2733-2735
            process.console.print("<I> Input ", fb::PrintEnd::None);
            process.console.print(round.chelp, fb::PrintEnd::None);
            process.console.print(" found on file.in.", fb::PrintEnd::Newline);
            process.n_iter = fb::d2l(fb::val(fb::mid(round.chelp, 7, len_of(round.chelp) - 7)));
        } else {
            // GEF.bas:2737-2742
            round.nfilein = fb::add(round.nfilein, 1);
            if (round.nfilein >= 1000) {
                // QUIRK(candidate): the 1000th name is never stored; Nfilein is set to 1000 and
                // Cfilein(1000) keeps its initial "", so the sequence loop stops at that entry.
                process.console.print("<E> Maximum number of input files reached.",
                                      fb::PrintEnd::Newline);
                round.nfilein = 1000;
                break;
            }
            // GEF.bas:2743-2745
            if (fb::ucase(round.chelp) == "END") {
                round.nfilein = fb::sub(round.nfilein, 1);
                break;
            }
            // GEF.bas:2747
            if (left(round.chelp, 1) != "'") {
                // GEF.bas:2748-2754
                // QUIRK(candidate): names of 2 characters or fewer skip the comment cut, the
                // RTRIM and the quote removal below; they are stored as read after Trim.
                if (len_of(round.chelp) > 2) {
                    // GEF.bas:2749
                    auto const quote = fb::instr(round.chelp, "'");
                    if (quote > 0) {
                        round.chelp = fb::mid(round.chelp, 1, quote - 1);
                    }
                    // GEF.bas:2750
                    round.chelp = rtrim(round.chelp);
                    // GEF.bas:2751-2753
                    if (left(round.chelp, 1) == "\"" && right(round.chelp, 1) == "\"") {
                        round.chelp = fb::mid(round.chelp, 2, len_of(round.chelp) - 2);
                    }
                }
                // GEF.bas:2755
                round.cfilein(round.nfilein) = round.chelp;
            } else {
                // GEF.bas:2757-2758
                round.nfilein = fb::sub(round.nfilein, 1);
                process.console.print("Input ***", fb::PrintEnd::None);
                process.console.print(round.chelp, fb::PrintEnd::None);
                process.console.print("*** skipped.", fb::PrintEnd::Newline);
            }
        }
    }
    // GEF.bas:2762
    if (round.nfilein == 0) {
        process.console.print("No file with input data specified in file.in.",
                              fb::PrintEnd::Newline);
    }
    // GEF.bas:2763 `Close #Ffilein`: nothing to release, the input is an in-memory copy.
}

