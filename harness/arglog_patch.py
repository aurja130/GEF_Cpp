# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Generate the harness patch ``arglog`` (M5.1) from the pristine GEF source.

The patch is mechanical (one wrapper per function, an ``#undef``/``#define`` pair around every
definition), so it is generated rather than written by hand. ``harness/ARGLOG.md`` describes
what the patched program does and the log format; ``harness.arglog`` reads the logs.

Usage::

    python3 -m harness.arglog_patch           # (re)write harness/patches/arglog.patch
    python3 -m harness.arglog_patch --check   # exit 1 if the committed patch is stale

Construction (``GEF.bas`` line numbers are kept; see CODING_STANDARDS.md §3.1):

* ``GEF.bas:695`` (blank, after the last ``Declare`` of a logged function) includes
  ``harness_arglog.bi``, the logging runtime. ``GEF.bas:1820`` (blank, after ``Dim Shared f`` at
  1768 and before the first call at 2119) includes ``harness_arglog_wrappers.bi``: one wrapper
  ``hlog_<name>`` per function, then per function ``#undef <name>`` and a function-like macro
  ``#define <name>(...) hlog_<name>(__FILE__, __LINE__, ...)``, so every later call goes
  through its wrapper. fbc rejects a ``#define`` of a declared procedure name; ``#undef``
  removes that symbol first, and wrappers compiled before keep calling the procedure.
* Every definition in ``GEF.bas`` is preceded by ``#undef <name>`` and followed by the
  ``#undef``/``#define`` again, each with a ``#line`` that restores the numbering (the emitted C
  of the patch set without ``-d GEF_ARGLOG`` equals that of ``seed`` + ``scope`` apart from
  source-echo comments). Inside its own body a function is therefore not renamed; calls to
  the other functions are logged.
* ``U_Q_beta_minus`` is declared and defined in ``DCLbranchingJEFF33.bas:110-115``, which
  ``GEF.bas:1284`` includes after the runtime: line 111 (blank) includes its wrapper, line 116
  (blank) the macro.
* The two deterministic pieces are logged at their sites by includes on blank lines: the
  ``P_Egamma_low`` table (``GEF.bas:16979`` in, ``17038`` out) and the light and heavy E2
  cascades (``9308``/``9369``, ``9429``/``9485``).

