' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
' Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.
'
' M5 physics driver, group "shape" (MILESTONE_5_PLAN.md section 3): Getyield, F1, F2, Masscurv,
' Masscurv1, Masscurv2, De_Saddle_Scission, beta_light, beta_heavy, Z_equi, Beta_Equi, cut from
' GEF.bas. LyMass and ECOUL are cut as dependencies only. Conventions: harness/drivers/M5_DRIVERS.md.
' Beta_Equi writes its "not converged" line to the global file f, which this driver opens as
' Beta_Equi_print.txt; a grid row's printed flag is set when the file position moved during the call.
' Usage:
'   m5_shape                 grids: <fn>_grid.txt and <fn>_random.txt per function
'   m5_shape replay <dir>    replay/<fn>.txt for every <dir>/<fn>.txt arglog file

Declare Function Getyield(E_rel As Single,E_ref As Single,E_shell As Single, dE_defo As Single, _
                  T_low As Single,T_high As Single, T_high_mac As Single,I_Mode As Integer) As Single
Declare Function F1(Z_S_A As Single) As Single
Declare Function F2(Z_S_A As Single) As Single
Declare Function Masscurv(Z As Single,A As Single,RL As Single,kappa As Single, _
                  kappa4 As Single) As Single
Declare Function Masscurv1(Z As Single,A As Single,RL As Single,kappa As Single, _
                  kappa4 As Single) As Single
Declare Function Masscurv2(Z As Single,A As Single,RL As Single,kappa As Single, _
                  kappa4 As Single) As Single
Declare Function De_Saddle_Scission(Z_CN_in As Single,A_CN_in As Single, _
                  ESHIFTSASCI As Single) As Single
Declare Function LyMass(Z As Single,A As Single,beta As Single) As Single
Declare Function ECOUL(Z1 As Single,A1 As Single,beta1 As Single,Z2 As Single,A2 As Single, _
                  beta2 As Single,d As Single) As Single
Declare Function beta_light(Z As Integer,betaL0 As Single,betaL1 As Single) As Single
Declare Function beta_heavy(Z As Integer,betaH0 As Single,betaH1 As Single) As Single
Declare Function Z_equi(ZCN As Integer,A1 As Integer,A2 As Integer, _
                  beta1 As Single,beta2 As Single,d As Single,Imode As Integer) As Single
Declare Sub Beta_Equi(A1 As Single,A2 As Single,Z1 As Single,Z2 As Single,d As Single, _
                  beta1prev As Single,beta2prev As Single, _
                  ByRef beta1opt As Single,ByRef beta2opt As Single)

' Global file handle: GEF.bas Beta_Equi prints "not converged" to it (Print #f, ...).
Dim Shared As Integer f

'@include-source utilities.bi
'@cut GEF.bas:760-760 as gef_pi.bi
'@cut GEF.bas:16110-16137 as gef_lymass.bi
'@cut GEF.bas:16326-16355 as gef_ecoul.bi
'@cut GEF.bas:15862-15920 as gef_getyield.bi
'@cut GEF.bas:15923-15928 as gef_f1.bi
'@cut GEF.bas:15929-15934 as gef_f2.bi
'@cut GEF.bas:15936-15963 as gef_masscurv.bi
'@cut GEF.bas:15965-16003 as gef_masscurv1.bi
'@cut GEF.bas:16005-16045 as gef_masscurv2.bi
'@cut GEF.bas:16047-16063 as gef_de_saddle.bi
'@cut GEF.bas:16358-16365 as gef_beta_light.bi
'@cut GEF.bas:16368-16375 as gef_beta_heavy.bi
'@cut GEF.bas:16379-16426 as gef_z_equi.bi
'@cut GEF.bas:16480-16646 as gef_beta_equi.bi
'@include-driver m5_common.bi

#include "utilities.bi"
#include "gef_pi.bi"
#include "gef_lymass.bi"
#include "gef_ecoul.bi"
#include "gef_getyield.bi"
#include "gef_f1.bi"
#include "gef_f2.bi"
#include "gef_masscurv.bi"
#include "gef_masscurv1.bi"
#include "gef_masscurv2.bi"
#include "gef_de_saddle.bi"
#include "gef_beta_light.bi"
#include "gef_beta_heavy.bi"
#include "gef_z_equi.bi"
#include "gef_beta_equi.bi"
#include "m5_common.bi"

