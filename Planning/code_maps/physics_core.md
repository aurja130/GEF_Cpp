# Code map: Physics core

> Saved verbatim from the planning-session report `PhysicsCoreScout` (agent output, 2026-10-06), source commit `ba9f0aa`. Corrections made after the report was written are listed in `README.md` in this directory; the text below is unedited.

## Summary

GEF is one ~15.7k-line block of module-level FreeBASIC code in GEF.bas, lines 1–15690. It has no main SUB: the active GEFSUB at 1676 sits inside a /' … '/ comment from 1630 to 1689. Everything else is pulled in with textual #include, and several includes are re-entered inside loops. The include chain is: Parameters.bas (1015, re-included at 3320); ParameterManipulation.mac (1017); NucPropJEFF33.bas (1052, the active isomer table); BEldmTF, BEexp, DEFO and ShellMO (1559–1565, data tables); Spectra.bas (1278, the growable histogram arrays); DCLplotting (1280); DCLendf and DCLbranchingJEFF33 (1282–1284, active because `#define B_delayed` at 427). Inside the per-run output section come Branchings.bas (14704, which includes CovarCUMU at Branchings.bas:993) and ENDF.bas (14711, which includes ENDF_tape_description). Inactive variants: NucPropJEFF311, NucPropNUBASE2016/2020, NucPropx/f/mf, DCLbranchingJEFF311, Extend.bas, ENDF_EOT.bas and GEFSUB.

The RNG is FreeBASIC Mersenne Twister. `Randomize,3` at GEF.bas:1553 has no seed, so the seed comes from the clock and runs are NOT reproducible. All sampling goes through `Rnd` plus home-made distributions at GEF.bas:17878–18060, not utilities.bi.

Uncertainty runs: N_Error_Max = Int(sqr(Fenhance*100)), which is 31 for Fenhance=10. Each perturbed set uses NEVTtot = Fenhance·1e5/N_Error_Max = 32258 events. 48 parameters are redrawn independently as PGauss(nominal, Var_x) at GEF.bas:5112–5160; the Var_x values set at 2575–2622 are the ones in force. After the perturbed runs comes one nominal run of 1e6 events (loop control at 15527–15550).

ENDF yields: MT454 (independent) = nominal NZPOST normalised to sum 2, with uncertainty = sample standard deviation over the 31 perturbed runs (GEF.bas:11396–11410). MT459 (cumulative) = nominal NZIcumu from a single-pass, deterministic decay-chain sweep using JEFF-3.3 branchings (Branchings.bas:273–860), with the standard deviation over perturbed runs (Branchings.bas:876–897). Decay-data uncertainties are not included. Both are capped at 100%.

For 59 energies, ENDF.bas works as a state machine over N_E_steps = 59+3 = 62. Step 1 is thermal nominal and step 2 is Emax nominal; both only fix the nuclide list. Steps 3–61 are the 59 energies (31 perturbed + nominal each). Step 62 is thermal nominal again: it appends the buffered MT459 data from tmp/CUMU<thread>.dat and writes TEND.

Why the reference ENDF file has two tapes [INFERENCE]: the first tape has EMAX=2.53e-2 eV, but this run's En_max was 30 MeV. The log reports thread number 2 (so a ctl/ folder from a previous run existed), and all outputs are opened For Append. The thermal-only tape is therefore most likely left over from an earlier run, not produced by this one.

## Architecture

Execution is linear module-level code steered by GOTO and nested FOR loops. Includes are inlined text, so Static/Dim inside them follows the scope where they land.

