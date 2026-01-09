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
    let stripCount: Int
    let videoURL: URL
    let photoData: Data
    let onRetake: () -> Void
    let onContinue: () -> Void
    let isLastStrip: Bool
    let showsReviewControls: Bool
    let autoAdvanceSeconds: Int
    
    @State private var playerManager = VideoPlayerManager()
    @State private var player: AVPlayer?
    
    @Environment(\.appTheme) private var theme
    
    private var playerID: String {
        "strip-review-\(stripIndex)"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                theme.secondary.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    autoAdvanceLabel

                    // Media preview
                    mediaPreview(geometry: geometry)
                    
                    Spacer()
                    
                    // Action buttons
                    if showsReviewControls {
                        actionButtons
                    }
                }
                .padding(32)
            }
        }
        .onAppear {
            startPlayback(fromStart: true)
        }
        .onDisappear {
            playerManager.stop(id: playerID)
            player = nil
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Strip \(stripIndex + 1) of \(stripCount)")
                .font(.headline)
                .foregroundStyle(theme.accent.opacity(0.7))
            
            Text("Review Your Capture")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accent)
        }
    }
    
    private var autoAdvanceLabel: some View {
        Text("Auto-advancing in \(autoAdvanceSeconds)s")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.accent.opacity(0.7))
    }

    // MARK: - Media Preview
    
    private func mediaPreview(geometry: GeometryProxy) -> some View {
        let previewHeight = geometry.size.height * 0.5
        let previewWidth = geometry.size.width * 0.42
        
        return ViewThatFits {
            HStack(spacing: 20) {
                videoPreview(maxHeight: previewHeight)
                    .frame(maxWidth: previewWidth)
                photoPreview(maxHeight: previewHeight)
                    .frame(maxWidth: previewWidth)
            }
            VStack(spacing: 20) {
                videoPreview(maxHeight: previewHeight)
                photoPreview(maxHeight: previewHeight * 0.7)
            }
        }
    }
    
    // MARK: - Video Playback
    
    private func startPlayback(fromStart: Bool) {
        player = playerManager.play(id: playerID, url: videoURL, fromStart: fromStart)
    }
    
    private func videoPreview(maxHeight: CGFloat) -> some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(9/16, contentMode: .fit)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.accent))
            }
        }
        .frame(maxHeight: maxHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 20)
    }

    private func photoPreview(maxHeight: CGFloat) -> some View {
        ZStack {
            if let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.black.opacity(0.2)
            }
        }
        .frame(maxHeight: maxHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 20)
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
