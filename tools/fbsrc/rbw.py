# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Read-before-write and writer analysis of a range of GEF's emitted C (M7.0).

Usage (from the repository root)::

    python3 -m tools.fbsrc.rbw reads   <file>:<first>-<last> [--json]
    python3 -m tools.fbsrc.rbw writers <file>:<first>-<last> [--json]
    python3 -m tools.fbsrc.rbw escapes <file>:<first>-<last> [--json]

The range is a run of BASIC lines whose C is one contiguous stretch of ``GEF.c`` (every
``#line`` directive inside the stretch points into the range). The C is analysed as a
control-flow graph: one node per statement, ``goto label$N`` and ``if( ... ) goto label$N``
as edges, a jump to a label outside the stretch as an exit. Entry is the first statement.

``reads`` lists every variable that some path from the entry reads before writing it,
the *read-before-write set* (a forward must-defined analysis; the meet is intersection,
so a variable written on only one branch stays undefined after the join):

* a scalar is defined by ``X = ...;`` and by ``__builtin_memset( &X, ... )`` (fbc's
  initialisation of a ``Dim``);
* an array is defined only by its own ``Dim``/``ReDim`` inside the stretch
  (``fb_ArrayRedimEx``/``memset`` of its descriptor); an element write ``*(T*)(...) = ...``
  defines nothing, so every array the stretch reads and does not create is reported;
* ``&X`` passed to a procedure (``ByRef``) is a read and does not define ``X``;
* a call to a GEF procedure reads the ``Shared`` globals that procedure (or one it calls)
  reads before writing them, computed with the same analysis on its body.
  ``Static`` variables of the called procedures are listed separately: they carry state
  between calls that no probe of module variables sees.

``writers`` lists, for each variable written in the stretch, the BASIC lines that write
it, in program order (element writes of an array carry the BASIC text of the target; a
scalar passed ``ByRef`` to a procedure counts as written there, since the procedure may; a
``Shared`` global that a called procedure writes, transitively, is listed at the call with
the procedure's name).
``escapes`` lists, for each variable written in the stretch, the BASIC lines outside the
stretch whose C reads it (module code and procedure bodies), i.e. the values that later
code consumes.

fbc names: ``NAME$`` is a ``Dim Shared`` global, ``NAME$0`` a module-level ``Dim``/
``Static``, ``NAME$<n>`` a block or procedure local; temporaries (``vr$N``, ``tmp$N``,
``TMP$N$M``) are fbc's own and not tracked.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections.abc import Container, Iterable, Sequence
from collections.abc import Set as AbstractSet
from dataclasses import dataclass, field
from functools import cache
from pathlib import Path

from tools.fbsrc.common import FbsrcError, read_source_lines, resolve_source_name
from tools.fbsrc.emit_c import Emission, emit
from tools.fbsrc.fbdef import load_index
from tools.fbsrc.fbline import CIndex, c_index, parse_location
from tools.toolchain.fbc import GEF_SOURCE_DIR

EXIT_OK = 0
EXIT_ERROR = 2

_VAR = re.compile(r"(?<![\w$])([A-Z_][A-Z0-9_]*\$\d*)(?![\w$])")
_FB_TEMP = re.compile(r"^TMP\$\d+\$\d+$")
_CALL = re.compile(r"(?<![\w$])([A-Z_][A-Z0-9_]*)\(")
_STRING = re.compile(r'"(?:[^"\\]|\\.)*"')
_LABEL = re.compile(r"^(label\$\d+):;$")
_GOTO = re.compile(r"^goto (label\$\d+);$")
_IF_GOTO = re.compile(r"^if\(.*\) goto (label\$\d+);$")
_ASSIGN = re.compile(r"^([A-Z_][A-Z0-9_]*\$\d*) = (.*);$")
_MEMSET = re.compile(r"^__builtin_memset\( &([A-Z_][A-Z0-9_]*\$\d*), ")
_REDIM = re.compile(r"^fb_ArrayRedimEx\( \(struct \$\w+\*\)&([A-Z_][A-Z0-9_]*\$\d*), ")
_ELEMENT_WRITE = re.compile(r"^\*\(.* = .*;$")
# Set-up of a new array's descriptor (fbc's Dim/ReDim prologue): writes to descriptor fields
# through the descriptor's own address, not through its data pointer (``*(int64*)&X``).
_DESC_INIT = re.compile(
    r"^(?:__builtin_memset\( \(void\*\)\(\(uint8\*\)&[A-Z_][A-Z0-9_]*\$\d* \+ \d+ll\), "
    r"|\*\(\w+\*+\)(?:&[A-Z_][A-Z0-9_]*\$\d*|\(\(uint8\*\)&[A-Z_][A-Z0-9_]*\$\d* \+ \d+ll\)) = )"
)
_ARRAY_DECL = re.compile(r"^\s*(?:static )?struct \$\d+FBARRAY\w* ([A-Z_][A-Z0-9_]*\$\d*)(?![\w$])")
_SCALAR_DECL = re.compile(
    r"^\s*(?:static )?(float|double|int64|int32|int16|int8|uint64|uint32|uint16|uint8|FBSTRING)"
    r"\*? ([A-Z_][A-Z0-9_]*\$\d*)[;\s=]"
)
_STATIC_DECL = re.compile(
    r"^\s+static (?:struct \$\w+|[A-Za-z0-9_]+\*?) ([A-Z_][A-Z0-9_]*\$\d+)(?![\w$])"
)
_FUNC_DEF = re.compile(r"^[a-zA-Z][\w$ *]*?\b([A-Z_][A-Z0-9_]*)\( .*\)$")
_LINE = re.compile(r'^\s*#line\s+(\d+)\s+"([^"]*)"')
_C_TYPE_CODE = {
    "float": "S",
    "double": "D",
    "FBSTRING": "Z",
}


@dataclass(frozen=True)
class Statement:
    c_line: int  # 1-based line in GEF.c
    basic_file: str
    basic_line: int
    text: str  # stripped, string literals blanked


@dataclass
class Node:
    stmt: Statement
    succ: list[int] = field(default_factory=lambda: list[int]())
    defs: frozenset[str] = frozenset()  # must-defined after the statement
    uses: frozenset[str] = frozenset()  # read by the statement
    byref: frozenset[str] = frozenset()  # passed with & to a called procedure (also in uses)
    element_writes: frozenset[str] = frozenset()  # arrays with an element written
    scalar_writes: frozenset[str] = frozenset()  # scalars assigned (same as the defs)
    calls: tuple[str, ...] = ()  # GEF procedures called


@dataclass(frozen=True)
class Read:
    variable: str
    basic_file: str
    basic_line: int
    c_line: int
    via: str  # "" for a direct read, else the procedure called at the site
    byref: bool


@dataclass(frozen=True)
class Analysis:
    file: str
    c_first: int
    c_last: int
    nodes: tuple[Node, ...]
    reads: tuple[Read, ...]  # first read-before-write site of every variable, program order
    statics: dict[str, tuple[str, ...]]  # called procedure -> its Static variables (transitive)
    # C line of a call statement -> (procedure, Shared globals it writes, transitively) per call
    callee_writes: dict[int, tuple[tuple[str, frozenset[str]], ...]]


class Program:
    """Declarations and procedure bodies of one ``GEF.c``."""

    def __init__(self, emission: Emission) -> None:
        self.index: CIndex = c_index(emission)
        lines = self.index.lines
        self.arrays: set[str] = set()
        self.types: dict[str, str] = {}
        self.decl_line: dict[str, tuple[str, int]] = {}
        self.functions: dict[str, tuple[int, int]] = {}  # name -> (0-based first body line, end)
        current: tuple[str, int] = ("", 0)
        fn_name: str | None = None
        fn_start = 0
        for i, text in enumerate(lines):
            m = _LINE.match(text)
            if m is not None:
                current = (Path(m.group(2)).name, int(m.group(1)))
                continue
            if fn_name is None:
                f = _FUNC_DEF.match(text)
                j = i + 1
                while j < len(lines) and _LINE.match(lines[j]) is not None:
                    j += 1
                if f is not None and j < len(lines) and lines[j] == "{":
                    fn_name = f.group(1)
                    fn_start = j + 1
            elif text == "}":
                self.functions[fn_name] = (fn_start, i)
                fn_name = None
            a = _ARRAY_DECL.match(text)
            if a is not None:
                self.arrays.add(a.group(1))
                self.types.setdefault(a.group(1), "array")
                self.decl_line.setdefault(a.group(1), current)
                continue
            s = _SCALAR_DECL.match(text)
            if s is not None:
                self.types.setdefault(s.group(2), s.group(1))
                self.decl_line.setdefault(s.group(2), current)

    def type_code(self, var: str) -> str:
        t = self.types.get(var, "")
        if var in self.arrays:
            return "A"
        if t in _C_TYPE_CODE:
            return _C_TYPE_CODE[t]
        return "I" if t else "?"

    def statements(self, c_first: int, c_last: int) -> list[Statement]:
        """Statements of 0-based C lines ``c_first..c_last-1`` (directives tracked)."""
        lines = self.index.lines
        out: list[Statement] = []
        current = ("", 0)
        # The directive in force at c_first may sit above it.
        for i in range(c_first, -1, -1):
            m = _LINE.match(lines[i])
            if m is not None:
                current = (Path(m.group(2)).name, int(m.group(1)))
                break
        for i in range(c_first, c_last):
            text = lines[i]
            m = _LINE.match(text)
            if m is not None:
                current = (Path(m.group(2)).name, int(m.group(1)))
                continue
            s = text.strip()
            if not s or s in ("{", "}") or s.startswith("//"):
                continue
            out.append(Statement(i + 1, current[0], current[1], _STRING.sub('""', s)))
        return out

    def declared(self, c_first: int, c_last: int) -> list[str]:
        """Variables declared on 0-based C lines ``c_first..c_last-1``."""
        found: list[str] = []
        for text in self.index.lines[c_first:c_last]:
            m = _SCALAR_DECL.match(text) or _ARRAY_DECL.match(text)
            if m is not None:
                found.append(m.groups()[-1])
        return found

    def function_statics(self, name: str) -> tuple[str, ...]:
        first, end = self.functions[name]
        return static_declarations(self.index.lines[first:end])


def static_declarations(lines: Iterable[str]) -> tuple[str, ...]:
    """The ``Static`` variables declared in the lines of a procedure body (C ``static``)."""
    return tuple(m.group(1) for text in lines if (m := _STATIC_DECL.match(text)) is not None)


def _tracked(var: str) -> bool:
    return _FB_TEMP.match(var) is None


def _vars(text: str) -> list[str]:
    return [v for v in _VAR.findall(text) if _tracked(v)]


def build_nodes(
    stmts: Sequence[Statement], arrays: AbstractSet[str], functions: Container[str]
) -> list[Node]:
    """One node per statement; ``arrays`` names the array descriptors, ``functions`` the GEF
    procedures (calls to anything else are runtime or C library calls)."""
    labels = {m.group(1): k for k, st in enumerate(stmts) if (m := _LABEL.match(st.text))}
    nodes: list[Node] = []
    for k, st in enumerate(stmts):
        text = st.text
        node = Node(st)
        nxt = [k + 1] if k + 1 < len(stmts) else []
        g = _GOTO.match(text)
        ig = _IF_GOTO.match(text)
        if g is not None:
            target = labels.get(g.group(1))
            node.succ = [] if target is None else [target]
        elif ig is not None:
            target = labels.get(ig.group(1))
            node.succ = nxt + ([] if target is None else [target])
        else:
            node.succ = nxt
        defs: set[str] = set()
        element_writes: set[str] = set()
        uses: list[str]
        refs = True  # whether `&X` in the statement passes X to a procedure
        a = _ASSIGN.match(text)
        decl = _SCALAR_DECL.match(text) or _ARRAY_DECL.match(text)
        if a is not None and a.group(1) not in arrays:
            defs.add(a.group(1))
            uses = _vars(a.group(2))
        elif (ms := _MEMSET.match(text)) is not None or (ms := _REDIM.match(text)) is not None:
            defs.add(ms.group(1))
            uses = [v for v in _vars(text) if v != ms.group(1)]  # e.g. ReDim bounds
            refs = False
        elif _DESC_INIT.match(text) is not None:
            uses = []  # set-up of a new array's descriptor (Dim/ReDim prologue)
            refs = False
        elif _ELEMENT_WRITE.match(text) is not None:
            lhs, rhs = _split_assignment(text)
            written = _written_array(lhs, arrays)
            # Without a data pointer (e.g. a pointer deref) every array named is taken as written.
            targets = {written} if written is not None else {v for v in _vars(lhs) if v in arrays}
            element_writes.update(targets)
            # Other arrays on the left index the element: their elements are read.
            uses = [v for v in _vars(lhs) if v not in targets] + _vars(rhs)
        elif decl is not None:
            # A declaration; fbc normally initialises it in the next statement. A `static`
            # initialiser runs once, so it defines nothing for a later pass through.
            name = decl.groups()[-1]
            _, eq, init = text.partition(" = ")
            uses = _vars(init) if eq else []
            if eq and not text.startswith("static "):
                defs.add(name)
            refs = False
        else:
            uses = _vars(text)
        byref: set[str] = set()
        if refs:
            byref = {m.group(1) for m in re.finditer(r"&([A-Z_][A-Z0-9_]*\$\d*)(?![\w$])", text)}
            byref = {v for v in byref if v not in arrays and _tracked(v)}
        calls = tuple(c for c in _CALL.findall(text) if c in functions)
        node.defs = frozenset(defs)
        node.scalar_writes = frozenset(defs - arrays)
        node.element_writes = frozenset(element_writes)
        node.uses = frozenset(uses)
        node.byref = frozenset(byref)
        node.calls = calls
        nodes.append(node)
    return nodes


_DATA_POINTER = re.compile(r"\*\(int64\*\)&([A-Z_][A-Z0-9_]*\$\d*)(?![\w$])")


def _written_array(lhs: str, arrays: AbstractSet[str]) -> str | None:
    """The array whose element ``lhs`` (``*(T*)(<address>)``) denotes: the one whose data
    pointer (``*(int64*)&X``) is the base of the address, i.e. the shallowest in parentheses;
    deeper data pointers are elements of other arrays read to form the index."""
    found: list[tuple[int, str]] = []
    for m in _DATA_POINTER.finditer(lhs):
        if m.group(1) in arrays:
            depth = lhs.count("(", 0, m.start()) - lhs.count(")", 0, m.start())
            found.append((depth, m.group(1)))
    if not found:
        return None
    shallowest = min(d for d, _ in found)
    names = {v for d, v in found if d == shallowest}
    if len(names) != 1:
        raise FbsrcError(f"element write with more than one base array: {lhs!r}")
    return names.pop()


def _split_assignment(text: str) -> tuple[str, str]:
    """Split ``<lhs> = <rhs>;`` at the first ``=`` outside parentheses."""
    depth = 0
    for i, ch in enumerate(text):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "=" and depth == 0 and text[i - 1] == " " and text[i + 1] == " ":
            return text[:i], text[i + 1 :]
    raise FbsrcError(f"no top-level assignment in {text!r}")


def must_defined(nodes: Sequence[Node]) -> list[frozenset[str] | None]:
    """Variables defined on every path from node 0 to the entry of each node (None: unreachable)."""
    preds: list[list[int]] = [[] for _ in nodes]
    for k, n in enumerate(nodes):
        for s in n.succ:
            preds[s].append(k)
    state_in: list[frozenset[str] | None] = [None] * len(nodes)
    state_in[0] = frozenset()
    work = [0]
    queued = {0}
    while work:
        k = work.pop()
        queued.discard(k)
        cur = state_in[k]
        assert cur is not None
        out = cur | nodes[k].defs
        for s in nodes[k].succ:
            old = state_in[s]
            new = out if old is None else old & out
            if new != old:
                state_in[s] = new
                if s not in queued:
                    queued.add(s)
                    work.append(s)
    return state_in


@dataclass(frozen=True)
class _Summary:
    reads: frozenset[str]  # Shared globals read before written (transitively)
    writes: frozenset[str]  # Shared globals written, elements included (transitively)
    statics: frozenset[str]  # "<PROC>.<fbc name>" of the Static variables (transitively)


class _Procedures:
    """Per-procedure summaries of the GEF procedures, memoised per instance."""

    def __init__(self, program: Program) -> None:
        self.program = program
        self._done: dict[str, _Summary] = {}
        self._active: list[str] = []

    def summary(self, name: str) -> _Summary:
        found = self._done.get(name)
        if found is not None:
            return found
        if name in self._active:
            cycle = " -> ".join([*self._active[self._active.index(name) :], name])
            raise FbsrcError(f"recursive procedures are not supported: {cycle}")
        self._active.append(name)
        try:
            p = self.program
            first, end = p.functions[name]
            nodes = build_nodes(p.statements(first, end), p.arrays, p.functions)
            state = must_defined(nodes) if nodes else []
            reads: set[str] = set()
            writes: set[str] = set()
            statics = {f"{name}.{v}" for v in p.function_statics(name)}
            for n, st in zip(nodes, state, strict=True):
                writes.update(v for v in n.defs | n.element_writes | n.byref if v.endswith("$"))
                for c in n.calls:
                    sub = self.summary(c)
                    writes.update(sub.writes)
                    statics.update(sub.statics)
                    if st is not None:
                        reads.update(v for v in sub.reads if v not in st)
                if st is not None:
                    reads.update(v for v in n.uses if v.endswith("$") and v not in st)
            result = _Summary(frozenset(reads), frozenset(writes), frozenset(statics))
        finally:
            self._active.pop()
        self._done[name] = result
        return result


@cache
def program_for(patch_dir: Path | None = None) -> Program:
    return Program(emit(patch_dir))


def c_span(program: Program, file: str, first: int, last: int) -> tuple[int, int]:
    """0-based ``[start, end)`` of the C stretch generated from ``file:first-last``."""
    run = [d for d in program.index.directives if d.file == file and first <= d.line <= last]
    if not run:
        raise FbsrcError(f"{file}:{first}-{last} generated no C")
    start, end = run[0].index, run[-1].end
    for d in program.index.directives:
        if start <= d.index < end and not (d.file == file and first <= d.line <= last):
            where = f"GEF.c:{d.index + 1} is {d.file}:{d.line}"
            raise FbsrcError(f"{file}:{first}-{last} is not one C stretch: {where}")
    return start, end


def analyse(location: str, patch_dir: Path | None = None) -> Analysis:
    file, first, last = parse_location(location)
    program = program_for(patch_dir)
    file = resolve_source_name(file, GEF_SOURCE_DIR)
    start, end = c_span(program, file, first, last)
    stmts = program.statements(start, end)
    nodes = build_nodes(stmts, program.arrays, program.functions)
    state = must_defined(nodes)
    procs = _Procedures(program)
    seen: set[str] = set()
    reads: list[Read] = []
    called: set[str] = set()
    for n, st in zip(nodes, state, strict=True):
        if st is None:
            continue
        site = (n.stmt.basic_file, n.stmt.basic_line, n.stmt.c_line)
        for v in sorted(n.uses):
            if v not in st and v not in seen:
                seen.add(v)
                reads.append(Read(v, *site, "", v in n.byref))
        for c in n.calls:
            called.add(c)
            for v in sorted(procs.summary(c).reads):
                if v not in st and v not in seen:
                    seen.add(v)
                    reads.append(Read(v, *site, c, False))
    statics = {
        c: tuple(sorted(procs.summary(c).statics))
        for c in sorted(called)
        if procs.summary(c).statics
    }
    callee_writes = {
        n.stmt.c_line: tuple((c, procs.summary(c).writes) for c in n.calls)
        for n in nodes
        if n.calls
    }
    return Analysis(file, start + 1, end, tuple(nodes), tuple(reads), statics, callee_writes)


def basic_spelling(program: Program, var: str) -> str:
    """BASIC spelling of an fbc name: a local's from its declaration line, a ``Shared`` global's
    (declared by fbc at the end of the file) from the fbdef index."""
    base = var.split("$", 1)[0]
    decl = program.decl_line.get(var)
    if decl is not None and decl[1] > 0 and not var.endswith("$"):
        try:
            name = resolve_source_name(decl[0], GEF_SOURCE_DIR)
            text = read_source_lines(GEF_SOURCE_DIR / name)[decl[1] - 1]
            m = re.search(rf"(?<![\w]){re.escape(base)}(?![\w])", text, re.IGNORECASE)
            if m is not None:
                return m.group(0)
        except FbsrcError, IndexError:
            pass
    tags = sorted(
        (t for t in load_index() if t.name.upper() == base),
        key=lambda t: (t.role != "def", t.path != "GEF.bas", t.line),
    )
    return tags[0].name if tags else base


@dataclass(frozen=True)
class Write:
    basic_line: int
    target: str  # BASIC text of the written element for arrays, "" for scalars
    via: str = ""  # the procedure called at the line when the write happens inside it


def writers(analysis: Analysis, program: Program) -> dict[str, list[Write]]:
    """The writes of each variable in the stretch, in program order: assignments, element writes,
    ``ByRef`` arguments (the procedure may write them) and the ``Shared`` globals a called
    procedure writes (``via``). Element writes through a pointer passed to a runtime function
    (``fb_DataReadSingle( (float*)… )``) are not seen."""
    source = read_source_lines(GEF_SOURCE_DIR / analysis.file)
    out: dict[str, list[Write]] = {}

    def add(v: str, write: Write) -> None:
        ws = out.setdefault(v, [])
        if not ws or (ws[-1].basic_line, ws[-1].via) != (write.basic_line, write.via):
            ws.append(write)

    for n in analysis.nodes:
        line = n.stmt.basic_line
        for v in sorted(n.scalar_writes | n.byref):  # a ByRef argument may be written
            add(v, Write(line, ""))
        for v in sorted(n.element_writes):
            add(v, Write(line, _element_target(source[line - 1], basic_spelling(program, v))))
        for proc, written in analysis.callee_writes.get(n.stmt.c_line, ()):
            for v in sorted(written):
                add(v, Write(line, "", proc))
    return out


def _element_target(text: str, name: str) -> str:
    m = re.search(rf"(?<![\w]){re.escape(name)}\s*\(", text, re.IGNORECASE)
    if m is None:
        return ""
    depth = 0
    for i in range(m.end() - 1, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return re.sub(r"\s+", "", text[m.start() : i + 1])
    return ""


def escapes(
    analysis: Analysis, program: Program, variables: Iterable[str]
) -> dict[str, list[tuple[str, int]]]:
    """BASIC lines outside the stretch whose C reads each variable (module code and procedure
    bodies). A superset of the values later code consumes: a site may read only what its own
    code wrote first."""
    wanted = set(variables)
    out: dict[str, set[tuple[str, int]]] = {v: set() for v in wanted}
    lo, hi = analysis.c_first - 1, analysis.c_last
    for part in (program.statements(0, lo), program.statements(hi, len(program.index.lines))):
        for node in build_nodes(part, program.arrays, program.functions):
            if node.stmt.basic_line <= 0:
                continue
            for v in node.uses & wanted:
                out[v].add((node.stmt.basic_file, node.stmt.basic_line))
    return {v: sorted(locs) for v, locs in out.items()}


def _ranges(lines: Sequence[int]) -> str:
    parts: list[str] = []
    start = prev = None
    for n in lines:
        if start is None:
            start = prev = n
        elif prev is not None and n == prev + 1:
            prev = n
        else:
            parts.append(f"{start}" if start == prev else f"{start}-{prev}")
            start = prev = n
    if start is not None:
        parts.append(f"{start}" if start == prev else f"{start}-{prev}")
    return ",".join(parts)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.fbsrc.rbw",
        description="Read-before-write, writer and escape analysis of GEF's emitted C.",
    )
    parser.add_argument("mode", choices=("reads", "writers", "escapes"))
    parser.add_argument("location", help="<file>:<first>-<last>, e.g. GEF.bas:5578-7920")
    parser.add_argument("--json", action="store_true", help="machine-readable output")
    parser.add_argument("--patch-dir", type=Path, help="analyse the emission of this patch dir")
    args = parser.parse_args(argv)
    mode: str = args.mode
    patch_dir: Path | None = args.patch_dir
    try:
        analysis = analyse(args.location, patch_dir)
    except FbsrcError as exc:
        print(f"rbw: {exc}", file=sys.stderr)
        return EXIT_ERROR
    program = program_for(patch_dir)
    if mode == "reads":
        rows = [
            {
                "variable": r.variable,
                "basic": basic_spelling(program, r.variable),
                "type": program.type_code(r.variable),
                "line": f"{r.basic_file}:{r.basic_line}",
                "c_line": r.c_line,
                "via": r.via,
                "byref": r.byref,
            }
            for r in analysis.reads
        ]
        if args.json:
            json.dump({"reads": rows, "statics": analysis.statics}, sys.stdout, indent=1)
            sys.stdout.write("\n")
        else:
            for row in rows:
                via = f" via {row['via']}" if row["via"] else ""
                ref = " byref" if row["byref"] else ""
                head = f"{row['basic']:<24} {row['type']} {row['variable']:<26} {row['line']}"
                print(f"{head}{via}{ref}")
            for proc, sts in analysis.statics.items():
                print(f"static {proc}: {' '.join(sts)}")
    elif mode == "writers":
        ws = writers(analysis, program)
        if args.json:
            records = [
                {
                    "variable": v,
                    "basic": basic_spelling(program, v),
                    "writes": [
                        {"line": w.basic_line, "target": w.target, "via": w.via} for w in lst
                    ],
                }
                for v, lst in ws.items()
            ]
            json.dump(records, sys.stdout, indent=1)
            sys.stdout.write("\n")
        else:
            for v, lst in ws.items():
                text = " ".join(
                    f"{w.basic_line}{'=' + w.target if w.target else ''}"
                    f"{'@' + w.via if w.via else ''}"
                    for w in lst
                )
                print(f"{basic_spelling(program, v):<24} {v:<26} {text}")
    else:
        ws = writers(analysis, program)
        es = escapes(analysis, program, ws)
        if args.json:
            records = [
                {
                    "variable": v,
                    "basic": basic_spelling(program, v),
                    "reads": [f"{f}:{n}" for f, n in locs],
                }
                for v, locs in es.items()
            ]
            json.dump(records, sys.stdout, indent=1)
            sys.stdout.write("\n")
        else:
            for v in ws:
                locs = es[v]
                by_file: dict[str, list[int]] = {}
                for f, n in locs:
                    by_file.setdefault(f, []).append(n)
                text = "; ".join(f"{f}:{_ranges(ns)}" for f, ns in by_file.items())
                print(f"{basic_spelling(program, v):<24} {v:<26} {text or '-'}")
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
