' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
' Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.
'
' M5 physics driver, group "rotation" (MILESTONE_5_PLAN.md section 3): U_Ired, U_IredFF,
' U_I_Shell, E0_GDR, Width_GDR, Efac_def_GDR, u_accel, cut from GEF.bas. Conventions:
' harness/drivers/M5_DRIVERS.md.
' Usage:
'   m5_rotation                grids: <fn>_grid.txt and <fn>_random.txt per function
'   m5_rotation replay <dir>   replay/<fn>.txt for every <dir>/<fn>.txt arglog file

Declare Function u_accel(A1 As Single,Z1 As Single,A2 As Single,Z2 As Single, _
          TKE As Single,E0 As Single,Tn As Single) As Single
Declare Function U_Ired(Z As Single,A As Single) As Single
Declare Function U_IredFF(Z As Single,A As Single) As Single
Declare Function U_I_Shell(Z As Single, A As Single) As Single
Declare Function E0_GDR(Z As Single, A As Single) As Single
Declare Function Width_GDR(E0 As Single) As Single
Declare Function Efac_def_GDR(Beta As Single,Gamma As Single,K As Single) As Single

'@include-source utilities.bi
'@cut GEF.bas:16907-16959 as gef_u_accel.bi
'@cut GEF.bas:17094-17170 as gef_rotation.bi
'@cut GEF.bas:17439-17475 as gef_gdr.bi
'@include-driver m5_common.bi

#include "utilities.bi"
#include "gef_u_accel.bi"
#include "gef_rotation.bi"
' GEF.bas:760, module level in GEF; used by Efac_def_GDR (gef_gdr.bi).
Const As Single pi = 3.14159
#include "gef_gdr.bi"
#include "m5_common.bi"

Const S_ZA = "Z:f32 A:f32 result:f32"
Const S_E0 = "E0:f32 result:f32"
Const S_EFAC = "Beta:f32 Gamma:f32 K:f32 result:f32"
Const S_UACC = "A1:f32 Z1:f32 A2:f32 Z2:f32 TKE:f32 E0:f32 Tn:f32 result:f32"

Const N_RANDOM = 100000

