# Milestone 1: Reference Harness

**Status:** complete (2026-10-07)
**Strategy reference:** `IMPLEMENTATION_STRATEGY.md` §2.6 and §3, M1
**Depends on:** M0 (complete)
**Unblocks:** M2 (comparison toolkit), and through the probes, drivers and draw logs every differential gate from M3 onward

## 1. Goal

Make the BASIC program a controllable, observable test oracle:

- A **reference binary** that takes its random seed from the caller. It is proven byte-equivalent to the existing `validation/test_run/gef_reference`: the seed the original binary picks from the clock is captured during a run and replayed (§2, decision D1).
- **Seed control and a per-event reseed mode**, so BASIC runs are repeatable and T3 trajectory comparisons stay local.
- **Rnd logging, probes and function drivers**, so any BASIC quantity a later milestone names can be captured exactly.
- A **clean-run runner** and an **immutable reference store** with committed manifests.

M1 ports no physics and writes no C++. Everything it delivers is working tooling, proven by the gates in §5.

## 2. Decisions taken in this plan

| ID | Topic | Decision | Reason |
|---|---|---|---|
| D1 | Reference binary | Build the submodule source with **only the seed patch** applied. Run the original `gef_reference` and capture the seed it derives from the clock. Run the new build with that seed and require byte-identical output (timestamps masked). Once that holds, the new build is **the M1 reference binary**. `gef_reference` stays as recorded history | User decision (2026-10-07). Replaying the captured seed gives byte-level proof instead of statistical equivalence |
| D2 | Seed capture | Run `gef_reference` under `gdb` with a breakpoint on the runtime's MT initialiser `hRndCtxInitMTWIST32` and read its argument (`$rdi`). Then delete the breakpoints and continue to completion | Non-invasive: the binary is not modified, and a breakpoint does not change what it computes. Feasibility shown during planning (§3) |
| D3 | Seed injection | Environment variable `GEF_SEED`, a decimal integer 0 … 2³²−1. The seed patch replaces `Randomize,3` (`GEF.bas:1553`) with `Randomize Val(seed),3`. A harness binary without `GEF_SEED` stops with a message and a non-zero exit code before any computation | `fb_Randomize(s, 3)` seeds MT with `(uint32_t)s`, so an explicit integer seed reproduces the clock path exactly (§3). Failing loudly avoids accidental clock-seeded runs |
| D4 | Run sizes | Runs use **production `Fenhance`** (10 for `EN`, 100 for `GS`). Runs are shortened only by using fewer energies (§4.3) | User decision (2026-10-07): shorten energy ranges, never the event statistics |
| D5 | Statistical check | M1 contains a **minimal** statistical check (Poisson z-scores against `validation/reference/`, thresholds fixed in §4.9). M2 replaces it with the full, null-calibrated toolkit | User decision (2026-10-07) |
| D6 | Per-event reseed | A **separate run mode** (`GEF_RESEED=1`). It deliberately changes the random stream, so it is not subject to the neutrality proof against normal mode. It must be repeatable and probe-neutral within its own mode, and its seed derivation is a written spec that the C++ code reproduces in M3 | Approved (2026-10-07) |
| D7 | Volume control | Rnd logging and per-bin/per-event probes are off by default and enabled by run-time scope selectors (energy step, pass, event range) | Approved (2026-10-07). A full Rnd log of one energy step is about 10⁸ draws |
| D8 | Reference store | Captured runs and binaries live in `validation/reference_store/` (gitignored). Each capture has a committed manifest in `manifests/reference_store/`. Captures are immutable; a new capture gets a new ID | Approved (2026-10-07). Follows the M0 convention: data outside git, checksums in git |
| D9 | Build options | Harness binaries are built with `fbc GEF.bas` and no extra options (fbc defaults, gcc `-O0`), plus `-d` defines that switch the probe and logging code on. `SOURCE_DATE_EPOCH` is set to the submodule commit time | These are the options that reproduce `gef_reference` (§3). `SOURCE_DATE_EPOCH` makes builds reproducible (`QUIRKS.md` B-003) |
| D10 | Patches | Unified diffs in `harness/patches/`, applied in order by named **patch sets** (`harness/patchsets/<name>.txt`), using the same `patch -p1` mechanism as `tools/fbsrc/emit_c --patch-dir`. `emit_c` shows the generated C of every patch set | Reuses the M0 tooling. Patch sets keep the variants (seed only; seed + probes; seed + Rnd log; …) explicit |
| D11 | Language and layout | Harness tooling in Python under `harness/` (run as `python3 -m harness.<module>`), with FreeBASIC drivers under `harness/drivers/`. `pyproject.toml` extends ruff, basedpyright and pytest to `harness/` | Same conventions as `tools/` (`CODING_STANDARDS.md` §3) |

