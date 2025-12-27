//
//  StripReviewView.swift
//  fotoX
//
//  Review screen for a captured strip
//

import SwiftUI
import AVKit

/// View for reviewing a captured strip (video + photo)
struct StripReviewView: View {
    let stripIndex: Int
    let stripCount: Int
    let videoURL: URL
    let photoData: Data
    let onRetake: () -> Void
    let onContinue: () -> Void

    var isLastStrip: Bool {
        stripIndex >= stripCount - 1
    }

    @State private var showingVideo = true
    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?

    @Environment(\.appTheme) private var theme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                theme.secondary.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Media preview
                    mediaPreview(geometry: geometry)

                    // Toggle buttons
                    mediaToggle

                    Spacer()

                    // Action buttons
                    actionButtons
                }
                .padding(32)
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }

    // MARK: - Player Setup

    private func setupPlayer() {
        let newPlayer = AVPlayer(url: videoURL)
        player = newPlayer

        // Set up looping
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { [weak newPlayer] _ in
            newPlayer?.seek(to: .zero)
            newPlayer?.play()
        }

        newPlayer.play()
    }

    private func cleanupPlayer() {
        player?.pause()
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        loopObserver = nil
        player = nil
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Strip \(stripIndex + 1) of \(stripCount)")
                .font(.headline)
                .foregroundStyle(theme.accent.opacity(0.7))

            Text("Your Video Clip")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accent)

            Text("A video is captured alongside each photo!")
                .font(.subheadline)
                .foregroundStyle(theme.accent.opacity(0.6))
        }
    }

    // MARK: - Media Preview

    private func mediaPreview(geometry: GeometryProxy) -> some View {
        let previewHeight = geometry.size.height * 0.5

        return ZStack {
            if showingVideo, let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(9/16, contentMode: .fit)
                    .frame(maxHeight: previewHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else if let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: previewHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 20)
    }

    // MARK: - Media Toggle

    private var mediaToggle: some View {
        HStack(spacing: 0) {
            toggleButton(title: "Video", icon: "video.fill", isSelected: showingVideo) {
                withAnimation {
                    showingVideo = true
                    player?.seek(to: .zero)
                    player?.play()
                }
            }

            toggleButton(title: "Photo", icon: "photo.fill", isSelected: !showingVideo) {
                withAnimation {
                    showingVideo = false
                    player?.pause()
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.secondary.opacity(0.5))
        )
    }

    private func toggleButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.bold())
            .foregroundStyle(isSelected ? theme.secondary : theme.accent.opacity(0.7))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? theme.primary : Color.clear)
            )
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 24) {
            // Retake button
            Button(action: onRetake) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Retake")
                }
                .font(.headline)
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .stroke(theme.accent.opacity(0.5), lineWidth: 2)
                )
            }

            // Continue button
            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text(isLastStrip ? "Finish" : "Continue")
                    Image(systemName: isLastStrip ? "checkmark" : "arrow.right")
                }
                .font(.headline)
                .foregroundStyle(theme.secondary)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(theme.primary)
                )
                .shadow(color: theme.primary.opacity(0.4), radius: 10, y: 4)
            }
        }
        .padding(.bottom, 20)
    }
}

/// Summary view showing all captured strips before upload
struct CaptureSummaryView: View {
    let strips: [CapturedStrip]
    let onRetake: (Int) -> Void
    let onFinish: () -> Void
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                theme.secondary.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(theme.primary)
                        
                        Text("All Done!")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.accent)
                        
                        Text("Review your captures before we process them")
                            .font(.body)
                            .foregroundStyle(theme.accent.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Strip thumbnails
                    HStack(spacing: 16) {
                        ForEach(strips, id: \.stripIndex) { strip in
                            stripThumbnail(strip: strip, geometry: geometry)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    // Finish button
                    Button(action: onFinish) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Process & Upload")
                        }
                        .font(.title3.bold())
                        .foregroundStyle(theme.secondary)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(theme.primary)
                        )
                        .shadow(color: theme.primary.opacity(0.4), radius: 15, y: 5)
                    }
                    .padding(.bottom, 60)
                }
            }
        }
    }
    
    private func stripThumbnail(strip: CapturedStrip, geometry: GeometryProxy) -> some View {
        let width = (geometry.size.width - 96) / 3
        
        return VStack(spacing: 12) {
            // Thumbnail
            if let uiImage = UIImage(data: strip.photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(9/16, contentMode: .fill)
                    .frame(width: width, height: width * 16/9 * 0.6)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.primary.opacity(0.5), lineWidth: 2)
                    )
            }
            
            // Label
            Text("Strip \(strip.stripIndex + 1)")
                .font(.caption.bold())
                .foregroundStyle(theme.accent.opacity(0.7))
            
            // Retake button
            Button {
                onRetake(strip.stripIndex)
            } label: {
                Text("Retake")
                    .font(.caption2)
                    .foregroundStyle(theme.accent.opacity(0.6))
            }
        }
    }
}
