#!/bin/bash
# ──────────────────────────────────────────────────────────────
# setup-git-hooks.sh
#
# Configures git to use .githooks/ for hook scripts.
# Run once after cloning:  ./scripts/setup-git-hooks.sh
# ──────────────────────────────────────────────────────────────

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$REPO_ROOT/.githooks"

echo "Setting git hooks path to .githooks/ ..."
git config core.hooksPath .githooks

# Verify pre-push is executable
if [[ -f "$HOOKS_DIR/pre-push" ]]; then
    if [[ ! -x "$HOOKS_DIR/pre-push" ]]; then
        chmod +x "$HOOKS_DIR/pre-push"
        echo "Made pre-push hook executable."
    fi
    echo "✓ Git hooks configured. pre-push hook is active."
else
    echo "✗ Warning: $HOOKS_DIR/pre-push not found."
    exit 1
fi
