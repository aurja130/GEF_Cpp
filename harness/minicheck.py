# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Minimal statistical check of GEF ENDF tapes against a library tape (provisional, M2 retires it).

Usage::

    python3 -m harness.minicheck <tape R> <library tape L> --events N
        [--ref-events NL] [--third <tape T> [--third-events NT]]
        [--tape I] [--ref-tape J] [--third-tape K] [--json OUT]

``R`` is the tape under test (N nominal events = Fenhance * 1e5), ``L`` the
library (reference) tape (``NL`` events, default N), ``T`` an optional second,
independent run of the reference code (``NT`` events, default N). ``--tape``,
``--ref-tape`` and ``--third-tape`` select a tape inside a multi-tape file
(0-based, negative counts from the end, default -1 = last).

Every energy of R must exist (exact float match) in L (and in T when given).
For two tapes a (Na events) and b (Nb events), per nuclide (ZA, isomeric
state) and for mass yields (sum over Z and states per A)::

    z = (Ya - Yb) / sqrt(Ya/Na + Yb/Nb)

which equals (Ya - Yb)/sqrt((Ya + Yb)/N) when Na = Nb = N. A nuclide (or mass)
is excluded when its expected total counts Ya*Na + Yb*Nb < 20 (for Na = Nb
that is (Ya + Yb)*N < 20). Exclusion is evaluated separately for each pair.

Metrics per energy and pair: number of entries used, z_rms of independent
and of mass yields, max |z| with its nuclide, sum of Y per tape.

Verdict per energy. A metric m (independent z_rms, mass z_rms) is *in band*
when it lies in [0.80, 1.50].

* two-way (no ``--third``): pass iff R-vs-L(m) in band for both metrics;
* three-way: metric m passes if R-vs-L(m) is in band; otherwise it passes by
  library fluctuation iff T-vs-L(m) is also out of band AND R-vs-T(m) is in
  band (L is the odd one out); otherwise it fails.

The energy verdict is ``fail`` if the sum check |sum(Y_R) - 2| <= 1e-4 fails or
any metric fails; else ``pass-by-library-fluctuation`` if any metric needed
that rescue; else ``pass``. A z_rms of NaN (no entries used) is out of band.

