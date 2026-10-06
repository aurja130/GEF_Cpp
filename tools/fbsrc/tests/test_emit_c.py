# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aurora Jahan
# See LICENSE.txt in the repository root for the full license text.
"""emit_c: emission layout, reuse, patch directories and determinism."""

from __future__ import annotations

import difflib
import json
from pathlib import Path

import pytest

from tools.fbsrc.common import FBSRC_BUILD_DIR, FbsrcError, read_source_lines, sha256_file
from tools.fbsrc.emit_c import (
    MANIFEST_NAME,
    Emission,
    emission_key,
    emit,
    normalised_sha256,
    patch_dir_sha256,
    patch_files,
    submodule_revision,
)
from tools.fbsrc.fbline import lookup
from tools.toolchain.fbc import GEF_SOURCE_DIR, REQUIRED_FBC_VERSION

LINE_8392 = "E_intr_heavy = E_intr_heavy - I_A_heavy_sci/I_A_sci * (Delta_E_Q)"
PATCHED_8392 = "E_intr_heavy = E_intr_heavy - CSng(I_A_heavy_sci/I_A_sci) * (Delta_E_Q)"


def _write_patch(patch_dir: Path, name: str, line: int, old: str, new: str) -> None:
    """A unified diff (a/ b/ prefixes) that replaces ``old`` by ``new`` on GEF.bas ``line``."""
    before = read_source_lines(GEF_SOURCE_DIR / "GEF.bas")
    after = list(before)
    assert old in after[line - 1]
    after[line - 1] = after[line - 1].replace(old, new)
    diff = difflib.unified_diff(
        [f"{t}\n" for t in before], [f"{t}\n" for t in after], "a/GEF.bas", "b/GEF.bas"
    )
    patch_dir.mkdir(parents=True, exist_ok=True)
    (patch_dir / name).write_text("".join(diff), encoding="utf-8")


def test_patch_dir_rules(tmp_path: Path) -> None:
    with pytest.raises(FbsrcError):
        patch_files(tmp_path / "missing")
    with pytest.raises(FbsrcError):
        patch_files(tmp_path)  # empty
    (tmp_path / "b.patch").write_text("x", encoding="utf-8")
    (tmp_path / "a.diff").write_text("y", encoding="utf-8")
    assert [p.name for p in patch_files(tmp_path)] == ["a.diff", "b.patch"]
    first = patch_dir_sha256(patch_files(tmp_path))
    (tmp_path / "b.patch").write_text("z", encoding="utf-8")
    assert patch_dir_sha256(patch_files(tmp_path)) != first
    (tmp_path / "notes.txt").write_text("", encoding="utf-8")
    with pytest.raises(FbsrcError):
        patch_files(tmp_path)


def test_emission_key() -> None:
    assert emission_key("ba9f0aa", None) == "ba9f0aa"
    assert emission_key("ba9f0aa", "0123456789abcdef" * 4) == "ba9f0aa-p0123456789ab"


@pytest.mark.fbc
def test_manifest_and_reuse(emission: Emission) -> None:
    rev = submodule_revision()
    m = emission.manifest
    assert emission.key == rev.short == m.submodule_revision
    assert emission.root.name == rev.short
    assert m.submodule_commit == rev.commit
    assert m.fbc_version == REQUIRED_FBC_VERSION
    assert m.command[1:] == ["-gen", "gcc", "-R", "-g", "-c", "GEF.bas"]
    assert m.patch_dir is None and m.patch_dir_sha256 is None
    assert sha256_file(emission.gef_c) == m.gef_c_sha256
    on_disk = json.loads((emission.root / MANIFEST_NAME).read_text(encoding="utf-8"))
    assert on_disk["gef_c_sha256"] == m.gef_c_sha256
    again = emit()
    assert again.reused and again.manifest == m


@pytest.mark.fbc
@pytest.mark.slow
def test_emission_is_deterministic(emission: Emission) -> None:
    before = emission.manifest
    fresh = emit(force=True)
    assert not fresh.reused
    assert fresh.manifest.gef_c_sha256 == before.gef_c_sha256
    assert fresh.manifest.gef_c_sha256_normalised == before.gef_c_sha256_normalised
    assert fresh.manifest.fbc_wall_time_s < 60


@pytest.mark.fbc
@pytest.mark.slow
def test_patched_emission(emission: Emission, tmp_path: Path) -> None:
    patch_dir = tmp_path / "patches"
    _write_patch(patch_dir, "0001-csng.patch", 8392, LINE_8392, PATCHED_8392)
    patched = emit(patch_dir)
    m = patched.manifest
    assert m.patch_dir_sha256 is not None
    assert m.patch_dir_sha256 == patch_dir_sha256(patch_files(patch_dir))
    assert patched.key == f"{emission.key}-p{m.patch_dir_sha256[:12]}"
    assert m.patches == ["0001-csng.patch"]
    assert PATCHED_8392 in read_source_lines(patched.src_dir / "GEF.bas")[8391]
    assert m.gef_c_sha256_normalised != emission.manifest.gef_c_sha256_normalised
    assert normalised_sha256(patched.gef_c, patched.src_dir) == m.gef_c_sha256_normalised
    # CSng narrows the quotient before the subtraction, which is now done in float.
    result = lookup("GEF.bas", 8392, patch_dir=patch_dir)
    assert PATCHED_8392 in result.basic[0][1]
    (stmt,) = [s.text.strip() for s in result.statements()]
    assert stmt.startswith("E_INTR_HEAVY$ = E_INTR_HEAVY$ - ((float)((double)I_A_HEAVY_SCI$")
    # the unpatched emission is untouched
    assert LINE_8392 in lookup("GEF.bas", 8392).basic[0][1]


@pytest.mark.fbc
def test_failing_patch_leaves_no_emission(tmp_path: Path) -> None:
    patch_dir = tmp_path / "bad"
    _write_patch(patch_dir, "0001.patch", 8392, LINE_8392, PATCHED_8392)
    text = (patch_dir / "0001.patch").read_text(encoding="utf-8")
    (patch_dir / "0001.patch").write_text(text.replace(LINE_8392, "no such line"), "utf-8")
    key = emission_key(submodule_revision().short, patch_dir_sha256(patch_files(patch_dir)))
    with pytest.raises(FbsrcError, match="does not apply"):
        emit(patch_dir)
    assert not (FBSRC_BUILD_DIR / key).exists()
