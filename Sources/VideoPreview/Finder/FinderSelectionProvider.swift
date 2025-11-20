import AppKit
import UniformTypeIdentifiers

@MainActor
final class FinderSelectionProvider {
    private let finderBundleId = "com.apple.finder"

    func firstVideoURL() -> URL? {
        selectedFileURLs().first { isVideo(url: $0) }
    }

    func isFinderActive() -> Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == finderBundleId
    }

    private func selectedFileURLs() -> [URL] {
        let scriptSource = """
        tell application "Finder"
            set selectedItems to selection as alias list
            set posixPaths to {}
            repeat with anItem in selectedItems
                set end of posixPaths to POSIX path of anItem
            end repeat
        end tell
        return posixPaths
        """

        guard let script = NSAppleScript(source: scriptSource) else {
            return []
        }

        var errorDict: NSDictionary?
        let output = script.executeAndReturnError(&errorDict)
        if errorDict != nil {
            return []
        }

        guard output.numberOfItems > 0 else { return [] }

        var urls: [URL] = []
        for index in 1...output.numberOfItems {
            if let item = output.atIndex(index)?.stringValue, !item.isEmpty {
                urls.append(URL(fileURLWithPath: item))
            }
        }
        return urls
    }

    private func isVideo(url: URL) -> Bool {
        if let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let type = UTType(typeIdentifier) {
            if type.conforms(to: .audiovisualContent) || type.conforms(to: .movie) {
                return true
            }
        }

        let allowedExtensions: Set<String> = [
            "mp4", "mov", "m4v", "mkv", "avi", "flv", "wmv", "mpg", "mpeg", "webm"
        ]

        return allowedExtensions.contains(url.pathExtension.lowercased())
    }
}
