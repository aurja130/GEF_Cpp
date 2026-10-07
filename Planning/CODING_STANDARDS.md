# Coding Standards

**Created:** M0.9. **Applies to:** all C++ under `Cpp_implementation/`, all Python under `tools/`, `harness/` (M1) and `compare/` (M2), shell and CMake files.
**Related documents:** `Planning/QUIRKS.md` (quirk register), `Planning/COVERAGE_MATRIX.md` (coverage), `Planning/IMPLEMENTATION_STRATEGY.md` §2 (decisions this document turns into rules), `Planning/MILESTONE_0_PLAN.md` §2 (toolchain decisions).

The goal of every rule here is fidelity first, then readability: the C++ code must compute what the BASIC binary computes, and a reader must be able to see where each statement came from.

## 1. License notice

The project is licensed under the GNU General Public License, version 3 or (at your option) any later version (`GPL-3.0-or-later`, `LICENSE.txt`). It is a derivative work of GEF, which is under the same license.

Every source file created in this repository starts with this notice, after the shebang line if there is one. This covers C++ sources and headers, Python (including `__init__.py` and tests), shell scripts, CMake files and tool configuration files that allow comments. It is not used for JSON, Markdown documents, or generated files under `build/`.

C++:

```cpp
// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
```

Python, shell, CMake:

```python
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
```

**Files that port or translate GEF code** (C++ ported from the BASIC, FreeBASIC harness drivers, data generated from GEF tables) keep the GEF authors' copyright as well. Add this line directly after our copyright line:

```cpp
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.
```

Generated files that embed GEF data carry the same two copyright lines in their generated header. Third-party code (e.g. Catch2, BSL-1.0) keeps its own license and is never relabelled; only GPL-3.0-compatible dependencies may be added.

## 2. C++

### 2.1 Language and layout

- C++23 in ISO mode (`-std=c++23`, never `gnu++23`).
- Sources live in `Cpp_implementation/src/<module>/`; the include root is `Cpp_implementation/src`, so includes read `#include "fbrt/fp_environment.hpp"`.
- File names are `snake_case.hpp` / `snake_case.cpp`.
- Everything is in namespace `gef`. FreeBASIC-runtime emulation is in `gef::fb` (directory `fbrt/`, CMake target `gef_fbrt`). Further modules follow strategy §2.8 (`data/`, `params/`, `physics/`, `run/`, `prepass/`, `tables/`, `event/`, `analysis/`, `output/`, `app/`); each milestone plan may refine it.
- Every target links the interface target `gef_exact_fp`, which carries the floating-point flags (§2.5).

### 2.2 Naming

| Entity | Style | Example |
|---|---|---|
| Types, enums, concepts | PascalCase | `FbMtRng`, `PGaussState`, `Emode` |
| Enumerators | PascalCase | `Emode::NeutronInduced` |
| Functions, variables, namespaces | snake_case | `u_mass`, `n_e_steps`, `gef::fb` |
| Private data members | snake_case with trailing `_` | `state_`, `cache_valid_` |
| Macros | UPPER_CASE | `GEF_ASSERT` |

Ported identifiers keep their BASIC name in snake_case where that stays readable (`E_tunn` → `e_tunn`, `Getyield` → `getyield`), so `fbdef` searches map back. When a better name is chosen, the provenance comment names the BASIC symbol.

### 2.3 Ownership, state and randomness

- **Value semantics and RAII.** Types are regular values by default. Resources (files, buffers) are owned by RAII objects; no owning raw pointers, no manual `new`/`delete`. Non-owning access uses references, `std::span` or `std::string_view`.
- **No mutable globals.** BASIC's shared and `Static` state lives in the explicit scope objects of strategy §2.4 (`ProcessState`, `SequenceFileState`, `SystemState`, `StepState`, `PassState`, `BinTables`, `Event`). A value that leaks across scopes in BASIC is an explicit field of the longer-lived scope and has a quirk-register entry. `const`/`constexpr` globals (tables, constants) are allowed.
- **Explicit `Rng&`.** Every function that consumes random numbers takes the generator as an explicit `Rng&` parameter. There is no hidden or default generator. Sampler caches (e.g. `PGaussState`) are explicit objects passed alongside it.
- **Order is fidelity.** Within a ported component keep BASIC's order of operations, accumulation order in `float`, and order of random draws. Restructure control flow (`GoTo` → loops), never arithmetic order (strategy §4).

### 2.4 Numeric types and conversions

