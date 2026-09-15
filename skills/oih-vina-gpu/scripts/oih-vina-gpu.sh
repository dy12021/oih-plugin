#!/usr/bin/env bash
# vina-gpu runner: fast GPU docking of pdbqt receptor + ligand.
# NOTE: no prepare_receptor/prepare_ligand in the container — pdbqt inputs only.
set -euo pipefail
source "$(dirname "$0")/../../../scripts/_common.sh"

REC="${1:?usage: oih-vina-gpu.sh <receptor.pdbqt> <ligand.pdbqt> <job_name> <cx> <cy> <cz>}"
LIG="${2:?missing ligand}"
JOB="${3:?missing job_name}"
CX="${4:?missing center_x}"; CY="${5:?missing center_y}"; CZ="${6:?missing center_z}"
REC="${REC//\\//}"; LIG="${LIG//\\//}"
[[ "$REC" == /* || "$REC" =~ ^[A-Za-z]:/ ]] || REC="$OIH_DATA/inputs/$REC"
[[ "$LIG" == /* || "$LIG" =~ ^[A-Za-z]:/ ]] || LIG="$OIH_DATA/inputs/$LIG"
[ -f "$REC" ] || { oih_fail "receptor not found: $REC"; exit 1; }
[ -f "$LIG" ] || { oih_fail "ligand not found: $LIG"; exit 1; }

OUT_HOST="$OIH_DATA/outputs/${JOB}_vina_gpu"
mkdir -p "$OUT_HOST"

# Placeholder / limitation handling for non-pdbqt inputs.
for pair in "receptor:$REC" "ligand:$LIG"; do
  KIND="${pair%%:*}"; FILE="${pair#*:}"
  if [[ "${FILE##*.}" != "pdbqt" ]]; then
    cp -f "$FILE" "$OUT_HOST/"
    echo "[oih] WARNING: $KIND is not .pdbqt ($FILE). No prepare_receptor in the"
    echo "[oih] container — convert with ADFR/ADT (e.g. 'prepare_receptor -r x.pdb')"
    echo "[oih] and pass the .pdbqt. The original file was copied to the output dir"
    echo "[oih] as a placeholder only."
    oih_fail "$KIND must be pdbqt (conversion tools not in image)"
    exit 1
  fi
done

C_REC="$(oih_container_path "$REC")"
C_LIG="$(oih_container_path "$LIG")"
C_OUT="$(oih_container_path "$OUT_HOST")"

oih_exec oih-vina-gpu vina_gpu --receptor "$C_REC" --ligand "$C_LIG" \
  --out "$C_OUT/docked.pdbqt" \
  --center_x "$CX" --center_y "$CY" --center_z "$CZ" \
  --size_x 25 --size_y 25 --size_z 25 \
  --num_poses 9 --exhaustiveness 8

OUT_PDBQT="$OUT_HOST/docked.pdbqt"
if [ -s "$OUT_PDBQT" ]; then
  POSES=$(grep -c '^MODEL' "$OUT_PDBQT" || true)
  BEST=$(grep -m1 'VINA RESULT' "$OUT_PDBQT" || true)
  echo "OIH_OUTPUT_DIR: $OUT_HOST"
  echo "OIH_OUTPUT_PDBQT: $OUT_HOST/docked.pdbqt"
  echo "OIH_POSES: $POSES"
  echo "OIH_BEST: $BEST"
  oih_ok
else
  oih_fail "vina_gpu produced no docked.pdbqt"
  exit 1
fi
