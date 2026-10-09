// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// C++ side of the harness probes (harness/PROBES.md "File format"): writes values in exactly
// the line format the BASIC probes write, so C++ state can be compared with T0/P1/P2/P3
// dumps line by line or through per-variable fingerprints (M4).

#pragma once

#include "fbrt/array.hpp"

#include <cstddef>
#include <cstdint>
#include <map>
#include <string>
#include <string_view>
#include <vector>

namespace gef::test {

// Per-variable fingerprint: number of lines and FNV-1a-64 over the bytes of every line of the
// variable followed by '\n' (h = 0xCBF29CE484222325; h = (h ^ byte) * 0x100000001B3).
struct ProbeFingerprint {
    std::size_t lines = 0;
    std::uint64_t fnv = 0xCBF29CE484222325ULL;

    friend bool operator==(ProbeFingerprint const&, ProbeFingerprint const&) = default;
};

class ProbeDump {
public:
    explicit ProbeDump(std::string id = "T0", std::string context = "-");

    // Scalars: type S (float), D (double), I (integers), Z (string).
    void scalar(std::string_view name, float value);
    void scalar(std::string_view name, double value);
    void scalar(std::string_view name, std::int64_t value);
    void scalar(std::string_view name, std::string_view value);

    // Whole arrays: bounds record (`B`, or `BS` when sparse) and the elements, last index
    // fastest; sparse dumps omit elements whose bit pattern is all zero.
    template <typename T, std::size_t rank>
    void array(std::string_view name, fb::Array<T, rank> const& a, bool sparse = false);

    // A field of a 1-dimensional UDT array (`NucTab.R_AWR`): `field(rec)` returns the value.
    template <typename Rec, typename Field>
    void field(std::string_view name, fb::Array<Rec, 1> const& records, Field field);

    // An array field of a 1-dimensional UDT array (`Isotab.R_SPI`, record index first):
    // `field(rec)` returns the fb::Array<T, 1> member.
    template <typename Rec, typename Field>
    void array_field(std::string_view name, fb::Array<Rec, 1> const& records, Field field);

    [[nodiscard]] std::vector<std::string> const& lines(std::string_view name) const;
    [[nodiscard]] ProbeFingerprint fingerprint(std::string_view name) const;

private:
    std::string id_;
    std::string context_;
    std::map<std::string, std::vector<std::string>, std::less<>> lines_;
};

// The fingerprint of any sequence of lines (e.g. a whole file, `harness.probe_fingerprints
// --files`).
[[nodiscard]] ProbeFingerprint fingerprint_lines(std::vector<std::string> const& lines);

// The committed fingerprints of one probe file (see tools for how they are produced):
// lines `<NAME> <line count> <fnv 16 hex>`.
[[nodiscard]] std::map<std::string, ProbeFingerprint, std::less<>>
read_fingerprints(std::string_view golden_name, std::string_view file);

} // namespace gef::test

#include "support/probe_dump_impl.hpp" // template definitions
