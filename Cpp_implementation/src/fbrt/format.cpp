// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "fbrt/format.hpp"

#include "fbrt/convert.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace gef::fb {

namespace {

// fb.h FB_MAXFIXLEN: floor( log10( pow( 2.0, 64 ) ) )
constexpr std::ptrdiff_t max_fix_len = 19;

// I18n off: runtime defaults of fb_IntlGetTimeFormat / fb_IntlGetDateFormat.
constexpr std::string_view time_format = "HH:mm:ss";
constexpr std::string_view date_format = "MM/dd/yyyy";

// intl_getmonthname.c / intl_getweekdayname.c English tables.
constexpr std::array<std::string_view, 12> month_long{
    "January", "February", "March",     "April",   "May",      "June",
    "July",    "August",   "September", "October", "November", "December"};
constexpr std::array<std::string_view, 12> month_short{"Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                                       "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
constexpr std::array<std::string_view, 7> weekday_long{"Sunday",   "Monday", "Tuesday", "Wednesday",
                                                       "Thursday", "Friday", "Saturday"};
constexpr std::array<std::string_view, 7> weekday_short{"Sun", "Mon", "Tue", "Wed",
                                                        "Thu", "Fri", "Sat"};

// Locale fixed by the runtime defaults (intl_get*.c with I18n off).
struct Locale {
    char decimal_point;
    char thousands_sep;
    char date_sep;
    char time_sep;
};
constexpr Locale locale{
    .decimal_point = '.', .thousands_sep = ',', .date_sep = '/', .time_sep = ':'};

enum class MaskType : std::uint8_t { Unknown, Number, DateTime };

// str_format.c FormatMaskInfo. Length bookkeeping (length_min / length_opt) only sizes the
// runtime allocation and never changes the produced bytes, so it is not transcribed.
struct MaskInfo {
    MaskType mask_type = MaskType::Unknown;
    bool has_decimal_point = false;
    bool has_thousand_sep = false;
    bool has_percent = false;
    bool has_exponent = false;
    bool exponent_add_plus = false;
    bool has_sign = false;
    bool sign_add_plus = false;
    std::ptrdiff_t num_digits_fix = 0;
    std::ptrdiff_t num_digits_frac = 0;
    std::ptrdiff_t num_digits_omit = 0;
    std::ptrdiff_t exp_digits = 0;
    bool has_ampm = false;
};

// C string semantics for mask[i]: the runtime mask is NUL-terminated.
char char_at(std::string_view s, std::ptrdiff_t pos) {
    if (pos < 0 || std::cmp_greater_equal(pos, s.size())) {
        return '\0';
    }
    return s.at(static_cast<std::size_t>(pos));
}

// Clamped suffix view: an index at or past the end yields an empty view.
std::string_view view_from(std::string_view s, std::ptrdiff_t pos) {
    const auto start = static_cast<std::size_t>(std::max<std::ptrdiff_t>(pos, 0));
    return start >= s.size() ? std::string_view{} : s.substr(start);
}

char ascii_lower(char c) {
    return (c >= 'A' && c <= 'Z') ? static_cast<char>(c - 'A' + 'a') : c;
}

// strncasecmp(mask + pos, pattern, strlen(pattern)) == 0
bool ci_prefix(std::string_view mask, std::ptrdiff_t pos, std::string_view pattern) {
    for (std::size_t k = 0; k < pattern.size(); ++k) {
        const char c = char_at(mask, pos + static_cast<std::ptrdiff_t>(k));
        if (ascii_lower(c) != ascii_lower(pattern.at(k))) {
            return false;
        }
    }
    return true;
}

// time_core.c fb_hTimeLeap / fb_hTimeDaysInMonth; fb_hTimeDaysInYear is the macro 365 + leap.
int time_leap(int year) {
    if (year % 400 == 0) {
        return 1;
    }
    if (year % 100 == 0) {
        return 0;
    }
    return ((year & 3) == 0) ? 1 : 0;
}

int days_in_month(int month, int year) {
    constexpr std::array<int, 12> days{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (month == 2) {
        return days.at(1) + time_leap(year);
    }
    return days.at(static_cast<std::size_t>(month - 1));
}

int days_in_year(int year) {
    return 365 + time_leap(year);
}

struct Date {
    int year;
    int month;
    int day;
};

// time_decodeserdate.c fb_hDateDecodeSerial (year 1900 origin, serial - 2).
Date decode_date(double serial) {
    int cur_year = 1900;
    int cur_month = 1;
    serial = std::floor(serial);
    serial -= 2;
    while (serial < 0) {
        serial += days_in_year(--cur_year);
    }
    for (int days = days_in_year(cur_year); serial >= days; days = days_in_year(cur_year)) {
        serial -= days;
        ++cur_year;
    }
    for (int days = days_in_month(cur_month, cur_year); serial >= days;
         days = days_in_month(cur_month, cur_year)) {
        serial -= days;
        ++cur_month;
    }
    const int cur_day = static_cast<int>(1.0 + serial);
    return Date{.year = cur_year, .month = cur_month, .day = cur_day};
}

// time_decodeserdate.c fb_Weekday(serial, FB_WEEK_DAY_SUNDAY): 1 = Sunday ... 7 = Saturday.
int weekday_of(double serial) {
    int dow = (static_cast<int>(std::floor(serial) - 1.0) % 7) + 1;
    if (dow < 1) {
        dow += 7;
    } else if (dow > 7) {
        dow -= 7;
    }
    return dow;
}

struct Hms {
    int hour;
    int minute;
    int second;
};

// time_decodesertime.c fb_hTimeDecodeSerial with use_qb_hack = TRUE (every caller uses it).
// The "l" literals make the intermediate steps long double; each result is stored as double.
Hms decode_time(double serial) {
    const double fix_value = fix(serial);
    serial -= fix_value;
    if (serial < 0.0) {
        // QB quirk: fix_value == 0.0 covers both +0.0 and -0.0.
        if (fix_value == 0.0) {
            serial = -serial;
        } else {
            serial = static_cast<double>(static_cast<long double>(serial) + 1.0L);
        }
    }
    serial = static_cast<double>(static_cast<long double>(serial) + 0.000000001L);
    serial = static_cast<double>(static_cast<long double>(serial) * 24.0L);
    const auto hour = static_cast<int>(serial);
    serial -= hour;
    serial = static_cast<double>(static_cast<long double>(serial) * 60.0L);
    const auto minute = static_cast<int>(serial);
    serial -= minute;
    serial = static_cast<double>(static_cast<long double>(serial) * 60.0L);
    const auto second = static_cast<int>(serial);
    return Hms{.hour = hour, .minute = minute, .second = second};
}

// intl_getmonthname.c / time_monthname.c fb_MonthName (month is always 1..12 here).
std::string_view month_name(int month, bool short_names) {
    const auto index = static_cast<std::size_t>(month - 1);
    return short_names ? month_short.at(index) : month_long.at(index);
}

// time_weekdayname.c fb_WeekdayName with first day = Sunday (weekday is always 1..7 here).
std::string_view weekday_name(int weekday, bool short_names) {
    const auto index = static_cast<std::size_t>(weekday - 1);
    return short_names ? weekday_short.at(index) : weekday_long.at(index);
}

// math_log10.c fb_IntLog10_32
constexpr std::uint64_t pow10u(int k) {
    std::uint64_t result = 1;
    for (int i = 0; i < k; ++i) {
        result *= 10;
    }
    return result;
}

int int_log10_32(std::uint32_t x) {
    for (int k = 9; k >= 0; --k) {
        if (x >= pow10u(k)) {
            return k;
        }
    }
    return -1;
}

// math_log10.c fb_IntLog10_64
int int_log10_64(std::uint64_t x) {
    if ((x & 0xffffffff00000000ULL) != 0) {
        for (int k = 19; k >= 10; --k) {
            if (x >= pow10u(k)) {
                return k;
            }
        }
        return 9;
    }
    return int_log10_32(static_cast<std::uint32_t>(x));
}

struct Parts {
    std::string fix;
    std::string frac;
    char sign = '\0';
};

// str_format.c fb_hGetNumberParts. Both callers pass '.' as the decimal point.
Parts number_parts(double number, int precision) {
    double dbl_fix = 0.0;
    double dbl_frac = std::modf(number, &dbl_fix);
    const bool neg = number < 0.0;
    const auto ull_fix = static_cast<std::uint64_t>(neg ? -dbl_fix : dbl_fix);
    if (dbl_frac < 0.0) {
        dbl_frac = -dbl_frac;
    }

    std::array<char, 128> buf{};
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg): "%.*f" is the runtime's own formatter
    const int len = std::snprintf(buf.data(), buf.size(), "%.*f", precision, dbl_frac);
    const std::string_view text{buf.data(), static_cast<std::size_t>(len)};

    // Strip the leading "0" (or "-0") and trailing zeros; drop the point if nothing remains.
    std::size_t start = 0;
    if (text.front() == '-') {
        ++start;
    }
    ++start;
    std::size_t end = text.size();
    while (end != start) {
        --end;
        if (text.at(end) != '0') {
            if (text.at(end) != '.') {
                ++start;
                ++end;
            }
            break;
        }
    }

    Parts parts;
    parts.frac = std::string(text.substr(start, end - start));
    if (ull_fix == 0 && neg) {
        parts.sign = '-';
    } else if (ull_fix == 0 && number > 0.0) {
        parts.sign = '+';
    } else {
        if (neg) {
            parts.sign = '-';
        } else if (ull_fix > 0) {
            parts.sign = '+';
        }
        parts.fix = std::to_string(ull_fix);
    }
    return parts;
}

// str_format.c fb_hBuildDouble (empty mask: 11 digits of precision).
std::string build_double(double num) {
    const Parts parts = number_parts(num, 11);
    std::string out;
    if (parts.sign == '-') {
        out.push_back('-');
    }
    out += parts.fix;
    if (!parts.frac.empty()) {
        out.push_back(locale.decimal_point);
        out += parts.frac;
    }
    return out;
}

// str_format.c hRound
double h_round(double value, const MaskInfo& info) {
    double whole = 0.0;
    double frac = std::modf(value, &whole);

    if (info.num_digits_frac == 0) {
        // Round here because modf() in number_parts does not.
        const auto intfrac = static_cast<long long>(frac * 1.E+15);
        if (intfrac > static_cast<long long>(5.E+14)) {
            value = std::ceil(value);
        } else if (intfrac < -static_cast<long long>(5.E+14)) {
            value = std::floor(value);
        }
    } else if (frac != 0.0) {
        // Drop the fraction of the fraction (VBDOS: 2.55 -> 2.5, not 2.6).
        const double p10 = std::pow(10.0, static_cast<double>(info.num_digits_frac));
        const double fracfrac = std::modf(frac * p10, &frac);
        const auto intfrac = static_cast<long long>(fracfrac * (1.E+15 / p10));
        if (intfrac > static_cast<long long>(5.E+14 / p10)) {
            frac += 1.0;
        } else if (intfrac < -static_cast<long long>(5.E+14 / p10)) {
            frac += -1.0;
        }
        frac /= p10;
        value = whole + frac;
    }
    return value;
}

// Numeric date/time field value: the switch at the end of fb_hProcessMask's do_output block.
int numeric_field(char ch, bool two_digit_year, bool has_ampm, double value) {
    if (two_digit_year) {
        return decode_date(value).year % 100;
    }
    if (ch == 'd') {
        return decode_date(value).day;
    }
    if (ch == 'M') {
        return decode_date(value).month;
    }
    if (ch == 'm' || ch == 'n') {
        return decode_time(value).minute;
    }
    if (ch == 's') {
        return decode_time(value).second;
    }
    int hour = decode_time(value).hour;
    if (has_ampm && ch == 'h') {
        if (hour > 12) {
            hour -= 12;
        } else if (hour == 0) {
            hour += 12;
        }
    }
    return hour;
}

std::string numeric_text(char ch, std::ptrdiff_t count, bool two_digit_year, bool has_ampm,
                         double value) {
    const int number = numeric_field(ch, two_digit_year, has_ampm, value);
    if (count == 1 && !two_digit_year) {
        return std::to_string(number);
    }
    return std::format("{:02}", number);
}

// Defined below; the date tokens call back into the full formatter (fb_hStrFormat).
std::optional<std::string> format_value(double value, std::string_view mask);

// Result of one step of the mask loop: Restart is the runtime's `--i; continue`.
enum class Flow : std::uint8_t { Proceed, Restart, Fail };

// Output of one pass over the mask. Pass 1 (no output) collects MaskInfo; pass 2 writes.
class MaskRun {
public:
    MaskRun(std::string_view mask, double value, MaskInfo& stats, std::string* out) noexcept
        : mask_{mask}, value_{value}, info_{&stats}, out_{out}, do_output_{out != nullptr} {}

    // str_format.c fb_hProcessMask. Returns false on the runtime's illegal-call errors.
    [[nodiscard]] bool run();

private:
    [[nodiscard]] MaskInfo& info() const noexcept { return *info_; }

    // Main-loop body; returns false on error.
    bool step();
    Flow dispatch();
    Flow mask_char();
    void finish_comma();
    void emit();
    bool exponent_char();
    bool top_digit();
    bool interpret();
    void classify();
    void plain();
    bool number_char();
    bool percent_char();
    void point_char();
    void comma_char();
    void digit_entry();
    bool exp_char();
    void digit_char();
    void frac_digit();
    void exp_digit();
    void thousands_before_fix();
    void fix_digit();
    void sign_char();
    void divider_char();
    void ampm_char();
    void date_token();
    bool date_text_token(std::ptrdiff_t count);
    bool date_num_token(std::ptrdiff_t count);
    void prepare_number();
    void set_exponent_text();
    void set_text(std::string text);
    void set_owned(std::string text);
    [[nodiscard]] std::string_view sign_view() const noexcept;

    std::string_view mask_;
    double value_;
    MaskInfo* info_;
    std::string* out_;
    bool do_output_;

    std::ptrdiff_t i_ = 0;
    char ch_ = '\0';
    char sign_ = '\0';

    std::string fix_;
    std::string frac_;
    std::string exp_;
    std::ptrdiff_t len_fix_ = 0;
    std::ptrdiff_t len_frac_ = 0;
    std::ptrdiff_t len_exp_ = 0;
    std::ptrdiff_t index_fix_ = 0;
    std::ptrdiff_t index_frac_ = 0;
    std::ptrdiff_t index_exp_ = 0;
    std::ptrdiff_t exp_adjust_ = 0;
    std::ptrdiff_t num_skip_fix_ = 0;
    std::ptrdiff_t num_skip_exp_ = 0;
    std::ptrdiff_t exp_value_ = 0;
    bool non_zero_ = false;

    bool do_skip_ = false;
    bool do_exp_ = false;
    bool do_string_ = false;
    bool did_sign_ = false;
    bool did_exp_ = false;
    bool did_hour_ = false;
    bool did_thousandsep_ = false;
    bool do_num_frac_ = false;
    bool last_was_comma_ = false;
    bool was_k_div_ = false;
    bool do_add_ = false;

    std::string_view add_src_;
    std::ptrdiff_t add_len_ = 1;
    std::string owned_;
};

bool MaskRun::run() {
    if (!do_output_) {
        info() = MaskInfo{};
    } else if (info().mask_type == MaskType::Number) {
        if (info().has_percent) {
            value_ *= 100.0;
        }
        value_ /= std::pow(10.0, static_cast<double>(info().num_digits_omit));
    }

    if (value_ != 0.0) {
        const int magnitude = static_cast<int>(std::floor(std::log10(std::fabs(value_))));
        exp_value_ = static_cast<std::ptrdiff_t>(magnitude) + 1;
        non_zero_ = true;
    } else {
        exp_value_ = 0;
        non_zero_ = false;
    }

    if (do_output_ && info().mask_type == MaskType::Number) {
        prepare_number();
    }

    const auto n = static_cast<std::ptrdiff_t>(mask_.size());
    for (i_ = 0; i_ != n; ++i_) {
        if (!step()) {
            return false;
        }
    }

    if (!do_output_ && !info().has_decimal_point && info().num_digits_omit != 0) {
        info().num_digits_omit += 3;
    }
    return true;
}

// str_format.c fb_hProcessMask, number branch of the do_output block (lines 277-393).
void MaskRun::prepare_number() {
    if (info().has_exponent) {
        // If non-zero, scale the mantissa to fill the fix digits.
        if (non_zero_) {
            exp_value_ -= info().num_digits_fix;
        }
        if (exp_value_ != 0) {
            if (-exp_value_ <= 308) {
                value_ *= std::pow(10.0, static_cast<double>(-exp_value_));
            } else {
                value_ *= std::pow(5.0, static_cast<double>(-exp_value_));
                value_ *= std::pow(2.0, static_cast<double>(-exp_value_));
            }
        }
        while (value_ >= 18446744073709551616.0) {
            value_ /= 10.0;
            exp_value_ += 1;
        }
        set_exponent_text();
    } else if (exp_value_ < 0) {
        // Too small: value between (+|-)0.0..1.0 with too many leading zeros.
        if (-exp_value_ >= info().num_digits_frac) {
            value_ = 0.0;
            exp_value_ = 0;
        }
    } else {
        // Too big to fit a 64-bit integer: move the excess into the value's scale.
        if (exp_value_ > max_fix_len) {
            exp_value_ -= max_fix_len;
            value_ *= std::pow(10.0, static_cast<double>(-exp_value_));
        } else {
            exp_value_ = 0;
        }
    }

    value_ = h_round(value_, info());

    // Value rounded up to the next power of 10?
    if (info().has_exponent &&
        int_log10_64(static_cast<std::uint64_t>(std::fabs(value_))) == info().num_digits_fix) {
        value_ /= 10.0;
        exp_value_ += 1;
        set_exponent_text();
    }

    Parts parts = number_parts(value_, static_cast<int>(info().num_digits_frac));
    fix_ = std::move(parts.fix);
    frac_ = std::move(parts.frac);
    sign_ = parts.sign;
    len_fix_ = static_cast<std::ptrdiff_t>(fix_.size());
    len_frac_ = static_cast<std::ptrdiff_t>(frac_.size());

    // Too big numbers: append the exponent as zero digits.
    if (exp_value_ > 0 && !info().has_exponent) {
        fix_.append(static_cast<std::size_t>(exp_value_), '0');
        len_fix_ = static_cast<std::ptrdiff_t>(fix_.size());
    }

    num_skip_fix_ = info().num_digits_fix - len_fix_;
}

// str_format.c fb_hProcessMask: LenExp / IndexExp / ExpAdjust / NumSkipExp setup.
void MaskRun::set_exponent_text() {
    exp_ = std::to_string(exp_value_);
    len_exp_ = static_cast<std::ptrdiff_t>(exp_.size());
    exp_adjust_ = exp_value_ < 0 ? 1 : 0;
    index_exp_ = exp_adjust_;
    num_skip_exp_ = info().exp_digits - (len_exp_ - exp_adjust_);
}

void MaskRun::set_text(std::string text) {
    fix_ = std::move(text);
    add_src_ = fix_;
    add_len_ = static_cast<std::ptrdiff_t>(fix_.size());
    do_add_ = true;
}

// Owned text is emitted with strlen semantics (LenAdd == 0 in the runtime).
void MaskRun::set_owned(std::string text) {
    owned_ = std::move(text);
    add_src_ = owned_;
    add_len_ = static_cast<std::ptrdiff_t>(owned_.size());
    do_add_ = true;
}

std::string_view MaskRun::sign_view() const noexcept {
    return std::string_view{&sign_, 1};
}

// One iteration of the fb_hProcessMask loop. A `continue` in the runtime returns true early
// after its `--i`, so the trailing comma check and emission are skipped as in C.
bool MaskRun::step() {
    ch_ = char_at(mask_, i_);
    add_src_ = view_from(mask_, i_).substr(0, 1);
    add_len_ = 1;

    switch (dispatch()) {
    case Flow::Fail:
        return false;
    case Flow::Restart:
        return true;
    case Flow::Proceed:
        break;
    }

    finish_comma();
    emit();
    return true;
}

// The do_skip / do_exp / do_string branches, or the main mask character switch.
Flow MaskRun::dispatch() {
    if (do_skip_) {
        do_skip_ = false;
        if (do_output_) {
            do_add_ = true;
        }
        return Flow::Proceed;
    }
    if (do_exp_) {
        return exponent_char() ? Flow::Proceed : Flow::Fail;
    }
    if (do_string_) {
        if (ch_ == '"') {
            do_string_ = false;
        } else if (do_output_) {
            do_add_ = true;
        }
        return Flow::Proceed;
    }
    return mask_char();
}

// The output-time digit check, then the interpretation switch for a mask character.
Flow MaskRun::mask_char() {
    if (do_output_) {
        if ((ch_ == '.' || ch_ == '#' || ch_ == '0') && top_digit()) {
            return Flow::Restart;
        }
        if (do_add_) {
            --i_;
        }
    }
    if (!do_add_ && !interpret()) {
        return Flow::Fail;
    }
    return Flow::Proceed;
}

// A thousands-separator run ends at a character other than ',' or the last mask character.
void MaskRun::finish_comma() {
    if (last_was_comma_ && (ch_ != ',' || i_ == static_cast<std::ptrdiff_t>(mask_.size()) - 1)) {
        if (!do_output_ && !was_k_div_) {
            info().has_thousand_sep = true;
        }
        last_was_comma_ = false;
        was_k_div_ = false;
    }
}

// Append the pending add_src_ text: LenAdd == 0 means strlen semantics.
void MaskRun::emit() {
    if (!do_add_) {
        return;
    }
    do_add_ = false;
    std::size_t n = (add_len_ == 0) ? add_src_.find('\0') : static_cast<std::size_t>(add_len_);
    if (n == std::string_view::npos) {
        n = add_src_.size();
    }
    out_->append(add_src_.substr(0, n));
}

// Exponent sign directly after 'E'/'e' (the do_exp branch).
bool MaskRun::exponent_char() {
    if (!do_output_) {
        info().has_exponent = true;
        switch (ch_) {
        case '-':
            info().exponent_add_plus = false;
            break;
        case '+':
            info().exponent_add_plus = true;
            break;
        default:
            return false;
        }
    } else if (info().exponent_add_plus || exp_value_ < 0) {
        add_src_ = (exp_value_ < 0) ? std::string_view{"-"} : std::string_view{"+"};
        do_add_ = true;
    }
    do_exp_ = false;
    did_exp_ = true;
    do_num_frac_ = false;
    return true;
}

// Top-level output switch for '.', '#', '0' (before the interpretation switch).
// Returns true when the runtime's `--i; continue` is taken.
bool MaskRun::top_digit() {
    if (!info().has_sign && !did_sign_) {
        did_sign_ = true;
        if (info().sign_add_plus || sign_ == '-') {
            add_src_ = sign_view();
            do_add_ = true;
        } else {
            --i_;
            return true;
        }
    } else if (num_skip_fix_ < 0) {
        add_src_ = view_from(fix_, index_fix_);
        if (info().has_thousand_sep) {
            const std::ptrdiff_t remaining = len_fix_ - index_fix_;
            if (index_fix_ != len_fix_ && remaining % 3 == 0) {
                if (did_thousandsep_) {
                    did_thousandsep_ = false;
                    add_len_ = 3;
                } else if (index_fix_ >= 1) {
                    did_thousandsep_ = true;
                    add_src_ = std::string_view{&locale.thousands_sep, 1};
                    add_len_ = 1;
                }
            } else {
                add_len_ = remaining % 3;
            }
        } else {
            add_len_ = -num_skip_fix_;
        }
        do_add_ = true;
        if (!did_thousandsep_) {
            index_fix_ += add_len_;
            num_skip_fix_ += add_len_;
        }
    }
    return false;
}

// Second switch of fb_hProcessMask: classify the character, then interpret it.
bool MaskRun::interpret() {
    classify();
    switch (ch_) {
    case '%':
    case '.':
    case ',':
    case '#':
    case '0':
    case 'E':
    case 'e':
        return number_char();
    case '+':
    case '-':
        sign_char();
        return true;
    case 'd':
    case 'n':
    case 'm':
    case 'M':
    case 'y':
    case 'h':
    case 'H':
    case 's':
    case 't':
        date_token();
        return true;
    case '/':
    case ':':
        divider_char();
        return true;
    case 'a':
    case 'A':
        ampm_char();
        return true;
    case '\\':
        do_skip_ = true;
        return true;
    case '"':
        do_string_ = true;
        return true;
    default:
        plain();
        return true;
    }
}

// First switch of fb_hProcessMask: the first mask character decides Number or DateTime.
void MaskRun::classify() {
    switch (ch_) {
    case '%':
    case ',':
    case '#':
    case '0':
    case '+':
    case 'E':
    case 'e':
    case '-':
    case '.':
        if (info().mask_type == MaskType::Unknown) {
            info().mask_type = MaskType::Number;
        }
        break;
    case 'd':
    case 'n':
    case 'm':
    case 'M':
    case 'y':
    case 'h':
    case 'H':
    case 's':
    case 't':
    case ':':
    case '/':
        if (info().mask_type == MaskType::Unknown) {
            info().mask_type = MaskType::DateTime;
        }
        break;
    default:
        break;
    }
}

// Literal character: emitted from the mask in pass 2, counted in pass 1.
void MaskRun::plain() {
    if (do_output_) {
        do_add_ = true;
    }
}

// '%', '.', ',', '#', '0', 'E', 'e'.
bool MaskRun::number_char() {
    switch (ch_) {
    case '%':
        return percent_char();
    case '.':
        point_char();
        return true;
    case ',':
        comma_char();
        return true;
    case '#':
    case '0':
        digit_entry();
        return true;
    case 'E':
    case 'e':
        return exp_char();
    default:
        return true;
    }
}

bool MaskRun::percent_char() {
    if (do_output_) {
        do_add_ = true;
        return true;
    }
    if (info().mask_type != MaskType::Number) {
        return true;
    }
    if (info().has_percent) {
        return false;
    }
    info().has_percent = true;
    return true;
}

void MaskRun::point_char() {
    if (!do_output_) {
        if (info().mask_type == MaskType::Number && !info().has_decimal_point) {
            info().has_decimal_point = true;
            if (last_was_comma_) {
                info().num_digits_omit += 3;
                was_k_div_ = true;
            } else if (info().num_digits_omit != 0) {
                info().num_digits_omit += 3;
            }
        }
    } else {
        do_add_ = true;
        if (info().mask_type == MaskType::Number) {
            add_src_ = std::string_view{&locale.decimal_point, 1};
        }
    }
    do_num_frac_ = true;
}

void MaskRun::comma_char() {
    if (info().mask_type != MaskType::Number) {
        if (do_output_) {
            do_add_ = true;
        }
        return;
    }
    if (!do_output_) {
        if (last_was_comma_) {
            info().num_digits_omit += 3;
            was_k_div_ = true;
        }
    } else if (last_was_comma_) {
        was_k_div_ = true;
    }
    last_was_comma_ = true;
}

void MaskRun::digit_entry() {
    if (info().mask_type != MaskType::Number) {
        if (do_output_) {
            do_add_ = true;
        }
        return;
    }
    if (!do_output_) {
        if (do_num_frac_) {
            ++info().num_digits_frac;
        } else if (did_exp_) {
            ++info().exp_digits;
        } else {
            ++info().num_digits_fix;
        }
        return;
    }
    digit_char();
}

bool MaskRun::exp_char() {
    if (info().mask_type != MaskType::Number) {
        if (do_output_) {
            do_add_ = true;
        }
        return true;
    }
    if (did_exp_) {
        return false;
    }
    do_exp_ = true;
    if (do_output_) {
        do_add_ = true;
    }
    return true;
}

// Output of a '#' or '0' in a number mask: fraction, exponent or integer digits.
void MaskRun::digit_char() {
    if (do_num_frac_) {
        frac_digit();
        return;
    }
    if (did_exp_) {
        exp_digit();
        return;
    }
    thousands_before_fix();
    if (!do_add_) {
        fix_digit();
    }
}

void MaskRun::frac_digit() {
    if (index_frac_ != len_frac_) {
        add_src_ = view_from(frac_, index_frac_);
        ++index_frac_;
        do_add_ = true;
    } else if (ch_ == '0') {
        do_add_ = true;
    }
}

void MaskRun::exp_digit() {
    if (num_skip_exp_ > 0) {
        if (ch_ == '0') {
            do_add_ = true;
        }
        --num_skip_exp_;
    } else if (index_exp_ != len_exp_) {
        add_src_ = view_from(exp_, index_exp_);
        ++index_exp_;
        if (index_exp_ - exp_adjust_ >= info().exp_digits && index_exp_ != len_exp_) {
            --i_;
        }
        do_add_ = true;
    }
}

void MaskRun::thousands_before_fix() {
    if (!info().has_thousand_sep) {
        return;
    }
    const std::ptrdiff_t remaining = len_fix_ - index_fix_ + num_skip_fix_;
    if (remaining % 3 != 0) {
        return;
    }
    if (did_thousandsep_) {
        did_thousandsep_ = false;
    } else if (num_skip_fix_ == 0 && index_fix_ != 0) {
        did_thousandsep_ = true;
        add_src_ = std::string_view{&locale.thousands_sep, 1};
        add_len_ = 1;
        do_add_ = true;
        --i_;
    }
}

void MaskRun::fix_digit() {
    if (num_skip_fix_ != 0) {
        if (ch_ == '0') {
            do_add_ = true;
        }
        --num_skip_fix_;
    } else if (index_fix_ != len_fix_) {
        add_src_ = view_from(fix_, index_fix_);
        ++index_fix_;
        do_add_ = true;
    } else if (ch_ == '0') {
        do_add_ = true;
    }
}

// '+' and '-'.
void MaskRun::sign_char() {
    if (!do_output_) {
        if (!info().has_sign) {
            info().has_sign = true;
            info().sign_add_plus = ch_ == '+';
        }
    } else if (info().mask_type == MaskType::DateTime || did_sign_) {
        do_add_ = true;
    } else {
        did_sign_ = true;
        if (info().sign_add_plus || sign_ == '-') {
            add_src_ = sign_view();
            do_add_ = true;
        }
    }
}

// '/' and ':' (date and time separators in a DateTime mask).
void MaskRun::divider_char() {
    if (!do_output_) {
        return;
    }
    if (info().mask_type == MaskType::DateTime) {
        add_src_ = (ch_ == '/') ? std::string_view{&locale.date_sep, 1}
                                : std::string_view{&locale.time_sep, 1};
    }
    do_add_ = true;
}

// 'a' / 'A': AM/PM or A/P in a DateTime mask.
void MaskRun::ampm_char() {
    if (info().mask_type != MaskType::DateTime ||
        (!ci_prefix(mask_, i_, "AM/PM") && !ci_prefix(mask_, i_, "A/P"))) {
        plain();
        return;
    }
    if (!do_output_) {
        info().has_ampm = true;
    } else {
        const bool small = char_at(mask_, i_ + 1) == '/';
        const std::ptrdiff_t len = small ? 1 : 2;
        add_len_ = len;
        if (decode_time(value_).hour >= 12) {
            add_src_ = view_from(mask_, i_ + len + 1);
        } else {
            add_src_ = view_from(mask_, i_);
        }
        do_add_ = true;
    }
    i_ += (char_at(mask_, i_ + 1) == '/') ? 2 : 4;
}

// 'd', 'm', 'n', 'M', 'y', 'h', 'H', 's', 't' in a DateTime mask: a run of identical characters.
void MaskRun::date_token() {
    if (info().mask_type != MaskType::DateTime) {
        plain();
        return;
    }
    const bool old_did_hour = did_hour_;
    std::ptrdiff_t count = 1;
    while (char_at(mask_, i_ + count) == ch_) {
        ++count;
    }
    did_hour_ = false;
    if (ch_ == 'm' && (count > 2 || !old_did_hour)) {
        ch_ = 'M';
    }
    if (!date_text_token(count) && !date_num_token(count)) {
        plain();
    }
}

// Composite tokens (ttttt, ddddd, ddd/dddd, MMM/MMMM) that produce text.
bool MaskRun::date_text_token(std::ptrdiff_t count) {
    const bool is_time5 = ch_ == 't' && count == 5;
    const bool is_date5 = ch_ == 'd' && count == 5;
    const bool is_weekday = ch_ == 'd' && (count == 3 || count == 4);
    const bool is_month_name = ch_ == 'M' && (count == 3 || count == 4);
    if (!is_time5 && !is_date5 && !is_weekday && !is_month_name) {
        return false;
    }
    i_ += count - 1;
    if (!do_output_) {
        return true;
    }
    if (is_time5) {
        fix_ = std::string(time_format);
        set_owned(format_value(value_, time_format).value_or(std::string{}));
    } else if (is_date5) {
        fix_ = std::string(date_format);
        set_owned(format_value(value_, date_format).value_or(std::string{}));
    } else if (is_weekday) {
        set_owned(std::string(weekday_name(weekday_of(value_), count == 3)));
    } else {
        set_owned(std::string(month_name(decode_date(value_).month, count == 3)));
    }
    return true;
}

// Numeric date/time fields; returns false when the token is not one of them.
bool MaskRun::date_num_token(std::ptrdiff_t count) {
    if (ch_ == 't' && (count == 1 || count == 2)) {
        i_ += count - 1;
        if (!do_output_) {
            info().has_ampm = true;
        } else {
            add_src_ =
                (decode_time(value_).hour >= 12) ? std::string_view{"PM"} : std::string_view{"AM"};
            add_len_ = count;
            do_add_ = true;
        }
        return true;
    }

    const bool year4 = ch_ == 'y' && count == 4;
    const bool two_digit_year = ch_ == 'y' && count < 3;
    const bool field =
        (count == 1 || count == 2) && (ch_ == 'd' || ch_ == 'm' || ch_ == 'n' || ch_ == 'M' ||
                                       ch_ == 's' || ch_ == 'h' || ch_ == 'H');
    if (!year4 && !two_digit_year && !field) {
        return false;
    }
    i_ += count - 1;
    if (field && (ch_ == 'h' || ch_ == 'H')) {
        did_hour_ = true;
    }
    if (!do_output_) {
        return true;
    }

    if (year4) {
        set_text(std::format("{:04}", decode_date(value_).year));
        return true;
    }
    set_text(numeric_text(ch_, count, two_digit_year, info().has_ampm, value_));
    return true;
}

// Entry point (str_format.c fb_hStrFormat, non-empty mask). Returns nullopt on error.
std::optional<std::string> format_value(double value, std::string_view mask) {
    MaskInfo info{};
    if (!MaskRun{mask, value, info, nullptr}.run()) {
        return std::nullopt;
    }
    std::string out;
    if (!MaskRun{mask, value, info, &out}.run()) {
        return std::nullopt;
    }
    return out;
}

} // namespace

std::string format(double value, std::string_view mask) {
    if (mask.empty()) {
        return build_double(value);
    }
    return format_value(value, mask).value_or(std::string{});
}

} // namespace gef::fb
