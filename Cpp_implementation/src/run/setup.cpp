// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// System and step set-up of GEF.bas (M6): begin_system (GEF.bas:3301-3440), step_energy
// (3444-3540) and the M6 part of set_up_step (3542-3880 and 3914-3972).

#include "run/setup.hpp"

#include "data/tables.hpp"
#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "fbrt/strings.hpp"
#include "fbrt/text.hpp"
#include "params/parameters.hpp"
#include "physics/barriers.hpp"
#include "physics/masses.hpp"

#include <cmath>
#include <cstdint>
#include <stdexcept>
#include <string>

namespace gef::run {
namespace {

using fb::PrintEnd;

// BFTF, BFTFA and BFTFB report an undefined switch only in their default case (barriers.cpp).
// Every switch the set-up passes is a defined case, so the message of GEF.bas:17731 is never
// printed on these paths; a reported flag would break that contract and is an error here.
float barrier_value(physics::BftfResult const& result) {
    if (result.print_undefined_option) {
        throw std::logic_error("BFTF: the set-up passed an undefined switch");
    }
    return result.value;
}

// GEF.bas:3370 and 3373, 3377: `AME2020(Z, A-1) - AME2020(Z, A)`; the two masses are evaluated
// in this order, as the emitted C does.
float separation_energy(data::TableSet const& tables, std::int64_t z, std::int64_t a) {
    float const lower = physics::ame2020(tables, z, fb::sub(a, 1));
    float const upper = physics::ame2020(tables, z, a);
    return lower - upper;
}

} // namespace

// GEF.bas:3301-3440 (one pass of `For I_Double_Covar`).
Flow begin_system(ProcessState& process, InputRoundState& round, SequenceFileState& file) {
    fb::PrintFile& console = process.console;
    data::TableSet const& tables = *process.tables;

    // GEF.bas:3301-3305
    if (process.i_double_covar == 2) {
        process.p_z_cn = process.p_z_cn_double;
        process.p_a_cn = process.p_a_cn_double;
        process.p_e_exc = process.p_e_exc_double;
    }
    // GEF.bas:3313-3315
    if (process.bfilein != 0) {
        process.clocal = file.clocal_file_option;
    }
    // GEF.bas:3317-3321 (`#include "Parameters.bas"`): the global parameters are reset.
    if (process.b_fit == 0) {
        params::load_parameters_bas(process.params);
    }
    // GEF.bas:3323-3329
    if (process.clocal == "localon") {
        if (process.b_fit == 1) {
            console.print("Local parameters not allowed for FIT option.", PrintEnd::Newline);
            console.print("Global parameters are used.", PrintEnd::Newline);
            process.clocal = "localoff";
        }
    }
    // GEF.bas:3337-3344 (the code of 3331-3335 and 3338-3341 is commented out)
    if (process.clocal == "localon") {
        console.print("Local parameters are not available.", PrintEnd::Newline);
    }

    // The CN does not change below; the BASIC reads P_Z_CN and P_A_CN at every use.
    std::int64_t const z = process.p_z_cn;
    std::int64_t const a = process.p_a_cn;
    float const zf = static_cast<float>(z);
    float const af = static_cast<float>(a);

    // GEF.bas:3346-3348
    console.print(" ", PrintEnd::Newline);
    console.print("Fission barrier of CN (Z =", PrintEnd::None);
    console.print(z, PrintEnd::None);
    console.print(", A =", PrintEnd::None);
    console.print(a, PrintEnd::None);
    console.print("):", PrintEnd::Newline);
    console.print("Macrosc. barrier (Thomas-Fermi) = ", PrintEnd::None);
    console.print(fb::round(barrier_value(physics::bftf(tables, zf, af, 0)), 3), PrintEnd::None);
    console.print(" MeV", PrintEnd::Newline);

    // GEF.bas:3350-3360. The emitted C tests `BFTFA - BFTFB >= 2` for the second branch, so a
    // NaN difference takes the inner-saddle branch.
    float const vr14 = barrier_value(physics::bftfa(tables, zf, af, 1));
    float const vr15 = barrier_value(physics::bftfb(tables, zf, af, 1));
    if (vr14 - vr15 >= 2.0F) {
        // GEF.bas:3359
        console.print("Fission-barrier height =", PrintEnd::None);
        console.print(fb::round(barrier_value(physics::bftf(tables, zf, af, 1)), 3),
                      PrintEnd::None);
        console.print(" MeV", PrintEnd::Newline);
    } else {
        // GEF.bas:3351-3352
        console.print("Inner saddle =", PrintEnd::None);
        console.print(fb::round(barrier_value(physics::bftfa(tables, zf, af, 1)), 3),
                      PrintEnd::None);
        console.print(" MeV, second saddle =", PrintEnd::None);
        console.print(fb::round(barrier_value(physics::bftfb(tables, zf, af, 1)), 3),
                      PrintEnd::None);
        console.print(" MeV", PrintEnd::Newline);
        // GEF.bas:3353-3357
        if (z >= 90 && z <= 98) {
            // GEF.bas:3354. The emitted C is (BFTFB + BFTFB) - BFTFA, not the BASIC's
            // BFTFB + (BFTFB - BFTFA) (QUIRK(candidate): fbc reassociates the third saddle).
            float const vr23 = barrier_value(physics::bftfb(tables, zf, af, 1));
            float const vr24 = barrier_value(physics::bftfb(tables, zf, af, 1));
            float const vr25 = barrier_value(physics::bftfa(tables, zf, af, 1));
            process.params.bfc = (vr23 + vr24) - vr25;
            // GEF.bas:3355
            if (z >= 92) {
                double const vr26 = std::pow(static_cast<double>(fb::add(z, -92)), 2.0);
                process.params.bfc = static_cast<float>(static_cast<double>(process.params.bfc) -
                                                        (vr26 * 0x1.3333333333333p-2));
            }
            // GEF.bas:3356
            console.print("Third saddle (estimated) = ", PrintEnd::None);
            console.print(fb::round(process.params.bfc, 3), PrintEnd::Newline);
        }
    }

    // GEF.bas:3361 and 3368: `BEexp(A-Z, Z) > -1.E10` selects the experimental quantities. The
    // emitted C tests `<= -1.E10` for the other branch, so a NaN entry takes the experimental one.
    bool const no_exp_value = static_cast<double>(process.tables->be_exp(fb::sub(a, z), z)) <=
                              -1.0E10;

    // GEF.bas:3361-3366
    if (no_exp_value) {
        console.print("Mass = ", PrintEnd::None);
    } else {
        console.print("exp. Mass = ", PrintEnd::None);
    }
    console.print(physics::ame2020(tables, z, a), PrintEnd::None);
    console.print(" MeV", PrintEnd::Newline);
    console.print("Lymass    = ", PrintEnd::None);
    console.print(physics::ly_mass(zf, af, 0.0F), PrintEnd::None);
    console.print(" MeV", PrintEnd::Newline);

    // GEF.bas:3367-3375
    console.print("G.S.Shell effect (Moeller) = ", PrintEnd::None);
    console.print(fb::round(physics::u_shell(tables, z, a), 3), PrintEnd::None);
    console.print(" MeV, ", PrintEnd::None);
    if (no_exp_value) {
        // GEF.bas:3372-3373
        console.print("G.S.Shell effect = ", PrintEnd::None);
        console.print(fb::round(physics::u_shell_exp(tables, z, a), 3), PrintEnd::None);
        console.print(" MeV", PrintEnd::Newline);
        console.print("S_n = ", PrintEnd::None);
        console.print(separation_energy(tables, z, a), PrintEnd::None);
        console.print(" MeV", PrintEnd::Newline);
    } else {
        // GEF.bas:3369-3370
        console.print("G.S.Shell effect (exp,TF) = ", PrintEnd::None);
        console.print(fb::round(physics::u_shell_exp(tables, z, a), 3), PrintEnd::None);
        console.print(" MeV", PrintEnd::Newline);
        console.print("S_n(exp.) = ", PrintEnd::None);
        console.print(separation_energy(tables, z, a), PrintEnd::None);
        console.print(" MeV", PrintEnd::Newline);
    }
    // GEF.bas:3375
    console.print("S_n(Lymass) = ", PrintEnd::None);
    float const vr63 = physics::ly_mass(zf, static_cast<float>(fb::sub(a, 1)), 0.0F);
    float const vr64 = physics::ly_mass(zf, af, 0.0F);
    console.print(vr63 - vr64, PrintEnd::None);
    console.print(" MeV", PrintEnd::Newline);

    // GEF.bas:3377-3390. The emitted C branches on `(AME2020(Z,A-1) - AME2020(Z,A)) >= 0`, so a
    // NaN separation energy takes the unbound branch.
    if (!(separation_energy(tables, z, a) >= 0.0F)) {
        console.print_void(PrintEnd::Newline);
        console.print("<W> Fissioning nucleus is not bound.", PrintEnd::Newline);
        console.print("Calculation of this system is stopped.", PrintEnd::Newline);
        if (process.bfilein != 0) {
            console.print("Starting calculation of next system from input file.",
                          PrintEnd::Newline);
            console.print_void(PrintEnd::Newline);
            return Flow::NextLine; // GEF.bas:3384 `Goto Next_Iline_label`
        }
        console.print("Please start input again!", PrintEnd::Newline);
        console.print_void(PrintEnd::Newline);
        // GEF.bas:3388 `Goto RepeatInput`: fbc's scope-exit cleanup releases the input round's
        // arrays and strings on the way out (emitted at the goto, not elsewhere).
        round.cfilein.erase();
        round.chelp.clear();
        round.ne_fis.erase();
        round.ne_all.erase();
        round.w_spectrum.erase();
        round.l_spectrum.erase();
        round.e_spectrum.erase();
        round.spin_table.erase();
        round.energy_table.erase();
        round.c_energy_table.clear();
        return Flow::Restart;
    }

    // GEF.bas:3395: the file name of the single system.
    process.cfileout_single = "GEF_" + fb::trim(fb::str(z)) + "_" + fb::trim(fb::str(a));
    // GEF.bas:3396-3427, the first system of a correlation (I_Double_Covar = 1).
    if (process.i_double_covar == 1) {
        // GEF.bas:3397-3403
        if (process.b_double_covar == 0) {
            process.cfileout = "GEF_" + fb::trim(fb::str(z)) + "_" + fb::trim(fb::str(a));
        } else {
            process.cfileout = "GEF_" + fb::trim(fb::str(z)) + "_" + fb::trim(fb::str(a)) + "+" +
                               fb::trim(fb::str(process.p_z_cn_double)) + "_" +
                               fb::trim(fb::str(process.p_a_cn_double));
        }
        // GEF.bas:3404-3407
        if (process.i_e_iso > 0) {
            if (fb::abs(process.params.emode) == 1) {
                process.cfileout = process.cfileout + "f" + fb::trim(fb::str(process.i_e_iso));
            }
            if (fb::imod(process.params.emode, 10) == 2) {
                process.cfileout = process.cfileout + "m" + fb::trim(fb::str(process.i_e_iso));
            }
        }
        // GEF.bas:3408-3411
        if (process.params.emode == 0) {
            process.cfileout += "_EB";
        }
        if (process.params.emode == 2) {
            process.cfileout += "_n";
        }
        if (process.params.emode == 12) {
            process.cfileout += "_p";
        }
        if (process.params.emode == 22) {
            process.cfileout += "_a";
        }
        // GEF.bas:3412-3422
        if (fb::abs(process.params.emode) == 1) {
            if (process.p_e_exc == 0.0F) {
                process.cfileout += "_sf";
            } else if (process.params.emode == -1) {
                process.cfileout += "_fc";
            } else {
                process.cfileout += "_cf";
            }
        }
        // GEF.bas:3423-3424
        if (process.params.emode == 3) {
            process.cfileout += "_ed";
        }
        if (process.params.emode == 13) {
            process.cfileout += "_em";
        }
        // GEF.bas:3425-3427
        if (file.i_mode_selected > -1) {
            process.cfileout += "_select";
        }
    }
    // GEF.bas:3429 (outside the I_Double_Covar = 1 block)
    process.cfileout_full = "out\\" + process.cfileout + ".dat";
    // GEF.bas:3430-3439: the lmd file name, except in batch mode
    if (process.bfilein == 0) {
        // GEF.bas:3431
        if (file.cfileoutlmd == "$Events.lmd") {
            file.cfileoutlmd = process.cfileout + ".lmd";
        }
        // GEF.bas:3432-3438
        if (file.cfileoutlmd != "") {
            if (fb::instr(file.cfileoutlmd, ".") == 0) {
                process.cfileoutlmd_full = "out\\" + file.cfileoutlmd + ".lmd";
            } else {
                process.cfileoutlmd_full = "out\\" + file.cfileoutlmd;
            }
        }
    }
    return Flow::Proceed;
}

} // namespace gef::run
