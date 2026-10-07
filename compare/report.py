# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Text and JSON reports of a ``VerdictResult`` (plan M2.7).

Both are byte-deterministic for the same result: everything is sorted, floats are formatted with
fixed rules and no timestamp, host or process information is included. The reports contain

* the verdict and its parameters (calibration, candidates, alpha, Holm family count);
* deterministic failures (missing and unexpected families, mismatching fields and text keys),
  listed separately from the statistics;
* the rejected statistical families with p, Holm rank and threshold, the global and local
  statistics and the top contributing bins (candidate value, ensemble mean, z);
* the lowest p of the families that were not rejected;
* a summary per file kind and per file kind and energy.
"""

from __future__ import annotations

import json
import math
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from compare.verdict import FamilyResult, VerdictResult

__all__ = ["render_json", "render_pvalues", "render_text", "result_dict"]

NEAR_MISSES = 15
LISTED_FAMILIES = 200  # failing families listed in the text report (JSON lists all)


def _g(x: float) -> str:
    return "nan" if math.isnan(x) else f"{x:.4g}"


def _clean(x: float) -> float | None:
    return None if math.isnan(x) else x


def _family_name(f: FamilyResult) -> str:
    return " | ".join([f.file, f.block, f.group])


def _family_dict(f: FamilyResult) -> dict[str, Any]:
    return {
        "file": f.file,
        "block": f.block,
        "group": f.group,
        "status": f.status,
        "rejected": f.rejected,
        "n_stoch": f.n_stoch,
        "n_tested_fields": f.n_test,
        "d": _clean(f.d),
        "m": _clean(f.m),
        "p_global": _clean(f.p_global),
        "p_local": _clean(f.p_local),
        "p": _clean(f.p),
        "holm_rank": f.rank or None,
        "holm_threshold": _clean(f.threshold),
        "n_mismatch": f.n_mismatch,
        "mismatches": [{"key": m.key, "expected": m.expected, "got": m.got} for m in f.mismatches],
        "stochastic_text_keys": f.listed_text,
        "top_bins": [
            {"key": t.key, "candidate": t.candidate, "mean": t.mean, "z": t.z} for t in f.top
        ],
    }


def result_dict(r: VerdictResult) -> dict[str, Any]:
    """The JSON report as a dict."""
    exact = [f for f in r.families if f.failed_exactly]
    rejected = sorted(
        (f for f in r.families if f.rejected), key=lambda f: (f.rank, _family_name(f))
    )
    near = sorted(
        (f for f in r.families if f.status == "tested" and not f.rejected),
        key=lambda f: (f.p, _family_name(f)),
    )[:NEAR_MISSES]
    return {
        "verdict": "pass" if r.passed else "fail",
        "calibration": r.calibration,
        "candidates": r.candidates,
        "runs_calibration": r.runs_calibration,
        "runs_candidate": r.runs_candidate,
        "alpha": r.alpha,
        "holm_families": r.holm_total,
        "statistical_families_tested": r.tested,
        "exact_only_families": r.exact_only,
        "rejected_statistical": len(rejected),
        "exact_failures": len(exact),
        "exact_failed_families": [_family_dict(f) for f in exact],
        "rejected_families": [_family_dict(f) for f in rejected],
        "lowest_p_not_rejected": [_family_dict(f) for f in near],
        "per_kind": {k: r.kinds[k] for k in sorted(r.kinds)},
        "per_kind_energy": {k: r.energies[k] for k in sorted(r.energies, key=_energy_sort)},
        "unparsed_candidate_files": r.unparsed_candidate,
    }


def _energy_sort(label: str) -> tuple[str, float, str]:
    kind, _, energy = label.partition(" @ ")
    try:
        return kind, float(energy), ""
    except ValueError:
        return kind, -1.0, energy


def render_json(r: VerdictResult) -> str:
    """Deterministic JSON report."""
    return json.dumps(result_dict(r), indent=1, sort_keys=True, allow_nan=False) + "\n"


def render_pvalues(r: VerdictResult) -> str:
    """Deterministic JSON of every tested family's p-value (for null validation)."""
    order = sorted(range(len(r.p_index)), key=lambda i: r.p_index[i])
    data = {
        "families": [list(r.p_index[i]) for i in order],
        "p": [float(r.p_values[i]) for i in order],
    }
    return json.dumps(data, sort_keys=True, allow_nan=False) + "\n"


