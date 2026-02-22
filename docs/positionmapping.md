# Physical Position Cross-Reference: Go60 / Glove80 / SliceMK ErgoDox

## How This Works

Every board defines the **same logical position names** (e.g., `POS_LH_C5R3`) pointing to
**different physical key numbers**. Shared behaviors, combos, and HRM configs reference the
logical names — the C preprocessor resolves them to the correct physical numbers at build time.

---

## Core Positions (shared across ALL three boards)

These positions exist on every board. Any shared code that uses only these names
will compile on all three boards without `#ifdef` guards.

| Logical Name| Function            | Go60        | Glove80 | slicMk  |
|-------------|---------------------|-------------|---------|---------|
| **Row 1 (Numbers)**
| Logical Name| Function            | Go60        | Glove80 | slicMk  |
|-------------|---------------------|-------------|---------|---------|
| POS_LH_C6R1 | Esc/Grave           | 0           | 10      | 1       |
| POS_LH_C5R1 | 1                   | 1           | 11      | 2       |
| POS_LH_C4R1 | 2                   | 2           | 12      | 3       |
| POS_LH_C3R1 | 3                   | 3           | 13      | 4       |
| POS_LH_C2R1 | 4                   | 4           | 14      | 5       |
| POS_LH_C1R1 | 5                   | 5           | 15      | 6       |
| POS_RH_C1R1 | 6                   | 6           | 16      | 9       |
| POS_RH_C2R1 | 7                   | 7           | 17      | 10      |
| POS_RH_C3R1 | 8                   | 8           | 18      | 11      |
| POS_RH_C4R1 | 9                   | 9           | 19      | 12      |
| POS_RH_C5R1 | 0                   | 10          | 20      | 13      |
| POS_RH_C6R1 | Brace/symbol        | 11          | 21      | 14      |
| **Row 2 (QWERTY)**
| Logical Name| Function            | Go60        | Glove80 | slicMk  |
|-------------|---------------------|-------------|---------|---------|
| POS_LH_C6R2 | Tab                 | 12          | 22      | 15      |
| POS_LH_C5R2 | Q                   | 13          | 23      | 16      |
| POS_LH_C4R2 | W                   | 14          | 24      | 17      |
| POS_LH_C3R2 | E                   | 15          | 25      | 18      |
| POS_LH_C2R2 | R                   | 16          | 26      | 19      |
| POS_LH_C1R2 | T                   | 17          | 27      | 20      |
| POS_RH_C1R2 | Y                   | 18          | 28      | 23      |
| POS_RH_C2R2 | U                   | 19          | 29      | 24      |
| POS_RH_C3R2 | I                   | 20          | 30      | 25      |
| POS_RH_C4R2 | O                   | 21          | 31      | 26      |
| POS_RH_C5R2 | P                   | 22          | 32      | 27      |
| POS_RH_C6R2 | Paren/symbol        | 23          | 33      | 28      |
| **Row 3 (Home — HRM lives here)** 
| Logical Name| Function            | Go60        | Glove80 | slicMk  |
|-------------|---------------------|-------------|---------|---------|
| POS_LH_C6R3 | Shift/Tab           | 24          | 34      | 29      |
| POS_LH_C5R3 | A (GUI)             | 25          | 35      | 30      |
| POS_LH_C4R3 | S (ALT)             | 26          | 36      | 31      |
| POS_LH_C3R3 | D (CTRL)            | 27          | 37      | 32      |
| POS_LH_C2R3 | F (SHIFT)           | 28          | 38      | 33      |
| POS_LH_C1R3 | G (Symbol)          | 29          | 39      | 34      |
| POS_RH_C1R3 | H (Symbol)          | 30          | 40      | 35      |
| POS_RH_C2R3 | J (SHIFT)           | 31          | 41      | 36      |
| POS_RH_C3R3 | K (CTRL)            | 32          | 42      | 37      |
| POS_RH_C4R3 | L (ALT)             | 33          | 43      | 38      |
| POS_RH_C5R3 | ; (GUI)             | 34          | 44      | 39      |
| POS_RH_C6R3 | '/DQT               | 35          | 45      | 40      |
| **Row 4 (ZXCV)**
| Logical Name| Function            | Go60        | Glove80 | slicMk  |
|-------------|---------------------|-------------|---------|---------|
| POS_LH_C6R4 | Shift           | 36   | 46      | 41      |
| POS_LH_C5R4 | Z               | 37   | 47      | 42      |
| POS_LH_C4R4 | X               | 38   | 48      | 43      |
| POS_LH_C3R4 | C               | 39   | 49      | 44      |
| POS_LH_C2R4 | V               | 40   | 50      | 45      |
| POS_LH_C1R4 | B               | 41   | 51      | 46      |
| POS_RH_C1R4 | N               | 42   | 58      | 49      |
| POS_RH_C2R4 | M               | 43   | 59      | 50      |
| POS_RH_C3R4 | ,               | 44   | 60      | 51      |
| POS_RH_C4R4 | .               | 45   | 61      | 52      |
| POS_RH_C5R4 | /               | 46   | 62      | 53      |
| POS_RH_C6R4 | Angle/symbol    | 47   | 63      | 54      |
| **Primary Thumbs (T1-T3)**
| Logical Name| Function            | Go60        | Glove80 | slicMk  |
|-------------|---------------------|-------------|---------|---------|
| POS_LH_T1   | Space/Nav       | 54   | 69      | 69      |
| POS_LH_T2   | Enter/Power     | 55   | 70      | 70      |
| POS_LH_T3   | Tertiary        | 56   | 71      | 71      |
| POS_RH_T3   | Tertiary        | 57   | 72      | 72      |
| POS_RH_T2   | Bspc            | 58   | 73      | 73      |
| POS_RH_T1   | Space/Nav       | 59   | 74      | 74      |