- BASIC `Single` → `float`; BASIC `Double` → `double`. BASIC `Integer` (64-bit in fbc on x86-64) → `std::int64_t`; `Long` → `std::int32_t`; check the generated C (§5) when in doubt.
- Literals follow FreeBASIC typing: an unsuffixed BASIC literal with a decimal point is a `double`; write it as a `double` literal and convert explicitly where BASIC narrows.
- **Every Single/Double/integer conversion goes through the `gef::fb` helpers once M3 provides them** (`fb::cint` round-half-even, `fb::int_` floor, `fb::fix`, integer `\`, etc.).
- **Until M3 lands**, write such conversions as an explicit `static_cast` with a comment stating the FreeBASIC semantics being reproduced, for example:

  ```cpp
  // GEF.bas:8392 — division in double, narrowed to Single on assignment
  e_ratio = static_cast<float>(static_cast<double>(e_a) / e_b_double);
  ```

  These casts are replaced by `gef::fb` helpers when M3 closes.
- Never rely on implicit promotion or narrowing; the warnings in §2.5 make that a compile error.

### 2.5 Warnings, floating-point flags and static analysis

- **Warnings:** `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wdouble-promotion -Wshadow -Werror` on GCC and Clang.
  - `-Wconversion` and `-Wsign-conversion` reject silent narrowing between `double`, `float` and integer types; every such crossing must be written out, which is exactly where BASIC's `Single`/`Double` semantics live.
  - `-Wdouble-promotion` rejects silent `float` → `double` promotion, so a `float` expression cannot quietly be evaluated in `double` where BASIC computed in `Single` (and vice versa must be explicit).
- **Exact-mode floating-point flags** (`gef_exact_fp`): `-march=x86-64 -ffp-contract=off -fno-fast-math -frounding-math -fno-math-errno -fexcess-precision=standard`. They mirror the gcc flags fbc 1.10.1 uses and rule out FMA contraction. Never add `-ffast-math`, `-mfma`, `-ffp-contract=fast` or `-Ofast` to any target. The optimisation level is free unless M3/M5 tests show otherwise (M0 plan §2 note).
- Primary compiler GCC 16.2.1 (same backend and glibc libm as fbc); Clang 22 must also build warning-free.
- **`.clang-format` and `.clang-tidy` at the repository root are authoritative.** Format with `clang-format`; fix `clang-tidy` findings rather than suppressing them. A local `// NOLINT(check-name)` needs a reason on the same line.

### 2.6 Provenance comments

Every ported statement group carries a comment naming its BASIC source location, file name and line(s) as in the submodule at commit `ba9f0aa`:

```cpp
// GEF.bas:8392
// GEF.bas:7214-7219
// Spectra.bas:1505-1510
// ENDF.bas:1170
// NucProp_Functions.mac:28-49
```

- Format: `<file>:<line>` or `<file>:<first>-<last>`, file name relative to `Reference/GEF_code/source/`, plain ASCII hyphen for ranges. Included files are named by their own file and line, never by the `GEF.bas` line of the `#Include`.
- One comment per statement group (a contiguous BASIC block ported together), placed above it. A function ported whole gets the range of its body above its definition.
- Non-contiguous sources are comma-joined: `// GEF.bas:8129, 8152`.
- If C++ restructures control flow, the comment says so briefly: `// GEF.bas:4811-4830 (GoTo calcstart loop)`.

### 2.7 Quirk annotations and fidelity switches

- Code that reproduces an entry of `Planning/QUIRKS.md` carries `// QUIRK(Q-0xx)` next to its provenance comment, using the register's ID and a one-line summary. Illustrative form (the real ID comes from the register):

  ```cpp
  // GEF.bas:9417
  // QUIRK(Q-0xx): Egamma(N) = Egamma(N) + 1 is a no-op; heavy-fragment E1 gammas dropped
  ```

- A quirk without a register entry must not be annotated with an invented ID: add the entry first.
- Each quirk is behind a named switch in the `Fidelity` configuration (strategy §2.1), defaulting to "reproduce". Switch names are snake_case, describe the **corrected** behaviour and read as a boolean that is `false` by default: `fix_heavy_e1_gammas`, `fix_edefo_a_dimension`, `fix_uncertainty_cap`. The switch name is recorded in the quirk's register entry, and the register entry names the C++ symbol.
- Fixing a quirk (changing a default) is a separate, user-approved decision, never part of a porting milestone.

### 2.8 Tests

- Catch2 v3, tests in `Cpp_implementation/tests/<module>_test.cpp`.
- `TEST_CASE` names: `"<module>: <behaviour>"`, e.g. `"fbrt: rounding mode is to-nearest at start-up"`.
- Tags: one kind tag and, where relevant, a tier tag plus the module tag:
  - `[unit]` implementation tests;
  - `[T0]` … `[T5]` differential and integral tiers (vision §4.2; T2a/T2b both use `[T2]`, the name says which);
  - `[slow]` for anything over 10 s;
  - `[<module>]`, e.g. `[fbrt]`.

  Example: `TEST_CASE("fbrt: FbMtRng matches FreeBASIC stream", "[T2][fbrt]")`.
- CTest labels mirror the tags, so `ctest --preset dev-gcc -L T1` runs one tier.
- Tolerances are written down before the test is run; loosening one needs a recorded justification in the milestone plan (strategy §4).
- A test that closes a coverage-matrix cell is cited there by its `TEST_CASE` name.

## 3. Python

- Configuration is `pyproject.toml` at the root (do not fork it per package):
  - **ruff** lint and format, line length 100, rules `E,W,F,I,N,UP,B,SIM,PTH,RUF`;
  - **basedpyright strict** over `tools/` and `harness/` (and `compare/` when added);
  - **pytest**: `testpaths=["tools", "harness"]`, `pythonpath=["."]`, importlib import mode, `--strict-markers`.
- Markers: `fbc` (needs the pinned fbc), `slow` (over 10 s), `gdb` (needs gdb), `validation` (needs the gitignored `validation/` data). No other markers without adding them to `pyproject.toml`. Marked tests skip cleanly when their prerequisite is missing.
- Tools are packages run from the repository root: `python3 -m tools.<pkg>.<module> ...` or `python3 -m harness.<module> ...`. Each package has an `__init__.py` with the license notice.
- Tests live in `tools/<pkg>/tests/test_*.py` and `harness/tests/test_*.py`, with an `__init__.py`.
- fbc is located only through `tools/toolchain/fbc.py` (`resolve_fbc()`, env `GEF_FBC`); never hard-code its path elsewhere.
- Use `pathlib`, type annotations everywhere, and no mutable module-level state.
- Generated output goes only under `build/` (gitignored). Never write into `Reference/`, and never into `validation/` except through the documented manifest tools.

### 3.1 FreeBASIC harness code (patches and drivers)

- **The submodule is never edited.** BASIC changes are unified diffs in `harness/patches/`, applied to a copy by named patch sets (`harness/patchsets/`) in the canonical order `seed → scope → reseed → rndlog → probes`. A new patch takes its place in that order and must apply with `patch -p1 --fuzz=0` on top of its predecessors in every patch set that contains it (a pytest test checks this).
- **Keep `GEF.bas` line numbers.** Draw-site tags and probe locations use the original numbering. Put harness code in new `harness_<name>.bi` files; include them by replacing a blank line or appending to an existing line with `:`. If lines must be inserted, follow them with a `#line` directive that restores the numbering.
- **Neutral by construction.** Harness code only reads GEF state: no change to GEF variables, control flow, file numbers or the random stream. Optional features sit behind `#ifdef GEF_<NAME>` or an environment variable that is inert when unset. Every patch set is proven neutral with `harness.compare_runs` before it is used (plan M1, gate G3).
- **Check the generated C.** Use `python3 -m tools.fbsrc.emit_c --patch-dir build/harness/patchdirs/<set>` to confirm a patch changes only what it intends.
- **Drivers** live in `harness/drivers/<name>.bas`. They pull GEF code in only through `'@include-source` and `'@cut` directives, so `driver.json` records exactly which source lines a result depends on. Their outputs are stored with `harness.store`, never edited.
- **Output for comparison** is written as hex bit patterns (`Single` 8 digits, `Double` 16) or exact integers, never as rounded decimals.
- License notice per §1, with `'` comments; files containing GEF code also carry the GEF copyright line.

## 4. Commands that must stay clean

```sh
ruff check . && ruff format --check .
basedpyright
pytest
cmake --preset dev-gcc && cmake --build --preset dev-gcc && ctest --preset dev-gcc
scripts/ci.sh          # everything, in order (M0.10)
```

## 5. Establishing what a BASIC line computes

Do not infer BASIC semantics from reading the source alone. Use the M0.7 tools (see `tools/fbsrc/README.md`):

- `python3 -m tools.fbsrc.fbline GEF.bas:8392` — the BASIC line(s) and the C that fbc 1.10.1 generates for them (works for included files, e.g. `Spectra.bas:1505-1510`; flags `--context N`, `--raw`, `--symbols`). The generated C shows the evaluation precision, cast points and discarded calls.
- `python3 -m tools.fbsrc.fbdef <name>` — case-insensitive definition lookup (function, label, variable, type, constant); `--refs` lists all references.

When reading and the generated C disagree, the generated C (and ultimately the binary) is authoritative. Record any surprising semantics as a quirk.

## 6. Commit hygiene

- Commit only when the user asks. Agents never commit, push or rewrite git state on their own.
- Short commit messages: an imperative summary line under ~72 characters, optionally a short body.
- Nothing under `build/`, `validation/` or `.omp/` is committed; `Reference/` changes only through submodule updates the user requests.
