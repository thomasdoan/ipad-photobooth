//
//  GalleryView.swift
//  fotoX
//
//  Event gallery screen showing all sessions
//

import SwiftUI

/// Screen for viewing all sessions in an event
struct GalleryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: GalleryViewModel
    
    init(eventId: Int) {
        _viewModel = State(initialValue: GalleryViewModel(eventId: eventId))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    loadingView
                } else if viewModel.sessions.isEmpty {
                    emptyView
                } else {
                    sessionsGrid
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundGradient)
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.white)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            await viewModel.loadSessions()
        }
        .sheet(item: $viewModel.selectedSession) { session in
            SessionDetailView(session: session)
                .statusBarHidden(true)
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
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
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading sessions...")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty
    
    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("No Sessions Yet")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text("Captured sessions will appear here.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button {
                Task { await viewModel.refresh() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
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
    
    // MARK: - Sessions Grid
    
    private var sessionsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(viewModel.sessions) { session in
                    SessionCard(session: session) {
                        viewModel.selectedSession = session
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Scale Button Style

/// Custom button style with scale animation that doesn't block scroll gestures
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: GallerySession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Thumbnail
                thumbnailView
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        SessionSourceIndicator(source: session.source, style: .labeled)
                        Spacer()
                        Text(session.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    Text(session.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 4)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let localURL = session.localThumbURL {
            // Load from local file
            AsyncImage(url: localURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderView
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.2))
                @unknown default:
                    placeholderView
                }
            }
        } else if let thumbPath = session.thumbPath {
            // Load from remote
            AsyncImage(url: WorkerAPIClient.shared.assetURL(path: thumbPath)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderView
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.2))
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
    
}

#Preview {
    GalleryView(eventId: 1)
        .environment(AppState())
}
