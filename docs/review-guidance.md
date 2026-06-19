# Review Guidance for High-Impact Changes

This repo derives Glove80 and SliceMK layers from Go60 via translation maps. A
small mistake in the sync engine, the maps, validation, or CI can silently break
every board. `.github/CODEOWNERS` marks those high-risk paths so they always get
a deliberate review. This file lists what to actually check.

For routine keymap edits, none of this applies — see
[getting-started.md](../getting-started.md).

---

## Always, for any high-risk change

- [ ] CI is green, including the **Sync keymaps** drift gate and the **Validate**
      job (which runs `validation.sh` and the keymapsync fixture tests).
- [ ] `bash scripts/check.sh` passes locally.
- [ ] If documented facts changed (counts, names, paths), the
      [documentation verification checklist](doc-verification-checklist.md) was followed.

---

## Changing `scripts/keymapsync.sh` (the sync engine)

- [ ] `tests/keymapsync_test.sh` still passes, and a new fixture case covers the
      changed behavior (don't change the parser without a fixture proving it).
- [ ] Re-running sync on the real repo is idempotent (no unexpected diff).
- [ ] Comment/whitespace preservation and target-board-only positions are unaffected.
- [ ] The SliceMK `&magic` → `&none` rewrite still holds.

## Changing a translation map (`boards/translations/*.map`)

- [ ] `validation.sh` section 25 passes (no duplicate/out-of-range indices, all
      entries agree with `positions.dtsi` logical names, full coverage of the 60
      shared positions, reverse map stays a consistent inverse).
- [ ] Each changed `src dst` pair maps the **same logical position** on both
      boards — verify against `boards/<board>/positions.dtsi`, not by eye.
- [ ] Board-only positions are **not** added to the map (the map is the ownership
      boundary; unmapped positions stay board-local).

## Changing `scripts/validation.sh`

- [ ] No check was weakened or removed without justification.
- [ ] New checks have both a passing case and a failing case (a check that can't
      fail is not a check).

## Changing CI (`.github/workflows/`) or build wiring (`build/`, `config/`, `build.yaml`)

- [ ] Build jobs still consume the **synced workspace**, not the raw checkout.
- [ ] The drift gate and validation still run before any firmware build.
- [ ] Artifact names/paths match what the docs claim.

---

## Adding a new board

Follow [docs/add-new-keyboard-layout.md](add-new-keyboard-layout.md). The review
must confirm all of:

- [ ] A `boards/translations/go60_to_<board>.map` with exactly 60 entries, each
      agreeing with the new board's `positions.dtsi` logical names.
- [ ] `keymapsync.sh` registers the new board as a sync target.
- [ ] `validation.sh` covers the new board (position count, binding counts, layer
      includes, exclusions) and section 25 validates its map.
- [ ] A build job that builds from the synced workspace, with a documented
      artifact name and path.
- [ ] Docs updated (readme, getting-started, doc-verification-checklist rows).

## Changing logical position mappings across boards

- [ ] The change starts from Go60 logical positions, then flows through the maps —
      not by hand-editing matching positions on a derived board.
- [ ] `validation.sh` section 25 still proves every shared logical position maps
      consistently across all supported boards.
- [ ] `bash scripts/check.sh` is clean and the three boards are committed together.
