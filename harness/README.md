# harness — the BASIC reference harness (M1)

The harness turns the original FreeBASIC GEF into a controllable, observable test oracle: seeded and repeatable runs, a per-event reseed mode, random-draw logs, state probes, function drivers, a clean-run runner and an immutable reference store. Plan and gates: `Planning/MILESTONE_1_PLAN.md`.

The submodule `Reference/GEF_code/` is never modified. Every binary is built from a copy of the source with a named **patch set** applied. All tools run from the repository root as `python3 -m harness.<module>`; each module's docstring has the full usage.

## Reference binary

`ref-1` is the `seed` patch set: the original source with only `Randomize,3` (`GEF.bas:1553`) replaced by a seed read from `GEF_SEED`. It was shown to reproduce the original clock-seeded `validation/test_run/gef_reference` byte for byte (timestamps masked) when given the seed captured from a `gef_reference` run (gate G1). `manifests/reference_binary.json` records its provenance.

## Patches and patch sets

Unified diffs in `patches/`, applied with `patch -p1 --fuzz=0` in the canonical order **variant patches → seed → scope → reseed → rndlog → probes → datachain**. None of them changes the line numbering of `GEF.bas` (draw-site tags and probe locations use the original lines). Harness code lives in new `harness_*.bi` files that the patches add.

| Patch | Effect | Switch |
|---|---|---|
| `seed` | `Randomize <GEF_SEED>,3`; a missing or invalid `GEF_SEED` stops with exit 2 before any computation | always |
| `scope` | Tracks the current energy step, pass and event (`Harness_Step/Pass/Event`) and parses the trace selectors | always (inert) |
| `reseed` | Per-event reseed mode, `RESEED_SPEC.md` | `GEF_RESEED=1` at run time |
| `rndlog` | Logs every traced `Rnd` draw to `rnd.log`, `RNDLOG.md` | compile with `-d GEF_RNDLOG` |
| `probes` | Hex dumps of state at T0, P1, P2, P3 to `probes/<ID>.txt`, `PROBES.md` | compile with `-d GEF_PROBES` |
| `datachain` | Dumps every `DATA` item, in `Read` order, as hex to `probes/datachain.txt` (M4) | compile with `-d GEF_DATACHAIN` |
| `nucprop-<v>` | Swaps the nuclide-data include at `GEF.bas:1052` for `NucProp<v>.bas` (`jeff311`, `nubase2016`, `nubase2020`, `x`, `mf`, `f`; M4) | always |
| `legacy-isosource` | Defines `ISOSOURCE` in the legacy `NucPropx/mf/f.bas`, which GEF 2025/1.2 needs; not a stock configuration (M4) | always |

Patch sets (`patchsets/<name>.txt`): `none`, `seed`, `seed-rndlog`, `seed-probes`, `seed-rndlog-probes`, `seed-reseed`, `seed-reseed-rndlog`, `seed-reseed-probes`, `seed-reseed-rndlog-probes`, and the M4 variant sets `m4-jeff33`, `m4-jeff311`, `m4-nubase2016`, `m4-nubase2020`, `m4-legacy-x`, `m4-legacy-mf`, `m4-legacy-f` (each with seed, scope, probes and datachain).

```sh
python3 -m harness.build seed                                   # -> build/harness/seed-<hash>/GEF
python3 -m harness.build seed-rndlog-probes --define GEF_RNDLOG --define GEF_PROBES
python3 -m tools.fbsrc.emit_c --patch-dir build/harness/patchdirs/seed   # C of a patched source
```

Builds use plain `fbc GEF.bas` (the options that reproduce `gef_reference`) with `SOURCE_DATE_EPOCH` set to the submodule commit time, and are reproducible.

## Run-time environment variables

