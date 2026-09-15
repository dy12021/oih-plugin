#!/usr/bin/env bash
# freesasa runner: per-residue SASA + ADC conjugation site candidates.
# Runs on the HOST python (no docker): E:\oih\venvs\oih\python.exe
set -euo pipefail
source "$(dirname "$0")/../../../scripts/_common.sh"

PDB="${1:?usage: oih-freesasa.sh <pdb_path> <job_name>}"
JOB="${2:-freesasa}"
PDB="${PDB//\\//}"
[[ "$PDB" == /* || "$PDB" =~ ^[A-Za-z]:/ ]] || PDB="$OIH_DATA/inputs/$PDB"
[ -f "$PDB" ] || { oih_fail "input not found: $PDB"; exit 1; }

OUT_HOST="$OIH_DATA/outputs/${JOB}_freesasa"
mkdir -p "$OUT_HOST"

"$OIH_HOME/venvs/oih/python.exe" - "$PDB" "$OUT_HOST" <<'PY'
import sys, json
import freesasa

pdb, out_dir = sys.argv[1], sys.argv[2]
structure = freesasa.Structure(pdb)
result = freesasa.calc(structure)

per_res = []
for chain, residues in result.residueAreas().items():
    for res_key, area in residues.items():
        per_res.append({
            "chain": chain,
            "residue": area.residueType if hasattr(area, "residueType") else res_key[:3],
            "resnum": area.residueNumber if hasattr(area, "residueNumber") else res_key[3:],
            "sasa": round(area.total, 2),
        })

per_res.sort(key=lambda r: (r["chain"], int(str(r["resnum"]))))
with open(f"{out_dir}/sasa_per_residue.json", "w") as fh:
    json.dump(per_res, fh, indent=2)

TARGETS = {"LYS", "CYS", "THR", "SER"}
cands = [r for r in per_res if str(r["residue"]).upper() in TARGETS and r["sasa"] > 80.0]
cands.sort(key=lambda r: -r["sasa"])
with open(f"{out_dir}/adc_candidates.json", "w") as fh:
    json.dump(cands, fh, indent=2)

print("OIH_RESIDUES: %d" % len(per_res))
print("OIH_CANDIDATES: %d" % len(cands))
for r in cands[:5]:
    print("OIH_COUPLING_SITE: %s%s chain=%s sasa=%.2f" % (r["residue"], r["resnum"], r["chain"], r["sasa"]))
PY

if [ -s "$OUT_HOST/adc_candidates.json" ]; then
  echo "OIH_OUTPUT_DIR: $OUT_HOST"
  echo "OIH_OUTPUT_JSON: $OUT_HOST/sasa_per_residue.json"
  echo "OIH_OUTPUT_CANDIDATES: $OUT_HOST/adc_candidates.json"
  oih_ok
else
  oih_fail "freesasa produced no output"
  exit 1
fi
