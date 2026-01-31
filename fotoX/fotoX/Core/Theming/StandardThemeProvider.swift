//
//  StandardThemeProvider.swift
//  fotoX
//
//  Default theme provider implementing standard UI components
//

import SwiftUI

/// Default theme provider that implements standard (non-themed) UI components.
/// This serves as the baseline visual style for the app.
@MainActor
final class StandardThemeProvider: ThemeComponentProvider, Sendable {
    let style: ThemeStyle = .standard

    func makeBackgroundView() -> AnyView {
        AnyView(StandardBackgroundView())
    }

    func makePrimaryButton(title: String, icon: String?, action: @escaping () -> Void) -> AnyView {
        AnyView(StandardPrimaryButton(title: title, icon: icon, action: action))
    }

    func makeSecondaryButton(title: String, icon: String?, action: @escaping () -> Void) -> AnyView {
        AnyView(StandardSecondaryButton(title: title, icon: icon, action: action))
    }

    func makeCountdownView(number: Int) -> AnyView {
        AnyView(CountdownView(number: number))
    }

    func makeRecordingProgressView(progress: Double, duration: TimeInterval, elapsed: TimeInterval) -> AnyView {
        AnyView(RecordingProgressView(progress: progress, duration: duration, elapsed: elapsed))
    }

    func makeRecordingBadge() -> AnyView {
        AnyView(RecordingBadge())
    }

    func makeParticlesView(theme: AppTheme) -> AnyView {
        AnyView(ParticlesView(theme: theme))
    }

    func makeErrorOverlayBackground() -> Color {
        Color.black.opacity(0.7)
    }

    func makeRecordingEncouragement() -> AnyView {
        AnyView(StandardRecordingEncouragement())
    }

    func makeErrorIcon() -> AnyView {
        AnyView(StandardErrorIcon())
    }
}

// MARK: - Standard Background View

/// Standard background with gradient and decorative orbs
struct StandardBackgroundView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var themeAssets

    var body: some View {
        ZStack {
            // Base gradient using theme colors
            LinearGradient(
                colors: [
                    theme.secondary,
                    theme.secondary.opacity(0.9),
                    theme.primary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Theme background image if available
            if let background = themeAssets?.background {
                background
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.6)
            }

            // Decorative gradient orbs
            Circle()
                .fill(theme.primary.opacity(0.15))
                .frame(width: 500, height: 500)
                .blur(radius: 80)
                .offset(x: -100, y: -300)

            Circle()
                .fill(theme.accent.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: 200, y: 200)
        }
    }
}

// MARK: - Standard Primary Button

/// Standard capsule-style primary button with shadow
struct StandardPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title)
                }

                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            .foregroundStyle(theme.secondary)
            .padding(.horizontal, 64)
            .padding(.vertical, 24)
            .background(
                Capsule()
                    .fill(theme.primary)
                    .shadow(color: theme.primary.opacity(0.5), radius: isPulsing ? 30 : 15, y: 5)
            )
            .scaleEffect(isPulsing ? 1.02 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Standard Secondary Button

/// Standard secondary button with stroke border
struct StandardSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(Capsule().fill(.white))
        }
    }
}

// MARK: - Standard Recording Encouragement

/// Standard "Keep going!" text during recording
struct StandardRecordingEncouragement: View {
    var body: some View {
        Text("Keep going!")
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.top, 16)
    }
}

// MARK: - Standard Error Icon

/// Standard error icon (yellow warning triangle)
struct StandardErrorIcon: View {
    var body: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 50))
            .foregroundStyle(.yellow)
    }
}
