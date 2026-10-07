<!--
SPDX-License-Identifier: GPL-3.0-or-later
Copyright (C) 2026 Aurora Jahan
Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
-->

# Per-scope reseed mode (`GEF_RESEED=1`)

GEF draws all its random numbers from one global Mersenne Twister stream. In **reseed mode** the generator is re-initialised at the start of every *scope instance* (one pre-pass history, one block of perturbation draws, one event) from a seed derived from the master seed and the BASIC loop counters of that instance. Each scope instance then has its own random stream, independent of how many draws the instances before it took. That makes single events reproducible, lets the C++ port be compared event by event, and lets runs be split or reordered.

Reseed mode **deliberately changes the random stream** relative to normal mode (decision D6). It is a separate mode with its own repeatability proof; it is not covered by the neutrality proof against normal mode. This document is the contract the C++ port (M3) implements. It does not need the patches.

Files: patch `harness/patches/reseed.patch` (`harness_reseed.bi`), reference implementation `harness/reseed.py`, log check `python3 -m harness.rndlog scopes`, tests `harness/tests/test_reseed.py`.

## 1. Activation

| Environment | Meaning |
|---|---|
| `GEF_RESEED` unset or empty | Inert. No draw, no output and no state of GEF changes (checked, section 7) |
| `GEF_RESEED=1` | Reseed mode. The master seed is `GEF_SEED` (decimal integer 0 to 4294967295, required by the `seed` patch as before) |
| anything else | Error message on stdout, exit code 2, before any computation |

## 2. The random generator

`Randomize s, 3` (s = 32-bit seed) is fbc 1.10.1's `hRndCtxInitMTWIST32((uint32_t)s)`: the 624-word state is `state[0] = s`, `state[i] = state[i-1] * 1664525 + 1013904223 (mod 2^32)`, and the first draw twists the state. It **replaces the complete generator state**; nothing of the previous stream survives. `Rnd` is `u32 / 2^32`. `harness/fbmt.py` (`FbMtRng(s)`) is the Python reference. The C++ port needs exactly this generator, seeded this way.

## 3. Seed derivation

All arithmetic is on unsigned 64-bit integers, modulo 2^64.

```
splitmix64(x):
    x = x + 0x9E3779B97F4A7C15
    z = x
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB
    return z ^ (z >> 31)

derive_seed(master, scope_id, t[0], ..., t[n-1]):
    h = splitmix64(master)                   # master = GEF_SEED, zero-extended
    h = splitmix64(h ^ uint64(scope_id))
    for v in t[0], ..., t[n-1]:              # in the order of section 4
        h = splitmix64(h ^ uint64(v))        # v signed 64-bit, taken as two's complement
    return h >> 32                           # upper 32 bits, 0 .. 2^32 - 1
```

- `uint64(v)` of a negative `v` is `v + 2^64` (the C cast `(uint64_t)(int64_t)v`). GEF's counters are never negative; the rule is fixed so that the vectors below cover it.
- The scope ID is hashed first, then the tuple elements in the stated order. The tuple length is fixed per scope (section 4); it is part of the identity and is not hashed separately.
- On every reseed GEF executes `Randomize derive_seed(...), 3` and **resets the `PGauss` cache**: `PGauss` (`GEF.bas:17956`) is a Marsaglia polar sampler with `Static ISet` / `GSet`; every second call returns the stored `GSet` without a draw. After a reseed `ISet` is 0, so the next `PGauss` call draws. (The patch sets a flag that `PGauss` checks on entry.) A C++ sampler that keeps a cached second value must clear it on every reseed.
- The global draw counter used in `rnd.log` is not reset; it counts all draws of the program.

Reference: `harness.reseed.derive_seed(master, scope_id, *tuple)`. The BASIC implementation (`Harness_DeriveSeed` in `harness_reseed.bi`) is checked against the vectors in section 6 by `test_basic_derivation_reproduces_the_vectors`, which compiles it with the pinned fbc.

## 4. Scopes

Counters are the BASIC variables of the same name in `GEF.bas`, converted to signed 64-bit integers. "Starts" is the point at which the reseed is executed; the scope runs until the next scope starts or its end marker (the closing statement named below).

### Scope 1: multi-chance pre-pass history

