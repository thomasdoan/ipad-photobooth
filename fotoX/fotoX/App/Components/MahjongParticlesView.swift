//
//  MahjongParticlesView.swift
//  fotoX
//
//  Floating mahjong-themed particles (winds, dragons, bamboo, circles)
//

import SwiftUI

/// Mahjong-themed floating particles with traditional symbols
@MainActor
struct MahjongParticlesView: View {
    let theme: AppTheme

    @State private var particles: [MahjongParticle] = []

    // Mahjong colors
    private let ivory = Color(hex: "#F5F5DC") ?? .white
    private let dragonRed = Color(hex: "#B22222") ?? .red
    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green
    private let gold = Color(hex: "#D4AF37") ?? .yellow

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    MahjongParticleView(particle: particle, theme: theme)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles(in size: CGSize) {
        let count = 16

        // Safe bounds for X
        let minX: CGFloat = 40
        let maxX: CGFloat = max(minX, size.width - 40)

        // Safe bounds for Y
        let minY: CGFloat = 60
        let maxY: CGFloat = max(minY, size.height - 60)

        particles = (0..<count).map { index in
            let symbolType = MahjongSymbolType.allCases[index % MahjongSymbolType.allCases.count]
            return MahjongParticle(
                id: UUID(),
                symbolType: symbolType,
                basePosition: CGPoint(
                    x: CGFloat.random(in: minX...maxX),
                    y: CGFloat.random(in: minY...maxY)
                ),
                baseRotation: Double.random(in: -20...20),
                phase: Double.random(in: 0...(2 * .pi)),
                duration: Double.random(in: 5...9),
                opacity: Double.random(in: 0.5...0.9),
                baseScale: Double.random(in: 0.7...1.2)
            )
        }
    }
}

/// Individual animated mahjong particle
@MainActor
struct MahjongParticleView: View {
    let particle: MahjongParticle
    let theme: AppTheme

    @State private var animationProgress: Double = 0

    // Mahjong colors
    private let ivory = Color(hex: "#F5F5DC") ?? .white
    private let dragonRed = Color(hex: "#B22222") ?? .red
    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green
    private let gold = Color(hex: "#D4AF37") ?? .yellow

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
        // Gentle floating pattern
        let floatY = sin(animationProgress * .pi * 2 + particle.phase) * 30
        let floatY2 = cos(animationProgress * .pi * 2.5 + particle.phase * 1.2) * 15
        let driftX = sin(animationProgress * .pi * 3 + particle.phase * 0.8) * 20
        let driftX2 = cos(animationProgress * .pi * 2 + particle.phase) * 10

        return CGPoint(
            x: driftX + driftX2,
            y: floatY + floatY2
        )
    }

    private var currentRotation: Double {
        // Slow rotation
        sin(animationProgress * .pi * 2 + particle.phase) * 20 +
        cos(animationProgress * .pi * 1.5) * 10 +
        particle.baseRotation
    }

    private var currentScale: Double {
        // Scale pulse
        let basePulse = 0.85 + sin(animationProgress * .pi * 2.5) * 0.12
        let secondaryPulse = cos(animationProgress * .pi * 2) * 0.06
        return (basePulse + secondaryPulse) * particle.baseScale
    }

    private var currentOpacity: Double {
        // Subtle flicker effect
        let flicker = 0.8 + sin(animationProgress * .pi * 4 + particle.phase) * 0.12
        return particle.opacity * flicker
    }

    @ViewBuilder
    private var symbolView: some View {
        switch particle.symbolType {
        case .eastWind:
            Text("東")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(ivory.opacity(0.8))
        case .southWind:
            Text("南")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(ivory.opacity(0.8))
        case .westWind:
            Text("西")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(ivory.opacity(0.8))
        case .northWind:
            Text("北")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(ivory.opacity(0.8))
        case .redDragon:
            Text("中")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(dragonRed)
        case .greenDragon:
            Text("發")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.green)
        case .whiteDragon:
            // White dragon - empty frame
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(ivory.opacity(0.6), lineWidth: 2)
                .frame(width: 24, height: 32)
        case .bamboo:
            // Bamboo stick representation
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(.green.opacity(0.7))
                        .frame(width: 4, height: 10)
                }
            }
        case .circle:
            // Circle tile representation
            ZStack {
                Circle()
                    .fill(dragonRed.opacity(0.6))
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(ivory.opacity(0.8))
                    .frame(width: 12, height: 12)
            }
        case .character:
            // Character tile representation
            Text("萬")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(dragonRed.opacity(0.7))
        case .flower:
            // Chrysanthemum/flower symbol
            Image(systemName: "leaf.fill")
                .font(.system(size: 20))
                .foregroundStyle(gold)
        case .tile:
            // Floating tile representation
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(ivory.opacity(0.9))
                    .frame(width: 24, height: 32)
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(jadeGreen.opacity(0.3), lineWidth: 1)
                    .frame(width: 20, height: 28)
            }
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

enum MahjongSymbolType: String, CaseIterable {
    case eastWind
    case southWind
    case westWind
    case northWind
    case redDragon
    case greenDragon
    case whiteDragon
    case bamboo
    case circle
    case character
    case flower
    case tile
}

struct MahjongParticle: Identifiable {
    let id: UUID
    let symbolType: MahjongSymbolType
    let basePosition: CGPoint
    let baseRotation: Double
    let phase: Double
    let duration: Double
    let opacity: Double
    let baseScale: Double
}

#Preview {
    ZStack {
        Color(hex: "#1D4E3E")
        MahjongParticlesView(theme: .default)
    }
}
