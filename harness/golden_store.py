# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Reading the runs of store captures for the store-derived goldens.

A capture under ``validation/reference_store/captures/`` holds one directory per run, each with a
``run.json``. The goldens read a run's JSON, its probe dumps under ``work/probes/`` and its
``work/file.in`` through the helpers here. A malformed entry raises ``HarnessError`` naming the
capture and the run it belongs to.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import cast

from harness.common import HarnessError
from harness.probe_fingerprints import split_lines
from harness.probes import ProbeRecord, read_probe_file


@dataclass(frozen=True)
class StoreRun:
    """One run of a capture. ``rel`` is its directory relative to the capture, with ``/``."""

    capture: str
    rel: str
    run_dir: Path
    corpus_exit: int | None  # the exit code corpus.json lists for the run, if it lists it

    @property
    def where(self) -> str:
        """The run as error messages name it."""
        return f"{self.capture}/{self.rel}"

    def has_file_in(self) -> bool:
        """Whether the run has ``work/file.in``; runs without it have no golden entry."""
        return (self.run_dir / "work" / "file.in").is_file()


@dataclass(frozen=True)
class CaptureRuns:
    """The runs of one capture, in the sorted order of their ``run.json`` paths."""

    runs: tuple[StoreRun, ...]
    has_corpus: bool  # whether the capture has a corpus.json


def capture_runs(captures_dir: Path, capture: str) -> CaptureRuns:
    """The runs of ``capture``, with the exit codes its corpus.json lists."""
    base = captures_dir / capture
    if not base.is_dir():
        raise HarnessError(f"capture {capture} not found in {captures_dir}")
    run_dirs = [path.parent for path in sorted(base.rglob("run.json"))]
    rels = [run_dir.relative_to(base).as_posix() for run_dir in run_dirs]
    corpus = base / "corpus.json"
    has_corpus = corpus.is_file()
    exit_codes: dict[str, int] = _corpus_exit_codes(corpus, capture) if has_corpus else {}
    unknown = sorted(set(exit_codes) - set(rels))
    if unknown:
        raise HarnessError(f"{capture}: corpus.json names unknown runs {unknown}")
    runs = tuple(
        StoreRun(capture=capture, rel=rel, run_dir=run_dir, corpus_exit=exit_codes.get(rel))
        for run_dir, rel in zip(run_dirs, rels, strict=True)
    )
    return CaptureRuns(runs=runs, has_corpus=has_corpus)


def run_exit_code(run: StoreRun, run_json: dict[str, object]) -> int:
    """The run's exit code: corpus.json's when it lists the run, else run.json's."""
    if run.corpus_exit is not None:
        return run.corpus_exit
    return int_of(field(run_json, "exit_code", run.where), "exit_code", run.where)


def skip_comment(run: StoreRun) -> str:
    """The comment a derived golden keeps in place of a run that has no work/file.in."""
    if load_json(run.run_dir / "run.json", run.where).get("file_in") is not None:
        raise HarnessError(f"{run.where}: run.json records file_in but work/file.in is absent")
    return f"# skipped {run.capture} {run.rel}: the store keeps no work/file.in"


def read_dump(path: Path, where: str) -> list[tuple[ProbeRecord, list[bytes]]]:
    """The records of the probe dump ``path``, each with its raw lines; empty when absent."""
    if not path.is_file():
        return []
    lines = split_lines(path.read_bytes())
    probe_records = read_probe_file(path)
    if sum(record.line_count for record in probe_records) != len(lines):
        raise HarnessError(f"{where}: {path.name} has blank lines")
    dump: list[tuple[ProbeRecord, list[bytes]]] = []
    start = 0
    for record in probe_records:
        dump.append((record, lines[start : start + record.line_count]))
        start += record.line_count
    return dump


def probe_value(record: ProbeRecord, name: str, where: str) -> object:
    """The decoded value of the variable ``name`` of ``record``."""
    if name not in record.variables:
        raise HarnessError(f"{where}: {record.probe} record rec={record.rec} has no {name}")
    return record.var(name).get()


def load_json(path: Path, where: str) -> dict[str, object]:
    """The JSON object in ``path``; ``where`` names the run in error messages."""
    try:
        data: object = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise HarnessError(f"{where}: cannot read {path.name}: {exc}") from exc
    return as_object(data, path.name, where)


def as_object(value: object, what: str, where: str) -> dict[str, object]:
    if not isinstance(value, dict):
        raise HarnessError(f"{where}: {what} is not a JSON object")
    return cast("dict[str, object]", value)


def field(obj: dict[str, object], key: str, where: str) -> object:
    if key not in obj:
        raise HarnessError(f"{where}: no {key!r} entry")
    return obj[key]


def int_of(value: object, what: str, where: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise HarnessError(f"{where}: {what} is not an integer")
    return value


def str_of(value: object, what: str, where: str) -> str:
    if not isinstance(value, str):
        raise HarnessError(f"{where}: {what} is not a string")
    return value


def _corpus_exit_codes(path: Path, capture: str) -> dict[str, int]:
    entries = field(load_json(path, capture), "entries", capture)
    if not isinstance(entries, list):
        raise HarnessError(f"{capture}: corpus.json entries is not a list")
    codes: dict[str, int] = {}
    for entry in cast("list[object]", entries):
        item = as_object(entry, "corpus entry", capture)
        run_id = str_of(field(item, "id", capture), "corpus id", capture)
        codes[run_id] = int_of(field(item, "exit_code", capture), "corpus exit_code", capture)
    return codes
