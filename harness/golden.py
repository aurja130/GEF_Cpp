# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Driver goldens for the C++ tests (M3 plan, decision D1).

A golden is the output directory of one FreeBASIC driver run, with its ``driver.json``.
Small goldens (at most ``MAX_COMMITTED_BYTES``) are committed under
``Cpp_implementation/tests/golden/<name>/``; larger ones go into the reference store as
capture ``<name>`` (kind ``driver``). C++ tests that need a store golden skip without it.

A *store-derived* golden (M4 plan, D7) is a small file computed from reference-store captures
(e.g. per-table fingerprints of a T0 dump). Its directory holds ``derived.json`` instead of
``driver.json``: the producing tool, the capture files it read with their SHA-256 (which the
committed store manifests must confirm), and the SHA-256 of every output file. Producers call
``write_derived``.

Usage::

    python3 -m harness.golden promote <driver> --name NAME [--note TEXT] [--replace] [-- args]
    python3 -m harness.golden check     # committed goldens still match their sources

``check`` fails when a driver source, an included or cut GEF source, the fbc version, a
capture file of a derived golden or a golden file no longer matches its record: such a golden
is stale and must be produced again.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path

from harness import driver, store
from harness.common import BUILD_ROOT, DRIVERS_DIR, GEF_SOURCE_DIR, REPO_ROOT, HarnessError
from harness.driver import DRIVER_JSON, cut_lines
from tools.fbsrc.common import sha256_file
from tools.toolchain.fbc import REQUIRED_FBC_VERSION

GOLDEN_DIR = REPO_ROOT / "Cpp_implementation" / "tests" / "golden"
MAX_COMMITTED_BYTES = 1_000_000
DERIVED_JSON = "derived.json"
STORE_MANIFESTS = REPO_ROOT / "manifests" / "reference_store"


def promote(
    driver_name: str,
    args: list[str],
    name: str,
    *,
    note: str = "",
    replace: bool = False,
    golden_dir: Path = GOLDEN_DIR,
    store_paths: store.StorePaths | None = None,
) -> Path:
    """Run ``driver_name`` and keep its outputs as golden ``name``; returns where it went."""
    BUILD_ROOT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=BUILD_ROOT, prefix="golden-") as tmp:
        result = driver.run(driver_name, args, out_dir=Path(tmp) / "out")
        if result.returncode != 0:
            raise HarnessError(f"driver {driver_name} exited with {result.returncode}")
        files = [p for p in result.out_dir.rglob("*") if p.is_file()]
        total = sum(p.stat().st_size for p in files)
        if total > MAX_COMMITTED_BYTES:
            return store.add_capture(result.out_dir, name, "driver", note, store_paths)
        dest = golden_dir / name
        if dest.exists():
            if not replace:
                raise HarnessError(f"golden {name!r} exists; pass --replace to promote again")
            shutil.rmtree(dest)
        shutil.copytree(result.out_dir, dest)
        return dest


def write_derived(golden: Path, tool: str, sources: list[tuple[str, str]]) -> Path:
    """Record a store-derived golden: ``sources`` are (capture id, file in capture) pairs.

    Call after writing the golden's output files into ``golden``; their hashes and those of the
    capture files (from the committed store manifests) go into ``derived.json``.
    """
    records: list[dict[str, str]] = []
    for capture, file in sources:
        files = _manifest_files(capture)
        if file not in files:
            raise HarnessError(f"{file} is not in the manifest of capture {capture}")
        records.append({"capture": capture, "file": file, "sha256": files[file]})
    outputs = {
        p.relative_to(golden).as_posix(): sha256_file(p)
        for p in sorted(golden.rglob("*"))
        if p.is_file() and p.name != DERIVED_JSON
    }
    record = {"kind": "store-derived", "tool": tool, "sources": records, "outputs": outputs}
    path = golden / DERIVED_JSON
    path.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def _manifest_files(capture: str) -> dict[str, str]:
    manifest = STORE_MANIFESTS / f"{capture}.json"
    if not manifest.is_file():
        raise HarnessError(f"no store manifest for capture {capture}")
    files: dict[str, str] = json.loads(manifest.read_text(encoding="utf-8"))["files"]
    return files


