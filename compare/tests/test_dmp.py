# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests of ``compare.parsers.dmp``: synthetic edge cases and real dumps (round trip, keys)."""

from __future__ import annotations

import re
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import pytest

from compare.model import Key, Value
from compare.parsers import ParseError, dmp

ROOT = Path(__file__).resolve().parents[2]
TEST_RUN = ROOT / "validation" / "test_run"
CAPTURES = ROOT / "validation" / "reference_store" / "captures"
ROUNDTRIP_CAPTURES = (
    "m1-g1-rn215-ref1",
    "m1-g1-cf252-ref1",
    "m1-g23-rn215-n-a",
    "m1-g23-rn215-n-rp",
    "m1-g4-cf252-ref1-independent",
)

HEADER = (
    "GEF analyzer dump: test\n"
    "C: Written on 15.09.2026, 18:25:04\n"
    "C: Calculation performed with GEF2025/1.2\n"
)


def block(
    name: str = "APOST",
    values: str = "1,2.5,0.9985999,",
    rng: str = "(X = 61 TO 63 BY 1) Y,BT11",
    comments: tuple[str, ...] = ("Z86_A215_n_E0.1MeV", "Post, 1000000 fission events"),
) -> str:
    lines = [f"S: ANALYZER({name})", "S: TITLE(Mass distribution)"]
    lines += [f"S: COMMENT({c})" for c in comments]
    lines += ["X: Mass number", "Y: Yield", f"A: {rng}", values, " "]
    return "\n".join(lines) + "\n"


def keys_of(text: str, tmp_path: Path, rel: str = "work/dmp/s/T.dmp") -> dict[Key, Value]:
    path = tmp_path / "T.dmp"
    path.write_bytes(text.encode())
    return dict(dmp.observables(path, rel))


def rt(text: str) -> str:
    return dmp.render(dmp.parse_text(text))


# ---- synthetic -------------------------------------------------------------------------------


def test_patterns() -> None:
    assert dmp.PATTERNS == ("work/dmp/*/*.dmp",)


def test_roundtrip_keeps_text_exactly() -> None:
    text = HEADER + block()
    assert rt(text) == text


def test_one_d_observables(tmp_path: Path) -> None:
    obs = keys_of(HEADER + block(), tmp_path)
    f = "work/dmp/s/T.dmp"

    def k(label: str, *index: int) -> Key:
        return Key(f, "APOST", "#1", label, tuple(index))

    assert obs[k("y", 61)] == 1.0
    assert obs[k("y", 62)] == 2.5
    assert obs[k("y", 63)] == 0.9985999
    assert obs[k("lo")] == 61.0
    assert obs[k("hi")] == 63.0
    assert obs[k("range")] == "BY 1 Y,BT11"
    assert obs[k("title")] == "Mass distribution"
    assert obs[k("xaxis")] == "Mass number"
    assert obs[k("yaxis")] == "Yield"
    assert obs[k("comment", 0)] == "Z86_A215_n_E0.1MeV"
    assert obs[k("comment", 1)] == "Post, # fission events"
    assert obs[k("events", 1)] == 1000000
    assert obs[Key(f, dmp.FILE_BLOCK, "", "version", (0,))] == "2025/1.2"
    assert obs[Key(f, dmp.PRE_BLOCK, "#1", "GEF analyzer dump: test")] == 1


def test_time_stamp_is_parsed_but_not_emitted(tmp_path: Path) -> None:
    obs = keys_of(HEADER + block(), tmp_path)
    assert not any("Written on" in k.label or "Written on" in str(v) for k, v in obs.items())
    other = HEADER.replace("18:25:04", "19:00:00") + block()
    assert keys_of(other, tmp_path) == obs
    assert rt(other) == other


def test_non_integral_start_uses_ordinals(tmp_path: Path) -> None:
    text = HEADER + block("EN", "5,6,7,", "(X = 0.25 TO 0.45 BY 0.1) Y,HT0", ("c",))
    obs = keys_of(text, tmp_path)
    ys = {k.index: v for k, v in obs.items() if k.label == "y"}
    assert ys == {(0,): 5.0, (1,): 6.0, (2,): 7.0}


