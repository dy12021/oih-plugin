#!/usr/bin/env bash
# AlphaFold 3 runner: single-chain protein, one seed.
set -euo pipefail
source "$(dirname "$0")/../../../scripts/_common.sh"

JOB="${1:?usage: af3.sh <job_name> <protein_sequence>}"
SEQ="${2:?missing protein sequence}"
SEQ="$(echo "$SEQ" | tr -d '[:space:]')"

IN_HOST="$OIH_DATA/inputs/${JOB}_af3"
OUT_HOST="$OIH_DATA/outputs/${JOB}_af3"
mkdir -p "$IN_HOST" "$OUT_HOST"

cat > "$IN_HOST/${JOB}_af3.json" <<JSON
{
  "name": "$JOB",
  "sequences": [{"protein": {"id": ["A"], "sequence": "$SEQ"}}],
  "modelSeeds": [1],
  "dialect": "alphafold3",
  "version": 2
}
JSON

C_IN="$(oih_container_path "$IN_HOST")"
C_OUT="$(oih_container_path "$OUT_HOST")"

echo "[oih] AF3 job $JOB (${#SEQ} aa) — input: $IN_HOST/${JOB}_af3.json"
oih_exec oih-alphafold3 python /app/alphafold/run_alphafold.py \
  --json_path="$C_IN/${JOB}_af3.json" \
  --output_dir="$C_OUT" \
  --model_dir=/data/alphafold3_models \
  --db_dir=/data/alphafold3_db \
  --flash_attention_implementation=triton \
  --jackhmmer_n_cpu=8 --nhmmer_n_cpu=8

CIF=$(find "$OUT_HOST" -name "*_model.cif" | head -1)
if [ -n "$CIF" ]; then
  echo "OIH_CIF: $CIF"
  CONF=$(find "$OUT_HOST" -name "*summary_confidences*.json" | head -1)
  [ -n "$CONF" ] && echo "OIH_CONFIDENCES: $CONF"
  oih_ok
else
  oih_fail "no model cif produced"
  exit 1
fi
