# Claude Instructions — zmk-multi-keyboard-build

## What this repo is

ZMK firmware for three keyboards sharing one logical keymap library:

| Board | Keys | Upstream / build path |
|---|---:|---|
| go60 | 60 | `moergo-sc/zmk` via Nix |
| glove80 | 80 | `moergo-sc/zmk` via Nix |
| slicemk | 77 | `slicemk/zmk` via west |

`boards/go60/` is the source of truth for shared layer content. `boards/glove80/` and `boards/slicemk/` are derived from it with board-specific extras layered on top.

---

## Primary workflow

1. Edit the shared change in `boards/go60/layers/<name>.dtsi`
2. Run `bash scripts/keymapsync.sh`
3. If needed, adjust board-only keys in `boards/glove80/layers/` or `boards/slicemk/layers/`
4. Run `bash scripts/validation.sh`
5. Commit the synchronized set of board files together

Do not hand-edit matching shared positions on Glove80 or SliceMK first. That creates drift the sync script will overwrite.

---

## Source-of-truth rules

- Shared layer edits start in `boards/go60/layers/`
- Shared behaviors live in `shared/`
- Board-only physical keys may be edited directly in the target board layer file after sync
- When a change affects all boards, expect changes in all three board trees
- SliceMK intentionally keeps a `layers/magic.dtsi` file on disk but does not include it in `boards/slicemk/slicemk.keymap`

---

## Directory map

### Shared logic

| Task | File |
|---|---|
| Layer index constants | `shared/layers.dtsi` |
| Timing constants | `shared/global_timings.dtsi` |
| Behaviors | `shared/behaviors.dtsi` |
| Macros | `shared/macros.dtsi` |
| Mod-morphs | `shared/modMorphs.dtsi` |
| Autoshift config | `shared/autoshift.dtsi` |
| Bluetooth helpers | `shared/bluetooth.dtsi` |
| Magic / RGB helpers | `shared/magic.dtsi` |
| HRM macros | `shared/homeRowMods/hrm_macros.dtsi` |
| HRM behaviors | `shared/homeRowMods/hrm_behaviors.dtsi` |
| Shared combos | `shared/combos/combos_common.dtsi` |
| F-key combos | `shared/combos/combos_fkeys.dtsi` |

### Per-board files

Each board directory contains:

- `positions.dtsi` for logical-to-physical position defines
- `position_groups.dtsi` for left/right/thumb groups and HRM trigger groups
- `board_meta.dtsi` for board-specific metadata and helper behaviors
- `<board>.keymap` for include ordering and top-level composition
- `<board>.conf` for board-specific config
- `layers/*.dtsi` for the actual key bindings

### Translation maps

Translation maps are in `boards/translations/`, not at the repo root.

- `boards/translations/go60_to_glove80.map`
- `boards/translations/go60_to_slicemk.map`

Each map is `src_idx dst_idx`, one pair per line, with `#` comments allowed. The sync script uses these maps to copy Go60 bindings into the matching physical positions on each target board.

---

## Layer structure

There are 21 logical layers defined in `shared/layers.dtsi`, indexed contiguously from 0 through 20:

- `Base`
- `Typing`
- `Autoshift`
- `LeftPinky`
- `LeftRingy`
- `LeftMiddy`
- `LeftIndex`
- `RightPinky`
- `RightRingy`
- `RightMiddy`
- `RightIndex`
- `Cursor`
- `Keypad`
- `Symbol`
- `Mouse`
- `MouseSlow`
- `MouseFast`
- `MouseWarp`
- `Magic`
- `Symbol_lh`
- `Symbol_rh`

Every board has a file for each layer under `boards/<board>/layers/`. SliceMK keeps all 21 files on disk, but its keymap intentionally includes only 20 of them because `magic.dtsi` is excluded.

Each layer file should contain one layer node with a `bindings = < ... >;` block. Binding order must match that board's `positions.dtsi` numbering.

---

## Key position naming

Shared logical positions are named consistently across boards:

- `POS_LH_CxRy` and `POS_RH_CxRy` for matrix keys
- `POS_LH_T1/T2/T3` and `POS_RH_T1/T2/T3` for shared thumb keys

Board-specific extras are not fully shared by translation maps:

