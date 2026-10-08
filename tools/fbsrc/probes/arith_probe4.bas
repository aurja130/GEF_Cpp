' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' fbc arithmetic probe 4 (M3.6a, Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md R10).
' Read the generated C with:  fbc -gen gcc -r arith_probe4.bas   (writes arith_probe4.c)

Dim Shared As Double x, t, y
y = (x - 0.5) * 2000
y = (x + 0.5) * t
y = (x + t) * 2
y = 2 * (x + 0.5)
y = (x + 0.5) / 4
y = (x * 3 + 0.5) * 2
y = -(x + 0.5)
