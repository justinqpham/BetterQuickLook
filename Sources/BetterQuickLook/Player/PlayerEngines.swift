import AppKit
import AVFoundation
import AVKit

@MainActor
protocol PlayerEngine: AnyObject {
    var containerView: NSView { get }
    var currentPresentationSize: CGSize? { get }
    var usesNativeControls: Bool { get }
    var isPlaying: Bool { get }
    var currentTime: Double { get } // seconds
    var duration: Double? { get }
    func load(url: URL)
    func togglePlayPause()
    func pause()
    func skip(by seconds: Double)
    func setFillWindowAspect(_ fill: Bool)
    func seek(to seconds: Double)
}

final class AVPlayerEngine: NSObject, PlayerEngine {
    private let player = AVPlayer()
    private let playerView = AVPlayerView()

    override init() {
        super.init()
        playerView.player = player
        playerView.controlsStyle = .inline
        playerView.videoGravity = .resizeAspect
        playerView.showsFullScreenToggleButton = false
        playerView.showsTimecodes = true
        playerView.showsFrameSteppingButtons = false
        playerView.showsSharingServiceButton = false
        playerView.updatesNowPlayingInfoCenter = false
        playerView.allowsPictureInPicturePlayback = false
    }

    var containerView: NSView { playerView }
    var currentPresentationSize: CGSize? {
        player.currentItem?.presentationSize
    }
    var usesNativeControls: Bool { true }
    var isPlaying: Bool { player.timeControlStatus == .playing }
    var currentTime: Double { CMTimeGetSeconds(player.currentTime()) }
    var duration: Double? {
        guard let dur = player.currentItem?.duration, dur.isNumeric else { return nil }
        return CMTimeGetSeconds(dur)
    }

    func load(url: URL) {
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.play()
    }

    func togglePlayPause() {
        switch player.timeControlStatus {
        case .playing:
            player.pause()
        default:
            player.play()
        }
    }

    func pause() {
        player.pause()
    }

    func skip(by seconds: Double) {
        guard let currentItem = player.currentItem else { return }

        let currentSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(currentItem.duration)
        guard durationSeconds.isFinite else { return }

        let targetSeconds = max(0, min(durationSeconds, currentSeconds + seconds))
        let target = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        player.seek(to: target)
    }

    func setFillWindowAspect(_ fill: Bool) {
        // Fill crops to the window shape; off keeps aspect-fitted view.
        playerView.videoGravity = fill ? .resizeAspectFill : .resizeAspect
    }

    func seek(to seconds: Double) {
        let target = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: target)
    }
}

#if canImport(VLCKit)
import VLCKit

final class VLCPlayerEngine: NSObject, PlayerEngine {
    private let videoView = VLCVideoView()
    private let mediaPlayer = VLCMediaPlayer()
    private var frameObserver: Any?
    private var stretchToWindowShape = false
    private var aspectCString: UnsafeMutablePointer<Int8>?

    var currentPresentationSize: CGSize? {
        // VLCKit exposes videoSize but may be zero until playback starts; fallback to nil.
        let size = mediaPlayer.videoSize
        return size == .zero ? nil : size
    }
    var usesNativeControls: Bool { false }
    var isPlaying: Bool { mediaPlayer.isPlaying }
    var currentTime: Double {
        let t = mediaPlayer.time
        return Double(t.intValue) / 1000.0
    }
    var duration: Double? {
        guard let len = mediaPlayer.media?.length else { return nil }
        return Double(len.intValue) / 1000.0
    }

    override init() {
        super.init()
        mediaPlayer.drawable = videoView
        videoView.fillScreen = true
        videoView.postsFrameChangedNotifications = true
        frameObserver = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: videoView,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.applyFillMode()
            }
        }
        applyFillMode()
    }

    var containerView: NSView { videoView }

    func load(url: URL) {
        mediaPlayer.media = VLCMedia(url: url)
        mediaPlayer.play()
    }

    func togglePlayPause() {
        mediaPlayer.isPlaying ? mediaPlayer.pause() : mediaPlayer.play()
    }

    func pause() {
        mediaPlayer.pause()
    }

    func skip(by seconds: Double) {
        let delta = Int32(seconds)
        if delta >= 0 {
            mediaPlayer.jumpForward(delta)
        } else {
            mediaPlayer.jumpBackward(abs(delta))
        }
    }

    func setFillWindowAspect(_ fill: Bool) {
        stretchToWindowShape = fill
        applyFillMode()
    }

    func seek(to seconds: Double) {
        let millis = Int32(max(0, seconds * 1000))
        mediaPlayer.time = VLCTime(int: millis)
    }

    @MainActor
    deinit {
        if let observer = frameObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func applyFillMode() {
        mediaPlayer.videoAspectRatio = nil // reset to natural aspect
        mediaPlayer.scaleFactor = 0 // let VLC size to the drawable

        guard stretchToWindowShape else { return }
        let size = videoView.bounds.size
        guard size.width > 0, size.height > 0 else { return }
        let aspect = size.width / size.height
        let aspectString = String(format: "%.6f:1", aspect)
        aspectString.withCString { cString in
            mediaPlayer.videoAspectRatio = UnsafeMutablePointer(mutating: cString)
        }
    }
}
#endif

enum PlayerEngineFactory {
    @MainActor
    static func make(preferVLC: Bool) -> PlayerEngine {
        #if canImport(VLCKit)
        return VLCPlayerEngine()
        #else
        return AVPlayerEngine()
        #endif
    }
}
