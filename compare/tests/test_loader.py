# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the run loader."""

from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest

from compare.loader import (
    PARSER_NAMES,
    iter_observables,
    load_file,
    load_run,
    load_run_with_stats,
    parser_modules,
    run_files,
)
from compare.model import Key

_ROOT = Path(__file__).resolve().parents[2]
_TEST_RUN = _ROOT / "validation" / "test_run"
_CAPTURES = _ROOT / "validation" / "reference_store" / "captures"
_MODULES = parser_modules(("probe", "text"))
_ALL_PARSERS = all(importlib.util.find_spec(f"compare.parsers.{n}") for n in PARSER_NAMES)


def _make_m1(root: Path) -> Path:
    (root / "work" / "probes").mkdir(parents=True)
    (root / "work" / "in").mkdir()
    (root / "stdout.log").write_text("run 1\n")
    (root / "stderr.log").write_text("")
    (root / "run.json").write_text("{}")
    (root / "gdb.log").write_text("x 1\n")
    (root / "work" / "file.in").write_text("a 5\n")
    (root / "work" / "rnd.log").write_bytes(b"\0" * 10)
    (root / "work" / "probes" / "P1.txt").write_text("P1 step=1 pass=- bin=- rec=1 N - I 3\n")
    return root


def test_m1_layout(tmp_path: Path) -> None:
    root = _make_m1(tmp_path / "run")
    assert sorted(run_files(root)) == [
        "stderr.log",
        "stdout.log",
        "work/file.in",
        "work/probes/P1.txt",
        "work/rnd.log",
    ]
    table, stats = load_run_with_stats(root, _MODULES)
    assert table.unparsed == ["work/rnd.log"]
    assert stats.files["probe"] == 1
    assert stats.files["text"] == 3
    assert table.values[Key("work/probes/P1.txt", "P1", "step=1 pass=- bin=- rec=1", "N")] == 3
    assert table.values[Key("stdout.log", "text", "", "run # #1", (1,))] == 1
    assert all(k.file not in ("run.json", "gdb.log") for k in table)


def test_plain_layout(tmp_path: Path) -> None:
    root = tmp_path / "plain"
    (root / "in").mkdir(parents=True)
    (root / "run.log").write_text("run 1\n")
    (root / "file.in").write_text("a 5\n")
    (root / "in" / "x.in").write_text("b 6\n")
    assert run_files(root) == {
        "stdout.log": root / "run.log",
        "work/file.in": root / "file.in",
        "work/in/x.in": root / "in" / "x.in",
    }
    table, _ = load_run_with_stats(root, _MODULES)
    assert Key("stdout.log", "text", "", "run # #1", (1,)) in table.values
    assert Key("work/in/x.in", "text", "", "b # #1", (1,)) in table.values


def test_load_file_and_streaming(tmp_path: Path) -> None:
    root = _make_m1(tmp_path / "run")
    one = load_file(root / "work" / "file.in", "work/file.in", _MODULES)
    assert len(one) == 2
    streamed = {rel: len(t) for rel, t in iter_observables(root, _MODULES)}
    assert streamed["work/file.in"] == 2
    assert streamed["work/rnd.log"] == 0


def test_not_a_directory(tmp_path: Path) -> None:
    with pytest.raises(NotADirectoryError):
        load_run(tmp_path / "missing")


@pytest.mark.validation
@pytest.mark.skipif(not _ALL_PARSERS, reason="not all parser modules exist yet")
def test_real_layouts_all_parsers() -> None:
    if not _TEST_RUN.is_dir() or not _CAPTURES.is_dir():
        pytest.skip("validation data absent")
    plain = load_run(_TEST_RUN)
    m1 = load_run(_CAPTURES / "m1-g1-cf252-ref1")
    assert len(plain) > 0
    assert len(m1) > 0
    assert {k.file for k in plain if k.file.startswith("work/")}
