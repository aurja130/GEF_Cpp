' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
' Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.
'
' M5 physics driver, group "e2_cascade" (MILESTONE_5_PLAN.md D6): the E2 rotational cascade of
' the light fragment (GEF.bas:9309-9368) and of the heavy fragment (GEF.bas:9430-9484), each cut
' verbatim into a Sub. The variables the copies use are Dim Shared with GEF's types (GEF.bas:842-
' 845, 876, 1342-1344, 1750-1751, 8063-8067, 8700-8703, 8105, 9241-9251); Isotab comes from
' NucPropJEFF33.bas (JEFF-3.3, as GEF.bas:1052). The histogram fills Acc_EGamma* (Spectra.bas,
' M10) are empty Subs with Spectra.bas's signatures. Conventions: harness/drivers/M5_DRIVERS.md.
'
' Usage:
'   m5_e2_cascade                 grids: e2_light_grid.txt, e2_heavy_grid.txt, e2_light_random.txt,
'                                 e2_heavy_random.txt
'   m5_e2_cascade replay <dir>    replay/e2_light.txt and replay/e2_heavy.txt (arglog sites)
'
' Grid schema (S_GRID_*): the inputs, then the live outputs. The scope locals J, K, RJeff, Eg and
' Nspectrum are not written: each is written before it is read on every path through
' GEF.bas:9240-9486 (the heavy prologue overwrites Nspectrum at 9390, J and K are set by their
' For statements, RJeff and Eg in the J loop before use), and the Scope ends at 9486, so their
' values at the end of a copy are never used. Counters start at 0 for every grid call.
'
' Structured grid, the same inputs for both copies; NG = nuclides: every ground state I_MAT
' (NucTab(I_MAT).I_ISO = 0, I_MAT <= UBound(NucTab) - 6, Z <= 136, A - Z <= 236) in I_MAT order,
' Spin_gs = NucTab(I_MAT).R_SPI:
'   A  with isomers (N_ISO_MAT > 0): Jfrag = 0 .. 40 step 0.5 x off in {0, 0.5},
'      J_frag = Jfrag + Spin_gs + off
'   B  without isomers, every 10th of them: Jfrag = 0 .. 80 step 2, J_frag = Jfrag + Spin_gs
'   C  synthetic Isotab: the first nuclide of A with Z >= 30 (its Isotab entry I_iso) gets the
'      states of pattern P = 0..4 (SynthSet), then Jfrag = -1 .. 30 step 0.5 x off in {0, 0.3,
'      0.5, 1} x Spin_gs in {0, 0.5, 1.5}, J_frag = Jfrag + off. The entry is restored afterwards.
' Random, 100,000 calls per copy: Randomize 7001 (light) / 7002 (heavy), 3; per call, in order:
'   idx = Int(M5_Draw(0, count of A)) selects a nuclide of A, Jfrag = Int(M5_Draw(-4, 24)),
'   off = M5_Draw(-1, 4); J_frag = Jfrag + off, Spin_gs = NucTab(I_MAT).R_SPI.

' GEF.bas:595-599
Declare Function U_Ired(Z As Single,A As Single) As Single
Declare Function U_IredFF(Z As Single,A As Single) As Single
Declare Function U_I_Shell(Z As Single, A As Single) As Single

'@include-source utilities.bi
'@include-source DEFO.bas
'@include-source NucPropJEFF33.bas
'@include-source NucProp_Functions.mac
'@cut GEF.bas:17094-17170 as gef_rotation.bi
'@cut GEF.bas:9309-9368 as e2_light.bi
'@cut GEF.bas:9430-9484 as e2_heavy.bi
'@include-driver m5_common.bi

#include once "file.bi"  ' GEF.bas:436 (FileExists, used by NucProp_Functions.mac)
#include "utilities.bi"
' GEF.bas:760
Const As Single pi = 3.14159
' NucPropJEFF33.bas counts its entries with Read before any Restore, so its DATA must be the
' program's first, as in GEF (included at GEF.bas:1052, DEFO.bas at 1563).
#include "NucPropJEFF33.bas"
' GEF.bas:1244: DEFOtab(N, Z), filled by DEFO.bas.
ReDim Shared DEFOtab(0 To 236,0 To 136) As Single
#include "DEFO.bas"
#include "gef_rotation.bi"
#include "m5_common.bi"

' Spectra.bas:1496, 1513, 1579, 1607, 1635 (the fills belong to M10).
ReDim Shared _EGamma(1000) As Double
Sub Acc_EGamma(I_EkeV As Integer, Value As Double)
End Sub
Sub Acc_EGammaL(I_EkeV As Integer, Value As Double)
End Sub
Sub Acc_EGammaH(I_EkeV As Integer, Value As Double)
End Sub
Sub Acc_EGammaE2(I_EkeV As Integer, Value As Double)
End Sub

' GEF's shared variables (Dim Shared in GEF.bas), with GEF's types.
Dim Shared As Integer Ngtot = 0, Nglight = 0, Ngheavy = 0  ' GEF.bas:842-844
Dim Shared As Single Egtot1000 = 0                          ' GEF.bas:845
Dim Shared As Single rbeta, beta1, beta2                    ' GEF.bas:787
ReDim Shared As Single Array_Eg2_light(100)                 ' GEF.bas:1342
ReDim Shared As Single Array_Eg2_heavy(100)                 ' GEF.bas:1343

' One copy per Sub. GEF's non-shared variables the copy uses are parameters (ByVal, the ones the
' copy reads first) or locals of the Sub, with GEF's types: module level I_DelGam (GEF.bas:876,
' = 0), Ig2_* (1344), Spin_gs_* (1750-1751); the scope of the event (8063-8067, 8105-8106,
' 8700-8703); the Scope GEF.bas:9240-9486 (9241-9251). Outs receives the live outputs, a NUL, then the counters.
Sub E2Light(ByVal I_Z_light_sci As Integer, ByVal I_A_light_post As Integer, _
            ByVal I_MAT As Integer, ByVal Jfrag As Single, ByVal J_frag_light As Single, _
            ByVal Spin_gs_light As Single, ByVal I_iso As Integer, ByRef Outs As String)
  Dim As Integer I_DelGam = 0
  Dim As Integer Ig2_light
  Dim As Single IfragEff_light
  Dim As String C_iso_lmd_light
  Dim As Single Eg, RJeff, alph, J, K
  Dim As Integer Nspectrum, N_iso
#include "e2_light.bi"
  Outs = M5_F32(E_E2_tot) & " " & M5_F32(IfragEff_light) & " " & M5_F32(beta1) & " " & _
         M5_F32(alph) & " " & M5_I64(N_iso) & " " & M5_I64(I_iso) & " " & _
         M5_Str(C_iso_lmd_light) & Chr(0) & M5_I64(Nglight) & " " & M5_I64(Ngtot) & " " & _
         M5_F32(Egtot1000) & " " & M5_I64(Ig2_light) & " " & _
         M5_F32List(Array_Eg2_light(), 1, Ig2_light)
End Sub

Sub E2Heavy(ByVal I_Z_heavy_sci As Integer, ByVal I_A_heavy_post As Integer, _
            ByVal I_MAT As Integer, ByVal Jfrag As Single, ByVal J_frag_heavy As Single, _
            ByVal Spin_gs_heavy As Single, ByVal I_iso As Integer, ByRef Outs As String)
  Dim As Integer I_DelGam = 0
  Dim As Integer Ig2_heavy
  Dim As Single IfragEff_heavy
  Dim As String C_iso_lmd_heavy
  Dim As Single Eg, RJeff, alph, J, K
  Dim As Integer Nspectrum, N_iso
  Dim As Single E_E2_tot  ' GEF.bas:9310: declared in the light copy's part of the Scope
#include "e2_heavy.bi"
  Outs = M5_F32(E_E2_tot) & " " & M5_F32(IfragEff_heavy) & " " & M5_F32(beta1) & " " & _
         M5_F32(alph) & " " & M5_I64(N_iso) & " " & M5_I64(I_iso) & " " & _
         M5_Str(C_iso_lmd_heavy) & Chr(0) & M5_I64(Ngheavy) & " " & M5_I64(Ngtot) & " " & _
         M5_F32(Egtot1000) & " " & M5_I64(Ig2_heavy) & " " & _
         M5_F32List(Array_Eg2_heavy(), 1, Ig2_heavy)
End Sub

' Runs one copy; Lives and Counts receive the live outputs before and after the dead locals.
Sub RunCopy(ByVal Heavy As Long, ByVal Iz As Integer, ByVal Ia As Integer, ByVal Imat As Integer, _
            ByVal Jf As Single, ByVal Jfr As Single, ByVal Sg As Single, ByVal Iiso As Integer, _
            ByRef Lives As String, ByRef Counts As String)
  Dim As String Outs
  If Heavy = 0 Then
    E2Light(Iz, Ia, Imat, Jf, Jfr, Sg, Iiso, Outs)
  Else
    E2Heavy(Iz, Ia, Imat, Jf, Jfr, Sg, Iiso, Outs)
  End If
  Dim As Long P = InStr(Outs, Chr(0))
  Lives = Left(Outs, P - 1)
  Counts = Mid(Outs, P + 1)
End Sub

Const S_GRID_LIGHT = "in.I_Z_light_sci:i64 in.I_A_light_post:i64 in.I_MAT:i64 in.Jfrag:f32 in.J_frag_light:f32 in.Spin_gs_light:f32 out.E_E2_tot:f32 out.IfragEff_light:f32 out.beta1:f32 out.alph:f32 out.N_iso:i64 out.I_iso:i64 out.C_iso_lmd_light:str out.Nglight:i64 out.Ngtot:i64 out.Egtot1000:f32 out.Ig2_light:i64 out.Array_Eg2_light(1..Ig2_light):f32[]"
Const S_GRID_HEAVY = "in.I_Z_heavy_sci:i64 in.I_A_heavy_post:i64 in.I_MAT:i64 in.Jfrag:f32 in.J_frag_heavy:f32 in.Spin_gs_heavy:f32 out.E_E2_tot:f32 out.IfragEff_heavy:f32 out.beta1:f32 out.alph:f32 out.N_iso:i64 out.I_iso:i64 out.C_iso_lmd_heavy:str out.Ngheavy:i64 out.Ngtot:i64 out.Egtot1000:f32 out.Ig2_heavy:i64 out.Array_Eg2_heavy(1..Ig2_heavy):f32[]"
Const S_LIGHT = "in.I_Z_light_sci:i64 in.I_A_light_post:i64 in.I_MAT:i64 in.I_DelGam:i64 in.Jfrag:f32 in.J_frag_light:f32 in.Spin_gs_light:f32 in.N_iso:i64 in.I_iso:i64 in.Nglight:i64 in.Ngtot:i64 in.Egtot1000:f32 in.Ig2_light:i64 out.E_E2_tot:f32 out.IfragEff_light:f32 out.beta1:f32 out.alph:f32 out.N_iso:i64 out.I_iso:i64 out.C_iso_lmd_light:str out.J:f32 out.K:f32 out.RJeff:f32 out.Eg:f32 out.Nspectrum:i64 out.Nglight:i64 out.Ngtot:i64 out.Egtot1000:f32 out.Ig2_light:i64 out.Array_Eg2_light(1..Ig2_light):f32[]"
Const S_HEAVY = "in.I_Z_heavy_sci:i64 in.I_A_heavy_post:i64 in.I_MAT:i64 in.I_DelGam:i64 in.Jfrag:f32 in.J_frag_heavy:f32 in.Spin_gs_heavy:f32 in.N_iso:i64 in.I_iso:i64 in.Ngheavy:i64 in.Ngtot:i64 in.Egtot1000:f32 in.Ig2_heavy:i64 in.E_E2_tot:f32 out.E_E2_tot:f32 out.IfragEff_heavy:f32 out.beta1:f32 out.alph:f32 out.N_iso:i64 out.I_iso:i64 out.C_iso_lmd_heavy:str out.J:f32 out.K:f32 out.RJeff:f32 out.Eg:f32 out.Nspectrum:i64 out.Ngheavy:i64 out.Ngtot:i64 out.Egtot1000:f32 out.Ig2_heavy:i64 out.Array_Eg2_heavy(1..Ig2_heavy):f32[]"

Const N_RANDOM = 100000

' One grid call: counters and I_iso start at 0.
Function GridLine(ByVal Heavy As Long, ByVal Iz As Integer, ByVal Ia As Integer, _
                  ByVal Imat As Integer, ByVal Jf As Single, ByVal Jfr As Single, _
                  ByVal Sg As Single) As String
  Dim As String Lives, Counts
  Ngtot = 0
  Nglight = 0
  Ngheavy = 0
  Egtot1000 = 0
  RunCopy(Heavy, Iz, Ia, Imat, Jf, Jfr, Sg, 0, Lives, Counts)
  Return M5_I64(Iz) & " " & M5_I64(Ia) & " " & M5_I64(Imat) & " " & M5_F32(Jf) & " " & _
         M5_F32(Jfr) & " " & M5_F32(Sg) & " " & Lives & " " & Counts
End Function

' The synthetic states of pattern P for Isotab entry Ii (grid C).
Sub SynthSet(ByVal Ii As Integer, ByVal P As Long)
  Dim As Single Spi(1 To 10), Exc(1 To 10)
  Dim As Integer Ns
  Select Case P
    Case 0
      Ns = 2 : Spi(1) = 0 : Spi(2) = 4 : Exc(1) = 0 : Exc(2) = 0.5
    Case 1
      Ns = 3 : Spi(1) = 1.5 : Spi(2) = 5.5 : Spi(3) = 10.5
      Exc(1) = 0 : Exc(2) = 0.1 : Exc(3) = 1.25
    Case 2
      Ns = 10
      For I As Integer = 1 To 10
        Spi(I) = 2 * (I - 1)
        Exc(I) = 0.1 * (I - 1)
      Next
    Case 3
      Ns = 1 : Spi(1) = 6 : Exc(1) = 0
    Case Else
      Ns = 4 : Spi(1) = 2 : Spi(2) = 2 : Spi(3) = 7 : Spi(4) = 7.5
      Exc(1) = 0 : Exc(2) = 0.2 : Exc(3) = 0.3 : Exc(4) = 2.5
  End Select
  Isotab(Ii).N_STATES = Ns
  For I As Integer = 1 To 10
    Isotab(Ii).R_SPI(I) = Spi(I)
    Isotab(Ii).R_EXC(I) = Exc(I)
  Next
End Sub

Sub Grids()
  ' The nuclides: ground states inside DEFOtab, with (A) and without (B) isomers.
  Dim As Integer IsoList(1 To 4000), PlainList(1 To 4000)
  Dim As Integer NIso = 0, NPlain = 0
  For M As Integer = 1 To UBound(NucTab) - 6
    If NucTab(M).I_ISO = 0 And NucTab(M).I_Z >= 1 And NucTab(M).I_Z <= 136 And _
       NucTab(M).I_A - NucTab(M).I_Z >= 0 And NucTab(M).I_A - NucTab(M).I_Z <= 236 Then
      If N_ISO_MAT(M) > 0 Then
        NIso += 1
        IsoList(NIso) = M
      Else
        NPlain += 1
        PlainList(NPlain) = M
      End If
    End If
  Next
  Dim As Integer SynthMat = 0
  For L As Integer = 1 To NIso
    If NucTab(IsoList(L)).I_Z >= 30 Then
      SynthMat = IsoList(L)
      Exit For
    End If
  Next
  Dim As Single Offs(0 To 3) = {0, 0.3, 0.5, 1}
  Dim As Single Sgs(0 To 2) = {0, 0.5, 1.5}

  For Heavy As Long = 0 To 1
    Dim As Long F
    If Heavy = 0 Then
      F = M5_OpenGrid("e2_light_grid.txt", "e2_light", S_GRID_LIGHT)
    Else
      F = M5_OpenGrid("e2_heavy_grid.txt", "e2_heavy", S_GRID_HEAVY)
    End If
    ' A
    For L As Integer = 1 To NIso
      Dim As Integer M = IsoList(L)
      Dim As Single Sg = NucTab(M).R_SPI
      For I As Integer = 0 To 80
        For O As Integer = 0 To 1
          Dim As Single Jf = M5_Axis(0, 0.5, I)
          Print #F, GridLine(Heavy, NucTab(M).I_Z, NucTab(M).I_A, M, Jf, Jf + Sg + Offs(2 * O), Sg)
        Next
      Next
    Next
    ' B
    For L As Integer = 1 To NPlain Step 10
      Dim As Integer M = PlainList(L)
      Dim As Single Sg = NucTab(M).R_SPI
      For I As Integer = 0 To 40
        Dim As Single Jf = M5_Axis(0, 2, I)
        Print #F, GridLine(Heavy, NucTab(M).I_Z, NucTab(M).I_A, M, Jf, Jf + Sg, Sg)
      Next
    Next
    ' C
    Dim As Integer Ii = ISO_for_MAT(SynthMat)
    Dim As Isoprop Saved = Isotab(Ii)
    For P As Long = 0 To 4
      SynthSet(Ii, P)
      For I As Integer = 0 To 62
        For O As Integer = 0 To 3
          For S As Integer = 0 To 2
            Dim As Single Jf = M5_Axis(-1, 0.5, I)
            Print #F, GridLine(Heavy, NucTab(SynthMat).I_Z, NucTab(SynthMat).I_A, SynthMat, _
                               Jf, Jf + Offs(O), Sgs(S))
          Next
        Next
      Next
    Next
    Isotab(Ii) = Saved
    Close #F

    Randomize 7001 + Heavy, 3
    If Heavy = 0 Then
      F = M5_OpenGrid("e2_light_random.txt", "e2_light", S_GRID_LIGHT)
    Else
      F = M5_OpenGrid("e2_heavy_random.txt", "e2_heavy", S_GRID_HEAVY)
    End If
    For R As Long = 1 To N_RANDOM
      Dim As Integer Idx = Int(M5_Draw(0, NIso))
      Dim As Single Jf = Int(M5_Draw(-4, 24))
      Dim As Single Off = M5_Draw(-1, 4)
      Dim As Integer M = IsoList(Idx + 1)
      Print #F, GridLine(Heavy, NucTab(M).I_Z, NucTab(M).I_A, M, Jf, Jf + Off, NucTab(M).R_SPI)
    Next
    Close #F
  Next
End Sub

' Replay: the in.* tokens set GEF's variables as they were at the site's entry; out.* are
' recomputed except the dead scope locals J, K, RJeff, Eg, Nspectrum (see the header), whose
' logged tokens are echoed.
Sub Replay(ByRef Cdir As String)
  Dim As M5_Replay R
  Dim As String T()
  For Heavy As Long = 0 To 1
    Dim As String Cfn = IIf(Heavy = 0, "e2_light", "e2_heavy")
    Dim As String Csch = IIf(Heavy = 0, S_LIGHT, S_HEAVY)
    Dim As Long O = IIf(Heavy = 0, 13, 14)  ' index of the first out.* token
    If M5_ReplayOpen(R, Cdir, Cfn, Csch) Then
      While M5_ReplayNext(R, T())
        Dim As String Cin = T(0)
        For I As Long = 1 To O - 1
          Cin &= " " & T(I)
        Next
        Ngtot = M5_ParseI64(T(10))
        Egtot1000 = M5_ParseF32(T(11))
        If Heavy = 0 Then Nglight = M5_ParseI64(T(9)) Else Ngheavy = M5_ParseI64(T(9))
        Dim As String Lives, Counts
        RunCopy(Heavy, M5_ParseI64(T(0)), M5_ParseI64(T(1)), M5_ParseI64(T(2)), _
                M5_ParseF32(T(4)), M5_ParseF32(T(5)), M5_ParseF32(T(6)), M5_ParseI64(T(8)), _
                Lives, Counts)
        Dim As String Cdead = T(O + 7) & " " & T(O + 8) & " " & T(O + 9) & " " & T(O + 10) & _
                              " " & T(O + 11)
        M5_ReplayWrite(R, Cin & " " & Lives & " " & Cdead & " " & Counts)
      Wend
      M5_ReplayClose(R)
    End If
  Next
End Sub

If Command(1) = "replay" Then
  Replay(Command(2))
ElseIf Command(1) = "" Then
  Grids()
Else
  Print "usage: m5_e2_cascade [replay <arglog dir>]"
  End 2
End If
