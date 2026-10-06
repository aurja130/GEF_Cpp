# Code map: Outputs

> Saved verbatim from the planning-session report `OutputScout` (agent output, 2026-10-06), source commit `ba9f0aa`. Corrections made after the report was written are listed in `README.md` in this directory; the text below is unedited.

## Summary

I mapped everything GEF does after the event loop. Each perturbed or nominal pass runs GEF.bas:10035-15555, which writes the results file and the per-pass mvd/par/ptb files and runs Branchings.bas (with CovarCUMU.bas), ENDF.bas, the chi-square block, the External/ block and the dmp dumps. It covers about 5,500 lines in GEF.bas and about 4,000 more in the include files, not counting data tables. It splits into about 20 components that can be ported and tested on their own. Several have clean seams that need no RNG: FreeBASIC (FB) text formatting, covariance computed from the mvd text, the decay sweep in Branchings, the ENDF writer, and the isomer split.

**What T4 depends on:**
- **Single precision and text formatting.** Outputs are formatted from Single (float) values and accumulated in float. Examples: ENDF yields print as 1.999998-6 rather than 2.000000-6, and out yields print as 1.496599.
- **Covariances are computed from text.** They are recomputed from the mvd file after it has been written and read back, so values are already rounded to 5 decimals or 7 significant digits. Matching the text exactly requires the C++ port to round the same way.

**Quirks confirmed against the validation output:**
- **Uncertainty cap does not work.** The 100% cap on independent-yield uncertainties prints σ+Y instead of capping at Y, because the accumulate function `Acc_d_ZISOPOST(0,…)` adds where it should set (GEF.bas:11383-11391). In the validation output, Y=0.0001 prints dY=0.000657 = 0.000557 + 0.0001.
- **EdefoA is always zero.** The bounds check uses `UBound(EdefoA,I)`, i.e. dimension I (GEF.bas:10245). XE.dmp shows `X = 0 TO 1`, `0,0,`.
- **ZApre.dmp and ZApost.dmp data rows go through a closed file number.** They are written to `#f` after it was closed at 14842. This works only because `Freefile` hands the same number to the dmp file, and the validation dmp files do contain the rows.

Other suspect code is flagged in the report, e.g. the Apost two-system normalisation loop that uses the Apre bounds, TXE's uncertainty printing d_TKEpre, the R_alpha overwrite in Branchings, the 3rd-isomer fallback, the lmd heavy-fragment velocity, and the RNG draws made by the lmd output.

## Architecture

Every pass after the event loop (one perturbed set or the final nominal pass) runs the same linear tail of GEF.bas:

1. sync.ctl lock, then open #f (ptb when perturbed, out when nominal).
2. Projections, which fill the mean-per-A arrays.
3. Uncertainty code, branching on two flags:
   - Perturbed pass (B_Error_On=1, B_Error_Analysis=1): accumulate Σ and Σ², then append one set to `_Single.mvd`.
   - Final nominal pass after N_Error_Max sets: read `_Single.mvd` back, build the covariance and correlation matrices and the d_*(0) σ, and optionally run the two-system covariances via tmp/<CFileout>.mvd.
4. Out writer into #f. Before printing, it normalises arrays in place (ZISO* to 200%, NN* to probabilities) and computes the isomer split, which fills Isotab.R_Prob.
5. Branchings.bas: decay of NZPOST through R_Prob into NZIcumu; nu_delayed; antineutrinos; d_NZIcumu; it includes CovarCUMU.bas (*AZcumu* mvd round-trip).
6. ENDF.bas (nominal pass, or every pass with RANDOM): a state machine over I_E_step with Static state. It accumulates nuclide limits in steps 1-2, writes MF1 and MT454 directly to ENDF/GEFY_<Z>_<Atarget>_<s|n>.dat, buffers MT459 in tmp/CUMU<thr>.dat, and copies the buffer plus TEND at the last step.
7. Chi-square via Plotting.bas, Comments, closing tags.
8. External/ cumulation, which re-runs Branchings.
9. Close #f, then the dmp dumps (nominal only).
10. Release sync, then `I_Error+1` and GoTo calcstart.

All result files are opened for Append, except the ptb (Output) and the first mvd set (Output). The dependency order is: projections → accumulators/mvd → covariances/σ → out printing (with in-place normalisation and R_Prob) → Branchings/CovarCUMU → ENDF → dmp.

## Files

### `Reference/GEF_code/source/GEF.bas:10035-10078`

Takes the sync.ctl output lock, then opens the result file. Perturbed passes go to tmp/<Csystem>.ptb (For Output, keeps only the last set) or, with PTB, to out/<Csystem>.ptb (Append). The nominal pass appends to out/<CFileout>.dat.

### `Reference/GEF_code/source/GEF.bas:10080-10427`

Projects 2-D histograms to means per A: NmultiApre/post, NApre/post, ENApre/post(fs), EdefoA (bug at 10245), EintrA, EcollA, EkinApre/post, TKEApre/post, QA.

### `Reference/GEF_code/source/GEF.bas:10429-10632`

Error accumulators for perturbed passes: Σ and Σ² of d_APost, d_ZPost and d_ZISOPOST, plus 14 scalar means (d_NCN … d_TotXE).

### `Reference/GEF_code/source/GEF.bas:10633-10738`

Writes tmp/<Csystem>_Single.mvd (header and *Z*/*A*/*AZ* blocks). Accumulates d_NZPOST Σ and Σ².

### `Reference/GEF_code/source/GEF.bas:10739-11428`

Final nominal pass. Reads the mvd back twice and builds Z/Apre/Apost/ZApre/ZApost covariance and correlation matrices (Single). Writes deviations to tmp/<CFileout>.mvd for two-system runs. Finalises all σ (d_*(0)), including the broken ZISOPOST cap.

### `Reference/GEF_code/source/GEF.bas:11431-11938`

Two-system covariances (I_Double_Covar=2) read from tmp/<CFileout>.mvd. Bugs at 11651-11652 (uses Apre bounds) and 11905 (rms_ZA_Double has the wrong dimension).

### `Reference/GEF_code/source/GEF.bas:11943-14663`

XML-like out/ptb writer: Title, Prompt_results subsections, Control. Normalises some arrays in place first: ZISOPRE/ZISOPOST to 200%, and NN* multiplicities to probability.

### `Reference/GEF_code/source/GEF.bas:14212-14301`

Isomeric yields. Sums JFRAGpost over the Isotab R_lim spin windows (Single loop variable used as an index) and sets Isotab.R_Prob, which Branchings and ENDF consume. Clamps R_lim to 50 permanently.

### `Reference/GEF_code/source/GEF.bas:14700-14775`

Includes Branchings.bas and ENDF.bas. Chi-square block (Plotting.bas included 8 times), Printcomments, and the closing GEF1/GEF2/GEF tags.

### `Reference/GEF_code/source/GEF.bas:14776-14842`

External/<Csystem>.dat: replaces _NZPOST with the external yields and re-runs Branchings, writing an <External> block after </GEF>. Closes #f.

### `Reference/GEF_code/source/GEF.bas:14844-15465`

