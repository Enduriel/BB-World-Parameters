#!/bin/bash
# Run one world_parameters config on the modern engine's world_fights (modern_engine repo,
# bb-engine/examples/world_fights.rs), headless.
#
#   run_world_fights.sh OUTDIR NAME MSU WP_ZIP [world_fights args...]
#
# NAME: a file in settings/ (without .nut). MSU: "installed" (the install's mod_msu, 1.9.0)
# or a path to an MSU zip (e.g. 1.7.2). WP_ZIP: the world_parameters build under test.
# Extra args go to world_fights, e.g. --days 20 --save-every-days 5 --chain 2.
# Writes OUTDIR/NAME.log (world_fights' log), .stdout, .stderr and .time.
# WF_WORLD_SCRIPT: comma-separated --world-script files, run in order (default worldgen_report.nut).
# WF_TIMEOUT: world_fights --timeout in seconds (default 900). Don't run two world_fights at once.
# Fights: python3 fights.py OUTDIR/NAME.log
set -u
out=$1 name=$2 msu=$3 wp=$4; shift 4
here=$(cd "$(dirname "$0")" && pwd)
engine=/home/end/dev/battle_brothers/modern_engine/modern-bb-engine/modern_bb_engine
export CARGO_TARGET_DIR=/home/end/dev/battle_brothers/scratch-targets/llm-mods
mkdir -p "$out"
(cd "$engine" && cargo build -q --release -p bb-engine --example world_fights) || exit 1
if [ "$msu" = installed ]; then mods=mod_modern_hooks,mod_msu; extra=$wp; else mods=mod_modern_hooks; extra=$msu,$wp; fi
scripts=()
IFS=, read -ra list <<< "${WF_WORLD_SCRIPT:-$here/worldgen_report.nut}"
for f in "${list[@]}"; do scripts+=(--world-script "$f"); done
limit=${WF_TIMEOUT:-900}
# world_fights --timeout stops a stuck run (a worldgen that never finishes) with exit 124 and logs the
# stuck script's stack; the outer timeout is only a backstop.
/usr/bin/time -v -o "$out/$name.time" timeout $((limit + 120)) \
	systemd-run --user --scope -q -p CPUQuota=100% -p MemoryMax=6G \
	"$CARGO_TARGET_DIR/release/examples/world_fights" --mods "$mods" --extra "$extra" \
	--settings "$here/settings/$name.nut" "${scripts[@]}" --timeout "$limit" \
	--saves "$out/saves" --out "$out/$name.log" "$@" >"$out/$name.stdout" 2>"$out/$name.stderr"
rc=$?
echo "$name rc=$rc wall=$(grep 'Elapsed' "$out/$name.time" | awk '{print $NF}')"
exit $rc
