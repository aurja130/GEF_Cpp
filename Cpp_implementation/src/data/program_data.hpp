// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

// The DATA items of GEF (M4.2): every item in the order Read sees them, for one nuclide-data
// variant, with the positions of the BASIC labels that Restore uses. The items are the texts
// fbc stores (extracted from the emitted C by tools/fbsrc/gen_gef_data.py, plan D1), so a
// fb::DataReader over items() reads exactly what the compiled BASIC reads.

#pragma once

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace gef::data {

// The nuclide-data file included at GEF.bas:1052 (M4 plan D3). The branchings are always
// DCLbranchingJEFF33.bas (DCLbranchingJEFF311.bas does not compile with GEF 2025/1.2).
enum class NuclideData : std::uint8_t {
    Jeff33,     // NucPropJEFF33.bas, the reference binary's choice (default, fully certified)
    Jeff311,    // NucPropJEFF311.bas
    Nubase2016, // NucPropNUBASE2016.bas
    Nubase2020, // NucPropNUBASE2020.bas (GEF stops while loading it, QUIRKS.md Q-032)
    LegacyX,    // NucPropx.bas  (needs the legacy-isosource compatibility patch)
    LegacyMf,   // NucPropmf.bas (likewise)
    LegacyF,    // NucPropf.bas  (likewise)
};

// The variant's ISOSOURCE string, which selects GEF's `#If ISOSOURCE = …` branches.
[[nodiscard]] std::string_view isosource(NuclideData variant) noexcept;

class ProgramData {
public:
    explicit ProgramData(NuclideData variant);

    [[nodiscard]] NuclideData variant() const noexcept { return variant_; }

    // All DATA items in Read order (fbc's block chain, from the first block).
    [[nodiscard]] std::span<std::string_view const> items() const noexcept { return items_; }

    // The item index a `Restore <label>` moves to. BASIC labels are case-insensitive.
    // Throws std::out_of_range for a label that has no DATA block.
    [[nodiscard]] std::size_t label(std::string_view basic_label) const;

private:
    NuclideData variant_;
    std::vector<std::string_view> items_;
    std::vector<std::pair<std::string, std::size_t>> labels_; // upper-case label, item index
};

} // namespace gef::data