## 3. Facts established while planning (2026-10-07)

| Fact | Evidence |
|---|---|
| `Randomize,3` compiles to `fb_Randomize( -0x1.p+0, 3 )` (GEF.c:30780). It is the only `Randomize` in the program | `build/fbsrc/ba9f0aa/src/GEF.c` |
| In fbc 1.10.1, `fb_Randomize(-1.0, 3)` computes `seed = (double)(lo32(Timer) ^ hi32(Timer))` and then calls `hRndCtxInitMTWIST32((uint32_t)seed)`. An explicit `Randomize s,3` with the same integer `s` therefore produces the identical generator state | `src/rtlib/math_rnd.c` at fbc tag `1.10.1` |
| `gef_reference` contains the static symbols `fb_Randomize`, `hRndCtxInitMTWIST32` and `fb_Timer`. A gdb breakpoint on `hRndCtxInitMTWIST32` in a scratch directory stopped once and read a seed (`2651126221` in that trial run) | `gdb -batch` trial, scratch directory deleted afterwards |
| Rebuilding the **unpatched** submodule source with `fbc GEF.bas` (fbc 1.10.1, gcc 16.2.1, `SOURCE_DATE_EPOCH` set to 2026-09-15 17:20:38 UTC) gives a binary whose **loaded sections are byte-identical** to `gef_reference`, with identical disassembly. Only the non-loaded `.comment` section differs: the reference also records a glibc static object built by GCC 16.1.1 | Section-by-section `cmp` and `objdump -d` diff |
| GEF draws random numbers at 60 call sites, all `Rnd` with no argument (`fb_Rnd( 0x1.p+0f )`) | GEF.c |
| `Timer` is also read at `GEF.bas:704` (`await`, process-slot waiting) and `GEF.bas:1887` (`Timeoffset`, written to `ctl/thread.ctl`). `run.log` prints the compile stamp and wall-clock progress lines (`… processed at 15.09.2026, 18:21:24`) | Source; `validation/test_run/run.log` |
| Rn-215 compound nucleus (input `86, 215, "EN"`): no pre-pass below 13 MeV; from 13 MeV the pre-pass runs but finds too few fissions ("100% first-chance fission assumed"); first pre-pass fissions at 14.5 MeV; second chance from 18.5 MeV (Pf₂ = 0.059); second chance at 1–15 % from 22 to 30 MeV | `validation/test_run/run.log` |
| The production run took about 106 min for 62 energy steps (59 energies + 3), i.e. about 1.7 min per step at `Fenhance = 10` | `run.log` timestamps |

## 4. Work breakdown

Tasks in execution order. Mark each one done here when finished, and update `CURRENT_PROJECT_STATE.md` (see `.omp/AGENTS.md`).

### M1.1 Harness skeleton
- [x] Create `harness/` (Python package with `__init__.py`, `README.md`, `tests/`), `harness/patches/`, `harness/patchsets/`, `harness/drivers/`, `harness/inputs/`.
- [x] Extend `pyproject.toml`: ruff and basedpyright include `harness/`; pytest `testpaths` adds `harness`.
- [x] License notices per `CODING_STANDARDS.md` §1. FreeBASIC drivers and patch files that carry GEF code also carry the GEF copyright line (FreeBASIC comment syntax `'`).

**Done when:** `scripts/ci.sh --quick` lints, type-checks and tests `harness/`.

### M1.2 Patch-set builder
- [x] `python3 -m harness.build <patchset> [--define NAME …]`:
  1. Copies `Reference/GEF_code/source/` to `build/harness/<build-id>/src/`. The build ID hashes the patch-set content, the defines, the submodule revision and the fbc version.
  2. Applies the patch set's patches in order (`patch -p1`, as `emit_c` does).
  3. Compiles with `fbc GEF.bas` plus the `-d` defines, `SOURCE_DATE_EPOCH` = submodule commit time, fbc from `tools.toolchain.fbc.resolve_fbc()`.
  4. Writes `build/harness/<build-id>/build.json`: patch set and patch hashes, defines, fbc version and command, binary SHA-256, wall time.
