import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    static let defaultSkipInterval: Double = 5.0
    static let minSkipInterval: Double = 1.0
    static let maxSkipInterval: Double = 30.0
    static let defaultMatchVideoSizeOnOpen = true
    static let defaultLockAspectRatio = true
    static let defaultFillWindowAspect = true
    static let defaultPreferVLCEngine = false

    @Published var skipInterval: Double {
        didSet { persistSkipInterval() }
    }
    @Published var matchVideoSizeOnOpen: Bool {
        didSet { persistMatchVideoSizeOnOpen() }
    }
    @Published var lockAspectRatio: Bool {
        didSet { persistLockAspectRatio() }
    }
    @Published var fillWindowAspect: Bool {
        didSet { persistFillWindowAspect() }
    }
    @Published var preferVLCEngine: Bool {
        didSet { persistPreferVLCEngine() }
    }

    private enum Keys {
        static let skipInterval = "skipInterval"
        static let matchVideoSizeOnOpen = "matchVideoSizeOnOpen"
        static let lockAspectRatio = "lockAspectRatio"
        static let fillWindowAspect = "fillWindowAspect"
        static let preferVLCEngine = "preferVLCEngine"
    }

    private init() {
        let storedValue = UserDefaults.standard.double(forKey: Keys.skipInterval)
        skipInterval = storedValue > 0 ? storedValue : Self.defaultSkipInterval
        matchVideoSizeOnOpen = UserDefaults.standard.object(forKey: Keys.matchVideoSizeOnOpen) as? Bool ?? Self.defaultMatchVideoSizeOnOpen
        lockAspectRatio = UserDefaults.standard.object(forKey: Keys.lockAspectRatio) as? Bool ?? Self.defaultLockAspectRatio
        fillWindowAspect = UserDefaults.standard.object(forKey: Keys.fillWindowAspect) as? Bool ?? Self.defaultFillWindowAspect
        preferVLCEngine = UserDefaults.standard.object(forKey: Keys.preferVLCEngine) as? Bool ?? Self.defaultPreferVLCEngine
    }

    func updateSkipInterval(_ value: Double) {
        let clamped = max(Self.minSkipInterval, min(Self.maxSkipInterval, value))
        if clamped != skipInterval {
            skipInterval = clamped
        }
    }

    func updateMatchVideoSizeOnOpen(_ value: Bool) {
        matchVideoSizeOnOpen = value
    }

    func updateLockAspectRatio(_ value: Bool) {
        lockAspectRatio = value
    }

    func updateFillWindowAspect(_ value: Bool) {
        fillWindowAspect = value
    }

    func updatePreferVLCEngine(_ value: Bool) {
        preferVLCEngine = value
    }

    private func persistSkipInterval() {
        UserDefaults.standard.set(skipInterval, forKey: Keys.skipInterval)
    }

    private func persistMatchVideoSizeOnOpen() {
        UserDefaults.standard.set(matchVideoSizeOnOpen, forKey: Keys.matchVideoSizeOnOpen)
    }

    private func persistLockAspectRatio() {
        UserDefaults.standard.set(lockAspectRatio, forKey: Keys.lockAspectRatio)
    }

    private func persistFillWindowAspect() {
        UserDefaults.standard.set(fillWindowAspect, forKey: Keys.fillWindowAspect)
    }

    private func persistPreferVLCEngine() {
        UserDefaults.standard.set(preferVLCEngine, forKey: Keys.preferVLCEngine)
    }
}