def test_fractional_step_with_integral_ratio(tmp_path: Path) -> None:
    text = HEADER + block("EN", "5,6,", "(X = 23.3 TO 23.4 BY 0.1) Y,HT0", ("c",))
    ys = {k.index: v for k, v in keys_of(text, tmp_path).items() if k.label == "y"}
    assert ys == {(233,): 5.0, (234,): 6.0}


def test_wrapped_data_and_last_line_without_comma(tmp_path: Path) -> None:
    text = (
        HEADER
        + "S: ANALYZER(X)\nS: TITLE(t)\nS: COMMENT(a)\nX: x\nY: y\n"
        + "A: (X = 0 TO 5 BY 1) Y,HT0\n1,2,3,\n4,5,6\n \n"
    )
    assert rt(text) == text
    ys = {k.index[0]: v for k, v in keys_of(text, tmp_path).items() if k.label == "y"}
    assert ys == {0: 1.0, 1: 2.0, 2: 3.0, 3: 4.0, 4: 5.0, 5: 6.0}


def test_row_block(tmp_path: Path) -> None:
    text = (
        HEADER
        + "C: Z distributions\nS: Analyzer(Zpre(61))\nC: Apre = 61\nX: Zpre\nY: Yield (%)\n"
        + "A:  X     Y,LTR1\n  24      0.000100\n  26      1.496499\n"
        + "S: Analyzer(Apre(30))\nC: Z = 30\nX: Apre\nY: Yield (%)\nA:  X+30     Y,LTR1\n"
        + "  61      0.000100\n \n"
    )
    assert rt(text) == text
    obs = keys_of(text, tmp_path)
    f = "work/dmp/s/T.dmp"
    assert obs[Key(f, "Zpre(61)", "#1", "y", (26,))] == 1.496499
    assert obs[Key(f, "Zpre(61)", "#1", "range")] == " X     Y,LTR1"
    assert obs[Key(f, "Zpre(61)", "#1", "note", (0,))] == "Apre = 61"
    assert obs[Key(f, "Apre(30)", "#1", "y", (61,))] == 0.0001
    assert obs[Key(f, dmp.PRE_BLOCK, "#1", "C: Z distributions")] == 1


def test_repeated_analyzer_gets_group_counter(tmp_path: Path) -> None:
    text = HEADER + block(values="1,2,3,") + HEADER + block(values="4,5,6,")
    assert rt(text) == text
    obs = keys_of(text, tmp_path)
    f = "work/dmp/s/T.dmp"
    assert obs[Key(f, "APOST", "#1", "y", (61,))] == 1.0
    assert obs[Key(f, "APOST", "#2", "y", (61,))] == 4.0
    # the same remark twice is distinguished by an occurrence counter, not by position
    assert obs[Key(f, dmp.PRE_BLOCK, "#2", "GEF analyzer dump: test")] == 1


def test_multichance_and_trailer(tmp_path: Path) -> None:
    text = (
        "GEF analyzer dump: Multi-chance\n"
        "C: Relative probability for fission after the emission of  1 neutrons and  0 protons: "
        " 0.05882353\n"
        + HEADER
        + block("Emultichance(1,0)", "0.5,", "(X = 23.3 TO 23.3 BY 0.1) Y,HTB0", ("c",))
        + "C: Only first-chance fission occured.\n"
    )
    assert rt(text) == text
    obs = keys_of(text, tmp_path)
    f = "work/dmp/s/T.dmp"
    assert obs[Key(f, "Emultichance(1,0)", "#1", "chance_probability", (1, 0))] == 0.05882353
    assert obs[Key(f, dmp.PRE_BLOCK, "#1", "C: Only first-chance fission occured.")] == 1


def test_only_comment_file(tmp_path: Path) -> None:
    text = "C: Only first-chance fission occured.\n"
    assert rt(text) == text
    assert list(keys_of(text, tmp_path)) == [
        Key("work/dmp/s/T.dmp", dmp.PRE_BLOCK, "#1", "C: Only first-chance fission occured.")
    ]


