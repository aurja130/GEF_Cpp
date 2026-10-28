# Milestone 5: Deterministic Physics Function Library

**Status:** complete (2026-10-13); planned 2026-10-12
**Strategy reference:** `IMPLEMENTATION_STRATEGY.md` §2.1, §2.2, §2.4, §2.9 and §3, M5
**Depends on:** M1 (driver framework, patch sets, runner, reference store), M2 (`compare.exact`), M3 (`gef::fb` conversions, maths, `Str`, `fb::Array`), M4 (`TableSet`, `Parameters`, `Isotab`, lookup functions)
**Unblocks:** M6 (`U_Valid`, the barrier and mass printout, CN kinematics), M7 (the per-nucleus table builder), M8 (`Eva` and the `P_Egamma_low` sampler built on the table), M9 (pre-pass widths), M10 (the E2 cascade inside the gamma stage), M11 (`U_Q_beta_minus` in `Branchings.bas`)

## 1. Goal

Every physics function of GEF that does not consume random numbers exists in C++ and returns, for every input GEF can give it, the same bits as the BASIC program. That covers masses, barriers, level densities, temperatures, yields, deformations, moments of inertia and the GDR helpers. It also covers two deterministic pieces that BASIC has inline or buried in random functions: the `P_Egamma_low` cross-section table and the E2 rotational cascade. After M5, everything in the physics that does not consume random numbers is proven (strategy, M5 exit).

## 2. Decisions taken in this plan

