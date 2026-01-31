//
//  ThemeComponentProvider.swift
//  fotoX
//
//  Protocol defining theme-specific component factories for extensible theming
//

import SwiftUI

/// Protocol defining theme-specific component factories.
/// Each theme style (standard, casino, etc.) implements this protocol
/// to provide its own visual components.
@MainActor
protocol ThemeComponentProvider: Sendable {
    /// The theme style this provider handles
    var style: ThemeStyle { get }

    /// Creates the background view for idle/main screens
    func makeBackgroundView() -> AnyView

    /// Creates a primary action button (e.g., "Tap to Start")
    /// - Parameters:
    ///   - title: Button title text
    ///   - icon: Optional SF Symbol icon name
    ///   - action: Button action closure
    func makePrimaryButton(title: String, icon: String?, action: @escaping () -> Void) -> AnyView

    /// Creates a secondary action button
    /// - Parameters:
    ///   - title: Button title text
    ///   - icon: Optional SF Symbol icon name
    ///   - action: Button action closure
    func makeSecondaryButton(title: String, icon: String?, action: @escaping () -> Void) -> AnyView

    /// Creates the countdown overlay view
    /// - Parameter number: Current countdown number
    func makeCountdownView(number: Int) -> AnyView

    /// Creates the recording progress indicator
    /// - Parameters:
    ///   - progress: Recording progress from 0.0 to 1.0
    ///   - duration: Total recording duration
    ///   - elapsed: Elapsed time
    func makeRecordingProgressView(progress: Double, duration: TimeInterval, elapsed: TimeInterval) -> AnyView

    /// Creates the recording badge indicator
    func makeRecordingBadge() -> AnyView

    /// Creates floating particles view for visual interest
    /// - Parameter theme: The current app theme for colors
    func makeParticlesView(theme: AppTheme) -> AnyView

    /// Returns the background color for error overlays
    func makeErrorOverlayBackground() -> Color

    /// Creates "Keep going!" encouragement text during recording
    func makeRecordingEncouragement() -> AnyView

    /// Creates themed error icon
    func makeErrorIcon() -> AnyView
}
