# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the M7 capture corpus (manifest, m7-p3 golden derivation, last-writer map)."""

from __future__ import annotations

import json
import re
from pathlib import Path
from types import SimpleNamespace
from typing import cast

import pytest

from harness.common import GEF_SOURCE_DIR, REPO_ROOT, STORE_CAPTURES, HarnessError
from harness.corpus import M7_MANIFEST, load_entries
from harness.golden import GOLDEN_DIR
from harness.p3_golden import build_golden

GOLDEN = GOLDEN_DIR / "m7-p3"

COVERAGE_MATRIX = REPO_ROOT / "Planning" / "COVERAGE_MATRIX.md"
# The T1 cells MILESTONE_7_PLAN.md section 4 says M7 closes; every one needs a capture (D5).
M7_T1_CELLS = (
    "Pre-actinides",
    "Actinides",
    "Heavy actinides",
    "Superheavies",
    "Light vs. heavy isotopes",
    "Even-Z / even-N",
    "Odd-Z and/or odd-N",
    "Very low fissility",
    "Thermal",
    "Fast, first-chance only",
    "`NOSUPP`",
    "`MODE(i)`",
)


def _matrix_rows() -> set[str]:
    rows: set[str] = set()
    for line in COVERAGE_MATRIX.read_text(encoding="utf-8").splitlines():
        if line.startswith("| ") and not line.startswith("| ---"):
            rows.add(line.split(" | ")[0][2:].strip())
    return rows


def test_m7_entries_fix_seed_and_trace_selection_and_have_their_files() -> None:
    entries = load_entries((M7_MANIFEST,))
    assert entries
    seeds = [e.seed for e in entries]
    assert None not in seeds and len(set(seeds)) == len(seeds)
    for e in entries:
        assert e.group == "m7" and e.steps and e.passes and e.note, e.id
        assert (REPO_ROOT / e.input).is_file(), e.id
        for src, _ in e.work_files:
            assert (REPO_ROOT / src).is_file(), e.id
        if e.file_in is not None:
            assert e.tree is not None
            for name in re.findall(r'"in/([^"]+)"', (REPO_ROOT / e.file_in).read_text()):
                assert (REPO_ROOT / e.tree / name).is_file(), (e.id, name)


def test_m7_cells_name_coverage_rows_and_cover_every_cell_m7_closes() -> None:
    rows = _matrix_rows()
    covered: set[str] = set()
    for e in load_entries((M7_MANIFEST,)):
        for cell in e.cells:
            assert cell in rows, (e.id, cell)
            covered.add(cell)
    for cell in M7_T1_CELLS:
        assert any(c.startswith(cell) for c in covered), cell


def test_chain_entries_are_nominal_first_chance_runs() -> None:
    """D2: chain runs have one nominal pass (no option or mode line can switch on error
    analysis or change the run) and only first-chance bins (from the committed golden)."""
    chains = [e for e in load_entries((M7_MANIFEST,)) if e.chain]
    assert len(chains) >= 2
    golden = (GOLDEN / "fingerprints.txt").read_text(encoding="utf-8").splitlines()[1:]
    for e in chains:
        lines = [ln.strip() for ln in (REPO_ROOT / e.input).read_text().splitlines()]
        assert not [ln for ln in lines if re.match(r"(?i)(options|mode|fit|niter)\b", ln)], e.id
        assert e.passes == "0", e.id
        bins = [ln.split()[5] for ln in golden if ln.split()[0] == e.id]
        assert bins and all(b.endswith(":0:0:0") for b in bins), e.id


# ---- m7-p3 golden ----------------------------------------------------------------------


def _record(probe: str, rec: int, bin_: str, value: str) -> str:
    ctx = f"{probe} step=1 pass=0 bin={bin_} rec={rec}"
    return f"{ctx} NEVTused - I 5\n{ctx} Racc - S {value}\n"


