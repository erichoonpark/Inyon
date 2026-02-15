#!/bin/bash
# ──────────────────────────────────────────────────────────────
# run-tests-on-change.sh
#
# Claude Code hook: runs the Inyon test suite after source edits
# and blocks task completion until tests pass.
#
# Called by:
#   PostToolUse (Write|Edit) — feedback on each edit
#   Stop (FULL_SUITE=1)      — gate before Claude finishes
#
# Auto-fix loop:
#   Claude sees test failures via stderr → fixes → re-edits →
#   hook fires again. After MAX_ATTEMPTS failures, the Stop hook
#   stops blocking so Claude can report what's still broken.
#
# Configuration:
#   DESTINATION  — iOS Simulator destination (edit below)
#   MAX_ATTEMPTS — auto-fix retry limit before giving up
# ──────────────────────────────────────────────────────────────

set -uo pipefail

# ── Config ────────────────────────────────────────────────────
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2"
MAX_ATTEMPTS=5
NOTIFY_PHONE="+12135981088"   # iMessage number for done notifications
# ──────────────────────────────────────────────────────────────

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Read hook JSON from stdin (non-blocking, tolerate empty)
INPUT=""
if ! [ -t 0 ]; then
    INPUT=$(cat 2>/dev/null || true)
fi

# Parse file_path and session_id (use python3 fallback if no jq)
parse_json() {
    local key="$1"
    if command -v jq &>/dev/null; then
        echo "$INPUT" | jq -r "$key" 2>/dev/null || echo ""
    elif command -v python3 &>/dev/null; then
        echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    keys = '$key'.strip('.').split('.')
    for k in keys:
        d = d.get(k, {}) if isinstance(d, dict) else {}
    print(d if isinstance(d, str) else '')
except: print('')
" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

FILE_PATH=$(parse_json '.tool_input.file_path')
SESSION_ID=$(parse_json '.session_id')
SESSION_ID="${SESSION_ID:-unknown}"

IS_FULL_SUITE="${FULL_SUITE:-0}"

# ── Skip non-source files (PostToolUse only) ──────────────────
if [[ "$IS_FULL_SUITE" != "1" && -n "$FILE_PATH" ]]; then
    case "$FILE_PATH" in
        *.swift) ;;  # source file — run tests
        *)
            exit 0   # not source — skip silently
            ;;
    esac
fi

# ── Attempt tracking ──────────────────────────────────────────
ATTEMPT_FILE="/tmp/inyon-test-attempts-${SESSION_ID}"

current_attempts() {
    if [[ -f "$ATTEMPT_FILE" ]]; then
        cat "$ATTEMPT_FILE"
    else
        echo 0
    fi
}

increment_attempts() {
    local n
    n=$(current_attempts)
    n=$((n + 1))
    echo "$n" > "$ATTEMPT_FILE"
    echo "$n"
}

reset_attempts() {
    rm -f "$ATTEMPT_FILE"
}

# ── Run tests ─────────────────────────────────────────────────
TEST_OUTPUT=$(xcodebuild test \
    -project Inyon.xcodeproj \
    -scheme Inyon \
    -destination "$DESTINATION" \
    -quiet 2>&1) && TEST_EXIT=0 || TEST_EXIT=$?

# ── Tests passed ──────────────────────────────────────────────
if [[ $TEST_EXIT -eq 0 ]]; then
    reset_attempts
    echo "All tests passed." >&2

    # Send iMessage notification on successful task completion (Stop hook only)
    if [[ "$IS_FULL_SUITE" == "1" && -n "$NOTIFY_PHONE" ]]; then
        osascript -e "tell application \"Messages\" to send \"Claude Code finished at $(date +%H:%M). All tests passed.\" to buddy \"$NOTIFY_PHONE\" of (first account whose service type is iMessage)" 2>/dev/null || true
    fi

    exit 0
fi

# ── Tests failed ──────────────────────────────────────────────
ATTEMPTS=$(increment_attempts)

# Extract readable failure summary
FAILURES=$(echo "$TEST_OUTPUT" \
    | grep -E '(error:|Test Case.*failed|FAILED|Executed .* with .* failure)' \
    | head -30)

EDITED_NOTE=""
if [[ -n "$FILE_PATH" ]]; then
    EDITED_NOTE=" after editing $(basename "$FILE_PATH")"
fi

if [[ "$IS_FULL_SUITE" == "1" ]]; then
    # ── Stop hook: block Claude from finishing ─────────────────
    if [[ $ATTEMPTS -ge $MAX_ATTEMPTS ]]; then
        cat >&2 <<EOFAIL

TEST FAILURES (attempt $ATTEMPTS/$MAX_ATTEMPTS — auto-fix limit reached):
$FAILURES

Auto-fix limit reached after $MAX_ATTEMPTS attempts.
Stop and report:
  1. Which tests are still failing
  2. Root-cause hypothesis for each
  3. Exact manual fix to try next
EOFAIL
        reset_attempts
        exit 0  # let Claude finish — it must report the failures
    else
        cat >&2 <<EOFAIL

TEST FAILURES (attempt $ATTEMPTS/$MAX_ATTEMPTS):
$FAILURES

Tests must pass before you finish. Fix the failures above.
Do not ask for confirmation — apply the minimal targeted fix and continue.
EOFAIL
        exit 2  # block — Claude must keep going
    fi
else
    # ── PostToolUse: provide feedback so Claude auto-fixes ─────
    cat >&2 <<EOFAIL

TEST FAILURES${EDITED_NOTE} (attempt $ATTEMPTS/$MAX_ATTEMPTS):
$FAILURES

Fix the failing tests. Apply the minimal targeted fix, then continue.
EOFAIL
    if [[ $ATTEMPTS -ge $MAX_ATTEMPTS ]]; then
        cat >&2 <<EOLIMIT
Auto-fix limit ($MAX_ATTEMPTS) reached. Stop editing and report:
  1. Which tests are still failing
  2. Root-cause hypothesis for each
  3. Exact manual fix to try next
EOLIMIT
    fi
    exit 0
fi
