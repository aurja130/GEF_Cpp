# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Statistical kernels of ``compare`` (STATISTICS.md §1 to §6), free of any file handling.

Everything here works on one family at a time with plain arrays, so that ``calibrate`` (fitting),
``verdict`` (judging) and the tests share exactly one implementation:

* ``fit_family``: field classes (§1), means and variance model (§2), leave-one-out draws and the
  fitted null parameters (§4) of one family from its ``(K, U)`` ensemble matrix;
* ``judge_values``: the statistics (§3) and p-values (§4) of a candidate against a fit;
* ``holm``: the step-down procedure (§5);
* ``critical_z`` / ``mde_values``: the minimum detectable effect (§6).
"""

from __future__ import annotations

import fnmatch
import warnings
from dataclasses import dataclass
from functools import lru_cache

import numpy as np
from numpy.typing import NDArray
from scipy.special import gammaincc as _gammaincc  # pyright: ignore[reportMissingTypeStubs]
from scipy.special import ndtr as _ndtr  # pyright: ignore[reportMissingTypeStubs]
from scipy.special import ndtri as _ndtri  # pyright: ignore[reportMissingTypeStubs]
from scipy.stats import binom as _binom  # pyright: ignore[reportMissingTypeStubs]
from scipy.stats import t as _student_t  # pyright: ignore[reportMissingTypeStubs]

from compare.loader import PARSER_NAMES, parser_modules

__all__ = [
    "ALPHA",
    "CLS_DET",
    "CLS_IGN",
    "CLS_STOCH",
    "CLS_ZERO",
    "COUNT_LIKE_MIN_FIELDS",
    "DERIVED_LABELS",
    "DISPERSION_LIMIT",
    "FLOOR_QUANTILE",
    "INTEGRAL_TOL",
    "PSI_MIN_FIELDS",
    "SAMPLE_C",
    "SPARSE_MEAN",
    "STRUCTURAL_TEXT",
    "UNTESTED_KINDS",
    "FamilyFit",
    "Judgement",
    "LocalNull",
    "NullParams",
    "VarianceModel",
    "apply_quantum_hint",
    "classify_fields",
    "critical_z",
    "discrete_z",
    "field_fano",
    "file_kind",
    "fit_family",
    "fit_phi_psi",
    "group_quantum",
    "holm",
    "judge_values",
    "local_null",
    "mde_values",
    "print_quantum",
    "run_scale",
    "t_equivalent",
    "variance_model",
]

ALPHA = 0.01
COUNT_LIKE_MIN_FIELDS = 5
FLOOR_QUANTILE = 0.1  # variance floor of count-like groups: this quantile of the positive v
DISPERSION_LIMIT = 10.0  # a count-like group's largest var/mean over their median at most
VAR_SAFETY = 2.0  # standard errors added to the variance of the leave-one-out D
SAMPLE_C = 1.0  # a count-like field whose c * sample variance exceeds the model takes the t law
SPARSE_MEAN = 20.0  # expected counts per run below which a count field uses its exact discrete p
MAX_FANO = 3.0  # a count-like group more overdispersed than this is not treated as counts
MAX_CHECKED = 1000.0  # ratios above this (in quanta) are not used to test for whole numbers
INTEGRAL_TOL = 0.02  # a value is a whole number of quanta within this (plus 1e-4 relative)
PSI_MIN_FIELDS = 20  # dense fields needed to fit the quadratic variance term
MODE_MIN_RESIDUAL = 1e-3  # mean z^2 per dense field that must be left after the mode
MODE_SPREAD = 0.25  # participation ratio / fields needed to treat the leading mode as common
MIN_GLOBAL_FIELDS = 30  # fewer stochastic fields: the family has no global test
MIN_LOO_DRAWS = 3  # fewer valid leave-one-out draws than this: only the local test is used
_CHUNK = 2000  # fields per leave-one-out gather

# Labels whose value is derived from other fields of the same block, so a difference is already
# visible there: dmp ``lo``/``hi`` are the trimmed range of the ``y`` bins (a rare event moves
# them by a whole bin range), and are not tested.
DERIVED_LABELS: dict[str, frozenset[str]] = {"dmp": frozenset({"lo", "hi"})}
SPARSE_RUNS = 5  # a field of a non-count group nonzero in fewer runs has at least the group floor
# File kinds whose varying numbers are log lines (counts of messages, timings, nuclide lists whose
# length depends on the run): not tested. Their constants are still exact.
UNTESTED_KINDS = frozenset({"text"})
# Text labels whose constant value is structure, not data: a candidate that differs there is not
# a stochastic outcome (an analyzer title, an axis name, the file version, the range line). Every
# other constant of the ensemble, numeric or text, is judged with the rule of succession.
STRUCTURAL_TEXT: dict[str, frozenset[str]] = {
    "dmp": frozenset({"title", "xaxis", "yaxis", "version", "range"})
}
ZERO_INFLATED_FRACTION = 0.0  # share of zero entries above which a non-count group is zero-inflated

CLS_DET = 0  # identical in all K runs: must match exactly
CLS_STOCH = 1  # numeric, varies: statistical test
CLS_ZERO = 2  # zero in every run (absent or present): statistical test via the variance floor
CLS_IGN = 3  # varies but not finite: not tested

type FloatArray = NDArray[np.float64]
type BoolArray = NDArray[np.bool_]
type ClassArray = NDArray[np.int8]


# scipy has no type stubs; these shims are the only places that call it.


def gammaincc(a: float, x: float | FloatArray) -> FloatArray:
    """Regularized upper incomplete gamma function Q(a, x), elementwise."""
    return np.asarray(_gammaincc(a, x), dtype=np.float64)  # pyright: ignore[reportUnknownArgumentType]


def ndtr(x: float) -> float:
    """Standard normal CDF."""
    return float(_ndtr(x))  # pyright: ignore[reportUnknownArgumentType]


def ndtri(q: float) -> float:
    """Standard normal quantile."""
    return float(_ndtri(q))  # pyright: ignore[reportUnknownArgumentType]


def binom_sf(k: FloatArray, n: FloatArray, p: float | FloatArray) -> FloatArray:
    """``P(X > k)`` for ``X ~ Binomial(n, p)``, elementwise."""
    return np.asarray(_binom.sf(k, n, p), dtype=np.float64)  # pyright: ignore[reportUnknownMemberType, reportUnknownArgumentType]


def binom_cdf(k: FloatArray, n: FloatArray, p: float | FloatArray) -> FloatArray:
    """``P(X <= k)`` for ``X ~ Binomial(n, p)``, elementwise."""
    return np.asarray(_binom.cdf(k, n, p), dtype=np.float64)  # pyright: ignore[reportUnknownMemberType, reportUnknownArgumentType]


def ndtri_array(q: FloatArray) -> FloatArray:
    """Standard normal quantile, elementwise."""
    return np.asarray(_ndtri(q), dtype=np.float64)  # pyright: ignore[reportUnknownArgumentType]


def student_pdf(x: FloatArray, nu: float) -> FloatArray:
    """Density of Student's t with ``nu`` degrees of freedom, elementwise."""
    return np.asarray(_student_t.pdf(x, nu), dtype=np.float64)  # pyright: ignore[reportUnknownMemberType, reportUnknownArgumentType]


