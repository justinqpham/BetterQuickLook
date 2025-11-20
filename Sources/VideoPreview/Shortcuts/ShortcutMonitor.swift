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
        guard eventTap == nil else { return }

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
        ) else { return }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
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
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        if selectionProvider.isFinderActive() || isPreviewVisible() {
            switch keyCode {
            case 49: // space
                if isPreviewVisible() {
                    onCloseSelection()
                } else if let url = selectionProvider.firstVideoURL() {
                    onOpenSelection(url)
                }
                return nil // block native Quick Look
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
