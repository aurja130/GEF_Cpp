# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for harness.build: patch sets, build ids, fbc options, ELF sections, seed.patch."""

from __future__ import annotations

import shutil
import struct
import subprocess
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import pytest

from harness import build as build_mod
from harness.build import (
    BuildResult,
    compare_sections,
    compute_build_id,
    materialize_patch_dir,
    read_patchset,
    resolve_binary,
    validate_defines,
    validate_fbc_options,
)
from harness.common import GEF_SOURCE_DIR, PATCHES_DIR, PATCHSETS_DIR, HarnessError


def _dirs(tmp_path: Path, sets: dict[str, str], patches: tuple[str, ...]) -> tuple[Path, Path]:
    patchsets, patch_dir = tmp_path / "sets", tmp_path / "patches"
    patchsets.mkdir()
    patch_dir.mkdir()
    for name, body in sets.items():
        (patchsets / f"{name}.txt").write_text(body, encoding="utf-8")
    for name in patches:
        (patch_dir / f"{name}.patch").write_text(f"patch {name}\n", encoding="utf-8")
    return patchsets, patch_dir


def test_read_patchset_order_comments_and_blank_lines(tmp_path: Path) -> None:
    sets, patches = _dirs(
        tmp_path,
        {"s": "# comment\nseed\n\nscope  # trailing\nprobes\n", "none": "# empty\n"},
        ("seed", "scope", "probes"),
    )
    assert [p.stem for p in read_patchset("s", sets, patches)] == ["seed", "scope", "probes"]
    assert read_patchset("none", sets, patches) == []


@pytest.mark.parametrize(
    ("body", "message"),
    [
        ("scope\nseed\n", "canonical order"),
        ("seed\nseed\n", "twice"),
        ("bogus\n", "unknown patch"),
        ("probes\n", "does not exist"),
    ],
)
def test_read_patchset_rejects_bad_sets(tmp_path: Path, body: str, message: str) -> None:
    sets, patches = _dirs(tmp_path, {"bad": body}, ("seed", "scope"))
    with pytest.raises(HarnessError, match=message):
        read_patchset("bad", sets, patches)


def test_read_patchset_unknown_set_and_bad_name(tmp_path: Path) -> None:
    sets, patches = _dirs(tmp_path, {}, ())
    with pytest.raises(HarnessError, match="not found"):
        read_patchset("missing", sets, patches)
    with pytest.raises(HarnessError, match="invalid patch set name"):
        read_patchset("../x", sets, patches)


def test_materialize_patch_dir_numbers_and_recreates(tmp_path: Path) -> None:
    sets, patches = _dirs(tmp_path, {"s": "seed\nscope\n"}, ("seed", "scope"))
    out = tmp_path / "out"
    target = materialize_patch_dir("s", out, sets, patches)
    assert target == out / "s"
    assert sorted(p.name for p in target.iterdir()) == ["01-seed.patch", "02-scope.patch"]
    assert (target / "02-scope.patch").read_text(encoding="utf-8") == "patch scope\n"
    (target / "stale.patch").write_text("x", encoding="utf-8")
    materialize_patch_dir("s", out, sets, patches)
    assert not (target / "stale.patch").exists()


def test_build_id_is_stable_and_sensitive() -> None:
    args = ("seed", [("seed", "a" * 64)], ["GEF_PROBES"], "c" * 40, "1.10.1", 1000)
    base = compute_build_id(*args)
    assert base == compute_build_id(*args)
    assert base.startswith("seed-")
    assert len(base) == len("seed-") + 12
    # Define order and duplicates do not matter; everything else does.
    assert compute_build_id(
        "seed", [("seed", "a" * 64)], ["B", "A", "A"], "c" * 40, "1.10.1", 1000
    ) == (compute_build_id("seed", [("seed", "a" * 64)], ["A", "B"], "c" * 40, "1.10.1", 1000))
    no_defines: list[str] = []
    variants = [
        ("seed", [("seed", "b" * 64)], ["GEF_PROBES"], "c" * 40, "1.10.1", 1000),
        ("seed", [("seed", "a" * 64)], no_defines, "c" * 40, "1.10.1", 1000),
        ("seed", [("seed", "a" * 64)], ["GEF_PROBES"], "d" * 40, "1.10.1", 1000),
        ("seed", [("seed", "a" * 64)], ["GEF_PROBES"], "c" * 40, "1.10.2", 1000),
        ("seed", [("seed", "a" * 64)], ["GEF_PROBES"], "c" * 40, "1.10.1", 1001),
    ]
    assert all(compute_build_id(*v) != base for v in variants)


