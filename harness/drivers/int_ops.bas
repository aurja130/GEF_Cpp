' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Integer arithmetic edge cases (M3.3 golden): LongInt unary and binary operations over an edge
' list, and Long (32-bit) binary operations over a second edge list. Usage: int_ops (no arguments).
' Writes in the working directory:
'   int_unary.txt    per a in E:  <a 16 hex> <-a> <Abs(a)> <Sgn(a) 8 hex>
'   int_binary.txt   per ordered pair (a, b) in E x E:
'                    <a> <b> <a+b> <a-b> <a*b> <a \ b> <a Mod b>
'                    all 16 hex; "-" for both \ and Mod when b = 0 or (a = INT64_MIN and b = -1),
'                    in which case they are not evaluated.
'   long_binary.txt  per ordered pair (a, b) in L: <a 8 hex> <b 8 hex> <a+b> <a-b> <a*b>
'                    computed in Long, 8 hex each.
' Values are printed as raw two's-complement bits via pointer casts.

Function H64(ByVal V As LongInt) As String
  Return LCase(Hex(*Cast(ULongInt Ptr, @V), 16))
End Function

Function H32(ByVal V As Long) As String
  Return LCase(Hex(*Cast(ULong Ptr, @V), 8))
End Function

Dim As LongInt E(0 To 18) = { 0, 1, -1, 2, -2, 3, -3, 7, -7, 2147483647, -2147483648, _
  4294967296, 3037000499, 3037000500, &h5555555555555555, &hAAAAAAAAAAAAAAAA, _
  9223372036854775807, &h8000000000000000, &h8000000000000001 }

Dim As Long L(0 To 12) = { 0, 1, -1, 2, -2, 7, -7, 46340, 46341, 65536, 2147483647, _
  -2147483648, -2147483647 }

Dim As LongInt A, B, N, Ab, Sum, Dif, Prod, Quo, Md
Dim As Long Sg, LA, LB, LS, LD, LP

Open "int_unary.txt" For Output As #1
For I As Long = 0 To 18
  A = E(I)
  N = -A
  Ab = Abs(A)
  Sg = Sgn(A)
  Print #1, H64(A) & " " & H64(N) & " " & H64(Ab) & " " & H32(Sg)
Next I
Close #1

Open "int_binary.txt" For Output As #1
For I As Long = 0 To 18
  For J As Long = 0 To 18
    A = E(I)
    B = E(J)
    Sum = A + B
    Dif = A - B
    Prod = A * B
    If B = 0 Or (A = &h8000000000000000 And B = -1) Then
      Print #1, H64(A) & " " & H64(B) & " " & H64(Sum) & " " & H64(Dif) & " " & H64(Prod) & " - -"
    Else
      Quo = A \ B
      Md = A Mod B
      Print #1, H64(A) & " " & H64(B) & " " & H64(Sum) & " " & H64(Dif) & " " & H64(Prod) & " " & _
        H64(Quo) & " " & H64(Md)
    End If
  Next J
Next I
Close #1

Open "long_binary.txt" For Output As #1
For I As Long = 0 To 12
  For J As Long = 0 To 12
    LA = L(I)
    LB = L(J)
    LS = LA + LB
    LD = LA - LB
    LP = LA * LB
    Print #1, H32(LA) & " " & H32(LB) & " " & H32(LS) & " " & H32(LD) & " " & H32(LP)
  Next J
Next I
Close #1