def _capture(
    captures: Path, entry: str, p3in_bins: list[str], p3_bins: list[str], value: str = "3F800000"
) -> None:
    run = captures / f"m7-p3-{entry}"
    probes = run / "work" / "probes"
    probes.mkdir(parents=True)
    (run / "run.json").write_text(json.dumps({"exit_code": 0}), encoding="utf-8")
    (probes / "P3in.txt").write_text(
        "".join(_record("P3in", k, b, value) for k, b in enumerate(p3in_bins, start=1)),
        encoding="latin-1",
    )
    (probes / "P3.txt").write_text(
        "".join(_record("P3", k, b, "40000000") for k, b in enumerate(p3_bins, start=1)),
        encoding="latin-1",
    )


def test_golden_lists_p3in_then_p3_records_with_their_bins(tmp_path: Path) -> None:
    _capture(tmp_path, "a", ["1:0:0:0", "1:1:0:20"], ["1:0:0:0", "1:1:0:20"])
    golden = build_golden(tmp_path, ["a"])
    lines = golden.fingerprint_text.splitlines()
    assert lines[0] == "# m7-p3 fingerprints 1"
    fields = [ln.split()[:7] for ln in lines[1:]]
    assert fields == [
        ["a", "P3in", "1", "1", "0", "1:0:0:0", "2"],
        ["a", "P3in", "2", "1", "0", "1:1:0:20", "2"],
        ["a", "P3", "1", "1", "0", "1:0:0:0", "2"],
        ["a", "P3", "2", "1", "0", "1:1:0:20", "2"],
    ]
    assert ("m7-p3-a", "work/probes/P3in.txt") in golden.sources


def test_golden_digest_follows_the_values(tmp_path: Path) -> None:
    _capture(tmp_path, "a", ["1:0:0:0"], ["1:0:0:0"])
    _capture(tmp_path, "b", ["1:0:0:0"], ["1:0:0:0"])
    _capture(tmp_path, "c", ["1:0:0:0"], ["1:0:0:0"], value="3F800001")
    rows = [
        ln.split() for ln in build_golden(tmp_path, ["a", "b", "c"]).fingerprint_text.splitlines()
    ]
    digest = {r[0]: r[7] for r in rows[1:] if r[1] == "P3in"}
    assert digest["a"] == digest["b"] != digest["c"]


def test_golden_refuses_p3in_and_p3_of_different_bins(tmp_path: Path) -> None:
    _capture(tmp_path, "a", ["1:0:0:0", "1:0:0:5"], ["1:0:0:0", "1:0:0:6"])
    with pytest.raises(HarnessError, match="same bins"):
        build_golden(tmp_path, ["a"])


def test_golden_refuses_a_capture_without_p3in(tmp_path: Path) -> None:
    _capture(tmp_path, "a", [], ["1:0:0:0"])
    with pytest.raises(HarnessError, match="no P3in record"):
        build_golden(tmp_path, ["a"])


# ---- last-writer map -------------------------------------------------------------------


def test_golden_has_every_manifest_entry_in_manifest_order() -> None:
    rows = (GOLDEN / "fingerprints.txt").read_text(encoding="utf-8").splitlines()[1:]
    ids: list[str] = []
    for row in rows:
        if not ids or ids[-1] != row.split()[0]:
            ids.append(row.split()[0])
    assert ids == [e.id for e in load_entries((M7_MANIFEST,))]


@pytest.mark.skipif(not STORE_CAPTURES.is_dir(), reason="needs the reference store")
def test_chain_captures_run_no_multi_chance_pre_pass() -> None:
    """D2: the chain must be computable without M9, so no step runs the pre-pass (P2 Bmulti 0)."""
    from harness.probes import read_probe_file

    for e in load_entries((M7_MANIFEST,)):
        if not e.chain:
            continue
        p2 = read_probe_file(STORE_CAPTURES / f"m7-p3-{e.id}" / "work" / "probes" / "P2.txt")
        assert p2 and [r.scalar("Bmulti") for r in p2] == [0] * len(p2), e.id


