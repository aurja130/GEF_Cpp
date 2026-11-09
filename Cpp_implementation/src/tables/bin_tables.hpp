// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The per-nucleus model tables of one bin (MILESTONE_7_PLAN.md D7): the builder's arrays and
// shared scalars, held in run::ProcessState because BASIC never re-dimensions or clears the
// arrays, so every bin, pass, step and system starts from what the previous bin left (QUIRKS
// Q-010). Members keep the BASIC name in snake_case with the declaring line; each sub-milestone
// of M7 adds the members its blocks write.

#pragma once

#include "fbrt/array.hpp"

#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>

namespace gef::tables {

// The Singles of the seven gaps, four per gap.
inline constexpr std::size_t fragment_gap_singles = std::size_t{7} * 4;

// The seven gaps between the A-indexed tables at start-up (BinTables::fragment_gaps): per gap a
// zero Single pair, then glibc's size word of the next chunk, (bytes + 8) rounded up to 16 with
// PREV_INUSE set: 0x41E1 before Zshift, Temp, TempFF and Eshell (16,848 bytes each), 0x57D1
// before PEOZ, PEON and EPART (22,464 bytes each); seen by gdb (MILESTONE_7_PLAN.md §5, M7.2).
constexpr std::array<float, fragment_gap_singles> initial_fragment_gaps() {
    std::array<float, fragment_gap_singles> gaps{};
    for (std::size_t g = 0; g < 7; ++g) {
        gaps.at((g * 4) + 2) = std::bit_cast<float>(g < 4 ? 0x41E1U : 0x57D1U);
    }
    return gaps;
}

struct BinTables {
    // --- persistent per-fragment tables (`ReDim Shared` once at start-up, never cleared)
    // GEF.bas:1084 ReDim Shared Beta(-1 To 7,1 To 2,150): deformation per mode, fragment, Z
    fb::Array<float, 3> beta{{fb::Bounds{-1, 7}, fb::Bounds{1, 2}, fb::Bounds{0, 150}}};
    // GEF.bas:1097 ReDim Shared Edefo(-1 To 5,1 To 2,150): deformation energy per mode, fragment, Z
    fb::Array<float, 3> edefo{{fb::Bounds{-1, 5}, fb::Bounds{1, 2}, fb::Bounds{0, 150}}};
    // --- the eight A-indexed tables (`ReDim Shared` 1109-1193, never cleared). In the reference
    // binary they are consecutive glibc chunks, 16 bytes apart; an index beyond a bound reaches
    // the next row, the gap or the next table (QUIRK(Q-061), tables/fragment_memory.hpp).
    // GEF.bas:1109 ReDim Shared Zmean(0 To 5,1 To 2,350): mean Z per mode, fragment, A
    fb::Array<float, 3> zmean{{fb::Bounds{0, 5}, fb::Bounds{1, 2}, fb::Bounds{0, 350}}};
    // GEF.bas:1121 ReDim Shared Zshift(0 To 5,1 To 2,350): charge polarisation per mode, fragment,
    // A
    fb::Array<float, 3> zshift{{fb::Bounds{0, 5}, fb::Bounds{1, 2}, fb::Bounds{0, 350}}};
    // GEF.bas:1133 ReDim Shared Temp(0 To 5,1 To 2,350) (own writers from M7.4; Zshift's
    // QUIRK(Q-061) overrun reaches Temp(0, 1, ·) in M7.1)
    fb::Array<float, 3> temp{{fb::Bounds{0, 5}, fb::Bounds{1, 2}, fb::Bounds{0, 350}}};
    // GEF.bas:1145 ReDim Shared TempFF(0 To 5,1 To 2,350) (written from M7.4)
    fb::Array<float, 3> tempff{{fb::Bounds{0, 5}, fb::Bounds{1, 2}, fb::Bounds{0, 350}}};
    // GEF.bas:1157 ReDim Shared Eshell(0 To 5,1 To 2,350) (written from M7.4)
    fb::Array<float, 3> eshell{{fb::Bounds{0, 5}, fb::Bounds{1, 2}, fb::Bounds{0, 350}}};
    // GEF.bas:1169 ReDim Shared PEOZ(0 To 7,1 To 2,350) (written from M7.4)
    fb::Array<float, 3> peoz{{fb::Bounds{0, 7}, fb::Bounds{1, 2}, fb::Bounds{0, 350}}};
    // GEF.bas:1181 ReDim Shared PEON(0 To 7,1 To 2,350) (written from M7.4)
    fb::Array<float, 3> peon{{fb::Bounds{0, 7}, fb::Bounds{1, 2}, fb::Bounds{0, 350}}};
    // GEF.bas:1193 ReDim Shared EPART(0 To 7,1 To 2,350) (written from M7.4)
    fb::Array<float, 3> epart{{fb::Bounds{0, 7}, fb::Bounds{1, 2}, fb::Bounds{0, 350}}};
    // The 16 bytes before each of the last seven tables, four Singles each: the calloc-zeroed
    // end of the previous chunk (8 bytes), then the chunk's size word (low half, high half 0).
    // Written by GEF's out-of-bound writes and carried like the tables.
    std::array<float, fragment_gap_singles> fragment_gaps = initial_fragment_gaps();
    // Fidelity switch of QUIRK(Q-061): true makes an index beyond a bound of the eight tables
    // throw (fb::Array) instead of reaching the memory the reference binary reaches.
    bool fix_fragment_table_overrun = false;

