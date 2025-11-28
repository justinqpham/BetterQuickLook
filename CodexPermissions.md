## Codex Permission Troubleshooting Log

This document records everything I (Codex) attempted while trying to get the packaged `BetterQuickLook.app` and Xcode builds to intercept the Finder spacebar shortcut. Every time we rebuild or relocate the bundle, macOS treats it as a new app, so both Accessibility and Automation permissions must be re‑granted. Below is a chronological log of what I did, what failed, and how the issue was finally resolved.

---

### 2025‑11‑22 — Initial resets after repackaging
1. Repackaged the app (`swift build -c release`, rebuild `.app`).
2. Advised running `tccutil reset Accessibility/AppleEvents com.justinqpham.BetterQuickLook`.
3. User reported the packaged app still launched native Quick Look → Automation permission hadn’t been granted.

### 2025‑11‑23 14:42 PT — `swift run` works, packaged app fails
1. `swift run` produced audio/video correctly.
2. Packaged app did not intercept Space.
3. Suggested running `./Scripts/bootstrap-vlckit.sh` to restage VLCKit, then `swift run`.

### 2025‑11‑23 15:19 PT — `swift run` works after restaging
1. Verified `swift run` launched and worked (log line `creating player instance using shared library`).
2. Packaged app still failed to intercept Space → suspected Automation permission not recorded.

### 2025‑11‑23 15:53 PT — Collected TCC logs
1. Ran `log show --predicate 'process == "BetterQuickLook"'`.
2. Logs showed `tccd` prompting for Finder control (“Prompting for access to indirect object Finder by BetterQuickLook”).
3. Determined user had clicked “Don’t Allow” earlier; the permission was denied and persisted.

### 2025‑11‑23 15:56 PT — Forced permission re‑prompt
1. Instructed user to quit the app.
2. Ran `tccutil reset Accessibility com.justinqpham.BetterQuickLook` and `tccutil reset AppleEvents com.justinqpham.BetterQuickLook`.
3. Relaunch → press Space in Finder → click OK on both prompts. Packaged app worked again.

### 2025‑11‑23 17:36 PT — Repackaged after filename auto-hide work
1. Added filename auto-hide timer (modified `PlayerContainerView.swift`).
2. Rebuilt release, re-created `BetterQuickLook.app`.
3. Packaging script removed the old bundle, so macOS treated it as a new app.
4. User repeated the permission steps; Automation prompt appeared; app resumed intercepting Space.

### Accessory Attempts (failed)
- Trying to run `log show --predicate 'subsystem == "com.apple.TCC"'` initially failed with “too many arguments” because the command lacked the `/usr/bin/log` prefix and proper quoting; had to use `/usr/bin/log show --style syslog --last …`.
- Several `tccutil reset` commands failed because they were executed without specifying the sandbox `workdir`, yielding “No such file or directory.”
- Suggested manually removing entries under System Settings → Accessibility / Automation when `tccutil` failed to prompt.
- Xcode builds (DerivedData path) behaved like the packaged `.app`; same permission steps required for each path.

---

### Key Lessons
1. **Automation permission is essential.** Without Finder control, native Quick Look always wins.
2. **Every new bundle path needs permission.** Repackaging or building via Xcode creates a new path/signature; macOS revokes Automation each time.
3. **`tccutil reset` alone isn’t enough.** After resetting, the app must request Finder control while Finder is frontmost, or the Automation prompt never appears.
4. **Logs confirm the cause.** `log show --predicate 'subsystem == "com.apple.TCC"' --last 2m` confirms whether macOS is prompting, denying, or ignoring the request.

Use this log to understand why the packaged app sometimes “does nothing” after a rebuild: Automation and Accessibility must be re‑granted every single time the app bundle changes.
