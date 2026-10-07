# Statistical design of `compare` (M2)

This is the specification that `compare.calibrate` and `compare.verdict` implement (plan `Planning/MILESTONE_2_PLAN.md`, decisions D2, D3 and D6–D9). The first version was written before any calibration was run. The refinements marked **[refined]** were forced by running it on real ensembles and synthetic suites (see §9); the code is in `compare/stats.py` (kernels), `calibrate.py`, `verdict.py`.

## Inputs

- **Ensemble**: K seeded `ref-1` runs of one input (K = 20 in M2; at least 4 are required). Each run is an `ObservableTable` (`compare/model.py`), held as a per-run *extract* (§7).
- **Candidate**: m ≥ 1 runs of the same input, produced by the code under test (BASIC or C++). The candidate input hash must equal the ensemble's.
- **α = 0.01**: the family-wise error rate of one suite run (D3).

A **field** is a key `(label, index)` inside a family `(file, block, group)`. The **variance group** of a field is its label (the column of a table): fields of one column share a variance law, fields of different columns do not. **[refined]**

## 1. Field classes (D6)

For every key seen in at least one ensemble run:

| Class | Rule | Treatment |
|---|---|---|
| deterministic | present in all K runs with identical value (bitwise for floats) | the candidate must reproduce it, see below |
| stochastic numeric | numeric, finite, not identical across the K runs | statistical tests (§2–§4). A run where the key is absent counts as 0 (absent table rows are zero yields) |
| zero field | value 0 in every run, and either absent in some run or its column has a stochastic field **[refined]** | statistical, with mean 0 and the group floor (§2): a bin that stayed empty can receive an event |
| ignored | varies but not finite in all runs, a derived label (`dmp` `lo`, `hi`: the trimmed range of the `y` bins), or any varying number of a log-line file (kind `text`: stdout, ctl, input echoes; message counts and nuclide lists depend on the run; their constants stay exact, an absent or unknown line is accepted) **[refined]** | not tested |
| stochastic text | text, not identical across the K runs | not tested, counted in the report |

A family absent from some ensemble runs has all its fields zero-filled in them. A family present in all K runs and absent from the candidate fails (`missing`), **unless its file has a variable family set [refined]**: if the ensemble runs differ in which families the file holds (data-dependent analyzers such as `Zpre(A)`, `Zpost(A)`), the presence of a family is a Bernoulli outcome and K runs showing it is no evidence that it is structural. A missing family there is zero-filled and judged statistically, and its text is not judged.

**Deterministic numeric fields [refined].** In a family without stochastic numeric fields (headers, parameters) the candidate must match bitwise; an absent key fails unless the expected value is 0 (`dmp` trims zero bins). Inside a table (a family with stochastic fields) rows appear and disappear and printed values are rounded, so an absent field is accepted and a present one may differ by one unit of its last printed decimal (`print_quantum`; integers must match exactly). A deterministic zero that becomes nonzero is a bin that received an event and is judged like a new key.

**Constants by chance [refined].** Whether a field is deterministic *by construction* (barrier, header, parameter) or *constant by chance in K runs* (an edge bin with one event, a conditional mean such as `EcollA` 0.5 or `Z_mean` 60 over a handful of events) cannot be read off K identical values. The rule: a constant whose column (label) has stochastic fields in the same family is **pinned**, i.e. table content. It is judged statistically with its mean, the floor of its column (§2) and the candidate's value with absent = 0, together with the zero fields and new keys (z = Δ/√(floor·(1/m+1/K)): a single missing event is about √K ≈ 4σ, a large shift is rejected). Only constants whose column has no stochastic field stay exact (`events`, `barrier`, headers, parameters).

**New keys.** A candidate key never seen in the ensemble enters the statistics with ensemble value 0 and the variance floor of its column (§2). If the column is unknown in that family the typical floor of that label over the calibration is used; failing that, in a family with stochastic fields, the floor of one occupancy event of the observed size per K runs (`value²/K`); in a family without any stochastic field there is no evidence of scale and the key fails. A *family* the ensemble never had is judged the same way (all its numeric keys are new); its text is listed, not judged **[refined]**. Unknown text keys in a known family fail unless `--allow-extra`.

## 2. Per-field mean and variance

For a stochastic numeric field i of variance group g: ensemble mean m_i and sample variance s_i² (ddof 1).

**Count-like groups [refined]**: a group with at least 5 stochastic fields, all values ≥ 0, and `var/mean` consistent with one inflation factor (largest `var/mean` ≤ 10 × the median). Then v_i = φ_g · m_i with φ_g the median of s_i²/m_i over the fields with m_i > 0. φ_g absorbs the event count and every common-mode effect. Columns of conditional means (zero in empty bins, a typical value elsewhere) fail the dispersion test and fall under the next case.

