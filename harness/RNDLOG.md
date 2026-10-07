# Rnd log (`rnd.log`)

The `rndlog` patch records every random number GEF draws, tagged with the place in the BASIC source that drew it. It exists so that the C++ port can be compared draw by draw (M3 onward) and so that reseed mode can be checked for draws outside its scopes (M1.7).

## Building and enabling

| What | How |
|---|---|
| Build | `python3 -m harness.build seed-rndlog --define GEF_RNDLOG` (patch set `seed-rndlog` = `seed`, `scope`, `rndlog`) |
| Without `-d GEF_RNDLOG` | The patch adds no code that runs: `harness_rndlog.bi` is empty, and the C that fbc generates is identical to the `seed`+`scope` build (checked, see below) |
| Choose what is logged | `GEF_TRACE_STEPS`, `GEF_TRACE_PASSES`, `GEF_TRACE_EVENTS` (see "Scope" below), or `harness.run --scope steps=1 --scope passes=0 --scope events=1-100` |
| Inspect | `python3 -m harness.rndlog summary <rnd.log>` or `head <rnd.log> -n 20` |

The log is `rnd.log` in GEF's working directory (`<run>/work/rnd.log`). It is created at the first logged draw, opened in append mode, fully buffered (1 MiB) and closed when the program exits (also on `End`). A run with nothing selected creates no `rnd.log`. Without `GEF_SEED` the `seed` patch stops the program first; the logging patch needs no seed of its own.

## Record format

One ASCII line per logged draw, `\n` terminated, no header (in reseed mode scope marker lines are interleaved, see "Scope markers"):

```
<counter> <file>:<line> <u32>
```

| Field | Meaning |
|---|---|
| `counter` | Decimal. 1-based index of the draw among **all** draws of the program since start-up, logged or not. Strictly increasing in the file. A gap in the counters means draws outside the scope |
| `file:line` | The `Rnd` call site in the **original** BASIC source, i.e. the pristine `Reference/GEF_code/source/GEF.bas` numbering (the patches keep line numbers, see "Line numbers"). `file` is the file name without directory. Two `Rnd` on the same line (e.g. `Log(Rnd) + Log(Rnd)`) carry the same tag; their counters tell them apart |
| `u32` | Exactly 8 lowercase hex digits: the 32-bit output of the Mersenne Twister. `Rnd` returned `u32 / 2^32` (exact in binary64; fbc 1.10.1 `hRnd_MTWIST`) |

Example (Rn-215, thermal, seed 12345, events 1 to 3 of energy step 1, pass 0):

```
1 GEF.bas:7931 0cc85a7e
2 GEF.bas:17963 641e9339
3 GEF.bas:17964 69492bbd
4 GEF.bas:17963 b0c2858b
```

`harness/rndlog.py` parses this (`RndRecord(counter, file, line, u32)`, `.site`, `.value`, `read_log`, `summarize`). The values were checked against the independent Python implementation of fbc's generator (`harness/fbmt.py`): in the sample run all 684 logged `u32` equal `FbMtRng(12345)` output number `counter`.

## Scope

The logging uses `Harness_Traced()` from the `scope` patch. `harness_scope.bi` keeps `Harness_Step` (= `I_E_step`), `Harness_Pass` (= `I_Error`) and `Harness_Event` (= `ILoop`); each is 0 outside its loop. The selectors are comma-separated non-negative integers or ranges (`1,3-5`; at most 64 items); a malformed list stops the program with exit code 2 at start-up.

A draw is logged when its step is in `GEF_TRACE_STEPS` **and** its pass is in `GEF_TRACE_PASSES` **and**, only if it happens inside the event loop (`Harness_Event <> 0`), its event is in `GEF_TRACE_EVENTS`. An unset or empty selector selects nothing, so steps and passes must both be set to trace anything. Consequences:

- Draws between the events of a pass (the multi-chance pre-pass at `GEF.bas:4245` to `4651`, and the draws of a perturbation pass) have `Harness_Event = 0`; they are logged whenever their step and pass are selected, whatever `GEF_TRACE_EVENTS` says.
- The multi-chance pre-pass runs before `calcstart:` with `I_Error = 0`, so it belongs to pass 0.
- Select with `GEF_TRACE_STEPS=1 GEF_TRACE_PASSES=0 GEF_TRACE_EVENTS=1-1000` to log the pre-pass and the first 1000 events of the first step. A full event loop of one step is about 10^8 draws (about 3 GB of log).

## Line numbers

fbc's `__LINE__` is used for the site tag, so the patched `GEF.bas` must have the pristine numbering. `scope` and `rndlog` therefore add no lines: they replace the blank lines 1 and 446 with one `#include` each and append their statements to existing lines (3442, 3447, 4811, 7922, 9997, 15582). A patch that inserts lines above line 18047 must follow the inserted block with `#line <N-1>`, where `N` is the pristine number of the next original line (fbc numbers the line after `#line M` as `M+1`).

## How the draws are routed

`harness_rndlog.bi` (included at line 446, before the first `Rnd`, only with `-d GEF_RNDLOG`):

```
Private Function Harness_Rnd(ByVal Cfile As ZString Ptr, ByVal Iline As Long) As Double
  Dim As Double Rvalue = Rnd          ' the one and only draw
  Harness_Draws += 1
  If Harness_Traced() Then ... write "<Harness_Draws> <file>:<Iline> <u32>" ...
  Return Rvalue
End Function
#undef Rnd
#define Rnd Harness_Rnd(__FILE__, __LINE__)
```

