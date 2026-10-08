# Milestone 2: Comparison Toolkit

**Status:** not started
**Strategy reference:** `IMPLEMENTATION_STRATEGY.md` §2.7 and §3, M2
**Depends on:** M1 (complete)
**Unblocks:** M14 (first T4 integral verdicts), M15–M18 (every statistical gate)

## 1. Goal

Turn "these two outputs agree" into an automatic, calibrated verdict for any pair of GEF output directories: BASIC against BASIC, C++ against BASIC, or a library tape against a BASIC ensemble.

- **Parsers** read every file GEF writes into typed observables without loss.
- **Exact comparators** decide fields that must agree exactly (T0–T3 and the deterministic parts of every run).
- **Statistical comparators** decide stochastic fields against the natural spread of BASIC itself. That spread is measured empirically from seeded `ref-1` ensembles (null calibration), and a suite run has at most a 1 % chance of failing a correct implementation.
- **Reports** name the failing observable, energy step and bin.

M2 ports no physics. It replaces M1's provisional `harness.minicheck`.

## 2. Decisions taken in this plan

| ID | Topic | Decision | Reason |
|---|---|---|---|
| D1 | Calibration ensembles | K = 20 seeded `ref-1` runs each of `m1_rn215_short`, `m1_cf252_gs` and a new full 59-energy Rn-215 input (`m2_rn215_full`, the `gefy_nfy` energy list), all at production `Fenhance` | User decision (2026-10-07). The full input covers every multi-chance regime, including the low-statistics pre-pass energies around 13–19 MeV |
| D2 | Step-common noise | **Empirical**: acceptance comes from the ensembles' measured spread, which already contains the shared pre-pass, its k/N quantisation, the 31+1 pass structure and Poisson event noise. No parametric model of the pre-pass | User decision (2026-10-07). Rerunning GEF itself is closer to GEF's actual behaviour than any model of it |
| D3 | False-alarm control | **Family-wise error rate ≤ 1 % per suite run**, Holm step-down across all test families | User decision (2026-10-07). A red result has a defined meaning; GEF's own summed χ² (`Plotting.bas`) has no false-alarm control and hides local faults |
| D4 | Parser fidelity | **Round-trip** (parse → write → identical bytes) for ENDF-6, `dmp`, `mvd` and `par`. **Field coverage** for `out/`: every numeric token is captured as a typed field or explicitly listed as non-data | User decision (2026-10-07). M13 later gives `out/` byte-exact writers |
| D5 | Location | New Python package `compare/` (`python3 -m compare.<module>`). It absorbs `harness/endf_mt454.py`, and `harness.minicheck` is removed at the end of M2 | User decision (2026-10-07) |
| D6 | Field classes | The ensemble classifies every parsed field. If all K runs agree exactly, it is **deterministic** (barriers, parameter values, energy schedule, headers) and must match exactly. Otherwise it is **stochastic** and goes to the statistical tests | Lets the ensemble decide, not a hand-written list. A deterministic field that differs in a candidate is a real difference, not noise |
| D7 | Test families | One family = one observable block at one energy step of one system: a `dmp` analyzer, an `out/` section table, ENDF MT454 or MT459 at one energy, or the `par`/`mvd` content of one step. Each family has a **global** statistic (sensitive to broad shifts) and a **local** statistic (sensitive to one wrong bin), combined into one family p-value. Holm runs across families | Matches how failures must be reported (strategy §2.7) and keeps both broad and local faults visible |
| D8 | Tail calibration | K = 20 cannot resolve tail probabilities around 10⁻⁶ directly. The ensemble estimates per-field means and variances. For count-like fields the variance is the Poisson-shaped form scaled by a pooled, empirically fitted inflation factor per family. The null distribution of each global statistic is a moment-matched scaled χ² fitted to leave-one-out distances. The null-validation gate (G3) checks this approximation | Uses the ensemble for everything it can measure and makes the one modelling step explicit and testable |
| D9 | Candidates | A candidate can be one run or several runs with different seeds (their mean is compared, with variance scaled accordingly) | Later milestones can buy statistical power for the C++ side with more seeds instead of looser thresholds |
| D10 | Storage | Ensemble runs are stored with `harness.store` (`m2-ens-<input>-s<seed>`). Calibration artifacts are stored as their own store kind `calibration`, with committed manifests | Same immutability and provenance as M1 |

