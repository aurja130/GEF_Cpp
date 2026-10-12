' SPDX-License-Identifier: GPL-3.0-or-later
' Copyright (C) 2026 Aurora Jahan
' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
'
' Shared helpers of the M5 physics drivers (harness/drivers/m5_*.bas, '@include-driver).
' Conventions: harness/drivers/M5_DRIVERS.md. Tokens are those of the arglog patch
' (harness/ARGLOG.md): f32 8 hex, f64 16 hex, i64 16 hex (two's complement), u8 2 hex, str hex
' bytes or "-", f32[] "<count>[:v,v,...]", f32hash 16 hex; all lowercase.

#include once "file.bi"

' --- formatting ------------------------------------------------------------------------------

Function M5_F32(ByVal X As Single) As String
  Return LCase(Hex(*Cast(ULong Ptr, @X), 8))
End Function

Function M5_F64(ByVal X As Double) As String
  Return LCase(Hex(*Cast(ULongInt Ptr, @X), 16))
End Function

Function M5_I64(ByVal X As LongInt) As String
  Return LCase(Hex(*Cast(ULongInt Ptr, @X), 16))
End Function

Function M5_U8(ByVal X As UByte) As String
  Return LCase(Hex(X, 2))
End Function

Function M5_Str(ByRef S As String) As String
  If Len(S) = 0 Then Return "-"
  Dim As String R
  For I As Long = 0 To Len(S) - 1
    R &= LCase(Hex(S[I], 2))
  Next
  Return R
End Function

' Elements Ifirst..Ilast (clipped to UBound) of a Single array.
Function M5_F32List(A() As Single, ByVal Ifirst As LongInt, ByVal Ilast As LongInt) As String
  If Ilast > UBound(A) Then Ilast = UBound(A)
  If Ilast < Ifirst Then Return "0"
  Dim As String R = Str(Ilast - Ifirst + 1)
  For I As LongInt = Ifirst To Ilast
    R &= IIf(I = Ifirst, ":", ",") & M5_F32(A(I))
  Next
  Return R
End Function

' h = 0xCBF29CE484222325; h = (h Xor bits) * 0x100000001B3 over A(LBound..UBound).
Function M5_F32Hash(A() As Single) As String
  Dim As ULongInt H = &hCBF29CE484222325ull
  For I As LongInt = LBound(A) To UBound(A)
    Dim As Single X = A(I)
    H = (H Xor *Cast(ULong Ptr, @X)) * &h100000001B3ull
  Next
  Return LCase(Hex(H, 16))
End Function

' --- grid inputs ---------------------------------------------------------------------------

' Value I of a structured axis Lo, Lo + Stp, ...: CSng(Lo + I * Stp), evaluated in Double.
Function M5_Axis(ByVal Lo As Double, ByVal Stp As Double, ByVal I As LongInt) As Single
  Return CSng(Lo + I * Stp)
End Function

' A Single drawn from [Lo, Hi): CSng(Lo + (Hi - Lo) * Rnd), evaluated in Double.
Function M5_Draw(ByVal Lo As Double, ByVal Hi As Double) As Single
  Return CSng(Lo + (Hi - Lo) * Rnd)
End Function

' --- parsing ---------------------------------------------------------------------------------

Function M5_Bits(ByRef T As String) As ULongInt
  Dim As ULongInt V = 0
  For I As Long = 0 To Len(T) - 1
    Dim As Long C = T[I]
    Dim As Long D
    If C >= 48 And C <= 57 Then
      D = C - 48
    ElseIf C >= 97 And C <= 102 Then
      D = C - 87
    Else
      Print "m5_common: bad hex token " & T
      End 3
    End If
    V = (V Shl 4) Or D
  Next
  Return V
End Function

Function M5_ParseF32(ByRef T As String) As Single
  Dim As ULong B = CULng(M5_Bits(T))
  Return *Cast(Single Ptr, @B)
End Function

Function M5_ParseF64(ByRef T As String) As Double
  Dim As ULongInt B = M5_Bits(T)
  Return *Cast(Double Ptr, @B)
End Function

Function M5_ParseI64(ByRef T As String) As LongInt
  Dim As ULongInt B = M5_Bits(T)
  Return *Cast(LongInt Ptr, @B)
End Function

Function M5_ParseU8(ByRef T As String) As UByte
  Return CUByte(M5_Bits(T))
