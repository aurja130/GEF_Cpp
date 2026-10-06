# Code map: Control flow

> Saved verbatim from the planning-session report `ControlFlowScout` (agent output, 2026-10-06), source commit `ba9f0aa`. Corrections made after the report was written are listed in `README.md` in this directory; the text below is unedited.

## Summary

GEF.bas is a single monolithic FreeBASIC program with no real `main` function. Top-level code runs in this order: setup, then a GOTO/label-driven input stage, then nested loops (input file → nucleus line → second-system covariance pass → energy step → perturbed/nominal `calcstart` loop → event loop). The functions come after the `End` statement. Includes in effect: utilities.bi, Parameters.bas, ParameterManipulation.mac (MyparRead, FitparRead, ParameterUpdate), NucPropJEFF33.bas, Spectra.bas, DCLplotting.bas (it defines B_plotting), DCLendf.bas, DCLbranchingJEFF33.bas, BEldmTF/BEexp/DEFO/ShellMO/ElmtNames, plus several includes spliced into the middle of the code (CLEARerrors, CLEARspectra, Pfistest, Branchings→CovarCUMU, ENDF.bas→ENDF_tape_description, Plotting.bas). Dead code: ENDF_EOT.bas, the GEFSUB block, B_EgammaA, and on Linux Mutex.bas and the GUI. In the sequence file, line 1 is Fenhance (×1e5 events) and line 2 is the energy list. With error analysis, N_par = Int(sqrt(100·Fenhance)) = 31 and N_stat = Fenhance·1e5/31 = 32258. ENDF n-induced runs use N_E_steps = N+3 (thermal limits pass, max-E limits pass, N energies, final thermal pass that finalizes the tape). The first thermal-only tape in the validation ENDF file is almost certainly left over from an earlier single-energy process (thread 1). Its output was appended because files are opened For Append and never deleted, and the same stale ctl/thread.ctl explains why this run got 'thread number 2'.

## Architecture

How the program is executed (FreeBASIC compiles top-level code in order; `#include`s are spliced in textually and often inside loops). Order: compile flags (B_delayed on, B_EgammaA off) → mkdir ctl/out/tmp/dmp/GRAF/BestFit/External → Declares and the `await` sub → globals → Parameters.bas and ParameterManipulation → NucPropJEFF33 → `StartAgain:` analyzer array allocation and data tables → `Prompting:` thread assignment via ctl/thread.ctl → `RepeatInput:` dialogue (only when there is no file.in) → `Nextfitloop:` FitparRead and perturbation widths → read the file.in list → loop over input files (parse the sequence file) → loop over nucleus lines (skip/register in done.ctl, choose Emode and N_E_steps) → loop over I_Double_Covar (re-include Parameters.bas, set file names) → loop over I_E_step (pick energy and B_Error_On, run the multi-chance pre-pass) → `calcstart:` (event count and perturbed vs nominal parameters → event loop → take the sync.ctl lock → write ptb/out, mvd, Branchings, ENDF, dmp → release the lock → I_Error++ and GoTo calcstart until 31 perturbed + 1 nominal are done) → Next. Processes coordinate only through files in ctl/ plus 100-ms time slots derived from the Timer offset stored by thread 1.

## Files

### `Reference/GEF_code/source/GEF.bas`

The whole main program (lines 1–15670) plus about 120 functions (15691–18176). Holds the file.in and sequence-file parsing, the thread/done/sync control files, the energy-step and perturbed-run loops, the event loop, and output to out/ptb/mvd/dmp.

### `Reference/GEF_code/source/ENDF.bas`

Spliced in at GEF.bas:14711 (inside `#If B_delayed`, `If B_ENDF=1`). Writes the ENDF-6 MF1/MF8 MT454/459 tape ENDF/GEFY_Z_Atarget_n.dat. Per-step flags at 387-452; tmp/CUMU<thread>.dat buffer for cumulative yields; EOT at 1543-1550.

### `Reference/GEF_code/source/DCLendf.bas`

Included at GEF.bas:1282. Creates ENDF/, declares fENDF/fCUMU/CGEFY*, and defines the ENDF number formatters CDouble/CInteger/CTrailer and Testprint.

### `Reference/GEF_code/source/Branchings.bas`

