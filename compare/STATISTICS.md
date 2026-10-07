# Statistical design of `compare` (M2)

This is the specification that `compare.calibrate` and `compare.verdict` implement (plan `Planning/MILESTONE_2_PLAN.md`, decisions D2, D3 and D6–D9). It is written down before any calibration is run.

## Inputs

- **Ensemble**: K seeded `ref-1` runs of one input (K = 20 in M2). Each run is an `ObservableTable` (`compare/model.py`).
- **Candidate**: m ≥ 1 runs of the same input, produced by the code under test (BASIC or C++). The candidate input hash must equal the ensemble's.
- **α = 0.01**: the family-wise error rate of one suite run (D3).

## 1. Field classes (D6)

For every key seen in at least one ensemble run:

| Class | Rule | Treatment |
|---|---|---|
| deterministic | present in all K runs with identical value (bitwise for floats) | the candidate must have the same value; a mismatch, or a missing key, fails the family outright |
| stochastic numeric | numeric, and not identical across the K runs | statistical tests (§2–§4). A run where the key is absent counts as 0 (absent table rows are zero yields) |
| stochastic text | text, not identical across the K runs | not tested, listed in the report |

A candidate key never seen in the ensemble: numeric keys enter the statistics with ensemble values 0 (§2 variance floor); text keys are listed and fail their family.

## 2. Per-field mean and variance

For a stochastic numeric field i of family F: ensemble mean m_i and sample variance s_i² (ddof 1).

Variance model v_i:

- **count-like families** (every ensemble value ≥ 0 and at least 5 stochastic fields): Poisson-shaped variance with an empirically fitted inflation, v_i = φ_F · m_i, where φ_F = median over fields with m_i > 0 of s_i² / m_i. φ_F absorbs the event count and every common-mode effect (the shared pre-pass, the pass structure). The values are not raw counts, so φ_F is not 1.
- **other families**: v_i = s_i².
- **floor**: v_i ≥ v_floor,F, where v_floor,F is the smallest positive v in the family. This covers fields that were zero in all but a few runs and keys new in the candidate.

## 3. Statistics of one family

With the candidate mean c̄_i over m runs:

z_i = (c̄_i − m_i) / sqrt(v_i · (1/m + 1/K))

- **Global**: D = Σ_i z_i² over the n stochastic fields.
- **Local**: M = max_i |z_i|.

## 4. Null distributions (D8): leave-one-out moment matching

For each ensemble member j: compute D_j and M_j treating run j as the candidate (m = 1) and the other K − 1 runs as the ensemble, using §2 on those K − 1 runs. This gives K draws of each statistic under the null, with all of BASIC's common-mode noise included.

- **Global**: D ≈ a · χ²_ν with a = var(D_j) / (2 · mean(D_j)) and ν = 2 · mean(D_j)² / var(D_j). p_global = P(a · χ²_ν ≥ D).
- **Local**: the z_i are treated as N(0, κ²) with κ² = mean over j and i of z_ij². p_local = 1 − (1 − 2 · Φ̄(M / κ))^n (Šidák over the n fields).
- **Family p-value**: p_F = min(1, 2 · min(p_global, p_local)).
- **Degenerate families**: if fewer than 2 stochastic fields, or the leave-one-out variance of D is 0, only the local test is used, with κ from the pooled value over all families of the same file kind.

The leave-one-out draws come from K − 1 runs while the real verdict uses K. The (1/m + 1/K) term in z_i accounts for the difference in the mean's uncertainty; G3 measures whether the remaining approximation holds.

## 5. Suite verdict (D3)

All families with p_F < 1 (or failed deterministically) are sorted by p_F. Holm step-down at α: the family of rank r (1-based) out of F rejects if p_F ≤ α / (F − r + 1) and every lower rank rejected. Deterministic failures always reject. The suite **passes** if no family rejects.

## 6. Minimum detectable effect (G5)

For family F with n fields, the local test rejects a single-field shift δ at field i when |z_i| ≥ t*, where t* solves 1 − (1 − 2 · Φ̄(t*/κ))^n = α / F (Holm's first, strictest step). The MDE in value units is t* · sqrt(v_i · (1/m + 1/K)), and relative to the field it is that divided by m_i. `compare.calibrate` writes the MDE for every field of the families the injection tests use.

## 7. Memory and scale

A full 59-energy Rn-215 run has tens of millions of observables (the `dmp` files alone hold about 10,000 per file). Implementations must not hold whole runs as `dict[Key, Value]`. Instead:

- process family by family, file by file;
- intern keys to integer ids per family;
- keep values in NumPy arrays (runs × fields);
- store calibration artifacts as per-family arrays.

## 8. What is validated where

| Claim | Gate |
|---|---|
| The approximations in §2–§4 give ≤ 1 % suite false-alarm rate on BASIC | G3 (leave-one-out over all three ensembles plus 5 independent held-out runs; p-value uniformity) |
| The 18.5 MeV pre-pass case is accepted | G4 |
| Real faults above the MDE are found | G5 |
