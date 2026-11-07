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

At each batch boundary (before delegating a batch, before a review round, before a long build or CI run), and whenever a model call or agent fails on a usage limit, the orchestrator runs `python3 -m tools.agent.usage_guard --status --provider anthropic --threshold 0.95`. It reads the usage omp has already cached (`~/.omp/agent/agent.db`) and never calls a usage API itself: Anthropic ends sessions that poll its API too often, so never add a check that does. Exit 0: work continues. Exit 3: a window has less than 5 % left. The orchestrator waits at most 5 hours, whichever window it is: if every blocked window's reset time (printed by `--status`) is within 5 hours (the 5-hour window always is; the 7-day window only in its last 5 hours), it runs `python3 -m tools.agent.usage_guard --wait --provider anthropic --threshold 0.95` with bash `timeout: 18000`, which sleeps until the windows clear, and work continues; otherwise it does not wait: it reports the low window and work continues until the allowance is used up. Exit 1: omp's cache could not be read; report it and do not substitute an API call.

### Review cycle

1. Freeze the scope and acceptance criteria; every reviewer gets the same ones.
2. Review one verified snapshot: compiled in the affected presets, affected Catch2 and pytest tests passing, the bit-exact comparisons covering the change (T0–T3: driver goldens, probe dumps, `compare.exact`) passing, format, lint and tidy clean. A code change after approval re-verifies and voids the affected approvals.
3. Merge all findings into one blocker ledger: id, violated rule, evidence or counterexample, correction, regression test, status. Mark each as new defect, recurring defect or scope expansion.
4. Check each finding against the source; reviewers can be wrong. Reject unsupported findings with evidence. Scope expansion is the user's decision.
5. Fix the invariant, not the reported input. Check the whole class: light and heavy fragment, both copies of duplicated BASIC code, first and later calls (`Static`, ByRef carry-over), arithmetic and random-draw order, scope reset points (system, step, pass, bin, event), state leaking across scopes, NaN, ±0 and table-bound inputs. Add deterministic regressions for the failure and its symmetric and boundary cases; never weaken an assertion to pass.
6. If a defect survives its fix, stop patching locally: re-derive the state model and give the worker an invariant-level specification.
7. Re-review: reviewers recheck their blockers and the original criteria. A new blocker must cite an original-scope rule and a concrete failure; a preferred design is not one.

**Deliver** when the scope is complete, the required reviewers approve the final snapshot, the gates run are recorded, scaffolds are removed and `Planning/` is updated. Skips are not passes (tests needing `validation/` or the reference store skip without them); one preset does not certify the others (`dev-gcc`, `dev-clang`, `release-exact`); a gate run while code changed proves nothing about the final code.

## DBC (Driven by Concepts)

`Planning/DBC/` is the Captain's (the user's) main tool for leading the project: she reasons and decides in its concepts and terms. Keep it current without exception.

- `CONCEPTS.md` draws the project as mermaid flowcharts: L1 the whole project, one L2 diagram per L1 node, deeper levels only where the depth discipline allows (a structure node with at least three pointable parts, or a rule with steps). Each diagram has a node table (ID, meaning, terms, status) and owns 3–12 nodes. No code, file names or plan names. The Captain's edits to it are directives: turn them into a plan or contract change; never revert them.
- `CODE.md` maps every built concept to files and symbols, never line numbers. `DEFINITIONS.md` is the glossary. `TESTS.md` lists every test with the nodes it guards. `CAPTURES.md` lists every capture family (reference-store manifests, goldens, capture corpora) with its concept nodes and a Comments line.
- The format rules are the ones `Planning/DBC/check_dbc.py` enforces; its docstring lists them. The DBC gets no meta-documents of its own.
- Statuses track the plan: `implemented` (green) is built, `partial` (yellow) is in the current submilestone, `planned` (uncolored) is not started. When a submilestone's contract is frozen, mark the nodes it will build or change `partial` in the same commit. The orchestrator owns all DBC files. After every implementation batch: add or split nodes for concepts the batch made real (respecting the depth discipline); fix `CODE.md` rows; give every new test and capture its node IDs; run `python3 Planning/DBC/check_dbc.py` and fix the DBC files (never the checker's rules) until it passes. When the submilestone closes, flip its `partial` nodes to `implemented`, or back to `planned` if they were deferred, and mark the next submilestone's nodes `partial`. A rule that looks wrong goes to the Captain.
- Any commit that introduces, renames, redefines or retires a term updates `DEFINITIONS.md` in the same commit; any commit that adds, changes or drops a test, golden, store entry or corpus updates `TESTS.md` or `CAPTURES.md`; any commit that changes what a node means or where it lives updates `CONCEPTS.md` or `CODE.md`. No term reaches the Captain in a message, plan or receipt before it is defined there.
- Node IDs are stable; renaming one is a change of meaning. A changed meaning is rewritten in place with the date and the old meaning. Open questions are marked **Open:** in the definition's row.
- Workers and reviewers do not edit DBC files. Worker briefs name the node IDs of their slice; workers report concept impact (nodes built, code that fits no node, new terms) in their return message. The one exception: any agent that finds a problem with a capture entry adds a dated, signed note to its Comments line.
- Decisions put to the Captain use DBC terms. Read DBC files by section. A sub-milestone is not delivered (**Deliver** above) until the checker passes on its final snapshot.

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
- Commit and push when meaningful progress is achieved. If changes by the user are detected, ask if the user wants them included in the commit.
