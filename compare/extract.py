# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Compact, cached per-run representation of a run's observables (STATISTICS.md §7).

    python3 -m compare.extract RUN [RUN ...] [--cache DIR] [--jobs N] [--force]

A run directory (or a store capture id) becomes an *extract*: a directory with

``manifest.json``
    Source path, fingerprint, input sha256, per-file entries, totals, timings.
``layouts/<sha>.json``, ``<sha>.k.npy``, ``<sha>.t.npy``
    Per source file: the families with their interned label tables (json) and the numeric and text
    key matrices (npy, memory-mapped). Content addressed: runs of one input share identical
    layouts, which are stored once in the cache pool ``<cache>/layouts`` and hard-linked into
    every extract.
``vals/<i>.npy``
    Per source file: the float64 values of all numeric keys, family after family (memory-mapped
    on read).
``text/<i>.json``
    Per source file: the text values, in layout order (only files that have text keys).

Families are ``(file, block, group)`` as in ``Key.family``. Inside a family the numeric keys are
sorted by ``(label, index)``. A key is a row ``[label id, index_0, ..., index_{w-1}]`` of int64
(``PAD`` fills short indices); label ids index the family's sorted label table. Integers beyond
2**53 do not fit a float64 exactly and are kept as text keys instead.

Nothing holds a whole run: files are streamed from the parsers into per-family arrays and written
one file at a time, so memory is bounded by the largest single file.

The cache directory ``<cache>/runs/<fingerprint>`` is keyed by the size and mtime of every file of
the run plus the content of the parser and extractor sources, so a changed run or parser
invalidates it.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import resource
import shutil
import sys
import time
from array import array
from collections.abc import Iterable, Iterator, Mapping, Sequence
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any

import numpy as np
from numpy.typing import NDArray

from compare.loader import parser_modules, run_files, stream_file
from compare.model import Family, Key, Value
from harness.common import REPO_ROOT, STORE_CAPTURES

__all__ = [
    "DEFAULT_CACHE",
    "EXTRACT_VERSION",
    "PAD",
    "Aligned",
    "FamilyData",
    "FamilyLayout",
    "FileData",
    "FileLayout",
    "PackedFile",
    "RunExtract",
    "align_numeric",
    "build_layout",
    "extract_run",
    "key_label",
    "load_extract",
    "load_layout",
    "match_rows",
    "pack_pairs",
    "read_layout_npz",
    "resolve_run",
    "run_fingerprint",
    "text_map",
    "unique_rows",
    "write_layout_files",
    "write_layout_npz",
]

EXTRACT_VERSION = 2
DEFAULT_CACHE = REPO_ROOT / "build" / "compare" / "extract"
PAD = int(np.iinfo(np.int64).min)
_MAX_EXACT_INT = 2**53
_COMPARE_DIR = Path(__file__).resolve().parent

type IntArray = NDArray[np.int64]
type FloatArray = NDArray[np.float64]


# --------------------------------------------------------------------------------------------
# Layout
# --------------------------------------------------------------------------------------------


@dataclass(frozen=True)
class FamilyLayout:
    """One family inside a file: label tables, row counts and offsets into the flat arrays."""

    block: str
    group: str
    labels: tuple[str, ...]
    n: int
    width: int
    tlabels: tuple[str, ...]
    nt: int
    twidth: int
    kpos: int  # element offset of the numeric key rows in ``FileLayout.kmat``
    voff: int  # row offset in the value array
    tkpos: int  # element offset of the text key rows in ``FileLayout.tkmat``
    toff: int  # row offset in the text value list


@dataclass
class FileLayout:
    """The key structure of one source file."""

    sha: str
    families: tuple[FamilyLayout, ...]
    kmat: IntArray
    tkmat: IntArray
    index: dict[tuple[str, str], int]

    @property
    def nnum(self) -> int:
        return sum(f.n for f in self.families)

    @property
    def ntext(self) -> int:
        return sum(f.nt for f in self.families)


