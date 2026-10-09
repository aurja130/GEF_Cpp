# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Build a patched GEF binary from a named patch set (M1.2).

Usage (from the repository root)::

    python3 -m harness.build <patchset> [--define NAME[=VALUE] ...] [--force]
                             [--source-date-epoch N]
    python3 -m harness.build --compare-sections <binary A> <binary B>

``<patchset>`` names ``harness/patchsets/<patchset>.txt``: one patch name per line (without
``.patch``), ``#`` comments allowed, in the canonical stacking order: the M4 variant patches
(``nucprop-*``, ``legacy-isosource``), then ``seed``, ``scope``, ``reseed``, ``rndlog``,
``probes``, ``datachain``, ``lookups``. The set ``none`` is empty (the unmodified source).

The build copies the submodule source to ``build/harness/<build-id>/src/``, applies the
patches with ``patch -p1 --fuzz=0``, runs ``fbc GEF.bas [-d DEFINE ...]`` with
``SOURCE_DATE_EPOCH`` set to the submodule commit time (``GEF`` prints its compile stamp), moves
the binary to ``build/harness/<build-id>/GEF`` and writes ``build.json`` last. The build id
``<patchset>-<12 hex>`` hashes the patch contents in order, the defines, the submodule commit,
the fbc version and the epoch, so the same request always maps to the same directory. A valid
existing build is reused unless ``--force`` is given. Concurrent builds are serialised by a lock.

``materialize_patch_dir`` writes a patch set as ``NN-<name>.patch`` files, which
``python3 -m tools.fbsrc.emit_c --patch-dir`` accepts, to inspect the generated C.

``--compare-sections`` compares every ALLOC section (name, type, flags, address, contents) of
two ELF64 binaries; exit status 0 when all are identical, 1 otherwise. It re-establishes the
plan fact that the unpatched build equals ``validation/test_run/gef_reference`` (build with
``--source-date-epoch`` of 2026-09-15 17:20:38 UTC, i.e. 1789492838).

