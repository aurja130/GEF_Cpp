' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
' Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.
'
' M5 physics driver, group "masses" (MILESTONE_5_PLAN.md section 3): LyMass, LyPair, FEDEFOLys,
' LDMass, AME2020, U_SHELL, U_SHELL_exp, U_SHELL_EO_exp, U_MASS, ECOUL, U_Valid, U_Delta_S0 and
' U_Q_beta_minus, cut from GEF.bas (U_Q_beta_minus from DCLbranchingJEFF33.bas), with the mass
' tables BEldmTF, BEexp and ShellMO. Conventions: harness/drivers/M5_DRIVERS.md.
' Usage:
'   m5_masses                  grids: <fn>_grid.txt and <fn>_random.txt per function
'   m5_masses replay <dir>     replay/<fn>.txt for every <dir>/<fn>.txt arglog file

Declare Function LyMass(Z As Single,A As Single,beta As Single) As Single
Declare Function LyPair(Z As Integer,A As Integer) As Single
Declare Function FEDEFOLys(Z As Single,A As Single,beta As Single) As Single
Declare Function LDMass(Z As Single,A As Single,beta As Single) As Single
Declare Function AME2020(Z As Integer,A As Integer) As Single
Declare Function U_SHELL(Z As Integer,A As Integer) As Single
Declare Function U_SHELL_exp(Z As Integer, A As Integer) As Single
Declare Function U_SHELL_EO_exp(Z As Integer, A As Integer) As Single
Declare Function U_MASS(Z As Single,A As Single) As Single
Declare Function ECOUL(Z1 As Single,A1 As Single,beta1 As Single,Z2 As Single,A2 As Single, _
                  beta2 As Single,d As Single) As Single
Declare Function U_Valid(I_Z As Integer,I_A As Integer) As Ubyte
Declare Function U_Delta_S0(I_Z As Integer,I_A As Integer) As Single
Declare Function U_Q_beta_minus(IZ As Integer, IA As Integer) As Single

' Module constant used by LyMass, LDMass, FEDEFOLys and ECOUL (GEF.bas line 760).
Const As Single pi = 3.14159

' Mass tables: ReDim Shared in GEF.bas (lines 1222, 1233, 1255), filled by the table sources.
ReDim Shared BEldmTF(0 To 203,0 To 136) As Single
ReDim Shared BEexp(0 To 203,0 To 136) As Single
ReDim Shared ShellMO(0 To 203,0 To 136) As Single

'@include-source BEldmTF.bas
'@include-source BEexp.bas
'@include-source ShellMO.bas
'@cut GEF.bas:16110-16137 as ly_mass.bi
'@cut GEF.bas:16140-16151 as ly_pair.bi
'@cut GEF.bas:16211-16214 as fedefo_lys.bi
'@cut GEF.bas:16217-16236 as ld_mass.bi
'@cut GEF.bas:16238-16259 as ame2020.bi
'@cut GEF.bas:16261-16271 as u_shell.bi
'@cut GEF.bas:16273-16292 as u_shell_exp.bi
'@cut GEF.bas:16294-16306 as u_shell_eo_exp.bi
'@cut GEF.bas:16310-16323 as u_mass.bi
'@cut GEF.bas:16326-16355 as ecoul.bi
'@cut GEF.bas:15814-15832 as u_valid.bi
'@cut GEF.bas:15836-15859 as u_delta_s0.bi
'@cut DCLbranchingJEFF33.bas:112-115 as u_q_beta_minus.bi
'@include-driver m5_common.bi

#include "BEldmTF.bas"
#include "BEexp.bas"
#include "ShellMO.bas"
#include "ly_mass.bi"
#include "ly_pair.bi"
#include "fedefo_lys.bi"
#include "ld_mass.bi"
#include "ame2020.bi"
#include "u_shell.bi"
#include "u_shell_exp.bi"
#include "u_shell_eo_exp.bi"
#include "u_mass.bi"
#include "ecoul.bi"
#include "u_valid.bi"
#include "u_delta_s0.bi"
#include "u_q_beta_minus.bi"
#include "m5_common.bi"

