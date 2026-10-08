' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Run-time evidence for the fbc arithmetic rules of Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md
' (M3 plan, M3.2). Each expression E1..E18 is one rule's example; the C++ test
' (fbc_arithmetic_test.cpp) evaluates the same expressions the way the rules say fbc compiles
' them and must reproduce every result bit for bit.
'
' Usage: arith_rules [count]   (default 2000)
' Inputs come from Randomize 1, 3: per row s, t, u (Single), d, e (Double), i (Integer).
' Writes arith_rules.txt: one row per input set, the result bit patterns in hex (8 digits for
' Single, 16 for Double), space separated, inputs first.

Function B32(ByVal X As Single) As String
  Return LCase(Hex(*Cast(ULong Ptr, @X), 8))
End Function

Function B64(ByVal X As Double) As String
  Return LCase(Hex(*Cast(ULongInt Ptr, @X), 16))
End Function

Dim As Long Count = 2000
If Len(Command(1)) > 0 Then Count = CLng(Val(Command(1)))

Dim As Single s, t, u, r
Dim As Double d, e, rd
Dim As Integer i

Randomize 1, 3
Open "arith_rules.txt" For Output As #1
For K As Long = 1 To Count
  s = (Rnd - 0.5) * 1000
  t = (Rnd - 0.5) * 1000
  u = Rnd - 0.5
  d = (Rnd - 0.5) * 1000
  e = Rnd - 0.5
  i = Int(Rnd * 2000) - 1000
  Dim As String Row = B32(s) & " " & B32(t) & " " & B32(u) & " " & B64(d) & " " & B64(e) & " " & i
  r = s * 0.1 * t:            Row &= " " & B32(r)   ' E1
  r = 0.1 * s * t * u:        Row &= " " & B32(r)   ' E2
  r = s + 0.1 + t:            Row &= " " & B32(r)   ' E3
  r = s * 0.1 * t * 0.2 * u:  Row &= " " & B32(r)   ' E4
  r = s * (t * u):            Row &= " " & B32(r)   ' E5
  r = s - (t - u):            Row &= " " & B32(r)   ' E6
  r = s * t * (u * 0.1):      Row &= " " & B32(r)   ' E7
  r = s / 0.5 * t:            Row &= " " & B32(r)   ' E8
  r = s * t / 2 * u:          Row &= " " & B32(r)   ' E9
  r = s / t * u:              Row &= " " & B32(r)   ' E10
  r = s * t + u * 0.5:        Row &= " " & B32(r)   ' E11
  r = s ^ 2:                  Row &= " " & B32(r)   ' E12
  r = s ^ 3:                  Row &= " " & B32(r)   ' E13
  rd = d * 0.1 * e:           Row &= " " & B64(rd)  ' E14
  rd = d + 0.1 + e + 0.2:     Row &= " " & B64(rd)  ' E15
  r = i * s * 0.1:            Row &= " " & B32(r)   ' E16
  r = Exp(-u * 0.5):          Row &= " " & B32(r)   ' E17
  r = s - 0.1 - t:            Row &= " " & B32(r)   ' E18
  Print #1, Row
Next K
Close #1
