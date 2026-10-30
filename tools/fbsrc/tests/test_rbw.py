# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Tests for tools.fbsrc.rbw: the must-defined analysis on synthetic fbc-style C."""

from __future__ import annotations

import pytest

from tools.fbsrc.rbw import (
    Statement,
    analyse,
    build_nodes,
    must_defined,
    program_for,
    static_declarations,
    writers,
)


def _exposed(code: str, arrays: frozenset[str] = frozenset()) -> list[str]:
    """Variables some path reads before writing them, in order of first such read."""
    stmts = [
        Statement(k + 1, "GEF.bas", k + 1, line.strip())
        for k, line in enumerate(code.strip().splitlines())
    ]
    nodes = build_nodes(stmts, arrays, frozenset({"FOO"}))
    state = must_defined(nodes)
    out: list[str] = []
    for node, defined in zip(nodes, state, strict=True):
        if defined is None:
            continue
        out.extend(v for v in sorted(node.uses) if v not in defined and v not in out)
    return out


def test_a_write_on_one_branch_leaves_the_variable_undefined_after_the_join() -> None:
    code = """
        if( A$ == 0ll ) goto label$1;
        X$ = 1ll;
        label$1:;
        Y$ = X$;
    """
    assert _exposed(code) == ["A$", "X$"]


def test_a_write_on_both_branches_defines_the_variable() -> None:
    code = """
        if( A$ == 0ll ) goto label$1;
        X$ = 1ll;
        goto label$2;
        label$1:;
        X$ = 2ll;
        label$2:;
        Y$ = X$;
    """
    assert _exposed(code) == ["A$"]


def test_a_self_update_reads_before_it_writes() -> None:
    assert _exposed("X$ = X$ + 1ll;") == ["X$"]


def test_a_loop_body_write_does_not_define_for_the_zero_trip_path() -> None:
    code = """
        I$ = 1ll;
        goto label$2;
        label$1:;
        S$ = I$;
        I$ = I$ + 1ll;
        label$2:;
        if( I$ <= N$ ) goto label$1;
        Y$ = S$;
    """
    assert _exposed(code) == ["N$", "S$"]


def test_element_writes_do_not_define_an_array_and_reads_expose_it() -> None:
    code = """
        *(float*)((I$8 << (2ll & 63ll)) + *(int64*)&ARR$) = 0x0p+0f;
        X$ = *(float*)((I$8 << (2ll & 63ll)) + *(int64*)&ARR$);
    """
    assert _exposed(code, frozenset({"ARR$"})) == ["I$8", "ARR$"]


def test_an_array_created_in_the_stretch_is_defined() -> None:
    code = """
        struct $8FBARRAY1IfE LOC$17;
        *(float**)&LOC$17 = (float*)0ull;
        __builtin_memset( (void*)((uint8*)&LOC$17 + 48ll), 0, 24ll );
        fb_ArrayRedimEx( (struct $7FBARRAYIvE*)&LOC$17, 4ull, -1, 0, 1ull, 0ll, 7ll );
        X$ = *(float*)((uint8*)*(int64*)&LOC$17 + 4ll);
    """
    assert _exposed(code, frozenset({"LOC$17"})) == []


def test_declarations_and_memset_initialise_scalars() -> None:
    code = """
        float X$17;
        __builtin_memset( &X$17, 0, 4ll );
        Y$ = X$17;
    """
    assert _exposed(code) == []


def test_byref_arguments_are_reads_and_do_not_define() -> None:
    code = """
        FOO( A$, &B$ );
        Y$ = B$;
    """
    assert _exposed(code) == ["A$", "B$"]


def test_fbc_temporaries_are_not_tracked() -> None:
    code = """
        float vr$12 = FOO( A$ );
        Y$ = vr$12 + TMP$5$7;
    """
    assert _exposed(code) == ["A$"]


def test_a_jump_out_of_the_stretch_ends_the_path() -> None:
    code = """
        if( A$ == 0ll ) goto label$9;
        X$ = 1ll;
        Y$ = X$;
    """
    assert _exposed(code) == ["A$"]


