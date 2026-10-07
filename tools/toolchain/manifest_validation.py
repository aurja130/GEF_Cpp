# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Write and verify the SHA-256 manifests of the gitignored validation data (M0.8).

Usage (from the repository root)::

    python3 -m tools.toolchain.manifest_validation write  [--validation-dir validation]
    python3 -m tools.toolchain.manifest_validation verify [--validation-dir validation]

Two manifests are kept under ``manifests/``:

``validation_reference.sha256``
    The 382 reference ENDF tapes in ``reference/gefy_nfy_ENDF/`` and
    ``reference/gefy_sfy_ENDF/`` plus the two sequence files ``reference/gefy_nfy``
    and ``reference/gefy_sfy``.
``validation_test_run.sha256``
    The recorded evidence of ``test_run/``: the binary ``gef_reference``, ``run.log``,
    the ENDF tape in ``ENDF/`` and every file under ``out/``, ``dmp/`` and ``tmp/``.

The format is the one ``sha256sum`` writes (``<hex>  <path>``), with paths relative to the
validation directory, sorted, preceded by ``#`` header lines. GNU ``sha256sum -c`` skips the
header lines, so the manifests can also be checked with it (it does not detect extra files).

Exit codes: 0 success; 1 verification found missing/changed/extra files, or an error;
2 command-line usage error (argparse); 77 skipped because the validation directory is absent.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
import time
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

from tools.toolchain.fbc import REPO_ROOT

DEFAULT_VALIDATION_DIR = REPO_ROOT / "validation"
DEFAULT_MANIFEST_DIR = REPO_ROOT / "manifests"

EXIT_OK = 0
EXIT_FAILED = 1
EXIT_SKIPPED = 77
"""The validation directory is absent; callers such as CI treat this as 'skipped'."""

_LINE_RE = re.compile(r"^([0-9a-f]{64}) [ *](.+)$")


class ManifestError(RuntimeError):
    """A manifest cannot be written or read."""


@dataclass(frozen=True)
class ManifestSpec:
    """One manifest: which paths (relative to the validation directory) it covers."""

    filename: str
    title: str
    directories: tuple[str, ...]
    """Covered recursively: every regular file below them."""
    files: tuple[str, ...]
    notes: tuple[str, ...]


REFERENCE_SPEC = ManifestSpec(
    filename="validation_reference.sha256",
    title="the GEF reference data in validation/reference/",
    directories=("reference/gefy_nfy_ENDF", "reference/gefy_sfy_ENDF"),
    files=("reference/gefy_nfy", "reference/gefy_sfy"),
    notes=(
        "reference/gefy_nfy and reference/gefy_sfy are the GEF sequence input files (options,",
        "Z/A ranges, energies) that produced the tapes in the *_ENDF/ directories.",
    ),
)

TEST_RUN_SPEC = ManifestSpec(
    filename="validation_test_run.sha256",
    title="the recorded evidence in validation/test_run/",
    directories=("test_run/ENDF", "test_run/out", "test_run/dmp", "test_run/tmp"),
    files=("test_run/gef_reference", "test_run/run.log"),
    notes=(
        "WARNING: validation/test_run/ is NOT a clean run. It is recorded evidence only and",
        "must never be used as a working directory (never run GEF in it, never write into it).",
        "  - ctl/ holds stale control files (thread.ctl, done.ctl, sync.ctl) left over from an",
        "    earlier run. They are not covered by this manifest.",
        "  - ENDF/GEFY_86_214_n.dat contains two tapes: lines 1-857 are an earlier thermal-only",
        "    run, lines 858 onward are the real 59-energy tape.",
        "Also not covered: the inputs in/ and file.in, and the empty BestFit/, External/, GRAF/.",
    ),
)

SPECS: tuple[ManifestSpec, ...] = (REFERENCE_SPEC, TEST_RUN_SPEC)


@dataclass(frozen=True)
class HashedFiles:
    digests: dict[str, str]
    total_bytes: int
    seconds: float


@dataclass(frozen=True)
class VerifyResult:
    missing: tuple[str, ...]
    changed: tuple[str, ...]
    extra: tuple[str, ...]
    checked: int
    total_bytes: int
    seconds: float

    @property
    def ok(self) -> bool:
        return not (self.missing or self.changed or self.extra)


def sha256_file(path: Path) -> str:
    """Streamed SHA-256 of a file, as lowercase hex."""
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def _check_path_name(rel: str) -> None:
    # sha256sum escapes names containing these characters; keep the format plain.
    if "\\" in rel or "\n" in rel or "\r" in rel:
        raise ManifestError(f"unsupported character in file name: {rel!r}")


