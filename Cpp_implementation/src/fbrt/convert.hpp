// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team
// (LGPL-2.0-or-later).

// FreeBASIC numeric conversions and integer arithmetic as GEF's compiled code performs them
// (M3.3; rules in FBC_ARITHMETIC.md, R8). Names follow the generated C, so a statement ported
// from `fbline` output maps one to one: `fb_F2L(S$)` becomes `fb::f2l(s)`.

#pragma once

#include <cstdint>

namespace gef::fb {

// Float to integer: fbc's inline macros `(intN)__builtin_nearbyint[f](x)`. nearbyint rounds
// to nearest, ties to even. The cast of a value outside the target range (and of NaN) is what
// x86-64 gcc emits at fbc's -O0: cvttss2si/cvttsd2si yield the "integer indefinite" (the
// minimum of the signed type); the unsigned 64-bit cast uses gcc's two-range sequence.
// Each result is the one the FreeBASIC driver prints (goldens m3-conv-*).
[[nodiscard]] std::int32_t f2i(float x) noexcept;    // fb_F2I: Long = Single, CLng(Single)
[[nodiscard]] std::int64_t f2l(float x) noexcept;    // fb_F2L: Integer = Single, CInt(Single)
[[nodiscard]] std::uint64_t f2ul(float x) noexcept;  // fb_F2UL: ULongInt = Single
[[nodiscard]] std::int32_t d2i(double x) noexcept;   // fb_D2I: Long = Double
[[nodiscard]] std::int64_t d2l(double x) noexcept;   // fb_D2L: Integer = Double, CInt(Double)
[[nodiscard]] std::uint64_t d2ul(double x) noexcept; // fb_D2UL: ULongInt = Double

// Runtime functions (libfb.a): Fix(x) = trunc(|x|) * Sgn(x); Sgn returns -1, 0 or 1, and -1
// for NaN (the unordered compare falls through to the "not greater" branch).
[[nodiscard]] float fix(float x) noexcept;               // fb_FIXSingle
[[nodiscard]] double fix(double x) noexcept;             // fb_FIXDouble
[[nodiscard]] std::int32_t sgn(float x) noexcept;        // fb_SGNSingle
[[nodiscard]] std::int32_t sgn(double x) noexcept;       // fb_SGNDouble
[[nodiscard]] std::int32_t sgn(std::int64_t x) noexcept; // fb_SGNl

// Integer arithmetic. fbc's gcc backend compiles with -fwrapv, so Integer (int64) and Long
// (int32) +, -, *, unary - and Abs wrap in two's complement; in C++ signed overflow is
// undefined, so ported code uses these helpers wherever an operation can overflow.
[[nodiscard]] std::int64_t add(std::int64_t a, std::int64_t b) noexcept;
[[nodiscard]] std::int64_t sub(std::int64_t a, std::int64_t b) noexcept;
[[nodiscard]] std::int64_t mul(std::int64_t a, std::int64_t b) noexcept;
[[nodiscard]] std::int64_t neg(std::int64_t a) noexcept;
[[nodiscard]] std::int64_t
abs(std::int64_t a) noexcept; // __builtin_llabs: Abs(&h8000...) stays negative
[[nodiscard]] std::int32_t add(std::int32_t a, std::int32_t b) noexcept;
[[nodiscard]] std::int32_t sub(std::int32_t a, std::int32_t b) noexcept;
[[nodiscard]] std::int32_t mul(std::int32_t a, std::int32_t b) noexcept;

// Integer `\` and `Mod`: C's truncating `/` and `%`. A zero divisor, or the minimum value
// divided by -1, traps (SIGFPE) in the compiled BASIC; here they throw std::domain_error.
[[nodiscard]] std::int64_t idiv(std::int64_t a, std::int64_t b);
[[nodiscard]] std::int64_t imod(std::int64_t a, std::int64_t b);

} // namespace gef::fb
