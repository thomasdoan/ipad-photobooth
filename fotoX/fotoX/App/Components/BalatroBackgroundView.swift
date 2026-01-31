//
//  BalatroBackgroundView.swift
//  fotoX
//
//  Balatro-themed background with CRT scanlines and neon glow
//

import SwiftUI

/// Balatro-themed background with deep purple gradient, CRT scanlines, and neon edge glow
@MainActor
struct BalatroBackgroundView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var themeAssets
    @State private var glowPulse = false

    // Balatro color palette
    private let deepPurple = Color(hex: "#1a1a2e") ?? .purple
    private let voidBlack = Color(hex: "#0f0f1a") ?? .black
    private let neonMagenta = Color(hex: "#FF2D6A") ?? .pink
    private let neonCyan = Color(hex: "#4DEEEA") ?? .cyan

    var body: some View {
        ZStack {
            // Base radial gradient (deep purple → void black)
            radialGradient

            // Theme background if available
            if let background = themeAssets?.background {
                background
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.4)
            }

            // CRT scanline overlay
            scanlineOverlay

            // Neon edge glow
            neonEdgeGlow

            // Corner joker motifs
            jokerCornerAccents

            // Subtle vignette
            vignetteOverlay
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: - Components

    private var radialGradient: some View {
        RadialGradient(
            colors: [
                deepPurple,
                deepPurple.opacity(0.9),
                voidBlack.opacity(0.95),
                voidBlack
            ],
            center: .center,
            startRadius: 100,
            endRadius: 800
        )
    }

    private var scanlineOverlay: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let lineSpacing: CGFloat = 3
                let lineCount = Int(size.height / lineSpacing)

                for i in 0..<lineCount {
                    let y = CGFloat(i) * lineSpacing
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(0.04)))
                }
            }
        }
    }

    private var neonEdgeGlow: some View {
        GeometryReader { geometry in
            ZStack {
                // Inner glow from edges (magenta)
                Rectangle()
                    .fill(.clear)
                    .overlay(
                        Rectangle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        neonMagenta.opacity(glowPulse ? 0.6 : 0.3),
                                        neonCyan.opacity(glowPulse ? 0.4 : 0.2),
                                        neonMagenta.opacity(glowPulse ? 0.6 : 0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                            .blur(radius: glowPulse ? 15 : 10)
                    )
            }
        }
    }

    private var jokerCornerAccents: some View {
        GeometryReader { geometry in
            ZStack {
                // Top-left joker silhouette
                Image(systemName: "theatermask.and.paintbrush.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(neonMagenta.opacity(0.06))
                    .position(x: 70, y: 70)
                    .rotationEffect(.degrees(-15))

                // Top-right
                Image(systemName: "suit.club.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(neonCyan.opacity(0.05))
                    .position(x: geometry.size.width - 60, y: 80)
                    .rotationEffect(.degrees(10))

                // Bottom-left
                Image(systemName: "suit.diamond.fill")
                    .font(.system(size: 55))
                    .foregroundStyle(neonMagenta.opacity(0.05))
                    .position(x: 80, y: geometry.size.height - 100)
                    .rotationEffect(.degrees(20))

                // Bottom-right joker
                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: 70))
                    .foregroundStyle(neonCyan.opacity(0.04))
                    .position(x: geometry.size.width - 90, y: geometry.size.height - 80)
                    .rotationEffect(.degrees(-10))
            }
        }
    }

    private var vignetteOverlay: some View {
        RadialGradient(
            colors: [
                .clear,
                .clear,
                voidBlack.opacity(0.4)
            ],
            center: .center,
            startRadius: 200,
            endRadius: 900
        )
    }
}

/// Simplified Balatro background for performance-critical areas
@MainActor
struct BalatroBackgroundSimple: View {
    private let deepPurple = Color(hex: "#1a1a2e") ?? .purple
    private let voidBlack = Color(hex: "#0f0f1a") ?? .black

    var body: some View {
        LinearGradient(
            colors: [deepPurple, voidBlack],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    BalatroBackgroundView()
        .withTheme(.default)
}