Everything the patch adds is inside ``#ifdef GEF_ARGLOG``; without the define only ``#line``
directives and empty includes remain.
"""

from __future__ import annotations

import argparse
import difflib
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from harness.common import GEF_SOURCE_DIR, PATCHES_DIR, HarnessError

PATCH_FILE = PATCHES_DIR / "arglog.patch"

# The functions of MILESTONE_5_PLAN.md §3 (P_Egamma_low is logged as a site, not wrapped).
FUNCTIONS = (
    "LyMass",
    "LyPair",
    "FEDEFOLys",
    "LDMass",
    "AME2020",
    "U_SHELL",
    "U_SHELL_exp",
    "U_SHELL_EO_exp",
    "U_MASS",
    "ECOUL",
    "U_Q_beta_minus",
    "U_Valid",
    "U_Delta_S0",
    "BFTF",
    "BFTFA",
    "BFTFB",
    "U_alev_ld",
    "U_levdens",
    "U_levdens_Egidy",
    "U_levdens_FG",
    "U_Temp",
    "U_Temp2",
    "TEgidy",
    "TRusanov",
    "Getyield",
    "F1",
    "F2",
    "Masscurv",
    "Masscurv1",
    "Masscurv2",
    "De_Saddle_Scission",
    "beta_light",
    "beta_heavy",
    "Z_equi",
    "Beta_Equi",
    "Gaussintegral",
    "Bell",
    "U_Box",
    "EVEN_ODD",
    "U_Ired",
    "U_IredFF",
    "U_I_Shell",
    "E0_GDR",
    "Width_GDR",
    "Efac_def_GDR",
    "u_accel",
)

DCL_FILE = "DCLbranchingJEFF33.bas"
DCL_FUNCTION = "U_Q_beta_minus"
RUNTIME_LINE = 695  # GEF.bas, blank: after the last Declare of a logged function
WRAPPERS_LINE = 1820  # GEF.bas, blank: after Dim Shared f (1768), before the first call (2119)
DCL_WRAPPER_LINE = 111  # DCLbranchingJEFF33.bas, blank
DCL_MACRO_LINE = 116  # DCLbranchingJEFF33.bas, blank

# Shared variables a function reads besides its arguments, logged as "global.<name>" (value
# at entry). Beta_Equi prints its non-convergence message to file number f (GEF.bas:16628).
EXTRA_GLOBALS: dict[str, tuple[tuple[str, str], ...]] = {"Beta_Equi": (("f", "i64"),)}

# BASIC type -> (log type, FreeBASIC type name).
_TYPES = {
    "single": ("f32", "Single"),
    "double": ("f64", "Double"),
    "integer": ("i64", "Integer"),
    "ubyte": ("u8", "UByte"),
}
_PUT = {"f32": "HL_F32", "f64": "HL_F64", "i64": "HL_I64", "u8": "HL_U8"}
_FB_OF = {"f32": "Single", "f64": "Double", "i64": "Integer", "u8": "UByte"}


@dataclass(frozen=True)
class Param:
    name: str
    log_type: str
    fb_type: str
    byref: bool


@dataclass(frozen=True)
class Function:
    name: str
    params: tuple[Param, ...]
    result: tuple[str, str] | None  # (log type, FB type); None for a Sub
    file: str
    def_first: int  # first line of the definition header
    def_last: int  # the End Function / End Sub line


@dataclass(frozen=True)
class SiteField:
    expr: str  # BASIC expression logged
    name: str  # field name in the log header
    log_type: str  # f32, i64, str, f32list, f32hash


@dataclass(frozen=True)
class Site:
    name: str
    line_in: int
    line_out: int
    fields_in: tuple[SiteField, ...]
    fields_out: tuple[SiteField, ...]


def _f(expr: str, log_type: str, name: str | None = None) -> SiteField:
    return SiteField(expr, name if name is not None else expr, log_type)


def _e2_fields(side: str) -> tuple[tuple[SiteField, ...], tuple[SiteField, ...]]:
    ng = "Nglight" if side == "light" else "Ngheavy"
    common_in = (
        _f(f"I_Z_{side}_sci", "i64"),
        _f(f"I_A_{side}_post", "i64"),
        _f("I_MAT", "i64"),
        _f("I_DelGam", "i64"),
        _f("Jfrag", "f32"),
        _f(f"J_frag_{side}", "f32"),
        _f(f"Spin_gs_{side}", "f32"),
        _f("N_iso", "i64"),
        _f("I_iso", "i64"),
        _f(ng, "i64"),
        _f("Ngtot", "i64"),
        _f("Egtot1000", "f32"),
        _f(f"Ig2_{side}", "i64"),
    )
    # E_E2_tot is declared inside the light copy (GEF.bas:9310); the heavy copy sees its value.
    fields_in = common_in if side == "light" else (*common_in, _f("E_E2_tot", "f32"))
    fields_out = (
        _f("E_E2_tot", "f32"),
        _f(f"IfragEff_{side}", "f32"),
        _f("beta1", "f32"),
        _f("alph", "f32"),
        _f("N_iso", "i64"),
        _f("I_iso", "i64"),
        _f(f"C_iso_lmd_{side}", "str"),
        _f("J", "f32"),
        _f("K", "f32"),
        _f("RJeff", "f32"),
        _f("Eg", "f32"),
        _f("Nspectrum", "i64"),
        _f(ng, "i64"),
        _f("Ngtot", "i64"),
        _f("Egtot1000", "f32"),
        _f(f"Ig2_{side}", "i64"),
        _f(f"Array_Eg2_{side}", "f32list", f"Array_Eg2_{side}(1..Ig2_{side})"),
    )
    return fields_in, fields_out


_E2L = _e2_fields("light")
_E2H = _e2_fields("heavy")
SITES = (
    Site("e2_light", 9308, 9369, *_E2L),
    Site("e2_heavy", 9429, 9485, *_E2H),
    Site(
        "pegl_table",
        16979,
        17038,
        tuple(_f(x, "f32") for x in ("Zi", "Ai", "Ei", "Tscale", "Econd", "Etrans")),
        (
            _f("N", "i64"),
            _f("Tm", "f32"),
            _f("betadef", "f32"),
            _f("gammadef", "f32"),
            _f("sigMax", "f32"),
            _f("Eg", "f32"),
            _f("I", "i64"),
            *(_f(f"E0({i})", "f32") for i in range(4)),
            *(_f(f"G0({i})", "f32") for i in range(4)),
            _f("UBound(sigma)", "i64"),
            _f("sigma", "f32hash", "sigma(0..UBound)"),
        ),
    ),
)

_LICENSE = (
    "' SPDX-License-Identifier: GPL-3.0-or-later\n"
    "' Copyright (C) 2026 Aurora Jahan\n"
    "' Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.\n"
)


def _logical_lines(lines: list[str]) -> list[tuple[int, int, str]]:
    """(first line, last line, joined text) per logical line; `` _`` continues a line."""
    out: list[tuple[int, int, str]] = []
    buf: list[str] = []
    first = 0
    for no, raw in enumerate(lines, start=1):
        if not buf:
            first = no
        text = raw.split("'", 1)[0] if "'" in raw and '"' not in raw else raw
        if re.search(r"\s_\s*$", text):
            buf.append(re.sub(r"\s_\s*$", " ", text))
            continue
        buf.append(text)
        out.append((first, no, " ".join(s.strip() for s in buf)))
        buf = []
    return out


_DECL_RE = re.compile(
    r"^Declare\s+(Function|Sub)\s+(\w+)\s*\((.*)\)\s*(?:As\s+(\w+))?\s*$", re.IGNORECASE
)
_PARAM_RE = re.compile(r"^(ByRef\s+|ByVal\s+)?(\w+)\s+As\s+(\w+)$", re.IGNORECASE)


def _parse_declare(text: str) -> tuple[tuple[Param, ...], tuple[str, str] | None]:
    m = _DECL_RE.match(text)
    if m is None:
        raise HarnessError(f"cannot parse declaration: {text}")
    params: list[Param] = []
    for part in (p.strip() for p in m[3].split(",")):
        pm = _PARAM_RE.match(part)
        if pm is None or pm[3].lower() not in _TYPES:
            raise HarnessError(f"unsupported parameter {part!r} in: {text}")
        log_type, fb_type = _TYPES[pm[3].lower()]
        byref = (pm[1] or "").strip().lower() == "byref"
        params.append(Param(pm[2], log_type, fb_type, byref))
    if m[1].lower() == "sub":
        return tuple(params), None
    if m[4] is None or m[4].lower() not in _TYPES:
        raise HarnessError(f"unsupported result type in: {text}")
    return tuple(params), _TYPES[m[4].lower()]


def _find_function(name: str, file: str, logical: list[tuple[int, int, str]]) -> Function:
    decl = [
        t for (_, _, t) in logical if re.match(rf"Declare\s+(Function|Sub)\s+{name}\s*\(", t, re.I)
    ]
    if len(decl) != 1:
        raise HarnessError(f"{file}: expected one Declare of {name}, found {len(decl)}")
    params, result = _parse_declare(decl[0])
    head_re = re.compile(rf"((Public|Private)\s+)?(Function|Sub)\s+{name}\s*\(", re.I)
    heads = [(a, t) for (a, _, t) in logical if head_re.match(t)]
    if len(heads) != 1:
        raise HarnessError(f"{file}: expected one definition of {name}, found {len(heads)}")
    first = heads[0][0]
    kind = "Sub" if result is None else "Function"
    ends = [a for (a, _, t) in logical if a > first and re.fullmatch(rf"End\s+{kind}", t, re.I)]
    if not ends:
        raise HarnessError(f"{file}: no End {kind} after {name} at line {first}")
    return Function(name, params, result, file, first, ends[0])


def _read_lines(source_dir: Path, file: str) -> list[str]:
    return (source_dir / file).read_text(encoding="latin-1").splitlines(keepends=True)


def discover(source_dir: Path = GEF_SOURCE_DIR) -> list[Function]:
    gef = _logical_lines(_read_lines(source_dir, "GEF.bas"))
    dcl = _logical_lines(_read_lines(source_dir, DCL_FILE))
    found: list[Function] = []
    for name in FUNCTIONS:
        fn = _find_function(
            name,
            DCL_FILE if name == DCL_FUNCTION else "GEF.bas",
            dcl if name == DCL_FUNCTION else gef,
        )
        if fn.file == "GEF.bas" and fn.def_first <= WRAPPERS_LINE:
            raise HarnessError(f"{name} is defined before the wrappers (GEF.bas:{WRAPPERS_LINE})")
        found.append(fn)
    return found


def _schema(fn: Function) -> str:
    fields: list[str] = []
    for p in fn.params:
        if p.byref:
            fields += [f"{p.name}.in:{p.log_type}", f"{p.name}.out:{p.log_type}"]
        else:
            fields.append(f"{p.name}:{p.log_type}")
    if fn.result is not None:
        fields.append(f"result:{fn.result[0]}")
    fields += [f"global.{g}:{t}" for g, t in EXTRA_GLOBALS.get(fn.name, ())]
    return " ".join(fields)


def _site_schema(site: Site) -> str:
    def typ(f: SiteField) -> str:
        return {"f32list": "f32[]", "f32hash": "f32hash"}.get(f.log_type, f.log_type)

    return " ".join(
        [f"in.{f.name}:{typ(f)}" for f in site.fields_in]
        + [f"out.{f.name}:{typ(f)}" for f in site.fields_out]
    )


def _wrapper(fn: Function, ident: int) -> str:
    sig = ", ".join(
        f"{'ByRef' if p.byref else 'ByVal'} hl_p{i} As {p.fb_type}"
        for i, p in enumerate(fn.params, start=1)
    )
    call_args = ", ".join(f"hl_p{i}" for i in range(1, len(fn.params) + 1))
    head = f"Private {'Sub' if fn.result is None else 'Function'} hlog_{fn.name}("
    head += f"ByVal hl_file As ZString Ptr, ByVal hl_line As Long, {sig})"
    if fn.result is not None:
        head += f" As {fn.result[1]}"
    body = [head, f"  Dim As ULongInt hl_seq = HL_Next({ident})"]
    extra = EXTRA_GLOBALS.get(fn.name, ())
    for k, (g, t) in enumerate(extra, start=1):
        body.append(f"  Dim As {_FB_OF[t]} hl_g{k} = {g}")
    for i, p in enumerate(fn.params, start=1):
        if p.byref:
            body.append(f"  Dim As {p.fb_type} hl_in{i} = hl_p{i}")
    if fn.result is None:
        body.append(f"  {fn.name}({call_args})")
    else:
        body.append(f"  Dim As {fn.result[1]} hl_r = {fn.name}({call_args})")
    body.append("  If hl_seq <> 0 Then")
    body.append(f'    HL_Begin({ident}, "{fn.name}", "{_schema(fn)}", hl_seq, hl_file, hl_line)')
    for i, p in enumerate(fn.params, start=1):
        if p.byref:
            body.append(f"    {_PUT[p.log_type]}({ident}, hl_in{i})")
        body.append(f"    {_PUT[p.log_type]}({ident}, hl_p{i})")
    if fn.result is not None:
        body.append(f"    {_PUT[fn.result[0]]}({ident}, hl_r)")
    for k, (_, t) in enumerate(extra, start=1):
        body.append(f"    {_PUT[t]}({ident}, hl_g{k})")
    body.append(f"    HL_End({ident})")
    body.append("  End If")
    if fn.result is not None:
        body.append("  Return hl_r")
    body.append(f"End {'Sub' if fn.result is None else 'Function'}")
    return "\n".join(body) + "\n"


def _macro(fn: Function) -> str:
    # fbc refuses a #define whose name is a declared procedure ("Duplicated definition"); #undef
    # removes the procedure symbol (or the earlier macro) first. Wrappers bound to the procedure
    # before that keep calling it (same C name).
    args = ", ".join(f"hl_a{i}" for i in range(1, len(fn.params) + 1))
    return (
        f"#undef {fn.name}\n#define {fn.name}({args}) hlog_{fn.name}(__FILE__, __LINE__, {args})\n"
    )


_RUNTIME = r"""
' Logging runtime. POSIX open/write/close and static buffers: no FreeBASIC file numbers (GEF's
' FreeFile results stay the same) and no heap allocation in GEF's address space.
Extern "C"
  Declare Function HLC_open Alias "open" (ByVal Cpath As ZString Ptr, ByVal Iflags As Long, _
    ...) As Long
  Declare Function HLC_write Alias "write" (ByVal Ifd As Long, ByVal Pbuf As Any Ptr, _
    ByVal Nbytes As UInteger) As Integer
  Declare Function HLC_close Alias "close" (ByVal Ifd As Long) As Long
  Declare Function HLC_mkdir Alias "mkdir" (ByVal Cpath As ZString Ptr, _
    ByVal Imode As ULong) As Long
  Declare Function HLC_getenv Alias "getenv" (ByVal Cname As ZString Ptr) As ZString Ptr
