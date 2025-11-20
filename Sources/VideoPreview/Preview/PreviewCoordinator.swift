import AppKit
import Combine

@MainActor
final class PreviewCoordinator {
    private let settings: SettingsStore
    private let selectionMonitor: FinderSelectionMonitor
    private var playerWindowController: PlayerWindowController
    private var settingsCancellable: AnyCancellable?
    private var lastURL: URL?
    private var isMonitoringSelection = false

    init(settings: SettingsStore, selectionMonitor: FinderSelectionMonitor) {
        self.settings = settings
        self.selectionMonitor = selectionMonitor
        self.playerWindowController = PlayerWindowController(settings: settings, preferVLC: settings.preferVLCEngine)
        settingsCancellable = settings.$preferVLCEngine
            .removeDuplicates()
            .sink { [weak self] prefer in
                self?.rebuildPlayer(preferVLC: prefer)
            }
    }

    var isPreviewVisible: Bool {
        playerWindowController.isVisible
    }

    func presentPreview(for url: URL) {
        lastURL = url
        playerWindowController.show(url: url)
        startMonitoringSelection()
    }

    func togglePlayPause() {
        playerWindowController.togglePlayPause()
    }

    func skipForward() {
        playerWindowController.skipForward()
    }

    func skipBackward() {
        playerWindowController.skipBackward()
    }

    func closePreview() {
        lastURL = nil
        stopMonitoringSelection()
        playerWindowController.closePreview()
    }

    private func startMonitoringSelection() {
        guard !isMonitoringSelection else { return }
        isMonitoringSelection = true
        selectionMonitor.start { [weak self] url in
            guard let self else { return }
            if let url {
                self.playerWindowController.show(url: url)
            } else {
                self.closePreview()
            }
        }
    }

    private func stopMonitoringSelection() {
        selectionMonitor.stop()
        isMonitoringSelection = false
    }

    private func rebuildPlayer(preferVLC: Bool) {
        let wasVisible = playerWindowController.isVisible
        playerWindowController.closePreview()
        playerWindowController = PlayerWindowController(settings: settings, preferVLC: preferVLC)
        if wasVisible, let url = lastURL {
            playerWindowController.show(url: url)
        }
    }
}