End Function

Function M5_ParseStr(ByRef T As String) As String
  If T = "-" Then Return ""
  Dim As String R
  For I As Long = 1 To Len(T) Step 2
    R &= Chr(CLng(M5_Bits(Mid(T, I, 2))))
  Next
  Return R
End Function

' Splits a line at single spaces into Tok(0..n-1); returns n.
Function M5_Split(ByRef L As String, Tok() As String) As Long
  Dim As Long N = 0, P = 1
  ReDim Tok(0 To 63)
  Do
    Dim As Long Q = InStr(P, L, " ")
    If N > UBound(Tok) Then ReDim Preserve Tok(0 To 2 * UBound(Tok) + 1)
    If Q = 0 Then
      Tok(N) = Mid(L, P)
      Return N + 1
    End If
    Tok(N) = Mid(L, P, Q - P)
    N += 1
    P = Q + 1
  Loop
End Function

' --- output files ----------------------------------------------------------------------------

' Opens <name> for output and writes the header "# m5grid 1 <fn> <schema>"; returns the file number.
Function M5_OpenGrid(ByRef Cfile As String, ByRef Cfn As String, ByRef Cschema As String) As Long
  Dim As Long F = FreeFile
  If Open(Cfile For Output As #F) <> 0 Then
    Print "m5_common: cannot create " & Cfile
    End 3
  End If
  Print #F, "# m5grid 1 " & Cfn & " " & Cschema
  Return F
End Function

' --- replay ----------------------------------------------------------------------------------
' A replay reads <arglog dir>/<fn>.txt, checks its header against the driver's schema, and for each
' record calls back the driver, which recomputes the call from the logged inputs and returns the
' full token list (inputs echoed as logged, outputs recomputed). The replay file
' replay/<fn>.txt holds "<seq> <tokens>"; harness.arglog replay-check compares it with the log.

Type M5_Replay
  Fin As Long        ' arglog file, 0 if absent
  Fout As Long
  Ntok As Long       ' tokens per record after the 5-token prefix
  Cseq As String
End Type

' Opens the log of Cfn in Cdir and replay/<fn>.txt; returns 0 if the log does not exist.
Function M5_ReplayOpen(ByRef R As M5_Replay, ByRef Cdir As String, ByRef Cfn As String, _
                       ByRef Cschema As String) As Long
  Dim As String Cpath = Cdir & "/" & Cfn & ".txt"
  R.Fin = 0
  If FileExists(Cpath) = 0 Then Return 0
  R.Fin = FreeFile
  Open Cpath For Input As #R.Fin
  Dim As String Lhead
  Line Input #R.Fin, Lhead
  If Lhead <> "# arglog 1 " & Cfn & " " & Cschema Then
    Print "m5_common: schema mismatch for " & Cfn
    Print "  log:    " & Lhead
    Print "  driver: # arglog 1 " & Cfn & " " & Cschema
    End 3
  End If
  Dim As String Tok()
  R.Ntok = M5_Split(Cschema, Tok())
  MkDir "replay"
  R.Fout = FreeFile
  Open "replay/" & Cfn & ".txt" For Output As #R.Fout
  Return 1
End Function

' Reads the next record into Tok(0..Ntok-1) (without the prefix); returns 0 at the end.
Function M5_ReplayNext(ByRef R As M5_Replay, Tok() As String) As Long
  If R.Fin = 0 OrElse EOF(R.Fin) Then Return 0
  Dim As String L
  Line Input #R.Fin, L
  Dim As String All()
  Dim As Long N = M5_Split(L, All())
  If N <> R.Ntok + 5 Then
    Print "m5_common: bad record: " & L
    End 3
  End If
  R.Cseq = All(0)
  ReDim Tok(0 To R.Ntok - 1)
  For I As Long = 0 To R.Ntok - 1
    Tok(I) = All(I + 5)
  Next
  Return 1
End Function

Sub M5_ReplayWrite(ByRef R As M5_Replay, ByRef Ctokens As String)
  Print #R.Fout, R.Cseq & " " & Ctokens
End Sub

Sub M5_ReplayClose(ByRef R As M5_Replay)
  If R.Fin <> 0 Then
    Close #R.Fin
    Close #R.Fout
    R.Fin = 0
  End If
End Sub
