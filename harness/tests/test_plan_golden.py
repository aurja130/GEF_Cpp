# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the m6-plan golden derivation, on synthetic captures under ``tmp_path``."""

from __future__ import annotations

import json
from pathlib import Path
from typing import cast

import pytest

from harness.common import STORE_CAPTURES, HarnessError
from harness.p0_golden import CAPTURES
from harness.plan_golden import GOLDEN_OUT, Golden, build_golden, write_golden

PLAN_HEADER = "# m6-plan 1"
NAMES_LINE = (
    "names Iline Ifilein I_Double_Covar N_Double_Covar I_E_step N_E_steps N_E_values I_E_iso "
    "Bfilein B_ENDF B_Random_on B_Error_On I_Error En_min En_max P_Z_CN P_A_CN P_I_rms_CN "
    "P_Z_CN_Double P_A_CN_Double P_E_exc_Double E_EXC_TRUE Emode"
)
P1_NAMES = tuple(NAMES_LINE.split()[1:])
FILEIN = b"END\n"
FEN1 = "4024000000000000"
FEN2 = "4034000000000000"
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1


def text(*lines: str) -> str:
    return "".join(f"{line}\n" for line in lines)


def fnv_hex(*lines: str) -> str:
    """FNV-1a 64 of the given lines, each followed by a newline (not the module's helper)."""
    value = FNV_OFFSET
    for line in lines:
        for byte in (line + "\n").encode("latin-1"):
            value = ((value ^ byte) * FNV_PRIME) & MASK64
    return f"{value:016x}"


def hex_of(line: str) -> str:
    return line.encode("latin-1").hex()


def barrier_header(z: int, a: int) -> str:
    return f"Fission barrier of CN (Z = {z}, A = {a}):"


def cn_header(z: int, a: int) -> str:
    return f"CN: Z = {z}, A = {a}, E =  10.00 MeV, Spin =  0"


def p1_lines(rec: int) -> list[str]:
    """One P1 record: a scalar line for each name the plan's digest covers."""
    return [f"P1 step=1 pass=- bin=- rec={rec} {name} - I 1" for name in P1_NAMES]


def p1_text(count: int) -> str:
    """P1 records 1..count."""
    return text(*(line for rec in range(1, count + 1) for line in p1_lines(rec)))


def p1b_text(*fenhances: str) -> str:
    """One P1b record per Fenhance value, numbered from 1."""
    return text(
        *(
            f"P1b step=1 pass=- bin=- rec={rec} Fenhance - D {value}"
            for rec, value in enumerate(fenhances, start=1)
        )
    )


def digest(count: int) -> str:
    """The plan's P1 digest of records 1..count."""
    return fnv_hex(*(line for rec in range(1, count + 1) for line in p1_lines(rec)))


def expected_plan(*lines: str) -> str:
    return text(PLAN_HEADER, NAMES_LINE, *lines)


def setup_block(number: int, capture: str, rel: str) -> list[str]:
    """The golden lines of a run that sets up 92 236 and runs one calculation."""
    return [
        f"run {number} {capture} {rel}",
        "mode setup",
        "system 92 236 ok",
        f"step ok 92 236 {FEN1}",
        f"p1 1 {digest(1)}",
        "exit terminated",
        "endrun",
    ]


def write_run(
    capture: Path,
    rel: str,
    stdout: str,
    *,
    p1: str | None = None,
    p1b: str | None = None,
    exit_code: int = 0,
    file_in: bool = True,
) -> None:
    run_dir = capture / rel
    probes = run_dir / "work" / "probes"
    probes.mkdir(parents=True)
    (run_dir / "run.json").write_text(json.dumps({"exit_code": exit_code}), encoding="utf-8")
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
RESTART = "Please stop GEF, complete table and restart GEF."
UNBOUND = "<W> Fissioning nucleus is not bound."
ALPHA = "<S> Alpha energy is too low. (E* of compound nucleus would be negativ.)"
BELOW_GROUND = "<E> Input energy of the fissioning nucleus is below the ground state."
PRESS_ENTER = "    Press Enter key to leave GEF!"
NOMINAL = "Calculation with nominal model parameters."
PERTURBED = "Calculation ( 1 of  1) with perturbed model parameters."
EVENTS = " 10 events will be calculated."
GRAVE_HEAD = "<W> The calculation with 250 events will be subject"
GRAVE_TAIL = "to grave statistical fluctuations!"
TERMINATED = ("GEF is terminated.", "Press ENTER to close this window!")
SETUP_STDOUT = text(barrier_header(92, 236), cn_header(92, 236), WAIT, *TERMINATED)


