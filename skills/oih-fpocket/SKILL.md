---
name: oih-fpocket
description: Detect and rank protein binding pockets with fpocket (Docker container oih-fpocket) Trigger: When the user asks to detect binding pockets, find binding sites, identify cavities, or assess druggability of a protein structure (PDB/mmCIF)
---

> Note: `${PLUGIN_DIR}` is the absolute install path of this plugin
> (`C:/Users/dy120/.minimax/plugins/oih-bio-tools` for this installation). Resolve it from the plugin
> context and substitute before invoking the bash command below.

# fpocket — binding pocket detection

Runs fpocket in the `oih-fpocket` container. Input structure comes from
`$OIH_HOME/data/inputs`, output lands in `$OIH_HOME/data/outputs/fpocket_<stem>/`.

## Command

```bash
bash "${PLUGIN_DIR}/skills/oih-fpocket/scripts/fpocket.sh" "$pdb_path"
```

`$pdb_path` may be an absolute host path or just a filename under inputs/.
The script prints `OIH_STATUS: OK` on success and the number of detected pockets.

## Reading the result

Output directory: `$OIH_HOME/data/outputs/fpocket_<stem>/` (container path `/data/oih/outputs/...`).
- `<stem>_info.txt` — per-pocket stats: "Score", "Druggability Score", "Volume",
  "Number of Alpha Spheres", polar/apolar SASA
- `pockets/pocket<N>_atm.pdb` — pocket atom coordinates (N = pocket rank)

Report to the user: top pocket druggability + volume, and how many pockets scored
>= 0.5. Suggest P2Rank (oih-p2rank skill) as ML cross-check when relevant.