def test_validate_defines() -> None:
    assert validate_defines(["B", "A=1", "B"]) == ["A=1", "B"]
    with pytest.raises(HarnessError, match="invalid --define"):
        validate_defines(["bad name"])


def test_resolve_binary(tmp_path: Path) -> None:
    (tmp_path / "seed-abc").mkdir()
    binary = tmp_path / "seed-abc" / "GEF"
    binary.write_bytes(b"x")
    assert resolve_binary(str(binary), tmp_path) == binary.resolve()
    assert resolve_binary("seed-abc", tmp_path) == binary.resolve()
    with pytest.raises(HarnessError, match="neither"):
        resolve_binary("nope", tmp_path)


def test_repository_patch_sets_parse() -> None:
    assert read_patchset("none", PATCHSETS_DIR, PATCHES_DIR) == []
    assert [p.stem for p in read_patchset("seed", PATCHSETS_DIR, PATCHES_DIR)] == ["seed"]


def test_seed_patch_applies_to_pristine_source(tmp_path: Path) -> None:
    patch = shutil.which("patch")
    if patch is None or not (GEF_SOURCE_DIR / "GEF.bas").is_file():
        pytest.skip("GNU patch or the GEF submodule is not available")
    copy = tmp_path / "src"
    copy.mkdir()
    shutil.copy(GEF_SOURCE_DIR / "GEF.bas", copy / "GEF.bas")
    cmd = [patch, "-p1", "--fuzz=0", "--dry-run", "--batch", "-d", str(copy)]
    proc = subprocess.run(
        [*cmd, "-i", str(PATCHES_DIR / "seed.patch")], capture_output=True, text=True, check=False
    )
    assert proc.returncode == 0, proc.stdout + proc.stderr
    # The patch keeps every line number of GEF.bas (probe and Rnd-log tags rely on that).
    text = (PATCHES_DIR / "seed.patch").read_text(encoding="utf-8")
    assert "@@ -1550,8 +1550,8 @@" in text


def _write_elf(path: Path, sections: list[tuple[str, int, int, bytes]]) -> None:
    """A minimal little-endian ELF64 with the given (name, type, flags, content) sections."""
    names = b"\0" + b"".join(n.encode() + b"\0" for n, *_ in sections) + b".shstrtab\0"
    body = b"".join(c for *_, c in sections)
    header_size, shent = 64, 64
    data = bytearray(header_size)
    data += body
    strtab_off = len(data)
    data += names
    shoff = len(data)
    entries = [struct.pack("<IIQQQQIIQQ", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)]
    name_off, off = 1, header_size
    for name, sh_type, flags, content in sections:
        entries.append(
            struct.pack(
                "<IIQQQQIIQQ", name_off, sh_type, flags, 0x1000 + off, off, len(content), 0, 0, 1, 0
            )
        )
        name_off += len(name) + 1
        off += len(content)
    entries.append(
        struct.pack("<IIQQQQIIQQ", name_off, 3, 0, 0, strtab_off, len(names), 0, 0, 1, 0)
    )
    data += b"".join(entries)
    data[0:16] = b"\x7fELF\x02\x01\x01" + b"\0" * 9
    struct.pack_into("<H", data, 0x34, header_size)
    struct.pack_into("<Q", data, 0x28, shoff)
    struct.pack_into("<HHH", data, 0x3A, shent, len(entries), len(entries) - 1)
    path.write_bytes(bytes(data))


def test_compare_sections_reports_differences(tmp_path: Path) -> None:
    alloc = 0x2
    a, b, c = tmp_path / "a", tmp_path / "b", tmp_path / "c"
    _write_elf(
        a, [(".text", 1, alloc, b"code"), (".data", 1, alloc, b"data"), (".comment", 1, 0, b"A")]
    )
    _write_elf(
        b, [(".text", 1, alloc, b"code"), (".data", 1, alloc, b"data"), (".comment", 1, 0, b"B")]
    )
    _write_elf(c, [(".text", 1, alloc, b"CODE"), (".rodata", 1, alloc, b"ro")])
    same = compare_sections(a, b)
    assert same.equal
    assert same.identical == [".text", ".data"]  # non-ALLOC .comment is ignored
    diff = compare_sections(a, c)
    assert not diff.equal
    assert diff.different == [".text"]
    assert diff.only_in_a == [".data"]
    assert diff.only_in_b == [".rodata"]


def test_compare_sections_rejects_non_elf(tmp_path: Path) -> None:
    junk = tmp_path / "junk"
    junk.write_bytes(b"not an elf")
    with pytest.raises(HarnessError, match="ELF64"):
        compare_sections(junk, junk)


