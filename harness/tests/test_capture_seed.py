# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for harness.capture_seed: script generation, result parsing, binary verification."""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

import pytest

from harness.capture_seed import (
    VALIDATION_MANIFEST,
    capture_seed,
    expected_sha256,
    parse_capture_result,
    render_gdb_script,
    verify_binary,
)
from harness.common import GEF_REFERENCE, HarnessError, sha256_file

GOOD = {
    "seed": 2651126221,
    "randomize_args": [[-1.0, 3]],
    "mt_init_hits": 1,
    "exit_code": 0,
    "error": None,
}


def test_render_gdb_script_is_valid_python_with_literals() -> None:
    script = render_gdb_script(Path("/opt/a b/gef"), Path("/tmp/out dir/capture.json"))
    compile(script, "capture_seed.gdb.py", "exec")
    assert '"/opt/a b/gef"' in script
    assert '"/tmp/out dir/capture.json"' in script
    assert '"run < /dev/null > ../stdout.log 2> ../stderr.log"' in script
    assert '"*fb_Randomize"' in script
    assert '"*hRndCtxInitMTWIST32"' in script
    assert "$xmm0.v2_double[0]" in script
    assert "seed != -1.0 or algorithm != 3" in script


def test_render_gdb_script_escapes_quotes() -> None:
    script = render_gdb_script(Path('/tmp/we"ird/gef'), Path("/tmp/r.json"))
    compile(script, "capture_seed.gdb.py", "exec")


def test_parse_capture_result_good() -> None:
    result = parse_capture_result(json.dumps(GOOD))
    assert result.seed == 2651126221
    assert result.randomize_args == [(-1.0, 3)]
    assert result.mt_init_hits == 1
    assert result.exit_code == 0
    assert result.error is None


def test_parse_capture_result_with_error_and_no_seed() -> None:
    data = {**GOOD, "seed": None, "exit_code": None, "error": "boom", "randomize_args": []}
    result = parse_capture_result(json.dumps(data))
    assert (result.seed, result.exit_code, result.error) == (None, None, "boom")


@pytest.mark.parametrize(
    "text",
    [
        "not json",
        "[]",
        json.dumps({"seed": 1}),
        json.dumps({**GOOD, "seed": -1}),
        json.dumps({**GOOD, "seed": 2**32}),
        json.dumps({**GOOD, "randomize_args": [[1]]}),
        json.dumps({**GOOD, "mt_init_hits": "1"}),
        json.dumps({**GOOD, "error": 5}),
    ],
)
def test_parse_capture_result_rejects_malformed(text: str) -> None:
    with pytest.raises(HarnessError):
        parse_capture_result(text)


def test_expected_sha256_reads_manifest_entry(tmp_path: Path) -> None:
    manifest = tmp_path / "m.sha256"
    manifest.write_text(
        "# comment\n" + "a" * 64 + "  test_run/other\n" + "b" * 64 + "  test_run/gef_reference\n",
        encoding="utf-8",
    )
    assert expected_sha256(manifest) == "b" * 64
    manifest.write_text("# nothing\n", encoding="utf-8")
    with pytest.raises(HarnessError, match="no entry"):
        expected_sha256(manifest)


def test_verify_binary_rejects_mismatch(tmp_path: Path) -> None:
    binary = tmp_path / "gef"
    binary.write_bytes(b"not the reference")
    manifest = tmp_path / "m.sha256"
    manifest.write_text("c" * 64 + "  test_run/gef_reference\n", encoding="utf-8")
    with pytest.raises(HarnessError, match="unverified binary"):
        verify_binary(binary, manifest)
    # The capture refuses before creating anything.
    with pytest.raises(HarnessError, match="unverified binary"):
        capture_seed(binary, tmp_path / "in.in", tmp_path / "out", manifest)
    assert not (tmp_path / "out").exists()


@pytest.mark.validation
@pytest.mark.gdb
def test_reference_binary_matches_manifest() -> None:
    if not GEF_REFERENCE.is_file():
        pytest.skip("validation/test_run/gef_reference is not available")
    assert verify_binary(GEF_REFERENCE, VALIDATION_MANIFEST)


