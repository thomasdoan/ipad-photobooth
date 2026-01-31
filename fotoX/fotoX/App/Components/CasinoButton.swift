//
//  CasinoButton.swift
//  fotoX
//
//  Poker chip-styled button for casino theme
//

import SwiftUI

/// Poker chip-styled button with ridged edges and stacked shadow
struct CasinoChipButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @Environment(\.appTheme) private var theme
    @State private var isPressed = false
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Stacked chip shadow
                chipShape(offset: 6, color: theme.primary.opacity(0.3))
                chipShape(offset: 4, color: theme.primary.opacity(0.5))
                chipShape(offset: 2, color: theme.primary.opacity(0.7))
                
                // Main chip
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
    }
    
    private func chipShape(offset: CGFloat, color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 180, height: 180)
            .offset(y: offset)
    }
    
    private var mainChip: some View {
        ZStack {
            // Outer chip ring
            Circle()
                .fill(
                    LinearGradient(
                        colors: [theme.primary, theme.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 180)
            
            // Ridged edge pattern
            ForEach(0..<24) { index in
                Rectangle()
                    .fill(theme.accent.opacity(0.6))
                    .frame(width: 4, height: 12)
                    .offset(y: -84)
                    .rotationEffect(.degrees(Double(index) * 15))
            }
            
            // Inner circle
            Circle()
                .fill(theme.secondary)
                .frame(width: 140, height: 140)
            
            // Gold ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [theme.accent, theme.accent.opacity(0.7), theme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 130, height: 130)
            
            // Content
            VStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(theme.accent)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accent)
                    .multilineTextAlignment(.center)
            }
            
            // Shine effect
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: 140, height: 140)
                .mask {
                    Circle()
                        .frame(width: 60, height: 60)
                        .offset(x: -30, y: -30)
                }
        }
    }
}

/// Smaller casino button for secondary actions
struct CasinoSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @Environment(\.appTheme) private var theme
    @State private var isPressed = false
    
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
            .foregroundStyle(theme.accent.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(Color(hex: "#0D4D2B")?.opacity(0.8) ?? theme.secondary.opacity(0.5))
                    .overlay {
                        Capsule()
                            .strokeBorder(theme.accent.opacity(0.3), lineWidth: 1)
                    }
            }
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
        Color.black
        
        VStack(spacing: 40) {
            CasinoChipButton("Tap to\nStart", icon: "camera.fill") {
                print("Tapped!")
            }
            
            CasinoSecondaryButton("Gallery", icon: "photo.on.rectangle.angled") {
                print("Gallery")
            }
        }
    }
    .withTheme(.default)
}
