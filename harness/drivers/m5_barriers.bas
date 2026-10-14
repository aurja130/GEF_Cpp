' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
' Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.
'
' M5 physics driver, group "barriers" (MILESTONE_5_PLAN.md section 3): BFTF, BFTFA, BFTFB, cut from
' GEF.bas, with the mass functions they call (LyPair, LyMass, FEDEFOLys, LDMass, AME2020, U_SHELL,
' U_SHELL_exp, U_SHELL_EO_exp) and the tables those read (BEldmTF, BEexp, ShellMO), filled by
' including GEF's own table files. Conventions: harness/drivers/M5_DRIVERS.md.
' Usage:
'   m5_barriers                 grids: <fn>_grid.txt and <fn>_random.txt per function
'   m5_barriers replay <dir>    replay/<fn>.txt for every <dir>/<fn>.txt arglog file

Declare Function LyMass(Z As Single,A As Single,beta As Single) As Single
Declare Function LyPair(Z As Integer,A As Integer) As Single
Declare Function FEDEFOLys(Z As Single,A As Single,beta As Single) As Single
Declare Function LDMass(Z As Single,A As Single,beta As Single) As Single
Declare Function AME2020(Z As Integer,A As Integer) As Single
Declare Function U_SHELL(Z As Integer,A As Integer) As Single
Declare Function U_SHELL_exp(Z As Integer, A As Integer) As Single
Declare Function U_SHELL_EO_exp(Z As Integer, A As Integer) As Single
Declare Function BFTF(RZ As Single,RA As Single,I_Switch As Integer) As Single
Declare Function BFTFA(RZ As Single,RA As Single,I_Switch As Integer) As Single
Declare Function BFTFB(RZ As Single,RA As Single,I_Switch As Integer) As Single

'@include-source utilities.bi
'@include-source BEldmTF.bas
'@include-source BEexp.bas
'@include-source ShellMO.bas
'@cut GEF.bas:16110-16137 as gef_lymass.bi
'@cut GEF.bas:16140-16151 as gef_lypair.bi
'@cut GEF.bas:16211-16214 as gef_fedefolys.bi
'@cut GEF.bas:16217-16236 as gef_ldmass.bi
'@cut GEF.bas:16238-16259 as gef_ame2020.bi
'@cut GEF.bas:16261-16271 as gef_u_shell.bi
'@cut GEF.bas:16273-16292 as gef_u_shell_exp.bi
'@cut GEF.bas:16294-16306 as gef_u_shell_eo_exp.bi
'@cut GEF.bas:17657-17750 as gef_bftf.bi
'@cut GEF.bas:17752-17773 as gef_bftfa.bi
'@cut GEF.bas:17775-17796 as gef_bftfb.bi
'@include-driver m5_common.bi

#include "utilities.bi"
' GEF.bas:760, module level; used by LyMass and the other mass functions.
Const As Single pi = 3.14159
' GEF.bas:1222, 1559: BEldmTF(N, Z), N 0..203, Z 0..136.
ReDim Shared BEldmTF(0 To 203,0 To 136) As Single
#include "BEldmTF.bas"
' GEF.bas:1233, 1561: BEexp(N, Z).
ReDim Shared BEexp(0 To 203,0 To 136) As Single
#include "BEexp.bas"
' GEF.bas:1255, 1565: ShellMO(N, Z).
ReDim Shared ShellMO(0 To 203,0 To 136) As Single
#include "ShellMO.bas"
#include "gef_lymass.bi"
#include "gef_lypair.bi"
#include "gef_fedefolys.bi"
#include "gef_ldmass.bi"
#include "gef_ame2020.bi"
#include "gef_u_shell.bi"
#include "gef_u_shell_exp.bi"
#include "gef_u_shell_eo_exp.bi"
#include "gef_bftf.bi"
#include "gef_bftfa.bi"
#include "gef_bftfb.bi"
#include "m5_common.bi"

Const S_BARRIER = "RZ:f32 RA:f32 I_Switch:i64 result:f32"

Const N_RANDOM = 100000

' One line of function Which (0 = BFTF, 1 = BFTFA, 2 = BFTFB): inputs echoed, result recomputed.
Function LineOf(ByVal Which As Long, ByVal RZ As Single, ByVal RA As Single, ByVal ISW As Integer) As String
  Dim As String Head = M5_F32(RZ) & " " & M5_F32(RA) & " " & M5_I64(ISW) & " "
  If Which = 0 Then
    Return Head & M5_F32(BFTF(RZ, RA, ISW))
  ElseIf Which = 1 Then
    Return Head & M5_F32(BFTFA(RZ, RA, ISW))
  End If
  Return Head & M5_F32(BFTFB(RZ, RA, ISW))
End Function

