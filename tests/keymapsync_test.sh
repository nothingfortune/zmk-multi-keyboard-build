#!/usr/bin/env bash
# Fixture-based regression tests for scripts/keymapsync.sh
#
# These tests run the REAL sync script against a tiny synthetic repo tree
# (via the KEYMAPSYNC_REPO_ROOT override) so a parser regression can be
# reproduced from a small fixture instead of a full keyboard configuration.
#
# Usage: bash tests/keymapsync_test.sh
# Exit:  0 = all pass, 1 = one or more failures
#
# Re-exec with bash 4+ if needed (matches keymapsync.sh requirement).
if (( BASH_VERSINFO[0] < 4 )); then
  for _b in /opt/homebrew/bin/bash /usr/local/bin/bash; do
    [[ -x "$_b" ]] && exec "$_b" "$0" "$@"
  done
  echo "Error: bash 4+ required. Install via: brew install bash" >&2; exit 1
fi
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNC="$REPO_ROOT/scripts/keymapsync.sh"

TESTS=0
FAILS=0
if [[ -t 1 ]]; then GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
else GREEN=''; RED=''; BOLD=''; NC=''; fi

pass() { printf "  ${GREEN}PASS${NC}  %s\n" "$1"; TESTS=$((TESTS+1)); }
fail() { printf "  ${RED}FAIL${NC}  %s\n" "$1"; TESTS=$((TESTS+1)); FAILS=$((FAILS+1)); }

# assert_contains <file> <literal-string> <message>
assert_contains() {
  if grep -qF -- "$2" "$1"; then pass "$3"; else fail "$3 — expected to find: $2"; fi
}
# assert_not_contains <file> <literal-string> <message>
assert_not_contains() {
  if grep -qF -- "$2" "$1"; then fail "$3 — unexpectedly found: $2"; else pass "$3"; fi
}
# assert_line_contains <file> <literal-A> <literal-B> <message>  (A and B on the same line)
assert_line_contains() {
  if grep -F -- "$2" "$1" | grep -qF -- "$3"; then pass "$4"
  else fail "$4 — expected a line with both '$2' and '$3'"; fi
}
# assert_str_contains <string> <literal> <message>  (asserts against captured output)
assert_str_contains() {
  if printf '%s' "$1" | grep -qF -- "$2"; then pass "$3"; else fail "$3 — expected output to contain: $2"; fi
}

# ── Build a minimal fixture repo tree under $1 ───────────────────────────────
build_fixture() {
  local root="$1"
  mkdir -p "$root/boards/go60/layers" \
           "$root/boards/glove80/layers" \
           "$root/boards/slicemk/layers" \
           "$root/boards/translations"

  # Forward maps: go60 indices 0..3 → target indices 0..3 (index 4 is target-only)
  printf '# go60 -> glove80\n0 0\n1 1\n2 2\n3 3\n' > "$root/boards/translations/go60_to_glove80.map"
  printf '# go60 -> slicemk\n0 0\n1 1\n2 2\n3 3\n' > "$root/boards/translations/go60_to_slicemk.map"

  # go60 canonical base layer: exercises zero/single/multi-param + a &magic binding.
  cat > "$root/boards/go60/layers/base.dtsi" <<'EOF'
/ {
    keymap {
        compatible = "zmk,keymap";
        base_layer {
            /* canonical go60 base */
            bindings = <
                &gresc
                &kp A
                &HRM_left_pinky LGUI S
                &magic LAYER_Magic 0
            >;
        };
    };
};
EOF

  # go60 layer with an empty bindings block → must be skipped, not corrupt targets.
  cat > "$root/boards/go60/layers/empty.dtsi" <<'EOF'
/ {
    keymap {
        compatible = "zmk,keymap";
        empty_layer {
            bindings = <  >;
        };
    };
};
EOF

  # Target base layers: mapped positions get overwritten, index 4 stays board-only.
  # Comment scaffolding (/* n */ and // ...) must survive the sync untouched.
  cat > "$root/boards/glove80/layers/base.dtsi" <<'EOF'
/ {
    keymap {
        compatible = "zmk,keymap";
        base_layer {
            bindings = <
/* 0 */         &kp Q
/* 1 */         &kp W
/* 2 */         &kp E
/* 3 */         &kp R
/* 4 */         &kp BOARDONLY            /* glove80-only thumb */
            >;
        };
    };
};
EOF

  cat > "$root/boards/slicemk/layers/base.dtsi" <<'EOF'
/ {
    keymap {
        compatible = "zmk,keymap";
        base_layer {
            bindings = <
/* 0 */         &kp Q
/* 1 */         &kp W
/* 2 */         &kp E
/* 3 */         &kp R
/* 4 */         &kp SLICEONLY
            >;
        };
    };
};
EOF

  # Target empty layers carry a sentinel binding to prove they stay untouched.
  for b in glove80 slicemk; do
    cat > "$root/boards/$b/layers/empty.dtsi" <<'EOF'
/ {
    keymap {
        compatible = "zmk,keymap";
        empty_layer {
            bindings = <
                &kp UNTOUCHED
            >;
        };
    };
};
EOF
  done
}

