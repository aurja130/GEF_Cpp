' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Dynamic array semantics (M3.7 golden): ReDim, ReDim Preserve, Erase, LBound/UBound and the
' GEF growth helpers Extend_1dim/2dim/3dim (utilities.bi) on Double arrays of rank 1 to 3 and
' a String array of rank 1. The operations come from the Data statements below; each one is
' echoed to ops.txt as its own line (the Data text), and after each one a state line is written.
' Usage: arrays (no arguments).
' Writes in the working directory:
'   ops.txt    one line per operation: the Data text
'   state.txt  one line per operation, the state after it:
'              <op index> <array> L0=<LBound 0> U0=<UBound 0> L-1=<l>,U-1=<u> L1=.. U1=.. ... |<elements>
'              Double elements are the 16 lowercase hex digits of their bits, each preceded by a
'              space, in row-major order. A String element is its bytes in hex, each element
'              preceded by a space. Double arrays of more than 4096 elements are not written in
'              full: " #<count> <hash>" follows the bar, where hash is FNV-1a over the 64-bit
'              patterns of the elements in row-major order.
'   The Double element of a fill is seed * 100000 + k (k counts from 0 in row-major order).

'@include-source utilities.bi

#include "utilities.bi"

Const F_OPS = 1
Const F_STATE = 2
Const BIG = 4096

Dim Shared A1() As Double
Dim Shared A2(Any, Any) As Double
Dim Shared A3(Any, Any, Any) As Double
Dim Shared S1() As String

Function Hex16(ByVal V As Double) As String
  Return LCase(Hex(*Cast(ULongInt Ptr, @V), 16))
End Function

Function HexStr(ByVal S As String) As String
  Dim As String R
  Dim As Long J
  For J = 1 To Len(S)
    R = R & LCase(Hex(Asc(Mid(S, J, 1)), 2))
  Next J
  Return R
End Function

Function NextTok(ByVal S As String, ByRef P As Long) As String
  Dim As Long Q
  Do While P <= Len(S) AndAlso Mid(S, P, 1) = " "
    P += 1
  Loop
  Q = P
  Do While P <= Len(S) AndAlso Mid(S, P, 1) <> " "
    P += 1
  Loop
  Return Mid(S, Q, P - Q)
End Function

Sub Dump1(ByVal Idx As Long)
  Dim As LongInt Cnt = UBound(A1, 1) - LBound(A1, 1) + 1
  Dim As String Elems = ""
  Dim As ULongInt H = &hCBF29CE484222325ULL
  Dim As ULongInt B
  Dim As Double V
  For I As Long = LBound(A1, 1) To UBound(A1, 1)
    V = A1(I)
    B = *Cast(ULongInt Ptr, @V)
    H = (H Xor B) * &h100000001B3ULL
    If Cnt <= BIG Then Elems = Elems & " " & Hex16(V)
  Next I
  If Cnt > BIG Then Elems = " #" & Str(Cnt) & " " & LCase(Hex(H, 16))
  Print #F_STATE, Str(Idx) & " A1 L0=" & LBound(A1, 0) & " U0=" & UBound(A1, 0) & _
    " L-1=" & LBound(A1, -1) & ",U-1=" & UBound(A1, -1) & _
    " L1=" & LBound(A1, 1) & ",U1=" & UBound(A1, 1) & _
    " L2=" & LBound(A1, 2) & ",U2=" & UBound(A1, 2) & " |" & Elems
End Sub

Sub Dump2(ByVal Idx As Long)
  Dim As LongInt Cnt = (UBound(A2, 1) - LBound(A2, 1) + 1) * (UBound(A2, 2) - LBound(A2, 2) + 1)
  Dim As String Elems = ""
  Dim As ULongInt H = &hCBF29CE484222325ULL
  Dim As ULongInt B
  Dim As Double V
  For I As Long = LBound(A2, 1) To UBound(A2, 1)
    For J As Long = LBound(A2, 2) To UBound(A2, 2)
      V = A2(I, J)
      B = *Cast(ULongInt Ptr, @V)
      H = (H Xor B) * &h100000001B3ULL
      If Cnt <= BIG Then Elems = Elems & " " & Hex16(V)
    Next J
  Next I
  If Cnt > BIG Then Elems = " #" & Str(Cnt) & " " & LCase(Hex(H, 16))
  Print #F_STATE, Str(Idx) & " A2 L0=" & LBound(A2, 0) & " U0=" & UBound(A2, 0) & _
    " L-1=" & LBound(A2, -1) & ",U-1=" & UBound(A2, -1) & _
    " L1=" & LBound(A2, 1) & ",U1=" & UBound(A2, 1) & _
    " L2=" & LBound(A2, 2) & ",U2=" & UBound(A2, 2) & _
    " L3=" & LBound(A2, 3) & ",U3=" & UBound(A2, 3) & " |" & Elems
