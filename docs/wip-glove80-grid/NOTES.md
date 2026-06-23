# DONE — Glove80 layer "grid" reformat

**Status:** Complete and verified. The glove80 `boards/glove80/layers/*.dtsi` files are
a uniform, column-aligned grid with an aligned label-comment row directly above each
binding row — labels start at the exact column of their binding.

## Final solution (two coordinated parts)

### 1. Decoupled the sync engine (root-cause fix)
`scripts/keymapsync.sh` `write_bindings` previously padded every synced glove80 cell to
`max(current_cell, go60_slot_width)`. go60's slot widths are large and irregular (normal
cells 48–57, the last cell before the hand-gap 66–88, the thumb-gap cell 150–202), so the
sync forced those widths onto glove80 — bloating lines to ~900 chars and making a uniform
grid impossible (the original "blocker" in this file's history).

Fix: `write_bindings` now preserves **each board's own column width**, growing a cell only
when the new binding text itself doesn't fit. It never inherits go60's gap-inflated slot
widths. This decouples glove80's (and slicemk's) column layout from go60 and is what makes
a clean uniform grid survive a sync. Verified: sync stays a byte-identical no-op on all
three boards, and `tests/keymapsync_test.sh` passes (idempotent).

### 2. Regenerated all 21 glove80 layers as a uniform grid
`scripts/glove80_grid.py` lays each layer out as an 18-column grid
(6 LH | 6 center | 6 RH), W=48, label row above bindings. It normalizes the two old input
styles (base's `/* Row */` + label-above, and the other 20's box-with-separator-below) into
one clean format. It only re-lays-out the existing bindings and **refuses to run if the
ordered `&`-token stream would change** — so it can never alter the keymap, only formatting.

Longest binding anywhere is 43 chars, so W=48 has headroom; max line dropped ~909 → ~831.

## Maintaining the grid
- Edit shared content in go60, run `bash scripts/keymapsync.sh`, then
  `python3 scripts/glove80_grid.py` to re-normalize glove80 alignment. Both are idempotent.
- `python3 scripts/glove80_grid.py --check` exits non-zero if any layer is not normalized
  (useful as a drift guard / pre-commit / CI check).
- glove80 layer files are row-interleaved to match the sync/translation map and hardware
  matrix — never re-block them by hand. See memory: glove80-binding-order-scramble.

## Verification checklist (re-run if the grid or sync logic changes)
- `python3 scripts/glove80_grid.py --check` → exit 0
- ordered `&`-token stream of each layer matches `git show HEAD:<file>`
- `bash scripts/validation.sh` → 319 PASS / 0 FAIL / 0 WARN
- snapshot `boards/`, `bash scripts/keymapsync.sh`, diff → byte-identical (no-op)
- `bash tests/keymapsync_test.sh` → 0 failed
