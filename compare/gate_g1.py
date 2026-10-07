# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Gate G1 (M2): parser fidelity over every real file.

    python3 -m compare.gate_g1 [--json OUT] [--include-ensembles] [--workers N]

* ``endf``, ``mvd``, ``par``, ``dmp`` files: ``roundtrip(path)`` must equal the file bytes
  (plan D4);
* ``out`` files: ``coverage(path).ok`` must be true (every numeric token emitted or allow-listed).

Inputs: the library tapes ``validation/reference/gefy_{nfy,sfy}_ENDF/*.dat`` (as
``work/ENDF/<name>``), ``validation/test_run`` and every capture of
``validation/reference_store/captures`` (``m2-ens-*`` only with ``--include-ensembles``).
A file goes to the first parser, in loader order, whose ``PATTERNS`` match its run-relative path.
Exit status: 0 iff every file passes and every needed parser module exists.
"""

from __future__ import annotations

import argparse
import fnmatch
import importlib
import json
import os
import sys
import time
from collections.abc import Sequence
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path
from types import ModuleType
from typing import Any

from compare.loader import PARSER_NAMES, run_files

__all__ = ["GATE_KINDS", "GateResult", "check_file", "main", "run_gate"]

GATE_KINDS: tuple[str, ...] = ("endf", "mvd", "par", "out", "dmp")
_ROOT = Path(__file__).resolve().parent.parent
_VALIDATION = _ROOT / "validation"
_LIBRARIES = ("reference/gefy_nfy_ENDF", "reference/gefy_sfy_ENDF")
_CAPTURES = "reference_store/captures"


@dataclass(frozen=True)
class Job:
    kind: str
    path: str
    rel: str
    origin: str


@dataclass
class KindResult:
    files: int = 0
    passed: int = 0
    seconds: float = 0.0
    failures: list[tuple[str, str]] = field(default_factory=lambda: [])


@dataclass
class GateResult:
    kinds: dict[str, KindResult] = field(default_factory=lambda: {})
    missing_modules: list[str] = field(default_factory=lambda: [])

    @property
    def ok(self) -> bool:
        return not self.missing_modules and all(r.passed == r.files for r in self.kinds.values())


def _first_difference(a: bytes, b: bytes) -> str:
    for i, (x, y) in enumerate(zip(a, b, strict=False)):
        if x != y:
            line = a.count(b"\n", 0, i) + 1
            return f"first difference at byte {i} (line {line})"
    return f"length differs: file {len(a)} bytes, rebuilt {len(b)} bytes"


def check_file(kind: str, path: str, rel: str) -> tuple[bool, str, float]:
    """Run the gate check of one file in a worker; returns (passed, message, seconds)."""
    module: ModuleType = importlib.import_module(f"compare.parsers.{kind}")
    start = time.perf_counter()
    try:
        if hasattr(module, "roundtrip"):
            original = Path(path).read_bytes()
            rebuilt: bytes = module.roundtrip(Path(path))
            ok = rebuilt == original
            message = "" if ok else _first_difference(original, rebuilt)
        else:
            report: Any = module.coverage(Path(path))
            ok = bool(report.ok)
            message = "" if ok else str(report)
    except Exception as exc:  # parser failures are gate failures, whatever their type
        ok, message = False, f"{type(exc).__name__}: {exc}"
    return ok, message, time.perf_counter() - start


def _inputs(include_ensembles: bool) -> list[tuple[str, dict[str, Path]]]:
    inputs: list[tuple[str, dict[str, Path]]] = []
    for library in _LIBRARIES:
        directory = _VALIDATION / library
        if directory.is_dir():
            files = {f"work/ENDF/{p.name}": p for p in sorted(directory.glob("*.dat"))}
            inputs.append((library, files))
    test_run = _VALIDATION / "test_run"
    if test_run.is_dir():
        inputs.append(("test_run", run_files(test_run)))
    captures = _VALIDATION / _CAPTURES
    if captures.is_dir():
        for capture in sorted(captures.iterdir()):
            if not capture.is_dir():
                continue
            if capture.name.startswith("m2-ens-") and not include_ensembles:
                continue
            inputs.append((f"capture {capture.name}", run_files(capture)))
    return inputs


def _jobs(
    inputs: list[tuple[str, dict[str, Path]]],
    modules: list[tuple[str, ModuleType]],
    wanted: Sequence[str],
) -> list[Job]:
    jobs: list[Job] = []
    for origin, files in inputs:
        for rel, path in files.items():
            for name, module in modules:
                patterns: tuple[str, ...] = module.PATTERNS
                if any(fnmatch.fnmatchcase(rel, p) for p in patterns):
                    if name in wanted:
                        jobs.append(Job(name, str(path), rel, origin))
                    break
    return jobs


def run_gate(include_ensembles: bool = False, workers: int | None = None) -> GateResult:
    result = GateResult(kinds={k: KindResult() for k in GATE_KINDS})
    modules: list[tuple[str, ModuleType]] = []
    for name in PARSER_NAMES:
        try:
            modules.append((name, importlib.import_module(f"compare.parsers.{name}")))
        except ModuleNotFoundError as exc:
            if exc.name != f"compare.parsers.{name}":
                raise
            result.missing_modules.append(name)
    jobs = _jobs(_inputs(include_ensembles), modules, GATE_KINDS)
    count = workers or min(4, os.cpu_count() or 1)
    with ProcessPoolExecutor(max_workers=count) as pool:
        futures = [(job, pool.submit(check_file, job.kind, job.path, job.rel)) for job in jobs]
        for job, future in futures:
            ok, message, seconds = future.result()
            kind = result.kinds[job.kind]
            kind.files += 1
            kind.seconds += seconds
            if ok:
                kind.passed += 1
            else:
                kind.failures.append((f"{job.origin}: {job.rel}", message))
    return result


def format_result(result: GateResult, limit: int = 10) -> str:
    lines: list[str] = []
    for name in result.missing_modules:
        lines.append(f"MISSING parser module compare.parsers.{name}")
    for kind, r in result.kinds.items():
        status = "ok" if r.passed == r.files else "FAIL"
        what = "coverage" if kind == "out" else "round-trip"
        lines.append(
            f"{kind:5s} {what:10s} {r.passed}/{r.files} files  {r.seconds:7.1f} s  {status}"
        )
        lines += [f"    {where}: {msg}" for where, msg in r.failures[:limit]]
        if len(r.failures) > limit:
            lines.append(f"    ... {len(r.failures) - limit} more")
    lines.append("G1: PASS" if result.ok else "G1: FAIL")
    return "\n".join(lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="compare.gate_g1", description="Gate G1 over real files")
    parser.add_argument("--json", type=Path, default=None, metavar="OUT")
    parser.add_argument("--include-ensembles", action="store_true")
    parser.add_argument("--workers", type=int, default=None)
    try:
        args = parser.parse_args(argv)
    except SystemExit as exc:
        return 2 if exc.code else 0
    out: Path | None = args.json
    try:
        result = run_gate(args.include_ensembles, args.workers)
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    print(format_result(result))
    if out is not None:
        payload = {
            "ok": result.ok,
            "missing_modules": result.missing_modules,
            "kinds": {
                k: {
                    "files": r.files,
                    "passed": r.passed,
                    "seconds": r.seconds,
                    "failures": [{"where": w, "message": m} for w, m in r.failures],
                }
                for k, r in result.kinds.items()
            },
        }
        out.write_text(json.dumps(payload, indent=1) + "\n", encoding="utf-8")
    return 0 if result.ok else 1


if __name__ == "__main__":
    sys.exit(main())