Exit status: 0 success, 1 failure (message on stderr).
"""

from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import time
from collections.abc import Generator, Sequence
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from harness.common import (
    BUILD_ROOT,
    GEF_SOURCE_DIR,
    PATCHES_DIR,
    PATCHSETS_DIR,
    HarnessError,
    sha256_file,
    write_json,
)
from tools.fbsrc.common import FbsrcError
from tools.fbsrc.emit_c import submodule_revision
from tools.toolchain.fbc import FbcError, fbc_version, filter_fbc_stderr, resolve_fbc

__all__ = [
    "CANONICAL_ORDER",
    "BuildResult",
    "SectionComparison",
    "build",
    "compare_sections",
    "compute_build_id",
    "materialize_patch_dir",
    "read_patchset",
    "resolve_binary",
]

SCHEMA = 1
# Variant patches (M4: alternative nuclide-data and branching files) come first, the DATA chain
# dump (M4) last.
CANONICAL_ORDER = (
    "nucprop-jeff311",
    "nucprop-nubase2016",
    "nucprop-nubase2020",
    "nucprop-x",
    "nucprop-mf",
    "nucprop-f",
    "legacy-isosource",
    "seed",
    "scope",
    "reseed",
    "rndlog",
    "probes",
    "datachain",
    "lookups",
)
BINARY_NAME = "GEF"
BUILD_JSON = "build.json"
_DEFINE_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(=[A-Za-z0-9_.+-]+)?$")
_NAME_RE = re.compile(r"^[A-Za-z0-9_-]+$")
_TIMEOUT_S = 900


@dataclass(frozen=True)
class BuildResult:
    """A complete build on disk."""

    build_id: str
    root: Path
    binary: Path
    manifest: dict[str, Any]
    reused: bool


# --------------------------------------------------------------------------- patch sets


def read_patchset(
    name: str, patchsets_dir: Path = PATCHSETS_DIR, patches_dir: Path = PATCHES_DIR
) -> list[Path]:
    """The patch files of set ``name`` in application order.

    Rejects unknown sets, unknown or duplicate patches, missing patch files and any order
    that differs from ``CANONICAL_ORDER``.
    """
    if not _NAME_RE.fullmatch(name):
        raise HarnessError(f"invalid patch set name {name!r}")
    set_file = patchsets_dir / f"{name}.txt"
    if not set_file.is_file():
        raise HarnessError(f"patch set {name!r} not found ({set_file})")
    names: list[str] = []
    for lineno, raw in enumerate(set_file.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        if line not in CANONICAL_ORDER:
            raise HarnessError(
                f"{set_file}:{lineno}: unknown patch {line!r}; known: {', '.join(CANONICAL_ORDER)}"
            )
        if line in names:
            raise HarnessError(f"{set_file}:{lineno}: patch {line!r} listed twice")
        names.append(line)
    if names != sorted(names, key=CANONICAL_ORDER.index):
        raise HarnessError(
            f"{set_file}: patches {names} are not in canonical order {list(CANONICAL_ORDER)}"
        )
    files: list[Path] = []
    for patch in names:
        path = patches_dir / f"{patch}.patch"
        if not path.is_file():
            raise HarnessError(f"{set_file}: patch file {path} does not exist")
        files.append(path)
    return files


def materialize_patch_dir(
    name: str,
    out_root: Path | None = None,
    patchsets_dir: Path = PATCHSETS_DIR,
    patches_dir: Path = PATCHES_DIR,
) -> Path:
    """Write set ``name`` as ``<out_root>/<name>/NN-<patch>.patch`` and return that directory.

    The directory is recreated each time. It is usable with ``emit_c --patch-dir`` (which
    rejects an empty directory, so the set ``none`` has nothing to emit there).
    """
    files = read_patchset(name, patchsets_dir, patches_dir)
    target = (out_root if out_root is not None else BUILD_ROOT / "patchdirs") / name
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True)
    for index, path in enumerate(files, 1):
        shutil.copyfile(path, target / f"{index:02d}-{path.name}")
    return target


# --------------------------------------------------------------------------- build id


def validate_defines(defines: Sequence[str]) -> list[str]:
    """Sorted, de-duplicated defines; each must be ``NAME`` or ``NAME=VALUE``."""
    bad = [d for d in defines if not _DEFINE_RE.fullmatch(d)]
    if bad:
        raise HarnessError(f"invalid --define {bad}; expected NAME or NAME=VALUE")
    return sorted(set(defines))


def compute_build_id(
    patchset: str,
    patches: Sequence[tuple[str, str]],
    defines: Sequence[str],
    submodule_commit: str,
    fbc_ver: str,
    source_date_epoch: int,
) -> str:
    """``<patchset>-<12 hex>`` over everything that determines the binary."""
    payload = json.dumps(
        {
            "patches": [[n, h] for n, h in patches],
            "defines": sorted(set(defines)),
            "submodule_commit": submodule_commit,
            "fbc_version": fbc_ver,
            "source_date_epoch": source_date_epoch,
        },
        sort_keys=True,
    )
    return f"{patchset}-{hashlib.sha256(payload.encode()).hexdigest()[:12]}"


# --------------------------------------------------------------------------- build


@contextmanager
def _locked(lock_path: Path) -> Generator[None]:
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open("w") as handle:
        fcntl.flock(handle, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def _load_valid(root: Path, build_id: str) -> dict[str, Any] | None:
    try:
        raw: Any = json.loads((root / BUILD_JSON).read_text(encoding="utf-8"))
    except OSError, ValueError:
        return None
    if not isinstance(raw, dict):
        return None
    manifest: dict[str, Any] = {str(k): v for k, v in raw.items()}  # pyright: ignore[reportUnknownVariableType, reportUnknownArgumentType]
    binary = root / BINARY_NAME
    if (
        manifest.get("schema") != SCHEMA
        or manifest.get("build_id") != build_id
        or not binary.is_file()
        or sha256_file(binary) != manifest.get("binary_sha256")
    ):
        return None
    return manifest


def _apply_patch(patch: Path, src_dir: Path) -> None:
    patch_exe = shutil.which("patch")
    if patch_exe is None:
        raise HarnessError("GNU patch is needed but is not on PATH")
    proc = subprocess.run(
        [
            patch_exe,
            "-p1",
            "--fuzz=0",
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
        timeout=120,
    )
    if proc.returncode != 0:
        raise HarnessError(
            f"patch {patch.name} does not apply to the source copy (check the stacking order):\n"
            f"{(proc.stdout + proc.stderr).strip()}"
        )


def build(
    patchset: str,
    defines: Sequence[str] = (),
    *,
    force: bool = False,
    source_date_epoch: int | None = None,
    build_root: Path = BUILD_ROOT,
    source_dir: Path = GEF_SOURCE_DIR,
    patchsets_dir: Path = PATCHSETS_DIR,
    patches_dir: Path = PATCHES_DIR,
) -> BuildResult:
    """Build (or reuse) the binary for ``patchset`` plus ``defines``."""
    clean_defines = validate_defines(defines)
    patches = read_patchset(patchset, patchsets_dir, patches_dir)
    patch_hashes = [(p.stem, sha256_file(p)) for p in patches]
    try:
        revision = submodule_revision()
        fbc = resolve_fbc()
        fbc_ver = fbc_version(fbc)
    except (FbsrcError, FbcError) as exc:
        raise HarnessError(str(exc)) from exc
    epoch = revision.commit_epoch if source_date_epoch is None else source_date_epoch
    build_id = compute_build_id(
        patchset, patch_hashes, clean_defines, revision.commit, fbc_ver, epoch
    )
    root = build_root / build_id
    with _locked(build_root / ".build.lock"):
        if not force:
            existing = _load_valid(root, build_id)
            if existing is not None:
                return BuildResult(build_id, root, root / BINARY_NAME, existing, reused=True)
        if root.exists():
            shutil.rmtree(root)
        src_dir = root / "src"
        try:
            shutil.copytree(source_dir, src_dir)
            for patch in patches:
                _apply_patch(patch, src_dir)
            command = [str(fbc), "GEF.bas"]
            for define in clean_defines:
                command += ["-d", define]
            env = dict(os.environ, SOURCE_DATE_EPOCH=str(epoch))
            start = time.perf_counter()
            try:
                proc = subprocess.run(
                    command,
                    cwd=src_dir,
                    capture_output=True,
                    text=True,
                    check=False,
                    timeout=_TIMEOUT_S,
                    env=env,
                )
            except (OSError, subprocess.TimeoutExpired) as exc:
                raise HarnessError(f"running fbc failed: {exc}") from exc
            wall = time.perf_counter() - start
            diagnostics = "\n".join(
                part
                for part in (proc.stdout.strip(), filter_fbc_stderr(proc.stderr).strip())
                if part
            )
            if proc.returncode != 0:
                raise HarnessError(f"fbc exited with status {proc.returncode}:\n{diagnostics}")
            produced = src_dir / BINARY_NAME
            if not produced.is_file():
                raise HarnessError(f"fbc succeeded but did not produce {produced}")
            binary = root / BINARY_NAME
            shutil.move(produced, binary)
        except BaseException:
            shutil.rmtree(root, ignore_errors=True)
            raise
        manifest: dict[str, Any] = {
            "schema": SCHEMA,
            "build_id": build_id,
            "patchset": patchset,
            "patches": [{"name": n, "sha256": h} for n, h in patch_hashes],
            "defines": clean_defines,
            "fbc_path": str(fbc),
            "fbc_version": fbc_ver,
            "command": command,
            "cwd": str(src_dir),
            "source_date_epoch": epoch,
            "submodule_commit": revision.commit,
            "binary": BINARY_NAME,
            "binary_sha256": sha256_file(binary),
            "fbc_wall_time_s": round(wall, 3),
            "fbc_diagnostics": diagnostics,
        }
        write_json(root / BUILD_JSON, manifest)
        return BuildResult(build_id, root, binary, manifest, reused=False)


def resolve_binary(spec: str, build_root: Path = BUILD_ROOT) -> Path:
    """``spec`` as a file path, or a build id under ``build_root``."""
    path = Path(spec)
    if path.is_file():
        return path.resolve()
    candidate = build_root / spec / BINARY_NAME
    if candidate.is_file():
        return candidate.resolve()
    raise HarnessError(f"{spec!r} is neither a binary file nor a build id under {build_root}")


# --------------------------------------------------------------------------- ELF sections

_SHF_ALLOC = 0x2
_SHT_NOBITS = 8


@dataclass(frozen=True)
class _Section:
    name: str
    sh_type: int
    flags: int
    addr: int
    size: int
    content: bytes


@dataclass(frozen=True)
class SectionComparison:
    """Result of comparing the ALLOC sections of two binaries."""

    identical: list[str]
    different: list[str]
    only_in_a: list[str]
    only_in_b: list[str]

    @property
    def equal(self) -> bool:
        return not (self.different or self.only_in_a or self.only_in_b)


def _alloc_sections(path: Path) -> dict[str, _Section]:
    data = path.read_bytes()
    if data[:4] != b"\x7fELF" or data[4] != 2 or data[5] != 1:
        raise HarnessError(f"{path} is not a little-endian ELF64 file")
    (shoff,) = struct.unpack_from("<Q", data, 0x28)
    shentsize, shnum, shstrndx = struct.unpack_from("<HHH", data, 0x3A)
    headers: list[tuple[int, int, int, int, int, int]] = []
    for index in range(shnum):
        off = shoff + index * shentsize
        name, sh_type, flags, addr, offset, size = struct.unpack_from("<IIQQQQ", data, off)
        headers.append((name, sh_type, flags, addr, offset, size))
    str_off, str_size = headers[shstrndx][4], headers[shstrndx][5]
    strtab = data[str_off : str_off + str_size]
    sections: dict[str, _Section] = {}
    for name_off, sh_type, flags, addr, offset, size in headers:
        if not flags & _SHF_ALLOC:
            continue
        name = strtab[name_off : strtab.index(b"\0", name_off)].decode("ascii")
        content = b"" if sh_type == _SHT_NOBITS else data[offset : offset + size]
        sections[name] = _Section(name, sh_type, flags, addr, size, content)
    return sections


def compare_sections(path_a: Path, path_b: Path) -> SectionComparison:
    """Compare the ALLOC (loaded) sections of two ELF64 binaries byte for byte."""
    a, b = _alloc_sections(path_a), _alloc_sections(path_b)
    identical: list[str] = []
    different: list[str] = []
    for name in a:
        if name in b:
            (identical if a[name] == b[name] else different).append(name)
    return SectionComparison(
        identical, different, [n for n in a if n not in b], [n for n in b if n not in a]
    )


# --------------------------------------------------------------------------- CLI


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m harness.build",
        description="Build a GEF binary from a patch set into build/harness/<build-id>/.",
    )
    parser.add_argument("patchset", nargs="?", help="patch set name (harness/patchsets/NAME.txt)")
    parser.add_argument(
        "--define", action="append", default=[], metavar="NAME", help="fbc -d NAME[=VALUE]"
    )
    parser.add_argument("--force", action="store_true", help="rebuild even if a valid build exists")
    parser.add_argument(
        "--source-date-epoch",
        type=int,
        help="SOURCE_DATE_EPOCH for fbc instead of the submodule commit time",
    )
    parser.add_argument(
        "--compare-sections",
        nargs=2,
        type=Path,
        metavar=("BIN_A", "BIN_B"),
        help="compare the ALLOC sections of two binaries instead of building",
    )
    args = parser.parse_args(argv)
    try:
        if args.compare_sections:
            if args.patchset:
                parser.error("--compare-sections takes no patch set")
            bin_a, bin_b = args.compare_sections
            cmp = compare_sections(bin_a, bin_b)
            print(f"identical ALLOC sections ({len(cmp.identical)}): {' '.join(cmp.identical)}")
            for label, names in (
                ("DIFFERENT", cmp.different),
                ("only in A", cmp.only_in_a),
                ("only in B", cmp.only_in_b),
            ):
                if names:
                    print(f"{label}: {' '.join(names)}")
            print("ALLOC sections identical" if cmp.equal else "ALLOC sections differ")
            return 0 if cmp.equal else 1
        if not args.patchset:
            parser.error("a patch set name is required")
        result = build(
            args.patchset,
            args.define,
            force=args.force,
            source_date_epoch=args.source_date_epoch,
        )
    except HarnessError as exc:
        print(f"harness.build: {exc}", file=sys.stderr)
        return 1
    m = result.manifest
    status = "reused" if result.reused else f"built in {m['fbc_wall_time_s']:.1f} s"
    print(f"{status}: {result.build_id}")
    print(f"binary  {result.binary}")
    print(f"sha256  {m['binary_sha256']}")
    if m["fbc_diagnostics"] and not result.reused:
        print(f"fbc diagnostics:\n{m['fbc_diagnostics']}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
