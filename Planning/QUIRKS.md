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
- **Evidence:** `fbline GEF.bas:5831` as quoted; `fbdef Beta --refs`. M7.1: the C++ port reproduces `Beta` as BASIC leaves it after the M7.1 blocks in all 148 P3 records of the M7 captures (`tables: mode centres and deformations equal BASIC from P3in`, every `Beta` element M7.1 writes last, `Beta(4,1,·)` included); upgraded to *confirmed in output* with the capture IDs in M7.5.
- **Fidelity switch:** `fix_beta_mode4_light`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `gef::tables::mode_centres_and_deformations` (`deformations_modes`, `Cpp_implementation/src/tables/deformations.cpp`)
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
- **Evidence:** `fbline Branchings.bas:157-158`, `fbline Branchings.bas:121`, `fbline Branchings.bas:192` (exit 1). Branchings.bas is included twice (`GEF.bas:14704, 14836`), so the C appears twice (also GEF.c:158685). M4.3: the T0 dump of `BranchData` (probe's private loader copy) shows the effect and the C++ reproduces it (`tables_test.cpp`).
- **Fidelity switch:** `fix_branch_alpha_isomer`
- **C++ symbol:** `gef::data::load_branchings` (`Cpp_implementation/src/data/branchings.cpp`); the switch comes with a later fix decision (strategy §2.1)
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
- **Evidence:** `fbline Branchings.bas:225-228` as quoted; row count from the DATA source. Confirmed by M4 T0 (BranchData dump): the C++ loader reproduces it (`tables_test.cpp`).
- **Fidelity switch:** `fix_branch_table_full_load`
- **C++ symbol:** `gef::data::load_branchings` (`Cpp_implementation/src/data/branchings.cpp`); the switch comes with a later fix decision (strategy §2.1)
- **Owning milestone:** M4

### Q-018 `MyParameters.dat` never applied; `Fitpar.dat` values reset per system by the re-included `Parameters.bas`

- **BASIC location:** `GEF.bas:1017` (→ `ParameterManipulation.mac:2-4` → `MyparRead.bas:3`, `FitparRead.bas`), `GEF.bas:2555`, `GEF.bas:3317-3321`. Merges vision §3 "`Parameters.bas` is re-included per system".
- **Mechanism:**
  - `MyparRead.bas` is included only at `GEF.bas:1017`, top-level code that runs once at start-up, guarded by `If B_MyParameters Then` (GEF.c:20550). `B_MyParameters` is `Dim … = 0` at 1010 and is set only later (`GEF.bas:2360`, GEF.c:32856; `GEF.bas:2866`, GEF.c:38912; 2155 is inside `#ifdef __FB_WIN32__`, 1913–2158, and generates no C). No label before line 1017 exists, so no jump returns to it.
  - `FitparRead.bas` runs at 1017 and again at 2555 (GEF.c:22096 and 35999). Per system, `If B_Fit = 0 Then #include "Parameters.bas"` (3317–3321; e.g. `Parameters.bas:52` appears twice in the C, GEF.c:20405 and 41448) resets every nominal parameter.
  - The `Var_*` widths are computed once at 2574ff, after `FitparRead` at 2555 and before the per-system reset (`Var_P_A_Width_S2 = _P_A_Width_S2 * 0.03 …`, 2578; `fbdef`: no other assignment).
- **Effect (expected):** `MyParameters.dat` has no effect on the calculation in any mode, although the results file still prints "Values of Parameters found in MyParameters.dat are replaced." and lists them (`GEF.bas:12039-12066`). In non-fit runs `Fitpar.dat` values are overwritten before every system, but relative perturbation widths derived from them remain. Seed said "ignored in batch"; the source shows it is ignored in every mode.
- **Evidence status:** *confirmed in output* (M6; before: *confirmed by fbc C*)
- **Evidence:** `fbline MyparRead.bas:3`, `fbline GEF.bas:2360`, `fbline GEF.bas:2866`, `fbline GEF.bas:2155` (exit 1), `fbline FitparRead.bas:2`, `fbline Parameters.bas:52`, `fbline GEF.bas:3316-3321`; `fbdef B_MyParameters --refs`, `fbdef MyparRead --refs`. M4.4: capture `m4-t0-fitpar` (a `Fitpar.dat` in the working directory) confirms the Fitpar part: P1 of the first system holds the `Parameters.bas` values again for every parameter that file sets, while those it does not set (`D_Par_Fac`, `EOscale`, `_Delta_S0`, `Chisqr_Fit_min`) and `Var_P_A_Width_S2` (computed from the Fitpar value at 2578) keep the Fitpar values. M6 (run flow): the setup-only capture `m6-patch-check-m1/setup/m4-fitpar` (same `Fitpar.dat`) shows the same in P1 (`_P_DZ_Mean_S1` −0.35 = `BEB33333` and `_P_Shell_S1` −2.3 from `Parameters.bas`, where the file sets −0.3 and −2.1; `Chisqr_Fit_min` 12.5 and `Var_P_A_Width_S2` from the file), and `run_corpus_test.cpp` reproduces that run's P0/P1/P1b with the real `begin_round` (FitparRead at 2555) and `begin_system` (the reset at 3317-3321); fit-mode corpus entries skip the reset (`B_Fit` 1). Capture `m6-setup-edge-7/edge-e_options-myparameters` (`Options(… MYPARAMETERS …)` with a `MyParameters.dat` in the working directory): GEF prints the option's notice `User-defined parameter values will be used.` (GEF.bas:2867) but never `File MyParameters.dat found.` (`MyparRead.bas:14`), so the file is not read. MyParameters.dat: end-to-end confirmation in M15 (override-path runs).
- **Fidelity switch:** `fix_parameter_file_overrides`
- **C++ symbol:** `gef::params::mypar_read` (gated by `Parameters::b_myparameters`), `gef::params::fitpar_read`, `gef::params::load_parameters_bas` (`Cpp_implementation/src/params/`, M4.4); per round and per system `gef::run::begin_round` and `gef::run::begin_system` (`Cpp_implementation/src/run/system_setup.cpp`, M6.3)
- **Owning milestone:** M15 (per-system reset done in M6, `Var_*` in M4)

### Q-019 `Var_PZ_S3_olap_curv` is zero, so `PZ_S3_olap_curv` is never perturbed

- **BASIC location:** `GEF.bas:2610` (seed said 2575)
- **Mechanism:** `Var_PZ_S3_olap_curv = 0.03 * Fred_par * PZ_S3_olap_curv * D_Par_Fac` uses the working copy `PZ_S3_olap_curv` (GEF.c:37651 reads `PZ_S3_OLAP_CURV$`), where the neighbouring relative widths use the nominal value (`Var_P_Z_Curv_S5 = _P_Z_Curv_S5 * 0.03 * Fred_par * D_Par_Fac`, 2608). The working copy is still 0 at that point (first assigned at 5128/5451). Line 2610 runs once per process in non-fit runs: the input-file and system loops start after it (`For Ifilein`, 2768; `For Iline`, 3141). Only fit mode returns before it (`GoTo Nextfitloop`, 15610 → 2519), and then the working copy is no longer 0 [INFERENCE]. The perturbation `PZ_S3_olap_curv = PGAUSS(_PZ_S3_olap_curv,Var_PZ_S3_olap_curv)` (5128) still consumes a `PGauss` value.
- **Effect:** the parameter is identical in every perturbed set; the random stream is unaffected.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:2610` as quoted. Output `validation/test_run/tmp/GEF_86_215_n.par`: all 1860 `PZ_S3_olap_curv =` lines read `0.004088318` (the `Parameters.bas:52` value), while `P_DZ_Mean_S2` takes 1859 distinct values.
- **Fidelity switch:** `fix_pz_s3_olap_curv_width`
- **C++ symbol:** `gef::params::update_widths` (argument `pz_s3_olap_curv`, M4.4; matches P1), called with the working copy `run::ProcessState::working.pz_s3_olap_curv` (`tables::WorkingParameters`, M7.1)
- **Owning milestone:** M12 (registry list in M4)

### Q-020 Analyzer registry naming errors

- **BASIC location:** `Spectra.bas:1082-1096` (NNCNtot/NPCNtot), `Spectra.bas:557-559` and `575-577` (ErotL2d), lookup `GEF.bas:15691-15707` (`Find_IAnl`)
- **Mechanism:**
  - The `NNCNtot` and `NPCNtot` registrations do not increment `I_Anl`, so they overwrite the `NNCN` entry (GEF.c:28165, 28195 assign to `Anl_Par(I_Anl)` with the same `I_ANL$0`); `NNCN`'s slot ends up named `NPCNtot`.
  - Array `ErotL2dlight` is registered as `"ErotL2dheavy"` (559, GEF.c:26609) and `ErotL2dheavy` as `"ErotL2d"` (577). `Find_IAnl` strips `(...)`, compares names case-insensitively and returns 0 (the default entry) when nothing matches. The dump `"ErotL2dlight(i)"` therefore gets the defaults and `"ErotL2dheavy(i)"` gets the light array's registration.
- **Effect:** `dmp` header text changes (TITLE, axis labels, line symbol).
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline Spectra.bas:1082-1083`, `fbline Spectra.bas:1090-1091`, `fbline Spectra.bas:559` as quoted. Output `validation/test_run/dmp/Z86_A215_n_E14MeV/Eexc.dmp:11297-11307`: `ANALYZER(ErotL2dlight(0))` with `TITLE()`, `X: Channel`, `Y: Counts`, `Y,HT0`; versus `Eexc.dmp:29497-29504`: `ANALYZER(ErotL2dheavy(0))` with `TITLE(Rotational energy over angular momentum)`, `X: L / hb^`. No `NNCN` dump exists in the recorded `dmp` files, so that part is not visible in output; the T0 dump of the registry (M4.5) shows the `NPCNtot` entry in `NNCN`'s slot, and the C++ reproduces every entry.
- **Fidelity switch:** `fix_analyzer_registry_names`
- **C++ symbol:** `gef::analysis::build_analyzer_registry` (`Cpp_implementation/src/analysis/analyzer_registry.cpp`, M4.5); `Find_IAnl` follows with the writers (M13)
- **Owning milestone:** M4

### Q-021 `I_MAT_ENDF` persists state in `ctl/IMATmax.ctl`

- **BASIC location:** `NucProp_Functions.mac:11-63` (seed said 28–49; the file I/O spans 37–58)
- **Mechanism:** for a nuclide missing from `NucTab`, the lookup does `CHDIR("ctl")` (37; GEF.c:4668 `fb_ChDir`), reads `IMATmax.ctl` for an earlier assignment (38–49), otherwise assigns `IMAT_max + 1`, appends `IZ, IA, IMAT` to the file (51–56) and returns with `CHDIR("..")` (58). The file is never deleted (no `Kill` in the source). "Missing" is `IMAT = 0`, so Z = 0, A = 0, which matches the empty record `NucTab(0)`, is treated as missing too and gets a MAT number from the file (the first one of a fresh `ctl/` in the M4.6 grid: 3853 for JEFF-3.3).
- **Effect (expected):** MAT numbers of nuclides outside `NucTab` depend on the history of earlier runs in the same working directory, and the lookup changes the process working directory temporarily. Callers (`fbdef I_MAT_ENDF --refs`) include the event loop (`GEF.bas:9259, 9379`), the isomeric-yield output (14246), set-up (3562, 3707, 3751) and the ENDF writer (`ENDF.bas:332, 695, 934`). Within one run, numbers assigned by a step body shift those of later systems (M6, full run F4 below).
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline NucProp_Functions.mac:37`, `fbline NucProp_Functions.mac:52-53` as quoted. Not exercised in `validation/test_run`: `ctl/` holds no `IMATmax.ctl` and `run.log` has no `<I> IMAT =` line. M4.6 T1: captures `m4-lookups-jeff33` and `m4-lookups-nubase2016` (harness patch `lookups`, the full (Z, A) grid in a fresh `ctl/`): 720 and 713 assignments in `ctl/IMATmax.ctl`, reproduced line by line by the C++ (`lookups_test.cpp`). M6: capture `edge-e_missing_nuclide` (U-250 `EN`, target U-249 not in `NucTab`, then Pu-252 `EN1`): the set-up assigns `<I> IMAT = 3853 assigned to Z = 92, A = 249`; in the full run (`m6-full-f1-f7`, F4) the first system's events assign 3854-3954 to fission fragments missing from `NucTab`, so the second system's target gets 3955 where the setup-only run gives 3854. `run_corpus_test.cpp` reproduces the set-up's assignments and `run_console_test.cpp` their console lines (in full runs offset by the assignments BASIC printed in the step body); further assignments in `m6-setup-corpus` (`gefy_sfy`, `SFred`, `SFtest`, `FM256S`). Edge systems in M15.
- **Fidelity switch:** `fix_imat_no_persistent_state`
- **C++ symbol:** `gef::data::i_mat_endf` with `gef::data::MatNumberState` (`Cpp_implementation/src/data/lookups.cpp`, M4.6): the state holds `I_message` and the bytes of `ctl/IMATmax.ctl`. M6: one state for the whole run, `gef::run::ProcessState::mat` (plan D7: no `CHDIR`, the file in memory); the set-up lookups (3562, 3707, 3751) go through `mat_number` in `Cpp_implementation/src/run/step_setup.cpp`. Reading an `IMATmax.ctl` left by an earlier run and writing it to disk go with Q-026 (M13/M14).
- **Owning milestone:** M4 (in-process state in M6; the file on disk in M13/M14)

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

### Q-032 The stock `NucPropNUBASE2020.bas` stops GEF while loading

- **BASIC location:** `NucPropNUBASE2020.bas:56-94` (selected by replacing the include at `GEF.bas:1052`)
- **Mechanism:** the mass-excess conversion loop `For I_MAT = 1 To N_MAT_MAX … Next I_MAT` (`NucPropNUBASE2020.bas:95-98`) sits inside the record-reading `Do Until I_MAT = N_MAT_MAX` loop instead of after it, and reuses `I_MAT` as its counter. After the first record it leaves `I_MAT = N_MAT_MAX + 1`, so the `Do Until` test never holds again: each further pass increments `I_MAT`, prints `<E> NucPropx: N_MAT_MAX too small!` (line 80) and reads a record into `NucTab(I_MAT)` past the array's end (an out-of-bounds write; GEF is compiled without bounds checks). The lines after the inner loop (R_SPI clamp, isomer bookkeeping) also address `NucTab(N_MAT_MAX + 1)`. The `DATA` pointer keeps advancing through the following tables until a value read as `I_ISO` lies outside 0…9; then line 89-93 prints `<E> Error in NucProp` and `GEF stopped.` and ends the program.
- **Effect:** GEF cannot run with this variant as shipped; it stops before the T0 probe point.
- **Evidence status:** *confirmed in output*
- **Evidence:** reference-store capture `m4-t0-nubase2020` (patch set `m4-nubase2020`, input `harness/inputs/m4_t0.in`): 6,556 "too small" lines, then the error and stop. Same output from a build with only `nucprop-nubase2020` and `seed` (M4.1, 2026-10-09). The NUBASE 2016 file loads normally.
- **Fidelity switch:** none planned (the C++ loader reproduces the stop when this variant is selected)
- **C++ symbol:** `gef::data::load_nubase2020` (`Cpp_implementation/src/data/nuclide_tables.cpp`, M4.3) throws `GefStopped` with the same 6,558 lines (checked against the capture's `stdout.log`). It reproduces every `Read` (so the stop comes at the same item) and the printed lines; the out-of-bounds writes and the statements that address `NucTab(N_MAT_MAX + 1)` have no observable effect before the stop and are not emulated.
- **Owning milestone:** M4

### Q-033 Loader error messages say "GEF stopped." but GEF continues

- **BASIC location:** `NucPropJEFF33.bas:77-82` and the same block in `NucPropJEFF311.bas`, `NucPropNUBASE2016.bas`, `NucPropx/mf/f.bas`; `Branchings.bas:76-80`
- **Mechanism:** the checks print an error and `GEF stopped.`, then `Sleep`, but have no `End` (unlike `NucPropNUBASE2020.bas:89-93`), so the program carries on with the bad record after a key press. (The unknown-time-unit message at `Branchings.bas:214-216` also continues, but does not claim to stop.)
- **Effect:** none with the shipped tables: no certified variant triggers these checks (the `stdout.log` of every M4.1 capture has no such line). With a corrupt table the run would continue after claiming to stop.
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `fbline NucPropJEFF33.bas:77-82`, `fbline Branchings.bas:76-80` (no `fb_End` call); M4.3 tests check that the loaders print nothing for the shipped data.
- **Fidelity switch:** `fix_loader_error_stop`
- **C++ symbol:** `gef::data::load_plain` and `gef::data::load_branchings` write the lines to `TableSet::console` and continue
- **Owning milestone:** M4

### Q-034 JEFF-3.1.1 nuclide table is 9 records shorter than its `N_MAT_MAX`

- **BASIC location:** `NucPropJEFF311.bas:47-57` (counting loop), `90` (`If NucTab(I_MAT).I_Z = 111 Then Exit Do`), `94` (message)
- **Mechanism:** the counting loop counts every record up to the `9999` terminator, `N_MAT_MAX = 3887`, and `NucTab` is dimensioned for them; the reading loop leaves at the first `I_Z = 111` record, number 3878. The last 9 entries stay zero (Z = 0, A = 0) and the loader prints `<E> Nucprop: N_MAT_MAX too large, should be  3878` and continues. (The JEFF-3.3 and NUBASE files have the `I_Z = 111` exit commented out.)
- **Effect:** every JEFF-3.1.1 run prints that line; lookups that scan `NucTab` to its end see the 9 empty entries.
- **Evidence status:** *confirmed in output*
- **Evidence:** capture `m4-t0-jeff311`: `stdout.log` line 21, and the T0 dump (`N_MAT_MAX` 3887, records 3879–3887 zero). Reproduced by `nuclide_tables_test.cpp`.
- **Fidelity switch:** none planned (data, not code)
- **C++ symbol:** `gef::data::load_plain` (`TableSet::console`)
- **Owning milestone:** M4

### Q-035 An unterminated or reversed `/'` comment in a parameter file hangs GEF

- **BASIC location:** `ReadParameters.mac:1-8` (included by `FitparRead.bas` and `MyparRead.bas`)
- **Mechanism:** `Do While Instr(Cline,"/'") > 0` removes a `/' … '/` comment only `If Ileft < Iright`. When a line has a `/'` without a later `'/` (`Iright` = 0, or the first `'/` stands before the first `/'`), the body changes nothing after the first `Trim`, so the loop never ends.
- **Effect:** GEF hangs while reading `Fitpar.dat` (or `MyParameters.dat`, Q-018) with such a line; nothing after the four "File Fitpar.dat found." notice lines is printed.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline ReadParameters.mac:1-8` (GEF.c:20644-20692: the loop jumps back to `label$214` without changing `CLINE$3` when `ILEFT$3 >= IRIGHT$3`). Run of `m4-jeff33-3164a3415262` with a `Fitpar.dat` holding `_P_Shell_S1 = 1 /' open` (M4.4, 2026-10-09): no further output, killed after 30 s.
- **Fidelity switch:** none planned. The C++ cannot usefully loop forever: `gef::params::read_parameters` throws `gef::params::GefHangs` where BASIC would start the endless loop.
- **C++ symbol:** `gef::params::read_parameters` (`Cpp_implementation/src/params/parameter_files.cpp`)
- **Owning milestone:** M4

### Q-036 The legacy NucProp files map nuclides outside `NucTab` to its last entry

- **BASIC location:** `NucPropx.bas:157-165`, `NucPropmf.bas:165-173`, `NucPropf.bas:162-170` (`I_MAT_ENDF`), with `R_AWR_ENDF` (`NucPropx.bas:182-188`, `NucPropmf.bas:190-196`, `NucPropf.bas:187-193`)
- **Mechanism:** `For I = LBound(NucTab) To UBound(NucTab): IMAT = I: If <match> Then Exit For: Next: I_MAT_ENDF = IMAT`. Without a match the function returns the loop variable's last value, `UBound(NucTab)`, and prints nothing; `R_AWR_ENDF` then returns that entry's AWR.
- **Effect:** in a build with a legacy nuclide-data file (not a stock GEF 2025/1.2 configuration, M4 plan D4), every nuclide missing from the table gets the MAT number and the AWR of the table's last nuclide. (JEFF-3.1.1's own version returns 0 and prints the warning once; the stock files use `NucProp_Functions.mac`, Q-021.)
- **Evidence status:** *confirmed in output*
- **Evidence:** capture `m4-lookups-legacy-x` (M4.6): `N 50 96 3897 43866893 …`, i.e. Sn-96 gets MAT 3897 = `UBound(NucTab)` and AWR 268.8; no "Missing MAT number" line in `stdout.log` (`m4-lookups-legacy-mf`, `-f` likewise).
- **Fidelity switch:** none planned (legacy, non-stock files)
- **C++ symbol:** `gef::data::i_mat_endf`, `gef::data::r_awr_endf` (`Cpp_implementation/src/data/lookups.cpp`)
- **Owning milestone:** M4