End Extern

Const HL_N = {n_ids}             ' log files: {n_fun} functions, then {n_sites} sites
Const HL_BUFSZ = 65536
Dim Shared As Long HL_Fd(1 To HL_N)             ' 0 = not open (descriptor + 1 otherwise)
Dim Shared As Long HL_Len(1 To HL_N)
Dim Shared As UByte HL_Buf(1 To HL_N, 0 To HL_BUFSZ - 1)
Dim Shared As ULongInt HL_Calls(1 To HL_N)      ' every call, logged or not
Dim Shared As ULongInt HL_SiteSeq(1 To HL_N)    ' sites: sequence number of the open record
Dim Shared As ULongInt HL_Max, HL_Spread
Dim Shared As ULongInt HL_Stride(1 To HL_N), HL_Limit(1 To HL_N)  ' sampling beyond HL_Max
Dim Shared As Long HL_Ready

' A decimal environment variable, or Ndefault if it is unset.
Private Function HL_EnvCount(ByVal Cname As ZString Ptr, ByVal Ndefault As ULongInt) As ULongInt
  Dim As UByte Ptr P = Cast(UByte Ptr, HLC_getenv(Cname))
  If P = 0 Then Return Ndefault
  Dim As ULongInt Nvalue = 0
  Dim As Long Ic = 0
  While P[Ic] >= 48 And P[Ic] <= 57
    Nvalue = Nvalue * 10 + (P[Ic] - 48)
    Ic += 1
  Wend
  If Ic = 0 Or P[Ic] <> 0 Then
    Print "<harness> " & *Cname & " must be a decimal integer."
    End 2
  End If
  Return Nvalue
