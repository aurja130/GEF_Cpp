# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""ENDF-6 tapes written by GEF (and the library tapes): parser, observables, round-trip (M2.2).

Files
-----
``work/ENDF/GEFY_<Z>_<A>_<n|s>.dat`` is a tape (``ENDF.bas``, opened ``For Append``, so a
file may hold several tapes), ``work/tmp/CUMU<thread>.dat`` is a *fragment*: the cumulative-yield
MF8/MT459 records that GEF buffers during the run and copies into the tape at the last energy
(``DCLendf.bas:TestprintC``). A fragment starts with the SEND of the (absent) MT454 section and
has no TPID, no MF1 and, in the buffer a run leaves behind, no TEND. The parser reads both.

Record layout (80 columns): six 11-column fields (1-66), then MAT (67-70), MF (71-72), MT
(73-75), NS (76-80). Every line of a file must have exactly 80 characters.

Parsed form
-----------
``EndfFile`` holds ``EndfTape`` objects (each closed by the TEND card, MAT = -1; the last tape
of a fragment has none). A tape is a list of *entries*: ``Card`` (a record that is not part of
a section: TPID, FEND, MEND, TEND, a SEND without section) or ``Section`` (the data records of
one MAT/MF/MT, with its SEND). A section's ``content`` is typed:

* ``Mt451``: MF1/MT451 HEAD and three CONT records, ``NWD`` description lines, ``NXC``
  dictionary records (MF, MT, NC, MOD).
* ``Yields``: MF8/MT454 (independent) and MF8/MT459 (cumulative) yields: a HEAD and one LIST
  per energy. A LIST holds ``NFP`` fission products as ``ZAFP, FPS, Y, DY``.
* ``RawLines``: any other section, the 66-column bodies verbatim.

Number fields
-------------
A numeric field is stored as its value (``float`` or ``int``). Fields whose text the canonical
formatter (:func:`format_float`: GEF's ``CDouble``, seven significant digits, one-digit
exponent for 1e-9 <= |x| < 1e10 and five decimals with a two-digit exponent otherwise; integers
right-aligned in 11 columns) cannot reproduce keep their text in an ``over`` dictionary: blank
fields, an integer written as a float (``59`` in a float field), ``-0.000000+0``, three-digit
exponents, non-normalised mantissas. On the real data the canonical formatter reproduces every
field. The control columns are canonical too (``MAT``, ``MF``, ``MT`` fixed width, ``NS``
sequential within a section); exceptions are recorded per card in ``Section.ns_over``.

Observables (``Key.file`` = run-relative path)
----------------------------------------------
Every key has ``group`` ``tape<k>`` (1-based tape number), extended with ``#<n>`` for the n-th
repeated section of the same MF/MT in one tape (``tape1#2``).

``TPID`` ``text``: the tape identification line.
``MF1/MT451``: header numbers ``ZA AWR LRP LFI NLIB NMOD ELIS STA LIS LISO N1 NFOR AWI EMAX LREL
N2 NSUB NVER TEMP C2 LDRV N3 NWD NXC`` (``int`` or ``float`` as in the record), the description
lines ``TEXT`` (``index`` = (line number,)), and the dictionary ``NC`` and ``MOD`` with
``index`` = (MF, MT). ``NC`` is the length of each listed section in records, which changes
with the number of nuclides written.
``MF8/MT454`` and ``MF8/MT459``: group ``tape<k>`` has the HEAD numbers ``ZA AWR LE L2 N1 N2``;
for every energy the group is ``tape<k>/E=<energy as written>#<n>`` (``<n>`` the occurrence of
that exact text in the section) with the LIST numbers ``E C2 L1 L2 NPL NFP`` and, per fission
product, ``Y`` and ``DY`` indexed by ``(ZA, FPS)``. A repeated ``(ZA, FPS)`` gets a third index
``2, 3, ...``.
``MF<f>/MT<t>`` (any other section): the lines as ``TEXT`` indexed by (line number,).

