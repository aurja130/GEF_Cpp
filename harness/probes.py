# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Reader for the probe files written by the ``probes`` harness patch (M1.8).

Usage (from the repository root)::

    python3 -m harness.probes summary <probe file> [--names]
    python3 -m harness.probes show <probe file> <NAME> [--limit N]

``summary`` lists every record of the file (one record = one probe invocation) with its
context and the number of scalars and arrays; ``--names`` also lists each variable with its
type and bounds. ``show`` prints the decoded values of one variable in every record.
Exit status: 0 success, 1 unreadable or malformed file or unknown variable.

The line format is specified in ``harness/PROBES.md``::

    <ID> <context> <NAME> <idx1,idx2,...|-> <type> <value>

Types: ``S`` Single (8 hex digits of the IEEE bit pattern), ``D`` Double (16 hex digits),
``I`` integer (decimal), ``Z`` string (quoted, with ``\\\\``, ``\\"`` and ``\\xHH`` escapes),
``B``/``BS`` bounds record of a dense / sparse array ("<element type> lo:hi,lo:hi"). A sparse
array omits the elements whose bit pattern is all zero; ``ProbeVar.get`` returns the zero of
the element type for those.

Library use::

    from harness.probes import read_probe_file
    records = read_probe_file(path)
    spin = records[0].var("SpinRMSNZ").get((1, 1, 90, 40))   # float, exact Single value
    bits = records[0].var("SpinRMSNZ").raw((1, 1, 90, 40))   # "3F800000"
"""

from __future__ import annotations

import argparse
import re
import struct
import sys
from collections.abc import Iterator, Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Final

from harness.common import HarnessError

__all__ = [
    "ProbeFormatError",
    "ProbeLine",
    "ProbeRecord",
    "ProbeValue",
    "ProbeVar",
    "decode_double",
    "decode_single",
    "encode_double",
    "encode_single",
    "parse_line",
    "read_probe_file",
    "summarize",
    "unescape_string",
]

Index = tuple[int, ...]
ProbeValue = float | int | str
Bounds = tuple[tuple[int, int], ...]

_CONTEXT_KEYS: Final = ("step", "pass", "bin", "rec")
_HEX_RE: Final = re.compile(r"[0-9A-Fa-f]+")
_ESCAPE_RE: Final = re.compile(r"\\(\\|\"|x[0-9A-Fa-f]{2})")


class ProbeFormatError(HarnessError):
    """A probe file line does not follow the format of ``harness/PROBES.md``."""


def decode_single(text: str) -> float:
    """Value of an 8-digit hex bit pattern as an IEEE binary32 (exact, as a Python float)."""
    if len(text) != 8 or _HEX_RE.fullmatch(text) is None:
        raise ProbeFormatError(f"not a Single bit pattern (8 hex digits): {text!r}")
    return float(struct.unpack(">f", bytes.fromhex(text))[0])


def decode_double(text: str) -> float:
    """Value of a 16-digit hex bit pattern as an IEEE binary64."""
    if len(text) != 16 or _HEX_RE.fullmatch(text) is None:
        raise ProbeFormatError(f"not a Double bit pattern (16 hex digits): {text!r}")
    return float(struct.unpack(">d", bytes.fromhex(text))[0])


def encode_single(value: float) -> str:
    """The 8-digit upper-case hex bit pattern of ``value`` rounded to binary32."""
    return struct.pack(">f", value).hex().upper()


def encode_double(value: float) -> str:
    """The 16-digit upper-case hex bit pattern of ``value``."""
    return struct.pack(">d", value).hex().upper()


def unescape_string(text: str) -> str:
    """Decode a quoted probe string to latin-1 text (escapes: backslash, quote, ``\\xHH``)."""
    if len(text) < 2 or text[0] != '"' or text[-1] != '"':
        raise ProbeFormatError(f"string value is not quoted: {text!r}")
    body = text[1:-1]

    def _sub(match: re.Match[str]) -> str:
        token = match.group(1)
        return chr(int(token[1:], 16)) if token[0] == "x" else token

    result = _ESCAPE_RE.sub(_sub, body)
    leftover = _ESCAPE_RE.sub("", body)
    if "\\" in leftover or '"' in leftover:
        raise ProbeFormatError(f"bad escape or unescaped quote in string: {text!r}")
    return result


def _parse_bounds(text: str) -> Bounds:
    bounds: list[tuple[int, int]] = []
    for part in text.split(","):
        low, sep, high = part.partition(":")
        if not sep:
            raise ProbeFormatError(f"bad bounds {text!r}")
        try:
            bounds.append((int(low), int(high)))
        except ValueError as exc:
            raise ProbeFormatError(f"bad bounds {text!r}") from exc
    return tuple(bounds)


@dataclass(frozen=True)
class ProbeLine:
    """One parsed line. ``value`` is the raw text after the type token."""

    probe: str
    context: dict[str, str]
    name: str
    index: Index
    type: str
    value: str


def parse_line(line: str) -> ProbeLine:
    """Parse one probe line (no trailing newline)."""
    tokens = line.split(" ", 1)
    if len(tokens) != 2:
        raise ProbeFormatError(f"too few fields: {line!r}")
    probe, rest = tokens
    context: dict[str, str] = {}
    if rest.startswith("- "):
        rest = rest[2:]
    else:
        while True:
            token, sep, remainder = rest.partition(" ")
            key, eq, value = token.partition("=")
            if not sep or not eq:
                break
            context[key] = value
            rest = remainder
        if not context:
            raise ProbeFormatError(f"missing context: {line!r}")
    fields = rest.split(" ", 3)
    if len(fields) != 4:
        raise ProbeFormatError(f"expected NAME idx type value after the context: {line!r}")
    name, idx_text, type_, value = fields
    try:
        index: Index = () if idx_text == "-" else tuple(int(p) for p in idx_text.split(","))
    except ValueError as exc:
        raise ProbeFormatError(f"bad index {idx_text!r}: {line!r}") from exc
    if type_ not in ("S", "D", "I", "Z", "B", "BS"):
        raise ProbeFormatError(f"unknown type {type_!r}: {line!r}")
    return ProbeLine(probe, context, name, index, type_, value)


def _decode(type_: str, text: str) -> ProbeValue:
    if type_ == "S":
        return decode_single(text)
    if type_ == "D":
        return decode_double(text)
    if type_ == "I":
        try:
            return int(text)
        except ValueError as exc:
            raise ProbeFormatError(f"not an integer: {text!r}") from exc
    return unescape_string(text)


@dataclass
class ProbeVar:
    """One variable of a record: a scalar (``bounds is None``) or an array."""

    name: str
    type: str = ""
    bounds: Bounds | None = None
    sparse: bool = False
    texts: dict[Index, str] = field(default_factory=lambda: dict[Index, str]())

    @property
    def is_array(self) -> bool:
        """True when a bounds record was seen for the variable."""
        return self.bounds is not None

    def __len__(self) -> int:
        return len(self.texts)

    def indices(self) -> Iterator[Index]:
        """Indices present in the file, in file order."""
        return iter(self.texts)

    def raw(self, index: Index = ()) -> str:
        """The value text as written (hex bit pattern, decimal, or the quoted string)."""
        return self.texts[index]

    def get(self, index: Index = ()) -> ProbeValue:
        """The decoded value. A sparse array returns zero for an omitted element in bounds."""
        text = self.texts.get(index)
        if text is not None:
            return _decode(self.type, text)
        if self.sparse and self.bounds is not None and self.in_bounds(index):
            return 0.0 if self.type in ("S", "D") else 0
        raise KeyError(index)

    def items(self) -> Iterator[tuple[Index, ProbeValue]]:
        """(index, decoded value) for the elements present in the file."""
        for index, text in self.texts.items():
            yield index, _decode(self.type, text)

    def in_bounds(self, index: Index) -> bool:
        assert self.bounds is not None
        return len(index) == len(self.bounds) and all(
            lo <= i <= hi for i, (lo, hi) in zip(index, self.bounds, strict=True)
        )

    def expected_count(self) -> int | None:
        """Number of elements a dense array must have, None for scalars and sparse arrays."""
        if self.bounds is None or self.sparse:
            return None
        count = 1
        for lo, hi in self.bounds:
            count *= max(hi - lo + 1, 0)
        return count


@dataclass
class ProbeRecord:
    """All lines of one probe invocation (same probe ID and context)."""

    probe: str
    context: dict[str, str]
    variables: dict[str, ProbeVar] = field(default_factory=lambda: dict[str, ProbeVar]())
    line_count: int = 0

    @property
    def step(self) -> int | None:
        """The energy step of the context, None for T0 or when written as ``-``."""
        return _int_or_none(self.context.get("step"))

    @property
    def pass_(self) -> int | None:
        """The pass (I_Error) of the context, None when not applicable."""
        return _int_or_none(self.context.get("pass"))

    @property
    def bin(self) -> tuple[int, int, int, int] | None:
        """The bin (I_E_Distr, I_N_Multi, I_Z_Multi, I_E_Multi), None when not applicable."""
        text = self.context.get("bin")
        if text is None or text == "-":
            return None
        parts = tuple(int(p) for p in text.split(":"))
        if len(parts) != 4:
            raise ProbeFormatError(f"bin context needs four indices: {text!r}")
        return parts[0], parts[1], parts[2], parts[3]

    @property
    def rec(self) -> int | None:
        """The 1-based invocation counter of this probe in the process."""
        return _int_or_none(self.context.get("rec"))

    def var(self, name: str) -> ProbeVar:
        """The variable ``name`` (KeyError if the record does not contain it)."""
        return self.variables[name]

    def scalar(self, name: str) -> ProbeValue:
        """Decoded value of a scalar variable."""
        return self.variables[name].get(())


def _int_or_none(text: str | None) -> int | None:
    if text is None or text == "-":
        return None
    return int(text)


def _check_array(var: ProbeVar, where: str) -> None:
    expected = var.expected_count()
    if expected is not None and len(var) != expected:
        raise ProbeFormatError(
            f"{where}: dense array {var.name} has {len(var)} elements, bounds say {expected}"
        )
    if var.bounds is not None:
        for index in var.indices():
            if not var.in_bounds(index):
                raise ProbeFormatError(
                    f"{where}: {var.name}{list(index)} outside bounds {var.bounds}"
                )


def read_probe_file(path: Path) -> list[ProbeRecord]:
    """Parse a probe file into records, in file order. Raises ProbeFormatError on bad content.

    A new record starts when the probe ID or the context changes. Dense arrays are checked
    for the element count their bounds record announces.
    """
    records: list[ProbeRecord] = []
    current: ProbeRecord | None = None
    with path.open("r", encoding="latin-1", newline="") as handle:
        for number, line in enumerate(handle, 1):
            text = line.rstrip("\n")
            if not text:
                continue
            where = f"{path}:{number}"
            try:
                parsed = parse_line(text)
                if (
                    current is None
                    or current.probe != parsed.probe
                    or current.context != parsed.context
                ):
                    if current is not None:
                        _finish(current, where)
                    current = ProbeRecord(parsed.probe, parsed.context)
                    records.append(current)
                current.line_count += 1
                _add(current, parsed)
            except ProbeFormatError as exc:
                raise ProbeFormatError(f"{where}: {exc}") from exc
    if current is not None:
        _finish(current, str(path))
    return records


def _finish(record: ProbeRecord, where: str) -> None:
    for var in record.variables.values():
        _check_array(var, where)


def _add(record: ProbeRecord, parsed: ProbeLine) -> None:
    var = record.variables.get(parsed.name)
    if var is None:
        var = ProbeVar(parsed.name)
        record.variables[parsed.name] = var
    if parsed.type in ("B", "BS"):
        if var.bounds is not None or len(var) > 0:
            raise ProbeFormatError(f"bounds of {parsed.name} must be its first line")
        element_type, _, bounds_text = parsed.value.partition(" ")
        if element_type not in ("S", "D", "I", "Z"):
            raise ProbeFormatError(f"bounds record of {parsed.name} lacks an element type")
        var.type = element_type
        var.bounds = _parse_bounds(bounds_text)
        var.sparse = parsed.type == "BS"
        return
    if var.type and var.type != parsed.type:
        raise ProbeFormatError(f"{parsed.name} changes type from {var.type} to {parsed.type}")
    var.type = parsed.type
    if parsed.index in var.texts:
        raise ProbeFormatError(f"duplicate element {parsed.name}{list(parsed.index)}")
    _decode(parsed.type, parsed.value)  # validates the value text
    var.texts[parsed.index] = parsed.value


def _describe_context(record: ProbeRecord) -> str:
    if not record.context:
        return "-"
    return " ".join(
        f"{key}={record.context[key]}" for key in _CONTEXT_KEYS if key in record.context
    )


def _format_bounds(bounds: Bounds) -> str:
    return ",".join(f"{lo}:{hi}" for lo, hi in bounds)


def summarize(records: Sequence[ProbeRecord], *, names: bool = False) -> str:
    """Text summary of the records (what ``summary`` prints)."""
    out: list[str] = []
    for number, record in enumerate(records, 1):
        scalars = sum(1 for v in record.variables.values() if not v.is_array)
        arrays = sum(1 for v in record.variables.values() if v.is_array)
        out.append(
            f"record {number}: {record.probe} {_describe_context(record)}  "
            f"{record.line_count} lines, {scalars} scalars, {arrays} arrays"
        )
        if names:
            for var in record.variables.values():
                if var.bounds is None:
                    out.append(f"  {var.name} {var.type}")
                else:
                    kind = "sparse" if var.sparse else "dense"
                    extent = _format_bounds(var.bounds)
                    out.append(f"  {var.name} {var.type} [{extent}] {kind}, {len(var)} elements")
    return "\n".join(out)


def _format_show(var: ProbeVar, limit: int) -> list[str]:
    lines: list[str] = []
    for count, index in enumerate(var.indices()):
        if count >= limit:
            lines.append(f"  ... {len(var) - limit} more")
            break
        label = ",".join(str(i) for i in index) if index else "-"
        text = var.raw(index)
        if var.type in ("S", "D"):
            lines.append(f"  {label}  {text}  {var.get(index)!r}")
        else:
            lines.append(f"  {label}  {text}")
    return lines


def _main(argv: Sequence[str] | None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m harness.probes", description="Read harness probe files."
    )
    sub = parser.add_subparsers(dest="command", required=True)
    p_sum = sub.add_parser("summary", help="list the records of a probe file")
    p_sum.add_argument("file", type=Path)
    p_sum.add_argument("--names", action="store_true", help="also list every variable")
    p_show = sub.add_parser("show", help="print the decoded values of one variable")
    p_show.add_argument("file", type=Path)
    p_show.add_argument("name")
    p_show.add_argument("--limit", type=int, default=20, help="elements per record (default 20)")
    args = parser.parse_args(argv)
    file: Path = args.file
    try:
        records = read_probe_file(file)
    except (OSError, HarnessError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    if args.command == "summary":
        print(summarize(records, names=bool(args.names)))
        return 0
    name: str = args.name
    found = False
    for number, record in enumerate(records, 1):
        if name in record.variables:
            found = True
            print(f"record {number}: {record.probe} {_describe_context(record)}")
            print("\n".join(_format_show(record.variables[name], int(args.limit))))
    if not found:
        print(f"error: no variable {name!r} in {file}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(_main(None))
