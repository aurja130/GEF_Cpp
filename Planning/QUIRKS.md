# Quirk Register

**Created:** M0.9. **Source revision:** every BASIC line number in this file refers to the submodule `Reference/GEF_code/` at commit `ba9f0aa` (GEF 2025/1.2). File names are relative to `Reference/GEF_code/source/`.
**Related documents:** `Planning/IMPLEMENTATION_STRATEGY.md` §2.1 (why the register exists), `Planning/CODING_STANDARDS.md` §2.7 (annotations and switches) and §5 (how to establish what a BASIC line computes), `Planning/MILESTONE_0_PLAN.md` M0.9 (seed list) and §7 (build risk), `tools/fbsrc/README.md` (the verification tools).

## 1. Purpose and use

The C++ port reproduces the BASIC program, defects included (strategy §2.1, vision §3 "Fidelity first"). This register lists every known place where the BASIC code does something other than what it evidently intends, together with the evidence for it.

- **Reproduce by default.** C++ code that ports a quirk reproduces the BASIC behaviour. The corrected behaviour may exist only behind a named switch in the `Fidelity` configuration; every switch defaults to `false` (= reproduce).
- **Annotate.** The C++ statement group that reproduces a quirk carries `// QUIRK(Q-0xx): <one-line summary>` next to its provenance comment (`// GEF.bas:9417`). Never annotate with an ID that is not in this register: add the entry first.
- **Fixing is separate.** Changing a switch default is a separate, user-approved decision with measured impact, never part of a porting milestone.
- **Build notes** (section 5) are differences that come from the toolchain, not from GEF. They have `B-` IDs and no fidelity switch.

## 2. Entry format

| Field | Meaning |
|---|---|
| **ID** | `Q-001`, `Q-002`, … IDs are stable: never renumbered or reused. A withdrawn entry stays, marked *withdrawn* with the reason. |
| **Title** | One line. |
| **BASIC location** | `file:line` or `file:first-last` at `ba9f0aa`. Where the seed list gave other numbers, the entry says what was corrected. |
| **Mechanism** | What the code does, with the BASIC statement quoted briefly and, where the generated C proves it, the relevant C statement. |
| **Effect** | Observed (in recorded output) or expected effect on results. |
| **Evidence status** | Exactly one of the three values below. |
| **Evidence** | The commands run and what they showed; the output files and lines inspected. |
| **Fidelity switch** | `fix_<corrected behaviour>`, snake_case, `false` by default (coding standards §2.7). |
| **C++ symbol** | The C++ function or type that reproduces the quirk. `not yet ported` until the owning milestone ports it. |
| **Owning milestone** | The milestone (strategy §3) that ports the code and must reproduce and test the quirk. |

**Evidence status vocabulary:**

- *confirmed in output*: the effect is visible in recorded BASIC output (`validation/test_run/`, the Rn-215 (n,f) run, or `validation/reference/`). The file and line are cited.
- *confirmed by fbc C*: the C that fbc 1.10.1 generated (`build/fbsrc/ba9f0aa/src/GEF.c`) shows the behaviour. The `fbline` command is cited. Where the behaviour depends on the FreeBASIC runtime rather than on the C alone, a scratch probe compiled with the pinned fbc is cited as well.
- *read only*: established by reading the BASIC source (including `fbdef --refs` searches) only. The entry names the milestone whose tests will confirm it.

Statements marked **[INFERENCE]** are reasoning from the evidence, not observations.

Tool commands are run from the repository root: `python3 -m tools.fbsrc.fbline <file>:<line>` prints the BASIC line and its generated C (`GEF.c:<line>` below refers to `build/fbsrc/ba9f0aa/src/GEF.c`); `python3 -m tools.fbsrc.fbdef <name> --refs` lists every non-comment reference.

## 3. Adding and updating entries

- A new suspected quirk gets the next free ID, the full set of fields, and the strongest evidence status that can be reached with the M0 tools (`fbline`, `fbdef`, recorded outputs). Do not infer BASIC semantics from reading alone when `fbline` can show the C (coding standards §5).
- **Every milestone closes by updating this register.** For each entry it owns, the milestone:
  1. ports the quirk behind its switch and fills in **C++ symbol**;
  2. adds the test that shows the C++ code reproduces BASIC (and, where cheap, that the switch changes exactly the expected observable);
  3. upgrades **Evidence status** when its probes or comparisons confirm the effect, citing the test;
  4. adds any newly found quirk, and corrects locations or claims that its work shows to be wrong (keep the old claim in the entry, marked as corrected).
- If a correction shows an entry is not a quirk at all, mark it *withdrawn* with the evidence; do not delete it.
- Keep the summary table (section 6) in step with the entries.

## 4. Quirk entries

### Q-001 Heavy-fragment E1 gammas dropped from the total gamma spectrum

- **BASIC location:** `GEF.bas:9417`
- **Mechanism:** `Egamma(Nspectrum) = Egamma(Nspectrum) + 1`. `Egamma` is the read-accessor *function* `EGamma(I_EkeV As Integer)` (`Spectra.bas:1505`), not an array, so the statement parses as a call whose argument is the comparison `Nspectrum = Egamma(Nspectrum) + 1`; the result is discarded. Generated C: `double vr1 = EGAMMA( NSPECTRUM$20 );` then `EGAMMA( (int64)-((double)NSPECTRUM$20 == (vr1 + 0x1.p+0)) );`. The light-fragment E1 loop (`GEF.bas:9299`) uses `Acc_Egamma`; the heavy-fragment loop fills only `Acc_EgammaH` (`GEF.bas:9422`).
- **Effect:** the total prompt-gamma spectrum `Egamma` (and every quantity derived from it) lacks the heavy-fragment statistical (E1) gammas. `EgammaH` still contains them.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:9417` → GEF.c:69070–69072 as quoted. Output: in the first block of `validation/test_run/dmp/Z86_A215_n_E2.53e-08MeV/Egamma.dmp` (analyzers `Egamma` line 7, `EgammaL` line 424, `EgammaH` line 725, `EgammaE2` line 1000, all 1 keV bins) the 105 bins 0–104 keV of `Egamma` equal `EgammaL` exactly, although `EgammaH` holds 295 454 counts in those bins and `EgammaE2` holds none. Totals: `Egamma` 3 879 767 counts, `EgammaL` + `EgammaH` 6 308 539.
- **Fidelity switch:** `fix_heavy_e1_gammas`
- **C++ symbol:** not yet ported
- **Owning milestone:** M10

### Q-002 `ENsci` writes dropped

- **BASIC location:** `GEF.bas:8129, 8152`
- **Mechanism:** `ENsci(Cint(Array_E_n1_ss(I)*1000)) = ENsci(Cint(Array_E_n1_ss(I)*1000)) + 1` (and the same with `Array_E_n2_ss` at 8152). `ENsci` is the accessor function `ENsci(I_EkeV As Integer)` (`Spectra.bas:734`), so this is the Q-001 no-op: GEF.c:64940/64942 call `ENSCI(...)` twice, the second time with the comparison as argument, and discard the result (GEF.c:65051/65053 for 8152).
- **Effect (expected):** the saddle-to-scission neutron spectrum `ENsci` stays empty, so the `ENsci` dump in `EN.dmp`, the `<Nspectrum>` saddle-to-scission column and `Enscimean` (`GEF.bas:13916–13925`) are zero even when `NNsci` counts such neutrons.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline GEF.bas:8129` and `fbline GEF.bas:8152` as quoted; `fbdef ENsci` → function at `Spectra.bas:734`. Not observable in `validation/test_run`: no saddle-to-scission neutrons occur in the Rn-215 run (all 63 `Mean value (from saddle to scission)` lines in `out/GEF_86_215_n.dat` read 0). Output confirmation needs a system with saddle-to-scission emission (M10 T4).
- **Fidelity switch:** `fix_ensci_fill`
- **C++ symbol:** not yet ported
- **Owning milestone:** M10

### Q-003 Independent-yield uncertainty cap adds instead of setting

