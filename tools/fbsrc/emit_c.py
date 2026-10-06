# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aurora Jahan
# See LICENSE.txt in the repository root for the full license text.
"""Translate the GEF BASIC source to C with the pinned fbc (M0.7).

Usage (from the repository root)::

    python3 -m tools.fbsrc.emit_c [--patch-dir DIR] [--force]

The submodule's ``source/`` directory is copied to ``build/fbsrc/<key>/src/``, the
optional patch directory is applied to the copy, and ``fbc -gen gcc -R -g -c GEF.bas``
runs there. fbc keeps the generated ``GEF.c`` next to ``GEF.bas`` (``-R``) and also
compiles it to ``GEF.o`` (``-c``). ``build/fbsrc/<key>/manifest.json`` records how the
C was produced; it is written last, so its presence marks a complete emission.

``<key>`` is the short submodule revision, plus ``-p<12 hex>`` (from the SHA-256 of the
patch directory) when a patch directory is given. An existing emission is reused when its
manifest and ``GEF.c`` are intact and match the request, unless ``--force`` is given.

GEF prints a compile time stamp (``__DATE_ISO__``/``__TIME__``), so fbc runs with
``SOURCE_DATE_EPOCH`` set to the submodule commit time; the emitted C is then
byte-identical for the same emission directory.

Patch directory format: unified diffs named ``*.patch`` or ``*.diff``, applied in
lexicographic file-name order with ``patch -p1`` inside the copied source directory
(paths look like ``a/GEF.bas`` / ``b/GEF.bas``). Any other entry is an error.
"""

from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
from collections.abc import Generator, Sequence
from contextlib import contextmanager
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from tools.fbsrc.common import FBSRC_BUILD_DIR, FbsrcError, display_path, sha256_file
from tools.toolchain.fbc import (
    GEF_SOURCE_DIR,
    REQUIRED_FBC_VERSION,
    FbcError,
    fbc_version,
    filter_fbc_stderr,
    resolve_fbc,
)

SUBMODULE_DIR = GEF_SOURCE_DIR.parent
MAIN_SOURCE = "GEF.bas"
GEF_C = "GEF.c"
FBC_ARGS = ("-gen", "gcc", "-R", "-g", "-c", MAIN_SOURCE)
PATCH_SUFFIXES = (".patch", ".diff")
MANIFEST_NAME = "manifest.json"
MANIFEST_SCHEMA = 1

_FBC_TIMEOUT_S = 900
_GIT_TIMEOUT_S = 60


@dataclass(frozen=True)
class Manifest:
    """Content of ``build/fbsrc/<key>/manifest.json``."""

    schema: int
    key: str
    submodule_revision: str
    submodule_commit: str
    patch_dir: str | None
    patch_dir_sha256: str | None
    patches: list[str]
    source_date_epoch: int
    fbc_path: str
    fbc_version: str
    command: list[str]
    cwd: str
    gef_c: str
    gef_c_sha256: str
    gef_c_sha256_normalised: str
    fbc_wall_time_s: float
    total_wall_time_s: float
    fbc_diagnostics: str
    created_utc: str

    def to_json(self) -> str:
        return json.dumps(asdict(self), indent=2) + "\n"

    @classmethod
    def from_json(cls, text: str) -> Manifest:
        raw: Any = json.loads(text)
        if not isinstance(raw, dict):
            raise ValueError("manifest is not a JSON object")
        data: dict[str, Any] = {str(k): v for k, v in raw.items()}  # pyright: ignore[reportUnknownVariableType, reportUnknownArgumentType]
        expected = {f for f in cls.__dataclass_fields__}
        if set(data) != expected:
            raise ValueError(f"manifest fields differ: {sorted(set(data) ^ expected)}")
        strings = ("key", "submodule_commit", "gef_c", "gef_c_sha256", "cwd", "fbc_version")
        if not isinstance(data["schema"], int) or not all(
            isinstance(data[f], str) for f in strings
        ):
            raise ValueError("manifest field types are wrong")
        return cls(**data)


@dataclass(frozen=True)
class Emission:
    """A complete emission on disk."""

    root: Path
    manifest: Manifest
    reused: bool

    @property
    def key(self) -> str:
        return self.manifest.key

    @property
    def src_dir(self) -> Path:
        return self.root / "src"

    @property
    def gef_c(self) -> Path:
        return self.root / self.manifest.gef_c


