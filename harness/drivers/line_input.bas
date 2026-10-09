' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' M4.4 golden: Line Input / EOF on files, Trim / UCase / InStr / Mid, and GEF's ConvTab,
' CC_Count and CC_Cut (utilities.bi).
' Usage: line_input (no arguments).
' Writes in the working directory:
'   in_<case>.bin       the input file bytes, written with Put (Binary)
'   lines_<case>.txt    one line per Line Input: <index> <Len> <hex of the line or ->
'   strings.txt         TRIM/UCASE/INSTR/INSTRS/MID2/MID3 results, one per line
'   utilities.txt       CONVTAB, COUNT, CUT (COut of 10 elements), CUTS (COut of 3 elements)
' The "<E> Dimension of COut too small" lines go to stdout.
' Every hex field is the bytes of the string, lower case, "-" when the string is empty.

'@include-source utilities.bi

#include "utilities.bi"

Dim Shared As String CR, LF
CR = Chr(13)
LF = Chr(10)

Dim Shared As String TS(0 To 31)
Dim Shared As Integer NT
Dim Shared As String PS(0 To 63), PP(0 To 63)
Dim Shared As Integer NP
Dim Shared As String CCI(0 To 31), CCD(0 To 31)
Dim Shared As Integer NCC

Function HexOf(ByVal S As String) As String
  Dim As Integer J
  Dim As String Res
  If Len(S) = 0 Then
    Return "-"
  End If
  Res = ""
  For J = 1 To Len(S)
    Res = Res & LCase(Hex(Asc(Mid(S, J, 1)), 2))
  Next J
  Return Res
End Function

Sub AddPair(ByVal S As String, ByVal P As String)
  PS(NP) = S
  PP(NP) = P
  NP = NP + 1
End Sub

Sub AddCut(ByVal S As String, ByVal D As String)
  CCI(NCC) = S
  CCD(NCC) = D
  NCC = NCC + 1
End Sub

Sub EmitCase(ByVal CaseName As String, ByVal Content As String)
  Dim As Integer K
  Dim As String S
  Open "in_" & CaseName & ".bin" For Binary As #1
  Put #1, , Content
  Close #1
  Open "in_" & CaseName & ".bin" For Input As #2
  Open "lines_" & CaseName & ".txt" For Output As #3
  K = 0
  Do While Not EOF(2)
    K = K + 1
    Line Input #2, S
    Print #3, Str(K) & " " & Str(Len(S)) & " " & HexOf(S)
  Loop
  Close #2
  Close #3
End Sub

Dim As Integer I, J, K, NC, N10, N3
Dim As String S, CI, CD
Dim As String CA(0 To 9), CB(0 To 2)
Dim As String MS(0 To 4), MS3(0 To 2)
Dim As Integer Starts(0 To 8), MStarts(0 To 8)
Dim As Integer M3Lens(0 To 7), M3Starts(0 To 5)

' (a) Line Input and EOF, one case per file.
EmitCase "empty", ""
EmitCase "lf", "alpha" & LF & "beta" & LF
EmitCase "crlf", "alpha" & CR & LF & "beta" & CR & LF
EmitCase "lone_cr", "one" & CR & "two" & LF & "three" & CR & LF
EmitCase "cr_eof", "abc" & CR
EmitCase "no_final_lf", "x" & LF & "y"
EmitCase "blank", LF & CR & LF & LF & "a" & LF
EmitCase "nul_mid", "a" & Chr(0) & "b" & LF & Chr(0) & LF & "c" & Chr(0)
EmitCase "nul_only", Chr(0)
EmitCase "cr_nul_eof", "AAA" & CR & Chr(0)
EmitCase "nul511", "A" & String(510, 0) & "B" & LF
EmitCase "cr511", String(510, "B") & CR & LF & "tail" & LF
EmitCase "lf510", String(510, "A") & LF
EmitCase "crlf510", String(510, "A") & CR & LF
EmitCase "lf511", String(511, "A") & LF
EmitCase "crlf511", String(511, "A") & CR & LF
EmitCase "lf512", String(512, "A") & LF
EmitCase "crlf512", String(512, "A") & CR & LF
EmitCase "lf1022", String(1022, "A") & LF
EmitCase "crlf1022", String(1022, "A") & CR & LF
EmitCase "lf1023", String(1023, "A") & LF
EmitCase "crlf1023", String(1023, "A") & CR & LF

' (b) Trim and UCase inputs.
TS(0) = ""
TS(1) = " "
TS(2) = "  "
TS(3) = "a"
TS(4) = " a "
TS(5) = Chr(9) & "a" & Chr(9)
TS(6) = Chr(9)
TS(7) = "a b"
TS(8) = " a  b "
TS(9) = Chr(0) & " x"
TS(10) = " " & Chr(0) & " "
TS(11) = "abc" & Chr(0) & " "
TS(12) = Chr(200) & "x" & Chr(255) & " "
TS(13) = "azAZ{}[`@"
TS(14) = "abcxyz"
TS(15) = "ABCXYZ"
TS(16) = Chr(224) & Chr(181) & "q"
TS(17) = "hello world 123"
TS(18) = " " & LF & " "
TS(19) = "-1.5e3 "
NT = 20