# ── Run ──────────────────────────────────────────────────────────────────────
FIX="$(mktemp -d "${TMPDIR:-/tmp}/keymapsync_fixture.XXXXXX")"
trap 'rm -rf "$FIX"' EXIT
build_fixture "$FIX"

printf "${BOLD}── keymapsync.sh fixture tests${NC}\n"

SYNC_OUT="$(KEYMAPSYNC_REPO_ROOT="$FIX" bash "$SYNC" 2>&1)"
SYNC_RC=$?
if [[ $SYNC_RC -ne 0 ]]; then
  fail "sync exited $SYNC_RC (expected 0)"; printf "%s\n" "$SYNC_OUT"
else
  pass "sync completed successfully (exit 0)"
fi

GB="$FIX/boards/glove80/layers/base.dtsi"
SB="$FIX/boards/slicemk/layers/base.dtsi"

# 1. Zero-parameter binding (&gresc)
assert_contains "$GB" "&gresc" "zero-param binding (&gresc) synced to glove80"
# 2. Single-parameter binding (&kp A)
assert_contains "$GB" "&kp A" "single-param binding (&kp A) synced to glove80"
# 3. Multi-parameter binding (HRM) kept intact as one binding
assert_contains "$GB" "&HRM_left_pinky LGUI S" "multi-param HRM binding synced intact to glove80"
# 4. Inline + block comments preserved
assert_contains "$GB" "/* 0 */" "block comment scaffold preserved"
assert_contains "$GB" "/* glove80-only thumb */" "inline comment preserved"
# 5. Target-board-only position preserved (index 4 not in map)
assert_contains "$GB" "&kp BOARDONLY" "glove80-only position preserved"
assert_contains "$SB" "&kp SLICEONLY" "slicemk-only position preserved"
# 6. SliceMK &magic → &none rewrite (glove80 keeps &magic)
assert_contains "$GB" "&magic LAYER_Magic 0" "glove80 keeps &magic binding"
assert_not_contains "$SB" "&magic" "slicemk &magic rewritten away"
assert_contains "$SB" "&none" "slicemk received &none in place of &magic"
# 7. Surrounding DTS structure preserved
assert_contains "$GB" 'compatible = "zmk,keymap";' "surrounding DTS structure preserved"
assert_contains "$GB" "base_layer {" "layer node preserved"
# 8. Readable alignment/formatting: replacement happened in place, comment column kept
assert_line_contains "$GB" "/* 0 */" "&gresc" "binding replaced in place; comment column kept"
# 10. Malformed/empty bindings block → skipped, target untouched (clear behavior)
assert_str_contains "$SYNC_OUT" "skip" "empty bindings block produced a clear skip message"
assert_contains "$FIX/boards/glove80/layers/empty.dtsi" "&kp UNTOUCHED" "empty-source target left untouched (glove80)"
assert_contains "$FIX/boards/slicemk/layers/empty.dtsi" "&kp UNTOUCHED" "empty-source target left untouched (slicemk)"

# 9. Idempotency: a second sync produces no further changes
cp "$GB" "$FIX/.gb.after1"; cp "$SB" "$FIX/.sb.after1"
KEYMAPSYNC_REPO_ROOT="$FIX" bash "$SYNC" >/dev/null 2>&1
if diff -q "$FIX/.gb.after1" "$GB" >/dev/null && diff -q "$FIX/.sb.after1" "$SB" >/dev/null; then
  pass "idempotent: second sync produced no further changes"
else
  fail "idempotent: second sync changed files"
  diff "$FIX/.gb.after1" "$GB" || true
  diff "$FIX/.sb.after1" "$SB" || true
fi

printf "\n${BOLD}── keymapsync results: %d run, %d failed${NC}\n" "$TESTS" "$FAILS"
[[ "$FAILS" -eq 0 ]] && exit 0 || exit 1
