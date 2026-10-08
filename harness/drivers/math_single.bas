' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Exhaustive Single maths check over all 2^32 Single bit patterns (M3.4 golden). For each pattern x
' it applies Exp, Log, Sqr, Int, Abs, Sin, Acos, Erf, Erfc, Tanh, Coth, Log10, Floor and Ceil
' (Single forms, Erf/Erfc/Tanh/Coth/Log10/Floor/Ceil from GEF) and folds the raw result bits of each
' operation into its own FNV-style hash (ULongInt arithmetic, wrapping). Hashes restart for every
' block of 2^24 consecutive patterns. Usage: math_single (no arguments; takes a long time).
' Writes math_single.txt in the working directory: 256 lines
'   <block 2 hex digits> <h_exp> <h_log> <h_sqr> <h_int> <h_abs> <h_sin> <h_acos> <h_erf>
'     <h_erfc> <h_tanh> <h_coth> <h_log10> <h_floor> <h_ceil>
' with each hash as 16 lowercase hex digits.
' NaN results are hashed as the canonical Single NaN 0x7FC00000 (sign and payload ignored).

'@include-source utilities.bi
'@cut GEF.bas:18052-18089 as gef_round.bi

Declare Function Round(R As Single, N As Integer) As Single
Declare Function Floor(R As Single) As Single
Declare Function Ceil(R As Single) As Single
Declare Function Modulo(I As ULongint, J As ULongint) As Longint

#include "utilities.bi"
#include "gef_round.bi"

Sub Mix(ByRef H As ULongInt, ByVal V As ULongInt)
  H = (H Xor V) * &h100000001B3ULL
End Sub

' Raw bits of a Single result; every NaN maps to the canonical NaN 0x7FC00000.
Function Canon32(ByVal R As Single) As ULong
  Dim As Long N = (R <> R)
  If N Then Return &h7FC00000
  Return *Cast(ULong Ptr, @R)
End Function

Dim As ULongInt H(0 To 13)
Dim As ULong Bits, U32
Dim As Single X, R

Open "math_single.txt" For Output As #1
For B As ULong = 0 To 255
  For K As Long = 0 To 13
    H(K) = &hCBF29CE484222325ULL
  Next K
  For L As ULong = 0 To &hFFFFFF
    Bits = (B Shl 24) Or L
    X = *Cast(Single Ptr, @Bits)

    R = Exp(X)
    U32 = Canon32(R): Mix H(0), CULngInt(U32)
    R = Log(X)
    U32 = Canon32(R): Mix H(1), CULngInt(U32)
    R = Sqr(X)
    U32 = Canon32(R): Mix H(2), CULngInt(U32)
    R = Int(X)
    U32 = Canon32(R): Mix H(3), CULngInt(U32)
    R = Abs(X)
    U32 = Canon32(R): Mix H(4), CULngInt(U32)
    R = Sin(X)
    U32 = Canon32(R): Mix H(5), CULngInt(U32)
    R = Acos(X)
    U32 = Canon32(R): Mix H(6), CULngInt(U32)
    R = Erf(X)
    U32 = Canon32(R): Mix H(7), CULngInt(U32)
    R = Erfc(X)
    U32 = Canon32(R): Mix H(8), CULngInt(U32)
    R = Tanh(X)
    U32 = Canon32(R): Mix H(9), CULngInt(U32)
    R = Coth(X)
    U32 = Canon32(R): Mix H(10), CULngInt(U32)
    R = Log10(X)
    U32 = Canon32(R): Mix H(11), CULngInt(U32)
    R = Floor(X)
    U32 = Canon32(R): Mix H(12), CULngInt(U32)
    R = Ceil(X)
    U32 = Canon32(R): Mix H(13), CULngInt(U32)
  Next L
  Dim As String Txt = LCase(Hex(B, 2))
  For K As Long = 0 To 13
    Txt = Txt & " " & LCase(Hex(H(K), 16))
  Next K
  Print #1, Txt
Next B
Close #1
