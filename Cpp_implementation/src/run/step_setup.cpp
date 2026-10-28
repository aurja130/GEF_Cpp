// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The set-up of one energy step (GEF.bas:3499-3880) and the run-control lines of the multi-chance
// block (3914-3972), from the C fbc emits (GEF.c:43231-45847). Not here: the clearing of the CN
// spectra (3882-3907) and the pre-pass (3973-4800), which are M9's, and the pre-pass arrays of
// 3914-3945 (E_multi_chance, W_chances, En_multi_1..6, J_multi_last, I_emit_1..6, DUF), which
// only the pre-pass uses.

#include "data/lookups.hpp"
#include "data/tables.hpp"
#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"
#include "fbrt/gef_math.hpp"
#include "fbrt/input.hpp"
#include "fbrt/strings.hpp"
#include "fbrt/text.hpp"
#include "physics/barriers.hpp"
#include "physics/masses.hpp"
#include "run/run_util.hpp"
#include "run/setup.hpp"
#include "util/utilities.hpp"

#include <cmath>
#include <cstdint>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

namespace gef::run {
namespace {

using fb::PrintEnd;

// `x * (float)(A-k)` style operands: the Integer `A + (-k)` as fbc computes it.
std::int64_t minus(std::int64_t value, std::int64_t k) {
    return fb::add(value, -k);
}

// `I >= Lbound(NucTab) And I <= Ubound(NucTab)` (GEF.bas:3569, 3578, 3708, 3759, 3766).
bool in_nuc_tab(data::TableSet const& tables, std::int64_t index) {
    return index >= tables.nuc_tab.lbound() && index <= tables.nuc_tab.ubound();
}

// I_MAT_ENDF(IZ, IA), with the lines it prints.
// QUIRK(Q-021): ProcessState::mat holds ctl/IMATmax.ctl for the whole run (plan D7).
std::int64_t mat_number(ProcessState& process, std::int64_t iz, std::int64_t ia) {
    std::vector<std::string> lines;
    std::int64_t const imat = data::i_mat_endf(*process.tables, iz, ia, process.mat, lines);
    print_lines(process, lines);
    return imat;
}

// `Print "Z, A, #iso ",ZT,AT,I_E_iso;"."` (GEF.bas:3715, 3769).
void print_isomer_numbers(ProcessState& process, std::int64_t zt, std::int64_t at) {
    process.console.print("Z, A, #iso ", PrintEnd::Pad);
    process.console.print(zt, PrintEnd::Pad);
    process.console.print(at, PrintEnd::Pad);
    process.console.print(process.i_e_iso, PrintEnd::None);
    print_line(process, ".");
}

// GEF.bas:3500-3529: the name of the system.
void name_system(ProcessState& process, SequenceFileState const& file) {
    std::int64_t const emode = process.params.emode;
    // GEF.bas:3500
    process.csystem =
        "Z" + fb::trim(fb::str(process.p_z_cn)) + "_A" + fb::trim(fb::str(process.p_a_cn));
    // GEF.bas:3501-3504
    if (process.i_e_iso > 0) {
        if (fb::abs(emode) == 1) {
            process.csystem = process.csystem + "f" + fb::trim(fb::str(process.i_e_iso));
        }
        if (fb::imod(emode, 10) == 2) {
            process.csystem = process.csystem + "m" + fb::trim(fb::str(process.i_e_iso));
        }
    }
    // GEF.bas:3505-3508
    if (emode == 0) {
        process.csystem += "_EB";
    }
    if (emode == 2) {
        process.csystem += "_n";
    }
    if (emode == 12) {
        process.csystem += "_p";
    }
    if (emode == 22) {
        process.csystem += "_a";
    }
    // GEF.bas:3509-3519
    if (fb::abs(emode) == 1) {
        if (process.p_e_exc == 0.0F) {
            process.csystem += "_sf";
        } else if (emode == -1) {
            process.csystem += "_fc";
        } else {
            process.csystem += "_cf";
        }
    }
    // GEF.bas:3520-3526
    if (emode == 3) {
        process.csystem += "_ed";
    } else if (emode == 13) {
        process.csystem += "_em";
    } else {
        process.csystem = process.csystem + "_E" + fb::trim(fb::str(process.p_e_exc)) + "MeV";
    }
    // GEF.bas:3527-3529
    if (file.i_mode_selected > -1) {
        process.csystem = process.csystem + "_Mode" + fb::trim(fb::str(file.i_mode_selected));
    }
}

// GEF.bas:3531-3540: the lmd file name in batch mode, with the step's energy in Csystem.
void name_lmd_file(ProcessState& process, SequenceFileState& file) {
    if (process.bfilein != -1) {
        return;
    }
    // GEF.bas:3532
    if (file.cfileoutlmd == "$Events.lmd") {
        file.cfileoutlmd = process.csystem + ".lmd";
    }
    // GEF.bas:3533-3539
    if (!file.cfileoutlmd.empty()) {
        if (fb::instr(file.cfileoutlmd, ".") == 0) {
            process.cfileoutlmd_full = "out\\" + file.cfileoutlmd + ".lmd";
        } else {
            process.cfileoutlmd_full = "out\\" + file.cfileoutlmd;
        }
    }
}

// GEF.bas:3569-3588: the spin and excitation energy of the isomer, after its NucTab index `imat`
// passed the check of 3563.
void add_isomer_energy(ProcessState& process, std::int64_t imat) {
    data::TableSet const& tables = *process.tables;
    std::int64_t const emode = process.params.emode;
    std::int64_t const index = fb::add(imat, process.i_e_iso);
    // GEF.bas:3569-3573
    if (in_nuc_tab(tables, index)) {
        print_part(process, "spin = ");
        process.console.print(tables.nuc_tab(index).r_spi, PrintEnd::Newline);
    } else {
        print_part(process, "Spin not in NucTab (I_MAT = ");
        process.console.print(imat, PrintEnd::None);
        print_line(process, ")");
    }
    // GEF.bas:3574-3577
    if (fb::abs(emode) == 1) {
        print_line(process, "Energy above ground state ->");
    }
    if (emode == 2) {
        print_line(process, "Fictive neutron energy for capt. in g.s. ->");
    }
    if (emode == 12) {
        print_line(process, "Fictive proton energy for capt. in g.s. ->");
    }
    if (emode == 22) {
        print_line(process, "Fictive alpha energy for capt. in g.s. ->");
    }
    // GEF.bas:3578-3584
    if (in_nuc_tab(tables, index)) {
        process.e_exc_iso = tables.nuc_tab(index).r_exc;
    } else {
        print_line(process, "Excitation energy of isomer is not in table.");
        print_line(process, "Value set to zero.");
        process.e_exc_iso = 0.0F;
    }
    // GEF.bas:3585-3588
    if (fb::abs(emode) == 1 || emode == 2 || emode == 12 || emode == 22) {
        process.p_e_exc = process.p_e_exc + process.e_exc_iso;
    }
}

// GEF.bas:3542-3590 (Scope): the isomer of the entrance channel. False where BASIC goes to
// RepeatInput (3567).
bool set_isomer(ProcessState& process) {
    std::int64_t const emode = process.params.emode;
    // GEF.bas:3546-3549
    std::int64_t zt = process.p_z_cn;
    std::int64_t at = process.p_a_cn;
    process.e_exc_iso = 0.0F;
    process.e_exc_true = process.p_e_exc;
    // GEF.bas:3550-3558
    if (emode == 2) {
        at = minus(at, 1);
    }
    if (emode == 12) {
        at = minus(at, 1);
        zt = minus(zt, 1);
    }
    if (emode == 22) {
        at = minus(at, 4);
        zt = minus(zt, 2);
    }
    // GEF.bas:3559
    if (process.i_e_iso <= 0) {
        return true;
    }
    // GEF.bas:3560-3562
    print_line(process, " ");
    print_part(process, "isomer # ");
    process.console.print(process.i_e_iso, PrintEnd::Newline);
    std::int64_t const imat = mat_number(process, zt, at);
    // GEF.bas:3563-3568
    if (data::n_iso_mat(*process.tables, imat) < process.i_e_iso) {
        print_line(process, "The isomer is not in the table of nuclear properties.");
        process.console.print("Z, A, #iso ", PrintEnd::Pad);
        process.console.print(zt, PrintEnd::Pad);
        process.console.print(at, PrintEnd::Pad);
        process.console.print(process.i_e_iso, PrintEnd::Newline);
        print_line(process, "Please stop GEF, complete table and restart GEF.");
        // GEF.bas:3567 `Goto RepeatInput`. QUIRK(Q-049): the whole input is read again. On the
        // way out fbc erases Cfilein, Chelp, NE_fis, NE_all, the spectra, Spin_Table,
        // Energy_Table and C_Energy_Table (GEF.c:43660-43678); the driver's restart starts the
        // next round from a fresh InputRoundState.
        return false;
    }
    add_isomer_energy(process, imat);
    return true;
}

// GEF.bas:3593-3605: the CN line, and C_Espectrum for ES and EM.
void print_cn_line(ProcessState& process) {
    std::int64_t const emode = process.params.emode;
    fb::PrintFile& console = process.console;
    // GEF.bas:3593
    print_part(process, "CN: Z =");
    console.print(process.p_z_cn, PrintEnd::None);
    print_part(process, ", A =");
    console.print(process.p_a_cn, PrintEnd::None);
    if (fb::imod(emode, 10) < 3) {
        // GEF.bas:3595-3600
        print_part(process, ", E = ");
        console.print(process.p_e_exc, PrintEnd::None);
        print_part(process, " MeV");
        if (emode == 1) {
            print_part(process, ", Spin = ");
            console.print(process.p_i_rms_cn, PrintEnd::Newline);
        } else {
            print_line(process, " ");
        }
        return;
    }
    // GEF.bas:3602-3604
    if (process.i_double_covar == 1) {
        process.c_espectrum = process.c_espectrum1;
    }
    if (process.i_double_covar == 2) {
        process.c_espectrum = process.c_espectrum2;
    }
    print_part(process, ", E/MeV from file ");
    print_part(process, process.c_espectrum);
    print_line(process, ":");
}

// GEF.bas:3643-3651 and 3661-3669: the next channel of the spectrum file.
void add_channel(ProcessState& process, InputRoundState& round, float renergy, float rspin,
                 float rweight, bool with_spin) {
    // GEF.bas:3642, 3660
    round.ichannel = round.ichannel + 1.0F;
    // GEF.bas:3643-3647, 3661-3665: the C skips the Redim when `Ichannel <= Ubound`, so a NaN
    // Ichannel would redim.
    if (!(round.ichannel <= static_cast<float>(round.w_spectrum.ubound()))) {
        fb::Bounds const bounds{0, fb::f2l(round.ichannel)};
        round.e_spectrum.redim_preserve({bounds});
        round.l_spectrum.redim_preserve({bounds});
        round.w_spectrum.redim_preserve({bounds});
    }
    std::int64_t const channel = fb::f2l(round.ichannel);
    // GEF.bas:3648-3650, 3666-3668
    round.e_spectrum(channel) = renergy;
    round.l_spectrum(channel) = rspin;
    round.w_spectrum(channel) = rweight;
    // GEF.bas:3651, 3669
    process.console.print(round.e_spectrum(channel), PrintEnd::Pad);
    if (with_spin) {
        process.console.print(round.l_spectrum(channel), PrintEnd::Pad);
    }
    process.console.print(round.w_spectrum(channel), PrintEnd::Newline);
}

// GEF.bas:3619-3672 when the file exists: the channels of the spectrum file. Returns REmax.
float read_spectrum_file(ProcessState& process, InputRoundState& round,
                         std::string const& contents) {
    float remax = 0.0F; // GEF.bas:3616
    // GEF.bas:3620-3623
    round.e_spectrum.redim_preserve({fb::Bounds{0, 1}});
    round.l_spectrum.redim_preserve({fb::Bounds{0, 1}});
    round.w_spectrum.redim_preserve({fb::Bounds{0, 1}});
    round.ichannel = 0.0F;
    // GEF.bas:3624-3632: the comment lines at the head, and the number of fields after them.
    // Line Input returns "" once the file is read, so the loop ends.
    std::int64_t i_elist_skip = 0;
    fb::InputFile head{contents};
    std::string c_read = head.line_input();
    while (fb::left(fb::trim(c_read), 1) == "'") {
        i_elist_skip = fb::add(i_elist_skip, std::int64_t{1});
        c_read = head.line_input();
    }
    std::int64_t const n_count = util::cc_count(c_read, " ");
    // GEF.bas:3633-3637: the file again, without its comment lines.
    fb::InputFile file{contents};
    for (std::int64_t i_skip = 1; i_skip <= i_elist_skip; ++i_skip) {
        static_cast<void>(file.line_input());
    }
    // GEF.bas:3638-3671. Each loop ends: while EOF is false, every `Input #` consumes a byte, and
    // it puts one back (0xFF, fbrt/input.cpp) only for a '\r' at the very end, which the next
    // Input consumes without putting anything back.
    if (n_count == 2) {
        for (;;) {
            float const renergy = file.input_single();
            float const rweight = file.input_single();
            remax = fb::max(remax, renergy);
            add_channel(process, round, renergy, 0.0F, rweight, false);
            if (file.eof()) { // `Loop Until EOF(FEspectrum)`
                break;
            }
        }
    }
    if (n_count == 3) {
        for (;;) {
            float const renergy = file.input_single();
            float const rspin = file.input_single();
            float const rweight = file.input_single();
            remax = fb::max(remax, renergy);
            add_channel(process, round, renergy, rspin, rweight, true);
            if (file.eof()) { // `Loop Until EOF(FEspectrum)`
                break;
            }
        }
    }
    return remax;
}

// GEF.bas:3682-3691: the spectrum normalised, for every Emode.
// QUIRK(Q-047): without a spectrum W_spectrum(1) is 0 and the division is 0/0 (NaN); a
// spectrum read once is normalised again at every later step.
void normalise_spectrum(InputRoundState& round) {
    float norm = 0.0F; // GEF.bas:3612
    // GEF.bas:3682-3684 (the upper bound is evaluated once)
    std::int64_t const last = round.w_spectrum.ubound();
    for (std::int64_t i = 1; i <= last; ++i) {
        norm = norm + round.w_spectrum(i);
    }
    // GEF.bas:3685-3689
    round.w_spectrum_max = 0.0F;
    for (std::int64_t i = 1; i <= last; ++i) {
        round.w_spectrum(i) = static_cast<float>(static_cast<double>(round.w_spectrum(i)) /
                                                 static_cast<double>(norm));
        round.w_spectrum_max = fb::max(round.w_spectrum_max, round.w_spectrum(i));
    }
    // GEF.bas:3690-3691
    fb::Bounds const bounds{0, fb::f2l(round.ichannel)};
    round.ne_all.redim({bounds});
    round.ne_fis.redim({bounds});
}

// GEF.bas:3607-3692 (Scope): the E* spectrum of ES and EM, then its normalisation. False where
// BASIC ends (3674-3677).
bool read_spectrum(ProcessState& process, InputRoundState& round, WorkDir const& workdir) {
    std::int64_t const emode = process.params.emode;
    // GEF.bas:3618
    if (emode == 3 || emode == 13) {
        // GEF.bas:3619
        if (!workdir.exists(process.c_espectrum)) {
            // GEF.bas:3674-3677 (Sleep prints nothing)
            print_part(process, "<S> File ");
            print_part(process, process.c_espectrum);
            print_line(process, " not found.");
            print_line(process, "Press ENTER key to leave GEF!");
            return false;
        }
        // GEF.bas:3625 `Open C_Espectrum For Input`: the file is read whole.
        std::optional<std::string> const contents = workdir.read(process.c_espectrum);
        if (!contents) {
            // exists() converts no backslash and read() does, so this is reached only when a file
            // literally named with a backslash exists while its converted name does not, or when
            // the file changes between the two checks. BASIC would read a file that failed to
            // open; not ported.
            throw std::logic_error(
                "GEF.bas:3625: the spectrum file was found but cannot be opened");
        }
        float const remax = read_spectrum_file(process, round, *contents);
        // GEF.bas:3679: the C skips the assignment when `REmax <= 11`.
        if (!(remax <= 11.0F)) {
            process.i_warning = 1;
        }
    }
    normalise_spectrum(round);
    return true;
}

// GEF.bas:3703-3733: the spin of the CN for spontaneous and first-chance fission.
void set_fission_spin(ProcessState& process) {
    data::TableSet const& tables = *process.tables;
    // GEF.bas:3704, 3730-3731
    if (process.p_e_exc != 0.0F) {
        process.spin_cn = process.p_i_rms_cn;
        return;
    }
    // GEF.bas:3707
    std::int64_t const imat = mat_number(process, process.p_z_cn, process.p_a_cn);
    // GEF.bas:3708, 3723-3728
    if (!in_nuc_tab(tables, imat)) {
        process.spin_cn = 0.0F;
        print_line(process, "The fissioning nucleus is not in the table of nuclear properties.");
        process.console.print("Z, A ", PrintEnd::Pad);
        process.console.print(process.p_z_cn, PrintEnd::Pad);
        process.console.print(process.p_a_cn, PrintEnd::None);
        print_line(process, ".");
        print_line(process, "Spin value set to zero.");
        return;
    }
    // GEF.bas:3709-3711
    if (process.i_e_iso == 0) {
        process.spin_cn = tables.nuc_tab(imat).r_spi;
        print_part(process, "Ground-state spin ");
        process.console.print(process.spin_cn, PrintEnd::None);
        print_line(process, " imposed.");
        return;
    }
    // GEF.bas:3713-3717
    if (data::n_iso_mat(tables, imat) < process.i_e_iso) {
        print_line(process, "The isomer is not in the table of nuclear properties.");
        print_isomer_numbers(process, process.p_z_cn, process.p_a_cn);
        print_line(process, "Spin value or isomer set to zero.");
        process.spin_cn = 0.0F;
        return;
    }
    // GEF.bas:3719-3720
    process.spin_cn = tables.nuc_tab(fb::add(imat, process.i_e_iso)).r_spi;
    print_part(process, "Spin of isomer ");
    process.console.print(process.spin_cn, PrintEnd::None);
    print_line(process, " imposed.");
}

// GEF.bas:3736-3781 (Scope): the spin of the target nucleus for particle-induced fission.
void set_target_spin(ProcessState& process) {
    data::TableSet const& tables = *process.tables;
    std::int64_t const emode = process.params.emode;
    // GEF.bas:3738-3750 (`Dim As Integer ZT,AT` start at 0)
    std::int64_t zt = 0;
    std::int64_t at = 0;
    if (emode == 2) {
        zt = process.p_z_cn;
        at = minus(process.p_a_cn, 1);
    } else if (emode == 12) {
        zt = minus(process.p_z_cn, 1);
        at = minus(process.p_a_cn, 1);
    } else if (emode == 22) {
        zt = minus(process.p_z_cn, 2);
        at = minus(process.p_a_cn, 4);
    }
    // GEF.bas:3751
    std::int64_t const imat = mat_number(process, zt, at);
    if (process.i_e_iso == 0) {
        // GEF.bas:3753-3757
        if (imat == 0) {
            print_line(process, "The ground-state spin is not in the table of nuclear properties "
                                "for the nucleus");
            print_part(process, "Z, A ");
            process.console.print(zt, PrintEnd::Pad);
            process.console.print(at, PrintEnd::None);
            print_line(process, ".");
            print_line(process, "Spin value of targer nucleus set to zero.");
            process.spin_target = 0.0F;
            return;
        }
        // GEF.bas:3759-3763
        process.spin_target = in_nuc_tab(tables, imat) ? tables.nuc_tab(imat).r_spi : 0.0F;
        return;
    }
    // GEF.bas:3766, 3775-3777
    if (!in_nuc_tab(tables, imat)) {
        print_line(process, "Spin of target set to zero.");
        process.spin_target = 0.0F;
        return;
    }
    // GEF.bas:3767-3771
    if (data::n_iso_mat(tables, imat) < process.i_e_iso) {
        print_line(process, "The isomer is not in the table of nuclear properties.");
        print_isomer_numbers(process, zt, at);
        print_line(process, "Spin value or isomer set to zero.");
        process.spin_target = 0.0F;
        return;
    }
    // GEF.bas:3773
    process.spin_target = tables.nuc_tab(fb::add(imat, process.i_e_iso)).r_spi;
}

// `Spin_target^2` as the C forms it: the Single product, then widened.
double target_spin_squared(ProcessState const& process) {
    return static_cast<double>(process.spin_target * process.spin_target);
}

// `(0.1699 * (A-1)^0.333333 * sqr(P_E_exc))^2` (GEF.bas:3793-3794, 3806-3807), as emitted.
double neutron_angular_term(ProcessState const& process) {
    double const radius =
        std::pow(static_cast<double>(minus(process.p_a_cn, 1)), 0x1.55553EF6B5D46p-2);
    return std::pow(
        (radius * static_cast<double>(std::sqrt(process.p_e_exc))) * 0x1.5BF487FCB923Ap-3, 0x1.p+1);
}

// GEF.bas:3790-3799: neutron-induced fission (Case 2).
void neutron_capture(ProcessState& process) {
    data::TableSet const& tables = *process.tables;
    std::int64_t const a = process.p_a_cn;
    // GEF.bas:3792-3798: the C takes the Else branch when `P_E_exc <= 0`.
    if (!(process.p_e_exc <= 0.0F)) {
        process.spin_cn = static_cast<float>(
            std::sqrt((target_spin_squared(process) + neutron_angular_term(process)) + 0x1.p-2));
    } else {
        process.spin_cn = static_cast<float>(std::sqrt(target_spin_squared(process) + 0x1.p-2));
    }
    // GEF.bas:3799
    float const target = physics::ame2020(tables, process.p_z_cn, minus(a, 1));
    float const cn = physics::ame2020(tables, process.p_z_cn, a);
    process.eabsgs =
        static_cast<float>(((static_cast<double>(process.p_e_exc) *
                             (static_cast<double>(minus(a, 1)) / static_cast<double>(a))) +
                            static_cast<double>(target)) -
                           static_cast<double>(cn));
}

// GEF.bas:3801-3816: proton-induced fission (Case 12).
void proton_capture(ProcessState& process) {
    data::TableSet const& tables = *process.tables;
    std::int64_t const z = process.p_z_cn;
    std::int64_t const a = process.p_a_cn;
    // GEF.bas:3803
    double const radius = std::pow(static_cast<double>(minus(a, 1)), 0x1.555475A31A4BEp-2);
    process.bprot = static_cast<float>((static_cast<double>(minus(z, 1)) * 0x1.23D70A3D70A3Dp+0) /
                                       ((radius * 0x1.28F5C28F5C28Fp+0) + 0x1.28F5C28F5C28Fp+0));
    // GEF.bas:3804-3815
    double const no_kinetic = std::sqrt(target_spin_squared(process) + 0x1.p-2);
    if (!(process.p_e_exc <= 0.0F)) {
        // `P_E_exc * (P_A_CN-1) / P_A_CN`: the Single product, then the Double division.
        double const kinetic =
            static_cast<double>(process.p_e_exc * static_cast<float>(minus(a, 1))) /
            static_cast<double>(a);
        if (!(kinetic <= static_cast<double>(process.bprot))) {
            // GEF.bas:3806-3809
            process.spin_cn = static_cast<float>(
                std::sqrt((target_spin_squared(process) + neutron_angular_term(process)) +
                          0x1.p-2) *
                std::sqrt(-(static_cast<double>(process.bprot) / kinetic) + 0x1.p+0));
        } else {
            process.spin_cn = static_cast<float>(no_kinetic); // GEF.bas:3811
        }
    } else {
        process.spin_cn = static_cast<float>(no_kinetic); // GEF.bas:3814
    }
    // GEF.bas:3816
    float const target = physics::ame2020(tables, minus(z, 1), minus(a, 1));
    float const cn = physics::ame2020(tables, z, a);
    process.eabsgs =
        static_cast<float>(((static_cast<double>(process.p_e_exc) *
                             (static_cast<double>(minus(a, 1)) / static_cast<double>(a))) +
                            static_cast<double>(target)) -
                           static_cast<double>(cn));
}

// GEF.bas:3818-3840: alpha-induced fission (Case 22). False where BASIC ends (3835-3839).
bool alpha_capture(ProcessState& process) {
    data::TableSet const& tables = *process.tables;
    std::int64_t const z = process.p_z_cn;
    std::int64_t const a = process.p_a_cn;
    double const mass_ratio = static_cast<double>(minus(a, 4)) / static_cast<double>(a);
    // GEF.bas:3820-3832: the C takes the Else branch when `P_E_exc <= 0`.
    if (!(process.p_e_exc <= 0.0F)) {
        // GEF.bas:3821
        double const radius = std::pow(static_cast<double>(minus(a, 4)), 0x1.55553EF6B5D46p-2);
        process.balpha =
            static_cast<float>((static_cast<double>(minus(z, 2)) * 0x1.23D70A3D70A3Dp+1) /
                               ((radius * 0x1.28F5C28F5C28Fp+0) + 0x1.D764F74DDD35Dp+0));
        // GEF.bas:3822
        if (!((static_cast<double>(process.p_e_exc) * mass_ratio) <=
              static_cast<double>(process.balpha))) {
            // GEF.bas:3823-3826
            double const radius_2 =
                std::pow(static_cast<double>(minus(a, 4)), 0x1.55553EF6B5D46p-2);
            double const angular =
                std::pow(((radius_2 * 0x1.5BF487FCB923Ap-1) + 0x1.142C0E9748A93p+0) *
                             std::sqrt(static_cast<double>(process.p_e_exc) / 0x1.p+2),
                         0x1.p+1);
            double const kinetic =
                static_cast<double>(process.p_e_exc * static_cast<float>(minus(a, 4))) /
                static_cast<double>(a);
            process.spin_cn = static_cast<float>(
                std::sqrt(target_spin_squared(process) + angular) *
                std::sqrt(-(static_cast<double>(process.balpha) / kinetic) + 0x1.p+0));
        } else {
            process.spin_cn = process.spin_target; // GEF.bas:3828
        }
    } else {
        process.spin_cn = process.spin_target; // GEF.bas:3831
    }
    // GEF.bas:3833
    float const target = physics::ame2020(tables, minus(z, 2), minus(a, 4));
    float const cn = physics::ame2020(tables, z, a);
    process.eabsgs = static_cast<float>(
        (((static_cast<double>(process.p_e_exc) * mass_ratio) + static_cast<double>(target)) -
         static_cast<double>(cn)) +
        -0x1.C4B851EB851ECp+4);
    // GEF.bas:3835-3839: the C skips the block when `Eabsgs >= 0` (Sleep prints nothing).
    if (!(process.eabsgs >= 0.0F)) {
        print_line(process,
                   "<S> Alpha energy is too low. (E* of compound nucleus would be negativ.)");
        print_line(process, "    Press Enter key to leave GEF!");
        return false;
    }
    return true;
}

// GEF.bas:3698-3843: Spin_CN, Spin_target and the excitation energy above the ground state.
// QUIRK(Q-054): for ES and EM (Emode 3, 13) Spin_CN is not set here; it keeps what the last
// bin or the pre-pass of an earlier step wrote. False where BASIC ends (3835-3839).
bool set_excitation(ProcessState& process) {
    std::int64_t const emode = process.params.emode;
    // GEF.bas:3698-3700
    if (emode == 0) {
        process.spin_cn = process.p_i_rms_cn;
    }
    // GEF.bas:3703-3733
    if (fb::abs(emode) == 1) {
        set_fission_spin(process);
    }
    // GEF.bas:3736-3781
    if (fb::imod(emode, 10) == 2) {
        set_target_spin(process);
    }
    // GEF.bas:3785-3843 `Select Case Emode` (Case 3 and Case 13 do nothing)
    switch (emode) {
    case 0: {
        // GEF.bas:3787
        float const outer =
            barrier_value(physics::bftfb(*process.tables, static_cast<float>(process.p_z_cn),
                                         static_cast<float>(process.p_a_cn), 1));
        process.eabsgs = process.p_e_exc + outer;
        break;
    }
    case 1:
    case -1:
        process.eabsgs = process.p_e_exc; // GEF.bas:3789
        break;
    case 2:
        neutron_capture(process);
        break;
    case 12:
        proton_capture(process);
        break;
    case 22:
        return alpha_capture(process);
    default:
        break;
    }
    return true;
}

// GEF.bas:3844-3880: the energy checks and the lines before the pre-pass. False where BASIC ends
// (3869-3873).
bool check_energy(ProcessState& process) {
    // GEF.bas:3844-3848
    if (process.bfilein == 0) {
        dialogue_only("GEF.bas:3844-3848");
    }
    // GEF.bas:3849-3868: in batch mode (`If Bfilein Then` with an empty branch) nothing is
    // printed. The C skips the block when `Eabsgs <= 100`.
    // QUIRK(Q-055): no energy limit in batch mode; Emax_valid (GEF.bas:894) is never read.
    if (!(process.eabsgs <= 100.0F) && process.bfilein == 0) {
        dialogue_only("GEF.bas:3852-3866");
    }
    // GEF.bas:3869-3874: the C skips the block when `Eabsgs >= 0` (Sleep prints nothing).
    // QUIRK(Q-054): for ES and EM (Emode 3, 13) Eabsgs is not set by this step's set-up; the
    // check reads the value an earlier step or its pre-pass left.
    if (!(process.eabsgs >= 0.0F)) {
        print_line(process,
                   "<E> Input energy of the fissioning nucleus is below the ground state.");
        print_line(process, "    Press Enter key to leave GEF!");
        return false;
    }
    // GEF.bas:3876-3880
    print_line(process, " ");
    print_line(process, " ");
    print_line(process, "Please wait ... code is running.");
    print_line(process, " ");
    return true;
}

// GEF.bas:3949-3966: the energy threshold of multi-chance fission, Eexc_min_multi.
void set_multi_chance_threshold(ProcessState& process) {
    data::TableSet const& tables = *process.tables;
    std::int64_t const z = process.p_z_cn;
    std::int64_t const a = process.p_a_cn;
    if (process.params.emode == 1) {
        // GEF.bas:3951
        float const barrier =
            barrier_value(physics::bftf(tables, static_cast<float>(z), static_cast<float>(a), 5));
        process.params.eexc_min_multi = fb::max(barrier + -3.0F, 1.0F);
        return;
    }
    // GEF.bas:3954-3956, the calls in the order of the emitted C.
    float const proton_daughter = physics::ame2020(tables, minus(z, 1), minus(a, 1));
    float const cn_1 = physics::ame2020(tables, z, a);
    double const radius = std::pow(static_cast<double>(minus(a, 1)), 0x1.55553EF6B5D46p-2);
    float const proton_barrier = barrier_value(
        physics::bftf(tables, static_cast<float>(minus(z, 1)), static_cast<float>(minus(a, 1)), 1));
    float const neutron_daughter = physics::ame2020(tables, z, minus(a, 1));
    float const cn_2 = physics::ame2020(tables, z, a);
    float const neutron_barrier = barrier_value(
        physics::bftf(tables, static_cast<float>(z), static_cast<float>(minus(a, 1)), 1));
    float const neutron_threshold = ((neutron_daughter - cn_2) + neutron_barrier) + -3.0F;
    auto const proton_threshold =
        static_cast<float>(((static_cast<double>(proton_daughter - cn_1) +
                             ((static_cast<double>(minus(z, 1)) * 0x1.70A3D70A3D70Ap+0) /
                              ((radius * 0x1.p+1) + 0x1.p+1))) +
                            static_cast<double>(proton_barrier)) +
                           -0x1.8p+1);
    process.params.eexc_min_multi = fb::min(neutron_threshold, proton_threshold);
    // GEF.bas:3957
    process.params.eexc_min_multi = fb::max(process.params.eexc_min_multi, 1.0F);
}

// GEF.bas:3914-3972, the part M6 owns: the step's StepState, Fenhance, N_multi_sample, the
// threshold, probe P1b and the decision whether the pre-pass runs.
void decide_prepass(ProcessState& process, StepState& step) {
    std::int64_t const emode = process.params.emode;
    // GEF.bas:3914-3921: the Dims of the multi-chance block (Bmulti = 0, N_multi_sample = 0).
    step = StepState{};
    // GEF.bas:3922: the C skips the assignment when `Fenhance <> 0`.
    if (process.fenhance == 0.0) {
        process.fenhance = 1.0;
    }
    // GEF.bas:3926
    step.n_multi_sample = fb::d2l(std::sqrt(process.fenhance) * 0x1.86Ap+16);
    // GEF.bas:3947
    step.bmulti = 0;
    // GEF.bas:3948
    bool const multi_chance = (fb::imod(emode, 10) < 3 && emode >= 0) || emode == 13;
    if (!multi_chance) {
        // Probe P1b after GEF.bas:3947 for the channels that skip the block.
        if (process.probes != nullptr) {
            process.probes->step_threshold(process, step, false);
        }
        return;
    }
    set_multi_chance_threshold(process);
    // GEF.bas:3967
    bool const prepass = process.eabsgs >= process.params.eexc_min_multi || emode == 13;
    // Probe P1b after GEF.bas:3966.
    if (process.probes != nullptr) {
        process.probes->step_threshold(process, step, prepass);
    }
    if (prepass) {
        step.prepass = true;
        step.bmulti = 1; // GEF.bas:3972
    }
}

} // namespace

// GEF.bas:3499-3880 and 3914-3972, after the driver has set the step's energy and B_Error_On
// (3444-3497).
Flow set_up_step(ProcessState& process, InputRoundState& round, SequenceFileState& file,
                 StepState& step, WorkDir const& workdir) {
    // GEF.bas:3499-3540
    name_system(process, file);
    name_lmd_file(process, file);
    // GEF.bas:3542-3590
    if (!set_isomer(process)) {
        return Flow::Restart;
    }
    // GEF.bas:3593-3605
    print_cn_line(process);
    // GEF.bas:3607-3692
    if (!read_spectrum(process, round, workdir)) {
        return Flow::End;
    }
    // GEF.bas:3694-3696
    if (process.bfilein == -1) {
        process.fenhance = process.fenhance_global;
    }
    // GEF.bas:3698-3843
    if (!set_excitation(process)) {
        return Flow::End;
    }
    // GEF.bas:3844-3880
    if (!check_energy(process)) {
        return Flow::End;
    }
    // Probe P1, before GEF.bas:3882.
    if (process.probes != nullptr) {
        process.probes->step_setup(process, round, file);
    }
    // GEF.bas:3914-3972
    decide_prepass(process, step);
    return Flow::Proceed;
}

} // namespace gef::run