def build_layout(
    specs: Sequence[tuple[str, str, tuple[str, ...], int, int, tuple[str, ...], int, int]],
    kmat: IntArray,
    tkmat: IntArray,
    sha: str | None = None,
) -> FileLayout:
    """The layout of packed key matrices; ``sha`` (the content hash) is computed unless given."""
    families: list[FamilyLayout] = []
    kpos = voff = tkpos = toff = 0
    for block, group, labels, n, width, tlabels, nt, twidth in specs:
        families.append(
            FamilyLayout(
                block, group, labels, n, width, tlabels, nt, twidth, kpos, voff, tkpos, toff
            )
        )
        kpos += n * (1 + width)
        voff += n
        tkpos += nt * (1 + twidth)
        toff += nt
    if sha is None:
        meta = json.dumps([list(s) for s in specs], separators=(",", ":")).encode()
        digest = hashlib.sha256(meta)
        digest.update(kmat.tobytes())
        digest.update(tkmat.tobytes())
        sha = digest.hexdigest()[:24]
    index = {(f.block, f.group): i for i, f in enumerate(families)}
    return FileLayout(sha, tuple(families), kmat, tkmat, index)


def write_layout_npz(
    path: Path, layout: FileLayout, extra: Mapping[str, NDArray[Any]] | None = None
) -> None:
    """Write a layout (and optional extra arrays, e.g. calibration fits) as one compressed npz."""
    specs = [
        [f.block, f.group, list(f.labels), f.n, f.width, list(f.tlabels), f.nt, f.twidth]
        for f in layout.families
    ]
    tmp = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    arrays: dict[str, Any] = {
        "meta": np.array(json.dumps(specs)),
        "kmat": layout.kmat,
        "tkmat": layout.tkmat,
        **(extra or {}),
    }
    with tmp.open("wb") as handle:
        np.savez_compressed(handle, **arrays)
    tmp.replace(path)


def read_layout_npz(path: Path, sha: str | None = None) -> tuple[FileLayout, dict[str, Any]]:
    """Read ``write_layout_npz``; ``sha`` (if given) is checked against the layout content."""
    extra: dict[str, Any] = {}
    with np.load(path) as z:
        specs: list[list[Any]] = json.loads(str(z["meta"]))
        kmat = np.asarray(z["kmat"], dtype=np.int64)
        tkmat = np.asarray(z["tkmat"], dtype=np.int64)
        for name in z.files:
            if name not in ("meta", "kmat", "tkmat"):
                extra[name] = np.asarray(z[name])
    parsed = [
        (s[0], s[1], tuple(s[2]), int(s[3]), int(s[4]), tuple(s[5]), int(s[6]), int(s[7]))
        for s in specs
    ]
    layout = build_layout(parsed, kmat, tkmat)
    if sha is not None and layout.sha != sha:
        raise ValueError(f"layout {path} is corrupt: content hash {layout.sha} != {sha}")
    return layout, extra


_LAYOUT_SUFFIXES = (".k.npy", ".t.npy", ".json")  # the json marks a complete layout
_LAYOUT_CACHE: dict[str, FileLayout] = {}
_LAYOUT_CACHE_SIZE = 32


def write_layout_files(directory: Path, layout: FileLayout) -> None:
    """Write a layout as ``<sha>.k.npy``, ``<sha>.t.npy`` (memory-mappable) and ``<sha>.json``."""
    specs = [
        [f.block, f.group, list(f.labels), f.n, f.width, list(f.tlabels), f.nt, f.twidth]
        for f in layout.families
    ]
    stem = directory / layout.sha
    for suffix, matrix in ((".k.npy", layout.kmat), (".t.npy", layout.tkmat)):
        tmp = directory / f".{layout.sha}{suffix}.{os.getpid()}"
        with tmp.open("wb") as handle:
            np.save(handle, np.asarray(matrix))
        tmp.replace(stem.with_name(layout.sha + suffix))
    tmp = directory / f".{layout.sha}.json.{os.getpid()}"
    tmp.write_text(json.dumps(specs, separators=(",", ":")))
    tmp.replace(stem.with_name(layout.sha + ".json"))