Spliced in at GEF.bas:14704 and 14836. Decay branchings and cumulative yields (writes the <Delayed>/<Cumu> sections to the out file); includes CovarCUMU.bas (Branchings.bas:993).

### `Reference/GEF_code/source/NucPropJEFF33.bas`

The NucProp variant actually included (GEF.bas:1052): nuclear properties/isomers and I_MAT_ENDF. Includes NucProp_Functions.mac (writes IMATmax.ctl).

### `Reference/GEF_code/source/DCLbranchingJEFF33.bas`

The DCLbranching variant actually included (GEF.bas:1284) for decay data.

### `Reference/GEF_code/source/Parameters.bas`

Nominal model parameters. Included at GEF.bas:1015 and re-included for every system at 3320 (when B_Fit=0).

### `Reference/GEF_code/source/ParameterManipulation.mac`

Included once at GEF.bas:1017: MyparRead.bas, FitparRead.bas, ParameterUpdate.mac (writes tmp/ParameterUpdate.dat).

### `Reference/GEF_code/source/ParameterUpdate.mac`

Writes tmp/ParameterUpdate.dat, a copy of the current nominal parameters in Parameters.bas format. Runs at startup and on fit improvement (GEF.bas:2543).

### `Reference/GEF_code/source/DCLplotting.bas`

Included unconditionally at GEF.bas:1280. Line 1 `#define B_plotting`, so the plotting code is compiled in but disabled at runtime in batch mode (Bplot=0 at GEF.bas:2721).

### `Reference/GEF_code/source/Mutex.bas`

WaitSynch_GUI only. Included only `#ifdef __FB_WIN32__` (GEF.bas:441-444), so it is unused on Linux.

### `Reference/GEF_code/source/CLEARerrors.bas`

Resets the error accumulators (_d_NZPOST, d_APOST, d_TKE…) at the start of each energy step (GEF.bas:3446).

### `Reference/GEF_code/source/CLEARspectra.bas`

Resets the spectra at every calcstart pass (GEF.bas:4816).

### `Reference/GEF_code/README.md`

Batch-input format (lines 290-420); N_par/N_stat table (lines 159-200); output folders (lines 107-115).

### `validation/test_run/run.log`

Evidence: 'thread number 2' (line 13); per-energy fission-chance passes; final thermal pass (tail).

### `validation/test_run/ENDF/GEFY_86_214_n.dat`

Tape 1 is lines 1-857 (EMAX 2.53e-2 eV, LE+1=1, EOT at 857). Tape 2 starts at 858 (EMAX 3e7 eV, LE+1=59).

## Report

Paths below are relative to Reference/GEF_code/source unless noted. Line numbers refer to the files as read.

## 1. Program structure

### Compile flags
- `#define B_delayed` (GEF.bas:427). It also sets the default B_ENDF=1 (433-435), but B_ENDF is reset to 0 for every input file (GEF.bas:~2880, inside the per-file reset block) and only set again by Options(ENDF) at 2970-2977.
- `B_EgammaA` is commented out (429), so StoreEgammaA (687, 18103) is dead.
- `__FB_WIN32__` blocks (GUI, Mutex.bas; 441, 1824, 1913-2158, 15633) are off on Linux.
- `B_plotting` is defined in DCLplotting.bas:1, so plotting code is compiled in. At runtime Bplot=0 in batch mode (GEF.bas:2721) unless Options(plot) is given.

### Include order (what is actually in effect)
1. file.bi, vbcompat.bi (436-437)
2. utilities.bi (439): CC_Count/CC_Cut, Extend_1/2/3dim
3. [Win only] Mutex.bas (442)
4. Parameters.bas (1015)
5. ParameterManipulation.mac (1017) → MyparRead.bas, FitparRead.bas, ParameterUpdate.mac
6. NucPropJEFF33.bas (1052) → NucProp_Functions.mac
   - Not included: NucPropJEFF311, NUBASE2016/2020 (1051, 1057-1058), and the alternative `#If` block at 1062-1068, which is entirely inside a comment.
   - Not included anywhere: NucPropf/mf/x.bas.
