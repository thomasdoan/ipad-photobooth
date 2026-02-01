//
//  MahjongRecordingProgressView.swift
//  fotoX
//
//  Mahjong-themed recording progress with tile and dragon indicators
//

import SwiftUI

/// Mahjong-themed recording progress with tile-styled indicator
struct MahjongRecordingProgressView: View {
    let progress: Double
    let duration: TimeInterval
    let elapsed: TimeInterval

    @Environment(\.appTheme) private var theme
    @State private var glowPulse = false

    // Mahjong colors
    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green
    private let darkJade = Color(hex: "#0F2E24") ?? .black
    private let ivory = Color(hex: "#F5F5DC") ?? .white
    private let dragonRed = Color(hex: "#B22222") ?? .red
    private let gold = Color(hex: "#D4AF37") ?? .yellow

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(currentGlowColor.opacity(0.2))
                .frame(width: 170, height: 170)
                .blur(radius: glowPulse ? 25 : 15)

            // Base ring
            ringBase

            // Progress ring
            progressRing

            // Dragon milestone indicators
            dragonIndicators

            // Center content
            centerContent
        }
        .frame(width: 150, height: 150)
        .onAppear {
            startAnimations()
        }
    }

    private var currentGlowColor: Color {
        if progress >= 0.75 {
            return dragonRed
        } else if progress >= 0.5 {
            return gold
        } else {
            return jadeGreen
        }
    }

    // MARK: - Ring Base

    private var ringBase: some View {
        ZStack {
            // Jade base
            Circle()
                .fill(jadeGreen.opacity(0.35))
                .frame(width: 280, height: 280)

            // Inner darker circle
            Circle()
                .fill(darkJade.opacity(0.35))
                .frame(width: 220, height: 220)

            // Gold accent ring
            Circle()
                .strokeBorder(gold.opacity(0.2), lineWidth: 4)
                .frame(width: 210, height: 210)
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        // Background track
        Circle()
            .stroke(jadeGreen.opacity(0.5), lineWidth: 8)
            .frame(width: 130, height: 130)
    }

    // MARK: - Dragon Indicators

    private var dragonIndicators: some View {
        ZStack {
            // 25% - East
            dragonMilestone(symbol: "東", angle: 0, color: ivory.opacity(progress >= 0.25 ? 0.9 : 0.3))
            
            // 50% - Green Dragon
            dragonMilestone(symbol: "發", angle: 90, color: (progress >= 0.5 ? .green : .green.opacity(0.3)))
            
            // 75% - Red Dragon
            dragonMilestone(symbol: "中", angle: 180, color: dragonRed.opacity(progress >= 0.75 ? 1 : 0.3))
            
            // 100% - Gold
            dragonMilestone(symbol: "龍", angle: 270, color: gold.opacity(progress >= 1.0 ? 1 : 0.3))
        }
    }

    private func dragonMilestone(symbol: String, angle: Double, color: Color) -> some View {
        Text(symbol)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(color)
            .offset(y: -65)
            .rotationEffect(.degrees(angle))
            // Counter-rotate the text so it stays upright
            .overlay(
                Text(symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
                    .rotationEffect(.degrees(-angle))
                    .offset(
                        x: 65 * sin(angle * .pi / 180),
                        y: -65 * cos(angle * .pi / 180)
                    )
                    .opacity(0) // Hidden, using for positioning reference
            )
    }

    // MARK: - Center Content

    private var centerContent: some View {
        Text(timeString)
            .font(.system(size: 96, weight: .black, design: .rounded))
            .foregroundStyle(ivory.opacity(0.35))
            .contentTransition(.numericText())
    }

    // MARK: - Helpers

    private var timeString: String {
        let remaining = max(0, duration - elapsed)
        return "\(Int(ceil(remaining)))"
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
    }
}

/// Mahjong-themed recording badge
struct MahjongRecordingBadge: View {
    @Environment(\.appTheme) private var theme
    @State private var isAnimating = false

    private let jadeGreen = Color(hex: "#1D4E3E") ?? .green
    private let ivory = Color(hex: "#F5F5DC") ?? .white
    private let dragonRed = Color(hex: "#B22222") ?? .red
    private let gold = Color(hex: "#D4AF37") ?? .yellow

    var body: some View {
        HStack(spacing: 8) {
            // Pulsing red dragon
            Text("中")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(dragonRed)
                .opacity(isAnimating ? 1.0 : 0.5)

            Text("REC")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(ivory)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(jadeGreen.opacity(0.9))
                .overlay(
                    Capsule()
                        .strokeBorder(gold.opacity(0.5), lineWidth: 1.5)
                )
        )
        .shadow(color: jadeGreen.opacity(0.4), radius: 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#0F2E24")
        VStack(spacing: 40) {
            MahjongRecordingProgressView(
                progress: 0.65,
                duration: 5.0,
                elapsed: 3.25
            )
            MahjongRecordingBadge()
        }
    }
    .withTheme(.default)
}
