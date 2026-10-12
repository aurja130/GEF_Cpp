' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
' Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.
'
' M5 physics driver, group "level_density" (MILESTONE_5_PLAN.md section 3): U_alev_ld, U_levdens,
' U_levdens_Egidy, U_levdens_FG, U_Temp, U_Temp2, TEgidy, TRusanov, cut from GEF.bas. The tables
' BEldmTF, BEexp and ShellMO are filled from their GEF source files. Conventions:
' harness/drivers/M5_DRIVERS.md.
' Usage:
'   m5_level_density                 grids: <fn>_grid.txt and <fn>_random.txt per function
'   m5_level_density replay <dir>    replay/<fn>.txt for every <dir>/<fn>.txt arglog file

Declare Function TEgidy(A As Single,DU As Single,Fred As Single) As Single
Declare Function TRusanov(E As Single, A As Single) As Single
Declare Function LyMass(Z As Single,A As Single,beta As Single) As Single
Declare Function LyPair(Z As Integer,A As Integer) As Single
Declare Function FEDEFOLys(Z As Single,A As Single,beta As Single) As Single
Declare Function LDMass(Z As Single,A As Single,beta As Single) As Single
Declare Function AME2020(Z As Integer,A As Integer) As Single
Declare Function U_SHELL(Z As Integer,A As Integer) As Single
Declare Function U_SHELL_exp(Z As Integer, A As Integer) As Single
Declare Function U_SHELL_EO_exp(Z As Integer, A As Integer) As Single
Declare Function U_alev_ld(Z As Single, A As Single) As Single
Declare Function U_Temp(Z As Single, A As Single, E As Single, Ishell As Integer, _
           Ipair As Integer, Tscale As Single,Econd As Single, Etrans As Single) As Single
Declare Function U_levdens_Egidy(Z As Integer, A As Integer, E As Single, Ishell As Integer, _
           Ipair As Integer, Tscale As Single, Econd As Single, Etrans As Single, af_an As Single) As Double
Declare Function U_levdens_FG(Z As Integer, A As Integer, E As Single, Ishell As Integer, _
           Ipair As Integer, Tscale As Single, Econd As Single, Etrans As Single, af_an As Single) As Double
Declare Function U_levdens(Z As Integer, A As Integer, E As Single, Ishell As Integer, _
           Ipair As Integer, Tscale As Single, Econd As Single, Etrans As Single, af_an As Single) As Double
Declare Function U_Temp2(Z As Single, A As Single, E As Single, Rshell As Single, _
           Rpair As Single, Tscale As Single,Econd As Single,Etrans As Single) As Single

Const As Single pi = 3.14159

ReDim Shared BEldmTF(0 To 203,0 To 136) As Single
ReDim Shared BEexp(0 To 203,0 To 136) As Single
ReDim Shared ShellMO(0 To 203,0 To 136) As Single

Const S_ALEV = "Z:f32 A:f32 result:f32"
Const S_LEVDENS = "Z:i64 A:i64 E:f32 Ishell:i64 Ipair:i64 Tscale:f32 Econd:f32 Etrans:f32 af_an:f32 result:f64"
Const S_TEMP = "Z:f32 A:f32 E:f32 Ishell:i64 Ipair:i64 Tscale:f32 Econd:f32 Etrans:f32 result:f32"
Const S_TEMP2 = "Z:f32 A:f32 E:f32 Rshell:f32 Rpair:f32 Tscale:f32 Econd:f32 Etrans:f32 result:f32"
Const S_TEGIDY = "A:f32 DU:f32 Fred:f32 result:f32"
Const S_TRUSANOV = "E:f32 A:f32 result:f32"

Const N_RANDOM = 100000

Dim Shared EAx(0 To 2014) As Single
Dim Shared E3(0 To 2) As Single

'@include-source BEldmTF.bas
'@include-source BEexp.bas
'@include-source ShellMO.bas
'@cut GEF.bas:16072-16095 as gef_tegidy.bi
'@cut GEF.bas:16098-16108 as gef_trusanov.bi
'@cut GEF.bas:16110-16137 as gef_lymass.bi
'@cut GEF.bas:16140-16151 as gef_lypair.bi
'@cut GEF.bas:16211-16214 as gef_fedefolys.bi
'@cut GEF.bas:16217-16236 as gef_ldmass.bi
'@cut GEF.bas:16238-16259 as gef_ame2020.bi
'@cut GEF.bas:16261-16271 as gef_u_shell.bi
'@cut GEF.bas:16273-16292 as gef_u_shell_exp.bi
'@cut GEF.bas:16294-16306 as gef_u_shell_eo_exp.bi
'@cut GEF.bas:17173-17177 as gef_u_alev_ld.bi
'@cut GEF.bas:17205-17223 as gef_u_levdens.bi
'@cut GEF.bas:17225-17259 as gef_u_levdens_egidy.bi
'@cut GEF.bas:17261-17331 as gef_u_levdens_fg.bi
'@cut GEF.bas:17335-17385 as gef_u_temp.bi
'@cut GEF.bas:17388-17420 as gef_u_temp2.bi
'@include-driver m5_common.bi