' Structured grids of function Which, in this loop order (all lines: RZ RA I_Switch result):
'  1. Integer grid: RZ = Z, RA = Z + N, Z = 1..135 (outer), N = 1..202 (inner; the table range
'     0..203 x 0..136 of BEldmTF, BEexp, ShellMO), I_Switch = 0..6 (innermost).
'  2. Undefined options: I_Switch = -1, 7 at (RZ, RA) = (60, 120), (92, 236), (135, 336).
'  3. Quarter steps: RZ = M5_Axis(84, 0.25, K), K = 0..48 (outer); RA = M5_Axis(225, 0.25, J),
'     J = 0..80; I_Switch = 0..6 (innermost).
'  4. RX boundary: RZ = M5_Axis(59.5, 0.25, K), K = 0..4 (outer); RA = M5_Axis(119.25, 0.25, J),
'     J = 0..6; I_Switch = 0..6 (innermost). At (60, 120) RX = 30 exactly (quirk Q-037).
Sub Structured(ByVal F As Long, ByVal Which As Long)
  Dim As Single UZ(0 To 2) = {60, 92, 135}
  Dim As Single UA(0 To 2) = {120, 236, 336}
  Dim As Integer USW(0 To 1) = {-1, 7}
  For IZ As Long = 1 To 135
    For KN As Long = 1 To 202
      For ISW As Integer = 0 To 6
        Print #F, LineOf(Which, CSng(IZ), CSng(IZ + KN), ISW)
      Next
    Next
  Next
  For J As Long = 0 To 2
    For K As Long = 0 To 1
      Print #F, LineOf(Which, UZ(J), UA(J), USW(K))
    Next
  Next
  For K As Long = 0 To 48
    For J As Long = 0 To 80
      For ISW As Integer = 0 To 6
        Print #F, LineOf(Which, M5_Axis(84, 0.25, K), M5_Axis(225, 0.25, J), ISW)
      Next
    Next
  Next
  For K As Long = 0 To 4
    For J As Long = 0 To 6
      For ISW As Integer = 0 To 6
        Print #F, LineOf(Which, M5_Axis(59.5, 0.25, K), M5_Axis(119.25, 0.25, J), ISW)
      Next
    Next
  Next
End Sub

' Random tuples of function Which: Randomize Seed, 3; per tuple, in this order: RZ = M5_Draw(84, 107),
' RA = M5_Draw(210, 265) (the ranges of the four M5.2 captures), then I_Switch = ILo + Int(Rnd * INum)
' over the captured I_Switch range: BFTF 0..5, BFTFA 1..3, BFTFB 0..3 (the structured grids cover
' 0..6, -1, 7).
Sub Randoms(ByVal Which As Long, ByVal Seed As Long, ByRef Cfn As String)
  Dim As Long ILo = 0, INum = 6
  If Which = 1 Then
    ILo = 1
    INum = 3
  ElseIf Which = 2 Then
    INum = 4
  End If
  Dim As String Cname = Cfn & "_random.txt"
  Dim As Long F
  Randomize Seed, 3
  F = M5_OpenGrid(Cname, Cfn, S_BARRIER)
  For I As Long = 1 To N_RANDOM
    Dim As Single RZ = M5_Draw(84, 107)
    Dim As Single RA = M5_Draw(210, 265)
    Dim As Integer ISW = ILo + CLng(Int(Rnd * INum))
    Print #F, LineOf(Which, RZ, RA, ISW)
  Next
  Close #F
End Sub

Sub Grids()
  Dim As Long F
  Dim As String Cname
  Cname = "BFTF_grid.txt"
  F = M5_OpenGrid(Cname, "BFTF", S_BARRIER)
  Structured(F, 0)
  Close #F
  Randoms(0, 5101, "BFTF")

  Cname = "BFTFA_grid.txt"
  F = M5_OpenGrid(Cname, "BFTFA", S_BARRIER)
  Structured(F, 1)
  Close #F
  Randoms(1, 5102, "BFTFA")

  Cname = "BFTFB_grid.txt"
  F = M5_OpenGrid(Cname, "BFTFB", S_BARRIER)
  Structured(F, 2)
  Close #F
  Randoms(2, 5103, "BFTFB")
End Sub

Sub Replay(ByRef Cdir As String)
  Dim As M5_Replay R
  Dim As String T()
  If M5_ReplayOpen(R, Cdir, "BFTF", S_BARRIER) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineOf(0, M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseI64(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "BFTFA", S_BARRIER) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineOf(1, M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseI64(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "BFTFB", S_BARRIER) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineOf(2, M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseI64(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
End Sub

If Command(1) = "replay" Then
  Replay(Command(2))
ElseIf Command(1) = "" Then
  Grids()
Else
  Print "usage: m5_barriers [replay <arglog dir>]"
  End 2
End If
