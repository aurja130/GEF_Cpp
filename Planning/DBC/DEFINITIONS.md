# Definitions

The glossary of the GEF port: every term a concept node uses, and the project's own sense of generic words, with where each was decided. Links to [CONCEPTS](CONCEPTS.md), [CODE](CODE.md), [DEFINITIONS](DEFINITIONS.md), [TESTS](TESTS.md) and [CAPTURES](CAPTURES.md).

| Term | Meaning | Decision |
| --- | --- | --- |
| added-number list | The material numbers given to nuclei the table lacks; kept in process memory and, in the BASIC program, in a control file. | Q-021, M6, M13, M14 |
| analyzer | One named result the calculation tallies, such as a yield or spectrum, with its axis and plotting attributes. | DBC L1 (approved 2026-11-07); M4 plan |
| analyzer registry | The fixed table that describes each analyzer by its name, title, axis labels, plot symbol, type, limit and dimension. | M4 plan, section M4.5; Q-020 |
| antineutrino | A particle emitted in beta decay; the nuclides that emit it are listed separately. | IMPLEMENTATION_STRATEGY milestone M11 |
| argument log | A log of the arguments, by-reference values and results of selected function calls, with a check that replaying the log reproduces the calls. | harness/ARGLOG.md; Planning/MILESTONE_5_PLAN.md |
| argument type | Type of the argument of an intrinsic call, which selects the precision of the call | fbrt arithmetic rule R7 |
| array bounds | Lower and upper index of each dimension of an array | Milestone 3 plan decision 3 |
| atomic weight ratio | The ratio of a nucleus's mass to a neutron's mass (AWR). | M4 plan |
| `barrier energy` | Energy of each mode above the ground state at its barrier. | milestone plan §5 |
| BASIC source | The FreeBASIC source of GEF 2025/1.2 in the submodule `Reference/GEF_code` at `ba9f0aa`; never edited. | `IMPLEMENTATION_STRATEGY.md` §2.6 |
| batch file | The top-level input of a run: it sets the fit switch and the iteration count, and names the sequence files. | M6 plan decision 11 (input-file layout); quirk Q-058 (a batch file that names no sequence file waits for a key). |
| batch input | The batch file and the sequence files it names, read together as the input of one run. | DBC L1 (approved 2026-11-07). |
| bell function | Bell-shaped weight with smooth edges. | Keeps the GEF meaning |
| beta-decay energy | The energy released in the beta decay of a nuclide. | IMPLEMENTATION_STRATEGY milestone M11 |
| `bin` | One cell of the grid a step visits, for which one set of model tables is built. | DBC L1 (approved 2026-11-07) |
| `bin event count` | The number of events in a bin; a bin with none is skipped. | M7 plan |
| `bin visit` | Hands one bin with events to the table build; the visits of a step end when no candidate bin is left. | M7 plan |
| binomial conditional test | An exact test of a split count, conditional on the total, with a binomial null distribution. | compare/STATISTICS.md |
| bound system | A system is bound when its neutron separation energy is zero or more; otherwise it is not bound and is passed over with a warning. | Reference behaviour; no M6 plan decision or quirk. |
| box function | Box-shaped weight with smooth edges. | Keeps the GEF meaning |
| branch table end | The point where the branch loader stops, at Ra-234; the default-mode search still covers the empty records after it. | Q-017 |
| branching ratio | The fraction of a nucleus's decays that go by one decay mode. | M4 plan |
| `candidate bin` | A bin of the plan that the step still has to visit. | M7 plan |
| capture | One stored run of a reference binary, with its written files and its manifest. | Planning/MILESTONE_1_PLAN.md |
| `carried state` | Values that one bin keeps from earlier bins for later bins. | DBC L1 (approved 2026-11-07) |
| chance | A point in the pre-fission neutron emission sequence at which the nucleus may fission. | IMPLEMENTATION_STRATEGY milestone M9 |
| charge equilibrium | Charge split between the two fragments at scission. | Keeps the GEF meaning |
| `charge polarisation` | Polarisation of a mode's charge distribution. | M7 plan |
| chi-square test | A comparison of calculated yields with evaluated data for plotting, summarised as a chi-square value. | IMPLEMENTATION_STRATEGY milestone M11 |
| clean run | A run of the reference binary in an empty run directory, whose written files are compared after the output mask is applied. | harness/README.md; harness/PROBES.md |
| collective energy | The energy of the collective motion of the two fragments. | IMPLEMENTATION_STRATEGY milestone M10 |
| `collective temperature` | Temperature of a mode's collective motion, with the polarisation and asymmetry temperatures that go with it. | milestone plan §5 |
| compiler policy | The CMake interface targets that every project target links: exact FP flags and warnings-as-errors. | M0 plan; `CODING_STANDARDS.md` §2.5 |
| compound nucleus | The excited nucleus formed before it splits or emits particles. | IMPLEMENTATION_STRATEGY milestone M9 |
| constant field | A field with one identical value in every ensemble run; a candidate that differs is one unlikely outcome, with probability 1/(K+1), and cannot reject on its own. | compare/STATISTICS.md |
| corpus | A TOML list of input entries, each with its own seed and trace settings, that a capture run covers. | Planning/MILESTONE_6_PLAN.md; Planning/MILESTONE_7_PLAN.md |
| Coulomb energy | Electrostatic energy of the protons in a nucleus. | Keeps the GEF meaning |
| covariance | A measure of how the yields vary together over the perturbed runs. | IMPLEMENTATION_STRATEGY milestone M12 |
| coverage matrix | `Planning/COVERAGE_MATRIX.md`: GEF's dimensions (systems, channels, energies, options, observables, internal behaviour) against the test tiers, with the evidence of each covered cell. | Vision §4.4; strategy §3 conventions |
| cumulative yield | The yield of a nuclide including all yield fed to it by the decays of its precursors. | IMPLEMENTATION_STRATEGY milestones M11 and M12 |
| `curvature` | Curvature of a charge-versus-mass relation, scaled for the tables. | M7 plan |
| DATA block | A run of data items for one table, held as text; a long table spans several blocks. | M4 plan D1 |
| data item | One value of a BASIC DATA statement, in the order the Read statements consume them. | M4 plan D1 |
| data label | A BASIC label that `Restore` names as the place where `Read` resumes; it marks the DATA block where a table starts. Lookups ignore letter case. | M3 plan D12; M4 plan D1, D10 |
| data line | A line of sequence-file data, dispatched by its number of comma-separated fields: three for a system line, six for a pair line. | M6 plan decision 11 (input-file layout). |
| DATA statement | Statement that stores constant items in the program for later reading | Milestone 3 plan decision 12 |
| decay branch | One decay mode of a nucleus or isomeric state, with its branching ratio. | M4 plan |
| decay branching | A decay route from one nuclide to another, with its probability, that moves yield to the daughter. | IMPLEMENTATION_STRATEGY milestone M11 |
| default decay mode | The mode assumed for a nucleus the branch table does not list: -1 (beta-plus) below the mass number of the last listed nucleus of its element, -2 (beta-minus) above it, within the Z range; 0 otherwise. | M4 plan D10 |
| definition lookup | Finding where a BASIC name is defined and referenced, case-insensitively, outside comments. | `tools/fbsrc/README.md` (fbdef) |
| deformation | The per-nucleus deformation value held in a mass table. | M4 plan |
| deformation energy | Energy cost of deforming a nucleus from its spherical shape. | Keeps the GEF meaning |
| deformation minimum | Deformation at the minimum of the scission energy. | Planning/MILESTONE_5_PLAN.md §3 |
| delayed neutron yield | The number of delayed neutrons given off by each emitting nuclide. | IMPLEMENTATION_STRATEGY milestone M11 |
| derived golden | A golden computed from the store by a harness module; its record names the sources and the tool that made it. | Planning/MILESTONE_4_PLAN.md; Planning/CURRENT_PROJECT_STATE.md |
| derived seed | Seed computed for one reseed scope from the master seed by the derivation rule | Reseed specification section 3 |
| done record | A record that a system has finished, kept in the process; outside fit mode a system with a matching record is skipped. | M6 plan decision 2 (done records in process state, skipped in fit mode); quirk Q-048 (the key has no channel). |
| draw | One random value that a perturbed parameter receives in one uncertainty sample. | M8, M12 |
| draw log | A log of every random draw a run makes, with the scope in which the draw happened. | harness/README.md; Planning/MILESTONE_1_PLAN.md |
| driver golden | The recorded command lines and outputs of one function driver, checked by the golden test. | Planning/CURRENT_PROJECT_STATE.md; Planning/MILESTONE_6_PLAN.md |
| dump | A text output file that holds the analyzer headers and values of a run in a fixed layout. | DBC L1 (approved 2026-11-07); IMPLEMENTATION_STRATEGY milestone M13 |
| dynamic array | Array whose bounds are set at run time and which can be resized | Milestone 3 plan decision 3 |
| E2 cascade | Sequence of E2 gamma rays emitted while the spin of a fragment steps down. | Planning/MILESTONE_5_PLAN.md §3 |
| E2 gamma | One gamma ray of an E2 cascade, with its energy. | Keeps the GEF meaning |
| Egidy model | Level density form from Egidy's systematics. | Keeps the GEF meaning |
| emitted C | The C that fbc 1.10.1 generates from the BASIC source (`fbc -gen gcc`); the authority for what a BASIC line computes and the source of every DATA item the port embeds. | `CODING_STANDARDS.md` §5; strategy §2.5 (M4 plan D1) |
| emitter | A nuclide listed as a source of delayed neutrons or antineutrinos. | IMPLEMENTATION_STRATEGY milestone M11 |
| end statement | The END line that stops the reading of a batch file or of a sequence file. | M6 plan decision 8 (run end and hangs). |
| ENDF energy | The energy of an energy step in a file with ENDF output, taken from the ENDF energies instead of the energy table. | M6 plan decision 5 (control flow). |
| ENDF-6 tape | An evaluated-data file in the ENDF-6 format that holds yields for selected nuclides. | DBC L1 (approved 2026-11-07); IMPLEMENTATION_STRATEGY milestone M13 |
| energy line | The line of a sequence file that gives its energies: a quoted spectrum-file name, or a list of energies, each with an optional spin part. | Quirk Q-046 (a spectrum-file energy line keeps the earlier table); quirk Q-059 (an empty energy line reads past the table). |
| energy step | One energy of a system's energy list; the run sets each step up in turn and hands it to its passes. | DBC L1 (approved 2026-11-07). |
| energy table | The energies, with their spins, that an energy line gives; a spectrum-file energy line keeps the earlier table. | Quirk Q-046 (the earlier table is kept); quirk Q-059 (an empty table is read past its end). |
| enhancement factor | The input factor that sets how many perturbed runs are made and how many events each has. | IMPLEMENTATION_STRATEGY milestone M12 |
| entrance channel | The reaction channel named on a system line, for example FC, IS, ES or EM; a single-step channel uses only the first energy of the table. | Quirk Q-045 (single-step channels run the first table entry but are named by En_max). |
| EOF function | Function that reports whether a file has reached its end | Milestone 4 plan |
| evaporation competition | The random choice, at each step of de-excitation, between emitting a neutron and emitting a gamma ray. | IMPLEMENTATION_STRATEGY milestone M8 |
| even odd selector | Selector used by other groups, as in the smoothing helpers. **Open:** the exact selection rule was not re-read in this subtree. | Keeps the GEF meaning |
| `even-odd correction` | Energy correction for the even or odd proton and neutron numbers of the fragments, scaled by `EOscale`. | Q-011 |
| even-odd effect | The per-nucleus even-odd effect value held in a mass table. | M4 plan |
| event | One simulated fission, from the choice of splitting channel to the final fragments and gamma rays. | DBC L1 (approved 2026-11-07) |
| event loop | The running of the event stages for every event of every incident energy and perturbed run, with a guard against too many negative-energy events. | IMPLEMENTATION_STRATEGY milestone M10 |
| evidence status | How a quirk is established: confirmed in output, confirmed by fbc C, or read only. | `QUIRKS.md` header |
| exact comparison | A field-by-field equality check of a candidate run against its seeded reference, with no statistical tolerance. | compare/README.md; Planning/MILESTONE_3_PLAN.md |
| exact mode | Building and running the port so that it reproduces the BASIC arithmetic bit for bit: BASIC types, fbc evaluation order, and the exact floating-point compiler flags; the acceptance mode of phase 1. | Strategy §2.2, §2.9 (decision 2026-10-08) |
| external cumulation | An optional path in which cumulative yields read from an external source replace the calculated ones for a system. | IMPLEMENTATION_STRATEGY milestones M11 and M15; code map entry O14 |
| extract | A cached, compact array form of a run's observables, per family, so that statistics do not reread the run's files. | compare/STATISTICS.md |
| false alarm | A null run that the verdict judges as deviant; the verdict is calibrated so that such runs occur at a designed rate. | compare/STATISTICS.md; Planning/MILESTONE_2_PLAN.md |
| family | A group of fields that share one file, block and group key; the verdict tests each family as one unit. | compare/STATISTICS.md |
| family p-value | The one p-value of a family, combining its global and local tests. | Planning/MILESTONE_2_PLAN.md; compare/STATISTICS.md |
| fbc expression rule | Rule by which the BASIC compiler types, reorders and folds the arithmetic of one expression | Milestone 3 plan decision 9 and fbrt arithmetic rules R1 to R10 |
| Fermi gas model | Standard form of the level density from a gas of independent nucleons. | Keeps the GEF meaning |
| fidelity switch | A named setting that turns on the corrected behaviour of one quirk; off by default, so the port reproduces BASIC. | Strategy §2.1; `CODING_STANDARDS.md` §2.7 |
| field class | The class a parsed field receives from its values across the ensemble: constant, numeric, zero, ignored or text; the class sets how the field is tested. | compare/STATISTICS.md; Planning/MILESTONE_2_PLAN.md |
| file options | The run options that each sequence file starts from; the per-file reset keeps most of them and clears the fit error flag. | Quirk Q-050 (the per-file reset keeps most options and clears the fit error flag). |
| file scope | State reset after each sequence file's energy line; system lines and steps change it until the next file. | M6 plan decision 6 (`SequenceFileState`); quirk Q-050 (the per-file reset). |
| final standard deviation | The standard deviation of a yield after the program's upper caps and additions are applied. | IMPLEMENTATION_STRATEGY milestone M12 |
| `first-chance step` | A step that is not multi-chance. | M7 plan |
| fission barrier | Height of the energy barrier a nucleus must pass to fission. | Planning/MILESTONE_5_PLAN.md §3 |
| fission yield | Share of fission events that give a fragment with a given mass and charge. | Planning/MILESTONE_5_PLAN.md §3 |
| fit back edge | The return to the start of the fit loop for the next fit iteration, taken in fit mode while the iteration count is not reached. **Open:** the driver returns this edge as a result, but the iteration it starts depends on the planned fit optimiser; whether the edge counts as implemented before that work lands is a status question (see Notes). | M6 plan decision 4 (fit-mode inputs; the back edge is implemented with the planned optimiser); M6 plan decision 5 (the driver returns it as a result). |
| fit iteration | One repeat of the input rounds in fit mode, up to the iteration count; refining the fit parameters between iterations is planned work. | M6 plan decision 4 (fit-mode inputs); implementation strategy §1.2 (Fit mode row). |
| fit loop | The loop over fit iterations: in fit mode the input rounds repeat from their start for each iteration. | M6 plan decision 4 (fit-mode inputs); M6 plan decision 5 (control flow). |
| fit mode | The mode that the fit switch turns on: the input rounds repeat for the iteration count, and the done list is not consulted. | M6 plan decision 2 (done list skipped when fit mode is on); M6 plan decision 4 (fit-mode inputs). |
| fit parameter file | `Fitpar.dat` in the working directory: overrides nominal parameters; read at start-up and by the round set-up at the start of each input round. | M4 plan D6; strategy §1.2 (fit mode) |
| fit switch | The FIT key: a bare FIT line in the batch file, or a FIT(...) option line in a sequence file; it turns fit mode on. | M6 plan decision 4 (fit-mode inputs). |
| Fix function | BASIC function that drops the fractional part of a number, rounding toward zero | Milestone 3 plan decision 8 |
| floating-point environment | Compiler and runtime floating-point settings that exact mode depends on, checked at start-up | Milestone 0 plan floating-point environment check |
| Format function | BASIC function that gives the text of a number shaped by a format mask | Milestone 3 plan decision 2 |
| format mask | Pattern string that gives the layout of a formatted number | Milestone 3 plan decision 2 |
| fp environment | The floating-point properties exact mode assumes on the machine: `FLT_EVAL_METHOD == 0`, IEEE 754 types, round to nearest, no FMA contraction. | M0 plan; M3 plan |
| fragment | One of the two nuclei produced by a fission event, with its own mass, charge, excitation and spin. | IMPLEMENTATION_STRATEGY milestone M10 |
| fragment acceleration | Acceleration of a fragment after scission. | Keeps the GEF meaning |
| `fragment spin` | Root-mean-square angular momentum of a fragment. | Q-010 |
| FreeBASIC runtime | The behaviour fbc 1.10.1's runtime library gives a GEF program: conversions, maths, `Rnd`/`Randomize`, `Str`/`Print`/`Print Using`/`Format`, arrays, DATA and file input; the port reproduces it in `gef::fb`. | Strategy §1.2, M3 plan |
| function driver | A standalone FreeBASIC program that includes table loaders and copies of function bodies cut by line range, then evaluates them. | Planning/IMPLEMENTATION_STRATEGY.md; Planning/MILESTONE_1_PLAN.md |
| fused multiply-add | Operation that multiplies and adds with one rounding, which exact mode must not use | Milestone 0 plan floating-point environment check |
| gamma list limit | Maximum number of gamma energies one cascade can store; the call fails beyond it. | Planning/QUIRKS.md Q-039 |
| gap | The bytes between two table blocks, which hold allocator headers. | Q-042 |
| gate | A check that must pass before work is accepted: a CI step, a milestone exit gate, or an on-demand harness gate. | Strategy §3 "Conventions"; `.omp/AGENTS.md` review cycle |
| GEF maths helper | Maths function that GEF defines itself and the port keeps as written, such as the error function or rounding | Milestone 3 plan decision 5 |
| giant dipole resonance | Collective gamma-ray resonance of a nucleus, described by its energy and width. | Keeps the GEF meaning |
| golden | A checked-in record of expected results that a test compares its output against. | Planning/MILESTONE_1_PLAN.md |
| ground state stop | Ending of the cascade before its first gamma, when a state carries the whole fragment spin. | Planning/QUIRKS.md Q-038 |
| hard failure | A mismatch that no stochastic outcome can produce: a family present in every null run and missing from the candidate, or structural text that differs. The suite fails at once. | compare/STATISTICS.md |
| held-out run | A run that belongs to no ensemble, used as an independent sample to test a calibration. | Planning/MILESTONE_2_PLAN.md |
| histogram | A table of counts or yields grouped by a variable such as energy or mass number. **Open:** milestone placement of the histogram layer to be confirmed. | DBC L1 (approved 2026-11-07); IMPLEMENTATION_STRATEGY milestone M10 |
| Holm step-down | The step-down correction over all tested families: ranked by p-value, each family is rejected against a threshold that grows with its rank, stopping at the first family that is not rejected. | compare/STATISTICS.md; Planning/MILESTONE_2_PLAN.md |
| Input # statement | Statement that reads items from a file into variables, converting the numeric parts | Milestone 3 plan decision 11 |
| input file | File from which values are read in order by input statements | Milestone 3 plan decision 11 and Milestone 4 plan |
| input round | One reading of the batch input from its first sequence file to the end of the file list; a fit iteration or a missing-isomer restart starts a new one. | M6 plan decision 5 (control flow); M6 plan decision 6 (round state). |
| InStr function | Finds the first position of one string inside another, or zero when there is no match | Milestone 4 plan |
| integer division | Division with the backslash operator, whose operands are rounded before the quotient is taken | Milestone 3 plan decision 8 |
| intrinsic excitation | The excitation energy of a fragment that is not part of its collective motion. | IMPLEMENTATION_STRATEGY milestone M10 |
| intrinsic function | Built-in maths function, such as exponential or square root, whose precision follows its argument | fbrt arithmetic rule R7 and Milestone 3 plan decision 5 |
| `intrinsic temperature` | Temperature of a fragment's intrinsic excitation. | M7 plan |
| isomer | Excited state of a fragment that the cascade tests as a stopping point. | Keeps the GEF meaning |
| isomer stop | Ending of the cascade at an isomer, with no gamma in that step. | Keeps the GEF meaning |
| isomer window | Range of state spins in which a state counts as an isomer. | Keeps the GEF meaning |
| isomeric split | The division of a fragment's yield between its ground state and its isomers. | IMPLEMENTATION_STRATEGY milestone M11 |
| isomeric state | One state of a nucleus, with its own isotope-table entry. | M4 plan |
| iteration count | The count of fit iterations that the NITER key sets, given in the batch file or as a NITER(...) option line in a sequence file. | M6 plan decision 4 (fit-mode inputs). |
| kinematics | The motion of the fragments after scission, given by their momenta and kinetic energies. | IMPLEMENTATION_STRATEGY milestone M10 |
| `last-bin spin` | The `Spin_CN` that the last bin of a step leaves; a later ES or EM step reads it when its own set-up does not assign it. | Q-054 |
| leave-one-out null | The null law of a family, estimated by taking each null run in turn as the candidate and the others as the ensemble. | compare/STATISTICS.md |
| Left function | Returns the leftmost characters of a string | Milestone 6 plan |
| left-to-right chain | Chain without a literal, grouped from the left with parentheses not kept | fbrt arithmetic rule R5 |
| legacy fallback | For the legacy form, the material number of the last table entry, returned for a nucleus the table lacks. | Q-036 |
| level density | Number of nuclear states per unit of excitation energy. | Planning/MILESTONE_5_PLAN.md §3 |
| level density parameter | Parameter that sets how the level density grows with excitation energy. | Keeps the GEF meaning |
| library regeneration | Planned regeneration of the library tapes from the model, with trend analysis over Z, A and E. | Planning/MILESTONE_2_PLAN.md; Planning/IMPLEMENTATION_STRATEGY.md |
| library tape | A nuclear data library file that the library check judges against a calibrated ensemble. | Planning/MILESTONE_2_PLAN.md; compare/README.md |
| Line Input statement | Statement that reads one whole line of a file into a string | Milestone 4 plan |
| liquid drop mass | Mass from the liquid drop model, without shell effects. | Keeps the GEF meaning |
| list-mode record | A per-event record of the event's values and the random numbers that produced them, kept for list-mode output. **Open:** exact contents to be confirmed. | IMPLEMENTATION_STRATEGY milestones M10 and M15 |
| literal distribution | Spreading of a literal multiplier over the terms of a sum, after which the constants fold together | fbrt arithmetic rule R10 |
| literal folding | Combining the literals of a chain into one constant that is applied last | fbrt arithmetic rule R4 and quirk B-004 |
| literal multiplier | Literal that multiplies a sum holding another literal | fbrt arithmetic rule R10 |
| literal type | Type that the compiler gives each numeric literal before any operation is applied | fbrt arithmetic rule R1 |
| lookup form | One of three ways the material number is looked up: the current form, the JEFF-3.1.1 form or the legacy form. | M4 plan D3, Q-036 |
| low count | A discrete count field whose ensemble mean is at most 20 counts per run, which the verdict judges by the binomial test instead of by z. | compare/STATISTICS.md |
| low energy gamma table | Table of cross sections for low-energy gamma rays. | Planning/MILESTONE_5_PLAN.md §3 |
| manifest | The JSON record that describes one store entry, a capture or a binary, with its kind and provenance. | Planning/MILESTONE_1_PLAN.md |
| mass curvature | Curvature of the mass along the path to scission. | Keeps the GEF meaning |
| mass table | One of the five per-nucleus tables GEF indexes by (N, Z): BEldmTF, BEexp, DEFOtab, ShellMO and EVOD; the measured masses are read from them as table lookups. | M4 plan; M5 plan §3; M6 plan (Q-042) |
| master seed | Seed from which the seeds of all reseed scopes are derived | Reseed specification section 1 |
| material number | The ENDF material number (MAT) of a nuclide, unique to it; nuclides missing from the table get one by the lookup form's rule. | M4 plan (lookups); ENDF-6 format |
| `mean charge` | Mean proton number of a mode's fragment at a mass number. Above mass number 360 the reference writes past its arrays; the decided emulation is not built yet, and the code throws there. | Q-061 |
| Mid function | Returns a piece of a string, from a start position for a given length | Milestone 4 plan |
| minimum detectable effect | The smallest single-field shift of a family that its local test rejects, in value units, from the null variance of its fields. | compare/STATISTICS.md; Planning/MILESTONE_2_PLAN.md |
| missing-isomer restart | Restart of the batch input after set-up finds no isomer for an energy step. | Quirk Q-049 (the restart repeats the whole input); M6 plan decision 5 (control flow). |
| mixed precision | Operation whose operands differ in precision, with the precision decided for each operation while parsing | fbrt arithmetic rule R2 |
| Mod operator | Remainder operator, whose operands are unsigned 64-bit integers | Milestone 3 plan decision 8 |
| `mode` | One fission mode of the reference model. | M7 plan |
| `mode centre` | Charge, mass and neutron centre of a mode, taken from the scission limit. | M7 plan |
| `mode deformation` | Equilibrium deformation of each fragment of a mode, from the equilibrium solve. | Q-009 |
| `mode shift` | Energy-dependent shift of a mode. | M7 plan |
| `mode width` | Width of a mode's distribution: in proton number and polarisation (ModeWidths), in mass (ModeYields). One term covers both uses. | milestone plan §5 |
| `mode yield` | Share of the fission events that a mode receives. | M7 plan |
| model parameter | One of the named values the physics model reads. | M4 plan |
| `model table` | Arrays of mode and charge values built for one bin. | DBC L1 (approved 2026-11-07) |
| moment of inertia | Inertia of a fragment against rotation. | Keeps the GEF meaning |
| `multi-chance grid` | Grid of proton numbers, neutron numbers and energies that a multi-chance step visits. | M7 plan |
| `multi-chance step` | A step whose bins come from the multi-chance grid; it is multi-chance when `inofirst` is above zero or the energy mode is 13. | M7 plan |
| mvd round trip | Writing covariance data to text and reading it back, so that later steps use the values as the text rounds them. | IMPLEMENTATION_STRATEGY milestone M12 |
| neighbouring table | The next table in memory, whose element a read past the end of a table returns. | Q-042 |
| neutrality check | A comparison showing that instrumented runs, with probes or logs, write the same results as plain runs. | Planning/MILESTONE_1_PLAN.md |
| new material number | The next number after the largest in use, given to a nucleus the table lacks. | Q-021 |
| nominal parameter | A model parameter at its starting value, before a parameter file or a system's set-up changes it. | M4 plan D8, M4 plan D9 |
| non converged minimum | Minimum search that ends without convergence; the caller decides what to do. | Planning/QUIRKS.md Q-041 |
| normalisation | The rescaling of tallied counts so that they represent yields. | IMPLEMENTATION_STRATEGY milestone M11 |
| nuclear mass | Mass of a nucleus, including its binding energy. | Planning/MILESTONE_5_PLAN.md §3 |
| nuclear temperature | Temperature of a nucleus at a given excitation energy, derived from its level density. | Planning/MILESTONE_5_PLAN.md §3 |
| nuclide | A nucleus, identified by its proton number Z and mass number A. | M4 plan |
| nuclide table | The per-variant list of nuclei with their Z, A and material numbers (NucTab). | M4 plan D9 |
| nuclide-data variant | One of seven nuclear data sets GEF can run with: JEFF-3.3, JEFF-3.1.1, NUBASE 2016, NUBASE 2020, and the legacy sets X, MF and F. | M4 plan D3, M4 plan D4. **Open:** the JEFF-3.1.1 branchings pairing (see Notes). |
| null calibration | The stored null fit of an ensemble: per-field means and variances, family structure and validity tables, read by the verdict. | compare/README.md; Planning/MILESTONE_2_PLAN.md |
| null ensemble | A set of seeded runs of one input that differ only in seed; the verdict is calibrated from this sample, and at least four runs are required. | compare/STATISTICS.md; Planning/MILESTONE_2_PLAN.md |
| number text | Text that the Str function and the Print statements write for a number | Milestone 3 plan decision 2 |
| numeric conversion | Conversion of a value between floating-point and integer types, done as the BASIC compiler does it | fbrt arithmetic rules R1 and R8 and Milestone 3 plan decision 8 |
| numeric literal | Number written in the source that the compiler folds into the constant of its chain | fbrt arithmetic rule R4 and quirk B-004 |
| numeric prefix | Leading part of a string that reads as a number, while the rest is ignored | Milestone 3 plan decision 11 |
| numeric text | Text that holds a number in BASIC form, read by the Val family and the input statements | Milestone 3 plan decision 11 |
| observable | A typed value read from a run's files, identified by its family and key; comparisons work on observables. | Planning/MILESTONE_2_PLAN.md; compare/STATISTICS.md |
| operand type | Type of each operand of an arithmetic operation, fixed before the operation is applied | fbrt arithmetic rule R1 |
| operator chain | Run of sums or products that the compiler applies as one group | fbrt arithmetic rules R4 and R5 |
| option line | A line that sets process or file state, such as FIT, NITER, OPTIONS or MODE; in a sequence file it can come after the energy line, among the data lines. | M6 plan decision 4 (fit-mode inputs); M6 plan decision 11 (input-file layout). |
| out-of-bound write | A write BASIC makes past an array's bound, which lands in neighbouring memory; emulated like the out-of-range reads of Q-042, not thrown (Q-061). | User decision 2026-10-30 (Q-061) |
| out-of-range conversion | Conversion of a value to an integer type when the value does not fit that type | fbrt arithmetic rule R8 and Milestone 3 plan decision 8 |
| out-of-range read | A read outside its own table block; GEF returns a neighbouring value, a size word or zero, or stops. | Q-042 |
| output file | A file the run writes for later use, such as results, dumps, tapes or side files. | DBC L1 (approved 2026-11-07) |
| output mask | A set of regular expressions that replace time-dependent text in written files with a fixed mask token before two runs are compared. | harness/masks.toml; Planning/MILESTONE_1_PLAN.md (plan M1.3) |
| output parser | A reader that turns the files of one format into typed observables. | compare/README.md; Planning/MILESTONE_2_PLAN.md |
| `overlap mode` | One of two extra modes, numbered 11 and 22, each with its own barrier and excitation energy. | milestone plan §5 |
| overrun fix | The switch that makes an out-of-range mass-table read throw instead of returning a neighbouring value. | Q-042, M6.4 |
| own parameter file | The second optional parameter file, read only when its flag is set; the original program never sets the flag. | Q-018 |
| P0 | The probe record taken once for each sequence file read, after the file's enhancement factor is set. | M6 plan decision 1 (probe patches); the probe header. |
| P1 | The probe record written after the set-up of an energy step (after the entrance-channel set-up), including the parameters' final values. | Strategy §2.6; `harness/PROBES.md` |
| P1b | The probe record taken after an energy step's threshold is set, or earlier for the other channels; it reports the pre-pass value, which is false for those channels. | M6 plan decision 1 (probe patches); the probe header. |
| pair line | A data line of six comma-separated fields that names two systems; its energy is ignored. | Quirk Q-044 (the energy of a two-system line is ignored). |
| pairing energy | Energy term from the pairing of nucleons. | Keeps the GEF meaning |
| parallel-mode calibration | Planned null calibration of the parallel run mode, which the exact comparison does not cover. | Planning/MILESTONE_2_PLAN.md (exact first); Planning/IMPLEMENTATION_STRATEGY.md |
| parameter file | A text file that sets model parameter values by name. | M4 plan D6 |
| parser fidelity | The check that a parser's round trip writes back identical bytes and that every numeric token is captured or listed as non-data. | Planning/MILESTONE_2_PLAN.md |
| pass | One pass of event generation over a set-up energy step; the pass schedule hands each step to event generation as its passes. | DBC L1 (approved 2026-11-07); M6 plan decision 5 (control flow). |
| patch set | A named set of unified-diff patches, applied in one canonical order to the original sources before a build. | harness/README.md; Planning/MILESTONE_1_PLAN.md |
| patched build | A binary built from the original sources after a patch set has been applied to them. | harness/README.md; Planning/IMPLEMENTATION_STRATEGY.md |
| perturbation draw | A random draw of the perturbed value of one uncertain input, used for one perturbed run. | IMPLEMENTATION_STRATEGY milestone M12 (46 ordered draws) |
| perturbation width | The width (standard deviation) of the Gaussian change a perturbed parameter receives in a draw; initial widths at start-up, recomputed at the start of each input round. | M4 plan; strategy §1.2 (parameters) |
| perturbed parameter | A model parameter that the uncertainty draws vary, in a fixed draw order. | M12 |
| perturbed pass | A pass whose working parameters are perturbed by one draw per perturbed parameter; `Int(sqrt(100·Fenhance))` of them per energy step, before the nominal pass. | Strategy §1.1, §2.4; `CURRENT_PROJECT_STATE.md` §4.2 |
| physics function | One of GEF's deterministic functions (masses, barriers, level densities, temperatures, yields, shapes, rotation, gammas), ported statement by statement and proven bit-exact at T1. | M5 plan |
| `polarisation stiffness` | Stiffness that resists a mode's charge polarisation. | milestone plan §5 |
| power operation | Power operator, where a variable squared is a product and other powers use double precision | fbrt arithmetic rule R6 |
| pre-pass | A calculation run before the event loop that fixes the chances and spectra the events use. | DBC L1 (approved 2026-11-07); IMPLEMENTATION_STRATEGY milestone M9 |
| pre-pass decision | The decision, taken in step set-up after the threshold, whether a pre-pass is due; the set-up only records it, and the pre-pass body belongs to event generation. | M6 plan decision 6 (`StepState` holds it); M6 plan decision 5 (the set-up records it). |
| preset | A named CMake configure and test configuration: `dev-gcc`, `dev-clang`, `asan-ubsan`, `tsan`, `release-exact`. | M0 plan; `CURRENT_PROJECT_STATE.md` §3.1 |
| Print # statement | Statement that writes items to a file opened for output, with the separators and column stops of printing | Milestone 3 plan decision 2 |
| print separator | Comma or semicolon between printed items, which fixes the spacing between them | Milestone 3 plan decision 2 |
| Print Using statement | Statement that writes items through a template string whose fields fix the layout of each value | Milestone 3 plan decision 2 |
| print zone | Column block of fixed width that a comma moves printing on to | Milestone 3 plan decision 2 |
| probe | A patch that writes a record of internal state at one fixed point of a run; each probe has a name such as T0 or P1. | harness/PROBES.md |
| probe fingerprint | A per-variable digest of one probe record: the line count and an FNV-1a 64 hash of the variable's lines, committed as a golden. | harness/probe_fingerprints.py; Planning/MILESTONE_4_PLAN.md (test data decision) |
| probe line | One line of a probe's output, carrying the probe name and a record number. | harness/PROBES.md; Planning/MILESTONE_1_PLAN.md |
| probe P0 | State after a sequence file has been read; always written, whatever the trace selection. | harness/PROBES.md |
| probe P1 | State after the entrance-channel kinematics and validity checks of a selected step, before the step's set-up continues. | harness/PROBES.md |
| probe P1b | State after the threshold of a selected step is computed; in setup-only mode each selected step ends after this probe. | harness/PROBES.md; Planning/MILESTONE_6_PLAN.md |
| probe P2 | State after the multi-chance block of a selected step has run. | harness/PROBES.md |
| probe P3 | State just before the main loop of the table builder, for each table cell with input, in each selected pass and step. | harness/PROBES.md; Planning/MILESTONE_7_PLAN.md |
| probe P3in | State at the entry of the table builder, for the same table cells that the P3 probe records. | harness/PROBES.md; Planning/MILESTONE_7_PLAN.md |
| probe T0 | State after the module-level tables are set up, written once per process: tables, parameters and the name registry. | harness/PROBES.md |
| process scope | State that lasts for the whole run, including the fit switch, the done records and the console. | M6 plan decision 6 (`ProcessState`); M6 plan decision 2 (done records in process state). |
| projection | A histogram summed over some of its variables, leaving the distribution of the rest. | IMPLEMENTATION_STRATEGY milestone M11 |
| prompt gamma | A gamma ray emitted by a fragment soon after it is formed. | IMPLEMENTATION_STRATEGY milestone M10 |
| Q value | Energy released by a beta decay of a nucleus. | Keeps the GEF meaning |
| quick mode | `scripts/ci.sh --quick`: the `dev-gcc` pipeline without `[slow]` tests, plus the Python steps. | `CURRENT_PROJECT_STATE.md` §3.3 |
| quirk | A behaviour of the BASIC program that departs from its evident intent (defect or oddity); the port reproduces it by default. | Vision §3; strategy §2.1 |
| quirk ID | The register's identifier `Q-nnn` (quirks) or `B-nnn` (build notes), cited in code as `QUIRK(Q-nnn)`. | `CODING_STANDARDS.md` §2.7 |
| quirk register | `Planning/QUIRKS.md`: every quirk with ID, BASIC location, effect, evidence, status and C++ symbol, plus build notes. | Strategy §2.1 |
| random stream | Sequence of pseudo-random values from the Mersenne Twister generator, started by a Randomize statement | Implementation strategy section 2.3 and Milestone 3 plan decision 10 |
| Randomize statement | BASIC statement that seeds the random stream from a given seed | Reseed specification section 2 |
| read before write | The variables a stretch of BASIC reads before writing them, from a must-defined analysis over the emitted C. | M7 plan D1; `tools/fbsrc/README.md` (rbw) |
| READ statement | Statement that takes the next DATA item into a variable | Milestone 3 plan decision 12 |
| ReDim Preserve statement | Statement that resizes a dynamic array and keeps its existing elements | Milestone 3 plan decision 3 |
| reference binary | A BASIC executable whose outputs are the reference: `gef_reference` (clock-seeded) and `ref-1` (seed patch only, proven byte-identical for captured seeds). | M1 plan; `manifests/reference_binary.json` |
| reference program | GEF 2025/1.2 as the FreeBASIC source pinned at `ba9f0aa`, the C fbc emits from it and the binaries built from it; the specification of the port. | `GEF_CPP_VISION.md` §6; `.omp/AGENTS.md` "The port" |
| reference store | The directory of immutable captures and reference binaries, each described by a manifest. | Planning/MILESTONE_1_PLAN.md |
| reproduce by default | The rule that every quirk is reproduced unless the user approves a measured change of its fidelity switch's default. | Vision §3 "Fidelity first" |
| reseed mode | A mode, switched on by GEF_RESEED=1 at run time, in which the generator is re-initialised at the start of every scope instance, from a seed derived for that scope. | harness/RESEED_SPEC.md; harness/README.md |
| reseed scope | One of the fixed points at which the per-event reseed mode restarts the random stream from a derived seed: a pre-pass history, the perturbation block, or one event. | `harness/RESEED_SPEC.md` §4; M1 plan |
| RESTORE statement | Statement that moves the next read to the DATA items after a given label | Milestone 3 plan decision 12 |
| results file | The main output file of a run, with one section for each result. | IMPLEMENTATION_STRATEGY milestone M13 |
| Right function | Returns the rightmost characters of a string | Milestone 6 plan |
| Rnd function | BASIC function that gives the next value of the random stream | Milestone 3 plan decision 10 |
| round scope | State re-initialised each time the input is read again, once per fit iteration and once per restart; it holds the energy and spin tables and the sequence-file list. | M6 plan decision 6 (`InputRoundState`). |
| round set-up | The set-up at the start of each input round: it reads the fit parameter file and recomputes the perturbation widths. | M6 plan decision 5 (control flow). |
| round start | The starting state of an input round; each round start is recorded, so that a later round with the same start counts as a repeat. | Quirk Q-049 (the restart repeats the whole input); M6 plan decision 5 (control flow). |
| round to nearest | Rounding mode in which a result goes to the nearest representable value and ties go to even | Milestone 0 plan floating-point environment check and Milestone 3 plan decision 8 |
| RTrim function | Removes spaces from the end of a string | Milestone 6 plan |
| run console | The text the run writes to the console, which must equal the reference console byte for byte. | M6 plan decision 3 (console byte for byte). |
| run directory | The directory in which the run names and reads its files; the process's own directory is not changed. | M6 plan decision 7 (files and directories); quirk Q-060 (file checks do not convert backslashes; opens do). |
| run end | The finished end of a run: the closing lines are printed and the run finishes. | M6 plan decision 8 (run end result). |
| run hang | A point where the reference would wait for ever or repeat for ever; the run ends there as a hang. | M6 plan decision 8 (run end and hangs); quirks Q-049, Q-056, Q-057 and Q-058. |
| run mode | The mode that a sequence file's MODE(...) option line selects; it is part of the file's state, and the per-file reset starts it from its initial value. | M6 plan decision 4 (fit-mode inputs, including MODE). |
| `S1 correction` | Correction to the first asymmetric mode near particular neutron and proton shells. | milestone plan §5 |
| saddle | The configuration at the top of the fission barrier. | IMPLEMENTATION_STRATEGY milestone M10 |
| `saddle energy` | Energy of a mode above its saddle point. | milestone plan §5 |
| sampler | A routine that turns random numbers into values with a chosen probability shape. | DBC L1 (approved 2026-11-07); IMPLEMENTATION_STRATEGY §2.3 |
| scission | The moment the nucleus separates into two fragments. | IMPLEMENTATION_STRATEGY milestone M10 |
| scission energy | Energy at scission: the energy gained from saddle to scission (a physics function), and per mode the energy each mode has at scission, which the model tables keep (Q-008). | M5 plan §3; M7 plan (Q-008) |
| scission shape | Shape of the nucleus at the moment it splits into two fragments. | Planning/MILESTONE_5_PLAN.md §3 |
| `scratch temporary` | A temporary that the builder uses inside one bin and does not keep for the next. | M7 plan |
| seed capture | The clock seed of one reference run, recorded so that a later build can replay that run. | Planning/MILESTONE_1_PLAN.md; harness/README.md |
| self comparison | Comparison of a variable with itself in a branch condition, which the compiler folds to a constant | fbrt arithmetic rule R9 |
| sensitivity check | A test that synthetic faults at or above the minimum detectable effect of their family are all detected by the verdict. | Planning/MILESTONE_2_PLAN.md; compare/STATISTICS.md |
| separation energy | The energy needed to remove one neutron or one proton from a nucleus. | IMPLEMENTATION_STRATEGY milestone M8 |
| sequence file | A file named by the batch file; it holds an energy line, option lines, and the system, pair and data lines of its systems. | M6 plan decision 11 (input-file layout). |
| set-up probe | A test hook that reports a stage to a sink; with no sink set, nothing is reported. | M6 plan decision 1 (probe patches); the probe header. |
| set-up stage | One of the three set-up stages (round, system and energy-step set-up) that the run calls in turn before a step's passes. | M6 plan decision 5 (control flow). |
| Sgn function | BASIC function that gives the sign of a number. **Open:** no named plan decides how it is ported | No named plan decides it yet |
| shell correction | The extra binding energy from nuclear shells, added to the smooth (liquid-drop) part of a mass; tabulated per nucleus in a mass table. | M5 plan §3; keeps GEF's meaning |
| `shell energy` | Energy of a fission channel from its shell effects. | M7 plan |
| side file | An optional extra output file written beside the results, for covariance, parameter, perturbation or list-mode data. | IMPLEMENTATION_STRATEGY milestones M13 and M15 |
| Single quotient | Quotient of two Single values, computed in double precision and narrowed to Single once | fbrt arithmetic rule R3 |
| `single-energy bin` | The one bin of a first-chance step at a single energy, used when no spectrum is given. | M7 plan |
| size word | The allocator chunk header, which a read in a gap returns. | Q-042 |
| skippable step | A CI step that skips with a notice, rather than failing, when `validation/` is absent; a skip is not a pass. | `CURRENT_PROJECT_STATE.md` §3.3; `.omp/AGENTS.md` Deliver |
| smoothed step | Step function smoothed by a Gaussian integral. | Keeps the GEF meaning |
| `sorted energy list` | The modes' energies in order of size. | Q-010 |
| source tool | A tool under `tools/fbsrc/` that maps BASIC lines and names to the emitted C or analyses it. | `tools/fbsrc/README.md` |
| `spectrum point` | One point of a given spectrum; a first-chance step visits one bin per point. | M7 plan |
| spin | The angular momentum of a fragment. | IMPLEMENTATION_STRATEGY milestone M10 |
| spin step | Lowering of the fragment spin by 2 after each gamma. | Keeps the GEF meaning |
| standardized deviation | A field's deviation from its ensemble mean, divided by the spread that its variance model gives it. | compare/STATISTICS.md |
| state scope | One of the four groups of run state (process, round, file and step), each reset at its own point in the run. | DBC L1 (approved 2026-11-07); M6 plan decision 6 (state scopes). |
| static analysis | clang-tidy and clang-format for C++, ruff and basedpyright for Python; all must stay clean. | `CODING_STANDARDS.md` §4 |
| statistical verdict | The calibrated judgment of a candidate run against a null calibration, field by field and family by family. | compare/STATISTICS.md; compare/README.md |
| step scope | State re-initialised for each energy step at the top of the multi-chance block; it holds the fields that the step set-up sets, and the rest of the step's pre-pass state belongs to event generation. | M6 plan decision 6 (`StepState`). |
| step set-up | The set-up of one energy step: its isomer, spectrum, excitation and energy checks, then the threshold and the pre-pass decision. | M6 plan decision 5 (control flow). |
| Str function | Converts a number to text in the form BASIC gives it | Milestone 3 plan decision 2 |
| substream | An independent random sequence given to one event, so its values do not depend on other events or on the thread count. | IMPLEMENTATION_STRATEGY §2.3 and milestone M17 |
| suite verdict | The overall accept or fail outcome of one candidate suite judged against a calibration. | compare/STATISTICS.md; Planning/MILESTONE_2_PLAN.md |
| synthetic fault | A known change injected into the parsed observables of a held-out run, to test that the verdict detects it. | Planning/MILESTONE_2_PLAN.md |
| system | One fissioning case of the run input, set up and computed in turn. | M4 plan D9 |
| system line | A data line of the form `Z, A, CE` or `Z, A1-A2[+step], CE`, which gives one system per mass number. | M6 plan decision 11 (input-file layout); quirk Q-053 (the system table is filled without a bound). |
| system set-up | The set-up of one system: it sets the system's name and output name, prints its barriers and masses, and passes over a system that is not bound. | M6 plan decision 5 (control flow). |
| T0 | The reference probe that dumps the loaded tables and the initial parameters; see the probe table in the harness. | M4 plan, section 3 |
| T1 | Test tier of deterministic functions: bit-exact equality with BASIC over the inputs GEF uses, also for the per-nucleus tables. | Vision §4.2 |
| T2 | Test tier of samplers and single stochastic stages: same outputs for the same random stream (T2a), same distribution under independent streams (T2b). | Vision §4.2 |
| T3 | Test tier of seeded whole runs: identical output files from the same seed, timestamps masked; the release criterion of phase 1. | Vision §4.2; strategy §2.9 |
| T4 | Test tier of statistical integral comparison of every output; phase 2 only, against the exact C++ code. | Vision §4.2; decision 2026-10-08 |
| T5 | Test tier of the library check: regenerated reference libraries agree statistically with the stored tapes. | Vision §4.2 |
| Tab function | Moves printing to a given column of the current line | Milestone 3 plan decision 2 |
| table block | The block of mass-table memory that holds one table; blocks are separated by allocator chunk headers. | Q-042 |
| temperature window | Range of temperatures at scission that bounds the fragment yields. | Keeps the GEF meaning |
| template | Pattern of fields and literal text that gives the layout of printed values | Milestone 3 plan decision 2 |
| test tier | One of the levels T0–T5 at which the port is compared with BASIC, from embedded data (T0) to the regenerated library (T5). | Vision §4.2 |
| text output | Text that BASIC output statements and functions write for values | Milestone 3 plan decision 2 |
| Thomas Fermi model | Model of the nucleus used for the fission barrier. **Open:** the model variant was not re-read in this subtree. | Keeps the GEF meaning |
| threshold | The multi-chance threshold of an energy step, set in its step set-up before the pre-pass decision. | M6 plan decision 5 (the step set-up sets it). |
| token | One item read from a file or from a DATA list, such as a number or a string | Milestone 3 plan decisions 11 and 12 |
| toolchain pin | The recorded tool versions and the fbc 1.10.1 tarball checksum the build requires, checked against `manifests/toolchain.txt`. | M0 plan |
| top-level operation | Operation at the top of an expression, which decides which rule applies next | Milestone 3 plan decision 9 and fbrt arithmetic rules R3 to R7 and R9 |
| trace selection | The GEF_TRACE settings for steps, passes and events, which choose the records a probe writes. | harness/README.md; Planning/MILESTONE_7_PLAN.md |
| trap | Hardware trap raised by an undefined integer division, such as division by zero | Milestone 3 plan decision 8 and quirk B-002 |
| Trim function | Removes spaces from both ends of a string, or a given pattern from both ends | Milestone 4 plan and Milestone 6 plan for the pattern argument |
| two-system covariance | The covariance between the yields of two systems over the same perturbed runs. | IMPLEMENTATION_STRATEGY milestone M15 |
| UCase function | Converts the letters of a string to upper case | Milestone 4 plan |
| uncertainty | The spread of the results caused by uncertain input parameters, estimated from perturbed runs. | DBC L1 (approved 2026-11-07); IMPLEMENTATION_STRATEGY milestone M12 |
| uncertainty sample | One sampled parameter set: one draw for each perturbed parameter. | M12 |
| unterminated comment | A comment opened by a slash and an apostrophe and never closed; the BASIC program loops forever, and the port stops with an error. | Q-035 |
| update file | The text listing the parameter values after the parameter files are applied; the caller writes it to a file. | M4 plan |
| Val function | Converts the numeric prefix of a string to a number | Milestone 3 plan decision 11 |
| validation manifest | A SHA-256 manifest of the gitignored `validation/` data, committed under `manifests/`. | M0 plan |
| validity check | A check that the verdict's false-alarm rate holds at the designed level: leave-one-out suites and held-out runs are judged, and failures and p-value validity tables are tabulated. **Open:** the Rn-215 calibrations do not pass this check at the designed rate; their fix is deferred. | Planning/MILESTONE_2_PLAN.md (exact first); compare/STATISTICS.md |
| validity flag | Flag that says whether a mass table value is usable. | Keeps the GEF meaning |
| ValInt function | Converts the numeric prefix of a string to an integer | Milestone 3 plan decision 11 |
| ValLng function | Converts the numeric prefix of a string to a long integer | Milestone 3 plan decision 11 |
| variance model | How the expected spread of a numeric field is estimated: Poisson-shaped with a fitted inflation for count-like fields, empirical variance from the null runs for the rest. | Planning/MILESTONE_2_PLAN.md; compare/STATISTICS.md |
| variant string | The value of a variant's ISOSOURCE setting, which selects the code branches compiled for that variant. | M4 plan D3 |
| version report | The output of `gef --version`: version, git revision, compiler, preset, FP flags and the fp-environment verdict. | M0 plan |
| `working copy` | A copy of the nominal model parameters that the builder may change for one bin. | M7 plan |
| working folder | The folder a run starts in; the parameter files are read from it. | M4 plan |
| wrap-around arithmetic | Integer arithmetic that wraps around on overflow, as the compiled BASIC code does | Milestone 3 plan decision 8 |
| `Z-A relation` | Charge of a mode's fragments as a function of mass number. | M7 plan |
