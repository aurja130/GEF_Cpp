' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' M6.0: does console `Print` (no file number, stdout redirected to a file as in a harness run)
' write the same bytes as `Print #` to a sequential file, which fb::PrintFile reproduces (M3)?
' The same statements go to the console and to console_file.txt; lines longer than 80 columns
' and print zones beyond column 80 are included, because a console device could wrap there.
' Then `Sleep` without arguments (GEF's "Press ENTER" stops) is called with stdin at EOF; the
' line after it shows that it returned.
' Usage: m6_console (no arguments). Compare stdout.txt (minus its last line) with
' console_file.txt.

Dim As Single s1 = 1.5, s2 = -2.25, s3 = 0, s4 = 2.53e-08, s5 = 4.920654
Dim As Double d1 = 0.1, d2 = -1e300, d3 = 1e5
Dim As Integer i1 = 86, i2 = -7, i3 = 215
Dim As String t1 = "abc", t2 = "", t3 = "exactly14chars"
Dim As String tl = String(95, "x")
Dim As String tll = String(170, "y")

Open "console_file.txt" For Output As #1

Print t1
Print #1, t1
Print "Fission barrier of CN (Z =";i1;", A =";i3;"):"
Print #1, "Fission barrier of CN (Z =";i1;", A =";i3;"):"
Print "CN: Z =";i1;", A =";i3;
Print #1, "CN: Z =";i1;", A =";i3;
Print ", E = ";s4;" MeV";
Print #1, ", E = ";s4;" MeV";
Print " "
Print #1, " "
Print s1; s2; s3; s4; s5
Print #1, s1; s2; s3; s4; s5
Print d1; d2; d3
Print #1, d1; d2; d3
Print i1; i2; i3
Print #1, i1; i2; i3
Print "Z, A, #iso ", i1, i3, i2; "."
Print #1, "Z, A, #iso ", i1, i3, i2; "."
Print s1, s2, d1, i1, t1
Print #1, s1, s2, d1, i1, t1
Print t3, t1
Print #1, t3, t1
Print tl
Print #1, tl
Print tll
Print #1, tll
Print tl; i1; s4
Print #1, tl; i1; s4
Print tl, t1, t1, t1, t1
Print #1, tl, t1, t1, t1, t1
Print t3, t3, t3, t3, t3, t3, t3, t1
Print #1, t3, t3, t3, t3, t3, t3, t3, t1
Print t1,
Print #1, t1,
Print i2
Print #1, i2
Print
Print #1,
Print "Possible options are: local, global, err, dparfac(..), ptb, cov, cor, lmd, neo, ENDF, random."
Print #1, "Possible options are: local, global, err, dparfac(..), ptb, cov, cor, lmd, neo, ENDF, random."
Print t2
Print #1, t2
Close #1

Sleep
Print "after Sleep"
