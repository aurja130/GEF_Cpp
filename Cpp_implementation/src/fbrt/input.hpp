// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

// Text to number as the FreeBASIC runtime does it (M3.8): Val, ValLng and `Input #`.
// The numbers come from the C library (strtod, strtof, strtoul, strtoull) exactly as in
// libfb (str_convfrom*.c, file_input_*.c), in the "C" locale.

#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>

namespace gef::fb {

// fb_hStr2Double / Val(): leading blanks skipped; "&H", "&O", "&B" and "&" (octal) radix
// prefixes; "0x" gives 0; 'd'/'D' exponents accepted; otherwise strtod.
[[nodiscard]] double val(std::string_view s);

// fb_hStr2Longint / ValLng(): leading blanks skipped; radix prefixes; strtoull, so values
// outside the signed range wrap and a leading '-' negates.
[[nodiscard]] std::int64_t vallng(std::string_view s);

// fb_hStr2Int / ValInt(): as vallng, but 32-bit (strtoul truncated to int).
[[nodiscard]] std::int32_t valint(std::string_view s);

// The tokens `Input #f, …` reads from one file opened For Input (file_input_tok.c), and the
// conversions fb_InputSingle/Double/Longint/String apply to them. The file's bytes are given
// up front; reading past the end yields empty tokens (numbers 0).
class InputFile {
public:
    explicit InputFile(std::string contents);

    [[nodiscard]] float input_single();         // fb_InputSingle
    [[nodiscard]] double input_double();        // fb_InputDouble
    [[nodiscard]] std::int64_t input_longint(); // fb_InputLongint
    [[nodiscard]] std::string input_string();   // fb_InputString

    // True when no byte is left to read (the putback buffer included).
    [[nodiscard]] bool at_end() const noexcept;

    // `Line Input #f, s` on a file opened For Input: fb_FileLineInput -> fb_DevFileReadLine
    // (dev_file_readline.c, fb_DevFileReadLineDumb). Reads from the file position; the putback
    // buffer is not consulted and is left as it is.
    [[nodiscard]] std::string line_input();

    // EOF(f) on a file opened For Input: fb_FileEofEx (file_eof.c) with the text-mode device
    // branch (dev_file_eof.c). Same condition as at_end().
    [[nodiscard]] bool eof() const noexcept;

private:
    static constexpr int eof_char = -1;

    int read_char() noexcept;
    void unread_char(int c);
    int skip_white() noexcept;
    void skip_delimiter(int c);
    std::string next_token(std::size_t max_chars, bool is_string, bool& isfp);

    std::string contents_;
    std::size_t pos_ = 0;
    std::string putback_; // fb_FilePutBackEx: read back first, last put back read first
};

} // namespace gef::fb