End Sub

Sub Dump3(ByVal Idx As Long)
  Dim As LongInt Cnt = (UBound(A3, 1) - LBound(A3, 1) + 1) * (UBound(A3, 2) - LBound(A3, 2) + 1) * (UBound(A3, 3) - LBound(A3, 3) + 1)
  Dim As String Elems = ""
  Dim As ULongInt H = &hCBF29CE484222325ULL
  Dim As ULongInt B
  Dim As Double V
  For I As Long = LBound(A3, 1) To UBound(A3, 1)
    For J As Long = LBound(A3, 2) To UBound(A3, 2)
      For KK As Long = LBound(A3, 3) To UBound(A3, 3)
        V = A3(I, J, KK)
        B = *Cast(ULongInt Ptr, @V)
        H = (H Xor B) * &h100000001B3ULL
        If Cnt <= BIG Then Elems = Elems & " " & Hex16(V)
      Next KK
    Next J
  Next I
  If Cnt > BIG Then Elems = " #" & Str(Cnt) & " " & LCase(Hex(H, 16))
  Print #F_STATE, Str(Idx) & " A3 L0=" & LBound(A3, 0) & " U0=" & UBound(A3, 0) & _
    " L-1=" & LBound(A3, -1) & ",U-1=" & UBound(A3, -1) & _
    " L1=" & LBound(A3, 1) & ",U1=" & UBound(A3, 1) & _
    " L2=" & LBound(A3, 2) & ",U2=" & UBound(A3, 2) & _
    " L3=" & LBound(A3, 3) & ",U3=" & UBound(A3, 3) & _
    " L4=" & LBound(A3, 4) & ",U4=" & UBound(A3, 4) & " |" & Elems
End Sub

Sub DumpS1(ByVal Idx As Long)
  Dim As String Elems = ""
  For I As Long = LBound(S1, 1) To UBound(S1, 1)
    Elems = Elems & " " & HexStr(S1(I))
  Next I
  Print #F_STATE, Str(Idx) & " S1 L0=" & LBound(S1, 0) & " U0=" & UBound(S1, 0) & _
    " L-1=" & LBound(S1, -1) & ",U-1=" & UBound(S1, -1) & _
    " L1=" & LBound(S1, 1) & ",U1=" & UBound(S1, 1) & _
    " L2=" & LBound(S1, 2) & ",U2=" & UBound(S1, 2) & " |" & Elems
End Sub

Dim As Long Idx = 0
Dim As String Ln, Op, Arr, T
Dim As Long P, NumArgs, Nn(1 To 8)
Dim As LongInt K

Open "ops.txt" For Output As #F_OPS
Open "state.txt" For Output As #F_STATE

