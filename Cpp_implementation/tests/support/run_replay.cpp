// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "support/run_replay.hpp"

#include "params/parameter_files.hpp"
#include "params/parameters.hpp"
#include "support/golden.hpp"

#include <algorithm>
#include <cstddef>
#include <fstream>
#include <iterator>
#include <stdexcept>
#include <system_error>
#include <unistd.h>
#include <utility>

namespace fs = std::filesystem;

namespace gef::test {

namespace {

// The value of one hex digit.
int hex_value(char const digit) {
    if (digit >= '0' && digit <= '9') {
        return digit - '0';
    }
    if (digit >= 'a' && digit <= 'f') {
        return digit - 'a' + 10;
    }
    if (digit >= 'A' && digit <= 'F') {
        return digit - 'A' + 10;
    }
    throw std::runtime_error(std::string("bad hex digit '") + digit + "'");
}

// `file <id> <dest> <source|-> <sha256>`
void read_file_line(std::vector<std::string_view> const& fields, Plan& plan) {
    plan_check(fields.size() == 5, "plan: bad file line");
    PlanFile entry;
    entry.dest = std::string(fields.at(2));
    entry.source = fields.at(3) == "-" ? std::string{} : std::string(fields.at(3));
    plan.files[to_int(fields.at(1))] = std::move(entry);
}

// `parse <restart> <ifilein> <emode|-> <cfileoutlmd_full|-> <outcome>`; the outcome is `end`,
// `hang` or `p0=<rec>`.
PlanParse read_parse_line(std::vector<std::string_view> const& fields) {
    plan_check(fields.size() == 6, "plan: bad parse line");
    PlanParse parse;
    parse.restart = to_int(fields.at(1)) == 1;
    parse.ifilein = to_int(fields.at(2));
    if (fields.at(3) != "-") {
        parse.emode = to_int(fields.at(3));
    }
    parse.cfileoutlmd_full = decode_hex(fields.at(4));
    std::string_view const outcome = fields.at(5);
    if (outcome == "end") {
        parse.outcome = PlanParse::Outcome::End;
    } else if (outcome == "hang") {
        parse.outcome = PlanParse::Outcome::Hang;
    } else if (outcome.starts_with("p0=")) {
        parse.outcome = PlanParse::Outcome::P0;
        parse.rec = to_int(outcome.substr(3));
    } else {
        throw std::runtime_error("plan: bad outcome '" + std::string(outcome) + "'");
    }
    return parse;
}

// The run open at a line of the plan; `message` is thrown when no run is open.
PlanRun& require_open(std::optional<PlanRun>& open, std::string const& message) {
    if (!open.has_value()) {
        throw std::runtime_error(message);
    }
    return *open;
}

} // namespace

void plan_check(bool ok, std::string const& message) {
    if (!ok) {
        throw std::runtime_error(message);
    }
}

std::vector<std::string_view> split_fields(std::string_view line) {
    std::vector<std::string_view> fields;
    std::size_t start = 0;
    while (start <= line.size()) {
        std::size_t end = line.find(' ', start);
        if (end == std::string_view::npos) {
            end = line.size();
        }
        if (end > start) {
            fields.push_back(line.substr(start, end - start));
        }
        start = end + 1;
    }
    return fields;
}

std::int64_t to_int(std::string_view text) {
    bool const negative = text.starts_with('-');
    std::string_view const digits = negative ? text.substr(1) : text;
    plan_check(!digits.empty(), "bad integer '" + std::string(text) + "'");
    std::int64_t value = 0;
    for (char const digit : digits) {
        if (digit < '0' || digit > '9') {
            throw std::runtime_error("bad integer '" + std::string(text) + "'");
        }
        value = (value * 10) + (digit - '0');
    }
    return negative ? -value : value;
}

std::string decode_hex(std::string_view hex) {
    if (hex == "-") {
        return {};
    }
    plan_check(hex.size() % 2 == 0, "odd-length hex field '" + std::string(hex) + "'");
    std::string bytes;
    bytes.reserve(hex.size() / 2);
    for (std::size_t i = 0; i < hex.size(); i += 2) {
        bytes.push_back(static_cast<char>((hex_value(hex.at(i)) * 16) + hex_value(hex.at(i + 1))));
    }
    return bytes;
}

Plan read_plan(std::vector<std::string> const& lines) {
    Plan plan;
    std::optional<PlanRun> open;
    for (std::string const& line : lines) {
        std::vector<std::string_view> const fields = split_fields(line);
        if (fields.empty() || fields.front().starts_with('#')) {
            continue;
        }
        std::string_view const kind = fields.front();
        if (kind == "file") {
            read_file_line(fields, plan);
        } else if (kind == "run") {
            plan_check(!open.has_value() && fields.size() == 4,
                       "plan: bad run line '" + line + "'");
            open.emplace();
            open->number = to_int(fields.at(1));
            open->capture = std::string(fields.at(2));
            open->run_dir = std::string(fields.at(3));
        } else if (kind == "filein") {
            std::string const message = "plan: bad filein line '" + line + "'";
            PlanRun& run = require_open(open, message);
            plan_check(fields.size() == 2, message);
            run.filein = decode_hex(fields.at(1));
        } else if (kind == "work") {
            PlanRun& run = require_open(open, "plan: work line outside a run");
            for (std::size_t i = 1; i < fields.size(); ++i) {
                run.work.push_back(to_int(fields.at(i)));
            }
        } else if (kind == "parse") {
            PlanRun& run = require_open(open, "plan: parse line outside a run");
            run.parses.push_back(read_parse_line(fields));
        } else if (kind == "endrun") {
            PlanRun& run = require_open(open, "plan: endrun without run");
            plan.runs.push_back(std::move(run));
            open.reset();
        } else {
            throw std::runtime_error("plan: unknown line '" + line + "'");
        }
    }
    plan_check(!open.has_value(), "plan: run without endrun");
    return plan;
}

ScopedDir::ScopedDir(fs::path path) : path_(std::move(path)) {
    remove();
}

ScopedDir::~ScopedDir() {
    remove();
}

void ScopedDir::remove() {
    std::error_code ignored;
    static_cast<void>(fs::remove_all(path_, ignored));
}

fs::path process_scratch_root(std::string_view tag) {
    return fs::temp_directory_path() / ("gef-" + std::string(tag) + "-" + std::to_string(getpid()));
}

void write_bytes(fs::path const& path, std::string const& bytes) {
    std::ofstream out(path, std::ios::binary);
    plan_check(out.is_open(), "cannot create " + path.string());
    out.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
    out.close();
    plan_check(!out.fail(), "cannot write " + path.string());
}

std::string read_bytes(fs::path const& path) {
    std::ifstream in(path, std::ios::binary);
    plan_check(in.is_open(), "cannot open " + path.string());
    return {std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>()};
}

bool replayable(PlanRun const& run, std::map<std::int64_t, PlanFile> const& files,
                fs::path const& repo) {
    return std::ranges::all_of(run.work, [&](std::int64_t const id) {
        std::string const& source = files.at(id).source;
        return !source.empty() && fs::is_regular_file(repo / source);
    });
}

std::optional<fs::path> store_run(PlanRun const& run) {
    std::optional<fs::path> const marker = store_file(run.capture, run.run_dir + "/run.json");
    if (!marker.has_value()) {
        return std::nullopt;
    }
    return marker->parent_path();
}

void fill_scratch(PlanRun const& run, fs::path const& repo,
                  std::map<std::int64_t, PlanFile> const& files, fs::path const& root) {
    static_cast<void>(fs::create_directories(root));
    write_bytes(root / "file.in", run.filein);
    for (std::int64_t const id : run.work) {
        PlanFile const& plan_file = files.at(id);
        fs::path const dest = root / plan_file.dest;
        static_cast<void>(fs::create_directories(dest.parent_path()));
        plan_check(
            fs::copy_file(repo / plan_file.source, dest, fs::copy_options::overwrite_existing),
            "cannot copy " + plan_file.source + " to " + dest.string());
    }
}

void start_up(run::ProcessState& process, run::WorkDir const& workdir,
              std::vector<std::string>& parameter_console) {
    params::load_parameters_bas(process.params);
    static_cast<void>(params::parameter_manipulation(workdir.read("MyParameters.dat"),
                                                     workdir.read("Fitpar.dat"), 0.0,
                                                     process.params, parameter_console));
    // GEF.bas:1347-1394
    process.widths = params::initial_widths(process.params);
    process.bfilein = -1;
}

std::size_t find_line_start(std::string const& text, std::string_view prefix, std::size_t from) {
    std::size_t pos = text.find(prefix, from);
    while (pos != std::string::npos && pos != 0 && text.at(pos - 1) != '\n') {
        pos = text.find(prefix, pos + 1);
    }
    return pos;
}

std::vector<std::string_view> split_lines(std::string_view text) {
    std::vector<std::string_view> lines;
    std::size_t start = 0;
    while (start < text.size()) {
        std::size_t stop = text.find('\n', start);
        if (stop == std::string_view::npos) {
            stop = text.size();
        }
        lines.push_back(text.substr(start, stop - start));
        start = stop + 1;
    }
    return lines;
}

std::string first_line_difference(std::string_view basic, std::string_view printed) {
    std::string_view const missing = "<no line>";
    std::vector<std::string_view> const expected = split_lines(basic);
    std::vector<std::string_view> const actual = split_lines(printed);
    std::size_t const count = std::max(expected.size(), actual.size());
    for (std::size_t line = 0; line < count; ++line) {
        std::string_view const want = line < expected.size() ? expected.at(line) : missing;
        std::string_view const got = line < actual.size() ? actual.at(line) : missing;
        if (want != got) {
            return "line " + std::to_string(line + 1) + ": BASIC '" + std::string(want) +
                   "', C++ '" + std::string(got) + "'";
        }
    }
    return "the texts differ in line endings only";
}

std::map<std::int64_t, PlanMode> read_plan_modes(std::vector<std::string> const& lines) {
    std::map<std::int64_t, PlanMode> modes;
    std::optional<std::int64_t> current;
    bool has_mode = false;
    for (std::string const& line : lines) {
        std::vector<std::string_view> const fields = split_fields(line);
        if (fields.empty()) {
            continue;
        }
        if (fields.front() == "run") {
            plan_check(!current.has_value() && fields.size() == 4,
                       "m6-plan: bad run line '" + line + "'");
            current = to_int(fields.at(1));
            has_mode = false;
            PlanMode const mode{.capture = std::string{fields.at(2)},
                                .run_dir = std::string{fields.at(3)},
                                .full = false,
                                .exit = {}};
            plan_check(modes.try_emplace(*current, mode).second,
                       "m6-plan: repeated run " + std::to_string(*current));
        } else if (fields.front() == "mode" || fields.front() == "exit") {
            if (!current.has_value()) {
                throw std::runtime_error("m6-plan: '" + line + "' outside a run");
            }
            PlanMode& run = modes.at(*current);
            if (fields.front() == "mode") {
                plan_check(!has_mode && fields.size() == 2 &&
                               (fields.at(1) == "setup" || fields.at(1) == "full"),
                           "m6-plan: bad mode line '" + line + "'");
                run.full = fields.at(1) == "full";
                has_mode = true;
            } else {
                plan_check(fields.size() >= 2, "m6-plan: bad exit line '" + line + "'");
                // `exit fit back edge` has spaces: the rest of the line after "exit ".
                run.exit = line.substr(line.find(' ') + 1);
            }
        } else if (fields.front() == "endrun") {
            plan_check(current.has_value() && has_mode && !modes.at(*current).exit.empty(),
                       "m6-plan: endrun without a run, its mode and its exit");
            current.reset();
        }
    }
    return modes;
}

std::string describe_end(run::RunEnd end) {
    switch (end) {
    case run::RunEnd::Finished:
        return "terminated";
    case run::RunEnd::EndStatement:
        return "end";
    case run::RunEnd::FitBackEdge:
        return "fit back edge";
    case run::RunEnd::Hang:
        return "hang";
    case run::RunEnd::None:
        break;
    }
    return "not over";
}

RunRoot::RunRoot(PlanRun const& run, fs::path const& repo,
                 std::map<std::int64_t, PlanFile> const& files, std::string_view tag)
    : stored_{store_run(run)} {
    if (stored_.has_value()) {
        root_ = *stored_ / "work";
        return;
    }
    root_ = process_scratch_root(tag) / ("run-" + std::to_string(run.number));
    scratch_.emplace(root_);
    fill_scratch(run, repo, files, root_);
}

} // namespace gef::test
