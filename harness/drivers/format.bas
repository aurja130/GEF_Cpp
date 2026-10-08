' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Format$ check (M3.6b golden). Numeric values and date serials are formatted with the masks
' GEF uses plus a set of edge-case masks. One line per call: value bits, mask hex, result hex.
' Usage: format (no arguments).
' Writes format.txt in the working directory.

#Include "vbcompat.bi"

Dim Shared As Integer Fh

Function Bits(ByVal d As Double) As String
    Return Hex(*Cast(LongInt Ptr, @d), 16)
End Function

Function HexStr(ByVal s As String) As String
    Dim As String r = ""
    For k As Integer = 1 To Len(s)
        r &= Hex(Asc(Mid(s, k, 1)), 2)
    Next k
    Return r
End Function

' Skips the two combinations that hit runtime hazards (see format.cpp notes).
Sub Emit(ByVal d As Double, ByVal p As String)
    Dim As Integer isExp = (InStr(p, "E") > 0)
    Dim As Integer isNan = (d <> d)
    Dim As Integer isInf = (Not isNan) And (Abs(d) > 1.7976931348623157e308)
    If isExp And isInf Then Return
    If (Not isExp) And (Not isNan) And (Not isInf) And (Abs(d) >= 1e19) Then Return
    Print #Fh, Bits(d); " "; HexStr(p); " "; HexStr(Format(d, p))
End Sub

Sub Feed(ByVal d As Double)
    Emit d, "-0.00000E+00"
    Emit d, "-0.000000E+0"
    Emit d, "#####"
    Emit d, "0"
    Emit d, "0.00"
    Emit d, "#.##"
    Emit d, "#,##0.00"
    Emit d, "0.###E+0"
    Emit d, "0.0E-00"
    Emit d, ""
    Emit d, "0%"
End Sub

Sub SetBits(ByRef d As Double, ByVal b As LongInt)
    *Cast(LongInt Ptr, @d) = b
End Sub

Dim As Double z = 0, nz, v, nan, pinf, ninf, dmin, dmax
Dim As Double sers(0 To 13)
Dim As Double ser
Dim As String dp = "dd.mm.yyyy, hh:mm:ss"

nz = -z
SetBits nan, &H7FF8000000000000
SetBits pinf, &H7FF0000000000000
SetBits ninf, &HFFF0000000000000
SetBits dmin, &H0000000000000001
dmax = 1.7976931348623157e308

sers(0) = 0.0 : sers(1) = 1.0 : sers(2) = 2.0 : sers(3) = 59.0 : sers(4) = 60.0
sers(5) = 61.0 : sers(6) = 36526.0 : sers(7) = 45000.5 : sers(8) = 45000.999988425926
sers(9) = 45000.99999999 : sers(10) = 47000.25 : sers(11) = -1.0 : sers(12) = -365.75
sers(13) = 2958465.0

Open "format.txt" For Output As #1
Fh = 1

Feed z
Feed nz
Feed 0.5
Feed 1.5
Feed 2.5
Feed 0.05
Feed 0.005
Feed 9.99999
Feed 0.1
Feed 1
Feed 10
Feed 1e-300
Feed 1e-10
Feed 1e-5
Feed 123.456
Feed 99999.5
Feed 1e15
Feed 1e20
Feed 1e300
Feed -1.5
Feed -123.456
Feed dmax
Feed dmin
Feed nan
Feed ninf
Feed pinf

Randomize 1234
For n As Integer = 1 To 2000
    v = (Rnd - 0.5) * 10 ^ Int(Rnd * 40 - 20)
    Emit v, "-0.00000E+00"
    Emit v, "-0.000000E+0"
    Emit v, "#####"
Next n

For n As Integer = 0 To 13
    ser = sers(n)
    Print #Fh, Bits(ser); " "; HexStr(dp); " "; HexStr(Format(ser, dp))
Next n

For n As Integer = 1 To 1000
    ser = Rnd * 80000
    Print #Fh, Bits(ser); " "; HexStr(dp); " "; HexStr(Format(ser, dp))
Next n

Close #1
