// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for gef::fb FbMtRng and the reseed derivation against FreeBASIC driver goldens
// (harness/drivers/rnd_seeds.bas, rnd_stream.bas) and the RESEED_SPEC.md vectors.

#include "fbrt/reseed.hpp"
#include "fbrt/rng.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

namespace {

using gef::test::parse_hex;
using gef::test::read_lines;

constexpr double two_32 = 4294967296.0;

struct SeedLine {
    std::size_t index;
    double seed;
    std::string text;
};

// seeds.txt: "<index> <seed Double bit pattern> <seed text>".
std::vector<SeedLine> read_seeds(std::filesystem::path const& path) {
    std::vector<SeedLine> seeds;
    for (std::string const& line : read_lines(path)) {
        std::string_view const view(line);
        std::size_t const first = view.find(' ');
        std::size_t const second = view.find(' ', first + 1);
        REQUIRE(second != std::string_view::npos);
        seeds.push_back(
            {.index = static_cast<std::size_t>(std::stoul(line.substr(0, first))),
             .seed = std::bit_cast<double>(parse_hex(view.substr(first + 1, second - first - 1))),
             .text = line.substr(second + 1)});
    }
    return seeds;
}

// Compares the Rnd stream of every seed in a rnd_seeds output directory; returns the
// number of values compared. Reports only the first mismatch of each seed.
std::size_t check_rnd_seeds(std::filesystem::path const& seeds_txt) {
    std::size_t compared = 0;
    for (SeedLine const& seed : read_seeds(seeds_txt)) {
        std::filesystem::path const stream =
            seeds_txt.parent_path() / ("seed_" + std::to_string(seed.index) + ".txt");
        std::vector<std::string> const expected = read_lines(stream);
        gef::fb::FbMtRng rng(seed.seed);
        bool first_mismatch = true;
        for (std::size_t i = 0; i < expected.size(); ++i) {
            double const value = rng.rnd();
            double const want = static_cast<double>(parse_hex(expected.at(i))) / two_32;
            if (value != want && first_mismatch) {
                first_mismatch = false;
                INFO("seed " << seed.text << ", draw " << i + 1);
                CHECK(value == want);
            }
        }
        CHECK(first_mismatch);
        compared += expected.size();
    }
    return compared;
}

} // namespace

TEST_CASE("fbrt: FbMtRng matches FreeBASIC for edge seeds", "[T2][fbrt]") {
    // 22 seeds: integer boundaries, fractions, negatives, the int64 limits, NaN, +-Inf;
    // 1300 draws each, so every stream crosses two state regenerations.
    std::filesystem::path const seeds = gef::test::golden_file("m3-rnd-seeds-edge", "seeds.txt");
    REQUIRE(check_rnd_seeds(seeds) == std::size_t{22} * 1300U);
}

TEST_CASE("fbrt: FbMtRng Rnd(n) argument semantics and lazy start-up match FreeBASIC",
          "[T2][fbrt]") {
    // startup.txt: Rnd before any Randomize.
    gef::fb::FbMtRng fresh;
    for (std::string const& line :
         read_lines(gef::test::golden_file("m3-rnd-seeds-edge", "startup.txt"))) {
        CHECK(std::bit_cast<std::uint64_t>(fresh.rnd()) == parse_hex(line));
    }

    // args.txt: after Randomize 0, 3: "<argument> <Double bit pattern>". The driver's
    // Rnd(-1) and Rnd(0.5) arguments are Single, as in the runtime's signature.
    gef::fb::FbMtRng rng(0.0);
    std::vector<std::string> const lines =
        read_lines(gef::test::golden_file("m3-rnd-seeds-edge", "args.txt"));
    REQUIRE(lines.size() == 6U);
    constexpr std::array<float, 6> arguments{1.0F, 0.0F, -1.0F, 0.5F, 0.0F, 1.0F};
    for (std::size_t i = 0; i < lines.size(); ++i) {
        std::string_view const view(lines.at(i));
        INFO(lines.at(i));
        CHECK(std::bit_cast<std::uint64_t>(rng.rnd(arguments.at(i))) ==
              parse_hex(view.substr(view.find(' ') + 1)));
    }
}

TEST_CASE("fbrt: Randomize keeps the value Rnd(0) repeats, Rnd32 does not change it",
          "[unit][fbrt]") {
    gef::fb::FbMtRng rng(42.0);
    double const first = rng.rnd();
    rng.randomize(7.0);
    CHECK(rng.rnd(0.0F) == first);
    std::uint32_t const raw = rng.next_u32();
    CHECK(rng.rnd(0.0F) == first);
    gef::fb::FbMtRng same(7.0);
    CHECK(same.next_u32() == raw);
}

TEST_CASE("fbrt: Randomize -1 (clock seed) is rejected", "[unit][fbrt]") {
    gef::fb::FbMtRng rng;
    CHECK_THROWS_AS(rng.randomize(-1.0), std::invalid_argument);
    CHECK_THROWS_AS(gef::fb::FbMtRng(-1.0), std::invalid_argument);
}

