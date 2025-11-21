import Foundation
import AVFoundation
import AudioToolbox
import OSLog
#if os(macOS)
import Darwin
#endif
#if canImport(CommonCrypto)
import CommonCrypto
#endif

@MainActor
final class FFmpegTranscoder {
    static let shared = FFmpegTranscoder()

    private let logger = Logger(subsystem: "BetterQuickLook", category: "FFmpegTranscoder")
    private let workQueue = DispatchQueue(label: "ffmpeg.transcoder.queue")
    private let cacheDirectory: URL
    private let ffmpegURL: URL?
    private let supportedExtensions: Set<String> = [
        "mkv", "webm", "avi", "mpg", "mpeg", "wmv", "flv", "ts", "movpkg"
    ]
    private let unsupportedVideoSubtypes: Set<FourCharCode> = [
        FourCharCode("av01"),
        FourCharCode("vp09"),
        FourCharCode("vp08"),
        kCMVideoCodecType_MPEG4Video,
        kCMVideoCodecType_MPEG2Video
    ]
    private let unsupportedAudioSubtypes: Set<UInt32> = [
        kAudioFormatOpus,
        kAudioFormatFLAC
    ]

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        cacheDirectory = caches.appendingPathComponent("BetterQuickLook/Transcodes", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        let bundled = Bundle.module.url(forResource: "ffmpeg", withExtension: nil)
        if let bundled {
            let prepared = FFmpegTranscoder.prepareExecutable(from: bundled, caches: caches)
            self.ffmpegURL = prepared
            if let prepared {
                logger.info("FFmpeg binary ready at \(prepared.path, privacy: .public)")
            } else {
                logger.error("Failed to prepare FFmpeg binary from bundle path \(bundled.path, privacy: .public)")
            }
        } else {
            self.ffmpegURL = nil
            logger.error("FFmpeg binary missing from bundle resources")
        }
    }

    func preparePlayableURL(from url: URL) -> URL {
        guard needsTranscoding(url: url) else { return url }
        guard let ffmpegURL else {
            logger.error("FFmpeg binary missing or not executable; cannot transcode \(url.path)")
            return url
        }

        let cacheName = (url.path.sha256 ?? url.lastPathComponent) + ".mp4"
        let outputURL = cacheDirectory.appendingPathComponent(cacheName)

        if let sourceAttrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let targetAttrs = try? FileManager.default.attributesOfItem(atPath: outputURL.path),
           let sourceDate = sourceAttrs[.modificationDate] as? Date,
           let targetDate = targetAttrs[.modificationDate] as? Date,
           targetDate >= sourceDate {
            return outputURL
        }

        logger.info("Transcoding \(url.lastPathComponent, privacy: .public) -> \(outputURL.lastPathComponent, privacy: .public)")

        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = [
            "-hide_banner", "-loglevel", "error",
            "-i", url.path,
            "-c:v", "libx264",
            "-preset", "veryfast",
            "-crf", "23",
            "-c:a", "aac",
            "-movflags", "+faststart",
            "-y",
            outputURL.path
        ]

        let pipe = Pipe()
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                logger.info("Transcoded \(url.lastPathComponent, privacy: .public) to \(outputURL.lastPathComponent, privacy: .public)")
                return outputURL
            } else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let log = String(data: data, encoding: .utf8) {
                    logger.error("FFmpeg failed (\(process.terminationStatus)): \(log, privacy: .public)")
                }
            }
        } catch {
            logger.error("Failed to launch ffmpeg: \(error.localizedDescription, privacy: .public)")
        }

        return url
    }

    private static func prepareExecutable(from bundledURL: URL, caches: URL) -> URL? {
        let targetDir = caches.appendingPathComponent("BetterQuickLook/ffmpeg", isDirectory: true)
        let targetURL = targetDir.appendingPathComponent("ffmpeg")
        do {
            try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try? FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: bundledURL, to: targetURL)
            #if os(macOS)
            _ = targetURL.path.withCString { pathPtr in
                "com.apple.quarantine".withCString { namePtr in
                    removexattr(pathPtr, namePtr, 0)
                }
            }
            #endif
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: targetURL.path)
            return targetURL
        } catch {
            Logger(subsystem: "BetterQuickLook", category: "FFmpegTranscoder")
                .error("Unable to stage ffmpeg binary: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func needsTranscoding(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if supportedExtensions.contains(ext) { return true }
        return containsUnsupportedCodec(url: url)
    }

    private func containsUnsupportedCodec(url: URL) -> Bool {
        let asset = AVURLAsset(url: url)
        let videoTracks = asset.tracks(withMediaType: .video)
        for track in videoTracks {
            for formatDesc in track.formatDescriptions {
                let desc = formatDesc as! CMFormatDescription
                let subtype = CMFormatDescriptionGetMediaSubType(desc)
                if unsupportedVideoSubtypes.contains(subtype) {
                    return true
                }
            }
        }

        let audioTracks = asset.tracks(withMediaType: .audio)
        for track in audioTracks {
            for formatDesc in track.formatDescriptions {
                let desc = formatDesc as! CMAudioFormatDescription
                let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee
                if let mFormatID = asbd?.mFormatID, unsupportedAudioSubtypes.contains(mFormatID) {
                    return true
                }
            }
        }

        return false
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
    var sha256: String? {
        guard let data = data(using: .utf8) else { return nil }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

private extension FourCharCode {
    init(_ string: String) {
        var result: FourCharCode = 0
        for scalar in string.unicodeScalars.prefix(4) {
            result = (result << 8) + FourCharCode(scalar.value)
        }
        self = result
    }
}
