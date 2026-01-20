//
//  QRView.swift
//  fotoX
//
//  QR code display and email submission screen
//

import SwiftUI
import AVFoundation

/// Screen showing QR code and email input
struct QRView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var themeAssets
    let services: ServiceContainer
    let testableServices: TestableServiceContainer
    
    @State private var viewModel: QRViewModel<LocalSessionService>?
    @State private var showDoneAnimation = false
    @State private var autoReturnTimer: Timer?
    @State private var videoPlayerManager = VideoPlayerManager()
    @State private var videoPlayer: AVPlayer?
    
    /// Auto-return delay in seconds
    private let autoReturnDelay: TimeInterval = 60
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 80 // 40pt padding each side
            let availableHeight = geometry.size.height - 80 // 40pt padding top/bottom

            ZStack {
                // Themed background
                backgroundLayer

                VStack(spacing: 24) {
                    // Logo at top
                    logoSection

                    // Main content: side-by-side layout
                    HStack(alignment: .center, spacing: 40) {
                        // Left panel: Photo and video composites stacked
                        leftPanel(availableWidth: availableWidth, availableHeight: availableHeight)

                        // Right panel: QR code and controls
                        rightPanel(availableWidth: availableWidth, availableHeight: availableHeight)
                    }
                }
                .padding(40)

                // Hidden settings trigger
                settingsTrigger
            }
        }
        .task {
            setupViewModel()
            startAutoReturnTimer()
            await startVideoPlayback()
        }
        .onDisappear {
            autoReturnTimer?.invalidate()
        }
    }

    // MARK: - Composite URL Helpers

    private var compositePhotoURL: URL? {
        guard let sessionId = appState.currentSession?.sessionId else { return nil }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents
            .appendingPathComponent("Uploads")
            .appendingPathComponent(sessionId)
            .appendingPathComponent(CompositeStripAssets.photoFileName)
    }

    private var compositeVideoURL: URL? {
        guard let sessionId = appState.currentSession?.sessionId else { return nil }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents
            .appendingPathComponent("Uploads")
            .appendingPathComponent(sessionId)
            .appendingPathComponent(CompositeStripAssets.videoFileName)
    }

    // MARK: - Left Panel (Composites)

    @ViewBuilder
    private func leftPanel(availableWidth: CGFloat, availableHeight: CGFloat) -> some View {
        let panelWidth = availableWidth * 0.55
        let panelHeight = availableHeight - 100 // Account for logo
        let stripHeight = panelHeight // Full height since strips are side by side

        HStack(spacing: 16) {
            // Photo composite
            if let photoURL = compositePhotoURL,
               FileManager.default.fileExists(atPath: photoURL.path) {
                QRCompositeImageView(imageURL: photoURL)
                    .frame(maxWidth: panelWidth, maxHeight: stripHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: theme.secondary.opacity(0.3), radius: 8, y: 4)
            } else {
                // Fallback to current strip composite view
                fallbackStripView(maxWidth: panelWidth, maxHeight: stripHeight)
            }

            // Video composite
            if let player = videoPlayer {
                QRLoopingVideoView(player: player)
                    .frame(maxWidth: panelWidth, maxHeight: stripHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: theme.secondary.opacity(0.3), radius: 8, y: 4)
            } else {
                // Video not available placeholder
                videoUnavailablePlaceholder(maxWidth: panelWidth, maxHeight: stripHeight)
            }
        }
    }

    @ViewBuilder
    private func fallbackStripView(maxWidth: CGFloat, maxHeight: CGFloat) -> some View {
        let strips = appState.capturedStrips
        if !strips.isEmpty {
            let size = StripCompositeMetrics.sizeThatFits(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                slotCount: 3,
                slotAspectRatio: stripAspectRatio
            )
            StripCompositeView(
                slots: stripSlots(),
                footerText: stripFooterText(),
                slotAspectRatio: stripAspectRatio
            ) { slot in
                stripSlotContent(slot: slot, strips: strips)
            }
            .frame(width: size.width, height: size.height)
        }
    }

    @ViewBuilder
    private func videoUnavailablePlaceholder(maxWidth: CGFloat, maxHeight: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(theme.secondary.opacity(0.2))
            .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "video.slash")
                        .font(.title)
                        .foregroundStyle(theme.accent.opacity(0.5))
                    Text("Video processing...")
                        .font(.caption)
                        .foregroundStyle(theme.accent.opacity(0.5))
                }
            }
    }

    // MARK: - Right Panel (QR + Controls)

    @ViewBuilder
    private func rightPanel(availableWidth: CGFloat, availableHeight: CGFloat) -> some View {
        let panelWidth = availableWidth * 0.42

        VStack(spacing: 20) {
            Spacer()

            // QR Code section
            qrCodeSection(maxWidth: panelWidth)

            // URL display
            urlSection

            // Upload status
            uploadStatusSection

            // Email section
            if let viewModel = viewModel {
                emailSection(viewModel: viewModel)
            }

            // Done button
            doneButton

            Spacer()
        }
        .frame(maxWidth: panelWidth)
    }

    private var stripAspectRatio: CGFloat {
        appState.resolvedCaptureAspectRatio.widthToHeight
    }

    private func stripSlots() -> [StripSlot] {
        (0..<3).map { StripSlot(id: $0, isVideo: false) }
    }

    private func stripFooterText() -> String {
        theme.stripFooterText ?? appState.selectedEvent?.name ?? "FotoX"
    }

    @ViewBuilder
    private func stripSlotContent(slot: StripSlot, strips: [CapturedStrip]) -> some View {
        if let strip = strips.first(where: { $0.stripIndex == slot.id }),
           let image = UIImage(data: strip.photoData) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                theme.secondary.opacity(0.4)
                Image(systemName: "photo")
                    .foregroundStyle(theme.accent.opacity(0.5))
            }
        }
    }

    // MARK: - Background
    
    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [theme.secondary, theme.secondary.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if let background = themeAssets?.background {
                background
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.3)
            }
            
            // Decorative circles
            Circle()
                .fill(theme.primary.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: -150, y: -100)
            
            Circle()
                .fill(theme.accent.opacity(0.05))
                .frame(width: 250, height: 250)
                .blur(radius: 40)
                .offset(x: 150, y: 200)
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            if let logo = themeAssets?.logo {
                logo
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 80)
            }
            
            if let event = appState.selectedEvent {
                Text(event.name)
                    .font(.title2.bold())
                    .foregroundStyle(theme.accent)
            }
        }
    }
    
    // MARK: - QR Code Section

    private func qrCodeSection(maxWidth: CGFloat) -> some View {
        // Smaller QR code: 180pt max or 50% of panel width
        let qrSize = min(maxWidth * 0.5, 180.0)

        return VStack(spacing: 16) {
            Text("Scan to view your photos")
                .font(.headline)
                .foregroundStyle(theme.accent.opacity(0.8))

            if let qrImage = viewModel?.qrImage {
                // QR Code
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: qrSize, height: qrSize)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            } else if viewModel?.isLoadingQR == true {
                // Loading
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .frame(width: qrSize + 32, height: qrSize + 32)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                        .scaleEffect(1.2)
                }
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            } else {
                // Error state with retry
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .frame(width: qrSize + 32, height: qrSize + 32)

                    VStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)

                        Text("QR code unavailable")
                            .font(.caption)
                            .foregroundStyle(.gray)

                        Button("Retry") {
                            Task {
                                if let sessionId = appState.currentSession?.sessionId {
                                    await viewModel?.fetchQRIfNeeded(sessionId: sessionId)
                                }
                            }
                        }
                        .font(.caption.bold())
                        .foregroundStyle(theme.primary)
                    }
                }
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            }
        }
    }
    
    // MARK: - URL Section
    
    private var urlSection: some View {
        Group {
            if let url = viewModel?.universalURL, !url.isEmpty {
                VStack(spacing: 8) {
                    Text("Or visit:")
                        .font(.caption)
                        .foregroundStyle(theme.accent.opacity(0.6))
                    
                    Text(url)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(theme.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.secondary.opacity(0.5))
                        )
                }
            }
        }
    }

    private var uploadStatusSection: some View {
        Group {
            if appState.totalAssetsToUpload > 0 {
                let remaining = appState.totalAssetsToUpload - appState.assetsUploaded
                let isComplete = remaining <= 0

                HStack(spacing: 8) {
                    Image(systemName: isComplete ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                        .foregroundStyle(isComplete ? .green : theme.primary)
                    Text(isComplete ? "Uploads complete" : "Uploading \(appState.assetsUploaded)/\(appState.totalAssetsToUpload)")
                        .font(.caption)
                        .foregroundStyle(theme.accent.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(theme.secondary.opacity(0.5))
                )
            }
        }
    }
    
    // MARK: - Email Section
    
    private func emailSection(viewModel: QRViewModel<LocalSessionService>) -> some View {
        VStack(spacing: 16) {
            if viewModel.emailSubmitted {
                // Success state
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Email sent! Check your inbox soon.")
                        .font(.subheadline)
                        .foregroundStyle(theme.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.15))
                )
            } else {
                // Email input
                VStack(spacing: 12) {
                    Text("Get your photos via email")
                        .font(.subheadline)
                        .foregroundStyle(theme.accent.opacity(0.8))
                    
                    HStack(spacing: 12) {
                        // Email field
                        TextField("your@email.com", text: Binding(
                            get: { viewModel.email },
                            set: { viewModel.email = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.secondary.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            viewModel.emailError != nil ? .red.opacity(0.5) : theme.accent.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .foregroundStyle(theme.accent)
                        
                        // Submit button
                        Button {
                            Task {
                                if let sessionId = appState.currentSession?.sessionId {
                                    await viewModel.submitEmail(sessionId: sessionId)
                                }
                            }
                        } label: {
                            if viewModel.isSubmittingEmail {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: theme.secondary))
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(theme.secondary)
                            }
                        }
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(theme.primary)
                        )
                        .disabled(viewModel.isSubmittingEmail)
                    }
                    
                    // Error message
                    if let error = viewModel.emailError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button {
            finishSession()
        } label: {
            HStack(spacing: 10) {
                Text("Done")
                Image(systemName: "checkmark")
            }
            .font(.subheadline.bold())
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .stroke(theme.accent.opacity(0.5), lineWidth: 2)
            )
        }
    }
    
    // MARK: - Settings Trigger
    
    private var settingsTrigger: some View {
        VStack {
            HStack {
                Spacer()
                Color.clear
                    .frame(width: 60, height: 60)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 3) {
                        appState.showSettings = true
                    }
            }
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func startVideoPlayback() async {
        guard videoPlayer == nil else { return }
        guard let videoURL = compositeVideoURL else { return }

        // Poll for video file to exist (it may still be processing)
        while !FileManager.default.fileExists(atPath: videoURL.path) {
            try? await Task.sleep(for: .milliseconds(500))
        }

        videoPlayer = videoPlayerManager.play(id: "qr-composite-video", url: videoURL, fromStart: true)
    }

    private func setupViewModel() {
        let vm = QRViewModel(sessionService: services.sessionService, testableServices: testableServices)
        vm.setup(session: appState.currentSession)
        viewModel = vm
        
        // Fetch QR if not available
        if vm.qrImage == nil, let sessionId = appState.currentSession?.sessionId {
            Task {
                await vm.fetchQRIfNeeded(sessionId: sessionId)
            }
        }
    }
    
    private func startAutoReturnTimer() {
        autoReturnTimer = Timer.scheduledTimer(withTimeInterval: autoReturnDelay, repeats: false) { _ in
            Task { @MainActor in
                finishSession()
            }
        }
    }
    
    private func finishSession() {
        autoReturnTimer?.invalidate()
        appState.resetSession()
    }
}

#Preview {
    QRView(services: ServiceContainer(), testableServices: TestableServiceContainer())
        .environment(AppState())
        .withTheme(.default)
}
