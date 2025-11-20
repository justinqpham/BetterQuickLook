import AppKit
import Combine

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let onOpenPreferences: () -> Void
    private let onQuit: () -> Void
    private let onTogglePreview: () -> Void
    private let settings: SettingsStore
    private var bindings = Set<AnyCancellable>()
    private var toggleItems: [SettingsToggle: NSMenuItem] = [:]
    private var skipMenuItem: NSMenuItem?

    init(
        settings: SettingsStore,
        onOpenPreferences: @escaping () -> Void,
        onQuit: @escaping () -> Void,
        onTogglePreview: @escaping () -> Void
    ) {
        self.settings = settings
        self.onOpenPreferences = onOpenPreferences
        self.onQuit = onQuit
        self.onTogglePreview = onTogglePreview

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "play.rectangle", accessibilityDescription: "VideoPreview")
            button.image?.isTemplate = true
            button.toolTip = "Better QuickLook"
        }

        statusItem.menu = makeMenu(settings: settings)
        bind(settings: settings)
    }

    private func makeMenu(settings: SettingsStore) -> NSMenu {
        let menu = NSMenu()

        let skipItem = NSMenuItem()
        skipItem.title = "Skip: \(Int(settings.skipInterval))s"
        skipItem.target = self
        skipMenuItem = skipItem
        menu.addItem(skipItem)

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openPreferences), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        addToggle(title: "Match video size on open", type: .matchSize, state: settings.matchVideoSizeOnOpen, to: menu)
        addToggle(title: "Lock aspect ratio", type: .lockAspect, state: settings.lockAspectRatio, to: menu)
        addToggle(title: "Fit video to window shape", type: .fillWindow, state: settings.fillWindowAspect, to: menu)
        addToggle(title: "Prefer VLC playback", type: .preferVLC, state: settings.preferVLCEngine, to: menu)

        let quitItem = NSMenuItem(title: "Quit Better QuickLook", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func bind(settings: SettingsStore) {
        settings.$skipInterval.sink { [weak self] value in
            self?.skipMenuItem?.title = "Skip: \(Int(value))s"
        }.store(in: &bindings)

        settings.$matchVideoSizeOnOpen.sink { [weak self] value in
            self?.toggleItems[.matchSize]?.state = value ? .on : .off
        }.store(in: &bindings)

        settings.$lockAspectRatio.sink { [weak self] value in
            self?.toggleItems[.lockAspect]?.state = value ? .on : .off
        }.store(in: &bindings)

        settings.$fillWindowAspect.sink { [weak self] value in
            self?.toggleItems[.fillWindow]?.state = value ? .on : .off
        }.store(in: &bindings)

        settings.$preferVLCEngine.sink { [weak self] value in
            self?.toggleItems[.preferVLC]?.state = value ? .on : .off
        }.store(in: &bindings)
    }

    @objc private func quitApp() {
        onQuit()
    }

    @objc private func togglePreview() {
        onTogglePreview()
    }

    @objc private func handleToggle(_ sender: NSMenuItem) {
        guard let type = SettingsToggle(rawValue: sender.tag) else { return }
        let newState = sender.state == .off

        switch type {
        case .matchSize:
            settings.updateMatchVideoSizeOnOpen(newState)
        case .lockAspect:
            settings.updateLockAspectRatio(newState)
        case .fillWindow:
            settings.updateFillWindowAspect(newState)
        case .preferVLC:
            settings.updatePreferVLCEngine(newState)
        }
    }

    private func addToggle(title: String, type: SettingsToggle, state: Bool, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: #selector(handleToggle(_:)), keyEquivalent: "")
        item.target = self
        item.state = state ? .on : .off
        item.tag = type.rawValue
        item.state = state ? .on : .off
        menu.addItem(item)
        toggleItems[type] = item
    }

    @objc private func openPreferences() {
        onOpenPreferences()
    }
}

private enum SettingsToggle: Int {
    case matchSize = 1
    case lockAspect = 2
    case fillWindow = 3
    case preferVLC = 4
}
