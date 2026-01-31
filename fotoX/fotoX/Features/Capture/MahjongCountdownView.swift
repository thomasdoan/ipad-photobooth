//
//  MahjongCountdownView.swift
//  fotoX
//
//  Mahjong-themed countdown with tile flip animation
//

import SwiftUI

/// Mahjong-themed countdown with tile flip animation
struct MahjongCountdownView: View {
    let number: Int

    @State private var isFlipped = false
    @State private var tileRotation: Double = 0
    @State private var showGlow = false

    @Environment(\.appTheme) private var theme

    // Mahjong colors
    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green
    private let darkJade = Color(hex: "#0F2E24") ?? .black
    private let ivory = Color(hex: "#F5F5DC") ?? .white
    private let dragonRed = Color(hex: "#B22222") ?? .red
    private let gold = Color(hex: "#D4AF37") ?? .yellow

    private let tileWidth: CGFloat = 140
    private let tileHeight: CGFloat = 190

    var body: some View {
        ZStack {
            // Dark overlay
            darkJade.opacity(0.7)
                .ignoresSafeArea()

            // Tile container
            ZStack {
                // Glow effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(glowColor.opacity(0.4))
                    .frame(width: tileWidth + 40, height: tileHeight + 40)
                    .blur(radius: showGlow ? 30 : 18)
                    .opacity(showGlow ? 1 : 0.5)

                // The flipping tile
                ZStack {
                    // Tile back (bamboo pattern)
                    tileBack
                        .opacity(isFlipped ? 0 : 1)
                        .rotation3DEffect(
                            .degrees(tileRotation),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.5
                        )

                    // Tile front with number
                    tileFront
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(
                            .degrees(tileRotation - 180),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.5
                        )
                }
                .frame(width: tileWidth, height: tileHeight)

                // Floating dragon particles
                ForEach(0..<4) { index in
                    dragonParticle(index: index)
                }
            }
        }
        .onAppear {
            flipTile()
        }
        .onChange(of: number) { _, _ in
            // Reset and flip for next number
            withAnimation(.none) {
                isFlipped = false
                tileRotation = 0
                showGlow = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                flipTile()
            }
        }
    }

    private var glowColor: Color {
        number % 2 == 1 ? dragonRed : gold
    }

    private func flipTile() {
        // Glow burst
        withAnimation(.easeOut(duration: 0.2)) {
            showGlow = true
        }

        // Tile flip animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            tileRotation = 180
            isFlipped = true
        }

        // Glow fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                showGlow = false
            }
        }
    }

    // MARK: - Tile Components

    private var tileBack: some View {
        ZStack {
            // Tile base (ivory)
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [ivory, ivory.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Bamboo pattern
            bambooPattern
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(8)

            // Gold border
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    LinearGradient(
                        colors: [gold, gold.opacity(0.7), gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )

            // Center dragon watermark
            Text("龍")
                .font(.system(size: 50, weight: .bold))
                .foregroundStyle(jadeGreen.opacity(0.15))
        }
        .shadow(color: jadeGreen.opacity(0.5), radius: 12, y: 5)
    }

    private var bambooPattern: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 18
            let columns = Int(geometry.size.width / spacing)
            let rows = Int(geometry.size.height / spacing)

            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<columns, id: \.self) { column in
                    Circle()
                        .fill(jadeGreen.opacity(0.12))
                        .frame(width: 10, height: 10)
                        .position(
                            x: CGFloat(column) * spacing + spacing / 2,
                            y: CGFloat(row) * spacing + spacing / 2
                        )
                }
            }
        }
    }

    private var tileFront: some View {
        ZStack {
            // Tile base (ivory)
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [ivory, Color(hex: "#F0F0E0") ?? ivory],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Tile content
            VStack {
                // Top-left corner
                HStack {
                    VStack(spacing: 2) {
                        Text("\(number)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(numberColor)
                        Text("中")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(dragonRed.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.leading, 10)
                .padding(.top, 6)

                Spacer()

                // Center number
                ZStack {
                    // Glow behind
                    Text("\(number)")
                        .font(.system(size: 90, weight: .black, design: .rounded))
                        .foregroundStyle(numberColor.opacity(0.3))
                        .blur(radius: 8)

                    Text("\(number)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundStyle(numberColor)
                }

                Spacer()

                // Bottom-right corner (inverted)
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Text("發")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.green.opacity(0.7))
                        Text("\(number)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(numberColor)
                    }
                    .rotationEffect(.degrees(180))
                }
                .padding(.trailing, 10)
                .padding(.bottom, 6)
            }

            // Card border
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(gold.opacity(0.5), lineWidth: 2)
        }
        .shadow(color: numberColor.opacity(0.4), radius: 10, y: 4)
    }

    private var numberColor: Color {
        number % 2 == 1 ? dragonRed : jadeGreen
    }

    private func dragonParticle(index: Int) -> some View {
        let symbols = ["中", "發", "東", "西"]
        let colors: [Color] = [dragonRed, .green, ivory, ivory]
        let offsets: [(x: CGFloat, y: CGFloat)] = [
            (-100, -80), (100, -70), (-90, 90), (95, 85)
        ]

        return Text(symbols[index])
            .font(.system(size: 20, weight: .bold))
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
        Color(hex: "#0F2E24")
        MahjongCountdownView(number: 3)
    }
    .withTheme(.default)
}