def setup_run(capture: Path, rel: str) -> None:
    write_run(capture, rel, SETUP_STDOUT, p1=p1_text(1), p1b=p1b_text(FEN1))


def test_setup_run_lists_its_system_step_digest_and_exit(tmp_path: Path) -> None:
    """A set-up run: the system it set up, the step it ran, its P1 digest and its exit."""
    setup_run(tmp_path / "captures" / "cap", "a")
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(*setup_block(1, "cap", "a"))


def test_names_line_lists_the_dumped_variables_in_driver_order(tmp_path: Path) -> None:
    """With no captures the golden is the header and the names line alone."""
    golden = build(tmp_path)
    assert golden.plan_text == expected_plan()
    assert golden.sources == ()


def test_unbound_barrier_is_recorded_and_takes_no_step(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", text(barrier_header(76, 241), UNBOUND, *TERMINATED))
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(
        "run 1 cap a",
        "mode setup",
        "system 76 241 unbound",
        "p1 0 cbf29ce484222325",
        "exit terminated",
        "endrun",
    )


def test_restart_settles_its_system_and_later_systems_are_listed(tmp_path: Path) -> None:
    stdout = text(
        barrier_header(92, 236),
        cn_header(92, 236),
        WAIT,
        barrier_header(95, 243),
        RESTART,
        barrier_header(94, 240),
        cn_header(94, 240),
        WAIT,
        *TERMINATED,
    )
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout, p1=p1_text(2), p1b=p1b_text(FEN1, FEN2))
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(
        "run 1 cap a",
        "mode setup",
        "system 92 236 ok",
        f"step ok 92 236 {FEN1}",
        "system 95 243 ok",
        "step restart",
        "system 94 240 ok",
        f"step ok 94 240 {FEN2}",
        f"p1 2 {digest(2)}",
        "exit terminated",
        "endrun",
    )


def test_repeated_cn_of_the_same_system_runs_its_own_step(tmp_path: Path) -> None:
    stdout = text(
        barrier_header(92, 236),
        cn_header(92, 236),
        WAIT,
        cn_header(92, 236),
        WAIT,
        *TERMINATED,
    )
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout, p1=p1_text(2), p1b=p1b_text(FEN1, FEN2))
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(
        "run 1 cap a",
        "mode setup",
        "system 92 236 ok",
        f"step ok 92 236 {FEN1}",
        f"step ok 92 236 {FEN2}",
        f"p1 2 {digest(2)}",
        "exit terminated",
        "endrun",
    )


@pytest.mark.parametrize("stop", [ALPHA, BELOW_GROUND])
def test_stop_before_a_calculation_ends_the_run(tmp_path: Path, stop: str) -> None:
    stdout = text(barrier_header(92, 236), cn_header(92, 236), stop, PRESS_ENTER)
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout)
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(
        "run 1 cap a",
        "mode setup",
        "system 92 236 ok",
        "step end 92 236",
        "p1 0 cbf29ce484222325",
        "exit end",
        "endrun",
    )


