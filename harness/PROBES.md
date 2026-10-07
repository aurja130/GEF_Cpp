# Probes: exact variable lists and file format

The `probes` harness patch (`harness/patches/probes.patch`, built with `-d GEF_PROBES`) writes
GEF's internal state at four fixed points as hex bit patterns. This file fixes the format, the
probe points and the exact variable list of every probe, and names the milestone that consumes each
group. `python3 -m harness.probes` reads the files (see below). Line numbers refer to
`Reference/GEF_code/source/GEF.bas` at submodule commit `ba9f0aa`.

| Probe | Where | When written | Consumer milestones |
|---|---|---|---|
| **T0** | after line 1570 (`#Include Once "ElmtNames.bas"`), module level | once per process | M4 (tables, parameters, registry) |
| **P1** | before line 3882, after the entrance-channel kinematics and the validity checks (inside `For I_E_step`) | every energy step selected by `GEF_TRACE_STEPS` | M6 (input, run plan, step setup) |
| **P2** | after line 4800 (`End If ' If Emode < 3 etc.`, end of the multi-chance pre-pass) | every energy step selected by `GEF_TRACE_STEPS` | M9 (pre-pass), M10 (packed emission records) |
| **P3** | after line 7920 (`Racc = ...`), just before `For ILoop` | every bin with `NEVTused > 0`, in every pass selected by `GEF_TRACE_PASSES`, of every selected step | M7 (table builder), M10 (event-loop inputs) |

Deviations from the plan text (`MILESTONE_1_PLAN.md` M1.8), all checked with `fbline`:

* Line 3860 is the `Else` of the `Eabsgs > 120 MeV` warning, so code placed after it would run
  only for 100 < E < 120 MeV. P1 is therefore placed after the whole entrance-channel block
  (`Select Case Emode` ends at 3843, the `Eabsgs < 0` check at 3874), directly before the
  pre-pass starts clearing the CN spectra at 3882.
* The multi-chance threshold `Eexc_min_multi` is computed at 3951-3957, i.e. after P1. It is in P2.
* Line 4800 is the last line of the pre-pass block, so P2 is placed right after it.
* P3 is placed after line 7920 so that `Racc` is included. Bins with `NEVTused = 0` skip the table
  builder entirely and write no P3 record; their weights are visible in P2.

## File format

One file per probe in the working directory: `probes/T0.txt`, `probes/P1.txt`, `probes/P2.txt`,
`probes/P3.txt` (the directory is created by the probe; files are opened for appending, a clean run
directory has none). One value per line, fields separated by single spaces:

```
<ID> <context> <NAME> <idx1,idx2,...|-> <type> <value>
```

| Field | Content |
|---|---|
| `ID` | `T0`, `P1`, `P2` or `P3` |
| `context` | T0: `-`. Otherwise `step=<s> pass=<p> bin=<e>:<n>:<z>:<m> rec=<k>`: `s` = `I_E_step`; `p` = `I_Error` (P3) or `-` (P1, P2: the pre-pass belongs to no pass); `bin` = `I_E_Distr:I_N_Multi:I_Z_Multi:I_E_Multi` (P3) or `-`; `rec` = 1-based count of invocations of this probe in the process. `rec` separates records of different systems, which can repeat the same step number |
| `NAME` | BASIC spelling, as in the declaration. Fields of user-defined types are `Array.Field` (`NucTab.I_Z`, `Isotab.R_Lim`, `Anl_Par.C_Name`) |
| `idx` | `-` for a scalar, otherwise the comma-separated indices in declaration order, using the array's own bounds (a `0`-based `ReDim a(10)` has indices 0..10). For an array field of a UDT array the record index comes first (`Isotab.R_SPI 12,3` is `Isotab(12).R_SPI(3)`) |
| `type` | `S` Single: 8 upper-case hex digits of the IEEE-754 binary32 bit pattern. `D` Double: 16 hex digits of the binary64 pattern. `I` any integer type (`Byte`, `Integer`, `Long`, `LongInt`, `UInteger`, `ULongInt`, ...): decimal. `Z` string: double-quoted, `\\` and `\"` escaped, bytes outside 32..126 as `\xHH`; fixed-length `String*N` fields are cut at the first NUL byte. `B`, `BS`: bounds record, see below |
| `value` | the rest of the line |

The hex patterns are taken with `*CPtr(ULong Ptr, @x)` on a by-value copy, so no value is
changed. `Single` NaN and infinity patterns are written as they are (decode them with
`harness.probes.decode_single`).

**Arrays** are dumped over their full *current* bounds (`LBound..UBound` of every dimension, so
growable `ReDim`ed arrays show their present extent). Every array starts with a bounds record

```
<ID> <context> <NAME> - B <T> lo1:hi1,lo2:hi2,...      dense array: every element follows
<ID> <context> <NAME> - BS <T> lo1:hi1,lo2:hi2,...     sparse array: only non-zero elements follow
```

`T` is the element type (`S`, `D`, `I`, `Z`). Elements are written with the last index varying
fastest. A **sparse** array omits every element whose bit pattern is all zero (an `S` zero is
`00000000`; `-0.0` is not zero and is written). Readers must treat an omitted element inside the
bounds as zero. Sparse dumping is used for arrays that are large and mostly zero (the P3 tables,
`E_multi_chance`, the CN spectra, `EVOD`); every other array is dense. Lines of a variable are
contiguous, and the lines of one probe invocation are contiguous in the file.

**Size** (Rn-215 samples, `Fenhance = 10`): T0 292 123 lines, 10.0 MB; P1 about 220 lines; P2 about
275 lines; one P3 record about 50 000 lines, 3.2 MB (`SpinRMSNZ` is about two thirds of it). A step
with many populated multi-chance bins writes one P3 record per bin and pass, so select steps and
passes narrowly.

