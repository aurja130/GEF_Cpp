# GEF in C++ — Project Vision

## 1. Purpose

Recreate the GEF fission model code (K.-H. Schmidt, B. Jurado; version 2025/1.2, FreeBASIC) in C++. The result keeps GEF's physics but is written with modern engineering practice and with the capabilities C++ offers.

The project only succeeds if we can **prove** the recreation is correct. Every statement of the form "the C++ code is GEF" has to rest on tests that run the original BASIC binary and the C++ binary on the same inputs, compare what they produce, and agree within criteria defined in advance.

Two questions drive everything below:

1. **Fidelity:** does the C++ implementation behave like the BASIC implementation, piece by piece and as a whole?
2. **Evidence:** can a third party rerun our comparison and reach the same conclusion?

## 2. Starting point

| Asset | Location | Notes |
|---|---|---|
| BASIC source | `Reference/GEF_code/source/` (submodule, `ba9f0aa`) | `GEF.bas` has 18,176 lines: one monolithic module-level program plus ~120 functions. The rest are textual includes, mostly data tables (nuclide properties, JEFF-3.3 decay branchings, masses, shell/deformation tables). |
| Reference binary | `validation/test_run/gef_reference` | Built on Linux x86-64 from the submodule source, with debug info. |
| Reference library | `validation/reference/gefy_nfy_ENDF/` (143 tapes), `gefy_sfy_ENDF/` (239 tapes) | GEFY ENDF-6 MF8 MT454/MT459 yields, produced by GEF 2025/1.2 from the sequence files `gefy_nfy` / `gefy_sfy`. |
| Test run | `validation/test_run/` | Rn-215 (n,f), `Fenhance=10`, 59 energies from thermal to 30 MeV. Matches the reference statistically (independent-yield z_rms ≈ 1 against Poisson noise). |

Known properties of the original that shape this vision:

