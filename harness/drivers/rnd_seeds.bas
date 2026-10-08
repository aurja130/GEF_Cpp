' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Rnd streams of the fbc 1.10.1 runtime generator for several seeds (M3 golden).
'
' Usage: rnd_seeds <count> <seed> [<seed> ...]
' Each seed is read with Val, i.e. as a Double, and passed to Randomize seed, 3; the words
' nan, inf and -inf stand for those Double values.
' Writes in the working directory:
'   startup.txt  three Rnd values drawn before any Randomize, as Double bit patterns
'   args.txt     after Randomize <first seed>, 3: Rnd(1), Rnd(0), Rnd(-1), Rnd(0.5), Rnd(0),
'                Rnd, as "<argument> <Double bit pattern>" lines
'   seeds.txt    one line per seed: "<index> <seed Double bit pattern> <seed text>"
'   seed_<index>.txt   <count> lines: the u32 behind each Rnd as 8 lowercase hex digits
' Rnd returns u32 / 2^32 as a Double, so CULng(r * 4294967296#) recovers the u32 exactly.

Function Bits(ByVal D As Double) As String
  Return LCase(Hex(*Cast(ULongInt Ptr, @D), 16))
End Function

Dim As Long Count = CLng(Val(Command(1)))
Const F = 1, G = 2

Open "startup.txt" For Output As #F
For I As Long = 1 To 3
  Print #F, Bits(Rnd)
Next I
Close #F

Dim As Double Seed, Zero = 0
Open "seeds.txt" For Output As #G
Dim As Long Index = 0
Do While Len(Command(Index + 2)) > 0
  Select Case Command(Index + 2)
  Case "nan": Seed = Zero / Zero
  Case "inf": Seed = 1 / Zero
  Case "-inf": Seed = -1 / Zero
  Case Else: Seed = Val(Command(Index + 2))
  End Select
  Print #G, Index & " " & Bits(Seed) & " " & Command(Index + 2)
  If Index = 0 Then
    Randomize Seed, 3
    Open "args.txt" For Output As #F
    Print #F, "1 " & Bits(Rnd(1))
    Print #F, "0 " & Bits(Rnd(0))
    Print #F, "-1 " & Bits(Rnd(-1))
    Print #F, "0.5 " & Bits(Rnd(0.5))
    Print #F, "0 " & Bits(Rnd(0))
    Print #F, "default " & Bits(Rnd)
    Close #F
  End If
  Randomize Seed, 3
  Open "seed_" & Index & ".txt" For Output As #F
  For I As Long = 1 To Count
    Print #F, LCase(Hex(CULng(Rnd * 4294967296#), 8))
  Next I
  Close #F
  Index += 1
Loop
Close #G
