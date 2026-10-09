// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

#include "fbrt/input.hpp"

#include "fbrt/convert.hpp"

#include <algorithm>
#include <array>
#include <cstdlib>
#include <utility>

namespace gef::fb {

namespace {

// file_input_*.c limits (fb_file.h)
constexpr std::size_t max_int_len = 9;              // FB_INPUT_MAXINTLEN
constexpr std::size_t max_long_len = 18;            // FB_INPUT_MAXLONGLEN
constexpr std::size_t max_numeric_len = 2 + 64 + 1; // FB_INPUT_MAXNUMERICLEN
constexpr std::size_t max_string_len = 4096;        // FB_INPUT_MAXSTRINGLEN
constexpr std::size_t fgets_size = 512;             // char buffer[512] of fb_DevFileReadLineDumb

// str_hskip.c fb_hStrSkipChar(s, len, ' ')
std::string_view skip_blanks(std::string_view s) noexcept {
    std::size_t i = 0;
    while (i < s.size() && s.at(i) == ' ') {
        ++i;
    }
    return s.substr(i);
}

// The radix after '&': H, O, B, or octal without consuming the letter.
struct Radix {
    int base;
    std::size_t skip;
};

Radix amp_radix(char c) noexcept {
    switch (c) {
    case 'h':
    case 'H':
        return {.base = 16, .skip = 2};
    case 'o':
    case 'O':
        return {.base = 8, .skip = 2};
    case 'b':
    case 'B':
        return {.base = 2, .skip = 2};
    default:
        return {.base = 8, .skip = 1};
    }
}

// str_convfrom_radlng.c fb_hStrRadix2Longint (and _rad.c for Int): digits up to the first
// invalid one; overflow wraps (unsigned arithmetic, no undefined behaviour).
template <typename Unsigned>
Unsigned radix_value(std::string_view s, int base) noexcept {
    Unsigned v = 0;
    for (char const ch : s) {
        int const c = static_cast<unsigned char>(ch);
        int digit = -1;
        if (base == 16) {
            if (c >= 'a' && c <= 'f') {
                digit = c - 87;
            } else if (c >= 'A' && c <= 'F') {
                digit = c - 55;
            } else if (c >= '0' && c <= '9') {
                digit = c - 48;
            }
        } else if (base == 8) {
            if (c >= '0' && c <= '7') {
                digit = c - 48;
            }
        } else if (base == 2) {
            if (c == '0' || c == '1') {
                digit = c - 48;
            }
        }
        if (digit < 0) {
            break;
        }
        v = static_cast<Unsigned>(v * static_cast<Unsigned>(base) + static_cast<Unsigned>(digit));
    }
    return v;
}

} // namespace

// str_convfrom.c fb_hStr2Double
double val(std::string_view s) {
    std::string_view const p = skip_blanks(s);
    if (p.empty()) {
        return 0.0;
    }
    if (p.size() >= 2) {
        if (p.front() == '&') {
            Radix const r = amp_radix(p.at(1));
            return static_cast<double>(
                static_cast<std::int64_t>(radix_value<std::uint64_t>(p.substr(r.skip), r.base)));
        }
        if (p.front() == '0' && (p.at(1) == 'x' || p.at(1) == 'X')) {
            return 0.0;
        }
    }
    std::string q(p);
    for (char& c : q) {
        if (c == 'd' || c == 'D') {
            ++c;
        }
    }
    return std::strtod(q.c_str(), nullptr);
}

// str_convfrom_lng.c fb_hStr2Longint (non-MinGW branch: strtoull after the prefix)
std::int64_t vallng(std::string_view s) {
    std::string_view p = skip_blanks(s);
    if (p.empty()) {
        return 0;
    }
    int base = 10;
    if (p.size() >= 2 && p.front() == '&') {
        Radix const r = amp_radix(p.at(1));
        base = r.base;
        p = p.substr(r.skip);
    }
    std::string const q(p);
    return static_cast<std::int64_t>(std::strtoull(q.c_str(), nullptr, base));
}

// str_convfrom_int.c fb_hStr2Int
std::int32_t valint(std::string_view s) {
    std::string_view const p = skip_blanks(s);
    if (p.empty()) {
        return 0;
    }
    if (p.size() >= 2 && p.front() == '&') {
        Radix const r = amp_radix(p.at(1));
        return static_cast<std::int32_t>(radix_value<std::uint32_t>(p.substr(r.skip), r.base));
    }
    std::string const q(p);
    return static_cast<std::int32_t>(
        static_cast<std::uint32_t>(std::strtoul(q.c_str(), nullptr, 10)));
}

InputFile::InputFile(std::string contents) : contents_(std::move(contents)) {}

bool InputFile::at_end() const noexcept {
    return putback_.empty() && pos_ >= contents_.size();
}

namespace {

// fgets(buffer, 512, fp) on the in-memory file: at most 511 bytes, through the first LF, then a
// NUL. Returns false where fgets returns NULL (end of file).
bool fgets_chunk(std::string const& data, std::size_t& pos, std::array<char, fgets_size>& buffer) {
    if (pos >= data.size()) {
        return false;
    }
    std::size_t n = 0;
    while (n < fgets_size - 1 && pos < data.size()) {
        char const ch = data.at(pos++);
        buffer.at(n++) = ch;
        if (ch == '\n') {
            break;
        }
    }
    buffer.at(n) = '\0';
    return true;
}

struct ScanResult {
    bool found;
    std::size_t buffer_len;
    std::size_t tmp_buf_len;
};

// The backward scan and CR LF filter of fb_DevFileReadLineDumb. Updates buffer in place.
ScanResult scan_chunk(std::array<char, fgets_size>& buffer) {
    // while (buffer_len--) { ... } with unsigned wrap-around, as in C.
    std::size_t buffer_len = fgets_size - 1;
    bool found = false;
    while (buffer_len-- > 0) {
        char const ch = buffer.at(buffer_len);
        if (ch == '\r' || ch == '\n') {
            found = true;
            break;
        }
        if (ch != '\0') {
            break;
        }
    }
    if (!found) {
        ++buffer_len;
        return {.found = false, .buffer_len = buffer_len, .tmp_buf_len = buffer_len};
    }
    std::size_t const tmp_buf_len = buffer_len + 1;
    // filter a CR LF pair: the CR is dropped
    if (buffer.at(buffer_len) == '\n' && buffer_len != 0 && buffer.at(buffer_len - 1) == '\r') {
        --buffer_len;
    }
    buffer.at(buffer_len) = '\0';
    return {.found = true, .buffer_len = buffer_len, .tmp_buf_len = tmp_buf_len};
}

} // namespace

// dev_file_readline.c fb_DevFileReadLineDumb: fixed fgets(buf, 512) chunks from the FILE position;
// the putback buffer is not consulted for Line Input.
std::string InputFile::line_input() {
    // Literal port of fb_DevFileReadLineDumb (dev_file_readline.c). The 512-byte buffer is not
    // cleared between chunks: only the previous chunk's real length is memset, so stale bytes
    // from an earlier chunk survive into the next scan (observed on fbc 1.10.1).
    std::string result;
    std::array<char, fgets_size> buffer{};
    std::size_t mem_len = fgets_size;
    while (true) {
        std::fill_n(buffer.begin(), mem_len, '\0');
        if (!fgets_chunk(contents_, pos_, buffer)) {
            break;
        }
        ScanResult const scan = scan_chunk(buffer);
        for (std::size_t k = 0; k < scan.buffer_len; ++k) {
            result.push_back(buffer.at(k));
        }
        mem_len = scan.tmp_buf_len;
        if (scan.found) {
            break;
        }
    }
    return result;
}

bool InputFile::eof() const noexcept {
    return at_end();
}

// file_input_tok.c hReadChar (device branch): putback bytes first, then the file.
int InputFile::read_char() noexcept {
    if (!putback_.empty()) {
        int const c = static_cast<unsigned char>(putback_.front());
        putback_.erase(0, 1);
        return c;
    }
    if (pos_ >= contents_.size()) {
        return eof_char;
    }
    return static_cast<unsigned char>(contents_.at(pos_++));
}

// fb_FilePutBackEx(handle, &c, 1): the low byte of c goes in front of the putback buffer
// (so an unread EOF puts back 0xFF).
void InputFile::unread_char(int c) {
    putback_.insert(putback_.begin(), static_cast<char>(static_cast<unsigned char>(c & 0xFF)));
}

// file_input_tok.c hSkipWhiteSpc
int InputFile::skip_white() noexcept {
    int c = read_char();
    while (c == ' ' || c == '\t') {
        c = read_char();
    }
    return c;
}

// file_input_tok.c hSkipDelimiter
void InputFile::skip_delimiter(int c) {
    while (c == ' ' || c == '\t') {
        c = read_char();
    }
    switch (c) {
    case ',':
    case eof_char:
    case '\n':
        break;
    case '\r':
        c = read_char();
        if (c != '\n') {
            unread_char(c);
        }
        break;
    default:
        unread_char(c);
        break;
    }
}

// file_input_tok.c fb_FileInputNextToken
// NOLINTNEXTLINE(readability-function-cognitive-complexity): runtime structure kept
std::string InputFile::next_token(std::size_t max_chars, bool is_string, bool& isfp) {
    std::string buffer;
    isfp = false;
    bool skipdelim = true;
    bool isquote = false;
    bool hasamp = false;
    int c = skip_white();
    while (c != eof_char && buffer.size() < max_chars) {
        bool save = false;
        bool done = false;
        switch (c) {
        case '\n':
            skipdelim = false;
            done = true;
            break;
        case '\r':
            c = read_char();
            if (c != '\n') {
                unread_char(c);
            }
            skipdelim = false;
            done = true;
            break;
        case '"':
            if (!isquote) {
                if (buffer.empty()) {
                    isquote = true;
                } else {
                    save = true;
                }
            } else {
                isquote = false;
                if (is_string) {
                    c = read_char();
                    done = true;
                }
            }
            break;
        case ',':
            if (!isquote) {
                skipdelim = false;
                done = true;
            } else {
                save = true;
            }
            break;
        case '&':
            hasamp = true;
            save = true;
            break;
        case 'd':
        case 'D':
            // strtod accepts no 'd' exponent: numeric tokens get 'e' instead.
            if (!hasamp && !is_string) {
                ++c;
            }
            [[fallthrough]];
        case 'e':
        case 'E':
        case '.':
            if (!hasamp) {
                isfp = true;
            }
            save = true;
            break;
        case '\t':
        case ' ':
            if (!isquote && !is_string) {
                done = true;
            } else {
                save = true;
            }
            break;
        default:
            save = true;
            break;
        }
        if (done) {
            break;
        }
        if (save) {
            buffer.push_back(static_cast<char>(c));
        }
        c = read_char();
    }
    if (skipdelim) {
        skip_delimiter(c);
    }
    return buffer;
}

// file_input_float.c fb_InputSingle
float InputFile::input_single() {
    bool isfp = false;
    std::string const token = next_token(max_numeric_len, false, isfp);
    if (!isfp) {
        if (token.size() <= max_int_len) {
            return static_cast<float>(valint(token));
        }
        if (token.size() <= max_long_len || token.front() == '&') {
            return static_cast<float>(vallng(token));
        }
    }
    return std::strtof(token.c_str(), nullptr);
}

// file_input_float.c fb_InputDouble
double InputFile::input_double() {
    bool isfp = false;
    std::string const token = next_token(max_numeric_len, false, isfp);
    if (!isfp) {
        if (token.size() <= max_int_len) {
            return static_cast<double>(valint(token));
        }
        if (token.size() <= max_long_len || token.front() == '&') {
            return static_cast<double>(vallng(token));
        }
    }
    return std::strtod(token.c_str(), nullptr);
}

// file_input_longint.c fb_InputLongint: a floating-point token is rounded with rint and cast
// as x86-64 does (fb::d2l).
std::int64_t InputFile::input_longint() {
    bool isfp = false;
    std::string const token = next_token(max_numeric_len, false, isfp);
    if (!isfp) {
        if (token.size() <= max_int_len) {
            return valint(token);
        }
        return vallng(token);
    }
    return d2l(val(token));
}

// file_input_str.c fb_InputString
std::string InputFile::input_string() {
    bool isfp = false;
    return next_token(max_string_len, true, isfp);
}

} // namespace gef::fb