def load_layout(directory: Path, sha: str) -> FileLayout:
    """The layout ``<sha>`` of ``directory``; key matrices are memory-mapped, the most recent
    layouts stay open (runs of one input share them)."""
    hit = _LAYOUT_CACHE.get(sha)
    if hit is not None:
        _LAYOUT_CACHE[sha] = _LAYOUT_CACHE.pop(sha)
        return hit
    specs: list[list[Any]] = json.loads((directory / f"{sha}.json").read_text())
    kmat: IntArray = np.load(directory / f"{sha}.k.npy", mmap_mode="r")
    tkmat: IntArray = np.load(directory / f"{sha}.t.npy", mmap_mode="r")
    parsed = [
        (s[0], s[1], tuple(s[2]), int(s[3]), int(s[4]), tuple(s[5]), int(s[6]), int(s[7]))
        for s in specs
    ]
    layout = build_layout(parsed, kmat, tkmat, sha)
    _LAYOUT_CACHE[sha] = layout
    while len(_LAYOUT_CACHE) > _LAYOUT_CACHE_SIZE:
        _LAYOUT_CACHE.pop(next(iter(_LAYOUT_CACHE)))
    return layout


# --------------------------------------------------------------------------------------------
# Packing observables into arrays
# --------------------------------------------------------------------------------------------


class _Acc:
    """Observables of one family, accumulated in compact arrays."""

    __slots__ = ("lid", "nidx", "nlab", "nval", "nwid", "tidx", "tlab", "tlid", "tval", "twid")

    def __init__(self) -> None:
        self.lid: dict[str, int] = {}
        self.nlab = array("q")
        self.nwid = array("q")
        self.nidx = array("q")
        self.nval = array("d")
        self.tlid: dict[str, int] = {}
        self.tlab = array("q")
        self.twid = array("q")
        self.tidx = array("q")
        self.tval: list[str] = []

    def add(self, label: str, index: tuple[int, ...], value: Value) -> None:
        if type(value) is str or (type(value) is int and abs(value) > _MAX_EXACT_INT):
            lid = self.tlid.get(label)
            if lid is None:
                lid = self.tlid[label] = len(self.tlid)
            self.tlab.append(lid)
            self.twid.append(len(index))
            self.tidx.extend(index)
            self.tval.append(value if type(value) is str else str(value))
            return
        lid = self.lid.get(label)
        if lid is None:
            lid = self.lid[label] = len(self.lid)
        self.nlab.append(lid)
        self.nwid.append(len(index))
        self.nidx.extend(index)
        self.nval.append(float(value))


def _finish_keys(
    lid: dict[str, int], lab: array[int], wid: array[int], idx: array[int], what: str
) -> tuple[tuple[str, ...], IntArray, IntArray]:
    """Label table, sorted key matrix and the permutation that sorted the rows."""
    labels = tuple(sorted(lid))
    n = len(lab)
    if n == 0:
        return labels, np.zeros((0, 1), dtype=np.int64), np.zeros(0, dtype=np.int64)
    rank = np.empty(len(lid), dtype=np.int64)
    for pos, name in enumerate(labels):
        rank[lid[name]] = pos
    widths = np.frombuffer(wid, dtype=np.int64)
    maxw = int(widths.max())
    mat = np.full((n, 1 + maxw), PAD, dtype=np.int64)
    mat[:, 0] = rank[np.frombuffer(lab, dtype=np.int64)]
    if maxw:
        flat = np.frombuffer(idx, dtype=np.int64)
        starts = np.cumsum(widths) - widths
        for col in range(maxw):
            mask = widths > col
            mat[mask, 1 + col] = flat[starts[mask] + col]
    order = np.lexsort(mat.T[::-1])
    mat = mat[order]
    if n > 1 and bool(np.any(np.all(mat[1:] == mat[:-1], axis=1))):
        raise ValueError(f"duplicate {what} observable keys in one family")
    return labels, mat, order


@dataclass
class PackedFile:
    """One source file as arrays: the layout, float values and text values."""

    layout: FileLayout
    vals: FloatArray
    tvals: list[str]


