# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for ``harness.driver``: directives, cut lines, work files and fbc-built drivers."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import pytest

from harness import driver
from harness.common import DRIVERS_DIR, GEF_SOURCE_DIR, HarnessError
from harness.fbmt import FbMtRng
from tools.toolchain.fbc import FbcError, resolve_fbc

# ---------------------------------------------------------------- directive parsing


def test_parse_directives() -> None:
    text = (
        "' header\n"
        "'@include-source utilities.bi\n"
        "  '@cut GEF.bas:18084-18089 as modulo.bi\n"
        "Print 1 ' @not a directive\n"
    )
    assert driver.parse_directives(text) == [
        driver.IncludeSource("utilities.bi"),
        driver.Cut("GEF.bas", 18084, 18089, "modulo.bi"),
    ]


@pytest.mark.parametrize(
    "line",
    [
        "'@include-source ../secret.bi",
        "'@include-source /etc/passwd",
        "'@include-source",
        "'@include-driver ../shared.bi",
        "'@include-driver /abs.bi",
        "'@include-driver",
        "'@cut GEF.bas:10-5 as x.bi",
        "'@cut GEF.bas:0-5 as x.bi",
        "'@cut GEF.bas:1-5 as ../x.bi",
        "'@cut GEF.bas:1-5 x.bi",
        "'@frobnicate x",
    ],
)
def test_parse_directives_rejects(line: str) -> None:
    with pytest.raises(HarnessError):
        driver.parse_directives(line + "\n")


def test_cut_lines_verbatim(tmp_path: Path) -> None:
    src = tmp_path / "a.bas"
    src.write_bytes(b"one\r\ntwo\nthree\xe9\nfour")
    assert driver.cut_lines(src, 2, 3) == b"two\nthree\xe9\n"
    assert driver.cut_lines(src, 1, 4) == src.read_bytes()
    with pytest.raises(HarnessError, match="4 lines"):
        driver.cut_lines(src, 3, 5)


def test_materialise_records(tmp_path: Path) -> None:
    source = tmp_path / "gef"
    source.mkdir()
    (source / "lib.bi").write_text("lib\n")
    (source / "main.bas").write_text("a\nb\nc\n")
    dest = tmp_path / "dest"
    dest.mkdir()
    directives: list[driver.Directive] = [
        driver.IncludeSource("lib.bi"),
        driver.Cut("main.bas", 2, 3, "bc.bi"),
    ]
    includes, cuts = driver._materialise(directives, source, dest)  # pyright: ignore[reportPrivateUsage]
    assert (dest / "lib.bi").read_text() == "lib\n"
    assert (dest / "bc.bi").read_text() == "b\nc\n"
    assert includes == [{"file": "lib.bi", "sha256": hashlib.sha256(b"lib\n").hexdigest()}]
    assert cuts == [
        {
            "file": "main.bas",
            "first": 2,
            "last": 3,
            "as": "bc.bi",
            "source_sha256": hashlib.sha256(b"a\nb\nc\n").hexdigest(),
            "cut_sha256": hashlib.sha256(b"b\nc\n").hexdigest(),
        }
    ]


def test_missing_driver_and_source(tmp_path: Path) -> None:
    fake_fbc = tmp_path / "fbc"  # never executed: errors precede compilation
    with pytest.raises(HarnessError, match="not found"):
        driver.build("nope", drivers_dir=tmp_path, build_root=tmp_path / "b", fbc=fake_fbc)
    with pytest.raises(HarnessError, match="bad driver name"):
        driver.build("../x", drivers_dir=tmp_path, build_root=tmp_path / "b", fbc=fake_fbc)
    with pytest.raises(HarnessError, match="GEF source file"):
        driver._materialise(  # pyright: ignore[reportPrivateUsage]
            [driver.IncludeSource("missing.bi")], tmp_path, tmp_path
        )


# ---------------------------------------------------------------- fbc-built drivers


@pytest.fixture
def real_fbc() -> Path:
    try:
        return resolve_fbc()
    except FbcError as exc:
        pytest.skip(f"pinned fbc unavailable: {exc}")


CUT_DRIVER = """\
'@include-source utilities.bi
'@cut GEF.bas:18084-18089 as modulo.bi
#include "utilities.bi"
#include "modulo.bi"
Print Min(2.0, 3.0); Max(2.0, 3.0); Modulo(17, 5)
"""


