# Milestone 6: Input Parsing, Run Planning and System/Step Setup

**Status:** planned (2026-10-14)
**Strategy reference:** `IMPLEMENTATION_STRATEGY.md` §1.2, §2.1, §2.4, §2.9 and §3, M6
**Depends on:** M1 (probes P1, runner, reference store, `harness.golden`), M3 (`fb::PrintFile`, `fb::str`, `fb::val`, `fb::InputFile`, `fb::trim/ucase/instr/mid`, conversions, `fb::Array`), M4 (`TableSet`, `Parameters` with `load_parameters_bas`, `PerturbationWidths` with `update_widths`, `fitpar_read`, `MatNumberState` with `i_mat_endf`/`n_iso_mat`, `util::cc_count`/`cc_cut`), M5 (`U_Valid`, `BFTF`/`BFTFA`/`BFTFB`, `AME2020`, `LyMass`, `U_SHELL`, `U_SHELL_exp`; `Round` from M3)
**Unblocks:** M7 (per-step CN values that the bin loops start from), M9 (`StepState`: `Eabsgs`, `Spin_CN`, the spectrum tables, `Eexc_min_multi`, the pre-pass decision, `N_multi_sample`), M12 (pass schedule, `B_Error_On`, the per-system parameter reset), M13 (file names, the lmd name, `B_ENDF`/`Brec`/`I_first_E_step`), M14 (the run driver), M16 (the fit-loop back edge)

## 1. Goal

C++ reads GEF's batch inputs and goes through GEF's run control exactly as BASIC does: the same files, systems, energy steps and passes, in the same order, with the same per-system and per-step setup values (excitation energy, spins, kinematics, names, thresholds) and the same console text. After M6, C++ knows what BASIC would compute, and in what order (strategy, M6 exit). Pre-pass, passes and events are what later milestones hang onto the step body that M6 leaves empty.

## 2. Decisions taken in this plan