## 3. Facts from M1 that shape this plan

| Fact | Consequence |
|---|---|
| `ref-1` runs are byte-reproducible per seed (G1, G2), so an ensemble is just "seeds 1…K" | Every calibration is reproducible and rerunnable |
| At Rn-215 18.5 MeV the pre-pass derives the chance split from about 15 fissions. `ref-1` with seed 1776849192 had 0 of 15 second-chance fissions and deviated from the library at independent z_rms 2.47 (capture `m1-g1-rn215-ref1`) | The calibration must accept this run (gate G4) |
| A run writes 27 `dmp` analyzers per energy step, 45 tagged sections per step in `out/` (`<Title>` … `<Comments>`), per-pass `tmp/*_Single.mvd`, a per-system `.par` file and ENDF MF1/MF8 | Scope of the parsers |
| `validation/test_run/out/GEF_86_215_n.dat` holds an earlier partial run before the real one (63 `Output written on` records for 62 steps), and its ENDF file holds two tapes | Parsers must handle appended runs and select one |
| Shortened Rn-215 run: about 20 min alone. Full 59-energy Rn-215: about 106 min alone. Cf-252 `GS`: about 18 min. Run time grows under heavy parallel load | Ensemble cost, §4.4 |

## 4. Work breakdown

Tasks in execution order. Mark each one done here when finished, and update `CURRENT_PROJECT_STATE.md` (see `.omp/AGENTS.md`).

### M2.1 Package skeleton
- [ ] Create `compare/` (`__init__.py`, `README.md`, `tests/`), extend `pyproject.toml` (ruff, basedpyright strict and pytest include `compare/`), add the store kind `calibration` to `harness.store`.
- [ ] Move `harness/endf_mt454.py` into `compare/parsers/endf.py` and update its callers.

**Done when:** `scripts/ci.sh --quick` covers `compare/`.

### M2.2 Parsers
Each parser returns typed observables keyed by (system, energy step, energy, file kind, block, label, index tuple).

- [ ] **ENDF-6** (`compare/parsers/endf.py`): MF1/MT451 (header and description text), MF8/MT454 and MF8/MT459 (all energies, ZAFP, FPS, Y, DY), multi-tape files. Round-trip writer.
- [ ] **`dmp`** (SATAN analyzer dumps): header records (`C:`, `S:`, `X:`, `Y:`, `A:` with range and format), data blocks including the 128-character wrapping, 1-D and 2-D analyzers, the hand-written `ZApre`/`ZApost` blocks. Round-trip writer.
- [ ] **`mvd`** (per-pass multivariate yields) and **`par`** (perturbed parameter sets): round-trip.
- [ ] **`out/`** results file: split into runs and energy steps, then the 45 tagged sections. Every numeric token is captured as a typed field or listed in a per-section allow-list of non-data tokens (dates, section numbering). Coverage is checked by a test that counts numeric tokens.
- [ ] **Probe dumps**: an adapter over `harness.probes` into the same observable model.
- [ ] A run-directory loader (`compare.load_run`) that reads the M1 run layout (and plain GEF working directories such as `validation/test_run`) into one observable table.

**Done when:** gate G1 holds.

### M2.3 Exact comparator
- [ ] `compare.exact`: field-by-field comparison of two observable tables, or of two probe dumps. It reports value, bit pattern and ULP distance for floats, and the first difference per block. The M1 masks apply to text fields. Optional per-field ULP bounds for later T1 use, so that M5's written ULP bounds can be checked.
- [ ] `python3 -m compare.exact <A> <B> [--ulp N] [--json OUT]`.

