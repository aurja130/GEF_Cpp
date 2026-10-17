# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Store-derived golden of the M6.1 P0 parser test, format 2.

For every run of the m6 captures that has ``work/file.in``, ``plan.txt`` lists the files
copied into ``work/`` (ids into a ``file`` table at its head) and, for each sequence file
BASIC parsed (``stdout.log``), what the parser did: the P0 record that parse wrote, or
``end``/``hang`` when it wrote none. ``fingerprints.txt`` gives every P0 record a line count
and an FNV-1a 64 digest of its dump lines. The C++ test replays the parses from the plan and
compares its P0 dump with the fingerprints.

Derivation rules, all checked against the store:

- An input goes to its recorded dest, else to the sequence path BASIC opened under its name,
  else to the one file under ``work/`` with its sha256. The batch file ``work/file.in`` is no
  candidate: the plan's ``filein`` line records it. A work file goes to its recorded dest, else
  to its name at the work root.
- Only the last parse may lack a P0 record. Its Ifilein is 1 after a restart and the previous
  Ifilein plus one otherwise. Its Emode is the run's last P1 Emode, else its last P0 Emode,
  else 1.
- A parse whose P0 record has Cfileoutlmd ``$Events.lmd`` (the LMD option path) has seed ``-``:
  that parse wrote Cfileoutlmd_full itself before the probe, so the dump does not show the value
  it started from. Other parses take their seed from their record's Cfileoutlmd_full; a parse
  without a P0 record takes the last record's Cfileoutlmd_full.
- Without P0 a parse is ``hang`` when the run exited nonzero and ``end`` otherwise. The exit
  code is the one ``corpus.json`` gives the run, else the one in ``run.json``.
- A record's digest covers its full dump lines, each followed by a newline, grouped by variable
  in ascending NAME order and kept in dump order within a variable. Each variable's lines must
  be contiguous within their record.
- A run whose store lacks ``work/file.in`` is left out of the golden: ``plan.txt`` gets a
  ``# skipped`` comment line for it instead of a block. Such a run must record no ``file_in``
  in ``run.json``.
- Runs are numbered from 1 in plan order, skipped runs excluded; ``fingerprints.txt`` names a
  run by that number. A file's source is the repo-relative path under the source roots with
  the same sha256, or ``-``.

Usage from the repository root: ``python3 -m harness.p0_golden [--out DIR] [--replace]``.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Final, cast

from harness.common import INPUTS_DIR, REPO_ROOT, STORE_CAPTURES, HarnessError, sha256_file
from harness.golden import GOLDEN_DIR, write_derived
from harness.probe_fingerprints import fnv1a64, split_lines
from harness.probes import ProbeRecord, parse_line, read_probe_file

CAPTURES: Final[tuple[str, ...]] = (
    "m6-setup-corpus",
    "m6-setup-edge-4",
    "m6-full-f1-f7",
    "m6-patch-check-m1",
)
GOLDEN_OUT: Final[Path] = GOLDEN_DIR / "m6-p0"
TOOL: Final[str] = "python3 -m harness.p0_golden"
PLAN_HEADER: Final[str] = "# m6-p0 plan 2"
FINGERPRINTS_HEADER: Final[str] = "# m6-p0 fingerprints 2"
PROBE: Final[str] = "P0"
FOUND_LINE: Final[str] = "File 'file.in' found."
SEQUENCE_MARK: Final[str] = "Sequence of nuclei given in "
SEQUENCE_RE: Final[re.Pattern[str]] = re.compile(
    r"Sequence of nuclei given in (?P<path>.*?) will be calculated!"
)
EVENTS_LMD: Final[str] = "$Events.lmd"  # Cfileoutlmd after the LMD and LMD+ options


@dataclass(frozen=True)
class Parse:
    """One ``Sequence of nuclei given in`` line of ``stdout.log``."""

    sequence: str
    restart: bool  # a ``File 'file.in' found.`` line came after the previous parse


@dataclass(frozen=True)
class P0Record:
    """One record of ``work/probes/P0.txt``: what its parse read, and a digest of its dump."""

    rec: int
    ifilein: int
    emode: int
    cfileoutlmd: str  # short name: EVENTS_LMD marks a parse on the LMD option path
    cfileoutlmd_full: bytes
    lines: int  # dump lines of the record
    fnv: int  # FNV-1a 64 of those lines, see ``_record_fnv``


