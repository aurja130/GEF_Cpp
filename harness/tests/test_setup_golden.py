# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the m6-setup golden derivation, on synthetic captures under ``tmp_path``."""

from __future__ import annotations

import json
from pathlib import Path
from typing import cast

import pytest

from harness.common import STORE_CAPTURES, HarnessError
from harness.p0_golden import CAPTURES
from harness.plan_golden import NAMES
from harness.setup_golden import GOLDEN_OUT, Golden, build_golden, write_golden

FINGERPRINTS_HEADER = "# m6-setup fingerprints 1"
EXCLUDE_LINE = "exclude-full Spin_CN T Var_PZ_S3_olap_curv Z"
EXCLUDED = ("Spin_CN", "T", "Var_PZ_S3_olap_curv", "Z")
FEN1 = "4024000000000000"
FILEIN = b"END\n"
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1


def text(*lines: str) -> str:
    return "".join(f"{line}\n" for line in lines)


def fnv_hex(*lines: str) -> str:
    """FNV-1a 64 of the given lines, each followed by a newline (independent of the module)."""
    value = FNV_OFFSET
    for line in lines:
        for byte in (line + "\n").encode("latin-1"):
            value = ((value ^ byte) * FNV_PRIME) & MASK64
    return f"{value:016x}"


def name_of(line: str) -> str:
    return line.split(" ")[5]


def digest(*lines: str) -> str:
    """A record's golden digest: its lines stable-sorted by NAME, each NAME in dump order."""
    return fnv_hex(*sorted(lines, key=name_of))


def p1_line(rec: int, name: str, index: str = "-", *, step: str = "1", value: str = "1") -> str:
    return f"P1 step={step} pass=- bin=- rec={rec} {name} {index} I {value}"


def p1_record(rec: int, *extra: str) -> list[str]:
    """One P1 record: a scalar line for each NAME of the golden, then the ``extra`` lines."""
    return [*(p1_line(rec, name) for name in NAMES), *extra]


def p1_text(*records: list[str]) -> str:
    return text(*(line for record in records for line in record))


def p1b_line(rec: int, fenhance: str) -> str:
    return f"P1b step=1 pass=- bin=- rec={rec} Fenhance - D {fenhance}"


def write_run(
    capture: Path,
    rel: str,
    stdout: str,
    *,
    p1: str | None = None,
    p1b: str | None = None,
    file_in: bool = True,
) -> None:
    run_dir = capture / rel
    probes = run_dir / "work" / "probes"
    probes.mkdir(parents=True)
    (run_dir / "run.json").write_text(json.dumps({"exit_code": 0}), encoding="utf-8")
    (run_dir / "stdout.log").write_bytes(stdout.encode("latin-1"))
    if file_in:
        (run_dir / "work" / "file.in").write_bytes(FILEIN)
    if p1 is not None:
        (probes / "P1.txt").write_bytes(p1.encode("latin-1"))
    if p1b is not None:
        (probes / "P1b.txt").write_bytes(p1b.encode("latin-1"))


def build(tmp_path: Path, *captures: str) -> Golden:
    return build_golden(tmp_path / "captures", list(captures))


WAIT = "Please wait ... code is running."
NOMINAL = "Calculation with nominal model parameters."
UNBOUND = "<W> Fissioning nucleus is not bound."
TERMINATED = ("GEF is terminated.", "Press ENTER to close this window!")


def barrier_header(z: int, a: int) -> str:
    return f"Fission barrier of CN (Z = {z}, A = {a}):"


def cn_header(z: int, a: int) -> str:
    return f"CN: Z = {z}, A = {a}, E =  10.00 MeV, Spin =  0"


SETUP_STDOUT = text(barrier_header(92, 236), cn_header(92, 236), WAIT, *TERMINATED)
FULL_STDOUT = text(barrier_header(92, 236), cn_header(92, 236), WAIT, NOMINAL, *TERMINATED)
P1B_TEXT = text(p1b_line(1, FEN1))


def setup_run(capture: Path, rel: str) -> None:
    write_run(capture, rel, SETUP_STDOUT, p1=p1_text(p1_record(1)), p1b=P1B_TEXT)


def test_setup_run_digests_its_p1_and_p1b_records(tmp_path: Path) -> None:
    """A set-up run: one line for its P1 record, with every NAME, and one for its P1b record."""
    setup_run(tmp_path / "captures" / "cap", "a")
    golden = build(tmp_path, "cap")
    assert golden.fingerprint_text == text(
        FINGERPRINTS_HEADER,
        EXCLUDE_LINE,
        f"1 P1 1 {len(NAMES)} {digest(*p1_record(1))}",
        f"1 P1b 1 1 {digest(p1b_line(1, FEN1))}",
    )