7. Spectra.bas (1278)
8. DCLplotting.bas (1280)
9. Under B_delayed: DCLendf.bas (1282) and DCLbranchingJEFF33.bas (1284). JEFF311 and NUBASE20 are commented out.
10. BEldmTF.bas, BEexp.bas, DEFO.bas, ShellMO.bas (1559-1565); ElmtNames.bas (1570)

Spliced in mid-code:
- FitparWrite.bas and ParameterUpdate.mac (2541-2543, fit only)
- FitparRead.bas (2555)
- Parameters.bas again (3320)
- CLEARerrors.bas (3446)
- Pfistest.mac (4171, 4205)
- CLEARspectra.bas (4816)
- Branchings.bas (14704, which includes CovarCUMU.bas; again at 14836 for External)
- ENDF.bas (14711, which includes ENDF_tape_description.bas at ENDF.bas:832/1075)
- Plotting.bas (14728/14742 for the chi-square table; 15508/15514/15560 for plots)

Dead:
- ENDF_EOT.bas: its include at 15587 sits inside the `/' … '/` comment at 15583-15589, and the file says 'not used any more'.
- Extend.bas: never included (utilities.bi has the real Extend_*).
- ENDFdata.dat: not referenced from source.
- The GEFSUB block (1621-1696) and the debug blocks (1572-1619): commented out.

### Main-program map (GEF.bas)
- 1-358: changelog
- 426-444: flags and includes
- 448-506: mkdir ctl, out, tmp, dmp, GRAF, BestFit, External
- 513-746: Declares
  - `await` (698-708): spins until `Int((Timer-Timeoffset)*10) Mod (I_thread_max+1) = I_thread`, i.e. 100-ms slots.
  - Analyzer_Attributes UDT
- 749-1013: globals, e.g. I_thread (857), B_Error_On (861), N_Error_Max=10 default (863)
- 1071 `StartAgain:` — Redim Shared analyzer arrays plus Anl_Par registration (1071-1558); data tables (1559-1570)
- 1699 `Prompting:` — locals: Fenhance, `Ten_to_five=1e5` (1713), I_thread_max=8 (1761), CFthread/CFdone (1764-1766)
  - 1823-1906: file.in detection and thread assignment
- 1909 `RepeatInput:` — Windows GUI (1911-2158)
  - 2161-2517: Linux dialogue (labels RepeatNucleus 2164, RepeatReference 2188, RepeatEnergy 2287, RepeatDoubleNucleus 2429)
- 2519 `Nextfitloop:` — fit bookkeeping (2519-2554); FitparRead (2555); Var_* perturbation sigmas (2575-2623)
- 2698-2763: read file.in
- 2768 `For Ifilein` → 2776-3126 parse sequence file
- 3136-3283 `For Iline`: done.ctl check/register (3166-3223); Emode and N_E_steps (3226-3281)
- 3287 `For I_Double_Covar`
  - 3320: Parameters.bas reset
  - 3340-3388: barrier printout; unbound CN → `Goto Next_Iline_label`
  - 3393-3440: CFileout name
- 3442 `For I_E_step`
  - 3446: CLEARerrors
  - 3449-3495: energy and B_Error_On per step
  - 3497-3533: Csystem name
  - 3535-3588: isomer
  - 3600-3693: E-spectrum file
  - 3697-3860: target spin, CN spin, Eabsgs
  - 3882-3906: clear CN spectra
  - 3910-~4800: multi-chance pre-pass (labels Dice_I_Estep 4244, Aftergamma 4265, Repeat_multi 4560, REpkin 4615, REnkin 4643)
- 4805: `B_Error_Analysis = B_Error_On`
- 4811 `calcstart:`
  - CLEARspectra; lmd header (4819-5050)
  - Event count (5054-5084)
  - Parameter perturbation `P_x = PGauss(_P_x, Var_P_x)` (5095-5165); tmp/<CFileout>.par (5166-5281); storing for the second system (5283-5380); nominal restore `P_x = _P_x` (5434ff)
  - IEVTtot=0 (5497)
  - Loops: `For I_E_Distr` (5522) / `I_N_Multi, I_Z_Multi, I_E_Multi` (5526ff) / `Energy_loop:` (5533)
  - Physics labels: DiceA 7960, Next2 7974, Repeat_E_Q 8341, J_attempt 8676, TKEsci_again 8862, Nochmal 8916, Repeat_Eg_light/heavy 9281/9400, `SkipEvent:` 9982; loops close at 10004
