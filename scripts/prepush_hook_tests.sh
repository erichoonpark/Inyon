#!/bin/bash
# ──────────────────────────────────────────────────────────────
# prepush_hook_tests.sh
#
# Tests simulator-selection behavior used by .githooks/pre-push.
# Run: bash scripts/prepush_hook_tests.sh
# ──────────────────────────────────────────────────────────────

set -uo pipefail

PASS=0
FAIL=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/select_simulator.sh"

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $label"
        echo "    expected: '$expected'"
        echo "    actual:   '$actual'"
        FAIL=$((FAIL + 1))
    fi
}

assert_ne() {
    local label="$1" unexpected="$2" actual="$3"
    if [[ "$unexpected" != "$actual" ]]; then
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $label"
        echo "    did not expect: '$unexpected'"
        echo "    actual:         '$actual'"
        FAIL=$((FAIL + 1))
    fi
}

assert_not_empty() {
    local label="$1" actual="$2"
    if [[ -n "$actual" ]]; then
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $label (was empty)"
        FAIL=$((FAIL + 1))
    fi
}

run_selector() {
    local device_list="$1"
    select_simulator_destination_from_list "$device_list"
}

echo ""
echo "test_prePushSimulatorSelection_exactMatchAndFallbackBehavior"
echo ""

# Test 1: exact preferred ordering wins (17 Pro > 17 > 16e > 16)
echo "Test 1: Preferred exact order is respected"
FAKE_DEVICES="-- iOS 18.0 --
    iPhone 16 (AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE) (Booted)
    iPhone 17 (11111111-2222-3333-4444-555555555555) (Shutdown)
    iPhone 16e (99999999-8888-7777-6666-555555555555) (Shutdown)"
RESULT=$(run_selector "$FAKE_DEVICES")
assert_eq "selects iPhone 17 over iPhone 16/16e" \
    "platform=iOS Simulator,name=iPhone 17" "$RESULT"

# Test 2: only iPhone 16e present must never resolve to iPhone 16
echo "Test 2: iPhone 16e does not false-match iPhone 16"
FAKE_DEVICES="-- iOS 18.0 --
    iPhone 16e (AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE) (Shutdown)
    iPad Air (11111111-2222-3333-4444-555555555555) (Shutdown)"
RESULT=$(run_selector "$FAKE_DEVICES")
assert_eq "selects iPhone 16e when 16 is absent" \
    "platform=iOS Simulator,name=iPhone 16e" "$RESULT"
assert_ne "does not select nonexistent iPhone 16" \
    "platform=iOS Simulator,name=iPhone 16" "$RESULT"

# Test 3: fallback to first available iOS simulator
echo "Test 3: Fallback to first available simulator"
FAKE_DEVICES="-- iOS 18.0 --
    iPad mini (A0A0A0A0-1111-2222-3333-444444444444) (Shutdown)
    iPhone 15 (BBBB2222-3333-4444-5555-666666666666) (Shutdown)"
RESULT=$(run_selector "$FAKE_DEVICES")
assert_eq "falls back to first available iOS simulator" \
    "platform=iOS Simulator,name=iPad mini" "$RESULT"

# Test 4: preserve names with parentheses in model string
echo "Test 4: Preserves full iPad names"
FAKE_DEVICES="-- iOS 18.0 --
    iPad Air 11-inch (M3) (AAAA1111-2222-3333-4444-555555555555) (Shutdown)
    iPad Pro 13-inch (M5) (BBBB2222-3333-4444-5555-666666666666) (Shutdown)"
RESULT=$(run_selector "$FAKE_DEVICES")
assert_eq "keeps chip suffix in simulator name" \
    "platform=iOS Simulator,name=iPad Air 11-inch (M3)" "$RESULT"

# Test 5: no iOS simulators returns error
echo "Test 5: No iOS simulators"
FAKE_DEVICES="-- tvOS 18.0 --
    Apple TV (AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE) (Shutdown)"
RESULT=$(run_selector "$FAKE_DEVICES")
EXIT_CODE=$?
assert_eq "returns empty when no iOS simulators" "" "$RESULT"
assert_eq "returns error exit code" "1" "$EXIT_CODE"

# Test 6: real local list integration
echo "Test 6: Real device list integration"
REAL_DEVICES=$(xcrun simctl list devices available 2>/dev/null || echo "")
if [[ -n "$REAL_DEVICES" ]]; then
    RESULT=$(run_selector "$REAL_DEVICES")
    assert_not_empty "selects a simulator from real device list" "$RESULT"
else
    echo "  SKIP: No simulators on this machine"
fi

echo ""
echo "────────────────────────────────────────"
echo "  Results: $PASS passed, $FAIL failed"
echo "────────────────────────────────────────"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
