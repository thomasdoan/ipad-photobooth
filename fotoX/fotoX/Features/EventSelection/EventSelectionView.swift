//
//  EventSelectionView.swift
//  fotoX
//
//  Event selection screen
//

import SwiftUI

/// Screen for selecting an event to start the photobooth
struct EventSelectionView: View {
    @Environment(AppState.self) private var appState
    let services: ServiceContainer
    let testableServices: TestableServiceContainer
    
    @State private var viewModel: EventSelectionViewModel?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "#1a1a2e") ?? .black,
                        Color(hex: "#16213e") ?? .black,
                        Color(hex: "#0f3460") ?? .black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Decorative circles
                Circle()
                    .fill(Color(hex: "#e94560")?.opacity(0.1) ?? .pink.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 60)
                    .offset(x: -150, y: -200)
                
                Circle()
                    .fill(Color(hex: "#0f3460")?.opacity(0.3) ?? .blue.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 40)
                    .offset(x: 200, y: 300)
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                    
                    // Events list
                    if let viewModel = viewModel {
                        eventsContent(viewModel: viewModel, geometry: geometry)
                    } else {
                        loadingView
                    }
                    
                    // Footer with settings access
                    footerSection
                        .padding(.bottom, 40)
                }
            }
        }
        .task {
            if viewModel == nil {
                let vm = EventSelectionViewModel(
                    eventService: services.eventService,
                    themeService: services.themeService,
                    testableServices: testableServices
                )
                viewModel = vm
                await vm.loadEvents()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#e94560") ?? .pink,
                                Color(hex: "#ff6b6b") ?? .red
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: "#e94560")?.opacity(0.5) ?? .pink.opacity(0.5), radius: 20)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            
            Text("FotoX")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Select an Event")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    // MARK: - Events Content
    
    @ViewBuilder
    private func eventsContent(viewModel: EventSelectionViewModel, geometry: GeometryProxy) -> some View {
        if viewModel.isLoading && viewModel.events.isEmpty {
            loadingView
        } else if viewModel.events.isEmpty {
            emptyView(viewModel: viewModel)
        } else {
            eventsGrid(viewModel: viewModel, geometry: geometry)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading events...")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func emptyView(viewModel: EventSelectionViewModel) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("No Events Available")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text("Check your connection to the photobooth server.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    await viewModel.loadEvents()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color(hex: "#e94560") ?? .pink)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func eventsGrid(viewModel: EventSelectionViewModel, geometry: GeometryProxy) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 24),
                    GridItem(.flexible(), spacing: 24)
                ],
                spacing: 24
            ) {
                ForEach(viewModel.events) { event in
                    EventCard(event: event) {
                        Task {
                            await viewModel.selectEvent(event, appState: appState)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack {
            Spacer()
            
            Button {
                appState.showSettings = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.white.opacity(0.1))
                .clipShape(Capsule())
            }
            
            Spacer()
        }
    }
}

/// Card view for displaying an event
struct EventCard: View {
    let event: Event
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                // Event logo/icon area
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: event.theme.primaryColor) ?? .pink,
                                    Color(hex: event.theme.primaryColor)?.opacity(0.7) ?? .pink.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                    
                    if let logoURL = event.theme.logoURL,
                       let url = URL(string: logoURL) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 80)
                        } placeholder: {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                // Event details
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(event.displayDate)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityIdentifier("eventCard")
        .accessibilityLabel("Event: \(event.name)")
    }
}

#Preview {
    EventSelectionView(services: ServiceContainer(), testableServices: TestableServiceContainer())
        .environment(AppState())
}

