import SwiftUI

@main
struct BetterQuickLookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = SettingsStore.shared

    var body: some Scene {
        Settings {
            SettingsView(settings: settings)
                .frame(width: 360)
        }
    }
}
