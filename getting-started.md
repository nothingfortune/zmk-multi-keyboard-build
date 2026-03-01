# Getting Started

This guide is for people new to this repo. It covers the mental model, the edit workflow, and how to get firmware onto a keyboard.

---

## What this repo is

A shared ZMK firmware configuration for three split keyboards:

| Keyboard | Keys | ZMK fork |
|---|---|---|
| **Go60** | 60 | moergo-sc/zmk |
| **Glove80** | 80 | moergo-sc/zmk |
| **SliceMK ErgoDox Lite** | 77 | slicemk/zmk |

All three share one keymap library. **Go60 is the source of truth** — you edit layers there, then run a script that propagates the changes to the other two boards automatically.

You do not need all three keyboards. If you only have a Glove80, you still edit go60 first, then sync.

---

## Prerequisites

- **Git** (clone the repo)
- **bash 4+** for the sync script — macOS ships bash 3.2, install with `brew install bash`
- A text editor

To build firmware locally you also need:
- **Nix** for Go60 / Glove80 (or just push to `main` and let GitHub Actions build it)
- **west** for SliceMK (or push to `main`)

Most people just push to `main` and download artifacts from GitHub Actions. Local builds are optional.

---

## Clone the repo

```sh
git clone https://github.com/<your-username>/zmk-multi-keyboard-build
cd zmk-multi-keyboard-build
```

---

## The mental model

### One source, three boards

```
boards/go60/layers/base.dtsi    ← edit this
         │
         ├─── boards/glove80/layers/base.dtsi   ← keymapsync.sh writes this
         └─── boards/slicemk/layers/base.dtsi   ← keymapsync.sh writes this
```

Each board has the same 21 layer files, but with different key counts per row (60 / 80 / 77). The sync script translates binding positions using maps in `boards/translations/`.

### Shared vs board-specific

Everything in `shared/` is used by all boards unchanged:
- `shared/layers.dtsi` — layer index constants (`LAYER_Base`, `LAYER_Cursor`, …)
- `shared/macros.dtsi` — auto-pair macros, sequences
- `shared/behaviors.dtsi` — custom behaviors
- `shared/homeRowMods/` — HRM behaviors and macros
- `shared/combos/` — combo definitions
- `shared/global_timings.dtsi` — timing constants

Each board in `boards/<board>/` has:
- `positions.dtsi` — maps logical names (`POS_LH_C5R3`) to physical key numbers
- `position_groups.dtsi` — which keys belong to each hand (for HRM)
- `board_meta.dtsi` — hardware-specific config (trackpad, RGB, tap-dance)
- `layers/` — one `.dtsi` file per layer, with 60 / 80 / 77 bindings each

### Key position names

All boards use the same logical names for shared positions:

```
POS_LH_CxRy  →  left hand, column x (outermost = highest number), row y (top = 1)
POS_RH_CxRy  →  right hand, column x (innermost = 1), row y
POS_LH_T1    →  left thumb 1 (center)
POS_RH_T1    →  right thumb 1 (center)
```

Each board's `positions.dtsi` maps these to its own physical key numbers. See `docs/positionmapping.md` for the full table.

---

## The 21 layers

| # | Name | What it does |
|---|---|---|
| 0 | Base | QWERTY with Home Row Mods |
| 1 | Typing | Plain typing (HRM disabled) |
| 2 | Autoshift | Autoshift enabled |
| 3–6 | HRM Left (Pinky/Ring/Middy/Index) | Activated while left home-row key is held |
| 7–10 | HRM Right (Pinky/Ring/Middy/Index) | Activated while right home-row key is held |
| 11 | Cursor | Navigation |
| 12 | Keypad | Numpad |
| 13 | Symbol | Symbols (both hands) |
| 14 | Mouse | Mouse movement and buttons |
| 15–17 | MouseSlow / MouseFast / MouseWarp | Mouse speed variants |
| 18 | Magic | RGB status (Go60 / Glove80 only) |
| 19 | Symbol_lh | Left-hand symbols (right hand triggers) |
| 20 | Symbol_rh | Right-hand symbols (left hand triggers) |

---

## Editing a keymap

### 1. Open the go60 layer file

```sh
# Example: change something on the base layer
code boards/go60/layers/base.dtsi
```

Each file has a `bindings = < ... >;` block. Each binding corresponds to a key position in `boards/go60/positions.dtsi`. The binding order matches the physical key numbering (0, 1, 2, … left to right, top to bottom).

Common bindings:
```
&kp A              →  tap sends A
&trans             →  transparent (fall through to layer below)
&none              →  no action (block fall-through)
&mo LAYER_Cursor   →  hold = momentary Cursor layer
&lt LAYER_Cursor SPACE  →  tap = Space, hold = Cursor layer
&mt LGUI A         →  tap = A, hold = Left GUI
```

