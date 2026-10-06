# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aurora Jahan
# See LICENSE.txt in the repository root for the full license text.
"""One unpatched emission shared by every test that needs generated C."""

from __future__ import annotations

import pytest

from tools.fbsrc.emit_c import Emission, emit


@pytest.fixture(scope="session")
def emission() -> Emission:
    """The unpatched emission; reused from ``build/fbsrc/`` when it is already there."""
    return emit()
