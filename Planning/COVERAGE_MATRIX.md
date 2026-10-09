# Coverage Matrix

**Purpose:** track which dimension of GEF (vision `GEF_CPP_VISION.md` §4.4) is proven at which test tier (vision §4.2). Uncovered cells must be visible here.
**Created:** M0.9. **Source commit of the BASIC reference:** `ba9f0aa`.

## Legend

| Status | Meaning |
|---|---|
| `uncovered` | Applies, but no milestone owns it yet. Not allowed at the end of M15 except where deferred. |
| `planned (Mxx)` | Applies and is owned by milestone `Mxx` (`IMPLEMENTATION_STRATEGY.md` §3). With several milestones, e.g. `planned (M10, M14)`, the earlier ones contribute partial evidence and the **last listed milestone closes the cell**. |
| `covered (test id)` | A gating test passes. The test id is the Catch2 `TEST_CASE` name (C++) or the pytest node id (Python harness/compare), e.g. `covered ("event: mode choice replay" [T2][event])`. Several ids are separated by `;`. |
| `n/a — reason` | The tier genuinely does not apply to this cell; the reason is stated in one line. |
| `deferred — needs user approval` | Applies, but no milestone plans to cover it; it stays open until the user approves the deferral or assigns a milestone. Once approved it reads `deferred (approved YYYY-MM-DD)`, stays open and is revisited when a milestone can cover it. |

Tiers (vision §4.2, strategy §3 *Conventions*):

| Tier | Meaning |
|---|---|
| T0 | Data: embedded tables, exact equality |
| T1 | Deterministic functions and probe-fed deterministic stages; also the snapshot-fed byte-exact writer tests of M13 |
| T2 | Samplers and stage replay. T2a = same random stream, bit-exact; T2b = same distribution (KS/χ²). Unmarked `planned` means both apply where the owning milestone's "Proven by" lists both |
| T3 | Seeded trajectory: identical output to the seeded BASIC reference (FreeBASIC-compatible generator; normal mode at production settings, per-event reseed mode for localisation). The integral acceptance tier of phase 1 (strategy §2.9) |
| T4 | Statistical integral (null-calibrated, vision §4.5). Phase 2 only: optimised and parallel C++ modes against the exact C++ code (strategy §2.9). All T4 cells are therefore owned by M17 |
| T5 | Library integral: regeneration of `gefy_nfy` (143 tapes, EN, 59 energies, `Fenhance` 10) and `gefy_sfy` (239 tapes, GS, single energy, `Fenhance` 100), both `Options(ENDF)` only |

## How to update

- Every milestone closes by updating this matrix (strategy §3 *Conventions*) together with `Planning/QUIRKS.md`.
- When a milestone's gate passes, change each cell it closes from `planned (Mxx)` to `covered (test id)`. A cell listing several milestones becomes `covered` only when the last one closes; earlier ones may append their test ids in the milestone plan's completion notes.
- If a milestone does not close a cell it owns, move the cell to the milestone that will (`planned (Myy)`), or mark it `deferred — needs user approval`, and record why in the milestone plan.
- New dimensions found during the port (a new threshold, option or code path) are added as new rows with an owner in every tier.
- `n/a` may be changed only with a reason; never leave a cell blank.
- Recompute the summary tables at the end after every update.

### Update log

| Milestone | Date | Cells changed |
|---|---|---|
| M0 | 2026-10-06 | Matrix created; no cell covered |
| M1 | 2026-10-07 | None. M1 builds the BASIC oracle (reference binary, probes, draw logs, drivers), not the port, so no cell can close. Its T0–T3 capture tooling is what the owning milestones' tests will use |
| M2 | 2026-10-08 | Exact-first decision (strategy §2.9): T3 becomes the integral acceptance tier; every planned T4 cell moves to M17 (99 cells), where T4 compares optimised and parallel C++ against the exact C++ code; the two production-`Fenhance` T3 cells change from n/a to planned (M14). No cell closes in M2 (it builds the comparison toolkit, not the port) |
| M3 | 2026-10-09 | Two cells covered: FreeBASIC numeric semantics at T1 (`fbrt:` tests in `fbc_arithmetic_test.cpp`, `conversion_test.cpp`, `maths_test.cpp`, `text_test.cpp`, `print_using_test.cpp`, `format_test.cpp`, `array_test.cpp`, `data_input_test.cpp`), and the `FbMtRng` stream and seeding at T2 (`rng_test.cpp`). NaN results compare equal regardless of sign and payload (user decision, `QUIRKS.md` B-001) |