Do
  Read Ln
  If Ln = "end" Then Exit Do
  Idx += 1
  Print #F_OPS, Ln
  P = 1
  Op = NextTok(Ln, P)
  Arr = NextTok(Ln, P)
  NumArgs = 0
  Do
    T = NextTok(Ln, P)
    If T = "" Then Exit Do
    NumArgs += 1
    Nn(NumArgs) = CLng(Val(T))
  Loop

  Select Case Op
  Case "dump"
    ' state only
  Case "redim"
    Select Case Arr
    Case "A1"
      ReDim A1(Nn(1) To Nn(2))
    Case "A2"
      ReDim A2(Nn(1) To Nn(2), Nn(3) To Nn(4))
    Case "A3"
      ReDim A3(Nn(1) To Nn(2), Nn(3) To Nn(4), Nn(5) To Nn(6))
    Case "S1"
      ReDim S1(Nn(1) To Nn(2))
    End Select
  Case "preserve"
    Select Case Arr
    Case "A1"
      ReDim Preserve A1(Nn(1) To Nn(2))
    Case "A2"
      ReDim Preserve A2(Nn(1) To Nn(2), Nn(3) To Nn(4))
    Case "A3"
      ReDim Preserve A3(Nn(1) To Nn(2), Nn(3) To Nn(4), Nn(5) To Nn(6))
    Case "S1"
      ReDim Preserve S1(Nn(1) To Nn(2))
    End Select
  Case "erase"
    Select Case Arr
    Case "A1"
      Erase A1
    Case "A2"
      Erase A2
    Case "A3"
      Erase A3
    Case "S1"
      Erase S1
    End Select
  Case "extend"
    Select Case Arr
    Case "A1"
      Extend_1dim(A1(), Nn(1), Nn(2))
    Case "A2"
      Extend_2dim(A2(), Nn(1), Nn(2), Nn(3), Nn(4))
    Case "A3"
      Extend_3dim(A3(), Nn(1), Nn(2), Nn(3), Nn(4), Nn(5), Nn(6))
    End Select
  Case "fill"
    K = 0
    Select Case Arr
    Case "A1"
      For I As Long = LBound(A1, 1) To UBound(A1, 1)
        A1(I) = CDbl(Nn(1)) * 100000 + K
        K += 1
      Next I
    Case "A2"
      For I As Long = LBound(A2, 1) To UBound(A2, 1)
        For J As Long = LBound(A2, 2) To UBound(A2, 2)
          A2(I, J) = CDbl(Nn(1)) * 100000 + K
          K += 1
        Next J
      Next I
    Case "A3"
      For I As Long = LBound(A3, 1) To UBound(A3, 1)
        For J As Long = LBound(A3, 2) To UBound(A3, 2)
          For L As Long = LBound(A3, 3) To UBound(A3, 3)
            A3(I, J, L) = CDbl(Nn(1)) * 100000 + K
            K += 1
          Next L
        Next J
      Next I
    Case "S1"
      For I As Long = LBound(S1, 1) To UBound(S1, 1)
        S1(I) = "s" & Str(CLngInt(Nn(1)) * 100000 + K)
        K += 1
      Next I
    End Select
  End Select

  Select Case Arr
  Case "A1"
    Dump1(Idx)
  Case "A2"
    Dump2(Idx)
  Case "A3"
    Dump3(Idx)
  Case "S1"
    DumpS1(Idx)
  End Select
Loop

Close #F_OPS
Close #F_STATE

' Operations: <op> <array> <numbers...>
Data "dump A1"
Data "redim A1 1 5"
Data "fill A1 1"
Data "preserve A1 1 8"
Data "preserve A1 1 3"
Data "preserve A1 -2 3"
Data "erase A1"
Data "preserve A1 4 6"
Data "fill A1 2"
Data "redim A1 7 2"
Data "redim A1 0 3"
Data "fill A1 3"
Data "preserve A1 5 1"
Data "extend A1 2 10"
Data "extend A1 -4 0"
Data "erase A1"
Data "extend A1 5 9"
Data "extend A1 16777215 16777219"
Data "extend A1 -16777219 -16777215"
Data "dump A2"
Data "redim A2 0 2 1 3"
Data "fill A2 1"
Data "preserve A2 0 3 1 3"
Data "preserve A2 0 2 1 4"
Data "preserve A2 1 2 0 1"
Data "extend A2 -1 4 0 5"
Data "erase A2"
Data "extend A2 2 3 4 5"
Data "redim A2 3 1 0 1"
Data "dump A3"
Data "redim A3 0 1 0 2 0 3"
Data "fill A3 1"
Data "preserve A3 0 1 0 2 0 4"
Data "preserve A3 0 2 0 1 0 3"
Data "extend A3 -1 2 -1 2 -1 2"
Data "erase A3"
Data "extend A3 1 2 1 2 1 2"
Data "dump S1"
Data "redim S1 0 3"
Data "fill S1 1"
Data "preserve S1 0 5"
Data "preserve S1 0 1"
Data "erase S1"
Data "preserve S1 2 4"
Data "fill S1 2"
Data "end"