**Done when:** pytest covers identical, one-ULP, NaN/±0 and masked cases, and the M1 G3 run pairs come out identical at field level.

### M2.4 Calibration ensembles (D1)
- [ ] `harness/inputs/m2_rn215_full.in`: `gefy_nfy` settings, 59 energies, `86, 215, "EN"`, `Fenhance = 10`, `Options(ENDF)`.
- [ ] Run `ref-1` with seeds 1001–1020 (`m1_rn215_short`), 2001–2020 (`m1_cf252_gs`) and 3001–3020 (`m2_rn215_full`) in normal mode, then store every run (`m2-ens-<input>-s<seed>`). This is a scripted job (`compare/ensemble.sh` or a Python driver) that can resume after interruption.
- [ ] Record wall time and CPU time. Estimate: about 7, 6 and 35 CPU-hours (48 total). Budget about 6–8 h wall on 16 parallel slots, plus about 12 GB of store space.

**Done when:** all 60 runs are stored and `harness.store verify` passes.

### M2.5 Calibration (D6–D8)
- [ ] `compare.calibrate --ensemble <capture ids> --out <dir>`: field classification (D6), per-field ensemble mean and variance, per-family variance model (Poisson-shaped × fitted inflation for count-like fields, empirical variance for scalars), and leave-one-out distances for each family's global and local statistics with the fitted null parameters.
- [ ] The calibration artifact (JSON + NumPy arrays) records the ensemble ids, the code version, the family definitions and fit diagnostics. It is stored as a `calibration` store entry.
- [ ] Diagnostics report: families whose inflation factor is far above 1 (expected at low-statistics pre-pass energies), and fields deterministic in BASIC that a candidate must match exactly.

**Done when:** calibrations for the three ensembles are stored and their diagnostics are recorded in the completion notes.

### M2.6 Verdict engine (D3, D7, D9)
- [ ] `compare.verdict --calibration <id> --candidate <run dir> [--candidate …] [--json OUT]`:
  - deterministic fields → exact check: any mismatch fails the family;
  - stochastic fields → global and local statistics per family against the calibrated null → family p-value;
  - Holm across all families at α = 0.01 → suite verdict;
  - candidate sets of several runs are averaged with the variance scaled accordingly (D9).
- [ ] The candidate and the calibration must describe the same input (the input hash is checked).

**Done when:** pytest covers the Holm procedure, the p-value combination and the candidate-set scaling on synthetic data with known answers.

### M2.7 Reports
- [ ] Text and JSON reports. Per failing family: observable, energy step and energy, statistic, p-value, Holm rank and threshold, and the top contributing bins with candidate value, ensemble mean and z. A summary table per file kind and energy. Deterministic mismatches are listed separately.
- [ ] Reports are byte-deterministic for the same inputs (sorted, no timestamps in the body).

### M2.8 Null validation (gate G3)
- [ ] **Leave-one-out**: for each ensemble, calibrate on 19 runs and judge the 20th, for all 20 choices.
- [ ] **Independent held-out runs**, never part of any ensemble: `m1-g1-rn215-ref1` and `m1-g23-rn215-n-a` (short Rn-215), `m1-g1-cf252-ref1` and `m1-g4-cf252-ref1-independent` (Cf-252), and `validation/test_run` (full Rn-215, real tape selected).
- [ ] Collect all family p-values from these null judgements and test them for uniformity (KS, p > 0.01).

### M2.9 Sensitivity (gate G5)
- [ ] `compare.inject`: applies synthetic faults to the parsed observables of a held-out run, each in a fixed primary representation:
  - one independent yield scaled by 2 %: ENDF MF8/MT454 `Y` of one (ZA, state) at one energy;
  - one mass bin's content moved to its neighbour: the `dmp` `APOST` analyzer of one energy step;
  - one isomeric state dropped: ENDF MT454 `Y` of state 1 added to state 0 and set to 0.

  A real fault would show in every file that carries the quantity. Injecting it in one representation is the harder case for detection, because only one family sees it.
