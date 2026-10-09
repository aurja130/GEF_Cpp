# GEF in C++: Current Project State

**As of:** 2026-10-09
**Phase:** M0–M3 complete. Next: M4 (static data, parameters and analyzer registry), which has no plan yet. No GEF physics has been ported yet; the FreeBASIC runtime layer it will run on is done and proven.

**Decision 2026-10-08 — exact reproduction first** (vision §4.2 and §5, strategy §2.9):
- **Phase 1 (M3–M16):** the C++ port must reproduce the BASIC arithmetic exactly. A seeded C++ run in exact mode must write the same output bytes as the seeded BASIC reference binary (T3).
- **Phase 2 (M17 onward):** optimisation, parallel mode and quirk fixes are judged against the exact C++ code, not against BASIC.
- **Statistical verdicts** are needed only in phase 2 and for the T5 library check.

## 1. Summary

| Area | State |
|---|---|
| Vision | Written: `Planning/GEF_CPP_VISION.md` |
| Implementation strategy | Written: `Planning/IMPLEMENTATION_STRATEGY.md`, 19 milestones (M0–M18) |
| Milestone plan files (`Planning/MILESTONE_<n>_PLAN.md`) | M0–M3 complete; M4–M18 not written |
| C++ implementation (`Cpp_implementation/`) | `gef_fbrt` (namespace `gef::fb`): the FreeBASIC runtime emulation of M3 (conversions, maths, random numbers, `Str`/`Print`/`Print Using`/`Format`, arrays, `DATA`, `Val`/`Input #`), bit-exact against FreeBASIC drivers. `gef` CLI (`--version`). Catch2 tests; five CMake presets. See §3.6 |
| Python tooling (`tools/`) | Toolchain check and fbc pin, validation-data manifests, BASIC-source tools (`emit_c`, `fbline`, `fbdef`) |
| Local CI | `scripts/ci.sh` (full) and `scripts/ci.sh --quick` |
| Reference harness (`harness/`) | Complete (M1). Reference binary `ref-1` (seed patch only), proven byte-identical to `gef_reference` for captured seeds; per-event reseed mode; Rnd draw logs; probes T0/P1/P2/P3; function drivers; clean-run runner; immutable reference store. See §3.4 |
| Comparison toolkit (`compare/`) | Complete (M2). Lossless parsers for every output file; exact field-level comparison (the phase-1 acceptance tool); calibrated statistical verdicts, valid for Cf-252 and not for Rn-215 with 20 BASIC runs (re-validated in M17). See §3.5 |
| Reference store | 82 entries: 18 M1 entries (gate runs, the `ref-1` binary, the golden random stream), 60 M2 ensemble runs, 3 calibrations, and the M3 stream `m3-rnd-seeds-1e6`; about 12 GB, gitignored, manifests committed. Small M3 driver goldens are committed under `Cpp_implementation/tests/golden/` |
| Quirk register | `Planning/QUIRKS.md`: 31 quirks (Q-001–Q-031) and 4 build notes (B-001–B-004) |
| Coverage matrix | `Planning/COVERAGE_MATRIX.md`: 114 rows × T0–T5; 2 cells covered (M3: FreeBASIC numeric semantics at T1, `FbMtRng` at T2); T4 cells owned by M17 after the exact-first decision; one cell deferred (approved 2026-10-07) |
| Coding standards | `Planning/CODING_STANDARDS.md` |
| Code maps | `Planning/code_maps/`: the six planning-session reports, with a README listing corrected claims |
| Version control | `.omp/` and `validation/` (including `validation/reference_store/`) are gitignored; manifests of stored data are committed under `manifests/` |

## 2. Repository inventory

### 2.1 BASIC reference: `Reference/GEF_code` (submodule)
- Pinned at `ba9f0aa`. `git describe` reports `2023-V3.2-12-gba9f0aa`, but the source declares `C_GEF_Version = "2025/1.2"` (`GEF.bas:3`). The tag name is stale; the code is 2025/1.2.
- Licensed GPL-3.0-or-later (`Reference/GEF_code/LICENSE`, `README.md` "Licence and copyright"; copyright 2009–2025 Karl-Heinz Schmidt and Beatriz Jurado). This repository is a derivative work and is licensed GPL-3.0-or-later as well (`LICENSE.txt`, relicensed from MIT on 2026-10-07).
- Source: `source/` holds about 88k lines in 40 files (38 `.bas`/`.bi`/`.mac` plus 2 `.dat`).
  - `GEF.bas` has 18,176 lines: module-level main program at 1–15670, functions at 15691–18176.
  - About 45k lines are `DATA` tables.
