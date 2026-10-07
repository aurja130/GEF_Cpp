# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for harness.store (all roots in tmp_path)."""

from __future__ import annotations

import json
import os
from pathlib import Path

import pytest

from harness import store
from harness.common import HarnessError
from harness.store import StorePaths


@pytest.fixture
def paths(tmp_path: Path) -> StorePaths:
    root = tmp_path / "validation" / "reference_store"
    return StorePaths(root / "captures", root / "binaries", tmp_path / "manifests")


@pytest.fixture
def run_dir(tmp_path: Path) -> Path:
    d = tmp_path / "run"
    (d / "work" / "out").mkdir(parents=True)
    (d / "run.json").write_text('{"seed": 7}\n')
    (d / "stdout.log").write_text("hello\n")
    (d / "work" / "out" / "a.txt").write_text("data\n")
    return d


def test_roundtrip(paths: StorePaths, run_dir: Path) -> None:
    manifest = store.add_capture(run_dir, "r1", "run", "note", paths)
    data = json.loads(manifest.read_text())
    assert data["schema"] == 1
    assert data["run_json"] == {"seed": 7}
    assert data["file_count"] == 3
    assert list(data["files"]) == sorted(data["files"])
    assert "work/out/a.txt" in data["files"]
    copied = paths.captures / "r1" / "stdout.log"
    assert not os.access(copied, os.W_OK)
    assert store.verify(None, paths).ok
    assert store.verify(["r1"], paths).ok
    assert [c["id"] for c in store.list_captures(paths)] == ["r1"]
    assert store.main(["verify"], paths) == 0
    assert store.main(["list"], paths) == 0


def test_immutability(paths: StorePaths, run_dir: Path) -> None:
    store.add_capture(run_dir, "r1", "run", "", paths)
    with pytest.raises(HarnessError, match="already exists"):
        store.add_capture(run_dir, "r1", "run", "", paths)
    # manifest-only collision
    (paths.manifests / "r2.json").write_text("{}")
    with pytest.raises(HarnessError, match="already exists"):
        store.add_capture(run_dir, "r2", "run", "", paths)


def test_detects_missing_changed_extra(paths: StorePaths, run_dir: Path) -> None:
    store.add_capture(run_dir, "r1", "capture", "", paths)
    cap = paths.captures / "r1"
    (cap / "stdout.log").chmod(0o644)
    (cap / "stdout.log").write_text("tampered\n")
    (cap / "work" / "out" / "a.txt").unlink()
    (cap / "new.txt").write_text("x")
    rep = store.verify(["r1"], paths).entries[0]
    assert rep.changed == ["stdout.log"]
    assert rep.missing == ["work/out/a.txt"]
    assert rep.extra == ["new.txt"]
    assert store.main(["verify", "r1"], paths) == 1


def test_unknown_and_unmanifested(paths: StorePaths, run_dir: Path) -> None:
    store.add_capture(run_dir, "r1", "run", "", paths)
    assert not store.verify(["nope"], paths).ok
    (paths.captures / "stray").mkdir()
    assert not store.verify(None, paths).ok


@pytest.mark.parametrize("bad", ["", "A", "-x", ".x", "a/b", "a b", "binary-1"])
def test_invalid_ids(paths: StorePaths, run_dir: Path, bad: str) -> None:
    with pytest.raises(HarnessError):
        store.add_capture(run_dir, bad, "run", "", paths)


def test_invalid_kind_and_symlink(paths: StorePaths, run_dir: Path) -> None:
    with pytest.raises(HarnessError, match="kind"):
        store.add_capture(run_dir, "r1", "bogus", "", paths)
    (run_dir / "link").symlink_to(run_dir / "stdout.log")
    with pytest.raises(HarnessError, match="not a regular file"):
        store.add_capture(run_dir, "r1", "run", "", paths)
    assert not (paths.captures / "r1").exists()
    assert not (paths.manifests / "r1.json").exists()


def test_binary_idempotent(paths: StorePaths, tmp_path: Path) -> None:
    b = tmp_path / "gef"
    b.write_bytes(b"\x7fELF fake")
    d1 = store.add_binary(b, "n", {"src": "x"}, paths)
    manifest = paths.manifests / f"binary-{d1[:12]}.json"
    first = manifest.read_text()
    d2 = store.add_binary(b, "other", {}, paths)
    assert d1 == d2
    assert manifest.read_text() == first
    assert json.loads(first)["provenance"] == {"src": "x"}
    assert (paths.binaries / d1 / "GEF").read_bytes() == b.read_bytes()
    assert store.verify(None, paths).ok
    (paths.binaries / d1 / "GEF").chmod(0o755)
    (paths.binaries / d1 / "GEF").write_bytes(b"changed")
    assert not store.verify([f"binary-{d1[:12]}"], paths).ok


def test_absent_root_skips(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    p = StorePaths(
        tmp_path / "none" / "reference_store" / "captures",
        tmp_path / "none" / "reference_store" / "binaries",
        tmp_path / "manifests",
    )
    assert store.main(["verify"], p) == 77
    assert "skipped" in capsys.readouterr().out