- [ ] Before injecting, `compare.calibrate` reports the **minimum detectable effect** of each family at the designed α, so detectability is known in advance.
- [ ] Faults are injected at every energy of each held-out run, at the largest-yield nuclide or mass bin and at a mid-yield one.

### M2.10 The M1 18.5 MeV case (gate G4)
- [ ] Judge `m1-g1-rn215-ref1` against the `m1_rn215_short` calibration. It must pass, including at 18.5 MeV. Record the inflation factor and statistics at 18.5 MeV against neighbouring energies.

### M2.11 Library comparison (informational, not a gate)
- [ ] Judge the library tape `GEFY_86_214_n.dat` (MT454/MT459 only) against the `m2_rn215_full` calibration and report per energy. This is the first look at T5-style comparisons. The library was produced by an unknown GEF 2025/1.2 build at the same `Fenhance`.

### M2.12 Retirement, CI and close-out
- [ ] Remove `harness/minicheck.py` and its tests; `harness/gates.sh g4` calls `compare.verdict` instead. Update `harness/README.md`.
- [ ] Fast `compare/` tests in CI; the long ensemble job and gates run on demand (`compare/gates.sh`).
- [ ] `QUIRKS.md` (new findings), `COVERAGE_MATRIX.md` (M2 closes no cells; record that), `IMPLEMENTATION_STRATEGY.md` (decisions D6–D10 if they refine §2.7), `CURRENT_PROJECT_STATE.md`, and mark this plan complete.

## 5. Exit gate (all must hold)

| Gate | Requirement |
|---|---|
| G1 Parsers | Round-trip byte-identical for every ENDF file in `validation/reference/` (382 tapes) and `validation/test_run/`, and for every `dmp`, `mvd` and `par` file in `validation/test_run/` and the M1 store captures. `out/` field coverage is 100 % of numeric tokens for the same files |
| G2 Exact comparator | The M1 G3 pairs (probed against unprobed builds, same seed) are identical at field level; injected single-ULP changes are reported with the correct location and ULP distance |
| G3 Null validation | Over all leave-one-out and held-out judgements (60 + 5), the number of failed suites is consistent with ≤ 1 % FWER: at most 3 of 65, since P(X ≥ 4) = 0.45 % for a true 1 % rate. Pooled family p-values are uniform (KS p > 0.01) |
| G4 M1 18.5 MeV case | `m1-g1-rn215-ref1` passes against the `m1_rn215_short` calibration |
| G5 Sensitivity | Every injected fault whose size is at least the family's precomputed minimum detectable effect is detected, in the right family and bin. The MDE table, including where the single-nuclide 2 % shift lies relative to the MDE at each energy, is recorded |
| G6 Store | Ensembles and calibrations are stored with committed manifests; `harness.store verify` passes |
| G7 CI | `scripts/ci.sh` passes; `harness.minicheck` is gone |

## 6. Out of scope (later milestones)

- Comparisons of C++ runs (none exist yet): the first T4 verdicts are M14.
- T5 library regeneration and trend analysis over Z, A, E (M18). M2.11 is a preview only.
- Ensembles for further systems (U-235, Pu-239, U-238, a superheavy): produced by M14 when its core set needs them, with this toolkit.
- List-mode (`lmd`) parsing (M15) and fit-mode outputs (M16).

## 7. Risks and open questions

| Item | Handling |
|---|---|
| The scaled-χ² approximation of the tail (D8) is wrong for some families | G3 tests it on 65 null judgements. Families that fail calibration diagnostics are reported, and their model is fixed (e.g. empirical variance instead of Poisson-shaped) before close-out. No threshold is loosened without a recorded justification |
| A single-nuclide 2 % shift is below the MDE at 10⁶ events once Holm is applied over thousands of families | G5 requires the MDE to be computed and recorded beforehand. Where the shift is undetectable with one candidate run, later milestones use candidate sets (D9) rather than weaker thresholds |
| Duplicated quantities (the same yields in ENDF, `out/` and `dmp`) count as separate families and make Holm conservative | Accepted. It costs some power but never inflates false alarms. Revisit only if G5 shows a real loss |
| Ensemble run time under heavy parallel load | Resumable job; runs are stored as they finish |
| `out/` contains appended earlier runs (`validation/test_run`) | The loader splits runs and selects explicitly; tests cover the two-run file |

