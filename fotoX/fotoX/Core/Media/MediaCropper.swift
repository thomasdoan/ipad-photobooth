//
//  MediaCropper.swift
//  fotoX
//
//  Helpers for cropping photos and videos to a target aspect ratio
//

import AVFoundation
import CoreGraphics
import UIKit

enum MediaCropperError: Error {
    case missingVideoTrack
    case exportFailed
}

enum MediaCropper {
    @MainActor
    static func cropPhotoData(_ data: Data, to aspectRatio: CGFloat) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let normalized = image.normalizedOrientation()
        guard let cgImage = normalized.cgImage else { return nil }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let currentRatio = width / height
        if abs(currentRatio - aspectRatio) < 0.01 {
            return data
        }

        let cropRect: CGRect
        if currentRatio > aspectRatio {
            let targetWidth = height * aspectRatio
            let x = (width - targetWidth) / 2
            cropRect = CGRect(x: x, y: 0, width: targetWidth, height: height)
        } else {
            let targetHeight = width / aspectRatio
            let y = (height - targetHeight) / 2
            cropRect = CGRect(x: 0, y: y, width: width, height: targetHeight)
        }

        guard let cropped = cgImage.cropping(to: cropRect.integral) else { return nil }
        let croppedImage = UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
        return croppedImage.jpegData(compressionQuality: 0.9)
    }

    static func cropVideoIfNeeded(at url: URL, to aspectRatio: CGFloat) async throws -> URL {
        let asset = AVAsset(url: url)
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            throw MediaCropperError.missingVideoTrack
        }

        let orientedSize = orientedVideoSize(for: videoTrack)
        let currentRatio = orientedSize.width / orientedSize.height
        if abs(currentRatio - aspectRatio) < 0.01 {
            return url
        }

        let targetSize = cropSize(from: orientedSize, aspectRatio: aspectRatio)

        let composition = AVMutableComposition()
        guard let compVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw MediaCropperError.exportFailed
        }

        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        try compVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)

        if let audioTrack = asset.tracks(withMediaType: .audio).first,
           let compAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try compAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = targetSize
        let fps = max(Int32(videoTrack.nominalFrameRate), 30)
        videoComposition.frameDuration = CMTime(value: 1, timescale: fps)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compVideoTrack)
        layerInstruction.setTransform(
            cropTransform(for: videoTrack, targetSize: targetSize),
            at: .zero
        )
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("strip_crop_\(UUID().uuidString).mov")

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw MediaCropperError.exportFailed
        }

        exportSession.outputFileType = .mov
        exportSession.outputURL = outputURL
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true

        await exportSession.export()

        if exportSession.status == .completed {
            return outputURL
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        throw exportSession.error ?? MediaCropperError.exportFailed
    }

    private static func orientedVideoSize(for track: AVAssetTrack) -> CGSize {
        let rawRect = CGRect(origin: .zero, size: track.naturalSize).applying(track.preferredTransform)
        return CGSize(width: abs(rawRect.width), height: abs(rawRect.height))
    }

    private static func cropSize(from size: CGSize, aspectRatio: CGFloat) -> CGSize {
        let currentRatio = size.width / size.height
        let targetWidth: CGFloat
        let targetHeight: CGFloat

        if currentRatio > aspectRatio {
            targetHeight = size.height
            targetWidth = size.height * aspectRatio
        } else {
            targetWidth = size.width
            targetHeight = size.width / aspectRatio
        }

        return CGSize(
            width: evenDimension(targetWidth),
            height: evenDimension(targetHeight)
        )
    }

    private static func cropTransform(for track: AVAssetTrack, targetSize: CGSize) -> CGAffineTransform {
        let preferred = track.preferredTransform
        let rawRect = CGRect(origin: .zero, size: track.naturalSize).applying(preferred)
        let normalizedOrigin = CGPoint(x: -rawRect.origin.x, y: -rawRect.origin.y)
        let orientedSize = CGSize(width: abs(rawRect.width), height: abs(rawRect.height))

        let scale = max(targetSize.width / orientedSize.width, targetSize.height / orientedSize.height)
        let scaledSize = CGSize(width: orientedSize.width * scale, height: orientedSize.height * scale)
        let x = (targetSize.width - scaledSize.width) / 2
        let y = (targetSize.height - scaledSize.height) / 2

        var transform = preferred
        transform = transform.concatenating(CGAffineTransform(translationX: normalizedOrigin.x, y: normalizedOrigin.y))
        transform = transform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
        transform = transform.concatenating(CGAffineTransform(translationX: x, y: y))
        return transform
    }

    private static func evenDimension(_ value: CGFloat) -> CGFloat {
        floor(value / 2) * 2
    }
}

private extension UIImage {
    @MainActor
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