' (c) InStr pairs.
AddPair "", "a"
AddPair "abc", ""
AddPair "", ""
AddPair "abc", "abc"
AddPair "abcabc", "bc"
AddPair "aaaa", "aa"
AddPair "abc", "abcd"
AddPair "abc", "c"
AddPair "abc", "z"
AddPair "a" & Chr(9) & "b", Chr(9)
AddPair "ab" & Chr(200) & "xy", Chr(200) & "x"
AddPair "xyz" & Chr(255), Chr(255)
AddPair "abcab", "cab"
AddPair "aabaacaab", "aab"
AddPair "ABC", "abc"
AddPair "hello world", "o w"
AddPair "GCATCGCAGAGAGTATACAGTACG", "GCAGAGAG"
AddPair "abababab", "baba"
AddPair "aaaaab", "aaab"
AddPair "xabcxabcy", "xabcy"
AddPair "a" & Chr(0) & "b", Chr(0) & "b"
AddPair "abc", "abc" & Chr(0)
AddPair "mississippi", "issi"
AddPair "mississippi", "ssippi"
AddPair "mississippi", "pi"
AddPair "ab", "b"
AddPair String(60, "z") & "y", "zzy"

Starts(0) = -1 : Starts(1) = 0 : Starts(2) = 1 : Starts(3) = 2 : Starts(4) = 3
Starts(5) = 5 : Starts(6) = 8 : Starts(7) = 12 : Starts(8) = 30

Open "strings.txt" For Output As #9
For I = 0 To NT - 1
  S = TS(I)
  Print #9, "TRIM " & HexOf(S) & " " & HexOf(Trim(S))
  Print #9, "UCASE " & HexOf(S) & " " & HexOf(UCase(S))
Next I
For I = 0 To NP - 1
  Print #9, "INSTR " & HexOf(PS(I)) & " " & HexOf(PP(I)) & " " & Str(InStr(PS(I), PP(I)))
  For J = 0 To 8
    Print #9, "INSTRS " & Str(Starts(J)) & " " & HexOf(PS(I)) & " " & HexOf(PP(I)) & " " & Str(InStr(Starts(J), PS(I), PP(I)))
  Next J
Next I

' Mid(s, start) on a few strings.
MS(0) = ""
MS(1) = "abc"
MS(2) = Chr(0) & "a"
MS(3) = " x "
MS(4) = "hello"
MStarts(0) = -5 : MStarts(1) = -1 : MStarts(2) = 0 : MStarts(3) = 1 : MStarts(4) = 2
MStarts(5) = 3 : MStarts(6) = 5 : MStarts(7) = 6 : MStarts(8) = 100
For I = 0 To 4
  For J = 0 To 8
    S = MS(I)
    Print #9, "MID2 " & HexOf(S) & " " & Str(MStarts(J)) & " " & HexOf(Mid(S, MStarts(J)))
  Next J
Next I

' Mid(s, start, len) (a negative len means to the end).
MS3(0) = "abcdef"
MS3(1) = ""
MS3(2) = "a" & Chr(0) & "b"
M3Starts(0) = -1 : M3Starts(1) = 0 : M3Starts(2) = 1 : M3Starts(3) = 3 : M3Starts(4) = 6 : M3Starts(5) = 7
M3Lens(0) = -2 : M3Lens(1) = -1 : M3Lens(2) = 0 : M3Lens(3) = 1
M3Lens(4) = 2 : M3Lens(5) = 3 : M3Lens(6) = 10 : M3Lens(7) = 2147483647
For I = 0 To 2
  For J = 0 To 5
    For K = 0 To 7
      S = MS3(I)
      Print #9, "MID3 " & HexOf(S) & " " & Str(M3Starts(J)) & " " & Str(M3Lens(K)) & " " & HexOf(Mid(S, M3Starts(J), M3Lens(K)))
    Next K
  Next J
Next I
Close #9

' (d) ConvTab, CC_Count and CC_Cut. CA has 10 elements; CB has 3 (overflow cases).
AddCut "a = 1", "="
AddCut "a=", "="
AddCut "=1", "="
AddCut "x==1", "="
AddCut " a  =  b ", "="
AddCut "a" & Chr(9) & "=" & Chr(9) & "b", "="
AddCut Chr(9) & "a = 1", "="
AddCut "a = 1 ", " "
AddCut "a   b", " "
AddCut "  abc  ", "="
AddCut "", "="
AddCut "   ", "="
AddCut "a=b=", "="
AddCut "a=b", ""
AddCut "a=b=c=d", "="
AddCut "  a=b=c=d  ", "="
AddCut "a=b=c", "="
AddCut "a=b", "="
AddCut Chr(0) & "=x", "="
AddCut "a" & Chr(9) & "b", Chr(9)
AddCut "x, y ,", ","

Open "utilities.txt" For Output As #8
Print #8, "CONVTAB " & HexOf("") & " " & HexOf(ConvTab(""))
Print #8, "CONVTAB " & HexOf("a" & Chr(9) & "b") & " " & HexOf(ConvTab("a" & Chr(9) & "b"))
Print #8, "CONVTAB " & HexOf(Chr(9) & Chr(9)) & " " & HexOf(ConvTab(Chr(9) & Chr(9)))
Print #8, "CONVTAB " & HexOf(" " & Chr(9) & " ") & " " & HexOf(ConvTab(" " & Chr(9) & " "))
Print #8, "CONVTAB " & HexOf("no tab") & " " & HexOf(ConvTab("no tab"))

For I = 0 To NCC - 1
  CI = CCI(I)
  CD = CCD(I)
  NC = CC_Count(CI, CD)
  Print #8, "COUNT " & HexOf(CI) & " " & HexOf(CD) & " " & Str(NC)
  CC_Cut(CI, CD, CA(), N10)
  S = "CUT " & HexOf(CI) & " " & HexOf(CD) & " " & Str(N10)
  For K = 1 To N10
    S = S & " " & HexOf(CA(K))
  Next K
  Print #8, S
  CC_Cut(CI, CD, CB(), N3)
  S = "CUTS " & HexOf(CI) & " " & HexOf(CD) & " " & Str(N3)
  For K = 1 To N3
    S = S & " " & HexOf(CB(K))
  Next K
  Print #8, S
Next I
Close #8

End
