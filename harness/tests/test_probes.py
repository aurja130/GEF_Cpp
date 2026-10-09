# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the probes patch and harness.probes (synthetic files; the build test needs fbc)."""

from __future__ import annotations

import math
import random
import re
import shutil
import struct
import subprocess
from pathlib import Path

import pytest

from harness import probes
from harness.build import read_patchset
from harness.common import GEF_SOURCE_DIR, PATCHES_DIR, PATCHSETS_DIR, HarnessError
from harness.probes import (
    ProbeFormatError,
    decode_double,
    decode_single,
    encode_double,
    encode_single,
    parse_line,
    read_probe_file,
    summarize,
    unescape_string,
)

HARNESS_DIR = Path(__file__).resolve().parents[1]
PROBES_PATCH = PATCHES_DIR / "probes.patch"
PROBES_MD = HARNESS_DIR / "PROBES.md"
GEF_BAS = GEF_SOURCE_DIR / "GEF.bas"

needs_source = pytest.mark.skipif(
    shutil.which("patch") is None or not GEF_BAS.is_file(),
    reason="needs GNU patch and the Reference/GEF_code submodule",
)

SYNTHETIC = """\
P3 step=2 pass=0 bin=1:0:0:5 rec=1 NEVTused - I 1000
P3 step=2 pass=0 bin=1:0:0:5 rec=1 Racc - S 3F800000
P3 step=2 pass=0 bin=1:0:0:5 rec=1 Fenhance - D 4024000000000000
P3 step=2 pass=0 bin=1:0:0:5 rec=1 Csystem - Z "Z86 A215 \\"n\\" \\\\ \\x00\\xFF"
P3 step=2 pass=0 bin=1:0:0:5 rec=1 W - B S 0:1,1:2
P3 step=2 pass=0 bin=1:0:0:5 rec=1 W 0,1 S 3DCCCCCD
P3 step=2 pass=0 bin=1:0:0:5 rec=1 W 0,2 S 00000000
P3 step=2 pass=0 bin=1:0:0:5 rec=1 W 1,1 S 80000000
P3 step=2 pass=0 bin=1:0:0:5 rec=1 W 1,2 S 7FC00000
P3 step=2 pass=0 bin=1:0:0:5 rec=1 Sp - BS S 0:3
P3 step=2 pass=0 bin=1:0:0:5 rec=1 Sp 2 S 3F800000
P3 step=2 pass=0 bin=1:0:0:5 rec=1 Zero - BS I 1:2
P3 step=3 pass=0 bin=1:0:0:5 rec=2 NEVTused - I 7
"""


def _write(tmp_path: Path, text: str, name: str = "P3.txt") -> Path:
    path = tmp_path / name
    path.write_text(text, encoding="latin-1", newline="")
    return path


# ---- hex decoding ----------------------------------------------------------------------


def test_single_decode_is_exact() -> None:
    assert decode_single("3F800000") == 1.0
    assert decode_single("3DCCCCCD") == struct.unpack(">f", bytes.fromhex("3DCCCCCD"))[0]
    assert decode_single("3DCCCCCD") != 0.1  # the Single nearest 0.1 is not the Double 0.1
    assert math.isinf(decode_single("7F800000"))
    assert math.isnan(decode_single("7FC00000"))
    assert math.copysign(1.0, decode_single("80000000")) == -1.0


def test_double_decode_is_exact() -> None:
    assert decode_double("3FB999999999999A") == 0.1
    assert decode_double("4024000000000000") == 10.0
    assert decode_double("0000000000000001") == 5e-324


@pytest.mark.parametrize("seed", range(3))
def test_roundtrip_of_random_bit_patterns(seed: int) -> None:
    rng = random.Random(seed)
    for _ in range(500):
        bits32 = rng.getrandbits(32)
        text32 = f"{bits32:08X}"
        value32 = decode_single(text32)
        if not math.isnan(value32):
            assert encode_single(value32) == text32
        bits64 = rng.getrandbits(64)
        text64 = f"{bits64:016X}"
        value64 = decode_double(text64)
        if not math.isnan(value64):
            assert encode_double(value64) == text64


@pytest.mark.parametrize("bad", ["", "3F80000", "3F8000000", "3F80000G"])
def test_single_rejects_bad_text(bad: str) -> None:
    with pytest.raises(ProbeFormatError):
        decode_single(bad)


def test_double_rejects_bad_text() -> None:
    with pytest.raises(ProbeFormatError):
        decode_double("3F800000")


