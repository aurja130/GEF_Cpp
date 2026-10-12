# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Function-driver framework: compile and run small FreeBASIC programs against GEF code.

A driver is ``harness/drivers/<name>.bas``. Three directives (own line, ``'`` comment) pull
GEF source or shared driver files into the build directory so the driver can ``#include``
them:

* ``'@include-source <file>``: copy ``<file>`` from the GEF source directory next to the
  driver (e.g. ``'@include-source utilities.bi`` then ``#include "utilities.bi"``).
* ``'@include-driver <file>``: copy ``<file>`` from ``harness/drivers`` (a path relative to
  it) next to the driver, so several drivers can share a helper (e.g.
  ``'@include-driver m5_common.bi`` then ``#include "m5_common.bi"``).
* ``'@cut <file>:<first>-<last> as <name>.bi``: write the 1-based inclusive line range of
  ``<file>`` to ``<name>.bi`` (to paste a function body without its surroundings).

Usage::

    python3 -m harness.driver build <name> [--rebuild]
    python3 -m harness.driver run <name> [--out DIR] [--rebuild] [--work-file PATH]... [-- ARGS...]

Layout under ``build/harness/drivers/<name>/``: ``src/`` (driver copy, copied GEF and shared
driver files, cut files, binary, ``<name>.c`` as fbc kept it, ``build.json``) and
``run-<n>/`` (a fresh working directory per run, or ``--out DIR``; it must be absent or
empty). A run writes ``stdout.txt`` and ``driver.json`` there: driver, binary and output-file
SHA-256s, fbc version, command, include, driver-include, cut and work-file records (work file:
name, source path and SHA-256), exit code and wall time. ``--work-file PATH`` (repeatable)
copies ``PATH`` into the run directory under its own name before the run, so the driver can
open it by name; work files are not in ``outputs``. Builds run ``fbc -R``: ``build.json``
records ``c_file`` and ``c_sha256``, and ``DriverBuild.c_source`` is the C file. A shared
driver file is hashed into the build key and recorded as ``driver_includes`` (file, SHA-256)
in ``build.json`` and ``driver.json``; ``harness.golden check`` reports a golden stale when one
changes. ``SOURCE_DATE_EPOCH`` is set to the GEF submodule commit time. ``run`` exits with the
driver's exit code; build and usage errors exit 2.
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
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from harness.common import (
    BUILD_ROOT,
    DRIVERS_DIR,
    GEF_SOURCE_DIR,
    REPO_ROOT,
    HarnessError,
    write_json,
)
from tools.fbsrc.common import sha256_file
from tools.toolchain.fbc import FbcError, fbc_version, filter_fbc_stderr, resolve_fbc

DRIVER_BUILD_ROOT = BUILD_ROOT / "drivers"
STDOUT_NAME = "stdout.txt"
DRIVER_JSON = "driver.json"
BUILD_JSON = "build.json"
# ``-R`` keeps the C file fbc generates (``<name>.c``) next to the binary.
DRIVER_FBC_OPTIONS = ("-R",)
# Names the run writes into its own directory; a work file may not use them.
_RESERVED_WORK_NAMES = frozenset({STDOUT_NAME, DRIVER_JSON})

_INCLUDE_RE = re.compile(r"^\s*'@include-source\s+(\S+)\s*$")
_INCLUDE_DRIVER_RE = re.compile(r"^\s*'@include-driver\s+(\S+)\s*$")
_CUT_RE = re.compile(r"^\s*'@cut\s+(\S+):(\d+)-(\d+)\s+as\s+(\S+)\s*$")
_DIRECTIVE_PREFIX = re.compile(r"^\s*'@")
_NAME_RE = re.compile(r"^[A-Za-z0-9_][A-Za-z0-9_.-]*$")


@dataclass(frozen=True)
class IncludeSource:
    """``'@include-source <file>``."""

    file: str


@dataclass(frozen=True)
class IncludeDriver:
    """``'@include-driver <file>``: a file of the drivers directory, shared by drivers."""

    file: str


@dataclass(frozen=True)
class Cut:
    """``'@cut <file>:<first>-<last> as <name>``; lines are 1-based and inclusive."""

    file: str
    first: int
    last: int
    name: str


Directive = IncludeSource | IncludeDriver | Cut


def _check_relative_name(value: str, what: str, lineno: int) -> None:
    parts = value.split("/")
    if value.startswith("/") or ".." in parts or "" in parts:
        raise HarnessError(f"line {lineno}: {what} {value!r} must be a relative path inside it")


def parse_directives(text: str) -> list[Directive]:
    """Parse the ``'@include-source``, ``'@include-driver`` and ``'@cut`` directives."""
    found: list[Directive] = []
    for lineno, line in enumerate(text.splitlines(), start=1):
        if _DIRECTIVE_PREFIX.match(line) is None:
            continue
        if (m := _INCLUDE_RE.match(line)) is not None:
            _check_relative_name(m[1], "source file", lineno)
            found.append(IncludeSource(m[1]))
        elif (m := _INCLUDE_DRIVER_RE.match(line)) is not None:
            _check_relative_name(m[1], "driver file", lineno)
            found.append(IncludeDriver(m[1]))
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
        if isinstance(d, IncludeDriver):
            continue
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


def _driver_include_records(directives: list[Directive], drivers_dir: Path) -> list[dict[str, str]]:
    """``{file, sha256}`` of each ``'@include-driver``; each file must be in ``drivers_dir``."""
    records: list[dict[str, str]] = []
    for d in directives:
        if not isinstance(d, IncludeDriver):
            continue
        src = drivers_dir / d.file
        if not src.is_file():
            raise HarnessError(f"driver include {d.file} not found in {drivers_dir}")
        records.append({"file": d.file, "sha256": sha256_file(src)})
    return records


def _commit_epoch() -> int:
    from tools.fbsrc.emit_c import submodule_revision

    return submodule_revision().commit_epoch


@dataclass(frozen=True)
class DriverBuild:
    """A compiled driver: where it is and the record written to ``build.json``."""

    name: str
    binary: Path
    record: dict[str, Any]

    @property
    def c_source(self) -> Path:
        """The C file fbc kept for the driver; it sits next to the binary."""
        return self.binary.parent / str(self.record["c_file"])


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
    """Compile driver ``name`` with ``fbc -R``; reuse the build if its inputs are unchanged."""
    if _NAME_RE.fullmatch(name) is None or "/" in name:
        raise HarnessError(f"bad driver name {name!r}")
    driver_src = drivers_dir / f"{name}.bas"
    if not driver_src.is_file():
        raise HarnessError(f"driver source {driver_src} not found")
    text = driver_src.read_bytes().decode("latin-1")
    directives = parse_directives(text)
    driver_includes = _driver_include_records(directives, drivers_dir)

    fbc = fbc if fbc is not None else _resolve_fbc()
    version = fbc_version(fbc)
    epoch = source_date_epoch if source_date_epoch is not None else _commit_epoch()

    src_dir = build_root / name / "src"
    binary = src_dir / name
    c_file = f"{name}.c"
    c_path = src_dir / c_file
    # Inputs that determine the binary and its C file; a matching build.json means nothing to do.
    key = {
        "driver_sha256": sha256_file(driver_src),
        "fbc_version": version,
        "fbc_options": list(DRIVER_FBC_OPTIONS),
        "source_date_epoch": epoch,
        "directives": [
            {"file": d.file, **({"first": d.first, "last": d.last} if isinstance(d, Cut) else {})}
            for d in directives
            if not isinstance(d, IncludeDriver)
        ],
        "source_files": {
            d.file: sha256_file(source_dir / d.file)
            for d in directives
            if not isinstance(d, IncludeDriver) and (source_dir / d.file).is_file()
        },
        "driver_includes": driver_includes,
    }
    build_json = src_dir / BUILD_JSON
    if not rebuild and binary.is_file() and build_json.is_file():
        old = json.loads(build_json.read_text(encoding="utf-8"))
        if (
            old.get("key") == key
            and old.get("binary_sha256") == sha256_file(binary)
            and c_path.is_file()
            and old.get("c_sha256") == sha256_file(c_path)
        ):
            return DriverBuild(name, binary, old)

    if src_dir.exists():
        shutil.rmtree(src_dir)
    src_dir.mkdir(parents=True)
    shutil.copyfile(driver_src, src_dir / driver_src.name)
    includes, cuts = _materialise(directives, source_dir, src_dir)
    for inc in driver_includes:
        target = src_dir / inc["file"]
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(drivers_dir / inc["file"], target)

    command = [str(fbc), *DRIVER_FBC_OPTIONS, driver_src.name]
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
    if not c_path.is_file():
        raise HarnessError(f"fbc did not keep {c_file} for driver {name}")
    record: dict[str, Any] = {
        "key": key,
        "driver": name,
        "driver_sha256": key["driver_sha256"],
        "fbc": str(fbc),
        "fbc_version": version,
        "source_date_epoch": epoch,
        "command": command,
        "fbc_options": list(DRIVER_FBC_OPTIONS),
        "c_file": c_file,
        "c_sha256": sha256_file(c_path),
        "includes": includes,
        "cuts": cuts,
        "driver_includes": driver_includes,
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


def _check_work_files(work_files: Sequence[Path]) -> None:
    """Refuse a work file that does not exist, repeats a name or takes a name the run needs."""
    names: set[str] = set()
    for path in work_files:
        if not path.is_file():
            raise HarnessError(f"work file {path} does not exist")
        if path.name in _RESERVED_WORK_NAMES or path.name in names:
            raise HarnessError(f"work file name {path.name!r} is reserved or repeated")
        names.add(path.name)


def _record_path(path: Path) -> str:
    """``path`` as records show it: relative to the repository when inside it."""
    resolved = path.resolve()
    if resolved.is_relative_to(REPO_ROOT):
        return resolved.relative_to(REPO_ROOT).as_posix()
    return resolved.as_posix()


def run(
    name: str,
    args: list[str] | None = None,
    *,
    out_dir: Path | None = None,
    work_files: Sequence[Path] = (),
    build_root: Path = DRIVER_BUILD_ROOT,
    **build_kwargs: Any,
) -> DriverRun:
    """Build (if needed) and run driver ``name`` with cwd = a fresh output directory.

    Each of ``work_files`` is copied into that directory under its own name before the run,
    so the driver can open it by name. The copies are recorded in ``driver.json`` (name,
    source path, SHA-256) and are not outputs; a driver that changes or removes one fails.
    """
    args = args or []
    _check_work_files(work_files)
    built = build(name, build_root=build_root, **build_kwargs)
    if out_dir is None:
        out_dir = _next_run_dir(build_root / name)
    if out_dir.exists() and (not out_dir.is_dir() or any(out_dir.iterdir())):
        raise HarnessError(f"output directory {out_dir} exists and is not empty")
    out_dir.mkdir(parents=True, exist_ok=True)
    work_records: list[dict[str, Any]] = []
    for src in work_files:
        copy = out_dir / src.name
        shutil.copyfile(src, copy)
        work_records.append(
            {"name": src.name, "source": _record_path(src), "sha256": sha256_file(copy)}
        )

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
    for work in work_records:
        current = out_dir / str(work["name"])
        if not current.is_file() or sha256_file(current) != work["sha256"]:
            raise HarnessError(f"driver {name} changed or removed work file {work['name']}")
    work_names = {src.name for src in work_files}
    outputs: dict[str, str] = {}
    for p in sorted(out_dir.rglob("*")):
        rel = p.relative_to(out_dir).as_posix()
        if p.is_file() and p.name != DRIVER_JSON and rel not in work_names:
            outputs[rel] = sha256_file(p)
    record: dict[str, Any] = {
        "driver": name,
        "driver_sha256": built.record["driver_sha256"],
        "fbc_version": built.record["fbc_version"],
        "binary_sha256": built.record["binary_sha256"],
        "command": [name, *args],
        "returncode": proc.returncode,
        "includes": built.record["includes"],
        "cuts": built.record["cuts"],
        "driver_includes": built.record["driver_includes"],
        "work_files": work_records,
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
    p_run.add_argument(
        "--work-file",
        action="append",
        type=Path,
        metavar="PATH",
        help="copy this file into the run directory first (repeatable)",
    )
    p_run.add_argument("args", nargs="*", help="driver arguments, after --")
    ns = parser.parse_args(argv)
    try:
        if ns.cmd == "build":
            b = build(ns.name, rebuild=ns.rebuild)
            print(f"{b.binary} sha256={b.record['binary_sha256']}")
            return 0
        r = run(ns.name, ns.args, out_dir=ns.out, rebuild=ns.rebuild, work_files=ns.work_file or [])
    except HarnessError as exc:
        print(f"harness.driver: {exc}", file=sys.stderr)
        return 2
    print(f"{r.out_dir} (exit {r.returncode}, {r.record['run_wall_time_s']} s)")
    return r.returncode


if __name__ == "__main__":
    sys.exit(main())
