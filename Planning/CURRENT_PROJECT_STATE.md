# GEF in C++: Current Project State

**As of:** 2026-10-06
**Phase:** M0 (Foundations) complete (`Planning/MILESTONE_0_PLAN.md`). Next: plans for M1 (reference harness) and M2 (comparison toolkit); M3 (FreeBASIC runtime emulation) can start in parallel. No GEF physics has been ported yet.

## 1. Summary

| Area | State |
|---|---|
| Vision | Written: `Planning/GEF_CPP_VISION.md` |
| Implementation strategy | Written: `Planning/IMPLEMENTATION_STRATEGY.md`, 19 milestones (M0–M18) |
| Milestone plan files (`Planning/MILESTONE_<n>_PLAN.md`) | M0 written and complete; M1–M18 not started |
| C++ implementation (`Cpp_implementation/`) | Build skeleton: `gef_fbrt` library (floating-point environment self-check) and `gef` CLI (`--version`); Catch2 tests; four CMake presets |
| Python tooling (`tools/`) | Toolchain check and fbc pin, validation-data manifests, BASIC-source tools (`emit_c`, `fbline`, `fbdef`) |
| Local CI | `scripts/ci.sh` (full) and `scripts/ci.sh --quick` |
| Reference harness (`harness/`) | Not started (M1) |
| Comparison toolkit (`compare/`) | Not started (M2); one ad-hoc analysis done (§4) |
| Quirk register | `Planning/QUIRKS.md`: 29 quirks (Q-001–Q-029) and 4 build notes (B-001–B-004) |
| Coverage matrix | `Planning/COVERAGE_MATRIX.md`: 114 rows × T0–T5; no cell covered yet; one cell deferred pending user approval |
| Coding standards | `Planning/CODING_STANDARDS.md` |
| Code maps | `Planning/code_maps/`: the six planning-session reports, with a README listing corrected claims |
| Version control | `.omp/` and `validation/` are gitignored; everything else of M0 is committed |

## 2. Repository inventory

### 2.1 BASIC reference: `Reference/GEF_code` (submodule)
- Pinned at `ba9f0aa`. `git describe` reports `2023-V3.2-12-gba9f0aa`, but the source declares `C_GEF_Version = "2025/1.2"` (`GEF.bas:3`). The tag name is stale; the code is 2025/1.2.
- Licensed GPL-3.0 (`Reference/GEF_code/LICENSE`); this repository is MIT (`LICENSE.txt`).
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

## 3. What exists after M0

### 3.1 C++ build

- Top-level `CMakeLists.txt` (C++23 ISO mode, compile commands exported) and `CMakePresets.json`:

  | Preset | Compiler | Build |
  |---|---|---|
  | `dev-gcc` | GCC | Debug |
  | `dev-clang` | Clang | Debug (its `compile_commands.json` feeds clangd and clang-tidy) |
  | `asan-ubsan` | GCC | ASan + UBSan, `-fno-sanitize-recover=all` |
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

Configuration: `pyproject.toml` (ruff, basedpyright strict, pytest markers `fbc` and `slow`). Details: `tools/fbsrc/README.md`, `Planning/CODING_STANDARDS.md` §3.

### 3.3 Local CI

`scripts/ci.sh` runs the toolchain check; configure, build and test for `dev-gcc`, `dev-clang`, `asan-ubsan`; clang-tidy; clang-format; ruff lint and format; basedpyright; pytest; validation-manifest verification (skipped with a notice without `validation/`). One summary line per step, logs in `build/ci/`, non-zero exit on any failure. `--quick` runs the `dev-gcc` pipeline and the Python steps. A full run from an empty `build/` took 89 s (pytest 49 s, most of it the first `GEF.c` emission; the three C++ builds 10–13 s each); a warm run about 25 s.

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
- The 18.5 MeV outlier is probably noise from the multi-chance pre-pass, which is shared by all passes of an energy step. This is an inference, not verified.
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
| fbc reassociates multiplication chains and applies numeric literals last (`a * 0.03 * b * c` → `((a*b)*c)*0.03`); port arithmetic from the generated C | fbc C (`QUIRKS.md` B-004) |
| `MyParameters.dat` is never applied in any mode (not only batch): `MyparRead` runs once at `GEF.bas:1017`, before its flag can be set | fbc C (`QUIRKS.md` Q-018) |
| All quirks and their evidence | `Planning/QUIRKS.md` (13 confirmed in output, 12 confirmed by fbc C, 4 read only) |

### 4.3 Code maps

The six planning-session reports are saved in `Planning/code_maps/` (M0.1). Their README lists three claims corrected since (46 perturbed parameters; `GEFSUB` dead; `ctl/` holds all three control files).

## 5. Open risks and items

1. **License compatibility.** Upstream GEF is GPL-3.0; this repository is MIT. A port that translates GEF's code may count as a derivative work of the GPL code. Needs a decision by the project owner before ported code is published.
2. **Optimisation level vs fbc's `-O0`** (`QUIRKS.md` B-001): measured by M3/M5 T1 tests; fallback `-O0` per translation unit.
3. **fbc expression reordering** (B-004): the extent of fbc's constant folding and reassociation is not characterised yet. M3 drivers must establish the rules.
4. **`-fwrapv` in the fbc backend** (B-002): BASIC integer overflow wraps; C++ helpers must make it explicit (M3).
5. **Reference rebuild reproducibility** (B-003): M1 must build with `SOURCE_DATE_EPOCH` or mask the `compiled on` line.
6. **Deferred coverage cell:** the `Static Ntimes` negative-TKE guard at T4 cannot be triggered statistically; marked "deferred — needs user approval" in `COVERAGE_MATRIX.md`.
7. **Unregistered quirk candidates** seen in the code maps but not yet verified, to be registered by their owning milestones: `d_ZISOPOST` reader checks `_ZISOPOST` bounds (`Spectra.bas:1779–1787`); two-system covariance issues (`GEF.bas:11651–11652, 11905`); 1st-isomer β⁻2n line prints `Radd` instead of `2*Radd` (`Branchings.bas:578`); `TKEmin` exponents 0.33333/0.3333 (`GEF.bas:8254`); `DEFOtab(A_post - Z_sci, Z_sci)` (`GEF.bas:9313/9433`); `EexcA2d` registered as `Eexc2dlight` (`Spectra.bas:512–514`); `#If EgammaA` missing its `B_` prefix (`GEF.bas:9418`).
8. **`FetchContent` needs network** on the first configure of each build tree. Offline fallback: `catch2-devel` via dnf and `find_package`.

## 6. Next steps

1. Write `MILESTONE_1_PLAN.md` (reference harness) and `MILESTONE_2_PLAN.md` (comparison toolkit). M1 builds the patched reference binary with `tools/fbsrc` patch directories and the pinned fbc.
2. Write `MILESTONE_3_PLAN.md` (FreeBASIC runtime emulation); it can run in parallel with M1/M2 and should start by characterising fbc's expression reordering (B-004).
3. Decide the license question (§5 item 1).
