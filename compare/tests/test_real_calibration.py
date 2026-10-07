# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Smoke test of calibrate and verdict on the real Cf-252 ensemble members (validation data).

It uses the first five stored members of ``m2-ens-m1-cf252-gs`` (a calibration needs only four)
and the held-out run ``m1-g4-cf252-ref1-independent``; it checks that the pipeline runs end to end
on real parser output and that the artifacts are sane. It does not assert the verdict: with five
runs the calibration is not the K = 20 one that gate G3 measures.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pytest

from compare import calibrate as cal_mod
from compare import verdict
from compare.calibrate import Calibration
from compare.extract import load_extract

_CAPTURES = Path(__file__).resolve().parents[2] / "validation" / "reference_store" / "captures"
_HELD_OUT = "m1-g4-cf252-ref1-independent"
_PREFIX = "m2-ens-m1-cf252-gs"


def _members() -> list[str]:
    if not _CAPTURES.is_dir():
        return []
    return cal_mod.resolve_ensemble([_PREFIX]) if any(_CAPTURES.glob(f"{_PREFIX}-s*")) else []


@pytest.mark.validation
@pytest.mark.slow
def test_calibrate_and_judge_real_captures(tmp_path: Path) -> None:
    members = _members()
    if len(members) < 5 or not (_CAPTURES / _HELD_OUT).is_dir():
        pytest.skip("fewer than five stored Cf-252 ensemble members or no held-out run")
    out = tmp_path / "cal"
    assert (
        cal_mod.main(
            [
                "--ensemble",
                *members[:5],
                "--leave-out",
                members[0],
                "--out",
                str(out),
                "--jobs",
                "2",
            ]
        )
        == 0
    )
    cal = Calibration.open(out)
    assert cal.runs == 4 and cal.manifest["excluded"] == [members[0]]
    assert cal.manifest["families"] > 1000 and cal.stat_families > 1000
    assert cal.input_sha256 and len(cal.input_sha256) == 64
    diag = json.loads((out / "diagnostics.json").read_text())
    assert diag["fields"]["n_det"] > 0 and "dmp" in diag["per_kind"]
    candidate = load_extract(_HELD_OUT)
    assert candidate.input_sha256 == cal.input_sha256
    result = verdict.judge(cal, [candidate])
    assert result.tested > 1000
    assert np.all((result.p_values >= 0.0) & (result.p_values <= 1.0))
    held_in = verdict.judge(cal, [load_extract(members[0])])  # the left-out member, like any run
    assert abs(held_in.tested - result.tested) < 0.02 * result.tested
    assert np.all((held_in.p_values >= 0.0) & (held_in.p_values <= 1.0))
