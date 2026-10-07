# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Synthetic ensembles for the statistics tests: known distributions, no GEF files.

A synthetic run is a ``dict[Key, Value]`` per file. ``draw_run`` mimics the structure of the real
observables: count histograms (multinomial/Poisson counts times a quantum) with a per-run common
mode (the shared pre-pass), a few scalar Gaussian families, deterministic headers and a
stochastic text field. ``MemoryExtract`` serves such a run as a ``RunExtract`` without disk IO.
"""

from __future__ import annotations

import math
from pathlib import Path
from typing import Any

import numpy as np

from compare.extract import ExtractWriter, FileData, RunExtract, pack_pairs
from compare.model import Key, Value

SHA = "a" * 64
DMP = "work/dmp/Z1_A1_n_E1MeV/Syn.dmp"
OUT = "work/out/Syn.dat"

type Files = dict[str, dict[Key, Value]]


def count_profile(n_bins: int, total: float = 20000.0) -> np.ndarray[Any, np.dtype[np.float64]]:
    """Expected counts per bin: a smooth peak with a long low tail."""
    x = np.arange(n_bins)
    shape = np.exp(-0.5 * ((x - n_bins / 2) / (n_bins / 8)) ** 2) + 0.002
    return total * shape / shape.sum()


def draw_run(
    rng: np.random.Generator,
    *,
    n_count: int = 8,
    n_scalar: int = 3,
    n_bins: int = 80,
    common_mode: float = 0.02,
    seed: int = 0,
) -> Files:
    """One synthetic run: count families ``B<i>`` in a dmp file, scalar families ``S<i>`` in an
    out file, deterministic headers, one stochastic text key."""
    quantum = 1e-4
    dmp: dict[Key, Value] = {}
    eta = 1.0 + common_mode * rng.standard_normal()
    for i in range(n_count):
        counts = rng.poisson(count_profile(n_bins, 20000.0 * (1 + i)) * eta)
        block = f"B{i}"
        for b, c in enumerate(counts.tolist()):
            if c:  # a dmp trims empty bins; zero-fill makes absent keys zero
                dmp[Key(DMP, block, "#1", "y", (b,))] = c * quantum
        dmp[Key(DMP, block, "#1", "events", ())] = 100000
        dmp[Key(DMP, block, "#1", "title", ())] = f"histogram {i}"
        dmp[Key(DMP, block, "#1", "comment", (0,))] = f"seed {seed}"
    out: dict[Key, Value] = {}
    for j in range(n_scalar):
        for f in range(4):
            out[Key(OUT, f"S{j}", "run1/1#1", "x", (f,))] = float(
                10 + 3 * f + rng.standard_normal()
            )
        out[Key(OUT, f"S{j}", "run1/1#1", "barrier", ())] = 5.25 + j
    return {DMP: dmp, OUT: out}


class MemoryExtract(RunExtract):
    """A ``RunExtract`` held in memory (no directory), for fast statistical tests."""

    def __init__(self, files: Files, input_sha256: str | None = SHA, name: str = "memory") -> None:
        packed = {rel: pack_pairs(table.items()) for rel, table in files.items()}
        manifest: dict[str, Any] = {
            "kind": "extract",
            "files": [{"rel": rel, "unparsed": False} for rel in files],
            "input_sha256": input_sha256,
            "source": name,
        }
        super().__init__(Path(name), manifest)
        self._data = {rel: FileData(rel, p.layout, p.vals, p.tvals) for rel, p in packed.items()}

    def file(self, rel: str) -> FileData | None:
        return self._data.get(rel)


def write_extract(
    root: Path, files: Files, pool: Path, input_sha256: str | None = SHA, seed: int = 0
) -> Path:
    """Write ``files`` as an extract directory (what ``compare.extract`` would produce)."""
    root.mkdir(parents=True)
    writer = ExtractWriter(root, pool)
    for rel, table in files.items():
        writer.add_file(rel, pack_pairs(table.items()))
    writer.finish({"source": str(root), "input_sha256": input_sha256, "seed": seed,
                   "fingerprint": f"synthetic-{root.name}"})  # fmt: skip
    return root


def binom_interval(n: int, p: float, tail: float = 0.005) -> tuple[int, int]:
    """Interval ``[lo, hi]`` of Binomial(n, p) with at most ``tail`` mass beyond each end."""
    log = math.log
    pmf = [
        math.exp(
            math.lgamma(n + 1) - math.lgamma(k + 1) - math.lgamma(n - k + 1)
            + k * log(p) + (n - k) * log(1 - p)
        )
        for k in range(n + 1)
    ]  # fmt: skip
    lo = 0
    acc = 0.0
    while lo <= n and acc + pmf[lo] <= tail:
        acc += pmf[lo]
        lo += 1
    hi = n
    acc = 0.0
    while hi >= 0 and acc + pmf[hi] <= tail:
        acc += pmf[hi]
        hi -= 1
    return lo, hi
