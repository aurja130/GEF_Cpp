# Captures

The project's evidence: BASIC reference runs in the reference store (manifests under `manifests/reference_store/`), the goldens derived from them or from FreeBASIC drivers (`Cpp_implementation/tests/golden/`), and the capture corpora. Each family names the concept nodes it proves; agents add dated, signed notes to **Comments**. Links to [CONCEPTS](CONCEPTS.md), [CODE](CODE.md), [DEFINITIONS](DEFINITIONS.md), [TESTS](TESTS.md) and [CAPTURES](CAPTURES.md).

## Arithmetic rule evaluation
**Concepts:** `FbArithmeticRules` `FrOperandTypes` `FrExpressionForm` `FrSingleQuotient` `FrChainHasLiteral` `FrLeftToRight` `FrFoldLast` `FrPower` `FrIntrinsicByType`
**Comments:** none yet

The arithmetic driver `harness/drivers/arith_rules.bas` (no arguments; 2000 rows by default) draws its inputs from Randomize 1, 3. Each row holds a Single s, t and u, a Double d and e, and an Integer i, followed by the eighteen results E1 to E18, one per rule example. In `arith_rules.txt` the inputs come first as hex, except that the Integer is decimal, and then the results follow in the same hex form: Single values have 8 hex digits and Double values have 16. The arithmetic evaluator test must reproduce every result bit for bit.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-arith-rules/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `FbArithmeticRules` |
| `Cpp_implementation/tests/golden/m3-arith-rules/arith_rules.txt` | 2000 rows of six inputs and the eighteen rule results. | `FbArithmeticRules` `FrOperandTypes` `FrExpressionForm` `FrSingleQuotient` `FrChainHasLiteral` `FrLeftToRight` `FrFoldLast` `FrPower` `FrIntrinsicByType` |
| `Cpp_implementation/tests/golden/m3-arith-rules/stdout.txt` | Standard output of the driver run. | `FbArithmeticRules` |

## Dynamic arrays
**Concepts:** `FbArrays`
**Comments:** none yet

The arrays driver `harness/drivers/arrays.bas` (no arguments) checks dynamic array behaviour on Double arrays of rank one to three and on a String array of rank one. It covers ReDim, ReDim Preserve, Erase, the LBound and UBound queries, and the GEF growth helpers Extend_1dim, Extend_2dim and Extend_3dim. The operations come from DATA statements. Each one is echoed to ops.txt as its own line, and state.txt gets one line after it with the operation index, the array, the bounds of each dimension and the elements in row-major order; Double elements are 16 hex digits and String elements are hex bytes. The array test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-arrays/driver.json` | Run record for the arrays driver. | `FbArrays` |
| `Cpp_implementation/tests/golden/m3-arrays/ops.txt` | 45 operations, one per line, echoed from the DATA text. | `FbArrays` |
| `Cpp_implementation/tests/golden/m3-arrays/state.txt` | 45 state lines, one per operation, with bounds and elements. | `FbArrays` |
| `Cpp_implementation/tests/golden/m3-arrays/stdout.txt` | Standard output of the driver run. | `FbArrays` |

## Single conversions
**Concepts:** `FbNumericConversions`
**Comments:** none yet

The conversion driver `harness/drivers/conv_single.bas` (no arguments) runs over all 2^32 Single bit patterns. For each pattern it applies the CLng, CLngInt and ULongInt assignments, Fix and Sgn, and folds the raw results into one FNV-style hash per operation, computed with wrapping ULongInt arithmetic. The hashes restart for each block of 2^24 consecutive patterns, so the golden has 256 lines, each a two-digit hex block number followed by the five hashes. The conversion test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-conv-single/driver.json` | Run record for the conversion driver. | `FbNumericConversions` |
| `Cpp_implementation/tests/golden/m3-conv-single/conv_single.txt` | 256 lines: block number, then the hashes of CLng, CLngInt, ULongInt, Fix and Sgn. | `FbNumericConversions` |
| `Cpp_implementation/tests/golden/m3-conv-single/stdout.txt` | Standard output of the driver run. | `FbNumericConversions` |

## Double conversions
**Concepts:** `FbNumericConversions`
**Comments:** none yet

The conversion driver `harness/drivers/conv_double.bas` (no arguments) has two parts. The grid part converts fixed Double bit patterns, at both signs and including three NaN patterns, and writes the raw result bits for each value. The random part calls Randomize 12345, 3 and builds 2^20 Double values from two Rnd draws each, the hi draw first and then the lo draw; its FNV-style hashes restart per block of 2^16, so the random file has 16 lines. The conversion test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-conv-double/driver.json` | Run record for the conversion driver. | `FbNumericConversions` |
| `Cpp_implementation/tests/golden/m3-conv-double/conv_double_grid.txt` | One line per grid value, with the raw result bits of its conversions. | `FbNumericConversions` |
| `Cpp_implementation/tests/golden/m3-conv-double/conv_double_random.txt` | 16 lines: block number and five hashes. | `FbNumericConversions` |
| `Cpp_implementation/tests/golden/m3-conv-double/stdout.txt` | Standard output of the driver run. | `FbNumericConversions` |

## Integer operations
**Concepts:** `FbIntegerArithmetic` `FbNumericConversions`
**Comments:** none yet

The integer driver `harness/drivers/int_ops.bas` (no arguments) runs LongInt unary and binary operations over an edge list, and Long (32-bit) binary operations over a second edge list. For each value of the first list, the unary file gives its hex form, its negation, its absolute value and its sign. For each ordered pair, the binary file gives the sum, difference, product, integer quotient and Mod result. The quotient and Mod columns hold dashes where the driver does not evaluate them: for a zero divisor, and for the most negative LongInt divided by minus one. The conversion test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-int-ops/driver.json` | Run record for the integer driver. | `FbIntegerArithmetic` `FbNumericConversions` |
| `Cpp_implementation/tests/golden/m3-int-ops/int_unary.txt` | Per value: hex form, negation, absolute value and sign. | `FbIntegerArithmetic` `FbNumericConversions` |
| `Cpp_implementation/tests/golden/m3-int-ops/int_binary.txt` | Per ordered pair: both operands, sum, difference, product, quotient and Mod. | `FbIntegerArithmetic` |
| `Cpp_implementation/tests/golden/m3-int-ops/long_binary.txt` | Long (32-bit) binary results over the second edge list. | `FbIntegerArithmetic` |
| `Cpp_implementation/tests/golden/m3-int-ops/stdout.txt` | Standard output of the driver run. | `FbIntegerArithmetic` |

## DATA, Val and Input # reads
**Concepts:** `DataStatements` `TextToNumber` `InputFileStatements`
**Comments:** none yet

The data driver `harness/drivers/data_input.bas` (no arguments) has three parts. Part (a) reads DATA statements from three labelled blocks holding 39 items in all, starting with a Read before any Restore; it writes the first Read as Double bits, every item as a String, the label positions, the Single, Double and LongInt bits of every item, and a chained run of reads after Restore. Part (b) converts strings with Val, ValLng and ValInt. Part (c) reads a binary-exact file with Input #, one item per operation, and writes each operation with its result. The data input test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-data-input/driver.json` | Run record for the data driver. | `DataStatements` `TextToNumber` `InputFileStatements` |
| `Cpp_implementation/tests/golden/m3-data-input/data_first.txt` | The first Read, a Double, as bits, taken before any Restore. | `DataStatements` |
| `Cpp_implementation/tests/golden/m3-data-input/data_items.txt` | One line per DATA item read as a String: its hex bytes, or a dash when empty. | `DataStatements` |
| `Cpp_implementation/tests/golden/m3-data-input/data_labels.txt` | Positions of the three labels in the flat item list. | `DataStatements` |
| `Cpp_implementation/tests/golden/m3-data-input/data_values.txt` | Per item: index, Single bits, Double bits and LongInt bits. | `DataStatements` |
| `Cpp_implementation/tests/golden/m3-data-input/data_chain.txt` | Eight Double reads after Restore to the second block, then two Strings, two LongInts and two Strings after Restore to the third block. | `DataStatements` |
| `Cpp_implementation/tests/golden/m3-data-input/val.txt` | Per input string: its hex or a dash, then the Val, ValLng and ValInt results in hex. | `TextToNumber` |
| `Cpp_implementation/tests/golden/m3-data-input/input.txt` | The binary-exact input file read by Input #. | `InputFileStatements` |
| `Cpp_implementation/tests/golden/m3-data-input/input_ops.txt` | One operation letter per line: S for Single, D for Double, L for LongInt, dollar sign for String. | `InputFileStatements` |
| `Cpp_implementation/tests/golden/m3-data-input/input_results.txt` | Per operation: op index, type and value; Single 8 hex, Double 16 hex, LongInt 16 hex, String hex bytes or a dash. | `InputFileStatements` |
| `Cpp_implementation/tests/golden/m3-data-input/stdout.txt` | Standard output of the driver run. | `DataStatements` `TextToNumber` `InputFileStatements` |

## Format function
**Concepts:** `FormatFunction`
**Comments:** none yet

