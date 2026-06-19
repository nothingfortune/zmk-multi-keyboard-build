# Documentation Verification Checklist

Use this checklist whenever you make an architecture, CI, layer, board, or
translation-map change. Its job is narrow: keep hardcoded facts in the docs
matching the implementation so a contributor never has to cross-check docs
against the code to learn current behavior.

This is a manual checklist. The authoritative facts always live in the
implementation files listed in the "source of truth" column.

---

## Facts that drift and where they live

| Fact in docs | Source of truth | Docs to recheck |
|---|---|---|
| Board key counts (60 / 80 / 77) | `boards/<board>/positions.dtsi`, `scripts/validation.sh` (`check_positions`) | `readme.md`, `getting-started.md`, `docs/add-new-keyboard-layout.md` |
| Total layer count (21) and active per board (SliceMK 20) | `shared/layers.dtsi`, each `boards/<board>/<board>.keymap` include list | `readme.md` (Layers table), `getting-started.md` |
| Layer names / indices | `shared/layers.dtsi` | `readme.md` (Layers table) |
| Firmware artifact names | `.github/workflows/build.yml` (`upload-artifact` `name:`) | `readme.md` (Output files), `getting-started.md`, `docs/ci-cd-pipeline.md` |
| Firmware output paths / `.uf2` filenames | `.github/workflows/build.yml` (`path:`), `build/*.nix`, west build dir | `readme.md`, `getting-started.md`, `docs/ci-cd-pipeline.md` |
| Artifact retention (firmware 7d, synced-workspace 1d) | `.github/workflows/build.yml` (`retention-days:`) | `docs/ci-cd-pipeline.md`, `readme.md` |
| Translation-map filenames and extension (`.map`) | files in `boards/translations/`, `scripts/keymapsync.sh` (`load_map`) | `readme.md`, `getting-started.md`, `docs/add-new-keyboard-layout.md` |
| Which maps are consumed by sync | `scripts/keymapsync.sh` (`load_map` lines) | `readme.md` (translation tree comment) |
| Board / shield names | `.github/workflows/build.yml`, `build.yaml`, `config/` | `readme.md`, `docs/ci-cd-pipeline.md` |
| Validation section list / what is gated | `scripts/validation.sh` (`section` headers) | `docs/ci-cd-pipeline.md`, `readme.md` |

---

## Quick verification commands

```sh
# Layer count (expect 21). NOTE: shared/layers.dtsi also defines LAYER_Lower as
# an alias to Base (index 0), so a raw `grep -c '#define LAYER_'` reports 22.
# Count distinct layer indices instead:
grep -oE '#define LAYER_[A-Za-z_]+[[:space:]]+[0-9]+' shared/layers.dtsi \
  | awk '{print $3}' | sort -nu | wc -l

# Artifact names + retention as CI actually declares them
grep -nE 'name:|retention-days:|path:' .github/workflows/build.yml

# Maps actually consumed by the sync script
grep -n 'load_map' scripts/keymapsync.sh

# Translation-map files on disk and their entry counts
for f in boards/translations/*.map; do printf '%s: ' "$f"; grep -cvE '^\s*(#|$)' "$f"; done
```

---

## On every documentation-affecting change

- [ ] Re-derive any count or name from its source-of-truth file, not from memory.
- [ ] Update every doc listed in the row above for the fact you changed.
- [ ] Check that internal doc links still resolve (especially after moving files
      into or out of `docs/completedplans/`).
- [ ] If you added or removed a board or layer, follow the full checklist in
      `docs/add-new-keyboard-layout.md` and `readme.md` → "Adding or removing a layer".
- [ ] Run `bash scripts/validation.sh` and confirm it passes.
