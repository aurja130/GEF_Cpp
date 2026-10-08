' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' fbc arithmetic probe 3 (M3.2, Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md).
' Read the generated C with:  fbc -gen gcc -r arith_probe3.bas   (writes arith_probe3.c)

Dim Shared As Single s, t, u, v, r
Dim Shared As Double d, e, f, rd
r = s + (t + u)
rd = d * (e * f)
rd = d + (e + f)
r = s - (t - u)
r = s - (t + u)
r = s * t / 2 * u
r = (s * t) * (u * v)
r = (s + t) + (u + v)
r = s * (t * 0.5)
rd = d * (e * 2) * f
r = s / t / u
r = s / (t / u)
r = s * (t / u)
r = s + t * 0.1 + u
r = s * Exp(t) * 0.5
r = Sqr(s) * 0.5 * t