- [x] Builds are reproducible: the same request gives the same binary SHA-256.
- [x] A patch set named `none` (no patches) exists and is used to re-establish the §3 fact: its binary's loaded sections match `gef_reference` when built with the original compile stamp time.

**Done when:** `none` and `seed` (M1.4) build reproducibly, and the `none` comparison is recorded in the completion notes.

### M1.3 Clean-run runner and timestamp masks
- [x] `python3 -m harness.run --binary <path|build-id> --input <sequence file> --seed N [--reseed] [--scope …] --out <dir>`:
  - creates a fresh working directory (refuses an existing one), writes `file.in` pointing at the copied sequence file, and runs the binary with `stdin` from `/dev/null`;
  - captures stdout (`run.log`) and stderr, exit code and wall time;
  - writes `run.json`: binary SHA-256, input SHA-256, seed, mode, scope selectors, environment variables set, timings.
- [x] Every run happens in a working directory at the **same absolute path depth and name** (`<store>/<capture-id>/work/`), so any path printed by GEF compares equal.
- [x] `harness/masks.toml`: the list of time-dependent output fields. Built **before** gate G1 by enumerating every time source in the BASIC (`Date`, `Time`, `Now`, `Timer`, `Compilationstamp`, `Format(Now…)`) with `fbdef --refs` and `fbline`, and listing each output line or file field it reaches. Each entry names its BASIC location.
- [x] `python3 -m harness.compare_runs <dirA> <dirB>`: byte comparison of every output file (`run.log`, `out/`, `dmp/`, `ENDF/`, `tmp/`, probe and log files), with only the `masks.toml` fields masked. It reports the first differing line per file. A mask that matches nothing is reported, so masks cannot hide drift.

**Done when:** pytest covers the runner's refusal of dirty directories, the manifest content and the mask logic on synthetic files; the mask list is complete per the enumeration above.

### M1.4 Seed patch and seed capture
- [x] Patch `seed`: implements D3 at `GEF.bas:1553`. Check the generated C with `emit_c --patch-dir`: the call must become `fb_Randomize( <value of GEF_SEED>, 3 )`, and no other statement may change apart from the code that reads `GEF_SEED`.
- [x] `python3 -m harness.capture_seed --input <sequence file> --out <dir>`: runs `validation/test_run/gef_reference` (verified against `manifests/validation_test_run.sha256` first) in a fresh working directory under `gdb -batch`:
  - a breakpoint on `fb_Randomize` checks the arguments are `(-1.0, 3)`;
  - a breakpoint on `hRndCtxInitMTWIST32` reads the seed from `$rdi` and stops if it is hit more than once;
  - after the capture all breakpoints are deleted and the run continues to completion; the program's stdout and stderr are redirected to files inside `gdb`'s `run` command.

  The captured seed goes into the run manifest.

**Done when:** a short capture run records a seed, and a harness run of the `seed` build with that seed on the same input matches it (`compare_runs`), as a smoke test before G1.

### M1.5 M1 run inputs
- [x] `harness/inputs/m1_rn215_short.in`: the `gefy_nfy` settings with a shortened energy list, `Fenhance = 10`, `Options(ENDF)`, system `86, 215, "EN"`. Energies, chosen from the facts in §3:

  | Energy (MeV) | Why |
  |---|---|
  | 0.0253E-6 | Thermal |
  | 2 | Fast, first-chance only |
  | 7 | Below the pre-pass threshold |
  | 13 | Pre-pass runs, too few fissions (first-chance fallback path) |
  | 14.5 | First pre-pass fissions |
  | 18.5 | Second chance appears; the outlier energy of the planning comparison |
  | 22 | Second chance established |
  | 30 | Maximum energy; it is also the second step of the N+3 ENDF schedule |

  8 energies, 11 energy steps, about 19 min per run.
- [x] `harness/inputs/m1_cf252_gs.in`: the `gefy_sfy` settings (`Fenhance = 100`, energy `0`, `Options(ENDF)`), system `98, 252, "GS"`. Runtime to be measured; estimated under 30 min.

