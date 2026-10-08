# How fbc 1.10.1 compiles GEF's arithmetic

GEF's BASIC is compiled by fbc 1.10.1 to C, and gcc compiles that C. fbc does not translate an expression as written: it types and converts the operands while parsing, then rewrites the expression tree (it reassociates and folds constants). Floating-point arithmetic is not associative, so the C++ port must reproduce the expression **as fbc emits it**, not as the BASIC reads.

**Porting rule** (coding standards §5): port every arithmetic statement from its generated C (`python3 -m tools.fbsrc.fbline <file>:<line>`). The rules below explain that C and make it predictable; they do not replace looking at it.

**Evidence:**
- Probe programs `tools/fbsrc/probes/arith_probe1.bas`–`arith_probe3.bas`; `fbc -gen gcc -r` writes their C next to them (M3.2, 2026-10-08). Every "Generated C" cell below is quoted from that output.
- The driver `harness/drivers/arith_rules.bas` evaluates one example per rule over 2,000 random input sets. Its output is the committed golden `m3-arith-rules`.
- `Cpp_implementation/tests/fbc_arithmetic_test.cpp` writes each example the way these rules say and reproduces every result bit for bit, in `dev-gcc`, `dev-clang` and `release-exact` (`-O3`).

In the C below, `S`, `T`, `U`, `V` are `Single` (`float`), `D`, `E`, `F` are `Double`, and `I`, `J` are `Integer` (`int64`). Hex literals are fbc's.

## R1 Literal and operand types

| BASIC | Generated C | Rule |
|---|---|---|
| `s * 0.1` | `(double)S * 0x1.999999999999Ap-4` | A literal with a decimal point or exponent is `Double` |
| `s * 1.5!`, `s * 0.1F` | `S * 0x1.8p+0f` | `!`/`F` suffix: `Single` |
| `s * t * 2`, `s + 1`, `1 - s` | `(S * T) * 0x1.p+1f`, `S + 0x1.p+0f` | An integer literal takes the type of the floating operand (`Single` here, `Double` next to a `Double`) |
| `s / 3`, `s * t / 2 * u` | `(double)S / 0x1.8p+1`, `((double)(S*T) / 0x1.p+1) * (double)U` | …except as a `/` operand, where it is `Double`, so the quotient is `Double` |
| `s * i`, `s * l` | `S * (float)I`, `S * (float)(int64)L` | `Integer`/`Long` next to a `Single` converts to `Single` |
| `i * 0.5`, `i / j` | `(double)I * 0x1.p-1`, `(double)I / (double)J` | …next to a `Double`, to `Double`; `/` is always floating |

## R2 Mixed precision is decided per operation, left to right, while parsing

A binary operation on a `Single` and a `Double` converts the `Single` to `double` and yields `Double`. An operation on two `Single`s stays `Single`. The result is narrowed only on assignment or when passed to a `Single` parameter.

| BASIC | Generated C |
|---|---|
| `r = s * d` | `R = (float)((double)S * D)` |
| `r = s * t + u * 0.5` | `R = (float)((double)(S * T) + ((double)U * 0x1.p-1))`: `S * T` is a `Single` product |
| `rd = s * t` | `RD = (double)(S * T)` |
| `rd = s + 0.1` | `RD = (double)S + 0x1.999999999999Ap-4` |
| `r = F(s * 0.1)` (`ByVal x As Single`) | `F((float)((double)S * 0x1.999999999999Ap-4))` |
| `If s < 0.1`, `If s < d` | `(double)S >= 0x1.999999999999Ap-4`, `(double)S >= D` (compared in `Double`) |

## R3 `/` of two `Single`s is a `Single` quotient

`s / t * u` → `(float)((double)S / (double)T) * U`. The division is done in `double` and narrowed at once, which gives the same bits as a `float` division (`double` carries more than 2·24 + 2 bits). Port it as `s / t` in `float` or as written; both are exact. Chains of `/` keep their order and narrow each quotient: `s / t / u` → `(float)((double)(float)((double)S / (double)T) / (double)U)`.

