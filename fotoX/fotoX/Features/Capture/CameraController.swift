//
//  CameraController.swift
//  fotoX
//
//  AVFoundation wrapper for video recording and photo capture
//

@preconcurrency import AVFoundation
import UIKit

/// Delegate protocol for camera events
protocol CameraControllerDelegate: AnyObject {
    func cameraController(_ controller: CameraController, didStartRecording url: URL)
    func cameraController(_ controller: CameraController, didFinishRecording url: URL)
    func cameraController(_ controller: CameraController, didCapturePhoto data: Data)
    func cameraController(_ controller: CameraController, didFailWithError error: CameraError)
}

/// Camera-related errors
enum CameraError: Error, LocalizedError {
    case cameraUnavailable
    case microphoneUnavailable
    case setupFailed(String)
    case recordingFailed(String)
    case captureFailed(String)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available"
        case .microphoneUnavailable:
            return "Microphone is not available"
        case .setupFailed(let reason):
            return "Camera setup failed: \(reason)"
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .captureFailed(let reason):
            return "Photo capture failed: \(reason)"
        case .permissionDenied:
            return "Camera permission was denied"
        }
    }
}

/// Controller for camera operations (video recording + photo capture)
final class CameraController: NSObject, @unchecked Sendable {
    // MARK: - Constants
    
    /// Video rotation angle for portrait orientation (degrees clockwise)
    private static let videoRotationAngle: CGFloat = 270
    
    // MARK: - Properties
    
    weak var delegate: CameraControllerDelegate?
    
    /// The capture session
    let captureSession = AVCaptureSession()
    
    /// Preview layer for displaying camera feed
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    
    /// Current recording URL
    private var currentRecordingURL: URL?
    
    /// Whether currently recording
    private(set) var isRecording = false
    
    /// Video output for recording
    private var movieOutput: AVCaptureMovieFileOutput?
    
    /// Photo output for capturing still images
    private var photoOutput: AVCapturePhotoOutput?
    
    /// Video device input
    private var videoInput: AVCaptureDeviceInput?
    
    /// Audio device input
    private var audioInput: AVCaptureDeviceInput?
    
    /// Session queue for camera operations
    private let sessionQueue = DispatchQueue(label: "com.fotox.camera.session")
    
    /// Completion handler for photo capture
    private var photoCaptureCompletion: ((Result<Data, CameraError>) -> Void)?
    
    // MARK: - Setup
    
    /// Checks camera permissions
    static func checkPermissions() async -> Bool {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        var cameraGranted = cameraStatus == .authorized
        var micGranted = micStatus == .authorized
        
        if cameraStatus == .notDetermined {
            cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        if micStatus == .notDetermined {
            micGranted = await AVCaptureDevice.requestAccess(for: .audio)
        }
        
        return cameraGranted && micGranted
    }
    
    /// Sets up the capture session
    func setup() async throws {
        // Check permissions first
        guard await CameraController.checkPermissions() else {
            throw CameraError.permissionDenied
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.setupFailed("Controller deallocated"))
                    return
                }
                
                do {
                    try self.configureSession()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func configureSession() throws {
        captureSession.beginConfiguration()
        
        // Set session preset for high-quality video (vertical 9:16)
        captureSession.sessionPreset = .high
        
        // Add video input (front camera for photobooth)
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            captureSession.commitConfiguration()
            throw CameraError.cameraUnavailable
        }
        
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            self.videoInput = videoInput
        } else {
            captureSession.commitConfiguration()
            throw CameraError.setupFailed("Cannot add video input")
        }
        
        // Add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                    self.audioInput = audioInput
                }
            } catch {
                // Audio is optional, continue without it
                print("Could not add audio input: \(error)")
            }
        }
        
        // Add movie output for video recording
        let movieOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
            self.movieOutput = movieOutput
            
            // Configure video orientation for portrait
            if let connection = movieOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(Self.videoRotationAngle) {
                    connection.videoRotationAngle = Self.videoRotationAngle
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true // Mirror front camera
                }
            }
        } else {
            captureSession.commitConfiguration()
            throw CameraError.setupFailed("Cannot add movie output")
        }
        
        // Add photo output
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            self.photoOutput = photoOutput
            
            // Configure for high quality photos
            photoOutput.isHighResolutionCaptureEnabled = true
            
            // Configure orientation
            if let connection = photoOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(Self.videoRotationAngle) {
                    connection.videoRotationAngle = Self.videoRotationAngle
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true
                }
            }
        } else {
            captureSession.commitConfiguration()
            throw CameraError.setupFailed("Cannot add photo output")
        }
        
        captureSession.commitConfiguration()
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        // Configure preview orientation
        if let connection = previewLayer.connection {
            if connection.isVideoRotationAngleSupported(Self.videoRotationAngle) {
                connection.videoRotationAngle = Self.videoRotationAngle
            }
        }
        
        self.previewLayer = previewLayer
    }
    
    // MARK: - Session Control
    
    /// Starts the capture session
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
    
    /// Stops the capture session
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
    
    // MARK: - Recording
    
    /// Starts video recording
    func startRecording() throws {
        guard let movieOutput = movieOutput else {
            throw CameraError.setupFailed("Movie output not configured")
        }
        
        guard !isRecording else { return }
        
        // Create unique file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoFileName = "strip_\(UUID().uuidString).mov"
        let videoURL = documentsPath.appendingPathComponent(videoFileName)
        
        currentRecordingURL = videoURL
        isRecording = true
        
        sessionQueue.async { [weak self] in
            movieOutput.startRecording(to: videoURL, recordingDelegate: self!)
        }
        
        delegate?.cameraController(self, didStartRecording: videoURL)
    }
    
    /// Stops video recording
    func stopRecording() {
        guard isRecording else { return }
        
        sessionQueue.async { [weak self] in
            self?.movieOutput?.stopRecording()
        }
    }
    
    // MARK: - Photo Capture
    
    /// Captures a photo
    func capturePhoto() async throws -> Data {
        guard let photoOutput = photoOutput else {
            throw CameraError.setupFailed("Photo output not configured")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.photoCaptureCompletion = { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            sessionQueue.async {
                let settings = AVCapturePhotoSettings()
                settings.isHighResolutionPhotoEnabled = true
                photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }
    
    // MARK: - Utilities
    
    /// Generates a thumbnail from a video URL
    static func generateThumbnail(from videoURL: URL) async -> Data? {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 400)
        
        do {
            let cgImage = try await generator.image(at: .zero).image
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: 0.8)
        } catch {
            return nil
        }
    }
    
    /// Cleans up temporary video files
    func cleanupTempFiles() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "mov" {
                try? fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to cleanup temp files: \(error)")
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Recording started
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        isRecording = false
        
        if let error = error {
            delegate?.cameraController(self, didFailWithError: .recordingFailed(error.localizedDescription))
            return
        }
        
        delegate?.cameraController(self, didFinishRecording: outputFileURL)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoCaptureCompletion?(.failure(.captureFailed(error.localizedDescription)))
            photoCaptureCompletion = nil
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            photoCaptureCompletion?(.failure(.captureFailed("No photo data")))
            photoCaptureCompletion = nil
            return
        }
        
        photoCaptureCompletion?(.success(data))
        photoCaptureCompletion = nil
        delegate?.cameraController(self, didCapturePhoto: data)
    }
}

