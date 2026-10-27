# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Derive the m6-plan golden from the store: how BASIC ran each M6 capture run.

For each run with ``work/file.in`` the golden lists, in BASIC's order, the set-up stages it
called (``system`` and ``step`` events), its pass headers (``pass``), a digest of the P1
records the run driver must reproduce (``p1``) and how the run ended (``exit``). Runs are
numbered as in ``m6-p0``; a run without ``work/file.in`` keeps a comment in its place.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Final

from harness.common import STORE_CAPTURES, HarnessError
from harness.golden import GOLDEN_DIR, write_derived
from harness.golden_store import (
    StoreRun,
    capture_runs,
    load_json,
    read_dump,
    run_exit_code,
    skip_comment,
)
from harness.p0_golden import CAPTURES
from harness.probe_fingerprints import fnv1a64
from harness.probes import ProbeLine, ProbeRecord, parse_line

GOLDEN_OUT: Final[Path] = GOLDEN_DIR / "m6-plan"
TOOL: Final[str] = "python3 -m harness.plan_golden"
PLAN_HEADER: Final[str] = "# m6-plan 1"
P1_PROBE: Final[str] = "P1"
P1B_PROBE: Final[str] = "P1b"
FENHANCE: Final[str] = "Fenhance"

# The P1 variables the run driver dumps; the digest covers them in this order.
NAMES: Final[tuple[str, ...]] = (
    "Iline",
    "Ifilein",
    "I_Double_Covar",
    "N_Double_Covar",
    "I_E_step",
    "N_E_steps",
    "N_E_values",
    "I_E_iso",
    "Bfilein",
    "B_ENDF",
    "B_Random_on",
    "B_Error_On",
    "I_Error",
    "En_min",
    "En_max",
    "P_Z_CN",
    "P_A_CN",
    "P_I_rms_CN",
    "P_Z_CN_Double",
    "P_A_CN_Double",
    "P_E_exc_Double",
    "E_EXC_TRUE",
    "Emode",
)

# BASIC's stdout markers, compared with the spaces at both ends stripped.
WAIT_LINE: Final[str] = "Please wait ... code is running."
RESTART_LINE: Final[str] = "Please stop GEF, complete table and restart GEF."
UNBOUND_LINE: Final[str] = "<W> Fissioning nucleus is not bound."
ALPHA_LINE: Final[str] = "<S> Alpha energy is too low. (E* of compound nucleus would be negativ.)"
BELOW_GROUND_LINE: Final[str] = (
    "<E> Input energy of the fissioning nucleus is below the ground state."
)
NOMINAL_LINE: Final[str] = "Calculation with nominal model parameters."
GRAVE_TAIL_LINE: Final[str] = "to grave statistical fluctuations!"
TERMINATED_LINES: Final[tuple[str, str]] = (
    "GEF is terminated.",
    "Press ENTER to close this window!",
)

BARRIER_RE: Final[re.Pattern[str]] = re.compile(r"Fission barrier of CN \(Z = (\d+), A = (\d+)\):")
# The CN header's variants differ only after ", E", so the prefix is what matches.
CN_RE: Final[re.Pattern[str]] = re.compile(r"CN: Z = (\d+), A = (\d+), E")
PERTURBED_RE: Final[re.Pattern[str]] = re.compile(
    r"Calculation \( *\d+ of *\d+\) with perturbed model parameters\."
)
EVENTS_RE: Final[re.Pattern[str]] = re.compile(r"\d+ events will be calculated\.")
GRAVE_HEAD_RE: Final[re.Pattern[str]] = re.compile(
    r"<W> The calculation with .* events will be subject"
)
HEX16_RE: Final[re.Pattern[str]] = re.compile(r"[0-9a-f]{16}")


@dataclass(frozen=True)
class Golden:
    """The text of the m6-plan golden and the store files it was derived from."""

    plan_text: str
    sources: tuple[tuple[str, str], ...]  # (capture, path within the capture), sorted


@dataclass(frozen=True)
class RunBlock:
    """One run with ``work/file.in``: its golden lines and the store files they came from."""

    capture: str
    rel: str
    lines: tuple[str, ...]  # the mode, event, p1 and exit lines between run and endrun
    files: tuple[str, ...]  # paths within the capture