def student_sf_array(x: FloatArray, nu: float) -> FloatArray:
    """Survival function of Student's t with ``nu`` degrees of freedom, elementwise."""
    return np.asarray(_student_t.sf(x, nu), dtype=np.float64)  # pyright: ignore[reportUnknownMemberType, reportUnknownArgumentType]


def student_sf(x: float, nu: float) -> float:
    """Survival function of Student's t with ``nu`` degrees of freedom."""
    return float(_student_t.sf(x, nu))  # pyright: ignore[reportUnknownMemberType, reportUnknownArgumentType]


def student_isf(q: float, nu: float) -> float:
    """Inverse survival function of Student's t."""
    return float(_student_t.isf(q, nu))  # pyright: ignore[reportUnknownMemberType, reportUnknownArgumentType]


@lru_cache(maxsize=1)
def _patterns() -> tuple[tuple[str, tuple[str, ...]], ...]:
    return tuple((name, tuple(mod.PATTERNS)) for name, mod in parser_modules(PARSER_NAMES))


def file_kind(rel: str) -> str:
    """The parser kind (``dmp``, ``endf``, ``out``, ...) that claims a run-relative path."""
    for name, patterns in _patterns():
        if any(fnmatch.fnmatchcase(rel, p) for p in patterns):
            return name
    return "other"


# --------------------------------------------------------------------------------------------
# §1 field classes
# --------------------------------------------------------------------------------------------


def classify_fields(
    vals: FloatArray,
    present: BoolArray,
    gid: NDArray[np.int64],
    n_groups: int,
    ignore: BoolArray | None = None,
) -> tuple[ClassArray, BoolArray, BoolArray]:
    """Field classes of a ``(K, U)`` ensemble matrix and which variance groups are count-like.

    Returns ``(cls, count_like, zero_inflated)``; ``ignore`` marks derived fields (not tested).

    ``vals`` is zero-filled where ``present`` is false. A *variance group* is the set of fields
    of one label (``gid`` is the label id, ``n_groups`` the number of labels): the columns of one
    table have different scales and only fields of one column share a variance law.

    A field identical (bitwise) in all runs is deterministic, except a field that is zero in
    every run when it is absent in some run, or when its group has a stochastic field (a table
    column): that is ``CLS_ZERO``, a statistical field with mean 0 (a bin that happened to stay
    empty). A field that varies is stochastic if
    finite in all runs, else ignored.

    A group is count-like if it has at least ``COUNT_LIKE_MIN_FIELDS`` stochastic fields, all
    their values are >= 0, and ``var / mean`` of its fields is consistent with ``phi + psi * mean``
    (``fit_phi_psi``): the largest ratio of ``var / mean`` to it is at most ``DISPERSION_LIMIT``.
    Columns of conditional means (zero in empty bins, a typical value elsewhere) fail the last
    test. A table column that is not count-like and has more than ``ZERO_INFLATED_FRACTION``
    zero entries is *zero-inflated*:
    each field is zero or typical depending on whether its bin received events, so the variance
    model adds an occupancy term (``variance_model``).
    """
    bits = vals.view(np.uint64)
    identical = np.all(bits == bits[0], axis=0)
    allpresent = np.all(present, axis=0)
    finite = np.all(np.isfinite(vals), axis=0)
    cls = np.full(vals.shape[1], CLS_DET, dtype=np.int8)
    skip = np.zeros(vals.shape[1], dtype=bool) if ignore is None else ignore
    stoch = ~identical & finite & ~skip
    cls[~identical & ~finite] = CLS_IGN
    cls[stoch] = CLS_STOCH
    count = np.bincount(gid[stoch], minlength=n_groups)
    negative = np.any(vals[:, stoch] < 0.0, axis=0)
    has_negative = np.bincount(gid[stoch][negative], minlength=n_groups) > 0
    table_like = count >= COUNT_LIKE_MIN_FIELDS
    count_like = table_like & ~has_negative
    sv = vals[:, stoch]
    gs = gid[stoch]
    for g in np.flatnonzero(count_like):
        cols = sv[:, gs == g]
        mean_g = cols.mean(axis=0)
        ratio = cols.var(axis=0, ddof=1) / mean_g
        dense = np.count_nonzero(cols, axis=0) >= SPARSE_RUNS
        phi_g, psi_g = fit_phi_psi(mean_g[None, :], ratio[None, :], dense[None, :])
        expected = phi_g[0] + psi_g[0] * mean_g  # phi + psi * mean: the dispersion of this column
        count_like[g] = bool(expected.min() > 0.0 and np.max(ratio / expected) <= DISPERSION_LIMIT)
    zero_inflated = np.zeros(n_groups, dtype=bool)
    for g in np.flatnonzero(table_like & ~count_like):
        cols = sv[:, gs == g]
        zero_inflated[g] = (
            float(np.count_nonzero(cols == 0.0)) / max(cols.size, 1) > ZERO_INFLATED_FRACTION
        )
    zero = identical & (bits[0] == 0)
    cls[zero & (~allpresent | (count[gid] >= 1))] = CLS_ZERO
    cls[skip] = CLS_IGN
    return cls, count_like, zero_inflated


# --------------------------------------------------------------------------------------------
# §2 variance model
# --------------------------------------------------------------------------------------------


@dataclass
class VarianceModel:
    """Variances of ``R`` independent rows of ``n`` fields (rows: the full ensemble, or each
    leave-one-out ensemble)."""

    v: FloatArray  # (R, n), NaN rows where no floor exists
    phi: FloatArray  # (R, G): inflation of count-like groups, NaN elsewhere
    psi: FloatArray  # (R, G): quadratic (run-to-run scale) term of count-like groups
    group_floor: FloatArray  # (R, G): smallest positive v of the group, else the family floor
    floor: FloatArray  # (R,): smallest positive v of the family, NaN if none
    sample: BoolArray  # (R, n): the field's own sample variance rules (t law, see t_equivalent)


