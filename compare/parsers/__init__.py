# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Parsers that turn one GEF output file into observables (M2)."""

from __future__ import annotations

__all__ = ["ParseError"]


class ParseError(ValueError):
    """A file does not follow its format; the message names the file and the line."""