``PATTERNS`` also cover the CUMU fragments. Nothing in an ENDF file is a time stamp (the
``2026`` in the library tapes is a record-number field), so nothing is masked.
"""

from __future__ import annotations

import re
from collections import Counter
from collections.abc import Iterator
from dataclasses import dataclass, field
from pathlib import Path

from compare.model import Key, Value
from compare.parsers import ParseError

__all__ = [
    "PATTERNS",
    "Card",
    "Cont",
    "EndfFile",
    "EndfTape",
    "ListRecord",
    "Mt451",
    "Nuclide",
    "RawLines",
    "Section",
    "Tape",
    "Yields",
    "format_float",
    "mt454_tapes",
    "observables",
    "observables_from",
    "parse_endf_float",
    "parse_text",
    "read",
    "read_mt454",
    "render",
    "roundtrip",
]

PATTERNS: tuple[str, ...] = ("work/ENDF/*.dat", "work/tmp/CUMU*.dat")

_WIDTH = 80
_BODY = 66
_FIELD = 11
_NFIELDS = 6
_FLOAT_RE = re.compile(r"^([+-]?(?:\d+\.?\d*|\.\d+))(?:[eEdD]?([+-]?\d+))?$")
_CANON_RE = re.compile(r"[ -][1-9]\.\d{6}(?:\+\d|-[1-9])|[ -][1-9]\.\d{5}(?:\+[1-9]\d|-[1-9]\d)")
_ZERO_TEXT = " 0.000000+0"

_MT451_NAMES = (
    ("ZA", "AWR", "LRP", "LFI", "NLIB", "NMOD"),
    ("ELIS", "STA", "LIS", "LISO", "N1", "NFOR"),
    ("AWI", "EMAX", "LREL", "N2", "NSUB", "NVER"),
    ("TEMP", "C2", "LDRV", "N3", "NWD", "NXC"),
)
_YIELD_HEAD_NAMES = ("ZA", "AWR", "LE", "L2", "N1", "N2")
_LIST_HEAD_NAMES = ("E", "C2", "L1", "L2", "NPL", "NFP")
_YIELD_MTS = {(8, 454), (8, 459)}


# --------------------------------------------------------------------------------------------
# numbers
# --------------------------------------------------------------------------------------------


def parse_endf_float(field: str) -> float:
    """Parse an ENDF number: ``1.234567-5`` (no ``E``), ``1.2E-5``, plain, or blank (0)."""
    s = field.strip()
    if not s:
        return 0.0
    m = _FLOAT_RE.match(s)
    if m is None:
        raise ValueError(f"not an ENDF number: {field!r}")
    mant, exp = m.groups()
    return float(mant + ("e" + exp if exp else ""))


def format_float(x: float) -> str:
    """GEF's ``CDouble`` text of ``x``: ``" 1.234567+5"``, ``"-1.23457-12"``."""
    if x == 0.0:
        return _ZERO_TEXT
    sign = "-" if x < 0.0 else " "
    ax = abs(x)
    mant, _, exp = f"{ax:.6e}".partition("e")
    e = int(exp)
    if -9 <= e <= 9:
        return f"{sign}{mant}{'+' if e >= 0 else '-'}{abs(e)}"
    mant, _, exp = f"{ax:.5e}".partition("e")
    e = int(exp)
    return f"{sign}{mant}{'+' if e >= 0 else '-'}{abs(e):02d}"


def _float_field(text: str) -> tuple[float, bool]:
    """(value, text is what ``format_float`` writes for that value)."""
    if text == _ZERO_TEXT:
        return 0.0, True
    if _CANON_RE.fullmatch(text) is not None:
        k = 3 if text[-3] in "+-" else 2
        return float(f"{text[:-k]}e{text[-k:]}"), True
    return parse_endf_float(text), False


def _int_text(n: int) -> str:
    return f"{n:11d}"


# --------------------------------------------------------------------------------------------
# records
# --------------------------------------------------------------------------------------------


@dataclass(slots=True)
class Cont:
    """A HEAD/CONT/LIST-head/dictionary record: ``C1, C2`` (float) and ``L1, L2, N1, N2`` (int).

    ``over`` maps a field number (0-5) to its verbatim 11-column text when the canonical
    formatter would write something else.
    """

    values: tuple[float, float, int, int, int, int]
    over: dict[int, str] = field(default_factory=lambda: {})

    def text(self, i: int) -> str:
        """The 11-column text of field ``i`` as it is (or would be) written."""
        t = self.over.get(i)
        if t is not None:
            return t
        v = self.values[i]
        return format_float(v) if i < 2 else _int_text(int(v))

    def body(self) -> str:
        return "".join(self.text(i) for i in range(_NFIELDS))


