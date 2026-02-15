#!/bin/sh

set -e

# Dynamic simulator discovery using python3 (ships with macOS)
pick_simulator() {
  xcrun simctl list devices available --json 2>/dev/null | python3 -c "
import json, sys
preferred = sys.argv[1:]
data = json.load(sys.stdin)
found = {}
fallback = None
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    for d in devices:
        if not d.get('isAvailable', False):
            continue
        name = d['name']
        if name in preferred:
            found[name] = name
        if fallback is None and 'iPhone' in name:
            fallback = name
for p in preferred:
    if p in found:
        print(p)
        sys.exit(0)
if fallback:
    print(fallback)
    sys.exit(0)
sys.exit(1)
" "iPhone 17 Pro" "iPhone 17" "iPhone 16e"
}

SIMULATOR=$(pick_simulator) || {
  echo "Error: No available iOS Simulator found." >&2
  echo "Install a simulator via Xcode > Settings > Platforms." >&2
  exit 1
}

DESTINATION="platform=iOS Simulator,name=${SIMULATOR}"

echo "Running Inyon tests..."
echo "Simulator: ${SIMULATOR}"
echo "Destination: ${DESTINATION}"
echo ""

if xcodebuild test \
  -scheme Inyon \
  -destination "${DESTINATION}" \
  -quiet; then
  echo "All tests passed"
else
  echo "Tests failed" >&2
  exit 1
fi
