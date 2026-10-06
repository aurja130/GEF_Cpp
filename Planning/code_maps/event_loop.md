# Code map: Event loop

> Saved verbatim from the planning-session report `EventLoopScout` (agent output, 2026-10-06), source commit `ba9f0aa`. Corrections made after the report was written are listed in `README.md` in this directory; the text below is unedited.

## Summary

I mapped the Monte Carlo event loop (GEF.bas:7920-9997) into 15 stages, plus the per-event subroutines (Eva, u_accel, P_Egamma_low/high, U_Ired*, EVEN_ODD), the samplers and the post-loop isomer population (14236-14300). For each piece I give line ranges, approximate LOC, the data contract, random-number use, the histograms it fills, FreeBASIC hazards and a test seam. The full component table is in `report`. Everything was found by reading code and fbc sources; nothing was run.

Findings that change the porting plan:
1. **Heavy-fragment E1 gammas are missing from the total gamma spectrum.** At 9417, `Egamma(Nspectrum) = Egamma(Nspectrum) + 1` assigns to the read-accessor function `EGamma` (Spectra.bas:1505), not to an array. FB parses it as a call with a boolean argument, so it does nothing. The validation data confirms it: the low-energy bins of Egamma equal EgammaL exactly (validation/test_run/dmp/Z86_A215_n_E2.53e-08MeV/Egamma.dmp:15 vs :432). By the same mechanism `ENsci(..) = ..` at 8129/8152 is a no-op [INFERENCE: consistent with the empty ENsci section in E30MeV/EN.dmp:95-104, though that energy may also simply have no saddle-to-scission emission].
2. **The J_attempt retry counts some histograms twice.** It jumps back after Acc_JFRAGpre and Acc_AQpre/Qvalues have already been filled (8676-8728).
3. **The FreeBASIC Rnd algorithm is confirmed identical in fbc 1.05.0 and current master; the reference CI builds with fbc 1.10.0.** `Randomize s,3` sets state[0]=(uint32)s, then state[i]=state[i-1]*1664525+1013904223 for i=1..623 (mod 2^32). The index starts at 624, so the first call does a standard MT19937 twist. Output uses standard MT tempering, and Rnd = u32/4294967296.0 as a Double in [0, 1-2^-32]. Bare `Randomize ,3` uses seed = lo32 XOR hi32 of the Double returned by Timer.
4. **Float semantics, verified in fbc's compiler source:**
   - `/` always converts integer operands to Double, so even a Single divided by an Integer is computed in Double.
   - `var^2`, where the operand is a plain variable or array element, is rewritten to `var*var` in the variable's own type (Single). Any other `^` calls pow(double).
   - Sqr, Log, Exp and Int of a Single compile to sqrtf/logf/expf/floorf. Of an Integer they use the double versions.
   - Float-to-integer conversion uses nearbyint (round half to even).
   - So the earlier report's statement that `^` is evaluated in Double is only partly true.
5. **Random-number use per event depends on the data almost everywhere.**
   - About 12 rejection loops, plus the cached second value of PGauss.
   - The TXE_shift draw only happens when Z_CN and the light fragment's Z are both even.
   - The lmd option adds draws, so the random stream differs between lmd and non-lmd runs.
   - There is one global stream from Randomize (1553) through the pre-pass, the 48 PGauss calls per perturbed pass, and every event loop.
   - For seeded-trajectory (T3) tests: patch the reference harness to reseed per pass or per event and to reset PGauss's cached state, log every draw by replacing Rnd textually, and test stages by replaying recorded draws.

## Architecture

For each (I_E_distr, I_N_Multi, I_Z_Multi, I_E_Multi) channel with NEVTused>0 (5522-5569), the deterministic per-nucleus tables are rebuilt (5619-7919; no Rnd calls there, grep-verified). Then `For ILoop = 1 To NEVTused` (7922-9997) runs one fission event straight through, with no subroutine boundary:

mode → A/Z (DiceA) → even-odd integer Z/N at saddle + Q_sad → optional saddle-to-scission evaporation (Eva Ilh=0) → deformation energy → intrinsic energy and energy division (Repeat_E_Q is dead) → Q_sci and pre-neutron yields → collective energy → spins (J_attempt) → TKE and pre-neutron kinematics → TKEsci → light-fragment Eva + neutron kinematics → heavy-fragment Eva + post-neutron yields and kinematics → prompt gammas (E1 statistical + E2 cascade with isomer stop) → pre-saddle multiplicities and bookkeeping → optional lmd record → IEVTtot++.

State is module-level Shared Single scalars, plus Shared arrays for per-event neutron/gamma lists, plus Double histograms in Spectra.bas. Every histogram is filled inline. After the loop, the results/dmp code reads the histograms, and the isomer block (14236-14300) turns the post-neutron spin distribution JFRAGpost into Isotab.R_Prob, which ENDF.bas and Branchings.bas consume.

Random numbers: one global FB Mersenne Twister stream plus PGauss's static cached value. The stream continues across the pre-pass, the parameter perturbation, all passes, energies and systems.

C++ seams: an Event struct passed through stage functions, each stage taking an `Rng&`; a Histograms object with FB-exact bin rounding and growable bounds; an isomer post-processor.

## Files

### `Reference/GEF_code/source/GEF.bas`

Event loop 7920-9997 (stages listed in report); energy/multi-chance loop headers 5504-5616 (Escission_lim 5616, NEVTused 5569); E_coll_saddle/E_tunn setup 7177-7213; lmd column flags 2221-2237/2923-2962; lmd open 4819-4821; Randomize 1553; isomer population 14211-14300; mode-yield printout 12340-12351; dmp writers 14884-15460; Eva 16650-16905; u_accel 16907-16960; P_Egamma_low 16962-17054; P_Egamma_high 17056-17092; U_Ired/U_IredFF/U_I_Shell 17094-17171; GDR helpers 17439-17477; EVEN_ODD 17593-17643; Gaussintegral 17808; samplers 17877-18051