- **BASIC location:** `GEF.bas:11383-11391`, `Spectra.bas:1788-1800`
- **Mechanism:** the final σ of `ZISOPOST` is written with `Acc_d_ZISOPOST(0,I,J,sqr(...))` (11383) and then "capped" with `Acc_d_ZISOPOST(0,I,J,ZISOPOST(I,J))` (11391) when `d_ZISOPOST(0,I,J) > ZISOPOST(I,J) or d_ZISOPOST(0,I,J) = 0`. `Acc_d_ZISOPOST` accumulates: `_d_ZISOPOST(I_S,I_A,I_Z) = _d_ZISOPOST(I_S,I_A,I_Z) + Value` (Spectra.bas:1799). The commented-out originals (11381, 11386, 11390) assigned.
- **Effect:** where σ > Y the printed uncertainty is σ + Y instead of Y; where σ = 0 it is 0 + Y (which looks correct). Printed independent-yield uncertainties can therefore exceed the yield.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:11380-11393` → GEF.c:81040 `ACC_D_ZISOPOST( 0ll, I$, J$, __builtin_sqrt(...) )` and GEF.c:81071 `ACC_D_ZISOPOST( 0ll, I$, J$, vr9 )` after the test at GEF.c:81065; `fbline Spectra.bas:1788-1800` → GEF.c:8374 adds `VALUE$1`. Output `validation/test_run/out/GEF_86_215_n.dat:362`: A=62, Z=26, Y=0.000200, ±0.000757 (= 0.000557 + 0.000200); line 364: Y=0.000400, ±0.001994.
- **Fidelity switch:** `fix_uncertainty_cap`
- **C++ symbol:** not yet ported
- **Owning milestone:** M12 (printed by M13)

### Q-004 `EdefoA` always zero

- **BASIC location:** `GEF.bas:10245`
- **Mechanism:** `If I >= LBound(EdefoA,1) And I <= UBound(EdefoA,I) Then` uses the loop variable `I` (0…350) as the *dimension* argument. GEF.c:74067 `fb_ArrayUBound( (struct $7FBARRAYIKvE*)&EDEFOA$0, I$ )`. For the 1-D array `EdefoA(350)` (`Spectra.bas:332`) the fbc runtime returns `UBound(EdefoA,0)` = 1 (the number of dimensions), `UBound(EdefoA,1)` = 350, and −1 for any dimension ≥ 2. Only `I` = 0 and 1 pass the test, and those mass numbers carry no events (`Nenner` = 0), so they are set to 0; every other element keeps the 0 from the reset loop at 10235–10237.
- **Effect:** the `EdefoA` analyzer (mean deformation energy versus pre-neutron mass) is identically zero.
- **Seed claim refined:** the seed said the wrong dimension makes it zero; precisely, elements 0 and 1 are written (with 0) and all others are never written.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:10225-10255` → GEF.c:74065–74069 as quoted. Runtime probe (scratch file `build/quirks_scratch/ub.bas`, compiled and run with the pinned fbc 1.10.1; source below) prints `UBound(EdefoA,0)= 1`, `I= 1 UBound(EdefoA,I)= 350`, `I= 2 UBound(EdefoA,I)=-1`, `I= 3 UBound(EdefoA,I)=-1`, `UBound(NZ2,3)=-1 LBound(NZ2,3)= 0`, `passes: I= 0`, `passes: I= 1`, and nothing else. Output `validation/test_run/dmp/Z86_A215_n_E14MeV/XE.dmp:35-42`: `ANALYZER(EdefoA)`, `A: (X = 0 TO 1 BY 1)`, data `0,0,`.

  ```basic
  ReDim Shared EdefoA(350) As Double
  ReDim Shared NZ2(0 To 50, 20 To 70) As Double   ' used by Q-027
  Dim As Integer I
  Print "UBound(EdefoA,0)="; UBound(EdefoA, 0)
  For I = 1 To 3 : Print "I="; I; " UBound(EdefoA,I)="; UBound(EdefoA, I) : Next
  Print "UBound(NZ2,3)="; UBound(NZ2, 3); " LBound(NZ2,3)="; LBound(NZ2, 3)
  For I = 0 To 350
    If I >= LBound(EdefoA,1) And I <= UBound(EdefoA,I) Then Print "passes: I="; I
  Next
  ```
- **Fidelity switch:** `fix_edefo_a_dimension`
- **C++ symbol:** not yet ported
- **Owning milestone:** M11

### Q-005 `ZApre.dmp`/`ZApost.dmp` rows written through the closed results-file number

- **BASIC location:** `GEF.bas:14842`, `GEF.bas:15019-15157` (rows at 15036, 15060, 15077, 15102, 15126, 15150)
- **Mechanism:** the results file `#f` is closed at 14842 (`Close #f`). The ZApre/ZApost dump blocks open `DMPFile = Freefile` (15019, 15085) and write their headers to `#DMPFile`, but the data rows use `Print #f,Using "####    ###.######";J;...`. GEF.c:168619–168631 prints through `F$`, not `DMPFILE$`. The rows land in the dump file only because `Freefile` (GEF.c:168456 `fb_FileFree()`) hands out the number that `f` still holds.
- **Effect:** in the recorded run the rows are present and correctly placed. [INFERENCE] If any lower file number were open at that point (e.g. a list-mode file), the rows would go to that file or be lost.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:14836-14846` → GEF.c:166165 `fb_FileClose( (int32)F$ )`; `fbline GEF.bas:15019-15020` and `fbline GEF.bas:15036` as quoted. Output `validation/test_run/dmp/Z86_A215_n_E14MeV/ZApre.dmp:9-19`: rows `  26      0.000200` etc. in the `####    ###.######` format under each `A:  X     Y,LTR1` header.
- **Fidelity switch:** `fix_za_dmp_file_handle`. [INFERENCE] A C++ writer has no file numbers; reproducing means writing the rows to the dump file, which is also the fixed behaviour, so this switch is expected to have no effect. M13 decides whether it is needed.
- **C++ symbol:** not yet ported
- **Owning milestone:** M13

### Q-006 `Nmulti2dpre`/`Nmulti2dpost` never cleared

- **BASIC location:** `CLEARspectra.bas:172-181`
- **Mechanism:** the loops bounded by `Nmulti2dpre`/`Nmulti2dpost` clear `N2dpre(I,J) = 0` and `N2dpost(I,J) = 0` instead (GEF.c:52023 writes `N2DPRE$0`). `fbdef Nmulti2dpre --refs` shows no other write except the per-event `+ 1` at `GEF.bas:9157/9165` (`9161/9169` for post) and the startup `Redim` at `Spectra.bas:585/594` (Spectra.bas is included once, `GEF.bas:1278`).
- **Effect:** the counts accumulate over every pass and every energy step of the process. `NmultiApre/post` (`GEF.bas:10086-10111`), the `Nmean (CN)` columns of `out/` and `NA.dmp`, are ratios of these accumulated counts, so later steps carry earlier steps' pre-fission neutron multiplicities.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline CLEARspectra.bas:172-180` as quoted; `fbline GEF.bas:9155-9157` → GEF.c:68158 increments `NMULTI2DPRE$0`. Output `validation/test_run/out/GEF_86_215_n.dat`, `Apre` table: in the step-1 thermal block of the logged process (written 18:21:13) all 85 rows (lines 8289–8373) have `Nmean (CN)` = 0.000; in the final thermal block of the same process (written 20:06:41) 92 of 98 rows (lines 432063–432160) are non-zero, e.g. 0.250, 0.200, 0.014, although no pre-fission neutron can be emitted at 2.53e-08 MeV. Rows A = 55, 56 appear there with all `N2dpre` columns 0.
- **Fidelity switch:** `fix_nmulti2d_clear`
- **C++ symbol:** not yet ported
- **Owning milestone:** M10 (clear sets); printed by M11/M13

### Q-007 Stale global `Z` in the pre-pass parity test

