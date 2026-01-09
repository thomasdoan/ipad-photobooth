//
//  SimulatorCameraController.swift
//  fotoX
//
//  Simulated camera for iOS Simulator testing
//

import Foundation
import AVFoundation
import CoreGraphics
import CoreImage
import CoreText
import ImageIO
import UniformTypeIdentifiers
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

    private struct SampleColor: Sendable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
    }

    /// Sample image colors for generating frames
    private nonisolated static let sampleColors: [SampleColor] = [
        SampleColor(red: 0.0, green: 0.48, blue: 1.0),
        SampleColor(red: 0.69, green: 0.32, blue: 0.87),
        SampleColor(red: 1.0, green: 0.18, blue: 0.33),
        SampleColor(red: 1.0, green: 0.58, blue: 0.0),
        SampleColor(red: 1.0, green: 0.8, blue: 0.0),
        SampleColor(red: 0.0, green: 0.8, blue: 0.4)
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
        let tempDirectory = FileManager.default.temporaryDirectory
        let videoFileName = "strip_\(UUID().uuidString).mov"
        let videoURL = tempDirectory.appendingPathComponent(videoFileName)

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

        Task {
            do {
                try await Task.detached { [videoURL, actualDuration] in
                    try Self.generateSampleVideo(at: videoURL, duration: actualDuration)
                }.value
                delegate?.cameraController(self, didFinishRecording: videoURL)
            } catch {
                delegate?.cameraController(self, didFailWithError: .recordingFailed(error.localizedDescription))
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
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            for file in files
            where file.pathExtension == "mov"
            && file.lastPathComponent.hasPrefix("strip_") {
                try? fileManager.removeItem(at: file)
            }
        } catch {
            Self.logger.error("Failed to cleanup temp files: \(String(describing: error))")
        }
    }

    // MARK: - Sample Content Generation

    private nonisolated static func makeColor(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat,
        in colorSpace: CGColorSpace
    ) -> CGColor? {
        CGColor(colorSpace: colorSpace, components: [red, green, blue, alpha])
    }

    private nonisolated static func makeColor(
        _ color: SampleColor,
        alpha: CGFloat = 1.0,
        in colorSpace: CGColorSpace
    ) -> CGColor? {
        makeColor(red: color.red, green: color.green, blue: color.blue, alpha: alpha, in: colorSpace)
    }

    private nonisolated static func makeTextLine(
        _ text: String,
        fontName: String,
        fontSize: CGFloat,
        color: CGColor
    ) -> (CTLine, CGRect) {
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds, .useOpticalBounds])
        return (line, bounds)
    }

    private nonisolated static func drawCenteredText(
        _ text: String,
        in context: CGContext,
        canvasSize: CGSize,
        fontName: String,
        fontSize: CGFloat,
        color: CGColor
    ) {
        let (line, bounds) = makeTextLine(text, fontName: fontName, fontSize: fontSize, color: color)
        let x = (canvasSize.width - bounds.width) / 2 - bounds.origin.x
        let y = (canvasSize.height - bounds.height) / 2 - bounds.origin.y
        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private nonisolated static func drawCenteredTextAtTop(
        _ text: String,
        in context: CGContext,
        canvasSize: CGSize,
        top: CGFloat,
        fontName: String,
        fontSize: CGFloat,
        color: CGColor
    ) {
        let (line, bounds) = makeTextLine(text, fontName: fontName, fontSize: fontSize, color: color)
        let x = (canvasSize.width - bounds.width) / 2 - bounds.origin.x
        let y = top - (bounds.origin.y + bounds.height)
        context.saveGState()
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    /// Generates a sample video file at the specified URL
    private nonisolated static func generateSampleVideo(at url: URL, duration: TimeInterval) throws {
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

            if let pixelBuffer = Self.createSamplePixelBuffer(width: width, height: height, progress: progress) {
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
    private nonisolated static func createSamplePixelBuffer(width: Int, height: Int, progress: Double) -> CVPixelBuffer? {
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

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Create animated gradient background
        let colorIndex1 = Int(progress * 3) % Self.sampleColors.count
        let colorIndex2 = (colorIndex1 + 1) % Self.sampleColors.count

        let color1 = Self.sampleColors[colorIndex1]
        let color2 = Self.sampleColors[colorIndex2]

        let color1CG = Self.makeColor(color1, in: colorSpace)
        let color2CG = Self.makeColor(color2, in: colorSpace)
        let gradient = color1CG.flatMap { firstColor in
            color2CG.flatMap { secondColor in
                CGGradient(
                    colorsSpace: colorSpace,
                    colors: [firstColor, secondColor] as CFArray,
                    locations: [0, 1]
                )
            }
        }

        if let gradient {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: CGFloat(width), y: CGFloat(height)),
                options: []
            )
        } else {
            // CGGradient(colorsSpace:colors:locations:) can return nil; if `gradient` is missing, fill a solid background so the frame renders.
            Self.logger.error("Failed to create gradient for simulator video frame.")
            let fallbackColor = color1CG ?? Self.makeColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0, in: colorSpace)
            if let fallbackColor {
                context.setFillColor(fallbackColor)
                context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            }
        }

        // Add "SIMULATOR" text
        if let textColor = Self.makeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8, in: colorSpace) {
            let fontSize = CGFloat(width) / 8
            Self.drawCenteredText(
                "SIMULATOR",
                in: context,
                canvasSize: CGSize(width: CGFloat(width), height: CGFloat(height)),
                fontName: "Helvetica-Bold",
                fontSize: fontSize,
                color: textColor
            )
        }

        // Add recording indicator circle (pulsing)
        let pulse = sin(progress * .pi * 8) * 0.3 + 0.7
        let indicatorSize: CGFloat = 40
        let indicatorRect = CGRect(
            x: 60,
            y: CGFloat(height) - 100,
            width: indicatorSize,
            height: indicatorSize
        )
        if let indicatorColor = Self.makeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: CGFloat(pulse), in: colorSpace) {
            context.setFillColor(indicatorColor)
            context.fillEllipse(in: indicatorRect)
        }

        return buffer
    }

    /// Generates a sample photo as JPEG data
    private nonisolated static func generateSamplePhoto(colorIndex: Int) throws -> Data {
        let width = 1080
        let height = 1920
        let size = CGSize(width: width, height: height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw JPEGEncodingError.failedToEncode
        }

        // Gradient background
        let color1 = Self.sampleColors[colorIndex % Self.sampleColors.count]
        let color2 = Self.sampleColors[(colorIndex + 1) % Self.sampleColors.count]
        let color1CG = Self.makeColor(color1, in: colorSpace)
        let color2CG = Self.makeColor(color2, in: colorSpace)
        let gradient = color1CG.flatMap { firstColor in
            color2CG.flatMap { secondColor in
                CGGradient(
                    colorsSpace: colorSpace,
                    colors: [firstColor, secondColor] as CFArray,
                    locations: [0, 1]
                )
            }
        }

        if let gradient {
            context.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        } else {
            Self.logger.error("Failed to create gradient for simulator sample photo.")
            let fallbackColor = color1CG ?? Self.makeColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0, in: colorSpace)
            if let fallbackColor {
                context.setFillColor(fallbackColor)
                context.fill(CGRect(origin: .zero, size: size))
            }
        }

        // Add "PHOTO" text
        if let textColor = Self.makeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9, in: colorSpace) {
            Self.drawCenteredText(
                "PHOTO",
                in: context,
                canvasSize: size,
                fontName: "Helvetica-Bold",
                fontSize: size.width / 6,
                color: textColor
            )
        }

        // Add timestamp
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        if let timestampColor = Self.makeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7, in: colorSpace) {
            Self.drawCenteredTextAtTop(
                timestamp,
                in: context,
                canvasSize: size,
                top: 150,
                fontName: "Helvetica",
                fontSize: 36,
                color: timestampColor
            )
        }

        guard let cgImage = context.makeImage() else {
            throw JPEGEncodingError.failedToEncode
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw JPEGEncodingError.failedToEncode
        }

        CGImageDestinationAddImage(
            destination,
            cgImage,
            [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw JPEGEncodingError.failedToEncode
        }

        return data as Data
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
