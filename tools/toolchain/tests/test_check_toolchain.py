# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aurora Jahan
# See LICENSE.txt in the repository root for the full license text.
"""Tests for tools.toolchain.check_toolchain."""

from __future__ import annotations

import hashlib
import stat
from pathlib import Path

import pytest

from tools.toolchain import check_toolchain as ct
from tools.toolchain.fbc import FBC_ENV_VAR, REQUIRED_FBC_VERSION, FbcError, resolve_fbc

# First lines of `--version` as printed by the tools on the reference machine.
SAMPLE_OUTPUTS = {
    "gcc": ("gcc (GCC) 16.2.1 20260819 (Red Hat 16.2.1-2)\nCopyright (C) 2026 FSF\n", "16.2.1"),
    "clang": ("clang version 22.1.8 (Fedora 22.1.8-4.fc44)\nTarget: x86_64\n", "22.1.8"),
    "cmake": ("cmake version 4.3.0\n\nCMake suite maintained by Kitware\n", "4.3.0"),
    "ninja": ("1.13.2\n", "1.13.2"),
    "python": ("Python 3.14.7\n", "3.14.7"),
    "ruff": ("ruff 0.16.6\n", "0.16.6"),
    "basedpyright": ("basedpyright 1.39.10\nbased on pyright 1.1.412\n", "1.39.10"),
    "pytest": ("pytest 9.1.1\n", "9.1.1"),
    "clang-tidy": (
        "LLVM (http://llvm.org/):\n  LLVM version 22.1.8\n  Optimized build.\n",
        "22.1.8",
    ),
    "clang-format": ("clang-format version 22.1.8 (Fedora 22.1.8-4.fc44)\n", "22.1.8"),
    "ctags": ("Universal Ctags 6.2.1, Copyright (C) 2015-2025 Universal Ctags Team\n", "6.2.1"),
}


def _spec(name: str) -> ct.ToolSpec:
    return next(spec for spec in ct.TOOL_SPECS if spec.name == name)


def _fake_executable(path: Path, script: str) -> Path:
    path.write_text(script, encoding="ascii")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)
    return path


def test_parse_version() -> None:
    assert ct.parse_version("16.2.1") == (16, 2, 1)
    assert ct.parse_version("4") == (4,)
    with pytest.raises(ValueError, match="not a numeric version"):
        ct.parse_version("1.10.1rc1")


@pytest.mark.parametrize(
    ("version", "minimum", "expected"),
    [
        ((16, 2, 1), (16,), True),
        ((15, 9, 9), (16,), False),
        ((4, 0), (4, 0), True),
        ((4,), (4, 0), True),
        ((1, 38, 9), (1, 39), False),
        ((1, 39, 10), (1, 39), True),
        ((0, 16, 6), (0, 16), True),
        ((0, 9), (0, 16), False),
    ],
)
def test_version_at_least(
    version: tuple[int, ...], minimum: tuple[int, ...], expected: bool
) -> None:
    assert ct.version_at_least(version, minimum) is expected


def test_every_tool_has_a_sample() -> None:
    assert {spec.name for spec in ct.TOOL_SPECS} == set(SAMPLE_OUTPUTS)


@pytest.mark.parametrize("name", sorted(SAMPLE_OUTPUTS))
def test_version_output_parsed(name: str) -> None:
    output, version = SAMPLE_OUTPUTS[name]
    result = ct.evaluate_version_output(_spec(name), "/usr/bin/x", output)
    assert result.status is ct.Status.OK
    assert result.version == version


def test_too_old_version_fails_with_hint() -> None:
    result = ct.evaluate_version_output(_spec("cmake"), "/usr/bin/cmake", "cmake version 3.31.6\n")
    assert result.status is ct.Status.FAIL
    assert "3.31.6 is older than the required >= 4.0" in result.detail
    assert "install CMake" in result.detail


def test_exuberant_ctags_is_rejected() -> None:
    output = "Exuberant Ctags 5.8, Copyright (C) 1996-2009 Darren Hiebert\n"
    result = ct.evaluate_version_output(_spec("ctags"), "/usr/bin/ctags", output)
    assert result.status is ct.Status.FAIL
    assert "Universal Ctags" in result.detail
    assert "Exuberant Ctags 5.8" in result.detail


def test_missing_tool_fails() -> None:
    spec = ct.ToolSpec("nosuch", "gef-no-such-tool-xyz", _spec("ruff").version_re, (1,), "hint")
    result = ct.check_tool(spec)
    assert result.status is ct.Status.FAIL
    assert "not found on PATH" in result.detail


