//
//  CasinoBackgroundView.swift
//  fotoX
//
//  Casino-themed background with green felt texture and card pattern
//

import SwiftUI

/// Casino-themed background with green felt gradient and decorative elements
struct CasinoBackgroundView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var themeAssets
    
    var body: some View {
        ZStack {
            // Base felt gradient (deep green)
            feltGradient
            
            // Subtle card pattern overlay
            cardPatternOverlay
                .opacity(0.04)
            
            // Theme background if available
            if let background = themeAssets?.background {
                background
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.5)
            }
            
            // Decorative corner accents
            cornerAccents
            
            // Subtle vignette
            vignetteOverlay
            
            // Neon border glow
            neonBorderGlow
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Components
    
    private var feltGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "#0D4D2B") ?? .green,  // Deep casino green
                Color(hex: "#0A3D22") ?? .green,  // Slightly darker
                Color(hex: "#072A18") ?? .green   // Darkest at edges
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var cardPatternOverlay: some View {
        GeometryReader { geometry in
            let patternSize: CGFloat = 60
            let columns = Int(geometry.size.width / patternSize) + 1
            let rows = Int(geometry.size.height / patternSize) + 1
            
            Canvas { context, size in
                let suits = ["suit.spade.fill", "suit.heart.fill", "suit.diamond.fill", "suit.club.fill"]
                
                for row in 0..<rows {
                    for column in 0..<columns {
                        let suitIndex = (row + column) % 4
                        let x = CGFloat(column) * patternSize + patternSize / 2
                        let y = CGFloat(row) * patternSize + patternSize / 2
                        
                        if let symbol = context.resolveSymbol(id: suits[suitIndex]) {
                            context.draw(symbol, at: CGPoint(x: x, y: y))
                        }
                    }
                }
            } symbols: {
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .tag("suit.spade.fill")
                
                Image(systemName: "suit.heart.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .tag("suit.heart.fill")
                
                Image(systemName: "suit.diamond.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .tag("suit.diamond.fill")
                
                Image(systemName: "suit.club.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .tag("suit.club.fill")
            }
        }
    }
    
    private var cornerAccents: some View {
        GeometryReader { geometry in
            ZStack {
                // Top-left ace
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(theme.accent.opacity(0.08))
                    .position(x: 80, y: 80)
                    .rotationEffect(.degrees(-15))
                
                // Top-right
                Image(systemName: "suit.heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(theme.primary.opacity(0.1))
                    .position(x: geometry.size.width - 60, y: 100)
                    .rotationEffect(.degrees(10))
                
                // Bottom-left
                Image(systemName: "suit.diamond.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(theme.accent.opacity(0.06))
                    .position(x: 100, y: geometry.size.height - 120)
                    .rotationEffect(.degrees(20))
                
                // Bottom-right
                Image(systemName: "suit.club.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(theme.accent.opacity(0.05))
                    .position(x: geometry.size.width - 100, y: geometry.size.height - 80)
                    .rotationEffect(.degrees(-10))
            }
        }
    }
    
    private var vignetteOverlay: some View {
        RadialGradient(
            colors: [
                .clear,
                .clear,
                Color.black.opacity(0.3)
            ],
            center: .center,
            startRadius: 200,
            endRadius: 800
        )
    }
    
    private var neonBorderGlow: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            theme.accent.opacity(0.4),
                            theme.primary.opacity(0.3),
                            theme.accent.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .blur(radius: 8)
                .padding(4)
        }
    }
}

/// Simplified casino background for performance-critical areas
struct CasinoBackgroundSimple: View {
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "#0D4D2B") ?? .green,
                Color(hex: "#072A18") ?? .green
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    CasinoBackgroundView()
        .withTheme(.default)
}
