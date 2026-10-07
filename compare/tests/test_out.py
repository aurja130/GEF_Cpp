# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests of ``compare.parsers.out``: synthetic layouts, then real results files (coverage)."""

from __future__ import annotations

import re
import time
from pathlib import Path

import pytest

from compare.model import Key, Value
from compare.parsers import ParseError, out

ROOT = Path(__file__).resolve().parents[2]
TEST_RUN = ROOT / "validation" / "test_run"
CAPTURES = ROOT / "validation" / "reference_store" / "captures"
RN215_CAPTURES = ("m1-g1-rn215-ref1", "m1-g23-rn215-n-a")
ALL_CAPTURES = (*RN215_CAPTURES, "m1-g1-cf252-ref1")

needs_validation = pytest.mark.skipif(
    not TEST_RUN.is_dir() or not CAPTURES.is_dir(), reason="validation/ data not present"
)

TITLE = (
    '<?xml version="1.0" encoding="ISO-8859-1"?>\n<GEF>\n  <Title>\n'
    "***********************************************************\n"
    " \n       *    GEF, Version 2025/1.2  *\n \n"
    "Output written on 07.10.2026, 11:38:33\n"
    "Calculation with {events} events.\n \n"
    "Calculated yields for the nucleus Z =   86 , A =  215\n"
    " formed by (n,f) with En =  {energy} MeV.\n"
    "  </Title>\n"
)


def block(body: str = "", *, energy: str = "2.53e-08", events: int = 1000000) -> str:
    return TITLE.format(energy=energy, events=events) + body + "</GEF>\n"


def write(tmp_path: Path, text: str, name: str = "R.dat") -> Path:
    path = tmp_path / name
    path.write_bytes(text.encode("latin-1"))
    return path


def parse(tmp_path: Path, text: str) -> dict[Key, Value]:
    result: dict[Key, Value] = {}
    for key, value in out.observables(write(tmp_path, text), "work/out/R.dat"):
        assert key not in result, key
        result[key] = value
    return result


def select(values: dict[Key, Value], block_name: str) -> dict[tuple[str, tuple[int, ...]], Value]:
    return {(k.label, k.index): v for k, v in values.items() if k.block == block_name}


MASS = (
    "  <Prompt_results>\n    <FF>\n      <FF_A>\n        <Mass_yields>\n"
    "------------------------------------------------------------------------\n"
    "--- Mass-yield distribution before and after prompt-neutron emission ---\n"
    "------------------------------------------------------------------------\n"
    " \n  A            Yield            Yield\n"
    "               pre-neutron      post-neutron\n \n"
    "  63            0.001100         0.001100\n"
    "  64            0.002000         0\n"
    "        </Mass_yields>\n      </FF_A>\n    </FF>\n  </Prompt_results>\n"
)


def test_table_scalar_group_and_masked_stamp(tmp_path: Path) -> None:
    values = parse(tmp_path, block(MASS))
    mass = select(values, "Prompt_results/FF/FF_A/Mass_yields")
    assert mass[("Yield (pre-neutron)", (63,))] == 0.0011
    assert mass[("Yield (post-neutron)", (64,))] == 0.0
    assert all(isinstance(v, float) for k, v in mass.items() if k[0].startswith("Yield"))
    title = select(values, "Title")
    assert title[("Calculation with # events.", (1, 1))] == 1000000
    assert title[("Calculated yields for the nucleus Z = # , A = #", (1, 2))] == 215
    assert title[("formed by (n,f) with En = # MeV.", (1, 1))] == 2.53e-08
    assert not any("Output written" in k[0] for k in title)  # masked stamp not emitted
    assert {k.group for k in values} == {"run1/2.53e-08#1"}
    assert {k.file for k in values} == {"work/out/R.dat"}


def test_runs_and_occurrences(tmp_path: Path) -> None:
    text = (
        block(energy="2.53e-08")  # earlier partial run
        + block(energy="2.53e-08")  # real run starts again with thermal
        + block(energy="30")
        + block(energy="2.53e-08")
        + block(energy="30")
        + block(energy="2.53e-08")
    )
    path = write(tmp_path, text)
    got = [s.group for s in out.steps(path)]
    assert got == [
        "run1/2.53e-08#1",
        "run2/2.53e-08#1",
        "run2/30#1",
        "run2/2.53e-08#2",
        "run2/30#2",
        "run2/2.53e-08#3",
    ]
    groups = {k.group for k, _ in out.observables(path, "work/out/R.dat")}
    assert groups == set(got)
    report = out.coverage(path)
    assert [s.group for s in report.steps] == got
    assert report.ok


