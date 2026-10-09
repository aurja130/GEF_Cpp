' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' DATA / READ / RESTORE and Val/ValLng/ValInt and `Input #` (M3.8 golden).
' (a) DATA: three labelled blocks; the first statement is a Read before any Restore.
' (b) Val, ValLng and ValInt of a list of strings.
' (c) Input # of a binary-exact file, one single-variable statement per op.
' Usage: data_input (no arguments).
' Writes in the working directory:
'   data_first.txt     the first Read (Double, bits), before any Restore
'   data_items.txt     one line per DATA item of L1, L2, L3 in order: the item read as String,
'                      hex of its bytes, or "-" when empty
'   data_labels.txt    "L1 <index>", "L2 <index>", "L3 <index>" in the flat item list
'   data_values.txt    <index> <Single bits 8 hex> <Double bits 16 hex> <LongInt 16 hex>
'   data_chain.txt     Restore L2: 8 Double reads; Restore L3: 2 String, 2 LongInt, 2 String
'   val.txt            <hex of s or -> <Val(s) 16 hex> <ValLng(s) 16 hex> <ValInt(s) 8 hex>
'   input.txt          the input file (binary-exact)
'   input_ops.txt      one op letter per line: S Single, D Double, L LongInt, $ String
'   input_results.txt  <op index> <type> <value>: Single 8 hex, Double 16 hex, LongInt 16 hex,
'                      String hex of its bytes or "-"

Dim As Double D0, DX
Dim As Single SX
Dim As LongInt LX
Dim As String SS
Dim As Long K
Dim As Single SB(0 To 38)
Dim As Double DB(0 To 38)
Dim As LongInt LB(0 To 38)
Dim As String Content, Ops, OpC
Dim As Single VSg
Dim As Double VDb
Dim As LongInt VLn
Dim As String VSt

Function HexS(ByVal V As Single) As String
  Return LCase(Hex(*Cast(ULong Ptr, @V), 8))
End Function

Function HexD(ByVal V As Double) As String
  Return LCase(Hex(*Cast(ULongInt Ptr, @V), 16))
End Function

Function HexL(ByVal V As LongInt) As String
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

Function HexOrDash(ByVal S As String) As String
  If Len(S) = 0 Then Return "-"
  Return HexStr(S)
End Function

' One Val line for the string S.
Sub Emit(ByVal S As String)
  Dim As Double V = Val(S)
  Dim As LongInt L = ValLng(S)
  Dim As Long I = ValInt(S)
  Print #1, HexOrDash(S) & " " & HexD(V) & " " & HexL(L) & " " & LCase(Hex(*Cast(ULong Ptr, @I), 8))
End Sub

' The first statement: a Read before any Restore (fbc starts at the first DATA block).
Read D0

Open "data_first.txt" For Output As #1
Print #1, HexD(D0)
Close #1

' (a) Items as String, all 39 items of L1, L2, L3 in one run.
Open "data_items.txt" For Output As #1
Restore L1
For K = 0 To 38
  Read SS
  Print #1, HexOrDash(SS)
Next K
Close #1

Open "data_labels.txt" For Output As #1
Print #1, "L1 0"
Print #1, "L2 33"
Print #1, "L3 36"
Close #1

' Values as Single, then Double, then LongInt, each from L1.
Restore L1
For K = 0 To 38
  Read SX
  SB(K) = SX
Next K
Restore L1
For K = 0 To 38
  Read DX
  DB(K) = DX
Next K
Restore L1
For K = 0 To 38
  Read LX
  LB(K) = LX
Next K

Open "data_values.txt" For Output As #1
For K = 0 To 38
  Print #1, Str(K) & " " & HexS(SB(K)) & " " & HexD(DB(K)) & " " & HexL(LB(K))
Next K
Close #1

' Chained blocks and the end of the data.
Open "data_chain.txt" For Output As #1
Restore L2
For K = 1 To 8
  Read DX
  Print #1, HexD(DX)