- **BASIC location:** `GEF.bas:4322`
- **Mechanism:** `If Z Mod 2 = 0 And (A_left - 1 - Z_left) Mod 2 = 0 Then` tests the module-level `Dim Shared As Single Z` (`GEF.bas:790`), not the emitting nucleus `Z_left`. GEF.c:48186: `fb_F2L( Z$ ) % 2ll`. `fbdef Z --refs` shows the global is written only by the table builder's Z(A) loops (`GEF.bas:5893, 5895, 5918, 5939, 5957, 5971`; GEF.c:60280 `Z$ = ZUCD$;` for 5971), which run after the pre-pass of each step. At process start the global is 0.
- **Effect (expected):** in the first energy step of a process the Z-parity half of the even-even GN suppression test (4322–4324) is evaluated with Z = 0, i.e. as even; in later steps it uses whatever `Z` the last table-builder bin left (the Mode-5 loop, last iteration `ZUCD = (I_A_CN-10)/I_A_CN*I_Z_CN`). [INFERENCE] For the Rn-216 compound nucleus that value rounds to 82 (even), so the first step does not differ there; it differs for systems where that value rounds to an odd number.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline GEF.bas:4318-4326`, `fbline GEF.bas:5971`, `fbline GEF.bas:5893` as quoted; `fbdef Z --refs`. The run-level effect is confirmed by the M9 T3 pre-pass comparison (probe P1 captures the stale `Z`).
- **Fidelity switch:** `fix_prepass_parity_z`
- **C++ symbol:** not yet ported
- **Owning milestone:** M9

### Q-008 Mode-7 `E_tunn`, `E_pot_scission`, `E_diss_Scission` leak into the event loop

- **BASIC location:** `GEF.bas:7213-7219` (inside `For I_Mode = 0 To 7`, 7182–7379). Seed said 7214–7219; the `E_tunn` assignment is at 7213.
- **Mechanism:** the energy-partition loop overwrites the shared globals `E_tunn` (`Dim Shared`, 791), `E_pot_scission` (1546) and `E_diss_Scission` (1547) for each mode: `If Etot < 0 Then E_tunn = -Etot Else E_tunn = 0` (GEF.c:63334/63342 write `E_TUNN$`), `E_diss_Scission = EDISSFRAC * (E_pot_scission - E_tunn) + Epot_shift` (GEF.c:63358). After the loop they hold the `I_Mode = 7` values. The event loop reads them for every mode: `E_diss_Scission` at 8188, 8439, 8450, 8457, 8510, 8529; `E_tunn` at 8613. The earlier values set at 6311/6344 (used at 6614–6619, 6664, 6679) are lost.
- **Effect (expected):** event-loop energies use the mode-7 (S22) tunnelling and dissipation values for all modes; the results file prints the mode-7 `E_POT_Scission` (`GEF.bas:14658`).
- **Evidence status:** *read only*
- **Evidence:** `fbdef E_tunn --refs`, `fbdef E_diss_Scission --refs`; `fbline GEF.bas:7213`, `fbline GEF.bas:7218`. Confirmed by M7 (probe P3 captures the post-loop values).
- **Fidelity switch:** `fix_mode7_scission_energy_leak`
- **C++ symbol:** not yet ported
- **Owning milestone:** M7 (consumed in M10)

### Q-009 `Beta(4,1,·)` never set

- **BASIC location:** `GEF.bas:5831`
- **Mechanism:** the Mode-4 loop computes the light-fragment deformation but writes `Beta(5,1,I_short) = rbeta` (GEF.c:59700 indexes `BETA$` with `* 5ll) + 1ll`). The Mode-5 loop then overwrites `Beta(5,1,I_short)` over the same `I_short` range (5848). `fbdef Beta --refs` lists every write; none targets `Beta(4,1,·)`, which keeps the 0 from `ReDim Shared Beta(-1 To 7,1 To 2,150)` (1084). `Edefo(4,1,·)` (5835) is computed with the correct `rbeta`.
- **Effect (expected):** readers of `Beta(4,1,·)` (`GEF.bas:5958`, Z(A) for mode 4; `GEF.bas:7433`, the rigid moment of inertia in `SpinRMSNZ`) see a spherical light fragment for mode 4.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline GEF.bas:5831` as quoted; `fbdef Beta --refs`.
- **Fidelity switch:** `fix_beta_mode4_light`
- **C++ symbol:** not yet ported
- **Owning milestone:** M7

### Q-010 `EPART`/`PEOZ`/`PEON` never cleared outside the filled range

- **BASIC location:** `GEF.bas:1169, 1181, 1193` (`ReDim Shared … (0 To 7,1 To 2,350)`), fills `GEF.bas:7230-7325` and `7376-7377`, reads `GEF.bas:7437, 7475`. Seed said 7173–7379, 7436; the fills start at the `For IA1 = 40 To I_A_CN - 40` loop (7230) and the `SpinRMSNZ` read is at 7437.
- **Mechanism:** each table build fills only `IA1 = 40 … I_A_CN-40` (and the mirror `IA2 = I_A_CN-IA1`, same range). `fbdef EPART|PEOZ|PEON --refs` shows no clearing anywhere (outside the fill loops only the startup `ReDim`, the `XE.dmp` dump at 15452–15458 and the readers). The `SpinRMSNZ` loop (7421–7500) runs `IA1 = Int(AUCD-15) To Int(AUCD+15)` with `IZ1` from 10, so it reads `EPART(I_Mode,·,IA1)` for `IA1 < 40` or `> I_A_CN-40`.
- **Effect (expected):** those `SpinRMSNZ` entries use values left by earlier bins, steps or systems, or the startup zeros. The other readers of `EPART`/`PEOZ`/`PEON` (7550–7692, 7870–7872, and in the event loop 8073–8098, 8326–8327, 8421, 8484) also see stale values if their mass index falls outside the filled range.
- **Evidence status:** *read only*
- **Evidence:** `fbdef EPART --refs`, `fbdef PEOZ --refs`, `fbdef PEON --refs`; source lines above. Confirmed by M7 (probe P3 dumps the touched ranges).
- **Fidelity switch:** `fix_epart_peoz_peon_clear`
- **C++ symbol:** not yet ported
- **Owning milestone:** M7

### Q-011 `EOscale` applied twice on the mirrored half

- **BASIC location:** `GEF.bas:7322-7325`, with the copies at `GEF.bas:7294-7297` (seed gave 7322 only)
- **Mechanism:** in the loop `For IA1 = 40 To I_A_CN - 40`, iteration `IA1` sets `PEOZ(m,1,IA1)` and `PEOZ(m,2,IA2)` and multiplies both by `EOscale` (7322–7325). For `IA1 > IA2` the values are not recomputed but copied from the other half: `PEOZ(I_Mode,1,IA1) = PEOZ(I_Mode,2,IA1)` (7294; GEF.c:63600 reads index 2 into index 1). Those sources were already scaled in the earlier iteration `A_CN − IA1`, and 7322–7325 scale them again. The same holds for `PEON` and for the `(m,2,IA2)` copies.
- **Effect (expected):** the mirrored half carries `EOscale²`. No effect for `EOscale` ∈ {0, 1}; the default is 1 (`GEF.bas:897`), changed by the `EOfac` option (2097) or the dialogue (2331–2333).
- **Evidence status:** *read only*
- **Evidence:** `fbline GEF.bas:7322`, `fbline GEF.bas:7294`; `fbdef EOscale --refs`. Confirmed by M7 (P3 with an `EOscale ≠ 1` run; the recorded run uses 1).
- **Fidelity switch:** `fix_eoscale_single_application`
- **C++ symbol:** not yet ported
- **Owning milestone:** M7

### Q-012 `J_attempt` retry fills histograms again