def test_full_run_lists_each_pass_header_right_after_its_step(tmp_path: Path) -> None:
    stdout = text(
        barrier_header(92, 236),
        cn_header(92, 236),
        WAIT,
        NOMINAL,
        cn_header(92, 236),
        WAIT,
        PERTURBED,
        *TERMINATED,
    )
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout, p1=p1_text(2), p1b=p1b_text(FEN1, FEN2))
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(
        "run 1 cap a",
        "mode full",
        "system 92 236 ok",
        f"step ok 92 236 {FEN1}",
        f"pass {hex_of(NOMINAL)}",
        f"step ok 92 236 {FEN2}",
        f"pass {hex_of(PERTURBED)}",
        f"p1 2 {digest(2)}",
        "exit terminated",
        "endrun",
    )


def test_events_line_is_a_pass_header_with_its_leading_spaces(tmp_path: Path) -> None:
    stdout = text(barrier_header(92, 236), cn_header(92, 236), WAIT, EVENTS, *TERMINATED)
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout, p1=p1_text(1), p1b=p1b_text(FEN1))
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(
        "run 1 cap a",
        "mode full",
        "system 92 236 ok",
        f"step ok 92 236 {FEN1}",
        f"pass {hex_of(EVENTS)}",
        f"p1 1 {digest(1)}",
        "exit terminated",
        "endrun",
    )


def test_grave_statistics_head_and_tail_are_two_pass_headers(tmp_path: Path) -> None:
    stdout = text(
        barrier_header(92, 236),
        cn_header(92, 236),
        WAIT,
        GRAVE_HEAD,
        GRAVE_TAIL,
        *TERMINATED,
    )
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout, p1=p1_text(1), p1b=p1b_text(FEN1))
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(
        "run 1 cap a",
        "mode full",
        "system 92 236 ok",
        f"step ok 92 236 {FEN1}",
        f"pass {hex_of(GRAVE_HEAD)}",
        f"pass {hex_of(GRAVE_TAIL)}",
        f"p1 1 {digest(1)}",
        "exit terminated",
        "endrun",
    )


def test_file_and_option_lines_are_not_events(tmp_path: Path) -> None:
    stdout = text(
        "File 'file.in' found.",
        "    File 'MyParameters.dat' not found.",
        "    Calculation with perturbed parameters enabled.",
        "Sequence of nuclei given in in/a.dat will be calculated!",
        barrier_header(92, 236),
        cn_header(92, 236),
        WAIT,
        *TERMINATED,
    )
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout, p1=p1_text(1), p1b=p1b_text(FEN1))
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(*setup_block(1, "cap", "a"))


def test_nonzero_exit_without_the_closing_lines_is_hang(tmp_path: Path) -> None:
    stdout = text(barrier_header(92, 236), cn_header(92, 236), WAIT)
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout, p1=p1_text(1), p1b=p1b_text(FEN1), exit_code=-1)
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(
        "run 1 cap a",
        "mode setup",
        "system 92 236 ok",
        f"step ok 92 236 {FEN1}",
        f"p1 1 {digest(1)}",
        "exit hang",
        "endrun",
    )


def test_run_without_work_file_in_keeps_a_comment_and_takes_no_number(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a-skip", "", file_in=False)
    setup_run(capture, "b-run")
    golden = build(tmp_path, "cap")
    assert golden.plan_text == expected_plan(
        "# skipped cap a-skip: the store keeps no work/file.in",
        *setup_block(1, "cap", "b-run"),
    )
    assert golden.sources == (
        ("cap", "a-skip/run.json"),
        ("cap", "b-run/run.json"),
        ("cap", "b-run/stdout.log"),
        ("cap", "b-run/work/file.in"),
        ("cap", "b-run/work/probes/P1.txt"),
        ("cap", "b-run/work/probes/P1b.txt"),
    )


def test_runs_are_numbered_across_captures_in_order(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    setup_run(captures / "first", "a")
    setup_run(captures / "second", "b")
    golden = build(tmp_path, "first", "second")
    assert golden.plan_text == expected_plan(
        *setup_block(1, "first", "a"),
        *setup_block(2, "second", "b"),
    )


def test_p1_and_p1b_must_hold_the_same_number_of_records(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=p1_text(1), p1b=p1b_text(FEN1, FEN2))
    with pytest.raises(HarnessError, match="P1 has 1 records but P1b has 2"):
        build(tmp_path, "cap")


def test_calculations_must_match_the_p1_records(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=p1_text(2), p1b=p1b_text(FEN1, FEN2))
    with pytest.raises(HarnessError, match="BASIC made 1 calculations but P1 holds 2 records"):
        build(tmp_path, "cap")


def test_a_step_in_a_full_run_needs_its_pass_header(tmp_path: Path) -> None:
    stdout = text(
        barrier_header(92, 236),
        cn_header(92, 236),
        WAIT,
        cn_header(92, 236),
        WAIT,
        NOMINAL,
        *TERMINATED,
    )
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout, p1=p1_text(2), p1b=p1b_text(FEN1, FEN2))
    with pytest.raises(HarnessError, match="a calculation has no pass header after its step"):
        build(tmp_path, "cap")


def test_p1_record_must_hold_every_name(tmp_path: Path) -> None:
    lines = [line for line in p1_lines(1) if " Emode " not in line]
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=text(*lines), p1b=p1b_text(FEN1))
    with pytest.raises(HarnessError, match="P1 record 1 has no Emode"):
        build(tmp_path, "cap")


