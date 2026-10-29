// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// M6.4: the console of every run of the M6 captures, replayed in C++ with the real set-up
// (BatchSetup), against BASIC's stdout over the range of MILESTONE_6_PLAN.md D3: from the first
// line printed at or after Nextfitloop (GEF.bas:2519) to the end of the run (golden m6-stdout,
// harness/stdout_golden.py).
//
// A set-up run (`mode setup` in m6-plan, the GEF_SETUP_ONLY build) must print that range byte for
// byte. A full run also runs code M6 does not port; its C++ console is cut where that code runs,
// and the pieces must appear in BASIC's range in order, byte for byte, with BASIC's text between
// them only at those cuts and holding no line that only the ported code prints. Without the
// reference store a set-up run is compared through the golden's length and digest; a full run
// needs the store.

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "params/parameter_files.hpp"
#include "run/driver.hpp"
#include "run/setup.hpp"
#include "run/state.hpp"
#include "run/workdir.hpp"
#include "support/golden.hpp"
#include "support/run_replay.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <filesystem>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace data = gef::data;
namespace fs = std::filesystem;

namespace {

using gef::run::BatchSetup;
using gef::run::ProcessState;
using gef::run::RunDriver;
using gef::run::WorkDir;
using gef::test::PlanMode;
using gef::test::PlanRun;

// One row of m6-stdout/runs.txt: `<run> <mode> <start> <bytes> <fnv>`.
struct StdoutRow {
    std::string mode;
    std::int64_t start = 0; // 1-based line of stdout.log where the range starts
    std::size_t bytes = 0;
    std::uint64_t fnv = 0;
};

std::map<std::int64_t, StdoutRow> read_stdout_golden(std::vector<std::string> const& lines) {
    std::map<std::int64_t, StdoutRow> rows;
    for (std::string const& line : lines) {
        std::vector<std::string_view> const fields = gef::test::split_fields(line);
        if (fields.empty() || fields.front().starts_with('#')) {
            continue;
        }
        gef::test::plan_check(fields.size() == 5, "m6-stdout runs.txt: bad row '" + line + "'");
        StdoutRow const row{.mode = std::string{fields.at(1)},
                            .start = gef::test::to_int(fields.at(2)),
                            .bytes = static_cast<std::size_t>(gef::test::to_int(fields.at(3))),
                            .fnv = gef::test::parse_hex(fields.at(4))};
        gef::test::plan_check(rows.try_emplace(gef::test::to_int(fields.at(0)), row).second,
                              "m6-stdout runs.txt: repeated run in '" + line + "'");
    }
    return rows;
}

// FNV-1a 64 over the bytes as they are (harness.stdout_golden.fnv1a64_bytes).
std::uint64_t fnv_bytes(std::string_view text) {
    std::uint64_t h = 0xCBF29CE484222325ULL;
    for (char const c : text) {
        h = (h ^ static_cast<unsigned char>(c)) * 0x100000001B3ULL;
    }
    return h;
}

// What the C++ printed in one run, and where the code M6 does not port would print.
struct Console {
    std::string text;
    std::vector<std::size_t> body_points; // offsets in text, ascending
    std::string exit;
    bool hang_after_pass = false; // the hang came from end_pass(): BASIC waits in unported code
};

Console run_console(PlanRun const& source, PlanMode const& mode, fs::path const& repo,
                    std::map<std::int64_t, gef::test::PlanFile> const& files,
                    data::TableSet const& tables) {
    gef::test::RunRoot const run_root{source, repo, files, "m6-console"};
    WorkDir const workdir{run_root.root()};
    ProcessState process{tables};
    std::vector<std::string> parameter_console;
    gef::test::start_up(process, workdir, parameter_console);
    // start_up leaves bfilein at -1 (GEF.bas:1821-1822); the batch loop starts at 0.
    process.bfilein = 0;
    BatchSetup stages;
    RunDriver driver{process, workdir, stages};
    Console console;
    auto const body = [&console, &process] {
        console.body_points.push_back(process.console.text().size());
    };
    try {
        while (driver.next_step()) {
            if (!mode.full) {
                continue; // the GEF_SETUP_ONLY build ends the step after its set-up
            }
            // The rest of the step before its first pass header: the clearing of the CN spectra
            // and the pre-pass (GEF.bas:3882-3921, 3967-4804, M9), then CLEARspectra and the lmd
            // header (4811-5054, M10/M15).
            body();
            for (;;) {
                static_cast<void>(driver.begin_pass());
                // The pass after its header (GEF.bas:5092-15582, M10-M13), and 4811-5054 again
                // before the next pass's header (15549 `GoTo calcstart`).
                body();
                console.hang_after_pass = true;
                bool const again = driver.end_pass();
                console.hang_after_pass = false;
                if (!again) {
                    break;
                }
            }
        }
        console.exit = gef::test::describe_end(driver.end());
    } catch (gef::params::GefHangs const&) {
        console.exit = "hang";
    }
    console.text = process.console.text();
    return console;
}

// The text of `log` from its 1-based line `line` on.
std::string_view from_line(std::string const& log, std::int64_t line) {
    std::size_t offset = 0;
    for (std::int64_t i = 1; i < line; ++i) {
        std::size_t const end = log.find('\n', offset);
        gef::test::plan_check(end != std::string::npos, "stdout.log is shorter than the golden");
        offset = end + 1;
    }
    return std::string_view{log}.substr(offset);
}

// The 1-based line of `text` that holds offset `at`.
std::size_t line_of(std::string_view text, std::size_t at) {
    return 1 + static_cast<std::size_t>(std::ranges::count(text.substr(0, at), '\n'));
}

// The first line of `text`, for messages.
std::string first_line(std::string_view text) {
    return std::string{text.substr(0, text.find('\n'))};
}

// The line of `text` that starts at `at`, without its '\n'.
std::string_view line_at(std::string_view text, std::size_t at) {
    std::size_t const end = text.find('\n', at);
    return text.substr(at, end == std::string_view::npos ? std::string_view::npos : end - at);
}

// ---- IMAT numbers -----------------------------------------------------------------------------

// QUIRK(Q-021): I_MAT_ENDF gives a nuclide missing from NucTab the number IMAT_max + 1 and prints
// `<I> IMAT = <n> assigned to Z = .., A = ..` (NucProp_Functions.mac:50-52). The step body
// (M10-M13) assigns numbers too, so in a full run every number the set-up prints after a body has
// run is larger than the C++'s by the assignments BASIC printed in the bodies before it (M6.0
// patch check, F4 e_missing_nuclide).
constexpr std::string_view imat_head = "<I> IMAT = ";
constexpr std::string_view imat_tail = " assigned to ";

bool is_imat_line(std::string_view line) {
    return line.starts_with(imat_head) && line.contains(imat_tail);
}

// The number of an IMAT line, or nullopt for any other line.
std::optional<std::int64_t> imat_number(std::string_view line) {
    if (!is_imat_line(line)) {
        return std::nullopt;
    }
    std::string_view const digits =
        line.substr(imat_head.size(), line.find(imat_tail) - imat_head.size());
    if (digits.empty() ||
        !std::ranges::all_of(digits, [](char c) { return c >= '0' && c <= '9'; })) {
        return std::nullopt;
    }
    return gef::test::to_int(digits);
}

// `text` with the number of each IMAT line raised by `shift`.
std::string shift_imat_numbers(std::string_view text, std::int64_t shift) {
    std::string out;
    out.reserve(text.size());
    std::size_t start = 0;
    while (start < text.size()) {
        std::size_t end = text.find('\n', start);
        end = end == std::string_view::npos ? text.size() : end + 1;
        std::string_view const line = text.substr(start, end - start);
        std::optional<std::int64_t> const number = imat_number(line);
        if (shift != 0 && number.has_value()) {
            out.append(imat_head)
                .append(std::to_string(*number + shift))
                .append(line.substr(line.find(imat_tail)));
        } else {
            out.append(line);
        }
        start = end;
    }
    return out;
}

// ---- Full runs --------------------------------------------------------------------------------

// Lines only the ported code prints (GEF.bas:2700-2701, 2771, 3347, 3593, 3879, 5056-5057, 5070,
// 5083, 5091, 15665): none may stand in BASIC's text between two pieces or after the last one.
constexpr std::array<std::string_view, 12> ported_markers{
    "File 'file.in' found.",
    "Manual input suspended, input will be taken from file.",
    "Sequence of nuclei given in ",
    "Fission barrier of CN (",
    "CN: Z =",
    "Please wait ... code is running.",
    "Calculation (",
    "Calculation with nominal model parameters.",
    " events will be calculated.",
    "<W> The calculation with ",
    "    to grave statistical fluctuations!",
    "GEF is terminated.",
};

// The first line of `gap` that only ported code prints, or nullopt.
std::optional<std::string> ported_line_in(std::string_view gap) {
    std::size_t start = 0;
    while (start < gap.size()) {
        std::string_view const line = line_at(gap, start);
        for (std::string_view const marker : ported_markers) {
            if (line.contains(marker)) {
                return std::string{line};
            }
        }
        start += line.size() + 1;
    }
    return std::nullopt;
}

// Where a piece stands in BASIC's range, and how long BASIC's text of it is (its IMAT numbers can
// have more digits than the C++'s).
struct Match {
    std::size_t at = 0;
    std::size_t size = 0;
};

// Where `piece` starts in `basic` at or after `cursor`, at a line start, with its IMAT numbers
// raised by `shift` plus the IMAT lines BASIC printed from `cursor` to there (added to `shift`).
std::optional<Match> find_piece(std::string_view basic, std::size_t cursor, std::string_view piece,
                                std::int64_t& shift) {
    std::int64_t gap_imats = 0;
    std::string want = shift_imat_numbers(piece, shift);
    std::size_t at = cursor;
    for (;;) {
        if (basic.substr(at).starts_with(want)) {
            shift += gap_imats;
            return Match{.at = at, .size = want.size()};
        }
        std::size_t const end = basic.find('\n', at);
        if (end == std::string_view::npos) {
            return std::nullopt;
        }
        if (is_imat_line(basic.substr(at, end - at))) {
            ++gap_imats;
            want = shift_imat_numbers(piece, shift + gap_imats);
        }
        at = end + 1;
    }
}

// A full run: the C++ console cut at the body points, each piece found in BASIC's range in order
// at a line start, the first one at the start of the range; BASIC's text between two pieces is
// what the unported code printed. The range must end with the last piece unless the run hangs
// where BASIC waits in unported code (`open_end`); that text, too, holds no ported-only line.
std::optional<std::string> pieces_difference(std::string_view basic, Console const& console,
                                             bool open_end) {
    std::string_view const text{console.text};
    std::vector<std::size_t> cuts = console.body_points;
    cuts.push_back(text.size());
    std::size_t cursor = 0;
    std::size_t from = 0;
    std::int64_t shift = 0;
    bool first = true;
    for (std::size_t const cut : cuts) {
        std::string_view const piece = text.substr(from, cut - from);
        from = cut;
        if (piece.empty()) {
            continue;
        }
        if (first) {
            if (!basic.starts_with(piece)) {
                return "the console's start: " +
                       gef::test::first_line_difference(basic.substr(0, piece.size()), piece);
            }
            first = false;
            cursor = piece.size();
            continue;
        }
        std::optional<Match> const match = find_piece(basic, cursor, piece, shift);
        if (!match.has_value()) {
            std::string const want = shift_imat_numbers(piece, shift);
            std::size_t const near = basic.find(first_line(want) + "\n", cursor);
            return "the C++ text from '" + first_line(piece) +
                   "' is not in BASIC's stdout after its range line " +
                   std::to_string(line_of(basic, cursor)) +
                   (near == std::string_view::npos
                        ? std::string{}
                        : "; from range line " + std::to_string(line_of(basic, near)) + ": " +
                              gef::test::first_line_difference(basic.substr(near, want.size()),
                                                               want));
        }
        if (auto const ported = ported_line_in(basic.substr(cursor, match->at - cursor));
            ported.has_value()) {
            return "BASIC prints '" + *ported + "' before range line " +
                   std::to_string(line_of(basic, match->at)) +
                   ", where only code M6 does not port runs";
        }
        cursor = match->at + match->size;
    }
    if (auto const ported = ported_line_in(basic.substr(cursor)); ported.has_value()) {
        return "BASIC prints '" + *ported + "' after the C++ console ends";
    }
    if (cursor != basic.size() && !open_end) {
        return "BASIC's range goes on after the C++ console ends, at its line " +
               std::to_string(line_of(basic, cursor)) + ": '" + first_line(basic.substr(cursor)) +
               "'";
    }
    return std::nullopt;
}

// How a run's console was compared.
enum class Compared : std::uint8_t {
    Store,   // with BASIC's stdout.log
    Digest,  // with the golden's length and digest (set-up run, no store)
    Skipped, // not at all (full run, no store)
};

Compared check_run(PlanRun const& source, PlanMode const& mode, StdoutRow const& row,
                   fs::path const& repo, std::map<std::int64_t, gef::test::PlanFile> const& files,
                   data::TableSet const& tables) {
    INFO("run " + std::to_string(source.number) + " " + source.capture + " " + source.run_dir);
    CHECK(row.mode == (mode.full ? "full" : "setup"));
    std::optional<fs::path> const stored = gef::test::store_run(source);
    if (!stored.has_value() && mode.full) {
        return Compared::Skipped; // a full run's pieces need BASIC's text
    }
    Console const console = run_console(source, mode, repo, files, tables);
    CHECK(console.exit == mode.exit);
    if (!stored.has_value()) {
        CHECK(console.text.size() == row.bytes);
        CHECK(fnv_bytes(console.text) == row.fnv);
        return Compared::Digest;
    }
    std::string const log = gef::test::read_bytes(*stored / "stdout.log");
    std::string_view const basic = from_line(log, row.start);
    CHECK(basic.size() == row.bytes);
    CHECK(fnv_bytes(basic) == row.fnv);
    if (!mode.full) {
        if (console.text != basic) {
            FAIL_CHECK("the console differs from BASIC's stdout from its line " +
                       std::to_string(row.start) + ": " +
                       gef::test::first_line_difference(basic, console.text));
        }
        return Compared::Store;
    }
    bool const open_end = console.exit == "hang" && console.hang_after_pass;
    if (auto const difference = pieces_difference(basic, console, open_end);
        difference.has_value()) {
        FAIL_CHECK(*difference);
    }
    return Compared::Store;
}

} // namespace