End Function

Private Sub HL_Init()
  HL_Ready = 1
  HL_Max = HL_EnvCount("GEF_ARGLOG_MAX", 100000)
  HL_Spread = HL_EnvCount("GEF_ARGLOG_SPREAD", 1)
End Sub

Private Sub HL_Flush(ByVal Id As Long)
  If HL_Len(Id) > 0 Then
    If HLC_write(HL_Fd(Id) - 1, @HL_Buf(Id, 0), HL_Len(Id)) <> HL_Len(Id) Then
      Print "<harness> arglog write failed."
      End 2
    End If
    HL_Len(Id) = 0
  End If
End Sub

Private Sub HL_PutC(ByVal Id As Long, ByVal C As UByte)
  If HL_Len(Id) >= HL_BUFSZ Then HL_Flush(Id)
  HL_Buf(Id, HL_Len(Id)) = C
  HL_Len(Id) += 1
End Sub

Private Sub HL_PutZ(ByVal Id As Long, ByVal Z As ZString Ptr)
  Dim As Long Ic = 0
  While Cast(UByte Ptr, Z)[Ic] <> 0
    HL_PutC(Id, Cast(UByte Ptr, Z)[Ic])
    Ic += 1
  Wend
End Sub

' Space, then V as exactly Ndig lowercase hex digits.
Private Sub HL_PutHex(ByVal Id As Long, ByVal V As ULongInt, ByVal Ndig As Long)
  HL_PutC(Id, 32)
  For Ic As Long = Ndig - 1 To 0 Step -1
    Dim As Long D = (V Shr (4 * Ic)) And 15
    HL_PutC(Id, IIf(D < 10, 48 + D, 87 + D))
  Next