**Reading**: `python3 -m harness.probes summary <file> [--names]` and
`python3 -m harness.probes show <file> <NAME> [--limit N]`; in Python
`harness.probes.read_probe_file(path)` returns one `ProbeRecord` per invocation with typed values
(Single decoded exactly to a Python float, raw hex kept for bitwise comparison).

## Selection and neutrality

* `GEF_TRACE_STEPS`, `GEF_TRACE_PASSES` (comma-separated integers or ranges such as `1,3-5`; unset
  selects nothing) come from the `scope` patch. T0 is always written. P1 and P2 use
  `Harness_StepSelected()`; P3 uses `Harness_Traced()` (step and pass selected; the event selector
  is not consulted outside the event loop). Without `-d GEF_PROBES` the inserted lines are empty.
* The probes only read variables. They add no `ReDim`, call no GEF function and draw no random
  number (they use no `Rnd`; the `rndlog` patch redefines `Rnd`). Arrays that GEF exposes through
  accessor functions (`Egamma`, `ENsci`, ...) are read through their underlying `_` arrays.
* Each probe invocation opens its file with `FreeFile`, writes and closes it, so GEF's own file
  numbers (including the `Print #f` after `Close #f` quirk, which relies on `Freefile` handing back
  the same number) are untouched.
* T0 contains a private copy of the `BranchData`/`INlast` loader (`Branchings.bas` lines 44-251,
  marked `BEGIN copy` / `END copy` in `harness_probe_t0.bi`), writing to private arrays, because GEF
  itself loads `BranchData` only in the post-pass. The loader is idempotent and ends with `Restore`/
  `Read` on `EndA`; every later `Read` in GEF follows its own `Restore`, so the DATA pointer is not
  relied on.
* `#line` directives after each inserted `#Include` keep the original BASIC line numbers for every
  later statement, so the `rnd.log` site tags (`__LINE__`) are unchanged.
* The patch must apply after `seed`, `scope`, `reseed`, `rndlog` in this order (it touches only
  lines 1570/1571, 3881/3882, 4800/4801 and 7920/7921, with one line of patch context).
  Patch sets that contain it: `seed-probes`, `seed-rndlog-probes`, `seed-reseed-rndlog-probes`
  (where `reseed.patch` exists).

## Not captured

* `ZT`, `AT`, `I_MAT`, `REmax` (target Z and A, NucTab index of the target): block-local in the
  step setup, not visible at P1. They follow from `Emode`, `P_Z_CN`, `P_A_CN`.
* The raw `NNCNtot`/`NPCNtot` counts (normalised in place before P2) and the `PGauss` cache
  (`Static ISet`/`GSet` inside the function).
* The raw DATA stream (`Restore` + `Read As String`), which M4's converter test wants: it needs the
  total token count from the converter and is added by M4 as a probe of its own.
* The `Var_*` values are written twice: T0 holds the initial ones (GEF.bas:1348-1394), P1 the final
  ones assigned at 2575-2622 (times `D_Par_Fac`), so no separate probe after 2623 is needed.
* Per-event records, post-pass quantities and the probes after 10427 (later milestones, plan §6).


## T0: tables and parameters as loaded

Written once, after the static tables, the analyzer registry and the nominal parameters are loaded, before any input is read. Context `-`. The parameter group holds the 111 variables declared at GEF.bas:894-1012 (every nominal parameter, the perturbed ones with a leading underscore) as they are after `Parameters.bas`, `ParameterManipulation.mac` (`MyparRead`, `FitparRead`) have run.

### table sizes

Consumer: M4 (loader assertions: counts and index ranges)

| Type | Scalars |
|---|---|
| I | `N_MAT_MAX`, `N_ISO_TOT`, `N_Anl`, `Z_min_branching`, `Z_max_branching`, `A_max_branching` |

### mass, shell and deformation tables

Consumer: M4 T0 exact; M5 (LDMass, AME2020, U_SHELL, DEFOtab users) reads the same tables. EVOD is declared but never filled, so it is dumped sparse (normally empty).

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `BEldmTF` | S | 0:203,0:136 | dense |
| `BEexp` | S | 0:203,0:136 | dense |
| `DEFOtab` | S | 0:236,0:136 | dense |
| `ShellMO` | S | 0:203,0:136 | dense |
| `EVOD` | S | 0:203,0:136 | sparse |

### element names

Consumer: M4 T0 exact; M13 (ENDF ZSYMAM field)

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `CElement` | Z | 1:120 | dense |

### neutron-spectrum bin limits (Spectra.bas:798)

Consumer: M4 T0 exact; M10 (variable-bin neutron spectra), M13 (dump of ENfrvar)

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `ENfrvar_lim` | D | 0:303 | dense |

### NucTab / MAT_for_ISO / Isotab

Consumer: M4 T0 exact (the spin-sorted states and `R_Lim` windows are in `Isotab`); M6 (target spin, isomer lookups); M11 (isomeric split). `R_Prob` is still zero at T0.

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `MAT_for_ISO` | I | 0:699 | dense |
| `NucTab.I_Z` | I | 0:3852 | dense |
| `NucTab.I_A` | I | 0:3852 | dense |
| `NucTab.I_ISO` | I | 0:3852 | dense |
| `NucTab.R_SPI` | S | 0:3852 | dense |
| `NucTab.I_PAR` | I | 0:3852 | dense |
| `NucTab.R_AWR` | D | 0:3852 | dense |
| `NucTab.R_EXC` | S | 0:3852 | dense |
| `Isotab.I_MAT` | I | 0:699 | dense |
| `Isotab.I_Z` | I | 0:699 | dense |
| `Isotab.I_A` | I | 0:699 | dense |
| `Isotab.N_STATES` | I | 0:699 | dense |
| `Isotab.I_ISO` | I | 0:699,0:10 | dense |
| `Isotab.R_SPI` | S | 0:699,0:10 | dense |
| `Isotab.I_PAR` | I | 0:699,0:10 | dense |
| `Isotab.R_EXC` | S | 0:699,0:10 | dense |
| `Isotab.R_Lim` | S | 0:699,0:10 | dense |
| `Isotab.R_Prob` | S | 0:699,0:10 | dense |