def test_setup_run_lists_the_store_files_it_came_from(tmp_path: Path) -> None:
    setup_run(tmp_path / "captures" / "cap", "a")
    golden = build(tmp_path, "cap")
    assert golden.sources == (
        ("cap", "a/run.json"),
        ("cap", "a/stdout.log"),
        ("cap", "a/work/file.in"),
        ("cap", "a/work/probes/P1.txt"),
        ("cap", "a/work/probes/P1b.txt"),
    )


def test_setup_run_digests_every_p1_line(tmp_path: Path) -> None:
    """A set-up run keeps the excluded names: their lines are counted and digested."""
    extra = [p1_line(1, name) for name in EXCLUDED]
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=p1_text(p1_record(1, *extra)), p1b=P1B_TEXT)
    golden = build(tmp_path, "cap")
    assert golden.fingerprint_text == text(
        FINGERPRINTS_HEADER,
        EXCLUDE_LINE,
        f"1 P1 1 {len(NAMES) + len(EXCLUDED)} {digest(*p1_record(1, *extra))}",
        f"1 P1b 1 1 {digest(p1b_line(1, FEN1))}",
    )


def test_full_run_leaves_the_excluded_p1_lines_out(tmp_path: Path) -> None:
    """A full run's P1 digest leaves out the excluded names: their step body is not ported."""
    extra = [p1_line(1, name) for name in EXCLUDED]
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", FULL_STDOUT, p1=p1_text(p1_record(1, *extra)), p1b=P1B_TEXT)
    golden = build(tmp_path, "cap")
    assert golden.fingerprint_text == text(
        FINGERPRINTS_HEADER,
        EXCLUDE_LINE,
        f"1 P1 1 {len(NAMES)} {digest(*p1_record(1))}",
        f"1 P1b 1 1 {digest(p1b_line(1, FEN1))}",
    )


def test_full_run_keeps_every_p1b_line(tmp_path: Path) -> None:
    """Only P1 is filtered: a full run's P1b record keeps all of its lines."""
    extra = "P1b step=1 pass=- bin=- rec=1 Z - I 2"
    capture = tmp_path / "captures" / "cap"
    write_run(
        capture,
        "a",
        FULL_STDOUT,
        p1=p1_text(p1_record(1)),
        p1b=text(p1b_line(1, FEN1), extra),
    )
    golden = build(tmp_path, "cap")
    assert golden.fingerprint_text == text(
        FINGERPRINTS_HEADER,
        EXCLUDE_LINE,
        f"1 P1 1 {len(NAMES)} {digest(*p1_record(1))}",
        f"1 P1b 1 2 {digest(p1b_line(1, FEN1), extra)}",
    )


def test_elements_of_a_name_keep_their_dump_order(tmp_path: Path) -> None:
    """Within a NAME the lines keep their dump order, which need not be index order."""
    elements = [p1_line(1, "Ebins", "1", value="20"), p1_line(1, "Ebins", "0", value="10")]
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=p1_text(p1_record(1, *elements)), p1b=P1B_TEXT)
    golden = build(tmp_path, "cap")
    assert golden.fingerprint_text == text(
        FINGERPRINTS_HEADER,
        EXCLUDE_LINE,
        f"1 P1 1 {len(NAMES) + 2} {digest(*p1_record(1, *elements))}",
        f"1 P1b 1 1 {digest(p1b_line(1, FEN1))}",
    )


def test_a_name_must_be_contiguous_within_its_record(tmp_path: Path) -> None:
    lines = [p1_line(1, "Ebins", "0"), *p1_record(1), p1_line(1, "Ebins", "1")]
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=text(*lines), p1b=P1B_TEXT)
    with pytest.raises(HarnessError, match="variable Ebins is not contiguous in P1 rec=1"):
        build(tmp_path, "cap")


def test_a_p1_record_needs_its_step_context(tmp_path: Path) -> None:
    stepless = [p1_line(1, name, step="-") for name in NAMES]
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=text(*stepless), p1b=P1B_TEXT)
    with pytest.raises(HarnessError, match="P1 record 1 has no step context"):
        build(tmp_path, "cap")


def test_a_p1b_record_needs_its_step_context(tmp_path: Path) -> None:
    stepless = text(p1b_line(1, FEN1).replace("step=1", "step=-"))
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=p1_text(p1_record(1)), p1b=stepless)
    with pytest.raises(HarnessError, match="P1b record 1 has no step context"):
        build(tmp_path, "cap")