**Other groups**: v_i = s_i². If the group has any zero entry (*zero-inflated*), v_i ≥ μ̃_i² · p̂(1 − p̂) with μ̃_i the mean over the nonzero runs and p̂ = (n_nonzero + 1)/(K + 2): a bin filled in every run can still be empty in the next.

**Sparse fields [refined]**: a field nonzero in fewer than 5 runs has v_i ≥ the group floor.

**Group floor** [refined] (the variance of a field of the group not seen nonzero): count-like group: max(10 % quantile of its positive v, q²/K), q the 10 % quantile of the fields' nonzero means; other groups: (largest |value| of the group)²/K. A group without a floor uses the smallest floor of the family. (The first version used the smallest positive v of the family, which a single rounding artifact of 10⁻⁶ among yields of 0.5 turned into z ≈ 10⁵.)

## 3. Statistics of one family

With the candidate mean c̄_i over m runs:

z_i = (c̄_i − m_i) / sqrt(v_i · (1/m + 1/K))

- **Global**: D = Σ_i z_i² over the n stochastic fields, plus the zero fields and new keys where the candidate is nonzero.
- **Local**: M = max_i |z_i| over the same fields.

## 4. Null distributions (D8): leave-one-out moment matching

For each ensemble member j: compute D_j and M_j treating run j as the candidate (m = 1) and the other K − 1 runs as the ensemble, using §2 on those K − 1 runs (a field constant in the K − 1 runs uses the full-ensemble variance). The field set and the variance groups are those of the full ensemble. This gives K draws of each statistic under the null, with all of BASIC's common-mode noise included.

- **Global [refined]**: D = (leading mode)² + rest. The leading mode is the top singular direction of the K standardized z vectors; its squared projection is a σ²·χ²₁ (a shared shift of all fields: heavy tail), the rest is a · χ²_ν by moment matching of D_j − mode_j. Both variances are taken on their upper side (mean + 2 standard errors of the K draws). p_global = P(σ²χ²₁ + aχ²_ν ≥ D) by quadrature. A single scaled χ² (the first version) underestimates the tail of D by orders of magnitude when the shared pre-pass dominates, and gave about 5 % suite false alarms on synthetic data.
- **Local [refined]**: the z_i are treated as a scaled Student t with variance κ² = mean over the draws of z² and kurtosis equal to the observed mean z⁴/κ⁴ (ν = 4 + 6/(kurt − 3), between 4.1 and Gaussian). If most of the family's variances are sample variances (non-count groups), ν ≤ K − 2. p_local = 1 − (1 − P(|z| ≥ M))ⁿ (Šidák over the n tested fields: the stochastic ones plus the nonzero zero fields and new keys).
- **Family p-value**: p_F = min(1, 2 · min(p_global, p_local)).
- **Degenerate families [refined]**: fewer than 30 stochastic fields (a global statistic needs many), or no variance of D. Only the local test is used and p_F = p_local. κ² and ν come from the pool of all degenerate families of the same file kind (sums of z², z⁴ over their draws; the median over all families if fewer than 500 draws).

The leave-one-out draws come from K − 1 runs while the real verdict uses K. The (1/m + 1/K) term in z_i accounts for the difference in the mean's uncertainty; G3 measures whether the remaining approximation holds.

**Low counts [refined]**: a count-like column whose nonzero values are whole multiples of a quantum q (the smallest positive value; ≥ 99.5 % within 0.02 quanta; q = 1/events for the `dmp` histograms) and whose Fano factor φ/q ≤ 3 is a *discrete* column. A field of it with an ensemble mean ≤ 20 counts per run is not judged by z. Given Poisson rates, the candidate's count c (over m runs) and the ensemble's total E (over K runs) are conditionally binomial, c | c+E ~ Binomial(c+E, m/(m+K)); this also carries the uncertainty of a rate known from a few events. The p-value is min(1, 2·min(P(X ≥ c), P(X ≤ c))), raised to 1/Fano if Fano > 1 (conservative: discrete), and the field's score in D, M and the leave-one-out draws is its normal equivalent Φ⁻¹(1 − p/2). A bin the ensemble never filled (zero field, new key of a known discrete column) is the case E = 0: one event is p = 2/(K+1), three events 2/(K+1)³ (the Gaussian treatment gave about 4σ for one event and p ~ 10⁻⁸ for three). The local test combines two parts: the fields judged by the fitted t law (κ², ν from the well-populated fields only) and the low-count fields judged by the largest normal-equivalent score with an exact Šidák term; the family's local p is the Šidák combination of the two.

## 5. Suite verdict (D3)

