# Tests

Every test file, what it proves and the concept nodes it guards; links to [CONCEPTS](CONCEPTS.md), [CODE](CODE.md), [DEFINITIONS](DEFINITIONS.md), [TESTS](TESTS.md) and [CAPTURES](CAPTURES.md).

## Reference program and build checks

| Test | Checks | Concepts |
| --- | --- | --- |
| `tools/fbsrc/tests/test_emit_c.py` | Emitted C is deterministic and patch directories apply. | `EmittedC` |
| `tools/fbsrc/tests/test_fbline.py` | BASIC lines map to their emitted C, also in included files. | `LineLookup` |
| `tools/fbsrc/tests/test_fbdef.py` | Definitions and references of BASIC names, including `Static`, `ReDim` and `#Define`. | `DefinitionLookup` |
| `tools/fbsrc/tests/test_rbw.py` | Read-before-write sets, writers and escapes on emitted C. | `ReadBeforeWrite` |
| `tools/fbsrc/tests/test_fn_c_equiv.py` | Driver functions and pieces compile to the same C as in GEF. | `DriverEquivalence` |
| `tools/fbsrc/tests/test_gen_gef_data.py` | The generated nuclide data equals what the emitted C holds. | `EmittedC`, `ModelData` |
| `tools/toolchain/tests/test_check_toolchain.py` | Tool version parsing, the fbc pin and the manifest comparison. | `ToolchainPin` |
| `tools/toolchain/tests/test_manifest_validation.py` | Writing and verifying validation-data checksums. | `ValidationManifests` |
| `Cpp_implementation/tests/fp_environment_test.cpp` | Evaluation method, IEEE 754 formats, rounding mode and no FMA contraction. | `FpEnvironmentCheck` |
| `scripts/ci.sh` | The local CI gate itself: every preset, analysis and Python step. | `LocalCiGate`, `BuildPresets`, `StaticAnalysis` |

## FreeBASIC runtime

| Test | Checks | Concepts |
|---|---|---|
| `Cpp_implementation/tests/array_test.cpp` | Array state replay; per-dimension bounds checks. | `FbArrays` |
| `Cpp_implementation/tests/conversion_test.cpp` | Exhaustive Single conversions; Double grid; integer and Long operations. | `FbNumericConversions` `FbIntegerArithmetic` |
| `Cpp_implementation/tests/data_input_test.cpp` | DATA, READ and RESTORE replay; Val family; Input # tokens. | `DataStatements` `TextToNumber` `InputFileStatements` |
| `Cpp_implementation/tests/fbc_arithmetic_test.cpp` | Driver inputs from FbMtRng; every expression form bit for bit. | `FbArithmeticRules` `FrOperandTypes` `FrExpressionForm` `FrSingleQuotient` `FrChainHasLiteral` `FrLeftToRight` `FrFoldLast` `FrPower` `FrIntrinsicByType` |
| `Cpp_implementation/tests/format_test.cpp` | Format output byte for byte. | `FormatFunction` |
| `Cpp_implementation/tests/line_input_test.cpp` | Line Input and EOF on edge-case inputs; hang case. | `InputFileStatements` |
| `Cpp_implementation/tests/maths_test.cpp` | Exhaustive Single maths; Double grids; pow; Min, Max, Round, Modulo. | `FbIntrinsicMaths` `GefMathHelpers` |
| `Cpp_implementation/tests/print_using_test.cpp` | Every Print Using driver statement. | `PrintUsingStatement` |
| `Cpp_implementation/tests/rng_test.cpp` | Edge seeds, Rnd, Randomize, stored streams, reseed restart. | `FbRandomStream` `PerEventReseed` |
| `Cpp_implementation/tests/strings_test.cpp` | Trim, UCase, InStr, Mid, RTrim, Left, Right on golden strings. | `FbStringFunctions` |
| `Cpp_implementation/tests/text_test.cpp` | Str grids and exhaustive Single; Print # to file; console Print. | `StrFunction` `PrintFileStatement` |

