' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Str formatting check (M3.6a golden), three parts plus LongInt.
' (a) Grids: fixed Single and Double values at both signs, with NaN and infinities; each line
'     is the input bit pattern and Str of it, nothing after.
' (b) Random: Randomize 99, 3; 2^20 Double bit patterns (hi drawn first, then lo) in 16 blocks
'     of 2^16; FNV-1a hash of the Str texts (each followed by LF), restarted per block.
' (c) Moderate: the same Rnd stream continues with 2^20 values x = (Rnd - 0.5) * 2000, same hashes.
' (d) LongInt: a grid of fixed values, then 4096 random values (hi drawn first), one line each.
' Usage: str_numbers (no arguments).
' Writes in the working directory:
'   str_double_grid.txt      <x bits 16 hex> <Str(x)>
'   str_single_grid.txt      <x bits 8 hex> <Str(x)>
'   str_double_random.txt    16 lines: <block 1 hex digit> <hash>
'   str_double_moderate.txt  16 lines, same format as str_double_random.txt
'   str_longint.txt          <i bits 16 hex> <Str(i)>, grid then random

Sub MixStr(ByRef H As ULongInt, ByRef S As String)
  Dim As UByte Ptr P = StrPtr(S)
  For K As Long = 0 To Len(S) - 1
    H = (H Xor CULngInt(P[K])) * &h100000001B3ULL
  Next K
  H = (H Xor &h0AULL) * &h100000001B3ULL
End Sub

' One Double grid line for the bit pattern Bits.
Sub WriteD(ByVal Bits As ULongInt)
  Dim As Double X = *Cast(Double Ptr, @Bits)
  Print #1, LCase(Hex(Bits, 16)) & " " & Str(X)
End Sub

' One Single grid line for the bit pattern Bits.
Sub WriteS(ByVal Bits As ULong)
  Dim As Single X = *Cast(Single Ptr, @Bits)
  Print #1, LCase(Hex(Bits, 8)) & " " & Str(X)
End Sub

' One LongInt line for the bit pattern U.
Sub WriteL(ByVal U As ULongInt)
  Dim As LongInt I = *Cast(LongInt Ptr, @U)
  Print #1, LCase(Hex(U, 16)) & " " & Str(I)
End Sub

' Finite non-zero Double values of the grid; each is written with sign + and sign -.
Dim As Double DV(0 To 16) = { _
  1e-310, 1e-300, 1e-17, 1e-16, 1e-15, 0.1, 0.5, 1, 1.5, 0.6666666666666666, 10, _
  123456789012345.6, 1e15, 1e16, 1e17, 9007199254740993#, 1.7976931348623157e308 }

' Finite non-zero Single values of the grid.
Dim As Single SV(0 To 12) = { _
  1e-45, 1e-38, 0.1, 0.5, 1, 1.5, 0.6666667, 10, 1234567, 12345678, 1e7, 1e8, 3.4028235e38 }

Dim As ULongInt Bits, DBits
Dim As ULong SBits
Dim As ULong Hi, Lo
Dim As ULongInt H
Dim As String T

' (a) Double grid
Open "str_double_grid.txt" For Output As #1
WriteD &h0000000000000000ULL
WriteD &h8000000000000000ULL
WriteD &h0000000000000001ULL
For I As Long = 0 To 16
  DBits = *Cast(ULongInt Ptr, @DV(I))
  WriteD DBits
Next I
WriteD &h7FF0000000000000ULL
WriteD &hFFF0000000000000ULL
WriteD &h7FF8000000000000ULL
WriteD &hFFF8000000000000ULL
WriteD &h8000000000000001ULL
For I As Long = 0 To 16
  DBits = *Cast(ULongInt Ptr, @DV(I)) Or &h8000000000000000ULL
  WriteD DBits
Next I
Close #1

' (a) Single grid
Open "str_single_grid.txt" For Output As #1
WriteS &h00000000UL
WriteS &h80000000UL
WriteS &h00000001UL
For I As Long = 0 To 12
  SBits = *Cast(ULong Ptr, @SV(I))
  WriteS SBits
Next I
WriteS &h7F800000UL
WriteS &hFF800000UL
WriteS &h7FC00000UL
WriteS &hFFC00000UL
WriteS &h80000001UL
For I As Long = 0 To 12
  SBits = *Cast(ULong Ptr, @SV(I)) Or &h80000000UL
  WriteS SBits
Next I
Close #1

' (b) Random Double bit patterns
Randomize 99, 3
Open "str_double_random.txt" For Output As #1
For Blk As ULong = 0 To 15
  H = &hCBF29CE484222325ULL
  For J As Long = 1 To 65536
    Hi = CULng(Rnd * 4294967296#)
    Lo = CULng(Rnd * 4294967296#)
    Bits = (CULngInt(Hi) Shl 32) Or CULngInt(Lo)
    Dim As Double X = *Cast(Double Ptr, @Bits)
    T = Str(X)
    MixStr H, T
  Next J
  Print #1, LCase(Hex(Blk, 1)) & " " & LCase(Hex(H, 16))
Next Blk
Close #1

' (c) Moderate values, continuing the same stream
Open "str_double_moderate.txt" For Output As #1
For Blk As ULong = 0 To 15
  H = &hCBF29CE484222325ULL
  For J As Long = 1 To 65536
    Dim As Double Y = (Rnd - 0.5) * 2000
    T = Str(Y)
    MixStr H, T
  Next J
  Print #1, LCase(Hex(Blk, 1)) & " " & LCase(Hex(H, 16))
Next Blk
Close #1

' (d) LongInt grid, then random values continuing the stream
Open "str_longint.txt" For Output As #1
WriteL 0
WriteL 1
WriteL &hFFFFFFFFFFFFFFFFULL
WriteL 9
WriteL 10
WriteL &hFFFFFFFFFFFFFFF6ULL
WriteL 2147483647
WriteL &hFFFFFFFF80000000ULL
WriteL &h7FFFFFFFFFFFFFFFULL
WriteL &h8000000000000000ULL
For J As Long = 1 To 4096
  Hi = CULng(Rnd * 4294967296#)
  Lo = CULng(Rnd * 4294967296#)
  Bits = (CULngInt(Hi) Shl 32) Or CULngInt(Lo)
  WriteL Bits
Next J
Close #1
