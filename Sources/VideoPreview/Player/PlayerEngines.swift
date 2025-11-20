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
        // .resize stretches to window shape; .resizeAspect preserves aspect.
        playerView.videoGravity = fill ? .resize : .resizeAspect
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
        // For VLCKit, aspect ratio is managed by the view/player; leave default (aspect) unless stretching is requested.
        // VLCKit macOS does not expose a direct stretch toggle; keep default behavior.
    }

    func seek(to seconds: Double) {
        let millis = Int32(max(0, seconds * 1000))
        mediaPlayer.time = VLCTime(int: millis)
    }
}
#endif

enum PlayerEngineFactory {
    @MainActor
    static func make(preferVLC: Bool) -> PlayerEngine {
        #if canImport(VLCKit)
        if preferVLC { return VLCPlayerEngine() }
        #endif
        return AVPlayerEngine()
    }
}