def _git(*args: str) -> str:
    # GIT_OPTIONAL_LOCKS=0 stops `git status` from refreshing the submodule's index.
    env = dict(os.environ, GIT_OPTIONAL_LOCKS="0", LC_ALL="C")
    try:
        proc = subprocess.run(
            ["git", "-C", str(SUBMODULE_DIR), *args],
            capture_output=True,
            text=True,
            check=False,
            timeout=_GIT_TIMEOUT_S,
            env=env,
        )
    except OSError as exc:
        raise FbsrcError(f"cannot run git: {exc}") from exc
    if proc.returncode != 0:
        raise FbsrcError(
            f"git {' '.join(args)} failed in {display_path(SUBMODULE_DIR)} "
            f"(is the submodule checked out?): {proc.stderr.strip()}"
        )
    return proc.stdout.strip()


@dataclass(frozen=True)
class SubmoduleRevision:
    short: str
    commit: str
    commit_epoch: int


def submodule_revision() -> SubmoduleRevision:
    """The checked-out commit of the GEF submodule; refuses a modified ``source/``."""
    short = _git("rev-parse", "--short", "HEAD")
    commit = _git("rev-parse", "HEAD")
    epoch = int(_git("log", "-1", "--format=%ct", "HEAD"))
    dirty = _git("status", "--porcelain", "--", "source")
    if dirty:
        raise FbsrcError(
            f"{display_path(GEF_SOURCE_DIR)} has local changes; emission keys assume the "
            f"committed revision. Put modifications in a --patch-dir instead:\n{dirty}"
        )
    return SubmoduleRevision(short, commit, epoch)


def patch_files(patch_dir: Path) -> list[Path]:
    """The patches in ``patch_dir`` in application order; rejects anything else."""
    if not patch_dir.is_dir():
        raise FbsrcError(f"patch directory {patch_dir} does not exist")
    entries = sorted(patch_dir.iterdir(), key=lambda p: p.name)
    bad = [p.name for p in entries if not (p.is_file() and p.suffix in PATCH_SUFFIXES)]
    if bad:
        raise FbsrcError(
            f"patch directory {patch_dir} may only contain *.patch/*.diff files; found {bad}"
        )
    if not entries:
        raise FbsrcError(f"patch directory {patch_dir} contains no *.patch/*.diff files")
    return entries


def patch_dir_sha256(patches: Sequence[Path]) -> str:
    """SHA-256 over the patch file names and contents, in application order."""
    digest = hashlib.sha256()
    for patch in patches:
        digest.update(patch.name.encode() + b"\0" + sha256_file(patch).encode() + b"\n")
    return digest.hexdigest()


def emission_key(revision: str, patch_sha256: str | None) -> str:
    return revision if patch_sha256 is None else f"{revision}-p{patch_sha256[:12]}"


def normalised_sha256(gef_c: Path, src_dir: Path) -> str:
    """SHA-256 of ``GEF.c`` with the absolute source directory removed from ``#line`` paths.

    fbc writes included files into ``#line`` directives with absolute paths, so the raw
    hash depends on the emission directory; this one does not.
    """
    prefix = b'"' + str(src_dir).encode() + b"/"
    return hashlib.sha256(gef_c.read_bytes().replace(prefix, b'"')).hexdigest()


def _load_valid(root: Path, key: str, commit: str, patch_sha256: str | None) -> Manifest | None:
    manifest_path = root / MANIFEST_NAME
    try:
        manifest = Manifest.from_json(manifest_path.read_text(encoding="utf-8"))
    except OSError, ValueError, TypeError:
        return None
    gef_c = root / manifest.gef_c
    if (
        manifest.schema != MANIFEST_SCHEMA
        or manifest.key != key
        or manifest.submodule_commit != commit
        or manifest.patch_dir_sha256 != patch_sha256
        or manifest.fbc_version != REQUIRED_FBC_VERSION
        or not gef_c.is_file()
        or sha256_file(gef_c) != manifest.gef_c_sha256
    ):
        return None
    return manifest


@contextmanager
def _locked(lock_path: Path) -> Generator[None]:
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open("w") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def _apply_patches(patches: Sequence[Path], src_dir: Path) -> None:
    patch_exe = shutil.which("patch")
    if patch_exe is None:
        raise FbsrcError("GNU patch is needed for --patch-dir but is not on PATH")
    for patch in patches:
        proc = subprocess.run(
            [
                patch_exe,
                "-p1",
                "--batch",
                "--forward",
                "--no-backup-if-mismatch",
                "--reject-file=-",
                "-d",
                str(src_dir),
                "-i",
                str(patch),
            ],
            capture_output=True,
            text=True,
            check=False,
            timeout=_GIT_TIMEOUT_S,
        )
        if proc.returncode != 0:
            raise FbsrcError(
                f"patch {patch.name} does not apply to the source copy:\n"
                f"{(proc.stdout + proc.stderr).strip()}"
            )