### BranchData / INlast: result of the Branchings.bas loader, private arrays

Consumer: M4 T0 exact (BranchData/EndA/INlast loader quirks); M11 (decay chains). Written under the names `BranchData.<field>` and `INlast`, from a private copy of the loader (GEF only loads BranchData in the post-pass).

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `BranchData.I_Z` | I | 0:3425 | dense |
| `BranchData.I_A` | I | 0:3425 | dense |
| `BranchData.I_ISO` | I | 0:3425 | dense |
| `BranchData.R_Life` | S | 0:3425 | dense |
| `BranchData.R_beta` | S | 0:3425 | dense |
| `BranchData.R_beta_plus` | S | 0:3425 | dense |
| `BranchData.R_beta_n` | S | 0:3425 | dense |
| `BranchData.R_beta_2n` | S | 0:3425 | dense |
| `BranchData.R_beta_p` | S | 0:3425 | dense |
| `BranchData.R_beta_2p` | S | 0:3425 | dense |
| `BranchData.R_IT` | S | 0:3425 | dense |
| `BranchData.R_alpha` | S | 0:3425 | dense |
| `BranchData.R_beta_m` | S | 0:3425 | dense |
| `BranchData.R_beta_plus_m` | S | 0:3425 | dense |
| `BranchData.R_beta_n_m` | S | 0:3425 | dense |
| `BranchData.R_beta_2n_m` | S | 0:3425 | dense |
| `BranchData.R_beta_p_m` | S | 0:3425 | dense |
| `BranchData.R_beta_2p_m` | S | 0:3425 | dense |
| `BranchData.R_IT_m` | S | 0:3425 | dense |
| `BranchData.R_alpha_m` | S | 0:3425 | dense |
| `BranchData.R_beta_mm` | S | 0:3425 | dense |
| `BranchData.R_beta_plus_mm` | S | 0:3425 | dense |
| `BranchData.R_beta_n_mm` | S | 0:3425 | dense |
| `BranchData.R_beta_2n_mm` | S | 0:3425 | dense |
| `BranchData.R_beta_p_mm` | S | 0:3425 | dense |
| `BranchData.R_beta_2p_mm` | S | 0:3425 | dense |
| `BranchData.R_IT_mm` | S | 0:3425 | dense |
| `BranchData.R_alpha_mm` | S | 0:3425 | dense |
| `INlast` | I | 0:90 | dense |

### analyzer registry Anl_Par(0..N_Anl)

Consumer: M4 T0 exact (registry with its naming quirks); M13 (dump writers). Entry 0 is the defaults entry.

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `Anl_Par.C_Name` | Z | 0:129 | dense |
| `Anl_Par.C_Title` | Z | 0:129 | dense |
| `Anl_Par.C_xaxis` | Z | 0:129 | dense |
| `Anl_Par.C_yaxis` | Z | 0:129 | dense |
| `Anl_Par.C_Linesymbol` | Z | 0:129 | dense |
| `Anl_Par.C_Type` | Z | 0:129 | dense |
| `Anl_Par.I_Dim` | I | 0:129 | dense |
| `Anl_Par.R_ALim` | S | 0:129,1:4,1:3 | dense |

### nominal parameters as loaded (Parameters.bas, FitparRead, ...)

Consumer: M4 T0 exact (Double literal narrowed to Single, last assignment wins); M7, M9, M10 read the same values through P3 and P1.

| Type | Scalars |
|---|---|
| S | `Emax_valid`, `Eexc_min_multi`, `_Delta_S0`, `EOscale` |
| I | `Emode` |
| S | `D_Par_Fac`, `Chisqr_Fit_min`, `_P_DZ_Mean_S1`, `_P_corr_S1`, `_P_DZ_Mean_S2`, `_P_DZ_Mean_S3`, `_P_DZ_Mean_S4`, `_P_DZ_Mean_SL5`, `_P_DZ_Mean_S5`, `ZC_Mode_SL5`, `_P_Z_Curv_S1`, `P_Z_Curvmod_S1`, `_P_Z_CurV_S2`, `_S2leftmod`, `P_Z_Curvmod_S2`, `_P_A_Width_S2`, `P_Cut_S2`, `Fmod_slope_S2`, `_P_Z_Curv_S3`, `P_Z_Curvmod_S3`, `_P_Z_Curv_S4`, `_P_Z_Curv_SL5`, `_P_Z_Curv_S5`, `P_Z_Curvmod_S4`, `P_Z_Curvmod_S5`, `_P_Shell_S1`, `_P_Shell_S2`, `_P_Shell_S3`, `_P_Shell_S4`, `_P_Shell_SL5`, `_P_Shell_S5`, `P_S5_mod`, `_PZ_S3_olap_pos`, `_PZ_S3_olap_curv`, `ETHRESHSUPPS1`, `ESIGSUPPS1`, `Level_S11`, `Shell_fading`, `_T_low_S1`, `_T_low_S2`, `_T_low_S3`, `_T_low_S4`, `_T_low_S5`, `_T_low_SL`, `T_low_S11`, `T_low_S22`, `_P_att_pol`, `P_att_pol2`, `P_att_pol3`, `_P_att_rel`, `_dE_Defo_S1`, `_dE_Defo_S2`, `_dE_Defo_S3`, `_dE_Defo_S4`, `_dE_Defo_S5`, `_betaL0`, `_betaL1`, `_betaH0`, `_betaH1`, `_dbeta_S3`, `kappa`, `kappa4`, `BFC`, `TCOLLFRAC`, `_ECOLLFRAC`, `TFCOLL`, `TCOLLMIN`, `ESHIFTSASCI_intr`, `ESHIFTSASCI_coll`, `_EDISSFRAC`, `Epot_shift`, `SIGDEFO`, `SIGDEFO_0`, `SIGDEFO_slope`, `SIGENECK`, `EexcSIGrel`, `DNECK`, `FTRUNC50`, `ZTRUNC50`, `FTRUNC28`, `ZTRUNC28`, `ZMAX_S2`, `NTRANSFEREO`, `NTRANSFERE`, `Csort`, `PZ_EO_symm`, `PN_EO_Symm`, `R_EO_THRESH`, `R_EO_SIGMA`, `R_EO_MAX`, `_POLARadd`, `POLARfac`, `T_POL_RED`, `_HOMPOL`, `ZPOL1`, `P_n_x`, `Tscale`, `Econd`, `Etrans`, `T_orbital`, `_Jscaling`, `Spin_odd`, `Esort_extend`, `Esort_slope`, `Esort_slope_S0` |
| I | `B_MyParameters` |