### `Reference/GEF_code/source/Spectra.bas`

Histogram arrays and their accessors. Each `_X` array has a Function X(...) reader and a Sub Acc_X(...) accumulator that extends the array on out-of-range writes. Because X is a function, writing `X(i) = X(i) + 1` does nothing (this is the source of the Egamma/ENsci losses). Acc_JFRAGpost 406-428 takes an Integer spin parameter, so the Single J_Frag is rounded half-to-even. Acc_EGamma 1513-1522

### `Reference/GEF_code/source/utilities.bi`

Min/Max on Single (17-35; `If R1 > R2`, so NaN handling is asymmetric); Erf/Erfc (Numerical Recipes, Double internally); Extend_* used by the Acc_* growth logic

### `Reference/GEF_code/source/NucPropJEFF33.bas`

Isotab construction, 133-171. States sorted by spin, R_lim spin-window limits, last limit = 1e3. Used by the gamma-cascade isomer stop and the post-loop isomer population

### `Reference/GEF_code/source/NucProp_Functions.mac`

I_MAT_ENDF (11-62): linear scan of NucTab, called twice per event. For nuclides not in the table it does file I/O on ctl/IMATmax.ctl on every call. N_ISO_MAT 65-83, ISO_for_MAT 99-107

### `https://raw.githubusercontent.com/freebasic/fbc/master/src/rtlib/math_rnd.c`