@pytest.mark.parametrize("text", ["", "\n", " \n \n"])
def test_empty_and_blank_files(text: str) -> None:
    assert rt(text) == text


def test_no_final_newline_and_crlf() -> None:
    text = HEADER + block().rstrip(" \n")
    assert rt(text) == text
    crlf = (HEADER + block()).replace("\n", "\r\n")
    assert rt(crlf) == crlf


def test_note_lines_and_exponents(tmp_path: Path) -> None:
    text = HEADER + block(values="7.1e-05,1e-06,-1.5e+02,", rng="(X = 0 TO 2 BY 1) Y,LTR1")
    text = text.replace("X: Mass", "C: a note\nX: Mass")
    obs = keys_of(text, tmp_path)
    f = "work/dmp/s/T.dmp"
    assert obs[Key(f, "APOST", "#1", "y", (2,))] == -150.0
    assert obs[Key(f, "APOST", "#1", "note", (0,))] == "a note"
    assert rt(text) == text


@pytest.mark.parametrize(
    ("text", "needle"),
    [
        (HEADER + "S: ANALYZER(X)\n", "without an A: line"),
        (HEADER + "garbage\n", "unexpected line"),
        (HEADER + block(values="1,2,"), "values for the range"),
        (HEADER + block(values="1,,3,"), "empty value"),
        (HEADER + block(rng="(X = 0 TO 2 BY 0) Y,HT0"), "non-positive step"),
        (HEADER + block(rng="(X = 0 TO 2) Y,HT0"), "unknown data definition"),
        (
            HEADER + "S: ANALYZER(X)\nS: TITLE(t)\nS: bogus(1)\nA:  X     Y,LTR1\n",
            "unexpected line in analyzer header",
        ),
    ],
)
def test_parse_errors_name_file_and_line(text: str, needle: str) -> None:
    with pytest.raises(ParseError, match=re.escape(needle)) as info:
        dmp.parse_text(text, "f.dmp")
    assert re.search(r"f\.dmp:\d+:", str(info.value))


def test_duplicate_row_x_is_an_error(tmp_path: Path) -> None:
    text = (
        HEADER
        + "S: Analyzer(Zpre(61))\nX: Z\nY: y\nA:  X     Y,LTR1\n  24      0.1\n  24      0.2\n"
    )
    with pytest.raises(ParseError, match="duplicate row"):
        keys_of(text, tmp_path)


def test_range_change_is_visible(tmp_path: Path) -> None:
    a = keys_of(HEADER + block(values="1,2,3,"), tmp_path)
    b = keys_of(HEADER + block(values="2,3,", rng="(X = 62 TO 63 BY 1) Y,BT11"), tmp_path)
    f = "work/dmp/s/T.dmp"
    assert a[Key(f, "APOST", "#1", "lo")] == 61.0
    assert b[Key(f, "APOST", "#1", "lo")] == 62.0
    assert a[Key(f, "APOST", "#1", "y", (62,))] == b[Key(f, "APOST", "#1", "y", (62,))] == 2.0
    assert Key(f, "APOST", "#1", "y", (61,)) not in b


# ---- real data -------------------------------------------------------------------------------


def _check_files(paths: list[str]) -> list[str]:
    """Worker: names of the files whose round trip fails (with the reason)."""
    bad: list[str] = []
    for name in paths:
        path = Path(name)
        try:
            same = dmp.roundtrip(path) == path.read_bytes()
        except ParseError as exc:
            bad.append(f"{name}: {exc}")
            continue
        if not same:
            bad.append(f"{name}: bytes differ")
    return bad


def _roundtrip_all(files: list[Path]) -> list[str]:
    names = sorted(str(p) for p in files)
    chunks = [names[i::16] for i in range(16)]
    with ProcessPoolExecutor(max_workers=4) as pool:
        return [b for result in pool.map(_check_files, chunks) for b in result]


def _dmp_files(root: Path) -> list[Path]:
    return sorted(root.glob("*/*.dmp"))


