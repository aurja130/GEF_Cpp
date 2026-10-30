# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""The batch-input corpora: GEF inputs run through the BASIC program (M6.0, M7.0).

Manifests (same schema):

* ``inputs/m6/corpus.toml`` is written by ``generate``: every distinct ``*.in`` sequence file
  under ``Reference/GEF_code/wrkdir/in/`` (identical copies, e.g. under ``fit/``, once), every
  ``file*.in`` list in ``Reference/GEF_code/wrkdir/`` and the sequence files of
  ``validation/reference/``.
* ``inputs/m6/edge.toml`` is written by hand: the M6 edge inputs.
* ``inputs/m7/corpus.toml`` is written by hand: the M7 table-builder captures
  (``MILESTONE_7_PLAN.md`` D5); each entry fixes its own seed and trace selection.

Entry keys::

    id          unique name; the entry's run directory is <out>/<id>
    group       "wrkdir", "validation", "edge" or "m7"
    input       repository-relative sequence file (or file.in list, see file_in)
    tree        optional repository-relative directory whose files are copied to work/in/
    file_in     optional repository-relative file used as work/file.in (default: the
                generated list of ``input``, i.e. ``"in/<name>"`` and ``END``)
    prepend     optional lines written before file.in (``NITER(1)`` for fit-mode inputs, so
                that BASIC ends after the first fit iteration; M6 plan D4)
    work_files  optional list of {src, dest}: repository-relative file to work/<dest>
    timeout_s   optional run time limit (default 300)
    note        optional free text
    seed        optional GEF_SEED of this entry (default: ``run --seed``)
    steps       optional GEF_TRACE_STEPS of this entry (default: every step)
    passes      optional GEF_TRACE_PASSES of this entry (default: ``run --passes``)
    cells       optional list of COVERAGE_MATRIX.md rows the entry covers
    chain       optional bool: a run of the M7 end-to-end chain (plan D2: nominal passes and
                first-chance steps only)

Usage::

    python3 -m harness.corpus generate
    python3 -m harness.corpus list [--manifest m6|m7] [--group G]
    python3 -m harness.corpus run --binary <path|build-id> --out DIR [--manifest m6|m7]
                                  [--group G ...] [--id ID ...] [--jobs N] [--seed S]
                                  [--keep-t0] [--passes LIST] [--timeout S]