- 10035-10053: sync.ctl lock
- 10056-10078: open the ptb or out file
- 10080-~14700: results text (10437-10760: error accumulation and mvd; the final nominal pass computes covariances by re-reading the mvd, 10733ff)
- 14704: Branchings.bas; 14711: ENDF.bas
- 14715-14775: chi-square; 14776-14840: External/ cumulation
- 14842: Close #f
- 14844-15460: dmp dumps (only when B_Error_Analysis=0)
- ~15466-15471: release sync
- 15474 `NewPlot:` → error loop 15527-15553 (`I_Error+=1`; at `=N_Error_Max` sets B_Error_Analysis=0; `GoTo calcstart` while `I_Error<=N_Error_Max`)
- Loop ends: 15581 Next I_E_step; 15591 Next I_Double_Covar; 15593 `Next_Iline_label:`; 15594-15596 Next Iline/Ifilein
- 15597-15612: fit loop → `GoTo Nextfitloop`
- 15613-15670: exit (batch: kin="Q"; prints 'GEF is terminated', then Sleep)

### Functions (GEF.bas, after End)
- 15691 Find_IAnl; 15709 U_DMP_1D; 15770 U_DMP_1D_S
- 15814 U_Valid; 15836 U_Delta_S0
- 15862 Getyield; 15923/15929 F1/F2; 15936/15965/16005 Masscurv/1/2
- 16047 De_Saddle_Scission; 16065 TKE_Viola; 16072 TEgidy; 16098 TRusanov
- 16110 LyMass; 16140 LyPair; 16154 TFPair; 16176 Pmass; 16197 FEDEFOP; 16211 FEDEFOLys; 16217 LDMass; 16238 AME2020
- 16261/16273/16294 U_SHELL/_exp/_EO_exp; 16310 U_MASS; 16326 ECOUL
- 16358/16368 beta_light/heavy; 16379 Z_equi; 16429 Beta_opt_light; 16480 Beta_Equi
- 16650 Eva (neutron/gamma evaporation); 16907 u_accel; 16962/17056 P_Egamma_low/high
- 17094 U_Ired; 17110 U_IredFF; 17120 U_I_Shell; 17173 U_alev_ld
- 17180/17205/17225/17261 U_levdens_old/levdens/Egidy/FG; 17335/17388 U_Temp/U_Temp2
- 17439-17477 GDR, GgGtot; 17490 E_next; 17559 Pexplim; 17580 U_Even_Odd; 17593 EVEN_ODD
- 17657/17752/17775 BFTF/BFTFA/BFTFB; 17798 Acentral; 17808 Gaussintegral; 17818 Bell
- 17830-17864 U_Box/U_Gauss*; 17877-18051 random samplers (PBox, PBox2, PPower*, PGauss (Box-Muller with static ISet), PLinGauss, PExp, PMaxwell*)
- 18052-18091 Floor, Ceil, Round, Modulo, PLoss; 18104 StoreEgammaA (dead); 18128 Printcomments

## 2. Input handling

### file.in (GEF.bas:2698-2763)
- Each non-comment line is the name of a sequence file; surrounding quotes and trailing `'` comments are stripped.
- `'` lines are skipped; `END` stops reading.
- `FIT` and `NITER(n)` lines are also accepted here.
- At most 1000 entries.

### Sequence file (GEF.bas:2775-3126)
**Line 1:** `Input #Ffilein, Fenhance_global` (2777). This is the statistical enhancement factor: events = Fenhance·1e5 (3128, 3695, 5082).
- ' 10' → 1e6 nominal events.
- ' 100' (the SF example) → 1e7.

**Line 2:** `Line Input` energy table (2778).
- A quoted string is the name of an E* spectrum file (ES/EM only; 2780-2788).
- Otherwise a comma list; an optional `k:` prefix sets I_first_E_step, used only in random-file names (2790-2793).
- An optional `E/spin` per entry is allowed only for GS/EB (2798-2809).
- Energies must be strictly ascending (2811-2819). En_min/En_max = first/last (2822-2823).
- ' 0' with "GS" → Emode=1, P_E_exc=0 → spontaneous fission ('_sf', ground-state spin imposed at 3703-3720).