## Model data

| Test | Checks | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/lookups_test.cpp` | Material-number and branch lookups for JEFF-3.3, JEFF-3.1.1 and NUBASE 2016, and the legacy NucPropx, NucPropmf and NucPropf, equal the BASIC run. | `MatLookups`, `DecayBranchings` |
| `Cpp_implementation/tests/nuclide_tables_test.cpp` | NucTab, MAT_for_ISO and Isotab match the BASIC dump for each certified variant; the NUBASE 2020 loader stops at the BASIC stop lines; the JEFF-3.1.1 table prints its N_MAT_MAX message; the other certified loaders print nothing. | `NuclideTables` |
| `Cpp_implementation/tests/params_test.cpp` | Nominal parameters and initial widths equal T0; final widths and per-system parameters equal P1; the fit parameter file at start-up and the later read equal their probes and the console; the update file equals the BASIC file; the own parameter file is read only with its flag; an unterminated comment gives the port's hang error where the BASIC program loops forever. | `NominalParameters`, `PerturbationWidths`, `ParameterLineReader`, `FitparFile`, `MyParametersFile`, `ParameterUpdateFile`, `ParameterFiles` |
| `Cpp_implementation/tests/program_data_test.cpp` | Program data reports each variant's ISOSOURCE; its items match the datachain golden per variant and start with the chain head's items; labels are case-insensitive and point at their block; a label without a DATA block is rejected. | `VariantSelection`, `EmittedNuclideC`, `DataItemLabels` |
| `Cpp_implementation/tests/table_memory_test.cpp` | Mass-table reads inside the bounds return the element; past the bounds they read the next table, as the original does; between two tables they read the allocator chunk header; before BEldmTF or after EVOD they throw; with the overrun fix, a read outside the bounds throws. | `MassTableReads`, `MassShellTables` |
| `Cpp_implementation/tests/tables_test.cpp` | T0 probe tables match the BASIC dump for the six variants; branchings print no warning for the shipped data. | `NuclideTables`, `MassShellTables`, `DecayBranchings` |
| `Cpp_implementation/tests/utilities_test.cpp` | ConvTab, CC_Count and CC_Cut reproduce fbc 1.10.1 output on the recorded line-input golden. | `ParameterFiles` |

## Physics functions

| Test | Checks | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/physics_masses_test.cpp` | Test cases for the mass functions and the mass table. | `MacroscopicMass`, `ShellCorrections`, `TabulatedMasses` |
| `Cpp_implementation/tests/physics_barriers_test.cpp` | Test cases for the barrier functions. | `FissionBarriers` |
| `Cpp_implementation/tests/physics_level_density_test.cpp` | Test cases for level density and temperature functions; some are tagged slow. | `LevelDensities`, `NuclearTemperatures` |
| `Cpp_implementation/tests/physics_shape_test.cpp` | Test cases for yield, curvature, scission and deformation minimum functions; some are tagged slow. | `FissionYields`, `CurvatureLimits`, `ScissionEquilibrium`, `DeformationMinimum` |
| `Cpp_implementation/tests/physics_rotation_test.cpp` | Test cases for inertia, giant dipole resonance and acceleration functions. | `RotationalDynamics` |
| `Cpp_implementation/tests/physics_helpers_test.cpp` | Test cases for the smoothing helpers. | `SmoothingHelpers` |
| `Cpp_implementation/tests/physics_egamma_table_test.cpp` | Test cases for the low-energy gamma table. | `EgammaLowTable` |
| `Cpp_implementation/tests/physics_e2_cascade_test.cpp` | Test cases for the E2 cascade. | `E2Cascade` |

## Run control