FAKE_C = r"""
#include <stdio.h>
#include <stdlib.h>
__attribute__((noinline)) void hRndCtxInitMTWIST32(unsigned int seed) {
    fprintf(stderr, "init %u\n", seed);
}
__attribute__((noinline)) void fb_Randomize(double seed, int algo) {
    (void)algo;
    if (seed == -1.0) hRndCtxInitMTWIST32(MODE_SEED);
    if (getenv("TWICE")) hRndCtxInitMTWIST32(1);
}
int main(void) {
    fb_Randomize(ARG_SEED, ARG_ALGO);
    puts("program output");
    FILE *f = fopen("result.txt", "w"); fputs("ok\n", f); fclose(f);
    return EXIT_CODE;
}
"""


def _fake_reference(
    tmp_path: Path, seed: str, algo: str, exit_code: int = 0, mode_seed: int = 4000000000
) -> tuple[Path, Path]:
    if shutil.which("gcc") is None or shutil.which("gdb") is None:
        pytest.skip("gcc and gdb are required")
    source = tmp_path / "fake.c"
    source.write_text(FAKE_C, encoding="utf-8")
    binary = tmp_path / f"fake_{seed}_{algo}_{exit_code}"
    subprocess.run(
        [
            "gcc",
            "-O0",
            "-no-pie",
            f"-DARG_SEED={seed}",
            f"-DARG_ALGO={algo}",
            f"-DEXIT_CODE={exit_code}",
            f"-DMODE_SEED={mode_seed}u",
            "-o",
            str(binary),
            str(source),
        ],
        check=True,
    )
    manifest = tmp_path / f"m_{binary.name}.sha256"
    manifest.write_text(f"{sha256_file(binary)}  test_run/gef_reference\n", encoding="utf-8")
    return binary, manifest


@pytest.mark.gdb
def test_capture_with_fake_binary(tmp_path: Path) -> None:
    binary, manifest = _fake_reference(tmp_path, "-1.0", "3")
    sequence = tmp_path / "seq.in"
    sequence.write_text(" 1\n0\n", encoding="utf-8")
    result, record = capture_seed(binary, sequence, tmp_path / "cap", manifest)
    assert result.seed == 4000000000
    assert result.mt_init_hits == 1
    assert record["mode"] == "capture"
    assert record["captured_seed"] == 4000000000
    assert (tmp_path / "cap" / "stdout.log").read_text(encoding="utf-8") == "program output\n"
    assert (tmp_path / "cap" / "stderr.log").read_text(encoding="utf-8") == "init 4000000000\n"
    assert (tmp_path / "cap" / "work" / "result.txt").read_text(encoding="utf-8") == "ok\n"
    assert json.loads((tmp_path / "cap" / "run.json").read_text(encoding="utf-8"))["exit_code"] == 0
    assert (tmp_path / "cap" / "gdb.log").is_file()


@pytest.mark.gdb
def test_capture_rejects_wrong_randomize_arguments(tmp_path: Path) -> None:
    binary, manifest = _fake_reference(tmp_path, "2.0", "3")
    sequence = tmp_path / "seq.in"
    sequence.write_text(" 1\n0\n", encoding="utf-8")
    with pytest.raises(HarnessError, match="expected"):
        capture_seed(binary, sequence, tmp_path / "cap", manifest)
    assert json.loads((tmp_path / "cap" / "run.json").read_text(encoding="utf-8"))[
        "randomize_args"
    ] == [[2.0, 3]]


@pytest.mark.gdb
def test_capture_aborts_on_second_generator_init(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    binary, manifest = _fake_reference(tmp_path, "-1.0", "3")
    sequence = tmp_path / "seq.in"
    sequence.write_text(" 1\n0\n", encoding="utf-8")
    monkeypatch.setenv("TWICE", "1")
    with pytest.raises(HarnessError, match="hit 2 times"):
        capture_seed(binary, sequence, tmp_path / "cap", manifest)


@pytest.mark.gdb
def test_capture_reports_nonzero_program_exit(tmp_path: Path) -> None:
    binary, manifest = _fake_reference(tmp_path, "-1.0", "3", exit_code=4)
    sequence = tmp_path / "seq.in"
    sequence.write_text(" 1\n0\n", encoding="utf-8")
    with pytest.raises(HarnessError, match="program exit 4"):
        capture_seed(binary, sequence, tmp_path / "cap", manifest)
