# Milestone 0: Foundations

**Status:** complete (2026-10-06)
**Strategy reference:** `IMPLEMENTATION_STRATEGY.md` §3, M0
**Depends on:** nothing
**Unblocks:** M1 (reference harness), M3 (FreeBASIC runtime emulation), and through them every later milestone

## 1. Goal

Make the repository ready for the port before any physics is written:

- C++ and Python code build, are linted and are tested by one command.
- The BASIC source can be inspected at the level the port needs: definitions, labels, and the exact C semantics of every BASIC line.
- Decisions, known quirks and coverage targets are written down where later milestones can update them.

M0 delivers no GEF physics. Everything it does deliver is real, working tooling. It contains no placeholders or stubs.

## 2. Decisions taken in this plan

| Topic | Decision | Reason |
|---|---|---|
| C++ standard | C++23, ISO mode (`-std=c++23`, not `gnu++23`) | GCC 16.2 and Clang 22 support it fully; ISO mode avoids GNU floating-point defaults |
| Build | CMake ≥ 4.0 + Ninja, `CMakePresets.json` | Both available; presets keep the build configurations reproducible |
| Primary compiler | GCC 16.2.1 (the system GCC) | fbc 1.10.1 compiles GEF's generated C with the same system `gcc`. Exact mode should share its code generation and glibc libm. Clang 22 is a second compiler for warnings and portability |
| Exact-mode floating-point flags | `-march=x86-64 -ffp-contract=off -fno-fast-math -frounding-math -fno-math-errno -fexcess-precision=standard` | Mirrors what fbc passes to gcc (`-march=x86-64 -O0 -frounding-math -fno-math-errno`, captured with `fbc -v`) and rules out FMA contraction. Optimisation level is free (see note below) |
| Warnings | `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wdouble-promotion -Wshadow -Werror` | `-Wconversion` and `-Wdouble-promotion` force every Single/Double crossing to be written explicitly, which is what fidelity needs |
| Sanitizers | `asan-ubsan` preset; TSan preset added in M17 | ASan/UBSan are verified on this machine (`.omp/LOCAL_ENVIRONMENT.md`); TSan matters only once threading arrives |
| Static analysis | `clang-tidy` with a checked-in `.clang-tidy`; `clang-format` with a checked-in `.clang-format` | Both installed |
| Unit-test framework | Catch2 v3, through CMake `FetchContent` pinned to a release tag and hash | No C++ test framework is installed system-wide. Catch2 has good floating-point matchers and test tags (used for the tier labels T0–T5). Network access is needed once, at first configure |
| Python | System Python 3.14 (pyenv), `pyproject.toml`; NumPy, SciPy and pytest are already present; ruff for lint and format; basedpyright for types | Matches `.omp/AGENTS.md` |
| FreeBASIC | fbc 1.10.1, not vendored into git (46 MB). Found through the `GEF_FBC` environment variable, with a documented default. The toolchain check verifies its version and the distribution tarball's SHA-256 (`844aa9e9…08bc`) | Pinned without bloating the repository; the check makes a different fbc version impossible to miss |
| Generated artifacts | All under `build/` (gitignored). Nothing generated is committed in M0 | Keeps the repository clean. Generated C++ data (M4) will make its own decision |
| Validation data | Stays in gitignored `validation/`. SHA-256 manifests are committed under `manifests/` | Gives tamper evidence and reproducibility without 1.1 GB in git |

**Note on optimisation level.** fbc compiles at `-O0`. On x86-64 with SSE, round-to-nearest and FMA disabled, GCC's optimisation level does not change IEEE results. The exception is library calls that GCC may constant-fold or inline differently. M3/M5 verify this claim empirically with bit-exact T1 tests. If it fails, exact mode falls back to `-O0` for the affected translation units. This is recorded as an open risk (§6).

## 3. Directory layout created in M0