## Matrix

### 1. Fissioning system

| Cell | T0 | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| Pre-actinides (Z = 86–88, e.g. Rn-215) | planned (M4) | planned (M7) | planned (M10) | planned (M10, M14) | planned (M17) | planned (M18) |
| Actinides (Z = 89–98; U-235, U-238, Pu-239 n-induced) | planned (M4) | planned (M7) | planned (M10) | planned (M10, M14) | planned (M17) | planned (M18) |
| Heavy actinides / transfermium (Z = 99–103, sf) | planned (M4) | planned (M7) | planned (M10) | planned (M14) | planned (M17) | planned (M18) |
| Superheavies (Z = 104–106 reference range; up to Z = 120 in T1 grids) | planned (M4) | planned (M5, M7) | planned (M10) | planned (M14) | planned (M17) | planned (M18) |
| Light vs. heavy isotopes of one element | planned (M4) | planned (M7) | planned (M10) | planned (M14) | planned (M17) | planned (M18) |
| Even-Z / even-N | planned (M4) | planned (M7) | planned (M10) | planned (M10) | planned (M17) | planned (M18) |
| Odd-Z and/or odd-N | planned (M4) | planned (M7) | planned (M10) | planned (M10) | planned (M17) | planned (M18) |
| Unbound compound nucleus (skip path) | n/a — no embedded table specific to this cell | planned (M6) | n/a — system is skipped before any draw | planned (M15) | planned (M17) | n/a — no reference-library system is unbound |
| Very low fissility | n/a — no embedded table specific to this cell | planned (M7) | planned (M10) | planned (M15) | planned (M17) | planned (M18) |
| Nuclide missing from NucTab/Isotab (`IMATmax.ctl` MAT assignment, blind β⁻) | planned (M4) | planned (M4, M11) | n/a — table lookup and decay sweep draw no random numbers | planned (M15) | planned (M17) | n/a — reference systems all have MAT numbers |

### 2. Entrance channel and kind of fission

