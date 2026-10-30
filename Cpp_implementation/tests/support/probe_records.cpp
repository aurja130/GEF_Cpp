// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "support/probe_records.hpp"

#include <array>
#include <bit>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace gef::test {

namespace {

[[noreturn]] void fail(std::string const& message) {
    throw std::runtime_error("probe file: " + message);
}

// The next space-separated field of `rest`, which is advanced past it and its separator.
std::string_view take_field(std::string_view& rest, std::string_view line) {
    std::size_t const space = rest.find(' ');
    if (space == std::string_view::npos) {
        fail("too few fields in line: " + std::string(line));
    }
    std::string_view const field = rest.substr(0, space);
    rest.remove_prefix(space + 1);
    return field;
}

std::int64_t to_int64(std::string_view text) {
    std::int64_t value = 0;
    char const* const last = std::to_address(text.end());
    auto const [end, error] = std::from_chars(std::to_address(text.begin()), last, value);
    if (error != std::errc{} || end != last) {
        fail("not an integer: " + std::string(text));
    }
    return value;
}

float decode_single(std::string_view hex) {
    std::uint32_t bits = 0;
    char const* const last = std::to_address(hex.end());
    auto const [end, error] = std::from_chars(std::to_address(hex.begin()), last, bits, 16);
    if (hex.size() != 8 || error != std::errc{} || end != last) {
        fail("not a Single bit pattern: " + std::string(hex));
    }
    return std::bit_cast<float>(bits);
}

// The scalar line of `name` (exactly one line with index `-`).
ProbeLine scalar_line(ProbeRecord const& record, std::string_view name) {
    std::vector<std::string> const& lines = record.lines(name);
    if (lines.size() != 1) {
        fail(std::string(name) + " is not a scalar in " + record.context);
    }
    ProbeLine const line = split_probe_line(lines.front());
    if (line.index != "-") {
        fail(std::string(name) + " is not a scalar in " + record.context);
    }
    return line;
}

// The value of the context field `key=` (e.g. "pass=").
std::string_view context_field(std::string const& context, std::string_view key) {
    std::size_t const at = context.find(key);
    if (at == std::string::npos || (at != 0 && context.at(at - 1) != ' ')) {
        fail("no " + std::string(key) + " in context " + context);
    }
    std::string_view value = std::string_view(context).substr(at + key.size());
    return value.substr(0, value.find(' '));
}

} // namespace

ProbeLine split_probe_line(std::string_view line) {
    std::string_view rest = line;
    ProbeLine out;
    out.id = take_field(rest, line);
    if (rest.starts_with("- ")) {
        out.context = rest.substr(0, 1);
        rest.remove_prefix(2);
    } else {
        std::size_t length = 0;
        for (int i = 0; i < 4; ++i) {
            std::size_t const space = rest.find(' ', length);
            if (space == std::string_view::npos) {
                fail("bad context in line: " + std::string(line));
            }
            length = space + 1;
        }
        out.context = rest.substr(0, length - 1);
        rest.remove_prefix(length);
    }
    out.name = take_field(rest, line);
    out.index = take_field(rest, line);
    // `B`/`BS` for a bounds record, whose value is `<T> <bounds>`
    out.type = take_field(rest, line);
    out.value = rest;
    return out;
}

bool ProbeRecord::has(std::string_view name) const {
    return vars.contains(name);
}

std::vector<std::string> const& ProbeRecord::lines(std::string_view name) const {
    auto const it = vars.find(name);
    if (it == vars.end()) {
        fail("no variable " + std::string(name) + " in " + id + " " + context);
    }
    return it->second;
}

std::int64_t ProbeRecord::step() const {
    return to_int64(context_field(context, "step="));
}

std::optional<std::int64_t> ProbeRecord::pass() const {
    std::string_view const value = context_field(context, "pass=");
    if (value == "-") {
        return std::nullopt;
    }
    return to_int64(value);
}

