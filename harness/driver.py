# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Function-driver framework: compile and run small FreeBASIC programs against GEF code.

A driver is ``harness/drivers/<name>.bas``. Two directives (own line, ``'`` comment) pull
GEF source into the build directory so the driver can ``#include`` it:

* ``'@include-source <file>``: copy ``<file>`` from the GEF source directory next to the
  driver (e.g. ``'@include-source utilities.bi`` then ``#include "utilities.bi"``).
* ``'@cut <file>:<first>-<last> as <name>.bi``: write the 1-based inclusive line range of
  ``<file>`` to ``<name>.bi`` (to paste a function body without its surroundings).

Usage::

    python3 -m harness.driver build <name> [--rebuild]
    python3 -m harness.driver run <name> [--out DIR] [--rebuild] [-- ARGS...]

Layout under ``build/harness/drivers/<name>/``: ``src/`` (driver copy, copied/cut GEF
files, binary, ``build.json``) and ``run-<n>/`` (a fresh working directory per run, or
``--out DIR``; it must be absent or empty). A run writes ``stdout.txt`` and
``driver.json`` there: driver, binary and output-file SHA-256s, fbc version, command,
include and cut records (cuts with line range, source SHA-256 and extracted SHA-256),
exit code and wall time. Builds use default fbc options with ``SOURCE_DATE_EPOCH`` set
to the GEF submodule commit time. ``run`` exits with the driver's exit code; build and
usage errors exit 2.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from harness.common import BUILD_ROOT, DRIVERS_DIR, GEF_SOURCE_DIR, HarnessError, write_json
from tools.fbsrc.common import sha256_file
from tools.toolchain.fbc import FbcError, fbc_version, filter_fbc_stderr, resolve_fbc

DRIVER_BUILD_ROOT = BUILD_ROOT / "drivers"
STDOUT_NAME = "stdout.txt"
DRIVER_JSON = "driver.json"
BUILD_JSON = "build.json"

_INCLUDE_RE = re.compile(r"^\s*'@include-source\s+(\S+)\s*$")
_CUT_RE = re.compile(r"^\s*'@cut\s+(\S+):(\d+)-(\d+)\s+as\s+(\S+)\s*$")
_DIRECTIVE_PREFIX = re.compile(r"^\s*'@")
_NAME_RE = re.compile(r"^[A-Za-z0-9_][A-Za-z0-9_.-]*$")


@dataclass(frozen=True)
class IncludeSource:
    """``'@include-source <file>``."""

    file: str


@dataclass(frozen=True)
class Cut:
    """``'@cut <file>:<first>-<last> as <name>``; lines are 1-based and inclusive."""

    file: str
    first: int
    last: int
    name: str


Directive = IncludeSource | Cut


def _check_relative_name(value: str, what: str, lineno: int) -> None:
    parts = value.split("/")
    if value.startswith("/") or ".." in parts or "" in parts:
        raise HarnessError(f"line {lineno}: {what} {value!r} must be a relative path inside it")


def parse_directives(text: str) -> list[Directive]:
    """Parse the ``'@include-source`` / ``'@cut`` directives of a driver source."""
    found: list[Directive] = []
    for lineno, line in enumerate(text.splitlines(), start=1):
        if _DIRECTIVE_PREFIX.match(line) is None:
            continue
        if (m := _INCLUDE_RE.match(line)) is not None:
            _check_relative_name(m[1], "source file", lineno)
            found.append(IncludeSource(m[1]))
        elif (m := _CUT_RE.match(line)) is not None:
            _check_relative_name(m[1], "source file", lineno)
            first, last = int(m[2]), int(m[3])
            if first < 1 or last < first:
                raise HarnessError(f"line {lineno}: bad line range {first}-{last} (1-based)")
            if _NAME_RE.fullmatch(m[4]) is None:
                raise HarnessError(f"line {lineno}: bad cut output name {m[4]!r}")
            found.append(Cut(m[1], first, last, m[4]))
        else:
            raise HarnessError(f"line {lineno}: unrecognised directive: {line.strip()!r}")
    return found


def cut_lines(source: Path, first: int, last: int) -> bytes:
    """The bytes of lines ``first..last`` (1-based, inclusive) of ``source``, verbatim."""
    lines = source.read_bytes().splitlines(keepends=True)
    if last > len(lines):
        raise HarnessError(f"{source.name} has {len(lines)} lines; cannot cut {first}-{last}")
    return b"".join(lines[first - 1 : last])


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _materialise(
    directives: list[Directive], source_dir: Path, dest: Path
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Copy/cut the requested GEF files into ``dest``; returns (includes, cuts) records."""
    includes: list[dict[str, Any]] = []
    cuts: list[dict[str, Any]] = []
    for d in directives:
        src = source_dir / d.file
        if not src.is_file():
            raise HarnessError(f"GEF source file {d.file} not found in {source_dir}")
        if isinstance(d, IncludeSource):
            target = dest / d.file
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, target)
            includes.append({"file": d.file, "sha256": sha256_file(src)})
        else:
            data = cut_lines(src, d.first, d.last)
            (dest / d.name).write_bytes(data)
            cuts.append(
                {
                    "file": d.file,
                    "first": d.first,
                    "last": d.last,
                    "as": d.name,
                    "source_sha256": sha256_file(src),
                    "cut_sha256": _sha256_bytes(data),
                }
            )
    return includes, cuts


def _commit_epoch() -> int:
    from tools.fbsrc.emit_c import submodule_revision

    return submodule_revision().commit_epoch


@dataclass(frozen=True)
class DriverBuild:
    """A compiled driver: where it is and the record written to ``build.json``."""

    name: str
    binary: Path
    record: dict[str, Any]


def build(
    name: str,
    *,
    drivers_dir: Path = DRIVERS_DIR,
    build_root: Path = DRIVER_BUILD_ROOT,
    source_dir: Path = GEF_SOURCE_DIR,
    fbc: Path | None = None,
    source_date_epoch: int | None = None,
    rebuild: bool = False,
) -> DriverBuild:
    """Compile driver ``name``; reuse the existing binary if its inputs are unchanged."""
    if _NAME_RE.fullmatch(name) is None or "/" in name:
        raise HarnessError(f"bad driver name {name!r}")
    driver_src = drivers_dir / f"{name}.bas"
    if not driver_src.is_file():
        raise HarnessError(f"driver source {driver_src} not found")
    text = driver_src.read_bytes().decode("latin-1")
    directives = parse_directives(text)

    fbc = fbc if fbc is not None else _resolve_fbc()
    version = fbc_version(fbc)
    epoch = source_date_epoch if source_date_epoch is not None else _commit_epoch()

    src_dir = build_root / name / "src"
    binary = src_dir / name
    # Inputs that determine the binary; a matching build.json means nothing to do.
    key = {
        "driver_sha256": sha256_file(driver_src),
        "fbc_version": version,
        "source_date_epoch": epoch,
        "directives": [
            {"file": d.file, **({"first": d.first, "last": d.last} if isinstance(d, Cut) else {})}
            for d in directives
        ],
        "source_files": {
            d.file: sha256_file(source_dir / d.file)
            for d in directives
            if (source_dir / d.file).is_file()
        },
    }
    build_json = src_dir / BUILD_JSON
    if not rebuild and binary.is_file() and build_json.is_file():
        old = json.loads(build_json.read_text(encoding="utf-8"))
        if old.get("key") == key and old.get("binary_sha256") == sha256_file(binary):
            return DriverBuild(name, binary, old)

    if src_dir.exists():
        shutil.rmtree(src_dir)
    src_dir.mkdir(parents=True)
    shutil.copyfile(driver_src, src_dir / driver_src.name)
    includes, cuts = _materialise(directives, source_dir, src_dir)

    command = [str(fbc), driver_src.name]
    env = dict(os.environ, SOURCE_DATE_EPOCH=str(epoch))
    start = time.monotonic()
    try:
        proc = subprocess.run(
            command, cwd=src_dir, env=env, capture_output=True, text=True, check=False
        )
    except OSError as exc:
        raise HarnessError(f"cannot run fbc: {exc}") from exc
    wall = time.monotonic() - start
    diagnostics = "\n".join(
        p for p in (proc.stdout.strip(), filter_fbc_stderr(proc.stderr).strip()) if p
    )
    if proc.returncode != 0 or not binary.is_file():
        raise HarnessError(f"fbc failed for driver {name} (exit {proc.returncode}):\n{diagnostics}")
    record: dict[str, Any] = {
        "key": key,
        "driver": name,
        "driver_sha256": key["driver_sha256"],
        "fbc": str(fbc),
        "fbc_version": version,
        "source_date_epoch": epoch,
        "command": command,
        "includes": includes,
        "cuts": cuts,
        "binary_sha256": sha256_file(binary),
        "fbc_diagnostics": diagnostics,
        "build_wall_time_s": round(wall, 3),
    }
    write_json(build_json, record)
    return DriverBuild(name, binary, record)


def _resolve_fbc() -> Path:
    try:
        return resolve_fbc()
    except FbcError as exc:
        raise HarnessError(str(exc)) from exc


def _next_run_dir(driver_root: Path) -> Path:
    numbers = [
        int(p.name[4:]) for p in driver_root.glob("run-*") if p.name[4:].isdigit() and p.is_dir()
    ]
    return driver_root / f"run-{max(numbers, default=0) + 1}"


@dataclass(frozen=True)
class DriverRun:
    """Result of ``run``: the output directory, its ``driver.json`` record and the exit code."""

    out_dir: Path
    record: dict[str, Any]
    returncode: int


def run(
    name: str,
    args: list[str] | None = None,
    *,
    out_dir: Path | None = None,
    build_root: Path = DRIVER_BUILD_ROOT,
    **build_kwargs: Any,
) -> DriverRun:
    """Build (if needed) and run driver ``name`` with cwd = a fresh output directory."""
    args = args or []
    built = build(name, build_root=build_root, **build_kwargs)
    if out_dir is None:
        out_dir = _next_run_dir(build_root / name)
    if out_dir.exists() and (not out_dir.is_dir() or any(out_dir.iterdir())):
        raise HarnessError(f"output directory {out_dir} exists and is not empty")
    out_dir.mkdir(parents=True, exist_ok=True)

    command = [str(built.binary.resolve()), *args]
    start = time.monotonic()
    with (out_dir / STDOUT_NAME).open("wb") as stdout:
        proc = subprocess.run(
            command,
            cwd=out_dir,
            stdin=subprocess.DEVNULL,
            stdout=stdout,
            stderr=subprocess.STDOUT,
            check=False,
        )
    wall = time.monotonic() - start
    outputs = {
        p.relative_to(out_dir).as_posix(): sha256_file(p)
        for p in sorted(out_dir.rglob("*"))
        if p.is_file() and p.name != DRIVER_JSON
    }
    record: dict[str, Any] = {
        "driver": name,
        "driver_sha256": built.record["driver_sha256"],
        "fbc_version": built.record["fbc_version"],
        "binary_sha256": built.record["binary_sha256"],
        "command": [name, *args],
        "returncode": proc.returncode,
        "includes": built.record["includes"],
        "cuts": built.record["cuts"],
        "outputs": outputs,
        "run_wall_time_s": round(wall, 3),
    }
    write_json(out_dir / DRIVER_JSON, record)
    return DriverRun(out_dir, record, proc.returncode)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m harness.driver", description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p_build = sub.add_parser("build", help="compile a driver")
    p_build.add_argument("name")
    p_build.add_argument("--rebuild", action="store_true", help="ignore an up-to-date build")
    p_run = sub.add_parser("run", help="build if needed and run a driver")
    p_run.add_argument("name")
    p_run.add_argument("--out", type=Path, help="output directory (absent or empty)")
    p_run.add_argument("--rebuild", action="store_true")
    p_run.add_argument("args", nargs="*", help="driver arguments, after --")
    ns = parser.parse_args(argv)
    try:
        if ns.cmd == "build":
            b = build(ns.name, rebuild=ns.rebuild)
            print(f"{b.binary} sha256={b.record['binary_sha256']}")
            return 0
        r = run(ns.name, ns.args, out_dir=ns.out, rebuild=ns.rebuild)
    except HarnessError as exc:
        print(f"harness.driver: {exc}", file=sys.stderr)
        return 2
    print(f"{r.out_dir} (exit {r.returncode}, {r.record['run_wall_time_s']} s)")
    return r.returncode


if __name__ == "__main__":
    sys.exit(main())
