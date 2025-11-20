import Foundation

/// Polls Finder selection while preview is shown so the player can follow selection changes.
@MainActor
final class FinderSelectionMonitor {
    private let provider: FinderSelectionProvider
    private var timer: Timer?
    private var lastURL: URL?
    private var onChange: ((URL?) -> Void)?

    init(provider: FinderSelectionProvider) {
        self.provider = provider
    }

    func start(onChange: @escaping (URL?) -> Void) {
        stop()
        self.onChange = onChange
        lastURL = provider.firstVideoURL()
        let timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(checkSelection), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onChange = nil
        lastURL = nil
    }

    @objc private func checkSelection() {
        let url = provider.firstVideoURL()
        if url?.absoluteURL != lastURL?.absoluteURL {
            lastURL = url
            onChange?(url)
        }
    }
}
