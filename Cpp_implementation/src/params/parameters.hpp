// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// GEF's model parameters (M4.4): the nominal values that `Parameters.bas` sets
// (GEF.bas:893-1010 declarations, `Parameters.bas` included at GEF.bas:1015 and, per system,
// at GEF.bas:3320), the perturbation widths `Var_*` (GEF.bas:1348-1394, 2575-2620) and the
// descriptor tables that name them.
//
// Every Single is a float and every Integer an int64 (exact mode). Members keep the BASIC name
// in snake_case; the nominal parameters that GEF perturbs carry a leading underscore in BASIC
// (`_P_DZ_Mean_S1`), which the members drop: within `Parameters` every value is nominal. The
// perturbed working copies (`P_DZ_Mean_S1`) belong to the pass state (M12).

#pragma once

#include <array>
#include <cstdint>
#include <string_view>
#include <variant>

namespace gef::params {

// The 110 shared nominal parameters in their declaration order (GEF.bas:893-1007), with the
// initial values of their `Dim` statements, and `B_MyParameters` (GEF.bas:1010). This is the
// order of the T0/P1 probe group "nominal parameters" (harness/PROBES.md).
struct Parameters {
    // GEF.bas:894 Emax_valid: Maximum allowed excitation energy
    float emax_valid = 0x1.9p+6F;
    // GEF.bas:895 Eexc_min_multi: Threshold for calc. of multi-chance fission
    float eexc_min_multi = 0x1.8p+1F;
    // GEF.bas:896 _Delta_S0: Shell effect for SL, for individual systems
    float delta_s0 = 0x0p+0F;
    // GEF.bas:897 EOscale: Scaling factor for even-odd structure in yields
    float eoscale = 0x1.p+0F;
    // GEF.bas:898 Emode: 0: E over BF_B; 1: E over gs; 2: E_neutron; 12: E_proton
    std::int64_t emode = 1;
    // GEF.bas:899 D_Par_Fac: Scales the variation of perturbed parameters
    float d_par_fac = 0x1.p+0F;
    // GEF.bas:901 Chisqr_Fit_min
    float chisqr_fit_min = 0.0F;
    // GEF.bas:903 _P_DZ_Mean_S1
    float p_dz_mean_s1 = 0.0F;
    // GEF.bas:904 _P_corr_S1
    float p_corr_s1 = 0.0F;
    // GEF.bas:905 _P_DZ_Mean_S2
    float p_dz_mean_s2 = 0.0F;
    // GEF.bas:906 _P_DZ_Mean_S3: Shift of mean Z of Mode 3
    float p_dz_mean_s3 = 0.0F;
    // GEF.bas:907 _P_DZ_Mean_S4: Shift of mean Z of Mode around Z=82
    float p_dz_mean_s4 = 0.0F;
    // GEF.bas:908 _P_DZ_Mean_SL5: Shift of mean Z of Mode around Z=36 for around Pu
    float p_dz_mean_sl5 = 0.0F;
    // GEF.bas:909 _P_DZ_Mean_S5: Shift of mean Z of Mode around Z=36
    float p_dz_mean_s5 = 0.0F;
    // GEF.bas:910 ZC_Mode_SL5: enhances S1 near Pu
    float zc_mode_sl5 = 0.0F;
    // GEF.bas:911 _P_Z_Curv_S1
    float p_z_curv_s1 = 0.0F;
    // GEF.bas:912 P_Z_Curvmod_S1: Scales energy-dependent shift
    float p_z_curvmod_s1 = 0.0F;
    // GEF.bas:913 _P_Z_CurV_S2
    float p_z_curv_s2 = 0.0F;
    // GEF.bas:914 _S2leftmod: Asymmetry in diffuseness of S2 mass peak
    float s2leftmod = 0.0F;
    // GEF.bas:915 P_Z_Curvmod_S2: Scales energy-dependent shift
    float p_z_curvmod_s2 = 0.0F;
    // GEF.bas:916 _P_A_Width_S2: A width of Mode 2 (box)
    float p_a_width_s2 = 0.0F;
    // GEF.bas:917 P_Cut_S2: Divide S2 into two modes, S2a and S2b
    float p_cut_s2 = 0.0F;
    // GEF.bas:918 Fmod_slope_S2: Slope modification of linear part of potential
    float fmod_slope_s2 = 0.0F;
    // GEF.bas:919 _P_Z_Curv_S3
    float p_z_curv_s3 = 0.0F;
    // GEF.bas:920 P_Z_Curvmod_S3: Scales energy-dependent shift
    float p_z_curvmod_s3 = 0.0F;
    // GEF.bas:921 _P_Z_Curv_S4
    float p_z_curv_s4 = 0.0F;
    // GEF.bas:922 _P_Z_Curv_SL5
    float p_z_curv_sl5 = 0.0F;
    // GEF.bas:924 _P_Z_Curv_S5
    float p_z_curv_s5 = 0.0F;
    // GEF.bas:925 P_Z_Curvmod_S4: Scales energy-dependent shift
    float p_z_curvmod_s4 = 0.0F;
    // GEF.bas:926 P_Z_Curvmod_S5: Scales energy-dependent shift
    float p_z_curvmod_s5 = 0.0F;
    // GEF.bas:927 _P_Shell_S1: Shell effect for Mode 1 (S1)
    float p_shell_s1 = 0.0F;
    // GEF.bas:928 _P_Shell_S2: Shell effect for Mode 2 (S2)
    float p_shell_s2 = 0.0F;
    // GEF.bas:929 _P_Shell_S3: Shell effect for Mode 3 (SA)
    float p_shell_s3 = 0.0F;
    // GEF.bas:930 _P_Shell_S4: Shell effect for Mode 4  (Z=82)
    float p_shell_s4 = 0.0F;
    // GEF.bas:931 _P_Shell_SL5: Shell enhancing S1
    float p_shell_sl5 = 0.0F;
    // GEF.bas:932 _P_Shell_S5: Shell effect for Mode 5  (Z=36)
    float p_shell_s5 = 0.0F;
    // GEF.bas:933 P_S5_mod: Variation of S5 shell with N_CN (reference: 205Bi)
    float p_s5_mod = 0.0F;
    // GEF.bas:934 _PZ_S3_olap_pos: Pos. of S3 shell in light fragment (in Z)
    float pz_s3_olap_pos = 0.0F;
    // GEF.bas:935 _PZ_S3_olap_curv
    float pz_s3_olap_curv = 0.0F;
    // GEF.bas:936 ETHRESHSUPPS1
    float ethreshsupps1 = 0.0F;
    // GEF.bas:937 ESIGSUPPS1
    float esigsupps1 = 0.0F;
    // GEF.bas:938 Level_S11: Level for mode S11
    float level_s11 = 0.0F;
    // GEF.bas:939 Shell_fading: fading of shell effect with E*
    float shell_fading = 0.0F;
    // GEF.bas:940 _T_low_S1
    float t_low_s1 = 0.0F;
    // GEF.bas:941 _T_low_S2: Slope parameter for tunneling
    float t_low_s2 = 0.0F;
    // GEF.bas:942 _T_low_S3: Slope parameter for tunneling
    float t_low_s3 = 0.0F;
    // GEF.bas:943 _T_low_S4: Slope parameter for tunneling
    float t_low_s4 = 0.0F;
    // GEF.bas:944 _T_low_S5: Slope parameter for tunneling
    float t_low_s5 = 0.0F;
    // GEF.bas:945 _T_low_SL: Slope parameter for tunneling
    float t_low_sl = 0.0F;
    // GEF.bas:946 T_low_S11: Slope parameter for tunneling
    float t_low_s11 = 0.0F;
    // GEF.bas:947 T_low_S22
    float t_low_s22 = 0.0F;
    // GEF.bas:948 _P_att_pol: Attenuation length of 132Sn shell
    float p_att_pol = 0.0F;
    // GEF.bas:949 P_att_pol2
    float p_att_pol2 = 0.0F;
    // GEF.bas:950 P_att_pol3
    float p_att_pol3 = 0.0F;
    // GEF.bas:951 _P_att_rel: Relative portion of attenuation
    float p_att_rel = 0.0F;
    // GEF.bas:952 _dE_Defo_S1: Deformation energy expense for Mode 1
    float de_defo_s1 = 0.0F;
    // GEF.bas:953 _dE_Defo_S2: Deformation energy expense for Mode 2
    float de_defo_s2 = 0.0F;
    // GEF.bas:954 _dE_Defo_S3: Deformation energy expense for Mode 3
    float de_defo_s3 = 0.0F;
    // GEF.bas:955 _dE_Defo_S4: Deformation energy expense for Mode 4
    float de_defo_s4 = 0.0F;
    // GEF.bas:956 _dE_Defo_S5: Deformation energy expense for Mode 5
    float de_defo_s5 = 0.0F;
    // GEF.bas:957 _betaL0
    float betal0 = 0.0F;
    // GEF.bas:958 _betaL1
    float betal1 = 0.0F;
    // GEF.bas:959 _betaH0: Offset for deformation of heavy fragment
    float betah0 = 0.0F;
    // GEF.bas:960 _betaH1
    float betah1 = 0.0F;
    // GEF.bas:961 _dbeta_S3
    float dbeta_s3 = 0.0F;
    // GEF.bas:962 kappa: N/Z dedendence of A-asym. potential
    float kappa = 0.0F;
    // GEF.bas:963 kappa4: Dahlinger appoach
    float kappa4 = 0.0F;
    // GEF.bas:964 BFC: third saddle
    float bfc = 0.0F;
    // GEF.bas:965 TCOLLFRAC: Tcoll per energy gain from saddle to scission
    float tcollfrac = 0.0F;
    // GEF.bas:966 _ECOLLFRAC
    float ecollfrac = 0.0F;
    // GEF.bas:967 TFCOLL
    float tfcoll = 0.0F;
    // GEF.bas:968 TCOLLMIN
    float tcollmin = 0.0F;
    // GEF.bas:969 ESHIFTSASCI_intr: Shift of saddle-scission energy
    float eshiftsasci_intr = 0.0F;
    // GEF.bas:970 ESHIFTSASCI_coll: Shift of saddle-scission energy
    float eshiftsasci_coll = 0.0F;
    // GEF.bas:971 _EDISSFRAC
    float edissfrac = 0.0F;
    // GEF.bas:972 Epot_shift: shift of potential at scission
    float epot_shift = 0.0F;
    // GEF.bas:973 SIGDEFO
    float sigdefo = 0.0F;
    // GEF.bas:974 SIGDEFO_0
    float sigdefo_0 = 0.0F;
    // GEF.bas:975 SIGDEFO_slope
    float sigdefo_slope = 0.0F;
    // GEF.bas:976 SIGENECK: Width of TXE by fluctuation of neck length
    float sigeneck = 0.0F;
    // GEF.bas:977 EexcSIGrel
    float eexcsigrel = 0.0F;
    // GEF.bas:978 DNECK: Tip distance at scission / fm
    float dneck = 0.0F;
    // GEF.bas:979 FTRUNC50: Truncation near Z = 50
    float ftrunc50 = 0.0F;
    // GEF.bas:980 ZTRUNC50: Z value for truncation
    float ztrunc50 = 0.0F;
    // GEF.bas:981 FTRUNC28: Truncation near Z = 28
    float ftrunc28 = 0.0F;
    // GEF.bas:982 ZTRUNC28: Z value for truncation
    float ztrunc28 = 0.0F;
    // GEF.bas:983 ZMAX_S2: Maximum Z of S2 channel in light fragment
    float zmax_s2 = 0.0F;
    // GEF.bas:984 NTRANSFEREO: Steps for E sorting for even-odd effect
    float ntransfereo = 0.0F;
    // GEF.bas:985 NTRANSFERE: Steps for E sorting for energy division
    float ntransfere = 0.0F;
    // GEF.bas:986 Csort: Smoothing of energy sorting
    float csort = 0.0F;
    // GEF.bas:987 PZ_EO_symm: Even-odd effect in Z at symmetry
    float pz_eo_symm = 0.0F;
    // GEF.bas:988 PN_EO_Symm: Even-odd effect in N at symmetry
    float pn_eo_symm = 0.0F;
    // GEF.bas:989 R_EO_THRESH: Threshold for asymmetry-driven even-odd effect
    float r_eo_thresh = 0.0F;
    // GEF.bas:990 R_EO_SIGMA
    float r_eo_sigma = 0.0F;
    // GEF.bas:991 R_EO_MAX: Maximum even-odd effect
    float r_eo_max = 0.0F;
    // GEF.bas:992 _POLARadd: Offset for enhanced polarization
    float polaradd = 0.0F;
    // GEF.bas:993 POLARfac: Enhancement of polarization of ligu. drop
    float polarfac = 0.0F;
    // GEF.bas:994 T_POL_RED: Reduction of temperature for sigma(Z)
    float t_pol_red = 0.0F;
    // GEF.bas:995 _HOMPOL: hbar omega of polarization oscillation
    float hompol = 0.0F;
    // GEF.bas:996 ZPOL1: Extra charge polarization of S1
    float zpol1 = 0.0F;
    // GEF.bas:997 P_n_x: Enhanced inverse neutron x section
    float p_n_x = 0.0F;
    // GEF.bas:998 Tscale
    float tscale = 0.0F;
    // GEF.bas:999 Econd
    float econd = 0.0F;
    // GEF.bas:1000 Etrans
    float etrans = 0.0F;
    // GEF.bas:1001 T_orbital: From orbital ang. momentum
    float t_orbital = 0.0F;
    // GEF.bas:1002 _Jscaling: General scaling of fragment angular momenta
    float jscaling = 0.0F;
    // GEF.bas:1003 Spin_odd: RMS Spin enhancement for odd Z
    float spin_odd = 0.0F;
    // GEF.bas:1005 Esort_extend: Extension of energy range for E-sorting
    float esort_extend = 0.0F;
    // GEF.bas:1006 Esort_slope: Onset of E-sorting around symmetry
    float esort_slope = 0.0F;
    // GEF.bas:1007 Esort_slope_S0: Onset of E-sorting around symmetry for S0 channel
    float esort_slope_s0 = 0.0F;
    // GEF.bas:1010 `Dim As Byte B_MyParameters = 0` (set later by the input; Q-018)
    std::int8_t b_myparameters = 0;
};

// Parameters.bas, line by line as fbc compiles it (each Double literal narrowed to Single at
// compile time; repeated assignments kept, the last one wins). Parameters the file does not
// assign keep their values.
void load_parameters_bas(Parameters& p);

// The perturbation widths of the error analysis (GEF.bas:1347-1394): `Fred_par` and one
// `Var_*` per perturbed parameter, in the order of their declaration (and of the probe group).
struct PerturbationWidths {
    float fred_par = 0.0F;            // Fred_par
    float var_p_dz_mean_s1 = 0.0F;    // Var_P_DZ_Mean_S1
    float var_p_corr_s1 = 0.0F;       // Var_P_Corr_S1
    float var_p_dz_mean_s2 = 0.0F;    // Var_P_DZ_Mean_S2
    float var_p_a_width_s2 = 0.0F;    // Var_P_A_Width_S2
    float var_p_dz_mean_s3 = 0.0F;    // Var_P_DZ_Mean_S3
    float var_p_dz_mean_s4 = 0.0F;    // Var_P_DZ_Mean_S4
    float var_p_dz_mean_sl5 = 0.0F;   // Var_P_DZ_Mean_SL5
    float var_p_dz_mean_s5 = 0.0F;    // Var_P_DZ_Mean_S5
    float var_delta_s0 = 0.0F;        // Var_Delta_S0
    float var_p_shell_s1 = 0.0F;      // Var_P_Shell_S1
    float var_p_shell_s2 = 0.0F;      // Var_P_Shell_S2
    float var_p_shell_s3 = 0.0F;      // Var_P_Shell_S3
    float var_p_shell_s4 = 0.0F;      // Var_P_Shell_S4
    float var_p_shell_sl5 = 0.0F;     // Var_P_Shell_SL5
    float var_p_shell_s5 = 0.0F;      // Var_P_Shell_S5
    float var_p_z_curv_s1 = 0.0F;     // Var_P_Z_Curv_S1
    float var_p_z_curv_s2 = 0.0F;     // Var_P_Z_Curv_S2
    float var_s2leftmod = 0.0F;       // Var_S2leftmod
    float var_p_z_curv_s3 = 0.0F;     // Var_P_Z_Curv_S3
    float var_p_z_curv_s4 = 0.0F;     // Var_P_Z_Curv_S4
    float var_p_z_curv_sl5 = 0.0F;    // Var_P_Z_Curv_SL5
    float var_p_z_curv_s5 = 0.0F;     // Var_P_Z_Curv_S5
    float var_pz_s3_olap_pos = 0.0F;  // Var_PZ_S3_olap_pos
    float var_pz_s3_olap_curv = 0.0F; // Var_PZ_S3_olap_curv
    float var_de_defo_s1 = 0.0F;      // Var_dE_Defo_S1
    float var_de_defo_s2 = 0.0F;      // Var_dE_Defo_S2
    float var_de_defo_s3 = 0.0F;      // Var_dE_Defo_S3
    float var_de_defo_s4 = 0.0F;      // Var_dE_Defo_S4
    float var_de_defo_s5 = 0.0F;      // Var_dE_Defo_S5
    float var_betal0 = 0.0F;          // Var_betaL0
    float var_betal1 = 0.0F;          // Var_betaL1
    float var_betah0 = 0.0F;          // Var_betaH0
    float var_betah1 = 0.0F;          // Var_betaH1
    float var_dbeta_s3 = 0.0F;        // Var_dbeta_S3
    float var_t_low_s1 = 0.0F;        // Var_T_low_S1
    float var_t_low_s2 = 0.0F;        // Var_T_low_S2
    float var_t_low_s3 = 0.0F;        // Var_T_low_S3
    float var_t_low_s4 = 0.0F;        // Var_T_low_S4
    float var_t_low_s5 = 0.0F;        // Var_T_low_S5
    float var_t_low_sl = 0.0F;        // Var_T_low_SL
    float var_ecollfrac = 0.0F;       // Var_ECOLLFRAC
    float var_edissfrac = 0.0F;       // Var_EDISSFRAC
    float var_p_att_pol = 0.0F;       // Var_P_att_pol
    float var_hompol = 0.0F;          // Var_HOMPOL
    float var_polaradd = 0.0F;        // Var_POLARadd
    float var_jscaling = 0.0F;        // Var_Jscaling
};

// GEF.bas:1348-1394: the `Dim` initialisers, evaluated once after `Parameters.bas` and
// `ParameterManipulation.mac` (GEF.bas:1015-1017).
[[nodiscard]] PerturbationWidths initial_widths(Parameters const& p);

// GEF.bas:2575-2620: the widths recomputed with `D_Par_Fac`, once per process after the input
// is read. `pz_s3_olap_curv` is the working copy `PZ_S3_olap_curv` (not the nominal value) that
// GEF.bas:2610 reads (QUIRK(Q-019)); it is zero unless a perturbation pass has set it.
void update_widths(PerturbationWidths& w, Parameters const& p, float pz_s3_olap_curv);

// One nominal parameter: its BASIC name (as declared, the probe name) and member.
struct NominalParameter {
    std::string_view name;
    std::variant<float Parameters::*, std::int64_t Parameters::*, std::int8_t Parameters::*> member;
};

// The 111 nominal parameters in the order of `Parameters` (the probe order).
extern std::array<NominalParameter, 111> const nominal_parameters;

// One perturbation width: BASIC name and member (`Fred_par` first, then the 46 `Var_*`).
struct WidthParameter {
    std::string_view name;
    float PerturbationWidths::* member;
};

extern std::array<WidthParameter, 47> const width_parameters;

// A perturbed parameter (GEF.bas:5112-5160): `<working> = PGauss(<nominal>, <width>)`.
struct PerturbedParameter {
    std::string_view working_name; // BASIC name of the working copy, e.g. "P_DZ_Mean_S1"
    std::string_view nominal_name; // e.g. "_P_DZ_Mean_S1"
    float Parameters::* nominal;
    std::string_view width_name; // e.g. "Var_P_DZ_Mean_S1"
    float PerturbationWidths::* width;
};

// The 46 perturbed parameters in the order GEF draws them (one PGauss each, GEF.bas:5112-5160).
// `P_att_rel = _P_att_rel` (GEF.bas:5155) is a copy between the draws, not a draw.
extern std::array<PerturbedParameter, 46> const perturbation_order;

} // namespace gef::params
