# RCA: SliceMK Validation Failure on Magic Binding

Date: 2026-04-11
Status: Resolved
Owner: zmk-multi-keyboard-build

## Summary

Validation failed for SliceMK with an undefined label error for `&magic` after running sync.

Observed failure:

- `boards/slicemk — undefined &labels: &magic`

The issue was caused by sync behavior, not by manual layer edits.

## Impact

- `scripts/validation.sh` failed in the undefined label check.
- CI validation/build pipeline was blocked for commits where synced SliceMK layers included `&magic`.
- Developers could repeatedly hit the same failure after each sync run.

## Detection

The failure reproduced locally with:

```sh
bash scripts/keymapsync.sh
bash scripts/validation.sh
```

Validation section 18 reported unresolved `&magic` references on SliceMK.

## Technical Context

- Go60 is the source of truth and uses `&magic LAYER_Magic 0` in multiple layer files.
- SliceMK intentionally excludes `shared/magic.dtsi` because RGB status behavior is unsupported in the `slicemk/zmk` fork.
- `scripts/keymapsync.sh` previously copied Go60 bindings directly to SliceMK mapped positions, including `&magic`.

This created an invalid state:

1. SliceMK keymap correctly excluded magic includes.
2. SliceMK layer files still contained `&magic` references.
3. Validation (and downstream DTS compile) flagged `&magic` as undefined.

## Root Cause

Sync logic did not apply board-specific behavior translation for incompatible bindings.

Specifically, there was no SliceMK exception in `scripts/keymapsync.sh` to prevent importing Go60 `&magic` bindings into SliceMK layer files.

## Resolution

Updated `scripts/keymapsync.sh` to include target-board context in `sync_layer` and apply a SliceMK-specific rewrite:

- If target board is `slicemk` and synced binding starts with `&magic`, map it to `&none`.

This preserves Go60 as source-of-truth while enforcing SliceMK compatibility automatically during sync.

## Verification

Post-fix verification command:

```sh
bash scripts/keymapsync.sh && bash scripts/validation.sh
```

Result:

- `PASS: 309`
- `FAIL: 0`
- `WARN: 0`
- Section 18 now passes for SliceMK label resolution.

## Why This Fix

- Keeps one-way sync model unchanged (Go60 source of truth).
- Prevents recurring regressions without requiring manual post-sync edits.
- Aligns sync output with existing SliceMK constraints already documented and validated.

## Preventive Actions

1. Keep SliceMK incompatibility rules encoded in sync scripts, not only in docs.
2. Keep validation checks for both conditions:
   - no magic include on SliceMK
   - no unresolved `&magic` refs on SliceMK layers
3. When adding shared behaviors, explicitly define per-board compatibility behavior in sync/validation scripts.

## Related Files

- `scripts/keymapsync.sh`
- `scripts/validation.sh`
- `boards/slicemk/slicemk.keymap`
- `shared/magic.dtsi`
