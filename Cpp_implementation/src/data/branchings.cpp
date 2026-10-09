// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// Branchings.bas (the BranchData and INlast loader) over DCLbranchingJEFF33.bas.
#include "data/table_loaders.hpp"
#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"
#include "fbrt/text.hpp"

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

namespace gef::data {

using fb::PrintEnd;
using fb::PrintFile;

namespace {

// `x * 0.01` on a Single: the C emission computes (float)((double)x * 0.01).
[[nodiscard]] float percent(float x) noexcept {
    return static_cast<float>(static_cast<double>(x) * 0.01);
}

// Appends the lines one BASIC Print statement wrote, as PrintFile formatted them.
void append_print(std::vector<std::string>& console, PrintFile const& file) {
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

// Branchings.bas:197-213 `Select Case unit`: sets r_unit for each case (Single, as the C stores
// it). `Case Else` (Branchings.bas:214) leaves r_unit unchanged, as BASIC does.
void time_unit(std::string const& unit, float& r_unit, std::vector<std::string>& console,
               std::int64_t i_branch) {
    if (unit == "ns") {
        r_unit = 0x1.12E0BEp-30F; // 1.E-9
    } else if (unit == "ms") {
        r_unit = 0x1.0624DEp-10F; // 1.E-3
    } else if (unit == "s") {
        r_unit = 0x1.p+0F; // 1
    } else if (unit == "min") {
        r_unit = 0x1.Ep+5F; // 60
    } else if (unit == "h") {
        r_unit = 0x1.C2p+11F; // 3600
    } else if (unit == "d") {
        r_unit = 0x1.518p+16F; // 3600 * 24
    } else if (unit == "y") {
        r_unit = 0x1.E1853Ep+24F; // 3600 * 24 * 365.2422
    } else if (unit == "stable") {
        r_unit = 0x1.5AF1D8p+66F; // 1.E20
    } else {
        // Branchings.bas:214-216: `Case Else` prints a warning and Sleeps without End.
        PrintFile file;
        file.print("Error in time unit ", PrintEnd::None);
        file.print(unit, PrintEnd::None);
        file.print(" ", PrintEnd::None);
        file.print(i_branch, PrintEnd::Newline);
        append_print(console, file);
    }
}

} // namespace

// DCLbranchingJEFF33.bas:6-8 `Dim Shared As Integer Z_min_branching = 20`, Z_max = 88,
// A_max = 234. DCLbranchingJEFF33.bas:106 `Redim Shared BranchData(3425)`,
// DCLbranchingJEFF33.bas:4611 `Redim Shared As Integer INlast(90)`.
// Branchings.bas:44-252: the loader. Its Print/Sleep statements that do not end the program
// (Branchings.bas:76-80 bad I_ISO, :214-216 unknown unit, :233-237 table too small) are not
// reproduced: they only print, and BASIC continues after Sleep.
void load_branchings(ProgramData const& data, fb::DataReader& reader, TableSet& tables) {
    tables.z_min_branching = 20;
    tables.z_max_branching = 88;
    tables.a_max_branching = 234;
    tables.branch_data.redim({fb::Bounds{0, 3425}});
    tables.in_last.redim({fb::Bounds{0, 90}});

    // Branchings.bas:44-57 (Scope): the locals. Their values persist across the loop, so they
    // are declared here (zero-initialised, as Dim As does).
    std::int64_t i_branch = 0;
    float rtot_beta = 0;
    float rtot_beta_plus = 0;
    float rtot_beta_m = 0;
    float rtot_beta_plus_m = 0;
    float beta_np = 0;
    float beta_2np = 0;
    float t = 0;
    float r_unit = 0;
    std::string unit;
    std::int64_t i_work = 0;

    // Branchings.bas:61-64 `Restore BranchTable`, `Do`, `Read I_Work`. A positive I_Work starts
    // a new record; a non-positive one (an isomer decay) updates the current record.
    reader.restore(data.label("BranchTable"));
    for (;;) {
        i_work = reader.read_longint();
        if (i_work > 0) {
            i_branch = fb::add(i_branch, std::int64_t{1});
        }
        BranchRecord& rec = tables.branch_data(i_branch);
        rec.i_z = fb::abs(i_work);
        rec.i_a = reader.read_longint();
        rec.i_iso = reader.read_longint();

        // Branchings.bas:76-80: an I_ISO outside 0..9 prints a warning and Sleeps without End,
        // so loading continues.
        // QUIRK(Q-033): prints "GEF stopped." and continues
        if (rec.i_iso < 0 || rec.i_iso > 9) {
            PrintFile file;
            file.print("<E> Error in branching table: I_ISO, nmbr ", PrintEnd::Pad);
            file.print(rec.i_iso, PrintEnd::Pad);
            file.print(i_branch, PrintEnd::Newline);
            file.print("GEF stopped.", PrintEnd::Newline);
            append_print(tables.console, file);
        }

        // Branchings.bas:86-87: Read t, Read unit (both branches).
        t = reader.read_single();
        unit = reader.read_string();

        if (i_work > 0) {
            // Branchings.bas:91-125: the positive-I_Work branch.
            rtot_beta = percent(reader.read_single());
            rtot_beta_plus = percent(reader.read_single());
            beta_np = percent(reader.read_single());
            beta_2np = percent(reader.read_single());
            if (rtot_beta > 0) {
                rec.r_beta_n = beta_np;
                rec.r_beta_2n = beta_2np;
            }
            if (rtot_beta_plus > 0) {
                rec.r_beta_p = beta_np;
                rec.r_beta_2p = beta_2np;
            }
            rec.r_beta = (rtot_beta - rec.r_beta_n) - rec.r_beta_2n;
            rec.r_beta_plus = (rtot_beta_plus - rec.r_beta_p) - rec.r_beta_2p;
            rec.r_it = percent(reader.read_single());
            rec.r_alpha = percent(reader.read_single());
        } else {
            // Branchings.bas:127-158: the m-block. Its `If I_m = 1` guard is commented out, so
            // it runs for every I_Work <= 0 record. I_m itself is never read: not modelled.
            rtot_beta_m = percent(reader.read_single());
            rtot_beta_plus_m = percent(reader.read_single());
            beta_np = percent(reader.read_single());
            beta_2np = percent(reader.read_single());
            if (rtot_beta_m > 0) {
                rec.r_beta_n_m = beta_np;
                rec.r_beta_2n_m = beta_2np;
            }
            if (rtot_beta_plus_m > 0) {
                rec.r_beta_p_m = beta_np;
                rec.r_beta_2p_m = beta_2np;
            }
            rec.r_beta_m = (rtot_beta_m - rec.r_beta_n_m) - rec.r_beta_2n_m;
            rec.r_beta_plus_m = (rtot_beta_plus_m - rec.r_beta_p_m) - rec.r_beta_2p_m;
            rec.r_it_m = percent(reader.read_single());
            rec.r_alpha_m = reader.read_single();
            // Branchings.bas:158
            // QUIRK(Q-015): writes R_alpha from R_alpha_m (R_alpha_m is offset 88, R_alpha is
            // offset 56; the _mm block that would fill R_alpha_mm is disabled).
            rec.r_alpha = percent(rec.r_alpha_m);
        }

        // Branchings.bas:197-216 unit switch, then Branchings.bas:218 R_life = t * r_unit.
        time_unit(unit, r_unit, tables.console, i_branch);
        rec.r_life = t * r_unit;

        // Branchings.bas:225-229
        // QUIRK(Q-017): loading stops at Ra-234; the rows for Z = 89-111 are never read
        if (rec.i_z == 88 && rec.i_a == 234) {
            break;
        }
    }

    // Branchings.bas:233-237: `If Alarm` is nonzero (-1) unless the table end was reached. The
    // BASIC prints a warning and Sleeps without End, so loading continues.

    // Branchings.bas:240-248 `Restore EndA:`, `Read IA`, `INlast(IZ) = IA - IZ` for IZ=1..90.
    reader.restore(data.label("EndA"));
    for (std::int64_t iz = 1; iz <= 90; ++iz) {
        std::int64_t const ia = reader.read_longint();
        tables.in_last(iz) = fb::sub(ia, iz);
    }
}

} // namespace gef::data
