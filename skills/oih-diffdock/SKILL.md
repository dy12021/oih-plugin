---
name: oih-diffdock
description: Diffusion-model molecular docking with DiffDock (Docker container oih-diffdock) — blind docking from receptor PDB + SMILES with confidence scores Trigger: When the user asks to dock a ligand by SMILES into a receptor without specifying a binding box, or wants equivariant diffusion docking poses with confidence scores
---

> Note: `${PLUGIN_DIR}` is the absolute install path of this plugin
> (`C:/Users/dy120/.minimax/plugins/oih-bio-tools` for this installation). Resolve it from the plugin
> context and substitute before invoking the bash command below.

# diffdock — diffusion model docking

Runs DiffDock `inference.py` in the `oih-diffdock` container. The receptor PDB
comes from `$OIH_HOME/data/inputs`; output lands in
`$OIH_HOME/data/outputs/<job_name>_diffdock/`. The script writes the required
`complex_name,protein_path,ligand_description,protein_sequence` CSV for you.

## Command

```bash
bash "${PLUGIN_DIR}/skills/oih-diffdock/scripts/oih-diffdock.sh" "$receptor_pdb" "$smiles" "$job_name"
```

- `$receptor_pdb`: absolute host path or filename under inputs/ (PDB).
- `$smiles`: ligand SMILES (quote it).

The script prints `OIH_STATUS: OK` plus pose count and best confidence.

## Reading the result

Output directory: `$OIH_HOME/data/outputs/<job_name>_diffdock/<job_name>/`
- `rank1_confidence<score>.sdf` ... `rank5_confidence<score>.sdf` — top 5 poses
  with the confidence value embedded in the filename (higher = better, ~> -1.5
  is typically a trustworthy pose)

Report to the user: number of poses generated and the confidence of the best
pose; note that DiffDock confidence is not a binding affinity — compare with
gnina (oih-gnina) CNNscore on the same pair when possible.

## Notes

- Runtime is a few minutes on GPU per ligand.
- First-ever run precomputes SO(2)/SO(3) series caches (a few minutes); these
  are persisted in the container's `/root/.cache`.
- Models live in the mounted workdir (`/app/DiffDock/workdir`), ESM embeddings
  are cached; no network is needed at inference time.
