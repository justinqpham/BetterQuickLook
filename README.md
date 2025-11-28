## Better QuickLook

Better QuickLook replaces the built-in macOS Quick Look for videos with a smarter menu bar player. Hit **Space** in Finder to open videos instantly, skip with arrow keys, and play any video format with VLCKit's comprehensive codec support.

### Features
- Spacebar in Finder opens the selected video via our player (Accessibility permission required for key interception).
- Non-video files fall back to macOS Quick Look; spacebar interception is video-only.
- Arrow keys skip forward/backward; skip duration is configurable (1–30s).
- Menu bar toggles for: match video size on open, lock aspect ratio, and fit video to window shape.
- Universal codec support: plays all video formats using VLCKit (H.264, HEVC, AV1, VP9, VP8, MPEG-4, etc.).
- Supports all containers: MP4, MOV, MKV, WebM, AVI, MPEG, WMV, FLV, and more.
- Player stays non-activating so Finder remains active—navigate up/down in Finder to auto-update the preview.

### Build & Run

**Important**: If you clean `.build`, bootstrap VLCKit once, then `swift run` works normally.

From the project root:
```bash
# Stage VLCKit (only needed after a clean)
./Scripts/bootstrap-vlckit.sh

# Run the application
swift run
```

First run: grant Accessibility in System Settings → Privacy & Security → Accessibility for Terminal (or the built app) so the space/arrow intercept works.

Release binary:
```bash
swift build -c release
mkdir -p .build/release/Frameworks
cp -R Frameworks/VLCKit.xcframework/macos-arm64_x86_64/VLCKit.framework .build/release/Frameworks/
.build/release/BetterQuickLook
```

**Note**: The VLCKit framework must be present in `Frameworks/VLCKit.xcframework`. The app uses VLCKit for all video playback to ensure universal codec support.

### Package the .app bundle

Create a standalone `BetterQuickLook.app` in the project root:

```bash
swift build -c release

APP_NAME="BetterQuickLook.app"
rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/Contents/MacOS" "$APP_NAME/Contents/Frameworks" "$APP_NAME/Contents/Resources"

cp .build/release/BetterQuickLook "$APP_NAME/Contents/MacOS/BetterQuickLook"
cp -R Frameworks/VLCKit.xcframework/macos-arm64_x86_64/VLCKit.framework "$APP_NAME/Contents/Frameworks/"
cp -R .build/arm64-apple-macosx/release/BetterQuickLook_BetterQuickLook.bundle "$APP_NAME/Contents/Resources/"
cp Sources/BetterQuickLook/Resources/BetterQuickLookAppIcon.png "$APP_NAME/Contents/Resources/"
cp Sources/BetterQuickLook/Resources/BetterQuickLookMenuBarIcon.png "$APP_NAME/Contents/Resources/"

cat > "$APP_NAME/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Better QuickLook</string>
    <key>CFBundleDisplayName</key>
    <string>Better QuickLook</string>
    <key>CFBundleIdentifier</key>
    <string>com.justinqpham.BetterQuickLook</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>BetterQuickLook</string>
    <key>CFBundleIconFile</key>
    <string>BetterQuickLookAppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAccessibilityUsageDescription</key>
    <string>Better QuickLook needs Accessibility access to intercept the spacebar key to open video previews.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Better QuickLook needs access to Finder to read the current selection for preview.</string>
</dict>
</plist>
EOF

# Generate app icon
mkdir -p /tmp/icon.iconset
for size in 16 32 128 256 512; do
  sips -z $size $size Sources/BetterQuickLook/Resources/BetterQuickLookAppIcon.png --out /tmp/icon.iconset/icon_${size}x${size}.png
  sips -z $((size*2)) $((size*2)) Sources/BetterQuickLook/Resources/BetterQuickLookAppIcon.png --out /tmp/icon.iconset/icon_${size}x${size}@2x.png
done
iconutil -c icns /tmp/icon.iconset -o "$APP_NAME/Contents/Resources/BetterQuickLookAppIcon.icns"

# Code sign
codesign --force --deep --sign - "$APP_NAME"
```

Open with `open BetterQuickLook.app`. (Bundle is unsigned; right-click → Open once if Gatekeeper prompts.)

### Troubleshooting
- **Packaged app doesn’t intercept Space** – macOS occasionally drops Accessibility permission when you rebuild the bundle. Remove Better QuickLook from System Settings → Privacy & Security → Accessibility, add it again, and relaunch the app.
- **Packaged app doesn’t request Finder control (Automation)** – run `tccutil reset AppleEvents com.justinqpham.BetterQuickLook`, launch the app, press Space in Finder, and click OK on the Finder-control prompt so it reappears under System Settings → Privacy & Security → Automation.
- **`swift run`/`swift build` complain about missing VLCKit headers** – delete `.build`, then run `./Scripts/bootstrap-vlckit.sh` to restage the framework before launching.

### Controls
- Space (Finder): open/close preview for the selected video.
- Space (player): play/pause.
- Left / Right: skip backward / forward by your configured duration.
- Escape: close the player window.

### Settings
- **Skip duration** (1–30s) - Configure how many seconds to skip with arrow keys.
- **Match video size on open** - Window automatically sizes to match video dimensions.
- **Lock aspect ratio** - Maintain video aspect ratio while resizing window.
- **Fit video to window shape** - Stretch video to fill window (may distort).

### VLCKit Integration

- **Universal codec support**
  - Plays all video codecs: H.264, HEVC, AV1, VP9, VP8, MPEG-4 Part 2, MPEG-2, and more
  - Supports all container formats: MP4, MOV, MKV, WebM, AVI, MPEG, WMV, FLV, and more
  - No transcoding - instant playback for any format

- **Size optimized**
  - VLCKit trimmed from 310MB to 35MB (88% reduction)
  - ARM64-only build (no x86_64 bloat)
  - Debug symbols removed (dSYMs stripped)

- **Custom player controls**
  - Overlay controls for play/pause, seek, and skip
  - Keyboard shortcuts fully supported
  - Window sizing and aspect ratio controls