    // --- bin-local (GEF.bas:5610 `Dim As Single Escission_lim` inside the bin's `If`)
    float escission_lim = 0.0F;

    // --- mode centres (GEF.bas:5621-5694)
    float zc_mode_0 = 0.0F;             // 767 Shared
    float zc_mode_1 = 0.0F;             // 767
    float zc_mode_2 = 0.0F;             // 767
    float zc_mode_3 = 0.0F;             // 767
    float zc_mode_4 = 0.0F;             // 767
    float zc_mode_5 = 0.0F;             // 767
    float zc_mode_3_shift = 0.0F;       // 769
    float p_z_mean_s1 = 0x1.A66666p+5F; // 1508 `Dim Shared As Single P_Z_Mean_S1 = 52.8`
    float p_z_mean_s2 = 0x1.B8p+5F;     // 1509 `= 55`
    float p_z_mean_s3 = 0x1.04p+6F;     // 1510 `= 65`
    float p_z_mean_s4 = 0x1.5p+6F;      // 1511 `= 84`
    float p_z_mean_s5 = 0x1.3p+5F;      // 1512 `= 38`
    std::int64_t i_n_cn = 0;            // 761 Shared Integer

    // --- mean Z as a function of A, Z-A relations, curvatures (GEF.bas:5876-6058)
    float zucd = 0.0F;         // 789
    float rzpol = 0.0F;        // 807
    float ra = 0.0F;           // 803
    float ac_mode_0 = 0.0F;    // 805
    float ac_mode_1 = 0.0F;    // 805
    float ac_mode_2 = 0.0F;    // 805
    float ac_mode_3 = 0.0F;    // 805
    float ac_mode_4 = 0.0F;    // 805
    float ac_mode_5 = 0.0F;    // 805
    float nc_mode_0 = 0.0F;    // 1513
    float nc_mode_1 = 0.0F;    // 1514
    float nc_mode_2 = 0.0F;    // 1515
    float nc_mode_3 = 0.0F;    // 1516
    float nc_mode_4 = 0.0F;    // 1517
    float nc_mode_5 = 0.0F;    // 1518
    float r_z_curv_s0 = 0.0F;  // 766
    float r_z_curv1_s0 = 0.0F; // 766
    float r_a_curv1_s0 = 0.0F; // 766
    float r_z_curv2_s0 = 0.0F; // 766
    float r_a_curv2_s0 = 0.0F; // 766

