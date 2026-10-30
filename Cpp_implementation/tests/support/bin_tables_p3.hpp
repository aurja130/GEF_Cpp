// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// The C++ state of one table-builder bin, set from BASIC's P3in record and written in P3's line
// format (MILESTONE_7_PLAN.md D1, D9), and the M7 capture corpus in the reference store.

#pragma once

#include "params/parameters.hpp"
#include "support/probe_dump.hpp"
#include "support/probe_records.hpp"
#include "tables/bin_plan.hpp"
#include "tables/bin_tables.hpp"
#include "tables/working_parameters.hpp"

#include <cstdint>
#include <filesystem>
#include <map>
#include <set>
#include <string>
#include <string_view>
#include <vector>

namespace gef::test {

// Everything the builder reads or writes in a bin, as the P3 variables name it.
struct BuilderCase {
    tables::BinPlanInput plan; // Inofirst, P_Z_CN, P_A_CN, P_E_exc, Eabsgs, NEVTtot
    std::int64_t imulti = 0;   // GEF.bas:3919 Imulti
    tables::BinInput bin;
    tables::WorkingParameters working;
    params::Parameters params; // Emode and the never-perturbed parameters
    tables::BinTables tables;
    tables::Temporaries temporaries;
    float spin_cn = 0.0F; // Spin_CN (run::ProcessState::spin_cn)
    float z = 0.0F;       // Z (run::ProcessState::z)
    std::int64_t f = 0;   // f, the file number Beta_Equi prints to (QUIRKS Q-041)
};

// The P3 names of the variables BuilderCase holds, ascending.
[[nodiscard]] std::set<std::string, std::less<>> const& builder_variable_names();

// The BASIC names of the 47 working copies (P3 group "working parameter set"), in declaration
// order.
[[nodiscard]] std::vector<std::string_view> const& working_parameter_names();

// Sets all 47 working copies to `value`.
void fill_working(tables::WorkingParameters& w, float value);

// Sets every BuilderCase variable the record holds (P3in or P3); the others keep their values.
void load_builder_case(ProbeRecord const& record, BuilderCase& c);

// The BuilderCase variables in P3's line format (arrays sparse, as P3 dumps them; left out
// unless `with_arrays`).
[[nodiscard]] ProbeDump dump_builder_case(BuilderCase const& c, std::string_view id,
                                          std::string_view context, bool with_arrays = true);

// One row of harness/inputs/m7/last_writer.tsv: the P3 variable, the part that writes it last in
// a bin (`input` when the builder does not write it) and its writers
// (`<line>:<part>[=<array target>]`).
struct LastWriter {
    std::string part;
    std::vector<std::string> writers;
};
[[nodiscard]] std::map<std::string, LastWriter, std::less<>> const& last_writer_map();

// The entry ids of the M7 corpus in the order of the golden m7-p3 (`rn215-n`, ...); the store
// capture of entry `id` is `m7-p3-<id>`.
[[nodiscard]] std::vector<std::string> const& m7_corpus_ids();

// validation/reference_store/captures/<capture>/<file> of a capture whose presence the caller
// established; throws std::runtime_error when the file is absent.
[[nodiscard]] std::filesystem::path capture_file(std::string const& capture, std::string_view file);

} // namespace gef::test