- **BASIC location:** `GEF.bas:8676-8738` (seed said 8676–8728; the retry `Goto` is at 8738)
- **Mechanism:** label `J_attempt:` (8676, GEF.c:66432 `label$4106`) precedes `Acc_JFRAGpre` (8692, 8695), `Acc_AQpre` (8724, 8725) and `Qvalues(Qvalue_sci) = Qvalues(Qvalue_sci) + 1` (8727; a real array, GEF.c:66625). When `TKE < 0`, `If N_J_attempt <= 3 Then Goto J_attempt` (8738; GEF.c:66654 `goto label$4106`) redraws the spins and passes the fills again.
- **Effect (expected):** an event that needs retries is counted up to four times (one pass plus up to three retries) in `JFRAGpre`, `AQpre` and `Qvalues`. Seed said "twice"; the bound is four.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline GEF.bas:8676-8677`, `fbline GEF.bas:8738`, `fbline GEF.bas:8727 --symbols` as quoted. Frequency of retries is confirmed by M10 (T2a stage replay).
- **Fidelity switch:** `fix_j_attempt_double_fill`
- **C++ symbol:** not yet ported
- **Owning milestone:** M10

### Q-013 Isomer spin windows double-count shared endpoints

- **BASIC location:** `GEF.bas:14258-14265` (seed gave 14212–14300 for Q-013 and Q-014 together)
- **Mechanism:** state 1 sums `For RJ = 0 To Isotab(Iiso).R_lim(1) Step 1`; state K sums `For RJ = Isotab(Iiso).R_lim(K-1) To Isotab(Iiso).R_lim(K) Step 1`. `RJ` is `Single`; `JFRAGpost` takes an `Integer` spin (`Spectra.bas:393`), so each `RJ` is rounded with `fb_F2L` (half to even). GEF.c:102776 `JFRAGPOST( I$ - J$, J$, fb_F2L( RJ$8 ) )`; GEF.c:102808 starts window K at `R_lim(K-1)`.
- **Effect (expected):** windows K−1 and K share one spin bin whenever the last `RJ` of window K−1 and `R_lim(K-1)` round to the same integer; they never leave a gap. For state 1 (which starts at `RJ = 0`) this happens whenever `R_lim(1)` rounds down (fractional part < 0.5, exactly .5 with an even integer part, or an integer). The recorded first limits are mostly of that kind (e.g. 1.267754, 4.142857, 5.356731 in `out/GEF_86_215_n.dat:3691-3697`). Isomeric yields `R_Prob` and the ENDF MT454 isomer split are affected.
- **Seed claim refined:** whether the endpoint is counted twice depends on how `RJ` rounds at the boundary (and, for K ≥ 3, on `R_lim(K-2)`), not on the boundary being shared alone.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline GEF.bas:14258-14266` as quoted; `fbdef JFRAGpost`. Confirmed numerically by M11 (T1, probe-fed `JFRAGpost`).
- **Fidelity switch:** `fix_isomer_window_endpoints`
- **C++ symbol:** not yet ported
- **Owning milestone:** M11

### Q-014 `Isotab.R_lim` clamped in place

- **BASIC location:** `GEF.bas:14253-14257`
- **Mechanism:** `If Isotab(Iiso).R_lim(K) > 50 Then Isotab(Iiso).R_lim(K) = 50` writes the global table (GEF.c:102741 stores `0x1.9p+5f` into `ISOTAB$`). The loaders set the top limit to `1.E3` (`NucPropJEFF33.bas:170, 173`). `fbdef R_lim --refs` shows no other reader in the compiled program besides 14254–14288.
- **Effect:** the `Upper limit` column of `<Isomeric_yields>` prints 50 instead of the table value, and the table stays modified for the rest of the process. [INFERENCE] No other computation reads `R_lim`, so the in-place persistence changes nothing else in this build.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:14255` as quoted. Output `validation/test_run/out/GEF_86_215_n.dat:3692, 3695, 3698, 3701, 3705, 3708`: the last state of each nuclide shows `Upper limit` 50.
- **Fidelity switch:** `fix_r_lim_local_clamp`
- **C++ symbol:** not yet ported
- **Owning milestone:** M11 (table: M4)

### Q-015 BranchData isomer row overwrites `R_alpha`

- **BASIC location:** `Branchings.bas:157-158` (seed said `Branchings.bas:147`, which is an `End If`)
- **Mechanism:** for an isomer row, `Read BranchData(I_Branch).R_alpha_m` is followed by `BranchData(I_Branch).R_alpha = BranchData(I_Branch).R_alpha_m * 0.01`. GEF.c:106335 writes offset +56 (the `R_alpha` field, the same offset written by the ground-state line 121, GEF.c:106275) from offset +88 (`R_alpha_m`). The analogous `_mm` line 192 is inside a comment block (fbline: no C).
- **Effect (expected):** the ground-state α branching of that record is replaced by the isomer's (scaled to a fraction), and `R_alpha_m` stays in percent. Both are read in the decay sweeps (`Branchings.bas:365-368, 447-450`).
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline Branchings.bas:157-158`, `fbline Branchings.bas:121`, `fbline Branchings.bas:192` (exit 1). Branchings.bas is included twice (`GEF.bas:14704, 14836`), so the C appears twice (also GEF.c:158685).
- **Fidelity switch:** `fix_branch_alpha_isomer`
- **C++ symbol:** not yet ported
- **Owning milestone:** M4

### Q-016 3rd-isomer missing-branch fallback uses state 2

- **BASIC location:** `Branchings.bas:430-437` (seed said 434–438; key lines 435–436)
- **Mechanism:** when no branch record exists for the third isomer (`NZIcumu(IN,IZ,3) > 0`, 359), the `Else` branch assumes IT but does `Radd = NZIcumu(IN,IZ,2)` / `NZIcumu(IN,IZ,0) = NZIcumu(IN,IZ,0) + Radd`. GEF.c:107504 reads offset +8 bytes (index 2 of the `Single` state dimension).
- **Effect (expected):** the third isomer's population never reaches the ground state, and the second isomer's population is added to the ground state an extra time (its own block at 440ff adds it again). Seed said "moves state 2": nothing is removed from state 2; it is added twice.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline Branchings.bas:435-436` as quoted. Confirmed numerically by M11 driver tests with synthetic `NZPOST`.
- **Fidelity switch:** `fix_third_isomer_fallback`
- **C++ symbol:** not yet ported
- **Owning milestone:** M11

### Q-017 Branch-table loading stops at Ra-234

- **BASIC location:** `Branchings.bas:225-228` (seed: "Branchings.bas loader"); data `DCLbranchingJEFF33.bas:4140-4608`
- **Mechanism:** `If BranchData(I_Branch).I_Z = 88 and BranchData(I_Branch).I_A = 234 Then Alarm = 0 : Exit Do` (GEF.c:106476–106481). The `BranchTable` DATA continues after the (88, 234) row at `DCLbranchingJEFF33.bas:4139` with 469 rows for Z = 89–111 (lines 4140–4608).
- **Effect (expected):** decay data for Z = 89–111 are never loaded, so cumulative yields and delayed-neutron/antineutrino results ignore their decays.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline Branchings.bas:225-228` as quoted; row count from the DATA source. Confirmed by M4 T0 (BranchData dump).
- **Fidelity switch:** `fix_branch_table_full_load`
- **C++ symbol:** not yet ported
- **Owning milestone:** M4

### Q-018 `MyParameters.dat` never applied; `Fitpar.dat` values reset per system by the re-included `Parameters.bas`

- **BASIC location:** `GEF.bas:1017` (→ `ParameterManipulation.mac:2-4` → `MyparRead.bas:3`, `FitparRead.bas`), `GEF.bas:2555`, `GEF.bas:3317-3321`. Merges vision §3 "`Parameters.bas` is re-included per system".
- **Mechanism:**
  - `MyparRead.bas` is included only at `GEF.bas:1017`, top-level code that runs once at start-up, guarded by `If B_MyParameters Then` (GEF.c:20550). `B_MyParameters` is `Dim … = 0` at 1010 and is set only later (`GEF.bas:2360`, GEF.c:32856; `GEF.bas:2866`, GEF.c:38912; 2155 is inside `#ifdef __FB_WIN32__`, 1913–2158, and generates no C). No label before line 1017 exists, so no jump returns to it.
  - `FitparRead.bas` runs at 1017 and again at 2555 (GEF.c:22096 and 35999). Per system, `If B_Fit = 0 Then #include "Parameters.bas"` (3317–3321; e.g. `Parameters.bas:52` appears twice in the C, GEF.c:20405 and 41448) resets every nominal parameter.
  - The `Var_*` widths are computed once at 2574ff, after `FitparRead` at 2555 and before the per-system reset (`Var_P_A_Width_S2 = _P_A_Width_S2 * 0.03 …`, 2578; `fbdef`: no other assignment).
