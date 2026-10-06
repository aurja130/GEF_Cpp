# Planning-session code maps

Six code-mapping reports written during the planning session on 2026-10-06 by read-only scout agents. They were saved from the session store (`.omp/sessions/`) into the repository in M0.1, so they can be read without access to that session.

All line numbers refer to `Reference/GEF_code/source/` at submodule commit **`ba9f0aa`** (GEF 2025/1.2). Each file holds the scout's summary, architecture note, file list and full report. The report text has not been edited; corrections are listed below instead.

| File | Scout | Covers |
|---|---|---|
| [`control_flow.md`](control_flow.md) | ControlFlowScout | Program structure: compile flags, include order, the `GoTo`/label-driven input stage, the nested loops (input file → nucleus line → covariance pass → energy step → `calcstart` pass → event loop), `ctl/` coordination, inputs and outputs per file |
| [`physics_core.md`](physics_core.md) | PhysicsCoreScout | First overview: file roles (active, data, inactive, dead), Monte Carlo core layout, RNG use, parameter perturbation, uncertainty and ENDF yield computation, FreeBASIC hazards |
| [`data_layer.md`](data_layer.md) | DataLayerScout | Static data and infrastructure: the `DATA` tables and their loaders, `Isotab`/`NucTab`, branchings, the analyzer registry, histogram arrays and `Extend_*` growth, parameters, table lookup functions |
| [`setup_physics.md`](setup_physics.md) | SetupPhysicsScout | Per-system and per-energy setup (`GEF.bas:3287–7919`) and the physics functions (`15814–18051`): components S0–S23, the multi-chance pre-pass, the per-nucleus table builder, hidden-state hazards |
| [`event_loop.md`](event_loop.md) | EventLoopScout | The event loop (`GEF.bas:7920–9997`) in 15 stages, the per-event subroutines (`Eva`, `u_accel`, `P_Egamma_*`, `U_Ired*`, `EVEN_ODD`), the samplers and the isomer population |
| [`outputs.md`](outputs.md) | OutputScout | Everything after the event loop (`GEF.bas:10035–15560` plus includes): projections, uncertainties, covariances, `Branchings.bas`, `CovarCUMU.bas`, `ENDF.bas`, χ², `External/`, `out/` and `dmp` writers |

## Claims corrected since the reports were written

The reports are kept as written. The following claims in them are wrong; the corrected facts hold.

1. **46 perturbed parameters, not 48.** `physics_core.md` says 48 parameters are redrawn at `GEF.bas:5112–5160`. There are 46 live `PGauss` perturbation draws in `GEF.bas:5104–5162`; a 47th line is commented out. `data_layer.md` already records the correction.
2. **`GEFSUB` is dead code.** `physics_core.md` lists "GEFSUB/GEFRESULTS arrays: 7517–7919" as part of the live Monte Carlo core. The block `GEF.bas:7514–7919` sits inside a nested `/' … '/` comment and never runs (`setup_physics.md` gives the evidence: `run.log` never prints its `N_cases` line, and its tables are never filled).
3. **`ctl/` in `validation/test_run` holds all three control files.** `control_flow.md` infers that `ctl/` holds only `sync.ctl` and that `thread.ctl` and `done.ctl` were removed. In fact `validation/test_run/ctl/` holds `thread.ctl`, `done.ctl` and `sync.ctl`.