def _check_outputs(path: Path, outputs: dict[str, str], record_name: str) -> list[str]:
    problems: list[str] = []
    present = {
        p.relative_to(path).as_posix(): p
        for p in path.rglob("*")
        if p.is_file() and p.name != record_name
    }
    for rel in sorted(set(present) ^ set(outputs)):
        problems.append(f"{rel} is {'not recorded' if rel in present else 'missing'}")
    for rel in sorted(set(present) & set(outputs)):
        if sha256_file(present[rel]) != outputs[rel]:
            problems.append(f"{rel} differs from its recorded hash")
    return problems


def check_derived(path: Path) -> list[str]:
    """Problems that make the store-derived golden at ``path`` stale; empty when current."""
    record = json.loads((path / DERIVED_JSON).read_text(encoding="utf-8"))
    problems: list[str] = []
    for source in record["sources"]:
        try:
            files = _manifest_files(source["capture"])
        except HarnessError as exc:
            problems.append(str(exc))
            continue
        if files.get(source["file"]) != source["sha256"]:
            problems.append(f"capture file {source['capture']}/{source['file']} changed")
    problems += _check_outputs(path, record["outputs"], DERIVED_JSON)
    return [f"{path.name}: {p}" for p in problems]


def check_golden(path: Path, drivers_dir: Path = DRIVERS_DIR) -> list[str]:
    """Problems that make the committed golden at ``path`` stale; empty when current."""
    if (path / DERIVED_JSON).is_file():
        return check_derived(path)
    record_path = path / DRIVER_JSON
    if not record_path.is_file():
        return [f"{path.name}: no {DRIVER_JSON} or {DERIVED_JSON}"]
    record = json.loads(record_path.read_text(encoding="utf-8"))
    problems: list[str] = []
    source = drivers_dir / f"{record['driver']}.bas"
    if not source.is_file():
        problems.append(f"driver source {source.name} is missing")
    elif sha256_file(source) != record["driver_sha256"]:
        problems.append(f"driver source {source.name} changed")
    if record["fbc_version"] != REQUIRED_FBC_VERSION:
        problems.append(f"made with fbc {record['fbc_version']}, pinned {REQUIRED_FBC_VERSION}")
    if record["returncode"] != 0:
        problems.append(f"driver exited with {record['returncode']}")
    for inc in record["includes"]:
        src = GEF_SOURCE_DIR / inc["file"]
        if not src.is_file() or sha256_file(src) != inc["sha256"]:
            problems.append(f"included source {inc['file']} changed")
    for cut in record["cuts"]:
        src = GEF_SOURCE_DIR / cut["file"]
        data = cut_lines(src, cut["first"], cut["last"]) if src.is_file() else b""
        if hashlib.sha256(data).hexdigest() != cut["cut_sha256"]:
            problems.append(f"cut {cut['file']}:{cut['first']}-{cut['last']} changed")
    problems += _check_outputs(path, record["outputs"], DRIVER_JSON)
    return [f"{path.name}: {p}" for p in problems]


def check(golden_dir: Path = GOLDEN_DIR, drivers_dir: Path = DRIVERS_DIR) -> list[str]:
    """Problems over every committed golden."""
    if not golden_dir.is_dir():
        return []
    return [
        problem
        for path in sorted(p for p in golden_dir.iterdir() if p.is_dir())
        for problem in check_golden(path, drivers_dir)
    ]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m harness.golden", description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p_promote = sub.add_parser("promote", help="run a driver and keep its outputs as a golden")
    p_promote.add_argument("driver")
    p_promote.add_argument("--name", required=True, help="golden directory or store capture id")
    p_promote.add_argument("--note", default="", help="note for a store capture")
    p_promote.add_argument("--replace", action="store_true", help="overwrite a committed golden")
    p_promote.add_argument("args", nargs="*", help="driver arguments, after --")
    sub.add_parser("check", help="verify committed goldens against their drivers")
    ns = parser.parse_args(argv)
    try:
        if ns.cmd == "promote":
            where = promote(ns.driver, ns.args, ns.name, note=ns.note, replace=ns.replace)
            print(where.relative_to(REPO_ROOT) if where.is_relative_to(REPO_ROOT) else where)
            return 0
        problems = check()
    except HarnessError as exc:
        print(f"harness.golden: {exc}", file=sys.stderr)
        return 2
    for problem in problems:
        print(problem)
    print("goldens OK" if not problems else f"{len(problems)} stale golden problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