| ID | Topic | Decision | Reason |
|---|---|---|---|
| D1 | BASIC oracle | Standalone FreeBASIC drivers (`harness.driver`, `'@cut` of each function's line range, `'@include-source` of `utilities.bi` and the table files), plus an equivalence check: for every cut function, the C fbc emits in the driver must equal the same function in the emitted `GEF.c` after normalising fbc's temporary and label numbering. Any difference fails | User decision (2026-10-12). Drivers allow any input grid and rebuild quickly; the C comparison removes the risk that the driver's surroundings (stubs, include order, declarations) compile the function differently from GEF |
| D2 | Test inputs | Synthetic grids (all integer (Z, N) inside the tables; structured and seeded random `Single` grids; named edges) **plus** the arguments of real calls: harness patch `arglog` records the arguments, ByRef values and results of the first K calls of every M5 function in reference runs; the drivers and the C++ replay them | User decision (2026-10-12). Real calls reach non-integer A (`Beta_Equi` gets `A1 = Z1/Z·A`), energies from `Single`-stepped loops and the continuation chains of `Beta_Equi`. The logged results also give a second, in-context oracle that checks the drivers |
| D3 | Table indices outside the bounds | Decided by evidence. The `arglog` replay and an `-exx` (bounds-checked) build of the reference run on the capture inputs show which out-of-range indices GEF reaches. Default: the domain is the table interior and the C++ throws (`fb::Array`). Where GEF reaches an out-of-range index, the C++ reproduces the read explicitly behind a quirk switch. **Amended 2026-10-28 (user decision, M6.4; `MILESTONE_6_PLAN.md` §8):** GEF reaches such indices for a CN beyond the tables (capture `edge-f_second_system_outside_table`); every read of `BEldmTF`, `BEexp`, `DEFOtab`, `ShellMO` now goes through `gef::data::read_mass_table`, which reproduces the reference binary's memory (the next table or a malloc header word, QUIRK(Q-042)) and throws only before `BEldmTF` or after `EVOD`; `TableSet::fix_table_overrun` restores the throw outside the bounds | User decision (2026-10-12). fbc builds GEF without `-exx`, so BASIC never checks; coding standards §2.4: an out-of-bounds access found while porting is a quirk to register and reproduce explicitly |
| D4 | Scope | Add the live functions the strategy list did not name: `U_Valid`, `U_Delta_S0`, `U_Q_beta_minus`, `FEDEFOLys`, `F1`, `F2`, `U_alev_ld`, `E0_GDR`, `Width_GDR`, `Efac_def_GDR`. Do not port the functions without a live caller: `TKE_Viola`, `TFPair`, `Pmass`, `FEDEFOP`, `Beta_opt_light`, `Acentral`, `GgGtot`, `U_Gauss`, `U_Gauss_abs`, `U_Gauss_mod`, `U_Box2`, `U_Even_Odd`, `U_LinGauss`; the strategy's "Not ported" list is amended | User decision (2026-10-12). Callers checked with `tools.fbsrc.fbdef --refs` (2026-10-12); `U_LinGauss` was found while writing this plan and follows the same rule. Code that nothing calls cannot affect output |
| D5 | `P_Egamma_low` | Split. M5 ports the table builder (`GEF.bas:16980-17037`: `N`, `ReDim sigma(N)`, `Tm`, `betadef`/`gammadef`, both GDR branches, `sigMax`) as a pure function; M8 ports the rejection sampler (`GEF.bas:17048-17053`) on top of it | User decision (2026-10-12). The table is the precision-sensitive part (`Single` `For` loop, `CInt` index collisions); coverage-matrix row "`P_Egamma_low` cross-section table" is T1 in M5 |
| D6 | E2 cascade | One pure function for the deterministic cascade of one fragment: moment of inertia with the deformation factor, the isomer stop, the gamma energies, `E_E2_tot` and the lmd label `C_iso_lmd`. The histogram fills stay in the event stage (M10), which calls it for both fragments. The BASIC light (`GEF.bas:9309-9368`) and heavy (`9430-9484`) copies are each cut into a driver `Sub` and both are checked against the one C++ function. Nuclide data: JEFF-3.3 `Isotab` plus synthetic `Isotab` entries for spin edge cases | User decision (2026-10-12). No random draws, so T1 applies; the coverage-matrix cell "Isomer stop in the gamma cascade" is T1 in M5; one function for both copies also proves the copies equivalent. JEFF-3.3 only beyond T0, as M4 D4 |
| D7 | Output written by physics functions | Functions stay pure and return a diagnostic (`U_MASS` with Z < 0 or A < 0, `GEF.bas:16316-16318`; `Beta_Equi` not converged, `GEF.bas:16628`), with the values BASIC prints; the caller writes the text. M5 establishes whether either condition is reachable (grids and `arglog`) and registers a quirk if it is. Routing to `#f` belongs to M7/M13, which own the file state | User decision (2026-10-12). Output order is unchanged: nothing else prints between BASIC's `Print` and the function's return |
| D8 | C++ API | Free functions in `gef::physics`. Only functions that read tables take `const data::TableSet&`; globals BASIC reads (e.g. `Tscale`, `Econd`, `Etrans` in `P_Egamma_low`) become explicit arguments; ByRef outputs become returned values, and where BASIC leaves a ByRef output unassigned (e.g. `Beta_Equi` without improvement) the incoming value is an explicit argument | User decision (2026-10-12). Explicit data flow, as for `Rng&` (coding standards §2.3) |
| D9 | Test data | As M3 D1 and M4 D7: fingerprints and small goldens are committed (`harness.golden`); full driver outputs and captures stay in the reference store; tests that need the store skip without it | User decision (2026-10-12) |
| D10 | Types and arithmetic | Coding standards §2.4 and §5: `Single` → `float`, `Integer` → `std::int64_t`, `Long` → `std::int32_t`; parameters keep their BASIC types and callers convert as the generated C does (`fb::f2i`, `fb::f2l`, …), e.g. `U_levdens(Z As Integer, …)` called with a `Single`; arithmetic follows the `fbline` output (B-004) | Coding standards |
| D11 | Optimisation level | Every T1 test runs in `dev-gcc`, `dev-clang` and `release-exact` (`-O3`). A non-NaN difference is fixed in the source first (the M3 `fb::fix` precedent); compiling the translation unit at `-O0` is the last resort (M0 plan §2). NaN sign and payload differences are accepted (user decision 2026-10-08, B-001) | M0 plan, B-001 |
| D12 | A function that cannot be made bit-exact | Needs a written analysis and the user's approval (strategy §2.9). This replaces the "written ULP bound" wording of the strategy's M5 section, which is amended | Strategy §2.9 (decision 2026-10-08) |
| D13 | `Static` locals | `fgamma` (`U_levdens_FG`, `U_Temp`, `U_Temp2`), the `E0_GDR` constants and `e2`/`u`/`hbarc` in `u_accel` become `constexpr` once the emitted C confirms they are never assigned; `AME2020`'s `Static Izaehl` is never used and is dropped | Coding standards §2.3: no mutable globals; `const`/`constexpr` allowed |
| D14 | Layout | `Cpp_implementation/src/physics/`, CMake target `gef_physics`, namespace `gef::physics`, one file pair per group of §3 (`masses`, `barriers`, `level_density`, `shape`, `helpers`, `rotation`, `gamma`). Tests `Cpp_implementation/tests/physics_<group>_test.cpp`, tagged `[physics][T1]`, long ones `[slow]` | Strategy §2.8, coding standards §2.1 |

## 3. Scope inventory

Line ranges are `GEF.bas` at `ba9f0aa` unless another file is named.

| Group (file) | Functions |
|---|---|
| Masses and energies (`masses`) | `LyMass` 16110-16137, `LyPair` 16140-16151, `FEDEFOLys` 16211-16214, `LDMass` 16217-16236, `AME2020` 16238-16259, `U_SHELL` 16261-16271, `U_SHELL_exp` 16273-16292, `U_SHELL_EO_exp` 16294-16306, `U_MASS` 16310-16323, `ECOUL` 16326-16355, `U_Q_beta_minus` (`DCLbranchingJEFF33.bas:112-115`), `U_Valid` 15814-15832, `U_Delta_S0` 15836-15859 |
| Barriers (`barriers`) | `BFTF` 17657-17750, `BFTFA` 17752-17773, `BFTFB` 17775-17796 |
| Level densities and temperatures (`level_density`) | `U_alev_ld` 17173-17177, `U_levdens` 17205-17223, `U_levdens_Egidy` 17225-17259, `U_levdens_FG` 17261-17331, `U_Temp` 17335-17385, `U_Temp2` 17388-17420, `TEgidy` 16072-16095, `TRusanov` 16098-16108 |
| Shape and yields (`shape`) | `Getyield` 15862-15920, `F1` 15923-15928, `F2` 15929-15934, `Masscurv` 15936-15963, `Masscurv1` 15965-16003, `Masscurv2` 16005-16045, `De_Saddle_Scission` 16047-16063, `beta_light` 16358-16365, `beta_heavy` 16368-16375, `Z_equi` 16379-16426, `Beta_Equi` 16480-16646 |
| Small helpers (`helpers`) | `Gaussintegral` 17808-17816, `Bell` 17818-17828, `U_Box` 17830-17837, `EVEN_ODD` 17593-17653 |
| Rotation, GDR, kinematics (`rotation`) | `U_Ired` 17094-17108, `U_IredFF` 17110-17118, `U_I_Shell` 17120-17170, `E0_GDR` 17439-17459, `Width_GDR` 17461-17464, `Efac_def_GDR` 17466-17475, `u_accel` 16907-16959 |
| Extracted pieces (`gamma`) | `P_Egamma_low` table 16980-17037 (D5); E2 cascade 9309-9368 and 9430-9484 (D6) |

**Not in M5:**
- Random functions (M8): `Eva`, `P_Egamma_high`, the `P_Egamma_low` sampler, `PBox2`, `PPower_Griffin_v`, `PGauss`, `PLinGauss`, `PExp`, `PMaxwell`, `PMaxwellMod`.
- Already ported in M3: `Floor`, `Ceil`, `Round`, `Modulo`, and `utilities.bi`'s `Min`/`Max`/`Erf`/`Erfc`/`Tanh`.
- Analysis and output helpers (M13): `Find_IAnl`, `U_DMP_1D`, `U_DMP_1D_S`, `PLoss`, `Printcomments`.
- Not ported: dead code (`U_levdens_old`, `E_next`, `Pexplim`, `StoreEgammaA` under `B_EgammaA`), the unused samplers, and the D4 list.

## 4. Facts established while planning (2026-10-12)

| Item | Fact |
|---|---|
| Table bounds | `BEldmTF`, `BEexp`, `ShellMO` are `(0 To 203, 0 To 136)` (N, Z), `DEFOtab` is `(0 To 236, 0 To 136)` (`GEF.bas:1222-1255`). fbc compiles GEF without `-exx`; BASIC never checks an index. `U_SHELL_exp` reads `AME2020` at (Z, A ± 1) and (Z ± 1, A ± 1), so its domain is one cell smaller than the table's |
| Table indices of `Single` type | `LDMass` uses `BEexp(CInt(N), CInt(Z))`; `P_Egamma_low` and the E2 cascade use `DEFOtab(Ai - Zi, Zi)` with `Single` or `Integer` arguments; `Single` indices round half to even |
| Hidden state | `Beta_Equi` assigns its ByRef outputs only on improvement, so the caller's incoming values pass through; `U_MASS` prints to the console and `Beta_Equi` to `#f` (D7). `f` is a shared file number reassigned by `FreeFile` at `GEF.bas:4150, 4179, 10057`; which file, if any, is open when `Beta_Equi` runs is not established. The `Static` locals are listed in D13 |
| `Beta_Equi` | `Single` sums; four one-dimensional slope probes of up to `Int(beta/5E-4)` steps; then a diagonal search `N = 1…1000` with an inner loop over `N1 = 1…N`, i.e. up to about 5·10⁵ `LyMass`/`ECOUL` evaluations per call; `Ubest` is not reset between the probes |
| `P_Egamma_low` | Builds the table on every call: `N = Int(Ei*10 + 0.5)`, `ReDim sigma(N)`, `For Eg = 0.1 To Ei Step 0.1` in `Single`, index `CInt(Eg*10)`. The branch `betadef = 0 And gammadef = 0` cannot be taken (`gammadef = 47.4 − 120·betadef`), so the three-Lorentzian branch with `Efac_def_GDR` always runs. Reads `Tscale`, `Econd`, `Etrans` as globals |
| E2 cascade | Two near-identical copies (light `9309-9368`, heavy `9430-9484`) with the histogram fills inline. **Corrected 2026-10-12 (M5.1, emitted C):** `J` and `K` are not the shared `LongInt` `J` of `GEF.bas:762` but `Dim As Single J,K` locals of the module-level `Scope` `9240-9486` (C `J$20`, `K$20`), so `For J = Jfrag To 2 Step -2` runs in `Single` and nothing outside that scope can read them; `Exit For, For` leaves both loops. `I_DelGam` is `Dim As Integer I_DelGam = 0` (`GEF.bas:876`) and never assigned. Gamma energies go to `Array_Eg2_light/heavy(100)` (`GEF.bas:1342`), without a bounds check in BASIC. `C_iso_lmd` uses `Str(Single)`. Whether code between and after the copies reads the scope locals (`RJeff`, `Eg`, `Nspectrum`, `alph`) before reassigning them is established in M5.3 |
| `U_Valid` | `I_A / I_Z` is a floating-point division; `I_Z = 0` divides by zero before the `I_Z < 76` test |
| `U_Delta_S0` | Its body is commented out; it returns 0 for every input |
| Known edges | `Getyield` divides by zero when `T_high = T_low`; `BFTF` leaves `RF` unassigned at `RX = 30` (a local, so 0) |
| Code-map correction | `setup_physics.md:620` marks `Efac_def_GDR` as unused; it is called at `GEF.bas:17020` (recorded in `code_maps/README.md`) |
| Tooling | `harness.driver` compiles with default fbc options and keeps no C; `'@cut` already extracts line ranges. `harness.build` passes only `-d` defines to fbc. `harness.run --work-file` exists. Inputs in `harness/inputs/`: `m1_rn215_short.in`, `m2_rn215_full.in`, `m1_cf252_gs.in`, `m4_t0.in` |

## 5. Work breakdown

Tasks in execution order. Mark each one done here when finished, and update `CURRENT_PROJECT_STATE.md`.

### M5.1 Harness and tooling
- [x] `harness.driver`: compile with `-R` and keep the emitted C next to the binary; record its SHA-256 in `build.json`. Add `run --work-file` (as `harness.run`) so drivers can read case files.
- [x] `tools/fbsrc/fn_c_equiv.py` (D1): extract one function's C from a driver build and from the emitted `GEF.c`, normalise fbc's temporary (`vr$N`, `tmp$N`) and label (`label$N`) numbering, and compare. A driver `Sub` cut from inline code (D5, D6) is compared statement by statement with the corresponding `#line` range of `GEF.c`. Pytest with a matching and a deliberately altered function.
- [x] `harness.build --fbc-option OPT` (repeatable, part of the build id), needed for the `-exx` builds of M5.2.
- [x] Patch `arglog` (`-d GEF_ARGLOG`), in the canonical order after `lookups`. It logs, as hex, the arguments, the incoming and outgoing ByRef values and the result of the first `GEF_ARGLOG_MAX` calls (default 10⁵) of every function of §3, and the inputs and outputs of the two extracted pieces at their sites, to `probes/arglog/<name>.txt`. Like every harness patch, it does not shift `GEF.bas` line numbers. Reader `harness.arglog`.

**Done when:** pytest covers `fn_c_equiv` and `harness.arglog`; `arglog` is proven neutral (same seed, byte-identical outputs with timestamps masked) on `m1_rn215_short.in` and `m1_cf252_gs.in`.

### M5.2 Captures (D2, D3)
- [x] Inputs: the existing `m1_rn215_short.in` (pre-actinide, n-induced) and `m1_cf252_gs.in` (actinide, sf); new `m5_u235_n.in` (U-235 + n at thermal and at an energy above the second-chance threshold, so the pre-pass calls `U_levdens`/`U_Temp2`) and `m5_superheavy_sf.in` (one sf system with Z ≥ 104 from `validation/reference/gefy_sfy`). `Fenhance` as low as each input allows.
- [x] `arglog` captures `m5-arglog-<system>` in the store.
- [x] `-exx` builds (`seed` patch set, `--fbc-option -exx`) run on the same inputs, captures `m5-exx-<system>`. A bounds error inside a §3 function is a D3 site. An error elsewhere is recorded in `CURRENT_PROJECT_STATE.md` §5 for its owning milestone. If such an error stops a run early, the `arglog` replay remains the M5 evidence for that system.
- [x] Per function: call count, the range of every argument, and whether any table index left the bounds. Recorded in the completion notes; it sets the grids of M5.3.

**Done when:** the captures are stored and the per-function ranges are known.

### M5.3 BASIC drivers and goldens
- [x] One driver per group of §3: `m5_masses`, `m5_barriers`, `m5_level_density`, `m5_shape`, `m5_helpers`, `m5_rotation`, `m5_egamma_table` (lines 16980-17037 wrapped in a `Sub` that writes `sigma` and `sigMax`) and `m5_e2_cascade` (the two copies wrapped in two `Sub`s with explicit arguments; JEFF-3.3 `Isotab` through the `NucPropJEFF33.bas` loader, plus synthetic entries). Globals the functions read (`pi`, `Tscale`, `Econd`, `Etrans`, the tables) are declared as GEF declares them.
- [x] Each driver evaluates its synthetic grid and replays its functions' `arglog` cases, writing hex results.
- [x] Synthetic grids:
  - Integer (Z, A) over every (Z, N) whose reads stay inside the tables, Z = 1…120; just outside that domain, the C++ is expected to throw (D3 default).
  - `Single` Z and A on the integer grid plus quarter steps.
  - Energies from −1 to 100 MeV, 0.01 MeV steps below 10 MeV and 0.1 MeV above, plus ±1 ULP around `Etrans`, `Econd` and the `Eeff0 > 0.5` threshold of `U_Temp`/`U_Temp2`.
  - Spins 0…80 in steps of 0.5.
  - 10⁵ seeded random `Single` tuples per function inside the ranges seen in M5.2.
  - The named edges: `BFTF` `RX = 30`, `Getyield` with `T_high = T_low`, `U_Valid` with `I_Z = 0`.
  - `Beta_Equi` additionally on the continuation chains GEF runs (`GEF.bas:5697-5873`: `IZ1 = 10…Z−10`, each result the next start) for the four capture systems.
- [x] Driver checks (D1):
  - every driver reproduces the `arglog` results bit for bit;
  - `fn_c_equiv` passes for every cut function and both extracted pieces.
- [x] Goldens (D9): fingerprints committed through `harness.golden`; full outputs in the store as `m5-<driver>`.

**Done when:** every driver builds, passes both checks and has its golden.

### M5.4 C++ port (`gef_physics`)
- [x] Port in dependency order, each from its `fbline` output (D10), with provenance comments and the API of D8: helpers → masses → barriers → level densities and temperatures → shape and yields (`Beta_Equi` last) → rotation, GDR and `u_accel` → `p_egamma_low_table` → `e2_cascade`. `e2_cascade` takes the `Isotab` entry the caller found with `n_iso_mat`/`iso_for_mat` (M4); if later BASIC code reads `J` or `K` before reassigning them, it also returns their final values.
- [x] Diagnostics of D7 and constants of D13.
- [x] Tests (`physics_<group>_test.cpp`): fingerprint against the committed golden. With the store present, every value is compared, and the first difference is reported with ULP distance and the input that produced it. Every `arglog` case is replayed against its logged result. The out-of-domain cases expect the throw (or the reproduced read, for D3 sites).

**Done when:** every test passes in `dev-gcc`, `dev-clang` and `release-exact`; `asan-ubsan` and `tsan` pass without `[slow]`.

### M5.5 Reachability and quirks
- [x] D3: for every out-of-range index found in M5.2, establish what BASIC reads, reproduce it behind a quirk switch and register the quirk. If none is found, record that the table interior covers every captured call.
- [x] D7: whether `U_MASS`'s negative-input print and `Beta_Equi`'s non-convergence print are reachable in the captures and on the grids; for `Beta_Equi`, what `#f` refers to at its call sites (emitted C and fbc runtime). Register a quirk if a print is reachable.
- [x] Register the confirmed quirks among the facts of §4: `Getyield` division by zero, the `BFTF` `RX = 30` hole, the `U_Valid` `I_Z = 0` division, the E2 cascade's ground-state stop (`R_SPI(K) = CInt(J_frag)` at `J = Jfrag`, `event_loop.md`), the unchecked `Array_Eg2_*(100)`, and the `J`/`K` leak if later code reads them.

### M5.6 CI, documentation and close-out
- [x] `scripts/ci.sh` covers the new library, tests and pytest; `harness.golden check` covers the M5 goldens.
- [x] Update:
  - `QUIRKS.md`: new quirks; B-001 and B-004 findings for the physics functions.
  - `COVERAGE_MATRIX.md`: the T1 cells M5 closes ("Isomer stop in the gamma cascade", "Masses and shell/deformation tables", "`P_Egamma_low` cross-section table") and its contributions to "Superheavies", "Q values" and "Prompt-gamma spectra".
  - `IMPLEMENTATION_STRATEGY.md`: M5 status.
  - `CODING_STANDARDS.md`: if the physics module adds conventions.
  - `CURRENT_PROJECT_STATE.md`.
- [x] Mark this plan complete with completion notes.

## 6. Exit gate (all must hold)

| Gate | Requirement |
|---|---|
| G1 Tooling | Drivers keep their emitted C; `fn_c_equiv` passes for every cut function and both extracted pieces; `arglog` is proven neutral |
| G2 Captures | `arglog` and `-exx` captures stored for the four systems of M5.2 |
| G3 Bit-exact | Every function of §3 and both extracted pieces equal BASIC bit for bit on the synthetic grids and on every captured call, in `dev-gcc`, `dev-clang` and `release-exact`; NaN sign and payload excepted (B-001). Any other exception has a written analysis and the user's approval (D12) |
| G4 Domain | Every out-of-range table access reached in the captures is reproduced explicitly with a quirk entry, or none is reached (D3) |
| G5 Diagnostics | The `U_MASS` and `Beta_Equi` print conditions are returned as diagnostics, and their reachability is recorded (D7) |
| G6 CI | `scripts/ci.sh` passes in all presets; clang-tidy, clang-format, ruff and basedpyright clean; goldens current |

## 7. Out of scope (later milestones)

- The random functions, including the `P_Egamma_low` sampler (M8).
- The pre-pass width block `GEF.bas:4269-4421` (M9), the per-nucleus table builder (M7) and the event stages that call M5 functions, including the cascade's histogram fills (M10).
- Writing the D7 diagnostics to the console or `#f` (M7, M13).
- `Branchings.bas` itself (M11); M5 provides `U_Q_beta_minus`.

## 8. Risks and open questions

| Item | Handling |
|---|---|
| A driver compiles a function differently from GEF | D1's C comparison, plus each driver reproducing the `arglog` results of the real binary |
| An `-exx` run stops at an unrelated out-of-bounds access before reaching M5 sites | The `arglog` replay covers every M5 call up to K; the stop is recorded for its owning milestone (M5.2) |
| `arglog` output too large | K is configurable; the default is set from the first capture, and the size is recorded |
| `Beta_Equi` grids are slow (up to ≈5·10⁵ evaluations per call) | Grid size bounded by the continuation chains and the captured calls; long tests tagged `[slow]` |
| `-O3` changes a result | D11 |
| An expression shape outside `FBC_ARITHMETIC.md` rules R1–R10 | Ported from the `fbline` output; the T1 tests catch any remaining difference (B-004) |
| The two cascade copies differ in their emitted C | Each copy is checked against the C++ function separately; a difference becomes a parameter of the function and a quirk entry |

## 9. Completion notes

### M5.1 (2026-10-12)

- **Driver tooling.** `harness.driver` compiles with `fbc -R` and keeps `<name>.c` (`c_file`, `c_sha256` in `build.json`, `DriverBuild.c_source`); `run --work-file`; directive `'@include-driver <file>` (shared driver helpers such as `harness/drivers/m5_common.bi`, hashed into the build key and checked by `harness.golden check`). `harness.build --fbc-option=OPT` (in the build id when present).
- **`fn_c_equiv`** (`tools/fbsrc/fn_c_equiv.py`, 24 pytest cases): function mode compares one function's C after dropping `#line`/source-echo lines and renumbering `label$N`, `vrN`, `tmpN`, `TMP$N$M`; piece mode re-emits the driver with `-g`, checks that this C equals the kept C, and compares GEF.c and driver statements per source line, with scope suffixes dropped. First result: `Gaussintegral`, `Bell`, `U_Box`, `EVEN_ODD`, `Floor` of `m5_helpers` equal GEF.c. Limitation found while testing: a loop at module level gives fbc an extra label at `Next`, so a piece should be compared with a reference inside a procedure (relevant for the E2 cascade, which is module-level code).
- **`arglog`** (`harness/ARGLOG.md`): generated by `python3 -m harness.arglog_patch` (`--check`). Wrappers `hlog_<name>` behind function-like macros, with `#undef`/`#define` around every definition (fbc refuses a `#define` of a declared procedure; `#undef` removes the symbol). Site logs for `e2_light`, `e2_heavy`, `pegl_table`. POSIX I/O and static buffers (no FreeBASIC file numbers, no heap). Deviation from the text above, decided while building it: after the first K calls (`GEF_ARGLOG_MAX`, default 10⁵) the patch also logs every 2^j-th call in the j-th doubling of the call count (`GEF_ARGLOG_SPREAD=1`, default), about K/2 more records per doubling, so that the logs cover the whole run and not only its first calls. `Beta_Equi` additionally logs `global.f`.
- **Line numbers.** Without `-d GEF_ARGLOG` the emitted C of `m5-arglog` equals the `seed`+`scope` emission apart from source-echo comments. Found on the way: after an `#endif`, fbc's `#line N` numbers the next line N + 1 (after an `#include` it does not; the existing patches use the latter form and are correct, as their rndlog site tags show).
- **Neutrality (gate G1).** Same seed as the stored seed runs, `GEF_ARGLOG_MAX=20000`: Rn-215 short (seed 20261007) identical to `m1-g23-rn215-n-a` over 244 files, Cf-252 (seed 20261008) identical to `m1-g4-cf252-ref1-independent` over 42 files (`harness.compare_runs`, timestamps masked, `probes/` allowed only in the arglog run). These runs are the captures `m5-arglog-rn215` and `m5-arglog-cf252`.
- **Correction of §4:** the cascade's `J`, `K` are `Single` scope locals (row "E2 cascade" amended).

### M5.2 (2026-10-12)

- **Inputs.** `harness/inputs/m5_u235_n.in` (CN 92/236, `EN`, 0.0253 eV and 14 MeV, `Fenhance` 1) and `harness/inputs/m5_superheavy_sf.in` (Sg-264 `GS`, `Fenhance` 1). `Fenhance` 1 rather than lower: with it each run takes under two minutes and every function is still called (U-235 at 14 MeV reaches the pre-pass level densities).
- **Captures** (store, `GEF_ARGLOG_MAX=20000`, spread on): `m5-arglog-rn215` (549 MB), `m5-arglog-cf252` (381 MB), `m5-arglog-u235` (seed 20261012, 365 MB), `m5-arglog-sh264` (seed 20261013, 192 MB). Every log holds exactly the calls the sampling rule selects (`harness.arglog summary`: `complete=True` for all 49 files of all four).
- **`-exx` runs** (`seed` patch set, `--fbc-option=-exx`, build `seed-1a1bb1c529a8`, which links `fb_ArrayBoundChk`): all four systems ran to the end with exit 0 and no runtime error; Rn-215 and Cf-252 outputs are byte-identical to the unchecked reference runs. Captures `m5-exx-rn215`, `m5-exx-cf252`, `m5-exx-u235`, `m5-exx-sh264`. **D3 result: GEF indexes no array out of bounds in these four runs** (not only in the §3 functions), so the C++ keeps the default (throw outside the table) and no D3 quirk is needed for the captured systems.
- **Calls per function** (calls, logged records in parentheses). Argument ranges: `python3 -m harness.arglog summary <capture>/work/probes/arglog`.

| Function | Rn-215 | Cf-252 | U-236 | Sg-264 |
|---|---|---|---|---|
| LyMass | 1934867593 (184761) | 1044409971 (175936) | 378137675 (161539) | 16055767 (115679) |
| LyPair | 1151756962 (177574) | 917427757 (173998) | 97496639 (141901) | 7402319 (104457) |
| FEDEFOLys | 804875586 (172281) | 458989468 (164007) | 36423642 (127784) | 3379136 (93199) |
| LDMass | 805218454 (172286) | 470279916 (164351) | 36717118 (127928) | 3446486 (93462) |
| AME2020 | 659485119 (170062) | 352835708 (160767) | 30379976 (124833) | 2907809 (91358) |
| U_SHELL | 1095794581 (176720) | 1032418492 (175753) | 91071742 (141117) | 8215869 (106046) |
| U_SHELL_exp | 42568526 (130392) | 2 (2) | 2659545 (90388) | 2 (2) |
| U_SHELL_EO_exp | 67069631 (136374) | 411 (411) | 4078864 (95933) | 47 (47) |
| U_MASS | 287384354 (157540) | 232834746 (154211) | 12138206 (111853) | 1707742 (83341) |
| ECOUL | 89358514 (140908) | 17457244 (117048) | 149533574 (148253) | 4201582 (96412) |
| U_Q_beta_minus | 118656 (44832) | 58028 (34507) | 17940 (17940) | 4068 (4068) |
| U_Valid | 1 (1) | 1 (1) | 1 (1) | 1 (1) |
| U_Delta_S0 | 0 | 0 | 0 | 0 |
| BFTF | 41705955 (130182) | 615 (615) | 2594690 (90135) | 71 (71) |
| BFTFA | 13900663 (113574) | 104 (104) | 863484 (73491) | 12 (12) |
| BFTFB | 13903289 (113577) | 307 (307) | 866303 (73535) | 34 (34) |
| U_alev_ld | 811966826 (172389) | 794974377 (172130) | 79095573 (139310) | 6477195 (102650) |
| U_levdens | 22907827 (121185) | 0 | 1403549 (80965) | 0 |
| U_levdens_Egidy | 22907827 (121185) | 0 | 1403549 (80965) | 0 |
| U_levdens_FG | 10652219 (110402) | 0 | 714518 (71164) | 0 |
| U_Temp | 794364933 (172121) | 794974377 (172130) | 77950019 (139030) | 6477195 (102650) |
| U_Temp2 | 6949674 (103573) | 0 | 431036 (63469) | 0 |
| TEgidy | 813898292 (172419) | 795484124 (172138) | 85438894 (140429) | 6535352 (102764) |
| TRusanov | 1313 (1313) | 101 (101) | 1409 (1409) | 11 (11) |
| Getyield | 10504 (10504) | 808 (808) | 11272 (11272) | 88 (88) |
| F1, F2 | 6565 (6565) | 505 (505) | 7045 (7045) | 55 (55) |
| Masscurv | 1313 (1313) | 101 (101) | 1409 (1409) | 11 (11) |
| Masscurv1, Masscurv2 | 2626 (2626) | 202 (202) | 2818 (2818) | 22 (22) |
| De_Saddle_Scission | 57019449 (133920) | 60001515 (134648) | 2121003 (86570) | 600165 (68755) |
| beta_light | 527826 (66494) | 47874 (31968) | 617142 (69285) | 5742 (5742) |
| beta_heavy | 175942 (50996) | 15958 (15958) | 205714 (52857) | 1914 (1914) |
| Z_equi | 1537764 (82013) | 141198 (47649) | 1824456 (84253) | 16170 (16170) |
| Beta_Equi | 87971 (40996) | 7979 (7979) | 102857 (42857) | 957 (957) |
| Gaussintegral | 31519613 (125390) | 227000 (54187) | 2955937 (91546) | 26402 (23201) |
| Bell | 512588 (66018) | 47066 (31766) | 608152 (69004) | 5390 (5390) |
| U_Box | 1313 (1313) | 101 (101) | 1409 (1409) | 11 (11) |
| EVEN_ODD | 37999836 (128554) | 40000000 (129531) | 1399912 (80936) | 400000 (62500) |
| U_Ired | 82949346 (140125) | 80000000 (139531) | 3230860 (92620) | 800000 (72500) |
| U_IredFF | 37999836 (128554) | 40000000 (129531) | 1399912 (80936) | 400000 (62500) |
| U_I_Shell | 86016992 (140500) | 98538238 (142028) | 3387295 (93231) | 849213 (73268) |
| E0_GDR, Width_GDR | 895779709 (173668) | 857072654 (173077) | 32269123 (125756) | 8859394 (107303) |
| Efac_def_GDR | 893706759 (173636) | 856968906 (173076) | 32192211 (125718) | 8850171 (107285) |
| u_accel | 25667127 (122532) | 36100145 (127627) | 973534 (75211) | 125238 (45654) |
| site e2_light, e2_heavy | 18999918 (118554) | 20000000 (119531) | 699956 (70936) | 200000 (52500) |
| site pegl_table | 297902253 (158182) | 285656302 (157435) | 10730737 (110479) | 2950057 (91523) |

`U_Delta_S0` is never called in these runs (it would return 0 anyway); `U_Valid` once per system. At the logged `Beta_Equi` calls `f` is 0 or 1 (`global.f` in all four captures): file number 0 is the console; what #1 refers to at those calls is established in M5.5 (D7).

### M5.3 and M5.4 (2026-10-13)

Drivers, C++ port and tests were built group by group (each driver replayed against every capture before its C++ was integrated). Store goldens `m5-<group>` with committed whole-file fingerprints (`Cpp_implementation/tests/golden/m5-<group>/files.txt`).

| Group | Driver | C++ | Grid files (lines) | Store golden | Replayed records (4 captures) |
|---|---|---|---|---|---|
| helpers | `m5_helpers` | `helpers.cpp` | 8 (639,446) | 21 MB | Gaussintegral, Bell, U_Box, EVEN_ODD |
| masses | `m5_masses` | `masses.cpp` | 26 (3,056,490) | 112 MB | all 13 functions (U_Delta_S0 never called) |
| barriers | `m5_barriers` | `barriers.cpp` | 6 (956,778) | 41 MB | BFTF, BFTFA, BFTFB |
| level_density | `m5_level_density` | `level_density.cpp` | 16 (2,445,447) | 180 MB | all 8 |
| shape | `m5_shape` | `shape.cpp` | 22 (1,628,187) | 83 MB | all 11 |
| rotation | `m5_rotation` | `rotation.cpp` | 14 (2,336,231) | 67 MB | all 7 |
| P_Egamma_low table | `m5_egamma_table` | `gamma_table.cpp` | 2 (146,817) | 34 MB | site pegl_table (517,619) |
| E2 cascade | `m5_e2_cascade` | `e2_cascade.cpp` | 4 (452,990) | 124 MB | sites e2_light, e2_heavy (723,042) |

- **Driver checks (D1):** every driver's replay reproduces every logged record of all four captures token for token (`harness.arglog replay-check`); `fn_c_equiv` passes for all 79 cut functions of the eight drivers and for the three pieces (`P_Egamma_low` table 73 statements, light cascade 91, heavy cascade 89). The two cascade copies compile to identical C apart from the `Dim` of `E_E2_tot` at `GEF.bas:9310`, so one C++ function serves both (D6) and both copies are checked against it.
- **T1 (G3):** 58 test cases `[T1][physics]` (`physics_<group>_test.cpp`) regenerate every grid file and compare it with the golden (fingerprint; every line when the store is present, first difference with ULP distance), and replay every captured call. All pass in `dev-gcc`, `dev-clang` and `release-exact` (about 14.8 million assertions each); `asan-ubsan` and `tsan` pass without the `[slow]` cases. No ULP difference and no NaN-only difference was found, so neither D11's `-O0` fallback nor a D12 analysis is needed.
- **API (D8):** as in the group headers. Deviations decided while porting: `p_egamma_low_table` returns the table and the final values of the piece's locals; `e2_cascade` takes `n_iso`/`i_iso` from the caller (who calls `n_iso_mat`/`iso_for_mat`, `GEF.bas:9318-9321`) and returns the live outputs; the counters `Ng*`, `Ngtot`, `Egtot1000` and the histogram fills stay with the caller (M10), whose part the test reproduces. Parameters BASIC never reads (Getyield's `E_shell`, `dE_defo`, `T_high_mac`, `Imode`; Masscurv1/2's `kappa4`; Z_equi's `Imode`) stay in the signatures (`[[maybe_unused]]`) so that call sites keep BASIC's argument evaluation.
- **Dead outputs of the cascade site.** The arglog site records also log the scope locals `J`, `K`, `RJeff`, `Eg`, `Nspectrum` at the cut's exit. Each is written before it is read on every path through `GEF.bas:9240-9486` (the heavy prologue overwrites `Nspectrum` at 9390) and the Scope ends at 9486, so their exit values are never used; when the J loop does not run they hold values of earlier code that the site does not log. The replays (driver and C++) echo these five tokens and recompute every other one; `E2Cascade` carries only live values. With `J` and `K` local to that Scope, the §4 concern about a `J`/`K` leak does not arise.
- **Static locals (D13):** `fgamma` (U_levdens_FG, U_Temp, U_Temp2) and `e2` of u_accel are never assigned in the emitted C and are `constexpr`; the E0_GDR statics, `u` and `hbarc` of u_accel and `Izaehl` of AME2020 do not feed any result in the emitted C and are not ported.
- **Tooling fixes found on the way:** `fn_c_equiv` piece mode re-emitted the driver with `-c` only, which makes fbc emit the module-level code as a constructor; it now passes `-m <stem>` (README: `emit_c`'s `GEF.c` has the same property, which does not affect procedure bodies). `NucPropJEFF33.bas` reads its first `DATA` without a `Restore`, so a driver must include it before any other file with `DATA` (as GEF does).
- **Worker substitution (disclosure):** the group workers ran on the `task` role (`anthropic/claude-haiku-5-5`); two of them stopped on that model's rate limit, and the remaining work of the shape C++ port, the `P_Egamma_low` integration and the whole E2 cascade (driver, C++, test) was done in the orchestrator session.

- **Grid coverage beyond the plan's list (review notes, accepted):** `Beta_Equi`'s continuation chains (M5.3) are covered by the replay, not by a separate grid: the first 20,000 calls of each capture are complete chains (a chain is IZ1 = 10 … Z − 10, i.e. Z − 19 calls: 298 complete chains for Rn-215, 273 for U-236, all 101 for Cf-252 and all 11 for Sg-264), each start the previous result. `Masscurv*`, `De_Saddle_Scission` and the `P_Egamma_low` table take continuous Single Z/A and read at most DEFOtab; their structured grids cover integer Z/A around the fission range and the random tuples the rest. The masses quarter-step block steps N by 0.5 (the round-half-to-even ties); `ECOUL` has no quarter-step block (its random tuples are continuous). The barriers integer grid uses N = 1 … 202 for every switch (the single-cell reads of `I_Switch` 1 and 3 are not evaluated at N = 0 and 203), and its quarter-step block covers RZ 84–96 × RA 225–245; the random tuples cover the captured RZ 84–107 × RA 210–265.

### Review round 1 (2026-10-13)

Three reviewers (`reviewer` role, `anthropic/claude-opus-5-5`) on snapshot `d8da542`, with one frozen brief. Round 2 on `226d7e8`: every finding resolved or closed by a recorded decision, no new blocker; all three approve (harness and tooling; masses, barriers, level densities, helpers; shape, rotation, the `P_Egamma_low` table, the E2 cascade). Port fidelity: one defect (`EVEN_ODD` took the 1E-3 test in positive form, so a NaN `R_EVEN_ODD` went to the other branch; fixed to the compiled `!(... >= 1E-3)`, NaN added to the grid). Test gaps fixed: print flags asserted and printed lines compared (U_MASS, BFTF, Beta_Equi), `Beta_Equi` pass-through (D8) and N around the threshold, throw/no-throw pairs for masses, the `P_Egamma_low` table and the E2 cascade, the barriers random tuples widened to the captured ranges, `replay-check --require` reports logs without a replay. Quirks added: Q-040, Q-041; Q-037/Q-038 texts corrected. Documented, not changed: the `arglog` spread sample is not uniform (first K records are; `ARGLOG.md` Limits), `AME2020` calls inside `U_Q_beta_minus` are not logged, call sites are the last line of a continued call. The regenerated goldens have new store ids `m5-helpers-2`, `m5-masses-2`, `m5-barriers-2`, `m5-shape-2`; the superseded captures stay in the store (captures never change).

### M5.5 (2026-10-13)

- **D3:** the `-exx` runs of the four systems raise no bound error (M5.2), so no table index of a §3 function, nor anything else in GEF, leaves its array in these runs. The C++ throws `std::out_of_range` outside the tables; every group that reads a table tests throw/no-throw pairs at the table edges (masses, barriers, level densities, the `P_Egamma_low` table, the E2 cascade). The one unchecked write found while porting, `Array_Eg2_*(100)`, is Q-039 (largest Ig2 in the captures: 17).
- **D7:** none of the print conditions is reached in the captures: `U_MASS` gets Z ≥ 26, A ≥ 63; `BFTF*` get `I_Switch` 0–5; the C++ replay of 92,789 `Beta_Equi` calls asserts that none would print. On the grids each is reached: `U_MASS` for four negative inputs, `BFTF*` for `I_Switch` −1 and 7 (18 lines), `Beta_Equi` for 696 + 3 grid and 1,712 random inputs (all unphysical Z/A splits except the three threshold rows). The tests assert each flag on every grid line and rebuild the printed lines with `gef::fb::PrintFile` against the driver's `stdout.txt` / `Beta_Equi_print.txt` (fingerprinted in the goldens); `Beta_Equi`'s returned N is checked at N = 996 … 1001 around the `N > 998` threshold. `f` is 0 or 1 at the `Beta_Equi` calls (console, or file number 1: the `pfis`/`ptb` files are opened with `FreeFile` at `GEF.bas:4150, 4179, 10057`); since no captured call prints, which file #1 is at those calls has no effect on the captured output and is left to M7/M13, which own the file state. The `U_MASS` and `BFTF` prints go to the console and are the intended diagnostics; no quirk. `Beta_Equi`'s destination, the shared `f`, is Q-041.
- **Quirks:** Q-037 (`BFTF` RF hole at RX = 30, confirmed by fbc C; RX 36.3–46.6 in every captured call), Q-040 (`TRusanov` computes a pairing floor and does not use it; found by the review), Q-041 (`Beta_Equi` prints to the shared file number `f`), Q-038 (the E2 cascade stops before its first gamma when any state has spin `CInt(J_frag)`; confirmed in output: 248–1,036 cascades per copy and capture), Q-039 (`Array_Eg2_*(100)` without bound). Assessed and not registered: `Getyield` with `T_high = T_low` gives an infinite effective temperature, a Fermi factor of 1/2 and a finite yield (0 or exp(…)/2 on the grid), not reached (T_high ≥ 0.426 > T_low ≤ 0.420 in the captures); `U_Valid` with `I_Z = 0` divides by zero, but the `I_Z < 76` test sets the result to 0 anyway (0 for all such grid rows), so it has no effect.

### M5.6 and exit gate (2026-10-13)

- **CI:** `scripts/ci.sh` covers `gef_physics` and its tests through the CMake presets, and the M5 goldens through pytest (`harness/tests/test_golden.py::test_committed_goldens_are_current` runs `harness.golden check`). Full run on `226d7e8`: PASS in every step (toolchain; build and test `dev-gcc` 888 s, `dev-clang` 161 s, `asan-ubsan` 705 s and `tsan` 1026 s without `[slow]`, `release-exact` 375 s; clang-tidy; clang-format; ruff; basedpyright; pytest 344 s; validation manifests; reference store). The toolchain manifest was refreshed for Python 3.14.8.
- **Documents:** `QUIRKS.md` (Q-037–Q-041; B-001 finding 3; B-004 M5 result), `COVERAGE_MATRIX.md` (3 T1 cells closed; contributions to Superheavies, Q values, Prompt-gamma spectra), `IMPLEMENTATION_STRATEGY.md` (M5 status), `CODING_STANDARDS.md` (canonical patch order), `CURRENT_PROJECT_STATE.md`.
- **Exit gate:**

| Gate | Result |
|---|---|
| G1 Tooling | Drivers keep their C; `fn_c_equiv` ok for all 79 cut functions and the three pieces; `arglog` neutral on Rn-215 (244 files) and Cf-252 (42 files) |
| G2 Captures | `m5-arglog-{rn215,cf252,u235,sh264}` and `m5-exx-{rn215,cf252,u235,sh264}` stored |
| G3 Bit-exact | Every §3 function and both pieces equal BASIC on the grids and every captured call in `dev-gcc`, `dev-clang`, `release-exact`; no NaN-only or other exception, so no D12 analysis |
| G4 Domain | No out-of-range access in the `-exx` runs; C++ throws outside the tables (tested at the table edges) |
| G5 Diagnostics | U_MASS, BFTF and Beta_Equi print conditions returned as flags, asserted, and their printed lines rebuilt; reachability recorded (none in the captures; all on the grids) |
| G6 CI | `scripts/ci.sh` passes in all presets; tidy, format, ruff, basedpyright clean; goldens current |

- **Review:** approved by all three reviewers in round 2. After the approved snapshot only documentation changed (these notes, `QUIRKS.md` Q-041 counts, `CURRENT_PROJECT_STATE.md`, the strategy status) and the header comments of two test files (golden names), which `clang-format` checked.