End Sub

Private Sub HL_PutHexRaw(ByVal Id As Long, ByVal V As ULongInt, ByVal Ndig As Long)
  For Ic As Long = Ndig - 1 To 0 Step -1
    Dim As Long D = (V Shr (4 * Ic)) And 15
    HL_PutC(Id, IIf(D < 10, 48 + D, 87 + D))
  Next
End Sub

' Signed decimal, without a leading space.
Private Sub HL_PutDec(ByVal Id As Long, ByVal V As LongInt)
  Dim As UByte Digits(0 To 20)
  Dim As Long Nd = 0
  Dim As ULongInt U
  If V < 0 Then
    HL_PutC(Id, 45)
    U = CULngInt(-(V + 1)) + 1
  Else
    U = CULngInt(V)
  End If
  Do
    Digits(Nd) = 48 + (U Mod 10)
    Nd += 1
    U \= 10
  Loop While U > 0
  For Ic As Long = Nd - 1 To 0 Step -1
    HL_PutC(Id, Digits(Ic))
  Next
End Sub

Private Sub HL_Open(ByVal Id As Long, ByVal Cname As ZString Ptr, ByVal Cschema As ZString Ptr)
  HLC_mkdir("probes", &o755)
  HLC_mkdir("probes/arglog", &o755)
  Dim As ZString * 256 Cpath = "probes/arglog/"
  Dim As Long Ip = 14, Ic = 0
  While Cast(UByte Ptr, Cname)[Ic] <> 0 And Ip < 250
    Cpath[Ip] = Cast(UByte Ptr, Cname)[Ic]
    Ip += 1
    Ic += 1
  Wend
  Cpath[Ip] = 46 : Cpath[Ip + 1] = 116 : Cpath[Ip + 2] = 120  ' ".txt"
  Cpath[Ip + 3] = 116 : Cpath[Ip + 4] = 0
  ' O_WRONLY | O_CREAT | O_TRUNC (Linux)
  Dim As Long Ifd = HLC_open(@Cpath, &h241, &o644)
  If Ifd < 0 Then
    Print "<harness> cannot create " & Cpath
    End 2
  End If
  HL_Fd(Id) = Ifd + 1
  HL_PutZ(Id, "# arglog 1 ")
  HL_PutZ(Id, Cname)
  HL_PutC(Id, 32)
  HL_PutZ(Id, Cschema)
  HL_PutC(Id, 10)
End Sub

' Counts the call; returns its 1-based number n if it is logged, 0 otherwise. Logged: n <= K
' (K = GEF_ARGLOG_MAX) and, unless GEF_ARGLOG_SPREAD=0, every 2^j-th call for
' K*2^(j-1) < n <= K*2^j (about K/2 more records per doubling of the call count).
Private Function HL_Next(ByVal Id As Long) As ULongInt
  If HL_Ready = 0 Then HL_Init()
  HL_Calls(Id) += 1
  Dim As ULongInt N = HL_Calls(Id)
  If N <= HL_Max Then Return N
  If HL_Spread = 0 Or HL_Max = 0 Then Return 0
  If HL_Stride(Id) = 0 Then
    HL_Stride(Id) = 1
    HL_Limit(Id) = HL_Max
  End If
  If N > HL_Limit(Id) Then
    HL_Stride(Id) *= 2
    HL_Limit(Id) *= 2
  End If
  If N Mod HL_Stride(Id) = 0 Then Return N
  Return 0
End Function

