//
//  CasinoParticlesView.swift
//  fotoX
//
//  Floating casino-themed particles (cards, chips, dice, suits)
//

import SwiftUI

/// Casino-themed floating particles with cards, chips, and dice
struct CasinoParticlesView: View {
    let theme: AppTheme
    
    @State private var particles: [CasinoParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    CasinoParticleView(particle: particle, theme: theme)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func generateParticles(in size: CGSize) {
        let count = 20
        particles = (0..<count).map { index in
            let symbolType = CasinoSymbolType.allCases[index % CasinoSymbolType.allCases.count]
            return CasinoParticle(
                id: UUID(),
                symbolType: symbolType,
                basePosition: CGPoint(
                    x: CGFloat.random(in: 30...(size.width - 30)),
                    y: CGFloat.random(in: 50...(size.height - 50))
                ),
                baseRotation: Double.random(in: -45...45),
                phase: Double.random(in: 0...(2 * .pi)),
                duration: Double.random(in: 4...8),
                opacity: Double.random(in: 0.4...0.9),
                baseScale: Double.random(in: 0.8...1.4)
            )
        }
    }
}

/// Individual animated particle
struct CasinoParticleView: View {
    let particle: CasinoParticle
    let theme: AppTheme
    
    @State private var animationProgress: Double = 0
    
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
        let floatY = sin(animationProgress * .pi * 2 + particle.phase) * 40
        let floatY2 = cos(animationProgress * .pi * 3 + particle.phase * 1.3) * 20
        let driftX = sin(animationProgress * .pi * 4 + particle.phase) * 30
        let driftX2 = cos(animationProgress * .pi * 2.5 + particle.phase * 0.8) * 15
        
        return CGPoint(
            x: driftX + driftX2,
            y: floatY + floatY2
        )
    }
    
    private var currentRotation: Double {
        sin(animationProgress * .pi * 3 + particle.phase) * 30 +
        cos(animationProgress * .pi * 2) * 15 +
        particle.baseRotation
    }
    
    private var currentScale: Double {
        (0.7 + sin(animationProgress * .pi * 4) * 0.25 + cos(animationProgress * .pi * 2.5) * 0.1) * particle.baseScale
    }
    
    private var currentOpacity: Double {
        let flicker = 0.7 + sin(animationProgress * .pi * 5 + particle.phase) * 0.2
        return particle.opacity * flicker
    }
    
    @ViewBuilder
    private var symbolView: some View {
        switch particle.symbolType {
        case .spade:
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(theme.accent)
        case .heart:
            Image(systemName: "suit.heart.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(theme.primary)
        case .diamond:
            Image(systemName: "suit.diamond.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(theme.primary)
        case .club:
            Image(systemName: "suit.club.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(theme.accent)
        case .chip:
            ZStack {
                Circle()
                    .strokeBorder(theme.accent, lineWidth: 3)
                    .frame(width: 28, height: 28)
                Circle()
                    .fill(theme.primary)
                    .frame(width: 18, height: 18)
            }
        case .dice:
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(theme.accent)
                    .frame(width: 26, height: 26)
                Circle()
                    .fill(theme.secondary)
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private func startAnimation() {
        // Continuous looping animation
        withAnimation(
            .linear(duration: particle.duration)
            .repeatForever(autoreverses: false)
        ) {
            animationProgress = 1.0
        }
    }
}

// MARK: - Models

enum CasinoSymbolType: String, CaseIterable {
    case spade, heart, diamond, club, chip, dice
}

struct CasinoParticle: Identifiable {
    let id: UUID
    let symbolType: CasinoSymbolType
    let basePosition: CGPoint
    let baseRotation: Double
    let phase: Double
    let duration: Double
    let opacity: Double
    let baseScale: Double
}

#Preview {
    ZStack {
        Color(hex: "#0A3D22")
        CasinoParticlesView(theme: .default)
    }
}
