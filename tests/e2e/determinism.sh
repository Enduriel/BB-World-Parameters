#!/bin/bash
# Same seed and settings must give the same map every run. For each settings name, runs world_fights three
# times with worldgen_report.nut and compares its "map hash" (every settlement's name and tile, every
# faction): run a in a fresh saves folder, run b in the same folder (now holding the MSU#*.sav storages run
# a wrote), run c in another fresh folder. Runs one at a time (world_fights runs mustn't overlap).
#
#   determinism.sh OUTDIR WP_ZIP [NAME...]      (default names: lfoj fewer factions9)
#
# Prints one line per settings name, "same" or "DIFFERENT", and exits 1 if any differ.
# Original game (2026-10-21): two campaign runs of worldgen_report.nut --setup settings/lfoj.nut at seed
# VUQJTMOOMN gave the same map hash (7685322, 38 settlements), and so does the modern engine with the same
# effective settings. (An earlier 9097029 vs 7685322 wasn't an engine difference: the original had loaded
# old World Parameters values from the user's stored MSU#mod_msu#ModSettings.sav for the settings lfoj.nut
# didn't set. Every settings/*.nut now resets all of them to their defaults first.)
set -u
out=$1 wp=$2; shift 2
names=${*:-lfoj fewer factions9}
here=$(cd "$(dirname "$0")" && pwd)
status=0
for name in $names; do
	"$here/run_world_fights.sh" "$out/$name/ab" "$name" installed "$wp" --seed VUQJTMOOMN --days 0 >/dev/null
	cp "$out/$name/ab/$name.log" "$out/$name/a.log"
	"$here/run_world_fights.sh" "$out/$name/ab" "$name" installed "$wp" --seed VUQJTMOOMN --days 0 >/dev/null
	cp "$out/$name/ab/$name.log" "$out/$name/b.log"
	"$here/run_world_fights.sh" "$out/$name/c" "$name" installed "$wp" --seed VUQJTMOOMN --days 0 >/dev/null
	cp "$out/$name/c/$name.log" "$out/$name/c.log"
	hashes=$(for r in a b c; do grep -a -m1 "PROBE map hash = " "$out/$name/$r.log" | sed 's/.*= //'; done | tr '\n' ' ')
	counts=$(for r in a b c; do grep -a -m1 "PROBE settlements = " "$out/$name/$r.log" | sed 's/.*= //'; done | tr '\n' ' ')
	if [ "$(echo $hashes | tr ' ' '\n' | sort -u | wc -l)" = 1 ] && [ -n "${hashes// /}" ]; then
		echo "$name: same (hash $hashes, settlements $counts)"
	else
		echo "$name: DIFFERENT (hashes $hashes, settlements $counts)"; status=1
	fi
done
exit $status
