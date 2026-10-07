# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Sparse count families: exact discrete p for low counts (STATISTICS.md §4, §9).

Histograms of Poisson counts times a quantum, with expected counts per bin from 1500 down to
0.005 (a few events in the whole ensemble in the tail). The p-values must be valid
(``P(p <= t) <= t`` within binomial noise) and planted shifts must be found.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest

from compare import verdict
from compare.calibrate import Calibration, calibrate
from compare.model import Key, Value
from compare.stats import discrete_z
from compare.tests.synth import DMP, SHA, MemoryExtract, binom_interval, write_extract

Q = 1e-4
N_FAM = 6
N_BIN = 60
K = 20


def sparse_run(rng: np.random.Generator, scale_sd: float = 0.0) -> dict[str, dict[Key, Value]]:
    lam = 1500.0 * np.exp(-np.arange(N_BIN) / 5.0) * float(np.exp(scale_sd * rng.standard_normal()))
    table: dict[Key, Value] = {}
    for f in range(N_FAM):
        counts = rng.poisson(lam * (1.0 + 0.3 * f))
        for b, c in enumerate(counts.tolist()):
            if c:
                table[Key(DMP, f"B{f}", "#1", "y", (b,))] = c * Q
        table[Key(DMP, f"B{f}", "#1", "events", ())] = 100000
    return {DMP: table}


def _ensemble(tmp: Path, seed: int, scale_sd: float = 0.0) -> Calibration:
    rng = np.random.default_rng(seed)
    members = [
        str(write_extract(tmp / f"s{i}", sparse_run(rng, scale_sd), tmp / "pool")) for i in range(K)
    ]
    calibrate(members, tmp / "cal", jobs=1, mde=[], input_sha256=SHA)
    return Calibration.open(tmp / "cal")


def test_discrete_z_is_the_conditional_binomial_score() -> None:
    one = np.ones(3)
    # no event seen in 19 runs: one event is p = 2/20 (two-sided), three events p = 2/20**3
    z = discrete_z(np.array([0.0, 1.0, 3.0]), np.zeros(3), 1.0, 19.0, one)
    assert z[0] == 0.0
    assert z[1] == pytest.approx(1.6449, abs=1e-3)  # p = 0.1
    assert z[2] > 3.5
    # symmetric: fewer events than expected gives a negative score
    low = discrete_z(np.array([0.0]), np.array([400.0]), 1.0, 19.0, np.ones(1))
    assert low[0] < -4.0
    # the conservative p is never below the exact one: a rate known from few events is uncertain
    assert discrete_z(np.array([3.0]), np.array([2.0]), 1.0, 17.0, np.ones(1))[0] < 3.3
    # overdispersion (Fano 2) halves the exponent of the tail
    assert (
        discrete_z(np.array([6.0]), np.array([0.0]), 1.0, 19.0, np.array([2.0]))[0]
        < discrete_z(np.array([6.0]), np.array([0.0]), 1.0, 19.0, np.ones(1))[0]
    )


def test_calibration_detects_the_discrete_columns(tmp_path: Path) -> None:
    cal = _ensemble(tmp_path, 1)
    fam = cal.file(DMP).family("B2", "#1")  # type: ignore[union-attr]
    assert fam is not None
    y = fam.labels.index("y")
    assert fam.label_quantum[y] == pytest.approx(Q)
    assert 0.8 <= fam.label_fano[y] <= 1.3
    assert np.isnan(fam.label_quantum[fam.labels.index("events")])


def test_p_values_of_sparse_families_are_valid(tmp_path: Path) -> None:
    pooled: list[float] = []
    for seed in (11, 12, 13):
        sub = tmp_path / str(seed)
        cal = _ensemble(sub, seed)
        rng = np.random.default_rng(100 + seed)
        for _ in range(100):
            pooled.extend(verdict.judge(cal, [MemoryExtract(sparse_run(rng))]).p_values.tolist())
    p = np.array(pooled)
    assert len(p) == 3 * 100 * N_FAM
    for t in (1e-2, 1e-1):
        _, hi = binom_interval(len(p), t)
        assert int(np.sum(p <= t)) <= hi, f"P(p <= {t}) = {np.mean(p <= t):.4f}"
    assert int(np.sum(p <= 1e-3)) <= binom_interval(len(p), 1e-3)[1]
    assert int(np.sum(p <= 1e-4)) <= binom_interval(len(p), 1e-4)[1]


def test_planted_shifts_in_sparse_bins_are_found(tmp_path: Path) -> None:
    cal = _ensemble(tmp_path, 21)
    rng = np.random.default_rng(5)
    # a tail bin (about 0.1 events per run) receives six events
    files = sparse_run(rng)
    files[DMP][Key(DMP, "B3", "#1", "y", (52,))] = 6 * Q
    hit = verdict.judge(cal, [MemoryExtract(files)]).rejected
    assert hit and hit[0].block == "B3" and hit[0].top[0].key == "y[52]"
    # a bin with 10 events per run receives 10 times more
    files = sparse_run(rng)
    key = Key(DMP, "B1", "#1", "y", (22,))
    files[DMP][key] = float(files[DMP].get(key, 0.0)) + 120 * Q  # type: ignore[arg-type]
    hit = verdict.judge(cal, [MemoryExtract(files)]).rejected
    assert hit and hit[0].block == "B1"
    # one stray event in an empty tail bin is not a failure
    files = sparse_run(rng)
    files[DMP][Key(DMP, "B0", "#1", "y", (55,))] = 1 * Q
    assert verdict.judge(cal, [MemoryExtract(files)]).passed


