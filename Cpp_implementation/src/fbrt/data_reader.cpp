// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

#include "fbrt/data_reader.hpp"

#include "fbrt/input.hpp"

namespace gef::fb {

DataReader::DataReader(std::span<std::string_view const> items) noexcept : items_(items) {}

// data.c fb_DataRestore
void DataReader::restore(std::size_t index) noexcept {
    pos_ = index < items_.size() ? index : items_.size();
}

// data_readsingle.c: *dst = fb_hStr2Double(...), a Double narrowed to Single.
float DataReader::read_single() {
    return static_cast<float>(read_double());
}

// data_readdouble.c
double DataReader::read_double() {
    if (pos_ >= items_.size()) {
        return 0.0;
    }
    return val(items_.subspan(pos_++, 1).front());
}

// data_readlong.c
std::int64_t DataReader::read_longint() {
    if (pos_ >= items_.size()) {
        return 0;
    }
    return vallng(items_.subspan(pos_++, 1).front());
}

// data_readstr.c
std::string DataReader::read_string() {
    if (pos_ >= items_.size()) {
        return {};
    }
    return std::string(items_.subspan(pos_++, 1).front());
}

} // namespace gef::fb