def fit_phi_psi(
    m: FloatArray, ratio: FloatArray, dense: BoolArray
) -> tuple[FloatArray, FloatArray]:
    """Robust fit of ``var / mean = phi + psi * mean`` for ``R`` rows of ``n`` fields.

    ``ratio`` is ``var / mean`` (NaN where the mean is 0) and ``dense`` marks the well-populated
    fields. ``psi >= 0`` is the slope between the lowest and highest quartile of the means of the
    dense fields (medians of both coordinates); ``phi`` is the median of ``ratio - psi * mean``.
    With fewer than ``PSI_MIN_FIELDS`` dense fields in some row, ``psi = 0`` and ``phi`` is the
    plain median of ``ratio``.
    """
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", RuntimeWarning)
        phi = np.nanmedian(ratio, axis=1)
        psi = np.zeros(m.shape[0])
        if int(dense.sum(axis=1).min()) >= PSI_MIN_FIELDS:
            dense_m = np.where(dense, m, np.nan)
            lo_q, hi_q = np.nanquantile(dense_m, [0.25, 0.75], axis=1)
            in_lo = dense_m <= lo_q[:, None]
            in_hi = dense_m >= hi_q[:, None]
            m_lo = np.nanmedian(np.where(in_lo, m, np.nan), axis=1)
            m_hi = np.nanmedian(np.where(in_hi, m, np.nan), axis=1)
            r_lo = np.nanmedian(np.where(in_lo, ratio, np.nan), axis=1)
            r_hi = np.nanmedian(np.where(in_hi, ratio, np.nan), axis=1)
            slope = (r_hi - r_lo) / np.where(m_hi > m_lo, m_hi - m_lo, np.nan)
            psi = np.where(np.isfinite(slope), np.maximum(slope, 0.0), 0.0)
            resid = np.where(dense, ratio - psi[:, None] * m, np.nan)
            phi = np.maximum(np.nanmedian(resid, axis=1), 0.05 * r_lo)
    return phi, psi


def variance_model(
    mean: FloatArray,
    var: FloatArray,
    peak: FloatArray,
    occupied: FloatArray,
    nonzero_mean: FloatArray,
    gid: NDArray[np.int64],
    count_like: BoolArray,
    zero_inflated: BoolArray,
    runs: int,
    fallback_var: FloatArray | None = None,
) -> VarianceModel:
    """Per-field variance ``v`` and per-group floors (§2) for ``R`` rows of ``n`` fields.

    ``mean``, ``var``, ``peak`` (largest absolute value), ``occupied`` (number of nonzero runs)
    and ``nonzero_mean`` (mean over the nonzero runs) are ``(R, n)``, each row computed from
    ``runs`` ensemble runs. Count-like group: ``v = phi * mean + psi * mean^2``. ``psi >= 0`` is
    the slope of ``var / mean`` against ``mean`` between the lowest and highest quartile of the
    well-populated fields (0, and ``phi`` the plain median of ``var / mean``, with fewer than
    ``PSI_MIN_FIELDS`` of them), ``phi`` the median of ``var / mean - psi * mean``: a run-to-run
    scale factor (a perturbed parameter set) multiplies all counts and makes the variance grow
    faster than Poisson. Other groups: ``v = var``.

    The *group floor* is the variance of a field of the group that has not been seen nonzero in
    the ensemble (a zero field, or a field new in the candidate). For a count-like group it is
    the larger of the ``FLOOR_QUANTILE`` quantile of its positive ``v`` and ``q^2 / runs``, ``q``
    the ``FLOOR_QUANTILE`` quantile of the fields' nonzero means (one event of the smallest
    typical size per ``runs`` runs). For another group it is ``peak^2 / runs``:
    an occupancy event of at most the largest value seen in the group, with probability of order
    ``1 / runs`` per run. A group without a floor uses the family floor (the smallest group
    floor).

    A field that is nonzero in fewer than ``SPARSE_RUNS`` runs has at least the group floor: a
    handful of values say little about their scale (and a count-like group's bulk can be far
    below Poisson while its rare bins are single events).
    A field of a zero-inflated group has ``v >= nonzero_mean^2 * p * (1 - p)`` with the Laplace
    occupancy ``p = (occupied + 1) / (runs + 2)``: a bin that was filled in every run can still be
    empty in the next one, which ``var`` alone does not allow for. A field never seen nonzero uses
    the group floor.

    ``fallback_var`` (``(n,)``, the variance of the whole ensemble) replaces a zero ``var`` of a
    field of a non-count-like group: a leave-one-out ensemble in which a field is constant gives
    no information on its scale, and the full ensemble is the only source for it.
    """
    rows, n = int(mean.shape[0]), int(mean.shape[1])
    groups = len(count_like)
    phi = np.full((rows, groups), np.nan)
    psi = np.zeros((rows, groups))
    group_floor = np.full((rows, groups), np.nan)
    v = var.copy()
    if n == 0:
        return VarianceModel(
            v, phi, psi, group_floor, np.full(rows, np.nan, dtype=np.float64),
            np.zeros((rows, 0), dtype=bool),
        )  # fmt: skip
    if fallback_var is not None:
        plain = ~count_like[gid]
        v[:, plain] = np.where(v[:, plain] == 0.0, fallback_var[plain][None, :], v[:, plain])
    order = np.argsort(gid, kind="stable")
    sorted_gid = gid[order]
    starts = np.flatnonzero(np.r_[True, sorted_gid[1:] != sorted_gid[:-1]])
    ends = np.r_[starts[1:], n]
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", RuntimeWarning)
        for lo, hi in zip(starts, ends, strict=True):
            g = int(sorted_gid[lo])
            sel = order[lo:hi]
            if count_like[g]:
                m = mean[:, sel]
                positive = m > 0.0
                ratio = np.where(positive, var[:, sel] / np.where(positive, m, 1.0), np.nan)
                dense = positive & (occupied[:, sel] >= SPARSE_RUNS)
                phi[:, g], psi[:, g] = fit_phi_psi(m, ratio, dense)
                v[:, sel] = phi[:, g, None] * m + psi[:, g, None] * m * m
                vs = np.where(v[:, sel] > 0.0, v[:, sel], np.nan)
                quantum = np.nanquantile(
                    np.where(occupied[:, sel] > 0.0, np.abs(nonzero_mean[:, sel]), np.nan),
                    FLOOR_QUANTILE,
                    axis=1,
                )
                group_floor[:, g] = np.fmax(
                    np.nanquantile(vs, FLOOR_QUANTILE, axis=1), quantum * quantum / runs
                )
            else:
                top = peak[:, sel].max(axis=1)
                group_floor[:, g] = np.where(top > 0.0, top * top / runs, np.nan)
        floor = np.nanmin(group_floor, axis=1) if groups else np.full(rows, np.nan)
    group_floor = np.where(np.isnan(group_floor), floor[:, None], group_floor)
    with np.errstate(invalid="ignore"):
        inflated = zero_inflated[gid]
        if inflated.any():
            occ = occupied[:, inflated]
            p = (occ + 1.0) / (runs + 2.0)
            seen = nonzero_mean[:, inflated] ** 2 * p * (1.0 - p)
            seen = np.where(occ > 0.0, seen, group_floor[:, gid[inflated]])
            v[:, inflated] = np.maximum(v[:, inflated], seen)
        sparse = occupied < SPARSE_RUNS
        v = np.where(sparse, np.maximum(v, group_floor[:, gid]), v)
    # never let the column model under-state a cell's own spread (heavy per-cell dispersion:
    # perturbed parameters acting on single bins): v = max(model, c * s^2) for count-like fields,
    # and the field is judged by its own sample variance with a t law. The fields of a column that
    # is not made of counts already have v = s^2 and take the t law whenever nothing raised v.
    dense = occupied >= SPARSE_RUNS
    count_cols = count_like[gid][None, :]
    with np.errstate(invalid="ignore"):
        sample = (
            dense & (var > 0.0) & np.where(count_cols, SAMPLE_C * var > v, v <= var * (1 + 1e-9))
        )
        v = np.where(sample & count_cols, np.maximum(v, SAMPLE_C * var), v)
    # a variance is never zero: estimates of 0 (a column constant in a leave-one-out ensemble, a
    # phi of 0) take the floor of their group; without any floor the field is not testable (NaN)
    v = np.where(v > 0.0, v, group_floor[:, gid])
    v = np.where(v > 0.0, v, np.nan)
    v = np.where(np.isnan(floor)[:, None], np.nan, v)
    return VarianceModel(v, phi, psi, group_floor, floor, sample & ~np.isnan(v))


