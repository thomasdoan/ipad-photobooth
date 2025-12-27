//
//  FrameOverlayView.swift
//  fotoX
//
//  Custom frame overlay with couple's names and event details
//

import SwiftUI

/// Frame overlay that displays decorative frame image with text overlays
struct FrameOverlayView: View {
    let event: Event?
    let showTextOverlays: Bool

    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var themeAssets

    var body: some View {
        ZStack {
            // Decorative frame image (if available)
            if let frame = themeAssets?.photoFrame {
                frame
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Text overlays (if enabled and event available)
            if showTextOverlays, let event = event {
                VStack {
                    // Top: Couple's names
                    if let coupleNames = event.coupleDisplayName {
                        Text(coupleNames)
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                            .padding(.top, 40)
                    }

                    Spacer()

                    // Bottom: Date and hashtag
                    VStack(spacing: 8) {
                        Text(event.displayDate)
                            .font(.system(size: 24, weight: .semibold, design: .serif))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)

                        if let hashtag = event.hashtag {
                            Text(hashtag)
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.primary)
                                .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    let sampleEvent = Event(
        id: 1,
        name: "Wedding Shower",
        date: "2026-01-31",
        theme: Theme(
            id: 1,
            primaryColor: "#FF4081",
            secondaryColor: "#212121",
            accentColor: "#FFFFFF",
            fontFamily: "system",
            logoURL: nil,
            backgroundURL: nil,
            photoFrameURL: nil,
            stripFrameURL: nil
        ),
        coupleName1: "Jack",
        coupleName2: "Zeu",
        hashtag: "#JackZeu2026"
    )

    ZStack {
        Color.gray
        FrameOverlayView(event: sampleEvent, showTextOverlays: true)
    }
    .withTheme(.default)
}
