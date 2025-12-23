//
//  GalleryView.swift
//  fotoX
//
//  Gallery view for viewing all photos and videos from an event
//

import SwiftUI
import AVKit

/// Gallery view for browsing event media
struct GalleryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appTheme) private var theme
    let services: ServiceContainer
    let testableServices: TestableServiceContainer

    @State private var viewModel: GalleryViewModel?
    @State private var selectedMedia: GalleryMedia?

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundLayer

                // Content
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Gallery content
                    if let viewModel = viewModel {
                        galleryContent(viewModel: viewModel)
                    } else {
                        loadingView
                    }
                }
            }
        }
        .task {
            if viewModel == nil {
                let vm = GalleryViewModel(sessionService: services.sessionService)
                viewModel = vm
                if let eventId = appState.selectedEvent?.id {
                    await vm.loadGallery(eventId: eventId)
                }
            }
        }
        .sheet(item: $selectedMedia) { media in
            MediaDetailView(media: media, theme: theme)
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
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                // Back button
                Button {
                    appState.currentRoute = .idle
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(theme.secondary.opacity(0.3))
                    .clipShape(Capsule())
                }

                Spacer()

                if let event = appState.selectedEvent {
                    Text(event.name)
                        .font(.title2.bold())
                        .foregroundStyle(theme.accent)
                }

                Spacer()

                // Placeholder for symmetry
                Color.clear
                    .frame(width: 100)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Text("Event Gallery")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primary)
                .padding(.bottom, 8)
        }
        .background(theme.secondary.opacity(0.5))
    }

    // MARK: - Gallery Content

    @ViewBuilder
    private func galleryContent(viewModel: GalleryViewModel) -> some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.allMedia.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.allMedia) { media in
                        MediaThumbnailView(media: media, theme: theme)
                            .onTapGesture {
                                selectedMedia = media
                            }
                    }
                }
                .padding(24)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                .scaleEffect(2)

            Text("Loading gallery...")
                .font(.headline)
                .foregroundStyle(theme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundStyle(theme.accent.opacity(0.5))

            Text("No photos yet")
                .font(.title.bold())
                .foregroundStyle(theme.accent)

            Text("Photos and videos from this event will appear here")
                .font(.body)
                .foregroundStyle(theme.accent.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Media Thumbnail View

struct MediaThumbnailView: View {
    let media: GalleryMedia
    let theme: AppTheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Placeholder with gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [theme.primary, theme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(9/16, contentMode: .fit)
                .overlay {
                    // Media type icon
                    VStack {
                        Spacer()
                        Image(systemName: media.kind == .video ? "play.circle.fill" : "photo.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                    }
                }

            // Type badge
            HStack(spacing: 4) {
                Image(systemName: media.kind == .video ? "video.fill" : "photo.fill")
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .padding(8)
            .background(
                Capsule()
                    .fill(.black.opacity(0.6))
            )
            .padding(8)
        }
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
}

// MARK: - Media Detail View

struct MediaDetailView: View {
    let media: GalleryMedia
    let theme: AppTheme

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                            Text("Close")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: media.kind == .video ? "video.fill" : "photo.fill")
                        Text(media.kind == .video ? "Video" : "Photo")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())
                }
                .padding(24)

                Spacer()

                // Media content
                if media.kind == .video {
                    if let player = player {
                        VideoPlayer(player: player)
                            .aspectRatio(9/16, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 40)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                    }
                } else {
                    // Photo placeholder
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(9/16, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Metadata
                VStack(spacing: 8) {
                    Text("Strip \(media.stripIndex + 1)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if media.kind == .video {
                if let url = URL(string: media.url) {
                    player = AVPlayer(url: url)
                    player?.play()
                }
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

#Preview {
    GalleryView(services: ServiceContainer(), testableServices: TestableServiceContainer())
        .environment(AppState())
        .withTheme(.default)
}