# --------------------------------------------------------------------------------------------
# §4 null parameters
# --------------------------------------------------------------------------------------------


def _whole_multiples(ratio: FloatArray, minimum: int = 5) -> bool:
    """At least 99.5 % of the small ratios (at most ``MAX_CHECKED`` quanta, at least ``minimum``
    of them) are whole numbers: counts times a quantum. Large ratios cannot be told from whole
    numbers by printed digits and are not used."""
    small = ratio[ratio <= MAX_CHECKED]
    if len(small) < max(minimum, 1):
        return minimum == 0
    whole = np.abs(small - np.rint(small)) <= INTEGRAL_TOL + 1e-5 * small
    return float(np.count_nonzero(whole)) / len(small) >= 0.995


def group_quantum(
    sv: FloatArray,
    gs: NDArray[np.int64],
    count_like: BoolArray,
    phi: FloatArray,
    psi: FloatArray,
) -> tuple[FloatArray, FloatArray]:
    """Event quantum and Fano factor per count-like variance group, NaN elsewhere.

    The quantum ``q`` is the smallest positive value of the group; the group is *discrete* if
    at least 99.5 % of its nonzero values are whole multiples of ``q`` (counts times a
    normalization, such as 1 / events). The Fano factor ``phi / q`` is 1 for Poisson counts and
    ``phi / q + psi * n`` for a field of ``n`` counts; a group whose factor at ``SPARSE_MEAN``
    counts exceeds ``MAX_FANO`` is not treated as counts.
    """
    groups = len(count_like)
    quantum = np.full(groups, np.nan)
    fano = np.full(groups, np.nan)
    for g in np.flatnonzero(count_like):
        cols = sv[:, gs == g]
        positive = cols[cols > 0.0]
        if not len(positive):
            continue
        q = float(positive.min())
        f = float(phi[g]) / q if np.isfinite(phi[g]) else float("nan")
        edge = max(1.0, f) + float(psi[g]) * SPARSE_MEAN  # dispersion at the largest low count
        if _whole_multiples(positive / q) and edge <= MAX_FANO:
            quantum[g], fano[g] = q, f
    return quantum, fano


def apply_quantum_hint(
    quantum: FloatArray,
    fano: FloatArray,
    vals: FloatArray,
    gid: NDArray[np.int64],
    hint: FloatArray,
    phi: FloatArray,
    psi: FloatArray,
) -> None:
    """Give small groups the quantum of the same label in larger families of the file.

    A histogram column with a handful of stochastic fields cannot show its own quantum, but
    the events normalization is the same for every analyzer of a file. The hint is accepted if
    the group's positive values are whole multiples of it (or it has none) and the group's own
    dispersion at that quantum is within ``MAX_FANO`` as for a quantum of its own (a column
    that is overdispersed against Poisson stays on the Gaussian path).
    """
    for g in np.flatnonzero(np.isfinite(hint) & ~np.isfinite(quantum)):
        cols = vals[:, gid == g]
        positive = cols[cols > 0.0]
        if len(positive) and not _whole_multiples(positive / hint[g], minimum=0):
            continue
        f = float(phi[g]) / hint[g] if np.isfinite(phi[g]) else 1.0
        if max(1.0, f) + float(psi[g]) * SPARSE_MEAN > MAX_FANO:
            continue
        quantum[g], fano[g] = hint[g], f


def run_scale(sv: FloatArray, quantum: FloatArray) -> FloatArray:
    """Size of each run's histogram against the mean of the other runs (leave-one-out).

    ``sv`` is ``(K, n)``; only the fields with a finite ``quantum`` count (events summed over the
    discrete columns). Clipped to [0.2, 5].
    """
    cols = np.isfinite(quantum)
    if not cols.any():
        return np.ones(int(sv.shape[0]), dtype=np.float64)
    total: FloatArray = np.sum(sv[:, cols] / quantum[cols], axis=1)
    others = (total.sum() - total) / (len(total) - 1)
    ratio = np.where(others > 0.0, total / np.where(others > 0.0, others, 1.0), 1.0)
    return np.asarray(np.clip(ratio, 0.2, 5.0), dtype=np.float64)


def t_equivalent(z: FloatArray, dof: float) -> FloatArray:
    """Normal-equivalent score of a Student t statistic: ``sign(z) * Phi^-1(1 - P(|t| > |z|) / 2)``.

    ``z`` is a deviation in units of the field's *sample* standard deviation (with the 1/m + 1/K
    factor), a t variable with ``dof`` degrees of freedom under the null. The score is bounded by
    about 37 (probabilities below 1e-300 are not distinguished).
    """
    p = 2.0 * student_sf_array(np.abs(z), dof)
    return np.sign(z) * -ndtri_array(np.maximum(p / 2.0, 1e-300))


def field_fano(fano: FloatArray, psi: FloatArray, counts: FloatArray) -> FloatArray:
    """Dispersion of a field of ``counts`` expected events: ``max(1, phi / q + psi * counts)``."""
    return np.maximum(1.0, fano + psi * counts)


def discrete_z(
    counts: FloatArray,
    ensemble: FloatArray,
    cand_runs: float | FloatArray,
    ens_runs: float,
    fano: FloatArray,
) -> FloatArray:
    """Normal-equivalent score of the exact discrete two-sided p of a low-count field.

    Given Poisson rates, the candidate's ``counts`` (summed over ``cand_runs`` runs) and the
    ensemble's ``ensemble`` total (over ``ens_runs`` runs) are conditionally binomial: the
    candidate share of ``counts + ensemble`` is ``Binomial(n, cand_runs / (cand_runs + ens_runs))``.
    The p-value ``min(1, 2 min(P(X >= c), P(X <= c)))`` is conservative (discrete), so the score
    ``Phi^-1(1 - p / 2)`` is no larger than a true normal one; this also accounts for the
    uncertainty of a rate known from a few events. An overdispersed group (Fano > 1) gets
    ``p ** (1 / fano)``.
    """
    c = np.rint(counts)
    n = c + np.rint(ensemble)
    prob = cand_runs / (cand_runs + ens_runs)
    p_hi = binom_sf(c - 1.0, n, prob)
    p_lo = binom_cdf(c, n, prob)
    p = np.clip(2.0 * np.minimum(p_hi, p_lo), 0.0, 1.0)
    p = np.where(n > 0.0, p, 1.0) ** (1.0 / fano)
    z = -ndtri_array(np.maximum(p / 2.0, 1e-300))
    return np.where(c >= n * prob, z, -z)