The format driver `harness/drivers/format.bas` (no arguments) runs the Format function over numeric values and date serials, using the masks GEF uses and a set of edge-case masks. It skips two combinations that hit runtime hazards. Each call writes one line with the value bits, the mask in hex and the result in hex. The format test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-format/driver.json` | Run record for the format driver. | `FormatFunction` |
| `Cpp_implementation/tests/golden/m3-format/format.txt` | One line per call: value bits, mask in hex, result in hex. | `FormatFunction` |
| `Cpp_implementation/tests/golden/m3-format/stdout.txt` | Standard output of the driver run. | `FormatFunction` |

## GEF maths helpers
**Concepts:** `GefMathHelpers`
**Comments:** none yet

The GEF maths driver `harness/drivers/gef_math2.bas` (no arguments) checks the helpers that GEF defines itself. Min and Max come from the GEF utilities; Round and Modulo come from a cut of the GEF source, which the run record lists. Part (a) covers all ordered pairs of a fixed Single grid for Min and Max. Part (b) takes 2^20 random Single pairs from Randomize 4242, 3, in 16 blocks of 2^16, and hashes the Min and Max results per block. Part (c) computes Round over fixed N and R values. Part (d) continues the Rnd stream to round random Single values with N in 1, 2, 3, 4, 5 and 7, and part (e) continues it for 4096 Modulo pairs. The maths test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-gef-math2/driver.json` | Run record; it lists the cut of the GEF source. | `GefMathHelpers` |
| `Cpp_implementation/tests/golden/m3-gef-math2/minmax_grid.txt` | Two inputs and their Min and Max results, for all ordered pairs of the Single grid. | `GefMathHelpers` |
| `Cpp_implementation/tests/golden/m3-gef-math2/minmax_random.txt` | 16 lines: block number, hash of the Min results, hash of the Max results. | `GefMathHelpers` |
| `Cpp_implementation/tests/golden/m3-gef-math2/round_grid.txt` | Per line: N in decimal, R in hex, and Round of R and N in hex. | `GefMathHelpers` |
| `Cpp_implementation/tests/golden/m3-gef-math2/round_random.txt` | 16 lines: block number and six hashes, one per N in the order 1, 2, 3, 4, 5, 7. | `GefMathHelpers` |
| `Cpp_implementation/tests/golden/m3-gef-math2/modulo.txt` | 4096 lines: two inputs in hex and their Modulo result in hex. | `GefMathHelpers` |
| `Cpp_implementation/tests/golden/m3-gef-math2/stdout.txt` | Standard output of the driver run. | `GefMathHelpers` |

## Single maths functions
**Concepts:** `FbIntrinsicMaths` `GefMathHelpers`
**Comments:** none yet

The Single maths driver `harness/drivers/math_single.bas` (no arguments) runs over all 2^32 Single bit patterns. For each pattern it applies Exp, Log, Sqr, Int, Abs, Sin, Acos, Erf, Erfc, Tanh, Coth, Log10, Floor and Ceil, and folds each result's raw bits into its own FNV-style hash. The hashes restart for each block of 2^24 patterns, so the golden has 256 lines, each a block number and fourteen hashes. The maths test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-math-single/driver.json` | Run record; it lists the cut of the GEF source that the driver uses. | `FbIntrinsicMaths` `GefMathHelpers` |
| `Cpp_implementation/tests/golden/m3-math-single/math_single.txt` | 256 lines: block number and fourteen hashes, one per function. | `FbIntrinsicMaths` `GefMathHelpers` |
| `Cpp_implementation/tests/golden/m3-math-single/stdout.txt` | Standard output of the driver run. | `FbIntrinsicMaths` `GefMathHelpers` |

## Double maths and power
**Concepts:** `FbIntrinsicMaths` `FrPower`
**Comments:** none yet

The Double maths driver `harness/drivers/math_double.bas` (no arguments) has five parts. Part (a) runs a grid of fixed Double bit patterns, covering zero, denormals, normal values up to the largest finite value, positive infinity and NaN values of both signs, through Exp, Log, Sqr, Int, Abs and Cos. Part (b) uses Randomize 777, 3 to draw 2^20 random values in 16 blocks, and part (c) takes moderate-range values in 16 blocks; each block gives six hashes. Parts (d) and (e) test the Double power operator, once over a fixed grid of bases and exponents and once over random pairs in 16 blocks. NaN results are hashed as one canonical NaN value. The maths test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-math-double/driver.json` | Run record for the Double maths driver. | `FbIntrinsicMaths` `FrPower` |
| `Cpp_implementation/tests/golden/m3-math-double/math_double_grid.txt` | One line per grid value with the raw result bits of Exp, Log, Sqr, Int, Abs and Cos. | `FbIntrinsicMaths` |
| `Cpp_implementation/tests/golden/m3-math-double/math_double_random.txt` | 16 lines: block number and six hashes for the random values. | `FbIntrinsicMaths` |
| `Cpp_implementation/tests/golden/m3-math-double/math_double_moderate.txt` | 16 lines: block number and six hashes for the moderate-range values. | `FbIntrinsicMaths` |
| `Cpp_implementation/tests/golden/m3-math-double/pow_grid.txt` | One line per base and exponent pair: both input bit patterns and the raw result bits. | `FrPower` `FbIntrinsicMaths` |
| `Cpp_implementation/tests/golden/m3-math-double/pow_random.txt` | 16 lines: block number and hash of the power results. | `FrPower` `FbIntrinsicMaths` |
| `Cpp_implementation/tests/golden/m3-math-double/stdout.txt` | Standard output of the driver run. | `FbIntrinsicMaths` `FrPower` |

## Print # file output
**Concepts:** `PrintFileStatement`
**Comments:** none yet

The print driver `harness/drivers/print_file.bas` runs a fixed sequence of Print # statements to a file: strings, Single, Double and LongInt values, the semicolon and comma separators, an empty statement, a Tab() call and an embedded line feed. The golden keeps the raw bytes written to the file. The text test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-print-file/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `PrintFileStatement` |
| `Cpp_implementation/tests/golden/m3-print-file/print_file.txt` | Raw bytes written by the Print # sequence (19 lines). | `PrintFileStatement` |
| `Cpp_implementation/tests/golden/m3-print-file/stdout.txt` | Standard output of the driver run. | `PrintFileStatement` |

## Print Using output
**Concepts:** `PrintUsingStatement`
**Comments:** none yet

The print-using driver `harness/drivers/print_using.bas` runs every GEF Print Using template and a set of generic templates. The templates cover signs, exponents, floating dollar signs, asterisk fill, commas, underscore escapes, and the ampersand, exclamation point and backslash string fields. The values include NaN, infinities, signed zeros and denormals. The driver never gives a template more items than it has fields, because fbc then reads freed memory. The print-using test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-print-using/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `PrintUsingStatement` |
| `Cpp_implementation/tests/golden/m3-print-using/templates.txt` | Hex of each template: 82 templates with indexes 0 to 81. | `PrintUsingStatement` |
| `Cpp_implementation/tests/golden/m3-print-using/calls.txt` | One line per statement: template index, item count, then each item as its type letter and value bytes in hex (5719 lines). | `PrintUsingStatement` |
| `Cpp_implementation/tests/golden/m3-print-using/print_using.txt` | Raw output of every statement. | `PrintUsingStatement` |
| `Cpp_implementation/tests/golden/m3-print-using/stdout.txt` | Standard output of the driver run. | `PrintUsingStatement` |

## Random seeds and the Rnd stream (edge seeds)
**Concepts:** `FbRandomStream`
**Comments:** none yet

The seed driver `harness/drivers/rnd_seeds.bas` takes a count and a list of seeds, as `rnd_seeds <count> <seed> [<seed> ...]`. Each seed is read with Val as a Double and passed to Randomize seed, 3. The words nan, inf and -inf are accepted. This family runs 22 seeds with a count of 1300: integers near the 32-bit limits, values near plus and minus 2^63, 1e20 and -1e20, 4.9e-324, fractions, and the three words. The golden holds three Rnd values before any Randomize, six Rnd values after the first seed (Rnd(1), Rnd(0), Rnd(-1), Rnd(0.5), Rnd(0) and Rnd), the seed table, and 1300 u32 values per seed. The random number test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `FbRandomStream` |
| `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/startup.txt` | Three Rnd values before any Randomize (3 lines). | `FbRandomStream` |
| `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/args.txt` | The six Rnd values after the first seed, each as its argument and Double bit pattern (6 lines). | `FbRandomStream` |
| `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seeds.txt` | One line per seed: index, seed Double bit pattern and seed text (22 lines). | `FbRandomStream` |
| `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/stdout.txt` | Standard output of the driver run. | `FbRandomStream` |
| `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_0.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_1.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_2.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_3.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_4.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_5.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_6.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_7.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_8.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_9.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_10.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_11.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_12.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_13.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_14.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_15.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_16.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_17.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_18.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_19.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_20.txt`, `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/seed_21.txt` | 1300 lines per seed, each a u32 as eight lowercase hex digits. | `FbRandomStream` |

## Str text of all Single values
**Concepts:** `StrFunction`
**Comments:** none yet

The Str driver `harness/drivers/str_single.bas` converts all 2^32 Single bit patterns with Str. For each pattern it folds the text and a line feed into an FNV-1a 64 hash, and it writes one line per block of 2^24 patterns. Usage is `str_single [first_block [last_block]]`, with defaults 0 and 255. A full run takes tens of minutes. The text test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-str-single/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `StrFunction` |
| `Cpp_implementation/tests/golden/m3-str-single/str_single.txt` | One line per block: the block number in two hex digits, then the 16-digit hash (256 lines). | `StrFunction` |
| `Cpp_implementation/tests/golden/m3-str-single/stdout.txt` | Standard output of the driver run. | `StrFunction` |

## Str text of Single and Double values
**Concepts:** `StrFunction`
**Comments:** none yet

The Str driver `harness/drivers/str_numbers.bas` has three parts. Part (a) writes grids of fixed Single and Double values, including NaN values and infinities, each line holding the input bit pattern and its Str text. Part (b) calls Randomize 99, 3 and converts 2^20 random Double bit patterns in 16 blocks, hashing their Str texts with FNV-1a. Part (c) converts moderate Double values, x = (Rnd - 0.5) * 2000. The LongInt text is written to `str_longint.txt`. The text test uses this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m3-str-numbers/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `StrFunction` |
| `Cpp_implementation/tests/golden/m3-str-numbers/str_single_grid.txt` | Part (a): input bit pattern and Str text for each fixed Single value (34 lines). | `StrFunction` |
| `Cpp_implementation/tests/golden/m3-str-numbers/str_double_grid.txt` | Part (a): input bit pattern and Str text for each fixed Double value (42 lines). | `StrFunction` |
| `Cpp_implementation/tests/golden/m3-str-numbers/str_double_random.txt` | Part (b): 16 lines, each a block index and a 16-digit hash. | `StrFunction` |
| `Cpp_implementation/tests/golden/m3-str-numbers/str_double_moderate.txt` | Part (c): 16 lines, each an index and a 16-digit hash. | `StrFunction` |
| `Cpp_implementation/tests/golden/m3-str-numbers/str_longint.txt` | LongInt text: 10 grid lines followed by 4096 random lines (4106 lines). | `StrFunction` |
| `Cpp_implementation/tests/golden/m3-str-numbers/stdout.txt` | Standard output of the driver run. | `StrFunction` |

## Line Input, EOF and string functions
**Concepts:** `InputFileStatements` `FbStringFunctions`
**Comments:** none yet

The line input driver `harness/drivers/line_input.bas` writes 22 binary input files with Put Binary and reads each one with Line Input and EOF. The cases cover blank input, LF and CRLF endings, lone CR, NUL bytes, a missing final line feed, empty input, and cases named for lengths 510 to 512 and 1022 to 1023. The driver also runs Trim, UCase, InStr and Mid, and the GEF ConvTab, CC_Count and CC_Cut utilities. The line input test, the string test and the utilities test use this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m4-line-input/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `InputFileStatements` `FbStringFunctions` |
| `Cpp_implementation/tests/golden/m4-line-input/strings.txt` | TRIM, UCASE, INSTR, INSTRS, MID2 and MID3 results (499 lines). | `FbStringFunctions` |
| `Cpp_implementation/tests/golden/m4-line-input/utilities.txt` | ConvTab, Count and Cut results (68 lines): CONVTAB, COUNT, CUT of 10 elements and CUTS of 3 elements. | `FbStringFunctions` |
| `Cpp_implementation/tests/golden/m4-line-input/stdout.txt` | Standard output of the driver run, including the dimension messages from the cut utilities. | `FbStringFunctions` |
| `Cpp_implementation/tests/golden/m4-line-input/in_blank.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_cr511.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_cr_eof.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_cr_nul_eof.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_crlf.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_lf.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_lone_cr.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_no_final_lf.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_nul511.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_nul_mid.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_nul_only.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_crlf1022.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_crlf1023.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_lf1023.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_lf1022.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_crlf510.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_crlf511.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_crlf512.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_lf510.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_lf511.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_lf512.bin`, `Cpp_implementation/tests/golden/m4-line-input/in_empty.bin` | Binary input for each of the 22 cases, written with Put Binary. | `InputFileStatements` |
| `Cpp_implementation/tests/golden/m4-line-input/lines_blank.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_cr511.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_cr_eof.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_cr_nul_eof.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_crlf.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_lf.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_lone_cr.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_no_final_lf.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_nul511.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_nul_mid.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_nul_only.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_crlf1022.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_crlf1023.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_lf1023.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_lf1022.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_crlf510.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_crlf511.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_crlf512.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_lf510.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_lf511.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_lf512.txt`, `Cpp_implementation/tests/golden/m4-line-input/lines_empty.txt` | One line per Line Input record for each case: index, length, and the hex bytes of the line or a dash when empty. | `InputFileStatements` |

## Trim with pattern, RTrim, Left and Right
**Concepts:** `InputFileStatements` `FbStringFunctions`
**Comments:** none yet

The strings driver `harness/drivers/m6_strings.bas` checks Trim with a pattern argument, RTrim, Left and Right. Each of its five cases has a binary input file. `strings.txt` holds one line per TRIMEX call with the input, the pattern and the result, followed by lines for RTRIM, LEFT and RIGHT. `hang.txt` holds Input # and Line Input records for five cases in which a loop that reads until end of file would never finish in GEF. The string test and the line input test use this golden.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m6-strings/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `InputFileStatements` `FbStringFunctions` |
| `Cpp_implementation/tests/golden/m6-strings/strings.txt` | TRIMEX lines (input, pattern, result), then RTRIM, LEFT and RIGHT lines. | `FbStringFunctions` |
| `Cpp_implementation/tests/golden/m6-strings/hang.txt` | Input # and Line Input records for the five cases (35 lines). | `InputFileStatements` |
| `Cpp_implementation/tests/golden/m6-strings/stdout.txt` | Standard output of the driver run. | `FbStringFunctions` |
| `Cpp_implementation/tests/golden/m6-strings/in_blank_first.bin`, `Cpp_implementation/tests/golden/m6-strings/in_number.bin`, `Cpp_implementation/tests/golden/m6-strings/in_number_noeol.bin`, `Cpp_implementation/tests/golden/m6-strings/in_quote.bin`, `Cpp_implementation/tests/golden/m6-strings/in_quote_noeol.bin` | Binary input file for each of the five cases. | `InputFileStatements` |

## Console Print and Print # to a file
**Concepts:** `PrintFileStatement`
**Comments:** none yet

The console driver `harness/drivers/m6_console.bas` writes lines with console Print and with Print # to `console_file.txt`. The lines include text longer than 80 columns and zone positions past column 80. The program ends with Sleep at end of file. The text test compares the console output, without its final line, with the file.

| Item | Holds | Concepts |
|---|---|---|
| `Cpp_implementation/tests/golden/m6-console/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `PrintFileStatement` |
| `Cpp_implementation/tests/golden/m6-console/stdout.txt` | Console output. Its final line, printed after Sleep, is excluded from the comparison. | `PrintFileStatement` |
| `Cpp_implementation/tests/golden/m6-console/console_file.txt` | Lines written with Print # (18 lines). | `PrintFileStatement` |