TEST_CASE("run: the console of every captured run equals BASIC's stdout", "[T1][run]") {
    gef::test::Plan const sources =
        gef::test::read_plan(gef::test::read_lines(gef::test::golden_file("m6-p0", "plan.txt")));
    std::map<std::int64_t, PlanMode> const modes = gef::test::read_plan_modes(
        gef::test::read_lines(gef::test::golden_file("m6-plan", "plan.txt")));
    std::map<std::int64_t, StdoutRow> const rows =
        read_stdout_golden(gef::test::read_lines(gef::test::golden_file("m6-stdout", "runs.txt")));
    fs::path const repo{GEF_TEST_REPO_DIR};
    data::TableSet const tables = data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    gef::test::ScopedDir const scratch{gef::test::process_scratch_root("m6-console")};

    CHECK(rows.size() == sources.runs.size());
    std::map<Compared, std::size_t> counts;
    for (PlanRun const& source : sources.runs) {
        auto const mode = modes.find(source.number);
        auto const row = rows.find(source.number);
        if (mode == modes.end() || row == rows.end() || mode->second.capture != source.capture ||
            mode->second.run_dir != source.run_dir) {
            FAIL_CHECK("run " + std::to_string(source.number) +
                       " is not the same run in m6-plan and m6-stdout");
            continue;
        }
        if (!gef::test::store_run(source).has_value() &&
            !gef::test::replayable(source, sources.files, repo)) {
            ++counts[Compared::Skipped];
            continue;
        }
        try {
            ++counts[check_run(source, mode->second, row->second, repo, sources.files, tables)];
        } catch (std::exception const& error) {
            FAIL_CHECK("run " + std::to_string(source.number) + " aborted: " + error.what());
        }
    }
    if (counts[Compared::Store] < sources.runs.size()) {
        WARN(std::to_string(counts[Compared::Skipped]) + " of " +
             std::to_string(sources.runs.size()) + " runs not compared, " +
             std::to_string(counts[Compared::Digest]) +
             " compared through the golden digest only (no reference store)");
    }
}