### Q-037 The fission barrier RF has no value at RX exactly 30

- **BASIC location:** `GEF.bas:17679-17690` (the four `If` tests on `RX` that set `RF`; `BFTF` spans `GEF.bas:17657-17750`)
- **Mechanism:** The tests are `RX < 30` (RF = 1E10), `RX > RX0` (RF = 0), `RX < RX1 And RX > 30` (linear) and `RX >= RX1 And RX <= RX0` (cubic). `RX` exactly 30 satisfies none of them, so `RF` keeps its `Dim` value 0 and `RB = RF * RS` is 0.
- **Effect:** At RZ = 60, RA = 120, `RI = 0`, so `RX = RZ^2 / RA = 30` exactly. Any input whose float `RX` is exactly 30 gets `RF = 0` and therefore `RB = 0`. `I_Switch` 0 then returns exactly 0, and `I_Switch` 1–5 add their shell and pairing terms to that zero base. `I_Switch` 6 also returns 0 at this point: `Max(RB + LYPAIR(60,120) * 2/12, 0)` clamps a negative pairing term (`LYPAIR(60,120)` ≈ −2.19, inferred from the grid values for `I_Switch` 1, 3 and 5).
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** GEF.c 17263-17314 (the guarded RF assignments between the `#line 17679` and `#line 17690` markers) has no branch for RX = 30. Driver output `BFTF_grid.txt:83841` of store capture `m5-barriers` (RZ 60, RA 120, I_Switch 0) is `00000000`; I_Switch 1 at the same point (line 83842) is `bebaf111`. Reproduced by the C++ (`physics: BFTF/BFTFA/BFTFB equals BASIC on the driver grids`). Not reached in the M5.2 captures: RX is 36.29–37.66 (Rn-215), 39.33–39.97 (U-236), 42.61 (Cf-252) and 46.62 (Sg-264) in every captured call (recomputed from the arglog records by the M5 review).
- **Fidelity switch:** `fix_bftf_rx30_hole`; the switch comes with a later fix decision (strategy §2.1); the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `gef::physics::bftf` (`Cpp_implementation/src/physics/barriers.cpp`)
- **Owning milestone:** M5

