# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for harness.minicheck on synthetic tapes (parser: ``compare.parsers.endf``)."""

from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np
import pytest

from compare.parsers.endf import Nuclide, parse_endf_float
from compare.parsers.endf import mt454_tapes as parse_text
from compare.parsers.endf import read_mt454 as parse_file
from harness.common import REPO_ROOT, HarnessError
from harness.minicheck import PASS, PASS_FLUCT, compare_tapes, main, z_scores

Spec = dict[float, list[tuple[int, int, float]]]


def _endf(x: float) -> str:
    """ENDF float without 'E': ``1.234567-5``."""
    if x == 0:
        return "0.000000+0"
    mant, exp = f"{x:.6e}".split("e")
    return f"{float(mant):.6f}{int(exp):+d}"


def _rec(fields: list[str], mat: int, ns: int, mf: int = 8, mt: int = 454) -> str:
    body = "".join(f.rjust(11) for f in fields).ljust(66)
    return f"{body}{mat:4d}{mf:2d}{mt:3d}{ns:5d}\n"


def write_tape(spec: Spec, mat: int = 3332) -> str:
    """Render ``{E: [(ZA, FPS, Y)]}`` as a one-tape ENDF text."""
    out = _rec([], mat, 0, 0, 0)
    ns = 0
    rows: list[str] = []

    def add(fields: list[str]) -> None:
        nonlocal ns
        ns += 1
        rows.append(_rec(fields, mat, ns))

    add([_endf(8.6214e4), _endf(212.157), "1", "0", "0", "0"])
    for energy, nucs in spec.items():
        add([_endf(energy), _endf(0), "1", "0", str(4 * len(nucs)), str(len(nucs))])
        vals: list[str] = []
        for za, st, y in nucs:
            vals += [_endf(float(za)), _endf(float(st)), _endf(y), _endf(0.0)]
        for i in range(0, len(vals), 6):
            add(vals[i : i + 6])
    out += "".join(rows)
    out += _rec([_endf(0)] * 2 + ["0"] * 4, mat, 99999, 8, 0)
    out += _rec([], mat, 0, 0, 0)
    out += _rec([], 0, 0, 0, 0)
    out += _rec([], -1, 0, 0, 0)
    return out


