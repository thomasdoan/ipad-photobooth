//
//  VolumeButtonHandler.swift
//  fotoX
//
//  Handles Bluetooth remote volume button presses
//

import AVFoundation
import Observation
import SwiftUI
import MediaPlayer

/// Handler for detecting volume button presses (typically from Bluetooth remotes)
@Observable
@MainActor
final class VolumeButtonHandler {
    // MARK: - State

    /// Whether the handler is currently listening for volume changes
    private(set) var isListening: Bool = false

    /// Callback invoked when a volume button press is detected
    var onVolumeButtonPressed: (() -> Void)?

    // MARK: - Private

    private var volumeObservation: NSKeyValueObservation?
    private var lastTriggerTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.3
    private var initialVolume: Float?

    /// Reference to the volume slider for programmatic volume control
    private var volumeSlider: UISlider?

    /// Target volume to reset to after button press (allows button to work at any volume)
    private let targetVolume: Float = 0.5

    // MARK: - Public Methods

    /// Sets the volume slider reference for programmatic volume control
    func setVolumeSlider(_ slider: UISlider?) {
        volumeSlider = slider
    }

    /// Starts listening for volume button presses
    func startListening() {
        guard !isListening else { return }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            print("VolumeButtonHandler: Failed to activate audio session: \(error)")
            return
        }

        // Store initial volume to detect changes
        initialVolume = audioSession.outputVolume

        // Observe volume changes
        volumeObservation = audioSession.observe(\.outputVolume, options: [.new, .old]) { [weak self] session, change in
            Task { @MainActor in
                self?.handleVolumeChange(oldValue: change.oldValue, newValue: change.newValue)
            }
        }

        isListening = true
    }

    /// Stops listening for volume button presses
    func stopListening() {
        volumeObservation?.invalidate()
        volumeObservation = nil
        initialVolume = nil
        isListening = false
    }

    // MARK: - Private Methods

    private func handleVolumeChange(oldValue: Float?, newValue: Float?) {
        guard let oldVolume = oldValue, let newVolume = newValue else { return }

        // Only handle volume-up presses
        guard newVolume > oldVolume else { return }

        // Apply debouncing
        let now = Date()
        guard now.timeIntervalSince(lastTriggerTime) >= debounceInterval else { return }
        lastTriggerTime = now

        // Trigger callback
        onVolumeButtonPressed?()

        // Reset volume to target level after a short delay so subsequent presses work
        // even when volume was at max (1.0) or min (0.0)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            self.resetVolumeToTarget()
        }
    }

    private func resetVolumeToTarget() {
        guard let slider = volumeSlider else {
            print("VolumeButtonHandler: No slider reference - cannot reset volume")
            return
        }
        // Always reset to target volume to ensure subsequent presses work reliably
        let currentVolume = AVAudioSession.sharedInstance().outputVolume
        print("VolumeButtonHandler: Resetting volume from \(currentVolume) to \(targetVolume)")
        slider.value = targetVolume
    }
}

// MARK: - VolumeHUDSuppressor

/// A view that suppresses the system volume HUD by embedding a hidden MPVolumeView
struct VolumeHUDSuppressor: UIViewRepresentable {
    /// Callback invoked when the volume slider is ready for programmatic control
    var onSliderReady: ((UISlider) -> Void)?

    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.clipsToBounds = true
        // Hide the slider visually but keep it in the view hierarchy
        volumeView.showsVolumeSlider = true
        volumeView.setVolumeThumbImage(UIImage(), for: .normal)
        volumeView.isUserInteractionEnabled = false
        // Make the track invisible
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            slider.minimumTrackTintColor = .clear
            slider.maximumTrackTintColor = .clear
            slider.thumbTintColor = .clear
            // Notify caller that slider is ready
            onSliderReady?(slider)
        }
        return volumeView
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        // Keep slider visuals clear on updates
        if let slider = uiView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            slider.minimumTrackTintColor = .clear
            slider.maximumTrackTintColor = .clear
            slider.thumbTintColor = .clear
            // Re-provide slider reference on updates to ensure handler always has valid reference
            onSliderReady?(slider)
        }
    }
}