def test_unescape_string() -> None:
    assert unescape_string('"a \\"b\\" \\\\ \\x41\\xFF"') == 'a "b" \\ A\xff'
    for bad in ("abc", '"abc', '"a"b"', '"a\\qb"', '"a\\x4"'):
        with pytest.raises(ProbeFormatError):
            unescape_string(bad)


# ---- line parsing ----------------------------------------------------------------------


def test_parse_line_t0_and_p3() -> None:
    line = parse_line("T0 - BEexp 3,4 S BF800000")
    assert (line.probe, line.context, line.name, line.index) == ("T0", {}, "BEexp", (3, 4))
    line = parse_line('P1 step=1 pass=- bin=- rec=1 Csystem - Z "a b"')
    assert line.context == {"step": "1", "pass": "-", "bin": "-", "rec": "1"}
    assert (line.type, line.value) == ("Z", '"a b"')


@pytest.mark.parametrize(
    "bad",
    [
        "T0",
        "T0 - X",
        "T0 - X - Q 1",
        "T0 - X a,b S 00000000",
        "P1 X - I 1",
    ],
)
def test_parse_line_rejects(bad: str) -> None:
    with pytest.raises(ProbeFormatError):
        parse_line(bad)


# ---- records ---------------------------------------------------------------------------


def test_read_records_and_values(tmp_path: Path) -> None:
    records = read_probe_file(_write(tmp_path, SYNTHETIC))
    assert [r.rec for r in records] == [1, 2]
    first = records[0]
    assert (first.step, first.pass_, first.bin) == (2, 0, (1, 0, 0, 5))
    assert first.scalar("NEVTused") == 1000
    assert first.scalar("Racc") == 1.0
    assert first.scalar("Fenhance") == 10.0
    assert first.scalar("Csystem") == 'Z86 A215 "n" \\ \x00\xff'
    w = first.var("W")
    assert w.bounds == ((0, 1), (1, 2)) and not w.sparse and w.type == "S"
    assert w.raw((0, 1)) == "3DCCCCCD"
    assert w.get((0, 1)) == decode_single("3DCCCCCD")
    assert math.isnan(float(w.get((1, 2))))
    assert w.expected_count() == 4


def test_sparse_arrays_return_zero_for_omitted_elements(tmp_path: Path) -> None:
    first = read_probe_file(_write(tmp_path, SYNTHETIC))[0]
    sp = first.var("Sp")
    assert sp.sparse and len(sp) == 1
    assert sp.get((2,)) == 1.0
    assert sp.get((0,)) == 0.0 and sp.get((3,)) == 0.0
    with pytest.raises(KeyError):
        sp.get((4,))
    zero = first.var("Zero")
    assert zero.type == "I" and len(zero) == 0 and zero.get((1,)) == 0


def test_t0_has_no_context(tmp_path: Path) -> None:
    text = (
        "T0 - N - I 3\nT0 - A - B I 0:1\nT0 - A 0 I 5\nT0 - A 1 I 6\n"
        'T0 - CE - B Z 1:1\nT0 - CE 1 Z "H"\n'
    )
    (record,) = read_probe_file(_write(tmp_path, text, "T0.txt"))
    assert record.context == {} and record.step is None and record.bin is None
    assert [v for _, v in record.var("A").items()] == [5, 6]
    assert record.var("CE").get((1,)) == "H"


@pytest.mark.parametrize(
    ("text", "message"),
    [
        ("T0 - A - B S 0:2\nT0 - A 0 S 00000000\n", "has 1 elements"),
        ("T0 - A - BS S 0:1\nT0 - A 5 S 00000001\n", "outside bounds"),
        ("T0 - A - B S 0:0\nT0 - A 0 S 00000000\nT0 - A 0 S 00000000\n", "duplicate"),
        ("T0 - A - S 3F80000\n", "Single bit pattern"),
        ("T0 - A - I 1\nT0 - A - S 00000000\n", "changes type"),
        ("T0 - A 0 I 1\nT0 - A - B I 0:0\n", "first line"),
        ("T0 - A - B X 0:0\n", "element type"),
    ],
)
def test_read_rejects_malformed_files(tmp_path: Path, text: str, message: str) -> None:
    with pytest.raises(ProbeFormatError, match=message):
        read_probe_file(_write(tmp_path, text, "T0.txt"))