### Q-038 The E2 cascade stops before its first gamma when any state has spin CInt(J_frag)

- **BASIC location:** `GEF.bas:9330-9333` (light fragment), `GEF.bas:9447-9450` (heavy fragment)
- **Mechanism:** At the first J of `For J = Jfrag To 2 Step -2`, the isomer loop compares every state of the nucleus, the ground state included (Isotab holds the states in ascending spin order, `NucPropJEFF33.bas:143-155`, so K = 1 is the lowest-spin state, an isomer for e.g. Tc-99, In-115, Ir-192), with the fragment's total spin: `If Isotab(I_iso).R_SPI(K) = Cint(J_frag_light) Then Exit For, For`. A match leaves both loops before any gamma is stored and `C_iso_lmd` stays `"GS"`; if an earlier state K lies in the isomer window (lines 9335-9339), the cascade stops there instead with `"M(…)"` and also without a gamma. The line above it, commented out (`GEF.bas:9331`, `9448`), compares with `Cint(J_frag_light + Spin_gs_light)`. `CInt` rounds half to even (`fb_F2L`, GEF.c:68762). Generated C: `if( R_SPI(K) != (float)fb_F2L( J_FRAG_LIGHT$19 ) ) goto …; goto label$4263;` (label 4263 is after the J loop).
- **Effect:** the fragment emits no E2 gamma at all (no `EgammaE2`, `E_E2_tot` = 0, no rotational gammas in `Egamma`, `EgammaL`/`EgammaH`, `Ngamma*`), although its rotational band lies above the state, whenever the rounded total spin equals the spin of the ground state or of an isomer.
- **Evidence status:** *confirmed in output*
- **Evidence:** the arglog site logs of the M5.2 captures: records with Jfrag ≥ 2 and N_iso > 0 that end with label `GS` and no stored gamma (only this stop gives that outcome): light/heavy 248/318 (`m5-arglog-rn215`), 756/1036 (`m5-arglog-cf252`), 570/727 (`m5-arglog-u235`), 307/857 (`m5-arglog-sh264`), out of 7754–20853 such records per copy. Reproduced by `physics::e2_cascade` in `physics: E2 cascade replays the captured light and heavy cascades` and on the synthetic Isotab patterns of `physics: E2 cascade equals the light copy on the driver grids` (and the heavy copy).
- **Fidelity switch:** `fix_e2_ground_state_stop`, with a later fix decision (the corrected comparison would be the commented-out one; which test the authors intended is part of that decision); the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `gef::physics::e2_cascade` (`Cpp_implementation/src/physics/e2_cascade.cpp`)
- **Owning milestone:** M5 (function), M10 (event stage that calls it)

### Q-039 `Array_Eg2_light/heavy(100)` is written without a bound

- **BASIC location:** `GEF.bas:9352-9353` (light), `GEF.bas:9468-9469` (heavy); array `GEF.bas:1342-1343`
- **Mechanism:** `Ig2_light = Ig2_light + 1 : Array_Eg2_light(Ig2_light) = Eg`, one element per gamma of the cascade; the array is `ReDim Shared … (100)` and nothing limits Ig2. fbc builds GEF without `-exx`: GEF.c:68875 `*(float*)((IG2_LIGHT$0 << 2) + *(int64*)&ARRAY_EG2_LIGHT$) = EG$20;` writes past the array for Ig2 > 100, i.e. for Jfrag ≥ 202.
- **Effect:** none in the captured runs: the largest Ig2 in the M5.2 captures is 17 (heavy, Rn-215 and Sg-264; Jfrag ≤ 34), and the `-exx` runs of the same systems (`m5-exx-*`) raise no bound error. Beyond 100 the BASIC behaviour is undefined (heap corruption).
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `python3 -m tools.fbsrc.fbline GEF.bas:9353`; capture ranges from `python3 -m harness.arglog summary`; `MILESTONE_5_PLAN.md` §9, M5.5.
- **Fidelity switch:** none. Plan D3 default: the C++ throws `std::out_of_range` for a 101st gamma (`physics: E2 cascade throws beyond Array_Eg2(100)`); undefined behaviour is not reproduced.
- **C++ symbol:** `gef::physics::e2_cascade`
- **Owning milestone:** M5

### Q-040 TRusanov computes a pairing floor for E and does not use it

- **BASIC location:** `GEF.bas:16100-16107`
- **Mechanism:** `If E < Emin Then Eeff = Emin Else Eeff = E` ("Introduced Sept. 2021", Emin = 8), then `TRusanov = sqr(E / (0.094E0 * A))`: the result uses E, not Eeff. GEF.c:12017-12038: `EEFF$1` is assigned on both paths and never read; the return is `__builtin_sqrt( (double)E$1 / ((double)A$1 * 0x1.810624DD2F1AAp-4) )`.
- **Effect:** the temperature has no floor at the critical pairing energy. In the M5.2 captures E < 8 in 1375 of 1409 calls (U-236), 101 of 101 (Cf-252), 11 of 11 (Sg-264); Rn-215's smallest E is 0.1 (found by the M5 review; code-map candidate #10, `code_maps/setup_physics.md:737`).
- **Evidence status:** *confirmed by fbc C*
- **Evidence:** `python3 -m tools.fbsrc.fbline GEF.bas:16098-16108`; reproduced by `physics: TRusanov equals BASIC on the driver grids` and `physics: level_density replays the captured GEF calls`.
- **Fidelity switch:** `fix_trusanov_pairing_floor`, with a later fix decision; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `gef::physics::trusanov` (`Cpp_implementation/src/physics/level_density.cpp`)
- **Owning milestone:** M5

### Q-041 Beta_Equi prints its non-convergence message to whatever file number f holds

- **BASIC location:** `GEF.bas:16628`; `f` is `Dim Shared As Integer f` (`GEF.bas:1768`), set by `f = FreeFile` at `GEF.bas:4150, 4179, 10057`
- **Mechanism:** `If N > 998 Then Print #f,"Beta_Equi not converged: ",Z1,N` uses the shared file number of the `pfis`/`ptb` output files (GEF.c:13801-13814), which is 0 (the console) or 1 at the logged calls (arglog field `global.f`); it is not opened for this message.
- **Effect:** not reached in the M5 captured runs: the C++ replay of all 92,789 logged `Beta_Equi` calls asserts that none would print. It is reached on the grids of driver `m5_shape`: 699 of 979 structured rows (696 unphysical Z/A splits with N = 1001, and the threshold rows exiting at N = 999 and 1000) and 1,712 of 2,000 random inputs print once each. M7.0 (plan D6): it is reached from the table builder's call (GEF.bas:5722) in batch runs with nominal parameters. A C++ sweep through `physics::beta_equi` over every compound nucleus `U_Valid` accepts (4,825 of Z 1-140 × A 1-400; `U_Valid` itself refuses Z outside 76-120, GEF.bas:15823) and its multi-chance reductions (7,247 CN, 550,101 calls) finds 2,572 non-converging calls at DNECK = 1 (CN Z 94-120; IZ1 10-110, 1,652 of them at IZ1 = 10; N up to 1001), and DNECK, which `Fitpar.dat` can set to any value, changes the count without removing it for any of the nine values tried (−1: 3,985; 10: 1,214; 100: 7,533; program and outputs in capture `m7-d6-sweep`). BASIC prints the line `Beta_Equi not converged:     10            1001` to the console (`f` = 0 at that point) for Fm-212 and Ds-270 spontaneous fission. Where it goes after `f` has been set for a `pfis`/`ptb` file stays with M13.
- **Evidence status:** *confirmed in output* for the condition in batch runs (M7.0); *read only* for the destination when `f` <> 0
- **Evidence:** `python3 -m tools.fbsrc.fbline GEF.bas:16628`; driver output `Beta_Equi_print.txt` of store golden `m5-shape-2`, rebuilt by `physics: Beta_Equi equals BASIC on the driver grids`; `physics: Beta_Equi replays the captured GEF calls`; captures `m7-p3-fm212-sf` and `m7-p3-ds270-sf` (`stdout.log`; `f` in P3in).
- **Fidelity switch:** none yet (the C++ returns the condition as `BetaEquiResult::print_not_converged` with N, plan D7; the caller decides the destination in M7/M13)
- **C++ symbol:** `gef::physics::beta_equi` (`Cpp_implementation/src/physics/shape.cpp`); the builder's call (5722) hands the messages to its caller through the out-parameter `messages` of `gef::tables::mode_centres_and_deformations` (`gef::tables::BetaEquiMessage`, M7.1, plan D6; also when the bin then stops at Q-061); the M7.1 test checks them against the console lines of every M7 capture (fm212-sf and ds270-sf print one each)
- **Owning milestone:** M5 (condition), M7/M13 (destination)

