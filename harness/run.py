# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Clean-run runner for harness binaries (M1.3).

Usage (from the repository root)::

    python3 -m harness.run --binary <path|build-id> --input <sequence file> [--input ...] --seed N
                           --out <dir> [--reseed] [--scope steps=1,3-5] [--scope passes=1]
                           [--scope events=1-100] [--env NAME=VALUE ...]
                           [--work-file PATH[=REL] ...] [--file-in PATH]

``--binary`` is a file path or a build id under ``build/harness/`` (see ``harness.build``).
``--out`` must not exist. The run directory layout is::

    <out>/run.json     manifest (binary and input SHA-256, seed, mode, env set, timings, exit code)
    <out>/stdout.log   the program's standard output
    <out>/stderr.log   the program's standard error
    <out>/work/        GEF's working directory (cwd): file.in, in/<input>..., the --work-file
                       copies (e.g. Fitpar.dat), and everything GEF and the harness patches create
                       (ctl/ out/ dmp/ tmp/ ENDF/ probes/ rnd.log)

Every ``--input`` is copied to ``work/in/<name>``. ``work/file.in`` lists them as quoted relative
paths ``"in/<name>"``, one per line, followed by ``END``, like a batch-mode ``file.in``;
``--file-in PATH`` uses the bytes of PATH instead (e.g. to add ``NITER(1)`` or list a file
twice). ``--work-file PATH`` copies PATH to ``work/<its name>``; ``--work-file PATH=REL`` copies it
to ``work/REL`` (a relative path inside ``work/``, e.g. ``in/Espectrum.in``). The program runs
with ``stdin`` from ``/dev/null`` and the current environment plus the harness variables
``GEF_SEED``, ``GEF_RESEED`` (``--reseed``) and the scope selectors ``GEF_TRACE_STEPS`` /
``GEF_TRACE_PASSES`` / ``GEF_TRACE_EVENTS`` (``--scope``).

Exit status: 0 when the program exits with 0; 1 otherwise (``run.json`` is written first, so a
failed run still leaves its evidence). Usage errors exit 2.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import time
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path, PurePosixPath
from typing import Any

from harness.build import BINARY_NAME, BUILD_JSON, resolve_binary
from harness.common import HarnessError, sha256_file, write_json

__all__ = [
    "RunResult",
    "build_environment",
    "prepare_run_dir",
    "run",
    "scope_environment",
    "utc_now",
]

RUN_SCHEMA = 1
SCOPE_VARIABLES = {
    "steps": "GEF_TRACE_STEPS",
    "passes": "GEF_TRACE_PASSES",
    "events": "GEF_TRACE_EVENTS",
}
MAX_SEED = 2**32 - 1


@dataclass(frozen=True)
class RunResult:
    """Outcome of one run; ``record`` is the content of ``run.json``."""

    out_dir: Path
    work_dir: Path
    exit_code: int
    wall_time_s: float
    record: dict[str, Any]


def utc_now() -> str:
    return datetime.now(UTC).isoformat(timespec="seconds")


def _relative_destination(rel: str) -> PurePosixPath:
    dest = PurePosixPath(rel)
    if dest.is_absolute() or not dest.parts or ".." in dest.parts:
        raise HarnessError(f"work file destination {rel!r} must be a relative path inside work/")
    if dest.parts[0] == "file.in" or dest == PurePosixPath("in"):
        raise HarnessError(f"work file destination {rel!r} is reserved")
    return dest


