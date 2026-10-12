# M5 physics drivers

FreeBASIC drivers that evaluate the deterministic physics functions of `Planning/MILESTONE_5_PLAN.md` §3 with the GEF code itself (cut from `GEF.bas`), on synthetic grids and on the calls GEF really makes (the `arglog` captures, `harness/ARGLOG.md`). Their outputs are the oracle of the C++ port (`Cpp_implementation/src/physics/`, tests `physics_<group>_test.cpp`).

## Layout

One driver per group: `m5_masses`, `m5_barriers`, `m5_level_density`, `m5_shape`, `m5_helpers`, `m5_rotation`, `m5_egamma_table`, `m5_e2_cascade`. Each one

- pulls GEF code in only through `'@include-source` and `'@cut` (whole functions by their line range; for the two extracted pieces, the line range wrapped in a driver `Sub`), plus the shared helpers `'@include-driver m5_common.bi`;
- declares what the cut code needs exactly as GEF declares it (`Declare` lines copied from `GEF.bas`, `ReDim Shared` tables with GEF's bounds, `Dim Shared` globals with GEF's types and initial values), and fills the tables by including GEF's own table files (`BEldmTF.bas`, `BEexp.bas`, `DEFO.bas`, `ShellMO.bas`; `NucPropJEFF33.bas` for `Isotab`);
- with no arguments writes the grids, with `replay <arglog dir>` replays the captured calls.

`m5_helpers.bas` is the reference example.

## Schemas and tokens

Every function and site has one schema, the field list of its `arglog` header (`harness/ARGLOG.md`): parameters in order (ByRef ones as `<name>.in`, `<name>.out`), `result`, `global.<name>`; sites `in.<expr>` / `out.<expr>`. Tokens are the `arglog` tokens (`f32` 8 hex, `f64` 16, `i64` 16, `u8` 2, `str` hex bytes or `-`, `f32[]`, `f32hash`), written with the `M5_*` functions of `m5_common.bi`. A driver's schema string must equal the `arglog` header text, or the replay stops.

## Grid files

`<fn>_grid.txt` (structured grid) and `<fn>_random.txt` (seeded random tuples), in the working directory:

```
# m5grid 1 <fn> <schema>
<token> <token> ...          one line per evaluation: all fields of the schema, in order
```

Rules, so that the C++ test can regenerate every input exactly:

- Structured axes: value i is `CSng(Lo + i * Stp)` computed in `Double` (`M5_Axis` in `m5_common.bi`, `m5::axis` in C++); integer axes are plain loops. Lists of named edge values are written as `Single` literals in the driver (and repeated in the C++ test).
- Random tuples: `Randomize <seed>, 3` with a seed of its own per file, then for each tuple the fields are drawn in schema order with `M5_Draw(Lo, Hi)` = `CSng(Lo + (Hi - Lo) * Rnd)` in `Double`, unless the driver documents another formula next to it (the C++ test uses `gef::fb::FbMtRng`). 10⁵ tuples per function unless the plan says otherwise.
- The loop order and every range are documented in a comment in the driver.

## Replay

`m5_<group> replay <dir>`: for each function or site of the group whose log `<dir>/<fn>.txt` exists, the driver reads every record (`M5_ReplayOpen`/`M5_ReplayNext`), recomputes the call from the logged inputs and writes `replay/<fn>.txt`: `<seq> <tokens>` with all fields (inputs echoed, outputs recomputed). `python3 -m harness.arglog replay-check <dir> replay` must report every file `OK`: the driver computes what GEF computed in context.

## Goldens

The full grid outputs go to the reference store as capture `m5-<group>` (`harness.golden promote`, kind `driver`, larger than the committed limit); their whole-file fingerprints (`python3 -m harness.probe_fingerprints m5-<group> --name m5-<group> --files ...`) are committed under `Cpp_implementation/tests/golden/m5-<group>/files.txt`. The C++ test regenerates every line, compares the fingerprint, and with the store present compares line by line.