### Q-042 Mass-table reads past the bounds read the neighbouring table or a malloc header

- **BASIC location:** the readers of `BEldmTF`, `BEexp`, `DEFOtab`, `ShellMO` (`ReDim Shared` at `GEF.bas:1222, 1233, 1244, 1255`; `EVOD` at 1266, never read): `LDMass` (16224, 16227), `AME2020` (16253), `U_SHELL` (16266), the system set-up (3361, 3368), `P_Egamma_low` (16987), the E2 cascade (9313, 9433) (`fbdef --refs`); reached through `BFTF`, `U_SHELL_exp`, `U_SHELL_EO_exp` and every caller of these.
- **Mechanism:** fbc compiles GEF without `-exx`; `BEexp(N, Z)` is `*(float*)(((N * 137 + Z) << 2) + data)` (e.g. GEF.c at `fbline GEF.bas:3361`), with no check. The five tables (with `EVOD`, declared and never filled) are allocated one after the other at start-up (GEF.c:25524-25620: nothing else is allocated between the five `fb_ArrayRedimEx` calls; each table is dimensioned once and never erased), each one glibc malloc chunk: `BEldmTF | 16 | BEexp | 16 | DEFOtab | 12 | ShellMO | 16 | EVOD`. A gap is the end of a chunk, zeroed because libfb allocates with `calloc` (which clears up to the next chunk's size word), then the next chunk's 8-byte size word (chunk size with PREV_INUSE set: `0x1B4C1` for the 204 × 137 tables, `0x1FB61` for DEFOtab). An index past one table therefore reads the next table, or a header word. The layout depends on glibc's main arena (DEFOtab's 129888-byte chunk is below the default 128 KiB mmap threshold); another allocator or a lowered `MALLOC_MMAP_THRESHOLD_` would change it.
- **Effect:** for a CN beyond the tables GEF computes with values of other nuclides' tables. Capture `edge-f_second_system_outside_table` (line `92, 236, 82, 300, 5, "EB"`): `AME2020(82, 300)` reads `BEexp(218, 82)` = `DEFOtab(14, 78)` = 0, `BEldmTF(218, 82)` reads `BEexp(14, 78)` = −1.E11; BASIC prints `Inner saddle =-1e+11 MeV`, `exp. Mass =  0 MeV`, and ends at GEF.bas:3869 (`Eabsgs < 0`). Reads before `BEldmTF` or after `EVOD` would read other heap data, which the C++ does not model.
- **Evidence status:** *confirmed in output*
- **Evidence:** gdb on build `seed-probes-32c3cfccb98c` at the first `AME2020(82, 300)` call of that capture (M6.4, 2026-10-28): the five tables' data pointers and sizes, and a dump of the memory from 256 bytes before `BEldmTF` to 256 bytes past `EVOD`; from `BEldmTF`'s first element to `EVOD`'s last it equals the C++ tables plus the gap model byte for byte; builds `none-8ee226bf3241` and `seed-probes-9bc237a66eec` place the tables at the same relative offsets. Reproduced by `table_memory_test.cpp` (values read from the dump, including reads that land on filled elements of the next table) and by `run_corpus_test.cpp` and `run_console_test.cpp`, whose runs of the capture equal BASIC's P0/P1/P1b records, console and run end.
- **Fidelity switch:** `fix_table_overrun` (`gef::data::TableSet::fix_table_overrun`; true: a read outside the bounds throws `std::out_of_range`). The C++ has no `Fidelity` configuration yet; the switch moves there when it exists.
- **C++ symbol:** `gef::data::read_mass_table` (`Cpp_implementation/src/data/table_memory.cpp`), called by `gef::physics::ld_mass`, `ame2020`, `u_shell`, `e2_cascade`, `p_egamma_low_table` and `gef::run::begin_system`
- **Owning milestone:** M6.4 (user decision 2026-10-28, `MILESTONE_6_PLAN.md` §8; amends M5 plan D3)

### Q-043 The average-spin check of the energy line reads a stale `Emode`

- **BASIC location:** `GEF.bas:2801` (in the energy-line parse 2795-2825); `Emode` start value `GEF.bas:898`, batch assignments `GEF.bas:3227-3277`
- **Mechanism:** an energy value written `E/spin` is refused unless `Abs(Emode) <= 1 Or Emode = 3` (GEF.c:38535 `if( ((int64)-(__builtin_llabs( EMODE$ ) > 1ll) & (int64)-(EMODE$ != 3ll)) == 0ll ) goto …`). The check runs while the sequence file is parsed, before any of its system lines is read; in batch mode `Emode` is set only by the system loop from each line's channel (3227-3277, after the parse and after the `done.ctl` and `U_Valid` skips). It therefore tests the channel of the last system line of an earlier file that got that far, or the start value 1.
- **Effect:** whether `E/spin` is accepted depends on the file before: an `E/spin` energy line is accepted in the first file (`Emode` 1) and refused (`<E> Error in input line:` … `Press Enter key to leave GEF!`, then `End`) after a file whose last computed line was `EN` (`Emode` 2), whatever the new file's channels are; by the condition the same holds after `EP` (12), `EM` (13) and `EA` (22). The missing-isomer restart (Q-049) re-parses with the `Emode` the earlier round left, so a restart can end here.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:2795-2803` as quoted; `fbdef Emode --refs`. Captures (M6.0-M6.2, setup-only build `seed-probes-32c3cfccb98c`): `m6-setup-edge-7/edge-l_espin_stale` (file 1 an ENDF `EN` line, file 2 `2/10` for `EB`: refused, stdout ends with the error text), `edge-e_eb` (an `E/spin` line for `EB` as the first file: accepted), `m6-setup-restart/edge-l_restart_emode` (five rounds, the last two differing only in `Emode`, then this end). Reproduced by `run_input_test.cpp` (the P0 parses and their outcome), `run_driver_test.cpp` and `run_corpus_test.cpp` (run end), `run_console_test.cpp` (text).
- **Fidelity switch:** `fix_espin_check_channel` (check the channel of each system line instead); the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `read_energy_table` in `Cpp_implementation/src/run/input_files.cpp` (via `gef::run::read_sequence_file`)
- **Owning milestone:** M6

### Q-044 The energy of a two-system line is ignored

- **BASIC location:** `GEF.bas:3150` (`P_E_exc_Double = S_par(Iline).E_double`), `GEF.bas:3304` (`P_E_exc = P_E_exc_Double`), overwritten at `GEF.bas:3449-3497`
- **Mechanism:** for the second system of a 6-field line (`Z1, A1, Z2, A2, E, channel`) 3304 sets `P_E_exc` from the line's own energy (GEF.c:41349), but the batch step schedule (3449-3497) assigns `P_E_exc` again for every `Emode` before any reader (`fbdef P_E_exc_Double --refs`: no other reader in batch mode).
- **Effect:** both systems run at the file's energy table; the line's energy changes nothing. Capture `edge-e_two_system` (`92, 236, 94, 240, 7, "EB"` with energy line 5): P1 of both systems has `P_E_exc` = 5 (`40A00000`) and `P_E_exc_Double` = 7 (`40E00000`), `Csystem` `Z92_A236_EB_E5MeV` and `Z94_A240_EB_E5MeV`.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:3150`, `fbline GEF.bas:3304`, `fbline GEF.bas:3459-3497`; capture `m6-setup-edge-7/edge-e_two_system` and the full run `m6-full-f1-f7/edge-e_two_system` (F2); reproduced by `run_corpus_test.cpp`.
- **Fidelity switch:** `fix_two_system_energy`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `gef::run::RunDriver::system_iteration` (3301-3305) and `RunDriver::step_energy` (`Cpp_implementation/src/run/driver.cpp`)
- **Owning milestone:** M6

### Q-045 Single-step channels run `Energy_table(1)` but are named and deduplicated by `En_max`

- **BASIC location:** `GEF.bas:3225` (`P_E_exc = En_max`), `GEF.bas:3217` (`done.ctl` record), `GEF.bas:3412-3422` (`_sf`/`_cf`/`_fc` suffix of `CFileout`), `GEF.bas:3494-3495` (step energy)
- **Mechanism:** `FC`, `IS`, `ES` and `EM` keep `N_E_steps = 1` and run `P_E_exc = Energy_table(I_E_step)` = `Energy_table(1)` (GEF.c:43218), the lowest energy of the line, while the `done.ctl` key (3217, `En_max`, GEF.c:40890) and the output-file name use `En_max`: `CFileout` is built in the system set-up, where `P_E_exc` still holds `En_max` (3225, GEF.c:40927; `If P_E_exc = 0` at 3413, GEF.c:42216).
- **Effect:** a single-step line with several energies computes only the first one, under a `done.ctl` key (all four channels) and, for `FC` and `IS`, an output-file suffix (`_sf` or `_cf`/`_fc`, 3412-3422) that refer to the last; `ES` and `EM` get `_ed`/`_em` whatever the energy. Capture `edge-e_is` (`0, 1.5` with `IS1` for Am-242): `Cfileout` `GEF_95_242f1_cf` (`En_max` 1.5 ≠ 0) while the step runs at 0 MeV plus the isomer energy, `Csystem` `Z95_A242f1_sf_E0MeV`; `edge-e_fc` (`6, 8`, `FC`): one step at 6 MeV, `En_max` 8.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:3225`, `fbline GEF.bas:3217`, `fbline GEF.bas:3413`, `fbline GEF.bas:3459-3497`; captures `m6-setup-edge-7/edge-e_is`, `edge-e_fc`, `edge-l_channels`; reproduced by `run_corpus_test.cpp` (P1) and `run_driver_test.cpp` (the steps and the `done.ctl` decisions).
- **Fidelity switch:** `fix_single_step_energy`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `gef::run::RunDriver::step_energy`, `RunDriver::register_done` (`driver.cpp`); `name_output_file` in `Cpp_implementation/src/run/system_setup.cpp` (via `gef::run::begin_system`)
- **Owning milestone:** M6

### Q-046 A spectrum-file energy line keeps the energy table of an earlier file

