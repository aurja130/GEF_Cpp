# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the m6-p0 golden derivation, on synthetic captures under ``tmp_path``."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import cast

import pytest

from harness.common import HarnessError
from harness.p0_golden import Golden, build_golden, default_source_roots, write_golden

FILEIN = b'"in/a.in"\nEND\n'
FOUND = "File 'file.in' found.\n"
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1
CTX1 = "P0 step=- pass=- bin=- rec=1"
CTX2 = "P0 step=- pass=- bin=- rec=2"


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def text(*lines: str) -> str:
    return "".join(f"{line}\n" for line in lines)


def fnv_hex(*lines: str) -> str:
    """FNV-1a 64 of the given lines, each followed by a newline (not the module's helper)."""
    value = FNV_OFFSET
    for line in lines:
        for byte in (line + "\n").encode("latin-1"):
            value = ((value ^ byte) * FNV_PRIME) & MASK64
    return f"{value:016x}"


def parse_line(sequence: str) -> str:
    return f"Sequence of nuclei given in {sequence} will be calculated\n"


def p0_block(rec: int, ifilein: int, emode: int, cfile: str) -> str:
    context = f"P0 step=- pass=- bin=- rec={rec}"
    return (
        f"{context} Ifilein - I {ifilein}\n"
        f"{context} Emode - I {emode}\n"
        f'{context} Cfileoutlmd_full - Z "{cfile}"\n'
    )


def make_inputs(tmp_path: Path, files: dict[str, bytes]) -> Path:
    inputs = tmp_path / "inputs"
    inputs.mkdir()
    for name, data in files.items():
        (inputs / name).write_bytes(data)
    return inputs


def write_run(
    capture: Path,
    rel: str,
    *,
    stdout: str,
    exit_code: int = 0,
    filein: bytes | None = FILEIN,
    input_entry: dict[str, object] | None = None,
    work_files: list[dict[str, object]] | None = None,
    p0: str | None = None,
    p1: str | None = None,
    run_extra: dict[str, object] | None = None,
) -> None:
    run_dir = capture / rel
    probes = run_dir / "work" / "probes"
    probes.mkdir(parents=True)
    (run_dir / "stdout.log").write_text(stdout, encoding="latin-1")
    if filein is not None:
        (run_dir / "work" / "file.in").write_bytes(filein)
    if p0 is not None:
        (probes / "P0.txt").write_text(p0, encoding="latin-1")
    if p1 is not None:
        (probes / "P1.txt").write_text(p1, encoding="latin-1")
    run: dict[str, object] = {"exit_code": exit_code, "work_files": work_files or []}
    if input_entry is not None:
        run["input"] = input_entry
    run.update(run_extra or {})
    (run_dir / "run.json").write_text(json.dumps(run), encoding="utf-8")


def write_corpus(capture: Path, exit_codes: dict[str, int]) -> None:
    entries = [{"id": rel, "exit_code": code} for rel, code in exit_codes.items()]
    (capture / "corpus.json").write_text(json.dumps({"entries": entries}), encoding="utf-8")


