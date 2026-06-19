#!/usr/bin/env bash
# install-hooks.sh — opt in to this repo's git hooks (.githooks/).
#
# Sets core.hooksPath so the committed hooks (commit-msg, pre-commit) run for
# your clone. This is optional; CI remains authoritative either way.
#
# Usage: bash scripts/install-hooks.sh
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true

echo "Enabled repo hooks: core.hooksPath = .githooks"
echo "Active hooks:"
for h in .githooks/*; do
  [[ -f "$h" ]] && echo "  - $(basename "$h")"
done
echo
echo "To disable: git config --unset core.hooksPath"
