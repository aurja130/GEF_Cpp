# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Paths, errors and small helpers shared by every harness module."""

from __future__ import annotations

import json
from pathlib import Path

from tools.fbsrc.common import sha256_file
from tools.toolchain.fbc import GEF_SOURCE_DIR, REPO_ROOT

__all__ = [
    "BUILD_ROOT",
    "DRIVERS_DIR",
    "GEF_REFERENCE",
    "GEF_SOURCE_DIR",
    "HARNESS_DIR",
    "INPUTS_DIR",
    "MANIFEST_STORE_DIR",
    "MASKS_FILE",
    "PATCHES_DIR",
    "PATCHSETS_DIR",
    "REPO_ROOT",
    "STORE_BINARIES",
    "STORE_CAPTURES",
    "STORE_ROOT",
    "HarnessError",
    "sha256_file",
    "write_json",
]

HARNESS_DIR = REPO_ROOT / "harness"
PATCHES_DIR = HARNESS_DIR / "patches"
PATCHSETS_DIR = HARNESS_DIR / "patchsets"
DRIVERS_DIR = HARNESS_DIR / "drivers"
INPUTS_DIR = HARNESS_DIR / "inputs"
MASKS_FILE = HARNESS_DIR / "masks.toml"

# Disposable build products (gitignored).
BUILD_ROOT = REPO_ROOT / "build" / "harness"

# Immutable reference store (gitignored) and its committed manifests.
STORE_ROOT = REPO_ROOT / "validation" / "reference_store"
STORE_CAPTURES = STORE_ROOT / "captures"
STORE_BINARIES = STORE_ROOT / "binaries"
MANIFEST_STORE_DIR = REPO_ROOT / "manifests" / "reference_store"

# The original clock-seeded BASIC binary (recorded evidence, verified by
# manifests/validation_test_run.sha256).
GEF_REFERENCE = REPO_ROOT / "validation" / "test_run" / "gef_reference"


class HarnessError(RuntimeError):
    """A harness operation cannot proceed; the message says why and what to do."""


def write_json(path: Path, data: object) -> None:
    """Write ``data`` as deterministic JSON (sorted keys, 2-space indent, final newline)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
