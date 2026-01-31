//
//  BalatroParticlesView.swift
//  fotoX
//
//  Floating Balatro-themed particles (joker faces, cards, chips, suits, neon stars)
//

import SwiftUI

/// Balatro-themed floating particles with CRT flicker effect
@MainActor
struct BalatroParticlesView: View {
    let theme: AppTheme

    @State private var particles: [BalatroParticle] = []

    // Balatro colors
    private let neonMagenta = Color(hex: "#FF2D6A") ?? .pink
    private let neonCyan = Color(hex: "#4DEEEA") ?? .cyan
    private let gold = Color(hex: "#FFD700") ?? .yellow

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    BalatroParticleView(particle: particle, theme: theme)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles(in size: CGSize) {
        let count = 18

        // Safe bounds for X
        let minX: CGFloat = 40
        let maxX: CGFloat = max(minX, size.width - 40)

        // Safe bounds for Y
        let minY: CGFloat = 60
        let maxY: CGFloat = max(minY, size.height - 60)

        particles = (0..<count).map { index in
            let symbolType = BalatroSymbolType.allCases[index % BalatroSymbolType.allCases.count]
            return BalatroParticle(
                id: UUID(),
                symbolType: symbolType,
                basePosition: CGPoint(
                    x: CGFloat.random(in: minX...maxX),
                    y: CGFloat.random(in: minY...maxY)
                ),
                baseRotation: Double.random(in: -30...30),
                phase: Double.random(in: 0...(2 * .pi)),
                duration: Double.random(in: 5...9),
                opacity: Double.random(in: 0.5...0.95),
                baseScale: Double.random(in: 0.7...1.3)
            )
        }
    }
}

/// Individual animated Balatro particle
@MainActor
struct BalatroParticleView: View {
    let particle: BalatroParticle
    let theme: AppTheme

    @State private var animationProgress: Double = 0

    // Balatro colors
    private let neonMagenta = Color(hex: "#FF2D6A") ?? .pink
    private let neonCyan = Color(hex: "#4DEEEA") ?? .cyan
    private let gold = Color(hex: "#FFD700") ?? .yellow
    private let deepPurple = Color(hex: "#1a1a2e") ?? .purple

    var body: some View {
        symbolView
            .opacity(currentOpacity)
            .scaleEffect(currentScale)
            .rotationEffect(.degrees(currentRotation))
            .offset(x: currentOffset.x, y: currentOffset.y)
            .position(particle.basePosition)
            .onAppear {
                startAnimation()
            }
    }

    private var currentOffset: CGPoint {
        // Sinusoidal float pattern
        let floatY = sin(animationProgress * .pi * 2 + particle.phase) * 35
        let floatY2 = cos(animationProgress * .pi * 2.5 + particle.phase * 1.2) * 18
        let driftX = sin(animationProgress * .pi * 3 + particle.phase * 0.8) * 25
        let driftX2 = cos(animationProgress * .pi * 2 + particle.phase) * 12

        return CGPoint(
            x: driftX + driftX2,
            y: floatY + floatY2
        )
    }

    private var currentRotation: Double {
        // Slow rotation
        sin(animationProgress * .pi * 2.5 + particle.phase) * 25 +
        cos(animationProgress * .pi * 1.8) * 12 +
        particle.baseRotation
    }

    private var currentScale: Double {
        // Scale pulse
        let basePulse = 0.8 + sin(animationProgress * .pi * 3) * 0.15
        let secondaryPulse = cos(animationProgress * .pi * 2) * 0.08
        return (basePulse + secondaryPulse) * particle.baseScale
    }

    private var currentOpacity: Double {
        // CRT-like flicker effect
        let flicker = 0.75 + sin(animationProgress * .pi * 6 + particle.phase) * 0.15
        let secondaryFlicker = cos(animationProgress * .pi * 8 + particle.phase * 1.5) * 0.08
        return particle.opacity * (flicker + secondaryFlicker)
    }

    @ViewBuilder
    private var symbolView: some View {
        switch particle.symbolType {
        case .jokerFace:
            Image(systemName: "face.smiling.inverse")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(gold)
        case .playingCard:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.9))
                    .frame(width: 22, height: 30)
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(deepPurple)
            }
        case .chip:
            ZStack {
                Circle()
                    .fill(neonMagenta)
                    .frame(width: 26, height: 26)
                Circle()
                    .strokeBorder(gold, lineWidth: 2)
                    .frame(width: 26, height: 26)
                Circle()
                    .fill(deepPurple)
                    .frame(width: 14, height: 14)
            }
        case .spade:
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(neonCyan)
        case .heart:
            Image(systemName: "suit.heart.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(neonMagenta)
        case .diamond:
            Image(systemName: "suit.diamond.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(neonMagenta)
        case .club:
            Image(systemName: "suit.club.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(neonCyan)
        case .neonStar:
            Image(systemName: "star.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [neonCyan, neonMagenta],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .sparkle:
            Image(systemName: "sparkle")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(gold)
        }
    }

    private func startAnimation() {
        withAnimation(
            .linear(duration: particle.duration)
            .repeatForever(autoreverses: false)
        ) {
            animationProgress = 1.0
        }
    }
}

// MARK: - Models

enum BalatroSymbolType: String, CaseIterable {
    case jokerFace
    case playingCard
    case chip
    case spade
    case heart
    case diamond
    case club
    case neonStar
    case sparkle
}

struct BalatroParticle: Identifiable {
    let id: UUID
    let symbolType: BalatroSymbolType
    let basePosition: CGPoint
    let baseRotation: Double
    let phase: Double
    let duration: Double
    let opacity: Double
    let baseScale: Double
}

#Preview {
    ZStack {
        Color(hex: "#0f0f1a")
        BalatroParticlesView(theme: .default)
    }
}