## Stored random seed run, one million values (store only)
**Concepts:** `FbRandomStream`
**Comments:** none yet

This capture is held in the reference store and has no golden copy in the repository. The stored run is the seed driver `rnd_seeds` with a count of 1000000 and 20 seeds: 0, 1, 2, 3, 42, 12345, 65535, 65536, 16777216, 123456789, 987654321, 1000000007, 1776849192, 1776917293, 2147483647, 2147483648, 2718281828, 3141592653, 4294967294 and 4294967295. Each seed file holds 1000000 u32 values as eight lowercase hex digits. The manifest records 25 files and 180003468 bytes. The random number test reads this capture from the store.

| Item | Holds | Concepts |
|---|---|---|
| `manifests/reference_store/m3-rnd-seeds-1e6.json` | Store manifest: 25 files, 180003468 bytes. | `FbRandomStream` |
| `validation/reference_store/captures/m3-rnd-seeds-1e6/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `FbRandomStream` |
| `validation/reference_store/captures/m3-rnd-seeds-1e6/args.txt` | The six Rnd values after the first seed, in the same layout as the edge golden. | `FbRandomStream` |
| `validation/reference_store/captures/m3-rnd-seeds-1e6/seeds.txt` | One line per seed (20 lines). | `FbRandomStream` |
| `validation/reference_store/captures/m3-rnd-seeds-1e6/startup.txt` | Three Rnd values before any Randomize. | `FbRandomStream` |
| `validation/reference_store/captures/m3-rnd-seeds-1e6/stdout.txt` | Standard output of the stored run. | `FbRandomStream` |
| `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_0.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_1.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_2.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_3.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_4.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_5.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_6.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_7.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_8.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_9.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_10.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_11.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_12.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_13.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_14.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_15.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_16.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_17.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_18.txt`, `validation/reference_store/captures/m3-rnd-seeds-1e6/seed_19.txt` | 1000000 lines per seed, each a u32 as eight lowercase hex digits. | `FbRandomStream` |

## Stored Rnd stream for seed 42 (store only)
**Concepts:** `FbRandomStream`
**Comments:** none yet

This capture is held in the reference store and has no golden copy in the repository. The stored run is `rnd_stream` with its defaults: seed 42 and a count of 1000000. Its output is one u32 per line as eight lowercase hex digits, from the Mersenne Twister stream of fbc 1.10.1. The manifest records three files. The random number test reads this capture from the store.

| Item | Holds | Concepts |
|---|---|---|
| `manifests/reference_store/m1-golden-rnd-stream-42.json` | Store manifest: 3 files. | `FbRandomStream` |
| `validation/reference_store/captures/m1-golden-rnd-stream-42/driver.json` | Run record: driver, command, fbc version, return code, outputs, source and binary hashes. | `FbRandomStream` |
| `validation/reference_store/captures/m1-golden-rnd-stream-42/rnd_stream_42.txt` | One u32 per line, eight lowercase hex digits (1000000 lines). | `FbRandomStream` |
| `validation/reference_store/captures/m1-golden-rnd-stream-42/stdout.txt` | Standard output of the stored run. | `FbRandomStream` |

## Lookup captures

**Concepts:** `MatLookups`, `DecayBranchings`
**Comments:** none yet

Six captures run the nuclide lookup functions of one variant over a grid of nucleus numbers in a fresh control folder: JEFF-3.1.1, JEFF-3.3, legacy X, legacy MF, legacy F and NUBASE 2016. The JEFF-3.3 capture also runs the default-mode lookup after the branchings loader. Each golden includes files.txt.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m4-lookups-jeff311.json` | Manifest of the JEFF-3.1.1 lookup capture. | `MatLookups`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-lookups-jeff311/derived.json` | Golden of the JEFF-3.1.1 lookup capture, with files.txt. | `MatLookups`, `DecayBranchings` |
| `manifests/reference_store/m4-lookups-jeff33.json` | Manifest of the JEFF-3.3 lookup capture. | `MatLookups`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-lookups-jeff33/derived.json` | Golden of the JEFF-3.3 lookup capture, with files.txt. | `MatLookups`, `DecayBranchings` |
| `manifests/reference_store/m4-lookups-legacy-x.json` | Manifest of the legacy X lookup capture. | `MatLookups`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-lookups-legacy-x/derived.json` | Golden of the legacy X lookup capture, with files.txt. | `MatLookups`, `DecayBranchings` |
| `manifests/reference_store/m4-lookups-legacy-mf.json` | Manifest of the legacy MF lookup capture. | `MatLookups`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-lookups-legacy-mf/derived.json` | Golden of the legacy MF lookup capture, with files.txt. | `MatLookups`, `DecayBranchings` |
| `manifests/reference_store/m4-lookups-legacy-f.json` | Manifest of the legacy F lookup capture. | `MatLookups`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-lookups-legacy-f/derived.json` | Golden of the legacy F lookup capture, with files.txt. | `MatLookups`, `DecayBranchings` |
| `manifests/reference_store/m4-lookups-nubase2016.json` | Manifest of the NUBASE 2016 lookup capture. | `MatLookups`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-lookups-nubase2016/derived.json` | Golden of the NUBASE 2016 lookup capture, with files.txt. | `MatLookups`, `DecayBranchings` |

