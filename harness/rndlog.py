# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Reader for the ``rnd.log`` written by the ``rndlog`` harness patch (M1.8).

The format is described in ``harness/RNDLOG.md``. One line per traced draw::

    <counter> <file>:<line> <u32 hex>

Usage (from the repository root)::

    python3 -m harness.rndlog summary <rnd.log> [--json]
    python3 -m harness.rndlog head <rnd.log> [-n N]
    python3 -m harness.rndlog scopes <rnd.log> [--master SEED] [--streams] [--json]

``summary`` prints the number of records, the counter range, the number of contiguous
segments (a gap means untraced draws in between) and the draw count per site. ``head``
prints the first records with the value ``u32 / 2**32``. A malformed line or a counter that
does not increase is an error (exit status 1, message on stderr); usage errors exit 2.

In reseed mode (``harness/RESEED_SPEC.md``) the log also holds scope markers::

    B <scope> <seed32 hex> <tuple element>...     a scope instance begins (after its reseed)
    E <scope>                                      the scope instance ends

A scope instance covers the draws after its ``B`` and before the next ``B`` or ``E`` line.
``scopes`` reports the draws that are in no scope instance and, with ``--master``, checks the
seeds in the ``B`` lines against ``harness.reseed.derive_seed``; ``--streams`` checks that the
draws of each instance are the output of ``FbMtRng(seed)`` from its start. The record readers
(``parse_lines``, ``read_log``, ``summarize``) ignore marker lines.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from collections.abc import Iterable, Iterator, Sequence
from dataclasses import dataclass, field
from pathlib import Path

from harness.common import HarnessError
from harness.fbmt import FbMtRng
from harness.reseed import SCOPE_NAMES, TUPLE_FIELDS, derive_seed

__all__ = [
    "RndLogError",
    "RndLogSummary",
    "RndRecord",
    "ScopeBegin",
    "ScopeEnd",
    "ScopeReport",
    "analyze_scopes",
    "main",
    "parse_events",
    "parse_line",
    "parse_lines",
    "read_events",
    "read_log",
    "summarize",
]

_LINE_RE = re.compile(r"^(\d+) ([^\s:]+):(\d+) ([0-9a-f]{8})$")
_BEGIN_RE = re.compile(r"^B (\d+) ([0-9a-f]{8})((?: -?\d+)*)$")
_END_RE = re.compile(r"^E (\d+)$")
_TWO_POW_32 = 4294967296.0


class RndLogError(HarnessError):
    """``rnd.log`` content is malformed."""


@dataclass(frozen=True, slots=True)
class RndRecord:
    """One traced draw. ``counter`` is the 1-based index among all draws of the program."""

    counter: int
    file: str
    line: int
    u32: int

    @property
    def site(self) -> str:
        """``<file>:<line>`` of the ``Rnd`` in the original (unpatched) BASIC source."""
        return f"{self.file}:{self.line}"

    @property
    def value(self) -> float:
        """The double ``Rnd`` returned; exact, because ``Rnd = u32 / 2**32``."""
        return self.u32 / _TWO_POW_32


@dataclass(frozen=True, slots=True)
class ScopeBegin:
    """``B`` marker: scope instance ``scope`` starts, reseeded with ``seed``."""

    scope: int
    seed: int
    tuple_values: tuple[int, ...]


@dataclass(frozen=True, slots=True)
class ScopeEnd:
    """``E`` marker: the scope instance of kind ``scope`` ends."""

    scope: int


LogItem = RndRecord | ScopeBegin | ScopeEnd


def parse_line(text: str, lineno: int = 0) -> RndRecord:
    """Parse one log line (without its newline)."""
    match = _LINE_RE.match(text)
    if match is None:
        raise RndLogError(f"rnd.log line {lineno}: malformed record {text!r}")
    counter, file, line, hexval = match.groups()
    return RndRecord(int(counter), file, int(line), int(hexval, 16))


def parse_events(lines: Iterable[str]) -> Iterator[LogItem]:
    """Parse a log with its scope markers, checking that the draw counters strictly increase."""
    previous = 0
    for lineno, raw in enumerate(lines, 1):
        text = raw.rstrip("\r\n")
        begin = _BEGIN_RE.match(text)
        if begin is not None:
            scope, seed, rest = begin.groups()
            yield ScopeBegin(int(scope), int(seed, 16), tuple(int(v) for v in rest.split()))
            continue
        end = _END_RE.match(text)
        if end is not None:
            yield ScopeEnd(int(end.group(1)))
            continue
        record = parse_line(text, lineno)
        if record.counter <= previous:
            raise RndLogError(
                f"rnd.log line {lineno}: counter {record.counter} does not follow {previous}"
            )
        previous = record.counter
        yield record


