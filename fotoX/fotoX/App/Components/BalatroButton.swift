//
//  BalatroButton.swift
//  fotoX
//
//  Balatro-themed buttons with neon glow and CRT aesthetics
//

import SwiftUI

/// Balatro chip-styled primary button with neon magenta gradient and cyan glow
struct BalatroChipButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var isPressed = false
    @State private var glowPulse = false

    // Balatro colors
    private let neonMagenta = Color(hex: "#FF2D6A") ?? .pink
    private let neonCyan = Color(hex: "#4DEEEA") ?? .cyan
    private let deepPurple = Color(hex: "#1a1a2e") ?? .purple
    private let gold = Color(hex: "#FFD700") ?? .yellow

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer cyan glow
                RoundedRectangle(cornerRadius: 20)
                    .fill(neonCyan.opacity(glowPulse ? 0.4 : 0.2))
                    .frame(width: 200, height: 200)
                    .blur(radius: glowPulse ? 30 : 20)

                // Main chip shape
                mainChip
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
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    private var mainChip: some View {
        ZStack {
            // Base rounded rectangle with magenta gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [neonMagenta, neonMagenta.opacity(0.8), neonMagenta.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 180)

            // Scanline overlay on button surface
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .frame(width: 180, height: 180)
                .overlay(
                    scanlinePattern
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                )

            // Inner dark area
            RoundedRectangle(cornerRadius: 12)
                .fill(deepPurple)
                .frame(width: 150, height: 150)

            // Gold accent border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [gold, gold.opacity(0.6), gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 150, height: 150)

            // Content
            VStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(neonCyan)
                }

                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(neonCyan)
                    .multilineTextAlignment(.center)
            }

            // Corner chip decorations
            chipCorners
        }
    }

    private var scanlinePattern: some View {
        Canvas { context, size in
            let lineSpacing: CGFloat = 4
            let lineCount = Int(size.height / lineSpacing)

            for i in 0..<lineCount {
                let y = CGFloat(i) * lineSpacing
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(rect), with: .color(.black.opacity(0.1)))
            }
        }
    }

    private var chipCorners: some View {
        ZStack {
            // Small chip indicators at corners
            ForEach(0..<4) { index in
                Circle()
                    .fill(gold.opacity(0.8))
                    .frame(width: 12, height: 12)
                    .offset(
                        x: index % 2 == 0 ? -70 : 70,
                        y: index < 2 ? -70 : 70
                    )
            }
        }
    }
}

/// Balatro secondary button with cyan stroke and dark fill
struct BalatroSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var isPressed = false

    private let neonCyan = Color(hex: "#4DEEEA") ?? .cyan
    private let deepPurple = Color(hex: "#1a1a2e") ?? .purple

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
            .foregroundStyle(neonCyan)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(deepPurple.opacity(0.8))
                    .overlay {
                        Capsule()
                            .strokeBorder(neonCyan.opacity(0.6), lineWidth: 2)
                    }
            }
            .shadow(color: neonCyan.opacity(0.3), radius: 8)
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
        Color(hex: "#0f0f1a")

        VStack(spacing: 40) {
            BalatroChipButton("Tap to\nStart", icon: "camera.fill") {
                print("Tapped!")
            }

            BalatroSecondaryButton("Gallery", icon: "photo.on.rectangle.angled") {
                print("Gallery")
            }
        }
    }
    .withTheme(.default)
}
