' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Print # formatting check (M3.6a golden). One sequential file gets a fixed sequence of
' Print # statements covering strings, Single, Double and LongInt items, the separators `;`
' and `,`, the empty statement, Tab() and embedded line feeds.
' Usage: print_file (no arguments).
' Writes print_file.txt in the working directory (raw bytes, as libfb writes them).

Dim As Single s1 = 1.5, s2 = -2.25, s3 = 0, s4 = 3.4028235e38, s5 = 1e-8
Dim As Double d1 = 0.1, d2 = -1e300, d3 = 2.5
Dim As LongInt i1 = 42, i2 = -7, i3 = 0
Dim As String t1 = "abc", t2 = "", t3 = "exactly14chars", t4 = "line1" & Chr(10) & "xy"

Open "print_file.txt" For Output As #1
Print #1, t1
Print #1, t1; t2; t1
Print #1, s1; s2; s3; s4; s5
Print #1, d1; d2; d3
Print #1, i1; i2; i3
Print #1, s1, s2, d1, i1, t1
Print #1, t3, t1
Print #1, t3; t3, t1
Print #1, t1,
Print #1, i2
Print #1, t1;
Print #1, s1,
Print #1,
Print #1, Tab(10); t1; Tab(5); t1; Tab(20); i1
Print #1, t4; Tab(5); "z", t1
Print #1, Tab(60); d3
Print #1, ""
Print #1, t2
Print #1, s1; Tab(3); s2
Close #1
