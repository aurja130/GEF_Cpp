# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the statistical kernels (``compare.stats``) on hand-made and drawn data."""

from __future__ import annotations

import math

import numpy as np
import pytest

from compare.stats import (
    CLS_DET,
    CLS_IGN,
    CLS_STOCH,
    CLS_ZERO,
    LocalNull,
    chi2_scaled_sf,
    classify_fields,
    critical_z,
    file_kind,
    fit_family,
    global_sf,
    holm,
    judge_values,
    local_null,
    mde_values,
    print_quantum,
    sidak_p,
    variance_model,
)


def _gid(n: int) -> np.ndarray:
    return np.zeros(n, dtype=np.int64)


# ---- Holm -----------------------------------------------------------------------------------


def test_holm_all_rejected_in_order() -> None:
    p = np.array([0.02, 0.001, 0.004, 0.5])
    order, threshold, rejected = holm(p, alpha=0.05)
    assert order.tolist() == [1, 2, 0, 3]
    assert threshold.tolist() == pytest.approx([0.05 / 4, 0.05 / 3, 0.05 / 2, 0.05])
    assert rejected.tolist() == [True, True, True, False]


def test_holm_stops_at_first_failure() -> None:
    # rank 2 fails (0.02 > 0.05 / 3), so rank 3 cannot reject although 0.021 <= 0.05 / 2
    p = np.array([0.001, 0.02, 0.021, 0.9])
    _, _, rejected = holm(p, alpha=0.05)
    assert rejected.tolist() == [True, False, False, False]


def test_holm_total_larger_than_listed() -> None:
    # 10 hypotheses of which two are listed (the rest cannot reject): thresholds 0.005, 0.0056
    p = np.array([0.006, 0.004])
    order, threshold, rejected = holm(p, alpha=0.05, total=10)
    assert order.tolist() == [1, 0]
    assert threshold.tolist() == pytest.approx([0.005, 0.05 / 9])
    assert rejected.tolist() == [True, False]
    with pytest.raises(ValueError, match="total"):
        holm(p, total=1)


def test_holm_ties_keep_input_order() -> None:
    order, _, _ = holm(np.array([0.3, 0.1, 0.1]), alpha=0.05)
    assert order.tolist() == [1, 2, 0]


# ---- Šidák, local null, combination ------------------------------------------------------------


def test_sidak_matches_closed_form() -> None:
    local = LocalNull(1.0, float("inf"))
    m, n = 3.0, 50
    q = math.erfc(m / math.sqrt(2))
    assert sidak_p(m, local, n) == pytest.approx(1 - (1 - q) ** n, rel=1e-9)
    assert sidak_p(0.0, local, n) == 1.0
    assert sidak_p(5.0, local, 0) == 1.0
    kappa = LocalNull(4.0, float("inf"))
    assert sidak_p(6.0, kappa, 7) == pytest.approx(sidak_p(3.0, local, 7))


def test_local_null_gaussian_and_heavy() -> None:
    rng = np.random.default_rng(1)
    z = rng.standard_normal(200_000)
    gauss = local_null(float((z**2).sum()), float((z**4).sum()), len(z))
    assert gauss.kappa2 == pytest.approx(1.0, rel=0.02)
    assert math.isinf(gauss.nu)
    t = rng.standard_t(6, 400_000)
    heavy = local_null(float((t**2).sum()), float((t**4).sum()), len(t))
    assert heavy.kappa2 == pytest.approx(6 / 4, rel=0.1)
    assert 4.1 <= heavy.nu < 100  # kurtosis of t6 is 6, i.e. nu = 6 by the moment formula
    # a heavier tail gives a larger p for the same maximum
    assert sidak_p(6.0, heavy, 1000) > sidak_p(6.0, gauss, 1000)
    assert local_null(0.0, 0.0, 0) == LocalNull(1.0, float("inf"))


def test_critical_z_inverts_sidak() -> None:
    local = LocalNull(1.3, 8.0)
    for n, alpha in [(5, 0.01), (500, 1e-4)]:
        t_star = critical_z(alpha, n, local)
        assert sidak_p(t_star, local, n) == pytest.approx(alpha, rel=1e-6)
    assert math.isinf(critical_z(0.01, 0, local))


def test_judge_values_combines_with_bonferroni() -> None:
    rng = np.random.default_rng(2)
    vals = rng.poisson(50.0, size=(20, 60)).astype(float)
    fit = fit_family(vals, np.ones_like(vals, dtype=bool), _gid(60), 1)
    pool = LocalNull(1.0, float("inf"))
    z = np.zeros(60)
    quiet = judge_values(fit.null, z, pool)
    assert quiet.p == 1.0
    z[3] = 8.0
    j = judge_values(fit.null, z, pool)
    assert j.p == pytest.approx(min(1.0, 2 * min(j.p_global, j.p_local)))
    assert j.p < 1e-6
    assert j.m == 8.0 and j.d == 64.0


