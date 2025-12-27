//
//  StripGenerator.swift
//  fotoX
//
//  Service for generating photo and video strips from captured media
//

import Foundation
import UIKit
import AVFoundation
import CoreImage

/// Errors that can occur during strip generation
enum StripGeneratorError: Error, LocalizedError {
    case invalidPhotoData
    case insufficientPhotos
    case insufficientVideos
    case videoCompositionFailed(String)
    case exportFailed(String)
    case logoLoadFailed

    var errorDescription: String? {
        switch self {
        case .invalidPhotoData:
            return "Invalid photo data provided"
        case .insufficientPhotos:
            return "At least 3 photos are required for a strip"
        case .insufficientVideos:
            return "At least 3 videos are required for a strip"
        case .videoCompositionFailed(let reason):
            return "Video composition failed: \(reason)"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .logoLoadFailed:
            return "Failed to load logo image"
        }
    }
}

/// Service for generating photo and video strips
actor StripGenerator {

    // MARK: - Constants

    /// Standard photo strip dimensions (2:6 ratio - classic photo booth strip)
    /// Width is base, height is 3x width for photos + logo section
    private static let stripWidth: CGFloat = 600
    private static let photoHeight: CGFloat = 600 // Square photos
    private static let logoHeight: CGFloat = 200 // Logo section at bottom
    private static let stripHeight: CGFloat = photoHeight * 3 + logoHeight // Total: 2000px

    /// Padding and styling
    private static let photoPadding: CGFloat = 10
    private static let cornerRadius: CGFloat = 0 // No rounded corners for classic look
    private static let backgroundColor = UIColor.white

    // MARK: - Photo Strip Generation

    /// Generates a photo strip from captured photos with an optional logo
    /// - Parameters:
    ///   - photos: Array of photo data (should be 3 photos)
    ///   - logoData: Optional logo image data
    ///   - backgroundColor: Background color for the strip (default: white)
    /// - Returns: JPEG data of the generated photo strip
    func generatePhotoStrip(
        from photos: [Data],
        logoData: Data?,
        backgroundColor: UIColor = .white
    ) async throws -> Data {
        guard photos.count >= 3 else {
            throw StripGeneratorError.insufficientPhotos
        }

        // Convert photo data to UIImages
        let photoImages = try photos.prefix(3).map { data -> UIImage in
            guard let image = UIImage(data: data) else {
                throw StripGeneratorError.invalidPhotoData
            }
            return image
        }

        // Load logo if provided
        let logoImage: UIImage? = logoData.flatMap { UIImage(data: $0) }

        // Create the strip
        let stripSize = CGSize(
            width: Self.stripWidth,
            height: Self.stripHeight
        )

        let renderer = UIGraphicsImageRenderer(size: stripSize)
        let stripImage = renderer.image { context in
            // Fill background
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: stripSize))

            let photoWidth = Self.stripWidth - (Self.photoPadding * 2)
            let photoDrawHeight = Self.photoHeight - (Self.photoPadding * 2)

            // Draw each photo
            for (index, photo) in photoImages.enumerated() {
                let yPosition = CGFloat(index) * Self.photoHeight + Self.photoPadding
                let photoRect = CGRect(
                    x: Self.photoPadding,
                    y: yPosition,
                    width: photoWidth,
                    height: photoDrawHeight
                )

                // Draw photo with aspect fill
                drawImageAspectFill(photo, in: photoRect, context: context.cgContext)
            }

            // Draw logo at the bottom
            let logoSection = CGRect(
                x: 0,
                y: Self.photoHeight * 3,
                width: Self.stripWidth,
                height: Self.logoHeight
            )

            if let logo = logoImage {
                // Center the logo in the bottom section
                let logoAspect = logo.size.width / logo.size.height
                let maxLogoHeight = Self.logoHeight - 40 // Padding
                let maxLogoWidth = Self.stripWidth - 40

                var logoDrawSize: CGSize
                if logoAspect > maxLogoWidth / maxLogoHeight {
                    // Width constrained
                    logoDrawSize = CGSize(width: maxLogoWidth, height: maxLogoWidth / logoAspect)
                } else {
                    // Height constrained
                    logoDrawSize = CGSize(width: maxLogoHeight * logoAspect, height: maxLogoHeight)
                }

                let logoRect = CGRect(
                    x: (Self.stripWidth - logoDrawSize.width) / 2,
                    y: logoSection.minY + (Self.logoHeight - logoDrawSize.height) / 2,
                    width: logoDrawSize.width,
                    height: logoDrawSize.height
                )

                logo.draw(in: logoRect)
            } else {
                // Draw placeholder text if no logo
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                    .foregroundColor: UIColor.darkGray,
                    .paragraphStyle: paragraphStyle
                ]

                let text = "FotoX"
                let textSize = text.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: (Self.stripWidth - textSize.width) / 2,
                    y: logoSection.minY + (Self.logoHeight - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )

                text.draw(in: textRect, withAttributes: attributes)
            }
        }

        guard let jpegData = stripImage.jpegData(compressionQuality: 0.9) else {
            throw StripGeneratorError.invalidPhotoData
        }

        return jpegData
    }

    /// Helper to draw image with aspect fill
    private func drawImageAspectFill(_ image: UIImage, in rect: CGRect, context: CGContext) {
        let imageAspect = image.size.width / image.size.height
        let rectAspect = rect.width / rect.height

        var drawRect: CGRect

        if imageAspect > rectAspect {
            // Image is wider - crop left/right
            let scaledHeight = rect.height
            let scaledWidth = scaledHeight * imageAspect
            let xOffset = (scaledWidth - rect.width) / 2
            drawRect = CGRect(
                x: rect.minX - xOffset,
                y: rect.minY,
                width: scaledWidth,
                height: scaledHeight
            )
        } else {
            // Image is taller - crop top/bottom
            let scaledWidth = rect.width
            let scaledHeight = scaledWidth / imageAspect
            let yOffset = (scaledHeight - rect.height) / 2
            drawRect = CGRect(
                x: rect.minX,
                y: rect.minY - yOffset,
                width: scaledWidth,
                height: scaledHeight
            )
        }

        // Clip to the target rect and draw
        context.saveGState()
        context.clip(to: rect)
        image.draw(in: drawRect)
        context.restoreGState()
    }

    // MARK: - Video Strip Generation

    /// Generates a video strip by stitching videos together sequentially
    /// - Parameters:
    ///   - videoURLs: Array of video file URLs (should be 3 videos)
    ///   - outputURL: URL where the output video should be saved
    ///   - logoData: Optional logo image data to overlay at the end
    /// - Returns: URL to the generated video strip
    func generateVideoStrip(
        from videoURLs: [URL],
        to outputURL: URL,
        logoData: Data? = nil
    ) async throws -> URL {
        guard videoURLs.count >= 3 else {
            throw StripGeneratorError.insufficientVideos
        }

        // Use first 3 videos
        let videos = Array(videoURLs.prefix(3))

        // Create composition
        let composition = AVMutableComposition()

        // Create video and audio tracks
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw StripGeneratorError.videoCompositionFailed("Failed to create video track")
        }

        let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        var currentTime = CMTime.zero
        var videoSize = CGSize.zero

        // Add each video to the composition sequentially
        for (index, videoURL) in videos.enumerated() {
            let asset = AVAsset(url: videoURL)

            // Get the asset's video track
            guard let assetVideoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                throw StripGeneratorError.videoCompositionFailed("No video track in asset \(index)")
            }

            let duration = try await asset.load(.duration)
            let naturalSize = try await assetVideoTrack.load(.naturalSize)
            let transform = try await assetVideoTrack.load(.preferredTransform)

            // Calculate the actual size after applying transform
            let transformedSize = naturalSize.applying(transform)
            let actualSize = CGSize(
                width: abs(transformedSize.width),
                height: abs(transformedSize.height)
            )

            // Use the first video's size as reference
            if index == 0 {
                videoSize = actualSize
            }

            let timeRange = CMTimeRange(start: .zero, duration: duration)

            // Insert video track
            try videoTrack.insertTimeRange(
                timeRange,
                of: assetVideoTrack,
                at: currentTime
            )

            // Insert audio track if available
            if let assetAudioTrack = try await asset.loadTracks(withMediaType: .audio).first,
               let audioTrack = audioTrack {
                try? audioTrack.insertTimeRange(
                    timeRange,
                    of: assetAudioTrack,
                    at: currentTime
                )
            }

            currentTime = CMTimeAdd(currentTime, duration)
        }

        // Create video composition for proper orientation
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = videoSize

        // Create instruction for the entire duration
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: currentTime)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

        // Apply identity transform (videos should already be properly oriented)
        layerInstruction.setTransform(.identity, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        // Remove existing file if present
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }

        // Export the composition
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw StripGeneratorError.exportFailed("Failed to create export session")
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition

        await exportSession.export()

        switch exportSession.status {
        case .completed:
            return outputURL
        case .failed:
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown error"
            throw StripGeneratorError.exportFailed(errorMessage)
        case .cancelled:
            throw StripGeneratorError.exportFailed("Export was cancelled")
        default:
            throw StripGeneratorError.exportFailed("Unexpected export status: \(exportSession.status.rawValue)")
        }
    }

    // MARK: - Combined Strip Generation

    /// Generates both photo and video strips from captured media
    /// - Parameters:
    ///   - photos: Array of photo data (should be 3)
    ///   - videoURLs: Array of video URLs (should be 3)
    ///   - outputDirectory: Directory to save the video strip
    ///   - logoData: Optional logo image data
    /// - Returns: Tuple containing photo strip data and video strip URL
    func generateStrips(
        photos: [Data],
        videoURLs: [URL],
        outputDirectory: URL,
        logoData: Data?
    ) async throws -> (photoStripData: Data, videoStripURL: URL) {
        // Generate photo strip
        let photoStripData = try await generatePhotoStrip(
            from: photos,
            logoData: logoData
        )

        // Generate video strip
        let videoStripURL = outputDirectory.appendingPathComponent("video_strip.mov")
        let generatedVideoURL = try await generateVideoStrip(
            from: videoURLs,
            to: videoStripURL,
            logoData: logoData
        )

        return (photoStripData, generatedVideoURL)
    }
}