def test_a_run_lists_its_p1_records_then_its_p1b_records(tmp_path: Path) -> None:
    """Two steps: P1 1, P1 2, then P1b 1, P1b 2, each record with its own digest."""
    stdout = text(
        barrier_header(92, 236), cn_header(92, 236), WAIT, cn_header(92, 236), WAIT, *TERMINATED
    )
    second = p1_record(2, p1_line(2, "Ebins", "0", value="7"))
    capture = tmp_path / "captures" / "cap"
    write_run(
        capture,
        "a",
        stdout,
        p1=p1_text(p1_record(1), second),
        p1b=text(p1b_line(1, FEN1), p1b_line(2, FEN1)),
    )
    golden = build(tmp_path, "cap")
    assert golden.fingerprint_text == text(
        FINGERPRINTS_HEADER,
        EXCLUDE_LINE,
        f"1 P1 1 {len(NAMES)} {digest(*p1_record(1))}",
        f"1 P1 2 {len(NAMES) + 1} {digest(*second)}",
        f"1 P1b 1 1 {digest(p1b_line(1, FEN1))}",
        f"1 P1b 2 1 {digest(p1b_line(2, FEN1))}",
    )


def test_p1_and_p1b_must_hold_the_same_number_of_records(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=p1_text(p1_record(1), p1_record(2)), p1b=P1B_TEXT)
    with pytest.raises(HarnessError, match="P1 has 2 records but P1b has 1"):
        build(tmp_path, "cap")


def test_numbering_runs_across_captures_skips_runs_without_file_in(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    setup_run(captures / "first", "a")
    write_run(captures / "second", "b-skip", "", file_in=False)
    setup_run(captures / "second", "c")
    golden = build(tmp_path, "first", "second")
    assert golden.fingerprint_text == text(
        FINGERPRINTS_HEADER,
        EXCLUDE_LINE,
        f"1 P1 1 {len(NAMES)} {digest(*p1_record(1))}",
        f"1 P1b 1 1 {digest(p1b_line(1, FEN1))}",
        f"2 P1 1 {len(NAMES)} {digest(*p1_record(1))}",
        f"2 P1b 1 1 {digest(p1b_line(1, FEN1))}",
    )
    assert ("second", "b-skip/run.json") in golden.sources


def test_a_run_without_probe_records_takes_a_number_and_no_line(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", text(barrier_header(76, 241), UNBOUND, *TERMINATED))
    setup_run(capture, "b")
    golden = build(tmp_path, "cap")
    assert golden.fingerprint_text == text(
        FINGERPRINTS_HEADER,
        EXCLUDE_LINE,
        f"2 P1 1 {len(NAMES)} {digest(*p1_record(1))}",
        f"2 P1b 1 1 {digest(p1b_line(1, FEN1))}",
    )


def test_no_captures_leave_only_the_header_and_the_exclude_line(tmp_path: Path) -> None:
    golden = build(tmp_path)
    assert golden.fingerprint_text == text(FINGERPRINTS_HEADER, EXCLUDE_LINE)
    assert golden.sources == ()


def test_write_golden_writes_fingerprints_and_store_derived_record(tmp_path: Path) -> None:
    """The fingerprint text and a store-derived record naming the one golden file."""
    out = tmp_path / "m6-setup"
    write_golden(out, Golden(fingerprint_text="fp\n", sources=()), replace=False)
    assert (out / "fingerprints.txt").read_bytes() == b"fp\n"
    derived = out / "derived.json"
    record = cast("dict[str, object]", json.loads(derived.read_text(encoding="utf-8")))
    assert record["kind"] == "store-derived"
    assert record["tool"] == "python3 -m harness.setup_golden"
    assert record["sources"] == []
    outputs = cast("dict[str, str]", record["outputs"])
    assert sorted(outputs) == ["fingerprints.txt"]


def test_write_golden_refuses_an_existing_golden_without_replace(tmp_path: Path) -> None:
    out = tmp_path / "m6-setup"
    out.mkdir()
    (out / "fingerprints.txt").write_text("old\n", encoding="utf-8")
    with pytest.raises(HarnessError, match="--replace"):
        write_golden(out, Golden(fingerprint_text="new\n", sources=()), replace=False)
    assert (out / "fingerprints.txt").read_text(encoding="utf-8") == "old\n"


def test_write_golden_replaces_an_existing_golden_when_asked(tmp_path: Path) -> None:
    out = tmp_path / "m6-setup"
    out.mkdir()
    (out / "fingerprints.txt").write_text("old\n", encoding="utf-8")
    write_golden(out, Golden(fingerprint_text="new\n", sources=()), replace=True)
    assert (out / "fingerprints.txt").read_text(encoding="utf-8") == "new\n"


@pytest.mark.validation
def test_committed_golden_matches_the_store() -> None:
    """The committed m6-setup golden is what the store derives now."""
    if not STORE_CAPTURES.is_dir():
        pytest.skip("the reference store is not present")
    golden_file = GOLDEN_OUT / "fingerprints.txt"
    if not golden_file.is_file():
        pytest.skip("the m6-setup golden is not written yet")
    built = build_golden(STORE_CAPTURES, CAPTURES)
    assert built.fingerprint_text == golden_file.read_text(encoding="utf-8")
