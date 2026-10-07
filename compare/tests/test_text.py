# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for the generic text parser."""

from __future__ import annotations

from pathlib import Path

from compare.model import Key
from compare.parsers import text

_BANNER = "   GEF 2025/1.2 compiled on 2026-01-02 at 03:04:05.\n"
_PROGRESS = "   100 events processed at 15.09.2026, 18:20:48\n"


def _obs(tmp_path: Path, content: str, rel: str = "work/in/a.in") -> dict[Key, object]:
    path = tmp_path / "f.txt"
    path.write_bytes(content.encode("latin-1"))
    return dict(text.observables(path, rel))


def test_numbers_and_templates(tmp_path: Path) -> None:
    obs = _obs(tmp_path, "x = 3 4.5e-2\nname\n\n -7\n")
    label = "x = # # #1"
    assert obs[Key("work/in/a.in", "text", "", "x = # # #1")] == "x = # #"
    assert obs[Key("work/in/a.in", "text", "", label, (1,))] == 3
    assert obs[Key("work/in/a.in", "text", "", label, (2,))] == 0.045
    assert obs[Key("work/in/a.in", "text", "", "name #1")] == "name"
    assert obs[Key("work/in/a.in", "text", "", " # #1", (1,))] == -7


def test_keys_stable_under_inserted_and_removed_lines(tmp_path: Path) -> None:
    base = "a 1\nb 2\na 3\nc 4\n"
    changed = "new line 9\na 1\nb 2\na 3\nextra\nc 4\n"
    ob, oc = _obs(tmp_path, base), _obs(tmp_path, changed)
    assert all(oc[k] == v for k, v in ob.items())
    removed = _obs(tmp_path, "a 1\na 3\nc 4\n")
    assert Key("work/in/a.in", "text", "", "b # #1", (1,)) not in removed
    assert removed[Key("work/in/a.in", "text", "", "a # #2", (1,))] == 3


def test_changed_wording_is_visible(tmp_path: Path) -> None:
    a = _obs(tmp_path, "mass yield 5\n")
    b = _obs(tmp_path, "mass yields 5\n")
    assert set(a) != set(b)


def test_masked_times_not_emitted(tmp_path: Path) -> None:
    a = _obs(tmp_path, _BANNER + _PROGRESS, "stdout.log")
    b = _obs(
        tmp_path,
        _BANNER.replace("2026-01-02", "2027-05-06") + _PROGRESS.replace("18", "19"),
        "stdout.log",
    )
    assert a == b
    assert not any("18:20" in str(v) for v in a.values())
    assert any(v == "   # events processed at <MASK:progress_time>" for v in a.values())


def test_roundtrip_keeps_bytes(tmp_path: Path) -> None:
    path = tmp_path / "f.txt"
    for data in (b"", b"a\n", b"a\n\n\nb", b"x\r\n\xe4\xff\n"):
        path.write_bytes(data)
        assert text.roundtrip(path) == data