def prepare_run_dir(
    out_dir: Path,
    input_file: Path,
    work_files: Sequence[Path | tuple[Path, str]] = (),
    *,
    extra_inputs: Sequence[Path] = (),
    file_in: bytes | None = None,
    input_dest: str | None = None,
) -> Path:
    """Create ``out_dir`` with ``work/``, ``work/in/<input>`` for ``input_file`` (or
    ``work/<input_dest>``) and each of ``extra_inputs``, ``work/file.in`` (``file_in``, or the
    generated list of the inputs) and a copy of each of ``work_files`` in ``work/``: a path goes
    under its own name (e.g. ``Fitpar.dat``), a ``(path, rel)`` pair to ``work/rel``.

    Refuses an existing ``out_dir``. Returns the (absolute) work directory.
    """
    out = out_dir.resolve()
    if out.exists():
        raise HarnessError(f"output directory {out} already exists; runs never overwrite")
    inputs = [input_file, *extra_inputs]
    for f in inputs:
        if not f.is_file():
            raise HarnessError(f"input file {f} does not exist")
    input_names = [f.name for f in inputs]
    if len(set(input_names)) != len(input_names):
        raise HarnessError(f"input file names repeat: {input_names}")
    input_dests = [
        _relative_destination(input_dest if input_dest is not None else f"in/{input_file.name}")
    ] + [PurePosixPath("in", f.name) for f in extra_inputs]
    placed: list[tuple[Path, PurePosixPath]] = []
    for item in work_files:
        source, dest = (item, PurePosixPath(item.name)) if isinstance(item, Path) else item
        dest = _relative_destination(str(dest))
        if not source.is_file():
            raise HarnessError(f"work file {source} does not exist")
        placed.append((source, dest))
    destinations = [str(d) for _, d in placed] + [str(d) for d in input_dests]
    if len(set(destinations)) != len(destinations):
        raise HarnessError(f"work file destinations repeat: {destinations}")
    work = out / "work"
    (work / "in").mkdir(parents=True)
    for f, dest in zip(inputs, input_dests, strict=True):
        target = work.joinpath(*dest.parts)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(f.read_bytes())
    if file_in is None:
        file_in = "".join(f'"{d}"\n' for d in input_dests).encode() + b"END\n"
    (work / "file.in").write_bytes(file_in)
    for source, dest in placed:
        target = work.joinpath(*dest.parts)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(source.read_bytes())
    return work


def scope_environment(scope: Mapping[str, str] | None) -> dict[str, str]:
    """Map ``{"steps": "1,3-5", ...}`` to the ``GEF_TRACE_*`` variables."""
    env: dict[str, str] = {}
    for key, value in (scope or {}).items():
        if key not in SCOPE_VARIABLES:
            raise HarnessError(f"unknown scope key {key!r}; use {sorted(SCOPE_VARIABLES)}")
        env[SCOPE_VARIABLES[key]] = value
    return env


def build_environment(
    seed: int | None,
    reseed: bool = False,
    extra_env: Mapping[str, str] | None = None,
    scope: Mapping[str, str] | None = None,
) -> dict[str, str]:
    """The variables the harness sets (never the inherited environment)."""
    if seed is not None and not 0 <= seed <= MAX_SEED:
        raise HarnessError(f"seed {seed} is outside 0..{MAX_SEED}")
    env: dict[str, str] = {}
    if seed is not None:
        env["GEF_SEED"] = str(seed)
    if reseed:
        env["GEF_RESEED"] = "1"
    env.update(scope_environment(scope))
    env.update(extra_env or {})
    return env


def _binary_record(binary: Path) -> dict[str, Any]:
    record: dict[str, Any] = {"path": str(binary), "sha256": sha256_file(binary)}
    if binary.name == BINARY_NAME and (binary.parent / BUILD_JSON).is_file():
        record["build_id"] = binary.parent.name
    return record