## T0 probe captures

**Concepts:** `NuclideTables`, `MassShellTables`, `DecayBranchings`
**Comments:** none yet

Six captures run the T0 probe and dump the DATA chain of one certified variant: JEFF-3.1.1, JEFF-3.3, legacy X, legacy MF, legacy F and NUBASE 2016. Each golden holds the T0 dump (T0.txt) that the BASIC run produces. The store also keeps the console log of the JEFF-3.1.1 capture as m4-t0-jeff311/stdout.log, in plain text.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m4-t0-jeff311.json` | Manifest of the JEFF-3.1.1 T0 capture. | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-t0-jeff311/derived.json` | Golden of the JEFF-3.1.1 T0 dump (T0.txt). | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `manifests/reference_store/m4-t0-jeff33.json` | Manifest of the JEFF-3.3 T0 capture. | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-t0-jeff33/derived.json` | Golden of the JEFF-3.3 T0 dump (T0.txt). | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `manifests/reference_store/m4-t0-legacy-x.json` | Manifest of the legacy X T0 capture. | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-t0-legacy-x/derived.json` | Golden of the legacy X T0 dump (T0.txt). | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `manifests/reference_store/m4-t0-legacy-mf.json` | Manifest of the legacy MF T0 capture. | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-t0-legacy-mf/derived.json` | Golden of the legacy MF T0 dump (T0.txt). | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `manifests/reference_store/m4-t0-legacy-f.json` | Manifest of the legacy F T0 capture. | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-t0-legacy-f/derived.json` | Golden of the legacy F T0 dump (T0.txt). | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `manifests/reference_store/m4-t0-nubase2016.json` | Manifest of the NUBASE 2016 T0 capture. | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `Cpp_implementation/tests/golden/m4-t0-nubase2016/derived.json` | Golden of the NUBASE 2016 T0 dump (T0.txt). | `NuclideTables`, `MassShellTables`, `DecayBranchings` |

## NUBASE 2020 T0 capture

**Concepts:** `NuclideTables`
**Comments:** none yet

The NUBASE 2020 T0 capture has no T0 dump: GEF stops while loading the NUBASE 2020 nuclide list (Q-032), and the loader test checks that stop. The store keeps the console log of the stopped run as m4-t0-nubase2020/stdout.log, in plain text.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m4-t0-nubase2020.json` | Manifest of the stopped NUBASE 2020 capture; there is no golden. | `NuclideTables` |

## Fit parameter file captures

**Concepts:** `NominalParameters`, `PerturbationWidths`, `FitparFile`, `ParameterFiles`
**Comments:** none yet

A run with a fit parameter file in the working folder, one energy step and no passes. The file is read at start-up and again later in the run; the T0 and P1 probes record the values, and the golden of the file holds its text (Fitpar.dat).

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m4-t0-fitpar.json` | Manifest of the fit parameter capture. | `NominalParameters`, `PerturbationWidths`, `FitparFile`, `ParameterFiles` |
| `Cpp_implementation/tests/golden/m4-t0-fitpar/derived.json` | Golden of the T0 probe (T0.txt) of the fit parameter capture. | `NominalParameters`, `PerturbationWidths`, `FitparFile`, `ParameterFiles` |
| `Cpp_implementation/tests/golden/m4-p1-fitpar/derived.json` | Golden of the P1 probe (P1.txt) of the fit parameter capture. | `NominalParameters`, `PerturbationWidths`, `FitparFile`, `ParameterFiles` |
| `Cpp_implementation/tests/golden/m4-fitpar-files/derived.json` | Golden of the fit parameter file itself (Fitpar.dat). | `NominalParameters`, `PerturbationWidths`, `FitparFile`, `ParameterFiles` |

## Final widths probe

**Concepts:** `PerturbationWidths`, `NominalParameters`
**Comments:** none yet

The P1 probe of the rn215 run, copied from the milestone probe store (source capture m1-g23-rn215-r-probes, file P1.txt), with its context line. It records the final widths and the per-system parameters.

| Item | Holds | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/golden/m4-p1-rn215/derived.json` | Golden of the copied P1 probe (P1.txt). | `PerturbationWidths`, `NominalParameters` |

## Update file

**Concepts:** `ParameterUpdateFile`, `ParameterFiles`
**Comments:** none yet

The update file that the JEFF-3.3 T0 run writes after the parameter files are applied; the golden holds its text (ParameterUpdate.dat).

| Item | Holds | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/golden/m4-parameter-update/derived.json` | Golden of the update file text (ParameterUpdate.dat). | `ParameterUpdateFile`, `ParameterFiles` |

## Data chain items

**Concepts:** `VariantSelection`, `EmittedNuclideC`, `DataItemLabels`
**Comments:** none yet

The DATA chain dumps of the certified variants, reduced to fingerprints per variant (fingerprints.txt) by the generator's fingerprint mode. The NUBASE 2020 chain is kept as a manifest only, because GEF stops while loading that nuclide list (Q-032).

| Item | Holds | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/golden/m4-datachain/derived.json` | Golden of the per-variant item fingerprints (fingerprints.txt). | `VariantSelection`, `EmittedNuclideC`, `DataItemLabels` |
| `manifests/reference_store/m4-datachain-nubase2020.json` | Manifest of the NUBASE 2020 DATA chain dump, taken before the nuclide-list include. | `VariantSelection`, `EmittedNuclideC`, `DataItemLabels` |

## Argument-log captures

**Concepts:** `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade`

**Comments:** none yet

Argument-log captures of the GEF calls for four nuclides, one manifest per nuclide, each paired with its input file.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m5-arglog-rn215.json` | Argument log for the rn215 short input. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `manifests/reference_store/m5-arglog-cf252.json` | Argument log for the cf252 ground-state input. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `manifests/reference_store/m5-arglog-u235.json` | Argument log for the u235 neutron input. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `manifests/reference_store/m5-arglog-sh264.json` | Argument log for the superheavy spontaneous fission input. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `harness/inputs/m1_rn215_short.in` | Input for the rn215 log. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `harness/inputs/m1_cf252_gs.in` | Input for the cf252 log. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `harness/inputs/m5_u235_n.in` | Input for the u235 log. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `harness/inputs/m5_superheavy_sf.in` | Input for the sh264 log. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `harness/drivers/M5_DRIVERS.md` | Driver notes for the M5 physics groups. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `harness/drivers/m5_common.bi` | Shared driver include. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |

## Bounds-checked runs

**Concepts:** `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade`

**Comments:** none yet

Runs of the four argument-log systems built with fbc's bounds checking (`-exx`, patch set `seed`): no runtime error, and outputs identical to the unchecked build where a reference exists. They show which table indices GEF reaches.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m5-exx-rn215.json` | Bounds-checked run of Rn-215 (n,f). | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `manifests/reference_store/m5-exx-cf252.json` | Bounds-checked run of Cf-252 (sf). | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `manifests/reference_store/m5-exx-u235.json` | Bounds-checked run of U-236 (n,f), thermal and 14 MeV. | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |
| `manifests/reference_store/m5-exx-sh264.json` | Bounds-checked run of Sg-264 (sf). | `NuclearMasses`, `FissionBarriers`, `LevelDensities`, `NuclearTemperatures`, `ScissionShapes`, `SmoothingHelpers`, `RotationalDynamics`, `EgammaLowTable`, `E2Cascade` |

## Mass golden

**Concepts:** `MacroscopicMass`, `ShellCorrections`, `TabulatedMasses`

**Comments:** none yet