FB Rnd/Randomize: MTWIST init via hRnd_FillFAST32 (LCG), twist and tempering, Rnd=u32/2^32, Timer-based seed when seed=-1. Same algorithm as the 1.05.0 version (https://raw.githubusercontent.com/freebasic/fbc/1.05.0/src/rtlib/math_rnd.c)

### `https://raw.githubusercontent.com/freebasic/fbc/master/src/rtlib/fb_math.h`

FBRNDFAST32 = x*1664525+1013904223; FB_RND_MAX_STATE=624; hRnd_FillFAST32 (lines 38-47)

### `https://raw.githubusercontent.com/freebasic/fbc/master/src/compiler/ast-node-bop.bas`

Type rules: `/` promotes integer operands to Double (1129-1145); pow promotes to Double (1168-1176); `var^2` becomes var*var in the variable's type (1490-1520); mixed types use typeMax (1188-1215)

### `https://raw.githubusercontent.com/freebasic/fbc/master/src/compiler/ir-hlc.bas`

C backend: Single operands map to __builtin_sqrtf/logf/expf/floorf (2335-2343); float-to-int uses __builtin_nearbyint[f] (1252-1258)

### `validation/test_run/dmp/Z86_A215_n_E2.53e-08MeV/Egamma.dmp`

Evidence that heavy-fragment E1 gammas are absent from Egamma: line 15 (Egamma) is identical to line 432 (EgammaL), while EgammaH (line 733) has similar but different counts

### `Reference/GEF_code/.nea/.gitlab-ci.yml`

The reference binary is a static build made with the FreeBASIC 1.10.0 docker image (lines 29, 45)

## Report

# Event-loop slice: component decomposition for porting and differential testing

Line numbers refer to Reference/GEF_code/source/GEF.bas unless another file is named. LOC means logic lines, excluding comments and prints.

Abbreviations used below:
- **FBX** = FreeBASIC hazard.
- **Seam** = where BASIC and C++ can be compared, and how.
- **draws** = Rnd calls.
- **PG** = one PGauss call. PGauss uses a polar Box–Muller method with a Static cache (ISet/GSet). The 1st, 3rd, 5th, … call overall consumes 2 Rnd per attempt, with acceptance π/4. The 2nd, 4th, … call consumes 0 Rnd and returns the cached value. This parity is global state.

## A. FreeBASIC runtime facts this slice depends on (verified in fbc sources)

### A1. Rnd and Randomize
Verified in fbc master and 1.05.0 `src/rtlib/math_rnd.c`, and master `fb_math.h`. CI builds with fbc 1.10.0 (`.nea/.gitlab-ci.yml:29`).

**`Randomize seed, 3`** selects FB_RND_MTWIST and seeds as follows:
- `s = (uint32_t)seed`.
- `state[0] = s`.
- `state[i] = state[i-1]*1664525u + 1013904223u` for i = 1..623, mod 2^32. This is an LCG fill, not `init_genrand`.
- `index = 624`, so the first draw regenerates the whole state.

**Twist** (standard MT19937, constants as in fbc):
- For i in 0..226: `v = (st[i] & 0x80000000) | (st[i+1] & 0x7FFFFFFF)`; `st[i] = st[i+397] ^ (v>>1) ^ (v&1 ? 0x9908B0DF : 0)`.
- For i in 227..622: the same, but with `st[i+397-624]`.
- Element 623 pairs `st[623]` with `st[0]` and xors `st[396]`.

**Tempering:**
- `v ^= v>>11`
- `v ^= (v<<7) & 0x9D2C5680`
- `v ^= (v<<15) & 0xEFC60000`
- `v ^= v>>18`

**Output and seeding details:**
- `Rnd = (double)v / 4294967296.0`. It can return exactly 0.0 and never 1.0.
- `Rnd(0)` returns the last value; GEF never calls it that way.
- `Randomize ,3` (line 1553): the seed defaults to -1.0, which is replaced by `(double)(lo32 XOR hi32)` of the Double returned by `fb_Timer()`. The run is therefore not reproducible.
- 1553 is the only Randomize call. It runs again only on GoTo StartAgain.

**Consequences of storing Rnd in a Single:**
- Many call sites assign Rnd to a Single (e.g. `R_Choice` at 7930, `X1` in PExp at 18010).
- Values ≥ 1 − 2^-25 round to 1.0f.
  - Mode choice: R_Choice = 1.0f falls through to the default I_Mode = 7.
  - PExp rejects X1 ≥ 0.99999.

### A2. Arithmetic and type rules (fbc compiler)

**Division:** `/` always converts integer operands to Double (`ast-node-bop.bas:1129-1145`).
- `TKE*I_A_heavy_sci/I_A_sci`: Single × Integer stays Single; dividing by an Integer gives a Double; the result is rounded to Single on assignment.
- `I_A_light_sci/I_A_sci` (8391, 8392, 8497-8498) is evaluated in Double. In C++, int/int would truncate to 0.

**Powers:**
- When the left operand of `^2` is a plain variable or array element (VAR/IDX/FIELD/DEREF), the expression is rewritten to `x*x` in x's own type (`ast-node-bop.bas:1490-1520`). Examples: `v_N^2`, `V1^2` (Single math), `vn0^2`.
- Any other `^` is `pow(double,double)`, with the result as Double. Examples: `(Array_v_F1_CN(I)+v_N_long)^2`, `I_A_light_sci^0.33333`, `(Jfrag+1)^2`.

**Math functions:** Sqr, Log, Exp, Int and Abs of a Single compile to `__builtin_sqrtf/logf/expf/floorf/fabsf` (`ast-node-uop.bas:249-257`, `ir-hlc.bas:2335-2343`). On an Integer or Double operand they use the double versions.
- Bit-exact T3 therefore needs the same glibc expf/logf/powf/pow/exp/log as the static reference binary. These functions are not correctly rounded, and musl or MSVC results can differ.

**Float to integer:** conversion uses `__builtin_nearbyint[f]`, i.e. round half to even. This applies to CInt, implicit assignment, Single used as an array index, and a Single passed to an Integer parameter.
- `Int()` is floor; `Fix()` truncates.
- `\` first rounds float operands to integers, then divides with truncation.

**Literals:** floating literals without a suffix are Double, so `Single op 0.5` is evaluated in Double [INFERENCE from FB docs; no Single demotion found in ast-node-bop].

**Mixed Single and Integer** under `+`, `-`, `*` uses typeMax, which gives Single [INFERENCE: rank Single > LongInt].

**Compiler flags:** -gen gcc on x86-64 with SSE math and no FMA by default [INFERENCE about the fbc gcc flags]. The C++ build must use `-ffp-contract=off`, no `-ffast-math`, and no `-march` with FMA.

**Parameter passing:** in -lang fb, scalars are passed ByVal by default. Integer actual arguments passed to Single parameters (Eva, LyMass, U_Ired) convert exactly.

**`Dim` inside the loop body** zero-initialises the variable each time execution passes through it, e.g. TXE_shift at 8415/8473, so TXE_shift = 0 whenever the Rnd branch is not taken. GoTo targets placed after a Dim keep the variable's value.

## B. Data inputs the event loop consumes from setup (built before 7920)

| Kind | Items |
|---|---|
| Mode tables | `Yield_Mode_0..5,11,22`; `I_Mode_selected`; `AC_Mode_0..5`; `SigA_Mode_0..5,11,22`; `S2leftmod`, `P_A_Width_S2`, `R_slope_S2`; `SigPol_Mode_0..4`; `ZC_Mode_0/5` |
| Per-mode, per-fragment tables | `Zshift(0..5,2,A)`; `PEOZ/PEON(0..7,1..2,A)`; `EPART(0..7,1..2,A)`; `Temp/TempFF(0..5,1..2,A)`; `Edefo(-1..5,1..2,Z)`; `Beta(-1..7,1..2,Z)`; `SpinRMSNZ(0..7,1..2,N,Z)`; `E_coll_saddle(0..7)` |
| Scalars | `E_Exc_S0`, `E_diss_Scission`, `E_tunn`, `Escission_lim` (5616), `R_E_exc_GS`, `Racc` (7920, Single), `I_Z_CN`, `I_A_CN`, `I_N_CN` |
| Global parameters | `SIGDEFO(_0)`, `EexcSIGrel`, `SIGENECK`, `ECOLLFRAC`, `ESHIFTSASCI_coll`, `dneck`, `Tscale`, `Econd`, `Etrans` |
| Data tables | `DEFOtab`, `NucTab`, `Isotab`, the AME/BEexp tables |
| Multi-chance pre-pass | `I_N/Z/E/A_Multi`, `Imulti`, `En_multi_1..6`, `I_emit_1..6`, `J_multi_last` |
| lmd | `CFileoutlmd`, the `P*` column flags, `Emode`, `P_E_exc`, `Inofirst`, `B_Error_Analysis`, `Brec` |

**Suspicious inputs:**
- `E_tunn` at event time holds the value from the last iteration (S22) of the mode loop at 7182-7213, not the S0 value set at 6311.
- `Tlight`/`Theavy` (8305-8318) are assigned but never used afterwards (grep-verified).
- `TempFF` is passed to Eva as `T`, which Eva does not use.

## C. Components

### C0. Random-number core and samplers (17877-18051; ~110 LOC)

| Sampler | Lines | Draws | Used in |
|---|---|---|---|
| PGauss | 17956-17977 | see the PG note above | everywhere |
| PBox2 | 17886-17921 | 1 PG + 1 Rnd, +1 Rnd if Rbox<0, +1 Rnd in the steeper wing (wing reflection) | S2 mass, event loop |
| PLinGauss | 17979-17989 | `|PG|+|PG|` plus a shape correction | spins, event loop |
| PExp | 18006-18016 | X1 stored as Single; rejects X1 ≤ 1e-10 or ≥ 0.99999 | Eva |
| PMaxwellMod | 18038-18050 | 1 Rnd for the branch test `<3.3/sqrt(A)`, then 2 Rnd with Double logs | Eva and pre-pass |
| PMaxwell | 18019-18025 | Double internally | pre-pass only |
| PPower_Griffin_v | 17931-17943 | rejection loop | pre-pass only |
| PBox, PPower, PPower_Griffin_E, PMaxwellv | — | — | dead (no call sites; grep 1-15700) |

- **Precision.** V1 and V2 are Single. `R = V1*V1 + V2*V2` is computed in Single. `Fac = Sqr(-2.E0*logf(R)/R)` is computed in Double and stored as Single.
- **Order of evaluation.** The pairs `|PG|+|PG|` and `Log(Rnd)*Log(Rnd)` sit in single expressions, but both operations are commutative, so evaluation order does not change the result.
- **Edge case.** `Log(Rnd)` with Rnd = 0 gives −inf (probability 2^-32).
- **Seam (T2a).** A FreeBASIC driver that includes the sampler code, calls `Randomize s,3`, and dumps the raw Rnd values and the sampler outputs as hex. Replicate the PGauss call order. The C++ side needs an `FbRng` plus a `PGaussState` object; do not use a function-static.

### C1. Mode choice (7924-7954; ~25 LOC)
- **Input:** Yield_Mode_*, I_Mode_selected.
- **Draws:** 1 Rnd (stored as Single), or 0 when MODE(i) is set.
- **Output:** I_Mode (0-7).
- **Fills:** `Mode_Events(I_Mode)` and `Mode_Events(10)` (LongInt), printed in the out-file mode yields (12340-12351).
- **FBX:** the cumulative sums are Single; mode 7 is the fall-through default.
- **Seam:** a per-event probe of I_Mode; the mode-yield lines in the out file.

### C2. A and Z sampling (7956-8058; ~70 LOC)
- **Labels:** DiceA 7960. Next2 7974 is dead because its GoTo is commented out.
- **Mode cases:**
  - Modes 0, 1, 3, 4: `R_A_heavy = PG(AC,SigA)`; `RZ = R_A_heavy*Z/A + Zshift(mode,2,round(A))`; `R_Z_heavy = PG(RZ,SigPol)`.
  - Mode 2: PBox2 for A.
  - Mode 5: uses SigPol_Mode_4. If ZC_Mode_5 ≤ ZC_Mode_0, then `A = A_CN − PG`.
  - Modes 6 and 7: no Zshift.
- **Rejection (8028-8029):** GoTo DiceA if A_heavy < 1, A_light < 1, or A_heavy < A_light. For symmetric modes this rejects about half the attempts.
- **Draws:** 2 PG per attempt, plus the PBox2 extras.
- **Output:** R_A_heavy, R_Z_heavy, R_A_light, R_Z_light (Shared Single).
- **Fills:** ZPROV, ZMPROV (via CInt(Z)), APROV and AMPROV (8047-8054) → Aprov.dmp.
- **Flags:**
  - The APROV index is `CInt(R_Z*A_CN/Z_CN + 0.5)`: a +0.5 is added before rounding, which biases the bin.
  - The Zshift index is read before the range rejection, so an out-of-range index is possible (there is no bounds checking).
- **Seam:** a per-event probe of (I_Mode, R_A_heavy, R_Z_heavy); Aprov.dmp; stage replay with recorded draws.

### C3. Even-odd rounding, saddle nuclides and Q_sad (8060-8098; ~25 LOC)
- **Calls:** `EVEN_ODD(R, PEON/PEOZ(mode,2,round(A_heavy)))` (17593-17643, pure, ~25 LOC).
  - Its parameter R_EVEN_ODD is clamped by Min(·,1).
  - Floor = Int returns a Single.
  - Negative R_FLOOR Mod 2 = −1 takes the odd branch.
- **Light fragment:** obtained as the complement.
- **Q value:** `Qvalue_sad = AME2020(CN) − AME2020(heavy) − AME2020(light)`.
- **Intrinsic energies:** `E_intr_light/heavy = EPART(mode,1|2,A_sad)`.
- **Draws:** 0.
- **Seam:** EVEN_ODD can be tested T1 on a grid with a driver; the stage itself through a probe.

### C4. Saddle-to-scission evaporation (8099-8180; ~65 LOC)
- **Condition:** only runs if `E_intr_l + E_intr_h > Escission_lim`, where Escission_lim = 900·exp(−Z²/A/13), about 57-64 MeV for actinides. This is rare at low energy.
- **Calls:** `Eva(0, Z_sad, A_sad, E_intr, T=1, J=0, ..., E_FINAL = Escission_lim*A/A_sad − 9)` for each fragment. The `E_FINAL` input is used as Eva's E_MIN.
- **Output:** the I_*_sci nuclides (otherwise copied from _sad), new E_intr values, I_nu_ss, Array_En_sci, C_pattern_sci (lmd).
- **Fills:** NNsci(I_nu_ss). The `ENsci(...) = ...` writes at 8129/8152 are no-ops (see D1).
- **Draws:** data-dependent (Eva).
- **FBX:** `ReDim` of a local array every event; `Redim Preserve` of the global Array_En_sci.

### C5. Deformation energy (8183-8301; ~95 LOC)
- **Inputs:** RW_mac = Gaussintegral(E_Exc_S0 + E_diss − 20, 5); Edefo; Beta; SIGDEFO(_0); LyMass.
- **ESIGDEFO** = LyMass(β+δ) − LyMass(β).
- **TKEmin** (8254) uses exponents 0.33333 and 0.3333 (inconsistent; a quirk to preserve). If Q − TKEmin < 0, TKEmin = Q − 1 with a warning.
- **Edef clamps:** Edef1_mean and Edef2_mean are replaced by the Edefo(0) value if they exceed the limit.
- **Rejection:** `While Edef<0 or Edef > (Q−TKEmin)*A_other/A_sci: PG` (8288-8295). Each loop draws at least 1 PG.
- **Output:** Edef1, Edef2, Eexc_light/heavy (initial values), ESIGDEFO.
- **Fills:** Acc_Edefo2d (→ XE.dmp EdefoA, derived later).

### C6. Intrinsic excitation energy and energy division (8320-8578; ~170 LOC)

**Mode 0 (8334-8467):**
- Repeat_E_Q is dead: E_intr_*_S0_mac = Max(0, ·) can never be < 0 (8393-8401).
- 1 PG for the energy division, with Sigma ∝ E_tot·0.47·exp(−sqrt(·/160))/2.35.
- Shell and pairing via AME2020 − LDMass − 24/sqrt(A).
- TKE_mac (Wilkins) uses `Beta(0,·,I_Z_sci/2)`: a Double index rounded half-to-even, which is asymmetric for odd Z_sci. `(I_Z_sci/2)^2` is evaluated in Double.
- Delta_E_Q with `LYMass(I_Z_sci/2, ...)` (Single parameters, no rounding).
- The macroscopic and microscopic mixture is weighted by RW_mac.
- TXE_shift: `RND < PEOZ(mode,1,0.5*I_A_sci)` (8421). The index is a Double rounded half-to-even.
- Then 2 while-PG rejections for positivity.

**Other modes (8468-8540):**
- TXE_shift draw under the same condition.
- `While E<0: E = PG(mean,RS) − Lypair` (two loops).

**Draws:** 1 conditional Rnd, taken only if Z_CN is even and Z_light_sci is even. This is a data-dependent branch in the stream.

**Flags:**
- 8434: the light-fragment microscopic energy subtracts Lypair of the **heavy** fragment.
- 8504: the test is `If E_intr_heavy < 0` but the correction is applied to E_intr_heavy_mean.
- 8392 and 8497: `I_A_x_sci/I_A_sci` is Integer/Integer and evaluates in Double.

**Then (8554-8578):** Qvalue_sci (AME2020).

**Fills:** APRE, AMPRE, NZPRE (a **Single** array of counts), NPRE, NMPRE, Acc_ZISOPRE, Acc_Eintr2d (8582-8603) → Apre, Npre, ZApre, ZPolarpre, SigmaZpre and XE EintrA dumps.

### C7. Collective energy (8612-8668; ~25 LOC)
- `Ecoll_mean = ECOLLFRAC*(De_Saddle_Scission(Z_CN,A_CN) − E_tunn)`. This is deterministic per channel and could be hoisted out of the loop.
- Two `While <0` PG loops, each adding 0.5·E_coll_saddle(mode).
- **Fills:** Acc_Ecoll2d, Acc_EexcA2d.

### C8. Spins and TKE (8670-8835; ~120 LOC)
- **Labels:** J_attempt 8676.
- **Spins:** `J = PLinGauss(SpinRMSNZ(...)/sqr(2)) − 0.5`, clamped at 0.
  - Each PLinGauss call makes 2 PG calls, so 4 PG per attempt.
  - Modes 6 and 7 use the (1,2) and (2,2) tables.
- **Rotational energy:** `Erot = J(J+1)/(2·U_Ired)`, where U_Ired = 0.45·1.16²·A^1.6667/103.8415 (17094).
- **Energy balance:** TXE = Eexc + Erot; `E_total = Qvalue_sci + R_E_exc_GS`; TKE = E_total − TXE.
- **Negative TKE:** GoTo J_attempt while N_J_attempt ≤ 3. After that, TXE is rescaled and TKE = 1.
  - `Static Ntimes` counts these events globally across all systems; when it exceeds 99 the program executes `End` (8764).
- **Fills, and repeated on every retry (flag):** Acc_JFRAGpre (8692/8695), Acc_AQpre, Qvalues (8724-8728).
- **Fills after the retry loop:** EexcL2d/ErotL2d light/heavy (Single indices rounded), TotXE, Ekinpre/EkinpreM, Acc_AEkinpre, TKEpre/TKEpreM, Acc_ATKEpre → Ekin, Eexc, XE, Qvalues dumps.
- **Output:** TKE, TXElight/heavy, Ekinlight/heavy_sci, J_Frag_*, Erot*.

### C9. Pre-evaporation setup (8838-8886; ~20 LOC)
- Resets Ngtot, Nglight, Ngheavy and Egtot1000. Egtot1000 is Single.
- `TKEsci_mean = 0.4·De_Saddle_Scission(Z_CN,A_CN)` at 8861. The earlier assignment at 8332 is dead.
- TKEsci_again loop (8862-8869): `TKEsci = PG(mean, mean)` while < 0. It draws even though TKEsci is used only by u_accel.
- TempFF lookup. Eva receives it but ignores it.

### C10. Light-fragment evaporation and kinematics (8888-9042; ~85 LOC, excluding the commented IAEA block 8904-8946)
- Clears the shared per-fragment arrays (size 50) and Array_Eg0_light (size 100).
- Calls `Eva(1, ...)`. Post-neutron Z and N are CInt of the Single results.
- **Per neutron:**
  - u_accel if Tn ≤ 100, otherwise the final velocity.
  - `v_long = v·(2Rnd−1)` (1 draw).
  - CM-frame energy and angle.
  - `phi = Rnd·360` (1 draw).
  - So exactly 2 draws per neutron.
- **Fills:**
  - Ndirlight (Int(100·cos)), ENfrvar, Acc_ENfr (Int(E·1000)), Acc_ENfrC (bound-checked), ENM, ENlight, ENApre2d/ENApost2d (CInt(E·10)), Acc_ENApre2dfs/post2dfs, Acc_ENfrfs.
  - APOST, AMPOST, ZPOST, ZMPOST, NPOST, NMPOST, Acc_NZPOST(Racc) (9031), NNlight, N2dpost, N2dpre.
  - Mixed binning conventions: Int (floor) vs CInt (round half even).
  - These go to EN.dmp, NA.dmp, Apost.dmp, Zpost.dmp and Npost.dmp, and to NZPOST, which drives the out-file independent yields and ENDF MT454.
- **FBX:** `I_nu_light/heavy/fr` are declared Single (8848) but used as indices.

### C11. Heavy-fragment evaporation and post-neutron kinematics (9043-9230; ~140 LOC)
- Mirrors C10 with Eva(2, ...), ENheavy, NNheavy, NNfr. Acc_ENfrC has no I_N_Multi bound check here.
- **Fills:**
  - Nmulti2dpre/post.
  - nuTKEpre(TKE, ν) and nuTKEpost (Single indices).
  - Recoil-corrected post-neutron energies (loop over vlong ≠ 0) → Ekinpost(M), TKEpost(M), Acc_AEkinpost, Acc_ATKEpost.
  - Acc_ZISOPOST.
  - **Acc_JFRAGpost(N_post, Z_post, J_Frag, 1)** (9228-9229). J_Frag is the spin at scission, not reduced by emission; it is passed to an Integer parameter and rounded half-to-even. This array feeds the isomer component C15.

### C12. Eva subroutine (16650-16905; ~150 LOC)

**Interface:** `Eva(Ilh, Z, A, E_INIT, T(unused), J_Frag, ByRef Z_RES, A_RES, E_FINAL, Array_En(), Array_Tn(), Array_Eg0())`.
- `Static E_MIN` is the same variable as `E_min` (case-insensitive). It is overwritten from E_FINAL on every call, so it is effectively an input.

**Setup:** J_crit = 12·sqrt(A/100); Fred and Fred_shell are computed once from J_Frag.
- SN = Fred_shell·(Fred·SNexp + (1−Fred)·SNeff) + (1−Fred_shell)·SNld, using AME2020, U_Mass and LDMass.
- If Ei < SN, it exits immediately with no draws.

**Each Do iteration:**
- Tm and Td from U_Temp.
- Γγ = 0.624·A^1.6·Tm^5·1e-9; zero for Ilh = 0.
- Γn = Moretto formula with a cut at the ground state, multiplied by a pairing suppression below the gap.
- Tn = PExp(0.658/Γn), at least 1 draw; accumulated into Tn_acc.
- `RND < Pgamma` (1 draw, always taken, even when Pgamma = 0).
  - If a gamma is emitted: P_Egamma_high (2 draws per attempt); Array_Eg0 is written **without a bounds check**; Ngtot, Nglight/Ngheavy and Egtot1000 are updated; Acc_Egamma is filled; Ei −= Eg.
- If Ei − SN ≤ E_MIN, exit.
- Too_Low (≤ 98 attempts): PMaxwellMod(Td, A−1) (3 draws), then `RND > sqrt(exp(E/Td)/exp(E/Tf))` if Ei − E − Td > 5 (+1 draw). Retry if E_kin > Ei − SN.
- After 98 failed attempts, exit with no emission.
- Otherwise: emission, SN recomputed, `Array_En(Ifold) = E·(A−1)/A`, Array_Tn = Tn_acc.
- `Loop While Ei − SN > E_min`.
- Raus: `E_FINAL = Max(Ef, 0)`.

**Flags:**
- In the loop, SNld is computed with the pre-emission Zi, Ai (Ai = Af is set later).
- Gamma and neutron emission can both happen in the same iteration.
- Γn = 0 gives Pgamma = NaN; the comparison `RND < NaN` is false.

**Side effects on globals:** Ngtot, Nglight, Ngheavy, Egtot1000, _Egamma.

**Seam:** T2a, either through a driver that includes the mass, temperature and Eva code, or through a probe that records (inputs, draw slice, outputs, arrays). Testing first with recorded-draw replay is recommended.

### C13. u_accel (16907-16960; ~40 LOC, deterministic)
- Coulomb acceleration integrated in three For loops with Single counters and steps 0.01, 0.1 and 1. The Single accumulation decides the iteration count and must be replicated.
- `If t > 100` tests the local t before it is assigned, so it is always 0 and the test never fires. Only the `TKE < E0` shortcut is live.
- **Seam:** T1 grid through a driver.

### C14. Prompt gammas (9238-9500; ~180 LOC)

**Per fragment:**
1. **Ground-state spin lookup.** `I_MAT_ENDF(Z_sci, A_post)` does a linear NucTab scan. For nuclides not in the table it does ctl/IMATmax.ctl file I/O on every call. The physics only sees "not in table": Spin_gs = 0 and N_iso = 0. Then Spin_gs = NucTab.R_SPI.
2. **Collective spin.** `Jfrag = ((J − Spin_gs) \\ 2)*2`. `\\` rounds the Single operand half-to-even, then truncates.
3. **Entrance energy.** `Acc_Eentrance(E_Final·1000)` with implicit rounding → Eexc.dmp.
4. **E1 loop (Repeat_Eg_light 9281 / Repeat_EG_heavy 9400):**
   - While Erest ≥ 0.1: `Eg0 = P_Egamma_low(Z_sci, A_post, Erest)` (16962-17054).
     - It rebuilds a ReDim sigma table on every call, using a Single For loop `Eg = 0.1 To Ei Step 0.1`.
     - The branch `If betadef=0 And gammadef=0` is never true (gammadef = 47.4 − 120β), so the three-Lorentzian triaxial GDR branch always runs.
     - Its rejection loop draws 2 Rnd per attempt.
   - Then `Eg = PG(Eg0, σ)` with `σ = 0.3·Erot·((J+1)²/(J−1)²)`. Retry from P_Egamma_low if Eg < 0 or Eg > 2·Eg0.
   - **Light fragment:** Acc_Egamma and Acc_EgammaL are filled. Array_Eg1_light has no bounds check.
   - **Heavy fragment:** only Acc_EgammaH is filled. The **`Egamma(N) = Egamma(N) + 1` at 9417 is a no-op** (D1). Its `#If EgammaA` is missing the B_ prefix.
5. **E2 cascade.** `For J = Jfrag To 2 Step -2` (Single counter). Draws: 0.
   - Isomer stop when N_iso > 0 and I_DelGam = 0 (always 0, declared at 876):
     - At J = Jfrag, if any state's R_SPI = CInt(J_frag), it executes `Exit For, For`, which ends the cascade with no E2 gammas. The test includes K = 1, so this can trigger on the ground state itself.
     - Otherwise it stops at the first state with spin in [J + Spin_gs − 0.01, Jfrag + Spin_gs + 0.01] and sets C_iso_lmd = "M(spin/E)" (via Str(Single)).
   - Eg comes from RJeff, with U_I_Shell² damping and a pairing factor, and the moment of inertia U_IredFF·(1 + 0.5α + 9/7α²), α = DEFOtab/sqrt(4π/5) (π = 3.14159 Single).
   - Binning: `Int(Eg·1000 + 0.5)` here, versus CInt for E1.
   - Fills Acc_Egamma, Acc_EgammaL/H and Acc_EgammaE2.
6. **End of event:** NgammaA, Ngammatot, Acc_Egammatot(Egtot1000 → Integer) → Egamma.dmp and Ngammatot.dmp.

- The isomer stop affects only gamma observables and lmd, not the isomeric yields.
- **Seam:**
  - P_Egamma_low: test the table builder at T1 and the sampler at T2a.
  - The cascade is deterministic given (Jfrag, Spin_gs, Isotab, Z, A); test it at T1 with a driver.
  - Integral checks: Egamma.dmp sections.

### C15. Isomer population after the loop (14211-14300; ~45 LOC)
- **Loop:** A from 20 to A_CN − 20, Z from 10 to Z_CN − 10, N in [10, N_CN − 10], restricted to nuclides with ZISOPOST > 0 and Niso > 0.
- **Clamp:** R_lim(K) is clamped to 50 **in place**, a persistent mutation of Isotab.
- **Spin windows:**
  - Window 1: `For RJ = 0 To R_lim(1) Step 1`.
  - Window K: `For RJ = R_lim(K−1) To R_lim(K)`.
  - RJ is Single and is passed to JFRAGpost's Integer spin parameter, so it is rounded half-to-even.
  - When frac(R_lim) < 0.5 (or exactly .5 with an even integer part), the boundary spin is counted in both adjacent states.
- **Normalisation:** R_yield_iso is Single and accumulates Double values. `R_Prob = yield/Rnorm`, or 0 if Rnorm = 0.
- R_Prob stays stale for nuclides not visited.
- **Consumers:** the out-file `<Isomeric_yields>` section; ENDF.bas MT454 (`Y = NZPOST·R_Prob/R_Norm`); Branchings.bas (NZIcumu).
- **Seam:** a deterministic T1 test given JFRAGpost, ZISOPOST and Isotab. Probe those three in BASIC and compare R_Prob exactly.

### C16. Pre-saddle bookkeeping (9502-9640; ~110 LOC)
- **Fills:** NP(I_Z_Multi), NNCN(I_N_Multi), NN(ν_fr + ν_ss + N_Multi) → NP.dmp, NN.dmp.
- **Matching:** for I_A_multi = 1..6, a circular search over En_multi_k / I_emit_k (pre-pass arrays) for a matching (proton count via PLoss/Oct, E bin) gives C_test (Oct string) and IE_array (10-bit fields decoded with Fix·2^-n and Mod).
- These results are used **only** by lmd; the code that used C_test for histograms is commented out.
- **Draws:** 0.
- **Cost:** the scan is O(Imulti) per event. Port it late.

### C17. List-mode output (9644-9980; ~300 LOC)
- **Condition:** CFileoutlmd ≠ "" and (B_Error_Analysis = 0 or Brec = 1).
- **Draws (these change the stream):**
  - Pdir: costheta = 1 − 2·Rnd and phi = Rnd·360 (2 draws).
  - PnCN with I_A_multi ≤ 6: per pre-saddle particle, 3 draws for Emode 2/12/22 (En, cos, phi) and 3 for other Emodes (En, cos, phi).
  - Saddle-to-scission neutrons: 2 draws for Emode 2/12/22, otherwise 1 (phi only). In that case cosn prints as 0 because it was just Dim'd.
- **Output:** Print Using formats ("###.#", "####.###", …). FB's Print Using rounding and formatting must be reproduced for byte equality.
- **Flags:**
  - The heavy-fragment lab neutron conversion uses `Array_v_f1_CN(J)`, the light fragment's array (9902, 9917).
  - LMD and LMD+ always set Pdir = PnCN = 1 (2931-2960).
- **Seam:** the .lmd file can be compared line by line with T3. Because it changes the random stream, T3 comparisons need lmd on or off identically on both sides.

### C18. Event counter and progress (9982-9995)
- `IEVTtot += 1`; the progress print uses Now/Format.
- IEVTtot ≠ NEVTtot in multi-chance runs because each channel's count is rounded with CLngInt. For example, E30MeV/EN.dmp:98 says "1000003 fission events".

## D. Cross-cutting findings

### D1. Function-accessor no-op writes
Spectra.bas declares each histogram as an array `_X` plus `Function X()` plus `Sub Acc_X()`. Writing `X(i) = expr` at module level parses as a call to X with the boolean argument `(i) = expr`, and the result is discarded.
- **9417** (heavy-fragment E1 into Egamma): **confirmed** by data.
  - Egamma.dmp (thermal) line 15 equals EgammaL line 432 bin for bin at low energy.
  - EgammaH line 733 holds about 2000 counts per bin that are missing from Egamma.
- **8129/8152** (ENsci): same mechanism [INFERENCE: the data cannot distinguish this from simply having no saddle-to-scission emission].
- No other direct writes to accessor names were found in 7920-9997. All other function-backed histograms are filled through Acc_*.

### D2. Single vs Double in the event path
- **Single:** every event scalar, every setup table, the returns of all physics functions (AME2020, LDMass, LyMass, U_Temp, U_Ired, …), Racc (5052), NZPRE (GEF.bas:1290, counts stored in Single), Egtot1000 (845), the per-neutron and per-gamma arrays, Isotab fields, R_yield_iso.
- **Double:** Rnd itself, the Spectra histograms, PMaxwell/PMaxwellMod internals, Erfc internals, any `^` with a non-variable operand or a non-2 exponent, any expression involving `/` by an integer or a floating literal.
- **LongInt/Integer:** Mode_Events, IEVTtot, NEVTused, Ngtot, Ig*, In_post, the I_*_sad/sci/post nuclide numbers.
- **Implicit rounding sites (round half to even):**
  - Zshift/PEOZ/PEON indices.
  - `PEOZ(·,1,0.5·A_sci)`.
  - `Beta(0,·,Z_sci/2)`.
  - Qvalues(Q) and Acc_AQpre(Q).
  - EexcL2d/ErotL2d(E·10, J).
  - nuTKEpre(TKE, ν).
  - Acc_JFRAGpre/post(J).
  - Acc_Eentrance(E·1000).
  - Acc_Egammatot(Egtot1000).
  - TotXE/Ekin*/TKE* via CInt.
  - `\\` in Jfrag.
  - Isomer RJ.
- **Floor sites:** Ndirlight, ENM/ENlight/ENfr (Int), E2 bins (Int + 0.5).

### D3. Random-number use and seeded-trajectory (T3) implications
Draws per event are fixed only for the neutron angles (2 per neutron) and the mode choice (1, unless MODE(i) is set).

Data-dependent consumers:
- the DiceA rejection;
- PGauss parity and polar rejection;
- PBox2 branches;
- the Edef, Eintr and Ecoll while-loops;
- the TXE_shift branch (parity of Z);
- J_attempt (≤ 3 retries);
- TKEsci;
- Eva (Pexp rejection, gamma competition, P_Egamma_high rejection, Too_Low ≤ 98 × 3-4 draws);
- the E1 loop (P_Egamma_low rejection and the Eg retry);
- lmd.

The stream and the PGauss cache are global from 1553 onwards. To reproduce event k of the nominal pass, everything before it must be replayed: the pre-pass, 31 × (48 PGauss perturbation calls + events), and so on.

Any single-ULP difference that flips a comparison misaligns the stream for every later event. Comparisons that can flip include `RND < Pgamma`, `RND > sqrt(exp/exp)`, `yran > sigma`, `Rnd < PEOZ` and the while-loop limits.

**Harness recommendations:**
1. Replace `rnd`/`RND` textually (case-insensitive) with a logging function `HRnd()` that records (event, site tag, u32). FB may also allow `#undef Rnd` [INFERENCE].
2. Add `Randomize EvSeed,3` at the start of each event, and a Shared flag that resets PGauss's ISet. This turns T3 into per-event comparisons that cannot poison each other.
3. Give every C++ stage an `Rng&` parameter, so a draw log recorded in BASIC can be replayed for stage-isolated tests ("T2 stage tests with controlled random inputs").
4. Keep lmd identical between the two codes.
5. Build C++ against the same glibc libm; consider a `libm` shim for expf/logf/powf.

### D4. Which validation output checks which stage

| Stage | Observables |
|---|---|
| C1 | out-file mode yields |
| C2 | Aprov.dmp; ZPROV |
| C3/C6 | Apre.dmp, Npre.dmp, ZApre.dmp, ZPolarpre/SigmaZpre.dmp, XE.dmp (EintrA) |
| C5 | XE EdefoA |
| C7 | XE EcollA |
| C8 | Ekin.dmp (pre), Qvalues.dmp, Eexc.dmp (EexcL2d/ErotL2d), XE TotXE; the out-file spin section (JFRAGpre) |
| C10/C11 | Apost, Zpost, Npost, ZApost, ZPolarpost, SigmaZpost, NA, EN (ENfr/ENlight/ENheavy/ENfrfs, ENApre/post), Ekin (post); NZPOST → out-file independent yields → ENDF MT454/MT459 |
| C12 | everything after it, plus the Egamma Eva component |
| C14 | Egamma.dmp (Egamma, EgammaL, EgammaH, EgammaE2, Egammatot), Ngammatot.dmp, Eexc Eentrance |
| C15 | out-file `<Isomeric_yields>`, ENDF isomer splits |
| C16 | NP.dmp, NN.dmp |
| C17 | the .lmd file |

XE.dmp also dumps EPART, the setup table, which gives a free T1 seam for the energy-sorting tables.

## E. Suggested porting order within this slice (smallest seam first)
1. FbRng (MT with LCG seeding) and the samplers (C0), compared T2a against a FreeBASIC driver.
2. Pure helpers at T1: EVEN_ODD, u_accel, U_Ired, U_IredFF, U_I_Shell, the GDR helpers, the P_Egamma sigma-table builder, the E2-cascade function, Gaussintegral.
3. Eva and P_Egamma_* with replayed draws (T2a).
4. Scission stages C1-C9 as functions over an Event struct, compared T2 by replaying draws from the BASIC per-event probe.
5. C10, C11 and C14 the same way.
6. The histogram layer: FB-exact binning plus Acc_* growth semantics that reproduce the D1 no-ops, then dmp and out writers (T4).
7. C15 at T1 on probed JFRAGpost.
8. C16 and C17 (lmd last), then full T3.

Checks the main agent should run before relying on the [INFERENCE] items:
- Compile a tiny FreeBASIC test confirming that `F(i) = F(i) + 1` on a function is a silent no-op.
- Confirm that a Single times a Double literal evaluates in Double.
- Confirm that `#undef Rnd` works.