def test_p1_names_must_be_scalars(tmp_path: Path) -> None:
    lines = ["P1 step=1 pass=- bin=- rec=1 Iline 1 I 1", *p1_lines(1)[1:]]
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=text(*lines), p1b=p1b_text(FEN1))
    with pytest.raises(HarnessError, match="P1 record 1 has Iline as an array element"):
        build(tmp_path, "cap")


def test_duplicate_p1_lines_are_rejected(tmp_path: Path) -> None:
    lines = [*p1_lines(1), p1_lines(1)[0]]
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=text(*lines), p1b=p1b_text(FEN1))
    with pytest.raises(HarnessError, match="duplicate element"):
        build(tmp_path, "cap")


def test_a_marker_after_the_end_of_the_run_is_rejected(tmp_path: Path) -> None:
    stdout = text(barrier_header(92, 236), cn_header(92, 236), ALPHA, WAIT)
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout)
    with pytest.raises(HarnessError, match="a marker follows the end of the run"):
        build(tmp_path, "cap")


def test_a_cn_header_needs_its_verdict_before_the_end(tmp_path: Path) -> None:
    stdout = text(barrier_header(92, 236), cn_header(92, 236))
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout)
    with pytest.raises(HarnessError, match="ends with a CN header and no verdict"):
        build(tmp_path, "cap")


def test_a_wait_line_needs_a_cn_header(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", text(WAIT))
    with pytest.raises(HarnessError, match="a Please wait line with no CN header before it"):
        build(tmp_path, "cap")


def test_a_pass_header_cannot_follow_a_cn_header_directly(tmp_path: Path) -> None:
    stdout = text(barrier_header(92, 236), cn_header(92, 236), NOMINAL)
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout)
    with pytest.raises(HarnessError, match="a pass header while a CN header awaits its verdict"):
        build(tmp_path, "cap")


def test_restart_while_a_cn_header_awaits_its_verdict_is_rejected(tmp_path: Path) -> None:
    stdout = text(barrier_header(92, 236), cn_header(92, 236), RESTART)
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout)
    with pytest.raises(HarnessError, match="a restart while a CN header awaits its verdict"):
        build(tmp_path, "cap")


def test_unbound_needs_a_fission_barrier(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", text(UNBOUND))
    with pytest.raises(HarnessError, match="an unbound verdict with no fission barrier"):
        build(tmp_path, "cap")


def test_cn_header_must_follow_the_fission_barrier_of_its_system(tmp_path: Path) -> None:
    stdout = text(barrier_header(92, 236), cn_header(94, 240))
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout)
    with pytest.raises(HarnessError, match="CN 94 240 does not match the fission barrier"):
        build(tmp_path, "cap")


def test_cn_header_without_any_fission_barrier_is_rejected(tmp_path: Path) -> None:
    stdout = text(cn_header(94, 240), WAIT)
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout)
    with pytest.raises(HarnessError, match="CN 94 240 has no fission barrier of its system"):
        build(tmp_path, "cap")