def test_key_independent_of_other_table_lengths(tmp_path: Path) -> None:
    longer = MASS.replace(
        "  64            0.002000         0\n",
        "  64            0.002000         0\n  65            0.5   0.25\n",
    )
    a = parse(tmp_path, block(MASS, events=10) + block(MASS, energy="5"))
    b = parse(tmp_path, block(longer, events=11) + block(longer, energy="5"))
    only_b = set(b) - set(a)
    assert {k.index for k in only_b if k.block.endswith("Mass_yields")} == {(65,)}
    # the line count of the table does not shift any other key
    other_a = {k for k in a if not k.block.endswith("Mass_yields")}
    other_b = {k for k in b if not k.block.endswith("Mass_yields")}
    assert other_a == other_b


def test_repeated_key_and_isomer_rows(tmp_path: Path) -> None:
    body = (
        "  <Prompt_results>\n    <FF_spin>\n      <Isomeric_yields>\n"
        " A             Z             J             E*           Yield         Events"
        "        Upper limit\n \n"
        " 68            27            3             0.15          100 %         3"
        "             4.142857      \n"
        " 68            27            0             0             85.7 %        6"
        "             5.5           \n"
        "      </Isomeric_yields>\n    </FF_spin>\n  </Prompt_results>\n"
    )
    iso = select(parse(tmp_path, block(body)), "Prompt_results/FF_spin/Isomeric_yields")
    # Rows are keyed by the state's E* in eV, not by row order.
    assert iso[("Yield (%)", (68, 27, 150000))] == 100.0
    assert iso[("Yield (%)", (68, 27, 0))] == 85.7
    assert iso[("Events", (68, 27, 0))] == 6.0


def test_extra_decay_row_does_not_shift_other_rows(tmp_path: Path) -> None:
    rows = (
        "39 97 58       0.002505467    6.03894        1st isomer, beta\n"
        "39 97 58       0.008621801    6.03894        gs, beta\n"
    )
    extra = "39 97 58       1.392843e-09   6.03894        2nd isomer, beta\n"
    head = (
        "  <Delayed>\n    <anti_neutrinos>\n"
        " Z  A   N       Number          Q value       Decay\n \n"
    )
    tail = "    </anti_neutrinos>\n  </Delayed>\n"
    plain = select(parse(tmp_path, block(head + rows + tail)), "Delayed/anti_neutrinos")
    (tmp_path / "x").mkdir()
    shifted = select(
        parse(tmp_path / "x", block(head + extra + rows + tail)), "Delayed/anti_neutrinos"
    )
    for label in ("Number[1st isomer, beta]", "Number[gs, beta]"):
        assert plain[(label, (39, 97, 58, 1))] == shifted[(label, (39, 97, 58, 1))]


def test_decay_text_tables(tmp_path: Path) -> None:
    body = (
        "  <Delayed>\n    <dn_emitters>\n Pn            Z             A             decay\n \n"
        " 3e-06         54            144          ground state - beta_n\n"
        " 5.52e-06      49            127          1st isomer - beta_n\n"
        "    </dn_emitters>\n    <anti_neutrinos>\n Z  A   N       Number          Q value"
        "       Decay\n \n"
        "54 144 90      9.700001e-07   5.616699       gs, beta\n"
        "57 146 89      4e-06          5.622437       1st isomer, beta\n"
        "    </anti_neutrinos>\n  </Delayed>\n"
    )
    values = parse(tmp_path, block(body))
    dn = select(values, "Delayed/dn_emitters")
    assert dn[("Pn[ground state - beta_n]", (54, 144, 1))] == 3e-06
    assert dn[("Pn[1st isomer - beta_n]", (49, 127, 1))] == 5.52e-06
    anti = select(values, "Delayed/anti_neutrinos")
    assert anti[("Q value[1st isomer, beta]", (57, 146, 89, 1))] == 5.622437
    assert out.coverage(write(tmp_path, block(body), "C.dat")).ok