@pytest.mark.skipif(not (GEF_SOURCE_DIR / "GEF.bas").is_file(), reason="needs Reference/GEF_code")
@pytest.mark.fbc
def test_committed_last_writer_map_is_current() -> None:
    from harness.last_writer import MAP_PATH, derive
    from tools.toolchain.fbc import FbcError, resolve_fbc

    try:
        resolve_fbc()
    except FbcError:
        pytest.skip("pinned fbc is not available")
    assert MAP_PATH.read_text(encoding="utf-8") == derive()


def test_last_writer_map_covers_every_p3_variable_once() -> None:
    from harness.last_writer import MAP_PATH, p3_variables

    rows = [ln.split(" ", 3) for ln in MAP_PATH.read_text(encoding="utf-8").splitlines()[2:]]
    assert [r[0] for r in rows] == [name for name, _ in p3_variables()]
    for name, kind, last, writers in rows:
        assert kind in {"S", "I", "D", "A"}, name
        assert last in {"input", "M7.1", "M7.2", "M7.3", "M7.4"}, name
        if last == "input":
            assert writers == "-", name
        else:
            last_cell = writers.split()[-1]
            assert re.fullmatch(rf"\d+:{re.escape(last)}(=\S+)?(@\w+)?", last_cell), name


# Plan section 3 anchors: a variable whose last writer is known from the plan's block cut.
LAST_WRITER_ANCHORS = {
    "ZC_Mode_0": "M7.1",  # 5621-5696 mode centres
    "Z": "M7.1",  # 5876-5994 mean Z vs A (global Z)
    "R_Z_Curv_S0": "M7.1",  # 6050-6062 curvatures
    "R_E_exc_Eb": "M7.2",  # 6063-6104 energy transformation
    "beta": "M7.2",  # 6142-6151 in-place update of Beta(1,1,.)
    "EsciS0": "M7.3",  # 6561-6733 energy-dependent shifts
    "Yield_Mode_0": "M7.3",  # 6872-7019 mode yields
    "Racc": "M7.3",  # 7920
    "DU0": "M7.4",  # 7040-7072 shell effects
    "E_tunn": "M7.4",  # mode-7 value of the EPART loop (Q-008)
    "EPART": "M7.4",  # 7376-7377
    "SpinRMSNZ": "M7.4",  # 7381-7511
    "Spin_CN": "input",  # bin input, not written by the builder
}


def test_last_writer_map_follows_the_plan_block_cut() -> None:
    from harness.last_writer import MAP_PATH

    rows = {
        ln.split(" ")[0]: ln.split(" ")[2]
        for ln in MAP_PATH.read_text(encoding="utf-8").splitlines()[2:]
    }
    assert {name: rows[name] for name in LAST_WRITER_ANCHORS} == LAST_WRITER_ANCHORS


# ---- per-entry run settings ------------------------------------------------------------


def test_entry_seed_and_scope_override_the_run_defaults(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import harness.corpus as corpus

    calls: list[tuple[int, dict[str, str]]] = []

    def fake_run(binary: Path, inp: Path, out: Path, seed: int, **kw: object) -> object:
        del binary, inp, out
        scope = kw["scope"]
        assert isinstance(scope, dict)
        calls.append((seed, cast(dict[str, str], scope)))
        return SimpleNamespace(exit_code=0)

    monkeypatch.setattr(corpus, "run", fake_run)
    source = REPO_ROOT / "harness/inputs/m7/cf252_sf.in"
    plain = corpus.Entry(id="plain", group="m7", input=source)
    pinned = corpus.Entry(id="pinned", group="m7", input=source, seed=7, steps="2", passes="0,3")
    summary = corpus.run_entries([plain, pinned], Path("GEF"), tmp_path / "out", seed=1, passes="9")
    assert calls == [
        (1, {"steps": corpus.STEPS, "passes": "9"}),
        (7, {"steps": "2", "passes": "0,3"}),
    ]
    assert "seed" not in summary["entries"][0]
    assert summary["entries"][1]["seed"] == 7
    assert summary["entries"][1]["scope"] == {"steps": "2", "passes": "0,3"}
