# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Immutable reference store for harness captures and reference binaries.

Captures (copied run directories) live in ``validation/reference_store/captures/<id>/``
and binaries in ``validation/reference_store/binaries/<sha256>/GEF`` (both gitignored,
read-only files).  Their committed manifests live in ``manifests/reference_store/``.

Usage::

    python3 -m harness.store add <run-dir> --id <capture-id> --kind run|capture|driver [--note TEXT]
    python3 -m harness.store add-binary <path> [--note TEXT] [--provenance-json FILE]
    python3 -m harness.store verify [ID ...]     # capture ids and/or binary-<sha256[:12]>
    python3 -m harness.store list

Capture ids match ``[a-z0-9][a-z0-9._-]*`` (and do not start with ``binary-``).  An id that
already exists, in the store or as a manifest, is refused: captures are immutable.

Capture manifest ``manifests/reference_store/<id>.json`` (schema 1)::

    {"schema": 1, "id", "kind", "note", "created_utc",
     "run_json": <run.json content, if present>, "driver_json": <driver.json, if present>,
     "file_count", "total_bytes", "files": {"<relative path>": "<sha256>", ...}}

Binary manifest ``binary-<sha256[:12]>.json``::

    {"schema": 1, "kind": "binary", "sha256", "size", "note", "created_utc", "provenance": {...}}

Only regular files are stored (symlinks and special files are rejected); empty directories
are not preserved.

Exit codes: 0 success; 1 verification problems or an error; 2 usage error (argparse);
77 ``verify`` skipped because the ``validation/`` directory is absent.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import stat
import sys
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, cast

from harness.common import (
    MANIFEST_STORE_DIR,
    STORE_BINARIES,
    STORE_CAPTURES,
    HarnessError,
    sha256_file,
    write_json,
)

SCHEMA_VERSION = 1
EXIT_OK = 0
EXIT_FAILED = 1
EXIT_SKIPPED = 77
KINDS = ("run", "capture", "driver")
_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
_BINARY_PREFIX = "binary-"
_BINARY_NAME = "GEF"


@dataclass(frozen=True)
class StorePaths:
    """Directories of one store (override in tests)."""

    captures: Path = STORE_CAPTURES
    binaries: Path = STORE_BINARIES
    manifests: Path = MANIFEST_STORE_DIR

    @property
    def validation_dir(self) -> Path:
        """The directory whose absence makes ``verify`` skip (parent of the store root)."""
        return self.captures.parent.parent


@dataclass
class EntryReport:
    """Verification result for one capture or binary."""

    id: str
    missing: list[str] = field(default_factory=list[str])
    changed: list[str] = field(default_factory=list[str])
    extra: list[str] = field(default_factory=list[str])
    error: str = ""

    @property
    def ok(self) -> bool:
        return not (self.missing or self.changed or self.extra or self.error)


@dataclass
class Report:
    """Verification result for a set of entries."""

    entries: list[EntryReport] = field(default_factory=list[EntryReport])

    @property
    def ok(self) -> bool:
        return all(e.ok for e in self.entries)


def _now() -> str:
    return datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


def _check_id(capture_id: str) -> None:
    if not _ID_RE.fullmatch(capture_id):
        raise HarnessError(f"invalid capture id {capture_id!r}: must match [a-z0-9][a-z0-9._-]*")
    if capture_id.startswith(_BINARY_PREFIX):
        raise HarnessError(f"invalid capture id {capture_id!r}: prefix 'binary-' is reserved")


def _readonly(path: Path) -> None:
    path.chmod(path.stat().st_mode & ~(stat.S_IWUSR | stat.S_IWGRP | stat.S_IWOTH))


def _scan_files(root: Path) -> list[str]:
    """Relative POSIX paths of the regular files below ``root``; rejects symlinks/specials."""
    found: list[str] = []
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        base = Path(dirpath)
        for name in dirnames:
            if (base / name).is_symlink():
                raise HarnessError(f"symlink not allowed: {(base / name).relative_to(root)}")
        for name in filenames:
            path = base / name
            if path.is_symlink() or not stat.S_ISREG(path.lstat().st_mode):
                raise HarnessError(f"not a regular file: {path.relative_to(root)}")
            found.append(path.relative_to(root).as_posix())
    return sorted(found)


def _hash_all(root: Path, rels: Sequence[str]) -> dict[str, str]:
    with ThreadPoolExecutor(max_workers=max(1, os.cpu_count() or 1)) as pool:
        digests = list(pool.map(sha256_file, [root / r for r in rels]))
    return dict(zip(rels, digests, strict=True))


