# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Store-derived golden ``m6-setup``: the P1 and P1b fingerprints of every run, format 1.

The C++ corpus test (``run_corpus_test.cpp``) reads this golden. Format (``fingerprints.txt``):

    # m6-setup fingerprints 1
    exclude-full Spin_CN T Var_PZ_S3_olap_curv Z
    <run> P1 <rec> <lines> <fnv>
    <run> P1b <rec> <lines> <fnv>

Derivation rules:

- Runs are numbered from 1 in plan order over the captures, as ``m6-p0`` numbers them: a run
  without ``work/file.in`` takes no number and no line. Each replayed run is checked by
  ``plan_golden.run_block``, which also checks the P1/P1b pairing, the record numbering and
  Fenhance.
- For each run in ascending number: its P1 records in ascending ``rec``, then its P1b records in
  ascending ``rec``. A run without P1 or P1b records has no line.
- ``<lines>`` and ``<fnv>``: the record's dump lines grouped by NAME in ascending byte order of
  NAME, kept in dump order within a NAME, each line followed by a newline, hashed with FNV-1a 64
  (16 lower-case hex digits), as ``m6-p0`` hashes them. Each NAME's lines must be contiguous
  within their record.
- In a full run (``mode full`` in ``m6-plan``) the P1 lines whose NAME is in ``exclude-full`` are
  left out of the record before hashing, and out of ``<lines>``. Those values come from the step
  body (pre-pass and passes), which M6.3 does not port. Set-up runs keep every line, and P1b is
  never filtered.
- Each record must carry its step context (``step=<s>``, not ``-``).

Usage from the repository root: ``python3 -m harness.setup_golden [--out DIR] [--replace]``
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
from harness.golden_store import StoreRun, capture_runs, read_dump
from harness.p0_golden import CAPTURES, record_fnv
from harness.plan_golden import run_block
from harness.probes import parse_line

GOLDEN_OUT: Final[Path] = GOLDEN_DIR / "m6-setup"
TOOL: Final[str] = "python3 -m harness.setup_golden"
FINGERPRINTS_HEADER: Final[str] = "# m6-setup fingerprints 1"
EXCLUDE_FULL: Final[tuple[str, ...]] = ("Spin_CN", "T", "Var_PZ_S3_olap_curv", "Z")
EXCLUDE_LINE: Final[str] = "exclude-full " + " ".join(EXCLUDE_FULL)
P1_PROBE: Final[str] = "P1"
P1B_PROBE: Final[str] = "P1b"


@dataclass(frozen=True)
class Golden:
    """The text of ``fingerprints.txt`` and the store files it was derived from."""

    fingerprint_text: str
    sources: tuple[tuple[str, str], ...]  # (capture id, file in capture), sorted


def _fingerprint(
    block: Sequence[bytes], probe: str, rec: int, excluded: tuple[str, ...], where: str
) -> tuple[int, int]:
    """The line count and FNV-1a 64 of one record, leaving out the ``excluded`` variables."""
    whole = record_fnv(block, probe, rec, where)  # every variable is checked, excluded or not
    if not excluded:
        return len(block), whole
    kept = [line for line in block if parse_line(line.decode("latin-1")).name not in excluded]
    return len(kept), record_fnv(kept, probe, rec, where)


def _record_lines(run: StoreRun, number: int, *, full: bool) -> list[str]:
    """The golden lines of one replayed run: its P1 records, then its P1b records."""
    lines: list[str] = []
    for probe in (P1_PROBE, P1B_PROBE):
        excluded = EXCLUDE_FULL if full and probe == P1_PROBE else ()
        dump = read_dump(run.run_dir / "work" / "probes" / f"{probe}.txt", run.where)
        for rec, (record, block) in enumerate(dump, start=1):
            if record.step is None:
                raise HarnessError(f"{run.where}: {probe} record {rec} has no step context")
            count, fnv = _fingerprint(block, probe, rec, excluded, run.where)
            lines.append(f"{number} {probe} {rec} {count} {fnv:016x}")
    return lines


def build_golden(captures_dir: Path, captures: Sequence[str]) -> Golden:
    """Derive the m6-setup golden for ``captures`` under ``captures_dir``; writes nothing."""
    lines: list[str] = []
    files: set[tuple[str, str]] = set()
    number = 0
    for capture in captures:
        found = capture_runs(captures_dir, capture)
        if found.has_corpus:
            files.add((capture, "corpus.json"))
        for run in found.runs:
            if not run.has_file_in():
                # A skipped run takes no number and no line; its run.json is still a source.
                files.add((capture, f"{run.rel}/run.json"))
                continue
            number += 1
            block = run_block(run)
            files.update((capture, path) for path in block.files)
            lines.extend(_record_lines(run, number, full=block.lines[0] == "mode full"))
    text_lines = (FINGERPRINTS_HEADER, EXCLUDE_LINE, *lines)
    return Golden(
        fingerprint_text="".join(f"{line}\n" for line in text_lines),
        sources=tuple(sorted(files)),
    )


def write_golden(out: Path, golden: Golden, *, replace: bool) -> None:
    """Write ``fingerprints.txt`` into ``out``, then its ``derived.json``."""
    if out.exists():
        if not replace:
            raise HarnessError(f"golden {out} exists; pass --replace to produce it again")
        shutil.rmtree(out)
    out.mkdir(parents=True)
    (out / "fingerprints.txt").write_text(golden.fingerprint_text, encoding="utf-8", newline="\n")
    write_derived(out, TOOL, list(golden.sources))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Derive the m6-setup golden from the store.")
    parser.add_argument("--out", type=Path, default=GOLDEN_OUT, help="golden directory to write")
    parser.add_argument("--replace", action="store_true", help="replace an existing golden")
    args = parser.parse_args(argv)
    out: Path = args.out
    replace: bool = args.replace
    try:
        golden = build_golden(STORE_CAPTURES, CAPTURES)
        write_golden(out, golden, replace=replace)
    except HarnessError as exc:
        print(f"setup_golden: {exc}", file=sys.stderr)
        return 2
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
