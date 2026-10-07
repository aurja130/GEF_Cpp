# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Run the original ``gef_reference`` under gdb and capture the seed it takes from the clock (M1.4).

Usage (from the repository root)::

    python3 -m harness.capture_seed --input <sequence file> --out <dir>
                                    [--binary validation/test_run/gef_reference]

The binary's SHA-256 is first verified against ``manifests/validation_test_run.sha256`` (entry
``test_run/gef_reference``). The run directory layout is the one of ``harness.run`` (cwd =
``<out>/work``, program output in ``<out>/stdout.log`` / ``<out>/stderr.log``), plus two files
that ``compare_runs`` ignores: ``<out>/gdb.log`` (gdb's own output) and
``<out>/capture.json`` (the structured capture result written by the gdb script).

gdb (``-batch -nx``) runs a generated Python script that

* stops once at the entry of ``fb_Randomize`` and checks the arguments: ``xmm0`` (seed) is
  ``-1.0`` and ``edi`` (algorithm) is ``3``; then deletes that breakpoint and continues;
* keeps a non-stopping counting breakpoint on the entry of ``hRndCtxInitMTWIST32`` and reads its
  argument (``edi``, the ``uint32_t`` seed). A second hit stops the program, which is killed and
  reported as a failure, as is any wrong ``fb_Randomize`` argument;
* starts the program with ``run < /dev/null > ../stdout.log 2> ../stderr.log`` and
  ``disable-randomization off`` (as without gdb); gdb's ``LINES`` and ``COLUMNS`` are removed from
  the program's environment.

``run.json`` records ``mode: "capture"`` and ``captured_seed``. Exit status: 0 success, 1 failure
(binary mismatch, wrong breakpoint evidence, gdb failure, non-zero program exit).
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from harness.common import GEF_REFERENCE, REPO_ROOT, HarnessError, sha256_file, write_json
from harness.run import RUN_SCHEMA, prepare_run_dir, utc_now

__all__ = [
    "CaptureResult",
    "capture_seed",
    "expected_sha256",
    "parse_capture_result",
    "render_gdb_script",
]

VALIDATION_MANIFEST = REPO_ROOT / "manifests" / "validation_test_run.sha256"
MANIFEST_ENTRY = "test_run/gef_reference"
RESULT_FILE = "capture.json"
GDB_LOG = "gdb.log"


@dataclass(frozen=True)
class CaptureResult:
    """The structured result written by the gdb script."""

    seed: int | None
    randomize_args: list[tuple[float, int]]
    mt_init_hits: int
    exit_code: int | None
    error: str | None


def expected_sha256(manifest: Path = VALIDATION_MANIFEST, entry: str = MANIFEST_ENTRY) -> str:
    """The digest of ``entry`` in a ``sha256sum``-style manifest (``#`` lines are comments)."""
    try:
        text = manifest.read_text(encoding="utf-8")
    except OSError as exc:
        raise HarnessError(f"cannot read {manifest}: {exc}") from exc
    for raw in text.splitlines():
        if not raw or raw.startswith("#"):
            continue
        digest, _, name = raw.partition("  ")
        if name == entry:
            return digest
    raise HarnessError(f"{manifest} has no entry {entry!r}")


def verify_binary(binary: Path, manifest: Path = VALIDATION_MANIFEST) -> str:
    """Return the binary's SHA-256 after checking it against the manifest."""
    actual = sha256_file(binary)
    expected = expected_sha256(manifest)
    if actual != expected:
        raise HarnessError(
            f"{binary} has SHA-256 {actual}, but {manifest.name} lists {expected} for "
            f"{MANIFEST_ENTRY}; refusing to capture a seed from an unverified binary"
        )
    return actual


# The gdb script. Placeholders are filled with json.dumps so every value is a valid Python literal.
_GDB_SCRIPT = """\
import gdb
import json

BINARY = {binary}
RESULT_FILE = {result_file}
RUN_COMMAND = {run_command}

state = {{"seed": None, "randomize_args": [], "mt_init_hits": 0, "exit_code": None, "error": None}}


def save():
    with open(RESULT_FILE, "w", encoding="utf-8") as handle:
        json.dump(state, handle, indent=2, sort_keys=True)
        handle.write("\\n")


class RandomizeBreakpoint(gdb.Breakpoint):
    def stop(self):
        seed = float(gdb.parse_and_eval("$xmm0.v2_double[0]"))
        algorithm = int(gdb.parse_and_eval("$edi")) & 0xFFFFFFFF
        state["randomize_args"].append([seed, algorithm])
        if seed != -1.0 or algorithm != 3:
            state["error"] = "fb_Randomize called with (%r, %d), expected (-1.0, 3)" % (
                seed, algorithm)
        return True


class MtInitBreakpoint(gdb.Breakpoint):
    def stop(self):
        state["mt_init_hits"] += 1
        if state["mt_init_hits"] == 1:
            state["seed"] = int(gdb.parse_and_eval("$rdi")) & 0xFFFFFFFF
            return False
        state["error"] = "hRndCtxInitMTWIST32 was hit %d times, expected once" % (
            state["mt_init_hits"])
        return True


def alive():
    return gdb.selected_inferior().pid != 0


def exit_code():
    value = gdb.parse_and_eval("$_exitcode")
    return int(value) if value.type.code != gdb.TYPE_CODE_VOID else None


try:
    gdb.execute("set pagination off")
    gdb.execute("set confirm off")
    gdb.execute("set disable-randomization off")
    gdb.execute("unset environment LINES")
    gdb.execute("unset environment COLUMNS")
    gdb.execute("file " + BINARY)
    randomize = RandomizeBreakpoint("*fb_Randomize")
    MtInitBreakpoint("*hRndCtxInitMTWIST32")
    gdb.execute(RUN_COMMAND)
    if alive() and state["error"] is None:
        # Stopped at fb_Randomize with the right arguments: drop that breakpoint and run on.
        randomize.delete()
        gdb.execute("continue")
    if alive():
        if state["error"] is None:
            state["error"] = "program stopped unexpectedly"
        gdb.execute("kill")
    else:
        state["exit_code"] = exit_code()
        if state["error"] is None and state["seed"] is None:
            state["error"] = "program ended without initialising the generator"
except gdb.error as exc:
    state["error"] = "gdb error: %s" % (exc,)
finally:
    save()
"""


def render_gdb_script(binary: Path, result_file: Path) -> str:
    """The gdb Python script that performs the capture (see the module docstring)."""
    return _GDB_SCRIPT.format(
        binary=json.dumps(str(binary)),
        result_file=json.dumps(str(result_file)),
        run_command=json.dumps("run < /dev/null > ../stdout.log 2> ../stderr.log"),
    )


def parse_capture_result(text: str) -> CaptureResult:
    """Parse and validate the JSON the gdb script wrote."""
    try:
        raw: Any = json.loads(text)
    except ValueError as exc:
        raise HarnessError(f"capture result is not valid JSON: {exc}") from exc
    if not isinstance(raw, dict):
        raise HarnessError("capture result is not a JSON object")
    data: dict[str, Any] = {str(k): v for k, v in raw.items()}  # pyright: ignore[reportUnknownVariableType, reportUnknownArgumentType]
    try:
        seed = data["seed"]
        hits = data["mt_init_hits"]
        code = data["exit_code"]
        error = data["error"]
        args_raw: Any = data["randomize_args"]
        args = [(float(a[0]), int(a[1])) for a in args_raw]  # pyright: ignore[reportUnknownVariableType, reportUnknownArgumentType]
    except (KeyError, TypeError, ValueError, IndexError) as exc:
        raise HarnessError(f"capture result has missing or malformed fields: {exc!r}") from exc
    if seed is not None and not (isinstance(seed, int) and 0 <= seed <= 2**32 - 1):
        raise HarnessError(f"captured seed {seed!r} is not a uint32")
    if not isinstance(hits, int) or not (code is None or isinstance(code, int)):
        raise HarnessError("capture result has malformed counters")
    if error is not None and not isinstance(error, str):
        raise HarnessError("capture result has a malformed error field")
    return CaptureResult(seed, args, hits, code, error)


def capture_seed(
    binary: Path,
    input_file: Path,
    out_dir: Path,
    manifest: Path = VALIDATION_MANIFEST,
    gdb: str = "gdb",
) -> tuple[CaptureResult, dict[str, Any]]:
    """Run ``binary`` under gdb in a fresh run directory; return the capture and ``run.json``."""
    binary = binary.resolve()
    binary_sha = verify_binary(binary, manifest)
    work = prepare_run_dir(out_dir, input_file)
    out = work.parent
    script = out / "capture_seed.gdb.py"
    result_file = out / RESULT_FILE
    script.write_text(render_gdb_script(binary, result_file), encoding="utf-8")
    command = [gdb, "-batch", "-nx", "-x", str(script)]
    start_utc = utc_now()
    start = time.perf_counter()
    try:
        with (out / GDB_LOG).open("wb") as log:
            proc = subprocess.run(
                command,
                cwd=work,
                stdin=subprocess.DEVNULL,
                stdout=log,
                stderr=subprocess.STDOUT,
                check=False,
            )
    except OSError as exc:
        raise HarnessError(f"cannot run gdb: {exc}") from exc
    wall = time.perf_counter() - start
    try:
        result = parse_capture_result(result_file.read_text(encoding="utf-8"))
    except OSError as exc:
        raise HarnessError(
            f"gdb (exit {proc.returncode}) left no {RESULT_FILE}; see {out / GDB_LOG}"
        ) from exc
    record: dict[str, Any] = {
        "schema": RUN_SCHEMA,
        "mode": "capture",
        "binary": {"path": str(binary), "sha256": binary_sha},
        "input": {"name": input_file.name, "sha256": sha256_file(input_file)},
        "seed": None,
        "captured_seed": result.seed,
        "reseed": False,
        "env_set": {},
        "command": command,
        "cwd": str(work),
        "start_utc": start_utc,
        "end_utc": utc_now(),
        "wall_time_s": round(wall, 3),
        "exit_code": result.exit_code,
        "gdb_exit_code": proc.returncode,
        "randomize_args": [list(a) for a in result.randomize_args],
        "mt_init_hits": result.mt_init_hits,
    }
    write_json(out / "run.json", record)
    if result.error is not None:
        raise HarnessError(f"seed capture failed: {result.error}; see {out / GDB_LOG}")
    if proc.returncode != 0 or result.exit_code != 0 or result.seed is None:
        raise HarnessError(
            f"capture run did not finish cleanly (gdb exit {proc.returncode}, program exit "
            f"{result.exit_code}, seed {result.seed}); see {out / GDB_LOG}, {out / 'stdout.log'}"
        )
    return result, record


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m harness.capture_seed",
        description="Run gef_reference under gdb and capture its clock-derived seed.",
    )
    parser.add_argument("--input", required=True, type=Path, help="GEF sequence file")
    parser.add_argument("--out", required=True, type=Path, help="new run directory")
    parser.add_argument("--binary", type=Path, default=GEF_REFERENCE)
    args = parser.parse_args(argv)
    try:
        result, record = capture_seed(args.binary, args.input, args.out)
    except HarnessError as exc:
        print(f"harness.capture_seed: {exc}", file=sys.stderr)
        return 1
    print(f"captured seed {result.seed} (run took {record['wall_time_s']:.1f} s): {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