- **Effect (expected):** `MyParameters.dat` has no effect on the calculation in any mode, although the results file still prints "Values of Parameters found in MyParameters.dat are replaced." and lists them (`GEF.bas:12039-12066`). In non-fit runs `Fitpar.dat` values are overwritten before every system, but relative perturbation widths derived from them remain. Seed said "ignored in batch"; the source shows it is ignored in every mode.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline MyparRead.bas:3`, `fbline GEF.bas:2360`, `fbline GEF.bas:2866`, `fbline GEF.bas:2155` (exit 1), `fbline FitparRead.bas:2`, `fbline Parameters.bas:52`, `fbline GEF.bas:3316-3321`; `fbdef B_MyParameters --refs`, `fbdef MyparRead --refs`. Not exercised in `validation/test_run`; end-to-end confirmation in M15 (override-path runs).
- **Fidelity switch:** `fix_parameter_file_overrides`
- **C++ symbol:** not yet ported
- **Owning milestone:** M15 (per-system reset in M6, `Var_*` in M4)

### Q-019 `Var_PZ_S3_olap_curv` is zero, so `PZ_S3_olap_curv` is never perturbed

- **BASIC location:** `GEF.bas:2610` (seed said 2575)
- **Mechanism:** `Var_PZ_S3_olap_curv = 0.03 * Fred_par * PZ_S3_olap_curv * D_Par_Fac` uses the working copy `PZ_S3_olap_curv` (GEF.c:37651 reads `PZ_S3_OLAP_CURV$`), where the neighbouring relative widths use the nominal value (`Var_P_Z_Curv_S5 = _P_Z_Curv_S5 * 0.03 * Fred_par * D_Par_Fac`, 2608). The working copy is still 0 at that point (first assigned at 5128/5451). Line 2610 runs once per process in non-fit runs: the input-file and system loops start after it (`For Ifilein`, 2768; `For Iline`, 3141). Only fit mode returns before it (`GoTo Nextfitloop`, 15610 → 2519), and then the working copy is no longer 0 [INFERENCE]. The perturbation `PZ_S3_olap_curv = PGAUSS(_PZ_S3_olap_curv,Var_PZ_S3_olap_curv)` (5128) still consumes a `PGauss` value.
- **Effect:** the parameter is identical in every perturbed set; the random stream is unaffected.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:2610` as quoted. Output `validation/test_run/tmp/GEF_86_215_n.par`: all 1860 `PZ_S3_olap_curv =` lines read `0.004088318` (the `Parameters.bas:52` value), while `P_DZ_Mean_S2` takes 1859 distinct values.
- **Fidelity switch:** `fix_pz_s3_olap_curv_width`
- **C++ symbol:** not yet ported
- **Owning milestone:** M12 (registry list in M4)

### Q-020 Analyzer registry naming errors

- **BASIC location:** `Spectra.bas:1082-1096` (NNCNtot/NPCNtot), `Spectra.bas:557-559` and `575-577` (ErotL2d), lookup `GEF.bas:15691-15707` (`Find_IAnl`)
- **Mechanism:**
  - The `NNCNtot` and `NPCNtot` registrations do not increment `I_Anl`, so they overwrite the `NNCN` entry (GEF.c:28165, 28195 assign to `Anl_Par(I_Anl)` with the same `I_ANL$0`); `NNCN`'s slot ends up named `NPCNtot`.
  - Array `ErotL2dlight` is registered as `"ErotL2dheavy"` (559, GEF.c:26609) and `ErotL2dheavy` as `"ErotL2d"` (577). `Find_IAnl` strips `(...)`, compares names case-insensitively and returns 0 (the default entry) when nothing matches. The dump `"ErotL2dlight(i)"` therefore gets the defaults and `"ErotL2dheavy(i)"` gets the light array's registration.
- **Effect:** `dmp` header text changes (TITLE, axis labels, line symbol).
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline Spectra.bas:1082-1083`, `fbline Spectra.bas:1090-1091`, `fbline Spectra.bas:559` as quoted. Output `validation/test_run/dmp/Z86_A215_n_E14MeV/Eexc.dmp:11297-11307`: `ANALYZER(ErotL2dlight(0))` with `TITLE()`, `X: Channel`, `Y: Counts`, `Y,HT0`; versus `Eexc.dmp:29497-29504`: `ANALYZER(ErotL2dheavy(0))` with `TITLE(Rotational energy over angular momentum)`, `X: L / hb^`. No `NNCN` dump exists in the recorded `dmp` files, so that part is not visible in output.
- **Fidelity switch:** `fix_analyzer_registry_names`
- **C++ symbol:** not yet ported
- **Owning milestone:** M4

### Q-021 `I_MAT_ENDF` persists state in `ctl/IMATmax.ctl`

- **BASIC location:** `NucProp_Functions.mac:11-63` (seed said 28–49; the file I/O spans 37–58)
- **Mechanism:** for a nuclide missing from `NucTab`, the lookup does `CHDIR("ctl")` (37; GEF.c:4668 `fb_ChDir`), reads `IMATmax.ctl` for an earlier assignment (38–49), otherwise assigns `IMAT_max + 1`, appends `IZ, IA, IMAT` to the file (51–56) and returns with `CHDIR("..")` (58). The file is never deleted (no `Kill` in the source).
- **Effect (expected):** MAT numbers of nuclides outside `NucTab` depend on the history of earlier runs in the same working directory, and the lookup changes the process working directory temporarily. Callers (`fbdef I_MAT_ENDF --refs`) include the event loop (`GEF.bas:9259, 9379`), the isomeric-yield output (14246), set-up (3562, 3707, 3751) and the ENDF writer (`ENDF.bas:332, 695, 934`).
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline NucProp_Functions.mac:37`, `fbline NucProp_Functions.mac:52-53` as quoted. Not exercised in `validation/test_run`: `ctl/` holds no `IMATmax.ctl` and `run.log` has no `<I> IMAT =` line. Confirmed by M4 T1 (lookup over full grids in a fresh `ctl/`) and M15 (edge systems).
- **Fidelity switch:** `fix_imat_no_persistent_state`
- **C++ symbol:** not yet ported
- **Owning milestone:** M4

### Q-022 TXE printed with the TKE uncertainty

- **BASIC location:** `GEF.bas:14402-14403` (seed said 14403; the statement starts at 14402)
- **Mechanism:** `Print #f,"Mean value: TXE =";Csng(Zaehler/Nenner); " MeV +-"; Csng(d_TKEpre(0));" MeV,"`. GEF.c:103772 prints `*(double*)D_TKEPRE$0`.
- **Effect:** the `<TXE>` uncertainty is the pre-neutron TKE uncertainty.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:14402` as quoted. Output `validation/test_run/out/GEF_86_215_n.dat:4235` `TKE_pre = 134.7623 MeV +- 2.189842 MeV` and `:4314` `TXE = 23.26706 MeV +- 2.189842 MeV`.
- **Fidelity switch:** `fix_txe_uncertainty`
- **C++ symbol:** not yet ported
- **Owning milestone:** M13

### Q-023 "Width (standard deviation)" prints the variance for light and heavy fragments

- **BASIC location:** `GEF.bas:13753, 13773`
- **Mechanism:** `Print #f,"Width (standard deviation): ",Csng(Nlightsigma2)` where `Nlightsigma2 = Σ p·(I − mean)²` (13664–13667; heavy 13681–13684). GEF.c:99031 `fb_PrintSingle(…, (float)NLIGHTSIGMA2$9, 1)`. The other width lines (13708–13722) print `sqr(...)`.
- **Effect:** the light- and heavy-fragment neutron-multiplicity widths are variances.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:13753` as quoted. Output `validation/test_run/out/GEF_86_215_n.dat:2051-2059`: the light distribution (0.355045, 0.365661, 0.209132, 0.064418, 0.005701, 4.3e-05) has mean 1.000198 and variance 0.873846; the file prints `Width (standard deviation): 0.8738459`. Heavy (`:2066-2074`): variance 1.208710, printed 1.20871. The total (`:2043`) prints 1.723189, which is the standard deviation of its distribution (`:2024-2032`).
- **Fidelity switch:** `fix_width_standard_deviation`
- **C++ symbol:** not yet ported
- **Owning milestone:** M13

### Q-024 ENDF `R_Norm` accumulated in `Single`

- **BASIC location:** `ENDF.bas:157, 496-502` (seed: "ENDF.bas")
- **Mechanism:** `Static As Single R_Norm`; `R_Norm = R_Norm + NZPOST(IN,IZ)` over Z 1–100, N 1–200 (GEF.c:114831 `R_NORM$12 = (float)((double)R_NORM$12 + vr1)`), then `R_Norm * P_selected / 2.0` narrowed to `Single` (GEF.c:114857). Every MT454/MT459 value is divided by it (`ENDF.bas:1211-1454`).
- **Effect:** yields carry the `Single` rounding of the normalisation: values print as `1.999998-6`, `3.999996-6`, `9.999994-…` instead of `2.000000-6` etc.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline ENDF.bas:494-502` as quoted. Output `validation/test_run/ENDF/GEFY_86_214_n.dat:48` (`1.999998-6 1.999998-6`) and `:53` (`3.999996-6 3.999996-6 … 1.999998-6 1.999998-6`); 467 occurrences of `1.999998-` in the file. [INFERENCE] The common relative deviation (≈ 1e-6) points to the shared divisor `R_Norm`; M13 snapshot tests confirm the attribution.
- **Fidelity switch:** `fix_endf_norm_double`
- **C++ symbol:** not yet ported
- **Owning milestone:** M13