**Done when:** both inputs run to completion with the `seed` build and their runtimes are recorded.

### M1.6 Reference-binary equivalence and promotion (D1)
- [x] For each M1 input: `capture_seed` runs `gef_reference`; `harness.run` runs the `seed` build with the captured seed; `compare_runs` compares the two output trees. The two runs may execute in parallel. Each input gives an independent captured seed.
- [x] Promote the `seed` build to **reference binary `ref-1`**: copy it to `validation/reference_store/binaries/<sha256>/GEF` and write `manifests/reference_binary.json` (patch set, build ID, binary SHA-256, fbc and gcc versions, the two equivalence captures and their seeds).
- [x] Store both capture pairs as reference captures (M1.8).

**Done when:** gate G1 holds for both inputs.

### M1.7 Repeatability and per-event reseed mode
- [x] Repeatability: two `ref-1` runs of `m1_rn215_short.in` with the same seed are byte-identical (masked).
- [x] `harness/RESEED_SPEC.md`: the per-event reseed scheme, written so that M3 can implement it in C++ without reading the patches:
  - scopes: each pre-pass history, each block of the 46 perturbation draws, each event;
  - each scope instance is identified by its tuple of BASIC loop counters (system line, energy step, pass, bin, event, …);
  - derived seed = upper 32 bits of a SplitMix64 chain over (master seed, scope ID, tuple elements), with the exact constants and order written down;
  - on each reseed: `Randomize <derived>,3` and the `PGauss` cache (`Static` `ISet`/`GSet`, `GEF.bas:17956`) is reset.
- [x] Patch `reseed` (active only with `GEF_RESEED=1`) and a Python reference implementation of the derivation (`harness/reseed.py`) with test vectors that M3 reuses.
- [x] With Rnd logging (M1.8), check that in reseed mode **every** draw falls inside a reseeded scope; list any draw site outside one and either add a scope for it or document why it is left out.
- [x] Reseed mode is repeatable: two runs with the same master seed are byte-identical.

**Done when:** gate G2 holds in both modes and the spec has test vectors.

### M1.8 Rnd logging, probes and reference store
- [x] Patch `rndlog` (define `GEF_RNDLOG`): each of the 60 `Rnd` sites is replaced by a wrapper that calls `Rnd` exactly once and, when logging is in scope, appends `(site tag, draw counter, u32)` to `rnd.log`. The site tag is the BASIC `file:line`. The u32 is recovered exactly from the double (`Rnd` = u32 / 2³²).
- [x] Patch `probes` (define `GEF_PROBES`): the first probe set from strategy §2.6:

  | Probe | Location | Captures |
  |---|---|---|
  | T0 | after `GEF.bas:1570` | tables |
  | P1 | after `GEF.bas:3860` | step setup |
  | P2 | after `GEF.bas:4800` | multi-chance pre-pass |
  | P3 | at `GEF.bas:7920`, per bin and pass | per-nucleus model tables |

  Values are written as hex bit patterns (`Single` 8 hex digits, `Double` 16), one value per line with probe ID, variable name (BASIC spelling) and indices, into `probes/<probe>.txt`. Locations are confirmed with `fbline` before patching. The exact variable list per probe is fixed in `harness/PROBES.md`, derived from the code maps and the consumers (M4 for T0, M6 for P1, M9 for P2, M7 for P3).
- [x] Scope selectors (D7) through environment variables (`GEF_TRACE_STEPS`, `GEF_TRACE_PASSES`, `GEF_TRACE_EVENTS`), documented in `harness/README.md`.
- [x] Reference store (D8): `python3 -m harness.store add|verify|list`. A capture holds the run directory, `run.json` and the binary reference. Its committed manifest `manifests/reference_store/<capture-id>.json` lists the seed, mode, patch set, binary SHA-256, input SHA-256 and the SHA-256 of every output file. `verify` reports missing, changed and extra files. Captures are never modified: `add` refuses an existing ID.

**Done when:** gate G3 holds, and the G1/G2 captures are stored and verify.

### M1.9 Minimal statistical check (D5)
- [x] `python3 -m harness.minicheck <ENDF tape> <reference tape> --events N`: parses MF8/MT454 independent yields per energy and computes, per nuclide, the Poisson z-score
  `z = (Y_a − Y_b) / sqrt((Y_a + Y_b) / N)`
  where N is the number of nominal events (Fenhance·10⁵). Nuclides with `(Y_a + Y_b)·N < 20` are excluded. Mass yields are summed per A and tested the same way.
