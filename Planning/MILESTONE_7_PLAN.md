# Milestone 7: Per-Nucleus Model Tables

**Status:** planned 2026-10-29; M7.0 done 2026-10-30
**Strategy reference:** `IMPLEMENTATION_STRATEGY.md` §2.4, §2.8, §2.9 and §3, M7
**Depends on:** M1 (probe P3, runner, reference store, `harness.golden`), M3 (`gef::fb` conversions, maths, `fb::Array`, `fb::PrintFile`, `fb::str`), M4 (`TableSet`, `Parameters`), M5 (the `gef::physics` functions the builder calls, `BetaEquiResult`), M6 (`RunDriver`, `ProcessState`, `StepState`, the console of D3, `read_mass_table` of Q-042)
**Unblocks:** M9 (the global `Z` the builder leaves for the next step's pre-pass, Q-007; the bin list that consumes `E_multi_chance`), M10 (every event-loop input except the random stream), M11 (the `EPART`/`SpinRMSNZ`/`EMpot` tables behind the dmp files), M12 (the working-parameter state that the perturbed branch fills), M13 (the values of the `<Control>` block)

## 1. Goal

C++ builds the per-nucleus model tables of every bin exactly as BASIC does (`GEF.bas:5432-7511`, with the bin loops 5497-5577 and 10001-10004): the same bins in the same order, the same mode positions, deformations, polarisation, curvatures, barriers, energies, temperatures, widths, yields, shells, even-odd tables, energy sorting and RMS spins, bit for bit, including what earlier bins, passes, steps and systems leave behind. The builder draws no random number, so it is proven at T1. After M7, every input of the event loop except the random stream is proven, for every bin whose inputs are given (strategy exit, extended by D4).

## 2. Decisions taken in this plan

User decisions of 2026-10-29 (D1, D2, D3, D4, D5, D6, D14), taken on the facts of §4.

| ID | Topic | Decision | Reason |
|---|---|---|---|
| D1 | BASIC oracle for carried state | Extend the `probes` patch with **P3in**, written at bin entry (after `GEF.bas:5577`, `If NEVTused > 0 Then`) under the same scope selector as P3 (`Harness_Traced()`), with P3's variable list plus every variable the builder reads before writing it in the same bin that P3 lacks (the read-before-write set, established in M7.0 from the emitted C). P3 itself is unchanged, so the M1 captures stay valid. Proven neutral as in M6.0 (same seed, byte-identical output, only `probes/` added) | Because of Q-010 a bin's tables depend on what earlier bins left; P3 is written after the builder, so no record holds a bin's input state. With P3in each bin is tested on its own, including perturbed passes and multi-chance bins (user, option b of "carried state") |
| D2 | End-to-end chain | In addition to D1, nominal first-chance runs are replayed from process start with nothing injected: `RunDriver` (M6) plus the builder over every bin of every step, the carried arrays flowing through `ProcessState`; compared with every traced P3 record | Proves the carry-over as data flow, not only per bin (user, option c of "carried state"). Limited to runs whose every step is first-chance and whose passes are all nominal: multi-chance bin weights need M9, perturbed parameters need `PGauss` (M8) |
| D3 | Perturbed-pass parameters | Injected from the hex working copies in P3in (group "working parameter set"), not from `tmp/*.par`. The strategy's "parameter sets injected from BASIC `tmp/*.par` captures" is amended | `.par` prints `Single`s to at most 7 significant digits (`P_DZ_Mean_S1 = -0.334592`); a `Single` needs 9 to round-trip, so `.par` injection is not exact (user, option a) |
| D4 | Bin loops and multi-chance bins | M7 ports the bin enumeration and bin inputs (5497-5577, the closers 10001-10004) as a `BinPlan` that yields the bins with `NEVTused > 0` in BASIC's order, including `I_A_CN`/`I_Z_CN`/`R_E_exc_used`/`R_NEVTspectrum` of multi-chance bins (5546-5550), `Spin_CN = 0` for `Emode = 13` (5552), the `ES` spectrum values (5556-5559), `I_rigid_spher`, `I_eff_CN`, `E_rot_CN` and `NEVTused` (5565-5569). The builder is tested on multi-chance bins with inputs from P3in. The M7 exit becomes "every bin whose inputs are given"; M9 then proves only `E_multi_chance`, M10 the body 7920-9997 | In multi-chance steps `I_A_CN` changes from bin to bin, the case where Q-010's stale reads matter most; first-chance-only tests would leave it to M9/M10 (user, option b) |
| D5 | Capture corpus | Driven by the coverage matrix: the systems, options and quirk runs of §5 M7.0, listed in the committed manifest `harness/inputs/m7/corpus.toml` (inputs, seed, `GEF_TRACE_STEPS`/`GEF_TRACE_PASSES`, purpose, coverage cells), read by the harness and the C++ tests. Narrow trace selections; sizes recorded at M7.0 | Every T1 cell M7 closes needs a capture of its own (user, option b) |
| D6 | `Beta_Equi` message (Q-041) | M7.0 sweeps the builder's call (5722) over its whole input domain: every CN `U_Valid` accepts, the multi-chance reductions (Z − 0…10, A − 0…20), `IZ1 = 10 … I_Z_CN − 10`, nominal `DNECK` and every `DNECK` the batch inputs can set (`Fitpar.dat` through `ReadParameters.mac`, checked in M7.0). Never reached: ported as `throw std::logic_error` with the proof (M6 D10). Reached: the builder returns `BetaEquiResult`'s diagnostic to its caller and the destination stays with M13 (Q-041) | The destination depends on the file state of M9/M13 (`f` from 4150, 4179, 10057); proving unreachability avoids pulling it forward (user, option a, fallback c) |
| D7 | State | Strategy §2.4 refined: the builder's arrays (`beta`, `Edefo`, `Zmean`, `Zshift`, `Temp`, `TempFF`, `Eshell`, `PEOZ`, `PEON`, `EPART`, `SpinRMSNZ`, `EMpot`) and its scalars are one `tables::BinTables` held in `ProcessState`. `Beta`, `Edefo`, `PEOZ`, `PEON`, `EPART` and `SpinRMSNZ` are `ReDim Shared` once (1084-1205) and never cleared, so they carry across bins, passes, steps and systems (M7.0 checks the other arrays the same way). Writers outside the builder (e.g. `EMpot` cleared per pass by `CLEARspectra.bas:10`) are ported in M7 as `BinTables` members and called where BASIC calls them. Builder temporaries that later code reads (global `Z`, `T`, and those found in M7.0 among `beta1`, `Z1`, `IA1`, … of P3's group "stale temporaries") are `ProcessState` fields (coding standards §2.3, "no mutable globals"); the rest are locals. The working parameters (the 47 working copies of P3's group "working parameter set") are a `WorkingParameters` struct in `PassState`, which M7 creates; M7 ports the nominal branch (5432-5484), M12 the perturbed one | Lifetimes as BASIC resets them; `params::Parameters` holds only nominal values (M4.4) |
| D8 | C++ API and layout | `Cpp_implementation/src/tables/`, CMake target `gef_tables`, namespace `gef::tables`: `bin_plan.{hpp,cpp}` (D4), `bin_tables.hpp` (D7), one source file per block group of §3 (`deformations.cpp`, `barriers.cpp`, `widths.cpp`, `yields.cpp`, `fragments.cpp`, `spins.cpp`; final names in M7.1), each a function over (`BinInput`, `WorkingParameters`, `params::Parameters`, `data::TableSet`, `BinTables&`, the `ProcessState` fields it writes), and `build_bin_tables` composing them in BASIC's order. Tests `Cpp_implementation/tests/bin_tables_<part>_test.cpp`, tagged `[tables][T1]`; P3/P3in readers and writers in `tests/support/` | Strategy §2.8 (`tables/`); `tables_test.cpp` and `[data]` are M4's `TableSet`, hence the `bin_tables_` prefix. Block functions let each sub-milestone verify its part |
| D9 | Per-block comparison | M7.0 builds a last-writer map: for each P3 variable (and array element range) the block of §3 that writes it last in a bin. M7.k compares, after its blocks, every P3 variable whose last writer is in M7.1…M7.k, starting each record from its P3in state; variables a later block overwrites are compared when that block exists | A sub-milestone is approved on a bit-exact gate of its own, not on the whole builder |
| D10 | Console | The builder's prints (5584-5586 for `Emode = 3`; 7016-7017 when `P_selected = 0`) go to `ProcessState::console` (M6 D3); M6's console test covers them (full runs: subsequence order) | Same console model as M6 |
| D11 | Zero-patch cross-checks | The `<Control>` block of `out/` (writer GEF.bas:14603ff), the `Epart(i,j)` sections of `XE.dmp` (15452-15461) and `EMpot.dmp` (writer via `U_DMP_1D`, about 14888) are parsed with the M2 parsers and compared with the C++ values printed as BASIC prints them. M7.5 establishes from which bin and pass each printed value comes | Strategy M7 "Proven by"; independent of the probe patch |
| D12 | Unreachable branches | As M6 D10: `throw std::logic_error` with the proof in a comment | Keeps the port line for line |
| D13 | Types, arithmetic, presets, nuclide data, test data | As M6 D9, D12, D13: JEFF-3.3 only; BASIC types (`Single` → `float`, `Integer` → `std::int64_t`), arithmetic from the `fbline` output, conversions through `fb::f2l` etc.; table reads through `read_mass_table` (Q-042); every T1 test in `dev-gcc`, `dev-clang` and `release-exact`, NaN sign and payload excepted (B-001); P3/P3in fingerprints committed with `harness.golden`, full dumps in the store, tests that need the store skip without it | Coding standards §2.4, §5; M3–M6 |
| D14 | Sub-milestone cut | M7.0 oracle and captures; M7.1 bins, mode centres and deformations; M7.2 barriers, energies, temperatures and widths; M7.3 shifts, `EMpot`, polarisation and yields; M7.4 shells, fragment temperatures, even-odd, energy sorting and spins; M7.5 integration, cross-checks and close-out (§5). One session per sub-milestone | Each part ends at a block boundary where P3 groups give a bit-exact result (D9) (user, six-part cut) |

## 3. Scope inventory

Line ranges are `GEF.bas` at `ba9f0aa`. Boundaries marked ~ are from the planning survey and are confirmed with `fbline` in the sub-milestone that ports them; the authority for which lines are live is the emitted C (the `/' … '/` nesting is easy to misread).

| Region | Content | Part |
|---|---|---|
| 5432-5484 | Nominal branch of the working-parameter assignment (`P_DZ_Mean_S1 = _P_DZ_Mean_S1`, … `Jscaling`) | M7.1 (D7; the perturbed branch 5095-5431 is M12's) |
| 5490-5577, 10001-10004 | Bin inputs, `IEVTtot`, the four bin loops, multi-chance and `ES` bin inputs, `I_rigid_spher`, `I_eff_CN`, `E_rot_CN`, `NEVTused`, the `NEVTused > 0` guard, the loop closers | M7.1 (`BinPlan`, D4) |
| 5584-5586 | `Emode = 3` console print | M7.1 |
| 5600-5620 | Shell effects of the symmetric channel | M7.1 |
| 5621-5696 | Central Z of the modes (Böckstiegel fit), `ZC_Mode_*` | M7.1 |
| 5697-5875 | Mean deformations at scission, modes 0-7: `Beta`, `Edefo`; `Beta_Equi` at 5722 (D6); Q-009 at 5831 | M7.1 |
| 5876-5994 | Mean Z as a function of A per mode (writes the global `Z`) | M7.1 |
| 5995-6049 | Z–A relations of the modes (`RZpol`, `AC_Mode_*`, `NC_Mode_*`) | M7.1 |
| 6050-6062 | Potential curvatures (`Masscurv`) | M7.1 |
| 6063-6104 | Energy transformation, barriers (`BFTF`, `BFTFB`), N = 82 influence | M7.2 |
| 6105-6224 | S1 enhancement around Pu; Z = 44 shell reduces the light deformation (`Beta(1,1,·)`, `Edefo(1,1,·)` updated in place, 6142-6151) | M7.2 |
| 6225-6278 | Overlap modes S11, S22 | M7.2 |
| 6279-6321 | Energies above the mode saddles, `E_exc_Barr` | M7.2 |
| 6322-6346 | Temperatures (`TRusanov`, collective, polarisation) | M7.2 |
| 6347-6448 | Suppression of S1 at low energy at scission | M7.2 |
| 6449-6475 | Polarisation stiffness | M7.2 |
| 6476-6560 | Mean values and widths of the modes, `R_Att`, `R_Att_Sad` | M7.2 |
| 6561-6733 | Energy-dependent shifts of the modes; `B_supp` (`NOSUPP`) | M7.3 |
| 6734-6785 | `EMPot`, only in bin (1, 0, 0, 0) | M7.3 |
| 6786-6871 | Energy dependence of the charge polarisation; Z–A relations, 2nd iteration | M7.3 |
| 6872-7019 | Mode yields (`Getyield`), `Yield_Norm`, `I_Mode_selected` (`MODE(i)`), `P_selected`; print 7016-7017 | M7.3 |
| 7020-7039 | Mass widths `SigA_Mode_*` | M7.3 |
| 7920 | `Racc = 100 / NEVTtot * P_selected` | M7.3 |
| 7040-7072 | Microscopic shell effects `EShell` | M7.4 |
| 7073-~7180 | Intrinsic temperatures, `Temp`/`TempFF` per fragment (writes the global `T`) | M7.4 |
| ~7180-7380 | Per-mode scission energies (Q-008 at 7213-7220), even-odd `PEOZ`/`PEON` (Q-011 at 7294-7297, 7322-7325), energy sorting `EPART` (7376-7377) | M7.4 |
| 7381-7511 | RMS spins `SpinRMSNZ` (Q-010 reads at 7437, 7475; writes the global `T`) | M7.4 |
| `CLEARspectra.bas:10` | `EMPot(I,J) = 0` per pass | M7.5 (D7, member of `BinTables`) |

**Dead code, not ported:** 7514-7918 (`GEFSUB`/`GEFRESULTS`), and inside the live range about 600 lines of commented blocks (5579-5583, 5588-5595, 5981-5989, 6241-6245, 6393-6405, 6687-6728, the constant-temperature yield version ~6905-6975, 7301-7320, 7326-7332, 7412-7416). The live range is about 1,870 lines including comments (not measured exactly).

**Not in M7:** `PGauss` and the perturbed branch with `.par` (5095-5431; M8, M12); the pre-pass and `E_multi_chance` (3882-4800; M9); the event loop 7922-9997 (M10); `CLEARspectra` except the `EMpot` line (M10/M15); the writers of `<Control>`, `XE.dmp`, `EMpot.dmp` (M13); covariance between two systems (M12).

## 4. Facts established while planning (2026-10-29)

| Item | Fact |
|---|---|
| Random numbers | No `Rnd`, `PGauss`, `PBox*`, `PLinGauss`, `PExp` or `PMaxwell` call between 5163 and 7925. The last draws before the builder are the 46 perturbations (5112-5160); the next is `R_Choice = Rnd` at 7930-7931, after P3 |
| Carried arrays | `Beta` (1084), `Edefo` (1097), `PEOZ` (1169), `PEON` (1181), `EPART` (1193), `SpinRMSNZ` (1205) are `ReDim Shared` once and never cleared or re-dimensioned; `EPART` and `SpinRMSNZ` are written only at 7376-7377 and 7464/7499. `EMpot` (`Spectra.bas:5`) is cleared per pass by `CLEARspectra.bas:10` and written only in bin (1, 0, 0, 0) (6738-6741) |
| Bin loops | Up to 1 × 11 × 11 × 1001 bins per step in multi-chance steps (5515-5531), `I_E_Multi` counting down; first-chance steps have one bin per `ES` spectrum point. The loops close at 10001-10004. P3 sits at 7920, inside `If NEVTused > 0` |
| Output | Live prints in the builder: 5584-5586 (`Emode = 3`), 7016-7017 (`P_selected = 0`). No `Open`, `Close`, `Print #` or `Write #`. `Beta_Equi` (5722, once per `IZ1`) can print to `f` (Q-041) |
| Existing P3 data | Only Rn-215: `m1-g23-rn215-{n,r}-{probes,rp}` (steps 2 and 8, passes 0 and 31). `m1-g23-rn215-n-probes`' `P3.txt` has 1,700,742 lines: 31 records for step 2 (multi-chance, `I_E_Multi` up to 348) and 2 for step 8 (first chance, passes 0 and 31). A record is about 50,000 lines, 3.2 MB (`SpinRMSNZ` about two thirds) |
| `.par` precision | `tmp/GEF_86_215_n.par` prints perturbed values with `Str` precision (`P_DZ_Mean_S1 = -0.334592`, `P_corr_S1 = -0.04894118`); not a round-trip format for `Single` (D3) |
| `EOscale` | Initial 1 (897); set by `NEO` to 0 (2964), by `EOfac` (2097, in the `Cname`/`Cvalue` settings block; whether a batch run reaches it is checked in M7.0), by the dialogue (2329-2333) and by `ReadParameters.mac:186` (`Fitpar.dat`). A `Fitpar.dat` with `EOscale` ≠ 0, 1 is the batch route to Q-011; `NEO` (0) hides the double scaling |
| `Spin_CN` | Written by the bin inputs for `EM` (5552, 0) and `ES` (5558); the next step's set-up reads what the last bin wrote (Q-054). M7 writes `ProcessState::spin_cn` (`run/state.hpp:152`), as M6 prepared it |
| Builder calls | All implemented in `gef::physics` (M5): `Gaussintegral`, `Bell`, `U_Box`, `TEgidy`, `TRusanov`, `U_Temp`, `U_Temp2`, `LyMass`, `LyPair`, `FEDEFOLys`, `LDMass`, `AME2020`, `U_Mass`, `Ecoul`, `Masscurv`, `Masscurv1`, `Masscurv2`, `Getyield`, `De_Saddle_Scission`, `beta_light`, `beta_heavy`, `Z_equi`, `Beta_Equi`, `BFTF`, `BFTFA`, `BFTFB`, `Efac_def_GDR` (complete list from the emitted C in M7.0) |
| Coverage | M7 closes 12 T1 cells: pre-actinides, actinides, heavy actinides, superheavies, light vs. heavy isotopes, even-Z/even-N, odd-Z and/or odd-N, very low fissility, thermal, fast first-chance, `NOSUPP`, `MODE(i)`. It adds T1 evidence to charge polarisation, excitation energies, fragment spins and state persisting across energy steps |

**Quirks owned by M7:** Q-008 (mode-7 scission energies leak, 7213-7220), Q-009 (`Beta(4,1,·)` never set, 5831), Q-010 (`EPART`/`PEOZ`/`PEON` read outside the filled range 40 … `I_A_CN` − 40, 7437, 7475), Q-011 (`EOscale` applied twice on the mirrored half), Q-041 (destination, D6). Each is ported faithfully with its fidelity switch and confirmed in output by P3/P3in.

**Quirk candidates** to establish in M7 and register (numbers from Q-061), or show not to hold: (a) `R_Att_Sad(5)` uses the S4 energy `R_E_intr_S4` (6517); (b) `EMPot(6,·)`/`EMPot(7,·)` add two shell terms where modes 1-5 take `Min` (6772-6783); (c) `Yield_Mode_k / Yield_Norm` without a zero guard (6952); (d) `Edefo(1,2,·)` of the heavy fragment computed with the light `Z1`/`A1` (5770); (e) `EMpot` built only in bin (1, 0, 0, 0), so a multi-chance step whose first-chance zero-energy bin is empty writes no `EMpot` and the pass keeps `CLEARspectra`'s zeros; (f) mode 0's `E_diss_Scission = EDISSFRAC * E_pot_scission` (6344) has no `E_tunn` term, unlike the mode loop (7218); (g) the `I_E_Multi` loop runs 1001 bins per (N, Z), most skipped by `NEVTused = 0`, while `R_E_exc_used = 0.1 * I_E_Multi` is computed for each (performance only, recorded for M17).

## 5. Work breakdown

Tasks in execution order. Mark each one done here when finished, and update `CURRENT_PROJECT_STATE.md`. Branch `m7-tables`, created at the start of M7.0.

### M7.0 Oracle and captures (D1, D5, D6, D9) — done 2026-10-30 (notes §9)
- [x] Read-before-write set: from the emitted C of 5432-7920, every variable the builder reads before writing it in the same bin (scalars and array elements, including conditionally written scalars); every writer of the carried arrays outside the builder (`fbdef --refs`); the builder temporaries that later code reads (D7).
- [x] `probes.patch`: **P3in** after 5577 (D1), `#line` keeping every original line number; `PROBES.md` section P3in; reader support in `harness.probes`, `harness.probe_fingerprints`. If the size measurement below needs it, a bin selector `GEF_TRACE_BINS` in the `scope` patch. (Readers unchanged; no bin selector needed.)
- [x] Neutrality: the extended patch set against `m1-g23-rn215-n-a` and `m1-g4-cf252-ref1-independent` with `harness.compare_runs` (identical, only `probes/` added).
- [x] Corpus manifest `harness/inputs/m7/corpus.toml` (D5). Proposed entries, final in the manifest (deviations in §9):
  - pre-actinide: Rn-215 (n,f) (`m1_rn215_short.in`): odd N, a multi-chance step, a perturbed pass;
  - actinides: U-235 (n,f) at thermal, about 2 MeV (fast first chance) and 14 MeV (multi-chance), with `ERR` for one perturbed pass; Pu-239 (n,f) thermal (S1 enhancement around Pu, 6105);
  - odd Z: Np-237 (n,f) (odd-odd CN);
  - actinide sf: Cf-252 (`m1_cf252_gs.in`); heavy actinide: Fm-258 sf (symmetric);
  - superheavies: Sg-264 sf (`m5_superheavy_sf.in`) and one system at Z ≥ 110 if `U_Valid` accepts it, else the highest Z it accepts;
  - light vs. heavy isotopes and the leak between systems: a heavy and a light U isotope at the same excitation energy in one sequence file, heavy first;
  - very low fissility: Hg-180 and one Z ≈ 80-84 system at high excitation energy (mode 5);
  - options and quirks: `NOSUPP`; `MODE(i)`; `NEO`; a `Fitpar.dat` with `EOscale` = 0.5 (Q-011); `ES` and `EM` lines (the print at 5584, `Spin_CN = 0`; the M6 edge inputs have both);
  - D2 chain runs: at least two nominal, first-chance-only inputs with several steps and two systems.
- [x] Captures with `seed-probes` builds (`Fenhance` 1 unless the entry says otherwise); store entries `m7-p3-<name>`; store size recorded.
- [x] D6 sweep of `Beta_Equi` at 5722 (driver or C++ replay through `physics::beta_equi`), with the `DNECK` range batch inputs can set.
- [x] Last-writer map of the P3 variables over the blocks of §3 (D9), committed as test data.
- [x] Goldens: P3/P3in fingerprints per record (`harness.golden`); pytest for the patch, readers and the manifest.

### M7.1 Bins, mode centres and deformations (D4, D7, D8)
- [ ] `gef_tables`: `BinTables`, `WorkingParameters` (nominal branch 5432-5484), `BinPlan` (5490-5577, 10001-10004), `BinInput`.
- [ ] Blocks 5584-6062 from the `fbline` output: print 5584, S0 shell, mode centres, deformations of modes 0-7 (Q-009, `Beta_Equi` per D6), mean Z vs. A (global `Z`), Z–A relations, curvatures.
- [ ] Tests: the bin sequence and bin inputs of every capture equal the P3/P3in contexts and bin-input groups; every P3 variable whose last writer is in M7.1 equals BASIC, from P3in, for every record.

### M7.2 Barriers, energies, temperatures and widths
- [ ] Blocks 6063-6560: energy transformation, barriers, N = 82, S1 enhancement and the in-place `Beta(1,1,·)`/`Edefo(1,1,·)` update, S11/S22, energies above the saddles, temperatures, S1 suppression, polarisation stiffness, mean values and widths.
- [ ] Tests: D9 comparison through M7.2 for every record.

### M7.3 Shifts, `EMpot`, polarisation and yields
- [ ] Blocks 6561-7039 and 7920: energy-dependent shifts (`NOSUPP`), `EMPot` (first bin only), energy-dependent polarisation, Z–A 2nd iteration, mode yields with `MODE(i)` and the print 7016, mass widths, `Racc`.
- [ ] Tests: D9 comparison through M7.3; the `NOSUPP` and `MODE(i)` captures.

### M7.4 Shells, fragment temperatures, even-odd, energy sorting and spins
- [ ] Blocks 7040-7511: `EShell`, intrinsic temperatures, `Temp`/`TempFF` (global `T`), per-mode scission energies (Q-008), even-odd (Q-011), energy sorting (`EPART`, Q-010), RMS spins.
- [ ] Tests: the whole P3 of every record equals BASIC from its P3in (G3), including the stale parts of `EPART`/`PEOZ`/`PEON`, `Beta(4,1,·) = 0`, the mode-7 `E_tunn`/`E_diss_Scission`/`E_POT_SCISSION`, and the `EOscale` = 0.5 capture.

### M7.5 Integration, cross-checks, quirks and close-out (D2, D10, D11)
- [ ] `RunDriver` step body: the nominal working parameters per pass, the `EMpot` clear of `CLEARspectra`, `BinPlan` and `build_bin_tables` for every bin; `BinTables` and the builder's `ProcessState` fields carried as BASIC carries them.
- [ ] Chain test (D2): every traced P3 record of the chain runs equals the C++ computed from process start, without injection.
- [ ] Cross-checks (D11): `<Control>`, `XE.dmp` `Epart`, `EMpot.dmp` at printed precision; the console test with the builder's prints (D10).
- [ ] Quirks: Q-008–Q-011 upgraded to *confirmed in output* with the capture IDs; Q-041 resolved per D6; candidates (a)–(g) of §4 registered or shown not to hold; `QUIRK(Q-0xx)` annotations.
- [ ] `scripts/ci.sh` covers `gef_tables`, its tests and the new pytest; `harness.golden check` covers the M7 goldens.
- [ ] Update `COVERAGE_MATRIX.md` (the 12 T1 cells and the contributions of §4), `IMPLEMENTATION_STRATEGY.md` (M7 status; §2.4 `BinTables` per D7), `harness/README.md`, `PROBES.md`, `CODING_STANDARDS.md` if `tables/` adds conventions, `CURRENT_PROJECT_STATE.md`.
- [ ] Mark this plan complete with completion notes.

## 6. Exit gate (all must hold)

| Gate | Requirement |
|---|---|
| G1 Oracle | `probes` patch with P3in neutral; read-before-write set complete (no P3 difference traced to a missing P3in variable) |
| G2 Captures | Every manifest entry captured and in the store; sizes recorded |
| G3 Bit-exact tables | Every P3 record of every capture equals the C++ builder run from its P3in, in `dev-gcc`, `dev-clang` and `release-exact`; NaN sign and payload excepted (B-001) |
| G4 Bins | The bins with `NEVTused > 0`, their order and their inputs equal BASIC's for every capture, first-chance and multi-chance |
| G5 Chain | The D2 runs equal every traced P3 record without injection |
| G6 Cross-checks | `<Control>`, `XE.dmp` `Epart` and `EMpot.dmp` equal at printed precision; the builder's console lines in the console test |
| G7 Quirks | Q-008–Q-011 confirmed in output; Q-041 resolved per D6; every candidate of §4 registered or refuted |
| G8 Coverage | The 12 T1 cells of §4 covered in `COVERAGE_MATRIX.md` |
| G9 CI | `scripts/ci.sh` passes in all presets; clang-tidy, clang-format, ruff and basedpyright clean; goldens current |

## 7. Out of scope (later milestones)

- `PGauss`, the perturbed branch and `.par` (M8, M12); the C++ computes perturbed passes only from injected parameters until then.
- The pre-pass and `E_multi_chance` (M9); multi-chance bins are tested with their inputs from P3in.
- The event loop (M10), which reads `BinTables`; the rest of `CLEARspectra` (M10/M15).
- The writers of `out/`, `dmp/` and `ptb` (M13); M7 compares their printed values only (D11).
- Where `Beta_Equi`'s message goes if D6 finds it reachable (M13).

## 8. Risks and open questions

| Item | Handling |
|---|---|
| A variable the builder reads before writing is missing from P3in | M7.0 derives the set from the emitted C before capturing; a later P3 difference traced to a missing variable extends P3in, re-proves neutrality and re-captures (G1) |
| Store size (3.2 MB per P3 record, doubled by P3in; multi-chance steps write one record per populated bin) | Narrow `GEF_TRACE_*` selections in the manifest; sizes recorded at M7.0; a bin selector if needed; fingerprints committed, dumps in the store |
| Dead-code brackets misread in the BASIC text | Port from the `fbline` output only; the survey's line ranges are confirmed per sub-milestone |
| Conditionally written scalars keep values from an earlier bin | Part of the read-before-write set; compared through P3in/P3 and the D2 chain |
| Table reads past the bounds inside the builder | Direct reads of `DEFOtab`, `ShellMO`, `EVOD`, … route through `read_mass_table` (Q-042), with the bound tests of M6.4 |
| `Beta_Equi` reachable through a `Fitpar.dat` parameter | Settled in M7.0: reached with nominal parameters (Fm-212, Ds-270); D6 fallback applies: diagnostic returned, destination M13 |
| The `<Control>` and dmp values come from a different bin or pass than the last P3 record | Established in M7.5 before the comparison (D11) |
| The `PZ_S3_olap_curv` working copy lives in `ProcessState` since M6.3 (Q-019) | M7.1 decides whether `WorkingParameters` holds it or refers to the M6 field; one owner, no copy |
| A Z ≥ 110 system is rejected by `U_Valid` | The highest accepted Z stands in; the coverage note records it |
| No capture has a multi-chance bin with `I_Z_Multi` > 0 (a proton emitted before fission) | The captured multi-chance bins (u236-9, rn215-n, spectra) all have `I_Z_Multi` = 0, so `I_Z_CN` < `P_Z_CN` is not exercised; M7.1 tests `BinPlan` on it with synthetic `E_multi_chance` and adds a capture if a batch input with such a bin is found |

## 9. Completion notes

### M7.0 (2026-10-29 to 2026-10-30)

- **Read-before-write set (G1).** New tool `python3 -m tools.fbsrc.rbw` (`tools/fbsrc/README.md`): a control-flow graph of the emitted C of a BASIC range (gotos, labels, loops), a forward must-defined analysis (intersection at joins), the `Shared` globals the called GEF procedures read before writing them (transitively), their `Static` variables; modes `reads`, `writers` (ByRef arguments count as writes), `escapes`. The stretch is GEF.bas:5578-7920 (from bin entry to P3). Before it, 5432-5484 (nominal working parameters, D3/M7.1) have their results in P3in's working-parameter group, and 5490-5577 are the bin inputs of D4. Result at `ba9f0aa`: 105 variables read before written on some path; 101 are P3 variables, the others are `f` (Beta_Equi's file number) and `BEexp`, `BEldmTF`, `ShellMO` (read by `BFTF*`/`U_Temp`, written only by their loaders before T0). Called procedures hold two `Static`s, `AME2020`'s `Izaehl` (never used) and `U_Temp`'s `fgamma` (constant), so no procedure carries state between bins. Arrays read before written: `Beta`, `Zshift`, `Eshell`, `Temp`, `PEOZ`, `PEON`, `EPART`; `Edefo`, `Zmean`, `TempFF`, `SpinRMSNZ`, `EMpot` are written, not read. Scalars the builder carries across bins itself: `I_N_Multi_Max`, `I_Z_Multi_Max` only. `kappa4` is read (6053-6058) and assigned nowhere: always 0.
- **Writers outside the builder (D7).** The carried arrays are written outside 5578-7920 only by their `ReDim Shared` (1084-1205); `EMpot` (`Spectra.bas:5`) also by `CLEARspectra.bas:10` (and an erase on the interactive end path, not reached in batch). No builder input is written in the event loop 7921-9997; the closers 10001-10004 write the loop counters. Measured: within a pass, P3in of bin k+1 differs from P3 of bin k only in the bin inputs and in `RZ`, `RZpol`, `beta1` (event-loop scratch that the builder writes before it reads them). Temporaries read later: global `Z` (next step's pre-pass, GEF.bas:4322 and `Pfistest.mac:55`, Q-007; printed at `Branchings.bas:294`); `T` is read nowhere outside the builder; `beta1` (9313/9433) and `A1` (11719/11835, `CovarCUMU.bas:467`) are written before they are read there. So D7's `ProcessState` temporaries are `Z` and `T` (the latter only for P1 fidelity).
- **P3in (D1).** `probes.patch` gains `harness_probe_p3in.bi` after 5577 (`#line 5577`; eight insertion points), counter 6. P3in writes P3's list in P3's order minus the ten variables the bin block declares itself (`Escission_lim`, `T_Rusanov`, `R_E_intr_S1`…`S5`, `R_Att`, `R_Att_Sad`, `E_coll_saddle`: not yet declared at the probe point, fbc error 42; zero in every bin), plus `f`. `PROBES.md` section P3in; the readers needed no change. pytest: list equality, ids and counters, line numbers, and (fbc) the rbw set minus P3in equals the three T0 tables.
- **Neutrality.** `seed-probes-9ddf9e1b6099` (`-d GEF_PROBES`, binary stored as `binary-54b0e32ba44e` without a provenance record; its build id is in every `m7-p3-*` `run.json`, its patch hashes in `build/harness/seed-probes-9ddf9e1b6099/build.json`, whose probes hash equals the committed `probes.patch`) on `m1_rn215_short.in` (seed 20261007) and `m1_cf252_gs.in` (seed 20261008), steps 1-20, passes 0 and 31, events 1-5: `harness.compare_runs` IDENTICAL to `m1-g23-rn215-n-a` (244 files) and `m1-g4-cf252-ref1-independent` (42 files), only `probes/` added. The 33 P3 records of `m1-g23-rn215-n-probes` equal the new run's P3 line for line (apart from `rec`).
- **Corpus (D5).** `harness/inputs/m7/corpus.toml`, 20 entries, `Fenhance` 1, own seed and trace selection each; `harness.corpus` gained per-entry `seed`, `steps`, `passes`, `cells`, `chain` and `--manifest m7`. Deviations from the proposed list: Rn-215 uses `rn215_n.in` (thermal and 30 MeV, `ERR`, pass 0) instead of `m1_rn215_short.in` (`Fenhance` 10, `ENDF`: 11 steps × 32 passes); the multi-chance U entry is U-235 (n,f) at 9 MeV (64 bins, 480 MB) because 14 MeV writes 111 bins (about 830 MB); the `EM` part of `spectra` uses Pu-240, because a second U-236 line in the same run is skipped by `done.ctl` (Q-048: the key has no channel); the second chain run is Np-237 and Am-241 (n,f) at thermal, 0.5 and 1.5 MeV (`chain-odd`): `FC` runs one step only (Q-045), and a first `GS` version (`m7-p3-chain-gs`, Cf-252 and Np-238 at E* 6-8 MeV, kept in the store, no longer in the manifest) ran the multi-chance pre-pass in every step (`GS` thresholds 1.41 and 3.00 MeV), which the D2 chain cannot compute without M9; Cf-252 sf and Sg-264 sf use new inputs (`Fenhance` 1, no `ENDF`) instead of `m1_cf252_gs.in` (`Fenhance` 100, `ENDF`) and `m5_superheavy_sf.in` (`ENDF`), so one nominal pass is traced, not the perturbed passes of the ENDF schedule; Z ≥ 110: Ds-270 is accepted by `U_Valid`; very low fissility: Hg-180 FC 12 MeV and Po-210 FC 40 MeV; added Fm-212 GS (D6). The 12 T1 cells of §4 each name at least one entry, and every chain capture has P2 `Bmulti` = 0 in every step (pytest).
- **Captures (G2).** 20 store captures `m7-p3-<id>` in the manifest, one run each, 1,107,672,864 bytes in all (largest: u236-9 480 MB, spectra 271 MB, rn215-n 142 MB; single-bin entries 5-7 MB), plus the superseded `m7-p3-chain-gs` and `m7-d6-sweep` (the D6 program and its outputs). 296 P3in/P3 records for 148 bins: 34 first-chance bins (with `ES` `I_E_Distr` 1-4) and 114 bins of the multi-chance loops (u236-9 64, rn215-n 19, the `EM` part of spectra 31). Store: 154 entries.
- **D6.** Reached (details in Q-041): nominal DNECK gives 2,572 non-converging calls over the `U_Valid` domain and its reductions (C++ sweep through `physics::beta_equi`; program and outputs stored as capture `m7-d6-sweep`), and BASIC prints the message to the console for Fm-212 and Ds-270 (captures `m7-p3-fm212-sf`, `m7-p3-ds270-sf`). So the builder returns `BetaEquiResult`'s diagnostic and M13 decides the destination; no `logic_error`.
- **Last-writer map (D9).** `harness/inputs/m7/last_writer.tsv` (`python3 -m harness.last_writer [--check]`): per P3 variable its kind, the part of its last writer and every writer line (array targets in BASIC). 138 P3 variables are not written by the builder (`input`: P3 must equal P3in), 22/106/58/37 last written in M7.1/M7.2/M7.3/M7.4. pytest pins it to a fresh derivation and to plan anchors.
- **Golden.** `m7-p3` (`python3 -m harness.p3_golden`): one FNV-1a 64 per P3in and P3 record with its context, 14,949 bytes; checks that P3in and P3 cover the same bins; pytest checks that it lists the manifest's entries in order.
- **Review.** Round 1 (two `reviewer` agents on `anthropic/claude-opus-5-5`, as the usage-limit error of one shows; neither delivered a ledger, one stopped on the usage limit and the other ended with the session; their findings were taken from their transcripts): unused `CallRead` class and `Program.emission` field (removed); ByRef out-arguments missing from `writers` (`beta1_opt`/`beta2_opt` at 5722; fixed); descriptor set-up of block-local arrays counted as element writes (fixed); `ReDim` bounds and `static FBSTRING` declarations not seen (fixed, no instance in the stretch); D6 record said "all at IZ1 = 10" (corrected: 10-110); chain test did not check first chance; digest test compared records that differ in their context only; `last_writer` block cut and per-entry corpus settings untested (tests added); undocumented corpus deviations and binary provenance (recorded above). Round 2: ReviewerA2 approved A1-A7 with non-blockers; ReviewerB2 found one blocker, `chain-gs` running the pre-pass (B1, replaced by `chain-odd`, with a store-backed test that fails on `chain-gs`). Non-blockers fixed: arrays indexing a written element counted as written (`GEF.bas:11487`, outside the stretch); `writers` missed writes inside called procedures (now `@<procedure>`); JSON of `writers`/`escapes` keyed by BASIC name (collisions; now records per fbc name); a `static` initialiser counted as a definition; memoised recursion guard replaced by a per-instance summary that refuses recursion; dead fields `Analysis.first/last`, `Write.variable`; missing unit tests (`static` declarations, callee writes on `GEF.c`); fbc test without the source skip; golden not tied to the manifest; `u236-9` claimed the "energy steps" cell; record wording (binary note, sizes in MB, 5432-5577, D6 program kept in `m7-d6-sweep`). None changed the read set, P3in or `last_writer.tsv`.
- **Round 3** (the same two reviewers on the fixed tree): both approve A1-A7. ReviewerB2 confirmed B1 and N1-N8 fixed (`chain-odd`: threshold 8.19 MeV against `Eabsgs` 5.5-7.0 MeV, `Imulti` = `Inofirst` = 0 in every record; the 60 golden sources match the store). ReviewerA2 confirmed R2-1-R2-10; its three non-blocking notes were fixed in the records (`writers` does not see whole arrays passed to a GEF procedure that writes them, e.g. `Extend_2dim(_NZPOST(), …)`, none in the builder: README limit; the `u236-9` note's size; Q-041's Z range now cites `U_Valid`'s own limit, GEF.bas:15823). Not changed: the note in the immutable store manifest of `m7-p3-chain-gs` still calls it a corpus entry; this section records it as superseded.
- **Gates** (final tree; Planning edits only after them): `scripts/ci.sh` PASSED: toolchain; build and test in `dev-gcc`, `dev-clang`, `asan-ubsan`, `tsan`, `release-exact` (no C++ change in M7.0); clang-tidy; clang-format; ruff check and format; basedpyright; pytest (771 passed in the preceding standalone run, including the fbc tests of `rbw`/P3in/last-writer and the store-backed chain test); validation manifests; reference store (154 entries). `python3 -m harness.golden check` OK; `python3 -m harness.last_writer --check` OK.