def parse_lines(lines: Iterable[str]) -> Iterator[RndRecord]:
    """The draw records of a log (scope markers are skipped)."""
    for item in parse_events(lines):
        if isinstance(item, RndRecord):
            yield item


def read_events(path: Path) -> Iterator[LogItem]:
    """Stream the draw records and scope markers of ``path``."""
    try:
        handle = path.open(encoding="ascii", newline="")
    except OSError as err:
        raise RndLogError(f"cannot read {path}: {err}") from err
    with handle:
        yield from parse_events(handle)


def read_log(path: Path) -> Iterator[RndRecord]:
    """Stream the draw records of ``path`` (scope markers are skipped)."""
    for item in read_events(path):
        if isinstance(item, RndRecord):
            yield item


@dataclass(frozen=True, slots=True)
class RndLogSummary:
    """Totals of a log. ``segments`` counts runs of consecutive counters."""

    records: int
    first_counter: int
    last_counter: int
    segments: int
    per_site: dict[str, int]

    def as_json(self) -> dict[str, object]:
        return {
            "records": self.records,
            "first_counter": self.first_counter,
            "last_counter": self.last_counter,
            "segments": self.segments,
            "per_site": self.per_site,
        }


def _site_key(site: str) -> tuple[str, int]:
    file, _, line = site.rpartition(":")
    return file, int(line)


def summarize(records: Iterable[RndRecord]) -> RndLogSummary:
    """Count records per site and find the counter range and gaps."""
    sites: Counter[str] = Counter()
    total = 0
    first = last = 0
    segments = 0
    for record in records:
        if total == 0:
            first = record.counter
            segments = 1
        elif record.counter != last + 1:
            segments += 1
        last = record.counter
        total += 1
        sites[record.site] += 1
    ordered = dict(sorted(sites.items(), key=lambda item: _site_key(item[0])))
    return RndLogSummary(total, first, last, segments, ordered)


def _format_summary(summary: RndLogSummary) -> str:
    out = [f"records        {summary.records}"]
    if summary.records:
        out.append(f"counter range  {summary.first_counter} .. {summary.last_counter}")
        out.append(f"segments       {summary.segments}")
    out.append(f"sites          {len(summary.per_site)}")
    out.extend(f"{count:>12}  {site}" for site, count in summary.per_site.items())
    return "\n".join(out)


@dataclass(slots=True)
class ScopeReport:
    """Result of :func:`analyze_scopes`. ``outside`` counts draws in no scope instance."""

    draws: int = 0
    inside: int = 0
    instances: Counter[int] = field(default_factory=Counter)
    draws_per_scope: Counter[int] = field(default_factory=Counter)
    sites_per_scope: dict[int, Counter[str]] = field(default_factory=dict)
    outside_sites: Counter[str] = field(default_factory=Counter)
    outside_first: dict[str, int] = field(default_factory=dict)
    stray_ends: int = 0
    problems: list[str] = field(default_factory=list)

    @property
    def outside(self) -> int:
        return self.draws - self.inside

    @property
    def clean(self) -> bool:
        return self.outside == 0 and not self.problems

    def as_json(self) -> dict[str, object]:
        return {
            "draws": self.draws,
            "inside": self.inside,
            "outside": self.outside,
            "instances": {str(k): v for k, v in sorted(self.instances.items())},
            "draws_per_scope": {str(k): v for k, v in sorted(self.draws_per_scope.items())},
            "outside_sites": {
                site: {"draws": n, "first_counter": self.outside_first[site]}
                for site, n in sorted(self.outside_sites.items(), key=lambda i: _site_key(i[0]))
            },
            "stray_ends": self.stray_ends,
            "problems": self.problems,
        }