def test_degenerate_family_uses_local_test_only() -> None:
    rng = np.random.default_rng(3)
    vals = rng.standard_normal((20, 3)) + 10.0
    fit = fit_family(vals, np.ones_like(vals, dtype=bool), _gid(3), 1)
    assert fit.null.degenerate
    pool = LocalNull(1.2, float("inf"))
    j = judge_values(fit.null, np.array([4.0, 0.0, 0.0]), pool)
    assert math.isnan(j.p_global)
    assert j.p == j.p_local == pytest.approx(sidak_p(4.0, pool, 3))


# ---- field classes --------------------------------------------------------------------------


def test_classify_deterministic_zero_stochastic_ignored() -> None:
    k = 6
    vals = np.zeros((k, 6))
    present = np.ones((k, 6), dtype=bool)
    vals[:, 0] = 7.5  # identical everywhere: deterministic
    vals[:, 1] = [1, 2, 3, 4, 5, 6]  # varies: stochastic
    vals[:, 2] = 0.0  # zero everywhere, present: deterministic (no stochastic sibling)
    vals[:, 3] = [0, 0, 0, 0, 0, 0]
    present[:3, 3] = False  # absent in some runs, zero in the rest: a zero field
    vals[:, 4] = [1, 2, 3, 4, 5, np.nan]  # varies and not finite: ignored
    vals[:, 5] = [1, 1, 1, 1, 1, 2]
    gid = np.array([0, 1, 2, 3, 4, 5])
    cls, count_like, inflated = classify_fields(vals, present, gid, 6)
    assert cls.tolist() == [CLS_DET, CLS_STOCH, CLS_DET, CLS_ZERO, CLS_IGN, CLS_STOCH]
    assert not count_like.any() and not inflated.any()


def test_zero_in_a_table_column_is_statistical() -> None:
    rng = np.random.default_rng(4)
    vals = rng.poisson(30.0, size=(10, 12)).astype(float)
    vals[:, 5] = 0.0  # a bin that stayed empty in every run, same column as stochastic bins
    cls, count_like, _ = classify_fields(vals, np.ones_like(vals, dtype=bool), _gid(12), 1)
    assert cls[5] == CLS_ZERO
    assert count_like[0]


def test_count_like_needs_five_nonnegative_consistent_fields() -> None:
    rng = np.random.default_rng(5)
    present = np.ones((20, 8), dtype=bool)
    poisson = rng.poisson(40.0, size=(20, 8)).astype(float)
    assert classify_fields(poisson, present, _gid(8), 1)[1][0]
    assert not classify_fields(poisson[:, :4], present[:, :4], _gid(4), 1)[1][0]
    negative = poisson - 41.0
    assert not classify_fields(negative, present, _gid(8), 1)[1][0]
    # variance proportional to the square of the mean (a conditional mean) is not Poisson-shaped
    scale = np.array([1, 10, 100, 1000, 1e4, 1e5, 1e6, 1e7])
    wide = rng.standard_normal((20, 8)) * scale + 3 * scale
    wide = np.abs(wide)
    assert not classify_fields(wide, present, _gid(8), 1)[1][0]


def test_ignore_marks_derived_fields() -> None:
    vals = np.array([[1.0, 2.0], [1.0, 3.0], [2.0, 4.0], [2.0, 5.0], [1.0, 6.0]])
    present = np.ones_like(vals, dtype=bool)
    cls, _, _ = classify_fields(vals, present, _gid(2), 1, np.array([True, False]))
    assert cls.tolist() == [CLS_IGN, CLS_STOCH]


# ---- variance model and fit -------------------------------------------------------------------


def test_variance_model_poisson_shape_recovers_phi() -> None:
    rng = np.random.default_rng(6)
    runs, n, quantum = 200, 400, 0.01
    lam = np.linspace(5, 500, n)
    counts = rng.poisson(lam, size=(runs, n))
    vals = counts * quantum
    mean = vals.mean(0)[None, :]
    var = vals.var(0, ddof=1)[None, :]
    occ = np.count_nonzero(vals, axis=0).astype(float)[None, :]
    model = variance_model(
        mean, var, np.abs(vals).max(0)[None, :], occ, mean, _gid(n), np.array([True]),
        np.array([False]), runs,
    )  # fmt: skip
    assert model.phi[0, 0] == pytest.approx(quantum, rel=0.1)  # var = quantum * mean
    assert model.v[0] == pytest.approx(quantum * mean[0], rel=0.05)


