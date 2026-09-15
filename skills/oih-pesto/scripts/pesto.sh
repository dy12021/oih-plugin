#!/usr/bin/env bash
# pesto runner: protein-protein interface (PPI) residue prediction.
# Shares the oih-proteinmpnn container (pesto lives under /app/pesto).
set -euo pipefail
source "$(dirname "$0")/../../../scripts/_common.sh"

# args: pdb_path [threshold] [chain_id] [job_name]
PDB="${1:?usage: pesto.sh <pdb_path> [threshold] [chain_id] [job_name]}"
THRESHOLD="${2:-0.5}"
CHAIN_ID="${3:-}"
JOB="${4:-}"

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
OUT_HOST="$OIH_DATA/outputs/${JOB}_pesto"
mkdir -p "$OUT_HOST"

C_OUT="$(oih_container_path "$OUT_HOST")"
C_PDB="$(oih_container_path "$PDB")"
C_JSON="$C_OUT/result.json"

oih_ensure_container oih-proteinmpnn || { oih_fail "container oih-proteinmpnn unavailable"; exit 1; }

# Optional: restrict prediction to a single chain (pesto scores whole structures;
# gemmi extracts the chain to a container-side scratch file).
C_INPUT="$C_PDB"
if [ -n "$CHAIN_ID" ]; then
  oih_exec oih-proteinmpnn python3 -c "
import gemmi
st = gemmi.read_structure('$C_PDB')
m = st[0]
for c in list(m):
    if c.name != '$CHAIN_ID':
        m.remove_chain(c.name)
st.write_pdb('/tmp/pesto_in.pdb')
" || { oih_fail "failed to extract chain $CHAIN_ID with gemmi"; exit 1; }
  C_INPUT="/tmp/pesto_in.pdb"
fi

# predict_cli.py must run with /app/pesto as working directory.
docker exec -w /app/pesto oih-proteinmpnn python3 predict_cli.py \
  --input "$C_INPUT" \
  --output "$C_JSON" \
  --threshold "$THRESHOLD"

if [ -f "$OUT_HOST/result.json" ]; then
  echo "OIH_OUTPUT_DIR: $OUT_HOST"
  echo "OIH_RESULT_JSON_BEGIN"
  docker exec oih-proteinmpnn cat "$C_JSON"
  echo
  echo "OIH_RESULT_JSON_END"
  oih_ok
else
  oih_fail "pesto produced no output json"
  exit 1
fi