std::string ProbeRecord::bin() const {
    return std::string(context_field(context, "bin="));
}

ProbeRecordReader::ProbeRecordReader(std::filesystem::path const& path,
                                     std::set<std::string, std::less<>> keep)
    : in_{path}, keep_{std::move(keep)} {
    if (!in_) {
        fail("cannot open " + path.string());
    }
}

bool ProbeRecordReader::next(ProbeRecord& record) {
    record = ProbeRecord{};
    bool first = true;
    std::string prefix; // `<ID> <context> `, shared by every line of the record
    // The lines of a variable are contiguous: decide and look its entry up once.
    std::vector<std::string>* current = nullptr; // null while the variable is not kept
    std::string current_name;
    bool have_current = false;
    auto take = [&](std::string_view text) {
        std::string_view name;
        if (!first && text.starts_with(prefix)) {
            name = text.substr(prefix.size());
            name = name.substr(0, name.find(' '));
        } else {
            ProbeLine const fields = split_probe_line(text);
            if (!first) {
                return false; // the next record's first line
            }
            record.id = std::string(fields.id);
            record.context = std::string(fields.context);
            prefix = record.id + ' ' + record.context + ' ';
            first = false;
            name = fields.name;
        }
        if (!have_current || current_name != name) {
            current_name = std::string(name);
            have_current = true;
            bool const kept = keep_.empty() || keep_.contains(current_name);
            current = kept ? &record.vars[current_name] : nullptr;
        }
        if (current != nullptr) {
            current->emplace_back(text);
        }
        return true;
    };
    if (has_pending_) {
        has_pending_ = false;
        take(pending_);
    }
    while (std::getline(in_, line_)) {
        if (!line_.empty() && line_.back() == '\r') {
            line_.pop_back();
        }
        if (line_.empty()) {
            continue;
        }
        if (!take(line_)) {
            pending_ = line_;
            has_pending_ = true;
            return true;
        }
    }
    return !first;
}

std::vector<ProbeRecord> read_probe_records(std::filesystem::path const& path) {
    std::vector<ProbeRecord> records;
    ProbeRecordReader reader(path);
    ProbeRecord record;
    while (reader.next(record)) {
        records.push_back(std::move(record));
    }
    return records;
}

float single_value(ProbeRecord const& record, std::string_view name) {
    ProbeLine const line = scalar_line(record, name);
    if (line.type != "S") {
        fail(std::string(name) + " is not a Single in " + record.context);
    }
    return decode_single(line.value);
}

std::int64_t integer_value(ProbeRecord const& record, std::string_view name) {
    ProbeLine const line = scalar_line(record, name);
    if (line.type != "I") {
        fail(std::string(name) + " is not an integer in " + record.context);
    }
    return to_int64(line.value);
}

template <std::size_t rank>
std::array<std::int64_t, rank> parse_index(std::string_view index) {
    std::array<std::int64_t, rank> out{};
    for (std::size_t d = 0; d < rank; ++d) {
        std::size_t const comma = index.find(',');
        if ((comma == std::string_view::npos) != (d + 1 == rank)) {
            fail("index " + std::string(index) + " does not have " + std::to_string(rank) +
                 " dimensions");
        }
        out.at(d) = to_int64(index.substr(0, comma));
        index.remove_prefix(comma == std::string_view::npos ? index.size() : comma + 1);
    }
    return out;
}

template std::array<std::int64_t, 1> parse_index<1>(std::string_view);
template std::array<std::int64_t, 3> parse_index<3>(std::string_view);