## 8. Completion notes

*(Filled in when M2 closes: dates, ensemble timings, calibration diagnostics, null-validation and sensitivity results, MDE table, deviations from this plan.)*

### Interim status (2026-10-08, 06:30)

All numbers are from the final overnight run with the code at `cb1385b` (outputs in `build/compare/final2/`, driver `build/compare/run_final_gates.sh`). That run includes two bug fixes:
- round-off variance had disabled the `dmp` local test (pooled κ² of about 10²⁷);
- the MDE of fields judged by their own sample variance did not invert the saturating t score.

**Passing:**
- **G1:** round-trip of 417 ENDF, 4,482 `dmp`, 166 `mvd` and 17 `par` files; `out/` coverage of 183 files at 100 %.
- **G2:** same-seed runs are identical over 4.6 M fields. Probed against unprobed builds: 0 mismatches; the only extras are the probe files.
- **Ensembles:** all 60 stored. The full 59-energy runs took about 3.7 h each under load.
- **G3 Cf-252:** 0 of 22 failed suites (2 allowed). Validity holds at every threshold.
- **G4:** `m1-g1-rn215-ref1` passes against the short Rn-215 calibration (39,711 families).
- **G5 Cf-252:** all 5 faults of at least 1 MDE detected in the right family and bin.

**Failing, needs the user's decision** (only method changes were made overnight; α, Holm and the gate criteria are unchanged):
- **G3 Rn-215 short:** 5 of 22 failed suites (2 allowed).
  - s1001 is the 18.5 MeV rare-regime run: a second-chance pre-pass split in 1 of 20 runs.
  - The rest are single-cell bursts in sparse histograms (`NmultA`, `Nspectrum`, `mvd` cells, `SigmaZpost`).
- **G3 Rn-215 full (59 energies, 225,416 families):** 19 of 21 failed suites (2 allowed). Validity fails at t = 10⁻⁴ (858 against 470 expected); the larger thresholds are conservative. Failure types, all from correct BASIC runs:
  - edge and tail bins of sparse distributions (`SigmaZpost` y[63]/y[151], `DPlocal`, `Qvalues`, `Eexc`);
  - per-run row churn in the `mvd` `AZ`/`AZIcumu` tables, where new and lost rows still combine with a statistical p;
  - rare-regime steps: `EMpot` tables at 24–25 MeV and 18.5/19/19.5 MeV, where one run shifts many families together.
- **Conclusion so far:** the per-field calibrated model holds on Cf-252 (one energy, 10⁷ events). It does not hold on Rn-215, where many steps are in low-statistics or rare regimes and the number of families grows to 225 k. Reaching the 1 % target there needs a change of approach, not more tuning. For example:
  - test whole energy steps against the ensemble by rank (step-level permutation or Monte Carlo statistics);
  - or larger K for the regime-mixing steps.
- **G5 Rn-215 short:** 1 fault at or above 1 MDE missed (`isomer`, 30 MeV mid site, 1.01 MDE).
  - After the MDE fix most Rn-215 sites are far below 1 MDE: fields judged by their own sample variance have almost no power at this Holm level with K = 20.
  - A single-nuclide 2 % yield shift is below 1 MDE at every Rn-215 energy.
- **`validation/test_run` cannot be used as a held-out run for the full ensemble.** It ran as thread 2, so it writes `CUMU2.dat` where clean runs write `CUMU1.dat`. Its thermal `dmp` files and `out/` file also carry an appended earlier run, which shifts the block counters.
  - Its verdict therefore shows 61 structural mismatches and 53 rejected families.
  - It was still included as the one held-out suite in G3-full and fails there. Without it, 18 of the 20 leave-one-out suites fail.