## R4 Literals of a `*` or `+` chain are folded and moved to the end (B-004)

After R1 and R2 have fixed every operand's conversion, fbc collects the numeric literals of each chain of `*` (or of `+`), folds them into one constant in the chain's type, and applies it **last**. The other operands keep their order and their conversions.

| BASIC | Generated C |
|---|---|
| `s * 0.1 * t` | `(float)(((double)S * (double)T) * 0x1.999999999999Ap-4)` |
| `0.1 * s * t * u` | `(float)((((double)S * (double)T) * (double)U) * 0x1.999999999999Ap-4)` |
| `s * 0.1 * t * 0.2 * u` | `(float)((((double)S * (double)T) * (double)U) * 0x1.47AE147AE147Cp-6)` (0.1 · 0.2 folded in `Double`) |
| `s * 2.0 * 3.0`, `2.0 * s * 3.0` | `(float)((double)S * 0x1.8p+2)` |
| `2 * s * 3` | `S * 0x1.8p+2f` (integer literals, `Single` chain) |
| `s * 1e-3 * t * 1e3` | `(float)(((double)S * (double)T) * 0x1.p+0)`: the folded 1.0 is still multiplied |
| `s + 0.1 + t`, `d + 0.1 + e + 0.2` | `(float)(((double)S + (double)T) + 0x1.999999999999Ap-4)`, `(D + E) + 0x1.3333333333334p-2` |
| `s - 0.1 - t` | `(float)(((double)S + -0x1.999999999999Ap-4) - (double)T)`: a subtracted literal becomes an added negative one; `- t` ends the `+` chain |
| `s * -0.5 * t` | `(float)(((double)S * (double)T) * -0x1.p-1)` |
| `s * t - 0.1 * u` | `(float)((double)(S * T) - ((double)U * 0x1.999999999999Ap-4))`: the literal moves to the end of its own product |
| `s / 0.5 * t` | `(float)(((double)S / 0x1.p-1) * (double)T)`: a literal never moves across `/` |
| `s * Exp(t) * 0.5`, `Sqr(s) * 0.5 * t` | `(float)((double)(S * expf(T)) * 0x1.p-1)`, `(float)(((double)sqrtf(S) * (double)T) * 0x1.p-1)`: calls are ordinary operands |

Constants that fbc folds on their own are folded in `Double` and then rounded to the target type: `r = 1 / 3` → `0x1.555556p-2f`, `r = 0.1 + 0.2` → `0x1.333334p-2f`.

**Effect:** for chains that end narrowed to `Single`, the reorder rarely changes the result, because `double` hides the rounding difference (E1–E4: 0 of 2,000 inputs differ from left-to-right evaluation). For `Double` chains it often does: `d * 0.1 * e` differs from `(d * 0.1) * e` for 824 of 2,000 inputs, `d + 0.1 + e + 0.2` for 697.

## R5 Parentheses around `*`, `+` and `-` are not respected

fbc re-associates `*` and `+` chains to the left even without literals, and distributes a parenthesised difference:

| BASIC | Generated C |
|---|---|
| `s * (t * u)`, `d * (e * f)` | `(S * T) * U`, `(D * E) * F` |
| `s + (t + u)`, `d + (e + f)` | `(S + T) + U`, `(D + E) + F` |
| `(s * t) * (u * v)`, `(s + t) + (u + v)` | `((S * T) * U) * V`, `((S + T) + U) + V` |
| `s - (t - u)`, `s - (t + u)` | `(S - T) + U`, `(S - T) - U` |
| `s * t * (u * 0.1)` | `(float)(((double)(S * T) * (double)U) * 0x1.999999999999Ap-4)`: R2 conversions first, then flattening |
| `rd = d * (e * 2) * f` | `((D * E) * F) * 0x1.p+1` |
| `s * (t + 0.1)`, `s * (t / u)`, `s / (t / u)` | kept: different operators are not merged |

