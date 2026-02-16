#!/bin/bash
# ──────────────────────────────────────────────────────────────
# prepush_hook_tests.sh
#
# Tests for the simulator selection logic used by pre-push hook.
# Verifies that when the preferred simulator (iPhone 16) is
# missing, the first available simulator is selected.
#
# Run: bash scripts/prepush_hook_tests.sh
# ──────────────────────────────────────────────────────────────

set -uo pipefail

PASS=0
FAIL=0

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

# ── Simulator selection function (extracted from pre-push hook) ──

select_simulator() {
    local device_list="$1"
    local DESTINATION=""

    if echo "$device_list" | grep -q "iPhone 16"; then
        DESTINATION="platform=iOS Simulator,name=iPhone 16"
    else
        local FIRST_SIM
        FIRST_SIM=$(echo "$device_list" \
            | grep -E '^\s+.+\(' \
            | head -1 \
            | sed 's/^[[:space:]]*//' \
            | sed 's/ ([0-9A-F]\{8\}-.*//')

        if [[ -z "$FIRST_SIM" ]]; then
            echo ""
            return 1
        fi
        DESTINATION="platform=iOS Simulator,name=$FIRST_SIM"
    fi

    echo "$DESTINATION"
    return 0
}

# ── Tests ────────────────────────────────────────────────────────

echo ""
echo "test_prePushSimulatorSelection_choosesFirstAvailable_whenPreferredMissing"
echo ""

# Test 1: iPhone 16 present → selects iPhone 16
echo "Test 1: Preferred simulator available"
FAKE_DEVICES="-- iOS 18.0 --
    iPhone 16 (AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE) (Booted)
    iPhone 16 Pro (11111111-2222-3333-4444-555555555555) (Shutdown)"
RESULT=$(select_simulator "$FAKE_DEVICES")
assert_eq "selects iPhone 16 when present" \
    "platform=iOS Simulator,name=iPhone 16" "$RESULT"

# Test 2: iPhone 16 missing → selects first available
echo "Test 2: Preferred missing, falls back to first available"
FAKE_DEVICES="-- iOS 18.0 --
    iPhone 17 Pro (AAAA1111-2222-3333-4444-555555555555) (Shutdown)
    iPad Air (BBBB2222-3333-4444-5555-666666666666) (Shutdown)"
RESULT=$(select_simulator "$FAKE_DEVICES")
assert_eq "falls back to first available simulator" \
    "platform=iOS Simulator,name=iPhone 17 Pro" "$RESULT"

# Test 3: No simulators at all → returns empty and error
echo "Test 3: No simulators available"
FAKE_DEVICES=""
RESULT=$(select_simulator "$FAKE_DEVICES")
EXIT_CODE=$?
assert_eq "returns empty when no simulators" "" "$RESULT"
assert_eq "returns error exit code" "1" "$EXIT_CODE"

# Test 4: Only iPads with chip names in parens → preserves full name
echo "Test 4: Only iPad simulators with chip names"
FAKE_DEVICES="-- iOS 18.0 --
    iPad Air 11-inch (M3) (AAAA1111-2222-3333-4444-555555555555) (Shutdown)
    iPad Pro 13-inch (M5) (BBBB2222-3333-4444-5555-666666666666) (Shutdown)"
RESULT=$(select_simulator "$FAKE_DEVICES")
assert_eq "selects first iPad when no iPhones" \
    "platform=iOS Simulator,name=iPad Air 11-inch (M3)" "$RESULT"

# Test 5: Real device list from current machine (integration check)
echo "Test 5: Real device list integration"
REAL_DEVICES=$(xcrun simctl list devices available 2>/dev/null || echo "")
if [[ -n "$REAL_DEVICES" ]]; then
    RESULT=$(select_simulator "$REAL_DEVICES")
    assert_not_empty "selects a simulator from real device list" "$RESULT"
else
    echo "  SKIP: No simulators on this machine"
fi

# ── Summary ──────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────"
echo "  Results: $PASS passed, $FAIL failed"
echo "────────────────────────────────────────"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