Golden outputs of the mass functions. The plain manifest is superseded and cited for reference only.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m5-masses-2.json` | Manifest of the current mass golden. | `MacroscopicMass`, `ShellCorrections`, `TabulatedMasses` |
| `manifests/reference_store/m5-masses.json` | Superseded manifest, cited for reference only. | `MacroscopicMass`, `ShellCorrections`, `TabulatedMasses` |
| `Cpp_implementation/tests/golden/m5-masses-2/derived.json` | Derived golden values for the mass group. | `MacroscopicMass`, `ShellCorrections`, `TabulatedMasses` |
| `Cpp_implementation/tests/golden/m5-masses-2/files.txt` | File list of the mass golden. | `MacroscopicMass`, `ShellCorrections`, `TabulatedMasses` |
| `harness/drivers/m5_masses.bas` | Driver of the mass golden. | `MacroscopicMass`, `ShellCorrections`, `TabulatedMasses` |
| `Cpp_implementation/tests/physics_masses_test.cpp` | Test file of the mass group. | `MacroscopicMass`, `ShellCorrections`, `TabulatedMasses` |

## Shape golden

**Concepts:** `CurvatureLimits`, `ScissionEquilibrium`, `DeformationMinimum`, `FissionYields`

**Comments:** none yet

Golden outputs of the shape functions and the yield function. The driver also writes a print file for the deformation minimum. The plain manifest is superseded and cited for reference only.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m5-shape-2.json` | Manifest of the current shape golden. | `CurvatureLimits`, `ScissionEquilibrium`, `DeformationMinimum`, `FissionYields` |
| `manifests/reference_store/m5-shape.json` | Superseded manifest, cited for reference only. | `CurvatureLimits`, `ScissionEquilibrium`, `DeformationMinimum`, `FissionYields` |
| `Cpp_implementation/tests/golden/m5-shape-2/derived.json` | Derived golden values for the shape group. | `CurvatureLimits`, `ScissionEquilibrium`, `DeformationMinimum`, `FissionYields` |
| `Cpp_implementation/tests/golden/m5-shape-2/files.txt` | File list of the shape golden. | `CurvatureLimits`, `ScissionEquilibrium`, `DeformationMinimum`, `FissionYields` |
| `harness/drivers/m5_shape.bas` | Driver of the shape golden. | `CurvatureLimits`, `ScissionEquilibrium`, `DeformationMinimum`, `FissionYields` |
| `Cpp_implementation/tests/physics_shape_test.cpp` | Test file of the shape group. | `CurvatureLimits`, `ScissionEquilibrium`, `DeformationMinimum`, `FissionYields` |

## Barrier golden

**Concepts:** `FissionBarriers`

**Comments:** none yet

Golden outputs of the barrier functions. The plain manifest is superseded and cited for reference only.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m5-barriers-2.json` | Manifest of the current barrier golden. | `FissionBarriers` |
| `manifests/reference_store/m5-barriers.json` | Superseded manifest, cited for reference only. | `FissionBarriers` |
| `Cpp_implementation/tests/golden/m5-barriers-2/derived.json` | Derived golden values for the barrier group. | `FissionBarriers` |
| `Cpp_implementation/tests/golden/m5-barriers-2/files.txt` | File list of the barrier golden. | `FissionBarriers` |
| `harness/drivers/m5_barriers.bas` | Driver of the barrier golden. | `FissionBarriers` |
| `Cpp_implementation/tests/physics_barriers_test.cpp` | Test file of the barrier group. | `FissionBarriers` |

## Level-density golden

**Concepts:** `LevelDensities`, `NuclearTemperatures`

**Comments:** none yet

Golden outputs of the level density and temperature functions.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m5-level_density.json` | Manifest of the level density golden. | `LevelDensities`, `NuclearTemperatures` |
| `Cpp_implementation/tests/golden/m5-level_density/derived.json` | Derived golden values for the level density group. | `LevelDensities`, `NuclearTemperatures` |
| `Cpp_implementation/tests/golden/m5-level_density/files.txt` | File list of the level density golden. | `LevelDensities`, `NuclearTemperatures` |
| `harness/drivers/m5_level_density.bas` | Driver of the level density golden. | `LevelDensities`, `NuclearTemperatures` |
| `Cpp_implementation/tests/physics_level_density_test.cpp` | Test file of the level density group. | `LevelDensities`, `NuclearTemperatures` |

## Rotation golden

**Concepts:** `RotationalDynamics`

**Comments:** none yet

Golden outputs of the rotation functions.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m5-rotation.json` | Manifest of the rotation golden. | `RotationalDynamics` |
| `Cpp_implementation/tests/golden/m5-rotation/derived.json` | Derived golden values for the rotation group. | `RotationalDynamics` |
| `Cpp_implementation/tests/golden/m5-rotation/files.txt` | File list of the rotation golden. | `RotationalDynamics` |
| `harness/drivers/m5_rotation.bas` | Driver of the rotation golden. | `RotationalDynamics` |
| `Cpp_implementation/tests/physics_rotation_test.cpp` | Test file of the rotation group. | `RotationalDynamics` |

## Helper golden

**Concepts:** `SmoothingHelpers`

**Comments:** none yet

Golden outputs of the smoothing helpers. The plain manifest is superseded and cited for reference only.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m5-helpers-2.json` | Manifest of the current helper golden. | `SmoothingHelpers` |
| `manifests/reference_store/m5-helpers.json` | Superseded manifest, cited for reference only. | `SmoothingHelpers` |
| `Cpp_implementation/tests/golden/m5-helpers-2/derived.json` | Derived golden values for the helper group. | `SmoothingHelpers` |
| `Cpp_implementation/tests/golden/m5-helpers-2/files.txt` | File list of the helper golden. | `SmoothingHelpers` |
| `harness/drivers/m5_helpers.bas` | Driver of the helper golden. | `SmoothingHelpers` |
| `Cpp_implementation/tests/physics_helpers_test.cpp` | Test file of the helper group. | `SmoothingHelpers` |

## E2 cascade golden

**Concepts:** `E2Cascade`

**Comments:** none yet

Golden outputs of the E2 cascade.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m5-e2_cascade.json` | Manifest of the E2 cascade golden. | `E2Cascade` |
| `Cpp_implementation/tests/golden/m5-e2_cascade/derived.json` | Derived golden values for the E2 cascade group. | `E2Cascade` |
| `Cpp_implementation/tests/golden/m5-e2_cascade/files.txt` | File list of the E2 cascade golden. | `E2Cascade` |
| `harness/drivers/m5_e2_cascade.bas` | Driver of the E2 cascade golden. | `E2Cascade` |
| `Cpp_implementation/tests/physics_e2_cascade_test.cpp` | Test file of the E2 cascade group. | `E2Cascade` |

## Low-energy gamma golden

**Concepts:** `EgammaLowTable`

**Comments:** none yet

Golden outputs of the low-energy gamma table.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m5-egamma_table.json` | Manifest of the low-energy gamma golden. | `EgammaLowTable` |
| `Cpp_implementation/tests/golden/m5-egamma_table/derived.json` | Derived golden values for the gamma table group. | `EgammaLowTable` |
| `Cpp_implementation/tests/golden/m5-egamma_table/files.txt` | File list of the gamma table golden. | `EgammaLowTable` |
| `harness/drivers/m5_egamma_table.bas` | Driver of the gamma table golden. | `EgammaLowTable` |
| `Cpp_implementation/tests/physics_egamma_table_test.cpp` | Test file of the gamma table group. | `EgammaLowTable` |

## Batch run console

**Concepts:** `RunConsole`, `SystemSetup`, `StepSetup`

**Comments:** none yet

A FreeBASIC driver prints a fixed set of text, numbers and long lines with `Print`, repeats the same statements to a file with `Print #`, then calls `Sleep` with stdin at end of file and prints one more line, which shows that it returned. Its standard output without that last line must equal the console file byte for byte. The descriptor records the command, the FreeBASIC version (1.10.1), return code 0 and the two outputs.

| Item | Holds | Concepts |
| --- | --- | --- |
| `harness/drivers/m6_console.bas` | The driver: the same statements to the console and to a file, then `Sleep` at end of input. | `RunConsole`, `SystemSetup`, `StepSetup` |
| `Cpp_implementation/tests/golden/m6-console/driver.json` | Descriptor of the run: command, FreeBASIC version, return code 0 and the two outputs. | `RunConsole`, `SystemSetup`, `StepSetup` |
| `Cpp_implementation/tests/golden/m6-console/stdout.txt` | Standard output of the driver (21 lines); its last line is printed after `Sleep` returns. | `RunConsole`, `SystemSetup`, `StepSetup` |
| `Cpp_implementation/tests/golden/m6-console/console_file.txt` | Text written to the console file by the same statements (18 lines). | `RunConsole`, `SystemSetup`, `StepSetup` |

## Batch run stdout

**Concepts:** `RunConsole`, `RunEnding`

**Comments:** none yet

Each captured run, set-up only or full, adds one line to a run table: its index, its mode, two numbers and a hash of its standard output. The table is store-derived from the seven captures that the other derived tables also use: the full-run, pass, plot and patch-check captures, the corpus set-up capture, the seventh edge capture and the restart capture.

| Item | Holds | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/golden/m6-stdout/derived.json` | Store-derived descriptor: output `runs.txt`, 906 to 912 source files. | `RunConsole`, `RunEnding` |
| `Cpp_implementation/tests/golden/m6-stdout/runs.txt` | The run table: one line per captured run (188 lines). | `RunConsole`, `RunEnding` |

## Batch run plan

**Concepts:** `RunPlan`, `FileLoop`, `SystemLoop`

**Comments:** none yet

The plan golden lists the run plan of every captured run: for each run, its capture and input, its mode, and its systems with their nucleus and status. It is store-derived from the same seven captures as the run table.

| Item | Holds | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/golden/m6-plan/derived.json` | Store-derived descriptor: output `plan.txt`, 906 to 912 source files. | `RunPlan`, `FileLoop`, `SystemLoop` |
| `Cpp_implementation/tests/golden/m6-plan/plan.txt` | The run plans (22,231 lines): a header, then one block per run with its mode and systems. | `RunPlan`, `FileLoop`, `SystemLoop` |

