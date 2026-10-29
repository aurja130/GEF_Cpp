# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for harness.corpus (manifests, run-directory layout) and harness.patch_check."""

from __future__ import annotations

from pathlib import Path

import pytest

from harness.common import REPO_ROOT, HarnessError
from harness.corpus import (
    CORPUS_MANIFEST,
    EDGE_MANIFEST,
    Entry,
    _list_targets,  # pyright: ignore[reportPrivateUsage]
    _render,  # pyright: ignore[reportPrivateUsage]
    _work_files,  # pyright: ignore[reportPrivateUsage]
    generate,
    load_entries,
)
from harness.patch_check import probe_differences, stdout_subsequence

WRKDIR_IN = REPO_ROOT / "Reference" / "GEF_code" / "wrkdir" / "in"
needs_wrkdir = pytest.mark.skipif(not WRKDIR_IN.is_dir(), reason="GEF submodule not checked out")


@needs_wrkdir
def test_committed_corpus_manifest_is_current() -> None:
    assert CORPUS_MANIFEST.read_text(encoding="utf-8") == _render(generate())


def test_manifests_load_with_unique_ids_and_existing_inputs() -> None:
    entries = load_entries()
    assert {e.group for e in entries} == {"wrkdir", "validation", "edge"}
    for e in entries:
        if e.group != "validation":
            assert (REPO_ROOT / e.input).is_file(), e.id
        for source, _ in e.work_files:
            assert (REPO_ROOT / source).is_file(), e.id


@needs_wrkdir
def test_fit_inputs_end_after_one_iteration_and_comment_first_inputs_time_out() -> None:
    by_id = {e.id: e for e in load_entries([CORPUS_MANIFEST])}
    am241 = by_id["wrkdir-AM241F"]  # FIT(APOST): BASIC never ends without NITER
    assert am241.file_in_bytes() == b'NITER(1)\n"in/AM241F.in"\nEND\n'
    assert by_id["wrkdir-Espectrum"].timeout_s < 300  # first line is a comment: GEF hangs
    assert by_id["wrkdir-list-filefitALL"].prepend == ()  # the list carries its own NITER(1)


def test_input_destinations() -> None:
    nested = Entry(
        id="x",
        group="wrkdir",
        input=Path("Reference/GEF_code/wrkdir/in/U238F-distri/antineutrinosU238F.in"),
        tree=Path("Reference/GEF_code/wrkdir/in"),
    )
    assert nested.input_dest() == "in/U238F-distri/antineutrinosU238F.in"
    listed = Entry(id="y", group="edge", input=Path("a/l.in"), file_in=Path("a/l.in"))
    assert listed.input_dest() == "lists/l.in"
    plain = Entry(id="z", group="validation", input=Path("validation/reference/gefy_nfy"))
    assert plain.input_dest() == "in/gefy_nfy"
    assert plain.file_in_bytes() == b'"in/gefy_nfy"\nEND\n'


@needs_wrkdir
def test_tree_copy_skips_the_input_itself() -> None:
    entry = next(e for e in load_entries([CORPUS_MANIFEST]) if e.id == "wrkdir-AM241F")
    dests = [d for _, d in _work_files(entry)]
    assert entry.input_dest() not in dests
    assert "in/U238F-distri/En-U238F-Magali.dat" in dests


def test_list_targets_stop_at_end_and_skip_fit_lines() -> None:
    data = b"fit\r\nNITER(1)\r\n' comment\r\nin/A.in\r\n\"in/B.in\" ' note\r\nEND\r\nin/C.in\r\n"
    assert _list_targets(data) == [Path("in/A.in"), Path("in/B.in")]


def test_bad_manifest_keys_are_refused(tmp_path: Path) -> None:
    manifest = tmp_path / "m.toml"
    manifest.write_text('[[entry]]\nid = "a"\ngroup = "edge"\ninput = "x"\nbogus = 1\n')
    with pytest.raises(HarnessError, match="unknown keys"):
        load_entries([manifest])
    manifest.write_text('[[entry]]\nid = "a"\ngroup = "e"\ninput = "x"\n' * 2)
    with pytest.raises(HarnessError, match="duplicate"):
        load_entries([manifest])


def test_edge_manifest_names_its_note_for_every_entry() -> None:
    assert all(e.note for e in load_entries([EDGE_MANIFEST]))


# ---- patch_check ---------------------------------------------------------------------------


def _probe(path: Path, lines: list[str]) -> Path:
    path.write_text("".join(f"{ln}\n" for ln in lines), encoding="latin-1")
    return path


def test_probe_differences_name_variable_and_record(tmp_path: Path) -> None:
    ctx1, ctx2 = "step=1 pass=- bin=- rec=1", "step=2 pass=- bin=- rec=2"
    a = _probe(tmp_path / "a.txt", [f"P1 {ctx1} Z - S 00000000", f"P1 {ctx2} Z - S 00000000"])
    b = _probe(tmp_path / "b.txt", [f"P1 {ctx1} Z - S 00000000", f"P1 {ctx2} Z - S 3F800000"])
    assert probe_differences(a, b) == {"records": [2, 2], "variables": {"Z": ["2"]}}
    assert probe_differences(a, a) == {"records": [2, 2], "variables": {}}


def test_stdout_subsequence(tmp_path: Path) -> None:
    setup = tmp_path / "s.log"
    full = tmp_path / "f.log"
    setup.write_text("banner\nFile 'file.in' found.\nA\nB\n", encoding="latin-1")
    full.write_text("other banner\nFile 'file.in' found.\nA\nevents\nB\n", encoding="latin-1")
    assert stdout_subsequence(setup, full) == {"subsequence": True, "extra_lines": 1}
    full.write_text("File 'file.in' found.\nB\nA\n", encoding="latin-1")
    assert stdout_subsequence(setup, full)["first_missing"] == "B"