' "<seq> <step> <pass> <event> <file>:<line>" (the file without its directory).
Private Sub HL_Begin(ByVal Id As Long, ByVal Cname As ZString Ptr, ByVal Cschema As ZString Ptr, _
                     ByVal Nseq As ULongInt, ByVal Cfile As ZString Ptr, ByVal Iline As Long)
  If HL_Fd(Id) = 0 Then HL_Open(Id, Cname, Cschema)
  HL_PutDec(Id, Nseq)
  HL_PutC(Id, 32) : HL_PutDec(Id, Harness_Step)
  HL_PutC(Id, 32) : HL_PutDec(Id, Harness_Pass)
  HL_PutC(Id, 32) : HL_PutDec(Id, Harness_Event)
  HL_PutC(Id, 32)
  Dim As Long Ibase = 0, Ic = 0
  While Cast(UByte Ptr, Cfile)[Ic] <> 0
    If Cast(UByte Ptr, Cfile)[Ic] = 47 Or Cast(UByte Ptr, Cfile)[Ic] = 92 Then Ibase = Ic + 1
    Ic += 1
  Wend
  HL_PutZ(Id, Cfile + Ibase)
  HL_PutC(Id, 58)
  HL_PutDec(Id, Iline)
End Sub

Private Sub HL_End(ByVal Id As Long)
  HL_PutC(Id, 10)
End Sub

Private Sub HL_F32(ByVal Id As Long, ByVal X As Single)
  HL_PutHex(Id, *Cast(ULong Ptr, @X), 8)
End Sub

Private Sub HL_F64(ByVal Id As Long, ByVal X As Double)
  HL_PutHex(Id, *Cast(ULongInt Ptr, @X), 16)
End Sub

Private Sub HL_I64(ByVal Id As Long, ByVal X As LongInt)
  HL_PutHex(Id, CULngInt(X), 16)
End Sub

Private Sub HL_U8(ByVal Id As Long, ByVal X As UByte)
  HL_PutHex(Id, X, 2)
End Sub

' The bytes of a string in hex, "-" if it is empty.
Private Sub HL_Str(ByVal Id As Long, ByRef S As String)
  HL_PutC(Id, 32)
  If Len(S) = 0 Then
    HL_PutC(Id, 45)
  Else
    For Ic As Long = 0 To Len(S) - 1
      HL_PutHexRaw(Id, S[Ic], 2)
    Next
  End If
End Sub

' "<count>" or "<count>:<v1>,<v2>,..." for elements Ifirst..Ilast of a Single array.
Private Sub HL_F32List(ByVal Id As Long, A() As Single, ByVal Ifirst As LongInt, _
                       ByVal Ilast As LongInt)
  HL_PutC(Id, 32)
  If Ilast > UBound(A) Then Ilast = UBound(A)
  If Ilast < Ifirst Then
    HL_PutDec(Id, 0)
    Exit Sub
  End If
  HL_PutDec(Id, Ilast - Ifirst + 1)
  For I As LongInt = Ifirst To Ilast
    HL_PutC(Id, IIf(I = Ifirst, 58, 44))
    Dim As Single X = A(I)
    HL_PutHexRaw(Id, *Cast(ULong Ptr, @X), 8)
  Next
End Sub

' FNV-style hash h = (h Xor bits) * &h100000001B3 over the bits of A(LBound..UBound).
Private Sub HL_F32Hash(ByVal Id As Long, A() As Single)
  Dim As ULongInt H = &hCBF29CE484222325ull
  For I As LongInt = LBound(A) To UBound(A)
    Dim As Single X = A(I)
    H = (H Xor *Cast(ULong Ptr, @X)) * &h100000001B3ull
  Next
  HL_PutHex(Id, H, 16)
End Sub

Private Sub HL_Final() Destructor
  If HL_Ready = 0 Then Exit Sub
  For Id As Long = 1 To HL_N
    If HL_Fd(Id) <> 0 Then
      HL_Flush(Id)
      HLC_close(HL_Fd(Id) - 1)
      HL_Fd(Id) = 0
    End If
  Next
  ' Total calls per function and site, logged or not.
  HLC_mkdir("probes", &o755)
  HLC_mkdir("probes/arglog", &o755)
  Dim As Long Ifd = HLC_open("probes/arglog/_counts.txt", &h241, &o644)
  If Ifd < 0 Then Exit Sub
  HL_Fd(1) = Ifd + 1
  HL_Len(1) = 0
  HL_PutZ(1, "# arglog 1 _counts name calls max spread")
  HL_PutC(1, 10)
{count_lines}  HL_Flush(1)
  HLC_close(Ifd)
  HL_Fd(1) = 0
