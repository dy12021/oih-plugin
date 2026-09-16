---
name: oih-alphafold3
description: "Predict protein/RNA/DNA/ligand complex structures with AlphaFold 3 (container oih-alphafold3, models + databases on E:) Trigger: When the user asks for AlphaFold3 / AF3 structure prediction, folding a protein sequence, or validating a designed binder against its target"
---

> Note: `${PLUGIN_DIR}` is the absolute install path of this plugin
> (`C:/Users/dy120/.minimax/plugins/oih-bio-tools` for this installation). Resolve it from the plugin
> context and substitute before invoking the bash command below.

# AlphaFold 3 — structure prediction

Container `oih-alphafold3` (GPU). Weights: `$OIH_HOME/models/alphafold3/af3.bin`;
genetic DBs: `$OIH_HOME/models/af3_db/`. All mounted read-only by the compose file.

## Command (single-chain protein, one seed)

```bash
bash "${PLUGIN_DIR}/skills/oih-alphafold3/scripts/af3.sh" "$job_name" "$sequence"
```

- `$sequence`: amino-acid sequence (single-letter, no spaces), or a FASTA/PDB path is
  NOT supported here — paste the raw sequence.
- `$job_name`: short lowercase job id, e.g. `her2_design_1`.

Runtime: MSA search (jackhmmer) + inference typically 5–40 min on 2×RTX 3080 for
<600 aa; the script streams progress.

## Reading the result

Output: `$OIH_HOME/data/outputs/<job>_af3/` containing `<job>_model.cif`,
`<job>_summary_confidences.json`, `<job>_confidences.json`.

Report: mean pLDDT / iPTM from `*_summary_confidences.json`, and where the CIF is.
For binder–target complexes, next step: interface scoring (PeSTo / ipSAE).

## Notes

- Multi-chain / ligand complexes: edit the generated JSON at
  `$OIH_HOME/data/inputs/<job>_af3.json` (add `sequences` entries: protein/rna/dna/
  ligand with `ccdCodes` or SMILES), then re-run with the same command.
- Single 20 GB GPU per AF3 job; the runner auto-picks the freer GPU.