@dataclass(slots=True)
class ListRecord:
    """A LIST record of MF8: ``head.values[4]`` = NPL numbers, then ``pad`` (verbatim text of
    the unused slots in the last 66-column line)."""

    head: Cont
    values: list[float]
    over: dict[int, str]
    pad: str

    def bodies(self, cache: dict[float, str]) -> list[str]:
        texts: list[str] = []
        get = cache.get
        for v in self.values:
            t = get(v)
            if t is None:
                t = cache[v] = format_float(v)
            texts.append(t)
        for i, t in self.over.items():
            texts[i] = t
        s = "".join(texts) + self.pad
        return [self.head.body()] + [s[i : i + _BODY] for i in range(0, len(s), _BODY)]


@dataclass(slots=True)
class Mt451:
    head: Cont
    cont2: Cont
    cont3: Cont
    cont4: Cont
    text: list[str]
    dictionary: list[Cont]
    extra: list[str]


@dataclass(slots=True)
class Yields:
    head: Cont
    lists: list[ListRecord]


@dataclass(slots=True)
class RawLines:
    bodies: list[str]


type Content = Mt451 | Yields | RawLines


@dataclass(slots=True)
class Card:
    """A record outside any section, kept verbatim: 66-column body and the 14 control columns."""

    body: str
    mat: int
    mf: int
    mt: int
    ns: int
    ctl_text: str | None = None

    def line(self) -> str:
        ctl = self.ctl_text
        if ctl is None:
            ctl = f"{self.mat:4d}{self.mf:2d}{self.mt:3d}{self.ns:5d}"
        return self.body + ctl


@dataclass(slots=True)
class Section:
    """The data records of one MAT/MF/MT, followed by their SEND card (None when absent)."""

    mat: int
    mf: int
    mt: int
    content: Content
    ns0: int
    ns_over: dict[int, str]
    send: Card | None = None
    lineno: int = 1

    def lines(self) -> list[str]:
        bodies = _content_bodies(self.content)
        canon = f"{self.mat:4d}{self.mf:2d}{self.mt:3d}"
        over = self.ns_over
        ns0 = self.ns0
        out = [b + over.get(i, f"{canon}{ns0 + i:5d}") for i, b in enumerate(bodies)]
        if self.send is not None:
            out.append(self.send.line())
        return out


type Entry = Card | Section


@dataclass(slots=True)
class EndfTape:
    entries: list[Entry] = field(default_factory=lambda: [])

    def sections(self, mf: int, mt: int) -> list[Section]:
        return [e for e in self.entries if isinstance(e, Section) and e.mf == mf and e.mt == mt]


@dataclass(slots=True)
class EndfFile:
    """A parsed file. ``render`` writes exactly the bytes ``parse_text`` read."""

    tapes: list[EndfTape] = field(default_factory=lambda: [])
    eol: str = "\n"
    final_newline: bool = True


def _content_bodies(content: Content) -> list[str]:
    if isinstance(content, RawLines):
        return content.bodies
    if isinstance(content, Yields):
        cache: dict[float, str] = {}
        out = [content.head.body()]
        for lst in content.lists:
            out.extend(lst.bodies(cache))
        return out
    out = [content.head.body(), content.cont2.body(), content.cont3.body(), content.cont4.body()]
    out.extend(content.text)
    out.extend(c.body() for c in content.dictionary)
    out.extend(content.extra)
    return out


# --------------------------------------------------------------------------------------------
# parsing
# --------------------------------------------------------------------------------------------


def _fail(name: str, lineno: int, message: str) -> ParseError:
    return ParseError(f"{name}:{lineno}: {message}")


def _control(line: str, name: str, lineno: int) -> tuple[int, int, int]:
    try:
        return int(line[66:70]), int(line[70:72]), int(line[72:75])
    except ValueError:
        raise _fail(
            name, lineno, f"MAT/MF/MT columns 67-75 are not integers: {line[66:75]!r}"
        ) from None


