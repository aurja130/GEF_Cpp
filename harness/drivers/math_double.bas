' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Double maths check (M3.4 golden), five parts.
' (a) Grid: fixed Double bit patterns at both signs (0, denormals, normals, 1e-10 .. 1e300, max
'     double, +Inf) plus positive and negative NaN; each run through Exp, Log, Sqr, Int, Abs and Cos.
' (b) Random: Randomize 777, 3; 2^20 values built from two Rnd draws each (hi first, then lo), in
'     16 blocks of 2^16; six FNV-style hashes (one per function) restarted per block.
' (c) Moderate: continuing the same Rnd stream, 2^20 values x = (Rnd - 0.5) * 1500 (one Rnd each),
'     same six hashes in 16 blocks.
' (d) Pow grid: every base and exponent in the fixed lists, result of base ^ exponent (pow).
' (e) Pow random: continuing the Rnd stream, 2^20 pairs b = Rnd * 20, e = (Rnd - 0.5) * 40 (b drawn
'     first), hash of b ^ e in 16 blocks of 2^16.
' Usage: math_double (no arguments).
' NaN results are hashed as the canonical Double NaN 0x7FF8000000000000 (sign and payload ignored);
'   grid files keep raw result bits.
' Writes in the working directory:
'   math_double_grid.txt      one line per grid value: <x bits 16 hex> <exp> <log> <sqr> <int> <abs>
'                             <cos>, each result as raw Double bits, 16 lowercase hex digits
'   math_double_random.txt    16 lines: <block 1 hex digit> <h_exp> <h_log> <h_sqr> <h_int> <h_abs>
'                             <h_cos>
'   math_double_moderate.txt  16 lines, same format as math_double_random.txt
'   pow_grid.txt              one line per (base, exponent): <base bits> <exponent bits> <result bits>
'   pow_random.txt            16 lines: <block 1 hex digit> <hash of b ^ e>

Sub Mix(ByRef H As ULongInt, ByVal V As ULongInt)
  H = (H Xor V) * &h100000001B3ULL
End Sub

' Raw result bits of Exp, Log, Sqr, Int, Abs and Cos of the Double with bit pattern Bits.
Sub Apply(ByVal Bits As ULongInt, O() As ULongInt)
  Dim As Double X = *Cast(Double Ptr, @Bits)
  Dim As Double R
  R = Exp(X)
  O(0) = *Cast(ULongInt Ptr, @R)
  R = Log(X)
  O(1) = *Cast(ULongInt Ptr, @R)
  R = Sqr(X)
  O(2) = *Cast(ULongInt Ptr, @R)
  R = Int(X)
  O(3) = *Cast(ULongInt Ptr, @R)
  R = Abs(X)
  O(4) = *Cast(ULongInt Ptr, @R)
  R = Cos(X)
  O(5) = *Cast(ULongInt Ptr, @R)
End Sub

Function Hex16(ByVal V As ULongInt) As String
  Return LCase(Hex(V, 16))
End Function

' Bits of a Double value; every NaN maps to the canonical NaN 0x7FF8000000000000.
Function Canon64(ByVal V As ULongInt) As ULongInt
  Dim As Double D = *Cast(Double Ptr, @V)
  Dim As Long N = (D <> D)
  If N Then Return &h7FF8000000000000ULL
  Return V
End Function

' Grid of positive magnitudes: 0, 5e-324, 1e-310, 2.2250738585072014e-308, 1e-10, 0.1, 0.5, 1, 1.5, 2,
' e, pi, 10, 100, 700, 709.78, 710, 745, 746, 1e10, 1e300, max double, +Inf. Each is written with
' sign + and sign -.
Dim As ULongInt PosV(0 To 22) = { _
  &h0000000000000000, &h0000000000000001, &h000012688B70E62B, &h0010000000000000, _
  &h3DDB7CDFD9D7BDBB, &h3FB999999999999A, &h3FE0000000000000, &h3FF0000000000000, _
  &h3FF8000000000000, &h4000000000000000, &h4005BF0A8B145769, &h400921FB54442D18, _
  &h4024000000000000, &h4059000000000000, &h4085E00000000000, &h40862E3D70A3D70A, _
  &h4086300000000000, &h4087480000000000, &h4087500000000000, &h4202A05F20000000, _
  &h7E37E43C8800759C, &h7FEFFFFFFFFFFFFF, &h7FF0000000000000 }

Dim As ULongInt Nan(0 To 1) = { &h7FF8000000000000, &hFFF8000000000000 }

Dim As ULongInt O(0 To 5), Bits, H(0 To 5)
Dim As Double X, Y, R

