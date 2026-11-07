# Code

This map from concept nodes to code links to [CONCEPTS](CONCEPTS.md), [CODE](CODE.md), [DEFINITIONS](DEFINITIONS.md), [TESTS](TESTS.md) and [CAPTURES](CAPTURES.md). Paths are relative to the repository root; symbols are whole words in the file before them; no line numbers.

## Reference program and build checks

| Node | Code | Notes |
| --- | --- | --- |
| `BasicSource` | `Reference/GEF_code/source/GEF.bas` | The main program; its includes sit beside it in the pinned submodule. |
| `EmittedC` | `tools/fbsrc/emit_c.py` `emit` `main` | Deterministic `fbc -gen gcc` translation, with optional patch directories. |
| `ReferenceBinary` | `manifests/reference_binary.json` `binary_sha256` | Provenance of the seeded reference binary `ref-1`. |
| `LineLookup` | `tools/fbsrc/fbline.py` `lookup` `main` | BASIC lines and the C emitted from them. |
| `DefinitionLookup` | `tools/fbsrc/fbdef.py` `find_definitions` `find_references` | Case-insensitive definitions and whole-word references. |
| `ReadBeforeWrite` | `tools/fbsrc/rbw.py` `analyse` `writers` `escapes` | Must-defined analysis over the emitted C. |
| `DriverEquivalence` | `tools/fbsrc/fn_c_equiv.py` `compare_function` `compare_piece` | Driver C against GEF's C, per function or cut piece. |
| `QuirkRegister` | `Planning/QUIRKS.md` | Quirk entries Q-001…, build notes B-001…; code marks each reproduced quirk with `QUIRK(Q-0xx)`. |
| `FidelitySwitch` | `Cpp_implementation/src/data/tables.hpp` `fix_table_overrun` `Cpp_implementation/src/data/table_memory.cpp` `fix_table_overrun` | The first fidelity switch (Q-042); off reproduces BASIC. |
| `CompilerPolicy` | `Cpp_implementation/cmake/GefCompilerPolicy.cmake` `gef_exact_fp` `gef_warnings` `gef_apply_policy` | Exact-mode FP flags and warnings-as-errors. |
| `BuildPresets` | `CMakePresets.json` `dev-gcc` `dev-clang` `asan-ubsan` `tsan` `release-exact` | Configure and test presets. |
| `FpEnvironmentCheck` | `Cpp_implementation/src/fbrt/fp_environment.hpp` `check_flt_eval_method` `check_iec559` `check_round_to_nearest` `check_no_fma_contraction` `check_fp_environment` | Four checks and the combined report. |
| `VersionReport` | `Cpp_implementation/src/app/main.cpp` `print_version` `Cpp_implementation/src/app/build_info.hpp` | `gef --version`. |
| `ToolchainPin` | `tools/toolchain/check_toolchain.py` `check_tool` `check_fbc` `check_fbc_tarball` `compare_manifest` `manifests/toolchain.txt` | Tool versions and the fbc tarball checksum against the committed manifest. |
| `ValidationManifests` | `tools/toolchain/manifest_validation.py` `write_manifest` `verify_manifest` | Checksums of `validation/`; exit 77 without it. |
| `StaticAnalysis` | `.clang-tidy` `Checks` `WarningsAsErrors` `.clang-format` `BasedOnStyle` `pyproject.toml` | clang-tidy, clang-format, ruff and basedpyright settings. |
| `LocalCiGate` | `scripts/ci.sh` `run_step` `quick` | Full and `--quick` runs, one summary line per step. |

## FreeBASIC runtime