def _card(line: str, name: str, lineno: int) -> Card:
    mat, mf, mt = _control(line, name, lineno)
    try:
        ns = int(line[75:80])
    except ValueError:
        raise _fail(name, lineno, f"NS columns 76-80 are not an integer: {line[75:80]!r}") from None
    card = Card(line[:_BODY], mat, mf, mt, ns)
    if card.line() != line:
        card.ctl_text = line[_BODY:]
    return card


def _cont(body: str, name: str, lineno: int) -> Cont:
    vals: list[float | int] = []
    over: dict[int, str] = {}
    for i in range(_NFIELDS):
        t = body[i * _FIELD : (i + 1) * _FIELD]
        try:
            if i < 2:
                v, ok = _float_field(t)
                vals.append(v)
                if not ok:
                    over[i] = t
            else:
                n = int(t) if t.strip() else 0
                vals.append(n)
                if _int_text(n) != t:
                    over[i] = t
        except ValueError:
            raise _fail(name, lineno, f"field {i + 1} is not a number: {t!r}") from None
    c1, c2, l1, l2, n1, n2 = vals
    return Cont((float(c1), float(c2), int(l1), int(l2), int(n1), int(n2)), over)


def _parse_list(
    bodies: list[str], pos: int, name: str, first: int, cache: dict[str, float], bad: set[str]
) -> tuple[ListRecord, int]:
    head = _cont(bodies[pos], name, first + pos)
    npl, nfp = head.values[4], head.values[5]
    if npl < 0 or nfp < 0 or npl != 4 * nfp:
        raise _fail(
            name, first + pos, f"LIST at E={head.text(0).strip()} has NPL={npl} != 4*NFP={4 * nfp}"
        )
    nlines = -(-npl // _NFIELDS)
    end = pos + 1 + nlines
    if end > len(bodies):
        raise _fail(name, first + pos, f"truncated LIST at E={head.text(0).strip()}")
    s = "".join(bodies[pos + 1 : end])
    values: list[float] = []
    over: dict[int, str] = {}
    get = cache.get
    for i in range(npl):
        t = s[i * _FIELD : (i + 1) * _FIELD]
        v = get(t)
        if v is None:
            try:
                v, ok = _float_field(t)
            except ValueError:
                raise _fail(name, first + pos + 1 + i // _NFIELDS, f"not a number: {t!r}") from None
            cache[t] = v
            if not ok:
                bad.add(t)
        values.append(v)
        if bad and t in bad:
            over[i] = t
    return ListRecord(head, values, over, s[npl * _FIELD :]), end


def _parse_yields(bodies: list[str], name: str, first: int) -> Yields:
    head = _cont(bodies[0], name, first)
    lists: list[ListRecord] = []
    cache: dict[str, float] = {}
    bad: set[str] = set()
    pos = 1
    while pos < len(bodies):
        lst, pos = _parse_list(bodies, pos, name, first, cache, bad)
        lists.append(lst)
    return Yields(head, lists)


def _parse_mt451(bodies: list[str], name: str, first: int) -> Mt451:
    if len(bodies) < 4:
        raise _fail(name, first, "MF1/MT451 has fewer than 4 records")
    conts = [_cont(bodies[i], name, first + i) for i in range(4)]
    nwd, nxc = conts[3].values[4], conts[3].values[5]
    if nwd < 0 or nxc < 0 or 4 + nwd + nxc > len(bodies):
        raise _fail(
            name, first + 3, f"MF1/MT451 announces NWD={nwd}, NXC={nxc}; section is shorter"
        )
    text = bodies[4 : 4 + nwd]
    d0 = 4 + nwd
    dictionary = [_cont(bodies[d0 + i], name, first + d0 + i) for i in range(nxc)]
    return Mt451(conts[0], conts[1], conts[2], conts[3], text, dictionary, bodies[d0 + nxc :])


def _make_section(
    seg: list[str], pref: str, mat: int, mf: int, mt: int, name: str, first: int
) -> Section:
    try:
        ns0 = int(seg[0][75:80])
    except ValueError:
        ns0 = 0
    canon = f"{mat:4d}{mf:2d}{mt:3d}"
    ns_over: dict[int, str] = {}
    if pref == canon:
        for i, ln in enumerate(seg):
            if ln[_BODY:] != f"{canon}{ns0 + i:5d}":
                ns_over[i] = ln[_BODY:]
    else:
        ns_over = {i: ln[_BODY:] for i, ln in enumerate(seg)}
    bodies = [ln[:_BODY] for ln in seg]
    content: Content
    if (mf, mt) == (1, 451):
        content = _parse_mt451(bodies, name, first)
    elif (mf, mt) in _YIELD_MTS:
        content = _parse_yields(bodies, name, first)
    else:
        content = RawLines(bodies)
    return Section(mat, mf, mt, content, ns0, ns_over, None, first)


def parse_text(text: str, name: str = "<endf>") -> EndfFile:
    """Parse the text of an ENDF file (``name`` is only used in error messages)."""
    eol = "\r\n" if "\r\n" in text else "\n"
    if "\r" in text.replace("\r\n", ""):
        raise _fail(name, 1, "stray carriage return")
    lines = text.split(eol)
    final_newline = True
    if lines[-1] == "":
        lines.pop()
    else:
        final_newline = False
    out = EndfFile(eol=eol, final_newline=final_newline)
    for i, line in enumerate(lines):
        if len(line) != _WIDTH:
            raise _fail(name, i + 1, f"line has {len(line)} characters, expected {_WIDTH}")
    n = len(lines)
    tape = EndfTape()
    i = 0
    while i < n:
        line = lines[i]
        pref = line[66:75]
        mat, mf, mt = _control(line, name, i + 1)
        if mf > 0 and mt > 0:
            j = i + 1
            while j < n and lines[j][66:75] == pref:
                j += 1
            sec = _make_section(lines[i:j], pref, mat, mf, mt, name, i + 1)
            i = j
            if i < n:
                m2, f2, t2 = _control(lines[i], name, i + 1)
                if t2 == 0 and m2 == mat and f2 == mf:
                    sec.send = _card(lines[i], name, i + 1)
                    i += 1
            tape.entries.append(sec)
            continue
        card = _card(line, name, i + 1)
        tape.entries.append(card)
        i += 1
        if mat == -1:
            out.tapes.append(tape)
            tape = EndfTape()
    if tape.entries:
        out.tapes.append(tape)
    return out


def read(path: Path) -> EndfFile:
    """Parse the ENDF file at ``path`` (latin-1 text)."""
    return parse_text(path.read_bytes().decode("latin-1"), str(path))


# --------------------------------------------------------------------------------------------
# writing
# --------------------------------------------------------------------------------------------


def render(endf: EndfFile) -> str:
    """The text of a parsed file, written back from the parsed form."""
    out: list[str] = []
    for tape in endf.tapes:
        for entry in tape.entries:
            if isinstance(entry, Card):
                out.append(entry.line())
            else:
                out.extend(entry.lines())
    text = endf.eol.join(out)
    if endf.final_newline and out:
        text += endf.eol
    return text


def roundtrip(path: Path) -> bytes:
    """Parse ``path`` and write it back; equals the file bytes."""
    return render(read(path)).encode("latin-1")


# --------------------------------------------------------------------------------------------
# observables
# --------------------------------------------------------------------------------------------


class _Dedup:
    """Appends an occurrence number to an index tuple that was already used."""

    def __init__(self) -> None:
        self._seen: Counter[tuple[int, ...]] = Counter()

    def __call__(self, index: tuple[int, ...]) -> tuple[int, ...]:
        self._seen[index] += 1
        n = self._seen[index]
        return index if n == 1 else (*index, n)


def _cont_observables(
    cont: Cont, names: tuple[str, ...], rel: str, block: str, group: str
) -> Iterator[tuple[Key, Value]]:
    for name, value in zip(names, cont.values, strict=True):
        yield Key(rel, block, group, name), value


def _yield_observables(
    sec: Section, rel: str, block: str, group: str
) -> Iterator[tuple[Key, Value]]:
    content = sec.content
    assert isinstance(content, Yields)
    yield from _cont_observables(content.head, _YIELD_HEAD_NAMES, rel, block, group)
    seen: Counter[str] = Counter()
    for lst in content.lists:
        label = lst.head.text(0).strip()
        seen[label] += 1
        egroup = f"{group}/E={label}#{seen[label]}"
        yield from _cont_observables(lst.head, _LIST_HEAD_NAMES, rel, block, egroup)
        dedup = _Dedup()
        v = lst.values
        for j in range(0, len(v), 4):
            idx = dedup((int(v[j]), int(v[j + 1])))
            yield Key(rel, block, egroup, "Y", idx), v[j + 2]
            yield Key(rel, block, egroup, "DY", idx), v[j + 3]


def _mt451_observables(
    sec: Section, rel: str, block: str, group: str
) -> Iterator[tuple[Key, Value]]:
    content = sec.content
    assert isinstance(content, Mt451)
    for cont, names in zip(
        (content.head, content.cont2, content.cont3, content.cont4), _MT451_NAMES, strict=True
    ):
        yield from _cont_observables(cont, names, rel, block, group)
    for i, line in enumerate((*content.text, *content.extra), 1):
        yield Key(rel, block, group, "TEXT", (i,)), line.rstrip()
    dedup = _Dedup()
    for d in content.dictionary:
        idx = dedup((d.values[2], d.values[3]))
        yield Key(rel, block, group, "NC", idx), d.values[4]
        yield Key(rel, block, group, "MOD", idx), d.values[5]


def _tape_observables(tape: EndfTape, rel: str, k: int) -> Iterator[tuple[Key, Value]]:
    first = tape.entries[0] if tape.entries else None
    if isinstance(first, Card) and first.mf == 0 and first.mt == 0 and first.mat >= 0:
        yield Key(rel, "TPID", f"tape{k}", "text"), first.body.rstrip()
    seen: Counter[tuple[int, int]] = Counter()
    for entry in tape.entries:
        if not isinstance(entry, Section):
            continue
        seen[entry.mf, entry.mt] += 1
        n = seen[entry.mf, entry.mt]
        group = f"tape{k}" if n == 1 else f"tape{k}#{n}"
        block = f"MF{entry.mf}/MT{entry.mt}"
        content = entry.content
        if isinstance(content, Yields):
            yield from _yield_observables(entry, rel, block, group)
        elif isinstance(content, Mt451):
            yield from _mt451_observables(entry, rel, block, group)
        else:
            for i, body in enumerate(content.bodies, 1):
                yield Key(rel, block, group, "TEXT", (i,)), body.rstrip()


def observables_from(endf: EndfFile, rel: str) -> Iterator[tuple[Key, Value]]:
    """All observables of a parsed file; ``rel`` is the run-relative path (``Key.file``)."""
    for k, tape in enumerate(endf.tapes, 1):
        yield from _tape_observables(tape, rel, k)


def observables(path: Path, rel: str) -> Iterator[tuple[Key, Value]]:
    """All observables of the ENDF file at ``path``; ``rel`` is the run-relative path."""
    return observables_from(read(path), rel)


# --------------------------------------------------------------------------------------------
# MT454 view (harness.minicheck)
# --------------------------------------------------------------------------------------------


@dataclass(frozen=True)
class Nuclide:
    """One fission product: ``za`` = 1000*Z + A, isomeric ``state`` (FPS), yield, uncertainty."""

    za: int
    state: int
    y: float
    dy: float

    @property
    def z(self) -> int:
        return self.za // 1000

    @property
    def a(self) -> int:
        return self.za % 1000


# energy [eV] -> nuclides, in file order
type Tape = dict[float, list[Nuclide]]


def mt454_tapes(text: str, where: str = "<text>") -> list[Tape]:
    """The MF8/MT454 yields of every tape of ``text``, ``{energy: [Nuclide, ...]}`` each."""
    out: list[Tape] = []
    for tape in parse_text(text, where).tapes:
        result: Tape = {}
        for sec in tape.sections(8, 454):
            content = sec.content
            assert isinstance(content, Yields)
            for lst in content.lists:
                energy = lst.head.values[0]
                if energy in result:
                    raise _fail(where, sec.lineno, f"duplicate energy {energy:g}")
                v = lst.values
                result[energy] = [
                    Nuclide(int(v[j]), int(v[j + 1]), v[j + 2], v[j + 3])
                    for j in range(0, len(v), 4)
                ]
        out.append(result)
    return out


def read_mt454(path: Path) -> list[Tape]:
    """The MF8/MT454 yields of every tape of the file at ``path``."""
    return mt454_tapes(path.read_bytes().decode("latin-1"), str(path))
