# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for harness.reseed, the ``reseed`` patch and the scope analysis of rnd.log."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path

import pytest

from harness.common import GEF_SOURCE_DIR, HARNESS_DIR, PATCHES_DIR, PATCHSETS_DIR
from harness.fbmt import FbMtRng
from harness.reseed import (
    DERIVE_VECTORS,
    SCOPE_EVENT,
    SCOPE_PERTURBATION,
    SCOPE_PREPASS_HISTORY,
    SPLITMIX64_VECTORS,
    TUPLE_FIELDS,
    derive_seed,
    splitmix64,
)
from harness.rndlog import (
    RndLogError,
    RndRecord,
    ScopeBegin,
    ScopeEnd,
    analyze_scopes,
    main,
    parse_events,
    parse_lines,
    read_log,
)

GEF_BAS = GEF_SOURCE_DIR / "GEF.bas"
needs_source = pytest.mark.skipif(
    shutil.which("patch") is None or not GEF_BAS.is_file(),
    reason="needs GNU patch and the Reference/GEF_code submodule",
)
SPEC = HARNESS_DIR / "RESEED_SPEC.md"


# --- the derivation ---------------------------------------------------------------------------


def test_splitmix64_known_values() -> None:
    # The first output of SplitMix64 seeded with 0 is the published 0xE220A8397B1DCDAF.
    assert splitmix64(0) == 0xE220A8397B1DCDAF
    for state, want in SPLITMIX64_VECTORS:
        assert splitmix64(state) == want


def test_vectors_cover_edge_cases() -> None:
    assert len(DERIVE_VECTORS) >= 10
    masters = {m for m, _, _, _ in DERIVE_VECTORS}
    assert {0, 2**32 - 1} <= masters
    assert any(v < 0 for _, _, t, _ in DERIVE_VECTORS for v in t)
    assert {s for _, s, _, _ in DERIVE_VECTORS} == {1, 2, 3}


@pytest.mark.parametrize(("master", "scope", "values", "seed"), DERIVE_VECTORS)
def test_derive_seed_vectors(master: int, scope: int, values: tuple[int, ...], seed: int) -> None:
    assert derive_seed(master, scope, *values) == seed
    assert 0 <= seed < 2**32


def test_derive_seed_matches_the_written_chain() -> None:
    mask = 2**64 - 1
    h = splitmix64(42)
    for v in (3, 1, -2, 7):
        h = splitmix64(h ^ (v & mask))
    assert derive_seed(42, 3, 1, -2, 7) == h >> 32


def test_derive_seed_depends_on_every_element_and_their_order() -> None:
    base = derive_seed(1, 3, 1, 2, 3)
    assert derive_seed(2, 3, 1, 2, 3) != base
    assert derive_seed(1, 2, 1, 2, 3) != base
    assert derive_seed(1, 3, 1, 2, 4) != base
    assert derive_seed(1, 3, 3, 2, 1) != base
    assert derive_seed(1, 3, 1, 2, 3, 0) != base


@pytest.mark.parametrize(
    ("master", "values"), [(-1, ()), (2**32, ()), (0, (2**63,)), (0, (-(2**63) - 1,))]
)
def test_derive_seed_rejects_out_of_range(master: int, values: tuple[int, ...]) -> None:
    with pytest.raises(ValueError, match=r"must be in|does not fit"):
        derive_seed(master, 1, *values)


def test_spec_lists_every_vector_and_scope_tuple() -> None:
    text = SPEC.read_text(encoding="utf-8")
    for master, scope, values, seed in DERIVE_VECTORS:
        row = f"| {master} | {scope} | {' '.join(str(v) for v in values) or '-'} | {seed} |"
        assert row in text
    for state, want in SPLITMIX64_VECTORS:
        assert f"| `0x{state:016X}` | `0x{want:016X}` |" in text
    for names in TUPLE_FIELDS.values():
        assert ", ".join(names) in text


# --- the patch ---------------------------------------------------------------------------------


