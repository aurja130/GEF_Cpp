' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
' Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.
'
' M5 physics driver, group "egamma_table" (MILESTONE_5_PLAN.md D5): the P_Egamma_low cross-section
' table builder, GEF.bas:16980-17037, cut verbatim into Sub PEglTable. The piece reads GEF's
' globals DEFOtab and ShellMO (filled by DEFO.bas and ShellMO.bas) and Tscale, Econd, Etrans (set
' per call by PEglLine), and calls U_Temp with its callees, E0_GDR, Width_GDR and Efac_def_GDR.
' Its locals are declared in Sub PEglTable as in GEF.bas:16966-16976. Conventions:
' harness/drivers/M5_DRIVERS.md.
'
' Usage:
'   m5_egamma_table                 grids: pegl_table_grid.txt and pegl_table_random.txt
'   m5_egamma_table replay <dir>    replay/pegl_table.txt for <dir>/pegl_table.txt (arglog)
'
' Each grid line is one call: the six inputs echoed, then the 17 outputs (N, Tm, betadef, gammadef,
' sigMax, Eg, I, E0(0..3), G0(0..3), UBound(sigma), hash of sigma).
' Structured grid, 46,815 calls:
'   A  Zi x (Ai - Zi) x (Tscale, Econd, Etrans) x Ei = 0.05 .. 10.00 step 0.05 (200 values)
'      7 x 9 x 3 x 200 = 37,800
'   B  Zi x (Ai - Zi) x Ei in EDGE, with (Tscale, Econd, Etrans) = (1, 2, 9.5)
'      7 x 9 x 105 = 6,615
'   C  (Zi, Ai) in {(37.5, 92), (37, 91.5), (37.5, 91.5), (36.5, 91.5)} x 3 parameter sets
'      x Ei = 0.05 .. 10.00 step 0.05: 4 x 3 x 200 = 2,400. Half-integer Zi and Ai - Zi exercise
'      the round-half-to-even of the DEFOtab index.
' EDGE: K = 1..100 running Single sum of 0.1 (so Ei is an accumulated Eg), then 0, 0.001, 0.05, 0.1, 25.
' Random grid, 100,000 calls: Randomize 6001, 3; six draws per call in this order: Zi = Int(20..100),
' Ai = Zi + Int(30..150), Ei (0.05..10), Tscale (0.8..1.2), Econd (0.5..3), Etrans (5..12).

Declare Function TEgidy(A As Single,DU As Single,Fred As Single) As Single
Declare Function LyPair(Z As Integer,A As Integer) As Single
Declare Function U_SHELL(Z As Integer,A As Integer) As Single
Declare Function U_alev_ld(Z As Single, A As Single) As Single
Declare Function U_Temp(Z As Single, A As Single, E As Single, Ishell As Integer, _
             Ipair As Integer, Tscale As Single,Econd As Single, Etrans As Single) As Single
Declare Function E0_GDR(Z As Single, A As Single) As Single
Declare Function Width_GDR(E0 As Single) As Single
Declare Function Efac_def_GDR(Beta As Single,Gamma As Single,K As Single) As Single

'@include-source utilities.bi
'@include-source DEFO.bas
'@include-source ShellMO.bas
'@cut GEF.bas:16072-16095 as gef_tegidy.bi
'@cut GEF.bas:16140-16151 as gef_lypair.bi
'@cut GEF.bas:16261-16271 as gef_u_shell.bi
'@cut GEF.bas:17173-17177 as gef_u_alev_ld.bi
'@cut GEF.bas:17335-17385 as gef_u_temp.bi
'@cut GEF.bas:17439-17475 as gef_gdr.bi
'@cut GEF.bas:16980-17037 as egamma_piece.bi
'@include-driver m5_common.bi

#include "utilities.bi"
' GEF.bas:760, module level; used by Efac_def_GDR.
Const As Single pi = 3.14159
' GEF.bas:1244, 1245: DEFOtab(Ai - Zi, Zi), 0 To 236 x 0 To 136; filled by DEFO.bas.
ReDim Shared DEFOtab(0 To 236,0 To 136) As Single
#include "DEFO.bas"
' GEF.bas:1255: ShellMO(N, Z), 0 To 203 x 0 To 136; read by U_SHELL.
ReDim Shared ShellMO(0 To 203,0 To 136) As Single
#include "ShellMO.bas"
' GEF.bas:998-1000: globals read by P_Egamma_low; set per call by PEglLine.
Dim Shared As Single Tscale
Dim Shared As Single Econd
Dim Shared As Single Etrans
#include "gef_tegidy.bi"
#include "gef_lypair.bi"
#include "gef_u_shell.bi"
#include "gef_u_alev_ld.bi"
#include "gef_u_temp.bi"
#include "gef_gdr.bi"
#include "m5_common.bi"

Const S_PEGL = "in.Zi:f32 in.Ai:f32 in.Ei:f32 in.Tscale:f32 in.Econd:f32 in.Etrans:f32 out.N:i64 out.Tm:f32 out.betadef:f32 out.gammadef:f32 out.sigMax:f32 out.Eg:f32 out.I:i64 out.E0(0):f32 out.E0(1):f32 out.E0(2):f32 out.E0(3):f32 out.G0(0):f32 out.G0(1):f32 out.G0(2):f32 out.G0(3):f32 out.UBound(sigma):i64 out.sigma(0..UBound):f32hash"

Const N_RANDOM = 100000