#include "BEldmTF.bas"
#include "BEexp.bas"
#include "ShellMO.bas"
#include "gef_tegidy.bi"
#include "gef_trusanov.bi"
#include "gef_lymass.bi"
#include "gef_lypair.bi"
#include "gef_fedefolys.bi"
#include "gef_ldmass.bi"
#include "gef_ame2020.bi"
#include "gef_u_shell.bi"
#include "gef_u_shell_exp.bi"
#include "gef_u_shell_eo_exp.bi"
#include "gef_u_alev_ld.bi"
#include "gef_u_levdens.bi"
#include "gef_u_levdens_egidy.bi"
#include "gef_u_levdens_fg.bi"
#include "gef_u_temp.bi"
#include "gef_u_temp2.bi"
#include "m5_common.bi"

' Bit pattern to Single (exact specials: NaN, Inf, subnormal).
Function F32Bits(ByVal B As ULong) As Single
  Return *Cast(Single Ptr, @B)
End Function

' Integer drawn from [Lo, Hi): floor of one M5_Draw (one Rnd per draw).
Function LdDrawI(ByVal Lo As Double, ByVal Hi As Double) As LongInt
  Return CLngInt(Int(M5_Draw(Lo, Hi)))
End Function

Function LdName(ByVal Which As Long) As String
  Select Case Which
    Case 0
      Return "U_levdens"
    Case 1
      Return "U_levdens_Egidy"
    Case Else
      Return "U_levdens_FG"
  End Select
End Function

