//
//  SimulatorCameraController.swift
//  fotoX
//
//  Simulated camera for iOS Simulator testing
//

import AVFoundation
import UIKit
import CoreImage
import os

/// Simulated camera controller for testing in iOS Simulator
/// Generates sample video and photo content without requiring real camera hardware
@MainActor
final class SimulatorCameraController: CameraControlling {
    // MARK: - Properties

    weak var delegate: CameraControllerDelegate?

    /// No preview layer in simulator mode
    var previewLayer: AVCaptureVideoPreviewLayer? { nil }

    /// Whether currently recording
    private(set) var isRecording = false

    /// Whether this is a simulator camera
    var isSimulator: Bool { true }

    /// Current recording URL
    private var currentRecordingURL: URL?

    /// Recording start time
    private var recordingStartTime: Date?

    /// Background queue for video generation
    private let videoQueue = DispatchQueue(label: "com.fotox.simulator.video")

    private nonisolated static let logger = Logger(subsystem: "fotoX", category: "SimulatorCamera")

    /// Sample image colors for generating frames
    private nonisolated(unsafe) static let sampleColors: [UIColor] = [
        .systemBlue, .systemPurple, .systemPink,
        .systemOrange, .systemYellow, .systemGreen
    ]

    /// Current color index for variety
    private var colorIndex = 0

    // MARK: - CameraControlling

    func setup() async throws {
        // No setup needed for simulator
    }

    func startSession() {
        // No session needed for simulator
    }

    func stopSession() {
        // No session to stop for simulator
    }

    func startRecording() throws {
        guard !isRecording else { return }

        // Create unique file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoFileName = "strip_\(UUID().uuidString).mov"
        let videoURL = documentsPath.appendingPathComponent(videoFileName)

        currentRecordingURL = videoURL
        isRecording = true
        recordingStartTime = Date()

        delegate?.cameraController(self, didStartRecording: videoURL)
        // Recording duration is managed by CaptureViewModel
    }

    func stopRecording() {
        guard isRecording, let videoURL = currentRecordingURL else { return }

        isRecording = false

        let actualDuration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 3.0

        // Generate the video file asynchronously
        Task.detached { [weak self] in
            do {
                try self?.generateSampleVideo(at: videoURL, duration: actualDuration)

                await MainActor.run {
                    guard let self = self else { return }
                    self.delegate?.cameraController(self, didFinishRecording: videoURL)
                }
            } catch {
                await MainActor.run {
                    guard let self = self else { return }
                    self.delegate?.cameraController(self, didFailWithError: .recordingFailed(error.localizedDescription))
                }
            }
        }
    }

    func capturePhoto() async throws -> Data {
        let sampleIndex = colorIndex % Self.sampleColors.count
        colorIndex = (colorIndex + 1) % Self.sampleColors.count

        let photoData = try await Task.detached { [sampleIndex] in
            try Self.generateSamplePhoto(colorIndex: sampleIndex)
        }.value

        await MainActor.run {
            self.delegate?.cameraController(self, didCapturePhoto: photoData)
        }
        return photoData
    }

