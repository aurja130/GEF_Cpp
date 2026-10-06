# GEF in C++: Current Project State

**As of:** 2026-10-06
**Phase:** M0 planned (`Planning/MILESTONE_0_PLAN.md`), not started. No C++ code exists.

## 1. Summary

| Area | State |
|---|---|
| Vision | Written: `Planning/GEF_CPP_VISION.md` |
| Implementation strategy | Written: `Planning/IMPLEMENTATION_STRATEGY.md`, 19 milestones (M0–M18) |
| Milestone plan files (`Planning/MILESTONE_<n>_PLAN.md`) | M0 written; M1–M18 not started |
| C++ implementation (`Cpp_implementation/`) | Empty directory |
| Reference harness (`harness/`) | Not started |
| Comparison toolkit (`compare/`) | Not started; one ad-hoc analysis done (§4) |
| Quirk register / coverage matrix | Not created; scheduled for M0 |
| Version control | One commit (`28bc926`, adds the submodules). `.gitignore` (now covering `validation/`, `.omp/` and C++/Python build artifacts) and `Planning/` are untracked and uncommitted |

## 2. Repository inventory

### 2.1 BASIC reference: `Reference/GEF_code` (submodule)
- Pinned at `ba9f0aa`. `git describe` reports `2023-V3.2-12-gba9f0aa`, but the source declares `C_GEF_Version = "2025/1.2"` (`GEF.bas:3`). The tag name is stale; the code is 2025/1.2.
- Source: `source/` holds about 88k lines.
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

**Caveats about `test_run/`:**
- It is **not** a clean working directory.
- `ctl/` still holds `thread.ctl`, `done.ctl` and `sync.ctl`.
- The ENDF file contains two concatenated tapes:
  - Lines 1–857 come from an earlier thermal-only run.
  - Line 858 onward is the real 59-energy tape.
- Reruns in this directory would append to the existing outputs.

### 2.4 Toolchain on this workstation

| Tool | Status |
|---|---|
| FreeBASIC 1.10.1 | Present at `~/Downloads/FreeBASIC-1.10.1-linux-x86_64`. Compiles and runs, with harmless `libtinfo` warnings. **Not on PATH** |
| GCC 16.2.1, Clang 22.1.8 | Available |
| CMake 4.3.0, Ninja | Available |
| Python 3, NumPy 2.4.6, SciPy 1.17.1 | Available |
| Meson, Conan, vcpkg | Not installed (not required by the strategy) |
| CPU | 20 cores |
| Universal Ctags 6.2.1 | Available. Its `Basic` parser indexes the GEF sources correctly (functions, subs, `GoTo` labels, `Dim Shared` globals) |
| FreeBASIC LSP server | None exists (not in the official LSP server list; the best editor tooling is an in-process VS Code extension that omp cannot use) |

**FreeBASIC → C translation (checked 2026-10-06).**
- `fbc -gen gcc -R -g -c GEF.bas`, run on a copy of `source/`, takes about 11 s.
- It produces a 230k-line `GEF.c` with about 100k `#line` directives that map back to `GEF.bas` and the include files.
- The C shows the exact type promotions and casts. For example, `GEF.bas:8392` (`I_A_heavy_sci/I_A_sci`) becomes a double division, and the `Egamma(N) = Egamma(N) + 1` no-op at `GEF.bas:9417` becomes a discarded accessor call with a boolean argument.
- This translation is the planned semantic reference for porting. It is not yet scripted into the repository.

## 3. Planning documents

- **`GEF_CPP_VISION.md`** covers:
  - the goal: a faithful, modern C++ GEF;
  - what is out of scope;
  - differential and integral testing, in test tiers T0–T5;
  - the reference harness concept;
  - the coverage dimensions;
  - statistical acceptance rules;
  - the definition of done.