`s * (t * u)` differs from the written order for 714 of 2,000 inputs, `s - (t - u)` for 715.

## R6 Powers

| BASIC | Generated C |
|---|---|
| `s ^ 2` (variable base) | `(float)(double)(S * S)`: a product in the base's type |
| `s ^ 3`, `s ^ 0.5`, `(s + t) ^ 2` | `(float)pow((double)S, 0x1.8p+1)`, …, `pow((double)(S + T), 0x1.p+1)` |
| `Spin_target^2 + 0.5^2` (`GEF.bas:3797`) | `(double)(SPIN_TARGET * SPIN_TARGET) + 0x1.p-2` |

## R7 Intrinsics are chosen by the argument's type

`Exp(s)` → `expf`, `Exp(d)` → `exp`, `Exp(-s * 0.5)` → `exp((double)-S * 0x1.p-1)` (the argument is `Double`, R1). The same holds for `Sqr` (`sqrtf`/`sqrt`), `Log` (`logf`/`log`), `Abs` (`fabsf`/`fabs`) and `Int` (`floorf`/`floor`). `Fix` calls the runtime (`fb_FIXSingle`/`fb_FIXDouble`). The wrappers are M3.4's.

## R8 Conversions to integers

These are inline macros in the generated C, not runtime calls:

| BASIC | Generated C |
|---|---|
| `ri = CInt(s)`, `ri = s` | `fb_F2L(S)` = `(int64)__builtin_nearbyintf(S)` |
| `l = s` (`Long`) | `fb_F2I(S)` = `(int32)__builtin_nearbyintf(S)` |
| `ri = d`, `ri = i / j` | `fb_D2L(D)` = `(int64)__builtin_nearbyint(D)` |
| unsigned 64-bit target | `fb_D2UL(D)` = `(uint64)__builtin_nearbyint(D)` |
| `ri = Int(s)` | `fb_F2L(floorf(S))` |
| `ri = s \ t` | `fb_F2L(S) / fb_F2L(T)`: operands rounded to integers first |

`nearbyint` rounds in the current rounding mode (to nearest, ties to even: `CLng(-1.5)` is −2). Out of range, the C cast is undefined, but fbc's `-O0` code does the x86-64 thing (M3.3, goldens `m3-conv-*`): NaN and values outside the target range give the type's minimum (`&h80000000`, `&h8000000000000000`); the unsigned 64-bit cast gives `&h8000000000000000` for NaN, −Inf and values below −2⁶³, the two's-complement pattern for other negatives, and 0 from 2⁶⁴ up. `Fix` and `Sgn` are libfb calls: `fb_FIXSingle(x)` is `truncf(fabsf(x)) * (float)fb_SGNSingle(x)`, and `fb_SGNSingle` returns −1 for NaN. The C++ helpers are `fb::f2i`, `f2l`, `f2ul`, `d2i`, `d2l`, `d2ul`, `fix`, `sgn` in `convert.hpp`. Integer overflow wraps (`-fwrapv`): use `fb::add`, `sub`, `mul`, `neg`, `abs`.

## Writing C++ that keeps fbc's order

- Write the generated C's tree literally, with its parentheses and casts: `static_cast<float>((static_cast<double>(s) * static_cast<double>(t)) * 0.1)`.
- Use the folded constant fbc emits (as a hex literal when it is not a short decimal), not the BASIC literals: `0x1.47AE147AE147Cp-6`, not `0.1 * 0.2`.
- The exact-mode flags (`-ffp-contract=off`, no `-ffast-math`) stop gcc and clang from reassociating or fusing. With them, `-O3` gives the same bits (verified by the `release-exact` run of `fbc_arithmetic_test.cpp`).
- Never rely on C++ precedence to rebuild a BASIC expression: `s * (t * u)` in C++ is not what GEF computes.
