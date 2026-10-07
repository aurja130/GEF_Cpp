# GEF_Cpp

A C++ recreation of **GEF** (GEneral description of Fission observables, K.-H. Schmidt and B. Jurado), version 2025/1.2, originally written in FreeBASIC.

The goal is a faithful, testable and modern C++ GEF. "Faithful" is defined by evidence: the C++ code must agree with the original BASIC binary in differential tests (tables, functions, samplers, seeded event trajectories) and integral tests (whole calculations and the full GEFY yield library), within criteria fixed in advance. Known defects of the original are reproduced by default and documented in a quirk register.

## Status

**Milestones 0 (Foundations) and 1 (Reference harness) are complete.** The repository has its build, test, lint and CI infrastructure, tooling to inspect the BASIC source, and a reference harness that turns the original BASIC program into a repeatable, observable test oracle. No GEF physics has been ported yet; that starts with M3 (FreeBASIC runtime emulation), alongside M2 (comparison toolkit).

| Area | State |
|---|---|
| C++ build (CMake + Ninja, C++23) | `gef_fbrt` library and `gef` CLI; four presets; Catch2 v3 tests |
| Exact floating-point mode | Flags mirror fbc's gcc backend; checked at run time by `gef --version` |
| BASIC-source tooling | FreeBASIC → C translation, BASIC line → C lookup, symbol index |
| Reference harness | Seeded reference binary `ref-1`, proven byte-identical to the original binary; per-event reseed mode; random-draw logs; state probes; function drivers; immutable reference store |
| Toolchain and data pinning | Toolchain check with fbc 1.10.1 pin; SHA-256 manifests for the validation data and the reference store |
| Plans | 19 milestones (M0–M18); see `Planning/` |

## Repository layout

```
CMakeLists.txt, CMakePresets.json   C++ build (presets dev-gcc, dev-clang, asan-ubsan, release-exact)
Cpp_implementation/
  src/app/                          gef CLI
  src/fbrt/                         FreeBASIC runtime emulation (M0: floating-point environment self-check)
  tests/                            Catch2 tests, tagged [unit] and [T0]…[T5]
  cmake/                            compiler policy (exact-mode FP flags, warnings), build-time git revision
tools/
  toolchain/                        toolchain check, fbc locator, validation-data manifests
  fbsrc/                            BASIC-source tools: emit_c, fbline, fbdef (see tools/fbsrc/README.md)
harness/                            BASIC reference harness: patches, builder, runner, comparison,
                                    seed capture, store, drivers (see harness/README.md)
manifests/                          committed toolchain record, SHA-256 manifests of validation/,
                                    reference-binary provenance and reference-store manifests
scripts/ci.sh                       single local CI entry point
pyproject.toml                      Python tooling configuration (ruff, basedpyright, pytest)
Planning/                           vision, strategy, milestone plans, project state,
                                    coding standards, quirk register, coverage matrix, code maps
Reference/GEF_code, Reference/GEF_data   upstream GEF sources and NEA helper scripts (git submodules, read-only)
validation/                         reference library and a recorded BASIC run (not in git, ~1.1 GB)
```

## Requirements

Developed on Fedora 44 (x86-64). The toolchain check (`python3 -m tools.toolchain.check_toolchain`) verifies these minimums:

- GCC ≥ 16 (primary compiler; same backend and glibc libm as fbc) and Clang ≥ 22
- CMake ≥ 4.0, Ninja ≥ 1.11
- clang-tidy and clang-format ≥ 22
- Python ≥ 3.14 with NumPy and SciPy; ruff ≥ 0.16, basedpyright ≥ 1.39, pytest ≥ 9.1
- Universal Ctags ≥ 6.0
- GNU `patch` (harness builds) and `gdb` (seed capture from the original binary)
- **FreeBASIC fbc 1.10.1 exactly**, Linux x86-64 build (not vendored). The tools look for it in `GEF_FBC`, falling back to `~/Downloads/FreeBASIC-1.10.1-linux-x86_64/bin/fbc`. When the distribution tarball sits next to that directory, its SHA-256 is checked against `844aa9e9…08bc`. fbc prints harmless `libtinfo`/`ospeed` loader warnings; the tools filter them.

The first CMake configure downloads Catch2 v3.16.0 (pinned by archive hash), so it needs network access once.

## Getting started

```sh
git clone --recurse-submodules https://github.com/aurja130/GEF_Cpp.git
cd GEF_Cpp
export GEF_FBC=/path/to/FreeBASIC-1.10.1-linux-x86_64/bin/fbc   # if not at the default path
python3 -m tools.toolchain.check_toolchain
```

### Build and test the C++ code

```sh
cmake --preset dev-gcc
cmake --build --preset dev-gcc
ctest --preset dev-gcc
build/dev-gcc/Cpp_implementation/src/app/gef --version
```

| Preset | Compiler | Purpose |
|---|---|---|
| `dev-gcc` | GCC | Debug development build |
| `dev-clang` | Clang | Debug; second compiler; its `compile_commands.json` feeds clangd and clang-tidy |
| `asan-ubsan` | GCC | AddressSanitizer + UndefinedBehaviorSanitizer, failing on the first error |
| `release-exact` | GCC | Optimised build with the exact-mode floating-point flags |

