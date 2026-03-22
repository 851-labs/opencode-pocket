#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PACKAGE_DIR/.build/debug"
TEST_BUNDLE="$BUILD_DIR/OpenCodeSDKPackageTests.xctest"
TEST_BINARY="$TEST_BUNDLE/Contents/MacOS/OpenCodeSDKPackageTests"
PROFDATA="$BUILD_DIR/codecov/default.profdata"
SOURCE_DIR="$PACKAGE_DIR/Sources/OpenCodeSDK"

cd "$PACKAGE_DIR"

swift test --enable-code-coverage

if [[ ! -f "$TEST_BINARY" ]]; then
  echo "error: missing test binary at $TEST_BINARY" >&2
  exit 1
fi

if [[ ! -f "$PROFDATA" ]]; then
  echo "error: missing coverage profile at $PROFDATA" >&2
  exit 1
fi

xcrun llvm-cov report "$TEST_BINARY" \
  -instr-profile "$PROFDATA" \
  "$SOURCE_DIR"
