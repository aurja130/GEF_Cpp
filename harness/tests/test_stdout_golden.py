# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the m6-stdout golden derivation, on synthetic captures under ``tmp_path``."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from harness.common import STORE_CAPTURES, HarnessError
from harness.p0_golden import CAPTURES
from harness.plan_golden import NAMES
from harness.stdout_golden import (
    GOLDEN_OUT,
    Golden,
    build_golden,
    console_start,
    write_golden,
)

RUNS_HEADER = "# m6-stdout runs 1"
FEN1 = "4024000000000000"
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1

FOUND = "File 'file.in' found."
FITPAR = "File Fitpar.dat found."
BANNER = "GEF 2025/1.2"
WAIT = "Please wait ... code is running."
TERMINATED = ("GEF is terminated.", "Press ENTER to close this window!")


def text(*lines: str) -> str:
    return "".join(f"{line}\n" for line in lines)


def fnv_hex(data: bytes) -> str:
    """FNV-1a 64 of raw bytes (independent of the module)."""
    value = FNV_OFFSET
    for byte in data:
        value = ((value ^ byte) * FNV_PRIME) & MASK64
    return f"{value:016x}"


def p1_text() -> str:
    return text(*(f"P1 step=1 pass=- bin=- rec=1 {name} - I 1" for name in NAMES))


def p1b_text() -> str:
    return text(f"P1b step=1 pass=- bin=- rec=1 Fenhance - D {FEN1}")


def range_text() -> str:
    """The lines of a one-step set-up run from the D3 start on."""
    return text(
        FOUND,
        "Fission barrier of CN (Z = 92, A = 236):",
        "CN: Z = 92, A = 236, E =  10.00 MeV, Spin =  0",
        WAIT,
        *TERMINATED,
    )


def write_run(capture: Path, rel: str, stdout: str, *, fitpar: bool = False) -> None:
    run_dir = capture / rel
    probes = run_dir / "work" / "probes"
    probes.mkdir(parents=True)
    (run_dir / "run.json").write_text(json.dumps({"exit_code": 0}), encoding="utf-8")
    (run_dir / "stdout.log").write_bytes(stdout.encode("latin-1"))
    (run_dir / "work" / "file.in").write_bytes(b"END\n")
    (probes / "P1.txt").write_bytes(p1_text().encode("latin-1"))
    (probes / "P1b.txt").write_bytes(p1b_text().encode("latin-1"))
    if fitpar:
        (run_dir / "work" / "Fitpar.dat").write_bytes(b"_P_Shell_S1 = 1\n")


def build(tmp_path: Path, *captures: str) -> Golden:
    return build_golden(tmp_path / "captures", list(captures))


def test_without_fitpar_the_range_starts_at_file_in_found(tmp_path: Path) -> None:
    head = text(BANNER, "start-up line")
    write_run(tmp_path / "captures" / "cap", "a", head + range_text())
    golden = build(tmp_path, "cap")
    tail = range_text().encode("latin-1")
    assert golden.runs_text == text(RUNS_HEADER, f"1 setup 3 {len(tail)} {fnv_hex(tail)}")


def test_with_fitpar_the_range_starts_at_the_nextfitloop_notice(tmp_path: Path) -> None:
    """Start-up and Nextfitloop both print FitparRead's notice; the range takes the second."""
    notice = text(FITPAR, "Parameter values from file 'Fitpar.dat' are used as starting values.")
    stdout = text(BANNER) + notice + text("start-up line") + notice + range_text()
    write_run(tmp_path / "captures" / "cap", "a", stdout, fitpar=True)
    golden = build(tmp_path, "cap")
    tail = (notice + range_text()).encode("latin-1")
    assert golden.runs_text == text(RUNS_HEADER, f"1 setup 5 {len(tail)} {fnv_hex(tail)}")
    assert ("cap", "a/work/Fitpar.dat") in golden.sources


def test_the_digest_covers_a_last_line_without_newline(tmp_path: Path) -> None:
    stdout = text(BANNER) + range_text() + "cut off"
    write_run(tmp_path / "captures" / "cap", "a", stdout)
    golden = build(tmp_path, "cap")
    tail = (range_text() + "cut off").encode("latin-1")
    assert golden.runs_text.endswith(f"1 setup 2 {len(tail)} {fnv_hex(tail)}\n")


def test_console_start_needs_file_in_found() -> None:
    with pytest.raises(HarnessError, match="no line"):
        console_start(text(BANNER, WAIT).encode("latin-1"), fitpar=False, where="cap/a")


def test_console_start_with_fitpar_needs_its_notice() -> None:
    stdout = text(BANNER, FOUND).encode("latin-1")
    with pytest.raises(HarnessError, match=r"Fitpar\.dat is present"):
        console_start(stdout, fitpar=True, where="cap/a")


def test_console_start_with_fitpar_needs_the_start_up_notice_too() -> None:
    stdout = text(BANNER, FITPAR, FOUND).encode("latin-1")
    with pytest.raises(HarnessError, match="no start-up"):
        console_start(stdout, fitpar=True, where="cap/a")


def test_a_notice_after_file_in_found_does_not_start_the_range() -> None:
    stdout = text(FITPAR, BANNER, FITPAR, FOUND, FITPAR).encode("latin-1")
    assert console_start(stdout, fitpar=True, where="cap/a") == 2


def test_runs_are_numbered_across_captures_and_skip_runs_without_file_in(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(captures / "first", "a", range_text())
    skipped = captures / "second" / "b-skip"
    skipped.mkdir(parents=True)
    (skipped / "run.json").write_text(json.dumps({"exit_code": 0}), encoding="utf-8")
    write_run(captures / "second", "c", range_text())
    golden = build(tmp_path, "first", "second")
    numbers = [line.split(" ")[0] for line in golden.runs_text.splitlines()[1:]]
    assert numbers == ["1", "2"]
    assert ("second", "b-skip/run.json") in golden.sources


def test_write_golden_writes_runs_and_derived_record(tmp_path: Path) -> None:
    out = tmp_path / "m6-stdout"
    write_golden(out, Golden(runs_text="runs\n", sources=()), replace=False)
    assert (out / "runs.txt").read_bytes() == b"runs\n"
    record = json.loads((out / "derived.json").read_text(encoding="utf-8"))
    assert record["tool"] == "python3 -m harness.stdout_golden"


def test_write_golden_refuses_an_existing_golden_without_replace(tmp_path: Path) -> None:
    out = tmp_path / "m6-stdout"
    out.mkdir()
    (out / "runs.txt").write_text("old\n", encoding="utf-8")
    with pytest.raises(HarnessError, match="--replace"):
        write_golden(out, Golden(runs_text="new\n", sources=()), replace=False)


def test_write_golden_replaces_an_existing_golden_when_asked(tmp_path: Path) -> None:
    out = tmp_path / "m6-stdout"
    out.mkdir()
    (out / "stale.txt").write_text("old\n", encoding="utf-8")
    write_golden(out, Golden(runs_text="new\n", sources=()), replace=True)
    assert (out / "runs.txt").read_bytes() == b"new\n"
    assert not (out / "stale.txt").exists()


@pytest.mark.validation
def test_committed_golden_matches_the_store() -> None:
    """The committed m6-stdout golden is what the store derives now."""
    if not STORE_CAPTURES.is_dir():
        pytest.skip("the reference store is not present")
    golden_file = GOLDEN_OUT / "runs.txt"
    if not golden_file.is_file():
        pytest.skip("the m6-stdout golden is not written yet")
    built = build_golden(STORE_CAPTURES, CAPTURES)
    assert built.runs_text == golden_file.read_text(encoding="utf-8")
