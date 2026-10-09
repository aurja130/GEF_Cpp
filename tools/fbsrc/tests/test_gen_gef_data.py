# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

"""Tests for tools/fbsrc/gen_gef_data.py: C string decoding, DATA table parsing, chain order,
Restore naming, rendering, and fingerprints. The slow test checks the stock emission."""

from __future__ import annotations

import re
from pathlib import Path

import pytest

from tools.fbsrc.common import FbsrcError
from tools.fbsrc.emit_c import Emission
from tools.fbsrc.gen_gef_data import (
    CAPTURES_DIR,
    GOLDEN_FILE,
    VARIANTS,
    Block,
    DataTable,
    VariantData,
    build_variant,
    chain_order,
    check_capture,
    decode_c_string,
    fingerprint,
    item_hex,
    own_symbols,
    parse_tables,
    render_block,
    restore_names,
    shared_symbols,
    split_table,
)


def _fnv1a64(data: bytes) -> int:
    digest = 0xCBF29CE484222325
    for byte in data:
        digest = ((digest ^ byte) * 0x100000001B3) & ((1 << 64) - 1)
    return digest


def _table(index: int, entries: list[str]) -> str:
    return (
        f"static struct $14__FB_DATADESC$ label${index}[{len(entries)}] = "
        f"{{ {', '.join(entries)} }};"
    )


def _item(length: int, text: str) -> str:
    return f'{{ (int16){length}, (void*)"{text}" }}'


def _link(target: str) -> str:
    return f"{{ (int16)-1, (void*){target} }}"


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("0.5", b"0.5"),
        (r"\x5C", b"\\"),
        (r"\x22", b'"'),
        (r"\101", b"A"),
        (r"\n", b"\n"),
        (r"\\", b"\\"),
        (r"\?", b"?"),
        ("", b""),
    ],
)
def test_decode_c_string(body: str, expected: bytes) -> None:
    assert decode_c_string(body) == expected


@pytest.mark.parametrize("body", [r"a\qb", r"\x1FF", "tab\there"])
def test_decode_c_string_rejects_unsupported_syntax(body: str) -> None:
    with pytest.raises(FbsrcError):
        decode_c_string(body)


def test_parse_tables_reads_items_and_link() -> None:
    text = "\n".join(
        [
            _table(7, [_item(1, "A"), _item(2, "BC"), _link("label$9")]),
            _table(9, [_item(1, "x"), _link("0ull")]),
            "unrelated line",
        ]
    )
    tables = parse_tables(text)
    assert set(tables) == {7, 9}
    assert tables[7].items == (b"A", b"BC")
    assert tables[7].link == 9
    assert tables[9].items == (b"x",)
    assert tables[9].link is None


def test_parse_tables_rejects_length_mismatch() -> None:
    text = _table(1, [_item(3, "A"), _link("0ull")])
    with pytest.raises(FbsrcError, match="item length 3"):
        parse_tables(text)


def test_parse_tables_rejects_wrong_count() -> None:
    text = _table(1, [_item(1, "A"), _item(1, "B"), _link("0ull")]).replace("[3]", "[2]")
    with pytest.raises(FbsrcError, match="declares 2 entries"):
        parse_tables(text)


def test_parse_tables_rejects_negative_item_length() -> None:
    text = _table(1, [_item(-2, "A"), _link("0ull")])
    with pytest.raises(FbsrcError, match="not an item"):
        parse_tables(text)


def test_parse_tables_rejects_duplicate_and_empty() -> None:
    text = _table(1, [_link("0ull")])
    with pytest.raises(FbsrcError, match="declared twice"):
        parse_tables(text + "\n" + text)
    with pytest.raises(FbsrcError, match="no DATA tables"):
        parse_tables("nothing here")


def _data_table(index: int, link: int | None) -> DataTable:
    return DataTable(index, (), link)


def test_chain_order_follows_links_from_the_head() -> None:
    tables = {1: _data_table(1, 2), 2: _data_table(2, None), 3: _data_table(3, 1)}
    assert [t.index for t in chain_order(tables)] == [3, 1, 2]


def test_chain_order_rejects_two_heads() -> None:
    tables = {1: _data_table(1, None), 2: _data_table(2, None)}
    with pytest.raises(FbsrcError, match="2 heads"):
        chain_order(tables)


def test_chain_order_rejects_cycle_and_dangling_link() -> None:
    cycle = {1: _data_table(1, 2), 2: _data_table(2, 1)}
    with pytest.raises(FbsrcError, match="heads"):
        chain_order(cycle)
    dangling = {1: _data_table(1, 5)}
    with pytest.raises(FbsrcError, match="dangling"):
        chain_order(dangling)


