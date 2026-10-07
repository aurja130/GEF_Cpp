# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Calibration and verdict on synthetic ensembles with known distributions.

The ensemble has count histograms (Poisson counts with a per-run common-mode factor, like the
shared pre-pass), scalar Gaussian families, deterministic headers and a stochastic text key.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np
import pytest

from compare import calibrate as cal_mod
from compare import report, verdict
from compare.calibrate import Calibration, calibrate
from compare.extract import FileData, pack_pairs
from compare.model import Key
from compare.tests.synth import (
    DMP,
    OUT,
    SHA,
    MemoryExtract,
    binom_interval,
    draw_run,
    write_extract,
)

K = 20
N_COUNT = 8
N_SCALAR = 3


@pytest.fixture(scope="module")
def ensemble(tmp_path_factory: pytest.TempPathFactory) -> tuple[Calibration, Path]:
    root = tmp_path_factory.mktemp("ens")
    rng = np.random.default_rng(12345)
    members = [
        str(write_extract(root / f"s{i}", draw_run(rng, seed=i), root / "pool", seed=i))
        for i in range(K)
    ]
    out = root / "cal"
    calibrate(members, out, jobs=1, mde=[f"{DMP}::B0"], input_sha256=SHA)
    return Calibration.open(out), root


def _judge(cal: Calibration, runs: list[MemoryExtract], **kw: object) -> verdict.VerdictResult:
    return verdict.judge(cal, runs, **kw)  # type: ignore[arg-type]


# ---- calibration artifact ----


def test_manifest_and_layout(ensemble: tuple[Calibration, Path]) -> None:
    cal, root = ensemble
    m = cal.manifest
    assert m["kind"] == "calibration" and m["runs"] == K
    assert m["input_sha256"] == SHA
    assert m["alpha"] == 0.01
    assert sorted(m["files"]) == [DMP, OUT]
    assert m["families"] == N_COUNT + N_SCALAR
    assert m["stat_families"] == N_COUNT + N_SCALAR
    assert len(m["ensemble"]) == K and (root / "cal" / "diagnostics.txt").is_file()
    assert m["code"]["rev"]
    dmp = cal.file(DMP)
    assert dmp is not None
    fam = dmp.family("B0", "#1")
    assert fam is not None
    assert fam.null.count_like and not fam.null.degenerate
    assert fam.loo_d.shape == (K,) and np.all(np.isfinite(fam.loo_d))
    # the deterministic header and the text title are exact, the per-run comment is stochastic
    assert fam.tcls.tolist().count(0) == 1 and fam.tcls.tolist().count(1) == 1
    out = cal.file(OUT)
    assert out is not None
    scalar = out.family("S0", "run1/1#1")
    assert scalar is not None
    assert scalar.null.n_stoch == 4 and scalar.null.degenerate  # fewer than 30 fields
    assert 1 in scalar.cls.tolist() and 0 in scalar.cls.tolist()  # 'barrier' is deterministic


def test_mde_tables_are_written_and_recomputable(
    ensemble: tuple[Calibration, Path], capsys: pytest.CaptureFixture[str]
) -> None:
    cal, root = ensemble
    index = json.loads((root / "cal" / "mde" / "index.json").read_text())
    assert [e["block"] for e in index] == ["B0"]
    entry = index[0]
    assert entry["t_star"] > 4.0 and entry["candidate_runs"] == 1
    assert 0.0 < entry["median_rel_mde"] < 1.0
    npz = np.load(root / "cal" / "mde" / f"{entry['npz']}.npz")
    tag = entry["tag"]
    assert npz[f"abs_{tag}"].shape == npz[f"mean_{tag}"].shape
    # more candidate runs lower the MDE; the selectors can be rewritten for another m
    assert (
        cal_mod.main(
            ["--mde-from", str(root / "cal"), "--mde", f"{OUT}::S0", "--candidate-runs", "4"]
        )
        == 0
    )
    assert "MDE" in capsys.readouterr().out
    again = json.loads((root / "cal" / "mde" / "index.json").read_text())
    assert [e["block"] for e in again] == ["S0"] and again[0]["candidate_runs"] == 4
    cal_mod.write_mde(cal, [f"{DMP}::B0"], 1)  # restore for the other tests