Next K
Restore L3
For K = 1 To 2
  Read SS
  Print #1, HexOrDash(SS)
Next K
For K = 1 To 2
  Read LX
  Print #1, HexL(LX)
Next K
For K = 1 To 2
  Read SS
  Print #1, HexOrDash(SS)
Next K
Close #1

' (b) Val, ValLng, ValInt.
Open "val.txt" For Output As #1
Emit ""
Emit " "
Emit "1.5"
Emit "  -2.5e3"
Emit "1d2"
Emit "1D-2"
Emit "&H1F"
Emit "&h"
Emit "&O17"
Emit "&B101"
Emit "&17"
Emit "&"
Emit "0x10"
Emit "1e400"
Emit "-1e400"
Emit "nan"
Emit "inf"
Emit "1.5abc"
Emit "abc"
Emit Chr(9) & "7"
Emit "+3"
Emit "- 3"
Emit "9223372036854775807"
Emit "9223372036854775808"
Emit "18446744073709551616"
Emit "-1"
Emit "&HFFFFFFFFFFFFFFFFF"
Emit "1.999999999999999999"
Emit "0.1"
Emit "3.4028235e38"
Emit "1e-320"
Emit "4294967296"
Emit "2147483648"
Emit "  &H80000000"
Close #1

' (c) Input #: the file, built from Chr() pieces so every byte is explicit.
Content = "1.5,2.5,3e2" & Chr(13) & Chr(10)
Content = Content & "10 20 30" & Chr(9) & "40" & Chr(10)
Content = Content & "50" & Chr(13)
Content = Content & Chr(10)
Content = Content & Chr(34) & "quoted, comma" & Chr(34) & ","
Content = Content & "unquoted inner spaces" & Chr(10)
Content = Content & "ab" & Chr(34) & "cd" & ","
Content = Content & "1d2,1D-2,&H1F,&O17" & Chr(10)
Content = Content & "123456789,1234567890,123456789012345678,1234567890123456789,12345678901234567890" & Chr(10)
Content = Content & "2.5,3.5,-2.5,4.5" & Chr(10)
Content = Content & "-0,+3,.5,5." & Chr(10)
Content = Content & "&H7FFFFFFFFF,-9223372036854775808" & Chr(10)
Content = Content & "1e400,1e400," & "7   ," & "9876"

Open "input.txt" For Output As #3
Print #3, Content;
Close #3

' One op letter per token of input.txt in order (34 tokens), then 26 ops past the end.
Ops = "SDSLDS$L$$" & "$DSLDLLLLL" & "LLLLSDLSLL" & "SDLD" & "SDL$SDL$SDL$SDL$SDL$SDL$SD"

Open "input.txt" For Input As #2
Open "input_ops.txt" For Output As #4
Open "input_results.txt" For Output As #5
For K = 1 To Len(Ops)
  OpC = Mid(Ops, K, 1)
  Print #4, OpC
  Select Case OpC
  Case "S"
    VSg = 0
    Input #2, VSg
    Print #5, Str(K) & " S " & HexS(VSg)
  Case "D"
    VDb = 0
    Input #2, VDb
    Print #5, Str(K) & " D " & HexD(VDb)
  Case "L"
    VLn = 0
    Input #2, VLn
    Print #5, Str(K) & " L " & HexL(VLn)
  Case "$"
    VSt = ""
    Input #2, VSt
    Print #5, Str(K) & " $ " & HexOrDash(VSt)
  End Select
Next K
Close #2
Close #4
Close #5

End

L1: Data 1.5, -2.25, 0.1, "abc", 3, 1.E-3, 1D2, &H1F, &O17, &B101, " 7", 1e40, -1e-50, 123456789012, 9223372036854775807, -9223372036854775808, 1.2345678901234567, 3.4028235E38, 1.7976931348623157E308, 0, -0, .5, 5., "", 16777217, 0.30000000000000004, "1d2", "0x10", "&h", "nan", "-inf", "  12", "1e400"
L2: Data 10, 20, 30
L3: Data 40, "x y", 50
