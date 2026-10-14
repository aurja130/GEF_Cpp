# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the arglog patch generator (harness.arglog_patch) and reader (harness.arglog)."""

from __future__ import annotations

import math
import shutil
import subprocess
from pathlib import Path

import pytest

from harness.arglog import (
    decode,
    is_logged,
    logged_calls,
    parse_header,
    parse_record,
    read_arglog,
    read_counts,
    summarize,
)
from harness.arglog import main as arglog_main
from harness.arglog_patch import FUNCTIONS, PATCH_FILE, SITES, discover, generate
from harness.common import GEF_SOURCE_DIR, PATCHES_DIR, PATCHSETS_DIR, HarnessError

# --- reader -----------------------------------------------------------------------------------


def test_decode_every_type() -> None:
    assert decode("f32", "3f800000") == 1.0
    assert decode("f32", "80000000") == 0.0
    assert math.copysign(1.0, float(decode("f32", "80000000"))) == -1.0  # type: ignore[arg-type]
    assert math.isnan(float(decode("f32", "7fc00000")))  # type: ignore[arg-type]
    assert decode("f64", "3ff8000000000000") == 1.5
    assert decode("i64", "ffffffffffffffff") == -1
    assert decode("i64", "0000000000000062") == 98
    assert decode("u8", "ff") == 255
    assert decode("str", "4753") == b"GS"
    assert decode("str", "-") == b""
    assert decode("f32[]", "0") == ()
    assert decode("f32[]", "2:3f800000,40000000") == (1.0, 2.0)
    assert decode("f32hash", "a2d8c376ef65f02f") == 0xA2D8C376EF65F02F


@pytest.mark.parametrize(
    ("typ", "token"),
    [
        ("f32", "3f80000"),  # 7 digits
        ("f32", "3F800000"),  # upper case
        ("i64", "62"),
        ("str", "475"),
        ("f32[]", "2:3f800000"),
        ("f32[]", "x"),
        ("nope", "00"),
    ],
)
def test_decode_rejects_malformed_tokens(typ: str, token: str) -> None:
    with pytest.raises(HarnessError):
        decode(typ, token)


def test_header_and_record() -> None:
    name, fields = parse_header("# arglog 1 Beta_Equi A1:f32 b.in:f32 b.out:f32 global.f:i64")
    assert name == "Beta_Equi"
    assert [(f.name, f.type) for f in fields] == [
        ("A1", "f32"),
        ("b.in", "f32"),
        ("b.out", "f32"),
        ("global.f", "i64"),
    ]
    rec = parse_record(
        "7 1 -2 0 GEF.bas:5722 41cdb6dc 3e99999a 3ea353f8 0000000000000000", len(fields)
    )
    assert (rec.seq, rec.step, rec.pass_, rec.event, rec.site) == (7, 1, -2, 0, "GEF.bas:5722")
    with pytest.raises(HarnessError, match="expected 9 fields"):
        parse_record("7 1 0 0 GEF.bas:5722 41cdb6dc", len(fields))
    with pytest.raises(HarnessError, match="not an arglog header"):
        parse_header("# something else")
    with pytest.raises(HarnessError, match="bad field spec"):
        parse_header("# arglog 1 X a:f16")


def test_read_arglog_summary_and_sampling(tmp_path: Path) -> None:
    logs = tmp_path / "arglog"
    logs.mkdir()
    # K = 2 with spread: calls 1, 2, then every 2nd up to 4, every 4th up to 8.
    seqs = list(logged_calls(9, 2, 1))
    assert seqs == [1, 2, 4, 8]
    lines = ["# arglog 1 U_MASS Z:f32 A:f32 result:f32"] + [
        f"{s} 1 0 {s} GEF.bas:16718 42200000 42c60000 c453be4f" for s in seqs
    ]
    (logs / "U_MASS.txt").write_text("\n".join(lines) + "\n", encoding="ascii")
    (logs / "_counts.txt").write_text(
        "# arglog 1 _counts name calls max spread\nU_MASS 9 2 1\nU_Valid 0 2 1\n", encoding="ascii"
    )
    log = read_arglog(logs / "U_MASS.txt")
    assert [r.seq for r in log.records] == seqs
    assert list(log.values("A")) == [99.0] * 4
    assert read_counts(logs / "_counts.txt")["U_MASS"].calls == 9
    summary = summarize(logs)
    assert summary["U_MASS"].complete is True
    assert summary["U_MASS"].fields["Z"] == {"min": 40.0, "max": 40.0}
    assert summary["U_Valid"].records == 0
    # A lost record is detected.
    (logs / "U_MASS.txt").write_text("\n".join(lines[:-1]) + "\n", encoding="ascii")
    assert summarize(logs)["U_MASS"].complete is False
    # Sequence numbers must increase.
    (logs / "U_MASS.txt").write_text("\n".join([lines[0], lines[2], lines[1]]) + "\n")
    with pytest.raises(HarnessError, match="sequence"):
        read_arglog(logs / "U_MASS.txt")