def test_plan_and_fingerprints_for_a_two_parse_run(tmp_path: Path) -> None:
    seq_a = b"seq a\n"
    seq_b = b"seq b\n"
    inputs = make_inputs(tmp_path, {"a.in": seq_a, "b.in": seq_b})
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "r1",
        stdout=FOUND + parse_line("in/a.in") + parse_line("in/b.in"),
        input_entry={"name": "a.in", "sha256": sha(seq_a)},
        work_files=[{"dest": "in/b.in", "name": "b.in", "sha256": sha(seq_b)}],
        p0=p0_block(1, 1, 1, "xy") + p0_block(2, 2, 1, "xy"),
    )

    golden = build_golden(captures, ["cap"], (("harness/inputs", inputs),))

    assert golden.plan_text == text(
        "# m6-p0 plan 2",
        f"file 1 in/a.in harness/inputs/a.in {sha(seq_a)}",
        f"file 2 in/b.in harness/inputs/b.in {sha(seq_b)}",
        "run 1 cap r1",
        f"filein {FILEIN.hex()}",
        "work 1 2",
        "parse 1 1 1 7879 p0=1",
        "parse 0 2 1 7879 p0=2",
        "endrun",
    )
    # A record's digest hashes its lines sorted by variable NAME, not in dump order.
    record_1 = fnv_hex(
        f'{CTX1} Cfileoutlmd_full - Z "xy"',
        f"{CTX1} Emode - I 1",
        f"{CTX1} Ifilein - I 1",
    )
    record_2 = fnv_hex(
        f'{CTX2} Cfileoutlmd_full - Z "xy"',
        f"{CTX2} Emode - I 1",
        f"{CTX2} Ifilein - I 2",
    )
    assert golden.fingerprint_text == text(
        "# m6-p0 fingerprints 2",
        f"1 1 3 {record_1}",
        f"1 2 3 {record_2}",
    )
    assert golden.sources == (
        ("cap", "r1/run.json"),
        ("cap", "r1/stdout.log"),
        ("cap", "r1/work/file.in"),
        ("cap", "r1/work/probes/P0.txt"),
    )


def test_restart_resets_ifilein_and_p1_emode_seeds_last_parse(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "r2",
        stdout=FOUND + parse_line("in/a.in") + FOUND + parse_line("in/b.in"),
        p0=p0_block(1, 1, 4, "xy"),
        p1="P1 step=- pass=- bin=- rec=1 Emode - I 9\n",
    )

    golden = build_golden(captures, ["cap"], ())

    assert golden.plan_text == text(
        "# m6-p0 plan 2",
        "run 1 cap r2",
        f"filein {FILEIN.hex()}",
        "work",
        "parse 1 1 4 7879 p0=1",
        "parse 1 1 9 7879 end",
        "endrun",
    )