A per-file reset follows (2825-2840): B_Error_On, Brec, Bcov, Bcor = 0; B_supp=1; B_ENDF=0; B_Random_On=0; lmd off; localoff; I_Mode_selected=-1.

**Remaining lines** (blank and `'` lines skipped):
- `Options(a,b,...)` (2845-2985). Keywords: PLOT, MYPARAMETERS, LOCAL, GLOBAL, NOSUPP, ERR, DPARFAC(x) (flagged 'not yet available'), PTB (Brec=1, implies err), RANDOM (B_ENDF=1, err, B_Random_On=1), COV, COR, LMD, LMD+, NEO (EOscale=0), ENDF (2970: B_ENDF=1 **and B_Error_On=1**, i.e. ENDF implies error analysis).
- `FIT(obs)`, `NITER(n)`, `MODE(i)` (2989-3030).
- `END` stops reading.
- A 3-field line `Z, A, "CE"` (3034-3070). A may be a range `A1-A2` or `A1-A2+step` (3040-3056).
- A 6-field line `Z, A, Z2, A2, E2|"spectrumfile", "CE"` defines a correlation between two systems (3071-3113).

**A is always the CN mass.** Kind of fission (3226-3281):
- EB → Emode=0
- GS → 1
- FC → -1
- ISn → 1 (spontaneous fission from isomer n)
- EN[n] → 2 (n = target isomer)
- EP → 12
- EA → 22
- ES → 3 (forces B_ENDF=0)
- EM → 13

For EN with ENDF: `N_E_steps = N_E_Values + 3` if there is more than one energy, else 1 (3249-3257). With 'random' and a single energy, N_E_steps=2.

**Target vs CN naming:**
- For Emode 2 the target is (Z, A-1) (3549, 3746-3748). E* = En·(A-1)/A + M(Z,A-1) − M(Z,A) (3800).
- out/dmp/tmp names use the CN: CFileout `GEF_<Z>_<A>_n` (3397-3410); Csystem `Z<Z>_A<A>_n_E<Str(P_E_exc)>MeV` (3497-3533). Note FreeBASIC `Str(Single)` formatting, e.g. '2.53e-08', '0.1', '19.5'.
- ENDF uses `A_target = P_A_CN - 1` (ENDF.bas:103) → `ENDF\GEFY_86_214_n.dat` (ENDF.bas:644-653). MAT = I_MAT_ENDF(Z, A_target) + I_E_iso (ENDF.bas:332).

### Parameter-file caveat [INFERENCE — verify]
- MyparRead runs only at 1017, before B_MyParameters is set by Options (2866).
- Parameters.bas is re-included for every system at 3320 when B_Fit=0. That overwrites values loaded from Fitpar.dat at 2555.
- So in non-fit batch mode, MyParameters.dat and Fitpar.dat may not actually take effect, despite the comments at 2556-2569 and 3318-3319.

## 3. Multi-process coordination
- Several GEF processes are started by hand in the same directory, all reading the same file.in.

**Thread assignment** (1823-1906):
- If ctl/thread.ctl exists and its first value is 1: read Timeoffset (second field), then the last listed thread number; `I_thread = last + 1`; append it to the file.
- If the file is missing: I_thread=1; write `1, Timeoffset=Timer` (Output mode).
- `I_thread > I_thread_max` (8, at 1761) aborts.
- GEF never deletes thread.ctl or done.ctl (no Kill anywhere).
- So 'thread number 2' means a stale ctl/thread.ctl was left by an earlier thread-1 process; GEF prints this hint itself at 1898-1902.
- The validation ctl/ now holds only sync.ctl, so thread.ctl and done.ctl were presumably removed afterwards [INFERENCE].

**Work split** (3141-3223): granularity is one nucleus line (all energies of that system).
- Before each line, wait for this thread's `await` slot, then read ctl/done.ctl records `Z, A, En_max, Fenhance, I_Mode_selected`.
- If a match is found, skip the line; otherwise append the record and compute it.
- Nothing is split within one system.

