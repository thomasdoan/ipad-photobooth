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
    @State private var animationPhase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    
                    for particle in particles {
                        let progress = (time - particle.startTime).truncatingRemainder(dividingBy: particle.duration) / particle.duration
                        
                        // Floating animation
                        let floatOffset = sin(progress * .pi * 2 + particle.phase) * 20
                        let driftX = sin(progress * .pi * 4 + particle.phase) * 10
                        
                        let x = particle.basePosition.x + driftX
                        let y = particle.basePosition.y + floatOffset
                        
                        let rotation = Angle.degrees(sin(progress * .pi * 2 + particle.phase) * 15 + particle.baseRotation)
                        let scale = 0.8 + sin(progress * .pi * 2) * 0.2
                        
                        context.opacity = particle.opacity * (0.7 + sin(progress * .pi * 2) * 0.3)
                        
                        if let resolved = context.resolveSymbol(id: particle.symbolId) {
                            var transform = CGAffineTransform.identity
                                .translatedBy(x: x, y: y)
                                .rotated(by: rotation.radians)
                                .scaledBy(x: scale, y: scale)
                            
                            context.transform = transform
                            context.draw(resolved, at: .zero)
                            context.transform = .identity
                        }
                    }
                } symbols: {
                    // Card suits
                    ForEach(CasinoSymbolType.allCases, id: \.self) { symbolType in
                        symbolView(for: symbolType)
                            .tag(symbolType.rawValue)
                    }
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private func symbolView(for type: CasinoSymbolType) -> some View {
        switch type {
        case .spade:
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 28))
                .foregroundStyle(theme.accent.opacity(0.6))
        case .heart:
            Image(systemName: "suit.heart.fill")
                .font(.system(size: 28))
                .foregroundStyle(theme.primary.opacity(0.6))
        case .diamond:
            Image(systemName: "suit.diamond.fill")
                .font(.system(size: 28))
                .foregroundStyle(theme.primary.opacity(0.6))
        case .club:
            Image(systemName: "suit.club.fill")
                .font(.system(size: 28))
                .foregroundStyle(theme.accent.opacity(0.6))
        case .chip:
            Circle()
                .strokeBorder(theme.accent.opacity(0.5), lineWidth: 3)
                .frame(width: 24, height: 24)
                .overlay {
                    Circle()
                        .fill(theme.primary.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
        case .dice:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.accent.opacity(0.6))
                    .frame(width: 22, height: 22)
                
                // Dice dots
                Circle()
                    .fill(.black.opacity(0.5))
                    .frame(width: 4, height: 4)
            }
        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: 16))
                .foregroundStyle(theme.accent.opacity(0.4))
        }
    }
    
    private func generateParticles(in size: CGSize) {
        let count = 18
        particles = (0..<count).map { index in
            let symbolType = CasinoSymbolType.allCases[index % CasinoSymbolType.allCases.count]
            return CasinoParticle(
                id: UUID(),
                symbolId: symbolType.rawValue,
                basePosition: CGPoint(
                    x: CGFloat.random(in: 40...(size.width - 40)),
                    y: CGFloat.random(in: 60...(size.height - 60))
                ),
                baseRotation: Double.random(in: -30...30),
                phase: Double.random(in: 0...(2 * .pi)),
                duration: Double.random(in: 4...8),
                opacity: Double.random(in: 0.3...0.7),
                startTime: Date.timeIntervalSinceReferenceDate
            )
        }
    }
}

// MARK: - Models

enum CasinoSymbolType: String, CaseIterable {
    case spade, heart, diamond, club, chip, dice, star
}

struct CasinoParticle: Identifiable {
    let id: UUID
    let symbolId: String
    let basePosition: CGPoint
    let baseRotation: Double
    let phase: Double
    let duration: Double
    let opacity: Double
    let startTime: TimeInterval
}

#Preview {
    ZStack {
        Color.black
        CasinoParticlesView(theme: .default)
    }
}
