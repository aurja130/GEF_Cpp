// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// The dumps of BASIC's probes P1 (the set-up of each energy step, before GEF.bas:3882) and P1b (the
// threshold of each channel, after GEF.bas:3966), written from the C++ state at the probe points of
// run/probes.hpp. run_corpus_test.cpp checks each record against the golden and the stored probes.

#pragma once

#include "run/state.hpp"
#include "support/probe_dump.hpp"

#include <array>
#include <cstdint>
#include <string_view>

namespace gef::test {

// P1 (ProbeSink::step_setup): the 205 variables of BASIC's P1 record `rec` (numbered from 1 within
// its run). The context is `step=<I_E_step> pass=- bin=- rec=<rec>`.
[[nodiscard]] ProbeDump dump_p1(run::ProcessState const& process, run::InputRoundState const& round,
                                run::SequenceFileState const& file, std::int64_t rec);

// P1b (ProbeSink::step_threshold): four variables per record. `prepass` is the decision of
// GEF.bas:3967 as the probe hook passes it.
[[nodiscard]] ProbeDump dump_p1b(run::ProcessState const& process, run::StepState const& step,
                                 bool prepass, std::int64_t rec);

// The variables a full run leaves out of P1 before the digest and the store comparison. The
// `exclude-full` line of the m6-setup golden lists them in this order (contract §Golden m6-setup).
inline constexpr std::array<std::string_view, 4> full_run_excluded_p1{"Spin_CN", "T",
                                                                      "Var_PZ_S3_olap_curv", "Z"};

} // namespace gef::test