def _spec(scale: float = 1.0) -> Spec:
    """Two energies, 60 nuclides over 20 masses; yields sum to 2 per energy."""
    spec: Spec = {}
    for energy in (2.53e-2, 1.0e6):
        nucs: list[tuple[int, int, float]] = []
        for k in range(60):
            a = 80 + k % 20
            nucs.append((1000 * (30 + k // 20) + a, k % 2, 2.0 / 60 * (1 + 0.1 * (k % 3))))
        tot = sum(n[2] for n in nucs)
        spec[energy] = [(za, st, 2.0 * y / tot * scale) for za, st, y in nucs]
    return spec


@pytest.mark.parametrize(
    ("text", "value"),
    [
        ("1.234567-5", 1.234567e-5),
        ("-1.234567-5", -1.234567e-5),
        (" 2.506200+4", 25062.0),
        ("1.5E+3", 1500.0),
        ("1.5E-3", 1.5e-3),
        ("           ", 0.0),
        ("0.000000+0", 0.0),
        ("         59", 59.0),
        (" 9.999997-7", 9.999997e-7),
    ],
)
def test_endf_float(text: str, value: float) -> None:
    assert parse_endf_float(text) == pytest.approx(value, rel=1e-12, abs=0)


def test_endf_float_rejects_garbage() -> None:
    with pytest.raises(ValueError, match="not an ENDF number"):
        parse_endf_float("abc")


def test_parse_roundtrip_and_states() -> None:
    (tape,) = parse_text(write_tape(_spec()))
    assert sorted(tape) == [pytest.approx(2.53e-2), 1.0e6]
    nucs = tape[1.0e6]
    assert len(nucs) == 60
    assert nucs[0].state == 0
    assert nucs[1] == Nuclide(nucs[1].za, 1, nucs[1].y, 0.0)
    assert nucs[0].z == 30
    assert nucs[0].a == 80
    assert math.fsum(n.y for n in nucs) == pytest.approx(2.0, abs=1e-5)


def test_two_tape_file_selection(tmp_path: Path) -> None:
    first = {1.0e6: [(30080, 0, 2.0)]}
    p = tmp_path / "two.dat"
    p.write_text(write_tape(first) + write_tape(_spec()))
    tapes = parse_file(p)
    assert len(tapes) == 2
    assert list(tapes[0]) == [1.0e6]
    assert len(tapes[1]) == 2


def _write(tmp_path: Path, name: str, spec: Spec) -> Path:
    p = tmp_path / name
    p.write_text(write_tape(spec))
    return p


def test_identical_tapes_pass(tmp_path: Path) -> None:
    a = _write(tmp_path, "a.dat", _spec())
    out = tmp_path / "r.json"
    # identical tapes: z = 0 everywhere, so z_rms = 0 is below the lower bound -> FAIL by
    # design; the check below uses compare_tapes to assert z = 0 and Σ passes.
    (ta,) = parse_file(a)
    for r in compare_tapes(ta, ta, 1e9):
        assert r.rl.z_rms == 0.0
        assert r.rl.z_rms_mass == 0.0
        assert r.rl.max_abs_z == 0.0
        assert abs(r.rl.sum_a - 2.0) < 1e-4
    assert main([str(a), str(a), "--events", "1e9", "--json", str(out)]) == 1
    data = json.loads(out.read_text())
    assert data["passed"] is False
    assert len(data["energies"]) == 2


def test_scaled_yield_fails(tmp_path: Path) -> None:
    base = _spec()
    scaled = {
        e: [(za, st, y * (1.1 if i == 0 else 1.0)) for i, (za, st, y) in enumerate(v)]
        for e, v in base.items()
    }
    a = _write(tmp_path, "a.dat", scaled)
    b = _write(tmp_path, "b.dat", base)
    (ta,), (tb,) = parse_file(a), parse_file(b)
    res = compare_tapes(ta, tb, 1e9)
    assert all(not r.passed for r in res)
    assert all(r.rl.max_z_nuclide == res[0].rl.max_z_nuclide for r in res)
    assert res[0].rl.max_abs_z > 10
    assert main([str(a), str(b), "--events", "1e9"]) == 1


def test_low_statistics_excluded() -> None:
    spec: Spec = {1.0: [(30080, 0, 1.0), (30081, 0, 1e-9)]}
    tape = parse_text(write_tape(spec))[0]
    (r,) = compare_tapes(tape, tape, 1e6)
    assert r.rl.n_nuclides == 1


def test_missing_energy_is_error(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    spec = _spec()
    short = {e: v for e, v in spec.items() if e == 1.0e6}
    a = _write(tmp_path, "a.dat", spec)
    b = _write(tmp_path, "b.dat", short)
    assert main([str(a), str(b), "--events", "1e6"]) == 2
    assert "missing in the reference" in capsys.readouterr().err


def test_usage_errors(tmp_path: Path) -> None:
    a = _write(tmp_path, "a.dat", _spec())
    assert main([str(a), str(a)]) == 2
    assert main([str(a), str(a), "--events", "0"]) == 2
    assert main([str(a), str(tmp_path / "nope.dat"), "--events", "1"]) == 2
    assert main([str(a), str(a), "--events", "1", "--tape", "5"]) == 2


def test_compare_raises_harness_error_on_duplicates() -> None:
    spec: Spec = {1.0: [(30080, 0, 1.0), (30080, 0, 1.0)]}
    tape = parse_text(write_tape(spec))[0]
    with pytest.raises(HarnessError, match="duplicate nuclide"):
        compare_tapes(tape, tape, 1e6)


def _draw(seed: int, n: float, perturb: dict[float, float] | None = None) -> Spec:
    """Poisson-noisy 400-nuclide / 200-mass yields; ``perturb[E]`` = +-fraction on alternates."""
    rng = np.random.default_rng(seed)
    spec: Spec = {}
    for energy in (2.53e-2, 1.0e6):
        d = (perturb or {}).get(energy, 0.0)
        raw: list[float] = []
        for k in range(400):
            true = 2.0 / 400 * (1 + 0.5 * (k % 5) / 4) * (1 + d * (1 if k % 2 else -1))
            raw.append(float(rng.poisson(true * n)) / n)
        tot = math.fsum(raw)
        spec[energy] = [
            (1000 * (30 + k // 200) + 80 + k % 200, k % 2, 2.0 * y / tot) for k, y in enumerate(raw)
        ]
    return spec


def _three(
    tmp_path: Path, r: Spec, lib: Spec, t: Spec, extra: list[str] | None = None
) -> tuple[int, dict[str, object]]:
    paths = [_write(tmp_path, f"{n}.dat", sp) for n, sp in (("r", r), ("l", lib), ("t", t))]
    out = tmp_path / "out.json"
    argv = [str(paths[0]), str(paths[1]), "--events", "1e6", "--json", str(out), *(extra or [])]
    rc = main([*argv, "--third", str(paths[2])])
    return rc, json.loads(out.read_text())


def test_z_generalised_event_counts() -> None:
    key = (30080, 0)
    _, z = z_scores({key: 0.02}, {key: 0.03}, 1e6, 1e6)
    assert z[0] == pytest.approx(-0.01 / math.sqrt(0.05 / 1e6))
    _, z = z_scores({key: 0.02}, {key: 0.03}, 1e6, 4e6)
    assert z[0] == pytest.approx(-0.01 / math.sqrt(0.02 / 1e6 + 0.03 / 4e6))
    # expected counts 0.02*1e3 + 0.03*1e3 = 50 >= 20 kept; 10 excluded
    assert z_scores({key: 0.02}, {key: 0.03}, 1e3, 1e3)[0] == [key]
    assert z_scores({key: 0.002}, {key: 0.003}, 1e3, 1e3)[0] == []


def test_three_way_library_fluctuation(tmp_path: Path) -> None:
    lib = _draw(13, 1e6, {1.0e6: 0.1})
    r, t = _draw(11, 1e6), _draw(12, 1e6)
    (tr,), (tl,), (tt,) = (
        parse_file(_write(tmp_path, n, sp)) for n, sp in (("r", r), ("l", lib), ("t", t))
    )
    res = {x.energy: x for x in compare_tapes(tr, tl, 1e6, third=tt)}
    bad = res[1.0e6]
    assert bad.verdict == PASS_FLUCT
    assert bad.rl.z_rms > 1.5
    assert bad.tl is not None
    assert bad.tl.z_rms > 1.5
    assert bad.rt is not None
    assert 0.8 <= bad.rt.z_rms <= 1.5
    assert res[2.53e-2].verdict == PASS
    rc, data = _three(tmp_path, r, lib, t)
    assert rc == 0
    assert data["passed"] is True
    # two-way: the same R fails against the perturbed library
    assert main([str(tmp_path / "r.dat"), str(tmp_path / "l.dat"), "--events", "1e6"]) == 1


def test_three_way_test_tape_perturbed_fails(tmp_path: Path) -> None:
    lib, t = _draw(13, 1e6), _draw(12, 1e6)
    r = _draw(11, 1e6, {1.0e6: 0.1})
    rc, data = _three(tmp_path, r, lib, t)
    assert rc == 1
    verdicts = {e["energy"]: e["verdict"] for e in data["energies"]}  # type: ignore[index]
    assert verdicts[1.0e6] == "fail"
    assert verdicts[2.53e-2] == PASS


def test_three_way_missing_energy_in_third(tmp_path: Path) -> None:
    spec = _draw(11, 1e6)
    short = {e: v for e, v in _draw(12, 1e6).items() if e == 1.0e6}
    rc, _ = _three_rc(tmp_path, spec, _draw(13, 1e6), short)
    assert rc == 2


def _three_rc(tmp_path: Path, r: Spec, lib: Spec, t: Spec) -> tuple[int, None]:
    paths = [_write(tmp_path, f"{n}.dat", sp) for n, sp in (("r", r), ("l", lib), ("t", t))]
    return main([str(paths[0]), str(paths[1]), "--events", "1e6", "--third", str(paths[2])]), None


def test_third_events_requires_third(tmp_path: Path) -> None:
    a = _write(tmp_path, "a.dat", _spec())
    assert main([str(a), str(a), "--events", "1", "--third-events", "1"]) == 2


@pytest.mark.validation
def test_real_comparison() -> None:
    test = REPO_ROOT / "validation/test_run/ENDF/GEFY_86_214_n.dat"
    ref = REPO_ROOT / "validation/reference/gefy_nfy_ENDF/GEFY_86_214_n.dat"
    if not (test.exists() and ref.exists()):
        pytest.skip("validation data not available")
    tapes = parse_file(test)
    assert len(tapes) == 2
    res = compare_tapes(tapes[-1], parse_file(ref)[-1], 1e6)
    assert len(res) == 59
    assert all(abs(r.rl.sum_a - 2.0) <= 1e-4 for r in res)
    assert all(0.8 <= r.rl.z_rms <= 1.5 for r in res)
    # Recorded result: two of the 59 energies (5 MeV, 18.5 MeV) miss the provisional
    # mass-yield band; the planning thresholds are provisional and replaced in M2.
    failing = sorted(r.energy for r in res if not r.passed)
    assert failing == [5.0e6, 1.85e7]