@pytest.mark.fbc
@pytest.mark.slow
def test_seed_build_is_reproducible(tmp_path: Path) -> None:
    from harness.build import build
    from tools.toolchain.fbc import FbcError, resolve_fbc

    try:
        resolve_fbc()
    except FbcError:
        pytest.skip("pinned fbc is not available")
    first = build("seed", build_root=tmp_path / "b")
    second = build("seed", force=True, build_root=tmp_path / "b")
    again = build("seed", build_root=tmp_path / "b")
    assert not first.reused
    assert not second.reused
    assert again.reused
    assert first.manifest["binary_sha256"] == second.manifest["binary_sha256"]
    assert first.manifest["patches"][0]["name"] == "seed"


def test_cli_passes_fbc_options(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    seen: dict[str, object] = {}
    manifest: dict[str, Any] = {
        "binary_sha256": "0" * 64,
        "fbc_diagnostics": "",
        "fbc_wall_time_s": 0.0,
    }

    def fake_build(patchset: str, defines: list[str], **kwargs: object) -> BuildResult:
        seen.update(patchset=patchset, defines=defines, **kwargs)
        return BuildResult("plain-x", tmp_path, tmp_path / "GEF", manifest, reused=True)

    monkeypatch.setattr(build_mod, "build", fake_build)
    assert build_mod.main(["plain", "--fbc-option=-exx", "--fbc-option=-g"]) == 0
    assert seen == {
        "patchset": "plain",
        "defines": [],
        "force": False,
        "source_date_epoch": None,
        "fbc_options": ["-exx", "-g"],
    }


def test_cli_refuses_flags_the_harness_sets(capsys: pytest.CaptureFixture[str]) -> None:
    assert build_mod.main(["plain", "--fbc-option=-o"]) == 1
    assert "harness.build: invalid --fbc-option ['-o']" in capsys.readouterr().err


@pytest.mark.fbc
def test_fbc_options_reach_the_command_and_the_build_id(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    from tools.toolchain.fbc import FbcError, resolve_fbc

    try:
        resolve_fbc()
    except FbcError as exc:
        pytest.skip(f"pinned fbc unavailable: {exc}")
    source = tmp_path / "src"
    source.mkdir()
    (source / "GEF.bas").write_text('Print "ok"\n')
    sets = tmp_path / "sets"
    sets.mkdir()
    (sets / "empty.txt").write_text("# no patches\n")
    build_root = tmp_path / "b"
    build_root.mkdir()
    revision = SimpleNamespace(commit="c" * 40, commit_epoch=1000)
    monkeypatch.setattr(build_mod, "submodule_revision", lambda: revision)

    def build_with(options: list[str]) -> BuildResult:
        return build_mod.build(
            "empty",
            ["FOO"],
            fbc_options=options,
            source_date_epoch=0,
            build_root=build_root,
            source_dir=source,
            patchsets_dir=sets,
            patches_dir=PATCHES_DIR,
        )

    first = build_with(["-exx", "-g"])
    assert not first.reused
    assert first.manifest["command"][1:] == ["GEF.bas", "-d", "FOO", "-exx", "-g"]
    assert first.manifest["fbc_options"] == ["-exx", "-g"]
    assert first.binary.is_file()
    again = build_with(["-exx", "-g"])
    assert again.reused
    assert again.build_id == first.build_id
    other = build_with(["-g", "-exx"])
    assert not other.reused
    assert other.build_id != first.build_id


def test_validate_fbc_options() -> None:
    assert validate_fbc_options(["-exx", "-g"]) == ["-exx", "-g"]
    assert validate_fbc_options(["-g", "-exx"]) == ["-g", "-exx"]
    assert validate_fbc_options([]) == []
    for bad in (["-d"], ["-o"], ["-x"], ["OUT"], [""]):
        with pytest.raises(HarnessError, match="invalid --fbc-option"):
            validate_fbc_options(bad)


def test_fbc_options_enter_the_build_id_only_when_given() -> None:
    args = ("seed", [("seed", "a" * 64)], ["GEF_PROBES"], "c" * 40, "1.10.1", 1000)
    plain = compute_build_id(*args)
    assert plain == "seed-0324c1f83a9e"
    assert compute_build_id(*args, fbc_options=()) == plain
    assert compute_build_id(*args, fbc_options=["-exx"]) != plain
    ordered = compute_build_id(*args, fbc_options=["-exx", "-g"])
    assert ordered != compute_build_id(*args, fbc_options=["-g", "-exx"])