class _Trace:
    """The events of one run, replayed from the markers in its stdout in BASIC's order."""

    def __init__(self, fenhances: Sequence[str], where: str) -> None:
        self.events: list[str] = []
        self.steps = 0  # calculations run so far; each one is a `step ok` event
        self._fenhances: Sequence[str] = fenhances
        self._where = where
        self._line = 0
        self._pending: tuple[int, int] | None = None  # a barrier no verdict has settled yet
        self._system: tuple[int, int] | None = None  # the system the steps run on
        self._cn: tuple[int, int] | None = None  # a CN header awaiting its verdict
        self._ended = False  # an alpha or below-ground stop ended the run

    def at(self, line: int) -> None:
        """Name the 1-based stdout line of the marker that comes next, for error messages."""
        self._line = line

    def fail(self, message: str) -> HarnessError:
        return HarnessError(f"{self._where}: stdout line {self._line}: {message}")

    def barrier(self, z: int, a: int) -> None:
        self._check_open()
        if self._cn is not None:
            raise self.fail("a fission barrier while a CN header awaits its verdict")
        self._settle()
        self._pending = (z, a)
        self._system = (z, a)

    def cn(self, z: int, a: int) -> None:
        self._check_open()
        if self._cn is not None:
            raise self.fail("a CN header while the previous CN header awaits its verdict")
        if self._pending is not None:
            if self._pending != (z, a):
                raise self.fail(f"CN {z} {a} does not match the fission barrier before it")
            self._settle()
        elif self._system != (z, a):
            raise self.fail(f"CN {z} {a} has no fission barrier of its system")
        self._cn = (z, a)

    def unbound(self) -> None:
        self._check_open()
        if self._pending is None:
            raise self.fail("an unbound verdict with no fission barrier awaiting one")
        z, a = self._pending
        self.events.append(f"system {z} {a} unbound")
        self._pending = None
        self._system = None

    def wait(self) -> None:
        self._check_open()
        if self._cn is None:
            raise self.fail("a Please wait line with no CN header before it")
        if self.steps >= len(self._fenhances):
            raise self.fail(f"calculation {self.steps + 1} has no P1b record")
        z, a = self._cn
        self.events.append(f"step ok {z} {a} {self._fenhances[self.steps]}")
        self.steps += 1
        self._cn = None

    def restart(self) -> None:
        self._check_open()
        if self._cn is not None:
            raise self.fail("a restart while a CN header awaits its verdict")
        self._settle()
        self._system = None
        self.events.append("step restart")

    def step_end(self) -> None:
        self._check_open()
        if self._cn is None:
            raise self.fail("an alpha or below-ground stop with no CN header before it")
        z, a = self._cn
        self.events.append(f"step end {z} {a}")
        self._cn = None
        self._ended = True

    def pass_line(self, raw: bytes) -> None:
        self._check_open()
        if self._cn is not None:
            raise self.fail("a pass header while a CN header awaits its verdict")
        self._settle()
        self.events.append(f"pass {raw.hex()}")

    def finish(self) -> None:
        if self._cn is not None:
            raise HarnessError(f"{self._where}: stdout ends with a CN header and no verdict")
        self._settle()

    def _check_open(self) -> None:
        if self._ended:
            raise self.fail("a marker follows the end of the run")

    def _settle(self) -> None:
        """Record the pending fission barrier as set up: no verdict contradicted it."""
        if self._pending is not None:
            z, a = self._pending
            self.events.append(f"system {z} {a} ok")
            self._pending = None


def _scan(lines: Sequence[bytes], trace: _Trace) -> None:
    """Replay the stdout lines into ``trace``; a grave-statistics head takes its tail line too."""
    index = 0
    while index < len(lines):
        raw = lines[index]
        trace.at(index + 1)
        text = raw.decode("latin-1").strip(" ")
        index += 1
        if GRAVE_HEAD_RE.match(text) is not None:
            tail = lines[index] if index < len(lines) else b""
            if tail.decode("latin-1").strip(" ") != GRAVE_TAIL_LINE:
                raise trace.fail("a grave-statistics line without its tail line")
            trace.pass_line(raw)
            trace.at(index + 1)
            trace.pass_line(tail)
            index += 1
        else:
            _classify(text, raw, trace)