Nesting:
- Ifilein (GEF.bas:2768)
  - Iline (3141)
    - I_Double_Covar (3294)
      - I_E_step (3442; maps step to P_E_exc and B_Error_On at 3459–3488)
        - multi-chance pre-fission MC, once per energy (3917–4800)
        - calcstart: label at 4811 (body 4811–15550), re-entered by GoTo for each I_Error
          - clear spectra; perturb or restore parameters (5100–5490)
          - multi-chance loop nest I_E_distr / I_N_Multi / I_Z_Multi / I_E_Multi (5521–5531)
            - Energy_loop: deterministic tables per (Z_CN,A_CN,E*) (5533–7919)
            - event loop `For ILoop = 1 To NEVTused` (7922–9997)
          - output and uncertainty statistics (10008–11420)
          - isomeric ratios (14212–14300)
          - Branchings (14704), ENDF (14711), Chi-square, .dmp files
          - I_Error++ and GoTo calcstart (15527–15550)

Physics SUBs live at the end of GEF.bas: Eva 16650; P_Egamma_low/high 16962/17056; level densities and temperatures 17173–17437; EVEN_ODD 17593; BFTF barriers 17657–17796; random distributions 17878–18060.

Global state is about 400 Dim Shared scalars and arrays at GEF.bas:447–1014, including shared loop counters I,J,K (762) and single-letter globals Z (790) and T (823).

## Files

### `Reference/GEF_code/source/GEF.bas`

LOGIC. 18176 lines. Main program as module-level code (1–15690) plus physics SUB/FUNCTIONs (15691–18176). Contains the event loop, multi-chance pre-fission Monte Carlo, perturbation, uncertainty analysis and output.

### `Reference/GEF_code/source/utilities.bi`

LOGIC. Min/Max (Single-typed!), Erf/Erfc (Numerical Recipes approximation), Tanh/Coth/Log10, Pyes, ShellSort1/3, CC_Count/CC_Cut/ConvTab string parsing, Extend_1/2/3dim (growable-array helpers). Contains no random-number functions.

### `Reference/GEF_code/source/Parameters.bas`

DATA/LOGIC. Nominal global model parameters (`_P_*`, etc.). Duplicate assignments to the same variable; the last one wins. Included at GEF.bas:1015 and again for each system at 3320.

### `Reference/GEF_code/source/ParameterManipulation.mac`

LOGIC. 6-line include: MyparRead.bas, then FitparRead.bas, then ParameterUpdate.mac.

### `Reference/GEF_code/source/ReadParameters.mac`

LOGIC. Line parser: `NAME = value` mapped through a Select Case onto the nominal parameter variables. Shared by MyparRead and FitparRead. Has a stray `Print Cline` at line 15.

### `Reference/GEF_code/source/ParameterUpdate.mac`

LOGIC/IO. Writes tmp/ParameterUpdate.dat, a Parameters.bas-style dump of the current nominal values. Runs at every start.

### `Reference/GEF_code/source/MyparRead.bas`

LOGIC. Reads MyParameters.dat if B_MyParameters is set.

### `Reference/GEF_code/source/FitparRead.bas`

LOGIC. If Fitpar.dat exists in the working directory, it silently overrides nominal parameters (also included at GEF.bas:2555).

### `Reference/GEF_code/source/FitparWrite.bas`

LOGIC. Fit mode only: writes Fitpar.dat.

### `Reference/GEF_code/source/BEldmTF.bas`

DATA. Thomas-Fermi macroscopic binding energies, BELDMTF(1..203,1..136) via READ/DATA (MassData:).

### `Reference/GEF_code/source/BEexp.bas`

DATA. Experimental (AME) binding energies, BEexp(N,Z); default value -1e11. Used by AME2020() at GEF.bas:16238.

### `Reference/GEF_code/source/ShellMO.bas`

DATA. Möller shell corrections ShellMO(1..203,1..136).

### `Reference/GEF_code/source/DEFO.bas`

DATA. Ground-state deformations DEFOtab(N,Z). 9027 lines.

### `Reference/GEF_code/source/ElmtNames.bas`

DATA. Element symbols CElement(1..120).

### `Reference/GEF_code/source/Spectra.bas`

LOGIC/DECL. All histogram arrays, plus getter/Acc_ accessor functions that auto-extend dynamic arrays with non-zero lower bounds (e.g. _NZPOST(0 To 50,20 To 70) indexed by N-Z and Z).

