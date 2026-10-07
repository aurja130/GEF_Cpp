# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for harness.rndlog and the ``scope`` / ``rndlog`` patches."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from pathlib import Path

import pytest

from harness.common import GEF_SOURCE_DIR, PATCHES_DIR, PATCHSETS_DIR, HarnessError
from harness.fbmt import FbMtRng
from harness.rndlog import (
    RndLogError,
    RndRecord,
    main,
    parse_line,
    parse_lines,
    read_log,
    summarize,
)

GOOD = [
    "1 GEF.bas:7931 0cc85a7e",
    "2 GEF.bas:17963 641e9339",
    "3 GEF.bas:17964 69492bbd",
    "10 GEF.bas:17963 ffffffff",
    "11 GEF.bas:4245 00000000",
]


def test_parse_line_fields() -> None:
    record = parse_line("42 GEF.bas:17963 80000000")
    assert record == RndRecord(42, "GEF.bas", 17963, 0x80000000)
    assert record.site == "GEF.bas:17963"
    assert record.value == 0.5


def test_value_is_exact_u32_over_2_pow_32() -> None:
    assert parse_line("1 GEF.bas:1 ffffffff").value == 4294967295 / 4294967296
    assert parse_line("1 GEF.bas:1 00000001").value == 2.0**-32


@pytest.mark.parametrize(
    "text",
    [
        "",
        "1 GEF.bas:7931",
        "1 GEF.bas:7931 0cc85a7e extra",
        "x GEF.bas:7931 0cc85a7e",
        "1 GEF.bas 0cc85a7e",
        "1 GEF.bas:abc 0cc85a7e",
        "1 GEF.bas:7931 0CC85A7E",
        "1 GEF.bas:7931 0cc85a7",
        "1  GEF.bas:7931 0cc85a7e",
    ],
)
def test_parse_line_rejects_malformed(text: str) -> None:
    with pytest.raises(RndLogError, match="line 7"):
        parse_line(text, 7)


def test_parse_lines_requires_increasing_counters() -> None:
    with pytest.raises(RndLogError, match="does not follow"):
        list(parse_lines(["5 GEF.bas:1 00000000\n", "5 GEF.bas:1 00000000\n"]))
    with pytest.raises(RndLogError, match="line 2"):
        list(parse_lines(["5 GEF.bas:1 00000000\n", "4 GEF.bas:1 00000000\n"]))


def test_parse_lines_strips_line_endings() -> None:
    records = list(parse_lines(["1 GEF.bas:1 0000000a\r\n", "2 GEF.bas:2 0000000b\n"]))
    assert [r.u32 for r in records] == [10, 11]


def test_summarize_counts_range_and_segments() -> None:
    summary = summarize(parse_lines(GOOD))
    assert summary.records == 5
    assert (summary.first_counter, summary.last_counter) == (1, 11)
    assert summary.segments == 2  # 1-3, then 10-11
    # Sorted by line number, not lexically.
    assert list(summary.per_site) == [
        "GEF.bas:4245",
        "GEF.bas:7931",
        "GEF.bas:17963",
        "GEF.bas:17964",
    ]
    assert summary.per_site["GEF.bas:17963"] == 2


def test_summarize_empty() -> None:
    summary = summarize([])
    assert (summary.records, summary.segments, summary.per_site) == (0, 0, {})


def test_read_log_missing_file(tmp_path: Path) -> None:
    with pytest.raises(RndLogError, match="cannot read"):
        list(read_log(tmp_path / "absent.log"))