- **BASIC location:** `GEF.bas:2780-2787` (quoted file name: the numeric branch 2788-2825 is skipped); readers `GEF.bas:3072` (two-system check), `3217`/`3225` (`En_max`), `3495` (step energy)
- **Mechanism:** when the energy line is a quoted spectrum file name, the parse sets `C_Espectrum1` (2781, GEF.c:38387) and leaves `N_E_values`, `Energy_Table`, `Spin_Table`, `En_min` and `En_max` as earlier files left them: the first three as the round's earlier files (or the `Dim`s after `Nextfitloop`, 2648-2650) left them; `En_min` and `En_max` are `Static` (2652-2653), so after a restart they even keep the previous round's values. The `ES`/`EM` step energy (3495), the `done.ctl` key (3217) and the two-system check (3072) read them.
- **Effect:** `ES`/`EM` lines carry the energy table of whatever file came before: capture `edge-l_spectrum_stale` (files `e_lines_spectrum`, `e_lines`, `e_es`): the first file's `EM` steps run at the start-up `Energy_Table(1)` = 0; the third file's `ES` line for U-236 gets `En_max` 5 from the second file, so its `done.ctl` key equals that of the second file's `EB` line for U-236 at 5 MeV and it is skipped (`… E =  5 Fenhance =  1 I_Mode_selected = -1 skipped (already in done.ctl).`, with Q-048). In `edge-l_channels` the `ES` line runs with `P_E_exc` = 25 (`41C80000`) from the `EA` file before it.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:2780-2787`, `fbline GEF.bas:2824`, `fbline GEF.bas:3459-3497`; captures `m6-setup-edge-7/edge-l_spectrum_stale`, `edge-l_channels`; reproduced by `run_input_test.cpp` (P0), `run_corpus_test.cpp` (P1, run end) and `run_console_test.cpp`.
- **Fidelity switch:** `fix_spectrum_line_energy_table`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `read_energy_table` in `input_files.cpp` (via `gef::run::read_sequence_file`); `gef::run::RunDriver::step_energy`
- **Owning milestone:** M6

### Q-047 The excitation-energy spectrum is normalised 0/0 without a spectrum, and again at every step