- [x] **Acceptance band, fixed before any `ref-1` run:** z_rms of independent yields and of mass yields ∈ [0.80, 1.50]; ΣIY = 2 within 1×10⁻⁴ at every energy.
- [x] **Three-way rule** (user decision, 2026-10-07). Checking the band on existing BASIC-against-BASIC data (`validation/test_run` tape against the library, 59 energies) showed it fails there too: independent z_rms 0.877–1.434 passes everywhere, but mass z_rms is 0.789 at 5 MeV and 1.582 at 18.5 MeV, the known step-common pre-pass outlier. A single library point can therefore be the outlier. So each `ref-1` tape R is compared with the library tape L **and** with an independent BASIC run T:
  - per energy and metric, PASS if R-vs-L is in the band;
  - otherwise PASS (library fluctuation) only if T-vs-L is also outside the band **and** R-vs-T is inside it;
  - otherwise FAIL.

  T is `validation/test_run/ENDF/GEFY_86_214_n.dat` (last tape) for the Rn-215 input. For Cf-252, which has no recorded independent run, T is a second `ref-1` run with a different seed. For R-vs-T the variance is `Y_r/N_r + Y_t/N_t`, so different event counts are allowed.

  These rules are provisional. M2 replaces them with null-calibrated thresholds and correlation-aware metrics, and `minicheck` is then retired in favour of `compare/`.
- [x] pytest on synthetic tapes: identical tapes give z = 0; a yield scaled by 10 % at high statistics fails; a perturbed library point with unperturbed R and T passes by library fluctuation, while a perturbed R alone fails.

**Done when:** gate G4 holds.

