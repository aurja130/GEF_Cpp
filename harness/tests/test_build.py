# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for harness.build: patch sets, build ids, ELF section comparison, seed.patch."""

from __future__ import annotations

import shutil
import struct
import subprocess
from pathlib import Path

import pytest

from harness.build import (
    compare_sections,
    compute_build_id,
    materialize_patch_dir,
    read_patchset,
    resolve_binary,
    validate_defines,
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
