# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Helpers shared by ``emit_c``, ``fbline`` and ``fbdef``."""

from __future__ import annotations

import hashlib
from pathlib import Path

from tools.toolchain.fbc import GEF_SOURCE_DIR, REPO_ROOT

FBSRC_BUILD_DIR = REPO_ROOT / "build" / "fbsrc"
BASIC_SUFFIXES = (".bas", ".bi", ".mac")


class FbsrcError(RuntimeError):
    """A user-facing failure of one of the fbsrc tools; the message says what to do."""


def sha256_file(path: Path) -> str:
    """Streamed SHA-256 of a file, as lowercase hex."""
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def display_path(path: Path) -> str:
    """``path`` relative to the repository root when it lies inside it."""
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def basic_source_files(source_dir: Path = GEF_SOURCE_DIR) -> list[Path]:
    """All ``.bas``/``.bi``/``.mac`` files directly in ``source_dir``, sorted by name."""
    return sorted(
        p for p in source_dir.iterdir() if p.is_file() and p.suffix.lower() in BASIC_SUFFIXES
    )


def read_source_lines(path: Path) -> list[str]:
    """The lines of a BASIC source file; index 0 is line 1.

    Splits on ``\\n`` only (``str.splitlines`` would also split on form feeds and
    other separators and shift line numbers away from fbc's). Undecodable bytes are
    replaced, a trailing ``\\r`` is dropped.
    """
    text = path.read_bytes().decode("utf-8", errors="replace")
    lines = [line.removesuffix("\r") for line in text.split("\n")]
    if lines and lines[-1] == "":
        lines.pop()
    return lines


def resolve_source_name(name: str, source_dir: Path) -> str:
    """The on-disk spelling of source file ``name`` in ``source_dir`` (case-insensitive)."""
    if (source_dir / name).is_file():
        return name
    matches = [p.name for p in source_dir.iterdir() if p.name.lower() == name.lower()]
    if len(matches) == 1:
        return matches[0]
    if matches:
        raise FbsrcError(f"{name!r} is ambiguous in {display_path(source_dir)}: {matches}")
    raise FbsrcError(f"no source file {name!r} in {display_path(source_dir)}")