def analyze_scopes(
    items: Iterable[LogItem], master: int | None = None, check_streams: bool = False
) -> ScopeReport:
    """Classify every draw as inside or outside a reseeded scope instance.

    A draw is *inside* when a ``B`` marker precedes it and no later ``B`` or ``E`` marker
    comes between them. With ``master`` the seed of every ``B`` marker is compared with
    ``derive_seed``; with ``check_streams`` as well the draws of an instance must be, in
    order and with consecutive counters, the output of ``FbMtRng(seed)`` from its start.
    """
    report = ScopeReport()
    current: ScopeBegin | None = None
    rng: FbMtRng | None = None
    last_counter = 0
    for item in items:
        if isinstance(item, ScopeBegin):
            current = item
            report.instances[item.scope] += 1
            report.sites_per_scope.setdefault(item.scope, Counter())
            names = TUPLE_FIELDS.get(item.scope)
            if names is None:
                report.problems.append(f"unknown scope id {item.scope}")
            elif len(names) != len(item.tuple_values):
                report.problems.append(
                    f"scope {item.scope}: {len(item.tuple_values)} tuple elements, "
                    f"expected {len(names)}"
                )
            elif master is not None:
                want = derive_seed(master, item.scope, *item.tuple_values)
                if want != item.seed:
                    report.problems.append(
                        f"scope {item.scope} {item.tuple_values}: seed {item.seed:08x}, "
                        f"derive_seed gives {want:08x}"
                    )
            rng = FbMtRng(item.seed) if check_streams else None
            last_counter = 0
        elif isinstance(item, ScopeEnd):
            if current is None:
                report.stray_ends += 1
            elif current.scope != item.scope:
                report.problems.append(f"scope {current.scope} closed by end of {item.scope}")
            current = None
            rng = None
        else:
            report.draws += 1
            if current is None:
                report.outside_sites[item.site] += 1
                report.outside_first.setdefault(item.site, item.counter)
                continue
            report.inside += 1
            report.draws_per_scope[current.scope] += 1
            report.sites_per_scope[current.scope][item.site] += 1
            if rng is not None:
                if last_counter and item.counter != last_counter + 1:
                    report.problems.append(
                        f"scope {current.scope} {current.tuple_values}: gap before draw "
                        f"{item.counter}"
                    )
                    rng = None
                elif rng.next_u32() != item.u32:
                    report.problems.append(
                        f"scope {current.scope} {current.tuple_values}: draw {item.counter} "
                        f"is not the next FbMtRng({current.seed}) output"
                    )
                    rng = None
                last_counter = item.counter
    return report


def _format_scope_report(report: ScopeReport) -> str:
    out = [
        f"draws          {report.draws}",
        f"inside scopes  {report.inside}",
        f"outside scopes {report.outside}",
    ]
    for scope in sorted(report.instances):
        name = SCOPE_NAMES.get(scope, "?")
        sites = report.sites_per_scope[scope]
        out.append(
            f"scope {scope} ({name}): {report.instances[scope]} instances, "
            f"{report.draws_per_scope[scope]} draws, {len(sites)} sites"
        )
    if report.stray_ends:
        out.append(f"end markers without an open scope: {report.stray_ends}")
    if report.outside_sites:
        out.append("draws outside any scope (draws, first counter, site):")
        for site, count in sorted(report.outside_sites.items(), key=lambda i: _site_key(i[0])):
            out.append(f"{count:>12}  {report.outside_first[site]:>12}  {site}")
    out.extend(f"problem: {problem}" for problem in report.problems[:20])
    if len(report.problems) > 20:
        out.append(f"... and {len(report.problems) - 20} more problems")
    return "\n".join(out)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="harness.rndlog",
        description="Reader for the rnd.log written by the rndlog harness patch.",
    )
    sub = parser.add_subparsers(dest="command", required=True)
    p_sum = sub.add_parser("summary", help="draws per site and counter range")
    p_sum.add_argument("log", type=Path)
    p_sum.add_argument("--json", action="store_true", help="machine-readable output")
    p_head = sub.add_parser("head", help="print the first records")
    p_head.add_argument("log", type=Path)
    p_head.add_argument("-n", type=int, default=10, help="number of records (default 10)")
    p_scopes = sub.add_parser(
        "scopes",
        help="draws outside reseeded scopes (exit 3 if there are any, or on a problem)",
    )
    p_scopes.add_argument("log", type=Path)
    p_scopes.add_argument("--master", type=int, help="GEF_SEED: check the seed of every scope")
    p_scopes.add_argument(
        "--streams", action="store_true", help="check each scope's draws against FbMtRng(seed)"
    )
    p_scopes.add_argument("--json", action="store_true", help="machine-readable output")
    args = parser.parse_args(argv)
    try:
        if args.command == "scopes":
            report = analyze_scopes(read_events(args.log), args.master, args.streams)
            if args.json:
                print(json.dumps(report.as_json(), indent=2))
            else:
                print(_format_scope_report(report))
            return 0 if report.clean else 3
        if args.command == "summary":
            summary = summarize(read_log(args.log))
            if args.json:
                print(json.dumps(summary.as_json(), indent=2))
            else:
                print(_format_summary(summary))
        else:
            for count, record in enumerate(read_log(args.log)):
                if count >= args.n:
                    break
                print(f"{record.counter} {record.site} {record.u32:08x} {record.value!r}")
    except HarnessError as err:
        print(f"harness.rndlog: {err}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