No call site is edited. The log uses C `fopen`/`fprintf` (declared under `Harness_` names), never FreeBASIC file numbers, so GEF's own `#n` handles are untouched. `Harness_Draws` (`ULongInt`, never reset) is also readable by probes.

## Scope markers (reseed mode)

Only in a build of patch set `seed-reseed-rndlog` (`seed`, `scope`, `reseed`, `rndlog`; `-d GEF_RNDLOG`) run with `GEF_RESEED=1`, `harness_reseed.bi` writes two more kinds of line to `rnd.log`, under the same `Harness_Traced()` condition as the draws. Without `GEF_RESEED` the log has no markers and is byte-identical to a log of the `seed-rndlog` build.

```
B <scope> <seed32> <tuple element>...
E <scope>
```

| Field | Meaning |
|---|---|
| `B` | Written right after the reseed of a scope instance (`Randomize seed32, 3`), before its first draw |
| `E` | The end of the scope instance (after the last history of the pre-pass, after the 46 perturbation draws, after the last event of a bin). The next `B` ends the previous instance as well |
| `scope` | Decimal scope ID: 1 pre-pass history, 2 perturbation block, 3 event |
| `seed32` | 8 lowercase hex digits: the `Randomize` argument derived by `harness/RESEED_SPEC.md` |
| tuple | Signed decimal BASIC loop counters of the instance, in hashing order (5 elements for scopes 1 and 2, 10 for scope 3) |

A draw is *inside* a scope when a `B` line precedes it and no `B` or `E` line lies between them. `python3 -m harness.rndlog scopes <rnd.log> [--master SEED] [--streams] [--json]` lists the draws that are not inside, checks every seed against `harness.reseed.derive_seed` (`--master`) and checks that the draws of each instance are the stream `FbMtRng(seed32)` from its start (`--streams`). Exit status 3 if there are draws outside scopes or any problem. `parse_lines`, `read_log` and `summarize` ignore marker lines; `parse_events` and `read_events` return them (`ScopeBegin`, `ScopeEnd`).

## Neutrality evidence

Generated C (`emit_c --patch-dir` with `01-seed`, `02-scope`, `03-rndlog`; temporaries `$N`, `#line` and comment lines normalised away):

| Comparison | Result |
|---|---|
| `seed` against `seed`+`scope` | Pure insertions: the harness procedures and variables, and the 7 one-line assignments `HARNESS_STEP$ = ...`, `HARNESS_PASS$ = ...`, `HARNESS_EVENT$ = ...` at the loop heads and after the loops. No GEF statement changes or moves |
| `seed`+`scope` against `seed`+`scope`+`rndlog` without the define | Identical (only a `//` comment line differs) |
| The same with `-d GEF_RNDLOG` | 4 insertion hunks (wrapper, declarations) and 60 one-for-one replacements of `double vr$N = fb_Rnd( 0x1.p+0f );` by `double vr$N = HARNESS_RND( (char*)"GEF.bas", <line> );`, in place, same order. Statements with two `Rnd` (`Log(Rnd) + Log(Rnd)` and similar at 18024, 18034, 18045, 18047) keep their two temporaries in the same order |
| Sites | The 60 `HARNESS_RND` line numbers equal the 60 `Rnd` tokens of the pristine source outside comments and strings (test `test_rndlog_sites_match_every_rnd_in_gef_source`) |

Run evidence (Rn-215 thermal and 14.5 MeV, `Fenhance 10`): see the completion notes of M1.8.

## The 60 sites

56 distinct lines; four lines hold two draws. Lines are in the original `GEF.bas`.

| Lines | Where | Draws |
|---|---|---|
| 4245, 4247 | module level, pre-pass: incident energy sampled from an input energy distribution (`Emode = 13`) | 2 |
| 4420, 4453 | pre-pass: decay channel (`Grandom * Gtot`), fission test against `Pfis` | 2 |
| 4562-4585 | pre-pass: pre-equilibrium emission (neutron or proton, exciton number) | 4 |
| 4613-4651 | pre-pass: proton or neutron evaporation and kinetic-energy rejection | 3 |
| 7931 | event loop: fission mode choice | 1 |
| 8421, 8484 | event loop: even-odd choice with `PEOZ` (rounding of the fragment spin) | 2 |
| 8963, 8981, 9074, 9091 | event loop: neutron emission from the fragments, longitudinal velocity component and azimuth `phi` | 4 |
| 9680, 9719 | event loop: fission-fragment direction in the CN system (`costheta_f1_CN`, `phi_frag1`) | 2 |
| 9769-9839 | event loop: neutron energies and directions in the CN system | 10 |
| 16777, 16827 | `Eva`: gamma emission, kinetic-energy rejection | 2 |
| 17049, 17050, 17086, 17087 | `P_Egamma_low`, `P_Egamma_high` | 4 |
| 17568, 17572 | `Pexplim` | 2 |
| 17882, 17896, 17898, 17906, 17914 | `PBox`, `PBox2` | 5 |
| 17927, 17936, 17938, 17950, 17952 | `PPower`, `PPower_Griffin_v`, `PPower_Griffin_E` | 5 |
| 17963, 17964 | `PGauss` (two uniform draws per Marsaglia polar try) | 2 |
| 18010 | `PExp` | 1 |
| 18024 (2), 18034 (2), 18044, 18045 (2), 18047 (2) | `PMaxwell`, `PMaxwellv`, `PMaxwellMod` | 9 |

`rndlog.py summary` lists the sites that actually drew in a run.
