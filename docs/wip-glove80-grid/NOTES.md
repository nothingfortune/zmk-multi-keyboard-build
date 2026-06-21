# WIP — Glove80 layer "grid" reformat

**Goal:** make the glove80 `boards/glove80/layers/*.dtsi` files readable like the MoErgo
default (`docs/glove80defaultlayout.keymap:334-341`) — a clean column-aligned grid — but with
an **aligned label comment row** above each binding row so you can see what each key is.

## Agreed format (from the back-and-forth)
- **Uniform** column width (every column the same), **left-aligned** (label starts at the exact
  same column as its binding — alignment label↔binding is "absolutely critical").
- One **label comment row** per physical row, directly above the bindings. No `|----|` boxes.
- Width target the user gave: **longest mapping + 10%** (base layer = 43 → W=48).
- Bottom thumb cluster lives in the center columns (cols 6–11), positions 69–74
  (LH T1 T2 T3 | RH T3 T2 T1) — this was the approved "3-block split" content, just rendered
  inline in the grid's center columns now.

## Current state
- `boards/glove80/layers/base.dtsi` is the **uniform W=48 prototype** (validates 319/0/0,
  bindings provably identical to HEAD). It is the visible WIP.
- Generator prototype: `docs/wip-glove80-grid/gen_grid.py` (base layer only — needs generalizing
  to loop all 21 layers; labels come from the box-comment version still in `git HEAD`).
- **Not approved to spread** to the other 20 glove80 files yet.

## ⛔ Blocker: keymapsync.sh fights a narrow uniform grid
`scripts/keymapsync.sh` (write_bindings) re-pads every **mapped/shared** glove80 binding to
`max(current_slot_width, go60_slot_width)`. So the next `keymapsync.sh` widens any column that is
narrower than go60's slot for that position, breaking the uniform grid (verified: a sync mangles
rows 3–6 of the W=48 base.dtsi).

Measured go60 slot widths:
- center-gap slots (last-LH→first-RH): up to ~202 — **fine**, they map to glove80 positions that
  already have a wide center.
- **normal** (non-gap) slots: **up to 88**. → a uniform grid would need **W ≥ 88** to survive a
  sync, i.e. ~1600-char lines. Impractical.

## Decision needed (pick one) before spreading
- **A. Reformat go60 too** with the same grid generator so go60's slot widths are ≤ W; glove80
  then inherits clean widths and sync is a no-op. Touches the source of truth + all boards, but
  makes everything consistent. (Biggest, cleanest end-state.)
- **B. Make the generator a repo script run *after* keymapsync.sh** (workflow becomes: edit go60 →
  sync → regenerate glove80 grid). Keeps glove80 independent; adds one workflow step + a CI tweak.
- **C. Change keymapsync.sh to stop enforcing go60 slot widths** — replace binding *text* only,
  preserve each board's own spacing. Cleanest decoupling (also helps the slicemk reformat already
  done). Must verify it doesn't misalign when a synced binding's length changes vs the column.

## Verify steps to reuse when picking this back up
- bindings unchanged vs last-good: compare ordered `&`-token list of file vs `git show HEAD:<file>`.
- validation: `bash scripts/validation.sh` → expect 319 PASS / 0 FAIL.
- sync stability: snapshot file, `bash scripts/keymapsync.sh`, `diff` must be **byte-identical**.

## Uncommitted working-tree state at hand-off (nothing committed)
- `boards/slicemk/layers/*.dtsi` (21) — earlier separator-below-binding swap (validated, sync-safe).
- `boards/glove80/layers/*.dtsi` (20, non-base) — earlier separator-below-binding swap.
- `boards/glove80/layers/base.dtsi` — the uniform W=48 grid prototype (this WIP).