- **BASIC location:** `GEF.bas:3682-3689`; start-up `GEF.bas:2671` (`Redim As Single W_spectrum(1)`)
- **Mechanism:** the loop `Norm = Σ W_spectrum(I)`, `W_spectrum(I) = W_spectrum(I) / Norm` (GEF.c:44312-44377) runs at every energy step for every `Emode`, not only for `ES`/`EM`. Without a spectrum `W_spectrum(1)` is the cleared start-up element, so the division is 0/0 = NaN (`FFC00000`, x86's default NaN); a spectrum read once is divided again by its (already 1) sum at every later step.
- **Effect:** after a step without a spectrum, as long as no spectrum has been read in the round, `W_spectrum(1)` is NaN and `W_spectrum_max` 0; P1 shows both (capture `edge-e_gs`: `W_spectrum 1 S FFC00000`, `W_spectrum_max - S 00000000`). Once a spectrum has been read it stays and is normalised again (`edge-l_spectrum_stale`, record 3: `W_spectrum 1` `3DCCCCCD`).
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:2671`, `fbline GEF.bas:3682-3691`; captures `m6-setup-edge-7/edge-e_gs` and every setup-only capture with a non-spectrum step before any spectrum of the round; reproduced by `run_corpus_test.cpp` (P1 `W_spectrum`, `W_spectrum_max`).
- **Fidelity switch:** `fix_spectrum_normalisation`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `normalise_spectrum` in `Cpp_implementation/src/run/step_setup.cpp` (via `gef::run::set_up_step`)
- **Owning milestone:** M6

### Q-048 The `done.ctl` key: no channel, and a `Fenhance` read back as `Single`

- **BASIC location:** `GEF.bas:3174-3217` (check 3176-3212, record 3217)
- **Mechanism:** the record is `Print #Fdone, P_Z_CN, P_A_CN, En_max, Fenhance, I_Mode_selected` (GEF.c:40884-40894; `Fenhance` printed as `Double`), read back with `Input #Fdone` into the `Single`s `Zdone, Adone, Edone, Fenhance_done` and the `Integer` `Imode_done` (GEF.c:40702-40712), and compared field by field, `Fenhance` as `(double)Fenhance_done != Fenhance` (GEF.c:40727). The channel is not part of the key. The record of a system is written at 3217, before `If Fenhance = 0 Then Fenhance = 1` (3922). The check is off in fit mode (`If B_Fit = 0`, 3174).
- **Effect:** (1) a repeated line is never recognised when `Fenhance` is not exact in `Single` (0.1): capture `edge-e_dup3` computes both repeats; (2) a second line with the same Z, A and `En_max` but another channel is skipped (`edge-e_dup2`: the `GS` line after `EN` for U-236; `edge-l_spectrum_stale`, Q-046); (3) with `Fenhance` 0 the first system's record holds 0 and every later one 1, so a repeat of the first system is computed again (`edge-e_fen0`).
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:3174-3182`, `fbline GEF.bas:3217`, `fbline GEF.bas:3922`; captures `m6-setup-edge-7/edge-e_dup1`, `edge-e_dup2`, `edge-e_dup3`, `edge-e_fen0`, `edge-l_dedupe`; reproduced by `run_driver_test.cpp` (the skips, against stdout) and `run_corpus_test.cpp` (the computed systems). The C++ keeps `done.ctl` in memory (plan D2) and reads it back with `fb::InputFile`.
- **Fidelity switch:** `fix_done_key`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `gef::run::RunDriver::find_done`, `RunDriver::register_done` (`driver.cpp`)
- **Owning milestone:** M6

### Q-049 A missing isomer restarts the whole input, and can do so for ever

- **BASIC location:** `GEF.bas:3563-3567` (`Goto RepeatInput`), `RepeatInput:` `GEF.bas:1909`
- **Mechanism:** when the isomer number of the entrance channel exceeds `N_ISO_MAT` (3563), GEF prints `Please stop GEF, complete table and restart GEF.` and jumps to `RepeatInput` (GEF.c:43660-43680: the step's arrays are erased, then `goto label$1568`). In batch mode that runs 1910, 2515-2517, `Nextfitloop` (FitparRead, the `Var_*` widths, 2647-2684) and reads `file.in` again from the first file. The round ends only when `done.ctl` holds every line that restarts, or when a value left by the earlier round (`Emode` at 2801, Q-043; `En_max` in the `done.ctl` key) leads to an `End`. In fit mode the `done.ctl` check is off, so only such a stale value can end it; otherwise it never ends.
- **Effect:** every system before the faulty line is computed again (in non-fit mode skipped through `done.ctl` only if its key repeats exactly, Q-048), and the widths of 2575-2620 are recomputed with the working copy `PZ_S3_olap_curv` the earlier round left (Q-019). Capture `edge-e_restart` (system, system with a missing isomer, system) restarts once and ends through `done.ctl`; `edge-l_restart_stale`, `m6-setup-restart/edge-l_restart_emode` (five rounds, the last two differing only in `Emode`) and `edge-l_restart_fit_stale` (fit mode) end at the `E/spin` check with a stale `Emode` (Q-043); a fit-mode run without such a value, run directly in M6.2, did not end.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:3560-3566`, `fbline GEF.bas:3567`; captures `m6-setup-edge-7/edge-e_restart`, `edge-l_restart_stale`, `m6-setup-restart` (`edge-l_restart_emode`, `edge-l_restart_fit_stale`), full run `m6-full-f1-f7/edge-e_restart` (F6); `MILESTONE_6_PLAN.md` §4 "Missing isomer in batch", §9 M6.2. Reproduced by `run_driver_test.cpp` (the rounds of every capture; restart unit tests: fit mode, `Fenhance` 0.1, 1 and 0, two missing isomers, stale `Emode`) and `run_corpus_test.cpp`.
- **Fidelity switch:** `fix_missing_isomer_skip` (skip the line instead of restarting); the C++ has no `Fidelity` configuration yet. The C++ cannot loop for ever: `RunDriver::restart` throws `gef::params::GefHangs` when a round would start from a state an earlier round started from (`RunDriver::RoundStart`; the proof holds for the empty step body of M6, plan §8).
- **C++ symbol:** `set_isomer` in `step_setup.cpp` (returns false; its caller `gef::run::set_up_step` returns `Flow::Restart`), `gef::run::RunDriver::restart` and `RunDriver::round_start` (`driver.cpp`)
- **Owning milestone:** M6

### Q-050 The per-file reset leaves most options set and clears the `B_Error_On` of `FIT`

- **BASIC location:** `GEF.bas:2829-2842` (per-file reset); option assignments in `GEF.bas:2843-3118`; `B_Fit` written only at 868, 2729, 2987; `B_Error_On = 1` by `FIT` in `file.in` at 2730
- **Mechanism:** before each sequence file's options are read (after its energy line), the reset sets `B_Error_On`, `Brec`, `Bcov`, `Bcor`, `B_supp`, `B_ENDF`, `B_Random_On`, `CFileoutlmd`, `Clocal_file_option` and `I_Mode_selected` (GEF.c:38676-38703). It does not reset `EOscale` (`NEO`), `D_Par_Fac` (`DPARFAC`), `B_MyParameters`, `Bplot`, the list-mode `P*` flags, `Cfileoutlmd_full`, `N_iter`, `C_Fitoption` or `B_Fit`, so a later file inherits them; and it clears the `B_Error_On = 1` that `FIT` in `file.in` set (2730), before the first file's options are read.
- **Effect:** options of one sequence file apply to every later file of the run: capture `edge-l_sticky` (file 1 with `NEO`, `DPARFAC(2)`, `LMD`, `FIT`; file 2 plain): P0 of file 2 still has `EOscale` 0, `D_Par_Fac` 2, the LMD flags and `B_Fit` 1. `edge-l_options_reset` shows the fields the reset does clear; `m6-setup-restart/edge-l_restart_fit_stale` (`FIT` in `file.in`) has `B_Error_On` 0 in P0 of its first file.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:2829-2842`, `fbline GEF.bas:868`, `fbline GEF.bas:2729`, `fbline GEF.bas:2730`, `fbline GEF.bas:2987`; captures `m6-setup-edge-7/edge-l_sticky`, `edge-l_options_reset`, `edge-e_sticky1`, `edge-e_sticky2`, `m6-setup-restart/edge-l_restart_fit_stale`; reproduced by `run_input_test.cpp` (every P0 field) and `run_corpus_test.cpp`.
- **Fidelity switch:** `fix_per_file_option_reset`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `reset_file_options` in `input_files.cpp` (via `gef::run::read_sequence_file`); the surviving options are fields of `gef::run::ProcessState`
- **Owning milestone:** M6

### Q-051 `B_Error_On`, `B_ENDF` and `B_Random_On` carry over from one system line to the next

- **BASIC location:** `GEF.bas:3459-3490` (ENDF step schedule), `GEF.bas:3268-3275` (`ES` with `B_ENDF`)
- **Mechanism:** in an ENDF file the schedule sets `B_Error_On` per step (GEF.c:43046-43194) and leaves it 0 after the last step of a multi-energy line (3487-3488); nothing resets it per system line, so a following line whose schedule does not assign it (a non-`EN` line: 3459 applies only to neutron-induced lines) runs with the value left. An `ES` line in an ENDF file prints `<W> ENDF output not available for option 'ES'.` and clears `B_ENDF` and `B_random_on` (GEF.c:41218-41221) for the rest of the file.
- **Effect:** capture `edge-e_sched_mixed` (`EN` with several energies, then `GS`, in one ENDF file): the `GS` line runs with `B_Error_On` 0, i.e. without the error analysis the file asked for; `edge-e_sched_es_endf`: the `EM` line after an `ES` line runs without ENDF output.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:3268-3277`, `fbline GEF.bas:3459-3497`; captures `m6-setup-edge-7/edge-e_sched_mixed`, `edge-e_sched_es_endf`, full run `m6-full-f1-f7/edge-e_sched_mixed` (F7, with its pass schedule); reproduced by `run_corpus_test.cpp` (P1 `B_Error_On`, `B_ENDF`, `B_Random_on`) and `run_driver_test.cpp` (pass schedule).
- **Fidelity switch:** `fix_per_line_error_flags`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `gef::run::RunDriver::endf_step_energy`, `RunDriver::select_channel` (`driver.cpp`)
- **Owning milestone:** M6

### Q-052 `DPARFAC` takes effect only from the next input round

- **BASIC location:** `GEF.bas:2888-2892`; widths `GEF.bas:2575-2620`
- **Mechanism:** `DPARFAC(x)` sets `D_Par_Fac = Val(Cval)` (GEF.c:39058-39060) and prints `<W> Sorry, this option is not yet available!!!!!!!`. The perturbation widths `Var_*` that use `D_Par_Fac` are computed at 2575-2620, before `file.in` and the sequence files are read, and again only at the next pass through `Nextfitloop` (a fit iteration, or the restart of Q-049). `D_Par_Fac` is not reset per file (Q-050).
- **Effect:** in the round that reads it the option changes nothing, as the warning says; after a restart or in fit iteration 2 and later the widths are scaled by it. P1 `Var_P_DZ_Mean_S1` is `3CF5C28F` with `DPARFAC(2)` (captures `edge-e_options`, `edge-l_sticky`: `D_Par_Fac` `40000000`) and without it (`edge-e_gs`: `D_Par_Fac` `3F800000`).
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:2888-2892`; `fbline GEF.bas:2610` (Q-019, B-004); captures `m6-setup-edge-7/edge-e_options`, `edge-l_sticky`, `edge-e_gs`; reproduced by `run_corpus_test.cpp` (P1 widths). The later-round effect is not captured (M16 owns fit iterations after the first).
- **Fidelity switch:** `fix_dparfac_widths`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `read_option` in `input_files.cpp`; `gef::run::begin_round` (`system_setup.cpp`) calls `gef::params::update_widths`
- **Owning milestone:** M6 (M16 for the fit iterations)

### Q-053 `S_par(5000)` is filled without a bound

- **BASIC location:** `GEF.bas:2664` (`Static S_par(5000) As S_par_type`), writes `GEF.bas:3050-3055`, `3057-3061`, `3087-3091`
- **Mechanism:** each system line (and each nucleus of an A range) does `Iline = Iline + 1` and writes `S_par(Iline)` (GEF.c:40055-40060: `*(int64*)(… + (ILINE$0 << 6)) = …`), with no check against 5000; GEF is built without `-exx`. `Cfilein(1000)` is checked (2738), `S_par` is not.
- **Effect:** a sequence file with more than 5000 systems writes past the array: capture `m6-s-par-overflow` (5001 system lines): the `-exx` build stops with runtime error 6 at GEF.bas:3058, the normal build aborts (SIGABRT). No corpus file comes near the limit (the largest, `gefy_sfy`, has 251 system lines).
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:3050`, `fbline GEF.bas:3051`, `fbline GEF.bas:3057`, `fbline GEF.bas:3087`; capture `m6-s-par-overflow` (M6.0). `run_input_test.cpp` checks that the C++ throws `std::out_of_range` at the 5001st line.
- **Fidelity switch:** none. Undefined behaviour is not reproduced (as Q-039): `ProcessState::s_par` is an `fb::Array`, whose bound check throws.
- **C++ symbol:** `read_system_line`, `read_pair_line`, `read_data_line` in `input_files.cpp`
- **Owning milestone:** M6

### Q-054 `ES` and `EM` steps read `Spin_CN` and `Eabsgs` left by earlier code

- **BASIC location:** `GEF.bas:3698-3843` (no assignment for `Emode` 3 and 13), readers `GEF.bas:3849`, `3869` and probe P1; writers `GEF.bas:4248-4249` (pre-pass), `5552`, `5558` (bins); `Spin_CN` is `Static` (1749)
- **Mechanism:** the set-up assigns `Spin_CN` and `Eabsgs` for `Emode` 0, ±1, 2, 12 and 22 (`fbdef Spin_CN --refs`, `fbdef Eabsgs --refs`); `Case 3` and `Case 13` of the `Select Case Emode` at 3785 assign nothing. The energy checks (3849, 3869: GEF.c:45124, 45219) and P1 read what the previous system's set-up, the pre-pass (`Eabsgs = E_spectrum(I_Estep)`, `Spin_CN = L_spectrum(I_Estep)`, GEF.c:47924-47927) or the bins (`Spin_CN = 0` at 5552, `L_spectrum(I_E_distr)` at 5558) wrote last. The pre-pass decision (3967) does not depend on the stale value: `ES` skips the block of 3948 (GEF.c:45793), and for `EM` `Or Emode = 13` decides (GEF.c:45843 evaluates both operands).
- **Effect:** the `Eabsgs < 0` end (3869) of an `ES` or `EM` step depends on the system computed before it, and P1 shows the stale values. Capture `edge-l_channels`, record 13 (an `ES` line for U-236 after the `EA` line of Pu-242 at 40 MeV): `Spin_CN` 10.705837 (`412B4B1C`) and `Eabsgs` 34.355244 (`42096BC5`), both the `EA` record's values. In the full run F1 (`m6-full-f1-f7/edge-l_spectra`) the only computed step is the first of the run (its `EM` line is skipped through `done.ctl`, Q-046, Q-048), so both runs show the start value 0; `Spin_CN` stays in the corpus test's list of step-body fields left out of full runs, as a write of 5552 and 5558.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:3947-3972`, `fbline GEF.bas:4248-4249`, `fbline GEF.bas:5552`, `fbline GEF.bas:5558`, `fbline GEF.bas:3849-3874`; capture `m6-setup-edge-7/edge-l_channels` (P1b record 13: `Harness_Prepass` 0); `m6-full-f1-f7/edge-l_spectra` with `patch_check.json`; reproduced by `run_corpus_test.cpp` (P1, P1b). The step-body writers belong to M9 (`ProcessState::spin_cn`, `eabsgs`).
- **Fidelity switch:** `fix_spectrum_step_spin_energy`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `set_excitation`, `check_energy` in `step_setup.cpp` (via `gef::run::set_up_step`); the bin writes 5552, 5558: `gef::tables::BinPlan::next` (M7.1, every loop iteration, populated or not; `tables: EM and ES passes leave the last iteration's spin, populated or not`)
- **Owning milestone:** M6 (set-up), M7 (the bin writes), M9 (the pre-pass writes)

### Q-055 No excitation-energy limit in batch mode; `Emax_valid` is never read

- **BASIC location:** `GEF.bas:894` (`Dim Shared As Single Emax_valid = 100 /' Maximum allowed excitation energy '/`), `GEF.bas:3849-3868`
- **Mechanism:** `fbdef Emax_valid --refs` shows the declaration and a comment line printed by `ParameterUpdate.mac:25` only. The energy checks test the literals 100 and 120 (GEF.c:45124, 45139), and in batch mode (`If Bfilein Then`, 3850) the branch is empty: neither the `<W> … beyond validity limit of 100 MeV` nor the `<E> Energy of CN > 120 MeV is not supported.` text is printed and the run goes on.
- **Effect:** batch runs above 100 or 120 MeV run without a message: capture `edge-e_high_energy` (`EN` at 150 MeV; `Eabsgs` 155.9 MeV, `431BE8F2`): no warning in stdout. Only `Eabsgs < 0` (3869) and the alpha check (3835) end GEF.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:894` (no C), `fbline GEF.bas:3849-3874`; capture `m6-setup-edge-7/edge-e_high_energy`; reproduced by `run_corpus_test.cpp` and `run_console_test.cpp`.
- **Fidelity switch:** `fix_batch_energy_limit`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `check_energy` in `step_setup.cpp`
- **Owning milestone:** M6

### Q-056 A sequence file whose first line holds a second, blank-separated item is never finished

- **BASIC location:** `GEF.bas:2777-2778` (`Input #Ffilein,Fenhance_global`, `Line Input #Ffilein,C_Energy_Table`), `GEF.bas:2843-2844` (`Do Until EOF(Ffilein)`)
- **Mechanism:** after an `Input #` item that ends at a blank, libfb's `hSkipDelimiter` skips the blanks and puts the next byte back unless it is `,`, LF, CR LF or the end of file. For a first line such as `' original: …` (the item `'`, read as 0) or `6.9  9.8` that byte stays in the put-back buffer: `EOF(f)` counts it as unread, `Line Input` ignores it, so once the data is used up `EOF` stays 0 and every `Line Input` returns "" (GEF.c:38706-38714): the `Do Until EOF` loop never ends. A first line with one item (`5`, or `'ab` without a blank) does not hang. The same put-back can make the energy line read as "".
- **Effect:** GEF hangs while parsing the file. Corpus inputs `wrkdir/in/Espectrum.in` (13 blanks, then `'   E/MeV   spin   weight`), `Jeremi.in` (`' original: 238U_9Be.in`) and `filefitall.in` (`'Full file name: filefitALL.in`, a `file.in` list used as a sequence file) time out (exit −1 in `m6-setup-corpus`; gdb: `fb_DevFileReadLine` at GEF.bas:2844). Capture `edge-h_energy_line_lost` shows the lost energy line.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:2843-2844`; driver golden `m6-strings` (`hang.txt`: inputs `quote` and `number` end, `quote_noeol`, `blank_first` and `number_noeol` hang, with fbc 1.10.1's runtime); `hSkipDelimiter` as ported in `Cpp_implementation/src/fbrt/input.cpp` (`InputFile::skip_delimiter`); captures `m6-setup-corpus` (the three inputs above), `m6-setup-edge-7/edge-h_energy_line_lost`; M6.0/M6.1 notes in `MILESTONE_6_PLAN.md` §9. Reproduced by `run_input_test.cpp` (four hang parses) and the run end of `run_driver_test.cpp`/`run_corpus_test.cpp`.
- **Fidelity switch:** none planned (as Q-035): the C++ throws `gef::params::GefHangs` when the data is used up while `EOF` stays false (`fb::InputFile::data_at_end`).
- **C++ symbol:** `read_sequence_lines` in `input_files.cpp` (via `gef::run::read_sequence_file`); `gef::fb::InputFile`
- **Owning milestone:** M6

