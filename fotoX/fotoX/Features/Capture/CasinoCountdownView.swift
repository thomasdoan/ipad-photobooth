//
//  CasinoCountdownView.swift
//  fotoX
//
//  Casino-themed countdown with playing card flip animation
//

import SwiftUI

/// Casino-themed countdown with card flip animation
@MainActor
struct CasinoCountdownView: View {
    let number: Int
    
    @State private var isFlipped = false
    @State private var cardRotation: Double = 0
    @State private var showGlow = false
    
    @Environment(\.appTheme) private var theme
    
    private let cardWidth: CGFloat = 180
    private let cardHeight: CGFloat = 260
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Card container
            ZStack {
                // Neon glow effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.accent.opacity(0.3))
                    .frame(width: cardWidth + 40, height: cardHeight + 40)
                    .blur(radius: showGlow ? 30 : 15)
                    .opacity(showGlow ? 1 : 0.6)
                
                // The flipping card
                ZStack {
                    // Card back (red with pattern)
                    cardBack
                        .opacity(isFlipped ? 0 : 1)
                        .rotation3DEffect(
                            .degrees(cardRotation),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.5
                        )
                    
                    // Card front with number
                    cardFront
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(
                            .degrees(cardRotation - 180),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.5
                        )
                }
                .frame(width: cardWidth, height: cardHeight)
                
                // Floating suit particles
                ForEach(0..<4) { index in
                    suitParticle(index: index)
                }
            }
        }
        .onAppear {
            flipCard()
        }
        .onChange(of: number) { _, _ in
            // Reset and flip for next number
            withAnimation(.none) {
                isFlipped = false
                cardRotation = 0
                showGlow = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                flipCard()
            }
        }
    }
    
    private func flipCard() {
        // Glow pulse
        withAnimation(.easeOut(duration: 0.3)) {
            showGlow = true
        }
        
        // Card flip animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            cardRotation = 180
            isFlipped = true
        }
        
        // Glow fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showGlow = false
            }
        }
    }
    
    // MARK: - Card Components
    
    private var cardBack: some View {
        ZStack {
            // Card base
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [theme.primary, theme.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Diamond pattern overlay
            GeometryReader { geometry in
                let patternSize: CGFloat = 20
                let columns = Int(geometry.size.width / patternSize) + 1
                let rows = Int(geometry.size.height / patternSize) + 1
                
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { column in
                        if (row + column) % 2 == 0 {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(theme.accent.opacity(0.2))
                                .position(
                                    x: CGFloat(column) * patternSize + patternSize / 2,
                                    y: CGFloat(row) * patternSize + patternSize / 2
                                )
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Inner border
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(theme.accent.opacity(0.5), lineWidth: 2)
                .padding(8)
            
            // Center emblem
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(theme.accent)
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
    }
    
    private var cardFront: some View {
        ZStack {
            // White card base
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
            
            // Card content
            VStack {
                // Top-left corner
                HStack {
                    VStack(spacing: 2) {
                        Text("\(number)")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(theme.primary)
                        Image(systemName: suitForNumber.systemName)
                            .font(.system(size: 14))
                            .foregroundStyle(suitForNumber.color)
                    }
                    Spacer()
                }
                .padding(.leading, 12)
                .padding(.top, 8)
                
                Spacer()
                
                // Center number
                ZStack {
                    // Large suit behind
                    Image(systemName: suitForNumber.systemName)
                        .font(.system(size: 80))
                        .foregroundStyle(suitForNumber.color.opacity(0.15))
                    
                    Text("\(number)")
                        .font(.system(size: 100, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primary)
                }
                
                Spacer()
                
                // Bottom-right corner (inverted)
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Image(systemName: suitForNumber.systemName)
                            .font(.system(size: 14))
                            .foregroundStyle(suitForNumber.color)
                        Text("\(number)")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(theme.primary)
                    }
                    .rotationEffect(.degrees(180))
                }
                .padding(.trailing, 12)
                .padding(.bottom, 8)
            }
            
            // Card border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
    
    private var suitForNumber: (systemName: String, color: Color) {
        switch number % 4 {
        case 1: return ("suit.heart.fill", .red)
        case 2: return ("suit.diamond.fill", .red)
        case 3: return ("suit.club.fill", theme.secondary)
        default: return ("suit.spade.fill", theme.secondary)
        }
    }
    
    private func suitParticle(index: Int) -> some View {
        let suits = ["suit.spade.fill", "suit.heart.fill", "suit.diamond.fill", "suit.club.fill"]
        let colors: [Color] = [theme.secondary, .red, .red, theme.secondary]
        let offsets: [(x: CGFloat, y: CGFloat)] = [
            (-120, -100), (120, -80), (-100, 100), (110, 110)
        ]
        
        return Image(systemName: suits[index])
            .font(.system(size: 24))
            .foregroundStyle(colors[index].opacity(0.6))
            .offset(x: offsets[index].x, y: offsets[index].y)
            .opacity(isFlipped ? 1 : 0)
            .scaleEffect(isFlipped ? 1 : 0.5)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.6).delay(Double(index) * 0.1),
                value: isFlipped
            )
    }
}

#Preview {
    ZStack {
        Color.black
        CasinoCountdownView(number: 3)
    }
    .withTheme(.default)
}