@dataclass(frozen=True)
class Golden:
    """The two text files of the golden and the store files they were derived from."""

    plan_text: str
    fingerprint_text: str
    sources: tuple[tuple[str, str], ...]  # (capture, path relative to the capture)


@dataclass(frozen=True)
class _RunBlock:
    """One run that has ``work/file.in``, reduced to what the two golden files need."""

    capture: str
    rel: str
    filein: str  # lower-case hex of work/file.in, or "-" when it is empty
    work: tuple[tuple[str, str], ...]  # (dest, sha256) of each input and work file, in order
    parses: tuple[str, ...]  # one ``parse`` line per parse of the run
    records: tuple[P0Record, ...]
    files: tuple[str, ...]  # store files read, relative to the capture


def default_source_roots() -> tuple[tuple[str, Path], ...]:
    """Work-file source roots in search order: (repo-relative prefix, directory)."""
    return (
        ("harness/inputs", INPUTS_DIR),
        ("Reference/GEF_code/wrkdir", REPO_ROOT / "Reference" / "GEF_code" / "wrkdir"),
        ("validation/reference", REPO_ROOT / "validation" / "reference"),
    )


def build_golden(
    captures_dir: Path,
    captures: Sequence[str],
    source_roots: Sequence[tuple[str, Path]],
) -> Golden:
    """Derive the golden for ``captures`` under ``captures_dir``. Writes nothing."""
    sources = _index_sources(source_roots)
    items: list[_RunBlock | str] = []  # a run block, or the skip comment of a skipped run
    files: set[tuple[str, str]] = set()
    for capture in captures:
        base = captures_dir / capture
        if not base.is_dir():
            raise HarnessError(f"capture {capture} not found in {captures_dir}")
        run_jsons = sorted(base.rglob("run.json"))
        run_ids = {path.parent.relative_to(base).as_posix() for path in run_jsons}
        exit_codes: dict[str, int] = {}
        corpus = base / "corpus.json"
        if corpus.is_file():
            exit_codes = _corpus_exit_codes(corpus, capture)
            unknown = sorted(set(exit_codes) - run_ids)
            if unknown:
                raise HarnessError(f"{capture}: corpus.json names unknown runs {unknown}")
            files.add((capture, "corpus.json"))
        for run_json in run_jsons:
            run_dir = run_json.parent
            rel = run_dir.relative_to(base).as_posix()
            if not (run_dir / "work" / "file.in").is_file():
                items.append(_skip_line(capture, rel, run_json))
                files.add((capture, f"{rel}/run.json"))
                continue
            block = _run_block(capture, rel, run_dir, exit_codes.get(rel))
            items.append(block)
            files.update((capture, path) for path in block.files)
    plan_text, fingerprint_text = _render(items, sources)
    return Golden(
        plan_text=plan_text,
        fingerprint_text=fingerprint_text,
        sources=tuple(sorted(files)),
    )


def _render(items: Sequence[_RunBlock | str], sources: dict[str, str]) -> tuple[str, str]:
    """Number the runs, id the work files in first-use order, and lay out both texts."""
    ids: dict[tuple[str, str], int] = {}  # (dest, sha256) -> file id
    table: list[str] = []
    body: list[str] = []
    rows: list[str] = [FINGERPRINTS_HEADER]
    runs = 0
    for item in items:
        if isinstance(item, str):
            body.append(item)
            continue
        runs += 1
        work_ids: list[str] = []
        for dest, sha in item.work:
            key = (dest, sha)
            if key not in ids:
                ids[key] = len(ids) + 1
                table.append(f"file {ids[key]} {dest} {sources.get(sha, '-')} {sha}")
            work_ids.append(str(ids[key]))
        body.append(f"run {runs} {item.capture} {item.rel}")
        body.append(f"filein {item.filein}")
        body.append(" ".join(["work", *work_ids]))
        body.extend(item.parses)
        body.append("endrun")
        rows.extend(
            f"{runs} {record.rec} {record.lines} {record.fnv:016x}" for record in item.records
        )
    plan = [PLAN_HEADER, *table, *body]
    return "\n".join(plan) + "\n", "\n".join(rows) + "\n"


