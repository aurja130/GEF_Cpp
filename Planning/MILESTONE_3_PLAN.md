# Milestone 3: FreeBASIC Runtime Emulation

**Status:** in progress (M3.1–M3.7 done, 2026-10-09)
**Strategy reference:** `IMPLEMENTATION_STRATEGY.md` §2.2, §2.3, §2.9 and §3, M3
**Depends on:** M0, M1 (driver framework, `fbmt.py`, reseed vectors), M2 (exact comparison)
**Unblocks:** M4 (data layer uses `DataReader`, arrays, conversions), M5 (physics functions use the maths intrinsics), M8 (samplers use `FbMtRng`), M13 (writers use the text formatting), and through them every later milestone

## 1. Goal

A C++ library, `gef_fbrt` (namespace `gef::fb`), that behaves **bit for bit** like the FreeBASIC 1.10.1 runtime and fbc's code generation wherever GEF depends on them. Under the exact-first decision (strategy §2.9), every later milestone builds on this layer and must reproduce BASIC exactly, so the layer itself is proven exhaustively where the domain allows it and against FreeBASIC driver programs everywhere else.

The milestone also settles the three open build questions on which exact reproduction depends:
- **B-001:** does the optimisation level change results?
- **B-002:** where does integer overflow wrap?
- **B-004:** how does fbc fold and reorder arithmetic?

**Exit:** no later milestone needs its own conversion, rounding, maths-intrinsic, random-number, formatting, array or `DATA` code.

## 2. Decisions taken in this plan

