# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the per-run extract (``compare.extract``)."""

from __future__ import annotations

import json
import os
from pathlib import Path

import numpy as np
import pytest

from compare.extract import (
    PAD,
    FileData,
    align_numeric,
    extract_run,
    key_label,
    load_extract,
    match_rows,
    pack_pairs,
    resolve_run,
    run_fingerprint,
    text_map,
    unique_rows,
)
from compare.loader import load_run
from compare.model import Key

_ROOT = Path(__file__).resolve().parents[2]
_CAPTURES = _ROOT / "validation" / "reference_store" / "captures"


def _pairs() -> dict[Key, float | int | str]:
    f = "work/x.dat"
    return {
        Key(f, "B", "g1", "y", (3,)): 1.5,
        Key(f, "B", "g1", "y", (1,)): 2,
        Key(f, "B", "g1", "y", (1, 2)): 7.0,
        Key(f, "B", "g1", "hi", ()): 4.0,
        Key(f, "B", "g1", "title", ()): "text",
        Key(f, "B", "g1", "note", (0,)): "a",
        Key(f, "B", "g1", "note", (1,)): "b",
        Key(f, "A", "", "n", (5,)): float("nan"),
        Key(f, "A", "", "big", ()): 2**60,  # does not fit a float64: kept as text
    }


def test_pack_roundtrip_and_canonical_order() -> None:
    packed = pack_pairs(_pairs().items())
    data = FileData("work/x.dat", packed.layout, packed.vals, packed.tvals)
    assert [(f.block, f.group) for f in packed.layout.families] == [("A", ""), ("B", "g1")]
    seen: dict[Key, float | int | str] = {}
    for fam in data:
        for row, value in zip(fam.kmat.tolist(), fam.vals.tolist(), strict=True):
            label, index = key_label(fam.labels, row)
            seen[Key(fam.family.file, fam.family.block, fam.family.group, label, index)] = value
        for (label, index), value in text_map(fam.tlabels, fam.tkmat, fam.tvals).items():
            seen[Key(fam.family.file, fam.family.block, fam.family.group, label, index)] = value
    expected = {k: v for k, v in _pairs().items() if k.label != "n"}
    expected[Key("work/x.dat", "A", "", "big", ())] = str(2**60)
    nan = next(v for k, v in seen.items() if k.label == "n")
    assert isinstance(nan, float) and np.isnan(nan)
    assert {
        k: float(v) if isinstance(v, int) else v for k, v in seen.items() if k.label != "n"
    } == {k: float(v) if isinstance(v, int) else v for k, v in expected.items()}
    b = data.get("B", "g1")
    assert b is not None
    # sorted by (label, index): hi, y[1], y[1,2], y[3]
    labels = [key_label(b.labels, r) for r in b.kmat.tolist()]
    assert labels == [("hi", ()), ("y", (1,)), ("y", (1, 2)), ("y", (3,))]
    assert b.kmat[0].tolist()[1] == PAD  # missing index columns are padded


def test_duplicate_keys_are_rejected() -> None:
    k = Key("f", "b", "", "x", (1,))
    with pytest.raises(ValueError, match="duplicate"):
        pack_pairs([(k, 1.0), (k, 2.0)])


def test_layout_is_shared_by_runs_with_the_same_keys() -> None:
    a = pack_pairs(_pairs().items())
    changed = {k: (v + 1.0 if isinstance(v, float) else v) for k, v in _pairs().items()}
    b = pack_pairs(changed.items())
    assert a.layout.sha == b.layout.sha
    assert not np.array_equal(a.vals, b.vals, equal_nan=True)


def test_unique_rows_and_matching() -> None:
    m = np.array([[1, 2], [0, 5], [1, 2], [0, 1]], dtype=np.int64)
    uniq, inv = unique_rows(m)
    assert uniq.tolist() == [[0, 1], [0, 5], [1, 2]]
    assert inv.tolist() == [2, 1, 2, 0]
    ref = np.array([[0, 1], [1, 2]], dtype=np.int64)
    assert match_rows(ref, np.array([[1, 2], [9, 9], [0, 1]], dtype=np.int64)).tolist() == [
        1,
        -1,
        0,
    ]