| Node | Code | Notes |
|---|---|---|
| `FbArithmeticRules` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R1` `R2` `R3` `R4` `R5` `R6` `R7` `R8` `R9` `R10` `Cpp_implementation/src/physics/shape.cpp` `approach_36` `scission_energy` `getyield` `Cpp_implementation/tests/fbc_arithmetic_test.cpp` `evaluate` `expression_count` | The rule note numbers the rules R1 to R10; the physics code and the evaluator show them applied to real expressions. |
| `FbIntrinsicMaths` | `Cpp_implementation/src/physics/shape.cpp` `f1` `f2` `getyield` `masscurv` `exp` `log` `pow` | No fbrt wrapper exists; the physics call sites show the intrinsics, and the argument type selects the precision (rule R7). |
| `FbNumericConversions` | `Cpp_implementation/src/fbrt/convert.hpp` `fix` `sgn` `Cpp_implementation/src/fbrt/convert.cpp` `f2i` `f2l` `f2ul` `d2i` `d2l` `d2ul` `truncate_indefinite` `to_uint64` `nearbyint` `fix` `sgn` | Rounds to nearest with ties to even through nearbyint, and gives the x86-64 result when the value is out of range (rule R8). |
| `FbIntegerArithmetic` | `Cpp_implementation/src/fbrt/convert.hpp` `idiv` `imod` `Cpp_implementation/src/fbrt/convert.cpp` `add` `sub` `mul` `neg` `abs` `idiv` `imod` `check_division` | Add, subtract, multiply, negate and absolute value wrap on overflow; undefined integer division and Mod trap as domain errors (quirk B-002). |
| `GefMathHelpers` | `Cpp_implementation/src/fbrt/gef_math.hpp` `erf` `erfc` `tanh` `coth` `log10` `floor` `ceil` `round` `modulo` `Cpp_implementation/src/fbrt/gef_math.cpp` `min` `max` `erf` `erfc` `tanh` `coth` `log10` `floor` `ceil` `round` `modulo` | Ported as written in GEF, not taken from the standard library. |
| `FbRandomStream` | `Cpp_implementation/src/fbrt/rng.hpp` `FbMtRng` `randomize` `rnd` `next_u32` `state_size` `randomize_seed_bits` `Cpp_implementation/src/fbrt/rng.cpp` `randomize_seed_bits` `seed_state` `twist` `mix` | The generator, Randomize seeding and Rnd; rng_test checks the sequence against stored streams. |
| `PerEventReseed` | `Cpp_implementation/src/fbrt/reseed.hpp` `ReseedScope` `derive_seed` `reseed` `Cpp_implementation/src/fbrt/reseed.cpp` `splitmix64` `derive_seed` `reseed` | Scopes and derivation follow the reseed spec; no caller exists in the source tree yet. |
| `FbArrays` | `Cpp_implementation/src/fbrt/array.hpp` `Array` `Bounds` `redim` `redim_preserve` `erase` `lbound` `ubound` `allocated` `elements` | Index ranges per dimension, with bounds checked on each access. |
| `FbStringFunctions` | `Cpp_implementation/src/fbrt/strings.hpp` `trim` `rtrim` `ucase` `instr` `mid` `left` `right` `Cpp_implementation/src/fbrt/strings.cpp` `char_index` `find_bm` `trailing_end` `trim` `rtrim` `ucase` `instr` `mid` `left` `right` | Covers the Milestone 4 and Milestone 6 string work items; see the Notes section. |
| `StrFunction` | `Cpp_implementation/src/fbrt/text.hpp` `str` `Cpp_implementation/src/fbrt/text.cpp` `str` `float_print_text` `strip_dot` | Converts Single, Double and LongInt values to text. |
| `FormatFunction` | `Cpp_implementation/src/fbrt/format.hpp` `format` `Cpp_implementation/src/fbrt/format.cpp` `format` `MaskInfo` `decode_date` `decode_time` `weekday_of` `days_in_month` `int_log10_32` `int_log10_64` | Calendar and digit-count helpers sit beside the format function in format.cpp. |
| `PrintFileStatement` | `Cpp_implementation/src/fbrt/text.hpp` `PrintEnd` `PrintFile` `print` `print_void` `tab` `Cpp_implementation/src/fbrt/text.cpp` `PrintFile::write` `pad` `print_item` `print_void` `print` `tab` | A comma moves output to the next 14-column print zone. |
| `PrintUsingStatement` | `Cpp_implementation/src/fbrt/text.hpp` `using_init` `using_print` `using_end` `Cpp_implementation/src/fbrt/print_using.cpp` `PrintFile::using_init` `using_text` `using_print` `using_real` `using_end` `scale_to_ull` `num_digits` `digit_char` | Numeric fields use the scale and digit helpers; the templates note gives the field syntax. |
| `DataStatements` | `Cpp_implementation/src/fbrt/data_reader.hpp` `DataReader` `restore` `read_single` `read_double` `read_longint` `read_string` `position` `Cpp_implementation/src/fbrt/data_reader.cpp` `restore` `read_single` `read_double` `read_longint` `read_string` | One reader holds the DATA items and the read position. |
| `TextToNumber` | `Cpp_implementation/src/fbrt/input.hpp` `val` `vallng` `valint` `Cpp_implementation/src/fbrt/input.cpp` `skip_blanks` `amp_radix` `radix_value` `val` `vallng` `valint` | Radix prefixes go through amp_radix and radix_value. |
| `InputFileStatements` | `Cpp_implementation/src/fbrt/input.hpp` `InputFile` `Cpp_implementation/src/fbrt/input.cpp` `at_end` `line_input` `eof` `data_at_end` `read_char` `unread_char` `skip_white` `skip_delimiter` `next_token` `input_single` `input_double` `input_longint` `input_string` | next_token reads the items of Input #; unread_char puts a character back. |
| `FrOperandTypes` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R1` `R2` `Cpp_implementation/tests/fbc_arithmetic_test.cpp` `evaluate` | Rule R1 types the literals and R2 sets the precision of each operation; E7 and E16 check them. |
| `FrExpressionForm` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R3` `R4` `R5` `R6` `R7` `Cpp_implementation/tests/fbc_arithmetic_test.cpp` `evaluate` `expression_count` | The top-level operation picks the rule; the driver has one result column per evaluator form. |
| `FrSingleQuotient` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R3` `Cpp_implementation/src/physics/shape.cpp` `getyield` `Cpp_implementation/tests/fbc_arithmetic_test.cpp` `evaluate` | getyield narrows its Single quotients through Double; E10 checks the same form. |
| `FrChainHasLiteral` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R4` `Cpp_implementation/src/physics/shape.cpp` `f1` `f2` `approach_36` `Cpp_implementation/tests/fbc_arithmetic_test.cpp` `evaluate` | f1 and f2 add their constants last; E1, E8 and E18 check the literal placement. |
| `FrLeftToRight` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R5` `Cpp_implementation/src/physics/shape.cpp` `scission_energy` `Cpp_implementation/tests/fbc_arithmetic_test.cpp` `evaluate` | Chains without a literal group from the left, as in scission_energy; E5 and E6 check parentheses. |
| `FrIsLiteralOverSum` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R10` `Cpp_implementation/src/physics/shape.cpp` `approach_36` | approach_36 shows the rewrite that rule R10 describes, with 32.4 added last; no evaluator case covers it. |
| `FrLiteralDistributed` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R10` `Cpp_implementation/src/physics/shape.cpp` `approach_36` | The 0.9 multiplier is distributed over a sum that holds 36, and the products fold into 32.4; no evaluator case covers it. |
| `FrFoldLast` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R4` `Cpp_implementation/tests/fbc_arithmetic_test.cpp` `evaluate` | E4 and E15 fold literals in Double and apply the folded constant last. |
| `FrPower` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R6` `Cpp_implementation/src/physics/shape.cpp` `rotation_term` `masscurv` `pow` `Cpp_implementation/tests/fbc_arithmetic_test.cpp` `evaluate` | E12 squares a Single as a product; E13 raises to the third power through pow in Double. |
| `FrIntrinsicByType` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R7` `Cpp_implementation/src/physics/shape.cpp` `f1` `f2` `getyield` `exp` `log` `Cpp_implementation/tests/fbc_arithmetic_test.cpp` `evaluate` | E17 takes the Double exponential because its argument is Double (rule R7). |
| `FrSelfCompareFolded` | `Cpp_implementation/src/fbrt/FBC_ARITHMETIC.md` `R9` `Cpp_implementation/src/fbrt/fp_environment.cpp` `check_iec559` | check_iec559 relies on a NaN compared with itself, which rule R9 keeps in an expression; no evaluator case covers it. |

## Model data

| Node | Code | Notes |
| --- | --- | --- |
| `NuclideTables` | `Cpp_implementation/src/data/nuclide_tables.cpp`: `build_isotab`, `load_plain`, `load_nubase2020`, `load_nuclide_tables`, `GefStopped` | Loaders for the plain and NUBASE 2020 nuclide lists, with their stop messages. |
| `NuclideTables` | `Cpp_implementation/src/data/nuclide_tables.hpp`: `load_nuclide_tables` | Loader entry point. |
| `NuclideTables` | `Cpp_implementation/src/data/tables.hpp`: `NucProp`, `IsoProp`, `nuc_tab`, `mat_for_iso`, `isotab`, `n_iso_tot`, `n_mat_max`, `GefStopped` | Storage of the nuclide and isotope tables. |
| `DecayBranchings` | `Cpp_implementation/src/data/branchings.cpp`: `load_branchings` | Loader for the branch table, which stops at Ra-234 as the original does. |
| `DecayBranchings` | `Cpp_implementation/src/data/table_loaders.hpp`: `load_branchings` | Loader declaration. |
| `DecayBranchings` | `Cpp_implementation/src/data/tables.hpp`: `BranchRecord`, `branch_data`, `z_min_branching`, `z_max_branching` | Branch records and the Z range the default mode applies to. |
| `DecayBranchings` | `Cpp_implementation/src/data/lookups.cpp`: `ibranch_for_zai` | Decay mode of a nucleus, with the default mode for nuclei the table does not list. |
| `DecayBranchings` | `Cpp_implementation/src/data/lookups.hpp`: `ibranch_for_zai` | Lookup declaration. |
| `MassShellTables` | `Cpp_implementation/src/data/mass_tables.cpp`: `load_mass_tables` | Loader for the five mass tables. |
| `MassShellTables` | `Cpp_implementation/src/data/table_loaders.hpp`: `load_mass_tables` | Loader declaration. |
| `MassShellTables` | `Cpp_implementation/src/data/tables.hpp`: `beldm_tf`, `be_exp`, `defo_tab`, `shell_mo`, `evod` | Storage of the five mass tables. |
| `MassTableReads` | `Cpp_implementation/src/data/table_memory.cpp`: `read_mass_table`, `size_word`, `inside`, `place` | Reads from the mass-table memory, with the out-of-range behaviour of the original program. |
| `MassTableReads` | `Cpp_implementation/src/data/table_memory.hpp`: `MassTable`, `read_mass_table` | Mass-table enumeration and read interface. |
| `MassTableReads` | `Cpp_implementation/src/data/tables.hpp`: `fix_table_overrun` | The switch that turns out-of-range reads into errors. |
| `MatLookups` | `Cpp_implementation/src/data/lookups.cpp`: `form_of`, `i_mat_endf`, `i_mat_endf_mac`, `i_mat_endf_jeff311`, `i_mat_endf_legacy`, `n_iso_mat`, `r_awr_endf`, `iso_for_mat`, `iso_for_za`, `nstates_for_za` | Material-number lookups for each lookup form, and the nucleus queries built on them. |
| `MatLookups` | `Cpp_implementation/src/data/lookups.hpp`: `MatNumberState`, `i_mat_endf`, `n_iso_mat`, `r_awr_endf`, `iso_for_mat`, `iso_for_za`, `nstates_for_za` | Declarations, including the MatNumberState type. |
| `NominalParameters` | `Cpp_implementation/src/params/parameters.hpp`: `Parameters`, `NominalParameter`, `nominal_parameters`, `load_parameters_bas` | Nominal parameter table and its loader declarations. |
| `NominalParameters` | `Cpp_implementation/src/params/parameters.cpp`: `load_parameters_bas`, `nominal_parameters` | Loads the nominal parameter values. |
| `PerturbationWidths` | `Cpp_implementation/src/params/parameters.hpp`: `PerturbationWidths`, `initial_widths`, `update_widths`, `WidthParameter`, `width_parameters` | Width table, the initial widths and their per-system update. |
| `PerturbationWidths` | `Cpp_implementation/src/params/parameters.cpp`: `initial_widths`, `update_widths`, `width_parameters` | Sets the initial widths and updates them for each system. |
| `PerturbedParameterList` | `Cpp_implementation/src/params/parameters.hpp`: `PerturbedParameter`, `perturbation_order` | The perturbed-parameter entries and their fixed draw order. |
| `PerturbedParameterList` | `Cpp_implementation/src/params/parameters.cpp`: `perturbation_order` | The fixed draw order of the perturbed parameters. |
| `VariantSelection` | `Cpp_implementation/src/data/program_data.hpp`: `NuclideData`, `isosource`, `ProgramData`, `variant` | The variants and the ISOSOURCE string of each, held by the program data. |
| `VariantSelection` | `Cpp_implementation/src/data/program_data.cpp`: `isosource` | Returns the ISOSOURCE string of a variant. |
| `DataItemLabels` | `Cpp_implementation/src/data/program_data.hpp`: `label`, `items` | Label lookup and the data items held by the program data. |
| `DataItemLabels` | `Cpp_implementation/src/data/program_data.cpp`: `label` | Finds the block a label names; lookups ignore letter case. |
| `DataItemLabels` | `Cpp_implementation/src/data/data_block.hpp`: `LabelEntry`, `DataBlock` | Label entry and data block types. |
| `EmittedNuclideC` | `tools/fbsrc/gen_gef_data.py`: `main`, `write_fingerprints`, `check_capture`, `load_variants`, `generated_files` | The generator that extracts the data items from the emitted C and writes the fingerprints. |
| `EmittedNuclideC` | `Cpp_implementation/src/data/generated/variant_jeff33.cpp`: `chain`, `labels`, `own_nuclidedata`, `LabelEntry` | Generated JEFF-3.3 data chain and labels. |
| `EmittedNuclideC` | `Cpp_implementation/src/data/generated/shared_tables.cpp`: `shared_apre_hg180`, `DataBlock` | Generated shared data block. |
| `EmittedNuclideC` | `Cpp_implementation/src/data/generated/tables.hpp`: `DataBlock` | Generated data block type. |
| `ParameterLineReader` | `Cpp_implementation/src/params/parameter_files.hpp`: `GefHangs`, `read_input_file`, `read_parameters` | The hang error for an unterminated comment, and the reader entry points. |
| `ParameterLineReader` | `Cpp_implementation/src/params/parameter_files.cpp`: `fit_keys`, `strip_comments`, `read_input_file`, `read_parameters` | Reads the lines, strips comments and sets the values the lines name. |
| `FitparFile` | `Cpp_implementation/src/params/parameter_files.hpp`: `fitpar_read` | Entry point for the fit parameter file. |
| `FitparFile` | `Cpp_implementation/src/params/parameter_files.cpp`: `fitpar_read` | Reads the fit parameter file at start-up and later in the run. |
| `MyParametersFile` | `Cpp_implementation/src/params/parameter_files.hpp`: `mypar_read` | Entry point for the own parameter file. |
| `MyParametersFile` | `Cpp_implementation/src/params/parameter_files.cpp`: `mypar_read` | Reads the own parameter file only when its flag is set. |
| `MyParametersFile` | `Cpp_implementation/src/params/parameters.hpp`: `b_myparameters` | The flag that enables the own parameter file; the original program never sets it. |
| `ParameterUpdateFile` | `Cpp_implementation/src/params/parameter_files.hpp`: `parameter_update_text`, `parameter_manipulation` | Builds the update file text, and the sequence that runs the file reads before it. |
| `ParameterUpdateFile` | `Cpp_implementation/src/params/parameter_files.cpp`: `parameter_update_text`, `parameter_manipulation` | Builds the update text; the caller writes the file. |

## Physics functions

| Node | Code | Notes |
| --- | --- | --- |
| `MacroscopicMass` | `Cpp_implementation/src/physics/masses.cpp` `ly_mass` `ly_pair` `fedefo_lys` `ecoul` | Liquid-drop, pairing, deformation and Coulomb energies. |
| `ShellCorrections` | `Cpp_implementation/src/physics/masses.cpp` `u_shell` `u_shell_exp` `u_shell_eo_exp` | Shell and even-odd corrections. |
| `TabulatedMasses` | `Cpp_implementation/src/physics/masses.cpp` `ame2020` `ld_mass` `u_mass` `u_q_beta_minus` `u_valid` `u_delta_s0` | Table lookups and derived values; the delta function returns zero. |
| `CurvatureLimits` | `Cpp_implementation/src/physics/shape.cpp` `f1` `f2` `masscurv` `masscurv1` `masscurv2` | Mass curvature and its two limit functions. |
| `ScissionEquilibrium` | `Cpp_implementation/src/physics/shape.cpp` `de_saddle_scission` `beta_light` `beta_heavy` `z_equi` `scission_energy` | The scission energy helper is local to the source file. |
| `DeformationMinimum` | `Cpp_implementation/src/physics/shape.cpp` `beta_equi` | Deformation minimum search; the print of non-convergence is handled by the caller. |
| `FissionBarriers` | `Cpp_implementation/src/physics/barriers.cpp` `bftf` `bftfa` `bftfb` `dahlinger_db` | Barrier options and a helper function. |
| `LevelDensities` | `Cpp_implementation/src/physics/level_density.cpp` `u_alev_ld` `u_levdens` `u_levdens_egidy` `u_levdens_fg` | Level density, its parameter and the Fermi gas and Egidy forms. |
| `NuclearTemperatures` | `Cpp_implementation/src/physics/level_density.cpp` `u_temp` `u_temp2` `tegidy` `trusanov` | Temperature from the level density. |
| `FissionYields` | `Cpp_implementation/src/physics/shape.cpp` `getyield` | No caller in the source tree yet. |
| `SmoothingHelpers` | `Cpp_implementation/src/physics/helpers.cpp` `gaussintegral` `bell` `u_box` `even_odd` | Smoothed step, weights and selector. |
| `RotationalDynamics` | `Cpp_implementation/src/physics/rotation.cpp` `u_ired` `u_iredff` `u_i_shell` `e0_gdr` `width_gdr` `efac_def_gdr` `u_accel` | Inertia, giant dipole resonance and acceleration. |
| `EgammaLowTable` | `Cpp_implementation/src/physics/gamma_table.cpp` `p_egamma_low_table` | Builds the low-energy gamma table. |
| `E2Cascade` | `Cpp_implementation/src/physics/e2_cascade.cpp` `e2_cascade` | Cascade loop with its stops and gamma list limit. |

## Run control

| Node | Code | Notes |
| --- | --- | --- |
| `BatchInputFiles` | `Cpp_implementation/src/run/input_files.hpp` `read_file_in` `read_sequence_file` | Declarations of the two readers (BASIC 2699–2763 and 2768–3133). |
| `RunPlan` | `Cpp_implementation/src/run/driver.cpp` `RunDriver` `next_step` | Driver constructor and the entry that runs one step. |
| `SetupStages` | `Cpp_implementation/src/run/driver.hpp` `SetupStages` `begin_round` `begin_system` `set_up_step` | Virtual seam the driver calls; BatchSetup implements it. |
| `StateScopes` | `Cpp_implementation/src/run/state.hpp` `ProcessState` `InputRoundState` `SequenceFileState` `StepState` | One struct per state scope. |
| `RunRestart` | `Cpp_implementation/src/run/driver.cpp` `restart` `round_start` `repeat_input` | Round-start comparison and repeat of the batch input (BASIC 1909, 3567). |
| `RunRestart` | `Cpp_implementation/src/run/step_setup.cpp` `set_isomer` | Returns false when no isomer is found, which starts the restart (BASIC 3542–3590). |
| `RunEnding` | `Cpp_implementation/src/run/driver.cpp` `finish` `stop` `hang` | End of the input, fit back edge and hang (BASIC 15597–15669). |
| `RunEnding` | `Cpp_implementation/src/run/driver.hpp` `RunEnd` | Enumeration of the run ends. |
| `RunEnding` | `Cpp_implementation/src/params/parameter_files.hpp` `GefHangs` | Exception that carries a hang to the caller. |
| `RunConsole` | `Cpp_implementation/src/run/run_util.hpp` `print_part` `print_line` `print_lines` | Console writers used by the run. |
| `RunWorkDir` | `Cpp_implementation/src/run/workdir.hpp` `WorkDir` `read` `exists` | Run-directory object and its reads. |
| `RunWorkDir` | `Cpp_implementation/src/run/workdir.cpp` `join` `resolve` `exists` | Joining and resolving of run-directory paths. |
| `SetupProbes` | `Cpp_implementation/src/run/probes.hpp` `ProbeSink` `sequence_file` `step_setup` `step_threshold` | Observation hooks (probes P0, P1 and P1b). |
| `SetupProbes` | `Cpp_implementation/src/run/state.hpp` `probes` | Optional sink pointer; a null sink runs no hook. |
| `BatchFileOptions` | `Cpp_implementation/src/run/input_files.cpp` `read_file_in` `read_file_in_entry` | Batch-file reader: its FIT and NITER lines and the sequence-file names (BASIC 2699–2763). |
| `SequenceFileHeader` | `Cpp_implementation/src/run/input_files.cpp` `read_sequence_file` `reset_file_options` `set_lmd_file` `set_lmd_flags` | Energy line, per-file reset and file-name settings. |
| `EnergyTableRead` | `Cpp_implementation/src/run/input_files.cpp` `read_energy_table` | Energy-table reader. |
| `SequenceLines` | `Cpp_implementation/src/run/input_files.cpp` `read_sequence_lines` `read_options` `read_option` `read_fit` `read_niter` `read_mode` `read_system_line` `read_pair_line` `read_data_line` | Loop over the option, system, pair and data lines to the end of the data, with its option and line readers. |
| `FileLoop` | `Cpp_implementation/src/run/driver.cpp` `file_iteration` | Walk over the sequence files. |
| `LineLoop` | `Cpp_implementation/src/run/driver.cpp` `line_iteration` `begin_line` `select_channel` | Walk over system lines and selection of the entrance channel. |
| `SystemLoop` | `Cpp_implementation/src/run/driver.cpp` `system_iteration` | Walk over the systems of a line. |
| `StepLoop` | `Cpp_implementation/src/run/driver.cpp` `step_iteration` `advance` | Walk over energy steps and dispatch of the set-up result. |
| `EnergySteps` | `Cpp_implementation/src/run/driver.cpp` `step_energy` `endf_step_energy` `neutron_steps` | Energy and step count of each energy step. |
| `PassSchedule` | `Cpp_implementation/src/run/driver.hpp` `PassInfo` `next_step` `begin_pass` `end_pass` | Pass information and pass boundaries. |
| `DoneRecords` | `Cpp_implementation/src/run/driver.cpp` `find_done` `register_done` | Lookup and registration of done records. |
| `DoneRecords` | `Cpp_implementation/src/run/state.hpp` `done_ctl` | Store of done records in the process scope. |
| `RoundSetup` | `Cpp_implementation/src/run/system_setup.cpp` `begin_round` | Round set-up (fit parameter file and widths). |
| `RoundSetup` | `Cpp_implementation/src/run/setup.hpp` `BatchSetup` | Batch-run set-up that forwards the three stages. |
| `SystemSetup` | `Cpp_implementation/src/run/system_setup.cpp` `begin_system` `print_barriers` `print_masses` `name_output_file` `gef_name` `neutron_separation` | System set-up and its printed lines. |
| `StepSetup` | `Cpp_implementation/src/run/step_setup.cpp` `set_up_step` `set_isomer` `read_spectrum` `set_excitation` `check_energy` `set_multi_chance_threshold` `decide_prepass` `name_system` `name_lmd_file` `print_cn_line` | Energy-step set-up (isomer, spectrum, excitation, energy checks, pre-pass decision). |

## Model tables

| Node | Code | Notes |
| --- | --- | --- |
| `BinVisits` | `Cpp_implementation/src/tables/bin_plan.hpp` `BinPlanInput` `BinInput` `BinPlan` `enter_bin` `Cpp_implementation/src/tables/bin_plan.cpp` `BinPlan` `advance` `next` `enter_bin` | Bin inputs, the bin loops and the guard of the bin block. |
| `NominalWorkingCopies` | `Cpp_implementation/src/tables/working_parameters.hpp` `WorkingParameters` `assign_nominal` `Cpp_implementation/src/tables/working_parameters.cpp` `assign_nominal` `Cpp_implementation/src/run/state.hpp` `working` | Nominal passes copy the nominal parameters into the working copies. The state header also holds RunControl's state scope (see Notes). |
| `CarriedBinTables` | `Cpp_implementation/src/tables/bin_tables.hpp` `BinTables` `Temporaries` `Cpp_implementation/src/run/state.hpp` `ProcessState` `bin_tables` `spin_cn` | The last bin's `Spin_CN` outlives its step; the next step reads it when its own set-up does not assign it (Q-054). The state header also holds RunControl's state scope (see Notes). |
| `ModesAndDeformations` | `Cpp_implementation/src/tables/builder.hpp` `mode_centres_and_deformations` `Cpp_implementation/src/tables/deformations.cpp` `mode_centres_and_deformations` | Public entry of the mode block. |
| `ModeCentres` | `Cpp_implementation/src/tables/deformations.cpp` `scission_limit` `mode_centres` `Cpp_implementation/src/tables/bin_tables.hpp` `escission_lim` `zc_mode_0` `ac_mode_0` `nc_mode_0` | Scission limit and mode centres (the 900 and 1150 variants are in Notes). |
| `ModeDeformations` | `Cpp_implementation/src/tables/deformations.cpp` `deformations_mode0` `deformations_modes` `not_negative` `deformation_energy` `polarised_a` `Cpp_implementation/src/tables/bin_tables.hpp` `beta` `edefo` `Cpp_implementation/src/tables/builder.hpp` `BetaEquiMessage` | Equilibrium deformations of mode zero and of the other modes. The solve's message comes back through an out-parameter (Q-041, open). |
| `MeanChargeAndRelations` | `Cpp_implementation/src/tables/deformations.cpp` `unchanged_charge_density` `store_mean_z` `n50_polarisation` `mean_z` `z_a_relation` `z_a_relations` `scaled_curvature` `curvatures` `Cpp_implementation/src/tables/bin_tables.hpp` `zmean` `zshift` `p_z_mean_s1` `r_z_curv_s0` `r_a_curv2_s0` | Mean charge, Z-A relations and curvatures. `mean_z` throws above mass number 360; the Q-061 emulation is decided but not built. |
| `MtCandidate` | `Cpp_implementation/src/tables/bin_plan.cpp` `next` `advance` | Candidate loops and their end. |
| `MtMultiChance` | `Cpp_implementation/src/tables/bin_plan.cpp` `multi_` `inputs` | The multi-chance flag, set from the bin inputs. |
| `MtGrid` | `Cpp_implementation/src/tables/bin_plan.cpp` `advance` `inputs` | The grid of bins for a multi-chance step. |
| `MtSpectrumLines` | `Cpp_implementation/src/tables/bin_plan.cpp` `inputs` | Spectrum points chosen over a single energy. |
| `MtSpectrumPoint` | `Cpp_implementation/src/tables/bin_plan.cpp` `advance` `inputs` | One bin per spectrum point. |
| `MtSingleEnergy` | `Cpp_implementation/src/tables/bin_plan.cpp` `inputs` | The single-energy bin. |
| `MtHasEvents` | `Cpp_implementation/src/tables/bin_plan.cpp` `inputs` `next` | Bin event count, and the skip of bins without events. |
| `MtVisit` | `Cpp_implementation/src/tables/bin_plan.hpp` `enter_bin` `Cpp_implementation/src/tables/bin_plan.cpp` `enter_bin` | Entering a bin that is handed out. |
| `MtDone` | `Cpp_implementation/src/tables/bin_plan.cpp` `next` | End of the visits when no candidate bin is left. |

## Event generation, result analysis and output writing

| Node | Code | Notes |
| --- | --- | --- |
| `AnalyzerRegistry` | `Cpp_implementation/src/analysis/analyzer_registry.hpp` `AnalyzerAttributes` `AnalyzerRegistry` `build_analyzer_registry` `Cpp_implementation/src/analysis/analyzer_registry.cpp` `spectra_bas_analyzers` `branching_analyzers` `build_analyzer_registry` | Attribute table and its builder; the builder fills the table through helpers for the spectra and branching groups. |

## Reference harness and comparison

| Node | Code | Notes |
| --- | --- | --- |
| `NeutralityProof` | `harness/patch_check.py` `check_entry` `probe_differences` `stdout_subsequence` | Compares each probed or logged run with the plain run and allows only the records the patch adds. |
| `PatchedBuilds` | `harness/build.py` `build()` `compute_build_id` `materialize_patch_dir` `compare_sections` `read_patchset` | Builds the reference program from a patch set and computes its build identifier. |
| `PatchedBuilds` | `harness/patchsets` | Directory of patch set lists. |
| `PatchedBuilds` | `harness/patches` | Directory of the patch files that patch sets apply. |
| `SeedCapture` | `harness/capture_seed.py` `capture_seed` `verify_binary` `parse_capture_result` `render_gdb_script` | Records the clock seed of a reference run through a debugger script and parses the result. |
| `ReseedMode` | `harness/reseed.py` `derive_seed` | Derives the seed of each reseed scope from the master seed and the scope identifiers. |
| `ReseedMode` | `harness/patches/reseed.patch` `GEF_RESEED` `Harness_DeriveSeed` `Harness_Reseed` `Harness_ReseedInit` `Harness_PGaussReset` | Adds the reseeding calls at each scope and clears the Gaussian cache after each reseed. |
| `DrawLogs` | `harness/rndlog.py` `read_log` `parse_line` `summarize` `analyze_scopes` | Reads draw logs and assigns each draw to its scope. |
| `DrawLogs` | `harness/fbmt.py` `FbMtRng` | Python transcription of the FreeBASIC random generator. |
| `DrawLogs` | `harness/patches/rndlog.patch` `GEF_RNDLOG` `Harness_Rnd` `Harness_RndOpen` | Adds the draw-log file and the logging call at each random draw site. |
| `ArgumentLog` | `harness/arglog.py` `read_arglog` `parse_record` `replay_check` | Reads argument records and checks that replaying them reproduces the recorded calls. |
| `ArgumentLog` | `harness/arglog_patch.py` `generate` `SITES` | Generates the argument-log patch for the listed call sites. |
| `ArgumentLog` | `harness/patches/arglog.patch` `GEF_ARGLOG` `Harness_Event` | Adds the argument-record calls to the reference program. |
| `CleanRunRunner` | `harness/run.py` `prepare_run_dir` `scope_environment` `run` | Prepares an empty run directory, sets the trace scope in the environment and runs the reference program. |
| `CleanRunRunner` | `harness/compare_runs.py` `compare_runs` `load_masks` `apply_masks` | Compares two run directories byte for byte after the output masks are applied. |
| `CleanRunRunner` | `harness/masks.toml` | Lists the output fields that depend on time or the host, which are masked. |
| `CleanRunRunner` | `harness/common.py` `MASKS_FILE` `INPUTS_DIR` `STORE_ROOT` | Shared paths of the mask file, the input directory and the reference store. |
| `CaptureCorpora` | `harness/corpus.py` `generate` `run_entries` `load_entries` `M6_INPUTS` `CORPUS_MANIFEST` `EDGE_MANIFEST` `M7_MANIFEST` | Generates the corpus manifests and loads and runs their entries. |
| `CaptureCorpora` | `harness/inputs/m6` `harness/inputs/m7` | Input files of the corpus families, one directory per family. |
| `ReferenceStore` | `harness/store.py` `add_capture` `add_binary` `verify` `list_captures` | Adds captures and binaries to the store with manifests, and verifies and lists them. |
| `ReferenceStore` | `manifests/reference_store` | Manifests of the stored captures and binaries, one file per entry. |
| `ReferenceStore` | `manifests/reference_binary.json` | Manifest of the reference binary build and its masked comparison. |
| `FunctionDrivers` | `harness/driver.py` `parse_directives` `cut_lines` `build()` `run` | Parses the driver directives, cuts the source lines, and builds and runs each driver. |
| `FunctionDrivers` | `harness/golden.py` `promote` `check_golden` | Promotes driver results to goldens and checks driver goldens against current results. |
| `FunctionDrivers` | `harness/drivers` | Driver source files and their notes. |
| `StoreGoldens` | `harness/golden_store.py` `capture_runs` `read_dump` `probe_value` | Reads probe values from stored captures for the derived goldens. |
| `StoreGoldens` | `harness/p0_golden.py` `build_golden` | Derives the sequence-probe golden from stored captures. |
| `StoreGoldens` | `harness/p3_golden.py` `build_golden` | Derives the table-builder probe golden from stored captures. |
| `StoreGoldens` | `harness/plan_golden.py` `build_golden` | Derives the plan golden from stored captures. |
| `StoreGoldens` | `harness/setup_golden.py` `build_golden` | Derives the setup golden from stored captures. |
| `StoreGoldens` | `harness/stdout_golden.py` `build_golden` `fnv1a64_bytes` | Derives the console golden and hashes console bytes with FNV-1a 64. |
| `StoreGoldens` | `harness/probe_fingerprints.py` `fingerprints` `fnv1a64` | Computes FNV-1a 64 digests for each probe variable. |
| `StoreGoldens` | `harness/last_writer.py` `p3_variables` `derive` `MAP_PATH` | Derives the last-writer map of the table builder's variables. |
| `StoreGoldens` | `harness/inputs/m7/last_writer.tsv` | Map file read by the last-writer derivation. |
| `StoreGoldens` | `harness/golden.py` `write_derived` | Writes the derived golden descriptors. |
| `ModuleStartProbe` | `harness/patches/probes.patch` `T0` | Adds the module-level probe record, written once per process. |
| `SequenceProbe` | `harness/patches/probes.patch` `P0` | Adds the record written after each sequence file read. |
| `StepSetupProbes` | `harness/patches/probes.patch` `P1` `P1b` `Harness_Step` `Harness_StepSelected` | Adds the step-start and threshold-decision records for the selected steps. |
| `PrepassProbe` | `harness/patches/probes.patch` `P2` `Harness_Prepass` | Adds the record at the end of the multi-chance pre-pass. |
| `TableInputProbes` | `harness/patches/probes.patch` `P3in` `P3` | Adds the record at the table builder's entry and the record before its event loop. |
| `ProbeFormat` | `harness/probes.py` `read_probe_file` `decode_double` `decode_single` `encode_double` `encode_single` | Reads probe files and encodes and decodes the double and single hex values. |
| `ProbeFormat` | `harness/patches/scope.patch` `GEF_TRACE_STEPS` `GEF_TRACE_PASSES` `GEF_TRACE_EVENTS` `Harness_ScopeInit` | Reads the trace selections from the environment and sets up the scope. |
| `ProbeFormat` | `Cpp_implementation/tests/support/probe_dump.hpp` `ProbeDump` `read_fingerprints` `fingerprint_lines` | C++ probe writer and fingerprint reader for the same line format. |
| `RunLoading` | `compare/loader.py` `load_run` `iter_observables` | Loads a run directory and iterates over its observables. |
| `RunLoading` | `compare/extract.py` `extract_run` `load_extract` | Builds the extract of a run and loads a stored extract. |
| `RunLoading` | `compare/model.py` `ObservableTable` `Key` | Table of observables and the key that identifies each value. |
| `OutputParsers` | `compare/parsers/dmp.py` `parse_text` `roundtrip` `observables` | Reads dmp output text into observables and provides a round-trip function for the fidelity check. |
| `OutputParsers` | `compare/parsers/endf.py` `parse_text` `roundtrip` `observables` | Reads ENDF format files into observables and provides a round-trip function for the fidelity check. |
| `OutputParsers` | `compare/parsers/mvd.py` `parse_text` `observables` `roundtrip` `render` | Reads mvd output text into observables and provides render and round-trip functions. |
| `OutputParsers` | `compare/parsers/out.py` `observables` `coverage` | Reads results files into observables and reports which layouts are covered. |
| `OutputParsers` | `compare/parsers/par.py` `parse_text` `roundtrip` `observables` | Reads parameter files into observables and provides a round-trip function. |
| `OutputParsers` | `compare/parsers/probe.py` `observables` | Reads probe records into observables. |
| `OutputParsers` | `compare/parsers/text.py` `observables` | Reads generic text output into observables. |
| `ParserFidelity` | `compare/gate_g1.py` `run_gate` `check_file` | Runs the parser fidelity check and checks each file it is given. |
| `ExactComparison` | `compare/exact.py` `compare_exact` `ulp_distance` `ExactReport` | Compares two runs value by value and reports each difference in units of the last place. |
| `CalibrationEnsembles` | `compare/ensemble.py` `run_ensemble` `parse_seeds` | Runs a set of null members from a list of seeds. |
| `CalibrationEnsembles` | `compare/calibrate.py` `calibrate` `Calibration` `DEFAULT_MDE` | Builds a null calibration from an ensemble, with the default minimum detectable effect. |
| `StatisticalVerdict` | `compare/stats.py` `fit_family` `classify_fields` `binom_sf` | Fits the null law of each family and classifies its fields. |
| `StatisticalVerdict` | `compare/verdict.py` `judge_family` `check_inputs` | Checks the inputs of a judgement and judges each family against the calibration. |
| `StatisticalVerdict` | `compare/report.py` `render_text` `render_json` | Writes the verdict as text or as JSON. |
| `ValidityChecks` | `compare/gates.py` `run_null` `run_g4` `validity_table` `allowed_failures` | Runs the leave-one-out null validation over an ensemble and its held-out runs, judges one candidate run against a calibration, and tabulates the failures and the p-value validity table. |
| `FaultInjection` | `compare/inject.py` `inject` `parse_spec` `list_sites` `FAULTS` | Injects a named synthetic fault into a copy of a run, as given by a fault specification. |
| `FaultInjection` | `compare/gates.py` `run_sensitivity` `sensitivity_table` | Runs the sensitivity check over the injected faults and tabulates the detections. |
| `LibraryCheck` | `compare/verdict.py` `judge` `main` | Judges the library tapes that a file glob selects, reported as information. |
| `CmFieldClass` | `compare/stats.py` `classify_fields` `CLS_DET` `CLS_STOCH` `CLS_ZERO` `CLS_IGN` | Assigns each numeric field one of four classes, which set how its values are tested. |
| `CmFieldClass` | `compare/verdict.py` `_judge_text` | Judges the text fields of a family separately from its numeric fields. |
| `CmHard` | `compare/verdict.py` `judge` `failed_exactly` `_is_structural` | Marks families that are missing or have mismatched values, and separates structural text from other text. |
| `CmHard` | `compare/stats.py` `STRUCTURAL_TEXT` | Lists the text fields that count as structure for each format. |
| `CmVariance` | `compare/stats.py` `variance_model` `fit_phi_psi` `VarianceModel` | Fits how the dispersion of each numeric field depends on its mean. |
| `CmDeviation` | `compare/stats.py` `judge_values` `t_equivalent` `discrete_z` | Gives each candidate value a standardized deviation and reports the sum of squares and the largest absolute value. |
| `CmDeviation` | `compare/verdict.py` `judge_family` `FamilyResult` | Stores the deviations of each family in its family result. |
| `CmNull` | `compare/stats.py` `_loo_moments` `fit_family` `local_null` `global_sf` `MIN_LOO_DRAWS` | Fits the null law of each family from leave-one-out moments, which need a minimum count of draws. |
| `CmNull` | `compare/calibrate.py` `loo_d` `loo_m` | Stores each family's leave-one-out statistics in the calibration. |
| `CmLowCount` | `compare/stats.py` `SPARSE_MEAN` `discrete_z` | Sends fields with a small mean count to the discrete score. |
| `CmBinomial` | `compare/stats.py` `binom_sf` `binom_cdf` | Gives the binomial tail probabilities that the discrete score uses. |
| `CmFamilyP` | `compare/stats.py` `judge_values` `global_sf` `MIN_GLOBAL_FIELDS` | Combines the global and local p-values as twice the smaller one, capped at one, and uses the local test alone when the global test has too few fields. |
| `CmFamilyP` | `compare/verdict.py` `p_global` `p_local` `FamilyResult` | Keeps the global and local p-values of each family in its result. |
| `CmHolm` | `compare/stats.py` `holm` `ALPHA` | Applies the Holm step-down correction at the default level. |
| `CmHolm` | `compare/verdict.py` `judge` `holm` | Passes the family p-values of the suite through the step-down correction. |
| `CmFail` | `compare/verdict.py` `VerdictResult` `rejected` | Reports the suite as failing when any family rejects or fails exactly. |
| `CmPass` | `compare/verdict.py` `VerdictResult` `passed` `main` | Reports the suite as passing when nothing is rejected, and the command exits zero only then. |
| `CoverageMatrix` | `Planning/COVERAGE_MATRIX.md` | The matrix, its legend and its update log. |
