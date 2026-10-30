// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Reading BASIC's probe files (harness/PROBES.md "File format") record by record, with typed
// access to scalars and arrays, so that C++ state can be set from a record (M7: P3in injection)
// and compared with another (P3).

#pragma once

#include "fbrt/array.hpp"

#include <array>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <functional>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <vector>

namespace gef::test {

// The fields of one probe line: `<ID> <context> <NAME> <idx> <type> <value>`. The context is one
// field (`-`) for T0 and four (`step=… pass=… bin=… rec=…`) otherwise. Throws on a malformed line.
struct ProbeLine {
    std::string_view id;
    std::string_view context;
    std::string_view name;
    std::string_view index;
    std::string_view type;
    std::string_view value;
};
[[nodiscard]] ProbeLine split_probe_line(std::string_view line);

// One probe invocation: its id, context and, per variable, its lines as written in the file.
struct ProbeRecord {
    std::string id;
    std::string context;
    std::map<std::string, std::vector<std::string>, std::less<>> vars;

    [[nodiscard]] bool has(std::string_view name) const;
    // The lines of `name`; throws std::runtime_error when the record lacks it.
    [[nodiscard]] std::vector<std::string> const& lines(std::string_view name) const;

    // Context fields (`step=<s> pass=<p> bin=<b> rec=<k>`); pass is empty for `pass=-`.
    [[nodiscard]] std::int64_t step() const;
    [[nodiscard]] std::optional<std::int64_t> pass() const;
    [[nodiscard]] std::string bin() const;
};

// A probe file read one record at a time. With a non-empty `keep`, only the lines of those
// variables are stored (the record is still delimited by its context).
class ProbeRecordReader {
public:
    explicit ProbeRecordReader(std::filesystem::path const& path,
                               std::set<std::string, std::less<>> keep = {});
    // The next record, or false at the end of the file.
    [[nodiscard]] bool next(ProbeRecord& record);

private:
    std::ifstream in_;
    std::string line_; // reused for every line read
    std::set<std::string, std::less<>> keep_;
    std::string pending_;
    bool has_pending_ = false;
};

// Every record of a (small) probe file.
[[nodiscard]] std::vector<ProbeRecord> read_probe_records(std::filesystem::path const& path);

// A scalar of type S (decoded bit pattern) or I; throws on another type or a missing variable.
[[nodiscard]] float single_value(ProbeRecord const& record, std::string_view name);
[[nodiscard]] std::int64_t integer_value(ProbeRecord const& record, std::string_view name);

// An array of element type S: checks that the record's bounds equal those of `a`, then sets
// every element (zero where a sparse dump omits it). Throws on a mismatch.
template <std::size_t rank>
void load_single_array(ProbeRecord const& record, std::string_view name, fb::Array<float, rank>& a);

// An array of element type S with the bounds the record gives it.
template <std::size_t rank>
[[nodiscard]] fb::Array<float, rank> read_single_array(ProbeRecord const& record,
                                                       std::string_view name);

// The indices of an element line (`3,1,47`); throws unless there are `rank` of them.
template <std::size_t rank>
[[nodiscard]] std::array<std::int64_t, rank> parse_index(std::string_view index);

} // namespace gef::test
