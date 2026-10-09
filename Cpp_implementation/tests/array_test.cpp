// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Tests for fb::Array (fbrt/array.hpp) and GEF's extend helpers (fbrt/extend.hpp) against the
// FreeBASIC driver golden m3-arrays: the operations of ops.txt are replayed on the C++ arrays and
// the state after each one is compared with state.txt. The format of the state lines is defined
// by harness/drivers/arrays.bas.

#include "fbrt/array.hpp"
#include "fbrt/extend.hpp"
#include "support/golden.hpp"

#include <catch2/catch_test_macros.hpp>

#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <iomanip>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace {

using gef::fb::Array;
using gef::fb::Bounds;
using gef::test::golden_file;
using gef::test::read_lines;

// The driver writes the elements of a Double array in full up to this many; larger arrays as
// a count and a hash.
constexpr std::size_t full_listing_limit = 4096;
constexpr std::uint64_t fnv_offset = 0xCBF29CE484222325ULL;
constexpr std::uint64_t fnv_prime = 0x100000001B3ULL;

struct Operation {
    std::string name;
    std::string array;
    std::vector<std::int64_t> numbers;
};

Operation parse_operation(std::string const& line) {
    std::istringstream in(line);
    Operation op;
    in >> op.name >> op.array;
    std::int64_t n = 0;
    while (in >> n) {
        op.numbers.push_back(n);
    }
    return op;
}

// The state of the four arrays the driver uses.
struct Arrays {
    Array<double, 1> a1;
    Array<double, 2> a2;
    Array<double, 3> a3;
    Array<std::string, 1> s1;
};

// `lbound To ubound` for each dimension, from the pairs of an operation's numbers.
template <std::size_t rank>
std::array<Bounds, rank> bounds_of(std::vector<std::int64_t> const& numbers) {
    REQUIRE(numbers.size() == 2 * rank);
    std::array<Bounds, rank> bounds{};
    for (std::size_t d = 0; d < rank; ++d) {
        bounds.at(d) = Bounds{numbers.at(2 * d), numbers.at(2 * d + 1)};
    }
    return bounds;
}

// Fill in storage (row-major) order, which is the driver's nested loop order: element k is
// seed * 100000 + k.
void fill_doubles(std::span<double> elements, std::int64_t seed) {
    double const base = static_cast<double>(seed) * 100000.0;
    double k = 0.0;
    for (double& e : elements) {
        e = base + k;
        k += 1.0;
    }
}

template <std::size_t rank>
void apply_double(Array<double, rank>& a, Operation const& op) {
    if (op.name == "redim") {
        a.redim(bounds_of<rank>(op.numbers));
    } else if (op.name == "preserve") {
        a.redim_preserve(bounds_of<rank>(op.numbers));
    } else if (op.name == "erase") {
        a.erase();
    } else if (op.name == "fill") {
        fill_doubles(a.elements(), op.numbers.at(0));
    } else {
        FAIL("unknown operation " << op.name);
    }
}

void apply(Arrays& arrays, Operation const& op) {
    if (op.name == "dump") {
        return;
    }
    if (op.array == "A1" && op.name == "extend") {
        gef::fb::extend_1dim(arrays.a1, op.numbers.at(0), op.numbers.at(1));
    } else if (op.array == "A2" && op.name == "extend") {
        gef::fb::extend_2dim(arrays.a2, op.numbers.at(0), op.numbers.at(1), op.numbers.at(2),
                             op.numbers.at(3));
    } else if (op.array == "A3" && op.name == "extend") {
        gef::fb::extend_3dim(arrays.a3, op.numbers.at(0), op.numbers.at(1), op.numbers.at(2),
                             op.numbers.at(3), op.numbers.at(4), op.numbers.at(5));
    } else if (op.array == "A1") {
        apply_double(arrays.a1, op);
    } else if (op.array == "A2") {
        apply_double(arrays.a2, op);
    } else if (op.array == "A3") {
        apply_double(arrays.a3, op);
    } else if (op.array == "S1") {
        if (op.name == "redim") {
            arrays.s1.redim(bounds_of<1>(op.numbers));
        } else if (op.name == "preserve") {
            arrays.s1.redim_preserve(bounds_of<1>(op.numbers));
        } else if (op.name == "erase") {
            arrays.s1.erase();
        } else if (op.name == "fill") {
            std::int64_t const base = op.numbers.at(0) * 100000;
            std::int64_t k = 0;
            for (std::string& s : arrays.s1.elements()) {
                s = "s" + std::to_string(base + k);
                ++k;
            }
        } else {
            FAIL("unknown operation " << op.name);
        }
    } else {
        FAIL("unknown array " << op.array);
    }
}

