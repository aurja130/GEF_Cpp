// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

#include "run/workdir.hpp"

#include "params/parameter_files.hpp"

#include <algorithm>
#include <fstream>
#include <utility>

namespace gef::run {

WorkDir::WorkDir(std::filesystem::path root) : root_{std::move(root)} {}

std::filesystem::path WorkDir::resolve(std::string_view path) const {
    std::string name{path};
    std::ranges::replace(name, '\\', '/');
    std::filesystem::path const rel{name};
    return rel.is_absolute() ? rel : root_ / rel;
}

std::optional<std::string> WorkDir::read(std::string_view path) const {
    return params::read_input_file(resolve(path));
}

bool WorkDir::exists(std::string_view path) const {
    // fb_FileExists: fopen(filename, "r") (libstdc++'s filebuf opens with fopen as well).
    std::ifstream const file(resolve(path), std::ios::binary);
    return file.is_open();
}

} // namespace gef::run