dmp/<Csystem>/*.dmp SATAN dumps (nominal pass only, Append) via U_DMP_1D. ZApre/ZApost rows are written through the closed #f, which aliases the dmp file number.

### `Reference/GEF_code/source/GEF.bas:15466-15555`

Releases sync and runs the perturbation loop (I_Error, GoTo calcstart). In fit mode the error loop is skipped.

### `Reference/GEF_code/source/GEF.bas:15709-15812`

U_DMP_1D / U_DMP_1D_S: SATAN analyzer text format (header lines, x-loop line, comma-joined Str(Csng(x)), line break at 128 characters).

### `Reference/GEF_code/source/GEF.bas:18064-18082`

Round(R,N): rounds a Single to N significant digits. Used throughout the out-file printing.

### `Reference/GEF_code/source/GEF.bas:4816-5048`

lmd header, written on every pass (opened Append) even when no events are written.

### `Reference/GEF_code/source/GEF.bas:9644-9980`

lmd record per event, written when nominal or Brec. Consumes Rnd (fragment and neutron angles), so enabling LMD changes the RNG stream.

### `Reference/GEF_code/source/GEF.bas:5160-5435`

tmp/<CFileout>.par record of perturbed parameters (Rdatetime never assigned). Stores Double_* arrays for the second system or the fit.

### `Reference/GEF_code/source/GEF.bas:2519-2570`

Fit loop bookkeeping: tmp/Fitlog<thr>.dat, best χ², FitparWrite and ParameterUpdate, Shell cp GRAF to BestFit, FitparRead.

### `Reference/GEF_code/source/GEF.bas:3071-3113`

Parses the 6-field two-system line (Z, A, Z2, A2, E2|"file", CE) into S_par. Activated at 3142-3150; loop over systems at 3288.

### `Reference/GEF_code/source/Branchings.bas`

1024 lines. Loads BranchTable and EndA. Splits NZPOST into isomers via R_Prob into NZIcumu. Sweeps decay on the neutron-rich side (N-Z 100→0) and the proton-rich side (0→100). Computes delayed-neutron and antineutrino output, accumulates and finalises d_NZIcumu, prints <Delayed>/<Cumu>, and writes *AZIcumu* to the mvd (never read).

### `Reference/GEF_code/source/CovarCUMU.bas`

721 lines. Builds NZcumu and ZISOcumu. Writes *AZcumu* to the mvd in perturbed passes and reads it back in the nominal pass to compute ZAcumu covariance and correlation, including the two-system case. Prints the matrices.

### `Reference/GEF_code/source/ENDF.bas`

1559 lines. ENDF-6 FPY state machine over I_E_step (387-451): limit accumulation (479-494), nuclide selection (510-597), naming (644-680), sf header (683-917), n header (920-1155), MT454 (1170-1246), MT459 direct (1253-1355), CUMU buffer (1359-1476), SEND/FEND/MEND (1480-1511), copy (1514-1531), TEND (1536-1550).

### `Reference/GEF_code/source/DCLendf.bas`

CDouble (vbcompat Format "-0.000000E+0" / "-0.00000E+00", 'E' stripped, 10.00 repair loop), CInteger (Format "#####", right-justified), CTrailer (MAT/MF/MT/NS columns), Testprint/TestprintC (flush at 66 characters).

### `Reference/GEF_code/source/ENDF_tape_description.bas`

30 fixed MF1/MT451 comment lines (embeds C_GEF_Version).

### `Reference/GEF_code/source/DCLbranchingJEFF33.bas`

NZICUMU (Single) and d_NZICUMU arrays, the BranchType UDT, U_Q_beta_minus, U_Print_an (antineutrino list plus Qbeta analyzer fill), Ibranch_for_ZAI (linear scan; -1/-2 trigger blind β+/β−), and about 4400 lines of BranchTable/EndA DATA.

### `Reference/GEF_code/source/NucProp_Functions.mac`

I_MAT_ENDF (NucTab index used as MAT; extends ctl/IMATmax.ctl), N_ISO_MAT, ISO_for_MAT, ISO_for_ZA, NStates_for_ZA, R_AWR_ENDF.

### `Reference/GEF_code/source/Plotting.bas`

2870 lines. Chi-square comparisons per known system (selected by Emode, Z, A, E) against DCLplotting DATA; GRAF .grf output; fit χ² accumulation and Fitlog.

### `Reference/GEF_code/source/DCLplotting.bas:20-131`

Yield_threshold=0.01, Chisqr_Apost (Chilin uses the evaluation dY; ChiGEFlin uses d_Apost(0); both divided by N), PrintChisqr, Ploteval.

### `Reference/GEF_code/source/Spectra.bas:48-80,1730-1810`

Accessor and accumulator semantics of NZPOST/_d_NZPOST (indexed by N-Z) and _d_ZISOPOST. The Acc_* functions add rather than set, which is the root of the uncertainty-cap bug.

### `Reference/GEF_code/source/FitparWrite.bas;FitparRead.bas;ReadParameters.mac;ParameterUpdate.mac`

Fit-mode parameter I/O: Fitpar.dat (Append; name = value), a name→variable dispatch of about 90 parameters, and the tmp/ParameterUpdate.dat dump.

### `validation/test_run/out/GEF_86_215_n.dat`

Reference output showing the formats in practice (Print zones, Single digits) and the σ+Y uncertainty quirk (lines 362-370).

### `validation/test_run/ENDF/GEFY_86_214_n.dat`

Reference ENDF tape: CDouble format, MAT 3332, MT454 layout, float-noise yields such as 1.999998-6.

## Report

# Post-event-loop analysis and outputs (GEF.bas 10035-15560 plus the decay/ENDF includes)

## 0. Execution context, needed to reproduce state

**When the tail runs.** It runs once per pass.
- Passes per energy step: `N_Error_Max = Int(sqr(Fenhance*100))` perturbed passes (`B_Error_Analysis=1`), then one nominal pass (GEF.bas:15527-15553).
- If `B_Error_On=0`, only the nominal pass runs.
- In fit mode the error loop is never entered (it sits inside `If B_fit = 0`, 15503). With `B_Error_On=1` forced and `N_Error_Max=1`, every fit iteration is a single "perturbed" pass: its output goes to the ptb file and no covariances are computed [INFERENCE from 2729-2730, 4805, 5060-5062, 15503].

**What the perturbed passes leave behind** for the nominal pass:
- the accumulators `d_*(1)` and `d_*(2)`
- tmp/<Csystem>_Single.mvd
- `d_NZIcumu` (finalised during the last perturbed pass, Branchings.bas:913-947)
- the Static variables in ENDF.bas
- `Isotab.R_Prob` and `Isotab.R_lim`, which are mutated on every pass.

**Resets.** CLEARerrors.bas resets the `d_*` arrays at the start of every energy step (GEF.bas:3446). It does not reset `d_NZIcumu` or `d_NZcumu`; Branchings resets `d_NZIcumu` itself when `B_Error_Analysis=1 And I_Error=0` (Branchings.bas:27-40).

**In-place mutation by the printing code**, which matters for everything that runs afterwards (Branchings, ENDF, dmp):
- `_ZISOPRE` and `_ZISOPOST` are renormalised to `200*P_selected` (12774-12835). The mvd values and the accumulators were taken before this.
- `NNCN`, `NNsci`, `NNfr`, `NN`, `NNlight` and `NNheavy` are normalised to 1 (13576-13680), so NN.dmp dumps probabilities.
- `NNCNtot` and `NPCNtot` are normalised (12113-12145).
- `Isotab.R_lim` is clamped to 50, and `Isotab.R_Prob` is set (14212-14300).
- `Nmax_multi_chance`, `Pmax_multi_chance` and `Emax_multi_chance` are set while printing (12241-12268) and used by Multichance.dmp.
- External/ zeroes `_NZPOST` and refills it with the external yields (14800-14818). It runs on every pass, before the dmp dumps, so ZApost.dmp's Apost(Z) section would show the external yields [INFERENCE].

## 1. Component catalogue (porting and test units)

Format per component: lines / approximate LOC of logic / purpose / data contract (inputs → state) / dependencies / FB hazards / test seam.

### O0. FB text-formatting runtime (cross-cutting; port first)

This is the foundation for every text output. It has no source range of its own.

**Functions to emulate:**
- **`Print #f, x`** for Integer, Single and Double:
  - Non-negative numbers get a leading space; negative numbers get a sign.
  - Single values print with up to 7 significant digits; Double with up to about 15 or 16.
  - Small or large magnitudes switch to exponent form like `2.53e-08`.
  - `;` concatenates. `,` pads to the next 14-column zone. `Tab(n)` moves to a column. A trailing `;` suppresses the newline.
- **`Str()` and `Trim(Str())`**: no leading space.
- **`Print Using`** templates: `#`, `.`, `&` for strings; a `%` prefix on overflow; rounding behaviour; `-0.000000` for negative zero, which is visible in the out file's Dminus column (e.g. line 490).
- **vbcompat `Format`** with three patterns: `"-0.000000E+0"` and `"-0.00000E+00"` (ENDF), `"#####"`, and `"dd.mm.yyyy, hh:mm:ss"` (timestamps).
- **GEF's `Round(R,N)`** (GEF.bas:18064): rounds a Single to N significant digits via `Fix(x+0.5)`.
- **`Csng(Double)`** before printing.

**Hazards:**
- Exact FB float-to-decimal conversion (the 7-digit Single algorithm).
- `Print Using` rounding mode.
- The comma tab zones.
- Locale: CDouble repairs a `,` decimal separator (DCLendf.bas:63-66).

**Test seam:** a standalone FB driver that prints grids of edge values for each construct, compared with C++ byte-for-byte. Tier: T1. It needs no GEF code.

### O1. Output lock and file selection (10035-10078)

About 15 LOC of logic.
- Uses ctl/sync.ctl plus `await`. This is out of scope per the vision (replaced in-process).
- Selects the file:
  - perturbed: `tmp\<Csystem>.ptb` (Output, with a 4-line note) or `out\<Csystem>.ptb` (Append, when Brec);
  - nominal: `out\<CFileout>.dat` (Append).
- The ptb header prints `"Parameter set #"+Str(I_Error+1)`.
- Seam: none needed; this is file routing.
- T4: the ptb file is not needed (an intermediate).

### O2. Post-loop projections (10080-10427)

About 120 LOC of logic.
- **Purpose:** compute means per A from 2-D histograms.
- **Inputs:** `Nmulti2dpre/post`, `N2Dpre/post`, `ENApre2d`, `ENApost2d`, `ENApre2dfs`, `ENApost2dfs`, `Edefo2d`, `Eintr2d`, `Ecoll2d`, `AEkinpre/post`, `ATKEpre/post`, `AQpre`.
- **Outputs:** `NmultiApre/post`, `NApre/post`, `ENApre/post`, `ENAprefs/postfs`, `EdefoA`, `EintrA`, `EcollA`, `EkinApre/post`, `TKEApre/post`, `QA`.
- **Consumers:** the out NmultA section and dmp NA/EN/Ekin/XE/Qvalues.
- **Bins:** bin centres `(0.1*J+0.5)` for Edefo/Eintr/Ecoll (note: not `0.1*(J+0.5)`) and `(J+0.5)` for Ekin/TKE/Q.
- **Hazards:**
  - **BUG at 10245:** `UBound(EdefoA,I)` uses dimension I, so only I≤1 is ever filled. Confirmed in validation XE.dmp: `A: (X = 0 TO 1 BY 1)`, `0,0,`.
  - EcollA, EkinA, TKEA and QA keep their zero when `Nenner=0` (handled by the reset loop).
- **Seam:** probe-dump the arrays, or compare XE/NA/EN/Ekin/Qvalues.dmp. Deterministic given the histograms (T1-style with injected histograms).

### O3. Per-pass uncertainty accumulators (10437-10632, 10719-10727)

About 110 LOC.
- **Gate:** `B_Error_On=1 And B_Error_Analysis=1`.
- **Accumulated per pass:**
  - `d_APost(1|2,A)` for A=20..P_A_CN-20, `d_ZPost(1|2,Z)` for Z=10..P_Z_CN-10, only where >0;
  - `Acc_d_ZISOPOST(1|2,A,Z)` and `Acc_d_NZPOST(1|2,N,Z)` (all cells);
  - scalar means of NNCN, NNsci, NNfr, NNlight, NNheavy, Ntot (=CN+sci+fr), ENfr (`I/1000` keV→MeV), Ngammatot, _Egamma, _Egammatot, Qvalues, TKEpre, TKEpost, TotXE.
- These read the raw (unnormalised) histograms.
- **Hazards:**
  - Division by zero gives NaN if a histogram is empty.
  - `Csng(I)` conversions.
  - Accumulation order in Double.
- **Seam:** a probe after each pass dumping `d_*(1..2)` at full precision. Deterministic given the histograms.

### O4. mvd writer (10633-10718) and its siblings

About 90 LOC.
- **File:** tmp\<Csystem>_Single.mvd. Opened for Output when `I_Error=0`, Append otherwise.
- **Header:** 4 comment lines, timestamp, `Print Using "& ### & ###"`, Emode text (same as the out Title but with a `*` prefix), set number.
- **Blocks:**
  - `*Z*`: `Using "####    ####    ###.#####"`, values `(set, Z, ZPOST)` for Z=10..P_Z_CN-10 where ZPOST>0.
  - `*A*`: `"####        ####         ###.#####        ###.#####"`, values `(set, A, APre, APost)` for A=20..P_A_CN-20.
  - `*AZ*`: default Print with comma zones, `I_Error+1, A, Z, Csng(ZISOPRE); Tab(60); Csng(ZISOPOST)`.
- **Siblings appended by later code:**
  - CovarCUMU appends a `*AZcumu*` block: `set, A, Z, Csng(ZISOcumu)` (CovarCUMU.bas:57-84).
  - Branchings appends `*AZIcumu*`: `set, A, Z, iso, NZIcumu` (Branchings.bas:997-1021). Nothing reads it.
- **Critical hazard:** the covariances in O5 and O12 are computed from these parsed text values. Z and A yields are quantised to 5 decimals; AZ yields to Str(Single) with 7 significant digits. A text-exact covariance port must either reproduce this round trip or quantise identically.
- Only lines with Y>0 are written. A nuclide missing from any set gets `Nval ≠ N_Error_Max`, and its covariance is forced to 0.
- **Seam:** the mvd file itself is an excellent probe. Compare the C++-written mvd with the BASIC one under a T3 seed. With independent seeds, compare statistically.

### O5. Single-system covariances and final σ (10739-11428)

About 300 LOC, written as 5 near-identical blocks; generic code in C++.
- **Steps:**
  1. Read the mvd twice: count lines, then parse with `CC_cut(" ")` and `Cast(Integer/Single, field)`.
  2. Per observable (Z, Apre, Apost, ZApre, ZApost): mean and rms per coordinate, with `rms = sqr((Σy²-(Σy)²/N)/(N-1))` and `VZmean`/`VZrms` stored as Single.
  3. Covariance: an O(n²) loop over all record pairs with equal IParameter, accumulated into `OCovar.Rval` (Single) and `Nval`.
  4. Keep only cells with `Nval = N_Error_Max`, divided by (N-1). Correlation = cov/(rms_i·rms_j) when both rms ≠ 0.
  5. ZA matrices are indexed `(Z, A-Amin(Z)+1, Z2, …)` with `VAprelim`/`VApostlim`.
- **Outputs:** `SZCovar/Corr`, `SApre*`, `SApost*`, `SZApre*`, `SZApost*` with limits `Zmin`, `Zmax`, `Apremin`, …, `VAprelim`, `VApostlim`. When `B_Double_Covar` is set, it also writes `tmp\<CFileout>.mvd` lines `system, set, tag, d1, d2, deviation` with comma zones.
- **Final σ (11346-11428):**
  - `d_APost(0)` for A=20..190 and `d_ZPost(0)` for Z=20..70 (not 10..; Z accumulates over 10..P_Z_CN-10).
  - `d_ZISOPOST(0)` and `d_NZPOST(0)`.
  - 14 scalars, each `sqr((Σ2-Σ1²/N)/(N-1))`.
  - Cap: σ>Y or σ=0 → σ=Y.
- **BUG, confirmed:** `Acc_d_ZISOPOST(0,…)` *adds* (Spectra.bas:1788-1800), so the "cap" becomes σ+Y, and the printed σ=Y case is really 0+Y (11383-11391). Validation out line 362 shows Y=0.0002 with dY=0.000757 = 0.000557+0.0002, where 0.000557 is the σ of a single 32258-event count over 31 sets.
- The NZPOST cap is correct: it assigns `_d_NZPost(0,I,J)` directly (11408).
- **Performance:** the AZ covariance is about (31·n)² pair checks. Grouping by set keeps the summation order identical.
- **Seam:** feed a BASIC-produced mvd into the C++ routine and compare matrices and σ (deterministic, T1-like). Out-file covariance sections compare as text.

### O6. Two-system covariances (11431-11938, CovarCUMU.bas:383-529)

About 200 LOC (5 duplicate blocks plus ZAcumu).

**Input:** a 6-field line `Z, A, Z2, A2, E2|"specfile", CE` (GEF.bas:3071-3109).
- It is only allowed with a single energy value (3073, 3152).
- `S_par.Z_double` activates `B_Double_Covar` (3146-3150).
- The second system takes `P_E_exc_Double`, the same CE, and reuses the same parameter sets through the `Double_*` arrays (5380-5430).
- `C_Espectrum2` is a global that later lines overwrite [quirk].

**Output layout:**
- `CFileout = "GEF_Z_A+Z2_A2…"`. One out file holds `<GEF><GEF1>…</GEF1>` and then `<GEF2>…</GEF2></GEF>`.
- tmp\<CFileout>.mvd holds the deviations of both systems.

**Algorithm:**
- Deviations are reordered into `VR*_Double(system, set, coord)`.
- Covariance sums over sets where both deviations are nonzero; cells with `Nval ≠ N_Error_Max` are zeroed.
- `rms = sqrt(Σdev²/(N-1))`.
- An exact-zero deviation is treated as missing [quirk].

**Suspected bugs:**
- 11651-11652: Apost normalisation loops `Apost_Double_min To Apre_Double_max`.
- 11905: `rms_ZA_Double` is ReDim'd with `dApre_Double_max` but indexed up to `dApost_Double_max`. There is no bounds check, so this is possible memory corruption.
- The variable `A1` used at 11718 and 11843 is not declared locally (a shared global) [verify].

**Seam:** like O5, using the BASIC tmp/<CFileout>.mvd. T4 coverage cell: two-system lines.

### O7. Results-file writer (11943-14663)

About 2,700 lines, of which about 250 are computation. The section map, with line ranges and the arrays that feed each section:

**Wrapper.** `<?xml…>`, `<GEF>` or `<GEF1>`/`<GEF2>` (11943-11963).

**`<Title>` (11964-12100).**
- Version, timestamp (`Format(Now)`), IEVTtot.
- An under-count note when `IEVTtot < NEVTtot`.
- `Using "& ### & ###"` with Z and A.
- Text by Emode: P_E_exc, Eabsgs, Spin_CN, Spin_target, E_EXC_ISO, C_Espectrum, and the spectrum table.
- Isomer, Ilocal, Delta_S0 (comma zone), an echo of MyParameters.dat with comments stripped, EOscale, D_Par_Fac, the Bmulti/Imulti warning, I_Warning, the ReadCorr note.

**`<Prompt_results>`** (12102) contains:
- **`<Non-fission_results>`** (12106-12150): NNCNtot and NPCNtot, normalised in place; `J, , Round(p,3)`.
- **`<P_fission>`** (12152-12191):
  - `Imulti/N_multi_sample`;
  - for Emode 13, a table of NE_fis and NE_all with Round(,3);
  - the C_pfis/C_pfis2 file names.
- **`<Multi_chance>`** (12193-12308):
  - W_chances(0..10, 0..2) as a comma-zoned table;
  - E_multi_chance(I,J,K) in `Using "####.#"` / `"    #.#####"`, header `"  I / J   "`;
  - sets the globals Nmax/Pmax/Emax_multi_chance.
- **`<Fission_channels>`** (12310-12360):
  - if `Emode<3 And Inofirst=0`: exact Yield_Mode_0..5, 11, 22;
  - otherwise Mode_Events(0..7)/Mode_Events(10);
  - both as `100*Round(x,4)`.
- **`<FF><FF_Z><Element_yields>`** (12369-12393): ZPOST for Z=20..70, `Using "####    ###.#####   &###.#####   &###.#####"` with ±d_ZPost(0).
- **`<Z_even_odd>`** (12403-12406): ZEO_GEF, which the fit also uses.
- **`<Z_covariances>` / `<Z_correlations>`** and their `_2_systems` variants (12409-12496): Round(,4), 20 values per line.
- **`<N_over_Z>`** (12501-12540): from NZpre and NZpost; `Print I, NoverZ` (Single).
- **`<FF_N><Isotonic_yields>`** (12545-12561): Npre and Npost, Print Using.
- **`<FF_A><Mass_yields>`** (12563-12589): Apre and Apost for A=20..190, 6 decimals, ±d_APost(0).
- **`<Apre|Apost_covariances/correlations>`** and `_2_systems` (12592-12768).
- **Computation block** (12772-12903):
  - 200% normalisation in Single (`RS0` is a Single sum over A 1..300 × Z 1..100);
  - ZPOLARPRE/POST and SIGMAZPRE/POST;
  - local even-odd DPLOCAL/DNLOCAL, where the sign uses `J` after the loop (J=6, or the break value via `GOTO NEXTIP`) [quirk];
  - global EvenOdd (Single).
- **`<FF_AZ><Independent_yields>`** (12905-12946): ZISOPRE and ZISOPOST (normalised) with ±d_ZISOPOST(0) (the σ+Y quirk).
- **`<ZApre|ZApost_covariances/correlations>`** and `_2_systems` (12948-13286):
  - a key table `Z Amin Amax`;
  - `Trim(Str(Round(x,4)))` with a line break per Z2 row block.
- **`<Z_mean>`** (13290-13319): ZPOLAR and SIGMAZ, Print Using.
- **`<Gammas>`** (13340-13528):
  - `<Gamma_multiplicity>`: NgammaA(A,0..20), Ngammatot(0..50), d_Ng;
  - `<E_entrance>`: _Eentrance rebinned to 100 keV via `Int(I/100)`;
  - `<E_gammas>`: _Egamma and _EgammaE2 rebinned, d_Eg;
  - `<Sum_gamma_energy>`: _Egammatot, d_Egtot.
- **`<Neutrons>`** (13534-14114):
  - `<NmultA>`: NmultiApre/post, NApre/post, N2Dpre/post(·, 0..16).
  - `<Nmult>`: NNCN, NNsci, NNfr, NN, NNlight, NNheavy normalised; means, d_*; Ndirlight(-100..99); nuTKEpre/post.
    - The "Width" lines for light and heavy fragments print the variance, not the sqrt (13753, 13773) [quirk].
    - The nuTKE First_output/Last_output scan uses `Exit For, For`; if there is no data the bounds stay at 0.
  - `<Nspectrum>`: EnCN (scaled by NEVTtot/Imulti), Ensci, Enfr, ENfrC(DN,DZ), En (all 100 keV, Double); ratio to a Maxwellian with Tnorm=1.32; ENfrvar with its limits.
  - `<Enmean>`.
- **`<FF_spin>`** (14139-14302):
  - `<A_Z_spin>`: JFRAGpre and JFRAGpost(N,Z,0..25), Jmean when NJ>4.
  - `<Isomeric_yields>`: see O8.
- **`<Q_value>`** (14307-14328).
- **`<TKE>`** (14337-14379): pre/post, d_TKEpre/post, sigma.
- **`<TXE>`** (14386-14407): prints `d_TKEpre(0)` as TXE's uncertainty [BUG, 14403].
- **`<A_Ekin>`, `<A_TKE>`** (14410-14594): dense 2-D dumps of AEkinpre/post and ATKEpre/post over automatic limits; default Print of Double, 50 per line.

**After `<Prompt_results>`:**
- **`<Control>`** (14604-14663): about 55 scalar globals as `"name = ",value`.
- **`<Delayed>…`**: written by Branchings (O9/O10).
- **`<CHI_square>`** (14715-14757): O13.
- **`<Comments>`**: Printcomments (18128-18172).
- Closing tags (14762-14774).
- **`<External>`** after `</GEF>` (14829-14837).

**Hazards:**
- Exact float arithmetic in the normalisation (yields print as e.g. 1.496599, not 1.4966).
- O0 formatting.
- `Exit For, For`.
- Double vs Single printing differences (e.g. `NCNmean` is Double and prints about 15 digits).

**Seam:** a section-tag parser, then:
- deterministic text (headers, Control, the Fission_channels exact branch) compared exactly with timestamps masked;
- histogram sections compared statistically (T4) or exactly (T3 seed).

**T4:** YES, this is the primary target.

### O8. Isomeric split (14212-14300)

About 60 LOC.
- **Inputs:** JFRAGpost(N,Z,J); `Isotab` (R_lim, I_ISO, R_SPI, R_EXC) via `I_MAT_ENDF`, `N_ISO_MAT`, `ISO_for_MAT` (NucProp_Functions.mac:11-106).
- **Loop:** A=20..P_A_CN-20, Z=10..P_Z_CN-10, N in [10, I_N_CN-10], ZISOPOST>0, Niso>0.
- **Steps:**
  1. Clamp `R_lim(K)>50` to 50, permanently.
  2. `R_yield_iso(1) = Σ JFRAGpost` over `RJ = 0 To R_lim(1)` (Single, step 1).
  3. For K≥2: `RJ = R_lim(K-1) To R_lim(K)`. Shared endpoints double-count, and RJ is fractional (R_lim is built in NucPropJEFF33.bas:160-173). The Single→Integer parameter conversion rounds to nearest, probably ties-to-even [INFERENCE: probe needed].
  4. `R_Prob(K) = R_yield_iso(K)/Rnorm`, or 0 when Rnorm=0 (D. Rochman fix).
- **Output:** `Isotab.R_Prob` (global). Branchings (NZPOST→isomers) and ENDF MT454 consume it.
- **Stale state:** nuclides with NZPOST>0 outside the loop window keep stale or zero R_Prob from earlier systems or steps. Zero means their whole yield disappears from NZIcumu [INFERENCE, edge].
- **Print format:** `A, Z, R_SPI, R_EXC, Cast(Single, P*100); " %", R_yield_iso, R_lim,` then `" "`.
- **Seam:** a driver taking a synthetic JFRAGpost table plus the JEFF33 Isotab and dumping R_Prob (T1). Or probe R_Prob after the out pass.

### O9. Branchings: isomer sorting plus decay sweep (Branchings.bas)

1024 lines; about 250 LOC if written table-driven while preserving the order of operations.

**Table load (1-237).**
- Re-reads `BranchTable` DATA on every call (`Branching_first_call` is forced to 1).
- Units: ns, ms, s, min, h, d, y (365.2422 d), stable (1e20).
- β⁻n and β⁻2n are split from the β⁻ total; β⁺ gets the p and 2p fields; IT and α as given.
- Reading stops at Ra-234. `INlast(Z)` comes from the `EndA` DATA (Z=1..90).
- **BUG at 147:** an isomer record writes `R_alpha = R_alpha_m*0.01`. This overwrites the ground-state α of the *same* record index, and `R_alpha_m` stays unscaled (in percent).
- T0: the BranchData table.

**Isomer sorting (275-305).** For IN 10..190 and IZ 10..90 with NZPOST>0:
- if the nuclide is in Isotab: `NZIcumu(N,Z,I_ISO(k)) += NZPOST·R_Prob(k)`;
- otherwise everything goes to the ground state.

**Neutron-rich sweep (342-690).** Order: N-Z from 100 down to 0, Z from 90 down to 10, states 3, 2, 1, 0.
- Branches per state:
  - α_m and α: only if `IN > INlast(Z)`; feed (N-2, Z-2);
  - IT_m and IT;
  - β_mm, β_m, β → (N-1, Z+1);
  - β-n(_m) → (N-2, Z+1);
  - β-2n(_m) → (N-3, Z+1).
- Skipped if `R_life ≥ 3.15e13` s.
- If the branch record is missing, IT to the ground state is assumed. **BUG at 434-438:** for the 3rd isomer it moves the population of state *2*.
- **Blind β⁻** (671-681): applies when the ground-state lookup returns -2 (A above the table's last A for that Z, Z in 20..88) and `U_Q_beta_minus > 0`.
- **Delayed neutrons:** each β-n event adds `Radd` and each β-2n adds `2·Radd` to `R_nu_delayed`, and prints a `<dn_emitters>` line `Radd, IZ, A, "…"` with comma zones. The 1st-isomer β2n_m line prints `Radd` instead of `2·Radd` (578) [quirk].
- **Antineutrinos:** `R_an` is summed. `U_Print_an` (nominal pass only) appends to `C_out_an` and fills the `Qbeta` analyzer, indexed by Single→Integer `Q*1e3` (DCLbranchingJEFF33.bas:119-141).

**Proton-rich sweep (704-848).** Order: N-Z from 0 up to 100, Z from 90 down to 10, states 2, 1, 0 only.
- α and IT only if `IN ≤ INlast`.
- β⁺ family → (N+1, Z-1), (N+1, Z-2), (N+1, Z-3).
- Blind β⁺ when the lookup returns -1.

**Accumulation (862-873)** on every pass, including the nominal one and a second External run:
- `d_NZIcumu(1|2, N, Z, 0..2)` and `d_R_nu_delayed`.
- Finalised at the last perturbed pass (876-910): σ with the 100% cap.
- The print loop applies the cap again (961-967), but only inside the print window [quirk: ENDF MT459 sees uncapped values outside it].

**Output (913-995):**
- `<nu_delayed>`: `Csng(R_nu_delayed*0.01)` ± d.
- `<anti_neutrinos>`: `Csng(R_an*0.01)`, then the C_out_an lines built from Str() pieces with Space padding.
- `<Cumu><Yields>`: `IA, IZ, Iori, NZIcumu (Single) [, Csng(d)]` with comma zones; then CovarCUMU.

**Data contract:**
- Inputs: NZPOST, Isotab.R_Prob, I_ISO, N_STATES, BranchData, INlast, AME2020 (for Q), P_Z_CN, P_A_CN, I_N_CN.
- Outputs: NZIcumu (Single, 250×120×4), d_NZIcumu, R_nu_delayed (Static Single), R_an, C_out_an, Qbeta.

**Hazards:**
- Single accumulation and the exact operation order: sources are read after earlier additions in the same sweep.
- Table lookup is a linear scan, and IAfound is the last A seen for that Z.

**Seam:** a standalone driver (include DCLbranchingJEFF33 and NucPropJEFF33, set NZPOST and R_Prob synthetically, run Branchings.bas, dump NZIcumu, R_nu_delayed and C_out_an). Deterministic, T1/T2-level. This is the best early-port candidate.

**T4:** YES (`<Delayed>`, `<Cumu>`, Decay.dmp, MT459).

### O10. CovarCUMU (CovarCUMU.bas)

About 350 LOC.
- Builds `NZcumu(N,Z) = Σ_iso NZIcumu` and `ZISOcumu(A,Z)`.
- **Perturbed passes:** appends a `*AZcumu*` block to the mvd with `Csng(ZISOcumu)`, and accumulates `d_NZcumu` (never finalised; dead).
- **Nominal pass:** parses `*AZcumu*` and computes `SZAcumuCovar/Corr` as in O5. With two systems it appends ZAcumu deviations to tmp/<CFileout>.mvd and, for system 2, computes `SZAcumu_Double_*`.
- Prints `<ZAcumu_covariances>` / `<ZAcumu_correlations>` (+`_2_systems`) as `Trim(Str(Round(x,4)))`.
- **Hazards:** the same text round trip as O4/O5. An External run of Branchings appends a second `*AZcumu*` per set, which corrupts the Nval counts (edge).
- **Seam:** mvd-driven, as in O5.

### O11. ENDF FPY writer (ENDF.bas, DCLendf.bas, ENDF_tape_description.bas)

About 700 LOC of logic, with the sf and n headers duplicated.

**Gate:** `B_ENDF=1` (set by the ENDF or RANDOM option; ES forces it off at 3268-3274), and `B_Error_Analysis=0 Or B_Random_On=1` (line 92).

**Projectile handling:**
- Only Emode 1 and Emode 2 set any flags.
  - **Emode 1** (GS, IS n, and also GS with E*>0, i.e. `_cf`): treated as sf. Suffix `_s` (not `_sf`), `A_target = P_A_CN`, NSUB=5, AWI=0, title "SPONTANEOUS".
  - **Emode 2:** suffix `_n`, `A_target = P_A_CN-1`, NSUB=11, AWI=1, `E_ev = E_EXC_TRUE·1e6` (Single), `R_Emax = 1e6·En_max` (Static Single).
- Isomer suffixes: `f<n>` for sf from an isomer, `m<n>` for a target isomer.
- For other Emodes (0, -1, 12, 22, 13) ENDF.bas still builds `ENDF\GEFY_<Z>_<A_target>.dat`, with A_target Static (stale or 0), opens it for Append and closes it, producing an empty or stray file [INFERENCE].

**State machine (387-451).** `N_E_steps` is set at GEF.bas:3242-3250 and the per-step energy and B_Error_On at 3459-3495.
- **sf, or n with one energy (`N_E_steps=1`):** acc + find + header + IY + CY_direct + EOT in a single nominal pass.
- **RANDOM with one energy (`N_E_steps=2`):**
  - step 1: nominal, limits only;
  - step 2: header + IY + CY_direct + EOT. In perturbed passes this writes `GEFY_…_n_E<k>_R<i>.rnd` with k = `I_E_step-2+I_first_E_step-1` (674-676); the random header has LE=0 and text "RANDOM".
- **n with N energies (`N_E_steps=N+3`):**
  - steps 1-2: B_Error_On=0, accumulate NZPOSTSUM and NZCUMUSUM (Static Single 250×100); step 2 also determines limits;
  - step 3: n header + IY + CY to buffer (or CY_direct when random+perturbed);
  - steps 4..N+2: IY (the LE field carries I_INT=4, "C_LE misused") + CY buffer;
  - step N+3: SEND/FEND/MEND appended to tmp/CUMU<thr>.dat, the buffer copied into the tape, then TEND.

**Nuclide selection (510-597).**
- Keep a nuclide when `NZPOSTSUM` or `NZCUMUSUM` exceeds `1.5·Racc`. Racc is that pass's `100/NEVTtot`, so the threshold is in units of the last step's events.
- Per-Z intervals [INfirst, INlast] are computed separately for independent and cumulative yields (the merge is commented out).
- `IA_NFP(2|3) = Σ NStates_for_ZA`. NC counts use `Ceil(NFP·4/6)`. The sums are then cleared.

**Records:**
- **MF1/MT451 header** (683-917 sf, 920-1155 n):
  - HEAD: ZA, AWR (`R_AWR_ENDF`), LRP=-1, LFI=1, NLIB=99, NMOD=1.
  - CONT: ELIS=E_EXC_ISO·1e6, STA=1, LIS=LISO=I_E_iso, NFOR=6.
  - CONT: AWI, EMAX, LREL=1, NSUB, NVER=1.
  - CONT: NWD=35, NXC=3.
  - ZSYMAM `CInteger(Z,3)-El-CInteger(A,3)[M]`, CENBG, EVAL-JUN25, K.H.SCHMIDT, DIST-AUG11, DIST-JUN25.
  - 3 HSUB lines, the 30 description lines, then the directory: 451 (NC=42), 454 (NC=1+(1+R)·E_steps), 459.
  - SEND (NS=99999), FEND, HEAD 8/454 with LE+1.
- The title line (`I_Print_Title_Line`, Static) is printed once per tape and re-armed after TEND.
- I_NS keeps counting from the static value through the n header ("I_NS = I_NS + 1 ???" at 940).
- **MT454 (1170-1246):** per Z and N in limits; for each state in ENDF isomer order:
  `CDouble(1000Z+A), CDouble(J), CDouble(NZPOST·R_Prob/R_Norm), CDouble(d_NZPOST(0)·R_Prob/R_Norm)`.
  - Six fields per line, flushed at 66 characters by Testprint.
  - `R_Norm = Σ_{Z=1..100} Σ_{N=1..200} NZPOST · P_selected/2` accumulated in **Static Single**. This produces the observed 1.999998-6 noise.
  - `I_NS_mem` carries NS across steps.
- **MT459:** the same layout with `NZIcumu` and `d_NZIcumu(0)`; written direct or into the buffer (TestprintC to #fCUMU).

**Formatting (DCLendf.bas):**
- `CDouble`:
  - 0 → `" 0.000000+0"`;
  - 1e-9 ≤ x < 1e10 → `Format(x, "-0.000000E+0")`, otherwise `"-0.00000E+00"`;
  - a comma becomes `.`; a leading space for non-negative values; the 'E' is removed;
  - if the result contains "10.00", multiply x by 1.0001 and retry (`GoTo Repair`).
  - Note: values below 1e-9 lose a mantissa digit.
- `CInteger`: `Format(i,"#####")`, right-justified to the width; a value of 0 gives "0" [verify against the observed "0"].
- `CTrailer`: `MAT(4) MF(2) MT(3) NS(5)`.
- MAT is the NucTab index from `I_MAT_ENDF`, plus I_E_iso. Unknown nuclides get new numbers persisted in ctl/IMATmax.ctl (state across runs).

**Seam:** probe-dump NZPOST, NZIcumu, d_NZPOST(0), d_NZIcumu(0) and R_Prob at ENDF entry for each step. A C++ writer fed those dumps must reproduce the tape byte-for-byte. Also run `Reference/GEF_data/.nea/endf_format_check.py`.

**T4/T5:** YES (MT454 and MT459). This is the library deliverable.

### O12. Isomer/MAT lookup helpers (NucProp_Functions.mac:11-135)

About 80 LOC.
- `I_MAT_ENDF` is a linear scan. When the nuclide is missing it reads and appends ctl/IMATmax.ctl (persistent side effect).
- `N_ISO_MAT` may read `NucTab(I_first+5)` out of range.
- `ISO_for_MAT` returns 0 implicitly when not found.
- `NStates_for_ZA` defaults to 1.
- T0/T1 with a driver.

### O13. Chi-square block (GEF.bas:14715-14757, Plotting.bas, DCLplotting.bas:77-130)

- Runs only on the nominal pass with `B_Fit=0`.
- `IENDFall` 0..3 (ENDF/B-VII, JEFF3.1.1, JEFF3.3, LOHENGRIN); Plotting.bas is included twice per value.
- Plotting selects datasets by (Emode, E window, Z_CN, A_CN): sf at E=0, thermal 0..0.05, fast 0.4..2, 14 MeV, and others.
- `Chisqr_Apost` reads DATA (Afirst, Alast, Y, dY):
  - `Chilin = Σ((Y-Apost)/dY)²/N` over A with both values > `Yield_threshold` (0.01);
  - `ChiGEFlin` uses `d_Apost(0)` only when `B_Error_On=1`;
  - if N=0 the result is NaN.
- Graphics are off because `B_Print_Chisquare=1` sets `B_graphics=0`.
- **Size:** Plotting.bas has 2870 lines of mostly repetitive dataset dispatch; DCLplotting.bas has 5500 lines, mostly DATA.
- **Seam:** pure function of Apost, d_Apost and the DATA tables (T1).
- **T4:** the `<CHI_square>` section exists only for systems that have evaluation data; it is empty for Rn-215.

### O14. External cumulation (14776-14840)

About 65 LOC.
- Triggered when `External/<Csystem>.dat` exists: leading `'` comment lines, then `Z, A, Y` triples.
- Zeroes `_NZPOST`, then calls `Acc_NZPOST(N, Z, Y)`, where `N = A-Z` is correct because the accessor itself subtracts Z.
- Re-runs Branchings (all side effects repeat: d_NZIcumu, C_out_an, mvd blocks) and writes `<External>` after `</GEF>`.
- Runs on every pass.
- Coverage edge only.

### O15. dmp dumps (14844-15465, plus U_DMP_1D at 15709-15812)

About 120 LOC of distinct logic within about 620 lines.
- **When:** nominal pass only. Folder `dmp/<Csystem>/`, created with the CHDIR/MKDIR test. Every file is opened for Append.
- **Files and contents:**
  - **EMpot**: EMpot(mode, ·).
  - **Multichance**: E_multi_chance slices, uses the Nmax/Pmax/Emax set by O7.
  - **Aprov**: APROV, AMPROV.
  - **Apre**: APRE, AMPRE.
  - **Apost**: APOST, AMPOST.
  - **Ekin**: Ekinpre, EkinpreM, EkinApre, Ekinpost, EkinpostM, EkinApost, TKEpre, TKEpreM, TKEpost, TKEpostM, TKEApre, TKEApost.
  - **ZApre**: custom SATAN blocks: Zpre(Apre), Apre(Z) and Npre(Z) with `Rnorm=200/ΣNZPRE` (Single).
  - **ZApost**: same, with NZPOST.
  - **Zpost**: ZPOST, ZMPOST.
  - **Npre**: NPRE, NMPRE.
  - **Npost**: NPOST, NMPOST.
  - **ZPolarpre / ZPolarpost / SigmaZpre / SigmaZpost**.
  - **NA**: NmultiApre/post, NApre/post.
  - **EN**: _ENCN and _EPCN (if Imulti>0), _ENsci, _ENfr, ENlight, ENheavy, ENApre/post, _ENfrfs, ENAprefs/postfs.
  - **NP**.
  - **NN**: normalised by O7.
  - **DPlocal, DNlocal**.
  - **Egamma**: _EgammaCN, _Egamma, L, H, E2, tot.
  - **Decay**: Qbeta.
  - **EgammaA**: dead (B_EgammaA is off).
  - **Ngammatot**.
  - **Eexc**: _Eentrance, EexcL2d/ErotL2d light and heavy.
  - **Qvalues**: Qvalues, QA.
  - **XE**: TotXE, EintrA, EdefoA (bug), EcollA, Epart(mode, 1|2, ·).
- **U_DMP_1D format:**
  - lines `C: Written on <date>`, `C: Calculation performed with GEF<ver>`, `S: ANALYZER(name)`, `S: TITLE`, `S: COMMENT(<Csystem>)`, `S: COMMENT(ccmt)`, an optional "analog" note, `X:`, `Y:`;
  - `A: (X = Str(Imin·step) TO Str(Imax·step) BY Str(step)) Y,<linesym>`;
  - data: `Trim(Str(Csng(v)))` joined by commas, with a trailing comma unless I=UBound, breaking lines once ≥128 characters.
  - Range rules: Imax becomes UBound if > 0.8·UBound; Imin becomes **0** (not LBound) if < LBound + 0.1·range; degenerate ranges become LBound..LBound+1.
  - Analyzer metadata comes from the `Anl_Par` registry (Spectra.bas).
- **Hazards:**
  - ZApre and ZApost data rows use `Print #f` after `Close #f` (14842). This works only because `DMPFile = Freefile` returns the same handle number, and the validation ZApre.dmp does contain the rows. The C++ port must write them into the dmp stream.
  - The comments embed `Str(IEVTtot)`.
- **Seam:** a SATAN parser to arrays. Compare exactly under T3; otherwise per-bin statistical tests.
- **T4:** YES (all analyzers).

### O16. Pass loop and tail control (15466-15555)

About 30 LOC relevant:
- `I_Error += 1`; at `N_Error_Max` set `B_Error_Analysis=0`; `GoTo calcstart` while `I_Error ≤ N_Error_Max`.
- Fit branch: there is no error loop; with Bplot set, Plotting is included for χ².
- In interactive mode without a plot, `End`.
- Replace with structured loops.

### O17. lmd list-mode output (header 4816-5048; record 9644-9980; close 10006)

About 330 LOC.

**Options:**
- `LMD`: Z1, Z2, A1/2 sci and post, I1/2 pre and gs, dir, XE, n1, n2, TKEpre/post, E@fission plus the pre-scission particle list.
- `LMD+`: adds XEdetails, PEnpost (record lines "0", "1", "2") and PEgpost (lines "3".. "8" plus the isomer tag C_iso_lmd).

**File name:** `out\<Csystem of the FIRST energy step>.lmd`. The `$Events.lmd` placeholder is replaced only once per sequence file (3531-3539), so later energies, and later nucleus lines of the same sequence file, append to the same file [INFERENCE].

**Header:** written on *every* pass, including perturbed passes that produce no events.

**Record format:** `Print Using` fields `"### "`, `"#### "`, `"###.# "`, `"####.## "`, `"###.#### "`, `"#####.## "`, `"####.### "`.

**Hazards:**
- **The record code draws Rnd:** costheta and phi for the fragments (9680, 9719) and for the pre-scission particles and neutrons (9769-9839). LMD therefore changes the downstream random stream and all MC results. A T3 comparison must use identical LMD flags.
- The heavy-fragment lab kinematics use `Array_v_f1_CN(J)` (9902, 9917) [suspected bug].
- Spin quantisation: `Int(J+0.5)` vs `Int(J)+0.5`.

**Size and separability:** separable as an event sink. It is the natural T3 per-event trace.

**T4:** not required. For T3: YES.

### O18. .par file and parameter-set storage (5160-5435)

About 130 LOC.
- tmp\<CFileout>.par, Append, perturbed passes only.
- Header at `I_Error=0`. Its timestamp variable `Rdatetime` is never assigned, so the header shows the FB date-0 string [INFERENCE: "30.12.1899, 00:00:00"].
- Body: about 48 lines `"name =   ", value` (comma zone).
- In parallel, the `Double_*(N_Error_Max)` arrays store each set for system 2 or the fit (5283-5430).
- **Seam:** the .par file is a perfect probe of perturbed-parameter draws (T2 for PGauss and the RNG order).
- **T4:** no.

### O19. Fit mode (2519-2570, 15597-15612, Plotting.bas, FitparWrite.bas ~80, FitparRead.bas 27, ReadParameters.mac ~210, ParameterUpdate.mac)

It is a random-search optimiser around the whole run.
- **Entry:** `FIT(obs)` (APRE, APOST, NUBAR, ZEO, ZEMFRS, MODES) or a FIT line in file.in. This sets `B_Fit=1`, `B_Error_On=1` and `Bplot=-1`. `NITER(n)` limits the number of loops.
- **Each loop:**
  - one parameter set: nominal in loop 1, perturbed with D_Par_Fac afterwards;
  - every system runs one pass;
  - Plotting accumulates `Chisqr_Fit_present` and writes Fitlog;
  - at the next Nextfitloop, if the total χ² is lower, write `Fitpar.dat` (Append; the *perturbed* working values written as new nominals), refresh tmp/ParameterUpdate.dat, `D_Par_Fac *= 0.9` (floor 0.03), then `Shell("cp -r GRAF BestFit; todos")`;
  - FitparRead then re-reads all of Fitpar.dat, so the last block wins, and also reads `Chisqr_Fit_min`.
- **Separability:** high. It needs only a parameter registry (name → variable, shared with MyParameters), the χ² functions and a driver loop.
- **Recommendation:** last milestone. Not needed for T4/T5.

### O20. ptb, CUMU and other intermediates

- **ptb:** a full results printout of a perturbed pass (O7 content into #f).
- **CUMU<thr>.dat:** the ENDF buffer.
- **GRAF/<Csystem>_Apost.grf:** only with plotting.
- Out of scope for T4. The C++ port can keep these in memory, but should keep an optional dump for differential tests.

## 2. Which outputs T4 needs

| Output | T4/T5 | Notes |
|---|---|---|
| out/*.dat | yes | Sections listed in O7, plus `<Delayed>` and `<Cumu>` |
| dmp/*/*.dmp | yes | All analyzers |
| ENDF/GEFY | yes (T5) | MT454 and MT459 |
| mvd | no | Best differential seam for the covariances |
| par | no | Seam for the perturbation RNG |
| ptb | no | Only the last set is kept |
| lmd | no | T3 trace |
| CUMU | no | Intermediate |
| Fit* / BestFit | no | Fit mode only |
| External | coverage only | Edge case |

