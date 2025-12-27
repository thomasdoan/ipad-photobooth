//
//  QRView.swift
//  fotoX
//
//  QR code display and email submission screen
//

import SwiftUI

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
    
    /// Auto-return delay in seconds
    private let autoReturnDelay: TimeInterval = 60
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Themed background
                backgroundLayer
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo
                        logoSection
                        
                        // Captured strips
                        capturedStripsSection(geometry: geometry)
                        
                        // QR Code
                        qrCodeSection(geometry: geometry)
                        
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
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 60)
                }
                
                // Hidden settings trigger
                settingsTrigger
            }
        }
        .task {
            setupViewModel()
            startAutoReturnTimer()
        }
        .onDisappear {
            autoReturnTimer?.invalidate()
        }
    }
    
    // MARK: - Captured Strips
    
    @ViewBuilder
    private func capturedStripsSection(geometry: GeometryProxy) -> some View {
        let strips = appState.capturedStrips
        if !strips.isEmpty {
            let availableWidth = geometry.size.width - 80
            let itemWidth = max(90, (availableWidth - 32) / 3)
            let itemHeight = itemWidth * 1.3
            
            VStack(spacing: 12) {
                Text("Your Photos")
                    .font(.headline)
                    .foregroundStyle(theme.accent.opacity(0.8))
                
                HStack(spacing: 16) {
                    ForEach(strips, id: \.stripIndex) { strip in
                        VStack(spacing: 8) {
                            if let image = UIImage(data: strip.photoData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: itemWidth, height: itemHeight)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.primary.opacity(0.4), lineWidth: 1)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.secondary.opacity(0.4))
                                    .frame(width: itemWidth, height: itemHeight)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundStyle(theme.accent.opacity(0.5))
                                    )
                            }
                            
                            Text("Strip \(strip.stripIndex + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(theme.accent.opacity(0.7))
                        }
                    }
                }
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
    
    private func qrCodeSection(geometry: GeometryProxy) -> some View {
        let qrSize = min(geometry.size.width * 0.6, 300.0)
        
        return VStack(spacing: 20) {
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
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.white)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            } else if viewModel?.isLoadingQR == true {
                // Loading
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                        .frame(width: qrSize + 40, height: qrSize + 40)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                        .scaleEffect(1.5)
                }
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            } else {
                // Error state with retry
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                        .frame(width: qrSize + 40, height: qrSize + 40)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 50))
                            .foregroundStyle(.gray)
                        
                        Text("QR code unavailable")
                            .font(.subheadline)
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
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
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
        .padding(.top, 16)
    }
    
    // MARK: - Done Button
    
    private var doneButton: some View {
        Button {
            finishSession()
        } label: {
            HStack(spacing: 12) {
                Text("Done")
                Image(systemName: "checkmark")
            }
            .font(.headline)
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 48)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .stroke(theme.accent.opacity(0.5), lineWidth: 2)
            )
        }
        .padding(.top, 24)
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
