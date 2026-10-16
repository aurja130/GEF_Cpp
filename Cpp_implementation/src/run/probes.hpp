// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// Observation points that match the harness probes of the BASIC program (harness/PROBES.md):
// the run code calls them where the BASIC build with GEF_PROBES writes P0, P1 and P1b, so a test
// can dump the C++ state at exactly the same point. The run never reads anything back; with no
// sink set (ProcessState::probes == nullptr) nothing happens.

#pragma once

namespace gef::run {

struct ProcessState;
struct InputRoundState;
struct SequenceFileState;
struct StepState;

class ProbeSink {
public:
    ProbeSink() = default;
    ProbeSink(ProbeSink const&) = default;
    ProbeSink(ProbeSink&&) = default;
    ProbeSink& operator=(ProbeSink const&) = default;
    ProbeSink& operator=(ProbeSink&&) = default;
    virtual ~ProbeSink() = default;

    // P0: after GEF.bas:3128 (`Fenhance = Fenhance_global`), once per sequence file read.
    virtual void sequence_file(ProcessState const& /*process*/, InputRoundState const& /*round*/,
                               SequenceFileState const& /*file*/) {}

    // P1: before GEF.bas:3882, after the entrance-channel set-up of the step.
    virtual void step_setup(ProcessState const& /*process*/, InputRoundState const& /*round*/,
                            SequenceFileState const& /*file*/) {}

    // P1b: after GEF.bas:3966 (before the decision of 3967) for the channels inside the `If` of
    // 3948, after 3947 for the others; `prepass` is the value of GEF's condition at 3967 for the
    // former and false for the latter.
    virtual void step_threshold(ProcessState const& /*process*/, StepState const& /*step*/,
                                bool /*prepass*/) {}
};

} // namespace gef::run