def _patch(src: Path, name: str, *, dry_run: bool = False) -> None:
    cmd = ["patch", "-p1", "--fuzz=0", "--forward", "--batch", "--no-backup-if-mismatch"]
    if dry_run:
        cmd.append("--dry-run")
    proc = subprocess.run(
        [*cmd, "-i", str(PATCHES_DIR / f"{name}.patch")],
        cwd=src,
        capture_output=True,
        check=False,
    )
    assert proc.returncode == 0, f"{name}.patch: {proc.stdout.decode()}{proc.stderr.decode()}"


def _stacked(tmp_path: Path, names: tuple[str, ...]) -> Path:
    src = tmp_path / "src"
    src.mkdir()
    shutil.copy(GEF_BAS, src / "GEF.bas")
    for name in names:
        _patch(src, name, dry_run=True)
        _patch(src, name)
    return src


@needs_source
def test_reseed_keeps_line_numbers_and_touches_only_its_sites(tmp_path: Path) -> None:
    before = _stacked(tmp_path, ("seed", "scope"))
    original = (before / "GEF.bas").read_bytes().split(b"\n")
    after_dir = tmp_path / "after"
    after_dir.mkdir()
    shutil.copytree(before, after_dir, dirs_exist_ok=True)
    _patch(after_dir, "reseed")
    patched = (after_dir / "GEF.bas").read_bytes().split(b"\n")
    assert len(patched) == len(original)
    changed = [i + 1 for i, (a, b) in enumerate(zip(original, patched, strict=True)) if a != b]
    assert changed == [1555, 4241, 4707, 5112, 5160, 7926, 9997, 17960]


@needs_source
def test_reseed_stacks_before_rndlog(tmp_path: Path) -> None:
    src = _stacked(tmp_path, ("seed", "scope", "reseed", "rndlog"))
    assert (src / "harness_reseed.bi").is_file()
    assert (src / "harness_rndlog.bi").is_file()


@pytest.mark.parametrize(
    ("name", "order"),
    [
        ("seed-reseed", ["seed", "scope", "reseed"]),
        ("seed-reseed-rndlog", ["seed", "scope", "reseed", "rndlog"]),
    ],
)
def test_patchsets_are_canonical(name: str, order: list[str]) -> None:
    lines = (PATCHSETS_DIR / f"{name}.txt").read_text(encoding="utf-8").splitlines()
    assert [ln for ln in lines if ln and not ln.startswith("#")] == order


def _find_fbc() -> Path:
    from tools.toolchain.fbc import FbcError, resolve_fbc

    try:
        return resolve_fbc()
    except FbcError:
        pytest.skip("pinned fbc is not available")


def _vector_program() -> str:
    lines = [
        '#include "harness_seed.bi"',
        '#include "harness_reseed.bi"',
        "Dim As LongInt Av(0 To 9)",
        "Dim As ULong Useed",
    ]
    for state, _ in SPLITMIX64_VECTORS:
        lines.append(f"Print Hex(Harness_SplitMix64(&h{state:016X}ULL), 16)")
    for master, scope, values, _ in DERIVE_VECTORS:
        for i, v in enumerate(values):
            literal = "&h8000000000000000" if v == -(2**63) else f"{v}LL"
            lines.append(f"Av({i}) = {literal}")
        lines.append(f"Useed = Harness_DeriveSeed({master}ULL, {scope}, {len(values)}, @Av(0))")
        lines.append("Print Useed")
    return "\n".join(lines) + "\n"