@dataclass
class NullParams:
    """Fitted null distribution of one family's statistics."""

    n_stoch: int
    count_like: bool  # at least one count-like variance group
    phi: float  # inflation of the largest count-like group (NaN if none)
    vfloor: float  # smallest positive variance of the family (NaN if none)
    n_draws: int  # valid leave-one-out draws
    d_mean: float
    d_var: float
    a: float
    nu: float
    kappa2: float  # NaN when the family is degenerate (the pooled value of its file kind is used)
    nu_local: float  # Student dof of the local tail (inf: Gaussian); NaN when degenerate
    degenerate: bool
    z2_sum: float  # sums of z^2 and z^4 and the number of z over the draws, to pool the local
    z4_sum: float  # tail over a file kind
    z2_count: int
    n_empirical: int  # stochastic fields whose variance is the sample variance (not Poisson-shaped)
    n_sparse: int  # stochastic fields judged by their exact discrete p (low counts)
    od_num: float  # sum of squared deviations of the low-count fields from their ensemble mean
    od_den: float  # and its Poisson expectation: their ratio is the clustering of events
    mode_var: float  # variance of the leading common mode of z (a chi2_1 part of D)
    psi: float = 0.0  # quadratic variance term of the largest count-like group
    mode_dof: float = float("inf")  # degrees of freedom of the common-mode amplitude (K - 2)


@dataclass
class FamilyFit:
    """The calibration of one family from a ``(K, U)`` ensemble matrix."""

    cls: ClassArray
    mean: FloatArray  # ensemble mean; the value for deterministic fields
    v: FloatArray  # variance model (stochastic and zero fields), 0 elsewhere
    label_floor: FloatArray  # (G,) variance floor per label, used for fields new in a candidate
    label_quantum: FloatArray  # (G,) event quantum of discrete count groups, else NaN
    label_fano: FloatArray  # (G,) phi / q of those groups (the Fano factor of one event)
    label_psi: FloatArray  # (G,) quadratic dispersion of those groups (counts^2 term)
    mode: FloatArray  # (U,) unit loadings of the leading common mode of the dense fields
    s2: FloatArray  # (U,) sample variance of the fields judged by it (t law), 0 elsewhere
    fcell: FloatArray  # (U,) empirical Fano factor s^2 / (m q) of the low-count fields, 0 elsewhere
    null: NullParams
    loo_d: FloatArray  # (K,) NaN for invalid draws
    loo_m: FloatArray


def _occupancy(vals: FloatArray) -> tuple[FloatArray, FloatArray]:
    """Number of nonzero runs and mean over those runs, per field of ``(R, n)`` or ``(K, n)``."""
    occupied = np.count_nonzero(vals, axis=0).astype(np.float64)
    total = vals.sum(axis=0)
    return occupied, np.where(occupied > 0.0, total / np.maximum(occupied, 1.0), 0.0)


def _loo_moments(
    vals: FloatArray,
) -> tuple[FloatArray, FloatArray, FloatArray, FloatArray, FloatArray]:
    """Mean, variance (ddof=1), peak |value|, occupied runs and nonzero mean of the K - 1 other
    runs of each left-out run."""
    runs, n = int(vals.shape[0]), int(vals.shape[1])
    others: NDArray[np.int64] = (np.arange(runs)[:, None] + 1 + np.arange(runs - 1)[None, :]) % runs
    mean = np.empty((runs, n))
    var = np.empty((runs, n))
    peak = np.empty((runs, n))
    occupied = np.empty((runs, n))
    nonzero_mean = np.empty((runs, n))
    for start in range(0, n, _CHUNK):
        sub = vals[others, start : start + _CHUNK]
        cols = slice(start, start + _CHUNK)
        mean[:, cols] = sub.mean(axis=1)
        var[:, cols] = sub.var(axis=1, ddof=1)
        peak[:, cols] = np.abs(sub).max(axis=1)
        occupied[:, cols] = np.count_nonzero(sub, axis=1)
        nonzero_mean[:, cols] = np.where(
            occupied[:, cols] > 0, sub.sum(axis=1) / np.maximum(occupied[:, cols], 1.0), 0.0
        )
    return mean, var, peak, occupied, nonzero_mean


