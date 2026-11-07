#!/usr/bin/env python3
"""Check a DBC (Driven by Concepts) reference set for drift.

Usage: ``python3 <dbc-dir>/check_dbc.py [--root PATH]``. The DBC directory is
the directory holding this script. The repository root is ``--root``, else the
git top level of the DBC directory, else the DBC directory's parent. Use
``--dbc DIR`` to override the directory holding this script. Paths in
the DBC files are relative to the repository root unless they are Markdown
link targets (relative to the linking file).

Exit 0: no drift; prints one summary line
``check_dbc: ok — <N> nodes (L1 a, L2 b, …), <C> code rows, <T> test rows,
<E> evidence sections``.
Exit 1: drift; one line per problem, ``<path>:<line>: <message>`` with the path
relative to the repository root, then ``check_dbc: <K> problems``.
Exit 2: the config or a DBC file is missing or unreadable.
Notices (``<path>:<line>: note: <message>``) never change the exit code.
Python 3.11+, standard library only.

Config: ``dbc.toml`` beside this script.
- ``project`` (required): the title of the L1 diagram.
- ``evidence`` (required): file name of the evidence file, e.g.
  ``FIXTURES.md``, ``EXERCISES.md``, ``SCENARIOS.md``.
- ``evidence_fields`` (default ``["Concepts", "Comments"]``; ``Concepts`` is
  always required): ``**<Field>:**`` lines every evidence section carries.
- ``test_globs``, ``evidence_globs`` (default ``[]``): repository-relative
  globs (``**`` allowed); every matching file is cited as a backticked path in
  TESTS.md or the evidence file respectively.
- ``banned_patterns`` (default ``[]``): regular expressions that must not
  match any line of the concept files (plan or milestone names, e.g.
  ``"\\bM[0-9]+\\b"``).
- ``min_nodes`` (default 3), ``max_nodes`` (default 12): bounds on the owned
  nodes of every diagram.
- ``review_depth`` (default 5): diagrams deeper than this get a notice asking
  whether the level is still a concept or already code. Never a failure.
Unknown keys are a config error (exit 2).

Files: ``CONCEPTS.md``, ``CODE.md``, ``DEFINITIONS.md``, ``TESTS.md`` and the
evidence file, in the DBC directory. Each links to the other four with
relative Markdown links. Every relative link or image target in any DBC file
(concept files included) exists; ``#anchors`` are ignored.

Concept files
- ``CONCEPTS.md`` plus, optionally, subtree files ``concepts/*.md``, read in
  that order (subtree files sorted by name). Each subtree file is linked from
  CONCEPTS.md and links back to it. Node IDs, statuses and diagrams are one
  namespace across all concept files.
- Levels are not capped. A diagram heading is ``L<n> · <title>`` for a
  structure diagram or ``L<n> rule · <title>`` for a rule diagram, at Markdown
  heading depth ``min(n + 1, 6)``. For n ≥ 2 the heading ends with
  `` (`ParentID`)``. Other headings are prose and ignored.
- Exactly one L1 diagram, in CONCEPTS.md, titled with ``project``; it is a
  structure diagram. The parent of an L<n> diagram is an owned node of a
  structure diagram at level n − 1. A node has at most one child diagram.
  Every owned L1 node has a child diagram. Nodes owned by a rule diagram have
  no child diagram.
- Each diagram has exactly one mermaid block. Structure diagrams start
  ``flowchart LR`` or ``flowchart TD``; rule diagrams start ``flowchart TD``.
  Allowed lines: node declarations ``ID["label"]`` (also ``("…")``,
  ``{"…"}``, ``(["…"])``, ``[("…")]``, ``{{"…"}}``); edges ``-->``,
  ``-.->``, ``==>``, ``---``, ``-.-`` with optional ``|label|`` and ``&``
  chains, endpoints declared IDs; ``subgraph ID["label"]`` … ``end``;
  ``classDef``; ``class ID[,ID] status``; ``style``, ``linkStyle``,
  ``direction``; ``%%`` comments; blank lines.
- Each diagram has exactly one node table ``| Node | Meaning | Terms | Status |``
  with exactly one row per declared mermaid node (subgraph IDs excluded); the
  row's backticked ID is declared in that diagram's block.
- Node IDs match ``[A-Za-z][A-Za-z0-9]*`` and are owned by exactly one
  diagram. Status is ``implemented`` (built), ``partial`` (in the current
  work unit: the submilestone, or milestone, now in progress, whether or not
  any of it is built yet), ``planned`` (not started and not in the current
  work unit) or ``external``. An ``external`` row shows a node owned by
  another diagram, for context; its ID is owned somewhere. Every node in a
  diagram carries exactly one status class matching its table row,
  ``class X implemented|partial|planned|external``, and every diagram
  declares the four ``classDef`` lines from SKILL.md verbatim (implemented
  green, partial yellow, planned uncolored with a dashed border, external
  grey and dotted).
- Every diagram owns between ``min_nodes`` and ``max_nodes`` nodes.
- Every owned node has a non-empty Meaning and at least one term in Terms
  (``, ``-separated); every term is defined in DEFINITIONS.md.
- Parent and child statuses agree, between a node and the owned nodes of its
  child diagram, with the order planned < implemented < partial: the parent's
  status is the highest status among those children. Any partial child makes
  the parent partial; otherwise any implemented child makes it implemented
  (its planned children are extensions not yet started); a parent whose
  children are all planned is planned.
- No line of a concept file matches a ``banned_patterns`` expression.

CODE.md
- Tables headed ``| Node | Code | Notes |``, one backticked owned node per
  row; never an L1 node or a planned node. A node may have several rows.
- The Code cell holds backticked tokens. A path token contains ``/`` or
  names an existing file or directory at the repository root; it starts a
  group, and the tokens after it, up to the next path token, are symbols that
  occur as whole words in that file (none after a directory). A cell starts
  with a path token. Missing paths, missing symbols and line references
  (``:<digits>``, ``L<digits>``, ``line <digits>``) are problems.
- A code-mapped node is an implemented node at level ≥ 2, owned by a
  structure diagram, with no child diagram or a rule diagram as its child.
  Every code-mapped node has at least one row. Other implemented nodes and
  partial nodes may have rows; planned nodes never do.

DEFINITIONS.md
- The first column of every table whose first header cell is ``Term`` is a
  term. ``", "`` and ``" / "`` separate alternative forms; backticks are
  ignored; a trailing ``(…)`` is optional when matching; matching is
  case-insensitive. A form defined twice is a problem.

TESTS.md
- Every table has a ``Concepts`` column; each row names at least one
  backticked owned node ID there, and every backticked token in that cell is
  an owned node ID.
- In the first column, a backticked token containing ``/`` is a path
  (optionally with a ``::`` suffix) that exists.
- Every file matching ``test_globs`` appears as a backticked path (optionally
  with a ``::`` suffix) somewhere in TESTS.md.

Evidence file
- Every ``## `` section has a line starting ``**<Field>:**`` for each
  ``evidence_fields`` entry. The ``**Concepts:**`` line names at least one
  backticked owned node ID, and every backticked token on it is an owned
  node ID.
- Every table with a ``Concepts`` column follows the TESTS.md rule for that
  column.
- Every file matching ``evidence_globs`` appears as a backticked path
  somewhere in the evidence file.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from collections.abc import Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import cast
from urllib.parse import unquote

import tomllib

STATUSES = {"implemented", "partial", "planned", "external"}
STATUS_RANK = {"planned": 0, "implemented": 1, "partial": 2}
NODE_ID = r"[A-Za-z][A-Za-z0-9]*"
NODE_DECLARATION = re.compile(
    r"""
    ([A-Za-z][A-Za-z0-9]*)
    (?:
        \["[^"]*"\]
        | \("[^"]*"\)
        | \{"[^"]*"\}
        | \(\["[^"]*"\]\)
        | \[\("[^"]*"\)\]
        | \{\{"[^"]*"\}\}
    )
    """,
    re.VERBOSE,
)
TABLE_SEPARATOR = re.compile(r":?-{3,}:?")
ANY_HEADING = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
DIAGRAM_HEADING = re.compile(r"^L([1-9][0-9]*)( rule)? · (.+?)$")
CONFIG_KEYS = {
    "project",
    "evidence",
    "evidence_fields",
    "test_globs",
    "evidence_globs",
    "banned_patterns",
    "min_nodes",
    "max_nodes",
    "review_depth",
}
BASE_FILES = ("CONCEPTS.md", "CODE.md", "DEFINITIONS.md", "TESTS.md")
NODE_TABLE_HEADER = ["Node", "Meaning", "Terms", "Status"]
CODE_TABLE_HEADER = ["Node", "Code", "Notes"]
CLASS_DEFS = (
    "classDef implemented fill:#c8e6c9,stroke:#2e7d32,color:#1b5e20",
    "classDef partial fill:#fff3b0,stroke:#b58900,color:#5c4400",
    "classDef planned stroke-dasharray:6 4",
    "classDef external fill:#eeeeee,stroke:#9e9e9e,stroke-dasharray:1 3,color:#616161",
)


@dataclass(frozen=True)
class Problem:
    filename: str
    line: int
    message: str


@dataclass(frozen=True)
class Notice:
    filename: str
    line: int
    message: str


@dataclass(frozen=True)
class Table:
    line: int
    header: list[str]
    rows: list[tuple[int, list[str]]]


@dataclass(frozen=True)
class Config:
    project: str
    evidence: str
    evidence_fields: list[str]
    test_globs: list[str]
    evidence_globs: list[str]
    banned_patterns: list[re.Pattern[str]]
    min_nodes: int
    max_nodes: int
    review_depth: int


@dataclass(frozen=True)
class Node:
    identifier: str
    status: str
    level: int
    diagram_index: int
    line: int
    filename: str


@dataclass
class Diagram:
    level: int
    kind: str
    title: str
    parent: str | None
    filename: str
    line: int
    start: int
    end: int
    declared: set[str] = field(default_factory=set)
    nodes: dict[str, Node] = field(default_factory=dict)
    classes: dict[str, list[str]] = field(
        default_factory=lambda: {status: [] for status in STATUSES}
    )


def display_path(prefix: str, filename: str) -> str:
    return f"{prefix}/{filename}" if prefix else filename


def add_problem(
    problems: list[Problem], filename: str, line: int, message: str
) -> None:
    problems.append(Problem(filename, max(1, line), message))


def split_cells(line: str) -> list[str]:
    value = line.strip().removeprefix("|").removesuffix("|")
    return [cell.strip() for cell in value.split("|")]


def markdown_tables(lines: list[str]) -> list[Table]:
    tables: list[Table] = []
    index = 0
    while index + 1 < len(lines):
        if "|" not in lines[index]:
            index += 1
            continue
        separator = split_cells(lines[index + 1])
        if not separator or not all(
            TABLE_SEPARATOR.fullmatch(part) for part in separator
        ):
            index += 1
            continue
        header = split_cells(lines[index])
        rows: list[tuple[int, list[str]]] = []
        row_index = index + 2
        while row_index < len(lines) and "|" in lines[row_index]:
            rows.append((row_index + 1, split_cells(lines[row_index])))
            row_index += 1
        tables.append(Table(index + 1, header, rows))
        index = row_index
    return tables


def headings(lines: list[str]) -> list[tuple[int, int, str]]:
    found: list[tuple[int, int, str]] = []
    fence_char: str | None = None
    fence_length = 0
    for index, line in enumerate(lines):
        fence = re.match(r"^\s*(`{3,}|~{3,})", line)
        if fence:
            marker = fence.group(1)
            if fence_char is None:
                fence_char = marker[0]
                fence_length = len(marker)
            elif marker[0] == fence_char and len(marker) >= fence_length:
                fence_char = None
            continue
        if fence_char is not None:
            continue
        match = ANY_HEADING.match(line)
        if match:
            found.append((index, len(match.group(1)), match.group(2).strip()))
    return found


def term_forms(value: str) -> set[str]:
    pieces = re.split(r", | / ", value.replace("`", "").strip())
    forms: set[str] = set()
    for piece in pieces:
        clean = piece.strip()
        if not clean:
            continue
        forms.add(clean.casefold())
        optional = re.sub(r"\s*\([^()]*\)\s*$", "", clean).strip()
        if optional != clean:
            forms.add(optional.casefold())
    return forms


def config_string_list(raw: object, key: str) -> list[str]:
    if not isinstance(raw, list):
        raise TypeError(f"{key} must be an array of non-empty strings")
    items = cast(list[object], raw)
    values: list[str] = []
    for item in items:
        if not isinstance(item, str) or not item:
            raise TypeError(f"{key} must be an array of non-empty strings")
        values.append(item)
    return values


def read_config(path: Path) -> Config:
    try:
        with path.open("rb") as stream:
            raw = cast(dict[str, object], tomllib.load(stream))
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise ValueError(f"cannot read config {path.name}: {error}") from error
    unknown = sorted(set(raw) - CONFIG_KEYS)
    if unknown:
        raise ValueError(f"unknown config key(s): {', '.join(unknown)}")
    missing = [key for key in ("project", "evidence") if key not in raw]
    if missing:
        raise ValueError(f"missing required config key(s): {', '.join(missing)}")
    project = raw["project"]
    evidence = raw["evidence"]
    if not isinstance(project, str) or not project.strip():
        raise ValueError("project must be a non-empty string")
    if (
        not isinstance(evidence, str)
        or not evidence.endswith(".md")
        or Path(evidence).name != evidence
    ):
        raise ValueError("evidence must be a Markdown file name")
    if evidence in BASE_FILES:
        raise ValueError("evidence must be distinct from the four standard DBC files")

    evidence_fields = config_string_list(
        raw.get("evidence_fields", ["Concepts", "Comments"]), "evidence_fields"
    )
    if "Concepts" not in evidence_fields:
        evidence_fields = ["Concepts", *evidence_fields]
    test_globs = config_string_list(raw.get("test_globs", []), "test_globs")
    evidence_globs = config_string_list(raw.get("evidence_globs", []), "evidence_globs")
    banned_raw = config_string_list(raw.get("banned_patterns", []), "banned_patterns")
    try:
        banned_patterns = [re.compile(pattern) for pattern in banned_raw]
    except re.error as error:
        raise ValueError(f"invalid banned_patterns expression: {error}") from error

    def integer(key: str, default: int) -> int:
        value = raw.get(key, default)
        if isinstance(value, bool) or not isinstance(value, int):
            raise TypeError(f"{key} must be an integer")
        return value

    min_nodes = integer("min_nodes", 3)
    max_nodes = integer("max_nodes", 12)
    review_depth = integer("review_depth", 5)
    if min_nodes < 1 or max_nodes < min_nodes:
        raise ValueError(
            "min_nodes and max_nodes must be positive and min_nodes <= max_nodes"
        )
    if review_depth < 1:
        raise ValueError("review_depth must be a positive integer")
    return Config(
        project,
        evidence,
        evidence_fields,
        test_globs,
        evidence_globs,
        banned_patterns,
        min_nodes,
        max_nodes,
        review_depth,
    )


def definition_forms(
    lines: list[str], filename: str, problems: list[Problem]
) -> set[str]:
    definitions: dict[str, int] = {}
    for table in markdown_tables(lines):
        if not table.header or table.header[0] != "Term":
            continue
        for row_line, row in table.rows:
            if not row:
                continue
            for form in term_forms(row[0]):
                if form in definitions:
                    add_problem(
                        problems,
                        filename,
                        row_line,
                        f"term form {form!r} is defined more than once "
                        + f"(first at line {definitions[form]})",
                    )
                else:
                    definitions[form] = row_line
    return set(definitions)


def parse_diagram_heading(
    text: str,
) -> tuple[int, str, str, str | None] | None:
    match = DIAGRAM_HEADING.fullmatch(text)
    if match is None:
        return None
    level = int(match.group(1))
    kind = "rule" if match.group(2) else "structure"
    title_text = match.group(3).strip()
    if level == 1:
        return level, kind, title_text, None
    parent_match = re.fullmatch(r"(.+?)\s+\(`(" + NODE_ID + r")`\)", title_text)
    if parent_match is None:
        return level, kind, title_text, None
    return level, kind, parent_match.group(1).strip(), parent_match.group(2)


def parse_edge_tokens(tokens: list[str], arrows: tuple[str, ...]) -> list[str] | None:
    index = 0
    endpoints: list[str] = []

    def take_endpoint() -> bool:
        nonlocal index
        if index >= len(tokens) or re.fullmatch(NODE_ID, tokens[index]) is None:
            return False
        endpoints.append(tokens[index])
        index += 1
        return True

    def take_group() -> bool:
        nonlocal index
        if not take_endpoint():
            return False
        while index < len(tokens) and tokens[index] == "&":
            index += 1
            if not take_endpoint():
                return False
        return True

    valid = take_group()
    found_arrow = False
    while valid and index < len(tokens):
        if tokens[index] not in arrows:
            return None
        found_arrow = True
        index += 1
        valid = take_group()
    if valid and found_arrow and index == len(tokens):
        return endpoints
    return None


def parse_mermaid(
    lines: list[str],
    start: int,
    filename: str,
    kind: str,
    problems: list[Problem],
) -> tuple[set[str], dict[str, list[str]]]:
    declared: set[str] = set()
    classes: dict[str, list[str]] = {status: [] for status in STATUSES}
    class_definitions: list[tuple[str, int]] = []
    subgraphs: set[str] = set()
    endpoints: list[tuple[str, int]] = []
    body: list[tuple[int, str]] = []
    close = start + 1
    while close < len(lines) and not re.fullmatch(r"\s*```\s*", lines[close]):
        body.append((close + 1, lines[close]))
        close += 1
    if close == len(lines):
        add_problem(problems, filename, start + 1, "unclosed ```mermaid fence")

    allowed_starts = (
        {"flowchart TD"} if kind == "rule" else {"flowchart LR", "flowchart TD"}
    )
    if not body or body[0][1].strip() not in allowed_starts:
        expectation = (
            "'flowchart TD'" if kind == "rule" else "'flowchart LR' or 'flowchart TD'"
        )
        add_problem(
            problems,
            filename,
            body[0][0] if body else start + 1,
            f"{kind} diagram mermaid block must start with {expectation}",
        )

    subgraph_depth = 0
    arrows = ("-->", "-.->", "==>", "---", "-.-")
    arrow_pattern = "|".join(re.escape(arrow) for arrow in arrows)
    token_pattern = re.compile(r"\s*(-->|-\.->|==>|---|-\.-|&|[A-Za-z][A-Za-z0-9]*)")
    for line_number, raw_line in body[1:]:
        text = raw_line.strip()
        if not text or text.startswith("%%"):
            continue
        if re.match(r"^classDef\b", text):
            class_definitions.append((" ".join(text.split()), line_number))
            continue
        if re.match(r"^style\b|^linkStyle\b|^direction\b", text):
            continue
        subgraph = re.fullmatch(r"subgraph\s+(" + NODE_ID + r")\[\"[^\"]*\"\]", text)
        if subgraph:
            subgraphs.add(subgraph.group(1))
            subgraph_depth += 1
            continue
        if text == "end":
            if subgraph_depth == 0:
                add_problem(
                    problems, filename, line_number, "unmatched mermaid subgraph 'end'"
                )
            else:
                subgraph_depth -= 1
            continue
        declaration = NODE_DECLARATION.fullmatch(text)
        if declaration:
            declared.add(declaration.group(1))
            continue
        class_match = re.fullmatch(
            r"class\s+([A-Za-z][A-Za-z0-9]*(?:\s*,\s*[A-Za-z][A-Za-z0-9]*)*)"
            + r"\s+([A-Za-z][A-Za-z0-9_]*)",
            text,
        )
        if class_match:
            status = class_match.group(2)
            if status in classes:
                for identifier in re.split(r"\s*,\s*", class_match.group(1)):
                    classes[status].append(identifier)
            else:
                add_problem(
                    problems,
                    filename,
                    line_number,
                    f"unrecognised mermaid status class {status!r}",
                )
            continue

        inline_declarations = list(NODE_DECLARATION.finditer(text))
        labelled = text
        for declaration in reversed(inline_declarations):
            identifier = declaration.group(1)
            declared.add(identifier)
            labelled = (
                labelled[: declaration.start()]
                + identifier
                + labelled[declaration.end() :]
            )
        labelled = re.sub(r"(" + arrow_pattern + r")\|[^|]*\|", r"\1", labelled)
        tokens: list[str] = []
        position = 0
        token_error = False
        while position < len(labelled):
            match = token_pattern.match(labelled, position)
            if match is None:
                token_error = True
                break
            tokens.append(match.group(1))
            position = match.end()
        if "|" in labelled:
            token_error = True
        if not token_error and tokens:
            parsed_endpoints = parse_edge_tokens(tokens, arrows)
            if parsed_endpoints is not None:
                endpoints.extend(
                    (endpoint, line_number) for endpoint in parsed_endpoints
                )
                continue
        add_problem(
            problems, filename, line_number, f"unrecognised mermaid line: {text!r}"
        )

    if subgraph_depth:
        add_problem(problems, filename, start + 1, "mermaid subgraph is missing 'end'")
    for expected in CLASS_DEFS:
        matches = [
            line for definition, line in class_definitions if definition == expected
        ]
        if len(matches) != 1:
            add_problem(
                problems,
                filename,
                matches[1]
                if len(matches) > 1
                else (class_definitions[0][1] if class_definitions else start + 1),
                f"mermaid classDef must declare exactly once: {expected}",
            )
    for definition, line in class_definitions:
        if definition not in CLASS_DEFS:
            add_problem(
                problems,
                filename,
                line,
                f"unexpected or altered mermaid classDef line: {definition}",
            )
    for endpoint, line_number in endpoints:
        if endpoint not in declared and endpoint not in subgraphs:
            add_problem(
                problems,
                filename,
                line_number,
                f"mermaid edge references undeclared node or subgraph ID {endpoint}",
            )
    return declared, classes


def parse_concepts(
    documents: dict[str, list[str]],
    definition_names: set[str],
    config: Config,
    prefix: str,
    problems: list[Problem],
    notices: list[Notice],
) -> tuple[list[Diagram], dict[str, Node]]:
    diagrams: list[Diagram] = []
    for relative_filename, lines in documents.items():
        filename = display_path(prefix, relative_filename)
        all_headings = headings(lines)
        starts: list[tuple[int, int, int, str, str, str, str | None]] = []
        for index, heading_depth, text in all_headings:
            parsed = parse_diagram_heading(text)
            if parsed is None:
                if re.match(r"^L[0-9]+(?: rule)? ·", text):
                    add_problem(
                        problems,
                        filename,
                        index + 1,
                        f"malformed diagram heading {text!r}",
                    )
                continue
            level, kind, title, parent = parsed
            starts.append((index, heading_depth, level, kind, title, text, parent))
            expected_depth = min(level + 1, 6)
            if heading_depth != expected_depth:
                add_problem(
                    problems,
                    filename,
                    index + 1,
                    f"L{level} diagram heading must use Markdown depth {expected_depth}",
                )

        level_one = [item for item in starts if item[2] == 1]
        if relative_filename == "CONCEPTS.md" and len(level_one) != 1:
            line = level_one[1][0] + 1 if len(level_one) > 1 else 1
            add_problem(
                problems,
                filename,
                line,
                f"CONCEPTS.md must contain exactly one L1 heading; found {len(level_one)}",
            )
        if relative_filename != "CONCEPTS.md" and level_one:
            add_problem(
                problems,
                filename,
                level_one[0][0] + 1,
                "the L1 diagram must be in CONCEPTS.md",
            )

        for start_index, item in enumerate(starts):
            index, _heading_depth, level, kind, title, _text, parent = item
            line = index + 1
            if level == 1:
                if title != config.project:
                    add_problem(
                        problems,
                        filename,
                        line,
                        f"the L1 diagram title must be {config.project!r}",
                    )
                if kind != "structure":
                    add_problem(
                        problems,
                        filename,
                        line,
                        "the L1 diagram must be a structure diagram",
                    )
            elif parent is None:
                add_problem(
                    problems,
                    filename,
                    line,
                    f"L{level} diagram heading must end with its parent node ID in backticks",
                )
            end = (
                starts[start_index + 1][0]
                if start_index + 1 < len(starts)
                else len(lines)
            )
            diagram = Diagram(
                level,
                kind,
                title,
                parent,
                filename,
                line,
                index,
                end,
            )
            diagrams.append(diagram)
            if level > config.review_depth:
                notices.append(
                    Notice(
                        filename,
                        line,
                        f"L{level} is deeper than review_depth {config.review_depth}; "
                        + "review whether it is still a concept or already code",
                    )
                )

            section = lines[index:end]
            mermaid_starts = [
                index + offset
                for offset, text in enumerate(section)
                if re.fullmatch(r"\s*```mermaid\s*", text)
            ]
            if len(mermaid_starts) != 1:
                add_problem(
                    problems,
                    filename,
                    line,
                    f"L{level} diagram must contain exactly one ```mermaid block; found {len(mermaid_starts)}",
                )
            if mermaid_starts:
                declared, classes = parse_mermaid(
                    lines, mermaid_starts[0], filename, kind, problems
                )
                diagram.declared = declared
                diagram.classes = classes
                for status, identifiers in classes.items():
                    for identifier in sorted(set(identifiers) - declared):
                        add_problem(
                            problems,
                            filename,
                            line,
                            f"mermaid class {status} references undeclared node ID {identifier}",
                        )

            tables = [
                table
                for table in markdown_tables(section)
                if table.header == NODE_TABLE_HEADER
            ]
            if len(tables) != 1:
                add_problem(
                    problems,
                    filename,
                    line,
                    f"L{level} diagram must contain exactly one node table headed "
                    + "'| Node | Meaning | Terms | Status |'; "
                    + f"found {len(tables)}",
                )
            if tables:
                for relative_line, row in tables[0].rows:
                    row_line = index + relative_line
                    if len(row) != 4:
                        add_problem(
                            problems,
                            filename,
                            row_line,
                            "node table row must have Node, Meaning, Terms, and Status cells",
                        )
                        continue
                    id_match = re.fullmatch(r"`(" + NODE_ID + r")`", row[0])
                    if id_match is None:
                        add_problem(
                            problems,
                            filename,
                            row_line,
                            f"node table ID must be one backticked ID, found {row[0]!r}",
                        )
                        continue
                    identifier = id_match.group(1)
                    status = row[3]
                    if status not in STATUSES:
                        add_problem(
                            problems,
                            filename,
                            row_line,
                            f"node {identifier} has invalid status {status!r}; "
                            + "use implemented, partial, planned, or external",
                        )
                    if identifier not in diagram.declared:
                        add_problem(
                            problems,
                            filename,
                            row_line,
                            f"node table ID {identifier} is not declared in this diagram's mermaid block",
                        )
                    if identifier in diagram.nodes:
                        add_problem(
                            problems,
                            filename,
                            row_line,
                            f"node {identifier} has more than one row in this diagram's node table",
                        )
                    if status in STATUSES and status != "external":
                        if not row[1].strip():
                            add_problem(
                                problems,
                                filename,
                                row_line,
                                f"owned node {identifier} must have a non-empty Meaning",
                            )
                        terms = [
                            term.strip() for term in row[2].split(",") if term.strip()
                        ]
                        if not terms:
                            add_problem(
                                problems,
                                filename,
                                row_line,
                                f"owned node {identifier} must list at least one term",
                            )
                        for term in terms:
                            if not (term_forms(term) & definition_names):
                                add_problem(
                                    problems,
                                    filename,
                                    row_line,
                                    f"node {identifier} uses unknown term {term.replace('`', '')!r} in its Terms cell",
                                )
                    node = Node(
                        identifier,
                        status,
                        level,
                        len(diagrams) - 1,
                        row_line,
                        filename,
                    )
                    diagram.nodes[identifier] = node
                    actual_classes = [
                        class_status
                        for class_status, identifiers in diagram.classes.items()
                        for class_identifier in identifiers
                        if class_identifier == identifier
                    ]
                    if actual_classes != [status]:
                        actual = ", ".join(actual_classes) or "no status class"
                        add_problem(
                            problems,
                            filename,
                            row_line,
                            f"node {identifier} has status {status!r} but mermaid "
                            + f"status classes are {actual}; expected exactly one {status} class",
                        )
            for identifier in sorted(diagram.declared - set(diagram.nodes)):
                add_problem(
                    problems,
                    filename,
                    line,
                    f"mermaid node ID {identifier} has no row in this diagram's node table",
                )
            owned_count = sum(
                node.status in STATUSES and node.status != "external"
                for node in diagram.nodes.values()
            )
            if not config.min_nodes <= owned_count <= config.max_nodes:
                add_problem(
                    problems,
                    filename,
                    line,
                    f"L{level} diagram owns {owned_count} nodes; expected between "
                    + f"{config.min_nodes} and {config.max_nodes}",
                )

    owners: dict[str, Node] = {}
    for diagram in diagrams:
        for identifier, node in diagram.nodes.items():
            if node.status == "external" or node.status not in STATUSES:
                continue
            existing = owners.get(identifier)
            if existing is not None and existing.diagram_index != node.diagram_index:
                add_problem(
                    problems,
                    node.filename,
                    node.line,
                    f"node ID {identifier} is owned by more than one diagram",
                )
            else:
                owners[identifier] = node

    for diagram in diagrams:
        for identifier, node in diagram.nodes.items():
            if node.status != "external":
                continue
            owner = owners.get(identifier)
            if owner is None or owner.diagram_index == node.diagram_index:
                add_problem(
                    problems,
                    node.filename,
                    node.line,
                    f"external node {identifier} must be owned by a different diagram "
                    + "with a non-external status",
                )

    child_diagrams: dict[str, list[Diagram]] = {}
    for diagram in diagrams:
        if diagram.level == 1 or diagram.parent is None:
            continue
        child_diagrams.setdefault(diagram.parent, []).append(diagram)
        parent = owners.get(diagram.parent)
        if parent is None:
            add_problem(
                problems,
                diagram.filename,
                diagram.line,
                f"L{diagram.level} diagram parent {diagram.parent} is not an owned node",
            )
            continue
        if parent.level != diagram.level - 1:
            add_problem(
                problems,
                diagram.filename,
                diagram.line,
                f"L{diagram.level} diagram parent {diagram.parent} must be owned at "
                + f"L{diagram.level - 1}; it is owned at L{parent.level}",
            )
        if diagrams[parent.diagram_index].kind != "structure":
            add_problem(
                problems,
                diagram.filename,
                diagram.line,
                f"diagram parent {diagram.parent} is owned by a rule diagram; "
                + "rule diagrams cannot have child diagrams",
            )

    for identifier, children in child_diagrams.items():
        if len(children) > 1:
            parent = owners.get(identifier)
            filename = parent.filename if parent is not None else children[1].filename
            line = parent.line if parent is not None else children[1].line
            add_problem(
                problems,
                filename,
                line,
                f"node {identifier} has {len(children)} child diagrams; at most one is allowed",
            )
    for diagram in diagrams:
        if diagram.level != 1:
            continue
        for identifier, node in diagram.nodes.items():
            if node.status not in STATUSES or node.status == "external":
                continue
            count = len(child_diagrams.get(identifier, []))
            if count != 1:
                add_problem(
                    problems,
                    node.filename,
                    node.line,
                    f"L1 node {identifier} must have exactly one child diagram; found {count}",
                )

    for child in diagrams:
        if child.level == 1 or child.parent is None:
            continue
        parent = owners.get(child.parent)
        if parent is None:
            continue
        child_statuses = {
            node.status
            for node in child.nodes.values()
            if node.status in STATUS_RANK and node.status != "external"
        }
        if not child_statuses:
            continue
        expected = max(child_statuses, key=STATUS_RANK.__getitem__)
        if parent.status != expected:
            add_problem(
                problems,
                child.filename,
                child.line,
                f"parent/child status disagreement for {parent.identifier}: "
                + f"expected {expected!r} from child nodes, found parent {parent.status!r}",
            )
    return diagrams, owners


def node_ids_in_cell(
    cell: str,
    filename: str,
    line: int,
    problems: list[Problem],
    owners: dict[str, Node],
    context: str,
) -> None:
    identifiers = cast(list[str], re.findall(r"`([^`]+)`", cell))
    if not identifiers:
        add_problem(
            problems,
            filename,
            line,
            f"{context} must contain at least one backticked node ID",
        )
        return
    for identifier in identifiers:
        if re.fullmatch(NODE_ID, identifier) is None:
            add_problem(
                problems,
                filename,
                line,
                f"{context} contains invalid node ID {identifier!r}",
            )
        elif identifier not in owners:
            add_problem(
                problems,
                filename,
                line,
                f"{context} references unknown or non-owned node ID {identifier}",
            )


def backticked_tokens(text: str) -> list[str]:
    return re.findall(r"`([^`]+)`", text)


def code_path_token(token: str, root: Path) -> bool:
    if "/" in token:
        return True
    candidate = Path(token)
    return not candidate.is_absolute() and (root / candidate).exists()


def check_code(
    lines: list[str],
    filename: str,
    root: Path,
    owners: dict[str, Node],
    diagrams: list[Diagram],
    problems: list[Problem],
) -> int:
    tables = [
        table for table in markdown_tables(lines) if table.header == CODE_TABLE_HEADER
    ]
    row_count = sum(len(table.rows) for table in tables)
    covered: set[str] = set()
    child_diagrams: dict[str, list[Diagram]] = {}
    for diagram in diagrams:
        if diagram.parent is not None:
            child_diagrams.setdefault(diagram.parent, []).append(diagram)

    for table in tables:
        for line, row in table.rows:
            if len(row) != 3:
                add_problem(
                    problems,
                    filename,
                    line,
                    "CODE table row must have Node, Code, and Notes cells",
                )
                continue
            id_match = re.fullmatch(r"`(" + NODE_ID + r")`", row[0])
            if id_match is None:
                add_problem(
                    problems,
                    filename,
                    line,
                    f"CODE Node cell must contain one backticked ID, found {row[0]!r}",
                )
                continue
            identifier = id_match.group(1)
            node = owners.get(identifier)
            if node is None:
                add_problem(
                    problems,
                    filename,
                    line,
                    f"CODE row references unknown or non-owned node ID {identifier}",
                )
                continue
            if node.level == 1:
                add_problem(
                    problems,
                    filename,
                    line,
                    f"L1 node {identifier} must not have a CODE row",
                )
            if node.status == "planned":
                add_problem(
                    problems,
                    filename,
                    line,
                    f"planned node {identifier} has code; flip its status?",
                )
            covered.add(identifier)

            tokens = backticked_tokens(row[1])
            if not tokens:
                add_problem(
                    problems,
                    filename,
                    line,
                    "CODE cell must start with a backticked path token",
                )
                continue
            if not code_path_token(tokens[0], root):
                add_problem(
                    problems,
                    filename,
                    line,
                    f"CODE cell must start with a path token; found {tokens[0]!r}",
                )
            current_path: Path | None = None
            current_name: str | None = None
            current_is_directory = False
            for token in tokens:
                if re.search(r":\d+|\bL\d+\b|\bline\s+\d+\b", token, re.IGNORECASE):
                    add_problem(
                        problems,
                        filename,
                        line,
                        f"CODE token {token!r} is a line-number reference; use a path "
                        + "or symbol without a line number",
                    )
                    continue
                if code_path_token(token, root):
                    path = Path(token)
                    if path.is_absolute():
                        add_problem(
                            problems,
                            filename,
                            line,
                            f"CODE path {token!r} must be relative to the repository root",
                        )
                        current_path = None
                        continue
                    current_path = root / path
                    current_name = token
                    current_is_directory = token.endswith("/") or current_path.is_dir()
                    if not current_path.exists():
                        add_problem(
                            problems,
                            filename,
                            line,
                            f"CODE path {token!r} does not exist relative to the repository root",
                        )
                    continue
                if current_path is None:
                    add_problem(
                        problems,
                        filename,
                        line,
                        f"CODE symbol {token!r} appears before any path in the same cell",
                    )
                    continue
                if current_is_directory:
                    add_problem(
                        problems,
                        filename,
                        line,
                        f"CODE symbol {token!r} follows directory path {current_name!r}",
                    )
                    continue
                if not current_path.is_file():
                    continue
                symbol = token.removesuffix("()").split("::")[-1]
                try:
                    source = current_path.read_text(encoding="utf-8")
                except (OSError, UnicodeError):
                    continue
                if re.search(r"\b" + re.escape(symbol) + r"\b", source) is None:
                    add_problem(
                        problems,
                        filename,
                        line,
                        f"CODE symbol {token!r} is not present in path {current_name!r}",
                    )

    for identifier, node in owners.items():
        if (
            node.level < 2
            or node.status != "implemented"
            or diagrams[node.diagram_index].kind != "structure"
        ):
            continue
        children = child_diagrams.get(identifier, [])
        if children and any(child.kind == "structure" for child in children):
            continue
        if identifier not in covered:
            add_problem(
                problems,
                filename,
                node.line,
                f"code-mapped node {identifier} has no CODE row",
            )
    return row_count


def matching_files(root: Path, patterns: list[str]) -> set[str]:
    found: set[str] = set()
    for pattern in patterns:
        for path in root.glob(pattern):
            if path.is_file():
                found.add(path.relative_to(root).as_posix())
    return found


def citation_paths(text: str) -> set[str]:
    return {token.split("::", 1)[0] for token in backticked_tokens(text)}


def check_tables_with_concepts(
    lines: list[str],
    filename: str,
    context: str,
    owners: dict[str, Node],
    problems: list[Problem],
) -> int:
    tables = markdown_tables(lines)
    for table in tables:
        if "Concepts" not in table.header:
            add_problem(
                problems,
                filename,
                table.line,
                f"{context} table must have a 'Concepts' column",
            )
            continue
        concepts_index = table.header.index("Concepts")
        for line, row in table.rows:
            if concepts_index >= len(row):
                add_problem(
                    problems,
                    filename,
                    line,
                    f"{context} row is missing its Concepts cell",
                )
                continue
            node_ids_in_cell(
                row[concepts_index],
                filename,
                line,
                problems,
                owners,
                f"{context} Concepts cell",
            )
    return sum(len(table.rows) for table in tables)


def check_tests(
    lines: list[str],
    filename: str,
    root: Path,
    owners: dict[str, Node],
    globs: list[str],
    problems: list[Problem],
) -> int:
    tables = markdown_tables(lines)
    count = check_tables_with_concepts(lines, filename, "TESTS", owners, problems)
    for table in tables:
        for line, row in table.rows:
            if not row:
                continue
            for token in backticked_tokens(row[0]):
                path = token.split("::", 1)[0]
                if "/" in path and not (root / path).exists():
                    add_problem(
                        problems,
                        filename,
                        line,
                        f"TESTS path {path!r} does not exist relative to the repository root",
                    )
    cited = citation_paths("\n".join(lines))
    for path in sorted(matching_files(root, globs) - cited):
        add_problem(problems, filename, 1, f"test file {path!r} has no TESTS citation")
    return count


def check_evidence(
    lines: list[str],
    filename: str,
    root: Path,
    owners: dict[str, Node],
    config: Config,
    problems: list[Problem],
) -> int:
    all_headings = headings(lines)
    sections = [heading for heading in all_headings if heading[1] == 2]
    for start, _depth, _text in sections:
        end = len(lines)
        for next_start, next_depth, _next_text in all_headings:
            if next_start > start and next_depth == 2:
                end = next_start
                break
        for field_name in config.evidence_fields:
            prefix = f"**{field_name}:**"
            if not any(
                lines[index].startswith(prefix) for index in range(start + 1, end)
            ):
                add_problem(
                    problems,
                    filename,
                    start + 1,
                    f"evidence section must contain a line starting {prefix!r}",
                )
        for index in range(start + 1, end):
            if lines[index].startswith("**Concepts:**"):
                content = lines[index].split("**Concepts:**", 1)[1]
                node_ids_in_cell(
                    content,
                    filename,
                    index + 1,
                    problems,
                    owners,
                    "evidence Concepts line",
                )

    _ = check_tables_with_concepts(lines, filename, "Evidence", owners, problems)
    cited = citation_paths("\n".join(lines))
    for path in sorted(matching_files(root, config.evidence_globs) - cited):
        add_problem(problems, filename, 1, f"evidence file {path!r} has no citation")
    return len(sections)


def link_targets(contents: str) -> list[tuple[str, int, bool]]:
    links: list[tuple[str, int, bool]] = []
    pattern = re.compile(r"(!?)\[[^\]]*\]\((<[^>]*>|[^)\s]+)(?:\s+[^)]*)?\)")
    for match in pattern.finditer(contents):
        target = match.group(2).strip("<>")
        links.append(
            (
                target,
                contents.count("\n", 0, match.start()) + 1,
                not match.group(1),
            )
        )
    for match in re.finditer(
        r"<img\b[^>]*\bsrc\s*=\s*(['\"])(.*?)\1",
        contents,
        re.IGNORECASE | re.DOTALL,
    ):
        links.append(
            (
                match.group(2).strip(),
                contents.count("\n", 0, match.start()) + 1,
                False,
            )
        )
    return links


def check_links(
    documents: dict[str, str],
    concept_files: list[str],
    evidence_filename: str,
    dbc_dir: Path,
    prefix: str,
    problems: list[Problem],
) -> None:
    targets_by_file: dict[str, set[Path]] = {}
    for relative_filename, contents in documents.items():
        filename = display_path(prefix, relative_filename)
        linked_documents: set[Path] = set()
        for target, line, is_markdown in link_targets(contents):
            path_part = target.split("#", 1)[0].split("?", 1)[0]
            if not path_part:
                continue
            if re.match(r"^(?:[A-Za-z][A-Za-z0-9+.-]*:|//)", path_part):
                continue
            resolved = (
                (dbc_dir / relative_filename)
                .parent.joinpath(Path(unquote(path_part)))
                .resolve()
            )
            if is_markdown:
                linked_documents.add(resolved)
            if not resolved.exists():
                add_problem(
                    problems,
                    filename,
                    line,
                    f"relative link or image target {target!r} does not exist",
                )
        targets_by_file[relative_filename] = linked_documents

    base_documents = [*BASE_FILES, evidence_filename]
    resolved_base = {
        filename: (dbc_dir / filename).resolve() for filename in base_documents
    }
    for filename in base_documents:
        for other in base_documents:
            if other != filename and resolved_base[other] not in targets_by_file.get(
                filename, set()
            ):
                add_problem(
                    problems,
                    display_path(prefix, filename),
                    1,
                    f"missing relative link to {other}",
                )

    main_concepts = (dbc_dir / "CONCEPTS.md").resolve()
    for subtree in concept_files[1:]:
        subtree_path = (dbc_dir / subtree).resolve()
        if subtree_path not in targets_by_file.get("CONCEPTS.md", set()):
            add_problem(
                problems,
                display_path(prefix, "CONCEPTS.md"),
                1,
                f"CONCEPTS.md does not link to subtree file {subtree}",
            )
        if main_concepts not in targets_by_file.get(subtree, set()):
            add_problem(
                problems,
                display_path(prefix, subtree),
                1,
                f"subtree file {subtree} does not link back to CONCEPTS.md",
            )


class Arguments(argparse.Namespace):
    def __init__(self) -> None:
        super().__init__()
        self.root: Path | None = None
        self.dbc: Path | None = None


def repository_root(dbc_dir: Path, requested: Path | None) -> Path:
    if requested is not None:
        return requested.resolve()
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=dbc_dir,
            capture_output=True,
            check=False,
            text=True,
        )
    except OSError:
        return dbc_dir.parent
    if result.returncode == 0 and result.stdout.strip():
        return Path(result.stdout.strip()).resolve()
    return dbc_dir.parent


def path_from_root(path: Path, root: Path) -> str:
    try:
        relative = path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        relative = Path(os.path.relpath(path.resolve(), root.resolve())).as_posix()
    return "" if relative == "." else relative


def read_text_file(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="check DBC Markdown and code references"
    )
    _ = parser.add_argument("--root", type=Path, help="repository root")
    _ = parser.add_argument(
        "--dbc", type=Path, help="DBC directory (defaults to this script's directory)"
    )
    arguments = parser.parse_args(argv, namespace=Arguments())
    dbc_dir = (arguments.dbc or Path(__file__).resolve().parent).resolve()
    root = repository_root(dbc_dir, arguments.root)
    prefix = path_from_root(dbc_dir, root)
    try:
        config = read_config(dbc_dir / "dbc.toml")
    except (TypeError, ValueError) as error:
        print(f"check_dbc: {error}", file=sys.stderr)
        return 2

    required_files = (*BASE_FILES, config.evidence)
    paths = {name: dbc_dir / name for name in required_files}
    missing = [name for name, path in paths.items() if not path.is_file()]
    if missing:
        for name in missing:
            print(
                f"check_dbc: missing required file {display_path(prefix, name)}",
                file=sys.stderr,
            )
        return 2
    documents: dict[str, str] = {}
    try:
        for name, path in paths.items():
            documents[name] = read_text_file(path)
    except (OSError, UnicodeError) as error:
        print(f"check_dbc: cannot read DBC file: {error}", file=sys.stderr)
        return 2

    concept_files = ["CONCEPTS.md"]
    concept_dir = dbc_dir / "concepts"
    if concept_dir.exists():
        if not concept_dir.is_dir():
            print("check_dbc: concepts is not a directory", file=sys.stderr)
            return 2
        concept_files.extend(
            path.relative_to(dbc_dir).as_posix()
            for path in sorted(concept_dir.glob("*.md"), key=lambda item: item.name)
            if path.is_file()
        )
    concept_documents: dict[str, list[str]] = {}
    try:
        for filename in concept_files:
            text = read_text_file(dbc_dir / filename)
            concept_documents[filename] = text.splitlines()
            documents[filename] = text
    except (OSError, UnicodeError) as error:
        print(f"check_dbc: cannot read concept file: {error}", file=sys.stderr)
        return 2

    problems: list[Problem] = []
    notices: list[Notice] = []
    definitions_file = "DEFINITIONS.md"
    definition_names = definition_forms(
        documents[definitions_file].splitlines(),
        display_path(prefix, definitions_file),
        problems,
    )
    diagrams, owners = parse_concepts(
        concept_documents, definition_names, config, prefix, problems, notices
    )
    for relative_filename, lines in concept_documents.items():
        for line, text in enumerate(lines, 1):
            for pattern in config.banned_patterns:
                if pattern.search(text):
                    add_problem(
                        problems,
                        display_path(prefix, relative_filename),
                        line,
                        f"line matches banned pattern {pattern.pattern!r}",
                    )

    code_file = "CODE.md"
    code_count = check_code(
        documents[code_file].splitlines(),
        display_path(prefix, code_file),
        root,
        owners,
        diagrams,
        problems,
    )
    tests_file = "TESTS.md"
    test_count = check_tests(
        documents[tests_file].splitlines(),
        display_path(prefix, tests_file),
        root,
        owners,
        config.test_globs,
        problems,
    )
    evidence_count = check_evidence(
        documents[config.evidence].splitlines(),
        display_path(prefix, config.evidence),
        root,
        owners,
        config,
        problems,
    )
    check_links(documents, concept_files, config.evidence, dbc_dir, prefix, problems)

    if problems:
        for problem in sorted(
            problems, key=lambda item: (item.filename, item.line, item.message)
        ):
            print(f"{problem.filename}:{problem.line}: {problem.message}")
    for notice in sorted(
        notices, key=lambda item: (item.filename, item.line, item.message)
    ):
        print(
            f"{display_path(prefix, notice.filename)}:{notice.line}: note: {notice.message}"
        )
    if problems:
        print(f"check_dbc: {len(problems)} problems")
        return 1

    counts: dict[int, int] = {}
    for node in owners.values():
        counts[node.level] = counts.get(node.level, 0) + 1
    levels = ", ".join(f"L{level} {counts[level]}" for level in sorted(counts))
    total = sum(counts.values())
    print(
        f"check_dbc: ok — {total} nodes ({levels}), {code_count} code rows, {test_count} test rows, {evidence_count} evidence sections"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
