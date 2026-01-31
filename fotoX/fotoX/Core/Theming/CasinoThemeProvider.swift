//
//  CasinoThemeProvider.swift
//  fotoX
//
//  Casino theme provider wrapping existing casino-themed components
//

import SwiftUI

/// Casino theme provider that wraps existing casino-themed UI components.
/// Features poker chips, playing cards, green felt backgrounds, and gold accents.
@MainActor
final class CasinoThemeProvider: ThemeComponentProvider, Sendable {
    let style: ThemeStyle = .casino

    func makeBackgroundView() -> AnyView {
        AnyView(CasinoBackgroundView())
    }

    func makePrimaryButton(title: String, icon: String?, action: @escaping () -> Void) -> AnyView {
        AnyView(CasinoChipButton(title, icon: icon, action: action))
    }

    func makeSecondaryButton(title: String, icon: String?, action: @escaping () -> Void) -> AnyView {
        AnyView(CasinoSecondaryButton(title, icon: icon, action: action))
    }

    func makeCountdownView(number: Int) -> AnyView {
        AnyView(CasinoCountdownView(number: number))
    }

    func makeRecordingProgressView(progress: Double, duration: TimeInterval, elapsed: TimeInterval) -> AnyView {
        AnyView(CasinoRecordingProgressView(progress: progress, duration: duration, elapsed: elapsed))
    }

    func makeRecordingBadge() -> AnyView {
        AnyView(CasinoRecordingBadge())
    }

    func makeParticlesView(theme: AppTheme) -> AnyView {
        AnyView(CasinoParticlesView(theme: theme))
    }

    func makeErrorOverlayBackground() -> Color {
        Color(hex: "#0A3D22")?.opacity(0.95) ?? Color.black.opacity(0.7)
    }

    func makeRecordingEncouragement() -> AnyView {
        AnyView(CasinoRecordingEncouragement())
    }

    func makeErrorIcon() -> AnyView {
        AnyView(CasinoErrorIcon())
    }
}

// MARK: - Casino Recording Encouragement

/// Casino-styled "Keep going!" with poker theme
struct CasinoRecordingEncouragement: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "suit.heart.fill")
                .foregroundStyle(theme.primary)
            Text("Keep going!")
                .font(.headline.bold())
                .foregroundStyle(theme.accent)
            Image(systemName: "suit.spade.fill")
                .foregroundStyle(theme.accent)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(hex: "#0D4D2B")?.opacity(0.9) ?? theme.secondary.opacity(0.9))
                .overlay(
                    Capsule()
                        .strokeBorder(theme.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .padding(.top, 16)
    }
}

// MARK: - Casino Error Icon

/// Casino-themed error icon with diamond circle
struct CasinoErrorIcon: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.primary.opacity(0.2))
                .frame(width: 80, height: 80)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(theme.accent)
        }
    }
}
