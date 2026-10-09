// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "data/lookups.hpp"

#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "fbrt/input.hpp"
#include "fbrt/text.hpp"

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace gef::data {

namespace {

using fb::PrintEnd;
using fb::PrintFile;

// Which file defines the lookups.
enum class Form : std::uint8_t {
    Mac,     // NucProp_Functions.mac: JEFF33, NUBASE2016, NUBASE2020
    Jeff311, // NucPropJEFF311.bas:180-258
    Legacy,  // NucPropx.bas:157-224, NucPropmf.bas:165-232, NucPropf.bas:162-229
};

Form form_of(NuclideData variant) {
    switch (variant) {
    case NuclideData::Jeff311:
        return Form::Jeff311;
    case NuclideData::LegacyX:
    case NuclideData::LegacyMf:
    case NuclideData::LegacyF:
        return Form::Legacy;
    case NuclideData::Jeff33:
    case NuclideData::Nubase2016:
    case NuclideData::Nubase2020:
        break;
    }
    return Form::Mac;
}

// The lines one or more BASIC Print statements wrote to the console, without line ends.
void append_lines(std::vector<std::string>& console, PrintFile const& file) {
    std::string const& text = file.text();
    std::size_t start = 0;
    while (start < text.size()) {
        std::size_t const end = text.find('\n', start);
        if (end == std::string::npos) {
            console.push_back(text.substr(start));
            break;
        }
        console.push_back(text.substr(start, end - start));
        start = end + 1;
    }
}

// NucProp_Functions.mac:31-35 and NucPropJEFF311.bas:189-193.
void print_missing(std::vector<std::string>& console, std::int64_t iz, std::int64_t ia) {
    PrintFile out;
    out.print("<W> NucProb.bas: Missing MAT number in NucTab for Z,A = ", PrintEnd::None);
    out.print(iz, PrintEnd::None);
    out.print(",", PrintEnd::None);
    out.print(ia, PrintEnd::Newline);
    out.print("    Information on nuclear properties is not available.", PrintEnd::Newline);
    out.print("    Please extend table!", PrintEnd::Newline);
    out.print("    (Note that this message is shown only once for the first case",
              PrintEnd::Newline);
    out.print("     encountered in one GEF session!)", PrintEnd::Newline);
    append_lines(console, out);
}

// NucProp_Functions.mac:11-63.
std::int64_t i_mat_endf_mac(TableSet const& tables, std::int64_t iz, std::int64_t ia,
                            MatNumberState& state, std::vector<std::string>& console) {
    fb::Array<NucProp, 1> const& nuc = tables.nuc_tab;
    std::int64_t imat = 0;
    for (std::int64_t i = nuc.lbound(); i <= nuc.ubound(); ++i) {
        if (iz == nuc(i).i_z && ia == nuc(i).i_a) { // Nucleus already in NucTab
            imat = i;
            break;
        }
    }
    std::int64_t imat_max = nuc.ubound();
    // QUIRK(Q-021): a nuclide outside NucTab (and Z = A = 0, found at index 0) gets a MAT
    // number from ctl/IMATmax.ctl, which keeps it for later calls and runs.
    if (imat == 0) {
        if (!state.message_shown) {
            print_missing(console, iz, ia);
        }
        // CHDIR("ctl"); Fileexists(CFmat): read the dynamic extension list
        if (state.imatmax_ctl) {
            fb::InputFile file{*state.imatmax_ctl};
            for (;;) { // Do … Loop Until EOF(Fmat): one record even from an empty file
                std::int64_t const iz_in = file.input_longint();
                std::int64_t const ia_in = file.input_longint();
                std::int64_t const imat_in = file.input_longint();
                if (iz_in == iz && ia_in == ia) { // Nucleus already in dynamic extension list
                    imat = imat_in;
                }
                // `Max` is GEF's Single function (GEF.c: MAX((float)…, (float)…), fb_F2L)
                imat_max =
                    fb::f2l(fb::max(static_cast<float>(imat_max), static_cast<float>(imat_in)));
                if (file.eof()) {
                    break;
                }
            }
        }
        if (imat == 0) { // Add to dynamic extension list
            imat = imat_max + 1;
            PrintFile out;
            out.print("<I> IMAT =", PrintEnd::None);
            out.print(imat, PrintEnd::None);
            out.print(" assigned to Z =", PrintEnd::None);
            out.print(iz, PrintEnd::None);
            out.print(", A =", PrintEnd::None);
            out.print(ia, PrintEnd::Newline);
            append_lines(console, out);
            // Open CFmat For Append: Print #Fmat, IZ, IA, IMAT (a new file starts at column 1)
            PrintFile record;
            record.print(iz, PrintEnd::Pad);
            record.print(ia, PrintEnd::Pad);
            record.print(imat, PrintEnd::Newline);
            state.imatmax_ctl = state.imatmax_ctl.value_or(std::string{}) + record.text();
        }
        // CHDIR("..")
        state.message_shown = true;
    }
    return imat;
}

// NucPropJEFF311.bas:180-200: 0 for a nuclide outside NucTab.
std::int64_t i_mat_endf_jeff311(TableSet const& tables, std::int64_t iz, std::int64_t ia,
                                MatNumberState& state, std::vector<std::string>& console) {
    fb::Array<NucProp, 1> const& nuc = tables.nuc_tab;
    std::int64_t i = nuc.lbound();
    std::int64_t imat = 0;
    for (; i <= nuc.ubound(); ++i) {
        imat = i;
        if (iz == nuc(imat).i_z && ia == nuc(imat).i_a) {
            break;
        }
    }
    if (i > nuc.ubound()) {
        if (!state.message_shown) {
            print_missing(console, iz, ia);
        }
        imat = 0;
        state.message_shown = true;
    }
    return imat;
}

// NucPropx.bas:157-165, NucPropmf.bas:165-173, NucPropf.bas:162-170.
// QUIRK(Q-036): a nuclide outside NucTab gets the loop variable's last value, UBound(NucTab);
// no message.
std::int64_t i_mat_endf_legacy(TableSet const& tables, std::int64_t iz, std::int64_t ia) {
    fb::Array<NucProp, 1> const& nuc = tables.nuc_tab;
    std::int64_t imat = 0;
    for (std::int64_t i = nuc.lbound(); i <= nuc.ubound(); ++i) {
        imat = i;
        if (iz == nuc(imat).i_z && ia == nuc(imat).i_a) {
            break;
        }
    }
    return imat;
}

} // namespace

std::int64_t i_mat_endf(TableSet const& tables, std::int64_t iz, std::int64_t ia,
                        MatNumberState& state, std::vector<std::string>& console) {
    switch (form_of(tables.variant)) {
    case Form::Jeff311:
        return i_mat_endf_jeff311(tables, iz, ia, state, console);
    case Form::Legacy:
        return i_mat_endf_legacy(tables, iz, ia);
    case Form::Mac:
        break;
    }
    return i_mat_endf_mac(tables, iz, ia, state, console);
}

std::int64_t n_iso_mat(TableSet const& tables, std::int64_t imat) {
    fb::Array<NucProp, 1> const& nuc = tables.nuc_tab;
    if (form_of(tables.variant) == Form::Mac) {
        // NucProp_Functions.mac:65-85: 0 when IMAT > UBound(NucTab); otherwise compares the
        // entries IMAT..IMAT+5 with IMAT's Z and A. BASIC does not check the upper end of that
        // loop: for IMAT > UBound(NucTab) - 6 it may read past NucTab (undefined in BASIC);
        // the bounds-checked access throws there.
        if (imat > nuc.ubound()) {
            return 0;
        }
        std::int64_t const first = imat;
        std::int64_t const iz = nuc(first).i_z;
        std::int64_t const ia = nuc(first).i_a;
        std::int64_t last = first;
        for (std::int64_t i = first; i <= first + 5; ++i) {
            last = i;
            if (nuc(i).i_z != iz || nuc(i).i_a != ia) {
                break;
            }
        }
        return last - first - 1; // number of isomeric states found
    }
    // NucPropJEFF311.bas:202-215, NucPropx.bas:167-180 (and mf, f): searches up to N_MAT_MAX.
    std::int64_t const first = imat;
    std::int64_t const iz = nuc(first).i_z;
    std::int64_t const ia = nuc(first).i_a;
    std::int64_t last = first;
    for (std::int64_t i = first + 1; i <= tables.n_mat_max; ++i) {
        if (nuc(i).i_z != iz || nuc(i).i_a != ia) {
            break;
        }
        last = i;
    }
    return last - first;
}

float r_awr_endf(TableSet const& tables, std::int64_t iz, std::int64_t ia, MatNumberState& state,
                 std::vector<std::string>& console) {
    std::int64_t const imat = i_mat_endf(tables, iz, ia, state, console);
    if (form_of(tables.variant) == Form::Mac) {
        // NucProp_Functions.mac:87-97
        if (imat <= tables.nuc_tab.ubound()) {
            return static_cast<float>(tables.nuc_tab(imat).r_awr);
        }
        return 0.0F;
    }
    // NucPropJEFF311.bas:217-223, NucPropx.bas:182-188: no bounds check (I_MAT_ENDF returns an
    // index of NucTab there); the dead `If IMAT > UBound(NucTab)` before the call is skipped.
    return static_cast<float>(tables.nuc_tab(imat).r_awr);
}

// NucProp_Functions.mac:99-107 (the same in every variant). The function result starts at 0.
std::int64_t iso_for_mat(TableSet const& tables, std::int64_t imat) {
    for (std::int64_t i = 1; i <= tables.n_iso_tot; ++i) {
        if (imat == tables.mat_for_iso(i)) {
            return i;
        }
    }
    return 0;
}

// NucProp_Functions.mac:109-120 (the same in every variant).
std::int64_t iso_for_za(TableSet const& tables, std::int64_t iz, std::int64_t ia) {
    for (std::int64_t i = 1; i <= tables.n_iso_tot; ++i) {
        if (tables.isotab(i).i_z == iz && tables.isotab(i).i_a == ia) {
            return i;
        }
    }
    return 0;
}

// NucProp_Functions.mac:122-133 (the same in every variant).
std::int64_t nstates_for_za(TableSet const& tables, std::int64_t iz, std::int64_t ia) {
    for (std::int64_t i = 1; i <= tables.n_iso_tot; ++i) {
        if (tables.isotab(i).i_z == iz && tables.isotab(i).i_a == ia) {
            return tables.isotab(i).n_states;
        }
    }
    return 1;
}

// DCLbranchingJEFF33.bas:146-169. IAfound keeps the A of the last record of element IZ before
// the match (0 if there is none); every record up to UBound(BranchData) is searched, including
// the empty ones past Ra-234 (Q-017).
std::int64_t ibranch_for_zai(TableSet const& tables, std::int64_t iz, std::int64_t ia,
                             std::int64_t iso) {
    fb::Array<BranchRecord, 1> const& branch = tables.branch_data;
    std::int64_t inmbr = 0; // Default
    std::int64_t ia_found = 0;
    for (std::int64_t i = 1; i <= branch.ubound(); ++i) {
        if (iz == branch(i).i_z) {
            ia_found = branch(i).i_a;
        }
        if (iz == branch(i).i_z && ia == branch(i).i_a && iso == branch(i).i_iso) {
            inmbr = i;
            break;
        }
    }
    if (inmbr == 0) { // state in nucleus not found
        // no default decay branch outside the Z range
        if (iz >= tables.z_min_branching && iz <= tables.z_max_branching) {
            if (ia < ia_found) {
                inmbr = -1; // beta-plus decay assumed
            }
            if (ia > ia_found) {
                inmbr = -2; // beta-minus decay assumed
            }
        }
    }
    return inmbr;
}

} // namespace gef::data
