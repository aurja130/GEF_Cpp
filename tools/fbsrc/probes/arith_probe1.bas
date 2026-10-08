' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' fbc arithmetic probe 1 (M3.2, Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md).
' Read the generated C with:  fbc -gen gcc -r arith_probe1.bas   (writes arith_probe1.c)

Dim Shared As Single s, t, u, r
Dim Shared As Double d, e, rd
Dim Shared As Integer i, j, ri
Dim Shared As Long l
s = 1.1: t = 2.2: u = 3.3: d = 4.4: e = 5.5: i = 7: j = 3: l = 9
r = s * 0.1                ' L1 single * literal
r = s * 0.1 * t            ' L2 chain with literal in middle
r = 0.1 * s * t * u        ' L3 literal first
rd = d * 0.1 * e           ' L4 double chain
r = s + 0.1 + t            ' L5 add chain
r = s * t * 2              ' L6 integer literal
r = s / 3                  ' L7 division by int literal
r = s / t * u              ' L8 div then mul
r = s * d                  ' L9 single*double
r = (s * t) * u            ' L10 parenthesised
r = s * (t * u)            ' L11 right paren
r = -s * t                 ' L12 unary minus
r = s ^ 2                  ' L13
r = s ^ 3                  ' L14
r = s ^ 0.5                ' L15
r = (s + t) ^ 2            ' L16
ri = i \ j                 ' L17
ri = s \ t                 ' L18
ri = i / j                 ' L19
r = i / j                  ' L20
r = 1 / 3                  ' L21 const fold
r = 0.1 + 0.2              ' L22 const fold double
r = s * 2.0 * 3.0          ' L23 fold literals
r = 2.0 * s * 3.0          ' L24
rd = s * t                 ' L25 single product to double
rd = s + 0.1               ' L26
r = s * 1.5!               ' L27 single-suffixed literal
r = s - 0.1 - t            ' L28
r = s * i                  ' L29 single * integer
r = s * l                  ' L30 single * long
If s < 0.1 Then r = 1      ' L31 compare single with literal
If s < d Then r = 2        ' L32
r = s * t + u * 0.5        ' L33
r = Exp(s): rd = Exp(d): r = Exp(-s * 0.5)  ' L34
r = Sqr(s): r = Abs(s): r = Log(s): r = Int(s): r = Fix(s)  ' L35
ri = CInt(s): ri = Int(s): l = s: ri = d    ' L36
r = s * 0.1 * t * 0.2 * u  ' L37 two literals
