# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Store-derived golden ``m7-p3``: the P3in and P3 fingerprints of the M7 captures, format 1.

The M7 table-builder tests read this golden when the store is absent (``MILESTONE_7_PLAN.md``
D13). Format (``fingerprints.txt``)::

    # m7-p3 fingerprints 1
    <entry> P3in <rec> <step> <pass> <bin> <lines> <fnv>
    <entry> P3 <rec> <step> <pass> <bin> <lines> <fnv>

Derivation rules:

- ``<entry>`` is an id of ``harness/inputs/m7/corpus.toml``, in manifest order; its capture is
  ``m7-p3-<entry>``, which holds exactly one run (``run.json`` at the top of the capture).
- For each entry: its P3in records in ascending ``rec``, then its P3 records in ascending ``rec``.
  The two probes must have the same number of records with the same ``(step, pass, bin)``
  sequence (P3in and P3 are written for the same bins), and at least one each.
- ``<bin>`` is the context's ``I_E_Distr:I_N_Multi:I_Z_Multi:I_E_Multi``.
- ``<lines>`` and ``<fnv>``: the record's dump lines grouped by NAME in ascending byte order of
  NAME, kept in dump order within a NAME, each line followed by a newline, hashed with FNV-1a 64
  (16 lower-case hex digits), as ``m6-p0`` hashes them.

Usage from the repository root: ``python3 -m harness.p3_golden [--out DIR] [--replace]``
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
from harness.corpus import M7_MANIFEST, load_entries
from harness.golden import GOLDEN_DIR, write_derived
from harness.golden_store import StoreRun, capture_runs, read_dump
from harness.p0_golden import record_fnv
from harness.probes import ProbeRecord

GOLDEN_OUT: Final[Path] = GOLDEN_DIR / "m7-p3"
TOOL: Final[str] = "python3 -m harness.p3_golden"
FINGERPRINTS_HEADER: Final[str] = "# m7-p3 fingerprints 1"
CAPTURE_PREFIX: Final[str] = "m7-p3-"
PROBES: Final[tuple[str, str]] = ("P3in", "P3")


@dataclass(frozen=True)
class Golden:
    """The text of ``fingerprints.txt`` and the store files it was derived from."""

    fingerprint_text: str
    sources: tuple[tuple[str, str], ...]  # (capture id, file in capture), sorted


def _context(record: ProbeRecord, where: str) -> tuple[int, int, tuple[int, int, int, int]]:
    if record.step is None or record.pass_ is None or record.bin is None:
        raise HarnessError(f"{where}: {record.probe} rec={record.rec} has no bin context")
    return record.step, record.pass_, record.bin


def _single_run(captures_dir: Path, capture: str) -> StoreRun:
    runs = capture_runs(captures_dir, capture).runs
    if len(runs) != 1 or runs[0].rel != ".":
        raise HarnessError(f"{capture}: expected one run at the top of the capture")
    return runs[0]


def entry_lines(entry: str, run: StoreRun) -> tuple[list[str], list[str]]:
    """The golden lines of one entry and the capture files they come from."""
    lines: list[str] = []
    contexts: dict[str, list[tuple[int, int, tuple[int, int, int, int]]]] = {}
    files = ["run.json"]
    for probe in PROBES:
        path = run.run_dir / "work" / "probes" / f"{probe}.txt"
        dump = read_dump(path, run.where)
        if not dump:
            raise HarnessError(f"{run.where}: no {probe} record")
        files.append(f"work/probes/{probe}.txt")
        contexts[probe] = []
        for rec, (record, block) in enumerate(dump, start=1):
            if record.rec != rec:
                raise HarnessError(f"{run.where}: {probe} record {rec} has rec={record.rec}")
            step, pass_, bin_ = _context(record, run.where)
            contexts[probe].append((step, pass_, bin_))
            fnv = record_fnv(block, probe, rec, run.where)
            where = ":".join(str(i) for i in bin_)
            lines.append(f"{entry} {probe} {rec} {step} {pass_} {where} {len(block)} {fnv:016x}")
    if contexts["P3in"] != contexts["P3"]:
        raise HarnessError(f"{run.where}: P3in and P3 are not written for the same bins")
    return lines, files


def build_golden(captures_dir: Path, entries: Sequence[str]) -> Golden:
    """Derive the m7-p3 golden for the capture of each entry; writes nothing."""
    lines: list[str] = []
    sources: set[tuple[str, str]] = set()
    for entry in entries:
        capture = CAPTURE_PREFIX + entry
        found, files = entry_lines(entry, _single_run(captures_dir, capture))
        lines.extend(found)
        sources.update((capture, f) for f in files)
    return Golden(
        fingerprint_text="".join(f"{line}\n" for line in (FINGERPRINTS_HEADER, *lines)),
        sources=tuple(sorted(sources)),
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
    parser = argparse.ArgumentParser(description="Derive the m7-p3 golden from the store.")
    parser.add_argument("--out", type=Path, default=GOLDEN_OUT, help="golden directory to write")
    parser.add_argument("--replace", action="store_true", help="replace an existing golden")
    args = parser.parse_args(argv)
    out: Path = args.out
    replace: bool = args.replace
    try:
        golden = build_golden(STORE_CAPTURES, [e.id for e in load_entries((M7_MANIFEST,))])
        write_golden(out, golden, replace=replace)
    except HarnessError as exc:
        print(f"p3_golden: {exc}", file=sys.stderr)
        return 2
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
