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
    
    @State private var viewModel = CaptureViewModel()
    @State private var showFlash = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview (always underneath)
                cameraLayer
                
                // UI overlays based on state
                overlayLayer(geometry: geometry)
                
                // Flash effect
                PhotoFlashView(isFlashing: $showFlash)
            }
        }
        .task {
            await viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .onChange(of: viewModel.stripState) { oldState, newState in
            handleStateChange(from: oldState, to: newState)
        }
    }
    
    // MARK: - Camera Layer
    
    private var cameraLayer: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            // Camera preview
            CameraPreview(cameraController: viewModel.cameraController)
                .ignoresSafeArea()
            
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
        if viewModel.showingSummary {
            // Summary view
            CaptureSummaryView(
                strips: viewModel.getCapturedStrips(),
                onRetake: { index in
                    viewModel.retakeStrip(at: index)
                },
                onFinish: {
                    finishCapture()
                }
            )
            .transition(.opacity)
        } else if viewModel.isReviewing, let lastStrip = viewModel.capturedStrips.last {
            // Review view
            StripReviewView(
                stripIndex: lastStrip.stripIndex,
                videoURL: lastStrip.videoURL,
                photoData: lastStrip.photoData,
                onRetake: {
                    viewModel.retakeCurrentStrip()
                },
                onContinue: {
                    viewModel.continueToNext()
                },
                isLastStrip: viewModel.currentStripIndex >= viewModel.config.stripCount - 1
            )
            .transition(.opacity)
        } else {
            // Capture UI
            captureOverlay(geometry: geometry)
        }
    }
    
    // MARK: - Capture Overlay
    
    @ViewBuilder
    private func captureOverlay(geometry: GeometryProxy) -> some View {
        ZStack {
            // Top bar
            VStack {
                topBar
                Spacer()
            }
            
            // State-specific overlays
            switch viewModel.stripState {
            case .ready:
                readyOverlay
                
            case .countdown(let remaining):
                CountdownView(number: remaining, isPhotoCountdown: false)
                
            case .recording(let elapsed):
                recordingOverlay(elapsed: elapsed, geometry: geometry)
                
            case .processingVideo, .processingPhoto:
                processingOverlay
                
            case .photoCountdown(let remaining):
                CountdownView(number: remaining, isPhotoCountdown: true)
                
            case .capturingPhoto:
                Color.clear // Flash will handle this
                
            case .complete:
                EmptyView()
                
            case .error(let message):
                errorOverlay(message: message)
            }
            
            // Bottom bar (cancel button)
            VStack {
                Spacer()
                bottomBar
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
                RecordingBadge()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }
    
    // MARK: - Ready Overlay
    
    private var readyOverlay: some View {
        VStack {
            Spacer()
            
            Button {
                viewModel.startCapture()
            } label: {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(theme.primary, lineWidth: 4)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 80, height: 80)
                    }
                    
                    Text("Tap to Start Recording")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            
            Spacer()
                .frame(height: 150)
        }
    }
    
    // MARK: - Recording Overlay
    
    private func recordingOverlay(elapsed: TimeInterval, geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            RecordingProgressView(
                progress: elapsed / viewModel.config.videoDuration,
                duration: viewModel.config.videoDuration,
                elapsed: elapsed
            )
            
            Text("Keep going!")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.top, 16)
            
            Spacer()
                .frame(height: 150)
        }
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Processing...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.yellow)
                
                Text("Something went wrong")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button {
                    viewModel.retakeCurrentStrip()
                } label: {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(.white))
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
        appState.beginUpload()
    }
    
    private func cancelCapture() {
        viewModel.cleanup()
        appState.resetSession()
    }
}

#Preview {
    CaptureView()
        .environment(AppState())
        .withTheme(.default)
}