## Batch set-up probes

**Concepts:** `SetupProbes`, `BatchInputFiles`, `SetupStages`, `StepSetup`

**Comments:** none yet

The P0 golden lists the sequence files in the order the probe reads them, with reference paths and hashes, and gives one fingerprint per P0 record. The set-up golden gives one fingerprint per P1 record of the set-up runs; its header lists the variables left out of the full fingerprint. Both are store-derived from the seven captures.

| Item | Holds | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/golden/m6-p0/derived.json` | Store-derived descriptor: outputs `plan.txt` and `fingerprints.txt`, 906 to 912 source files. | `SetupProbes`, `BatchInputFiles`, `SetupStages`, `StepSetup` |
| `Cpp_implementation/tests/golden/m6-p0/plan.txt` | The sequence files of the P0 probe in order, with reference paths and hashes (1,360 lines). | `SetupProbes`, `BatchInputFiles`, `SetupStages`, `StepSetup` |
| `Cpp_implementation/tests/golden/m6-p0/fingerprints.txt` | One fingerprint per P0 record (316 lines). | `SetupProbes`, `BatchInputFiles`, `SetupStages`, `StepSetup` |
| `Cpp_implementation/tests/golden/m6-setup/derived.json` | Store-derived descriptor: output `fingerprints.txt`, 906 to 912 source files. | `SetupProbes`, `BatchInputFiles`, `SetupStages`, `StepSetup` |
| `Cpp_implementation/tests/golden/m6-setup/fingerprints.txt` | One fingerprint per P1 record of the set-up runs (39,766 lines). | `SetupProbes`, `BatchInputFiles`, `SetupStages`, `StepSetup` |

## Batch set-up captures

**Concepts:** `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding`

**Comments:** none yet

Set-up-only runs, built with the probe hooks and the set-up-only switch, of the corpus list and the edge list, plus a restart capture. The edge captures supersede one another as their notes state: the second supersedes the first, the third supersedes both, the fifth supersedes the fourth, the sixth the fifth and the seventh the sixth, so the seventh is the one the derived tables use. The edge inputs include empty energy lines, a file.in without a sequence file, the plot and pass-schedule inputs, and stale-state restarts; the corpus capture covers the wrkdir and validation groups.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m6-setup-corpus.json` | Set-up-only runs of every corpus entry in the wrkdir and validation groups, with the T0 probe file removed. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |
| `manifests/reference_store/m6-setup-edge.json` | Set-up-only runs of the first edge list; superseded by the second capture. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |
| `manifests/reference_store/m6-setup-edge-2.json` | The edge list again, with e_sched_es_endf now running ES then EM; superseded by the third capture. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |
| `manifests/reference_store/m6-setup-edge-3.json` | The edge list with e_sched_es_endf running ES then EM and e_missing_nuclide taking U-250 and Pu-252; supersedes the first two. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |
| `manifests/reference_store/m6-setup-edge-4.json` | Set-up-only runs of 52 edge inputs; superseded by the fifth capture. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |
| `manifests/reference_store/m6-setup-edge-5.json` | The 52 of the fourth capture plus l_empty, l_fit_only (a file.in without a sequence file), e_plot and e_plot_err; supersedes the fourth. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |
| `manifests/reference_store/m6-setup-edge-6.json` | The 56 of the fifth capture plus e_pass_fen10, e_pass_fen01 and e_pass_fen01_nominal; supersedes the fifth. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |
| `manifests/reference_store/m6-setup-edge-7.json` | The 59 of the sixth capture plus e_is_energy_empty, e_fc_energy_empty, e_endf_energy_empty and l_restart_stale; supersedes the sixth. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |
| `manifests/reference_store/m6-setup-restart.json` | Set-up-only runs of two restart inputs: one with five restart rounds, rounds 4 and 5 differing only in the stale `Emode`, ending at the E/spin check; one in fit mode that ends at the check in round 2. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |
| `harness/inputs/m6/corpus.toml` | The input list of the corpus captures: the wrkdir and validation groups. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |
| `harness/inputs/m6/edge.toml` | The input list of the edge captures. | `BatchInputFiles`, `SetupStages`, `RunRestart`, `RunEnding` |

## Batch input bounds

**Concepts:** `SequenceLines`, `BatchInputFiles`

**Comments:** none yet

An input of 5001 system lines overflows the system table, which holds 5000 entries (`S_par`). In a set-up-only build with runtime checks (`-exx`) the run stops with runtime error 6 at BASIC line 3058; in an unchecked build it aborts with SIGABRT.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m6-s-par-overflow.json` | The overflow capture: runtime error 6 at BASIC line 3058 in the checked build, SIGABRT in the unchecked build. | `SequenceLines`, `BatchInputFiles` |
| `harness/inputs/m6/edge/x_s_par_overflow.in` | The input of 5001 system lines. | `SequenceLines`, `BatchInputFiles` |

## Batch full-run captures

**Concepts:** `RunPlan`, `PassSchedule`, `RunConsole`, `RunEnding`, `SetupProbes`

**Comments:** none yet

Full runs with the probe build, which records no pass trace. Seven edge inputs run in full and are checked by a patch check against the set-up-only capture of the third edge list; three pass-schedule inputs run at two enhancement factors, with and without the error option; two plot inputs run under a 60-second limit and wait in a console input; and the m1 and m4 inputs are patch-checked, set-up only and in full, with runs trimmed to the run record, the standard output and the P0, P1 and P1b probes.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m6-full-f1-f7.json` | Full runs of l_spectra, e_two_system, e_en1, e_missing_nuclide, l_sticky, e_restart and e_sched_mixed, with the patch check against the third edge capture. | `RunPlan`, `PassSchedule`, `RunConsole`, `RunEnding`, `SetupProbes` |
| `manifests/reference_store/m6-full-passes.json` | Full runs of e_pass_fen10, e_pass_fen01 and e_pass_fen01_nominal at enhancement factors 10 and 0.1, with and without the error option. | `RunPlan`, `PassSchedule`, `RunConsole`, `RunEnding`, `SetupProbes` |
| `manifests/reference_store/m6-full-plot.json` | Full runs of e_plot and e_plot_err under a 60-second limit: each waits in a console input after the nominal pass, or after the first pass with the error option. | `RunPlan`, `PassSchedule`, `RunConsole`, `RunEnding`, `SetupProbes` |
| `manifests/reference_store/m6-patch-check-m1.json` | Patch checks of the m1 and m4 inputs; the m1 full runs are identical to the captures m1-g23-rn215-n-a and m1-g4-cf252-ref1-independent. | `RunPlan`, `PassSchedule`, `RunConsole`, `RunEnding`, `SetupProbes` |

## Reference-store captures of the bin tables

**Concepts:** `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations`

**Comments:** none yet

Each corpus entry is captured with a seed-probes build (`GEF_PROBES`, see `harness/inputs/m7/corpus.toml`) into the store entry `m7-p3-<id>`: its `run.json` and the P1, P3in and P3 probe files. The store holds all 21 corpus captures; `m7-p3-chain-gs` is superseded and has no corpus entry. Three test cases read the captures: each skips when none is present and requires records; two of them also require all 21 by a count check.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m7-p3-rn215-n.json` | Corpus entry `rn215-n`: Rn-215 (n,f) with Options(ERR); the thermal first-chance bin and the 30 MeV multi-chance bins of perturbed pass 0. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-u236-n.json` | Corpus entry `u236-n`: U-235 (n,f) nominal at thermal and at 2 MeV (fast first chance). | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-u236-9.json` | Corpus entry `u236-9`: U-235 (n,f) at 9 MeV with Options(ERR); first- and second-chance bins of perturbed pass 0. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-pu240-n.json` | Corpus entry `pu240-n`: Pu-239 (n,f) at thermal; S1 enhancement around Pu. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-np238-n.json` | Corpus entry `np238-n`: Np-237 (n,f) at thermal; odd-odd compound nucleus. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-cf252-sf.json` | Corpus entry `cf252-sf`: Cf-252 spontaneous fission. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-fm258-sf.json` | Corpus entry `fm258-sf`: Fm-258 spontaneous fission, symmetric. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-sg264-sf.json` | Corpus entry `sg264-sf`: Sg-264 spontaneous fission. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-ds270-sf.json` | Corpus entry `ds270-sf`: Ds-270 spontaneous fission at Z 110 or more; the equilibrium solve prints its not-converged message once (Q-041). | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-u-heavy-light.json` | Corpus entry `u-heavy-light` (chain entry): U-240 then U-230, FC at E* 8 MeV in one sequence file; what the heavy system leaves for the light one. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-hg180-fc.json` | Corpus entry `hg180-fc`: Hg-180 FC at E* 12 MeV; very low fissility. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-po210-fc.json` | Corpus entry `po210-fc`: Po-210 FC at E* 40 MeV; high excitation energy, mode 5. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-u236-nosupp.json` | Corpus entry `u236-nosupp`: U-235 (n,f) at thermal with Options(NOSUPP). | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-u236-mode.json` | Corpus entry `u236-mode`: U-235 (n,f) at thermal with MODE(S2). | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-u236-neo.json` | Corpus entry `u236-neo`: U-235 (n,f) at thermal with Options(NEO); EOscale 0. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-u236-eoscale.json` | Corpus entry `u236-eoscale`: U-235 (n,f) at thermal with a Fitpar.dat setting EOscale 0.5 (Q-011). | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-spectra.json` | Corpus entry `spectra`: U-236 ES, then Pu-240 EM with a three-column spectrum; Spin_CN taken from the spectrum, then EM bins with Spin_CN = 0. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-chain-en.json` | Corpus entry `chain-en` (chain entry): U-235 and Pu-239 (n,f) at thermal, 0.5 and 1.5 MeV; nominal; first chance only. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-chain-odd.json` | Corpus entry `chain-odd` (chain entry): Np-237 and Am-241 (n,f), odd-odd compound nuclei, at thermal, 0.5 and 1.5 MeV; no step runs the multi-chance pre-pass. Supersedes `m7-p3-chain-gs`. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-fm212-sf.json` | Corpus entry `fm212-sf`: Fm-212 ground state; the equilibrium solve does not converge for IZ1 = 10 and prints to the console (Q-041). | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-cm232-gs25.json` | Corpus entry `cm232-gs25`: Cm-232 ground state at 25 MeV; multi-chance bins with I_Z_Multi above 0. Manifest note: 89 multi-chance bins of pass 0, 4 with I_Z_Multi = 1 (a proton emitted before fission). | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `manifests/reference_store/m7-p3-chain-gs.json` | Superseded capture, not in the corpus; its steps ran the multi-chance pre-pass. | `BinVisits`, `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |

## Golden values of the bin captures

**Concepts:** `ModeCentres`, `ModeDeformations`

**Comments:** none yet

The store-derived golden `m7-p3` holds FNV-1a 64 fingerprints of the P3in and P3 probe files of each capture, one line per record; `python3 -m harness.p3_golden` derives it from the store. `m7_corpus_ids()` is the only helper that names it: it takes the corpus order from the first column of `fingerprints.txt`. No test compares the fingerprints with the values, which come from the store captures.

| Item | Holds | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/golden/m7-p3/derived.json` | Digests of the store files the fingerprints were derived from: `run.json`, `work/probes/P3.txt` and `work/probes/P3in.txt` of each capture. | `ModeCentres`, `ModeDeformations` |
| `Cpp_implementation/tests/golden/m7-p3/fingerprints.txt` | Per-record fingerprints; header `# m7-p3 fingerprints 1`; 475 lines in all; the first column names the corpus entry. | `ModeCentres`, `ModeDeformations` |

## Equilibrium solve sweep

**Concepts:** `ModeDeformations`

**Comments:** none yet

A sweep over the equilibrium solve (`Beta_Equi`) from an earlier submilestone, stored as a capture: its program and its outputs, which carry the solve's messages (Q-041). The capture holds four files.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m7-d6-sweep.json` | Capture manifest of the sweep: program `sweep.cpp`, a README and two output files (`out_dneck1_v2.txt`, `out_dneck_set.txt`); 4 files, 66,999 bytes. | `ModeDeformations` |

## Q-061 reference run

**Concepts:** `MeanChargeAndRelations`

**Comments:** none yet

One reference run for Z 120 and A 385, a ground state. The input validity check (`U_Valid`) accepts it. The table builder then indexes `Zmean` and `Zshift` past their bound of 350, and the reference binary stops with SIGSEGV (exit -11) in the event loop of the same bin, after one not-converged message of the equilibrium solve. The run is the evidence for Q-061.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m7-q061-z120a385.json` | Run record for Z 120, A 385: exit code -11; one step, no passes. | `MeanChargeAndRelations` |

## Harness inputs for the captures

**Concepts:** `BinVisits`, `CarriedBinTables`, `ModeDeformations`, `MeanChargeAndRelations`

**Comments:** none yet

The corpus lists the 21 inputs of the captures. Every entry sets `Fenhance` 1 and its own seed; the entries marked `chain` (`u-heavy-light`, `chain-en`, `chain-odd`) are the end-to-end runs. The last-writer map gives each P3 variable its kind, its last part and its writers (`-` means none); the later-writers test reads it through `last_writer_map()`. `python3 -m harness.last_writer` regenerates it, and the harness README gives its `--check` option.

| Item | Holds | Concepts |
| --- | --- | --- |
| `harness/inputs/m7/corpus.toml` | The 21 corpus entries, one `[[entry]]` each; each capture is `m7-p3-<id>`. | `BinVisits`, `CarriedBinTables`, `ModeDeformations`, `MeanChargeAndRelations` |
| `harness/inputs/m7/last_writer.tsv` | Last-writer map: header `# m7 last-writer map 1`, 363 lines, columns name, kind, last part and writers. | `BinVisits`, `CarriedBinTables`, `ModeDeformations`, `MeanChargeAndRelations` |

## Seed-build reference captures

**Concepts:** `SeedCapture`, `CleanRunRunner`, `PatchedBuilds`
**Comments:** none yet

Four captured references of the first identity check, for the Cf-252 and Rn-215 short inputs. Each capture is a run of the original reference binary under the debugger, with the clock seed read and recorded. Each run folder replays the same captured seed with the seed build (patch set seed) and is compared with its capture after the time-dependent fields are masked. The equivalence record in the reference binary manifest reports the masked comparison as identical for 42 files (Cf-252) and 244 files (Rn-215 short); the run folders hold 43 and 245 files.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m1-g1-cf252-gefref.json` | Capture of the Cf-252 input under the debugger; 46 files; seed read from the clock. | `SeedCapture`, `CleanRunRunner`, `PatchedBuilds` |
| `manifests/reference_store/m1-g1-cf252-ref1.json` | Seed-build run of the Cf-252 input replaying the captured seed; 43 files. | `SeedCapture`, `CleanRunRunner`, `PatchedBuilds` |
| `manifests/reference_store/m1-g1-rn215-gefref.json` | Capture of the Rn-215 short input under the debugger; 248 files; seed read from the clock. | `SeedCapture`, `CleanRunRunner`, `PatchedBuilds` |
| `manifests/reference_store/m1-g1-rn215-ref1.json` | Seed-build run of the Rn-215 short input replaying the captured seed; 245 files. | `SeedCapture`, `CleanRunRunner`, `PatchedBuilds` |

## Repeatability and neutrality runs

**Concepts:** `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner`
**Comments:** none yet

Eleven runs of the Rn-215 short input with seed 20261007, made by the repeatability and neutrality step of the gate script. The normal runs use the seed build and its state-probe and draw-log variants, and one normal run uses the reseed build with the reseed option off. The reseed runs use the reseed build with the reseed option on, in the same plain and instrumented variants. Each pair of runs without instrumentation repeats the other; the other normal runs are compared with the first normal run, and the other reseed runs with the first reseed run. The instrumented runs use the trace scope of steps 2 and 8, passes 0 and 31, and events 1 to 20.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m1-g23-rn215-n-a.json` | Normal run, seed build, no instrumentation; 245 files; first of its pair. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |
| `manifests/reference_store/m1-g23-rn215-n-b.json` | Normal run, seed build, no instrumentation; 245 files; second of its pair. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |
| `manifests/reference_store/m1-g23-rn215-n-probes.json` | Normal run, state-probe build, trace scope; 249 files. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |
| `manifests/reference_store/m1-g23-rn215-n-rnd.json` | Normal run, draw-log build, trace scope; 246 files. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |
| `manifests/reference_store/m1-g23-rn215-n-rp.json` | Normal run, draw-log and state-probe build, trace scope; 250 files. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |
| `manifests/reference_store/m1-g23-rn215-n-reseedinert.json` | Normal run, reseed build with the reseed option off; 245 files. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |
| `manifests/reference_store/m1-g23-rn215-r-a.json` | Reseed run, reseed build with the reseed option on, no instrumentation; 245 files; first of its pair. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |
| `manifests/reference_store/m1-g23-rn215-r-b.json` | Reseed run, reseed build with the reseed option on, no instrumentation; 245 files; second of its pair. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |
| `manifests/reference_store/m1-g23-rn215-r-probes.json` | Reseed run, state-probe reseed build, trace scope; 249 files. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |
| `manifests/reference_store/m1-g23-rn215-r-rnd.json` | Reseed run, draw-log reseed build, trace scope; 246 files. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |
| `manifests/reference_store/m1-g23-rn215-r-rp.json` | Reseed run, draw-log and state-probe reseed build, trace scope; 250 files. | `ReseedMode`, `DrawLogs`, `StateProbes`, `NeutralityProof`, `CleanRunRunner` |

## Held-out Cf-252 run

**Concepts:** `ValidityChecks`, `CleanRunRunner`, `PatchedBuilds`
**Comments:** none yet