**sync.ctl:**
- A global 0/1 output lock: spin with `await` until it reads 0, then write 1 (10035-10052) before writing out/ptb/mvd/ENDF/dmp.
- Reset to 0 after the dmp section (~15466-15471), before each `GoTo calcstart` (15541-15547), after each energy step (15573-15579), and in the fit loop (15601-15607).
- `await` is a 100-ms time-slot scheme with cycle (I_thread_max+1)·0.1 s, keyed to thread 1's Timer stamp (698-708).

**Other per-thread files:**
- tmp/CUMU<I_thread>.dat (ENDF.bas:666) — hence CUMU2.dat in the validation run.
- tmp/Fitlog<I_thread>.dat (2529).
- Mutex.bas is only the Windows GUI timer (WaitSynch_GUI), unrelated to Linux.

## 4. Per-energy loop, event counts, ENDF two-tape issue

**Energy-step semantics** (GEF.bas:3459-3495), EN + ENDF with N energies, N_E_steps = N+3:
- step 1: En_min, B_Error_On=0 (nominal only)
- step 2: En_max, nominal only
- steps 3..N+2: Energy_table(step−2), B_Error_On=1
- step N+3: En_min again, nominal only

This matches the ENDF.bas comment (39-50) and the flags (ENDF.bas:420-451):
- Steps 1-2: B_acc_limits (sum NZPOST and cumulative yields into NZPOSTSUM/NZCUMUSUM, 479-494). Step 2 also sets B_find_limits (510-597): nuclide (Z,N) ranges with sum > 1.5·Racc. These ranges are needed because the ENDF NFP counts must be known before writing.
- Step 3: B_n_header + title + B_IY + B_CY_write.
- Steps 4..N+2: B_IY + B_CY_write; cumulative yields go to tmp/CUMU<thr>.dat (1359-1477).
- Step N+3: B_CY_read copies CUMU into the tape (1514-1531) plus B_write_EOT (1480-1511, 1543-1550).

**ENDF write condition** (ENDF.bas:89):
- ENDF.bas writes only when `B_Error_Analysis=0 Or B_Random_On=1`, i.e. only in the nominal pass of each step. With 'random', each perturbed set goes to `GEFY_..._E<k>_R<i>.rnd` (674-676).

**Perturbed/nominal loop:**
- `B_Error_Analysis = B_Error_On` (4805); `calcstart:` (4811).
- With B_Error_Analysis=1 (5059-5071): `N_Error_Max = Int(sqr(Fenhance*100))` → 31 for Fenhance=10; `NEVTtot = Fenhance*1e5/N_Error_Max` → 32258 (truncated by LongInt assignment). README Table 1 (README.md:168-189) gives the same numbers.
- Nominal: NEVTtot = Fenhance·1e5 = 1e6 (5082).
- After each pass (15528-15552): `I_Error += 1`; when `I_Error = N_Error_Max`, set B_Error_Analysis=0 and run one more pass, which restores the nominal parameters at 5434ff.
- I_Error and the error accumulators are reset at the start of every energy step (3446-3447).
- Perturbed passes reuse the multi-chance result, because calcstart sits after the pre-pass (comment at 3886-3890).

**Fission-chance pre-pass** (3910-~4800):
- Not specific to 30 MeV. It runs at every step where Eabsgs ≥ Eexc_min_multi = min(Sn + Bf(A−1), Sp + Coulomb + Bf(Z−1,A−1)) − 3 MeV (3950-3967), or when Emode=13.
- It uses `N_multi_sample = sqr(Fenhance)·1e5` (3926).
- In the run it shows up at step 2 (30 MeV) and at every energy from 12.5 MeV upwards (run.log:65, 6125…11202).

**Why two concatenated tapes:** a single process produces exactly one tape.
- Tape 1 (ENDF file lines 1-857) has EMAX=2.53e-2 eV and LE+1=1. This is the N_E_steps=1 path: ENDF.bas:399-407 with B_CY_direct and EOT, and GEF.bas:3459-3462 with B_Error_On=1.
- That requires a run whose energy list was thermal only, i.e. a previous process.
- Evidence that it came from that earlier process:
  - out/GEF_86_215_n.dat begins with a thermal block 'Output written on 18:19:38' that has ± errors. The logged run's first event is 18:20:48, and its own step-1 block (18:21:13) has no errors.
  - run.log never prints 'Subfolder \\dmp\\Z86_A215_n_E2.53e-08MeV created' (that folder already existed), while every other energy folder is reported as created.
  - There is no CUMU1.dat (single-energy tapes write cumulative yields directly).
  - The stale thread.ctl explains thread 2.