def write_golden(out: Path, golden: Golden, *, replace: bool) -> None:
    """Write ``plan.txt`` and ``fingerprints.txt`` into ``out``, then its ``derived.json``."""
    if out.exists():
        if not replace:
            raise HarnessError(f"golden {out} exists; pass --replace to produce it again")
        shutil.rmtree(out)
    out.mkdir(parents=True)
    (out / "plan.txt").write_text(golden.plan_text, encoding="utf-8", newline="\n")
    (out / "fingerprints.txt").write_text(golden.fingerprint_text, encoding="utf-8", newline="\n")
    write_derived(out, TOOL, list(golden.sources))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Derive the m6-p0 golden from the store.")
    parser.add_argument("--out", type=Path, default=GOLDEN_OUT, help="golden directory to write")
    parser.add_argument("--replace", action="store_true", help="replace an existing golden")
    args = parser.parse_args(argv)
    out: Path = args.out
    replace: bool = args.replace
    try:
        golden = build_golden(STORE_CAPTURES, CAPTURES, default_source_roots())
        write_golden(out, golden, replace=replace)
    except HarnessError as exc:
        print(f"p0_golden: {exc}", file=sys.stderr)
        return 2
    print(f"wrote {out}")
    return 0


def _run_block(
    capture: str,
    rel: str,
    run_dir: Path,
    corpus_exit: int | None,
) -> _RunBlock:
    where = f"{capture}/{rel}"
    run = _load_json(run_dir / "run.json", where)
    exit_code = corpus_exit
    if exit_code is None:
        exit_code = _int_of(_field(run, "exit_code", where), "exit_code", where)
    parses = _read_parses((run_dir / "stdout.log").read_text(encoding="latin-1"), where)
    probes = run_dir / "work" / "probes"
    p0 = _read_p0(probes / "P0.txt", where)
    last_p1 = _last_p1_emode(probes / "P1.txt", where)
    filein = (run_dir / "work" / "file.in").read_bytes()
    _check_file_in(run, filein, where)
    files = [f"{rel}/run.json", f"{rel}/stdout.log", f"{rel}/work/file.in"]
    for name in ("P0.txt", "P1.txt"):
        if (probes / name).is_file():
            files.append(f"{rel}/work/probes/{name}")
    return _RunBlock(
        capture=capture,
        rel=rel,
        filein=filein.hex() or "-",
        work=tuple(_work_entries(run, parses, run_dir / "work", where)),
        parses=tuple(_parse_lines(parses, p0, last_p1, exit_code, where)),
        records=tuple(p0),
        files=tuple(files),
    )


def _skip_line(capture: str, rel: str, run_json: Path) -> str:
    """Plan comment for a run without work/file.in; the run must record no file_in."""
    where = f"{capture}/{rel}"
    if _load_json(run_json, where).get("file_in") is not None:
        raise HarnessError(f"{where}: run.json records file_in but work/file.in is absent")
    return f"# skipped {capture} {rel}: the store keeps no work/file.in"


def _parse_lines(
    parses: Sequence[Parse],
    p0: Sequence[P0Record],
    last_p1_emode: int | None,
    exit_code: int,
    where: str,
) -> list[str]:
    """One ``parse`` line per parse: the P0 record it wrote, else ``end`` or ``hang``."""
    if len(parses) - len(p0) not in (0, 1):
        raise HarnessError(
            f"{where}: {len(p0)} P0 records for {len(parses)} parses; "
            "only the last parse may lack one"
        )
    lines: list[str] = []
    previous: int | None = None
    for number, parse in enumerate(parses, start=1):
        expected = 1 if parse.restart else (None if previous is None else previous + 1)
        if number <= len(p0):
            record = p0[number - 1]
            if expected is not None and record.ifilein != expected:
                raise HarnessError(
                    f"{where}: parse {number} has Ifilein {record.ifilein}, expected {expected}"
                )
            ifilein = record.ifilein
            emode = record.emode
            # the LMD option path wrote Cfileoutlmd_full itself: no seed (module docstring)
            cfile = b"" if record.cfileoutlmd == EVENTS_LMD else record.cfileoutlmd_full
            outcome = f"p0={record.rec}"
        else:
            if expected is None:
                raise HarnessError(
                    f"{where}: parse {number} has no P0 record and no Ifilein to continue from"
                )
            ifilein = expected
            emode = last_p1_emode if last_p1_emode is not None else (p0[-1].emode if p0 else 1)
            cfile = p0[-1].cfileoutlmd_full if p0 else b""
            outcome = "hang" if exit_code != 0 else "end"
        restart = int(parse.restart)
        digest = cfile.hex() or "-"
        lines.append(f"parse {restart} {ifilein} {emode} {digest} {outcome}")
        previous = ifilein
    return lines


