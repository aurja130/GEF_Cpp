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

std::filesystem::path WorkDir::join(std::string_view path) const {
    std::filesystem::path const rel{std::string{path}};
    return rel.is_absolute() ? rel : root_ / rel;
}

// fb_DevFileOpen converts each backslash to a slash (fb_hConvertPath) before the open.
std::filesystem::path WorkDir::resolve(std::string_view path) const {
    std::string name{path};
    std::ranges::replace(name, '\\', '/');
    return join(name);
}

std::optional<std::string> WorkDir::read(std::string_view path) const {
    // The empty name is rejected here and in exists(): fopen("") fails (ENOENT); joined to the
    // root, "" would name the root directory instead.
    if (path.empty()) {
        return std::nullopt;
    }
    return params::read_input_file(resolve(path));
}

bool WorkDir::exists(std::string_view path) const {
    // fb_FileExists: fopen(filename, "r") (libstdc++'s filebuf opens with fopen as well), on the
    // name as given: no backslash conversion (fb_FileExists does none), so join(), not resolve().
    // FileExists("") is 0 with fbc 1.10.1.
    if (path.empty()) {
        return false;
    }
    std::ifstream const file(join(path), std::ios::binary);
    return file.is_open();
}

} // namespace gef::run