### Q-025 List-mode output consumes random numbers

- **BASIC location:** `GEF.bas:9680-9839` (draws), inside `If CFileoutlmd <> "" Then` (`GEF.bas:9653-9979`)
- **Mechanism:** the list-mode writer draws `Rnd` for fragment and neutron directions and energies: 9680 `costheta_f1_CN = (1.0 - 2.0 * rnd)` (GEF.c:70462 `fb_Rnd( 0x1.p+0f )`), 9719, 9769, 9775, 9783, 9789, 9797, 9799, 9801, 9820, 9829, 9839 (GEF.c:71445). The draws come from the global stream (strategy §1.3 item 2) and depend on the output flags (`Pdir` etc.).
- **Effect (expected):** enabling `LMD`/`LMD+` shifts the random stream, so every later event and therefore the physics results differ from a run without list-mode output.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline GEF.bas:9653`, `fbline GEF.bas:9680`, `fbline GEF.bas:9839` as quoted. The recorded run has no list-mode output. Confirmed by M15 (T3 `.lmd` diff); M10 runs with lmd off on both sides.
- **Fidelity switch:** `fix_lmd_separate_rng`
- **C++ symbol:** not yet ported
- **Owning milestone:** M15

### Q-026 Outputs opened `For Append`; `ctl/` never cleaned

- **BASIC location:** `GEF.bas:10077` (results file), `ENDF.bas:676, 678` (seed gave 676 only; 678 opens the normal tape), dump files `GEF.bas:14885-15280`
- **Mechanism:** `Open Cfileout_full For Append As #f` (GEF.c:73001 `fb_FileOpen(…, 4u, …)`; `For Output` at 10064 generates mode `3u`), `Open CGEFY For Append As #fENDF` (GEF.c:115506). The source contains no `Kill`, so `out/`, `dmp/`, `ENDF/`, `tmp/` files and `ctl/thread.ctl`/`done.ctl` survive between runs.
- **Effect:** a run appends to the files of earlier runs in the same working directory.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:10077`, `fbline GEF.bas:10064`, `fbline ENDF.bas:674-678` as quoted. Output:
  - `validation/test_run/ENDF/GEFY_86_214_n.dat` holds two tapes: lines 1–857 (EMAX `2.530000-2` at line 4, TEND at line 857) from an earlier thermal-only process, and 858–60971 (EMAX `3.000000+7` at line 861, TEND at 60971).
  - `out/GEF_86_215_n.dat` has 63 `<Title>` blocks; the first (written 18:19:38, with uncertainties) predates the logged process, whose step 1 was written 18:21:13.
  - `dmp/Z86_A215_n_E2.53e-08MeV/Egamma.dmp` has four appended blocks (18:19:38, 18:21:13, 18:23:36, 20:06:41).
  - `ctl/` still holds `thread.ctl` and `done.ctl`.
- **Fidelity switch:** `fix_fresh_outputs`
- **C++ symbol:** not yet ported
- **Owning milestone:** M13 (`ctl/` coordination is replaced in M14)

### Q-027 `Acc_d_NZPOST` checks `UBound(_NZPOST,3)` on a 2-D array

- **BASIC location:** `Spectra.bas:1758-1759` (vision §3 says 1759; the statement starts at 1758)
- **Mechanism:** the bounds test ends with `Or I_Z > Ubound(_NZPOST,3)`, the third dimension of the 2-D `_NZPOST(0 To 50,20 To 70)` (`Spectra.bas:47`) instead of `_d_NZPOST`. GEF.c:8226 `fb_ArrayUBound( (struct $7FBARRAYIKvE*)&_NZPOST$, 3ll )`. fbc returns −1 for a dimension beyond the array's, so the test is true for every `I_Z ≥ 0` and `Extend_3dim` (`utilities.bi:326`) runs on every call. With unchanged bounds it copies the array out and back.
- **Effect (expected):** results unchanged: with unchanged bounds `Extend_3dim` copies the array into `Work`, re-`Redim`s it, zeroes it and copies the values back (read from `utilities.bi:326-372`; `Extend.bas`, which has a second copy, is not compiled). Every call reallocates and copies the array, a performance cost only.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline Spectra.bas:1758` as quoted. Runtime probe (source under Q-004; pinned fbc 1.10.1): `ReDim Shared NZ2(0 To 50, 20 To 70)` prints `UBound(NZ2,3)=-1 LBound(NZ2,3)= 0`.
- **Fidelity switch:** `fix_d_nzpost_bounds_check`
- **C++ symbol:** not yet ported
- **Owning milestone:** M12 (performance in M17)

### Q-028 `NN.dmp` comment says "protons" for the neutron multiplicity

- **BASIC location:** `GEF.bas:15289`
- **Mechanism:** `U_DMP_1D(NN(),"NN","Multiplicity distribution of prompt protons, "+…)`, copied from the `NP` call at 15282. The file header at 15288 says neutrons.
- **Effect:** wrong comment text in every `NN.dmp`.
- **Evidence status:** *confirmed in output*
- **Evidence:** source line above. Output `validation/test_run/dmp/Z86_A215_n_E14MeV/NN.dmp:7`: `S: COMMENT(Multiplicity distribution of prompt protons, 1000000 fission events)`, followed by `X: Number of neutrons`; `NP.dmp:7` has the same comment.
- **Fidelity switch:** `fix_nn_dmp_comment`
- **C++ symbol:** not yet ported
- **Owning milestone:** M13

### Q-029 `d_NZIcumu` capped against the nominal yield only inside the printed window

- **BASIC location:** `Branchings.bas:876-899` (final σ), `Branchings.bas:963-978` (print loop)
- **Mechanism:** at the last perturbed pass σ is computed and capped against `NZIcumu` of that pass for `IN 10…190`, `IZ 10…90`, `Iori 0…2` (891, 894). In the nominal pass the cap against the nominal `NZIcumu` is applied again (974–978), but only for nuclides inside the print window `IA 20…P_A_CN-20`, `IZ 10…P_Z_CN-10`, `10 < IN < I_N_CN-10`, and only when `NZIcumu > 0`.
- **Effect (expected):** outside the window, `d_NZIcumu(0,·)` keeps the cap from the last perturbed pass, so consumers of `d_NZIcumu` (ENDF MT459, `ENDF.bas:1308, 1321, 1441, 1454`) can see an uncertainty above the nominal cumulative yield.
- **Evidence status:** *read only*
- **Evidence:** source lines above; `fbline Branchings.bas:974-975` (GEF.c:109783–109786, also 162133). Confirmed by M12 (T1, probe-fed `mvd`/histogram snapshots) and M13 (MT459 snapshot tests).
- **Fidelity switch:** `fix_cumulative_uncertainty_cap`
- **C++ symbol:** not yet ported
- **Owning milestone:** M12

### Q-030 `.par` files print an unassigned date (`30.12.1899, 00:00:00`)

