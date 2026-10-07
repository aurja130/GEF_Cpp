# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for harness.compare_runs on synthetic run directories."""

from __future__ import annotations

import re
from pathlib import Path

import pytest

from harness.common import MASKS_FILE, HarnessError
from harness.compare_runs import (
    Mask,
    apply_masks,
    compare_runs,
    compared_files,
    load_masks,
    main,
)


def make_run(root: Path, files: dict[str, bytes]) -> Path:
    for rel, data in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    return root


def stamp_mask(files: tuple[str, ...] = ("stdout.log",)) -> Mask:
    return Mask("stamp", files, re.compile(r"(?<=at )\d\d:\d\d:\d\d"), "GEF.bas:1", "clock")


BASE = {"stdout.log": b"start at 10:00:01\nline\n", "stderr.log": b"", "work/out/a.dat": b"1 2 3\n"}


def test_identical_runs(tmp_path: Path) -> None:
    a = make_run(tmp_path / "a", BASE)
    b = make_run(tmp_path / "b", BASE)
    result = compare_runs(a, b)
    assert result.identical
    assert result.compared == 3


def test_ignored_files_are_not_compared(tmp_path: Path) -> None:
    a = make_run(tmp_path / "a", {**BASE, "run.json": b"A", "gdb.log": b"A", "capture.json": b"A"})
    b = make_run(tmp_path / "b", {**BASE, "run.json": b"B", "gdb.log": b"B", "capture.json": b"B"})
    assert compare_runs(a, b).identical
    assert set(compared_files(a)) == set(BASE)


def test_first_difference_unmasked(tmp_path: Path) -> None:
    a = make_run(tmp_path / "a", BASE)
    b = make_run(
        tmp_path / "b",
        {
            **BASE,
            "work/out/a.dat": b"1 2 3\n4 5\n6 7\n",
            "stdout.log": b"start at 10:00:02\nline\n",
        },
    )
    a2 = make_run(tmp_path / "a2", {**BASE, "work/out/a.dat": b"1 2 3\n4 5\n6 8\n"})
    result = compare_runs(a, b)
    assert not result.identical
    by_path = {d.path: d for d in result.differences}
    assert by_path["stdout.log"].line == 1
    assert by_path["stdout.log"].a == "start at 10:00:01"
    assert by_path["stdout.log"].b == "start at 10:00:02"
    assert by_path["work/out/a.dat"].line == 2
    assert by_path["work/out/a.dat"].a == ""
    assert by_path["work/out/a.dat"].b == "4 5"
    third = compare_runs(a2, b)
    assert {d.path: d.line for d in third.differences}["work/out/a.dat"] == 3


def test_allowed_only_in_b_files_do_not_make_runs_different(tmp_path: Path) -> None:
    a = make_run(tmp_path / "a", BASE)
    b = make_run(
        tmp_path / "b",
        {**BASE, "work/probes/T0.txt": b"T0 - X - I 1\n", "work/stray.txt": b"x\n"},
    )
    result = compare_runs(a, b, allow_only_in_b=["work/probes/*", "work/rnd.log"])
    assert result.allowed_only_in_b == ["work/probes/T0.txt"]
    assert result.only_in_b == ["work/stray.txt"]
    assert not result.identical
    clean = make_run(tmp_path / "c", {**BASE, "work/probes/T0.txt": b"T0 - X - I 1\n"})
    assert compare_runs(a, clean, allow_only_in_b=["work/probes/*"]).identical


def test_masking_hides_only_masked_text(tmp_path: Path) -> None:
    a = make_run(tmp_path / "a", BASE)
    b = make_run(tmp_path / "b", {**BASE, "stdout.log": b"start at 11:22:33\nline\n"})
    masked = compare_runs(a, b, [stamp_mask()])
    assert masked.identical
    assert masked.mask_hits["stamp"] == 2
    assert masked.unused_masks == []
    # A real difference on the same line is still reported, with masked text.
    c = make_run(tmp_path / "c", {**BASE, "stdout.log": b"stop at 11:22:33\nline\n"})
    result = compare_runs(a, c, [stamp_mask()])
    diff = result.differences[0]
    assert (diff.a, diff.b) == ("start at <MASK:stamp>", "stop at <MASK:stamp>")


def test_mask_applies_only_to_matching_files(tmp_path: Path) -> None:
    files = {**BASE, "work/out/a.dat": b"at 10:00:00\n"}
    a = make_run(tmp_path / "a", files)
    b = make_run(tmp_path / "b", {**files, "work/out/a.dat": b"at 10:00:09\n"})
    result = compare_runs(a, b, [stamp_mask(("stdout.log",))])
    assert [d.path for d in result.differences] == ["work/out/a.dat"]
    wide = compare_runs(a, b, [stamp_mask(("work/*", "stdout.log"))])
    assert wide.identical


