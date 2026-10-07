# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Gates G3, G4 and G5 of M2 (plan §5), built on ``calibrate``, ``verdict`` and ``inject``.

    python3 -m compare.gates null --ensemble PREFIX [--held-out RUN[@FROM=TO,...] ...] --out DIR
    python3 -m compare.gates g4 --calibration DIR --candidate RUN [--out DIR]
    python3 -m compare.gates sensitivity --calibration DIR --run RUN --out DIR [--group-map FROM=TO]

``null`` (G3): for every ensemble member j it calibrates on the others (``--leave-out j``), judges
j, and collects the suite verdict and every family p-value; then it calibrates on all members and
judges each held-out run (``RUN@run2=run1,tape2=tape1`` applies a group map, as for
``validation/test_run``; ``--input-sha256`` / ``--input`` give the input of runs without
``run.json``). It writes ``summary.json`` and ``summary.txt``: failed suites against the number
a 1 % family-wise rate allows, the top rejected families per run, the pooled p-values with a
Kolmogorov-Smirnov test of uniformity (``p < 1`` values: families without anything testable have
p = 1 exactly) and failures per file kind. Every judgement is written to
``DIR/results/<name>.json`` as soon as it is done and skipped on a rerun, so an interrupted run
resumes. The leave-one-out calibrations are deleted after use (``--keep-calibrations`` keeps them).

``g4`` (G4): the verdict of one candidate plus, per file kind and energy, the median inflation
phi and kappa^2 of the calibration and the candidate's smallest p, with the 18.5 MeV neighbours
(``--energy`` changes the energy) next to each other.