def run(
    binary: Path,
    input_file: Path,
    out_dir: Path,
    seed: int,
    reseed: bool = False,
    extra_env: Mapping[str, str] | None = None,
    scope: Mapping[str, str] | None = None,
    timeout_s: float | None = None,
    work_files: Sequence[Path | tuple[Path, str]] = (),
    *,
    extra_inputs: Sequence[Path] = (),
    file_in: Path | None = None,
    input_dest: str | None = None,
) -> RunResult:
    """Run ``binary`` on ``input_file`` (and ``extra_inputs``) in a fresh run directory (see the
    module docstring). ``file_in`` replaces the generated ``work/file.in``; ``input_dest`` puts
    ``input_file`` at ``work/<input_dest>`` instead of ``work/in/<name>``.

    Raises ``HarnessError`` for a non-zero exit status, after writing ``run.json``.
    """
    binary = binary.resolve()
    if not binary.is_file() or not os.access(binary, os.X_OK):
        raise HarnessError(f"binary {binary} is not an executable file")
    harness_env = build_environment(seed, reseed, extra_env, scope)
    if file_in is not None and not file_in.is_file():
        raise HarnessError(f"file.in source {file_in} does not exist")
    work = prepare_run_dir(
        out_dir,
        input_file,
        work_files,
        extra_inputs=extra_inputs,
        file_in=None if file_in is None else file_in.read_bytes(),
        input_dest=input_dest,
    )
    out = work.parent
    command = [str(binary)]
    start_utc = utc_now()
    start = time.perf_counter()
    with (
        Path("/dev/null").open("rb") as stdin,
        (out / "stdout.log").open("wb") as stdout,
        (out / "stderr.log").open("wb") as stderr,
    ):
        try:
            proc = subprocess.run(
                command,
                cwd=work,
                stdin=stdin,
                stdout=stdout,
                stderr=stderr,
                env={**os.environ, **harness_env},
                check=False,
                timeout=timeout_s,
            )
            exit_code = proc.returncode
        except subprocess.TimeoutExpired:
            exit_code = -1
    wall = time.perf_counter() - start
    record: dict[str, Any] = {
        "schema": RUN_SCHEMA,
        "mode": "reseed" if reseed else "normal",
        "binary": _binary_record(binary),
        "input": {"name": input_file.name, "sha256": sha256_file(input_file)}
        | ({} if input_dest is None else {"dest": input_dest}),
        "seed": seed,
        "reseed": reseed,
        "env_set": harness_env,
        "command": command,
        "cwd": str(work),
        "start_utc": start_utc,
        "end_utc": utc_now(),
        "wall_time_s": round(wall, 3),
        "exit_code": exit_code,
    }
    if extra_inputs:
        record["inputs"] = [
            {"name": f.name, "sha256": sha256_file(f)} for f in (input_file, *extra_inputs)
        ]
    if file_in is not None:
        record["file_in"] = {"sha256": sha256_file(file_in)}
    if work_files:
        entries: list[dict[str, str]] = []
        for item in work_files:
            source, dest = (item, item.name) if isinstance(item, Path) else item
            entry = {"name": source.name, "sha256": sha256_file(source)}
            if dest != source.name:
                entry["dest"] = dest
            entries.append(entry)
        record["work_files"] = entries
    write_json(out / "run.json", record)
    if exit_code != 0:
        raise HarnessError(
            f"{binary.name} exited with status {exit_code}; see {out / 'stdout.log'} and "
            f"{out / 'stderr.log'}"
        )
    return RunResult(out, work, exit_code, wall, record)


def _parse_pairs(items: Sequence[str], what: str) -> dict[str, str]:
    pairs: dict[str, str] = {}
    for item in items:
        key, sep, value = item.partition("=")
        if not sep or not key:
            raise HarnessError(f"--{what} expects KEY=VALUE, got {item!r}")
        pairs[key] = value
    return pairs


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m harness.run",
        description="Run a harness GEF binary in a fresh run directory.",
    )
    parser.add_argument("--binary", required=True, help="binary path or build id")
    parser.add_argument(
        "--input",
        required=True,
        action="append",
        type=Path,
        help="GEF sequence file (repeatable; copied to work/in/)",
    )
    parser.add_argument("--seed", required=True, type=int, help="GEF_SEED, 0..4294967295")
    parser.add_argument("--out", required=True, type=Path, help="new run directory")
    parser.add_argument("--reseed", action="store_true", help="set GEF_RESEED=1")
    parser.add_argument(
        "--scope", action="append", default=[], metavar="KEY=VALUE", help="steps|passes|events=..."
    )
    parser.add_argument(
        "--env", action="append", default=[], metavar="NAME=VALUE", help="extra environment"
    )
    parser.add_argument(
        "--work-file",
        action="append",
        default=[],
        metavar="PATH[=REL]",
        help="copy into work/ (under its name, or to work/REL) before the run (in run.json)",
    )
    parser.add_argument("--file-in", type=Path, default=None, help="use this file as work/file.in")
    args = parser.parse_args(argv)
    work_files: list[Path | tuple[Path, str]] = []
    for item in args.work_file:
        source, sep, dest = str(item).partition("=")
        work_files.append((Path(source), dest) if sep else Path(source))
    try:
        binary = resolve_binary(args.binary)
        result = run(
            binary,
            args.input[0],
            args.out,
            args.seed,
            reseed=args.reseed,
            extra_env=_parse_pairs(args.env, "env"),
            scope=_parse_pairs(args.scope, "scope"),
            work_files=work_files,
            extra_inputs=args.input[1:],
            file_in=args.file_in,
        )
    except HarnessError as exc:
        print(f"harness.run: {exc}", file=sys.stderr)
        return 1
    print(f"run complete in {result.wall_time_s:.1f} s: {result.out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
