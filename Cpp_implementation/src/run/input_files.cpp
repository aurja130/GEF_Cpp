// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "run/input_files.hpp"

#include "fbrt/array.hpp"
#include "fbrt/convert.hpp"
#include "fbrt/input.hpp"
#include "fbrt/strings.hpp"
#include "fbrt/text.hpp"
#include "params/parameter_files.hpp"
#include "run/probes.hpp"
#include "run/run_util.hpp"
#include "util/utilities.hpp"

#include <cstdint>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace gef::run {

namespace {

std::int64_t len_of(std::string_view s) {
    return static_cast<std::int64_t>(s.size());
}

// GEF.bas:3065, 3101: the first line printed when a spectrum file is not ES or EM.
void print_spectrum_channel_error(ProcessState& process) {
    print_line(process,
               "<E> Energy distribution from file only supported for options 'ES' and 'EM'.");
}

// `Ucase(Left(Chelp,n)) = "KEYWORD(" And Right(Chelp,1) = ")"`; the keyword includes its "(".
bool has_call_form(std::string_view chelp, std::string_view keyword) {
    return fb::ucase(fb::left(chelp, len_of(keyword))) == keyword && fb::right(chelp, 1) == ")";
}

// CC_Cut (util/utilities.hpp). The messages it writes are printed at once, as BASIC prints them.
void cut_fields(ProcessState& process, std::string_view in, std::string_view div,
                fb::Array<std::string, 1>& out, std::int64_t& n) {
    std::vector<std::string> messages;
    util::cc_cut(in, div, out, n, messages);
    print_lines(process, messages);
}

// GEF.bas:2919-2920, 2940-2941. The doubled ".lmd" is the BASIC name, kept as written.
void set_lmd_file(ProcessState& process, SequenceFileState& file) {
    file.cfileoutlmd = "$Events.lmd";
    process.cfileoutlmd_full = "out\\" + file.cfileoutlmd + ".lmd";
}

// GEF.bas:2923-2938 (LMD), 2944-2962 (LMD+): the output flags are set to 1. LMD+ also sets
// PXEdetails, PEnpost and PEgpost; LMD leaves them as they are, as BASIC does.
void set_lmd_flags(LmdFlags& lmd, bool with_prompt) {
    lmd.pz1 = 1;
    lmd.pz2 = 1;
    lmd.pa1pre = 1;
    lmd.pa2pre = 1;
    lmd.pa1post = 1;
    lmd.pa2post = 1;
    lmd.pi1 = 1;
    lmd.pi2 = 1;
    lmd.pdir = 1;
    lmd.pxe = 1;
    if (with_prompt) {
        lmd.pxedetails = 1;
    }
    lmd.pn1 = 1;
    lmd.pn2 = 1;
    lmd.ptkepre = 1;
    lmd.ptkepost = 1;
    lmd.pncn = 1;
    if (with_prompt) {
        lmd.penpost = 1;
        lmd.pegpost = 1;
    }
    lmd.pndel = 1;
}

// GEF.bas:2986-2991: `FIT(...)`.
void read_fit(ProcessState& process, SequenceFileState& file, std::string_view chelp) {
    process.b_fit = 1;
    file.b_error_on = 1;
    process.bplot = -1;
    print_part(process, "<I> Input ");
    print_part(process, chelp);
    print_line(process, " found on input file");
    process.c_fitoption = fb::ucase(fb::mid(chelp, 5, len_of(chelp) - 5));
}

// GEF.bas:2992-2995: `NITER(...)`.
void read_niter(ProcessState& process, std::string_view chelp) {
    print_part(process, "<I> Input ");
    print_part(process, chelp);
    print_line(process, " found on input file.");
    std::string const coptions = fb::mid(chelp, 7, len_of(chelp) - 7);
    process.n_iter = fb::d2l(fb::val(coptions));
}

// GEF.bas:2996-3028: `MODE(...)`. The keys are case-sensitive, as in the BASIC Select Case.
void read_mode(ProcessState& process, SequenceFileState& file, std::string_view chelp) {
    print_part(process, "<I> Input ");
    print_part(process, chelp);
    print_line(process, " found on input file.");
    std::string const coptions = fb::mid(chelp, 6, len_of(chelp) - 6);
    std::int64_t mode_number = -1;
    std::string_view text;
    if (coptions == "0" || coptions == "S0" || coptions == "L") {
        mode_number = 0;
        text = "the super-long mode.";
    } else if (coptions == "1" || coptions == "S1") {
        mode_number = 1;
        text = "the standard 1 mode.";
    } else if (coptions == "2" || coptions == "S2") {
        mode_number = 2;
        text = "the standard 2 mode.";
    } else if (coptions == "3" || coptions == "S3") {
        mode_number = 3;
        text = "the standard 3 mode.";
    } else if (coptions == "4" || coptions == "S4") {
        mode_number = 4;
        text = "Pb mode.";
    } else if (coptions == "5" || coptions == "S5") {
        mode_number = 5;
        text = "the mode near Z=36.";
    } else if (coptions == "6" || coptions == "S11") {
        mode_number = 6;
        text = "the S11 mode.";
    } else if (coptions == "7" || coptions == "S22") {
        mode_number = 7;
        text = "the S22 mode.";
    }
    file.i_mode_selected = mode_number;
    if (mode_number >= 0) {
        print_part(process, "   Calculation will be restricted to fission of ");
        print_line(process, text);
    } else {
        print_part(process, "<E> Selected mode ");
        print_part(process, coptions);
        print_line(process, " not defined.");
        print_line(process, "    Selection ignored.");
    }
}

// GEF.bas:2859-2980: `Select Case Ucase(Ccut(I))`. `item` is the cut item (its "(" is kept) and
// `cval` is the text inside the parentheses.
void read_option(ProcessState& process, SequenceFileState& file, WorkDir const& workdir,
                 std::string_view item, std::string_view cval) {
    auto const key = fb::ucase(item);
    if (key == "PLOT") {
        // GEF.bas:2860-2862
        process.bplot = -1;
        print_line(process, "      Plot of mass distribution will be shown.");
    } else if (key == "MYPARAMETERS") {
        // GEF.bas:2863-2870
        print_line(process, "<I> Option 'MyParameters' found on input file");
        if (workdir.exists("MyParameters.dat")) {
            // QUIRK(Q-018): MyParameters.dat is never applied. B_MyParameters is set here, but
            // MyparRead.bas is included only at GEF.bas:1017, so no code reads the file.
            process.params.b_myparameters = -1;
            print_line(process, "    User-defined parameter values will be used.");
        } else {
            print_line(process, "    File 'MyParameters.dat' not found.");
        }
    } else if (key == "LOCAL") {
        // GEF.bas:2871-2872
        file.clocal_file_option = "localon";
    } else if (key == "GLOBAL") {
        // GEF.bas:2873-2874
        file.clocal_file_option = "localoff";
    } else if (key == "NOSUPP") {
        // GEF.bas:2875-2876
        file.b_supp = 0;
    } else if (key == "ERR") {
        // GEF.bas:2877-2887
        file.b_error_on = 1;
        print_line(process, "<I> Option 'err' found on input file:");
        print_line(process, "    Calculation with perturbed parameters enabled.");
        print_line(process, "    Uncertainties of several fission quantities will be determined,");
        print_line(process, "    Correlations are calculated with the 'cor' option in addition.");
        print_line(process, "    Covariances are calculated with the 'cov' option in addition.");
        print_line(process,
                   "    Output of perturbed calculations with the 'ptb' option in addition.");
        if (file.b_endf == 1) {
            print_line(process,
                       "    Random files in ENDF format are produced with the 'random' option.");
        }
    } else if (key == "DPARFAC(") {
        // GEF.bas:2888-2892
        // QUIRK(candidate): D_Par_Fac takes effect only from later rounds (widths set before).
        // BASIC computes the widths before it sets D_Par_Fac here (GEF.bas:2889).
        process.params.d_par_fac = static_cast<float>(fb::val(cval));
        print_part(process, "<I> Factor ");
        process.console.print(process.params.d_par_fac, fb::PrintEnd::None);
        print_line(process, " for scaling the variation of");
        print_line(process, "    the perturbed parameters found on input file.");
        print_line(process, "<W> Sorry, this option is not yet available!!!!!!!");
    } else if (key == "PTB") {
        // GEF.bas:2893-2897
        print_line(process, "<I> Option 'ptb' found on input file:");
        file.b_error_on = 1;
        file.brec = 1;
        print_line(process,
                   "    Extended output of perturbed-parameter calculations in /out/xxx.ptb file.");
    } else if (key == "RANDOM") {
        // GEF.bas:2898-2907. `#Ifdef B_delayed` is defined (GEF.bas:427), so its branch is taken.
        print_line(process, "<I> Option 'random' found on input file:");
        file.b_endf = 1;
        file.b_error_on = 1;
        file.b_random_on = 1;
        print_line(process, "    Production of random files in ENDF format enabled.");
    } else if (key == "COV") {
        // GEF.bas:2908-2912
        file.b_error_on = 1;
        file.bcov = 1;
        print_line(process, "<I> Option 'cov' found on input file:");
        print_line(process, "    Covariances will be written to output file.");
    } else if (key == "COR") {
        // GEF.bas:2913-2917
        file.b_error_on = 1;
        file.bcor = 1;
        print_line(process, "<I> Option 'cor' found on input file:");
        print_line(process, "    Correlations coefficients will be written to output file.");
    } else if (key == "LMD") {
        // GEF.bas:2918-2938
        set_lmd_file(process, file);
        print_line(process, "<I> Option 'lmd' found on input file:");
        print_line(process, "    List-mode output enabled.");
        set_lmd_flags(process.lmd, false);
    } else if (key == "LMD+") {
        // GEF.bas:2939-2962
        set_lmd_file(process, file);
        print_line(process, "<I> Option 'lmd+' found on input file:");
        print_line(process, "    List-mode output, including prompt neutrons and gammas, enabled.");
        set_lmd_flags(process.lmd, true);
    } else if (key == "NEO") {
        // GEF.bas:2963-2965
        process.params.eoscale = 0.0F;
        print_line(process, "<I> Even-odd effect in Z and N at scission suppressed.");
    } else if (key == "ENDF") {
        // GEF.bas:2970-2974. `#if defined(B_delayed)` is true, so its branch is taken.
        file.b_endf = 1;
        file.b_error_on = 1;
        print_line(process, "<I> Output files with FY in ENDF format will be produced.");
    } else {
        // GEF.bas:2978-2980. The NOSORT case (GEF.bas:2966-2969) is inside `/' ... '/`, so it is
        // not a case and falls through to this branch.
        print_part(process, "<E> Option ");
        print_part(process, item);
        print_line(process, " found on input file is not supported.");
        print_line(process,
                   "    Possible options are: local, global, err, dparfac(..), ptb, cov, cor, "
                   "lmd, neo, ENDF, random.");
    }
}

// GEF.bas:2849-2982: `OPTIONS(item, item, ...)`. The items are cut at ','.
void read_options(ProcessState& process, InputRoundState& round, SequenceFileState& file,
                  WorkDir const& workdir) {
    // GEF.bas:2850-2853
    std::string const coptions = fb::mid(round.chelp, 9, len_of(round.chelp) - 9);
    round.n_values = util::cc_count(coptions, ",");
    fb::Array<std::string, 1> ccut;
    ccut.redim({fb::Bounds{0, round.n_values}});
    cut_fields(process, coptions, ",", ccut, round.n_values);
    // GEF.bas:2848 `Dim As String Coptions,Cval` is per line, so Cval starts empty.
    std::string cval;
    for (std::int64_t i = 1; i <= round.n_values; i = fb::add(i, std::int64_t{1})) {
        std::string& item = ccut(i);
        // GEF.bas:2855-2858. The "(" stays in the item, as the BASIC Mid keeps it.
        auto const lparen = fb::instr(item, "(");
        auto const rparen = fb::instr(item, ")");
        if (lparen > 0 && rparen > 0) {
            cval = fb::mid(item, lparen + 1, rparen - lparen - 1);
            item = fb::mid(item, 1, lparen);
        }
        read_option(process, file, workdir, item, cval);
    }
}

// GEF.bas:3034-3070: a data line `Z, A, CE`, or `Z, A1-A2[+step], CE` for one system per A.
// Returns false where BASIC ends the program.
bool read_system_line(ProcessState& process, InputRoundState& round) {
    // GEF.bas:3034-3038
    fb::Array<std::string, 1> ccut;
    ccut.redim({fb::Bounds{0, 3}});
    std::int64_t count = 3;
    cut_fields(process, round.chelp, ",", ccut, count);
    ccut(3) = fb::trim(ccut(3));
    ccut(3) = fb::trim(ccut(3), "\"");
    // GEF.bas:3039-3055
    auto const dash = fb::instr(ccut(2), "-");
    if (dash > 0) {
        auto const plus = fb::instr(ccut(2), "+");
        round.i_first = fb::d2l(fb::val(fb::mid(ccut(2), 1, dash - 1)));
        if (plus > 0) {
            round.i_last = fb::d2l(fb::val(fb::mid(ccut(2), dash + 1, plus - dash - 1)));
            round.i_step = fb::d2l(fb::val(fb::mid(ccut(2), plus + 1)));
        } else {
            round.i_last = fb::d2l(fb::val(fb::mid(ccut(2), dash + 1)));
            round.i_step = 1;
        }
        std::int64_t const last = round.i_last;
        std::int64_t const step = round.i_step;
        for (std::int64_t i = round.i_first; step >= 0 ? i <= last : i >= last;
             i = fb::add(i, step)) {
            // QUIRK(candidate): S_par(Iline) is written with no bound check in BASIC (3050).
            // The port throws (fb::Array) past the end of S_par.
            process.iline = fb::add(process.iline, std::int64_t{1});
            auto& entry = process.s_par(process.iline);
            entry.z = fb::d2l(fb::val(ccut(1)));
            entry.a = i;
            entry.z_double = 0;
            entry.ce = ccut(3);
        }
    } else {
        // GEF.bas:3057-3061
        // QUIRK(candidate): S_par(Iline) is written with no bound check in BASIC (3057).
        process.iline = fb::add(process.iline, std::int64_t{1});
        auto& entry = process.s_par(process.iline);
        entry.z = fb::d2l(fb::val(ccut(1)));
        entry.a = fb::d2l(fb::val(ccut(2)));
        entry.z_double = 0;
        entry.ce = ccut(3);
    }
    // GEF.bas:3063-3070
    if (!process.c_espectrum1.empty() && ccut(3) != "ES" && ccut(3) != "EM") {
        print_spectrum_channel_error(process);
        print_line(process, "Press ENTER to leave GEF!");
        return false;
    }
    return true;
}

// GEF.bas:3071-3109: `Z, A, Z_double, A_double, E or "spectrum", CE`: two systems on one line.
// Returns false where BASIC ends the program.
bool read_pair_line(ProcessState& process, InputRoundState& round, WorkDir const& workdir) {
    // GEF.bas:3072-3081
    if (round.n_e_values > 1) {
        print_line(process, "<E> Calculation of correlations between two systems is supported");
        print_line(process, "    for only one energy value (or E* spectrum) in the input file.");
        print_line(process, "<H> As a work-around, you may provide several input files");
        print_line(process, "    with only one energy (or spectrum) each and write the list");
        print_line(process, "    of input files into the file 'file.in'.");
        print_line(process, "Press Enter key to leave GEF!");
        return false;
    }
    // GEF.bas:3083-3086
    fb::Array<std::string, 1> ccut;
    ccut.redim({fb::Bounds{0, 6}});
    std::int64_t count = 6;
    cut_fields(process, round.chelp, ",", ccut, count);
    ccut(6) = fb::trim(ccut(6));
    ccut(6) = fb::trim(ccut(6), "\"");
    // GEF.bas:3087-3091
    // QUIRK(candidate): S_par(Iline) is written with no bound check in BASIC (3087).
    process.iline = fb::add(process.iline, std::int64_t{1});
    auto& entry = process.s_par(process.iline);
    entry.z = fb::d2l(fb::val(ccut(1)));
    entry.a = fb::d2l(fb::val(ccut(2)));
    entry.z_double = fb::d2l(fb::val(ccut(3)));
    entry.a_double = fb::d2l(fb::val(ccut(4)));
    // GEF.bas:3092-3108
    if (fb::left(ccut(5), 1) == "\"") {
        process.c_espectrum2 = fb::trim(ccut(5), "\"");
        if (!workdir.exists(process.c_espectrum2)) {
            print_part(process, "<S> File ");
            print_part(process, process.c_espectrum2);
            print_line(process, " does not exist.");
            print_line(process, "Press ENTER key to leave GEF!");
            return false;
        }
        if (ccut(6) != "ES" && ccut(6) != "EM") {
            print_spectrum_channel_error(process);
            print_line(process, "Press Enter key to leave GEF!");
            return false;
        }
    } else {
        // GEF.bas:3107
        entry.e_double = static_cast<float>(fb::val(ccut(5)));
    }
    // GEF.bas:3109
    entry.ce = ccut(6);
    return true;
}

// GEF.bas:3032-3112: one data line, dispatched on its number of comma-separated fields.
// Returns false where BASIC ends the program.
bool read_data_line(ProcessState& process, InputRoundState& round, WorkDir const& workdir) {
    // GEF.bas:3033
    round.n_values = util::cc_count(round.chelp, ",");
    if (round.n_values == 3) {
        return read_system_line(process, round);
    }
    if (round.n_values == 6) {
        return read_pair_line(process, round, workdir);
    }
    // GEF.bas:3111
    print_part(process, "<E> Number of data not matching in ");
    print_part(process, round.chelp);
    print_line(process, ".");
    return true;
}

// GEF.bas:2779-2826: the energy line. A quoted name is a spectrum file (2780-2787). Otherwise it is
// a list of energies, each with an optional "/spin" part (2788-2825). Returns false where BASIC
// ends the program.
bool read_energy_table(ProcessState& process, InputRoundState& round, WorkDir const& workdir) {
    // GEF.bas:2779
    process.c_espectrum1 = "";
    // GEF.bas:2780-2787
    // QUIRK(candidate): a spectrum energy line keeps the earlier Energy_Table and N_E_values.
    // En_min and En_max keep theirs too; the numeric branch (2788-2825) is skipped.
    if (fb::left(round.c_energy_table, 1) == "\"") {
        process.c_espectrum1 = fb::trim(round.c_energy_table, "\"");
        if (!workdir.exists(process.c_espectrum1)) {
            print_part(process, "<S> File ");
            print_part(process, process.c_espectrum1);
            print_line(process, " does not exist.");
            print_line(process, "Press Enter key to leave GEF!");
            return false;
        }
        return true;
    }
    // GEF.bas:2789-2793
    auto const colon = fb::instr(round.c_energy_table, ":");
    if (colon > 0) {
        // GEF.bas:2791 `Cint(...)` of the text before the colon; fbc converts it with fb_VALLNG.
        process.i_first_e_step = fb::vallng(fb::left(round.c_energy_table, colon - 1));
        round.c_energy_table = fb::mid(round.c_energy_table, colon + 1);
    }
    // GEF.bas:2794-2798
    round.n_e_values = util::cc_count(round.c_energy_table, ",");
    round.energy_table.redim({fb::Bounds{0, round.n_e_values}});
    round.spin_table.redim({fb::Bounds{0, round.n_e_values}});
    fb::Array<std::string, 1> ccut;
    ccut.redim({fb::Bounds{0, round.n_e_values}});
    cut_fields(process, round.c_energy_table, ",", ccut, round.n_e_values);
    // GEF.bas:2799-2823
    for (std::int64_t i = 1; i <= round.n_e_values; i = fb::add(i, std::int64_t{1})) {
        // GEF.bas:2800-2811: the average spin is read only where BASIC allows it (2801).
        auto const slash = fb::instr(ccut(i), "/");
        if (slash > 0) {
            // QUIRK(candidate): the spin check (GEF.bas:2801) reads a stale Emode. In batch mode
            // Emode is set only by the system loop, from each system line's channel (GEF.bas:
            // 3227-3277, after the parse and the done.ctl and U_Valid skips), so this is the
            // value of the last earlier system line that got there, or the start value 1
            // (GEF.bas:898).
            if (fb::abs(process.params.emode) > 1 && process.params.emode != 3) {
                print_line(process, "<E> Error in input line:");
                print_line(process, round.c_energy_table);
                print_line(process, "Input of average spin values are only supported for options "
                                    "'CN fission' or 'ES'.");
                print_line(process, "Press Enter key to leave GEF!");
                return false;
            }
            round.spin_table(i) = static_cast<float>(fb::val(fb::mid(ccut(i), slash + 1)));
            ccut(i) = fb::left(ccut(i), slash - 1);
        }
        // GEF.bas:2812
        round.energy_table(i) = static_cast<float>(fb::val(ccut(i)));
        // GEF.bas:2813-2822. fbc tests `not (E(i) > E(i-1))` where BASIC has `E(i) <= E(i-1)`.
        if (i > 1 && !(round.energy_table(i) > round.energy_table(i - 1))) {
            print_line(process, "<E> Error in input line:");
            print_part(process, round.c_energy_table);
            print_line(process, ".");
            print_line(process, "Energy values in input file must be ascending.");
            print_line(process, "Press Enter key to leave GEF!");
            return false;
        }
    }
    // GEF.bas:2824-2825
    // QUIRK(candidate): with N_E_values 0, GEF.bas:2824 reads Energy_Table(1), past its bounds.
    // Redim Energy_Table(0) is calloc-cleared: BASIC reads +0.0F (capture edge-e_energy_empty).
    if (round.n_e_values < 1) {
        process.en_min = 0.0F;
    } else {
        process.en_min = round.energy_table(1);
    }
    process.en_max = round.energy_table(round.n_e_values);
    return true;
}

// GEF.bas:2827-2842: the per-file state is reset before the lines of the file are read. BASIC
// lines 2830-2833 are comments. CFileoutlmd_full is not reset, as in BASIC.
// QUIRK(candidate): the reset does not cover EOscale, D_Par_Fac, B_MyParameters, Bplot, the LMD
// flags, Cfileoutlmd_full, N_iter, C_Fitoption or B_Fit, and it clears B_Error_On, which FIT in
// file.in sets.
void reset_file_options(ProcessState& process, SequenceFileState& file) {
    process.iline = 0;
    file.b_error_on = 0;
    file.brec = 0;
    file.bcov = 0;
    file.bcor = 0;
    file.b_supp = 1;
    file.b_endf = 0;
    file.b_random_on = 0;
    file.cfileoutlmd = "";
    file.clocal_file_option = "localoff";
    file.i_mode_selected = -1;
}

// GEF.bas:2843-3118: the `Do Until EOF(Ffilein)` loop over the lines of one sequence file.
// Returns false where BASIC ends the program. END leaves the loop and returns true.
bool read_sequence_lines(ProcessState& process, InputRoundState& round, SequenceFileState& file,
                         WorkDir const& workdir, fb::InputFile& input) {
    while (!input.eof()) {
        // QUIRK(candidate): BASIC's Do Until EOF hangs once the data is used up; the port throws.
        if (input.data_at_end()) {
            throw params::GefHangs{
                "GEF.bas:2843: Do Until EOF(Ffilein) never ends: the data is used up"};
        }
        // GEF.bas:2844-2845
        round.chelp = fb::trim(input.line_input());
        // GEF.bas:2846
        if (fb::left(round.chelp, 1) != "'" && !round.chelp.empty()) {
            // GEF.bas:2849-2982 (OPTIONS), 2986-2991 (FIT), 2992-2995 (NITER), 2996-3028 (MODE)
            if (has_call_form(round.chelp, "OPTIONS(")) {
                read_options(process, round, file, workdir);
            } else if (has_call_form(round.chelp, "FIT(")) {
                read_fit(process, file, round.chelp);
            } else if (has_call_form(round.chelp, "NITER(")) {
                read_niter(process, round.chelp);
            } else if (has_call_form(round.chelp, "MODE(")) {
                read_mode(process, file, round.chelp);
            } else if (fb::ucase(round.chelp) == "END") {
                // GEF.bas:3029-3031
                print_part(process, "Input after ***");
                print_part(process, round.chelp);
                print_line(process, "*** skipped.");
                break;
            } else if (!read_data_line(process, round, workdir)) {
                return false;
            }
        } else if (!round.chelp.empty()) {
            // GEF.bas:3116
            print_part(process, "Input ***");
            print_part(process, round.chelp);
            print_line(process, "*** skipped.");
        }
    }
    return true;
}

// GEF.bas:2737-2760: a file.in line that is neither FIT nor NITER(...). Returns false where
// BASIC leaves the loop (`Exit Do`: the 1000th entry, or END).
bool read_file_in_entry(ProcessState& process, InputRoundState& round) {
    // GEF.bas:2737-2742
    round.nfilein = fb::add(round.nfilein, std::int64_t{1});
    if (round.nfilein >= 1000) {
        // The 1000th name is never stored: Nfilein is set to 1000 and Cfilein(1000) keeps its
        // initial "", so the sequence loop stops at that entry.
        print_line(process, "<E> Maximum number of input files reached.");
        round.nfilein = 1000;
        return false;
    }
    // GEF.bas:2743-2745
    if (fb::ucase(round.chelp) == "END") {
        round.nfilein = fb::sub(round.nfilein, std::int64_t{1});
        return false;
    }
    // GEF.bas:2747
    if (fb::left(round.chelp, 1) == "'") {
        // GEF.bas:2757-2758
        round.nfilein = fb::sub(round.nfilein, std::int64_t{1});
        print_part(process, "Input ***");
        print_part(process, round.chelp);
        print_line(process, "*** skipped.");
        return true;
    }
    // GEF.bas:2748-2754. Names of 2 characters or fewer skip the comment cut, the RTRIM and the
    // quote removal below; they are stored as read after Trim.
    if (len_of(round.chelp) > 2) {
        // GEF.bas:2749
        auto const quote = fb::instr(round.chelp, "'");
        if (quote > 0) {
            round.chelp = fb::mid(round.chelp, 1, quote - 1);
        }
        // GEF.bas:2750
        round.chelp = fb::rtrim(round.chelp);
        // GEF.bas:2751-2753
        if (fb::left(round.chelp, 1) == "\"" && fb::right(round.chelp, 1) == "\"") {
            round.chelp = fb::mid(round.chelp, 2, len_of(round.chelp) - 2);
        }
    }
    // GEF.bas:2755
    round.cfilein(round.nfilein) = round.chelp;
    return true;
}

} // namespace