- Glove80 adds extra matrix positions, including function-row positions
- SliceMK adds extra inner columns and additional thumb positions

When changing shared bindings, think in logical positions first, then let the translation map place them on each target board.

---

## keymapsync.sh behavior

Run sync with:

```sh
bash scripts/keymapsync.sh
```

Important facts about the script:

- Requires bash 4+
- Re-execs into Homebrew bash on macOS if the system shell is too old
- Reads Go60 layer files from `boards/go60/layers/`
- Applies `boards/translations/go60_to_glove80.map` and `boards/translations/go60_to_slicemk.map`
- Preserves comments and most spacing in target files instead of regenerating them wholesale
- Preserves target-only positions that are not present in the translation map
- Rewrites shared mapped positions on Glove80 and SliceMK
- Converts mapped `&magic...` bindings to `&none` when syncing into SliceMK

Do not add `set -x` to this script.

---

## Keymap composition constraints

The board keymap files have a few ordering and placement rules that validation enforces:

- `shared/layers.dtsi` must be included before `board_meta.dtsi`
- `shared/global_timings.dtsi` must be included before `board_meta.dtsi`
- Shared behavior and macro includes belong inside a `/ { behaviors { ... } }` block, not at top level
- Combo definition includes belong inside a `/ { combos { compatible = "zmk,combos"; ... } }` block
- `shared/combos/*.dtsi` files must be raw combo nodes only; they must not include their own wrapper block

Use `boards/go60/go60.keymap` as the canonical pattern when adjusting keymap structure.

---

## SliceMK constraints

SliceMK uses a different ZMK fork and has hard constraints:

- Do not include `../../shared/magic.dtsi` in `boards/slicemk/slicemk.keymap`
- Do not include `layers/magic.dtsi` in `boards/slicemk/slicemk.keymap`
- Do not include `zmk/rgb.h` in SliceMK keymap files
- Do not reference `pointing.h` in SliceMK-only files
- SliceMK builds via west using `config/west.yml`, not Nix

If a change is RGB- or pointing-related, assume SliceMK may need a different implementation or explicit exclusion.

---

## Validation

Run:

```sh
bash scripts/validation.sh
```

Validation checks repo structure, required files, layer presence, layer include counts, binding counts, include ordering, shared include presence, SliceMK exclusions, duplicate DTS labels, contiguous layer indices, build config wiring, workflow wiring, and a few informational stub checks.

Treat validation as required after structural edits, layer edits, include changes, translation-map changes, or shared DTS changes.

---

## Adding or removing a layer

When the layer set changes, update all of these together:

1. `shared/layers.dtsi`
2. `boards/go60/layers/`
3. `boards/glove80/layers/`
4. `boards/slicemk/layers/`
5. The `#include "layers/..."` list in each board keymap
6. Expected layer counts and related checks in `scripts/validation.sh`

Keep the layer indices contiguous and 0-based.

---

## CI and builds

CI is defined in `.github/workflows/build.yml`.

The workflow is:

1. Sync Go60 into the other boards
2. Upload the synced workspace as an artifact
3. Run validation against that synced tree
4. Build Go60 and Glove80 through Nix against `moergo-sc/zmk`
5. Build SliceMK through west against the slicemk fork

Current artifact outputs:

- `go60-firmware` -> `go60.uf2`
- `glove80-firmware` -> `glove80.uf2`
- `slicemk-firmware` -> `zmk.uf2`

Artifacts are retained for 90 days.

---

## Practical editing guidance

- For shared layout work, edit one Go60 layer file, sync, then review the two generated target files
- For board-specific physical keys, edit the target board layer after sync
- For behavior changes, prefer `shared/` over duplicating logic into board files
- For structural keymap fixes, update all three board keymaps consistently unless the change is SliceMK-excluded by design
- When unsure whether a file is canonical, prefer the Go60 version unless the file is explicitly board-specific

---

## Safe defaults for future edits

- Prefer minimal diffs that preserve alignment and comments in layer files
- Do not remove SliceMK exclusions around magic or RGB support
- Do not move behavior includes out of the `behaviors {}` block
- Do not add combo wrapper blocks inside shared combo include files
- Do not edit generated target layer positions by hand if the same position is mapped from Go60