End Sub
"""


def _runtime(functions: list[Function]) -> str:
    n_fun = len(functions)
    names = [fn.name for fn in functions] + [s.name for s in SITES]
    count_lines = "".join(
        f'  HL_PutZ(1, "{name} ") : HL_PutDec(1, HL_Calls({i})) : HL_PutC(1, 32) : '
        f"HL_PutDec(1, HL_Max) : HL_PutC(1, 32) : HL_PutDec(1, HL_Spread) : HL_PutC(1, 10)\n"
        for i, name in enumerate(names, start=1)
    )
    return _RUNTIME.format(
        n_ids=len(names), n_fun=n_fun, n_sites=len(SITES), count_lines=count_lines
    )


def _site_in(site: Site, ident: int) -> str:
    lines = [
        _LICENSE.rstrip("\n"),
        f'\' Harness patch "arglog": entry of site {site.name} (GEF.bas:{site.line_in}).',
        "#ifdef GEF_ARGLOG",
        f"HL_SiteSeq({ident}) = HL_Next({ident})",
        f"If HL_SiteSeq({ident}) <> 0 Then",
        f'  HL_Begin({ident}, "{site.name}", "{_site_schema(site)}", HL_SiteSeq({ident}), '
        f'"GEF.bas", {site.line_in + 1})',
    ]
    lines += [f"  {_site_put(f, ident)}" for f in site.fields_in]
    lines += ["End If", "#endif", ""]
    return "\n".join(lines)


def _site_out(site: Site, ident: int) -> str:
    lines = [
        _LICENSE.rstrip("\n"),
        f'\' Harness patch "arglog": exit of site {site.name} (GEF.bas:{site.line_out}).',
        "#ifdef GEF_ARGLOG",
        f"If HL_SiteSeq({ident}) <> 0 Then",
    ]
    lines += [f"  {_site_put(f, ident)}" for f in site.fields_out]
    lines += [f"  HL_End({ident})", f"  HL_SiteSeq({ident}) = 0", "End If", "#endif", ""]
    return "\n".join(lines)


def _site_put(f: SiteField, ident: int) -> str:
    if f.log_type == "str":
        return f"HL_Str({ident}, {f.expr})"
    if f.log_type == "f32list":
        side = "light" if "light" in f.expr else "heavy"
        return f"HL_F32List({ident}, {f.expr}(), 1, Ig2_{side})"
    if f.log_type == "f32hash":
        return f"HL_F32Hash({ident}, {f.expr}())"
    return f"{_PUT[f.log_type]}({ident}, {f.expr})"


def _runtime_bi(functions: list[Function]) -> str:
    return "".join(
        [
            _LICENSE,
            f'\' Harness patch "arglog" (M5.1), part 1, included at GEF.bas:{RUNTIME_LINE}: the\n'
            "' logging runtime (also used by the wrapper in DCLbranchingJEFF33.bas and the\n"
            "' sites).\n"
            "' See harness/ARGLOG.md. Generated by python3 -m harness.arglog_patch; do not edit.\n",
            "\n#ifdef GEF_ARGLOG\n",
            _runtime(functions),
            "\n#endif\n",
        ]
    )


def _wrappers_bi(functions: list[Function]) -> str:
    gef_functions = [fn for fn in functions if fn.file == "GEF.bas"]
    parts = [
        _LICENSE,
        f'\' Harness patch "arglog" (M5.1), part 2, included at GEF.bas:{WRAPPERS_LINE}. With\n'
        "' -d GEF_ARGLOG every call of the functions of MILESTONE_5_PLAN.md section 3 goes\n"
        "' through a wrapper that logs its arguments, ByRef values and result; see\n"
        "' harness/ARGLOG.md. Generated by python3 -m harness.arglog_patch; do not edit.\n",
        "\n#ifdef GEF_ARGLOG\n",
        "\n' Wrappers (each calls the original once and returns its result unchanged).\n",
    ]
    parts += [
        "\n" + _wrapper(fn, i) for i, fn in enumerate(functions, start=1) if fn.file == "GEF.bas"
    ]
    parts.append("\n' Every later call goes through its wrapper.\n")
    parts += [_macro(fn) for fn in gef_functions]
    parts.append("\n#endif\n")
    return "".join(parts)


def _dcl_wrapper_bi(functions: list[Function]) -> str:
    ident, fn = next((i, f) for i, f in enumerate(functions, start=1) if f.file == DCL_FILE)
    return (
        _LICENSE
        + f'\' Harness patch "arglog": wrapper of {fn.name} ({DCL_FILE}:{DCL_WRAPPER_LINE}).\n'
        + "#ifdef GEF_ARGLOG\n"
        + _wrapper(fn, ident)
        + "#endif\n"
    )


def _dcl_macro_bi(functions: list[Function]) -> str:
    fn = next(f for f in functions if f.file == DCL_FILE)
    return (
        _LICENSE
        + f'\' Harness patch "arglog": macro of {fn.name} ({DCL_FILE}:{DCL_MACRO_LINE}).\n'
        + "#ifdef GEF_ARGLOG\n"
        + _macro(fn)
        + "#endif\n"
    )


def _expect_blank(lines: list[str], line: int, file: str) -> None:
    if lines[line - 1].strip() != "":
        raise HarnessError(f"{file}:{line} is not blank: {lines[line - 1]!r}")


def _line_before(line: int) -> str:
    """The directive that gives the next source line the number ``line``.

    After a ``#endif`` (unlike after an ``#include``), fbc's ``#line N`` makes the following line
    N + 1; established with ``__LINE__`` and by comparing the emitted C (``#line`` markers).
    """
    return f"#line {line - 1}\n"


def _patched_gef(lines: list[str], functions: list[Function]) -> list[str]:
    _expect_blank(lines, RUNTIME_LINE, "GEF.bas")
    _expect_blank(lines, WRAPPERS_LINE, "GEF.bas")
    for site in SITES:
        _expect_blank(lines, site.line_in, "GEF.bas")
        _expect_blank(lines, site.line_out, "GEF.bas")
    before: dict[int, list[str]] = {}
    after: dict[int, list[str]] = {}
    for fn in functions:
        if fn.file != "GEF.bas":
            continue
        before.setdefault(fn.def_first, []).extend(
            ["#ifdef GEF_ARGLOG\n", f"#undef {fn.name}\n", "#endif\n", _line_before(fn.def_first)]
        )
        after.setdefault(fn.def_last, []).extend(
            [
                "#ifdef GEF_ARGLOG\n",
                *_macro(fn).splitlines(keepends=True),
                "#endif\n",
                _line_before(fn.def_last + 1),
            ]
        )
    replace = {
        RUNTIME_LINE: '#include "harness_arglog.bi"\n',
        WRAPPERS_LINE: '#include "harness_arglog_wrappers.bi"\n',
    }
    for site in SITES:
        replace[site.line_in] = f'#include "harness_arglog_{site.name}_in.bi"\n'
        replace[site.line_out] = f'#include "harness_arglog_{site.name}_out.bi"\n'
    out: list[str] = []
    for no, text in enumerate(lines, start=1):
        out += before.get(no, [])
        out.append(replace.get(no, text))
        out += after.get(no, [])
    return out


def _patched_dcl(lines: list[str]) -> list[str]:
    _expect_blank(lines, DCL_WRAPPER_LINE, DCL_FILE)
    _expect_blank(lines, DCL_MACRO_LINE, DCL_FILE)
    out = list(lines)
    out[DCL_WRAPPER_LINE - 1] = '#include "harness_arglog_dcl.bi"\n'
    out[DCL_MACRO_LINE - 1] = '#include "harness_arglog_dcl_on.bi"\n'
    return out


def _diff(old: list[str], new: list[str], name: str) -> str:
    return "".join(
        difflib.unified_diff(old, new, f"a/{name}", f"b/{name}", n=2, lineterm="\n")
    ).replace(f"--- a/{name}\t\n", f"--- a/{name}\n")


def _new_file(name: str, text: str) -> str:
    lines = text.splitlines(keepends=True)
    head = f"--- /dev/null\n+++ b/{name}\n@@ -0,0 +1,{len(lines)} @@\n"
    return head + "".join("+" + ln for ln in lines)


def generate(source_dir: Path = GEF_SOURCE_DIR) -> str:
    functions = discover(source_dir)
    if [fn.name for fn in functions if fn.file == DCL_FILE] != [DCL_FUNCTION]:
        raise HarnessError("exactly one function is expected in the branching file")
    gef = _read_lines(source_dir, "GEF.bas")
    dcl = _read_lines(source_dir, DCL_FILE)
    n_fun = len(functions)
    parts = [
        _diff(gef, _patched_gef(gef, functions), "GEF.bas"),
        _diff(dcl, _patched_dcl(dcl), DCL_FILE),
        _new_file("harness_arglog.bi", _runtime_bi(functions)),
        _new_file("harness_arglog_wrappers.bi", _wrappers_bi(functions)),
        _new_file("harness_arglog_dcl.bi", _dcl_wrapper_bi(functions)),
        _new_file("harness_arglog_dcl_on.bi", _dcl_macro_bi(functions)),
    ]
    for k, site in enumerate(SITES, start=n_fun + 1):
        parts.append(_new_file(f"harness_arglog_{site.name}_in.bi", _site_in(site, k)))
        parts.append(_new_file(f"harness_arglog_{site.name}_out.bi", _site_out(site, k)))
    return "".join(parts)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m harness.arglog_patch", description=__doc__)
    parser.add_argument("--check", action="store_true", help="compare with the committed patch")
    ns = parser.parse_args(argv)
    try:
        text = generate()
    except HarnessError as exc:
        print(f"harness.arglog_patch: {exc}", file=sys.stderr)
        return 2
    if ns.check:
        if not PATCH_FILE.is_file() or PATCH_FILE.read_text(encoding="latin-1") != text:
            print(f"harness.arglog_patch: {PATCH_FILE} is stale; regenerate it", file=sys.stderr)
            return 1
        print(f"{PATCH_FILE} is current")
        return 0
    PATCH_FILE.write_text(text, encoding="latin-1")
    print(f"wrote {PATCH_FILE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
