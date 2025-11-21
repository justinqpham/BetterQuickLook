## Better QuickLook

Better QuickLook replaces the built-in macOS Quick Look for videos with a smarter menu bar player. Hit **Space** in Finder to open videos instantly, skip with arrow keys, and play any video format with VLCKit's comprehensive codec support.

### Features
- Spacebar in Finder opens the selected video via our player (Accessibility permission required for key interception).
- Arrow keys skip forward/backward; skip duration is configurable (1–30s).
- Menu bar toggles for: match video size on open, lock aspect ratio, and fit video to window shape.
- Universal codec support: plays all video formats using VLCKit (H.264, HEVC, AV1, VP9, VP8, MPEG-4, etc.).
- Supports all containers: MP4, MOV, MKV, WebM, AVI, MPEG, WMV, FLV, and more.
- Player stays non-activating so Finder remains active—navigate up/down in Finder to auto-update the preview.

### Build & Run

**Important**: VLCKit framework requires a manual copy step for `swift run` to work properly.

From the project root:
```bash
# Copy VLCKit framework to the correct build location
mkdir -p .build/arm64-apple-macosx/Frameworks
cp -R Frameworks/VLCKit.xcframework/macos-arm64_x86_64/VLCKit.framework .build/arm64-apple-macosx/Frameworks/

# Run the application
swift run
```

First run: grant Accessibility in System Settings → Privacy & Security → Accessibility for Terminal (or the built app) so the space/arrow intercept works.

Release binary:
```bash
swift build -c release
mkdir -p .build/release/Frameworks
cp -R Frameworks/VLCKit.xcframework/macos-arm64_x86_64/VLCKit.framework .build/release/Frameworks/
.build/release/VideoPreview
```

**Note**: The VLCKit framework must be present in `Frameworks/VLCKit.xcframework`. The app uses VLCKit for all video playback to ensure universal codec support.

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
