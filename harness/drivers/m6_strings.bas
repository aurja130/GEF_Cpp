' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' M6.1 golden: TRIM with a pattern, RTrim, Left and Right (strings.txt), and Input #, EOF and
' Line Input on small files (hang.txt). The hang cases: `Input #f, <Double>` meets a non-number,
' and a `Do Until EOF` loop after it would never end in GEF.
' Usage: m6_strings (no arguments).
' Writes in the working directory:
'   in_<case>.bin   the input file bytes, one Put (Binary) per byte
'   strings.txt     TRIMEX <s> <pattern> <result>, RTRIM <s> <result>,
'                   LEFT <s> <n> <result> and RIGHT <s> <n> <result>, one per line
'   hang.txt        per case: INPUT <case> <Double bits> <eof> <at_end> after `Input #f, D`,
'                   then six LINE <case> <i> <eof> <at_end> <line> records, each taken before
'                   one step of `If EOF(f) = 0 Then Line Input #f, s`
' Every hex field is the bytes of the string, lower case, "-" when the string is empty; a LINE
' record whose step did not read (eof 1) has "-". eof and at_end are 1 or 0; at_end is
' Seek(f) > LOF(f). Seek counts the bytes libfb has put back as unread, so at_end equals eof
' and is not the position of the underlying file.

Dim Shared As String LF, Q

' Lower-case hex of the bytes of S; "-" for the empty string.
Function HexOf(ByVal S As String) As String
  Dim As Integer J
  Dim As String Res
  For J = 1 To Len(S)
    Res = Res & LCase(Hex(Asc(Mid(S, J, 1)), 2))
  Next J
  If Res = "" Then Res = "-"
  Return Res
End Function

' "1" for a true value (EOF returns -1), "0" otherwise.
Function Flag(ByVal B As Integer) As String
  If B <> 0 Then Return "1"
  Return "0"
End Function

' Bits of a Double, lower-case hex.
Function Bits(ByVal V As Double) As String
  Return LCase(Hex(*Cast(ULongInt Ptr, @V), 16))
End Function

' 1 when Seek(f) is past LOF(f) (Seek is 1-based and counts put-back bytes as unread).
Function AtEnd(ByVal Nf As Integer) As Integer
  If Seek(Nf) > LOF(Nf) Then Return 1
  Return 0
End Function

LF = Chr(10)
Q = Chr(34)

' (a) TRIM with a pattern, RTrim, Left and Right on fixed strings.
Dim As String SS(0 To 16), PP(0 To 8)
SS(0) = ""
SS(1) = " "
SS(2) = "ab"
SS(3) = " ab "
SS(4) = "xyabyx"
SS(5) = "xxxabxxx"
SS(6) = Q & "ab" & Q
SS(7) = Q
SS(8) = "ab" & Chr(0) & " "
SS(9) = Chr(0) & " ab "
SS(10) = "ab" & Chr(9)
SS(11) = "ababa"
SS(12) = Q & "in/e_spectrum2.dat" & Q
SS(13) = "ab" & Chr(0) & Q
SS(14) = Q & "ab" & Q & Chr(0)
SS(15) = "ab" & Chr(0) & "xx"
SS(16) = "abxx" & Chr(0)
PP(0) = Q
PP(1) = "xy"
PP(2) = "yx"
PP(3) = "xx"
PP(4) = "ab"
PP(5) = "aba"
PP(6) = " "
PP(7) = "xyabyx"
PP(8) = ""

Dim As Integer F, I, J, K, L
Dim As Integer NV(0 To 8)
F = FreeFile
Open "strings.txt" For Output As #F
For I = 0 To 16
  For J = 0 To 8
    Print #F, "TRIMEX " & HexOf(SS(I)) & " " & HexOf(PP(J)) & " " & HexOf(Trim(SS(I), PP(J)))
  Next J
Next I
For I = 0 To 16
  Print #F, "RTRIM " & HexOf(SS(I)) & " " & HexOf(RTrim(SS(I)))
Next I
For I = 0 To 16
  L = Len(SS(I))
  NV(0) = -2: NV(1) = -1: NV(2) = 0: NV(3) = 1: NV(4) = 2
  NV(5) = L - 1: NV(6) = L: NV(7) = L + 1: NV(8) = 100
  For K = 0 To 8
    Print #F, "LEFT " & HexOf(SS(I)) & " " & Str(NV(K)) & " " & HexOf(Left(SS(I), NV(K)))
  Next K
  For K = 0 To 8
    Print #F, "RIGHT " & HexOf(SS(I)) & " " & Str(NV(K)) & " " & HexOf(Right(SS(I), NV(K)))
  Next K
Next I
Close #F

' (b) Input # of a Double, then up to six steps of `If EOF(f) = 0 Then Line Input #f, s`.
Dim As String CN(0 To 4), CB(0 To 4)
CN(0) = "quote": CB(0) = "'ab" & LF & "1" & LF
CN(1) = "quote_noeol": CB(1) = "'original: x" & LF & "50" & LF & "96,247," & Q & "GS" & Q
CN(2) = "number": CB(2) = "5" & LF & "6" & LF
CN(3) = "blank_first": CB(3) = "   ' E/MeV" & LF & "  6.9  9.8" & LF
CN(4) = "number_noeol": CB(4) = "6.9  9.8"

Dim As Integer C, Ic, Eo, Ae
Dim As Double D
Dim As String Txt, Ct
Dim As UByte Byt
Open "hang.txt" For Output As #F
For C = 0 To 4
  Ct = CB(C)
  ' Binary Open does not truncate, so truncate first; then one Put per byte. #7 and #8 are
  ' free: F (hang.txt) holds the number FreeFile gave.
  Open "in_" & CN(C) & ".bin" For Output As #7
  Close #7
  Open "in_" & CN(C) & ".bin" For Binary As #7
  For K = 1 To Len(Ct)
    Byt = Asc(Mid(Ct, K, 1))
    Put #7, , Byt
  Next K
  Close #7
  Open "in_" & CN(C) & ".bin" For Input As #8
  D = 0
  Input #8, D
  Print #F, "INPUT " & CN(C) & " " & Bits(D) & " " & Flag(EOF(8)) & " " & Flag(AtEnd(8))
  For Ic = 1 To 6
    Eo = EOF(8)
    Ae = AtEnd(8)
    Txt = ""
    If Eo = 0 Then Line Input #8, Txt
    Print #F, "LINE " & CN(C) & " " & Str(Ic) & " " & Flag(Eo) & " " & Flag(Ae) & " " & HexOf(Txt)
  Next Ic
  Close #8
Next C
Close #F
End
