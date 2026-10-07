# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for harness.run using a fake binary (a shell script)."""

from __future__ import annotations

import json
import os
import stat
from pathlib import Path

import pytest

from harness.common import HarnessError, sha256_file
from harness.run import build_environment, main, prepare_run_dir, run

FAKE = """#!/bin/sh
echo "seed=$GEF_SEED reseed=${GEF_RESEED-unset} steps=${GEF_TRACE_STEPS-unset}"
echo "cwd=$(pwd)"
echo "file.in=$(cat file.in | tr '\\n' '|')"
if read -r line; then echo "stdin-not-empty"; else echo "stdin-eof"; fi
echo "to stderr" >&2
mkdir -p out
echo result > out/result.txt
exit ${FAKE_EXIT:-0}
"""


@pytest.fixture
def fake_binary(tmp_path: Path) -> Path:
    path = tmp_path / "fake_gef"
    path.write_text(FAKE, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)
    return path


@pytest.fixture
def input_file(tmp_path: Path) -> Path:
    path = tmp_path / "seq.in"
    path.write_text(' 10\n1\nOptions(ENDF)\n 86, 215, "EN"\n', encoding="utf-8")
    return path


def test_run_creates_layout_and_manifest(
    tmp_path: Path, fake_binary: Path, input_file: Path
) -> None:
    out = tmp_path / "run1"
    result = run(
        fake_binary,
        input_file,
        out,
        seed=4294967295,
        reseed=True,
        extra_env={"GEF_EXTRA": "1"},
        scope={"steps": "1,3-5", "events": "2"},
    )
    assert result.exit_code == 0
    stdout = (out / "stdout.log").read_text(encoding="utf-8")
    assert "seed=4294967295 reseed=1 steps=1,3-5" in stdout
    assert f"cwd={out.resolve() / 'work'}" in stdout
    assert 'file.in="in/seq.in"|END|' in stdout
    assert "stdin-eof" in stdout
    assert (out / "stderr.log").read_text(encoding="utf-8") == "to stderr\n"
    assert (out / "work" / "out" / "result.txt").read_text(encoding="utf-8") == "result\n"
    assert (out / "work" / "in" / "seq.in").read_bytes() == input_file.read_bytes()
    assert (out / "work" / "file.in").read_bytes() == b'"in/seq.in"\nEND\n'
    record = json.loads((out / "run.json").read_text(encoding="utf-8"))
    assert record == result.record
    assert record["mode"] == "reseed"
    assert record["seed"] == 4294967295
    assert record["exit_code"] == 0
    assert record["binary"] == {
        "path": str(fake_binary.resolve()),
        "sha256": sha256_file(fake_binary),
    }
    assert record["input"] == {"name": "seq.in", "sha256": sha256_file(input_file)}
    assert record["env_set"] == {
        "GEF_SEED": "4294967295",
        "GEF_RESEED": "1",
        "GEF_TRACE_STEPS": "1,3-5",
        "GEF_TRACE_EVENTS": "2",
        "GEF_EXTRA": "1",
    }
    assert record["start_utc"] <= record["end_utc"]
    assert record["wall_time_s"] >= 0


def test_run_refuses_existing_output_dir(
    tmp_path: Path, fake_binary: Path, input_file: Path
) -> None:
    out = tmp_path / "exists"
    out.mkdir()
    with pytest.raises(HarnessError, match="already exists"):
        run(fake_binary, input_file, out, seed=1)
    assert list(out.iterdir()) == []


def test_run_nonzero_exit_writes_manifest_then_raises(
    tmp_path: Path, fake_binary: Path, input_file: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv("FAKE_EXIT", "3")
    out = tmp_path / "bad"
    with pytest.raises(HarnessError, match="status 3"):
        run(fake_binary, input_file, out, seed=1)
    assert json.loads((out / "run.json").read_text(encoding="utf-8"))["exit_code"] == 3


def test_run_normal_mode_sets_no_reseed(
    tmp_path: Path, fake_binary: Path, input_file: Path
) -> None:
    out = tmp_path / "normal"
    run(fake_binary, input_file, out, seed=0)
    assert "reseed=unset steps=unset" in (out / "stdout.log").read_text(encoding="utf-8")
    assert json.loads((out / "run.json").read_text(encoding="utf-8"))["mode"] == "normal"


def test_run_rejects_bad_inputs(tmp_path: Path, fake_binary: Path, input_file: Path) -> None:
    with pytest.raises(HarnessError, match="outside"):
        run(fake_binary, input_file, tmp_path / "a", seed=2**32)
    with pytest.raises(HarnessError, match="unknown scope key"):
        run(fake_binary, input_file, tmp_path / "b", seed=1, scope={"bins": "1"})
    with pytest.raises(HarnessError, match="does not exist"):
        run(fake_binary, tmp_path / "missing.in", tmp_path / "c", seed=1)
    with pytest.raises(HarnessError, match="not an executable"):
        run(tmp_path / "nothing", input_file, tmp_path / "d", seed=1)
    assert not (tmp_path / "a").exists()


def test_prepare_run_dir_layout(tmp_path: Path, input_file: Path) -> None:
    work = prepare_run_dir(tmp_path / "x", input_file)
    assert work == (tmp_path / "x" / "work").resolve()
    assert sorted(p.name for p in work.iterdir()) == ["file.in", "in"]


def test_build_environment() -> None:
    assert build_environment(7) == {"GEF_SEED": "7"}
    assert build_environment(None, extra_env={"A": "b"}) == {"A": "b"}


def test_cli(
    tmp_path: Path, fake_binary: Path, input_file: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    out = tmp_path / "cli"
    code = main(
        [
            "--binary",
            str(fake_binary),
            "--input",
            str(input_file),
            "--seed",
            "5",
            "--out",
            str(out),
            "--scope",
            "passes=1",
            "--env",
            "GEF_X=y",
        ]
    )
    assert code == 0
    assert "run complete" in capsys.readouterr().out
    assert json.loads((out / "run.json").read_text(encoding="utf-8"))["env_set"]["GEF_X"] == "y"
    assert (
        main(
            [
                "--binary",
                str(fake_binary),
                "--input",
                str(input_file),
                "--seed",
                "5",
                "--out",
                str(out),
            ]
        )
        == 1
    )
    assert "already exists" in capsys.readouterr().err
    assert os.environ.get("GEF_SEED") is None
