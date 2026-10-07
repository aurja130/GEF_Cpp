# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""One unpatched emission shared by every test that needs generated C."""

from __future__ import annotations

import pytest

from tools.fbsrc.emit_c import Emission, emit


@pytest.fixture(scope="session")
def emission() -> Emission:
    """The unpatched emission; reused from ``build/fbsrc/`` when it is already there."""
    return emit()
