import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var shortcutMonitor: ShortcutMonitor?
    private var previewCoordinator: PreviewCoordinator?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let settings = SettingsStore.shared
        let selectionProvider = FinderSelectionProvider()
        let selectionMonitor = FinderSelectionMonitor(provider: selectionProvider)

        previewCoordinator = PreviewCoordinator(settings: settings, selectionMonitor: selectionMonitor)
        settingsWindowController = SettingsWindowController(settings: settings)

        if let previewCoordinator {
            shortcutMonitor = ShortcutMonitor(
                selectionProvider: selectionProvider,
                isPreviewVisible: { previewCoordinator.isPreviewVisible },
                onOpenSelection: { [weak self] url in self?.previewCoordinator?.presentPreview(for: url) },
                onCloseSelection: { [weak self] in self?.previewCoordinator?.closePreview() },
                onSkipBack: { [weak self] in self?.previewCoordinator?.skipBackward() },
                onSkipForward: { [weak self] in self?.previewCoordinator?.skipForward() }
            )
            shortcutMonitor?.start()
        }

        menuBarController = MenuBarController(
            settings: settings,
            onOpenPreferences: { [weak self] in self?.settingsWindowController?.show() },
            onQuit: { NSApp.terminate(nil) },
            onTogglePreview: { [weak self] in self?.previewCoordinator?.togglePlayPause() }
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        shortcutMonitor?.stop()
    }
}