def test_fit_null_distribution_of_d_matches_fitted_chi2() -> None:
    """The leave-one-out D of a Gaussian family is chi2 with n degrees of freedom (scaled)."""
    rng = np.random.default_rng(7)
    runs, n = 40, 60
    vals = rng.standard_normal((runs, n)) * 2.0 + 5.0
    fit = fit_family(vals, np.ones_like(vals, dtype=bool), _gid(n), 1)
    null = fit.null
    assert not null.degenerate
    assert null.n_stoch == n
    # E[D] = n (1 + 1/K') (K' - 1)/(K' - 3): z = (x - mean)/s with K' = runs - 1
    kp = runs - 1
    expected = n * (kp - 1) / (kp - 3)
    assert null.d_mean == pytest.approx(expected, rel=0.2)
    # D = leading mode + rest: the two parts (taken on their upper side) cover the mean of D
    assert 0.0 < null.mode_var < null.d_mean
    assert null.a * null.nu + null.mode_var >= 0.95 * null.d_mean
    assert null.kappa2 == pytest.approx(expected / n, rel=0.1)


def test_zero_field_variance_is_the_group_floor() -> None:
    rng = np.random.default_rng(8)
    vals = rng.poisson(20.0, size=(12, 10)).astype(float) * 0.5
    vals[:, 9] = 0.0
    fit = fit_family(vals, np.ones_like(vals, dtype=bool), _gid(10), 1)
    assert fit.cls[9] == CLS_ZERO
    assert fit.mean[9] == 0.0
    assert fit.v[9] > 0.0
    assert fit.v[9] == pytest.approx(fit.label_floor[0])


def test_constant_in_leave_one_out_uses_full_variance() -> None:
    """A field that is constant in K - 1 runs but differs in one must not blow up D."""
    rng = np.random.default_rng(9)
    vals = rng.standard_normal((20, 12)) + 50.0
    vals[:, 0] = 4.0
    vals[7, 0] = 5.0  # one run differs
    fit = fit_family(vals, np.ones_like(vals, dtype=bool), _gid(12), 1)
    assert fit.cls[0] == CLS_STOCH
    assert np.all(np.isfinite(fit.loo_d))
    assert fit.loo_d.max() < 1e3


def test_mde_scales_with_runs_and_alpha() -> None:
    v = np.array([4.0])
    mean = np.array([100.0])
    local = LocalNull(1.0, float("inf"))
    t1 = critical_z(0.01 / 1000, 50, local)
    a1, r1 = mde_values(v, mean, 20, 1, t1)
    a4, _ = mde_values(v, mean, 20, 4, t1)
    assert a1[0] == pytest.approx(t1 * 2.0 * math.sqrt(1 + 1 / 20))
    assert r1[0] == pytest.approx(a1[0] / 100)
    assert a4[0] < a1[0]
    assert a4[0] == pytest.approx(t1 * 2.0 * math.sqrt(1 / 4 + 1 / 20))
    assert critical_z(0.01 / 100, 50, local) < t1


# ---- small helpers --------------------------------------------------------------------------


def test_print_quantum() -> None:
    x = np.array([3.37, 1e-5, 1234567.0, 0.5, 2.0, 0.1 + 0.2, np.inf])
    q = print_quantum(x)
    assert q[:5].tolist() == pytest.approx([0.01, 1e-5, 1.0, 0.1, 1.0])
    assert q[5] < 1e-15  # not a short decimal: effectively exact


def test_file_kind_dispatch() -> None:
    assert file_kind("work/dmp/Z86_A215_n_E13MeV/Apost.dmp") == "dmp"
    assert file_kind("work/out/GEF_86_215_n.dat") == "out"
    assert file_kind("stdout.log") in {"text", "other"}


def test_global_null_is_a_mode_plus_chi2_mixture() -> None:
    d = 40.0
    assert global_sf(d, 0.0, 2.0, 10.0) == pytest.approx(chi2_scaled_sf(d, 2.0, 10.0))
    assert global_sf(0.0, 3.0, 2.0, 10.0) == 1.0
    rng = np.random.default_rng(11)
    draws = 3.0 * rng.standard_normal(2_000_000) ** 2 + 2.0 * rng.chisquare(10.0, 2_000_000)
    for q in (0.5, 0.99, 0.999):
        x = float(np.quantile(draws, q))
        assert global_sf(x, 3.0, 2.0, 10.0) == pytest.approx(1 - q, rel=0.1)
    # the mode makes the far tail heavier than a chi2 with the same mean and variance
    mean, var = 3.0 + 20.0, 2 * 9.0 + 2 * 4.0 * 10.0
    nu = 2 * mean**2 / var
    assert global_sf(150.0, 3.0, 2.0, 10.0) > chi2_scaled_sf(150.0, var / (2 * mean), nu)