Timestamps that must be masked: out Title, mvd, par, dmp (every analyzer), lmd, Fitlog, Fitpar, ParameterUpdate.

## 3. Number formatting that must reproduce exactly (hot spots)

- **Print Using templates:**
  - Yields: `"####    ###.#####   &###.#####   &###.#####"` (Z), `"####          ###.######       ###.######   &…"` (A), `"####  ###     ###.######         ###.######   &###.######  &###.######"` (AZ).
  - mvd: `"####    ####    ###.#####"`.
  - Spectra: `"####.#    ############"`, `"########   ###########"`, `"####.#      ##########      ##########"`, `"     ##########    ########## ########.######"`.
  - nuTKE: `"#####  #######  ###.##"`.
  - Spin: `"### ## ##.## ########"`.
  - lmd: as listed in O17.
- **Default Print of Single and Double with comma zones:** N_over_Z, Nmult, Isomeric_yields, Cumu yields, dn_emitters, Control, A_Ekin/A_TKE (Double), mvd AZ, two-system mvd.
- **`Round(x,n)` printed raw:** Fission_channels (`100*Round(,4)`), Z_even_odd, the covariance matrices (Round(,4), and `Trim(Str())` for ZA), Gamma means.
- **Str(Single):** Csystem/dmp folder names (`E2.53e-08MeV`), dmp data and headers, the anti-neutrino list, the ptb set number.
- **vbcompat Format:** ENDF CDouble and CInteger, plus the timestamps.

