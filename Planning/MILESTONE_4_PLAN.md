# Milestone 4: Static Data, Parameters and Analyzer Registry

**Status:** not started
**Strategy reference:** `IMPLEMENTATION_STRATEGY.md` §2.4, §2.5, §2.9 and §3, M4
**Depends on:** M1 (T0 probe, drivers, patch sets, reference store), M2 (exact comparison), M3 (`fb::DataReader`, `fb::Array`, conversions, `fb::InputFile`)
**Unblocks:** M5 (physics functions read the mass, shell and deformation tables), M6 (target and isomer lookups), M7 and later (nominal parameters, perturbation order), M11 (branchings), M13 (analyzer registry, element names)

## 1. Goal

Every table, constant and parameter that GEF loads before it computes anything exists in C++ with exactly the values the BASIC program holds: the same bits, the same array bounds, the same loader quirks. The data layer is then frozen and can be verified exactly. The first GEF code ported line by line lives here: the table loaders, `Parameters.bas`, `FitparRead.bas`, the analyzer registry set-up and the table lookup functions.

## 2. Decisions taken in this plan

| ID | Topic | Decision | Reason |
|---|---|---|---|
| D1 | Source of the `DATA` items | Extract the items from the C that fbc emits (`GEF.c`), not from the BASIC text. A cross-check maps every extracted block to its BASIC `DATA` statements (same number of items per label). Strategy §2.5 is amended accordingly | User decision (2026-10-09). M3.8 showed that fbc rewrites unquoted numeric `DATA` items at compile time (15 significant digits, `1.E-3` → `0.001`, `&H1F` → `31`); the emitted tables are what the binary reads |
| D2 | Form of the data in the repository | Generated C++ sources, committed, one per BASIC source file (about 2–4 MB in total). A pytest regenerates them from the emitted C and fails on any difference | User decision (2026-10-09). Builds need no FreeBASIC; changes are reviewable; drift is impossible |
| D3 | Nuclide-data variants | Port all of them, selectable at run time. `NucProp*`: JEFF-3.3 (default, the reference binary's choice), JEFF-3.1.1, NUBASE 2016, NUBASE 2020, and the three legacy files `NucPropx`, `NucPropmf`, `NucPropf`. Branchings: `DCLbranchingJEFF33` (default) and `DCLbranchingJEFF311`. The variant's `ISOSOURCE` string selects the compile-time `#If ISOSOURCE = …` branches of GEF (e.g. `GEF.bas:14228`), so the C++ chooses the same code paths at run time | User decision (2026-10-09): certify JEFF-3.3 end to end, keep the others available |
| D4 | Certification of the variants | JEFF-3.3 is certified at every tier (T0 here, T3 later). Every other variant is certified at T0 here, against a BASIC build in which a harness patch swaps the `#Include` at `GEF.bas:1052` (and `1284` for branchings); the patches do not shift `GEF.bas` line numbers. The legacy `NucPropx/mf/f` do not compile with GEF 2025/1.2 (no `ISOSOURCE`); a compatibility patch defines it in the variant file (by replacing a comment line), and they are marked "not a stock GEF 2025/1.2 configuration" | User decision (2026-10-09). Only these builds can show that the tables load identically |
| D5 | Certified combinations | JEFF-3.3 + branchings JEFF-3.3 (default); JEFF-3.1.1 + JEFF-3.1.1; NUBASE 2016 + JEFF-3.3; NUBASE 2020 + JEFF-3.3 (the pairs GEF's comments recommend, `GEF.bas:1036-1048`); each legacy file + JEFF-3.3. Other combinations are selectable but reported as uncertified | GEF's own guidance on consistent pairs; keeps the build count bounded (8 builds) |
| D6 | `Fitpar.dat` | `FitparRead.bas` is ported in M4 (with `fb::InputFile`), tested with and without a `Fitpar.dat` in the working directory | User decision (2026-10-09). It completes the nominal-parameter layer |
| D7 | Test data | Per-table fingerprints (hash of the dumped values, bounds and count) are committed as goldens; the full probe dumps stay in the reference store for diagnosis. Tests that need the store skip without it | User decision (2026-10-09), same rule as M3 D1 |
| D8 | Layout | `src/data/`: generated tables (`src/data/generated/`), loaders, lookups, the `TableSet` holding all loaded tables. `src/params/`: `Parameters` (one named `float`/`int64` member per BASIC variable, set by a line-by-line port of `Parameters.bas`), a descriptor table (name, member, perturbation order, width) on top, `Var_*` widths, `FitparRead` | Strategy §2.8; named members keep ported physics readable, the descriptor table serves perturbation and dumps |
| D9 | Ownership | Tables, `IMATmax` and the mutable `Isotab` fields belong to `ProcessState`; the nominal parameters that `Parameters.bas` reloads per system (`GEF.bas:3320`) belong to `SystemState` | Strategy §2.4 |
| D10 | Fidelity | Loaders are ported line by line from their generated C, keeping their quirks (e.g. BranchData isomer rows overwriting `R_alpha`, loading stopping at Ra-234, Q-004/Q-027 `UBound` quirks). Newly found quirks are registered | Strategy §2.1 |

## 3. Facts established while planning (2026-10-09)

| Item | Fact |
|---|---|
| `DATA` volume (default build) | 214,639 items in 197 linked blocks, 0.9 MB of item text (`GEF.c`) |
| Files with `DATA` | `DCLplotting.bas` (188 `DATA` statements, evaluation tables read on demand by `Plotting.bas`, 427 `Restore` sites), `DCLbranchingJEFF33/JEFF311.bas`, the `NucProp*` files, `ShellMO.bas`, `DEFO.bas`, `BEexp.bas`, `BEldmTF.bas`, `ElmtNames.bas`, `GEF.bas` (element names) |
| Variant selection | Commented `#Include` lines, not defines: `GEF.bas:1052` (NucProp), `GEF.bas:1284` (branchings, inside `#ifdef B_delayed`). Each `NucProp*` file defines `ISOSOURCE` and `N_MAT_MAX`; `ISOSOURCE` feeds `#If` branches in `GEF.bas:14228, 14289` |
| Variants that compile with GEF 2025/1.2 | JEFF-3.3, JEFF-3.1.1, NUBASE 2016, NUBASE 2020 (`fbc -gen gcc -r` with the include swapped). `NucPropx`, `NucPropmf`, `NucPropf` fail: `ISOSOURCE` undefined (`GEF.bas:14222`, `Branchings.bas:955`) |
| T0 probe (M1, `harness/PROBES.md`) | Already dumps table sizes, `BEldmTF`, `BEexp`, `DEFOtab`, `ShellMO`, `EVOD`, `CElement`, `ENfrvar_lim`, `MAT_for_ISO`, all `NucTab`/`Isotab` fields, `BranchData`/`INlast` (from a private copy of the loader), the analyzer registry and the 111 nominal parameters and initial `Var_*`. Final `Var_*` (after `GEF.bas:2580-2623`) are in P1. The `DCLplotting` evaluation tables are not dumped |
| `Fitpar.dat` | `FitparRead.bas` (29 lines) reads it with `Input #` if it exists (`GEF.bas:2555`); normally absent |

## 4. Work breakdown

Tasks in execution order. Mark each one done here when finished, and update `CURRENT_PROJECT_STATE.md`.

### M4.1 Variant builds and probes
- [x] Harness patches `nucprop-<variant>` (swap `GEF.bas:1052`), `branching-jeff311` (swap `GEF.bas:1284`) and `legacy-isosource` (defines `ISOSOURCE` in `NucPropx/mf/f`), with patch sets for the eight combinations of D5; none shifts `GEF.bas` lines. (Patches `nucprop-jeff311/nubase2016/nubase2020/x/mf/f` and `legacy-isosource`; patch sets `m4-jeff33`, `m4-jeff311`, `m4-nubase2016`, `m4-nubase2020`, `m4-legacy-x/mf/f`, each with `seed`, `scope`, `probes` and `datachain`; `harness.build` accepts them in a widened canonical order. **Deviation:** `DCLbranchingJEFF311.bas` does not compile with GEF 2025/1.2 (`ZISOPRE` defined twice, `AME2012` undeclared: an older, unmaintained version of the JEFF-3.3 branchings file, half its size), so no `branching-jeff311` patch exists and JEFF-3.1.1 is paired with the JEFF-3.3 branchings. Making the old file compile would change its code, not just add a definition, so it needs a user decision. That leaves seven combinations.)
- [x] Build each with the `probes` patch and store a T0 dump per combination in the reference store. (Input `harness/inputs/m4_t0.in`, Cf-252 sf with `Fenhance 1`, seed 12345; captures `m4-t0-<variant>` in the store. **Finding:** the stock `NucPropNUBASE2020.bas` stops GEF while loading (`<E> NucPropx: N_MAT_MAX too small!` 6,556 times, then `<E> Error in NucProp`, `GEF stopped.`), also without any probe patch; registered as `QUIRKS.md` Q-032. Its capture holds that output; there is no T0 for it.)
- [x] A new T0 section (or a driver) that dumps the `DCLplotting` evaluation tables by reading every block with `Read`, so they can be verified like the other tables. (Patch `datachain` (`-d GEF_DATACHAIN`): dumps every `DATA` item of the program in `Read` order, as hex, to `probes/datachain.txt`, which covers the `DCLplotting` tables and every other table. It runs at `GEF.bas:1011`, before the nuclide-data include, so even NUBASE 2020 gets a dump (capture `m4-datachain-nubase2020`, 227,698 items). Default build: 214,639 items, matching `GEF.c`. Proven neutral: same seed, same outputs and T0 as `seed-probes`.)
- Emitting `GEF.c` per combination moves to M4.2, where the generator needs it.

**Done when:** every combination builds, and a T0 dump of each is stored. (Met for six combinations; NUBASE 2020 stops before T0, see Q-032.)

### M4.2 Data extraction and generated C++
- [x] `tools/fbsrc/gen_gef_data.py`: parses the `FB_DATADESC` tables of an emitted `GEF.c`, follows the link chain from the first block, maps each block to its BASIC label (through the `fb_DataRestore` call sites and `#line` directives) and to its BASIC `DATA` statements, and checks that the item counts agree. (Emits the C of every combination through its `m4-*` patch set; decodes the C strings, finds the chain head (the one table no link points to), names tables by the `Restore` statements that target them (194 labels; 3 tables are never restored and are reached only through the chain). **Changed check:** instead of counting items per `DATA` statement, every item of every variant is compared with the `datachain` dump of the BASIC build itself, i.e. with what the compiled program's `Read` returns; this is stronger and needs no BASIC lexer.)
- [x] Generated C++ under `Cpp_implementation/src/data/generated/`, one file per BASIC source file and variant: the item texts as a single string with an offset table (`std::string_view` items for `fb::DataReader`), plus named label indices. Licence headers: ours and the GEF line. (Layout chosen by content instead of by file: the 212 blocks common to all variants once (184k items), the variant-specific blocks per variant (4–7 blocks), and a chain description per variant; string blobs split at 32 KB because clang rejects longer literals. 3.0 MB in total; `gef_data` compiles in 1.6 s. `gef::data::ProgramData` (`program_data.hpp`) assembles a variant's item list and label map.)
- [x] Pytest: regenerating from the emitted C of every combination reproduces the committed files byte for byte. (`python3 -m tools.fbsrc.gen_gef_data --check`, `tools/fbsrc/tests/test_gen_gef_data.py`. C++: `program_data_test.cpp` compares item count and fingerprint per variant with the store-derived golden `m4-datachain` (recorded in `derived.json`, checked by `harness.golden check` against the store manifests), and, with the store present, every item with the BASIC dump.)

**Done when:** all variants are generated, committed and regenerate identically.

### M4.3 Table loaders
- [x] Port, line by line from the generated C: the NucTab/`MAT_for_ISO`/Isotab loader (including the spin-sorted states and `R_Lim` windows), BranchData/EndA/INlast (`Branchings.bas` loader), `BEldmTF`, `BEexp`, `DEFOtab`, `ShellMO`, `EVOD`, `CElement`, `ENfrvar_lim` (`Spectra.bas:798`). Converter and loader assertions on counts and index ranges. (`src/data/nuclide_tables.cpp` (each variant's own loader: the files differ in record layout, in an active or commented `I_Z = 111` exit, and in a bounded or unbounded `N_ISO_MAT`), `mass_tables.cpp`, `branchings.cpp`, `tables.cpp`. Loader messages that do not stop go to `TableSet::console` with BASIC's `Print` formatting; the NUBASE 2020 stop throws `GefStopped` with the same 6,558 lines (Q-032). Quirks reproduced and annotated: Q-015, Q-017, Q-032, new Q-033 and Q-034. `N_ISO_MAT`'s unchecked loop never reads past `NucTab` with the shipped tables; the bounds-checked access would throw.)
- [x] `TableSet` (in `ProcessState`), loaded for a chosen variant combination. (`gef::data::load_tables(ProgramData const&)`; `ProcessState` itself comes with M6.)
- [x] Tests: every table's fingerprint equals the T0 dump of its combination (committed goldens), for all eight combinations. (`nuclide_tables_test.cpp`, `tables_test.cpp`, with the C++ probe writer `tests/support/probe_dump.hpp` and the store-derived goldens `m4-t0-<variant>` from `harness.probe_fingerprints`: six certified combinations (seven exist, NUBASE 2020 stops before T0); all pass in `dev-gcc`, `dev-clang`, `release-exact`. The legacy files' probe writes `N_MAT_MAX` under its `#DEFINE` value (e.g. `3897`), which the tests map.)

**Done when:** all T0 table fingerprints match for every certified combination.

### M4.4 Parameters
- [ ] `Parameters` and `Parameters.bas` ported line by line (Double literal → Single narrowing, duplicate assignments, last one wins); the descriptor table; the 46 perturbed parameters in draw order (`GEF.bas:5104-5162`); initial `Var_*` (`GEF.bas:1348-1394`) and final `Var_*` (`GEF.bas:2580-2623`).
- [ ] `ParameterManipulation.mac` and `FitparRead.bas` (`Fitpar.dat`); `MyparRead` is reproduced as never applied (Q-018).
- [ ] Tests: the 111 nominal parameters and initial `Var_*` against T0; final `Var_*` against P1 of the stored M1 runs; `Fitpar.dat` present and absent against a driver.

**Done when:** every parameter value is bit-exact.

### M4.5 Analyzer registry
- [ ] The `Anl_Par` registry set-up ported line by line, with its naming quirks.
- [ ] Tests: every field of entries 0…`N_Anl` against T0.

### M4.6 Lookup functions
- [ ] `I_MAT_ENDF` with explicit `IMATmax` state, `N_ISO_MAT`, `ISO_for_MAT`, `NStates_for_ZA`, `Ibranch_for_ZAI`.
- [ ] Tests (T1): a driver evaluates each over the full (Z, A) grid (and isomer index where relevant) in a fresh `ctl/`, for the default combination and for each other certified combination; the C++ reproduces every result and the evolution of `IMATmax`.

### M4.7 CI, documentation and close-out
- [ ] Tests tagged `[T0]`/`[T1]` and `[data]`/`[params]`; slow ones `[slow]`.
- [ ] `QUIRKS.md` (new loader quirks), `COVERAGE_MATRIX.md` (the cells M4 closes), `IMPLEMENTATION_STRATEGY.md` (§2.5 amended per D1, M4 status), `CODING_STANDARDS.md` (generated data, variant selection), `CURRENT_PROJECT_STATE.md`. Mark this plan complete with completion notes.

## 5. Exit gate (all must hold)

| Gate | Requirement |
|---|---|
| G1 Generated data | Every committed generated file regenerates byte for byte from the emitted C of its combination; every block's item count matches its BASIC `DATA` statements |
| G2 Tables | For each of the eight certified combinations, every table, bound and `Isotab`/`NucTab`/`BranchData` field equals its T0 dump bit for bit (fingerprints committed, full dumps in the store); the `DCLplotting` tables likewise |
| G3 Parameters | The 111 nominal parameters, initial and final `Var_*` and the perturbation order are bit-exact (T0, P1); `Fitpar.dat` present and absent reproduce the driver |
| G4 Registry | Every `Anl_Par` field of every entry equals T0 |
| G5 Lookups | Every lookup function and the `IMATmax` evolution reproduce the driver over the full grids, for every certified combination |
| G6 CI | `scripts/ci.sh` passes in all presets; clang-tidy, clang-format, ruff and basedpyright clean; goldens current |

## 6. Out of scope (later milestones)

- Physics functions that read the tables (M5).
- The plotting and χ² code that reads the `DCLplotting` tables (M13, M16); M4 only provides and verifies the data.
- The use of `BranchData` in decay chains (M11); M4 loads it.
- Input parsing (M6). `Fitpar.dat` is the only file M4 reads.

## 7. Risks and open questions

| Item | Handling |
|---|---|
| fbc's label numbering differs between variant builds | The generator maps blocks by BASIC labels and `DATA` statement locations, not by `label$N` |
| A loader quirk depends on the variant (array sizes, `N_MAT_MAX`) | Each variant has its own T0 dump; loaders take sizes from the variant, not from constants |
| Generated sources slow the build | One file per source file; if compile time hurts, switch to a single string blob per file (already the planned form) or a precompiled object |
| `ISOSOURCE` branches affect code outside M4 | Recorded now; the owning milestones (M11, M13) port them with a run-time variant check |
| Legacy variants behave unexpectedly even after the compatibility patch | They are certified at T0 only and labelled non-stock; anything beyond T0 is out of scope |

## 8. Completion notes

*(Filled in when M4 closes.)*