### initial perturbation widths (GEF.bas:1348-1394)

Consumer: M4 T0 exact (initial `Var_*`; the final values are in P1); M12

| Type | Scalars |
|---|---|
| S | `Fred_par`, `Var_P_DZ_Mean_S1`, `Var_P_Corr_S1`, `Var_P_DZ_Mean_S2`, `Var_P_A_Width_S2`, `Var_P_DZ_Mean_S3`, `Var_P_DZ_Mean_S4`, `Var_P_DZ_Mean_SL5`, `Var_P_DZ_Mean_S5`, `Var_Delta_S0`, `Var_P_Shell_S1`, `Var_P_Shell_S2`, `Var_P_Shell_S3`, `Var_P_Shell_S4`, `Var_P_Shell_SL5`, `Var_P_Shell_S5`, `Var_P_Z_Curv_S1`, `Var_P_Z_Curv_S2`, `Var_S2leftmod`, `Var_P_Z_Curv_S3`, `Var_P_Z_Curv_S4`, `Var_P_Z_Curv_SL5`, `Var_P_Z_Curv_S5`, `Var_PZ_S3_olap_pos`, `Var_PZ_S3_olap_curv`, `Var_dE_Defo_S1`, `Var_dE_Defo_S2`, `Var_dE_Defo_S3`, `Var_dE_Defo_S4`, `Var_dE_Defo_S5`, `Var_betaL0`, `Var_betaL1`, `Var_betaH0`, `Var_betaH1`, `Var_dbeta_S3`, `Var_T_low_S1`, `Var_T_low_S2`, `Var_T_low_S3`, `Var_T_low_S4`, `Var_T_low_S5`, `Var_T_low_SL`, `Var_ECOLLFRAC`, `Var_EDISSFRAC`, `Var_P_att_pol`, `Var_HOMPOL`, `Var_POLARadd`, `Var_Jscaling` |

## P1: step setup

Written for every energy step in `GEF_TRACE_STEPS`, after the entrance channel is fixed (isomer energy added to `P_E_exc`, `Spin_CN`, `Spin_target`, `Eabsgs`) and before the pre-pass. Context `step=<s> pass=- bin=- rec=<k>`.

### run position and plan

Consumer: M6 (run plan: system line, energy step, kind of fission, error-analysis switch). `I_E_iso` is the isomer index of the entrance state.

| Type | Scalars |
|---|---|
| I | `Iline`, `Ifilein`, `I_Double_Covar`, `N_Double_Covar`, `I_E_step`, `N_E_steps`, `N_E_values`, `I_E_iso`, `Bfilein`, `B_ENDF`, `B_Random_on`, `B_Error_On`, `I_Error` |
| D | `Fenhance` |
| S | `En_min`, `En_max` |

### system and step excitation

Consumer: M6 T1 exact: `P_E_exc` (after the isomer energy `E_EXC_ISO` was added), `E_EXC_TRUE`, `Spin_CN`, `Spin_target`, `Eabsgs`, `Bprot`, `Balpha`.

| Type | Scalars |
|---|---|
| I | `P_Z_CN`, `P_A_CN` |
| S | `P_E_exc`, `P_I_rms_CN` |
| I | `P_Z_CN_Double`, `P_A_CN_Double` |
| S | `P_E_exc_Double`, `E_EXC_ISO`, `E_EXC_TRUE`, `Spin_CN`, `Spin_target`, `Eabsgs`, `Bprot`, `Balpha` |

### names

Consumer: M6 (output naming with `Str(Single)`: `Csystem`, `Cfileout`, ...)

| Type | Scalars |
|---|---|
| Z | `Csystem`, `Cfileout`, `Cfileout_single`, `Cfileout_full`, `Cfileoutlmd_full`, `C_Espectrum` |

### E* spectrum of the entrance channel (ES / EM)

Consumer: M6 (spectrum reader and energy table); M9 (EM channel sampling)

