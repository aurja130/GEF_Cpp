# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""The ``out/<system>.dat`` results file and the perturbed-pass ``tmp/*.ptb`` (M2.2).

Both files hold the same XML-like blocks written by ``GEF.bas:11943-14774`` (see
``Planning/code_maps/outputs.md``, O7). A ``.ptb`` file is one block behind a five-line
preamble (``Parameter set #31``); an ``out/*.dat`` file appends one block per energy step.

Structure
---------
``<?xml ...?>`` starts a block (``<GEF>`` ... ``</GEF>``). Inside, ``<Title>``,
``<Prompt_results>`` (with nested ``<FF>``, ``<FF_A>``, ...), ``<Control>``, ``<Delayed>``,
``<CHI_square>`` and ``<Comments>`` nest as XML tags, one tag per line. ``Key.block`` is the
tag path below the root, e.g. ``Prompt_results/FF/FF_A/Mass_yields``.

* A **run** is a sequence of steps. An appended earlier run is recognised when a block has the
  same energy label as the block before it (the appended run restarts with the thermal
  pre-pass step). ``validation/test_run`` holds a one-block run followed by the real run.
* ``Key.group`` = ``run<r>/<energy label as written>#<occurrence>``; the occurrence counts
  blocks of that label in that run (thermal appears three times in a BASIC run). The label is
  taken from ``formed by (n,f) with En = <E> MeV`` or ``at E* = <E> MeV`` of ``<Title>``.
  Lines outside any block use the group of the preceding block (``preamble`` before the first).

Observables
-----------
Every line is exactly one of:

* **decoration** (blank, ``-----``, ``*****``): nothing.
* **masked stamp** ``Output written on <date>, <time>`` (``out_written`` of
  ``harness/masks.toml``): parsed, not emitted.
* **table row**, after a recognised header line (or banner): key columns go into
  ``Key.index`` (integers as written; decimal bin edges scaled to an integer, e.g. ``E`` in
  0.1 MeV bins -> ``E*10``). Each value column is a ``float`` (counts too, so a key never
  changes type between runs) labelled with its header name. A trailing vector (``J``
  distribution, ``nu`` distribution, ...) gets the vector position as last index. A repeated
  key within one table gets its occurrence number ``(n,)`` appended (``Isomeric_yields``,
  ``dn_emitters`` and ``anti_neutrinos`` always do).
* **dense array** (``A_Ekin``, ``A_TKE``): label ``array(A,E) (pre|post)``, index = the
  coordinates, in the loop order of the header.
* **scalar line** (a line with free numbers: ``Mean value: TXE = 23.2 MeV``,
  ``Calculation with 1000000 events.``, ``Yield of S1 (standard I) Channel = 3.9 %``):
  label = the line with each number replaced by ``#``, index = ``(occurrence of that label in
  the section, position of the number in the line)``, value ``float``. Numbers glued to
  letters (``S1``, ``1st isomer``, ``1.32MeV``) stay in the label.
* **text line** (no free number): label ``text``, index ``(k,)`` with k counting the text
  lines of the section; value = the stripped line.
* **fallback row** (an all-numeric line with no recognised header, e.g. the covariance
  sections ``Z_covariances`` ... that no tested file contains): label ``row``, index
  ``(k, position)`` with k counting fallback rows of the section. Such keys depend on the
  table length; ``CoverageReport.fallback_tokens`` counts them (0 for every tested file).

Keys never contain line numbers; everything is a function of the file content, so the same
quantity has the same key in every run. Key sets differ between two runs only where the
table extent is itself stochastic (zero-suppressed bins, nuclide lists, array limits).

Section handling (``Key.block`` below ``Prompt_results/`` unless noted)
------------------------------------------------------------------------
============================  ================================================================
Section                       Layout -> observables
============================  ================================================================
``Title``                     scalar/text lines (events, Z, A, En, spin, shell effect)
``Non-fission_results``       tables ``P(number of neutrons|protons)`` [N]; scalar headers
``P_fission``, ``Fission_c..``  scalar lines (``P_f = a / b = c``, ``Yield of ... = x %``)
``Multi_chance``              ``Contribution`` [n, p]; ``Events (n/p = i/j)`` [E*10]; scalars
``FF/FF_Z/Element_yields``    ``Yield`` (+ ``Uncertainty(+/-)``) [Z]
``FF/FF_Z/Z_even_odd``        scalar
``FF/N_over_Z``               ``N_mean/Z (pre|post-neutron)`` [Z]
``FF/FF_N/Isotonic_yields``   ``Yield (pre|post-neutron)`` [N]
``FF/FF_A/Mass_yields``       ``Yield (pre|post-neutron)`` (+ unc.) [A]
``FF/FF_AZ/Independent_..``   ``Yield (pre|post-neutron)`` (+ unc.) [A, Z]
``FF/FF_AZ/Z_mean``           ``Z_mean``, ``Z_mean-Z_UCD``, ``sigma_Z`` (pre|post) [A]
``Gammas/Gamma_multiplicity`` ``Nmean`` [A] + distribution [A, n]; ``Probability`` [N]
``Gammas/E_entrance``         ``Counts`` [E*10]; ``E_gammas``: total and E2; ``Sum_gamma_energy``
``Neutrons/NmultA``           ``Nmean CN/fragments``, distribution [A, n] for Apre and Apost
``Neutrons/Nmult``            ``P ...`` [N] (total, light, heavy), ``Counts`` [cos*1000],
                              ``events/nu_mean`` [TKE] + ``nu distribution`` [TKE, nu] pre/post
