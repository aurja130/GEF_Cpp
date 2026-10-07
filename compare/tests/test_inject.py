# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for ``compare.inject``: faults on the extracted table, found by the verdict."""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pytest

from compare import inject, verdict
from compare.calibrate import Calibration, calibrate
from compare.extract import load_extract
from compare.model import Key, Value
from compare.tests.synth import SHA, write_extract

ENDF = "work/ENDF/GEFY_86_214_n.dat"
APOST = "work/dmp/Z86_A215_n_E13MeV/Apost.dmp"
ENERGIES = ("1.300000+7", "1.450000+7")  # ENDF energies in eV
ZAS = [54140, 55143, 56144, 57147, 58150]
K = 20


def _run(rng: np.random.Generator) -> dict[str, dict[Key, Value]]:
    endf: dict[Key, Value] = {}
    for e, energy in enumerate(ENERGIES):
        block, group = "MF8/MT454", f"tape1/E={energy}#1"
        for z, za in enumerate(ZAS):
            for state, share in enumerate((0.75, 0.2, 0.05)):
                lam = 4e5 * (z + 1) * share * (1 + 0.3 * e)
                endf[Key(ENDF, block, group, "Y", (za, state))] = float(rng.poisson(lam)) * 1e-6
        endf[Key(ENDF, block, group, "E", ())] = float(f"{energy[:8]}e{int(energy[8:])}")
    apost: dict[Key, Value] = {}
    shape = np.exp(-0.5 * ((np.arange(40) - 20) / 5.0) ** 2)
    for a, lam in enumerate(1e6 * shape / shape.sum() * 40):
        if lam > 1:
            apost[Key(APOST, "APOST", "#1", "y", (a + 100,))] = (
                float(rng.poisson(float(lam))) * 1e-6
            )
    apost[Key(APOST, "APOST", "#1", "events", ())] = 1000000
    return {ENDF: endf, APOST: apost}


@pytest.fixture(scope="module")
def setup(tmp_path_factory: pytest.TempPathFactory) -> tuple[Calibration, Path, Path]:
    root = tmp_path_factory.mktemp("inj")
    rng = np.random.default_rng(321)
    members = [
        str(write_extract(root / f"s{i}", _run(rng), root / "pool", seed=i)) for i in range(K)
    ]
    calibrate(members, root / "cal", jobs=1, mde=[], input_sha256=SHA)
    base = write_extract(root / "base", _run(rng), root / "pool")
    return Calibration.open(root / "cal"), base, root


def _judge(cal: Calibration, path: Path) -> verdict.VerdictResult:
    return verdict.judge(cal, [load_extract(path)])


def test_base_candidate_passes(setup: tuple[Calibration, Path, Path]) -> None:
    cal, base, _ = setup
    assert _judge(cal, base).passed


def test_yield2pct_scales_one_nuclide_and_is_found(setup: tuple[Calibration, Path, Path]) -> None:
    cal, base, root = setup
    out = root / "y2"
    rec = inject.inject(load_extract(base), "yield2pct", "E=14.5,nuclide=max", out)
    ex = load_extract(base)
    data = ex.file(ENDF)
    assert data is not None
    fd = data.get("MF8/MT454", "tape1/E=1.450000+7#1")
    assert fd is not None
    y = {
        tuple(r[1:3]): v
        for r, v in zip(fd.kmat.tolist(), fd.vals.tolist(), strict=True)
        if r[1] != -1
    }
    za, state = max((k for k in y if k[0] in ZAS), key=lambda k: y[k])
    assert rec.keys == [f"Y[{za},{state}]"]
    assert rec.before[0] == pytest.approx(y[za, state]) and rec.after[0] == pytest.approx(
        1.02 * y[za, state]
    )
    assert rec.group == "tape1/E=1.450000+7#1"
    # the injected extract differs in exactly that value
    new = load_extract(out).file(ENDF)
    assert new is not None
    diff = np.flatnonzero(np.asarray(new.vals) != np.asarray(data.vals))
    assert len(diff) == 1
    assert json.loads((out / "manifest.json").read_text())["injection"]["fault"] == "yield2pct"
    # the source run is untouched and the verdict names the family and the key
    result = _judge(cal, out)
    assert not result.passed
    hit = result.rejected[0]
    assert (hit.file, hit.block, hit.group) == (ENDF, "MF8/MT454", "tape1/E=1.450000+7#1")
    assert hit.top[0].key == f"Y[{za},{state}]"
    assert _judge(cal, base).passed


def test_yield2pct_mid_and_explicit_nuclide(setup: tuple[Calibration, Path, Path]) -> None:
    cal, base, root = setup
    mid = inject.inject(load_extract(base), "yield2pct", "E=13,nuclide=mid,factor=1.5", root / "ym")
    assert mid.after[0] == pytest.approx(1.5 * mid.before[0])
    result = _judge(cal, root / "ym")
    assert not result.passed and result.rejected[0].group == "tape1/E=1.300000+7#1"
    explicit = inject.inject(load_extract(base), "yield2pct", "E=13,nuclide=54140:0", root / "ye")
    assert explicit.keys == ["Y[54140,0]"]
    with pytest.raises(ValueError, match="not found"):
        inject.inject(load_extract(base), "yield2pct", "E=13,nuclide=1:0", root / "yx")


