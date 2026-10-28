// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The round set-up at Nextfitloop (GEF.bas:2555, 2575-2624) and the system set-up of one pass of
// `For I_Double_Covar` (GEF.bas:3313-3440), from the C fbc emits (GEF.c:37546-37694,
// 41358-42368; FitparRead.bas through params::fitpar_read).

#include "data/table_memory.hpp"
#include "data/tables.hpp"
#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "fbrt/strings.hpp"
#include "fbrt/text.hpp"
#include "params/parameter_files.hpp"
#include "params/parameters.hpp"
#include "physics/barriers.hpp"
#include "physics/masses.hpp"
#include "run/run_util.hpp"
#include "run/setup.hpp"

#include <cmath>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <vector>

namespace gef::run {
namespace {

using fb::PrintEnd;

// GEF.bas:3370, 3373, 3377: `AME2020(P_Z_CN, P_A_CN-1) - AME2020(P_Z_CN, P_A_CN)`, the two masses
// evaluated in this order as the emitted C does.
float neutron_separation(data::TableSet const& tables, std::int64_t z, std::int64_t a) {
    float const target = physics::ame2020(tables, z, fb::sub(a, std::int64_t{1}));
    float const cn = physics::ame2020(tables, z, a);
    return target - cn;
}

// `"GEF_" + Trim(Str(Z)) + "_" + Trim(Str(A))` (GEF.bas:3395, 3398, 3401).
std::string gef_name(std::int64_t z, std::int64_t a) {
    return "GEF_" + fb::trim(fb::str(z)) + "_" + fb::trim(fb::str(a));
}

// GEF.bas:3346-3360: the barriers of the CN, and BFC (3354-3355) for Z 90 to 98.
void print_barriers(ProcessState& process) {
    fb::PrintFile& console = process.console;
    data::TableSet const& tables = *process.tables;
    std::int64_t const z = process.p_z_cn;
    auto const zf = static_cast<float>(z);
    auto const af = static_cast<float>(process.p_a_cn);

    // GEF.bas:3346-3348
    print_line(process, " ");
    print_part(process, "Fission barrier of CN (Z =");
    console.print(z, PrintEnd::None);
    print_part(process, ", A =");
    console.print(process.p_a_cn, PrintEnd::None);
    print_line(process, "):");
    print_part(process, "Macrosc. barrier (Thomas-Fermi) = ");
    console.print(fb::round(barrier_value(physics::bftf(tables, zf, af, 0)), 3), PrintEnd::None);
    print_line(process, " MeV");

    // GEF.bas:3350. The C jumps to the Else branch when `BFTFA - BFTFB >= 2`, so a NaN difference
    // takes the Then branch.
    float const inner = barrier_value(physics::bftfa(tables, zf, af, 1));
    float const outer = barrier_value(physics::bftfb(tables, zf, af, 1));
    if (inner - outer >= 2.0F) {
        // GEF.bas:3359
        print_part(process, "Fission-barrier height =");
        console.print(fb::round(barrier_value(physics::bftf(tables, zf, af, 1)), 3),
                      PrintEnd::None);
        print_line(process, " MeV");
        return;
    }
    // GEF.bas:3351-3352
    print_part(process, "Inner saddle =");
    console.print(fb::round(barrier_value(physics::bftfa(tables, zf, af, 1)), 3), PrintEnd::None);
    print_part(process, " MeV, second saddle =");
    console.print(fb::round(barrier_value(physics::bftfb(tables, zf, af, 1)), 3), PrintEnd::None);
    print_line(process, " MeV");
    // GEF.bas:3353
    if (z < 90 || z > 98) {
        return;
    }
    // GEF.bas:3354, as emitted: (BFTFB + BFTFB) - BFTFA, the three calls in this order.
    float const second_1 = barrier_value(physics::bftfb(tables, zf, af, 1));
    float const second_2 = barrier_value(physics::bftfb(tables, zf, af, 1));
    float const first = barrier_value(physics::bftfa(tables, zf, af, 1));
    process.params.bfc = (second_1 + second_2) - first;
    // GEF.bas:3355
    if (z >= 92) {
        double const square = std::pow(static_cast<double>(fb::add(z, std::int64_t{-92})), 0x1.p+1);
        process.params.bfc = static_cast<float>(static_cast<double>(process.params.bfc) -
                                                (square * 0x1.3333333333333p-2));
    }
    // GEF.bas:3356
    print_part(process, "Third saddle (estimated) = ");
    console.print(fb::round(process.params.bfc, 3), PrintEnd::Newline);
}

// GEF.bas:3361-3375: masses, shell effects and separation energies of the CN.
void print_masses(ProcessState& process) {
    fb::PrintFile& console = process.console;
    data::TableSet const& tables = *process.tables;
    std::int64_t const z = process.p_z_cn;
    std::int64_t const a = process.p_a_cn;
    auto const zf = static_cast<float>(z);
    auto const af = static_cast<float>(a);
    // GEF.bas:3361 and 3368 `If BEexp(P_A_CN-P_Z_CN, P_Z_CN) > -1.E10`: the C jumps to the Else
    // branch when the entry is `<= -1.E10`, so a NaN entry takes the experimental branch.
    // QUIRK(Q-042): reads outside the table return the memory next to it (data/table_memory).
    bool const experimental =
        !(static_cast<double>(data::read_mass_table(tables, data::MassTable::BeExp, fb::sub(a, z),
                                                    z)) <= -0x1.2A05F2p+33);

    // GEF.bas:3361-3365
    print_part(process, experimental ? "exp. Mass = " : "Mass = ");
    console.print(physics::ame2020(tables, z, a), PrintEnd::None);
    print_line(process, " MeV");
    // GEF.bas:3366
    print_part(process, "Lymass    = ");
    console.print(physics::ly_mass(zf, af, 0.0F), PrintEnd::None);
    print_line(process, " MeV");
    // GEF.bas:3367
    print_part(process, "G.S.Shell effect (Moeller) = ");
    console.print(fb::round(physics::u_shell(tables, z, a), 3), PrintEnd::None);
    print_part(process, " MeV, ");
    // GEF.bas:3368-3374
    print_part(process, experimental ? "G.S.Shell effect (exp,TF) = " : "G.S.Shell effect = ");
    console.print(fb::round(physics::u_shell_exp(tables, z, a), 3), PrintEnd::None);
    print_line(process, " MeV");
    print_part(process, experimental ? "S_n(exp.) = " : "S_n = ");
    console.print(neutron_separation(tables, z, a), PrintEnd::None);
    print_line(process, " MeV");
    // GEF.bas:3375
    print_part(process, "S_n(Lymass) = ");
    float const ly_target =
        physics::ly_mass(zf, static_cast<float>(fb::sub(a, std::int64_t{1})), 0.0F);
    float const ly_cn = physics::ly_mass(zf, af, 0.0F);
    console.print(ly_target - ly_cn, PrintEnd::None);
    print_line(process, " MeV");
}

// GEF.bas:3396-3428: the name of the output file, set at the first (or only) system of a line.
void name_output_file(ProcessState& process, SequenceFileState const& file) {
    std::int64_t const emode = process.params.emode;
    // GEF.bas:3397-3403
    if (process.b_double_covar == 0) {
        process.cfileout = gef_name(process.p_z_cn, process.p_a_cn);
    } else {
        process.cfileout = gef_name(process.p_z_cn, process.p_a_cn) + "+" +
                           fb::trim(fb::str(process.p_z_cn_double)) + "_" +
                           fb::trim(fb::str(process.p_a_cn_double));
    }
    // GEF.bas:3404-3407
    if (process.i_e_iso > 0) {
        if (fb::abs(emode) == 1) {
            process.cfileout = process.cfileout + "f" + fb::trim(fb::str(process.i_e_iso));
        }
        if (fb::imod(emode, 10) == 2) {
            process.cfileout = process.cfileout + "m" + fb::trim(fb::str(process.i_e_iso));
        }
    }
    // GEF.bas:3408-3411
    if (emode == 0) {
        process.cfileout += "_EB";
    }
    if (emode == 2) {
        process.cfileout += "_n";
    }
    if (emode == 12) {
        process.cfileout += "_p";
    }
    if (emode == 22) {
        process.cfileout += "_a";
    }
    // GEF.bas:3412-3422. QUIRK(candidate): P_E_exc is still the line's En_max here (GEF.bas:3225),
    // not a step energy, so a single-step FC or IS line that runs Energy_table(1) is named by
    // En_max (MILESTONE_6_PLAN.md §4 "Single-step modes").
    if (fb::abs(emode) == 1) {
        if (process.p_e_exc == 0.0F) {
            process.cfileout += "_sf";
        } else if (emode == -1) {
            process.cfileout += "_fc";
        } else {
            process.cfileout += "_cf";
        }
    }
    // GEF.bas:3423-3424
    if (emode == 3) {
        process.cfileout += "_ed";
    }
    if (emode == 13) {
        process.cfileout += "_em";
    }
    // GEF.bas:3425-3427
    if (file.i_mode_selected > -1) {
        process.cfileout += "_select";
    }
}

} // namespace

// GEF.bas:2555 and 2575-2624, at every pass through Nextfitloop.
void begin_round(ProcessState& process, WorkDir const& workdir) {
    // GEF.bas:2555 `#Include "FitparRead.bas"`: `If Fileexists("Fitpar.dat")` then the file is
    // read; WorkDir::read is nullopt exactly when the file cannot be opened.
    std::vector<std::string> lines;
    params::fitpar_read(workdir.read("Fitpar.dat"), process.params, lines);
    print_lines(process, lines);
    // GEF.bas:2575-2620. QUIRK(Q-019): 2610 reads the working copy PZ_S3_olap_curv.
    params::update_widths(process.widths, process.params, process.pz_s3_olap_curv);
    // GEF.bas:2622-2624
    if (process.bfilein != 0) {
        process.clocal = "localoff";
    }
}

// GEF.bas:3313-3440, after the driver has set the system's CN (3301-3305).
Flow begin_system(ProcessState& process, InputRoundState& /*round*/, SequenceFileState& file) {
    // GEF.bas:3313-3315
    if (process.bfilein != 0) {
        process.clocal = file.clocal_file_option;
    }
    // GEF.bas:3317-3321 `#include "Parameters.bas"`: the nominal parameters are reset; the others
    // in Parameters (Emode, EOscale, Eexc_min_multi, D_Par_Fac, Chisqr_Fit_min, BFC, ...) keep
    // their values (load_parameters_bas leaves them alone).
    if (process.b_fit == 0) {
        params::load_parameters_bas(process.params);
    }
    // GEF.bas:3323-3329
    if (process.clocal == "localon" && process.b_fit == 1) {
        print_line(process, "Local parameters not allowed for FIT option.");
        print_line(process, "Global parameters are used.");
        process.clocal = "localoff";
    }
    // GEF.bas:3337-3344 (3331-3335 and 3338-3341 are commented out)
    if (process.clocal == "localon") {
        print_line(process, "Local parameters are not available.");
    }
    // GEF.bas:3346-3375
    print_barriers(process);
    print_masses(process);

    // GEF.bas:3377. The C jumps past the block when the difference is `>= 0`, so a NaN separation
    // energy counts as unbound.
    if (!(neutron_separation(*process.tables, process.p_z_cn, process.p_a_cn) >= 0.0F)) {
        // GEF.bas:3378-3380
        process.console.print_void(PrintEnd::Newline);
        print_line(process, "<W> Fissioning nucleus is not bound.");
        print_line(process, "Calculation of this system is stopped.");
        // GEF.bas:3381-3389
        if (process.bfilein == 0) {
            dialogue_only("GEF.bas:3386-3388");
        }
        print_line(process, "Starting calculation of next system from input file.");
        process.console.print_void(PrintEnd::Newline);
        return Flow::NextLine; // GEF.bas:3384 `Goto Next_Iline_label`
    }

    // GEF.bas:3395
    process.cfileout_single = gef_name(process.p_z_cn, process.p_a_cn);
    // GEF.bas:3396-3428
    if (process.i_double_covar == 1) {
        name_output_file(process, file);
    }
    // GEF.bas:3429
    process.cfileout_full = "out\\" + process.cfileout + ".dat";
    // GEF.bas:3430-3439: the lmd name outside batch mode.
    if (process.bfilein == 0) {
        dialogue_only("GEF.bas:3430-3439");
    }
    return Flow::Proceed;
}

} // namespace gef::run
