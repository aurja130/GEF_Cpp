# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""M6.0 patch check: does the setup-only build change anything the run set-up computes?

Compares, entry by entry, a setup-only corpus capture (``-d GEF_SETUP_ONLY``) with full runs of
the same inputs and seed (``harness.corpus run`` of a build without it):

* probes P0, P1 and P1b, record by record and variable by variable (raw text, so bit for bit);
* stdout: from ``File 'file.in' found.`` on, the setup-only lines must appear in the full run in
  the same order (the full run prints more: pre-pass, passes, writers).

Usage::

    python3 -m harness.patch_check SETUP_DIR FULL_DIR [--json OUT]

Both directories hold one run directory per corpus entry (``<dir>/<id>/work/probes/...``);
every entry of FULL_DIR is checked. The report lists, per entry and probe file, the variables
that differ with the records (``rec``) they differ in, and whether stdout is a subsequence.
Exit status 0 always (differences are expected and explained in MILESTONE_6_PLAN.md); 1 when
an entry is missing.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import Any

from harness.probes import ProbeRecord, read_probe_file

__all__ = ["check_entry", "probe_differences", "stdout_subsequence"]

PROBE_FILES = ("P0.txt", "P1.txt", "P1b.txt")
STDOUT_START = "File 'file.in' found."


def _records(path: Path) -> list[ProbeRecord]:
    return read_probe_file(path) if path.is_file() else []


def probe_differences(setup: Path, full: Path) -> dict[str, Any]:
    """Variables that differ between two probe files of the same kind, with their records."""
    a, b = _records(setup), _records(full)
    result: dict[str, Any] = {"records": [len(a), len(b)], "variables": {}}
    variables: dict[str, list[str]] = result["variables"]
    for ra, rb in zip(a, b, strict=False):
        rec = ra.context.get("rec", "-")
        if ra.context != rb.context:
            variables.setdefault("<context>", []).append(rec)
            continue
        for name in sorted(set(ra.variables) | set(rb.variables)):
            va, vb = ra.variables.get(name), rb.variables.get(name)
            if va is None or vb is None or va.texts != vb.texts or va.bounds != vb.bounds:
                variables.setdefault(name, []).append(rec)
    return result


def _stdout_lines(path: Path) -> list[str]:
    lines = path.read_text(encoding="latin-1").split("\n")
    return lines[lines.index(STDOUT_START) :] if STDOUT_START in lines else lines


def stdout_subsequence(setup: Path, full: Path) -> dict[str, Any]:
    """Whether the setup-only stdout lines occur in order in the full-run stdout."""
    a, b = _stdout_lines(setup), _stdout_lines(full)
    j = 0
    for line in a:
        while j < len(b) and b[j] != line:
            j += 1
        if j == len(b):
            return {"subsequence": False, "first_missing": line, "extra_lines": len(b) - len(a)}
        j += 1
    return {"subsequence": True, "extra_lines": len(b) - len(a)}


def check_entry(setup_run: Path, full_run: Path) -> dict[str, Any]:
    """The probe and stdout comparison of one entry."""
    report: dict[str, Any] = {}
    for name in PROBE_FILES:
        report[name] = probe_differences(
            setup_run / "work" / "probes" / name, full_run / "work" / "probes" / name
        )
    report["stdout"] = stdout_subsequence(setup_run / "stdout.log", full_run / "stdout.log")
    return report


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m harness.patch_check", description=__doc__)
    parser.add_argument("setup_dir", type=Path)
    parser.add_argument("full_dir", type=Path)
    parser.add_argument("--json", type=Path, default=None)
    args = parser.parse_args(argv)
    reports: dict[str, Any] = {}
    missing = False
    for full_run in sorted(p for p in args.full_dir.iterdir() if p.is_dir()):
        setup_run = args.setup_dir / full_run.name
        if not setup_run.is_dir():
            print(f"{full_run.name}: no setup-only run in {args.setup_dir}")
            missing = True
            continue
        report = check_entry(setup_run, full_run)
        reports[full_run.name] = report
        parts: list[str] = []
        for name in PROBE_FILES:
            diff: dict[str, Any] = report[name]
            records: list[int] = diff["records"]
            variables: dict[str, list[str]] = diff["variables"]
            counts = "/".join(str(n) for n in records)
            names = ", ".join(f"{v}({len(r)})" for v, r in variables.items()) or "equal"
            parts.append(f"{name} [{counts}] {names}")
        out = report["stdout"]
        parts.append(
            "stdout subsequence" if out["subsequence"] else f"stdout NOT: {out['first_missing']!r}"
        )
        print(f"{full_run.name}: " + "; ".join(parts))
    if args.json is not None:
        args.json.write_text(json.dumps(reports, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
