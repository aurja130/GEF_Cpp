# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
"""Wait out a nearly used-up usage window (`.omp/AGENTS.md`, usage limits).

Usage (from the repository root)::

    python3 -m tools.agent.wait_for_usage [--provider anthropic] [--threshold 0.05]
                                          [--horizon-min 300] [--dry-run]

Reads ``omp usage --json --provider <provider>``. A window is *low* when less than
``threshold`` of it remains (default: more than 95 % used). A low window is *waited for* when
it resets within ``horizon-min`` minutes (default 5 hours: the 5-hour window always, the 7-day
window in its last 5 hours).

- No low window: print why and return at once.
- Some low windows are waited for: sleep until the last of them has reset (plus a minute), drop
  omp's cached report, check again (at most three waits). Low windows that are not waited for
  (resetting later, or without a reset time) are reported and do not stop the wait.
- Only low windows that are not waited for: return at once; work continues and uses up the
  remaining allowance.

``--dry-run`` prints the decision without sleeping. Exit codes: 0 done (keep working);
1 the usage report could not be read; 2 command-line usage error (argparse).
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from collections.abc import Sequence
from dataclasses import dataclass
from typing import cast

RESET_MARGIN_S = 60.0
MAX_WAITS = 3
OMP_TIMEOUT_S = 120


@dataclass(frozen=True)
class Window:
    """One usage window of one account."""

    label: str
    remaining: float  # fraction of the window still available, 0..1
    resets_at_ms: int | None  # Unix epoch milliseconds; None when omp reports no reset time


@dataclass(frozen=True)
class Decision:
    """How long to wait (0 means keep working) and why."""

    wait_s: float
    reason: str


def _field(obj: object, key: str) -> object:
    if isinstance(obj, dict):
        return cast(dict[str, object], obj).get(key)
    return None


def _items(obj: object) -> list[object]:
    return cast(list[object], obj) if isinstance(obj, list) else []


def parse_windows(report: object) -> list[Window]:
    """The windows of an ``omp usage --json`` report that state a remaining fraction."""
    windows: list[Window] = []
    for account in _items(_field(report, "reports")):
        for limit in _items(_field(account, "limits")):
            remaining = _field(_field(limit, "amount"), "remainingFraction")
            if not isinstance(remaining, int | float):
                continue
            resets_at = _field(_field(limit, "window"), "resetsAt")
            label = _field(limit, "label")
            windows.append(
                Window(
                    label=label if isinstance(label, str) else "unnamed window",
                    remaining=float(remaining),
                    resets_at_ms=int(resets_at) if isinstance(resets_at, int | float) else None,
                )
            )
    return windows


def decide(windows: Sequence[Window], now_ms: int, threshold: float, horizon_s: float) -> Decision:
    """Wait for the low windows that reset within the horizon."""
    low = [w for w in windows if w.remaining < threshold]
    if not low:
        return Decision(0.0, f"keep working: every window has at least {threshold:.0%} left")

    def waited_for(w: Window) -> bool:
        return w.resets_at_ms is not None and (w.resets_at_ms - now_ms) / 1000 <= horizon_s

    wait_for = [w for w in low if waited_for(w)]
    other = [w for w in low if not waited_for(w)]
    note = ""
    if other:
        names = ", ".join(w.label for w in other)
        note = (
            f"; {names} below {threshold:.0%} but not resetting within "
            f"{horizon_s / 60:.0f} min, waiting for it does not help"
        )
    if not wait_for:
        return Decision(0.0, f"keep working{note}")
    last_reset_ms = max(cast(int, w.resets_at_ms) for w in wait_for)
    wait_s = max((last_reset_ms - now_ms) / 1000, 0.0) + RESET_MARGIN_S
    names = ", ".join(w.label for w in wait_for)
    return Decision(wait_s, f"waiting {wait_s / 60:.1f} min for {names} to reset{note}")


def _read_report(provider: str) -> object:
    proc = subprocess.run(
        ["omp", "usage", "--json", "--provider", provider],
        capture_output=True,
        text=True,
        check=True,
        timeout=OMP_TIMEOUT_S,
    )
    return cast(object, json.loads(proc.stdout))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0] if __doc__ else None)
    parser.add_argument("--provider", default="anthropic", help="omp provider id")
    parser.add_argument("--threshold", type=float, default=0.05, help="low below this fraction")
    parser.add_argument("--horizon-min", type=float, default=300.0, help="longest wait, minutes")
    parser.add_argument("--dry-run", action="store_true", help="print the decision, do not sleep")
    args = parser.parse_args(argv)
    provider = cast(str, args.provider)
    threshold = cast(float, args.threshold)
    horizon_s = cast(float, args.horizon_min) * 60
    dry_run = cast(bool, args.dry_run)

    for _ in range(MAX_WAITS):
        try:
            windows = parse_windows(_read_report(provider))
        except (OSError, subprocess.SubprocessError, json.JSONDecodeError) as exc:
            print(f"wait_for_usage: cannot read omp usage: {exc}", file=sys.stderr)
            return 1
        if not windows:
            print(f"wait_for_usage: omp reports no usage windows for {provider}", file=sys.stderr)
            return 1
        decision = decide(windows, time.time_ns() // 1_000_000, threshold, horizon_s)
        print(decision.reason, flush=True)
        if decision.wait_s == 0.0 or dry_run:
            return 0
        time.sleep(decision.wait_s)
        subprocess.run(
            ["omp", "usage", "invalidate", "--provider", provider],
            capture_output=True,
            check=False,
            timeout=OMP_TIMEOUT_S,
        )
    print(f"keep working: still low after {MAX_WAITS} waits", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
