// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
// Ported from GEF 2025/1.2, Copyright (C) 2009-2025 Karl-Heinz Schmidt and Beatriz Jurado.

#include "data/program_data.hpp"

#include "data/data_block.hpp"
#include "data/generated/tables.hpp"

#include <algorithm>
#include <cctype>
#include <cstddef>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace gef::data {
namespace {

VariantTables const& tables_for(NuclideData variant) {
    switch (variant) {
    case NuclideData::Jeff33:
        return generated::variant_jeff33;
    case NuclideData::Jeff311:
        return generated::variant_jeff311;
    case NuclideData::Nubase2016:
        return generated::variant_nubase2016;
    case NuclideData::Nubase2020:
        return generated::variant_nubase2020;
    case NuclideData::LegacyX:
        return generated::variant_legacy_x;
    case NuclideData::LegacyMf:
        return generated::variant_legacy_mf;
    case NuclideData::LegacyF:
        return generated::variant_legacy_f;
    }
    std::unreachable();
}

} // namespace

std::string_view isosource(NuclideData variant) noexcept {
    return tables_for(variant).isosource;
}

ProgramData::ProgramData(NuclideData variant) : variant_{variant} {
    VariantTables const& tables = tables_for(variant);

    std::size_t total = 0;
    for (DataBlock const* block : tables.chain) {
        total += block->items;
    }
    items_.reserve(total);

    // Index of each block's first item, for the labels.
    std::vector<std::size_t> block_start;
    block_start.reserve(tables.chain.size());
    for (DataBlock const* block : tables.chain) {
        block_start.push_back(items_.size());
        std::string_view rest = block->text;
        for (std::size_t i = 0; i < block->items; ++i) {
            std::size_t const end = rest.find('\n');
            if (end == std::string_view::npos) {
                throw std::logic_error("DATA block is missing its item terminator");
            }
            items_.push_back(rest.substr(0, end));
            rest.remove_prefix(end + 1);
        }
    }

    labels_.reserve(tables.labels.size());
    for (LabelEntry const& entry : tables.labels) {
        labels_.emplace_back(std::string{entry.name}, block_start.at(entry.block));
    }
    std::ranges::sort(labels_, {}, &std::pair<std::string, std::size_t>::first);
}

std::size_t ProgramData::label(std::string_view basic_label) const {
    std::string key;
    key.reserve(basic_label.size());
    for (char const c : basic_label) {
        key.push_back(static_cast<char>(std::toupper(static_cast<unsigned char>(c))));
    }
    auto const found =
        std::ranges::lower_bound(labels_, key, {}, &std::pair<std::string, std::size_t>::first);
    if (found == labels_.end() || found->first != key) {
        throw std::out_of_range("no DATA block for Restore label " + std::string{basic_label});
    }
    return found->second;
}

} // namespace gef::data
