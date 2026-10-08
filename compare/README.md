# compare — the comparison toolkit (M2)

Turns two GEF output directories into a verdict. Plan and results: `Planning/MILESTONE_2_PLAN.md`; statistical method: [`STATISTICS.md`](STATISTICS.md). All tools run from the repository root as `python3 -m compare.<module>`; each module's docstring has the full usage.

Since the exact-first decision (strategy §2.9) the toolkit has two roles:

- **Exact comparison** (`compare.exact`) is the acceptance tool of phase 1. A seeded C++ run must equal the seeded BASIC reference, field by field.
- **Statistical verdicts** (`calibrate`, `verdict`) are for phase 2 (optimised and parallel C++ against the exact C++ code) and for the T5 library check.

## Parsers and the observable model

Every output file becomes `(Key, Value)` pairs (`model.py`). A key is file, block, group, label and index; a *family* (file, block, group) is the unit of a statistical test and of a report line.

| Parser | Files | Fidelity |
|---|---|---|
| `parsers/endf.py` | `work/ENDF/*.dat`, `work/tmp/CUMU*.dat`, library tapes | byte round-trip |
| `parsers/dmp.py` | `work/dmp/*/*.dmp` | byte round-trip |
| `parsers/mvd.py`, `parsers/par.py` | `work/tmp/*_Single.mvd`, `work/tmp/*.par` | byte round-trip |
| `parsers/out.py` | `work/out/*.dat`, `*.ptb` | every numeric token captured (field coverage) |
| `parsers/probe.py` | `work/probes/*.txt` | exact bit patterns |
| `parsers/text.py` | everything else (`stdout.log`, `ctl/`, inputs) | template-keyed lines |

Rules every parser follows:
- Keys depend only on file content, never on line numbers. Table rows are keyed by what identifies them (for example nuclide and decay name, or the state's E*).
- Time stamps listed in `harness/masks.toml` are parsed but not emitted.

```sh
python3 -m compare.gate_g1                       # round-trip / coverage over all stored files
python3 -m compare.exact RUN_A RUN_B [--ulp N]   # field-level exact comparison
```

`compare.loader.load_run` reads both the harness run layout (`stdout.log`, `work/…`) and plain GEF working directories (`run.log` is read as `stdout.log`).

## Statistical verdicts

```sh
python3 -m compare.ensemble run m1_rn215_short --seeds 1001-1020 --jobs 8   # seeded ref-1 runs into the store
python3 -m compare.extract RUN ...                                          # cached compact extracts
python3 -m compare.calibrate --ensemble m2-ens-m1-rn215-short --out DIR     # null calibration
python3 -m compare.verdict --calibration DIR --candidate RUN [--text OUT --json OUT]
python3 -m compare.gates null|g4|sensitivity ...                            # gates G3, G4, G5
python3 -m compare.inject --run RUN --fault yield2pct|massbin|isomer --at SPEC --out DIR
```

- **How it decides.** Each family gets a global and a local statistic against an ensemble of K seeded runs, and Holm's correction holds the suite false-alarm rate at α = 0.01 (`STATISTICS.md`).
- **Stored calibrations** (K = 20 `ref-1` runs each): `m2-cal-m1-rn215-short`, `m2-cal-m1-cf252-gs`, `m2-cal-m2-rn215-full`.
- **Validity limits:**
  - The method meets the false-alarm target for Cf-252.
  - It does not meet it for Rn-215 at full-output scale with K = 20; the M2 completion notes give the evidence.
  - Phase 2 re-validates it with large exact-C++ ensembles (strategy M17).

## Tests

Fast tests run in CI (`pytest compare`). Tests marked `validation` need `validation/` and the reference store.
