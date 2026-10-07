# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for ``compare.gates``: aggregation on synthetic inputs and the CLIs on a synthetic set."""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pytest

from compare import gates
from compare.calibrate import calibrate
from compare.tests.synth import SHA, draw_run, write_extract
from compare.tests.test_inject import K, synthetic_run


def test_allowed_failures_matches_the_plan() -> None:
    assert gates.allowed_failures(65) == 3  # plan G3: at most 3 of 65
    assert gates.allowed_failures(60) == 3
    assert gates.allowed_failures(5) == 1
    assert gates.allowed_failures(0) == 0


def test_ks_uniform() -> None:
    rng = np.random.default_rng(1)
    assert gates.ks_uniform(rng.uniform(size=2000)) > 0.01
    assert gates.ks_uniform(rng.uniform(size=2000) ** 4) < 1e-6
    assert np.isnan(gates.ks_uniform([]))


def _record(name: str, kind: str, passed: bool, kinds: dict[str, int]) -> dict[str, object]:
    return {
        "name": name, "kind": kind, "passed": passed, "tested": 10, "rejected": sum(kinds.values()),
        "exact_failures": 0, "per_kind": kinds, "top": [],
    }  # fmt: skip


def test_aggregate_null() -> None:
    records = [_record(f"loo-{i}", "loo", i != 3, {"dmp": 2} if i == 3 else {}) for i in range(60)]
    records += [
        _record("held-a", "held-out", True, {}),
        _record("held-b", "held-out", False, {"out": 1}),
    ]
    ps = [np.array([0.2, 0.7, 1.0, 1.0]), np.array([0.01, 0.5, 0.9])]
    s = gates.aggregate_null(records, ps)
    assert (s["suites"], s["leave_one_out"], s["held_out"], s["failed"]) == (62, 60, 2, 2)
    assert s["failed_names"] == ["loo-3", "held-b"] and s["g3_failures_ok"]
    assert s["failures_per_file_kind"] == {"dmp": 2, "out": 1}
    assert s["pooled_p_values"] == 7 and s["informative_p_values"] == 5
    assert s["fraction_below"]["0.1"] == pytest.approx(1 / 7)
    table = {v["t"]: v for v in s["validity"]}
    assert (
        table[1e-1]["observed"] == 1 and table[1e-2]["observed"] == 1
    )  # 7 values: 0.01, 0.2, 0.5...
    assert all(v["ok"] for v in s["validity"] if v["t"] <= 1e-3)
    many = [_record(f"loo-{i}", "loo", i > 4, {}) for i in range(65)]
    assert not gates.aggregate_null(many, [])["g3_failures_ok"]


def _site(fault: str, ratio_delta: float, detected: bool, right: bool) -> gates.SiteResult:
    return gates.SiteResult(
        fault, "E=1", "1", "f", "b", "g", ["k"], [ratio_delta], [2.0], detected, right, 1e-9
    )


def test_sensitivity_table_criterion() -> None:
    ok = [_site("yield2pct", 4.0, True, True), _site("yield2pct", 0.5, False, False)]
    t = gates.sensitivity_table(ok)
    assert t["g5_ok"] and t["sites_at_least_one_mde"] == 1 and t["missed"] == []
    wrong_place = [*ok, _site("isomer", 9.0, True, False)]
    assert not gates.sensitivity_table(wrong_place)["g5_ok"]
    assert gates.sensitivity_table(wrong_place)["missed"][0]["fault"] == "isomer"
    assert not gates.sensitivity_table([_site("massbin", 0.1, False, False)])[
        "g5_ok"
    ]  # nothing above
    assert _site("massbin", -6.0, True, True).ratio == pytest.approx(3.0)


def test_null_gate_resumes_and_summarizes(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    rng = np.random.default_rng(4)
    members = [
        str(
            write_extract(
                tmp_path / f"m{i}",
                draw_run(rng, n_count=2, n_scalar=1, seed=i),
                tmp_path / "p",
                seed=i,
            )
        )
        for i in range(7)
    ]
    held = str(
        write_extract(
            tmp_path / "held", draw_run(rng, n_count=2, n_scalar=1, seed=99), tmp_path / "p"
        )
    )
    out = tmp_path / "g3"
    args = ["null", "--ensemble", *members, "--held-out", held, "--out", str(out), "--jobs", "1"]
    assert gates.main(args) in (0, 1)
    summary = json.loads((out / "summary.json").read_text())
    assert (summary["leave_one_out"], summary["held_out"], summary["suites"]) == (7, 1, 8)
    assert summary["pooled_p_values"] > 0 and (out / "summary.txt").is_file()
    assert not (out / "cal" / "loo-m0").exists()  # leave-one-out calibrations are removed
    stamp = (out / "results" / "loo-m3.json").stat().st_mtime_ns
    assert gates.main(args) in (0, 1)  # a rerun skips everything done
    assert (out / "results" / "loo-m3.json").stat().st_mtime_ns == stamp
    assert gates.main(["null", "--ensemble", *members[:3], "--out", str(tmp_path / "x")]) == 2


def test_g4_and_sensitivity_gates(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    rng = np.random.default_rng(321)
    members = [
        str(write_extract(tmp_path / f"s{i}", synthetic_run(rng), tmp_path / "pool", seed=i))
        for i in range(K)
    ]
    cal_dir = tmp_path / "cal"
    calibrate(members, cal_dir, jobs=1, mde=[], input_sha256=SHA)
    run = write_extract(tmp_path / "run", synthetic_run(rng), tmp_path / "pool")
    # G4: the detail table lists the energy and its neighbour
    code = gates.main(
        [
            "g4",
            "--calibration",
            str(cal_dir),
            "--candidate",
            str(run),
            "--energy",
            "13",
            "--out",
            str(tmp_path / "g4"),
        ]
    )
    assert code in (0, 1)
    record = json.loads((tmp_path / "g4" / "g4.json").read_text())
    assert {r["energy"] for r in record["energy_detail"]} == {13.0, 14.5}
    assert all(r["median_kappa2"] > 0 for r in record["energy_detail"])
    # G5: all sites of all faults are far above the MDE and must be found in the right place
    out = tmp_path / "g5"
    assert (
        gates.main(
            ["sensitivity", "--calibration", str(cal_dir), "--run", str(run), "--out", str(out)]
        )
        == 0
    )
    table = json.loads((out / "sensitivity.json").read_text())
    assert table["g5_ok"] and table["sites"] == 2 * 2 + 2 * 1 + 2 * 2  # yield2pct, massbin, isomer
    assert {r["fault"] for r in table["rows"]} == {"yield2pct", "massbin", "isomer"}
    assert all(r["right_place"] for r in table["rows"] if (r["delta_over_mde"] or 0) >= 1.0)
    assert not (out / "work" / "yield2pct-000").exists()