| ID | Topic | Decision | Reason |
|---|---|---|---|
| D1 | BASIC oracle | (a) Extend the `probes` patch with **P0** (each parsed sequence file) and **P1b** (the multi-chance threshold, the pre-pass decision, `Fenhance` after `GEF.bas:3922`, `N_multi_sample`). (b) New patch `setup` (`-d GEF_SETUP_ONLY`): after P1b, jump to the end of the energy step, so pre-pass, passes, events and writers do not run. Patch set `m6-setup`. (c) A few full-run captures at `Fenhance` 1 (§5 M6.0), plus the existing `m4-p1-rn215` and `m4-p1-fitpar`, show which P1 values the skipped code changes and that it changes no other | User decision (2026-10-14), option D. Full runs of the corpus take days (`NFred.in` ≈ 50 h, `Jeremi2.in` ≈ a day, fit files never end; §4). With the setup patch every input takes seconds |
| D2 | `ctl/done.ctl` | Kept as an in-process list in `ProcessState`. Records are formatted with `fb::PrintFile` exactly as `GEF.bas:3217` prints them, read back with `fb::InputFile` into `Single`/`Integer` as at 3180, and compared as the emitted C does (`GEF.c:40715-40731`). Skipped when `B_Fit = 1`. A record is added before the system is computed. The run starts with an empty list (a clean working directory). History from earlier runs in the same directory goes with Q-026 (M13/M14) | User decision (2026-10-14), option A. Within one clean run the list decides which repeated lines are skipped, and it is what ends the missing-isomer restart (§4) |
| D3 | Console | Byte-exact for the batch code M6 ports. One `fb::PrintFile` per process stands for stdout (the column state carries across statements, e.g. `GEF.bas:3593-3600`). Lines of M4/M5 functions that return `std::vector<std::string>` are appended to it line by line. Not reproduced: the banner, folder creation, the thread-assignment messages (`GEF.bas:1832-1905`), the dialogue, GUI and plotting, wall-clock lines. `I_thread` is the constant 1 of a clean run (`GEF.bas:2718`). Compared from the first line printed at or after `Nextfitloop:` (`GEF.bas:2519`) to the end of the run (`GEF.bas:15665-15666`) | User decision (2026-10-14), option B. Byte equality implies the strategy's "printed digits"; the `Print` emulation exists (M3); M4 already compared console blocks this way. The strategy's M6 wording is amended |
| D4 | Fit-mode inputs | M6 parses `FIT`, `NITER` and `MODE`, keeps `B_Fit`, `N_iter` and `C_Fitoption` across files as BASIC does, applies the fit-mode branches of the M6 code (no parameter reset at 3317, no `done.ctl` check at 3174, `LOCAL` refused at 3324, `N_Error_Max = 1` at 5062) and covers fit iteration 1. The back edge at `GEF.bas:15597-15612` is an explicit driver result that M16 implements; until then the C++ ends there as `NITER(1)` does. BASIC captures of fit files add a `NITER(1)` line to `file.in` | User decision (2026-10-14), option A. 152 of 174 corpus files are fit files; without `NITER` BASIC never ends (§4) |
| D5 | Control flow | `run::RunDriver`, a state machine over BASIC's batch loops: input round (`Nextfitloop`) → file → system line → covariance system → energy step → pass schedule. It reproduces `Goto Next_Iline_label` (3384), `Goto RepeatInput` (3567) and `End` (§4). `next_step()` returns the next `StepPlan` (the step's setup and its pass schedule), the end of the run, or the fit back edge. The caller runs the step body (M9–M13) and asks again. **The run plan as data** is the sequence of `StepPlan`s from driving it with an empty step body, which is what the `setup` patch does to BASIC | Setup values of later steps depend on what earlier step bodies write (Q-candidates of §4), so a plan computed fully in advance would be wrong; a driver that yields per step is exact and still gives the plan as data |
| D6 | State | The strategy §2.4 scopes, refined: `ProcessState` (tables, the single `Parameters`, `PerturbationWidths`, `MatNumberState`, the done list, the console, options that survive the per-file reset, and every value a step body writes that later setup reads); new **`InputRoundState`** (reset at `Nextfitloop`, i.e. per fit iteration and per restart: the file list, `Energy_Table`, `Spin_Table`, `N_E_values`, the spectrum arrays, `GEF.bas:2647-2684`); `SequenceFileState` (the parse and the per-file reset of 2827-2842); `SystemState` (CN, names); `StepState` (energy, kinematics, spins, spectrum normalisation, threshold). `Parameters` stays **one** object in `ProcessState`; the per-system reset is `load_parameters_bas` on it (refines M4 D9) | `Parameters.bas` overwrites only its own variables; `Emode`, `EOscale`, `D_Par_Fac`, `BFC` and the other members of `Parameters` keep their values across systems, so one object reproduces BASIC and a per-system copy would not. `Nextfitloop` is a reset point the strategy table did not list |
| D7 | Files and directories | All file access goes through `run::WorkDir` (a root path; `read(rel)` returns the bytes or `nullopt`, with `params::read_input_file`'s semantics). No `chdir`. `ctl/IMATmax.ctl` and `done.ctl` live in `ProcessState` (D2, M4 `MatNumberState`); writing `ctl/` files to disk is M14's | BASIC's `CHDIR("ctl")`/`CHDIR("..")` (3175, 3214, `NucProp_Functions.mac:37`) changes process state; the run must not |
| D8 | `End`, hangs, `Sleep` | A BASIC `End` becomes a `RunEnd` result after its text has been printed; outputs of earlier systems stay valid. A path where BASIC never returns throws `params::GefHangs` (Q-035 precedent). `Sleep` prints nothing and returns (M6.0 establishes what it does with the harness's `/dev/null` stdin) | Same shape as M4's `GefStopped`/`GefHangs` |
| D9 | Nuclide data | JEFF-3.3 only | M4 D4 and M5 D6: the other variants are certified at T0/T1 in M4; M6 adds no variant-specific code |
| D10 | Unreachable branches | Ported as a `throw std::logic_error` with a comment giving the proof, e.g. `GEF.bas:3472-3474` (`N_E_steps = 2` without `RANDOM` cannot occur; the branch reads `Energy_table(I)` with the local `I` of 3171) | Keeps the port line-for-line without inventing behaviour |
| D11 | Layout | `Cpp_implementation/src/run/`, CMake target `gef_run`, namespace `gef::run`: `state.hpp`, `input_files.{hpp,cpp}` (file.in and sequence files), `driver.{hpp,cpp}` (D5, done list, schedules), `system_setup.{hpp,cpp}`, `step_setup.{hpp,cpp}`, `workdir.{hpp,cpp}`. Tests `Cpp_implementation/tests/run_<part>_test.cpp`, tagged `[run][T1]`; probe writers for P0/P1/P1b in `tests/support/` | Strategy §2.8 (`run/`); coding standards §2.1 |
| D12 | Test data | As M4 D7 and M5 D9: P0/P1/P1b fingerprints and console SHA-256 per capture committed with `harness.golden`; full dumps in the store; tests that need the store or `validation/` skip without them. The corpus and edge inputs are listed in a committed manifest (`harness/inputs/m6/corpus.toml`) that the harness and the C++ tests both read | Same rule as M3–M5 |
| D13 | Types, arithmetic, presets | As M5 D10 and D11: BASIC types (`Single` → `float`, `Integer` → `std::int64_t`, `Byte`/`UByte` as declared), arithmetic from the `fbline` output, conversions through `fb::f2l` etc.; every T1 test in `dev-gcc`, `dev-clang` and `release-exact`; NaN sign and payload excepted (B-001) | Coding standards §2.4, §5 |

## 3. Scope inventory

Line ranges are `GEF.bas` at `ba9f0aa` unless another file is named.

| Region | Content | M6 part |
|---|---|---|
| 1735-1772, 2647-2684 | Declarations and initial values of the run-control variables (`Static`/`Dim` at module level) | Fields and defaults of the D6 scopes; `Nfilein = 0`, `Redim Energy_Table(1)`, `N_E_values = 1`, the spectrum `Redim`s re-run at every pass through `Nextfitloop` |
| 2515-2570 | `Chisqr_Fit_min`, `I_Fitloop`, `Nextfitloop`, `FitparRead` (2555) | Calls M4 `fitpar_read`; the fit-only block 2526-2554 (Fitlog, FitparWrite) is M16's |
| 2575-2639 | `Var_*` widths, `Clocal`, the non-batch block | Calls M4 `update_widths` on every pass through `Nextfitloop` (Q-019 makes the result depend on the `PZ_S3_olap_curv` working copy) |
| 2699-2763 | `file.in`: list of files, `FIT`, `NITER(n)`, `END`, comments, at most 1000 entries | Parser |
| 2768-3133 | Sequence files: `Fenhance`, the energy line (`k:` prefix, `E/spin`, quoted spectrum file), the per-file reset, `Options(...)` (all keywords), `FIT(...)`, `NITER(...)`, `MODE(...)`, `END`, 3-field lines with A ranges, 6-field lines, the fatal checks | Parser and `SequenceFileState` |
| 3138-3285 | Per system line: covariance pair, `done.ctl`, `U_Valid` skip, `Emode`/`N_E_steps`/`I_E_iso` from the entrance channel | Driver |
| 3287-3440 | Per covariance system: `Clocal`, the `Parameters.bas` reset (3320), the local-parameter stub, the barrier and mass printout with `BFC`, the unbound-CN skip, `CFileout` | `system_setup` |
| 3442-3540 | Per step: energy and `B_Error_On` schedule, `Csystem`, the frozen lmd name | Driver and `step_setup`; `CLEARerrors.bas` (3446) marks where `StepState` starts, its arrays are M12's |
| 3542-3880 | Isomer energy, CN line, spectrum reader and normalisation, `Fenhance`, `Spin_CN`, `Spin_target`, `Eabsgs`, `Bprot`, `Balpha`, range checks, "Please wait" | `step_setup` |
| 3922, 3926, 3947-3972 | `Fenhance = 0 → 1`, `N_multi_sample`, the threshold `Eexc_min_multi` and the pre-pass decision (`Bmulti`) | `step_setup` (the decision only; the pre-pass is M9's) |
| 4805-4811, 5055-5091, 15527-15551 | `B_Error_Analysis`, `Chisqr_min`, the pass schedule (`N_Error_Max`, `NEVTtot`, `I_Error`), the pass header lines, the `GoTo calcstart` loop | Driver (pass schedule and headers) |
| 15581-15612, 15613-15669 | Loop ends, `Next_Iline_label`, the fit back edge, the batch exit text | Driver |

**Not in M6:** clearing the CN spectra and the pre-pass arrays (3882-3945) and the pre-pass itself (3973-4800, M9); `CLEARspectra`, the lmd header (4816-5050, M10/M15); parameter perturbation and `.par` (5095-5435, M12); the bin loops and everything after them (M7, M10–M13); the contents of `CLEARerrors.bas` (M12); fit iterations after the first, Fitlog, FitparWrite, χ² (M16); `ctl/` coordination and its files on disk (vision §3, M14); dialogue, GUI and plotting (not ported).

## 4. Facts established while planning (2026-10-14)

| Item | Fact |
|---|---|
| Cost of full BASIC runs | From store wall times: `m5_u235_n.in` (`Fenhance` 1, 2 energies, ENDF, 5 steps) 99 s; `m1_rn215_short.in` (`Fenhance` 10, 11 steps) about 40 min; `m2_rn215_full.in` (62 steps) about 4.8 h. Estimated: `wrkdir/in/NFred.in` (144 systems × 59 energies, ENDF) about 50 h; `SFred.in` (211 systems, `Fenhance` 10) several hours; `Jeremi2.in` (`Fenhance` 10000) about a day. The T0 captures (`m4_t0.in`) took about 5 s each |
| Corpus | `Reference/GEF_code/wrkdir/in/`: 183 files, 174 of which parse as sequence files (numeric first line, at least one system line); `Fenhance` 1 in 164, 10 in 8, 0.1 in one (`SFtest.in`), 10000 in one (`Jeremi2.in`); 152 contain `FIT(...)`, one `NITER`. Entrance channels used: `EN`, `GS`, `EN1`, `EB`, `EP`, `EM`, and `GS2`, `EN°` (read as `GS`, `EN` through `Left(CEref, 2)`). **`FC`, `IS`, `EA` and `ES` occur in no corpus file.** `validation/reference/` adds `gefy_nfy` (`Fenhance` 10, 59 energies, ENDF, A ranges giving 150 `EN` system lines for 143 library tapes) and `gefy_sfy` (`Fenhance` 100, ENDF, 251 `GS` system lines for 239 tapes); whether the setup skips account for the difference is recorded from the setup-only captures |
| Harness | P1 is written before 3882 (`PROBES.md`); `Eexc_min_multi` is computed after it and dumped only in P2. `harness.run` writes `file.in` as `"in/<input>"` + `END`, takes one `--input`, copies `--work-file`s into `work/` only, and runs with stdin from `/dev/null` |
| `done.ctl` | `Print #Fdone, P_Z_CN, P_A_CN, En_max, Fenhance, I_Mode_selected` (`GEF.c:40884-40894`: Longint, Longint, Single, **Double**, Longint), read back with `Input #` into `Single` `Zdone, Adone, Edone, Fenhance_done` and `Integer Imode_done`; the test is `(double)Fenhance_done != Fenhance` (`GEF.c:40727`). For `Fenhance` 0.1 a repeated line is never recognised. `U_Valid` failures are not registered (the check comes first, 3205); unbound systems are (registration 3217 precedes 3377) |
| Missing isomer in batch | `Goto RepeatInput` (3567) passes 1910 (`P_I_rms_CN = 0`), 2515-2517 (`Chisqr_Fit_min`, `I_Fitloop = 0`), `Nextfitloop` (FitparRead, `I_Fitloop = 1`, `Var_*`), 2647-2684 (`Nfilein = 0`, `GEF.c:38011`; tables reset) and re-reads `file.in`. It ends only because every started system is in `done.ctl`; in fit mode the check is off and BASIC loops for ever. Whether the recomputed `Var_*` differ (Q-019: the `PZ_S3_olap_curv` working copy is no longer 0 after a nominal pass) is to be established (M6.0, full run F6) |
| Sticky settings | `B_Fit` is written only at 868, 2729, 2987 (never reset). The per-file reset (2829-2842) does not cover `EOscale` (NEO), `D_Par_Fac` (DPARFAC), `B_MyParameters`, `Bplot`, the LMD `P*` flags, `N_iter`, `C_Fitoption`. `B_Error_On` has no per-system reset: the ENDF step schedule (3459-3490) leaves it 0 after the last step, so a later non-`EN` line of the same file runs without error analysis. An `ES` line clears `B_ENDF` and `B_random_on` (3273-3274) for the rest of the file |
| Stale values read by setup | The `E/spin` check (2801) reads `Emode` before the file's system lines are parsed (initial 1, `GEF.bas:898`). A spectrum-file energy line leaves `N_E_values`/`Energy_Table` as the round's earlier files left them; the two-system check (3072) and the `ES`/`EM` step energy (3495) read them. `Spin_CN` is not set for `Emode` 3 and 13 in setup; it holds what the previous bin (5552, 5558) or pre-pass (4249) wrote. `Fenhance` is set to 1 at 3922 when 0, after the per-step reset at 3695 |
| Single-step modes | `FC`, `IS`, `ES`, `EM` keep `N_E_steps = 1` and run `Energy_table(1)`, while `done.ctl` and the `_sf`/`_cf` choice of `CFileout` use `En_max` (3225, 3413) |
| Two-system lines | `P_E_exc = P_E_exc_Double` (3304) is overwritten by the batch step schedule for every `Emode` (3449-3497); `fbdef P_E_exc_Double --refs` shows no other reader, so the 6-field line's energy has no effect. `Goto Next_Iline_label` for an unbound first system also skips the second |
| Spectrum normalisation | Runs for every `Emode` (3682-3689). With the start-up `W_spectrum(1) = 0` (2671) it divides 0 by 0; P1 dumps the result. A spectrum read once is renormalised at every later step |
| Limits | `Emax_valid` (894) is never read. In batch mode `Eabsgs > 100` and `> 120` print nothing (3849-3868); only `Eabsgs < 0` (3869) and the alpha check (3835) end GEF |
| Fatal ends in batch | Missing sequence or spectrum file (2782, 3094, 3122, 3674), energies not ascending (2814), `E/spin` with `Abs(Emode) > 1 And Emode <> 3` (2801), spectrum file with a non-`ES`/`EM` line (3064, 3100), two-system line with several energies (3072, 3152), invalid channel (3279), alpha energy too low (3835), `Eabsgs < 0` (3869). Each prints, `Sleep`s and `End`s |
| Arrays | `S_par(5000)` (2664) is filled without a bound check (3050, 3057, 3087); `Cfilein(1000)` is checked (2738) |
| Pass schedule | With `B_Error_Analysis = 1`: `N_Error_Max = Int(sqr(Fenhance*100))`, `NEVTtot = Fenhance*1E5/N_Error_Max`; in fit mode `N_Error_Max = 1`, `NEVTtot = Fenhance*1E5` (5059-5071). Nominal: `NEVTtot = Fenhance*1E5`. `I_Error` runs 0…`N_Error_Max`; at `I_Error = N_Error_Max` the last pass is nominal (15528-15550). Float to integer assignments round half to even |
| `Parameters` | `Emode`, `EOscale`, `Eexc_min_multi`, `Emax_valid`, `D_Par_Fac`, `Chisqr_Fit_min`, `BFC`, `B_MyParameters` are members of M4's `Parameters` but not assigned by `Parameters.bas`, so `load_parameters_bas` leaves them alone (D6) |
| Coverage matrix | The `FC` row is labelled "excitation-energy spectrum"; `FC` is first-chance-only CN fission (`Emode = -1`, 3234) |

**Quirk candidates** to establish in M6 and register (numbers from Q-042): (a) stale `Emode` in the `E/spin` check; (b) the 6-field line's energy is ignored; (c) single-step modes run `Energy_table(1)` but name and deduplicate by `En_max`; (d) stale energy table after a spectrum-file line; (e) 0/0 spectrum normalisation and renormalisation every step; (f) `done.ctl` deduplication with the `Single`/`Double` `Fenhance` mismatch; (g) the missing-isomer restart (and its hang in fit mode); (h) settings that survive the per-file reset, including `B_Fit`; (i) `B_Error_On` and `B_ENDF` carried from one system line to the next; (j) `DPARFAC` takes effect only after a restart or fit iteration (widths are computed before the files are read); (k) `S_par(5000)` unchecked; (l) `Spin_CN` of `ES`/`EM` steps comes from the previous bin; (m) `Emax_valid` unused, no energy limit in batch mode.

## 5. Work breakdown

Tasks in execution order. Mark each one done here when finished, and update `CURRENT_PROJECT_STATE.md`.

### M6.0 Oracle and captures (D1)
- [ ] `probes.patch`: probe **P0** after each sequence file is read (after 3128, `Fenhance = Fenhance_global`): `Nfilein`, `Cfilein()`, `Ifilein`, `Fenhance_global`, `Fenhance`, `C_Energy_Table`, `I_first_E_step`, `N_E_values`, `Energy_Table`, `Spin_Table`, `En_min`, `En_max`, `C_Espectrum1`, `C_Espectrum2`, `Iline_tot`, `S_par(1…Iline_tot)` fields, the per-file flags (`B_Error_On`, `Brec`, `Bcov`, `Bcor`, `B_supp`, `B_ENDF`, `B_Random_On`, `CFileoutlmd`, `Cfileoutlmd_full`, `Clocal_file_option`, `I_Mode_selected`), the sticky settings (`B_Fit`, `N_iter`, `C_Fitoption`, `Bplot`, `B_MyParameters`, `D_Par_Fac`, `EOscale`, the LMD `P*` flags) and `Emode`. Probe **P1b**, once per step: at the pre-pass decision (3967) for the modes that enter the `If` of 3948, and right after that `If` (4801) for the modes that do not: `Eexc_min_multi`, the `Bmulti` decision, `Fenhance`, `N_multi_sample`. `PROBES.md` and `harness.probes` updated. Neutrality re-proved: same seed, byte-identical outputs to the stored `m1-g23` and `m1-g4` runs.
- [ ] Patch `setup` (`-d GEF_SETUP_ONLY`), in the canonical order after `arglog`: after P1b, `GoTo` a label placed on the blank line 15580 (so `GEF.bas` line numbers do not move). Patch set `m6-setup` (seed, scope, probes, setup). The emitted C without `GEF_SETUP_ONLY` equals the `seed-probes` emission apart from source-echo comments.
- [ ] `harness.run`: `--file-in PATH` (use this `file.in`), repeatable `--input` (each copied to `work/in/`), `--work-file SRC[=REL]` (copy to a relative destination), and, if M6.0 finds that `Sleep` blocks on `/dev/null`, a newline on stdin. Pytest for each.
- [ ] Establish, with `harness.driver` programs: (1) console `Print` to a redirected stdout (zones, `;`, lines longer than 80 columns) against `fb::PrintFile`; (2) what `Sleep` without arguments does with stdin at EOF. Record the results; a difference in (1) is ported into a console variant of `PrintFile`.
- [ ] Corpus manifest `harness/inputs/m6/corpus.toml` (D12): every sequence file of `wrkdir/in/` and `validation/reference/`, the extra files each needs (spectrum files, `MyParameters.dat`), and whether `NITER(1)` is added; plus the edge inputs. Tool `python3 -m harness.corpus run|store` runs the manifest against a binary into the store.
- [ ] Edge inputs `harness/inputs/m6/` (every channel and option the corpus lacks, every fatal end, every quirk candidate):

  | Input | Covers |
  |---|---|
  | `channels` | `EB` with `E/spin`, `GS` at 0 and > 0 with spin, `FC` with two energies, `IS1`, `EN`, `EN1`, `EP`, `EA`, `ES` (2-column file), `EM` (3-column file), `GS2`/`EN°`-style suffixes |
  | `options` | every `Options` keyword, an unknown one, `DPARFAC(2)`, `MODE(S2)`, an invalid `MODE` |
  | `lines` | A range, A range with step, 6-field line with energy and with spectrum file, a 4-field line |
  | `dedupe` | two files with overlapping systems, `Fenhance` 1 and 0.1; `Fenhance` 0 |
  | `skips` | `U_Valid` failure, an unbound CN, a CN missing from NucTab (`IMATmax`) |
  | `schedule` | `EN` + `ENDF` with 1 energy, `RANDOM` with 1 energy, N energies with `k:` prefix, `EN` then `GS` in one ENDF file, `ES` line in an ENDF file |
  | `sticky` | file 1 with NEO, DPARFAC, LMD, FIT; file 2 plain; `NITER(1)` |
  | `restart` | system, system with a missing isomer, system |
  | `threshold` | `EN` energies on both sides of `Eexc_min_multi` (one `Single` ULP apart, from a first run) and `GS` near its `BFTF(…, 5) − 3` |
  | `high_energy` | `EN` at 150 MeV (`Eabsgs > 120`) |
  | `fatal_<n>` | one input per fatal end of §4 |
  | `s_par_overflow` | more than 5000 systems in one file (run with an `-exx` build; shows the unchecked write) |

- [ ] Setup-only captures `m6-setup-<input>` for the corpus, `validation/reference/` and the edge inputs (all steps traced).
- [ ] Full-run captures (`seed-probes`, `Fenhance` 1): F1 `ES` + `EM`, F2 two-system line, F3 `EN1`, F4 CN missing from NucTab, F5 FIT with `NITER(1)`, F6 `restart`, F7 `EN` then `GS` in an ENDF file. Each also as a setup-only capture.
- [ ] Patch check: for F1–F7 and `m4-p1-rn215`, `m4-p1-fitpar`, the P0/P1/P1b of the setup-only run equal the full run's except a listed set of fields, each explained by a write in the skipped code (expected: `Z`, `T`, `Spin_CN` for `ES`/`EM`, `Fenhance` where 3922 applies, `IMATmax` additions, the `Var_*` after a restart). The setup-only stdout equals the full-run stdout with the lines of the skipped code removed. The list goes into `ProcessState` as the fields a step body may write (D5, D6).

**Done when:** patches proven neutral, captures stored, the patch check passes, the console and `Sleep` behaviour recorded.

### M6.1 State objects and input parsing
- [ ] `state.hpp`: the D6 scopes, each field with its BASIC name, type and reset point; `WorkDir` (D7).
- [ ] `read_file_in` (2699-2763) and `parse_sequence_file` (2768-3133), line by line from the `fbline` output, with every console line, the sticky settings in `ProcessState` and the fatal ends as `RunEnd` (D8).
- [ ] Tests: the P0 of every capture, field by field.

### M6.2 Run driver (D2, D4, D5)
- [ ] `RunDriver`: the round/file/line/system/step loops; `done` list (D2); `U_Valid` skip; `Emode`, `N_E_steps`, `I_E_iso`; the step schedule (3449-3497) including the ENDF N+3, single-energy and `RANDOM` paths; `B_Error_Analysis` and the pass schedule with its headers (5055-5091) and loop (15527-15551); unbound skip; restart; fit back edge (D4); batch exit text (15664-15666).
- [ ] Tests: the sequence of (file, line, system, step) records equals the P1 contexts of every capture; the pass schedule equals the pass headers of the full-run captures' stdout.

### M6.3 System setup
- [ ] `begin_system` (3294-3440): covariance system, `Clocal`, `load_parameters_bas` when `B_Fit = 0`, the barrier and mass printout (`BFC`), the unbound check, `CFileout`, `CFileout_Single`, `CFileout_full`.
- [ ] Round setup at `Nextfitloop`: `fitpar_read`, `I_Fitloop`, `update_widths` with the `PZ_S3_olap_curv` working copy from `ProcessState`.

### M6.4 Step setup
- [ ] `begin_step` (3442-3880 and 3922-3972): energy, `Csystem`, lmd name, isomer and `E_EXC_ISO`, spectrum reader and normalisation (`Ichannel`, `E/L/W_spectrum`, `W_spectrum_max`, `NE_all`, `NE_fis`, `I_Warning`), `Fenhance`, `Spin_CN`, `Spin_target`, `Eabsgs`, `Bprot`, `Balpha`, range checks, `Fenhance = 0 → 1`, `N_multi_sample`, `Eexc_min_multi`, pre-pass decision.

### M6.5 Tests
- [ ] `run_corpus_test.cpp`: for every manifest entry, the C++ driver with an empty step body on the same inputs; P0/P1/P1b equal BASIC field by field (all fields for setup-only captures; all but the M6.0 list for full runs); first difference reported with input, record and field. Fingerprints without the store; inputs from `validation/` skip without it.
- [ ] `run_console_test.cpp`: the C++ console equals the setup-only stdout from the D3 start to the end, byte for byte; for full runs, the C++ lines are a subsequence of the BASIC stdout in order, with only lines of M9–M13 code between them.
- [ ] Unit tests where the corpus cannot reach: `GefHangs` for a missing isomer in fit mode; the D10 branches.

**Done when:** every test passes in `dev-gcc`, `dev-clang` and `release-exact`; `asan-ubsan` and `tsan` pass without `[slow]`.

### M6.6 Quirks, CI, documentation and close-out
- [ ] Register the established quirk candidates of §4 with evidence and fidelity switches; annotate the C++ (`QUIRK(Q-0xx)`); close the M6 part of Q-018 (per-system reset) and Q-021 (in-process `IMATmax.ctl`).
- [ ] `scripts/ci.sh` covers `gef_run`, its tests and the new pytest; `harness.golden check` covers the M6 goldens.
- [ ] Update `COVERAGE_MATRIX.md` (the T1 cells M6 owns; the `FC` label; "Maximum valid energy" as no limit in batch mode), `IMPLEMENTATION_STRATEGY.md` (M6 status; §2.4 with `InputRoundState`; the M6 console criterion of D3), `harness/README.md`, `PROBES.md`, `CODING_STANDARDS.md` if the run module adds conventions, `CURRENT_PROJECT_STATE.md`.
- [ ] Mark this plan complete with completion notes.

## 6. Exit gate (all must hold)

| Gate | Requirement |
|---|---|
| G1 Oracle | Extended `probes` and `setup` patches neutral; the patch check of M6.0 passes with every difference explained |
| G2 Captures | Setup-only captures for the whole corpus, `validation/reference/` and the edge inputs; full-run captures F1–F7 |
| G3 Bit-exact setup | P0, P1 and P1b of the C++ equal BASIC for every capture (full runs: except the listed step-body fields), in `dev-gcc`, `dev-clang` and `release-exact`; NaN sign and payload excepted (B-001) |
| G4 Run plan | Files, lines, systems, steps and pass schedules in BASIC's order for every capture, including skips, the restart, every fatal end and the fit back edge |
| G5 Console | Byte-equal to the BASIC stdout over the D3 range for every setup-only capture; subsequence-equal for the full runs |
| G6 Quirks | Every candidate of §4 established and registered, or shown not to hold |
| G7 CI | `scripts/ci.sh` passes in all presets; clang-tidy, clang-format, ruff and basedpyright clean; goldens current |

## 7. Out of scope (later milestones)

- Pre-pass, bin loops, table builder, events, perturbation and writers (M7–M13); the CLI that runs them (M14).
- Writing `ctl/done.ctl` and `ctl/IMATmax.ctl` to disk, and history from earlier runs in the same directory (Q-026; M13/M14).
- Fit iterations after the first and the fit outputs (M16).
- Dialogue, GUI, plotting and `ctl/` coordination (vision §3).

## 8. Risks and open questions

| Item | Handling |
|---|---|
| The `setup` patch changes a setup value | Patch check of M6.0 on seven full runs and two existing captures; every difference must be explained by a write in the skipped code |
| Console `Print` to a redirected stdout differs from `PrintFile` (line width, zones) | Established in M6.0 before porting; a difference becomes a console variant of `PrintFile` |
| `Sleep` blocks with stdin at EOF, so fatal-end inputs hang the harness | Established in M6.0; the harness then supplies a newline |
| A corpus input refers to a file that is not in the repository | BASIC ends with its message; the C++ must print the same; recorded in the manifest |
| Store size of setup-only captures (`gefy_nfy`: up to 150 × 62 ≈ 9,300 P1 records) | Fingerprints committed; size recorded at M6.0; sparse dumps where `PROBES.md` already uses them |
| A step body changes a later control decision (which would invalidate the plan-as-data reading of D5) | The M6.0 list of step-body writes is checked against every control decision of the driver; any overlap is recorded for M17's scheduling |
| `S_par` overflow is undefined behaviour in BASIC | Not reproduced: the C++ throws (`fb::Array` bounds), recorded as a quirk with the `-exx` evidence |

## 9. Completion notes

None yet.
