# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Reader for the argument logs of the harness patch ``arglog`` (M5.1, ``harness/ARGLOG.md``).

Usage::

    python3 -m harness.arglog summary <probes/arglog dir | file.txt> [--json]
    python3 -m harness.arglog replay-check <probes/arglog dir> <driver replay dir>

``summary`` prints, per log file, the number of calls (from ``_counts.txt``), the number of
logged records, the call sites and, per field, the range of the decoded values (NaNs counted
apart). M5.2 uses it to set the driver grids. ``replay-check`` compares the replays an M5
driver wrote (``replay/<name>.txt``, one ``<seq> <tokens>`` line per logged record) with the
logs: every token must be identical.
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys
from collections import Counter
from collections.abc import Iterator
from dataclasses import asdict, dataclass
from pathlib import Path

from harness.common import HarnessError

COUNTS_FILE = "_counts.txt"
SCHEMA_PREFIX = "# arglog 1 "
FIELD_TYPES = ("f32", "f64", "i64", "u8", "str", "f32[]", "f32hash")
_HEX_WIDTH = {"f32": 8, "f64": 16, "i64": 16, "u8": 2, "f32hash": 16}

Value = float | int | bytes | tuple[float, ...]


@dataclass(frozen=True)
class Field:
    name: str
    type: str


@dataclass(frozen=True)
class Record:
    """One logged call: its number among all calls, the harness scope, the call site, values."""

    seq: int
    step: int
    pass_: int
    event: int
    file: str
    line: int
    tokens: tuple[str, ...]

    @property
    def site(self) -> str:
        return f"{self.file}:{self.line}"


@dataclass(frozen=True)
class ArglogFile:
    name: str
    fields: tuple[Field, ...]
    records: tuple[Record, ...]

    def index(self, field: str) -> int:
        for i, f in enumerate(self.fields):
            if f.name == field:
                return i
        raise HarnessError(f"{self.name}: no field {field!r}")

    def values(self, field: str) -> Iterator[Value]:
        i = self.index(field)
        typ = self.fields[i].type
        for r in self.records:
            yield decode(typ, r.tokens[i])


@dataclass(frozen=True)
class CallCount:
    calls: int
    max: int
    spread: int


def _check_hex(typ: str, token: str) -> int:
    width = _HEX_WIDTH[typ]
    if len(token) != width or any(c not in "0123456789abcdef" for c in token):
        raise HarnessError(f"bad {typ} token {token!r}")
    return int(token, 16)


def decode(typ: str, token: str) -> Value:
    """The value a token stands for (Singles and Doubles exactly, integers signed)."""
    if typ == "f32":
        return struct.unpack("<f", struct.pack("<I", _check_hex(typ, token)))[0]
    if typ == "f64":
        return struct.unpack("<d", struct.pack("<Q", _check_hex(typ, token)))[0]
    if typ == "i64":
        v = _check_hex(typ, token)
        return v - (1 << 64) if v >= 1 << 63 else v
    if typ in ("u8", "f32hash"):
        return _check_hex(typ, token)
    if typ == "str":
        if token == "-":
            return b""
        if len(token) % 2 != 0:
            raise HarnessError(f"bad str token {token!r}")
        return bytes.fromhex(token)
    if typ == "f32[]":
        count, _, rest = token.partition(":")
        if not count.isdigit():
            raise HarnessError(f"bad f32[] token {token!r}")
        items = rest.split(",") if rest else []
        if len(items) != int(count):
            raise HarnessError(f"f32[] token {token!r}: count {count}, {len(items)} values")
        return tuple(float(decode("f32", t)) for t in items)  # type: ignore[arg-type]
    raise HarnessError(f"unknown field type {typ!r}")


def parse_header(line: str) -> tuple[str, tuple[Field, ...]]:
    if not line.startswith(SCHEMA_PREFIX):
        raise HarnessError(f"not an arglog header: {line!r}")
    parts = line[len(SCHEMA_PREFIX) :].split()
    if not parts:
        raise HarnessError("arglog header without a name")
    fields: list[Field] = []
    for spec in parts[1:]:
        name, sep, typ = spec.rpartition(":")
        if not sep or typ not in FIELD_TYPES:
            raise HarnessError(f"bad field spec {spec!r}")
        fields.append(Field(name, typ))
    return parts[0], tuple(fields)