- Prebuilt binaries: `binaries/GEF64` (SHA-256 prefix `e4228385d276efad`), `GEF32`, `GEF.exe`.
- Batch inputs: `wrkdir/in/` holds about 200 example sequence files. These are useful later for parser tests.

### 2.2 `Reference/GEF_data` (submodule)
- Pinned at `9232761`.
- Contains only NEA helper scripts, including `.nea/endf_format_check.py`, which M13 will use. No nuclear data.

### 2.3 Validation assets: `validation/` (gitignored, about 1.1 GB, not under version control)

| Item | Content |
|---|---|
| `reference/gefy_nfy`, `reference/gefy_sfy` | Sequence files that produced the reference library |
| `reference/gefy_nfy_ENDF/` | 143 neutron-induced GEFY ENDF-6 tapes, Z = 86–98, 59 energies from thermal to 30 MeV, `Fenhance = 10` |
| `reference/gefy_sfy_ENDF/` | 239 spontaneous-fission tapes, Z = 89–106, `Fenhance = 100` |
| `test_run/gef_reference` | Linux x86-64 BASIC binary built 2026-09-15 with debug info (SHA-256 prefix `1942e588a32e29a1`). It is a different build from `binaries/GEF64` |
| `test_run/` outputs | One BASIC run of Rn-215 (n,f), 59 energies: `out/`, `dmp/` (59 energy folders × 27 analyzers), `tmp/` (`ptb`, `_Single.mvd`, `par`, `CUMU`), `ENDF/GEFY_86_214_n.dat`, `run.log` |

**Checksums:** `manifests/validation_reference.sha256` (384 files: 382 tapes and 2 sequence files) and `manifests/validation_test_run.sha256` (1719 files: binary, `run.log`, ENDF tape, `out/`, `dmp/`, `tmp/`). Verify with `python3 -m tools.toolchain.manifest_validation verify`, or with GNU `sha256sum -c --strict` from inside `validation/` (that cannot detect extra files). `test_run/in/`, `file.in` and the empty `BestFit/`, `External/`, `GRAF/` are not covered, as the M0 plan specified.

**Caveats about `test_run/`** (also recorded in the manifest header):
- It is **not** a clean working directory.
- `ctl/` still holds `thread.ctl`, `done.ctl` and `sync.ctl`.
- The ENDF file contains two concatenated tapes:
  - Lines 1–857 come from an earlier thermal-only run.
  - Line 858 onward is the real 59-energy tape.
- Reruns in this directory would append to the existing outputs.

### 2.4 Toolchain on this workstation

Recorded in `manifests/toolchain.txt`; checked by `python3 -m tools.toolchain.check_toolchain` (about 1.5 s).

| Tool | Version |
|---|---|
| GCC (primary), Clang | 16.2.1, 22.1.8 |
| CMake, Ninja | 4.3.0, 1.13.2 |
| clang-tidy, clang-format, clangd | 22.1.8 |
| Python, ruff, basedpyright, pytest | 3.14.7, 0.16.6, 1.39.10, 9.1.1 (NumPy 2.4.6, SciPy 1.17.1) |
| Universal Ctags | 6.2.1 |
| glibc; GNU as/ld | 2.43; 2.46.1 |
| FreeBASIC fbc | 1.10.1 at `~/Downloads/FreeBASIC-1.10.1-linux-x86_64` (not on PATH; override with `GEF_FBC`). Tarball SHA-256 `844aa9e9…08bc` verified. Prints harmless `libtinfo`/`ospeed` loader warnings, which the tools filter |
| Catch2 | v3.16.0, fetched by CMake `FetchContent`, pinned by archive SHA-256 |
| CPU | 20 cores |

**fbc backend (captured with `fbc -v`):** `gcc -m64 -march=x86-64 -S -nostdlib -nostdinc -Wall -Wno-unused -Wno-main -Werror-implicit-function-declaration -O0 -fno-strict-aliasing -frounding-math -fno-math-errno -fwrapv -fno-exceptions -fno-asynchronous-unwind-tables -funwind-tables -Wno-format -masm=intel`, then GNU `as` and `ld` with `-lfb -ltinfo -lm -ldl -lpthread -lgcc -lgcc_eh -lc`.

