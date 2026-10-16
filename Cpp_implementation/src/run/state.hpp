// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The run-control state of GEF's batch mode (M6): every BASIC variable that the input parser,
// the run driver and the system/step set-up read or write, grouped by the point where BASIC
// re-initialises it (MILESTONE_6_PLAN.md D6, strategy §2.4):
//
//   ProcessState       never re-initialised after start-up (module-level `Static`, `Shared`
//                      and `Dim` before `RepeatInput:`); BASIC's own assignments move it.
//   InputRoundState    the `Dim`s after `Nextfitloop:` (GEF.bas:2647-2684), which run again
//                      at every pass through it: once per fit iteration and per restart.
//   SequenceFileState  the per-file reset of GEF.bas:2827-2842, done after each sequence file's
//                      energy line; system lines and steps change it until the next file.
//   StepState          the `Dim`s at the top of the multi-chance block (GEF.bas:3914-3945),
//                      which run again for every energy step.
//
// No BASIC variable is re-initialised per system: `Parameters.bas` (GEF.bas:3320) assigns its
// own variables in ProcessState::params and leaves the others alone.
//
// Members keep the BASIC name in snake_case, with the declaring line. Types follow coding
// standards §2.4: Single float, Double double, Integer/LongInt int64, Byte int8, UByte uint8.

#pragma once

#include "data/lookups.hpp"
#include "data/tables.hpp"
#include "fbrt/array.hpp"
#include "fbrt/text.hpp"
#include "params/parameters.hpp"
#include "run/probes.hpp"

#include <cstdint>
#include <string>

namespace gef::run {

// One system line of a sequence file: `S_par_type` (GEF.bas:2655-2662).
struct SystemLine {
    std::int64_t z = 0;        // Z (CN)
    std::int64_t a = 0;        // A (CN)
    std::int64_t z_double = 0; // Z_double (second system of a correlation line, else 0)
    std::int64_t a_double = 0; // A_double
    float e_double = 0.0F;     // E_double
    std::string ce;            // CE: kind of entrance channel as written ("EN", "GS", "IS1", ...)
};

// List-mode selection flags (GEF.bas:1728-1733, `Dim As Byte`), set by Options(LMD/LMD+) and
// never reset.
struct LmdFlags {
    std::int8_t pz1 = 0;
    std::int8_t pz2 = 0;
    std::int8_t pa1pre = 0;
    std::int8_t pa2pre = 0;
    std::int8_t pa1post = 0;
    std::int8_t pa2post = 0;
    std::int8_t pi1 = 0;
    std::int8_t pi2 = 0;
    std::int8_t pn1 = 0;
    std::int8_t pn2 = 0;
    std::int8_t ptkepre = 0;
    std::int8_t ptkepost = 0;
    std::int8_t pncn = 0;
    std::int8_t penpost = 0;
    std::int8_t pegpost = 0;
    std::int8_t pdir = 0;
    std::int8_t pxe = 0;
    std::int8_t pxedetails = 0;
    std::int8_t pndel = 0;
};

struct ProcessState {
    explicit ProcessState(data::TableSet const& table_set) : tables{&table_set} {}

    data::TableSet const* tables; // NucTab, Isotab, mass tables (M4); never null
    params::Parameters params;    // nominal parameters incl. Emode, EOscale, D_Par_Fac, BFC
    params::PerturbationWidths widths;
    data::MatNumberState mat; // I_MAT_ENDF state; ctl/IMATmax.ctl in memory (D7)

    // stdout of the ported batch code (D3): the screen device of a redirected stdout.
    fb::PrintFile console = fb::PrintFile::console();
    // Test observation points (run/probes.hpp); the run works the same without them.
    ProbeSink* probes = nullptr;
    // The bytes ctl/done.ctl would hold (D2); the run starts in a clean directory.
    std::string done_ctl;

    // --- process and input mode
    std::int64_t i_thread = 1; // GEF.bas:857 (ctl/thread.ctl not ported: a clean run is thread 1)
    std::int64_t i_thread_max = 8; // 1761
    std::int8_t bfilein = 0;       // 1735 Static Byte: -1 once file.in is found (1822)
    std::int64_t ivalid = 0;       // 1754 (1908 Ivalid = 1)

    // --- fit mode (M16 owns the loop; M6 the flags and iteration 1)
    std::uint8_t b_fit = 0;                // 868
    std::int64_t n_iter = 0;               // 872
    std::string c_fitoption;               // 869
    std::int64_t i_fitloop = 0;            // 870 LongInt
    double chisqr_fit_present = 0.0;       // DCLplotting.bas:30 Shared Double
    std::uint8_t b_new_fit_parameters = 0; // 871
    double chisqr_min = 1.0E10;            // DCLplotting.bas:27 Shared Double

    // --- settings not covered by the per-file reset
    std::int8_t bplot = -1;       // 1725
    LmdFlags lmd;                 // 1728-1733
    std::string cfileoutlmd_full; // 1709 Static
    std::string clocal;           // 1717 Static
    std::string c_espectrum;      // 1770
    std::string c_espectrum1;     // 1771
    std::string c_espectrum2;     // 1771
    std::int64_t i_warning = 0;   // 1736

    // --- the current sequence file
    double fenhance = 0.0;           // 1712 Dim Double (3128 per file, 3695 per step, 3922)
    double fenhance_global = 0.0;    // 1757 Static Double
    std::int64_t iline = 0;          // 1737 Static
    std::int64_t iline_tot = 0;      // 1738 Static
    std::int64_t i_first_e_step = 1; // 1741 Static
    float en_min = 0.0F;             // 2652 Static
    float en_max = 0.0F;             // 2653 Static
    // 2664 `Static S_par(5000)`: filled without a bound check (the C++ throws beyond 5000).
    fb::Array<SystemLine, 1> s_par{{fb::Bounds{0, 5000}}};
    std::string ceref; // 1711

