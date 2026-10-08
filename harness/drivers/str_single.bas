' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Exhaustive Str check over all 2^32 Single bit patterns (M3.6a golden). For each pattern x
' it takes Str(x) and folds the text bytes, then a LF byte, into an FNV-1a 64 hash. Hashes
' restart for every block of 2^24 consecutive patterns b * 2^24 + low.
' Usage: str_single [first_block [last_block]] (defaults 0 and 255; takes tens of minutes).
' Writes str_single.txt in the working directory, one line per block:
'   <block 2 hex digits> <hash 16 hex digits>

Sub MixStr(ByRef H As ULongInt, ByRef S As String)
  Dim As UByte Ptr P = StrPtr(S)
  For K As Long = 0 To Len(S) - 1
    H = (H Xor CULngInt(P[K])) * &h100000001B3ULL
  Next K
  H = (H Xor &h0AULL) * &h100000001B3ULL
End Sub

Dim As ULong First, Last
First = 0
Last = 255
If Len(Command(1)) > 0 Then First = CULng(Val(Command(1)))
If Len(Command(2)) > 0 Then Last = CULng(Val(Command(2)))

Open "str_single.txt" For Output As #1
For B As ULong = First To Last
  Dim As ULongInt H = &hCBF29CE484222325ULL
  For L As ULong = 0 To &hFFFFFF
    Dim As ULong Bits = (B Shl 24) Or L
    Dim As Single X = *Cast(Single Ptr, @Bits)
    Dim As String T = Str(X)
    MixStr H, T
  Next L
  Print #1, LCase(Hex(B, 2)) & " " & LCase(Hex(H, 16))
Next B
Close #1
