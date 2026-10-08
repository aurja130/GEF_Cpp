#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Aurora Jahan
# Licensed under the GNU GPL v3 or later, WITHOUT ANY WARRANTY; see LICENSE.txt.
#
# Long-running M1 gates (Planning/MILESTONE_1_PLAN.md §5), run on demand, not in CI.
#
# Usage: harness/gates.sh <g1|g23|g4|all> [--out DIR]     (default DIR: build/m1_gates)
#   g1   capture the seed from gef_reference for both M1 inputs, replay it with the seed
#        build, compare byte for byte (masked)                       ~65 min, 4 GEF runs
#   g23  G2 repeatability and G3 neutrality on m1_rn215_short, normal and reseed mode,
#        probes/logging traced at steps 2 and 8 (18.5 MeV), passes 0 and 31    ~45 min, 11 runs
#   g4   the g1 ref-1 runs judged by the M2 statistical verdict against the stored
#        calibrations m2-cal-m1-rn215-short and m2-cal-m1-cf252-gs   ~2 min, no GEF runs
#   all  g1, g23 and g4
# Results: DIR/g1/<input>/{ref,seed}, DIR/g23/<run>, DIR/verdict_<input>.txt, one log per gate.
# Exit status: 0 if every requested gate passed, 1 otherwise.

set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

gate="${1:-}"
shift || true
out="build/m1_gates"
if [[ "${1:-}" == "--out" && -n "${2:-}" ]]; then
    out="$2"
elif [[ $# -gt 0 ]]; then
    echo "usage: harness/gates.sh <g1|g23|g4|all> [--out DIR]" >&2
    exit 2
fi
case "$gate" in g1 | g23 | g4 | all) ;; *)
    echo "usage: harness/gates.sh <g1|g23|g4|all> [--out DIR]" >&2
    exit 2
    ;;
esac
mkdir -p "$out"
failed=0

binary() { # binary <patch set> [define ...]
    local set=$1
    shift
    python3 -c "import sys; from harness.build import build; print(build(sys.argv[1], defines=tuple(sys.argv[2:])).binary)" "$set" "$@"
}

compare() { # compare <label> <dirA> <dirB>
    local label=$1 a=$2 b=$3 report
    report="$out/compare_$(basename "$a")_$(basename "$b").txt"
    if python3 -m harness.compare_runs "$a" "$b" \
        --allow-only-in-b 'work/probes/*' --allow-only-in-b work/rnd.log >"$report" 2>&1; then
        echo "PASS $label: $(tail -n 1 "$report")"
    else
        echo "FAIL $label: $(tail -n 1 "$report") (report: $report)"
        failed=1
    fi
}

run_g1() {
    local name input dir seed seed_bin
    seed_bin=$(binary seed) || return 1
    for name in m1_rn215_short m1_cf252_gs; do
        (
            input="harness/inputs/$name.in"
            dir="$out/g1/$name"
            mkdir -p "$dir"
            python3 -m harness.capture_seed --input "$input" --out "$dir/ref" >"$dir/capture.log" 2>&1 || exit 1
            seed=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['captured_seed'])" "$dir/ref/run.json")
            python3 -m harness.run --binary "$seed_bin" --input "$input" --seed "$seed" \
                --out "$dir/seed" >"$dir/run.log" 2>&1
        ) &
    done
    wait
    for name in m1_rn215_short m1_cf252_gs; do
        compare "G1 $name" "$out/g1/$name/ref" "$out/g1/$name/seed"
    done
}

run_g23() {
    local input=harness/inputs/m1_rn215_short.in seed=20261007 dir="$out/g23"
    local scope=(--scope steps=2,8 --scope passes=0,31 --scope events=1-20)
    local b_seed b_probes b_rnd b_rp b_rs b_rsp b_rsr b_rsrp
    b_seed=$(binary seed) && b_probes=$(binary seed-probes GEF_PROBES) &&
        b_rnd=$(binary seed-rndlog GEF_RNDLOG) &&
        b_rp=$(binary seed-rndlog-probes GEF_RNDLOG GEF_PROBES) &&
        b_rs=$(binary seed-reseed) && b_rsp=$(binary seed-reseed-probes GEF_PROBES) &&
        b_rsr=$(binary seed-reseed-rndlog GEF_RNDLOG) &&
        b_rsrp=$(binary seed-reseed-rndlog-probes GEF_RNDLOG GEF_PROBES) || return 1
    mkdir -p "$dir"
    one() { # one <name> <binary> [run args]
        local name=$1 bin=$2
        shift 2
        python3 -m harness.run --binary "$bin" --input "$input" --seed "$seed" \
            --out "$dir/$name" "$@" >"$dir/$name.log" 2>&1 || echo "RUN FAILED: $name"
    }
    one n_a "$b_seed" &
    one n_b "$b_seed" &
    one n_probes "$b_probes" "${scope[@]}" &
    one n_rnd "$b_rnd" "${scope[@]}" &
    one n_rp "$b_rp" "${scope[@]}" &
    one n_reseedinert "$b_rs" &
    one r_a "$b_rs" --reseed &
    one r_b "$b_rs" --reseed &
    one r_probes "$b_rsp" --reseed "${scope[@]}" &
    one r_rnd "$b_rsr" --reseed "${scope[@]}" &
    one r_rp "$b_rsrp" --reseed "${scope[@]}" &
    wait
    compare "G2 normal" "$dir/n_a" "$dir/n_b"
    compare "G2 reseed" "$dir/r_a" "$dir/r_b"
    local b
    for b in n_probes n_rnd n_rp n_reseedinert; do compare "G3 normal" "$dir/n_a" "$dir/$b"; done
    for b in r_probes r_rnd r_rp; do compare "G3 reseed" "$dir/r_a" "$dir/$b"; done
}

verdict() { # verdict <label> <calibration id> <run dir>
    local label=$1 calibration="validation/reference_store/captures/$2" run=$3
    local report="$out/verdict_$label.txt"
    if python3 -m compare.verdict --calibration "$calibration" --candidate "$run" \
        --text "$report" >"$out/verdict_$label.log" 2>&1; then
        echo "PASS G4 $label: $(head -n 1 "$report")"
    else
        echo "FAIL G4 $label: $(head -n 1 "$report" 2>/dev/null) (report: $report)"
        failed=1
    fi
}

run_g4() {
    verdict rn215 m2-cal-m1-rn215-short "$out/g1/m1_rn215_short/seed"
    verdict cf252 m2-cal-m1-cf252-gs "$out/g1/m1_cf252_gs/seed"
}

case "$gate" in
    g1) run_g1 ;;
    g23) run_g23 ;;
    g4) run_g4 ;;
    all) run_g1 && run_g23 && run_g4 ;;
esac
exit "$failed"