def test_redim_bounds_are_reads() -> None:
    code = """
        struct $8FBARRAY1IfE LOC$17;
        fb_ArrayRedimEx( (struct $7FBARRAYIvE*)&LOC$17, 4ull, -1, 0, 1ull, 0ll, N$ );
    """
    assert _exposed(code, frozenset({"LOC$17"})) == ["N$"]


def test_descriptor_set_up_is_not_an_element_write() -> None:
    stmts = [
        Statement(1, "GEF.bas", 1, "*(float**)&LOC$17 = (float*)0ull;"),
        Statement(2, "GEF.bas", 2, "*(int64*)((uint8*)&LOC$17 + 24ll) = 4ll;"),
        Statement(3, "GEF.bas", 3, "*(float*)((uint8*)*(int64*)&LOC$17 + 4ll) = X$;"),
    ]
    nodes = build_nodes(stmts, frozenset({"LOC$17"}), frozenset[str]())
    assert [sorted(n.element_writes) for n in nodes] == [[], [], ["LOC$17"]]


def test_only_procedure_arguments_count_as_byref() -> None:
    stmts = [
        Statement(1, "GEF.bas", 1, "__builtin_memset( &X$17, 0, 4ll );"),
        Statement(2, "GEF.bas", 2, "FOO( A$, &B$ );"),
    ]
    nodes = build_nodes(stmts, frozenset(), frozenset({"FOO"}))
    assert [sorted(n.byref) for n in nodes] == [[], ["B$"]]


def test_a_declaration_with_an_initialiser_reads_and_defines() -> None:
    code = """
        int64 X$17 = N$;
        Y$ = X$17;
    """
    assert _exposed(code) == ["N$"]


def test_an_array_indexing_the_written_element_is_read_not_written() -> None:
    # VRZ_Double(VIstored(1,I), 2) = 0 (shape of GEF.bas:11487)
    stmts = [
        Statement(
            1,
            "GEF.bas",
            1,
            "*(float*)((((*(int64*)((((1ll * *(int64*)((uint8*)&VIS$ + 72ll)) + I$)"
            " << (3ll & 63ll)) + *(int64*)&VIS$) * *(int64*)((uint8*)&VRZ$ + 72ll)) + 2ll)"
            " << (2ll & 63ll)) + *(int64*)&VRZ$) = 0x0p+0f;",
        )
    ]
    nodes = build_nodes(stmts, frozenset({"VIS$", "VRZ$"}), frozenset[str]())
    assert sorted(nodes[0].element_writes) == ["VRZ$"]
    assert sorted(nodes[0].uses) == ["I$", "VIS$"]


def test_a_static_initialiser_defines_nothing() -> None:
    code = """
        static int64 COUNT$1 = 0ll;
        Y$ = COUNT$1;
    """
    assert _exposed(code) == ["COUNT$1"]


def test_static_declarations_of_every_type_are_found() -> None:
    body = [
        "\tstatic FBSTRING NAME$1;",
        "\tstatic float FGAMMA$1 = 0x1.p-1f;",
        "\tstatic struct $8FBARRAY1IfE TAB$1;",
        "\tfloat LOCAL$1;",
    ]
    assert static_declarations(body) == ("NAME$1", "FGAMMA$1", "TAB$1")


@pytest.mark.fbc
@pytest.mark.usefixtures("emission")
def test_writers_on_gef_c_attribute_callee_writes_and_skip_index_arrays() -> None:
    program = program_for()
    # GEF.bas:8300 calls ACC_EdefO2D, which writes the Shared _EdefO2D.
    acc = writers(analyse("GEF.bas:8300-8300"), program)
    assert [(w.basic_line, w.via) for w in acc["_EDEFO2D$"]] == [(8300, "ACC_EDEFO2D")]
    # GEF.bas:11487 writes VRZ_Double(VIstored(1,I), ...): VIstored is only read.
    vrz = analyse("GEF.bas:11487-11487")
    assert set(writers(vrz, program)) == {"VRZ_DOUBLE$11"}
    assert "VISTORED$11" in {r.variable for r in vrz.reads}
