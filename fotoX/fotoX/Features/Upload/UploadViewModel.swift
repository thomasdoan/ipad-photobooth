//
//  UploadViewModel.swift
//  fotoX
//
//  ViewModel for the upload flow
//

import Foundation
import Observation

/// State of an individual upload
enum UploadItemState: Equatable, Sendable {
    case pending
    case uploading
    case completed
    case failed(String)
}

/// Represents an item to upload
struct UploadItem: Identifiable, Sendable {
    let id: UUID
    let stripIndex: Int
    let kind: AssetKind
    let fileName: String
    let mimeType: String
    var state: UploadItemState
    
    var displayName: String {
        "\(kind == .video ? "Video" : "Photo") \(stripIndex + 1)"
    }
}

/// ViewModel for managing uploads
@Observable
final class UploadViewModel<SessionService: SessionServicing> {
    // MARK: - State
    
    /// Items to upload
    var uploadItems: [UploadItem] = []
    
    /// Overall progress (0.0 - 1.0)
    var progress: Double = 0
    
    /// Whether upload is in progress
    var isUploading: Bool = false
    
    /// Whether all uploads completed
    var isComplete: Bool = false
    
    /// Current error
    var errorMessage: String?
    
    /// Number of retry attempts
    var retryCount: Int = 0
    
    /// Maximum retries
    let maxRetries = 3
    
    // MARK: - Dependencies
    
    private let sessionService: SessionService
    private let testableServices: TestableServiceContainer?
    
    // MARK: - Initialization
    
    init(sessionService: SessionService, testableServices: TestableServiceContainer? = nil) {
        self.sessionService = sessionService
        self.testableServices = testableServices
    }
    
    // MARK: - Actions
    
    /// Prepares upload items from captured strips
    func prepareUploads(from strips: [CapturedStrip]) {
        uploadItems = strips.flatMap { strip -> [UploadItem] in
            [
                UploadItem(
                    id: UUID(),
                    stripIndex: strip.stripIndex,
                    kind: .video,
                    fileName: "strip_\(strip.stripIndex)_video.mov",
                    mimeType: "video/quicktime",
                    state: .pending
                ),
                UploadItem(
                    id: UUID(),
                    stripIndex: strip.stripIndex,
                    kind: .photo,
                    fileName: "strip_\(strip.stripIndex)_photo.jpg",
                    mimeType: "image/jpeg",
                    state: .pending
                )
            ]
        }
        progress = 0
        isComplete = false
        errorMessage = nil
    }
    
    /// Starts the upload process
    @MainActor
    func startUpload(sessionId: Int, strips: [CapturedStrip], appState: AppState) async {
        guard !isUploading else { return }
        
        isUploading = true
        errorMessage = nil
        
        let totalItems = uploadItems.count
        var completedCount = 0
        
        for i in 0..<uploadItems.count {
            let item = uploadItems[i]
            
            // Update state to uploading
            uploadItems[i].state = .uploading
            
            do {
                // Find the corresponding strip
                guard let strip = strips.first(where: { $0.stripIndex == item.stripIndex }) else {
                    uploadItems[i].state = .failed("Strip not found")
                    continue
                }
                
                // Get the data to upload
                let data: Data
                let metadata: AssetUploadMetadata
                
                if item.kind == .video {
                    data = try Data(contentsOf: strip.videoURL)
                    metadata = AssetUploadMetadata(
                        kind: .video,
                        stripIndex: item.stripIndex,
                        sequenceIndex: AssetUploadMetadata.videoSequenceIndex
                    )
                } else {
                    data = strip.photoData
                    metadata = AssetUploadMetadata(
                        kind: .photo,
                        stripIndex: item.stripIndex,
                        sequenceIndex: AssetUploadMetadata.photoSequenceIndex
                    )
                }
                
                // Upload using testable services if available
                if let testable = testableServices {
                    _ = try await testable.uploadAsset(
                        sessionId: sessionId,
                        fileData: data,
                        fileName: item.fileName,
                        mimeType: item.mimeType,
                        metadata: metadata
                    )
                } else {
                    _ = try await sessionService.uploadAsset(
                        sessionId: sessionId,
                        fileData: data,
                        fileName: item.fileName,
                        mimeType: item.mimeType,
                        metadata: metadata
                    )
                }
                
                uploadItems[i].state = .completed
                completedCount += 1
                progress = Double(completedCount) / Double(totalItems)
                appState.assetUploaded()
                
            } catch let error as APIError {
                uploadItems[i].state = .failed(error.userMessage)
                errorMessage = error.userMessage
            } catch {
                uploadItems[i].state = .failed(error.localizedDescription)
                errorMessage = "Upload failed: \(error.localizedDescription)"
            }
        }
        
        isUploading = false
        
        // Check if all completed
        let allCompleted = uploadItems.allSatisfy { 
            if case .completed = $0.state { return true }
            return false
        }
        
        isComplete = allCompleted
    }
    
    /// Retries failed uploads
    @MainActor
    func retryFailed(sessionId: Int, strips: [CapturedStrip], appState: AppState) async {
        guard retryCount < maxRetries else {
            errorMessage = "Maximum retry attempts reached"
            return
        }
        
        retryCount += 1
        
        // Reset failed items to pending
        for i in 0..<uploadItems.count {
            if case .failed = uploadItems[i].state {
                uploadItems[i].state = .pending
            }
        }
        
        errorMessage = nil
        
        // Restart upload for pending items
        await startUpload(sessionId: sessionId, strips: strips, appState: appState)
    }
    
    /// Checks if there are failed uploads
    var hasFailedUploads: Bool {
        uploadItems.contains { 
            if case .failed = $0.state { return true }
            return false
        }
    }
    
    /// Count of completed uploads
    var completedCount: Int {
        uploadItems.filter { 
            if case .completed = $0.state { return true }
            return false
        }.count
    }
}