| | |
|---|---|
| ID | 1 |
| Reseed at | the top of each iteration of `Do Until Imulti >= N_multi_sample` (`GEF.bas:4241`), before the first statement of the history (before the `Dice_I_Estep` draws of `Emode = 13`) |
| Ends | the `Loop` at `GEF.bas:4707` (end of the last history) |
| Tuple | `Ifilein, Iline, I_Double_Covar, I_E_step, K` |
| Notes | `K` is the 0-based history index within this pre-pass (set to 0 at `GEF.bas:4239`, incremented at the end of each history at 4689). The pre-pass runs once per energy step and is shared by all passes of that step. The loop always runs exactly `N_multi_sample` histories. The retries inside a history (`Goto Dice_I_Estep`, `Goto REnkin`, ...) continue the same stream |

### Scope 2: perturbation block

| | |
|---|---|
| ID | 2 |
| Reseed at | immediately before the first `PGauss` of the 46-draw block (`GEF.bas:5112`, `P_DZ_Mean_S1 = PGauss(...)`) |
| Ends | after `Jscaling = PGauss(...)` (`GEF.bas:5160`) |
| Tuple | `Ifilein, Iline, I_Double_Covar, I_E_step, I_Error` |
| Notes | Executed once per perturbed pass, only if `B_Error_Analysis = 1` and `(B_Fit = 0 And I_Double_Covar = 1)` (or a new fit parameter set). `I_Error` is the 0-based pass number. The block calls `PGauss` 46 times (about 57 uniform draws including rejections) |

### Scope 3: event

| | |
|---|---|
| ID | 3 |
| Reseed at | the first statement of each iteration of `For ILoop = 1 To NEVTused` (`GEF.bas:7922`), before the fission-mode draw of `GEF.bas:7931` |
| Ends | `Next ILoop` (`GEF.bas:9997`) |
| Tuple | `Ifilein, Iline, I_Double_Covar, I_E_step, I_Error, I_E_Distr, I_N_Multi, I_Z_Multi, I_E_Multi, ILoop` |
| Notes | `ILoop` is 1-based within the bin; the bin is identified by `I_E_Distr, I_N_Multi, I_Z_Multi, I_E_Multi` (the loops at `GEF.bas:5522-5531`; `I_E_Multi` counts down from `N_E_Multi`; all three multi-chance indices are 0 when there is no multi-chance bin). A retry inside an event (`J_attempt`, rejection loops) continues the same stream |

Tuple counters:

| Name | Loop (`GEF.bas`) | Range / base |
|---|---|---|
| `Ifilein` | `For Ifilein = 1 To Max(Nfilein,1)` (2768) | 1-based index of the sequence file in `file.in` |
| `Iline` | `For Iline = 1 To Iline_tot` (3141) | 1-based index of the system line (including skipped lines) |
| `I_Double_Covar` | `For I_Double_Covar = 1 To N_Double_Covar` (3294) | 1, or 1 and 2 |
| `I_E_step` | `For I_E_step = 1 To N_E_steps` (3442) | 1-based energy step |
| `I_Error` | `I_Error = 0` at the top of each step, then `+1` per pass (`calcstart`, 4811) | 0-based pass: `0 .. N_Error_Max - 1` are perturbed passes, `N_Error_Max` is the nominal pass; 0 when there is no error analysis |
| `I_E_Distr` | `For I_E_Distr = 1 To N_E_distr` (5522) | 1-based |
| `I_N_Multi`, `I_Z_Multi` | (5526, 5527) | 0 .. 10 (0 without multi-chance) |
| `I_E_Multi` | (5531) | `N_E_Multi .. 0` step -1, `N_E_Multi = 1000` with multi-chance, else 0 |

The tuple lists are repeated in code form as `harness.reseed.TUPLE_FIELDS`:

| Scope | Tuple, in hashing order |
|---|---|
| 1 | Ifilein, Iline, I_Double_Covar, I_E_step, K |
| 2 | Ifilein, Iline, I_Double_Covar, I_E_step, I_Error |
| 3 | Ifilein, Iline, I_Double_Covar, I_E_step, I_Error, I_E_Distr, I_N_Multi, I_Z_Multi, I_E_Multi, ILoop |

## 5. Completeness: every draw is inside a scope

