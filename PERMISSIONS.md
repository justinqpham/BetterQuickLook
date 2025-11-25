## Permissions Troubleshooting

Better QuickLook needs two macOS permissions every time you rebuild or repackage the app. Without both, the packaged `.app` or an Xcode build launches but Finder continues to show native Quick Look.

### 1. Accessibility (Spacebar interception)
1. Quit Better QuickLook.
2. Reset permission so macOS prompts again:
   ```bash
   tccutil reset Accessibility com.justinqpham.BetterQuickLook
   ```
   If that fails, run `tccutil reset Accessibility` to reset globally.
3. Launch `BetterQuickLook.app`. When prompted “Better QuickLook wants to control your computer,” click **OK**.
4. Verify in **System Settings → Privacy & Security → Accessibility** that Better QuickLook is present and checked. If not, click `+`, add the app manually, and enable it.

### 2. Automation / Finder control (Apple Events)
1. Ensure Finder is frontmost (click its window).
2. Press **Space** once. macOS should show “Better QuickLook wants to control Finder.” Click **OK**.
3. If the prompt never appears, remove any stale entry under **System Settings → Privacy & Security → Automation** (unlock → select Better QuickLook → `–`), then run:
   ```bash
   tccutil reset AppleEvents com.justinqpham.BetterQuickLook
   ```
   Relaunch the app, make Finder active, and press Space again.

When both toggles are enabled (Accessibility + Automation), the packaged app intercepts Space and the Finder window no longer opens native Quick Look. Each time you rebuild or replace `BetterQuickLook.app`, repeat these steps to grant permissions to the new bundle path.