| Type | Scalars |
|---|---|
| S | `Ichannel`, `W_spectrum_max` |

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `Energy_Table` | S | 0:1 | dense |
| `Spin_Table` | S | 0:1 | dense |
| `E_spectrum` | S | 0:1 | dense |
| `L_spectrum` | S | 0:1 | dense |
| `W_spectrum` | S | 0:1 | dense |
| `NE_all` | I | 0:0 | dense |
| `NE_fis` | I | 0:0 | dense |

### stale globals read later

Consumer: M9 (stale global `Z` decides the parity test of the pre-pass), M7 (`T`)

| Type | Scalars |
|---|---|
| S | `Z`, `T` |

### nominal parameters in force for this system

Consumer: M4/M6 (reset at GEF.bas:3320 for every system); `BFC` holds the third-saddle estimate assigned at GEF.bas:3354.

| Type | Scalars |
|---|---|
| S | `Emax_valid`, `Eexc_min_multi`, `_Delta_S0`, `EOscale` |
| I | `Emode` |
| S | `D_Par_Fac`, `Chisqr_Fit_min`, `_P_DZ_Mean_S1`, `_P_corr_S1`, `_P_DZ_Mean_S2`, `_P_DZ_Mean_S3`, `_P_DZ_Mean_S4`, `_P_DZ_Mean_SL5`, `_P_DZ_Mean_S5`, `ZC_Mode_SL5`, `_P_Z_Curv_S1`, `P_Z_Curvmod_S1`, `_P_Z_CurV_S2`, `_S2leftmod`, `P_Z_Curvmod_S2`, `_P_A_Width_S2`, `P_Cut_S2`, `Fmod_slope_S2`, `_P_Z_Curv_S3`, `P_Z_Curvmod_S3`, `_P_Z_Curv_S4`, `_P_Z_Curv_SL5`, `_P_Z_Curv_S5`, `P_Z_Curvmod_S4`, `P_Z_Curvmod_S5`, `_P_Shell_S1`, `_P_Shell_S2`, `_P_Shell_S3`, `_P_Shell_S4`, `_P_Shell_SL5`, `_P_Shell_S5`, `P_S5_mod`, `_PZ_S3_olap_pos`, `_PZ_S3_olap_curv`, `ETHRESHSUPPS1`, `ESIGSUPPS1`, `Level_S11`, `Shell_fading`, `_T_low_S1`, `_T_low_S2`, `_T_low_S3`, `_T_low_S4`, `_T_low_S5`, `_T_low_SL`, `T_low_S11`, `T_low_S22`, `_P_att_pol`, `P_att_pol2`, `P_att_pol3`, `_P_att_rel`, `_dE_Defo_S1`, `_dE_Defo_S2`, `_dE_Defo_S3`, `_dE_Defo_S4`, `_dE_Defo_S5`, `_betaL0`, `_betaL1`, `_betaH0`, `_betaH1`, `_dbeta_S3`, `kappa`, `kappa4`, `BFC`, `TCOLLFRAC`, `_ECOLLFRAC`, `TFCOLL`, `TCOLLMIN`, `ESHIFTSASCI_intr`, `ESHIFTSASCI_coll`, `_EDISSFRAC`, `Epot_shift`, `SIGDEFO`, `SIGDEFO_0`, `SIGDEFO_slope`, `SIGENECK`, `EexcSIGrel`, `DNECK`, `FTRUNC50`, `ZTRUNC50`, `FTRUNC28`, `ZTRUNC28`, `ZMAX_S2`, `NTRANSFEREO`, `NTRANSFERE`, `Csort`, `PZ_EO_symm`, `PN_EO_Symm`, `R_EO_THRESH`, `R_EO_SIGMA`, `R_EO_MAX`, `_POLARadd`, `POLARfac`, `T_POL_RED`, `_HOMPOL`, `ZPOL1`, `P_n_x`, `Tscale`, `Econd`, `Etrans`, `T_orbital`, `_Jscaling`, `Spin_odd`, `Esort_extend`, `Esort_slope`, `Esort_slope_S0` |
| I | `B_MyParameters` |

### perturbation widths in force (GEF.bas:2575-2622)

Consumer: M4, M12 (final `Var_*`, after `D_Par_Fac` and the sequence-file options)

| Type | Scalars |
|---|---|
| S | `Fred_par`, `Var_P_DZ_Mean_S1`, `Var_P_Corr_S1`, `Var_P_DZ_Mean_S2`, `Var_P_A_Width_S2`, `Var_P_DZ_Mean_S3`, `Var_P_DZ_Mean_S4`, `Var_P_DZ_Mean_SL5`, `Var_P_DZ_Mean_S5`, `Var_Delta_S0`, `Var_P_Shell_S1`, `Var_P_Shell_S2`, `Var_P_Shell_S3`, `Var_P_Shell_S4`, `Var_P_Shell_SL5`, `Var_P_Shell_S5`, `Var_P_Z_Curv_S1`, `Var_P_Z_Curv_S2`, `Var_S2leftmod`, `Var_P_Z_Curv_S3`, `Var_P_Z_Curv_S4`, `Var_P_Z_Curv_SL5`, `Var_P_Z_Curv_S5`, `Var_PZ_S3_olap_pos`, `Var_PZ_S3_olap_curv`, `Var_dE_Defo_S1`, `Var_dE_Defo_S2`, `Var_dE_Defo_S3`, `Var_dE_Defo_S4`, `Var_dE_Defo_S5`, `Var_betaL0`, `Var_betaL1`, `Var_betaH0`, `Var_betaH1`, `Var_dbeta_S3`, `Var_T_low_S1`, `Var_T_low_S2`, `Var_T_low_S3`, `Var_T_low_S4`, `Var_T_low_S5`, `Var_T_low_SL`, `Var_ECOLLFRAC`, `Var_EDISSFRAC`, `Var_P_att_pol`, `Var_HOMPOL`, `Var_POLARadd`, `Var_Jscaling` |