def test_missing_p0_is_hang_or_end_by_corpus_then_run_json(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    capture = captures / "cap"
    write_run(capture, "hang", stdout=FOUND + parse_line("in/a.in"), exit_code=-1)
    write_run(capture, "corpus", stdout=FOUND + parse_line("in/a.in"), exit_code=-1)
    write_corpus(capture, {"corpus": 0})

    lines = build_golden(captures, ["cap"], ()).plan_text.splitlines()

    assert "parse 1 1 1 - hang" in lines
    assert "parse 1 1 1 - end" in lines


def test_corpus_entry_without_a_run_is_rejected(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(captures / "cap", "r1", stdout="")
    write_corpus(captures / "cap", {"ghost": 0})

    with pytest.raises(HarnessError, match="names unknown runs"):
        build_golden(captures, ["cap"], ())


def test_p0_ifilein_must_follow_the_restart_chain(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "r1",
        stdout=FOUND + parse_line("in/a.in") + parse_line("in/b.in") + parse_line("in/c.in"),
        p0=p0_block(1, 1, 1, "") + p0_block(2, 3, 1, ""),
    )

    with pytest.raises(HarnessError, match="parse 2 has Ifilein 3, expected 2"):
        build_golden(captures, ["cap"], ())


def test_restart_must_begin_ifilein_at_one(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "r1",
        stdout=FOUND + parse_line("in/a.in") + FOUND + parse_line("in/b.in"),
        p0=p0_block(1, 1, 1, "") + p0_block(2, 2, 1, ""),
    )

    with pytest.raises(HarnessError, match="parse 2 has Ifilein 2, expected 1"):
        build_golden(captures, ["cap"], ())


def test_p0_records_are_numbered_from_one(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "r1",
        stdout=FOUND + parse_line("in/a.in"),
        p0=p0_block(2, 1, 1, ""),
    )

    with pytest.raises(HarnessError, match=r"records must be rec=1\.\.n"):
        build_golden(captures, ["cap"], ())


def test_p0_count_must_match_the_parses(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "r1",
        stdout=FOUND + parse_line("in/a.in"),
        p0=p0_block(1, 1, 1, "") + p0_block(2, 2, 1, ""),
    )

    with pytest.raises(HarnessError, match="2 P0 records for 1 parses"):
        build_golden(captures, ["cap"], ())


def test_p0_variable_lines_must_be_contiguous(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    p0 = text(
        f"{CTX1} V - B I 1:2",
        f"{CTX1} V 1 I 5",
        f"{CTX1} Emode - I 1",
        f"{CTX1} V 2 I 6",
        f"{CTX1} Ifilein - I 1",
        f'{CTX1} Cfileoutlmd_full - Z "xy"',
    )
    write_run(captures / "cap", "r1", stdout=FOUND + parse_line("in/a.in"), p0=p0)

    with pytest.raises(HarnessError, match="variable V is not contiguous"):
        build_golden(captures, ["cap"], ())


def test_blank_line_in_p0_is_rejected(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "r1",
        stdout=FOUND + parse_line("in/a.in"),
        p0=p0_block(1, 1, 1, "xy") + "\n",
    )

    with pytest.raises(HarnessError, match="has blank lines"):
        build_golden(captures, ["cap"], ())


def test_first_parse_without_restart_or_p0_is_rejected(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(captures / "cap", "r1", stdout=parse_line("in/a.in"), exit_code=-1)

    with pytest.raises(HarnessError, match="no Ifilein to continue from"):
        build_golden(captures, ["cap"], ())


def test_file_in_must_match_run_json(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(captures / "cap", "r1", stdout="", run_extra={"file_in": {"sha256": "0" * 64}})

    with pytest.raises(HarnessError, match="does not match file_in"):
        build_golden(captures, ["cap"], ())


def test_run_without_work_file_in_is_skipped_with_a_comment(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "r1",
        stdout=FOUND + parse_line("a.in"),
        filein=None,
        p0=p0_block(1, 1, 1, "x"),
    )
    write_run(captures / "cap", "r2", stdout="")

    golden = build_golden(captures, ["cap"], ())

    assert golden.plan_text == text(
        "# m6-p0 plan 2",
        "# skipped cap r1: the store keeps no work/file.in",
        "run 1 cap r2",
        f"filein {FILEIN.hex()}",
        "work",
        "endrun",
    )
    assert golden.fingerprint_text == text("# m6-p0 fingerprints 2")
    assert golden.sources == (
        ("cap", "r1/run.json"),
        ("cap", "r2/run.json"),
        ("cap", "r2/stdout.log"),
        ("cap", "r2/work/file.in"),
    )


def test_recorded_file_in_without_bytes_is_rejected(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "r1",
        stdout="",
        filein=None,
        run_extra={"file_in": {"sha256": "0" * 64}},
    )

    with pytest.raises(HarnessError, match=r"records file_in but work/file.in is absent"):
        build_golden(captures, ["cap"], ())


def test_empty_file_in_is_recorded_as_dash(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(captures / "cap", "r1", stdout="", filein=b"")

    golden = build_golden(captures, ["cap"], ())

    assert golden.plan_text == text(
        "# m6-p0 plan 2",
        "run 1 cap r1",
        "filein -",
        "work",
        "endrun",
    )
    assert golden.fingerprint_text == text("# m6-p0 fingerprints 2")


def test_input_and_work_file_dests_are_derived(tmp_path: Path) -> None:
    seq = b"seq\n"
    lst = b"list\n"
    other = b"other\n"
    inputs = make_inputs(tmp_path, {"s.in": seq, "l.in": lst})
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "seq",
        stdout=FOUND + parse_line("in/s.in"),
        input_entry={"name": "s.in", "sha256": sha(seq)},
    )
    write_run(
        captures / "cap",
        "lst",
        stdout="",
        input_entry={"name": "l.in", "sha256": sha(lst)},
        work_files=[{"name": "w.dat", "sha256": sha(other)}],
    )

    golden = build_golden(captures, ["cap"], (("harness/inputs", inputs),))

    assert golden.plan_text == text(
        "# m6-p0 plan 2",
        f"file 1 lists/l.in harness/inputs/l.in {sha(lst)}",
        f"file 2 w.dat - {sha(other)}",
        f"file 3 in/s.in harness/inputs/s.in {sha(seq)}",
        "run 1 cap lst",
        f"filein {FILEIN.hex()}",
        "work 1 2",
        "endrun",
        "run 2 cap seq",
        f"filein {FILEIN.hex()}",
        "work 3",
        "parse 1 1 1 - end",
        "endrun",
    )
    assert golden.fingerprint_text == text("# m6-p0 fingerprints 2")


def test_two_files_for_one_dest_are_rejected(tmp_path: Path) -> None:
    captures = tmp_path / "captures"
    write_run(
        captures / "cap",
        "r1",
        stdout=FOUND + parse_line("in/a.in"),
        input_entry={"name": "a.in", "sha256": sha(b"x")},
        work_files=[{"dest": "in/a.in", "name": "other.in", "sha256": sha(b"y")}],
    )

    with pytest.raises(HarnessError, match=r"two files are written to in/a\.in"):
        build_golden(captures, ["cap"], ())


def test_first_source_root_wins_and_hidden_files_are_skipped(tmp_path: Path) -> None:
    data = b"shared\n"
    first = make_inputs(tmp_path, {".stale.in": data, "x.in": data})
    second = tmp_path / "second"
    second.mkdir()
    (second / "x.in").write_bytes(data)
    write_run(
        tmp_path / "captures" / "cap",
        "r1",
        stdout="",
        work_files=[{"dest": "x.in", "name": "x.in", "sha256": sha(data)}],
    )

    golden = build_golden(
        tmp_path / "captures",
        ["cap"],
        (("harness/inputs", first), ("validation/reference", second)),
    )

    assert golden.plan_text == text(
        "# m6-p0 plan 2",
        f"file 1 x.in harness/inputs/x.in {sha(data)}",
        "run 1 cap r1",
        f"filein {FILEIN.hex()}",
        "work 1",
        "endrun",
    )


def test_default_source_roots_are_searched_in_order() -> None:
    prefixes = [prefix for prefix, _ in default_source_roots()]

    assert prefixes == [
        "harness/inputs",
        "Reference/GEF_code/wrkdir",
        "validation/reference",
    ]


def test_unknown_capture_is_rejected(tmp_path: Path) -> None:
    with pytest.raises(HarnessError, match="capture cap not found"):
        build_golden(tmp_path, ["cap"], ())


def test_write_golden_writes_both_files_and_derived_record(tmp_path: Path) -> None:
    out = tmp_path / "m6-p0"
    golden = Golden(plan_text="plan\n", fingerprint_text="fp\n", sources=())

    write_golden(out, golden, replace=False)

    assert (out / "plan.txt").read_bytes() == b"plan\n"
    assert (out / "fingerprints.txt").read_bytes() == b"fp\n"
    record: dict[str, object] = json.loads((out / "derived.json").read_text(encoding="utf-8"))
    assert record["kind"] == "store-derived"
    assert record["tool"] == "python3 -m harness.p0_golden"
    assert record["sources"] == []
    outputs = cast("dict[str, str]", record["outputs"])
    assert sorted(outputs) == ["fingerprints.txt", "plan.txt"]


def test_write_golden_refuses_an_existing_directory(tmp_path: Path) -> None:
    out = tmp_path / "m6-p0"
    out.mkdir()
    (out / "plan.txt").write_text("keep\n", encoding="utf-8")
    golden = Golden(plan_text="new\n", fingerprint_text="new\n", sources=())

    with pytest.raises(HarnessError, match="--replace"):
        write_golden(out, golden, replace=False)

    assert (out / "plan.txt").read_text(encoding="utf-8") == "keep\n"


def test_write_golden_replace_clears_the_old_directory(tmp_path: Path) -> None:
    out = tmp_path / "m6-p0"
    out.mkdir()
    (out / "stale.txt").write_text("old\n", encoding="utf-8")
    golden = Golden(plan_text="plan\n", fingerprint_text="fp\n", sources=())

    write_golden(out, golden, replace=True)

    assert sorted(path.name for path in out.iterdir()) == [
        "derived.json",
        "fingerprints.txt",
        "plan.txt",
    ]