### `Reference/GEF_code/source/CLEARspectra.bas`

LOGIC. Zeroes all spectra at calcstart (GEF.bas:4816).

### `Reference/GEF_code/source/CLEARerrors.bas`

LOGIC. Zeroes the uncertainty accumulators at each I_E_step (GEF.bas:3446).

### `Reference/GEF_code/source/NucPropJEFF33.bas`

ACTIVE isomer/spin table (JEFF-3.3, 4046 lines of DATA). Builds NucTab and Isotab (spin-sorted states, R_lim spin cut limits). Defines ISOSOURCE. Includes NucProp_Functions.mac.

### `Reference/GEF_code/source/NucProp_Functions.mac`

LOGIC. I_MAT_ENDF: linear search; nuclei missing from the table get MAT numbers assigned and persisted in ctl/IMATmax.ctl (state carried across runs). Also N_ISO_MAT, R_AWR_ENDF, ISO_for_MAT, ISO_for_ZA, NStates_for_ZA.

### `Reference/GEF_code/source/NucPropJEFF311.bas`

INACTIVE alternative (JEFF-3.1.1). Commented out at GEF.bas:1051/1063.

### `Reference/GEF_code/source/NucPropNUBASE2016.bas`

INACTIVE alternative. Adds C_Lifetime, used under `#If ISOSOURCE="NUBASE-…"` at GEF.bas:14228/14289.

### `Reference/GEF_code/source/NucPropNUBASE2020.bas`

INACTIVE alternative. The commented-out include at GEF.bas:1067 misspells it as NucProbNUBASE2020.bas.

### `Reference/GEF_code/source/NucPropx.bas`

