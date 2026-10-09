// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "fbrt/array.hpp"
#include "support/probe_dump.hpp"

#include <catch2/catch_test_macros.hpp>

#include <bit>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace {

using gef::fb::Array;
using gef::fb::Bounds;
using gef::test::ProbeDump;
using gef::test::read_fingerprints;

struct NucRecord {
    double r_awr = 0.0;
};

struct IsoRecord {
    Array<std::int32_t, 1> i_iso;
};

} // namespace

TEST_CASE("scalars use the probe line format", "[unit][probes]") {
    ProbeDump dump;
    dump.scalar("Sx", 1.0F);
    dump.scalar("Sn", -0.0F);
    dump.scalar("Dx", 1.0);
    dump.scalar("Ix", std::int64_t{-5});
    dump.scalar("Zx", std::string_view("a\"b\\c\x01"));

    CHECK(dump.lines("Sx") == std::vector<std::string>{"T0 - Sx - S 3F800000"});
    CHECK(dump.lines("Sn") == std::vector<std::string>{"T0 - Sn - S 80000000"});
    CHECK(dump.lines("Dx") == std::vector<std::string>{"T0 - Dx - D 3FF0000000000000"});
    CHECK(dump.lines("Ix") == std::vector<std::string>{"T0 - Ix - I -5"});
    CHECK(dump.lines("Zx") == std::vector<std::string>{R"(T0 - Zx - Z "a\"b\\c\x01")"});
}

TEST_CASE("double field array: bounds and first elements match the real T0", "[unit][probes]") {
    Array<NucRecord, 1> nuc;
    nuc.redim({Bounds{0, 3852}});
    nuc(1).r_awr = 1.0;
    nuc(2).r_awr = std::bit_cast<double>(0x3FEFF92DC4763489ULL);
    nuc(3).r_awr = std::bit_cast<double>(0x3FFFF2E437D6032BULL);
    nuc(3851).r_awr = std::bit_cast<double>(0x4070ECD6138BB099ULL);

    ProbeDump dump;
    dump.field("NucTab.R_AWR", nuc, [](NucRecord const& r) { return r.r_awr; });

    auto const& lines = dump.lines("NucTab.R_AWR");
    REQUIRE(lines.size() == 3854);
    CHECK(lines.at(0) == "T0 - NucTab.R_AWR - B D 0:3852");
    CHECK(lines.at(1) == "T0 - NucTab.R_AWR 0 D 0000000000000000");
    CHECK(lines.at(2) == "T0 - NucTab.R_AWR 1 D 3FF0000000000000");
    CHECK(lines.at(3) == "T0 - NucTab.R_AWR 2 D 3FEFF92DC4763489");
    CHECK(lines.at(4) == "T0 - NucTab.R_AWR 3 D 3FFFF2E437D6032B");
    CHECK(lines.at(3852) == "T0 - NucTab.R_AWR 3851 D 4070ECD6138BB099");
}

TEST_CASE("string array: escaped Z values and bounds match the real T0", "[unit][probes]") {
    Array<std::string, 1> names;
    names.redim({Bounds{1, 120}});
    names(1) = "H";
    names(2) = "He";
    names(3) = "Li";
    names(120) = "120";

    ProbeDump dump;
    dump.array("CElement", names);

    auto const& lines = dump.lines("CElement");
    REQUIRE(lines.size() == 121);
    CHECK(lines.at(0) == "T0 - CElement - B Z 1:120");
    CHECK(lines.at(1) == R"(T0 - CElement 1 Z "H")");
    CHECK(lines.at(2) == R"(T0 - CElement 2 Z "He")");
    CHECK(lines.at(3) == R"(T0 - CElement 3 Z "Li")");
    CHECK(lines.at(120) == R"(T0 - CElement 120 Z "120")");
}

TEST_CASE("single 2-D array: row-major indices and bounds match the real T0", "[unit][probes]") {
    Array<float, 2> eldm;
    eldm.redim({Bounds{0, 203}, Bounds{0, 136}});
    eldm(1, 1) = std::bit_cast<float>(0xC180CCCDU);
    eldm(1, 2) = std::bit_cast<float>(0xC127AE14U);
    eldm(1, 3) = std::bit_cast<float>(0xBF9C28F6U);

    ProbeDump dump;
    dump.array("BEldmTF", eldm);

    auto const& lines = dump.lines("BEldmTF");
    REQUIRE(lines.size() == 1 + 204 * 137);
    CHECK(lines.at(0) == "T0 - BEldmTF - B S 0:203,0:136");
    CHECK(lines.at(1) == "T0 - BEldmTF 0,0 S 00000000");
    CHECK(lines.at(139) == "T0 - BEldmTF 1,1 S C180CCCD");
    CHECK(lines.at(140) == "T0 - BEldmTF 1,2 S C127AE14");
    CHECK(lines.at(141) == "T0 - BEldmTF 1,3 S BF9C28F6");
}

TEST_CASE("sparse array writes only non-zero bit patterns", "[unit][probes]") {
    Array<float, 2> zero;
    zero.redim({Bounds{0, 203}, Bounds{0, 136}});
    ProbeDump empty;
    empty.array("EVOD", zero, true);
    CHECK(empty.lines("EVOD") == std::vector<std::string>{"T0 - EVOD - BS S 0:203,0:136"});

    Array<float, 2> signed_zero;
    signed_zero.redim({Bounds{0, 203}, Bounds{0, 136}});
    signed_zero(5, 5) = -0.0F;
    ProbeDump sparse;
    sparse.array("EVOD", signed_zero, true);
    CHECK(sparse.lines("EVOD") ==
          std::vector<std::string>{"T0 - EVOD - BS S 0:203,0:136", "T0 - EVOD 5,5 S 80000000"});
}

TEST_CASE("array field: record index first, then member index", "[unit][probes]") {
    Array<IsoRecord, 1> iso;
    iso.redim({Bounds{0, 699}});
    for (std::int64_t r = 0; r <= 699; ++r) {
        iso(r).i_iso.redim({Bounds{0, 10}});
    }
    iso(1).i_iso(1) = 1;
    iso(2).i_iso(1) = 1;
    iso(3).i_iso(1) = 1;

    ProbeDump dump;
    dump.array_field("Isotab.I_ISO", iso,
                     [](IsoRecord const& r) -> auto const& { return r.i_iso; });

    auto const& lines = dump.lines("Isotab.I_ISO");
    REQUIRE(lines.size() == 1 + 700 * 11);
    CHECK(lines.at(0) == "T0 - Isotab.I_ISO - B I 0:699,0:10");
    CHECK(lines.at(1) == "T0 - Isotab.I_ISO 0,0 I 0");
    CHECK(lines.at(12) == "T0 - Isotab.I_ISO 1,0 I 0");
    CHECK(lines.at(13) == "T0 - Isotab.I_ISO 1,1 I 1");
}

TEST_CASE("fingerprint hashes each line plus newline (FNV-1a 64)", "[unit][probes]") {
    ProbeDump dump;
    dump.scalar("X", std::int64_t{1});
    dump.scalar("X", std::int64_t{2});
    auto const fingerprint = dump.fingerprint("X");
    CHECK(fingerprint.lines == 2);
    CHECK(fingerprint.fnv == 0x8FBC97249931DE12ULL);

    ProbeDump one;
    one.scalar("X", std::int64_t{1});
    CHECK(one.fingerprint("X").fnv == 0x4082451E44ADCB29ULL);
}

TEST_CASE("read_fingerprints parses the committed jeff33 golden", "[unit][probes]") {
    auto const fingerprints = read_fingerprints("m4-t0-jeff33", "T0.txt");
    REQUIRE(fingerprints.contains("CElement"));
    CHECK(fingerprints.at("CElement").lines == 121);
    CHECK(fingerprints.at("BEldmTF").lines == 1 + 204 * 137);
    CHECK(fingerprints.at("NucTab.R_AWR").lines == 3854);
    CHECK(fingerprints.at("EVOD").lines == 1);
}
