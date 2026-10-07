# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for tools.toolchain.manifest_validation on a synthetic validation tree."""

from __future__ import annotations

import hashlib
import shutil
import subprocess
from pathlib import Path

import pytest

from tools.toolchain import manifest_validation as mv

SYNTHETIC_FILES = {
    "reference/gefy_nfy": "nfy sequence\n",
    "reference/gefy_sfy": "sfy sequence\n",
    "reference/gefy_nfy_ENDF/GEFY_92_235_n.dat": "tape 1\n",
    "reference/gefy_nfy_ENDF/GEFY_94_239_n.dat": "tape 2\n",
    "reference/gefy_sfy_ENDF/GEFY_98_252_s.dat": "tape 3\n",
    "test_run/gef_reference": "binary\n",
    "test_run/run.log": "log\n",
    "test_run/ENDF/GEFY_86_214_n.dat": "endf\n",
    "test_run/out/GEF_86_215_n.dat": "out\n",
    "test_run/dmp/Z86_A215_n_E1MeV/list.dmp": "dump\n",
    "test_run/tmp/CUMU1.dat": "tmp\n",
    # Present but not covered by any manifest:
    "test_run/ctl/thread.ctl": "stale\n",
    "test_run/in/gefy_nfy.in": "input\n",
    "test_run/file.in": "file\n",
}
UNCOVERED = {"test_run/ctl/thread.ctl", "test_run/in/gefy_nfy.in", "test_run/file.in"}


@pytest.fixture
def tree(tmp_path: Path) -> tuple[Path, Path]:
    validation = tmp_path / "validation"
    for rel, content in SYNTHETIC_FILES.items():
        path = validation / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    return validation, tmp_path / "manifests"


def _run(command: str, validation: Path, manifests: Path) -> int:
    return mv.main([command, "--validation-dir", str(validation), "--manifest-dir", str(manifests)])


def test_write_format(tree: tuple[Path, Path]) -> None:
    validation, manifests = tree
    assert _run("write", validation, manifests) == mv.EXIT_OK
    reference = (manifests / mv.REFERENCE_SPEC.filename).read_text(encoding="utf-8")
    test_run = (manifests / mv.TEST_RUN_SPEC.filename).read_text(encoding="utf-8")
    assert "NOT a clean run" in test_run
    assert "ctl/" in test_run
    assert "lines 1-857" in test_run

    body = [ln for ln in reference.splitlines() if not ln.startswith("#")]
    paths = [ln.split("  ", 1)[1] for ln in body]
    assert paths == sorted(rel for rel in SYNTHETIC_FILES if rel.startswith("reference/"))
    digest = hashlib.sha256(b"tape 1\n").hexdigest()
    assert f"{digest}  reference/gefy_nfy_ENDF/GEFY_92_235_n.dat" in body

    entries = mv.parse_manifest(test_run, Path("test_run.sha256"))
    expected = {rel for rel in SYNTHETIC_FILES if rel.startswith("test_run/")} - UNCOVERED
    assert set(entries) == expected


def test_roundtrip_detects_missing_changed_extra(
    tree: tuple[Path, Path], capsys: pytest.CaptureFixture[str]
) -> None:
    validation, manifests = tree
    assert _run("write", validation, manifests) == mv.EXIT_OK
    assert _run("verify", validation, manifests) == mv.EXIT_OK

    # Changes outside the covered entries are ignored.
    (validation / "test_run/ctl/thread.ctl").write_text("changed\n", encoding="utf-8")
    (validation / "test_run/ctl/done.ctl").write_text("new\n", encoding="utf-8")
    assert _run("verify", validation, manifests) == mv.EXIT_OK

    (validation / "reference/gefy_sfy_ENDF/GEFY_98_252_s.dat").unlink()
    (validation / "test_run/out/GEF_86_215_n.dat").write_text("tampered\n", encoding="utf-8")
    (validation / "test_run/dmp/Z86_A215_n_E1MeV/extra.dmp").write_text("x\n", encoding="utf-8")
    capsys.readouterr()
    assert _run("verify", validation, manifests) == mv.EXIT_FAILED
    out = capsys.readouterr().out
    assert "missing reference/gefy_sfy_ENDF/GEFY_98_252_s.dat" in out
    assert "changed test_run/out/GEF_86_215_n.dat" in out
    assert "extra   test_run/dmp/Z86_A215_n_E1MeV/extra.dmp" in out
    assert "1 missing, 0 changed, 0 extra" in out
    assert "0 missing, 1 changed, 1 extra" in out


def test_missing_covered_single_file_is_reported(
    tree: tuple[Path, Path], capsys: pytest.CaptureFixture[str]
) -> None:
    validation, manifests = tree
    assert _run("write", validation, manifests) == mv.EXIT_OK
    (validation / "test_run/run.log").unlink()
    capsys.readouterr()
    assert _run("verify", validation, manifests) == mv.EXIT_FAILED
    assert "missing test_run/run.log" in capsys.readouterr().out


def test_write_refuses_incomplete_tree(
    tree: tuple[Path, Path], capsys: pytest.CaptureFixture[str]
) -> None:
    validation, manifests = tree
    shutil.rmtree(validation / "test_run/tmp")
    assert _run("write", validation, manifests) == mv.EXIT_FAILED
    assert "test_run/tmp" in capsys.readouterr().err


def test_absent_validation_dir_is_skipped(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    for command in ("verify", "write"):
        assert _run(command, tmp_path / "absent", tmp_path / "m") == mv.EXIT_SKIPPED
        assert "skipped" in capsys.readouterr().out
    assert not (tmp_path / "m").exists()


def test_missing_manifest_is_an_error(
    tree: tuple[Path, Path], capsys: pytest.CaptureFixture[str]
) -> None:
    validation, manifests = tree
    assert _run("verify", validation, manifests) == mv.EXIT_FAILED
    assert "manifest_validation write" in capsys.readouterr().err


def test_malformed_manifest_is_an_error(
    tree: tuple[Path, Path], capsys: pytest.CaptureFixture[str]
) -> None:
    validation, manifests = tree
    assert _run("write", validation, manifests) == mv.EXIT_OK
    path = manifests / mv.REFERENCE_SPEC.filename
    path.write_text(path.read_text(encoding="utf-8") + "garbage line\n", encoding="utf-8")
    assert _run("verify", validation, manifests) == mv.EXIT_FAILED
    assert "malformed line" in capsys.readouterr().err


@pytest.mark.skipif(shutil.which("sha256sum") is None, reason="sha256sum not installed")
def test_gnu_sha256sum_accepts_manifests(tree: tuple[Path, Path]) -> None:
    validation, manifests = tree
    assert _run("write", validation, manifests) == mv.EXIT_OK
    for spec in mv.SPECS:
        proc = subprocess.run(
            ["sha256sum", "-c", "--strict", "--quiet", str(manifests / spec.filename)],
            cwd=validation,
            capture_output=True,
            text=True,
            check=False,
        )
        assert proc.returncode == 0, proc.stdout + proc.stderr