def _classify(text: str, raw: bytes, trace: _Trace) -> None:
    """Route one stdout line to ``trace``; lines that are not markers are ignored."""
    barrier = BARRIER_RE.fullmatch(text)
    if barrier is not None:
        trace.barrier(int(barrier.group(1)), int(barrier.group(2)))
        return
    cn = CN_RE.match(text)
    if cn is not None:
        trace.cn(int(cn.group(1)), int(cn.group(2)))
    elif text == UNBOUND_LINE:
        trace.unbound()
    elif text == WAIT_LINE:
        trace.wait()
    elif text == RESTART_LINE:
        trace.restart()
    elif text in (ALPHA_LINE, BELOW_GROUND_LINE):
        trace.step_end()
    elif (
        text == NOMINAL_LINE
        or PERTURBED_RE.fullmatch(text) is not None
        or EVENTS_RE.fullmatch(text) is not None
    ):
        trace.pass_line(raw)


def _check_dump(
    dump: Sequence[tuple[ProbeRecord, list[bytes]]], file_name: str, probe: str, where: str
) -> list[list[bytes]]:
    """The raw lines of each record of a probe dump, which must hold ``probe`` records 1..n."""
    blocks: list[list[bytes]] = []
    for number, (record, lines) in enumerate(dump, start=1):
        if record.probe != probe:
            raise HarnessError(f"{where}: {file_name} holds {record.probe} records")
        if record.rec != number:
            raise HarnessError(
                f"{where}: {probe} record {number} has rec={record.rec}, not {number}"
            )
        blocks.append(lines)
    return blocks


def _scalars(
    lines: Sequence[bytes], wanted: Sequence[str], probe: str, number: int, where: str
) -> dict[str, tuple[ProbeLine, bytes]]:
    """The scalar line of each wanted variable of one record; other variables are skipped."""
    found: dict[str, tuple[ProbeLine, bytes]] = {}
    for raw in lines:
        parsed = parse_line(raw.decode("latin-1"))
        if parsed.name not in wanted:
            continue
        if parsed.index != ():
            raise HarnessError(
                f"{where}: {probe} record {number} has {parsed.name} as an array element"
            )
        found[parsed.name] = (parsed, raw)
    for name in wanted:
        if name not in found:
            raise HarnessError(f"{where}: {probe} record {number} has no {name}")
    return found


def _fenhances(blocks: Sequence[Sequence[bytes]], where: str) -> list[str]:
    """The Fenhance of each P1b record, as the 16 lower-case hex digits of its double."""
    values: list[str] = []
    for number, lines in enumerate(blocks, start=1):
        line, _ = _scalars(lines, (FENHANCE,), P1B_PROBE, number, where)[FENHANCE]
        value = line.value.lower()
        if line.type != "D" or HEX16_RE.fullmatch(value) is None:
            raise HarnessError(f"{where}: P1b record {number} has no Fenhance as 16 hex digits")
        values.append(value)
    return values


def _p1_digest(blocks: Sequence[Sequence[bytes]], where: str) -> str:
    """FNV-1a 64 of the P1 lines of NAMES, record by record and name by name, as hex."""
    lines: list[bytes] = []
    for number, block in enumerate(blocks, start=1):
        found = _scalars(block, NAMES, P1_PROBE, number, where)
        lines.extend(found[name][1] for name in NAMES)
    return f"{fnv1a64(lines):016x}"


def _check_step_passes(events: Sequence[str], where: str) -> None:
    """In a full run each calculation's step is followed at once by its pass header."""
    for index, event in enumerate(events):
        if not event.startswith("step ok "):
            continue
        following = events[index + 1] if index + 1 < len(events) else ""
        if not following.startswith("pass "):
            raise HarnessError(f"{where}: a calculation has no pass header after its step")


def _exit_state(lines: Sequence[bytes], exit_code: int) -> str:
    """How a run ended: terminated, hang (nonzero exit without the closing lines) or end."""
    texts = [raw.decode("latin-1").strip(" ") for raw in lines]
    last = [text for text in texts if text][-2:]
    if tuple(last) == TERMINATED_LINES:
        return "terminated"
    return "hang" if exit_code != 0 else "end"


