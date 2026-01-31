//
//  CaptureView.swift
//  fotoX
//
//  Main capture screen for recording video and taking photos
//

import SwiftUI

/// Main capture view managing the 3-strip capture flow
struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var themeAssets
    @Environment(\.themeComponents) private var themeComponents: any ThemeComponentProvider
    let services: ServiceContainer
    
    @State private var viewModel = CaptureViewModel()
    @State private var showFlash = false
    @State private var volumeButtonHandler = VolumeButtonHandler()

    private var isReviewing: Bool {
        viewModel.stripState == .complete && (viewModel.pendingStrip != nil || viewModel.isSessionComplete)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview (always underneath)
                cameraLayer
                
                // UI overlays based on state
                overlayLayer(geometry: geometry)
                
                // Flash effect
                PhotoFlashView(isFlashing: $showFlash)

                // Volume HUD suppressor when Bluetooth button is enabled
                if WorkerConfiguration.bluetoothButtonEnabled() {
                    VolumeHUDSuppressor()
                        .frame(width: 1, height: 1)
                }
            }
        }
        .task {
            viewModel.updateAspectRatioSetting(
                appState.captureAspectRatioSetting,
                orientation: appState.layoutOrientation
            )
            await viewModel.setupCamera()

            // Start volume button listening if enabled
            if WorkerConfiguration.bluetoothButtonEnabled() {
                volumeButtonHandler.onVolumeButtonPressed = {
                    _ = viewModel.handleVolumeButtonPress()
                }
                volumeButtonHandler.startListening()
            }
        }
        .onDisappear {
            volumeButtonHandler.stopListening()
            viewModel.cleanup(deleteTemporaryFiles: false)
        }
        .onChange(of: appState.captureAspectRatioSetting) { _, newValue in
            viewModel.updateAspectRatioSetting(newValue, orientation: appState.layoutOrientation)
        }
        .onChange(of: appState.layoutOrientation) { _, newValue in
            viewModel.updateAspectRatioSetting(appState.captureAspectRatioSetting, orientation: newValue)
        }
        .onChange(of: viewModel.stripState) { oldState, newState in
            handleStateChange(from: oldState, to: newState)
        }
        .onChange(of: viewModel.isSessionComplete) { _, isComplete in
            // When complete, show the summary review screen so the operator can
            // pick a strip frame (and optionally retake) before uploading.
            _ = isComplete
        }
        .alert(
            "Processing Error",
            isPresented: Binding(
                get: { viewModel.videoProcessingError != nil },
                set: { if !$0 { viewModel.videoProcessingError = nil } }
            )
        ) {
            Button("OK") {
                viewModel.videoProcessingError = nil
            }
        } message: {
            Text(viewModel.videoProcessingError ?? "")
        }
    }
    
    // MARK: - Camera Layer
    
    private var cameraLayer: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            // Camera preview (uses SimulatorPreviewView when in simulator)
            if viewModel.cameraController.isSimulator {
                SimulatorPreviewView()
                    .ignoresSafeArea()
            } else {
                CameraPreview(
                    cameraController: viewModel.cameraController,
                    isReady: viewModel.isCameraReady
                )
                .ignoresSafeArea()
            }

            // Frame overlay if available
            if let frame = themeAssets?.photoFrame {
                frame
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Overlay Layer
    
    @ViewBuilder
    private func overlayLayer(geometry: GeometryProxy) -> some View {
        captureOverlay(geometry: geometry)
    }
    
    // MARK: - Capture Overlay
    
    @ViewBuilder
    private func captureOverlay(geometry: GeometryProxy) -> some View {
        ZStack {
            // Top bar
            if !isReviewing {
                VStack {
                    topBar
                    Spacer()
                }
            }
            
            // State-specific overlays
            switch viewModel.stripState {
            case .ready:
                readyOverlay
                
            case .countdown(let remaining):
                ThemedCountdownOverlay(number: remaining)
                
            case .recording(let elapsed):
                ZStack {
                    recordingOverlay(elapsed: elapsed, geometry: geometry)

                    // Show countdown overlay during final seconds of recording
                    if let countdownRemaining = viewModel.recordingCountdownRemaining {
                        ThemedCountdownOverlay(number: countdownRemaining)
                    }
                }

            case .processingVideo, .processingPhoto:
                EmptyView() // Camera preview stays visible during processing

            case .capturingPhoto:
                Color.clear // Flash will handle this
                
            case .complete:
                if let pendingStrip = viewModel.pendingStrip {
                    StripReviewView(
                        stripIndex: pendingStrip.stripIndex,
                        stripCount: viewModel.config.stripCount,
                        videoURL: pendingStrip.videoURL,
                        photoData: pendingStrip.photoData,
                        aspectRatio: viewModel.currentAspectRatio.widthToHeight,
                        onRetake: {
                            viewModel.retakePendingStrip()
                        },
                        onContinue: {
                            viewModel.acceptPendingStripAndAdvance()
                        },
                        isLastStrip: pendingStrip.stripIndex == viewModel.config.stripCount - 1,
                        showsReviewControls: viewModel.showsReviewControls,
                        showsAutoAdvanceLabel: !viewModel.config.manualAdvanceAfterReview,
                        autoAdvanceSeconds: Int(round(viewModel.reviewDuration))
                    )
                } else if viewModel.isSessionComplete {
                    CaptureSummaryView(
                        strips: viewModel.getCapturedStrips(),
                        onRetake: { index in
                            viewModel.retakeStrip(at: index)
                        },
                        onFinish: {
                            finishCapture()
                        },
                        aspectRatio: viewModel.currentAspectRatio.widthToHeight,
                        selectedFrameAssetName: $viewModel.selectedFrameAssetName,
                        onCompositeRendered: { assets in
                            viewModel.compositeAssetsForUpload = assets
                        }
                    )
                } else {
                    EmptyView()
                }
                
            case .error(let message):
                errorOverlay(message: message)
            }
            
            // Bottom bar (cancel button)
            if !isReviewing {
                VStack {
                    Spacer()
                    bottomBar
                }
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Strip indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index < viewModel.capturedStrips.count ? theme.primary : 
                              index == viewModel.currentStripIndex ? theme.primary.opacity(0.5) : 
                              theme.accent.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
                
                Text("Strip \(viewModel.currentStripIndex + 1) of 3")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("stripIndicator")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.black.opacity(0.5))
            )
            
            Spacer()
            
            // Recording badge when recording
            if case .recording = viewModel.stripState {
                ThemedRecordingIndicator()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }
    
    // MARK: - Ready Overlay
    
    private var readyOverlay: some View {
        VStack {
            Spacer()

            ThemedActionButton("Tap to\nStart", icon: "camera.fill") {
                viewModel.startCapture()
            }

            Spacer()
                .frame(height: 150)
        }
    }
    
    // MARK: - Recording Overlay
    
    private func recordingOverlay(elapsed: TimeInterval, geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()

            // Hide small countdown when big countdown is showing
            if viewModel.recordingCountdownRemaining == nil {
                ThemedRecordingProgress(
                    progress: elapsed / viewModel.config.videoDuration,
                    duration: viewModel.config.videoDuration,
                    elapsed: elapsed
                )

                ThemedRecordingEncouragement()
            }

            Spacer()
                .frame(height: 150)
        }
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(message: String) -> some View {
        ZStack {
            themeComponents.makeErrorOverlayBackground()

            VStack(spacing: 24) {
                ThemedErrorIcon()

                Text("Something went wrong")
                    .font(.title2.bold())
                    .foregroundStyle(theme.accent)

                Text(message)
                    .font(.body)
                    .foregroundStyle(theme.accent.opacity(0.8))
                    .multilineTextAlignment(.center)

                ThemedSecondaryActionButton("Try Again", icon: "arrow.counterclockwise") {
                    viewModel.retryCurrentStrip()
                }
            }
            .padding(32)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack {
            // Cancel/Reset button
            Button {
                cancelCapture()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                    Text("Cancel")
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.5))
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    
    private func handleStateChange(from oldState: StripCaptureState, to newState: StripCaptureState) {
        // Trigger flash effect when capturing photo
        if case .capturingPhoto = newState {
            showFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showFlash = false
            }
        }
    }
    
    private func finishCapture() {
        // Transfer captured strips to app state and proceed to upload
        let strips = viewModel.getCapturedStrips()
        for strip in strips {
            appState.addCapturedStrip(strip)
        }

        // Store selected frame ID for email collection
        if let frameName = viewModel.selectedFrameAssetName {
            appState.selectedFrameId = FrameOption.availableFrames.first { $0.frameName == frameName }?.id
        } else {
            appState.selectedFrameId = nil
        }

        guard let eventId = appState.selectedEvent?.id,
              let session = appState.currentSession else {
            appState.currentError = APIError.invalidResponse
            appState.currentRoute = .idle
            return
        }

        appState.beginUpload()

        Task { @MainActor in
            do {
                var compositeAssets: CompositeStripAssets? = nil

                let footerText = theme.stripFooterText ?? appState.selectedEvent?.name ?? "FotoX"
                if let prepared = viewModel.compositeAssetsForUpload {
                    compositeAssets = prepared
                } else {
                    do {
                        compositeAssets = try await StripCompositeRenderer.renderCompositeAssets(
                            strips: strips,
                            theme: theme,
                            assets: themeAssets,
                            footerText: footerText,
                            customFrameAssetName: viewModel.selectedFrameAssetName,
                            slotAspectRatio: viewModel.currentAspectRatio.widthToHeight
                        )
                    } catch {
                        // Log but continue - composite is optional.
                        print("Composite rendering failed: \(error)")
                        compositeAssets = nil
                    }
                }
                
                try await services.uploadQueueWorker.enqueueAndStart(
                    eventId: eventId,
                    session: session,
                    strips: strips,
                    composite: compositeAssets,
                    onProgress: { sessionId in
                        if appState.currentSession?.sessionId == sessionId {
                            appState.assetUploaded()
                        }
                    },
                    onError: { sessionId, error in
                        if sessionId.isEmpty || appState.currentSession?.sessionId == sessionId {
                            appState.uploadFailed(error: error)
                        }
                    }
                )
                viewModel.compositeAssetsForUpload = nil
            } catch let error as APIError {
                appState.uploadFailed(error: error)
            } catch {
                appState.uploadFailed(error: .unknown(error))
            }
        }
    }
    
    private func cancelCapture() {
        viewModel.cleanup(deleteTemporaryFiles: true)
        appState.resetSession()
    }
}

#Preview {
    CaptureView(services: ServiceContainer())
        .environment(AppState())
        .withTheme(.default)
}