@pytest.mark.fbc
def test_include_and_cut_driver(real_fbc: Path, tmp_path: Path) -> None:
    if not (GEF_SOURCE_DIR / "GEF.bas").is_file():
        pytest.skip("GEF submodule not checked out")
    drivers = tmp_path / "drivers"
    drivers.mkdir()
    (drivers / "cutdemo.bas").write_text(CUT_DRIVER)
    result = driver.run(
        "cutdemo",
        drivers_dir=drivers,
        build_root=tmp_path / "build",
        fbc=real_fbc,
        source_date_epoch=0,
    )
    assert result.returncode == 0
    assert result.out_dir == tmp_path / "build" / "cutdemo" / "run-1"
    assert (result.out_dir / "stdout.txt").read_text().split() == ["2", "3", "2"]
    rec = result.record
    assert rec["includes"][0]["file"] == "utilities.bi"
    cut = rec["cuts"][0]
    assert (cut["file"], cut["first"], cut["last"], cut["as"]) == (
        "GEF.bas",
        18084,
        18089,
        "modulo.bi",
    )
    assert cut["source_sha256"] == driver.sha256_file(GEF_SOURCE_DIR / "GEF.bas")
    assert set(rec["outputs"]) == {"stdout.txt"}
    assert rec["fbc_version"] == "1.10.1"
    assert (result.out_dir / "driver.json").is_file()
    # A second run gets a fresh directory; an up-to-date build is reused.
    second = driver.run(
        "cutdemo",
        drivers_dir=drivers,
        build_root=tmp_path / "build",
        fbc=real_fbc,
        source_date_epoch=0,
    )
    assert second.out_dir.name == "run-2"
    assert second.record["binary_sha256"] == rec["binary_sha256"]
    with pytest.raises(HarnessError, match="not empty"):
        driver.run(
            "cutdemo",
            drivers_dir=drivers,
            build_root=tmp_path / "build",
            out_dir=second.out_dir,
            fbc=real_fbc,
            source_date_epoch=0,
        )


@pytest.mark.fbc
def test_build_error_is_reported(real_fbc: Path, tmp_path: Path) -> None:
    (tmp_path / "bad.bas").write_text("Print (\n")
    with pytest.raises(HarnessError, match="fbc failed"):
        driver.build(
            "bad",
            drivers_dir=tmp_path,
            build_root=tmp_path / "b",
            fbc=real_fbc,
            source_date_epoch=0,
        )


@pytest.mark.fbc
@pytest.mark.parametrize("seed", [42, 0, 4294967295])
def test_rnd_stream_matches_fbmt(real_fbc: Path, tmp_path: Path, seed: int) -> None:
    result = driver.run(
        "rnd_stream",
        [str(seed), "1000"],
        drivers_dir=DRIVERS_DIR,
        build_root=tmp_path / "build",
        fbc=real_fbc,
        source_date_epoch=0,
    )
    assert result.returncode == 0
    lines = (result.out_dir / f"rnd_stream_{seed}.txt").read_text().split()
    rng = FbMtRng(seed)
    assert lines == [f"{rng.next_u32():08x}" for _ in range(1000)]


# ---------------------------------------- C files, includes and work files


def counting_fbc(real_fbc: Path, tmp_path: Path) -> tuple[Path, Path]:
    """A fbc wrapper that logs each call, so tests can count real compiles."""
    log = tmp_path / "fbc-calls.log"
    wrapper = tmp_path / "fbc-wrapper"
    wrapper.write_text(f'#!/bin/sh\necho "$*" >> "{log}"\nexec "{real_fbc}" "$@"\n')
    wrapper.chmod(0o755)
    return wrapper, log


def compiles(log: Path) -> int:
    """Compiles logged by ``counting_fbc``; ``fbc -version`` calls are not counted."""
    if not log.is_file():
        return 0
    return sum(line.endswith(".bas") for line in log.read_text().splitlines())


CDEMO = 'Print "c"\n'


