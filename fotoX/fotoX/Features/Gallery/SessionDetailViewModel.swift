//
//  SessionDetailViewModel.swift
//  fotoX
//
//  ViewModel for session detail view with on-demand asset loading
//

import Foundation
import Observation

/// ViewModel for displaying session details with on-demand asset loading
@Observable
final class SessionDetailViewModel {
    // MARK: - State
    
    /// The session being displayed
    private(set) var session: GallerySession
    
    /// Assets for this session (loaded on demand for remote sessions)
    var assets: [GalleryAsset] = []
    
    /// Whether assets are being loaded
    var isLoadingAssets: Bool = false
    
    /// Error message if asset loading failed
    var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let apiClient: WorkerAPIClient
    
    // MARK: - Initialization
    
    init(session: GallerySession, apiClient: WorkerAPIClient = WorkerAPIClient()) {
        self.session = session
        self.apiClient = apiClient
        // Start with any assets the session already has (from local)
        self.assets = session.assets
    }
    
    // MARK: - Actions
    
    /// Loads assets for the session if not already loaded
    @MainActor
    func loadAssetsIfNeeded() async {
        // If we already have assets, don't reload
        guard assets.isEmpty else { return }
        
        // For local-only sessions, assets should already be populated
        guard session.source == .remote || session.source == .both else { return }
        
        isLoadingAssets = true
        errorMessage = nil
        
        do {
            let manifest = try await apiClient.fetchSessionManifest(sessionId: session.sessionId)
            assets = manifest.assets.map { manifestAsset in
                GalleryAsset(
                    id: manifestAsset.id,
                    kind: manifestAsset.kind,
                    stripIndex: manifestAsset.stripIndex,
                    remotePath: manifestAsset.path,
                    localURL: nil, // Remote assets have no local URL
                    mimeType: manifestAsset.contentType,
                    posterPath: manifestAsset.posterPath
                )
            }
        } catch {
            errorMessage = "Failed to load assets: \(error.localizedDescription)"
        }
        
        isLoadingAssets = false
    }
    
    // MARK: - Computed
    
    /// Assets sorted by strip index and kind
    var sortedAssets: [GalleryAsset] {
        assets.sorted { a, b in
            if a.stripIndex != b.stripIndex {
                return a.stripIndex < b.stripIndex
            }
            // Videos before photos within a strip
            return a.kind == .video && b.kind == .photo
        }
    }
}