def pack_pairs(pairs: Iterable[tuple[Key, Value]]) -> PackedFile:
    """Pack a stream of observables (one file) into a ``PackedFile``."""
    accs: dict[tuple[str, str], _Acc] = {}
    acc: _Acc | None = None
    last: tuple[str, str] | None = None
    for key, value in pairs:
        fam = (key.block, key.group)
        if acc is None or fam != last:
            acc = accs.get(fam)
            if acc is None:
                acc = accs[fam] = _Acc()
            last = fam
        acc.add(key.label, key.index, value)
    specs: list[tuple[str, str, tuple[str, ...], int, int, tuple[str, ...], int, int]] = []
    kparts: list[IntArray] = []
    tkparts: list[IntArray] = []
    vparts: list[FloatArray] = []
    tvals: list[str] = []
    for fam in sorted(accs):
        a = accs[fam]
        labels, kmat, order = _finish_keys(a.lid, a.nlab, a.nwid, a.nidx, "numeric")
        tlabels, tkmat, torder = _finish_keys(a.tlid, a.tlab, a.twid, a.tidx, "text")
        specs.append(
            (fam[0], fam[1], labels, len(kmat), kmat.shape[1] - 1, tlabels, len(tkmat),
             tkmat.shape[1] - 1)
        )  # fmt: skip
        kparts.append(kmat.ravel())
        tkparts.append(tkmat.ravel())
        column: FloatArray = (
            np.frombuffer(a.nval, dtype=np.float64)[order] if len(order) else np.zeros(0)
        )
        vparts.append(column)
        tvals.extend([a.tval[int(i)] for i in torder.tolist()])
    kmat_all = np.concatenate(kparts) if kparts else np.zeros(0, dtype=np.int64)
    tkmat_all = np.concatenate(tkparts) if tkparts else np.zeros(0, dtype=np.int64)
    vals = np.concatenate(vparts) if vparts else np.zeros(0, dtype=np.float64)
    return PackedFile(build_layout(specs, kmat_all, tkmat_all), vals, tvals)


# --------------------------------------------------------------------------------------------
# Reading
# --------------------------------------------------------------------------------------------


@dataclass
class FamilyData:
    """The observables of one family of one run (views into the file arrays)."""

    family: Family
    labels: tuple[str, ...]
    kmat: IntArray  # (n, 1 + width)
    vals: FloatArray  # (n,)
    tlabels: tuple[str, ...]
    tkmat: IntArray  # (nt, 1 + twidth)
    tvals: list[str]


class FileData:
    """One source file of an extract: layout plus value arrays."""

    def __init__(self, rel: str, layout: FileLayout, vals: FloatArray, tvals: list[str]) -> None:
        self.rel = rel
        self.layout = layout
        self.vals = vals
        self.tvals = tvals

    def family_at(self, i: int) -> FamilyData:
        f = self.layout.families[i]
        kn = f.n * (1 + f.width)
        tn = f.nt * (1 + f.twidth)
        return FamilyData(
            Family(self.rel, f.block, f.group),
            f.labels,
            self.layout.kmat[f.kpos : f.kpos + kn].reshape(f.n, 1 + f.width),
            self.vals[f.voff : f.voff + f.n],
            f.tlabels,
            self.layout.tkmat[f.tkpos : f.tkpos + tn].reshape(f.nt, 1 + f.twidth),
            self.tvals[f.toff : f.toff + f.nt],
        )

    def get(self, block: str, group: str) -> FamilyData | None:
        i = self.layout.index.get((block, group))
        return None if i is None else self.family_at(i)

    def __iter__(self) -> Iterator[FamilyData]:
        for i in range(len(self.layout.families)):
            yield self.family_at(i)


class RunExtract:
    """An opened extract directory."""

    def __init__(self, root: Path, manifest: dict[str, Any]) -> None:
        self.root = root
        self.manifest = manifest
        self.entries: dict[str, dict[str, Any]] = {e["rel"]: e for e in manifest["files"]}

    @classmethod
    def open(cls, root: Path) -> RunExtract:
        manifest = json.loads((root / "manifest.json").read_text())
        if manifest.get("kind") != "extract":
            raise ValueError(f"{root} is not an extract directory")
        if manifest.get("version") != EXTRACT_VERSION:
            raise ValueError(f"{root}: extract version {manifest.get('version')} is not current")
        return cls(root, manifest)

    @property
    def input_sha256(self) -> str | None:
        return self.manifest.get("input_sha256")

    @property
    def rels(self) -> list[str]:
        return [e["rel"] for e in self.manifest["files"] if not e.get("unparsed")]

    @property
    def unparsed(self) -> list[str]:
        return [e["rel"] for e in self.manifest["files"] if e.get("unparsed")]

    def file(self, rel: str) -> FileData | None:
        """The data of one parsed file, or ``None`` if the run has no such parsed file."""
        entry = self.entries.get(rel)
        if entry is None or entry.get("unparsed"):
            return None
        layout = load_layout(self.root / "layouts", entry["layout"])
        vals: FloatArray = np.load(self.root / "vals" / f"{entry['idx']}.npy", mmap_mode="r")
        tpath = self.root / "text" / f"{entry['idx']}.json"
        tvals: list[str] = json.loads(tpath.read_text()) if tpath.is_file() else []
        return FileData(rel, layout, vals, tvals)