| Test | Checks | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/run_console_test.cpp` | The console of every captured run equals BASIC's stdout (`[T1][run]`). A full run's console pieces follow BASIC's text only where unported code runs. Sections: the printed `IMAT` numbers follow the assignments in the step body; an off-by-one `IMAT` fails; BASIC text after the last piece fails unless the run waits in unported code; an `IMAT` that gains a digit fails; a line that only ported code prints may not stand between two pieces. | `RunConsole`, `StepSetup`, `RunEnding` |
| `Cpp_implementation/tests/run_corpus_test.cpp` | Every set-up of the captured corpus equals BASIC's P0, P1 and P1b probe records (`[T1][run]`), through the batch set-up. | `SetupProbes`, `SetupStages`, `RoundSetup`, `SystemSetup`, `StepSetup` |
| `Cpp_implementation/tests/run_driver_test.cpp` | The driver repeats BASIC's files, lines, systems, steps and passes (`[T1][run]`). A restart that repeats its round hangs, as in BASIC; seven sections: fit mode does not consult the done list; a `Fenhance` of 0.1 never matches the done list; a `Fenhance` of 1 skips the line on the second round and the run ends; two missing isomers; a `Fenhance` of 0 with the records of the restarting line; fit mode leaves `Emode` as the restarting line left it; rounds that differ only in the stale `Emode`. Fit mode ends after NITER fit iterations; fit mode without the end of NITER takes the fit back edge; a hang in the first round's set-up ends the run as a hang; the driver's unreachable branches throw logic_error, six sections: a system set-up that restarts the input, a step set-up that leaves the system line, `Nextfitloop` in dialogue mode, a system line without a sequence file, a two-system line with several energies, `N_E_steps` 2 without RANDOM. | `FileLoop`, `LineLoop`, `SystemLoop`, `StepLoop`, `EnergySteps`, `PassSchedule`, `RunRestart`, `DoneRecords`, `RunEnding`, `SetupStages` |
| `Cpp_implementation/tests/run_input_test.cpp` | Every sequence-file parse of the captured corpus equals BASIC's P0 record (`[T1][run]`). More than 5000 system lines overflow `S_par` (edge input). `WorkDir` names a file as `fb_FileExists` and `Open` do. | `BatchFileOptions`, `SequenceFileHeader`, `EnergyTableRead`, `SequenceLines`, `SetupProbes`, `RunWorkDir` |
| `Cpp_implementation/tests/run_setup_test.cpp` | Dialogue branches of set-up throw logic_error outside batch mode: the `lmd` name, an unbound compound nucleus (`CN`), and energy lines. A barrier switch outside the cases of `BFTF` is a logic_error. An input file that exists but cannot be opened is a logic_error: a sequence file, a spectrum file, and `file.in` found and then gone. | `SystemSetup`, `StepSetup`, `BatchInputFiles`, `RunWorkDir` |

## Model tables

| Test | Checks | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/bin_tables_bins_test.cpp` | Bin plan, nominal copies and carried spin of the bin tables. | `BinVisits`, `NominalWorkingCopies`, `CarriedBinTables` |
| `Cpp_implementation/tests/bin_tables_bins_test.cpp::tables: multi-chance bins run N, Z up and E* down, with protons emitted` | Multi-chance bins step N and Z up and the excitation energy down, with protons emitted. | `BinVisits`, `MtMultiChance`, `MtGrid` |
| `Cpp_implementation/tests/bin_tables_bins_test.cpp::tables: EM and ES passes leave the last iteration's spin, populated or not` | EM and ES passes leave the last iteration's spin, whether or not the bins are populated. | `CarriedBinTables`, `MtSpectrumPoint` |
| `Cpp_implementation/tests/bin_tables_bins_test.cpp::tables: the bins and bin inputs of every M7 capture equal BASIC's` | Bins and bin inputs of every capture equal the reference values. | `BinVisits` |
| `Cpp_implementation/tests/bin_tables_bins_test.cpp::tables: nominal passes copy the nominal parameters into the working copies` | Nominal passes copy the nominal parameters into the working copies. | `NominalWorkingCopies` |
| `Cpp_implementation/tests/bin_tables_deformations_test.cpp` | Mode centres, mode deformations and mean-charge relations. | `ModeCentres`, `ModeDeformations`, `MeanChargeAndRelations` |
| `Cpp_implementation/tests/bin_tables_deformations_test.cpp::tables: the later writers of beta, Edefo and Zshift are those the M7.1 test excludes` | Writers of beta, Edefo and Zshift outside the earlier block equal the expected lines. | `ModeDeformations`, `MeanChargeAndRelations` |
| `Cpp_implementation/tests/bin_tables_deformations_test.cpp::tables: mode centres and deformations equal BASIC from P3in` | Mode centres and deformations equal the reference values from the P3in probe. | `ModeCentres`, `ModeDeformations` |
| `Cpp_implementation/tests/bin_tables_deformations_test.cpp::tables: a CN with A above 360 stops at the bound of Zmean and Zshift` | A compound nucleus above mass 360 throws out_of_range and keeps one not-converged message (Q-061 changes this). | `MeanChargeAndRelations` |