### 2. Sync to the other boards

```sh
bash scripts/keymapsync.sh
```

This reads `boards/translations/go60_to_glove80.map` and `go60_to_slicemk.map` and rewrites the matching positions in all 21 layer files on each board. Board-specific positions (Glove80's function row, SliceMK's inner columns) are left untouched.

### 3. Edit board-specific positions if needed

If your change affects a position that only exists on one board (e.g., Glove80's function row), edit that board's layer file directly:

```sh
code boards/glove80/layers/base.dtsi
# or
code boards/slicemk/layers/base.dtsi
```

### 4. Validate

```sh
bash scripts/validation.sh
```

Runs 21 structural checks — binding counts, include ordering, undefined labels, and more. If something is wrong this will tell you exactly what before it hits the compiler.

### 5. Commit and push

```sh
git add boards/ shared/          # or just git add -p to review changes
git commit -m "Update base layer: ..."
git push
```

GitHub Actions picks it up, validates, and builds all three boards in parallel. Firmware artifacts appear on the [Actions](../../actions) page within a few minutes.

---

## Getting firmware onto your keyboard

### Download from GitHub Actions

1. Go to the **Actions** tab on GitHub
2. Click the latest successful run
3. Scroll to **Artifacts** and download your board's firmware

| Board | Artifact | File |
|---|---|---|
| Go60 | `go60-firmware` | `go60.uf2` |
| Glove80 | `glove80-firmware` | `glove80.uf2` |
| SliceMK | `firmware` | `.uf2` |

### Flashing

**Go60 / Glove80:**
1. Double-press the reset button on the left half to enter bootloader (a USB drive appears)
2. Copy the `.uf2` file onto it — the keyboard reboots automatically
3. Repeat for the right half

**SliceMK:**
1. Double-press reset on the left-central half
2. Copy the `.uf2` file onto the drive that appears

---

## Inspecting layers

```sh
# See which layers are fully filled vs still all-&trans
bash scripts/diff_layers.sh

# Show all go60 bindings for a layer, numbered by key position
bash scripts/diff_layers.sh base

# Show one board's bindings
bash scripts/diff_layers.sh base glove80

# Diff two boards side by side
bash scripts/diff_layers.sh base go60 glove80
```

---

## Adding or modifying shared behaviors

| What | Where |
|---|---|
| New key behavior (tap-hold, etc.) | `shared/behaviors.dtsi` |
| New macro (key sequence) | `shared/macros.dtsi` |
| New mod-morph | `shared/modMorphs.dtsi` |
| Timing values | `shared/global_timings.dtsi` |
| New combo | `shared/combos/combos_common.dtsi` |

Changes here apply to all boards automatically — no sync step needed.

### Combos

Add raw combo nodes to `shared/combos/combos_common.dtsi`. Do **not** add a `/ { combos { ... }; };` wrapper — that wrapper already exists in each board's keymap file.

```
// Example combo: press J + K simultaneously → Escape
jk_combo: jk_combo {
    timeout-ms = <50>;
    key-positions = <POS_RH_C1R3 POS_RH_C2R3>;
    bindings = <&kp ESC>;
};
```

---

## Adding a new layer

1. Add `#define LAYER_Name N` to `shared/layers.dtsi` (keep indices 0-based and contiguous)
2. Create `boards/<board>/layers/<name>.dtsi` for **all three boards** (copy an existing layer as a starting point)
3. Add `#include "layers/<name>.dtsi"` to **all three** board keymap files
4. Update the expected layer counts in `scripts/validation.sh` (search for the hardcoded `20` and `21`)
5. Run `bash scripts/validation.sh` to confirm everything is consistent

---

## Common mistakes

| Mistake | Result | Fix |
|---|---|---|
| Edit glove80 layer directly without syncing | Next `keymapsync.sh` overwrites your changes | Always edit go60 first, then sync |
| Add `/ { combos { }; };` wrapper in shared combo files | Duplicate DTS nodes at build time | Combo files are raw includes — no wrapper |
| Include `shared/magic.dtsi` in slicemk.keymap | Build failure on slicemk/zmk fork | Magic is intentionally excluded from SliceMK |
| Run `keymapsync.sh` with system bash on macOS | `declare -A: invalid option` error | Use `bash scripts/keymapsync.sh` (script auto-upgrades to Homebrew bash) |
| Gap in layer indices in `shared/layers.dtsi` | Build failure + validation error | Keep indices contiguous, starting at 0 |

---

## Adding a net-new board

To bring a fourth (or fifth) keyboard into the repo:

### 1. Create the board directory

```sh
mkdir -p boards/<board>/layers
```

### 2. Write `positions.dtsi`

Map every physical key on the new board to the same logical `POS_*` names used by go60. Open `docs/positionmapping.md` and `boards/go60/positions.dtsi` side by side — the logical names are your guide.

```c
// boards/<board>/positions.dtsi

// Shared positions (match the same logical names as go60)
#define POS_LH_C6R1   <physical key number>
#define POS_LH_C5R1   <physical key number>
// ... all 60 shared positions

// Board-specific extras (only this board has these)
#define POS_LH_C0R1   <physical key number>   // e.g. an inner column
```

You must define all 60 shared positions plus any board-specific extras.

### 3. Write `position_groups.dtsi`

Define the five required macros. Copy from an existing board and adjust the key lists to match your physical layout:

```c
// boards/<board>/position_groups.dtsi
#define LEFT_HAND_KEYS    POS_LH_C6R1 POS_LH_C5R1 ... (all left-hand keys)
#define RIGHT_HAND_KEYS   POS_RH_C1R1 POS_RH_C2R1 ... (all right-hand keys)
#define THUMB_KEYS        POS_LH_T1 POS_LH_T2 POS_LH_T3 POS_RH_T1 POS_RH_T2 POS_RH_T3

#define HRM_LEFT_TRIGGER_POSITIONS   RIGHT_HAND_KEYS THUMB_KEYS
#define HRM_RIGHT_TRIGGER_POSITIONS  LEFT_HAND_KEYS  THUMB_KEYS
```

### 4. Write `board_meta.dtsi`

For most boards this is nearly empty — just a placeholder for hardware-specific config that doesn't belong in shared code (trackpad, RGB, tap-dance using `ZMK_TD_LAYER`). Copy from `boards/glove80/board_meta.dtsi` as a minimal template.

### 5. Write the keymap file

Copy an existing keymap (e.g. `boards/glove80/glove80.keymap`) and adjust:
- The `#include` path for ZMK system headers (`zmk/pointing.h` vs `zmk/mouse.h` depending on your fork)
- The layer `#include` list — include all 21 layers, or omit any that are incompatible with your fork
- The `compatible = "zmk,keymap"` node name
- The combo DTS wrapper

### 6. Create the 21 layer files

The fastest way is to copy all go60 layer files and adjust the binding count to match your board's key count. Add `&trans` for any extra positions your board has.

```sh
cp boards/go60/layers/*.dtsi boards/<board>/layers/
```

Then manually add the extra bindings for any positions that don't exist on go60 (board-specific keys). Each layer file must have exactly as many bindings as your board has keys.

### 7. Create the translation map

Create `boards/translations/go60_to_<board>.map`. For each of the 60 shared logical positions, find the go60 physical index and the new board's physical index and write a `src dst` pair:

```
# go60_to_<board>.map
# go60 index → <board> index
0 <board key number for POS_LH_C6R1>
1 <board key number for POS_LH_C5R1>
...
```

Use `docs/positionmapping.md` and your new `positions.dtsi` to build this map. The file must have exactly 60 entries.

### 8. Add the board to `keymapsync.sh`

In `scripts/keymapsync.sh`, add the new board alongside glove80 and slicemk:

```bash
# Near the top, add:
NEWBOARD_DIR="$REPO_ROOT/boards/<board>/layers"

# In the main section, add a new declare and load_map call:
declare -A fwd_newboard
load_map "$TRANS_DIR/go60_to_<board>.map" fwd_newboard

# And a new sync loop:
echo
echo "==> go60 → <board>"
for f in "$GO60_DIR"/*.dtsi; do
  sync_layer "$f" "$NEWBOARD_DIR/$(basename "$f")" fwd_newboard
done
```

### 9. Update `validation.sh`

Add the new board to each relevant check:
- Section 1 (required files): add `boards/<board>/positions.dtsi`, `position_groups.dtsi`, `board_meta.dtsi`, keymap, conf
- Section 2 (layer files and keymap includes): add a case for the new board
- Section 3 (position counts): call `check_positions <board> <N>`
- Section 4 (binding counts): call `check_layer_bindings <board> <N>`
- Sections 5–7, 12–13, 17–21: add the board to each loop or add a new case

### 10. Add a build step

**Nix build** (if using moergo-sc/zmk or a similar fork):
- Copy `build/glove80.nix`, adjust the board name and shield

**west build** (if using a standard west-compatible fork):
- Add the board to `build.yaml`
- The existing GitHub Actions workflow (`build-user-config.yml`) will pick it up

### 11. Validate and sync

```sh
bash scripts/validation.sh   # fix any errors it finds
bash scripts/keymapsync.sh   # propagate go60 layers to the new board
bash scripts/validation.sh   # confirm clean
```

---

## Next steps

- `docs/zmk-sync-architecture.md` — deep dive into how the sync system works
- `docs/positionmapping.md` — full cross-board position number reference table
- [ZMK documentation](https://zmk.dev/docs) — ZMK behaviors, combos, macros reference
