' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Golden Rnd stream of the fbc 1.10.1 runtime generator (Randomize seed, 3 = MT19937).
'
' Usage: rnd_stream [seed [count]]       (defaults: 42 and 1000000)
' Writes rnd_stream_<seed>.txt in the working directory: <count> lines, each the u32
' behind one Rnd value as 8 lowercase hex digits. Rnd returns u32 / 2^32 as a Double,
' so CULng(r * 4294967296#) recovers the u32 exactly (both operations are exact).

Dim As Double Seed = 42
Dim As Long Count = 1000000
If Len(Command(1)) > 0 Then Seed = Val(Command(1))
If Len(Command(2)) > 0 Then Count = CLng(Val(Command(2)))

Dim As String OutName = "rnd_stream_" & Trim(Str(CULng(Seed))) & ".txt"
Dim As Long F = FreeFile
If Open(OutName For Output As #F) <> 0 Then
  Print "rnd_stream: cannot open " & OutName
  End 1
End If

Randomize Seed, 3
Dim As Double R
For I As Long = 1 To Count
  R = Rnd
  Print #F, LCase(Hex(CULng(R * 4294967296#), 8))
Next I
Close #F
