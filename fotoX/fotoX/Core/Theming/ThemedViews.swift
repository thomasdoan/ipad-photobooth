//
//  ThemedViews.swift
//  fotoX
//
//  Wrapper views that consume theme components from the environment
//

import SwiftUI

// MARK: - Themed Background

/// Background view that uses the current theme's background component
struct ThemedBackgroundView: View {
    @Environment(\.themeComponents) private var themeComponents: any ThemeComponentProvider

    var body: some View {
        themeComponents.makeBackgroundView()
    }
}

// MARK: - Themed Buttons

/// Primary action button using the current theme's styling
struct ThemedActionButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.themeComponents) private var themeComponents: any ThemeComponentProvider

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        themeComponents.makePrimaryButton(title: title, icon: icon, action: action)
    }
}

/// Secondary action button using the current theme's styling
struct ThemedSecondaryActionButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.themeComponents) private var themeComponents: any ThemeComponentProvider

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        themeComponents.makeSecondaryButton(title: title, icon: icon, action: action)
    }
}

// MARK: - Themed Countdown

/// Countdown overlay using the current theme's styling
struct ThemedCountdownOverlay: View {
    let number: Int

    @Environment(\.themeComponents) private var themeComponents: any ThemeComponentProvider

    var body: some View {
        themeComponents.makeCountdownView(number: number)
    }
}

// MARK: - Themed Recording Progress

/// Recording progress indicator using the current theme's styling
struct ThemedRecordingProgress: View {
    let progress: Double
    let duration: TimeInterval
    let elapsed: TimeInterval

    @Environment(\.themeComponents) private var themeComponents: any ThemeComponentProvider

    var body: some View {
        themeComponents.makeRecordingProgressView(
            progress: progress,
            duration: duration,
            elapsed: elapsed
        )
    }
}

// MARK: - Themed Recording Badge

/// Recording badge indicator using the current theme's styling
struct ThemedRecordingIndicator: View {
    @Environment(\.themeComponents) private var themeComponents: any ThemeComponentProvider

    var body: some View {
        themeComponents.makeRecordingBadge()
    }
}

// MARK: - Themed Particles

/// Floating particles view using the current theme's styling
struct ThemedParticlesView: View {
    @Environment(\.themeComponents) private var themeComponents: any ThemeComponentProvider
    @Environment(\.appTheme) private var theme

    var body: some View {
        themeComponents.makeParticlesView(theme: theme)
    }
}

// MARK: - Themed Recording Encouragement

/// "Keep going!" text styled according to current theme
struct ThemedRecordingEncouragement: View {
    @Environment(\.themeComponents) private var themeComponents: any ThemeComponentProvider

    var body: some View {
        themeComponents.makeRecordingEncouragement()
    }
}

// MARK: - Themed Error Icon

/// Error icon styled according to current theme
struct ThemedErrorIcon: View {
    @Environment(\.themeComponents) private var themeComponents: any ThemeComponentProvider

    var body: some View {
        themeComponents.makeErrorIcon()
    }
}
