import AppKit

@MainActor
final class ShortcutMonitor {
    private let selectionProvider: FinderSelectionProvider
    private let isPreviewVisible: () -> Bool
    private let onOpenSelection: (URL) -> Void
    private let onCloseSelection: () -> Void
    private let onSkipBack: () -> Void
    private let onSkipForward: () -> Void

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(
        selectionProvider: FinderSelectionProvider,
        isPreviewVisible: @escaping () -> Bool,
        onOpenSelection: @escaping (URL) -> Void,
        onCloseSelection: @escaping () -> Void,
        onSkipBack: @escaping () -> Void,
        onSkipForward: @escaping () -> Void
    ) {
        self.selectionProvider = selectionProvider
        self.isPreviewVisible = isPreviewVisible
        self.onOpenSelection = onOpenSelection
        self.onCloseSelection = onCloseSelection
        self.onSkipBack = onSkipBack
        self.onSkipForward = onSkipForward
    }

    func start() {
        NSLog("🚀 ShortcutMonitor.start() called")
        guard eventTap == nil else {
            NSLog("⚠️ Event tap already exists, skipping")
            return
        }

        // Check if Accessibility permission is granted
        let accessEnabled = AXIsProcessTrusted()
        NSLog("🔐 AXIsProcessTrusted() returned: %@", accessEnabled ? "true" : "false")
        guard accessEnabled else {
            NSLog("❌ Accessibility permission not granted - event tap cannot be created")
            NSLog("📋 Please grant Accessibility permission in System Settings → Privacy & Security → Accessibility")
            return
        }
        NSLog("✅ Accessibility permission granted - creating event tap")

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<ShortcutMonitor>.fromOpaque(refcon).takeUnretainedValue()
            return monitor.handleEvent(proxy: proxy, type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            NSLog("❌ Failed to create event tap - this shouldn't happen if Accessibility is granted")
            NSLog("📋 Bundle ID: %@", Bundle.main.bundleIdentifier ?? "unknown")
            NSLog("📋 Bundle path: %@", Bundle.main.bundlePath)
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        NSLog("✅ Event tap created and enabled successfully")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Re-enable the event tap if macOS disabled it due to timeout or user input
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        if selectionProvider.isFinderActive() || isPreviewVisible() {
            switch keyCode {
            case 49: // space
                if isPreviewVisible() {
                    onCloseSelection()
                    return nil
                }
                if let url = selectionProvider.firstVideoURL() {
                    onOpenSelection(url)
                    return nil // block native Quick Look when we handled it
                }
                return Unmanaged.passUnretained(event) // let macOS Quick Look handle non-video
            case 123: // left arrow
                if isPreviewVisible() {
                    onSkipBack()
                    return nil
                }
            case 124: // right arrow
                if isPreviewVisible() {
                    onSkipForward()
                    return nil
                }
            case 53: // escape closes preview
                if isPreviewVisible() {
                    onCloseSelection()
                    return nil
                }
            default:
                break
            }
        }

        return Unmanaged.passUnretained(event)
    }
}