class ExtractWriter:
    """Write an extract directory file by file."""

    def __init__(self, root: Path, pool: Path) -> None:
        self.root = root
        self.pool = pool
        for sub in ("layouts", "vals", "text"):
            (root / sub).mkdir(parents=True, exist_ok=True)
        pool.mkdir(parents=True, exist_ok=True)
        self.entries: list[dict[str, Any]] = []
        self.observables = 0
        self.bytes = 0

    def add_unparsed(self, rel: str) -> None:
        self.entries.append({"rel": rel, "unparsed": True})

    def add_file(self, rel: str, packed: PackedFile) -> None:
        idx = len(self.entries)
        layout = packed.layout
        if not (self.pool / f"{layout.sha}.json").is_file():
            write_layout_files(self.pool, layout)
        for suffix in _LAYOUT_SUFFIXES:
            link = self.root / "layouts" / f"{layout.sha}{suffix}"
            if not link.exists():
                try:
                    os.link(self.pool / f"{layout.sha}{suffix}", link)
                except OSError:
                    shutil.copy2(self.pool / f"{layout.sha}{suffix}", link)
        np.save(self.root / "vals" / f"{idx}.npy", packed.vals)
        if packed.tvals:
            (self.root / "text" / f"{idx}.json").write_text(json.dumps(packed.tvals))
        nnum, ntext = len(packed.vals), len(packed.tvals)
        self.observables += nnum + ntext
        self.bytes += packed.vals.nbytes
        self.entries.append(
            {"rel": rel, "idx": idx, "layout": layout.sha, "numeric": nnum, "text": ntext}
        )

    def finish(self, meta: dict[str, Any]) -> None:
        manifest: dict[str, Any] = {
            "kind": "extract",
            "version": EXTRACT_VERSION,
            **meta,
            "files": self.entries,
            "observables": self.observables,
            "value_bytes": self.bytes,
        }
        (self.root / "manifest.json").write_text(json.dumps(manifest, indent=1, sort_keys=True))


# --------------------------------------------------------------------------------------------
# Extraction
# --------------------------------------------------------------------------------------------


def resolve_run(spec: str | Path) -> Path:
    """A run directory: an existing path, or a capture id of the reference store."""
    path = Path(spec)
    if path.is_dir():
        return path
    capture = STORE_CAPTURES / str(spec)
    if capture.is_dir():
        return capture
    raise FileNotFoundError(f"{spec} is neither a directory nor a reference-store capture id")


@lru_cache(maxsize=1)
def _code_fingerprint() -> str:
    h = hashlib.sha256()
    sources = [
        _COMPARE_DIR / "extract.py",
        _COMPARE_DIR / "loader.py",
        _COMPARE_DIR / "model.py",
        *sorted((_COMPARE_DIR / "parsers").glob("*.py")),
    ]
    for path in sources:
        h.update(path.name.encode())
        h.update(path.read_bytes())
    return h.hexdigest()


def run_fingerprint(run_dir: Path) -> str:
    """Hash of the run's file listing (relative path, size, mtime) and the extraction code."""
    h = hashlib.sha256()
    h.update(f"extract-v{EXTRACT_VERSION}\0{_code_fingerprint()}\n".encode())
    for rel, path in run_files(run_dir).items():
        st = path.stat()
        h.update(f"{rel}\0{st.st_size}\0{st.st_mtime_ns}\n".encode())
    run_json = run_dir / "run.json"
    if run_json.is_file():
        h.update(run_json.read_bytes())
    return h.hexdigest()


def _run_meta(run_dir: Path) -> dict[str, Any]:
    meta: dict[str, Any] = {"source": str(run_dir), "input_sha256": None, "seed": None}
    run_json = run_dir / "run.json"
    if run_json.is_file():
        info: dict[str, Any] = json.loads(run_json.read_text())
        recorded: dict[str, Any] = info.get("input") or {}
        meta["input_sha256"] = recorded.get("sha256")
        meta["seed"] = info.get("seed")
    return meta