template <std::size_t rank>
void load_single_array(ProbeRecord const& record, std::string_view name,
                       fb::Array<float, rank>& a) {
    std::vector<std::string> const& lines = record.lines(name);
    ProbeLine const head = split_probe_line(lines.front());
    if (head.index != "-" || (head.type != "B" && head.type != "BS")) {
        fail(std::string(name) + " has no bounds record in " + record.context);
    }
    // `S lo:hi,lo:hi,...`
    std::string_view bounds = head.value;
    if (!bounds.starts_with("S ")) {
        fail(std::string(name) + " is not a Single array in " + record.context);
    }
    bounds.remove_prefix(2);
    std::array<std::int64_t, rank> lower{};
    std::array<std::int64_t, rank> extent{};
    for (std::size_t d = 0; d < rank; ++d) {
        std::size_t const comma = bounds.find(',');
        std::string_view const pair = bounds.substr(0, comma);
        std::size_t const colon = pair.find(':');
        std::int64_t const lo = to_int64(pair.substr(0, colon));
        std::int64_t const hi = to_int64(pair.substr(colon + 1));
        auto const dimension = static_cast<std::int64_t>(d + 1);
        if (lo != a.lbound(dimension) || hi != a.ubound(dimension)) {
            fail(std::string(name) + " bounds differ from the C++ array in " + record.context);
        }
        lower.at(d) = lo;
        extent.at(d) = hi - lo + 1;
        bounds.remove_prefix(comma == std::string_view::npos ? bounds.size() : comma + 1);
    }
    std::span<float> const elements = a.elements();
    std::ranges::fill(elements, 0.0F);
    bool const sparse = head.type == "BS";
    std::size_t next = 0;
    for (std::size_t i = 1; i < lines.size(); ++i) {
        ProbeLine const line = split_probe_line(lines.at(i));
        std::array<std::int64_t, rank> const index = parse_index<rank>(line.index);
        if (line.type != "S") {
            fail(std::string(name) + " has a bad element line in " + record.context);
        }
        std::size_t linear = 0;
        for (std::size_t d = 0; d < rank; ++d) {
            std::int64_t const offset = index.at(d) - lower.at(d);
            if (offset < 0 || offset >= extent.at(d)) {
                fail(std::string(name) + " element outside its bounds in " + record.context);
            }
            linear =
                linear * static_cast<std::size_t>(extent.at(d)) + static_cast<std::size_t>(offset);
        }
        if (!sparse && linear != next) {
            fail(std::string(name) + " dense dump out of order in " + record.context);
        }
        next = linear + 1;
        elements.subspan(linear, 1).front() = decode_single(line.value);
    }
    if (!sparse && next != elements.size()) {
        fail(std::string(name) + " dense dump incomplete in " + record.context);
    }
}

template void load_single_array<1>(ProbeRecord const&, std::string_view, fb::Array<float, 1>&);
template void load_single_array<3>(ProbeRecord const&, std::string_view, fb::Array<float, 3>&);

template <std::size_t rank>
fb::Array<float, rank> read_single_array(ProbeRecord const& record, std::string_view name) {
    ProbeLine const head = split_probe_line(record.lines(name).front());
    std::string_view bounds = head.value;
    if (head.index != "-" || !bounds.starts_with("S ")) {
        fail(std::string(name) + " is not a Single array in " + record.context);
    }
    bounds.remove_prefix(2);
    std::array<fb::Bounds, rank> dims{};
    for (std::size_t d = 0; d < rank; ++d) {
        std::size_t const comma = bounds.find(',');
        std::string_view const pair = bounds.substr(0, comma);
        std::size_t const colon = pair.find(':');
        dims.at(d) = fb::Bounds{to_int64(pair.substr(0, colon)), to_int64(pair.substr(colon + 1))};
        bounds.remove_prefix(comma == std::string_view::npos ? bounds.size() : comma + 1);
    }
    fb::Array<float, rank> a{dims};
    load_single_array(record, name, a);
    return a;
}

template fb::Array<float, 1> read_single_array<1>(ProbeRecord const&, std::string_view);
template fb::Array<float, 3> read_single_array<3>(ProbeRecord const&, std::string_view);

} // namespace gef::test