def test_dense_array_and_decimal_keys(tmp_path: Path) -> None:
    body = (
        "  <Prompt_results>\n    <A_Ekin>\n"
        "--- A-Ekin spectrum (pre-neutron)---\n"
        "2-dim. array: (A =  63 To  64 Step 1) (E =  30 To  32 Step 1)\n \n"
        "(The data are written according to the loop structure specified above.\n \n"
        " 0 1 2 3 4 5 \n \n"
        "    </A_Ekin>\n    <E_entrance>\n E / MeV         Counts\n"
        "   0.0           90753\n   0.1           5\n"
        "    </E_entrance>\n  </Prompt_results>\n"
    )
    values = parse(tmp_path, block(body))
    arr = select(values, "Prompt_results/A_Ekin")
    assert arr[("array(A,E) (pre)", (63, 30))] == 0
    assert arr[("array(A,E) (pre)", (64, 32))] == 5
    ent = select(values, "Prompt_results/E_entrance")
    assert ent[("Counts", (0,))] == 90753
    assert ent[("Counts", (1,))] == 5


def test_unknown_numeric_rows_use_the_fallback_and_are_reported(tmp_path: Path) -> None:
    body = "  <Prompt_results>\n    <Z_covariances>\n 0.5 0.25 \n 1 2 3\n    </Z_covariances>\n"
    body += "  </Prompt_results>\n"
    path = write(tmp_path, block(body))
    rows = select(parse(tmp_path, block(body)), "Prompt_results/Z_covariances")
    assert rows[("row", (2, 3))] == 3
    report = out.coverage(path)
    assert report.ok
    assert report.fallback_tokens == 5
    assert report.sections["Prompt_results/Z_covariances"].fallback == 5


def test_coverage_accounts_stamps_and_xml(tmp_path: Path) -> None:
    report = out.coverage(write(tmp_path, block(MASS)))
    assert report.ok
    assert report.tokens == report.accounted
    assert sum(report.allowed.values()) == 5 + 3  # stamp date and time, xml declaration
    assert "100.00 %" in str(report)
    assert report.sections["Prompt_results/FF/FF_A/Mass_yields"].keys == 2


def test_report_not_ok_when_tokens_are_missing() -> None:
    bad = out.Unaccounted(7, "x 1 2", 2, 1)
    report = out.CoverageReport(
        path="x", lines=1, steps=(), tokens=2, accounted=1, allowed={}, sections={},
        unaccounted=(bad,), observables=0,
    )  # fmt: skip
    assert not report.ok
    assert "FAIL" in str(report)


@pytest.mark.parametrize(
    ("text", "needle"),
    [
        (block("  <Prompt_results>\n  </Control>\n"), "closes <Prompt_results>"),
        (TITLE.format(energy="1", events=2), "truncated"),
        (
            block(
                "  <Prompt_results>\n    <A_Ekin>\n"
                "2-dim. array: (A =  63 To  64 Step 1) (E =  30 To  32 Step 1)\n"
                " 0 1 2 3 4 5 6 \n    </A_Ekin>\n  </Prompt_results>\n"
            ),
            "more than 6 values",
        ),
        (
            block(
                "  <Prompt_results>\n    <A_Ekin>\n"
                "2-dim. array: (A =  63 To  64 Step 1) (E =  30 To  32 Step 1)\n"
                " 0 1 2 3 4 \n \n    </A_Ekin>\n  </Prompt_results>\n"
            ),
            "5 of 6",
        ),
    ],
)
def test_parse_errors_name_file_and_line(tmp_path: Path, text: str, needle: str) -> None:
    with pytest.raises(ParseError, match=needle) as info:
        list(out.observables(write(tmp_path, text), "work/out/R.dat"))
    assert "work/out/R.dat: line" in str(info.value)


# --------------------------------------------------------------------------- real files


def real_files() -> list[Path]:
    files: list[Path] = []
    for cap in ALL_CAPTURES:
        work = CAPTURES / cap / "work"
        files += sorted((work / "out").glob("*.dat"))
        files += sorted((work / "tmp").glob("*.ptb"))
    return files


