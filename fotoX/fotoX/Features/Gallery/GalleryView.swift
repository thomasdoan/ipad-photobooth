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
                    GridItem(.adaptive(minimum: 120), spacing: 16)
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Info
                footerView
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
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let stripAsset = session.assets.first(where: { $0.kind == .stripPhoto }) {
            // Priority 1: Use the pre-composed strip asset
            assetImageView(asset: stripAsset)
        } else {
            // Priority 2: Try to construct dynamic strip from photos
            let photoAssets = session.assets
                .filter { $0.kind == .photo }
                .sorted { $0.stripIndex < $1.stripIndex }
            
            if !photoAssets.isEmpty {
                // Determine if we need to show a strip (if we have multiple photos or if it's a strip session)
                let slots = photoAssets.map { StripSlot(id: $0.stripIndex, isVideo: false) }
                // Use a simplified composite view
                ViewThatFits {
                    // Try to fit the composite view
                    dynamicStripView(slots: slots, assets: photoAssets)
                }
            } else {
                // Priority 3: Fallback to existing logic
                fallbackThumbnailView
            }
        }
    }
    
    private func dynamicStripView(slots: [StripSlot], assets: [GalleryAsset]) -> some View {
        let assetsByIndex = Dictionary(assets.map { ($0.stripIndex, $0) }, uniquingKeysWith: { first, _ in first })
        
        return StripCompositeView(
            slots: slots,
            footerText: "", // detailed footer not needed for thumb
            slotAspectRatio: 9.0/16.0
        ) { slot in
            if let asset = assetsByIndex[slot.id] {
                // Recursively use the asset image view logic but forced to fill
                assetImageView(asset: asset, contentMode: .fill)
            } else {
                Color.black.opacity(0.2)
            }
        }
    }

    private func assetImageView(asset: GalleryAsset, contentMode: ContentMode = .fit) -> some View {
        let url = asset.isLocallyAvailable ? asset.localURL : WorkerAPIClient.shared.assetURL(path: asset.remotePath)
        
        return AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                if contentMode == .fit {
                    image
                        .resizable()
                        .scaledToFit()
                } else {
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                }
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
    }

    @ViewBuilder
    private var fallbackThumbnailView: some View {
        if let localURL = session.localThumbURL {
            // Load from local file
            AsyncImage(url: localURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
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
                        .scaledToFit()
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
    
    private var footerSourceIcon: some View {
        SessionSourceIndicator(source: session.source, style: .compact)
    }

    private var footerDateLabel: some View {
        Text(session.formattedDate)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.8))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var footerTimeLabel: some View {
        Text(session.formattedTime)
            .font(.system(size: 10))
            .foregroundStyle(.white.opacity(0.5))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var footerView: some View {
        HStack(alignment: .center, spacing: 0) {
            footerSourceIcon
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                footerDateLabel
                footerTimeLabel
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 4)
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
