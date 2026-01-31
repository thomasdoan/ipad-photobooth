//
//  MahjongButton.swift
//  fotoX
//
//  Mahjong tile-styled buttons with ivory surface and jade accents
//

import SwiftUI

/// Mahjong tile-styled primary button with carved ivory appearance
struct MahjongTileButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var isPressed = false
    @State private var glowPulse = false

    // Mahjong colors
    private let ivory = Color(hex: "#F5F5DC") ?? .white
    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green
    private let dragonRed = Color(hex: "#B22222") ?? .red
    private let gold = Color(hex: "#D4AF37") ?? .yellow

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                RoundedRectangle(cornerRadius: 12)
                    .fill(gold.opacity(glowPulse ? 0.3 : 0.15))
                    .frame(width: 200, height: 220)
                    .blur(radius: glowPulse ? 25 : 15)

                // Stacked tile shadow effect
                tileShape(offset: 8, color: jadeGreen.opacity(0.4))
                tileShape(offset: 5, color: jadeGreen.opacity(0.6))
                tileShape(offset: 2, color: jadeGreen.opacity(0.8))

                // Main tile
                mainTile
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    private func tileShape(offset: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(color)
            .frame(width: 160, height: 200)
            .offset(y: offset)
    }

    private var mainTile: some View {
        ZStack {
            // Tile base (ivory)
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [ivory, ivory.opacity(0.9), Color(hex: "#E8E8D0") ?? ivory],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 200)

            // Inner carved area
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [ivory.opacity(0.95), Color(hex: "#F0F0E0") ?? ivory],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 140, height: 180)
                .shadow(color: .black.opacity(0.1), radius: 2, x: -1, y: -1)
                .shadow(color: .white.opacity(0.8), radius: 1, x: 1, y: 1)

            // Border decoration
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    LinearGradient(
                        colors: [gold, gold.opacity(0.6), gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 160, height: 200)

            // Content
            VStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(dragonRed)
                }

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(jadeGreen)
                    .multilineTextAlignment(.center)
            }

            // Corner dragon decorations
            tileCornerDecorations
        }
    }

    private var tileCornerDecorations: some View {
        ZStack {
            // Top corners - small dragons
            Text("中")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(dragonRed.opacity(0.4))
                .offset(x: -55, y: -75)

            Text("發")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.green.opacity(0.4))
                .offset(x: 55, y: -75)

            // Bottom corners
            Text("發")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.green.opacity(0.4))
                .rotationEffect(.degrees(180))
                .offset(x: -55, y: 75)

            Text("中")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(dragonRed.opacity(0.4))
                .rotationEffect(.degrees(180))
                .offset(x: 55, y: 75)
        }
    }
}

/// Mahjong secondary button with jade stroke
struct MahjongSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var isPressed = false

    private let ivory = Color(hex: "#F5F5DC") ?? .white
    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green
    private let gold = Color(hex: "#D4AF37") ?? .yellow

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(ivory)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(jadeGreen.opacity(0.8))
                    .overlay {
                        Capsule()
                            .strokeBorder(gold.opacity(0.5), lineWidth: 1.5)
                    }
            }
            .shadow(color: jadeGreen.opacity(0.4), radius: 6)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "#1D4E3E")

        VStack(spacing: 40) {
            MahjongTileButton("Tap to\nStart", icon: "camera.fill") {
                print("Tapped!")
            }

            MahjongSecondaryButton("Gallery", icon: "photo.on.rectangle.angled") {
                print("Gallery")
            }
        }
    }
    .withTheme(.default)
}
