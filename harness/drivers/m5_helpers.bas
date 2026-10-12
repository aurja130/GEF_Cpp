' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
' Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.
'
' M5 physics driver, group "helpers" (MILESTONE_5_PLAN.md section 3): Gaussintegral, Bell, U_Box,
' EVEN_ODD, cut from GEF.bas. Conventions: harness/drivers/M5_DRIVERS.md.
' Usage:
'   m5_helpers                 grids: <fn>_grid.txt and <fn>_random.txt per function
'   m5_helpers replay <dir>    replay/<fn>.txt for every <dir>/<fn>.txt arglog file

Declare Function Floor(R As Single) As Single
Declare Function Gaussintegral(R_x As Single,R_sigma As Single) As Single
Declare Function Bell(xpos As Single, xleft As Single, xright As Single) As Single
Declare Function U_Box(x As Single,sigma As Single, _
                  width As Single) As Single
Declare Function EVEN_ODD(R_ORIGIN As Single,R_EVEN_ODD As Single) As Integer

'@include-source utilities.bi
'@cut GEF.bas:18052-18054 as gef_floor.bi
'@cut GEF.bas:17593-17653 as gef_even_odd.bi
'@cut GEF.bas:17808-17837 as gef_helpers.bi
'@include-driver m5_common.bi

#include "utilities.bi"
#include "gef_floor.bi"
#include "gef_even_odd.bi"
#include "gef_helpers.bi"
#include "m5_common.bi"

Const S_GAUSS = "R_x:f32 R_sigma:f32 result:f32"
Const S_BELL = "xpos:f32 xleft:f32 xright:f32 result:f32"
Const S_BOX = "x:f32 sigma:f32 width:f32 result:f32"
Const S_EO = "R_ORIGIN:f32 R_EVEN_ODD:f32 result:i64"

Const N_RANDOM = 100000

Function LineGauss(ByVal X As Single, ByVal S As Single) As String
  Return M5_F32(X) & " " & M5_F32(S) & " " & M5_F32(Gaussintegral(X, S))
End Function

Function LineBell(ByVal X As Single, ByVal L As Single, ByVal R As Single) As String
  Return M5_F32(X) & " " & M5_F32(L) & " " & M5_F32(R) & " " & M5_F32(Bell(X, L, R))
End Function

Function LineBox(ByVal X As Single, ByVal S As Single, ByVal W As Single) As String
  Return M5_F32(X) & " " & M5_F32(S) & " " & M5_F32(W) & " " & M5_F32(U_Box(X, S, W))
End Function

Function LineEO(ByVal X As Single, ByVal E As Single) As String
  Return M5_F32(X) & " " & M5_F32(E) & " " & M5_I64(EVEN_ODD(X, E))
End Function

