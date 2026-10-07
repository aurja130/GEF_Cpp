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
    "FamilyFit",
    "Judgement",
    "LocalNull",
    "NullParams",
    "VarianceModel",
    "classify_fields",
    "critical_z",
    "file_kind",
    "fit_family",
    "holm",
    "judge_values",
    "local_null",
    "mde_values",
    "print_quantum",
    "variance_model",
]

ALPHA = 0.01
COUNT_LIKE_MIN_FIELDS = 5
FLOOR_QUANTILE = 0.1  # variance floor of count-like groups: this quantile of the positive v
DISPERSION_LIMIT = 10.0  # a count-like group's largest var/mean over their median at most
VAR_SAFETY = 2.0  # standard errors added to the variance of the leave-one-out D
MIN_GLOBAL_FIELDS = 30  # fewer stochastic fields: the family has no global test
MIN_LOO_DRAWS = 3  # fewer valid leave-one-out draws than this: only the local test is used
_CHUNK = 2000  # fields per leave-one-out gather

# Labels whose value is derived from other fields of the same block, so a difference is already
# visible there: dmp ``lo``/``hi`` are the trimmed range of the ``y`` bins (a rare event moves
# them by a whole bin range), and are not tested.
DERIVED_LABELS: dict[str, frozenset[str]] = {"dmp": frozenset({"lo", "hi"})}
SPARSE_RUNS = 5  # a field of a non-count group nonzero in fewer runs has at least the group floor
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
    their values are >= 0, and ``var / mean`` of its fields is consistent with one inflation
    factor: the largest ``var / mean`` is at most ``DISPERSION_LIMIT`` times their median.
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
        ratio = cols.var(axis=0, ddof=1) / cols.mean(axis=0)
        count_like[g] = ratio.max() <= DISPERSION_LIMIT * np.median(ratio)
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
    group_floor: FloatArray  # (R, G): smallest positive v of the group, else the family floor
    floor: FloatArray  # (R,): smallest positive v of the family, NaN if none


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
    ``runs`` ensemble runs. Count-like group: ``v = phi * mean`` with ``phi`` the median of
    ``var / mean`` over the fields of the group with a positive mean. Other groups: ``v = var``.

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
    group_floor = np.full((rows, groups), np.nan)
    v = var.copy()
    if n == 0:
        return VarianceModel(v, phi, group_floor, np.full(rows, np.nan, dtype=np.float64))
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
                phi[:, g] = np.nanmedian(ratio, axis=1)
                v[:, sel] = phi[:, g, None] * m
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
    v = np.where(np.isnan(floor)[:, None], np.nan, v)
    return VarianceModel(v, phi, group_floor, floor)


# --------------------------------------------------------------------------------------------
# §4 null parameters
# --------------------------------------------------------------------------------------------


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
    mode_var: float  # variance of the leading common mode of z (a chi2_1 part of D)


