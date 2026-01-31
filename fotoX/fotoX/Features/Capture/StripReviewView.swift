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
            countdownTask = nil
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
        countdownTask?.cancel()
        countdownTask = nil
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
        
        return ZStack {
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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20)
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
    @Binding var selectedFrameAssetName: String?
    let onCompositeRendered: (CompositeStripAssets?) -> Void
    
    @Environment(AppState.self) private var appState
    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var themeAssets
    
    @State private var isProcessing = false
    @State private var isRenderingComposite = false
    @State private var compositePhotoData: Data?
    @State private var compositeVideoURL: URL?
    @State private var compositePlayerManager = VideoPlayerManager()
    @State private var compositePlayer: AVPlayer?
    @State private var renderTask: Task<Void, Never>?
    
    private var compositePlayerID: String { "summary-composite-video" }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                theme.secondary.ignoresSafeArea()
                
                HStack(alignment: .top, spacing: 0) {
                    // Left pane - Title + frame selector (50% width)
                    selectorPane
                        .frame(width: geometry.size.width * 0.5)
                    
                    // Right pane - Composite preview + upload (50% width)
                    previewPane(geometry: geometry)
                        .frame(width: geometry.size.width * 0.5)
                }
                .overlay(alignment: .center) {
                    Rectangle()
                        .fill(theme.accent.opacity(0.15))
                        .frame(width: 1)
                        .padding(.vertical, 32)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                
                // Interstitial loading overlay
                if isProcessing {
                    loadingOverlay
                }
            }
        }
        .onAppear {
            if selectedFrameAssetName == nil {
                // Default to the first loadable local frame option.
                if let first = FrameOption.availableFrames.first(where: { $0.loadFrameImage() != nil }) {
                    selectedFrameAssetName = first.frameName
                }
            }
            scheduleCompositeRender()
        }
        .onDisappear {
            renderTask?.cancel()
            renderTask = nil
            compositePlayerManager.stop(id: compositePlayerID)
            compositePlayer = nil
        }
        .onChange(of: selectedFrameAssetName) { _, _ in
            scheduleCompositeRender()
        }
    }

    @ViewBuilder
    private func previewPane(geometry: GeometryProxy) -> some View {
        let availableSize = CGSize(
            width: geometry.size.width * 0.5,
            height: max(geometry.size.height, 1)
        )
        let previewSize = compositePreviewSize(availableSize: availableSize)

        VStack(alignment: .center, spacing: 40) {
            Spacer()

            compositePreview(previewSize: previewSize)

            // Upload button directly under the composite
            Button(action: handleUpload) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Process & Upload")
                }
                .font(.title3.bold())
                .foregroundStyle(theme.secondary)
                .padding(.horizontal, 44)
                .padding(.vertical, 16)
                .background(Capsule().fill(theme.primary))
                .shadow(color: theme.primary.opacity(0.4), radius: 15, y: 5)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var selectorPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(theme.primary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select a frame!")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.accent)

                        Text("Select a frame for your captures before we process them")
                            .font(.body)
                            .foregroundStyle(theme.accent.opacity(0.7))
                    }
                }
            }

            FrameSelectorView(
                selectedFrame: $selectedFrameAssetName,
                strips: strips,
                slotAspectRatio: aspectRatio,
                footerText: stripFooterText()
            )

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            theme.secondary.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.accent))
                    .scaleEffect(2)
                
                Text("Processing your photos...")
                    .font(.title2.bold())
                    .foregroundStyle(theme.accent)
            }
        }
    }
    
    private func handleUpload() {
        isProcessing = true
        
        // Simulate brief processing delay before calling onFinish
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            onFinish()
        }
    }
    
    private func stripFooterText() -> String {
        theme.stripFooterText ?? appState.selectedEvent?.name ?? "FotoX"
    }

    private func compositePreviewSize(availableSize: CGSize) -> CGSize {
        let maxWidth = min(availableSize.width * 0.92, 720)
        let maxHeight = availableSize.height * 0.62
        return CGSize(width: maxWidth, height: maxHeight)
    }

    @ViewBuilder
    private func compositePreview(previewSize: CGSize) -> some View {
        HStack(spacing: 16) {
            // Video composite
            if let player = compositePlayer {
                QRLoopingVideoView(player: player)
                    .frame(maxWidth: previewSize.width / 2, maxHeight: previewSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: theme.secondary.opacity(0.3), radius: 8, y: 4)
            } else {
                videoUnavailablePlaceholder(maxWidth: previewSize.width / 2, maxHeight: previewSize.height)
            }
        }
        .overlay(alignment: .topLeading) {
            if isRenderingComposite {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                    Text("Rendering composite…")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accent.opacity(0.85))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(theme.secondary.opacity(0.55))
                        .overlay(
                            Capsule()
                                .stroke(theme.accent.opacity(0.18), lineWidth: 1)
                        )
                )
                .padding(10)
            }
        }
    }

    @ViewBuilder
    private func fallbackStripView(maxWidth: CGFloat, maxHeight: CGFloat) -> some View {
        let size = StripCompositeMetrics.sizeThatFits(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            slotCount: 3,
            slotAspectRatio: aspectRatio
        )
        StripCompositeView(
            slots: (0..<3).map { StripSlot(id: $0, isVideo: false) },
            footerText: stripFooterText(),
            slotAspectRatio: aspectRatio
        ) { slot in
            stripSlotContent(slot: slot)
        }
        .frame(width: size.width, height: size.height)
        .withTheme(theme, assets: effectiveThemeAssetsForFallback)
    }

    @ViewBuilder
    private func videoUnavailablePlaceholder(maxWidth: CGFloat, maxHeight: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(theme.secondary.opacity(0.2))
            .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "video.slash")
                        .font(.title)
                        .foregroundStyle(theme.accent.opacity(0.5))
                    Text(isRenderingComposite ? "Rendering video…" : "Video processing…")
                        .font(.caption)
                        .foregroundStyle(theme.accent.opacity(0.5))
                }
            }
            .shadow(color: theme.secondary.opacity(0.3), radius: 8, y: 4)
    }

    private var effectiveThemeAssetsForFallback: ThemeAssets? {
        guard let selectedFrameAssetName,
              let frame = FrameImageLoader.loadImage(named: selectedFrameAssetName) else {
            return themeAssets
        }
        return ThemeAssets(
            logo: themeAssets?.logo,
            background: themeAssets?.background,
            photoFrame: themeAssets?.photoFrame,
            stripFrame: frame
        )
    }

    @ViewBuilder
    private func stripSlotContent(slot: StripSlot) -> some View {
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

    private func scheduleCompositeRender() {
        renderTask?.cancel()
        renderTask = Task { @MainActor in
            await renderCompositeIfPossible()
        }
    }

    private func renderCompositeIfPossible() async {
        guard !strips.isEmpty else { return }

        isRenderingComposite = true
        defer { isRenderingComposite = false }

        let footerText = stripFooterText()
        do {
            let assets = try await StripCompositeRenderer.renderCompositeAssets(
                strips: strips,
                theme: theme,
                assets: themeAssets,
                footerText: footerText,
                customFrameAssetName: selectedFrameAssetName,
                slotAspectRatio: aspectRatio
            )

            compositePhotoData = assets.photoData
            compositeVideoURL = assets.videoURL
            appState.compositePhotoData = assets.photoData
            appState.compositeVideoURL = assets.videoURL
            onCompositeRendered(assets)

            if FileManager.default.fileExists(atPath: assets.videoURL.path) {
                compositePlayer = compositePlayerManager.play(
                    id: compositePlayerID,
                    url: assets.videoURL,
                    fromStart: true,
                    loop: true
                )
            } else {
                compositePlayerManager.stop(id: compositePlayerID)
                compositePlayer = nil
            }
        } catch {
            // If composite fails, fall back to the live StripCompositeView preview.
            compositePhotoData = nil
            compositeVideoURL = nil
            appState.compositePhotoData = nil
            appState.compositeVideoURL = nil
            compositePlayerManager.stop(id: compositePlayerID)
            compositePlayer = nil
            onCompositeRendered(nil)
        }
    }
}