## 4. Consolidated list of suspect and quirk code (all must be reproduced unless the deviation is documented)

1. 10245: `UBound(EdefoA,I)`, so EdefoA is always 0. Confirmed.
2. 11383-11391 with Spectra.bas:1788: d_ZISOPOST(0) becomes σ+Y instead of min(σ,Y). Confirmed in out line 362.
3. 11651-11652: Apost two-system normalisation uses the Apre bounds.
4. 11905: rms_ZA_Double is dimensioned with dApre but indexed with dApost, a possible out-of-bounds write.
5. 12882 and 12899: the local even-odd sign uses the post-loop `J`.
6. 13753 and 13773: "Width" for light and heavy fragments prints the variance.
7. 14403: TXE prints d_TKEpre as its uncertainty.
8. 14258-14265: Single loop variable used as a spin index, shared endpoints double-counted; R_lim clamped permanently.
9. ZApre/ZApost.dmp rows written through the closed #f, which aliases the new handle (15036-15150).
10. Branchings.bas:147: R_alpha overwritten from the isomer record, R_alpha_m left unscaled.
11. Branchings.bas:434-438: the 3rd-isomer missing-branch fallback moves state-2 population.
12. Branchings.bas:578: the Pn print shows Radd instead of 2·Radd.
13. The proton-rich sweep ignores state 3.
14. The cap on d_NZIcumu(0) is applied only to printed nuclides.
15. ENDF R_Norm is a Static Single accumulation, which gives the 1.999998-6 noise.
16. ENDF for Emode other than 1 or 2 opens a stray file named with a stale A_target [INFERENCE].
17. `.par` timestamp variable never assigned.
18. lmd consumes Rnd, so enabling LMD changes the physics stream. The heavy-fragment lab velocity uses Array_v_f1_CN.
19. lmd header written on every perturbed pass; the file name is frozen at the first energy step of the sequence file.
20. External re-runs Branchings and duplicates the mvd *AZcumu* blocks.
21. GEF.bas:3471: the non-random `N_E_steps=2` branch uses the stale global `I` (unreachable in practice).