All targets compile with `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wdouble-promotion -Wshadow -Werror` and the exact-mode flags `-march=x86-64 -ffp-contract=off -fno-fast-math -frounding-math -fno-math-errno -fexcess-precision=standard`.

`gef --version` prints the project version, git revision, compiler, preset, compiled-in floating-point flags and the verdict of a run-time check of the exact-mode assumptions (`FLT_EVAL_METHOD == 0`, IEEE 754 types, round-to-nearest, no FMA contraction). It exits non-zero if any check fails.

Catch2 tags become CTest labels, so `ctest --preset dev-gcc -L fbrt` (or later `-L T1`) runs one group.

### Local CI

```sh
scripts/ci.sh           # everything
scripts/ci.sh --quick   # dev-gcc build and tests, plus the Python checks
```

The full run executes the toolchain check; configure, build and test for `dev-gcc`, `dev-clang` and `asan-ubsan`; clang-tidy; clang-format; ruff (lint and format); basedpyright; pytest; and validation-manifest and reference-store verification (skipped with a notice when `validation/` is absent). It prints a one-line summary per step and exits non-zero on any failure. Logs go to `build/ci/`.

### Running the BASIC reference

```sh
python3 -m harness.build seed                       # ref-1: original source + seed patch
python3 -m harness.run --binary seed-<hash> --input harness/inputs/m1_rn215_short.in --seed 12345 --out build/runs/a
python3 -m harness.compare_runs build/runs/a build/runs/b
harness/gates.sh all                                # the long M1 gates (about 2 h)
```

Runs are byte-reproducible for a given seed, with timestamps masked. Builds with probes or draw logging give the same outputs. See [`harness/README.md`](harness/README.md).

### Inspecting the BASIC source

The original BASIC is the specification. To see exactly what a BASIC line computes, look at the C that fbc generates for it:

```sh
python3 -m tools.fbsrc.fbline GEF.bas:8392          # BASIC line(s) and the generated C
python3 -m tools.fbsrc.fbline Spectra.bas:1505 --symbols
python3 -m tools.fbsrc.fbdef PGauss                 # where a symbol is defined
python3 -m tools.fbsrc.fbdef E_min --refs           # every reference, case-insensitive
python3 -m tools.fbsrc.emit_c                       # (re)emit GEF.c under build/fbsrc/
```

The first call translates the source (about 15 s); later calls reuse it. See [`tools/fbsrc/README.md`](tools/fbsrc/README.md).

### Validation data

`validation/` (gitignored) holds the GEFY reference library (382 ENDF-6 tapes and their sequence files) and one recorded BASIC run. Its checksums are committed under `manifests/`:

```sh
python3 -m tools.toolchain.manifest_validation verify   # reports missing, changed and extra files
```

`validation/test_run/` is recorded evidence only, not a clean working directory (stale `ctl/` files and a two-tape ENDF file).

## Documentation

| Document | Content |
|---|---|
| [`Planning/GEF_CPP_VISION.md`](Planning/GEF_CPP_VISION.md) | Goals, test tiers T0–T5, coverage dimensions, statistical acceptance, definition of done |
| [`Planning/IMPLEMENTATION_STRATEGY.md`](Planning/IMPLEMENTATION_STRATEGY.md) | Component inventory, strategic decisions, milestones M0–M18 and their gates |
| [`Planning/CURRENT_PROJECT_STATE.md`](Planning/CURRENT_PROJECT_STATE.md) | What exists now, open risks, next steps |
| [`Planning/MILESTONE_0_PLAN.md`](Planning/MILESTONE_0_PLAN.md), [`MILESTONE_1_PLAN.md`](Planning/MILESTONE_1_PLAN.md) | Milestone plans and completion notes |
| [`Planning/CODING_STANDARDS.md`](Planning/CODING_STANDARDS.md) | C++ and Python conventions, provenance and quirk annotations, tests, license notices |
| [`Planning/QUIRKS.md`](Planning/QUIRKS.md) | Register of known BASIC quirks and defects that the port reproduces |
| [`Planning/COVERAGE_MATRIX.md`](Planning/COVERAGE_MATRIX.md) | Coverage of GEF's dimensions by test tier, with owning milestones |
| [`Planning/code_maps/`](Planning/code_maps/) | Code maps of the BASIC program from the planning session |

## License

GEF_Cpp is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See [`LICENSE.txt`](LICENSE.txt) for the full text. Every source file carries an SPDX license notice.

Copyright (C) 2026 Aurora Jahan.

GEF_Cpp is a derivative work of GEF, which is licensed under the same terms. The GEF code is Copyright (C) 2009–2025 Dr. Karl-Heinz Schmidt and Dr. Beatriz Jurado; its development was supported by the European Union (EURATOM FP6 EFNUDAT, contract FP6-036434; FP7 ERINDA, contract FP7-269499) and by the Nuclear Energy Agency of the OECD (2010–2016). The original sources are in the `Reference/GEF_code` submodule (see its `LICENSE` and `README.md`). Files that port GEF code carry the GEF copyright line in addition to ours.

Third-party components keep their own licenses: Catch2 (Boost Software License 1.0, fetched at build time), NumPy and SciPy (BSD-3-Clause). All are GPL-3.0-compatible.
