//
//  MahjongBackgroundView.swift
//  fotoX
//
//  Mahjong-themed background with jade green gradient and tile patterns
//

import SwiftUI

/// Mahjong-themed background with jade green gradient, tile pattern, and decorative elements
struct MahjongBackgroundView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var themeAssets
    @State private var glowPulse = false

    // Mahjong color palette
    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green
    private let darkJade = Color(hex: "#0F2E24") ?? .black
    private let ivory = Color(hex: "#F5F5DC") ?? .white
    private let dragonRed = Color(hex: "#B22222") ?? .red
    private let gold = Color(hex: "#D4AF37") ?? .yellow

    var body: some View {
        ZStack {
            // Base radial gradient (jade green → dark jade)
            radialGradient

            // Subtle tile pattern overlay
            tilePatternOverlay
                .opacity(0.04)

            // Theme background if available
            if let background = themeAssets?.background {
                background
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.4)
            }

            // Decorative corner wind symbols
            windCornerAccents

            // Gold border glow
            goldBorderGlow

            // Subtle vignette
            vignetteOverlay
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: - Components

    private var radialGradient: some View {
        RadialGradient(
            colors: [
                jadeGreen,
                jadeGreen.opacity(0.9),
                darkJade.opacity(0.95),
                darkJade
            ],
            center: .center,
            startRadius: 100,
            endRadius: 800
        )
    }

    private var tilePatternOverlay: some View {
        GeometryReader { geometry in
            let patternSize: CGFloat = 50
            let columns = Int(geometry.size.width / patternSize) + 1
            let rows = Int(geometry.size.height / patternSize) + 1

            Canvas { context, size in
                for row in 0..<rows {
                    for column in 0..<columns {
                        let x = CGFloat(column) * patternSize + patternSize / 2
                        let y = CGFloat(row) * patternSize + patternSize / 2
                        
                        // Draw tile outline
                        let tileRect = CGRect(
                            x: x - 18,
                            y: y - 24,
                            width: 36,
                            height: 48
                        )
                        let tilePath = RoundedRectangle(cornerRadius: 4)
                            .path(in: tileRect)
                        context.stroke(tilePath, with: .color(ivory.opacity(0.3)), lineWidth: 1)
                    }
                }
            }
        }
    }

    private var windCornerAccents: some View {
        GeometryReader { geometry in
            ZStack {
                // East - top-left
                Text("東")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(ivory.opacity(0.06))
                    .position(x: 70, y: 70)
                    .rotationEffect(.degrees(-10))

                // South - top-right
                Text("南")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(dragonRed.opacity(0.05))
                    .position(x: geometry.size.width - 60, y: 90)
                    .rotationEffect(.degrees(8))

                // West - bottom-left
                Text("西")
                    .font(.system(size: 55, weight: .bold))
                    .foregroundStyle(ivory.opacity(0.05))
                    .position(x: 80, y: geometry.size.height - 100)
                    .rotationEffect(.degrees(15))

                // North - bottom-right
                Text("北")
                    .font(.system(size: 65, weight: .bold))
                    .foregroundStyle(ivory.opacity(0.04))
                    .position(x: geometry.size.width - 90, y: geometry.size.height - 70)
                    .rotationEffect(.degrees(-12))
            }
        }
    }

    private var goldBorderGlow: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .overlay(
                    Rectangle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    gold.opacity(glowPulse ? 0.5 : 0.3),
                                    dragonRed.opacity(glowPulse ? 0.3 : 0.15),
                                    gold.opacity(glowPulse ? 0.5 : 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: glowPulse ? 12 : 8)
                )
        }
    }

    private var vignetteOverlay: some View {
        RadialGradient(
            colors: [
                .clear,
                .clear,
                darkJade.opacity(0.5)
            ],
            center: .center,
            startRadius: 200,
            endRadius: 900
        )
    }
}

/// Simplified mahjong background for performance-critical areas
struct MahjongBackgroundSimple: View {
    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green
    private let darkJade = Color(hex: "#0F2E24") ?? .black

    var body: some View {
        LinearGradient(
            colors: [jadeGreen, darkJade],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    MahjongBackgroundView()
        .withTheme(.default)
}