def _work_entries(
    run: dict[str, object], parses: Sequence[Parse], work_dir: Path, where: str
) -> list[tuple[str, str]]:
    """(dest, sha256) of the run's input and work files, in run.json order."""
    entries: list[tuple[str, str]] = []
    if run.get("input") is not None:
        inp = _as_object(run["input"], "input", where)
        sha = _str_of(_field(inp, "sha256", where), "input sha256", where)
        entries.append((_input_dest(inp, parses, work_dir, where), sha))
    raw_files = run.get("work_files", [])
    if not isinstance(raw_files, list):
        raise HarnessError(f"{where}: work_files is not a list")
    for item in cast("list[object]", raw_files):
        work = _as_object(item, "work_files entry", where)
        dest = _str_of(_field(work, "name", where), "work file name", where)
        if work.get("dest") is not None:
            dest = _str_of(work["dest"], "work file dest", where)
        sha = _str_of(_field(work, "sha256", where), "work file sha256", where)
        entries.append((dest, sha))
    seen: set[str] = set()
    for dest, _ in entries:
        if dest in seen:
            raise HarnessError(f"{where}: two files are written to {dest}")
        seen.add(dest)
    return entries


def _input_dest(inp: dict[str, object], parses: Sequence[Parse], work_dir: Path, where: str) -> str:
    """Dest of the run's input: recorded, else the sequence path BASIC opened, else the one
    file under work/ with its sha256. The batch file work/file.in is no candidate."""
    if inp.get("dest") is not None:
        return _str_of(inp["dest"], "input dest", where)
    name = _str_of(_field(inp, "name", where), "input name", where)
    opened = sorted({parse.sequence for parse in parses if Path(parse.sequence).name == name})
    if len(opened) > 1:
        raise HarnessError(f"{where}: input {name} matches sequence paths {opened}")
    if opened:
        return opened[0]
    sha = _str_of(_field(inp, "sha256", where), "input sha256", where)
    copies: list[str] = []
    for path in sorted(work_dir.rglob("*")):
        relative = path.relative_to(work_dir).as_posix()
        if path.is_file() and relative != "file.in" and sha256_file(path) == sha:
            copies.append(relative)
    if not copies:
        raise HarnessError(f"{where}: no file under work/ has the sha256 of input {name}")
    if len(copies) > 1:
        raise HarnessError(
            f"{where}: {len(copies)} files under work/ have the sha256 of input {name}: {copies}"
        )
    return copies[0]


def _check_file_in(run: dict[str, object], filein: bytes, where: str) -> None:
    if run.get("file_in") is None:
        return
    recorded = _as_object(run["file_in"], "file_in", where)
    sha = _str_of(_field(recorded, "sha256", where), "file_in sha256", where)
    if hashlib.sha256(filein).hexdigest() != sha:
        raise HarnessError(f"{where}: work/file.in does not match file_in in run.json")


def _read_parses(stdout: str, where: str) -> list[Parse]:
    parses: list[Parse] = []
    restart = False
    for line in stdout.split("\n"):
        if FOUND_LINE in line:
            restart = True
        if SEQUENCE_MARK in line:
            match = SEQUENCE_RE.search(line)
            if match is None:
                raise HarnessError(f"{where}: unreadable sequence line {line!r}")
            parses.append(Parse(str(match.group("path")), restart))
            restart = False
    return parses