def covered_files(spec: ManifestSpec, validation_dir: Path) -> dict[str, list[str]]:
    """The files currently on disk in each covered entry (paths relative to validation_dir).

    Absent entries map to an empty list.
    """
    found: dict[str, list[str]] = {}
    for rel_dir in spec.directories:
        root = validation_dir / rel_dir
        names: list[str] = []
        if root.is_dir():
            for dirpath, dirnames, filenames in os.walk(root):
                dirnames.sort()
                for name in filenames:
                    full = Path(dirpath) / name
                    if full.is_file():
                        rel = full.relative_to(validation_dir).as_posix()
                        _check_path_name(rel)
                        names.append(rel)
        found[rel_dir] = sorted(names)
    for rel_file in spec.files:
        found[rel_file] = [rel_file] if (validation_dir / rel_file).is_file() else []
    return found


def hash_files(validation_dir: Path, rel_paths: Sequence[str], jobs: int) -> HashedFiles:
    """Hash files in parallel (hashlib releases the GIL while digesting large buffers)."""
    start = time.perf_counter()
    paths = [validation_dir / rel for rel in rel_paths]
    with ThreadPoolExecutor(max_workers=max(1, jobs)) as pool:
        digests = list(pool.map(sha256_file, paths))
    total = sum(p.stat().st_size for p in paths)
    return HashedFiles(
        dict(zip(rel_paths, digests, strict=True)), total, time.perf_counter() - start
    )


def render_manifest(spec: ManifestSpec, counts: dict[str, int], digests: dict[str, str]) -> str:
    covered = [f"{d}/ (files: {counts[d]})" for d in spec.directories]
    covered += spec.files
    header = [
        f"# SHA-256 manifest of {spec.title} (M0.8). {len(digests)} files.",
        "# Paths are relative to validation/ (gitignored). Covered, recursively for directories:",
        *(f"#   {entry}" for entry in covered),
        *(f"# {note}" for note in spec.notes),
        "#",
        "# Generated by `python3 -m tools.toolchain.manifest_validation write`;",
        "# do not edit by hand.",
        "# Verify (reports missing, changed and extra files):",
        "#   python3 -m tools.toolchain.manifest_validation verify",
        "# or with GNU coreutils, which skips these '#' lines but cannot detect extra files:",
        f"#   (cd validation && sha256sum -c --strict --quiet ../manifests/{spec.filename})",
    ]
    body = [f"{digests[rel]}  {rel}" for rel in sorted(digests)]
    return "\n".join([*header, *body]) + "\n"


def parse_manifest(text: str, source: Path) -> dict[str, str]:
    """Parse ``<hex>  <path>`` lines; ``#`` lines and blank lines are ignored."""
    entries: dict[str, str] = {}
    for number, line in enumerate(text.splitlines(), start=1):
        if not line.strip() or line.startswith("#"):
            continue
        match = _LINE_RE.match(line)
        if match is None:
            raise ManifestError(f"{source}:{number}: malformed line: {line!r}")
        digest, rel = match.group(1), match.group(2)
        if rel in entries:
            raise ManifestError(f"{source}:{number}: duplicate entry for {rel}")
        entries[rel] = digest
    return entries


def write_manifest(
    spec: ManifestSpec, validation_dir: Path, manifest_dir: Path, jobs: int
) -> tuple[HashedFiles, dict[str, int]]:
    """Hash the covered files and write the manifest; returns the hashes and per-entry counts."""
    found = covered_files(spec, validation_dir)
    absent = [d for d in spec.directories if not (validation_dir / d).is_dir()]
    absent += [f for f in spec.files if not found[f]]
    if absent:
        raise ManifestError(
            f"cannot write {spec.filename}: missing in {validation_dir}: {', '.join(absent)}"
        )
    rel_paths = sorted(rel for names in found.values() for rel in names)
    hashed = hash_files(validation_dir, rel_paths, jobs)
    counts = {entry: len(names) for entry, names in found.items()}
    manifest_dir.mkdir(parents=True, exist_ok=True)
    (manifest_dir / spec.filename).write_text(
        render_manifest(spec, counts, hashed.digests), encoding="utf-8"
    )
    return hashed, counts


