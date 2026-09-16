---
name: oih-overview
description: "Overview of the OIH Bio Tools plugin - 17 containerized/host computational-biology tools, paths, conventions, and prerequisites. Trigger: When the user asks what bio tools are available or how the plugin is organized"
---

> Note: `${PLUGIN_DIR}` is the absolute install path of this plugin
> (`C:/Users/dy120/.minimax/plugins/oih-bio-tools` for this installation). Resolve it from the plugin
> context and substitute before invoking the bash command below.

# OIH Bio Tools — overview

16 skills wrapping the OIH platform's tool containers. Each heavy tool runs in a
Docker container (`oih-<tool>`) built and pre-verified in this deployment.

## Tool map

| Skill | Tool | Purpose |
|-------|------|---------|
| oih-alphafold3 | AlphaFold 3 | Structure prediction (protein/RNA/DNA/ligand) |
| oih-rfdiffusion | RFdiffusion | De novo backbone/binder design |
| oih-proteinmpnn | ProteinMPNN | Sequence design on a backbone |
| oih-pesto | PeSTo | PPI interface / hotspot prediction |
| oih-bindcraft | BindCraft | End-to-end binder design (PyRosetta-free mode) |
| oih-fpocket | fpocket | Binding pocket detection |
| oih-p2rank | P2Rank | ML pocket prediction |
| oih-gnina | GNINA | CNN docking |
| oih-vina-gpu | Vina-GPU | Fast GPU docking |
| oih-autodock-gpu | AutoDock-GPU | AutoDock4 GPU docking |
| oih-diffdock | DiffDock | Diffusion docking (blind) |
| oih-gromacs | GROMACS | MD simulation (protein-only v1) |
| oih-esm | ESM-2 | Embeddings / pseudo-perplexity |
| oih-chemprop | Chemprop | ADMET prediction (ESOL reference model) |
| oih-discotope3 | DiscoTope3 | B-cell epitope prediction |
| oih-igfold | IgFold | Antibody/nanobody folding |
| oih-freesasa | FreeSASA | SASA + ADC conjugation sites (host-side) |

## Conventions

- Data root: `$OIH_HOME` (default `E:\oih`); inputs → `data/inputs`, outputs →
  `data/outputs/<job>_<tool>/`.
- Model weights live in `$OIH_HOME/models/` and are mounted into containers —
  they are NOT part of this plugin.
- All scripts resolve containers via `oih_exec`/`oih_ensure_container`; if a
  container is down, the compose stack at
  `$OIH_HOME/oih-platform/docker-compose.windows.yml` starts it.
- Verify availability first: run the tool's smoke command (its SKILL.md states it)
  before long runs.