Const S_LYMASS = "Z:f32 A:f32 beta:f32 result:f32"
Const S_LYPAIR = "Z:i64 A:i64 result:f32"
Const S_FEDEFOLYS = "Z:f32 A:f32 beta:f32 result:f32"
Const S_LDMASS = "Z:f32 A:f32 beta:f32 result:f32"
Const S_AME2020 = "Z:i64 A:i64 result:f32"
Const S_U_SHELL = "Z:i64 A:i64 result:f32"
Const S_U_SHELL_EXP = "Z:i64 A:i64 result:f32"
Const S_U_SHELL_EO_EXP = "Z:i64 A:i64 result:f32"
Const S_U_MASS = "Z:f32 A:f32 result:f32"
Const S_ECOUL = "Z1:f32 A1:f32 beta1:f32 Z2:f32 A2:f32 beta2:f32 d:f32 result:f32"
Const S_U_VALID = "I_Z:i64 I_A:i64 result:u8"
Const S_U_DELTA_S0 = "I_Z:i64 I_A:i64 result:f32"
Const S_U_Q_BETA_MINUS = "IZ:i64 IA:i64 result:f32"

Const N_RANDOM = 100000

' Integer draw of the driver: CLngInt(Int(M5_Draw(Lo, Hi + 0.5))), uniform on [Lo, Hi].
Function RandInt(ByVal Lo As Long, ByVal Hi As Long) As LongInt
  Return CLngInt(Int(M5_Draw(Lo, Hi + 0.5)))
End Function

