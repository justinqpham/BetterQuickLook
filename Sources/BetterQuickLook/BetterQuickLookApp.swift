import SwiftUI

@main
struct BetterQuickLookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = SettingsStore.shared

    init() {
        NSLog("🌟 BetterQuickLookApp.init() called")
    }

    var body: some Scene {
        NSLog("🎨 BetterQuickLookApp.body computed")
        return Settings {
            SettingsView(settings: settings)
                .frame(width: 360)
        }
    }
}
