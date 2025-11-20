import AppKit
import SwiftUI
import AVFoundation
import Combine

/// Floating, non-activating panel that stays above Finder without stealing focus.
@MainActor
final class PlayerWindowController: NSWindowController, NSWindowDelegate {
    private let settings: SettingsStore
    private let engine: PlayerEngine
    private let hostingController: NSHostingController<PlayerContainerView>
    private var currentVideoSize: CGSize?
    private var currentFileName: String?
    private var cancellables = Set<AnyCancellable>()

    init(settings: SettingsStore, preferVLC: Bool) {
        self.settings = settings
        engine = PlayerEngineFactory.make(preferVLC: preferVLC)
        hostingController = NSHostingController(rootView: PlayerContainerView(engine: engine, settings: settings, fileName: nil))

        let panel = PlayerPanel(contentViewController: hostingController)
        panel.setContentSize(NSSize(width: 960, height: 540))
        panel.isReleasedWhenClosed = false
        panel.level = .statusBar
        panel.collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        super.init(window: panel)
        panel.delegate = self

        settings.$fillWindowAspect
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fill in
                guard let self else { return }
                self.engine.setFillWindowAspect(fill)
                // When turning stretch off, snap window back to video aspect if available.
                if !fill {
                    let size = self.currentVideoSize ?? self.engine.currentPresentationSize
                    if let size {
                        self.currentVideoSize = size
                        self.resizeForVideo(size, force: true)
                    }
                    self.updateAspectLock()
                }
            }
            .store(in: &cancellables)

        settings.$lockAspectRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAspectLock()
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isVisible: Bool { window?.isVisible ?? false }

    func show(url: URL) {
        currentFileName = url.lastPathComponent
        engine.load(url: url)
        engine.setFillWindowAspect(settings.fillWindowAspect)
        window?.center()
        orderFront()
        Task { [weak self] in
            guard let self else { return }
            if let size = await self.naturalSize(for: url) {
                self.currentVideoSize = size
                self.resizeForVideo(size)
                self.updateAspectLock()
            }
        }
    }

    func togglePlayPause() { engine.togglePlayPause() }
    func skipForward() { engine.skip(by: settings.skipInterval) }
    func skipBackward() { engine.skip(by: -settings.skipInterval) }

    func closePreview() {
        engine.pause()
        window?.orderOut(nil)
    }

    func windowWillClose(_ notification: Notification) {
        engine.pause()
    }

    private func orderFront() {
        if let panel = window as? NSPanel {
            panel.orderFrontRegardless()
        } else {
            window?.orderFrontRegardless()
        }
    }

    private func clamp(size: CGSize, toFit ratio: CGFloat, minSize: CGSize) -> CGSize {
        guard let screen = NSScreen.main else { return size }
        let maxWidth = screen.visibleFrame.width * ratio
        let maxHeight = screen.visibleFrame.height * ratio
        let widthRatio = maxWidth / size.width
        let heightRatio = maxHeight / size.height
        let scale = min(widthRatio, heightRatio, 1.0)
        let scaled = CGSize(width: max(size.width * scale, minSize.width), height: max(size.height * scale, minSize.height))
        return scaled
    }

    private func naturalSize(for url: URL) async -> CGSize? {
        let asset = AVURLAsset(url: url)
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let track = tracks.first else { return nil }
            let size = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let transformed = CGSizeApplyAffineTransform(size, transform)
            return CGSize(width: abs(transformed.width), height: abs(transformed.height))
        } catch {
            return nil
        }
    }

    private func resizeForVideo(_ size: CGSize, force: Bool = false) {
        guard (settings.matchVideoSizeOnOpen || force), let window else { return }
        let clamped = clamp(size: size, toFit: 0.9, minSize: CGSize(width: 320, height: 180))
        let contentRect = NSRect(origin: .zero, size: clamped)
        let frameRect = window.frameRect(forContentRect: contentRect)
        let origin = NSPoint(
            x: window.frame.midX - frameRect.width / 2,
            y: window.frame.midY - frameRect.height / 2
        )
        let frame = NSRect(origin: origin, size: frameRect.size)
        window.setFrame(frame, display: true, animate: true)
        hostingController.rootView.fileName = currentFileName
    }

    private func updateAspectLock() {
        guard let window else { return }
        let aspectSize = currentVideoSize ?? engine.currentPresentationSize
        if settings.lockAspectRatio, let size = aspectSize, size.width > 0, size.height > 0 {
            window.contentAspectRatio = size
        } else {
            window.contentAspectRatio = NSSize(width: 1, height: 1)
        }
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        guard settings.lockAspectRatio, let size = currentVideoSize, size.width > 0, size.height > 0 else {
            return frameSize
        }
        let ratio = size.width / size.height
        let proposedRatio = frameSize.width / frameSize.height
        if proposedRatio > ratio {
            return NSSize(width: frameSize.height * ratio, height: frameSize.height)
        } else {
            return NSSize(width: frameSize.width, height: frameSize.width / ratio)
        }
    }
}

private final class PlayerPanel: NSPanel {
    init(contentViewController: NSViewController) {
        let style: NSWindow.StyleMask = [.nonactivatingPanel, .fullSizeContentView, .titled, .resizable]
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 540),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        hasShadow = true
        self.contentViewController = contentViewController
        backgroundColor = .clear
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        standardWindowButton(.toolbarButton)?.isHidden = true
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
