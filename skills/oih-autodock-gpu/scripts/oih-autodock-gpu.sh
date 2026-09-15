#!/usr/bin/env bash
# autodock-gpu runner: AutoDock4 GPU docking against a precomputed maps.fld grid.
# NOTE: autogrid is NOT in the image — grids must be prepared externally.
set -euo pipefail
source "$(dirname "$0")/../../../scripts/_common.sh"

FLD="${1:?usage: oih-autodock-gpu.sh <maps.fld> <ligand.pdbqt> <job_name> [num_poses]}"
LIG="${2:?missing ligand_pdbqt}"
JOB="${3:?missing job_name}"
NUM_POSES="${4:-9}"
FLD="${FLD//\\//}"; LIG="${LIG//\\//}"
[[ "$FLD" == /* || "$FLD" =~ ^[A-Za-z]:/ ]] || FLD="$OIH_DATA/inputs/$FLD"
[[ "$LIG" == /* || "$LIG" =~ ^[A-Za-z]:/ ]] || LIG="$OIH_DATA/inputs/$LIG"
[ -f "$FLD" ] || { oih_fail "maps.fld not found: $FLD"; exit 1; }
[ -f "$LIG" ] || { oih_fail "ligand not found: $LIG"; exit 1; }
if ! compgen -G "${FLD%.fld}.*" >/dev/null; then
  oih_fail "no .maps.* siblings next to $FLD — autogrid output incomplete"
  exit 1
fi

NRUN=$(( NUM_POSES * 2 ))

OUT_HOST="$OIH_DATA/outputs/${JOB}_autodock_gpu"
mkdir -p "$OUT_HOST"

C_FLD="$(oih_container_path "$FLD")"
C_LIG="$(oih_container_path "$LIG")"
C_OUT="$(oih_container_path "$OUT_HOST")"

oih_exec oih-autodock-gpu autodock_gpu_128wi \
  --ffile "$C_FLD" --lfile "$C_LIG" \
  --nrun "$NRUN" --devnum 1 \
  --resnam "$C_OUT/result"

RESULT="$OUT_HOST/result.pdbqt"
if [ -s "$RESULT" ]; then
  POSES=$(grep -c '^MODEL' "$RESULT" || true)
  BEST=$(grep -m1 -i 'binding energy' "$RESULT" || true)
  echo "OIH_OUTPUT_DIR: $OUT_HOST"
  echo "OIH_OUTPUT_PDBQT: $OUT_HOST/result.pdbqt"
  echo "OIH_POSES: $POSES"
  [ -n "$BEST" ] && echo "OIH_BEST: $BEST"
  oih_ok
else
  oih_fail "autodock_gpu produced no result.pdbqt"
  exit 1
fi
