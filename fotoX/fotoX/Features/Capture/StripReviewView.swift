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
    let aspectRatio: CGFloat
    let onRetake: () -> Void
    let onContinue: () -> Void
    let isLastStrip: Bool
    let showsReviewControls: Bool
    let showsAutoAdvanceLabel: Bool
    let autoAdvanceSeconds: Int
    
    @State private var playerManager = VideoPlayerManager()
    @State private var player: AVPlayer?
    @State private var showingVideo = true
    @State private var remainingSeconds: Int
    @State private var countdownTask: Task<Void, Never>?

    init(
        stripIndex: Int,
        stripCount: Int,
        videoURL: URL,
        photoData: Data,
        aspectRatio: CGFloat,
        onRetake: @escaping () -> Void,
        onContinue: @escaping () -> Void,
        isLastStrip: Bool,
        showsReviewControls: Bool,
        showsAutoAdvanceLabel: Bool,
        autoAdvanceSeconds: Int
    ) {
        self.stripIndex = stripIndex
        self.stripCount = stripCount
        self.videoURL = videoURL
        self.photoData = photoData
        self.aspectRatio = aspectRatio
        self.onRetake = onRetake
        self.onContinue = onContinue
        self.isLastStrip = isLastStrip
        self.showsReviewControls = showsReviewControls
        self.showsAutoAdvanceLabel = showsAutoAdvanceLabel
        self.autoAdvanceSeconds = autoAdvanceSeconds
        self._remainingSeconds = State(initialValue: autoAdvanceSeconds)
    }
    
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
                    
                    if showsAutoAdvanceLabel {
                        autoAdvanceLabel
                    }

                    // Media preview
                    mediaPreview(geometry: geometry)
                    
                    // Toggle between video and photo
                    mediaToggle
                        .padding(.top, 16)
                    
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
            if showsAutoAdvanceLabel {
                startCountdown()
            }
        }
        .onDisappear {
            playerManager.stop(id: playerID)
            player = nil
            countdownTask?.cancel()
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
        Text("Auto-advancing in \(remainingSeconds)s")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.accent.opacity(0.7))
    }

    private func startCountdown() {
        countdownTask = Task { @MainActor in
            while remainingSeconds > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled {
                    remainingSeconds -= 1
                }
            }
        }
    }

    // MARK: - Media Preview
    
    private func mediaPreview(geometry: GeometryProxy) -> some View {
        let previewHeight = geometry.size.height * 0.5
        
        return ThemedStripFrame {
            ZStack {
                theme.secondary.opacity(0.4)

                if showingVideo, let player = player {
                    VideoPlayer(player: player)
                        .aspectRatio(aspectRatio, contentMode: .fit)
                } else if let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(maxHeight: previewHeight)
        }
    }
    
    // MARK: - Media Toggle
    
    private var mediaToggle: some View {
        HStack(spacing: 0) {
            toggleButton(title: "Video", icon: "video.fill", isSelected: showingVideo) {
                withAnimation {
                    showingVideo = true
                }
            }
            
            toggleButton(title: "Photo", icon: "photo.fill", isSelected: !showingVideo) {
                withAnimation {
                    showingVideo = false
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.secondary.opacity(0.5))
        )
    }

    private func toggleButton(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? theme.secondary : theme.accent.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? theme.accent : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Video Playback
    
    private func startPlayback(fromStart: Bool) {
        player = playerManager.play(id: playerID, url: videoURL, fromStart: fromStart)
    }
    
    private func videoPreview(maxHeight: CGFloat) -> some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(aspectRatio, contentMode: .fit)
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
@MainActor
struct CaptureSummaryView: View {
    let strips: [CapturedStrip]
    let onRetake: (Int) -> Void
    let onFinish: () -> Void
    let aspectRatio: CGFloat
    
    @Environment(AppState.self) private var appState
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
                
                // Strip composite
                StripCompositeView(
                    slots: stripSlots(),
                    footerText: stripFooterText(),
                    slotAspectRatio: aspectRatio
                ) { slot in
                    stripSlotContent(slot: slot, strips: strips)
                }
                .frame(width: stripSize(for: geometry).width, height: stripSize(for: geometry).height)

                HStack(spacing: 12) {
                    ForEach(stripSlots()) { slot in
                        Button {
                            onRetake(slot.id)
                        } label: {
                            Text("Retake \(slot.id + 1)")
                                .font(.caption2.bold())
                                .foregroundStyle(theme.accent.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                
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
    
    private func stripSlots() -> [StripSlot] {
        (0..<3).map { StripSlot(id: $0, isVideo: false) }
    }

    private func stripFooterText() -> String {
        theme.stripFooterText ?? appState.selectedEvent?.name ?? "FotoX"
    }

    private func stripSize(for geometry: GeometryProxy) -> CGSize {
        let maxWidth = min(geometry.size.width * 0.6, 320)
        let maxHeight = geometry.size.height * 0.55
        return StripCompositeMetrics.sizeThatFits(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            slotCount: 3,
            slotAspectRatio: aspectRatio
        )
    }

    @ViewBuilder
    private func stripSlotContent(slot: StripSlot, strips: [CapturedStrip]) -> some View {
        if let strip = strips.first(where: { $0.stripIndex == slot.id }),
           let uiImage = UIImage(data: strip.photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(aspectRatio, contentMode: .fill)
        } else {
            ZStack {
                theme.secondary.opacity(0.4)
                Image(systemName: "photo")
                    .foregroundStyle(theme.accent.opacity(0.5))
            }
        }
    }
}
