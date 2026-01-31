//
//  BalatroRecordingProgressView.swift
//  fotoX
//
//  Balatro-themed recording progress with chips + mult display
//

import SwiftUI

/// Balatro-themed recording progress with chips/mult indicator
struct BalatroRecordingProgressView: View {
    let progress: Double
    let duration: TimeInterval
    let elapsed: TimeInterval

    @Environment(\.appTheme) private var theme
    @State private var glowPulse = false
    @State private var sparkAngle: Double = 0

    // Balatro colors
    private let deepPurple = Color(hex: "#1a1a2e") ?? .purple
    private let neonMagenta = Color(hex: "#FF2D6A") ?? .pink
    private let neonCyan = Color(hex: "#4DEEEA") ?? .cyan
    private let gold = Color(hex: "#FFD700") ?? .yellow

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(currentGlowColor.opacity(0.2))
                .frame(width: 170, height: 170)
                .blur(radius: glowPulse ? 25 : 15)

            // Base ring
            ringBase

            // Progress ring (cyan → magenta gradient)
            progressRing

            // Spark at progress point
            sparkIndicator

            // Center content (chips + mult)
            centerContent
        }
        .frame(width: 150, height: 150)
        .onAppear {
            startAnimations()
        }
    }

    private var currentGlowColor: Color {
        if progress >= 0.75 {
            return neonMagenta
        } else if progress >= 0.5 {
            return gold
        } else {
            return neonCyan
        }
    }

    // MARK: - Ring Base

    private var ringBase: some View {
        ZStack {
            // Dark purple base
            Circle()
                .fill(deepPurple)
                .frame(width: 140, height: 140)

            // Inner darker circle
            Circle()
                .fill(Color(hex: "#0f0f1a") ?? .black)
                .frame(width: 110, height: 110)

            // Gold accent ring
            Circle()
                .strokeBorder(gold.opacity(0.3), lineWidth: 2)
                .frame(width: 105, height: 105)
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(deepPurple.opacity(0.5), lineWidth: 8)
                .frame(width: 130, height: 130)

            // Progress arc with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [neonCyan, neonMagenta, neonCyan],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
        }
    }

    // MARK: - Spark Indicator

    private var sparkIndicator: some View {
        ZStack {
            // Spark glow
            Circle()
                .fill(neonCyan)
                .frame(width: 14, height: 14)
                .blur(radius: 4)

            // Spark core
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
        }
        .offset(y: -65)
        .rotationEffect(.degrees(-90 + (progress * 360)))
        .opacity(progress > 0 ? 1 : 0)
    }

    // MARK: - Center Content

    private var centerContent: some View {
        VStack(spacing: 4) {
            // CHIPS label and value
            Text("CHIPS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(neonCyan.opacity(0.7))

            Text("\(chipsValue)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(neonCyan)
                .contentTransition(.numericText())

            // Mult indicator
            HStack(spacing: 2) {
                Text("x")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(neonMagenta.opacity(0.8))
                Text("\(multValue)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(neonMagenta)
                    .contentTransition(.numericText())
            }
            .scaleEffect(multValue > 1 ? (glowPulse ? 1.1 : 1.0) : 1.0)
        }
    }

    // MARK: - Computed Values

    private var chipsValue: Int {
        Int(progress * 100)
    }

    private var multValue: Int {
        if progress >= 1.0 {
            return 4
        } else if progress >= 0.75 {
            return 3
        } else if progress >= 0.5 {
            return 2
        } else if progress >= 0.25 {
            return 1
        } else {
            return 1
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Glow pulse
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
    }
}

/// Balatro-themed recording badge
struct BalatroRecordingBadge: View {
    @Environment(\.appTheme) private var theme
    @State private var isAnimating = false

    private let deepPurple = Color(hex: "#1a1a2e") ?? .purple
    private let neonMagenta = Color(hex: "#FF2D6A") ?? .pink
    private let neonCyan = Color(hex: "#4DEEEA") ?? .cyan

    var body: some View {
        HStack(spacing: 8) {
            // Pulsing joker icon
            Image(systemName: "face.smiling.inverse")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(neonMagenta)
                .opacity(isAnimating ? 1.0 : 0.5)

            Text("REC")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(neonCyan)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(deepPurple.opacity(0.9))
                .overlay(
                    Capsule()
                        .strokeBorder(neonMagenta.opacity(0.6), lineWidth: 2)
                )
        )
        .shadow(color: neonMagenta.opacity(0.3), radius: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0f0f1a")
        VStack(spacing: 40) {
            BalatroRecordingProgressView(
                progress: 0.65,
                duration: 5.0,
                elapsed: 3.25
            )
            BalatroRecordingBadge()
        }
    }
    .withTheme(.default)
}