def test_fbc_missing_file(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    missing = tmp_path / "no" / "fbc"
    monkeypatch.setenv(FBC_ENV_VAR, str(missing))
    result, fbc = ct.check_fbc()
    assert fbc is None
    assert result.status is ct.Status.FAIL
    assert f"fbc not found at {missing}" in result.detail
    assert f"set {FBC_ENV_VAR}" in result.detail


def test_fbc_wrong_version(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    fake = _fake_executable(
        tmp_path / "fbc",
        "#!/bin/sh\n"
        "echo 'FreeBASIC Compiler - Version 1.09.0 (2021-12-31), built for linux-x86_64 (64bit)'\n",
    )
    monkeypatch.setenv(FBC_ENV_VAR, str(fake))
    result, fbc = ct.check_fbc()
    assert fbc is None
    assert result.status is ct.Status.FAIL
    assert f"reports version 1.09.0, but {REQUIRED_FBC_VERSION} is required" in result.detail
    assert f"set {FBC_ENV_VAR}" in result.detail


def test_fbc_not_freebasic(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    fake = _fake_executable(tmp_path / "fbc", "#!/bin/sh\necho 'hello'\n")
    monkeypatch.setenv(FBC_ENV_VAR, str(fake))
    result, _ = ct.check_fbc()
    assert result.status is ct.Status.FAIL
    assert "did not report a FreeBASIC version" in result.detail


def test_fbc_not_executable(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    plain = tmp_path / "fbc"
    plain.write_text("not a program\n", encoding="ascii")
    monkeypatch.setenv(FBC_ENV_VAR, str(plain))
    result, _ = ct.check_fbc()
    assert result.status is ct.Status.FAIL
    assert "is not executable" in result.detail


def test_main_fails_for_missing_fbc(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    monkeypatch.setenv(FBC_ENV_VAR, str(tmp_path / "missing-fbc"))
    manifest = tmp_path / "toolchain.txt"
    assert ct.main(["--write-manifest", "--manifest", str(manifest)]) == ct.EXIT_FAILED
    out = capsys.readouterr().out
    assert "FAIL  fbc" in out
    assert "fbc not found at" in out
    assert "toolchain check FAILED: " in out
    assert not manifest.exists()


def test_tarball_absent(tmp_path: Path) -> None:
    result = ct.check_fbc_tarball(tmp_path / "missing.tar.gz")
    assert result.status is ct.Status.INFO
    assert result.detail == "tarball not found, hash not checked"


def test_tarball_hash(tmp_path: Path) -> None:
    tarball = tmp_path / "fbc.tar.gz"
    tarball.write_bytes(b"not the real tarball")
    digest = hashlib.sha256(b"not the real tarball").hexdigest()
    assert ct.check_fbc_tarball(tarball, digest).status is ct.Status.OK
    wrong = ct.check_fbc_tarball(tarball)
    assert wrong.status is ct.Status.FAIL
    assert "does not match the pinned" in wrong.detail


def test_compare_manifest(tmp_path: Path) -> None:
    manifest = tmp_path / "toolchain.txt"
    missing, _ = ct.compare_manifest(manifest, "a\nb\n")
    assert missing.status is ct.Status.FAIL
    assert "--write-manifest" in missing.detail
    manifest.write_text("a\nb\n", encoding="utf-8")
    same, diff = ct.compare_manifest(manifest, "a\nb\n")
    assert same.status is ct.Status.OK
    assert diff == []
    stale, diff = ct.compare_manifest(manifest, "a\nc\n")
    assert stale.status is ct.Status.FAIL
    assert "out of date" in stale.detail
    assert "rerun with --write-manifest" in stale.detail
    assert diff == ["-b", "+c"]


def test_display_path() -> None:
    assert ct.display_path(Path.home() / "x" / "y") == "~/x/y"
    assert (
        ct.display_path(ct.REPO_ROOT / "manifests" / "toolchain.txt") == "manifests/toolchain.txt"
    )
    assert ct.display_path("/usr/bin/gcc") == "/usr/bin/gcc"


@pytest.fixture
def real_fbc() -> Path:
    try:
        return resolve_fbc()
    except FbcError as exc:
        pytest.skip(f"pinned fbc unavailable: {exc}")


@pytest.mark.fbc
def test_backend_capture_is_deterministic(real_fbc: Path) -> None:
    first = ct.capture_fbc_backend(real_fbc)
    second = ct.capture_fbc_backend(real_fbc)
    assert first == second
    assert first.version_line.startswith(f"FreeBASIC Compiler - Version {REQUIRED_FBC_VERSION}")
    assert first.backend == "gcc"
    assert first.compile_c.startswith("gcc ")
    for flag in ("-march=x86-64", "-O0", "-frounding-math", "-fno-math-errno"):
        assert flag in first.compile_c.split()
    assert first.assemble.startswith("as ")
    assert first.link.startswith("ld ")
    assert first.gcc_version.startswith("gcc ")
    text = "\n".join([first.compile_c, first.assemble, first.link, *first.filtered_stderr])
    assert "fbc_capture_" not in text
    assert str(Path.home()) not in text
    assert all("libtinfo" in ln or "ospeed" in ln for ln in first.filtered_stderr)


@pytest.mark.fbc
def test_manifest_write_then_check(
    real_fbc: Path, tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    del real_fbc  # resolved again inside the check; the fixture only skips when absent
    manifest = tmp_path / "toolchain.txt"
    assert ct.main(["--write-manifest", "--manifest", str(manifest)]) == ct.EXIT_OK
    content = manifest.read_text(encoding="utf-8")
    assert "compile C:    gcc " in content
    assert "[filtered fbc stderr]" in content
    assert ct.main(["--manifest", str(manifest)]) == ct.EXIT_OK
    assert manifest.read_text(encoding="utf-8") == content

    manifest.write_text(content.replace("backend:      gcc", "backend:      llvm"), "utf-8")
    capsys.readouterr()
    assert ct.main(["--manifest", str(manifest)]) == ct.EXIT_FAILED
    out = capsys.readouterr().out
    assert "FAIL  manifest" in out
    assert "rerun with --write-manifest" in out
    assert "-backend:      llvm" in out