@needs_source
@pytest.mark.fbc
def test_basic_derivation_reproduces_the_vectors(tmp_path: Path) -> None:
    from tools.toolchain.fbc import filter_fbc_stderr

    fbc = _find_fbc()
    src = _stacked(tmp_path, ("seed", "scope", "reseed"))
    (src / "vectors.bas").write_text(_vector_program(), encoding="utf-8")
    proc = subprocess.run(
        [str(fbc), "vectors.bas"], cwd=src, capture_output=True, text=True, check=False
    )
    assert proc.returncode == 0, filter_fbc_stderr(proc.stderr) + proc.stdout
    env = {k: v for k, v in os.environ.items() if not k.startswith("GEF_")}
    done = subprocess.run(
        [str(src / "vectors")], cwd=src, env=env, capture_output=True, text=True, check=False
    )
    assert done.returncode == 0
    want = [f"{out:016X}" for _, out in SPLITMIX64_VECTORS]
    want += [str(seed) for *_, seed in DERIVE_VECTORS]
    assert [ln.strip() for ln in done.stdout.splitlines()] == want


_RESEED_PROBE = """
#include "harness_seed.bi"
#include "harness_reseed.bi"
Print Harness_ReseedOn;" ";Harness_ReseedMaster
Harness_Reseed(3, 2, 5, 6)
Dim As Long Ik
For Ik = 1 To 3 : Print Hex(CULng(Rnd * 4294967296.0), 8) : Next
Print Harness_PGaussReset
"""


@needs_source
@pytest.mark.fbc
def test_reseed_mode_switch_and_generator_state(tmp_path: Path) -> None:
    fbc = _find_fbc()
    src = _stacked(tmp_path, ("seed", "scope", "reseed"))
    (src / "probe.bas").write_text(_RESEED_PROBE, encoding="utf-8")
    proc = subprocess.run(
        [str(fbc), "probe.bas"], cwd=src, capture_output=True, text=True, check=False
    )
    assert proc.returncode == 0, proc.stderr + proc.stdout
    base = {k: v for k, v in os.environ.items() if not k.startswith("GEF_")}

    def run(**extra: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(src / "probe")],
            cwd=src,
            env={**base, **extra},
            capture_output=True,
            text=True,
            check=False,
        )

    inert = run(GEF_SEED="9", GEF_RESEED="")
    assert inert.returncode == 0
    assert inert.stdout.split()[:2] == ["0", "0"]
    assert inert.stdout.splitlines()[-1].strip() == "0"
    on = run(GEF_SEED="9", GEF_RESEED="1")
    assert on.returncode == 0
    lines = on.stdout.splitlines()
    assert lines[0].split() == ["1", "9"]
    rng = FbMtRng(derive_seed(9, 3, 5, 6))
    assert lines[1:4] == [f"{rng.next_u32():08X}" for _ in range(3)]
    assert lines[4].strip() == "1"  # PGauss must forget its cached value
    for bad in ("0", "2", "true", " 1"):
        failed = run(GEF_SEED="9", GEF_RESEED=bad)
        assert failed.returncode == 2
        assert "GEF_RESEED must be unset, empty or 1" in failed.stdout


# --- the scope analysis of rnd.log -------------------------------------------------------------


def _draw(counter: int, line: int, u32: int) -> str:
    return f"{counter} GEF.bas:{line} {u32:08x}"


def _scoped_log(master: int) -> list[str]:
    seed1 = derive_seed(master, 1, 1, 1, 1, 1, 0)
    seed3 = derive_seed(master, 3, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1)
    r1 = FbMtRng(seed1)
    r3 = FbMtRng(seed3)
    return [
        f"B 1 {seed1:08x} 1 1 1 1 0",
        _draw(1, 4245, r1.next_u32()),
        _draw(2, 4247, r1.next_u32()),
        "E 1",
        _draw(3, 17963, 5),  # outside
        f"B 3 {seed3:08x} 1 1 1 1 0 1 0 0 0 1",
        _draw(4, 7931, r3.next_u32()),
        _draw(5, 17963, r3.next_u32()),
        "E 3",
    ]


def test_parse_events_and_marker_skipping() -> None:
    lines = _scoped_log(7)
    items = list(parse_events(lines))
    assert isinstance(items[0], ScopeBegin)
    assert items[0].scope == 1
    assert items[0].tuple_values == (1, 1, 1, 1, 0)
    assert isinstance(items[3], ScopeEnd)
    assert sum(isinstance(i, RndRecord) for i in items) == 5
    assert [r.counter for r in parse_lines(lines)] == [1, 2, 3, 4, 5]