Sub Grids()
  Dim As Long F
  ' Gaussintegral: R_x = -10 .. 10 step 0.01 times the sigma list; random R_x in [-50, 80),
  ' R_sigma in [0, 6).
  Dim As Single SigG(0 To 11) = {0, -0.0!, -1, 1E-30, 2E-4, 0.01, 0.1, 0.5, 1, 2, 5, 100}
  F = M5_OpenGrid("Gaussintegral_grid.txt", "Gaussintegral", S_GAUSS)
  For J As Long = 0 To 11
    For I As Long = 0 To 2000
      Print #F, LineGauss(M5_Axis(-10, 0.01, I), SigG(J))
    Next
  Next
  Close #F
  Randomize 5001, 3
  F = M5_OpenGrid("Gaussintegral_random.txt", "Gaussintegral", S_GAUSS)
  For I As Long = 1 To N_RANDOM
    Dim As Single X = M5_Draw(-50, 80)
    Dim As Single S = M5_Draw(0, 6)
    Print #F, LineGauss(X, S)
  Next
  Close #F

  ' Bell: xpos = -5 .. 150 step 0.05 times the (xleft, xright) list; random xpos in [0, 150),
  ' xleft in [0, 100), xright = xleft + [0, 20).
  Dim As Single BL(0 To 5) = {45, 0, 10, 10, 5, 45.0001}
  Dim As Single BR(0 To 5) = {49.5, 1, 10, 10.001, 4, 45.0021}
  F = M5_OpenGrid("Bell_grid.txt", "Bell", S_BELL)
  For J As Long = 0 To 5
    For I As Long = 0 To 3100
      Print #F, LineBell(M5_Axis(-5, 0.05, I), BL(J), BR(J))
    Next
  Next
  Close #F
  Randomize 5002, 3
  F = M5_OpenGrid("Bell_random.txt", "Bell", S_BELL)
  For I As Long = 1 To N_RANDOM
    Dim As Single X = M5_Draw(0, 150)
    Dim As Single L = M5_Draw(0, 100)
    Dim As Single R = CSng(L + 20 * Rnd)
    Print #F, LineBell(X, L, R)
  Next
  Close #F

  ' U_Box: x = -50 .. 50 step 0.05 times the (sigma, width) list; random x in [-60, 60),
  ' sigma in [0, 6), width in [0, 20).
  Dim As Single XS(0 To 5) = {4.2, 1, 0, 1, 0.1, 4.3}
  Dim As Single XW(0 To 5) = {11.5, 1, 1, 0, 20, 12.2}
  F = M5_OpenGrid("U_Box_grid.txt", "U_Box", S_BOX)
  For J As Long = 0 To 5
    For I As Long = 0 To 2000
      Print #F, LineBox(M5_Axis(-50, 0.05, I), XS(J), XW(J))
    Next
  Next
  Close #F
  Randomize 5003, 3
  F = M5_OpenGrid("U_Box_random.txt", "U_Box", S_BOX)
  For I As Long = 1 To N_RANDOM
    Dim As Single X = M5_Draw(-60, 60)
    Dim As Single S = M5_Draw(0, 6)
    Dim As Single W = M5_Draw(0, 20)
    Print #F, LineBox(X, S, W)
  Next
  Close #F

  ' EVEN_ODD: R_ORIGIN = -2 .. 130 step 0.01 times the R_EVEN_ODD list (edges of the 1E-3
  ' threshold, of Min(., 1) and of the 0.01 floor of Max); random R_ORIGIN in [0, 130),
  ' R_EVEN_ODD in [-1.5, 1.5).
  Dim As Single EO(0 To 13) = {0, 1E-3, -1E-3, 9.99E-4, -9.99E-4, 0.1, 0.3, -0.3, 0.99, 1, 2, _
                               -0.99, -1, -2}
  F = M5_OpenGrid("EVEN_ODD_grid.txt", "EVEN_ODD", S_EO)
  For J As Long = 0 To 13
    For I As Long = 0 To 13200
      Print #F, LineEO(M5_Axis(-2, 0.01, I), EO(J))
    Next
  Next
  Close #F
  Randomize 5004, 3
  F = M5_OpenGrid("EVEN_ODD_random.txt", "EVEN_ODD", S_EO)
  For I As Long = 1 To N_RANDOM
    Dim As Single X = M5_Draw(0, 130)
    Dim As Single E = M5_Draw(-1.5, 1.5)
    Print #F, LineEO(X, E)
  Next
  Close #F
End Sub

Sub Replay(ByRef Cdir As String)
  Dim As M5_Replay R
  Dim As String T()
  If M5_ReplayOpen(R, Cdir, "Gaussintegral", S_GAUSS) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineGauss(M5_ParseF32(T(0)), M5_ParseF32(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "Bell", S_BELL) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineBell(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "U_Box", S_BOX) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineBox(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "EVEN_ODD", S_EO) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineEO(M5_ParseF32(T(0)), M5_ParseF32(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
End Sub

If Command(1) = "replay" Then
  Replay(Command(2))
ElseIf Command(1) = "" Then
  Grids()
Else
  Print "usage: m5_helpers [replay <arglog dir>]"
  End 2
End If