@pytest.mark.validation
def test_roundtrip_validation_test_run() -> None:
    root = TEST_RUN / "dmp"
    if not root.is_dir():
        pytest.skip("validation/test_run is not available")
    files = _dmp_files(root)
    assert len(files) > 1500
    assert _roundtrip_all(files) == []


@pytest.mark.validation
def test_roundtrip_store_captures() -> None:
    files: list[Path] = []
    for cid in ROUNDTRIP_CAPTURES:
        root = CAPTURES / cid / "work" / "dmp"
        if not root.is_dir():
            pytest.skip(f"capture {cid} is not available")
        files += _dmp_files(root)
    assert len(files) >= 500
    assert _roundtrip_all(files) == []


@pytest.mark.validation
def test_appended_blocks_get_group_counters() -> None:
    """The thermal step dir of test_run holds four appended blocks per analyzer (steps 1, 3,
    62 and an earlier partial run); the 30 MeV dir holds two."""
    root = TEST_RUN / "dmp"
    if not root.is_dir():
        pytest.skip("validation/test_run is not available")
    path = root / "Z86_A215_n_E2.53e-08MeV" / "Apost.dmp"
    obs = dict(dmp.observables(path, "work/dmp/E/Apost.dmp"))
    groups = {k.group for k in obs if k.block == "APOST"}
    assert groups == {"#1", "#2", "#3", "#4"}
    stamps = [v for v in obs.values() if isinstance(v, str) and "Written on" in v]
    assert stamps == []


def _family_shape(
    name_rel: tuple[str, str],
) -> dict[tuple[str, str, str], set[tuple[str, tuple[int, ...]]]]:
    """Worker: per (file, block, group) the non-data key set (label, index) of one dump."""
    name, rel = name_rel
    shape: dict[tuple[str, str, str], set[tuple[str, tuple[int, ...]]]] = {}
    for key, _ in dmp.observables(Path(name), rel):
        fam = shape.setdefault((key.file, key.block, key.group), set())
        if key.label != "y":
            fam.add((key.label, key.index))
    return shape


def _shapes(cid: str) -> dict[tuple[str, str, str], set[tuple[str, tuple[int, ...]]]]:
    root = CAPTURES / cid / "work" / "dmp"
    if not root.is_dir():
        pytest.skip(f"capture {cid} is not available")
    jobs = [(str(p), p.relative_to(root).as_posix()) for p in _dmp_files(root)]
    out: dict[tuple[str, str, str], set[tuple[str, tuple[int, ...]]]] = {}
    with ProcessPoolExecutor(max_workers=4) as pool:
        for shape in pool.map(_family_shape, jobs, chunksize=8):
            out.update(shape)
    return out


#: Analyzers that exist only when the run produced content for them (empty arrays are not
#: written or the loop skips the A/Z): ZApre/ZApost blocks per Z or A with yield, the pre-fission
#: spectra and the second multi-chance branch.
_OPTIONAL = re.compile(r"^(?:Zpre|Zpost|Apre|Apost|Npre|Npost)\(\d+\)$")
_OPTIONAL_NAMES = {"ENCN", "EPCN", "EgammaCN", "Emultichance(2,0)"}


@pytest.mark.validation
def test_key_set_stability_between_same_input_runs() -> None:
    """Same input, same seed class, different seed: identical non-data keys per analyzer.

    The ``y`` keys of an analyzer differ legitimately (GEF trims leading/trailing zero bins, and
    the ZApre/ZApost row blocks list only non-zero rows), so only the non-data keys (title,
    axes, comments, events, range, lo, hi, chance probabilities, section remarks) must agree.
    Analyzers present in only one run must be of the optional kind.
    """
    a = _shapes("m1-g1-rn215-ref1")
    b = _shapes("m1-g23-rn215-n-a")
    assert len(a) > 30000
    mismatched = [fam for fam in a.keys() & b.keys() if a[fam] != b[fam]]
    assert mismatched == []
    for fam in a.keys() ^ b.keys():
        name = fam[1]
        assert name in _OPTIONAL_NAMES or _OPTIONAL.fullmatch(name), fam
