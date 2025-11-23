#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build/arm64-apple-macosx"
# Build first (swift may clean .build) then stage VLCKit where both the compiler and dyld expect it.
swift build
mkdir -p "$BUILD_DIR/Frameworks" "$BUILD_DIR/debug"
cp -R -X "$ROOT/Frameworks/VLCKit.xcframework/macos-arm64_x86_64/VLCKit.framework" "$BUILD_DIR/Frameworks/"
cp -R -X "$ROOT/Frameworks/VLCKit.xcframework/macos-arm64_x86_64/VLCKit.framework" "$BUILD_DIR/debug/"
