import AppKit
import Combine

@MainActor
final class PreviewCoordinator {
    private let settings: SettingsStore
    private let selectionMonitor: FinderSelectionMonitor
    private var playerWindowController: PlayerWindowController
    private var lastURL: URL?
    private var isMonitoringSelection = false
    private var isPlayerVisible = false

    init(settings: SettingsStore, selectionMonitor: FinderSelectionMonitor) {
        self.settings = settings
        self.selectionMonitor = selectionMonitor
        self.playerWindowController = PlayerWindowController(
            settings: settings,
            preferVLC: false,
            onRequestClose: nil
        )
        self.playerWindowController.onRequestClose = { [weak self] in
            self?.closePreview()
        }
    }

    var isPreviewVisible: Bool {
        isPlayerVisible
    }

    func presentPreview(for url: URL) {
        lastURL = url
        playerWindowController.show(url: url)
        isPlayerVisible = true
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
        guard isPlayerVisible else { return }
        lastURL = nil
        stopMonitoringSelection()
        playerWindowController.closePreview()
        isPlayerVisible = false
    }

    private func startMonitoringSelection() {
        guard !isMonitoringSelection else { return }
        isMonitoringSelection = true
        selectionMonitor.start { [weak self] url in
            guard let self else { return }
            if let url {
                self.playerWindowController.show(url: url)
                self.isPlayerVisible = true
            } else {
                self.closePreview()
            }
        }
    }

    private func stopMonitoringSelection() {
        selectionMonitor.stop()
        isMonitoringSelection = false
    }
}
