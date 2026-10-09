// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Tests for gef::data::ProgramData (data/program_data.hpp) against the datachain golden
// m4-datachain (M4 plan D1): for each nuclide-data variant the item count and an FNV-1a digest
// of every DATA item, as tools/fbsrc/gen_gef_data.py --fingerprints writes them after checking
// each item against the reference-store captures.

#include "data/program_data.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>

namespace {

using gef::data::isosource;
using gef::data::NuclideData;
using gef::data::ProgramData;
using gef::test::golden_file;
using gef::test::parse_hex;
using gef::test::read_lines;

constexpr std::string_view golden = "m4-datachain";

struct VariantCase {
    std::string_view key;
    NuclideData variant;
    std::string_view isosource;
};

constexpr std::array<VariantCase, 7> variants{{
    {.key = "jeff33", .variant = NuclideData::Jeff33, .isosource = "JEFF-3.3"},
    {.key = "jeff311", .variant = NuclideData::Jeff311, .isosource = "JEFF-3.1.1"},
    {.key = "nubase2016", .variant = NuclideData::Nubase2016, .isosource = "NUBASE-2016"},
    {.key = "nubase2020", .variant = NuclideData::Nubase2020, .isosource = "NUBASE-2020"},
    {.key = "legacy-x", .variant = NuclideData::LegacyX, .isosource = "NucPropx"},
    {.key = "legacy-mf", .variant = NuclideData::LegacyMf, .isosource = "NucPropmf"},
    {.key = "legacy-f", .variant = NuclideData::LegacyF, .isosource = "NucPropf"},
}};

constexpr std::uint64_t fnv_offset = 0xCBF29CE484222325ULL;
constexpr std::uint64_t fnv_prime = 0x100000001B3ULL;

void mix(std::uint64_t& digest, char c) {
    digest = (digest ^ static_cast<std::uint64_t>(static_cast<unsigned char>(c))) * fnv_prime;
}

// The digest the generator writes: per item its uppercase hex bytes ('-' when empty), then '\n'.
std::uint64_t fingerprint(std::span<std::string_view const> items) {
    constexpr std::string_view hex_digits = "0123456789ABCDEF";
    std::uint64_t digest = fnv_offset;
    for (std::string_view const item : items) {
        if (item.empty()) {
            mix(digest, '-');
        }
        for (char const c : item) {
            auto const byte = static_cast<unsigned char>(c);
            mix(digest, hex_digits.at(static_cast<std::size_t>(byte >> 4U)));
            mix(digest, hex_digits.at(static_cast<std::size_t>(byte & 0x0FU)));
        }
        mix(digest, '\n');
    }
    return digest;
}

struct GoldenRow {
    std::size_t count;
    std::uint64_t digest;
};

// The golden's row for one variant; throws when the golden has none.
GoldenRow golden_row(std::string_view key) {
    for (std::string const& line : read_lines(golden_file(golden, "fingerprints.txt"))) {
        if (line.empty() || line.front() == '#') {
            continue;
        }
        std::istringstream fields{line};
        std::string name;
        std::string count;
        std::string digest;
        fields >> name >> count >> digest;
        if (name == key) {
            return GoldenRow{
                .count = static_cast<std::size_t>(std::stoull(count)),
                .digest = parse_hex(digest),
            };
        }
    }
    throw std::runtime_error("no golden row for " + std::string{key});
}

} // namespace

TEST_CASE("ProgramData reports each variant's ISOSOURCE", "[T0][data]") {
    for (VariantCase const& v : variants) {
        CAPTURE(v.key);
        CHECK(isosource(v.variant) == v.isosource);
    }
}

TEST_CASE("ProgramData items match the datachain golden per variant", "[T0][data]") {
    for (VariantCase const& v : variants) {
        DYNAMIC_SECTION(v.key) {
            GoldenRow const row = golden_row(v.key);

            ProgramData const data{v.variant};
            CHECK(data.variant() == v.variant);
            CHECK(data.items().size() == row.count);
            CHECK(fingerprint(data.items()) == row.digest);
        }
    }
}

TEST_CASE("ProgramData starts with the chain head's items", "[T0][data]") {
    ProgramData const data{NuclideData::Jeff33};
    REQUIRE(!data.items().empty());
    CHECK(data.items().front() == "1");
    // The head is the variant's own NUCLIDEDATA table, the first block of the chain.
    CHECK(data.label("NUCLIDEDATA") == 0);
}

TEST_CASE("ProgramData labels are case-insensitive and point at their block", "[T0][data]") {
    ProgramData const data{NuclideData::Jeff33};
    std::size_t const index = data.label("apre_hg180");
    CHECK(index == data.label("APRE_HG180"));
    REQUIRE(index < data.items().size());
    CHECK(data.items().subspan(index, 1).front() == "61");
}

TEST_CASE("ProgramData rejects a label without a DATA block", "[T0][data]") {
    ProgramData const data{NuclideData::Jeff33};
    CHECK_THROWS_AS(static_cast<void>(data.label("NO_SUCH_LABEL")), std::out_of_range);
}
