## Better QuickLook

Better QuickLook replaces the built-in macOS Quick Look for videos with a smarter menu bar player. Hit **Space** in Finder to open videos instantly, skip with arrow keys, and optionally use VLCKit for full codec coverage while keeping familiar controls.

### Features
- Spacebar in Finder opens the selected video via our player (Accessibility permission required for key interception).
- Arrow keys skip forward/backward; skip duration is configurable (1–30s).
- Menu bar toggles for: match video size on open, lock aspect ratio, fit video to window shape, and prefer VLC playback.
- AVKit by default (native controls). If VLCKit is present and enabled, builds use VLC codecs with a custom overlay.
- Player stays non-activating so Finder remains active—navigate up/down in Finder to auto-update the preview.

### Build & Run
From the project root:
```bash
swift run
```
First run: grant Accessibility in System Settings → Privacy & Security → Accessibility for Terminal (or the built app) so the space/arrow intercept works.

Release binary:
```bash
swift build -c release
```
Binary will be at `.build/release/BetterQuickLook`.

### Enabling VLCKit (full codecs)
1. Copy `VLCKit.xcframework` into `Frameworks/VLCKit.xcframework`.
   - Use the macOS slice (e.g., `macos-arm64_x86_64` inside the xcframework) if you need to place the framework at runtime under `.build/arm64-apple-macosx/Frameworks/`.
2. Ensure `Package.swift` has:
   ```swift
   .binaryTarget(name: "VLCKit", path: "Frameworks/VLCKit.xcframework"),
   .executableTarget(name: "VideoPreview", dependencies: ["VLCKit"])
   ```
3. Build/run: `swift run`
4. In the app Settings or menu toggles, turn on “Prefer VLC playback” to activate VLC + custom controls.

### Controls
- Space (Finder): open/close preview for the selected video.
- Space (player): play/pause.
- Left / Right: skip backward / forward by your configured duration.
- Escape: close the player window.

### Settings (menu or window)
- Skip duration (1–30s).
- Match video size on open.
- Lock aspect ratio while resizing.
- Fit video to window shape.
- Prefer VLC playback.

### Notes
- With VLC enabled, controls are provided by a custom overlay (since VLCKit lacks native macOS controls). With VLC off, AVKit’s native control bar is used.
- If you see a runtime load error for VLCKit, ensure the framework is available at `Frameworks/VLCKit.xcframework` and, for local runs, that the macOS slice is copied under `.build/arm64-apple-macosx/Frameworks/VLCKit.framework`.