## 5. Suggested porting order and seams for this slice

- **M-a. O0 formatting runtime.** FB driver golden tests (T1). It gates everything textual.
- **M-b. Static tables.** BranchData/EndA, Isotab/R_lim, MAT/AWR (T0), plus the O12 helpers (T1).
- **M-c. Deterministic post-processing functions, each with a synthetic-input driver:**
  - O2 projections;
  - O8 isomer split;
  - O9 Branchings (NZPOST + R_Prob → NZIcumu, nu_d, anti-ν);
  - O13 χ².
- **M-d. Text round trip and statistics:**
  - O4 writer, then O5/O10 covariances and σ, driven by BASIC-produced mvd files (exact text compare of the covariance sections);
  - then O3 accumulators, probed per pass;
  - O6 two-system variant afterwards.
- **M-e. Writers:**
  - O7 out writer, section by section with a tag parser, masks and exact compare under T3;
  - O15 SATAN dmp writer;
  - O11 ENDF writer fed by probe dumps (byte-exact, plus the format checker).
  - Together these close T4.
- **M-f. Options:**
  - O17 lmd (enables T3 per-event diffing; mind its RNG draws);
  - O18 .par (T2 perturbation seam);
  - O14 External;
  - O19 fit last.

**Probe points to patch into the reference copy:**
- after 10427 (projections);
- after 10727 (accumulators, per pass);
- after 11428 (σ and covariances);
- after 12903 (normalised ZISO* and polar arrays);
- after 14300 (R_Prob);
- at Branchings entry and exit (NZPOST, NZIcumu);
- at ENDF entry (NZPOST, NZIcumu, d_*, R_Norm, limits, I_E_step flags).

All dumps should be written at full precision (hex-float or `%.9g` / `%.17g`).
