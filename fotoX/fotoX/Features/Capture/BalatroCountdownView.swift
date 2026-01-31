//
//  BalatroCountdownView.swift
//  fotoX
//
//  Balatro-themed countdown with joker card flip animation
//

import SwiftUI

/// Balatro-themed countdown with joker card flip animation
struct BalatroCountdownView: View {
    let number: Int

    @State private var isFlipped = false
    @State private var cardRotation: Double = 0
    @State private var showGlow = false

    @Environment(\.appTheme) private var theme

    // Balatro colors
    private let deepPurple = Color(hex: "#1a1a2e") ?? .purple
    private let voidBlack = Color(hex: "#0f0f1a") ?? .black
    private let neonMagenta = Color(hex: "#FF2D6A") ?? .pink
    private let neonCyan = Color(hex: "#4DEEEA") ?? .cyan
    private let gold = Color(hex: "#FFD700") ?? .yellow

    private let cardWidth: CGFloat = 180
    private let cardHeight: CGFloat = 260

    var body: some View {
        ZStack {
            // Dark overlay
            voidBlack.opacity(0.7)
                .ignoresSafeArea()

            // Card container
            ZStack {
                // Neon glow effect (magenta/cyan based on odd/even)
                RoundedRectangle(cornerRadius: 16)
                    .fill(glowColor.opacity(0.4))
                    .frame(width: cardWidth + 50, height: cardHeight + 50)
                    .blur(radius: showGlow ? 35 : 20)
                    .opacity(showGlow ? 1 : 0.5)

                // The flipping card
                ZStack {
                    // Card back (purple with diamond pattern and joker silhouette)
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

                // Floating particles around card
                ForEach(0..<6) { index in
                    floatingParticle(index: index)
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

    private var glowColor: Color {
        number % 2 == 1 ? neonMagenta : neonCyan
    }

    private func flipCard() {
        // Glow burst
        withAnimation(.easeOut(duration: 0.2)) {
            showGlow = true
        }

        // Card flip animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            cardRotation = 180
            isFlipped = true
        }

        // Glow fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                showGlow = false
            }
        }
    }

    // MARK: - Card Components

    private var cardBack: some View {
        ZStack {
            // Card base (deep purple)
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [deepPurple, deepPurple.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Diamond pattern overlay
            diamondPatternOverlay
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Gold border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [gold, gold.opacity(0.7), gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )

            // Inner border
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(gold.opacity(0.3), lineWidth: 1)
                .padding(10)

            // Center joker silhouette
            ZStack {
                Circle()
                    .fill(neonMagenta.opacity(0.15))
                    .frame(width: 70, height: 70)
                    .blur(radius: 5)

                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(gold.opacity(0.8))
            }
        }
        .shadow(color: neonMagenta.opacity(0.4), radius: 15, y: 5)
    }

    private var diamondPatternOverlay: some View {
        GeometryReader { geometry in
            let patternSize: CGFloat = 25
            let columns = Int(geometry.size.width / patternSize) + 1
            let rows = Int(geometry.size.height / patternSize) + 1

            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<columns, id: \.self) { column in
                    if (row + column) % 2 == 0 {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(neonMagenta.opacity(0.15))
                            .position(
                                x: CGFloat(column) * patternSize + patternSize / 2,
                                y: CGFloat(row) * patternSize + patternSize / 2
                            )
                    }
                }
            }
        }
    }

    private var cardFront: some View {
        ZStack {
            // Off-white card base
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#F5F5DC") ?? .white)

            // Card content
            VStack {
                // Top-left corner (joker pip)
                HStack {
                    VStack(spacing: 2) {
                        Text("\(number)")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(numberColor)
                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: 14))
                            .foregroundStyle(numberColor.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.leading, 12)
                .padding(.top, 8)

                Spacer()

                // Center number with glow
                ZStack {
                    // Glow behind number
                    Text("\(number)")
                        .font(.system(size: 110, weight: .black, design: .rounded))
                        .foregroundStyle(numberColor.opacity(0.3))
                        .blur(radius: 10)

                    Text("\(number)")
                        .font(.system(size: 100, weight: .black, design: .rounded))
                        .foregroundStyle(numberColor)
                }

                Spacer()

                // Bottom-right corner (inverted)
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: 14))
                            .foregroundStyle(numberColor.opacity(0.7))
                        Text("\(number)")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(numberColor)
                    }
                    .rotationEffect(.degrees(180))
                }
                .padding(.trailing, 12)
                .padding(.bottom, 8)
            }

            // Card border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: numberColor.opacity(0.4), radius: 12, y: 4)
    }

    private var numberColor: Color {
        number % 2 == 1 ? neonMagenta : neonCyan
    }

    private func floatingParticle(index: Int) -> some View {
        let symbols = ["suit.spade.fill", "suit.heart.fill", "suit.diamond.fill", "suit.club.fill", "star.fill", "sparkle"]
        let colors: [Color] = [neonCyan, neonMagenta, neonMagenta, neonCyan, gold, neonCyan]
        let offsets: [(x: CGFloat, y: CGFloat)] = [
            (-130, -110), (130, -90), (-120, 110), (125, 120), (-140, 20), (145, -20)
        ]

        return Image(systemName: symbols[index])
            .font(.system(size: index < 4 ? 22 : 18))
            .foregroundStyle(colors[index].opacity(0.7))
            .offset(x: offsets[index].x, y: offsets[index].y)
            .opacity(isFlipped ? 1 : 0)
            .scaleEffect(isFlipped ? 1 : 0.3)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.6).delay(Double(index) * 0.08),
                value: isFlipped
            )
    }
}

#Preview {
    ZStack {
        Color(hex: "#0f0f1a")
        BalatroCountdownView(number: 3)
    }
    .withTheme(.default)
}
