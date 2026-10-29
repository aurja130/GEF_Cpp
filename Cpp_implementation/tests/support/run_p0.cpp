// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "support/run_p0.hpp"

#include <concepts>
#include <cstdint>
#include <string>
#include <string_view>

namespace gef::test {
namespace {

// BASIC prints every integer as `I`. ProbeDump::scalar takes int64 and the floating and string
// types only, so an int8 or uint8 argument would be ambiguous between the overloads: widen it.
template <std::integral T>
void put_integer(ProbeDump& dump, std::string_view name, T value) {
    dump.scalar(name, static_cast<std::int64_t>(value));
}

} // namespace

// The variables and their order follow harness/patches/probes.patch (P0 block, about lines
// 862-938; HP_F1 at 891-896) and harness/PROBES.md section P0. BASIC writes the record after
// GEF.bas:3128 (`Fenhance = Fenhance_global`).
ProbeDump dump_p0(run::ProcessState const& process, run::InputRoundState const& round,
                  run::SequenceFileState const& file, std::int64_t rec) {
    ProbeDump dump{"P0", "step=- pass=- bin=- rec=" + std::to_string(rec)};

    // GEF.bas:2647-2684 (the round's Dims), 2699-2763 (file.in), 2770-3128 (the sequence file).
    put_integer(dump, "Nfilein", round.nfilein);
    dump.array("Cfilein", round.cfilein, true);
    put_integer(dump, "Ifilein", round.ifilein);
    dump.scalar("Fenhance_global", process.fenhance_global);
    dump.scalar("Fenhance", process.fenhance);
    dump.scalar("C_Energy_Table", round.c_energy_table);
    put_integer(dump, "I_first_E_step", process.i_first_e_step);
    put_integer(dump, "N_E_values", round.n_e_values);
    dump.array("Energy_Table", round.energy_table);
    dump.array("Spin_Table", round.spin_table);
    dump.scalar("En_min", process.en_min);
    dump.scalar("En_max", process.en_max);
    dump.scalar("C_Espectrum1", process.c_espectrum1);
    dump.scalar("C_Espectrum2", process.c_espectrum2);
    put_integer(dump, "Iline_tot", process.iline_tot);

    // The system lines s_par(1..Iline_tot), one field at a time (HP_F1 writes the bounds first).
    dump.field("S_par.Z", process.s_par, 1, process.iline_tot,
               [](run::SystemLine const& line) { return line.z; });
    dump.field("S_par.A", process.s_par, 1, process.iline_tot,
               [](run::SystemLine const& line) { return line.a; });
    dump.field("S_par.Z_double", process.s_par, 1, process.iline_tot,
               [](run::SystemLine const& line) { return line.z_double; });
    dump.field("S_par.A_double", process.s_par, 1, process.iline_tot,
               [](run::SystemLine const& line) { return line.a_double; });
    dump.field("S_par.E_double", process.s_par, 1, process.iline_tot,
               [](run::SystemLine const& line) { return line.e_double; });
    dump.field("S_par.CE", process.s_par, 1, process.iline_tot,
               [](run::SystemLine const& line) { return line.ce; });

    put_integer(dump, "B_Error_On", file.b_error_on);
    put_integer(dump, "Brec", file.brec);
    put_integer(dump, "Bcov", file.bcov);
    put_integer(dump, "Bcor", file.bcor);
    put_integer(dump, "B_supp", file.b_supp);
    put_integer(dump, "B_ENDF", file.b_endf);
    put_integer(dump, "B_Random_on", file.b_random_on);
    dump.scalar("Cfileoutlmd", file.cfileoutlmd);
    dump.scalar("Cfileoutlmd_full", process.cfileoutlmd_full);
    dump.scalar("Clocal_file_option", file.clocal_file_option);
    put_integer(dump, "I_Mode_selected", file.i_mode_selected);
    put_integer(dump, "B_Fit", process.b_fit);
    put_integer(dump, "N_iter", process.n_iter);
    dump.scalar("C_Fitoption", process.c_fitoption);
    put_integer(dump, "Bplot", process.bplot);
    put_integer(dump, "B_MyParameters", process.params.b_myparameters);
    dump.scalar("D_Par_Fac", process.params.d_par_fac);
    dump.scalar("EOscale", process.params.eoscale);
    put_integer(dump, "Emode", process.params.emode);

    // The lmd flags (the `Pz1` ... `Pndel` block of the P0 record).
    run::LmdFlags const& lmd = process.lmd;
    put_integer(dump, "PZ1", lmd.pz1);
    put_integer(dump, "PZ2", lmd.pz2);
    put_integer(dump, "PA1pre", lmd.pa1pre);
    put_integer(dump, "PA2pre", lmd.pa2pre);
    put_integer(dump, "PA1post", lmd.pa1post);
    put_integer(dump, "PA2post", lmd.pa2post);
    put_integer(dump, "PI1", lmd.pi1);
    put_integer(dump, "PI2", lmd.pi2);
    put_integer(dump, "Pn1", lmd.pn1);
    put_integer(dump, "Pn2", lmd.pn2);
    put_integer(dump, "PTKEpre", lmd.ptkepre);
    put_integer(dump, "PTKEpost", lmd.ptkepost);
    put_integer(dump, "PnCN", lmd.pncn);
    put_integer(dump, "PEnpost", lmd.penpost);
    put_integer(dump, "PEgpost", lmd.pegpost);
    put_integer(dump, "Pdir", lmd.pdir);
    put_integer(dump, "PXE", lmd.pxe);
    put_integer(dump, "PXEdetails", lmd.pxedetails);
    put_integer(dump, "Pndel", lmd.pndel);

    return dump;
}

} // namespace gef::test
