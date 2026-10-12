# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for ``harness.golden``: committed driver goldens are current; staleness is caught."""

from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path

import pytest

from harness import driver, golden
from harness.common import DRIVERS_DIR, HarnessError


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


def test_derived_golden_detects_changed_output_and_source(tmp_path: Path) -> None:
    source = next(
        p for p in sorted(golden.GOLDEN_DIR.iterdir()) if (p / golden.DERIVED_JSON).is_file()
    )
    path = tmp_path / source.name
    shutil.copytree(source, path)
    assert golden.check_golden(path) == []
    record = json.loads((path / golden.DERIVED_JSON).read_text(encoding="utf-8"))
    record["sources"][0]["sha256"] = "0" * 64
    (path / golden.DERIVED_JSON).write_text(json.dumps(record), encoding="utf-8")
    output = next(p for p in path.iterdir() if p.name != golden.DERIVED_JSON)
    output.write_bytes(output.read_bytes() + b"x")
    problems = golden.check_golden(path)
    assert any("capture file" in p and "changed" in p for p in problems)
    assert any("differs" in p and output.name in p for p in problems)


def _record_with(path: Path, **fields: object) -> None:
    """Rewrite a golden's ``driver.json`` with the given fields added or replaced."""
    record = json.loads((path / "driver.json").read_text(encoding="utf-8"))
    record.update(fields)
    (path / "driver.json").write_text(json.dumps(record), encoding="utf-8")


def test_work_file_changes_and_removals_are_stale(
    copied: tuple[Path, Path], tmp_path: Path
) -> None:
    path, drivers = copied
    work = tmp_path / "input.txt"
    work.write_bytes(b"hello\n")
    digest = hashlib.sha256(b"hello\n").hexdigest()
    _record_with(
        path, work_files=[{"name": "input.txt", "source": work.as_posix(), "sha256": digest}]
    )
    assert golden.check_golden(path, drivers) == []
    work.write_bytes(b"bye\n")
    assert golden.check_golden(path, drivers) == [
        f"{path.name}: work file input.txt changed: {work.as_posix()}"
    ]
    work.unlink()
    assert golden.check_golden(path, drivers) == [
        f"{path.name}: work file input.txt not found: {work.as_posix()}"
    ]


def test_absent_validation_work_file_is_skipped(copied: tuple[Path, Path]) -> None:
    path, drivers = copied
    source = "validation/m5-test-absent/input.txt"
    _record_with(path, work_files=[{"name": "input.txt", "source": source, "sha256": "0" * 64}])
    assert golden.check_golden(path, drivers) == []
    assert golden.skipped_work_files(path.parent) == [
        f"{path.name}: work file input.txt skipped, {source} is not in this checkout"
    ]


def test_driver_include_changes_and_removals_are_stale(copied: tuple[Path, Path]) -> None:
    path, drivers = copied
    shared = drivers / "m5_shared.bi"
    shared.write_text("' shared\n", encoding="utf-8")
    digest = hashlib.sha256(b"' shared\n").hexdigest()
    _record_with(path, driver_includes=[{"file": "m5_shared.bi", "sha256": digest}])
    assert golden.check_golden(path, drivers) == []
    shared.write_text("' edited\n", encoding="utf-8")
    assert golden.check_golden(path, drivers) == [
        f"{path.name}: driver include m5_shared.bi changed"
    ]
    shared.unlink()
    assert golden.check_golden(path, drivers) == [
        f"{path.name}: driver include m5_shared.bi not found"
    ]


def test_promote_passes_work_files_through(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    seen: dict[str, object] = {}
    work = tmp_path / "input.txt"
    work.write_bytes(b"hello\n")

    def fake_run(name: str, args: list[str] | None = None, **kwargs: object) -> driver.DriverRun:
        out_dir = kwargs["out_dir"]
        assert isinstance(out_dir, Path)
        out_dir.mkdir(parents=True)
        (out_dir / "input.txt").write_bytes(b"hello\n")  # the run's copy; promote removes it
        (out_dir / "stdout.txt").write_text("hello\n", encoding="utf-8")
        seen.update(name=name, args=args, work_files=kwargs["work_files"])
        return driver.DriverRun(out_dir, {}, 0)

    monkeypatch.setattr(driver, "run", fake_run)
    monkeypatch.setattr(golden, "BUILD_ROOT", tmp_path / "build")
    dest = golden.promote(
        "demo", ["7"], "m5-test", golden_dir=tmp_path / "goldens", work_files=[work]
    )
    assert seen == {"name": "demo", "args": ["7"], "work_files": [work]}
    assert dest == tmp_path / "goldens" / "m5-test"
    assert sorted(p.name for p in dest.iterdir()) == ["stdout.txt"]


def test_promote_refuses_a_failed_driver(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    def failing_run(*_args: object, **kwargs: object) -> driver.DriverRun:
        out_dir = kwargs["out_dir"]
        assert isinstance(out_dir, Path)
        return driver.DriverRun(out_dir, {}, 1)

    monkeypatch.setattr(driver, "run", failing_run)
    monkeypatch.setattr(golden, "BUILD_ROOT", tmp_path / "build")
    with pytest.raises(HarnessError, match="driver demo exited with 1"):
        golden.promote("demo", [], "m5-test", golden_dir=tmp_path / "goldens")
    assert not (tmp_path / "goldens").exists()


def test_promote_cli_passes_work_files(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    seen: dict[str, object] = {}

    def fake_promote(driver_name: str, args: list[str], name: str, **kwargs: object) -> Path:
        seen.update(driver=driver_name, args=args, name=name, work_files=kwargs["work_files"])
        return tmp_path / "goldens" / name

    monkeypatch.setattr(golden, "promote", fake_promote)
    argv = ["promote", "demo", "--name", "m5-test", "--work-file", "a.txt", "--", "7"]
    assert golden.main(argv) == 0
    assert seen == {
        "driver": "demo",
        "args": ["7"],
        "name": "m5-test",
        "work_files": [Path("a.txt")],
    }


def test_promote_cli_reports_driver_failure(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    def failing_run(*_args: object, **kwargs: object) -> driver.DriverRun:
        out_dir = kwargs["out_dir"]
        assert isinstance(out_dir, Path)
        return driver.DriverRun(out_dir, {}, 1)

    monkeypatch.setattr(driver, "run", failing_run)
    monkeypatch.setattr(golden, "BUILD_ROOT", tmp_path / "build")
    assert golden.main(["promote", "demo", "--name", "m5-test"]) == 2
    assert "driver demo exited with 1" in capsys.readouterr().err