def _load_json(path: Path) -> dict[str, Any]:
    try:
        data: object = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise HarnessError(f"cannot read {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise HarnessError(f"{path}: expected a JSON object")
    return cast("dict[str, Any]", data)


def _rmtree_force(path: Path) -> None:
    for dirpath, dirnames, _ in os.walk(path):
        for name in dirnames:
            (Path(dirpath) / name).chmod(0o755)
    path.chmod(0o755)
    shutil.rmtree(path, ignore_errors=True)


def add_capture(
    run_dir: Path,
    capture_id: str,
    kind: str,
    note: str = "",
    paths: StorePaths | None = None,
) -> Path:
    """Copy ``run_dir`` into the store as ``capture_id`` and write its manifest.

    Returns the manifest path.  Raises HarnessError on a bad id/kind/source or if the id
    already exists in the store or the manifest directory.
    """
    p = paths or StorePaths()
    _check_id(capture_id)
    if kind not in KINDS:
        raise HarnessError(f"invalid kind {kind!r}: expected one of {', '.join(KINDS)}")
    if not run_dir.is_dir() or run_dir.is_symlink():
        raise HarnessError(f"not a directory: {run_dir}")
    dest = p.captures / capture_id
    manifest_path = p.manifests / f"{capture_id}.json"
    if dest.exists() or manifest_path.exists():
        raise HarnessError(f"capture {capture_id!r} already exists; captures are immutable")
    rels = _scan_files(run_dir)

    p.captures.mkdir(parents=True, exist_ok=True)
    tmp = p.captures / f".tmp-{capture_id}"
    if tmp.exists():
        _rmtree_force(tmp)
    try:
        for rel in rels:
            target = tmp / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(run_dir / rel, target)
            shutil.copymode(run_dir / rel, target)
            _readonly(target)
        tmp.mkdir(exist_ok=True)
        hashes = _hash_all(tmp, rels)
        manifest: dict[str, Any] = {
            "schema": SCHEMA_VERSION,
            "id": capture_id,
            "kind": kind,
            "note": note,
            "created_utc": _now(),
            "file_count": len(rels),
            "total_bytes": sum((tmp / r).stat().st_size for r in rels),
            "files": dict(sorted(hashes.items())),
        }
        for key, name in (("run_json", "run.json"), ("driver_json", "driver.json")):
            if name in hashes:
                manifest[key] = _load_json(tmp / name)
        tmp.rename(dest)
    except BaseException:
        _rmtree_force(tmp)
        raise
    write_json(manifest_path, manifest)
    return manifest_path


def add_binary(
    binary: Path,
    note: str = "",
    provenance: dict[str, Any] | None = None,
    paths: StorePaths | None = None,
) -> str:
    """Store ``binary`` under its SHA-256 and write its manifest; returns the SHA-256.

    Adding an identical binary again is a no-op.
    """
    p = paths or StorePaths()
    if not binary.is_file():
        raise HarnessError(f"not a file: {binary}")
    digest = sha256_file(binary)
    dest_dir = p.binaries / digest
    dest = dest_dir / _BINARY_NAME
    manifest_path = p.manifests / f"{_BINARY_PREFIX}{digest[:12]}.json"
    if dest.exists() and manifest_path.exists():
        if sha256_file(dest) != digest:
            raise HarnessError(f"stored binary {dest} is corrupt; run 'verify'")
        return digest
    dest_dir.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        dest.chmod(0o755)
    tmp = dest_dir / f".tmp-{_BINARY_NAME}"
    shutil.copyfile(binary, tmp)
    tmp.chmod(0o555)
    tmp.replace(dest)
    write_json(
        manifest_path,
        {
            "schema": SCHEMA_VERSION,
            "kind": "binary",
            "sha256": digest,
            "size": dest.stat().st_size,
            "note": note,
            "created_utc": _now(),
            "provenance": provenance or {},
        },
    )
    return digest


def _manifest_files(manifest: dict[str, Any]) -> dict[str, str]:
    files = manifest.get("files")
    if not isinstance(files, dict):
        raise HarnessError("manifest has no 'files' object")
    return {str(k): str(v) for k, v in cast("dict[object, object]", files).items()}


def _verify_capture(entry_id: str, manifest: dict[str, Any], p: StorePaths) -> EntryReport:
    rep = EntryReport(entry_id)
    root = p.captures / entry_id
    if not root.is_dir():
        rep.error = f"capture directory missing: {root}"
        return rep
    expected = _manifest_files(manifest)
    try:
        on_disk = set(_scan_files(root))
    except HarnessError as exc:
        rep.error = str(exc)
        return rep
    rep.missing = sorted(set(expected) - on_disk)
    rep.extra = sorted(on_disk - set(expected))
    present = sorted(on_disk & set(expected))
    actual = _hash_all(root, present)
    rep.changed = [r for r in present if actual[r] != expected[r]]
    return rep


def _verify_binary(entry_id: str, manifest: dict[str, Any], p: StorePaths) -> EntryReport:
    rep = EntryReport(entry_id)
    digest = str(manifest.get("sha256", ""))
    path = p.binaries / digest / _BINARY_NAME
    rel = f"{digest}/{_BINARY_NAME}"
    if not path.is_file():
        rep.missing = [rel]
    elif sha256_file(path) != digest:
        rep.changed = [rel]
    return rep


def verify(ids: Sequence[str] | None = None, paths: StorePaths | None = None) -> Report:
    """Verify captures/binaries against their manifests (all manifests when ``ids`` is None).

    Without ``ids``, capture directories lacking a manifest are reported as errors.
    """
    p = paths or StorePaths()
    report = Report()
    if ids is None:
        names = sorted(f.stem for f in p.manifests.glob("*.json")) if p.manifests.is_dir() else []
    else:
        names = list(ids)
    for name in names:
        manifest_path = p.manifests / f"{name}.json"
        if not manifest_path.is_file():
            report.entries.append(EntryReport(name, error=f"no manifest {manifest_path}"))
            continue
        try:
            manifest = _load_json(manifest_path)
            if manifest.get("kind") == "binary":
                report.entries.append(_verify_binary(name, manifest, p))
            else:
                report.entries.append(_verify_capture(name, manifest, p))
        except HarnessError as exc:
            report.entries.append(EntryReport(name, error=str(exc)))
    if ids is None and p.captures.is_dir():
        known = set(names)
        for d in sorted(p.captures.iterdir()):
            if d.is_dir() and not d.name.startswith(".") and d.name not in known:
                report.entries.append(EntryReport(d.name, error="capture has no manifest"))
    return report


def list_captures(paths: StorePaths | None = None) -> list[dict[str, Any]]:
    """Summaries (id, kind, created_utc, file_count, total_bytes, note) of all captures."""
    p = paths or StorePaths()
    out: list[dict[str, Any]] = []
    if not p.manifests.is_dir():
        return out
    for f in sorted(p.manifests.glob("*.json")):
        m = _load_json(f)
        if m.get("kind") == "binary":
            continue
        out.append({k: m.get(k) for k in _SUMMARY_KEYS})
    return out


_SUMMARY_KEYS = ("id", "kind", "created_utc", "file_count", "total_bytes", "note")


def _print_report(report: Report) -> None:
    for e in report.entries:
        if e.ok:
            print(f"ok       {e.id}")
            continue
        print(f"PROBLEM  {e.id}")
        if e.error:
            print(f"  error: {e.error}")
        for label, items in (("missing", e.missing), ("changed", e.changed), ("extra", e.extra)):
            for item in items:
                print(f"  {label}: {item}")


def main(argv: Sequence[str] | None = None, paths: StorePaths | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m harness.store", description="Immutable reference store."
    )
    sub = parser.add_subparsers(dest="cmd", required=True)
    add = sub.add_parser("add", help="copy a run directory into the store")
    add.add_argument("run_dir", type=Path)
    add.add_argument("--id", required=True, dest="capture_id")
    add.add_argument("--kind", required=True, choices=KINDS)
    add.add_argument("--note", default="")
    addb = sub.add_parser("add-binary", help="store a reference binary by SHA-256")
    addb.add_argument("binary", type=Path)
    addb.add_argument("--note", default="")
    addb.add_argument("--provenance-json", type=Path)
    ver = sub.add_parser("verify", help="verify captures/binaries against their manifests")
    ver.add_argument("ids", nargs="*")
    sub.add_parser("list", help="list captures")
    args = parser.parse_args(argv)
    p = paths or StorePaths()
    try:
        if args.cmd == "add":
            manifest = add_capture(args.run_dir, args.capture_id, args.kind, args.note, p)
            print(f"added {args.capture_id}: {manifest}")
        elif args.cmd == "add-binary":
            prov: dict[str, Any] = {}
            if args.provenance_json:
                prov = _load_json(args.provenance_json)
            print(add_binary(args.binary, args.note, prov, p))
        elif args.cmd == "verify":
            if not p.validation_dir.is_dir():
                print(f"skipped: {p.validation_dir} not present")
                return EXIT_SKIPPED
            report = verify(args.ids or None, p)
            _print_report(report)
            print(f"{len(report.entries)} entries: {'OK' if report.ok else 'PROBLEMS FOUND'}")
            return EXIT_OK if report.ok else EXIT_FAILED
        else:
            for c in list_captures(p):
                print(
                    f"{c['id']}\t{c['kind']}\t{c['created_utc']}\t"
                    f"{c['file_count']} files\t{c['total_bytes']} bytes\t{c['note']}"
                )
    except HarnessError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return EXIT_FAILED
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