## P2: multi-chance pre-pass

Written for every energy step in `GEF_TRACE_STEPS`, after the pre-pass and its normalisations. Context as P1. When the build also defines `GEF_RNDLOG`, `Harness_Draws` (the number of `Rnd` draws made so far, `ULongInt`) is written as well; it is the draw count of everything before P2, including the pre-pass. Bounds shown below are those of the Rn-215 22 MeV sample run: `En_multi_k`, `I_emit_k`, `E_spectrum`, `L_spectrum`, `W_spectrum`, `Energy_Table`, `Spin_Table`, `NE_all`, `NE_fis` and the growable CN spectra change their extent with the data.

### pre-pass control and results

Consumer: M9 T3 (`Imulti`, `Inofirst`, `Bmulti`, threshold `Eexc_min_multi`, `N_multi_sample`; `Harness_Draws` is the Rnd draw counter, written only when the build defines GEF_RNDLOG)

| Type | Scalars |
|---|---|
| I | `Bmulti`, `Imulti`, `Inofirst`, `N_multi_sample` |
| S | `Eexc_min_multi`, `DUF` |
| I | `Emax_multi_chance`, `Nmax_multi_chance`, `Pmax_multi_chance` |
| S | `Eabsgs`, `Spin_CN`, `Z` |
| I | `Harness_Draws` |

### fission chances

Consumer: M9 T3 (every non-zero `E_multi_chance` cell, already divided by `Imulti` when `Inofirst > 0` or Emode 13; `W_chances`)

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `E_multi_chance` | S | 0:10,0:10,0:1000 | sparse |
| `W_chances` | S | 0:10,0:10 | dense |

### pre-saddle emission records

Consumer: M9 T3 (packed `En_multi_k`/`I_emit_k` records, including the Double precision loss of the packing); M10 (consumes them in the event loop)

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `En_multi_1` | I | 0:2 | dense |
| `En_multi_2` | I | 0:0 | dense |
| `En_multi_3` | I | 0:0 | dense |
| `En_multi_4` | I | 0:0 | dense |
| `En_multi_5` | I | 0:0 | dense |
| `En_multi_6` | I | 0:0 | dense |
| `I_emit_1` | I | 0:2 | dense |
| `I_emit_2` | I | 0:0 | dense |
| `I_emit_3` | I | 0:0 | dense |
| `I_emit_4` | I | 0:0 | dense |
| `I_emit_5` | I | 0:0 | dense |
| `I_emit_6` | I | 0:0 | dense |
| `J_multi_last` | I | 0:6 | dense |

### non-fission emission probabilities (normalised) and CN spectra

Consumer: M9 (`NNCNtot`/`NPCNtot` are normalised in place at GEF.bas:4711-4751 before the probe point, so the raw counts are not observable); M10/M13 (CN spectra)

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `NNCNtot` | D | 0:50 | dense |
| `NPCNtot` | D | 0:50 | dense |
| `_ENCN` | D | 0:1028 | sparse |
| `_EPCN` | D | 0:1000 | sparse |
| `_EGammaCN` | D | 0:1000 | sparse |

## P3: per-nucleus model tables of one bin

Written once per bin with `NEVTused > 0`, in every pass of `GEF_TRACE_PASSES`, of every step in `GEF_TRACE_STEPS`. Context `step=<s> pass=<p> bin=<I_E_Distr>:<I_N_Multi>:<I_Z_Multi>:<I_E_Multi> rec=<k>`. All table arrays are sparse. Parameters in effect are the working copies (the perturbed values of the pass) plus the never-perturbed parameters; for the nominal values see T0/P1.

### bin loop counters and limits

Consumer: M7/M10 (bin list; also the context of the record)

| Type | Scalars |
|---|---|
| I | `I_E_distr`, `I_N_Multi`, `I_Z_Multi`, `I_E_Multi`, `N_E_distr`, `N_N_Multi`, `N_Z_Multi`, `N_E_Multi`, `I_N_Multi_Max`, `I_Z_Multi_Max`, `I_A_Multi` |

### bin inputs

Consumer: M7 T1 (inputs of the table builder: `I_Z_CN`, `I_A_CN`, `R_E_exc_used`, `Spin_CN`, `E_rot_CN`, `NEVTused`), M9 (bin weights `R_NEVTspectrum`)

| Type | Scalars |
|---|---|
| I | `I_E_iso`, `P_Z_CN`, `P_A_CN` |
| S | `P_E_exc` |
| I | `Emode`, `I_Z_CN`, `I_A_CN`, `I_N_CN` |
| S | `R_E_exc_used`, `R_NEVTspectrum`, `Eabsgs`, `Spin_CN`, `Spin_target`, `I_rigid_spher`, `I_eff_CN`, `E_rot_CN` |
| I | `NEVTtot`, `NEVTused`, `IEVTtot` |
| S | `Racc` |
| I | `Inofirst`, `Imulti` |
| S | `Escission_lim` |

### mode centres, mean Z, mean A and N of the modes 0-5

Consumer: M7 T1 exact; M10

| Type | Scalars |
|---|---|
| S | `ZC_Mode_0`, `ZC_Mode_1`, `ZC_Mode_2`, `ZC_Mode_3`, `ZC_Mode_4`, `ZC_Mode_5`, `ZC_Mode_3_shift`, `P_Z_Mean_S0`, `P_Z_Mean_S1`, `P_Z_Mean_S2`, `P_Z_Mean_S3`, `P_Z_Mean_S4`, `P_Z_Mean_S5`, `AC_Mode_0`, `AC_Mode_1`, `AC_Mode_2`, `AC_Mode_3`, `AC_Mode_4`, `AC_Mode_5`, `NC_Mode_0`, `NC_Mode_1`, `NC_Mode_2`, `NC_Mode_3`, `NC_Mode_4`, `NC_Mode_5`, `RZpol`, `RA`, `RZ`, `ZUCD` |