// GEF.bas:2699-2763 (`If Bfilein Then` through `Close #Ffilein`).
void read_file_in(ProcessState& process, InputRoundState& round, SequenceFileState& file,
                  WorkDir const& workdir) {
    // GEF.bas:2699 `If Bfilein Then`. Bfilein is -1 when file.in exists (GEF.bas:1821-1822).
    if (process.bfilein == 0) {
        return;
    }
    // GEF.bas:2700-2701
    print_line(process, "File 'file.in' found.");
    print_line(process, "Manual input suspended, input will be taken from file.");
    // GEF.bas:2718-2719 (the `#ifdef __FB_WIN32__` lines 2710-2716 are not in the Linux C)
    print_part(process, "Number of running processes:");
    process.console.print(process.i_thread, fb::PrintEnd::Newline);
    print_part(process, "Maximum number of parallel processes:");
    process.console.print(process.i_thread_max, fb::PrintEnd::Newline);
    // GEF.bas:2721
    process.bplot = 0;
    // GEF.bas:2722-2723 `Open "file.in" for input`: the file is read whole.
    auto contents = workdir.read("file.in");
    if (!contents) {
        // Unreachable unless file.in changes between the two checks: Bfilein is -1 only when
        // WorkDir::exists("file.in") was true (GEF.bas:1821), and "file.in" has no backslash,
        // so read() opens the same file.
        throw std::logic_error("GEF.bas:2723: file.in was found but cannot be opened");
    }
    fb::InputFile input{std::move(*contents)};
    // GEF.bas:2724 `Do Until EOF(Ffilein)`
    while (!input.eof()) {
        // GEF.bas:2725-2726
        round.chelp = input.line_input();
        round.chelp = fb::trim(round.chelp);
        if (fb::ucase(round.chelp) == "FIT") {
            // GEF.bas:2727-2731 (2732 is a comment)
            print_line(process, "<I> Fit option specified in file.in.");
            process.b_fit = 1;
            file.b_error_on = 1;
            process.bplot = -1;
        } else if (has_call_form(round.chelp, "NITER(")) {
            // GEF.bas:2733-2735
            print_part(process, "<I> Input ");
            print_part(process, round.chelp);
            print_line(process, " found on file.in.");
            process.n_iter = fb::d2l(fb::val(fb::mid(round.chelp, 7, len_of(round.chelp) - 7)));
        } else if (!read_file_in_entry(process, round)) {
            break;
        }
    }
    // GEF.bas:2762
    if (round.nfilein == 0) {
        print_line(process, "No file with input data specified in file.in.");
    }
    // GEF.bas:2763 `Close #Ffilein`: nothing to release, the input is an in-memory copy.
}

