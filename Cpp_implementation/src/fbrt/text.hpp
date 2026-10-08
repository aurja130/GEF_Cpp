// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

// `Str` and `Print #` as GEF's compiled code performs them (M3.6a). Numbers are formatted by
// the C library exactly as libfb does (`%.7g`, `%.16g`, `%lld`), in the "C" locale.

#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>

namespace gef::fb {

// Str(): fb_FloatToStr ("%.7g"), fb_DoubleToStr ("%.16g"), fb_LongintToStr ("%lld"). A
// trailing '.' would be removed (never produced by %g, kept for fidelity).
[[nodiscard]] std::string str(float x);
[[nodiscard]] std::string str(double x);
[[nodiscard]] std::string str(std::int64_t x);

// What follows an item in a Print statement: the mask fbc passes to the runtime.
enum class PrintEnd : std::uint8_t {
    None = 0,    // `;` (or `;` at the end of the statement)
    Newline = 1, // end of statement
    Pad = 2,     // `,`: advance to the next 14-column print zone
};

// The text written by a sequence of `Print #f` statements to one sequential file (libfb's
// FB_FILE with width 0, not a console or pipe). It tracks libfb's line_length, the number of
// characters since the last CR or LF, which zones (`,`) and Tab() depend on.
class PrintFile {
public:
    void print(std::string_view s, PrintEnd end); // fb_PrintString
    void print(float x, PrintEnd end);            // fb_PrintSingle: blank or '-', then %.7g
    void print(double x, PrintEnd end);           // fb_PrintDouble: blank or '-', then %.16g
    void print(std::int64_t x, PrintEnd end);     // fb_PrintLongint: "% lld"
    void print_void(PrintEnd end); // fb_PrintVoid: `Print #f` with no item, or a trailing `,`
    void tab(std::int32_t column); // fb_PrintTab: `Tab(column)`

    // Print Using (io_printusg.c). fbc calls using_init once per statement, then one using_print
    // per item (the last one with last = true: the mask FB_PRINT_ISLAST), then using_end.
    void using_init(std::string_view format);                      // fb_PrintUsingInit
    void using_print(std::string_view s, PrintEnd end, bool last); // fb_PrintUsingStr
    void using_print(float x, PrintEnd end, bool last);            // fb_PrintUsingSingle
    void using_print(double x, PrintEnd end, bool last);           // fb_PrintUsingDouble
    void using_print(std::int64_t x, PrintEnd end, bool last);     // fb_PrintUsingLongint
    void using_end();                                              // fb_PrintUsingEnd

    [[nodiscard]] std::string const& text() const noexcept { return text_; }
    [[nodiscard]] std::size_t line_length() const noexcept { return line_length_; }

private:
    void write(std::string_view s);
    void pad();
    void print_item(std::string_view s, PrintEnd end);
    // The flags of a number as hPrintNumber receives them (VAL_ISNEG, VAL_ISINF, ...).
    struct UsingFlags {
        bool neg = false;
        bool inf = false;
        bool ind = false;
        bool nan = false;
        bool is_float = false;
        bool is_single = false;
    };
    void using_text(); // fb_PrintUsingFmtStr: template text up to a field
    void using_number(std::uint64_t val, int val_exp, UsingFlags flags, PrintEnd end, bool last);
    void using_real(double x, bool is_single, PrintEnd end,
                    bool last); // fb_PrintUsingDouble/Single

    std::string text_;
    std::size_t line_length_ = 0;

    std::string using_format_;
    std::size_t using_pos_ = 0;
};

} // namespace gef::fb
