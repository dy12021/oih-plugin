#!/usr/bin/env bash
# p2rank runner: ML binding pocket prediction.
# First run loads the Java ML model (~6 min); subsequent runs are fast.
set -euo pipefail
source "$(dirname "$0")/../../../scripts/_common.sh"

PDB="${1:?usage: oih-p2rank.sh <pdb_path> <job_name>}"
JOB="${2:-p2rank}"
PDB="${PDB//\\//}"
if [[ ! "$PDB" == /* && ! "$PDB" =~ ^[A-Za-z]:/ ]]; then
  PDB="$OIH_DATA/inputs/$PDB"
fi
[ -f "$PDB" ] || { oih_fail "input not found: $PDB"; exit 1; }

OUT_HOST="$OIH_DATA/outputs/${JOB}_p2rank"
mkdir -p "$OUT_HOST"
cp -f "$PDB" "$OUT_HOST/"
STEM="$(basename "$PDB")"; STEM="${STEM%.*}"

C_OUT="$(oih_container_path "$OUT_HOST")"

oih_exec oih-p2rank /app/p2rank/prank predict -f "$C_OUT/$STEM.pdb" -o "$C_OUT"

CSV="$OUT_HOST/${STEM}.pdb_predictions.csv"
if [ -f "$CSV" ]; then
  echo "OIH_OUTPUT_DIR: $OUT_HOST"
  echo "OIH_TOP_POCKETS:"
  head -n 4 "$CSV"
  oih_ok
else
  oih_fail "p2rank produced no predictions csv"
  exit 1
fi
