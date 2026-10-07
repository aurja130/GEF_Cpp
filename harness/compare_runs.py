# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Byte-exact comparison of two run directories with documented masks (M1.3).

Usage (from the repository root)::

    python3 -m harness.compare_runs <dirA> <dirB> [--masks FILE | --no-masks]
                                    [--allow-only-in-b GLOB ...]

Compared: ``stdout.log``, ``stderr.log`` and every file below ``work/`` (the set of files must
match; files present on one side only are reported). Not compared: ``run.json`` and ``gdb.log``
(run metadata and gdb's own output, which carry timestamps and paths by design).

Masks come from ``harness/masks.toml`` (or ``--masks FILE``)::

    [[mask]]
    id = "compile-stamp"                  # unique; replaces each match with <MASK:compile-stamp>
    files = ["stdout.log", "work/out/*"]  # fnmatch globs on the POSIX path relative to the run dir
    pattern = "..."                       # Python regex, applied to every line (latin-1 text)
    source = "GEF.bas:1234"               # BASIC location that writes the field
    reason = "..."                        # why the field is time-dependent

Files matching no mask are compared as raw bytes. Masked files are compared line by line after
every match of every applicable pattern has been replaced. The first differing line of every
differing file is printed with both (masked) sides. Masks that matched nothing are listed so that
a stale mask cannot hide drift; this is informational and does not change the exit status.

``--allow-only-in-b GLOB`` (repeatable; fnmatch on the run-dir-relative path) accepts files that
exist only in B, for example the harness's own outputs when B is a probed or logging build
(``work/probes/*``, ``work/rnd.log``). They are listed but do not make the runs different.

Exit status: 0 identical, 1 different, 2 usage or mask-file error.
"""

from __future__ import annotations

import argparse
import fnmatch
import re
import sys
import tomllib
from collections import Counter
from collections.abc import Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from harness.common import MASKS_FILE, HarnessError

__all__ = [
    "NOT_COMPARED",
    "Comparison",
    "FileDifference",
    "Mask",
    "apply_masks",
    "compare_runs",
    "compared_files",
    "load_masks",
]

NOT_COMPARED = frozenset({"run.json", "gdb.log"})
_MASK_KEYS = {"id", "files", "pattern", "source", "reason"}
_MAX_SHOWN = 300


@dataclass(frozen=True)
class Mask:
    """One masked field; see the module docstring."""

    id: str
    files: tuple[str, ...]
    pattern: re.Pattern[str]
    source: str
    reason: str

    def applies_to(self, rel_path: str) -> bool:
        return any(fnmatch.fnmatchcase(rel_path, glob) for glob in self.files)


@dataclass(frozen=True)
class FileDifference:
    """The first differing line of one file (1-based; ``None`` text = the file ended)."""

    path: str
    line: int
    a: str | None
    b: str | None


@dataclass
class Comparison:
    """Result of comparing two run directories."""

    compared: int = 0
    differences: list[FileDifference] = field(default_factory=lambda: [])
    only_in_a: list[str] = field(default_factory=lambda: [])
    only_in_b: list[str] = field(default_factory=lambda: [])
    mask_hits: Counter[str] = field(default_factory=lambda: Counter[str]())
    unused_masks: list[str] = field(default_factory=lambda: [])
    allowed_only_in_b: list[str] = field(default_factory=lambda: [])

    @property
    def identical(self) -> bool:
        return not (self.differences or self.only_in_a or self.only_in_b)


# --------------------------------------------------------------------------- masks


def load_masks(path: Path) -> list[Mask]:
    """Parse and validate a masks file; raises ``HarnessError`` naming the problem."""
    try:
        with path.open("rb") as handle:
            raw = tomllib.load(handle)
    except OSError as exc:
        raise HarnessError(f"cannot read masks file {path}: {exc}") from exc
    except tomllib.TOMLDecodeError as exc:
        raise HarnessError(f"{path}: invalid TOML: {exc}") from exc
    extra = set(raw) - {"mask"}
    if extra:
        raise HarnessError(f"{path}: unknown top-level keys {sorted(extra)}; only [[mask]]")
    entries: Any = raw.get("mask", [])
    if not isinstance(entries, list):
        raise HarnessError(f"{path}: 'mask' must be an array of tables ([[mask]])")
    masks: list[Mask] = []
    seen: set[str] = set()
    for index, entry_any in enumerate(entries, 1):  # pyright: ignore[reportUnknownVariableType, reportUnknownArgumentType]
        where = f"{path}: mask #{index}"
        if not isinstance(entry_any, dict):
            raise HarnessError(f"{where}: not a table")
        entry: dict[str, Any] = {str(k): v for k, v in entry_any.items()}  # pyright: ignore[reportUnknownVariableType, reportUnknownArgumentType, reportUnknownMemberType]
        if set(entry) != _MASK_KEYS:
            raise HarnessError(
                f"{where}: keys must be exactly {sorted(_MASK_KEYS)}, got {sorted(entry)}"
            )
        for key in ("id", "pattern", "source", "reason"):
            if not isinstance(entry[key], str) or not entry[key]:
                raise HarnessError(f"{where}: '{key}' must be a non-empty string")
        files_any: Any = entry["files"]
        if (
            not isinstance(files_any, list)
            or not files_any
            or not all(isinstance(g, str) and g for g in files_any)  # pyright: ignore[reportUnknownVariableType]
        ):
            raise HarnessError(f"{where}: 'files' must be a non-empty list of glob strings")
        mask_id: str = entry["id"]
        if mask_id in seen:
            raise HarnessError(f"{where}: duplicate id {mask_id!r}")
        seen.add(mask_id)
        try:
            pattern = re.compile(entry["pattern"])
        except re.error as exc:
            raise HarnessError(f"{where} ({mask_id}): bad regex: {exc}") from exc
        masks.append(
            Mask(
                mask_id,
                tuple(str(g) for g in files_any),  # pyright: ignore[reportUnknownArgumentType, reportUnknownVariableType]
                pattern,
                entry["source"],
                entry["reason"],
            )
        )
    return masks


def apply_masks(
    text: str, masks: Sequence[Mask], hits: Counter[str] | None = None
) -> tuple[str, bool]:
    """Mask every line of ``text`` (split on ``\\n`` only); return (masked text, any match)."""
    matched = False
    out_lines: list[str] = []
    for line in text.split("\n"):
        for mask in masks:
            line, count = mask.pattern.subn(f"<MASK:{mask.id}>", line)
            if count:
                matched = True
                if hits is not None:
                    hits[mask.id] += count
        out_lines.append(line)
    return "\n".join(out_lines), matched


# --------------------------------------------------------------------------- comparison


def compared_files(run_dir: Path) -> dict[str, Path]:
    """The files of ``run_dir`` that take part in a comparison, by POSIX relative path."""
    files: dict[str, Path] = {}
    for name in ("stdout.log", "stderr.log"):
        path = run_dir / name
        if path.is_file():
            files[name] = path
    work = run_dir / "work"
    if work.is_dir():
        for path in sorted(work.rglob("*")):
            if path.is_file():
                files[path.relative_to(run_dir).as_posix()] = path
    return files


def _shown(text: str | None) -> str | None:
    if text is None or len(text) <= _MAX_SHOWN:
        return text
    return text[:_MAX_SHOWN] + f"... [{len(text) - _MAX_SHOWN} more chars]"


def _first_difference(rel: str, text_a: str, text_b: str) -> FileDifference | None:
    if text_a == text_b:
        return None
    lines_a, lines_b = text_a.split("\n"), text_b.split("\n")
    for index in range(max(len(lines_a), len(lines_b))):
        a = lines_a[index] if index < len(lines_a) else None
        b = lines_b[index] if index < len(lines_b) else None
        if a != b:
            return FileDifference(rel, index + 1, _shown(a), _shown(b))
    return None  # unreachable: the texts differ


def compare_runs(
    dir_a: Path, dir_b: Path, masks: Sequence[Mask] = (), allow_only_in_b: Sequence[str] = ()
) -> Comparison:
    """Compare two run directories; see the module docstring for the rules."""
    for directory in (dir_a, dir_b):
        if not directory.is_dir():
            raise HarnessError(f"{directory} is not a directory")
    files_a, files_b = compared_files(dir_a), compared_files(dir_b)
    result = Comparison()
    result.only_in_a = sorted(set(files_a) - set(files_b))
    for rel in sorted(set(files_b) - set(files_a)):
        if any(fnmatch.fnmatchcase(rel, glob) for glob in allow_only_in_b):
            result.allowed_only_in_b.append(rel)
        else:
            result.only_in_b.append(rel)
    for rel in sorted(set(files_a) & set(files_b)):
        result.compared += 1
        data_a, data_b = files_a[rel].read_bytes(), files_b[rel].read_bytes()
        applicable = [m for m in masks if m.applies_to(rel)]
        if not applicable:
            if data_a != data_b:
                text_a, text_b = data_a.decode("latin-1"), data_b.decode("latin-1")
                diff = _first_difference(rel, text_a, text_b)
                assert diff is not None
                result.differences.append(diff)
            continue
        masked_a, _ = apply_masks(data_a.decode("latin-1"), applicable, result.mask_hits)
        masked_b, _ = apply_masks(data_b.decode("latin-1"), applicable, result.mask_hits)
        diff = _first_difference(rel, masked_a, masked_b)
        if diff is not None:
            result.differences.append(diff)
    result.unused_masks = [m.id for m in masks if result.mask_hits[m.id] == 0]
    return result


def format_report(result: Comparison, dir_a: Path, dir_b: Path) -> str:
    """Human-readable report of a ``Comparison``."""
    lines: list[str] = [f"A: {dir_a}", f"B: {dir_b}"]
    for rel in result.only_in_a:
        lines.append(f"ONLY IN A: {rel}")
    for rel in result.only_in_b:
        lines.append(f"ONLY IN B: {rel}")
    for rel in result.allowed_only_in_b:
        lines.append(f"ALLOWED ONLY IN B: {rel}")
    for diff in result.differences:
        lines.append(f"DIFFERS: {diff.path}: first difference at line {diff.line}")
        lines.append(f"  A: {'<end of file>' if diff.a is None else diff.a}")
        lines.append(f"  B: {'<end of file>' if diff.b is None else diff.b}")
    if result.mask_hits:
        hits = ", ".join(f"{k}={v}" for k, v in sorted(result.mask_hits.items()))
        lines.append(f"mask matches (both sides): {hits}")
    if result.unused_masks:
        lines.append(f"unused masks (matched nothing): {', '.join(result.unused_masks)}")
    verdict = "IDENTICAL" if result.identical else "DIFFERENT"
    lines.append(
        f"{verdict}: {result.compared} files compared, {len(result.differences)} differ, "
        f"{len(result.only_in_a)} only in A, {len(result.only_in_b)} only in B, "
        f"{len(result.allowed_only_in_b)} allowed only in B"
    )
    return "\n".join(lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m harness.compare_runs",
        description="Compare two run directories byte for byte, with documented masks.",
    )
    parser.add_argument("dir_a", type=Path)
    parser.add_argument("dir_b", type=Path)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--masks", type=Path, help=f"masks file (default {MASKS_FILE.name})")
    group.add_argument("--no-masks", action="store_true", help="compare without any masks")
    parser.add_argument(
        "--allow-only-in-b",
        action="append",
        default=[],
        metavar="GLOB",
        help="accept files matching GLOB that exist only in B (repeatable)",
    )
    args = parser.parse_args(argv)
    try:
        masks: list[Mask] = []
        if not args.no_masks:
            masks_path: Path = args.masks if args.masks is not None else MASKS_FILE
            if args.masks is not None or masks_path.is_file():
                masks = load_masks(masks_path)
            else:
                print(f"note: {masks_path} does not exist; comparing without masks")
        allowed: list[str] = args.allow_only_in_b
        result = compare_runs(args.dir_a, args.dir_b, masks, allowed)
    except HarnessError as exc:
        print(f"harness.compare_runs: {exc}", file=sys.stderr)
        return 2
    print(format_report(result, args.dir_a, args.dir_b))
    return 0 if result.identical else 1


if __name__ == "__main__":
    sys.exit(main())
