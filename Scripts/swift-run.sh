#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRAMEWORK_DST="$ROOT/.build/arm64-apple-macosx/Frameworks"
FRAMEWORK_SRC="$ROOT/Frameworks/VLCKit.xcframework/macos-arm64_x86_64/VLCKit.framework"

# Stage VLCKit for both compiler (debug) and dyld locations
mkdir -p "$FRAMEWORK_DST" "$ROOT/.build/arm64-apple-macosx/debug"
cp -R -X "$FRAMEWORK_SRC" "$FRAMEWORK_DST/"
cp -R -X "$FRAMEWORK_SRC" "$ROOT/.build/arm64-apple-macosx/debug/"

cd "$ROOT"
exec swift run "$@"
