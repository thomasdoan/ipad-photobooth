//
//  BalatroThemeProvider.swift
//  fotoX
//
//  Balatro theme provider with CRT/synthwave aesthetics
//

import SwiftUI

/// Balatro theme provider with CRT scanlines, neon magenta/cyan, and joker card motifs.
/// Features deep purple backgrounds, synthwave aesthetics, and chips/mult gaming elements.
@MainActor
final class BalatroThemeProvider: ThemeComponentProvider, Sendable {
    let style: ThemeStyle = .balatro

    func makeBackgroundView() -> AnyView {
        AnyView(BalatroBackgroundView())
    }

    func makePrimaryButton(title: String, icon: String?, action: @escaping () -> Void) -> AnyView {
        AnyView(BalatroChipButton(title, icon: icon, action: action))
    }

    func makeSecondaryButton(title: String, icon: String?, action: @escaping () -> Void) -> AnyView {
        AnyView(BalatroSecondaryButton(title, icon: icon, action: action))
    }

    func makeCountdownView(number: Int) -> AnyView {
        AnyView(BalatroCountdownView(number: number))
    }

    func makeRecordingProgressView(progress: Double, duration: TimeInterval, elapsed: TimeInterval) -> AnyView {
        AnyView(BalatroRecordingProgressView(progress: progress, duration: duration, elapsed: elapsed))
    }

    func makeRecordingBadge() -> AnyView {
        AnyView(BalatroRecordingBadge())
    }

    func makeParticlesView(theme: AppTheme) -> AnyView {
        AnyView(BalatroParticlesView(theme: theme))
    }

    func makeErrorOverlayBackground() -> Color {
        Color(hex: "#0f0f1a")?.opacity(0.95) ?? Color.black.opacity(0.9)
    }

    func makeRecordingEncouragement() -> AnyView {
        AnyView(BalatroRecordingEncouragement())
    }

    func makeErrorIcon() -> AnyView {
        AnyView(BalatroErrorIcon())
    }
}

// MARK: - Balatro Recording Encouragement

/// Balatro-styled "Keep going!" with neon chip theme
struct BalatroRecordingEncouragement: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Text("x2")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(theme.primary)
            Text("MULT!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accent)
            Text("x2")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(theme.primary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(hex: "#1a1a2e")?.opacity(0.9) ?? theme.secondary.opacity(0.9))
                .overlay(
                    Capsule()
                        .strokeBorder(theme.accent.opacity(0.5), lineWidth: 2)
                )
        )
        .shadow(color: theme.accent.opacity(0.3), radius: 12)
        .padding(.top, 16)
    }
}

// MARK: - Balatro Error Icon

/// Balatro-themed error icon with neon glow
struct BalatroErrorIcon: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.primary.opacity(0.2))
                .frame(width: 90, height: 90)
                .blur(radius: 10)
            Circle()
                .fill(Color(hex: "#1a1a2e") ?? theme.secondary)
                .frame(width: 80, height: 80)
            Circle()
                .strokeBorder(theme.primary, lineWidth: 3)
                .frame(width: 80, height: 80)
            Image(systemName: "xmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(theme.primary)
        }
    }
}
