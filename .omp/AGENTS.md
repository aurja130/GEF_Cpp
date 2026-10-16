# Agent Context

Development environment (tools, paths, versions):

@LOCAL_ENVIRONMENT.md

Project rules: `Planning/CODING_STANDARDS.md`. Status and plans: `Planning/CURRENT_PROJECT_STATE.md`, `Planning/MILESTONE_<n>_PLAN.md`. Full local CI: `scripts/ci.sh` (`--quick` for the `dev-gcc` pipeline).

## The port

GEF 2025/1.2 (FreeBASIC, `Reference/GEF_code` at `ba9f0aa`) is ported to C++ exact-first: in phase 1 (M3–M16) a seeded C++ run must write the same bytes as the seeded BASIC run. Authorities, in this order: the BASIC source and the C fbc emits from it (`python3 -m tools.fbsrc.fbline`), the decisions in the milestone plan, `Planning/QUIRKS.md`, `Planning/CODING_STANDARDS.md`. A divergence from BASIC is a defect; one that provably cannot be removed needs a written analysis and the user's approval.

## Multi-model workflow

Models come from the user's session choice, otherwise `.omp/config.yml` (`task.agentModelOverrides`: `task` → `@task`, `sonic` → `@smol`, `reviewer` → `@slow`). Disclose any substitution; never claim a model use that was not observed.

- **Orchestrator** (main session): owns scope, plan, contracts, integration, verification and `Planning/` updates. It understands the code it integrates; it does not relay patches.
- **Coding workers**: `task` for bounded slices, `sonic` for mechanical edits. Each gets the target files, the `fbline` output of the BASIC it ports, the relevant `CODING_STANDARDS.md` rules, the interfaces, non-goals and the test or golden that must match. One owner per file; parallel only for independent slices; the top-level plan is never delegated.
- **Reviewers**: `reviewer`, in a context of its own, read-only, judging against the authorities above. A worker never approves its own patch.
- Workers and reviewers do not build or test. The orchestrator verifies each integrated batch; review approval is not runtime proof. Mechanical or documentation-only changes need no review panel.

### Sessions and usage limits

A session completes one sub-milestone (e.g. M6.1) and nothing more: it delivers it as defined under **Deliver** below, then stops and reports. It may run unattended (overnight), so it never stops early to wait for the user while reachable work remains.

At each batch boundary (before delegating a batch, before a review round, before a long build or CI run), and whenever a model call or agent fails on a usage limit, the orchestrator runs `python3 -m tools.agent.wait_for_usage` with bash `timeout: 0`. When a usage window has less than 5 % left and resets within 5 hours (the 5-hour window always; the 7-day window in its last 5 hours), it sleeps until the reset and returns, and work continues; a low window that resets later is reported and work continues until the allowance is used up.

### Review cycle

1. Freeze the scope and acceptance criteria; every reviewer gets the same ones.
2. Review one verified snapshot: compiled in the affected presets, affected Catch2 and pytest tests passing, the bit-exact comparisons covering the change (T0–T3: driver goldens, probe dumps, `compare.exact`) passing, format, lint and tidy clean. A code change after approval re-verifies and voids the affected approvals.
3. Merge all findings into one blocker ledger: id, violated rule, evidence or counterexample, correction, regression test, status. Mark each as new defect, recurring defect or scope expansion.
4. Check each finding against the source; reviewers can be wrong. Reject unsupported findings with evidence. Scope expansion is the user's decision.
5. Fix the invariant, not the reported input. Check the whole class: light and heavy fragment, both copies of duplicated BASIC code, first and later calls (`Static`, ByRef carry-over), arithmetic and random-draw order, scope reset points (system, step, pass, bin, event), state leaking across scopes, NaN, ±0 and table-bound inputs. Add deterministic regressions for the failure and its symmetric and boundary cases; never weaken an assertion to pass.
6. If a defect survives its fix, stop patching locally: re-derive the state model and give the worker an invariant-level specification.
7. Re-review: reviewers recheck their blockers and the original criteria. A new blocker must cite an original-scope rule and a concrete failure; a preferred design is not one.

**Deliver** when the scope is complete, the required reviewers approve the final snapshot, the gates run are recorded, scaffolds are removed and `Planning/` is updated. Skips are not passes (tests needing `validation/` or the reference store skip without them); one preset does not certify the others (`dev-gcc`, `dev-clang`, `release-exact`); a gate run while code changed proves nothing about the final code.

## License notices

The project is `GPL-3.0-or-later` (`LICENSE.txt`), a derivative of GEF. Every file of ours that contains code (C/C++, Python, shell, CMake, FreeBASIC, …) starts with these lines in its comment syntax, after any shebang or encoding line:

```text
SPDX-License-Identifier: GPL-3.0-or-later
Copyright (C) <year the file was created> Aurora Jahan
Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
```

- Files that port GEF code (C++ ports, FreeBASIC drivers, data generated from GEF tables) add directly after: `Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.`
- Add the notice to any file you touch that lacks it; never rewrite existing years.
- Never add it to `Reference/`, fetched third-party code, `build/`, data files or formats without comments (JSON).
- Dependencies must be GPL-3.0-compatible.

## Tracking

- Only the orchestrator edits `Planning/`. When a task, sub-milestone or milestone is finished, mark it done in its plan file and record it in `CURRENT_PROJECT_STATE.md`.
- Commit or push only when the user asks; never include unrelated or private local changes.