One run of the Cf-252 input with the seed build and seed 20261008, a seed that no ensemble member uses. The real-calibration smoke test calibrates on stored members of the Cf-252 ensemble and judges this run as its held-out run, and the DMP round-trip test includes it by name. The manifest note refers to a three-way check of the first Cf-252 run, and no file named for that check is in the harness or compare directories. The gate script does not read this run.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m1-g4-cf252-ref1-independent.json` | Seed-build run of the Cf-252 input with seed 20261008, normal mode; 43 files; the held-out run. | `ValidityChecks`, `CleanRunRunner`, `PatchedBuilds` |

## Null ensemble, Cf-252 input

**Concepts:** `CalibrationEnsembles`
**Comments:** none yet

Twenty null ensemble members of the Cf-252 input, each a normal run of the reference binary ref-1 with its own seed from 2001 to 2020. These runs are the sample from which the Cf-252 calibration is built, listed in the calibration family below.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2001.json` | Member with seed 2001; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2002.json` | Member with seed 2002; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2003.json` | Member with seed 2003; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2004.json` | Member with seed 2004; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2005.json` | Member with seed 2005; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2006.json` | Member with seed 2006; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2007.json` | Member with seed 2007; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2008.json` | Member with seed 2008; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2009.json` | Member with seed 2009; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2010.json` | Member with seed 2010; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2011.json` | Member with seed 2011; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2012.json` | Member with seed 2012; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2013.json` | Member with seed 2013; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2014.json` | Member with seed 2014; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2015.json` | Member with seed 2015; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2016.json` | Member with seed 2016; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2017.json` | Member with seed 2017; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2018.json` | Member with seed 2018; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2019.json` | Member with seed 2019; 43 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-cf252-gs-s2020.json` | Member with seed 2020; 43 files. | `CalibrationEnsembles` |

## Null ensemble, Rn-215 short input

**Concepts:** `CalibrationEnsembles`
**Comments:** none yet

Twenty null ensemble members of the Rn-215 short input, each a normal run of the reference binary ref-1 with its own seed from 1001 to 1020. These runs are the sample from which the Rn-215 short calibration is built, listed in the calibration family below.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1001.json` | Member with seed 1001; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1002.json` | Member with seed 1002; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1003.json` | Member with seed 1003; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1004.json` | Member with seed 1004; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1005.json` | Member with seed 1005; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1006.json` | Member with seed 1006; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1007.json` | Member with seed 1007; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1008.json` | Member with seed 1008; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1009.json` | Member with seed 1009; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1010.json` | Member with seed 1010; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1011.json` | Member with seed 1011; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1012.json` | Member with seed 1012; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1013.json` | Member with seed 1013; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1014.json` | Member with seed 1014; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1015.json` | Member with seed 1015; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1016.json` | Member with seed 1016; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1017.json` | Member with seed 1017; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1018.json` | Member with seed 1018; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1019.json` | Member with seed 1019; 245 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m1-rn215-short-s1020.json` | Member with seed 1020; 245 files. | `CalibrationEnsembles` |

## Null ensemble, full Rn-215 input

**Concepts:** `CalibrationEnsembles`
**Comments:** none yet

Twenty null ensemble members of the full Rn-215 input, each a normal run of the reference binary ref-1 with its own seed from 3001 to 3020. These runs are the sample from which the full Rn-215 calibration is built, listed in the calibration family below.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3001.json` | Member with seed 3001; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3002.json` | Member with seed 3002; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3003.json` | Member with seed 3003; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3004.json` | Member with seed 3004; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3005.json` | Member with seed 3005; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3006.json` | Member with seed 3006; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3007.json` | Member with seed 3007; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3008.json` | Member with seed 3008; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3009.json` | Member with seed 3009; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3010.json` | Member with seed 3010; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3011.json` | Member with seed 3011; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3012.json` | Member with seed 3012; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3013.json` | Member with seed 3013; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3014.json` | Member with seed 3014; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3015.json` | Member with seed 3015; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3016.json` | Member with seed 3016; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3017.json` | Member with seed 3017; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3018.json` | Member with seed 3018; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3019.json` | Member with seed 3019; 1724 files. | `CalibrationEnsembles` |
| `manifests/reference_store/m2-ens-m2-rn215-full-s3020.json` | Member with seed 3020; 1724 files. | `CalibrationEnsembles` |

## Null calibrations

**Concepts:** `CalibrationEnsembles`, `StatisticalVerdict`
**Comments:** none yet

Three calibrations, one for each ensemble above, each built from twenty members at code revision cb1385b. A calibration is the stored null fit that the statistical verdict reads when it judges a candidate run against an ensemble.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_store/m2-cal-m1-cf252-gs.json` | Calibration of the Cf-252 ensemble, twenty members; 48 files. | `CalibrationEnsembles`, `StatisticalVerdict` |
| `manifests/reference_store/m2-cal-m1-rn215-short.json` | Calibration of the Rn-215 short ensemble, twenty members; 257 files. | `CalibrationEnsembles`, `StatisticalVerdict` |
| `manifests/reference_store/m2-cal-m2-rn215-full.json` | Calibration of the full Rn-215 ensemble, twenty members; 1787 files. | `CalibrationEnsembles`, `StatisticalVerdict` |

## Reference binaries

**Concepts:** `PatchedBuilds`, `ReferenceStore`
**Comments:** none yet

The promoted reference binary ref-1 is built from the seed patch set with FreeBASIC 1.10.1, with build identifier seed-5d9886c955fa, and was promoted on 2026-10-07. Its record holds the masked equivalence with the original reference captures, identical for 244 files of Rn-215 short and 42 files of Cf-252. The reference store also keeps a seed-probes build with the table-builder probe, whose provenance block is empty.

| Item | Holds | Concepts |
| --- | --- | --- |
| `manifests/reference_binary.json` | Promoted binary record: name ref-1, build seed-5d9886c955fa, patch set seed, FreeBASIC 1.10.1, masked equivalence results. | `PatchedBuilds`, `ReferenceStore` |
| `manifests/reference_store/binary-8f0f2ff8dccd.json` | Store record of the ref-1 binary; 5074848 bytes; created 2026-10-07. | `PatchedBuilds`, `ReferenceStore` |
| `manifests/reference_store/binary-54b0e32ba44e.json` | Store record of a seed-probes build with the table-builder probe, built with the probes define; 5471216 bytes; created 2026-10-29; provenance block empty. | `PatchedBuilds`, `ReferenceStore` |

## Capture corpora

**Concepts:** `CaptureCorpora`, `TableInputProbes`
**Comments:** none yet

Three input corpora define which captures the reference store produces. The m6 corpus is generated by the harness corpus tool and is not edited by hand; the m6 edge file holds hand-written edge-case entries; the m7 file holds hand-written table-builder entries, each with its own seed and its own trace steps and passes, captured with the seed-probes build into store entries with the prefix m7-p3-.

| Item | Holds | Concepts |
| --- | --- | --- |
| `harness/inputs/m6/corpus.toml` | Generated corpus entries; not edited by hand. | `CaptureCorpora`, `TableInputProbes` |
| `harness/inputs/m6/edge.toml` | Hand-written edge-case entries. | `CaptureCorpora`, `TableInputProbes` |
| `harness/inputs/m7/corpus.toml` | Hand-written table-builder entries, each with its own seed and trace steps and passes, captured as store entries with the prefix m7-p3-. | `CaptureCorpora`, `TableInputProbes` |

## Function-driver goldens

**Concepts:** `FunctionDrivers`
**Comments:** none yet

Eighteen function-driver goldens, one per small FreeBASIC driver program. Each driver is compiled with FreeBASIC 1.10.1, and its golden records the digests of the compiled binary and of the driver source, the command lines, includes and cuts it ran with, its return code, and the digests of the output files it wrote. The golden test reads these records.

| Item | Holds | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/golden/m3-arith-rules/driver.json` | Driver arith_rules; two command lines; two output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-arrays/driver.json` | Driver arrays; one command line and one include; three output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-conv-double/driver.json` | Driver conv_double; one command line; three output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-conv-single/driver.json` | Driver conv_single; one command line; two output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-data-input/driver.json` | Driver data_input; one command line; ten output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-format/driver.json` | Driver format; one command line; two output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-gef-math2/driver.json` | Driver gef_math2; one command line, one include and one cut; six output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-int-ops/driver.json` | Driver int_ops; one command line; four output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-math-double/driver.json` | Driver math_double; one command line; six output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-math-single/driver.json` | Driver math_single; one command line, one include and one cut; two output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-print-file/driver.json` | Driver print_file; one command line; two output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-print-using/driver.json` | Driver print_using; one command line; four output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-rnd-seeds-edge/driver.json` | Driver rnd_seeds; 24 command lines; 26 output files, including the seed files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-str-numbers/driver.json` | Driver str_numbers; one command line; six output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m3-str-single/driver.json` | Driver str_single; one command line; two output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m4-line-input/driver.json` | Driver line_input; one command line and one include; 47 output files for the line-ending cases of the line reader. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m6-console/driver.json` | Driver m6_console; one command line; two output files. | `FunctionDrivers` |
| `Cpp_implementation/tests/golden/m6-strings/driver.json` | Driver m6_strings; one command line; eight output files. | `FunctionDrivers` |

## Store-derived goldens

**Concepts:** `StoreGoldens`
**Comments:** none yet

Five derived goldens, each recording the sources and the outputs of a harness tool. Each record names the tool that computed it, and the golden test reads these records along with the driver goldens.

| Item | Holds | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/golden/m6-p0/derived.json` | Lists 912 sources; two outputs, fingerprints.txt and plan.txt; tool is the p0_golden module. | `StoreGoldens` |
| `Cpp_implementation/tests/golden/m6-plan/derived.json` | Lists 906 sources; one output, plan.txt; tool is the plan_golden module. | `StoreGoldens` |
| `Cpp_implementation/tests/golden/m6-setup/derived.json` | Lists 906 sources; one output, fingerprints.txt; tool is the setup_golden module. | `StoreGoldens` |
| `Cpp_implementation/tests/golden/m6-stdout/derived.json` | Lists 907 sources; one output, runs.txt; tool is the stdout_golden module. | `StoreGoldens` |
| `Cpp_implementation/tests/golden/m7-p3/derived.json` | Lists 63 sources; one output, fingerprints.txt; tool is the p3_golden module. | `StoreGoldens` |
