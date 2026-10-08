' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Exhaustive conversion check over all 2^32 Single bit patterns (M3.3 golden). For each pattern x
' it applies CLng, CLngInt, ULongInt assignment, Fix and Sgn, and folds the raw result bits of each
' operation into its own FNV-style hash (ULongInt arithmetic, wrapping). Hashes restart for every
' block of 2^24 consecutive patterns. Usage: conv_single (no arguments; takes several minutes).
' Writes conv_single.txt in the working directory: 256 lines
'   <block 2 hex digits> <h_clng> <h_clngint> <h_ulongint> <h_fix> <h_sgn>
' with each hash as 16 lowercase hex digits.

Sub Mix(ByRef H As ULongInt, ByVal V As ULongInt)
  H = (H Xor V) * &h100000001B3ULL
End Sub

Dim As ULongInt HC, HL, HU, HF, HS
Dim As ULong Bits, U32
Dim As ULongInt U64

Open "conv_single.txt" For Output As #1
For B As ULong = 0 To 255
  HC = &hCBF29CE484222325ULL
  HL = &hCBF29CE484222325ULL
  HU = &hCBF29CE484222325ULL
  HF = &hCBF29CE484222325ULL
  HS = &hCBF29CE484222325ULL
  For L As ULong = 0 To &hFFFFFF
    Bits = (B Shl 24) Or L
    Dim As Single X = *Cast(Single Ptr, @Bits)

    Dim As Long R32 = CLng(X)
    U32 = *Cast(ULong Ptr, @R32)
    U64 = U32
    Mix HC, U64

    Dim As LongInt R64 = CLngInt(X)
    U64 = *Cast(ULongInt Ptr, @R64)
    Mix HL, U64

    Dim As ULongInt RU = X
    Mix HU, RU

    Dim As Single FX = Fix(X)
    U32 = *Cast(ULong Ptr, @FX)
    U64 = U32
    Mix HF, U64

    Dim As Long SG = Sgn(X)
    U32 = *Cast(ULong Ptr, @SG)
    U64 = U32
    Mix HS, U64
  Next L
  Print #1, LCase(Hex(B, 2)) & " " & LCase(Hex(HC, 16)) & " " & LCase(Hex(HL, 16)) & " " & _
    LCase(Hex(HU, 16)) & " " & LCase(Hex(HF, 16)) & " " & LCase(Hex(HS, 16))
Next B
Close #1
