// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

#include "fbrt/text.hpp"

#include <array>
#include <cstdio>
#include <utility>

namespace gef::fb {

namespace {

constexpr std::size_t tab_width = 14; // FB_TAB_WIDTH
constexpr std::string_view newline = "\n";

// snprintf into a string; the formats used here never exceed the buffer.
template <typename T>
std::string format(char const* fmt, T value) {
    std::array<char, 64> buffer{};
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg): the C formatting libfb uses
    int const len = std::snprintf(buffer.data(), buffer.size(), fmt, value);
    if (len <= 0) {
        return {};
    }
    return {buffer.data(), static_cast<std::size_t>(len)};
}

// str_convto_flt.c: skip the dot at the end, if any.
std::string strip_dot(std::string s) {
    if (!s.empty() && s.back() == '.') {
        s.pop_back();
    }
    return s;
}

// str_ftoa.c fb_hFloat2Str with FB_F2A_ADDBLANK: a blank in front unless the text starts
// with '-'. A result of maxlen = 1 + digits + 6 + 1 or more characters gives no text.
std::string float_print_text(double value, char const* fmt, std::size_t digits) {
    std::string s = format(fmt, value);
    if (s.empty() || s.size() >= 1 + digits + 6 + 1) {
        return {};
    }
    s = strip_dot(std::move(s));
    if (s.front() != '-') {
        s.insert(s.begin(), ' ');
    }
    return s;
}

} // namespace

std::string str(float x) {
    return strip_dot(format("%.7g", static_cast<double>(x)));
}

std::string str(double x) {
    return strip_dot(format("%.16g", x));
}

std::string str(std::int64_t x) {
    return format("%lld", static_cast<long long>(x));
}

// file_put.c fb_FilePutDataEx: line_length counts the characters after the last CR or LF.
void PrintFile::write(std::string_view s) {
    text_.append(s);
    std::size_t const last = s.find_last_of("\r\n");
    if (last == std::string_view::npos) {
        line_length_ += s.size();
    } else {
        line_length_ = s.size() - (last + 1);
    }
}

// io_printpad.c fb_PrintPadEx (file width 0): spaces up to the next zone start
// (columns 1, 15, 29, ...); never a newline, because the new column is always greater.
void PrintFile::pad() {
    std::size_t const old_x = line_length_ + 1;
    std::size_t const new_x = ((old_x + tab_width - 1) / tab_width) * tab_width + 1;
    if (new_x <= old_x) {
        write(newline);
    } else {
        write(std::string(new_x - old_x, ' '));
    }
}

// io_printvoid.c fb_PrintVoidEx
void PrintFile::print_void(PrintEnd end) {
    if (end == PrintEnd::Newline) {
        write(newline);
    } else if (end == PrintEnd::Pad) {
        pad();
    }
}

// io_print_fix.c fb_hPrintStrEx
void PrintFile::print_item(std::string_view s, PrintEnd end) {
    if (!s.empty()) {
        write(s);
    }
    print_void(end);
}

void PrintFile::print(std::string_view s, PrintEnd end) {
    print_item(s, end);
}

void PrintFile::print(float x, PrintEnd end) {
    print_item(float_print_text(static_cast<double>(x), "%.7g", 7), end);
}

void PrintFile::print(double x, PrintEnd end) {
    print_item(float_print_text(x, "%.16g", 16), end);
}

// io_print_longint.c / fb_print.h FB_PRINTNUM: "% lld", the newline in the same write, then
// the zone padding.
void PrintFile::print(std::int64_t x, PrintEnd end) {
    std::string s = format("% lld", static_cast<long long>(x));
    if (end == PrintEnd::Newline) {
        s.append(newline);
    }
    write(s);
    if (end == PrintEnd::Pad) {
        pad();
    }
}

// io_spc.c fb_PrintTab, file branch: spaces up to the column, or a newline and column - 1
// spaces when the line is already at or past it.
void PrintFile::tab(std::int32_t column) {
    if (column >= 0 && std::cmp_greater(column, line_length_)) {
        write(std::string(static_cast<std::size_t>(column) - line_length_ - 1, ' '));
        return;
    }
    write(newline);
    if (column > 0) {
        write(std::string(static_cast<std::size_t>(column) - 1, ' '));
    }
}

} // namespace gef::fb
