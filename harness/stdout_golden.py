# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Store-derived golden ``m6-stdout``: where each run's console range starts, and its digest.

The C++ console test (``run_console_test.cpp``) reads this golden. Format (``runs.txt``):

    # m6-stdout runs 1
    <run> <mode> <start> <bytes> <fnv>

Derivation rules:

- Runs are numbered from 1 in plan order over the captures, as ``m6-p0`` and ``m6-plan`` number
  them: a run without ``work/file.in`` takes no number and no line. ``<mode>`` is ``setup`` or
  ``full``, as ``m6-plan`` gives it (``plan_golden.run_block``, which also checks the run).
- The console range of MILESTONE_6_PLAN.md D3 starts at the first line BASIC prints at or after
  ``Nextfitloop:`` (GEF.bas:2519) and runs to the end of ``stdout.log``. In batch mode the first
  such line is FitparRead's notice ``File Fitpar.dat found.`` (GEF.bas:2555) when the run's
  ``work/`` holds ``Fitpar.dat``, else ``File 'file.in' found.`` (GEF.bas:2700). Start-up printed
  the same FitparRead notice at GEF.bas:1017, so the start is the last ``File Fitpar.dat found.``
  line before the first ``File 'file.in' found.`` line, and an earlier one (start-up's) must
  exist. ``<start>`` is its 1-based line number; a run's ``work/Fitpar.dat`` is recorded among the
  golden's sources.
- ``<bytes>`` and ``<fnv>``: the length and the FNV-1a 64 digest (16 lower-case hex digits) of the
  bytes of ``stdout.log`` from the start line to the end, as they are.

Usage from the repository root: ``python3 -m harness.stdout_golden [--out DIR] [--replace]``
"""

from __future__ import annotations

import argparse
import shutil
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Final

from harness.common import STORE_CAPTURES, HarnessError
from harness.golden import GOLDEN_DIR, write_derived
from harness.golden_store import StoreRun, capture_runs
from harness.p0_golden import CAPTURES
from harness.plan_golden import run_block
from harness.probe_fingerprints import FNV_OFFSET, FNV_PRIME, MASK64

GOLDEN_OUT: Final[Path] = GOLDEN_DIR / "m6-stdout"
TOOL: Final[str] = "python3 -m harness.stdout_golden"
RUNS_HEADER: Final[str] = "# m6-stdout runs 1"
FILEIN_FOUND: Final[bytes] = b"File 'file.in' found."
FITPAR_FOUND: Final[bytes] = b"File Fitpar.dat found."


@dataclass(frozen=True)
class Golden:
    """The text of ``runs.txt`` and the store files it was derived from."""

    runs_text: str
    sources: tuple[tuple[str, str], ...]  # (capture id, file in capture), sorted


def fnv1a64_bytes(data: bytes) -> int:
    """FNV-1a 64 over ``data`` as it is (no line ends added)."""
    h = FNV_OFFSET
    for byte in data:
        h = ((h ^ byte) * FNV_PRIME) & MASK64
    return h


def console_start(stdout: bytes, *, fitpar: bool, where: str) -> int:
    """The 0-based index of the line that starts the console range (rules in the docstring)."""
    lines = stdout.split(b"\n")
    try:
        found = lines.index(FILEIN_FOUND)
    except ValueError:
        raise HarnessError(f"{where}: stdout.log has no line {FILEIN_FOUND!r}") from None
    if not fitpar:
        return found
    for index in range(found - 1, -1, -1):
        if lines[index] == FITPAR_FOUND:
            if FITPAR_FOUND not in lines[:index]:
                raise HarnessError(
                    f"{where}: no start-up {FITPAR_FOUND!r} line precedes line {index + 1}"
                )
            return index
    raise HarnessError(f"{where}: Fitpar.dat is present but no {FITPAR_FOUND!r} line precedes")


def _run_line(run: StoreRun, number: int, mode: str, files: set[tuple[str, str]]) -> str:
    """The ``runs.txt`` line of ``run``; adds the store files it read to ``files``."""
    stdout = (run.run_dir / "stdout.log").read_bytes()
    fitpar_path = run.run_dir / "work" / "Fitpar.dat"
    fitpar = fitpar_path.is_file()
    if fitpar:
        files.add((run.capture, f"{run.rel}/work/Fitpar.dat"))
    start = console_start(stdout, fitpar=fitpar, where=run.where)
    offset = sum(len(line) + 1 for line in stdout.split(b"\n")[:start])
    tail = stdout[offset:]
    return f"{number} {mode} {start + 1} {len(tail)} {fnv1a64_bytes(tail):016x}"


def build_golden(captures_dir: Path, captures: Sequence[str]) -> Golden:
    """Derive the m6-stdout golden for ``captures`` under ``captures_dir``; writes nothing."""
    lines: list[str] = []
    files: set[tuple[str, str]] = set()
    number = 0
    for capture in captures:
        found = capture_runs(captures_dir, capture)
        if found.has_corpus:
            files.add((capture, "corpus.json"))
        for run in found.runs:
            if not run.has_file_in():
                files.add((capture, f"{run.rel}/run.json"))
                continue
            number += 1
            block = run_block(run)
            files.update((capture, path) for path in block.files)
            mode = block.lines[0].removeprefix("mode ")
            lines.append(_run_line(run, number, mode, files))
    return Golden(
        runs_text="".join(f"{line}\n" for line in (RUNS_HEADER, *lines)),
        sources=tuple(sorted(files)),
    )


def write_golden(out: Path, golden: Golden, *, replace: bool) -> None:
    """Write ``runs.txt`` into ``out``, then its ``derived.json``."""
    if out.exists():
        if not replace:
            raise HarnessError(f"golden {out} exists; pass --replace to produce it again")
        shutil.rmtree(out)
    out.mkdir(parents=True)
    (out / "runs.txt").write_text(golden.runs_text, encoding="utf-8", newline="\n")
    write_derived(out, TOOL, list(golden.sources))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Derive the m6-stdout golden from the store.")
    parser.add_argument("--out", type=Path, default=GOLDEN_OUT, help="golden directory to write")
    parser.add_argument("--replace", action="store_true", help="replace an existing golden")
    args = parser.parse_args(argv)
    out: Path = args.out
    replace: bool = args.replace
    try:
        golden = build_golden(STORE_CAPTURES, CAPTURES)
        write_golden(out, golden, replace=replace)
    except HarnessError as exc:
        print(f"stdout_golden: {exc}", file=sys.stderr)
        return 2
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