``sensitivity`` (G5): every fault of ``compare.inject`` at the ``max`` and ``mid`` site of every
energy of the run, judged against the calibration (restricted to the one file the fault touches,
Holm over the calibration's family count, which equals the full suite's first step). Per site:
change in units of the MDE, detected, detected in the right family and bin. Pass: every site
whose change is at least 1 MDE is detected in the right family and bin.
"""

from __future__ import annotations

import argparse
import json
import math
import shutil
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import scipy.stats as _stats  # pyright: ignore[reportMissingTypeStubs]
from numpy.typing import NDArray

from compare import inject
from compare.calibrate import Calibration, calibrate, resolve_ensemble
from compare.extract import DEFAULT_CACHE, load_extract
from compare.stats import file_kind
from compare.verdict import VerdictResult, check_inputs, family_energy, judge, sha256_file

__all__ = [
    "SiteResult",
    "aggregate_null",
    "allowed_failures",
    "ks_uniform",
    "main",
    "sensitivity_table",
    "summarize",
]

TOP_FAMILIES = 10
FAMILY_WISE = 0.01


# --------------------------------------------------------------------------------------------
# Aggregation (pure functions, unit-tested)
# --------------------------------------------------------------------------------------------


def allowed_failures(suites: int, rate: float = FAMILY_WISE, level: float = 0.01) -> int:
    """Largest number of failed suites ``f`` with ``P(X >= f) >= level`` for X ~ Binomial(n, rate).

    Seeing more failures than this is inconsistent with the family-wise rate (plan G3: at most 3
    of 65).
    """
    pmf = [math.comb(suites, k) * rate**k * (1 - rate) ** (suites - k) for k in range(suites + 1)]
    tail = 1.0
    allowed = 0
    for f in range(suites + 1):
        if tail >= level:
            allowed = f
        tail -= pmf[f]
    return allowed


def ks_uniform(p: Sequence[float] | NDArray[np.float64]) -> float:
    """p-value of the Kolmogorov-Smirnov test of ``p`` against the uniform law on [0, 1]."""
    if not len(p):
        return float("nan")
    return float(_stats.kstest(np.asarray(p, dtype=np.float64), "uniform").pvalue)  # pyright: ignore[reportUnknownMemberType, reportUnknownArgumentType]


def summarize(result: VerdictResult, name: str) -> dict[str, Any]:
    """One judgement as a JSON-able record (without the p-values, which go to an ``.npy``)."""
    rejected = sorted(
        result.rejected, key=lambda f: (not f.failed_exactly, f.rank or 10**9, f.file)
    )
    per_kind: dict[str, int] = {}
    for f in rejected:
        per_kind[file_kind(f.file)] = per_kind.get(file_kind(f.file), 0) + 1
    return {
        "name": name,
        "passed": result.passed,
        "tested": result.tested,
        "rejected": len(rejected),
        "exact_failures": sum(f.failed_exactly for f in rejected),
        "per_kind": per_kind,
        "runs_calibration": result.runs_calibration,
        "top": [
            {
                "file": f.file, "block": f.block, "group": f.group, "status": f.status,
                "p": None if math.isnan(f.p) else f.p, "rank": f.rank or None,
                "mismatches": [m.key for m in f.mismatches[:3]],
                "top_bins": [t.key for t in f.top[:3]],
            }
            for f in rejected[:TOP_FAMILIES]
        ],
    }  # fmt: skip


def aggregate_null(
    records: Sequence[dict[str, Any]], p_values: Sequence[NDArray[np.float64]]
) -> dict[str, Any]:
    """The G3 summary from the leave-one-out (``kind == "loo"``) and held-out judgements."""
    loo = [r for r in records if r["kind"] == "loo"]
    held = [r for r in records if r["kind"] == "held-out"]
    everything = [*loo, *held]
    failed = [r["name"] for r in everything if not r["passed"]]
    allowed = allowed_failures(len(everything))
    pooled = np.concatenate(p_values) if len(p_values) else np.zeros(0)
    informative = pooled[pooled < 1.0]
    kinds: dict[str, int] = {}
    for r in everything:
        for kind, n in r["per_kind"].items():
            kinds[kind] = kinds.get(kind, 0) + n
    return {
        "suites": len(everything),
        "leave_one_out": len(loo),
        "held_out": len(held),
        "failed": len(failed),
        "failed_names": failed,
        "allowed_failures": allowed,
        "g3_failures_ok": len(failed) <= allowed,
        "pooled_p_values": len(pooled),
        "informative_p_values": len(informative),
        "ks_p_all": ks_uniform(pooled),
        "ks_p_informative": ks_uniform(informative),
        "fraction_below": {
            f"{t:g}": float(np.mean(pooled < t)) if len(pooled) else float("nan")
            for t in (1e-4, 1e-3, 1e-2, 1e-1)
        },
        "failures_per_file_kind": dict(sorted(kinds.items())),
        "runs": [
            {
                k: r[k]
                for k in ("name", "kind", "passed", "tested", "rejected", "exact_failures", "top")
            }
            for r in everything
        ],
    }


@dataclass
class SiteResult:
    """One injected fault and its outcome."""

    fault: str
    spec: str
    energy: str
    file: str
    block: str
    group: str
    keys: list[str]
    delta: list[float]
    mde_abs: list[float | None]
    detected: bool
    right_place: bool
    p: float | None

    @property
    def ratio(self) -> float | None:
        """Largest change over its MDE (the fault counts as ``>= 1 MDE`` when this is)."""
        ratios = [abs(d) / m for d, m in zip(self.delta, self.mde_abs, strict=True) if m]
        return max(ratios) if ratios else None


def sensitivity_table(sites: Sequence[SiteResult]) -> dict[str, Any]:
    """G5 table and pass criterion from the per-site results."""
    above = [s for s in sites if s.ratio is not None and s.ratio >= 1.0]
    missed = [s for s in above if not (s.detected and s.right_place)]
    return {
        "sites": len(sites),
        "sites_at_least_one_mde": len(above),
        "missed": [
            {"fault": s.fault, "spec": s.spec, "ratio": s.ratio, "detected": s.detected}
            for s in missed
        ],
        "detected_below_one_mde": sum(
            1 for s in sites if s not in above and s.detected and s.right_place
        ),
        "g5_ok": not missed and bool(above),
        "rows": [
            {
                "fault": s.fault, "spec": s.spec, "energy": s.energy, "family": s.block,
                "group": s.group, "keys": s.keys, "delta": s.delta, "mde": s.mde_abs,
                "delta_over_mde": s.ratio, "detected": s.detected, "right_place": s.right_place,
                "p": s.p,
            }
            for s in sites
        ],
    }  # fmt: skip


# --------------------------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------------------------


def _parse_group_map(items: Sequence[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for item in items:
        src, sep, dst = item.partition("=")
        if not sep or not src or not dst:
            raise ValueError(f"group map expects FROM=TO, got {item!r}")
        out[src] = dst
    return out


def _input_override(args: argparse.Namespace) -> str | None:
    if args.input_sha256:
        return str(args.input_sha256)
    if args.input:
        return sha256_file(args.input)
    return None


def _judge_and_save(
    results: Path, name: str, kind: str, cal: Calibration, spec: str, override: str | None,
    group_map: dict[str, str],
) -> None:  # fmt: skip
    done = results / f"{name}.json"
    if done.is_file():
        return
    ex = load_extract(spec)
    check_inputs(cal, [ex], override)
    result = judge(cal, [ex], names=[spec], group_map=group_map)
    record = summarize(result, name)
    record["kind"] = kind
    record["spec"] = spec
    np.save(results / f"{name}.p.npy", result.p_values)
    done.write_text(json.dumps(record, indent=1, sort_keys=True))


def _write_summary(out: Path, summary: dict[str, Any]) -> None:
    (out / "summary.json").write_text(json.dumps(summary, indent=1, sort_keys=True) + "\n")
    lines = [
        f"G3 null validation: {summary['failed']} failed suites of {summary['suites']} "
        f"({summary['leave_one_out']} leave-one-out, {summary['held_out']} held-out); "
        f"allowed {summary['allowed_failures']} -> {'OK' if summary['g3_failures_ok'] else 'FAIL'}",
        f"failed: {', '.join(summary['failed_names']) or '-'}",
        f"pooled p-values: {summary['pooled_p_values']} "
        f"({summary['informative_p_values']} below 1);"
        f" KS p (all) {summary['ks_p_all']:.3g}, KS p (p < 1) {summary['ks_p_informative']:.3g}",
        "fraction of p below: "
        + ", ".join(f"{k}: {v:.4g}" for k, v in summary["fraction_below"].items()),
        f"rejected families per file kind: {summary['failures_per_file_kind']}",
        "",
    ]
    for r in summary["runs"]:
        lines.append(
            f"{r['name']} [{r['kind']}] {'pass' if r['passed'] else 'FAIL'}: tested {r['tested']}, "
            f"rejected {r['rejected']} ({r['exact_failures']} exact)"
        )
        for t in r["top"][:3]:
            lines.append(
                f"    {t['status']} p={t['p']} {t['file']} | {t['block']} | {t['group']} "
                f"{t['mismatches'] or t['top_bins']}"
            )
    (out / "summary.txt").write_text("\n".join(lines) + "\n")


# --------------------------------------------------------------------------------------------
# G3
# --------------------------------------------------------------------------------------------


def run_null(args: argparse.Namespace) -> int:
    out: Path = args.out
    results = out / "results"
    results.mkdir(parents=True, exist_ok=True)
    members = resolve_ensemble(args.ensemble, args.exclude)
    override = _input_override(args)
    for j, member in enumerate(members):
        name = f"loo-{Path(member).name}"
        if (results / f"{name}.json").is_file():
            continue
        cal_dir = out / "cal" / name
        if not (cal_dir / "manifest.json").is_file():
            calibrate(
                [m for m in members if m != member], cal_dir, excluded=[member], cache=args.cache,
                jobs=args.jobs, mde=[], input_sha256=override, log=None,
            )  # fmt: skip
        print(f"[{j + 1}/{len(members)}] judging {member}", file=sys.stderr, flush=True)
        _judge_and_save(results, name, "loo", Calibration.open(cal_dir), member, override, {})
        if not args.keep_calibrations:
            shutil.rmtree(cal_dir, ignore_errors=True)
    held = [h for h in args.held_out]
    if held:
        full = out / "cal" / "full"
        if not (full / "manifest.json").is_file():
            calibrate(members, full, cache=args.cache, jobs=args.jobs, input_sha256=override)
        cal = Calibration.open(full)
        for spec in held:
            run, _, mapping = spec.partition("@")
            gmap = _parse_group_map([m for m in mapping.split(",") if m])
            _judge_and_save(results, f"held-{Path(run).name}", "held-out", cal, run, override, gmap)
    records = [json.loads(p.read_text()) for p in sorted(results.glob("*.json"))]
    ps = [np.load(p) for p in sorted(results.glob("*.p.npy"))]
    summary = aggregate_null(records, ps)
    _write_summary(out, summary)
    print((out / "summary.txt").read_text().split("\n\n")[0])
    return 0 if summary["g3_failures_ok"] else 1


# --------------------------------------------------------------------------------------------
# G4
# --------------------------------------------------------------------------------------------


def energy_detail(
    cal: Calibration, result: VerdictResult, energy: float, neighbours: int = 2
) -> list[dict[str, Any]]:
    """Per (file kind, energy): calibration phi and kappa^2 medians and the candidate's min p,
    for ``energy`` and its ``neighbours`` nearest energies on each side."""
    phis: dict[str, list[float]] = {}
    kappas: dict[str, list[float]] = {}
    for rel in cal.rels:
        cf = cal.file(rel)
        if cf is None:
            continue
        for block, group in cf.families:
            label = f"{file_kind(rel)} @ {family_energy(rel, group) or '-'}"
            fam = cf.family(block, group)
            if fam is None or not fam.null.n_stoch:
                continue
            if not math.isnan(fam.null.phi):
                phis.setdefault(label, []).append(fam.null.phi)
            local = cal.local_of(fam)
            kappas.setdefault(label, []).append(local.kappa2)
    levels = sorted({float(k.split(" @ ")[1]) for k in phis if k.split(" @ ")[1] != "-"})
    if energy not in levels:
        raise ValueError(f"no family at {energy} MeV in the calibration (have {levels})")
    at = levels.index(energy)
    wanted = set(levels[max(0, at - neighbours) : at + neighbours + 1])
    rows: list[dict[str, Any]] = []
    for label in sorted(phis, key=lambda s: (s.split(" @ ")[0], s)):
        kind, _, e = label.partition(" @ ")
        if e == "-" or float(e) not in wanted:
            continue
        summary = result.energies.get(label, {})
        rows.append(
            {
                "kind": kind, "energy": float(e), "families": len(phis[label]),
                "median_phi": float(np.median(phis[label])),
                "median_kappa2": float(np.median(kappas.get(label, [float("nan")]))),
                "candidate_min_p": summary.get("min_p"), "rejected": summary.get("rejected", 0),
                "exact_failed": summary.get("exact_failed", 0),
            }
        )  # fmt: skip
    return sorted(rows, key=lambda r: (r["kind"], r["energy"]))


def run_g4(args: argparse.Namespace) -> int:
    cal = Calibration.open(args.calibration)
    ex = load_extract(args.candidate, args.cache)
    check_inputs(cal, [ex], _input_override(args))
    result = judge(cal, [ex], names=[args.candidate])
    detail = energy_detail(cal, result, args.energy)
    record = summarize(result, Path(args.candidate).name)
    record["energy_detail"] = detail
    lines = [
        f"G4 {args.candidate}: {'PASS' if result.passed else 'FAIL'} ({result.tested} families)"
    ]
    lines.append(
        f"{'kind':<6}{'E/MeV':>8}{'fams':>7}{'med phi':>12}{'med kappa2':>12}"
        f"{'min p':>12}{'rej':>5}"
    )
    for r in detail:
        mp = r["candidate_min_p"]
        lines.append(
            f"{r['kind']:<6}{r['energy']:>8g}{r['families']:>7}{r['median_phi']:>12.4g}"
            f"{r['median_kappa2']:>12.4g}{(mp if mp is not None else float('nan')):>12.4g}"
            f"{r['rejected']:>5}"
        )
    text = "\n".join(lines) + "\n"
    if args.out:
        args.out.mkdir(parents=True, exist_ok=True)
        (args.out / "g4.json").write_text(json.dumps(record, indent=1, sort_keys=True) + "\n")
        (args.out / "g4.txt").write_text(text)
    print(text, end="")
    return 0 if result.passed else 1


# --------------------------------------------------------------------------------------------
# G5
# --------------------------------------------------------------------------------------------


def judge_site(
    cal: Calibration, ex_dir: Path, site: inject.Site
) -> tuple[bool, bool, float | None]:
    """``(detected, right place, p)`` of an injected extract, judged on the one file touched."""
    result = judge(
        cal, [load_extract(ex_dir)], files=[site.rel], holm_total="calibration",
        group_map={},
    )  # fmt: skip
    hits = [
        f
        for f in result.rejected
        if (f.file, f.block, f.group) == (site.rel, site.block, site.group)
    ]
    if not hits:
        return bool(result.rejected), False, None
    hit = hits[0]
    keys = {t.key for t in hit.top}
    right = any(k in keys for k in site.keys)
    return True, right, None if math.isnan(hit.p) else hit.p


def run_sensitivity(args: argparse.Namespace) -> int:
    cal = Calibration.open(args.calibration)
    ex = load_extract(args.run, args.cache)
    gmap = _parse_group_map(args.group_map)
    out: Path = args.out
    results = out / "sites"
    results.mkdir(parents=True, exist_ok=True)
    sites: list[SiteResult] = []
    for fault in args.fault or inject.FAULTS:
        listed = inject.list_sites(ex, fault, cal=cal, candidate_runs=1, group_map=gmap)
        for n, site in enumerate(listed):
            tag = f"{fault}-{n:03d}"
            done = results / f"{tag}.json"
            if done.is_file():
                sites.append(SiteResult(**json.loads(done.read_text())))
                continue
            work = out / "work" / tag
            inject.inject(ex, fault, site.spec, work)
            detected, right, p = judge_site(cal, work, site)
            shutil.rmtree(work, ignore_errors=True)
            group = site.group
            result = SiteResult(
                fault, site.spec, family_energy(site.rel, group), site.rel, site.block, group,
                list(site.keys), [a - b for a, b in zip(site.after, site.values, strict=True)],
                list(site.mde_abs), detected, right, p,
            )  # fmt: skip
            done.write_text(json.dumps(result.__dict__, sort_keys=True))
            sites.append(result)
    table = sensitivity_table(sites)
    (out / "sensitivity.json").write_text(json.dumps(table, indent=1, sort_keys=True) + "\n")
    lines = [
        f"G5: {table['sites']} sites, {table['sites_at_least_one_mde']} at least 1 MDE, "
        f"{len(table['missed'])} missed -> {'OK' if table['g5_ok'] else 'FAIL'}",
        f"{'fault':<10}{'E/MeV':>8} {'spec':<34}{'delta/MDE':>10} det right",
    ]
    for row in table["rows"]:
        r = row["delta_over_mde"]
        lines.append(
            f"{row['fault']:<10}{row['energy']:>8} {row['spec']:<34}"
            f"{(f'{r:.3g}' if r is not None else 'n/a'):>10} {int(row['detected'])}   "
            f"{int(row['right_place'])}"
        )
    (out / "sensitivity.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines[:1]))
    return 0 if table["g5_ok"] else 1


# --------------------------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------------------------


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m compare.gates", description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    common.add_argument("--input", type=Path, help="input file of runs without run.json")
    common.add_argument("--input-sha256")
    null = sub.add_parser("null", parents=[common], help="gate G3")
    null.add_argument("--ensemble", nargs="+", required=True)
    null.add_argument("--exclude", nargs="*", default=[])
    null.add_argument("--held-out", action="append", default=[], metavar="RUN[@FROM=TO,...]")
    null.add_argument("--out", type=Path, required=True)
    null.add_argument("--jobs", type=int, default=4)
    null.add_argument("--keep-calibrations", action="store_true")
    g4 = sub.add_parser("g4", parents=[common], help="gate G4")
    g4.add_argument("--calibration", required=True)
    g4.add_argument("--candidate", required=True)
    g4.add_argument("--energy", type=float, default=18.5)
    g4.add_argument("--out", type=Path)
    sens = sub.add_parser("sensitivity", parents=[common], help="gate G5")
    sens.add_argument("--calibration", required=True)
    sens.add_argument("--run", required=True)
    sens.add_argument("--out", type=Path, required=True)
    sens.add_argument("--fault", action="append", choices=inject.FAULTS)
    sens.add_argument("--group-map", action="append", default=[], metavar="FROM=TO")
    args = parser.parse_args(argv)
    try:
        if args.cmd == "null":
            return run_null(args)
        if args.cmd == "g4":
            return run_g4(args)
        return run_sensitivity(args)
    except (OSError, ValueError, KeyError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
