## Better QuickLook (Video)

Menu bar replacement for macOS video Quick Look: press **Space** in Finder and play the selection in a custom window with left/right arrow skipping. Uses AVKit by default and can take advantage of `VLCKit` when you add it for broader codec support.

### Features
- Spacebar in Finder opens the selected video in the custom player instead of the native preview (requires Accessibility permission for the key tap).
- Arrow keys skip forward/backward; skip duration is configurable (defaults to 5s).
- Menu bar item with quick actions and a Settings pane (`⌘,`) to adjust skip length.
- Falls back to AVKit playback; if `VLCKit` is available it will automatically prefer that engine.

### Build & Run
From the project root:

```bash
swift run
```

The compiled binary lives at `.build/debug/VideoPreview`. Run it to keep the app in your menu bar. The first run will prompt for Accessibility permission (System Settings → Privacy & Security → Accessibility); approve Terminal (if running via `swift run`) or the built app so keystroke interception works.

### Packaging as an app bundle (optional)
For a distributable bundle, you can:
1) Build release: `swift build -c release`
2) Create `VideoPreview.app/Contents/MacOS/VideoPreview` and copy the release binary there.
3) Add an `Info.plist` if you need custom metadata (bundle id, icon, etc.).

### Using VLCKit for all codecs
The code is written to use `VLCKit` when it is present (`canImport(VLCKit)`), otherwise it uses AVKit. To enable VLC-grade codec coverage:
1) Download `VLCKit.xcframework` for macOS from Videolan.
2) Create `Frameworks/VLCKit.xcframework` in this repo and place the download there.
3) In `Package.swift`, uncomment the `binaryTarget` for `VLCKit` and add `dependencies: ["VLCKit"]` to the `VideoPreview` target.

Rebuild; the VLC engine will be chosen automatically.

### Controls
- Space (in Finder): open preview for the selected video.
- Space (in the player window): play/pause.
- Left/Right arrow: skip backward/forward by the configured duration.
- Escape: close the player window.
