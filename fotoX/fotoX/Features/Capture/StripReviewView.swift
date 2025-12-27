//
//  StripReviewView.swift
//  fotoX
//
//  Review screen for a captured strip
//

import SwiftUI
import AVKit

/// View for reviewing a captured strip (video + photo)
// TODO: Revisit whether this view is still needed with auto-advance capture. Might be needed if we want to allow retakes.
struct StripReviewView: View {
    let stripIndex: Int
    let videoURL: URL
    let photoData: Data
    let onRetake: () -> Void
    let onContinue: () -> Void
    let isLastStrip: Bool
    
    @State private var showingVideo = true
    @State private var player: AVPlayer?
    
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
            player = AVPlayer(url: videoURL)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Strip \(stripIndex + 1) of 3")
                .font(.headline)
                .foregroundStyle(theme.accent.opacity(0.7))
            
            Text("Review Your Capture")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accent)
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
                    .onAppear {
                        player.play()
                    }
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