Static check. Every `Rnd` of GEF lives in `GEF.bas` (no other source file contains `Rnd` or `Randomize` outside comments). The 60 sites (`RNDLOG.md`) are reached only from:

| Sites | Reached from | Scope |
|---|---|---|
| 4245, 4247 | module level inside the history loop, `Emode = 13` | 1 |
| 4420-4651 and the samplers they call (`P_Egamma_high` 4428, `PPower_Griffin_v` 4567/4587, `PMaxwell` 4616, `PMaxwellMod` 4645) | the history loop body | 1 |
| 7931-9839 and the callees (`PGauss`, `PBox2`, `PLinGauss`, `Eva` at 8123/8146/8900/9055 with `P_Egamma_high`, `PMaxwellMod`, `PExp`, `P_Egamma_low` at 9282/9401) | the event loop body | 3 |
| `PGauss` 5112-5160 | the perturbation block | 2 |
| 17882 (`PBox`), 17927 (`PPower`), 17950 and 17952 (`PPower_Griffin_E`), 18034 (`PMaxwellv`, 2 draws) | functions without a caller (dead code) | none needed |
| 17568, 17572 (`Pexplim`) | only `E_next` (17518-17528), which has no caller | none needed |

Dynamic check (`python3 -m harness.rndlog scopes <rnd.log> --master N --streams`): the `rndlog` build, in reseed mode, writes a marker line when each scope starts and ends (format in `RNDLOG.md`). A draw is *inside* when a `B` marker precedes it and no later `B` or `E` marker lies between them. The command lists draws that are not inside, checks the seed of every `B` marker against `derive_seed`, and (`--streams`) checks that the draws of each scope instance are exactly `FbMtRng(seed)` output 1, 2, 3, ... with consecutive counters.

Result (build `seed-reseed-rndlog` with `-d GEF_RNDLOG`, `GEF_RESEED=1`, `GEF_SEED=42`, every step and pass selected, events 1 to 100 of every bin; `harness/inputs/m1_rn215_short.in` with `Fenhance` 2, i.e. Rn-215 at 0.0253 eV, 2, 7, 13, 14.5, 18.5, 22 and 30 MeV with `Options(ENDF)`, 29 773 504 draws, 0.99 GB):

| Scope | Instances | Draws | Sites |
|---|---|---|---|
| 1 pre-pass history | 848 526 | 22 673 458 | 17 |
| 2 perturbation block | 112 (8 energies x 14 perturbed passes) | 6 548 | 2 (17963, 17964) |
| 3 event | 38 472 | 7 093 498 | 22 |
| **outside any scope** | | **0** | |

All seeds equal `derive_seed(42, ...)` and all draws of every instance equal the `FbMtRng(seed)` stream (`--streams`, no problem reported). The same check gave 0 draws outside scopes for `Fenhance` 1 at 18.5 MeV with and without `Options(ENDF)` (100 000 histories, 10 perturbation blocks, 11 passes of 20 events) and for Cf-252 `GS` (`Fenhance` 1, 10 perturbation blocks, 3 300 events).

The sites that drew in these runs are 34 of the 56 distinct `Rnd` lines. Those that did not are all positioned inside a scope (table above): 4245 and 4247 (`Emode = 13` only, history loop), 9680, 9719 and 9769 to 9839 (CN-frame kinematics, event loop; not reached by these inputs), the lines of functions without callers (17568, 17572, 17882, 17927, 17950, 17952, 18034, section 5) and 17914 (`PBox2`, a branch that did not fire). Draws outside scopes are therefore not expected in any input; there is nothing left outside a scope to document. The code between scopes (the bin set-up between two event loops, the statements between the pre-pass and `calcstart`, the output code) contains no `Rnd`. It still runs with whatever generator state the last scope left; since it draws nothing, it does not depend on it.

## 6. Test vectors

`harness/tests/test_reseed.py` checks both tables against `harness/reseed.py` and the BASIC implementation. Tuple elements are in hashing order; the vectors use tuples of any length (the first rows are not valid GEF scopes).

SplitMix64 (state in, output):

| State | Output |
|---|---|
| `0x0000000000000000` | `0xE220A8397B1DCDAF` |
| `0x0000000000000001` | `0x910A2DEC89025CC1` |
| `0x0000000000000002` | `0x975835DE1C9756CE` |
| `0x123456789ABCDEF0` | `0x161922C645CE50E8` |
| `0xFFFFFFFFFFFFFFFF` | `0xE4D971771B652C20` |

