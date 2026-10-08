// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

// `Print Using` (io_printusg.c) as a PrintFile. The template is consumed piece by piece: text
// up to the next field, then one field per item; a template reused for more items than fields
// starts again. Every function below is a transcription of the runtime's C code, including its
// corner cases; the (dead) VAL_ISBOOL paths are not transcribed because GEF never prints a
// Boolean with Print Using.

#include "fbrt/text.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <string>
#include <string_view>
#include <utility>

namespace gef::fb {

namespace {

constexpr int buffer_len = 2048; // BUFFERLEN
constexpr int min_expdigs = 3;   // MIN_EXPDIGS
constexpr int max_expdigs = 5;   // MAX_EXPDIGS
constexpr int max_digs = buffer_len - 2 - 1 - 1 - 1 - max_expdigs - (min_expdigs - 1); // MAX_DIGS
constexpr int sng_autodigs = 7;                           // SNG_AUTODIGS
constexpr int dbl_maxdigs = 16;                           // DBL_MAXDIGS
constexpr std::uint64_t chars_nan = 0x23'4E'41'4E;        // CHARS_NAN "#NAN"
constexpr std::uint64_t chars_inf = 0x23'49'4E'46;        // CHARS_INF "#INF"
constexpr std::uint64_t chars_ind = 0x23'49'4E'44;        // CHARS_IND "#IND"
constexpr std::uint64_t chars_trunc = 0x24'30'30'30;      // CHARS_TRUNC "$000"
constexpr std::uint64_t ind_bits = 0xFFF8'0000'0000'0000; // the bits of the indefinite value

// The C string of s: fb_PrintFixString prints up to the first NUL byte.
std::string_view c_prefix(std::string_view s) {
    std::size_t const nul = s.find('\0');
    return nul == std::string_view::npos ? s : s.substr(0, nul);
}

// hPow10_ULL (unsigned arithmetic wraps, as in C)
std::uint64_t pow10_ull(int n) {
    std::uint64_t ret = 1;
    std::uint64_t a = 10;
    while (n > 0) {
        if ((n & 1) != 0) {
            ret *= a;
        }
        a *= a;
        n >>= 1;
    }
    return ret;
}

// hLog10_ULL
int log10_ull(std::uint64_t a) {
    int ret = 0;
    std::uint64_t a64 = a;
    while (a64 >= 100000000ULL) {
        a64 /= 100000000ULL;
        ret += 8;
    }
    int a32 = static_cast<int>(a64);
    if (a32 >= 10000) {
        ret += 4;
    } else {
        a32 *= 10000;
    }
    if (a32 >= 1000000) {
        ret += 2;
    } else {
        a32 *= 100;
    }
    if (a32 >= 10000000) {
        ret += 1;
    }
    return ret;
}

// hNumDigits
int num_digits(std::uint64_t a) {
    return log10_ull(a) + 1;
}

// hDivPow10_ULL: a / 10^n, rounded half up
std::uint64_t div_pow10_ull(std::uint64_t a, int n) {
    if (n > 19) {
        return 0;
    }
    std::uint64_t const b = pow10_ull(n);
    std::uint64_t ret = a / b;
    if ((a % b) >= (b + 1) / 2) {
        ret += 1; // round up
    }
    return ret;
}

// hScaleDoubleToULL: a positive finite value as 16 significant digits (at most) and its
// base-10 exponent.
std::uint64_t scale_to_ull(double value, int& val_exp) {
    auto val_ull = std::bit_cast<std::uint64_t>(value);
    int pow2 = static_cast<int>(val_ull >> 52) - 1023;
    val_ull &= (1ULL << 52) - 1;

    if (pow2 > -1023) {
        val_ull |= (1ULL << 52); // normalized
    } else {
        pow2 += 1; // denormed
    }
    pow2 -= 52; // 52 (+1?) integer bits in val_ull

    int pow10 = 0;

    while (pow2 > 0) {
        // essentially, val_ull*=2, --pow2, dividing by 5 when necessary to keep within 64 bits
        if (val_ull < (1ULL << 63)) {
            val_ull *= 2;
            --pow2;
        } else {
            // divide by 5, rounding to nearest
            val_ull = (val_ull - 3) / 5 + 1;
            ++pow10;
            --pow2;
        }
    }

    while (pow2 < 0) {
        // essentially, val_ull/=2, ++pow2, multiplying by 5 when possible to keep precision high
        if (val_ull <= 0x3333333333333333ULL) {
            val_ull *= 5; // multiply by 5 (max 0xffffffffffffffff)
            --pow10;
            ++pow2;
        } else {
            // divide by 2, rounding to even
            val_ull = val_ull / 2 + (val_ull & (val_ull / 2) & 1);
            ++pow2;
        }
    }

    int const digs = num_digits(val_ull);
    if (digs > dbl_maxdigs) { // scale to 16 digits
        int const scale = digs - dbl_maxdigs;
        val_ull = div_pow10_ull(val_ull, scale);
        pow10 += scale;
    }

    val_exp = pow10;
    return val_ull;
}

// Writes characters backwards from the end of a buffer (ADD_CHAR); the text is what was written.
class BackBuffer {
public:
    BackBuffer() {
        add('\0'); // the terminator, at buffer[buffer_len]
    }