def fit_family(
    vals: FloatArray,
    present: BoolArray,
    gid: NDArray[np.int64],
    n_groups: int,
    ignore: BoolArray | None = None,
    untested: bool = False,
    quantum_hint: FloatArray | None = None,
) -> FamilyFit:
    """Classify, fit the variance model and the leave-one-out null of one family.

    ``gid`` is the variance-group (label) id of each of the ``U`` fields; ``ignore`` marks
    derived fields that are not tested; ``untested`` turns every varying field into an ignored one.
    """
    runs, u = int(vals.shape[0]), int(vals.shape[1])
    if runs < 4:
        raise ValueError(f"calibration needs at least 4 ensemble runs, got {runs}")
    cls, count_like_g, inflated_g = classify_fields(vals, present, gid, n_groups, ignore)
    if untested:
        cls[(cls == CLS_STOCH) | (cls == CLS_ZERO)] = CLS_IGN
    stoch = cls == CLS_STOCH
    n_stoch = int(stoch.sum())
    mean = np.where(cls == CLS_ZERO, 0.0, vals[0])
    v_full = np.zeros(u)
    label_floor = np.full(n_groups, np.nan)
    quantum_g = np.full(n_groups, np.nan)
    fano_g = np.full(n_groups, np.nan)
    psi_g = np.zeros(n_groups)
    phi = vfloor = float("nan")
    psi_main = 0.0
    overdispersed = False
    loo_d = np.full(runs, np.nan)
    loo_m = np.full(runs, np.nan)
    z2_sum = z4_sum = 0.0
    z2_count = 0
    n_sparse = 0
    od_num = od_den = 0.0
    s2_cell = np.zeros(u)
    fcell = np.zeros(u)
    mode = np.zeros(u)  # loadings of the leading common mode of the dense fields
    proj2 = np.zeros(runs)  # squared projection of each leave-one-out z on the leading mode
    if n_stoch:
        sv = vals[:, stoch]
        gs = gid[stoch]
        m_full = sv.mean(axis=0)
        s2_full = sv.var(axis=0, ddof=1)
        peak_full = np.abs(sv).max(axis=0)
        occ_full, nzm_full = _occupancy(sv)
        model = variance_model(
            m_full[None, :],
            s2_full[None, :],
            peak_full[None, :],
            occ_full[None, :],
            nzm_full[None, :],
            gs,
            count_like_g,
            inflated_g,
            runs,
        )
        mean[stoch] = m_full
        v_full[stoch] = model.v[0]
        s2_cell[stoch] = np.where(model.sample[0], s2_full, 0.0)
        vfloor = float(model.floor[0])
        zero = cls == CLS_ZERO
        v_full[zero] = model.group_floor[0][gid[zero]]
        has_stoch = np.bincount(gs, minlength=n_groups) > 0
        label_floor = np.where(has_stoch, model.group_floor[0], np.nan)
        zero_floor = np.where(np.isfinite(label_floor), label_floor, model.group_floor[0])
        v_full[zero] = zero_floor[gid[zero]]
        big = np.flatnonzero(count_like_g)
        if len(big):
            sizes = np.bincount(gs, minlength=n_groups)
            main = big[np.argmax(sizes[big])]
            phi = float(model.phi[0, main])
            psi_main = float(model.psi[0, main])
            overdispersed = psi_main * float(np.median(m_full[gs == main])) >= phi > 0.0
        # leave-one-out: run j as a single candidate against the other K - 1 runs
        m_loo, s2_loo, peak_loo, occ_loo, nzm_loo = _loo_moments(sv)
        v_loo = variance_model(
            m_loo,
            s2_loo,
            peak_loo,
            occ_loo,
            nzm_loo,
            gs,
            count_like_g,
            inflated_g,
            runs - 1,
            s2_full,
        )
        z = (sv - m_loo) / np.sqrt(v_loo.v * (1.0 + 1.0 / (runs - 1)))
        # fields judged by their own spread (t law of K - 2 dof), also in a draw whose own
        # estimate is not larger than the model: the full ensemble decides which fields they are
        own_t = v_loo.sample | (model.sample[0][None, :] & (s2_loo > 0.0))
        if own_t.any():
            with np.errstate(invalid="ignore", divide="ignore"):
                z_t = (sv - m_loo) / np.sqrt(
                    np.where(own_t, s2_loo, 1.0) * (1.0 + 1.0 / (runs - 1))
                )
            z = np.where(own_t, t_equivalent(z_t, runs - 2.0), z)
        psi_g = np.where(np.isfinite(model.psi[0]), model.psi[0], 0.0)
        quantum_g, fano_g = group_quantum(sv, gs, count_like_g, model.phi[0], psi_g)
        if quantum_hint is not None:
            apply_quantum_hint(quantum_g, fano_g, vals, gid, quantum_hint, model.phi[0], psi_g)
        # a column that is not counts has no one-event scale: an unseen field can be as large as
        # the largest field of the column (deterministic ones included), once in K runs
        peak_group = np.zeros(n_groups)
        np.maximum.at(peak_group, gid, np.abs(vals).max(axis=0))
        label_floor = np.where(
            has_stoch & ~np.isfinite(quantum_g),
            np.fmax(label_floor, peak_group**2 / runs),
            label_floor,
        )
        zero_floor = np.where(np.isfinite(label_floor), label_floor, model.group_floor[0])
        v_full[zero] = zero_floor[gid[zero]]
        q_f = quantum_g[gs]
        # low counts get their exact discrete p unless the cell's own spread says it is not Poisson
        # (a cell of 20 expected counts with a variance/mean of 12 is judged by the t law above)
        sparse = (
            np.isfinite(q_f)
            & (m_full <= SPARSE_MEAN * np.where(np.isfinite(q_f), q_f, 1.0))
            & ~model.sample[0]
        )
        if sparse.any():  # exact discrete p for low counts, as a normal-equivalent score
            counts = np.rint(sv[:, sparse] / q_f[sparse])
            rest = counts.sum(axis=0)[None, :] - counts
            # the whole histogram is larger or smaller in a run (shared normalization): the
            # share of one run in a bin is scaled by that run's size against the others
            scale = run_scale(sv, q_f)
            fano_f = field_fano(fano_g[gs][sparse], psi_g[gs][sparse], m_full[sparse] / q_f[sparse])
            # a cell that spikes in a few runs (a cluster of events: 183 and 194 counts in 2 of 20
            # runs, 0 elsewhere) is overdispersed by its own account: Fano = s^2 / (m q), from the
            # runs the draw is compared with
            qs = q_f[sparse]
            m_o = m_loo[:, sparse] / qs
            s2_o = s2_loo[:, sparse] / (qs * qs)
            own_fano = np.where(m_o > 0.0, s2_o / np.where(m_o > 0.0, m_o, 1.0), 1.0)
            fano_draw = np.maximum(fano_f[None, :], own_fano)
            z[:, sparse] = discrete_z(counts, rest, scale[:, None], runs - 1.0, fano_draw)
            m_all = m_full[sparse] / qs
            fcell[np.flatnonzero(stoch)[sparse]] = np.where(
                m_all > 0.0, s2_full[sparse] / (qs * qs) / np.where(m_all > 0.0, m_all, 1.0), 1.0
            )
        valid = np.all(np.isfinite(z), axis=1)
        z2 = z * z
        loo_d[valid] = z2[valid].sum(axis=1)
        n_sparse = int(sparse.sum())
        z_loc = z
        if n_stoch >= MIN_GLOBAL_FIELDS and int(valid.sum()) > MIN_LOO_DRAWS:
            # the leading mode of the draws (the shared pre-pass shifts every field together)
            zv = z[valid]
            top = np.linalg.svd(zv, full_matrices=False)[2][0]
            proj2[valid] = (zv @ top) ** 2
            # the local test is judged on the dense fields with their own leading mode removed:
            # the mode belongs to the global test, and it would otherwise make the local law so
            # heavy that a single shifted bin could not be seen (STATISTICS.md section 4)
            dense_cols = np.flatnonzero(~sparse)
            zd = z[valid][:, dense_cols] if len(dense_cols) >= MIN_GLOBAL_FIELDS else None
            top_d = np.linalg.svd(zd, full_matrices=False)[2][0] if zd is not None else None
            # a *common* mode has loadings spread over the fields (participation ratio of at
            # least a quarter of them); one concentrated on a few fields is an event in those
            # bins (an edge bin of a table), and one that leaves no noise behind (a family of
            # perfectly correlated fields: Epart of XE.dmp, mean z^2 left per field under
            # MODE_MIN_RESIDUAL) would give a residual law of numerical noise: neither is
            # projected out
            if (
                zd is not None
                and top_d is not None
                and 1.0 / float(np.sum(top_d**4)) >= MODE_SPREAD * len(dense_cols)
                and float(np.sum(zd**2) - np.sum((zd @ top_d) ** 2)) >= MODE_MIN_RESIDUAL * zd.size
            ):
                # each draw is projected with the mode of the *other* draws, as a fresh run is
                # (projecting with its own would remove noise and make the local law too narrow)
                resid = np.empty_like(zd)
                for i in range(len(zd)):
                    others = np.delete(zd, i, axis=0)
                    top_i = np.linalg.svd(others, full_matrices=False)[2][0]
                    resid[i] = zd[i] - float(zd[i] @ top_i) * top_i
                z_loc = z.copy()
                z_loc[np.ix_(valid, dense_cols)] = resid
                mode_s = np.zeros(n_stoch)
                mode_s[dense_cols] = top_d
                mode[stoch] = mode_s
        # the local null is that of the well-populated fields; low counts carry their exact p
        zd2 = (z_loc * z_loc)[:, ~sparse]
        if zd2.shape[1]:
            loo_m[valid] = np.sqrt(zd2[valid].max(axis=1))
        else:
            loo_m[valid] = 0.0
        z2_sum = float(zd2[valid].sum())
        z4_sum = float((zd2[valid] ** 2).sum())
        z2_count = int(valid.sum()) * int(zd2.shape[1])
        if sparse.any():
            low = np.rint(sv[:, sparse] / q_f[sparse])
            od_num = float(((low - low.mean(axis=0)) ** 2).sum())
            od_den = float(low.mean(axis=0).sum()) * (runs - 1)
    ok = np.isfinite(loo_d)
    draws = int(ok.sum())
    d_mean = float(loo_d[ok].mean()) if draws else float("nan")
    d_var = float(loo_d[ok].var(ddof=1)) if draws > 1 else float("nan")
    degenerate = not (
        n_stoch >= MIN_GLOBAL_FIELDS and draws >= MIN_LOO_DRAWS and d_mean > 0.0 and d_var > 0.0
    )
    a = nu = float("nan")
    mode_var = 0.0
    if not degenerate:
        # D = (leading mode)^2 + rest: the mode is a chi2_1 (a shared shift, heavy tail), the
        # rest a sum of many fields, matched by a scaled chi2. A variance estimated from few
        # draws is itself uncertain, so both are taken on their upper side.
        safety = float(np.sqrt(2.0 / (draws - 1)))
        mode_var = float(proj2[ok].mean()) * (1.0 + VAR_SAFETY * safety)
        rest = loo_d[ok] - proj2[ok]
        r_mean = float(rest.mean())
        r_var = max(float(rest.var(ddof=1)) * (1.0 + VAR_SAFETY * safety), 1e-12 * r_mean**2)
        if r_mean > 0.0:
            a = r_var / (2.0 * r_mean)
            nu = 2.0 * r_mean * r_mean / r_var
        else:  # the mode explains all of D: no scale for the rest, only the local test
            degenerate = True
    n_empirical = int((stoch & ~count_like_g[gid]).sum())
    # a quantity estimated from K runs has a t tail: variances that are sample variances, and the
    # shared run-to-run factor (psi) of overdispersed counts
    nu_cap = float(runs - 2) if 2 * n_empirical > n_stoch or overdispersed else float("inf")
    own = local_null(z2_sum, z4_sum, z2_count, nu_cap)
    kappa2 = own.kappa2 if z2_count and not degenerate else float("nan")
    nu_local = own.nu if z2_count and not degenerate else float("nan")
    null = NullParams(
        n_stoch, bool(count_like_g.any()), phi, vfloor, draws, d_mean, d_var, a, nu,
        kappa2, nu_local, degenerate, z2_sum, z4_sum, z2_count, n_empirical, n_sparse,
        od_num, od_den, mode_var, psi_main, float(max(runs - 2, 3)),
    )  # fmt: skip
    if quantum_hint is not None and not n_stoch:
        apply_quantum_hint(
            quantum_g, fano_g, vals, gid, quantum_hint, np.full(n_groups, np.nan), psi_g
        )
    return FamilyFit(
        cls,
        mean,
        v_full,
        label_floor,
        quantum_g,
        fano_g,
        psi_g,
        mode,
        s2_cell,
        fcell,
        null,
        loo_d,
        loo_m,
    )