def test_restore_names_maps_table_to_basic_label(tmp_path: Path) -> None:
    (tmp_path / "GEF.bas").write_text("print 1\n  Restore NucliDedata  ' comment\n", "utf-8")
    text = "\n".join(
        [
            '#line 2 "/some/where/GEF.bas"',
            "fb_DataRestore( (void*)label$5 );",
        ]
    )
    names, calls = restore_names(text, tmp_path)
    assert names == {5: "NUCLIDEDATA"}
    assert calls == 1


def test_restore_names_rejects_line_that_is_not_a_restore(tmp_path: Path) -> None:
    (tmp_path / "GEF.bas").write_text("print 1\n", "utf-8")
    text = '#line 1 "GEF.bas"\nfb_DataRestore( (void*)label$5 );'
    with pytest.raises(FbsrcError, match="not a Restore statement"):
        restore_names(text, tmp_path)


def test_restore_names_rejects_missing_source(tmp_path: Path) -> None:
    text = '#line 1 "GEF.bas"\nfb_DataRestore( (void*)label$5 );'
    with pytest.raises(FbsrcError, match="cannot read BASIC source"):
        restore_names(text, tmp_path)


def test_render_block_round_trips_the_items() -> None:
    items = (b'a"b', b"\\", b"?", b"x" * 200, b"0.5")
    block = Block("LABEL", items)
    text = "\n".join(render_block("shared_label", block))
    literals = re.findall(r'"((?:[^"\\]|\\.)*)"', text)
    decoded = b"".join(decode_c_string(literal) for literal in literals)
    assert decoded == b"".join(item + b"\n" for item in items)
    assert ".items = 5," in text
    assert "DataBlock const shared_label{" in text


def test_render_block_handles_no_items() -> None:
    text = "\n".join(render_block("shared_empty", Block(None, ())))
    assert '.text = ""' in text
    assert ".items = 0," in text


def test_fingerprint_matches_reference_fnv_over_hex_text() -> None:
    assert item_hex(b"") == "-"
    assert item_hex(b"\x0a\xff") == "0AFF"
    items = [b"A", b"", b"0.5"]
    assert fingerprint(items) == _fnv1a64(b"41\n-\n302E35\n")
    assert fingerprint([]) == 0xCBF29CE484222325


def _variant(key: str, blocks: list[Block]) -> VariantData:
    variant = next(v for v in VARIANTS if v.key == key)
    return VariantData(variant, tuple(blocks), (), 0)


def test_shared_and_own_symbols() -> None:
    common = Block("APRE_HG180", (b"1",))
    unrestored = Block(None, (b"2",))
    only_here = Block("NUCLIDEDATA", (b"3",))
    jeff33 = _variant("jeff33", [only_here, common, unrestored])
    jeff311 = _variant("jeff311", [common, unrestored, Block("NUCLIDEDATA", (b"4",))])
    variants = [jeff33, jeff311, *(_variant(v.key, [common]) for v in VARIANTS[2:])]
    shared = shared_symbols(variants)
    assert shared == {common: "shared_apre_hg180"}
    assert own_symbols(jeff33, shared) == {
        only_here: "own_nuclidedata",
        unrestored: "own_unrestored_1",
    }


def test_split_table_keeps_items_in_order_and_bounds_blocks() -> None:
    items = (b"x" * 20000,) * 3
    blocks = split_table("L", items)
    assert [block.part for block in blocks] == [0, 1, 2]
    assert all(block.name == "L" for block in blocks)
    assert [item for block in blocks for item in block.items] == list(items)
    assert split_table(None, ()) == [Block(None, ())]
    with pytest.raises(FbsrcError, match="does not fit one block"):
        split_table("L", (b"x" * 40000,))


def test_continuation_blocks_get_part_suffix() -> None:
    first = Block("NUCLIDEDATA", (b"1",))
    second = Block("NUCLIDEDATA", (b"2",), 1)
    assert own_symbols(_variant("jeff33", [first, second]), {}) == {
        first: "own_nuclidedata",
        second: "own_nuclidedata_1",
    }


@pytest.mark.slow
def test_stock_emission_matches_the_jeff33_golden(emission: Emission) -> None:
    variant = VARIANTS[0]
    data = build_variant(variant, emission)
    assert sum(1 for block in data.blocks if block.part == 0) == 197
    assert sum(len(block.items) for block in data.blocks) == 214639
    assert len(data.labels) == 194
    assert sum(1 for block in data.blocks if block.name is None and block.part == 0) == 3
    assert all(sum(len(item) + 1 for item in block.items) <= 65536 for block in data.blocks)
    row = next(
        line.split()
        for line in GOLDEN_FILE.read_text("utf-8").splitlines()
        if line.startswith("jeff33 ")
    )
    items = [item for block in data.blocks for item in block.items]
    assert fingerprint(items) == int(row[2], 16)
    capture = CAPTURES_DIR / variant.capture / "work" / "probes" / "datachain.txt"
    if not capture.is_file():
        pytest.skip("reference store capture absent")
    assert check_capture(data) == len(items)