def test_cli_summary_and_head(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    log = tmp_path / "rnd.log"
    log.write_text("\n".join(GOOD) + "\n", encoding="ascii")
    assert main(["summary", str(log)]) == 0
    out = capsys.readouterr().out
    assert "records        5" in out
    assert "counter range  1 .. 11" in out
    assert "GEF.bas:17963" in out
    assert main(["summary", str(log), "--json"]) == 0
    data = json.loads(capsys.readouterr().out)
    assert data["segments"] == 2
    assert data["per_site"]["GEF.bas:7931"] == 1
    assert main(["head", str(log), "-n", "2"]) == 0
    lines = capsys.readouterr().out.splitlines()
    assert len(lines) == 2
    assert lines[0].startswith("1 GEF.bas:7931 0cc85a7e 0.0499")


def test_cli_reports_errors(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    log = tmp_path / "rnd.log"
    log.write_text("garbage\n", encoding="ascii")
    assert main(["summary", str(log)]) == 1
    assert "malformed record" in capsys.readouterr().err


# --- the patches ----------------------------------------------------------------------------

PATCH_ORDER = ("seed", "scope", "rndlog")
GEF_BAS = GEF_SOURCE_DIR / "GEF.bas"
needs_source = pytest.mark.skipif(
    shutil.which("patch") is None or not GEF_BAS.is_file(),
    reason="needs GNU patch and the Reference/GEF_code submodule",
)


def _patch(src: Path, name: str, *, dry_run: bool = False) -> None:
    cmd = ["patch", "-p1", "--fuzz=0", "--forward", "--batch", "--no-backup-if-mismatch"]
    if dry_run:
        cmd.append("--dry-run")
    proc = subprocess.run(
        cmd,
        input=(PATCHES_DIR / f"{name}.patch").read_bytes(),
        cwd=src,
        capture_output=True,
        check=False,
    )
    assert proc.returncode == 0, f"{name}.patch: {proc.stdout.decode()}{proc.stderr.decode()}"


def _stacked(tmp_path: Path, names: tuple[str, ...]) -> Path:
    """A scratch source directory holding GEF.bas with ``names`` applied in order."""
    src = tmp_path / "src"
    src.mkdir()
    shutil.copy(GEF_BAS, src / "GEF.bas")
    for name in names:
        _patch(src, name)
    return src


@needs_source
@pytest.mark.parametrize("names", [("scope",), ("scope", "rndlog"), PATCH_ORDER])
def test_patches_apply_on_pristine_source_in_stacking_order(
    tmp_path: Path, names: tuple[str, ...]
) -> None:
    names = tuple(n for n in names if (PATCHES_DIR / f"{n}.patch").is_file())
    assert "scope" in names
    src = tmp_path / "src"
    src.mkdir()
    shutil.copy(GEF_BAS, src / "GEF.bas")
    for name in names:
        _patch(src, name, dry_run=True)
        _patch(src, name)
    assert (src / "harness_scope.bi").is_file()
    assert (src / "harness_rndlog.bi").is_file() == ("rndlog" in names)


@needs_source
def test_scope_and_rndlog_keep_original_line_numbers(tmp_path: Path) -> None:
    """Site tags rely on the patched file having the pristine line numbering."""
    original = GEF_BAS.read_bytes().split(b"\n")
    patched = (_stacked(tmp_path, ("scope", "rndlog")) / "GEF.bas").read_bytes().split(b"\n")
    assert len(patched) == len(original)
    changed = [i + 1 for i, (a, b) in enumerate(zip(original, patched, strict=True)) if a != b]
    assert changed == [1, 446, 3442, 3447, 4811, 7922, 9997, 15582]


def test_patchset_seed_rndlog_is_canonical() -> None:
    lines = (PATCHSETS_DIR / "seed-rndlog.txt").read_text(encoding="utf-8").splitlines()
    assert [ln for ln in lines if ln and not ln.startswith("#")] == list(PATCH_ORDER)


def _find_fbc() -> Path:
    from tools.toolchain.fbc import FbcError, resolve_fbc

    try:
        return resolve_fbc()
    except FbcError:
        pytest.skip("pinned fbc is not available")


def _compile(fbc: Path, src: Path, main_bas: str, *defines: str) -> Path:
    cmd = [str(fbc), main_bas, *[a for d in defines for a in ("-d", d)]]
    proc = subprocess.run(cmd, cwd=src, capture_output=True, text=True, check=False)
    from tools.toolchain.fbc import filter_fbc_stderr

    assert proc.returncode == 0, filter_fbc_stderr(proc.stderr) + proc.stdout
    return src / main_bas.removesuffix(".bas")


_SCOPE_PROBE = """
#include "harness_scope.bi"
Dim As Long Istep, Ipass, Ievent
Dim As String Cout
For Istep = 0 To 3
  For Ipass = 0 To 2
    For Ievent = 0 To 4
      Harness_Step = Istep: Harness_Pass = Ipass: Harness_Event = Ievent
      If Harness_Traced() Then Cout &= Istep & "." & Ipass & "." & Ievent & " "
    Next
  Next
Next
Print Trim(Cout)
Harness_Step = 2
Print Trim(Str(Harness_StepSelected()))
"""


def _run_scope_probe(
    src: Path, exe: Path, steps: str | None, passes: str | None, events: str | None
) -> subprocess.CompletedProcess[str]:
    env = {k: v for k, v in os.environ.items() if not k.startswith("GEF_")}
    for key, value in (
        ("GEF_TRACE_STEPS", steps),
        ("GEF_TRACE_PASSES", passes),
        ("GEF_TRACE_EVENTS", events),
    ):
        if value is not None:
            env[key] = value
    return subprocess.run([str(exe)], cwd=src, env=env, capture_output=True, text=True, check=False)


@needs_source
@pytest.mark.fbc
def test_scope_selectors_and_traced_predicate(tmp_path: Path) -> None:
    fbc = _find_fbc()
    src = _stacked(tmp_path, ("scope",))
    (src / "probe.bas").write_text(_SCOPE_PROBE, encoding="utf-8")
    exe = _compile(fbc, src, "probe.bas")

    # Nothing selected unless steps AND passes are set.
    for args in ((None, None, None), ("1", None, None), (None, "0", None), ("", "", "")):
        done = _run_scope_probe(src, exe, *args)
        assert done.returncode == 0
        assert done.stdout.splitlines() == ["", "0"]

    # Outside the event loop (event 0) the event selector is not consulted.
    done = _run_scope_probe(src, exe, "1", "0", "2-3")
    assert done.stdout.splitlines() == ["1.0.0 1.0.2 1.0.3", "0"]
    done = _run_scope_probe(src, exe, "2,0", "1-2", None)
    assert done.stdout.splitlines() == ["0.1.0 0.2.0 2.1.0 2.2.0", "1"]
    done = _run_scope_probe(src, exe, " 3 , 1-1", "0", "4,1")
    assert done.stdout.splitlines() == ["1.0.0 1.0.1 1.0.4 3.0.0 3.0.1 3.0.4", "0"]


@needs_source
@pytest.mark.fbc
@pytest.mark.parametrize(
    "bad", ["x", "1,", ",1", "1,,2", "3-1", "1-", "-1", "1-2-3", "99999999999"]
)
def test_scope_rejects_bad_selector(tmp_path: Path, bad: str) -> None:
    fbc = _find_fbc()
    src = _stacked(tmp_path, ("scope",))
    (src / "probe.bas").write_text(_SCOPE_PROBE, encoding="utf-8")
    exe = _compile(fbc, src, "probe.bas")
    done = _run_scope_probe(src, exe, "1", bad, None)
    assert done.returncode == 2
    assert done.stdout.startswith("<harness> GEF_TRACE_PASSES must be")


_RND_PROBE = """
#include "harness_scope.bi"
#include "harness_rndlog.bi"
Randomize 42, 3
Dim As Double R, Rsum
Dim As Long I
Harness_Step = 1: Harness_Pass = 0
For I = 1 To 5
  R = Rnd                    ' draw 1..5, outside the event loop
  Rsum += R
Next
For I = 1 To 4
  Harness_Event = I
  Rsum += Rnd * 2 + Rnd      ' two draws per event, evaluated left to right
Next
Harness_Event = 0
Harness_Step = 2
Rsum += Rnd                  ' not selected: counted, not logged
Print Hex(CULngInt(Rsum * 1048576))
#ifdef GEF_RNDLOG
Print Trim(Str(Harness_Draws))
#endif
"""


@needs_source
@pytest.mark.fbc
def test_rndlog_wrapper_logs_selected_draws_and_keeps_values(tmp_path: Path) -> None:
    fbc = _find_fbc()
    src = _stacked(tmp_path, ("scope", "rndlog"))
    (src / "probe.bas").write_text(_RND_PROBE, encoding="utf-8")
    logged = _compile(fbc, src, "probe.bas", "GEF_RNDLOG")
    logged = logged.rename(src / "probe_logged")
    plain = _compile(fbc, src, "probe.bas")  # without the define Rnd is untouched

    work = tmp_path / "work"
    work.mkdir()
    env = {k: v for k, v in os.environ.items() if not k.startswith("GEF_")}
    env.update(GEF_TRACE_STEPS="1", GEF_TRACE_PASSES="0", GEF_TRACE_EVENTS="2-3")
    done = subprocess.run(
        [str(logged)], cwd=work, env=env, capture_output=True, text=True, check=False
    )
    assert done.returncode == 0, done.stderr
    base = subprocess.run(
        [str(plain)], cwd=work, env=env, capture_output=True, text=True, check=False
    )
    assert base.returncode == 0
    # Same arithmetic result; the draw counter counts all 14 draws, logged or not.
    assert done.stdout.splitlines()[0] == base.stdout.splitlines()[0]
    assert done.stdout.splitlines()[1] == "14"
    records = list(read_log(work / "rnd.log"))
    # Draws 1-5 (outside the event loop), then events 2 and 3: draws 8-9 and 10-11.
    assert [r.counter for r in records] == [1, 2, 3, 4, 5, 8, 9, 10, 11]
    assert {r.file for r in records} == {"probe.bas"}
    mt = FbMtRng(42).u32_stream(14)
    assert [r.u32 for r in records] == [mt[r.counter - 1] for r in records]
    # The two Rnd of `Rnd * 2 + Rnd` share a line.
    assert records[5].line == records[6].line != records[0].line


@needs_source
@pytest.mark.fbc
def test_rndlog_sites_match_every_rnd_in_gef_source(tmp_path: Path) -> None:
    """Each of the 60 Rnd calls in GEF.c is replaced once, tagged with its original line."""
    fbc = _find_fbc()
    src = tmp_path / "src"
    shutil.copytree(GEF_SOURCE_DIR, src)
    for name in PATCH_ORDER:
        if (PATCHES_DIR / f"{name}.patch").is_file():
            _patch(src, name)
    proc = subprocess.run(
        [str(fbc), "-gen", "gcc", "-r", "-d", "GEF_RNDLOG", "GEF.bas"],
        cwd=src,
        capture_output=True,
        text=True,
        check=False,
    )
    assert proc.returncode == 0, proc.stderr
    c_text = (src / "GEF.c").read_text(encoding="latin-1")
    sites = sorted(
        int(m.group(2)) for m in re.finditer(r'HARNESS_RND\( \(char\*\)"([^"]+)", (\d+) \)', c_text)
    )
    expected = _rnd_lines(GEF_BAS)
    assert len(expected) == 60
    assert sites == expected


def _rnd_lines(path: Path) -> list[int]:
    """Line of every ``Rnd`` token outside strings and comments (with multiplicity)."""
    found: list[int] = []
    depth = 0
    for number, text in enumerate(path.read_bytes().decode("latin-1").split("\n"), 1):
        code: list[str] = []
        i = 0
        while i < len(text):
            if depth:
                end = text.find("'/", i)
                if end < 0:
                    break
                depth -= 1
                i = end + 2
            elif text.startswith("/'", i):
                depth += 1
                i += 2
            elif text[i] == "'":
                break
            elif text[i] == '"':
                end = text.find('"', i + 1)
                i = len(text) if end < 0 else end + 1
                code.append(" ")
            else:
                code.append(text[i])
                i += 1
        found += [number] * len(
            re.findall(r"(?<![A-Za-z0-9_])rnd(?![A-Za-z0-9_])", "".join(code), re.I)
        )
    return found


def test_error_type_is_harness_error() -> None:
    assert issubclass(RndLogError, HarnessError)