def test_p1b_file_must_hold_p1b_records(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=p1_text(1), p1b=p1_text(1))
    with pytest.raises(HarnessError, match=r"P1b\.txt holds P1 records"):
        build(tmp_path, "cap")


def test_records_must_be_numbered_from_one(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", SETUP_STDOUT, p1=text(*p1_lines(2)), p1b=p1b_text(FEN1))
    with pytest.raises(HarnessError, match="P1 record 1 has rec=2, not 1"):
        build(tmp_path, "cap")


def test_run_directory_with_a_space_is_rejected(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "run 1", SETUP_STDOUT, p1=p1_text(1), p1b=p1b_text(FEN1))
    with pytest.raises(HarnessError, match="the run directory has a space in its name"):
        build(tmp_path, "cap")


def test_grave_head_needs_its_tail_line(tmp_path: Path) -> None:
    stdout = text(barrier_header(92, 236), cn_header(92, 236), WAIT, GRAVE_HEAD, *TERMINATED)
    capture = tmp_path / "captures" / "cap"
    write_run(capture, "a", stdout, p1=p1_text(1), p1b=p1b_text(FEN1))
    with pytest.raises(HarnessError, match="a grave-statistics line without its tail line"):
        build(tmp_path, "cap")


def test_fenhance_must_be_a_double(tmp_path: Path) -> None:
    capture = tmp_path / "captures" / "cap"
    fenhance = text("P1b step=1 pass=- bin=- rec=1 Fenhance - I 1")
    write_run(capture, "a", SETUP_STDOUT, p1=p1_text(1), p1b=fenhance)
    with pytest.raises(HarnessError, match="P1b record 1 has no Fenhance as 16 hex digits"):
        build(tmp_path, "cap")


def test_write_golden_writes_plan_text_and_store_derived_record(tmp_path: Path) -> None:
    """The plan text and a store-derived record naming the one golden file."""
    out = tmp_path / "m6-plan"
    write_golden(out, Golden(plan_text="plan\n", sources=()), replace=False)
    assert (out / "plan.txt").read_bytes() == b"plan\n"
    derived = out / "derived.json"
    record = cast("dict[str, object]", json.loads(derived.read_text(encoding="utf-8")))
    assert record["kind"] == "store-derived"
    assert record["tool"] == "python3 -m harness.plan_golden"
    assert record["sources"] == []
    outputs = cast("dict[str, str]", record["outputs"])
    assert sorted(outputs) == ["plan.txt"]


def test_write_golden_refuses_an_existing_golden_without_replace(tmp_path: Path) -> None:
    out = tmp_path / "m6-plan"
    out.mkdir()
    (out / "plan.txt").write_text("old\n", encoding="utf-8")
    with pytest.raises(HarnessError, match="--replace"):
        write_golden(out, Golden(plan_text="new\n", sources=()), replace=False)
    assert (out / "plan.txt").read_text(encoding="utf-8") == "old\n"


def test_write_golden_replaces_an_existing_golden_when_asked(tmp_path: Path) -> None:
    out = tmp_path / "m6-plan"
    out.mkdir()
    (out / "plan.txt").write_text("old\n", encoding="utf-8")
    write_golden(out, Golden(plan_text="new\n", sources=()), replace=True)
    assert (out / "plan.txt").read_text(encoding="utf-8") == "new\n"


@pytest.mark.validation
def test_committed_golden_matches_the_store() -> None:
    """The committed m6-plan golden is what the store derives now."""
    if not STORE_CAPTURES.is_dir():
        pytest.skip("the reference store is not present")
    golden_file = GOLDEN_OUT / "plan.txt"
    if not golden_file.is_file():
        pytest.skip("the m6-plan golden is not written yet")
    built = build_golden(STORE_CAPTURES, CAPTURES)
    assert built.plan_text == golden_file.read_text(encoding="utf-8")