DEAD legacy variant (#DEFINE N_MAT_MAX 3897). Not included anywhere.

### `Reference/GEF_code/source/NucPropf.bas`

DEAD legacy variant with fission shape isomers. Not included anywhere.

### `Reference/GEF_code/source/NucPropmf.bas`

DEAD legacy variant. Not included anywhere.

### `Reference/GEF_code/source/DCLbranchingJEFF33.bas`

ACTIVE decay data. Declares NZICUMU(250,120,3) Single and d_NZICUMU(2,250,120,3) Double, BranchType, U_Q_beta_minus (from AME2020) and Ibranch_for_ZAI (returns -2 for unknown nuclei). BranchTable: DATA (~4400 lines) and EndA: (stability-line limits).

### `Reference/GEF_code/source/DCLbranchingJEFF311.bas`

INACTIVE. Uses AME2012(), which is no longer defined, so it would not compile [INFERENCE].

### `Reference/GEF_code/source/Branchings.bas`

LOGIC. Reads BranchTable on the first call. Splits NZPOST into isomers (R_Prob), then sweeps beta-minus chains (N-Z from 100 down to 0) and the beta-plus side (N-Z from 0 up to 100) to get cumulative yields; also delayed-neutron multiplicity and antineutrinos. Accumulates and finalises d_NZIcumu. Writes the cumulative-yield section of out/*.dat.

### `Reference/GEF_code/source/CovarCUMU.bas`

LOGIC. Writes ZISOcumu for each perturbed set to tmp/*_Single.mvd (*AZcumu*). In the nominal pass it reads them back to build cumulative-yield covariance/correlation, printed only with the cov/cor options. Does NOT feed the ENDF file.

### `Reference/GEF_code/source/DCLendf.bas`

LOGIC. ENDF formatting helpers: CDouble (vbcompat Format with mantissa fix-ups), CInteger, CTrailer, Testprint/TestprintC (66-column line breaking). Creates ENDF/.

### `Reference/GEF_code/source/ENDF.bas`

LOGIC. MF1/MT451 header, MF8 MT454/MT459 writer and multi-energy state machine. Persistent state is held in Static variables. Runs only when B_Error_Analysis=0 (unless the random option is set).

### `Reference/GEF_code/source/ENDF_tape_description.bas`

DATA/IO. Fixed MT451 comment card text.

### `Reference/GEF_code/source/ENDF_EOT.bas`

DEAD. Its include at GEF.bas:15587 sits inside a /' '/ comment; TEND is now written in ENDF.bas:1536–1550.

### `Reference/GEF_code/source/DCLplotting.bas`

GRAPHICS plus DATA. `#define B_plotting`, gfx primitives, Chi-square routines, and large DATA tables of evaluated/experimental mass yields. The Chi-square result goes into out/*.dat (GEF.bas:14715–14756).

### `Reference/GEF_code/source/Plotting.bas`

GRAPHICS/LOGIC. ScreenRes/Window drawing (only when I_thread<2) plus Chi-square computation and GRAF/*.grf output.

### `Reference/GEF_code/source/Pfistest.mac`

LOGIC. Fission-probability test snippet (GEF.bas:4171/4205), writes tmp/*.pfis.

### `Reference/GEF_code/source/Mutex.bas`

Windows GUI only (#ifdef __FB_WIN32__).

### `Reference/GEF_code/source/Extend.bas`

DEAD. Test scaffold duplicating the Extend_* helpers in utilities.bi; not included.

### `Reference/GEF_code/source/ENDFdata.dat`

DATA. ENDF/B-VII 235U(nth,f) mass yields; not referenced by code (grep shows nothing).

### `Reference/GEF_code/source/MyParameters_sample.dat`

Sample user parameter file.

## Report

## 1. File roles
See `files`. In short:
- **Active logic:** GEF.bas, utilities.bi, Spectra.bas, CLEAR*.bas, the parameter files and macros, Branchings.bas, CovarCUMU.bas, DCLendf.bas, ENDF.bas, ENDF_tape_description.bas, NucProp_Functions.mac.
- **Active data tables (READ/DATA):** BEldmTF, BEexp, ShellMO, DEFO, ElmtNames, NucPropJEFF33 (NuclideData:), DCLbranchingJEFF33 (BranchTable:, EndA:), DCLplotting (evaluation tables).
- **Inactive alternatives:** NucPropJEFF311, NucPropNUBASE2016/2020, DCLbranchingJEFF311.
- **Dead:** NucPropx/f/mf, Extend.bas, ENDF_EOT.bas, ENDFdata.dat, the GEFSUB block (GEF.bas:1630–1689, inside /' '/), E_next and Pexplim (17490–17578; no call sites; Pexplim also has no return value in its lambda≈0 branch), U_levdens_old (17180, "Not used any more").
- **Comment markers:** `/'<'/`, `/'>'/` and `<FO … FO>` mark code for the deterministic FORTRAN extraction; they are only comments.

## 2. Monte Carlo core (GEF.bas)

**Before the event loop**
- **Pre-fission chance calculation (once per energy, outside the perturbation loop):** 3917–4800.
  - Runs only if Eabsgs ≥ Eexc_min_multi (3949–3972), which prints "Calculation of fission chances…".
  - N_multi_sample = sqr(Fenhance)·1e5 (3926).
  - Loop `Do Until Imulti >= N_multi_sample` at 4241. Each history competes gamma, n, p and fission using Pfistest.mac-style widths (4265–4560).
  - Pre-equilibrium emission via PPower_Griffin_v (4560–4610); Maxwell emission with rejection (4613–4660).
  - Results E_multi_chance(N_loss,Z_loss,E100keV) (4471) are normalised by Imulti into W_chances (4766–4777).
- **Energy_loop (5533):** sets I_A_CN, I_Z_CN, R_E_exc_used and the weight R_NEVTspectrum. NEVTused = CLngInt(NEVTtot·weight) (5569). It then builds deterministic tables for that nucleus:
  - deformation at scission: 5697
  - mean Z(A): 5876
  - potential curvatures (Masscurv): 6050
  - barriers and E* per mode: 6077–6320
  - charge-polarisation stiffness: 6449
  - energy-dependent mode shifts: 6561
  - mode yields via Getyield (15862): 6872–7018
  - mass widths: 7020
  - shells: 7040
  - temperatures: 7073–7170
  - even-odd and **energy sorting**, giving tables EPART(mode,1|2,A): 7173–7379, with the sorting formulas at 7334–7377
  - RMS spins: 7381–7516
  - GEFSUB/GEFRESULTS arrays: 7517–7919

**Event loop 7922–9997 (per event)**
1. **Mode choice:** one Rnd against cumulative Yield_Mode_0…22 (7926–7954).
2. **A_heavy:** PGauss, or PBox2 for S2 (7960–8022); Z from PGauss around UCD + Zshift polarisation. Rejection via GoTo DiceA (8024–8025).
3. **Integer Z and N:** EVEN_ODD (17593) with PEOZ/PEON (8072–8079); Q from AME2020 (8085).
4. **E\* at saddle:** EPART (8097). Saddle-to-scission neutrons: Eva(0,…) at 8123/8146.
5. **Temperatures:** 8303. **Intrinsic E\*** with Gaussian energy-division fluctuation, shell/pairing gain and Q/TKE adjustment (Repeat_E_Q): 8319–8578.
6. **Pre-neutron histograms:** 8580. **Collective energy:** 8610.
7. **Fragment spins:** PLinGauss with J_attempt rejection (8670–8716). **TKE/kinetic energies:** 8718–8837.
8. **Neutron evaporation:** Eva(1,…) for the light fragment (8900; 8886–9042) and Eva(2,…) for the heavy fragment (9055; 9043–9152). Eva (16650–16905) does the n/gamma competition with PMaxwellMod and rejection (Too_Low). Isotropic CM angles at 8963/8981 and 9074/9091.
9. **Prompt gammas (9238–9500):** statistical E1 via P_Egamma_low plus PGauss smearing (Repeat_Eg_light), then an E2 rotational cascade in steps of -2ħ. The cascade stops at an isomer when an Isotab state spin lies in [J, Jfrag] (9327–9345, 9446). Uses `Exit For, For`.
10. **Pre-saddle emission bookkeeping:** 9502. **List-mode output:** 9644. Event counter at the SkipEvent label (9982).

**Isomeric yields** are not taken per event. They come after the loop from the post-neutron spin distribution JFRAGpost summed over spin windows Isotab.R_lim (GEF.bas:14236–14280), giving Isotab.R_Prob. R_lim is built in NucPropJEFF33.bas:160–173.

## 3. Random numbers
- **Seeding:** `Randomize,3` (GEF.bas:1553) is the only call. It is re-executed on GoTo StartAgain (1071).
- **Algorithm:** 3 = Mersenne Twister. With the seed omitted, FB uses `seed = lo32 XOR hi32` of the bits of the Double returned by Timer, so runs are not reproducible.
- **FB rtlib details (current fbc master, math_rnd.c and fb_math.h):**
  - MT state is filled with an LCG, not standard `init_genrand`: `state[0]=seed; state[i]=state[i-1]*1664525+1013904223`.
  - Twist and tempering are standard MT19937.
  - `Rnd = u32/2^32` (Double in [0,1)).
  - [INFERENCE] The rtlib version used to build the reference binary may differ; check it if bit-exact output is the goal.
- **For bit-exact validation:** add a fixed seed in the BASIC source (`Randomize <seed>,3`) and replicate this seeding in C++. Rejection loops make the number of Rnd draws data-dependent.
- **Distributions (GEF.bas:17878–18060, not utilities.bi):**
  - PGauss: polar Box–Muller with a Static cached second value (ISet/GSet), so its state carries across events and runs.
  - Also PBox, PBox2, PPower, PPower_Griffin_v/E, PLinGauss, PExp, PMaxwell (internally Double, −T(lnU1+lnU2)), PMaxwellv, PMaxwellMod.
  - Deterministic helpers: U_Gauss, U_Gauss_mod, U_Box, Gaussintegral (17808–17863); Floor/Ceil/Round (18035–18082).

## 4. Parameters and perturbation
- **Declarations:** nominal `_x` at GEF.bas:894–1014; working copies `x` at ~1396+.
- **Value sources, in order:**
  1. Parameters.bas (1015).
  2. MyParameters.dat if option set; Fitpar.dat if it exists (ParameterManipulation.mac). Fitpar.dat is read again at 2555.
  3. Per system, Parameters.bas is re-included at 3320 when B_Fit=0. This resets values from Fitpar/MyParameters.
  4. Echoed to tmp/ParameterUpdate.dat.
- **Variances:** Fred_par = 0.5. Initial values at 1348–1394 are overridden at 2575–2622 (all × D_Par_Fac, the `Dparfac` option).
  - Differences between the two sets: Var_P_Shell_S3 0.3→0.12, Var_dbeta_S3 0.1→0.05, Var_Jscaling 0→0.06·_Jscaling.
  - Var_PZ_S3_olap_curv uses the working PZ_S3_olap_curv rather than `_PZ_S3_olap_curv`. On the first pass that value is probably still 0, so this parameter may not be perturbed [INFERENCE].
- **Counts:** N_Error_Max = Int(sqr(Fenhance·100)) and NEVTtot = Fenhance·1e5/N_Error_Max for perturbed runs; NEVTtot = Fenhance·1e5 for the nominal run (5059–5091). Ten_to_five = 1e5 (1719).
- **Sampling (5104–5160):** applies when B_Error_Analysis=1 and not the first fit iteration.
  - 48 parameters are drawn as independent Gaussians around nominal; no correlations.
  - Values are logged to tmp/<Cfileout>.par (5162–5282) and stored in Double_* arrays so the second system in two-system covariance runs reuses the same sets (5283–5435).
  - The else branch restores nominal values (5437–5486).
- **Loop control (15527–15550):** I_Error runs 0…N_Error_Max−1 with perturbed parameters. At I_Error = N_Error_Max, B_Error_Analysis is set to 0 and one more nominal pass runs via GoTo calcstart.
- **Fit mode:** Nextfitloop (2519) and GoTo Nextfitloop (15610).

## 5. ENDF output
- **Step/mode logic (ENDF.bas:387–450):**
  - Emode=2 with N_E_steps > 2: step 1 → B_acc_limits; step 2 → acc + find_limits; step 3 → header + IY + CY to buffer; steps 4…N-1 → IY + CY to buffer (L1 field carries the interpolation law, I_INT=4); step N → copy the CUMU buffer, then SEND/FEND/MEND and TEND.
  - E_steps = N_E_steps−3 (106–118). R_Emax = 1e6·En_max.
  - The whole routine is skipped when B_Error_Analysis=1 unless the random option is set (ENDF.bas:89).
- **Nuclide list (ENDF.bas:510–585):** keep a nuclide if NZPOSTSUM or NZCUMUSUM (summed over steps 1+2) > 1.5·Racc, i.e. 1.5 events. IA_NFP counts states per nuclide (NStates_for_ZA).
- **MT454 (ENDF.bas:1170–1245):** per nuclide (ZA, isomer J, Y, dY) with
  - Y = NZPOST·R_Prob/R_Norm
  - R_Norm = ΣNZPOST·P_selected/2 (yields sum to 2; NZPOST is in percent because Racc = 100/NEVTtot, GEF.bas:7920)
  - dY = d_NZPOST(0)·R_Prob/R_Norm. The isomer split assumes full correlation.
- **d_NZPOST:**
  - Sums Σy and Σy² accumulated in perturbed passes (GEF.bas:10733–10737).
  - Final value in the nominal pass: σ = sqrt((Σy² − (Σy)²/N)/(N−1)) (11396–11410). If σ = 0 or σ > y, set σ = y.
  - The nominal value comes from the 1e6-event run; σ comes from the 31×32258-event perturbed runs, so it includes statistical noise.
- **MT459:**
  - Branchings.bas: NZPOST split into isomers into NZIcumu (273–305).
  - Neutron-rich sweep, N-Z from 100 down to 0, Z descending (355–700). It handles 3rd/2nd/1st isomers and the ground state: alpha (only above the EndA line), IT, β⁻, β⁻n, β⁻2n, and the _m variants feeding isomers. Unknown nuclides with Q_β⁻ > 0 get a "blind β⁻" (671).
  - Second sweep, N-Z from 0 up to 100, for the proton-rich side (704–860).
  - Nuclides with half-life ≥ 3.15e13 s are treated as stable.
  - d_NZIcumu: Σ/Σ² accumulated on every pass (862–873); σ finalised on the last perturbed pass (876–897), same 100% cap.
  - CY is written directly (B_CY_direct) for sf, single-energy or random cases; otherwise to the buffer tmp/CUMU<I_thread>.dat (ENDF.bas:1352–1472), which is copied in at the last step (1512–1530).
- **Formatting:** CDouble uses vbcompat Format("-0.000000E+0"), with a retry if the mantissa formats as 10.00 (DCLendf.bas:55–75). CInteger uses Format("#####").

## 6. FreeBASIC hazards for the C++ port

**Rounding and numeric conversion**
- Float→integer conversion (CInt and implicit assignment/parameter passing) rounds half to even, per the FB docs.
  - Implicit cases: `I_Estep = Rnd*Ichannel` (4245); `Nspectrum = Einit*1000` (9262); `Zshift(3,2,R_A_heavy)` with a Single passed to an Integer index (7989); `Beta(0,1,I_Z_sci/2)` (8379); AME2020(Zi,Ai-1) with Single arguments (Eva 16700); `JFRAGpost(I-J,J,RJ)` with Single RJ (14259/14265).
  - Explicit CInt: 8032, 8048–8052, 17051.
- `/` always does floating division, even on integers: `I_A_light_sci/I_A_sci` (8396); `M = M / 2` with Integer M rounds half to even (utilities.bi:149/177).
- `\` first rounds float operands, then truncates: `(J_frag_light - Spin_gs_light) \ 2` (9260). `Int` = floor, `Fix` = truncate (Round at 18070).
- utilities.bi Min/Max take and return Single (lines 17–35). Integer arguments are converted to Single (e.g. Spectra.bas:1760–1763).

**Precision and number formatting**
- Most physics is Single (float); histograms and statistics are Double; Rnd is Double; `^` is evaluated in Double.
- `Const pi As Single = 3.14159` (760).
- Custom Erf/Erfc approximations (utilities.bi:36–60) must be kept; std::erf will not match.
- FB `Str()` of a Single drives file names: dmp folder `Z86_A215_n_E2.53e-08MeV` (Csystem at 3519) and E_ev.
- Integer is 64-bit on Linux x64; shared loop counters `Dim Shared As Longint I,J,K` (762).

**Arrays**
- `Dim a(N)` means indices 0..N (N+1 elements).
- Non-zero lower bounds: Beta(-1 To 7,1 To 2,150) (1082); Edefo(-1 To 5,…) (1095); _NZPOST(0 To 50,20 To 70), _ZISOPOST(50 To 160,20 To 80), _AEkinpre(50 To 200,80 To 100), _ATKEpre(50 To 200,200 To 200) (Spectra.bas); CElement(1 To 120) (1569); IA_NC(1 To 10) (ENDF.bas:149).
- Arrays grow at run time through Extend_* (utilities.bi:269–372).
- There is no bounds checking, and there are latent out-of-range reads: N_ISO_MAT reads NucTab(I_first+5) (NucProp_Functions.mac:72).
- Bug to replicate: Acc_d_NZPOST compares against `Ubound(_NZPOST,3)` on a 2-D array (Spectra.bas:1759). [INFERENCE] UBound returns -1 for an invalid dimension, so Extend_3dim runs on every call: correct result, but slow.

**Control flow**
- GOTO is used throughout: StartAgain, RepeatInput, Nextfitloop, calcstart, Next_Iline_label (3384), DiceA/Next2, Repeat_E_Q, J_attempt (8738), TKEsci_again (8869), Repeat_Eg_light/heavy, Too_Low/Raus (Eva), and rejection labels in the distributions (Repeat:, Again:, Repeat_Griffin:, Pbox_Repeat:).
- `Exit For, For` (9332, 9449). For loops with Single counters: `For J = Jfrag To 2 Step -2` (9330); `For RJ = R_lim(K-1) To R_lim(K) Step 1`, whose shared endpoints count a spin twice (14263); `For R1 = 0 To 50 Step 0.5` (NucPropJEFF33.bas:144).
- No GOSUB, ON ERROR or RESUME was found. No #lang/Option (default -lang fb), so variables are explicitly declared.

**Scope and state**
- Identifiers are case-insensitive: `Static E_MIN` and `E_min` are the same variable (Eva 16662/16681).
- Leading-underscore names coexist with plain ones: `_d_NZPOST` (array) vs `d_NZPOST` (function).
- Global state: GEF.bas:447–1014. Single-letter globals Z (790) and T (823); Branchings.bas:296 prints the global Z.
- Static at module level inside includes persists across energy steps (all of ENDF.bas:103–330, E_EXC_TRUE 832). Function-level Statics: PGauss GSet, Eva E_MIN.
- [INFERENCE] `Dim` inside loop bodies re-initialises each iteration (e.g. 7957, 8057, 8322).
- `ReDim` without Preserve clears arrays. The ReDims after StartAgain (1071–1552) re-run when GoTo StartAgain fires.

**Code to strip**
- Graphics: DCLplotting.bas (Circle/Line/Draw String), Plotting.bas (ScreenRes 36, Window 129), `Screen 0` at 1941, 3298, 15537, 15567, 15637, 15650.
- Plotting.bas also computes the Chi-square printed in out/*.dat (14715–14756); keep that if out-file parity matters.
- Windows/GUI: #ifdef __FB_WIN32__ blocks 1824–1830, 1913–2158, 15633–15646; Mutex.bas.
- Interactive input, Sleep and Inkey: 2161–2518, 15624–15632, and error stops in NucProp/Branchings.
- Multi-process coordination: ctl/thread.ctl and sync.ctl, await() (698), I_thread in file names (CUMU<thread>.dat, Fitlog). Shell("cp -r …") at 2546.

**Paths and files**
- Windows-style paths: "out\\", "tmp\\", "dmp\\"+CdmpFolder+"\\Decay.dmp", "ENDF\\", "GUI\\Mutex.ctl". These mix with forward-slash paths such as "tmp/CUMU…" (ENDF.bas:670) and "tmp/Fitlog".
  - [INFERENCE from observed output] The Linux rtlib turns `\\` into `/`, since the run log prints "out\\GEF_86_215_n.dat" while the file lands in out/.
- Folder existence is tested with CHDIR/MKDIR (ENDF.bas:93–98; DCLendf.bas:1–6).
- Outputs are opened For Append: out/*.dat (10077), ENDF (678), dmp (14885+). tmp/*.ptb is opened For Output (10064). So reruns accumulate unless folders are cleaned, which explains the two-tape ENDF file [INFERENCE].
- State across runs: ctl/IMATmax.ctl (MAT numbers for nuclei missing from NucTab), and Fitpar.dat if present.

**Other quirks to preserve**
- Case 5 of the A/Z sampling uses SigPol_Mode_4 (8005).
- Parameters.bas assigns some parameters several times; the last assignment wins (e.g. _P_DZ_Mean_S1, lines 12–13).
- PExp rejects u ≤ 1e-10 and u ≥ 0.99999 (18011).
