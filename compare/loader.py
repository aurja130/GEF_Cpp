# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Load a run directory into an ``ObservableTable`` (M2.2).

Two layouts are accepted:

* **M1 run directory**: ``stdout.log``, ``stderr.log`` and ``work/...`` (``run.json``,
  ``gdb.log``, ``capture.json``, ``capture_seed.gdb.py`` are ignored);
* **plain GEF working directory** (e.g. ``validation/test_run``): ``run.log`` is read as
  ``stdout.log`` and every other file as ``work/<path>``.

Memory: an ``ObservableTable`` holds every key of the run in one dict (a dmp file alone gives
about 10 000 observables, a whole BASIC run tens of millions: gigabytes). ``iter_observables``
streams file by file for callers that process per family or per file; ``load_file`` loads one
file. Draw logs (``work/rnd.log``, hundreds of MB) are never read.

Each file goes to the first parser whose ``PATTERNS`` match its run-relative path, in the order
of ``PARSER_NAMES`` (``text`` matches everything and is last). Binary files and files listed in
``probe.UNPARSED_BY_DESIGN`` are reported in ``ObservableTable.unparsed``.
"""

from __future__ import annotations

import fnmatch
import importlib
import time
from collections import Counter
from collections.abc import Iterator
from dataclasses import dataclass, field
from pathlib import Path
from types import ModuleType

from compare.model import Key, ObservableTable, Value
from compare.parsers.probe import UNPARSED_BY_DESIGN

__all__ = [
    "PARSER_NAMES",
    "LoadStats",
    "iter_observables",
    "load_file",
    "load_run",
    "load_run_with_stats",
    "run_files",
    "stream_file",
]

PARSER_NAMES: tuple[str, ...] = ("endf", "mvd", "par", "out", "dmp", "probe", "text")

_M1_ROOT_FILES = ("stdout.log", "stderr.log")


@dataclass
class LoadStats:
    """Per-parser file counts, observable counts and seconds of one ``load_run``."""

    files: Counter[str] = field(default_factory=lambda: Counter[str]())
    observables: Counter[str] = field(default_factory=lambda: Counter[str]())
    seconds: dict[str, float] = field(default_factory=lambda: {})


def parser_modules(names: tuple[str, ...] = PARSER_NAMES) -> list[tuple[str, ModuleType]]:
    return [(n, importlib.import_module(f"compare.parsers.{n}")) for n in names]


def _select(rel: str, modules: list[tuple[str, ModuleType]]) -> tuple[str, ModuleType] | None:
    for name, module in modules:
        patterns: tuple[str, ...] = module.PATTERNS
        if any(fnmatch.fnmatchcase(rel, p) for p in patterns):
            return name, module
    return None


def run_files(run_dir: Path) -> dict[str, Path]:
    """Run-relative POSIX path -> file, for either layout."""
    files: dict[str, Path] = {}
    if (run_dir / "work").is_dir() or (run_dir / "stdout.log").is_file():
        for name in _M1_ROOT_FILES:
            if (run_dir / name).is_file():
                files[name] = run_dir / name
        work = run_dir / "work"
        if work.is_dir():
            for path in sorted(work.rglob("*")):
                if path.is_file():
                    files[path.relative_to(run_dir).as_posix()] = path
        return files
    for path in sorted(run_dir.rglob("*")):
        if not path.is_file():
            continue
        sub = path.relative_to(run_dir).as_posix()
        if sub == "run.log":
            files["stdout.log"] = path
        else:
            files[f"work/{sub}"] = path
    return files


def _is_binary(path: Path) -> bool:
    with path.open("rb") as handle:
        return b"\0" in handle.read(8192)


def stream_file(
    path: Path, rel: str, modules: list[tuple[str, ModuleType]]
) -> Iterator[tuple[Key, Value]] | None:
    """The ``(Key, Value)`` pairs of one file as a lazy stream, or ``None`` if unparsed.

    A file is unparsed when it is listed in ``UNPARSED_BY_DESIGN``, is binary, or matches no
    parser. Unlike ``load_file`` nothing is collected: callers that pack observables into arrays
    never hold the file as a dict.
    """
    if rel in UNPARSED_BY_DESIGN or _is_binary(path):
        return None
    found = _select(rel, modules)
    if found is None:
        return None
    return found[1].observables(path, rel)


def load_file(
    path: Path, rel: str, modules: list[tuple[str, ModuleType]] | None = None
) -> ObservableTable:
    """Observables of one file, dispatched by ``rel``."""
    table = ObservableTable()
    found = _select(rel, modules if modules is not None else parser_modules())
    if found is None:
        table.unparsed.append(rel)
        return table
    table.extend(found[1].observables(path, rel))
    return table


def iter_observables(
    run_dir: Path, modules: list[tuple[str, ModuleType]] | None = None
) -> Iterator[tuple[str, ObservableTable]]:
    """Stream ``(rel, ObservableTable)`` per file of the run; only one file is held at a time."""
    mods = modules if modules is not None else parser_modules()
    for rel, path in run_files(run_dir).items():
        if rel in UNPARSED_BY_DESIGN or _is_binary(path) or _select(rel, mods) is None:
            table = ObservableTable()
            table.unparsed.append(rel)
            yield rel, table
        else:
            yield rel, load_file(path, rel, mods)


def load_run_with_stats(
    run_dir: Path, modules: list[tuple[str, ModuleType]] | None = None
) -> tuple[ObservableTable, LoadStats]:
    """``load_run`` plus per-parser statistics."""
    if not run_dir.is_dir():
        raise NotADirectoryError(f"{run_dir} is not a directory")
    mods = modules if modules is not None else parser_modules()
    table = ObservableTable()
    stats = LoadStats()
    for rel, path in run_files(run_dir).items():
        if rel in UNPARSED_BY_DESIGN or _is_binary(path):
            table.unparsed.append(rel)
            continue
        found = _select(rel, mods)
        if found is None:
            table.unparsed.append(rel)
            continue
        name, module = found
        start = time.perf_counter()
        before = len(table)
        table.extend(module.observables(path, rel))
        stats.seconds[name] = stats.seconds.get(name, 0.0) + time.perf_counter() - start
        stats.files[name] += 1
        stats.observables[name] += len(table) - before
    return table, stats


def load_run(run_dir: Path) -> ObservableTable:
    """All observables of the run in ``run_dir`` (either layout)."""
    return load_run_with_stats(run_dir)[0]