def test_summary_and_cli(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    path = _write(tmp_path, SYNTHETIC)
    text = summarize(read_probe_file(path), names=True)
    assert "record 1: P3 step=2 pass=0 bin=1:0:0:5 rec=1  12 lines, 4 scalars, 3 arrays" in text
    assert "  W S [0:1,1:2] dense, 4 elements" in text
    assert "  Sp S [0:3] sparse, 1 elements" in text
    assert probes._main(["summary", str(path)]) == 0  # pyright: ignore[reportPrivateUsage]
    assert "record 2: P3 step=3" in capsys.readouterr().out
    assert probes._main(["show", str(path), "W"]) == 0  # pyright: ignore[reportPrivateUsage]
    out = capsys.readouterr().out
    assert "0,1  3DCCCCCD  0.10000000149011612" in out
    assert probes._main(["show", str(path), "Nope"]) == 1  # pyright: ignore[reportPrivateUsage]
    assert probes._main(["summary", str(tmp_path / "missing.txt")]) == 1  # pyright: ignore[reportPrivateUsage]
    assert "error:" in capsys.readouterr().err


# ---- the patch and PROBES.md ------------------------------------------------------------


def _patch_new_files() -> dict[str, str]:
    """New files of probes.patch (name -> content)."""
    files: dict[str, list[str]] = {}
    current: list[str] | None = None
    for line in PROBES_PATCH.read_text(encoding="latin-1").splitlines():
        if line.startswith("+++ b/") and line != "+++ b/GEF.bas":
            current = files.setdefault(line[6:], [])
        elif line.startswith("+++ b/GEF.bas"):
            current = None
        elif current is not None and line.startswith("+"):
            current.append(line[1:])
    return {name: "\n".join(lines) + "\n" for name, lines in files.items()}


def _emitted_names(text: str) -> list[str]:
    names: list[str] = []
    for line in text.splitlines():
        if (m := re.match(r"\s*HP_(?:V|A[123]|S[1-4])\((\w+)\)", line)) is not None:
            names.append(m.group(1))
        elif (m := re.match(r"\s*HP_(?:F1|FS1|FA1|FA2)\((\w+), (\w+),", line)) is not None:
            names.append(f"{m.group(1)}.{m.group(2)}")
        elif (m := re.match(r'\s*HP_(?:F1N|A1N)\("([\w.]+)"', line)) is not None:
            names.append(m.group(1))
    return names


def _md_section(probe: str) -> str:
    text = PROBES_MD.read_text(encoding="utf-8")
    match = re.search(rf"^## {probe}:.*?(?=^## |\Z)", text, re.S | re.M)
    assert match is not None, probe
    return match.group(0)


@pytest.mark.parametrize("probe", ["T0", "P1", "P2", "P3"])
def test_probes_md_lists_exactly_the_emitted_variables(probe: str) -> None:
    source = _patch_new_files()[f"harness_probe_{probe.lower()}.bi"]
    emitted = _emitted_names(source)
    assert emitted, probe
    assert len(emitted) == len(set(emitted)), "a variable is dumped twice"
    section = _md_section(probe)
    documented = re.findall(r"`([A-Za-z_][\w.]*)`", section)
    # Names appear in tables only; prose names (other variables) are in the free text above them.
    table_rows = [ln for ln in section.splitlines() if ln.startswith("|")]
    in_tables = [n for ln in table_rows for n in re.findall(r"`([A-Za-z_][\w.]*)`", ln)]
    assert sorted(in_tables) == sorted(emitted)
    assert set(emitted) <= set(documented)


def test_every_probe_group_names_a_consumer() -> None:
    for probe in ("T0", "P1", "P2", "P3"):
        section = _md_section(probe)
        groups = re.findall(r"^### .*$", section, re.M)
        assert groups
        assert section.count("Consumer: ") == len(groups)
        assert "Consumer: ?" not in section


def test_probe_files_are_guarded_by_gef_probes() -> None:
    for name, text in _patch_new_files().items():
        code = [ln for ln in text.splitlines() if ln.strip() and not ln.lstrip().startswith("'")]
        assert code[0] == "#ifdef GEF_PROBES", name
        assert code[-1].startswith("#endif"), name


def _branchings_copy() -> tuple[str, list[str]]:
    text = _patch_new_files()["harness_probe_t0.bi"]
    begin = re.search(r"' BEGIN copy of Branchings\.bas:(\d+)-(\d+)", text)
    assert begin is not None
    lines = text.splitlines()
    start = next(i for i, ln in enumerate(lines) if "BEGIN copy" in ln)
    end = next(i for i, ln in enumerate(lines) if "END copy" in ln)
    return begin.group(0), [ln.strip() for ln in lines[start + 1 : end]]


@needs_source
def test_branchings_loader_copy_matches_the_source() -> None:
    marker, copy = _branchings_copy()
    first, last = (int(n) for n in re.findall(r"(\d+)-(\d+)", marker)[0])
    source = (GEF_SOURCE_DIR / "Branchings.bas").read_text(encoding="latin-1").splitlines()
    expected = [ln.strip() for ln in source[first - 1 : last]]
    renamed = [
        re.sub(r"\bINlast\(", "HP_INlast(", re.sub(r"\bBranchData\(", "HP_BranchData(", ln))
        for ln in expected
    ]
    assert copy == renamed


def _apply(src: Path, patch: Path, *, dry_run: bool = False) -> None:
    cmd = ["patch", "-p1", "--fuzz=0", "--forward", "--batch", "--no-backup-if-mismatch"]
    if dry_run:
        cmd.append("--dry-run")
    proc = subprocess.run(
        cmd, input=patch.read_bytes(), cwd=src, capture_output=True, check=False, timeout=120
    )
    assert proc.returncode == 0, f"{patch.name}: {proc.stdout.decode()}{proc.stderr.decode()}"


def _probe_patchsets() -> list[str]:
    names: list[str] = []
    for path in sorted(PATCHSETS_DIR.glob("*.txt")):
        try:
            files = read_patchset(path.stem)
        except HarnessError:
            continue  # e.g. a set naming a patch that another agent has not written yet
        if PROBES_PATCH in files:
            names.append(path.stem)
    return names


def test_there_are_patchsets_with_probes() -> None:
    names = _probe_patchsets()
    assert "seed-probes" in names
    assert "seed-rndlog-probes" in names


@needs_source
@pytest.mark.parametrize("patchset", _probe_patchsets())
def test_probes_patch_applies_in_every_patch_set(tmp_path: Path, patchset: str) -> None:
    src = tmp_path / "src"
    shutil.copytree(GEF_SOURCE_DIR, src)
    files = read_patchset(patchset)
    before_probes = files[: files.index(PROBES_PATCH)]
    for patch in before_probes:
        _apply(src, patch)
    without = (src / "GEF.bas").read_bytes().splitlines()
    _apply(src, PROBES_PATCH, dry_run=True)
    _apply(src, PROBES_PATCH)
    with_probes = (src / "GEF.bas").read_bytes().splitlines()
    inserted = [ln for ln in with_probes if ln.startswith((b'#Include "harness_probe_', b"#line "))]
    assert len(inserted) == 8
    assert [ln for ln in with_probes if ln not in inserted] == without


@needs_source
def test_probes_patch_keeps_original_line_numbers(tmp_path: Path) -> None:
    """After each inserted pair, `#line N` makes the next line report N + 1 as in the original."""
    src = tmp_path / "src"
    src.mkdir()
    shutil.copy(GEF_BAS, src / "GEF.bas")
    _apply(src, PROBES_PATCH)
    lines = (src / "GEF.bas").read_bytes().splitlines()
    original = GEF_BAS.read_bytes().splitlines()
    for index, line in enumerate(lines):
        if line.startswith(b"#line "):
            number = int(line.split()[1])
            assert lines[index + 1] == original[number]  # original line number + 1, 0-based
            assert lines[index - 1].startswith(b"#Include")
            assert lines[index - 2] == original[number - 1]


# ---- compile and run (fbc) --------------------------------------------------------------


@needs_source
@pytest.mark.fbc
@pytest.mark.slow
def test_probes_build_and_write_every_probe_file(tmp_path: Path) -> None:
    from harness.build import build
    from harness.run import run
    from tools.toolchain.fbc import FbcError, resolve_fbc

    try:
        resolve_fbc()
    except FbcError:
        pytest.skip("pinned fbc is not available")
    result = build("seed-probes", ["GEF_PROBES"], build_root=tmp_path / "build")
    sequence = tmp_path / "th.in"
    sequence.write_text(' 10\n0.0253E-6\n 86, 215, "EN"\n', encoding="utf-8")
    outcome = run(
        result.binary,
        sequence,
        tmp_path / "run",
        seed=12345,
        scope={"steps": "1", "passes": "0"},
        timeout_s=600,
    )
    probe_dir = outcome.work_dir / "probes"
    assert sorted(p.name for p in probe_dir.iterdir()) == ["P1.txt", "P2.txt", "P3.txt", "T0.txt"]
    t0 = read_probe_file(probe_dir / "T0.txt")[0]
    assert t0.scalar("N_MAT_MAX") == 3852
    assert t0.var("NucTab.I_Z").get((1,)) == 0 and t0.var("BEldmTF").bounds == ((0, 203), (0, 136))
    p1 = read_probe_file(probe_dir / "P1.txt")[0]
    assert (p1.scalar("P_Z_CN"), p1.scalar("P_A_CN"), p1.scalar("Emode")) == (86, 215, 2)
    p3 = read_probe_file(probe_dir / "P3.txt")[0]
    assert p3.bin == (1, 0, 0, 0) and p3.pass_ == 0