def test_align_zero_fills_absent_keys_and_unions_labels() -> None:
    def part(d: dict[Key, float]) -> tuple[tuple[str, ...], np.ndarray, np.ndarray]:
        p = pack_pairs(d.items())
        f = p.layout.families[0]
        data = FileData("f", p.layout, p.vals, p.tvals)
        fd = data.family_at(0)
        assert f.n == len(fd.vals)
        return fd.labels, fd.kmat, fd.vals

    r1 = {Key("f", "b", "", "y", (1,)): 1.0, Key("f", "b", "", "y", (2,)): 2.0}
    r2 = {Key("f", "b", "", "y", (2,)): 3.0, Key("f", "b", "", "z", (7,)): 9.0}
    al = align_numeric([part(r1), part(r2), part(r1)])
    assert al.labels == ("y", "z")
    keys = [key_label(al.labels, r) for r in al.kmat.tolist()]
    col = {k: i for i, k in enumerate(keys)}
    assert al.vals[:, col["y", (1,)]].tolist() == [1.0, 0.0, 1.0]
    assert al.present[:, col["y", (1,)]].tolist() == [True, False, True]
    assert al.vals[:, col["z", (7,)]].tolist() == [0.0, 9.0, 0.0]
    same = align_numeric([part(r1), part(r1)])  # fast path: identical key sets
    assert same.vals.shape == (2, 2) and same.present.all()


def _make_run(root: Path, number: int) -> Path:
    (root / "work" / "in").mkdir(parents=True)
    (root / "stdout.log").write_text(f"run {number} done in 12.5 s\n")
    (root / "stderr.log").write_text("")
    (root / "work" / "in" / "x.in").write_text("a 5\nb 6 7\n")
    (root / "run.json").write_text(json.dumps({"input": {"sha256": "ab" * 32}, "seed": number}))
    return root


def test_extract_run_cache_keying(tmp_path: Path) -> None:
    run = _make_run(tmp_path / "run", 1)
    cache = tmp_path / "cache"
    first = extract_run(run, cache)
    assert first.input_sha256 == "ab" * 32
    assert first.manifest["seed"] == 1
    assert first.rels == ["stdout.log", "stderr.log", "work/in/x.in"]
    again = extract_run(run, cache)
    assert again.root == first.root  # cached
    data = first.file("work/in/x.in")
    assert data is not None and data.layout.nnum > 0
    # the extract holds exactly the observables of the loader
    table = load_run(run)
    total = sum(f.n + f.nt for rel in first.rels for f in (first.file(rel) or data).layout.families)
    assert total == len(table)
    # a changed file (size) gives another extract
    (run / "work" / "in" / "x.in").write_text("a 5\nb 6 7\nc 8\n")
    changed = extract_run(run, cache)
    assert changed.root != first.root
    assert load_extract(changed.root).root == changed.root  # an extract dir loads as itself
    assert load_extract(run, cache).root == changed.root
    # forcing rebuilds in place
    forced = extract_run(run, cache, force=True)
    assert forced.root == changed.root


def test_fingerprint_follows_mtime(tmp_path: Path) -> None:
    run = _make_run(tmp_path / "run", 2)
    before = run_fingerprint(run)
    assert run_fingerprint(run) == before
    target = run / "work" / "in" / "x.in"
    os.utime(target, ns=(1, 1))
    assert run_fingerprint(run) != before


def test_resolve_run(tmp_path: Path) -> None:
    assert resolve_run(tmp_path) == tmp_path
    with pytest.raises(FileNotFoundError):
        resolve_run("no-such-capture-id")


@pytest.mark.validation
@pytest.mark.skipif(not _CAPTURES.is_dir(), reason="no reference store")
def test_real_capture_extract_matches_loader(tmp_path: Path) -> None:
    run = _CAPTURES / "m1-g1-cf252-ref1"
    if not run.is_dir():
        pytest.skip("capture m1-g1-cf252-ref1 not stored")
    ex = extract_run(run, tmp_path / "cache")
    table = load_run(run)
    assert ex.manifest["observables"] == len(table)
    assert not ex.unparsed or set(ex.unparsed) == set(table.unparsed)
    assert json.loads((ex.root / "manifest.json").read_text())["kind"] == "extract"