@pytest.mark.fbc
def test_driver_c_file_is_kept_hashed_and_rebuilt(real_fbc: Path, tmp_path: Path) -> None:
    wrapper, log = counting_fbc(real_fbc, tmp_path)
    drivers = tmp_path / "drivers"
    drivers.mkdir()
    (drivers / "cdemo.bas").write_text(CDEMO)
    build_root = tmp_path / "build"
    first = driver.build(
        "cdemo",
        drivers_dir=drivers,
        build_root=build_root,
        fbc=wrapper,
        source_date_epoch=0,
    )
    c_source = first.c_source
    assert c_source == build_root / "cdemo" / "src" / "cdemo.c"
    assert "main(" in c_source.read_text(encoding="latin-1")
    rec = first.record
    assert rec["c_file"] == "cdemo.c"
    assert rec["c_sha256"] == driver.sha256_file(c_source)
    assert rec["fbc_options"] == ["-R"]
    assert rec["command"][1:] == ["-R", "cdemo.bas"]
    assert compiles(log) == 1
    # An up-to-date build, kept C file included, is reused without compiling.
    again = driver.build(
        "cdemo",
        drivers_dir=drivers,
        build_root=build_root,
        fbc=wrapper,
        source_date_epoch=0,
    )
    assert again.record["c_sha256"] == rec["c_sha256"]
    assert compiles(log) == 1
    # Editing the kept C file makes the build stale; the rebuild restores it.
    c_source.write_text("/* edited */\n")
    rebuilt = driver.build(
        "cdemo",
        drivers_dir=drivers,
        build_root=build_root,
        fbc=wrapper,
        source_date_epoch=0,
    )
    assert compiles(log) == 2
    assert rebuilt.record["c_sha256"] == rec["c_sha256"]
    assert driver.sha256_file(c_source) == rec["c_sha256"]


SHARED_BI = "Function Scale(x As Integer) As Integer\n    Return 2 * x\nEnd Function\n"
USE_SHARED = '\'@include-driver shared.bi\n#include "shared.bi"\nPrint Scale(21)\n'


@pytest.mark.fbc
def test_include_driver_is_copied_hashed_and_rebuilt(real_fbc: Path, tmp_path: Path) -> None:
    wrapper, log = counting_fbc(real_fbc, tmp_path)
    drivers = tmp_path / "drivers"
    drivers.mkdir()
    (drivers / "usedemo.bas").write_text(USE_SHARED)
    shared = drivers / "shared.bi"
    shared.write_text(SHARED_BI)
    build_root = tmp_path / "build"
    digest = hashlib.sha256(SHARED_BI.encode()).hexdigest()
    first = driver.run(
        "usedemo",
        drivers_dir=drivers,
        build_root=build_root,
        fbc=wrapper,
        source_date_epoch=0,
    )
    assert first.returncode == 0
    assert (first.out_dir / "stdout.txt").read_text().split() == ["42"]
    assert first.record["driver_includes"] == [{"file": "shared.bi", "sha256": digest}]
    src = build_root / "usedemo" / "src"
    assert (src / "shared.bi").read_text() == SHARED_BI
    build_json = json.loads((src / driver.BUILD_JSON).read_text())
    assert build_json["driver_includes"] == [{"file": "shared.bi", "sha256": digest}]
    assert compiles(log) == 1
    # Up to date: reused without compiling, into a fresh run directory.
    second = driver.run(
        "usedemo",
        drivers_dir=drivers,
        build_root=build_root,
        fbc=wrapper,
        source_date_epoch=0,
    )
    assert second.out_dir.name == "run-2"
    assert second.record["binary_sha256"] == first.record["binary_sha256"]
    assert compiles(log) == 1
    # A changed shared file rebuilds the driver and updates the recorded hash.
    shared.write_text(SHARED_BI.replace("2 * x", "3 * x"))
    third = driver.run(
        "usedemo",
        drivers_dir=drivers,
        build_root=build_root,
        fbc=wrapper,
        source_date_epoch=0,
    )
    assert (third.out_dir / "stdout.txt").read_text().split() == ["63"]
    assert third.record["driver_includes"][0]["sha256"] != digest
    assert compiles(log) == 2


def test_missing_driver_include(tmp_path: Path) -> None:
    drivers = tmp_path / "drivers"
    drivers.mkdir()
    (drivers / "lost.bas").write_text("'@include-driver nope.bi\nPrint 1\n")
    with pytest.raises(HarnessError, match=r"driver include nope\.bi not found in"):
        driver.build(
            "lost",
            drivers_dir=drivers,
            build_root=tmp_path / "b",
            fbc=tmp_path / "fbc",
            source_date_epoch=0,
        )


