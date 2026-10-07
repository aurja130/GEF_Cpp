# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Locate and identify the pinned FreeBASIC compiler (fbc 1.10.1).

fbc is not vendored. It is found through the ``GEF_FBC`` environment variable,
falling back to ``DEFAULT_FBC``. Every tool that runs fbc goes through
``resolve_fbc`` so the pin is enforced in one place.
"""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GEF_SOURCE_DIR = REPO_ROOT / "Reference" / "GEF_code" / "source"

FBC_ENV_VAR = "GEF_FBC"
REQUIRED_FBC_VERSION = "1.10.1"
DEFAULT_FBC_DIST_DIR = Path.home() / "Downloads" / "FreeBASIC-1.10.1-linux-x86_64"
DEFAULT_FBC = DEFAULT_FBC_DIST_DIR / "bin" / "fbc"
FBC_TARBALL_NAME = "FreeBASIC-1.10.1-linux-x86_64.tar.gz"
FBC_TARBALL_SHA256 = "844aa9e997f9ff93566a28f05c502cf24f5aefefc64c4aca0e7a304994f508bc"

# The prebuilt fbc links against an older ncurses; the dynamic loader prints
# these lines on stderr on every invocation. They are harmless.
_HARMLESS_FBC_STDERR = (
    re.compile(r"libtinfo\.so\.\d+: no version information available"),
    re.compile(r"Symbol `ospeed' has different size in shared object"),
)

_VERSION_RE = re.compile(r"FreeBASIC Compiler - Version (\S+)")


class FbcError(RuntimeError):
    """fbc is missing, not executable, or not the pinned version."""


def is_harmless_fbc_stderr_line(line: str) -> bool:
    """True for the known ``libtinfo``/``ospeed`` loader warnings."""
    return any(p.search(line) for p in _HARMLESS_FBC_STDERR)


def filter_fbc_stderr(text: str) -> str:
    """Drop the known harmless loader warnings from fbc's stderr."""
    return "\n".join(ln for ln in text.splitlines() if not is_harmless_fbc_stderr_line(ln))


def fbc_candidate() -> tuple[Path, str]:
    """The fbc path to use and where it came from (``GEF_FBC`` or ``default``)."""
    env = os.environ.get(FBC_ENV_VAR)
    if env:
        return Path(env).expanduser(), FBC_ENV_VAR
    return DEFAULT_FBC, "default"


def fbc_version(fbc: Path) -> str:
    """Run ``fbc -version`` and return the reported version string."""
    try:
        proc = subprocess.run(
            [str(fbc), "-version"], capture_output=True, text=True, check=False, timeout=60
        )
    except OSError as exc:
        raise FbcError(f"cannot run fbc at {fbc}: {exc}") from exc
    match = _VERSION_RE.search(proc.stdout)
    if proc.returncode != 0 or match is None:
        detail = filter_fbc_stderr(proc.stderr).strip() or proc.stdout.strip()
        raise FbcError(f"{fbc} -version did not report a FreeBASIC version: {detail!r}")
    return match.group(1)


def resolve_fbc() -> Path:
    """Return the pinned fbc, or raise ``FbcError`` with an actionable message."""
    fbc, origin = fbc_candidate()
    hint = f"set {FBC_ENV_VAR} to the fbc {REQUIRED_FBC_VERSION} executable"
    if not fbc.is_file():
        raise FbcError(f"fbc not found at {fbc} (from {origin}); {hint}")
    if not os.access(fbc, os.X_OK):
        raise FbcError(f"fbc at {fbc} (from {origin}) is not executable; {hint}")
    version = fbc_version(fbc)
    if version != REQUIRED_FBC_VERSION:
        raise FbcError(
            f"fbc at {fbc} (from {origin}) reports version {version}, "
            f"but {REQUIRED_FBC_VERSION} is required; {hint}"
        )
    return fbc


def fbc_tarball(fbc: Path) -> Path:
    """Where the distribution tarball is expected: next to the unpacked distribution."""
    dist_dir = fbc.resolve().parent.parent
    return dist_dir.parent / FBC_TARBALL_NAME
