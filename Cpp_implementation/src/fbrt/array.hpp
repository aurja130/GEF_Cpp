// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

// fb::Array<T, rank>: a FreeBASIC dynamic array (FBARRAY descriptor, M3.7) with `rank`
// dimensions, arbitrary bounds and row-major storage. Semantics follow libfb's array_redim.c,
// array_redimpresv.c, array_erase.c, array_lbound.c and array_ubound.c. Element access is
// bounds-checked in every build and throws std::out_of_range (user decision 2026-10-09):
// GEF is compiled without -exx, so an out-of-bounds access in BASIC reads or writes stray
// memory, and the port must reproduce such a case explicitly at its call site.

#pragma once

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace gef::fb {

// One dimension's bounds, `lbound To ubound` (`ReDim a(n)` is `Bounds{0, n}`).
struct Bounds {
    constexpr Bounds() noexcept = default;
    constexpr Bounds(std::int64_t lower, std::int64_t upper) noexcept
        : lbound(lower), ubound(upper) {}

    std::int64_t lbound = 0;
    std::int64_t ubound = -1;
};

template <typename T, std::size_t rank>
class Array {
    static_assert(rank >= 1 && rank <= 8, "FreeBASIC arrays have 1 to 8 dimensions");

public:
    // `Dim a() As T`: not allocated (LBound 0, UBound -1).
    Array() = default;

    // `ReDim a(b0, b1, ...) As T`.
    explicit Array(std::array<Bounds, rank> const& bounds) { redim(bounds); }

    // fb_ArrayRedimEx: erase, then allocate zero-initialised elements. If any lbound exceeds
    // its ubound the runtime sets an error that fbc's default build ignores, and the array is
    // left erased.
    void redim(std::array<Bounds, rank> const& bounds) {
        erase();
        if (!valid(bounds)) {
            return;
        }
        bounds_ = bounds;
        data_.assign(element_count(bounds), T{});
        allocated_ = true;
    }

    // fb_ArrayRedimPresvEx: realloc of the element storage, so the first elements keep their
    // linear (row-major) positions, whatever the new shape, and new elements are
    // zero-initialised. Invalid bounds leave the array unchanged. An unallocated array is
    // allocated as by redim.
    void redim_preserve(std::array<Bounds, rank> const& bounds) {
        if (!valid(bounds)) {
            return;
        }
        bounds_ = bounds;
        data_.resize(element_count(bounds), T{});
        allocated_ = true;
    }

    // fb_ArrayErase (dynamic array): free the storage; the array is unallocated again.
    void erase() noexcept {
        data_.clear();
        data_.shrink_to_fit();
        allocated_ = false;
    }

    // fb_ArrayLBound: dimension 0 gives 1; an unallocated array or a dimension outside
    // 1..rank gives 0.
    [[nodiscard]] std::int64_t lbound(std::int64_t dimension = 1) const noexcept {
        if (dimension == 0) {
            return 1;
        }
        if (!allocated_ || dimension < 0 || std::cmp_greater(dimension, rank)) {
            return 0;
        }
        return bounds_.at(static_cast<std::size_t>(dimension - 1)).lbound;
    }

    // fb_ArrayUBound: dimension 0 gives rank (0 when unallocated); an unallocated array or a
    // dimension outside 1..rank gives -1.
    [[nodiscard]] std::int64_t ubound(std::int64_t dimension = 1) const noexcept {
        if (dimension == 0) {
            return allocated_ ? static_cast<std::int64_t>(rank) : 0;
        }
        if (!allocated_ || dimension < 0 || std::cmp_greater(dimension, rank)) {
            return -1;
        }
        return bounds_.at(static_cast<std::size_t>(dimension - 1)).ubound;
    }

    [[nodiscard]] bool allocated() const noexcept { return allocated_; }

    // The elements in storage (row-major) order.
    [[nodiscard]] std::span<T> elements() noexcept { return data_; }
    [[nodiscard]] std::span<T const> elements() const noexcept { return data_; }

    // a(i0, i1, ...): bounds-checked; throws std::out_of_range.
    template <typename... Index>
        requires(sizeof...(Index) == rank)
    [[nodiscard]] T& operator()(Index... index) {
        return data_.at(offset({static_cast<std::int64_t>(index)...}));
    }

    template <typename... Index>
        requires(sizeof...(Index) == rank)
    [[nodiscard]] T const& operator()(Index... index) const {
        return data_.at(offset({static_cast<std::int64_t>(index)...}));
    }

private:
    static bool valid(std::array<Bounds, rank> const& bounds) noexcept {
        return std::ranges::all_of(bounds, [](Bounds const& b) { return b.lbound <= b.ubound; });
    }

    static std::size_t element_count(std::array<Bounds, rank> const& bounds) noexcept {
        std::size_t count = 1;
        for (Bounds const& b : bounds) {
            count *= static_cast<std::size_t>(b.ubound - b.lbound + 1);
        }
        return count;
    }

    [[nodiscard]] std::size_t offset(std::array<std::int64_t, rank> const& index) const {
        if (!allocated_) {
            throw std::out_of_range("access to an unallocated FreeBASIC array");
        }
        std::size_t linear = 0;
        for (std::size_t d = 0; d < rank; ++d) {
            Bounds const& b = bounds_.at(d);
            std::int64_t const i = index.at(d);
            if (i < b.lbound || i > b.ubound) {
                throw std::out_of_range("FreeBASIC array index " + std::to_string(i) + " outside " +
                                        std::to_string(b.lbound) + " To " +
                                        std::to_string(b.ubound) + " in dimension " +
                                        std::to_string(d + 1));
            }
            linear = linear * static_cast<std::size_t>(b.ubound - b.lbound + 1) +
                     static_cast<std::size_t>(i - b.lbound);
        }
        return linear;
    }

    std::vector<T> data_;
    std::array<Bounds, rank> bounds_{};
    bool allocated_ = false;
};

} // namespace gef::fb