| Cell | T0 | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| `EN` neutron-induced, ground-state target | n/a — no embedded table specific to this cell | planned (M6) | planned (M10) | planned (M14) | planned (M17) | planned (M18) |
| `EN[n]` neutron-induced on target isomer | planned (M4) | planned (M6) | n/a — isomer enters through setup only (T1) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `GS` spontaneous fission | n/a — no embedded table specific to this cell | planned (M6) | planned (M10) | planned (M14) | planned (M17) | planned (M18) |
| `IS n` spontaneous fission from isomer n | planned (M4) | planned (M6) | n/a — isomer enters through setup only (T1) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `EB` excitation energy above barrier | n/a — no embedded table specific to this cell | planned (M6) | n/a — channel enters through setup only (T1) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `EP` proton-induced | n/a — no embedded table specific to this cell | planned (M6) | n/a — channel enters through setup only (T1) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `EA` alpha-induced | n/a — no embedded table specific to this cell | planned (M6) | n/a — channel enters through setup only (T1) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `FC` excitation-energy spectrum | n/a — no embedded table specific to this cell | planned (M6) | planned (M15) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `ES` excitation-energy spectrum (file) | n/a — no embedded table specific to this cell | planned (M6) | planned (M15) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `EM` excitation-energy spectrum (multi-chance sampling) | n/a — no embedded table specific to this cell | planned (M6) | planned (M9) | planned (M9, M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| Single-system lines (3-field and 6-field, A ranges with steps) | n/a — no embedded table specific to this cell | planned (M6) | n/a — parsing draws no random numbers | planned (M14) | planned (M17) | planned (M18) |
| Two-system correlation lines | n/a — no embedded table specific to this cell | planned (M6, M12) | n/a — reuses stored perturbation draws (T3) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |

### 3. Energy regimes and code-path thresholds

| Cell | T0 | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| Spontaneous (E = 0) | n/a — no embedded table specific to this cell | planned (M6) | planned (M10) | planned (M14) | planned (M17) | planned (M18) |
| Thermal (0.0253 eV) | n/a — no embedded table specific to this cell | planned (M6, M7) | planned (M10) | planned (M10, M14) | planned (M17) | planned (M18) |
| Fast, first-chance only (below `Eexc_min_multi`) | n/a — no embedded table specific to this cell | planned (M7) | planned (M10) | planned (M10, M14) | planned (M17) | planned (M18) |
| Start of multi-chance pre-pass (`Eexc_min_multi`, both sides) | n/a — no embedded table specific to this cell | planned (M6, M9) | planned (M9) | planned (M9) | planned (M17) | planned (M18) |
| Each additional fission chance (2nd, 3rd, 4th, … both sides) | n/a — no embedded table specific to this cell | planned (M9) | planned (M9) | planned (M9) | planned (M17) | planned (M18) |
| Pre-equilibrium emission onset (both sides) | n/a — no embedded table specific to this cell | planned (M9) | planned (M9) | planned (M9) | planned (M17) | planned (M18) |
| Maximum valid energy (at and beyond) | n/a — no embedded table specific to this cell | planned (M6) | n/a — limit decided in setup (T1) | planned (M15) | planned (M17) | n/a — reference grid is fixed (≤ 30 MeV); limit tested at T4 |
| Single-energy run (`N_E_steps = 1`, ENDF path) | n/a — no embedded table specific to this cell | planned (M6, M13) | n/a — schedule draws no random numbers | planned (M14) | planned (M17) | planned (M18) |
| Two-energy run (`N_E_steps = 2`, ENDF path) | n/a — no embedded table specific to this cell | planned (M6, M13) | n/a — schedule draws no random numbers | planned (M15) | planned (M17) | n/a — no two-energy line in the reference sequences |
| Multi-energy run (`N_E_steps = N+3`, ENDF path) | n/a — no embedded table specific to this cell | planned (M6, M13) | n/a — schedule draws no random numbers | planned (M14) | planned (M17) | planned (M18) |

### 4. Options and modes

| Cell | T0 | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| `ENDF` | n/a — no embedded table specific to this cell | planned (M6, M13) | n/a — option selects writers only | planned (M14) | planned (M17) | planned (M18) |
| `ERR` (perturbed-parameter passes) | planned (M4) | planned (M6, M12) | n/a — draws via M8 samplers; draw order proven at T3 | planned (M12, M14) | planned (M17) | planned (M18) |
| `PTB` | n/a — no embedded table specific to this cell | planned (M6, M13) | n/a — no random draws specific to this cell | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `RANDOM` (random energies, `.rnd` ENDF path) | n/a — no embedded table specific to this cell | planned (M6, M13) | planned (M15) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `COV` | n/a — no embedded table specific to this cell | planned (M6, M12) | n/a — no random draws specific to this cell | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `COR` | n/a — no embedded table specific to this cell | planned (M6, M12) | n/a — no random draws specific to this cell | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `LMD` / `LMD+` list-mode output | n/a — no embedded table specific to this cell | planned (M6) | planned (M15) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `NEO` | n/a — no embedded table specific to this cell | planned (M6) | planned (M15) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `LOCAL` / `GLOBAL` | n/a — no embedded table specific to this cell | planned (M6) | planned (M15) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `NOSUPP` | n/a — no embedded table specific to this cell | planned (M6, M7) | n/a — no random draws specific to this cell | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `MYPARAMETERS` | n/a — no embedded table specific to this cell | planned (M6) | n/a — no random draws specific to this cell | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `DPARFAC` | n/a — no embedded table specific to this cell | planned (M6, M12) | n/a — scales widths; draws proven at T3 | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `MODE(i)` | n/a — no embedded table specific to this cell | planned (M6, M7) | planned (M15) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `FIT` / `NITER` fit mode | n/a — no embedded table specific to this cell | planned (M6, M16) | n/a — search draws proven at T3 | planned (M16) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |

### 5. `Fenhance` values

| Cell | T0 | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| `Fenhance` = 10 (n-induced production: 31 + 1 passes) | n/a — no embedded table specific to this cell | planned (M12) | n/a — no random draws specific to this cell | planned (M14) | planned (M17) | planned (M18) |
| `Fenhance` = 100 (sf production) | n/a — no embedded table specific to this cell | planned (M12) | n/a — no random draws specific to this cell | planned (M14) | planned (M17) | planned (M18) |
| Reduced `Fenhance` (< 10, short runs) | n/a — no embedded table specific to this cell | planned (M12) | n/a — no random draws specific to this cell | planned (M14) | planned (M17) | n/a — reference library uses 10 and 100 only |
| Other values (non-square pass counts, `Int(sqrt(100·Fenhance))` rounding) | n/a — no embedded table specific to this cell | planned (M12) | n/a — no random draws specific to this cell | planned (M15) | planned (M17) | n/a — reference library uses 10 and 100 only |

### 6. Override paths

| Cell | T0 | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| `MyParameters.dat` (incl. batch-mode no-effect quirk) | n/a — no embedded table specific to this cell | planned (M15) | n/a — no random draws specific to this cell | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `Fitpar.dat` read (incl. per-system reset) | n/a — no embedded table specific to this cell | planned (M15) | n/a — no random draws specific to this cell | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| `Fitpar.dat` / `BestFit/` written by fit mode | n/a — no embedded table specific to this cell | planned (M16) | n/a — no random draws specific to this cell | planned (M16) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |

### 7. Observables

| Cell | T0 | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| Z yields (pre/post) | n/a — observable, not a table | planned (M11) | planned (M10) | planned (M10, M14) | planned (M17) | planned (M18) |
| A yields pre-neutron | n/a — observable, not a table | planned (M11) | planned (M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| A yields post-neutron | n/a — observable, not a table | planned (M11) | planned (M10) | planned (M10, M14) | planned (M17) | planned (M18) |
| Z×A pre/post (ZApre/ZApost) | n/a — observable, not a table | planned (M11) | planned (M10) | planned (M10, M14) | planned (M17) | planned (M18) |
| Charge polarisation | n/a — observable, not a table | planned (M7, M11) | planned (M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Isomeric ratios | n/a — observable, not a table | planned (M11) | planned (M10) | planned (M14) | planned (M17) | planned (M18) |
| Independent yields (MT454) | n/a — observable, not a table | planned (M11) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | planned (M18) |
| Cumulative yields (MT459) | n/a — observable, not a table | planned (M11) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | planned (M18) |
| TKE and fragment kinetic energies | n/a — observable, not a table | planned (M11) | planned (M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Q values (incl. `Qbeta`) | n/a — observable, not a table | planned (M5, M11) | planned (M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Excitation energies (intrinsic, collective, deformation, TXE) | n/a — observable, not a table | planned (M7, M11) | planned (M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Fragment spins | n/a — observable, not a table | planned (M7, M11) | planned (M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Prompt-neutron multiplicities | n/a — observable, not a table | planned (M11) | planned (M8, M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| ν(A) and per-fragment neutron data | n/a — observable, not a table | planned (M11) | planned (M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Prompt-neutron spectra and local distributions | n/a — observable, not a table | planned (M11) | planned (M8, M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Prompt-gamma spectra | n/a — observable, not a table | planned (M5, M11) | planned (M8, M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Prompt-gamma multiplicities | n/a — observable, not a table | planned (M11) | planned (M8, M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Pre-scission emission | n/a — observable, not a table | planned (M11) | planned (M10) | planned (M10, M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Multi-chance emission (chance probabilities, CN spectra) | n/a — observable, not a table | planned (M9) | planned (M9) | planned (M9) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Decay heat / decay energetics (`Qbeta`, antineutrino list) | n/a — observable, not a table | planned (M11) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Delayed-neutron yield and emitter list | n/a — observable, not a table | planned (M11) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Cumulative decay chains (branching sweeps) | n/a — observable, not a table | planned (M11) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | planned (M18) |
| Perturbed-parameter distributions (`.par`) | n/a — observable, not a table | planned (M12) | n/a — draw order proven at T3 | planned (M12) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Standard deviations (incl. cap quirks) | n/a — observable, not a table | planned (M12) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | planned (M18) |
| Covariance matrices (Z, Apre, Apost, ZApre, ZApost, CovarCUMU) | n/a — observable, not a table | planned (M12) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Correlation matrices | n/a — observable, not a table | planned (M12) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |
| Two-system covariances | n/a — observable, not a table | planned (M12) | n/a — derived deterministically from histograms (T1) | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| χ² against DCLplotting evaluations (`<CHI_square>`) | n/a — observable, not a table | planned (M11) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | n/a — not stored in GEFY ENDF tapes |

### 8. Output formats

| Cell | T0 | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| ENDF-6 syntax (independent `endf_format_check.py`) | n/a — no embedded table specific to this cell | planned (M13) | n/a — formatting draws no random numbers | planned (M14) | planned (M17) | planned (M18) |
| ENDF MF1/MT451 header, MT454/MT459 records, `R_Norm`, `10.00` repair | n/a — no embedded table specific to this cell | planned (M13) | n/a — formatting draws no random numbers | planned (M14) | planned (M17) | planned (M18) |
| ENDF MAT numbering and file naming (`_n`, `_s`, isomer targets) | planned (M4) | planned (M4, M13) | n/a — formatting draws no random numbers | planned (M14) | planned (M17) | planned (M18) |
| `out/` results file, every section `<Title>` … `<External>` | n/a — no embedded table specific to this cell | planned (M13) | n/a — formatting draws no random numbers | planned (M14) | planned (M17) | n/a — library integral compares ENDF tapes only |
| `dmp/` SATAN analyzer files (headers, wrapping, ZApre/ZApost blocks) | planned (M4) | planned (M13) | n/a — formatting draws no random numbers | planned (M14) | planned (M17) | n/a — library integral compares ENDF tapes only |
| Side files `mvd`, `par`, `ptb` | n/a — no embedded table specific to this cell | planned (M12, M13) | n/a — formatting draws no random numbers | planned (M12, M14) | planned (M17) | n/a — debug outputs, not in the library |
| List-mode `.lmd` record format | n/a — no embedded table specific to this cell | planned (M15) | n/a — formatting draws no random numbers | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| Run-log printouts (barriers, masses, chances) | n/a — no embedded table specific to this cell | planned (M6, M9) | n/a — formatting draws no random numbers | planned (M14) | n/a — compared at printed digits, not statistically | n/a — no library-level run log |
| `External/` cumulation output | n/a — no embedded table specific to this cell | planned (M11) | n/a — formatting draws no random numbers | planned (M15) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |
| Fit outputs `Fitlog` | n/a — no embedded table specific to this cell | planned (M16) | n/a — formatting draws no random numbers | planned (M16) | planned (M17) | n/a — not exercised by `gefy_nfy`/`gefy_sfy` (EN/GS, `Options(ENDF)` only) |

### 9. Internal behaviour

| Cell | T0 | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| FreeBASIC numeric semantics (conversions, custom `Erf`/`Min`/`Max`, `Str`, `Print Using`, `Format`) | n/a — no embedded table specific to this cell | covered (`fbrt:` T1 tests of `conversion_test.cpp`, `maths_test.cpp`, `text_test.cpp`, `print_using_test.cpp`, `format_test.cpp`, `fbc_arithmetic_test.cpp`, `array_test.cpp`, `data_input_test.cpp`) | n/a — deterministic | n/a — covered through every T3 run, no own trajectory | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |
| `FbMtRng` stream and seeding (`Randomize s,3`) | n/a — no embedded table specific to this cell | n/a — stochastic; see T2 | covered (`fbrt: FbMtRng matches FreeBASIC for edge seeds`, `fbrt: FbMtRng matches the stored 10^6-draw FreeBASIC streams`, `fbrt: derive_seed reproduces the RESEED_SPEC vectors`) | planned (M14) | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |
| `PGauss` cached second value across calls | n/a — no embedded table specific to this cell | n/a — stochastic; see T2 | planned (M8) | planned (M10, M14) | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |
| Rejection-loop paths (draw counts depend on data) | n/a — no embedded table specific to this cell | n/a — stochastic; see T2 | planned (M8, M10) | planned (M9, M10) | planned (M17) | planned (M18) |
| Isomer stop in the gamma cascade | planned (M4) | planned (M5) | planned (M10) | planned (M10) | planned (M17) | planned (M18) |
| `J_attempt` retry and double histogram fill | n/a — no embedded table specific to this cell | n/a — stochastic; see T2 | planned (M10) | planned (M10) | planned (M17) | n/a — exercised indirectly by every integral run |
| `Static Ntimes` negative-TKE guard (99 events) | n/a — no embedded table specific to this cell | n/a — stochastic trigger; see T2 | planned (M10) | planned (M15) | deferred (approved 2026-10-07) — no statistical comparison exists for a run that stops; revisit later. The guard itself is still ported and replicated (M10 scope) | n/a — not triggered by reference systems |
| `Eva` `Static E_MIN` carry-over | n/a — no embedded table specific to this cell | n/a — stochastic; see T2 | planned (M8) | planned (M10) | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |
| State persisting across energy steps (incl. stale `Z`, `EPART`/`PEOZ`/`PEON`) | n/a — no embedded table specific to this cell | planned (M7, M9) | n/a — leak is in deterministic state | planned (M14) | planned (M17) | planned (M18) |
| State persisting across perturbation passes | n/a — no embedded table specific to this cell | planned (M12) | n/a — leak is in deterministic state | planned (M14) | planned (M17) | planned (M18) |
| State persisting across systems / process (`Nmulti2d*`, `R_lim` clamp, `IMATmax`) | planned (M4) | planned (M11) | n/a — leak is in deterministic state | planned (M14) | planned (M17) | planned (M18) |
| Normalisation (`ZISOPRE/POST` to 200 %, multiplicities to probabilities) | n/a — no embedded table specific to this cell | planned (M11) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | planned (M18) |
| Nuclide inclusion thresholds (ENDF selection) | n/a — no embedded table specific to this cell | planned (M13) | n/a — formatting draws no random numbers | planned (M14) | planned (M17) | planned (M18) |
| `mvd` text round trip (5-decimal / 7-digit quantisation) | n/a — no embedded table specific to this cell | planned (M12) | n/a — derived deterministically from histograms (T1) | planned (M14) | planned (M17) | planned (M18) |
| Per-event reseed mode equivalence (C++ and harness) | n/a — no embedded table specific to this cell | n/a — stochastic; see T3 | planned (M8, M10) | planned (M10, M14) | n/a — test-only mode; production runs use one stream | n/a — test-only mode |
| Parallel mode, bit-identical across thread counts | n/a — no embedded table specific to this cell | n/a — stochastic | n/a — per-event substreams validated statistically | n/a — not trajectory-equivalent by design (strategy §2.3) | planned (M17) | planned (M18) |

### 10. Embedded data

| Cell | T0 | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|---|
| NucTab / Isotab (incl. spin-sorted `R_lim` windows) | planned (M4) | planned (M4) | n/a — static data, no random draws | n/a — static data, no trajectory | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |
| BranchData / EndA / INlast (incl. Ra-234 loading stop) | planned (M4) | planned (M4, M11) | n/a — static data, no random draws | n/a — static data, no trajectory | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |
| Masses and shell/deformation tables (BEldmTF, BEexp, DEFOtab, ShellMO) | planned (M4) | planned (M5) | n/a — static data, no random draws | n/a — static data, no trajectory | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |
| ElmtNames, DCLplotting evaluation tables, `ENfrvar_lim` | planned (M4) | planned (M4) | n/a — static data, no random draws | n/a — static data, no trajectory | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |
| Parameter registry (nominal values, `Var_*`, 46 perturbed in draw order) | planned (M4) | planned (M4) | n/a — static data, no random draws | planned (M12) | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |
| `Anl_Par` analyzer registry (incl. naming quirks) | planned (M4) | planned (M4) | n/a — static data, no random draws | n/a — static data, no trajectory | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |
| `P_Egamma_low` cross-section table | n/a — built at run time, not embedded | planned (M5) | planned (M8) | n/a — static data, no trajectory | n/a — exercised indirectly by every integral run | n/a — exercised indirectly by every integral run |

## Summary

Counts by status and tier:

| Status | T0 | T1 | T2 | T3 | T4 | T5 | Total |
|---|---:|---:|---:|---:|---:|---:|---:|
| covered | 0 | 1 | 1 | 0 | 0 | 0 | 2 |
| planned | 21 | 105 | 49 | 106 | 100 | 43 | 424 |
| uncovered | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| deferred | 0 | 0 | 0 | 0 | 1 | 0 | 1 |
| n/a | 93 | 8 | 64 | 8 | 13 | 71 | 257 |
| **cells** | 114 | 114 | 114 | 114 | 114 | 114 | 684 |

Planned cells by closing milestone (last listed milestone in the cell):

| Closing milestone | M3 | M4 | M5 | M6 | M7 | M8 | M9 | M10 | M11 | M12 | M13 | M14 | M15 | M16 | M17 | M18 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Planned cells | 0 | 25 | 3 | 18 | 12 | 3 | 15 | 40 | 27 | 18 | 13 | 59 | 42 | 6 | 100 | 43 |