TEST_CASE("run: a full run's console pieces follow BASIC's text only where unported code runs",
          "[run]") {
    std::string const assigned = "<I> IMAT = 10 assigned to Z = 1, A = 2\n";
    // One step's set-up, its body (which assigns IMAT 11), and the next step's set-up, which
    // assigns 12 in BASIC and 11 in the C++.
    std::string const basic = "set-up 1\n" + assigned +
                              "<I> IMAT = 11 assigned to Z = 3, A = 4\nbody\n"
                              "set-up 2\n<I> IMAT = 12 assigned to Z = 5, A = 6\n";
    Console console;
    console.text = "set-up 1\n" + assigned;
    console.body_points.push_back(console.text.size());
    console.text += "set-up 2\n<I> IMAT = 11 assigned to Z = 5, A = 6\n";

    SECTION("the IMAT numbers follow the body's assignments") {
        CHECK_FALSE(pieces_difference(basic, console, false).has_value());
    }
    SECTION("an IMAT number off by one fails, before and after a body") {
        Console first = console;
        first.text.replace(first.text.find("= 10 "), 5, "= 9 ");
        first.body_points.front() -= 1;
        CHECK(pieces_difference(basic, first, false).has_value());
        Console later = console;
        later.text.replace(later.text.find("= 11 assigned to Z = 5"), 5, "= 12 ");
        CHECK(pieces_difference(basic, later, false).has_value());
    }
    SECTION("BASIC text after the last piece fails unless the run waits in unported code") {
        std::string const longer = basic + "more\n";
        CHECK(pieces_difference(longer, console, false)
                  .value_or("")
                  .starts_with("BASIC's range goes on"));
        CHECK_FALSE(pieces_difference(longer, console, true).has_value());
        std::string const marked = basic + "Please wait ... code is running.\n";
        CHECK(pieces_difference(marked, console, true).value_or("").starts_with("BASIC prints"));
    }
    SECTION("an IMAT number that gains a digit in BASIC") {
        std::string const grown = "s\n<I> IMAT = 10 assigned to Z = 3, A = 4\nbody\n"
                                  "t\n<I> IMAT = 10 assigned to Z = 5, A = 6\n";
        Console nine;
        nine.text = "s\n";
        nine.body_points.push_back(nine.text.size());
        nine.text += "t\n<I> IMAT = 9 assigned to Z = 5, A = 6\n";
        CHECK_FALSE(pieces_difference(grown, nine, false).has_value());
    }
    SECTION("a line only ported code prints may not stand between two pieces") {
        std::string const marked = "set-up 1\n" + assigned + "Please wait ... code is running.\n" +
                                   "set-up 2\n<I> IMAT = 11 assigned to Z = 5, A = 6\n";
        CHECK(pieces_difference(marked, console, false).value_or("").starts_with("BASIC prints"));
    }
}