    // --- the current system
    std::int64_t p_z_cn = 92;        // 878 Shared Integer
    std::int64_t p_a_cn = 236;       // 879 Shared Integer
    float p_e_exc = 2.0F;            // 880
    float p_i_rms_cn = 0.0F;         // 890 Shared (1910 `P_I_rms_CN = 0` at every RepeatInput)
    std::uint8_t b_double_covar = 0; // 882
    std::int64_t i_double_covar = 0; // 883
    std::int64_t n_double_covar = 0; // 884
    std::int64_t p_z_cn_double = 0;  // 885
    std::int64_t p_a_cn_double = 0;  // 886
    float p_e_exc_double = 0.0F;     // 887
    std::int64_t n_e_steps = 0;      // 1739 Static
    std::int64_t i_e_iso = 0;        // 1748 Static
    std::string cfileout;            // 1708 Static
    std::string cfileout_single;     // 1708
    std::string cfileout_full;       // 1708
    std::string c_pfis;              // 814
    std::string c_pfis2;             // 815

    // --- the current energy step
    std::int64_t i_e_step = 0;         // 1740 Static
    std::int64_t i_error = 0;          // 864
    std::uint8_t b_error_analysis = 0; // 862
    std::int64_t n_error_max = 10;     // 863
    std::string csystem;               // 1707 Static
    float e_exc_iso = 0.0F;            // 832 Static
    float e_exc_true = 0.0F;           // 832 Static
    float spin_cn = 0.0F;              // 1749 Static (ES/EM steps: what the last bin wrote)
    float spin_target = 0.0F;          // 1749 Static
    float eabsgs = 0.0F;               // 1742
    float bprot = 0.0F;                // 772 Shared
    float balpha = 0.0F;               // 772 Shared

    // --- written by later stages (step body), read by the set-up or dumped at P1. M6 never
    // writes them; a step body may (MILESTONE_6_PLAN.md M6.0 patch check).
    float z = 0.0F;               // 790 Shared `Z` (table builder; Q-007)
    float t = 0.0F;               // 823 Shared `T`
    float pz_s3_olap_curv = 0.0F; // working copy read by GEF.bas:2610 (Q-019; set by M12)
};

// GEF.bas:2647-2684.
struct InputRoundState {
    std::string c_energy_table;                               // 2647
    fb::Array<float, 1> energy_table{{fb::Bounds{0, 1}}};     // 2648 Redim Energy_Table(1)
    fb::Array<float, 1> spin_table{{fb::Bounds{0, 1}}};       // 2649
    std::int64_t n_e_values = 1;                              // 2650
    std::int64_t i_first = 0;                                 // 2651
    std::int64_t i_last = 0;                                  // 2651
    std::int64_t i_step = 0;                                  // 2651
    std::int64_t n_values = 0;                                // 2651
    fb::Array<float, 1> e_spectrum{{fb::Bounds{0, 1}}};       // 2669
    fb::Array<float, 1> l_spectrum{{fb::Bounds{0, 1}}};       // 2670
    fb::Array<float, 1> w_spectrum{{fb::Bounds{0, 1}}};       // 2671
    fb::Array<std::int64_t, 1> ne_all{{fb::Bounds{0, 1}}};    // 2672 LongInt
    fb::Array<std::int64_t, 1> ne_fis{{fb::Bounds{0, 1}}};    // 2673 LongInt
    std::int64_t i_estep = 0;                                 // 2674 LongInt
    float w_spectrum_max = 0.0F;                              // 2675
    float ichannel = 0.0F;                                    // 2676 (a Single counter)
    std::string chelp;                                        // 2681
    fb::Array<std::string, 1> cfilein{{fb::Bounds{0, 1000}}}; // 2682
    std::int64_t ifilein = 0;                                 // 2683
    std::int64_t nfilein = 0;                                 // 2684
};

// GEF.bas:2827-2842 (the values right after the reset), changed by Options(...) and later by
// system lines (3273-3274) and the step schedule (3459-3490).
struct SequenceFileState {
    std::uint8_t b_error_on = 0;                 // 861 Shared UByte
    std::int8_t brec = 0;                        // 1721
    std::int8_t bcov = 0;                        // 1722
    std::int8_t bcor = 0;                        // 1723
    std::uint8_t b_supp = 1;                     // 793 Shared UByte
    std::uint8_t b_endf = 0;                     // 431
    std::uint8_t b_random_on = 0;                // 874
    std::string cfileoutlmd;                     // 1709 Static
    std::string clocal_file_option = "localoff"; // 1718 Static
    std::int64_t i_mode_selected = -1;           // 783 Shared
};

// GEF.bas:3914-3945, the part M6 sets (the rest belongs to the pre-pass, M9).
struct StepState {
    std::int64_t bmulti = 0;         // 3920 (3972 `Bmulti = 1` when the pre-pass runs)
    std::int64_t n_multi_sample = 0; // 3921 LongInt (3926)
    bool prepass = false; // the decision of 3967 (`Eabsgs >= Eexc_min_multi Or Emode = 13`)
};

// What BASIC does after a block of the input or the set-up: carry on, leave the system line
// (`Goto Next_Iline_label`, GEF.bas:3384, or `Continue For`, 3222), start the input again
// (`Goto RepeatInput`, 3567), or stop the program (`Sleep : End` after an error message).
enum class Flow : std::uint8_t {
    Proceed,
    NextLine,
    Restart,
    End,
};

} // namespace gef::run
