import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    @State private var pendingSkip: Double

    init(settings: SettingsStore) {
        self.settings = settings
        _pendingSkip = State(initialValue: settings.skipInterval)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Playback")
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Skip duration")
                    Spacer()
                    Text("\(Int(pendingSkip))s")
                        .foregroundColor(.secondary)
                }

                ResponsiveSkipControls(pendingSkip: $pendingSkip)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Match video size on open", isOn: $settings.matchVideoSizeOnOpen)
                Toggle("Lock aspect ratio while resizing", isOn: $settings.lockAspectRatio)
                Toggle("Make video follow window shape", isOn: $settings.fillWindowAspect)
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 320, minHeight: 240)
        .onChange(of: settings.skipInterval) { pendingSkip = $0 }
        .onChange(of: pendingSkip) { settings.updateSkipInterval($0) }
    }

    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.minimum = NSNumber(value: SettingsStore.minSkipInterval)
        formatter.maximum = NSNumber(value: SettingsStore.maxSkipInterval)
        return formatter
    }()
}

private struct ResponsiveSkipControls: View {
    @Binding var pendingSkip: Double

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                slider
                stepControl
            }
            VStack(alignment: .leading, spacing: 12) {
                slider
                stepControl
            }
        }
    }

    private var slider: some View {
        Slider(
            value: $pendingSkip,
            in: SettingsStore.minSkipInterval...SettingsStore.maxSkipInterval,
            step: 1
        )
    }

    private var stepControl: some View {
        HStack(spacing: 12) {
            Stepper("", value: $pendingSkip, in: SettingsStore.minSkipInterval...SettingsStore.maxSkipInterval, step: 1)
                .labelsHidden()

            TextField("Seconds", value: $pendingSkip, formatter: SettingsView.formatter)
                .frame(width: 72)
                .textFieldStyle(.roundedBorder)
        }
    }
}