### Q-057 `Options(PLOT)` in a batch run waits for console input after the first pass

- **BASIC location:** `GEF.bas:15506-15524` (`Input " ",Icontinue` at 15522; 15512 at the nominal pass of the last step)
- **Mechanism:** outside fit mode, with `Bplot` set by `Options(PLOT)`, every pass ends with the plotting code and a console `Input` (GEF.c:210004-210008 `fb_ConsoleInput`, 191188-191192 for 15512), also in batch mode. With stdin at EOF the console `Input` does not return (`fb_ConReadLine` waits for ever).
- **Effect:** an unattended batch run with `PLOT` stops after its first pass. Full runs `m6-full-plot` (`Options(PLOT)` and `Options(PLOT, ERR)`) hang there (gdb in `fb_ConReadLine`); `Bplot` survives the per-file reset (Q-050), so `PLOT` in one file affects every later file.
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:15512`, `fbline GEF.bas:15522`; full runs `m6-full-plot/edge-e_plot`, `edge-e_plot_err` (exit −1); the setup-only runs of the same inputs (`m6-setup-edge-7`) end normally, since they skip the passes; reproduced by `run_driver_test.cpp` and `run_console_test.cpp` (the run end and the text before it).
- **Fidelity switch:** none planned (a hang): the C++ throws `gef::params::GefHangs` from `RunDriver::end_pass`. Plotting itself is not ported (vision §3).
- **C++ symbol:** `gef::run::RunDriver::end_pass` (`driver.cpp`)
- **Owning milestone:** M6

### Q-058 A `file.in` that names no sequence file waits for a key for ever

- **BASIC location:** `GEF.bas:3129-3132` (`Bfilein = 0`), `GEF.bas:15618-15631` (key loop)
- **Mechanism:** when `file.in` lists no sequence file (`Nfilein = 0`), the `Else` branch clears `Bfilein` (GEF.c:40508). At the end of the run `If Bfilein Then kin = "Q" Else Do … kin = Inkey … If kin <> "" Then Exit Do : Sleep 1,1 : Loop` (GEF.c:229241-229312); with stdin at EOF `Inkey` returns "" every time.
- **Effect:** GEF prints `No file with input data specified in file.in.` and never ends. Captures `edge-l_empty` (a comment only) and `edge-l_fit_only` (`FIT` and `NITER(1)` only): exit −1 (timeout).
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:3129-3132`, `fbline GEF.bas:15615-15631`; captures `m6-setup-edge-7/edge-l_empty`, `edge-l_fit_only`; reproduced by `run_driver_test.cpp` (run end) and `run_console_test.cpp`.
- **Fidelity switch:** none planned (a hang): the C++ throws `gef::params::GefHangs` from `RunDriver::finish`.
- **C++ symbol:** `gef::run::RunDriver::finish` (`driver.cpp`)
- **Owning milestone:** M6

### Q-059 An empty energy line makes GEF read `Energy_Table(1)` and `Spin_Table(1)` past `Redim (0)`

