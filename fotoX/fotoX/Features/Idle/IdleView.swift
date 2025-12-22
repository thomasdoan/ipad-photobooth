//
//  IdleView.swift
//  fotoX
//
//  Idle/attract screen shown when an event is selected
//

import SwiftUI

/// Idle screen that displays the event theme and prompts user to start
struct IdleView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var themeAssets
    let services: ServiceContainer
    let testableServices: TestableServiceContainer
    
    @State private var viewModel: IdleViewModel<LocalSessionService>?
    @State private var isPulsing = false
    @State private var showParticles = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Themed background
                backgroundLayer
                
                // Floating particles
                if showParticles {
                    ParticlesView(theme: theme)
                }
                
                // Main content
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo and event info
                    eventHeader
                    
                    Spacer()
                    
                    // Start button
                    startButton
                    
                    Spacer()
                    
                    // Footer
                    footerSection
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 60)
                
                // Loading overlay
                if viewModel?.isCreatingSession == true {
                    loadingOverlay
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = IdleViewModel(sessionService: services.sessionService, testableServices: testableServices)
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel?.showError ?? false },
                set: { if !$0 { viewModel?.clearError() } }
            ),
            presenting: viewModel?.errorMessage
        ) { _ in
            Button("OK") {
                viewModel?.clearError()
            }
        } message: { message in
            Text(message)
        }
    }
    
    // MARK: - Background
    
    private var backgroundLayer: some View {
        ZStack {
            // Base gradient using theme colors
            LinearGradient(
                colors: [
                    theme.secondary,
                    theme.secondary.opacity(0.9),
                    theme.primary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Theme background image if available
            if let background = themeAssets?.background {
                background
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.6)
            }
            
            // Decorative gradient orbs
            Circle()
                .fill(theme.primary.opacity(0.15))
                .frame(width: 500, height: 500)
                .blur(radius: 80)
                .offset(x: -100, y: -300)
            
            Circle()
                .fill(theme.accent.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: 200, y: 200)
        }
    }
    
    // MARK: - Event Header
    
    private var eventHeader: some View {
        VStack(spacing: 32) {
            // Logo
            if let logo = themeAssets?.logo {
                logo
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 180)
                    .shadow(color: .black.opacity(0.3), radius: 20)
            } else {
                // Fallback camera icon
                ZStack {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 140, height: 140)
                        .shadow(color: theme.primary.opacity(0.5), radius: 30)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(theme.secondary)
                }
            }
            
            // Event name
            if let event = appState.selectedEvent {
                VStack(spacing: 12) {
                    Text(event.name)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 8)
                    
                    Text(event.displayDate)
                        .font(.title3)
                        .foregroundStyle(theme.accent.opacity(0.7))
                }
            }
        }
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        Button {
            Task {
                await viewModel?.startSession(appState: appState)
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.title)
                
                Text("Tap to Start")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            .foregroundStyle(theme.secondary)
            .padding(.horizontal, 64)
            .padding(.vertical, 24)
            .background(
                Capsule()
                    .fill(theme.primary)
                    .shadow(color: theme.primary.opacity(0.5), radius: isPulsing ? 30 : 15, y: 5)
            )
            .scaleEffect(isPulsing ? 1.02 : 1.0)
        }
        .disabled(viewModel?.isCreatingSession == true)
        .accessibilityIdentifier("startButton")
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack {
            // Back to events button
            Button {
                appState.returnToEventSelection()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Change Event")
                }
                .font(.subheadline)
                .foregroundStyle(theme.accent.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(theme.secondary.opacity(0.3))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // Hidden settings trigger (triple-tap)
            Color.clear
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
                .onTapGesture(count: 3) {
                    appState.showSettings = true
                }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.accent))
                    .scaleEffect(2)
                
                Text("Preparing your session...")
                    .font(.headline)
                    .foregroundStyle(theme.accent)
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.secondary.opacity(0.9))
            )
        }
    }
}

/// Floating particles for visual interest
struct ParticlesView: View {
    let theme: AppTheme
    
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .blur(radius: particle.blur)
                    .opacity(particle.opacity)
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<15).map { _ in
            Particle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 4...12),
                color: [theme.primary, theme.accent].randomElement()!.opacity(Double.random(in: 0.1...0.3)),
                blur: CGFloat.random(in: 0...4),
                opacity: Double.random(in: 0.3...0.7)
            )
        }
    }
}

struct Particle: Identifiable {
    let id: UUID
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let blur: CGFloat
    let opacity: Double
}

#Preview {
    IdleView(services: ServiceContainer(), testableServices: TestableServiceContainer())
        .environment(AppState())
        .withTheme(.default)
}