def test_massbin_moves_content_to_the_neighbour(setup: tuple[Calibration, Path, Path]) -> None:
    cal, base, root = setup
    rec = inject.inject(load_extract(base), "massbin", "E=13,bin=max", root / "mb")
    assert len(rec.keys) == 2 and rec.after[1] == 0.0
    assert rec.after[0] == pytest.approx(rec.before[0] + rec.before[1])
    hit = _judge(cal, root / "mb").rejected[0]
    assert (hit.file, hit.block) == (APOST, "APOST")
    assert {t.key for t in hit.top[:2]} == set(rec.keys)
    down = inject.inject(load_extract(base), "massbin", "E=13,bin=mid,step=-1", root / "mb2")
    assert down.keys[0] != down.keys[1]
    with pytest.raises(ValueError, match=r"Apost\.dmp files match"):
        inject.inject(load_extract(base), "massbin", "E=7,bin=max", root / "mb3")


def test_isomer_moves_state_one_into_state_zero(setup: tuple[Calibration, Path, Path]) -> None:
    cal, base, root = setup
    rec = inject.inject(load_extract(base), "isomer", "E=14.5,nuclide=max", root / "iso")
    assert rec.keys[0].endswith(",0]") and rec.keys[1].endswith(",1]")
    assert rec.after == [pytest.approx(rec.before[0] + rec.before[1]), 0.0]
    hit = _judge(cal, root / "iso").rejected[0]
    assert hit.group == "tape1/E=1.450000+7#1"
    assert {t.key for t in hit.top[:2]} == set(rec.keys)


def test_list_sites_gives_max_and_mid_per_energy(setup: tuple[Calibration, Path, Path]) -> None:
    _, base, root = setup
    ex = load_extract(base)
    sites = inject.list_sites(ex, "yield2pct")
    assert len(sites) == 2 * len(ENERGIES)
    assert {s.spec.split(",")[0] for s in sites} == {"E=13", "E=14.5"}
    assert {s.spec.split(",")[-1] for s in sites} == {"nuclide=max", "nuclide=mid"}
    for i, site in enumerate(sites):  # every listed spec can be injected as written
        rec = inject.inject(ex, "yield2pct", site.spec, root / f"site{i}")
        assert tuple(rec.keys) == site.keys
    assert len(inject.list_sites(ex, "massbin")) == 2
    assert len(inject.list_sites(ex, "isomer")) == 2 * len(ENERGIES)


def test_sites_carry_the_mde_of_their_keys(setup: tuple[Calibration, Path, Path]) -> None:
    cal, base, _ = setup
    ex = load_extract(base)
    sites = inject.list_sites(ex, "yield2pct", cal=cal)
    mde = cal.mde(cal.file(ENDF).family("MF8/MT454", "tape1/E=1.450000+7#1"), 1)  # type: ignore[union-attr]
    for site in sites:
        assert site.mde_abs[0] is not None and site.mde_abs[0] > 0.0
        assert site.delta_over_mde[0] == pytest.approx(0.02 * site.values[0] / site.mde_abs[0])
    top = next(s for s in sites if s.spec.startswith("E=14.5") and s.spec.endswith("max"))
    za, state = top.keys[0][2:-1].split(",")
    row = next(
        i for i in range(len(mde.mean)) if mde.kmat[i].tolist()[1:3] == [int(za), int(state)]
    )
    assert top.mde_abs[0] == pytest.approx(float(mde.absolute[row]))
    # a 2 % shift of the largest yield is far above the MDE here; the isomer transfer even more
    assert top.delta_over_mde[0] is not None and top.delta_over_mde[0] > 1.0
    assert all(
        r is not None and r > 1.0
        for s in inject.list_sites(ex, "isomer", cal=cal)
        for r in s.delta_over_mde
    )


def test_cli(setup: tuple[Calibration, Path, Path], capsys: pytest.CaptureFixture[str]) -> None:
    cal, base, root = setup
    out = root / "cli"
    assert (
        inject.main(
            [
                "--run",
                str(base),
                "--fault",
                "yield2pct",
                "--at",
                "E=13,nuclide=max",
                "--out",
                str(out),
            ]
        )
        == 0
    )
    assert json.loads(capsys.readouterr().out)["fault"] == "yield2pct"
    assert (
        verdict.main(["--calibration", str(cal.root), "--candidate-extract", str(out), "--quiet"])
        == 1
    )
    assert inject.main(["--run", str(base), "--fault", "massbin", "--list-sites"]) == 0
    printed = [ln for ln in capsys.readouterr().out.splitlines() if ln.startswith("{")]
    assert len(printed) == 2
    assert (
        inject.main(
            ["--run", str(base), "--fault", "isomer", "--at", "E=99", "--out", str(root / "no")]
        )
        == 2
    )