- **Non-deterministic by construction.** `Randomize,3` seeds FreeBASIC's Mersenne Twister from the clock, so two BASIC runs never agree bit for bit. Comparison must be statistical unless we pin the seed ourselves.
- **Numerical semantics specific to FreeBASIC.** Physics is mostly single precision. Float-to-integer conversion rounds half to even. `\` rounds its operands and then truncates. `Erf`, `Min` and `Max` are home-made. Several `For` loops step over floating-point values.
- **Global, stateful control flow.** The program flow uses `GoTo` labels. Statics persist across energy steps. Includes are re-entered inside loops. Files are opened in append mode and coordinated across processes through `ctl/` files.
- **Cost.** One nucleus over 59 energies takes ~1 h 46 min in a single process, so regenerating the full neutron-induced library takes ~250 CPU-hours.

## 3. What we are building

A C++ implementation of GEF that is:

- **Faithful.** It reproduces every observable the BASIC code produces: yields, isomeric ratios, prompt neutron and gamma emission, kinetic energies, multi-chance fission, uncertainties, covariances, cumulative yields, and ENDF-6 output. Agreement is to within the tolerances defined in §4.2 and §4.5.
- **Structured.** It is split into a reusable library and a thin command-line front end. Inputs and model parameters are explicit values. The model has no hidden global state. Each physics stage (mode selection, fragment sampling, energy sorting, emission, decay) is a separately testable unit.
- **Deterministic on demand.** Every source of randomness comes from an injected, seedable generator. A fixed seed gives identical output on every run, every thread count and every platform we support.
- **Parallel by design.** Events, perturbed-parameter sets and energy steps run concurrently inside one process. This replaces the file-based `ctl/` coordination of the original.
- **Compatible at the edges.** It accepts GEF's existing input formats (`file.in`, sequence files, `Options(...)`). It writes output in GEF's formats (ENDF-6 tapes, `out/` result files, `dmp/` analyzer dumps), so existing downstream tools and our comparison harness work on both implementations unchanged.
- **Built with modern C++ practice.** A current C++ standard, value semantics and RAII, strong types for physical quantities and nuclide identifiers, compile-time or embedded data tables, warnings-as-errors, sanitizers and static analysis in CI, and a standard build system and test framework.

### Fidelity first, improvements second

The first goal is a faithful recreation, including the BASIC code's quirks:

- When the original contains a suspected defect, the C++ code reproduces it by default and the defect is documented.
- A corrected behaviour may exist only behind an explicit, named switch that is off by default.
- Departures from the original are allowed only when the test suite measures them, they are documented, and they have been deliberately approved.

Suspected defects found so far:

- `Ubound(_NZPOST,3)` is called on a 2-D array (`Spectra.bas:1759`).
- `Var_PZ_S3_olap_curv` is probably never perturbed.
- `Parameters.bas` is re-included per system, which may override `MyParameters.dat`/`Fitpar.dat` in batch mode.
- The comment in the `NN.dmp` header says "protons" for a neutron distribution.

### Out of scope for the recreation

- The Windows GUI, the FreeBASIC screen graphics and plotting, and the interactive console dialogue.
- Process coordination through `ctl/thread.ctl`, `done.ctl` and `sync.ctl`. In-process parallelism replaces it; the result files it would have coordinated are still produced.
- Code the BASIC build never runs: inactive NucProp/branching variants, the `GEFSUB` block, `ENDF_EOT.bas` and `Extend.bas`. It may be ported later as optional data sources if needed.

## 4. How we prove it works: differential and integral testing

### 4.1 The method

For every test case:

1. Run the **BASIC reference binary** on a test input.
2. Run the **C++ binary** on the same input.
3. **Compare** the two outputs with a metric suited to the observable, and accept or reject against a predefined tolerance.

The results are recorded, versioned and reproducible. Tests come in two kinds:

- **Differential tests** isolate one component (a function, a table, a sampling distribution, a single physics stage) and compare its behaviour between the two implementations. A failure points to a specific piece of code.
- **Integral tests** run complete GEF calculations and compare everything they produce. They catch interaction effects, state leaking between energy steps or perturbation passes, and errors in bookkeeping, normalisation and output formatting that component tests cannot see.

Both kinds are required. Passing differential tests without integral tests proves the parts but not the assembly. Passing integral tests without differential tests can hide compensating errors and cannot locate failures.

### 4.2 Test tiers

| Tier | Kind | What is compared | Acceptance |
|---|---|---|---|
| **T0: Data** | differential | Embedded tables: nuclide properties, isomer table, decay branchings, masses, shell and deformation tables, ENDF MAT numbers | Exact equality, entry by entry |
| **T1: Deterministic functions** | differential | Pure functions such as masses (`LyMass`, `AME2020`, `U_MASS`), shell and pairing terms, barriers (`BFTF*`), level densities and temperatures, `Getyield`, `Masscurv`, `Erf`, `U_Gauss`, rounding helpers. Also the per-nucleus tables built before the event loop (mode yields, widths, `EPART` energy sorting, Z(A) polarisation) | Bit-exact where both sides use the same precision; otherwise a stated ULP or relative bound justified per function |
| **T2: Samplers** | differential | Random distributions (`PGauss`, `PBox2`, `PMaxwell*`, `PLinGauss`, `PExp`, `PPower*`) and single physics stages driven with controlled random inputs | Same outputs for the same random stream (T2a). Same distribution under independent streams, checked with KS/χ² (T2b) |
| **T3: Seeded trajectory** | differential/integral | Whole event histories with both codes on the same fixed seed and the same FreeBASIC-compatible generator | Identical event-by-event output for as long as the arithmetic is reproduced exactly. The point of first divergence is reported |
| **T4: Single-system integral** | integral | Every output of one GEF calculation: all `dmp` analyzers, `out/` sections, ENDF MT454/MT459, uncertainties, covariances and correlations | Statistical agreement (§4.5) |
| **T5: Library integral** | integral | Full regeneration of `gefy_nfy` and `gefy_sfy` compared with `validation/reference/` | Statistical agreement across all 382 tapes and all energies, with no systematic trend over Z, A or E |

T3 is the strongest evidence and also the most expensive to reach. It requires the C++ code to offer, as an option, a generator that reproduces FreeBASIC's Mersenne Twister. That includes FreeBASIC's own seeding (an LCG fill rather than standard `init_genrand`), its conversion of random numbers to `Double`, and `PGauss`'s cached second value. T3 is a goal we pursue, not a precondition for release. T4 and T5 are the release criteria.

### 4.3 Making the BASIC side testable

The submodule stays untouched. Reference behaviour is extracted through a **reference harness**: versioned patches and driver programs applied to a copy of the BASIC source.

- **Seed control:** replace the clock seed with a seed set from the command line, so BASIC runs are repeatable and T3 is possible.
- **Function drivers:** small FreeBASIC programs that include the table and function sources and call T1 functions on input grids, writing full-precision results.
- **Probes:** optional dumps of intermediate state (per-nucleus tables, per-event records) for T2 and T3.
- **Clean execution:** every reference run happens in a fresh directory. The original appends to `out/`, `ENDF/` and `dmp/` and keeps `ctl/` state between runs, which is exactly how the two-tape `GEFY_86_214_n.dat` in the test run came about.

Reference outputs are generated once per input and seed, stored with their input, binary hash and seed, and reused. The cost of the BASIC side is paid once.

### 4.4 Coverage: the dimensions of GEF

The suite is complete when every dimension below is exercised at both the differential and the integral level. Coverage is tracked as a matrix, and uncovered cells are visible.

**Fissioning system**
- Z from pre-actinides to superheavies (reference range Z = 86–106). Light and heavy isotopes per element. Odd and even Z and N.
- Systems at the edge of the model: unbound compound nuclei, very low fissility, isotopes outside the isomer and decay tables (blind β⁻ handling, `IMATmax.ctl`).

**Entrance channel and kind of fission**
- `EN` (neutron-induced, including target isomers `EN[n]`), `GS` (spontaneous), `IS n` (spontaneous from an isomer), `EB` (excitation energy above the barrier), `EP` (proton-induced), `EA` (alpha-induced), `FC`, `ES` and `EM` (excitation-energy spectra).
- Single-system lines and two-system correlation lines.

**Energy**
- Thermal, fast, and energies around each threshold that changes the code path: the start of the multi-chance pre-pass (`Eexc_min_multi`), each additional fission chance, pre-equilibrium emission, and the maximum valid energy.
- Single-energy runs and multi-energy runs, which follow different ENDF state-machine paths (`N_E_steps = 1`, `2`, `N+3`).

**Options and modes**
- `ENDF`, `ERR`, `PTB`, `RANDOM`, `COV`, `COR`, `LMD`/`LMD+`, `NEO`, `LOCAL`/`GLOBAL`, `NOSUPP`, `MYPARAMETERS`, `DPARFAC`, `MODE(i)`, `FIT`/`NITER`.
- Several `Fenhance` values, which change the event counts and the number of perturbed sets.
- The `Fitpar.dat`/`MyParameters.dat` override paths.

**Observables**
- Fragment yields: Z, A pre/post-neutron, Z×A, charge polarisation, isomeric ratios, independent and cumulative yields.
- Energetics: TKE and kinetic energies, Q values, excitation energies, fragment spins.
- Emission: prompt neutron multiplicities and spectra (ν(A), local distributions), prompt gamma spectra and multiplicities, pre-scission and multi-chance emission.
- Delayed and decay quantities: decay heat, delayed neutron data, cumulative chains.
- Uncertainty products: perturbed-parameter distributions, standard deviations, covariance and correlation matrices.
- Output formats: ENDF-6 syntax and section bookkeeping (validated with an independent checker, e.g. `Reference/GEF_data/.nea/endf_format_check.py`), `out/` and `dmp/` content.

**Internal behaviour**
- Rejection-loop paths, isomer stops in the gamma cascade, state that persists across energy steps and perturbation passes, normalisation, and nuclide inclusion thresholds.

### 4.5 Statistical acceptance

Integral comparisons are statistical, and the metric has to measure Monte Carlo noise, not model uncertainty. Lessons from the first test run:

- **Do not use the ENDF dY as the yardstick.** It is mostly model-parameter spread. Comparing against it gave z_rms ≈ 0.16, a test too loose to detect real errors.
- **Use the counting noise of the actual event numbers.** Poisson-based z-scores per nuclide and per mass/charge bin gave z_rms ≈ 1.0 on independent yields, the expected value for statistically equivalent codes.
- **Treat correlated quantities as correlated.** Cumulative yields along a chain, covariance matrices and normalised distributions need metrics that account for correlation: covariance-aware χ², or ensembles of runs with different seeds.
- **Expect noise that is common to a whole energy step.** One 18.5 MeV point showed z_rms 1.43 and a 6.7σ nuclide. The suspected cause is noise in the multi-chance pre-pass that shifts all yields at that energy together. Acceptance criteria must measure this component (seed ensembles) rather than treat it as independent.
- **Control false alarms.** Thresholds are set in advance and corrected for the number of comparisons, so a suite of thousands of tests does not fail by chance or pass by being too loose.
- **Show the tests have teeth.** Deliberately inject small faults into the C++ build (a shifted parameter, a wrong rounding mode, a dropped decay branch) and confirm the suite detects each one. A suite that cannot catch a planted defect proves nothing.

## 5. Definition of done

The C++ implementation counts as a correct recreation of GEF when:

1. T0 data tests are exact for every table.
2. T1 function tests pass at their stated precision bounds over the full input domain used by GEF.
3. T2 sampler tests pass for every distribution and physics stage.
4. T4 integral tests pass for every cell of the coverage matrix in §4.4.
5. T5 regeneration of both reference libraries agrees statistically with `validation/reference/` across all tapes and energies, with no systematic trend.
6. The mutation checks in §4.5 are caught by the suite.
7. Every intentional difference from the BASIC behaviour is documented, switchable and measured.

T3 seeded trajectory equivalence, if achieved, adds the strongest evidence on top.

## 6. Guiding principles

- **The BASIC binary is the specification.** When documentation, physics intuition and the reference binary disagree, the binary decides what "correct" means for this project.
- **Prove, don't assume.** No component is "ported" until a differential test has compared it with the original.
- **Reproducibility is mandatory.** Every comparison records inputs, seeds, binary hashes and tolerances, and can be rerun by someone else.
- **Readable over clever.** The C++ code should be the version of GEF a physicist can read, test and extend. The original's structure is not a template to copy.
- **Measure performance, never at the expense of fidelity.** Speed-ups are welcome and measured against the ~1 h 46 min per nucleus baseline. They are accepted only when the test suite still passes.