def parse_record(line: str, n_fields: int) -> Record:
    parts = line.split(" ")
    if len(parts) != 5 + n_fields:
        raise HarnessError(f"expected {5 + n_fields} fields, got {len(parts)}: {line[:120]!r}")
    file, sep, lineno = parts[4].rpartition(":")
    if not sep:
        raise HarnessError(f"bad call site {parts[4]!r}")
    try:
        seq, step, pass_, event, ln = (int(x) for x in (*parts[:4], lineno))
    except ValueError as exc:
        raise HarnessError(f"bad record prefix: {line[:120]!r}") from exc
    return Record(seq, step, pass_, event, file, ln, tuple(parts[5:]))


def read_arglog(path: Path) -> ArglogFile:
    with path.open(encoding="ascii") as fh:
        header = fh.readline().rstrip("\n")
        name, fields = parse_header(header)
        records: list[Record] = []
        last = 0
        for no, raw in enumerate(fh, start=2):
            rec = parse_record(raw.rstrip("\n"), len(fields))
            if rec.seq <= last:
                raise HarnessError(f"{path}:{no}: sequence {rec.seq} after {last}")
            last = rec.seq
            for f, tok in zip(fields, rec.tokens, strict=True):
                decode(f.type, tok)
            records.append(rec)
    return ArglogFile(name, fields, tuple(records))


def read_counts(path: Path) -> dict[str, CallCount]:
    lines = path.read_text(encoding="ascii").splitlines()
    if not lines or not lines[0].startswith(SCHEMA_PREFIX + "_counts"):
        raise HarnessError(f"{path}: not an arglog counts file")
    out: dict[str, CallCount] = {}
    for line in lines[1:]:
        name, calls, mx, spread = line.split()
        out[name] = CallCount(int(calls), int(mx), int(spread))
    return out


def is_logged(n: int, k: int, spread: int) -> bool:
    """Whether call ``n`` (1-based) is logged: the patch's ``HL_Next`` rule (ARGLOG.md)."""
    if n <= k:
        return True
    if spread == 0 or k == 0:
        return False
    stride, limit = 1, k
    while n > limit:
        stride *= 2
        limit *= 2
    return n % stride == 0


def logged_calls(calls: int, k: int, spread: int) -> Iterator[int]:
    """The call numbers ``1..calls`` the patch logs, in order."""
    n = 1
    stride, limit = 1, k
    while n <= calls:
        if n > limit:
            if spread == 0 or k == 0:
                return
            stride *= 2
            limit *= 2
        if n % stride == 0:
            yield n
        n += 1
        if n <= limit and stride > 1 and n % stride != 0:
            n += stride - n % stride


def _range(values: list[Value]) -> dict[str, object]:
    nums = [v for v in values if isinstance(v, (int, float))]
    lists = [v for v in values if isinstance(v, tuple)]
    if lists:
        lengths = [len(v) for v in lists]
        nums = [x for v in lists for x in v]
        extra: dict[str, object] = {"min_len": min(lengths), "max_len": max(lengths)}
    else:
        extra = {}
    if not nums:
        if values and isinstance(values[0], bytes):
            distinct = Counter(v for v in values if isinstance(v, bytes))
            return {"distinct": len(distinct)}
        return extra
    nan = sum(1 for v in nums if isinstance(v, float) and math.isnan(v))
    finite = [v for v in nums if not (isinstance(v, float) and math.isnan(v))]
    if finite:
        extra |= {"min": min(finite), "max": max(finite)}
    if nan:
        extra["nan"] = nan
    return extra


@dataclass(frozen=True)
class FileSummary:
    calls: int | None
    records: int
    complete: bool | None  # records are exactly the calls the sampling rule logs
    sites: dict[str, int]
    fields: dict[str, dict[str, object]]


