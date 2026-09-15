#!/usr/bin/env bash
# discotope3 runner: B-cell epitope prediction.
set -euo pipefail
source "$(dirname "$0")/../../../scripts/_common.sh"

# args: pdb_path [job_name] [threshold] [multichain]
PDB="${1:?usage: discotope3.sh <pdb_path> [job_name] [threshold] [multichain]}"
JOB="${2:-}"
THRESHOLD="${3:-0.5}"
MULTICHAIN="${4:-false}"

PDB="${PDB//\\//}"
if [[ "$PDB" =~ ^/([A-Za-z])/(.*)$ ]]; then
  PDB="${BASH_REMATCH[1]^}:/${BASH_REMATCH[2]}"   # /e/oih/... -> E:/oih/...
fi
if [[ ! "$PDB" =~ ^[A-Za-z]:/ ]]; then
  PDB="$OIH_DATA/inputs/$PDB"
fi
[ -f "$PDB" ] || { oih_fail "input not found: $PDB"; exit 1; }

STEM="$(basename "$PDB")"; STEM="${STEM%.*}"
JOB="${JOB:-$STEM}"
OUT_HOST="$OIH_DATA/outputs/${JOB}_discotope3"
mkdir -p "$OUT_HOST"

C_OUT="$(oih_container_path "$OUT_HOST")"
C_PDB="$(oih_container_path "$PDB")"

oih_ensure_container oih-discotope3 || { oih_fail "container oih-discotope3 unavailable"; exit 1; }

EXTRA=()
if [ "$MULTICHAIN" = "true" ]; then
  EXTRA+=(--multichain_mode)
fi

# main.py must run with /app/discotope3/discotope3 as working directory.
docker exec -w /app/discotope3/discotope3 oih-discotope3 python3 -u main.py \
  --pdb_or_zip_file "$C_PDB" \
  --out_dir "$C_OUT" \
  --models_dir /app/discotope3/models \
  --struc_type solved \
  --calibrated_score_epi_threshold "$THRESHOLD" \
  "${EXTRA[@]}"

# summarize produced files; main.py logs tracebacks but may still exit 0,
# so treat a traceback in log.txt or a missing per-residue CSV as failure.
# Output layout: <out>/<input_stem>/<chain>_discotope3.csv (one CSV per chain).
if grep -q "Traceback (most recent call last)" "$OUT_HOST"/log.txt 2>/dev/null; then
  echo "OIH_OUTPUT_DIR: $OUT_HOST"
  oih_fail "discotope3 errored (see log.txt)"
  exit 1
fi

CSV=$(find "$OUT_HOST" -name "*_discotope3.csv" 2>/dev/null | head -1 || true)
echo "OIH_OUTPUT_DIR: $OUT_HOST"
echo "OIH_OUTPUT_FILES:"
find "$OUT_HOST" -type f | sort || true
if [ -z "$CSV" ]; then
  oih_fail "discotope3 produced no per-residue CSV"
  exit 1
fi
# count residues flagged as epitope (epitope column == True) across all chain CSVs
N=$(find "$OUT_HOST" -name "*_discotope3.csv" -exec cat {} + 2>/dev/null | awk -F, 'NR>1 && $7=="True"' | wc -l)
echo "OIH_EPI_CSV: $CSV"
echo "OIH_EPI_RESIDUES: $N"
oih_ok
