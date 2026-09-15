#!/usr/bin/env bash
# diffdock runner: diffusion-model docking from receptor PDB + ligand SMILES.
set -euo pipefail
source "$(dirname "$0")/../../../scripts/_common.sh"

REC="${1:?usage: oih-diffdock.sh <receptor_pdb> <smiles> <job_name>}"
SMILES="${2:?missing smiles}"
JOB="${3:?missing job_name}"
REC="${REC//\\//}"
[[ "$REC" == /* || "$REC" =~ ^[A-Za-z]:/ ]] || REC="$OIH_DATA/inputs/$REC"
[ -f "$REC" ] || { oih_fail "receptor not found: $REC"; exit 1; }

OUT_HOST="$OIH_DATA/outputs/${JOB}_diffdock"
mkdir -p "$OUT_HOST"
CSV_HOST="$OIH_DATA/inputs/${JOB}_diffdock.csv"
C_REC="$(oih_container_path "$REC")"

# DiffDock input CSV: complex_name,protein_path,ligand_description,protein_sequence
printf 'complex_name,protein_path,ligand_description,protein_sequence\n%s,%s,%s,\n' \
  "$JOB" "$C_REC" "$SMILES" > "$CSV_HOST"
C_CSV="$(oih_container_path "$CSV_HOST")"
C_OUT="$(oih_container_path "$OUT_HOST")"

# First run precomputes SO(2)/SO(3) caches (persisted in /root/.cache); a normal
# run takes a few minutes on GPU.
oih_exec oih-diffdock python3 /app/DiffDock/inference.py \
  --protein_ligand_csv "$C_CSV" --out_dir "$C_OUT"

N_SDF=$(find "$OUT_HOST" -name '*.sdf' 2>/dev/null | wc -l | tr -d ' ')
if [ "$N_SDF" -gt 0 ]; then
  BEST=$(find "$OUT_HOST" -name 'rank*_confidence*.sdf' -printf '%f\n' 2>/dev/null \
         | sed -E 's/rank[0-9]+_confidence(-?[0-9.]+)\.sdf/\1/' \
         | sort -g | tail -1)
  echo "OIH_OUTPUT_DIR: $OUT_HOST"
  echo "OIH_POSES: $N_SDF"
  echo "OIH_BEST_CONFIDENCE: $BEST"
  oih_ok
else
  oih_fail "diffdock produced no sdf poses"
  exit 1
fi