def summarize(path: Path) -> dict[str, FileSummary]:
    if path.is_dir():
        files = sorted(p for p in path.glob("*.txt") if p.name != COUNTS_FILE)
    else:
        files = [path]
    counts_path = (path if path.is_dir() else path.parent) / COUNTS_FILE
    counts = read_counts(counts_path) if counts_path.is_file() else {}
    out: dict[str, FileSummary] = {}
    for p in files:
        log = read_arglog(p)
        fields: dict[str, dict[str, object]] = {}
        for i, f in enumerate(log.fields):
            if f.type == "f32hash":
                continue
            fields[f.name] = _range([decode(f.type, r.tokens[i]) for r in log.records])
        c = counts.get(log.name)
        complete = None
        if c is not None:
            seqs = [r.seq for r in log.records]
            complete = seqs == list(logged_calls(c.calls, c.max, c.spread))
        out[log.name] = FileSummary(
            c.calls if c else None,
            len(log.records),
            complete,
            dict(Counter(r.site for r in log.records).most_common()),
            fields,
        )
    for name, c in counts.items() if path.is_dir() else ():
        if name not in out:
            out[name] = FileSummary(c.calls, 0, c.calls == 0, {}, {})
    return out


@dataclass(frozen=True)
class ReplayResult:
    name: str
    records: int
    mismatches: int
    first: str | None  # description of the first mismatch


def replay_check(log_path: Path, replay_path: Path) -> ReplayResult:
    """Compare a driver replay (``<seq> <tokens>`` per record) with the logged records.

    Every logged record must appear, in order, with exactly the logged tokens.
    """
    log = read_arglog(log_path)
    lines = replay_path.read_text(encoding="ascii").splitlines()
    if len(lines) != len(log.records):
        return ReplayResult(
            log.name,
            len(log.records),
            abs(len(lines) - len(log.records)),
            f"{len(lines)} replay lines for {len(log.records)} records",
        )
    mismatches = 0
    first: str | None = None
    for rec, line in zip(log.records, lines, strict=True):
        seq, _, rest = line.partition(" ")
        got = tuple(rest.split(" "))
        if seq != str(rec.seq) or got != rec.tokens:
            mismatches += 1
            if first is None:
                diffs = [
                    f"{f.name}: log {a} replay {b}"
                    for f, a, b in zip(log.fields, rec.tokens, got, strict=False)
                    if a != b
                ]
                first = f"seq {rec.seq} (replay {seq}) at {rec.site}: " + "; ".join(diffs)
    return ReplayResult(log.name, len(log.records), mismatches, first)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python3 -m harness.arglog", description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p_sum = sub.add_parser("summary", help="calls, records, sites and value ranges")
    p_sum.add_argument("path", type=Path)
    p_sum.add_argument("--json", action="store_true")
    p_rep = sub.add_parser("replay-check", help="compare driver replays with the logs")
    p_rep.add_argument("arglog_dir", type=Path)
    p_rep.add_argument("replay_dir", type=Path)
    ns = parser.parse_args(argv)
    if ns.cmd == "replay-check":
        return _replay_main(ns.arglog_dir, ns.replay_dir)
    path: Path = ns.path
    try:
        result = summarize(path)
    except (HarnessError, OSError) as exc:
        print(f"harness.arglog: {exc}", file=sys.stderr)
        return 2
    if ns.json:
        print(json.dumps({k: asdict(v) for k, v in result.items()}, indent=2, sort_keys=True))
        return 0
    for name, info in sorted(result.items()):
        print(f"{name}: calls={info.calls} records={info.records} complete={info.complete}")
        print("  sites: " + ", ".join(f"{s} x{n}" for s, n in list(info.sites.items())[:8]))
        for fname, rng in info.fields.items():
            print(f"  {fname}: {rng}")
    return 0


def _replay_main(arglog_dir: Path, replay_dir: Path) -> int:
    """Exit 0 if every replay file matches its log, 1 otherwise."""
    try:
        replays = sorted(replay_dir.glob("*.txt"))
        if not replays:
            print(f"harness.arglog: no replay files in {replay_dir}", file=sys.stderr)
            return 2
        bad = 0
        for rp in replays:
            res = replay_check(arglog_dir / rp.name, rp)
            status = "OK" if res.mismatches == 0 else "MISMATCH"
            print(f"{status} {res.name}: {res.records} records, {res.mismatches} mismatches")
            if res.first is not None:
                print(f"  first: {res.first}")
                bad += 1
    except (HarnessError, OSError) as exc:
        print(f"harness.arglog: {exc}", file=sys.stderr)
        return 2
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
