//
//  CasinoRecordingProgressView.swift
//  fotoX
//
//  Casino-themed recording progress indicator with chip/roulette animation
//

import SwiftUI

/// Casino-themed recording progress with poker chip fill animation
struct CasinoRecordingProgressView: View {
    let progress: Double /// 0.0 to 1.0
    let duration: TimeInterval
    let elapsed: TimeInterval
    
    @Environment(\.appTheme) private var theme
    @State private var rotationAngle: Double = 0
    @State private var glowPulse = false
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(theme.accent.opacity(0.15))
                .frame(width: 160, height: 160)
                .blur(radius: glowPulse ? 20 : 10)
            
            // Poker chip base
            chipBase
            
            // Progress ring (like roulette wheel spinning)
            progressRing
            
            // Center content
            centerContent
        }
        .frame(width: 140, height: 140)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Chip Base
    
    private var chipBase: some View {
        ZStack {
            // Outer chip ring
            Circle()
                .fill(
                    LinearGradient(
                        colors: [theme.secondary, theme.secondary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 130, height: 130)
            
            // Ridged edge pattern (like poker chip)
            ForEach(0..<16) { index in
                Rectangle()
                    .fill(theme.accent.opacity(0.5))
                    .frame(width: 4, height: 10)
                    .offset(y: -60)
                    .rotationEffect(.degrees(Double(index) * 22.5))
            }
            
            // Inner dark circle
            Circle()
                .fill(Color(hex: "#0A3D22") ?? theme.secondary)
                .frame(width: 100, height: 100)
            
            // Gold inner ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [theme.accent, theme.accent.opacity(0.6), theme.accent],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 90, height: 90)
        }
    }
    
    // MARK: - Progress Ring
    
    private var progressRing: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(theme.accent.opacity(0.2), lineWidth: 6)
                .frame(width: 115, height: 115)
            
            // Progress arc with spinning effect
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [theme.primary, theme.accent, theme.primary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 115, height: 115)
                .rotationEffect(.degrees(-90 + rotationAngle))
                .animation(.linear(duration: 0.1), value: progress)
            
            // Spinning marker (like roulette ball)
            Circle()
                .fill(theme.accent)
                .frame(width: 10, height: 10)
                .offset(y: -57.5)
                .rotationEffect(.degrees(-90 + (progress * 360)))
                .shadow(color: theme.accent.opacity(0.5), radius: 4)
        }
    }
    
    // MARK: - Center Content
    
    private var centerContent: some View {
        VStack(spacing: 4) {
            // Animated dice or suits
            HStack(spacing: 6) {
                Image(systemName: "suit.diamond.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.primary)
                    .opacity(progress > 0.33 ? 1 : 0.3)
                
                Image(systemName: "suit.heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.primary)
                    .opacity(progress > 0.66 ? 1 : 0.3)
                
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.accent)
                    .opacity(progress >= 1.0 ? 1 : 0.3)
            }
            
            // Time remaining
            Text(timeString)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.accent)
        }
    }
    
    // MARK: - Helpers
    
    private var timeString: String {
        let remaining = max(0, duration - elapsed)
        return String(format: "%.1f", remaining)
    }
    
    private func startAnimations() {
        // Glow pulse
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
        
        // Subtle rotation effect
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

/// Casino-themed recording badge
struct CasinoRecordingBadge: View {
    @Environment(\.appTheme) private var theme
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Pulsing diamond instead of circle
            Image(systemName: "suit.diamond.fill")
                .font(.system(size: 12))
                .foregroundStyle(theme.primary)
                .opacity(isAnimating ? 1.0 : 0.5)
            
            Text("REC")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(hex: "#0A3D22")?.opacity(0.9) ?? theme.secondary.opacity(0.9))
                .overlay(
                    Capsule()
                        .strokeBorder(theme.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 40) {
            CasinoRecordingProgressView(
                progress: 0.65,
                duration: 5.0,
                elapsed: 3.25
            )
            CasinoRecordingBadge()
        }
    }
    .withTheme(.default)
}