- **BASIC location:** `GEF.bas:5165` (local `Dim As Double Rdatetime`), `GEF.bas:5178-5179` (print)
- **Mechanism:** the parameter-file block declares its own local `Rdatetime` (5165) and prints `Format(Rdatetime, "dd.mm.yyyy, hh:mm:ss")` without ever assigning it. GEF.c:57176 formats `RDATETIME$11`, which is 0.0, so FreeBASIC prints the date serial 0. The other output blocks assign `Rdatetime = Now` before printing.
- **Effect:** every `tmp/*.par` "Output written on" line reads `30.12.1899, 00:00:00` instead of the run time. It is the one time stamp that is deterministic, so `harness/masks.toml` deliberately does not mask it.
- **Evidence status:** *confirmed in output*
- **Evidence:** all 60 such lines in `validation/test_run/tmp/GEF_86_215_n.par`; `fbline GEF.bas:5179`, `fbdef Rdatetime` (five separate local declarations).
- **Fidelity switch:** `fix_par_timestamp`
- **C++ symbol:** not yet ported
- **Owning milestone:** M13

### Q-031 `Print Using "####.#"; x; " ";` drops the `" "`

- **BASIC location:** `GEF.bas:12292`
- **Mechanism:** the template has one numeric field and no string field. After `x` uses the field, the runtime restarts the template for the `" "` item (`fb_PrintUsingStr`), finds the numeric field `#` first and prints nothing; `fb_PrintUsingEnd` then prints the template text up to the next field, which is none. GEF.c passes mask 0 to both items, so the template is not freed early and the behaviour is well defined. (With a trailing newline the last item carries `FB_PRINT_ISLAST`, the runtime frees the template before `fb_PrintUsingEnd` reads it, and stray bytes appear; GEF does not do that.)
- **Effect:** the intended space after each `K * 0.1` value is missing, so the value runs into the following table text.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline GEF.bas:12292` shows GEF.c:87359-87367: `fb_PrintUsingInit`, `fb_PrintUsingDouble(…, 0)`, `fb_PrintUsingStr(…, 0)`, `fb_PrintUsingEnd`. `tools.fbsrc.fb_templates` lists it as the only statement with more items than fields. Runtime probe (M3.6b, 2026-10-08, scratch program compiled with the pinned fbc): `Print #1, Using "####.#"; x; " ";` repeated 32 times prints the values with no spaces, identical over three runs; with a trailing newline instead, the bytes after the newline differ between runs. The same calls on `gef::fb::PrintFile` (scratch program) give the probe's 16 lines byte for byte.
- **Fidelity switch:** `fix_using_space` (would print the space)
- **C++ symbol:** `gef::fb::PrintFile::using_print` (runtime behaviour); call site not yet ported
- **Owning milestone:** M13

## 5. Build notes (not GEF quirks)

These describe how the toolchain, not GEF, can make the C++ results differ from the reference binary. They have no fidelity switch.

### B-001 Optimisation level versus fbc's `-O0`

- **Source:** `manifests/toolchain.txt` `[fbc -v backend capture]`: fbc compiles the generated C with `gcc … -O0 …`. `MILESTONE_0_PLAN.md` §2 (note on optimisation level) and §7 (risk table).
- **Issue:** the exact-mode C++ build does not fix the optimisation level. With SSE, round-to-nearest and FMA contraction off, IEEE results should not depend on it, except where GCC constant-folds or inlines libm calls differently.
- **Status:** open risk, measured per function by the M3/M5 T1 bit-exact tests, which run in `release-exact` (`-O3`) as well. Fallback: compile the affected translation units at `-O0`.
- **Finding 1 (M3.3, 2026-10-08):** `fb::fix` written as libfb computes it, `trunc(|x|) * sgn(x)`, differs at `-O3` for NaN inputs. Without `-fsignaling-nans`, gcc folds the multiplication by −1 into a negation, which keeps the NaN's sign and does not quiet a signalling NaN; libfb (and our `-O0` builds) return `|x|` quieted. Fixed in the source rather than by flags: `fix` handles NaN with explicit bit operations and the other cases with `t`/`-t`/`0`, which no optimisation can change. Lesson for later ports: a multiplication by a literal −1 (or by a sign) can lose its NaN behaviour at `-O3`.
- **Finding 2 (M3.4, 2026-10-08):** across all libm intrinsics GEF uses and GEF's own maths helpers, every remaining difference between the C++ builds and the fbc-compiled drivers is a NaN result whose sign or payload differs; no non-NaN value differs in any preset. Examples: g++ expands `std::floor(float)` inline even in Debug, where fbc's C calls glibc `floorf`, which quiets a signalling NaN; clang rewrites `-a + 1` as `1 - a`, which keeps the NaN's sign; gcc `-O3` does the same inside `Erfc` and inlines `floor(double)`. IEEE 754 leaves the sign of most NaN results unspecified, so compilers may do this. **Decision (user, 2026-10-08): bit-exact comparisons treat every NaN as equal to every NaN.** The M3.4 drivers hash NaN results as the canonical NaN, and the tests accept any NaN where the driver printed one. A NaN that reaches a GEF output file would still show up in `compare.exact` (`nan` vs `-nan`). (`fb::fix`, written before this decision, reproduces libfb's NaN bits anyway.)
- **Owning milestone:** M3, M5

### B-002 fbc's backend gcc also passes `-fwrapv -fno-strict-aliasing`

