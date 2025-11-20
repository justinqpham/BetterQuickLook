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

### Codec support and known issues

- **AVKit (default)**  
  - Plays: H.264/HEVC in MP4/MOV, AAC/MP3, and most “normal” Apple formats.  
  - Does *not* reliably play: AV1, VP8/VP9, older MPEG‑4 Part 2/MPEG‑2, or some MKV/WebM/AVI containers.

- **VLCKit (optional, full coverage)**  
  - When configured, the app can use VLCKit as a secondary engine for “Prefer VLC playback”.  
  - This brings most of VLC’s codec support, but with a custom overlay instead of native AVKit controls.  
  - Known friction: you must manually place the VLCKit framework slice under `.build/arm64-apple-macosx/Frameworks/VLCKit.framework/` for `swift run` to work, because SwiftPM doesn’t manage that at runtime.

- **Minimal FFmpeg fallback (experimental)**  
  - The `ffmpeg-lite` branch adds a minimal ffmpeg build and a fallback transcoder:
    - `Scripts/build_ffmpeg_minimal.sh` builds a small static ffmpeg.  
    - Copy the resulting binary to `Sources/VideoPreview/Resources/ffmpeg/ffmpeg`.  
    - On launch, the app stages it to `~/Library/Caches/BetterQuickLook/ffmpeg/ffmpeg`, strips the `com.apple.quarantine` flag, marks it executable, and then uses it to transcode unsupported inputs (MKV/WebM/AVI, AV1/VPx/MPEG‑4/Opus/FLAC) to temporary MP4 files before passing them to AVKit.
  - **Current issue:** On some systems (including this development setup), launching the staged ffmpeg via `Process` still intermittently fails with `POSIXErrorCode.EACCES` (`Permission denied`), even after removing quarantine and setting `chmod 755`. When that happens:
    - Logs show “Failed to launch ffmpeg: The operation couldn’t be completed. Permission denied”.
    - No transcoded file is written to `~/Library/Caches/BetterQuickLook/Transcodes`.
    - The app silently falls back to the original file, so AV1/MPEG‑4 gap formats still do not play.
  - Root cause (suspected): macOS security/runtime constraints around executing an embedded third‑party binary (code signing, quarantine, and execution from certain locations). A robust fix likely requires:
    - Shipping a signed, embedded helper tool or  
    - Moving to a framework-based integration like FFmpegKit that handles signing/packaging.

- **Recommended today**  
  - For maximum reliability, use AVKit for Apple‑native formats and add VLCKit for “everything else”.  
  - Treat the ffmpeg fallback as experimental; it is wired in but not yet reliable for AV1/MPEG‑4 on all setups.