## Event generation, result analysis and output writing

| Test | Checks | Concepts |
| --- | --- | --- |
| `Cpp_implementation/tests/analyzer_registry_test.cpp` | Analyzer table bounds and every field match stored reference fingerprints for six variants. | `AnalyzerRegistry` |

## Reference harness and comparison

| Test | Checks | Concepts |
| --- | --- | --- |
| `harness/tests/test_arglog.py` | Argument log patch generator and reader. | `ArgumentLog` |
| `harness/tests/test_build.py` | Patch sets, build identifiers, compiler options, binary sections and the seed patch. | `PatchedBuilds` |
| `harness/tests/test_capture_seed.py` | Seed capture script generation, result parsing and binary verification. | `SeedCapture` |
| `harness/tests/test_compare_runs.py` | Run comparison on synthetic run directories. | `CleanRunRunner` |
| `harness/tests/test_corpus.py` | Corpus manifests, input destinations, run-directory layout, probe differences and the patch check. | `CaptureCorpora`, `NeutralityProof` |
| `harness/tests/test_driver.py` | Driver directives, cut lines, work files and driver builds. | `FunctionDrivers` |
| `harness/tests/test_fbmt.py` | Known answers of the random generator transcription, taken from the real driver. | `DrawLogs` |
| `harness/tests/test_golden.py` | Committed driver goldens are current, and staleness is detected. | `FunctionDrivers`, `StoreGoldens` |
| `harness/tests/test_m7_corpus.py` | Capture corpus manifest, table-input golden derivation, the last-writer map and the absence of a multi-chance pre-pass in chain captures. | `CaptureCorpora`, `PrepassProbe`, `StoreGoldens`, `TableInputProbes` |
| `harness/tests/test_p0_golden.py` | Sequence-probe golden derivation on synthetic captures. | `SequenceProbe`, `StoreGoldens` |
| `harness/tests/test_plan_golden.py` | Plan-capture golden derivation on synthetic captures. | `StoreGoldens` |
| `harness/tests/test_probe_fingerprints.py` | Probe fingerprint grouping, hashing and golden rendering. | `StoreGoldens` |
| `harness/tests/test_probes.py` | Probes patch and probe-record reader on synthetic files, the module-level and pre-pass values of the built probes; the build tests need a FreeBASIC compiler. | `ModuleStartProbe`, `PrepassProbe`, `ProbeFormat`, `StateProbes` |
| `harness/tests/test_reseed.py` | Seed derivation vectors, reseed patch sites and the scope analysis of the draw log. | `ReseedMode`, `DrawLogs` |
| `harness/tests/test_rndlog.py` | Draw-log line parsing and summaries, with the scope and draw-log patches. | `DrawLogs`, `ProbeFormat` |
| `harness/tests/test_run.py` | Run module driven by a fake binary, a shell script. | `CleanRunRunner` |
| `harness/tests/test_setup_golden.py` | Setup-step golden derivation on synthetic captures. | `StepSetupProbes`, `StoreGoldens` |
| `harness/tests/test_store.py` | Reference store operations, with all roots in a temporary directory. | `ReferenceStore` |
| `harness/tests/test_stdout_golden.py` | Console-output golden derivation on synthetic captures. | `StoreGoldens` |
| `compare/tests/test_discrete.py` | Binomial score, p-values of sparse count families, planted shifts in sparse bins and cells with their own dispersion. | `CmBinomial`, `CmFamilyP`, `CmLowCount`, `CmVariance`, `StatisticalVerdict` |
| `compare/tests/test_dmp.py` | DMP-format parser: round trip, observables, time stamps and wrapped data. | `OutputParsers` |
| `compare/tests/test_endf.py` | ENDF-format parser: float fields, round trip, line-ending and empty-file edge cases, and real library tapes. | `OutputParsers`, `ParserFidelity` |
| `compare/tests/test_exact.py` | Exact comparator: identical values, one-unit differences in the last place, NaN and signed zero, and the command-line run. | `ExactComparison` |
| `compare/tests/test_extract.py` | Per-run extract: packing round trip, duplicate keys, run alignment, cache keys and agreement with the loader on a real capture. | `RunLoading` |
| `compare/tests/test_gates.py` | Aggregation of check results on synthetic inputs, the sensitivity table criterion, resumable null runs and the command-line checks. | `ValidityChecks`, `FaultInjection` |
| `compare/tests/test_inject.py` | Synthetic fault kinds on the extracted table (yield scaling, mass-bin move, isomer move), their sites and their minimum detectable effects. | `FaultInjection`, `StatisticalVerdict` |
| `compare/tests/test_loader.py` | Run loader: two directory layouts, streamed file loading, non-directory input and real layouts for every parser. | `RunLoading` |
| `compare/tests/test_mvd.py` | MVD-format parser: synthetic round trip and observables, repeated identifiers, errors and real files. | `OutputParsers`, `ParserFidelity` |
| `compare/tests/test_out.py` | OUT-format parser: table layouts, repeated keys, decay tables, dense arrays and coverage accounting. | `OutputParsers` |
| `compare/tests/test_par.py` | PAR-format parser: synthetic round trip and structure, repeated names, errors and real files. | `OutputParsers`, `ParserFidelity` |
| `compare/tests/test_probe_adapter.py` | Probe adapter: exact values and keys, T0 context, parse errors and the draw log left unparsed by design. | `OutputParsers`, `ProbeFormat` |
| `compare/tests/test_real_calibration.py` | Calibration and verdict smoke run on the first real Cf-252 ensemble members and the held-out run. | `CalibrationEnsembles`, `StatisticalVerdict`, `ValidityChecks` |
| `compare/tests/test_stats.py` | Field classes, variance model, leave-one-out null law of the deviation statistic, Holm step-down, Sidak correction, local null laws, critical values and degenerate families. | `CmFamilyP`, `CmFieldClass`, `CmHolm`, `CmNull`, `CmVariance`, `StatisticalVerdict` |
| `compare/tests/test_text.py` | Generic text parser: numbers and templates, stable keys under line edits, masked times and byte-exact round trips. | `OutputParsers` |
| `compare/tests/test_verdict.py` | Calibration and verdict on synthetic ensembles with known distributions: manifests, leave-one-out records, hard failures, false-alarm rate on null suites, detection around the minimum detectable effect and the Holm total option. | `CalibrationEnsembles`, `CmDeviation`, `CmFail`, `CmHard`, `CmHolm`, `CmNull`, `CmPass`, `CmVariance`, `StatisticalVerdict` |
| `Cpp_implementation/tests/probe_dump_test.cpp` | Probe-record writer in the C++ support code: scalar and array field formats, sparse arrays, line fingerprints and parsing of a committed fingerprint golden. | `ProbeFormat`, `StoreGoldens` |
| `harness/gates.sh` | Long-running on-demand checks G1 to G4: seed build identity, repeatability, neutrality and the statistical judgment of the reference runs. | `SeedCapture`, `NeutralityProof`, `CleanRunRunner`, `CalibrationEnsembles`, `StatisticalVerdict` |
