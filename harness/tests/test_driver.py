# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for ``harness.driver``: directive parsing/cutting, and fbc-built drivers."""

from __future__ import annotations

import hashlib
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