Function LineLyMass(ByVal Z As Single, ByVal A As Single, ByVal B As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(B) & " " & M5_F32(LyMass(Z, A, B))
End Function

Function LineLyPair(ByVal Z As LongInt, ByVal A As LongInt) As String
  Return M5_I64(Z) & " " & M5_I64(A) & " " & M5_F32(LyPair(CInt(Z), CInt(A)))
End Function

Function LineFedefoLys(ByVal Z As Single, ByVal A As Single, ByVal B As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(B) & " " & M5_F32(FEDEFOLys(Z, A, B))
End Function

Function LineLdMass(ByVal Z As Single, ByVal A As Single, ByVal B As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(B) & " " & M5_F32(LDMass(Z, A, B))
End Function

Function LineAme2020(ByVal Z As LongInt, ByVal A As LongInt) As String
  Return M5_I64(Z) & " " & M5_I64(A) & " " & M5_F32(AME2020(CInt(Z), CInt(A)))
End Function

Function LineUShell(ByVal Z As LongInt, ByVal A As LongInt) As String
  Return M5_I64(Z) & " " & M5_I64(A) & " " & M5_F32(U_SHELL(CInt(Z), CInt(A)))
End Function

Function LineUShellExp(ByVal Z As LongInt, ByVal A As LongInt) As String
  Return M5_I64(Z) & " " & M5_I64(A) & " " & M5_F32(U_SHELL_exp(CInt(Z), CInt(A)))
End Function

Function LineUShellEoExp(ByVal Z As LongInt, ByVal A As LongInt) As String
  Return M5_I64(Z) & " " & M5_I64(A) & " " & M5_F32(U_SHELL_EO_exp(CInt(Z), CInt(A)))
End Function

Function LineUMass(ByVal Z As Single, ByVal A As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(U_MASS(Z, A))
End Function

Function LineEcoul(ByVal Z1 As Single, ByVal A1 As Single, ByVal B1 As Single, _
                   ByVal Z2 As Single, ByVal A2 As Single, ByVal B2 As Single, _
                   ByVal D As Single) As String
  Dim As String R = M5_F32(Z1) & " " & M5_F32(A1) & " " & M5_F32(B1)
  R &= " " & M5_F32(Z2) & " " & M5_F32(A2) & " " & M5_F32(B2)
  R &= " " & M5_F32(D) & " " & M5_F32(ECOUL(Z1, A1, B1, Z2, A2, B2, D))
  Return R
End Function

Function LineUValid(ByVal IZ As LongInt, ByVal IA As LongInt) As String
  Return M5_I64(IZ) & " " & M5_I64(IA) & " " & M5_U8(U_Valid(CInt(IZ), CInt(IA)))
End Function

Function LineUDeltaS0(ByVal IZ As LongInt, ByVal IA As LongInt) As String
  Return M5_I64(IZ) & " " & M5_I64(IA) & " " & M5_F32(U_Delta_S0(CInt(IZ), CInt(IA)))
End Function

Function LineUQBetaMinus(ByVal IZ As LongInt, ByVal IA As LongInt) As String
  Return M5_I64(IZ) & " " & M5_I64(IA) & " " & M5_F32(U_Q_beta_minus(CInt(IZ), CInt(IA)))
End Function

' Grid order is the golden contract: the outer loop is the first index, the inner loop the second.
' Integer grids: Z 1..120 (outer) x N 0..203 (inner), A = Z + N, unless noted.
' Random grids: Randomize <seed>, 3 before each, draws in the order written.

' LyMass, FEDEFOLys, LDMass: beta in {-0.5,-0.25,0,0.25,0.5,1,2} x Z 1..120 x N 0..203; then
' Z = 1 + 0.25 k (k 0..476) x N = 0.5 j (j 0..406), beta = 0.25; random Z, N, beta in
' [1,120), [0,203), [-0.5,2.5).
Sub GridLyMass()
  Dim As Single BetaList(0 To 6) = {-0.5, -0.25, 0, 0.25, 0.5, 1, 2}
  Dim As Long F = M5_OpenGrid("LyMass_grid.txt", "LyMass", S_LYMASS)
  For K As Long = 0 To 6
    For Zi As Long = 1 To 120
      For Ni As Long = 0 To 203
        Print #F, LineLyMass(CSng(Zi), CSng(Zi + Ni), BetaList(K))
      Next
    Next
  Next
  For K As Long = 0 To 476
    For J As Long = 0 To 406
      Dim As Single Z = M5_Axis(1, 0.25, K)
      Dim As Single N = M5_Axis(0, 0.5, J)
      Print #F, LineLyMass(Z, Z + N, 0.25)
    Next
  Next
  Close #F
  Randomize 6009, 3
  F = M5_OpenGrid("LyMass_random.txt", "LyMass", S_LYMASS)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z = M5_Draw(1, 120)
    Dim As Single N = M5_Draw(0, 203)
    Dim As Single B = M5_Draw(-0.5, 2.5)
    Print #F, LineLyMass(Z, Z + N, B)
  Next
  Close #F
End Sub

Sub GridLyPair()
  Dim As Long F = M5_OpenGrid("LyPair_grid.txt", "LyPair", S_LYPAIR)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 203
      Print #F, LineLyPair(Zi, Zi + Ni)
    Next
  Next
  Close #F
  Randomize 6002, 3
  F = M5_OpenGrid("LyPair_random.txt", "LyPair", S_LYPAIR)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt Z = RandInt(10, 107)
    Dim As LongInt A = RandInt(20, 265)
    Print #F, LineLyPair(Z, A)
  Next
  Close #F
End Sub

Sub GridFedefoLys()
  Dim As Single BetaList(0 To 6) = {-0.5, -0.25, 0, 0.25, 0.5, 1, 2}
  Dim As Long F = M5_OpenGrid("FEDEFOLys_grid.txt", "FEDEFOLys", S_FEDEFOLYS)
  For K As Long = 0 To 6
    For Zi As Long = 1 To 120
      For Ni As Long = 0 To 203
        Print #F, LineFedefoLys(CSng(Zi), CSng(Zi + Ni), BetaList(K))
      Next
    Next
  Next
  For K As Long = 0 To 476
    For J As Long = 0 To 406
      Dim As Single Z = M5_Axis(1, 0.25, K)
      Dim As Single N = M5_Axis(0, 0.5, J)
      Print #F, LineFedefoLys(Z, Z + N, 0.25)
    Next
  Next
  Close #F
  Randomize 6010, 3
  F = M5_OpenGrid("FEDEFOLys_random.txt", "FEDEFOLys", S_FEDEFOLYS)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z = M5_Draw(1, 120)
    Dim As Single N = M5_Draw(0, 203)
    Dim As Single B = M5_Draw(-0.5, 2.5)
    Print #F, LineFedefoLys(Z, Z + N, B)
  Next
  Close #F
End Sub

Sub GridLdMass()
  Dim As Single BetaList(0 To 6) = {-0.5, -0.25, 0, 0.25, 0.5, 1, 2}
  Dim As Long F = M5_OpenGrid("LDMass_grid.txt", "LDMass", S_LDMASS)
  For K As Long = 0 To 6
    For Zi As Long = 1 To 120
      For Ni As Long = 0 To 203
        Print #F, LineLdMass(CSng(Zi), CSng(Zi + Ni), BetaList(K))
      Next
    Next
  Next
  For K As Long = 0 To 476
    For J As Long = 0 To 406
      Dim As Single Z = M5_Axis(1, 0.25, K)
      Dim As Single N = M5_Axis(0, 0.5, J)
      Print #F, LineLdMass(Z, Z + N, 0.25)
    Next
  Next
  Close #F
  Randomize 6011, 3
  F = M5_OpenGrid("LDMass_random.txt", "LDMass", S_LDMASS)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z = M5_Draw(1, 120)
    Dim As Single N = M5_Draw(0, 203)
    Dim As Single B = M5_Draw(-0.5, 2.5)
    Print #F, LineLdMass(Z, Z + N, B)
  Next
  Close #F
End Sub

Sub GridAme2020()
  Dim As Long F = M5_OpenGrid("AME2020_grid.txt", "AME2020", S_AME2020)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 203
      Print #F, LineAme2020(Zi, Zi + Ni)
    Next
  Next
  Close #F
  Randomize 6001, 3
  F = M5_OpenGrid("AME2020_random.txt", "AME2020", S_AME2020)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt Z = RandInt(30, 107)
    Dim As LongInt N = RandInt(0, 203)
    Print #F, LineAme2020(Z, Z + N)
  Next
  Close #F
End Sub

Sub GridUShell()
  Dim As Long F = M5_OpenGrid("U_SHELL_grid.txt", "U_SHELL", S_U_SHELL)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 203
      Print #F, LineUShell(Zi, Zi + Ni)
    Next
  Next
  Close #F
  Randomize 6003, 3
  F = M5_OpenGrid("U_SHELL_random.txt", "U_SHELL", S_U_SHELL)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt Z = RandInt(10, 106)
    Dim As LongInt N = RandInt(0, 203)
    Print #F, LineUShell(Z, Z + N)
  Next
  Close #F
End Sub

' U_SHELL_exp: grid N 1..202; random Z in [91,106], N in [127,173].
Sub GridUShellExp()
  Dim As Long F = M5_OpenGrid("U_SHELL_exp_grid.txt", "U_SHELL_exp", S_U_SHELL_EXP)
  For Zi As Long = 1 To 120
    For Ni As Long = 1 To 202
      Print #F, LineUShellExp(Zi, Zi + Ni)
    Next
  Next
  Close #F
  Randomize 6005, 3
  F = M5_OpenGrid("U_SHELL_exp_random.txt", "U_SHELL_exp", S_U_SHELL_EXP)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt Z = RandInt(91, 106)
    Dim As LongInt N = RandInt(127, 173)
    Print #F, LineUShellExp(Z, Z + N)
  Next
  Close #F
End Sub

Sub GridUShellEoExp()
  Dim As Long F = M5_OpenGrid("U_SHELL_EO_exp_grid.txt", "U_SHELL_EO_exp", S_U_SHELL_EO_EXP)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 203
      Print #F, LineUShellEoExp(Zi, Zi + Ni)
    Next
  Next
  Close #F
  Randomize 6004, 3
  F = M5_OpenGrid("U_SHELL_EO_exp_random.txt", "U_SHELL_EO_exp", S_U_SHELL_EO_EXP)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt Z = RandInt(91, 106)
    Dim As LongInt N = RandInt(127, 173)
    Print #F, LineUShellEoExp(Z, Z + N)
  Next
  Close #F
End Sub

' U_MASS: quarter grid Z = 1 + 0.25 k (k 0..476) x N = 0.25 j (j 0..811), A = Z + N, then the
' integer grid Z 1..120 x N 0..203 (both as Single); random Z in [29,93), N in [0,203).
Sub GridUMass()
  Dim As Long F = M5_OpenGrid("U_MASS_grid.txt", "U_MASS", S_U_MASS)
  For K As Long = 0 To 476
    For J As Long = 0 To 811
      Dim As Single Z = M5_Axis(1, 0.25, K)
      Dim As Single N = M5_Axis(0, 0.25, J)
      Print #F, LineUMass(Z, Z + N)
    Next
  Next
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 203
      Print #F, LineUMass(CSng(Zi), CSng(Zi + Ni))
    Next
  Next
  Close #F
  Randomize 6012, 3
  F = M5_OpenGrid("U_MASS_random.txt", "U_MASS", S_U_MASS)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z = M5_Draw(29, 93)
    Dim As Single N = M5_Draw(0, 203)
    Print #F, LineUMass(Z, Z + N)
  Next
  Close #F
End Sub

' ECOUL: G1 Z1,A1 = (Z, Z+N) over Z 1..120 x N 0..203 with fragment 2 = (50,120); G2 the mirror
' with fragment 1 = (50,120); G3 beta1 x beta2 (7x7) x d in {-1,0,0.5,1,2,5,10,20} with both
' fragments (50,120); all with beta = 0 and d = 1 except G3. Random: draws Z1, N1, beta1, Z2, N2,
' beta2, d, with Z in [2.5,105), N in [5,150), beta in [-0.2,2.4), d in [0,10).
Sub GridEcoul()
  Dim As Single BetaList(0 To 6) = {-0.5, -0.25, 0, 0.25, 0.5, 1, 2}
  Dim As Single DList(0 To 7) = {-1, 0, 0.5, 1, 2, 5, 10, 20}
  Dim As Long F = M5_OpenGrid("ECOUL_grid.txt", "ECOUL", S_ECOUL)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 203
      Print #F, LineEcoul(CSng(Zi), CSng(Zi + Ni), 0, 50, 120, 0, 1)
    Next
  Next
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 203
      Print #F, LineEcoul(50, 120, 0, CSng(Zi), CSng(Zi + Ni), 0, 1)
    Next
  Next
  For IB1 As Long = 0 To 6
    For IB2 As Long = 0 To 6
      For ID As Long = 0 To 7
        Print #F, LineEcoul(50, 120, BetaList(IB1), 50, 120, BetaList(IB2), DList(ID))
      Next
    Next
  Next
  Close #F
  Randomize 6013, 3
  F = M5_OpenGrid("ECOUL_random.txt", "ECOUL", S_ECOUL)
  For I As Long = 1 To N_RANDOM
    Dim As Single Z1 = M5_Draw(2.5, 105)
    Dim As Single N1 = M5_Draw(5, 150)
    Dim As Single B1 = M5_Draw(-0.2, 2.4)
    Dim As Single Z2 = M5_Draw(2.5, 105)
    Dim As Single N2 = M5_Draw(5, 150)
    Dim As Single B2 = M5_Draw(-0.2, 2.4)
    Dim As Single D = M5_Draw(0, 10)
    Print #F, LineEcoul(Z1, Z1 + N1, B1, Z2, Z2 + N2, B2, D)
  Next
  Close #F
End Sub

' U_Valid: grid I_Z 0..136 x N 1..203, I_A = I_Z + N; random I_Z in [0,136], N in [1,203].
Sub GridUValid()
  Dim As Long F = M5_OpenGrid("U_Valid_grid.txt", "U_Valid", S_U_VALID)
  For Zi As Long = 0 To 136
    For Ni As Long = 1 To 203
      Print #F, LineUValid(Zi, Zi + Ni)
    Next
  Next
  Close #F
  Randomize 6007, 3
  F = M5_OpenGrid("U_Valid_random.txt", "U_Valid", S_U_VALID)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt IZ = RandInt(0, 136)
    Dim As LongInt N = RandInt(1, 203)
    Print #F, LineUValid(IZ, IZ + N)
  Next
  Close #F
End Sub

' U_Delta_S0: grid I_Z 1..120 x I_A = I_Z + N, N 0..203; random I_Z in [1,120], I_A in [1,300].
Sub GridUDeltaS0()
  Dim As Long F = M5_OpenGrid("U_Delta_S0_grid.txt", "U_Delta_S0", S_U_DELTA_S0)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 203
      Print #F, LineUDeltaS0(Zi, Zi + Ni)
    Next
  Next
  Close #F
  Randomize 6008, 3
  F = M5_OpenGrid("U_Delta_S0_random.txt", "U_Delta_S0", S_U_DELTA_S0)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt IZ = RandInt(1, 120)
    Dim As LongInt IA = RandInt(1, 300)
    Print #F, LineUDeltaS0(IZ, IA)
  Next
  Close #F
End Sub

' U_Q_beta_minus: grid IZ 1..120 x N 1..203, IA = IZ + N; random IZ in [25,74], N in [1,203].
Sub GridUQBetaMinus()
  Dim As Long F = M5_OpenGrid("U_Q_beta_minus_grid.txt", "U_Q_beta_minus", S_U_Q_BETA_MINUS)
  For IZ As Long = 1 To 120
    For N As Long = 1 To 203
      Print #F, LineUQBetaMinus(IZ, IZ + N)
    Next
  Next
  Close #F
  Randomize 6006, 3
  F = M5_OpenGrid("U_Q_beta_minus_random.txt", "U_Q_beta_minus", S_U_Q_BETA_MINUS)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt IZ = RandInt(25, 74)
    Dim As LongInt N = RandInt(1, 203)
    Print #F, LineUQBetaMinus(IZ, IZ + N)
  Next
  Close #F
End Sub

Sub Grids()
  GridLyMass()
  GridLyPair()
  GridFedefoLys()
  GridLdMass()
  GridAme2020()
  GridUShell()
  GridUShellExp()
  GridUShellEoExp()
  GridUMass()
  GridEcoul()
  GridUValid()
  GridUDeltaS0()
  GridUQBetaMinus()
End Sub

Sub Replay(ByRef Cdir As String)
  Dim As M5_Replay R
  Dim As String T()
  If M5_ReplayOpen(R, Cdir, "LyMass", S_LYMASS) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineLyMass(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "LyPair", S_LYPAIR) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineLyPair(M5_ParseI64(T(0)), M5_ParseI64(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "FEDEFOLys", S_FEDEFOLYS) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineFedefoLys(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "LDMass", S_LDMASS) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineLdMass(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "AME2020", S_AME2020) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineAme2020(M5_ParseI64(T(0)), M5_ParseI64(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "U_SHELL", S_U_SHELL) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineUShell(M5_ParseI64(T(0)), M5_ParseI64(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "U_SHELL_exp", S_U_SHELL_EXP) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineUShellExp(M5_ParseI64(T(0)), M5_ParseI64(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "U_SHELL_EO_exp", S_U_SHELL_EO_EXP) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineUShellEoExp(M5_ParseI64(T(0)), M5_ParseI64(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "U_MASS", S_U_MASS) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineUMass(M5_ParseF32(T(0)), M5_ParseF32(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "ECOUL", S_ECOUL) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineEcoul(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2)), _
                                  M5_ParseF32(T(3)), M5_ParseF32(T(4)), M5_ParseF32(T(5)), _
                                  M5_ParseF32(T(6))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "U_Valid", S_U_VALID) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineUValid(M5_ParseI64(T(0)), M5_ParseI64(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "U_Q_beta_minus", S_U_Q_BETA_MINUS) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineUQBetaMinus(M5_ParseI64(T(0)), M5_ParseI64(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
End Sub

If Command(1) = "replay" Then
  Replay(Command(2))
ElseIf Command(1) = "" Then
  Grids()
Else
  Print "usage: m5_masses [replay <arglog dir>]"
  End 2
End If
