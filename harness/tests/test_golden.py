# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for ``harness.golden``: committed driver goldens are current; staleness is caught."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

import pytest

from harness import golden
from harness.common import DRIVERS_DIR


def test_committed_goldens_are_current() -> None:
    assert golden.check() == []


@pytest.fixture
def copied(tmp_path: Path) -> tuple[Path, Path]:
    """A copy of one committed golden and of the drivers directory."""
    source = next(p for p in sorted(golden.GOLDEN_DIR.iterdir()) if p.is_dir())
    golden_dir = tmp_path / "golden"
    shutil.copytree(source, golden_dir / source.name)
    drivers = tmp_path / "drivers"
    shutil.copytree(DRIVERS_DIR, drivers)
    return golden_dir / source.name, drivers


def test_changed_driver_source_is_stale(copied: tuple[Path, Path]) -> None:
    path, drivers = copied
    record = json.loads((path / "driver.json").read_text(encoding="utf-8"))
    with (drivers / f"{record['driver']}.bas").open("a", encoding="latin-1") as f:
        f.write("' edit\n")
    assert any("changed" in p for p in golden.check_golden(path, drivers))


def test_edited_missing_and_extra_outputs_are_stale(copied: tuple[Path, Path]) -> None:
    path, drivers = copied
    outputs = sorted(p for p in path.iterdir() if p.name != "driver.json")
    outputs[0].write_bytes(outputs[0].read_bytes() + b"x")
    outputs[1].unlink()
    (path / "extra.txt").write_text("", encoding="utf-8")
    problems = golden.check_golden(path, drivers)
    assert any("differs" in p and outputs[0].name in p for p in problems)
    assert any("missing" in p and outputs[1].name in p for p in problems)
    assert any("not recorded" in p and "extra.txt" in p for p in problems)