@dataclass
class FamilyFit:
    """The calibration of one family from a ``(K, U)`` ensemble matrix."""

    cls: ClassArray
    mean: FloatArray  # ensemble mean; the value for deterministic fields
    v: FloatArray  # variance model (stochastic and zero fields), 0 elsewhere
    label_floor: FloatArray  # (G,) variance floor per label, used for fields new in a candidate
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
) -> FamilyFit:
    """Classify, fit the variance model and the leave-one-out null of one family.

    ``gid`` is the variance-group (label) id of each of the ``U`` fields; ``ignore`` marks
    derived fields that are not tested.
    """
    runs, u = int(vals.shape[0]), int(vals.shape[1])
    if runs < 4:
        raise ValueError(f"calibration needs at least 4 ensemble runs, got {runs}")
    cls, count_like_g, inflated_g = classify_fields(vals, present, gid, n_groups, ignore)
    stoch = cls == CLS_STOCH
    n_stoch = int(stoch.sum())
    mean = np.where(cls == CLS_ZERO, 0.0, vals[0])
    v_full = np.zeros(u)
    label_floor = np.full(n_groups, np.nan)
    phi = vfloor = float("nan")
    loo_d = np.full(runs, np.nan)
    loo_m = np.full(runs, np.nan)
    z2_sum = z4_sum = 0.0
    z2_count = 0
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
        vfloor = float(model.floor[0])
        zero = cls == CLS_ZERO
        v_full[zero] = model.group_floor[0][gid[zero]]
        has_stoch = np.bincount(gs, minlength=n_groups) > 0
        label_floor = np.where(has_stoch, model.group_floor[0], np.nan)
        big = np.flatnonzero(count_like_g)
        if len(big):
            sizes = np.bincount(gs, minlength=n_groups)
            phi = float(model.phi[0, big[np.argmax(sizes[big])]])
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
        ).v
        z = (sv - m_loo) / np.sqrt(v_loo * (1.0 + 1.0 / (runs - 1)))
        valid = np.all(np.isfinite(z), axis=1)
        z2 = z * z
        loo_d[valid] = z2[valid].sum(axis=1)
        loo_m[valid] = np.abs(z[valid]).max(axis=1)
        z2_sum = float(z2[valid].sum())
        z4_sum = float((z2[valid] ** 2).sum())
        z2_count = int(valid.sum()) * n_stoch
        if n_stoch >= MIN_GLOBAL_FIELDS and int(valid.sum()) > MIN_LOO_DRAWS:
            # the leading mode of the draws (the shared pre-pass shifts every field together)
            zv = z[valid]
            top = np.linalg.svd(zv, full_matrices=False)[2][0]
            proj2[valid] = (zv @ top) ** 2
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
        a = r_var / (2.0 * r_mean)
        nu = 2.0 * r_mean * r_mean / r_var
    n_empirical = int((stoch & ~count_like_g[gid]).sum())
    nu_cap = float(runs - 2) if 2 * n_empirical > n_stoch else float("inf")
    own = local_null(z2_sum, z4_sum, z2_count, nu_cap)
    kappa2 = own.kappa2 if z2_count and not degenerate else float("nan")
    nu_local = own.nu if z2_count and not degenerate else float("nan")
    null = NullParams(
        n_stoch, bool(count_like_g.any()), phi, vfloor, draws, d_mean, d_var, a, nu,
        kappa2, nu_local, degenerate, z2_sum, z4_sum, z2_count, n_empirical, mode_var,
    )  # fmt: skip
    return FamilyFit(cls, mean, v_full, label_floor, null, loo_d, loo_m)


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


def global_sf(d: float, mode_var: float, a: float, nu: float) -> float:
    """``P(mode_var * chi2_1 + a * chi2_nu >= d)``: the null of the global statistic.

    The leading mode is integrated over its normal law; where it alone exceeds ``d`` the
    probability is 1.
    """
    if d <= 0.0:
        return 1.0
    if mode_var <= 0.0:
        return chi2_scaled_sf(d, a, nu)
    t_max = float(np.sqrt(d / mode_var))
    t = 0.5 * t_max * (_GL_X + 1.0)
    rest = gammaincc(nu / 2.0, (d - mode_var * t * t) / (2.0 * a))
    integral = (
        0.5 * t_max * float(np.sum(_GL_W * 2.0 * np.exp(-0.5 * t * t) / np.sqrt(2 * np.pi) * rest))
    )
    return float(min(1.0, integral + 2.0 * ndtr(-t_max)))


def judge_values(
    null: NullParams, z: FloatArray, pool: LocalNull, *, n_extra: int = 0
) -> Judgement:
    """Statistics and the family p-value for the z-scores of the tested fields (§3, §4).

    ``z`` holds every tested field: the stochastic ones, plus zero and new fields where the
    candidate is nonzero; ``n_extra`` is the number of the latter (they widen the Šidák
    multiplicity beyond the ``n_stoch`` fields of the null fit).
    """
    d = float(np.sum(z * z))
    m = float(np.max(np.abs(z))) if len(z) else 0.0
    n_test = null.n_stoch + n_extra
    local = pool if null.degenerate else LocalNull(null.kappa2, null.nu_local)
    p_local = sidak_p(m, local, n_test)
    if null.degenerate:
        return Judgement(d, m, n_test, float("nan"), p_local, p_local, local, z)
    p_global = global_sf(d, null.mode_var, null.a, null.nu)
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
