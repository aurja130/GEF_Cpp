# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Produce null-calibration ensembles: seeded ``ref-1`` runs stored in the reference store (M2.4).

Usage (from the repository root)::

    python3 -m compare.ensemble run <input> --seeds 1001-1020 [--jobs N] [--binary PATH]
    python3 -m compare.ensemble status <input> --seeds 1001-1020

``<input>`` names ``harness/inputs/<input>.in``. Each seed becomes the capture
``m2-ens-<input>-s<seed>`` (underscores in the input name become hyphens). The job is
resumable: seeds whose capture already exists are skipped, so an interrupted run is simply
restarted with the same command. A finished run is stored with ``harness.store`` and its
scratch copy under ``build/compare/ensemble/`` is deleted. The binary defaults to ``ref-1``
from ``manifests/reference_binary.json`` (its stored copy), so every member uses the
promoted reference build.

Exit status: 0 when every requested seed is stored, 1 if any run or store step failed, 2 on
usage errors.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
import time
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

from harness.common import INPUTS_DIR, MANIFEST_STORE_DIR, REPO_ROOT, HarnessError
from harness.run import run
from harness.store import add_capture

__all__ = ["capture_id", "parse_seeds", "ref1_binary", "run_ensemble"]

SCRATCH_ROOT = REPO_ROOT / "build" / "compare" / "ensemble"
REFERENCE_BINARY_MANIFEST = REPO_ROOT / "manifests" / "reference_binary.json"


@dataclass(frozen=True)
class MemberResult:
    seed: int
    capture: str
    status: str  # "stored", "skipped" or "failed: <reason>"
    wall_s: float


def parse_seeds(text: str) -> list[int]:
    """Parse ``1001-1020`` or ``1,5,9-11`` into a sorted list of distinct seeds."""
    seeds: set[int] = set()
    for part in text.split(","):
        part = part.strip()
        if not part:
            raise ValueError(f"empty item in seed list {text!r}")
        if "-" in part:
            lo_text, hi_text = part.split("-", 1)
            lo, hi = int(lo_text), int(hi_text)
            if lo > hi:
                raise ValueError(f"descending seed range {part!r}")
            seeds.update(range(lo, hi + 1))
        else:
            seeds.add(int(part))
    if any(s < 0 or s > 0xFFFFFFFF for s in seeds):
        raise ValueError("seeds must be within 0..4294967295")
    return sorted(seeds)


def capture_id(input_name: str, seed: int) -> str:
    return f"m2-ens-{input_name.replace('_', '-')}-s{seed}"


def ref1_binary(manifest: Path = REFERENCE_BINARY_MANIFEST) -> Path:
    """The stored ``ref-1`` binary named by ``manifests/reference_binary.json``."""
    data = json.loads(manifest.read_text(encoding="utf-8"))
    path = REPO_ROOT / str(data["store_path"])
    if not path.is_file():
        raise HarnessError(f"ref-1 binary {path} is missing; restore the reference store")
    return path


def _member(input_file: Path, input_name: str, seed: int, binary: Path) -> MemberResult:
    cid = capture_id(input_name, seed)
    if (MANIFEST_STORE_DIR / f"{cid}.json").is_file():
        return MemberResult(seed, cid, "skipped", 0.0)
    scratch = SCRATCH_ROOT / cid
    if scratch.exists():
        shutil.rmtree(scratch)  # leftover of an interrupted attempt
    start = time.perf_counter()
    try:
        run(binary, input_file, scratch, seed)
        add_capture(
            scratch,
            cid,
            "run",
            f"M2 null-calibration ensemble member: ref-1, input {input_name}, seed {seed}",
        )
    except HarnessError as exc:
        return MemberResult(seed, cid, f"failed: {exc}", time.perf_counter() - start)
    shutil.rmtree(scratch)
    return MemberResult(seed, cid, "stored", time.perf_counter() - start)


def run_ensemble(
    input_name: str, seeds: Sequence[int], jobs: int, binary: Path | None = None
) -> list[MemberResult]:
    """Run and store every missing ensemble member; returns one result per seed."""
    input_file = INPUTS_DIR / f"{input_name}.in"
    if not input_file.is_file():
        raise HarnessError(f"input {input_file} does not exist")
    exe = binary if binary is not None else ref1_binary()
    SCRATCH_ROOT.mkdir(parents=True, exist_ok=True)
    results: list[MemberResult] = []
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        futures = [pool.submit(_member, input_file, input_name, s, exe) for s in seeds]
        for future in futures:
            result = future.result()
            results.append(result)
            print(f"{result.capture}: {result.status} ({result.wall_s:.0f} s)", flush=True)
    return results


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m compare.ensemble")
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("run", "status"):
        p = sub.add_parser(name)
        p.add_argument("input")
        p.add_argument("--seeds", required=True)
        if name == "run":
            p.add_argument("--jobs", type=int, default=8)
            p.add_argument("--binary", type=Path)
    args = parser.parse_args(argv)
    try:
        seeds = parse_seeds(args.seeds)
    except ValueError as exc:
        parser.error(str(exc))
    input_name: str = args.input
    if args.command == "status":
        missing = [
            s
            for s in seeds
            if not (MANIFEST_STORE_DIR / f"{capture_id(input_name, s)}.json").is_file()
        ]
        print(f"{len(seeds) - len(missing)} of {len(seeds)} stored; missing: {missing or 'none'}")
        return 0 if not missing else 1
    try:
        results = run_ensemble(input_name, seeds, args.jobs, args.binary)
    except HarnessError as exc:
        print(f"compare.ensemble: {exc}", file=sys.stderr)
        return 1
    failed = [r for r in results if r.status.startswith("failed")]
    print(f"{len(results) - len(failed)} of {len(results)} members stored or present")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
