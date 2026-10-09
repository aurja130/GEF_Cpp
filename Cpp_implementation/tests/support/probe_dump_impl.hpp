// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Template definitions of support/probe_dump.hpp (included at its end; do not include directly).

#pragma once

#include "fbrt/array.hpp"

#include <array>
#include <bit>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <string_view>
#include <type_traits>
#include <vector>

namespace gef::test {

namespace detail {

template <typename>
inline constexpr bool always_false = false;

template <typename T>
struct array_element;

template <typename T, std::size_t rank>
struct array_element<fb::Array<T, rank>> {
    using ElementType = T;
};

// The type token of an element: S (float), D (double), I (integer), Z (string).
template <typename T>
constexpr std::string_view type_token() {
    if constexpr (std::same_as<T, float>) {
        return "S";
    } else if constexpr (std::same_as<T, double>) {
        return "D";
    } else if constexpr (std::integral<T>) {
        return "I";
    } else if constexpr (std::same_as<T, std::string>) {
        return "Z";
    } else {
        static_assert(always_false<T>, "probe_dump: unsupported element type");
        return {};
    }
}

// The value field of one element (or scalar).
std::string single_bits(float value);
std::string double_bits(double value);
std::string quoted(std::string_view text);

template <typename T>
std::string element_text(T const& value) {
    if constexpr (std::same_as<T, float>) {
        return single_bits(value);
    } else if constexpr (std::same_as<T, double>) {
        return double_bits(value);
    } else if constexpr (std::integral<T>) {
        return std::to_string(value);
    } else if constexpr (std::same_as<T, std::string>) {
        return quoted(value);
    } else {
        static_assert(always_false<T>, "probe_dump: unsupported element type");
        return {};
    }
}

// Sparse dumps omit elements whose bit pattern is all zero (an empty string for Z).
template <typename T>
bool is_zero(T const& value) {
    if constexpr (std::same_as<T, float>) {
        return std::bit_cast<std::uint32_t>(value) == 0;
    } else if constexpr (std::same_as<T, double>) {
        return std::bit_cast<std::uint64_t>(value) == 0;
    } else if constexpr (std::integral<T>) {
        return value == 0;
    } else if constexpr (std::same_as<T, std::string>) {
        return value.empty();
    } else {
        static_assert(always_false<T>, "probe_dump: unsupported element type");
        return false;
    }
}

// `<ID> <context> <NAME> <index> <type> <value>`.
std::string dump_line(std::string_view id, std::string_view context, std::string_view name,
                      std::string_view index, std::string_view type, std::string_view value);

// `lo:hi` of one dimension.
std::string range_text(std::int64_t lower, std::int64_t upper);

// The comma-separated index of the element at `position` (row-major, last index fastest).
template <std::size_t rank>
std::string index_text(std::size_t position, std::array<std::int64_t, rank> const& lower,
                       std::array<std::int64_t, rank> const& extent) {
    std::array<std::int64_t, rank> index{};
    auto rest = static_cast<std::int64_t>(position);
    for (std::size_t d = rank; d-- > 0;) {
        index.at(d) = lower.at(d) + rest % extent.at(d);
        rest /= extent.at(d);
    }
    std::string text;
    for (std::size_t d = 0; d < rank; ++d) {
        if (d > 0) {
            text += ',';
        }
        text += std::to_string(index.at(d));
    }
    return text;
}

} // namespace detail

template <typename T, std::size_t rank>
void ProbeDump::array(std::string_view name, fb::Array<T, rank> const& a, bool sparse) {
    std::vector<std::string>& out = lines_[std::string(name)];
    std::array<std::int64_t, rank> lower{};
    std::array<std::int64_t, rank> extent{};
    std::string bounds;
    for (std::size_t d = 0; d < rank; ++d) {
        auto const dimension = static_cast<std::int64_t>(d + 1);
        lower.at(d) = a.lbound(dimension);
        std::int64_t const upper = a.ubound(dimension);
        extent.at(d) = upper - lower.at(d) + 1;
        if (d > 0) {
            bounds += ',';
        }
        bounds += detail::range_text(lower.at(d), upper);
    }
    out.push_back(detail::dump_line(id_, context_, name, "-", sparse ? "BS" : "B",
                                    std::string(detail::type_token<T>()) + " " + bounds));

    std::size_t position = 0;
    for (T const& value : a.elements()) {
        if (!sparse || !detail::is_zero(value)) {
            out.push_back(detail::dump_line(id_, context_, name,
                                            detail::index_text(position, lower, extent),
                                            detail::type_token<T>(), detail::element_text(value)));
        }
        ++position;
    }
}

template <typename Rec, typename Field>
void ProbeDump::field(std::string_view name, fb::Array<Rec, 1> const& records, Field field) {
    using T = std::remove_cvref_t<std::invoke_result_t<Field&, Rec const&>>;
    std::vector<std::string>& out = lines_[std::string(name)];
    std::int64_t const lower = records.lbound();
    out.push_back(detail::dump_line(id_, context_, name, "-", "B",
                                    std::string(detail::type_token<T>()) + " " +
                                        detail::range_text(lower, records.ubound())));

    std::int64_t index = lower;
    for (Rec const& record : records.elements()) {
        T const value = field(record);
        out.push_back(detail::dump_line(id_, context_, name, std::to_string(index),
                                        detail::type_token<T>(), detail::element_text(value)));
        ++index;
    }
}

template <typename Rec, typename Field>
void ProbeDump::array_field(std::string_view name, fb::Array<Rec, 1> const& records, Field field) {
    using Member = std::remove_cvref_t<std::invoke_result_t<Field&, Rec const&>>;
    using T = detail::array_element<Member>::ElementType;
    std::vector<std::string>& out = lines_[std::string(name)];

    // Every member array has the same bounds (the first record's); the bounds record is
    // written before the elements, so they are checked first.
    std::int64_t member_lower = 0;
    std::int64_t member_upper = -1;
    bool first = true;
    for (Rec const& record : records.elements()) {
        auto const& member = field(record);
        if (first) {
            member_lower = member.lbound();
            member_upper = member.ubound();
            first = false;
        } else if (member.lbound() != member_lower || member.ubound() != member_upper) {
            throw std::logic_error("probe_dump: " + std::string(name) +
                                   " has members of different bounds");
        }
    }

    std::int64_t const lower = records.lbound();
    out.push_back(detail::dump_line(id_, context_, name, "-", "B",
                                    std::string(detail::type_token<T>()) + " " +
                                        detail::range_text(lower, records.ubound()) + "," +
                                        detail::range_text(member_lower, member_upper)));

    std::int64_t index = lower;
    for (Rec const& record : records.elements()) {
        std::int64_t member_index = member_lower;
        for (T const& value : field(record).elements()) {
            out.push_back(detail::dump_line(
                id_, context_, name, std::to_string(index) + "," + std::to_string(member_index),
                detail::type_token<T>(), detail::element_text(value)));
            ++member_index;
        }
        ++index;
    }
}

} // namespace gef::test