Function LineAlev(ByVal Z As Single, ByVal A As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(U_alev_ld(Z, A))
End Function

Function LdCall(ByVal Which As Long, ByVal Z As Integer, ByVal A As Integer, ByVal E As Single, _
                ByVal Ishell As Integer, ByVal Ipair As Integer, ByVal Tscale As Single, _
                ByVal Econd As Single, ByVal Etrans As Single, ByVal Af As Single) As Double
  Select Case Which
    Case 0
      Return U_levdens(Z, A, E, Ishell, Ipair, Tscale, Econd, Etrans, Af)
    Case 1
      Return U_levdens_Egidy(Z, A, E, Ishell, Ipair, Tscale, Econd, Etrans, Af)
    Case Else
      Return U_levdens_FG(Z, A, E, Ishell, Ipair, Tscale, Econd, Etrans, Af)
  End Select
End Function

Function LineLD(ByVal Which As Long, ByVal Z As Integer, ByVal A As Integer, ByVal E As Single, _
                ByVal Ishell As Integer, ByVal Ipair As Integer, ByVal Tscale As Single, _
                ByVal Econd As Single, ByVal Etrans As Single, ByVal Af As Single) As String
  Return M5_I64(Z) & " " & M5_I64(A) & " " & M5_F32(E) & " " & M5_I64(Ishell) & " " & _
         M5_I64(Ipair) & " " & M5_F32(Tscale) & " " & M5_F32(Econd) & " " & M5_F32(Etrans) & " " & _
         M5_F32(Af) & " " & M5_F64(LdCall(Which, Z, A, E, Ishell, Ipair, Tscale, Econd, Etrans, Af))
End Function

Function LineTemp(ByVal Z As Single, ByVal A As Single, ByVal E As Single, ByVal Ishell As Integer, _
                  ByVal Ipair As Integer, ByVal Tscale As Single, ByVal Econd As Single, _
                  ByVal Etrans As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(E) & " " & M5_I64(Ishell) & " " & _
         M5_I64(Ipair) & " " & M5_F32(Tscale) & " " & M5_F32(Econd) & " " & M5_F32(Etrans) & " " & _
         M5_F32(U_Temp(Z, A, E, Ishell, Ipair, Tscale, Econd, Etrans))
End Function

Function LineTemp2(ByVal Z As Single, ByVal A As Single, ByVal E As Single, ByVal Rshell As Single, _
                   ByVal Rpair As Single, ByVal Tscale As Single, ByVal Econd As Single, _
                   ByVal Etrans As Single) As String
  Return M5_F32(Z) & " " & M5_F32(A) & " " & M5_F32(E) & " " & M5_F32(Rshell) & " " & _
         M5_F32(Rpair) & " " & M5_F32(Tscale) & " " & M5_F32(Econd) & " " & M5_F32(Etrans) & " " & _
         M5_F32(U_Temp2(Z, A, E, Rshell, Rpair, Tscale, Econd, Etrans))
End Function

Function LineTEgidy(ByVal A As Single, ByVal Du As Single, ByVal Fr As Single) As String
  Return M5_F32(A) & " " & M5_F32(Du) & " " & M5_F32(Fr) & " " & M5_F32(TEgidy(A, Du, Fr))
End Function

Function LineTRusanov(ByVal E As Single, ByVal A As Single) As String
  Return M5_F32(E) & " " & M5_F32(A) & " " & M5_F32(TRusanov(E, A))
End Function

' Energy axis EAx(0 To 2014) (Single), shared by the sweeps below; FillE fills it and E3:
'   EAx(0..1099)    = M5_Axis(-1, 0.01, K)        -1 .. 9.99
'   EAx(1100..2000) = M5_Axis(10, 0.1, K - 1100)   10 .. 100
'   EAx(2001..2014) = the -1 and +1 ULP neighbours of 0.0, 0.5, 2.0, 2.5, 4.0, 4.5 and 9.5
'   E3(0..2)        = {-1, 9.5, 100}, the energies of the Z,N sweeps (GridLD block 1).
Sub FillE()
  For K As Long = 0 To 2000
    If K < 1100 Then
      EAx(K) = M5_Axis(-1, 0.01, K)
    Else
      EAx(K) = M5_Axis(10, 0.1, K - 1100)
    End If
  Next
  EAx(2001) = F32Bits(&h80000001UL)
  EAx(2002) = F32Bits(&h00000001UL)
  EAx(2003) = F32Bits(&h3EFFFFFFUL)
  EAx(2004) = F32Bits(&h3F000001UL)
  EAx(2005) = F32Bits(&h3FFFFFFFUL)
  EAx(2006) = F32Bits(&h40000001UL)
  EAx(2007) = F32Bits(&h401FFFFFUL)
  EAx(2008) = F32Bits(&h40200001UL)
  EAx(2009) = F32Bits(&h407FFFFFUL)
  EAx(2010) = F32Bits(&h40800001UL)
  EAx(2011) = F32Bits(&h408FFFFFUL)
  EAx(2012) = F32Bits(&h40900001UL)
  EAx(2013) = F32Bits(&h4117FFFFUL)
  EAx(2014) = F32Bits(&h41180001UL)
  E3(0) = -1
  E3(1) = 9.5!
  E3(2) = 100
End Sub

' U_alev_ld (GEF.bas:17173-17177; Z unused). Grid: Z = 1..120 (outer), J = 0..812 (inner),
' A = M5_Axis(Z, 0.25, J) = Z .. Z+203; then the specials Sp(0..4) for Z in {10, 92}
' (Zs outer, Sp inner). Random (Randomize 5101): Z = M5_Draw(0,300), then A = M5_Draw(0,300).
Sub GridAlev()
  Dim As ULong Sp(0 To 4) = {&h3F000000, &h0D800000, &h71800000, &h7F7FFFFF, &h7FC00000}
  Dim As Single Zs(0 To 1) = {10, 92}
  Dim As String Gf = "U_alev_ld_grid.txt"
  Dim As Long F = M5_OpenGrid(Gf, "U_alev_ld", S_ALEV)
  For Z As Long = 1 To 120
    For J As Long = 0 To 812
      Print #F, LineAlev(Z, M5_Axis(Z, 0.25, J))
    Next
  Next
  For Iz As Long = 0 To 1
    For K As Long = 0 To 4
      Print #F, LineAlev(Zs(Iz), F32Bits(Sp(K)))
    Next
  Next
  Close #F
  Randomize 5101, 3
  Dim As String Rf = "U_alev_ld_random.txt"
  F = M5_OpenGrid(Rf, "U_alev_ld", S_ALEV)
  For I As Long = 1 To N_RANDOM
    Dim As Single Zr = M5_Draw(0, 300)
    Dim As Single Ar = M5_Draw(0, 300)
    Print #F, LineAlev(Zr, Ar)
  Next
  Close #F
End Sub

' LD sweep over EAx at one (Z, A) point with the other parameters given (inner loop of
' GridLD blocks 2 and 4). LineLD(Which, Z, A, E, Ishell, Ipair, Tscale, Econd, Etrans, Af).
Sub LdSweepE(ByVal F As Long, ByVal Which As Long, ByVal Z As Long, ByVal A As Long, ByVal Ish As Long, ByVal Ipr As Long, ByVal Ts As Single, ByVal Co As Single, ByVal Et As Single, ByVal Af As Single)
  For K As Long = 0 To 2014
    Print #F, LineLD(Which, Z, A, EAx(K), Ish, Ipr, Ts, Co, Et, Af)
  Next
End Sub

' GridLD(Which, Sd): the three level-density functions (Which: 0 U_levdens, 1 U_levdens_Egidy,
' 2 U_levdens_FG). Grid blocks, outer loop first:
'  1  Z = 1..120, N = 1..202 (A = Z + N), E in E3; Ishell 1, Ipair 0, Tscale 1.0, Econd 2.0,
'     Etrans 9.5, af_an 1.0. N = 1..202 keeps the U_SHELL_exp stencil inside the tables.
'  2  A in {233, 236} (outer), Z in {91, 92, 93}, Ishell 0..1, Ipair 0..2, E = EAx(0..2014)
'     (inner); Tscale 1.0, Econd 2.0, Etrans 9.5, af_an 1.0.
'  3  Z in {92, 93} (outer), A = 236, E in {-1, 1, 9, 9.5, 10, 16, 0, NaN, +Inf}, Ishell 0..1,
'     Ipair 0..2, Tscale {1.0, 0.5}, Econd {0, 2, 4}, Etrans {9.5, 4.0}, af_an {1.0, 0.75, 1.25}
'     (inner).
'  4  (Z, A) = (92, 236), E = EAx(0..2014), one parameter changed from the base (Ishell 0, Ipair 0,
'     Tscale 1.0, Econd 2.0, Etrans 9.5, af_an 1.0), in this order: Ishell 1; Ipair 1; Ipair 2;
'     Tscale 0.5; Econd 0; Econd 4; Etrans 4.0; Etrans 0.0; af_an 0.75; af_an 1.25.
' Random (own file, Randomize Sd): Z = floor(M5_Draw(88,97)), A = floor(M5_Draw(226,241)),
'     E in [-10,25), Ishell = floor(M5_Draw(0,2)), Ipair = floor(M5_Draw(0,3)), Tscale in
'     [0.5,1.5), Econd in [0,4), Etrans in [0,15), af_an in [0.9,1.1). Draw order: Z, A, E,
'     Ishell, Ipair, Tscale, Econd, Etrans, af_an.
Sub GridLD(ByVal Which As Long, ByVal Sd As Long)
  Dim As String Fn = LdName(Which)
  Dim As Single Ev(0 To 8) = {-1, 1, 9, 9.5!, 10, 16, 0, 0, 0}
  Ev(7) = F32Bits(&h7FC00000)
  Ev(8) = F32Bits(&h7F800000)
  Dim As Single Tsv(0 To 1) = {1.0!, 0.5!}
  Dim As Single Cov(0 To 2) = {0.0!, 2.0!, 4.0!}
  Dim As Single Etv(0 To 1) = {9.5!, 4.0!}
  Dim As Single Afv(0 To 2) = {1.0!, 0.75!, 1.25!}
  Dim As Long Zs(0 To 2) = {91, 92, 93}
  Dim As Long Ais(0 To 1) = {233, 236}
  Dim As String Gf = Fn & "_grid.txt"
  Dim As Long F = M5_OpenGrid(Gf, Fn, S_LEVDENS)
  For Zi As Long = 1 To 120
    For Ni As Long = 1 To 202
      For Ie As Long = 0 To 2
        Print #F, LineLD(Which, Zi, Zi + Ni, E3(Ie), 1, 0, 1.0!, 2.0!, 9.5!, 1.0!)
      Next
    Next
  Next
  For Ia As Long = 0 To 1
    For Iz As Long = 0 To 2
      For Ish As Long = 0 To 1
        For Ipr As Long = 0 To 2
          LdSweepE(F, Which, Zs(Iz), Ais(Ia), Ish, Ipr, 1.0!, 2.0!, 9.5!, 1.0!)
        Next
      Next
    Next
  Next
  For Iz As Long = 0 To 1
    For Ie As Long = 0 To 8
      For Ish As Long = 0 To 1
        For Ipr As Long = 0 To 2
          For Its As Long = 0 To 1
            For Ico As Long = 0 To 2
              For Iet As Long = 0 To 1
                For Iaf As Long = 0 To 2
                  Print #F, LineLD(Which, 92 + Iz, 236, Ev(Ie), Ish, Ipr, Tsv(Its), Cov(Ico), Etv(Iet), Afv(Iaf))
                Next
              Next
            Next
          Next
        Next
      Next
    Next
  Next
  LdSweepE(F, Which, 92, 236, 1, 0, 1.0!, 2.0!, 9.5!, 1.0!)
  LdSweepE(F, Which, 92, 236, 0, 1, 1.0!, 2.0!, 9.5!, 1.0!)
  LdSweepE(F, Which, 92, 236, 0, 2, 1.0!, 2.0!, 9.5!, 1.0!)
  LdSweepE(F, Which, 92, 236, 0, 0, 0.5!, 2.0!, 9.5!, 1.0!)
  LdSweepE(F, Which, 92, 236, 0, 0, 1.0!, 0.0!, 9.5!, 1.0!)
  LdSweepE(F, Which, 92, 236, 0, 0, 1.0!, 4.0!, 9.5!, 1.0!)
  LdSweepE(F, Which, 92, 236, 0, 0, 1.0!, 2.0!, 4.0!, 1.0!)
  LdSweepE(F, Which, 92, 236, 0, 0, 1.0!, 2.0!, 0.0!, 1.0!)
  LdSweepE(F, Which, 92, 236, 0, 0, 1.0!, 2.0!, 9.5!, 0.75!)
  LdSweepE(F, Which, 92, 236, 0, 0, 1.0!, 2.0!, 9.5!, 1.25!)
  Close #F
  Randomize Sd, 3
  Dim As String Rf = Fn & "_random.txt"
  F = M5_OpenGrid(Rf, Fn, S_LEVDENS)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt Zr = LdDrawI(88, 97)
    Dim As LongInt Ar = LdDrawI(226, 241)
    Dim As Single Er = M5_Draw(-10, 25)
    Dim As LongInt Ir = LdDrawI(0, 2)
    Dim As LongInt Pr = LdDrawI(0, 3)
    Dim As Single Tr = M5_Draw(0.5, 1.5)
    Dim As Single Cr = M5_Draw(0, 4)
    Dim As Single Hr = M5_Draw(0, 15)
    Dim As Single Fr = M5_Draw(0.9, 1.1)
    Print #F, LineLD(Which, Zr, Ar, Er, Ir, Pr, Tr, Cr, Hr, Fr)
  Next
  Close #F
End Sub

' TempSweepE: U_Temp at one (Z, A) over EAx (inner loop; ETRANS = Etrans of the call).
Sub TempSweepE(ByVal F As Long, ByVal Z As Single, ByVal A As Single, ByVal Ish As Long, ByVal Ipr As Long, ByVal Ts As Single, ByVal Co As Single, ByVal Et As Single)
  For K As Long = 0 To 2014
    Print #F, LineTemp(Z, A, EAx(K), Ish, Ipr, Ts, Co, Et)
  Next
End Sub

' U_Temp (GEF.bas:17335-17385; ETRANS unused). Grid blocks, outer loop first:
'  1  Z = 1..120, N = 0..203 (A = Z + N), E in E3; Ishell 1 (one ShellMO read per point), Ipair 0,
'     Tscale 1.0, Econd 2.0, Etrans 9.5.
'  2  Zq in {10, 10.25, 10.5, 10.75, 92, 92.25, 92.5, 92.75} (outer), A = M5_Axis(Zq, 0.25, J) for
'     J = 0..811 (A = Zq .. Zq+202.75), E in E3 (inner); Ishell 1, Ipair 1, Tscale 1.0, Econd 2.0,
'     Etrans 9.5. BASIC CLng rounds Z and A half to even.
'  3  Pairs (Z,A) in {(10,20), (50,110), (88,226), (92,233), (92,236), (96,240)} (outer), Ishell 0..1,
'     Ipair 0..2, E = EAx(0..2014) (inner); Tscale 1.0, Econd 2.0, Etrans 9.5.
'  4  Pairs (outer), Tscale {1.0, 0.5}, Econd {0, 2, 4}, Etrans {9.5, 0.0}, E in {-1, 0.5, 1, 5,
'     9.5, 20, NaN}, Ishell 0..1, Ipair 0..2 (inner).
'  5  (Z,A) = (92,236), E = EAx(0..2014), one parameter changed from the base (Ishell 0, Ipair 0,
'     Tscale 1.0, Econd 2.0, Etrans 9.5), in this order: Ishell 1; Ipair 1; Ipair 2; Tscale 0.5;
'     Econd 0; Econd 4.
' Random (own file, Randomize 5105): Zr = floor(M5_Draw(10,97)), Ar = Zr + floor(M5_Draw(0,141)),
'     E in [-12,95), Ishell = floor(M5_Draw(0,2)), Ipair = floor(M5_Draw(0,3)), Tscale in
'     [0.5,1.5), Econd in [0,4), Etrans in [0,15). Draw order: Zr, Ar, E, Ishell, Ipair, Tscale,
'     Econd, Etrans.
Sub GridTemp()
  Dim As Single PZ(0 To 5) = {10, 50, 88, 92, 92, 96}
  Dim As Single PA(0 To 5) = {20, 110, 226, 233, 236, 240}
  Dim As Single Zq(0 To 7) = {10, 10.25!, 10.5!, 10.75!, 92, 92.25!, 92.5!, 92.75!}
  Dim As Single Tsv(0 To 1) = {1.0!, 0.5!}
  Dim As Single Cov(0 To 2) = {0.0!, 2.0!, 4.0!}
  Dim As Single Etv(0 To 1) = {9.5!, 0.0!}
  Dim As Single Ev(0 To 6) = {-1, 0.5!, 1, 5, 9.5!, 20, 0}
  Ev(6) = F32Bits(&h7FC00000)
  Dim As String Gf = "U_Temp_grid.txt"
  Dim As Long F = M5_OpenGrid(Gf, "U_Temp", S_TEMP)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 203
      For Ie As Long = 0 To 2
        Print #F, LineTemp(Zi, Zi + Ni, E3(Ie), 1, 0, 1.0!, 2.0!, 9.5!)
      Next
    Next
  Next
  For Iq As Long = 0 To 7
    For J As Long = 0 To 811
      For Ie As Long = 0 To 2
        Print #F, LineTemp(Zq(Iq), M5_Axis(Zq(Iq), 0.25, J), E3(Ie), 1, 1, 1.0!, 2.0!, 9.5!)
      Next
    Next
  Next
  For Ip As Long = 0 To 5
    For Ish As Long = 0 To 1
      For Ipr As Long = 0 To 2
        TempSweepE(F, PZ(Ip), PA(Ip), Ish, Ipr, 1.0!, 2.0!, 9.5!)
      Next
    Next
  Next
  For Ip As Long = 0 To 5
    For Its As Long = 0 To 1
      For Ico As Long = 0 To 2
        For Iet As Long = 0 To 1
          For Ie As Long = 0 To 6
            For Ish As Long = 0 To 1
              For Ipr As Long = 0 To 2
                Print #F, LineTemp(PZ(Ip), PA(Ip), Ev(Ie), Ish, Ipr, Tsv(Its), Cov(Ico), Etv(Iet))
              Next
            Next
          Next
        Next
      Next
    Next
  Next
  TempSweepE(F, 92, 236, 1, 0, 1.0!, 2.0!, 9.5!)
  TempSweepE(F, 92, 236, 0, 1, 1.0!, 2.0!, 9.5!)
  TempSweepE(F, 92, 236, 0, 2, 1.0!, 2.0!, 9.5!)
  TempSweepE(F, 92, 236, 0, 0, 0.5!, 2.0!, 9.5!)
  TempSweepE(F, 92, 236, 0, 0, 1.0!, 0.0!, 9.5!)
  TempSweepE(F, 92, 236, 0, 0, 1.0!, 4.0!, 9.5!)
  Close #F
  Randomize 5105, 3
  Dim As String Rf = "U_Temp_random.txt"
  F = M5_OpenGrid(Rf, "U_Temp", S_TEMP)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt Zr = LdDrawI(10, 97)
    Dim As LongInt Ar = Zr + LdDrawI(0, 141)
    Dim As Single Er = M5_Draw(-12, 95)
    Dim As LongInt Ir = LdDrawI(0, 2)
    Dim As LongInt Pr = LdDrawI(0, 3)
    Dim As Single Tr = M5_Draw(0.5, 1.5)
    Dim As Single Cr = M5_Draw(0, 4)
    Dim As Single Hr = M5_Draw(0, 15)
    Print #F, LineTemp(Zr, Ar, Er, Ir, Pr, Tr, Cr, Hr)
  Next
  Close #F
End Sub

' Temp2SweepE: U_Temp2 at one (Z, A) over EAx (inner loop).
Sub Temp2SweepE(ByVal F As Long, ByVal Z As Single, ByVal A As Single, ByVal Rs As Single, ByVal Rp As Single, ByVal Ts As Single, ByVal Co As Single, ByVal Et As Single)
  For K As Long = 0 To 2014
    Print #F, LineTemp2(Z, A, EAx(K), Rs, Rp, Ts, Co, Et)
  Next
End Sub

' U_Temp2 (GEF.bas:17388-17420; no table reads; ETRANS unused). Grid blocks, outer loop first:
'  1  Z = 1..120, N = 0..203 (A = Z + N), E in E3; Rshell 0, Rpair 0, Tscale 1.0, Econd 2.0,
'     Etrans 9.5.
'  2  Zq as in U_Temp block 2 (outer), A = M5_Axis(Zq, 0.25, J) for J = 0..811, E in E3 (inner);
'     Rshell 0, Rpair 0, Tscale 1.0, Econd 2.0, Etrans 9.5.
'  3  Pairs (Z,A) as in U_Temp block 3 (outer), Rshell {0, -2.5, 1.5}, Rpair {0, 0.5, -1},
'     E = EAx(0..2014) (inner); Tscale 1.0, Econd 2.0, Etrans 9.5.
'  4  Pairs (outer), Tscale {1.0, 0.5}, Econd {0, 2, 4}, E in {-1, 0.5, 1, 5, 9.5, 20, NaN},
'     Rshell {0, -2.5, 1.5}, Rpair {0, 0.5} (inner); Etrans 9.5.
'  5  (Z,A) = (92,236), E = EAx(0..2014), one parameter changed from the base (Rshell 0, Rpair 0,
'     Tscale 1.0, Econd 2.0, Etrans 9.5), in this order: Tscale 0.5; Econd 0; Econd 4; Rshell -2.5;
'     Rshell 1.5; Rpair 0.5; Rpair -1.
' Random (own file, Randomize 5106): Zr = floor(M5_Draw(10,97)), Ar = floor(M5_Draw(20,237)) (drawn
'     independently, so N may be negative), E in [-12,40), Rshell in [-10,5), Rpair in [-2,2),
'     Tscale in [0.5,1.5), Econd in [0,4), Etrans in [0,15). Draw order: Zr, Ar, E, Rshell, Rpair,
'     Tscale, Econd, Etrans.
Sub GridTemp2()
  Dim As Single PZ(0 To 5) = {10, 50, 88, 92, 92, 96}
  Dim As Single PA(0 To 5) = {20, 110, 226, 233, 236, 240}
  Dim As Single Zq(0 To 7) = {10, 10.25!, 10.5!, 10.75!, 92, 92.25!, 92.5!, 92.75!}
  Dim As Single Rsv(0 To 2) = {0, -2.5!, 1.5!}
  Dim As Single Rpv(0 To 2) = {0, 0.5!, -1}
  Dim As Single Rqv(0 To 1) = {0, 0.5!}
  Dim As Single Tsv(0 To 1) = {1.0!, 0.5!}
  Dim As Single Cov(0 To 2) = {0.0!, 2.0!, 4.0!}
  Dim As Single Ev(0 To 6) = {-1, 0.5!, 1, 5, 9.5!, 20, 0}
  Ev(6) = F32Bits(&h7FC00000)
  Dim As String Gf = "U_Temp2_grid.txt"
  Dim As Long F = M5_OpenGrid(Gf, "U_Temp2", S_TEMP2)
  For Zi As Long = 1 To 120
    For Ni As Long = 0 To 203
      For Ie As Long = 0 To 2
        Print #F, LineTemp2(Zi, Zi + Ni, E3(Ie), 0, 0, 1.0!, 2.0!, 9.5!)
      Next
    Next
  Next
  For Iq As Long = 0 To 7
    For J As Long = 0 To 811
      For Ie As Long = 0 To 2
        Print #F, LineTemp2(Zq(Iq), M5_Axis(Zq(Iq), 0.25, J), E3(Ie), 0, 0, 1.0!, 2.0!, 9.5!)
      Next
    Next
  Next
  For Ip As Long = 0 To 5
    For Irs As Long = 0 To 2
      For Irp As Long = 0 To 2
        Temp2SweepE(F, PZ(Ip), PA(Ip), Rsv(Irs), Rpv(Irp), 1.0!, 2.0!, 9.5!)
      Next
    Next
  Next
  For Ip As Long = 0 To 5
    For Its As Long = 0 To 1
      For Ico As Long = 0 To 2
        For Ie As Long = 0 To 6
          For Irs As Long = 0 To 2
            For Irq As Long = 0 To 1
              Print #F, LineTemp2(PZ(Ip), PA(Ip), Ev(Ie), Rsv(Irs), Rqv(Irq), Tsv(Its), Cov(Ico), 9.5!)
            Next
          Next
        Next
      Next
    Next
  Next
  Temp2SweepE(F, 92, 236, 0, 0, 0.5!, 2.0!, 9.5!)
  Temp2SweepE(F, 92, 236, 0, 0, 1.0!, 0.0!, 9.5!)
  Temp2SweepE(F, 92, 236, 0, 0, 1.0!, 4.0!, 9.5!)
  Temp2SweepE(F, 92, 236, -2.5!, 0, 1.0!, 2.0!, 9.5!)
  Temp2SweepE(F, 92, 236, 1.5!, 0, 1.0!, 2.0!, 9.5!)
  Temp2SweepE(F, 92, 236, 0, 0.5!, 1.0!, 2.0!, 9.5!)
  Temp2SweepE(F, 92, 236, 0, -1, 1.0!, 2.0!, 9.5!)
  Close #F
  Randomize 5106, 3
  Dim As String Rf = "U_Temp2_random.txt"
  F = M5_OpenGrid(Rf, "U_Temp2", S_TEMP2)
  For I As Long = 1 To N_RANDOM
    Dim As LongInt Zr = LdDrawI(10, 97)
    Dim As LongInt Ar = LdDrawI(20, 237)
    Dim As Single Er = M5_Draw(-12, 40)
    Dim As Single Rs = M5_Draw(-10, 5)
    Dim As Single Rp = M5_Draw(-2, 2)
    Dim As Single Tr = M5_Draw(0.5, 1.5)
    Dim As Single Cr = M5_Draw(0, 4)
    Dim As Single Hr = M5_Draw(0, 15)
    Print #F, LineTemp2(Zr, Ar, Er, Rs, Rp, Tr, Cr, Hr)
  Next
  Close #F
End Sub

' TEgidy (GEF.bas:16072-16095; TEMP_SMOOTH and T_FAC unused). Grid: A = M5_Axis(0, 0.25, Ia),
' Ia = 0..960 (outer; A = 0 .. 240), DU = M5_Axis(-13, 0.5, Idu), Idu = 0..30 (middle), Fred in
' {0.8, 1.0, 1.25} (inner). Random (Randomize 5107): A = M5_Draw(1,240), DU = M5_Draw(-13,2),
' Fred = M5_Draw(0.5,1.5); draw order A, DU, Fred.
Sub GridTEgidy()
  Dim As Single Fv(0 To 2) = {0.8!, 1.0!, 1.25!}
  Dim As String Gf = "TEgidy_grid.txt"
  Dim As Long F = M5_OpenGrid(Gf, "TEgidy", S_TEGIDY)
  For Ia As Long = 0 To 960
    For Idu As Long = 0 To 30
      For Ifr As Long = 0 To 2
        Print #F, LineTEgidy(M5_Axis(0, 0.25, Ia), M5_Axis(-13, 0.5, Idu), Fv(Ifr))
      Next
    Next
  Next
  Close #F
  Randomize 5107, 3
  Dim As String Rf = "TEgidy_random.txt"
  F = M5_OpenGrid(Rf, "TEgidy", S_TEGIDY)
  For I As Long = 1 To N_RANDOM
    Dim As Single Ar = M5_Draw(1, 240)
    Dim As Single Dr = M5_Draw(-13, 2)
    Dim As Single Fr = M5_Draw(0.5, 1.5)
    Print #F, LineTEgidy(Ar, Dr, Fr)
  Next
  Close #F
End Sub

' TRusanov (GEF.bas:16098-16108; EMIN and EEFF unused). Block 1: A = 1..240 (outer), E = EAx(0..2000)
' (inner). Block 2: J = 0..956 (outer, J Mod 4 = 0 skipped), A = M5_Axis(1, 0.25, J), E = EAx(20*M)
' for M = 0..100 (inner). Random (Randomize 5108): E = M5_Draw(0,15), A = M5_Draw(1,240).
Sub GridTRusanov()
  Dim As String Gf = "TRusanov_grid.txt"
  Dim As Long F = M5_OpenGrid(Gf, "TRusanov", S_TRUSANOV)
  For Ai As Long = 1 To 240
    For Ie As Long = 0 To 2000
      Print #F, LineTRusanov(EAx(Ie), Ai)
    Next
  Next
  For J As Long = 0 To 956
    If J Mod 4 <> 0 Then
      For Ime As Long = 0 To 100
        Print #F, LineTRusanov(EAx(20 * Ime), M5_Axis(1, 0.25, J))
      Next
    End If
  Next
  Close #F
  Randomize 5108, 3
  Dim As String Rf = "TRusanov_random.txt"
  F = M5_OpenGrid(Rf, "TRusanov", S_TRUSANOV)
  For I As Long = 1 To N_RANDOM
    Dim As Single Er = M5_Draw(0, 15)
    Dim As Single Ar = M5_Draw(1, 240)
    Print #F, LineTRusanov(Er, Ar)
  Next
  Close #F
End Sub

Sub Grids()
  FillE()
  GridAlev()
  GridLD(0, 5102)
  GridLD(1, 5103)
  GridLD(2, 5104)
  GridTemp()
  GridTemp2()
  GridTEgidy()
  GridTRusanov()
End Sub

Sub ReplayLD(ByVal Which As Long, ByRef Cdir As String)
  Dim As M5_Replay R
  Dim As String T()
  Dim As String Fn = LdName(Which)
  If M5_ReplayOpen(R, Cdir, Fn, S_LEVDENS) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineLD(Which, M5_ParseI64(T(0)), M5_ParseI64(T(1)), M5_ParseF32(T(2)), _
                               M5_ParseI64(T(3)), M5_ParseI64(T(4)), M5_ParseF32(T(5)), _
                               M5_ParseF32(T(6)), M5_ParseF32(T(7)), M5_ParseF32(T(8))))
    Wend
    M5_ReplayClose(R)
  End If
End Sub

Sub Replay(ByRef Cdir As String)
  Dim As M5_Replay R
  Dim As String T()
  If M5_ReplayOpen(R, Cdir, "U_alev_ld", S_ALEV) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineAlev(M5_ParseF32(T(0)), M5_ParseF32(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
  ReplayLD(0, Cdir)
  ReplayLD(1, Cdir)
  ReplayLD(2, Cdir)
  If M5_ReplayOpen(R, Cdir, "U_Temp", S_TEMP) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineTemp(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2)), _
                                 M5_ParseI64(T(3)), M5_ParseI64(T(4)), M5_ParseF32(T(5)), _
                                 M5_ParseF32(T(6)), M5_ParseF32(T(7))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "U_Temp2", S_TEMP2) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineTemp2(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2)), _
                                  M5_ParseF32(T(3)), M5_ParseF32(T(4)), M5_ParseF32(T(5)), _
                                  M5_ParseF32(T(6)), M5_ParseF32(T(7))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "TEgidy", S_TEGIDY) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineTEgidy(M5_ParseF32(T(0)), M5_ParseF32(T(1)), M5_ParseF32(T(2))))
    Wend
    M5_ReplayClose(R)
  End If
  If M5_ReplayOpen(R, Cdir, "TRusanov", S_TRUSANOV) Then
    While M5_ReplayNext(R, T())
      M5_ReplayWrite(R, LineTRusanov(M5_ParseF32(T(0)), M5_ParseF32(T(1))))
    Wend
    M5_ReplayClose(R)
  End If
End Sub

If Command(1) = "replay" Then
  Replay(Command(2))
ElseIf Command(1) = "" Then
  Grids()
Else
  Print "usage: m5_level_density [replay <arglog dir>]"
  End 2
End If