// GEF.bas:2768-3133: the body of `For Ifilein`. The caller owns the loop and sets round.ifilein.
Flow read_sequence_file(ProcessState& process, InputRoundState& round, SequenceFileState& file,
                        WorkDir const& workdir) {
    // GEF.bas:2769 `If Nfilein > 0`. The Else branch is GEF.bas:3129-3132.
    if (round.nfilein <= 0) {
        process.bfilein = 0;
        process.en_min = process.p_e_exc;
        process.en_max = process.p_e_exc;
        return Flow::Proceed;
    }
    // GEF.bas:2770-2772
    print_line(process, " ");
    print_part(process, "Sequence of nuclei given in ");
    print_part(process, round.cfilein(round.ifilein));
    print_line(process, " will be calculated!");
    process.bfilein = -1;
    // GEF.bas:2775 `If Fileexists(...)`. The Else branch is GEF.bas:3121-3125.
    std::string const name = round.cfilein(round.ifilein);
    if (!workdir.exists(name)) {
        print_part(process, "<S> File ");
        print_part(process, name);
        print_line(process, " not found.");
        print_line(process, "Press ENTER key to leave GEF!");
        return Flow::End;
    }
    // GEF.bas:2776 `Open Cfilein(Ifilein) for input`: the file is read whole.
    auto contents = workdir.read(name);
    // exists() converts no backslash and read() does. So this throw is reached only when a file
    // literally named with a backslash exists while its converted name does not, or when the file
    // changes between the two checks. BASIC would read a file that failed to open; not ported.
    if (!contents) {
        throw std::logic_error("GEF.bas:2776: a sequence file was found but cannot be opened");
    }
    fb::InputFile input{std::move(*contents)};
    // GEF.bas:2777-2778
    process.fenhance_global = input.input_double();
    round.c_energy_table = input.line_input();
    // GEF.bas:2779-2826
    if (!read_energy_table(process, round, workdir)) {
        return Flow::End;
    }
    // GEF.bas:2827-2842
    reset_file_options(process, file);
    // GEF.bas:2843-3118
    if (!read_sequence_lines(process, round, file, workdir, input)) {
        return Flow::End;
    }
    // GEF.bas:3119-3128
    process.iline_tot = process.iline;
    process.fenhance = process.fenhance_global;
    if (process.probes != nullptr) {
        process.probes->sequence_file(process, round, file);
    }
    return Flow::Proceed;
}

} // namespace gef::run