- **BASIC location:** `GEF.bas:2824-2825` (`En_min = Energy_Table(1)`, `En_max = Energy_Table(N_E_values)`), the step schedule `GEF.bas:3454-3456` (`IS`: `Energy_Table(1)`, `Spin_Table(1)`), `3462` (single-energy ENDF), `3495` (`FC`, `IS`, `ES`, `EM`)
- **Mechanism:** an empty energy line (or `k:` with nothing after it) gives `N_E_values` 0, `Redim Energy_Table(0)` and `Redim Spin_Table(0)` (2795-2796). GEF.bas:2824 then reads element 1 (GEF.c:38661 `*(float*)(… + 4ll)`), past the array, without `-exx`; the single-step schedule reads `Energy_Table(1)` the same way (`FC`, `IS`, `ES`, `EM`: 3455, 3495; an ENDF `EN` line, which gets `N_E_steps` 1 at 3241-3252: 3462), and `IS` also `Spin_Table(1)` (3456). libfb allocates with `calloc`, and the 4 bytes after the one element lie inside the cleared chunk, so the reads give +0.0F.
- **Effect:** the run goes on at 0 MeV instead of reporting the missing energy: captures `edge-e_energy_empty`, `edge-e_energy_k_empty` (P0 `En_min`, `En_max` 0), `edge-e_fc_energy_empty`, `edge-e_endf_energy_empty` (P1 `P_E_exc` 0), `edge-e_is_energy_empty` (P1 `E_EXC_TRUE` 0 and `P_I_rms_CN` 0; `P_E_exc` is the isomer energy 0.0486, `3D473040`).
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:2795-2803`, `fbline GEF.bas:2824`, `fbline GEF.bas:3459-3497`; the captures above (`m6-setup-edge-7`); reproduced by `run_input_test.cpp` (P0) and `run_corpus_test.cpp` (P1). Reads further past the element are not modelled.
- **Fidelity switch:** `fix_empty_energy_line`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `read_energy_table` in `input_files.cpp`; `energy_table_at`, `spin_table_at` in `driver.cpp` (element 1 of a `(0)` table reads +0.0F, any other index outside the bounds throws `std::out_of_range`)
- **Owning milestone:** M6

### Q-060 `FileExists` does not convert backslashes, `Open` does

- **BASIC location:** `GEF.bas:2775` (sequence file, opened at 2776), `GEF.bas:2782`, `3094` and `3619` (spectrum files, opened at 3625)
- **Mechanism:** on Linux, libfb's `fb_DevFileOpen` passes the name through `fb_hConvertPath`, which turns `\` into `/`; `fb_FileExists` opens the name as given (`fopen(name, "r")`). GEF is a Windows program (its own output names are `out\GEF_….dat`), so a name written with a backslash fails the `Fileexists` test although `Open` would find the file.
- **Effect:** a sequence or spectrum file named with a backslash is reported missing, on Linux only: capture `edge-f_backslash_name` (`file.in` line `in\e_gs.in`: `<S> File in\e_gs.in not found.`), `edge-f_spectrum_backslash` (`<S> File in\e_spectrum2.dat does not exist.`, then `End`). GEF's own output names (`Cfileout_full` = `out\GEF_….dat`) are opened, not tested, so they work.
- **Evidence status:** *confirmed in output*
- **Evidence:** fbc 1.10.1 runtime checked directly (M6.1: a probe program with both calls on a backslash name); captures `m6-setup-edge-7/edge-f_backslash_name`, `edge-f_spectrum_backslash`; reproduced by `run_input_test.cpp` (P0 parses and their `End`), the `WorkDir` cases of `run_input_test.cpp`, and `run_corpus_test.cpp`.
- **Fidelity switch:** `fix_file_exists_backslash`; the C++ has no `Fidelity` configuration yet
- **C++ symbol:** `gef::run::WorkDir::exists` (no conversion) and `WorkDir::read` (converts), `Cpp_implementation/src/run/workdir.cpp`
- **Owning milestone:** M6

### Q-061 `Zmean`/`Zshift` are indexed beyond 350 for A_CN > 360

- **BASIC location:** `GEF.bas:5879-5991` (the Z(A) loops `For I_short = 10 To I_A_CN - 10`, writes `Zmean(m,k,I_short)`, `Zmean(m,k',I_A_CN - I_short)` and the same for `Zshift`); arrays `ReDim Shared Zmean(0 To 5,1 To 2,350)` (1109), `Zshift(…)` (1121); `U_Valid` (15818-15824)
- **Mechanism:** the loops run up to `I_A_CN - 10` and the C indexes the descriptors without a bound check (GEF.c:59938-60306, e.g. 59944 `… + I_A_CN$) - I_SHORT$0) << 2 …`). `U_Valid` admits A/Z up to 289/90, so a CN up to A 385 at Z 120 (A > 360 from Z 113 on). From A_CN 361 the writes of modes 0-4 and of `(5,1,·)` land in other rows of the same array (linear index (m·2 + k − 1)·351 + i), those of `(5,2,≥351)` past the end of the allocation (heap corruption).
- **Effect:** capture `m7-q061-z120a385` (Z 120, A 385, `GS`, binary `seed-probes-9ddf9e1b6099`): BASIC prints the builder's `Beta_Equi` message, writes P3 for the bin, then the event loop warns `Estimated TKEmin > Qvalue … Z_heavy = -9223372036854775808` and the process dies with SIGSEGV (exit −11). No corpus input comes near: the largest A_CN of the M7 captures is 270 (Ds-270). Later blocks index other `(·,·,350)` arrays (`Temp`, `TempFF`, `Eshell`, `PEOZ`, `PEON`, `EPART`) by A the same way (M7.2-M7.4).
- **Evidence status:** *confirmed in output*
- **Evidence:** `fbline GEF.bas:5884-5887`, `fbline GEF.bas:15818-15824`; capture `m7-q061-z120a385` (`run.json` exit −11, `stdout.log`, P3); the M7.0 D6 sweep lists accepted CN up to A 385 (`m7-d6-sweep/out_dneck1_v2.txt`); `tables: a CN with A above 360 stops at the bound of Zmean and Zshift` (A 360 runs, A 361 and 385 throw).
- **Fidelity switch:** none. Undefined behaviour is not reproduced (as Q-039, Q-053): the C++ throws `std::out_of_range` at the start of the Z(A) loops when `I_A_CN - 10 > 350` (the bin would always reach the writes past the end of `Zmean`). Open for the user's decision (M7.1 completion notes): emulate the in-array aliasing and the heap layout, as Q-042 does for reads.
- **C++ symbol:** `gef::tables::mode_centres_and_deformations` (`mean_z`, `Cpp_implementation/src/tables/deformations.cpp`)
- **Owning milestone:** M7

## 5. Build notes (not GEF quirks)

These describe how the toolchain, not GEF, can make the C++ results differ from the reference binary. They have no fidelity switch.

### B-001 Optimisation level versus fbc's `-O0`

- **Source:** `manifests/toolchain.txt` `[fbc -v backend capture]`: fbc compiles the generated C with `gcc … -O0 …`. `MILESTONE_0_PLAN.md` §2 (note on optimisation level) and §7 (risk table).
- **Issue:** the exact-mode C++ build does not fix the optimisation level. With SSE, round-to-nearest and FMA contraction off, IEEE results should not depend on it, except where GCC constant-folds or inlines libm calls differently.
- **Status:** open risk, measured per function by the M3/M5 T1 bit-exact tests, which run in `release-exact` (`-O3`) as well. Fallback: compile the affected translation units at `-O0`.
- **Finding 1 (M3.3, 2026-10-08):** `fb::fix` written as libfb computes it, `trunc(|x|) * sgn(x)`, differs at `-O3` for NaN inputs. Without `-fsignaling-nans`, gcc folds the multiplication by −1 into a negation, which keeps the NaN's sign and does not quiet a signalling NaN; libfb (and our `-O0` builds) return `|x|` quieted. Fixed in the source rather than by flags: `fix` handles NaN with explicit bit operations and the other cases with `t`/`-t`/`0`, which no optimisation can change. Lesson for later ports: a multiplication by a literal −1 (or by a sign) can lose its NaN behaviour at `-O3`.
- **Finding 2 (M3.4, 2026-10-08):** across all libm intrinsics GEF uses and GEF's own maths helpers, every remaining difference between the C++ builds and the fbc-compiled drivers is a NaN result whose sign or payload differs; no non-NaN value differs in any preset. Examples: g++ expands `std::floor(float)` inline even in Debug, where fbc's C calls glibc `floorf`, which quiets a signalling NaN; clang rewrites `-a + 1` as `1 - a`, which keeps the NaN's sign; gcc `-O3` does the same inside `Erfc` and inlines `floor(double)`. IEEE 754 leaves the sign of most NaN results unspecified, so compilers may do this. **Decision (user, 2026-10-08): bit-exact comparisons treat every NaN as equal to every NaN.** The M3.4 drivers hash NaN results as the canonical NaN, and the tests accept any NaN where the driver printed one. A NaN that reaches a GEF output file would still show up in `compare.exact` (`nan` vs `-nan`). (`fb::fix`, written before this decision, reproduces libfb's NaN bits anyway.)
- **Finding 3 (M5, 2026-10-13):** no difference between `release-exact` (`-O3`) and the Debug presets in any physics test (61 test cases, about 14.8 million comparisons each), so no translation unit needs `-O0`.
- **Owning milestone:** M3, M5 (done)

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
- **Status:** confirmed by fbc C and by a run: driver `arith_rules.bas`, golden `m3-arith-rules`, reproduced bit for bit by `fbc_arithmetic_test.cpp` in `dev-gcc`, `dev-clang` and `release-exact`. Coding rule unchanged: port arithmetic from the `fbline` output, not from the BASIC text (coding standards §5). **M5 (2026-10-13):** all physics functions ported from the `fbline` output are bit-exact on their grids and every logged call in the three presets; the shapes met there (folded constants such as `0.08*(Z²/A^⅓ + E) − 93`, `1.7*(4 − d)` → `−d*1.7 + 6.8`, literal multipliers moved behind `/`) are covered by the rules. One review finding was a comparison polarity (`EVEN_ODD`'s `If Abs(x) < 1E-3` compiled as `if (... >= 1E-3) goto`), which differs only for NaN: port each comparison in the polarity the C tests.
- **Owning milestone:** M3 (rules), M5 (done)

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
| Q-018 | `MyParameters.dat` never applied; `Fitpar.dat` reset per system | `GEF.bas:1017, 2555, 3317-3321` | confirmed in output | `fix_parameter_file_overrides` | M15 (reset: M6) |
| Q-019 | `Var_PZ_S3_olap_curv` is zero | `GEF.bas:2610` | confirmed in output | `fix_pz_s3_olap_curv_width` | M12 |
| Q-020 | Analyzer registry naming errors | `Spectra.bas:557-577, 1082-1096` | confirmed in output | `fix_analyzer_registry_names` | M4 |
| Q-021 | `I_MAT_ENDF` persists `ctl/IMATmax.ctl` | `NucProp_Functions.mac:11-63` | confirmed in output | `fix_imat_no_persistent_state` | M4 (in-process state: M6; file on disk: M13/M14) |
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
| Q-032 | Stock `NucPropNUBASE2020.bas` stops GEF while loading | `NucPropNUBASE2020.bas:56-98` | confirmed in output | — | M4 |
| Q-033 | Loader errors say "GEF stopped." but continue | `NucPropJEFF33.bas:77-82`, `Branchings.bas:76-80` | confirmed by fbc C | `fix_loader_error_stop` | M4 |
| Q-034 | JEFF-3.1.1 table 9 records shorter than `N_MAT_MAX` | `NucPropJEFF311.bas:47-57, 90, 94` | confirmed in output | — | M4 |
| Q-035 | Unterminated `/'` in a parameter file hangs GEF | `ReadParameters.mac:1-8` | confirmed in output | — | M4 |
| Q-036 | Legacy NucProp files map missing nuclides to the last entry | `NucPropx.bas:157-188` (and mf, f) | confirmed in output | — | M4 |
| Q-037 | BFTF RF has no value at RX = 30 | `GEF.bas:17679-17690` | confirmed by fbc C | `fix_bftf_rx30_hole` | M5 |
| Q-038 | E2 cascade stops before its first gamma when a state has spin CInt(J_frag) | `GEF.bas:9330-9333, 9447-9450` | confirmed in output | `fix_e2_ground_state_stop` | M5, M10 |
| Q-039 | `Array_Eg2_*(100)` written without a bound | `GEF.bas:9353, 9469` | confirmed by fbc C | — | M5 |
| Q-040 | TRusanov computes a pairing floor and does not use it | `GEF.bas:16100-16107` | confirmed by fbc C | `fix_trusanov_pairing_floor` | M5 |
| Q-041 | Beta_Equi prints to whatever file number `f` holds | `GEF.bas:16628` | confirmed in output (condition, M7.0); read only (destination when `f` <> 0) | — | M5, M7/M13 |
| Q-042 | Mass-table reads past the bounds read the neighbouring table | `GEF.bas:1222-1266` and readers | confirmed in output | `fix_table_overrun` | M6.4 |
| Q-043 | `E/spin` check reads a stale `Emode` | `GEF.bas:2801` | confirmed in output | `fix_espin_check_channel` | M6 |
| Q-044 | Two-system line energy ignored | `GEF.bas:3150, 3304, 3449-3497` | confirmed in output | `fix_two_system_energy` | M6 |
| Q-045 | Single-step channels run `Energy_table(1)`, named by `En_max` | `GEF.bas:3217, 3225, 3412-3422, 3495` | confirmed in output | `fix_single_step_energy` | M6 |
| Q-046 | Spectrum-file line keeps an earlier energy table | `GEF.bas:2780-2787` and readers | confirmed in output | `fix_spectrum_line_energy_table` | M6 |
| Q-047 | Spectrum normalised 0/0, and at every step | `GEF.bas:2671, 3682-3689` | confirmed in output | `fix_spectrum_normalisation` | M6 |
| Q-048 | `done.ctl` key: no channel, `Fenhance` as `Single` | `GEF.bas:3174-3217` | confirmed in output | `fix_done_key` | M6 |
| Q-049 | Missing isomer restarts the input, possibly for ever | `GEF.bas:3563-3567` | confirmed in output | `fix_missing_isomer_skip` | M6 |
| Q-050 | Per-file reset keeps most options, clears `FIT`'s `B_Error_On` | `GEF.bas:2829-2842` | confirmed in output | `fix_per_file_option_reset` | M6 |
| Q-051 | `B_Error_On`/`B_ENDF` carry over between system lines | `GEF.bas:3268-3275, 3459-3490` | confirmed in output | `fix_per_line_error_flags` | M6 |
| Q-052 | `DPARFAC` effective only from the next round | `GEF.bas:2888-2892, 2575-2620` | confirmed in output | `fix_dparfac_widths` | M6, M16 |
| Q-053 | `S_par(5000)` filled without a bound | `GEF.bas:3050, 3057, 3087` | confirmed in output | — | M6 |
| Q-054 | `ES`/`EM` steps read stale `Spin_CN` and `Eabsgs` | `GEF.bas:3698-3843, 3869` | confirmed in output | `fix_spectrum_step_spin_energy` | M6, M9 |
| Q-055 | No energy limit in batch mode; `Emax_valid` unread | `GEF.bas:894, 3849-3868` | confirmed in output | `fix_batch_energy_limit` | M6 |
| Q-056 | A second blank-separated item on a sequence file's first line hangs GEF | `GEF.bas:2777, 2843-2844` | confirmed in output | — | M6 |
| Q-057 | `Options(PLOT)` in batch waits for console input | `GEF.bas:15512, 15522` | confirmed in output | — | M6 |
| Q-058 | `file.in` without a sequence file waits for a key | `GEF.bas:3130, 15618-15631` | confirmed in output | — | M6 |
| Q-059 | Empty energy line reads `Energy_Table(1)` past `Redim (0)` | `GEF.bas:2824, 3455, 3462, 3495` | confirmed in output | `fix_empty_energy_line` | M6 |
| Q-060 | `FileExists` does not convert backslashes, `Open` does | `GEF.bas:2775, 2782, 3094, 3619` | confirmed in output | `fix_file_exists_backslash` | M6 |
| Q-061 | `Zmean`/`Zshift` indexed beyond 350 for A_CN > 360 | `GEF.bas:5879-5991` | confirmed in output | — | M7 |
| B-001 | Optimisation level vs fbc `-O0` | (toolchain) | open risk | — | M3, M5 |
| B-002 | fbc gcc passes `-fwrapv -fno-strict-aliasing` | (toolchain) | resolved for the runtime layer (M3.3) | — | M3 |
| B-003 | `Compilationstamp` needs `SOURCE_DATE_EPOCH` | `GEF.bas:17` | handled (M1) | — | M1 |
| B-004 | fbc reassociates `*`/`+` chains, literals last | `GEF.bas:2608, 2610` | confirmed by fbc C and run | — | M3, M5 |
