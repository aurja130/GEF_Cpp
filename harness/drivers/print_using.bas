' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Print Using check (M3.6b golden). Every template of GEF's Print Using statements, and the
' generic templates of the runtime's own cases (signs, exponents, $$, **, commas, _ escapes,
' & ! and \ \ fields, each with a grid of
' values: Single, Double, LongInt and String items, including NaN, indefinite, infinities,
' signed zero and denormals (given as bit patterns).
' Not generated: more items than fields (fbc then reads freed memory), and empty strings in
' ! and \ \ fields (also undefined in fbc). Empty strings in & fields are fine.
' Usage: print_using (no arguments).
' Writes templates.txt (hex of each template), calls.txt (one line per statement: template
' index, item count, then each item's type and value bytes in hex) and print_using.txt (the
' output of every statement, raw bytes, as libfb writes them).

Function HexBytes(s As String) As String
    Dim As String r = ""
    Dim As Integer i
    For i = 1 To Len(s)
        r = r & Right("0" & Hex(Asc(Mid(s, i, 1))), 2)
    Next
    Return r
End Function

Function BHex(s As String) As String
    Return HexBytes(s)
End Function

Function SngBits(b As UInteger) As Single
    Return *Cast(Single Ptr, @b)
End Function

Function DblBits(b As ULongInt) As Double
    Return *Cast(Double Ptr, @b)
End Function

Function SHex(x As Single) As String
    Dim As UInteger u = *Cast(UInteger Ptr, @x)
    Return Right("00000000" & Hex(u), 8)
End Function

Function DHex(x As Double) As String
    Dim As ULongInt u = *Cast(ULongInt Ptr, @x)
    Return Right("0000000000000000" & Hex(u), 16)
End Function

Function LHex(x As LongInt) As String
    Dim As ULongInt u = *Cast(ULongInt Ptr, @x)
    Return Right("0000000000000000" & Hex(u), 16)
End Function

Dim Shared As String tpl(0 To 81)
Dim Shared As Single sg1, sg2, sg3, sg4, sg5, sg6, sg7, sg8
Dim Shared As Double db1, db2, db3, db4, db5, db6, db7, db8
Dim Shared As LongInt li1, li2, li3, li4, li5, li6, li7, li8
Dim Shared As String st1, st2, st3, st4, st5, st6, st7, st8

Dim As Integer i
For i = 0 To 81
    Read tpl(i)
Next
Open "templates.txt" For Output As #3
For i = 0 To 81
    Print #3, HexBytes(tpl(i))
Next
Close #3
Open "calls.txt" For Output As #2
Open "print_using.txt" For Output As #1
' 0 template 0
sg1 = 0
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 1 template 0
sg1 = SngBits(&h80000000)
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 2 template 0
sg1 = 0.5!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 3 template 0
sg1 = -0.5!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 4 template 0
sg1 = 0.05!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 5 template 0
sg1 = 0.005!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 6 template 0
sg1 = 0.0005!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 7 template 0
sg1 = 0.15!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 8 template 0
sg1 = 0.25!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 9 template 0
sg1 = 0.35!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 10 template 0
sg1 = 0.45!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 11 template 0
sg1 = 1!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 12 template 0
sg1 = -1!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 13 template 0
sg1 = 1.5!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 14 template 0
sg1 = 2.5!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 15 template 0
sg1 = 9.995!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 16 template 0
sg1 = 10!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 17 template 0
sg1 = 99.995!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 18 template 0
sg1 = 99.9999!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 19 template 0
sg1 = 123.456!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 20 template 0
sg1 = -123.456!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 21 template 0
sg1 = 999.95!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 22 template 0
sg1 = 1234.5678!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 23 template 0
sg1 = 12345.678!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 24 template 0
sg1 = 99999.9!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 25 template 0
sg1 = 0.1!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 26 template 0
sg1 = 0.00001!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 27 template 0
sg1 = 0.000000123!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 28 template 0
sg1 = 0.0000000001!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 29 template 0
sg1 = 100000!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 30 template 0
sg1 = 10000000000!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 31 template 0
sg1 = 9999999999999999!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 32 template 0
sg1 = 1E+17!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 33 template 0
sg1 = 1E+20!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 34 template 0
sg1 = 1E+30!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 35 template 0
sg1 = -2.5E-30!
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 36 template 0
sg1 = SngBits(&h7FC00000)
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 37 template 0
sg1 = SngBits(&hFFC00000)
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 38 template 0
sg1 = SngBits(&h7F800000)
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 39 template 0
sg1 = SngBits(&hFF800000)
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 40 template 0
sg1 = SngBits(&h1)
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 41 template 0
sg1 = SngBits(&h80000001)
Print #2, "0 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(0); sg1
' 42 template 0
db1 = 0#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 43 template 0
db1 = DblBits(&h8000000000000000ULL)
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 44 template 0
db1 = 0.5#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 45 template 0
db1 = -0.5#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 46 template 0
db1 = 0.05#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 47 template 0
db1 = 0.005#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 48 template 0
db1 = 0.0005#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 49 template 0
db1 = 0.15#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 50 template 0
db1 = 0.25#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 51 template 0
db1 = 0.35#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 52 template 0
db1 = 0.45#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 53 template 0
db1 = 1#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 54 template 0
db1 = -1#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 55 template 0
db1 = 1.5#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 56 template 0
db1 = 2.5#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 57 template 0
db1 = 9.995#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 58 template 0
db1 = 10#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 59 template 0
db1 = 99.995#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 60 template 0
db1 = 99.9999#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 61 template 0
db1 = 123.456#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 62 template 0
db1 = -123.456#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 63 template 0
db1 = 999.95#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 64 template 0
db1 = 1234.5678#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 65 template 0
db1 = 12345.678#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 66 template 0
db1 = 99999.9#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 67 template 0
db1 = 0.1#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 68 template 0
db1 = 0.00001#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 69 template 0
db1 = 0.000000123#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 70 template 0
db1 = 0.0000000001#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 71 template 0
db1 = 100000#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 72 template 0
db1 = 10000000000#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 73 template 0
db1 = 9999999999999999#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 74 template 0
db1 = 1E+17#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 75 template 0
db1 = 1E+20#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 76 template 0
db1 = 1E+30#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 77 template 0
db1 = -2.5E-30#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 78 template 0
db1 = 1E+300#
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 79 template 0
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 80 template 0
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 81 template 0
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 82 template 0
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 83 template 0
db1 = DblBits(&h1ULL)
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 84 template 0
db1 = DblBits(&h8000000000000001ULL)
Print #2, "0 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(0); db1
' 85 template 1
sg1 = 0
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 86 template 1
sg1 = SngBits(&h80000000)
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 87 template 1
sg1 = 0.5!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 88 template 1
sg1 = -0.5!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 89 template 1
sg1 = 0.05!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 90 template 1
sg1 = 0.005!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 91 template 1
sg1 = 0.0005!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 92 template 1
sg1 = 0.15!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 93 template 1
sg1 = 0.25!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 94 template 1
sg1 = 0.35!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 95 template 1
sg1 = 0.45!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 96 template 1
sg1 = 1!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 97 template 1
sg1 = -1!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 98 template 1
sg1 = 1.5!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 99 template 1
sg1 = 2.5!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 100 template 1
sg1 = 9.995!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 101 template 1
sg1 = 10!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 102 template 1
sg1 = 99.995!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 103 template 1
sg1 = 99.9999!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 104 template 1
sg1 = 123.456!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 105 template 1
sg1 = -123.456!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 106 template 1
sg1 = 999.95!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 107 template 1
sg1 = 1234.5678!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 108 template 1
sg1 = 12345.678!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 109 template 1
sg1 = 99999.9!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 110 template 1
sg1 = 0.1!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 111 template 1
sg1 = 0.00001!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 112 template 1
sg1 = 0.000000123!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 113 template 1
sg1 = 0.0000000001!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 114 template 1
sg1 = 100000!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 115 template 1
sg1 = 10000000000!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 116 template 1
sg1 = 9999999999999999!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 117 template 1
sg1 = 1E+17!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 118 template 1
sg1 = 1E+20!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 119 template 1
sg1 = 1E+30!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 120 template 1
sg1 = -2.5E-30!
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 121 template 1
sg1 = SngBits(&h7FC00000)
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 122 template 1
sg1 = SngBits(&hFFC00000)
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 123 template 1
sg1 = SngBits(&h7F800000)
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 124 template 1
sg1 = SngBits(&hFF800000)
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 125 template 1
sg1 = SngBits(&h1)
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 126 template 1
sg1 = SngBits(&h80000001)
Print #2, "1 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(1); sg1
' 127 template 1
db1 = 0#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 128 template 1
db1 = DblBits(&h8000000000000000ULL)
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 129 template 1
db1 = 0.5#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 130 template 1
db1 = -0.5#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 131 template 1
db1 = 0.05#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 132 template 1
db1 = 0.005#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 133 template 1
db1 = 0.0005#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 134 template 1
db1 = 0.15#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 135 template 1
db1 = 0.25#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 136 template 1
db1 = 0.35#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 137 template 1
db1 = 0.45#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 138 template 1
db1 = 1#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 139 template 1
db1 = -1#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 140 template 1
db1 = 1.5#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 141 template 1
db1 = 2.5#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 142 template 1
db1 = 9.995#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 143 template 1
db1 = 10#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 144 template 1
db1 = 99.995#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 145 template 1
db1 = 99.9999#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 146 template 1
db1 = 123.456#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 147 template 1
db1 = -123.456#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 148 template 1
db1 = 999.95#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 149 template 1
db1 = 1234.5678#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 150 template 1
db1 = 12345.678#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 151 template 1
db1 = 99999.9#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 152 template 1
db1 = 0.1#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 153 template 1
db1 = 0.00001#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 154 template 1
db1 = 0.000000123#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 155 template 1
db1 = 0.0000000001#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 156 template 1
db1 = 100000#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 157 template 1
db1 = 10000000000#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 158 template 1
db1 = 9999999999999999#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 159 template 1
db1 = 1E+17#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 160 template 1
db1 = 1E+20#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 161 template 1
db1 = 1E+30#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 162 template 1
db1 = -2.5E-30#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 163 template 1
db1 = 1E+300#
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 164 template 1
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 165 template 1
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 166 template 1
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 167 template 1
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 168 template 1
db1 = DblBits(&h1ULL)
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 169 template 1
db1 = DblBits(&h8000000000000001ULL)
Print #2, "1 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(1); db1
' 170 template 2
st1 = ""
sg2 = 0.005!
st3 = "abc"
sg4 = 9.995!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 171 template 2
st1 = "A"
sg2 = 0.0005!
st3 = "exactly14chars"
sg4 = 10!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 172 template 2
st1 = "abc"
sg2 = 0.15!
st3 = "a string longer than any field"
sg4 = 99.995!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 173 template 2
st1 = "exactly14chars"
sg2 = 0.25!
st3 = " lead"
sg4 = 99.9999!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 174 template 2
st1 = "a string longer than any field"
sg2 = 0.35!
st3 = "12345678901234567890"
sg4 = 123.456!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 175 template 2
st1 = " lead"
sg2 = 0.45!
st3 = "x y"
sg4 = -123.456!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 176 template 2
st1 = "12345678901234567890"
sg2 = 1!
st3 = ""
sg4 = 999.95!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 177 template 2
st1 = "x y"
sg2 = -1!
st3 = "A"
sg4 = 1234.5678!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 178 template 2
st1 = ""
sg2 = 1.5!
st3 = "abc"
sg4 = 12345.678!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 179 template 2
st1 = "A"
sg2 = 2.5!
st3 = "exactly14chars"
sg4 = 99999.9!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 180 template 2
st1 = "abc"
sg2 = 9.995!
st3 = "a string longer than any field"
sg4 = 0.1!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 181 template 2
st1 = "exactly14chars"
sg2 = 10!
st3 = " lead"
sg4 = 0.00001!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 182 template 2
st1 = "a string longer than any field"
sg2 = 99.995!
st3 = "12345678901234567890"
sg4 = 0.000000123!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 183 template 2
st1 = " lead"
sg2 = 99.9999!
st3 = "x y"
sg4 = 0.0000000001!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 184 template 2
st1 = "12345678901234567890"
sg2 = 123.456!
st3 = ""
sg4 = 100000!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 185 template 2
st1 = "x y"
sg2 = -123.456!
st3 = "A"
sg4 = 10000000000!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 186 template 2
st1 = ""
sg2 = 999.95!
st3 = "abc"
sg4 = 9999999999999999!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 187 template 2
st1 = "A"
sg2 = 1234.5678!
st3 = "exactly14chars"
sg4 = 1E+17!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 188 template 2
st1 = "abc"
sg2 = 12345.678!
st3 = "a string longer than any field"
sg4 = 1E+20!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 189 template 2
st1 = "exactly14chars"
sg2 = 99999.9!
st3 = " lead"
sg4 = 1E+30!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 190 template 2
st1 = "a string longer than any field"
sg2 = 0.1!
st3 = "12345678901234567890"
sg4 = -2.5E-30!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 191 template 2
st1 = " lead"
sg2 = 0.00001!
st3 = "x y"
sg4 = SngBits(&h7FC00000)
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 192 template 2
st1 = "12345678901234567890"
sg2 = 0.000000123!
st3 = ""
sg4 = SngBits(&hFFC00000)
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 193 template 2
st1 = "x y"
sg2 = 0.0000000001!
st3 = "A"
sg4 = SngBits(&h7F800000)
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 194 template 2
st1 = ""
sg2 = 100000!
st3 = "abc"
sg4 = SngBits(&hFF800000)
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 195 template 2
st1 = "A"
sg2 = 10000000000!
st3 = "exactly14chars"
sg4 = SngBits(&h1)
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 196 template 2
st1 = "abc"
sg2 = 9999999999999999!
st3 = "a string longer than any field"
sg4 = SngBits(&h80000001)
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 197 template 2
st1 = "exactly14chars"
sg2 = 1E+17!
st3 = " lead"
sg4 = 0
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 198 template 2
st1 = "a string longer than any field"
sg2 = 1E+20!
st3 = "12345678901234567890"
sg4 = SngBits(&h80000000)
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 199 template 2
st1 = " lead"
sg2 = 1E+30!
st3 = "x y"
sg4 = 0.5!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 200 template 2
st1 = "12345678901234567890"
sg2 = -2.5E-30!
st3 = ""
sg4 = -0.5!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 201 template 2
st1 = "x y"
sg2 = SngBits(&h7FC00000)
st3 = "A"
sg4 = 0.05!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 202 template 2
st1 = ""
sg2 = SngBits(&hFFC00000)
st3 = "abc"
sg4 = 0.005!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 203 template 2
st1 = "A"
sg2 = SngBits(&h7F800000)
st3 = "exactly14chars"
sg4 = 0.0005!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 204 template 2
st1 = "abc"
sg2 = SngBits(&hFF800000)
st3 = "a string longer than any field"
sg4 = 0.15!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 205 template 2
st1 = "exactly14chars"
sg2 = SngBits(&h1)
st3 = " lead"
sg4 = 0.25!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 206 template 2
st1 = "a string longer than any field"
sg2 = SngBits(&h80000001)
st3 = "12345678901234567890"
sg4 = 0.35!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 207 template 2
st1 = " lead"
sg2 = 0
st3 = "x y"
sg4 = 0.45!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 208 template 2
st1 = "12345678901234567890"
sg2 = SngBits(&h80000000)
st3 = ""
sg4 = 1!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 209 template 2
st1 = "x y"
sg2 = 0.5!
st3 = "A"
sg4 = -1!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 210 template 2
st1 = ""
sg2 = -0.5!
st3 = "abc"
sg4 = 1.5!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 211 template 2
st1 = "A"
sg2 = 0.05!
st3 = "exactly14chars"
sg4 = 2.5!
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(2); st1; sg2; st3; sg4
' 212 template 2
st1 = ""
li2 = 12345
st3 = "abc"
li4 = -100
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 213 template 2
st1 = "A"
li2 = 99999
st3 = "exactly14chars"
li4 = 5
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 214 template 2
st1 = "abc"
li2 = 100000
st3 = "a string longer than any field"
li4 = 10
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 215 template 2
st1 = "exactly14chars"
li2 = 999999999
st3 = " lead"
li4 = 0
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 216 template 2
st1 = "a string longer than any field"
li2 = -2147483648
st3 = "12345678901234567890"
li4 = 1
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 217 template 2
st1 = " lead"
li2 = 2147483647
st3 = "x y"
li4 = -1
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 218 template 2
st1 = "12345678901234567890"
li2 = 9223372036854775807
st3 = ""
li4 = 42
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 219 template 2
st1 = "x y"
li2 = (-9223372036854775807 - 1)
st3 = "A"
li4 = -7
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 220 template 2
st1 = ""
li2 = 1000000
st3 = "abc"
li4 = 12345
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 221 template 2
st1 = "A"
li2 = 123456789012
st3 = "exactly14chars"
li4 = 99999
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 222 template 2
st1 = "abc"
li2 = -100
st3 = "a string longer than any field"
li4 = 100000
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 223 template 2
st1 = "exactly14chars"
li2 = 5
st3 = " lead"
li4 = 999999999
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 224 template 2
st1 = "a string longer than any field"
li2 = 10
st3 = "12345678901234567890"
li4 = -2147483648
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 225 template 2
st1 = " lead"
li2 = 0
st3 = "x y"
li4 = 2147483647
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 226 template 2
st1 = "12345678901234567890"
li2 = 1
st3 = ""
li4 = 9223372036854775807
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 227 template 2
st1 = "x y"
li2 = -1
st3 = "A"
li4 = (-9223372036854775807 - 1)
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 228 template 2
st1 = ""
li2 = 42
st3 = "abc"
li4 = 1000000
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 229 template 2
st1 = "A"
li2 = -7
st3 = "exactly14chars"
li4 = 123456789012
Print #2, "2 4" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2) & " " & "s:" & BHex(st3) & " " & "l:" & LHex(li4)
Print #1, Using tpl(2); st1; li2; st3; li4
' 230 template 3
sg1 = 0
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 231 template 3
sg1 = SngBits(&h80000000)
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 232 template 3
sg1 = 0.5!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 233 template 3
sg1 = -0.5!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 234 template 3
sg1 = 0.05!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 235 template 3
sg1 = 0.005!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 236 template 3
sg1 = 0.0005!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 237 template 3
sg1 = 0.15!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 238 template 3
sg1 = 0.25!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 239 template 3
sg1 = 0.35!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 240 template 3
sg1 = 0.45!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 241 template 3
sg1 = 1!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 242 template 3
sg1 = -1!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 243 template 3
sg1 = 1.5!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 244 template 3
sg1 = 2.5!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 245 template 3
sg1 = 9.995!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 246 template 3
sg1 = 10!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 247 template 3
sg1 = 99.995!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 248 template 3
sg1 = 99.9999!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 249 template 3
sg1 = 123.456!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 250 template 3
sg1 = -123.456!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 251 template 3
sg1 = 999.95!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 252 template 3
sg1 = 1234.5678!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 253 template 3
sg1 = 12345.678!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 254 template 3
sg1 = 99999.9!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 255 template 3
sg1 = 0.1!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 256 template 3
sg1 = 0.00001!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 257 template 3
sg1 = 0.000000123!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 258 template 3
sg1 = 0.0000000001!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 259 template 3
sg1 = 100000!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 260 template 3
sg1 = 10000000000!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 261 template 3
sg1 = 9999999999999999!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 262 template 3
sg1 = 1E+17!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 263 template 3
sg1 = 1E+20!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 264 template 3
sg1 = 1E+30!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 265 template 3
sg1 = -2.5E-30!
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 266 template 3
sg1 = SngBits(&h7FC00000)
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 267 template 3
sg1 = SngBits(&hFFC00000)
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 268 template 3
sg1 = SngBits(&h7F800000)
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 269 template 3
sg1 = SngBits(&hFF800000)
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 270 template 3
sg1 = SngBits(&h1)
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 271 template 3
sg1 = SngBits(&h80000001)
Print #2, "3 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(3); sg1
' 272 template 3
li1 = 0
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 273 template 3
li1 = 1
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 274 template 3
li1 = -1
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 275 template 3
li1 = 42
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 276 template 3
li1 = -7
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 277 template 3
li1 = 12345
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 278 template 3
li1 = 99999
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 279 template 3
li1 = 100000
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 280 template 3
li1 = 999999999
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 281 template 3
li1 = -2147483648
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 282 template 3
li1 = 2147483647
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 283 template 3
li1 = 9223372036854775807
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 284 template 3
li1 = (-9223372036854775807 - 1)
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 285 template 3
li1 = 1000000
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 286 template 3
li1 = 123456789012
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 287 template 3
li1 = -100
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 288 template 3
li1 = 5
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 289 template 3
li1 = 10
Print #2, "3 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(3); li1
' 290 template 4
sg1 = 0
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 291 template 4
sg1 = SngBits(&h80000000)
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 292 template 4
sg1 = 0.5!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 293 template 4
sg1 = -0.5!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 294 template 4
sg1 = 0.05!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 295 template 4
sg1 = 0.005!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 296 template 4
sg1 = 0.0005!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 297 template 4
sg1 = 0.15!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 298 template 4
sg1 = 0.25!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 299 template 4
sg1 = 0.35!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 300 template 4
sg1 = 0.45!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 301 template 4
sg1 = 1!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 302 template 4
sg1 = -1!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 303 template 4
sg1 = 1.5!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 304 template 4
sg1 = 2.5!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 305 template 4
sg1 = 9.995!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 306 template 4
sg1 = 10!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 307 template 4
sg1 = 99.995!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 308 template 4
sg1 = 99.9999!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 309 template 4
sg1 = 123.456!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 310 template 4
sg1 = -123.456!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 311 template 4
sg1 = 999.95!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 312 template 4
sg1 = 1234.5678!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 313 template 4
sg1 = 12345.678!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 314 template 4
sg1 = 99999.9!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 315 template 4
sg1 = 0.1!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 316 template 4
sg1 = 0.00001!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 317 template 4
sg1 = 0.000000123!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 318 template 4
sg1 = 0.0000000001!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 319 template 4
sg1 = 100000!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 320 template 4
sg1 = 10000000000!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 321 template 4
sg1 = 9999999999999999!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 322 template 4
sg1 = 1E+17!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 323 template 4
sg1 = 1E+20!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 324 template 4
sg1 = 1E+30!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 325 template 4
sg1 = -2.5E-30!
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 326 template 4
sg1 = SngBits(&h7FC00000)
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 327 template 4
sg1 = SngBits(&hFFC00000)
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 328 template 4
sg1 = SngBits(&h7F800000)
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 329 template 4
sg1 = SngBits(&hFF800000)
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 330 template 4
sg1 = SngBits(&h1)
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 331 template 4
sg1 = SngBits(&h80000001)
Print #2, "4 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(4); sg1
' 332 template 4
li1 = 0
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 333 template 4
li1 = 1
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 334 template 4
li1 = -1
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 335 template 4
li1 = 42
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 336 template 4
li1 = -7
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 337 template 4
li1 = 12345
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 338 template 4
li1 = 99999
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 339 template 4
li1 = 100000
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 340 template 4
li1 = 999999999
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 341 template 4
li1 = -2147483648
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 342 template 4
li1 = 2147483647
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 343 template 4
li1 = 9223372036854775807
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 344 template 4
li1 = (-9223372036854775807 - 1)
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 345 template 4
li1 = 1000000
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 346 template 4
li1 = 123456789012
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 347 template 4
li1 = -100
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 348 template 4
li1 = 5
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 349 template 4
li1 = 10
Print #2, "4 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(4); li1
' 350 template 5
sg1 = 0
sg2 = 0.005!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 351 template 5
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 352 template 5
sg1 = 0.5!
sg2 = 0.15!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 353 template 5
sg1 = -0.5!
sg2 = 0.25!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 354 template 5
sg1 = 0.05!
sg2 = 0.35!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 355 template 5
sg1 = 0.005!
sg2 = 0.45!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 356 template 5
sg1 = 0.0005!
sg2 = 1!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 357 template 5
sg1 = 0.15!
sg2 = -1!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 358 template 5
sg1 = 0.25!
sg2 = 1.5!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 359 template 5
sg1 = 0.35!
sg2 = 2.5!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 360 template 5
sg1 = 0.45!
sg2 = 9.995!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 361 template 5
sg1 = 1!
sg2 = 10!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 362 template 5
sg1 = -1!
sg2 = 99.995!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 363 template 5
sg1 = 1.5!
sg2 = 99.9999!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 364 template 5
sg1 = 2.5!
sg2 = 123.456!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 365 template 5
sg1 = 9.995!
sg2 = -123.456!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 366 template 5
sg1 = 10!
sg2 = 999.95!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 367 template 5
sg1 = 99.995!
sg2 = 1234.5678!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 368 template 5
sg1 = 99.9999!
sg2 = 12345.678!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 369 template 5
sg1 = 123.456!
sg2 = 99999.9!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 370 template 5
sg1 = -123.456!
sg2 = 0.1!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 371 template 5
sg1 = 999.95!
sg2 = 0.00001!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 372 template 5
sg1 = 1234.5678!
sg2 = 0.000000123!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 373 template 5
sg1 = 12345.678!
sg2 = 0.0000000001!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 374 template 5
sg1 = 99999.9!
sg2 = 100000!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 375 template 5
sg1 = 0.1!
sg2 = 10000000000!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 376 template 5
sg1 = 0.00001!
sg2 = 9999999999999999!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 377 template 5
sg1 = 0.000000123!
sg2 = 1E+17!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 378 template 5
sg1 = 0.0000000001!
sg2 = 1E+20!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 379 template 5
sg1 = 100000!
sg2 = 1E+30!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 380 template 5
sg1 = 10000000000!
sg2 = -2.5E-30!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 381 template 5
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 382 template 5
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 383 template 5
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 384 template 5
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 385 template 5
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 386 template 5
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 387 template 5
sg1 = SngBits(&hFFC00000)
sg2 = 0
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 388 template 5
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 389 template 5
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 390 template 5
sg1 = SngBits(&h1)
sg2 = -0.5!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 391 template 5
sg1 = SngBits(&h80000001)
sg2 = 0.05!
Print #2, "5 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(5); sg1; sg2
' 392 template 5
db1 = 0#
db2 = 0.005#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 393 template 5
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 394 template 5
db1 = 0.5#
db2 = 0.15#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 395 template 5
db1 = -0.5#
db2 = 0.25#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 396 template 5
db1 = 0.05#
db2 = 0.35#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 397 template 5
db1 = 0.005#
db2 = 0.45#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 398 template 5
db1 = 0.0005#
db2 = 1#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 399 template 5
db1 = 0.15#
db2 = -1#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 400 template 5
db1 = 0.25#
db2 = 1.5#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 401 template 5
db1 = 0.35#
db2 = 2.5#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 402 template 5
db1 = 0.45#
db2 = 9.995#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 403 template 5
db1 = 1#
db2 = 10#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 404 template 5
db1 = -1#
db2 = 99.995#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 405 template 5
db1 = 1.5#
db2 = 99.9999#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 406 template 5
db1 = 2.5#
db2 = 123.456#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 407 template 5
db1 = 9.995#
db2 = -123.456#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 408 template 5
db1 = 10#
db2 = 999.95#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 409 template 5
db1 = 99.995#
db2 = 1234.5678#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 410 template 5
db1 = 99.9999#
db2 = 12345.678#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 411 template 5
db1 = 123.456#
db2 = 99999.9#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 412 template 5
db1 = -123.456#
db2 = 0.1#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 413 template 5
db1 = 999.95#
db2 = 0.00001#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 414 template 5
db1 = 1234.5678#
db2 = 0.000000123#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 415 template 5
db1 = 12345.678#
db2 = 0.0000000001#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 416 template 5
db1 = 99999.9#
db2 = 100000#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 417 template 5
db1 = 0.1#
db2 = 10000000000#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 418 template 5
db1 = 0.00001#
db2 = 9999999999999999#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 419 template 5
db1 = 0.000000123#
db2 = 1E+17#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 420 template 5
db1 = 0.0000000001#
db2 = 1E+20#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 421 template 5
db1 = 100000#
db2 = 1E+30#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 422 template 5
db1 = 10000000000#
db2 = -2.5E-30#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 423 template 5
db1 = 9999999999999999#
db2 = 1E+300#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 424 template 5
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 425 template 5
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 426 template 5
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 427 template 5
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 428 template 5
db1 = 1E+300#
db2 = DblBits(&h1ULL)
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 429 template 5
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 430 template 5
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 431 template 5
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 432 template 5
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 433 template 5
db1 = DblBits(&h1ULL)
db2 = -0.5#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 434 template 5
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
Print #2, "5 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(5); db1; db2
' 435 template 6
sg1 = 0
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 436 template 6
sg1 = SngBits(&h80000000)
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 437 template 6
sg1 = 0.5!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 438 template 6
sg1 = -0.5!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 439 template 6
sg1 = 0.05!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 440 template 6
sg1 = 0.005!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 441 template 6
sg1 = 0.0005!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 442 template 6
sg1 = 0.15!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 443 template 6
sg1 = 0.25!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 444 template 6
sg1 = 0.35!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 445 template 6
sg1 = 0.45!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 446 template 6
sg1 = 1!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 447 template 6
sg1 = -1!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 448 template 6
sg1 = 1.5!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 449 template 6
sg1 = 2.5!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 450 template 6
sg1 = 9.995!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 451 template 6
sg1 = 10!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 452 template 6
sg1 = 99.995!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 453 template 6
sg1 = 99.9999!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 454 template 6
sg1 = 123.456!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 455 template 6
sg1 = -123.456!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 456 template 6
sg1 = 999.95!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 457 template 6
sg1 = 1234.5678!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 458 template 6
sg1 = 12345.678!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 459 template 6
sg1 = 99999.9!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 460 template 6
sg1 = 0.1!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 461 template 6
sg1 = 0.00001!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 462 template 6
sg1 = 0.000000123!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 463 template 6
sg1 = 0.0000000001!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 464 template 6
sg1 = 100000!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 465 template 6
sg1 = 10000000000!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 466 template 6
sg1 = 9999999999999999!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 467 template 6
sg1 = 1E+17!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 468 template 6
sg1 = 1E+20!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 469 template 6
sg1 = 1E+30!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 470 template 6
sg1 = -2.5E-30!
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 471 template 6
sg1 = SngBits(&h7FC00000)
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 472 template 6
sg1 = SngBits(&hFFC00000)
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 473 template 6
sg1 = SngBits(&h7F800000)
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 474 template 6
sg1 = SngBits(&hFF800000)
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 475 template 6
sg1 = SngBits(&h1)
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 476 template 6
sg1 = SngBits(&h80000001)
Print #2, "6 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(6); sg1
' 477 template 6
li1 = 0
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 478 template 6
li1 = 1
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 479 template 6
li1 = -1
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 480 template 6
li1 = 42
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 481 template 6
li1 = -7
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 482 template 6
li1 = 12345
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 483 template 6
li1 = 99999
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 484 template 6
li1 = 100000
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 485 template 6
li1 = 999999999
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 486 template 6
li1 = -2147483648
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 487 template 6
li1 = 2147483647
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 488 template 6
li1 = 9223372036854775807
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 489 template 6
li1 = (-9223372036854775807 - 1)
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 490 template 6
li1 = 1000000
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 491 template 6
li1 = 123456789012
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 492 template 6
li1 = -100
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 493 template 6
li1 = 5
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 494 template 6
li1 = 10
Print #2, "6 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(6); li1
' 495 template 7
sg1 = 0
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 496 template 7
sg1 = SngBits(&h80000000)
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 497 template 7
sg1 = 0.5!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 498 template 7
sg1 = -0.5!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 499 template 7
sg1 = 0.05!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 500 template 7
sg1 = 0.005!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 501 template 7
sg1 = 0.0005!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 502 template 7
sg1 = 0.15!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 503 template 7
sg1 = 0.25!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 504 template 7
sg1 = 0.35!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 505 template 7
sg1 = 0.45!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 506 template 7
sg1 = 1!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 507 template 7
sg1 = -1!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 508 template 7
sg1 = 1.5!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 509 template 7
sg1 = 2.5!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 510 template 7
sg1 = 9.995!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 511 template 7
sg1 = 10!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 512 template 7
sg1 = 99.995!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 513 template 7
sg1 = 99.9999!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 514 template 7
sg1 = 123.456!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 515 template 7
sg1 = -123.456!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 516 template 7
sg1 = 999.95!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 517 template 7
sg1 = 1234.5678!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 518 template 7
sg1 = 12345.678!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 519 template 7
sg1 = 99999.9!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 520 template 7
sg1 = 0.1!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 521 template 7
sg1 = 0.00001!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 522 template 7
sg1 = 0.000000123!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 523 template 7
sg1 = 0.0000000001!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 524 template 7
sg1 = 100000!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 525 template 7
sg1 = 10000000000!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 526 template 7
sg1 = 9999999999999999!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 527 template 7
sg1 = 1E+17!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 528 template 7
sg1 = 1E+20!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 529 template 7
sg1 = 1E+30!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 530 template 7
sg1 = -2.5E-30!
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 531 template 7
sg1 = SngBits(&h7FC00000)
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 532 template 7
sg1 = SngBits(&hFFC00000)
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 533 template 7
sg1 = SngBits(&h7F800000)
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 534 template 7
sg1 = SngBits(&hFF800000)
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 535 template 7
sg1 = SngBits(&h1)
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 536 template 7
sg1 = SngBits(&h80000001)
Print #2, "7 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(7); sg1
' 537 template 7
db1 = 0#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 538 template 7
db1 = DblBits(&h8000000000000000ULL)
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 539 template 7
db1 = 0.5#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 540 template 7
db1 = -0.5#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 541 template 7
db1 = 0.05#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 542 template 7
db1 = 0.005#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 543 template 7
db1 = 0.0005#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 544 template 7
db1 = 0.15#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 545 template 7
db1 = 0.25#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 546 template 7
db1 = 0.35#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 547 template 7
db1 = 0.45#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 548 template 7
db1 = 1#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 549 template 7
db1 = -1#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 550 template 7
db1 = 1.5#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 551 template 7
db1 = 2.5#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 552 template 7
db1 = 9.995#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 553 template 7
db1 = 10#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 554 template 7
db1 = 99.995#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 555 template 7
db1 = 99.9999#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 556 template 7
db1 = 123.456#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 557 template 7
db1 = -123.456#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 558 template 7
db1 = 999.95#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 559 template 7
db1 = 1234.5678#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 560 template 7
db1 = 12345.678#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 561 template 7
db1 = 99999.9#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 562 template 7
db1 = 0.1#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 563 template 7
db1 = 0.00001#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 564 template 7
db1 = 0.000000123#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 565 template 7
db1 = 0.0000000001#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 566 template 7
db1 = 100000#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 567 template 7
db1 = 10000000000#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 568 template 7
db1 = 9999999999999999#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 569 template 7
db1 = 1E+17#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 570 template 7
db1 = 1E+20#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 571 template 7
db1 = 1E+30#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 572 template 7
db1 = -2.5E-30#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 573 template 7
db1 = 1E+300#
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 574 template 7
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 575 template 7
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 576 template 7
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 577 template 7
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 578 template 7
db1 = DblBits(&h1ULL)
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 579 template 7
db1 = DblBits(&h8000000000000001ULL)
Print #2, "7 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(7); db1
' 580 template 8
sg1 = 0
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 581 template 8
sg1 = SngBits(&h80000000)
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 582 template 8
sg1 = 0.5!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 583 template 8
sg1 = -0.5!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 584 template 8
sg1 = 0.05!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 585 template 8
sg1 = 0.005!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 586 template 8
sg1 = 0.0005!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 587 template 8
sg1 = 0.15!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 588 template 8
sg1 = 0.25!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 589 template 8
sg1 = 0.35!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 590 template 8
sg1 = 0.45!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 591 template 8
sg1 = 1!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 592 template 8
sg1 = -1!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 593 template 8
sg1 = 1.5!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 594 template 8
sg1 = 2.5!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 595 template 8
sg1 = 9.995!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 596 template 8
sg1 = 10!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 597 template 8
sg1 = 99.995!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 598 template 8
sg1 = 99.9999!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 599 template 8
sg1 = 123.456!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 600 template 8
sg1 = -123.456!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 601 template 8
sg1 = 999.95!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 602 template 8
sg1 = 1234.5678!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 603 template 8
sg1 = 12345.678!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 604 template 8
sg1 = 99999.9!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 605 template 8
sg1 = 0.1!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 606 template 8
sg1 = 0.00001!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 607 template 8
sg1 = 0.000000123!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 608 template 8
sg1 = 0.0000000001!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 609 template 8
sg1 = 100000!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 610 template 8
sg1 = 10000000000!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 611 template 8
sg1 = 9999999999999999!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 612 template 8
sg1 = 1E+17!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 613 template 8
sg1 = 1E+20!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 614 template 8
sg1 = 1E+30!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 615 template 8
sg1 = -2.5E-30!
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 616 template 8
sg1 = SngBits(&h7FC00000)
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 617 template 8
sg1 = SngBits(&hFFC00000)
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 618 template 8
sg1 = SngBits(&h7F800000)
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 619 template 8
sg1 = SngBits(&hFF800000)
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 620 template 8
sg1 = SngBits(&h1)
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 621 template 8
sg1 = SngBits(&h80000001)
Print #2, "8 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(8); sg1
' 622 template 8
db1 = 0#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 623 template 8
db1 = DblBits(&h8000000000000000ULL)
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 624 template 8
db1 = 0.5#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 625 template 8
db1 = -0.5#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 626 template 8
db1 = 0.05#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 627 template 8
db1 = 0.005#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 628 template 8
db1 = 0.0005#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 629 template 8
db1 = 0.15#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 630 template 8
db1 = 0.25#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 631 template 8
db1 = 0.35#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 632 template 8
db1 = 0.45#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 633 template 8
db1 = 1#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 634 template 8
db1 = -1#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 635 template 8
db1 = 1.5#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 636 template 8
db1 = 2.5#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 637 template 8
db1 = 9.995#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 638 template 8
db1 = 10#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 639 template 8
db1 = 99.995#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 640 template 8
db1 = 99.9999#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 641 template 8
db1 = 123.456#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 642 template 8
db1 = -123.456#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 643 template 8
db1 = 999.95#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 644 template 8
db1 = 1234.5678#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 645 template 8
db1 = 12345.678#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 646 template 8
db1 = 99999.9#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 647 template 8
db1 = 0.1#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 648 template 8
db1 = 0.00001#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 649 template 8
db1 = 0.000000123#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 650 template 8
db1 = 0.0000000001#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 651 template 8
db1 = 100000#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 652 template 8
db1 = 10000000000#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 653 template 8
db1 = 9999999999999999#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 654 template 8
db1 = 1E+17#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 655 template 8
db1 = 1E+20#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 656 template 8
db1 = 1E+30#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 657 template 8
db1 = -2.5E-30#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 658 template 8
db1 = 1E+300#
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 659 template 8
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 660 template 8
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 661 template 8
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 662 template 8
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 663 template 8
db1 = DblBits(&h1ULL)
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 664 template 8
db1 = DblBits(&h8000000000000001ULL)
Print #2, "8 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(8); db1
' 665 template 9
sg1 = 0
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 666 template 9
sg1 = SngBits(&h80000000)
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 667 template 9
sg1 = 0.5!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 668 template 9
sg1 = -0.5!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 669 template 9
sg1 = 0.05!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 670 template 9
sg1 = 0.005!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 671 template 9
sg1 = 0.0005!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 672 template 9
sg1 = 0.15!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 673 template 9
sg1 = 0.25!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 674 template 9
sg1 = 0.35!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 675 template 9
sg1 = 0.45!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 676 template 9
sg1 = 1!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 677 template 9
sg1 = -1!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 678 template 9
sg1 = 1.5!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 679 template 9
sg1 = 2.5!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 680 template 9
sg1 = 9.995!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 681 template 9
sg1 = 10!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 682 template 9
sg1 = 99.995!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 683 template 9
sg1 = 99.9999!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 684 template 9
sg1 = 123.456!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 685 template 9
sg1 = -123.456!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 686 template 9
sg1 = 999.95!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 687 template 9
sg1 = 1234.5678!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 688 template 9
sg1 = 12345.678!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 689 template 9
sg1 = 99999.9!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 690 template 9
sg1 = 0.1!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 691 template 9
sg1 = 0.00001!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 692 template 9
sg1 = 0.000000123!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 693 template 9
sg1 = 0.0000000001!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 694 template 9
sg1 = 100000!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 695 template 9
sg1 = 10000000000!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 696 template 9
sg1 = 9999999999999999!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 697 template 9
sg1 = 1E+17!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 698 template 9
sg1 = 1E+20!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 699 template 9
sg1 = 1E+30!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 700 template 9
sg1 = -2.5E-30!
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 701 template 9
sg1 = SngBits(&h7FC00000)
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 702 template 9
sg1 = SngBits(&hFFC00000)
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 703 template 9
sg1 = SngBits(&h7F800000)
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 704 template 9
sg1 = SngBits(&hFF800000)
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 705 template 9
sg1 = SngBits(&h1)
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 706 template 9
sg1 = SngBits(&h80000001)
Print #2, "9 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(9); sg1
' 707 template 9
li1 = 0
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 708 template 9
li1 = 1
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 709 template 9
li1 = -1
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 710 template 9
li1 = 42
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 711 template 9
li1 = -7
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 712 template 9
li1 = 12345
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 713 template 9
li1 = 99999
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 714 template 9
li1 = 100000
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 715 template 9
li1 = 999999999
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 716 template 9
li1 = -2147483648
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 717 template 9
li1 = 2147483647
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 718 template 9
li1 = 9223372036854775807
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 719 template 9
li1 = (-9223372036854775807 - 1)
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 720 template 9
li1 = 1000000
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 721 template 9
li1 = 123456789012
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 722 template 9
li1 = -100
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 723 template 9
li1 = 5
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 724 template 9
li1 = 10
Print #2, "9 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(9); li1
' 725 template 10
sg1 = 0
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 726 template 10
sg1 = SngBits(&h80000000)
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 727 template 10
sg1 = 0.5!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 728 template 10
sg1 = -0.5!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 729 template 10
sg1 = 0.05!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 730 template 10
sg1 = 0.005!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 731 template 10
sg1 = 0.0005!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 732 template 10
sg1 = 0.15!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 733 template 10
sg1 = 0.25!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 734 template 10
sg1 = 0.35!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 735 template 10
sg1 = 0.45!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 736 template 10
sg1 = 1!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 737 template 10
sg1 = -1!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 738 template 10
sg1 = 1.5!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 739 template 10
sg1 = 2.5!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 740 template 10
sg1 = 9.995!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 741 template 10
sg1 = 10!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 742 template 10
sg1 = 99.995!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 743 template 10
sg1 = 99.9999!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 744 template 10
sg1 = 123.456!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 745 template 10
sg1 = -123.456!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 746 template 10
sg1 = 999.95!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 747 template 10
sg1 = 1234.5678!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 748 template 10
sg1 = 12345.678!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 749 template 10
sg1 = 99999.9!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 750 template 10
sg1 = 0.1!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 751 template 10
sg1 = 0.00001!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 752 template 10
sg1 = 0.000000123!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 753 template 10
sg1 = 0.0000000001!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 754 template 10
sg1 = 100000!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 755 template 10
sg1 = 10000000000!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 756 template 10
sg1 = 9999999999999999!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 757 template 10
sg1 = 1E+17!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 758 template 10
sg1 = 1E+20!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 759 template 10
sg1 = 1E+30!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 760 template 10
sg1 = -2.5E-30!
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 761 template 10
sg1 = SngBits(&h7FC00000)
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 762 template 10
sg1 = SngBits(&hFFC00000)
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 763 template 10
sg1 = SngBits(&h7F800000)
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 764 template 10
sg1 = SngBits(&hFF800000)
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 765 template 10
sg1 = SngBits(&h1)
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 766 template 10
sg1 = SngBits(&h80000001)
Print #2, "10 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(10); sg1
' 767 template 10
db1 = 0#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 768 template 10
db1 = DblBits(&h8000000000000000ULL)
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 769 template 10
db1 = 0.5#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 770 template 10
db1 = -0.5#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 771 template 10
db1 = 0.05#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 772 template 10
db1 = 0.005#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 773 template 10
db1 = 0.0005#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 774 template 10
db1 = 0.15#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 775 template 10
db1 = 0.25#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 776 template 10
db1 = 0.35#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 777 template 10
db1 = 0.45#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 778 template 10
db1 = 1#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 779 template 10
db1 = -1#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 780 template 10
db1 = 1.5#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 781 template 10
db1 = 2.5#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 782 template 10
db1 = 9.995#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 783 template 10
db1 = 10#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 784 template 10
db1 = 99.995#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 785 template 10
db1 = 99.9999#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 786 template 10
db1 = 123.456#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 787 template 10
db1 = -123.456#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 788 template 10
db1 = 999.95#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 789 template 10
db1 = 1234.5678#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 790 template 10
db1 = 12345.678#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 791 template 10
db1 = 99999.9#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 792 template 10
db1 = 0.1#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 793 template 10
db1 = 0.00001#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 794 template 10
db1 = 0.000000123#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 795 template 10
db1 = 0.0000000001#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 796 template 10
db1 = 100000#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 797 template 10
db1 = 10000000000#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 798 template 10
db1 = 9999999999999999#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 799 template 10
db1 = 1E+17#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 800 template 10
db1 = 1E+20#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 801 template 10
db1 = 1E+30#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 802 template 10
db1 = -2.5E-30#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 803 template 10
db1 = 1E+300#
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 804 template 10
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 805 template 10
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 806 template 10
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 807 template 10
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 808 template 10
db1 = DblBits(&h1ULL)
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 809 template 10
db1 = DblBits(&h8000000000000001ULL)
Print #2, "10 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(10); db1
' 810 template 11
sg1 = 0
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 811 template 11
sg1 = SngBits(&h80000000)
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 812 template 11
sg1 = 0.5!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 813 template 11
sg1 = -0.5!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 814 template 11
sg1 = 0.05!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 815 template 11
sg1 = 0.005!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 816 template 11
sg1 = 0.0005!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 817 template 11
sg1 = 0.15!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 818 template 11
sg1 = 0.25!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 819 template 11
sg1 = 0.35!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 820 template 11
sg1 = 0.45!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 821 template 11
sg1 = 1!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 822 template 11
sg1 = -1!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 823 template 11
sg1 = 1.5!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 824 template 11
sg1 = 2.5!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 825 template 11
sg1 = 9.995!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 826 template 11
sg1 = 10!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 827 template 11
sg1 = 99.995!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 828 template 11
sg1 = 99.9999!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 829 template 11
sg1 = 123.456!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 830 template 11
sg1 = -123.456!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 831 template 11
sg1 = 999.95!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 832 template 11
sg1 = 1234.5678!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 833 template 11
sg1 = 12345.678!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 834 template 11
sg1 = 99999.9!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 835 template 11
sg1 = 0.1!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 836 template 11
sg1 = 0.00001!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 837 template 11
sg1 = 0.000000123!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 838 template 11
sg1 = 0.0000000001!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 839 template 11
sg1 = 100000!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 840 template 11
sg1 = 10000000000!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 841 template 11
sg1 = 9999999999999999!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 842 template 11
sg1 = 1E+17!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 843 template 11
sg1 = 1E+20!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 844 template 11
sg1 = 1E+30!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 845 template 11
sg1 = -2.5E-30!
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 846 template 11
sg1 = SngBits(&h7FC00000)
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 847 template 11
sg1 = SngBits(&hFFC00000)
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 848 template 11
sg1 = SngBits(&h7F800000)
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 849 template 11
sg1 = SngBits(&hFF800000)
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 850 template 11
sg1 = SngBits(&h1)
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 851 template 11
sg1 = SngBits(&h80000001)
Print #2, "11 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(11); sg1
' 852 template 11
db1 = 0#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 853 template 11
db1 = DblBits(&h8000000000000000ULL)
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 854 template 11
db1 = 0.5#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 855 template 11
db1 = -0.5#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 856 template 11
db1 = 0.05#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 857 template 11
db1 = 0.005#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 858 template 11
db1 = 0.0005#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 859 template 11
db1 = 0.15#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 860 template 11
db1 = 0.25#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 861 template 11
db1 = 0.35#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 862 template 11
db1 = 0.45#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 863 template 11
db1 = 1#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 864 template 11
db1 = -1#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 865 template 11
db1 = 1.5#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 866 template 11
db1 = 2.5#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 867 template 11
db1 = 9.995#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 868 template 11
db1 = 10#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 869 template 11
db1 = 99.995#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 870 template 11
db1 = 99.9999#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 871 template 11
db1 = 123.456#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 872 template 11
db1 = -123.456#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 873 template 11
db1 = 999.95#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 874 template 11
db1 = 1234.5678#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 875 template 11
db1 = 12345.678#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 876 template 11
db1 = 99999.9#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 877 template 11
db1 = 0.1#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 878 template 11
db1 = 0.00001#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 879 template 11
db1 = 0.000000123#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 880 template 11
db1 = 0.0000000001#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 881 template 11
db1 = 100000#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 882 template 11
db1 = 10000000000#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 883 template 11
db1 = 9999999999999999#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 884 template 11
db1 = 1E+17#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 885 template 11
db1 = 1E+20#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 886 template 11
db1 = 1E+30#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 887 template 11
db1 = -2.5E-30#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 888 template 11
db1 = 1E+300#
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 889 template 11
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 890 template 11
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 891 template 11
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 892 template 11
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 893 template 11
db1 = DblBits(&h1ULL)
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 894 template 11
db1 = DblBits(&h8000000000000001ULL)
Print #2, "11 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(11); db1
' 895 template 12
sg1 = 0
sg2 = 0.005!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 896 template 12
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 897 template 12
sg1 = 0.5!
sg2 = 0.15!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 898 template 12
sg1 = -0.5!
sg2 = 0.25!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 899 template 12
sg1 = 0.05!
sg2 = 0.35!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 900 template 12
sg1 = 0.005!
sg2 = 0.45!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 901 template 12
sg1 = 0.0005!
sg2 = 1!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 902 template 12
sg1 = 0.15!
sg2 = -1!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 903 template 12
sg1 = 0.25!
sg2 = 1.5!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 904 template 12
sg1 = 0.35!
sg2 = 2.5!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 905 template 12
sg1 = 0.45!
sg2 = 9.995!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 906 template 12
sg1 = 1!
sg2 = 10!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 907 template 12
sg1 = -1!
sg2 = 99.995!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 908 template 12
sg1 = 1.5!
sg2 = 99.9999!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 909 template 12
sg1 = 2.5!
sg2 = 123.456!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 910 template 12
sg1 = 9.995!
sg2 = -123.456!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 911 template 12
sg1 = 10!
sg2 = 999.95!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 912 template 12
sg1 = 99.995!
sg2 = 1234.5678!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 913 template 12
sg1 = 99.9999!
sg2 = 12345.678!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 914 template 12
sg1 = 123.456!
sg2 = 99999.9!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 915 template 12
sg1 = -123.456!
sg2 = 0.1!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 916 template 12
sg1 = 999.95!
sg2 = 0.00001!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 917 template 12
sg1 = 1234.5678!
sg2 = 0.000000123!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 918 template 12
sg1 = 12345.678!
sg2 = 0.0000000001!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 919 template 12
sg1 = 99999.9!
sg2 = 100000!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 920 template 12
sg1 = 0.1!
sg2 = 10000000000!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 921 template 12
sg1 = 0.00001!
sg2 = 9999999999999999!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 922 template 12
sg1 = 0.000000123!
sg2 = 1E+17!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 923 template 12
sg1 = 0.0000000001!
sg2 = 1E+20!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 924 template 12
sg1 = 100000!
sg2 = 1E+30!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 925 template 12
sg1 = 10000000000!
sg2 = -2.5E-30!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 926 template 12
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 927 template 12
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 928 template 12
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 929 template 12
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 930 template 12
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 931 template 12
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 932 template 12
sg1 = SngBits(&hFFC00000)
sg2 = 0
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 933 template 12
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 934 template 12
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 935 template 12
sg1 = SngBits(&h1)
sg2 = -0.5!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 936 template 12
sg1 = SngBits(&h80000001)
sg2 = 0.05!
Print #2, "12 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(12); sg1; sg2
' 937 template 12
db1 = 0#
db2 = 0.005#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 938 template 12
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 939 template 12
db1 = 0.5#
db2 = 0.15#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 940 template 12
db1 = -0.5#
db2 = 0.25#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 941 template 12
db1 = 0.05#
db2 = 0.35#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 942 template 12
db1 = 0.005#
db2 = 0.45#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 943 template 12
db1 = 0.0005#
db2 = 1#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 944 template 12
db1 = 0.15#
db2 = -1#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 945 template 12
db1 = 0.25#
db2 = 1.5#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 946 template 12
db1 = 0.35#
db2 = 2.5#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 947 template 12
db1 = 0.45#
db2 = 9.995#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 948 template 12
db1 = 1#
db2 = 10#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 949 template 12
db1 = -1#
db2 = 99.995#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 950 template 12
db1 = 1.5#
db2 = 99.9999#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 951 template 12
db1 = 2.5#
db2 = 123.456#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 952 template 12
db1 = 9.995#
db2 = -123.456#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 953 template 12
db1 = 10#
db2 = 999.95#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 954 template 12
db1 = 99.995#
db2 = 1234.5678#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 955 template 12
db1 = 99.9999#
db2 = 12345.678#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 956 template 12
db1 = 123.456#
db2 = 99999.9#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 957 template 12
db1 = -123.456#
db2 = 0.1#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 958 template 12
db1 = 999.95#
db2 = 0.00001#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 959 template 12
db1 = 1234.5678#
db2 = 0.000000123#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 960 template 12
db1 = 12345.678#
db2 = 0.0000000001#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 961 template 12
db1 = 99999.9#
db2 = 100000#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 962 template 12
db1 = 0.1#
db2 = 10000000000#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 963 template 12
db1 = 0.00001#
db2 = 9999999999999999#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 964 template 12
db1 = 0.000000123#
db2 = 1E+17#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 965 template 12
db1 = 0.0000000001#
db2 = 1E+20#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 966 template 12
db1 = 100000#
db2 = 1E+30#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 967 template 12
db1 = 10000000000#
db2 = -2.5E-30#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 968 template 12
db1 = 9999999999999999#
db2 = 1E+300#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 969 template 12
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 970 template 12
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 971 template 12
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 972 template 12
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 973 template 12
db1 = 1E+300#
db2 = DblBits(&h1ULL)
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 974 template 12
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 975 template 12
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 976 template 12
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 977 template 12
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 978 template 12
db1 = DblBits(&h1ULL)
db2 = -0.5#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 979 template 12
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
Print #2, "12 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(12); db1; db2
' 980 template 13
sg1 = 0
sg2 = 0.005!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 981 template 13
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 982 template 13
sg1 = 0.5!
sg2 = 0.15!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 983 template 13
sg1 = -0.5!
sg2 = 0.25!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 984 template 13
sg1 = 0.05!
sg2 = 0.35!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 985 template 13
sg1 = 0.005!
sg2 = 0.45!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 986 template 13
sg1 = 0.0005!
sg2 = 1!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 987 template 13
sg1 = 0.15!
sg2 = -1!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 988 template 13
sg1 = 0.25!
sg2 = 1.5!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 989 template 13
sg1 = 0.35!
sg2 = 2.5!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 990 template 13
sg1 = 0.45!
sg2 = 9.995!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 991 template 13
sg1 = 1!
sg2 = 10!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 992 template 13
sg1 = -1!
sg2 = 99.995!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 993 template 13
sg1 = 1.5!
sg2 = 99.9999!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 994 template 13
sg1 = 2.5!
sg2 = 123.456!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 995 template 13
sg1 = 9.995!
sg2 = -123.456!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 996 template 13
sg1 = 10!
sg2 = 999.95!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 997 template 13
sg1 = 99.995!
sg2 = 1234.5678!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 998 template 13
sg1 = 99.9999!
sg2 = 12345.678!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 999 template 13
sg1 = 123.456!
sg2 = 99999.9!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1000 template 13
sg1 = -123.456!
sg2 = 0.1!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1001 template 13
sg1 = 999.95!
sg2 = 0.00001!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1002 template 13
sg1 = 1234.5678!
sg2 = 0.000000123!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1003 template 13
sg1 = 12345.678!
sg2 = 0.0000000001!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1004 template 13
sg1 = 99999.9!
sg2 = 100000!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1005 template 13
sg1 = 0.1!
sg2 = 10000000000!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1006 template 13
sg1 = 0.00001!
sg2 = 9999999999999999!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1007 template 13
sg1 = 0.000000123!
sg2 = 1E+17!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1008 template 13
sg1 = 0.0000000001!
sg2 = 1E+20!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1009 template 13
sg1 = 100000!
sg2 = 1E+30!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1010 template 13
sg1 = 10000000000!
sg2 = -2.5E-30!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1011 template 13
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1012 template 13
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1013 template 13
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1014 template 13
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1015 template 13
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1016 template 13
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1017 template 13
sg1 = SngBits(&hFFC00000)
sg2 = 0
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1018 template 13
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1019 template 13
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1020 template 13
sg1 = SngBits(&h1)
sg2 = -0.5!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1021 template 13
sg1 = SngBits(&h80000001)
sg2 = 0.05!
Print #2, "13 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(13); sg1; sg2
' 1022 template 13
db1 = 0#
db2 = 0.005#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1023 template 13
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1024 template 13
db1 = 0.5#
db2 = 0.15#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1025 template 13
db1 = -0.5#
db2 = 0.25#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1026 template 13
db1 = 0.05#
db2 = 0.35#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1027 template 13
db1 = 0.005#
db2 = 0.45#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1028 template 13
db1 = 0.0005#
db2 = 1#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1029 template 13
db1 = 0.15#
db2 = -1#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1030 template 13
db1 = 0.25#
db2 = 1.5#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1031 template 13
db1 = 0.35#
db2 = 2.5#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1032 template 13
db1 = 0.45#
db2 = 9.995#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1033 template 13
db1 = 1#
db2 = 10#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1034 template 13
db1 = -1#
db2 = 99.995#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1035 template 13
db1 = 1.5#
db2 = 99.9999#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1036 template 13
db1 = 2.5#
db2 = 123.456#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1037 template 13
db1 = 9.995#
db2 = -123.456#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1038 template 13
db1 = 10#
db2 = 999.95#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1039 template 13
db1 = 99.995#
db2 = 1234.5678#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1040 template 13
db1 = 99.9999#
db2 = 12345.678#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1041 template 13
db1 = 123.456#
db2 = 99999.9#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1042 template 13
db1 = -123.456#
db2 = 0.1#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1043 template 13
db1 = 999.95#
db2 = 0.00001#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1044 template 13
db1 = 1234.5678#
db2 = 0.000000123#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1045 template 13
db1 = 12345.678#
db2 = 0.0000000001#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1046 template 13
db1 = 99999.9#
db2 = 100000#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1047 template 13
db1 = 0.1#
db2 = 10000000000#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1048 template 13
db1 = 0.00001#
db2 = 9999999999999999#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1049 template 13
db1 = 0.000000123#
db2 = 1E+17#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1050 template 13
db1 = 0.0000000001#
db2 = 1E+20#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1051 template 13
db1 = 100000#
db2 = 1E+30#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1052 template 13
db1 = 10000000000#
db2 = -2.5E-30#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1053 template 13
db1 = 9999999999999999#
db2 = 1E+300#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1054 template 13
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1055 template 13
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1056 template 13
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1057 template 13
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1058 template 13
db1 = 1E+300#
db2 = DblBits(&h1ULL)
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1059 template 13
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1060 template 13
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1061 template 13
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1062 template 13
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1063 template 13
db1 = DblBits(&h1ULL)
db2 = -0.5#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1064 template 13
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
Print #2, "13 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(13); db1; db2
' 1065 template 14
sg1 = 0
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1066 template 14
sg1 = SngBits(&h80000000)
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1067 template 14
sg1 = 0.5!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1068 template 14
sg1 = -0.5!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1069 template 14
sg1 = 0.05!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1070 template 14
sg1 = 0.005!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1071 template 14
sg1 = 0.0005!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1072 template 14
sg1 = 0.15!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1073 template 14
sg1 = 0.25!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1074 template 14
sg1 = 0.35!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1075 template 14
sg1 = 0.45!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1076 template 14
sg1 = 1!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1077 template 14
sg1 = -1!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1078 template 14
sg1 = 1.5!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1079 template 14
sg1 = 2.5!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1080 template 14
sg1 = 9.995!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1081 template 14
sg1 = 10!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1082 template 14
sg1 = 99.995!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1083 template 14
sg1 = 99.9999!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1084 template 14
sg1 = 123.456!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1085 template 14
sg1 = -123.456!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1086 template 14
sg1 = 999.95!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1087 template 14
sg1 = 1234.5678!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1088 template 14
sg1 = 12345.678!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1089 template 14
sg1 = 99999.9!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1090 template 14
sg1 = 0.1!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1091 template 14
sg1 = 0.00001!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1092 template 14
sg1 = 0.000000123!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1093 template 14
sg1 = 0.0000000001!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1094 template 14
sg1 = 100000!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1095 template 14
sg1 = 10000000000!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1096 template 14
sg1 = 9999999999999999!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1097 template 14
sg1 = 1E+17!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1098 template 14
sg1 = 1E+20!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1099 template 14
sg1 = 1E+30!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1100 template 14
sg1 = -2.5E-30!
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1101 template 14
sg1 = SngBits(&h7FC00000)
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1102 template 14
sg1 = SngBits(&hFFC00000)
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1103 template 14
sg1 = SngBits(&h7F800000)
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1104 template 14
sg1 = SngBits(&hFF800000)
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1105 template 14
sg1 = SngBits(&h1)
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1106 template 14
sg1 = SngBits(&h80000001)
Print #2, "14 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(14); sg1
' 1107 template 14
li1 = 0
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1108 template 14
li1 = 1
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1109 template 14
li1 = -1
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1110 template 14
li1 = 42
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1111 template 14
li1 = -7
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1112 template 14
li1 = 12345
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1113 template 14
li1 = 99999
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1114 template 14
li1 = 100000
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1115 template 14
li1 = 999999999
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1116 template 14
li1 = -2147483648
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1117 template 14
li1 = 2147483647
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1118 template 14
li1 = 9223372036854775807
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1119 template 14
li1 = (-9223372036854775807 - 1)
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1120 template 14
li1 = 1000000
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1121 template 14
li1 = 123456789012
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1122 template 14
li1 = -100
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1123 template 14
li1 = 5
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1124 template 14
li1 = 10
Print #2, "14 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(14); li1
' 1125 template 15
sg1 = 0
sg2 = 0.005!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1126 template 15
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1127 template 15
sg1 = 0.5!
sg2 = 0.15!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1128 template 15
sg1 = -0.5!
sg2 = 0.25!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1129 template 15
sg1 = 0.05!
sg2 = 0.35!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1130 template 15
sg1 = 0.005!
sg2 = 0.45!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1131 template 15
sg1 = 0.0005!
sg2 = 1!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1132 template 15
sg1 = 0.15!
sg2 = -1!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1133 template 15
sg1 = 0.25!
sg2 = 1.5!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1134 template 15
sg1 = 0.35!
sg2 = 2.5!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1135 template 15
sg1 = 0.45!
sg2 = 9.995!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1136 template 15
sg1 = 1!
sg2 = 10!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1137 template 15
sg1 = -1!
sg2 = 99.995!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1138 template 15
sg1 = 1.5!
sg2 = 99.9999!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1139 template 15
sg1 = 2.5!
sg2 = 123.456!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1140 template 15
sg1 = 9.995!
sg2 = -123.456!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1141 template 15
sg1 = 10!
sg2 = 999.95!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1142 template 15
sg1 = 99.995!
sg2 = 1234.5678!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1143 template 15
sg1 = 99.9999!
sg2 = 12345.678!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1144 template 15
sg1 = 123.456!
sg2 = 99999.9!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1145 template 15
sg1 = -123.456!
sg2 = 0.1!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1146 template 15
sg1 = 999.95!
sg2 = 0.00001!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1147 template 15
sg1 = 1234.5678!
sg2 = 0.000000123!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1148 template 15
sg1 = 12345.678!
sg2 = 0.0000000001!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1149 template 15
sg1 = 99999.9!
sg2 = 100000!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1150 template 15
sg1 = 0.1!
sg2 = 10000000000!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1151 template 15
sg1 = 0.00001!
sg2 = 9999999999999999!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1152 template 15
sg1 = 0.000000123!
sg2 = 1E+17!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1153 template 15
sg1 = 0.0000000001!
sg2 = 1E+20!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1154 template 15
sg1 = 100000!
sg2 = 1E+30!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1155 template 15
sg1 = 10000000000!
sg2 = -2.5E-30!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1156 template 15
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1157 template 15
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1158 template 15
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1159 template 15
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1160 template 15
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1161 template 15
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1162 template 15
sg1 = SngBits(&hFFC00000)
sg2 = 0
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1163 template 15
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1164 template 15
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1165 template 15
sg1 = SngBits(&h1)
sg2 = -0.5!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1166 template 15
sg1 = SngBits(&h80000001)
sg2 = 0.05!
Print #2, "15 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(15); sg1; sg2
' 1167 template 15
li1 = 0
li2 = 12345
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1168 template 15
li1 = 1
li2 = 99999
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1169 template 15
li1 = -1
li2 = 100000
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1170 template 15
li1 = 42
li2 = 999999999
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1171 template 15
li1 = -7
li2 = -2147483648
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1172 template 15
li1 = 12345
li2 = 2147483647
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1173 template 15
li1 = 99999
li2 = 9223372036854775807
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1174 template 15
li1 = 100000
li2 = (-9223372036854775807 - 1)
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1175 template 15
li1 = 999999999
li2 = 1000000
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1176 template 15
li1 = -2147483648
li2 = 123456789012
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1177 template 15
li1 = 2147483647
li2 = -100
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1178 template 15
li1 = 9223372036854775807
li2 = 5
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1179 template 15
li1 = (-9223372036854775807 - 1)
li2 = 10
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1180 template 15
li1 = 1000000
li2 = 0
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1181 template 15
li1 = 123456789012
li2 = 1
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1182 template 15
li1 = -100
li2 = -1
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1183 template 15
li1 = 5
li2 = 42
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1184 template 15
li1 = 10
li2 = -7
Print #2, "15 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(15); li1; li2
' 1185 template 16
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1186 template 16
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1187 template 16
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1188 template 16
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1189 template 16
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1190 template 16
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1191 template 16
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1192 template 16
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1193 template 16
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1194 template 16
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1195 template 16
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1196 template 16
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1197 template 16
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1198 template 16
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1199 template 16
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1200 template 16
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1201 template 16
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1202 template 16
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1203 template 16
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1204 template 16
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1205 template 16
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1206 template 16
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1207 template 16
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1208 template 16
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1209 template 16
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1210 template 16
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1211 template 16
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1212 template 16
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1213 template 16
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1214 template 16
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1215 template 16
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1216 template 16
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1217 template 16
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1218 template 16
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1219 template 16
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1220 template 16
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1221 template 16
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1222 template 16
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1223 template 16
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1224 template 16
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1225 template 16
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1226 template 16
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
Print #2, "16 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(16); sg1; sg2; sg3
' 1227 template 16
db1 = 0#
db2 = 0.005#
db3 = 0.45#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1228 template 16
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1229 template 16
db1 = 0.5#
db2 = 0.15#
db3 = -1#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1230 template 16
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1231 template 16
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1232 template 16
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1233 template 16
db1 = 0.0005#
db2 = 1#
db3 = 10#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1234 template 16
db1 = 0.15#
db2 = -1#
db3 = 99.995#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1235 template 16
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1236 template 16
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1237 template 16
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1238 template 16
db1 = 1#
db2 = 10#
db3 = 999.95#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1239 template 16
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1240 template 16
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1241 template 16
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1242 template 16
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1243 template 16
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1244 template 16
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1245 template 16
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1246 template 16
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1247 template 16
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1248 template 16
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1249 template 16
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1250 template 16
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1251 template 16
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1252 template 16
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1253 template 16
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1254 template 16
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1255 template 16
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1256 template 16
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1257 template 16
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1258 template 16
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1259 template 16
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1260 template 16
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1261 template 16
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1262 template 16
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1263 template 16
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1264 template 16
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1265 template 16
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1266 template 16
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1267 template 16
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1268 template 16
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1269 template 16
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
Print #2, "16 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(16); db1; db2; db3
' 1270 template 17
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
sg4 = 9.995!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1271 template 17
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
sg4 = 10!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1272 template 17
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
sg4 = 99.995!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1273 template 17
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
sg4 = 99.9999!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1274 template 17
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
sg4 = 123.456!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1275 template 17
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
sg4 = -123.456!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1276 template 17
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
sg4 = 999.95!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1277 template 17
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
sg4 = 1234.5678!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1278 template 17
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
sg4 = 12345.678!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1279 template 17
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
sg4 = 99999.9!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1280 template 17
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
sg4 = 0.1!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1281 template 17
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
sg4 = 0.00001!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1282 template 17
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
sg4 = 0.000000123!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1283 template 17
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
sg4 = 0.0000000001!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1284 template 17
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
sg4 = 100000!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1285 template 17
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
sg4 = 10000000000!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1286 template 17
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
sg4 = 9999999999999999!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1287 template 17
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
sg4 = 1E+17!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1288 template 17
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
sg4 = 1E+20!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1289 template 17
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
sg4 = 1E+30!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1290 template 17
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
sg4 = -2.5E-30!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1291 template 17
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
sg4 = SngBits(&h7FC00000)
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1292 template 17
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
sg4 = SngBits(&hFFC00000)
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1293 template 17
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
sg4 = SngBits(&h7F800000)
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1294 template 17
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
sg4 = SngBits(&hFF800000)
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1295 template 17
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
sg4 = SngBits(&h1)
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1296 template 17
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
sg4 = SngBits(&h80000001)
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1297 template 17
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
sg4 = 0
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1298 template 17
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
sg4 = SngBits(&h80000000)
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1299 template 17
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
sg4 = 0.5!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1300 template 17
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
sg4 = -0.5!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1301 template 17
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
sg4 = 0.05!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1302 template 17
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
sg4 = 0.005!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1303 template 17
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
sg4 = 0.0005!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1304 template 17
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
sg4 = 0.15!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1305 template 17
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
sg4 = 0.25!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1306 template 17
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
sg4 = 0.35!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1307 template 17
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
sg4 = 0.45!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1308 template 17
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
sg4 = 1!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1309 template 17
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
sg4 = -1!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1310 template 17
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
sg4 = 1.5!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1311 template 17
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
sg4 = 2.5!
Print #2, "17 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(17); sg1; sg2; sg3; sg4
' 1312 template 17
db1 = 0#
db2 = 0.005#
db3 = 0.45#
db4 = 9.995#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1313 template 17
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
db4 = 10#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1314 template 17
db1 = 0.5#
db2 = 0.15#
db3 = -1#
db4 = 99.995#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1315 template 17
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
db4 = 99.9999#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1316 template 17
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
db4 = 123.456#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1317 template 17
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
db4 = -123.456#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1318 template 17
db1 = 0.0005#
db2 = 1#
db3 = 10#
db4 = 999.95#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1319 template 17
db1 = 0.15#
db2 = -1#
db3 = 99.995#
db4 = 1234.5678#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1320 template 17
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
db4 = 12345.678#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1321 template 17
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
db4 = 99999.9#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1322 template 17
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
db4 = 0.1#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1323 template 17
db1 = 1#
db2 = 10#
db3 = 999.95#
db4 = 0.00001#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1324 template 17
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
db4 = 0.000000123#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1325 template 17
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
db4 = 0.0000000001#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1326 template 17
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
db4 = 100000#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1327 template 17
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
db4 = 10000000000#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1328 template 17
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
db4 = 9999999999999999#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1329 template 17
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
db4 = 1E+17#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1330 template 17
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
db4 = 1E+20#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1331 template 17
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
db4 = 1E+30#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1332 template 17
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
db4 = -2.5E-30#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1333 template 17
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
db4 = 1E+300#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1334 template 17
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
db4 = DblBits(&h7FF8000000000000ULL)
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1335 template 17
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
db4 = DblBits(&hFFF8000000000000ULL)
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1336 template 17
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
db4 = DblBits(&h7FF0000000000000ULL)
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1337 template 17
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
db4 = DblBits(&hFFF0000000000000ULL)
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1338 template 17
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
db4 = DblBits(&h1ULL)
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1339 template 17
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
db4 = DblBits(&h8000000000000001ULL)
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1340 template 17
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
db4 = 0#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1341 template 17
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
db4 = DblBits(&h8000000000000000ULL)
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1342 template 17
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
db4 = 0.5#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1343 template 17
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
db4 = -0.5#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1344 template 17
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
db4 = 0.05#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1345 template 17
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
db4 = 0.005#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1346 template 17
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
db4 = 0.0005#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1347 template 17
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
db4 = 0.15#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1348 template 17
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
db4 = 0.25#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1349 template 17
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
db4 = 0.35#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1350 template 17
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
db4 = 0.45#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1351 template 17
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
db4 = 1#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1352 template 17
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
db4 = -1#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1353 template 17
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
db4 = 1.5#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1354 template 17
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
db4 = 2.5#
Print #2, "17 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(17); db1; db2; db3; db4
' 1355 template 18
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
sg4 = 9.995!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1356 template 18
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
sg4 = 10!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1357 template 18
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
sg4 = 99.995!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1358 template 18
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
sg4 = 99.9999!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1359 template 18
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
sg4 = 123.456!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1360 template 18
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
sg4 = -123.456!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1361 template 18
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
sg4 = 999.95!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1362 template 18
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
sg4 = 1234.5678!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1363 template 18
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
sg4 = 12345.678!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1364 template 18
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
sg4 = 99999.9!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1365 template 18
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
sg4 = 0.1!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1366 template 18
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
sg4 = 0.00001!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1367 template 18
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
sg4 = 0.000000123!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1368 template 18
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
sg4 = 0.0000000001!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1369 template 18
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
sg4 = 100000!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1370 template 18
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
sg4 = 10000000000!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1371 template 18
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
sg4 = 9999999999999999!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1372 template 18
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
sg4 = 1E+17!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1373 template 18
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
sg4 = 1E+20!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1374 template 18
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
sg4 = 1E+30!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1375 template 18
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
sg4 = -2.5E-30!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1376 template 18
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
sg4 = SngBits(&h7FC00000)
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1377 template 18
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
sg4 = SngBits(&hFFC00000)
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1378 template 18
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
sg4 = SngBits(&h7F800000)
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1379 template 18
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
sg4 = SngBits(&hFF800000)
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1380 template 18
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
sg4 = SngBits(&h1)
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1381 template 18
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
sg4 = SngBits(&h80000001)
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1382 template 18
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
sg4 = 0
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1383 template 18
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
sg4 = SngBits(&h80000000)
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1384 template 18
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
sg4 = 0.5!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1385 template 18
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
sg4 = -0.5!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1386 template 18
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
sg4 = 0.05!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1387 template 18
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
sg4 = 0.005!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1388 template 18
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
sg4 = 0.0005!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1389 template 18
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
sg4 = 0.15!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1390 template 18
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
sg4 = 0.25!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1391 template 18
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
sg4 = 0.35!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1392 template 18
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
sg4 = 0.45!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1393 template 18
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
sg4 = 1!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1394 template 18
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
sg4 = -1!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1395 template 18
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
sg4 = 1.5!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1396 template 18
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
sg4 = 2.5!
Print #2, "18 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(18); sg1; sg2; sg3; sg4
' 1397 template 18
db1 = 0#
db2 = 0.005#
db3 = 0.45#
db4 = 9.995#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1398 template 18
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
db4 = 10#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1399 template 18
db1 = 0.5#
db2 = 0.15#
db3 = -1#
db4 = 99.995#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1400 template 18
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
db4 = 99.9999#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1401 template 18
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
db4 = 123.456#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1402 template 18
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
db4 = -123.456#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1403 template 18
db1 = 0.0005#
db2 = 1#
db3 = 10#
db4 = 999.95#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1404 template 18
db1 = 0.15#
db2 = -1#
db3 = 99.995#
db4 = 1234.5678#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1405 template 18
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
db4 = 12345.678#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1406 template 18
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
db4 = 99999.9#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1407 template 18
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
db4 = 0.1#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1408 template 18
db1 = 1#
db2 = 10#
db3 = 999.95#
db4 = 0.00001#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1409 template 18
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
db4 = 0.000000123#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1410 template 18
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
db4 = 0.0000000001#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1411 template 18
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
db4 = 100000#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1412 template 18
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
db4 = 10000000000#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1413 template 18
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
db4 = 9999999999999999#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1414 template 18
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
db4 = 1E+17#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1415 template 18
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
db4 = 1E+20#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1416 template 18
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
db4 = 1E+30#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1417 template 18
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
db4 = -2.5E-30#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1418 template 18
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
db4 = 1E+300#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1419 template 18
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
db4 = DblBits(&h7FF8000000000000ULL)
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1420 template 18
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
db4 = DblBits(&hFFF8000000000000ULL)
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1421 template 18
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
db4 = DblBits(&h7FF0000000000000ULL)
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1422 template 18
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
db4 = DblBits(&hFFF0000000000000ULL)
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1423 template 18
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
db4 = DblBits(&h1ULL)
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1424 template 18
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
db4 = DblBits(&h8000000000000001ULL)
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1425 template 18
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
db4 = 0#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1426 template 18
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
db4 = DblBits(&h8000000000000000ULL)
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1427 template 18
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
db4 = 0.5#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1428 template 18
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
db4 = -0.5#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1429 template 18
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
db4 = 0.05#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1430 template 18
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
db4 = 0.005#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1431 template 18
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
db4 = 0.0005#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1432 template 18
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
db4 = 0.15#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1433 template 18
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
db4 = 0.25#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1434 template 18
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
db4 = 0.35#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1435 template 18
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
db4 = 0.45#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1436 template 18
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
db4 = 1#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1437 template 18
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
db4 = -1#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1438 template 18
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
db4 = 1.5#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1439 template 18
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
db4 = 2.5#
Print #2, "18 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(18); db1; db2; db3; db4
' 1440 template 19
sg1 = 0
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1441 template 19
sg1 = SngBits(&h80000000)
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1442 template 19
sg1 = 0.5!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1443 template 19
sg1 = -0.5!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1444 template 19
sg1 = 0.05!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1445 template 19
sg1 = 0.005!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1446 template 19
sg1 = 0.0005!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1447 template 19
sg1 = 0.15!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1448 template 19
sg1 = 0.25!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1449 template 19
sg1 = 0.35!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1450 template 19
sg1 = 0.45!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1451 template 19
sg1 = 1!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1452 template 19
sg1 = -1!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1453 template 19
sg1 = 1.5!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1454 template 19
sg1 = 2.5!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1455 template 19
sg1 = 9.995!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1456 template 19
sg1 = 10!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1457 template 19
sg1 = 99.995!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1458 template 19
sg1 = 99.9999!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1459 template 19
sg1 = 123.456!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1460 template 19
sg1 = -123.456!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1461 template 19
sg1 = 999.95!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1462 template 19
sg1 = 1234.5678!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1463 template 19
sg1 = 12345.678!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1464 template 19
sg1 = 99999.9!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1465 template 19
sg1 = 0.1!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1466 template 19
sg1 = 0.00001!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1467 template 19
sg1 = 0.000000123!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1468 template 19
sg1 = 0.0000000001!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1469 template 19
sg1 = 100000!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1470 template 19
sg1 = 10000000000!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1471 template 19
sg1 = 9999999999999999!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1472 template 19
sg1 = 1E+17!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1473 template 19
sg1 = 1E+20!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1474 template 19
sg1 = 1E+30!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1475 template 19
sg1 = -2.5E-30!
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1476 template 19
sg1 = SngBits(&h7FC00000)
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1477 template 19
sg1 = SngBits(&hFFC00000)
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1478 template 19
sg1 = SngBits(&h7F800000)
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1479 template 19
sg1 = SngBits(&hFF800000)
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1480 template 19
sg1 = SngBits(&h1)
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1481 template 19
sg1 = SngBits(&h80000001)
Print #2, "19 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(19); sg1
' 1482 template 19
db1 = 0#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1483 template 19
db1 = DblBits(&h8000000000000000ULL)
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1484 template 19
db1 = 0.5#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1485 template 19
db1 = -0.5#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1486 template 19
db1 = 0.05#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1487 template 19
db1 = 0.005#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1488 template 19
db1 = 0.0005#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1489 template 19
db1 = 0.15#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1490 template 19
db1 = 0.25#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1491 template 19
db1 = 0.35#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1492 template 19
db1 = 0.45#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1493 template 19
db1 = 1#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1494 template 19
db1 = -1#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1495 template 19
db1 = 1.5#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1496 template 19
db1 = 2.5#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1497 template 19
db1 = 9.995#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1498 template 19
db1 = 10#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1499 template 19
db1 = 99.995#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1500 template 19
db1 = 99.9999#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1501 template 19
db1 = 123.456#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1502 template 19
db1 = -123.456#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1503 template 19
db1 = 999.95#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1504 template 19
db1 = 1234.5678#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1505 template 19
db1 = 12345.678#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1506 template 19
db1 = 99999.9#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1507 template 19
db1 = 0.1#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1508 template 19
db1 = 0.00001#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1509 template 19
db1 = 0.000000123#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1510 template 19
db1 = 0.0000000001#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1511 template 19
db1 = 100000#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1512 template 19
db1 = 10000000000#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1513 template 19
db1 = 9999999999999999#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1514 template 19
db1 = 1E+17#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1515 template 19
db1 = 1E+20#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1516 template 19
db1 = 1E+30#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1517 template 19
db1 = -2.5E-30#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1518 template 19
db1 = 1E+300#
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1519 template 19
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1520 template 19
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1521 template 19
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1522 template 19
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1523 template 19
db1 = DblBits(&h1ULL)
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1524 template 19
db1 = DblBits(&h8000000000000001ULL)
Print #2, "19 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(19); db1
' 1525 template 20
sg1 = 0
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1526 template 20
sg1 = SngBits(&h80000000)
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1527 template 20
sg1 = 0.5!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1528 template 20
sg1 = -0.5!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1529 template 20
sg1 = 0.05!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1530 template 20
sg1 = 0.005!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1531 template 20
sg1 = 0.0005!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1532 template 20
sg1 = 0.15!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1533 template 20
sg1 = 0.25!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1534 template 20
sg1 = 0.35!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1535 template 20
sg1 = 0.45!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1536 template 20
sg1 = 1!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1537 template 20
sg1 = -1!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1538 template 20
sg1 = 1.5!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1539 template 20
sg1 = 2.5!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1540 template 20
sg1 = 9.995!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1541 template 20
sg1 = 10!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1542 template 20
sg1 = 99.995!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1543 template 20
sg1 = 99.9999!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1544 template 20
sg1 = 123.456!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1545 template 20
sg1 = -123.456!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1546 template 20
sg1 = 999.95!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1547 template 20
sg1 = 1234.5678!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1548 template 20
sg1 = 12345.678!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1549 template 20
sg1 = 99999.9!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1550 template 20
sg1 = 0.1!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1551 template 20
sg1 = 0.00001!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1552 template 20
sg1 = 0.000000123!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1553 template 20
sg1 = 0.0000000001!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1554 template 20
sg1 = 100000!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1555 template 20
sg1 = 10000000000!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1556 template 20
sg1 = 9999999999999999!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1557 template 20
sg1 = 1E+17!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1558 template 20
sg1 = 1E+20!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1559 template 20
sg1 = 1E+30!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1560 template 20
sg1 = -2.5E-30!
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1561 template 20
sg1 = SngBits(&h7FC00000)
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1562 template 20
sg1 = SngBits(&hFFC00000)
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1563 template 20
sg1 = SngBits(&h7F800000)
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1564 template 20
sg1 = SngBits(&hFF800000)
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1565 template 20
sg1 = SngBits(&h1)
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1566 template 20
sg1 = SngBits(&h80000001)
Print #2, "20 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(20); sg1
' 1567 template 20
db1 = 0#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1568 template 20
db1 = DblBits(&h8000000000000000ULL)
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1569 template 20
db1 = 0.5#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1570 template 20
db1 = -0.5#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1571 template 20
db1 = 0.05#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1572 template 20
db1 = 0.005#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1573 template 20
db1 = 0.0005#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1574 template 20
db1 = 0.15#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1575 template 20
db1 = 0.25#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1576 template 20
db1 = 0.35#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1577 template 20
db1 = 0.45#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1578 template 20
db1 = 1#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1579 template 20
db1 = -1#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1580 template 20
db1 = 1.5#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1581 template 20
db1 = 2.5#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1582 template 20
db1 = 9.995#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1583 template 20
db1 = 10#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1584 template 20
db1 = 99.995#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1585 template 20
db1 = 99.9999#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1586 template 20
db1 = 123.456#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1587 template 20
db1 = -123.456#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1588 template 20
db1 = 999.95#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1589 template 20
db1 = 1234.5678#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1590 template 20
db1 = 12345.678#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1591 template 20
db1 = 99999.9#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1592 template 20
db1 = 0.1#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1593 template 20
db1 = 0.00001#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1594 template 20
db1 = 0.000000123#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1595 template 20
db1 = 0.0000000001#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1596 template 20
db1 = 100000#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1597 template 20
db1 = 10000000000#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1598 template 20
db1 = 9999999999999999#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1599 template 20
db1 = 1E+17#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1600 template 20
db1 = 1E+20#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1601 template 20
db1 = 1E+30#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1602 template 20
db1 = -2.5E-30#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1603 template 20
db1 = 1E+300#
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1604 template 20
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1605 template 20
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1606 template 20
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1607 template 20
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1608 template 20
db1 = DblBits(&h1ULL)
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1609 template 20
db1 = DblBits(&h8000000000000001ULL)
Print #2, "20 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(20); db1
' 1610 template 21
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1611 template 21
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1612 template 21
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1613 template 21
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1614 template 21
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1615 template 21
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1616 template 21
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1617 template 21
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1618 template 21
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1619 template 21
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1620 template 21
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1621 template 21
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1622 template 21
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1623 template 21
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1624 template 21
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1625 template 21
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1626 template 21
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1627 template 21
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1628 template 21
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1629 template 21
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1630 template 21
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1631 template 21
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1632 template 21
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1633 template 21
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1634 template 21
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1635 template 21
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1636 template 21
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1637 template 21
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1638 template 21
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1639 template 21
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1640 template 21
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1641 template 21
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1642 template 21
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1643 template 21
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1644 template 21
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1645 template 21
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1646 template 21
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1647 template 21
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1648 template 21
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1649 template 21
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1650 template 21
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1651 template 21
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
Print #2, "21 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(21); sg1; sg2; sg3
' 1652 template 21
db1 = 0#
db2 = 0.005#
db3 = 0.45#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1653 template 21
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1654 template 21
db1 = 0.5#
db2 = 0.15#
db3 = -1#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1655 template 21
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1656 template 21
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1657 template 21
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1658 template 21
db1 = 0.0005#
db2 = 1#
db3 = 10#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1659 template 21
db1 = 0.15#
db2 = -1#
db3 = 99.995#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1660 template 21
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1661 template 21
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1662 template 21
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1663 template 21
db1 = 1#
db2 = 10#
db3 = 999.95#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1664 template 21
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1665 template 21
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1666 template 21
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1667 template 21
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1668 template 21
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1669 template 21
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1670 template 21
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1671 template 21
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1672 template 21
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1673 template 21
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1674 template 21
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1675 template 21
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1676 template 21
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1677 template 21
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1678 template 21
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1679 template 21
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1680 template 21
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1681 template 21
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1682 template 21
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1683 template 21
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1684 template 21
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1685 template 21
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1686 template 21
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1687 template 21
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1688 template 21
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1689 template 21
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1690 template 21
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1691 template 21
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1692 template 21
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1693 template 21
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1694 template 21
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
Print #2, "21 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(21); db1; db2; db3
' 1695 template 22
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1696 template 22
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1697 template 22
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1698 template 22
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1699 template 22
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1700 template 22
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1701 template 22
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1702 template 22
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1703 template 22
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1704 template 22
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1705 template 22
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1706 template 22
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1707 template 22
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1708 template 22
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1709 template 22
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1710 template 22
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1711 template 22
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1712 template 22
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1713 template 22
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1714 template 22
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1715 template 22
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1716 template 22
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1717 template 22
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1718 template 22
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1719 template 22
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1720 template 22
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1721 template 22
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1722 template 22
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1723 template 22
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1724 template 22
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1725 template 22
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1726 template 22
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1727 template 22
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1728 template 22
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1729 template 22
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1730 template 22
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1731 template 22
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1732 template 22
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1733 template 22
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1734 template 22
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1735 template 22
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1736 template 22
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
Print #2, "22 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(22); sg1; sg2; sg3
' 1737 template 22
db1 = 0#
db2 = 0.005#
db3 = 0.45#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1738 template 22
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1739 template 22
db1 = 0.5#
db2 = 0.15#
db3 = -1#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1740 template 22
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1741 template 22
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1742 template 22
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1743 template 22
db1 = 0.0005#
db2 = 1#
db3 = 10#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1744 template 22
db1 = 0.15#
db2 = -1#
db3 = 99.995#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1745 template 22
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1746 template 22
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1747 template 22
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1748 template 22
db1 = 1#
db2 = 10#
db3 = 999.95#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1749 template 22
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1750 template 22
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1751 template 22
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1752 template 22
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1753 template 22
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1754 template 22
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1755 template 22
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1756 template 22
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1757 template 22
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1758 template 22
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1759 template 22
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1760 template 22
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1761 template 22
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1762 template 22
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1763 template 22
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1764 template 22
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1765 template 22
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1766 template 22
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1767 template 22
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1768 template 22
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1769 template 22
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1770 template 22
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1771 template 22
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1772 template 22
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1773 template 22
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1774 template 22
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1775 template 22
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1776 template 22
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1777 template 22
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1778 template 22
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1779 template 22
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
Print #2, "22 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(22); db1; db2; db3
' 1780 template 23
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1781 template 23
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1782 template 23
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1783 template 23
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1784 template 23
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1785 template 23
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1786 template 23
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1787 template 23
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1788 template 23
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1789 template 23
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1790 template 23
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1791 template 23
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1792 template 23
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1793 template 23
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1794 template 23
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1795 template 23
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1796 template 23
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1797 template 23
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1798 template 23
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1799 template 23
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1800 template 23
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1801 template 23
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1802 template 23
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1803 template 23
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1804 template 23
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1805 template 23
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1806 template 23
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1807 template 23
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1808 template 23
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1809 template 23
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1810 template 23
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1811 template 23
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1812 template 23
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1813 template 23
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1814 template 23
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1815 template 23
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1816 template 23
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1817 template 23
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1818 template 23
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1819 template 23
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1820 template 23
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1821 template 23
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
Print #2, "23 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(23); sg1; sg2; sg3
' 1822 template 23
li1 = 0
li2 = 12345
li3 = 2147483647
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1823 template 23
li1 = 1
li2 = 99999
li3 = 9223372036854775807
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1824 template 23
li1 = -1
li2 = 100000
li3 = (-9223372036854775807 - 1)
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1825 template 23
li1 = 42
li2 = 999999999
li3 = 1000000
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1826 template 23
li1 = -7
li2 = -2147483648
li3 = 123456789012
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1827 template 23
li1 = 12345
li2 = 2147483647
li3 = -100
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1828 template 23
li1 = 99999
li2 = 9223372036854775807
li3 = 5
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1829 template 23
li1 = 100000
li2 = (-9223372036854775807 - 1)
li3 = 10
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1830 template 23
li1 = 999999999
li2 = 1000000
li3 = 0
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1831 template 23
li1 = -2147483648
li2 = 123456789012
li3 = 1
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1832 template 23
li1 = 2147483647
li2 = -100
li3 = -1
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1833 template 23
li1 = 9223372036854775807
li2 = 5
li3 = 42
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1834 template 23
li1 = (-9223372036854775807 - 1)
li2 = 10
li3 = -7
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1835 template 23
li1 = 1000000
li2 = 0
li3 = 12345
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1836 template 23
li1 = 123456789012
li2 = 1
li3 = 99999
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1837 template 23
li1 = -100
li2 = -1
li3 = 100000
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1838 template 23
li1 = 5
li2 = 42
li3 = 999999999
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1839 template 23
li1 = 10
li2 = -7
li3 = -2147483648
Print #2, "23 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(23); li1; li2; li3
' 1840 template 24
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
sg4 = 9.995!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1841 template 24
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
sg4 = 10!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1842 template 24
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
sg4 = 99.995!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1843 template 24
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
sg4 = 99.9999!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1844 template 24
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
sg4 = 123.456!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1845 template 24
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
sg4 = -123.456!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1846 template 24
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
sg4 = 999.95!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1847 template 24
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
sg4 = 1234.5678!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1848 template 24
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
sg4 = 12345.678!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1849 template 24
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
sg4 = 99999.9!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1850 template 24
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
sg4 = 0.1!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1851 template 24
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
sg4 = 0.00001!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1852 template 24
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
sg4 = 0.000000123!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1853 template 24
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
sg4 = 0.0000000001!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1854 template 24
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
sg4 = 100000!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1855 template 24
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
sg4 = 10000000000!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1856 template 24
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
sg4 = 9999999999999999!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1857 template 24
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
sg4 = 1E+17!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1858 template 24
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
sg4 = 1E+20!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1859 template 24
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
sg4 = 1E+30!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1860 template 24
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
sg4 = -2.5E-30!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1861 template 24
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
sg4 = SngBits(&h7FC00000)
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1862 template 24
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
sg4 = SngBits(&hFFC00000)
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1863 template 24
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
sg4 = SngBits(&h7F800000)
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1864 template 24
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
sg4 = SngBits(&hFF800000)
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1865 template 24
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
sg4 = SngBits(&h1)
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1866 template 24
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
sg4 = SngBits(&h80000001)
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1867 template 24
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
sg4 = 0
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1868 template 24
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
sg4 = SngBits(&h80000000)
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1869 template 24
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
sg4 = 0.5!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1870 template 24
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
sg4 = -0.5!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1871 template 24
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
sg4 = 0.05!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1872 template 24
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
sg4 = 0.005!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1873 template 24
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
sg4 = 0.0005!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1874 template 24
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
sg4 = 0.15!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1875 template 24
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
sg4 = 0.25!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1876 template 24
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
sg4 = 0.35!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1877 template 24
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
sg4 = 0.45!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1878 template 24
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
sg4 = 1!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1879 template 24
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
sg4 = -1!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1880 template 24
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
sg4 = 1.5!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1881 template 24
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
sg4 = 2.5!
Print #2, "24 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(24); sg1; sg2; sg3; sg4
' 1882 template 24
db1 = 0#
db2 = 0.005#
db3 = 0.45#
db4 = 9.995#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1883 template 24
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
db4 = 10#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1884 template 24
db1 = 0.5#
db2 = 0.15#
db3 = -1#
db4 = 99.995#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1885 template 24
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
db4 = 99.9999#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1886 template 24
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
db4 = 123.456#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1887 template 24
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
db4 = -123.456#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1888 template 24
db1 = 0.0005#
db2 = 1#
db3 = 10#
db4 = 999.95#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1889 template 24
db1 = 0.15#
db2 = -1#
db3 = 99.995#
db4 = 1234.5678#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1890 template 24
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
db4 = 12345.678#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1891 template 24
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
db4 = 99999.9#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1892 template 24
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
db4 = 0.1#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1893 template 24
db1 = 1#
db2 = 10#
db3 = 999.95#
db4 = 0.00001#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1894 template 24
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
db4 = 0.000000123#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1895 template 24
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
db4 = 0.0000000001#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1896 template 24
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
db4 = 100000#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1897 template 24
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
db4 = 10000000000#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1898 template 24
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
db4 = 9999999999999999#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1899 template 24
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
db4 = 1E+17#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1900 template 24
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
db4 = 1E+20#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1901 template 24
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
db4 = 1E+30#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1902 template 24
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
db4 = -2.5E-30#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1903 template 24
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
db4 = 1E+300#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1904 template 24
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
db4 = DblBits(&h7FF8000000000000ULL)
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1905 template 24
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
db4 = DblBits(&hFFF8000000000000ULL)
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1906 template 24
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
db4 = DblBits(&h7FF0000000000000ULL)
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1907 template 24
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
db4 = DblBits(&hFFF0000000000000ULL)
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1908 template 24
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
db4 = DblBits(&h1ULL)
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1909 template 24
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
db4 = DblBits(&h8000000000000001ULL)
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1910 template 24
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
db4 = 0#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1911 template 24
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
db4 = DblBits(&h8000000000000000ULL)
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1912 template 24
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
db4 = 0.5#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1913 template 24
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
db4 = -0.5#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1914 template 24
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
db4 = 0.05#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1915 template 24
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
db4 = 0.005#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1916 template 24
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
db4 = 0.0005#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1917 template 24
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
db4 = 0.15#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1918 template 24
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
db4 = 0.25#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1919 template 24
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
db4 = 0.35#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1920 template 24
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
db4 = 0.45#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1921 template 24
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
db4 = 1#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1922 template 24
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
db4 = -1#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1923 template 24
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
db4 = 1.5#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1924 template 24
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
db4 = 2.5#
Print #2, "24 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(24); db1; db2; db3; db4
' 1925 template 25
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
sg4 = 9.995!
st5 = "a string longer than any field"
sg6 = 0.1!
st7 = "12345678901234567890"
sg8 = -2.5E-30!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1926 template 25
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
sg4 = 10!
st5 = " lead"
sg6 = 0.00001!
st7 = "x y"
sg8 = SngBits(&h7FC00000)
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1927 template 25
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
sg4 = 99.995!
st5 = "12345678901234567890"
sg6 = 0.000000123!
st7 = ""
sg8 = SngBits(&hFFC00000)
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1928 template 25
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
sg4 = 99.9999!
st5 = "x y"
sg6 = 0.0000000001!
st7 = "A"
sg8 = SngBits(&h7F800000)
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1929 template 25
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
sg4 = 123.456!
st5 = ""
sg6 = 100000!
st7 = "abc"
sg8 = SngBits(&hFF800000)
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1930 template 25
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
sg4 = -123.456!
st5 = "A"
sg6 = 10000000000!
st7 = "exactly14chars"
sg8 = SngBits(&h1)
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1931 template 25
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
sg4 = 999.95!
st5 = "abc"
sg6 = 9999999999999999!
st7 = "a string longer than any field"
sg8 = SngBits(&h80000001)
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1932 template 25
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
sg4 = 1234.5678!
st5 = "exactly14chars"
sg6 = 1E+17!
st7 = " lead"
sg8 = 0
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1933 template 25
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
sg4 = 12345.678!
st5 = "a string longer than any field"
sg6 = 1E+20!
st7 = "12345678901234567890"
sg8 = SngBits(&h80000000)
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1934 template 25
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
sg4 = 99999.9!
st5 = " lead"
sg6 = 1E+30!
st7 = "x y"
sg8 = 0.5!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1935 template 25
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
sg4 = 0.1!
st5 = "12345678901234567890"
sg6 = -2.5E-30!
st7 = ""
sg8 = -0.5!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1936 template 25
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
sg4 = 0.00001!
st5 = "x y"
sg6 = SngBits(&h7FC00000)
st7 = "A"
sg8 = 0.05!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1937 template 25
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
sg4 = 0.000000123!
st5 = ""
sg6 = SngBits(&hFFC00000)
st7 = "abc"
sg8 = 0.005!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1938 template 25
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
sg4 = 0.0000000001!
st5 = "A"
sg6 = SngBits(&h7F800000)
st7 = "exactly14chars"
sg8 = 0.0005!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1939 template 25
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
sg4 = 100000!
st5 = "abc"
sg6 = SngBits(&hFF800000)
st7 = "a string longer than any field"
sg8 = 0.15!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1940 template 25
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
sg4 = 10000000000!
st5 = "exactly14chars"
sg6 = SngBits(&h1)
st7 = " lead"
sg8 = 0.25!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1941 template 25
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
sg4 = 9999999999999999!
st5 = "a string longer than any field"
sg6 = SngBits(&h80000001)
st7 = "12345678901234567890"
sg8 = 0.35!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1942 template 25
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
sg4 = 1E+17!
st5 = " lead"
sg6 = 0
st7 = "x y"
sg8 = 0.45!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1943 template 25
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
sg4 = 1E+20!
st5 = "12345678901234567890"
sg6 = SngBits(&h80000000)
st7 = ""
sg8 = 1!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1944 template 25
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
sg4 = 1E+30!
st5 = "x y"
sg6 = 0.5!
st7 = "A"
sg8 = -1!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1945 template 25
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
sg4 = -2.5E-30!
st5 = ""
sg6 = -0.5!
st7 = "abc"
sg8 = 1.5!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1946 template 25
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
sg4 = SngBits(&h7FC00000)
st5 = "A"
sg6 = 0.05!
st7 = "exactly14chars"
sg8 = 2.5!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1947 template 25
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
sg4 = SngBits(&hFFC00000)
st5 = "abc"
sg6 = 0.005!
st7 = "a string longer than any field"
sg8 = 9.995!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1948 template 25
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
sg4 = SngBits(&h7F800000)
st5 = "exactly14chars"
sg6 = 0.0005!
st7 = " lead"
sg8 = 10!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1949 template 25
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
sg4 = SngBits(&hFF800000)
st5 = "a string longer than any field"
sg6 = 0.15!
st7 = "12345678901234567890"
sg8 = 99.995!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1950 template 25
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
sg4 = SngBits(&h1)
st5 = " lead"
sg6 = 0.25!
st7 = "x y"
sg8 = 99.9999!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1951 template 25
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
sg4 = SngBits(&h80000001)
st5 = "12345678901234567890"
sg6 = 0.35!
st7 = ""
sg8 = 123.456!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1952 template 25
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
sg4 = 0
st5 = "x y"
sg6 = 0.45!
st7 = "A"
sg8 = -123.456!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1953 template 25
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
sg4 = SngBits(&h80000000)
st5 = ""
sg6 = 1!
st7 = "abc"
sg8 = 999.95!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1954 template 25
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
sg4 = 0.5!
st5 = "A"
sg6 = -1!
st7 = "exactly14chars"
sg8 = 1234.5678!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1955 template 25
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
sg4 = -0.5!
st5 = "abc"
sg6 = 1.5!
st7 = "a string longer than any field"
sg8 = 12345.678!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1956 template 25
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
sg4 = 0.05!
st5 = "exactly14chars"
sg6 = 2.5!
st7 = " lead"
sg8 = 99999.9!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1957 template 25
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
sg4 = 0.005!
st5 = "a string longer than any field"
sg6 = 9.995!
st7 = "12345678901234567890"
sg8 = 0.1!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1958 template 25
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
sg4 = 0.0005!
st5 = " lead"
sg6 = 10!
st7 = "x y"
sg8 = 0.00001!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1959 template 25
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
sg4 = 0.15!
st5 = "12345678901234567890"
sg6 = 99.995!
st7 = ""
sg8 = 0.000000123!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1960 template 25
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
sg4 = 0.25!
st5 = "x y"
sg6 = 99.9999!
st7 = "A"
sg8 = 0.0000000001!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1961 template 25
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
sg4 = 0.35!
st5 = ""
sg6 = 123.456!
st7 = "abc"
sg8 = 100000!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1962 template 25
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
sg4 = 0.45!
st5 = "A"
sg6 = -123.456!
st7 = "exactly14chars"
sg8 = 10000000000!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1963 template 25
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
sg4 = 1!
st5 = "abc"
sg6 = 999.95!
st7 = "a string longer than any field"
sg8 = 9999999999999999!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1964 template 25
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
sg4 = -1!
st5 = "exactly14chars"
sg6 = 1234.5678!
st7 = " lead"
sg8 = 1E+17!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1965 template 25
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
sg4 = 1.5!
st5 = "a string longer than any field"
sg6 = 12345.678!
st7 = "12345678901234567890"
sg8 = 1E+20!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1966 template 25
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
sg4 = 2.5!
st5 = " lead"
sg6 = 99999.9!
st7 = "x y"
sg8 = 1E+30!
Print #2, "25 8" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6) & " " & "s:" & BHex(st7) & " " & "f:" & SHex(sg8)
Print #1, Using tpl(25); sg1; sg2; sg3; sg4; st5; sg6; st7; sg8
' 1967 template 25
db1 = 0#
db2 = 0.005#
db3 = 0.45#
db4 = 9.995#
st5 = "a string longer than any field"
db6 = 0.1#
st7 = "12345678901234567890"
db8 = -2.5E-30#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1968 template 25
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
db4 = 10#
st5 = " lead"
db6 = 0.00001#
st7 = "x y"
db8 = 1E+300#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1969 template 25
db1 = 0.5#
db2 = 0.15#
db3 = -1#
db4 = 99.995#
st5 = "12345678901234567890"
db6 = 0.000000123#
st7 = ""
db8 = DblBits(&h7FF8000000000000ULL)
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1970 template 25
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
db4 = 99.9999#
st5 = "x y"
db6 = 0.0000000001#
st7 = "A"
db8 = DblBits(&hFFF8000000000000ULL)
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1971 template 25
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
db4 = 123.456#
st5 = ""
db6 = 100000#
st7 = "abc"
db8 = DblBits(&h7FF0000000000000ULL)
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1972 template 25
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
db4 = -123.456#
st5 = "A"
db6 = 10000000000#
st7 = "exactly14chars"
db8 = DblBits(&hFFF0000000000000ULL)
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1973 template 25
db1 = 0.0005#
db2 = 1#
db3 = 10#
db4 = 999.95#
st5 = "abc"
db6 = 9999999999999999#
st7 = "a string longer than any field"
db8 = DblBits(&h1ULL)
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1974 template 25
db1 = 0.15#
db2 = -1#
db3 = 99.995#
db4 = 1234.5678#
st5 = "exactly14chars"
db6 = 1E+17#
st7 = " lead"
db8 = DblBits(&h8000000000000001ULL)
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1975 template 25
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
db4 = 12345.678#
st5 = "a string longer than any field"
db6 = 1E+20#
st7 = "12345678901234567890"
db8 = 0#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1976 template 25
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
db4 = 99999.9#
st5 = " lead"
db6 = 1E+30#
st7 = "x y"
db8 = DblBits(&h8000000000000000ULL)
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1977 template 25
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
db4 = 0.1#
st5 = "12345678901234567890"
db6 = -2.5E-30#
st7 = ""
db8 = 0.5#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1978 template 25
db1 = 1#
db2 = 10#
db3 = 999.95#
db4 = 0.00001#
st5 = "x y"
db6 = 1E+300#
st7 = "A"
db8 = -0.5#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1979 template 25
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
db4 = 0.000000123#
st5 = ""
db6 = DblBits(&h7FF8000000000000ULL)
st7 = "abc"
db8 = 0.05#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1980 template 25
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
db4 = 0.0000000001#
st5 = "A"
db6 = DblBits(&hFFF8000000000000ULL)
st7 = "exactly14chars"
db8 = 0.005#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1981 template 25
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
db4 = 100000#
st5 = "abc"
db6 = DblBits(&h7FF0000000000000ULL)
st7 = "a string longer than any field"
db8 = 0.0005#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1982 template 25
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
db4 = 10000000000#
st5 = "exactly14chars"
db6 = DblBits(&hFFF0000000000000ULL)
st7 = " lead"
db8 = 0.15#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1983 template 25
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
db4 = 9999999999999999#
st5 = "a string longer than any field"
db6 = DblBits(&h1ULL)
st7 = "12345678901234567890"
db8 = 0.25#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1984 template 25
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
db4 = 1E+17#
st5 = " lead"
db6 = DblBits(&h8000000000000001ULL)
st7 = "x y"
db8 = 0.35#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1985 template 25
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
db4 = 1E+20#
st5 = "12345678901234567890"
db6 = 0#
st7 = ""
db8 = 0.45#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1986 template 25
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
db4 = 1E+30#
st5 = "x y"
db6 = DblBits(&h8000000000000000ULL)
st7 = "A"
db8 = 1#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1987 template 25
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
db4 = -2.5E-30#
st5 = ""
db6 = 0.5#
st7 = "abc"
db8 = -1#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1988 template 25
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
db4 = 1E+300#
st5 = "A"
db6 = -0.5#
st7 = "exactly14chars"
db8 = 1.5#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1989 template 25
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
db4 = DblBits(&h7FF8000000000000ULL)
st5 = "abc"
db6 = 0.05#
st7 = "a string longer than any field"
db8 = 2.5#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1990 template 25
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
db4 = DblBits(&hFFF8000000000000ULL)
st5 = "exactly14chars"
db6 = 0.005#
st7 = " lead"
db8 = 9.995#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1991 template 25
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
db4 = DblBits(&h7FF0000000000000ULL)
st5 = "a string longer than any field"
db6 = 0.0005#
st7 = "12345678901234567890"
db8 = 10#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1992 template 25
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
db4 = DblBits(&hFFF0000000000000ULL)
st5 = " lead"
db6 = 0.15#
st7 = "x y"
db8 = 99.995#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1993 template 25
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
db4 = DblBits(&h1ULL)
st5 = "12345678901234567890"
db6 = 0.25#
st7 = ""
db8 = 99.9999#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1994 template 25
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
db4 = DblBits(&h8000000000000001ULL)
st5 = "x y"
db6 = 0.35#
st7 = "A"
db8 = 123.456#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1995 template 25
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
db4 = 0#
st5 = ""
db6 = 0.45#
st7 = "abc"
db8 = -123.456#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1996 template 25
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
db4 = DblBits(&h8000000000000000ULL)
st5 = "A"
db6 = 1#
st7 = "exactly14chars"
db8 = 999.95#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1997 template 25
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
db4 = 0.5#
st5 = "abc"
db6 = -1#
st7 = "a string longer than any field"
db8 = 1234.5678#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1998 template 25
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
db4 = -0.5#
st5 = "exactly14chars"
db6 = 1.5#
st7 = " lead"
db8 = 12345.678#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 1999 template 25
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
db4 = 0.05#
st5 = "a string longer than any field"
db6 = 2.5#
st7 = "12345678901234567890"
db8 = 99999.9#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2000 template 25
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
db4 = 0.005#
st5 = " lead"
db6 = 9.995#
st7 = "x y"
db8 = 0.1#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2001 template 25
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
db4 = 0.0005#
st5 = "12345678901234567890"
db6 = 10#
st7 = ""
db8 = 0.00001#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2002 template 25
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
db4 = 0.15#
st5 = "x y"
db6 = 99.995#
st7 = "A"
db8 = 0.000000123#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2003 template 25
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
db4 = 0.25#
st5 = ""
db6 = 99.9999#
st7 = "abc"
db8 = 0.0000000001#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2004 template 25
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
db4 = 0.35#
st5 = "A"
db6 = 123.456#
st7 = "exactly14chars"
db8 = 100000#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2005 template 25
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
db4 = 0.45#
st5 = "abc"
db6 = -123.456#
st7 = "a string longer than any field"
db8 = 10000000000#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2006 template 25
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
db4 = 1#
st5 = "exactly14chars"
db6 = 999.95#
st7 = " lead"
db8 = 9999999999999999#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2007 template 25
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
db4 = -1#
st5 = "a string longer than any field"
db6 = 1234.5678#
st7 = "12345678901234567890"
db8 = 1E+17#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2008 template 25
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
db4 = 1.5#
st5 = " lead"
db6 = 12345.678#
st7 = "x y"
db8 = 1E+20#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2009 template 25
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
db4 = 2.5#
st5 = "12345678901234567890"
db6 = 99999.9#
st7 = ""
db8 = 1E+30#
Print #2, "25 8" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6) & " " & "s:" & BHex(st7) & " " & "d:" & DHex(db8)
Print #1, Using tpl(25); db1; db2; db3; db4; st5; db6; st7; db8
' 2010 template 26
sg1 = 0
sg2 = 0.005!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2011 template 26
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2012 template 26
sg1 = 0.5!
sg2 = 0.15!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2013 template 26
sg1 = -0.5!
sg2 = 0.25!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2014 template 26
sg1 = 0.05!
sg2 = 0.35!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2015 template 26
sg1 = 0.005!
sg2 = 0.45!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2016 template 26
sg1 = 0.0005!
sg2 = 1!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2017 template 26
sg1 = 0.15!
sg2 = -1!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2018 template 26
sg1 = 0.25!
sg2 = 1.5!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2019 template 26
sg1 = 0.35!
sg2 = 2.5!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2020 template 26
sg1 = 0.45!
sg2 = 9.995!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2021 template 26
sg1 = 1!
sg2 = 10!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2022 template 26
sg1 = -1!
sg2 = 99.995!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2023 template 26
sg1 = 1.5!
sg2 = 99.9999!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2024 template 26
sg1 = 2.5!
sg2 = 123.456!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2025 template 26
sg1 = 9.995!
sg2 = -123.456!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2026 template 26
sg1 = 10!
sg2 = 999.95!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2027 template 26
sg1 = 99.995!
sg2 = 1234.5678!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2028 template 26
sg1 = 99.9999!
sg2 = 12345.678!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2029 template 26
sg1 = 123.456!
sg2 = 99999.9!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2030 template 26
sg1 = -123.456!
sg2 = 0.1!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2031 template 26
sg1 = 999.95!
sg2 = 0.00001!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2032 template 26
sg1 = 1234.5678!
sg2 = 0.000000123!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2033 template 26
sg1 = 12345.678!
sg2 = 0.0000000001!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2034 template 26
sg1 = 99999.9!
sg2 = 100000!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2035 template 26
sg1 = 0.1!
sg2 = 10000000000!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2036 template 26
sg1 = 0.00001!
sg2 = 9999999999999999!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2037 template 26
sg1 = 0.000000123!
sg2 = 1E+17!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2038 template 26
sg1 = 0.0000000001!
sg2 = 1E+20!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2039 template 26
sg1 = 100000!
sg2 = 1E+30!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2040 template 26
sg1 = 10000000000!
sg2 = -2.5E-30!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2041 template 26
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2042 template 26
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2043 template 26
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2044 template 26
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2045 template 26
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2046 template 26
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2047 template 26
sg1 = SngBits(&hFFC00000)
sg2 = 0
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2048 template 26
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2049 template 26
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2050 template 26
sg1 = SngBits(&h1)
sg2 = -0.5!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2051 template 26
sg1 = SngBits(&h80000001)
sg2 = 0.05!
Print #2, "26 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(26); sg1; sg2
' 2052 template 26
db1 = 0#
db2 = 0.005#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2053 template 26
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2054 template 26
db1 = 0.5#
db2 = 0.15#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2055 template 26
db1 = -0.5#
db2 = 0.25#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2056 template 26
db1 = 0.05#
db2 = 0.35#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2057 template 26
db1 = 0.005#
db2 = 0.45#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2058 template 26
db1 = 0.0005#
db2 = 1#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2059 template 26
db1 = 0.15#
db2 = -1#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2060 template 26
db1 = 0.25#
db2 = 1.5#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2061 template 26
db1 = 0.35#
db2 = 2.5#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2062 template 26
db1 = 0.45#
db2 = 9.995#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2063 template 26
db1 = 1#
db2 = 10#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2064 template 26
db1 = -1#
db2 = 99.995#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2065 template 26
db1 = 1.5#
db2 = 99.9999#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2066 template 26
db1 = 2.5#
db2 = 123.456#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2067 template 26
db1 = 9.995#
db2 = -123.456#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2068 template 26
db1 = 10#
db2 = 999.95#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2069 template 26
db1 = 99.995#
db2 = 1234.5678#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2070 template 26
db1 = 99.9999#
db2 = 12345.678#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2071 template 26
db1 = 123.456#
db2 = 99999.9#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2072 template 26
db1 = -123.456#
db2 = 0.1#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2073 template 26
db1 = 999.95#
db2 = 0.00001#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2074 template 26
db1 = 1234.5678#
db2 = 0.000000123#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2075 template 26
db1 = 12345.678#
db2 = 0.0000000001#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2076 template 26
db1 = 99999.9#
db2 = 100000#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2077 template 26
db1 = 0.1#
db2 = 10000000000#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2078 template 26
db1 = 0.00001#
db2 = 9999999999999999#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2079 template 26
db1 = 0.000000123#
db2 = 1E+17#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2080 template 26
db1 = 0.0000000001#
db2 = 1E+20#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2081 template 26
db1 = 100000#
db2 = 1E+30#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2082 template 26
db1 = 10000000000#
db2 = -2.5E-30#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2083 template 26
db1 = 9999999999999999#
db2 = 1E+300#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2084 template 26
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2085 template 26
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2086 template 26
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2087 template 26
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2088 template 26
db1 = 1E+300#
db2 = DblBits(&h1ULL)
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2089 template 26
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2090 template 26
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2091 template 26
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2092 template 26
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2093 template 26
db1 = DblBits(&h1ULL)
db2 = -0.5#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2094 template 26
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
Print #2, "26 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(26); db1; db2
' 2095 template 27
sg1 = 0
sg2 = 0.005!
st3 = "abc"
sg4 = 9.995!
st5 = "a string longer than any field"
sg6 = 0.1!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2096 template 27
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
st3 = "exactly14chars"
sg4 = 10!
st5 = " lead"
sg6 = 0.00001!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2097 template 27
sg1 = 0.5!
sg2 = 0.15!
st3 = "a string longer than any field"
sg4 = 99.995!
st5 = "12345678901234567890"
sg6 = 0.000000123!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2098 template 27
sg1 = -0.5!
sg2 = 0.25!
st3 = " lead"
sg4 = 99.9999!
st5 = "x y"
sg6 = 0.0000000001!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2099 template 27
sg1 = 0.05!
sg2 = 0.35!
st3 = "12345678901234567890"
sg4 = 123.456!
st5 = ""
sg6 = 100000!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2100 template 27
sg1 = 0.005!
sg2 = 0.45!
st3 = "x y"
sg4 = -123.456!
st5 = "A"
sg6 = 10000000000!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2101 template 27
sg1 = 0.0005!
sg2 = 1!
st3 = ""
sg4 = 999.95!
st5 = "abc"
sg6 = 9999999999999999!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2102 template 27
sg1 = 0.15!
sg2 = -1!
st3 = "A"
sg4 = 1234.5678!
st5 = "exactly14chars"
sg6 = 1E+17!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2103 template 27
sg1 = 0.25!
sg2 = 1.5!
st3 = "abc"
sg4 = 12345.678!
st5 = "a string longer than any field"
sg6 = 1E+20!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2104 template 27
sg1 = 0.35!
sg2 = 2.5!
st3 = "exactly14chars"
sg4 = 99999.9!
st5 = " lead"
sg6 = 1E+30!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2105 template 27
sg1 = 0.45!
sg2 = 9.995!
st3 = "a string longer than any field"
sg4 = 0.1!
st5 = "12345678901234567890"
sg6 = -2.5E-30!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2106 template 27
sg1 = 1!
sg2 = 10!
st3 = " lead"
sg4 = 0.00001!
st5 = "x y"
sg6 = SngBits(&h7FC00000)
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2107 template 27
sg1 = -1!
sg2 = 99.995!
st3 = "12345678901234567890"
sg4 = 0.000000123!
st5 = ""
sg6 = SngBits(&hFFC00000)
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2108 template 27
sg1 = 1.5!
sg2 = 99.9999!
st3 = "x y"
sg4 = 0.0000000001!
st5 = "A"
sg6 = SngBits(&h7F800000)
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2109 template 27
sg1 = 2.5!
sg2 = 123.456!
st3 = ""
sg4 = 100000!
st5 = "abc"
sg6 = SngBits(&hFF800000)
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2110 template 27
sg1 = 9.995!
sg2 = -123.456!
st3 = "A"
sg4 = 10000000000!
st5 = "exactly14chars"
sg6 = SngBits(&h1)
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2111 template 27
sg1 = 10!
sg2 = 999.95!
st3 = "abc"
sg4 = 9999999999999999!
st5 = "a string longer than any field"
sg6 = SngBits(&h80000001)
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2112 template 27
sg1 = 99.995!
sg2 = 1234.5678!
st3 = "exactly14chars"
sg4 = 1E+17!
st5 = " lead"
sg6 = 0
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2113 template 27
sg1 = 99.9999!
sg2 = 12345.678!
st3 = "a string longer than any field"
sg4 = 1E+20!
st5 = "12345678901234567890"
sg6 = SngBits(&h80000000)
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2114 template 27
sg1 = 123.456!
sg2 = 99999.9!
st3 = " lead"
sg4 = 1E+30!
st5 = "x y"
sg6 = 0.5!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2115 template 27
sg1 = -123.456!
sg2 = 0.1!
st3 = "12345678901234567890"
sg4 = -2.5E-30!
st5 = ""
sg6 = -0.5!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2116 template 27
sg1 = 999.95!
sg2 = 0.00001!
st3 = "x y"
sg4 = SngBits(&h7FC00000)
st5 = "A"
sg6 = 0.05!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2117 template 27
sg1 = 1234.5678!
sg2 = 0.000000123!
st3 = ""
sg4 = SngBits(&hFFC00000)
st5 = "abc"
sg6 = 0.005!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2118 template 27
sg1 = 12345.678!
sg2 = 0.0000000001!
st3 = "A"
sg4 = SngBits(&h7F800000)
st5 = "exactly14chars"
sg6 = 0.0005!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2119 template 27
sg1 = 99999.9!
sg2 = 100000!
st3 = "abc"
sg4 = SngBits(&hFF800000)
st5 = "a string longer than any field"
sg6 = 0.15!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2120 template 27
sg1 = 0.1!
sg2 = 10000000000!
st3 = "exactly14chars"
sg4 = SngBits(&h1)
st5 = " lead"
sg6 = 0.25!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2121 template 27
sg1 = 0.00001!
sg2 = 9999999999999999!
st3 = "a string longer than any field"
sg4 = SngBits(&h80000001)
st5 = "12345678901234567890"
sg6 = 0.35!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2122 template 27
sg1 = 0.000000123!
sg2 = 1E+17!
st3 = " lead"
sg4 = 0
st5 = "x y"
sg6 = 0.45!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2123 template 27
sg1 = 0.0000000001!
sg2 = 1E+20!
st3 = "12345678901234567890"
sg4 = SngBits(&h80000000)
st5 = ""
sg6 = 1!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2124 template 27
sg1 = 100000!
sg2 = 1E+30!
st3 = "x y"
sg4 = 0.5!
st5 = "A"
sg6 = -1!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2125 template 27
sg1 = 10000000000!
sg2 = -2.5E-30!
st3 = ""
sg4 = -0.5!
st5 = "abc"
sg6 = 1.5!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2126 template 27
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
st3 = "A"
sg4 = 0.05!
st5 = "exactly14chars"
sg6 = 2.5!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2127 template 27
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
st3 = "abc"
sg4 = 0.005!
st5 = "a string longer than any field"
sg6 = 9.995!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2128 template 27
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
st3 = "exactly14chars"
sg4 = 0.0005!
st5 = " lead"
sg6 = 10!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2129 template 27
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
st3 = "a string longer than any field"
sg4 = 0.15!
st5 = "12345678901234567890"
sg6 = 99.995!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2130 template 27
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
st3 = " lead"
sg4 = 0.25!
st5 = "x y"
sg6 = 99.9999!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2131 template 27
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
st3 = "12345678901234567890"
sg4 = 0.35!
st5 = ""
sg6 = 123.456!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2132 template 27
sg1 = SngBits(&hFFC00000)
sg2 = 0
st3 = "x y"
sg4 = 0.45!
st5 = "A"
sg6 = -123.456!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2133 template 27
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
st3 = ""
sg4 = 1!
st5 = "abc"
sg6 = 999.95!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2134 template 27
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
st3 = "A"
sg4 = -1!
st5 = "exactly14chars"
sg6 = 1234.5678!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2135 template 27
sg1 = SngBits(&h1)
sg2 = -0.5!
st3 = "abc"
sg4 = 1.5!
st5 = "a string longer than any field"
sg6 = 12345.678!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2136 template 27
sg1 = SngBits(&h80000001)
sg2 = 0.05!
st3 = "exactly14chars"
sg4 = 2.5!
st5 = " lead"
sg6 = 99999.9!
Print #2, "27 6" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "s:" & BHex(st3) & " " & "f:" & SHex(sg4) & " " & "s:" & BHex(st5) & " " & "f:" & SHex(sg6)
Print #1, Using tpl(27); sg1; sg2; st3; sg4; st5; sg6
' 2137 template 27
db1 = 0#
db2 = 0.005#
st3 = "abc"
db4 = 9.995#
st5 = "a string longer than any field"
db6 = 0.1#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2138 template 27
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
st3 = "exactly14chars"
db4 = 10#
st5 = " lead"
db6 = 0.00001#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2139 template 27
db1 = 0.5#
db2 = 0.15#
st3 = "a string longer than any field"
db4 = 99.995#
st5 = "12345678901234567890"
db6 = 0.000000123#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2140 template 27
db1 = -0.5#
db2 = 0.25#
st3 = " lead"
db4 = 99.9999#
st5 = "x y"
db6 = 0.0000000001#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2141 template 27
db1 = 0.05#
db2 = 0.35#
st3 = "12345678901234567890"
db4 = 123.456#
st5 = ""
db6 = 100000#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2142 template 27
db1 = 0.005#
db2 = 0.45#
st3 = "x y"
db4 = -123.456#
st5 = "A"
db6 = 10000000000#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2143 template 27
db1 = 0.0005#
db2 = 1#
st3 = ""
db4 = 999.95#
st5 = "abc"
db6 = 9999999999999999#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2144 template 27
db1 = 0.15#
db2 = -1#
st3 = "A"
db4 = 1234.5678#
st5 = "exactly14chars"
db6 = 1E+17#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2145 template 27
db1 = 0.25#
db2 = 1.5#
st3 = "abc"
db4 = 12345.678#
st5 = "a string longer than any field"
db6 = 1E+20#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2146 template 27
db1 = 0.35#
db2 = 2.5#
st3 = "exactly14chars"
db4 = 99999.9#
st5 = " lead"
db6 = 1E+30#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2147 template 27
db1 = 0.45#
db2 = 9.995#
st3 = "a string longer than any field"
db4 = 0.1#
st5 = "12345678901234567890"
db6 = -2.5E-30#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2148 template 27
db1 = 1#
db2 = 10#
st3 = " lead"
db4 = 0.00001#
st5 = "x y"
db6 = 1E+300#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2149 template 27
db1 = -1#
db2 = 99.995#
st3 = "12345678901234567890"
db4 = 0.000000123#
st5 = ""
db6 = DblBits(&h7FF8000000000000ULL)
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2150 template 27
db1 = 1.5#
db2 = 99.9999#
st3 = "x y"
db4 = 0.0000000001#
st5 = "A"
db6 = DblBits(&hFFF8000000000000ULL)
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2151 template 27
db1 = 2.5#
db2 = 123.456#
st3 = ""
db4 = 100000#
st5 = "abc"
db6 = DblBits(&h7FF0000000000000ULL)
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2152 template 27
db1 = 9.995#
db2 = -123.456#
st3 = "A"
db4 = 10000000000#
st5 = "exactly14chars"
db6 = DblBits(&hFFF0000000000000ULL)
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2153 template 27
db1 = 10#
db2 = 999.95#
st3 = "abc"
db4 = 9999999999999999#
st5 = "a string longer than any field"
db6 = DblBits(&h1ULL)
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2154 template 27
db1 = 99.995#
db2 = 1234.5678#
st3 = "exactly14chars"
db4 = 1E+17#
st5 = " lead"
db6 = DblBits(&h8000000000000001ULL)
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2155 template 27
db1 = 99.9999#
db2 = 12345.678#
st3 = "a string longer than any field"
db4 = 1E+20#
st5 = "12345678901234567890"
db6 = 0#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2156 template 27
db1 = 123.456#
db2 = 99999.9#
st3 = " lead"
db4 = 1E+30#
st5 = "x y"
db6 = DblBits(&h8000000000000000ULL)
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2157 template 27
db1 = -123.456#
db2 = 0.1#
st3 = "12345678901234567890"
db4 = -2.5E-30#
st5 = ""
db6 = 0.5#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2158 template 27
db1 = 999.95#
db2 = 0.00001#
st3 = "x y"
db4 = 1E+300#
st5 = "A"
db6 = -0.5#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2159 template 27
db1 = 1234.5678#
db2 = 0.000000123#
st3 = ""
db4 = DblBits(&h7FF8000000000000ULL)
st5 = "abc"
db6 = 0.05#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2160 template 27
db1 = 12345.678#
db2 = 0.0000000001#
st3 = "A"
db4 = DblBits(&hFFF8000000000000ULL)
st5 = "exactly14chars"
db6 = 0.005#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2161 template 27
db1 = 99999.9#
db2 = 100000#
st3 = "abc"
db4 = DblBits(&h7FF0000000000000ULL)
st5 = "a string longer than any field"
db6 = 0.0005#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2162 template 27
db1 = 0.1#
db2 = 10000000000#
st3 = "exactly14chars"
db4 = DblBits(&hFFF0000000000000ULL)
st5 = " lead"
db6 = 0.15#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2163 template 27
db1 = 0.00001#
db2 = 9999999999999999#
st3 = "a string longer than any field"
db4 = DblBits(&h1ULL)
st5 = "12345678901234567890"
db6 = 0.25#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2164 template 27
db1 = 0.000000123#
db2 = 1E+17#
st3 = " lead"
db4 = DblBits(&h8000000000000001ULL)
st5 = "x y"
db6 = 0.35#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2165 template 27
db1 = 0.0000000001#
db2 = 1E+20#
st3 = "12345678901234567890"
db4 = 0#
st5 = ""
db6 = 0.45#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2166 template 27
db1 = 100000#
db2 = 1E+30#
st3 = "x y"
db4 = DblBits(&h8000000000000000ULL)
st5 = "A"
db6 = 1#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2167 template 27
db1 = 10000000000#
db2 = -2.5E-30#
st3 = ""
db4 = 0.5#
st5 = "abc"
db6 = -1#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2168 template 27
db1 = 9999999999999999#
db2 = 1E+300#
st3 = "A"
db4 = -0.5#
st5 = "exactly14chars"
db6 = 1.5#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2169 template 27
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
st3 = "abc"
db4 = 0.05#
st5 = "a string longer than any field"
db6 = 2.5#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2170 template 27
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
st3 = "exactly14chars"
db4 = 0.005#
st5 = " lead"
db6 = 9.995#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2171 template 27
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
st3 = "a string longer than any field"
db4 = 0.0005#
st5 = "12345678901234567890"
db6 = 10#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2172 template 27
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
st3 = " lead"
db4 = 0.15#
st5 = "x y"
db6 = 99.995#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2173 template 27
db1 = 1E+300#
db2 = DblBits(&h1ULL)
st3 = "12345678901234567890"
db4 = 0.25#
st5 = ""
db6 = 99.9999#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2174 template 27
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
st3 = "x y"
db4 = 0.35#
st5 = "A"
db6 = 123.456#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2175 template 27
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
st3 = ""
db4 = 0.45#
st5 = "abc"
db6 = -123.456#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2176 template 27
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
st3 = "A"
db4 = 1#
st5 = "exactly14chars"
db6 = 999.95#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2177 template 27
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
st3 = "abc"
db4 = -1#
st5 = "a string longer than any field"
db6 = 1234.5678#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2178 template 27
db1 = DblBits(&h1ULL)
db2 = -0.5#
st3 = "exactly14chars"
db4 = 1.5#
st5 = " lead"
db6 = 12345.678#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2179 template 27
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
st3 = "a string longer than any field"
db4 = 2.5#
st5 = "12345678901234567890"
db6 = 99999.9#
Print #2, "27 6" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "s:" & BHex(st3) & " " & "d:" & DHex(db4) & " " & "s:" & BHex(st5) & " " & "d:" & DHex(db6)
Print #1, Using tpl(27); db1; db2; st3; db4; st5; db6
' 2180 template 28
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2181 template 28
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2182 template 28
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2183 template 28
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2184 template 28
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2185 template 28
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2186 template 28
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2187 template 28
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2188 template 28
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2189 template 28
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2190 template 28
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2191 template 28
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2192 template 28
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2193 template 28
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2194 template 28
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2195 template 28
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2196 template 28
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2197 template 28
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2198 template 28
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2199 template 28
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2200 template 28
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2201 template 28
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2202 template 28
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2203 template 28
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2204 template 28
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2205 template 28
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2206 template 28
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2207 template 28
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2208 template 28
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2209 template 28
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2210 template 28
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2211 template 28
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2212 template 28
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2213 template 28
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2214 template 28
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2215 template 28
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2216 template 28
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2217 template 28
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2218 template 28
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2219 template 28
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2220 template 28
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2221 template 28
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
Print #2, "28 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(28); sg1; sg2; sg3
' 2222 template 28
db1 = 0#
db2 = 0.005#
db3 = 0.45#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2223 template 28
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2224 template 28
db1 = 0.5#
db2 = 0.15#
db3 = -1#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2225 template 28
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2226 template 28
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2227 template 28
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2228 template 28
db1 = 0.0005#
db2 = 1#
db3 = 10#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2229 template 28
db1 = 0.15#
db2 = -1#
db3 = 99.995#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2230 template 28
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2231 template 28
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2232 template 28
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2233 template 28
db1 = 1#
db2 = 10#
db3 = 999.95#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2234 template 28
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2235 template 28
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2236 template 28
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2237 template 28
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2238 template 28
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2239 template 28
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2240 template 28
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2241 template 28
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2242 template 28
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2243 template 28
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2244 template 28
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2245 template 28
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2246 template 28
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2247 template 28
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2248 template 28
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2249 template 28
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2250 template 28
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2251 template 28
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2252 template 28
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2253 template 28
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2254 template 28
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2255 template 28
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2256 template 28
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2257 template 28
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2258 template 28
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2259 template 28
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2260 template 28
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2261 template 28
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2262 template 28
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2263 template 28
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2264 template 28
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
Print #2, "28 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(28); db1; db2; db3
' 2265 template 29
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
sg4 = 9.995!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2266 template 29
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
sg4 = 10!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2267 template 29
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
sg4 = 99.995!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2268 template 29
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
sg4 = 99.9999!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2269 template 29
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
sg4 = 123.456!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2270 template 29
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
sg4 = -123.456!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2271 template 29
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
sg4 = 999.95!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2272 template 29
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
sg4 = 1234.5678!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2273 template 29
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
sg4 = 12345.678!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2274 template 29
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
sg4 = 99999.9!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2275 template 29
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
sg4 = 0.1!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2276 template 29
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
sg4 = 0.00001!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2277 template 29
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
sg4 = 0.000000123!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2278 template 29
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
sg4 = 0.0000000001!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2279 template 29
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
sg4 = 100000!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2280 template 29
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
sg4 = 10000000000!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2281 template 29
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
sg4 = 9999999999999999!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2282 template 29
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
sg4 = 1E+17!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2283 template 29
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
sg4 = 1E+20!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2284 template 29
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
sg4 = 1E+30!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2285 template 29
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
sg4 = -2.5E-30!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2286 template 29
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
sg4 = SngBits(&h7FC00000)
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2287 template 29
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
sg4 = SngBits(&hFFC00000)
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2288 template 29
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
sg4 = SngBits(&h7F800000)
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2289 template 29
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
sg4 = SngBits(&hFF800000)
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2290 template 29
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
sg4 = SngBits(&h1)
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2291 template 29
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
sg4 = SngBits(&h80000001)
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2292 template 29
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
sg4 = 0
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2293 template 29
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
sg4 = SngBits(&h80000000)
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2294 template 29
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
sg4 = 0.5!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2295 template 29
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
sg4 = -0.5!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2296 template 29
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
sg4 = 0.05!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2297 template 29
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
sg4 = 0.005!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2298 template 29
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
sg4 = 0.0005!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2299 template 29
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
sg4 = 0.15!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2300 template 29
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
sg4 = 0.25!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2301 template 29
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
sg4 = 0.35!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2302 template 29
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
sg4 = 0.45!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2303 template 29
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
sg4 = 1!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2304 template 29
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
sg4 = -1!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2305 template 29
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
sg4 = 1.5!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2306 template 29
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
sg4 = 2.5!
Print #2, "29 4" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "f:" & SHex(sg4)
Print #1, Using tpl(29); sg1; sg2; sg3; sg4
' 2307 template 29
db1 = 0#
db2 = 0.005#
db3 = 0.45#
db4 = 9.995#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2308 template 29
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
db4 = 10#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2309 template 29
db1 = 0.5#
db2 = 0.15#
db3 = -1#
db4 = 99.995#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2310 template 29
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
db4 = 99.9999#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2311 template 29
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
db4 = 123.456#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2312 template 29
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
db4 = -123.456#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2313 template 29
db1 = 0.0005#
db2 = 1#
db3 = 10#
db4 = 999.95#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2314 template 29
db1 = 0.15#
db2 = -1#
db3 = 99.995#
db4 = 1234.5678#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2315 template 29
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
db4 = 12345.678#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2316 template 29
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
db4 = 99999.9#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2317 template 29
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
db4 = 0.1#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2318 template 29
db1 = 1#
db2 = 10#
db3 = 999.95#
db4 = 0.00001#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2319 template 29
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
db4 = 0.000000123#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2320 template 29
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
db4 = 0.0000000001#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2321 template 29
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
db4 = 100000#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2322 template 29
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
db4 = 10000000000#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2323 template 29
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
db4 = 9999999999999999#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2324 template 29
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
db4 = 1E+17#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2325 template 29
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
db4 = 1E+20#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2326 template 29
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
db4 = 1E+30#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2327 template 29
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
db4 = -2.5E-30#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2328 template 29
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
db4 = 1E+300#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2329 template 29
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
db4 = DblBits(&h7FF8000000000000ULL)
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2330 template 29
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
db4 = DblBits(&hFFF8000000000000ULL)
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2331 template 29
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
db4 = DblBits(&h7FF0000000000000ULL)
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2332 template 29
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
db4 = DblBits(&hFFF0000000000000ULL)
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2333 template 29
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
db4 = DblBits(&h1ULL)
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2334 template 29
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
db4 = DblBits(&h8000000000000001ULL)
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2335 template 29
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
db4 = 0#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2336 template 29
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
db4 = DblBits(&h8000000000000000ULL)
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2337 template 29
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
db4 = 0.5#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2338 template 29
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
db4 = -0.5#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2339 template 29
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
db4 = 0.05#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2340 template 29
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
db4 = 0.005#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2341 template 29
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
db4 = 0.0005#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2342 template 29
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
db4 = 0.15#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2343 template 29
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
db4 = 0.25#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2344 template 29
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
db4 = 0.35#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2345 template 29
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
db4 = 0.45#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2346 template 29
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
db4 = 1#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2347 template 29
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
db4 = -1#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2348 template 29
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
db4 = 1.5#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2349 template 29
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
db4 = 2.5#
Print #2, "29 4" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "d:" & DHex(db4)
Print #1, Using tpl(29); db1; db2; db3; db4
' 2350 template 30
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2351 template 30
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2352 template 30
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2353 template 30
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2354 template 30
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2355 template 30
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2356 template 30
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2357 template 30
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2358 template 30
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2359 template 30
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2360 template 30
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2361 template 30
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2362 template 30
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2363 template 30
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2364 template 30
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2365 template 30
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2366 template 30
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2367 template 30
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2368 template 30
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2369 template 30
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2370 template 30
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2371 template 30
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2372 template 30
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2373 template 30
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2374 template 30
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2375 template 30
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2376 template 30
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2377 template 30
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2378 template 30
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2379 template 30
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2380 template 30
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2381 template 30
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2382 template 30
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2383 template 30
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2384 template 30
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2385 template 30
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2386 template 30
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2387 template 30
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2388 template 30
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2389 template 30
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2390 template 30
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2391 template 30
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
Print #2, "30 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(30); sg1; sg2; sg3
' 2392 template 30
db1 = 0#
db2 = 0.005#
db3 = 0.45#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2393 template 30
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2394 template 30
db1 = 0.5#
db2 = 0.15#
db3 = -1#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2395 template 30
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2396 template 30
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2397 template 30
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2398 template 30
db1 = 0.0005#
db2 = 1#
db3 = 10#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2399 template 30
db1 = 0.15#
db2 = -1#
db3 = 99.995#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2400 template 30
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2401 template 30
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2402 template 30
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2403 template 30
db1 = 1#
db2 = 10#
db3 = 999.95#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2404 template 30
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2405 template 30
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2406 template 30
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2407 template 30
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2408 template 30
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2409 template 30
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2410 template 30
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2411 template 30
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2412 template 30
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2413 template 30
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2414 template 30
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2415 template 30
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2416 template 30
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2417 template 30
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2418 template 30
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2419 template 30
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2420 template 30
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2421 template 30
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2422 template 30
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2423 template 30
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2424 template 30
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2425 template 30
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2426 template 30
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2427 template 30
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2428 template 30
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2429 template 30
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2430 template 30
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2431 template 30
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2432 template 30
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2433 template 30
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2434 template 30
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
Print #2, "30 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(30); db1; db2; db3
' 2435 template 31
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2436 template 31
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2437 template 31
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2438 template 31
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2439 template 31
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2440 template 31
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2441 template 31
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2442 template 31
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2443 template 31
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2444 template 31
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2445 template 31
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2446 template 31
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2447 template 31
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2448 template 31
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2449 template 31
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2450 template 31
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2451 template 31
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2452 template 31
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2453 template 31
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2454 template 31
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2455 template 31
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2456 template 31
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2457 template 31
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2458 template 31
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2459 template 31
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2460 template 31
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2461 template 31
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2462 template 31
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2463 template 31
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2464 template 31
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2465 template 31
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2466 template 31
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2467 template 31
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2468 template 31
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2469 template 31
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2470 template 31
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2471 template 31
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2472 template 31
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2473 template 31
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2474 template 31
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2475 template 31
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2476 template 31
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
Print #2, "31 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(31); sg1; sg2; sg3
' 2477 template 31
db1 = 0#
db2 = 0.005#
db3 = 0.45#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2478 template 31
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2479 template 31
db1 = 0.5#
db2 = 0.15#
db3 = -1#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2480 template 31
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2481 template 31
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2482 template 31
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2483 template 31
db1 = 0.0005#
db2 = 1#
db3 = 10#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2484 template 31
db1 = 0.15#
db2 = -1#
db3 = 99.995#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2485 template 31
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2486 template 31
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2487 template 31
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2488 template 31
db1 = 1#
db2 = 10#
db3 = 999.95#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2489 template 31
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2490 template 31
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2491 template 31
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2492 template 31
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2493 template 31
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2494 template 31
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2495 template 31
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2496 template 31
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2497 template 31
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2498 template 31
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2499 template 31
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2500 template 31
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2501 template 31
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2502 template 31
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2503 template 31
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2504 template 31
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2505 template 31
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2506 template 31
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2507 template 31
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2508 template 31
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2509 template 31
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2510 template 31
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2511 template 31
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2512 template 31
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2513 template 31
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2514 template 31
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2515 template 31
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2516 template 31
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2517 template 31
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2518 template 31
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2519 template 31
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
Print #2, "31 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(31); db1; db2; db3
' 2520 template 32
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
st4 = "x y"
sg5 = -123.456!
st6 = "A"
sg7 = 10000000000!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2521 template 32
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
st4 = ""
sg5 = 999.95!
st6 = "abc"
sg7 = 9999999999999999!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2522 template 32
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
st4 = "A"
sg5 = 1234.5678!
st6 = "exactly14chars"
sg7 = 1E+17!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2523 template 32
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
st4 = "abc"
sg5 = 12345.678!
st6 = "a string longer than any field"
sg7 = 1E+20!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2524 template 32
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
st4 = "exactly14chars"
sg5 = 99999.9!
st6 = " lead"
sg7 = 1E+30!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2525 template 32
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
st4 = "a string longer than any field"
sg5 = 0.1!
st6 = "12345678901234567890"
sg7 = -2.5E-30!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2526 template 32
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
st4 = " lead"
sg5 = 0.00001!
st6 = "x y"
sg7 = SngBits(&h7FC00000)
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2527 template 32
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
st4 = "12345678901234567890"
sg5 = 0.000000123!
st6 = ""
sg7 = SngBits(&hFFC00000)
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2528 template 32
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
st4 = "x y"
sg5 = 0.0000000001!
st6 = "A"
sg7 = SngBits(&h7F800000)
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2529 template 32
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
st4 = ""
sg5 = 100000!
st6 = "abc"
sg7 = SngBits(&hFF800000)
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2530 template 32
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
st4 = "A"
sg5 = 10000000000!
st6 = "exactly14chars"
sg7 = SngBits(&h1)
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2531 template 32
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
st4 = "abc"
sg5 = 9999999999999999!
st6 = "a string longer than any field"
sg7 = SngBits(&h80000001)
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2532 template 32
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
st4 = "exactly14chars"
sg5 = 1E+17!
st6 = " lead"
sg7 = 0
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2533 template 32
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
st4 = "a string longer than any field"
sg5 = 1E+20!
st6 = "12345678901234567890"
sg7 = SngBits(&h80000000)
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2534 template 32
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
st4 = " lead"
sg5 = 1E+30!
st6 = "x y"
sg7 = 0.5!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2535 template 32
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
st4 = "12345678901234567890"
sg5 = -2.5E-30!
st6 = ""
sg7 = -0.5!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2536 template 32
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
st4 = "x y"
sg5 = SngBits(&h7FC00000)
st6 = "A"
sg7 = 0.05!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2537 template 32
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
st4 = ""
sg5 = SngBits(&hFFC00000)
st6 = "abc"
sg7 = 0.005!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2538 template 32
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
st4 = "A"
sg5 = SngBits(&h7F800000)
st6 = "exactly14chars"
sg7 = 0.0005!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2539 template 32
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
st4 = "abc"
sg5 = SngBits(&hFF800000)
st6 = "a string longer than any field"
sg7 = 0.15!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2540 template 32
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
st4 = "exactly14chars"
sg5 = SngBits(&h1)
st6 = " lead"
sg7 = 0.25!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2541 template 32
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
st4 = "a string longer than any field"
sg5 = SngBits(&h80000001)
st6 = "12345678901234567890"
sg7 = 0.35!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2542 template 32
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
st4 = " lead"
sg5 = 0
st6 = "x y"
sg7 = 0.45!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2543 template 32
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
st4 = "12345678901234567890"
sg5 = SngBits(&h80000000)
st6 = ""
sg7 = 1!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2544 template 32
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
st4 = "x y"
sg5 = 0.5!
st6 = "A"
sg7 = -1!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2545 template 32
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
st4 = ""
sg5 = -0.5!
st6 = "abc"
sg7 = 1.5!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2546 template 32
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
st4 = "A"
sg5 = 0.05!
st6 = "exactly14chars"
sg7 = 2.5!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2547 template 32
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
st4 = "abc"
sg5 = 0.005!
st6 = "a string longer than any field"
sg7 = 9.995!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2548 template 32
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
st4 = "exactly14chars"
sg5 = 0.0005!
st6 = " lead"
sg7 = 10!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2549 template 32
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
st4 = "a string longer than any field"
sg5 = 0.15!
st6 = "12345678901234567890"
sg7 = 99.995!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2550 template 32
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
st4 = " lead"
sg5 = 0.25!
st6 = "x y"
sg7 = 99.9999!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2551 template 32
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
st4 = "12345678901234567890"
sg5 = 0.35!
st6 = ""
sg7 = 123.456!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2552 template 32
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
st4 = "x y"
sg5 = 0.45!
st6 = "A"
sg7 = -123.456!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2553 template 32
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
st4 = ""
sg5 = 1!
st6 = "abc"
sg7 = 999.95!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2554 template 32
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
st4 = "A"
sg5 = -1!
st6 = "exactly14chars"
sg7 = 1234.5678!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2555 template 32
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
st4 = "abc"
sg5 = 1.5!
st6 = "a string longer than any field"
sg7 = 12345.678!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2556 template 32
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
st4 = "exactly14chars"
sg5 = 2.5!
st6 = " lead"
sg7 = 99999.9!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2557 template 32
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
st4 = "a string longer than any field"
sg5 = 9.995!
st6 = "12345678901234567890"
sg7 = 0.1!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2558 template 32
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
st4 = " lead"
sg5 = 10!
st6 = "x y"
sg7 = 0.00001!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2559 template 32
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
st4 = "12345678901234567890"
sg5 = 99.995!
st6 = ""
sg7 = 0.000000123!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2560 template 32
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
st4 = "x y"
sg5 = 99.9999!
st6 = "A"
sg7 = 0.0000000001!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2561 template 32
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
st4 = ""
sg5 = 123.456!
st6 = "abc"
sg7 = 100000!
Print #2, "32 7" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3) & " " & "s:" & BHex(st4) & " " & "f:" & SHex(sg5) & " " & "s:" & BHex(st6) & " " & "f:" & SHex(sg7)
Print #1, Using tpl(32); sg1; sg2; sg3; st4; sg5; st6; sg7
' 2562 template 32
db1 = 0#
db2 = 0.005#
db3 = 0.45#
st4 = "x y"
db5 = -123.456#
st6 = "A"
db7 = 10000000000#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2563 template 32
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
st4 = ""
db5 = 999.95#
st6 = "abc"
db7 = 9999999999999999#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2564 template 32
db1 = 0.5#
db2 = 0.15#
db3 = -1#
st4 = "A"
db5 = 1234.5678#
st6 = "exactly14chars"
db7 = 1E+17#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2565 template 32
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
st4 = "abc"
db5 = 12345.678#
st6 = "a string longer than any field"
db7 = 1E+20#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2566 template 32
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
st4 = "exactly14chars"
db5 = 99999.9#
st6 = " lead"
db7 = 1E+30#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2567 template 32
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
st4 = "a string longer than any field"
db5 = 0.1#
st6 = "12345678901234567890"
db7 = -2.5E-30#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2568 template 32
db1 = 0.0005#
db2 = 1#
db3 = 10#
st4 = " lead"
db5 = 0.00001#
st6 = "x y"
db7 = 1E+300#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2569 template 32
db1 = 0.15#
db2 = -1#
db3 = 99.995#
st4 = "12345678901234567890"
db5 = 0.000000123#
st6 = ""
db7 = DblBits(&h7FF8000000000000ULL)
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2570 template 32
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
st4 = "x y"
db5 = 0.0000000001#
st6 = "A"
db7 = DblBits(&hFFF8000000000000ULL)
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2571 template 32
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
st4 = ""
db5 = 100000#
st6 = "abc"
db7 = DblBits(&h7FF0000000000000ULL)
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2572 template 32
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
st4 = "A"
db5 = 10000000000#
st6 = "exactly14chars"
db7 = DblBits(&hFFF0000000000000ULL)
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2573 template 32
db1 = 1#
db2 = 10#
db3 = 999.95#
st4 = "abc"
db5 = 9999999999999999#
st6 = "a string longer than any field"
db7 = DblBits(&h1ULL)
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2574 template 32
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
st4 = "exactly14chars"
db5 = 1E+17#
st6 = " lead"
db7 = DblBits(&h8000000000000001ULL)
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2575 template 32
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
st4 = "a string longer than any field"
db5 = 1E+20#
st6 = "12345678901234567890"
db7 = 0#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2576 template 32
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
st4 = " lead"
db5 = 1E+30#
st6 = "x y"
db7 = DblBits(&h8000000000000000ULL)
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2577 template 32
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
st4 = "12345678901234567890"
db5 = -2.5E-30#
st6 = ""
db7 = 0.5#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2578 template 32
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
st4 = "x y"
db5 = 1E+300#
st6 = "A"
db7 = -0.5#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2579 template 32
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
st4 = ""
db5 = DblBits(&h7FF8000000000000ULL)
st6 = "abc"
db7 = 0.05#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2580 template 32
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
st4 = "A"
db5 = DblBits(&hFFF8000000000000ULL)
st6 = "exactly14chars"
db7 = 0.005#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2581 template 32
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
st4 = "abc"
db5 = DblBits(&h7FF0000000000000ULL)
st6 = "a string longer than any field"
db7 = 0.0005#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2582 template 32
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
st4 = "exactly14chars"
db5 = DblBits(&hFFF0000000000000ULL)
st6 = " lead"
db7 = 0.15#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2583 template 32
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
st4 = "a string longer than any field"
db5 = DblBits(&h1ULL)
st6 = "12345678901234567890"
db7 = 0.25#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2584 template 32
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
st4 = " lead"
db5 = DblBits(&h8000000000000001ULL)
st6 = "x y"
db7 = 0.35#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2585 template 32
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
st4 = "12345678901234567890"
db5 = 0#
st6 = ""
db7 = 0.45#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2586 template 32
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
st4 = "x y"
db5 = DblBits(&h8000000000000000ULL)
st6 = "A"
db7 = 1#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2587 template 32
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
st4 = ""
db5 = 0.5#
st6 = "abc"
db7 = -1#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2588 template 32
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
st4 = "A"
db5 = -0.5#
st6 = "exactly14chars"
db7 = 1.5#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2589 template 32
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
st4 = "abc"
db5 = 0.05#
st6 = "a string longer than any field"
db7 = 2.5#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2590 template 32
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
st4 = "exactly14chars"
db5 = 0.005#
st6 = " lead"
db7 = 9.995#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2591 template 32
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
st4 = "a string longer than any field"
db5 = 0.0005#
st6 = "12345678901234567890"
db7 = 10#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2592 template 32
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
st4 = " lead"
db5 = 0.15#
st6 = "x y"
db7 = 99.995#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2593 template 32
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
st4 = "12345678901234567890"
db5 = 0.25#
st6 = ""
db7 = 99.9999#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2594 template 32
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
st4 = "x y"
db5 = 0.35#
st6 = "A"
db7 = 123.456#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2595 template 32
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
st4 = ""
db5 = 0.45#
st6 = "abc"
db7 = -123.456#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2596 template 32
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
st4 = "A"
db5 = 1#
st6 = "exactly14chars"
db7 = 999.95#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2597 template 32
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
st4 = "abc"
db5 = -1#
st6 = "a string longer than any field"
db7 = 1234.5678#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2598 template 32
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
st4 = "exactly14chars"
db5 = 1.5#
st6 = " lead"
db7 = 12345.678#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2599 template 32
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
st4 = "a string longer than any field"
db5 = 2.5#
st6 = "12345678901234567890"
db7 = 99999.9#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2600 template 32
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
st4 = " lead"
db5 = 9.995#
st6 = "x y"
db7 = 0.1#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2601 template 32
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
st4 = "12345678901234567890"
db5 = 10#
st6 = ""
db7 = 0.00001#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2602 template 32
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
st4 = "x y"
db5 = 99.995#
st6 = "A"
db7 = 0.000000123#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2603 template 32
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
st4 = ""
db5 = 99.9999#
st6 = "abc"
db7 = 0.0000000001#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2604 template 32
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
st4 = "A"
db5 = 123.456#
st6 = "exactly14chars"
db7 = 100000#
Print #2, "32 7" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3) & " " & "s:" & BHex(st4) & " " & "d:" & DHex(db5) & " " & "s:" & BHex(st6) & " " & "d:" & DHex(db7)
Print #1, Using tpl(32); db1; db2; db3; st4; db5; st6; db7
' 2605 template 33
sg1 = 0
sg2 = 0.005!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2606 template 33
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2607 template 33
sg1 = 0.5!
sg2 = 0.15!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2608 template 33
sg1 = -0.5!
sg2 = 0.25!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2609 template 33
sg1 = 0.05!
sg2 = 0.35!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2610 template 33
sg1 = 0.005!
sg2 = 0.45!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2611 template 33
sg1 = 0.0005!
sg2 = 1!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2612 template 33
sg1 = 0.15!
sg2 = -1!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2613 template 33
sg1 = 0.25!
sg2 = 1.5!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2614 template 33
sg1 = 0.35!
sg2 = 2.5!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2615 template 33
sg1 = 0.45!
sg2 = 9.995!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2616 template 33
sg1 = 1!
sg2 = 10!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2617 template 33
sg1 = -1!
sg2 = 99.995!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2618 template 33
sg1 = 1.5!
sg2 = 99.9999!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2619 template 33
sg1 = 2.5!
sg2 = 123.456!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2620 template 33
sg1 = 9.995!
sg2 = -123.456!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2621 template 33
sg1 = 10!
sg2 = 999.95!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2622 template 33
sg1 = 99.995!
sg2 = 1234.5678!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2623 template 33
sg1 = 99.9999!
sg2 = 12345.678!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2624 template 33
sg1 = 123.456!
sg2 = 99999.9!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2625 template 33
sg1 = -123.456!
sg2 = 0.1!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2626 template 33
sg1 = 999.95!
sg2 = 0.00001!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2627 template 33
sg1 = 1234.5678!
sg2 = 0.000000123!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2628 template 33
sg1 = 12345.678!
sg2 = 0.0000000001!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2629 template 33
sg1 = 99999.9!
sg2 = 100000!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2630 template 33
sg1 = 0.1!
sg2 = 10000000000!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2631 template 33
sg1 = 0.00001!
sg2 = 9999999999999999!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2632 template 33
sg1 = 0.000000123!
sg2 = 1E+17!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2633 template 33
sg1 = 0.0000000001!
sg2 = 1E+20!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2634 template 33
sg1 = 100000!
sg2 = 1E+30!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2635 template 33
sg1 = 10000000000!
sg2 = -2.5E-30!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2636 template 33
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2637 template 33
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2638 template 33
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2639 template 33
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2640 template 33
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2641 template 33
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2642 template 33
sg1 = SngBits(&hFFC00000)
sg2 = 0
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2643 template 33
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2644 template 33
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2645 template 33
sg1 = SngBits(&h1)
sg2 = -0.5!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2646 template 33
sg1 = SngBits(&h80000001)
sg2 = 0.05!
Print #2, "33 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(33); sg1; sg2
' 2647 template 33
db1 = 0#
db2 = 0.005#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2648 template 33
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2649 template 33
db1 = 0.5#
db2 = 0.15#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2650 template 33
db1 = -0.5#
db2 = 0.25#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2651 template 33
db1 = 0.05#
db2 = 0.35#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2652 template 33
db1 = 0.005#
db2 = 0.45#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2653 template 33
db1 = 0.0005#
db2 = 1#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2654 template 33
db1 = 0.15#
db2 = -1#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2655 template 33
db1 = 0.25#
db2 = 1.5#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2656 template 33
db1 = 0.35#
db2 = 2.5#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2657 template 33
db1 = 0.45#
db2 = 9.995#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2658 template 33
db1 = 1#
db2 = 10#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2659 template 33
db1 = -1#
db2 = 99.995#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2660 template 33
db1 = 1.5#
db2 = 99.9999#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2661 template 33
db1 = 2.5#
db2 = 123.456#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2662 template 33
db1 = 9.995#
db2 = -123.456#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2663 template 33
db1 = 10#
db2 = 999.95#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2664 template 33
db1 = 99.995#
db2 = 1234.5678#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2665 template 33
db1 = 99.9999#
db2 = 12345.678#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2666 template 33
db1 = 123.456#
db2 = 99999.9#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2667 template 33
db1 = -123.456#
db2 = 0.1#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2668 template 33
db1 = 999.95#
db2 = 0.00001#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2669 template 33
db1 = 1234.5678#
db2 = 0.000000123#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2670 template 33
db1 = 12345.678#
db2 = 0.0000000001#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2671 template 33
db1 = 99999.9#
db2 = 100000#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2672 template 33
db1 = 0.1#
db2 = 10000000000#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2673 template 33
db1 = 0.00001#
db2 = 9999999999999999#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2674 template 33
db1 = 0.000000123#
db2 = 1E+17#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2675 template 33
db1 = 0.0000000001#
db2 = 1E+20#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2676 template 33
db1 = 100000#
db2 = 1E+30#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2677 template 33
db1 = 10000000000#
db2 = -2.5E-30#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2678 template 33
db1 = 9999999999999999#
db2 = 1E+300#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2679 template 33
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2680 template 33
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2681 template 33
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2682 template 33
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2683 template 33
db1 = 1E+300#
db2 = DblBits(&h1ULL)
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2684 template 33
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2685 template 33
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2686 template 33
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2687 template 33
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2688 template 33
db1 = DblBits(&h1ULL)
db2 = -0.5#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2689 template 33
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
Print #2, "33 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(33); db1; db2
' 2690 template 34
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2691 template 34
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2692 template 34
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2693 template 34
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2694 template 34
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2695 template 34
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2696 template 34
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2697 template 34
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2698 template 34
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2699 template 34
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2700 template 34
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2701 template 34
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2702 template 34
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2703 template 34
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2704 template 34
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2705 template 34
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2706 template 34
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2707 template 34
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2708 template 34
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2709 template 34
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2710 template 34
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2711 template 34
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2712 template 34
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2713 template 34
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2714 template 34
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2715 template 34
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2716 template 34
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2717 template 34
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2718 template 34
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2719 template 34
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2720 template 34
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2721 template 34
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2722 template 34
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2723 template 34
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2724 template 34
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2725 template 34
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2726 template 34
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2727 template 34
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2728 template 34
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2729 template 34
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2730 template 34
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2731 template 34
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
Print #2, "34 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(34); sg1; sg2; sg3
' 2732 template 34
db1 = 0#
db2 = 0.005#
db3 = 0.45#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2733 template 34
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2734 template 34
db1 = 0.5#
db2 = 0.15#
db3 = -1#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2735 template 34
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2736 template 34
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2737 template 34
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2738 template 34
db1 = 0.0005#
db2 = 1#
db3 = 10#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2739 template 34
db1 = 0.15#
db2 = -1#
db3 = 99.995#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2740 template 34
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2741 template 34
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2742 template 34
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2743 template 34
db1 = 1#
db2 = 10#
db3 = 999.95#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2744 template 34
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2745 template 34
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2746 template 34
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2747 template 34
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2748 template 34
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2749 template 34
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2750 template 34
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2751 template 34
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2752 template 34
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2753 template 34
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2754 template 34
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2755 template 34
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2756 template 34
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2757 template 34
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2758 template 34
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2759 template 34
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2760 template 34
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2761 template 34
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2762 template 34
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2763 template 34
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2764 template 34
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2765 template 34
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2766 template 34
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2767 template 34
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2768 template 34
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2769 template 34
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2770 template 34
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2771 template 34
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2772 template 34
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2773 template 34
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2774 template 34
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
Print #2, "34 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(34); db1; db2; db3
' 2775 template 35
sg1 = 0
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2776 template 35
sg1 = SngBits(&h80000000)
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2777 template 35
sg1 = 0.5!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2778 template 35
sg1 = -0.5!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2779 template 35
sg1 = 0.05!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2780 template 35
sg1 = 0.005!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2781 template 35
sg1 = 0.0005!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2782 template 35
sg1 = 0.15!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2783 template 35
sg1 = 0.25!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2784 template 35
sg1 = 0.35!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2785 template 35
sg1 = 0.45!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2786 template 35
sg1 = 1!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2787 template 35
sg1 = -1!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2788 template 35
sg1 = 1.5!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2789 template 35
sg1 = 2.5!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2790 template 35
sg1 = 9.995!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2791 template 35
sg1 = 10!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2792 template 35
sg1 = 99.995!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2793 template 35
sg1 = 99.9999!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2794 template 35
sg1 = 123.456!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2795 template 35
sg1 = -123.456!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2796 template 35
sg1 = 999.95!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2797 template 35
sg1 = 1234.5678!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2798 template 35
sg1 = 12345.678!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2799 template 35
sg1 = 99999.9!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2800 template 35
sg1 = 0.1!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2801 template 35
sg1 = 0.00001!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2802 template 35
sg1 = 0.000000123!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2803 template 35
sg1 = 0.0000000001!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2804 template 35
sg1 = 100000!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2805 template 35
sg1 = 10000000000!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2806 template 35
sg1 = 9999999999999999!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2807 template 35
sg1 = 1E+17!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2808 template 35
sg1 = 1E+20!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2809 template 35
sg1 = 1E+30!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2810 template 35
sg1 = -2.5E-30!
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2811 template 35
sg1 = SngBits(&h7FC00000)
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2812 template 35
sg1 = SngBits(&hFFC00000)
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2813 template 35
sg1 = SngBits(&h7F800000)
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2814 template 35
sg1 = SngBits(&hFF800000)
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2815 template 35
sg1 = SngBits(&h1)
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2816 template 35
sg1 = SngBits(&h80000001)
Print #2, "35 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(35); sg1
' 2817 template 35
db1 = 0#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2818 template 35
db1 = DblBits(&h8000000000000000ULL)
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2819 template 35
db1 = 0.5#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2820 template 35
db1 = -0.5#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2821 template 35
db1 = 0.05#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2822 template 35
db1 = 0.005#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2823 template 35
db1 = 0.0005#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2824 template 35
db1 = 0.15#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2825 template 35
db1 = 0.25#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2826 template 35
db1 = 0.35#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2827 template 35
db1 = 0.45#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2828 template 35
db1 = 1#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2829 template 35
db1 = -1#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2830 template 35
db1 = 1.5#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2831 template 35
db1 = 2.5#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2832 template 35
db1 = 9.995#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2833 template 35
db1 = 10#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2834 template 35
db1 = 99.995#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2835 template 35
db1 = 99.9999#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2836 template 35
db1 = 123.456#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2837 template 35
db1 = -123.456#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2838 template 35
db1 = 999.95#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2839 template 35
db1 = 1234.5678#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2840 template 35
db1 = 12345.678#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2841 template 35
db1 = 99999.9#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2842 template 35
db1 = 0.1#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2843 template 35
db1 = 0.00001#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2844 template 35
db1 = 0.000000123#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2845 template 35
db1 = 0.0000000001#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2846 template 35
db1 = 100000#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2847 template 35
db1 = 10000000000#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2848 template 35
db1 = 9999999999999999#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2849 template 35
db1 = 1E+17#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2850 template 35
db1 = 1E+20#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2851 template 35
db1 = 1E+30#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2852 template 35
db1 = -2.5E-30#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2853 template 35
db1 = 1E+300#
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2854 template 35
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2855 template 35
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2856 template 35
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2857 template 35
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2858 template 35
db1 = DblBits(&h1ULL)
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2859 template 35
db1 = DblBits(&h8000000000000001ULL)
Print #2, "35 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(35); db1
' 2860 template 36
sg1 = 0
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2861 template 36
sg1 = SngBits(&h80000000)
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2862 template 36
sg1 = 0.5!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2863 template 36
sg1 = -0.5!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2864 template 36
sg1 = 0.05!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2865 template 36
sg1 = 0.005!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2866 template 36
sg1 = 0.0005!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2867 template 36
sg1 = 0.15!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2868 template 36
sg1 = 0.25!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2869 template 36
sg1 = 0.35!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2870 template 36
sg1 = 0.45!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2871 template 36
sg1 = 1!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2872 template 36
sg1 = -1!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2873 template 36
sg1 = 1.5!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2874 template 36
sg1 = 2.5!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2875 template 36
sg1 = 9.995!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2876 template 36
sg1 = 10!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2877 template 36
sg1 = 99.995!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2878 template 36
sg1 = 99.9999!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2879 template 36
sg1 = 123.456!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2880 template 36
sg1 = -123.456!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2881 template 36
sg1 = 999.95!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2882 template 36
sg1 = 1234.5678!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2883 template 36
sg1 = 12345.678!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2884 template 36
sg1 = 99999.9!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2885 template 36
sg1 = 0.1!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2886 template 36
sg1 = 0.00001!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2887 template 36
sg1 = 0.000000123!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2888 template 36
sg1 = 0.0000000001!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2889 template 36
sg1 = 100000!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2890 template 36
sg1 = 10000000000!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2891 template 36
sg1 = 9999999999999999!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2892 template 36
sg1 = 1E+17!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2893 template 36
sg1 = 1E+20!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2894 template 36
sg1 = 1E+30!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2895 template 36
sg1 = -2.5E-30!
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2896 template 36
sg1 = SngBits(&h7FC00000)
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2897 template 36
sg1 = SngBits(&hFFC00000)
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2898 template 36
sg1 = SngBits(&h7F800000)
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2899 template 36
sg1 = SngBits(&hFF800000)
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2900 template 36
sg1 = SngBits(&h1)
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2901 template 36
sg1 = SngBits(&h80000001)
Print #2, "36 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(36); sg1
' 2902 template 36
li1 = 0
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2903 template 36
li1 = 1
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2904 template 36
li1 = -1
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2905 template 36
li1 = 42
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2906 template 36
li1 = -7
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2907 template 36
li1 = 12345
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2908 template 36
li1 = 99999
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2909 template 36
li1 = 100000
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2910 template 36
li1 = 999999999
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2911 template 36
li1 = -2147483648
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2912 template 36
li1 = 2147483647
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2913 template 36
li1 = 9223372036854775807
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2914 template 36
li1 = (-9223372036854775807 - 1)
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2915 template 36
li1 = 1000000
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2916 template 36
li1 = 123456789012
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2917 template 36
li1 = -100
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2918 template 36
li1 = 5
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2919 template 36
li1 = 10
Print #2, "36 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(36); li1
' 2920 template 37
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2921 template 37
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2922 template 37
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2923 template 37
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2924 template 37
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2925 template 37
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2926 template 37
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2927 template 37
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2928 template 37
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2929 template 37
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2930 template 37
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2931 template 37
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2932 template 37
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2933 template 37
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2934 template 37
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2935 template 37
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2936 template 37
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2937 template 37
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2938 template 37
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2939 template 37
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2940 template 37
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2941 template 37
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2942 template 37
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2943 template 37
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2944 template 37
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2945 template 37
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2946 template 37
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2947 template 37
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2948 template 37
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2949 template 37
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2950 template 37
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2951 template 37
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2952 template 37
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2953 template 37
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2954 template 37
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2955 template 37
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2956 template 37
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2957 template 37
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2958 template 37
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2959 template 37
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2960 template 37
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2961 template 37
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
Print #2, "37 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(37); sg1; sg2; sg3
' 2962 template 37
db1 = 0#
db2 = 0.005#
db3 = 0.45#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2963 template 37
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
db3 = 1#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2964 template 37
db1 = 0.5#
db2 = 0.15#
db3 = -1#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2965 template 37
db1 = -0.5#
db2 = 0.25#
db3 = 1.5#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2966 template 37
db1 = 0.05#
db2 = 0.35#
db3 = 2.5#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2967 template 37
db1 = 0.005#
db2 = 0.45#
db3 = 9.995#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2968 template 37
db1 = 0.0005#
db2 = 1#
db3 = 10#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2969 template 37
db1 = 0.15#
db2 = -1#
db3 = 99.995#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2970 template 37
db1 = 0.25#
db2 = 1.5#
db3 = 99.9999#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2971 template 37
db1 = 0.35#
db2 = 2.5#
db3 = 123.456#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2972 template 37
db1 = 0.45#
db2 = 9.995#
db3 = -123.456#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2973 template 37
db1 = 1#
db2 = 10#
db3 = 999.95#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2974 template 37
db1 = -1#
db2 = 99.995#
db3 = 1234.5678#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2975 template 37
db1 = 1.5#
db2 = 99.9999#
db3 = 12345.678#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2976 template 37
db1 = 2.5#
db2 = 123.456#
db3 = 99999.9#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2977 template 37
db1 = 9.995#
db2 = -123.456#
db3 = 0.1#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2978 template 37
db1 = 10#
db2 = 999.95#
db3 = 0.00001#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2979 template 37
db1 = 99.995#
db2 = 1234.5678#
db3 = 0.000000123#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2980 template 37
db1 = 99.9999#
db2 = 12345.678#
db3 = 0.0000000001#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2981 template 37
db1 = 123.456#
db2 = 99999.9#
db3 = 100000#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2982 template 37
db1 = -123.456#
db2 = 0.1#
db3 = 10000000000#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2983 template 37
db1 = 999.95#
db2 = 0.00001#
db3 = 9999999999999999#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2984 template 37
db1 = 1234.5678#
db2 = 0.000000123#
db3 = 1E+17#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2985 template 37
db1 = 12345.678#
db2 = 0.0000000001#
db3 = 1E+20#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2986 template 37
db1 = 99999.9#
db2 = 100000#
db3 = 1E+30#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2987 template 37
db1 = 0.1#
db2 = 10000000000#
db3 = -2.5E-30#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2988 template 37
db1 = 0.00001#
db2 = 9999999999999999#
db3 = 1E+300#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2989 template 37
db1 = 0.000000123#
db2 = 1E+17#
db3 = DblBits(&h7FF8000000000000ULL)
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2990 template 37
db1 = 0.0000000001#
db2 = 1E+20#
db3 = DblBits(&hFFF8000000000000ULL)
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2991 template 37
db1 = 100000#
db2 = 1E+30#
db3 = DblBits(&h7FF0000000000000ULL)
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2992 template 37
db1 = 10000000000#
db2 = -2.5E-30#
db3 = DblBits(&hFFF0000000000000ULL)
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2993 template 37
db1 = 9999999999999999#
db2 = 1E+300#
db3 = DblBits(&h1ULL)
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2994 template 37
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
db3 = DblBits(&h8000000000000001ULL)
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2995 template 37
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
db3 = 0#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2996 template 37
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
db3 = DblBits(&h8000000000000000ULL)
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2997 template 37
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
db3 = 0.5#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2998 template 37
db1 = 1E+300#
db2 = DblBits(&h1ULL)
db3 = -0.5#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 2999 template 37
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
db3 = 0.05#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 3000 template 37
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
db3 = 0.005#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 3001 template 37
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
db3 = 0.0005#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 3002 template 37
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
db3 = 0.15#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 3003 template 37
db1 = DblBits(&h1ULL)
db2 = -0.5#
db3 = 0.25#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 3004 template 37
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
db3 = 0.35#
Print #2, "37 3" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2) & " " & "d:" & DHex(db3)
Print #1, Using tpl(37); db1; db2; db3
' 3005 template 38
sg1 = 0
sg2 = 0.005!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3006 template 38
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3007 template 38
sg1 = 0.5!
sg2 = 0.15!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3008 template 38
sg1 = -0.5!
sg2 = 0.25!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3009 template 38
sg1 = 0.05!
sg2 = 0.35!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3010 template 38
sg1 = 0.005!
sg2 = 0.45!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3011 template 38
sg1 = 0.0005!
sg2 = 1!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3012 template 38
sg1 = 0.15!
sg2 = -1!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3013 template 38
sg1 = 0.25!
sg2 = 1.5!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3014 template 38
sg1 = 0.35!
sg2 = 2.5!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3015 template 38
sg1 = 0.45!
sg2 = 9.995!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3016 template 38
sg1 = 1!
sg2 = 10!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3017 template 38
sg1 = -1!
sg2 = 99.995!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3018 template 38
sg1 = 1.5!
sg2 = 99.9999!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3019 template 38
sg1 = 2.5!
sg2 = 123.456!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3020 template 38
sg1 = 9.995!
sg2 = -123.456!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3021 template 38
sg1 = 10!
sg2 = 999.95!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3022 template 38
sg1 = 99.995!
sg2 = 1234.5678!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3023 template 38
sg1 = 99.9999!
sg2 = 12345.678!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3024 template 38
sg1 = 123.456!
sg2 = 99999.9!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3025 template 38
sg1 = -123.456!
sg2 = 0.1!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3026 template 38
sg1 = 999.95!
sg2 = 0.00001!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3027 template 38
sg1 = 1234.5678!
sg2 = 0.000000123!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3028 template 38
sg1 = 12345.678!
sg2 = 0.0000000001!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3029 template 38
sg1 = 99999.9!
sg2 = 100000!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3030 template 38
sg1 = 0.1!
sg2 = 10000000000!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3031 template 38
sg1 = 0.00001!
sg2 = 9999999999999999!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3032 template 38
sg1 = 0.000000123!
sg2 = 1E+17!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3033 template 38
sg1 = 0.0000000001!
sg2 = 1E+20!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3034 template 38
sg1 = 100000!
sg2 = 1E+30!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3035 template 38
sg1 = 10000000000!
sg2 = -2.5E-30!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3036 template 38
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3037 template 38
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3038 template 38
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3039 template 38
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3040 template 38
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3041 template 38
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3042 template 38
sg1 = SngBits(&hFFC00000)
sg2 = 0
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3043 template 38
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3044 template 38
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3045 template 38
sg1 = SngBits(&h1)
sg2 = -0.5!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3046 template 38
sg1 = SngBits(&h80000001)
sg2 = 0.05!
Print #2, "38 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(38); sg1; sg2
' 3047 template 38
li1 = 0
li2 = 12345
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3048 template 38
li1 = 1
li2 = 99999
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3049 template 38
li1 = -1
li2 = 100000
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3050 template 38
li1 = 42
li2 = 999999999
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3051 template 38
li1 = -7
li2 = -2147483648
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3052 template 38
li1 = 12345
li2 = 2147483647
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3053 template 38
li1 = 99999
li2 = 9223372036854775807
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3054 template 38
li1 = 100000
li2 = (-9223372036854775807 - 1)
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3055 template 38
li1 = 999999999
li2 = 1000000
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3056 template 38
li1 = -2147483648
li2 = 123456789012
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3057 template 38
li1 = 2147483647
li2 = -100
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3058 template 38
li1 = 9223372036854775807
li2 = 5
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3059 template 38
li1 = (-9223372036854775807 - 1)
li2 = 10
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3060 template 38
li1 = 1000000
li2 = 0
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3061 template 38
li1 = 123456789012
li2 = 1
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3062 template 38
li1 = -100
li2 = -1
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3063 template 38
li1 = 5
li2 = 42
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3064 template 38
li1 = 10
li2 = -7
Print #2, "38 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(38); li1; li2
' 3065 template 39
sg1 = 0
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3066 template 39
sg1 = SngBits(&h80000000)
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3067 template 39
sg1 = 0.5!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3068 template 39
sg1 = -0.5!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3069 template 39
sg1 = 0.05!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3070 template 39
sg1 = 0.005!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3071 template 39
sg1 = 0.0005!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3072 template 39
sg1 = 0.15!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3073 template 39
sg1 = 0.25!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3074 template 39
sg1 = 0.35!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3075 template 39
sg1 = 0.45!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3076 template 39
sg1 = 1!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3077 template 39
sg1 = -1!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3078 template 39
sg1 = 1.5!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3079 template 39
sg1 = 2.5!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3080 template 39
sg1 = 9.995!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3081 template 39
sg1 = 10!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3082 template 39
sg1 = 99.995!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3083 template 39
sg1 = 99.9999!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3084 template 39
sg1 = 123.456!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3085 template 39
sg1 = -123.456!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3086 template 39
sg1 = 999.95!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3087 template 39
sg1 = 1234.5678!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3088 template 39
sg1 = 12345.678!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3089 template 39
sg1 = 99999.9!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3090 template 39
sg1 = 0.1!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3091 template 39
sg1 = 0.00001!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3092 template 39
sg1 = 0.000000123!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3093 template 39
sg1 = 0.0000000001!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3094 template 39
sg1 = 100000!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3095 template 39
sg1 = 10000000000!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3096 template 39
sg1 = 9999999999999999!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3097 template 39
sg1 = 1E+17!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3098 template 39
sg1 = 1E+20!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3099 template 39
sg1 = 1E+30!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3100 template 39
sg1 = -2.5E-30!
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3101 template 39
sg1 = SngBits(&h7FC00000)
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3102 template 39
sg1 = SngBits(&hFFC00000)
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3103 template 39
sg1 = SngBits(&h7F800000)
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3104 template 39
sg1 = SngBits(&hFF800000)
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3105 template 39
sg1 = SngBits(&h1)
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3106 template 39
sg1 = SngBits(&h80000001)
Print #2, "39 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(39); sg1
' 3107 template 39
li1 = 0
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3108 template 39
li1 = 1
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3109 template 39
li1 = -1
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3110 template 39
li1 = 42
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3111 template 39
li1 = -7
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3112 template 39
li1 = 12345
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3113 template 39
li1 = 99999
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3114 template 39
li1 = 100000
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3115 template 39
li1 = 999999999
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3116 template 39
li1 = -2147483648
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3117 template 39
li1 = 2147483647
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3118 template 39
li1 = 9223372036854775807
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3119 template 39
li1 = (-9223372036854775807 - 1)
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3120 template 39
li1 = 1000000
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3121 template 39
li1 = 123456789012
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3122 template 39
li1 = -100
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3123 template 39
li1 = 5
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3124 template 39
li1 = 10
Print #2, "39 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(39); li1
' 3125 template 40
sg1 = 0
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3126 template 40
sg1 = SngBits(&h80000000)
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3127 template 40
sg1 = 0.5!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3128 template 40
sg1 = -0.5!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3129 template 40
sg1 = 0.05!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3130 template 40
sg1 = 0.005!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3131 template 40
sg1 = 0.0005!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3132 template 40
sg1 = 0.15!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3133 template 40
sg1 = 0.25!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3134 template 40
sg1 = 0.35!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3135 template 40
sg1 = 0.45!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3136 template 40
sg1 = 1!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3137 template 40
sg1 = -1!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3138 template 40
sg1 = 1.5!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3139 template 40
sg1 = 2.5!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3140 template 40
sg1 = 9.995!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3141 template 40
sg1 = 10!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3142 template 40
sg1 = 99.995!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3143 template 40
sg1 = 99.9999!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3144 template 40
sg1 = 123.456!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3145 template 40
sg1 = -123.456!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3146 template 40
sg1 = 999.95!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3147 template 40
sg1 = 1234.5678!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3148 template 40
sg1 = 12345.678!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3149 template 40
sg1 = 99999.9!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3150 template 40
sg1 = 0.1!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3151 template 40
sg1 = 0.00001!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3152 template 40
sg1 = 0.000000123!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3153 template 40
sg1 = 0.0000000001!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3154 template 40
sg1 = 100000!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3155 template 40
sg1 = 10000000000!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3156 template 40
sg1 = 9999999999999999!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3157 template 40
sg1 = 1E+17!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3158 template 40
sg1 = 1E+20!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3159 template 40
sg1 = 1E+30!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3160 template 40
sg1 = -2.5E-30!
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3161 template 40
sg1 = SngBits(&h7FC00000)
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3162 template 40
sg1 = SngBits(&hFFC00000)
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3163 template 40
sg1 = SngBits(&h7F800000)
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3164 template 40
sg1 = SngBits(&hFF800000)
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3165 template 40
sg1 = SngBits(&h1)
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3166 template 40
sg1 = SngBits(&h80000001)
Print #2, "40 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(40); sg1
' 3167 template 40
db1 = 0#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3168 template 40
db1 = DblBits(&h8000000000000000ULL)
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3169 template 40
db1 = 0.5#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3170 template 40
db1 = -0.5#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3171 template 40
db1 = 0.05#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3172 template 40
db1 = 0.005#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3173 template 40
db1 = 0.0005#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3174 template 40
db1 = 0.15#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3175 template 40
db1 = 0.25#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3176 template 40
db1 = 0.35#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3177 template 40
db1 = 0.45#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3178 template 40
db1 = 1#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3179 template 40
db1 = -1#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3180 template 40
db1 = 1.5#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3181 template 40
db1 = 2.5#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3182 template 40
db1 = 9.995#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3183 template 40
db1 = 10#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3184 template 40
db1 = 99.995#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3185 template 40
db1 = 99.9999#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3186 template 40
db1 = 123.456#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3187 template 40
db1 = -123.456#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3188 template 40
db1 = 999.95#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3189 template 40
db1 = 1234.5678#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3190 template 40
db1 = 12345.678#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3191 template 40
db1 = 99999.9#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3192 template 40
db1 = 0.1#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3193 template 40
db1 = 0.00001#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3194 template 40
db1 = 0.000000123#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3195 template 40
db1 = 0.0000000001#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3196 template 40
db1 = 100000#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3197 template 40
db1 = 10000000000#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3198 template 40
db1 = 9999999999999999#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3199 template 40
db1 = 1E+17#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3200 template 40
db1 = 1E+20#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3201 template 40
db1 = 1E+30#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3202 template 40
db1 = -2.5E-30#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3203 template 40
db1 = 1E+300#
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3204 template 40
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3205 template 40
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3206 template 40
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3207 template 40
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3208 template 40
db1 = DblBits(&h1ULL)
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3209 template 40
db1 = DblBits(&h8000000000000001ULL)
Print #2, "40 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(40); db1
' 3210 template 41
sg1 = 0
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3211 template 41
sg1 = SngBits(&h80000000)
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3212 template 41
sg1 = 0.5!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3213 template 41
sg1 = -0.5!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3214 template 41
sg1 = 0.05!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3215 template 41
sg1 = 0.005!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3216 template 41
sg1 = 0.0005!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3217 template 41
sg1 = 0.15!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3218 template 41
sg1 = 0.25!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3219 template 41
sg1 = 0.35!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3220 template 41
sg1 = 0.45!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3221 template 41
sg1 = 1!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3222 template 41
sg1 = -1!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3223 template 41
sg1 = 1.5!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3224 template 41
sg1 = 2.5!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3225 template 41
sg1 = 9.995!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3226 template 41
sg1 = 10!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3227 template 41
sg1 = 99.995!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3228 template 41
sg1 = 99.9999!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3229 template 41
sg1 = 123.456!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3230 template 41
sg1 = -123.456!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3231 template 41
sg1 = 999.95!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3232 template 41
sg1 = 1234.5678!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3233 template 41
sg1 = 12345.678!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3234 template 41
sg1 = 99999.9!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3235 template 41
sg1 = 0.1!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3236 template 41
sg1 = 0.00001!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3237 template 41
sg1 = 0.000000123!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3238 template 41
sg1 = 0.0000000001!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3239 template 41
sg1 = 100000!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3240 template 41
sg1 = 10000000000!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3241 template 41
sg1 = 9999999999999999!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3242 template 41
sg1 = 1E+17!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3243 template 41
sg1 = 1E+20!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3244 template 41
sg1 = 1E+30!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3245 template 41
sg1 = -2.5E-30!
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3246 template 41
sg1 = SngBits(&h7FC00000)
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3247 template 41
sg1 = SngBits(&hFFC00000)
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3248 template 41
sg1 = SngBits(&h7F800000)
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3249 template 41
sg1 = SngBits(&hFF800000)
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3250 template 41
sg1 = SngBits(&h1)
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3251 template 41
sg1 = SngBits(&h80000001)
Print #2, "41 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(41); sg1
' 3252 template 41
db1 = 0#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3253 template 41
db1 = DblBits(&h8000000000000000ULL)
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3254 template 41
db1 = 0.5#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3255 template 41
db1 = -0.5#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3256 template 41
db1 = 0.05#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3257 template 41
db1 = 0.005#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3258 template 41
db1 = 0.0005#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3259 template 41
db1 = 0.15#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3260 template 41
db1 = 0.25#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3261 template 41
db1 = 0.35#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3262 template 41
db1 = 0.45#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3263 template 41
db1 = 1#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3264 template 41
db1 = -1#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3265 template 41
db1 = 1.5#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3266 template 41
db1 = 2.5#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3267 template 41
db1 = 9.995#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3268 template 41
db1 = 10#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3269 template 41
db1 = 99.995#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3270 template 41
db1 = 99.9999#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3271 template 41
db1 = 123.456#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3272 template 41
db1 = -123.456#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3273 template 41
db1 = 999.95#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3274 template 41
db1 = 1234.5678#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3275 template 41
db1 = 12345.678#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3276 template 41
db1 = 99999.9#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3277 template 41
db1 = 0.1#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3278 template 41
db1 = 0.00001#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3279 template 41
db1 = 0.000000123#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3280 template 41
db1 = 0.0000000001#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3281 template 41
db1 = 100000#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3282 template 41
db1 = 10000000000#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3283 template 41
db1 = 9999999999999999#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3284 template 41
db1 = 1E+17#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3285 template 41
db1 = 1E+20#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3286 template 41
db1 = 1E+30#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3287 template 41
db1 = -2.5E-30#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3288 template 41
db1 = 1E+300#
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3289 template 41
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3290 template 41
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3291 template 41
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3292 template 41
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3293 template 41
db1 = DblBits(&h1ULL)
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3294 template 41
db1 = DblBits(&h8000000000000001ULL)
Print #2, "41 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(41); db1
' 3295 template 42
sg1 = 0
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3296 template 42
sg1 = SngBits(&h80000000)
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3297 template 42
sg1 = 0.5!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3298 template 42
sg1 = -0.5!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3299 template 42
sg1 = 0.05!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3300 template 42
sg1 = 0.005!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3301 template 42
sg1 = 0.0005!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3302 template 42
sg1 = 0.15!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3303 template 42
sg1 = 0.25!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3304 template 42
sg1 = 0.35!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3305 template 42
sg1 = 0.45!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3306 template 42
sg1 = 1!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3307 template 42
sg1 = -1!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3308 template 42
sg1 = 1.5!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3309 template 42
sg1 = 2.5!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3310 template 42
sg1 = 9.995!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3311 template 42
sg1 = 10!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3312 template 42
sg1 = 99.995!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3313 template 42
sg1 = 99.9999!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3314 template 42
sg1 = 123.456!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3315 template 42
sg1 = -123.456!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3316 template 42
sg1 = 999.95!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3317 template 42
sg1 = 1234.5678!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3318 template 42
sg1 = 12345.678!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3319 template 42
sg1 = 99999.9!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3320 template 42
sg1 = 0.1!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3321 template 42
sg1 = 0.00001!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3322 template 42
sg1 = 0.000000123!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3323 template 42
sg1 = 0.0000000001!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3324 template 42
sg1 = 100000!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3325 template 42
sg1 = 10000000000!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3326 template 42
sg1 = 9999999999999999!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3327 template 42
sg1 = 1E+17!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3328 template 42
sg1 = 1E+20!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3329 template 42
sg1 = 1E+30!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3330 template 42
sg1 = -2.5E-30!
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3331 template 42
sg1 = SngBits(&h7FC00000)
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3332 template 42
sg1 = SngBits(&hFFC00000)
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3333 template 42
sg1 = SngBits(&h7F800000)
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3334 template 42
sg1 = SngBits(&hFF800000)
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3335 template 42
sg1 = SngBits(&h1)
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3336 template 42
sg1 = SngBits(&h80000001)
Print #2, "42 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(42); sg1
' 3337 template 42
db1 = 0#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3338 template 42
db1 = DblBits(&h8000000000000000ULL)
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3339 template 42
db1 = 0.5#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3340 template 42
db1 = -0.5#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3341 template 42
db1 = 0.05#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3342 template 42
db1 = 0.005#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3343 template 42
db1 = 0.0005#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3344 template 42
db1 = 0.15#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3345 template 42
db1 = 0.25#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3346 template 42
db1 = 0.35#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3347 template 42
db1 = 0.45#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3348 template 42
db1 = 1#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3349 template 42
db1 = -1#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3350 template 42
db1 = 1.5#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3351 template 42
db1 = 2.5#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3352 template 42
db1 = 9.995#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3353 template 42
db1 = 10#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3354 template 42
db1 = 99.995#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3355 template 42
db1 = 99.9999#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3356 template 42
db1 = 123.456#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3357 template 42
db1 = -123.456#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3358 template 42
db1 = 999.95#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3359 template 42
db1 = 1234.5678#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3360 template 42
db1 = 12345.678#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3361 template 42
db1 = 99999.9#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3362 template 42
db1 = 0.1#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3363 template 42
db1 = 0.00001#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3364 template 42
db1 = 0.000000123#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3365 template 42
db1 = 0.0000000001#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3366 template 42
db1 = 100000#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3367 template 42
db1 = 10000000000#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3368 template 42
db1 = 9999999999999999#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3369 template 42
db1 = 1E+17#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3370 template 42
db1 = 1E+20#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3371 template 42
db1 = 1E+30#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3372 template 42
db1 = -2.5E-30#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3373 template 42
db1 = 1E+300#
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3374 template 42
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3375 template 42
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3376 template 42
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3377 template 42
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3378 template 42
db1 = DblBits(&h1ULL)
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3379 template 42
db1 = DblBits(&h8000000000000001ULL)
Print #2, "42 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(42); db1
' 3380 template 43
sg1 = 0
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3381 template 43
sg1 = SngBits(&h80000000)
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3382 template 43
sg1 = 0.5!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3383 template 43
sg1 = -0.5!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3384 template 43
sg1 = 0.05!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3385 template 43
sg1 = 0.005!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3386 template 43
sg1 = 0.0005!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3387 template 43
sg1 = 0.15!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3388 template 43
sg1 = 0.25!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3389 template 43
sg1 = 0.35!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3390 template 43
sg1 = 0.45!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3391 template 43
sg1 = 1!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3392 template 43
sg1 = -1!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3393 template 43
sg1 = 1.5!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3394 template 43
sg1 = 2.5!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3395 template 43
sg1 = 9.995!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3396 template 43
sg1 = 10!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3397 template 43
sg1 = 99.995!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3398 template 43
sg1 = 99.9999!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3399 template 43
sg1 = 123.456!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3400 template 43
sg1 = -123.456!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3401 template 43
sg1 = 999.95!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3402 template 43
sg1 = 1234.5678!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3403 template 43
sg1 = 12345.678!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3404 template 43
sg1 = 99999.9!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3405 template 43
sg1 = 0.1!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3406 template 43
sg1 = 0.00001!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3407 template 43
sg1 = 0.000000123!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3408 template 43
sg1 = 0.0000000001!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3409 template 43
sg1 = 100000!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3410 template 43
sg1 = 10000000000!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3411 template 43
sg1 = 9999999999999999!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3412 template 43
sg1 = 1E+17!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3413 template 43
sg1 = 1E+20!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3414 template 43
sg1 = 1E+30!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3415 template 43
sg1 = -2.5E-30!
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3416 template 43
sg1 = SngBits(&h7FC00000)
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3417 template 43
sg1 = SngBits(&hFFC00000)
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3418 template 43
sg1 = SngBits(&h7F800000)
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3419 template 43
sg1 = SngBits(&hFF800000)
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3420 template 43
sg1 = SngBits(&h1)
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3421 template 43
sg1 = SngBits(&h80000001)
Print #2, "43 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(43); sg1
' 3422 template 43
db1 = 0#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3423 template 43
db1 = DblBits(&h8000000000000000ULL)
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3424 template 43
db1 = 0.5#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3425 template 43
db1 = -0.5#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3426 template 43
db1 = 0.05#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3427 template 43
db1 = 0.005#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3428 template 43
db1 = 0.0005#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3429 template 43
db1 = 0.15#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3430 template 43
db1 = 0.25#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3431 template 43
db1 = 0.35#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3432 template 43
db1 = 0.45#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3433 template 43
db1 = 1#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3434 template 43
db1 = -1#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3435 template 43
db1 = 1.5#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3436 template 43
db1 = 2.5#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3437 template 43
db1 = 9.995#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3438 template 43
db1 = 10#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3439 template 43
db1 = 99.995#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3440 template 43
db1 = 99.9999#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3441 template 43
db1 = 123.456#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3442 template 43
db1 = -123.456#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3443 template 43
db1 = 999.95#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3444 template 43
db1 = 1234.5678#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3445 template 43
db1 = 12345.678#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3446 template 43
db1 = 99999.9#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3447 template 43
db1 = 0.1#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3448 template 43
db1 = 0.00001#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3449 template 43
db1 = 0.000000123#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3450 template 43
db1 = 0.0000000001#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3451 template 43
db1 = 100000#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3452 template 43
db1 = 10000000000#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3453 template 43
db1 = 9999999999999999#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3454 template 43
db1 = 1E+17#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3455 template 43
db1 = 1E+20#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3456 template 43
db1 = 1E+30#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3457 template 43
db1 = -2.5E-30#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3458 template 43
db1 = 1E+300#
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3459 template 43
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3460 template 43
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3461 template 43
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3462 template 43
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3463 template 43
db1 = DblBits(&h1ULL)
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3464 template 43
db1 = DblBits(&h8000000000000001ULL)
Print #2, "43 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(43); db1
' 3465 template 44
sg1 = 0
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3466 template 44
sg1 = SngBits(&h80000000)
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3467 template 44
sg1 = 0.5!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3468 template 44
sg1 = -0.5!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3469 template 44
sg1 = 0.05!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3470 template 44
sg1 = 0.005!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3471 template 44
sg1 = 0.0005!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3472 template 44
sg1 = 0.15!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3473 template 44
sg1 = 0.25!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3474 template 44
sg1 = 0.35!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3475 template 44
sg1 = 0.45!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3476 template 44
sg1 = 1!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3477 template 44
sg1 = -1!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3478 template 44
sg1 = 1.5!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3479 template 44
sg1 = 2.5!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3480 template 44
sg1 = 9.995!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3481 template 44
sg1 = 10!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3482 template 44
sg1 = 99.995!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3483 template 44
sg1 = 99.9999!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3484 template 44
sg1 = 123.456!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3485 template 44
sg1 = -123.456!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3486 template 44
sg1 = 999.95!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3487 template 44
sg1 = 1234.5678!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3488 template 44
sg1 = 12345.678!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3489 template 44
sg1 = 99999.9!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3490 template 44
sg1 = 0.1!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3491 template 44
sg1 = 0.00001!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3492 template 44
sg1 = 0.000000123!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3493 template 44
sg1 = 0.0000000001!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3494 template 44
sg1 = 100000!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3495 template 44
sg1 = 10000000000!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3496 template 44
sg1 = 9999999999999999!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3497 template 44
sg1 = 1E+17!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3498 template 44
sg1 = 1E+20!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3499 template 44
sg1 = 1E+30!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3500 template 44
sg1 = -2.5E-30!
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3501 template 44
sg1 = SngBits(&h7FC00000)
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3502 template 44
sg1 = SngBits(&hFFC00000)
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3503 template 44
sg1 = SngBits(&h7F800000)
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3504 template 44
sg1 = SngBits(&hFF800000)
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3505 template 44
sg1 = SngBits(&h1)
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3506 template 44
sg1 = SngBits(&h80000001)
Print #2, "44 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(44); sg1
' 3507 template 44
db1 = 0#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3508 template 44
db1 = DblBits(&h8000000000000000ULL)
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3509 template 44
db1 = 0.5#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3510 template 44
db1 = -0.5#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3511 template 44
db1 = 0.05#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3512 template 44
db1 = 0.005#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3513 template 44
db1 = 0.0005#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3514 template 44
db1 = 0.15#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3515 template 44
db1 = 0.25#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3516 template 44
db1 = 0.35#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3517 template 44
db1 = 0.45#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3518 template 44
db1 = 1#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3519 template 44
db1 = -1#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3520 template 44
db1 = 1.5#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3521 template 44
db1 = 2.5#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3522 template 44
db1 = 9.995#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3523 template 44
db1 = 10#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3524 template 44
db1 = 99.995#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3525 template 44
db1 = 99.9999#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3526 template 44
db1 = 123.456#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3527 template 44
db1 = -123.456#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3528 template 44
db1 = 999.95#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3529 template 44
db1 = 1234.5678#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3530 template 44
db1 = 12345.678#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3531 template 44
db1 = 99999.9#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3532 template 44
db1 = 0.1#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3533 template 44
db1 = 0.00001#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3534 template 44
db1 = 0.000000123#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3535 template 44
db1 = 0.0000000001#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3536 template 44
db1 = 100000#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3537 template 44
db1 = 10000000000#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3538 template 44
db1 = 9999999999999999#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3539 template 44
db1 = 1E+17#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3540 template 44
db1 = 1E+20#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3541 template 44
db1 = 1E+30#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3542 template 44
db1 = -2.5E-30#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3543 template 44
db1 = 1E+300#
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3544 template 44
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3545 template 44
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3546 template 44
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3547 template 44
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3548 template 44
db1 = DblBits(&h1ULL)
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3549 template 44
db1 = DblBits(&h8000000000000001ULL)
Print #2, "44 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(44); db1
' 3550 template 45
sg1 = 0
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3551 template 45
sg1 = SngBits(&h80000000)
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3552 template 45
sg1 = 0.5!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3553 template 45
sg1 = -0.5!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3554 template 45
sg1 = 0.05!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3555 template 45
sg1 = 0.005!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3556 template 45
sg1 = 0.0005!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3557 template 45
sg1 = 0.15!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3558 template 45
sg1 = 0.25!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3559 template 45
sg1 = 0.35!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3560 template 45
sg1 = 0.45!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3561 template 45
sg1 = 1!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3562 template 45
sg1 = -1!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3563 template 45
sg1 = 1.5!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3564 template 45
sg1 = 2.5!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3565 template 45
sg1 = 9.995!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3566 template 45
sg1 = 10!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3567 template 45
sg1 = 99.995!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3568 template 45
sg1 = 99.9999!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3569 template 45
sg1 = 123.456!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3570 template 45
sg1 = -123.456!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3571 template 45
sg1 = 999.95!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3572 template 45
sg1 = 1234.5678!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3573 template 45
sg1 = 12345.678!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3574 template 45
sg1 = 99999.9!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3575 template 45
sg1 = 0.1!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3576 template 45
sg1 = 0.00001!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3577 template 45
sg1 = 0.000000123!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3578 template 45
sg1 = 0.0000000001!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3579 template 45
sg1 = 100000!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3580 template 45
sg1 = 10000000000!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3581 template 45
sg1 = 9999999999999999!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3582 template 45
sg1 = 1E+17!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3583 template 45
sg1 = 1E+20!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3584 template 45
sg1 = 1E+30!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3585 template 45
sg1 = -2.5E-30!
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3586 template 45
sg1 = SngBits(&h7FC00000)
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3587 template 45
sg1 = SngBits(&hFFC00000)
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3588 template 45
sg1 = SngBits(&h7F800000)
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3589 template 45
sg1 = SngBits(&hFF800000)
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3590 template 45
sg1 = SngBits(&h1)
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3591 template 45
sg1 = SngBits(&h80000001)
Print #2, "45 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(45); sg1
' 3592 template 45
db1 = 0#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3593 template 45
db1 = DblBits(&h8000000000000000ULL)
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3594 template 45
db1 = 0.5#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3595 template 45
db1 = -0.5#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3596 template 45
db1 = 0.05#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3597 template 45
db1 = 0.005#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3598 template 45
db1 = 0.0005#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3599 template 45
db1 = 0.15#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3600 template 45
db1 = 0.25#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3601 template 45
db1 = 0.35#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3602 template 45
db1 = 0.45#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3603 template 45
db1 = 1#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3604 template 45
db1 = -1#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3605 template 45
db1 = 1.5#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3606 template 45
db1 = 2.5#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3607 template 45
db1 = 9.995#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3608 template 45
db1 = 10#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3609 template 45
db1 = 99.995#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3610 template 45
db1 = 99.9999#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3611 template 45
db1 = 123.456#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3612 template 45
db1 = -123.456#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3613 template 45
db1 = 999.95#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3614 template 45
db1 = 1234.5678#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3615 template 45
db1 = 12345.678#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3616 template 45
db1 = 99999.9#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3617 template 45
db1 = 0.1#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3618 template 45
db1 = 0.00001#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3619 template 45
db1 = 0.000000123#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3620 template 45
db1 = 0.0000000001#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3621 template 45
db1 = 100000#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3622 template 45
db1 = 10000000000#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3623 template 45
db1 = 9999999999999999#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3624 template 45
db1 = 1E+17#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3625 template 45
db1 = 1E+20#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3626 template 45
db1 = 1E+30#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3627 template 45
db1 = -2.5E-30#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3628 template 45
db1 = 1E+300#
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3629 template 45
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3630 template 45
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3631 template 45
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3632 template 45
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3633 template 45
db1 = DblBits(&h1ULL)
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3634 template 45
db1 = DblBits(&h8000000000000001ULL)
Print #2, "45 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(45); db1
' 3635 template 46
sg1 = 0
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3636 template 46
sg1 = SngBits(&h80000000)
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3637 template 46
sg1 = 0.5!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3638 template 46
sg1 = -0.5!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3639 template 46
sg1 = 0.05!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3640 template 46
sg1 = 0.005!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3641 template 46
sg1 = 0.0005!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3642 template 46
sg1 = 0.15!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3643 template 46
sg1 = 0.25!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3644 template 46
sg1 = 0.35!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3645 template 46
sg1 = 0.45!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3646 template 46
sg1 = 1!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3647 template 46
sg1 = -1!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3648 template 46
sg1 = 1.5!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3649 template 46
sg1 = 2.5!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3650 template 46
sg1 = 9.995!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3651 template 46
sg1 = 10!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3652 template 46
sg1 = 99.995!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3653 template 46
sg1 = 99.9999!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3654 template 46
sg1 = 123.456!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3655 template 46
sg1 = -123.456!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3656 template 46
sg1 = 999.95!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3657 template 46
sg1 = 1234.5678!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3658 template 46
sg1 = 12345.678!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3659 template 46
sg1 = 99999.9!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3660 template 46
sg1 = 0.1!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3661 template 46
sg1 = 0.00001!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3662 template 46
sg1 = 0.000000123!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3663 template 46
sg1 = 0.0000000001!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3664 template 46
sg1 = 100000!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3665 template 46
sg1 = 10000000000!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3666 template 46
sg1 = 9999999999999999!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3667 template 46
sg1 = 1E+17!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3668 template 46
sg1 = 1E+20!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3669 template 46
sg1 = 1E+30!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3670 template 46
sg1 = -2.5E-30!
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3671 template 46
sg1 = SngBits(&h7FC00000)
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3672 template 46
sg1 = SngBits(&hFFC00000)
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3673 template 46
sg1 = SngBits(&h7F800000)
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3674 template 46
sg1 = SngBits(&hFF800000)
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3675 template 46
sg1 = SngBits(&h1)
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3676 template 46
sg1 = SngBits(&h80000001)
Print #2, "46 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(46); sg1
' 3677 template 46
db1 = 0#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3678 template 46
db1 = DblBits(&h8000000000000000ULL)
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3679 template 46
db1 = 0.5#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3680 template 46
db1 = -0.5#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3681 template 46
db1 = 0.05#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3682 template 46
db1 = 0.005#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3683 template 46
db1 = 0.0005#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3684 template 46
db1 = 0.15#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3685 template 46
db1 = 0.25#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3686 template 46
db1 = 0.35#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3687 template 46
db1 = 0.45#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3688 template 46
db1 = 1#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3689 template 46
db1 = -1#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3690 template 46
db1 = 1.5#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3691 template 46
db1 = 2.5#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3692 template 46
db1 = 9.995#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3693 template 46
db1 = 10#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3694 template 46
db1 = 99.995#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3695 template 46
db1 = 99.9999#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3696 template 46
db1 = 123.456#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3697 template 46
db1 = -123.456#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3698 template 46
db1 = 999.95#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3699 template 46
db1 = 1234.5678#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3700 template 46
db1 = 12345.678#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3701 template 46
db1 = 99999.9#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3702 template 46
db1 = 0.1#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3703 template 46
db1 = 0.00001#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3704 template 46
db1 = 0.000000123#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3705 template 46
db1 = 0.0000000001#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3706 template 46
db1 = 100000#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3707 template 46
db1 = 10000000000#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3708 template 46
db1 = 9999999999999999#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3709 template 46
db1 = 1E+17#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3710 template 46
db1 = 1E+20#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3711 template 46
db1 = 1E+30#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3712 template 46
db1 = -2.5E-30#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3713 template 46
db1 = 1E+300#
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3714 template 46
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3715 template 46
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3716 template 46
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3717 template 46
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3718 template 46
db1 = DblBits(&h1ULL)
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3719 template 46
db1 = DblBits(&h8000000000000001ULL)
Print #2, "46 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(46); db1
' 3720 template 47
sg1 = 0
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3721 template 47
sg1 = SngBits(&h80000000)
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3722 template 47
sg1 = 0.5!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3723 template 47
sg1 = -0.5!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3724 template 47
sg1 = 0.05!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3725 template 47
sg1 = 0.005!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3726 template 47
sg1 = 0.0005!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3727 template 47
sg1 = 0.15!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3728 template 47
sg1 = 0.25!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3729 template 47
sg1 = 0.35!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3730 template 47
sg1 = 0.45!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3731 template 47
sg1 = 1!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3732 template 47
sg1 = -1!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3733 template 47
sg1 = 1.5!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3734 template 47
sg1 = 2.5!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3735 template 47
sg1 = 9.995!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3736 template 47
sg1 = 10!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3737 template 47
sg1 = 99.995!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3738 template 47
sg1 = 99.9999!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3739 template 47
sg1 = 123.456!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3740 template 47
sg1 = -123.456!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3741 template 47
sg1 = 999.95!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3742 template 47
sg1 = 1234.5678!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3743 template 47
sg1 = 12345.678!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3744 template 47
sg1 = 99999.9!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3745 template 47
sg1 = 0.1!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3746 template 47
sg1 = 0.00001!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3747 template 47
sg1 = 0.000000123!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3748 template 47
sg1 = 0.0000000001!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3749 template 47
sg1 = 100000!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3750 template 47
sg1 = 10000000000!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3751 template 47
sg1 = 9999999999999999!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3752 template 47
sg1 = 1E+17!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3753 template 47
sg1 = 1E+20!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3754 template 47
sg1 = 1E+30!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3755 template 47
sg1 = -2.5E-30!
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3756 template 47
sg1 = SngBits(&h7FC00000)
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3757 template 47
sg1 = SngBits(&hFFC00000)
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3758 template 47
sg1 = SngBits(&h7F800000)
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3759 template 47
sg1 = SngBits(&hFF800000)
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3760 template 47
sg1 = SngBits(&h1)
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3761 template 47
sg1 = SngBits(&h80000001)
Print #2, "47 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(47); sg1
' 3762 template 47
db1 = 0#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3763 template 47
db1 = DblBits(&h8000000000000000ULL)
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3764 template 47
db1 = 0.5#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3765 template 47
db1 = -0.5#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3766 template 47
db1 = 0.05#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3767 template 47
db1 = 0.005#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3768 template 47
db1 = 0.0005#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3769 template 47
db1 = 0.15#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3770 template 47
db1 = 0.25#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3771 template 47
db1 = 0.35#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3772 template 47
db1 = 0.45#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3773 template 47
db1 = 1#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3774 template 47
db1 = -1#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3775 template 47
db1 = 1.5#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3776 template 47
db1 = 2.5#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3777 template 47
db1 = 9.995#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3778 template 47
db1 = 10#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3779 template 47
db1 = 99.995#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3780 template 47
db1 = 99.9999#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3781 template 47
db1 = 123.456#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3782 template 47
db1 = -123.456#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3783 template 47
db1 = 999.95#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3784 template 47
db1 = 1234.5678#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3785 template 47
db1 = 12345.678#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3786 template 47
db1 = 99999.9#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3787 template 47
db1 = 0.1#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3788 template 47
db1 = 0.00001#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3789 template 47
db1 = 0.000000123#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3790 template 47
db1 = 0.0000000001#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3791 template 47
db1 = 100000#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3792 template 47
db1 = 10000000000#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3793 template 47
db1 = 9999999999999999#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3794 template 47
db1 = 1E+17#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3795 template 47
db1 = 1E+20#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3796 template 47
db1 = 1E+30#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3797 template 47
db1 = -2.5E-30#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3798 template 47
db1 = 1E+300#
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3799 template 47
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3800 template 47
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3801 template 47
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3802 template 47
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3803 template 47
db1 = DblBits(&h1ULL)
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3804 template 47
db1 = DblBits(&h8000000000000001ULL)
Print #2, "47 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(47); db1
' 3805 template 48
sg1 = 0
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3806 template 48
sg1 = SngBits(&h80000000)
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3807 template 48
sg1 = 0.5!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3808 template 48
sg1 = -0.5!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3809 template 48
sg1 = 0.05!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3810 template 48
sg1 = 0.005!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3811 template 48
sg1 = 0.0005!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3812 template 48
sg1 = 0.15!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3813 template 48
sg1 = 0.25!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3814 template 48
sg1 = 0.35!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3815 template 48
sg1 = 0.45!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3816 template 48
sg1 = 1!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3817 template 48
sg1 = -1!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3818 template 48
sg1 = 1.5!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3819 template 48
sg1 = 2.5!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3820 template 48
sg1 = 9.995!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3821 template 48
sg1 = 10!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3822 template 48
sg1 = 99.995!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3823 template 48
sg1 = 99.9999!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3824 template 48
sg1 = 123.456!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3825 template 48
sg1 = -123.456!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3826 template 48
sg1 = 999.95!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3827 template 48
sg1 = 1234.5678!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3828 template 48
sg1 = 12345.678!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3829 template 48
sg1 = 99999.9!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3830 template 48
sg1 = 0.1!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3831 template 48
sg1 = 0.00001!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3832 template 48
sg1 = 0.000000123!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3833 template 48
sg1 = 0.0000000001!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3834 template 48
sg1 = 100000!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3835 template 48
sg1 = 10000000000!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3836 template 48
sg1 = 9999999999999999!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3837 template 48
sg1 = 1E+17!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3838 template 48
sg1 = 1E+20!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3839 template 48
sg1 = 1E+30!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3840 template 48
sg1 = -2.5E-30!
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3841 template 48
sg1 = SngBits(&h7FC00000)
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3842 template 48
sg1 = SngBits(&hFFC00000)
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3843 template 48
sg1 = SngBits(&h7F800000)
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3844 template 48
sg1 = SngBits(&hFF800000)
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3845 template 48
sg1 = SngBits(&h1)
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3846 template 48
sg1 = SngBits(&h80000001)
Print #2, "48 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(48); sg1
' 3847 template 48
db1 = 0#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3848 template 48
db1 = DblBits(&h8000000000000000ULL)
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3849 template 48
db1 = 0.5#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3850 template 48
db1 = -0.5#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3851 template 48
db1 = 0.05#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3852 template 48
db1 = 0.005#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3853 template 48
db1 = 0.0005#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3854 template 48
db1 = 0.15#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3855 template 48
db1 = 0.25#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3856 template 48
db1 = 0.35#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3857 template 48
db1 = 0.45#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3858 template 48
db1 = 1#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3859 template 48
db1 = -1#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3860 template 48
db1 = 1.5#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3861 template 48
db1 = 2.5#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3862 template 48
db1 = 9.995#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3863 template 48
db1 = 10#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3864 template 48
db1 = 99.995#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3865 template 48
db1 = 99.9999#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3866 template 48
db1 = 123.456#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3867 template 48
db1 = -123.456#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3868 template 48
db1 = 999.95#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3869 template 48
db1 = 1234.5678#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3870 template 48
db1 = 12345.678#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3871 template 48
db1 = 99999.9#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3872 template 48
db1 = 0.1#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3873 template 48
db1 = 0.00001#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3874 template 48
db1 = 0.000000123#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3875 template 48
db1 = 0.0000000001#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3876 template 48
db1 = 100000#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3877 template 48
db1 = 10000000000#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3878 template 48
db1 = 9999999999999999#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3879 template 48
db1 = 1E+17#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3880 template 48
db1 = 1E+20#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3881 template 48
db1 = 1E+30#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3882 template 48
db1 = -2.5E-30#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3883 template 48
db1 = 1E+300#
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3884 template 48
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3885 template 48
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3886 template 48
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3887 template 48
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3888 template 48
db1 = DblBits(&h1ULL)
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3889 template 48
db1 = DblBits(&h8000000000000001ULL)
Print #2, "48 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(48); db1
' 3890 template 49
sg1 = 0
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3891 template 49
sg1 = SngBits(&h80000000)
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3892 template 49
sg1 = 0.5!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3893 template 49
sg1 = -0.5!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3894 template 49
sg1 = 0.05!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3895 template 49
sg1 = 0.005!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3896 template 49
sg1 = 0.0005!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3897 template 49
sg1 = 0.15!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3898 template 49
sg1 = 0.25!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3899 template 49
sg1 = 0.35!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3900 template 49
sg1 = 0.45!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3901 template 49
sg1 = 1!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3902 template 49
sg1 = -1!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3903 template 49
sg1 = 1.5!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3904 template 49
sg1 = 2.5!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3905 template 49
sg1 = 9.995!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3906 template 49
sg1 = 10!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3907 template 49
sg1 = 99.995!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3908 template 49
sg1 = 99.9999!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3909 template 49
sg1 = 123.456!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3910 template 49
sg1 = -123.456!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3911 template 49
sg1 = 999.95!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3912 template 49
sg1 = 1234.5678!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3913 template 49
sg1 = 12345.678!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3914 template 49
sg1 = 99999.9!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3915 template 49
sg1 = 0.1!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3916 template 49
sg1 = 0.00001!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3917 template 49
sg1 = 0.000000123!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3918 template 49
sg1 = 0.0000000001!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3919 template 49
sg1 = 100000!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3920 template 49
sg1 = 10000000000!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3921 template 49
sg1 = 9999999999999999!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3922 template 49
sg1 = 1E+17!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3923 template 49
sg1 = 1E+20!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3924 template 49
sg1 = 1E+30!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3925 template 49
sg1 = -2.5E-30!
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3926 template 49
sg1 = SngBits(&h7FC00000)
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3927 template 49
sg1 = SngBits(&hFFC00000)
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3928 template 49
sg1 = SngBits(&h7F800000)
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3929 template 49
sg1 = SngBits(&hFF800000)
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3930 template 49
sg1 = SngBits(&h1)
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3931 template 49
sg1 = SngBits(&h80000001)
Print #2, "49 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(49); sg1
' 3932 template 49
db1 = 0#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3933 template 49
db1 = DblBits(&h8000000000000000ULL)
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3934 template 49
db1 = 0.5#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3935 template 49
db1 = -0.5#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3936 template 49
db1 = 0.05#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3937 template 49
db1 = 0.005#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3938 template 49
db1 = 0.0005#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3939 template 49
db1 = 0.15#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3940 template 49
db1 = 0.25#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3941 template 49
db1 = 0.35#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3942 template 49
db1 = 0.45#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3943 template 49
db1 = 1#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3944 template 49
db1 = -1#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3945 template 49
db1 = 1.5#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3946 template 49
db1 = 2.5#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3947 template 49
db1 = 9.995#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3948 template 49
db1 = 10#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3949 template 49
db1 = 99.995#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3950 template 49
db1 = 99.9999#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3951 template 49
db1 = 123.456#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3952 template 49
db1 = -123.456#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3953 template 49
db1 = 999.95#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3954 template 49
db1 = 1234.5678#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3955 template 49
db1 = 12345.678#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3956 template 49
db1 = 99999.9#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3957 template 49
db1 = 0.1#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3958 template 49
db1 = 0.00001#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3959 template 49
db1 = 0.000000123#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3960 template 49
db1 = 0.0000000001#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3961 template 49
db1 = 100000#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3962 template 49
db1 = 10000000000#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3963 template 49
db1 = 9999999999999999#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3964 template 49
db1 = 1E+17#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3965 template 49
db1 = 1E+20#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3966 template 49
db1 = 1E+30#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3967 template 49
db1 = -2.5E-30#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3968 template 49
db1 = 1E+300#
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3969 template 49
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3970 template 49
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3971 template 49
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3972 template 49
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3973 template 49
db1 = DblBits(&h1ULL)
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3974 template 49
db1 = DblBits(&h8000000000000001ULL)
Print #2, "49 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(49); db1
' 3975 template 50
sg1 = 0
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3976 template 50
sg1 = SngBits(&h80000000)
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3977 template 50
sg1 = 0.5!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3978 template 50
sg1 = -0.5!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3979 template 50
sg1 = 0.05!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3980 template 50
sg1 = 0.005!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3981 template 50
sg1 = 0.0005!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3982 template 50
sg1 = 0.15!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3983 template 50
sg1 = 0.25!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3984 template 50
sg1 = 0.35!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3985 template 50
sg1 = 0.45!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3986 template 50
sg1 = 1!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3987 template 50
sg1 = -1!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3988 template 50
sg1 = 1.5!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3989 template 50
sg1 = 2.5!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3990 template 50
sg1 = 9.995!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3991 template 50
sg1 = 10!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3992 template 50
sg1 = 99.995!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3993 template 50
sg1 = 99.9999!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3994 template 50
sg1 = 123.456!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3995 template 50
sg1 = -123.456!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3996 template 50
sg1 = 999.95!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3997 template 50
sg1 = 1234.5678!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3998 template 50
sg1 = 12345.678!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 3999 template 50
sg1 = 99999.9!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4000 template 50
sg1 = 0.1!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4001 template 50
sg1 = 0.00001!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4002 template 50
sg1 = 0.000000123!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4003 template 50
sg1 = 0.0000000001!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4004 template 50
sg1 = 100000!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4005 template 50
sg1 = 10000000000!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4006 template 50
sg1 = 9999999999999999!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4007 template 50
sg1 = 1E+17!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4008 template 50
sg1 = 1E+20!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4009 template 50
sg1 = 1E+30!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4010 template 50
sg1 = -2.5E-30!
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4011 template 50
sg1 = SngBits(&h7FC00000)
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4012 template 50
sg1 = SngBits(&hFFC00000)
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4013 template 50
sg1 = SngBits(&h7F800000)
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4014 template 50
sg1 = SngBits(&hFF800000)
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4015 template 50
sg1 = SngBits(&h1)
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4016 template 50
sg1 = SngBits(&h80000001)
Print #2, "50 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(50); sg1
' 4017 template 50
db1 = 0#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4018 template 50
db1 = DblBits(&h8000000000000000ULL)
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4019 template 50
db1 = 0.5#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4020 template 50
db1 = -0.5#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4021 template 50
db1 = 0.05#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4022 template 50
db1 = 0.005#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4023 template 50
db1 = 0.0005#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4024 template 50
db1 = 0.15#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4025 template 50
db1 = 0.25#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4026 template 50
db1 = 0.35#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4027 template 50
db1 = 0.45#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4028 template 50
db1 = 1#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4029 template 50
db1 = -1#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4030 template 50
db1 = 1.5#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4031 template 50
db1 = 2.5#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4032 template 50
db1 = 9.995#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4033 template 50
db1 = 10#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4034 template 50
db1 = 99.995#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4035 template 50
db1 = 99.9999#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4036 template 50
db1 = 123.456#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4037 template 50
db1 = -123.456#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4038 template 50
db1 = 999.95#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4039 template 50
db1 = 1234.5678#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4040 template 50
db1 = 12345.678#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4041 template 50
db1 = 99999.9#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4042 template 50
db1 = 0.1#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4043 template 50
db1 = 0.00001#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4044 template 50
db1 = 0.000000123#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4045 template 50
db1 = 0.0000000001#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4046 template 50
db1 = 100000#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4047 template 50
db1 = 10000000000#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4048 template 50
db1 = 9999999999999999#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4049 template 50
db1 = 1E+17#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4050 template 50
db1 = 1E+20#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4051 template 50
db1 = 1E+30#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4052 template 50
db1 = -2.5E-30#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4053 template 50
db1 = 1E+300#
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4054 template 50
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4055 template 50
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4056 template 50
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4057 template 50
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4058 template 50
db1 = DblBits(&h1ULL)
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4059 template 50
db1 = DblBits(&h8000000000000001ULL)
Print #2, "50 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(50); db1
' 4060 template 51
sg1 = 0
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4061 template 51
sg1 = SngBits(&h80000000)
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4062 template 51
sg1 = 0.5!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4063 template 51
sg1 = -0.5!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4064 template 51
sg1 = 0.05!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4065 template 51
sg1 = 0.005!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4066 template 51
sg1 = 0.0005!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4067 template 51
sg1 = 0.15!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4068 template 51
sg1 = 0.25!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4069 template 51
sg1 = 0.35!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4070 template 51
sg1 = 0.45!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4071 template 51
sg1 = 1!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4072 template 51
sg1 = -1!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4073 template 51
sg1 = 1.5!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4074 template 51
sg1 = 2.5!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4075 template 51
sg1 = 9.995!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4076 template 51
sg1 = 10!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4077 template 51
sg1 = 99.995!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4078 template 51
sg1 = 99.9999!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4079 template 51
sg1 = 123.456!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4080 template 51
sg1 = -123.456!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4081 template 51
sg1 = 999.95!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4082 template 51
sg1 = 1234.5678!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4083 template 51
sg1 = 12345.678!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4084 template 51
sg1 = 99999.9!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4085 template 51
sg1 = 0.1!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4086 template 51
sg1 = 0.00001!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4087 template 51
sg1 = 0.000000123!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4088 template 51
sg1 = 0.0000000001!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4089 template 51
sg1 = 100000!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4090 template 51
sg1 = 10000000000!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4091 template 51
sg1 = 9999999999999999!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4092 template 51
sg1 = 1E+17!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4093 template 51
sg1 = 1E+20!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4094 template 51
sg1 = 1E+30!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4095 template 51
sg1 = -2.5E-30!
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4096 template 51
sg1 = SngBits(&h7FC00000)
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4097 template 51
sg1 = SngBits(&hFFC00000)
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4098 template 51
sg1 = SngBits(&h7F800000)
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4099 template 51
sg1 = SngBits(&hFF800000)
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4100 template 51
sg1 = SngBits(&h1)
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4101 template 51
sg1 = SngBits(&h80000001)
Print #2, "51 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(51); sg1
' 4102 template 51
db1 = 0#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4103 template 51
db1 = DblBits(&h8000000000000000ULL)
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4104 template 51
db1 = 0.5#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4105 template 51
db1 = -0.5#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4106 template 51
db1 = 0.05#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4107 template 51
db1 = 0.005#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4108 template 51
db1 = 0.0005#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4109 template 51
db1 = 0.15#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4110 template 51
db1 = 0.25#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4111 template 51
db1 = 0.35#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4112 template 51
db1 = 0.45#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4113 template 51
db1 = 1#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4114 template 51
db1 = -1#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4115 template 51
db1 = 1.5#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4116 template 51
db1 = 2.5#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4117 template 51
db1 = 9.995#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4118 template 51
db1 = 10#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4119 template 51
db1 = 99.995#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4120 template 51
db1 = 99.9999#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4121 template 51
db1 = 123.456#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4122 template 51
db1 = -123.456#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4123 template 51
db1 = 999.95#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4124 template 51
db1 = 1234.5678#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4125 template 51
db1 = 12345.678#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4126 template 51
db1 = 99999.9#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4127 template 51
db1 = 0.1#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4128 template 51
db1 = 0.00001#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4129 template 51
db1 = 0.000000123#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4130 template 51
db1 = 0.0000000001#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4131 template 51
db1 = 100000#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4132 template 51
db1 = 10000000000#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4133 template 51
db1 = 9999999999999999#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4134 template 51
db1 = 1E+17#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4135 template 51
db1 = 1E+20#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4136 template 51
db1 = 1E+30#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4137 template 51
db1 = -2.5E-30#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4138 template 51
db1 = 1E+300#
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4139 template 51
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4140 template 51
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4141 template 51
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4142 template 51
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4143 template 51
db1 = DblBits(&h1ULL)
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4144 template 51
db1 = DblBits(&h8000000000000001ULL)
Print #2, "51 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(51); db1
' 4145 template 52
sg1 = 0
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4146 template 52
sg1 = SngBits(&h80000000)
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4147 template 52
sg1 = 0.5!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4148 template 52
sg1 = -0.5!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4149 template 52
sg1 = 0.05!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4150 template 52
sg1 = 0.005!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4151 template 52
sg1 = 0.0005!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4152 template 52
sg1 = 0.15!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4153 template 52
sg1 = 0.25!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4154 template 52
sg1 = 0.35!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4155 template 52
sg1 = 0.45!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4156 template 52
sg1 = 1!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4157 template 52
sg1 = -1!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4158 template 52
sg1 = 1.5!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4159 template 52
sg1 = 2.5!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4160 template 52
sg1 = 9.995!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4161 template 52
sg1 = 10!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4162 template 52
sg1 = 99.995!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4163 template 52
sg1 = 99.9999!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4164 template 52
sg1 = 123.456!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4165 template 52
sg1 = -123.456!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4166 template 52
sg1 = 999.95!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4167 template 52
sg1 = 1234.5678!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4168 template 52
sg1 = 12345.678!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4169 template 52
sg1 = 99999.9!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4170 template 52
sg1 = 0.1!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4171 template 52
sg1 = 0.00001!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4172 template 52
sg1 = 0.000000123!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4173 template 52
sg1 = 0.0000000001!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4174 template 52
sg1 = 100000!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4175 template 52
sg1 = 10000000000!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4176 template 52
sg1 = 9999999999999999!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4177 template 52
sg1 = 1E+17!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4178 template 52
sg1 = 1E+20!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4179 template 52
sg1 = 1E+30!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4180 template 52
sg1 = -2.5E-30!
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4181 template 52
sg1 = SngBits(&h7FC00000)
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4182 template 52
sg1 = SngBits(&hFFC00000)
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4183 template 52
sg1 = SngBits(&h7F800000)
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4184 template 52
sg1 = SngBits(&hFF800000)
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4185 template 52
sg1 = SngBits(&h1)
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4186 template 52
sg1 = SngBits(&h80000001)
Print #2, "52 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(52); sg1
' 4187 template 52
li1 = 0
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4188 template 52
li1 = 1
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4189 template 52
li1 = -1
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4190 template 52
li1 = 42
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4191 template 52
li1 = -7
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4192 template 52
li1 = 12345
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4193 template 52
li1 = 99999
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4194 template 52
li1 = 100000
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4195 template 52
li1 = 999999999
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4196 template 52
li1 = -2147483648
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4197 template 52
li1 = 2147483647
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4198 template 52
li1 = 9223372036854775807
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4199 template 52
li1 = (-9223372036854775807 - 1)
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4200 template 52
li1 = 1000000
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4201 template 52
li1 = 123456789012
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4202 template 52
li1 = -100
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4203 template 52
li1 = 5
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4204 template 52
li1 = 10
Print #2, "52 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(52); li1
' 4205 template 53
sg1 = 0
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4206 template 53
sg1 = SngBits(&h80000000)
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4207 template 53
sg1 = 0.5!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4208 template 53
sg1 = -0.5!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4209 template 53
sg1 = 0.05!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4210 template 53
sg1 = 0.005!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4211 template 53
sg1 = 0.0005!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4212 template 53
sg1 = 0.15!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4213 template 53
sg1 = 0.25!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4214 template 53
sg1 = 0.35!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4215 template 53
sg1 = 0.45!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4216 template 53
sg1 = 1!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4217 template 53
sg1 = -1!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4218 template 53
sg1 = 1.5!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4219 template 53
sg1 = 2.5!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4220 template 53
sg1 = 9.995!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4221 template 53
sg1 = 10!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4222 template 53
sg1 = 99.995!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4223 template 53
sg1 = 99.9999!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4224 template 53
sg1 = 123.456!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4225 template 53
sg1 = -123.456!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4226 template 53
sg1 = 999.95!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4227 template 53
sg1 = 1234.5678!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4228 template 53
sg1 = 12345.678!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4229 template 53
sg1 = 99999.9!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4230 template 53
sg1 = 0.1!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4231 template 53
sg1 = 0.00001!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4232 template 53
sg1 = 0.000000123!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4233 template 53
sg1 = 0.0000000001!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4234 template 53
sg1 = 100000!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4235 template 53
sg1 = 10000000000!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4236 template 53
sg1 = 9999999999999999!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4237 template 53
sg1 = 1E+17!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4238 template 53
sg1 = 1E+20!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4239 template 53
sg1 = 1E+30!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4240 template 53
sg1 = -2.5E-30!
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4241 template 53
sg1 = SngBits(&h7FC00000)
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4242 template 53
sg1 = SngBits(&hFFC00000)
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4243 template 53
sg1 = SngBits(&h7F800000)
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4244 template 53
sg1 = SngBits(&hFF800000)
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4245 template 53
sg1 = SngBits(&h1)
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4246 template 53
sg1 = SngBits(&h80000001)
Print #2, "53 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(53); sg1
' 4247 template 53
db1 = 0#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4248 template 53
db1 = DblBits(&h8000000000000000ULL)
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4249 template 53
db1 = 0.5#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4250 template 53
db1 = -0.5#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4251 template 53
db1 = 0.05#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4252 template 53
db1 = 0.005#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4253 template 53
db1 = 0.0005#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4254 template 53
db1 = 0.15#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4255 template 53
db1 = 0.25#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4256 template 53
db1 = 0.35#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4257 template 53
db1 = 0.45#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4258 template 53
db1 = 1#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4259 template 53
db1 = -1#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4260 template 53
db1 = 1.5#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4261 template 53
db1 = 2.5#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4262 template 53
db1 = 9.995#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4263 template 53
db1 = 10#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4264 template 53
db1 = 99.995#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4265 template 53
db1 = 99.9999#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4266 template 53
db1 = 123.456#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4267 template 53
db1 = -123.456#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4268 template 53
db1 = 999.95#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4269 template 53
db1 = 1234.5678#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4270 template 53
db1 = 12345.678#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4271 template 53
db1 = 99999.9#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4272 template 53
db1 = 0.1#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4273 template 53
db1 = 0.00001#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4274 template 53
db1 = 0.000000123#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4275 template 53
db1 = 0.0000000001#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4276 template 53
db1 = 100000#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4277 template 53
db1 = 10000000000#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4278 template 53
db1 = 9999999999999999#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4279 template 53
db1 = 1E+17#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4280 template 53
db1 = 1E+20#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4281 template 53
db1 = 1E+30#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4282 template 53
db1 = -2.5E-30#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4283 template 53
db1 = 1E+300#
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4284 template 53
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4285 template 53
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4286 template 53
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4287 template 53
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4288 template 53
db1 = DblBits(&h1ULL)
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4289 template 53
db1 = DblBits(&h8000000000000001ULL)
Print #2, "53 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(53); db1
' 4290 template 54
sg1 = 0
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4291 template 54
sg1 = SngBits(&h80000000)
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4292 template 54
sg1 = 0.5!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4293 template 54
sg1 = -0.5!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4294 template 54
sg1 = 0.05!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4295 template 54
sg1 = 0.005!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4296 template 54
sg1 = 0.0005!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4297 template 54
sg1 = 0.15!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4298 template 54
sg1 = 0.25!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4299 template 54
sg1 = 0.35!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4300 template 54
sg1 = 0.45!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4301 template 54
sg1 = 1!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4302 template 54
sg1 = -1!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4303 template 54
sg1 = 1.5!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4304 template 54
sg1 = 2.5!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4305 template 54
sg1 = 9.995!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4306 template 54
sg1 = 10!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4307 template 54
sg1 = 99.995!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4308 template 54
sg1 = 99.9999!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4309 template 54
sg1 = 123.456!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4310 template 54
sg1 = -123.456!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4311 template 54
sg1 = 999.95!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4312 template 54
sg1 = 1234.5678!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4313 template 54
sg1 = 12345.678!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4314 template 54
sg1 = 99999.9!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4315 template 54
sg1 = 0.1!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4316 template 54
sg1 = 0.00001!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4317 template 54
sg1 = 0.000000123!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4318 template 54
sg1 = 0.0000000001!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4319 template 54
sg1 = 100000!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4320 template 54
sg1 = 10000000000!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4321 template 54
sg1 = 9999999999999999!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4322 template 54
sg1 = 1E+17!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4323 template 54
sg1 = 1E+20!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4324 template 54
sg1 = 1E+30!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4325 template 54
sg1 = -2.5E-30!
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4326 template 54
sg1 = SngBits(&h7FC00000)
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4327 template 54
sg1 = SngBits(&hFFC00000)
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4328 template 54
sg1 = SngBits(&h7F800000)
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4329 template 54
sg1 = SngBits(&hFF800000)
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4330 template 54
sg1 = SngBits(&h1)
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4331 template 54
sg1 = SngBits(&h80000001)
Print #2, "54 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(54); sg1
' 4332 template 54
db1 = 0#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4333 template 54
db1 = DblBits(&h8000000000000000ULL)
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4334 template 54
db1 = 0.5#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4335 template 54
db1 = -0.5#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4336 template 54
db1 = 0.05#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4337 template 54
db1 = 0.005#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4338 template 54
db1 = 0.0005#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4339 template 54
db1 = 0.15#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4340 template 54
db1 = 0.25#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4341 template 54
db1 = 0.35#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4342 template 54
db1 = 0.45#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4343 template 54
db1 = 1#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4344 template 54
db1 = -1#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4345 template 54
db1 = 1.5#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4346 template 54
db1 = 2.5#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4347 template 54
db1 = 9.995#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4348 template 54
db1 = 10#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4349 template 54
db1 = 99.995#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4350 template 54
db1 = 99.9999#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4351 template 54
db1 = 123.456#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4352 template 54
db1 = -123.456#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4353 template 54
db1 = 999.95#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4354 template 54
db1 = 1234.5678#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4355 template 54
db1 = 12345.678#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4356 template 54
db1 = 99999.9#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4357 template 54
db1 = 0.1#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4358 template 54
db1 = 0.00001#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4359 template 54
db1 = 0.000000123#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4360 template 54
db1 = 0.0000000001#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4361 template 54
db1 = 100000#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4362 template 54
db1 = 10000000000#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4363 template 54
db1 = 9999999999999999#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4364 template 54
db1 = 1E+17#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4365 template 54
db1 = 1E+20#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4366 template 54
db1 = 1E+30#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4367 template 54
db1 = -2.5E-30#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4368 template 54
db1 = 1E+300#
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4369 template 54
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4370 template 54
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4371 template 54
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4372 template 54
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4373 template 54
db1 = DblBits(&h1ULL)
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4374 template 54
db1 = DblBits(&h8000000000000001ULL)
Print #2, "54 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(54); db1
' 4375 template 55
sg1 = 0
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4376 template 55
sg1 = SngBits(&h80000000)
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4377 template 55
sg1 = 0.5!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4378 template 55
sg1 = -0.5!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4379 template 55
sg1 = 0.05!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4380 template 55
sg1 = 0.005!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4381 template 55
sg1 = 0.0005!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4382 template 55
sg1 = 0.15!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4383 template 55
sg1 = 0.25!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4384 template 55
sg1 = 0.35!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4385 template 55
sg1 = 0.45!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4386 template 55
sg1 = 1!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4387 template 55
sg1 = -1!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4388 template 55
sg1 = 1.5!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4389 template 55
sg1 = 2.5!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4390 template 55
sg1 = 9.995!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4391 template 55
sg1 = 10!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4392 template 55
sg1 = 99.995!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4393 template 55
sg1 = 99.9999!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4394 template 55
sg1 = 123.456!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4395 template 55
sg1 = -123.456!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4396 template 55
sg1 = 999.95!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4397 template 55
sg1 = 1234.5678!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4398 template 55
sg1 = 12345.678!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4399 template 55
sg1 = 99999.9!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4400 template 55
sg1 = 0.1!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4401 template 55
sg1 = 0.00001!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4402 template 55
sg1 = 0.000000123!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4403 template 55
sg1 = 0.0000000001!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4404 template 55
sg1 = 100000!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4405 template 55
sg1 = 10000000000!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4406 template 55
sg1 = 9999999999999999!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4407 template 55
sg1 = 1E+17!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4408 template 55
sg1 = 1E+20!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4409 template 55
sg1 = 1E+30!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4410 template 55
sg1 = -2.5E-30!
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4411 template 55
sg1 = SngBits(&h7FC00000)
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4412 template 55
sg1 = SngBits(&hFFC00000)
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4413 template 55
sg1 = SngBits(&h7F800000)
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4414 template 55
sg1 = SngBits(&hFF800000)
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4415 template 55
sg1 = SngBits(&h1)
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4416 template 55
sg1 = SngBits(&h80000001)
Print #2, "55 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(55); sg1
' 4417 template 55
li1 = 0
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4418 template 55
li1 = 1
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4419 template 55
li1 = -1
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4420 template 55
li1 = 42
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4421 template 55
li1 = -7
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4422 template 55
li1 = 12345
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4423 template 55
li1 = 99999
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4424 template 55
li1 = 100000
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4425 template 55
li1 = 999999999
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4426 template 55
li1 = -2147483648
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4427 template 55
li1 = 2147483647
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4428 template 55
li1 = 9223372036854775807
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4429 template 55
li1 = (-9223372036854775807 - 1)
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4430 template 55
li1 = 1000000
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4431 template 55
li1 = 123456789012
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4432 template 55
li1 = -100
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4433 template 55
li1 = 5
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4434 template 55
li1 = 10
Print #2, "55 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(55); li1
' 4435 template 56
sg1 = 0
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4436 template 56
sg1 = SngBits(&h80000000)
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4437 template 56
sg1 = 0.5!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4438 template 56
sg1 = -0.5!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4439 template 56
sg1 = 0.05!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4440 template 56
sg1 = 0.005!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4441 template 56
sg1 = 0.0005!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4442 template 56
sg1 = 0.15!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4443 template 56
sg1 = 0.25!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4444 template 56
sg1 = 0.35!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4445 template 56
sg1 = 0.45!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4446 template 56
sg1 = 1!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4447 template 56
sg1 = -1!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4448 template 56
sg1 = 1.5!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4449 template 56
sg1 = 2.5!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4450 template 56
sg1 = 9.995!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4451 template 56
sg1 = 10!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4452 template 56
sg1 = 99.995!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4453 template 56
sg1 = 99.9999!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4454 template 56
sg1 = 123.456!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4455 template 56
sg1 = -123.456!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4456 template 56
sg1 = 999.95!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4457 template 56
sg1 = 1234.5678!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4458 template 56
sg1 = 12345.678!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4459 template 56
sg1 = 99999.9!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4460 template 56
sg1 = 0.1!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4461 template 56
sg1 = 0.00001!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4462 template 56
sg1 = 0.000000123!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4463 template 56
sg1 = 0.0000000001!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4464 template 56
sg1 = 100000!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4465 template 56
sg1 = 10000000000!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4466 template 56
sg1 = 9999999999999999!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4467 template 56
sg1 = 1E+17!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4468 template 56
sg1 = 1E+20!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4469 template 56
sg1 = 1E+30!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4470 template 56
sg1 = -2.5E-30!
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4471 template 56
sg1 = SngBits(&h7FC00000)
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4472 template 56
sg1 = SngBits(&hFFC00000)
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4473 template 56
sg1 = SngBits(&h7F800000)
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4474 template 56
sg1 = SngBits(&hFF800000)
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4475 template 56
sg1 = SngBits(&h1)
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4476 template 56
sg1 = SngBits(&h80000001)
Print #2, "56 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(56); sg1
' 4477 template 56
li1 = 0
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4478 template 56
li1 = 1
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4479 template 56
li1 = -1
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4480 template 56
li1 = 42
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4481 template 56
li1 = -7
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4482 template 56
li1 = 12345
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4483 template 56
li1 = 99999
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4484 template 56
li1 = 100000
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4485 template 56
li1 = 999999999
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4486 template 56
li1 = -2147483648
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4487 template 56
li1 = 2147483647
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4488 template 56
li1 = 9223372036854775807
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4489 template 56
li1 = (-9223372036854775807 - 1)
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4490 template 56
li1 = 1000000
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4491 template 56
li1 = 123456789012
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4492 template 56
li1 = -100
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4493 template 56
li1 = 5
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4494 template 56
li1 = 10
Print #2, "56 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(56); li1
' 4495 template 57
sg1 = 0
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4496 template 57
sg1 = SngBits(&h80000000)
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4497 template 57
sg1 = 0.5!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4498 template 57
sg1 = -0.5!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4499 template 57
sg1 = 0.05!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4500 template 57
sg1 = 0.005!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4501 template 57
sg1 = 0.0005!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4502 template 57
sg1 = 0.15!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4503 template 57
sg1 = 0.25!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4504 template 57
sg1 = 0.35!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4505 template 57
sg1 = 0.45!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4506 template 57
sg1 = 1!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4507 template 57
sg1 = -1!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4508 template 57
sg1 = 1.5!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4509 template 57
sg1 = 2.5!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4510 template 57
sg1 = 9.995!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4511 template 57
sg1 = 10!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4512 template 57
sg1 = 99.995!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4513 template 57
sg1 = 99.9999!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4514 template 57
sg1 = 123.456!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4515 template 57
sg1 = -123.456!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4516 template 57
sg1 = 999.95!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4517 template 57
sg1 = 1234.5678!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4518 template 57
sg1 = 12345.678!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4519 template 57
sg1 = 99999.9!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4520 template 57
sg1 = 0.1!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4521 template 57
sg1 = 0.00001!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4522 template 57
sg1 = 0.000000123!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4523 template 57
sg1 = 0.0000000001!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4524 template 57
sg1 = 100000!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4525 template 57
sg1 = 10000000000!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4526 template 57
sg1 = 9999999999999999!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4527 template 57
sg1 = 1E+17!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4528 template 57
sg1 = 1E+20!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4529 template 57
sg1 = 1E+30!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4530 template 57
sg1 = -2.5E-30!
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4531 template 57
sg1 = SngBits(&h7FC00000)
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4532 template 57
sg1 = SngBits(&hFFC00000)
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4533 template 57
sg1 = SngBits(&h7F800000)
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4534 template 57
sg1 = SngBits(&hFF800000)
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4535 template 57
sg1 = SngBits(&h1)
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4536 template 57
sg1 = SngBits(&h80000001)
Print #2, "57 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(57); sg1
' 4537 template 57
db1 = 0#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4538 template 57
db1 = DblBits(&h8000000000000000ULL)
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4539 template 57
db1 = 0.5#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4540 template 57
db1 = -0.5#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4541 template 57
db1 = 0.05#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4542 template 57
db1 = 0.005#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4543 template 57
db1 = 0.0005#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4544 template 57
db1 = 0.15#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4545 template 57
db1 = 0.25#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4546 template 57
db1 = 0.35#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4547 template 57
db1 = 0.45#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4548 template 57
db1 = 1#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4549 template 57
db1 = -1#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4550 template 57
db1 = 1.5#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4551 template 57
db1 = 2.5#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4552 template 57
db1 = 9.995#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4553 template 57
db1 = 10#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4554 template 57
db1 = 99.995#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4555 template 57
db1 = 99.9999#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4556 template 57
db1 = 123.456#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4557 template 57
db1 = -123.456#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4558 template 57
db1 = 999.95#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4559 template 57
db1 = 1234.5678#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4560 template 57
db1 = 12345.678#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4561 template 57
db1 = 99999.9#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4562 template 57
db1 = 0.1#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4563 template 57
db1 = 0.00001#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4564 template 57
db1 = 0.000000123#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4565 template 57
db1 = 0.0000000001#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4566 template 57
db1 = 100000#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4567 template 57
db1 = 10000000000#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4568 template 57
db1 = 9999999999999999#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4569 template 57
db1 = 1E+17#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4570 template 57
db1 = 1E+20#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4571 template 57
db1 = 1E+30#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4572 template 57
db1 = -2.5E-30#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4573 template 57
db1 = 1E+300#
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4574 template 57
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4575 template 57
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4576 template 57
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4577 template 57
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4578 template 57
db1 = DblBits(&h1ULL)
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4579 template 57
db1 = DblBits(&h8000000000000001ULL)
Print #2, "57 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(57); db1
' 4580 template 58
sg1 = 0
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4581 template 58
sg1 = SngBits(&h80000000)
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4582 template 58
sg1 = 0.5!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4583 template 58
sg1 = -0.5!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4584 template 58
sg1 = 0.05!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4585 template 58
sg1 = 0.005!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4586 template 58
sg1 = 0.0005!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4587 template 58
sg1 = 0.15!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4588 template 58
sg1 = 0.25!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4589 template 58
sg1 = 0.35!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4590 template 58
sg1 = 0.45!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4591 template 58
sg1 = 1!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4592 template 58
sg1 = -1!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4593 template 58
sg1 = 1.5!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4594 template 58
sg1 = 2.5!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4595 template 58
sg1 = 9.995!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4596 template 58
sg1 = 10!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4597 template 58
sg1 = 99.995!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4598 template 58
sg1 = 99.9999!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4599 template 58
sg1 = 123.456!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4600 template 58
sg1 = -123.456!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4601 template 58
sg1 = 999.95!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4602 template 58
sg1 = 1234.5678!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4603 template 58
sg1 = 12345.678!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4604 template 58
sg1 = 99999.9!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4605 template 58
sg1 = 0.1!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4606 template 58
sg1 = 0.00001!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4607 template 58
sg1 = 0.000000123!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4608 template 58
sg1 = 0.0000000001!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4609 template 58
sg1 = 100000!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4610 template 58
sg1 = 10000000000!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4611 template 58
sg1 = 9999999999999999!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4612 template 58
sg1 = 1E+17!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4613 template 58
sg1 = 1E+20!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4614 template 58
sg1 = 1E+30!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4615 template 58
sg1 = -2.5E-30!
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4616 template 58
sg1 = SngBits(&h7FC00000)
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4617 template 58
sg1 = SngBits(&hFFC00000)
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4618 template 58
sg1 = SngBits(&h7F800000)
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4619 template 58
sg1 = SngBits(&hFF800000)
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4620 template 58
sg1 = SngBits(&h1)
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4621 template 58
sg1 = SngBits(&h80000001)
Print #2, "58 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(58); sg1
' 4622 template 58
li1 = 0
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4623 template 58
li1 = 1
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4624 template 58
li1 = -1
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4625 template 58
li1 = 42
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4626 template 58
li1 = -7
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4627 template 58
li1 = 12345
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4628 template 58
li1 = 99999
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4629 template 58
li1 = 100000
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4630 template 58
li1 = 999999999
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4631 template 58
li1 = -2147483648
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4632 template 58
li1 = 2147483647
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4633 template 58
li1 = 9223372036854775807
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4634 template 58
li1 = (-9223372036854775807 - 1)
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4635 template 58
li1 = 1000000
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4636 template 58
li1 = 123456789012
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4637 template 58
li1 = -100
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4638 template 58
li1 = 5
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4639 template 58
li1 = 10
Print #2, "58 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(58); li1
' 4640 template 59
st1 = "A"
Print #2, "59 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(59); st1
' 4641 template 59
st1 = "abc"
Print #2, "59 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(59); st1
' 4642 template 59
st1 = "exactly14chars"
Print #2, "59 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(59); st1
' 4643 template 59
st1 = "a string longer than any field"
Print #2, "59 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(59); st1
' 4644 template 59
st1 = " lead"
Print #2, "59 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(59); st1
' 4645 template 59
st1 = "12345678901234567890"
Print #2, "59 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(59); st1
' 4646 template 59
st1 = "x y"
Print #2, "59 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(59); st1
' 4647 template 59
st1 = "A"
Print #2, "59 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(59); st1
' 4648 template 60
st1 = ""
Print #2, "60 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(60); st1
' 4649 template 60
st1 = "A"
Print #2, "60 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(60); st1
' 4650 template 60
st1 = "abc"
Print #2, "60 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(60); st1
' 4651 template 60
st1 = "exactly14chars"
Print #2, "60 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(60); st1
' 4652 template 60
st1 = "a string longer than any field"
Print #2, "60 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(60); st1
' 4653 template 60
st1 = " lead"
Print #2, "60 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(60); st1
' 4654 template 60
st1 = "12345678901234567890"
Print #2, "60 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(60); st1
' 4655 template 60
st1 = "x y"
Print #2, "60 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(60); st1
' 4656 template 61
st1 = ""
st2 = " lead"
Print #2, "61 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(61); st1; st2
' 4657 template 61
st1 = "A"
st2 = "12345678901234567890"
Print #2, "61 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(61); st1; st2
' 4658 template 61
st1 = "abc"
st2 = "x y"
Print #2, "61 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(61); st1; st2
' 4659 template 61
st1 = "exactly14chars"
st2 = ""
Print #2, "61 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(61); st1; st2
' 4660 template 61
st1 = "a string longer than any field"
st2 = "A"
Print #2, "61 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(61); st1; st2
' 4661 template 61
st1 = " lead"
st2 = "abc"
Print #2, "61 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(61); st1; st2
' 4662 template 61
st1 = "12345678901234567890"
st2 = "exactly14chars"
Print #2, "61 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(61); st1; st2
' 4663 template 61
st1 = "x y"
st2 = "a string longer than any field"
Print #2, "61 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(61); st1; st2
' 4664 template 62
st1 = "A"
Print #2, "62 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(62); st1
' 4665 template 62
st1 = "abc"
Print #2, "62 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(62); st1
' 4666 template 62
st1 = "exactly14chars"
Print #2, "62 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(62); st1
' 4667 template 62
st1 = "a string longer than any field"
Print #2, "62 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(62); st1
' 4668 template 62
st1 = " lead"
Print #2, "62 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(62); st1
' 4669 template 62
st1 = "12345678901234567890"
Print #2, "62 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(62); st1
' 4670 template 62
st1 = "x y"
Print #2, "62 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(62); st1
' 4671 template 62
st1 = "A"
Print #2, "62 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(62); st1
' 4672 template 63
st1 = "A"
Print #2, "63 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(63); st1
' 4673 template 63
st1 = "abc"
Print #2, "63 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(63); st1
' 4674 template 63
st1 = "exactly14chars"
Print #2, "63 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(63); st1
' 4675 template 63
st1 = "a string longer than any field"
Print #2, "63 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(63); st1
' 4676 template 63
st1 = " lead"
Print #2, "63 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(63); st1
' 4677 template 63
st1 = "12345678901234567890"
Print #2, "63 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(63); st1
' 4678 template 63
st1 = "x y"
Print #2, "63 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(63); st1
' 4679 template 63
st1 = "A"
Print #2, "63 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(63); st1
' 4680 template 64
st1 = "A"
Print #2, "64 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(64); st1
' 4681 template 64
st1 = "abc"
Print #2, "64 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(64); st1
' 4682 template 64
st1 = "exactly14chars"
Print #2, "64 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(64); st1
' 4683 template 64
st1 = "a string longer than any field"
Print #2, "64 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(64); st1
' 4684 template 64
st1 = " lead"
Print #2, "64 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(64); st1
' 4685 template 64
st1 = "12345678901234567890"
Print #2, "64 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(64); st1
' 4686 template 64
st1 = "x y"
Print #2, "64 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(64); st1
' 4687 template 64
st1 = "A"
Print #2, "64 1" & " " & "s:" & BHex(st1)
Print #1, Using tpl(64); st1
' 4688 template 65
st1 = "A"
st2 = "12345678901234567890"
st3 = "abc"
Print #2, "65 3" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(65); st1; st2; st3
' 4689 template 65
st1 = "abc"
st2 = "x y"
st3 = "exactly14chars"
Print #2, "65 3" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(65); st1; st2; st3
' 4690 template 65
st1 = "exactly14chars"
st2 = "A"
st3 = "a string longer than any field"
Print #2, "65 3" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(65); st1; st2; st3
' 4691 template 65
st1 = "a string longer than any field"
st2 = "abc"
st3 = " lead"
Print #2, "65 3" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(65); st1; st2; st3
' 4692 template 65
st1 = " lead"
st2 = "exactly14chars"
st3 = "12345678901234567890"
Print #2, "65 3" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(65); st1; st2; st3
' 4693 template 65
st1 = "12345678901234567890"
st2 = "a string longer than any field"
st3 = "x y"
Print #2, "65 3" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(65); st1; st2; st3
' 4694 template 65
st1 = "x y"
st2 = " lead"
st3 = ""
Print #2, "65 3" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(65); st1; st2; st3
' 4695 template 65
st1 = "A"
st2 = "12345678901234567890"
st3 = "A"
Print #2, "65 3" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(65); st1; st2; st3
' 4696 template 66
sg1 = 0
st2 = " lead"
st3 = "a string longer than any field"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4697 template 66
sg1 = SngBits(&h80000000)
st2 = "12345678901234567890"
st3 = " lead"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4698 template 66
sg1 = 0.5!
st2 = "x y"
st3 = "12345678901234567890"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4699 template 66
sg1 = -0.5!
st2 = ""
st3 = "x y"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4700 template 66
sg1 = 0.05!
st2 = "A"
st3 = "A"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4701 template 66
sg1 = 0.005!
st2 = "abc"
st3 = "abc"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4702 template 66
sg1 = 0.0005!
st2 = "exactly14chars"
st3 = "exactly14chars"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4703 template 66
sg1 = 0.15!
st2 = "a string longer than any field"
st3 = "a string longer than any field"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4704 template 66
sg1 = 0.25!
st2 = " lead"
st3 = " lead"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4705 template 66
sg1 = 0.35!
st2 = "12345678901234567890"
st3 = "12345678901234567890"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4706 template 66
sg1 = 0.45!
st2 = "x y"
st3 = "x y"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4707 template 66
sg1 = 1!
st2 = ""
st3 = "A"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4708 template 66
sg1 = -1!
st2 = "A"
st3 = "abc"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4709 template 66
sg1 = 1.5!
st2 = "abc"
st3 = "exactly14chars"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4710 template 66
sg1 = 2.5!
st2 = "exactly14chars"
st3 = "a string longer than any field"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4711 template 66
sg1 = 9.995!
st2 = "a string longer than any field"
st3 = " lead"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4712 template 66
sg1 = 10!
st2 = " lead"
st3 = "12345678901234567890"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4713 template 66
sg1 = 99.995!
st2 = "12345678901234567890"
st3 = "x y"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4714 template 66
sg1 = 99.9999!
st2 = "x y"
st3 = "A"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4715 template 66
sg1 = 123.456!
st2 = ""
st3 = "abc"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4716 template 66
sg1 = -123.456!
st2 = "A"
st3 = "exactly14chars"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4717 template 66
sg1 = 999.95!
st2 = "abc"
st3 = "a string longer than any field"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4718 template 66
sg1 = 1234.5678!
st2 = "exactly14chars"
st3 = " lead"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4719 template 66
sg1 = 12345.678!
st2 = "a string longer than any field"
st3 = "12345678901234567890"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4720 template 66
sg1 = 99999.9!
st2 = " lead"
st3 = "x y"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4721 template 66
sg1 = 0.1!
st2 = "12345678901234567890"
st3 = "A"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4722 template 66
sg1 = 0.00001!
st2 = "x y"
st3 = "abc"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4723 template 66
sg1 = 0.000000123!
st2 = ""
st3 = "exactly14chars"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4724 template 66
sg1 = 0.0000000001!
st2 = "A"
st3 = "a string longer than any field"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4725 template 66
sg1 = 100000!
st2 = "abc"
st3 = " lead"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4726 template 66
sg1 = 10000000000!
st2 = "exactly14chars"
st3 = "12345678901234567890"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4727 template 66
sg1 = 9999999999999999!
st2 = "a string longer than any field"
st3 = "x y"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4728 template 66
sg1 = 1E+17!
st2 = " lead"
st3 = "A"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4729 template 66
sg1 = 1E+20!
st2 = "12345678901234567890"
st3 = "abc"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4730 template 66
sg1 = 1E+30!
st2 = "x y"
st3 = "exactly14chars"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4731 template 66
sg1 = -2.5E-30!
st2 = ""
st3 = "a string longer than any field"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4732 template 66
sg1 = SngBits(&h7FC00000)
st2 = "A"
st3 = " lead"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4733 template 66
sg1 = SngBits(&hFFC00000)
st2 = "abc"
st3 = "12345678901234567890"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4734 template 66
sg1 = SngBits(&h7F800000)
st2 = "exactly14chars"
st3 = "x y"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4735 template 66
sg1 = SngBits(&hFF800000)
st2 = "a string longer than any field"
st3 = "A"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4736 template 66
sg1 = SngBits(&h1)
st2 = " lead"
st3 = "abc"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4737 template 66
sg1 = SngBits(&h80000001)
st2 = "12345678901234567890"
st3 = "exactly14chars"
Print #2, "66 3" & " " & "f:" & SHex(sg1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); sg1; st2; st3
' 4738 template 66
li1 = 0
st2 = " lead"
st3 = "a string longer than any field"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4739 template 66
li1 = 1
st2 = "12345678901234567890"
st3 = " lead"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4740 template 66
li1 = -1
st2 = "x y"
st3 = "12345678901234567890"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4741 template 66
li1 = 42
st2 = ""
st3 = "x y"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4742 template 66
li1 = -7
st2 = "A"
st3 = "A"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4743 template 66
li1 = 12345
st2 = "abc"
st3 = "abc"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4744 template 66
li1 = 99999
st2 = "exactly14chars"
st3 = "exactly14chars"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4745 template 66
li1 = 100000
st2 = "a string longer than any field"
st3 = "a string longer than any field"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4746 template 66
li1 = 999999999
st2 = " lead"
st3 = " lead"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4747 template 66
li1 = -2147483648
st2 = "12345678901234567890"
st3 = "12345678901234567890"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4748 template 66
li1 = 2147483647
st2 = "x y"
st3 = "x y"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4749 template 66
li1 = 9223372036854775807
st2 = ""
st3 = "A"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4750 template 66
li1 = (-9223372036854775807 - 1)
st2 = "A"
st3 = "abc"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4751 template 66
li1 = 1000000
st2 = "abc"
st3 = "exactly14chars"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4752 template 66
li1 = 123456789012
st2 = "exactly14chars"
st3 = "a string longer than any field"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4753 template 66
li1 = -100
st2 = "a string longer than any field"
st3 = " lead"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4754 template 66
li1 = 5
st2 = " lead"
st3 = "12345678901234567890"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4755 template 66
li1 = 10
st2 = "12345678901234567890"
st3 = "x y"
Print #2, "66 3" & " " & "l:" & LHex(li1) & " " & "s:" & BHex(st2) & " " & "s:" & BHex(st3)
Print #1, Using tpl(66); li1; st2; st3
' 4756 template 67
st1 = "A"
sg2 = 0.005!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4757 template 67
st1 = "abc"
sg2 = 0.0005!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4758 template 67
st1 = "exactly14chars"
sg2 = 0.15!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4759 template 67
st1 = "a string longer than any field"
sg2 = 0.25!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4760 template 67
st1 = " lead"
sg2 = 0.35!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4761 template 67
st1 = "12345678901234567890"
sg2 = 0.45!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4762 template 67
st1 = "x y"
sg2 = 1!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4763 template 67
st1 = "A"
sg2 = -1!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4764 template 67
st1 = "abc"
sg2 = 1.5!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4765 template 67
st1 = "exactly14chars"
sg2 = 2.5!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4766 template 67
st1 = "a string longer than any field"
sg2 = 9.995!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4767 template 67
st1 = " lead"
sg2 = 10!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4768 template 67
st1 = "12345678901234567890"
sg2 = 99.995!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4769 template 67
st1 = "x y"
sg2 = 99.9999!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4770 template 67
st1 = "A"
sg2 = 123.456!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4771 template 67
st1 = "abc"
sg2 = -123.456!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4772 template 67
st1 = "exactly14chars"
sg2 = 999.95!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4773 template 67
st1 = "a string longer than any field"
sg2 = 1234.5678!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4774 template 67
st1 = " lead"
sg2 = 12345.678!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4775 template 67
st1 = "12345678901234567890"
sg2 = 99999.9!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4776 template 67
st1 = "x y"
sg2 = 0.1!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4777 template 67
st1 = "A"
sg2 = 0.00001!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4778 template 67
st1 = "abc"
sg2 = 0.000000123!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4779 template 67
st1 = "exactly14chars"
sg2 = 0.0000000001!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4780 template 67
st1 = "a string longer than any field"
sg2 = 100000!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4781 template 67
st1 = " lead"
sg2 = 10000000000!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4782 template 67
st1 = "12345678901234567890"
sg2 = 9999999999999999!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4783 template 67
st1 = "x y"
sg2 = 1E+17!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4784 template 67
st1 = "A"
sg2 = 1E+20!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4785 template 67
st1 = "abc"
sg2 = 1E+30!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4786 template 67
st1 = "exactly14chars"
sg2 = -2.5E-30!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4787 template 67
st1 = "a string longer than any field"
sg2 = SngBits(&h7FC00000)
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4788 template 67
st1 = " lead"
sg2 = SngBits(&hFFC00000)
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4789 template 67
st1 = "12345678901234567890"
sg2 = SngBits(&h7F800000)
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4790 template 67
st1 = "x y"
sg2 = SngBits(&hFF800000)
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4791 template 67
st1 = "A"
sg2 = SngBits(&h1)
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4792 template 67
st1 = "abc"
sg2 = SngBits(&h80000001)
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4793 template 67
st1 = "exactly14chars"
sg2 = 0
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4794 template 67
st1 = "a string longer than any field"
sg2 = SngBits(&h80000000)
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4795 template 67
st1 = " lead"
sg2 = 0.5!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4796 template 67
st1 = "12345678901234567890"
sg2 = -0.5!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4797 template 67
st1 = "x y"
sg2 = 0.05!
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(67); st1; sg2
' 4798 template 67
st1 = "A"
li2 = 12345
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4799 template 67
st1 = "abc"
li2 = 99999
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4800 template 67
st1 = "exactly14chars"
li2 = 100000
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4801 template 67
st1 = "a string longer than any field"
li2 = 999999999
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4802 template 67
st1 = " lead"
li2 = -2147483648
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4803 template 67
st1 = "12345678901234567890"
li2 = 2147483647
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4804 template 67
st1 = "x y"
li2 = 9223372036854775807
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4805 template 67
st1 = "A"
li2 = (-9223372036854775807 - 1)
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4806 template 67
st1 = "abc"
li2 = 1000000
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4807 template 67
st1 = "exactly14chars"
li2 = 123456789012
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4808 template 67
st1 = "a string longer than any field"
li2 = -100
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4809 template 67
st1 = " lead"
li2 = 5
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4810 template 67
st1 = "12345678901234567890"
li2 = 10
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4811 template 67
st1 = "x y"
li2 = 0
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4812 template 67
st1 = "A"
li2 = 1
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4813 template 67
st1 = "abc"
li2 = -1
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4814 template 67
st1 = "exactly14chars"
li2 = 42
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4815 template 67
st1 = "a string longer than any field"
li2 = -7
Print #2, "67 2" & " " & "s:" & BHex(st1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(67); st1; li2
' 4816 template 68
st1 = "A"
st2 = " lead"
Print #2, "68 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(68); st1; st2
' 4817 template 68
st1 = "abc"
st2 = "12345678901234567890"
Print #2, "68 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(68); st1; st2
' 4818 template 68
st1 = "exactly14chars"
st2 = "x y"
Print #2, "68 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(68); st1; st2
' 4819 template 68
st1 = "a string longer than any field"
st2 = ""
Print #2, "68 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(68); st1; st2
' 4820 template 68
st1 = " lead"
st2 = "A"
Print #2, "68 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(68); st1; st2
' 4821 template 68
st1 = "12345678901234567890"
st2 = "abc"
Print #2, "68 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(68); st1; st2
' 4822 template 68
st1 = "x y"
st2 = "exactly14chars"
Print #2, "68 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(68); st1; st2
' 4823 template 68
st1 = "A"
st2 = "a string longer than any field"
Print #2, "68 2" & " " & "s:" & BHex(st1) & " " & "s:" & BHex(st2)
Print #1, Using tpl(68); st1; st2
' 4824 template 69
sg1 = 0
sg2 = 0.005!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4825 template 69
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4826 template 69
sg1 = 0.5!
sg2 = 0.15!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4827 template 69
sg1 = -0.5!
sg2 = 0.25!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4828 template 69
sg1 = 0.05!
sg2 = 0.35!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4829 template 69
sg1 = 0.005!
sg2 = 0.45!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4830 template 69
sg1 = 0.0005!
sg2 = 1!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4831 template 69
sg1 = 0.15!
sg2 = -1!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4832 template 69
sg1 = 0.25!
sg2 = 1.5!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4833 template 69
sg1 = 0.35!
sg2 = 2.5!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4834 template 69
sg1 = 0.45!
sg2 = 9.995!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4835 template 69
sg1 = 1!
sg2 = 10!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4836 template 69
sg1 = -1!
sg2 = 99.995!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4837 template 69
sg1 = 1.5!
sg2 = 99.9999!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4838 template 69
sg1 = 2.5!
sg2 = 123.456!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4839 template 69
sg1 = 9.995!
sg2 = -123.456!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4840 template 69
sg1 = 10!
sg2 = 999.95!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4841 template 69
sg1 = 99.995!
sg2 = 1234.5678!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4842 template 69
sg1 = 99.9999!
sg2 = 12345.678!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4843 template 69
sg1 = 123.456!
sg2 = 99999.9!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4844 template 69
sg1 = -123.456!
sg2 = 0.1!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4845 template 69
sg1 = 999.95!
sg2 = 0.00001!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4846 template 69
sg1 = 1234.5678!
sg2 = 0.000000123!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4847 template 69
sg1 = 12345.678!
sg2 = 0.0000000001!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4848 template 69
sg1 = 99999.9!
sg2 = 100000!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4849 template 69
sg1 = 0.1!
sg2 = 10000000000!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4850 template 69
sg1 = 0.00001!
sg2 = 9999999999999999!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4851 template 69
sg1 = 0.000000123!
sg2 = 1E+17!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4852 template 69
sg1 = 0.0000000001!
sg2 = 1E+20!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4853 template 69
sg1 = 100000!
sg2 = 1E+30!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4854 template 69
sg1 = 10000000000!
sg2 = -2.5E-30!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4855 template 69
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4856 template 69
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4857 template 69
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4858 template 69
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4859 template 69
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4860 template 69
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4861 template 69
sg1 = SngBits(&hFFC00000)
sg2 = 0
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4862 template 69
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4863 template 69
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4864 template 69
sg1 = SngBits(&h1)
sg2 = -0.5!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4865 template 69
sg1 = SngBits(&h80000001)
sg2 = 0.05!
Print #2, "69 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(69); sg1; sg2
' 4866 template 69
li1 = 0
li2 = 12345
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4867 template 69
li1 = 1
li2 = 99999
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4868 template 69
li1 = -1
li2 = 100000
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4869 template 69
li1 = 42
li2 = 999999999
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4870 template 69
li1 = -7
li2 = -2147483648
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4871 template 69
li1 = 12345
li2 = 2147483647
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4872 template 69
li1 = 99999
li2 = 9223372036854775807
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4873 template 69
li1 = 100000
li2 = (-9223372036854775807 - 1)
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4874 template 69
li1 = 999999999
li2 = 1000000
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4875 template 69
li1 = -2147483648
li2 = 123456789012
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4876 template 69
li1 = 2147483647
li2 = -100
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4877 template 69
li1 = 9223372036854775807
li2 = 5
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4878 template 69
li1 = (-9223372036854775807 - 1)
li2 = 10
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4879 template 69
li1 = 1000000
li2 = 0
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4880 template 69
li1 = 123456789012
li2 = 1
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4881 template 69
li1 = -100
li2 = -1
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4882 template 69
li1 = 5
li2 = 42
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4883 template 69
li1 = 10
li2 = -7
Print #2, "69 2" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2)
Print #1, Using tpl(69); li1; li2
' 4884 template 70
sg1 = 0
sg2 = 0.005!
sg3 = 0.45!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4885 template 70
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
sg3 = 1!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4886 template 70
sg1 = 0.5!
sg2 = 0.15!
sg3 = -1!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4887 template 70
sg1 = -0.5!
sg2 = 0.25!
sg3 = 1.5!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4888 template 70
sg1 = 0.05!
sg2 = 0.35!
sg3 = 2.5!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4889 template 70
sg1 = 0.005!
sg2 = 0.45!
sg3 = 9.995!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4890 template 70
sg1 = 0.0005!
sg2 = 1!
sg3 = 10!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4891 template 70
sg1 = 0.15!
sg2 = -1!
sg3 = 99.995!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4892 template 70
sg1 = 0.25!
sg2 = 1.5!
sg3 = 99.9999!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4893 template 70
sg1 = 0.35!
sg2 = 2.5!
sg3 = 123.456!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4894 template 70
sg1 = 0.45!
sg2 = 9.995!
sg3 = -123.456!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4895 template 70
sg1 = 1!
sg2 = 10!
sg3 = 999.95!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4896 template 70
sg1 = -1!
sg2 = 99.995!
sg3 = 1234.5678!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4897 template 70
sg1 = 1.5!
sg2 = 99.9999!
sg3 = 12345.678!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4898 template 70
sg1 = 2.5!
sg2 = 123.456!
sg3 = 99999.9!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4899 template 70
sg1 = 9.995!
sg2 = -123.456!
sg3 = 0.1!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4900 template 70
sg1 = 10!
sg2 = 999.95!
sg3 = 0.00001!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4901 template 70
sg1 = 99.995!
sg2 = 1234.5678!
sg3 = 0.000000123!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4902 template 70
sg1 = 99.9999!
sg2 = 12345.678!
sg3 = 0.0000000001!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4903 template 70
sg1 = 123.456!
sg2 = 99999.9!
sg3 = 100000!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4904 template 70
sg1 = -123.456!
sg2 = 0.1!
sg3 = 10000000000!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4905 template 70
sg1 = 999.95!
sg2 = 0.00001!
sg3 = 9999999999999999!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4906 template 70
sg1 = 1234.5678!
sg2 = 0.000000123!
sg3 = 1E+17!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4907 template 70
sg1 = 12345.678!
sg2 = 0.0000000001!
sg3 = 1E+20!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4908 template 70
sg1 = 99999.9!
sg2 = 100000!
sg3 = 1E+30!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4909 template 70
sg1 = 0.1!
sg2 = 10000000000!
sg3 = -2.5E-30!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4910 template 70
sg1 = 0.00001!
sg2 = 9999999999999999!
sg3 = SngBits(&h7FC00000)
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4911 template 70
sg1 = 0.000000123!
sg2 = 1E+17!
sg3 = SngBits(&hFFC00000)
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4912 template 70
sg1 = 0.0000000001!
sg2 = 1E+20!
sg3 = SngBits(&h7F800000)
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4913 template 70
sg1 = 100000!
sg2 = 1E+30!
sg3 = SngBits(&hFF800000)
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4914 template 70
sg1 = 10000000000!
sg2 = -2.5E-30!
sg3 = SngBits(&h1)
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4915 template 70
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
sg3 = SngBits(&h80000001)
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4916 template 70
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
sg3 = 0
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4917 template 70
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
sg3 = SngBits(&h80000000)
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4918 template 70
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
sg3 = 0.5!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4919 template 70
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
sg3 = -0.5!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4920 template 70
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
sg3 = 0.05!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4921 template 70
sg1 = SngBits(&hFFC00000)
sg2 = 0
sg3 = 0.005!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4922 template 70
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
sg3 = 0.0005!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4923 template 70
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
sg3 = 0.15!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4924 template 70
sg1 = SngBits(&h1)
sg2 = -0.5!
sg3 = 0.25!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4925 template 70
sg1 = SngBits(&h80000001)
sg2 = 0.05!
sg3 = 0.35!
Print #2, "70 3" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2) & " " & "f:" & SHex(sg3)
Print #1, Using tpl(70); sg1; sg2; sg3
' 4926 template 70
li1 = 0
li2 = 12345
li3 = 2147483647
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4927 template 70
li1 = 1
li2 = 99999
li3 = 9223372036854775807
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4928 template 70
li1 = -1
li2 = 100000
li3 = (-9223372036854775807 - 1)
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4929 template 70
li1 = 42
li2 = 999999999
li3 = 1000000
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4930 template 70
li1 = -7
li2 = -2147483648
li3 = 123456789012
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4931 template 70
li1 = 12345
li2 = 2147483647
li3 = -100
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4932 template 70
li1 = 99999
li2 = 9223372036854775807
li3 = 5
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4933 template 70
li1 = 100000
li2 = (-9223372036854775807 - 1)
li3 = 10
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4934 template 70
li1 = 999999999
li2 = 1000000
li3 = 0
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4935 template 70
li1 = -2147483648
li2 = 123456789012
li3 = 1
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4936 template 70
li1 = 2147483647
li2 = -100
li3 = -1
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4937 template 70
li1 = 9223372036854775807
li2 = 5
li3 = 42
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4938 template 70
li1 = (-9223372036854775807 - 1)
li2 = 10
li3 = -7
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4939 template 70
li1 = 1000000
li2 = 0
li3 = 12345
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4940 template 70
li1 = 123456789012
li2 = 1
li3 = 99999
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4941 template 70
li1 = -100
li2 = -1
li3 = 100000
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4942 template 70
li1 = 5
li2 = 42
li3 = 999999999
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4943 template 70
li1 = 10
li2 = -7
li3 = -2147483648
Print #2, "70 3" & " " & "l:" & LHex(li1) & " " & "l:" & LHex(li2) & " " & "l:" & LHex(li3)
Print #1, Using tpl(70); li1; li2; li3
' 4944 template 72
sg1 = 0
sg2 = 0.005!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4945 template 72
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4946 template 72
sg1 = 0.5!
sg2 = 0.15!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4947 template 72
sg1 = -0.5!
sg2 = 0.25!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4948 template 72
sg1 = 0.05!
sg2 = 0.35!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4949 template 72
sg1 = 0.005!
sg2 = 0.45!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4950 template 72
sg1 = 0.0005!
sg2 = 1!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4951 template 72
sg1 = 0.15!
sg2 = -1!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4952 template 72
sg1 = 0.25!
sg2 = 1.5!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4953 template 72
sg1 = 0.35!
sg2 = 2.5!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4954 template 72
sg1 = 0.45!
sg2 = 9.995!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4955 template 72
sg1 = 1!
sg2 = 10!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4956 template 72
sg1 = -1!
sg2 = 99.995!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4957 template 72
sg1 = 1.5!
sg2 = 99.9999!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4958 template 72
sg1 = 2.5!
sg2 = 123.456!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4959 template 72
sg1 = 9.995!
sg2 = -123.456!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4960 template 72
sg1 = 10!
sg2 = 999.95!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4961 template 72
sg1 = 99.995!
sg2 = 1234.5678!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4962 template 72
sg1 = 99.9999!
sg2 = 12345.678!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4963 template 72
sg1 = 123.456!
sg2 = 99999.9!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4964 template 72
sg1 = -123.456!
sg2 = 0.1!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4965 template 72
sg1 = 999.95!
sg2 = 0.00001!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4966 template 72
sg1 = 1234.5678!
sg2 = 0.000000123!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4967 template 72
sg1 = 12345.678!
sg2 = 0.0000000001!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4968 template 72
sg1 = 99999.9!
sg2 = 100000!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4969 template 72
sg1 = 0.1!
sg2 = 10000000000!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4970 template 72
sg1 = 0.00001!
sg2 = 9999999999999999!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4971 template 72
sg1 = 0.000000123!
sg2 = 1E+17!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4972 template 72
sg1 = 0.0000000001!
sg2 = 1E+20!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4973 template 72
sg1 = 100000!
sg2 = 1E+30!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4974 template 72
sg1 = 10000000000!
sg2 = -2.5E-30!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4975 template 72
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4976 template 72
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4977 template 72
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4978 template 72
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4979 template 72
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4980 template 72
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4981 template 72
sg1 = SngBits(&hFFC00000)
sg2 = 0
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4982 template 72
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4983 template 72
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4984 template 72
sg1 = SngBits(&h1)
sg2 = -0.5!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4985 template 72
sg1 = SngBits(&h80000001)
sg2 = 0.05!
Print #2, "72 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(72); sg1; sg2
' 4986 template 72
db1 = 0#
db2 = 0.005#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4987 template 72
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4988 template 72
db1 = 0.5#
db2 = 0.15#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4989 template 72
db1 = -0.5#
db2 = 0.25#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4990 template 72
db1 = 0.05#
db2 = 0.35#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4991 template 72
db1 = 0.005#
db2 = 0.45#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4992 template 72
db1 = 0.0005#
db2 = 1#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4993 template 72
db1 = 0.15#
db2 = -1#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4994 template 72
db1 = 0.25#
db2 = 1.5#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4995 template 72
db1 = 0.35#
db2 = 2.5#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4996 template 72
db1 = 0.45#
db2 = 9.995#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4997 template 72
db1 = 1#
db2 = 10#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4998 template 72
db1 = -1#
db2 = 99.995#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 4999 template 72
db1 = 1.5#
db2 = 99.9999#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5000 template 72
db1 = 2.5#
db2 = 123.456#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5001 template 72
db1 = 9.995#
db2 = -123.456#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5002 template 72
db1 = 10#
db2 = 999.95#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5003 template 72
db1 = 99.995#
db2 = 1234.5678#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5004 template 72
db1 = 99.9999#
db2 = 12345.678#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5005 template 72
db1 = 123.456#
db2 = 99999.9#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5006 template 72
db1 = -123.456#
db2 = 0.1#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5007 template 72
db1 = 999.95#
db2 = 0.00001#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5008 template 72
db1 = 1234.5678#
db2 = 0.000000123#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5009 template 72
db1 = 12345.678#
db2 = 0.0000000001#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5010 template 72
db1 = 99999.9#
db2 = 100000#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5011 template 72
db1 = 0.1#
db2 = 10000000000#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5012 template 72
db1 = 0.00001#
db2 = 9999999999999999#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5013 template 72
db1 = 0.000000123#
db2 = 1E+17#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5014 template 72
db1 = 0.0000000001#
db2 = 1E+20#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5015 template 72
db1 = 100000#
db2 = 1E+30#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5016 template 72
db1 = 10000000000#
db2 = -2.5E-30#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5017 template 72
db1 = 9999999999999999#
db2 = 1E+300#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5018 template 72
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5019 template 72
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5020 template 72
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5021 template 72
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5022 template 72
db1 = 1E+300#
db2 = DblBits(&h1ULL)
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5023 template 72
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5024 template 72
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5025 template 72
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5026 template 72
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5027 template 72
db1 = DblBits(&h1ULL)
db2 = -0.5#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5028 template 72
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
Print #2, "72 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(72); db1; db2
' 5029 template 73
sg1 = 0
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5030 template 73
sg1 = SngBits(&h80000000)
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5031 template 73
sg1 = 0.5!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5032 template 73
sg1 = -0.5!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5033 template 73
sg1 = 0.05!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5034 template 73
sg1 = 0.005!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5035 template 73
sg1 = 0.0005!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5036 template 73
sg1 = 0.15!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5037 template 73
sg1 = 0.25!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5038 template 73
sg1 = 0.35!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5039 template 73
sg1 = 0.45!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5040 template 73
sg1 = 1!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5041 template 73
sg1 = -1!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5042 template 73
sg1 = 1.5!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5043 template 73
sg1 = 2.5!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5044 template 73
sg1 = 9.995!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5045 template 73
sg1 = 10!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5046 template 73
sg1 = 99.995!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5047 template 73
sg1 = 99.9999!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5048 template 73
sg1 = 123.456!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5049 template 73
sg1 = -123.456!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5050 template 73
sg1 = 999.95!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5051 template 73
sg1 = 1234.5678!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5052 template 73
sg1 = 12345.678!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5053 template 73
sg1 = 99999.9!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5054 template 73
sg1 = 0.1!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5055 template 73
sg1 = 0.00001!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5056 template 73
sg1 = 0.000000123!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5057 template 73
sg1 = 0.0000000001!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5058 template 73
sg1 = 100000!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5059 template 73
sg1 = 10000000000!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5060 template 73
sg1 = 9999999999999999!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5061 template 73
sg1 = 1E+17!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5062 template 73
sg1 = 1E+20!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5063 template 73
sg1 = 1E+30!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5064 template 73
sg1 = -2.5E-30!
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5065 template 73
sg1 = SngBits(&h7FC00000)
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5066 template 73
sg1 = SngBits(&hFFC00000)
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5067 template 73
sg1 = SngBits(&h7F800000)
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5068 template 73
sg1 = SngBits(&hFF800000)
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5069 template 73
sg1 = SngBits(&h1)
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5070 template 73
sg1 = SngBits(&h80000001)
Print #2, "73 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(73); sg1
' 5071 template 73
li1 = 0
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5072 template 73
li1 = 1
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5073 template 73
li1 = -1
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5074 template 73
li1 = 42
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5075 template 73
li1 = -7
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5076 template 73
li1 = 12345
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5077 template 73
li1 = 99999
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5078 template 73
li1 = 100000
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5079 template 73
li1 = 999999999
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5080 template 73
li1 = -2147483648
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5081 template 73
li1 = 2147483647
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5082 template 73
li1 = 9223372036854775807
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5083 template 73
li1 = (-9223372036854775807 - 1)
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5084 template 73
li1 = 1000000
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5085 template 73
li1 = 123456789012
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5086 template 73
li1 = -100
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5087 template 73
li1 = 5
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5088 template 73
li1 = 10
Print #2, "73 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(73); li1
' 5089 template 74
sg1 = 0
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5090 template 74
sg1 = SngBits(&h80000000)
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5091 template 74
sg1 = 0.5!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5092 template 74
sg1 = -0.5!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5093 template 74
sg1 = 0.05!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5094 template 74
sg1 = 0.005!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5095 template 74
sg1 = 0.0005!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5096 template 74
sg1 = 0.15!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5097 template 74
sg1 = 0.25!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5098 template 74
sg1 = 0.35!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5099 template 74
sg1 = 0.45!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5100 template 74
sg1 = 1!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5101 template 74
sg1 = -1!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5102 template 74
sg1 = 1.5!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5103 template 74
sg1 = 2.5!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5104 template 74
sg1 = 9.995!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5105 template 74
sg1 = 10!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5106 template 74
sg1 = 99.995!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5107 template 74
sg1 = 99.9999!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5108 template 74
sg1 = 123.456!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5109 template 74
sg1 = -123.456!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5110 template 74
sg1 = 999.95!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5111 template 74
sg1 = 1234.5678!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5112 template 74
sg1 = 12345.678!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5113 template 74
sg1 = 99999.9!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5114 template 74
sg1 = 0.1!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5115 template 74
sg1 = 0.00001!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5116 template 74
sg1 = 0.000000123!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5117 template 74
sg1 = 0.0000000001!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5118 template 74
sg1 = 100000!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5119 template 74
sg1 = 10000000000!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5120 template 74
sg1 = 9999999999999999!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5121 template 74
sg1 = 1E+17!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5122 template 74
sg1 = 1E+20!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5123 template 74
sg1 = 1E+30!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5124 template 74
sg1 = -2.5E-30!
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5125 template 74
sg1 = SngBits(&h7FC00000)
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5126 template 74
sg1 = SngBits(&hFFC00000)
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5127 template 74
sg1 = SngBits(&h7F800000)
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5128 template 74
sg1 = SngBits(&hFF800000)
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5129 template 74
sg1 = SngBits(&h1)
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5130 template 74
sg1 = SngBits(&h80000001)
Print #2, "74 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(74); sg1
' 5131 template 74
db1 = 0#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5132 template 74
db1 = DblBits(&h8000000000000000ULL)
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5133 template 74
db1 = 0.5#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5134 template 74
db1 = -0.5#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5135 template 74
db1 = 0.05#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5136 template 74
db1 = 0.005#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5137 template 74
db1 = 0.0005#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5138 template 74
db1 = 0.15#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5139 template 74
db1 = 0.25#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5140 template 74
db1 = 0.35#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5141 template 74
db1 = 0.45#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5142 template 74
db1 = 1#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5143 template 74
db1 = -1#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5144 template 74
db1 = 1.5#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5145 template 74
db1 = 2.5#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5146 template 74
db1 = 9.995#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5147 template 74
db1 = 10#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5148 template 74
db1 = 99.995#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5149 template 74
db1 = 99.9999#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5150 template 74
db1 = 123.456#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5151 template 74
db1 = -123.456#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5152 template 74
db1 = 999.95#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5153 template 74
db1 = 1234.5678#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5154 template 74
db1 = 12345.678#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5155 template 74
db1 = 99999.9#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5156 template 74
db1 = 0.1#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5157 template 74
db1 = 0.00001#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5158 template 74
db1 = 0.000000123#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5159 template 74
db1 = 0.0000000001#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5160 template 74
db1 = 100000#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5161 template 74
db1 = 10000000000#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5162 template 74
db1 = 9999999999999999#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5163 template 74
db1 = 1E+17#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5164 template 74
db1 = 1E+20#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5165 template 74
db1 = 1E+30#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5166 template 74
db1 = -2.5E-30#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5167 template 74
db1 = 1E+300#
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5168 template 74
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5169 template 74
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5170 template 74
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5171 template 74
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5172 template 74
db1 = DblBits(&h1ULL)
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5173 template 74
db1 = DblBits(&h8000000000000001ULL)
Print #2, "74 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(74); db1
' 5174 template 75
sg1 = 0
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5175 template 75
sg1 = SngBits(&h80000000)
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5176 template 75
sg1 = 0.5!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5177 template 75
sg1 = -0.5!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5178 template 75
sg1 = 0.05!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5179 template 75
sg1 = 0.005!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5180 template 75
sg1 = 0.0005!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5181 template 75
sg1 = 0.15!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5182 template 75
sg1 = 0.25!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5183 template 75
sg1 = 0.35!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5184 template 75
sg1 = 0.45!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5185 template 75
sg1 = 1!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5186 template 75
sg1 = -1!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5187 template 75
sg1 = 1.5!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5188 template 75
sg1 = 2.5!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5189 template 75
sg1 = 9.995!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5190 template 75
sg1 = 10!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5191 template 75
sg1 = 99.995!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5192 template 75
sg1 = 99.9999!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5193 template 75
sg1 = 123.456!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5194 template 75
sg1 = -123.456!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5195 template 75
sg1 = 999.95!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5196 template 75
sg1 = 1234.5678!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5197 template 75
sg1 = 12345.678!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5198 template 75
sg1 = 99999.9!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5199 template 75
sg1 = 0.1!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5200 template 75
sg1 = 0.00001!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5201 template 75
sg1 = 0.000000123!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5202 template 75
sg1 = 0.0000000001!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5203 template 75
sg1 = 100000!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5204 template 75
sg1 = 10000000000!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5205 template 75
sg1 = 9999999999999999!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5206 template 75
sg1 = 1E+17!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5207 template 75
sg1 = 1E+20!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5208 template 75
sg1 = 1E+30!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5209 template 75
sg1 = -2.5E-30!
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5210 template 75
sg1 = SngBits(&h7FC00000)
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5211 template 75
sg1 = SngBits(&hFFC00000)
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5212 template 75
sg1 = SngBits(&h7F800000)
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5213 template 75
sg1 = SngBits(&hFF800000)
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5214 template 75
sg1 = SngBits(&h1)
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5215 template 75
sg1 = SngBits(&h80000001)
Print #2, "75 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(75); sg1
' 5216 template 75
db1 = 0#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5217 template 75
db1 = DblBits(&h8000000000000000ULL)
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5218 template 75
db1 = 0.5#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5219 template 75
db1 = -0.5#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5220 template 75
db1 = 0.05#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5221 template 75
db1 = 0.005#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5222 template 75
db1 = 0.0005#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5223 template 75
db1 = 0.15#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5224 template 75
db1 = 0.25#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5225 template 75
db1 = 0.35#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5226 template 75
db1 = 0.45#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5227 template 75
db1 = 1#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5228 template 75
db1 = -1#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5229 template 75
db1 = 1.5#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5230 template 75
db1 = 2.5#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5231 template 75
db1 = 9.995#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5232 template 75
db1 = 10#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5233 template 75
db1 = 99.995#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5234 template 75
db1 = 99.9999#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5235 template 75
db1 = 123.456#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5236 template 75
db1 = -123.456#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5237 template 75
db1 = 999.95#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5238 template 75
db1 = 1234.5678#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5239 template 75
db1 = 12345.678#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5240 template 75
db1 = 99999.9#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5241 template 75
db1 = 0.1#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5242 template 75
db1 = 0.00001#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5243 template 75
db1 = 0.000000123#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5244 template 75
db1 = 0.0000000001#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5245 template 75
db1 = 100000#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5246 template 75
db1 = 10000000000#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5247 template 75
db1 = 9999999999999999#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5248 template 75
db1 = 1E+17#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5249 template 75
db1 = 1E+20#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5250 template 75
db1 = 1E+30#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5251 template 75
db1 = -2.5E-30#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5252 template 75
db1 = 1E+300#
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5253 template 75
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5254 template 75
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5255 template 75
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5256 template 75
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5257 template 75
db1 = DblBits(&h1ULL)
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5258 template 75
db1 = DblBits(&h8000000000000001ULL)
Print #2, "75 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(75); db1
' 5259 template 76
sg1 = 0
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5260 template 76
sg1 = SngBits(&h80000000)
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5261 template 76
sg1 = 0.5!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5262 template 76
sg1 = -0.5!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5263 template 76
sg1 = 0.05!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5264 template 76
sg1 = 0.005!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5265 template 76
sg1 = 0.0005!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5266 template 76
sg1 = 0.15!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5267 template 76
sg1 = 0.25!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5268 template 76
sg1 = 0.35!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5269 template 76
sg1 = 0.45!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5270 template 76
sg1 = 1!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5271 template 76
sg1 = -1!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5272 template 76
sg1 = 1.5!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5273 template 76
sg1 = 2.5!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5274 template 76
sg1 = 9.995!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5275 template 76
sg1 = 10!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5276 template 76
sg1 = 99.995!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5277 template 76
sg1 = 99.9999!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5278 template 76
sg1 = 123.456!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5279 template 76
sg1 = -123.456!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5280 template 76
sg1 = 999.95!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5281 template 76
sg1 = 1234.5678!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5282 template 76
sg1 = 12345.678!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5283 template 76
sg1 = 99999.9!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5284 template 76
sg1 = 0.1!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5285 template 76
sg1 = 0.00001!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5286 template 76
sg1 = 0.000000123!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5287 template 76
sg1 = 0.0000000001!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5288 template 76
sg1 = 100000!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5289 template 76
sg1 = 10000000000!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5290 template 76
sg1 = 9999999999999999!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5291 template 76
sg1 = 1E+17!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5292 template 76
sg1 = 1E+20!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5293 template 76
sg1 = 1E+30!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5294 template 76
sg1 = -2.5E-30!
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5295 template 76
sg1 = SngBits(&h7FC00000)
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5296 template 76
sg1 = SngBits(&hFFC00000)
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5297 template 76
sg1 = SngBits(&h7F800000)
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5298 template 76
sg1 = SngBits(&hFF800000)
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5299 template 76
sg1 = SngBits(&h1)
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5300 template 76
sg1 = SngBits(&h80000001)
Print #2, "76 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(76); sg1
' 5301 template 76
db1 = 0#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5302 template 76
db1 = DblBits(&h8000000000000000ULL)
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5303 template 76
db1 = 0.5#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5304 template 76
db1 = -0.5#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5305 template 76
db1 = 0.05#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5306 template 76
db1 = 0.005#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5307 template 76
db1 = 0.0005#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5308 template 76
db1 = 0.15#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5309 template 76
db1 = 0.25#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5310 template 76
db1 = 0.35#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5311 template 76
db1 = 0.45#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5312 template 76
db1 = 1#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5313 template 76
db1 = -1#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5314 template 76
db1 = 1.5#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5315 template 76
db1 = 2.5#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5316 template 76
db1 = 9.995#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5317 template 76
db1 = 10#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5318 template 76
db1 = 99.995#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5319 template 76
db1 = 99.9999#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5320 template 76
db1 = 123.456#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5321 template 76
db1 = -123.456#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5322 template 76
db1 = 999.95#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5323 template 76
db1 = 1234.5678#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5324 template 76
db1 = 12345.678#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5325 template 76
db1 = 99999.9#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5326 template 76
db1 = 0.1#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5327 template 76
db1 = 0.00001#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5328 template 76
db1 = 0.000000123#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5329 template 76
db1 = 0.0000000001#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5330 template 76
db1 = 100000#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5331 template 76
db1 = 10000000000#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5332 template 76
db1 = 9999999999999999#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5333 template 76
db1 = 1E+17#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5334 template 76
db1 = 1E+20#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5335 template 76
db1 = 1E+30#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5336 template 76
db1 = -2.5E-30#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5337 template 76
db1 = 1E+300#
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5338 template 76
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5339 template 76
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5340 template 76
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5341 template 76
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5342 template 76
db1 = DblBits(&h1ULL)
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5343 template 76
db1 = DblBits(&h8000000000000001ULL)
Print #2, "76 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(76); db1
' 5344 template 77
sg1 = 0
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5345 template 77
sg1 = SngBits(&h80000000)
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5346 template 77
sg1 = 0.5!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5347 template 77
sg1 = -0.5!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5348 template 77
sg1 = 0.05!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5349 template 77
sg1 = 0.005!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5350 template 77
sg1 = 0.0005!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5351 template 77
sg1 = 0.15!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5352 template 77
sg1 = 0.25!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5353 template 77
sg1 = 0.35!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5354 template 77
sg1 = 0.45!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5355 template 77
sg1 = 1!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5356 template 77
sg1 = -1!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5357 template 77
sg1 = 1.5!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5358 template 77
sg1 = 2.5!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5359 template 77
sg1 = 9.995!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5360 template 77
sg1 = 10!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5361 template 77
sg1 = 99.995!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5362 template 77
sg1 = 99.9999!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5363 template 77
sg1 = 123.456!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5364 template 77
sg1 = -123.456!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5365 template 77
sg1 = 999.95!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5366 template 77
sg1 = 1234.5678!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5367 template 77
sg1 = 12345.678!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5368 template 77
sg1 = 99999.9!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5369 template 77
sg1 = 0.1!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5370 template 77
sg1 = 0.00001!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5371 template 77
sg1 = 0.000000123!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5372 template 77
sg1 = 0.0000000001!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5373 template 77
sg1 = 100000!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5374 template 77
sg1 = 10000000000!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5375 template 77
sg1 = 9999999999999999!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5376 template 77
sg1 = 1E+17!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5377 template 77
sg1 = 1E+20!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5378 template 77
sg1 = 1E+30!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5379 template 77
sg1 = -2.5E-30!
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5380 template 77
sg1 = SngBits(&h7FC00000)
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5381 template 77
sg1 = SngBits(&hFFC00000)
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5382 template 77
sg1 = SngBits(&h7F800000)
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5383 template 77
sg1 = SngBits(&hFF800000)
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5384 template 77
sg1 = SngBits(&h1)
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5385 template 77
sg1 = SngBits(&h80000001)
Print #2, "77 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(77); sg1
' 5386 template 77
li1 = 0
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5387 template 77
li1 = 1
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5388 template 77
li1 = -1
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5389 template 77
li1 = 42
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5390 template 77
li1 = -7
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5391 template 77
li1 = 12345
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5392 template 77
li1 = 99999
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5393 template 77
li1 = 100000
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5394 template 77
li1 = 999999999
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5395 template 77
li1 = -2147483648
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5396 template 77
li1 = 2147483647
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5397 template 77
li1 = 9223372036854775807
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5398 template 77
li1 = (-9223372036854775807 - 1)
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5399 template 77
li1 = 1000000
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5400 template 77
li1 = 123456789012
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5401 template 77
li1 = -100
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5402 template 77
li1 = 5
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5403 template 77
li1 = 10
Print #2, "77 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(77); li1
' 5404 template 78
sg1 = 0
sg2 = 0.005!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5405 template 78
sg1 = SngBits(&h80000000)
sg2 = 0.0005!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5406 template 78
sg1 = 0.5!
sg2 = 0.15!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5407 template 78
sg1 = -0.5!
sg2 = 0.25!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5408 template 78
sg1 = 0.05!
sg2 = 0.35!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5409 template 78
sg1 = 0.005!
sg2 = 0.45!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5410 template 78
sg1 = 0.0005!
sg2 = 1!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5411 template 78
sg1 = 0.15!
sg2 = -1!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5412 template 78
sg1 = 0.25!
sg2 = 1.5!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5413 template 78
sg1 = 0.35!
sg2 = 2.5!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5414 template 78
sg1 = 0.45!
sg2 = 9.995!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5415 template 78
sg1 = 1!
sg2 = 10!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5416 template 78
sg1 = -1!
sg2 = 99.995!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5417 template 78
sg1 = 1.5!
sg2 = 99.9999!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5418 template 78
sg1 = 2.5!
sg2 = 123.456!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5419 template 78
sg1 = 9.995!
sg2 = -123.456!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5420 template 78
sg1 = 10!
sg2 = 999.95!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5421 template 78
sg1 = 99.995!
sg2 = 1234.5678!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5422 template 78
sg1 = 99.9999!
sg2 = 12345.678!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5423 template 78
sg1 = 123.456!
sg2 = 99999.9!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5424 template 78
sg1 = -123.456!
sg2 = 0.1!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5425 template 78
sg1 = 999.95!
sg2 = 0.00001!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5426 template 78
sg1 = 1234.5678!
sg2 = 0.000000123!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5427 template 78
sg1 = 12345.678!
sg2 = 0.0000000001!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5428 template 78
sg1 = 99999.9!
sg2 = 100000!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5429 template 78
sg1 = 0.1!
sg2 = 10000000000!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5430 template 78
sg1 = 0.00001!
sg2 = 9999999999999999!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5431 template 78
sg1 = 0.000000123!
sg2 = 1E+17!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5432 template 78
sg1 = 0.0000000001!
sg2 = 1E+20!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5433 template 78
sg1 = 100000!
sg2 = 1E+30!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5434 template 78
sg1 = 10000000000!
sg2 = -2.5E-30!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5435 template 78
sg1 = 9999999999999999!
sg2 = SngBits(&h7FC00000)
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5436 template 78
sg1 = 1E+17!
sg2 = SngBits(&hFFC00000)
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5437 template 78
sg1 = 1E+20!
sg2 = SngBits(&h7F800000)
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5438 template 78
sg1 = 1E+30!
sg2 = SngBits(&hFF800000)
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5439 template 78
sg1 = -2.5E-30!
sg2 = SngBits(&h1)
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5440 template 78
sg1 = SngBits(&h7FC00000)
sg2 = SngBits(&h80000001)
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5441 template 78
sg1 = SngBits(&hFFC00000)
sg2 = 0
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5442 template 78
sg1 = SngBits(&h7F800000)
sg2 = SngBits(&h80000000)
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5443 template 78
sg1 = SngBits(&hFF800000)
sg2 = 0.5!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5444 template 78
sg1 = SngBits(&h1)
sg2 = -0.5!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5445 template 78
sg1 = SngBits(&h80000001)
sg2 = 0.05!
Print #2, "78 2" & " " & "f:" & SHex(sg1) & " " & "f:" & SHex(sg2)
Print #1, Using tpl(78); sg1; sg2
' 5446 template 78
db1 = 0#
db2 = 0.005#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5447 template 78
db1 = DblBits(&h8000000000000000ULL)
db2 = 0.0005#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5448 template 78
db1 = 0.5#
db2 = 0.15#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5449 template 78
db1 = -0.5#
db2 = 0.25#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5450 template 78
db1 = 0.05#
db2 = 0.35#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5451 template 78
db1 = 0.005#
db2 = 0.45#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5452 template 78
db1 = 0.0005#
db2 = 1#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5453 template 78
db1 = 0.15#
db2 = -1#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5454 template 78
db1 = 0.25#
db2 = 1.5#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5455 template 78
db1 = 0.35#
db2 = 2.5#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5456 template 78
db1 = 0.45#
db2 = 9.995#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5457 template 78
db1 = 1#
db2 = 10#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5458 template 78
db1 = -1#
db2 = 99.995#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5459 template 78
db1 = 1.5#
db2 = 99.9999#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5460 template 78
db1 = 2.5#
db2 = 123.456#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5461 template 78
db1 = 9.995#
db2 = -123.456#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5462 template 78
db1 = 10#
db2 = 999.95#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5463 template 78
db1 = 99.995#
db2 = 1234.5678#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5464 template 78
db1 = 99.9999#
db2 = 12345.678#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5465 template 78
db1 = 123.456#
db2 = 99999.9#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5466 template 78
db1 = -123.456#
db2 = 0.1#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5467 template 78
db1 = 999.95#
db2 = 0.00001#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5468 template 78
db1 = 1234.5678#
db2 = 0.000000123#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5469 template 78
db1 = 12345.678#
db2 = 0.0000000001#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5470 template 78
db1 = 99999.9#
db2 = 100000#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5471 template 78
db1 = 0.1#
db2 = 10000000000#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5472 template 78
db1 = 0.00001#
db2 = 9999999999999999#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5473 template 78
db1 = 0.000000123#
db2 = 1E+17#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5474 template 78
db1 = 0.0000000001#
db2 = 1E+20#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5475 template 78
db1 = 100000#
db2 = 1E+30#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5476 template 78
db1 = 10000000000#
db2 = -2.5E-30#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5477 template 78
db1 = 9999999999999999#
db2 = 1E+300#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5478 template 78
db1 = 1E+17#
db2 = DblBits(&h7FF8000000000000ULL)
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5479 template 78
db1 = 1E+20#
db2 = DblBits(&hFFF8000000000000ULL)
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5480 template 78
db1 = 1E+30#
db2 = DblBits(&h7FF0000000000000ULL)
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5481 template 78
db1 = -2.5E-30#
db2 = DblBits(&hFFF0000000000000ULL)
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5482 template 78
db1 = 1E+300#
db2 = DblBits(&h1ULL)
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5483 template 78
db1 = DblBits(&h7FF8000000000000ULL)
db2 = DblBits(&h8000000000000001ULL)
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5484 template 78
db1 = DblBits(&hFFF8000000000000ULL)
db2 = 0#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5485 template 78
db1 = DblBits(&h7FF0000000000000ULL)
db2 = DblBits(&h8000000000000000ULL)
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5486 template 78
db1 = DblBits(&hFFF0000000000000ULL)
db2 = 0.5#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5487 template 78
db1 = DblBits(&h1ULL)
db2 = -0.5#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5488 template 78
db1 = DblBits(&h8000000000000001ULL)
db2 = 0.05#
Print #2, "78 2" & " " & "d:" & DHex(db1) & " " & "d:" & DHex(db2)
Print #1, Using tpl(78); db1; db2
' 5489 template 79
sg1 = 0
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5490 template 79
sg1 = SngBits(&h80000000)
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5491 template 79
sg1 = 0.5!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5492 template 79
sg1 = -0.5!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5493 template 79
sg1 = 0.05!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5494 template 79
sg1 = 0.005!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5495 template 79
sg1 = 0.0005!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5496 template 79
sg1 = 0.15!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5497 template 79
sg1 = 0.25!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5498 template 79
sg1 = 0.35!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5499 template 79
sg1 = 0.45!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5500 template 79
sg1 = 1!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5501 template 79
sg1 = -1!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5502 template 79
sg1 = 1.5!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5503 template 79
sg1 = 2.5!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5504 template 79
sg1 = 9.995!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5505 template 79
sg1 = 10!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5506 template 79
sg1 = 99.995!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5507 template 79
sg1 = 99.9999!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5508 template 79
sg1 = 123.456!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5509 template 79
sg1 = -123.456!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5510 template 79
sg1 = 999.95!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5511 template 79
sg1 = 1234.5678!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5512 template 79
sg1 = 12345.678!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5513 template 79
sg1 = 99999.9!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5514 template 79
sg1 = 0.1!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5515 template 79
sg1 = 0.00001!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5516 template 79
sg1 = 0.000000123!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5517 template 79
sg1 = 0.0000000001!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5518 template 79
sg1 = 100000!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5519 template 79
sg1 = 10000000000!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5520 template 79
sg1 = 9999999999999999!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5521 template 79
sg1 = 1E+17!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5522 template 79
sg1 = 1E+20!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5523 template 79
sg1 = 1E+30!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5524 template 79
sg1 = -2.5E-30!
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5525 template 79
sg1 = SngBits(&h7FC00000)
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5526 template 79
sg1 = SngBits(&hFFC00000)
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5527 template 79
sg1 = SngBits(&h7F800000)
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5528 template 79
sg1 = SngBits(&hFF800000)
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5529 template 79
sg1 = SngBits(&h1)
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5530 template 79
sg1 = SngBits(&h80000001)
Print #2, "79 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(79); sg1
' 5531 template 79
db1 = 0#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5532 template 79
db1 = DblBits(&h8000000000000000ULL)
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5533 template 79
db1 = 0.5#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5534 template 79
db1 = -0.5#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5535 template 79
db1 = 0.05#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5536 template 79
db1 = 0.005#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5537 template 79
db1 = 0.0005#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5538 template 79
db1 = 0.15#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5539 template 79
db1 = 0.25#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5540 template 79
db1 = 0.35#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5541 template 79
db1 = 0.45#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5542 template 79
db1 = 1#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5543 template 79
db1 = -1#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5544 template 79
db1 = 1.5#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5545 template 79
db1 = 2.5#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5546 template 79
db1 = 9.995#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5547 template 79
db1 = 10#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5548 template 79
db1 = 99.995#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5549 template 79
db1 = 99.9999#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5550 template 79
db1 = 123.456#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5551 template 79
db1 = -123.456#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5552 template 79
db1 = 999.95#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5553 template 79
db1 = 1234.5678#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5554 template 79
db1 = 12345.678#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5555 template 79
db1 = 99999.9#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5556 template 79
db1 = 0.1#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5557 template 79
db1 = 0.00001#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5558 template 79
db1 = 0.000000123#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5559 template 79
db1 = 0.0000000001#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5560 template 79
db1 = 100000#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5561 template 79
db1 = 10000000000#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5562 template 79
db1 = 9999999999999999#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5563 template 79
db1 = 1E+17#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5564 template 79
db1 = 1E+20#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5565 template 79
db1 = 1E+30#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5566 template 79
db1 = -2.5E-30#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5567 template 79
db1 = 1E+300#
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5568 template 79
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5569 template 79
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5570 template 79
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5571 template 79
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5572 template 79
db1 = DblBits(&h1ULL)
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5573 template 79
db1 = DblBits(&h8000000000000001ULL)
Print #2, "79 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(79); db1
' 5574 template 80
sg1 = 0
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5575 template 80
sg1 = SngBits(&h80000000)
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5576 template 80
sg1 = 0.5!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5577 template 80
sg1 = -0.5!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5578 template 80
sg1 = 0.05!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5579 template 80
sg1 = 0.005!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5580 template 80
sg1 = 0.0005!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5581 template 80
sg1 = 0.15!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5582 template 80
sg1 = 0.25!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5583 template 80
sg1 = 0.35!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5584 template 80
sg1 = 0.45!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5585 template 80
sg1 = 1!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5586 template 80
sg1 = -1!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5587 template 80
sg1 = 1.5!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5588 template 80
sg1 = 2.5!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5589 template 80
sg1 = 9.995!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5590 template 80
sg1 = 10!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5591 template 80
sg1 = 99.995!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5592 template 80
sg1 = 99.9999!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5593 template 80
sg1 = 123.456!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5594 template 80
sg1 = -123.456!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5595 template 80
sg1 = 999.95!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5596 template 80
sg1 = 1234.5678!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5597 template 80
sg1 = 12345.678!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5598 template 80
sg1 = 99999.9!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5599 template 80
sg1 = 0.1!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5600 template 80
sg1 = 0.00001!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5601 template 80
sg1 = 0.000000123!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5602 template 80
sg1 = 0.0000000001!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5603 template 80
sg1 = 100000!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5604 template 80
sg1 = 10000000000!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5605 template 80
sg1 = 9999999999999999!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5606 template 80
sg1 = 1E+17!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5607 template 80
sg1 = 1E+20!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5608 template 80
sg1 = 1E+30!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5609 template 80
sg1 = -2.5E-30!
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5610 template 80
sg1 = SngBits(&h7FC00000)
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5611 template 80
sg1 = SngBits(&hFFC00000)
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5612 template 80
sg1 = SngBits(&h7F800000)
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5613 template 80
sg1 = SngBits(&hFF800000)
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5614 template 80
sg1 = SngBits(&h1)
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5615 template 80
sg1 = SngBits(&h80000001)
Print #2, "80 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(80); sg1
' 5616 template 80
li1 = 0
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5617 template 80
li1 = 1
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5618 template 80
li1 = -1
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5619 template 80
li1 = 42
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5620 template 80
li1 = -7
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5621 template 80
li1 = 12345
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5622 template 80
li1 = 99999
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5623 template 80
li1 = 100000
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5624 template 80
li1 = 999999999
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5625 template 80
li1 = -2147483648
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5626 template 80
li1 = 2147483647
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5627 template 80
li1 = 9223372036854775807
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5628 template 80
li1 = (-9223372036854775807 - 1)
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5629 template 80
li1 = 1000000
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5630 template 80
li1 = 123456789012
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5631 template 80
li1 = -100
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5632 template 80
li1 = 5
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5633 template 80
li1 = 10
Print #2, "80 1" & " " & "l:" & LHex(li1)
Print #1, Using tpl(80); li1
' 5634 template 81
sg1 = 0
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5635 template 81
sg1 = SngBits(&h80000000)
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5636 template 81
sg1 = 0.5!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5637 template 81
sg1 = -0.5!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5638 template 81
sg1 = 0.05!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5639 template 81
sg1 = 0.005!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5640 template 81
sg1 = 0.0005!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5641 template 81
sg1 = 0.15!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5642 template 81
sg1 = 0.25!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5643 template 81
sg1 = 0.35!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5644 template 81
sg1 = 0.45!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5645 template 81
sg1 = 1!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5646 template 81
sg1 = -1!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5647 template 81
sg1 = 1.5!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5648 template 81
sg1 = 2.5!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5649 template 81
sg1 = 9.995!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5650 template 81
sg1 = 10!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5651 template 81
sg1 = 99.995!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5652 template 81
sg1 = 99.9999!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5653 template 81
sg1 = 123.456!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5654 template 81
sg1 = -123.456!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5655 template 81
sg1 = 999.95!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5656 template 81
sg1 = 1234.5678!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5657 template 81
sg1 = 12345.678!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5658 template 81
sg1 = 99999.9!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5659 template 81
sg1 = 0.1!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5660 template 81
sg1 = 0.00001!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5661 template 81
sg1 = 0.000000123!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5662 template 81
sg1 = 0.0000000001!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5663 template 81
sg1 = 100000!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5664 template 81
sg1 = 10000000000!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5665 template 81
sg1 = 9999999999999999!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5666 template 81
sg1 = 1E+17!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5667 template 81
sg1 = 1E+20!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5668 template 81
sg1 = 1E+30!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5669 template 81
sg1 = -2.5E-30!
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5670 template 81
sg1 = SngBits(&h7FC00000)
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5671 template 81
sg1 = SngBits(&hFFC00000)
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5672 template 81
sg1 = SngBits(&h7F800000)
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5673 template 81
sg1 = SngBits(&hFF800000)
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5674 template 81
sg1 = SngBits(&h1)
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5675 template 81
sg1 = SngBits(&h80000001)
Print #2, "81 1" & " " & "f:" & SHex(sg1)
Print #1, Using tpl(81); sg1
' 5676 template 81
db1 = 0#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5677 template 81
db1 = DblBits(&h8000000000000000ULL)
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5678 template 81
db1 = 0.5#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5679 template 81
db1 = -0.5#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5680 template 81
db1 = 0.05#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5681 template 81
db1 = 0.005#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5682 template 81
db1 = 0.0005#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5683 template 81
db1 = 0.15#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5684 template 81
db1 = 0.25#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5685 template 81
db1 = 0.35#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5686 template 81
db1 = 0.45#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5687 template 81
db1 = 1#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5688 template 81
db1 = -1#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5689 template 81
db1 = 1.5#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5690 template 81
db1 = 2.5#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5691 template 81
db1 = 9.995#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5692 template 81
db1 = 10#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5693 template 81
db1 = 99.995#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5694 template 81
db1 = 99.9999#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5695 template 81
db1 = 123.456#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5696 template 81
db1 = -123.456#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5697 template 81
db1 = 999.95#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5698 template 81
db1 = 1234.5678#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5699 template 81
db1 = 12345.678#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5700 template 81
db1 = 99999.9#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5701 template 81
db1 = 0.1#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5702 template 81
db1 = 0.00001#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5703 template 81
db1 = 0.000000123#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5704 template 81
db1 = 0.0000000001#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5705 template 81
db1 = 100000#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5706 template 81
db1 = 10000000000#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5707 template 81
db1 = 9999999999999999#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5708 template 81
db1 = 1E+17#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5709 template 81
db1 = 1E+20#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5710 template 81
db1 = 1E+30#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5711 template 81
db1 = -2.5E-30#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5712 template 81
db1 = 1E+300#
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5713 template 81
db1 = DblBits(&h7FF8000000000000ULL)
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5714 template 81
db1 = DblBits(&hFFF8000000000000ULL)
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5715 template 81
db1 = DblBits(&h7FF0000000000000ULL)
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5716 template 81
db1 = DblBits(&hFFF0000000000000ULL)
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5717 template 81
db1 = DblBits(&h1ULL)
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
' 5718 template 81
db1 = DblBits(&h8000000000000001ULL)
Print #2, "81 1" & " " & "d:" & DHex(db1)
Print #1, Using tpl(81); db1
Close #1
Close #2
End

Data "####.### ", "####.## ", "& ### & ###", "#########", "#### ", "####    ###.######"
Data " #########", "###.# ", "#####.## ", "### ", "###.#### ", "###.###"
Data "#### ###.###", "####.#    ############", "########", "########   ###########", "#####  #######  ###.##", "### ## ##.## ########"
Data " ####         ###.####     ###.####        ###.####", "###.#", "####.#", "####.#    ############      ############", "####.#      ##########      ##########", "########   ###########   ###########"
Data "####  ###     ###.######         ###.######", "####  ###     ###.######         ###.######   &###.######  &###.######", "####    ###.#####", "####    ###.#####   &###.#####   &###.#####", "####    ####    ###.#####", "####        ####         ###.#####        ###.#####"
Data "####         ###.#####              ###.#####", "####          ###.######       ###.######", "####          ###.######       ###.######   &###.#####   &###.##### ", " ##.###        ##############", "  ############.######    ############.######   ##################", "    #.#####"
Data "    ##########", "     ##########    ########## ########.######", "     ##########    ##########      Overflow", "###", "+###.##", "-###.##"
Data "###.##-", "+###.##-", "##.##^^^^", "#.###^^^^^", "+##.##^^^^^", "##.##^^"
Data "$$###.##", "**###.##", "**$###.##", "$$###,###.##", "#,###,###,###", ".##"
Data ".#", "##", "#", "#.", "_#_&###", "!"
Data "&", "&&", "\  \", "\\", "\ \", "\ \!&"
Data "x#y&z!", "\ \ ###", "a\  \b&", "###  ###", "# # #", "text only"
Data "##.## ##.##", "ab#cd", "###.##+", "+.##", "+$$#.##", "#,##0.00"
Data "##,##0.0##^^^^", "##########.##########", "%##", "###^^^^"