' (a) Grid
Open "math_double_grid.txt" For Output As #1
For S As Long = 0 To 1
  For I As Long = 0 To 22
    Bits = PosV(I) Or (CULngInt(S) Shl 63)
    Apply Bits, O()
    Print #1, Hex16(Bits) & " " & Hex16(O(0)) & " " & Hex16(O(1)) & " " & Hex16(O(2)) & " " & _
      Hex16(O(3)) & " " & Hex16(O(4)) & " " & Hex16(O(5))
  Next I
Next S
For I As Long = 0 To 1
  Bits = Nan(I)
  Apply Bits, O()
  Print #1, Hex16(Bits) & " " & Hex16(O(0)) & " " & Hex16(O(1)) & " " & Hex16(O(2)) & " " & _
    Hex16(O(3)) & " " & Hex16(O(4)) & " " & Hex16(O(5))
Next I
Close #1

Dim As ULong Hi, Lo

' (b) Random bit patterns
Randomize 777, 3
Open "math_double_random.txt" For Output As #1
For Blk As ULong = 0 To 15
  For K As Long = 0 To 5
    H(K) = &hCBF29CE484222325ULL
  Next K
  For J As Long = 1 To 65536
    Hi = CULng(Rnd * 4294967296#)
    Lo = CULng(Rnd * 4294967296#)
    Bits = (CULngInt(Hi) Shl 32) Or CULngInt(Lo)
    Apply Bits, O()
    For K As Long = 0 To 5
      Mix H(K), Canon64(O(K))
    Next K
  Next J
  Print #1, LCase(Hex(Blk, 1)) & " " & Hex16(H(0)) & " " & Hex16(H(1)) & " " & Hex16(H(2)) & " " & _
    Hex16(H(3)) & " " & Hex16(H(4)) & " " & Hex16(H(5))
Next Blk
Close #1

' (c) Moderate values, continuing the same stream
Open "math_double_moderate.txt" For Output As #1
For Blk As ULong = 0 To 15
  For K As Long = 0 To 5
    H(K) = &hCBF29CE484222325ULL
  Next K
  For J As Long = 1 To 65536
    X = (Rnd - 0.5) * 1500
    Bits = *Cast(ULongInt Ptr, @X)
    Apply Bits, O()
    For K As Long = 0 To 5
      Mix H(K), Canon64(O(K))
    Next K
  Next J
  Print #1, LCase(Hex(Blk, 1)) & " " & Hex16(H(0)) & " " & Hex16(H(1)) & " " & Hex16(H(2)) & " " & _
    Hex16(H(3)) & " " & Hex16(H(4)) & " " & Hex16(H(5))
Next Blk
Close #1

' (d) Pow grid
Dim As ULongInt PBase(0 To 13) = { _
  &h0000000000000000, &h8000000000000000, &h3FE0000000000000, &hBFE0000000000000, _
  &h3FF0000000000000, &hBFF0000000000000, &h4000000000000000, &hC000000000000000, _
  &h4024000000000000, &h01A56E1FC2F8F359, &h7E37E43C8800759C, &h7FF0000000000000, _
  &hFFF0000000000000, &h7FF8000000000000 }
Dim As ULongInt PExp(0 To 17) = { _
  &hC03E000000000000, &hC024000000000000, &hC008000000000000, &hC000000000000000, _
  &hBFF0000000000000, &hBFE0000000000000, &h0000000000000000, &h3FD5555555555555, _
  &h3FE0000000000000, &h3FF0000000000000, &h4000000000000000, &h4008000000000000, _
  &h4024000000000000, &h403E000000000000, &h4202A05F20000000, &h7FF0000000000000, _
  &hFFF0000000000000, &h7FF8000000000000 }

Dim As ULongInt PB, PE, PR
Open "pow_grid.txt" For Output As #1
For I As Long = 0 To 13
  For K As Long = 0 To 17
    PB = PBase(I)
    PE = PExp(K)
    X = *Cast(Double Ptr, @PB)
    Y = *Cast(Double Ptr, @PE)
    R = X ^ Y
    PR = *Cast(ULongInt Ptr, @R)
    Print #1, Hex16(PB) & " " & Hex16(PE) & " " & Hex16(PR)
  Next K
Next I
Close #1

' (e) Pow random, continuing the stream
Dim As ULongInt HP
Open "pow_random.txt" For Output As #1
For Blk As ULong = 0 To 15
  HP = &hCBF29CE484222325ULL
  For J As Long = 1 To 65536
    X = Rnd * 20
    Y = (Rnd - 0.5) * 40
    R = X ^ Y
    PR = *Cast(ULongInt Ptr, @R)
    Mix HP, Canon64(PR)
  Next J
  Print #1, LCase(Hex(Blk, 1)) & " " & Hex16(HP)
Next Blk
Close #1