    // --- energy transformation, fission barriers, shell effects, barriers and excitation
    // energies of the fission modes (GEF.bas:6063-6306)
    float r_e_exc_eb = 0.0F;     // 1505
    float r_e_exc_gs = 0.0F;     // 1506
    float b_f = 0.0F;            // 1499
    float b_f_ld = 0.0F;         // 1500
    float e_b = 0.0F;            // 1502
    float e_b_ld = 0.0F;         // 1504
    float e_a = 0.0F;            // 1501
    float de_ab = 0.0F;          // 1503
    float delta_nz_pol = 0.0F;   // 1527
    float r_shell_s1_eff = 0.0F; // 777
    float r_shell_s2_eff = 0.0F; // 777
    float r_shell_s3_eff = 0.0F; // 777
    float r_shell_s4_eff = 0.0F; // 777
    float r_shell_s5_eff = 0.0F; // 777
    float s1_enhance = 0.0F;     // 846
    float s1_enhance_s2 = 0.0F;  // 846
    float e_ld_s1 = 0.0F;        // 776
    float e_ld_s2 = 0.0F;        // 776
    float e_ld_s3 = 0.0F;        // 776
    float e_ld_s4 = 0.0F;        // 776
    float e_ld_s5 = 0.0F;        // 776
    float dz_asym = 0.0F;        // 768
    float b_s1 = 0.0F;           // 1519
    float b_s2 = 0.0F;           // 1520
    float b_s3 = 0.0F;           // 1521
    float b_s4 = 0.0F;           // 1522
    float b_s5 = 0.0F;           // 1523
    float b_s11 = 0.0F;          // 1524
    float b_s22 = 0.0F;          // 1525
    float des11zpm = 0.0F;       // 1526
    float e_exc_s0_prov = 0.0F;  // 773
    float e_exc_s1_prov = 0.0F;  // 773
    float e_exc_s2_prov = 0.0F;  // 773
    float e_exc_s3_prov = 0.0F;  // 773
    float e_exc_s4_prov = 0.0F;  // 773
    float e_exc_s5_prov = 0.0F;  // 773
    float e_exc_s11_prov = 0.0F; // 774
    float e_exc_s22_prov = 0.0F; // 774
    float e_min_barr = 0.0F;     // 785
    float e_exc_s0 = 0.0F;       // 1538
    float e_exc_s1 = 0.0F;       // 1539
    float e_exc_s2 = 0.0F;       // 1540
    float e_exc_s3 = 0.0F;       // 1541
    float e_exc_s4 = 0.0F;       // 1542
    float e_exc_s5 = 0.0F;       // 1543
    float e_exc_s11 = 0.0F;      // 1544
    float e_exc_s22 = 0.0F;      // 1545
    float e_exc_barr = 0.0F;     // 775
    // E_tunn: this block writes it (6311), M7.4's EPART loop writes it again (7213) with the
    // value P3 captures.
    float e_tunn = 0.0F;    // 791
    float e_tunn_s1 = 0.0F; // 791
    float e_tunn_s2 = 0.0F; // 791
    float e_tunn_s3 = 0.0F; // 791
    float e_tunn_s4 = 0.0F; // 791

