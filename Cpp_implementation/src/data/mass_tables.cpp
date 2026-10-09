// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The static tables GEF loads before it computes anything (M4.3), with BASIC's bounds and
// BASIC's DATA order: the mass-table DATA loaders and the ENfrvar_lim initialiser.
#include "data/table_loaders.hpp"
#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>

namespace gef::data {

namespace {

// Spectra.bas:798-end: `Dim As Double ENfrvar_lim(303) = {...}` (304 values, C emission order).
constexpr std::array<double, 304> enfrvar_lim_bits{{0x0p+0,
                                                    0x1.4F8B588E368F1p-17,
                                                    0x1.4F8B588E368F1p-16,
                                                    0x1.4F8B588E368F1p-15,
                                                    0x1.F75104D551D69p-15,
                                                    0x1.4F8B588E368F1p-14,
                                                    0x1.A36E2EB1C432Dp-14,
                                                    0x1.A36E2EB1C432Dp-13,
                                                    0x1.A36E2EB1C432Dp-12,
                                                    0x1.3A92A30553261p-11,
                                                    0x1.A36E2EB1C432Dp-11,
                                                    0x1.0624DD2F1A9FCp-10,
                                                    0x1.0624DD2F1A9FCp-9,
                                                    0x1.0624DD2F1A9FCp-8,
                                                    0x1.89374BC6A7EFAp-8,
                                                    0x1.0624DD2F1A9FCp-7,
                                                    0x1.47AE147AE147Bp-7,
                                                    0x1.47AE147AE147Bp-6,
                                                    0x1.47AE147AE147Bp-5,
                                                    0x1.EB851EB851EB8p-5,
                                                    0x1.47AE147AE147Bp-4,
                                                    0x1.999999999999Ap-4,
                                                    0x1.999999999999Ap-3,
                                                    0x1.999999999999Ap-2,
                                                    0x1.3333333333333p-1,
                                                    0x1.999999999999Ap-1,
                                                    0x1.p+0,
                                                    0x1.p+1,
                                                    0x1.p+2,
                                                    0x1.8p+2,
                                                    0x1.p+3,
                                                    0x1.4p+3,
                                                    0x1.4p+4,
                                                    0x1.4p+5,
                                                    0x1.Ep+5,
                                                    0x1.4p+6,
                                                    0x1.9p+6,
                                                    0x1.9p+7,
                                                    0x1.9p+8,
                                                    0x1.2Cp+9,
                                                    0x1.9p+9,
                                                    0x1.F4p+9,
                                                    0x1.F4p+10,
                                                    0x1.F4p+11,
                                                    0x1.77p+12,
                                                    0x1.F4p+12,
                                                    0x1.388p+13,
                                                    0x1.388p+14,
                                                    0x1.D4Cp+14,
                                                    0x1.388p+15,
                                                    0x1.86Ap+15,
                                                    0x1.D4Cp+15,
                                                    0x1.117p+16,
                                                    0x1.388p+16,
                                                    0x1.5F9p+16,
                                                    0x1.86Ap+16,
                                                    0x1.24F8p+17,
                                                    0x1.86Ap+17,
                                                    0x1.E848p+17,
                                                    0x1.24F8p+18,
                                                    0x1.55CCp+18,
                                                    0x1.86Ap+18,
                                                    0x1.B774p+18,
                                                    0x1.E848p+18,
                                                    0x1.0C8Ep+19,
                                                    0x1.24F8p+19,
                                                    0x1.3D62p+19,
                                                    0x1.55CCp+19,
                                                    0x1.6E36p+19,
                                                    0x1.86Ap+19,
                                                    0x1.9F0Ap+19,
                                                    0x1.B774p+19,
                                                    0x1.CFDEp+19,
                                                    0x1.E848p+19,
                                                    0x1.0059p+20,
                                                    0x1.0C8Ep+20,
                                                    0x1.18C3p+20,
                                                    0x1.24F8p+20,
                                                    0x1.312Dp+20,
                                                    0x1.3D62p+20,
                                                    0x1.4997p+20,
                                                    0x1.55CCp+20,
                                                    0x1.6201p+20,
                                                    0x1.6E36p+20,
                                                    0x1.7A6Bp+20,
                                                    0x1.86Ap+20,
                                                    0x1.92D5p+20,
                                                    0x1.9F0Ap+20,
                                                    0x1.AB3Fp+20,
                                                    0x1.B774p+20,
                                                    0x1.C3A9p+20,
                                                    0x1.CFDEp+20,
                                                    0x1.DC13p+20,
                                                    0x1.E848p+20,
                                                    0x1.F47Dp+20,
                                                    0x1.0059p+21,
                                                    0x1.06738p+21,
                                                    0x1.0C8Ep+21,
                                                    0x1.12A88p+21,
                                                    0x1.18C3p+21,
                                                    0x1.1EDD8p+21,
                                                    0x1.24F8p+21,
                                                    0x1.2B128p+21,
                                                    0x1.312Dp+21,
                                                    0x1.37478p+21,
                                                    0x1.3D62p+21,
                                                    0x1.437C8p+21,
                                                    0x1.4997p+21,
                                                    0x1.4FB18p+21,
                                                    0x1.55CCp+21,
                                                    0x1.5BE68p+21,
                                                    0x1.6201p+21,
                                                    0x1.681B8p+21,
                                                    0x1.6E36p+21,
                                                    0x1.74508p+21,
                                                    0x1.7A6Bp+21,
                                                    0x1.80858p+21,
                                                    0x1.86Ap+21,
                                                    0x1.8CBA8p+21,
                                                    0x1.92D5p+21,
                                                    0x1.98EF8p+21,
                                                    0x1.9F0Ap+21,
                                                    0x1.A5248p+21,
                                                    0x1.AB3Fp+21,
                                                    0x1.B1598p+21,
                                                    0x1.B774p+21,
                                                    0x1.BD8E8p+21,
                                                    0x1.C3A9p+21,
                                                    0x1.C9C38p+21,
                                                    0x1.CFDEp+21,
                                                    0x1.D5F88p+21,
                                                    0x1.DC13p+21,
                                                    0x1.E22D8p+21,
                                                    0x1.E848p+21,
                                                    0x1.EE628p+21,
                                                    0x1.F47Dp+21,
                                                    0x1.FA978p+21,
                                                    0x1.0059p+22,
                                                    0x1.03664p+22,
                                                    0x1.06738p+22,
                                                    0x1.0980Cp+22,
                                                    0x1.0C8Ep+22,
                                                    0x1.0F9B4p+22,
                                                    0x1.12A88p+22,
                                                    0x1.15B5Cp+22,
                                                    0x1.18C3p+22,
                                                    0x1.1BD04p+22,
                                                    0x1.1EDD8p+22,
                                                    0x1.21EACp+22,
                                                    0x1.24F8p+22,
                                                    0x1.28054p+22,
                                                    0x1.2B128p+22,
                                                    0x1.2E1FCp+22,
                                                    0x1.312Dp+22,
                                                    0x1.37478p+22,
                                                    0x1.3D62p+22,
                                                    0x1.437C8p+22,
                                                    0x1.4997p+22,
                                                    0x1.4FB18p+22,
                                                    0x1.55CCp+22,
                                                    0x1.5BE68p+22,
                                                    0x1.6201p+22,
                                                    0x1.681B8p+22,
                                                    0x1.6E36p+22,
                                                    0x1.74508p+22,
                                                    0x1.7A6Bp+22,
                                                    0x1.80858p+22,
                                                    0x1.86Ap+22,
                                                    0x1.8CBA8p+22,
                                                    0x1.92D5p+22,
                                                    0x1.98EF8p+22,
                                                    0x1.9F0Ap+22,
                                                    0x1.A5248p+22,
                                                    0x1.AB3Fp+22,
                                                    0x1.B1598p+22,
                                                    0x1.B774p+22,
                                                    0x1.BD8E8p+22,
                                                    0x1.C3A9p+22,
                                                    0x1.C9C38p+22,
                                                    0x1.CFDEp+22,
                                                    0x1.D5F88p+22,
                                                    0x1.DC13p+22,
                                                    0x1.E22D8p+22,
                                                    0x1.E848p+22,
                                                    0x1.EE628p+22,
                                                    0x1.F47Dp+22,
                                                    0x1.FA978p+22,
                                                    0x1.0059p+23,
                                                    0x1.03664p+23,
                                                    0x1.06738p+23,
                                                    0x1.0980Cp+23,
                                                    0x1.0C8Ep+23,
                                                    0x1.0F9B4p+23,
                                                    0x1.12A88p+23,
                                                    0x1.15B5Cp+23,
                                                    0x1.18C3p+23,
                                                    0x1.1BD04p+23,
                                                    0x1.1EDD8p+23,
                                                    0x1.21EACp+23,
                                                    0x1.24F8p+23,
                                                    0x1.28054p+23,
                                                    0x1.2B128p+23,
                                                    0x1.2E1FCp+23,
                                                    0x1.312Dp+23,
                                                    0x1.37478p+23,
                                                    0x1.3D62p+23,
                                                    0x1.437C8p+23,
                                                    0x1.4997p+23,
                                                    0x1.4FB18p+23,
                                                    0x1.55CCp+23,
                                                    0x1.5BE68p+23,
                                                    0x1.6201p+23,
                                                    0x1.681B8p+23,
                                                    0x1.6E36p+23,
                                                    0x1.74508p+23,
                                                    0x1.7A6Bp+23,
                                                    0x1.80858p+23,
                                                    0x1.86Ap+23,
                                                    0x1.8CBA8p+23,
                                                    0x1.92D5p+23,
                                                    0x1.98EF8p+23,
                                                    0x1.9F0Ap+23,
                                                    0x1.A5248p+23,
                                                    0x1.AB3Fp+23,
                                                    0x1.B1598p+23,
                                                    0x1.B774p+23,
                                                    0x1.BD8E8p+23,
                                                    0x1.C3A9p+23,
                                                    0x1.C9C38p+23,
                                                    0x1.CFDEp+23,
                                                    0x1.D5F88p+23,
                                                    0x1.DC13p+23,
                                                    0x1.E22D8p+23,
                                                    0x1.E848p+23,
                                                    0x1.EE628p+23,
                                                    0x1.F47Dp+23,
                                                    0x1.FA978p+23,
                                                    0x1.0059p+24,
                                                    0x1.03664p+24,
                                                    0x1.06738p+24,
                                                    0x1.0980Cp+24,
                                                    0x1.0C8Ep+24,
                                                    0x1.0F9B4p+24,
                                                    0x1.12A88p+24,
                                                    0x1.15B5Cp+24,
                                                    0x1.18C3p+24,
                                                    0x1.1BD04p+24,
                                                    0x1.1EDD8p+24,
                                                    0x1.21EACp+24,
                                                    0x1.24F8p+24,
                                                    0x1.28054p+24,
                                                    0x1.2B128p+24,
                                                    0x1.2E1FCp+24,
                                                    0x1.312Dp+24,
                                                    0x1.343A4p+24,
                                                    0x1.37478p+24,
                                                    0x1.3A54Cp+24,
                                                    0x1.3D62p+24,
                                                    0x1.406F4p+24,
                                                    0x1.437C8p+24,
                                                    0x1.4689Cp+24,
                                                    0x1.4997p+24,
                                                    0x1.4CA44p+24,
                                                    0x1.4FB18p+24,
                                                    0x1.52BECp+24,
                                                    0x1.55CCp+24,
                                                    0x1.58D94p+24,
                                                    0x1.5BE68p+24,
                                                    0x1.5EF3Cp+24,
                                                    0x1.6201p+24,
                                                    0x1.650E4p+24,
                                                    0x1.681B8p+24,
                                                    0x1.6B28Cp+24,
                                                    0x1.6E36p+24,
                                                    0x1.71434p+24,
                                                    0x1.74508p+24,
                                                    0x1.775DCp+24,
                                                    0x1.7A6Bp+24,
                                                    0x1.7D784p+24,
                                                    0x1.80858p+24,
                                                    0x1.8392Cp+24,
                                                    0x1.86Ap+24,
                                                    0x1.89AD4p+24,
                                                    0x1.8CBA8p+24,
                                                    0x1.8FC7Cp+24,
                                                    0x1.92D5p+24,
                                                    0x1.95E24p+24,
                                                    0x1.98EF8p+24,
                                                    0x1.9BFCCp+24,
                                                    0x1.9F0Ap+24,
                                                    0x1.A2174p+24,
                                                    0x1.A5248p+24,
                                                    0x1.A831Cp+24,
                                                    0x1.AB3Fp+24,
                                                    0x1.AE4C4p+24,
                                                    0x1.B1598p+24,
                                                    0x1.B466Cp+24,
                                                    0x1.B774p+24,
                                                    0x1.BA814p+24,
                                                    0x1.BD8E8p+24,
                                                    0x1.C09BCp+24,
                                                    0x1.C3A9p+24,
                                                    0x1.C6B64p+24,
                                                    0x1.C9C38p+24}};

} // namespace

// Spectra.bas:798 (static initialiser of ENfrvar_lim(0 To 303)).
void load_enfrvar_lim(TableSet& tables) {
    tables.enfrvar_lim.redim({fb::Bounds{0, 303}});
    for (std::int64_t k = 0; k <= 303; ++k) {
        tables.enfrvar_lim(k) = enfrvar_lim_bits.at(static_cast<std::size_t>(k));
    }
}

// GEF.bas:1222 `ReDim Shared BEldmTF(0 To 203,0 To 136) As Single`, BEldmTF.bas:3-12.
// GEF.bas:1233 `ReDim Shared BEexp(...)`, BEexp.bas. GEF.bas:1244 `Redim Shared DEFOtab(0 To
// 236,0 To 136)`, DEFO.bas. GEF.bas:1255 `ReDim Shared ShellMO(...)`, ShellMO.bas.
// GEF.bas:1266 `ReDim Shared EVOD(...)`. ReDim zero-fills, as the BASIC arrays are.
void load_mass_tables(ProgramData const& data, fb::DataReader& reader, TableSet& tables) {
    tables.evod.redim({fb::Bounds{0, 203}, fb::Bounds{0, 136}});

    // BEldmTF.bas:3-12 `Restore MassData`, `Read BELDMTF(I,J)` for I=1..203, J=1..136.
    tables.beldm_tf.redim({fb::Bounds{0, 203}, fb::Bounds{0, 136}});
    reader.restore(data.label("MassData"));
    for (std::int64_t i = 1; i <= 203; ++i) {
        for (std::int64_t j = 1; j <= 136; ++j) {
            tables.beldm_tf(i, j) = reader.read_single();
        }
    }

    // BEexp.bas: zero-fill loop to -1.E11 (Single), then `Restore BEexpdata`; `Do Until Z<0`
    // reads Z,A and stores BEexp(A-Z,Z) when Z>=0.
    tables.be_exp.redim({fb::Bounds{0, 203}, fb::Bounds{0, 136}});
    for (std::int64_t i = 0; i <= 203; ++i) {
        for (std::int64_t j = 0; j <= 136; ++j) {
            tables.be_exp(i, j) = static_cast<float>(-1.0E11);
        }
    }
    reader.restore(data.label("BEexpdata"));
    std::int64_t z = 0;
    while (!(z < 0)) {
        z = reader.read_longint();
        std::int64_t const a = reader.read_longint();
        if (z >= 0) {
            tables.be_exp(fb::sub(a, z), z) = reader.read_single();
        }
    }

    // DEFO.bas: the Lbound/Ubound zero loop is what the redim already left (zero-filled); then
    // `Restore DEFOtabdata`; `Do Until Z<0` reads Z,N and DEFOtab(N,Z), Rnotused when Z>=0.
    tables.defo_tab.redim({fb::Bounds{0, 236}, fb::Bounds{0, 136}});
    reader.restore(data.label("DEFOtabdata"));
    z = 0;
    while (!(z < 0)) {
        z = reader.read_longint();
        std::int64_t const n = reader.read_longint();
        if (z >= 0) {
            tables.defo_tab(n, z) = reader.read_single();
            [[maybe_unused]] float const rnotused = reader.read_single();
        }
    }

    // ShellMO.bas:3-12 `Restore ShellData`, the same I/J loop as BEldmTF.
    tables.shell_mo.redim({fb::Bounds{0, 203}, fb::Bounds{0, 136}});
    reader.restore(data.label("ShellData"));
    for (std::int64_t i = 1; i <= 203; ++i) {
        for (std::int64_t j = 1; j <= 136; ++j) {
            tables.shell_mo(i, j) = reader.read_single();
        }
    }

    // ElmtNames.bas: `If CElement(1)<>"H" Then Restore ElementNames`, `Read CElement(I)` for
    // I=1..120. GEF.bas:1569 `Static Shared CElement(1 To 120) As String`.
    tables.c_element.redim({fb::Bounds{1, 120}});
    if (tables.c_element(1) != "H") {
        reader.restore(data.label("ElementNames"));
        for (std::int64_t i = 1; i <= 120; ++i) {
            tables.c_element(i) = reader.read_string();
        }
    }
}

} // namespace gef::data