# --------------------------------------------------------------------------------------------
# §3 and §4 judging
# --------------------------------------------------------------------------------------------


@dataclass
class Judgement:
    """Statistics and p-values of one family for one candidate."""

    d: float
    m: float
    n_test: int
    p_global: float
    p_local: float
    p: float
    local: LocalNull
    z: FloatArray


@dataclass(frozen=True)
class LocalNull:
    """Null law of one standardized field: ``N(0, kappa2)`` or a scaled Student t."""

    kappa2: float  # variance of the field's z
    nu: float  # degrees of freedom of the Student t tail; inf means Gaussian

    @property
    def scale(self) -> float:
        if not np.isfinite(self.nu):
            return float(np.sqrt(self.kappa2))
        return float(np.sqrt(self.kappa2 * (self.nu - 2.0) / self.nu))

    def two_sided(self, x: float) -> float:
        """``P(|z| >= x)``."""
        if self.scale <= 0.0:
            return 1.0 if x <= 0.0 else 0.0
        if not np.isfinite(self.nu):
            return 2.0 * ndtr(-x / self.scale)
        return 2.0 * student_sf(x / self.scale, self.nu)

    def quantile(self, q: float) -> float:
        """``x`` with ``P(|z| >= x) = q``."""
        if not np.isfinite(self.nu):
            return self.scale * -ndtri(q / 2.0)
        return self.scale * student_isf(q / 2.0, self.nu)


NU_MIN = 4.1  # the heaviest tail allowed: kurtosis is capped at 3 + 6 / (NU_MIN - 4)
NU_GAUSSIAN = 200.0  # kurtosis within 3 + 6 / (200 - 4) of 3 counts as Gaussian


def local_null(z2_sum: float, z4_sum: float, count: int, nu_max: float = float("inf")) -> LocalNull:
    """Moment-matched local null from the sums of ``z^2`` and ``z^4`` of the leave-one-out draws.

    The variance is ``mean z^2``. The tail is a Student t whose kurtosis ``3 + 6 / (nu - 4)``
    equals the observed ``mean z^4 / (mean z^2)^2``: rare large z (discrete counts, a variance
    estimated from few runs) make the tail heavier than the Gaussian one, and the maximum over
    thousands of fields then exceeds the Gaussian expectation by orders of magnitude.

    ``nu_max`` bounds the degrees of freedom from above: a z whose variance was estimated from
    ``K`` runs is a t variable with about ``K - 2`` degrees of freedom whatever a short sample of
    draws suggests.
    """
    if count <= 0 or z2_sum <= 0.0:
        return LocalNull(1.0, float("inf"))
    kappa2 = z2_sum / count
    kurt = (z4_sum / count) / (kappa2 * kappa2)
    if kurt <= 3.0 + 6.0 / (NU_GAUSSIAN - 4.0):
        return LocalNull(kappa2, nu_max)
    return LocalNull(kappa2, min(nu_max, max(NU_MIN, 4.0 + 6.0 / (kurt - 3.0))))


def sidak_p(m: float, local: LocalNull, n: int) -> float:
    """``1 - (1 - P(|z| >= m))^n``: the max over n independent fields exceeds m."""
    if n <= 0 or not np.isfinite(m):
        return 1.0
    q = local.two_sided(m)
    if q >= 1.0:
        return 1.0
    if q <= 0.0:
        return 0.0
    return float(min(1.0, -np.expm1(n * np.log1p(-q))))


def chi2_scaled_sf(d: float, a: float, nu: float) -> float:
    """``P(a * chi2_nu >= d)``."""
    return float(gammaincc(nu / 2.0, max(d, 0.0) / (2.0 * a)))


_GL_X, _GL_W = np.polynomial.legendre.leggauss(256)