std::string hex_of(std::uint64_t value, int width) {
    std::ostringstream out;
    out << std::hex << std::setfill('0') << std::setw(width) << value;
    return out.str();
}

// "<index> <name> L0=.. U0=.. L-1=..,U-1=.. L1=..,U1=.. ... |" for dimensions 0, -1, 1..rank+1.
template <typename T, std::size_t rank>
std::string header(std::size_t index, std::string_view name, Array<T, rank> const& a) {
    std::string out = std::to_string(index) + " " + std::string(name) +
                      " L0=" + std::to_string(a.lbound(0)) + " U0=" + std::to_string(a.ubound(0));
    auto const add = [&out, &a](std::int64_t d) {
        out += " L" + std::to_string(d) + "=" + std::to_string(a.lbound(d)) + ",U" +
               std::to_string(d) + "=" + std::to_string(a.ubound(d));
    };
    add(-1);
    for (std::int64_t d = 1; d <= static_cast<std::int64_t>(rank) + 1; ++d) {
        add(d);
    }
    return out + " |";
}

template <std::size_t rank>
std::string dump_double(std::size_t index, std::string_view name, Array<double, rank> const& a) {
    std::string out = header(index, name, a);
    std::span<double const> const elements = a.elements();
    if (elements.size() <= full_listing_limit) {
        for (double v : elements) {
            out += " " + hex_of(std::bit_cast<std::uint64_t>(v), 16);
        }
    } else {
        std::uint64_t h = fnv_offset;
        for (double v : elements) {
            h = (h ^ std::bit_cast<std::uint64_t>(v)) * fnv_prime;
        }
        out += " #" + std::to_string(elements.size()) + " " + hex_of(h, 16);
    }
    return out;
}

std::string dump_strings(std::size_t index, std::string_view name, Array<std::string, 1> const& a) {
    std::string out = header(index, name, a);
    for (std::string const& s : a.elements()) {
        out += " ";
        for (char c : s) {
            out += hex_of(static_cast<unsigned char>(c), 2);
        }
    }
    return out;
}

std::string dump(std::size_t index, std::string const& name, Arrays const& arrays) {
    if (name == "A1") {
        return dump_double(index, name, arrays.a1);
    }
    if (name == "A2") {
        return dump_double(index, name, arrays.a2);
    }
    if (name == "A3") {
        return dump_double(index, name, arrays.a3);
    }
    return dump_strings(index, name, arrays.s1);
}

} // namespace

TEST_CASE("fbrt: arrays replay the FreeBASIC driver state after every operation", "[T1][fbrt]") {
    std::vector<std::string> const ops = read_lines(golden_file("m3-arrays", "ops.txt"));
    std::vector<std::string> const states = read_lines(golden_file("m3-arrays", "state.txt"));
    REQUIRE(ops.size() == states.size());

    Arrays arrays;
    // Once an array has mismatched, later mismatches on it are only consequences; the first
    // one is reported and replay goes on for the other arrays.
    std::set<std::string> failed;
    for (std::size_t i = 0; i < ops.size(); ++i) {
        Operation const op = parse_operation(ops.at(i));
        apply(arrays, op);
        if (failed.contains(op.array)) {
            continue;
        }
        std::string const got = dump(i + 1, op.array, arrays);
        INFO("operation " << i + 1 << ": " << ops.at(i));
        INFO("expected (state.txt): " << states.at(i));
        CHECK(got == states.at(i));
        if (got != states.at(i)) {
            failed.insert(op.array);
        }
    }
}

TEST_CASE("fbrt: Array element access is bounds-checked", "[unit][fbrt]") {
    Array<double, 1> a;
    REQUIRE_THROWS_AS(a(1), std::out_of_range);
    REQUIRE(a.lbound(1) == 0);
    REQUIRE(a.ubound(1) == -1);

    a.redim({{{1, 3}}});
    CHECK_NOTHROW(a(1));
    CHECK_NOTHROW(a(3));
    REQUIRE_THROWS_AS(a(0), std::out_of_range);
    REQUIRE_THROWS_AS(a(4), std::out_of_range);

    a.erase();
    REQUIRE_THROWS_AS(a(1), std::out_of_range);
}

TEST_CASE("fbrt: multi-dimensional Array access checks every dimension", "[unit][fbrt]") {
    Array<double, 2> b;
    b.redim({{{0, 1}, {5, 6}}});
    CHECK_NOTHROW(b(0, 5));
    CHECK_NOTHROW(b(1, 6));
    REQUIRE_THROWS_AS(b(2, 5), std::out_of_range);
    REQUIRE_THROWS_AS(b(0, 4), std::out_of_range);
    REQUIRE_THROWS_AS(b(0, 7), std::out_of_range);

    Array<std::string, 1> s;
    REQUIRE_THROWS_AS(s(0), std::out_of_range);
}