| Variable | Meaning |
|---|---|
| `GEF_SEED` | Master seed, decimal 0 … 4294967295 (required) |
| `GEF_RESEED` | `1` enables per-event reseed mode; unset or empty = normal mode; anything else exits 2 |
| `GEF_TRACE_STEPS`, `GEF_TRACE_PASSES`, `GEF_TRACE_EVENTS` | Comma lists of integers or ranges (`1,3-5`) selecting energy step (`I_E_step`), pass (`I_Error`; the nominal pass is `N_Error_Max`) and event (`ILoop`) for draw logging and probes. Unset selects nothing |

With `Options(ENDF)` and N energies, GEF runs N+3 energy steps: step 1 is the lowest energy, step 2 the highest (both nominal only), steps 3 … N+2 the listed energies, and step N+3 the lowest again.

## Running and comparing

```sh
python3 -m harness.run --binary seed-<hash> --input harness/inputs/m1_rn215_short.in \
    --seed 12345 --out build/runs/a [--reseed] [--scope steps=8 --scope passes=0,31 --scope events=1-20]
python3 -m harness.compare_runs build/runs/a build/runs/b [--allow-only-in-b 'work/probes/*' --allow-only-in-b work/rnd.log]
python3 -m harness.capture_seed --input harness/inputs/m1_rn215_short.in --out build/runs/ref
```

- `run` creates a fresh run directory (`run.json`, `stdout.log`, `stderr.log`, `work/` = GEF's working directory with `file.in`, `in/`, `out/`, `dmp/`, `tmp/`, `ENDF/`, `ctl/`, …). It refuses an existing directory.
- `compare_runs` compares two run directories byte for byte. Only the time-dependent fields listed in `masks.toml` are masked; each mask names the BASIC statement that writes it, and masks that matched nothing are listed.
- `capture_seed` runs the original `gef_reference` under gdb, verifies its SHA-256 first, and records the seed it derives from the clock (breakpoint on the runtime's MT initialiser).

Inputs used by the M1 gates: `inputs/m1_rn215_short.in` (Rn-215 compound nucleus, `EN`, `Fenhance` 10, 8 energies chosen to cross every multi-chance threshold) and `inputs/m1_cf252_gs.in` (Cf-252 `GS`, `Fenhance` 100).

## Reference store

```sh
python3 -m harness.store add <run-dir> --id <capture-id> --kind run|capture|driver|calibration --note "..."
python3 -m harness.store add-binary <path> --note "..." --provenance-json <file>
python3 -m harness.store verify            # every capture and binary against its manifest
python3 -m harness.store list
```

Captures are copied to `validation/reference_store/captures/<id>/` (gitignored, read-only files); their manifests, with the SHA-256 of every file, are committed in `manifests/reference_store/`. An existing id is refused: captures never change. `verify` exits 77 when `validation/` is absent.

## Drivers

```sh
python3 -m harness.driver run rnd_stream -- 42 1000000
```

A driver is a FreeBASIC program in `drivers/`. `'@include-source <file>` copies a GEF source file next to it; `'@cut <file>:<first>-<last> as <name>.bi` extracts a line range (e.g. one function) so it can be included. `driver.json` records the source, binary and output hashes and every cut. `rnd_stream` writes the `Randomize s,3` + `Rnd` stream as u32 hex; seed 42 × 10⁶ is stored as `m1-golden-rnd-stream-42` and matches `harness.fbmt`, the Python reference of fbc's generator.

## Logs and probes

```sh
python3 -m harness.rndlog summary work/rnd.log
python3 -m harness.rndlog scopes work/rnd.log --master 12345   # reseed mode: draws outside scopes, stream checks
python3 -m harness.probes summary work/probes/P3.txt
```

Comparisons of runs (exact field by field, or statistical against a calibration) are done with the `compare` package (M2, `compare/README.md`). M1's provisional `minicheck` was retired there.

## Python references for M3

- `fbmt.py`: fbc 1.10.1 `Randomize s,3` + `Rnd`.
- `reseed.py`: the reseed seed derivation, with the test vectors listed in `RESEED_SPEC.md`.