    // --- collective temperature, stiffness in polarization, mean values and standard
    // deviations of the fission modes (GEF.bas:6307-6558)
    float r_e_exc_eff = 0.0F; // 779
    // GEF.bas:6326 `Dim As Single T_Rusanov` (bin-local, zeroed in every bin)
    float t_rusanov = 0.0F;
    float t_coll_mode_0 = 0.0F; // 1537
    float t_coll_mode_1 = 0.0F; // 763
    float t_coll_mode_2 = 0.0F; // 763
    float t_coll_mode_3 = 0.0F; // 763
    float t_coll_mode_4 = 0.0F; // 763
    float t_coll_mode_5 = 0.0F; // 763
    float t_pol_mode_0 = 0.0F;  // 784
    float t_pol_mode_1 = 0.0F;  // 784
    float t_pol_mode_2 = 0.0F;  // 784
    float t_pol_mode_3 = 0.0F;  // 784
    float t_pol_mode_4 = 0.0F;  // 784
    float t_pol_mode_5 = 0.0F;  // 784
    float t_asym_mode_0 = 0.0F; // 764
    float t_asym_mode_1 = 0.0F; // 764
    float t_asym_mode_2 = 0.0F; // 764
    float t_asym_mode_3 = 0.0F; // 764
    float t_asym_mode_4 = 0.0F; // 764
    float t_asym_mode_5 = 0.0F; // 764
    float t_low_s1_used = 0.0F; // 840
    // E_pot_scission, E_diss_Scission: this block writes them (6342, 6344), M7.4's EPART loop
    // writes them again (7216, 7218/7219) with the values P3 captures.
    float e_pot_scission = 0.0F;  // 1546
    float e_diss_scission = 0.0F; // 1547
    float r_pol_curv_s0 = 0.0F;   // 802
    float r_pol_curv_s1 = 0.0F;   // 802
    float r_pol_curv_s2 = 0.0F;   // 802
    float r_pol_curv_s3 = 0.0F;   // 802
    float r_pol_curv_s4 = 0.0F;   // 802
    float r_pol_curv_s5 = 0.0F;   // 802
    float p_pol_curv_s0 = 0.0F;   // 1536
    // GEF.bas:6478-6479 `Dim As Single R_E_intr_S1, ..., R_E_intr_S5` (bin-local, zeroed in
    // every bin)
    float r_e_intr_s1 = 0.0F;
    float r_e_intr_s2 = 0.0F;
    float r_e_intr_s3 = 0.0F;
    float r_e_intr_s4 = 0.0F;
    float r_e_intr_s5 = 0.0F;
    // GEF.bas:6480-6481 `ReDim As Single R_Att(7)`, `R_Att_Sad(7)` (bin-local, zero-filled by
    // ReDim in every bin)
    fb::Array<float, 1> r_att;
    fb::Array<float, 1> r_att_sad;
    float sigz_mode_0 = 0.0F;   // 770
    float sigz_mode_1 = 0.0F;   // 770
    float sigz_mode_2 = 0.0F;   // 770
    float sigz_mode_3 = 0.0F;   // 770
    float sigz_mode_4 = 0.0F;   // 770
    float sigz_mode_5 = 0.0F;   // 770
    float sigz_sl5 = 0.0F;      // 771
    float sigpol_mode_0 = 0.0F; // 1550
    float sigpol_mode_1 = 0.0F; // 765
    float sigpol_mode_2 = 0.0F; // 765
    float sigpol_mode_3 = 0.0F; // 765
    float sigpol_mode_4 = 0.0F; // 765
    float sigpol_mode_5 = 0.0F; // 765
    // SigA_Mode_2: this block writes it (6157), M7.3 writes it again (7025, 7026) with the
    // value P3 captures.
    float siga_mode_2 = 0.0F; // 804
};

// The builder's shared scratch variables (P3 group "stale temporaries", plus `RZ` of the group
// "mode centres, mean Z, mean A and N of the modes 0-5"). The builder writes each of them before
// reading it in a bin (`tools.fbsrc.rbw reads GEF.bas:5578-7920`), and later code writes them
// before it reads them (MILESTONE_7_PLAN.md §9, M7.0), so they carry nothing: the caller owns
// them per bin (D7: locals). They are a struct so that tests can observe them.
// The global `Z` (read by the next step's pre-pass, Q-007) and `T` are run::ProcessState fields.
struct Temporaries {
    float rbeta = 0.0F;      // 787
    float beta1 = 0.0F;      // 787
    float beta2 = 0.0F;      // 787
    float beta1_opt = 0.0F;  // 796
    float beta2_opt = 0.0F;  // 796
    float beta1_prev = 0.0F; // 796
    float beta2_prev = 0.0F; // 796
    float z1 = 0.0F;         // 797
    float z2 = 0.0F;         // 797
    std::int64_t iz1 = 0;    // 798 Shared Integer
    std::int64_t iz2 = 0;    // 798
    float a1 = 0.0F;         // 799
    float a2 = 0.0F;         // 799
    float e_defo = 0.0F;     // 801
    // GEF.bas:6450 `RZ = Csng(I_Z_CN) * 0.5`: event-loop scratch the builder writes before
    // reading (M7.2).
    float rz = 0.0F; // 803
};

} // namespace gef::tables