TEST_CASE("fbrt: FbMtRng matches the stored 10^6-draw FreeBASIC streams", "[T2][fbrt]") {
    std::optional<std::filesystem::path> const seeds =
        gef::test::store_file("m3-rnd-seeds-1e6", "seeds.txt");
    std::optional<std::filesystem::path> const golden_42 =
        gef::test::store_file("m1-golden-rnd-stream-42", "rnd_stream_42.txt");
    if (!seeds || !golden_42) {
        SKIP("reference store not available (validation/reference_store)");
    }
    CHECK(check_rnd_seeds(*seeds) == std::size_t{20} * 1'000'000U);

    // The M1 golden stream, written by rnd_stream.bas.
    std::vector<std::string> const expected = read_lines(*golden_42);
    REQUIRE(expected.size() == 1'000'000U);
    gef::fb::FbMtRng rng(42.0);
    std::size_t mismatches = 0;
    for (std::string const& line : expected) {
        mismatches += rng.next_u32() != parse_hex(line) ? 1U : 0U;
    }
    CHECK(mismatches == 0U);
}

// RESEED_SPEC.md section 6 (and harness/reseed.py): the vectors every implementation must
// reproduce.
TEST_CASE("fbrt: splitmix64 reproduces the RESEED_SPEC vectors", "[unit][fbrt]") {
    constexpr std::array<std::pair<std::uint64_t, std::uint64_t>, 5> vectors{{
        {0x0000000000000000ULL, 0xE220A8397B1DCDAFULL},
        {0x0000000000000001ULL, 0x910A2DEC89025CC1ULL},
        {0x0000000000000002ULL, 0x975835DE1C9756CEULL},
        {0x123456789ABCDEF0ULL, 0x161922C645CE50E8ULL},
        {0xFFFFFFFFFFFFFFFFULL, 0xE4D971771B652C20ULL},
    }};
    for (auto const& [in, out] : vectors) {
        CHECK(gef::fb::splitmix64(in) == out);
    }
}

TEST_CASE("fbrt: derive_seed reproduces the RESEED_SPEC vectors", "[unit][fbrt]") {
    using gef::fb::ReseedScope;
    // (master, scope, tuple, seed)
    using Vector = std::tuple<std::uint32_t, ReseedScope, std::vector<std::int64_t>, std::uint32_t>;
    constexpr std::int64_t int64_min = INT64_MIN;
    std::vector<Vector> const vectors{
        {0, ReseedScope::PrepassHistory, {}, 146079144U},
        {0, ReseedScope::PrepassHistory, {0, 0, 0, 0, 0}, 3023585711U},
        {1, ReseedScope::Event, {1, 1, 0, 1, 0, 0, 0, 0, 0, 1}, 1149470725U},
        {42, ReseedScope::Event, {1, 1, 1, 1, 0, 1, 0, 0, 1000, 1}, 2490878954U},
        {42, ReseedScope::Event, {1, 1, 1, 1, 0, 1, 0, 0, 1000, 2}, 4268762869U},
        {4294967295U, ReseedScope::Event, {1, 1, 1, 1, 0, 1, 0, 0, 1000, 316228}, 70534132U},
        {4294967295U, ReseedScope::Perturbation, {1, 1, 1, 1, 31}, 1098892256U},
        {12345, ReseedScope::PrepassHistory, {1, 1, 1, 1, 0}, 4271272159U},
        {12345, ReseedScope::PrepassHistory, {1, 1, 1, 1, 316227}, 237973617U},
        {12345, ReseedScope::Event, {-1, -2, -3, -4, -5, -6, -7, -8, -9, -10}, 2360404655U},
        {2147483648U, ReseedScope::PrepassHistory, {int64_min, INT64_MAX, 0, 1, -1}, 824028776U},
        {987654321, ReseedScope::Perturbation, {2, 7, 1, 4, 12}, 2980720164U},
        {7, ReseedScope::Event, {}, 1806334056U},
        {0, ReseedScope::Event, {1099511627776, -1099511627776}, 1991928469U},
    };
    for (auto const& [master, scope, tuple, seed] : vectors) {
        CHECK(gef::fb::derive_seed(master, scope, tuple) == seed);
    }
}

TEST_CASE("fbrt: reseed restarts the stream at the derived seed", "[unit][fbrt]") {
    std::array<std::int64_t, 10> const tuple{1, 1, 1, 1, 0, 1, 0, 0, 1000, 1};
    gef::fb::FbMtRng rng(5.0);
    (void)rng.rnd();
    gef::fb::reseed(rng, 42, gef::fb::ReseedScope::Event, tuple);
    gef::fb::FbMtRng expected(2490878954.0);
    for (int i = 0; i < 1000; ++i) {
        REQUIRE(rng.next_u32() == expected.next_u32());
    }
}