Exit codes: 0 every energy passes (either way), 1 at least one fails,
2 usage or parse error.
"""

from __future__ import annotations

import argparse
import math
import sys
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path

import numpy as np

from compare.parsers import ParseError
from compare.parsers.endf import Nuclide, Tape, read_mt454
from harness.common import HarnessError, write_json

__all__ = [
    "FAIL",
    "MIN_COUNTS",
    "PASS",
    "PASS_FLUCT",
    "SUM_TARGET",
    "SUM_TOL",
    "Z_RMS_MAX",
    "Z_RMS_MIN",
    "EnergyResult",
    "PairMetrics",
    "compare_tapes",
    "main",
    "z_scores",
]

Z_RMS_MIN = 0.80
Z_RMS_MAX = 1.50
SUM_TARGET = 2.0
SUM_TOL = 1e-4
MIN_COUNTS = 20.0

PASS = "pass"
PASS_FLUCT = "pass-by-library-fluctuation"
FAIL = "fail"

Key = tuple[int, int]


@dataclass(frozen=True)
class PairMetrics:
    """z-score statistics of tape ``a`` against tape ``b`` at one energy."""

    n_nuclides: int
    z_rms: float
    max_abs_z: float
    max_z_nuclide: str
    n_mass: int
    z_rms_mass: float
    sum_a: float
    sum_b: float


@dataclass(frozen=True)
class EnergyResult:
    """Verdict at one energy. ``rl``: R vs L; ``tl``: T vs L; ``rt``: R vs T (three-way only)."""

    energy: float
    rl: PairMetrics
    tl: PairMetrics | None
    rt: PairMetrics | None
    verdict: str
    sum_ok: bool
    independent_verdict: str
    mass_verdict: str

    @property
    def passed(self) -> bool:
        return self.verdict != FAIL


def _independent(nuclides: list[Nuclide], where: str) -> dict[Key, float]:
    out: dict[Key, float] = {}
    for n in nuclides:
        key = (n.za, n.state)
        if key in out:
            raise HarnessError(f"{where}: duplicate nuclide ZA={n.za} state={n.state}")
        out[key] = n.y
    return out


def _mass(yields: dict[Key, float]) -> dict[Key, float]:
    out: dict[Key, float] = defaultdict(float)
    for (za, _state), y in yields.items():
        out[(za % 1000, 0)] += y
    return out


def z_scores(
    a: dict[Key, float], b: dict[Key, float], na: float, nb: float
) -> tuple[list[Key], np.ndarray]:
    keys: list[Key] = []
    zs: list[float] = []
    for key in sorted(set(a) | set(b)):
        ya, yb = a.get(key, 0.0), b.get(key, 0.0)
        if ya * na + yb * nb < MIN_COUNTS:
            continue
        keys.append(key)
        zs.append((ya - yb) / math.sqrt(ya / na + yb / nb))
    return keys, np.asarray(zs, dtype=np.float64)


def _rms(z: np.ndarray) -> float:
    return float(np.sqrt(np.mean(z * z))) if z.size else math.nan


def _fmt(key: Key) -> str:
    return f"{key[0]}" + (f"m{key[1]}" if key[1] else "")


def _pair(a: dict[Key, float], b: dict[Key, float], na: float, nb: float) -> PairMetrics:
    keys, z = z_scores(a, b, na, nb)
    if z.size:
        imax = int(np.argmax(np.abs(z)))
        max_z, max_nuc = float(abs(z[imax])), _fmt(keys[imax])
    else:
        max_z, max_nuc = math.nan, "-"
    mkeys, mz = z_scores(_mass(a), _mass(b), na, nb)
    return PairMetrics(
        len(keys),
        _rms(z),
        max_z,
        max_nuc,
        len(mkeys),
        _rms(mz),
        math.fsum(a.values()),
        math.fsum(b.values()),
    )


def _in_band(x: float) -> bool:
    return Z_RMS_MIN <= x <= Z_RMS_MAX


def _metric_verdict(rl: float, tl: float | None, rt: float | None) -> str:
    if _in_band(rl):
        return PASS
    if tl is not None and rt is not None and not _in_band(tl) and _in_band(rt):
        return PASS_FLUCT
    return FAIL


def _lookup(tape: Tape, energy: float, label: str) -> dict[Key, float]:
    if energy not in tape:
        raise HarnessError(f"energy {energy:g} eV of the test tape is missing in {label}")
    return _independent(tape[energy], f"{label} E={energy:g}")


def compare_tapes(
    test: Tape,
    library: Tape,
    events: float,
    *,
    library_events: float | None = None,
    third: Tape | None = None,
    third_events: float | None = None,
) -> list[EnergyResult]:
    """Check every energy of ``test`` (R) against ``library`` (L), optionally with ``third`` (T)."""
    nl = events if library_events is None else library_events
    nt = events if third_events is None else third_events
    results: list[EnergyResult] = []
    for energy in sorted(test):
        r = _independent(test[energy], f"test E={energy:g}")
        lib = _lookup(library, energy, "the reference")
        rl = _pair(r, lib, events, nl)
        tl = rt = None
        if third is not None:
            t = _lookup(third, energy, "the third tape")
            tl = _pair(t, lib, nt, nl)
            rt = _pair(r, t, events, nt)
        v_ind = _metric_verdict(rl.z_rms, tl and tl.z_rms, rt and rt.z_rms)
        v_mass = _metric_verdict(rl.z_rms_mass, tl and tl.z_rms_mass, rt and rt.z_rms_mass)
        sum_ok = abs(rl.sum_a - SUM_TARGET) <= SUM_TOL
        verdicts = (v_ind, v_mass)
        if not sum_ok or FAIL in verdicts:
            verdict = FAIL
        elif PASS_FLUCT in verdicts:
            verdict = PASS_FLUCT
        else:
            verdict = PASS
        results.append(EnergyResult(energy, rl, tl, rt, verdict, sum_ok, v_ind, v_mass))
    return results


def _select(path: Path, index: int, label: str) -> Tape:
    try:
        tapes = read_mt454(path)
    except OSError as exc:
        raise HarnessError(f"cannot read {path}: {exc}") from exc
    except ParseError as exc:
        raise HarnessError(str(exc)) from exc
    print(f"{label}: {path} holds {len(tapes)} tape(s); using index {index}")
    if not tapes:
        raise HarnessError(f"{path}: no tape found")
    try:
        return tapes[index]
    except IndexError:
        raise HarnessError(
            f"{path}: tape index {index} out of range (0..{len(tapes) - 1})"
        ) from None


def _print_table(results: list[EnergyResult]) -> None:
    three = results[0].tl is not None
    if three:
        print(
            f"{'E [eV]':>12} {'sumY_R':>9} | {'z_rms: R-L':>10} {'T-L':>6} {'R-T':>6} | "
            f"{'mass: R-L':>9} {'T-L':>6} {'R-T':>6} | {'max|z| R-L':>10} {'nuclide':>9}  verdict"
        )
    else:
        print(
            f"{'E [eV]':>12} {'nNuc':>5} {'z_rms':>6} {'max|z|':>7} {'nuclide':>9} "
            f"{'nA':>4} {'z_rms_A':>7} {'sumY_test':>10} {'sumY_ref':>10}  verdict"
        )
    for r in results:
        if r.tl is not None and r.rt is not None:
            print(
                f"{r.energy:12.5g} {r.rl.sum_a:9.6f} | {r.rl.z_rms:10.3f} {r.tl.z_rms:6.3f} "
                f"{r.rt.z_rms:6.3f} | {r.rl.z_rms_mass:9.3f} {r.tl.z_rms_mass:6.3f} "
                f"{r.rt.z_rms_mass:6.3f} | {r.rl.max_abs_z:10.2f} {r.rl.max_z_nuclide:>9}  "
                f"{r.verdict}"
            )
        else:
            print(
                f"{r.energy:12.5g} {r.rl.n_nuclides:5d} {r.rl.z_rms:6.3f} {r.rl.max_abs_z:7.2f} "
                f"{r.rl.max_z_nuclide:>9} {r.rl.n_mass:4d} {r.rl.z_rms_mass:7.3f} "
                f"{r.rl.sum_a:10.6f} {r.rl.sum_b:10.6f}  {r.verdict}"
            )
    counts = {v: sum(r.verdict == v for r in results) for v in (PASS, PASS_FLUCT, FAIL)}
    print(
        f"{len(results)} energies: {counts[PASS]} {PASS}, {counts[PASS_FLUCT]} {PASS_FLUCT}, "
        f"{counts[FAIL]} {FAIL}"
    )


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="python3 -m harness.minicheck", description=__doc__)
    ap.add_argument("test_file", metavar="tape", type=Path)
    ap.add_argument("ref_file", metavar="library-tape", type=Path)
    ap.add_argument("--events", type=float, required=True, help="nominal events N of the tape")
    ap.add_argument("--ref-events", type=float, help="events of the library tape (default N)")
    ap.add_argument("--third", type=Path, help="independent second run T (three-way check)")
    ap.add_argument("--third-events", type=float, help="events of T (default N)")
    ap.add_argument("--tape", type=int, default=-1, help="tape index in the test file")
    ap.add_argument("--ref-tape", type=int, default=-1, help="tape index in the library file")
    ap.add_argument("--third-tape", type=int, default=-1, help="tape index in the third file")
    ap.add_argument("--json", type=Path, help="write the per-energy metrics here")
    try:
        args = ap.parse_args(argv)
    except SystemExit as exc:
        return 2 if exc.code else 0
    counts = {
        "--events": args.events,
        "--ref-events": args.ref_events,
        "--third-events": args.third_events,
    }
    for name, value in counts.items():
        if value is not None and not value > 0:
            print(f"minicheck: {name} must be positive", file=sys.stderr)
            return 2
    if args.third is None and args.third_events is not None:
        print("minicheck: --third-events requires --third", file=sys.stderr)
        return 2
    try:
        test = _select(args.test_file, args.tape, "test")
        lib = _select(args.ref_file, args.ref_tape, "library")
        third = _select(args.third, args.third_tape, "third") if args.third else None
        results = compare_tapes(
            test,
            lib,
            args.events,
            library_events=args.ref_events,
            third=third,
            third_events=args.third_events,
        )
    except HarnessError as exc:
        print(f"minicheck: {exc}", file=sys.stderr)
        return 2
    if not results:
        print("minicheck: the test tape has no MF8/MT454 energies", file=sys.stderr)
        return 2
    _print_table(results)
    ok = all(r.passed for r in results)
    if args.json is not None:
        write_json(
            args.json,
            {
                "events": args.events,
                "library_events": args.ref_events or args.events,
                "third_events": (args.third_events or args.events) if args.third else None,
                "thresholds": {
                    "z_rms": [Z_RMS_MIN, Z_RMS_MAX],
                    "sum_target": SUM_TARGET,
                    "sum_tol": SUM_TOL,
                    "min_counts": MIN_COUNTS,
                },
                "energies": [asdict(r) | {"passed": r.passed} for r in results],
                "passed": ok,
            },
        )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