' The P_Egamma_low table builder (GEF.bas:16980-17037). Locals as declared in GEF.bas:16966-16976.
' Outs: the 17 output tokens the arglog site pegl_table logs after the piece.
Sub PEglTable(ByVal Zi As Single, ByVal Ai As Single, ByVal Ei As Single, ByRef Outs As String)
  Dim As Integer N
  Dim As Single sigMax, Eg
  Dim As Single Tm
  Dim As Single betadef = 0
  Dim As Single gammadef = 0
  Dim As Single G0(3), E0(3)
  Dim As Integer I
#include "egamma_piece.bi"
  Outs = M5_I64(N) & " " & M5_F32(Tm) & " " & M5_F32(betadef) & " " & M5_F32(gammadef) & " " & _
         M5_F32(sigMax) & " " & M5_F32(Eg) & " " & M5_I64(I) & " " & _
         M5_F32(E0(0)) & " " & M5_F32(E0(1)) & " " & M5_F32(E0(2)) & " " & M5_F32(E0(3)) & " " & _
         M5_F32(G0(0)) & " " & M5_F32(G0(1)) & " " & M5_F32(G0(2)) & " " & M5_F32(G0(3)) & " " & _
         M5_I64(UBound(sigma)) & " " & M5_F32Hash(sigma())
End Sub

' One line: the six inputs echoed, then the 17 outputs recomputed (23 tokens).
Function PEglLine(ByVal Zi As Single, ByVal Ai As Single, ByVal Ei As Single, ByVal Tsc As Single, _
                  ByVal Ec As Single, ByVal Et As Single) As String
  Dim As String Outs
  Tscale = Tsc
  Econd = Ec
  Etrans = Et
  PEglTable(Zi, Ai, Ei, Outs)
  Return M5_F32(Zi) & " " & M5_F32(Ai) & " " & M5_F32(Ei) & " " & M5_F32(Tsc) & " " & _
         M5_F32(Ec) & " " & M5_F32(Et) & " " & Outs
End Function

Sub Grids()
  Dim As Single Zs(0 To 6) = {20, 26, 37, 50, 64, 82, 99}
  Dim As Single Ds(0 To 8) = {31, 46, 55, 66, 77, 91, 105, 120, 149}
  Dim As Single Tsc(0 To 2) = {1.0!, 0.9!, 1.2!}
  Dim As Single Ecn(0 To 2) = {2.0!, 1.0!, 3.0!}
  Dim As Single Etr(0 To 2) = {9.5!, 5.0!, 12.0!}
  Dim As Single TieZ(0 To 3) = {37.5!, 37.0!, 37.5!, 36.5!}
  Dim As Single TieA(0 To 3) = {92.0!, 91.5!, 91.5!, 91.5!}
  Dim As Single Edge(0 To 104)
  Dim As Single Acc = 0
  Dim As Single Zi, Ai, Ei, T1, E1, E2
  Dim As Long F, Iz, Id, Ip, Ie, It, K

  For K = 1 To 100
    Acc = Acc + 0.1!
    Edge(K - 1) = Acc
  Next
  Edge(100) = 0
  Edge(101) = 0.001!
  Edge(102) = 0.05!
  Edge(103) = 0.1!
  Edge(104) = 25

  F = M5_OpenGrid("pegl_table_grid.txt", "pegl_table", S_PEGL)
  For Iz = 0 To 6
    For Id = 0 To 8
      For Ip = 0 To 2
        For Ie = 0 To 199
          Print #F, PEglLine(Zs(Iz), Zs(Iz) + Ds(Id), M5_Axis(0.05, 0.05, Ie), Tsc(Ip), Ecn(Ip), Etr(Ip))
        Next
      Next
    Next
  Next
  For Iz = 0 To 6
    For Id = 0 To 8
      For Ie = 0 To 104
        Print #F, PEglLine(Zs(Iz), Zs(Iz) + Ds(Id), Edge(Ie), Tsc(0), Ecn(0), Etr(0))
      Next
    Next
  Next
  For It = 0 To 3
    For Ip = 0 To 2
      For Ie = 0 To 199
        Print #F, PEglLine(TieZ(It), TieA(It), M5_Axis(0.05, 0.05, Ie), Tsc(Ip), Ecn(Ip), Etr(Ip))
      Next
    Next
  Next
  Close #F

  Randomize 6001, 3
  F = M5_OpenGrid("pegl_table_random.txt", "pegl_table", S_PEGL)
  For K = 1 To N_RANDOM
    Zi = Int(M5_Draw(20, 100))
    Ai = Zi + Int(M5_Draw(30, 150))
    Ei = M5_Draw(0.05, 10)
    T1 = M5_Draw(0.8, 1.2)
    E1 = M5_Draw(0.5, 3)
    E2 = M5_Draw(5, 12)
    Print #F, PEglLine(Zi, Ai, Ei, T1, E1, E2)
  Next
  Close #F
End Sub

Sub Replay(ByRef Cdir As String)
  Dim As M5_Replay R
  Dim As String T()
  Dim As String L
  If M5_ReplayOpen(R, Cdir, "pegl_table", S_PEGL) Then
    While M5_ReplayNext(R, T())
      L = PEglLine(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2)), M5_ParseF32(T(3)), _
                   M5_ParseF32(T(4)), M5_ParseF32(T(5)))
      M5_ReplayWrite(R, L)
    Wend
    M5_ReplayClose(R)
  End If
End Sub

If Command(1) = "replay" Then
  Replay(Command(2))
ElseIf Command(1) = "" Then
  Grids()
Else
  Print "usage: m5_egamma_table | m5_egamma_table replay <arglog dir>"
  End 2
End If