Const S_F1 = "Z_S_A:f32 result:f32"
Const S_F2 = "Z_S_A:f32 result:f32"
Const S_GETYIELD = "E_rel:f32 E:f32 E_shell:f32 dE_defo:f32 T_low:f32 T_high:f32 T_high_mac:f32 Imode:i64 result:f32"
Const S_MASSCURV = "Z:f32 A:f32 RL:f32 kappa:f32 kappa4:f32 result:f32"
Const S_DE_SADDLE = "Z_CN_in:f32 A_CN_in:f32 ESHIFTSASCI:f32 result:f32"
Const S_BETA_LIGHT = "Z:i64 betaL0:f32 betaL1:f32 result:f32"
Const S_BETA_HEAVY = "Z:i64 betaH0:f32 betaH1:f32 result:f32"
Const S_Z_EQUI = "ZCN:i64 A1:i64 A2:i64 beta1:f32 beta2:f32 d:f32 Imode:i64 result:f32"
Const S_BETA_EQUI = "A1:f32 A2:f32 Z1:f32 Z2:f32 d:f32 beta1prev:f32 beta2prev:f32 beta1opt.in:f32 beta1opt.out:f32 beta2opt.in:f32 beta2opt.out:f32 global.f:i64"
Const S_BETA_EQUI_GRID = "A1:f32 A2:f32 Z1:f32 Z2:f32 d:f32 beta1prev:f32 beta2prev:f32 beta1opt.in:f32 beta1opt.out:f32 beta2opt.in:f32 beta2opt.out:f32 printed:i64"

Const N_RANDOM = 100000
Const N_BETA_RANDOM = 2000

Function LineF1(ByVal ZSA As Single) As String
  Return M5_F32(ZSA) & " " & M5_F32(F1(ZSA))
End Function

Function LineF2(ByVal ZSA As Single) As String
  Return M5_F32(ZSA) & " " & M5_F32(F2(ZSA))
End Function

Function LineGetyield(ByVal ERel As Single, ByVal ERef As Single, ByVal EShell As Single, ByVal DEDefo As Single, ByVal TLow As Single, ByVal THigh As Single, ByVal THighMac As Single, ByVal IMode As Integer) As String
  Dim As Single Y = Getyield(ERel, ERef, EShell, DEDefo, TLow, THigh, THighMac, IMode)
  Return M5_F32(ERel) & " " & M5_F32(ERef) & " " & M5_F32(EShell) & " " & M5_F32(DEDefo) & " " & M5_F32(TLow) & " " & M5_F32(THigh) & " " & M5_F32(THighMac) & " " & M5_I64(IMode) & " " & M5_F32(Y)
End Function

Function MasscurvValue(ByVal Which As Long, ByVal Z As Single, ByVal A As Single, ByVal RL As Single, ByVal Kappa As Single, ByVal Kappa4 As Single) As Single
  If Which = 0 Then Return Masscurv(Z, A, RL, Kappa, Kappa4)
  If Which = 1 Then Return Masscurv1(Z, A, RL, Kappa, Kappa4)
  Return Masscurv2(Z, A, RL, Kappa, Kappa4)
End Function