### M1.10 Function-driver framework
- [x] `python3 -m harness.driver build|run <driver>`: compiles a FreeBASIC program from `harness/drivers/` with the pinned fbc and writes its output plus a manifest. Drivers can `#include` table loaders from the source copy and paste function bodies cut by line range (`file:first-last`, recorded in the manifest), so a later milestone can evaluate any function on a grid.
- [x] First driver `rnd_stream.bas`: `Randomize 42,3`, then 10⁶ `Rnd` values written as u32 hex. Stored in the reference store as the first golden file (consumed by M3's `FbMtRng` test).
- [x] Cross-check: the first 1,000 values of `rnd_stream` match an independent Python implementation of the fbc 1.10.1 MT seeding (`hRnd_FillFAST32` + MT19937, from `math_rnd.c`). This proves the golden file and gives M3 a second reference.

**Done when:** gate G5 holds.

### M1.11 CI and documentation
- [x] Fast harness tests run in `scripts/ci.sh` (pytest). Long gates (G1–G4) are scripted (`harness/gates.sh` or equivalent) and run on demand; their results are recorded here.
- [x] `harness/README.md`: build, run, capture, store, driver and minicheck usage; patch-set list; environment variables; masks.
- [x] `CODING_STANDARDS.md`: add FreeBASIC driver and patch conventions.

### M1.12 Close-out
- [x] `QUIRKS.md`: update B-003 (handled for harness builds) and upgrade any entry whose evidence the new probes or runs now confirm (for example Q-007 stale `Z`, Q-008 mode-7 leak, Q-026 append behaviour). This is opportunistic, not a gate.
- [x] `COVERAGE_MATRIX.md`: no cell closes in M1 (it builds the oracle, not the port); record that.
- [x] Update `IMPLEMENTATION_STRATEGY.md` where this plan changed it: D1 (byte-exact reference equivalence instead of statistical), D4, D5.
- [x] Update `CURRENT_PROJECT_STATE.md` and mark this plan complete.

## 5. Exit gate (all must hold)

| Gate | Requirement |
|---|---|
| G1 Reference equivalence | For `m1_rn215_short.in` and `m1_cf252_gs.in`, the `seed` build run with the seed captured from `gef_reference` produces output byte-identical to `gef_reference`'s run, with only `masks.toml` fields masked. The `seed` build is promoted to `ref-1` |
| G2 Repeatability | Two `ref-1` runs with the same seed are byte-identical (masked), in normal mode and in reseed mode |
| G3 Neutrality | With the same seed, builds with `probes`, `rndlog` and both together produce `run.log`, `out/`, `dmp/`, `ENDF/` and `tmp/` byte-identical to `ref-1` (masked), in normal mode and in reseed mode, with probes and logging in scope for at least one energy step with second-chance fission (18.5 MeV) |
| G4 Minimal statistics | `ref-1` outputs for both M1 inputs pass the §4.9 three-way rule against `validation/reference/gefy_nfy_ENDF/GEFY_86_214_n.dat` and `gefy_sfy_ENDF/GEFY_98_252_s.dat` at every energy of the run |
| G5 First golden file | `rnd_stream` (seed 42, 10⁶ values) is stored with a manifest, reproduces bit-identically on rebuild, and agrees with the Python MT reference |
| G6 Store integrity | All captures used for G1–G5 are in the reference store, their manifests are committed, and `harness.store verify` passes |
| G7 CI | `scripts/ci.sh` passes with the harness tests included |

## 6. Out of scope (later milestones)

- The comparison toolkit, null calibration and correlation-aware metrics (M2). `minicheck` is a stopgap.
- Probes beyond T0, P1, P2 and P3 (per-event records, post-pass, writer-entry snapshots): added by the milestones that consume them (M10–M13), with the framework built here.
- Any C++ code, including the C++ side of the reseed scheme (M3).
- Full 59-energy or full-library BASIC runs. They are not needed for M1 (D4).
- The `T0` hex dumps' comparison against C++ tables (M4).

## 7. Risks and open questions

| Item | Handling |
|---|---|
| Output depends on something besides seed and input (absolute paths, environment, ASLR under gdb vs. without) | Same-path working directories (M1.3). If G1 still differs, triage from the first differing line; run both sides under the same conditions (e.g. both under gdb) to isolate the cause |
| An incomplete mask list hides a real difference, or a missing mask fails G1 | Masks are derived by enumerating time sources before G1 and each names its BASIC location. `compare_runs` reports unused masks |
| `hRndCtxInitMTWIST32` is reached on a path other than `GEF.bas:1553` | The capture checks the `fb_Randomize` arguments and stops if the init is hit more than once |
| Patches change behaviour beyond their intent (e.g. by shifting the `Rnd` call order in an expression) | `emit_c` diff of the generated C for every patch set; G3 neutrality |
| Some draws in reseed mode fall outside any reseeded scope | M1.7 Rnd-log check. Each case is resolved or documented before G2 |
| The GS runtime is longer than estimated | Measured in M1.5. If needed the GS case moves to a lighter `GS` system from `gefy_sfy`, still at `Fenhance = 100` (D4) |
| `minicheck` thresholds are too loose or too tight | Provisional by design (D5). The band was checked against BASIC-against-BASIC data before use and failed there, which led to the three-way rule (§4.9). A failure is triaged and recorded, not silently re-tuned; M2 sets the real thresholds |

## 8. Completion notes

Started and closed 2026-10-07. The gate runs are stored in the reference store (18 entries, `manifests/reference_store/`); the reusable gate driver is `harness/gates.sh`.

**Exit gate.**

| Gate | Result |
|---|---|
| G1 | **Pass.** Seeds captured from `gef_reference` under gdb: 1776849192 (`m1_rn215_short`) and 1776917293 (`m1_cf252_gs`). In each capture `fb_Randomize` was called once with `(-1.0, 3)` and the MT initialiser was hit once. Replaying them with the `seed` build gave IDENTICAL output for 244 and 42 files, masking only `compile_stamp`, `progress_time`, `dmp_written`, `mvd_written`, `out_written`, `thread_timeoffset` and `update_written`. The `seed` build (sha256 `8f0f2ff8…6043`, build `seed-5d9886c955fa`) is promoted to **`ref-1`**: `manifests/reference_binary.json`, stored binary `binary-8f0f2ff8dccd`. Captures `m1-g1-{rn215,cf252}-{gefref,ref1}` |
| G2 | **Pass.** Two `ref-1` runs of `m1_rn215_short` with seed 20261007 are IDENTICAL (244 files), and so are two `seed-reseed` runs in reseed mode |
| G3 | **Pass.** All seven neutrality comparisons are IDENTICAL on 244 files: `seed-probes`, `seed-rndlog`, `seed-rndlog-probes` and `seed-reseed` without `GEF_RESEED` against `ref-1`, and `seed-reseed-probes`, `seed-reseed-rndlog`, `seed-reseed-rndlog-probes` against `seed-reseed` in reseed mode. Tracing covered steps 2 (30 MeV, nominal only: 31 P3 records, one per bin) and 8 (18.5 MeV: 1 bin, P3 in passes 0 and 31), events 1–20: 118 MB of probes and 18.9 M logged draws per run. In reseed mode `rndlog scopes` found 0 draws outside a scope (632,456 pre-pass histories, 1 perturbation block, 800 events), with every seed and per-scope stream checked against `reseed.py`/`fbmt.py`. Reseed mode differs from normal mode in 221 of 244 files, as intended |
| G4 | **Pass with a recorded exception** (user decision, 2026-10-07). Cf-252 passes; the third tape is an independent `ref-1` run with seed 20261008, `m1-g4-cf252-ref1-independent`. Rn-215 passes at 7 of 8 energies. At 18.5 MeV R-vs-library is 2.47 (independent) and 2.94 (mass), and R-vs-`test_run` is 2.64, so the three-way rescue does not apply. Triage: the pre-pass derives the chance split from only 15 fissions, 0 of which were second-chance in this run, so the output says "Probability of first-chance fission: 100%". `test_run` had 1 of 17 (5.9 %). The k/15 quantisation shifts every yield at that energy together, which is BASIC's own step-common noise: `ref-1` is byte-identical to `gef_reference` (G1). Handed to M2 as a required null-calibration point (strategy M2, "Proven by") |
| G5 | **Pass.** `rnd_stream` seed 42 × 10⁶ has sha256 `2ac2ac5a…868b`, is identical after a rebuild and equals `harness.fbmt` for all 10⁶ values. Stored as `m1-golden-rnd-stream-42` |
| G6 | **Pass.** `python3 -m harness.store verify`: 18 entries OK |
| G7 | **Pass.** `scripts/ci.sh` passes (it now also runs `harness.store verify`) |

**Runtimes.** The machine was shared by up to 13 GEF processes, so wall times are not single-run figures.
- Builds: about 9 s each.
- `m1_rn215_short`: capture 26 min, replay 40 min, 11 parallel G2/G3 runs 46 min.
- `m1_cf252_gs`: capture 18 min, replay 39 min, independent run 18 min.

**Deviations from the plan.**
- **Same-path working directories (M1.3)** were not needed. The time-source enumeration found no `CurDir`, `ExePath`, `Command` or `Environ` anywhere in GEF, so no output depends on the run directory.
- **The mask list** has 12 entries, from enumerating every clock source (`Now` via `Rdatetime`, `Timer`, `__DATE_ISO__`/`__TIME__`). 7 matched in the M1 runs; 5 belong to lmd, fit and plot output.
- **`tmp/*.par` prints an `Rdatetime` that is never assigned** (always `30.12.1899, 00:00:00`). It is left unmasked on purpose.
- **GEF reads no environment variable or terminal size**, so gdb's `LINES`/`COLUMNS` cannot affect the capture.
- **`capture_seed` keeps the MT-init breakpoint** armed as a non-stopping counter for the whole run, so a second initialisation would fail the capture. The plan said to delete all breakpoints after the capture.
- **Probe placement:** P1 sits at `GEF.bas:3881/3882`, because 3860 is the `Else` of a warning. `Eexc_min_multi` is set after P1 and is therefore dumped in P2. Probe lines carry a `rec=` invocation counter, and arrays have bounds records. T0 includes BranchData by running a marked copy of the `Branchings.bas` loader into private arrays (neutrality confirmed by G3).
- **Reseed scopes:** pre-pass history (reseeded at `GEF.bas:4241`), perturbation block (5112–5160) and event (7926–9997). The `PGauss` cache reset is confirmed in the generated C; no run-level test can show it.
- **`compare_runs --allow-only-in-b`** was added so the harness outputs (`work/probes/*`, `work/rnd.log`) of probed builds are listed but do not count as differences.
- **G4 three-way rule:** the user decided this before any `ref-1` run, after the band failed on BASIC-against-BASIC data (§4.9).
- **`tools.fbsrc.emit_c`** now resolves `--patch-dir` to an absolute path (`patch -d` needs it).