@pytest.mark.parametrize(("k", "spread"), [(0, 1), (1, 1), (3, 0), (3, 1), (5, 1), (64, 1)])
def test_logged_calls_matches_rule(k: int, spread: int) -> None:
    calls = 1000
    assert list(logged_calls(calls, k, spread)) == [
        n for n in range(1, calls + 1) if is_logged(n, k, spread)
    ]


def test_spread_logs_about_k_over_two_per_doubling() -> None:
    k = 1000
    n = sum(1 for _ in logged_calls(k * 2**10, k, 1))
    assert n == k + 10 * k // 2


# --- the patch --------------------------------------------------------------------------------

needs_source = pytest.mark.skipif(
    shutil.which("patch") is None or not (GEF_SOURCE_DIR / "GEF.bas").is_file(),
    reason="needs GNU patch and the Reference/GEF_code submodule",
)


@needs_source
def test_committed_patch_is_current() -> None:
    assert PATCH_FILE.read_text(encoding="latin-1") == generate()


@needs_source
def test_every_function_and_site_is_found() -> None:
    found = discover()
    assert [f.name for f in found] == list(FUNCTIONS)
    beta = next(f for f in found if f.name == "Beta_Equi")
    assert beta.result is None
    assert [p.byref for p in beta.params][-2:] == [True, True]
    assert {s.name for s in SITES} == {"e2_light", "e2_heavy", "pegl_table"}


def _apply(src: Path, name: str) -> None:
    proc = subprocess.run(
        ["patch", "-p1", "--fuzz=0", "--forward", "--batch", "--no-backup-if-mismatch"],
        input=(PATCHES_DIR / f"{name}.patch").read_bytes(),
        cwd=src,
        capture_output=True,
        check=False,
    )
    assert proc.returncode == 0, f"{name}.patch: {proc.stdout.decode()}{proc.stderr.decode()}"


@needs_source
def test_patch_set_applies_and_keeps_other_lines(tmp_path: Path) -> None:
    names = [
        ln.split("#", 1)[0].strip()
        for ln in (PATCHSETS_DIR / "m5-arglog.txt").read_text(encoding="utf-8").splitlines()
    ]
    names = [n for n in names if n]
    assert names == ["seed", "scope", "arglog"]
    src = tmp_path / "src"
    shutil.copytree(GEF_SOURCE_DIR, src)
    for name in names[:-1]:
        _apply(src, name)
    before = (src / "GEF.bas").read_text(encoding="latin-1").splitlines()
    _apply(src, "arglog")
    after = (src / "GEF.bas").read_text(encoding="latin-1").splitlines()
    # Removing the inserted directive lines gives back the file with only the include lines
    # changed (each replaces a blank line).
    kept = [ln for ln in after if not ln.startswith(("#ifdef GEF_ARGLOG", "#undef ", "#define "))]
    kept = [ln for ln in kept if not ln.startswith(("#endif", "#line "))]
    assert len(kept) == len(before)
    changed = [i + 1 for i, (a, b) in enumerate(zip(before, kept, strict=True)) if a != b]
    assert changed == sorted([695, 1820] + [x for s in SITES for x in (s.line_in, s.line_out)])
    assert all(before[i - 1].strip() == "" for i in changed)
    assert (src / "harness_arglog.bi").is_file()
    assert (src / "harness_arglog_wrappers.bi").is_file()


def test_replay_check_reports_required_logs_without_replay(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    logs, replays = tmp_path / "arglog", tmp_path / "replay"
    logs.mkdir()
    replays.mkdir()
    header = "# arglog 1 F1 Z_S_A:f32 result:f32\n"
    record = "1 1 0 0 GEF.bas:15959 40000000 3f800000\n"
    (logs / "F1.txt").write_text(header + record, encoding="ascii")
    (logs / "F2.txt").write_text(header.replace("F1", "F2") + record, encoding="ascii")
    (logs / "F3.txt").write_text(header.replace("F1", "F3"), encoding="ascii")  # no records
    (replays / "F1.txt").write_text("1 40000000 3f800000\n", encoding="ascii")
    assert arglog_main(["replay-check", str(logs), str(replays)]) == 0
    assert arglog_main(["replay-check", str(logs), str(replays), "--require", "F3"]) == 0
    assert arglog_main(["replay-check", str(logs), str(replays), "--require", "F2"]) == 1
    assert "NOT REPLAYED F2" in capsys.readouterr().out
    # A wrong token is a mismatch.
    (replays / "F1.txt").write_text("1 40000000 3f800001\n", encoding="ascii")
    assert arglog_main(["replay-check", str(logs), str(replays)]) == 1
