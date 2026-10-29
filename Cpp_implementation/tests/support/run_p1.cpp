// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "support/run_p1.hpp"

#include "params/parameters.hpp"

#include <concepts>
#include <cstdint>
#include <string>
#include <string_view>
#include <variant>

namespace gef::test {
namespace {

// Writes one variable as BASIC does: integers as I (the narrow int8 and uint8 members widened
// first), floats as S, the double as D and strings as Z (ProbeDump::scalar).
template <typename T>
void put_value(ProbeDump& dump, std::string_view name, T const& value) {
    if constexpr (std::integral<T>) {
        dump.scalar(name, static_cast<std::int64_t>(value));
    } else {
        dump.scalar(name, value);
    }
}

} // namespace

ProbeDump dump_p1(run::ProcessState const& process, run::InputRoundState const& round,
                  run::SequenceFileState const& file, std::int64_t rec) {
    ProbeDump dump{"P1", "step=" + std::to_string(process.i_e_step) +
                             " pass=- bin=- rec=" + std::to_string(rec)};

    // The step, the input and the flags of the file.
    put_value(dump, "Iline", process.iline);                   // GEF.bas:1737
    put_value(dump, "Ifilein", round.ifilein);                 // GEF.bas:2683
    put_value(dump, "I_Double_Covar", process.i_double_covar); // GEF.bas:883
    put_value(dump, "N_Double_Covar", process.n_double_covar); // GEF.bas:884
    put_value(dump, "I_E_step", process.i_e_step);             // GEF.bas:1740
    put_value(dump, "N_E_steps", process.n_e_steps);           // GEF.bas:1739
    put_value(dump, "N_E_values", round.n_e_values);           // GEF.bas:2650
    put_value(dump, "I_E_iso", process.i_e_iso);               // GEF.bas:1748
    put_value(dump, "Bfilein", process.bfilein);               // GEF.bas:1735
    put_value(dump, "B_ENDF", file.b_endf);                    // GEF.bas:431
    put_value(dump, "B_Random_on", file.b_random_on);          // GEF.bas:874
    put_value(dump, "B_Error_On", file.b_error_on);            // GEF.bas:861
    put_value(dump, "I_Error", process.i_error);               // GEF.bas:864
    put_value(dump, "Fenhance", process.fenhance);             // GEF.bas:1712
    put_value(dump, "En_min", process.en_min);                 // GEF.bas:2652
    put_value(dump, "En_max", process.en_max);                 // GEF.bas:2653

    // The nucleus, the excitation and the spin.
    put_value(dump, "P_Z_CN", process.p_z_cn);                 // GEF.bas:878
    put_value(dump, "P_A_CN", process.p_a_cn);                 // GEF.bas:879
    put_value(dump, "P_E_exc", process.p_e_exc);               // GEF.bas:880
    put_value(dump, "P_Z_CN_Double", process.p_z_cn_double);   // GEF.bas:885
    put_value(dump, "P_A_CN_Double", process.p_a_cn_double);   // GEF.bas:886
    put_value(dump, "P_E_exc_Double", process.p_e_exc_double); // GEF.bas:887
    put_value(dump, "P_I_rms_CN", process.p_i_rms_cn);         // GEF.bas:890
    put_value(dump, "E_EXC_ISO", process.e_exc_iso);           // GEF.bas:832
    put_value(dump, "E_EXC_TRUE", process.e_exc_true);         // GEF.bas:832, set at 3549
    put_value(dump, "Spin_CN", process.spin_cn);               // GEF.bas:1749
    put_value(dump, "Spin_target", process.spin_target);       // GEF.bas:1749
    put_value(dump, "Eabsgs", process.eabsgs);                 // GEF.bas:1742
    put_value(dump, "Bprot", process.bprot);                   // GEF.bas:772
    put_value(dump, "Balpha", process.balpha);                 // GEF.bas:772

    // The file names.
    put_value(dump, "Csystem", process.csystem);                   // GEF.bas:1707
    put_value(dump, "Cfileout", process.cfileout);                 // GEF.bas:1708
    put_value(dump, "Cfileout_single", process.cfileout_single);   // GEF.bas:1708
    put_value(dump, "Cfileout_full", process.cfileout_full);       // GEF.bas:1708
    put_value(dump, "Cfileoutlmd_full", process.cfileoutlmd_full); // GEF.bas:1709
    put_value(dump, "C_Espectrum", process.c_espectrum);           // GEF.bas:1770

    // The channel counter and the spectrum maximum.
    put_value(dump, "Ichannel", round.ichannel);             // GEF.bas:2676
    put_value(dump, "W_spectrum_max", round.w_spectrum_max); // GEF.bas:2675

    // The energy and spin tables and the spectra; NE_all and NE_fis are LongInt.
    dump.array("Energy_Table", round.energy_table); // GEF.bas:2648
    dump.array("Spin_Table", round.spin_table);     // GEF.bas:2649
    dump.array("E_spectrum", round.e_spectrum);     // GEF.bas:2669
    dump.array("L_spectrum", round.l_spectrum);     // GEF.bas:2670
    dump.array("W_spectrum", round.w_spectrum);     // GEF.bas:2671
    dump.array("NE_all", round.ne_all);             // GEF.bas:2672
    dump.array("NE_fis", round.ne_fis);             // GEF.bas:2673

    // Z and T: table-builder leftovers that BASIC's P1 still carries.
    put_value(dump, "Z", process.z); // GEF.bas:790
    put_value(dump, "T", process.t); // GEF.bas:823

    // The nominal parameters, in the order of params::nominal_parameters (GEF.bas:893-1010). A
    // parameter GEF perturbs keeps its leading underscore (_P_DZ_Mean_S1, _Delta_S0).
    for (gef::params::NominalParameter const& entry : gef::params::nominal_parameters) {
        std::visit([&](auto member) { put_value(dump, entry.name, process.params.*member); },
                   entry.member);
    }

    // The 47 perturbation widths: Fred_par, then the Var_* widths (GEF.bas:2575-2624).
    for (gef::params::WidthParameter const& entry : gef::params::width_parameters) {
        put_value(dump, entry.name, process.widths.*entry.member);
    }

    return dump;
}

ProbeDump dump_p1b(run::ProcessState const& process, run::StepState const& step, bool prepass,
                   std::int64_t rec) {
    ProbeDump dump{"P1b", "step=" + std::to_string(process.i_e_step) +
                              " pass=- bin=- rec=" + std::to_string(rec)};

    // GEF.bas:3967: CLng of the pre-pass condition, -1 when it holds and 0 otherwise.
    put_value(dump, "Harness_Prepass", prepass ? std::int64_t{-1} : std::int64_t{0});
    put_value(dump, "Eexc_min_multi", process.params.eexc_min_multi); // P1 group G
    put_value(dump, "Fenhance", process.fenhance);                    // GEF.bas:1712
    put_value(dump, "N_multi_sample", step.n_multi_sample);           // GEF.bas:3921
    return dump;
}

} // namespace gef::test
