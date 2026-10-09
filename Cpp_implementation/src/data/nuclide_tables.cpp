// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The nuclide-data loaders (M4.3): NucTab, MAT_for_ISO and Isotab from the NucProp*.bas file
// that GEF includes for the selected variant. The variant files differ in their record layout,
// in the exit test of the main loop, in N_ISO_MAT and in the NUBASE 2020 loop structure; each
// difference is marked where it is ported.

#include "data/nuclide_tables.hpp"

#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"
#include "fbrt/data_reader.hpp"
#include "fbrt/text.hpp"

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace gef::data {

namespace {

// Per-variant differences of the loader. NucPropNUBASE2016.bas and NucPropNUBASE2020.bas have
// C_Lifetime in `Type NucProp`; JEFF33, JEFF311 and the legacy files do not.
// NucProp_Functions.mac (included by JEFF33 and NUBASE2016) bounds N_ISO_MAT to five isomers;
// NucPropJEFF311, NucPropx, NucPropmf and NucPropf define an unbounded N_ISO_MAT.
// The legacy files have `#DEFINE N_MAT_MAX <n>` and no count loop.
struct Layout {
    bool string_record;           // the record and the count loop end with C_Lifetime
    bool exit_at_111;             // `If NucTab(I_MAT).I_Z = 111 Then Exit Do` is active
    bool iso_bounded;             // N_ISO_MAT from NucProp_Functions.mac
    std::int64_t fixed_n_mat_max; // `#DEFINE N_MAT_MAX` of the legacy files; 0 = counted
    bool legacy_names;            // NucPropx/mf/f print "NucPropx"/"Nucpropx" in their messages
    bool i_iso_detail;            // JEFF33 also prints "    I_ISO out of range."
};

Layout layout_for(NuclideData variant) {
    switch (variant) {
    case NuclideData::Jeff33:
        return {.string_record = false,
                .exit_at_111 = false,
                .iso_bounded = true,
                .fixed_n_mat_max = 0,
                .legacy_names = false,
                .i_iso_detail = true};
    case NuclideData::Jeff311:
        return {.string_record = false,
                .exit_at_111 = true,
                .iso_bounded = false,
                .fixed_n_mat_max = 0,
                .legacy_names = false,
                .i_iso_detail = false};
    case NuclideData::Nubase2016:
        return {.string_record = true,
                .exit_at_111 = false,
                .iso_bounded = true,
                .fixed_n_mat_max = 0,
                .legacy_names = false,
                .i_iso_detail = false};
    case NuclideData::LegacyX:
        return {.string_record = false,
                .exit_at_111 = true,
                .iso_bounded = false,
                .fixed_n_mat_max = 3897,
                .legacy_names = true,
                .i_iso_detail = false};
    case NuclideData::LegacyMf:
        return {.string_record = false,
                .exit_at_111 = true,
                .iso_bounded = false,
                .fixed_n_mat_max = 3889,
                .legacy_names = true,
                .i_iso_detail = false};
    case NuclideData::LegacyF:
        return {.string_record = false,
                .exit_at_111 = true,
                .iso_bounded = false,
                .fixed_n_mat_max = 3885,
                .legacy_names = true,
                .i_iso_detail = false};
    case NuclideData::Nubase2020:
        break; // handled by load_nubase2020
    }
    return {.string_record = false,
            .exit_at_111 = false,
            .iso_bounded = true,
            .fixed_n_mat_max = 0,
            .legacy_names = false,
            .i_iso_detail = false};
}

// BASIC `Print` lines, formatted by fbrt PrintFile and split at the line ends: the console keeps
// one entry per printed line, without the line end.
void split_lines(std::string const& text, std::vector<std::string>& out) {
    std::size_t start = 0;
    while (start < text.size()) {
        std::size_t const end = text.find('\n', start);
        if (end == std::string::npos) {
            out.push_back(text.substr(start));
            break;
        }
        out.push_back(text.substr(start, end - start));
        start = end + 1;
    }
}

// `Print "<text>"`
void print_text(std::vector<std::string>& out, std::string_view text) {
    fb::PrintFile file;
    file.print(text, fb::PrintEnd::Newline);
    split_lines(file.text(), out);
}

// `Print "<prefix>";<Integer value>`
void print_with_value(std::vector<std::string>& out, std::string_view prefix, std::int64_t value) {
    fb::PrintFile file;
    file.print(prefix, fb::PrintEnd::None);
    file.print(value, fb::PrintEnd::Newline);
    split_lines(file.text(), out);
}

// One NucProp record as the main loop reads it: `Read NucTab(I_MAT).I_Z, …`.
struct Record {
    std::int64_t i_z = 0;
    std::int64_t i_a = 0;
    std::int64_t i_iso = 0;
    float r_spi = 0.0F;
    std::int64_t i_par = 0;
    double r_awr = 0.0;
    float r_exc = 0.0F;
    std::string c_lifetime;
};

// The count loop's `Read` of one record after its MAT number: 7 Single dummies, then the
// C_Lifetime string where the variant has one.
void skip_record_tail(fb::DataReader& reader, bool string_record) {
    for (int i = 1; i <= 7; ++i) {
        (void)reader.read_single();
    }
    if (string_record) {
        (void)reader.read_string();
    }
}

Record read_record(fb::DataReader& reader, bool string_record) {
    Record rec;
    rec.i_z = reader.read_longint();
    rec.i_a = reader.read_longint();
    rec.i_iso = reader.read_longint();
    rec.r_spi = reader.read_single();
    rec.i_par = reader.read_longint();
    rec.r_awr = reader.read_double();
    rec.r_exc = reader.read_single();
    if (string_record) {
        rec.c_lifetime = reader.read_string();
    }
    return rec;
}

// N_ISO_MAT (NucProp_Functions.mac:65-86): 0 when IMAT > UBound(NucTab); otherwise compares the
// entries IMAT..IMAT+5 with IMAT's Z and A. BASIC does not check the upper end of that loop; with
// the shipped tables it always leaves before NucTab ends (the last nuclides with isomers are
// followed by a different nuclide), and the bounds-checked access throws if a table ever made it
// read past the end.
std::int64_t n_iso_mat_bounded(fb::Array<NucProp, 1> const& nuc, std::int64_t /*n_mat_max*/,
                               std::int64_t imat) {
    if (imat > nuc.ubound(1)) { // NucProp_Functions.mac:69 `If IMAT <= UBound(NucTab) Then`
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
    return last - first - 1;
}

// N_ISO_MAT of NucPropJEFF311.bas, NucPropx.bas, NucPropmf.bas and NucPropf.bas: searches to the
// end of NucTab.
std::int64_t n_iso_mat_unbounded(fb::Array<NucProp, 1> const& nuc, std::int64_t n_mat_max,
                                 std::int64_t imat) {
    std::int64_t const first = imat;
    std::int64_t const iz = nuc(first).i_z;
    std::int64_t const ia = nuc(first).i_a;
    std::int64_t last = first;
    for (std::int64_t i = first + 1; i <= n_mat_max; ++i) {
        if (nuc(i).i_z != iz || nuc(i).i_a != ia) {
            break;
        }
        last = i;
    }
    return last - first;
}

// NucPropNUBASE2020.bas:24-30 `F_AWR`.
double f_awr(std::int64_t a, double m_excess) {
    double const m_neutron = 939.56542194; // MeV/c^2
    double const u = 931.4941372;          // MeV/c^2
    double const m_total = static_cast<double>(a) * u + m_excess;
    return m_total / m_neutron;
}

// The Isotab loop of the variant file (NucPropJEFF33.bas:133-177 and the same lines of the other
// variants): sorts the states of each nuclide by spin and sets the spin windows R_lim.
void build_isotab(TableSet& tables, Layout const& lay) {
    fb::Array<NucProp, 1> const& nuc = tables.nuc_tab;
    std::int64_t const n_mat_max = tables.n_mat_max;
    // Redim Shared Isotab(N_ISO_TOT) As Isoprop
    tables.isotab.redim({fb::Bounds{0, tables.n_iso_tot}});

    for (std::int64_t i1 = 1; i1 <= tables.n_iso_tot; ++i1) {
        IsoProp& iso = tables.isotab(i1);
        std::int64_t const mat = tables.mat_for_iso(i1);
        iso.i_mat = mat;
        iso.i_z = nuc(mat).i_z;
        iso.i_a = nuc(mat).i_a;
        std::int64_t const n_iso = lay.iso_bounded ? n_iso_mat_bounded(nuc, n_mat_max, iso.i_mat)
                                                   : n_iso_mat_unbounded(nuc, n_mat_max, iso.i_mat);
        iso.n_states = n_iso + 1; // Number of states

        // Sorting the spin in ascending order (Single loop R1, 0 To 50.0 Step 0.5)
        std::int64_t inmbr = 0;
        for (std::int64_t k = 0; k <= 100; ++k) {
            float const r1 = static_cast<float>(k) * 0.5F; // exact: multiples of 0.5 in Single
            for (std::int64_t j1 = 1; j1 <= iso.n_states; ++j1) {
                NucProp const& st = nuc(mat + j1 - 1);
                if (st.r_spi == r1) {
                    ++inmbr;
                    iso.i_iso(inmbr) = st.i_iso;
                    iso.r_spi(inmbr) = st.r_spi;
                    iso.i_par(inmbr) = st.i_par;
                    iso.r_exc(inmbr) = st.r_exc;
                }
            }
        }

        // Setting the limits of the angular-momentum distribution. The expression is evaluated
        // as fbc's C does (fbc_arithmetic: Single operands, Double intermediates, Single result).
        for (std::int64_t j1 = 1; j1 <= iso.n_states - 1; ++j1) {
            float const r_j_diff = iso.r_spi(j1 + 1) - iso.r_spi(j1);
            float const r_e_diff = iso.r_exc(j1 + 1) - iso.r_exc(j1);
            auto const ratio =
                static_cast<float>(static_cast<double>(r_e_diff) / static_cast<double>(r_j_diff));
            double const term =
                (static_cast<double>(ratio) / (static_cast<double>(std::fabs(ratio)) + 0.05)) *
                    0.5 +
                0.5;
            auto const r_j_1 = static_cast<float>(static_cast<double>(r_j_diff) * term);
            iso.r_lim(j1) = iso.r_spi(j1) + r_j_1;

            if (iso.r_spi(j1 + 1) == iso.r_spi(j1)) {
                iso.r_lim(j1) = 1.E3F;
            }
        }
        iso.r_lim(iso.n_states) = 1.E3F;
    }
}

// I_ISO outside 0..9 (NucPropJEFF33.bas:78-81 and the variants' I_ISO blocks): Print, Sleep, no
// End, so the program goes on.
// QUIRK(Q-033): prints "GEF stopped." and continues
void print_i_iso_error(std::vector<std::string>& out, Layout const& lay, std::int64_t i_iso) {
    if (i_iso >= 0 && i_iso <= 9) {
        return;
    }
    print_text(out, lay.legacy_names ? "<E> Error in NucPropx" : "<E> Error in NucProp");
    if (lay.i_iso_detail) {
        print_text(out, "    I_ISO out of range.");
    }
    print_text(out, "GEF stopped.");
}

// Post-loop `If I_MAT < N_MAT_MAX Then Print "<E> Nucprop: N_MAT_MAX too large, should be ";I_MAT`.
// QUIRK(Q-034): fires for JEFF-3.1.1, whose reading loop leaves at the first Z = 111 record
void print_too_large(std::vector<std::string>& out, Layout const& lay, std::int64_t i_mat,
                     std::int64_t n_mat_max) {
    if (i_mat >= n_mat_max) {
        return;
    }
    print_with_value(out,
                     lay.legacy_names ? "<E> Nucpropx: N_MAT_MAX too large, should be "
                                      : "<E> Nucprop: N_MAT_MAX too large, should be ",
                     i_mat);
}

// The NucPropJEFF33/JEFF311/NUBASE2016/x/mf/f loader: the count loop, the main loop over the
// records, the MAT_for_ISO list and the Isotab.
void load_plain(ProgramData const& data, fb::DataReader& reader, TableSet& tables) {
    Layout const lay = layout_for(data.variant());

    // Determine N_MAT_MAX (number of states in table NuclideData). The legacy files have
    // `#DEFINE N_MAT_MAX` (NucPropx.bas:6, NucPropmf.bas:13, NucPropf.bas:10) and no count loop.
    std::int64_t n_mat_max = lay.fixed_n_mat_max;
    if (n_mat_max == 0) {
        for (;;) {
            std::int64_t const i_mat_original = reader.read_longint();
            if (i_mat_original == 9999) {
                break;
            }
            ++n_mat_max;
            skip_record_tail(reader, lay.string_record);
        }
    }
    tables.n_mat_max = n_mat_max;
    tables.nuc_tab.redim({fb::Bounds{0, n_mat_max}});
    fb::Array<std::int64_t, 1> mat_for_iso_prov;
    mat_for_iso_prov.redim({fb::Bounds{0, n_mat_max}});

    // Restore NuclideData; Do Until I_MAT = N_MAT_MAX
    reader.restore(data.label("NuclideData"));
    std::int64_t i_mat = 0;
    std::int64_t n_iso_tot = 0;
    while (i_mat != n_mat_max) {
        // Read nuclide properties into UDT NucTab
        (void)reader.read_longint(); // I_MAT_original
        i_mat = i_mat + 1;
        // Main-loop `If I_MAT > N_MAT_MAX Then Print "<E> NucPropx: N_MAT_MAX too small!"`
        // (NucPropJEFF33.bas:69). It cannot fire here: the loop exits on equality.
        if (i_mat > n_mat_max) {
            print_text(tables.console, "<E> NucPropx: N_MAT_MAX too small!");
        }
        Record const rec = read_record(reader, lay.string_record);
        NucProp& nuc = tables.nuc_tab(i_mat);
        nuc.i_z = rec.i_z;
        nuc.i_a = rec.i_a;
        nuc.i_iso = rec.i_iso;
        nuc.r_spi = rec.r_spi;
        nuc.i_par = rec.i_par;
        nuc.r_awr = rec.r_awr;
        nuc.r_exc = rec.r_exc;
        nuc.c_lifetime = rec.c_lifetime;
        // I_ISO block (NucPropJEFF33.bas:78-81): Print, Sleep, no End. The program goes on, so the
        // loop does too (the R_SPI clamp and the Exit Do test below still run).
        print_i_iso_error(tables.console, lay, nuc.i_iso);
        if (nuc.r_spi < 0.0F || nuc.r_spi > 1.E3F) {
            nuc.r_spi = 0.0F;
        }
        if (nuc.i_iso == 1) { // At least one isomeric state is in NucTab
            ++n_iso_tot;
            mat_for_iso_prov(n_iso_tot) = i_mat - 1;
        }
        if (lay.exit_at_111 && nuc.i_z == 111) {
            break;
        }
    }

    // Post-loop: If I_MAT < N_MAT_MAX Then Print "<E> Nucprop: N_MAT_MAX too large, should be
    // ";I_MAT
    print_too_large(tables.console, lay, i_mat, n_mat_max);

    tables.n_iso_tot = n_iso_tot;
    // Redim Shared MAT_for_ISO(N_ISO_TOT) As Integer
    tables.mat_for_iso.redim({fb::Bounds{0, n_iso_tot}});
    for (std::int64_t i1 = 1; i1 <= n_iso_tot; ++i1) {
        tables.mat_for_iso(i1) = mat_for_iso_prov(i1);
    }

    build_isotab(tables, lay);
}

// NucPropNUBASE2020.bas:56-109 and 200-end. The main loop's `For I_MAT = 1 To N_MAT_MAX`
// (line 95) runs in every pass and leaves I_MAT = N_MAT_MAX + 1, so the `Do Until` test on line 76
// never fires and each further record is read into NucTab past its end. The loop therefore ends
// only at the first record whose I_ISO is outside 0..9 (lines 89-94), which prints the stop
// lines and ends the program. The port keeps the record read in locals, skips the stores past
// the array end (they are unobservable: the program stops), and throws GefStopped there.
// QUIRK(Q-032): the misplaced R_AWR loop makes the reading loop run past N_MAT_MAX until GEF stops
void load_nubase2020(ProgramData const& data, fb::DataReader& reader, TableSet& tables) {
    // Determine N_MAT_MAX (number of states in table NuclideData): records of 8 values
    std::int64_t n_mat_max = 0;
    for (;;) {
        std::int64_t const i_mat_original = reader.read_longint();
        if (i_mat_original == 9999) {
            break;
        }
        ++n_mat_max;
        skip_record_tail(reader, true);
    }
    tables.n_mat_max = n_mat_max;
    tables.nuc_tab.redim({fb::Bounds{0, n_mat_max}});

    // Restore NuclideData
    reader.restore(data.label("NuclideData"));
    std::vector<std::string> lines;
    std::int64_t i_mat = 0;
    for (;;) {
        // Read I_MAT_original; I_MAT = I_MAT + 1
        (void)reader.read_longint();
        i_mat = i_mat + 1;
        // `<E> NucPropx: N_MAT_MAX too small!` (line 80) after the first overshoot
        if (i_mat > n_mat_max) {
            print_text(lines, "<E> NucPropx: N_MAT_MAX too small!");
        }
        // Read NucTab(I_MAT).I_Z … C_Lifetime (lines 81-88): R_Excess is read as Double, and
        // R_AWR is then computed from it (line 96-98)
        std::int64_t const i_z = reader.read_longint();
        std::int64_t const i_a = reader.read_longint();
        std::int64_t const i_iso = reader.read_longint();
        float const r_spi = reader.read_single();
        std::int64_t const i_par = reader.read_longint();
        double const r_excess = reader.read_double();
        float const r_exc = reader.read_single();
        std::string const c_lifetime = reader.read_string();
        if (i_mat <= n_mat_max) {
            NucProp& nuc = tables.nuc_tab(i_mat);
            nuc.i_z = i_z;
            nuc.i_a = i_a;
            nuc.i_iso = i_iso;
            nuc.r_spi = r_spi;
            nuc.i_par = i_par;
            nuc.r_excess = r_excess;
            nuc.r_exc = r_exc;
            nuc.c_lifetime = c_lifetime;
        }
        if (i_iso < 0 || i_iso > 9) {
            print_text(lines, "<E> Error in NucProp");
            print_text(lines, "GEF stopped.");
            throw GefStopped(lines);
        }
        // For I_MAT = 1 To N_MAT_MAX: R_AWR = F_AWR(I_A, R_Excess); leaves I_MAT = N_MAT_MAX + 1
        for (std::int64_t k = 1; k <= n_mat_max; ++k) {
            NucProp& nuc = tables.nuc_tab(k);
            nuc.r_awr = f_awr(nuc.i_a, nuc.r_excess);
        }
        i_mat = n_mat_max + 1;
    }
}

} // namespace

void load_nuclide_tables(ProgramData const& data, TableSet& tables) {
    fb::DataReader reader(data.items());
    if (data.variant() == NuclideData::Nubase2020) {
        load_nubase2020(data, reader, tables);
    } else {
        load_plain(data, reader, tables);
    }
}

} // namespace gef::data
