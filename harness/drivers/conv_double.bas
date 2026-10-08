' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Double-to-integer and Fix/Sgn conversion check (M3.3 golden), two parts.
' (a) Grid: fixed Double bit patterns at both signs plus three NaN patterns, each converted with
'     CLng, CLngInt, ULongInt assignment, Fix and Sgn; raw result bits are written per value.
' (b) Random: Randomize 12345, 3; 2^20 values built from two Rnd draws each (hi first, then lo),
'     converted as in (a) and folded into five FNV-style hashes, restarted per block of 2^16.
' Usage: conv_double (no arguments).
' Writes in the working directory:
'   conv_double_grid.txt    one line per grid value (positive values, then negative values,
'     then the NaNs):  <input bits 16 hex> <clng 8 hex> <clngint 16 hex> <ulongint 16 hex>
'     <fix 16 hex> <sgn 8 hex>
'   conv_double_random.txt  16 lines: <block 1 hex digit> <h_clng> <h_clngint> <h_ulongint>
'     <h_fix> <h_sgn>, hashes as 16 lowercase hex digits

Sub Mix(ByRef H As ULongInt, ByVal V As ULongInt)
  H = (H Xor V) * &h100000001B3ULL
End Sub

' Raw result bits of the five operations applied to the Double with bit pattern Bits.
Sub Convert(ByVal Bits As ULongInt, ByRef C32 As ULongInt, ByRef C64 As ULongInt, _
            ByRef CU As ULongInt, ByRef CF As ULongInt, ByRef CS As ULongInt)
  Dim As Double X = *Cast(Double Ptr, @Bits)
  Dim As Long R32 = CLng(X)
  Dim As ULong U32 = *Cast(ULong Ptr, @R32)
  C32 = U32
  Dim As LongInt R64 = CLngInt(X)
  C64 = *Cast(ULongInt Ptr, @R64)
  Dim As ULongInt RU = X
  CU = RU
  Dim As Double FX = Fix(X)
  CF = *Cast(ULongInt Ptr, @FX)
  Dim As Long SG = Sgn(X)
  U32 = *Cast(ULong Ptr, @SG)
  CS = U32
End Sub

Dim As ULongInt Posv(0 To 26) = { _
  &h0000000000000000, &h0000000000000001, &h000FFFFFFFFFFFFF, &h0010000000000000, _
  &h3FE0000000000000, &h3FF8000000000000, &h4004000000000000, &h400C000000000000, _
  &h3FDFFFFFFFFFFFFF, &h3FEFFFFFFFFFFFFF, &h41DFFFFFFFE00000, &h41DFFFFFFFC00000, _
  &h41E0000000000000, &h41E0000000100000, &h41EFFFFFFFF00000, &h41F0000000000000, _
  &h432FFFFFFFFFFFFF, &h4330000000000000, &h4340000000000001, &h43DFFFFFFFFFFFFF, _
  &h43E0000000000000, &h43EFFFFFFFFFFFFF, &h43F0000000000000, &h43F0000000000001, _
  &h7E37E43C8800759C, &h7FEFFFFFFFFFFFFF, &h7FF0000000000000 }

Dim As ULongInt Nan(0 To 2) = { &h7FF8000000000000, &hFFF8000000000000, &h7FF0000000000001 }

Dim As ULongInt C32, C64, CU, CF, CS
Dim As ULongInt Bits

Open "conv_double_grid.txt" For Output As #1
For S As Long = 0 To 1
  For I As Long = 0 To 26
    Bits = Posv(I)
    If S = 1 Then Bits = Bits Or &h8000000000000000ULL
    Convert Bits, C32, C64, CU, CF, CS
    Print #1, LCase(Hex(Bits, 16)) & " " & LCase(Hex(C32, 8)) & " " & LCase(Hex(C64, 16)) & " " & _
      LCase(Hex(CU, 16)) & " " & LCase(Hex(CF, 16)) & " " & LCase(Hex(CS, 8))
  Next I
Next S
For I As Long = 0 To 2
  Bits = Nan(I)
  Convert Bits, C32, C64, CU, CF, CS
  Print #1, LCase(Hex(Bits, 16)) & " " & LCase(Hex(C32, 8)) & " " & LCase(Hex(C64, 16)) & " " & _
    LCase(Hex(CU, 16)) & " " & LCase(Hex(CF, 16)) & " " & LCase(Hex(CS, 8))
Next I
Close #1

Dim As ULongInt H1, H2, H3, H4, H5
Dim As ULong Hi, Lo

Randomize 12345, 3
Open "conv_double_random.txt" For Output As #1
For Blk As ULong = 0 To 15
  H1 = &hCBF29CE484222325ULL
  H2 = H1
  H3 = H1
  H4 = H1
  H5 = H1
  For K As Long = 1 To 65536
    Hi = CULng(Rnd * 4294967296#)
    Lo = CULng(Rnd * 4294967296#)
    Bits = (CULngInt(Hi) Shl 32) Or CULngInt(Lo)
    Convert Bits, C32, C64, CU, CF, CS
    Mix H1, C32
    Mix H2, C64
    Mix H3, CU
    Mix H4, CF
    Mix H5, CS
  Next K
  Print #1, LCase(Hex(Blk, 1)) & " " & LCase(Hex(H1, 16)) & " " & LCase(Hex(H2, 16)) & " " & _
    LCase(Hex(H3, 16)) & " " & LCase(Hex(H4, 16)) & " " & LCase(Hex(H5, 16))
Next Blk
Close #1
