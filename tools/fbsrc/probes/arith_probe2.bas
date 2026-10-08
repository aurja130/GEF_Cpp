' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' fbc arithmetic probe 2 (M3.2, Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md).
' Read the generated C with:  fbc -gen gcc -r arith_probe2.bas   (writes arith_probe2.c)

Dim Shared As Single s, t, u, r
Dim Shared As Double d, e, rd
Dim Shared As Integer i, j, ri
Function F(ByVal x As Single) As Single
  Return x
End Function
r = s + 1
r = 1 - s
r = s * 2 * t
r = (s + t) * 0.5
r = 0.5 * (s + t)
r = s * t / 2
r = s * (t + 0.1)
r = d * s
r = i * 0.5
r = i + 1.5
r = i * s * 0.1
r = F(s * 0.1)
r = s * t * u / 0.5
r = s / 0.5 * t
r = s * 0.1 + t * 0.2 + u
rd = d + 0.1 + e + 0.2
r = s * s * s
r = 2 * s * 3
r = s * 1e-3 * t * 1e3
r = s * -0.5 * t
r = s * t * (u * 0.1)
r = -(s * 0.1)
r = s * t - 0.1 * u
r = s * 0.1F * t