- The file kept tape 1 because ENDF files are opened `For Append` (ENDF.bas:676/678/1521/1546). The out/ptb/dmp/par files are also appended, and GEF never deletes outputs (README.md:107).
- Tape 2 starts at line 858: EMAX=3e7 eV, LE+1=59 (E_steps = N_E_steps−3, ENDF.bas:98-102).

**Side effects to keep in mind:**
- The step 1, step 2 and step N+3 nominal runs all append full results to out/GEF_86_215_n.dat and to dmp/<Csystem>/*.dmp. Thermal appears three times from this process: steps 1, 3, 62.
- The final thermal 1M-event run exists only to close the ENDF tape (it writes no MT454 data).

## 5. Output files
- **out/<CFileout>.dat** (e.g. GEF_86_215_n.dat): `Open Cfileout_full For Append` (10077), nominal passes only. Main ASCII results, uncertainties when error analysis is on, the Branchings <Delayed>/<Cumu> sections, and chi-square tables (14715-14775). Paths are written as `out\...`; the FreeBASIC runtime maps `\` to `/` on Linux.
- **tmp/<Csystem>.ptb**: perturbed passes (10063-10075), opened For Output, so only the last perturbed set (#31) per energy survives. The file says so in its header. With the `ptb` option it is instead out/<Csystem>.ptb, For Append (10061). Content is the same result printout headed 'Results of perturbed calculations / Parameter set #'.
- **tmp/<Csystem>_Single.mvd** (10633-10730): written during perturbed passes inside `If B_Error_On=1 And B_Error_Analysis=1` (10437-10438). Output mode at I_Error=0, then Append. Per set it holds the `*Z*` Y(Z), `*A*` Y(Apre)/Y(Apost) and `*AZ*` Y(A,Z)pre/post tables. In the final nominal pass it is **read back** twice (10763, 10815) to build the covariances and correlations. So it is an intermediate data channel, not just a dump; a port can keep this in memory.
- **tmp/<CFileout>.mvd**: only for a two-system covariance (B_Double_Covar) (10742-10750).
- **tmp/<CFileout>.par** (e.g. GEF_86_215_n.par): perturbed parameter values for each set (5166-5281), Append mode, with a header at I_Error=0.
- **dmp/<Csystem>/*.dmp** (14844-15460): only when B_Error_Analysis=0, For Append. SATAN analyzer dumps written via U_DMP_1D (15709): EMpot, Multichance, Aprov, Apre, Apost, Ekin, ZApre, ZApost, Zpost, Npre, Npost, ZPolarpre/post, SigmaZpre/post, NA, EN, NP, NN, DPlocal, DNlocal, Egamma, Decay (B_delayed), EgammaA (B_EgammaA), Ngammatot, Eexc, Qvalues, XE. The folder is created via CHDIR/MKDIR (14875-14882).
- **tmp/CUMU<thread>.dat**: ENDF.bas buffer for MF8/MT459 cumulative yields across energies (ENDF.bas:666; Output on first write 1364, then Append; SEND/FEND/MEND lines at 1480-1511), copied into the tape at the last step (1514-1531).
- **ENDF/GEFY_<Z>_<Atarget>_n.dat**: the ENDF-6 tape. MF1/MT451 header lines (920ff) with ENDF_tape_description.bas; MF8/MT454 independent yields per energy (1170-1246); MF8/MT459 cumulative yields from CUMU; tape EOT line ' … -1 0  0    0' (1543-1550).
- **tmp/ParameterUpdate.dat**: ParameterUpdate.mac (lines 10-12, Output mode). Parameters.bas-format dump of the nominal parameters including Fitpar/MyParameters overrides; written at startup (via GEF.bas:1017) and when a fit improves (2543).
- **Others:** tmp/<CFileout>.pfis/.pfis2 (4151-4181, fission-probability test output); out/Work.dat (14124); IMATmax.ctl (NucProp_Functions.mac:19); ctl/thread.ctl, done.ctl, sync.ctl (section 3); out/*.lmd (lmd option, 4821).
