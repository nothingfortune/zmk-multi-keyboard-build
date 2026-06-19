#!/usr/bin/env bash
# check.sh — one local command that mirrors the important CI gates.
#
# It runs, in order:
#   1. keymap synchronization (go60 → glove80/slicemk)
#   2. drift detection: did sync change tracked derived files?
#   3. structural validation (scripts/validation.sh)
#   4. keymapsync fixture tests (tests/keymapsync_test.sh)
#
# Usage:
#   bash scripts/check.sh            # run everything
#   bash scripts/check.sh --no-tests # skip the fixture tests (steps 1–3 only)
#
# Exit: 0 = all gates pass and no drift; 1 = any gate failed or drift detected.
# This intentionally matches what CI enforces so a clean run here predicts a
# clean CI run.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RUN_TESTS=1
[[ "${1:-}" == "--no-tests" ]] && RUN_TESTS=0

if [[ -t 1 ]]; then GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
else GREEN=''; RED=''; YELLOW=''; BOLD=''; NC=''; fi
hdr()  { printf "\n${BOLD}══ %s${NC}\n" "$1"; }
good() { printf "  ${GREEN}✓${NC} %s\n" "$1"; }
bad()  { printf "  ${RED}✗${NC} %s\n" "$1"; }
note() { printf "  ${YELLOW}!${NC} %s\n" "$1"; }

sync_result="pass"; drift_result="pass"; validate_result="pass"; tests_result="skipped"

# ── 1. Sync ──────────────────────────────────────────────────────────────────
hdr "1/4  Keymap sync (go60 → glove80/slicemk)"
if bash scripts/keymapsync.sh; then good "sync completed"; else bad "sync failed"; sync_result="fail"; fi

# ── 2. Drift detection ───────────────────────────────────────────────────────
hdr "2/4  Drift detection (are committed derived files in sync?)"
DERIVED=(boards/glove80/layers boards/slicemk/layers)
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  note "not a git work tree — skipping drift check"
  drift_result="skipped"
elif git diff --quiet -- "${DERIVED[@]}"; then
  good "derived board files are in sync with go60"
else
  bad "sync changed derived files — commit them before pushing (CI will fail otherwise):"
  git --no-pager diff --stat -- "${DERIVED[@]}" | sed 's/^/      /'
  drift_result="fail"
fi

# ── 3. Validation ────────────────────────────────────────────────────────────
hdr "3/4  Structural validation"
if bash scripts/validation.sh >/tmp/check_validation.$$ 2>&1; then
  good "validation passed"
  grep -E 'PASS: [0-9]' /tmp/check_validation.$$ | tail -1 | sed 's/^/      /'
else
  bad "validation failed — details:"
  sed 's/^/      /' /tmp/check_validation.$$
  validate_result="fail"
fi
rm -f /tmp/check_validation.$$

# ── 4. Fixture tests ─────────────────────────────────────────────────────────
hdr "4/4  keymapsync fixture tests"
if [[ "$RUN_TESTS" -eq 0 ]]; then
  note "skipped (--no-tests)"
else
  if bash tests/keymapsync_test.sh >/tmp/check_tests.$$ 2>&1; then
    good "fixture tests passed"
    tests_result="pass"
  else
    bad "fixture tests failed — details:"
    sed 's/^/      /' /tmp/check_tests.$$
    tests_result="fail"
  fi
  rm -f /tmp/check_tests.$$
fi

# ── Summary ──────────────────────────────────────────────────────────────────
hdr "Summary"
printf "  sync:       %s\n" "$sync_result"
printf "  drift:      %s\n" "$drift_result"
printf "  validation: %s\n" "$validate_result"
printf "  tests:      %s\n" "$tests_result"

if [[ "$sync_result" == "fail" || "$drift_result" == "fail" \
   || "$validate_result" == "fail" || "$tests_result" == "fail" ]]; then
  printf "\n${RED}${BOLD}CHECK FAILED${NC} — fix the items above before pushing.\n\n"
  exit 1
fi
printf "\n${GREEN}${BOLD}ALL CHECKS PASSED${NC}\n\n"
exit 0