```
CMakeLists.txt              top-level build (C++)
CMakePresets.json           dev-gcc, dev-clang, asan-ubsan, release-exact
.clang-format, .clang-tidy, .editorconfig
pyproject.toml              Python tooling: tools/, harness/ (M1), compare/ (M2)
Cpp_implementation/
  src/app/                  gef CLI (M0: build/version information only)
  src/fbrt/                 FreeBASIC runtime emulation (M0: floating-point environment self-check)
  tests/                    Catch2 tests, tagged [unit] [T0]…[T5]
tools/
  toolchain/                toolchain check and manifest writer
  fbsrc/                    BASIC-source tooling: C emission, line lookup, symbol index
manifests/                  committed checksums: toolchain, validation data
scripts/ci.sh               single local CI entry point
Planning/
  code_maps/                saved code-mapping reports from the planning session
  QUIRKS.md, COVERAGE_MATRIX.md, CODING_STANDARDS.md
```

`harness/` (M1) and `compare/` (M2) are created by their own milestones.

## 4. Work breakdown

Tasks are listed in execution order. Mark each one done here when finished, and update `CURRENT_PROJECT_STATE.md` (see `.omp/AGENTS.md`).

### M0.1 Save the planning-session code maps
- [x] Copy the six code-mapping reports from the planning session into `Planning/code_maps/`, one Markdown file each:
  - `control_flow.md`
  - `physics_core.md`
  - `data_layer.md`
  - `setup_physics.md`
  - `event_loop.md`
  - `outputs.md`

  They currently exist only in the session store under `.omp/sessions/`.
- [x] Add a short `README.md` there: what each map covers, the source commit (`ba9f0aa`), and the claims since corrected:
  - 46 perturbed parameters, not 48;
  - `GEFSUB` is dead code;
  - `ctl/` in `test_run` holds all three control files.

**Done when:** the six maps are readable from the repository without session access.