Holm step-down at α over all statistically tested families: the family of rank r (1-based, by p_F) out of F rejects if p_F ≤ α / (F − r + 1) and every lower rank rejected. **F [refined] is the number of families judged that have numeric fields** (every such family gets a p-value, 1 when nothing in it is testable), not the number with p < 1; with the smaller F the thresholds would be too lax. `--holm-total calibration` uses the calibration's family count when only some files are judged. Deterministic failures (`missing` families, mismatching deterministic fields or text) always reject. The suite **passes** if nothing rejects.

## 6. Minimum detectable effect (G5)

For family F with n fields, the local test rejects a single-field shift δ at field i when |z_i| ≥ t*, where t* solves 1 − (1 − P(|z| ≥ t*))ⁿ = α / F under the local null of §4 (Holm's first, strictest step). The MDE in value units is t* · sqrt(v_i · (1/m + 1/K)), and relative to the field it is that divided by m_i. `compare.calibrate` writes the MDE of every field of the families the injection tests use (`--mde FILEGLOB::BLOCKGLOB`; default `Apost.dmp`/`APOST` and ENDF `MF8/MT454`) and `Calibration.mde(family, m)` computes it for any family on demand. Deterministic fields have MDE 0.

## 7. Memory and scale, artifacts

A full 59-energy Rn-215 run has tens of millions of observables. Nothing holds a run as `dict[Key, Value]`:

- `compare.extract` streams each file from its parser into per-family arrays (interned labels, int64 key matrix, float64 values; text separately), content-addressed key layouts shared by all runs of an input, one `.npy` of values per file (memory-mapped), cached under `build/compare/extract/` and keyed by the size and mtime of every run file plus the parser sources;
- calibration, verdict and injection process one file at a time and, inside it, one family at a time (K runs aligned by unique rows);
- the calibration artifact stores per-family arrays per file (`compare/calibrate.py` docstring has the layout).

## 8. What is validated where

| Claim | Gate |
|---|---|
| The approximations in §2–§4 give ≤ 1 % suite false-alarm rate on BASIC | G3 (leave-one-out over all three ensembles plus 5 independent held-out runs; p-value uniformity) |
| The 18.5 MeV pre-pass case is accepted | G4 |
| Real faults above the MDE are found | G5 |

## 9. Changes against the first version, and known weak spots

Reasons, in the order they were met on real data (`m1_cf252_gs` ensemble, held-out `m1-g4-cf252-ref1-independent`): columns of one table mix scales (yield, mean A, uncertainty) so φ per family is meaningless → groups per label; one rounding artifact set the family floor → group floors; conditional-mean columns (mean TKE, mean spin) are not Poisson-shaped and empty at the edges → dispersion test, zero-inflated and sparse rules; printed digits and rare analyzers made "identical in K runs" fail a new run → tolerance, absent zero, unseen families; mean z² as κ² was dominated by a few outlier families (10⁸) → kurtosis-fitted t and pools by median or by degenerate families; D far in the χ² tail with a shared mode → mixture; p-values of tiny discrete families → ≥ 30 fields for a global test.

Rare analyzers and chance constants (Rn-215 short, K = 12): the exact failures `Zpre(157)`, `Zpre(58)`, `Zpost(63)`, `Zpre(152)`, `Zpre(63)` (`ZApre.dmp`/`ZApost.dmp` hold one block per fragment mass A that received events; the edge masses appear in some runs only, here in all 12 by chance), `EcollA y[58]`, `y[157]` (XE.dmp: mean collective energy 0.5 in the bins with a single event) and `Z_mean (post)[151]` (out file: 60 in all runs, 59 in the candidate) were all constants of K runs. They are now variable-file and pinned cases (see §1). Before: `m1-g23-rn215-n-a` 7 exact failures, `m1-g1-rn215-ref1` 1; after: 0 exact failures in both.

Single-event bins (Cf-252, `m1_cf252_gs`, K = 17–19): the three leave-one-out failures of the first dry run (`EexcL2dheavy(189)`, `(308)`, `(280)`, `(175)` in `Eexc.dmp`) were all bins with one or two events in the ensemble and three in the candidate, scored z ≈ 6 and p ~ 10⁻⁷ to 10⁻⁸ under the Gaussian law; the conditional binomial gives p ≈ 2·10⁻³ for that bin. `test_discrete.py` checks `P(p ≤ t) ≤ t` for t = 10⁻⁴ … 0.1 on sparse Poisson histograms (expected counts 0.005 … 1500) and detection of six events in a bin of 0.1 expected.

Known weak spots, to be measured by G3 with K = 20:

- every tail p-value (10⁻⁶ and below) is an extrapolation from K = 20 draws; the variance safety margin and the t tail make it conservative but not exact;
- columns of conditional means have a very low sensitivity (occupancy variance), the conditional means are covered through the yields in other files;
- low-count fields assume Poisson counts (Fano ≤ 3); a column more overdispersed than that stays on the Gaussian path with its sparse-variance floor.