### curvatures, barriers, shell effects, energies above barrier, tunnelling

Consumer: M7 T1 exact. `E_tunn` is the mode-7 value left by the EPART loop (event-loop input); `E_exc_Barr` etc. appear in the `<Control>` block

| Type | Scalars |
|---|---|
| S | `R_Z_Curv_S0`, `R_Z_Curv1_S0`, `R_A_Curv1_S0`, `R_Z_Curv2_S0`, `R_A_Curv2_S0`, `R_E_exc_Eb`, `R_E_exc_GS`, `B_F`, `B_F_ld`, `E_B`, `E_B_ld`, `E_A`, `DE_AB`, `Delta_NZ_Pol`, `R_Shell_S1_eff`, `R_Shell_S2_eff`, `R_Shell_S3_eff`, `R_Shell_S4_eff`, `R_Shell_S5_eff`, `S1_enhance`, `S1_enhance_S2`, `E_LD_S1`, `E_LD_S2`, `E_LD_S3`, `E_LD_S4`, `E_LD_S5`, `DZ_asym`, `B_S1`, `B_S2`, `B_S3`, `B_S4`, `B_S5`, `B_S11`, `B_S22`, `DES11ZPM`, `E_exc_S0_prov`, `E_exc_S1_prov`, `E_exc_S2_prov`, `E_exc_S3_prov`, `E_exc_S4_prov`, `E_exc_S5_prov`, `E_exc_S11_prov`, `E_exc_S22_prov`, `E_Min_Barr`, `E_Exc_S0`, `E_Exc_S1`, `E_Exc_S2`, `E_Exc_S3`, `E_Exc_S4`, `E_Exc_S5`, `E_Exc_S11`, `E_Exc_S22`, `E_exc_Barr`, `E_tunn`, `E_tunn_S1`, `E_tunn_S2`, `E_tunn_S3`, `E_tunn_S4` |

### temperatures, stiffness, saddle-scission energies

Consumer: M7 T1 exact. `E_POT_SCISSION`, `E_diss_Scission` and `EINTR_SCISSION` are the values left by the EPART loop (mode 7), which the event loop reads. `R_Att`, `R_Att_Sad`, `E_coll_saddle` are arrays

| Type | Scalars |
|---|---|
| S | `R_E_exc_eff`, `T_Rusanov`, `T_Coll_Mode_0`, `T_coll_Mode_1`, `T_coll_Mode_2`, `T_coll_Mode_3`, `T_coll_Mode_4`, `T_coll_Mode_5`, `T_Pol_Mode_0`, `T_Pol_Mode_1`, `T_Pol_Mode_2`, `T_Pol_Mode_3`, `T_Pol_Mode_4`, `T_Pol_Mode_5`, `T_asym_Mode_0`, `T_asym_Mode_1`, `T_asym_Mode_2`, `T_asym_Mode_3`, `T_asym_Mode_4`, `T_asym_Mode_5`, `T_low_S1_used`, `E_POT_SCISSION`, `E_diss_Scission`, `EINTR_SCISSION`, `R_Pol_Curv_S0`, `R_Pol_Curv_S1`, `R_Pol_Curv_S2`, `R_Pol_Curv_S3`, `R_Pol_Curv_S4`, `R_Pol_Curv_S5`, `P_POL_CURV_S0`, `R_E_intr_S1`, `R_E_intr_S2`, `R_E_intr_S3`, `R_E_intr_S4`, `R_E_intr_S5` |

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `R_Att` | S | 0:7 | dense |
| `R_Att_Sad` | S | 0:7 | dense |
| `E_coll_saddle` | S | 0:7 | dense |

### widths, scission energies, suppression

Consumer: M7 T1 exact; M10 (mode choice and `PBox2` use `R_slope_S2`, `SigA_*`, `Sigpol_*`)

| Type | Scalars |
|---|---|
| S | `SigZ_Mode_0`, `SigZ_Mode_1`, `SigZ_Mode_2`, `SigZ_Mode_3`, `SigZ_Mode_4`, `SigZ_Mode_5`, `SigZ_SL5`, `Sigpol_Mode_0`, `Sigpol_Mode_1`, `Sigpol_Mode_2`, `Sigpol_Mode_3`, `Sigpol_Mode_4`, `Sigpol_Mode_5`, `SigA_Mode_0`, `SigA_Mode_1`, `SigA_Mode_2`, `SigA_Mode_3`, `SigA_Mode_4`, `SigA_Mode_5`, `SigA_Mode_11`, `SigA_Mode_22`, `EsciS0`, `EsciS1`, `EsciS2`, `EsciS3`, `EsciS4`, `EsciS5`, `DEsupp`, `R_supp_S0`, `R_supp_S1`, `R_supp_S2`, `R_Supp_S3`, `R_slope_S2` |
| I | `B_supp` |
| S | `B_nopot` |

### mode yields

Consumer: M7 T1 exact; M10 (mode choice)

| Type | Scalars |
|---|---|
| S | `Yield_Mode_0`, `Yield_Mode_1`, `Yield_Mode_2`, `Yield_Mode_3`, `Yield_Mode_4`, `Yield_Mode_5`, `Yield_Mode_11`, `Yield_Mode_22`, `Yield_Norm`, `P_selected` |
| I | `I_Mode_selected` |

### fragment temperatures and level-density energies

Consumer: M7 T1 exact