def _render(items: Sequence[RunBlock | str]) -> str:
    """The plan text: the header and names line, then each run block or skip comment in order."""
    lines = [PLAN_HEADER, "names " + " ".join(NAMES)]
    runs = 0
    for item in items:
        if isinstance(item, str):
            lines.append(item)
            continue
        runs += 1
        lines.append(f"run {runs} {item.capture} {item.rel}")
        lines.extend(item.lines)
        lines.append("endrun")
    return "\n".join(lines) + "\n"


def run_block(run: StoreRun) -> RunBlock:
    """The golden block of a run with work/file.in, replayed from its store files."""
    where = run.where
    if " " in run.rel:
        raise HarnessError(
            f"{where}: the run directory has a space in its name; the run line cannot hold it"
        )
    run_json = load_json(run.run_dir / "run.json", where)
    exit_code = run_exit_code(run, run_json)
    stdout = (run.run_dir / "stdout.log").read_bytes().split(b"\n")
    probes = run.run_dir / "work" / "probes"
    p1 = _check_dump(read_dump(probes / "P1.txt", where), "P1.txt", P1_PROBE, where)
    p1b = _check_dump(read_dump(probes / "P1b.txt", where), "P1b.txt", P1B_PROBE, where)
    if len(p1) != len(p1b):
        raise HarnessError(f"{where}: P1 has {len(p1)} records but P1b has {len(p1b)}")
    trace = _Trace(_fenhances(p1b, where), where)
    _scan(stdout, trace)
    trace.finish()
    if trace.steps != len(p1):
        raise HarnessError(
            f"{where}: BASIC made {trace.steps} calculations but P1 holds {len(p1)} records"
        )
    mode = "full" if any(event.startswith("pass ") for event in trace.events) else "setup"
    if mode == "full":
        _check_step_passes(trace.events, where)
    lines = (
        f"mode {mode}",
        *trace.events,
        f"p1 {len(p1)} {_p1_digest(p1, where)}",
        f"exit {_exit_state(stdout, exit_code)}",
    )
    files = [f"{run.rel}/run.json", f"{run.rel}/stdout.log", f"{run.rel}/work/file.in"]
    for name in ("P1.txt", "P1b.txt"):
        if (probes / name).is_file():
            files.append(f"{run.rel}/work/probes/{name}")
    return RunBlock(capture=run.capture, rel=run.rel, lines=lines, files=tuple(files))


def build_golden(captures_dir: Path, captures: Sequence[str]) -> Golden:
    """Derive the m6-plan golden for ``captures`` under ``captures_dir``; writes nothing."""
    items: list[RunBlock | str] = []
    files: set[tuple[str, str]] = set()
    for capture in captures:
        found = capture_runs(captures_dir, capture)
        if found.has_corpus:
            files.add((capture, "corpus.json"))
        for run in found.runs:
            if not run.has_file_in():
                items.append(skip_comment(run))
                files.add((capture, f"{run.rel}/run.json"))
                continue
            block = run_block(run)
            items.append(block)
            files.update((capture, path) for path in block.files)
    return Golden(plan_text=_render(items), sources=tuple(sorted(files)))


def write_golden(out: Path, golden: Golden, *, replace: bool) -> None:
    """Write ``plan.txt`` into ``out``, then its ``derived.json``."""
    if out.exists():
        if not replace:
            raise HarnessError(f"golden {out} exists; pass --replace to produce it again")
        shutil.rmtree(out)
    out.mkdir(parents=True)
    (out / "plan.txt").write_text(golden.plan_text, encoding="utf-8", newline="\n")
    write_derived(out, TOOL, list(golden.sources))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Derive the m6-plan golden from the store.")
    parser.add_argument("--out", type=Path, default=GOLDEN_OUT, help="golden directory to write")
    parser.add_argument("--replace", action="store_true", help="replace an existing golden")
    args = parser.parse_args(argv)
    out: Path = args.out
    replace: bool = args.replace
    try:
        golden = build_golden(STORE_CAPTURES, CAPTURES)
        write_golden(out, golden, replace=replace)
    except HarnessError as exc:
        print(f"plan_golden: {exc}", file=sys.stderr)
        return 2
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