Function LineUIred(ByVal Z As Single, ByVal A As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(U_Ired(Z, A))
End Function

Function LineUIredFF(ByVal Z As Single, ByVal A As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(U_IredFF(Z, A))
End Function

Function LineUIShell(ByVal Z As Single, ByVal A As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(U_I_Shell(Z, A))
End Function

Function LineE0GDR(ByVal Z As Single, ByVal A As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(E0_GDR(Z, A))
End Function

Function LineWidth(ByVal E0 As Single) As String
  Return M5_F32(E0) & " " & M5_F32(Width_GDR(E0))
End Function

Function LineEfac(ByVal Beta As Single, ByVal Gamma As Single, ByVal K As Single) As String
  Return M5_F32(Beta) & " " & M5_F32(Gamma) & " " & M5_F32(K) & " " & _
         M5_F32(Efac_def_GDR(Beta, Gamma, K))
End Function

Function LineUAcc(ByVal A1 As Single, ByVal Z1 As Single, ByVal A2 As Single, _
                  ByVal Z2 As Single, ByVal TKE As Single, ByVal E0 As Single, _
                  ByVal Tn As Single) As String
  Return M5_F32(A1) & " " & M5_F32(Z1) & " " & M5_F32(A2) & " " & M5_F32(Z2) & " " & _
         M5_F32(TKE) & " " & M5_F32(E0) & " " & M5_F32(Tn) & " " & _
         M5_F32(u_accel(A1, Z1, A2, Z2, TKE, E0, Tn))
End Function

Sub Grids()
  Dim As Long F
  Dim As Single KB(0 To 7) = {1, 2, 3, 0, -1, 0.5, 4, 2.5}
  Dim As Single BC(0 To 1) = {0, -0.0!}
  Dim As Single WE(0 To 5) = {0, -0.0!, 1.4E-45!, -1.4E-45!, 9.999999!, 10.000001!}
  Dim As Single PA1(0 To 7) = {140, 150, 110, 118, 140, 0, 120, 236}
  Dim As Single PZ1(0 To 7) = {56, 60, 40, 46, 0, 30, 50, 92}
  Dim As Single PA2(0 To 7) = {96, 114, 126, 118, 96, 236, -120, 0}
  Dim As Single PZ2(0 To 7) = {36, 50, 52, 46, 92, 92, 50, 0}
  Dim As Single QE(0 To 19) = {0, 0, 0, 0, 0, 5, 5, 5, 5, 5, 20, 20, 20, 20, 20, 50, 50, 50, 50, 50}
  Dim As Single QT(0 To 19) = {-1.4E-45!, 0, 1.4E-45!, 0.5, 100, 4.9999995!, 5, 5.0000005!, _
                               5.5, 105, 19.999998!, 20, 20.000002!, 20.5, 120, 49.999996!, _
                               50, 50.000004!, 50.5, 150}
  Dim As Single TNL(0 To 13) = {0, 1.4E-45!, 0.0001!, 0.01!, 0.010000001!, 0.1!, 0.5, 1, _
                                1.1!, 2, 10, 11, 100, 100.5}

  ' U_Ired: nuclide grid Z = 1..120, N = 0..200, Zv = Z + 0.25 I, Av = Z + N + 0.25 J (I, J = 0..3);
  ' random Z in [31, 92), A in [77, 236).
  F = M5_OpenGrid("U_Ired_grid.txt", "U_Ired", S_ZA)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 200
      For I As Long = 0 To 3
        For J As Long = 0 To 3
          Dim As Single Zv = Zi + 0.25!*I
          Dim As Single Av = (Zi + Ni) + 0.25!*J
          Print #F, LineUIred(Zv, Av)
        Next
      Next
    Next
  Next
  Close #F
  Randomize 5101, 3
  F = M5_OpenGrid("U_Ired_random.txt", "U_Ired", S_ZA)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z = M5_Draw(31, 92)
    Dim As Single A = M5_Draw(77, 236)
    Print #F, LineUIred(Z, A)
  Next
  Close #F

  ' U_IredFF: nuclide grid as U_Ired; random Z in [30, 73), A in [77, 180).
  F = M5_OpenGrid("U_IredFF_grid.txt", "U_IredFF", S_ZA)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 200
      For I As Long = 0 To 3
        For J As Long = 0 To 3
          Dim As Single Zv = Zi + 0.25!*I
          Dim As Single Av = (Zi + Ni) + 0.25!*J
          Print #F, LineUIredFF(Zv, Av)
        Next
      Next
    Next
  Next
  Close #F
  Randomize 5102, 3
  F = M5_OpenGrid("U_IredFF_random.txt", "U_IredFF", S_ZA)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z = M5_Draw(30, 73)
    Dim As Single A = M5_Draw(77, 180)
    Print #F, LineUIredFF(Z, A)
  Next
  Close #F

  ' U_I_Shell: nuclide grid as U_Ired; random Z in [29, 74), A in [72, 181).
  F = M5_OpenGrid("U_I_Shell_grid.txt", "U_I_Shell", S_ZA)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 200
      For I As Long = 0 To 3
        For J As Long = 0 To 3
          Dim As Single Zv = Zi + 0.25!*I
          Dim As Single Av = (Zi + Ni) + 0.25!*J
          Print #F, LineUIShell(Zv, Av)
        Next
      Next
    Next
  Next
  Close #F
  Randomize 5103, 3
  F = M5_OpenGrid("U_I_Shell_random.txt", "U_I_Shell", S_ZA)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z = M5_Draw(29, 74)
    Dim As Single A = M5_Draw(72, 181)
    Print #F, LineUIShell(Z, A)
  Next
  Close #F

  ' E0_GDR: nuclide grid as U_Ired; random Z in [29, 92), A in [73, 236).
  F = M5_OpenGrid("E0_GDR_grid.txt", "E0_GDR", S_ZA)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 200
      For I As Long = 0 To 3
        For J As Long = 0 To 3
          Dim As Single Zv = Zi + 0.25!*I
          Dim As Single Av = (Zi + Ni) + 0.25!*J
          Print #F, LineE0GDR(Zv, Av)
        Next
      Next
    Next
  Next
  Close #F
  Randomize 5104, 3
  F = M5_OpenGrid("E0_GDR_random.txt", "E0_GDR", S_ZA)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z = M5_Draw(29, 92)
    Dim As Single A = M5_Draw(73, 236)
    Print #F, LineE0GDR(Z, A)
  Next
  Close #F

  ' Width_GDR: E0 = -1 .. 10 step 0.01, then 10 .. 100 step 0.1, then the edges WE; random E0 in
  ' [11.66, 19.6).
  F = M5_OpenGrid("Width_GDR_grid.txt", "Width_GDR", S_E0)
  For I As Long = 0 To 1099
    Print #F, LineWidth(M5_Axis(-1, 0.01, I))
  Next
  For I As Long = 0 To 900
    Print #F, LineWidth(M5_Axis(10, 0.1, I))
  Next
  For I As Long = 0 To 5
    Print #F, LineWidth(WE(I))
  Next
  Close #F
  Randomize 5105, 3
  F = M5_OpenGrid("Width_GDR_random.txt", "Width_GDR", S_E0)
  For I As Long = 1 To N_RANDOM
    Dim As Single E0 = M5_Draw(11.66, 19.6)
    Print #F, LineWidth(E0)
  Next
  Close #F

  ' Efac_def_GDR: (a) Beta = -0.5 .. 1.5 step 0.01 with Gamma = -120 Beta + 47.4 and K = 1..3;
  ' (b) Beta = -0.5 .. 1.75 step 0.25, Gamma = -200 .. 200 step 0.5, K over KB; (c) Beta and Gamma
  ' over {0, -0.0}, K = 1..3. Random Beta in [-0.26, 0.4), Gamma in [0.4, 78.5), K in [1, 3).
  F = M5_OpenGrid("Efac_def_GDR_grid.txt", "Efac_def_GDR", S_EFAC)
  For I As Long = 0 To 200
    Dim As Single Bv = M5_Axis(-0.5, 0.01, I)
    Dim As Single Gv = CSng(-120.0# * Bv + 47.4#)
    For Kl As Long = 1 To 3
      Print #F, LineEfac(Bv, Gv, CSng(Kl))
    Next
  Next
  For I As Long = 0 To 8
    Dim As Single Bv = M5_Axis(-0.5, 0.25, I)
    For J As Long = 0 To 800
      Dim As Single Gv = M5_Axis(-200, 0.5, J)
      For KI As Long = 0 To 7
        Print #F, LineEfac(Bv, Gv, KB(KI))
      Next
    Next
  Next
  For I As Long = 0 To 1
    For J As Long = 0 To 1
      For Kl As Long = 1 To 3
        Print #F, LineEfac(BC(I), BC(J), CSng(Kl))
      Next
    Next
  Next
  Close #F
  Randomize 5106, 3
  F = M5_OpenGrid("Efac_def_GDR_random.txt", "Efac_def_GDR", S_EFAC)
  For I As Long = 1 To N_RANDOM
    Dim As Single Beta = M5_Draw(-0.26, 0.4)
    Dim As Single Gamma = M5_Draw(0.4, 78.5)
    Dim As Single Kv = M5_Draw(1, 3)
    Print #F, LineEfac(Beta, Gamma, Kv)
  Next
  Close #F

  ' u_accel: (a) the (A1, Z1, A2, Z2) pairs PA1..PZ2 with (TKE, E0) pairs QT, QE and Tn = TNL;
  ' (b) three blocks, Tn = 0 .. 100 step 0.01; random tuples in the capture ranges.
  F = M5_OpenGrid("u_accel_grid.txt", "u_accel", S_UACC)
  For P As Long = 0 To 7
    For Q As Long = 0 To 19
      For Tq As Long = 0 To 13
        Print #F, LineUAcc(PA1(P), PZ1(P), PA2(P), PZ2(P), QT(Q), QE(Q), TNL(Tq))
      Next
    Next
  Next
  For I As Long = 0 To 10000
    Print #F, LineUAcc(140, 56, 96, 36, 150, 20, M5_Axis(0, 0.01, I))
  Next
  For I As Long = 0 To 10000
    Print #F, LineUAcc(110, 40, 126, 52, 120, 5, M5_Axis(0, 0.01, I))
  Next
  For I As Long = 0 To 10000
    Print #F, LineUAcc(150, 60, 114, 50, 200, 50, M5_Axis(0, 0.01, I))
  Next
  Close #F
  Randomize 5107, 3
  F = M5_OpenGrid("u_accel_random.txt", "u_accel", S_UACC)
  For I As Long = 1 To N_RANDOM
    Dim As Single A1 = M5_Draw(74, 184)
    Dim As Single Z1 = M5_Draw(30, 73)
    Dim As Single A2 = M5_Draw(68, 177)
    Dim As Single Z2 = M5_Draw(28, 70)
    Dim As Single TKE = M5_Draw(108, 276)
    Dim As Single E0 = M5_Draw(0, 85)
    Dim As Single Tn = M5_Draw(0, 100)
    Print #F, LineUAcc(A1, Z1, A2, Z2, TKE, E0, Tn)
  Next
  Close #F
End Sub

Sub Replay(ByRef Cdir As String)
  Dim As M5_Replay R
  Dim As String T()
  If M5_ReplayOpen(R, Cdir, "U_Ired", S_ZA) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineUIred(M5_ParseF32(T(0)), M5_ParseF32(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "U_IredFF", S_ZA) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineUIredFF(M5_ParseF32(T(0)), M5_ParseF32(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "U_I_Shell", S_ZA) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineUIShell(M5_ParseF32(T(0)), M5_ParseF32(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "E0_GDR", S_ZA) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineE0GDR(M5_ParseF32(T(0)), M5_ParseF32(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "Width_GDR", S_E0) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineWidth(M5_ParseF32(T(0))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "Efac_def_GDR", S_EFAC) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineEfac(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "u_accel", S_UACC) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineUAcc(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2)), _
                                 M5_ParseF32(T(3)), M5_ParseF32(T(4)), M5_ParseF32(T(5)), _
                                 M5_ParseF32(T(6))))
    Wend
    M5_ReplayClose(R)
  End If
End Sub

If Command(1) = "replay" Then
  Replay(Command(2))
ElseIf Command(1) = "" Then
  Grids()
Else
  Print "usage: m5_rotation [replay <arglog dir>]"
  End 2
End If