WORK_DRIVER = """\
Dim As String arg1 = Command(1)
Dim As Integer f = FreeFile
Dim As String text
If arg1 = "change" Then
    Open "input.txt" For Output As #f
    Print #f, "changed"
    Close #f
ElseIf arg1 = "remove" Then
    Kill "input.txt"
Else
    Open "input.txt" For Input As #f
    Line Input #f, text
    Close #f
    Print text
End If
"""


@pytest.mark.fbc
def test_work_file_is_copied_recorded_and_guarded(real_fbc: Path, tmp_path: Path) -> None:
    drivers = tmp_path / "drivers"
    drivers.mkdir()
    (drivers / "workdemo.bas").write_text(WORK_DRIVER)
    work = tmp_path / "input.txt"
    work.write_bytes(b"hello\n")
    build_root = tmp_path / "build"
    result = driver.run(
        "workdemo",
        drivers_dir=drivers,
        build_root=build_root,
        fbc=real_fbc,
        source_date_epoch=0,
        work_files=[work],
    )
    assert result.returncode == 0
    assert (result.out_dir / "stdout.txt").read_text() == "hello\n"
    assert (result.out_dir / "input.txt").read_bytes() == b"hello\n"
    digest = hashlib.sha256(b"hello\n").hexdigest()
    assert result.record["work_files"] == [
        {"name": "input.txt", "source": work.resolve().as_posix(), "sha256": digest}
    ]
    assert set(result.record["outputs"]) == {"stdout.txt"}
    recorded = json.loads((result.out_dir / "driver.json").read_text())
    assert recorded["work_files"] == result.record["work_files"]
    # The driver may not change or remove its input: the run is refused.
    for action in ("change", "remove"):
        with pytest.raises(HarnessError, match=r"changed or removed work file input\.txt"):
            driver.run(
                "workdemo",
                [action],
                drivers_dir=drivers,
                build_root=build_root,
                fbc=real_fbc,
                source_date_epoch=0,
                work_files=[work],
            )
    assert work.read_bytes() == b"hello\n"


def test_work_file_refusals(tmp_path: Path) -> None:
    for sub in ("a", "b"):
        (tmp_path / sub).mkdir()
    (tmp_path / "a" / "input.txt").write_text("x")
    (tmp_path / "b" / "input.txt").write_text("y")
    out = tmp_path / "out"
    with pytest.raises(HarnessError, match="does not exist"):
        driver.run("demo", out_dir=out, work_files=[tmp_path / "missing.txt"])
    for name in ("stdout.txt", "driver.json"):
        reserved = tmp_path / "a" / name
        reserved.write_text("z")
        with pytest.raises(HarnessError, match="reserved or repeated"):
            driver.run("demo", out_dir=out, work_files=[reserved])
    with pytest.raises(HarnessError, match="reserved or repeated"):
        driver.run(
            "demo",
            out_dir=out,
            work_files=[tmp_path / "a" / "input.txt", tmp_path / "b" / "input.txt"],
        )
    assert not out.exists()


def test_run_cli_passes_work_files(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    seen: dict[str, object] = {}

    def fake_run(name: str, args: list[str] | None = None, **kwargs: object) -> driver.DriverRun:
        seen.update(name=name, args=args, work_files=kwargs["work_files"])
        return driver.DriverRun(tmp_path, {"run_wall_time_s": 0.0}, 0)

    monkeypatch.setattr(driver, "run", fake_run)
    argv = ["run", "demo", "--work-file", "a.txt", "--work-file", "b.txt", "--", "7"]
    assert driver.main(argv) == 0
    assert seen == {
        "name": "demo",
        "args": ["7"],
        "work_files": [Path("a.txt"), Path("b.txt")],
    }


def test_parse_include_driver() -> None:
    text = "'@include-driver m5_common.bi\n  '@include-driver m5_more.bi\n"
    assert driver.parse_directives(text) == [
        driver.IncludeDriver("m5_common.bi"),
        driver.IncludeDriver("m5_more.bi"),
    ]