def verify_manifest(
    spec: ManifestSpec, validation_dir: Path, manifest_dir: Path, jobs: int
) -> VerifyResult:
    manifest_path = manifest_dir / spec.filename
    if not manifest_path.is_file():
        raise ManifestError(
            f"{manifest_path} not found; create it with "
            "`python3 -m tools.toolchain.manifest_validation write`"
        )
    expected = parse_manifest(manifest_path.read_text(encoding="utf-8"), manifest_path)
    on_disk = {rel for names in covered_files(spec, validation_dir).values() for rel in names}
    present = sorted(rel for rel in expected if rel in on_disk)
    hashed = hash_files(validation_dir, present, jobs)
    return VerifyResult(
        missing=tuple(sorted(rel for rel in expected if rel not in on_disk)),
        changed=tuple(rel for rel in present if hashed.digests[rel] != expected[rel]),
        extra=tuple(sorted(on_disk - expected.keys())),
        checked=len(present),
        total_bytes=hashed.total_bytes,
        seconds=hashed.seconds,
    )


def _size(total_bytes: int) -> str:
    return f"{total_bytes / 1e6:.1f} MB"


def _cmd_write(validation_dir: Path, manifest_dir: Path, jobs: int) -> int:
    start = time.perf_counter()
    for spec in SPECS:
        hashed, counts = write_manifest(spec, validation_dir, manifest_dir, jobs)
        print(
            f"wrote {manifest_dir / spec.filename}: {len(hashed.digests)} files, "
            f"{_size(hashed.total_bytes)} hashed in {hashed.seconds:.2f} s"
        )
        for entry in (*spec.directories, *spec.files):
            print(f"  {counts[entry]:5d}  {entry}")
    print(f"total time {time.perf_counter() - start:.2f} s")
    return EXIT_OK


def _cmd_verify(validation_dir: Path, manifest_dir: Path, jobs: int) -> int:
    start = time.perf_counter()
    failed = False
    for spec in SPECS:
        result = verify_manifest(spec, validation_dir, manifest_dir, jobs)
        timing = f"{_size(result.total_bytes)} hashed in {result.seconds:.2f} s"
        if result.ok:
            print(f"OK    {spec.filename}: {result.checked} files match ({timing})")
            continue
        failed = True
        print(
            f"FAIL  {spec.filename}: {len(result.missing)} missing, {len(result.changed)} "
            f"changed, {len(result.extra)} extra ({result.checked} present files, {timing})"
        )
        for label, items in (
            ("missing", result.missing),
            ("changed", result.changed),
            ("extra  ", result.extra),
        ):
            for rel in items:
                print(f"  {label} {rel}")
    print(f"total time {time.perf_counter() - start:.2f} s")
    if failed:
        print(
            "validation data does not match the manifests; if the change is intended, "
            "rewrite them with `python3 -m tools.toolchain.manifest_validation write`"
        )
        return EXIT_FAILED
    return EXIT_OK


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.toolchain.manifest_validation",
        description="Write or verify the SHA-256 manifests of the validation data.",
        epilog=(
            f"exit codes: {EXIT_OK} ok; {EXIT_FAILED} mismatch or error; 2 usage error; "
            f"{EXIT_SKIPPED} skipped (validation directory absent)"
        ),
    )
    parser.add_argument("command", choices=("write", "verify"))
    parser.add_argument(
        "--validation-dir",
        type=Path,
        default=DEFAULT_VALIDATION_DIR,
        help="validation data directory (default: <repo>/validation)",
    )
    parser.add_argument(
        "--manifest-dir",
        type=Path,
        default=DEFAULT_MANIFEST_DIR,
        help="directory holding the .sha256 manifests (default: <repo>/manifests)",
    )
    parser.add_argument(
        "--jobs",
        type=int,
        default=min(16, os.cpu_count() or 1),
        help="parallel hashing threads (default: min(16, CPU count))",
    )
    args = parser.parse_args(argv)
    validation_dir: Path = args.validation_dir
    manifest_dir: Path = args.manifest_dir
    jobs: int = args.jobs
    command: str = args.command

    if not validation_dir.is_dir():
        print(
            f"skipped: validation directory {validation_dir} is absent; "
            f"nothing to {command} (exit {EXIT_SKIPPED})"
        )
        return EXIT_SKIPPED
    try:
        if command == "write":
            return _cmd_write(validation_dir, manifest_dir, jobs)
        return _cmd_verify(validation_dir, manifest_dir, jobs)
    except (ManifestError, OSError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return EXIT_FAILED


if __name__ == "__main__":
    sys.exit(main())