``Neutrons/Nspectrum``        counts and ``Yield norm. to Maxwellian`` [E*10]; variable-bin
                              table: upper limit and counts [lower edge in micro-eV]
``Neutrons/Enmean``           scalar lines
``FF_spin/A_Z_spin``          ``Jmean`` [A, Z] and ``J distribution`` [A, Z, J] (Apre, Apost)
``FF_spin/Isomeric_yields``   ``J``, ``E*``, ``Yield (%)``, ``Events``, ``Upper limit`` [A, Z, k]
``Q_value``, ``TKE``, ``TXE``  counts [bin] + scalar means ``Mean value: Q-bar = #``
``A_Ekin``, ``A_TKE``         dense arrays [A, E] (pre, post)
``Control`` (top level)       scalar ``name = #``
``Delayed/dn_emitters``       ``Pn[<decay>]`` [Z, A, k]
``Delayed/nu_delayed``        scalar
``Delayed/anti_neutrinos``    ``Number[<decay>]``, ``Q value[<decay>]`` [Z, A, N, k]
``Delayed/Cumu/Yields``       ``Yield`` (+ ``Uncertainty``) [A, Z, isomer]
``CHI_square``, ``Comments``  scalar and text lines
============================  ================================================================

Coverage
--------
``coverage`` re-runs the parser and checks, line by line, against an independent regular
expression (every digit run of a line), that each numeric token was emitted as a value, used as
a key, kept in a label/text, or matched by ``ALLOW_LIST`` (the XML declaration, tag names and
the masked time stamp). The report totals tokens per section.
"""

from __future__ import annotations

import re
from collections import Counter
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from decimal import Decimal
from functools import cache
from pathlib import Path

import harness
from compare.model import Key, Value
from compare.parsers import ParseError
from harness.compare_runs import load_masks

__all__ = [
    "ALLOW_LIST",
    "PATTERNS",
    "AllowEntry",
    "CoverageReport",
    "SectionCoverage",
    "Step",
    "coverage",
    "observables",
    "steps",
]

PATTERNS: tuple[str, ...] = ("work/out/*.dat", "work/out/*.ptb", "work/tmp/*.ptb")


@dataclass(frozen=True, slots=True)
class AllowEntry:
    """A line pattern whose numeric tokens are not data, with the reason."""

    pattern: re.Pattern[str]
    reason: str


_XML_ALLOW = AllowEntry(
    re.compile(r"<\?xml version=.*\?>$"), "XML declaration: version and encoding numbers"
)
_TAG_ALLOW = AllowEntry(re.compile(r"\s*</?[A-Za-z_][\w-]*>\s*$"), "tag names (<GEF1>, <GEF2>)")
_STAMP_LINE = -2  # sentinel returned for a masked time-stamp line
_STAMP_REASON = "time stamp 'Output written on' (mask out_written of harness/masks.toml)"
ALLOW_LIST: tuple[AllowEntry, ...] = (
    _XML_ALLOW,
    _TAG_ALLOW,
    AllowEntry(re.compile(r"Output written on \d\d\.\d\d\.\d{4}, \d\d:\d\d:\d\d$"), _STAMP_REASON),
)

_GEF_END = re.compile(r"\s*</GEF\d?>\s*$")
_TAG = re.compile(r"\s*<(/?)([A-Za-z_][\w-]*)>\s*$")
_NUM = re.compile(r"(?<![\w.])(?>[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)(?!\w)")
_DIGITS = re.compile(r"\d+(?:\.\d+)?(?:[eE][-+]?\d+)?")
_NUMTOK = r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?"
_ALLNUM = re.compile(rf"{_NUMTOK}(?:\s+{_NUMTOK})*")
_DECOR = re.compile(r"[-*=\s]*$")
_BANNER = re.compile(r"-{2,}\s*(.*?)\s*-{2,}$")
_ENERGY = re.compile(r"(?:\bEn|E\*) =\s*(\S+) MeV")
_DENSE = re.compile(r"(\d)-dim\. array: ((?:\(\w+ = *-?\d+ To *-?\d+ Step *\d+\) ?)+)$")
_DENSE_DIM = re.compile(r"\((\w+) = *(-?\d+) To *(-?\d+) Step *(\d+)\)")
_DN = re.compile(r"(\S+)\s+(\d+)\s+(\d+)\s+(.+?)\s*$")
_ANTI = re.compile(r"(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(.+?)\s*$")
_UNC = r"(?: Uncertainty ?\(\+-\))?"


@cache
def _stamp_pattern() -> re.Pattern[str]:
    masks = load_masks(Path(harness.__file__).resolve().parent / "masks.toml")
    for mask in masks:
        if mask.id == "out_written":
            return mask.pattern
    raise ParseError("mask out_written missing from harness/masks.toml")


# --------------------------------------------------------------------------- table specs

type _KeyKind = int | None  # None: integer text; k >= 0: decimal text scaled by 10**k


@dataclass(frozen=True, slots=True)
class _Spec:
    """Layout of one table: key columns, labelled value columns, optional trailing vector."""

    labels: tuple[str, ...]
    keys: tuple[_KeyKind, ...] = (None,)
    rest: str = ""  # label of a trailing vector (always 'a'); its position is the last index
    percent: bool = False  # drop standalone '%' tokens
    always_count: bool = False  # always append the repeat counter to the key
    tail: str = ""  # '' | 'dn' | 'anti': numbers followed by a free-text decay name


type _Builder = Callable[[re.Match[str], str], _Spec]


def _spec(
    labels: tuple[str, ...],
    *,
    keys: tuple[_KeyKind, ...] = (None,),
    rest: str = "",
    percent: bool = False,
    always_count: bool = False,
) -> _Spec:
    return _Spec(labels, keys, rest, percent, always_count)


def _fixed(spec: _Spec) -> _Builder:
    return lambda _m, _banner: spec


_UNC2 = ("Uncertainty(+)", "Uncertainty(-)")
_UNC1 = ("Uncertainty",)


def _with_unc(
    labels: tuple[str, ...],
    *,
    keys: tuple[_KeyKind, ...] = (None,),
    names: tuple[str, ...] = _UNC2,
) -> _Builder:
    def build(m: re.Match[str], _banner: str) -> _Spec:
        return _spec(labels + names if m.group("u") else labels, keys=keys)

    return build


def _nspectrum(m: re.Match[str], _banner: str) -> _Spec:
    nc = m.group(0).count("Counts")
    frag = [f"Counts fragments DN/DZ #{k}" for k in range(max(nc - 4, 0))]
    labels = ("Counts pre-saddle", "Counts saddle-scission", *frag)
    labels += ("Counts fragments all/all", "Counts total", "Yield norm. to Maxwellian")
    return _spec(labels[: nc + 1], keys=(1,))


def _mc_events(m: re.Match[str], _banner: str) -> _Spec:
    pairs = re.findall(r"(\d+) / (\d+)", m.group(1))
    return _spec(tuple(f"Events (n/p = {n}/{p})" for n, p in pairs), keys=(1,))


def _phase(banner: str) -> str:
    """``pre`` or ``post`` neutron emission, from the latest banner that names one."""
    pre, post = banner.rfind("pre-neutron"), banner.rfind("post-neutron")
    return "?" if pre == post else "pre" if pre > post else "post"


def _tke_nu(_m: re.Match[str], banner: str) -> _Spec:
    w = _phase(banner)
    return _spec((f"events ({w})", f"nu_mean ({w})"), rest=f"nu distribution ({w})")


def _n_over_z(m: re.Match[str], _banner: str) -> _Spec:
    return _spec((f"N_mean/Z ({m.group(1)}-neutron)",))


def _z_mean(m: re.Match[str], _banner: str) -> _Spec:
    w = m.group(1)
    return _spec((f"Z_mean ({w})", f"Z_mean-Z_UCD ({w})", f"sigma_Z ({w})"))


def _nmult_a(m: re.Match[str], _banner: str) -> _Spec:
    w = m.group(1)
    return _spec(
        (f"Nmean CN ({w})", f"Nmean fragments ({w})"), rest=f"multiplicity distribution ({w})"
    )


def _spin(m: re.Match[str], _banner: str) -> _Spec:
    w = m.group(1)
    return _spec((f"Jmean ({w})",), keys=(None, None), rest=f"J distribution ({w})")


_YIELD2 = ("Yield (pre-neutron)", "Yield (post-neutron)")

_HEADERS: tuple[tuple[re.Pattern[str], _Builder], ...] = tuple(
    (re.compile(rx), build)
    for rx, build in (
        (
            r"Number of neutrons Probability \(values > 0\)",
            _fixed(_spec(("P(number of neutrons)",))),
        ),
        (
            r"Number of protons Probability \(values > 0\)",
            _fixed(_spec(("P(number of protons)",))),
        ),
        (
            r"pre-saddle neutrons protons contribution",
            _fixed(_spec(("Contribution",), keys=(None, None))),
        ),
        (r"E\*/MeV((?: \d+ / \d+)+)", _mc_events),
        (rf"Z Yield(?P<u>{_UNC})", _with_unc(("Yield",))),
        (r"Z N_mean/Z \((pre|post)-neutron\)", _n_over_z),
        (
            rf"N Yield\(pre-neutron\) Yield\(post-neutron\)(?P<u>{_UNC})",
            _with_unc(_YIELD2),
        ),
        (rf"A Yield Yield(?P<u>{_UNC})", _with_unc(_YIELD2)),
        (rf"A Z Yield Yield(?P<u>{_UNC})", _with_unc(_YIELD2, keys=(None, None))),
        (r"A_(pre|post) Z_mean Z_mean-Z_UCD sigma_Z", _z_mean),
        (
            r"Apost Nmean Multiplicity distribution, unnormalized \(0 to \d+\)",
            _fixed(_spec(("Nmean",), rest="gamma multiplicity distribution")),
        ),
        (r"N Probability", _fixed(_spec(("Probability",)))),
        (r"E / MeV Counts", _fixed(_spec(("Counts",), keys=(1,)))),
        (
            r"E_gamma / MeV Counts\(total\) Counts\(E2 only\)",
            _fixed(_spec(("Counts (total)", "Counts (E2 only)"), keys=(1,))),
        ),
        (r"Egamma / MeV Counts", _fixed(_spec(("Counts",), keys=(1,)))),
        (
            r"(Apre|Apost) Nmean Nmean Multiplicity distribution, unnormalized \(0 to \d+\)",
            _nmult_a,
        ),
        (
            r"N pre-saddle saddle-scission from fragments total",
            _fixed(_spec(("P pre-saddle", "P saddle-scission", "P fragments", "P total"))),
        ),
        (r"Cos\(alpha\) Counts", _fixed(_spec(("Counts",), keys=(3,)))),
        (r"TKE events nu_mean nu distribution \(nu = 0 to \d+\)", _tke_nu),
        (r"E_neutron(?: Counts)+ Yield norm\. to Maxwellian", _nspectrum),
        (
            r"E_neutrons E_neutrons Counts",
            _fixed(_spec(("E_neutrons upper limit (eV)", "Counts"), keys=(6,))),
        ),
        (r"A Z Jmean J distribution, unnormalized .* for even \(odd\) (Apre|Apost)\)", _spin),
        (
            r"A Z J E\* Yield Events Upper limit",
            _fixed(
                _spec(
                    ("J", "E*", "Yield (%)", "Events", "Upper limit"),
                    keys=(None, None),
                    percent=True,
                    always_count=True,
                )
            ),
        ),
        (r"Q/MeV Counts", _fixed(_spec(("Counts",)))),
        (
            r"TKE/MeV Counts\(pre\) Counts\(post\)",
            _fixed(_spec(("Counts (pre)", "Counts (post)"))),
        ),
        (r"TXE/MeV Counts", _fixed(_spec(("Counts",)))),
        (r"Pn Z A decay", _fixed(_Spec((), (None, None), tail="dn", always_count=True))),
        (
            r"Z A N Number Q value Decay",
            _fixed(_Spec((), (None, None, None), tail="anti", always_count=True)),
        ),
        (
            rf"A Z Isomer Yield(?P<u>{_UNC})",
            _with_unc(("Yield",), keys=(None, None, None), names=_UNC1),
        ),
    )
)

_BANNER_SPECS: tuple[tuple[re.Pattern[str], _Spec], ...] = (
    (
        re.compile(r"Multiplicity distribution of prompt neutrons \(light fragment\)"),
        _spec(("P (light fragment)",)),
    ),
    (
        re.compile(r"Multiplicity distribution of prompt neutrons \(heavy-fragment\)"),
        _spec(("P (heavy fragment)",)),
    ),
)


def _header_spec(norm: str, banner: str) -> _Spec | None:
    for rx, build in _HEADERS:
        m = rx.fullmatch(norm)
        if m is not None:
            return build(m, banner)
    return None


# --------------------------------------------------------------------------- results


@dataclass(frozen=True, slots=True)
class Step:
    """One energy step (one ``<GEF>`` block) of a results file."""

    run: int
    energy: str
    occurrence: int
    first_line: int  # 1-based, the ``<?xml`` line
    last_line: int  # 1-based, the ``</GEF>`` line (or the last line of the file)

    @property
    def group(self) -> str:
        return f"run{self.run}/{self.energy}#{self.occurrence}"


@dataclass(frozen=True, slots=True)
class SectionCoverage:
    """Token accounting of one section path (summed over all steps)."""

    tokens: int = 0  # numeric tokens found by the independent digit-run regex
    values: int = 0  # tokens emitted as numeric observables
    keys: int = 0  # tokens used as index components
    text: int = 0  # tokens kept inside label/text (scalar labels, headers, glued digits)
    fallback: int = 0  # tokens emitted through the generic ``row`` fallback (subset of values)
    allowed: int = 0
    observables: int = 0


@dataclass(frozen=True, slots=True)
class Unaccounted:
    line: int
    text: str
    found: int
    accounted: int


@dataclass(frozen=True, slots=True)
class CoverageReport:
    path: str
    lines: int
    steps: tuple[Step, ...]
    tokens: int
    accounted: int
    allowed: dict[str, int]
    sections: dict[str, SectionCoverage]
    unaccounted: tuple[Unaccounted, ...]
    observables: int
    seconds: float = 0.0

    @property
    def ok(self) -> bool:
        return not self.unaccounted and self.tokens == self.accounted

    @property
    def fallback_tokens(self) -> int:
        return sum(s.fallback for s in self.sections.values())

    @property
    def percent(self) -> float:
        return 100.0 * self.accounted / self.tokens if self.tokens else 100.0

    def __str__(self) -> str:
        runs = max((s.run for s in self.steps), default=0)
        state = "ok" if self.ok else f"FAIL ({len(self.unaccounted)} lines)"
        return (
            f"{Path(self.path).name}: {state}, {self.accounted}/{self.tokens} numeric tokens "
            f"({self.percent:.2f} %), {sum(self.allowed.values())} allow-listed, "
            f"{self.fallback_tokens} via fallback rows, {len(self.steps)} steps in {runs} "
            f"run(s), {self.observables} observables"
        )


class _StepTracker:
    """Splits blocks into runs: a block with the energy label of the one before starts a run."""

    def __init__(self) -> None:
        self.run = 0
        self.energy: str | None = None
        self.occurrence: Counter[str] = Counter()
        self.first_line = 0

    def begin(self, energy: str, lineno: int) -> str:
        """A block with this energy label starts at ``lineno``; returns its group."""
        if self.energy is None:
            self.run = 1
        elif energy == self.energy:
            self.run += 1
            self.occurrence.clear()
        self.energy = energy
        self.occurrence[energy] += 1
        self.first_line = lineno
        return f"run{self.run}/{energy}#{self.occurrence[energy]}"

    def end(self, lineno: int) -> Step:
        energy = self.energy or "?"
        return Step(self.run, energy, self.occurrence[energy], self.first_line, lineno)


class _Ctx:
    """State of the currently open tag."""

    __slots__ = (
        "banner",
        "dense",
        "dups",
        "fallback_k",
        "rows",
        "seen",
        "table",
        "templates",
        "text_k",
    )

    def __init__(self) -> None:
        self.templates: Counter[str] = Counter()
        self.text_k = 0
        self.fallback_k = 0
        self.table: _Spec | None = None
        self.rows = 0
        self.seen: set[tuple[int, ...]] = set()
        self.dups: Counter[tuple[int, ...]] = Counter()
        self.banner = ""
        self.dense: _Dense | None = None

    def start_table(self, spec: _Spec) -> None:
        self.table = spec
        self.rows = 0
        self.seen = set()
        self.dups = Counter()


class _Dense:
    """A dense multi-dimensional array written in loop order, wrapped at 50 per line."""

    __slots__ = ("coords", "label", "pos", "total")

    def __init__(self, label: str, coords: list[tuple[int, ...]]) -> None:
        self.label = label
        self.coords = coords
        self.total = len(coords)
        self.pos = 0


def _decimal_key(tok: str, shift: int) -> int | None:
    scaled = Decimal(tok).scaleb(shift)
    integral = scaled.to_integral_value()
    if scaled != integral:
        return None
    return int(integral)


class _Engine:
    """One pass over the lines of a results file; ``run`` yields the observables."""

    def __init__(self, path: Path, rel: str, *, account: bool) -> None:
        self.path = path
        self.rel = rel
        self.lines = path.read_bytes().decode("latin-1").split("\n")
        if self.lines and self.lines[-1] == "":
            self.lines.pop()
        self.account = account
        self.steps: list[Step] = []
        self.buf: list[tuple[str, tuple[int, ...], Value]] = []
        # accounting (only filled when ``account``)
        self.sections: dict[str, Counter[str]] = {}
        self.allowed: Counter[str] = Counter()
        self.unaccounted: list[Unaccounted] = []
        self.tokens = 0
        self.accounted = 0
        self.nobs = 0
        # per-line accounting scratch: tokens taken as key / text / value (fallback separately)
        self.n_key = 0
        self.n_text = 0
        self.n_fallback = 0

    # ------------------------------------------------------------------ helpers
    def fail(self, lineno: int, message: str) -> ParseError:
        return ParseError(f"{self.rel}: line {lineno}: {message}")

    def energy_label(self, start: int) -> str:
        end = min(start + 120, len(self.lines))
        for i in range(start, end):
            line = self.lines[i]
            if _ENERGY.search(line):
                m = _ENERGY.search(line)
                assert m is not None
                return m.group(1)
            if line.strip() == "</Title>":
                break
        return "?"

    # ------------------------------------------------------------------ main loop
    def run(self) -> Iterator[tuple[Key, Value]]:
        lines = self.lines
        rel = self.rel
        stack: list[str] = []
        ctxs: list[_Ctx] = [_Ctx()]
        block = "(text)"
        group = "preamble"
        tracker = _StepTracker()
        stamp = _stamp_pattern()
        account = self.account
        buf = self.buf
        for i, line in enumerate(lines):
            lineno = i + 1
            first = line.lstrip()[:1]
            consumed = -1  # -1: not yet classified
            if first == "<":
                if line.startswith("<?xml"):
                    if stack:
                        raise self.fail(lineno, f"<?xml inside open tag <{stack[-1]}>")
                    group = tracker.begin(self.energy_label(i), lineno)
                    block = "(text)"
                    ctxs = [_Ctx()]
                    if account:
                        self._allow(line, _XML_ALLOW)
                    continue
                m = _TAG.match(line)
                if m is not None:
                    name = m.group(2)
                    if m.group(1):
                        if not stack or stack[-1] != name:
                            top = stack[-1] if stack else "(none)"
                            raise self.fail(lineno, f"</{name}> closes <{top}>")
                        stack.pop()
                        done = ctxs.pop()
                        if done.dense is not None and done.dense.pos != done.dense.total:
                            raise self.fail(lineno, f"array in <{name}> is incomplete")
                        if not stack:
                            self.steps.append(tracker.end(lineno))
                    else:
                        stack.append(name)
                        ctxs.append(_Ctx())
                    block = (
                        "/".join(stack[1:]) if len(stack) > 1 else "(root)" if stack else "(text)"
                    )
                    if account:
                        self._allow(line, _TAG_ALLOW)
                    continue
            ctx = ctxs[-1]
            self.n_key = self.n_text = self.n_fallback = 0
            consumed = self._line(line, lineno, ctx, stamp)
            if account:
                found = len(_DIGITS.findall(line))
                sec = self.sections.setdefault(block, Counter())
                n = len(buf)
                if consumed == _STAMP_LINE:
                    self.allowed[_STAMP_REASON] += found
                    sec["allowed"] += found
                    consumed = found
                    self.tokens += found
                    self.accounted += found
                    sec["tokens"] += found
                else:
                    self.tokens += found
                    self.accounted += consumed
                    sec["tokens"] += found
                    sec["keys"] += self.n_key
                    sec["text"] += self.n_text
                    sec["fallback"] += self.n_fallback
                    sec["values"] += consumed - self.n_key - self.n_text
                    if consumed != found:
                        self.unaccounted.append(Unaccounted(lineno, line[:100], found, consumed))
                sec["observables"] += n
            if buf:
                self.nobs += len(buf)
                for label, index, value in buf:
                    yield Key(rel, block, group, label, index), value
                buf.clear()
        if stack:
            raise self.fail(len(lines), f"end of file inside <{stack[-1]}> (truncated block)")

    def _allow(self, line: str, entry: AllowEntry) -> None:
        """Account the numeric tokens of a line that ``entry`` declares non-data."""
        if entry.pattern.match(line) is None:
            raise self.fail(0, f"internal: {entry.reason!r} does not match {line!r}")
        found = len(_DIGITS.findall(line))
        self.tokens += found
        self.accounted += found
        if found:
            self.allowed[entry.reason] += found

    # ------------------------------------------------------------------ one data line
    def _line(self, line: str, lineno: int, ctx: _Ctx, stamp: re.Pattern[str]) -> int:
        """Classify and emit one line; returns the number of numeric tokens consumed."""
        s = line.strip()
        dense = ctx.dense
        if dense is not None:
            if s and _ALLNUM.fullmatch(s):
                return self._dense_line(dense, s, lineno, ctx)
            if dense.pos > 0:
                if dense.pos != dense.total:
                    raise self.fail(lineno, f"array has {dense.pos} of {dense.total} values")
                ctx.dense = None
        if not s or _DECOR.match(s):
            return 0
        if _ALLNUM.fullmatch(s):
            tbl = ctx.table
            if tbl is not None:
                n = self._row(ctx, tbl, s, lineno)
                if n >= 0:
                    return n
            return self._fallback_row(ctx, s)
        tbl2 = ctx.table
        if tbl2 is not None and ((tbl2.percent and "%" in s) or tbl2.tail):
            n = self._row(ctx, tbl2, s, lineno)
            if n >= 0:
                return n
        if stamp.search(line) is not None and line.startswith("Output written on"):
            return _STAMP_LINE
        norm = " ".join(s.split())
        spec = _header_spec(norm, ctx.banner)
        if spec is not None:
            ctx.start_table(spec)
            return self._text(ctx, s)
        bm = _BANNER.match(norm)
        if bm is not None:
            ctx.banner = f"{ctx.banner} | {bm.group(1)}"[-400:]
            for rx, bspec in _BANNER_SPECS:
                if rx.fullmatch(bm.group(1)):
                    ctx.start_table(bspec)
                    return self._text(ctx, s)
        dm = _DENSE.match(norm)
        if dm is not None:
            return self._start_dense(dm, ctx, s, lineno)
        if ctx.table is not None and ctx.rows > 0:
            ctx.table = None
        return self._scalar_or_text(ctx, s, norm)

    # ------------------------------------------------------------------ text and scalars
    def _text(self, ctx: _Ctx, s: str) -> int:
        ctx.text_k += 1
        self.buf.append(("text", (ctx.text_k,), s))
        n = len(_DIGITS.findall(s))
        self.n_text += n
        return n

    def _scalar_or_text(self, ctx: _Ctx, s: str, norm: str) -> int:
        toks = list(_NUM.finditer(norm))
        if not toks:
            return self._text(ctx, s)
        parts: list[str] = []
        values: list[Value] = []
        last = 0
        for m in toks:
            parts.append(norm[last : m.start()])
            parts.append("#")
            last = m.end()
            values.append(float(m.group(0)))
        parts.append(norm[last:])
        template = "".join(parts)
        ctx.templates[template] += 1
        k = ctx.templates[template]
        buf = self.buf
        for pos, v in enumerate(values, 1):
            buf.append((template, (k, pos), v))
        in_label = len(_DIGITS.findall(template))
        self.n_text += in_label
        return len(values) + in_label

    # ------------------------------------------------------------------ table rows
    def _row(self, ctx: _Ctx, spec: _Spec, s: str, lineno: int) -> int:
        """Emit a row of ``spec``; returns tokens consumed, or -1 if the line does not fit."""
        if spec.tail:
            return self._tail_row(ctx, spec, s, lineno)
        if spec.percent:
            s = s.replace(" %", "")
            if not _ALLNUM.fullmatch(s):
                return -1
        toks = s.split()
        nk = len(spec.keys)
        if len(toks) <= nk:
            return -1
        idx: list[int] = []
        for tok, kind in zip(toks, spec.keys, strict=False):
            if kind is None:
                try:
                    idx.append(int(tok))
                except ValueError:
                    return -1
            else:
                key = _decimal_key(tok, kind)
                if key is None:
                    raise self.fail(lineno, f"key {tok!r} is not a multiple of 10^-{kind}")
                idx.append(key)
        index = self._unique(ctx, spec, tuple(idx))
        labels = spec.labels
        nl = len(labels)
        buf = self.buf
        rest = spec.rest
        for j, tok in enumerate(toks[nk:]):
            if j < nl:
                buf.append((labels[j], index, float(tok)))
            elif rest:
                buf.append((rest, (*index, j - nl), float(tok)))
            else:
                buf.append((f"column {nk + j + 1}", index, float(tok)))
        ctx.rows += 1
        self.n_key += nk
        return len(toks)

    @staticmethod
    def _unique(ctx: _Ctx, spec: _Spec, key: tuple[int, ...]) -> tuple[int, ...]:
        if spec.always_count:
            ctx.dups[key] += 1
            return (*key, ctx.dups[key])
        if key in ctx.seen:
            ctx.dups[key] += 1
            return (*key, ctx.dups[key] + 1)
        ctx.seen.add(key)
        return key

    def _tail_row(self, ctx: _Ctx, spec: _Spec, s: str, lineno: int) -> int:
        buf = self.buf
        if spec.tail == "dn":
            m = _DN.fullmatch(s)
            if m is None or not _NUM.fullmatch(m.group(1)):
                return -1
            pn, z, a, decay = m.groups()
            index = self._unique(ctx, spec, (int(z), int(a)))
            buf.append((f"Pn[{decay}]", index, float(pn)))
            nd = len(_DIGITS.findall(decay))
            self.n_key += 2
            self.n_text += nd
            ctx.rows += 1
            return 3 + nd
        m = _ANTI.fullmatch(s)
        if m is None or not (_NUM.fullmatch(m.group(4)) and _NUM.fullmatch(m.group(5))):
            return -1
        z, a, n, number, q, decay = m.groups()
        index = self._unique(ctx, spec, (int(z), int(a), int(n)))
        buf.append((f"Number[{decay}]", index, float(number)))
        buf.append((f"Q value[{decay}]", index, float(q)))
        nd = len(_DIGITS.findall(decay))
        self.n_key += 3
        self.n_text += nd
        ctx.rows += 1
        return 5 + nd

    def _fallback_row(self, ctx: _Ctx, s: str) -> int:
        ctx.fallback_k += 1
        k = ctx.fallback_k
        buf = self.buf
        toks = s.split()
        for pos, tok in enumerate(toks, 1):
            buf.append(("row", (k, pos), float(tok)))
        self.n_fallback += len(toks)
        return len(toks)

    # ------------------------------------------------------------------ dense arrays
    def _start_dense(self, m: re.Match[str], ctx: _Ctx, s: str, lineno: int) -> int:
        dims = _DENSE_DIM.findall(m.group(2))
        if len(dims) != int(m.group(1)):
            raise self.fail(lineno, f"array header announces {m.group(1)} dimensions: {s!r}")
        names: list[str] = []
        axes: list[range] = []
        for name, lo, hi, step in dims:
            names.append(name)
            axes.append(range(int(lo), int(hi) + 1, int(step)))
        coords: list[tuple[int, ...]] = [()]
        for axis in axes:
            coords = [(*c, v) for c in coords for v in axis]
        ctx.dense = _Dense(f"array({','.join(names)}) ({_phase(ctx.banner)})", coords)
        ctx.table = None
        return self._text(ctx, s)

    def _dense_line(self, dense: _Dense, s: str, lineno: int, ctx: _Ctx) -> int:
        toks = s.split()
        pos = dense.pos
        if pos + len(toks) > dense.total:
            raise self.fail(lineno, f"more than {dense.total} values in {dense.label}")
        buf = self.buf
        label = dense.label
        coords = dense.coords
        for tok in toks:
            buf.append((label, coords[pos], float(tok)))
            pos += 1
        dense.pos = pos
        self.n_key += 0
        return len(toks)


# --------------------------------------------------------------------------- public API


def observables(path: Path, rel: str) -> Iterator[tuple[Key, Value]]:
    """All observables of the results file (see the module docstring for keys)."""
    return _Engine(path, rel, account=False).run()


def steps(path: Path) -> tuple[Step, ...]:
    """The runs and energy steps of the file (a line scan, the sections are not parsed)."""
    engine = _Engine(path, path.name, account=False)
    tracker = _StepTracker()
    result: list[Step] = []
    for i, line in enumerate(engine.lines):
        if line.startswith("<?xml"):
            tracker.begin(engine.energy_label(i), i + 1)
        elif _GEF_END.match(line):
            result.append(tracker.end(i + 1))
    return tuple(result)


def coverage(path: Path) -> CoverageReport:
    """Account for every numeric token of the file (see the module docstring)."""
    import time

    t0 = time.perf_counter()
    engine = _Engine(path, path.name, account=True)
    for _ in engine.run():
        pass
    sections = {
        block: SectionCoverage(
            tokens=c["tokens"],
            values=c["values"],
            keys=c["keys"],
            text=c["text"],
            fallback=c["fallback"],
            allowed=c["allowed"],
            observables=c["observables"],
        )
        for block, c in sorted(engine.sections.items())
    }
    return CoverageReport(
        path=str(path),
        lines=len(engine.lines),
        steps=tuple(engine.steps),
        tokens=engine.tokens,
        accounted=engine.accounted,
        allowed=dict(engine.allowed),
        sections=sections,
        unaccounted=tuple(engine.unaccounted),
        observables=engine.nobs,
        seconds=time.perf_counter() - t0,
    )