| Type | Scalars |
|---|---|
| S | `DU0`, `DU1`, `DU2`, `DU3`, `DU4`, `DU5`, `T_intr_Mode_0`, `T_intr_Mode_1_heavy`, `T_intr_Mode_1_light`, `T_intr_Mode_2_heavy`, `T_intr_Mode_2_light`, `T_intr_Mode_3_heavy`, `T_intr_Mode_3_light`, `T_intr_Mode_4_heavy`, `T_intr_Mode_4_light`, `T_intr_Mode_5_heavy`, `T_intr_Mode_5_light` |

### stale temporaries left by the table builder

Consumer: M7/M9 (state leaks: global `Z`, `T`, `beta1`, ..., see QUIRKS Q-007)

| Type | Scalars |
|---|---|
| S | `beta1`, `beta2`, `rbeta`, `beta1_opt`, `beta2_opt`, `beta1_prev`, `beta2_prev`, `E_defo`, `Z1`, `Z2`, `A1`, `A2` |
| I | `IZ1`, `IN1`, `IZ2`, `IN2`, `IA1`, `IA2` |
| S | `Z`, `T` |

### persistent per-fragment tables (sparse)

Consumer: M7 T1 exact, including the never-cleared parts of `EPART`, `PEOZ`, `PEON` (stale values outside A in [40, A_CN-40]) and `Beta(4,1,*) = 0`; M10 (all are event-loop inputs); `EMpot` only for the first-chance bin

| Array | Type | Bounds | Dump |
|---|---|---|---|
| `beta` | S | -1:7,1:2,0:150 | sparse |
| `Edefo` | S | -1:5,1:2,0:150 | sparse |
| `Zmean` | S | 0:5,1:2,0:350 | sparse |
| `Zshift` | S | 0:5,1:2,0:350 | sparse |
| `Temp` | S | 0:5,1:2,0:350 | sparse |
| `TempFF` | S | 0:5,1:2,0:350 | sparse |
| `Eshell` | S | 0:5,1:2,0:350 | sparse |
| `PEOZ` | S | 0:7,1:2,0:350 | sparse |
| `PEON` | S | 0:7,1:2,0:350 | sparse |
| `EPART` | S | 0:7,1:2,0:350 | sparse |
| `SpinRMSNZ` | S | 0:7,1:2,1:200,1:150 | sparse |
| `EMpot` | S | 0:7,0:150 | sparse |

### working parameter set (perturbed copies)

Consumer: M7 (inject these values into the C++ table builder: it removes the RNG dependence for perturbed passes); M12 (the 46 draws plus `P_att_rel`)

| Type | Scalars |
|---|---|
| S | `P_DZ_Mean_S1`, `P_corr_S1`, `P_DZ_Mean_S2`, `P_DZ_Mean_S3`, `P_DZ_Mean_S4`, `P_DZ_Mean_SL5`, `P_DZ_Mean_S5`, `P_Z_Curv_S1`, `P_Z_Curv_S2`, `S2leftmod`, `P_A_Width_S2`, `P_Z_Curv_S3`, `P_Z_Curv_S4`, `P_Z_Curv_SL5`, `P_Z_Curv_S5`, `PZ_S3_olap_pos`, `PZ_S3_olap_curv`, `Delta_S0`, `P_Shell_S1`, `P_Shell_S2`, `P_Shell_S3`, `P_Shell_S4`, `P_Shell_SL5`, `P_Shell_S5`, `dE_Defo_S1`, `dE_Defo_S2`, `dE_Defo_S3`, `dE_Defo_S4`, `dE_Defo_S5`, `betaL0`, `betaL1`, `betaH0`, `betaH1`, `dbeta_S3`, `T_low_S1`, `T_low_S2`, `T_low_S3`, `T_low_S4`, `T_low_S5`, `T_low_SL`, `ECOLLFRAC`, `EDISSFRAC`, `P_att_pol`, `P_att_rel`, `HOMPOL`, `POLARadd`, `Jscaling` |

### non-perturbed parameters

Consumer: M7, M10 (parameters read directly by the table builder and the event loop)

| Type | Scalars |
|---|---|
| S | `Emax_valid`, `EOscale`, `ZC_Mode_SL5`, `P_Z_Curvmod_S1`, `P_Z_Curvmod_S2`, `P_Cut_S2`, `Fmod_slope_S2`, `P_Z_Curvmod_S3`, `P_Z_Curvmod_S4`, `P_Z_Curvmod_S5`, `P_S5_mod`, `ETHRESHSUPPS1`, `ESIGSUPPS1`, `Level_S11`, `Shell_fading`, `T_low_S11`, `T_low_S22`, `P_att_pol2`, `P_att_pol3`, `kappa`, `kappa4`, `BFC`, `TCOLLFRAC`, `TFCOLL`, `TCOLLMIN`, `ESHIFTSASCI_intr`, `ESHIFTSASCI_coll`, `Epot_shift`, `SIGDEFO`, `SIGDEFO_0`, `SIGDEFO_slope`, `SIGENECK`, `EexcSIGrel`, `DNECK`, `FTRUNC50`, `ZTRUNC50`, `FTRUNC28`, `ZTRUNC28`, `ZMAX_S2`, `NTRANSFEREO`, `NTRANSFERE`, `Csort`, `PZ_EO_symm`, `PN_EO_Symm`, `R_EO_THRESH`, `R_EO_SIGMA`, `R_EO_MAX`, `POLARfac`, `T_POL_RED`, `ZPOL1`, `P_n_x`, `Tscale`, `Econd`, `Etrans`, `T_orbital`, `Spin_odd`, `Esort_extend`, `Esort_slope`, `Esort_slope_S0` |