- **Source:** `manifests/toolchain.txt`: `gcc -m64 -march=x86-64 … -O0 -fno-strict-aliasing -frounding-math -fno-math-errno -fwrapv …`. The C++ exact-mode flags (`Cpp_implementation/cmake/GefCompilerPolicy.cmake`, `gef_exact_fp`; coding standards §2.5) mirror `-march=x86-64 -frounding-math -fno-math-errno` but not `-fwrapv` or `-fno-strict-aliasing`.
- **Issue:** signed integer overflow in the BASIC program wraps (two's complement), because GEF.c is compiled with `-fwrapv`; in C++ it is undefined behaviour. [INFERENCE] `-fno-strict-aliasing` matters for fbc's pointer-cast array access in GEF.c, not for idiomatic C++.
- **Status:** resolved for the runtime layer (M3.3). `gef::fb::add/sub/mul/neg/abs` (`Integer` and `Long`) wrap in unsigned arithmetic, verified against `int_ops.bas` (19 × 19 `Integer` and 13 × 13 `Long` edge pairs, golden `m3-int-ops`); UBSan in `asan-ubsan` runs the same tests. fbc evaluates `Long` `+`, `-`, `*` in 64 bits and truncates (`(int32)((int64)A * (int64)B)`), which equals 32-bit wrapping. Integer `\` and `Mod` are C `/` and `%`; a zero divisor or `&h8000000000000000 \ -1` traps (SIGFPE) in BASIC and throws `std::domain_error` in C++. Ported code must use these helpers wherever an `Integer` or `Long` operation can overflow.
- **Owning milestone:** M3

### B-003 `Compilationstamp` makes emitted C and binaries time-dependent

- **Source:** `GEF.bas:17` `#Define Compilationstamp __DATE_ISO__ + " at " __TIME__`, printed at `GEF.bas:18`.
- **Issue:** the date and time of compilation are embedded in the generated C, so emitted C and binaries are reproducible only with `SOURCE_DATE_EPOCH` set. `tools/fbsrc/emit_c.py` sets it to the submodule commit time (manifest `source_date_epoch` = 1752832402): GEF.c:19600 shows the expansion `$"2025-07-18"` / `$"09:53:22"`. The reference binary in `validation/test_run/` was built without it (`run.log:11`: `compiled on 2026-09-15 at 17:20:38`).
- **Status:** handled (M1, 2026-10-07). `harness.build` sets `SOURCE_DATE_EPOCH` to the submodule commit time for every harness build, and builds are reproducible. Built with the epoch of 2026-09-15 17:20:38 UTC, the unpatched source reproduces every loaded section of `gef_reference` byte for byte. Run comparisons mask the `compiled on` line (`harness/masks.toml`, mask `compile_stamp`).
- **Owning milestone:** M1

### B-004 fbc reassociates `*`/`+` chains and moves numeric literals to their end

- **Source:** `python3 -m tools.fbsrc.fbline GEF.bas:2608` and `GEF.bas:2610`. BASIC `Var_P_Z_Curv_S5 = _P_Z_Curv_S5 * 0.03 * Fred_par * D_Par_Fac` becomes GEF.c:37645 `(float)((((double)_P_Z_CURV_S5$ * (double)FRED_PAR$0) * (double)D_PAR_FAC$) * 0x1.EB851EB851EB8p-6)`; `0.03 * Fred_par * PZ_S3_olap_curv * D_Par_Fac` (2610) becomes GEF.c:37651 `(((FRED_PAR * PZ_S3_OLAP_CURV) * D_PAR_FAC) * 0.03)`. fbc's constant folding reassociates the chain and applies the literal last.
- **Issue:** floating-point arithmetic is not associative, so a C++ port that follows the BASIC source order (`a * 0.03 * b * c`, left to right) can round differently from the reference binary. The operation order that matters is the one in the generated C, not the one in the BASIC text.
- **Established rules (M3.2, `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md`):**
  - Operand types and conversions are fixed while parsing, left to right. Then each chain of `*` or `+` is flattened, its literals are folded into one constant in the chain's type, and that constant is applied last.
  - Parentheses inside `*`/`+` chains are dropped even without literals: `s * (t * u)` → `(S*T)*U`, `s - (t - u)` → `(S-T)+U`.
  - Literals never move across `/` or a subtracted non-literal.
  - `Double` chains are affected most: `d * 0.1 * e` differs from left-to-right evaluation for 824 of 2,000 random inputs, `s * (t * u)` for 714.
  - `1.0 - 2.0 * rnd` at `GEF.bas:9680` becomes `-(vr1 * 2) + 1`, which is exact-equivalent.
- **Status:** confirmed by fbc C and by a run: driver `arith_rules.bas`, golden `m3-arith-rules`, reproduced bit for bit by `fbc_arithmetic_test.cpp` in `dev-gcc`, `dev-clang` and `release-exact`. Coding rule unchanged: port arithmetic from the `fbline` output, not from the BASIC text (coding standards §5). M5 T1 bit-exact tests catch any remaining order differences.
- **Owning milestone:** M3 (rules, done), M5

## 6. Summary

| ID | Title | BASIC location | Evidence status | Fidelity switch | Owning milestone |
|---|---|---|---|---|---|
| Q-001 | Heavy-fragment E1 gammas dropped | `GEF.bas:9417` | confirmed in output | `fix_heavy_e1_gammas` | M10 |
| Q-002 | `ENsci` writes dropped | `GEF.bas:8129, 8152` | confirmed by fbc C | `fix_ensci_fill` | M10 |
| Q-003 | Uncertainty cap adds instead of setting | `GEF.bas:11383-11391`, `Spectra.bas:1788-1800` | confirmed in output | `fix_uncertainty_cap` | M12 |
| Q-004 | `EdefoA` always zero | `GEF.bas:10245` | confirmed in output | `fix_edefo_a_dimension` | M11 |
| Q-005 | ZApre/ZApost rows via closed `#f` | `GEF.bas:14842, 15019-15157` | confirmed in output | `fix_za_dmp_file_handle` | M13 |
| Q-006 | `Nmulti2dpre/post` never cleared | `CLEARspectra.bas:172-181` | confirmed in output | `fix_nmulti2d_clear` | M10 |
| Q-007 | Stale global `Z` in pre-pass parity | `GEF.bas:4322` | confirmed by fbc C | `fix_prepass_parity_z` | M9 |
| Q-008 | Mode-7 scission energies leak | `GEF.bas:7213-7219` | read only | `fix_mode7_scission_energy_leak` | M7 |
| Q-009 | `Beta(4,1,·)` never set | `GEF.bas:5831` | confirmed by fbc C | `fix_beta_mode4_light` | M7 |
| Q-010 | `EPART`/`PEOZ`/`PEON` not cleared | `GEF.bas:7230-7377, 7437, 7475` | read only | `fix_epart_peoz_peon_clear` | M7 |
| Q-011 | `EOscale` applied twice on mirrored half | `GEF.bas:7294-7297, 7322-7325` | read only | `fix_eoscale_single_application` | M7 |
| Q-012 | `J_attempt` retry refills histograms | `GEF.bas:8676-8738` | confirmed by fbc C | `fix_j_attempt_double_fill` | M10 |
| Q-013 | Isomer windows double-count endpoints | `GEF.bas:14258-14265` | confirmed by fbc C | `fix_isomer_window_endpoints` | M11 |
| Q-014 | `R_lim` clamped in place | `GEF.bas:14253-14257` | confirmed in output | `fix_r_lim_local_clamp` | M11 |
| Q-015 | Isomer row overwrites `R_alpha` | `Branchings.bas:157-158` | confirmed by fbc C | `fix_branch_alpha_isomer` | M4 |
| Q-016 | 3rd-isomer fallback uses state 2 | `Branchings.bas:430-437` | confirmed by fbc C | `fix_third_isomer_fallback` | M11 |
| Q-017 | Branch table stops at Ra-234 | `Branchings.bas:225-228` | confirmed by fbc C | `fix_branch_table_full_load` | M4 |
| Q-018 | `MyParameters.dat` never applied; `Fitpar.dat` reset per system | `GEF.bas:1017, 2555, 3317-3321` | confirmed by fbc C | `fix_parameter_file_overrides` | M15 |
| Q-019 | `Var_PZ_S3_olap_curv` is zero | `GEF.bas:2610` | confirmed in output | `fix_pz_s3_olap_curv_width` | M12 |
| Q-020 | Analyzer registry naming errors | `Spectra.bas:557-577, 1082-1096` | confirmed in output | `fix_analyzer_registry_names` | M4 |
| Q-021 | `I_MAT_ENDF` persists `ctl/IMATmax.ctl` | `NucProp_Functions.mac:11-63` | confirmed by fbc C | `fix_imat_no_persistent_state` | M4 |
| Q-022 | TXE printed with TKE uncertainty | `GEF.bas:14402-14403` | confirmed in output | `fix_txe_uncertainty` | M13 |
| Q-023 | "Width" prints variance | `GEF.bas:13753, 13773` | confirmed in output | `fix_width_standard_deviation` | M13 |
| Q-024 | ENDF `R_Norm` in `Single` | `ENDF.bas:157, 496-502` | confirmed in output | `fix_endf_norm_double` | M13 |
| Q-025 | lmd output consumes random numbers | `GEF.bas:9653-9979` | confirmed by fbc C | `fix_lmd_separate_rng` | M15 |
| Q-026 | Outputs appended; `ctl/` never cleaned | `GEF.bas:10077`, `ENDF.bas:676, 678` | confirmed in output | `fix_fresh_outputs` | M13 |
| Q-027 | `UBound(_NZPOST,3)` on a 2-D array | `Spectra.bas:1758-1759` | confirmed by fbc C | `fix_d_nzpost_bounds_check` | M12 |
| Q-028 | `NN.dmp` comment says "protons" | `GEF.bas:15289` | confirmed in output | `fix_nn_dmp_comment` | M13 |
| Q-029 | `d_NZIcumu` capped only in printed window | `Branchings.bas:876-899, 963-978` | read only | `fix_cumulative_uncertainty_cap` | M12 |
| Q-030 | `.par` files print an unassigned date | `GEF.bas:5165, 5179` | confirmed in output | `fix_par_timestamp` | M13 |
| Q-031 | `Print Using "####.#"; x; " ";` drops the `" "` | `GEF.bas:12292` | confirmed by fbc C | `fix_using_space` | M13 |
| B-001 | Optimisation level vs fbc `-O0` | (toolchain) | open risk | — | M3, M5 |
| B-002 | fbc gcc passes `-fwrapv -fno-strict-aliasing` | (toolchain) | resolved for the runtime layer (M3.3) | — | M3 |
| B-003 | `Compilationstamp` needs `SOURCE_DATE_EPOCH` | `GEF.bas:17` | handled (M1) | — | M1 |
| B-004 | fbc reassociates `*`/`+` chains, literals last | `GEF.bas:2608, 2610` | confirmed by fbc C and run | — | M3, M5 |
