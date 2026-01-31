//
//  MahjongThemeProvider.swift
//  fotoX
//
//  Mahjong theme provider with traditional tile aesthetics
//

import SwiftUI

/// Mahjong theme provider with jade green backgrounds, ivory tiles, and red accents.
/// Features tile-styled buttons, traditional mahjong symbols, and tile-flip animations.
@MainActor
final class MahjongThemeProvider: ThemeComponentProvider, Sendable {
    let style: ThemeStyle = .mahjong

    func makeBackgroundView() -> AnyView {
        AnyView(MahjongBackgroundView())
    }

    func makePrimaryButton(title: String, icon: String?, action: @escaping () -> Void) -> AnyView {
        AnyView(MahjongTileButton(title, icon: icon, action: action))
    }

    func makeSecondaryButton(title: String, icon: String?, action: @escaping () -> Void) -> AnyView {
        AnyView(MahjongSecondaryButton(title, icon: icon, action: action))
    }

    func makeCountdownView(number: Int) -> AnyView {
        AnyView(MahjongCountdownView(number: number))
    }

    func makeRecordingProgressView(progress: Double, duration: TimeInterval, elapsed: TimeInterval) -> AnyView {
        AnyView(MahjongRecordingProgressView(progress: progress, duration: duration, elapsed: elapsed))
    }

    func makeRecordingBadge() -> AnyView {
        AnyView(MahjongRecordingBadge())
    }

    func makeParticlesView(theme: AppTheme) -> AnyView {
        AnyView(MahjongParticlesView(theme: theme))
    }

    func makeErrorOverlayBackground() -> Color {
        Color(hex: "#1D4E3E")?.opacity(0.95) ?? Color.black.opacity(0.9)
    }

    func makeRecordingEncouragement() -> AnyView {
        AnyView(MahjongRecordingEncouragement())
    }

    func makeErrorIcon() -> AnyView {
        AnyView(MahjongErrorIcon())
    }
}

// MARK: - Mahjong Recording Encouragement

/// Mahjong-styled "Keep going!" with dragon motif
struct MahjongRecordingEncouragement: View {
    @Environment(\.appTheme) private var theme

    // Mahjong colors
    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green
    private let ivory = Color(hex: "#F5F5DC") ?? .white
    private let dragonRed = Color(hex: "#B22222") ?? .red

    var body: some View {
        HStack(spacing: 12) {
            Text("發")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.green)
            Text("Keep going!")
                .font(.headline.bold())
                .foregroundStyle(ivory)
            Text("中")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(dragonRed)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(jadeGreen.opacity(0.9))
                .overlay(
                    Capsule()
                        .strokeBorder(ivory.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .padding(.top, 16)
    }
}

// MARK: - Mahjong Error Icon

/// Mahjong-themed error icon with tile styling
struct MahjongErrorIcon: View {
    @Environment(\.appTheme) private var theme

    private let ivory = Color(hex: "#F5F5DC") ?? .white
    private let dragonRed = Color(hex: "#B22222") ?? .red
    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green

    var body: some View {
        ZStack {
            // Tile background
            RoundedRectangle(cornerRadius: 8)
                .fill(ivory)
                .frame(width: 80, height: 100)
                .shadow(color: jadeGreen.opacity(0.5), radius: 8)
            
            // Red dragon with X
            VStack(spacing: 4) {
                Text("中")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(dragonRed)
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(dragonRed.opacity(0.7))
            }
        }
    }
}