def render_text(r: VerdictResult) -> str:
    """Human-readable deterministic report."""
    d = result_dict(r)
    out: list[str] = []
    w = out.append
    w(f"VERDICT: {'PASS' if r.passed else 'FAIL'}")
    w(f"calibration : {r.calibration} ({r.runs_calibration} runs)")
    w(f"candidate   : {', '.join(r.candidates)} ({r.runs_candidate} run(s))")
    w(
        f"alpha {r.alpha:g}, Holm over {r.holm_total} statistical families "
        f"({r.tested} judged, {r.exact_only} judged by exact comparison only)"
    )
    w(
        f"rejected: {d['rejected_statistical']} statistical famil(ies), "
        f"{d['exact_failures']} deterministic failure(s)"
    )
    if r.unparsed_candidate:
        w(f"unparsed candidate files: {len(r.unparsed_candidate)}")
    exact = d["exact_failed_families"]
    if exact:
        w("")
        w(f"== Deterministic failures ({len(exact)}) ==")
        for f in r.families:
            if not f.failed_exactly:
                continue
            w(f"{_family_name(f)}: {f.status}, {f.n_mismatch} mismatch(es)")
            for m in f.mismatches:
                w(f"    {m.key}: expected {m.expected}, got {m.got}")
    rej = d["rejected_families"]
    if rej:
        w("")
        w(f"== Rejected statistical families ({len(rej)}; Holm, alpha {r.alpha:g}) ==")
        by_name = {_family_name(f): f for f in r.families if f.rejected}
        for fd in rej[:LISTED_FAMILIES]:
            f = by_name[" | ".join([fd["file"], fd["block"], fd["group"]])]
            w(
                f"#{f.rank} {_family_name(f)}: p={_g(f.p)} (threshold {_g(f.threshold)}), "
                f"p_global={_g(f.p_global)}, p_local={_g(f.p_local)}, D={_g(f.d)}, "
                f"M={_g(f.m)}, n={f.n_test}"
            )
            for t in f.top:
                w(f"    {t.key}: candidate {_g(t.candidate)}, mean {_g(t.mean)}, z={t.z:+.3f}")
        if len(rej) > LISTED_FAMILIES:
            w(f"... {len(rej) - LISTED_FAMILIES} more in the JSON report")
    near = d["lowest_p_not_rejected"]
    if near:
        w("")
        w(f"== Lowest p of families not rejected ({len(near)}) ==")
        for fd in near:
            w(
                f"p={_g(fd['p'])} {fd['file']} | {fd['block']} | {fd['group']} "
                f"(M={_g(fd['m'])}, n={fd['n_tested_fields']})"
            )
    w("")
    w("== Summary per file kind ==")
    w("kind        tested  exact-only  missing  extra")
    for kind in sorted(r.kinds):
        k = r.kinds[kind]
        w(f"{kind:<10} {k['tested']:>7} {k['exact_only']:>11} {k['missing']:>8} {k['extra']:>6}")
    w("")
    w("== Summary per file kind and energy (MeV) ==")
    w("kind @ energy              tested  min p       rejected  exact-failed")
    for label in sorted(r.energies, key=_energy_sort):
        e = r.energies[label]
        w(
            f"{label:<24} {e['tested']:>7}  {_g(float(e['min_p'])):<10} "
            f"{e['rejected']:>8}  {e['exact_failed']:>12}"
        )
    return "\n".join(out) + "\n"