Function LineMasscurv(ByVal Which As Long, ByVal Z As Single, ByVal A As Single, ByVal RL As Single, ByVal Kappa As Single, ByVal Kappa4 As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(RL) & " " & M5_F32(Kappa) & " " & M5_F32(Kappa4) & " " & M5_F32(MasscurvValue(Which, Z, A, RL, Kappa, Kappa4))
End Function

Function LineDeSaddle(ByVal ZCN As Single, ByVal ACN As Single, ByVal E As Single) As String
  Return M5_F32(ZCN) & " " & M5_F32(ACN) & " " & M5_F32(E) & " " & M5_F32(De_Saddle_Scission(ZCN, ACN, E))
End Function

Function BetaValue(ByVal Heavy As Long, ByVal Z As Integer, ByVal B0 As Single, ByVal B1 As Single) As Single
  If Heavy = 0 Then Return beta_light(Z, B0, B1)
  Return beta_heavy(Z, B0, B1)
End Function

Function LineBeta(ByVal Heavy As Long, ByVal Z As Integer, ByVal B0 As Single, ByVal B1 As Single) As String
  Return M5_I64(Z) & " " & M5_F32(B0) & " " & M5_F32(B1) & " " & M5_F32(BetaValue(Heavy, Z, B0, B1))
End Function

Function LineZEqui(ByVal ZCN As Integer, ByVal A1 As Integer, ByVal A2 As Integer, ByVal B1 As Single, ByVal B2 As Single, ByVal D As Single, ByVal IM As Integer) As String
  Return M5_I64(ZCN) & " " & M5_I64(A1) & " " & M5_I64(A2) & " " & M5_F32(B1) & " " & M5_F32(B2) & " " & M5_F32(D) & " " & M5_I64(IM) & " " & M5_F32(Z_equi(ZCN, A1, A2, B1, B2, D, IM))
End Function

' Runs Beta_Equi once. Returns 1 when it wrote a "not converged" line to f, else 0.
Function CallBetaEqui(ByVal A1 As Single, ByVal A2 As Single, ByVal Z1 As Single, ByVal Z2 As Single, ByVal D As Single, ByVal B1P As Single, ByVal B2P As Single, ByRef B1O As Single, ByRef B2O As Single) As Long
  Dim As LongInt Before, After
  Before = Seek(f)
  Beta_Equi(A1, A2, Z1, Z2, D, B1P, B2P, B1O, B2O)
  After = Seek(f)
  If After > Before Then Return 1
  Return 0
End Function

Function LineBetaEquiGrid(ByVal A1 As Single, ByVal A2 As Single, ByVal Z1 As Single, ByVal Z2 As Single, ByVal D As Single, ByVal B1P As Single, ByVal B2P As Single, ByVal B1I As Single, ByVal B2I As Single) As String
  Dim As Single B1O = B1I
  Dim As Single B2O = B2I
  Dim As Long PrintFlag = CallBetaEqui(A1, A2, Z1, Z2, D, B1P, B2P, B1O, B2O)
  Return M5_F32(A1) & " " & M5_F32(A2) & " " & M5_F32(Z1) & " " & M5_F32(Z2) & " " & M5_F32(D) & " " & M5_F32(B1P) & " " & M5_F32(B2P) & " " & M5_F32(B1I) & " " & M5_F32(B1O) & " " & M5_F32(B2I) & " " & M5_F32(B2O) & " " & M5_I64(PrintFlag)
End Function

Function LineBetaEquiReplay(ByVal A1 As Single, ByVal A2 As Single, ByVal Z1 As Single, ByVal Z2 As Single, ByVal D As Single, ByVal B1P As Single, ByVal B2P As Single, ByVal B1I As Single, ByVal B2I As Single, ByVal GF As LongInt) As String
  Dim As Single B1O = B1I
  Dim As Single B2O = B2I
  Dim As Long Ignored = CallBetaEqui(A1, A2, Z1, Z2, D, B1P, B2P, B1O, B2O)
  Return M5_F32(A1) & " " & M5_F32(A2) & " " & M5_F32(Z1) & " " & M5_F32(Z2) & " " & M5_F32(D) & " " & M5_F32(B1P) & " " & M5_F32(B2P) & " " & M5_F32(B1I) & " " & M5_F32(B1O) & " " & M5_F32(B2I) & " " & M5_F32(B2O) & " " & M5_I64(GF)
End Function

Sub GridGetyield()
  Dim As Long G
  Dim As Single EREFV(0 To 4) = {-2.33, 0.0, 2.5, 6.0, 12.6}
  Dim As Single TLOV(0 To 3) = {0.2436, 0.3, 0.3799, 0.25}
  Dim As Single THIV(0 To 3) = {0.4594, 0.5, 0.6525, 0.25}
  ' Grid loop order: E_rel = -20 + I/64 (2561 values), E_ref (5), (T_low, T_high) pair (4).
  ' Fixed: E_shell -5.0, dE_defo 0.5, T_high_mac 0.46, Imode 0.
  G = M5_OpenGrid("Getyield_grid.txt", "Getyield", S_GETYIELD)
  For I As Long = 0 To 2560
    For J As Long = 0 To 4
      For K As Long = 0 To 3
        Print #G, LineGetyield(M5_Axis(-20, 0.015625, I), EREFV(J), -5.0, 0.5, TLOV(K), THIV(K), 0.46, 0)
      Next
    Next
  Next
  Close #G
  ' Random draws in order: E_rel, E_ref, E_shell, dE_defo, T_low, T_high, T_high_mac, Imode.
  Randomize 6001, 3
  G = M5_OpenGrid("Getyield_random.txt", "Getyield", S_GETYIELD)
  For I As Long = 1 To N_RANDOM
    Dim As Single ERel = M5_Draw(-60, 20)
    Dim As Single ERef = M5_Draw(-3, 14)
    Dim As Single EShell = M5_Draw(-12, 1)
    Dim As Single DEDefo = M5_Draw(-9, 2)
    Dim As Single TLow = M5_Draw(0.2, 0.4)
    Dim As Single THigh = M5_Draw(0.4, 0.7)
    Dim As Single THighMac = M5_Draw(0.4, 0.5)
    Dim As Integer IMode = Int(M5_Draw(0, 23))
    Print #G, LineGetyield(ERel, ERef, EShell, DEDefo, TLow, THigh, THighMac, IMode)
  Next
  Close #G
End Sub

Sub GridF1()
  Dim As Long G
  ' Grid: Z_S_A = -5 + I/128, I = 0..25600.
  G = M5_OpenGrid("F1_grid.txt", "F1", S_F1)
  For I As Long = 0 To 25600
    Print #G, LineF1(M5_Axis(-5, 1.0 / 128.0, I))
  Next
  Close #G
  ' Random: Z_S_A in [-5, 200), seed 6002.
  Randomize 6002, 3
  G = M5_OpenGrid("F1_random.txt", "F1", S_F1)
  For I As Long = 1 To N_RANDOM
    Dim As Single ZSA = M5_Draw(-5, 200)
    Print #G, LineF1(ZSA)
  Next
  Close #G
End Sub

Sub GridF2()
  Dim As Long G
  ' Grid: Z_S_A = -5 + I/128, I = 0..25600.
  G = M5_OpenGrid("F2_grid.txt", "F2", S_F2)
  For I As Long = 0 To 25600
    Print #G, LineF2(M5_Axis(-5, 1.0 / 128.0, I))
  Next
  Close #G
  ' Random: Z_S_A in [-5, 200), seed 6003.
  Randomize 6003, 3
  G = M5_OpenGrid("F2_random.txt", "F2", S_F2)
  For I As Long = 1 To N_RANDOM
    Dim As Single ZSA = M5_Draw(-5, 200)
    Print #G, LineF2(ZSA)
  Next
  Close #G
End Sub

' Masscurv (Which 0), Masscurv1 (1), Masscurv2 (2): same schema and grids.
Sub GridMasscurv(ByVal Which As Long, ByVal FnName As String)
  Dim As Long G
  Dim As Single RLV(0 To 2) = {0, 3.5, 5.3}
  Dim As Single KV(0 To 1) = {0, 0.3}
  Dim As Single K4V(0 To 1) = {0, 0.05}
  Dim As Single EDV(0 To 2) = {0, 1, 2}
  ' Grid loop order: Z = 60 + J (51), A = 150 + I (101), RL (3), kappa (2), kappa4 (2);
  ' then edge rows Z in {0,1,2} x A in {0,1,2} with RL 3.5, kappa 0.3, kappa4 0.05.
  G = M5_OpenGrid(FnName & "_grid.txt", FnName, S_MASSCURV)
  For J As Long = 0 To 50
    For I As Long = 0 To 100
      For R As Long = 0 To 2
        For K As Long = 0 To 1
          For L As Long = 0 To 1
            Print #G, LineMasscurv(Which, M5_Axis(60, 1, J), M5_Axis(150, 1, I), RLV(R), KV(K), K4V(L))
          Next
        Next
      Next
    Next
  Next
  For J As Long = 0 To 2
    For I As Long = 0 To 2
      Print #G, LineMasscurv(Which, EDV(J), EDV(I), 3.5, 0.3, 0.05)
    Next
  Next
  Close #G
  ' Random draws in order: Z, A, RL, kappa, kappa4; seed 6004 + Which.
  Randomize 6004 + Which, 3
  G = M5_OpenGrid(FnName & "_random.txt", FnName, S_MASSCURV)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z = M5_Draw(1, 120)
    Dim As Single A = M5_Draw(1, 280)
    Dim As Single RL = M5_Draw(0, 8)
    Dim As Single Kappa = M5_Draw(-1, 1)
    Dim As Single Kappa4 = M5_Draw(-0.1, 0.1)
    Print #G, LineMasscurv(Which, Z, A, RL, Kappa, Kappa4)
  Next
  Close #G
End Sub

Sub GridDeSaddle()
  Dim As Long G
  Dim As Single ESV(0 To 7) = {-100, -90, -80, -67, -50, -30, 0, 10}
  ' Grid loop order: Z = 60 + J (61), A = 150 + I (111), ESHIFTSASCI list (8).
  G = M5_OpenGrid("De_Saddle_Scission_grid.txt", "De_Saddle_Scission", S_DE_SADDLE)
  For J As Long = 0 To 60
    For I As Long = 0 To 110
      For K As Long = 0 To 7
        Print #G, LineDeSaddle(M5_Axis(60, 1, J), M5_Axis(150, 1, I), ESV(K))
      Next
    Next
  Next
  Close #G
  ' Random draws in order: Z, A, E; seed 6007.
  Randomize 6007, 3
  G = M5_OpenGrid("De_Saddle_Scission_random.txt", "De_Saddle_Scission", S_DE_SADDLE)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z = M5_Draw(1, 120)
    Dim As Single A = M5_Draw(1, 260)
    Dim As Single E = M5_Draw(-120, 40)
    Print #G, LineDeSaddle(Z, A, E)
  Next
  Close #G
End Sub

' beta_light (Heavy 0) and beta_heavy (Heavy 1).
Sub GridBeta(ByVal Heavy As Long, ByVal FnName As String)
  Dim As Long G
  Dim As String SCH
  Dim As Single BKV(0 To 3) = {0.6127, 0.65, 0.6522, 0.7}
  If Heavy = 0 Then SCH = S_BETA_LIGHT Else SCH = S_BETA_HEAVY
  ' Grid loop order: Z = -2 + J (125 values, Integer), betaX0 = 10 + I/10 (201), betaX1 list (4).
  G = M5_OpenGrid(FnName & "_grid.txt", FnName, SCH)
  For J As Long = 0 To 124
    For I As Long = 0 To 200
      For K As Long = 0 To 3
        Print #G, LineBeta(Heavy, -2 + J, M5_Axis(10, 0.1, I), BKV(K))
      Next
    Next
  Next
  Close #G
  ' Random draws in order: Z (Integer 0..120), betaX0 in [10, 30), betaX1 in [0.5, 0.8); seed 6008 + Heavy.
  Randomize 6008 + Heavy, 3
  G = M5_OpenGrid(FnName & "_random.txt", FnName, SCH)
  For I As Long = 1 To N_RANDOM
    Dim As Integer Z = Int(M5_Draw(0, 121))
    Dim As Single B0 = M5_Draw(10, 30)
    Dim As Single B1 = M5_Draw(0.5, 0.8)
    Print #G, LineBeta(Heavy, Z, B0, B1)
  Next
  Close #G
End Sub

Sub GridZEqui()
  Dim As Long G
  Dim As Integer ZSV(0 To 4) = {20, 50, 80, 92, 110}
  Dim As Single PB1V(0 To 3) = {0, 0.3, 1.0, 1.9}
  Dim As Single PB2V(0 To 3) = {0, 0.6, 1.5, 0.2}
  Dim As Single DSV(0 To 2) = {0.5, 1.0, 2.0}
  ' Grid loop order: ZCN (5), A1 = 10 + 6*I (37), A2 = 10 + 6*J (37), beta pair (4), d (3); Imode 0.
  G = M5_OpenGrid("Z_equi_grid.txt", "Z_equi", S_Z_EQUI)
  For IZ As Long = 0 To 4
    For I As Long = 0 To 36
      For J As Long = 0 To 36
        For P As Long = 0 To 3
          For K As Long = 0 To 2
            Print #G, LineZEqui(ZSV(IZ), 10 + 6 * I, 10 + 6 * J, PB1V(P), PB2V(P), DSV(K), 0)
          Next
        Next
      Next
    Next
  Next
  Close #G
  ' Random draws in order: ZCN, A1, A2 (Integer), beta1 in [0, 2), beta2 in [0, 2), d in [0.5, 2),
  ' Imode (Integer 0..5); seed 6010.
  Randomize 6010, 3
  G = M5_OpenGrid("Z_equi_random.txt", "Z_equi", S_Z_EQUI)
  For I As Long = 1 To N_RANDOM
    Dim As Integer ZCN = Int(M5_Draw(1, 121))
    Dim As Integer A1 = Int(M5_Draw(1, 241))
    Dim As Integer A2 = Int(M5_Draw(1, 241))
    Dim As Single B1 = M5_Draw(0, 2)
    Dim As Single B2 = M5_Draw(0, 2)
    Dim As Single D = M5_Draw(0.5, 2)
    Dim As Integer IM = Int(M5_Draw(0, 6))
    Print #G, LineZEqui(ZCN, A1, A2, B1, B2, D, IM)
  Next
  Close #G
End Sub

Sub GridBetaEqui()
  Dim As Long G
  Dim As Single Z1V(0 To 8) = {10, 20, 30, 40, 46, 52, 62, 72, 82}
  Dim As Single A1V(0 To 5) = {25, 60, 100, 140, 180, 210}
  Dim As Single PB1V(0 To 2) = {0.3, 0.45, 0.584}
  Dim As Single PB2V(0 To 2) = {0.3, 0.5, 0.583}
  ' Grid loop order: Z1 (9; Z2 = 92 - Z1), A1 (6; A2 = 236 - A1), beta1prev (3), beta2prev (3),
  ' opt-in variant (2: 0 = opt-in equals prev values, 1 = opt-in (0, 0)); d = 1.0.
  G = M5_OpenGrid("Beta_Equi_grid.txt", "Beta_Equi", S_BETA_EQUI_GRID)
  For IZ As Long = 0 To 8
    For IA As Long = 0 To 5
      For IP As Long = 0 To 2
        For IQ As Long = 0 To 2
          For IV As Long = 0 To 1
            Dim As Single B1I, B2I
            If IV = 0 Then
              B1I = PB1V(IP)
              B2I = PB2V(IQ)
            Else
              B1I = 0
              B2I = 0
            End If
            Print #G, LineBetaEquiGrid(A1V(IA), 236 - A1V(IA), Z1V(IZ), 92 - Z1V(IZ), 1.0, PB1V(IP), PB2V(IQ), B1I, B2I)
          Next
        Next
      Next
    Next
  Next
  ' Edge rows, Z1 = Z2 = 46, A1 = A2 = 118, d = 1 (bit patterns found with the C++ port):
  ' (a) the start is the optimum of a converged search and opt-in (0.25, 0.75) differs from it:
  '     no improvement, so beta1opt/beta2opt keep their incoming values (D8);
  ' (b) beta1prev = 3eb70a3e and the beta2prev of EdgeP2 exit the N loop at N = 996 .. 1001,
  '     around the print condition N > 998 (GEF.bas:16628); opt-in = prev.
  Print #G, LineBetaEquiGrid(118, 118, 46, 46, 1.0, M5_ParseF32("3f0c28f6"), _
                             M5_ParseF32("3f0c6a7f"), 0.25, 0.75)
  Dim As String EdgeP2(0 To 5) = {"3e77ced8", "3e774bc6", "3e76c8b4", "3e7645a0", "3e75c28e", _
                                  "3e753f7c"}
  For IE As Long = 0 To 5
    Dim As Single B1P = M5_ParseF32("3eb70a3e")
    Dim As Single B2P = M5_ParseF32(EdgeP2(IE))
    Print #G, LineBetaEquiGrid(118, 118, 46, 46, 1.0, B1P, B2P, B1P, B2P)
  Next
  Close #G
  ' Random draws in order: A1 in [20, 215), A2 in [20, 215), Z1 and Z2 (Integer 8..84),
  ' d in [0.8, 1.2), beta1prev, beta2prev in [0.1, 0.9), beta1opt.in, beta2opt.in in [0, 1); seed 6011.
  Randomize 6011, 3
  G = M5_OpenGrid("Beta_Equi_random.txt", "Beta_Equi", S_BETA_EQUI_GRID)
  For I As Long = 1 To N_BETA_RANDOM
    Dim As Single A1 = M5_Draw(20, 215)
    Dim As Single A2 = M5_Draw(20, 215)
    Dim As Single Z1 = Int(M5_Draw(8, 85))
    Dim As Single Z2 = Int(M5_Draw(8, 85))
    Dim As Single D = M5_Draw(0.8, 1.2)
    Dim As Single B1P = M5_Draw(0.1, 0.9)
    Dim As Single B2P = M5_Draw(0.1, 0.9)
    Dim As Single B1I = M5_Draw(0, 1)
    Dim As Single B2I = M5_Draw(0, 1)
    Print #G, LineBetaEquiGrid(A1, A2, Z1, Z2, D, B1P, B2P, B1I, B2I)
  Next
  Close #G
