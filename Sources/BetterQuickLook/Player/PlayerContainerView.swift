final class PlayerContainerModel: ObservableObject {
    @Published var fileName: String?
}

import AppKit
import SwiftUI
import Combine

struct PlayerContainerView: View {
    @ObservedObject var model: PlayerContainerModel
    let engine: PlayerEngine
    @ObservedObject var settings: SettingsStore

    var body: some View {
        ZStack(alignment: .bottom) {
            EngineHostView(engine: engine)
                .background(Color.black)

            if !engine.usesNativeControls {
                PlayerOverlayView(engine: engine, skipInterval: settings.skipInterval)
                    .transition(.opacity)
            }
            fileOverlay
        }
    }

    private var fileOverlay: some View {
        VStack {
            if let name = model.fileName {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.top, 12)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
    }
}

private struct EngineHostView: NSViewRepresentable {
    let engine: PlayerEngine

    func makeNSView(context: Context) -> NSView {
        let wrapper = NSView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.wantsLayer = true
        wrapper.layer?.cornerRadius = 12
        wrapper.layer?.masksToBounds = true
        wrapper.layer?.backgroundColor = NSColor.black.cgColor

        let playerView = engine.containerView
        playerView.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(playerView)

        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: wrapper.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])

        return wrapper
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private struct PlayerOverlayView: View {
    let engine: PlayerEngine
    let skipInterval: Double

    @State private var isHovering = true
    @State private var isScrubbing = false
    @State private var lastInteraction = Date()
    @State private var sliderValue: Double = 0
    @State private var duration: Double = 0
    @State private var isPlaying: Bool = false

    private let hideDelay: TimeInterval = 2.5

    var body: some View {
        VStack {
            Spacer()
            controlBar
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
        .opacity(controlsVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: controlsVisible)
        .onHover { hovering in
            isHovering = hovering
            if hovering { bumpInteraction() }
        }
        .onReceive(timer) { _ in
            guard !isScrubbing else { return }
            updateFromEngine()
        }
        .onAppear {
            updateFromEngine()
        }
    }

    private var controlsVisible: Bool {
        isHovering || isScrubbing || Date().timeIntervalSince(lastInteraction) < hideDelay
    }

    private var controlBar: some View {
        HStack(spacing: 10) {
            Button(action: togglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3.weight(.medium))
            }
            .buttonStyle(.borderless)

            Button(action: { skip(by: -skipInterval) }) {
                Image(systemName: "gobackward.\(Int(skipInterval))")
            }
            .buttonStyle(.borderless)

            Button(action: { skip(by: skipInterval) }) {
                Image(systemName: "goforward.\(Int(skipInterval))")
            }
            .buttonStyle(.borderless)

            Text(timeString(sliderValue))
                .font(.caption.monospacedDigit())
                .foregroundColor(.white.opacity(0.85))
                .frame(minWidth: 48, alignment: .trailing)

            Slider(
                value: Binding(
                    get: { duration > 0 ? sliderValue : 0 },
                    set: { newValue in
                        sliderValue = newValue
                        isScrubbing = true
                    }
                ),
                in: 0...max(duration, 0.1),
                onEditingChanged: { editing in
                    isScrubbing = editing
                    bumpInteraction()
                    if !editing {
                        seek(to: sliderValue)
                    }
                }
            )
            .frame(minWidth: 220)

            Text(timeString(duration))
                .font(.caption.monospacedDigit())
                .foregroundColor(.white.opacity(0.85))
                .frame(minWidth: 48, alignment: .leading)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture { bumpInteraction() }
        .tint(.white)
    }

    private func togglePlayPause() {
        engine.togglePlayPause()
        bumpInteraction()
        updateFromEngine()
    }

    private func skip(by seconds: Double) {
        engine.skip(by: seconds)
        bumpInteraction()
        updateFromEngine()
    }

    private func seek(to seconds: Double) {
        engine.seek(to: seconds)
        bumpInteraction()
        updateFromEngine()
    }

    private func updateFromEngine() {
        isPlaying = engine.isPlaying
        duration = engine.duration ?? duration
        if duration.isFinite && duration > 0 {
            sliderValue = min(max(engine.currentTime, 0), duration)
        } else {
            sliderValue = engine.currentTime
        }
    }

    private func bumpInteraction() {
        lastInteraction = Date()
    }

    private func timeString(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }

    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    }
}
