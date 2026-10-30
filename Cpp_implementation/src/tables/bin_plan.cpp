// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "tables/bin_plan.hpp"

#include "fbrt/convert.hpp"

#include <algorithm>
#include <cmath>

namespace gef::tables {

BinPlan::BinPlan(BinPlanInput const& in, BinInput& bin) : in_{&in} {
    // GEF.bas:5490-5494 (`Dim` zeroes R_E_exc_used, I_rigid_spher and I_eff_CN)
    bin.r_e_exc_used = in.p_e_exc;
    bin.i_rigid_spher = 0.0F;
    bin.i_eff_cn = 0.0F;
    bin.i_a_cn = in.p_a_cn;
    bin.i_z_cn = in.p_z_cn;
    // GEF.bas:5051 `Dim As LongInt NEVTused,NEVTtot,IEVTtot` (once per pass) and 5497
    bin.nevtused = 0;
    bin.ievttot = 0;
    // GEF.bas:5499
    bin.r_nevtspectrum = 0x1.p+0F;
    // GEF.bas:5503-5507 (`Dim` zeroes the counters)
    bin.i_e_distr = 0;
    bin.i_e_multi = 0;
    bin.i_n_multi = 0;
    bin.i_z_multi = 0;
    bin.i_a_multi = 0;
    bin.i_n_multi_max = 0;
    bin.i_z_multi_max = 0;
    // GEF.bas:5508-5511
    bin.n_e_distr = 1;
    bin.n_n_multi = 0;
    bin.n_z_multi = 0;
    bin.n_e_multi = 0;
    // GEF.bas:5512-5514 (fb_ArrayUBound of dimension 1)
    if (in.emode == 3) {
        bin.n_e_distr = in.e_spectrum->ubound(1);
    }
    // GEF.bas:5515-5519; 5546 tests the same condition on the same values in every iteration.
    multi_ = in.inofirst > 0 || in.emode == 13;
    if (multi_) {
        bin.n_n_multi = 10;
        bin.n_z_multi = 10;
        bin.n_e_multi = 1000;
    }
}

namespace {

constexpr std::int64_t one = 1;

// GEF.bas:10001-10004 and the loop heads 5522-5531: one step of the innermost loop, entering
// the outer loops' next iterations as the closers do. The limits never change inside the loops,
// so the copies fbc takes at each loop head equal the BinInput fields.
void advance(BinInput& bin) {
    // 10001 Next I_E_multi (Step -1)
    bin.i_e_multi = fb::sub(bin.i_e_multi, one);
    if (bin.i_e_multi >= 0) {
        return;
    }
    for (;;) {
        // 10002 Next I_Z_multi
        bin.i_z_multi = fb::add(bin.i_z_multi, one);
        if (bin.i_z_multi <= bin.n_z_multi) {
            break;
        }
        // 10003 Next I_N_multi
        bin.i_n_multi = fb::add(bin.i_n_multi, one);
        if (bin.i_n_multi <= bin.n_n_multi) {
            bin.i_z_multi = -1; // 5527 re-enters at 0 through the increment above
            continue;
        }
        // 10004 Next I_E_distr
        bin.i_e_distr = fb::add(bin.i_e_distr, one);
        if (bin.i_e_distr > bin.n_e_distr) {
            return; // the loops have ended (i_e_multi stays -1)
        }
        bin.i_n_multi = 0; // 5526
        bin.i_z_multi = -1;
    }
    // GEF.bas:5530-5531
    bin.i_a_multi = fb::add(bin.i_n_multi, bin.i_z_multi);
    bin.i_e_multi = bin.n_e_multi;
}

} // namespace

void BinPlan::inputs(BinInput& bin, float& spin_cn) const {
    BinPlanInput const& in = *in_;
    if (multi_) {
        // GEF.bas:5547-5550
        bin.i_a_cn = fb::sub(fb::sub(in.p_a_cn, bin.i_n_multi), bin.i_z_multi);
        bin.i_z_cn = fb::sub(in.p_z_cn, bin.i_z_multi);
        bin.r_e_exc_used =
            static_cast<float>(static_cast<double>(bin.i_e_multi) * 0x1.999999999999Ap-4);
        bin.r_nevtspectrum = (*in.e_multi_chance)(bin.i_n_multi, bin.i_z_multi, bin.i_e_multi);
        // GEF.bas:5551-5553
        if (in.emode == 13) {
            spin_cn = 0x0p+0F;
        }
    } else {
        // GEF.bas:5555
        bin.i_a_cn = in.p_a_cn;
        if (in.emode == 3) {
            // GEF.bas:5557-5559
            bin.r_e_exc_used = (*in.e_spectrum)(bin.i_e_distr);
            spin_cn = (*in.l_spectrum)(bin.i_e_distr);
            bin.r_nevtspectrum = (*in.w_spectrum)(bin.i_e_distr);
        } else {
            // GEF.bas:5561
            bin.r_e_exc_used = in.eabsgs;
        }
    }
    // GEF.bas:5565 (1.16E0^2 folded by fbc)
    double const vr2 =
        std::pow(static_cast<double>(static_cast<float>(bin.i_a_cn)), 0x1.AAACD9E83E426p+0);
    bin.i_rigid_spher = static_cast<float>((vr2 * 0x1.58793DD97F62Bp+0) / 0x1.9F5DB22D0E56p+6);
    // GEF.bas:5566
    bin.i_eff_cn = static_cast<float>(
        static_cast<double>(bin.i_rigid_spher) *
        // NOLINTNEXTLINE(modernize-use-std-numbers): 0.693E0 as in GEF.c, not ln 2
        (-(std::exp((static_cast<double>(bin.r_e_exc_used) * -0x1.62D0E56041893p-1) / 0x1.4p+2) *
           0x1.999999999999Ap-1) +
         0x1.p+0));
    // GEF.bas:5567
    bin.e_rot_cn = static_cast<float>(static_cast<double>(spin_cn * (spin_cn + 0x1.p+0F)) /
                                      static_cast<double>(bin.i_eff_cn * 0x1.p+1F));
    // GEF.bas:5569
    bin.nevtused = fb::f2l(static_cast<float>(in.nevttot) * bin.r_nevtspectrum);
}

bool BinPlan::next(BinInput& bin, float& spin_cn) {
    if (done_) {
        return false;
    }
    if (!started_) {
        // GEF.bas:5522-5531, first entry: the loop tests run before the first body.
        started_ = true;
        bin.i_e_distr = 1;
        if (bin.i_e_distr > bin.n_e_distr) {
            done_ = true;
            return false;
        }
        bin.i_n_multi = 0;
        bin.i_z_multi = 0;
        bin.i_a_multi = fb::add(bin.i_n_multi, bin.i_z_multi);
        bin.i_e_multi = bin.n_e_multi;
    } else {
        advance(bin);
    }
    for (;;) {
        if (bin.i_e_distr > bin.n_e_distr) {
            done_ = true;
            return false;
        }
        inputs(bin, spin_cn);
        // GEF.bas:5577
        if (bin.nevtused > 0) {
            return true;
        }
        advance(bin);
    }
}

void enter_bin(BinInput& bin, std::int64_t emode, float spin_cn, fb::PrintFile& console) {
    // GEF.bas:5584-5586
    if (emode == 3) {
        console.print("E_exc: ", fb::PrintEnd::None);
        console.print(bin.r_e_exc_used, fb::PrintEnd::Pad);
        console.print(", spin: ", fb::PrintEnd::None);
        console.print(spin_cn, fb::PrintEnd::Pad);
        console.print(", normalized weight: ", fb::PrintEnd::None);
        console.print(bin.r_nevtspectrum, fb::PrintEnd::Newline);
    }
    // GEF.bas:5597-5598
    bin.i_n_multi_max = std::max(bin.i_n_multi_max, bin.i_n_multi);
    bin.i_z_multi_max = std::max(bin.i_z_multi_max, bin.i_z_multi);
}

} // namespace gef::tables