## 3. What exists after M0–M3

### 3.1 C++ build

- Top-level `CMakeLists.txt` (C++23 ISO mode, compile commands exported) and `CMakePresets.json`:

  | Preset | Compiler | Build |
  |---|---|---|
  | `dev-gcc` | GCC | Debug |
  | `dev-clang` | Clang | Debug (its `compile_commands.json` feeds clangd and clang-tidy) |
  | `asan-ubsan` | GCC | ASan + UBSan, `-fno-sanitize-recover=all` |
  | `tsan` | GCC | ThreadSanitizer, `TSAN_OPTIONS=halt_on_error=1` in the test preset (added 2026-10-08, earlier than the M0 plan's "M17") |
  | `release-exact` | GCC | Release (`-O3`) |

- `Cpp_implementation/cmake/GefCompilerPolicy.cmake`: interface targets `gef_exact_fp` (exact-mode FP flags `-march=x86-64 -ffp-contract=off -fno-fast-math -frounding-math -fno-math-errno -fexcess-precision=standard`, linked PUBLIC) and `gef_warnings` (`-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wdouble-promotion -Wshadow -Werror`, our targets only). New targets call `gef_apply_policy(<target>)`.
- `gef_fbrt` (`gef::fb`): `fp_environment` checks `FLT_EVAL_METHOD == 0`, IEEE 754 types with NaN semantics and no fast-math, round-to-nearest at start-up, and no FMA contraction.
- `gef --version`: project version, git revision (refreshed on every build), compiler, preset, build type, FP flags, per-check fp_environment verdict; exits 1 on FAIL.
- Tests: `Cpp_implementation/tests/` (Catch2 tags become CTest labels, e.g. `ctest --preset dev-gcc -L fbrt`). Test presets use `noTestsAction=error`, so a label filter that matches nothing fails instead of passing silently.
- `.clang-format`, `.clang-tidy` (with documented exclusions; tests relax one check for Catch2 macros), `.editorconfig`. clangd uses `build/dev-clang` (`.omp/lsp.json`).

### 3.2 Python tooling (run from the repository root)

| Command | Purpose |
|---|---|
| `python3 -m tools.toolchain.check_toolchain [--write-manifest]` | Check tool versions and the fbc pin; compare against or rewrite `manifests/toolchain.txt` |
| `python3 -m tools.toolchain.manifest_validation write\|verify` | Write or verify the validation-data manifests. Exit 77 when `validation/` is absent |
| `python3 -m tools.fbsrc.emit_c [--patch-dir DIR] [--force]` | Translate the BASIC source to C in `build/fbsrc/<rev>[-p<hash>]/` (`fbc -gen gcc -R -g -c GEF.bas`, `SOURCE_DATE_EPOCH` = submodule commit time, so output is deterministic). Patch dirs hold unified diffs applied with `patch -p1` |
| `python3 -m tools.fbsrc.fbline <file>:<line>[-<line>] [--context N] [--raw] [--symbols]` | BASIC line(s) and the C generated from them; works for included files |
| `python3 -m tools.fbsrc.fbdef <name> [--refs]` | Case-insensitive definition lookup (ctags index corrected for `Static`, `ReDim`, `#Define`) and whole-word references outside comments |

Configuration: `pyproject.toml` (ruff, basedpyright strict over `tools/` and `harness/`, pytest markers `fbc`, `slow`, `gdb`, `validation`). Details: `tools/fbsrc/README.md`, `Planning/CODING_STANDARDS.md` §3.

### 3.3 Local CI

`scripts/ci.sh` runs the toolchain check; configure, build and test for `dev-gcc`, `dev-clang`, `asan-ubsan`, `tsan`, `release-exact` (the sanitizer test presets exclude the `slow` label, i.e. the exhaustive `Single` checks); clang-tidy; clang-format; ruff lint and format; basedpyright; pytest; validation-manifest and reference-store verification (both skipped with a notice without `validation/`). One summary line per step, logs in `build/ci/`, non-zero exit on any failure. `--quick` runs the `dev-gcc` pipeline without `[slow]` tests and the Python steps. The long M1 gates are run on demand with `harness/gates.sh <g1|g23|g4|all>`.

**ThreadSanitizer pass (2026-10-08).** TSan works with GCC 16 and Clang 22 here: a racy probe is reported, a clean one is not. A TSan build of everything compiled so far (`gef_fbrt`, `gef`, the Catch2 tests), with GCC through the `tsan` preset and once with Clang, builds without warnings and passes all 7 tests and `gef --version` with no report; the binaries carry TSan instrumentation. This is an infrastructure check more than a finding: no C++ code creates threads yet, and the BASIC program (`GEF.c`) creates none either. The Python thread and process pools (`manifest_validation`, `check_toolchain`, `harness.store`, `compare.ensemble/extract/calibrate/gate_g1`) are outside TSan's reach. Each maps a pure function over independent items and collects results in the caller, so they share no mutable state. TSan becomes meaningful with parallel mode (M17).

### 3.4 Reference harness (M1, `harness/`, see `harness/README.md`)

- **Reference binary `ref-1`:** the `seed` patch set, i.e. the original source with `Randomize,3` replaced by `Randomize <GEF_SEED>,3`. With the seeds captured under gdb from `gef_reference` runs (1776849192 for the Rn-215 input, 1776917293 for Cf-252), it reproduced every output file byte for byte, with only timestamps masked. Provenance: `manifests/reference_binary.json`.
- **Patches**, in the canonical order `seed → scope → reseed → rndlog → probes`, none of which changes `GEF.bas` line numbering:
  - `scope` tracks the energy step, pass and event, and parses the `GEF_TRACE_*` selectors;
  - `reseed` is the per-event reseed mode (`GEF_RESEED=1`, spec in `harness/RESEED_SPEC.md`, Python reference `harness/reseed.py`);
  - `rndlog` logs every traced `Rnd` draw (`-d GEF_RNDLOG`);
  - `probes` writes hex dumps of state at T0, P1, P2 and P3 (`-d GEF_PROBES`, variable lists in `harness/PROBES.md`).

  All are proven neutral: same seed gives byte-identical output.
- **Tools:**
  - `harness.build`: reproducible patched builds;
  - `harness.run`: clean-run runner;
  - `harness.compare_runs`: byte comparison with the 12 masks in `harness/masks.toml`;
  - `harness.capture_seed`;
  - `harness.store`: immutable store in `validation/reference_store/`, manifests in `manifests/reference_store/`;
  - `harness.driver`: FreeBASIC function drivers;
  - `harness.rndlog` and `harness.probes`: readers;
  - `harness.fbmt`: Python reference of fbc's `Randomize s,3` + `Rnd`.
- **Stored references:** the G1–G5 gate runs and the golden random stream `m1-golden-rnd-stream-42` (seed 42, 10⁶ values), which M3's `FbMtRng` must reproduce.

### 3.5 Comparison toolkit (M2, `compare/`, see `compare/README.md`)

- **Parsers** for ENDF-6, `dmp`, `mvd`, `par` (byte round-trip on every stored file), `out/`/`ptb` (100 % numeric coverage), probe dumps and any text file. Keys depend only on file content.
- **`compare.exact RUN_A RUN_B`:** field-level comparison with ULP distances. It is the T3 acceptance tool of phase 1. Two same-seed BASIC runs are identical over 4.6 M fields.
- **Statistical verdict** (`compare.calibrate`, `compare.verdict`, `compare.gates`, method in `compare/STATISTICS.md`): per-family global and local tests against a seeded ensemble, with Holm's correction at α = 0.01.
  - It meets the false-alarm target for Cf-252 and detects planted faults above the minimum detectable effect.
  - For Rn-215 it fails the target with K = 20 BASIC runs: 5 of 22 suites on the short input, 18 of 20 on the full 59-energy input. Rare pre-pass regimes, sparse single-cell bursts and table-row churn make correct runs exceed the 4·10⁻⁸ per-family threshold.
  - Re-validation with large exact-C++ ensembles is part of M17.
- **Library check:** the library tape `GEFY_86_214_n.dat` passes against the full 59-energy calibration.

### 3.6 FreeBASIC runtime emulation (M3, `Cpp_implementation/src/fbrt/`, see `MILESTONE_3_PLAN.md`)

Every piece is transcribed from the fbc 1.10.1 runtime sources or GEF's generated C, and proven against FreeBASIC driver programs (`harness/drivers/`, goldens via `harness.golden`) in `dev-gcc`, `dev-clang` and `release-exact` (`-O3`):
- **fbc arithmetic rules** (`FBC_ARITHMETIC.md`, R1–R10): literal typing, per-operation promotion, reassociation and literal folding of `*`/`+` chains, dropped parentheses, distribution of a literal multiplier.
- **Conversions and integer arithmetic** (`convert.hpp`): `f2i/f2l/f2ul/d2i/d2l/d2ul`, `fix`, `sgn`, wrapping `add/sub/mul/neg/abs`, `idiv/imod`; exhaustive over all 2³² `Single` inputs.
- **Maths** (`gef_math.hpp`): GEF's `Min`, `Max`, `Erf`, `Erfc`, `Tanh`, `Coth`, `Log10`, `Floor`, `Ceil`, `Round`, `Modulo`; libm through the `std::` overloads. Exhaustive over `Single` for the one-argument functions.
- **Random numbers** (`rng.hpp`, `reseed.hpp`): `FbMtRng` and the per-event reseed derivation.
- **Text** (`text.hpp`, `print_using.cpp`, `format.hpp`): `Str`, `Print #` with zones and `Tab`, `Print Using` (all 39 GEF templates, inventory `TEMPLATES.md`), `Format`.
- **Arrays** (`array.hpp`, `extend.hpp`): `fb::Array<T, rank>` with FreeBASIC bounds and `ReDim Preserve` semantics, bounds-checked access; GEF's `Extend_*`.
- **Input** (`data_reader.hpp`, `input.hpp`): `DATA`/`Read`/`Restore`, `Val`/`ValLng`/`ValInt`, `Input #`.

Decisions taken in M3: NaN results compare equal regardless of sign and payload (B-001); array access is always bounds-checked and throws.

## 4. Established findings

### 4.1 The test run against the reference library (Rn-215, tape 2 vs `reference/gefy_nfy_ENDF/GEFY_86_214_n.dat`)

**Overall:** the BASIC binary reproduces the reference library statistically, not bit for bit. That is expected, because the BASIC RNG is seeded from the clock.

| Check | Result |
|---|---|
| ΣIY | 2.0000 at all 59 energies |
| Independent yields, Poisson z (10⁶ events) | z_rms mean 0.99 (range 0.88–1.43); max \|z\| median 3.1 over ~440 nuclides |
| Mass yields, z_rms | 1.00 |
| dY ratio, test/reference | Median 1.00 per energy (range 0.76–1.27) |
| Nuclides present in only one file | Yield ≤ 2.1e-5 |
| Outlier | 18.5 MeV: z_rms 1.43; Mo-105 at z = 6.7 |

**Caveats on these numbers:**
- The 18.5 MeV outlier comes from the multi-chance pre-pass, which is shared by all passes of an energy step. At this energy the pre-pass sees only 15–17 fissions, so the second-chance share is k/15 or k/17: 1 of 17 in `test_run`, 0 of 15 in the M1 `ref-1` run (100 % first chance). The `ref-1` run deviates from the library there at independent z_rms 2.47 (M1 plan, G4 exception). This is established for these two runs; the full spread is for M2's null calibration.
- Comparing against the ENDF dY itself is useless for code validation: it gives z_rms ≈ 0.16, because dY is mostly model-parameter spread.
- Cumulative mass-chain z_rms is about 1.8. That reflects correlation along the chain, not a discrepancy.

### 4.2 Facts about the BASIC code

| Fact | How confirmed |
|---|---|
| `Randomize ,3` (`GEF.bas:1553`) seeds the Mersenne Twister from the clock; runs are not reproducible | read |
| Nominal pass uses `Fenhance·10⁵` events. Perturbed passes: `Int(sqrt(100·Fenhance))` passes (31 for `Fenhance = 10`) of 32,258 events each | read; matches `run.log` |
| 46 parameters are perturbed (`GEF.bas:5104–5162`; a 47th `PGauss` line is commented out) | counted |
| `GEFSUB`/`GEFRESULTS` (`GEF.bas:7514–7919`) is dead code inside a nested comment | read |
| Float → integer conversion rounds half to even | fbc 1.10.1 test program |
| ENDF n-induced runs use N + 3 energy steps; the first two and the last write no MT454 data | read; matches `run.log` |
| fbc reassociates `*` and `+` chains, drops their parentheses, and applies numeric literals last (`a * 0.03 * b * c` → `((a*b)*c)*0.03`, `s * (t * u)` → `(s*t)*u`); port arithmetic from the generated C | fbc C and a run (`QUIRKS.md` B-004, `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md`) |
| `MyParameters.dat` is never applied in any mode (not only batch): `MyparRead` runs once at `GEF.bas:1017`, before its flag can be set | fbc C (`QUIRKS.md` Q-018) |
| All quirks and their evidence | `Planning/QUIRKS.md` (13 confirmed in output, 13 confirmed by fbc C, 4 read only; Q-031 added in M3.6b) |

### 4.3 Code maps

The six planning-session reports are saved in `Planning/code_maps/` (M0.1). Their README lists three claims corrected since (46 perturbed parameters; `GEFSUB` dead; `ctl/` holds all three control files).

## 5. Open risks and items

1. **Optimisation level vs fbc's `-O0`** (`QUIRKS.md` B-001): measured per function by the M3 T1 tests in `release-exact`. So far: no non-NaN difference; NaN sign/payload differences are accepted by user decision (2026-10-08). M5 extends the check to the physics functions.
2. **fbc expression reordering** (B-004): characterised in M3.2 and M3.6a (`FBC_ARITHMETIC.md`, rules R1–R10, verified by driver runs in all presets including `-O3`). The remaining risk is a GEF expression shape the probes did not cover; the porting rule (follow the generated C) and the M5 T1 tests cover it.
3. **`-fwrapv` in the fbc backend** (B-002): resolved for the runtime layer by the `fb::add/sub/mul/neg/abs` helpers (M3.3); ported code must use them where `Integer`/`Long` arithmetic can overflow.
4. **Statistical calibration of Rn-215-like inputs** (M2): 20 BASIC runs cannot calibrate the extreme per-family tails a full-output comparison needs. Rare pre-pass regimes (one run in 20 at 18.5 MeV gets a second-chance split), sparse bursts and row churn exceed the model. Irrelevant for phase 1 (exact equality). In phase 2, large exact-C++ ensembles are needed; detection power for single-nuclide shifts also needs several candidate runs.
5. **Deferred coverage cell:** the `Static Ntimes` negative-TKE guard at T4 cannot be checked statistically. Deferral approved by the user on 2026-10-07, to be revisited later (`COVERAGE_MATRIX.md`). The guard is still ported faithfully in M10 and checked at T2 (M10) and T3 (M15).
6. **Unregistered quirk candidates** seen in the code maps but not yet verified, to be registered by their owning milestones: `d_ZISOPOST` reader checks `_ZISOPOST` bounds (`Spectra.bas:1779–1787`); two-system covariance issues (`GEF.bas:11651–11652, 11905`); 1st-isomer β⁻2n line prints `Radd` instead of `2*Radd` (`Branchings.bas:578`); `TKEmin` exponents 0.33333/0.3333 (`GEF.bas:8254`); `DEFOtab(A_post - Z_sci, Z_sci)` (`GEF.bas:9313/9433`); `EexcA2d` registered as `Eexc2dlight` (`Spectra.bas:512–514`); `#If EgammaA` missing its `B_` prefix (`GEF.bas:9418`).
7. **`FetchContent` needs network** on the first configure of each build tree. Offline fallback: `catch2-devel` via dnf and `find_package`.

## 6. Next steps

1. Implement M4 per `MILESTONE_4_PLAN.md` (written 2026-10-09). User decisions: `DATA` items extracted from the emitted C, generated C++ committed, all nuclide-data variants ported and selectable (JEFF-3.3 certified end to end, the others at T0, the three legacy files through a compatibility patch), `Fitpar.dat` ported in M4, per-table fingerprints committed with full dumps in the store. M4 starts with the variant builds and their T0 probes (M4.1).
2. Per the exact-first decision, later milestone plans gate on bit-exact equality with BASIC (T0–T3) and use `compare.exact` and the per-event reseed mode to triage divergences. The Clang Debug test preset skips `[slow]` tests (user, 2026-10-08); work on this machine is limited to 10 cores (`taskset -c 0-9`, `-j 10`) while it is shared.