`derive_seed` (`-` is the empty tuple):

| Master | Scope | Tuple | Seed |
|---|---|---|---|
| 0 | 1 | - | 146079144 |
| 0 | 1 | 0 0 0 0 0 | 3023585711 |
| 1 | 3 | 1 1 0 1 0 0 0 0 0 1 | 1149470725 |
| 42 | 3 | 1 1 1 1 0 1 0 0 1000 1 | 2490878954 |
| 42 | 3 | 1 1 1 1 0 1 0 0 1000 2 | 4268762869 |
| 4294967295 | 3 | 1 1 1 1 0 1 0 0 1000 316228 | 70534132 |
| 4294967295 | 2 | 1 1 1 1 31 | 1098892256 |
| 12345 | 1 | 1 1 1 1 0 | 4271272159 |
| 12345 | 1 | 1 1 1 1 316227 | 237973617 |
| 12345 | 3 | -1 -2 -3 -4 -5 -6 -7 -8 -9 -10 | 2360404655 |
| 2147483648 | 1 | -9223372036854775808 9223372036854775807 0 1 -1 | 824028776 |
| 987654321 | 2 | 2 7 1 4 12 | 2980720164 |
| 7 | 3 | - | 1806334056 |
| 0 | 3 | 1099511627776 -1099511627776 | 1991928469 |

Stream check for the C++ port: `Randomize 2490878954, 3` then `Rnd` gives the first draw of event 1 of bin (1, 0, 0, 1000) for master 42 and tuple `1 1 1 1 0 1 0 0 1000 1`; `FbMtRng(seed).next_u32()` gives its 32-bit value.

## 7. Evidence

Inputs (not committed, built in `build/reseed_m17/`): `rn215_thermal.in` is `m1_rn215_short.in` with the single energy `0.0253E-6` (`Fenhance 10`, `Options(ENDF)`, `86, 215, "EN"`); the coverage inputs are described in section 5.

| Check | Runs (seed 42) | Result |
|---|---|---|
| (a) inert neutrality | `seed` build against `seed-reseed` build, no `GEF_RESEED`, `rn215_thermal.in` | `harness.compare_runs`: IDENTICAL, 41 files, 0 differ |
| (a') inert with logging | `seed-rndlog` against `seed-reseed-rndlog` (`-d GEF_RNDLOG`), no `GEF_RESEED`, 18.5 MeV, steps 1, passes 0-3, events 1-5 | `compare_runs` IDENTICAL (42 files) and the two `rnd.log` (77 MB) are byte-identical (`cmp`) |
| (b) repeatability | two `seed-reseed` runs with `GEF_RESEED=1`, same input and seed | IDENTICAL, 41 files, 0 differ |
| (c) mode changes the stream | `seed` run against `GEF_RESEED=1` run | DIFFERENT, 29 of 41 files differ (first: `tmp/..._Single.mvd` line 16) |
| (d) per-scope locality | all scopes of the coverage runs, and independently for events 1, 7, 20 of pass 0 and event 5 of pass 10 (`I_Error = 10`, nominal) of the 18.5 MeV run | the draws of each scope instance are the first 1, 2, 3, ... outputs of `FbMtRng(derive_seed(42, scope, tuple))` (1137, 87, 427 and 163 draws, all equal) |

Generated C (`emit_c`, patch set `seed`, `scope`, `reseed`): `HARNESS_SPLITMIX64`/`HARNESS_DERIVESEED` use `uint64` operations (the xor with `(uint64)ISCOPE`, `uint64` multiplication that wraps by definition); `PGauss` gains `if( HARNESS_PGAUSSRESET != 0 ) { ISET = 0; HARNESS_PGAUSSRESET = 0; }` after the `static float GSET`. The patch keeps the line numbering of `GEF.bas` (changed lines 1555, 4241, 4707, 5112, 5160, 7926, 9997, 17960, test `test_reseed_keeps_line_numbers_and_touches_only_its_sites`). The reseed code runs `Harness_Reseed` at each scope start also in normal mode; it returns at once when `Harness_ReseedOn = 0`.