---

## Board-Specific Positions

### Glove80 Only

| Logical Name | Physical | Notes                           
|--------------|----------|-------------------------------------|
| POS_LH_C5R0  | 0        | Function row (brightness dn)        |
| POS_LH_C4R0  | 1        | Function row (brightness up)        |
| POS_LH_C3R0  | 2        | Function row (mission ctl)          |
| POS_LH_C2R0  | 3        | Function row (lock screen)          |
| POS_LH_C1R0  | 4        | Function row (magic)                |
| POS_RH_C1R0  | 5        | Function row (prev)                 |
| POS_RH_C2R0  | 6        | Function row (next)                 |
| POS_RH_C3R0  | 7        | Function row (vol dn)               |
| POS_RH_C4R0  | 8        | Function row (vol up)               |
| POS_RH_C5R0  | 9        | Function row (bracket)              |
| POS_LH_C1R4i | 52       | Inner column row 4                  |
| POS_LH_C2R4i | 53       | Inner column row 4                  |
| POS_LH_C3R4i | 54       | Inner column row 4                  |
| POS_RH_C3R4i | 55       | Inner column row 4                  |
| POS_RH_C2R4i | 56       | Inner column row 4                  |
| POS_RH_C1R4i | 57       | Inner column row 4                  |
| POS_LH_C5R5  | 64       | Bottom row (5 per side vs Go60's 3) |
| POS_LH_C1R5  | 68       | Bottom row                          |
| POS_RH_C1R5  | 75       | Bottom row                          |
| POS_RH_C5R5  | 79       | Bottom row                          |
|--------------|----------|-------------------------------------|
### SliceMK ErgoDox Only

| Logical Name   | Physical | Notes |
|----------------|----------|-------|
| POS_SPECIAL_R0 | 0        | Single top key (bootloader/special) |
| POS_LH_C0R1    | 7        | Inner column key (layer toggle) |
| POS_RH_C0R1    | 8        | Inner column key (layer toggle) |
| POS_LH_C0R2    | 21       | Inner column key (media) |
| POS_RH_C0R2    | 22       | Inner column key (media) |
| POS_LH_C0R4    | 47       | Inner column key (media) |
| POS_RH_C0R4    | 48       | Inner column key (media) |
| POS_LH_C5R5    | 55       | Bottom row (5 per side vs Go60's 3) |
| POS_LH_C1R5    | 59       | Bottom row |
| POS_RH_C1R5    | 60       | Bottom row |
| POS_RH_C5R5    | 64       | Bottom row |
| POS_LH_T4      | 65       | Thumb tier 1 (top pair) |
| POS_LH_T5      | 66       | Thumb tier 1 |
| POS_RH_T5      | 67       | Thumb tier 1 |
| POS_RH_T4      | 68       | Thumb tier 1 |
| POS_LH_T6      | 75       | Thumb tier 3 (bottom single) |
| POS_RH_T6      | 76       | Thumb tier 3 |

---

## Shared Code Safety

### Always safe (no guards needed)
Any code referencing only the **Core Positions** table above will compile on all boards.
This includes all HRM behaviors, F-key combos, and most other shared features.

### Requires `#ifdef` guards
```c
#ifdef POS_LH_C0R1    /* Only exists on ErgoDox */
    /* ErgoDox inner column combo */
#endif

#ifdef POS_LH_C5R0    /* Only exists on Glove80 */
    /* Glove80 function row binding */
#endif
```

### Thumb key compatibility
T1-T3 exist on all boards. T4-T6 only exist on ErgoDox.
The Glove80 also has 6 thumb keys per side, but uses a different physical arrangement —
its extra thumbs would need their own naming if you want to share thumb-cluster logic
beyond the primary T1-T3.

---

## Validation

The `HRM_LEFT_TRIGGER_POSITIONS` and `HRM_RIGHT_TRIGGER_POSITIONS` macros automatically
include ALL keys on the opposite hand + all thumbs for each board. This means:

- **Go60**: ~30 trigger positions per side (27 hand + 6 thumb)
- **Glove80**: ~42 trigger positions per side (37 hand + 6 thumb)  
- **ErgoDox**: ~38 trigger positions per side (32 hand + 12 thumb)

The shared HRM behaviors don't care about the count — they just expand the macro.
More trigger positions = more keys that can trigger the hold. This is correct behavior:
if the Glove80 has an extra function row, pressing those keys should still trigger
an opposite-hand homerow mod hold.