def _read_p0(path: Path, where: str) -> list[P0Record]:
    if not path.is_file():
        return []
    lines = split_lines(path.read_bytes())
    probe_records = read_probe_file(path)
    if sum(record.line_count for record in probe_records) != len(lines):
        raise HarnessError(f"{where}: {path.name} has blank lines")
    records: list[P0Record] = []
    start = 0
    for number, record in enumerate(probe_records, start=1):
        if record.probe != PROBE:
            raise HarnessError(f"{where}: {path.name} holds {record.probe} records")
        if record.rec != number:
            raise HarnessError(
                f"{where}: P0 record {number} has rec={record.rec}; records must be rec=1..n"
            )
        block = lines[start : start + record.line_count]
        start += record.line_count
        records.append(
            P0Record(
                rec=number,
                ifilein=_int_of(_probe_value(record, "Ifilein", where), "Ifilein", where),
                emode=_int_of(_probe_value(record, "Emode", where), "Emode", where),
                cfileoutlmd=_str_of(
                    _probe_value(record, "Cfileoutlmd", where), "Cfileoutlmd", where
                ),
                cfileoutlmd_full=_str_of(
                    _probe_value(record, "Cfileoutlmd_full", where), "Cfileoutlmd_full", where
                ).encode("latin-1"),
                lines=record.line_count,
                fnv=_record_fnv(block, number, where),
            )
        )
    return records


def _record_fnv(block: Sequence[bytes], rec: int, where: str) -> int:
    """FNV-1a 64 of one record's dump lines, variable by variable in ascending NAME order."""
    named = [(parse_line(line.decode("latin-1")).name, line) for line in block]
    seen: set[str] = set()
    previous: str | None = None
    for name, _ in named:
        if name == previous:
            continue
        if name in seen:
            raise HarnessError(f"{where}: variable {name} is not contiguous in P0 rec={rec}")
        seen.add(name)
        previous = name
    named.sort(key=lambda pair: pair[0])  # stable: each variable keeps its dump order
    return fnv1a64([line for _, line in named])


def _last_p1_emode(path: Path, where: str) -> int | None:
    if not path.is_file():
        return None
    records = read_probe_file(path)
    if not records:
        return None
    return _int_of(_probe_value(records[-1], "Emode", where), "P1 Emode", where)


def _probe_value(record: ProbeRecord, name: str, where: str) -> object:
    if name not in record.variables:
        raise HarnessError(f"{where}: {record.probe} record rec={record.rec} has no {name}")
    return record.var(name).get()


def _corpus_exit_codes(path: Path, capture: str) -> dict[str, int]:
    entries = _field(_load_json(path, capture), "entries", capture)
    if not isinstance(entries, list):
        raise HarnessError(f"{capture}: corpus.json entries is not a list")
    codes: dict[str, int] = {}
    for entry in cast("list[object]", entries):
        item = _as_object(entry, "corpus entry", capture)
        run_id = _str_of(_field(item, "id", capture), "corpus id", capture)
        codes[run_id] = _int_of(_field(item, "exit_code", capture), "corpus exit_code", capture)
    return codes


def _index_sources(roots: Sequence[tuple[str, Path]]) -> dict[str, str]:
    """sha256 -> repo-relative path of the first file with that digest, in root order."""
    index: dict[str, str] = {}
    for prefix, root in roots:
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*")):
            relative = path.relative_to(root)
            if not path.is_file() or any(part.startswith(".") for part in relative.parts):
                continue
            index.setdefault(sha256_file(path), f"{prefix}/{relative.as_posix()}")
    return index


def _load_json(path: Path, where: str) -> dict[str, object]:
    try:
        data: object = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise HarnessError(f"{where}: cannot read {path.name}: {exc}") from exc
    return _as_object(data, path.name, where)


def _as_object(value: object, what: str, where: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise HarnessError(f"{where}: {what} is not a JSON object")
    return cast("dict[str, object]", value)


def _field(obj: dict[str, object], key: str, where: str) -> object:
    if key not in obj:
        raise HarnessError(f"{where}: no {key!r} entry")
    return obj[key]


def _int_of(value: object, what: str, where: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise HarnessError(f"{where}: {what} is not an integer")
    return value


def _str_of(value: object, what: str, where: str) -> str:
    if not isinstance(value, str):
        raise HarnessError(f"{where}: {what} is not a string")
    return value


if __name__ == "__main__":
    raise SystemExit(main())