def _run_fbc(fbc: Path, src_dir: Path, source_date_epoch: int) -> tuple[list[str], float, str]:
    command = [str(fbc), *FBC_ARGS]
    env = dict(os.environ, SOURCE_DATE_EPOCH=str(source_date_epoch))
    start = time.perf_counter()
    try:
        proc = subprocess.run(
            command,
            cwd=src_dir,
            capture_output=True,
            text=True,
            check=False,
            timeout=_FBC_TIMEOUT_S,
            env=env,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise FbsrcError(f"running fbc failed: {exc}") from exc
    elapsed = time.perf_counter() - start
    diagnostics = "\n".join(
        part for part in (proc.stdout.strip(), filter_fbc_stderr(proc.stderr).strip()) if part
    )
    if proc.returncode != 0:
        raise FbsrcError(f"fbc exited with status {proc.returncode}:\n{diagnostics}")
    if not (src_dir / GEF_C).is_file():
        raise FbsrcError(f"fbc succeeded but did not leave {GEF_C} in {display_path(src_dir)}")
    return command, elapsed, diagnostics


def emit(
    patch_dir: Path | None = None, force: bool = False, build_root: Path = FBSRC_BUILD_DIR
) -> Emission:
    """Return the emission for (submodule revision, patch dir), creating it if needed."""
    start = time.perf_counter()
    rev = submodule_revision()
    patches = patch_files(patch_dir) if patch_dir is not None else []
    patch_sha = patch_dir_sha256(patches) if patch_dir is not None else None
    key = emission_key(rev.short, patch_sha)
    root = build_root / key
    # One lock for all keys: emissions are rare and serialising them keeps build/ tidy.
    with _locked(build_root / ".emit.lock"):
        if not force:
            existing = _load_valid(root, key, rev.commit, patch_sha)
            if existing is not None:
                return Emission(root, existing, reused=True)
        try:
            fbc = resolve_fbc()
        except FbcError as exc:
            raise FbsrcError(str(exc)) from exc
        if root.exists():
            shutil.rmtree(root)
        src_dir = root / "src"
        try:
            shutil.copytree(GEF_SOURCE_DIR, src_dir)
            _apply_patches(patches, src_dir)
            command, fbc_seconds, diagnostics = _run_fbc(fbc, src_dir, rev.commit_epoch)
        except BaseException:
            shutil.rmtree(root, ignore_errors=True)
            raise
        gef_c = src_dir / GEF_C
        manifest = Manifest(
            schema=MANIFEST_SCHEMA,
            key=key,
            submodule_revision=rev.short,
            submodule_commit=rev.commit,
            patch_dir=str(patch_dir.resolve()) if patch_dir is not None else None,
            patch_dir_sha256=patch_sha,
            patches=[p.name for p in patches],
            source_date_epoch=rev.commit_epoch,
            fbc_path=str(fbc),
            fbc_version=fbc_version(fbc),
            command=command,
            cwd=str(src_dir),
            gef_c=f"src/{GEF_C}",
            gef_c_sha256=sha256_file(gef_c),
            gef_c_sha256_normalised=normalised_sha256(gef_c, src_dir),
            fbc_wall_time_s=round(fbc_seconds, 3),
            total_wall_time_s=round(time.perf_counter() - start, 3),
            fbc_diagnostics=diagnostics,
            created_utc=datetime.now(UTC).isoformat(timespec="seconds"),
        )
        (root / MANIFEST_NAME).write_text(manifest.to_json(), encoding="utf-8")
        return Emission(root, manifest, reused=False)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.fbsrc.emit_c",
        description="Translate the GEF BASIC source to C with fbc into build/fbsrc/<key>/.",
    )
    parser.add_argument(
        "--patch-dir",
        type=Path,
        help="directory of unified diffs (*.patch, *.diff; patch -p1) applied to the copy",
    )
    parser.add_argument(
        "--force", action="store_true", help="re-emit even if a matching emission exists"
    )
    args = parser.parse_args(argv)
    patch_dir: Path | None = args.patch_dir
    force: bool = args.force
    try:
        emission = emit(patch_dir, force)
    except FbsrcError as exc:
        print(f"emit_c: {exc}", file=sys.stderr)
        return 1
    m = emission.manifest
    if emission.reused:
        print(f"reused  {display_path(emission.gef_c)}")
    else:
        print(
            f"emitted {display_path(emission.gef_c)} "
            f"(fbc {m.fbc_wall_time_s:.1f} s, total {m.total_wall_time_s:.1f} s)"
        )
        if m.fbc_diagnostics:
            print(f"fbc diagnostics:\n{m.fbc_diagnostics}", file=sys.stderr)
    print(f"key     {m.key}")
    print(f"sha256  {m.gef_c_sha256}")
    print(f"manifest {display_path(emission.root / MANIFEST_NAME)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