def extract_run(run_dir: Path, cache: Path = DEFAULT_CACHE, *, force: bool = False) -> RunExtract:
    """The extract of ``run_dir``, built (file by file) if not already cached."""
    fingerprint = run_fingerprint(run_dir)
    root = cache / "runs" / fingerprint[:24]
    if (root / "manifest.json").is_file() and not force:
        return RunExtract.open(root)
    tmp = cache / "runs" / f".tmp-{fingerprint[:24]}-{os.getpid()}"
    shutil.rmtree(tmp, ignore_errors=True)
    tmp.mkdir(parents=True)
    start = time.perf_counter()
    writer = ExtractWriter(tmp, cache / "layouts")
    modules = parser_modules()
    for rel, path in run_files(run_dir).items():
        stream = stream_file(path, rel, modules)
        if stream is None:
            writer.add_unparsed(rel)
        else:
            writer.add_file(rel, pack_pairs(stream))
    meta = _run_meta(run_dir)
    meta["fingerprint"] = fingerprint
    meta["extract_seconds"] = round(time.perf_counter() - start, 3)
    writer.finish(meta)
    if force:
        shutil.rmtree(root, ignore_errors=True)
    try:
        tmp.rename(root)
    except OSError:  # another process finished the same run first
        shutil.rmtree(tmp, ignore_errors=True)
    return RunExtract.open(root)


def load_extract(spec: str | Path, cache: Path = DEFAULT_CACHE) -> RunExtract:
    """An extract directory as given, or the (cached) extract of a run directory / capture id."""
    path = Path(spec)
    if (path / "manifest.json").is_file():
        return RunExtract.open(path)
    return extract_run(resolve_run(spec), cache)


# --------------------------------------------------------------------------------------------
# Aligning runs
# --------------------------------------------------------------------------------------------


def unique_rows(mat: IntArray) -> tuple[IntArray, IntArray]:
    """Sorted unique rows of an int matrix and, per input row, the index of its unique row."""
    n = len(mat)
    if n == 0:
        return mat, np.zeros(0, dtype=np.int64)
    order = np.lexsort(mat.T[::-1])
    srt = mat[order]
    first = np.empty(n, dtype=bool)
    first[0] = True
    first[1:] = np.any(srt[1:] != srt[:-1], axis=1)
    group = np.cumsum(first) - 1
    inverse = np.empty(n, dtype=np.int64)
    inverse[order] = group
    return srt[first], inverse


def pad_width(mat: IntArray, width: int) -> IntArray:
    """``mat`` with PAD columns appended up to ``width`` columns."""
    if mat.shape[1] >= width:
        return mat
    out = np.full((len(mat), width), PAD, dtype=np.int64)
    out[:, : mat.shape[1]] = mat
    return out


def remap_labels(
    labels: tuple[str, ...], mat: IntArray, target: tuple[str, ...]
) -> tuple[IntArray, tuple[str, ...]]:
    """Re-express column 0 of ``mat`` in the label table ``target``; unknown labels are appended."""
    if labels == target:
        return mat, target
    table = list(target)
    where = {name: i for i, name in enumerate(table)}
    lookup = np.empty(len(labels), dtype=np.int64)
    for i, name in enumerate(labels):
        pos = where.get(name)
        if pos is None:
            pos = where[name] = len(table)
            table.append(name)
        lookup[i] = pos
    out = mat.copy()
    if len(mat):
        out[:, 0] = lookup[mat[:, 0]]
    return out, tuple(table)


def match_rows(ref: IntArray, mat: IntArray) -> IntArray:
    """Per row of ``mat`` the index of the equal row in ``ref`` (unique rows), or -1."""
    width = max(ref.shape[1], mat.shape[1])
    both = np.concatenate([pad_width(ref, width), pad_width(mat, width)])
    _, inverse = unique_rows(both)
    pos = np.full(int(inverse.max()) + 1 if len(inverse) else 0, -1, dtype=np.int64)
    pos[inverse[: len(ref)]] = np.arange(len(ref), dtype=np.int64)
    return pos[inverse[len(ref) :]]