def test_p_values_stay_valid_when_every_run_has_its_own_size(tmp_path: Path) -> None:
    """A shared normalization (the whole histogram a lognormal 15 % larger or smaller) must not
    look like excess events in the low-count bins. Calibrations are pooled (see the lognormal
    test below)."""
    pooled: list[float] = []
    for seed in range(31, 47):
        cal = _ensemble(tmp_path / str(seed), seed, scale_sd=0.15)
        rng = np.random.default_rng(200 + seed)
        for _ in range(40):
            pooled.extend(
                verdict.judge(cal, [MemoryExtract(sparse_run(rng, 0.15))]).p_values.tolist()
            )
    p = np.array(pooled)
    for t in (1e-3, 1e-2, 1e-1):
        assert int(np.sum(p <= t)) <= binom_interval(len(p), t)[1], f"t={t}: {np.mean(p <= t):.4f}"


def overdispersed_run(rng: np.random.Generator, sigma: float) -> dict[str, dict[Key, Value]]:
    """Dense histograms (50 to 5000 counts per bin) times a lognormal per-run factor."""
    lam = 50.0 + 5000.0 * np.exp(-0.5 * ((np.arange(120) - 40) / 15.0) ** 2)
    factor = float(np.exp(sigma * rng.standard_normal()))
    table: dict[Key, Value] = {}
    for f in range(4):
        # the factor of each histogram is the run's own times a smaller one of the histogram
        own = factor * float(np.exp(0.5 * sigma * rng.standard_normal()))
        for b, c in enumerate(rng.poisson(lam * own * (1.0 + 0.2 * f)).tolist()):
            table[Key(DMP, f"B{f}", "#1", "y", (b,))] = c * Q
        table[Key(DMP, f"B{f}", "#1", "events", ())] = 100000
    return {DMP: table}


@pytest.mark.parametrize("sigma", [0.10, 0.20])
def test_p_values_stay_valid_with_a_lognormal_run_factor(tmp_path: Path, sigma: float) -> None:
    """Validity holds across ensembles (a calibration whose K factors happen to scatter little is
    invalid on its own; the Student t amplitude makes the mixture valid), so many calibrations
    with a few suites each are pooled."""
    pooled: list[float] = []
    for seed in range(40, 56):
        rng = np.random.default_rng(seed)
        sub = tmp_path / f"{sigma}-{seed}"
        members = [
            str(write_extract(sub / f"s{i}", overdispersed_run(rng, sigma), sub / "pool"))
            for i in range(K)
        ]
        calibrate(members, sub / "cal", jobs=1, mde=[], input_sha256=SHA)
        cal = Calibration.open(sub / "cal")
        fam = cal.file(DMP).family("B1", "#1")  # type: ignore[union-attr]
        assert fam is not None and fam.null.psi >= 0.0
        for _ in range(40):
            pooled.extend(
                verdict.judge(cal, [MemoryExtract(overdispersed_run(rng, sigma))]).p_values.tolist()
            )
    p = np.array(pooled)
    for t in (1e-3, 1e-2, 1e-1):
        assert int(np.sum(p <= t)) <= binom_interval(len(p), t)[1], f"t={t}: {np.mean(p <= t):.4f}"


def test_the_quadratic_term_is_found_in_a_calibration(tmp_path: Path) -> None:
    rng = np.random.default_rng(57)
    members = [
        str(write_extract(tmp_path / f"s{i}", overdispersed_run(rng, 0.2), tmp_path / "pool"))
        for i in range(K)
    ]
    calibrate(members, tmp_path / "cal", jobs=1, mde=[], input_sha256=SHA)
    fam = Calibration.open(tmp_path / "cal").file(DMP).family("B1", "#1")  # type: ignore[union-attr]
    assert fam is not None and 0.01 < fam.null.psi < 0.2
    assert fam.null.mode_dof == pytest.approx(K - 2)


def test_a_planted_shift_is_still_found_with_a_run_factor(tmp_path: Path) -> None:
    rng = np.random.default_rng(51)
    members = [
        str(write_extract(tmp_path / f"s{i}", overdispersed_run(rng, 0.15), tmp_path / "pool"))
        for i in range(K)
    ]
    calibrate(members, tmp_path / "cal", jobs=1, mde=[], input_sha256=SHA)
    cal = Calibration.open(tmp_path / "cal")
    files = overdispersed_run(rng, 0.15)
    key = Key(DMP, "B2", "#1", "y", (40,))
    files[DMP][key] = float(files[DMP][key]) * 3.0  # type: ignore[operator]
    hit = verdict.judge(cal, [MemoryExtract(files)]).rejected
    assert hit and hit[0].block == "B2"
