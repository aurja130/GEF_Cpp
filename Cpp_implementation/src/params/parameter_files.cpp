// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "params/parameter_files.hpp"

#include "fbrt/array.hpp"
#include "fbrt/format.hpp"
#include "fbrt/input.hpp"
#include "fbrt/strings.hpp"
#include "fbrt/text.hpp"
#include "util/utilities.hpp"

#include <array>
#include <cstdint>
#include <fstream>
#include <iterator>
#include <string_view>
#include <system_error>

namespace gef::params {

namespace {

using fb::PrintEnd;

// One `Case "<KEY>" : <variable> = Valpar` of ReadParameters.mac:23-202, in source order.
// R_supp_S1..S3 (GEF.bas:794) are no nominal parameters: GEF.bas:6649-6651 sets all three
// before any statement reads them, so what Fitpar.dat assigns is never observable; the keys are
// accepted (no "not defined" message) and the values dropped.
struct FitKey {
    std::string_view key;
    float Parameters::* member;
};

std::array<FitKey, 87> const fit_keys{{
    FitKey{.key = "CHISQR_FIT_MIN",
           .member = &Parameters::chisqr_fit_min},                       // ReadParameters.mac:24-25
    FitKey{.key = "_P_DZ_MEAN_S1", .member = &Parameters::p_dz_mean_s1}, // ReadParameters.mac:26-27
    FitKey{.key = "_P_CORR_S1", .member = &Parameters::p_corr_s1},       // ReadParameters.mac:28-29
    FitKey{.key = "_P_DZ_MEAN_S2", .member = &Parameters::p_dz_mean_s2}, // ReadParameters.mac:30-31
    FitKey{.key = "_P_DZ_MEAN_S3", .member = &Parameters::p_dz_mean_s3}, // ReadParameters.mac:32-33
    FitKey{.key = "_P_DZ_MEAN_S4", .member = &Parameters::p_dz_mean_s4}, // ReadParameters.mac:34-35
    FitKey{.key = "_P_DZ_MEAN_SL5",
           .member = &Parameters::p_dz_mean_sl5},                        // ReadParameters.mac:36-37
    FitKey{.key = "_P_DZ_MEAN_S5", .member = &Parameters::p_dz_mean_s5}, // ReadParameters.mac:38-39
    FitKey{.key = "_P_Z_CURV_S1", .member = &Parameters::p_z_curv_s1},   // ReadParameters.mac:40-41
    FitKey{.key = "ZC_MODE_SL5", .member = &Parameters::zc_mode_sl5},    // ReadParameters.mac:42-43
    FitKey{.key = "P_Z_CURVMOD_S1",
           .member = &Parameters::p_z_curvmod_s1},                     // ReadParameters.mac:44-45
    FitKey{.key = "_P_Z_CURV_S2", .member = &Parameters::p_z_curv_s2}, // ReadParameters.mac:46-47
    FitKey{.key = "P_Z_CURVMOD_S2",
           .member = &Parameters::p_z_curvmod_s2}, // ReadParameters.mac:48-49
    FitKey{.key = "FMOD_SLOPE_S2",
           .member = &Parameters::fmod_slope_s2},                      // ReadParameters.mac:50-51
    FitKey{.key = "_P_Z_CURV_S3", .member = &Parameters::p_z_curv_s3}, // ReadParameters.mac:52-53
    FitKey{.key = "P_Z_CURVMOD_S3",
           .member = &Parameters::p_z_curvmod_s3},                     // ReadParameters.mac:54-55
    FitKey{.key = "_P_Z_CURV_S4", .member = &Parameters::p_z_curv_s4}, // ReadParameters.mac:56-57
    FitKey{.key = "P_Z_CURVMOD_S4",
           .member = &Parameters::p_z_curvmod_s4},                     // ReadParameters.mac:58-59
    FitKey{.key = "_P_Z_CURV_S5", .member = &Parameters::p_z_curv_s5}, // ReadParameters.mac:60-61
    FitKey{.key = "P_Z_CURVMOD_S5",
           .member = &Parameters::p_z_curvmod_s5},                       // ReadParameters.mac:62-63
    FitKey{.key = "_P_Z_CURV_SL5", .member = &Parameters::p_z_curv_sl5}, // ReadParameters.mac:64-65
    FitKey{.key = "_PZ_S3_OLAP_POS",
           .member = &Parameters::pz_s3_olap_pos}, // ReadParameters.mac:68-69
    FitKey{.key = "_PZ_S3_OLAP_CURV",
           .member = &Parameters::pz_s3_olap_curv},                      // ReadParameters.mac:70-71
    FitKey{.key = "_S2LEFTMOD", .member = &Parameters::s2leftmod},       // ReadParameters.mac:72-73
    FitKey{.key = "_P_A_WIDTH_S2", .member = &Parameters::p_a_width_s2}, // ReadParameters.mac:74-75
    FitKey{.key = "_DELTA_S0", .member = &Parameters::delta_s0},         // ReadParameters.mac:76-77
    FitKey{.key = "_P_SHELL_S1", .member = &Parameters::p_shell_s1},     // ReadParameters.mac:78-79
    FitKey{.key = "_P_SHELL_S2", .member = &Parameters::p_shell_s2},     // ReadParameters.mac:80-81
    FitKey{.key = "_P_SHELL_S3", .member = &Parameters::p_shell_s3},     // ReadParameters.mac:82-83
    FitKey{.key = "_P_SHELL_S4", .member = &Parameters::p_shell_s4},     // ReadParameters.mac:84-85
    FitKey{.key = "_P_SHELL_SL5", .member = &Parameters::p_shell_sl5},   // ReadParameters.mac:86-87
    FitKey{.key = "_P_SHELL_S5", .member = &Parameters::p_shell_s5},     // ReadParameters.mac:88-89
    FitKey{.key = "P_S5_MOD", .member = &Parameters::p_s5_mod},          // ReadParameters.mac:90-91
    FitKey{.key = "ETHRESHSUPPS1",
           .member = &Parameters::ethreshsupps1},                       // ReadParameters.mac:92-93
    FitKey{.key = "ESIGSUPPS1", .member = &Parameters::esigsupps1},     // ReadParameters.mac:94-95
    FitKey{.key = "LEVEL_S11", .member = &Parameters::level_s11},       // ReadParameters.mac:96-97
    FitKey{.key = "SHELL_FADING", .member = &Parameters::shell_fading}, // ReadParameters.mac:98-99
    FitKey{.key = "_DE_DEFO_S1", .member = &Parameters::de_defo_s1}, // ReadParameters.mac:100-101
    FitKey{.key = "_DE_DEFO_S2", .member = &Parameters::de_defo_s2}, // ReadParameters.mac:102-103
    FitKey{.key = "_DE_DEFO_S3", .member = &Parameters::de_defo_s3}, // ReadParameters.mac:104-105
    FitKey{.key = "_DE_DEFO_S4", .member = &Parameters::de_defo_s4}, // ReadParameters.mac:106-107
    FitKey{.key = "_DE_DEFO_S5", .member = &Parameters::de_defo_s5}, // ReadParameters.mac:108-109
    FitKey{.key = "_BETAL0", .member = &Parameters::betal0},         // ReadParameters.mac:110-111
    FitKey{.key = "_BETAL1", .member = &Parameters::betal1},         // ReadParameters.mac:112-113
    FitKey{.key = "_BETAH0", .member = &Parameters::betah0},         // ReadParameters.mac:114-115
    FitKey{.key = "_BETAH1", .member = &Parameters::betah1},         // ReadParameters.mac:116-117
    FitKey{.key = "_DBETA_S3", .member = &Parameters::dbeta_s3},     // ReadParameters.mac:118-119
    FitKey{.key = "_ECOLLFRAC", .member = &Parameters::ecollfrac},   // ReadParameters.mac:120-121
    FitKey{.key = "TCOLLFRAC", .member = &Parameters::tcollfrac},    // ReadParameters.mac:122-123
    FitKey{.key = "TCOLLMIN", .member = &Parameters::tcollmin},      // ReadParameters.mac:124-125
    FitKey{.key = "TFCOLL", .member = &Parameters::tfcoll},          // ReadParameters.mac:126-127
    FitKey{.key = "_EDISSFRAC", .member = &Parameters::edissfrac},   // ReadParameters.mac:128-129
    FitKey{.key = "KAPPA", .member = &Parameters::kappa},            // ReadParameters.mac:130-131
    FitKey{.key = "EPOT_SHIFT", .member = &Parameters::epot_shift},  // ReadParameters.mac:132-133
    FitKey{.key = "_T_LOW_S1", .member = &Parameters::t_low_s1},     // ReadParameters.mac:134-135
    FitKey{.key = "_T_LOW_S2", .member = &Parameters::t_low_s2},     // ReadParameters.mac:136-137
    FitKey{.key = "_T_LOW_S3", .member = &Parameters::t_low_s3},     // ReadParameters.mac:138-139
    FitKey{.key = "_T_LOW_S4", .member = &Parameters::t_low_s4},     // ReadParameters.mac:140-141
    FitKey{.key = "_T_LOW_S5", .member = &Parameters::t_low_s5},     // ReadParameters.mac:142-143
    FitKey{.key = "_T_LOW_SL", .member = &Parameters::t_low_sl},     // ReadParameters.mac:144-145
    FitKey{.key = "T_LOW_S11", .member = &Parameters::t_low_s11},    // ReadParameters.mac:146-147
    FitKey{.key = "_P_ATT_POL", .member = &Parameters::p_att_pol},   // ReadParameters.mac:148-149
    FitKey{.key = "_P_ATT_REL", .member = &Parameters::p_att_rel},   // ReadParameters.mac:150-151
    FitKey{.key = "_POLARADD", .member = &Parameters::polaradd},     // ReadParameters.mac:152-153
    FitKey{.key = "ESHIFTSASCI_INTR",
           .member = &Parameters::eshiftsasci_intr}, // ReadParameters.mac:154-155
    FitKey{.key = "ESHIFTSASCI_COLL",
           .member = &Parameters::eshiftsasci_coll},              // ReadParameters.mac:156-157
    FitKey{.key = "SIGDEFO", .member = &Parameters::sigdefo},     // ReadParameters.mac:158-159
    FitKey{.key = "SIGDEFO_0", .member = &Parameters::sigdefo_0}, // ReadParameters.mac:160-161
    FitKey{.key = "SIGDEFO_SLOPE",
           .member = &Parameters::sigdefo_slope},                     // ReadParameters.mac:162-163
    FitKey{.key = "SIGENECK", .member = &Parameters::sigeneck},       // ReadParameters.mac:164-165
    FitKey{.key = "EEXCSIGREL", .member = &Parameters::eexcsigrel},   // ReadParameters.mac:166-167
    FitKey{.key = "_HOMPOL", .member = &Parameters::hompol},          // ReadParameters.mac:168-169
    FitKey{.key = "DNECK", .member = &Parameters::dneck},             // ReadParameters.mac:170-171
    FitKey{.key = "PZ_EO_SYMM", .member = &Parameters::pz_eo_symm},   // ReadParameters.mac:172-174
    FitKey{.key = "PN_EO_SYMM", .member = &Parameters::pn_eo_symm},   // ReadParameters.mac:175-177
    FitKey{.key = "R_EO_THRESH", .member = &Parameters::r_eo_thresh}, // ReadParameters.mac:178-180
    FitKey{.key = "R_EO_SIGMA", .member = &Parameters::r_eo_sigma},   // ReadParameters.mac:181-182
    FitKey{.key = "R_EO_MAX", .member = &Parameters::r_eo_max},       // ReadParameters.mac:183-184
    FitKey{.key = "EOSCALE", .member = &Parameters::eoscale},         // ReadParameters.mac:185-186
    FitKey{.key = "POLARFAC", .member = &Parameters::polarfac},       // ReadParameters.mac:187-188
    FitKey{.key = "T_POL_RED", .member = &Parameters::t_pol_red},     // ReadParameters.mac:189-190
    FitKey{.key = "_JSCALING", .member = &Parameters::jscaling},      // ReadParameters.mac:191-192
    FitKey{.key = "D_PAR_FAC", .member = &Parameters::d_par_fac},     // ReadParameters.mac:193-194
    FitKey{.key = "SPIN_ODD", .member = &Parameters::spin_odd},       // ReadParameters.mac:195-196
    FitKey{.key = "R_SUPP_S1", .member = nullptr},                    // ReadParameters.mac:197-198
    FitKey{.key = "R_SUPP_S2", .member = nullptr},                    // ReadParameters.mac:199-200
    FitKey{.key = "R_SUPP_S3", .member = nullptr},                    // ReadParameters.mac:201-202
}};

// ReadParameters.mac:1-13: remove the /' ... '/ comments, then the text after a comment sign.
void strip_comments(std::string& cline) {
    while (fb::instr(cline, "/'") > 0) {
        cline = fb::trim(cline);
        std::int64_t const ileft = fb::instr(cline, "/'");
        std::int64_t const iright = fb::instr(cline, "'/");
        if (ileft >= iright) {
            // QUIRK(Q-035): nothing changes Cline any more (Trim is idempotent), so BASIC
            // repeats this iteration forever.
            throw GefHangs("ReadParameters.mac:1-8 loops forever on an unterminated or reversed "
                           "/' comment: " +
                           cline);
        }
        cline = fb::mid(cline, 1, ileft - 1) + fb::mid(cline, iright + 2);
    }
    cline = fb::trim(cline);
    if (fb::instr(cline, "'") > 0) {
        cline = fb::mid(cline, 1, fb::instr(cline, "'") - 1);
        cline = fb::trim(cline);
    }
}

} // namespace

std::optional<std::string> read_input_file(std::filesystem::path const& path) {
    // fb_FileExists: fopen(filename, "r") (libstdc++'s filebuf opens with fopen as well).
    std::ifstream f(path, std::ios::binary);
    if (!f.is_open()) {
        return std::nullopt;
    }
    // A directory passes Fileexists, but `Open … For Input` fails on it and EOF() of the
    // unopened number is true, so BASIC reads no line (fbc 1.10.1, checked 2026-10-09): the
    // same as an empty file.
    std::error_code ec;
    if (std::filesystem::is_directory(path, ec)) {
        return std::string{};
    }
    std::string contents{std::istreambuf_iterator<char>(f), std::istreambuf_iterator<char>()};
    return contents;
}

void read_parameters(fb::InputFile& file, Parameters& p, std::vector<std::string>& console) {
    // The Scope's locals (FitparRead.bas:3-9, MyparRead.bas:6-12): Cdiv() keeps its contents from
    // line to line.
    fb::Array<std::string, 1> cdiv{{fb::Bounds{0, 2}}};
    std::int64_t n = 0;
    std::string cpar;
    float valpar = 0.0F;
    while (!file.eof()) {
        std::string cline = file.line_input();
        strip_comments(cline);
        if (cline.empty()) { // ReadParameters.mac:14
            continue;
        }
        if (fb::instr(cline, "=") <= 0) { // ReadParameters.mac:15, 209-210
            console.push_back("<E> Syntax error in " + cline + " .");
            continue;
        }
        console.push_back(cline); // ReadParameters.mac:16 `Print Cline`
        std::int64_t const ndiv = util::cc_count(cline, "=");
        if (ndiv != 2) { // ReadParameters.mac:18, 206-207
            console.push_back("<E> Syntax error in " + cline + " .");
            continue;
        }
        util::cc_cut(cline, "=", cdiv, n, console); // ReadParameters.mac:19-21
        cpar = fb::ucase(fb::trim(cdiv(1)));
        valpar =
            static_cast<float>(fb::val(fb::trim(cdiv(2)))); // `Valpar = Val(...)`: Double to Single
        // ReadParameters.mac:23-204 Select Case Cpar
        bool found = false;
        for (FitKey const& k : fit_keys) {
            if (cpar == k.key) {
                if (k.member != nullptr) {
                    p.*k.member = valpar;
                }
                found = true;
                break;
            }
        }
        if (!found) {
            console.push_back("<E> Readparameters.mac: Parameter " + cpar + " not defined.");
        }
    }
}

void fitpar_read(std::optional<std::string> const& fitpar_dat, Parameters& p,
                 std::vector<std::string>& console) {
    if (!fitpar_dat) { // FitparRead.bas:2 `If Fileexists("Fitpar.dat")`
        return;
    }
    // FitparRead.bas:12-15
    console.emplace_back("File Fitpar.dat found.");
    console.emplace_back("Parameter values from file 'Fitpar.dat' are used as starting values.");
    console.emplace_back("To avoid this (and to keep the values of Parameters.bas), ");
    console.emplace_back("the file Fitpar.dat must be renamed or deleted.");
    fb::InputFile file{*fitpar_dat};   // FitparRead.bas:17-19
    read_parameters(file, p, console); // FitparRead.bas:21-25
}

void mypar_read(std::optional<std::string> const& myparameters_dat, Parameters& p,
                std::vector<std::string>& console) {
    if (p.b_myparameters == 0) { // MyparRead.bas:3 `If B_MyParameters Then`
        return;
    }
    if (!myparameters_dat) { // MyparRead.bas:4, 27-28
        console.emplace_back("File MyParameters.dat not found.");
        return;
    }
    // MyparRead.bas:14-15
    console.emplace_back("File MyParameters.dat found.");
    console.emplace_back("Parameter values from file 'MyParameters.dat' are used.");
    fb::InputFile file{*myparameters_dat}; // MyparRead.bas:17-19
    read_parameters(file, p, console);     // MyparRead.bas:20-24
}

std::string parameter_update_text(Parameters const& p, double now) {
    // ParameterUpdate.mac, the Print # statements as fbc emits them (mask 0: `;`, 1: newline).
    fb::PrintFile f;
    f.print("' GEF-Y2023/V2.2", PrintEnd::Newline); // ParameterUpdate.mac:14
    f.print(" ", PrintEnd::Newline);                // ParameterUpdate.mac:18
    f.print("'************************************************",
            PrintEnd::Newline);                                          // ParameterUpdate.mac:19
    f.print("' This update was written on ", PrintEnd::None);            // ParameterUpdate.mac:20
    f.print(fb::format(now, "dd.mm.yyyy, hh:mm:ss"), PrintEnd::Newline); // ParameterUpdate.mac:21
    f.print("'************************************************",
            PrintEnd::Newline);      // ParameterUpdate.mac:22
    f.print(" ", PrintEnd::Newline); // ParameterUpdate.mac:23
    f.print("'  Emax_valid = 100      /' Maximum allowed excitation energy '/",
            PrintEnd::Newline); // ParameterUpdate.mac:25
    f.print("'  Eexc_min_multi = 3            /' Threshold for calc. of multi-chance fission '/",
            PrintEnd::Newline); // ParameterUpdate.mac:26
    f.print("' _Delta_S0 = 0         /' Shell effect for SL, for individual systems '/",
            PrintEnd::Newline); // ParameterUpdate.mac:27
    f.print("'  EOscale = 1.0  /' Scaling factor for even-odd structure in yields '/",
            PrintEnd::Newline); // ParameterUpdate.mac:28
    f.print("'  Emode = 1      /' 0: E over BF_B; 1: E over gs; 2: E_neutron; 12: E_proton '/",
            PrintEnd::Newline);                                       // ParameterUpdate.mac:29
    f.print("    _P_DZ_Mean_S1 = ", PrintEnd::None);                  // ParameterUpdate.mac:31
    f.print(p.p_dz_mean_s1, PrintEnd::Newline);                       // ParameterUpdate.mac:31
    f.print("    _P_corr_S1 = ", PrintEnd::None);                     // ParameterUpdate.mac:32
    f.print(p.p_corr_s1, PrintEnd::Newline);                          // ParameterUpdate.mac:32
    f.print("    _P_DZ_Mean_S2 =", PrintEnd::None);                   // ParameterUpdate.mac:33
    f.print(p.p_dz_mean_s2, PrintEnd::Newline);                       // ParameterUpdate.mac:33
    f.print("    _P_DZ_Mean_S3 =", PrintEnd::None);                   // ParameterUpdate.mac:34
    f.print(p.p_dz_mean_s3, PrintEnd::None);                          // ParameterUpdate.mac:34
    f.print("   /' Shift of mean Z of Mode 3 '/", PrintEnd::Newline); // ParameterUpdate.mac:34
    f.print("    _P_DZ_Mean_S4 =", PrintEnd::None);                   // ParameterUpdate.mac:35
    f.print(p.p_dz_mean_s4, PrintEnd::None);                          // ParameterUpdate.mac:35
    f.print("   /' Shell around Z=82 '/", PrintEnd::Newline);         // ParameterUpdate.mac:35
    f.print("    _P_DZ_Mean_SL5 =", PrintEnd::None);                  // ParameterUpdate.mac:36
    f.print(p.p_dz_mean_sl5, PrintEnd::Newline);                      // ParameterUpdate.mac:36
    f.print("    _P_DZ_Mean_S5 =", PrintEnd::None);                   // ParameterUpdate.mac:37
    f.print(p.p_dz_mean_s5, PrintEnd::None);                          // ParameterUpdate.mac:37
    f.print("   /' Shell around Z=36 '/", PrintEnd::Newline);         // ParameterUpdate.mac:37
    f.print("    ZC_Mode_SL5 =", PrintEnd::None);                     // ParameterUpdate.mac:38
    f.print(p.zc_mode_sl5, PrintEnd::None);                           // ParameterUpdate.mac:38
    f.print("   /' Maximum at Pu, higher ZC_Mode_SL5 -> towards Am etc. '/",
            PrintEnd::Newline);                                           // ParameterUpdate.mac:38
    f.print("    _P_Z_Curv_S1 =", PrintEnd::None);                        // ParameterUpdate.mac:39
    f.print(p.p_z_curv_s1, PrintEnd::Newline);                            // ParameterUpdate.mac:39
    f.print("    P_Z_Curvmod_S1 =", PrintEnd::None);                      // ParameterUpdate.mac:40
    f.print(p.p_z_curvmod_s1, PrintEnd::None);                            // ParameterUpdate.mac:40
    f.print("   /' Scales energy-dependent shift '/", PrintEnd::Newline); // ParameterUpdate.mac:40
    f.print("    _P_Z_Curv_S2 =", PrintEnd::None);                        // ParameterUpdate.mac:41
    f.print(p.p_z_curv_s2, PrintEnd::Newline);                            // ParameterUpdate.mac:41
    f.print("    _S2leftmod =", PrintEnd::None);                          // ParameterUpdate.mac:42
    f.print(p.s2leftmod, PrintEnd::None);                                 // ParameterUpdate.mac:42
    f.print("   /' Asymmetry in diffuseness of S2 mass peak '/",
            PrintEnd::Newline);                                           // ParameterUpdate.mac:42
    f.print("    P_Z_Curvmod_S2 =", PrintEnd::None);                      // ParameterUpdate.mac:43
    f.print(p.p_z_curvmod_s2, PrintEnd::None);                            // ParameterUpdate.mac:43
    f.print("   /' Scales energy-dependent shift '/", PrintEnd::Newline); // ParameterUpdate.mac:43
    f.print("    _P_A_Width_S2 =", PrintEnd::None);                       // ParameterUpdate.mac:44
    f.print(p.p_a_width_s2, PrintEnd::None);                              // ParameterUpdate.mac:44
    f.print("   /' A width of Mode 2 (box) '/", PrintEnd::Newline);       // ParameterUpdate.mac:44
    f.print("    Fmod_slope_S2 = ", PrintEnd::None);                      // ParameterUpdate.mac:45
    f.print(p.fmod_slope_s2, PrintEnd::None);                             // ParameterUpdate.mac:45
    f.print("   /' Slope modification of linear part of potential '/",
            PrintEnd::Newline);                                           // ParameterUpdate.mac:45
    f.print("    _P_Z_Curv_S3 =", PrintEnd::None);                        // ParameterUpdate.mac:46
    f.print(p.p_z_curv_s3, PrintEnd::Newline);                            // ParameterUpdate.mac:46
    f.print("    P_Z_Curvmod_S3 =", PrintEnd::None);                      // ParameterUpdate.mac:47
    f.print(p.p_z_curvmod_s3, PrintEnd::None);                            // ParameterUpdate.mac:47
    f.print("   /' Scales energy-dependent shift '/", PrintEnd::Newline); // ParameterUpdate.mac:47
    f.print("    _P_Z_Curv_S4 =", PrintEnd::None);                        // ParameterUpdate.mac:48
    f.print(p.p_z_curv_s4, PrintEnd::None);                               // ParameterUpdate.mac:48
    f.print("   /' assumed to be equal to S1 '/", PrintEnd::Newline);     // ParameterUpdate.mac:48
    f.print("    P_Z_Curvmod_S4 =", PrintEnd::None);                      // ParameterUpdate.mac:49
    f.print(p.p_z_curvmod_s4, PrintEnd::None);                            // ParameterUpdate.mac:49
    f.print("   /' assumed to be equal to S1 '/", PrintEnd::Newline);     // ParameterUpdate.mac:49
    f.print("    _P_Z_Curv_SL5 =", PrintEnd::None);                       // ParameterUpdate.mac:50
    f.print(p.p_z_curv_sl5, PrintEnd::Newline);                           // ParameterUpdate.mac:50
    f.print("    _P_Z_Curv_S5 =", PrintEnd::None);                        // ParameterUpdate.mac:51
    f.print(p.p_z_curv_s5, PrintEnd::Newline);                            // ParameterUpdate.mac:51
    f.print("    P_Z_Curvmod_S5 =", PrintEnd::None);                      // ParameterUpdate.mac:52
    f.print(p.p_z_curvmod_s5, PrintEnd::None);                            // ParameterUpdate.mac:52
    f.print("   /' Scales energy-dependent shift '/", PrintEnd::Newline); // ParameterUpdate.mac:52
    f.print("    _P_Shell_S1 =", PrintEnd::None);                         // ParameterUpdate.mac:53
    f.print(p.p_shell_s1, PrintEnd::None);                                // ParameterUpdate.mac:53
    f.print("   /' Shell effect for Mode 1 (S1) '/", PrintEnd::Newline);  // ParameterUpdate.mac:53
    f.print("    _P_Shell_S2 =", PrintEnd::None);                         // ParameterUpdate.mac:54
    f.print(p.p_shell_s2, PrintEnd::None);                                // ParameterUpdate.mac:54
    f.print("   /' Shell effect for Mode 2 (S2) '/", PrintEnd::Newline);  // ParameterUpdate.mac:54
    f.print("    _P_Shell_S3 =", PrintEnd::None);                         // ParameterUpdate.mac:55
    f.print(p.p_shell_s3, PrintEnd::None);                                // ParameterUpdate.mac:55
    f.print("   /' Shell effect for Mode 3 (SA) '/", PrintEnd::Newline);  // ParameterUpdate.mac:55
    f.print("    _P_Shell_S4 =", PrintEnd::None);                         // ParameterUpdate.mac:56
    f.print(p.p_shell_s4, PrintEnd::None);                                // ParameterUpdate.mac:56
    f.print("   /' Shell near Z = 84, deduced from S1 '/",
            PrintEnd::Newline);                       // ParameterUpdate.mac:56
    f.print("    _P_Shell_SL5 =", PrintEnd::None);    // ParameterUpdate.mac:57
    f.print(p.p_shell_sl5, PrintEnd::Newline);        // ParameterUpdate.mac:57
    f.print("    _P_Shell_S5 =", PrintEnd::None);     // ParameterUpdate.mac:58
    f.print(p.p_shell_s5, PrintEnd::Newline);         // ParameterUpdate.mac:58
    f.print("    P_S5_mod =", PrintEnd::None);        // ParameterUpdate.mac:59
    f.print(p.p_s5_mod, PrintEnd::Newline);           // ParameterUpdate.mac:59
    f.print("    _PZ_S3_olap_pos =", PrintEnd::None); // ParameterUpdate.mac:60
    f.print(p.pz_s3_olap_pos, PrintEnd::None);        // ParameterUpdate.mac:60
    f.print("   /' Pos. of S3 shell in light fragment (in Z) '/",
            PrintEnd::Newline);                        // ParameterUpdate.mac:60
    f.print("    _PZ_S3_olap_curv =", PrintEnd::None); // ParameterUpdate.mac:61
    f.print(p.pz_s3_olap_curv, PrintEnd::Newline);     // ParameterUpdate.mac:61
    f.print("    ETHRESHSUPPS1 =", PrintEnd::None);    // ParameterUpdate.mac:62
    f.print(p.ethreshsupps1, PrintEnd::Newline);       // ParameterUpdate.mac:62
    f.print("    ESIGSUPPS1 =", PrintEnd::None);       // ParameterUpdate.mac:63
    f.print(p.esigsupps1, PrintEnd::Newline);          // ParameterUpdate.mac:63
    f.print("    Level_S11 =", PrintEnd::None);        // ParameterUpdate.mac:64
    f.print(p.level_s11, PrintEnd::None);              // ParameterUpdate.mac:64
    f.print("   /' Level for mode S11 (higher values means more symmetric fission) '/",
            PrintEnd::Newline);                                            // ParameterUpdate.mac:64
    f.print("    Shell_fading =", PrintEnd::None);                         // ParameterUpdate.mac:65
    f.print(p.shell_fading, PrintEnd::None);                               // ParameterUpdate.mac:65
    f.print("   /' fading of shell effect with E* '/", PrintEnd::Newline); // ParameterUpdate.mac:65
    f.print("    _T_low_S1 =", PrintEnd::None);                            // ParameterUpdate.mac:66
    f.print(p.t_low_s1, PrintEnd::None);                                   // ParameterUpdate.mac:66
    f.print("   /' Slope parameter for tunneling '/", PrintEnd::Newline);  // ParameterUpdate.mac:66
    f.print("    _T_low_S2 =", PrintEnd::None);                            // ParameterUpdate.mac:67
    f.print(p.t_low_s2, PrintEnd::None);                                   // ParameterUpdate.mac:67
    f.print("   /' Slope parameter for tunneling '/", PrintEnd::Newline);  // ParameterUpdate.mac:67
    f.print("    _T_low_S3 =", PrintEnd::None);                            // ParameterUpdate.mac:68
    f.print(p.t_low_s3, PrintEnd::None);                                   // ParameterUpdate.mac:68
    f.print("   /' Slope parameter for tunneling '/", PrintEnd::Newline);  // ParameterUpdate.mac:68
    f.print("    _T_low_S4 =", PrintEnd::None);                            // ParameterUpdate.mac:69
    f.print(p.t_low_s4, PrintEnd::None);                                   // ParameterUpdate.mac:69
    f.print("   /' Slope parameter for tunneling '/", PrintEnd::Newline);  // ParameterUpdate.mac:69
    f.print("    _T_low_S5 =", PrintEnd::None);                            // ParameterUpdate.mac:70
    f.print(p.t_low_s5, PrintEnd::Newline);                                // ParameterUpdate.mac:70
    f.print("    _T_low_SL =", PrintEnd::None);                            // ParameterUpdate.mac:71
    f.print(p.t_low_sl, PrintEnd::None);                                   // ParameterUpdate.mac:71
    f.print("   /' Slope parameter for tunneling '/", PrintEnd::Newline);  // ParameterUpdate.mac:71
    f.print("    T_low_S11 =", PrintEnd::None);                            // ParameterUpdate.mac:72
    f.print(p.t_low_s11, PrintEnd::None);                                  // ParameterUpdate.mac:72
    f.print("   /' Slope parameter for tunneling '/", PrintEnd::Newline);  // ParameterUpdate.mac:72
    f.print("    T_low_S22 =", PrintEnd::None);                            // ParameterUpdate.mac:73
    f.print(p.t_low_s22, PrintEnd::Newline);                               // ParameterUpdate.mac:73
    f.print("    _P_att_pol =", PrintEnd::None);                           // ParameterUpdate.mac:74
    f.print(p.p_att_pol, PrintEnd::Newline);                               // ParameterUpdate.mac:74
    f.print("    P_att_pol2  =", PrintEnd::None);                          // ParameterUpdate.mac:75
    f.print(p.p_att_pol2, PrintEnd::Newline);                              // ParameterUpdate.mac:75
    f.print("    P_att_pol3 =", PrintEnd::None);                           // ParameterUpdate.mac:76
    f.print(p.p_att_pol3, PrintEnd::Newline);                              // ParameterUpdate.mac:76
    f.print("    _P_att_rel =", PrintEnd::None);                           // ParameterUpdate.mac:77
    f.print(p.p_att_rel, PrintEnd::None);                                  // ParameterUpdate.mac:77
    f.print("   /' Relative portion of attenuation '/",
            PrintEnd::Newline);                   // ParameterUpdate.mac:77
    f.print("    _dE_Defo_S1 =", PrintEnd::None); // ParameterUpdate.mac:78
    f.print(p.de_defo_s1, PrintEnd::None);        // ParameterUpdate.mac:78
    f.print("   /' Deformation energy expense for Mode 1 '/",
            PrintEnd::Newline);                   // ParameterUpdate.mac:78
    f.print("    _dE_Defo_S2 =", PrintEnd::None); // ParameterUpdate.mac:79
    f.print(p.de_defo_s2, PrintEnd::None);        // ParameterUpdate.mac:79
    f.print("   /' Deformation energy expense for Mode 2 '/",
            PrintEnd::Newline);                   // ParameterUpdate.mac:79
    f.print("    _dE_Defo_S3 =", PrintEnd::None); // ParameterUpdate.mac:80
    f.print(p.de_defo_s3, PrintEnd::None);        // ParameterUpdate.mac:80
    f.print("   /' Deformation energy expense for Mode 3 '/",
            PrintEnd::Newline);                   // ParameterUpdate.mac:80
    f.print("    _dE_Defo_S4 =", PrintEnd::None); // ParameterUpdate.mac:81
    f.print(p.de_defo_s4, PrintEnd::None);        // ParameterUpdate.mac:81
    f.print("   /' Deformation energy expense for Mode 4, deduced from S1 '/",
            PrintEnd::Newline);                   // ParameterUpdate.mac:81
    f.print("    _dE_Defo_S5 =", PrintEnd::None); // ParameterUpdate.mac:82
    f.print(p.de_defo_s5, PrintEnd::None);        // ParameterUpdate.mac:82
    f.print("   /' Deformation energy expense for Mode 5 '/",
            PrintEnd::Newline);               // ParameterUpdate.mac:82
    f.print("    _betaL0 =", PrintEnd::None); // ParameterUpdate.mac:83
    f.print(p.betal0, PrintEnd::Newline);     // ParameterUpdate.mac:83
    f.print("    _betaL1 =", PrintEnd::None); // ParameterUpdate.mac:84
    f.print(p.betal1, PrintEnd::Newline);     // ParameterUpdate.mac:84
    f.print("    _betaH0 =", PrintEnd::None); // ParameterUpdate.mac:85
    f.print(p.betah0, PrintEnd::None);        // ParameterUpdate.mac:85
    f.print("   /' Offset for deformation of heavy fragment '/",
            PrintEnd::Newline); // ParameterUpdate.mac:85
    f.print("    ' _betaH0 = 48.2      ' This value in combination with EDISSFRAC = 0.35 gets "
            "nu-bar correct for U235T and Cf252SF",
            PrintEnd::Newline);                 // ParameterUpdate.mac:86
    f.print("    _betaH1 =", PrintEnd::None);   // ParameterUpdate.mac:87
    f.print(p.betah1, PrintEnd::Newline);       // ParameterUpdate.mac:87
    f.print("    _dbeta_S3 =", PrintEnd::None); // ParameterUpdate.mac:88
    f.print(p.dbeta_s3, PrintEnd::Newline);     // ParameterUpdate.mac:88
    f.print("    kappa =", PrintEnd::None);     // ParameterUpdate.mac:89
    f.print(p.kappa, PrintEnd::None);           // ParameterUpdate.mac:89
    f.print("   /' N/Z dedendence of A-asym. potential '/",
            PrintEnd::Newline);                 // ParameterUpdate.mac:89
    f.print("    TCOLLFRAC =", PrintEnd::None); // ParameterUpdate.mac:90
    f.print(p.tcollfrac, PrintEnd::None);       // ParameterUpdate.mac:90
    f.print("   /' Tcoll per energy gain from saddle to scission '/",
            PrintEnd::Newline);                  // ParameterUpdate.mac:90
    f.print("    _ECOLLFRAC =", PrintEnd::None); // ParameterUpdate.mac:91
    f.print(p.ecollfrac, PrintEnd::None);        // ParameterUpdate.mac:91
    f.print("   /' Fraction of pot. energy gain from saddle to scission, going into coll. "
            "excitations '/",
            PrintEnd::Newline);                        // ParameterUpdate.mac:91
    f.print("    TFCOLL =", PrintEnd::None);           // ParameterUpdate.mac:92
    f.print(p.tfcoll, PrintEnd::Newline);              // ParameterUpdate.mac:92
    f.print("    TCOLLMIN =", PrintEnd::None);         // ParameterUpdate.mac:93
    f.print(p.tcollmin, PrintEnd::Newline);            // ParameterUpdate.mac:93
    f.print("    ESHIFTSASCI_intr =", PrintEnd::None); // ParameterUpdate.mac:94
    f.print(p.eshiftsasci_intr, PrintEnd::None);       // ParameterUpdate.mac:94
    f.print("   /' Shift of saddle-scission energy '/",
            PrintEnd::Newline);                        // ParameterUpdate.mac:94
    f.print("    ESHIFTSASCI_coll =", PrintEnd::None); // ParameterUpdate.mac:95
    f.print(p.eshiftsasci_coll, PrintEnd::None);       // ParameterUpdate.mac:95
    f.print("   /' Shift of saddle-scission energy '/",
            PrintEnd::Newline);                     // ParameterUpdate.mac:95
    f.print("    _EDISSFRAC =", PrintEnd::None);    // ParameterUpdate.mac:96
    f.print(p.edissfrac, PrintEnd::Newline);        // ParameterUpdate.mac:96
    f.print("    Epot_shift =", PrintEnd::None);    // ParameterUpdate.mac:97
    f.print(p.epot_shift, PrintEnd::Newline);       // ParameterUpdate.mac:97
    f.print("    SIGDEFO =", PrintEnd::None);       // ParameterUpdate.mac:98
    f.print(p.sigdefo, PrintEnd::Newline);          // ParameterUpdate.mac:98
    f.print("    SIGDEFO_0 =", PrintEnd::None);     // ParameterUpdate.mac:99
    f.print(p.sigdefo_0, PrintEnd::Newline);        // ParameterUpdate.mac:99
    f.print("    SIGDEFO_slope =", PrintEnd::None); // ParameterUpdate.mac:100
    f.print(p.sigdefo_slope, PrintEnd::Newline);    // ParameterUpdate.mac:100
    f.print("    SIGENECK =", PrintEnd::None);      // ParameterUpdate.mac:101
    f.print(p.sigeneck, PrintEnd::None);            // ParameterUpdate.mac:101
    f.print("   /' Width of TXE by fluctuation of neck length '/",
            PrintEnd::Newline);                                           // ParameterUpdate.mac:101
    f.print("    EexcSIGrel =", PrintEnd::None);                          // ParameterUpdate.mac:102
    f.print(p.eexcsigrel, PrintEnd::Newline);                             // ParameterUpdate.mac:102
    f.print("    DNECK =", PrintEnd::None);                               // ParameterUpdate.mac:103
    f.print(p.dneck, PrintEnd::None);                                     // ParameterUpdate.mac:103
    f.print("   /' Tip distance at scission / fm '/", PrintEnd::Newline); // ParameterUpdate.mac:103
    f.print("    FTRUNC50 =", PrintEnd::None);                            // ParameterUpdate.mac:104
    f.print(p.ftrunc50, PrintEnd::None);                                  // ParameterUpdate.mac:104
    f.print("   /' Truncation near Z = 50 '/", PrintEnd::Newline);        // ParameterUpdate.mac:104
    f.print("    ZTRUNC50 =", PrintEnd::None);                            // ParameterUpdate.mac:105
    f.print(p.ztrunc50, PrintEnd::None);                                  // ParameterUpdate.mac:105
    f.print("   /' Z value for truncation '/", PrintEnd::Newline);        // ParameterUpdate.mac:105
    f.print("    FTRUNC28 =", PrintEnd::None);                            // ParameterUpdate.mac:106
    f.print(p.ftrunc28, PrintEnd::None);                                  // ParameterUpdate.mac:106
    f.print("   /' Truncation near Z = 28 '/", PrintEnd::Newline);        // ParameterUpdate.mac:106
    f.print("    ZTRUNC28 =", PrintEnd::None);                            // ParameterUpdate.mac:107
    f.print(p.ztrunc28, PrintEnd::None);                                  // ParameterUpdate.mac:107
    f.print("   /' Z value for truncation '/", PrintEnd::Newline);        // ParameterUpdate.mac:107
    f.print("    ZMAX_S2 =", PrintEnd::None);                             // ParameterUpdate.mac:108
    f.print(p.zmax_s2, PrintEnd::None);                                   // ParameterUpdate.mac:108
    f.print("   /' Maximum Z of S2 channel in light fragment '/",
            PrintEnd::Newline);                   // ParameterUpdate.mac:108
    f.print("    NTRANSFEREO =", PrintEnd::None); // ParameterUpdate.mac:109
    f.print(p.ntransfereo, PrintEnd::None);       // ParameterUpdate.mac:109
    f.print("   /' Steps for E sorting for even-odd effect '/",
            PrintEnd::Newline);                  // ParameterUpdate.mac:109
    f.print("    NTRANSFERE =", PrintEnd::None); // ParameterUpdate.mac:110
    f.print(p.ntransfere, PrintEnd::None);       // ParameterUpdate.mac:110
    f.print("    /' Steps for E sorting for energy division '/",
            PrintEnd::Newline);                                         // ParameterUpdate.mac:110
    f.print("    Csort =", PrintEnd::None);                             // ParameterUpdate.mac:111
    f.print(p.csort, PrintEnd::None);                                   // ParameterUpdate.mac:111
    f.print("   /' Smoothing of energy sorting '/", PrintEnd::Newline); // ParameterUpdate.mac:111
    f.print("    PZ_EO_symm =", PrintEnd::None);                        // ParameterUpdate.mac:112
    f.print(p.pz_eo_symm, PrintEnd::None);                              // ParameterUpdate.mac:112
    f.print("   /' Even-odd effect in Z at symmetry '/",
            PrintEnd::Newline);                  // ParameterUpdate.mac:112
    f.print("    PN_EO_symm =", PrintEnd::None); // ParameterUpdate.mac:113
    f.print(p.pn_eo_symm, PrintEnd::None);       // ParameterUpdate.mac:113
    f.print("   /' Even-odd effect in N at symmetry '/",
            PrintEnd::Newline);                   // ParameterUpdate.mac:113
    f.print("    R_EO_THRESH =", PrintEnd::None); // ParameterUpdate.mac:114
    f.print(p.r_eo_thresh, PrintEnd::None);       // ParameterUpdate.mac:114
    f.print("   /' Threshold for asymmetry-driven even-odd effect'/",
            PrintEnd::Newline);                  // ParameterUpdate.mac:114
    f.print("    R_EO_SIGMA =", PrintEnd::None); // ParameterUpdate.mac:115
    f.print(p.r_eo_sigma, PrintEnd::Newline);    // ParameterUpdate.mac:115
    f.print("    R_EO_Max =", PrintEnd::None);   // ParameterUpdate.mac:116
    f.print(p.r_eo_max, PrintEnd::Newline);      // ParameterUpdate.mac:116
    f.print("    _POLARadd =", PrintEnd::None);  // ParameterUpdate.mac:117
    f.print(p.polaradd, PrintEnd::None);         // ParameterUpdate.mac:117
    f.print("   /' Offset for enhanced polarization '/",
            PrintEnd::Newline);                // ParameterUpdate.mac:117
    f.print("    POLARfac =", PrintEnd::None); // ParameterUpdate.mac:118
    f.print(p.polarfac, PrintEnd::None);       // ParameterUpdate.mac:118
    f.print("   /' Enhancement of polarization of liqu. drop '/",
            PrintEnd::Newline);                 // ParameterUpdate.mac:118
    f.print("    T_POL_RED =", PrintEnd::None); // ParameterUpdate.mac:119
    f.print(p.t_pol_red, PrintEnd::None);       // ParameterUpdate.mac:119
    f.print("   /' Reduction of temperature for sigma(Z) '/",
            PrintEnd::Newline);               // ParameterUpdate.mac:119
    f.print("    _HOMPOL =", PrintEnd::None); // ParameterUpdate.mac:120
    f.print(p.hompol, PrintEnd::None);        // ParameterUpdate.mac:120
    f.print("   /' hbar omega of polarization oscillation '/",
            PrintEnd::Newline);             // ParameterUpdate.mac:120
    f.print("    ZPOL1 =", PrintEnd::None); // ParameterUpdate.mac:121
    f.print(p.zpol1, PrintEnd::None);       // ParameterUpdate.mac:121
    f.print("   /' Extra charge polarization of S1 '/",
            PrintEnd::Newline);             // ParameterUpdate.mac:121
    f.print("    P_n_x =", PrintEnd::None); // ParameterUpdate.mac:122
    f.print(p.p_n_x, PrintEnd::None);       // ParameterUpdate.mac:122
    f.print("   /' Enhanced inverse neutron x section '/",
            PrintEnd::Newline);                                          // ParameterUpdate.mac:122
    f.print("    Tscale =", PrintEnd::None);                             // ParameterUpdate.mac:123
    f.print(p.tscale, PrintEnd::Newline);                                // ParameterUpdate.mac:123
    f.print("    Econd =", PrintEnd::None);                              // ParameterUpdate.mac:124
    f.print(p.econd, PrintEnd::None);                                    // ParameterUpdate.mac:124
    f.print("   /' Pairing condenstation energy '/", PrintEnd::Newline); // ParameterUpdate.mac:124
    f.print("    Etrans =", PrintEnd::None);                             // ParameterUpdate.mac:125
    f.print(p.etrans, PrintEnd::None);                                   // ParameterUpdate.mac:125
    f.print("   /' Matching energy (const. temp to Fermi gas level density '/",
            PrintEnd::Newline);                                        // ParameterUpdate.mac:125
    f.print("    T_orbital =", PrintEnd::None);                        // ParameterUpdate.mac:126
    f.print(p.t_orbital, PrintEnd::None);                              // ParameterUpdate.mac:126
    f.print("   /' From orbital ang. momentum '/", PrintEnd::Newline); // ParameterUpdate.mac:126
    f.print("    _Jscaling =", PrintEnd::None);                        // ParameterUpdate.mac:127
    f.print(p.jscaling, PrintEnd::None);                               // ParameterUpdate.mac:127
    f.print("   /' General scaling of fragment angular momenta '/",
            PrintEnd::Newline);                // ParameterUpdate.mac:127
    f.print("    Spin_odd =", PrintEnd::None); // ParameterUpdate.mac:128
    f.print(p.spin_odd, PrintEnd::None);       // ParameterUpdate.mac:128
    f.print("   /' RMS Spin enhancement for odd Z '/",
            PrintEnd::Newline); // ParameterUpdate.mac:128
    f.print("                                         /' Value of 0.4 adjusted to data. In "
            "conflict with Naik! '/",
            PrintEnd::Newline);                    // ParameterUpdate.mac:129
    f.print("    Esort_extend =", PrintEnd::None); // ParameterUpdate.mac:130
    f.print(p.esort_extend, PrintEnd::None);       // ParameterUpdate.mac:130
    f.print("   /' Extension of energy range for E-sorting '/",
            PrintEnd::Newline);                   // ParameterUpdate.mac:130
    f.print("    Esort_slope =", PrintEnd::None); // ParameterUpdate.mac:131
    f.print(p.esort_slope, PrintEnd::None);       // ParameterUpdate.mac:131
    f.print("   /' Onset of E-sorting around symmetry '/",
            PrintEnd::Newline);                      // ParameterUpdate.mac:131
    f.print("    Esort_slope_S0 =", PrintEnd::None); // ParameterUpdate.mac:132
    f.print(p.esort_slope_s0, PrintEnd::None);       // ParameterUpdate.mac:132
    f.print("   /' Onset of E-sorting around symmetry for S0 channel '/",
            PrintEnd::Newline); // ParameterUpdate.mac:132
    return f.text();
}

std::string parameter_manipulation(std::optional<std::string> const& myparameters_dat,
                                   std::optional<std::string> const& fitpar_dat, double now,
                                   Parameters& p, std::vector<std::string>& console) {
    mypar_read(myparameters_dat, p, console); // ParameterManipulation.mac:2
    fitpar_read(fitpar_dat, p, console);      // ParameterManipulation.mac:4
    return parameter_update_text(p, now);     // ParameterManipulation.mac:6
}

} // namespace gef::params
