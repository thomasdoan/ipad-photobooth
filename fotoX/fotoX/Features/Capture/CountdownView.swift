//
//  CountdownView.swift
//  fotoX
//
//  Animated countdown overlay for capture
//

import SwiftUI

/// Animated countdown display
struct CountdownView: View {
    let number: Int
    let isPhotoCountdown: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Countdown number
            VStack(spacing: 16) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(theme.primary.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                    
                    // Number circle
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 150, height: 150)
                        .shadow(color: theme.primary.opacity(0.5), radius: 20)
                    
                    Text("\(number)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.secondary)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                if isPhotoCountdown {
                    Text("Smile!")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .opacity(opacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .onChange(of: number) { _, _ in
            // Reset and animate for each new number
            scale = 0.5
            opacity = 0
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

/// Progress ring for recording duration
struct RecordingProgressView: View {
    let progress: Double
    let duration: TimeInterval
    let elapsed: TimeInterval
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(theme.secondary.opacity(0.3), lineWidth: 8)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    theme.primary,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            
            // Time remaining
            VStack(spacing: 4) {
                Image(systemName: "record.circle")
                    .font(.title)
                    .foregroundStyle(theme.primary)
                    .symbolEffect(.pulse)
                
                Text(timeString)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 120, height: 120)
    }
    
    private var timeString: String {
        let remaining = max(0, duration - elapsed)
        return String(format: "%.1f", remaining)
    }
}

/// Recording indicator badge
struct RecordingBadge: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 12, height: 12)
                .opacity(isAnimating ? 1.0 : 0.5)
            
            Text("REC")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.black.opacity(0.6))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

/// Flash effect for photo capture
struct PhotoFlashView: View {
    @Binding var isFlashing: Bool
    
    var body: some View {
        Color.white
            .ignoresSafeArea()
            .opacity(isFlashing ? 1 : 0)
            .animation(.easeOut(duration: 0.15), value: isFlashing)
            .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black
        CountdownView(number: 3, isPhotoCountdown: false)
    }
    .withTheme(.default)
}

