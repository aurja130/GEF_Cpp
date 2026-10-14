// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Support for the M5 physics tests (harness/drivers/M5_DRIVERS.md): the tokens of the M5
// drivers and the arglog patch, the grid axes and random draws of the drivers, the comparison
// of regenerated grid files with the driver goldens, and the replay of arglog captures.

#pragma once

#include "fbrt/rng.hpp"

#include <cstdint>
#include <functional>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace gef::test::m5 {

// --- tokens (harness/ARGLOG.md) -------------------------------------------------------------

[[nodiscard]] std::string f32(float x);
[[nodiscard]] std::string f64(double x);
[[nodiscard]] std::string i64(std::int64_t x);
[[nodiscard]] std::string u8(std::uint8_t x);
[[nodiscard]] std::string str(std::string_view s);            // hex bytes, "-" if empty
[[nodiscard]] std::string f32_list(std::span<float const> v); // "<n>[:v,v,...]"
[[nodiscard]] std::string f32_hash(std::span<float const> v);

[[nodiscard]] float parse_f32(std::string_view token);
[[nodiscard]] double parse_f64(std::string_view token);
[[nodiscard]] std::int64_t parse_i64(std::string_view token);
[[nodiscard]] std::uint8_t parse_u8(std::string_view token);
[[nodiscard]] std::string parse_str(std::string_view token);

// Tokens joined by single spaces.
[[nodiscard]] std::string join(std::initializer_list<std::string> tokens);
[[nodiscard]] std::vector<std::string> split(std::string_view line);

// --- grid inputs ----------------------------------------------------------------------------

// Value i of a structured axis: CSng(Lo + i * Stp), evaluated in Double.
[[nodiscard]] float axis(double lo, double step, std::int64_t i) noexcept;

// CSng(Lo + (Hi - Lo) * Rnd), evaluated in Double.
[[nodiscard]] float draw(fb::FbMtRng& rng, double lo, double hi) noexcept;

// --- grid files -----------------------------------------------------------------------------

// A grid file as a driver writes it: the header "# m5grid 1 <fn> <schema>" and the lines.
struct GridFile {
    std::string file;   // e.g. "Gaussintegral_grid.txt"
    std::string header; // first line
    std::vector<std::string> lines;

    GridFile(std::string file_name, std::string_view fn, std::string_view schema);
    void add(std::string line) { lines.push_back(std::move(line)); }
};

// Checks a regenerated grid file against the golden of driver capture `golden` (e.g.
// "m5-helpers"): the committed whole-file fingerprint in golden/<golden>/files.txt, and, when
// the reference store holds capture <golden>, every line, the first difference reported with
// the ULP distance of each differing f32/f64 token (by schema). Two NaN tokens of the same
// type compare equal (B-001); the fingerprint is then not decisive and is skipped with a
// warning when the store shows only NaN differences. With GEF_TEST_M5_DIR set, the lines are
// compared with $GEF_TEST_M5_DIR/<golden>/<file> (a local driver run) and the fingerprint is
// not checked.
void check_grid(std::string_view golden, GridFile const& grid);

// A text file a driver writes besides its grids (its stdout.txt, Beta_Equi_print.txt), split
// into lines: compared line by line with the store golden (or $GEF_TEST_M5_DIR, as check_grid),
// and with its committed fingerprint.
void check_text(std::string_view golden, std::string_view file,
                std::vector<std::string> const& lines);

// The lines of a PrintFile's text (LF-terminated; a last line without LF is kept).
[[nodiscard]] std::vector<std::string> text_lines(std::string const& text);

// --- arglog replay --------------------------------------------------------------------------

struct ArglogRecord {
    std::int64_t seq = 0;
    std::string site;
    std::vector<std::string> tokens; // after the 5-token prefix
};

// The records of <fn>.txt in capture <capture> (work/probes/arglog/), or nothing when the store
// or the file is absent. Fails when the header does not match `schema`.
[[nodiscard]] std::optional<std::vector<ArglogRecord>>
read_arglog(std::string_view capture, std::string_view fn, std::string_view schema);

// The M5.2 arglog captures, one per system.
[[nodiscard]] std::span<std::string_view const> arglog_captures() noexcept;

// Replays every logged call of `fn` in every arglog capture: `recompute` gets the logged
// tokens and returns the full token line (inputs echoed, outputs recomputed), which must equal
// the logged tokens (NaN tokens compare equal). Returns the number of records replayed; 0
// without the store (the caller SKIPs).
std::size_t
check_replay(std::string_view fn, std::string_view schema,
             std::function<std::string(std::vector<std::string> const&)> const& recompute);

} // namespace gef::test::m5