def global_sf(
    d: float, mode_var: float, a: float, nu: float, mode_dof: float = float("inf")
) -> float:
    """``P(mode_var * x^2 + a * chi2_nu >= d)``: the null of the global statistic.

    ``x`` is the amplitude of the leading common mode, of unit variance: normal, or, with
    ``mode_dof`` finite, a scaled Student t. A shared factor is estimated from K runs only, so a
    fresh run's amplitude in units of the ensemble's spread is a t variable with K - 2 degrees of
    freedom (the pivotal law that makes the p-value valid across ensembles). Where the mode alone
    exceeds ``d`` the probability is 1.
    """
    if d <= 0.0:
        return 1.0
    if mode_var <= 0.0:
        return chi2_scaled_sf(d, a, nu)
    t_max = float(np.sqrt(d / mode_var))
    x = 0.5 * t_max * (_GL_X + 1.0)
    rest = gammaincc(nu / 2.0, (d - mode_var * x * x) / (2.0 * a))
    if np.isfinite(mode_dof):
        scale = float(np.sqrt((mode_dof - 2.0) / mode_dof))
        density = 2.0 * student_pdf(x / scale, mode_dof) / scale
        tail = 2.0 * student_sf(t_max / scale, mode_dof)
    else:
        density = 2.0 * np.exp(-0.5 * x * x) / np.sqrt(2.0 * np.pi)
        tail = 2.0 * ndtr(-t_max)
    integral = 0.5 * t_max * float(np.sum(_GL_W * density * rest))
    return float(min(1.0, integral + tail))


def judge_values(
    null: NullParams,
    z: FloatArray,
    pool: LocalNull,
    *,
    n_extra: int = 0,
    sparse: BoolArray | None = None,
    n_extra_sparse: int = 0,
    clustering: float = 1.0,
    mode: FloatArray | None = None,
) -> Judgement:
    """Statistics and the family p-value for the z-scores of the tested fields (§3, §4).

    ``z`` holds every tested field: the stochastic ones, plus zero and new fields where the
    candidate is nonzero; ``n_extra`` is the number of the latter (they widen the Šidák
    multiplicity beyond the ``n_stoch`` fields of the null fit). ``sparse`` flags the entries
    that are normal-equivalent scores of exact discrete p-values (low counts); ``n_extra_sparse``
    of the extras are such. Their maximum is judged by its own Šidák term, the others by the
    fitted local law, and the two are combined as independent tests.
    """
    d = float(np.sum(z * z))
    m = float(np.max(np.abs(z))) if len(z) else 0.0
    n_test = null.n_stoch + n_extra
    local = pool if null.degenerate else LocalNull(null.kappa2, null.nu_local)
    flags = np.zeros(len(z), dtype=bool) if sparse is None else sparse
    n_sparse = null.n_sparse + n_extra_sparse
    n_dense = n_test - n_sparse
    z_dense = z[~flags]
    if mode is not None and len(z_dense) and float(np.dot(mode[~flags], mode[~flags])) > 0.0:
        load = mode[~flags]
        z_dense = z_dense - float(np.dot(z_dense, load)) * load  # global test's part
    z_sparse = z[flags]
    m_dense = float(np.max(np.abs(z_dense))) if len(z_dense) else 0.0
    m_sparse = float(np.max(np.abs(z_sparse))) if len(z_sparse) else 0.0
    p_dense = sidak_p(m_dense, local, n_dense) if len(z_dense) else 1.0
    p_sparse = 1.0
    if len(z_sparse):
        # events that come in clusters make low counts more dispersed than Poisson (``clustering``,
        # measured on the ensemble): the exact p is raised to 1 / clustering
        exact = sidak_p(m_sparse, LocalNull(1.0, float("inf")), n_sparse)
        p_sparse = exact ** (1.0 / max(clustering, 1.0))
    both = len(z_dense) > 0 and len(z_sparse) > 0  # two tests: Sidak over the smaller p
    p_local = 1.0 - (1.0 - min(p_dense, p_sparse)) ** (2 if both else 1)
    if len(z) == 0:
        p_local = 1.0
    if null.degenerate:
        return Judgement(d, m, n_test, float("nan"), p_local, p_local, local, z)
    p_global = global_sf(d, null.mode_var, null.a, null.nu, null.mode_dof)
    p = min(1.0, 2.0 * min(p_global, p_local))
    return Judgement(d, m, n_test, p_global, p_local, p, local, z)


# --------------------------------------------------------------------------------------------
# §5 Holm
# --------------------------------------------------------------------------------------------


def holm(
    p: NDArray[np.float64], alpha: float = ALPHA, total: int | None = None
) -> tuple[NDArray[np.int64], FloatArray, BoolArray]:
    """Holm step-down over ``total`` hypotheses (default ``len(p)``).

    Returns ``(order, threshold, rejected)``: the indices of ``p`` sorted ascending (ties by
    index), the threshold ``alpha / (total - rank + 1)`` of each sorted rank, and, per sorted
    rank, whether it is rejected (every lower rank must have rejected too). The hypotheses
    missing from ``p`` (``total > len(p)``) are those that cannot reject (p = 1).
    """
    n_total = len(p) if total is None else total
    if n_total < len(p):
        raise ValueError("total must be at least the number of p-values")
    order = np.argsort(p, kind="stable").astype(np.int64)
    ranks = np.arange(1, len(p) + 1)
    threshold = np.asarray(alpha / (n_total - ranks + 1.0), dtype=np.float64)
    passes = p[order] <= threshold
    rejected = np.cumprod(passes).astype(bool)
    return order, threshold, rejected


# --------------------------------------------------------------------------------------------
# §6 minimum detectable effect
# --------------------------------------------------------------------------------------------


def print_quantum(x: FloatArray) -> FloatArray:
    """Resolution a value was printed with: the smallest ``10^-d`` (``d`` = 0 to 17) such that
    rounding to ``d`` decimals leaves it unchanged."""
    quantum = np.full(x.shape, 1e-17)
    done = ~np.isfinite(x)
    for d in range(18):
        hit = ~done & (np.round(x, d) == x)
        quantum[hit] = 10.0**-d
        done |= hit
    return quantum


def critical_z(alpha_family: float, n_fields: int, local: LocalNull) -> float:
    """``t*`` with ``1 - (1 - P(|z| >= t*))^n = alpha_family`` under the local null."""
    if n_fields <= 0:
        return float("inf")
    q = -np.expm1(np.log1p(-alpha_family) / n_fields)
    return local.quantile(float(q))


def mde_values(
    v: FloatArray, mean: FloatArray, runs: int, candidate_runs: int, t_star: float
) -> tuple[FloatArray, FloatArray]:
    """MDE in value units and relative to the field mean (NaN where the mean is 0)."""
    absolute = t_star * np.sqrt(v * (1.0 / candidate_runs + 1.0 / runs))
    with np.errstate(divide="ignore", invalid="ignore"):
        relative = np.where(mean != 0.0, absolute / np.abs(mean), np.nan)
    return absolute, relative