``run`` runs every selected entry with ``harness.run`` into ``DIR/<id>/`` (the entry's
``steps``, default every energy step; the entry's ``passes``, default ``--passes``, default 0,
which writes P3 only in pass 0; the entry's ``seed``, default ``--seed``) and writes
``DIR/corpus.json`` (per entry: exit code, error, seed, scope). ``--manifest`` picks the M6
manifests (default) or the M7 one. A non-zero exit or a timeout is recorded,
not fatal: some inputs end GEF on purpose or never end. ``--timeout`` replaces every entry's
``timeout_s`` (full runs). For full runs, ``--passes 1000000`` selects no pass, so no P3 is
written. ``probes/T0.txt`` is deleted from every run unless ``--keep-t0``: it is the same for
every run of a binary (the tables and parameters at start-up, capture ``m4-t0-jeff33``) and
would make a corpus capture 10 MB per entry. The ``DIR`` is then stored with
``python3 -m harness.store add DIR --id <capture-id> --kind capture``.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import tempfile
import tomllib
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from harness.build import resolve_binary
from harness.common import INPUTS_DIR, REPO_ROOT, HarnessError, write_json
from harness.run import run

__all__ = [
    "CORPUS_MANIFEST",
    "EDGE_MANIFEST",
    "M7_MANIFEST",
    "MANIFESTS",
    "Entry",
    "generate",
    "load_entries",
    "run_entries",
]

M6_INPUTS = INPUTS_DIR / "m6"
CORPUS_MANIFEST = M6_INPUTS / "corpus.toml"
EDGE_MANIFEST = M6_INPUTS / "edge.toml"
M7_MANIFEST = INPUTS_DIR / "m7" / "corpus.toml"
MANIFESTS: dict[str, tuple[Path, ...]] = {
    "m6": (CORPUS_MANIFEST, EDGE_MANIFEST),
    "m7": (M7_MANIFEST,),
}
WRKDIR = Path("Reference/GEF_code/wrkdir")
VALIDATION_SEQUENCES = (
    Path("validation/reference/gefy_nfy"),
    Path("validation/reference/gefy_sfy"),
)
DEFAULT_TIMEOUT_S = 300.0
STEPS = "1-1000000"
_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
_FIT_RE = re.compile(rb"^\s*fit\s*(\(|$)", re.IGNORECASE)
_NITER_RE = re.compile(rb"^\s*niter\(", re.IGNORECASE)


@dataclass(frozen=True)
class Entry:
    """One corpus entry (see the module docstring)."""

    id: str
    group: str
    input: Path
    tree: Path | None = None
    file_in: Path | None = None
    prepend: tuple[str, ...] = ()
    work_files: tuple[tuple[Path, str], ...] = ()
    timeout_s: float = DEFAULT_TIMEOUT_S
    note: str = ""
    seed: int | None = None
    steps: str | None = None
    passes: str | None = None
    cells: tuple[str, ...] = ()
    chain: bool = False

    def input_dest(self) -> str:
        """Where the input goes in the working directory: a file.in list (already the bytes of
        file.in) under ``lists/``, a sequence file inside ``tree`` at its place under ``in/``,
        any other under ``in/``."""
        if self.file_in is not None:
            return f"lists/{self.input.name}"
        if self.tree is not None and self.input.is_relative_to(self.tree):
            return f"in/{self.input.relative_to(self.tree).as_posix()}"
        return f"in/{self.input.name}"

    def file_in_bytes(self) -> bytes:
        """The bytes of work/file.in for this entry."""
        head = "".join(f"{line}\n" for line in self.prepend).encode()
        if self.file_in is not None:
            return head + (REPO_ROOT / self.file_in).read_bytes()
        return head + f'"{self.input_dest()}"\nEND\n'.encode()


def _entry_from_table(table: dict[str, Any], where: str) -> Entry:
    known = {
        "id",
        "group",
        "input",
        "tree",
        "file_in",
        "prepend",
        "work_files",
        "timeout_s",
        "note",
        "seed",
        "steps",
        "passes",
        "cells",
        "chain",
    }
    unknown = set(table) - known
    if unknown:
        raise HarnessError(f"{where}: unknown keys {sorted(unknown)}")
    try:
        ident = str(table["id"])
        group = str(table["group"])
        source = Path(str(table["input"]))
    except KeyError as exc:
        raise HarnessError(f"{where}: missing key {exc}") from exc
    if _ID_RE.fullmatch(ident) is None:
        raise HarnessError(f"{where}: bad id {ident!r}")
    work: list[tuple[Path, str]] = []
    for item in table.get("work_files", []):
        work.append((Path(str(item["src"])), str(item["dest"])))
    return Entry(
        id=ident,
        group=group,
        input=source,
        tree=Path(str(table["tree"])) if "tree" in table else None,
        file_in=Path(str(table["file_in"])) if "file_in" in table else None,
        prepend=tuple(str(x) for x in table.get("prepend", [])),
        work_files=tuple(work),
        timeout_s=float(table.get("timeout_s", DEFAULT_TIMEOUT_S)),
        note=str(table.get("note", "")),
        seed=int(table["seed"]) if "seed" in table else None,
        steps=str(table["steps"]) if "steps" in table else None,
        passes=str(table["passes"]) if "passes" in table else None,
        cells=tuple(str(x) for x in table.get("cells", [])),
        chain=bool(table.get("chain", False)),
    )


def load_entries(manifests: Sequence[Path] = (CORPUS_MANIFEST, EDGE_MANIFEST)) -> list[Entry]:
    """All entries of ``manifests`` (missing manifests are skipped), ids unique."""
    entries: list[Entry] = []
    for manifest in manifests:
        if not manifest.is_file():
            continue
        data = tomllib.loads(manifest.read_text(encoding="utf-8"))
        for index, table in enumerate(data.get("entry", [])):
            entries.append(_entry_from_table(table, f"{manifest.name} entry {index + 1}"))
    ids = [e.id for e in entries]
    duplicates = sorted({i for i in ids if ids.count(i) > 1})
    if duplicates:
        raise HarnessError(f"duplicate corpus ids: {duplicates}")
    return entries


# --------------------------------------------------------------------------- generate


def _active_lines(data: bytes) -> list[bytes]:
    return [ln for ln in data.splitlines() if ln.strip() and not ln.lstrip().startswith(b"'")]


def _has_fit(data: bytes) -> bool:
    return any(_FIT_RE.match(ln) for ln in _active_lines(data))


def _has_niter(data: bytes) -> bool:
    return any(_NITER_RE.match(ln) for ln in _active_lines(data))


def _list_targets(data: bytes) -> list[Path]:
    """Sequence files a file.in list names (relative to the GEF working directory)."""
    targets: list[Path] = []
    for line in _active_lines(data):
        text = line.strip().decode("latin-1")
        if text.upper() == "END":
            break
        if text.upper() == "FIT" or text.upper().startswith("NITER("):
            continue
        text = text.split("'", 1)[0].strip().strip('"')
        targets.append(Path(text))
    return targets


def _quote(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _render(entries: Sequence[Entry]) -> str:
    out = [
        "# SPDX-License-Identifier: GPL-3.0-or-later",
        "# Copyright (C) 2026 Aurora Jahan",
        "# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.",
        "# Generated by `python3 -m harness.corpus generate`; do not edit (M6 plan, M6.0).",
        "",
    ]
    for e in entries:
        out.append("[[entry]]")
        out.append(f"id = {_quote(e.id)}")
        out.append(f"group = {_quote(e.group)}")
        out.append(f"input = {_quote(e.input.as_posix())}")
        if e.tree is not None:
            out.append(f"tree = {_quote(e.tree.as_posix())}")
        if e.file_in is not None:
            out.append(f"file_in = {_quote(e.file_in.as_posix())}")
        if e.prepend:
            out.append("prepend = [" + ", ".join(_quote(p) for p in e.prepend) + "]")
        if e.timeout_s != DEFAULT_TIMEOUT_S:
            out.append(f"timeout_s = {e.timeout_s:g}")
        if e.note:
            out.append(f"note = {_quote(e.note)}")
        out.append("")
    return "\n".join(out)


def _entry_id(prefix: str, rel: Path) -> str:
    stem = rel.with_suffix("").as_posix().replace("/", "_")
    return f"{prefix}-{stem}"


def generate() -> list[Entry]:
    """The generated entries (``corpus.toml``)."""
    entries: list[Entry] = []
    in_dir = REPO_ROOT / WRKDIR / "in"
    seen: dict[str, Path] = {}
    files = sorted(in_dir.rglob("*.in"), key=lambda p: (len(p.relative_to(in_dir).parts), str(p)))
    for path in files:
        data = path.read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        rel = path.relative_to(in_dir)
        if digest in seen:
            continue
        seen[digest] = rel
        fit = _has_fit(data)
        # A first line that is not a number leaves a character in the putback buffer of
        # `Input #`, so EOF() stays false and the `Line Input` loop of GEF.bas:2843 never ends.
        hangs = data.lstrip(b" \t").startswith(b"'")
        notes = ["fit mode: NITER(1) added"] if fit else []
        if hangs:
            notes.append("first line is a comment: GEF never ends")
        entries.append(
            Entry(
                id=_entry_id("wrkdir", rel),
                group="wrkdir",
                input=WRKDIR / "in" / rel,
                tree=WRKDIR / "in",
                prepend=("NITER(1)",) if fit else (),
                timeout_s=20.0 if hangs else DEFAULT_TIMEOUT_S,
                note="; ".join(notes),
            )
        )
    for path in sorted((REPO_ROOT / WRKDIR).glob("*.in"), key=lambda p: p.name.lower()):
        if not path.name.lower().startswith("file"):
            continue
        data = path.read_bytes()
        fit = _has_fit(data)
        for target in _list_targets(data):
            target_path = REPO_ROOT / WRKDIR / target
            if target_path.is_file() and _has_fit(target_path.read_bytes()):
                fit = True
        add_niter = fit and not _has_niter(data)
        entries.append(
            Entry(
                id=_entry_id("wrkdir-list", Path(path.name)),
                group="wrkdir",
                input=WRKDIR / path.name,
                tree=WRKDIR / "in",
                file_in=WRKDIR / path.name,
                prepend=("NITER(1)",) if add_niter else (),
                note="file.in list" + ("; fit mode: NITER(1) added" if add_niter else ""),
            )
        )
    for seq in VALIDATION_SEQUENCES:
        entries.append(Entry(id=f"validation-{seq.name}", group="validation", input=seq))
    return entries


# --------------------------------------------------------------------------- run


def _work_files(entry: Entry) -> list[tuple[Path, str]]:
    placed: list[tuple[Path, str]] = []
    if entry.tree is not None:
        root = REPO_ROOT / entry.tree
        for path in sorted(p for p in root.rglob("*") if p.is_file()):
            dest = f"in/{path.relative_to(root).as_posix()}"
            if dest == entry.input_dest():
                continue  # the input itself goes there
            placed.append((path, dest))
    for source, dest in entry.work_files:
        placed.append((REPO_ROOT / source, dest))
    return placed


def _run_one(
    entry: Entry,
    binary: Path,
    out: Path,
    seed: int,
    keep_t0: bool,
    passes: str,
    timeout_s: float | None,
) -> dict[str, Any]:
    record: dict[str, Any] = {"id": entry.id, "group": entry.group}
    run_seed = seed if entry.seed is None else entry.seed
    scope = {
        "steps": STEPS if entry.steps is None else entry.steps,
        "passes": passes if entry.passes is None else entry.passes,
    }
    if entry.seed is not None or entry.steps is not None or entry.passes is not None:
        record["seed"] = run_seed
        record["scope"] = scope
    with tempfile.TemporaryDirectory() as tmp:
        file_in = Path(tmp) / "file.in"
        file_in.write_bytes(entry.file_in_bytes())
        try:
            result = run(
                binary,
                REPO_ROOT / entry.input,
                out / entry.id,
                run_seed,
                scope=scope,
                timeout_s=entry.timeout_s if timeout_s is None else timeout_s,
                work_files=_work_files(entry),
                file_in=file_in,
                input_dest=entry.input_dest(),
            )
            record["exit_code"] = result.exit_code
        except HarnessError as exc:
            run_json = out / entry.id / "run.json"
            record["error"] = str(exc)
            if run_json.is_file():
                record["exit_code"] = json.loads(run_json.read_text(encoding="utf-8"))["exit_code"]
    t0 = out / entry.id / "work" / "probes" / "T0.txt"
    if not keep_t0 and t0.is_file():
        t0.unlink()
    return record


def run_entries(
    entries: Sequence[Entry],
    binary: Path,
    out: Path,
    *,
    seed: int = 1,
    jobs: int = 1,
    keep_t0: bool = False,
    passes: str = "0",
    timeout_s: float | None = None,
) -> dict[str, Any]:
    """Run ``entries`` into ``out/<id>/`` and write ``out/corpus.json``."""
    if out.exists() and any(out.iterdir()):
        raise HarnessError(f"{out} exists and is not empty")
    out.mkdir(parents=True, exist_ok=True)

    def one(entry: Entry) -> dict[str, Any]:
        return _run_one(entry, binary, out, seed, keep_t0, passes, timeout_s)

    with ThreadPoolExecutor(max_workers=max(1, jobs)) as pool:
        records = list(pool.map(one, entries))
    summary: dict[str, Any] = {
        "schema": 1,
        "binary": str(binary),
        "seed": seed,
        "scope": {"steps": STEPS, "passes": passes},
        "t0_removed": not keep_t0,
        "entries": records,
    }
    write_json(out / "corpus.json", summary)
    return summary


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m harness.corpus", description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("generate", help="rewrite harness/inputs/m6/corpus.toml")
    lst = sub.add_parser("list", help="list entries")
    lst.add_argument("--manifest", choices=sorted(MANIFESTS), default="m6")
    lst.add_argument("--group", action="append", default=[])
    rn = sub.add_parser("run", help="run entries")
    rn.add_argument("--binary", required=True)
    rn.add_argument("--out", required=True, type=Path)
    rn.add_argument("--manifest", choices=sorted(MANIFESTS), default="m6")
    rn.add_argument("--group", action="append", default=[])
    rn.add_argument("--id", action="append", default=[])
    rn.add_argument("--jobs", type=int, default=1)
    rn.add_argument("--seed", type=int, default=1)
    rn.add_argument("--keep-t0", action="store_true")
    rn.add_argument("--passes", default="0")
    rn.add_argument("--timeout", type=float, default=None)
    args = parser.parse_args(argv)
    try:
        if args.cmd == "generate":
            entries = generate()
            CORPUS_MANIFEST.parent.mkdir(parents=True, exist_ok=True)
            CORPUS_MANIFEST.write_text(_render(entries), encoding="utf-8")
            print(f"{len(entries)} entries written to {CORPUS_MANIFEST.relative_to(REPO_ROOT)}")
            return 0
        entries = load_entries(MANIFESTS[args.manifest])
        if args.group:
            entries = [e for e in entries if e.group in args.group]
        if getattr(args, "id", None):
            wanted = set(args.id)
            entries = [e for e in entries if e.id in wanted]
            missing = wanted - {e.id for e in entries}
            if missing:
                raise HarnessError(f"unknown ids: {sorted(missing)}")
        if args.cmd == "list":
            for e in entries:
                print(f"{e.id}\t{e.group}\t{e.input.as_posix()}\t{e.note}")
            return 0
        summary = run_entries(
            entries,
            resolve_binary(args.binary),
            args.out,
            seed=args.seed,
            jobs=args.jobs,
            keep_t0=args.keep_t0,
            passes=args.passes,
            timeout_s=args.timeout,
        )
        failed = [r for r in summary["entries"] if r.get("exit_code") != 0]
        print(f"{len(summary['entries'])} entries run, {len(failed)} with a non-zero exit or error")
        return 0
    except HarnessError as exc:
        print(f"harness.corpus: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