- **`IMPLEMENTATION_STRATEGY.md`** covers:
  - a component inventory mapped to BASIC line ranges;
  - strategic decisions: fidelity-first quirk register, exact numeric mode, FreeBASIC-compatible RNG with a per-event reseed mode, scope-based state model, generated data, reference harness with neutrality proofs, null-calibrated comparisons;
  - the milestones with their gates;
  - a dependency graph with a physics track (M6–M10) and an analysis/output track (M11–M13) that meet at M14;
  - risks.

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

These are the facts the strategy depends on, and how each was confirmed.

| Fact | How confirmed |
|---|---|
| `Randomize ,3` (`GEF.bas:1553`) seeds the Mersenne Twister from the clock; runs are not reproducible | read |
| Nominal pass uses `Fenhance·10⁵` events. Perturbed passes: `Int(sqrt(100·Fenhance))` passes (31 for `Fenhance = 10`) of 32,258 events each | read; matches `run.log` |
| 46 parameters are perturbed (`GEF.bas:5104–5162`) | counted |
| `GEFSUB`/`GEFRESULTS` (`GEF.bas:7514–7919`) is dead code inside a nested comment | read |
| `Egamma(N) = Egamma(N) + 1` (`GEF.bas:9417`) is a silent no-op, so heavy-fragment E1 gammas are missing from the total gamma spectrum | fbc 1.10.1 test program; consistent with `Egamma.dmp` |
| Float → integer conversion rounds half to even | fbc 1.10.1 test program |
| ENDF n-induced runs use N + 3 energy steps; the first two and the last write no MT454 data | read; matches `run.log` |
| Outputs are opened `For Append`, and `ctl/` is never cleaned; this is how the two-tape ENDF file arose | read; matches `done.ctl` |
| Further quirks to be entered in the quirk register in M0 (e.g. `d_ZISOPOST` cap adds instead of setting, `EdefoA` always zero, `ZApre`/`ZApost` written through a closed file number, `MyParameters.dat` ignored in batch) | read; some confirmed in `test_run` outputs. Full list in `IMPLEMENTATION_STRATEGY.md` §1.3 |

### 4.3 Where the detailed code maps live

The four slice analyses and the two earlier overviews exist only in the agent session that produced them. They covered data layer, setup physics, event loop, outputs, control flow and physics core.

`IMPLEMENTATION_STRATEGY.md` keeps their essentials. The milestone plans will need to re-derive the details: per-component data contracts, per-quirk line numbers and probe points. One option is to save the reports into `Planning/` before they are lost.

## 5. What does not exist yet

- Any C++ source, build files or tests.
- The reference harness:
  - patches;
  - seed control;
  - probes;
  - FreeBASIC drivers;
  - the clean-run runner;
  - the reference store and manifests.
- The comparison toolkit. The analysis in §4.1 was a throwaway script and was not saved.
- `QUIRKS.md`, `COVERAGE_MATRIX.md`, `CODING_STANDARDS.md` (all M0 deliverables), and plans for M1–M18.
- A clean, seeded BASIC reference run.
- Checksums or manifests for `validation/`.

## 6. Open items and decisions pending

1. **Commit the planning work.** `.gitignore` and `Planning/` are untracked.
2. **Toolchain pinning:** decided in the M0 plan. fbc is not vendored; it is located through `GEF_FBC` and verified by version and tarball SHA-256. Rebuilding a binary equivalent to `validation/test_run/gef_reference` is an M1 task.
3. **Validation data management:** decided in the M0 plan. SHA-256 manifests are committed under `manifests/`; the data stays in gitignored `validation/`.
4. **Test framework and C++ standard:** decided in the M0 plan. C++23 in ISO mode and Catch2 v3, fetched with `FetchContent` (needs network once).
5. **The planning-session code maps exist only in `.omp/sessions/`.** M0.1 saves them into `Planning/code_maps/` and should run first.

## 7. Next steps

1. Run M0 per `Planning/MILESTONE_0_PLAN.md`, starting with M0.1 (saving the code maps).
2. Write `MILESTONE_1_PLAN.md` (reference harness) and `MILESTONE_2_PLAN.md` (comparison toolkit).