def test_calibration_needs_four_members_and_one_input(tmp_path: Path) -> None:
    rng = np.random.default_rng(1)
    dirs = [
        str(write_extract(tmp_path / f"r{i}", draw_run(rng, n_count=1, n_scalar=0), tmp_path / "p"))
        for i in range(3)
    ]
    with pytest.raises(ValueError, match="at least 4"):
        calibrate(dirs, tmp_path / "c", jobs=1, mde=[])
    dirs += [
        str(
            write_extract(
                tmp_path / "r3",
                draw_run(rng, n_count=1, n_scalar=0),
                tmp_path / "p",
                input_sha256="b" * 64,
            )
        ),
    ]
    with pytest.raises(ValueError, match="same known input"):
        calibrate(dirs, tmp_path / "c", jobs=1, mde=[])


def test_resolve_ensemble_prefix_and_exclusion(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    caps = tmp_path / "captures"
    for seed in (3, 1, 2):
        (caps / f"ens-x-s{seed}").mkdir(parents=True)
    (caps / "ens-x-sfoo").mkdir()
    monkeypatch.setattr(cal_mod, "STORE_CAPTURES", caps)
    assert cal_mod.resolve_ensemble(["ens-x"]) == ["ens-x-s1", "ens-x-s2", "ens-x-s3"]
    assert cal_mod.resolve_ensemble(["ens-x"], ["ens-x-s2"]) == ["ens-x-s1", "ens-x-s3"]
    with pytest.raises(ValueError, match="not ensemble members"):
        cal_mod.resolve_ensemble(["ens-x"], ["ens-x-s9"])
    with pytest.raises(FileNotFoundError):
        cal_mod.resolve_ensemble(["nothing"])


def test_leave_one_out_calibration_records_exclusion(tmp_path: Path) -> None:
    rng = np.random.default_rng(2)
    dirs = [
        str(
            write_extract(
                tmp_path / f"r{i}",
                draw_run(rng, n_count=2, n_scalar=1, seed=i),
                tmp_path / "p",
                seed=i,
            )
        )
        for i in range(6)
    ]
    members = cal_mod.resolve_ensemble(dirs, [dirs[2]])
    manifest = calibrate(members, tmp_path / "c", excluded=[dirs[2]], jobs=1, mde=[])
    assert manifest["runs"] == 5 and manifest["excluded"] == [dirs[2]]
    held_out = MemoryExtract(draw_run(np.random.default_rng(2), n_count=2, n_scalar=1))
    result = _judge(Calibration.open(tmp_path / "c"), [held_out])
    assert result.tested == 3


# ---- null behaviour ----


def test_null_suites_fail_at_about_alpha(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    rng = np.random.default_rng(777)
    suites = 400
    failures = 0
    for s in range(suites):
        cand = MemoryExtract(draw_run(rng, seed=1000 + s))
        failures += not _judge(cal, [cand]).passed
    # 400 suites at a true 1 % rate: the failure count lies in the 99 % binomial interval
    lo, hi = binom_interval(suites, 0.01)
    assert lo <= failures <= hi, f"{failures} failed of {suites}"


def test_candidate_sets_do_not_inflate_false_alarms(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    rng = np.random.default_rng(31)
    failures = 0
    suites = 150
    for s in range(suites):
        cands = [MemoryExtract(draw_run(rng, seed=2000 + 5 * s + j)) for j in range(4)]
        failures += not _judge(cal, cands).passed
    assert failures <= binom_interval(suites, 0.01)[1]


# ---- detection ----


def _with_shift(
    rng: np.random.Generator, key: Key, delta: float, runs: int = 1
) -> list[MemoryExtract]:
    out: list[MemoryExtract] = []
    for j in range(runs):
        files = draw_run(rng, seed=5000 + j)
        files[key.file][key] = float(files[key.file][key]) + delta  # type: ignore[arg-type]
        out.append(MemoryExtract(files))
    return out


def test_shift_above_mde_is_detected_in_the_right_family_and_bin(
    ensemble: tuple[Calibration, Path],
) -> None:
    cal, _ = ensemble
    dmp = cal.file(DMP)
    assert dmp is not None
    fam = dmp.family("B3", "#1")
    assert fam is not None
    mde = cal.mde(fam, 1)
    # pick a well-populated bin: its MDE is a few percent of the mean
    peak = int(np.argmax(np.where(fam.cls == 1, fam.mean, 0.0)))
    row = fam.kmat[peak].tolist()
    key = Key(DMP, "B3", "#1", "y", (row[1],))
    rng = np.random.default_rng(99)
    shifted = _with_shift(rng, key, 1.5 * float(mde.absolute[peak]))
    result = _judge(cal, shifted)
    assert not result.passed
    hit = result.rejected[0]
    assert (hit.file, hit.block) == (DMP, "B3")
    assert hit.top[0].key == f"y[{row[1]}]" and hit.top[0].z > 0
    # relative MDE is a real fraction of the mean, and larger for a single candidate run than
    # for a set of four
    assert 0.0 < mde.relative[peak] < 1.0
    assert cal.mde(fam, 4).absolute[peak] < mde.absolute[peak]


def test_shift_far_below_mde_is_not_detected(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    dmp = cal.file(DMP)
    assert dmp is not None
    fam = dmp.family("B3", "#1")
    assert fam is not None
    peak = int(np.argmax(np.where(fam.cls == 1, fam.mean, 0.0)))
    key = Key(DMP, "B3", "#1", "y", (fam.kmat[peak].tolist()[1],))
    mde = cal.mde(fam, 1)
    fails = sum(
        not _judge(
            cal, _with_shift(np.random.default_rng(300 + s), key, 0.05 * float(mde.absolute[peak]))
        ).passed
        for s in range(30)
    )
    assert fails <= 2


def test_broad_shift_is_caught_by_the_global_statistic(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    rng = np.random.default_rng(55)
    files = draw_run(rng, seed=6000)
    for key in list(files[DMP]):
        if key.block == "B5" and key.label == "y":
            files[DMP][key] = float(files[DMP][key]) * 1.15  # type: ignore[operator]
    result = _judge(cal, [MemoryExtract(files)])
    assert not result.passed
    hit = result.rejected[0]
    assert hit.block == "B5" and hit.p_global < hit.p_local


# ---- candidate-set scaling ----


def test_candidate_set_variance_scaling(ensemble: tuple[Calibration, Path]) -> None:
    """z uses sqrt(v (1/m + 1/K)): m identical shifted runs give z = delta / sqrt(v (1/m + 1/K))."""
    cal, _ = ensemble
    out = cal.file(OUT)
    assert out is not None
    fam = out.family("S1", "run1/1#1")
    assert fam is not None
    idx = next(i for i in range(len(fam.mean)) if fam.cls[i] == 1 and fam.kmat[i, 1] == 2)
    v = float(fam.v[idx])
    delta = 12.0 * math.sqrt(v)
    zs: dict[int, float] = {}
    for m in (1, 4):
        runs: list[MemoryExtract] = []
        for j in range(m):
            files = draw_run(np.random.default_rng(1), seed=j)
            target = Key(OUT, "S1", "run1/1#1", "x", (2,))
            files[OUT][target] = float(fam.mean[idx]) + delta
            runs.append(MemoryExtract(files))
        result = _judge(cal, runs)
        hit = next(f for f in result.families if f.block == "S1")
        top = next(t for t in hit.top if t.key == "x[2]")
        zs[m] = top.z
        assert top.z == pytest.approx(delta / math.sqrt(v * (1 / m + 1 / K)))
    assert zs[4] / zs[1] == pytest.approx(math.sqrt((1 + 1 / K) / (1 / 4 + 1 / K)))


# ---- zero fill, new keys, classes ----


def test_absent_bins_are_zero_and_new_bins_are_judged(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    rng = np.random.default_rng(404)
    files = draw_run(rng, seed=7000)
    tail = [k for k in files[DMP] if k.block == "B2" and k.label == "y"]
    # a bin the candidate does not have (zero) is fine when its mean is small ...
    small = min(tail, key=lambda k: files[DMP][k])  # type: ignore[arg-type, return-value]
    del files[DMP][small]
    # ... and a key never seen in the ensemble with a tiny value is not a failure either
    files[DMP][Key(DMP, "B2", "#1", "y", (9999,))] = 1e-4
    result = _judge(cal, [MemoryExtract(files)])
    assert not [f for f in result.rejected if f.block == "B2"]
    # a new key far above anything in the group is
    files[DMP][Key(DMP, "B2", "#1", "y", (9999,))] = 5.0
    result = _judge(cal, [MemoryExtract(files)])
    bad = [f for f in result.rejected if f.block == "B2"]
    assert bad and bad[0].top[0].key == "y[9999]"


def test_deterministic_mismatches_fail_outright(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    rng = np.random.default_rng(5)
    base = draw_run(rng, seed=8000)
    # numeric header
    files = {r: dict(t) for r, t in base.items()}
    files[DMP][Key(DMP, "B1", "#1", "events", ())] = 100001
    r1 = _judge(cal, [MemoryExtract(files)])
    assert not r1.passed and r1.rejected[0].mismatches[0].key == "events"
    # deterministic text
    files = {r: dict(t) for r, t in base.items()}
    files[DMP][Key(DMP, "B1", "#1", "title", ())] = "something else"
    r2 = _judge(cal, [MemoryExtract(files)])
    assert not r2.passed and r2.rejected[0].mismatches[0].key == "title"
    # a numeric constant of a table-free family
    files = {r: dict(t) for r, t in base.items()}
    files[OUT][Key(OUT, "S0", "run1/1#1", "barrier", ())] = 5.5
    r3 = _judge(cal, [MemoryExtract(files)])
    assert not r3.passed and r3.rejected[0].mismatches[0].key == "barrier"
    # a stochastic text field may differ freely
    files = {r: dict(t) for r, t in base.items()}
    files[DMP][Key(DMP, "B1", "#1", "comment", (0,))] = "another seed"
    assert _judge(cal, [MemoryExtract(files)]).passed


def test_missing_family_and_extra_text_key(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    base = draw_run(np.random.default_rng(6), seed=9000)
    files = {r: dict(t) for r, t in base.items()}
    files[DMP] = {k: v for k, v in files[DMP].items() if k.block != "B4"}
    result = _judge(cal, [MemoryExtract(files)])
    assert not result.passed and any(
        f.status == "missing" and f.block == "B4" for f in result.families
    )
    # restricting the files judged leaves out the out-file families
    scoped = _judge(cal, [MemoryExtract(base)], files=[DMP])
    assert scoped.tested == N_COUNT
    files = {r: dict(t) for r, t in base.items()}
    files[DMP][Key(DMP, "B1", "#1", "surprise", (0,))] = "text"
    assert not _judge(cal, [MemoryExtract(files)]).passed
    assert _judge(cal, [MemoryExtract(files)], allow_extra=True).passed


def test_group_map_selects_a_run(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    base = draw_run(np.random.default_rng(7), seed=9100)
    real: dict[Key, float | int | str] = {}
    for k, v in base[OUT].items():  # the real run, written as the second run of the file
        real[Key(k.file, k.block, k.group.replace("run1", "run2"), k.label, k.index)] = v
    for k, v in base[OUT].items():  # an earlier partial run (run1) with garbage values
        real[k] = 1e6 if isinstance(v, float) else v
    files = {DMP: dict(base[DMP]), OUT: real}
    assert not _judge(cal, [MemoryExtract(files)]).passed
    mapped = _judge(cal, [MemoryExtract(files)], group_map={"run2": "run1"})
    assert mapped.passed
    assert mapped.kinds["out"]["extra"] == 0 and mapped.kinds["out"]["tested"] == N_SCALAR


def test_group_map_keeps_files_without_the_mapped_run() -> None:
    f = "work/x.dat"
    two = pack_pairs(
        {
            Key(f, "B", "run1/1#1", "x", (0,)): 1.0,
            Key(f, "B", "run2/1#1", "x", (0,)): 2.0,
        }.items()
    )
    one = pack_pairs({Key(f, "B", "run1/1#1", "x", (0,)): 3.0}.items())
    mapped = verdict.remap_groups(FileData(f, two.layout, two.vals, two.tvals), {"run2": "run1"})
    assert sorted(mapped) == [("B", "run1/1#1")]
    assert mapped["B", "run1/1#1"] == two.layout.index["B", "run2/1#1"]
    kept = verdict.remap_groups(FileData(f, one.layout, one.vals, one.tvals), {"run2": "run1"})
    assert sorted(kept) == [("B", "run1/1#1")]


# ---- input hash ----


def test_input_hash_check(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    good = MemoryExtract(draw_run(np.random.default_rng(1)))
    verdict.check_inputs(cal, [good], None)
    wrong = MemoryExtract(draw_run(np.random.default_rng(1)), input_sha256="c" * 64)
    with pytest.raises(ValueError, match="mismatch"):
        verdict.check_inputs(cal, [wrong], None)
    plain = MemoryExtract(draw_run(np.random.default_rng(1)), input_sha256=None)
    with pytest.raises(ValueError, match=r"no run\.json"):
        verdict.check_inputs(cal, [plain], None)
    verdict.check_inputs(cal, [plain], SHA)
    with pytest.raises(ValueError, match="mismatch"):
        verdict.check_inputs(cal, [plain], "d" * 64)


# ---- reports ----


def test_reports_are_deterministic_and_complete(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    files = draw_run(np.random.default_rng(8), seed=9200)
    key = Key(DMP, "B6", "#1", "y", (40,))
    files[DMP][key] = float(files[DMP].get(key, 0.0)) + 0.5  # type: ignore[arg-type]
    files[DMP][Key(DMP, "B1", "#1", "events", ())] = 5
    a = _judge(cal, [MemoryExtract(files, name="cand")], names=["cand"])
    b = _judge(cal, [MemoryExtract(files, name="cand")], names=["cand"])
    assert report.render_text(a) == report.render_text(b)
    assert report.render_json(a) == report.render_json(b)
    assert report.render_pvalues(a) == report.render_pvalues(b)
    data = json.loads(report.render_json(a))
    assert data["verdict"] == "fail"
    assert data["exact_failures"] == 1
    assert data["exact_failed_families"][0]["mismatches"][0]["key"] == "events"
    rej = next(f for f in data["rejected_families"] if f["block"] == "B6")
    assert rej["holm_rank"] == 1 and rej["holm_threshold"] == pytest.approx(0.01 / a.holm_total)
    assert rej["top_bins"][0]["key"] == "y[40]"
    assert {"candidate", "mean", "z"} <= set(rej["top_bins"][0])
    assert any(label.startswith("dmp @") for label in data["per_kind_energy"])
    text = report.render_text(a)
    assert "VERDICT: FAIL" in text and "Deterministic failures" in text and "y[40]" in text
    assert "Summary per file kind and energy" in text
    assert "\n\n\n" not in text  # no stray blank runs; no timestamps
    ps = json.loads(report.render_pvalues(a))
    assert len(ps["p"]) == a.tested


def test_holm_total_calibration_option(ensemble: tuple[Calibration, Path]) -> None:
    cal, _ = ensemble
    cand = MemoryExtract(draw_run(np.random.default_rng(9), seed=9300))
    scoped = _judge(cal, [cand], files=[DMP])
    assert scoped.holm_total == N_COUNT
    assert (
        _judge(cal, [cand], files=[DMP], holm_total="calibration").holm_total == N_COUNT + N_SCALAR
    )


# ---- CLI ----


def test_cli_end_to_end(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    rng = np.random.default_rng(10)
    members = [
        str(
            write_extract(
                tmp_path / f"m{i}",
                draw_run(rng, n_count=3, n_scalar=1, seed=i),
                tmp_path / "pool",
                seed=i,
            )
        )
        for i in range(8)
    ]
    cal_dir = tmp_path / "cal"
    assert cal_mod.main(["--ensemble", *members, "--out", str(cal_dir), "--jobs", "1"]) == 0
    assert "calibrated" in capsys.readouterr().out
    good = write_extract(
        tmp_path / "good", draw_run(rng, n_count=3, n_scalar=1, seed=99), tmp_path / "pool"
    )
    args = [
        "--calibration",
        str(cal_dir),
        "--candidate-extract",
        str(good),
        "--json",
        str(tmp_path / "v.json"),
        "--text",
        str(tmp_path / "v.txt"),
        "--quiet",
    ]
    assert verdict.main(args) == 0
    assert json.loads((tmp_path / "v.json").read_text())["verdict"] == "pass"
    bad_files = draw_run(rng, n_count=3, n_scalar=1, seed=98)
    bad_files[DMP][Key(DMP, "B0", "#1", "events", ())] = 7
    bad = write_extract(tmp_path / "bad", bad_files, tmp_path / "pool")
    assert (
        verdict.main(["--calibration", str(cal_dir), "--candidate-extract", str(bad), "--quiet"])
        == 1
    )
    wrong = write_extract(
        tmp_path / "wrong",
        draw_run(rng, n_count=3, n_scalar=1),
        tmp_path / "pool",
        input_sha256="e" * 64,
    )
    assert (
        verdict.main(["--calibration", str(cal_dir), "--candidate-extract", str(wrong), "--quiet"])
        == 2
    )
    assert "input hash mismatch" in capsys.readouterr().err
    assert (
        verdict.main(
            ["--calibration", str(tmp_path / "nope"), "--candidate-extract", str(good), "--quiet"]
        )
        == 2
    )
