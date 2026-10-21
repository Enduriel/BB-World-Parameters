#!/bin/bash
# build_restart_mod.sh OUTDIR: zip the restart test mod as OUTDIR/mod_zz_wp_e2e_restart.zip
set -e
out=$(cd "$1" && pwd)/mod_zz_wp_e2e_restart.zip
rm -f "$out"
cd "$(dirname "$0")/restart_mod"
7z a -tzip "$out" "scripts/!mods_preload/mod_zz_wp_e2e_restart.nut" >/dev/null
echo "$out"
