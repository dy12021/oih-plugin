#!/usr/bin/env bash
# chemprop runner: ADMET property prediction from SMILES (default ESOL model).
set -euo pipefail
source "$(dirname "$0")/../../../scripts/_common.sh"

JOB="${1:?usage: oih-chemprop.sh <job_name> <smiles,csv> [model_path]}"
SMILES="${2:?missing smiles (comma-separated)}"
MODEL_IN="${3:-/data/oih/models/admet/models/esol/model_0/best.pt}"
# Accept container paths as-is; map host paths under $OIH_MODELS to /data/oih/models/.
M="${MODEL_IN//\\//}"
D="${OIH_MODELS//\\//}"
if [[ "$M" == "$D/"* ]]; then
  MODEL="/data/oih/models/${M#"$D"/}"
elif [[ "$M" == /* ]]; then
  MODEL="$M"
else
  oih_fail "model must be a container path or a path under $OIH_MODELS"
  exit 1
fi

OUT_HOST="$OIH_DATA/outputs/${JOB}_chemprop"
mkdir -p "$OUT_HOST"
CSV_HOST="$OIH_DATA/inputs/${JOB}_smiles.csv"
C_CSV="$(oih_container_path "$CSV_HOST")"
C_OUT="$(oih_container_path "$OUT_HOST")"

# chemprop v2 expects a csv with a 'smiles' column.
{ echo "smiles"; tr ',' '\n' <<< "$SMILES"; } > "$CSV_HOST"

oih_exec oih-chemprop python3 -m chemprop.cli.predict \
  --test-path "$C_CSV" \
  --model-path "$MODEL" \
  --preds-path "$C_OUT/preds.csv" \
  --accelerator cpu

if [ -s "$OUT_HOST/preds.csv" ]; then
  echo "OIH_OUTPUT_DIR: $OUT_HOST"
  echo "OIH_PREDS_CSV: $OUT_HOST/preds.csv"
  echo "OIH_PREDS:"
  cat "$OUT_HOST/preds.csv"
  oih_ok
else
  oih_fail "chemprop produced no preds.csv"
  exit 1
fi
