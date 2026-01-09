//
//  SessionDetailView.swift
//  fotoX
//
//  Detail view for a session showing all photos and videos
//

import SwiftUI
import AVKit

/// Full-screen view for viewing a session's photos and videos
struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    
    @State private var viewModel: SessionDetailViewModel
    @State private var selectedPageIndex: Int = 0
    @State private var scrollPosition: Int?
    @State private var playerManager = VideoPlayerManager()
    @State private var focusedAsset: GalleryAsset?
    
    init(session: GallerySession) {
        _viewModel = State(initialValue: SessionDetailViewModel(session: session))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoadingAssets {
                    loadingAssetsView
                } else if viewModel.assets.isEmpty {
                    emptyAssetsView
                } else {
                    VStack(spacing: 0) {
                        // Main content area
                        assetPager
                        
                        // Thumbnails strip
                        thumbnailStrip
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                    }
                }
            }
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(viewModel.session.formattedDateTime)
                            .font(.headline)
                            .foregroundStyle(.white)
                        let pageCount = stripPages.count
                        if pageCount > 0 {
                            Text("\(selectedPageIndex + 1) of \(pageCount)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    SessionSourceIndicator(source: viewModel.session.source, style: .compact)
                }
            }
            .sheet(item: $focusedAsset) { asset in
                AssetDetailView(asset: asset, playerManager: playerManager)
            }
        }
        .task {
            await viewModel.loadAssetsIfNeeded()
        }
        .onDisappear {
            playerManager.stopAll()
        }
    }
    
    // MARK: - Loading State
    
    private var loadingAssetsView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading photos and videos...")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    // MARK: - Empty State
    
    private var emptyAssetsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.4))
            
            Text("No assets available")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.6))
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button {
                Task { await viewModel.loadAssetsIfNeeded() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Asset Pager
    
    private var assetPager: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(stripPages.enumerated()), id: \.element.id) { index, page in
                    StripPageView(
                        page: page,
                        assetsByIndex: assetsByIndex(for: page.kind),
                        onSelectAsset: { asset in
                            focusedAsset = asset
                        }
                    )
                    .containerRelativeFrame([.horizontal, .vertical])
                    .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollPosition)
        .onChange(of: scrollPosition) { _, newValue in
            guard let newValue else { return }
            if newValue != selectedPageIndex {
                selectedPageIndex = newValue
            }
        }
        .onChange(of: selectedPageIndex) { _, newValue in
            if scrollPosition != newValue {
                scrollPosition = newValue
            }
        }
        .onChange(of: stripPages.count) { _, count in
            guard count > 0 else {
                scrollPosition = nil
                return
            }
            if selectedPageIndex >= count {
                selectedPageIndex = max(count - 1, 0)
            }
            if scrollPosition != selectedPageIndex {
                scrollPosition = selectedPageIndex
            }
        }
        .onAppear {
            if !stripPages.isEmpty {
                scrollPosition = selectedPageIndex
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Thumbnail Strip
    
    private var thumbnailStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(stripPages.enumerated()), id: \.element.id) { index, page in
                        StripPageButton(
                            title: page.title,
                            systemImage: page.kind == .photo ? "photo.stack.fill" : "video.fill",
                            isSelected: index == selectedPageIndex
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPageIndex = index
                                scrollPosition = index
                            }
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: selectedPageIndex) { _, newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Helpers
}

private extension SessionDetailView {
    var stripPages: [StripPage] {
        var pages: [StripPage] = []

        let photoSlots = stripSlots(for: .photo)
        if !photoSlots.isEmpty {
            pages.append(StripPage(kind: .photo, title: "Photo Strip", slots: photoSlots))
        }

        let videoSlots = stripSlots(for: .video)
        if !videoSlots.isEmpty {
            pages.append(StripPage(kind: .video, title: "Video Strip", slots: videoSlots))
        }

        return pages
    }

    func stripSlots(for kind: AssetKind) -> [StripSlot] {
        let assets = assetsByIndex(for: kind)
        guard !assets.isEmpty else { return [] }
        return (0..<3).map { StripSlot(id: $0, isVideo: kind == .video) }
    }

    func assetsByIndex(for kind: AssetKind) -> [Int: GalleryAsset] {
        viewModel.assets
            .filter { $0.kind == kind }
            .reduce(into: [:]) { result, asset in
                if result[asset.stripIndex] == nil {
                    result[asset.stripIndex] = asset
                }
            }
    }

    func stripFooterText() -> String {
        theme.stripFooterText ?? "FotoX"
    }
}

private struct StripPage: Identifiable {
    let id: String
    let kind: AssetKind
    let title: String
    let slots: [StripSlot]

    init(kind: AssetKind, title: String, slots: [StripSlot]) {
        self.id = kind.rawValue
        self.kind = kind
        self.title = title
        self.slots = slots
    }
}

private struct StripPageView: View {
    @Environment(\.appTheme) private var theme

    let page: StripPage
    let assetsByIndex: [Int: GalleryAsset]
    let onSelectAsset: (GalleryAsset) -> Void

    var body: some View {
        GeometryReader { geometry in
            StripCompositeView(
                slots: page.slots,
                footerText: stripFooterText()
            ) { slot in
                stripSlotContent(slot: slot)
            }
            .frame(width: stripSize(for: geometry).width, height: stripSize(for: geometry).height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    private func stripFooterText() -> String {
        theme.stripFooterText ?? "FotoX"
    }

    private func stripSize(for geometry: GeometryProxy) -> CGSize {
        let maxWidth = geometry.size.width * 0.8
        let maxHeight = geometry.size.height * 0.85
        return StripCompositeMetrics.sizeThatFits(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            slotCount: page.slots.count
        )
    }

    @ViewBuilder
    private func stripSlotContent(slot: StripSlot) -> some View {
        if let asset = assetsByIndex[slot.id] {
            Button {
                onSelectAsset(asset)
            } label: {
                switch asset.kind {
                case .photo:
                    stripPhotoContent(asset: asset)
                case .video:
                    stripVideoContent(asset: asset)
                }
            }
            .buttonStyle(.plain)
        } else {
            ZStack {
                Color.black.opacity(0.2)
                Image(systemName: slot.isVideo ? "video.fill" : "photo")
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    @ViewBuilder
    private func stripPhotoContent(asset: GalleryAsset) -> some View {
        let url = asset.isLocallyAvailable ? asset.localURL : WorkerAPIClient.shared.assetURL(path: asset.remotePath)
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                ZStack {
                    Color.black.opacity(0.2)
                    Image(systemName: "photo")
                        .foregroundStyle(.white.opacity(0.4))
                }
            case .empty:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            @unknown default:
                Color.black.opacity(0.2)
            }
        }
    }

    @ViewBuilder
    private func stripVideoContent(asset: GalleryAsset) -> some View {
        let posterURL: URL? = {
            if asset.isPosterLocallyAvailable {
                return asset.localPosterURL
            }
            if let posterPath = asset.posterPath {
                return WorkerAPIClient.shared.assetURL(path: posterPath)
            }
            return nil
        }()

        if let posterURL {
            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.black.opacity(0.2)
                        Image(systemName: "video.fill")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                @unknown default:
                    Color.black.opacity(0.2)
                }
            }
        } else {
            ZStack {
                Color.black.opacity(0.2)
                Image(systemName: "video.fill")
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}

// MARK: - Asset View

struct AssetDetailView: View {
    let asset: GalleryAsset
    let playerManager: VideoPlayerManager

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AssetView(
                asset: asset,
                isActive: true,
                playerManager: playerManager
            )
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(20)
            }
        }
        .onDisappear {
            playerManager.stop(id: asset.id)
        }
    }
}

struct AssetView: View {
    let asset: GalleryAsset
    let isActive: Bool
    let playerManager: VideoPlayerManager
    
    var body: some View {
        GeometryReader { geometry in
            switch asset.kind {
            case .photo:
                PhotoAssetView(asset: asset, geometry: geometry)
            case .video:
                VideoAssetView(
                    asset: asset,
                    geometry: geometry,
                    isActive: isActive,
                    playerManager: playerManager
                )
            }
        }
    }
}

/// Photo asset view with async loading
struct PhotoAssetView: View {
    let asset: GalleryAsset
    let geometry: GeometryProxy
    
    var body: some View {
        ThemedStripFrame {
            photoContent
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    @ViewBuilder
    private var photoContent: some View {
        // Local-first loading: check local URL first
        if let localURL = asset.localURL, asset.isLocallyAvailable {
            AsyncImage(url: localURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                case .failure:
                    errorView("Failed to load photo")
                case .empty:
                    loadingView
                @unknown default:
                    loadingView
                }
            }
        } else {
            // Load from remote
            AsyncImage(url: WorkerAPIClient.shared.assetURL(path: asset.remotePath)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                case .failure:
                    errorView("Failed to load photo")
                case .empty:
                    loadingView
                @unknown default:
                    loadingView
                }
            }
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color.black
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.red.opacity(0.7))
            Text(message)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

/// Video asset view with autoplay support
struct VideoAssetView: View {
    let asset: GalleryAsset
    let geometry: GeometryProxy
    let isActive: Bool
    let playerManager: VideoPlayerManager
    
    @State private var player: AVPlayer?
    
    private var videoURL: URL? {
        if let localURL = asset.localURL, asset.isLocallyAvailable {
            return localURL
        } else {
            return WorkerAPIClient.shared.assetURL(path: asset.remotePath)
        }
    }
    
    var body: some View {
        ThemedStripFrame {
            ZStack {
                if isActive, let player = player {
                    VideoPlayer(player: player)
                } else {
                    posterView
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            updatePlayback()
        }
        .onChange(of: isActive) { _, _ in
            updatePlayback()
        }
        .onDisappear {
            playerManager.stop(id: asset.id)
            player = nil
        }
    }
    
    private var posterURL: URL? {
        if let localPosterURL = asset.localPosterURL, asset.isPosterLocallyAvailable {
            return localPosterURL
        }
        if let posterPath = asset.posterPath {
            return WorkerAPIClient.shared.assetURL(path: posterPath)
        }
        return nil
    }
    
    @ViewBuilder
    private var posterView: some View {
        ZStack {
            Color.black
            if let posterURL = posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Color.black
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    @unknown default:
                        Color.black
                    }
                }
            }
            
            Image(systemName: "play.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
    
    private func updatePlayback() {
        guard isActive, let url = videoURL else {
            playerManager.stop(id: asset.id)
            player = nil
            return
        }
        player = playerManager.play(id: asset.id, url: url)
    }
}

// MARK: - Asset View Helpers

extension AssetView {
    fileprivate var loadingView: some View {
        ZStack {
            Color.black
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
        }
    }
    
    fileprivate func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.red.opacity(0.7))
            Text(message)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Thumbnail Button

struct StripPageButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? .white.opacity(0.2) : .white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

struct ThumbnailButton: View {
    let asset: GalleryAsset
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                thumbnailImage
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )
                
                // Video indicator
                if asset.kind == .video {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    @ViewBuilder
    private var thumbnailImage: some View {
        if asset.kind == .photo {
            // Photo - load directly
            if let localURL = asset.localURL, asset.isLocallyAvailable {
                AsyncImage(url: localURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        thumbnailPlaceholder
                    }
                }
            } else {
                AsyncImage(url: WorkerAPIClient.shared.assetURL(path: asset.remotePath)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        thumbnailPlaceholder
                    }
                }
            }
        } else {
            // Video - load poster image if available
            // Local-first: check if we have a local poster URL
            if let localPosterURL = asset.localPosterURL, asset.isPosterLocallyAvailable {
                AsyncImage(url: localPosterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        videoPlaceholder
                    }
                }
            } else if let posterPath = asset.posterPath {
                // Fallback to remote poster
                AsyncImage(url: WorkerAPIClient.shared.assetURL(path: posterPath)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        videoPlaceholder
                    }
                }
            } else {
                videoPlaceholder
            }
        }
    }
    
    private var videoPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: "video.fill")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.3)
            ProgressView()
                .scaleEffect(0.6)
        }
    }
}

#Preview {
    SessionDetailView(session: GallerySession(
        id: "test",
        sessionId: "test-session",
        eventId: 1,
        createdAt: Date(),
        source: .local,
        thumbPath: nil,
        localThumbURL: nil,
        galleryPath: "s/test",
        assets: []
    ))
}