@needs_validation
@pytest.mark.validation
def test_capture_coverage_is_complete_without_fallback() -> None:
    files = real_files()
    assert len(files) >= 3 + 8 + 1
    for path in files:
        report = out.coverage(path)
        assert report.ok, f"{path}: {report} {report.unaccounted[:3]}"
        assert report.percent == 100.0
        assert report.fallback_tokens == 0, path
        assert report.tokens == report.accounted
        kinds = set(report.allowed)
        assert kinds <= {
            "XML declaration: version and encoding numbers",
            "tag names (<GEF1>, <GEF2>)",
            out.ALLOW_LIST[2].reason,
        }


@needs_validation
@pytest.mark.validation
def test_ptb_has_one_step_and_same_layout_as_out() -> None:
    ptb = sorted((CAPTURES / "m1-g1-rn215-ref1" / "work" / "tmp").glob("*.ptb"))
    assert [len(out.steps(p)) for p in ptb] == [1] * len(ptb)
    assert out.steps(ptb[0])[0].group.startswith("run1/")
    sections = {k.block for k, _ in out.observables(ptb[0], f"work/tmp/{ptb[0].name}")}
    nominal = {
        k.block
        for k, _ in out.observables(
            CAPTURES / "m1-g1-rn215-ref1" / "work" / "out" / "GEF_86_215_n.dat", "x"
        )
    }
    assert sections - {"(text)"} == nominal - {"CHI_square"}  # ptb has no chi-square block
    # 45 tagged sections below <GEF> (containers included); the 34 leaves carry the data
    text = (CAPTURES / "m1-g1-rn215-ref1" / "work" / "out" / "GEF_86_215_n.dat").read_text(
        encoding="latin-1"
    )
    first = text[: text.index("</GEF>")]
    tags = re.findall(r"^\s*<([A-Za-z_][\w-]*)>\s*$", first, flags=re.MULTILINE)
    assert len(tags) - 1 == 45
    assert len(nominal - {"(text)", "(root)"}) == 34


@needs_validation
@pytest.mark.validation
def test_key_sets_are_stable_between_seeds_where_the_layout_is_fixed() -> None:
    def load(cap: str) -> dict[Key, Value]:
        path = CAPTURES / cap / "work" / "out" / "GEF_86_215_n.dat"
        values: dict[Key, Value] = {}
        for key, value in out.observables(path, "work/out/GEF_86_215_n.dat"):
            assert key not in values, key
            values[key] = value
        return values

    a, b = load("m1-g1-rn215-ref1"), load("m1-g23-rn215-n-a")
    differing = {k.block for k in set(a) ^ set(b)}
    # sections whose layout is fixed by the input have identical keys in both runs
    fixed = {
        "Control",
        "Comments",
        "CHI_square",
        "Delayed/nu_delayed",
        "Prompt_results/Fission_channels",
        "Prompt_results/FF/FF_Z/Z_even_odd",
        "Prompt_results/Neutrons/Enmean",
        "Prompt_results/Non-fission_results",
    }
    assert fixed.isdisjoint(differing)
    # every other difference is a stochastic table extent (zero-suppressed or content-limited)
    assert differing <= {k.block for k in a} | {k.block for k in b}
    assert "Prompt_results/FF/FF_AZ/Independent_yields" in differing
    # the same energy steps exist in both runs
    assert {k.group for k in a} == {k.group for k in b}
    # shared keys have shared value types
    assert all(type(a[k]) is type(b[k]) for k in set(a) & set(b))


@needs_validation
@pytest.mark.validation
@pytest.mark.slow
def test_test_run_two_runs_full_coverage_and_parse_time() -> None:
    path = TEST_RUN / "out" / "GEF_86_215_n.dat"
    start = time.perf_counter()
    report = out.coverage(path)
    seconds = time.perf_counter() - start
    assert report.ok, f"{report} {report.unaccounted[:3]}"
    assert report.fallback_tokens == 0
    assert len(report.steps) == 63
    assert max(s.run for s in report.steps) == 2
    runs = {s.run: [x for x in report.steps if x.run == s.run] for s in report.steps}
    assert [len(runs[1]), len(runs[2])] == [1, 62]
    thermal = [s.group for s in runs[2] if s.energy == "2.53e-08"]
    assert thermal == ["run2/2.53e-08#1", "run2/2.53e-08#2", "run2/2.53e-08#3"]
    assert report.tokens > 5_000_000
    assert seconds < 90, f"coverage took {seconds:.0f} s"