def test_missing_and_extra_files(tmp_path: Path) -> None:
    a = make_run(tmp_path / "a", {**BASE, "work/only_a.txt": b"x"})
    b = make_run(tmp_path / "b", {**BASE, "work/dmp/only_b.txt": b"y"})
    result = compare_runs(a, b)
    assert result.only_in_a == ["work/only_a.txt"]
    assert result.only_in_b == ["work/dmp/only_b.txt"]
    assert not result.identical


def test_unused_mask_is_reported_but_not_fatal(tmp_path: Path) -> None:
    a = make_run(tmp_path / "a", {**BASE, "stdout.log": b"nothing here\n"})
    b = make_run(tmp_path / "b", {**BASE, "stdout.log": b"nothing here\n"})
    result = compare_runs(a, b, [stamp_mask()])
    assert result.identical
    assert result.unused_masks == ["stamp"]


def test_trailing_text_and_binary_bytes(tmp_path: Path) -> None:
    a = make_run(tmp_path / "a", {**BASE, "work/b.bin": b"\x00\xff\x0b\x0c\n"})
    b = make_run(tmp_path / "b", {**BASE, "work/b.bin": b"\x00\xff\x0b\x0c\nextra"})
    diff = compare_runs(a, b).differences[0]
    assert (diff.line, diff.a, diff.b) == (2, "", "extra")
    c = make_run(tmp_path / "c", {**BASE, "work/b.bin": b"\x00\xff\x0b\x0c"})
    diff = compare_runs(a, c).differences[0]
    assert diff.b is None


def test_apply_masks_multiple_patterns_per_line() -> None:
    masks = [stamp_mask(), Mask("n", ("*",), re.compile(r"\d+ms"), "x:1", "r")]
    text, matched = apply_masks("at 10:00:00 took 15ms\nplain", masks)
    assert matched
    assert text == "at <MASK:stamp> took <MASK:n>\nplain"


def write_masks(path: Path, body: str) -> Path:
    path.write_text(body, encoding="utf-8")
    return path


GOOD = """
[[mask]]
id = "a"
files = ["stdout.log"]
pattern = "x+"
source = "GEF.bas:1"
reason = "r"
"""


def test_load_masks_valid(tmp_path: Path) -> None:
    masks = load_masks(write_masks(tmp_path / "m.toml", GOOD))
    assert [m.id for m in masks] == ["a"]
    assert masks[0].applies_to("stdout.log")
    assert not masks[0].applies_to("stderr.log")


@pytest.mark.parametrize(
    ("body", "message"),
    [
        ("[[mask]\n", "invalid TOML"),
        ("foo = 1\n", "unknown top-level"),
        ("mask = 3\n", "array of tables"),
        (GOOD.replace('reason = "r"\n', ""), "keys must be exactly"),
        (GOOD + GOOD, "duplicate id"),
        (GOOD.replace('"x+"', '"("'), "bad regex"),
        (GOOD.replace('["stdout.log"]', "[]"), "non-empty list"),
        (GOOD.replace('id = "a"', 'id = ""'), "non-empty string"),
        (GOOD.replace('"GEF.bas:1"', "5"), "non-empty string"),
    ],
)
def test_load_masks_rejects_bad_files(tmp_path: Path, body: str, message: str) -> None:
    with pytest.raises(HarnessError, match=message):
        load_masks(write_masks(tmp_path / "m.toml", body))


def test_load_masks_missing_file(tmp_path: Path) -> None:
    with pytest.raises(HarnessError, match="cannot read"):
        load_masks(tmp_path / "nope.toml")


def test_repository_masks_file_is_valid() -> None:
    if not MASKS_FILE.is_file():
        pytest.skip("harness/masks.toml does not exist yet")
    assert load_masks(MASKS_FILE)


def test_cli_exit_codes_and_report(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    a = make_run(tmp_path / "a", BASE)
    b = make_run(tmp_path / "b", {**BASE, "stdout.log": b"start at 11:22:33\nline\n"})
    masks = write_masks(
        tmp_path / "m.toml", GOOD.replace('"x+"', r'"(?<=at )\\d\\d:\\d\\d:\\d\\d"')
    )
    assert main([str(a), str(b), "--no-masks"]) == 1
    out = capsys.readouterr().out
    assert "DIFFERS: stdout.log: first difference at line 1" in out
    assert "A: start at 10:00:01" in out
    assert main([str(a), str(b), "--masks", str(masks)]) == 0
    assert "IDENTICAL" in capsys.readouterr().out
    assert main([str(a), str(tmp_path / "missing"), "--no-masks"]) == 2
    assert main([str(a), str(b), "--masks", str(tmp_path / "nope.toml")]) == 2
