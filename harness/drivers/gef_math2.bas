' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' GEF maths check (M3.4 golden): Min and Max (utilities.bi), and Round and Modulo (GEF.bas cut).
' (a) Min/Max grid: all ordered pairs of a fixed Single grid.
' (b) Min/Max random: Randomize 4242, 3; 2^20 pairs of random Single bit patterns, in 16 blocks of
'     2^16; hashes of Min and Max results restarted per block.
' (c) Round grid: Round(R, N) for fixed N and R values.
' (d) Round random: continuing the Rnd stream after (b); 2^20 random Single bit patterns R, each
'     rounded with N in {1, 2, 3, 4, 5, 7}; one hash per N, restarted per block of 2^16.
' (e) Modulo: continuing the stream after (d); 4096 pairs with divisor sizes varying by line index.
' Usage: gef_math2 (no arguments).
' Writes in the working directory:
'   minmax_grid.txt    <a 8 hex> <b 8 hex> <Min(a,b) 8 hex> <Max(a,b) 8 hex>, all ordered pairs
'   minmax_random.txt  16 lines: <block 1 hex digit> <h_min> <h_max>
'   round_grid.txt     <N decimal> <R 8 hex> <Round(R,N) 8 hex>
'   round_random.txt   16 lines: <block 1 hex digit> <6 hashes, in N order 1 2 3 4 5 7>
'   modulo.txt         4096 lines: <i 16 hex> <j 16 hex> <Modulo(i,j) 16 hex>
' Hashes are FNV-style over the raw result bits, 16 lowercase hex digits.
' NaN results of Min, Max and Round are hashed as the canonical Single NaN 0x7FC00000 (sign and
' payload ignored); grid files keep raw result bits.

Declare Function Round(R As Single, N As Integer) As Single
Declare Function Floor(R As Single) As Single
Declare Function Ceil(R As Single) As Single
Declare Function Modulo(I As ULongint, J As ULongint) As Longint

'@include-source utilities.bi
'@cut GEF.bas:18052-18089 as gef_round.bi

#include "utilities.bi"
#include "gef_round.bi"

Sub Mix(ByRef H As ULongInt, ByVal V As ULongInt)
  H = (H Xor V) * &h100000001B3ULL
End Sub

Function Bits32(ByVal R As Single) As ULong
  Return *Cast(ULong Ptr, @R)
End Function

' Raw bits of a Single result; every NaN maps to the canonical NaN 0x7FC00000.
Function Canon32(ByVal R As Single) As ULong
  Dim As Long N = (R <> R)
  If N Then Return &h7FC00000
  Return *Cast(ULong Ptr, @R)
End Function

Function Single32(ByVal V As ULong) As Single
  Return *Cast(Single Ptr, @V)
End Function

Function Hex8(ByVal V As ULong) As String
  Return LCase(Hex(V, 8))
End Function

Function Hex16(ByVal V As ULongInt) As String
  Return LCase(Hex(V, 16))
End Function

Dim As ULong GB(0 To 12) = { _
  &h00000000, &h80000000, &h00000001, &h3F800000, &hBF800000, &h3FC00000, &hBFC00000, _
  &h7F7FFFFF, &hFF7FFFFF, &h7F800000, &hFF800000, &h7FC00000, &hFFC00000 }

Dim As ULong A, B
Dim As Single SA, SB
Dim As ULong H1, H2

' (a) Min/Max grid
Open "minmax_grid.txt" For Output As #1
For I As Long = 0 To 12
  For J As Long = 0 To 12
    A = GB(I)
    B = GB(J)
    SA = Single32(A)
    SB = Single32(B)
    Print #1, Hex8(A) & " " & Hex8(B) & " " & Hex8(Bits32(Min(SA, SB))) & " " & _
      Hex8(Bits32(Max(SA, SB)))
  Next J
Next I
Close #1

' (b) Min/Max random pairs
Randomize 4242, 3
Open "minmax_random.txt" For Output As #1
For Blk As ULong = 0 To 15
  Dim As ULongInt HMin = &hCBF29CE484222325ULL
  Dim As ULongInt HMax = &hCBF29CE484222325ULL
  For K As Long = 1 To 65536
    A = CULng(Rnd * 4294967296#)
    B = CULng(Rnd * 4294967296#)
    SA = Single32(A)
    SB = Single32(B)
    Mix HMin, CULngInt(Canon32(Min(SA, SB)))
    Mix HMax, CULngInt(Canon32(Max(SA, SB)))
  Next K
  Print #1, LCase(Hex(Blk, 1)) & " " & Hex16(HMin) & " " & Hex16(HMax)
Next Blk
Close #1

' (c) Round grid
Dim As Long NV(0 To 10) = { -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 10 }
Dim As ULong RB(0 To 16) = { _
  &h00000000, &h80000000, &h3F800000, &hBF800000, &h3F000000, &h3FA00000, &h40200000, _
  &h39017428, &h42F6E979, &h42C7E666, &h4479FCCD, &hC7C0E6B7, &h000116C2, &h7F7FFFFF, _
  &h7F800000, &hFF800000, &h7FC00000 }

Dim As Single R
Open "round_grid.txt" For Output As #1
For I As Long = 0 To 10
  For J As Long = 0 To 16
    R = Single32(RB(J))
    Print #1, Str(NV(I)) & " " & Hex8(RB(J)) & " " & Hex8(Bits32(Round(R, NV(I))))
  Next J
Next I
Close #1

' (d) Round random values, continuing the stream
Dim As Long NR(0 To 5) = { 1, 2, 3, 4, 5, 7 }
Dim As ULongInt HR(0 To 5)
Open "round_random.txt" For Output As #1
For Blk As ULong = 0 To 15
  For K As Long = 0 To 5
    HR(K) = &hCBF29CE484222325ULL
  Next K
  For K As Long = 1 To 65536
    A = CULng(Rnd * 4294967296#)
    R = Single32(A)
    For N As Long = 0 To 5
      Mix HR(N), CULngInt(Canon32(Round(R, NR(N))))
    Next N
  Next K
  Print #1, LCase(Hex(Blk, 1)) & " " & Hex16(HR(0)) & " " & Hex16(HR(1)) & " " & Hex16(HR(2)) & " " & _
    Hex16(HR(3)) & " " & Hex16(HR(4)) & " " & Hex16(HR(5))
Next Blk
Close #1

' (e) Modulo, continuing the stream
Dim As ULongInt I64, J64, M64
Dim As ULong Hi, Lo
Open "modulo.txt" For Output As #1
For K As Long = 0 To 4095
  Hi = CULng(Rnd * 4294967296#)
  Lo = CULng(Rnd * 4294967296#)
  I64 = (CULngInt(Hi) Shl 32) Or CULngInt(Lo)
  Hi = CULng(Rnd * 4294967296#)
  Lo = CULng(Rnd * 4294967296#)
  J64 = (CULngInt(Hi) Shl 32) Or CULngInt(Lo)
  J64 = J64 Shr (K Mod 64)
  If J64 = 0 Then J64 = 1
  M64 = CULngInt(Modulo(I64, J64))
  Print #1, Hex16(I64) & " " & Hex16(J64) & " " & Hex16(M64)
Next K
Close #1
