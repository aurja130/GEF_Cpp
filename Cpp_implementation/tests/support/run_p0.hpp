// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// The dump of BASIC's probe P0: the state that read_sequence_file leaves for one record of a
// sequence file (GEF.bas:2769-3133), as the probe writes it at GEF.bas:3128. M6.1's test compares
// these dumps with the golden fingerprints and with BASIC's P0.txt files of the reference store.

#pragma once

#include "run/state.hpp"
#include "support/probe_dump.hpp"

#include <cstdint>

namespace gef::test {

// The P0 dump of record `rec` (the 1-based number of the P0 record within its run): id `P0`,
// context `step=- pass=- bin=- rec=<rec>`, and the variables of harness_probe_p0.bi in BASIC's
// order, with BASIC's names and types.
[[nodiscard]] ProbeDump dump_p0(run::ProcessState const& process, run::InputRoundState const& round,
                                run::SequenceFileState const& file, std::int64_t rec);

} // namespace gef::test
