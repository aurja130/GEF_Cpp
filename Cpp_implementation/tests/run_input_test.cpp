// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "data/program_data.hpp"
#include "data/tables.hpp"
#include "params/parameter_files.hpp"
#include "run/input_files.hpp"
#include "run/probes.hpp"
#include "run/state.hpp"
#include "run/workdir.hpp"
#include "support/golden.hpp"
#include "support/probe_dump.hpp"
#include "support/run_p0.hpp"

#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iterator>
#include <map>
#include <optional>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <system_error>
#include <unistd.h>
#include <utility>
#include <vector>

namespace data = gef::data;
namespace fs = std::filesystem;

namespace {

using gef::run::Flow;
using gef::run::InputRoundState;
using gef::run::ProbeSink;
using gef::run::ProcessState;
using gef::run::SequenceFileState;
using gef::run::WorkDir;
using gef::test::ProbeDump;
using gef::test::ProbeFingerprint;

// ---- The plan (tests/golden/m6-p0/plan.txt; harness/p0_golden.py) -------------------------------

struct PlanFile {
    std::string dest;   // relative to the run's work/ directory
    std::string source; // repository-relative; empty when the plan says `-`
};

struct PlanParse {
    enum class Outcome : std::uint8_t { P0, End, Hang };

    bool restart = false;
    std::int64_t ifilein = 0;
    std::int64_t emode = 0;
    std::string cfileoutlmd_full; // decoded bytes
    Outcome outcome = Outcome::End;
    std::int64_t rec = 0; // the record of a `p0=<rec>` outcome
};

struct PlanRun {
    std::int64_t number = 0;
    std::string capture;
    std::string run_dir;
    std::string filein;             // decoded contents of file.in
    std::vector<std::int64_t> work; // ids of the `file` lines copied into work/
    std::vector<PlanParse> parses;
};

struct Plan {
    std::map<std::int64_t, PlanFile> files;
    std::vector<PlanRun> runs;
};

// ---- Text helpers ----------------------------------------------------------------------------

void plan_check(bool ok, std::string const& message) {
    if (!ok) {
        throw std::runtime_error(message);
    }
}

// Splits a line on single spaces; empty fields are dropped.
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

// A decimal integer, optionally negative.
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

// A hex field of the plan: `-` is empty, otherwise two hex digits per byte.
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

// ---- Reading the plan and the golden fingerprints --------------------------------------------

// `file <id> <dest> <source|-> <sha256>`
void read_file_line(std::vector<std::string_view> const& fields, Plan& plan) {
    plan_check(fields.size() == 5, "plan: bad file line");
    PlanFile entry;
    entry.dest = std::string(fields.at(2));
    entry.source = fields.at(3) == "-" ? std::string{} : std::string(fields.at(3));
    plan.files[to_int(fields.at(1))] = std::move(entry);
}

// `parse <restart> <ifilein> <emode> <cfileoutlmd_full|-> <outcome>`; the outcome is `end`,
// `hang` or `p0=<rec>`.
PlanParse read_parse_line(std::vector<std::string_view> const& fields) {
    plan_check(fields.size() == 6, "plan: bad parse line");
    PlanParse parse;
    parse.restart = to_int(fields.at(1)) == 1;
    parse.ifilein = to_int(fields.at(2));
    parse.emode = to_int(fields.at(3));
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

using GoldenKey = std::pair<std::int64_t, std::int64_t>; // (run, rec)
using GoldenMap = std::map<GoldenKey, ProbeFingerprint>;

GoldenMap read_golden(std::vector<std::string> const& lines) {
    GoldenMap golden;
    for (std::string const& line : lines) {
        std::vector<std::string_view> const fields = split_fields(line);
        if (fields.empty() || fields.front().starts_with('#')) {
            continue;
        }
        plan_check(fields.size() == 4, "fingerprints: bad row '" + line + "'");
        ProbeFingerprint const fingerprint{.lines = static_cast<std::size_t>(to_int(fields.at(2))),
                                           .fnv = gef::test::parse_hex(fields.at(3))};
        GoldenKey const key{to_int(fields.at(0)), to_int(fields.at(1))};
        bool const inserted = golden.emplace(key, fingerprint).second;
        plan_check(inserted, "fingerprints: duplicate row '" + line + "'");
    }
    return golden;
}

// ---- BASIC's P0.txt --------------------------------------------------------------------------

using BasicRecord = std::map<std::string, std::vector<std::string>>; // NAME -> its P0 lines
using StoreRecords = std::optional<std::map<std::int64_t, BasicRecord>>;

// Lines are `P0 step=- pass=- bin=- rec=<k> NAME <type tokens...>`, grouped by record and NAME.
std::map<std::int64_t, BasicRecord> read_basic_p0(fs::path const& path) {
    std::map<std::int64_t, BasicRecord> records;
    for (std::string const& line : gef::test::read_lines(path)) {
        std::vector<std::string_view> const fields = split_fields(line);
        if (fields.size() < 6 || fields.at(0) != "P0") {
            continue;
        }
        plan_check(fields.at(4).starts_with("rec="), "P0.txt: bad line '" + line + "'");
        records[to_int(fields.at(4).substr(4))][std::string(fields.at(5))].push_back(line);
    }
    return records;
}

// The first variable, in ascending NAME order, whose lines differ from BASIC's or that is
// missing on either side.
std::optional<std::string> first_difference(BasicRecord const& basic, ProbeDump const& dump) {
    std::vector<std::string> const dump_names = dump.names();
    std::set<std::string> names(dump_names.begin(), dump_names.end());
    for (auto const& entry : basic) {
        names.insert(entry.first);
    }
    for (std::string const& name : names) {
        auto const found = basic.find(name);
        bool const in_dump = std::ranges::binary_search(dump_names, name);
        if (found == basic.end() || !in_dump || found->second != dump.lines(name)) {
            return name;
        }
    }
    return std::nullopt;
}

// The fingerprint that fingerprints.txt records: every variable's lines in ascending NAME order.
ProbeFingerprint fingerprint_of(ProbeDump const& dump) {
    std::vector<std::string> all;
    for (std::string const& name : dump.names()) {
        std::vector<std::string> const& variable = dump.lines(name);
        all.insert(all.end(), variable.begin(), variable.end());
    }
    return gef::test::fingerprint_lines(all);
}

std::string hex16(std::uint64_t value) {
    std::ostringstream out;
    out << std::hex << std::setw(16) << std::setfill('0') << value;
    return out.str();
}

std::string describe(ProbeFingerprint const& fingerprint) {
    return std::to_string(fingerprint.lines) + " lines, fnv " + hex16(fingerprint.fnv);
}

// ---- The replay ------------------------------------------------------------------------------

// Receives the P0 dump of each sequence-file parse the replay makes.
class P0Sink final : public ProbeSink {
public:
    void sequence_file(ProcessState const& process, InputRoundState const& round,
                       SequenceFileState const& file) override {
        ++records;
        pending.emplace(gef::test::dump_p0(process, round, file, records));
    }

    std::int64_t records = 0;
    std::optional<ProbeDump> pending;
};

struct Tally {
    std::set<GoldenKey> missing;    // golden rows of replayed runs not yet matched by a parse
    std::size_t store_compared = 0; // P0 records compared with BASIC's P0.txt
};

// Empties a scratch directory on construction and removes it on destruction.
class ScopedDir {
public:
    explicit ScopedDir(fs::path path) : path_(std::move(path)) { remove(); }
    ~ScopedDir() { remove(); }
    ScopedDir(ScopedDir const&) = delete;
    ScopedDir& operator=(ScopedDir const&) = delete;
    ScopedDir(ScopedDir&&) = delete;
    ScopedDir& operator=(ScopedDir&&) = delete;

private:
    void remove() {
        std::error_code ignored;
        static_cast<void>(fs::remove_all(path_, ignored));
    }

    fs::path path_;
};

void write_bytes(fs::path const& path, std::string const& bytes) {
    std::ofstream out(path, std::ios::binary);
    plan_check(out.is_open(), "cannot create " + path.string());
    out.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
    out.close();
    plan_check(!out.fail(), "cannot write " + path.string());
}

// A run is replayable from the repository when every file it copies has a source present there.
bool replayable(PlanRun const& run, std::map<std::int64_t, PlanFile> const& files,
                fs::path const& repo) {
    return std::ranges::all_of(run.work, [&](std::int64_t const id) {
        std::string const& source = files.at(id).source;
        return !source.empty() && fs::is_regular_file(repo / source);
    });
}

// The run's directory in the reference store, when the store holds it.
std::optional<fs::path> store_run(PlanRun const& run) {
    std::optional<fs::path> const marker =
        gef::test::store_file(run.capture, run.run_dir + "/run.json");
    if (!marker.has_value()) {
        return std::nullopt;
    }
    return marker->parent_path();
}

std::string read_bytes(fs::path const& path) {
    std::ifstream in(path, std::ios::binary);
    plan_check(in.is_open(), "cannot open " + path.string());
    return {std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>()};
}

// Checks the P0 record `rec` of one run against its golden fingerprint and, when BASIC's P0.txt
// is present, names the first variable that differs from it.
void check_record(GoldenMap const& golden, Tally& tally, std::int64_t run_number, std::int64_t rec,
                  ProbeDump const& dump, StoreRecords const& basic) {
    std::string const row = "run " + std::to_string(run_number) + " rec " + std::to_string(rec);
    GoldenKey const key{run_number, rec};
    auto const golden_row = golden.find(key);
    if (golden_row == golden.end()) {
        FAIL_CHECK("no fingerprints.txt row for " + row);
        return;
    }
    tally.missing.erase(key);

    ProbeFingerprint const actual = fingerprint_of(dump);
    if (!(actual == golden_row->second)) {
        FAIL_CHECK("P0 fingerprint of " + row + " is " + describe(actual) +
                   "; fingerprints.txt has " + describe(golden_row->second));
    }

    if (basic.has_value()) {
        auto const record = basic->find(rec);
        if (record == basic->end()) {
            FAIL_CHECK("BASIC's P0.txt has no record for " + row);
        } else if (auto const difference = first_difference(record->second, dump);
                   difference.has_value()) {
            FAIL_CHECK("variable " + *difference + " differs from BASIC's P0.txt for " + row);
        } else {
            ++tally.store_compared;
        }
    }
}

// Performs one parse of a run and checks its outcome against the plan; returns whether the
// checks of the parse passed. A parse that wrote no P0 record fails and returns false.
bool perform_parse(PlanParse const& parse, ProcessState& process, InputRoundState& round,
                   SequenceFileState& file, WorkDir const& workdir, P0Sink& sink,
                   GoldenMap const& golden, Tally& tally, std::int64_t run_number,
                   StoreRecords const& basic) {
    std::int64_t const records_before = sink.records;
    bool ok = true;
    switch (parse.outcome) {
    case PlanParse::Outcome::P0: {
        Flow const flow = gef::run::read_sequence_file(process, round, file, workdir);
        ok = flow == Flow::Proceed && sink.pending.has_value() && sink.records == parse.rec;
        CHECK(flow == Flow::Proceed);
        CHECK(sink.records == parse.rec);
        if (!sink.pending.has_value()) {
            FAIL_CHECK("the parse wrote no P0 record");
            return false;
        }
        std::size_t const compared_before = tally.store_compared;
        check_record(golden, tally, run_number, parse.rec, *sink.pending, basic);
        ok = ok && (!basic.has_value() || tally.store_compared > compared_before);
        break;
    }
    case PlanParse::Outcome::End: {
        Flow const flow = gef::run::read_sequence_file(process, round, file, workdir);
        ok = flow == Flow::End && sink.records == records_before;
        CHECK(flow == Flow::End);
        CHECK(sink.records == records_before);
        break;
    }
    case PlanParse::Outcome::Hang: {
        bool hung = false;
        try {
            static_cast<void>(gef::run::read_sequence_file(process, round, file, workdir));
        } catch (gef::params::GefHangs const&) {
            hung = true;
        }
        ok = hung;
        CHECK(hung);
        break;
    }
    }
    return ok;
}

// This test process's scratch root; the process id in its name keeps processes apart.
fs::path process_scratch_root() {
    return fs::temp_directory_path() / ("gef-m6-p0-" + std::to_string(getpid()));
}

// Fills a scratch work/ directory from the repository: file.in, then each copied source.
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

// Start-up as BASIC runs it before file.in is read: Parameters.bas and
// ParameterManipulation.mac (GEF.bas:1015-1017; FitparRead applies Fitpar.dat when present,
// which sets D_Par_Fac and EOscale, both P0 variables). bfilein: file.in exists
// (GEF.bas:1821-1822).
void start_up(ProcessState& process, WorkDir const& workdir,
              std::vector<std::string>& parameter_console) {
    gef::params::load_parameters_bas(process.params);
    static_cast<void>(gef::params::parameter_manipulation(workdir.read("MyParameters.dat"),
                                                          workdir.read("Fitpar.dat"), 0.0,
                                                          process.params, parameter_console));
    process.bfilein = -1;
}

// Nextfitloop (GEF.bas:2519-2684): FitparRead again (2555), then the round's variables start
// afresh and file.in is read.
void begin_round(ProcessState& process, InputRoundState& round, SequenceFileState& file,
                 WorkDir const& workdir, std::vector<std::string>& parameter_console) {
    gef::params::fitpar_read(workdir.read("Fitpar.dat"), process.params, parameter_console);
    round = InputRoundState{};
    gef::run::read_file_in(process, round, file, workdir);
}

// The first offset at or after `from` where `prefix` begins a line of `text`, or npos.
std::size_t find_line_start(std::string const& text, std::string_view prefix, std::size_t from) {
    std::size_t pos = text.find(prefix, from);
    while (pos != std::string::npos && pos != 0 && text.at(pos - 1) != '\n') {
        pos = text.find(prefix, pos + 1);
    }
    return pos;
}

// The lines of `text` without their '\n'; a final '\n' does not begin another line.
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

// Names the first line where the two texts differ (1-based), or says that only the line endings
// differ.
std::string first_line_difference(std::string_view basic, std::string const& printed) {
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

// One run's stdout.log, and how far the console text checked so far reaches into it.
struct StdoutLog {
    std::string text;
    std::size_t matched = 0;
};

// Checks that the console text one parse printed occurs in stdout.log at the parse's anchor,
// after the text of the previous parse. Reports the failure and returns false when it does not.
// An End or hang parse must also end stdout.log. Where a parse that wrote P0 ends is not
// checked: BASIC's system loop prints next, usually a " " line like the parser's own first line
// (GEF.bas:2770), so only the run driver can place that boundary; the byte-equal console test
// of M6.5 covers it.
bool check_console(PlanRun const& run, std::size_t index, PlanParse const& parse,
                   std::string const& printed, StdoutLog& stdout_log) {
    std::string_view const prefix =
        parse.restart ? "File 'file.in' found." : " \nSequence of nuclei given in ";
    std::string const kind = parse.restart
                                 ? "line 'File 'file.in' found.'"
                                 : "blank line followed by 'Sequence of nuclei given in '";
    std::string const where =
        "run " + std::to_string(run.number) + ", parse " + std::to_string(index + 1);
    std::size_t const anchor = find_line_start(stdout_log.text, prefix, stdout_log.matched);
    if (anchor == std::string::npos) {
        FAIL_CHECK(where + ": no " + kind + " at or after offset " +
                   std::to_string(stdout_log.matched) + " of stdout.log");
        return false;
    }
    if (stdout_log.text.compare(anchor, printed.size(), printed) != 0) {
        std::string_view const basic =
            std::string_view{stdout_log.text}.substr(anchor, printed.size());
        FAIL_CHECK(where + " (expected " + kind + " at offset " + std::to_string(anchor) +
                   "): " + first_line_difference(basic, printed));
        return false;
    }
    stdout_log.matched = anchor + printed.size();
    if (parse.outcome != PlanParse::Outcome::P0 && stdout_log.matched != stdout_log.text.size()) {
        FAIL_CHECK(where + ": stdout.log continues after the end of the run (offset " +
                   std::to_string(stdout_log.matched) + " of " +
                   std::to_string(stdout_log.text.size()) + ")");
        return false;
    }
    return true;
}

// Replays one plan run, from the store's work/ directory when the store holds the run, otherwise
// from a scratch work/ directory filled from the repository, and performs each parse in plan
// order (harness/p0_golden.py, module docstring). Stops at the first parse that fails, so one
// defect does not cascade into every later parse of the run.
void replay_run(PlanRun const& run, std::map<std::int64_t, PlanFile> const& files,
                fs::path const& repo, data::TableSet const& tables, GoldenMap const& golden,
                Tally& tally) {
    INFO("run " + std::to_string(run.number) + " " + run.capture + " " + run.run_dir);

    std::optional<fs::path> const stored = store_run(run);
    std::optional<ScopedDir> scratch;
    fs::path root;
    if (stored.has_value()) {
        root = *stored / "work";
    } else {
        root = process_scratch_root() / ("run-" + std::to_string(run.number));
        scratch.emplace(root);
        fill_scratch(run, repo, files, root);
    }
    WorkDir const workdir{root};

    ProcessState process{tables};
    std::vector<std::string> parameter_console;
    start_up(process, workdir, parameter_console);
    P0Sink sink;
    process.probes = &sink;
    InputRoundState round;
    SequenceFileState file;

    StoreRecords basic;
    std::optional<StdoutLog> stdout_log;
    if (stored.has_value()) {
        // A run whose only parse ends or hangs before GEF.bas:3128 wrote no P0.txt.
        fs::path const p0 = *stored / "work" / "probes" / "P0.txt";
        basic = fs::is_regular_file(p0) ? read_basic_p0(p0) : std::map<std::int64_t, BasicRecord>{};
        stdout_log = StdoutLog{.text = read_bytes(*stored / "stdout.log")};
    }

    for (std::size_t index = 0; index < run.parses.size(); ++index) {
        PlanParse const& parse = run.parses.at(index);
        std::size_t const console_mark = process.console.text().size();
        if (parse.restart) {
            begin_round(process, round, file, workdir, parameter_console);
        }
        // The values code outside the parser leaves between files (harness/p0_golden.py, module
        // docstring); the driver test of M6.5 checks them end to end. A "-" seed of
        // Cfileoutlmd_full decodes to ""; the parse overwrites it, so it is not recorded.
        round.ifilein = parse.ifilein;
        process.params.emode = parse.emode;
        process.cfileoutlmd_full = parse.cfileoutlmd_full;
        sink.pending.reset();
        bool ok = perform_parse(parse, process, round, file, workdir, sink, golden, tally,
                                run.number, basic);
        if (parse.outcome == PlanParse::Outcome::P0 && !sink.pending.has_value()) {
            // The parse wrote no P0 record, which FAIL_CHECK has reported: the run ends here.
            return;
        }

        // BASIC's console: the text this parse printed must occur in stdout.log at its anchor,
        // after the text the previous parse ended on (check_console).
        if (stdout_log.has_value()) {
            std::string const printed = process.console.text().substr(console_mark);
            if (!check_console(run, index, parse, printed, *stdout_log)) {
                ok = false;
            }
        }
        if (!ok) {
            return;
        }
    }
}

} // namespace

TEST_CASE("run: every sequence-file parse of the M6 captures equals BASIC's P0", "[T1][run]") {
    Plan const plan = read_plan(gef::test::read_lines(gef::test::golden_file("m6-p0", "plan.txt")));
    GoldenMap const golden =
        read_golden(gef::test::read_lines(gef::test::golden_file("m6-p0", "fingerprints.txt")));
    fs::path const repo{GEF_TEST_REPO_DIR};

    std::vector<PlanRun const*> todo;
    for (PlanRun const& run : plan.runs) {
        if (store_run(run).has_value() || replayable(run, plan.files, repo)) {
            todo.push_back(&run);
        }
    }
    if (todo.size() < plan.runs.size()) {
        WARN(std::to_string(plan.runs.size() - todo.size()) + " of " +
             std::to_string(plan.runs.size()) +
             " plan runs are not replayed: the store lacks them and a source they copy is absent "
             "from the repository");
    }
    if (todo.empty()) {
        WARN("no plan run is replayable; nothing was checked");
        return;
    }

    std::set<std::int64_t> replayed;
    for (PlanRun const* run : todo) {
        replayed.insert(run->number);
    }
    Tally tally;
    for (auto const& entry : golden) {
        if (replayed.contains(entry.first.first)) {
            tally.missing.insert(entry.first);
        }
    }

    data::TableSet const tables = data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    ScopedDir const scratch{process_scratch_root()};
    for (PlanRun const* run : todo) {
        try {
            replay_run(*run, plan.files, repo, tables, golden, tally);
        } catch (std::exception const& error) {
            FAIL_CHECK("run " + std::to_string(run->number) + " aborted: " + error.what());
        }
    }

    for (GoldenKey const& key : tally.missing) {
        FAIL_CHECK("no P0 record checked for run " + std::to_string(key.first) + " rec " +
                   std::to_string(key.second));
    }
    if (tally.store_compared == 0) {
        WARN("BASIC's P0.txt was not found for any replayed run; only the fingerprints were "
             "checked");
    }
}

TEST_CASE("run: more than 5000 system lines overflow S_par", "[run]") {
    fs::path const source =
        fs::path{GEF_TEST_REPO_DIR} / "harness" / "inputs" / "m6" / "edge" / "x_s_par_overflow.in";
    if (!fs::is_regular_file(source)) {
        SKIP("harness/inputs/m6/edge/x_s_par_overflow.in is absent from the repository");
        return;
    }
    ScopedDir const process_root{process_scratch_root()};
    fs::path const root = process_scratch_root() / "s-par-overflow";
    static_cast<void>(fs::create_directories(root / "in"));
    plan_check(fs::copy_file(source, root / "in" / "x.in", fs::copy_options::overwrite_existing),
               "cannot copy " + source.string());
    write_bytes(root / "file.in", "\"in/x.in\"\nEND\n");
    WorkDir const workdir{root};
    data::TableSet const tables = data::load_tables(data::ProgramData(data::NuclideData::Jeff33));
    ProcessState process{tables};
    std::vector<std::string> parameter_console;
    start_up(process, workdir, parameter_console);
    InputRoundState round;
    SequenceFileState file;
    gef::run::read_file_in(process, round, file, workdir);
    round.ifilein = 1;
    CHECK_THROWS_AS(static_cast<void>(gef::run::read_sequence_file(process, round, file, workdir)),
                    std::out_of_range);
}

TEST_CASE("run: WorkDir names a file as fb_FileExists and Open do", "[run]") {
    ScopedDir const process_root{process_scratch_root()};
    fs::path const root = process_scratch_root() / "names";
    static_cast<void>(fs::create_directories(root / "in"));
    write_bytes(root / "in" / "a.in", "NITER(1)\n");
    WorkDir const workdir{root};
    CHECK_FALSE(workdir.exists("in\\a.in"));
    CHECK(workdir.exists("in/a.in"));
    std::optional<std::string> const content = workdir.read("in\\a.in");
    if (content.has_value()) {
        CHECK(*content == "NITER(1)\n");
    } else {
        FAIL_CHECK("WorkDir::read did not find in\\a.in");
    }
    CHECK_FALSE(workdir.exists(""));
    CHECK_FALSE(workdir.read("").has_value());
}