    func cleanupTempFiles() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            for file in files
            where file.pathExtension == "mov"
            && file.lastPathComponent.hasPrefix("strip_") {
                try? fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to cleanup temp files: \(error)")
        }
    }

    // MARK: - Sample Content Generation

    /// Generates a sample video file at the specified URL
    private nonisolated func generateSampleVideo(at url: URL, duration: TimeInterval) throws {
        let width = 1080
        let height = 1920 // 9:16 portrait
        let frameRate: Int32 = 30
        let totalFrames = Int(duration * Double(frameRate))

        // Setup AVAssetWriter
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]

        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )

        writer.add(writerInput)

        guard writer.startWriting() else {
            throw CameraError.recordingFailed("Failed to start writing video")
        }

        writer.startSession(atSourceTime: .zero)

        // Generate frames
        for frameIndex in 0..<totalFrames {
            while !writerInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.01)
            }

            let presentationTime = CMTime(value: CMTimeValue(frameIndex), timescale: frameRate)
            let progress = Double(frameIndex) / Double(totalFrames)

            if let pixelBuffer = createSamplePixelBuffer(width: width, height: height, progress: progress) {
                adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
            }
        }

        writerInput.markAsFinished()

        // Wait for writing to complete
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()

        if writer.status == .failed {
            throw CameraError.recordingFailed(writer.error?.localizedDescription ?? "Unknown error")
        }
    }

    /// Creates a pixel buffer with gradient colors and animation
    private nonisolated func createSamplePixelBuffer(width: Int, height: Int, progress: Double) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?

        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        // Create animated gradient background
        let colorIndex1 = Int(progress * 3) % Self.sampleColors.count
        let colorIndex2 = (colorIndex1 + 1) % Self.sampleColors.count

        let color1 = Self.sampleColors[colorIndex1]
        let color2 = Self.sampleColors[colorIndex2]

        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [color1.cgColor, color2.cgColor] as CFArray,
            locations: [0, 1]
        )

        if let gradient {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: CGFloat(width), y: CGFloat(height)),
                options: []
            )
        } else {
            // CGGradient(colorsSpace:colors:locations:) can return nil; if `gradient` is missing, fill a solid background so the frame renders.
            context.setFillColor(color1.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        }

        // Add "SIMULATOR" text
        context.setFillColor(UIColor.white.withAlphaComponent(0.8).cgColor)

        let text = "SIMULATOR"
        let fontSize = CGFloat(width) / 8
        let font = UIFont.boldSystemFont(ofSize: fontSize)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]

        let textSize = text.size(withAttributes: textAttributes)
        let textRect = CGRect(
            x: (CGFloat(width) - textSize.width) / 2,
            y: (CGFloat(height) - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        // Draw text using UIGraphics
        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        text.draw(in: textRect, withAttributes: textAttributes)
        UIGraphicsPopContext()

        // Add recording indicator circle (pulsing)
        let pulse = sin(progress * .pi * 8) * 0.3 + 0.7
        context.setFillColor(UIColor.red.withAlphaComponent(CGFloat(pulse)).cgColor)
        let indicatorSize: CGFloat = 40
        let indicatorRect = CGRect(
            x: 60,
            y: CGFloat(height) - 100,
            width: indicatorSize,
            height: indicatorSize
        )
        context.fillEllipse(in: indicatorRect)

        return buffer
    }

    /// Generates a sample photo as JPEG data
    private nonisolated static func generateSamplePhoto(colorIndex: Int) throws -> Data {
        let size = CGSize(width: 1080, height: 1920)

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Gradient background
            let color1 = Self.sampleColors[colorIndex % Self.sampleColors.count]
            let color2 = Self.sampleColors[(colorIndex + 1) % Self.sampleColors.count]

            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [color1.cgColor, color2.cgColor] as CFArray,
                locations: [0, 1]
            )

            if let gradient {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            } else {
                Self.logger.error("Failed to create gradient for simulator sample photo.")
                context.cgContext.setFillColor(color1.cgColor)
                context.cgContext.fill(CGRect(origin: .zero, size: size))
            }

            // Add "PHOTO" text
            let text = "PHOTO"
            let fontSize = size.width / 6
            let font = UIFont.boldSystemFont(ofSize: fontSize)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]

            let textSize = text.size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: textAttributes)

            // Add timestamp
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let timestampFont = UIFont.systemFont(ofSize: 36)
            let timestampAttributes: [NSAttributedString.Key: Any] = [
                .font: timestampFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]
            let timestampSize = timestamp.size(withAttributes: timestampAttributes)
            let timestampRect = CGRect(
                x: (size.width - timestampSize.width) / 2,
                y: size.height - 150,
                width: timestampSize.width,
                height: timestampSize.height
            )
            timestamp.draw(in: timestampRect, withAttributes: timestampAttributes)
        }

        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            throw JPEGEncodingError.failedToEncode
        }
        return jpegData
    }
}

private enum JPEGEncodingError: LocalizedError {
    case failedToEncode

    var errorDescription: String? {
        switch self {
        case .failedToEncode:
            return "Failed to encode image to JPEG"
        }
    }
}

// MARK: - Camera Controller Factory

/// Factory for creating the appropriate camera controller based on environment
enum CameraControllerFactory {
    /// Creates the appropriate camera controller for the current environment
    static func makeController() -> any CameraControlling {
        #if targetEnvironment(simulator)
        return SimulatorCameraController()
        #else
        return CameraController()
        #endif
    }
}