    void add(char c) {
        if (pos_ >= 0) {
            chars_.at(static_cast<std::size_t>(pos_)) = c;
            --pos_;
        }
    }

    [[nodiscard]] std::string_view text() const {
        std::string_view const all{chars_.data(), chars_.size() - 1};
        return all.substr(static_cast<std::size_t>(pos_) + 1U);
    }

private:
    std::array<char, buffer_len + 1> chars_{};
    int pos_ = buffer_len;
};

char digit_char(std::uint64_t d) {
    return static_cast<char>('0' + d);
}

} // namespace

// io_printusg.c fb_PrintUsingInit
void PrintFile::using_init(std::string_view format) {
    using_format_ = std::string(format);
    using_pos_ = 0;
}

// io_printusg.c fb_PrintUsingEnd
void PrintFile::using_end() {
    using_text();
    using_format_.clear();
    using_pos_ = 0;
}

// io_printusg.c fb_PrintUsingFmtStr: the template text up to the next field (or the end).
// NOLINTNEXTLINE(readability-function-cognitive-complexity): runtime structure kept
void PrintFile::using_text() {
    std::string buffer;
    auto const size = using_format_.size();
    while (using_pos_ < size && buffer.size() < static_cast<std::size_t>(buffer_len)) {
        auto const at = [&](std::size_t k) -> int {
            return using_pos_ + k < size
                       ? static_cast<unsigned char>(using_format_.at(using_pos_ + k))
                       : -1;
        };
        int c = at(0);
        int const nc = at(1);
        int const nnc = at(2);

        bool doexit = false;
        switch (c) {
        case '*':
            // "**..." number format (includes "**$...")
            if (nc == '*') {
                doexit = true;
            }
            break;
        case '$':
            // "$$..." number format
            if (nc == '$') {
                doexit = true;
            }
            break;
        case '+':
            // "+#...", "+$$...", "+**...", "+.#..."
            if (nc == '#' || (nc == '$' && nnc == '$') || (nc == '*' && nnc == '*') ||
                (nc == '.' && nnc == '#')) {
                doexit = true;
            }
            break;
        case '!':
        case '\\':
        case '&':
        case '#':
            // "!", "\ ... \", "&" string formats, "#..." number format
            doexit = true;
            break;
        case '.':
            // ".#[...]" number format
            if (nc == '#') {
                doexit = true;
            }
            break;
        case '_':
            // escape next char if there is one, otherwise just print '_'
            if (size - using_pos_ > 1) {
                c = nc;
                ++using_pos_;
            }
            break;
        default:
            break;
        }

        if (doexit) {
            break;
        }

        buffer.push_back(static_cast<char>(c));
        ++using_pos_;
    }

    if (!buffer.empty()) {
        write(c_prefix(buffer));
    }
}

// io_printusg.c fb_PrintUsingStr
// NOLINTNEXTLINE(readability-function-cognitive-complexity): runtime structure kept
void PrintFile::using_print(std::string_view s, PrintEnd end, bool last) {
    if (using_pos_ >= using_format_.size()) {
        using_pos_ = 0; // restart
    }

    // any text first
    using_text();

    int strchars = -1;
    auto const size = using_format_.size();

    while (using_pos_ < size) {
        int const c = static_cast<unsigned char>(using_format_.at(using_pos_));
        int const nc = using_pos_ + 1 < size
                           ? static_cast<unsigned char>(using_format_.at(using_pos_ + 1))
                           : -1;

        bool doexit = true;
        switch (c) {
        case '!':
            // the first character of s, or a blank
            write(c_prefix(s.empty() ? std::string_view{" "} : s.substr(0, 1)));
            ++using_pos_;
            break;

        case '&':
            write(c_prefix(s));
            ++using_pos_;
            break;

        case '\\':
            if (strchars != -1 || nc == ' ' || nc == '\\') {
                if (strchars > 0) {
                    ++strchars;
                    std::string buffer;
                    if (std::cmp_less(s.size(), strchars)) {
                        write(c_prefix(s));
                        auto const spaces = static_cast<std::size_t>(strchars) - s.size();
                        buffer.assign(spaces, ' ');
                    } else {
                        buffer.assign(s.substr(0, static_cast<std::size_t>(strchars)));
                    }

                    // replace null-terminators by spaces
                    for (char& ch : buffer) {
                        if (ch == '\0') {
                            ch = ' ';
                        }
                    }

                    write(buffer);
                    ++using_pos_;
                } else {
                    strchars = 1;
                    doexit = false;
                }
            }
            break;

        case ' ':
            if (strchars > -1) {
                ++strchars;
                doexit = false;
            }
            break;

        default:
            break;
        }

        if (doexit) {
            break;
        }

        ++using_pos_;
    }

    // any text
    using_text();

    if (last) {
        if (end == PrintEnd::Newline) {
            print_void(PrintEnd::Newline);
        }
        using_format_.clear();
        using_pos_ = 0;
    }
}

// io_printusg.c fb_PrintUsingSingle, fb_PrintUsingDouble (a Single converts exactly to a Double)
void PrintFile::using_real(double x, bool is_single, PrintEnd end, bool last) {
    auto const bits = std::bit_cast<std::uint64_t>(x);
    UsingFlags flags;
    flags.is_float = true;
    flags.is_single = is_single;
    flags.neg = static_cast<std::int64_t>(bits) < 0;

    int val_exp = 0;
    std::uint64_t val = 1;
    bool const is_zero = (bits & 0x7FFF'FFFF'FFFF'FFFFULL) == 0;
    bool const is_finite = (bits & 0x7FF0'0000'0000'0000ULL) < 0x7FF0'0000'0000'0000ULL;
    bool const is_inf = (bits & 0x7FFF'FFFF'FFFF'FFFFULL) == 0x7FF0'0000'0000'0000ULL;
    bool const is_ind = bits == ind_bits;

    if (is_zero) {
        val = 0;
        val_exp = 0;
    } else if (is_finite) {
        val = scale_to_ull(std::fabs(x), val_exp);
    } else if (is_inf) {
        flags.inf = true;
    } else if (is_ind) {
        flags.ind = true;
    } else {
        flags.nan = true;
    }

    using_number(val, val_exp, flags, end, last);
}

// io_printusg.c fb_PrintUsingSingle
void PrintFile::using_print(float x, PrintEnd end, bool last) {
    using_real(static_cast<double>(x), true, end, last);
}

// io_printusg.c fb_PrintUsingDouble
void PrintFile::using_print(double x, PrintEnd end, bool last) {
    using_real(x, false, end, last);
}

// io_printusg.c fb_PrintUsingLongint
void PrintFile::using_print(std::int64_t x, PrintEnd end, bool last) {
    UsingFlags flags;
    std::uint64_t val = 0;
    if (x < 0) {
        flags.neg = true;
        val = 0ULL - static_cast<std::uint64_t>(x);
    } else {
        val = static_cast<std::uint64_t>(x);
    }
    using_number(val, 0, flags, end, last);
}

// io_printusg.c hPrintNumber
// NOLINTNEXTLINE(readability-function-cognitive-complexity): runtime structure kept
void PrintFile::using_number(std::uint64_t val, int val_exp, UsingFlags flags, PrintEnd end,
                             bool last) {
    if (using_pos_ >= using_format_.size()) {
        using_pos_ = 0; // restart
    }

    // any text first
    using_text();

    char padchar = ' ';
    int intdigs = 0;
    int decdigs = -1;
    int expdigs = 0;
    bool adddollar = false;
    bool addcommas = false;
    bool signatend = false;
    bool signatstart = false;
    bool plussign = false;
    int toobig = 0;
    bool isamp = false;
    int lc = -1;

    auto const size = using_format_.size();
    while (using_pos_ < size) {
        // exit if just parsed end '+'/'-' sign, or '&' sign
        if (signatend || isamp) {
            break;
        }

        int const c = static_cast<unsigned char>(using_format_.at(using_pos_));
        bool doexit = false;
        switch (c) {
        case '#':
            // increment intdigs or decdigs if in int/dec part, else exit
            if (expdigs != 0) {
                doexit = true;
            } else if (decdigs != -1) {
                ++decdigs;
            } else {
                ++intdigs;
            }
            break;

        case '.':
            // add decimal point if still in integer part, else exit
            if (decdigs != -1 || expdigs != 0) {
                doexit = true;
            } else {
                decdigs = 0;
            }
            break;

        case '*':
            // if first two characters, change padding to asterisks, else exit
            if (intdigs == 0 && decdigs == -1) { // first asterisk
                padchar = '*';
                ++intdigs;
            } else if (intdigs == 1 && lc == '*') { // second asterisk
                ++intdigs;
            } else {
                doexit = true;
            }
            break;

        case '$':
            // at beginning ("$..."), or after two '*'s ("**$..."): prepend a dollar sign
            if (lc == '*') {
                adddollar = true;
            } else if (intdigs == 0 && decdigs == -1) {
                if (!adddollar) { // first dollar
                    adddollar = true;
                } else { // second dollar
                    ++intdigs;
                }
            } else {
                doexit = true;
            }
            break;

        case ',':
            // if parsing integer part, enable commas and increment intdigs
            if (decdigs != -1 || expdigs != 0) {
                doexit = true;
            } else {
                addcommas = true;
                ++intdigs;
            }
            break;

        case '+':
        case '-':
            // '+' at start/end: explicit '+'/'-' sign; '-' at end: explicit '-' sign, if negative
            // NOLINTNEXTLINE(bugprone-branch-clone): mirrors the runtime's C source
            if (signatstart) { // one already at start?
                doexit = true;
            } else if (intdigs == 0 && decdigs == -1) { // found one before integer part?
                if (c == '+') {
                    plussign = true;
                }
                signatstart = true;
            } else if (expdigs == 0 || expdigs >= min_expdigs) {
                // otherwise it's at the end, as long as there are enough expdigs for an exponent
                if (c == '+') {
                    plussign = true;
                }
                signatend = true;
            } else {
                doexit = true;
            }
            break;

        case '^':
            // exponent digits; too many: leave the rest as printable chars
            if (expdigs < max_expdigs) {
                ++expdigs;
            } else {
                doexit = true;
            }
            break;

        case '&':
            // string format '&': print number in most natural form - similar to STR
            if (intdigs == 0 && decdigs == -1 && !signatstart) {
                isamp = true;
            } else {
                doexit = true;
            }
            break;

        default:
            doexit = true;
            break;
        }

        if (doexit) {
            break;
        }

        ++using_pos_;
        lc = c;
    }

    // check flags
    bool val_isneg = flags.neg;
    bool const val_isfloat = flags.is_float;
    bool const val_issng = flags.is_single;

    std::uint64_t chars = 0;
    if (flags.inf || flags.ind || flags.nan) {
        if (flags.inf) {
            chars = chars_inf;
        } else if (flags.ind) {
            chars = chars_ind;
        } else {
            chars = chars_nan;
        }

        // Set value to 1.1234 (placeholder for "1.#XYZ")
        val = 11234;
        val_exp = -4;
    }

    int val_digs = val != 0 ? num_digits(val) : 0;
    int val_zdigs = 0;

    // Special '&' format?
    if (isamp) {
        if (val_issng) { // crop to 7-digit precision
            if (val_digs > sng_autodigs) {
                val = div_pow10_ull(val, val_digs - sng_autodigs);
                val_exp += val_digs - sng_autodigs;
                val_digs = sng_autodigs;
            }

            if (val == 0) { // val has been scaled down to zero
                val_digs = 0;
                val_exp = -decdigs;
            } else if (val == pow10_ull(val_digs)) {
                // rounding up took val to next power of 10: set value to 1, put val_digs zeroes
                // onto val_exp
                val = 1;
                val_exp += val_digs;
                val_digs = 1;
            }
        }

        if (val_isfloat) { // remove trailing zeroes in float digits
            while (val_digs > 1 && (val % 10) == 0) {
                val /= 10;
                --val_digs;
                ++val_exp;
            }
        }

        // set digits for fixed-point
        if (val_digs + val_exp > 0) {
            intdigs = val_digs + val_exp;
        } else {
            intdigs = 1;
        }

        if (val_exp < 0) {
            decdigs = -val_exp;
        }

        if (val_isfloat) { // scientific notation? e.g. 3.1E+42
            if (intdigs > 16 || (val_issng && intdigs > 7) ||
                val_digs + val_exp - 1 < -min_expdigs) {
                intdigs = 1;
                decdigs = val_digs - 1;

                expdigs =
                    2 + num_digits(static_cast<std::uint64_t>(std::abs(val_digs + val_exp - 1)));
                if (expdigs < min_expdigs + 1) {
                    expdigs = min_expdigs;
                }
            }
        }

        if (val_isneg) {
            signatstart = true;
        }
    }

    // crop number of digits
    if (intdigs + 1 + decdigs > max_digs) {
        decdigs -= (intdigs + 1 + decdigs) - max_digs;
        if (decdigs < -1) {
            intdigs -= (-1 - decdigs);
            decdigs = -1;
        }
    }

    // decimal point if decdigs >= 0
    bool decpoint = false;
    if (decdigs <= -1) {
        decpoint = false;
        decdigs = 0;
    } else {
        decpoint = true;
    }

    BackBuffer out;

    if (signatend) { // put sign at end
        if (val_isneg) {
            out.add('-');
        } else {
            out.add(plussign ? '+' : ' ');
        }
    } else if (val_isneg && !signatstart) { // implicit negative sign at start
        signatstart = true;
        --intdigs;
    }

    // fixed-point format?
    if (expdigs < min_expdigs) {
        // append any trailing carets
        for (; expdigs > 0; --expdigs) {
            out.add('^');
        }

        // backup unscaled value
        std::uint64_t const val0 = val;
        int const val_digs0 = val_digs;
        int const val_exp0 = val_exp;

        // check range
        if (val_exp < -decdigs) { // scale and round integer value to get val_exp equal to -decdigs
            val_exp += (-decdigs - val_exp0);
            val_digs -= (-decdigs - val_exp0);
            val = div_pow10_ull(val, -decdigs - val_exp0);

            if (val == 0) { // val is/has been scaled down to zero
                val_digs = 0;
                val_exp = -decdigs;
            } else if (val == pow10_ull(val_digs)) {
                // rounding up took val to next power of 10: set value to 1, put val_digs zeroes
                // onto val_exp
                val = 1;
                val_exp += val_digs;
                val_digs = 1;
            }
        }

        int intdigs2 = std::max(val_digs + val_exp, 0);
        if (addcommas) {
            intdigs2 += (intdigs2 - 1) / 3;
        }

        // compare fixed/floating point representations, and use the one that needs fewest digits
        if (intdigs2 > intdigs + min_expdigs) { // too many digits for fixed point: floating point
            expdigs = min_expdigs;              // add three digits for exp notation
            toobig = 1;                         // add '%' sign

            // restore unscaled value
            val = val0;
            val_digs = val_digs0;
            val_exp = val_exp0;

            val_zdigs = 0;
        } else {                      // keep fixed point
            if (intdigs2 > intdigs) { // slightly too many digits in number
                intdigs = intdigs2;   // extend intdigs
                toobig = 1;           // add '%' sign
            }

            if (val_exp > -decdigs) { // put excess trailing zeroes from val_exp into val_zdigs
                val_zdigs = val_exp - -decdigs;
                val_exp = -decdigs;
            }
        }
    }

    // floating-point format
    if (expdigs > 0) {
        addcommas = false; // commas unused in f-p format

        if (intdigs == -1 || (intdigs == 0 && decdigs == 0)) { // add [another] '%' sign
            ++intdigs;
            toobig = 1; // We'll just stick with one
        }

        int totdigs = intdigs + decdigs; // treat intdigs and decdigs the same
        val_exp += decdigs;              // move decimal position to end

        // blank first digit if positive and no explicit sign
        if (!isamp && !val_isneg && !(signatstart || signatend)) {
            if (intdigs >= 1 && totdigs > 1) {
                --totdigs;
            }
        }

        if (val == 0) {
            val_exp = 0;                 // ensure exponent is printed as 0
            val_zdigs = decdigs;         // enough trailing zeroes to fill dec part
        } else if (val_digs < totdigs) { // add "zeroes" to the end of val
            val_zdigs = totdigs - val_digs;
            val_exp -= val_zdigs;
        } else if (val_digs > totdigs) { // scale down value
            val = div_pow10_ull(val, val_digs - totdigs);
            val_exp += (val_digs - totdigs);
            val_digs = totdigs;
            val_zdigs = 0;

            if (val >= pow10_ull(val_digs)) { // rounding up brought val to the next power of 10
                val /= 10;
                ++val_exp;
            }
        } else {
            val_zdigs = 0;
        }

        // output exp part
        char expsignchar = '+';
        if (val_exp < 0) {
            expsignchar = '-';
            val_exp = -val_exp;
        } else {
            expsignchar = '+';
        }

        // expdigs > 3
        for (; expdigs > min_expdigs; --expdigs) {
            out.add(digit_char(static_cast<std::uint64_t>(val_exp % 10)));
            val_exp /= 10;
        }

        // expdigs == 3
        if (val_exp > 9) { // too many exp digits? Add remaining digits (QB would just crop these)
            while (val_exp > 9) {
                out.add(digit_char(static_cast<std::uint64_t>(val_exp % 10)));
                val_exp /= 10;
            }
            out.add(digit_char(static_cast<std::uint64_t>(val_exp)));
            out.add('%'); // add a '%' sign
        } else {
            out.add(digit_char(static_cast<std::uint64_t>(val_exp)));
        }

        expdigs -= 1;

        // expdigs == 2
        out.add(expsignchar);
        out.add('E'); // QB would use 'D' for doubles

        expdigs -= 2;
    }

    // INF/IND/NAN: characters truncated?
    if (chars != 0 && val_digs < 5) {
        // QB wouldn't add the '%'. But otherwise "#" will result in an innocent-looking "1".
        toobig = 1;

        if (val_digs > 1) {
            chars = chars_trunc >> (8 * (5 - val_digs));
        } else {
            chars = 0;
        }
    }

    // output dec part
    if (decpoint) {
        for (; decdigs > 0; --decdigs) {
            if (val_zdigs > 0) {
                out.add('0');
                --val_zdigs;
            } else if (val_digs > 0) {
                if (chars != 0) {
                    out.add(static_cast<char>(chars & 0xFF));
                    chars >>= 8;
                } else {
                    out.add(digit_char(val % 10));
                }
                val /= 10;
                --val_digs;
            } else {
                out.add('0');
            }
        }
        out.add('.');
    }

    // output int part
    int i = 0;
    for (;;) {
        if (addcommas && (i & 3) == 3 && val_digs > 0) { // insert comma
            out.add(',');
        } else if (val_zdigs > 0) {
            out.add('0');
            --val_zdigs;
        } else if (val_digs > 0) {
            if (chars != 0) {
                out.add(static_cast<char>(chars & 0xFF));
                chars >>= 8;
            } else {
                out.add(digit_char(val % 10));
            }
            val /= 10;
            --val_digs;
        } else {
            if (i == 0 && intdigs > 0) {
                out.add('0');
            } else {
                break;
            }
        }
        ++i;
        --intdigs;
    }

    // output dollar sign?
    if (adddollar) {
        out.add('$');
    }

    // output sign?
    if (signatstart) {
        if (val_isneg) {
            out.add('-');
        } else {
            out.add(plussign ? '+' : padchar);
        }
    }

    // output padding for any remaining intdigs
    for (; intdigs > 0; --intdigs) {
        out.add(padchar);
    }

    // output '%' sign(s)?
    for (; toobig > 0; --toobig) {
        out.add('%');
    }

    write(c_prefix(out.text()));

    // any text
    using_text();

    if (end != PrintEnd::None) {
        print_void(end);
    }

    if (last) {
        using_format_.clear();
        using_pos_ = 0;
    }
}

} // namespace gef::fb