def test_parse_events_negative_tuple_and_errors() -> None:
    (item,) = parse_events(["B 3 0000000a -1 2 -3"])
    assert item == ScopeBegin(3, 10, (-1, 2, -3))
    for bad in ("B 3 0000000A 1", "B 3 a 1", "B x 0000000a", "E", "E 1 2", "B 3 0000000a  1"):
        with pytest.raises(RndLogError, match="malformed record"):
            list(parse_events([bad]))


def test_analyze_scopes_reports_outside_draws() -> None:
    report = analyze_scopes(parse_events(_scoped_log(7)), master=7, check_streams=True)
    assert (report.draws, report.inside, report.outside) == (5, 4, 1)
    assert dict(report.outside_sites) == {"GEF.bas:17963": 1}
    assert report.outside_first == {"GEF.bas:17963": 3}
    assert report.instances[1] == report.instances[3] == 1
    assert report.problems == []
    assert not report.clean


def test_analyze_scopes_detects_wrong_seed_stream_and_tuple() -> None:
    log = _scoped_log(7)
    assert analyze_scopes(parse_events(log), master=8).problems  # wrong master
    tampered = [*log[:2], _draw(2, 4247, 1), *log[3:]]
    problems = analyze_scopes(parse_events(tampered), check_streams=True).problems
    assert any("not the next FbMtRng" in p for p in problems)
    short = ["B 1 00000001 1 2", "E 1"]
    assert "2 tuple elements" in analyze_scopes(parse_events(short)).problems[0]
    assert (
        "closed by end of 3"
        in analyze_scopes(parse_events(["B 1 00000001 1 1 1 1 1", "E 3"])).problems[0]
    )


def test_analyze_scopes_new_begin_closes_the_previous_scope() -> None:
    log = [
        "B 3 00000001 1 1 1 1 0 1 0 0 0 1",
        _draw(1, 7931, 1),
        "B 3 00000002 1 1 1 1 0 1 0 0 0 2",
        _draw(2, 7931, 2),
        "E 3",
        "E 3",
    ]
    report = analyze_scopes(parse_events(log))
    assert report.clean is True
    assert report.instances[3] == 2
    assert report.stray_ends == 1


def test_cli_scopes(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    log = tmp_path / "rnd.log"
    log.write_text("\n".join(_scoped_log(7)) + "\n", encoding="ascii")
    assert main(["scopes", str(log), "--master", "7", "--streams"]) == 3
    out = capsys.readouterr().out
    assert "outside scopes 1" in out
    assert "GEF.bas:17963" in out
    assert "scope 3 (event): 1 instances, 2 draws" in out
    assert [r.counter for r in read_log(log)] == [1, 2, 3, 4, 5]
    clean = tmp_path / "clean.log"
    clean.write_text("\n".join([*_scoped_log(7)[:3], "E 1"]) + "\n", encoding="ascii")
    assert main(["scopes", str(clean), "--json"]) == 0
    assert '"outside": 0' in capsys.readouterr().out


def test_scope_ids_and_fields_are_consistent() -> None:
    assert (SCOPE_PREPASS_HISTORY, SCOPE_PERTURBATION, SCOPE_EVENT) == (1, 2, 3)
    assert [len(TUPLE_FIELDS[s]) for s in (1, 2, 3)] == [5, 5, 10]
    patch = (PATCHES_DIR / "reseed.patch").read_text(encoding="utf-8")
    assert re.search(r"Harness_Reseed\(1, 5, Ifilein, Iline, I_Double_Covar, I_E_step, K\)", patch)
    assert re.search(r"Harness_Reseed\(2, 5, .*I_Error\)", patch)
    assert re.search(r"Harness_Reseed\(3, 10, .*I_E_Multi, ILoop\)", patch)
