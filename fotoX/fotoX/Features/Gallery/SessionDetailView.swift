//
//  SessionDetailView.swift
//  fotoX
//
//  Detail view for a session showing all photos and videos
//

import SwiftUI
import AVKit

/// Full-screen view for viewing a session's photos and videos
@MainActor
struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(AppState.self) private var appState
    
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
                        // Main content: media + QR side by side
                        HStack(spacing: 0) {
                            // Left: Asset pager
                            assetPager
                                .frame(maxWidth: .infinity)
                            
                            // Right: QR code panel
                            qrCodePanel
                                .frame(width: 280)
                                .background(.ultraThinMaterial)
                        }
                        
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
            .fullScreenCover(item: $focusedAsset) { asset in
                AssetDetailView(asset: asset, playerManager: playerManager)
            }
        }
        .fotoXStatusBarHidden()
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
        let footerText = stripFooterText()
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(stripPages.enumerated()), id: \.element.id) { index, page in
                    StripPageView(
                        page: page,
                        footerText: footerText,
                        assetsByIndex: assetsByIndex(for: page.kind),
                        onSelectAsset: { asset in
                            focusedAsset = asset
                        },
                        slotAspectRatio: stripAspectRatio
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
                            systemImage: page.kind.isVideo ? "video.fill" : "photo.stack.fill",
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
    
    // MARK: - QR Code Panel
    
    private var qrCodePanel: some View {
        let galleryURL = QRCodeGenerator.galleryURL(from: viewModel.session.publicGalleryPath)
        
        return VStack(spacing: 20) {
            Spacer()
            
            // Title
            VStack(spacing: 4) {
                Text("Scan to View")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Access online")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            // QR Code
            QRCodeDisplayView(
                urlString: galleryURL,
                config: QRCodeDisplayConfig(
                    maxSize: 160,
                    padding: 16,
                    cornerRadius: 16,
                    shadowRadius: 8,
                    shadowY: 4,
                    shadowOpacity: 0.2
                )
            )
            
            // URL (compact)
            Text(viewModel.session.sessionId.prefix(8) + "...")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Helpers
}

private extension SessionDetailView {
    var stripAspectRatio: CGFloat {
        appState.resolvedCaptureAspectRatio.widthToHeight
    }

    var stripPages: [StripPage] {
        var pages: [StripPage] = []

        if let compositePhoto = compositeAsset(for: .stripPhoto) {
            pages.append(
                StripPage(
                    kind: .stripPhoto,
                    title: "Strip Photo",
                    slots: [],
                    slotCount: 3,
                    compositeAsset: compositePhoto
                )
            )
        }

        if let compositeVideo = compositeAsset(for: .stripVideo) {
            pages.append(
                StripPage(
                    kind: .stripVideo,
                    title: "Strip Video",
                    slots: [],
                    slotCount: 3,
                    compositeAsset: compositeVideo
                )
            )
        }

        return pages
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

    func compositeAsset(for kind: AssetKind) -> GalleryAsset? {
        viewModel.assets.first { $0.kind == kind }
    }

    func stripFooterText() -> String {
        theme.stripFooterText ?? appState.selectedEvent?.name ?? "FotoX"
    }
}

private struct StripPage: Identifiable {
    let id: String
    let kind: AssetKind
    let title: String
    let slots: [StripSlot]
    let slotCount: Int
    let compositeAsset: GalleryAsset?

    init(
        kind: AssetKind,
        title: String,
        slots: [StripSlot],
        slotCount: Int,
        compositeAsset: GalleryAsset? = nil
    ) {
        self.id = kind.rawValue
        self.kind = kind
        self.title = title
        self.slots = slots
        self.slotCount = slotCount
        self.compositeAsset = compositeAsset
    }
}

private struct StripPageView: View {
    let page: StripPage
    let footerText: String
    let assetsByIndex: [Int: GalleryAsset]
    let onSelectAsset: (GalleryAsset) -> Void
    let slotAspectRatio: CGFloat

    var body: some View {
        GeometryReader { geometry in
            if let compositeAsset = page.compositeAsset {
                CompositeStripAssetView(
                    asset: compositeAsset,
                    geometry: geometry,
                    onSelectAsset: onSelectAsset,
                    slotAspectRatio: slotAspectRatio
                )
            } else {
                StripCompositeView(
                    slots: page.slots,
                    footerText: footerText,
                    slotAspectRatio: slotAspectRatio
                ) { slot in
                    stripSlotContent(slot: slot)
                }
                .frame(width: stripSize(for: geometry).width, height: stripSize(for: geometry).height)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }

    private func stripSize(for geometry: GeometryProxy) -> CGSize {
        let maxWidth = geometry.size.width * 0.8
        let maxHeight = geometry.size.height * 0.85
        return StripCompositeMetrics.sizeThatFits(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            slotCount: page.slotCount,
            slotAspectRatio: slotAspectRatio
        )
    }

    @ViewBuilder
    private func stripSlotContent(slot: StripSlot) -> some View {
        if let asset = assetsByIndex[slot.id] {
            Button {
                onSelectAsset(asset)
            } label: {
                if asset.kind.isVideo {
                    stripVideoContent(asset: asset)
                } else {
                    stripPhotoContent(asset: asset)
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

private struct CompositeStripAssetView: View {
    let asset: GalleryAsset
    let geometry: GeometryProxy
    let onSelectAsset: (GalleryAsset) -> Void
    let slotAspectRatio: CGFloat

    var body: some View {
        let size = stripSize(for: geometry)
        Button {
            onSelectAsset(asset)
        } label: {
            ZStack {
                Color.black.opacity(0.2)

                if asset.kind.isVideo {
                    compositeVideoPreview
                } else {
                    compositePhotoPreview
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .buttonStyle(.plain)
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }

    private func stripSize(for geometry: GeometryProxy) -> CGSize {
        let maxWidth = geometry.size.width * 0.8
        let maxHeight = geometry.size.height * 0.85
        return StripCompositeMetrics.sizeThatFits(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            slotCount: 3,
            slotAspectRatio: slotAspectRatio
        )
    }

    @ViewBuilder
    private var compositePhotoPreview: some View {
        let url = asset.isLocallyAvailable ? asset.localURL : WorkerAPIClient.shared.assetURL(path: asset.remotePath)
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.white.opacity(0.4))
            case .empty:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            @unknown default:
                Color.black.opacity(0.2)
            }
        }
    }

    @ViewBuilder
    private var compositeVideoPreview: some View {
        let posterURL: URL? = {
            if asset.isPosterLocallyAvailable {
                return asset.localPosterURL
            }
            if let posterPath = asset.posterPath {
                return WorkerAPIClient.shared.assetURL(path: posterPath)
            }
            return nil
        }()

        ZStack {
            if let posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "video.fill")
                            .foregroundStyle(.white.opacity(0.4))
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    @unknown default:
                        Color.black.opacity(0.2)
                    }
                }
            } else {
                Image(systemName: "video.fill")
                    .foregroundStyle(.white.opacity(0.4))
            }

            Image(systemName: "play.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

// MARK: - Asset View

@MainActor
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
            .ignoresSafeArea()
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
        .fotoXStatusBarHidden()
    }
}

struct AssetView: View {
    let asset: GalleryAsset
    let isActive: Bool
    let playerManager: VideoPlayerManager
    
    var body: some View {
        GeometryReader { geometry in
            if asset.kind.isVideo {
                VideoAssetView(
                    asset: asset,
                    geometry: geometry,
                    isActive: isActive,
                    playerManager: playerManager
                )
            } else {
                PhotoAssetView(asset: asset, geometry: geometry)
            }
        }
    }
}

/// Photo asset view with async loading
struct PhotoAssetView: View {
    let asset: GalleryAsset
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            Color.black
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
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        ZStack {
            Color.black
            if isActive, let player = player {
                VideoPlayer(player: player)
            } else {
                posterView
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
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

// MARK: - Strip Page Button

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

// MARK: - Session QR Code View

struct SessionQRCodeView: View {
    let session: GallerySession
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    
    private var galleryURL: String {
        QRCodeGenerator.galleryURL(from: session.publicGalleryPath)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
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
                
                VStack(spacing: 32) {
                    // Title
                    VStack(spacing: 8) {
                        Text("Scan to View")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        
                        Text("Access your photos and videos online")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    // QR Code (using modular component)
                    QRCodeDisplayView(urlString: galleryURL)
                    
                    // URL display (using modular component)
                    QRCodeURLView(urlString: galleryURL)
                    
                    // Session info
                    Text(session.formattedDateTime)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(40)
            }
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

#Preview("Session Detail") {
    SessionDetailView(session: GallerySession(
        id: "test",
        sessionId: "test-session",
        eventId: 1,
        createdAt: Date(),
        source: .local,
        thumbPath: nil,
        localThumbURL: nil,
        galleryPath: "s/test",
        publicGalleryPath: "session/test",
        assets: []
    ))
}

#Preview("QR Code") {
    SessionQRCodeView(session: GallerySession(
        id: "test",
        sessionId: "test-session",
        eventId: 1,
        createdAt: Date(),
        source: .local,
        thumbPath: nil,
        localThumbURL: nil,
        galleryPath: "s/test-session",
        publicGalleryPath: "session/test-session",
        assets: []
    ))
}