### M0.2 Repository hygiene
- [x] `.gitignore`: done 2026-10-06, ahead of M0. It ignores:
  - `validation/` and all of `.omp/` (the user's choice; this covers sessions, `lsp.json` and the environment notes);
  - CMake/Ninja build trees and caches, plus `compile_commands.json`;
  - objects and binaries;
  - core dumps (`/core`, `core.[0-9]*`, so source directories named `core` are not affected), profiling, coverage and sanitizer leftovers;
  - clangd caches, Python caches and virtual environments, and editor files.

  Checked with `git check-ignore`: `Planning/` and `Cpp_implementation/src/core/` are not ignored.
- [x] Add `.editorconfig`, `.clang-format` (project style, C++23), and `.clang-tidy` (bugprone, cert, cppcoreguidelines, modernize, performance, readability, with documented exclusions).
- [x] Fix `.omp/lsp.json`: clangd currently points at `--compile-commands-dir=build/match_simulation`, which belongs to another project. Point it at this project's preset build directory and export `compile_commands.json` from CMake.
- [x] Extend `.omp/LOCAL_ENVIRONMENT.md` with FreeBASIC (path, version), Universal Ctags, clang-format, and glibc 2.43.

**Done when:** clangd resolves the M0 C++ sources through `xd://lsp` with no unresolved includes.

### M0.3 Toolchain pin and check
- [x] `tools/toolchain/check_toolchain.py` verifies minimum versions and reports exact versions for: GCC, Clang, CMake, Ninja, Python, ruff, basedpyright, pytest, clang-tidy, clang-format, ctags, fbc. It also reports the glibc version.
- [x] fbc is resolved from `GEF_FBC`, falling back to `~/Downloads/FreeBASIC-1.10.1-linux-x86_64/bin/fbc`. The check confirms that `fbc -version` reports 1.10.1 and, when the tarball is present, that its SHA-256 matches `844aa9e997f9ff93566a28f05c502cf24f5aefefc64c4aca0e7a304994f508bc`.
- [x] Capture fbc's backend invocation (`fbc -v` on a one-line program). Store the gcc command line, the `as`/`ld` commands and the system `gcc --version` in `manifests/toolchain.txt`. The known `libtinfo`/`ospeed` warnings are filtered out and recorded as harmless.

**Done when:** the check passes on this machine, and fails with a clear message when `GEF_FBC` points at a missing or wrong fbc.

### M0.4 C++ skeleton and exact-mode build policy
- [x] Top-level `CMakeLists.txt` with targets:
  - `gef_fbrt` (library);
  - `gef` (CLI).
- [x] Shared compile options as an interface target, `gef_exact_fp`, so every later target inherits the floating-point flags in §2.
- [x] `CMakePresets.json` with four presets:
  - `dev-gcc`: Debug;
  - `dev-clang`: Debug;
  - `asan-ubsan`: GCC with `-fsanitize=address,undefined -fno-omit-frame-pointer`;
  - `release-exact`: GCC, optimised, exact flags.
- [x] `gef_fbrt`: `fp_environment` module, a runtime self-check of the assumptions exact mode depends on:
  - `FLT_EVAL_METHOD == 0`;
  - IEEE 754 `float`/`double` (`std::numeric_limits<T>::is_iec559`);
  - rounding mode is to-nearest at start-up;
  - no FMA contraction: a known `a*b+c` case that rounds differently with and without FMA gives the non-FMA result.
- [x] `gef --version` prints the project version, git revision, compiler and version, build preset, the floating-point flags compiled in, and the `fp_environment` verdict. M1/M2 manifests record this output for every C++ run.

**Done when:** all four presets configure and build with zero warnings, and `gef --version` reports a passing floating-point environment for each preset.

### M0.5 Test infrastructure
- [x] Catch2 v3 via `FetchContent`, pinned to a release tag and archive hash, registered with CTest through `catch_discover_tests`.
- [x] Tag convention:
  - `[unit]` for implementation tests;
  - `[T0]`…`[T5]` for differential and integral tiers;
  - `[slow]` for anything over 10 s.

  CTest labels mirror the tags, so `ctest -L T1` runs one tier.
- [x] Tests for `fp_environment`. Each assumption gets one test that would fail on a contracting or fast-math build.
- [x] Negative check, performed once and recorded in the plan's completion notes: building the FMA test with `-mfma -ffp-contract=fast` makes it fail.

**Done when:** `ctest --preset <each>` passes, and the negative check is observed and recorded.

### M0.6 Python tooling environment
- [x] `pyproject.toml` for the in-repo tooling packages (`tools/` now; `harness/` and `compare/` later):
  - ruff settings (lint and format);
  - basedpyright in strict mode for new code;
  - pytest configuration.
- [x] Dependencies declared: NumPy and SciPy (already installed). Nothing new needs installing for M0.

**Done when:** `ruff check`, `ruff format --check`, `basedpyright` and `pytest` all run cleanly on the M0 Python code.

### M0.7 BASIC-source tooling (FreeBASIC → C translation, line lookup, symbol index)
This task carries the tooling folded in from the LSP discussion. It is the main way to work out what a BASIC line computes, and it must be usable for every later milestone.

- [x] `tools/fbsrc/emit_c.py`:
  1. Copies `Reference/GEF_code/source/` into `build/fbsrc/<submodule-rev>/src/`. The submodule is never written to.
  2. Runs `fbc -gen gcc -R -g -c GEF.bas` there.
  3. Keeps `GEF.c`.
  4. Writes `build/fbsrc/<rev>/manifest.json`: fbc path and version, the full command line, submodule revision, SHA-256 of `GEF.c`, and wall time.

  Accepts `--patch-dir` so M1 can emit C from patched harness copies with the same tool.
- [x] `tools/fbsrc/fbline.py <file>:<line>[-<line>]`: prints the BASIC source line(s) and the C statements generated from them, found through the `#line` directives. Works for included files (e.g. `Spectra.bas:1505`, `ENDF.bas:1170`) as well as `GEF.bas`. Optional flags:
  - `--context N`;
  - `--raw`, to keep tabs and temporaries;
  - `--symbols`, to annotate fbc-mangled names (`E_INTR_HEAVY$`) with their BASIC spelling.
- [x] `tools/fbsrc/fbdef.py <name>`: case-insensitive definition lookup from a Universal Ctags index of all 38 `.bas`/`.bi`/`.mac` files (`--map-Basic=+.bi --map-Basic=+.mac`). Reports kind (function, label, variable, type, constant), file and line. With `--refs`, it also lists case-insensitive whole-word references, so `E_MIN` and `E_min` resolve to the same symbol.
- [x] pytest suite for the three tools, using the facts established during planning as fixtures:
  - `fbline GEF.bas:8392` shows the division done in `double` and narrowed with `(float)`.
  - `fbline GEF.bas:9417` shows the discarded `EGAMMA(...)` call with a comparison argument.
  - `fbdef PGauss` → `GEF.bas:17956`; `fbdef calcstart` → label at `GEF.bas:4811`; `fbdef E_tunn` → `GEF.bas:791`.
  - Emitting twice gives the same `GEF.c` hash, so the output is deterministic.

**Done when:** the fixtures pass, a full emit takes under 60 s (measured about 11 s during planning), and the README in `tools/fbsrc/` documents the usage.

### M0.8 Validation data manifests
- [x] `tools/toolchain/manifest_validation.py` writes `manifests/validation_reference.sha256` (all 382 reference tapes plus the two sequence files) and `manifests/validation_test_run.sha256` (the binary, `run.log`, the ENDF tape, `out/`, `dmp/` and `tmp/`).
- [x] It also verifies those manifests and reports missing, changed or extra files.
- [x] Record in the manifest header that `validation/test_run/` is **not** a clean run: it has stale `ctl/` and a two-tape ENDF file. It must be used as recorded evidence only, never as a working directory.

**Done when:** the manifests are committed-ready and verification passes against the current files.

### M0.9 Living project documents
- [x] **`Planning/CODING_STANDARDS.md`**:
  - C++ conventions: naming, ownership, no mutable globals, explicit `Rng&` parameters, `float` for BASIC `Single` and `double` for BASIC `Double`, every conversion through `fb::` helpers once M3 provides them.
  - Provenance comments: `// GEF.bas:8392` on every ported statement group.
  - Quirk annotations: `// QUIRK(Q-0xx)`, linked to the register.
  - Test naming and tier tags.
  - Python conventions.
  - Commit hygiene: commits only when the user asks.
- [x] **`Planning/QUIRKS.md`**: register format (ID, BASIC location, observed or expected effect, evidence status: *confirmed in output* / *confirmed by fbc C* / *read only*, fidelity switch name, owning milestone). Seed it with the quirks already identified, at minimum:

  | Seed | Location | Short description |
  |---|---|---|
  | Heavy-fragment E1 gammas dropped | `GEF.bas:9417` | `Egamma(N) = Egamma(N) + 1` is a no-op |
  | `ENsci` writes dropped | `GEF.bas:8129, 8152` | Same accessor no-op mechanism |
  | Uncertainty cap adds instead of setting | `GEF.bas:11383–11391`, `Spectra.bas:1788` | σ printed as σ+Y |
  | `EdefoA` always zero | `GEF.bas:10245` | `UBound(EdefoA,I)` uses the wrong dimension |
  | ZApre/ZApost rows written after close | `GEF.bas:14842–15157` | Works only because `Freefile` reuses the file number |
  | `Nmulti2dpre/post` never cleared | `CLEARspectra.bas` | Accumulates over the whole process |
  | Stale global `Z` in pre-pass parity | `GEF.bas:4322` | First energy step behaves differently |
  | Mode-7 `E_tunn`, `E_diss_Scission` leak | `GEF.bas:7214–7219` | Event loop reads overwritten values |
  | `Beta(4,1,·)` never set | `GEF.bas:5831` | Write lands in `Beta(5,1,·)` |
  | `EPART`/`PEOZ`/`PEON` never cleared outside filled range | `GEF.bas:7173–7379, 7436` | Stale reads in `SpinRMSNZ` |
  | EOscale applied twice on mirrored half | `GEF.bas:7322` | Only matters for EOscale ∉ {0,1} |
  | `J_attempt` retry double-fills histograms | `GEF.bas:8676–8728` | Spin/Q histograms counted twice |
  | Isomer windows double-count shared endpoints; `R_lim` clamped in place | `GEF.bas:14212–14300` | Affects isomeric ratios |
  | BranchData isomer row overwrites `R_alpha` | `Branchings.bas:147` | `R_alpha_m` stays in percent |
  | 3rd-isomer missing-branch fallback moves state 2 | `Branchings.bas:434–438` | |
  | Branch table loading stops at Ra-234 | `Branchings.bas` loader | Z 89–111 rows never loaded |
  | `MyParameters.dat` ignored in batch; `Fitpar.dat` reset per system | `GEF.bas:1017, 3320` | |
  | `Var_PZ_S3_olap_curv` effectively unperturbed | `GEF.bas:2575` | Uses working copy (0) |
  | Analyzer registry naming errors | `Spectra.bas:1082–1096` and ErotL2d entries | Changes `dmp` header text |
  | `I_MAT_ENDF` persists state in `ctl/IMATmax.ctl` | `NucProp_Functions.mac:28–49` | Run-history-dependent MAT numbers |
  | TXE printed with the TKE uncertainty | `GEF.bas:14403` | |
  | "Width" prints variance | `GEF.bas:13753, 13773` | |
  | ENDF `R_Norm` accumulated in Single | `ENDF.bas` | Visible as 1.999998-6 style values |
  | lmd output consumes random numbers | `GEF.bas:9680–9839` | Enabling LMD changes physics results |
  | Outputs opened `For Append`, `ctl/` never cleaned | `GEF.bas:10077`, `ENDF.bas:676` | Two-tape ENDF file in `test_run` |

  Every seed entry is checked against the source with `fbline` (M0.7) before it is added. Entries not confirmable in M0 are marked *read only*, with the milestone that will confirm them.
- [x] **`Planning/COVERAGE_MATRIX.md`**: rows are the dimensions in vision §4.4 (system classes, kinds of fission, energy regimes and thresholds, options, observables, internal behaviours). Columns are the tiers T0–T5. Each cell holds status (*uncovered* / *planned (Mxx)* / *covered (test id)*). Initial state: every cell *uncovered* or *planned* with its owning milestone from the strategy.

**Done when:** the three documents exist, the quirk seeds are verified as described, and every matrix cell has an owning milestone or an explicit "deferred — needs user approval" mark.

### M0.10 Local CI entry point
- [x] `scripts/ci.sh` runs, in order:
  1. toolchain check (M0.3);
  2. configure, build and test for `dev-gcc`, `dev-clang` and `asan-ubsan`;
  3. clang-tidy over `Cpp_implementation/src`;
  4. clang-format check;
  5. ruff lint and format check;
  6. basedpyright;
  7. pytest;
  8. validation-manifest verification (M0.8; skipped with a notice if `validation/` is absent).

  It exits non-zero on any failure, prints a one-line summary per step, and supports `--quick` (gcc preset and Python only).

**Done when:** `scripts/ci.sh` passes from a clean checkout plus `build/` deletion, and a deliberately introduced warning makes it fail.

### M0.11 Close-out
- [x] Update `IMPLEMENTATION_STRATEGY.md` if any decision here changed it.
- [x] Update `CURRENT_PROJECT_STATE.md` with:
  - what exists now;
  - the CI command;
  - the tool usage (`emit_c`, `fbline`, `fbdef`);
  - open risks.
- [x] Mark this plan complete.

## 5. Exit gate (all must hold)

1. `scripts/ci.sh` passes on this machine.
2. All four presets build with zero warnings.
3. `gef --version` reports a passing floating-point environment for each preset.
4. The FMA negative check has been observed failing once.
5. `fbline` reproduces the `GEF.bas:8392` and `GEF.bas:9417` facts, and `fbdef` the three definition facts. Repeated C emission is deterministic.
6. Validation manifests verify.
7. Code maps, `QUIRKS.md`, `COVERAGE_MATRIX.md` and `CODING_STANDARDS.md` exist in `Planning/`, with the content specified above.
8. clangd resolves the C++ sources through the project LSP configuration.

## 6. Out of scope (later milestones)

- Building and running BASIC GEF from the harness:
  - patches, seeds and probes;
  - clean-run runner;
  - neutrality proofs.

  All of this is M1. M0 only *translates* the BASIC source to C.
- Comparison parsers and statistics (M2).
- Any FreeBASIC runtime emulation beyond the floating-point environment self-check (M3).
- clangd indexing of the generated 230k-line `GEF.c`. `fbline` covers the need; revisit only if a concrete use appears.

## 7. Risks and open questions

| Item | Handling |
|---|---|
| Optimisation level changes floating-point results relative to fbc's `-O0` (inlined or constant-folded libm calls) | Measured in M3/M5 T1 tests. Fallback: `-O0` for affected translation units. Tracked in `QUIRKS.md` as a build note, not a GEF quirk |
| `FetchContent` needs network on first configure | One-time. If offline, install `catch2-devel` via dnf (needs the user) and switch to `find_package` |
| fbc prints `libtinfo`/`ospeed` warnings | Harmless (the linked ncurses symbol size differs). Filtered and recorded in M0.3 |
| `.omp/` files are machine-specific and partly the user's | M0.2 edits only the clangd entry in `lsp.json` and appends to `LOCAL_ENVIRONMENT.md`, and reports both changes |
| Whether the generated `GEF.c` from the unpatched source matches what built `validation/test_run/gef_reference` | Not needed for M0 (C emission is for reading). M1 proves the rebuilt reference binary is equivalent |

## 8. Completion notes

Closed 2026-10-06 (started and finished the same day).

**Exit gate.**

| # | Gate | Result |
|---|---|---|
| 1 | `scripts/ci.sh` passes | Full run from an empty `build/`: all 11 steps PASS in 89 s (toolchain 0 s, dev-gcc 10 s, dev-clang 11 s, asan-ubsan 13 s, clang-tidy 3 s, clang-format 1 s, ruff 0 s, basedpyright 1 s, pytest 49 s, manifests 1 s). Warm run about 25 s. With a deliberately added `float f(double x) { return x; }` in `fp_environment.cpp`, `scripts/ci.sh --quick` failed at `build-test-dev-gcc` (`-Werror=float-conversion`) and exited 1 |
| 2 | Four presets build with zero warnings | `dev-gcc`, `dev-clang`, `asan-ubsan`, `release-exact`: 0 warnings; `ctest --preset <each>` 7/7 passed |
| 3 | `gef --version` passes for each preset | `fp_environment verdict: PASS` for all four (GNU 16.2.1 ×3, Clang 22.1.8) |
| 4 | FMA negative check observed | See below |
| 5 | `fbline`/`fbdef` facts and deterministic emission | pytest fixtures pass; repeated emission gives `GEF.c` SHA-256 `cf0c88ea…40ff4` every time |
| 6 | Validation manifests verify | 384 reference files and 1719 test-run files verify (0.4 s warm); GNU `sha256sum -c --strict` also accepts both |
| 7 | Documents exist | `Planning/code_maps/` (6 maps + README), `QUIRKS.md`, `COVERAGE_MATRIX.md`, `CODING_STANDARDS.md` |
| 8 | clangd resolves the C++ sources | `xd://lsp` diagnostics: no issues in all three `.cpp` files; go-to-definition from `main.cpp` resolves `check_fp_environment` in `fp_environment.cpp` |

**FMA negative check (M0.5).** Throwaway build tree `build/negative-fma` (GCC, Release), with `-mfma -ffp-contract=fast` appended after the target flags by overriding `CMAKE_CXX_COMPILE_OBJECT` (in `CMAKE_CXX_FLAGS` they would be overridden by `gef_exact_fp`'s `-ffp-contract=off`). Result: `fbrt: a*b+c is not contracted to a fused multiply-add` FAILED with `double (1+2^-27)(1-2^-27) - 1 = -0x1p-54; float (1+2^-13)(1-2^-13) - 1 = -0x1p-26` (the unfused results are 0); the combined-report test and the `gef --version` CTest also failed (3 of 7 tests), and `gef --version` printed `[FAIL] no_fma_contraction` with verdict FAIL. A second throwaway configuration with `-ffast-math` failed 6 of 7 tests (`NaN != NaN = false`, `__FAST_MATH__` defined). The tree was deleted afterwards.

**Measured timings.** Full `GEF.c` emission: fbc step 11.5–17.6 s depending on machine load (limit 60 s); `fbline` about 0.7 s per call and `fbdef` 0.6–0.9 s once `GEF.c` and the index exist; toolchain check about 1.5 s; manifest verify 0.4 s with a warm page cache.

**Deviations and additions.**
- **Determinism of C emission needed `SOURCE_DATE_EPOCH`.** `GEF.bas:17` embeds `__DATE_ISO__`/`__TIME__`, so two plain emissions differed. `emit_c` sets `SOURCE_DATE_EPOCH` to the submodule commit time (recorded in the manifest). fbc also writes absolute `#line` paths for included files, so the manifest records a path-normalised hash as well (`QUIRKS.md` B-003).
- **Patch-directory format** (for M1): unified diffs `*.patch`/`*.diff`, applied in name order with `patch -p1`; the emission key gets a `-p<hash>` suffix.
- **`fbdef` corrects the ctags Basic parser**, which misses `Static` declarations, `ReDim`-only arrays and `#Define`, mis-tags `Const As Single pi`, and creates labels from comments.
- **fbc backend flags include `-fwrapv -fno-strict-aliasing`**, which are not in §2's exact-mode list. They do not affect floating point; recorded as `QUIRKS.md` B-002 for M3.
- **fbc reassociates multiplication chains** and applies literals last (found while checking the quirk seeds); recorded as `QUIRKS.md` B-004. The coding standards already require porting from the generated C.
- **Quirk seeds:** the seed table has 25 rows; the isomer row was split into two entries (Q-013, Q-014), three entries were added from the vision and strategy (Q-027–Q-029), and the `Parameters.bas` re-include was merged into Q-018. 15 seed locations were corrected and 7 seed claims refined, each with evidence in the register (e.g. `MyParameters.dat` is ignored in every mode, not only batch; the `J_attempt` retry can count an event up to four times).
- **Coverage matrix:** 114 rows; 424 cells planned, 259 n/a with a reason, 1 deferred (the `Static Ntimes` negative-TKE guard at T4) pending user approval.
- **CTest `noTestsAction=error`** in the test presets: a label filter that matches nothing (e.g. `-L T1` today) fails instead of passing silently.
- **Clang and `-fexcess-precision=standard`:** accepted, but on Clang it only governs `_Float16`/`__bf16`; `FLT_EVAL_METHOD == 0` is checked at run time instead.
- **License notices:** every source file carries an SPDX license notice (`.omp/AGENTS.md`, `CODING_STANDARDS.md` §1). The project was relicensed from MIT to GPL-3.0-or-later on 2026-10-07, after M0 closed, because the port is a derivative work of GPL-licensed GEF.
- `IMPLEMENTATION_STRATEGY.md` needed no change: no decision in this plan altered it.