| ID | Topic | Decision | Reason |
|---|---|---|---|
| D1 | Reference outputs | FreeBASIC driver outputs up to about 1 MB are committed under `Cpp_implementation/tests/golden/`, each with its `driver.json` (driver source hash, fbc version, cut ranges). Larger ones, e.g. 20 seeds × 10⁶ draws, go into the reference store. C++ tests that need the store skip with a message when it is absent. A pytest checks that every committed golden still matches its driver's current source hash | User decision (2026-10-08). The C++ tests run anywhere; big data stays out of git |
| D2 | Text formatting coverage | The generic machinery (`Str`, `Print`, `Print Using`, `Format`) **and** a complete inventory of the templates GEF uses. Every distinct template is tested over edge-value grids | User decision (2026-10-08). The writers of M13 then only compose proven pieces |
| D3 | Arrays | A small custom type `fb::Array<T, N>`: arbitrary lower bounds, row-major, `ReDim`/`ReDim Preserve`/`Erase`/`LBound`/`UBound` semantics, and GEF's `Extend_1dim/2dim/3dim` growth | User decision (2026-10-08). Arbitrary bounds and growth are central to GEF's histograms; `std::mdspan` would need the same wrapper anyway |
| D4 | How runtime behaviour is ported | Transcribe from the fbc 1.10.1 sources (`src/rtlib`, tag `1.10.1`), as `harness/fbmt.py` already did for the generator. Behaviour is proven by drivers, never by reading alone. The runtime library is LGPL-2.0-or-later with a static-linking exception, which allows use under GPL-3.0-or-later. Transcribed files carry the line `Ported from the FreeBASIC 1.10.1 runtime library, Copyright (C) the FreeBASIC development team (LGPL-2.0-or-later).` after our notice. The same line is added to `harness/fbmt.py` | Exactness requires the same algorithm, not a look-alike. Linking `libfb` itself was rejected: it would tie the C++ code to an fbc build and to FreeBASIC's string and array ABI |
| D5 | Maths intrinsics | `gef::fb` wraps every BASIC intrinsic, per argument type, around the exact C function fbc emits. Examples: `Exp(Single)` → `expf`, `Exp(Double)` → `exp`, `Sqr(Single)` → `sqrtf`, `x^n` → `pow(double, double)`, `Single^2` → `x*x` in `float`. The mapping table is derived from the generated C and lives in the library. GEF's own `Erf`, `Erfc`, `Tanh`, `Coth`, `Log10`, `Min`, `Max` (`utilities.bi`) and `Floor`, `Ceil`, `Round`, `Modulo` (`GEF.bas`) are ported as written | Same function, same precision, same libm, so the same bits. Some names that look alike differ in GEF (`Min`/`Max` take `Single`, so integer arguments pass through `float`) |
| D6 | Exhaustive testing | Where the input domain is one `Single` (2³² bit patterns), the driver and the C++ test both run over **all** patterns and compare a rolling hash of the result bits. On a mismatch a bisection mode prints the first differing input. Two-argument and `Double` functions use dense edge grids plus 10⁶ pseudo-random inputs drawn with `FbMtRng`, so driver and test draw the same values | The golden stays small while the evidence covers the whole domain. Bisection locates any difference in seconds |
| D7 | Optimisation level (B-001) | Every T1 test of this milestone runs in all presets, including `release-exact` (`-O3`). A difference from the driver at any optimisation level is a defect. The fix is local (`#pragma GCC optimize`, `[[gnu::optimize]]` or a separate `-O0` translation unit, chosen by evidence) and recorded in `QUIRKS.md` B-001 | Exact mode must hold in the build that will be optimised later. Restricting fixes to proven cases keeps the rest of the code optimisable |
| D8 | Integer semantics (B-002) | FreeBASIC `Integer` is 64-bit (`int64` in GEF.c), `Long` 32-bit. Conversions follow fbc exactly (`fb_F2L`/`fb_D2L` round with the current rounding mode, `Fix` truncates, `\` rounds its operands, `Modulo` uses `ULongInt`). Every operation that can overflow is written so that it wraps in two's complement as `-fwrapv` makes it: unsigned arithmetic, then conversion. UBSan in `asan-ubsan` proves no signed overflow remains | C++ signed overflow is undefined behaviour; BASIC's is defined wrapping |
| D9 | Expression reordering (B-004) | Characterise fbc's constant folding and reassociation with small probe programs, read through `tools.fbsrc.emit_c`, and document the rules in `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` with examples. The porting rule stays: port arithmetic from the `fbline` output of each statement (coding standards §5). The document says when that rule matters and how to write the C++ so the compiler keeps the order | Only the generated C is authoritative; the rules make porting predictable and reviewable |
| D10 | Random numbers | `FbMtRng` (fbc's `Randomize s,3` + `Rnd`) and the per-event reseed derivation of `harness/RESEED_SPEC.md` are both built here. `PGaussState` and the samplers stay in M8 | The reseed mode is part of the generator contract; M8 builds samplers on top |
| D11 | Numeric text input | `Val`, `ValLng` and the numeric parts of `Input #` (Single, Double, Integer) are emulated here. Other string functions (`Instr`, `Trim`, `Mid`, …) are left to M6, which ports the parser | Number parsing is runtime numeric semantics and decides parameter values bit for bit; plain string slicing is not |
| D12 | `DATA` | `DataReader` reproduces `Restore` (to a label), `Read` into `Single`/`Double`/`Integer`/`String` (with fbc's string-to-number conversion), reads that cross label boundaries, and the value at the end of the data. It consumes a token stream; M4's converter produces the real one from the GEF sources. M3 tests it with drivers whose `DATA` is written for the test | Separates runtime semantics (M3) from GEF's tables (M4) |

## 3. Facts established while planning (2026-10-08)

From the generated C (`build/fbsrc/ba9f0aa/src/GEF.c`) and the sources at `ba9f0aa`:

| Runtime area | What GEF uses |
|---|---|
| Text output | `fb_PrintString` 5,107 calls, `fb_PrintSingle` 2,225, `fb_PrintLongint` 667, `fb_PrintDouble` 290, `fb_PrintTab` 2; `Str()` via `fb_FloatToStr` 52 and `fb_LongintToStr` 157 |
| `Print Using` | 130 statements, about 40 distinct templates. Values are `Single` (80), `Double` (69), `Longint` (55) and `String` (20, `&` fields). Examples: `"####.### "`, `"####    ###.######"`, `"& ### & ###"`, `"     ##########    ##########      Overflow"` |
| `Format` | 33 calls, 4 patterns: `"dd.mm.yyyy, hh:mm:ss"` (29, time stamps), `"-0.00000E+00"` and `"-0.000000E+0"` (ENDF), `"#####"` |
| Conversions | `fb_F2L` 573, `fb_D2L` 103, `fb_D2UL` 32, `fb_FIXDouble` 23, `fb_SGNSingle` 3, `__builtin_nearbyint` 2 |
| Maths | `Single` arguments go to single-precision libm: `expf` 72, `sqrtf` 70, `floorf` 40, `fabsf` 42, `logf` 11. `Double` arguments go to double precision: `sqrt` about 150, `exp` about 100, `log` about 30, `floor` 28, `cos` 42, `sin` 4. `^` goes to `pow(double, double)`, 459 calls. `Single^2` becomes `x*x` in `float` (e.g. `GEF.bas:3797`); a non-variable base with `^2` goes to `pow` (`GEF.bas:3793`) |
| Random numbers | `fb_Rnd` at 60 sites, `fb_Randomize` twice. Python reference `harness/fbmt.py`; golden stream `m1-golden-rnd-stream-42` |
| Arrays | `fb_ArrayRedimEx` 601, `fb_ArrayRedimPresvEx` 25, `fb_ArrayErase` 481, `fb_ArrayUBound` 699, `fb_ArrayLBound` 516. `Extend_1dim/2dim/3dim` (`utilities.bi:269–372`) copy through a work array and pass `Integer` bounds through the `Single`-typed `Min`/`Max` |
| `DATA` | `fb_DataRestore` 2,136, `fb_DataReadSingle` 529, `fb_DataReadLongint` 213, `fb_DataReadStr` 4, `fb_DataReadDouble` 2 |
| Numeric input | `fb_VAL` 61, `fb_VALLNG` 20; `Input #` of Single 14, Longint 17, Double 4, String 34 |
| GEF's own helpers | `utilities.bi`: `Min`, `Max`, `Erf`, `Erfc`, `Tanh`, `Coth`, `Log10` (all `Single`), `ShellSort1`, `ShellSort3`. `GEF.bas`: `Floor` (18052), `Ceil` (18056), `Round` (18064), `Modulo` (18084, `ULongInt`) |
| Not emulated | Console and graphics (`fb_Gfx*`, `fb_Locate`, `fb_Cls`, `fb_Inkey`, `fb_Sleep`), `fb_Shell`, `fb_ChDir`: not ported (vision §3) or replaced natively (M13, M16) |
| Licensing | fbc rtlib: LGPL-2.0-or-later with a static-linking exception (`readme.txt` at tag `1.10.1`) |

## 4. Work breakdown

Tasks in execution order. Mark each one done here when finished, and update `CURRENT_PROJECT_STATE.md` (see `.omp/AGENTS.md`).

### M3.1 Golden-file workflow and library layout
- [x] `python3 -m harness.golden promote <driver> --name NAME [-- args]`: runs a driver with `harness.driver` and copies its outputs and `driver.json` to `Cpp_implementation/tests/golden/<name>/`, or to the reference store when over 1 MB (D1).
- [x] A pytest checks every committed golden against the current driver source hash and fbc version. A stale golden fails CI. (`harness.golden check`, `harness/tests/test_golden.py`; it also checks included and cut GEF sources and each output's hash.)
- [x] C++ test support: a small reader for golden files (hex and decimal records) and a store-path resolver that `SKIP`s when the store is absent. (`Cpp_implementation/tests/support/golden.hpp`.)
- [x] Library layout under `Cpp_implementation/src/fbrt/`: `convert`, `math`, `rng`, `reseed`, `text` (`str`, `print`, `print_using`, `format`), `array`, `data_reader`, `input`, one header and source each, plus `FBC_ARITHMETIC.md`. Licence lines per D4. Also add the rtlib copyright line to `harness/fbmt.py`. (Each file is created by the task that fills it, never as an empty stub; `rng` and `reseed` exist. The rtlib line is two comment lines, wrapped by clang-format.)

**Done when:** a trivial driver round-trips through `promote` and is read by a Catch2 test in all presets.

### M3.2 fbc arithmetic semantics (B-004)
- [x] Probe programs for literal typing (`Single`/`Double` literals, suffixes), mixed-type promotion, `/` vs `\`, constant folding, reassociation of `*` and `+` chains with literals, unary minus, comparisons between `Single` and `Double`, and the `^` special cases. Each probe is read through `emit_c`, and every rule found is confirmed by running it. (Probes `tools/fbsrc/probes/arith_probe1–3.bas`, read with `fbc -gen gcc -r` because `emit_c` translates GEF only. The run is the driver `arith_rules.bas`: 18 expressions, one or more per rule, over 2,000 input sets drawn with `Randomize 1, 3`, golden `m3-arith-rules`.)
- [x] `FBC_ARITHMETIC.md`: the rules, each with a BASIC example, the generated C and the C++ that reproduces it. Plus guidance for writing C++ that the compiler will not reorder (no `-ffast-math`, explicit temporaries where fbc introduces them). (Rules R1–R8; the C++ for each driver expression is in `fbc_arithmetic_test.cpp`, which passes in `dev-gcc`, `dev-clang` and `release-exact`. New finding beyond the plan: fbc also drops parentheses in `*`/`+` chains without literals.)
- [x] Update `QUIRKS.md` B-004 with the established rules.

**Done when:** every rule in the document is backed by a probe whose generated C and run-time output are recorded.

### M3.3 Conversions and integer semantics (B-002)
- [x] `fb::cint`, `fb::clng`, `fb::cuint` (each matching `fb_F2L`, `fb_D2L`, `fb_D2UL`), `fb::int_` (floor), `fb::fix`, `fb::sgn`, integer `\` and `Mod`, and implicit `Single`↔`Double`↔integer conversions on assignment. (Named after the generated C instead, so ported statements map one to one: `fb::f2i`, `f2l`, `f2ul`, `d2i`, `d2l`, `d2ul`, `fix`, `sgn` (Single, Double, Integer), `idiv`, `imod`. No `int_`: fbc emits plain `floorf`/`floor` for `Int`, which M3.4 covers. Narrower targets (`Short`, `UByte`, `ULong`) are a C cast of `f2i`/`d2i`/`d2l` (`(uint32)fb_D2L(D)`), and integer-to-float conversions are plain casts.)
- [x] Wrapping arithmetic helpers for the operations where GEF's integers can overflow (D8). (`fb::add/sub/mul/neg/abs`, `Integer` and `Long`.)
- [x] Exhaustive tests over all `Single` patterns for the `Single`-argument conversions (D6). `Double` conversions get edge grids (±0, halves, 2⁵², 2⁶³ boundaries, NaN, ±Inf, denormals) plus 10⁶ random values. Out-of-range and NaN behaviour reproduces what the driver prints. (Drivers `conv_single.bas`, `conv_double.bas`, `int_ops.bas`; goldens `m3-conv-single` (hashes of 256 blocks of 2²⁴ patterns), `m3-conv-double` (57 grid values, 2²⁰ random bit patterns), `m3-int-ops`; tests in `conversion_test.cpp`. The exhaustive test takes 132 s in `dev-gcc` and 31 s in `release-exact`; it is tagged `[slow]`, which the sanitizer test presets and `ci.sh --quick` skip. One `-O3` difference was found and fixed in `fb::fix`, see `QUIRKS.md` B-001.)

**Done when:** all conversion tests are bit-exact in every preset.

### M3.4 Maths intrinsics and GEF helpers (B-001)
- [x] The intrinsic mapping table (D5), generated from the GEF.c inventory, with one wrapper per (intrinsic, argument type). (Deviation: no wrappers. The `std::` overload for the argument type is the libm function fbc emits, and the warning set rejects type changes; the mapping table is `FBC_ARITHMETIC.md` R7.)
- [x] Ports of `Min`, `Max`, `Erf`, `Erfc`, `Tanh`, `Coth`, `Log10`, `Floor`, `Ceil`, `Round`, `Modulo`, `ShellSort1`, `ShellSort3`, cut from the sources by the driver `'@cut` directive so the driver runs GEF's own code. (`fbrt/gef_math.hpp`, each from its generated C, including fbc's branch polarity. `ShellSort1/3` dropped: defined in `utilities.bi` but never called by GEF. The drivers `'@include-source utilities.bi` and `'@cut GEF.bas:18052-18089`.)
- [x] Exhaustive single-argument `Single` tests (`expf`, `logf`, `sqrtf`, `floorf`, `fabsf`, `Erf`, `Tanh`, `Log10`, …). `Double` and two-argument functions (`pow`, `Round(R, N)`, `Min`/`Max`) get grids plus random inputs (D6). (Drivers `math_single.bas` (14 functions × 2³²; 6 min), `math_double.bas`, `gef_math2.bas`; goldens `m3-math-single`, `m3-math-double`, `m3-gef-math2`; `maths_test.cpp`, whose exhaustive test runs the 256 blocks on all cores: 135 s in Debug, 41 s in `release-exact`.)
- [x] **B-001 experiment:** the full set in `dev-gcc`, `dev-clang` and `release-exact`, reporting any difference by function and preset. Record the outcome and any per-function fix in `QUIRKS.md` B-001. (No non-NaN difference anywhere. NaN sign and payload differ by compiler and optimisation level: `floor` in g++ Debug and at `-O3`, `Erf` in clang, `Erfc` at `-O3`. By user decision all NaNs compare equal; the drivers hash NaN results as the canonical NaN. With that, all 31 test cases pass in all three presets. `QUIRKS.md` B-001 finding 2.)

**Done when:** every intrinsic and helper is bit-exact against its driver in every preset, and B-001 is resolved for this layer.

### M3.5 Random numbers and reseed mode
- [x] `fb::FbMtRng`: `randomize(seed)`, `rnd()` returning the same `double` as fbc, and `next_u32()`. Transcribed from `math_rnd.c` (D4); the state is explicit, with no globals. (Also: `Rnd(0)` repeats the last value, other arguments draw; the lazy start-up equals seed 0; `randomize_seed_bits` reproduces the runtime's `(uint32_t)seed` cast, including fractions, negatives, values outside int64 and NaN/±Inf, which all give seed 0; `Randomize -1`, the clock seed, is rejected.)
- [x] `fb::derive_seed(master, scope, tuple…)` and the reseed procedure of `harness/RESEED_SPEC.md`, with its test vectors. (`fb::reseed` re-seeds; clearing the `PGauss` cache is M8's.)
- [x] Tests (`Cpp_implementation/tests/rng_test.cpp`):
  - `m1-golden-rnd-stream-42`;
  - 20 seeds × 10⁶ draws, stored as `m3-rnd-seeds-1e6`, including seeds 0, 1, 2³¹−1, 2³¹ and 2³²−1. They come from a new driver `rnd_seeds.bas` rather than `rnd_stream`, so one run covers all seeds;
  - 22 edge seeds × 1,300 draws (two state regenerations), the `Rnd(n)` argument sequence and the pre-`Randomize` stream, committed as golden `m3-rnd-seeds-edge`;
  - the reseed vectors of `harness/reseed.py`.

  The 21 × 10⁶ stored values take 2.4 s in `release-exact` and 4 s in `dev-gcc`, including reading the files.

**Done when:** all streams and vectors are bit-exact, and the 10⁶-draw test runs in under a second in `release-exact`.

### M3.6 Text formatting
- [x] Inventory script (`python3 -m tools.fbsrc.fb_templates`): lists every `Print Using` template and `Format` pattern in GEF.c with its argument types and BASIC locations. The output is committed as the coverage list. (`Cpp_implementation/src/fbrt/TEMPLATES.md`: 39 templates in 130 statements, items Single 79, Double 68, Longint 54, Str 19 (the planning count included prototypes); 4 `Format` patterns. One statement has more items than fields, `GEF.bas:12292`, registered as `QUIRKS.md` Q-031.)
- [x] `fb::str` (`Single`, `Double`, `Integer`), the `Print` number formatting (leading space for non-negatives, `Single` with 7 significant digits, `Double` with 15–16, exponent forms), comma zones, `;`, `Tab`, and line endings. (M3.6a, `fbrt/text.hpp`: `fb::str` and `fb::PrintFile`, transcribed from `str_convto_flt.c`, `str_ftoa.c`, `io_print*.c`, `io_printpad.c`, `io_spc.c`, `file_put.c`. `Single` prints with `%.7g`, `Double` with `%.16g`.)
- [x] `fb::print_using(template, args…)`: the full template machinery (`#`, `.`, `,`, `+`, `-`, `**`, `$$`, `^^^^`, `&`, `!`, `\ \`, literal text, `_` escapes, `%` overflow marker), transcribed from the runtime. (M3.6b: `PrintFile::using_init/using_print/using_end` in `print_using.cpp`, from `io_printusg.c`; the `Wstr`, `Boolean` and `ULongint` variants are not used by GEF and not ported.)
- [x] `fb::format(value, pattern)`: the numeric patterns GEF uses, plus the date pattern driven by an explicit time value, so tests are deterministic. (M3.6b: `fbrt/format.hpp`, the full numeric path of `str_format.c` and the date/time path for `dd.mm.yyyy, hh:mm:ss` on a date serial. Three runtime cases are undefined or hang in C and are not reproduced: `+Inf` with an exponent pattern loops forever, |x| ≥ 1e19 with a non-exponent pattern overflows a 128-byte buffer, and NaN/Inf cast to an unsigned integer.)
- [x] Tests: for every template and pattern in the inventory, a driver output over edge grids (±0, rounding halves at each printed digit, powers of ten across the representable range, values that overflow the field, NaN, ±Inf, denormals, large integers). Generic `Str`/`Print` tests over exhaustive `Single` patterns via hashing (D6) and `Double` grids. (`Str`/`Print` part done in M3.6a: drivers `str_single.bas` (all 2³² `Single`, 14 min), `str_numbers.bas` (grids and 2²⁰ random and moderate `Double`, `Integer`), `print_file.bas` (19 `Print #` statements with zones, trailing `;`/`,`, `Tab` backwards and to column 60, embedded LF); goldens `m3-str-single`, `m3-str-numbers`, `m3-print-file`; `text_test.cpp` passes in `dev-gcc`, `dev-clang` and `release-exact`. The exhaustive test takes 235–370 s on all cores. M3.6b: driver `print_using.bas`, 5,719 statements over all 39 GEF templates and the generic template features, golden `m3-print-using`, `print_using_test.cpp`; driver `format.bas`, 7,271 calls, golden `m3-format`, `format_test.cpp`; all byte-exact in `dev-gcc`, `dev-clang` and `release-exact`. Excluded from the driver because the runtime reads undefined memory there, and GEF never does it: more items than template fields (template reuse), and an empty string in a `!` or `\ \` field.)

**Done when:** every inventoried template is byte-exact over its grid, and `Str`/`Print` of `Single` is exact for all 2³² patterns.

### M3.7 Arrays
- [x] `fb::Array<T, N>`, N ≤ 6: bounds as written (`ReDim a(lo To hi, …)`), row-major element order, zero-initialised `ReDim`, `ReDim Preserve` (the 25 GEF uses), `Erase`, `LBound`/`UBound` including the dimension-0 and out-of-range dimension results that `QUIRKS.md` Q-004 and Q-027 depend on. (`fbrt/array.hpp`, `fb::Array<T, rank>`, rank 1–8 as in FreeBASIC; GEF uses up to 4. From `array_redim.c`, `array_redimpresv.c`, `array_erase.c`, `array_lbound.c`, `array_ubound.c`: `ReDim Preserve` keeps the elements' linear order, so multi-dimensional elements move; `ReDim` with lbound > ubound leaves the array erased and `ReDim Preserve` leaves it unchanged, as the runtime's ignored error does. Element access is bounds-checked in every build and throws `std::out_of_range` (user decision 2026-10-09).)
- [x] `fb::extend_1dim/2dim/3dim`, as written, including the round trip of the bounds through `Single` `Min`/`Max`. (`fbrt/extend.hpp`. An unallocated array counts as `0 To -1`, so the result includes index 0; bounds beyond 2²⁴ are rounded through `Single`, e.g. 16777219 becomes 16777220.)
- [x] Tests against drivers: growth sequences (bounds and contents after each step), `Preserve` behaviour on multi-dimensional arrays, `UBound(a, d)` for d = 0…N+1. (Driver `arrays.bas`: 56 operations on 1-, 2-, 3-dimensional `Double` and a `String` array, with the state after each; golden `m3-arrays`; `array_test.cpp` matches every state in `dev-gcc`, `dev-clang` and `release-exact`.)

**Done when:** every sequence matches the driver.

### M3.8 `DATA` reader and numeric input
- [ ] `fb::DataReader` over a token stream (D12): `restore(label)`, `read<T>()` for `Single`, `Double`, `Integer` and `String`. Number tokens are converted the way fbc does (`DataReadSingle` narrows from the text, not from a `Double`). Reads cross labels and continue past the end exactly as the driver shows.
- [ ] `fb::val`, `fb::vallng` and the numeric `Input #` parsing (D11): separators, leading signs and spaces, `d`/`e` exponents, `&H`/`&O`/`&B` prefixes, trailing garbage, empty fields.
- [ ] Tests: drivers with purpose-written `DATA` blocks and input files, covering each behaviour above, with byte-exact comparison of the read values (hex bit patterns).

**Done when:** every driver scenario is reproduced.

### M3.9 CI, documentation and close-out
- [ ] All new tests are tagged `[T1]` or `[T2]` and `[fbrt]`; the exhaustive ones are also tagged `[slow]` if over 10 s. CTest labels mirror the tags.
- [x] `scripts/ci.sh` gains a `release-exact` build-and-test step (today it builds `dev-gcc`, `dev-clang`, `asan-ubsan` and `tsan`), so the D7 check runs in CI. The full run includes the store-backed and `[slow]` tests; `--quick` excludes them. (Done in M3.3. `--quick` excludes `[slow]`; store-backed tests stay in, as they take about 2 s. The sanitizer test presets also exclude `[slow]`: the exhaustive `Single` loop is pure arithmetic and already runs in `dev-gcc`, `dev-clang` and `release-exact`. This narrows G1's "all presets" to the three non-sanitizer presets for the `[slow]` tests.)
- [x] `CODING_STANDARDS.md`: the `gef::fb` helpers become mandatory for conversions (replacing the M0 interim `static_cast` rule), with a pointer to `FBC_ARITHMETIC.md`. (Done in M3.3, §2.4.)
- [ ] `QUIRKS.md` (B-001, B-002, B-004, plus any new runtime quirk), `COVERAGE_MATRIX.md` (the "FreeBASIC numeric semantics" row and the T2 random-number cells close here), `IMPLEMENTATION_STRATEGY.md` (M3 status and any refinement), `CURRENT_PROJECT_STATE.md`. Mark this plan complete.

## 5. Exit gate (all must hold)

| Gate | Requirement |
|---|---|
| G1 Conversions | Every conversion helper is bit-exact against its driver: exhaustively over all `Single` patterns for single-argument `Single` conversions, over edge grids and 10⁶ random values otherwise. Holds in all presets |
| G2 Maths | Every intrinsic wrapper and GEF helper is bit-exact against its driver under the same test domains as G1, in `dev-gcc`, `dev-clang` and `release-exact`. B-001 is resolved for this layer and recorded |
| G3 Random numbers | `FbMtRng` reproduces the golden stream and 20 stored seeds × 10⁶ draws, including the seed edge values. The reseed derivation reproduces every vector of `harness/reseed.py` |
| G4 Text | `Str`/`Print` of `Single` is exact for all 2³² patterns. Every `Print Using` template and `Format` pattern in the inventory is byte-exact over its edge grid |
| G5 Arrays | Growth, `Preserve`, `Erase` and bound sequences match the drivers, including `UBound(a, d)` for out-of-range d |
| G6 `DATA` and input | Every `DataReader`, `Val` and `Input #` scenario reproduces the driver's values bit for bit |
| G7 B-002, B-004 | `FBC_ARITHMETIC.md` exists with probe evidence for every rule. `asan-ubsan` reports no signed overflow in the library or its tests |
| G8 CI | `scripts/ci.sh` passes with all five presets (`dev-gcc`, `dev-clang`, `asan-ubsan`, `tsan`, `release-exact`); clang-tidy and clang-format are clean; committed goldens are current |

## 6. Out of scope (later milestones)

- `PGauss` and the other samplers (M8); per-nucleus physics functions (M5), although they will use the M3 intrinsics.
- The `DATA` converter for GEF's real tables (M4).
- String functions beyond numeric parsing, and the input-file grammar (M6).
- File handling, append semantics and the writers that compose the formatting (M13).
- Console, graphics, `Shell`, `ChDir` and multi-process locking: not ported, or replaced natively.

## 7. Risks and open questions

| Item | Handling |
|---|---|
| An optimisation level changes a libm call's result (B-001) | Detected by G2 in `release-exact`. A local fix (D7) is applied only where evidence shows it is needed, and recorded |
| glibc `expf`/`logf`/`pow` change between glibc versions | Exact mode is defined on the pinned platform (strategy §5). `manifests/toolchain.txt` records glibc 2.43, and the toolchain check flags drift |
| Exhaustive driver runs are slow (2³² iterations of fbc `-O0` code) | Driver runs are one-off; only the hash is stored. If a run exceeds about 30 min, split the domain across processes |
| `Print Using` corner cases not visible in GEF's templates (e.g. `**`, `$$`) | Implemented by transcription and tested generically, but only GEF's templates are gating. Others are marked unverified in the source |
| fbc's string-to-number conversion for `DATA` and `Val` differs from `strtod` | Transcribed from the runtime and tested with edge tokens. This is where M4's table values come from, so G6 is strict |
| Transcribed LGPL code mixed into GPL files | Kept to the `fbrt/` files, with the rtlib copyright line (D4) |

## 8. Completion notes

*(Filled in when M3 closes: dates, exhaustive-run timings, B-001/B-002/B-004 outcomes, template inventory size, deviations from this plan.)*