End Sub

Sub Grids()
  GridGetyield()
  GridF1()
  GridF2()
  GridMasscurv(0, "Masscurv")
  GridMasscurv(1, "Masscurv1")
  GridMasscurv(2, "Masscurv2")
  GridDeSaddle()
  GridBeta(0, "beta_light")
  GridBeta(1, "beta_heavy")
  GridZEqui()
  GridBetaEqui()
End Sub

Sub ReplayMasscurv(ByRef Cdir As String, ByVal Which As Long, ByVal FnName As String)
  Dim As M5_Replay R
  Dim As String T()
  If M5_ReplayOpen(R, Cdir, FnName, S_MASSCURV) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineMasscurv(Which, M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2)), M5_ParseF32(T(3)), M5_ParseF32(T(4))))
    Wend
    M5_ReplayClose(R)
  End If
End Sub

Sub ReplayBeta(ByRef Cdir As String, ByVal Heavy As Long, ByVal FnName As String)
  Dim As M5_Replay R
  Dim As String T()
  Dim As String SCH
  If Heavy = 0 Then SCH = S_BETA_LIGHT Else SCH = S_BETA_HEAVY
  If M5_ReplayOpen(R, Cdir, FnName, SCH) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineBeta(Heavy, M5_ParseI64(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
End Sub

Sub Replay(ByRef Cdir As String)
  Dim As M5_Replay R
  Dim As String T()
  If M5_ReplayOpen(R, Cdir, "Getyield", S_GETYIELD) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineGetyield(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2)), M5_ParseF32(T(3)), M5_ParseF32(T(4)), M5_ParseF32(T(5)), M5_ParseF32(T(6)), M5_ParseI64(T(7))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "F1", S_F1) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineF1(M5_ParseF32(T(0))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "F2", S_F2) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineF2(M5_ParseF32(T(0))))
    Wend
    M5_ReplayClose(R)
  End If
  ReplayMasscurv(Cdir, 0, "Masscurv")
  ReplayMasscurv(Cdir, 1, "Masscurv1")
  ReplayMasscurv(Cdir, 2, "Masscurv2")
  If M5_ReplayOpen(R, Cdir, "De_Saddle_Scission", S_DE_SADDLE) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineDeSaddle(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
  ReplayBeta(Cdir, 0, "beta_light")
  ReplayBeta(Cdir, 1, "beta_heavy")
  If M5_ReplayOpen(R, Cdir, "Z_equi", S_Z_EQUI) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineZEqui(M5_ParseI64(T(0)), M5_ParseI64(T(1)), M5_ParseI64(T(2)), M5_ParseF32(T(3)), M5_ParseF32(T(4)), M5_ParseF32(T(5)), M5_ParseI64(T(6))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "Beta_Equi", S_BETA_EQUI) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineBetaEquiReplay(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2)), M5_ParseF32(T(3)), M5_ParseF32(T(4)), M5_ParseF32(T(5)), M5_ParseF32(T(6)), M5_ParseF32(T(7)), M5_ParseF32(T(9)), M5_ParseI64(T(11))))
    Wend
    M5_ReplayClose(R)
  End If
End Sub

f = FreeFile
Open "Beta_Equi_print.txt" For Output As #f
If Command(1) = "replay" Then
  Replay(Command(2))
ElseIf Command(1) = "" Then
  Grids()
Else
  Print "usage: m5_shape [replay <arglog dir>]"
  End 2
End If
Close #f
