//
//  UploadView.swift
//  fotoX
//
//  Upload screen with progress display
//

import SwiftUI

/// Screen showing upload progress
struct UploadView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appTheme) private var theme
    let services: ServiceContainer
    let testableServices: TestableServiceContainer
    
    @State private var viewModel: UploadViewModel?
    @State private var hasStartedUpload = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundLayer
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    headerSection
                    
                    // Progress section
                    if let viewModel = viewModel {
                        progressSection(viewModel: viewModel)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.accent))
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    if let viewModel = viewModel {
                        actionButtons(viewModel: viewModel)
                    }
                }
                .padding(40)
            }
        }
        .task {
            await setupAndStartUpload()
        }
    }
    
    // MARK: - Background
    
    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [theme.secondary, theme.secondary.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative elements
            Circle()
                .fill(theme.primary.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: -100, y: -200)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            if viewModel?.isComplete == true {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else if viewModel?.hasFailedUploads == true {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow)
            } else {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(theme.primary)
                    .symbolEffect(.pulse)
            }
            
            Text(headerTitle)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accent)
            
            Text(headerSubtitle)
                .font(.body)
                .foregroundStyle(theme.accent.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .animation(.spring(), value: viewModel?.isComplete)
    }
    
    private var headerTitle: String {
        if viewModel?.isComplete == true {
            return "Upload Complete!"
        } else if viewModel?.hasFailedUploads == true {
            return "Upload Issue"
        } else {
            return "Uploading..."
        }
    }
    
    private var headerSubtitle: String {
        if viewModel?.isComplete == true {
            return "Your photos and videos are being processed"
        } else if viewModel?.hasFailedUploads == true {
            return "Some files couldn't be uploaded. Tap retry to try again."
        } else {
            return "Please wait while we upload your captures"
        }
    }
    
    // MARK: - Progress Section
    
    private func progressSection(viewModel: UploadViewModel) -> some View {
        VStack(spacing: 24) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(theme.secondary.opacity(0.3), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        theme.primary,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                    
                    Text("\(viewModel.completedCount)/\(viewModel.uploadItems.count)")
                        .font(.caption)
                        .foregroundStyle(theme.accent.opacity(0.6))
                }
            }
            
            // Upload items list
            uploadItemsList(viewModel: viewModel)
        }
    }
    
    private func uploadItemsList(viewModel: UploadViewModel) -> some View {
        VStack(spacing: 12) {
            // Queue statistics header
            queueStatistics(viewModel: viewModel)

            Divider()
                .background(theme.accent.opacity(0.2))

            // Upload items
            VStack(spacing: 8) {
                ForEach(viewModel.uploadItems) { item in
                    uploadItemRow(item: item)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.secondary.opacity(0.5))
        )
    }

    private func queueStatistics(viewModel: UploadViewModel) -> some View {
        HStack(spacing: 20) {
            // Total size
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Size")
                    .font(.caption2)
                    .foregroundStyle(theme.accent.opacity(0.5))
                Text(viewModel.totalSizeFormatted)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.accent)
            }

            // Upload speed (if available)
            if let speed = viewModel.uploadSpeedFormatted {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Speed")
                        .font(.caption2)
                        .foregroundStyle(theme.accent.opacity(0.5))
                    Text(speed)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.primary)
                }
            }

            // Time remaining (if available and still uploading)
            if viewModel.isUploading, let timeRemaining = viewModel.timeRemainingFormatted {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Estimated")
                        .font(.caption2)
                        .foregroundStyle(theme.accent.opacity(0.5))
                    Text(timeRemaining)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.primary)
                }
            }

            Spacer()
        }
    }
    
    private func uploadItemRow(item: UploadItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Icon
                Image(systemName: item.kind == .video ? "video.fill" : "photo.fill")
                    .font(.body)
                    .foregroundStyle(theme.accent.opacity(0.7))
                    .frame(width: 24)

                // Name
                Text(item.displayName)
                    .font(.subheadline)
                    .foregroundStyle(theme.accent)

                Spacer()

                // Status
                statusIcon(for: item.state)
            }

            // Details row (file size, duration)
            HStack(spacing: 12) {
                // File size
                Text(item.fileSizeFormatted)
                    .font(.caption2)
                    .foregroundStyle(theme.accent.opacity(0.5))

                // Upload duration or status text
                if let duration = item.uploadDurationFormatted {
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(theme.accent.opacity(0.3))

                    Text(duration)
                        .font(.caption2)
                        .foregroundStyle(theme.accent.opacity(0.5))
                }

                // Status text for current state
                if case .uploading = item.state {
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(theme.accent.opacity(0.3))

                    Text("Uploading...")
                        .font(.caption2)
                        .foregroundStyle(theme.primary)
                } else if case .failed(let error) = item.state {
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(theme.accent.opacity(0.3))

                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.leading, 32)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func statusIcon(for state: UploadItemState) -> some View {
        switch state {
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(theme.accent.opacity(0.3))
        case .uploading:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                .scaleEffect(0.7)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private func actionButtons(viewModel: UploadViewModel) -> some View {
        VStack(spacing: 16) {
            if viewModel.isComplete {
                // Continue to QR
                Button {
                    fetchQRAndContinue()
                } label: {
                    HStack(spacing: 12) {
                        Text("View QR Code")
                        Image(systemName: "qrcode")
                    }
                    .font(.headline)
                    .foregroundStyle(theme.secondary)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(theme.primary)
                    )
                    .shadow(color: theme.primary.opacity(0.4), radius: 10, y: 4)
                }
            } else if viewModel.hasFailedUploads {
                // Retry button
                HStack(spacing: 16) {
                    Button {
                        Task {
                            await retryUpload()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .font(.headline)
                        .foregroundStyle(theme.secondary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(theme.primary)
                        )
                    }
                    
                    Button {
                        appState.resetSession()
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundStyle(theme.accent.opacity(0.7))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                if viewModel.retryCount > 0 {
                    Text("Retry attempt \(viewModel.retryCount) of \(viewModel.maxRetries)")
                        .font(.caption)
                        .foregroundStyle(theme.accent.opacity(0.5))
                }
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    
    private func setupAndStartUpload() async {
        guard !hasStartedUpload else { return }
        hasStartedUpload = true
        
        let vm = UploadViewModel(sessionService: services.sessionService, testableServices: testableServices)
        vm.prepareUploads(from: appState.capturedStrips)
        viewModel = vm
        
        guard let sessionId = appState.currentSession?.sessionId else {
            vm.errorMessage = "No active session"
            return
        }
        
        await vm.startUpload(
            sessionId: sessionId,
            strips: appState.capturedStrips,
            appState: appState
        )
    }
    
    private func retryUpload() async {
        guard let viewModel = viewModel,
              let sessionId = appState.currentSession?.sessionId else { return }
        
        await viewModel.retryFailed(
            sessionId: sessionId,
            strips: appState.capturedStrips,
            appState: appState
        )
    }
    
    private func fetchQRAndContinue() {
        Task {
            guard let sessionId = appState.currentSession?.sessionId else { return }
            
            do {
                let qrData = try await testableServices.fetchQRCode(sessionId: sessionId)
                await MainActor.run {
                    appState.uploadCompleted(qrData: qrData)
                }
            } catch {
                // If QR fetch fails, still proceed (can try again on QR screen)
                await MainActor.run {
                    appState.uploadCompleted(qrData: Data())
                }
            }
        }
    }
}

#Preview {
    UploadView(services: ServiceContainer(), testableServices: TestableServiceContainer())
        .environment(AppState())
        .withTheme(.default)
}