@dataclass
class Aligned:
    """Numeric fields of several runs on one common key set (absent keys are zero-filled)."""

    labels: tuple[str, ...]
    kmat: IntArray  # (U, 1 + width)
    vals: FloatArray  # (R, U)
    present: NDArray[np.bool_]  # (R, U)


def align_numeric(parts: Sequence[tuple[tuple[str, ...], IntArray, FloatArray]]) -> Aligned:
    """Union the numeric keys of ``parts`` (label table, key matrix, values) of R runs.

    The result's key order is that of the first part when all parts share the same keys (the
    usual case), and the sorted union otherwise.
    """
    labels = tuple(sorted(set[str]().union(*(p[0] for p in parts))))
    width = max((p[1].shape[1] for p in parts), default=1)
    mats = [pad_width(remap_labels(p[0], p[1], labels)[0], width) for p in parts]
    runs = len(parts)
    first = mats[0] if mats else np.zeros((0, width), dtype=np.int64)
    if all(m.shape == first.shape and np.array_equal(m, first) for m in mats[1:]):
        vals = np.stack([p[2] for p in parts]) if parts else np.zeros((0, 0))
        return Aligned(labels, first, vals, np.ones(vals.shape, dtype=bool))
    uniq, inverse = unique_rows(np.concatenate(mats))
    vals = np.zeros((runs, len(uniq)))
    present = np.zeros((runs, len(uniq)), dtype=bool)
    at = 0
    for r, part in enumerate(parts):
        cols = inverse[at : at + len(part[2])]
        vals[r, cols] = part[2]
        present[r, cols] = True
        at += len(part[2])
    return Aligned(labels, uniq, vals, present)


def text_map(
    tlabels: tuple[str, ...], tkmat: IntArray, tvals: Sequence[str]
) -> dict[tuple[str, tuple[int, ...]], str]:
    """Text keys as ``(label, index) -> value``."""
    out: dict[tuple[str, tuple[int, ...]], str] = {}
    for row, value in zip(tkmat.tolist(), tvals, strict=True):
        index = tuple(i for i in row[1:] if i != PAD)
        out[tlabels[row[0]], index] = value
    return out


def key_label(labels: tuple[str, ...], row: Sequence[int]) -> tuple[str, tuple[int, ...]]:
    """``(label, index)`` of one key-matrix row."""
    return labels[row[0]], tuple(i for i in row[1:] if i != PAD)


# --------------------------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------------------------


def _extract_one(job: tuple[str, str, bool]) -> dict[str, Any]:
    spec, cache, force = job
    start = time.perf_counter()
    ex = extract_run(resolve_run(spec), Path(cache), force=force)
    seconds = time.perf_counter() - start
    families = 0
    for rel in ex.rels:
        data = ex.file(rel)
        if data is not None:
            families += len(data.layout.families)
    return {
        "run": spec,
        "extract": str(ex.root),
        "files": len(ex.rels),
        "unparsed": len(ex.unparsed),
        "families": families,
        "observables": ex.manifest["observables"],
        "value_mb": round(ex.manifest["value_bytes"] / 1e6, 1),
        "seconds": round(seconds, 2),
        "built_seconds": ex.manifest.get("extract_seconds"),
        "peak_rss_mb": round(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1e3),
    }


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m compare.extract", description=__doc__)
    parser.add_argument("runs", nargs="+", help="run directories or reference-store capture ids")
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument("--jobs", type=int, default=1, help="parallel runs (default 1)")
    parser.add_argument("--force", action="store_true", help="rebuild even if cached")
    parser.add_argument("--json", type=Path, help="write the statistics here")
    args = parser.parse_args(argv)
    jobs = [(spec, str(args.cache), args.force) for spec in args.runs]
    try:
        if args.jobs > 1 and len(jobs) > 1:
            with ProcessPoolExecutor(max_workers=args.jobs) as pool:
                results = list(pool.map(_extract_one, jobs))
        else:
            results = [_extract_one(job) for job in jobs]
    except (OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    for r in results:
        print(
            f"{r['run']}: {r['observables']} observables, {r['families']} families, "
            f"{r['files']} files (+{r['unparsed']} unparsed), values {r['value_mb']} MB, "
            f"{r['seconds']} s, peak RSS {r['peak_rss_mb']} MB -> {r['extract']}"
        )
    if args.json:
        args.json.write_text(json.dumps(results, indent=1, sort_keys=True) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
