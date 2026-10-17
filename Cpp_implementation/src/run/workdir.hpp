// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Aurora Jahan
// Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.

// GEF's working directory as the batch input sees it (M6, MILESTONE_6_PLAN.md D7): every file
// the input names is read through here, relative to the root, without changing the process's
// working directory (BASIC's CHDIR("ctl") ... CHDIR("..") is not reproduced; the ctl/ files are
// state in memory).

#pragma once

#include <filesystem>
#include <optional>
#include <string>
#include <string_view>

namespace gef::run {

class WorkDir {
public:
    explicit WorkDir(std::filesystem::path root);

    // `Fileexists(path)` then `Open path For Input` and read to the end: nullopt when fopen
    // fails (params::read_input_file) or the name is empty. `path` is as GEF names it, relative
    // to the working directory; Open converts each backslash to a slash (fb_DevFileOpen).
    [[nodiscard]] std::optional<std::string> read(std::string_view path) const;

    // `Fileexists(path)`: fopen(path, "r") succeeds. The name is used as given, with no backslash
    // conversion (fb_FileExists does none): Fileexists("in\a.in") is 0 while in/a.in exists.
    // The empty name is false.
    [[nodiscard]] bool exists(std::string_view path) const;

    [[nodiscard]] std::filesystem::path const& root() const noexcept { return root_; }

private:
    // `path` as given, joined to the root; an absolute path stays as it is.
    [[nodiscard]] std::filesystem::path join(std::string_view path) const;
    // `path` with each backslash changed to a slash (fb_DevFileOpen's conversion), then joined.
    [[nodiscard]] std::filesystem::path resolve(std::string_view path) const;

    std::filesystem::path root_;
};

} // namespace gef::run
