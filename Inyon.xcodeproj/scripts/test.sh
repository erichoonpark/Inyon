#!/bin/bash

echo "Running Inyon tests..."

xcodebuild test \
  -scheme Inyon \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet

if [ $? -eq 0 ]; then
  echo "✅ All tests passed"
else
  echo "❌ Tests failed"
  exit 1
fi