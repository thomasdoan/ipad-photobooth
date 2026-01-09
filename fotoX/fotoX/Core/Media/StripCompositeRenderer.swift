//
//  StripCompositeRenderer.swift
//  fotoX
//
//  Renders composite photo/video strips for upload
//

import SwiftUI
import AVFoundation

enum StripCompositeRenderError: Error {
    case missingVideoTrack
    case imageRenderFailed
    case exportFailed
}

struct StripCompositeRenderLayout: Sendable {
    let slotCount: Int
    let totalSize: CGSize
    let slotSize: CGSize
    let slotSpacing: CGFloat
    let footerHeight: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let slotCornerRadius: CGFloat
    let outerCornerRadius: CGFloat

    init(outputWidth: CGFloat, slotCount: Int) {
        let slots = max(slotCount, 1)
        let slotWidth = outputWidth / (1 + 2 * StripCompositeMetrics.horizontalPaddingRatio)
        let slotHeight = slotWidth / StripCompositeMetrics.slotAspectRatio
        let spacing = slotWidth * StripCompositeMetrics.spacingRatio
        let footerHeight = slotWidth * StripCompositeMetrics.footerHeightRatio
        let horizontalPadding = slotWidth * StripCompositeMetrics.horizontalPaddingRatio
        let verticalPadding = slotWidth * StripCompositeMetrics.verticalPaddingRatio
        let totalHeight = slotHeight * CGFloat(slots)
            + spacing * CGFloat(slots - 1)
            + footerHeight
            + verticalPadding * 2
        let roundedHeight = totalHeight.rounded(.toNearestOrAwayFromZero)

        self.slotCount = slots
        self.totalSize = CGSize(width: outputWidth, height: roundedHeight)
        self.slotSize = CGSize(width: slotWidth, height: slotHeight)
        self.slotSpacing = spacing
        self.footerHeight = footerHeight
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.slotCornerRadius = slotWidth * 0.08
        self.outerCornerRadius = slotWidth * 0.12
    }

    func slotFrame(at index: Int) -> CGRect {
        let x = horizontalPadding
        let y = verticalPadding + CGFloat(index) * (slotSize.height + slotSpacing)
        return CGRect(x: x, y: y, width: slotSize.width, height: slotSize.height)
    }
}

@MainActor
enum StripCompositeRenderer {
    // TODO: Make composite render size configurable once target resolution is finalized.
    static let defaultOutputWidth: CGFloat = 720

    static func renderCompositeAssets(
        strips: [CapturedStrip],
        theme: AppTheme,
        assets: ThemeAssets?,
        footerText: String,
        outputWidth: CGFloat = defaultOutputWidth
    ) async throws -> CompositeStripAssets {
        let sortedStrips = strips.sorted { $0.stripIndex < $1.stripIndex }
        let activeStrips = Array(sortedStrips.prefix(3))
        guard !activeStrips.isEmpty else {
            throw StripCompositeRenderError.exportFailed
        }

        let layout = StripCompositeRenderLayout(outputWidth: outputWidth, slotCount: activeStrips.count)

        let photoData = try renderCompositePhoto(
            strips: activeStrips,
            layout: layout,
            theme: theme,
            assets: assets,
            footerText: footerText
        )

        let (backgroundData, overlayData) = try renderCompositeLayers(
            layout: layout,
            theme: theme,
            assets: assets,
            footerText: footerText
        )

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("strip_video_\(UUID().uuidString).mp4")

        let videoURL = try await exportCompositeVideo(
            strips: activeStrips,
            layout: layout,
            backgroundData: backgroundData,
            overlayData: overlayData,
            outputURL: outputURL
        )

        return CompositeStripAssets(photoData: photoData, videoURL: videoURL)
    }

    private static func renderCompositePhoto(
        strips: [CapturedStrip],
        layout: StripCompositeRenderLayout,
        theme: AppTheme,
        assets: ThemeAssets?,
        footerText: String
    ) throws -> Data {
        let images = strips.map { UIImage(data: $0.photoData) }
        let view = StripCompositePhotoRenderView(
            images: images,
            layout: layout,
            footerText: footerText
        )
        .withTheme(theme, assets: assets)

        guard let image = renderImage(view: view, size: layout.totalSize),
              let data = image.jpegData(compressionQuality: 0.9) else {
            throw StripCompositeRenderError.imageRenderFailed
        }

        return data
    }

    private static func renderCompositeLayers(
        layout: StripCompositeRenderLayout,
        theme: AppTheme,
        assets: ThemeAssets?,
        footerText: String
    ) throws -> (background: Data, overlay: Data) {
        let backgroundView = StripCompositeBackgroundRenderView(
            layout: layout,
            footerText: footerText
        )
        .withTheme(theme, assets: assets)

        let overlayView = StripCompositeFrameOverlayView(layout: layout)
            .withTheme(theme, assets: assets)

        guard let backgroundImage = renderImage(view: backgroundView, size: layout.totalSize),
              let overlayImage = renderImage(view: overlayView, size: layout.totalSize),
              let backgroundData = backgroundImage.pngData(),
              let overlayData = overlayImage.pngData() else {
            throw StripCompositeRenderError.imageRenderFailed
        }

        return (backgroundData, overlayData)
    }

    private static func renderImage<Content: View>(view: Content, size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 1
        return renderer.uiImage
    }

    private static func exportCompositeVideo(
        strips: [CapturedStrip],
        layout: StripCompositeRenderLayout,
        backgroundData: Data,
        overlayData: Data,
        outputURL: URL
    ) async throws -> URL {
        let composition = AVMutableComposition()
        let targetDuration = try buildComposition(
            strips: strips,
            layout: layout,
            composition: composition
        )

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = layout.totalSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [
            makeVideoInstruction(
                composition: composition,
                layout: layout,
                duration: targetDuration
            )
        ]
        videoComposition.animationTool = makeAnimationTool(
            layout: layout,
            backgroundData: backgroundData,
            overlayData: overlayData
        )

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw StripCompositeRenderError.exportFailed
        }

        exportSession.outputFileType = .mp4
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

        throw exportSession.error ?? StripCompositeRenderError.exportFailed
    }

    private static func buildComposition(
        strips: [CapturedStrip],
        layout: StripCompositeRenderLayout,
        composition: AVMutableComposition
    ) throws -> CMTime {
        var maxDuration = CMTime.zero
        var trackBindings: [(track: AVMutableCompositionTrack, source: AVAssetTrack, duration: CMTime)] = []

        for strip in strips.prefix(layout.slotCount) {
            let asset = AVAsset(url: strip.videoURL)
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                throw StripCompositeRenderError.missingVideoTrack
            }

            let compTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            if let compTrack {
                try compTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
                trackBindings.append((track: compTrack, source: videoTrack, duration: asset.duration))
            }

            maxDuration = maxTime(maxDuration, asset.duration)
        }

        if maxDuration == .zero {
            throw StripCompositeRenderError.exportFailed
        }

        // Extend shorter tracks by freezing their last frame.
        for binding in trackBindings {
            let duration = binding.duration
            guard CMTimeCompare(duration, maxDuration) < 0 else { continue }

            let fps = max(Int32(binding.source.nominalFrameRate), 30)
            let freezeDuration = minTime(CMTime(value: 1, timescale: fps), duration)
            let freezeStart = CMTimeSubtract(duration, freezeDuration)
            let freezeRange = CMTimeRange(start: freezeStart, duration: freezeDuration)
            try binding.track.insertTimeRange(freezeRange, of: binding.source, at: duration)

            let insertedRange = CMTimeRange(start: duration, duration: freezeDuration)
            let remaining = CMTimeSubtract(maxDuration, duration)
            binding.track.scaleTimeRange(insertedRange, toDuration: remaining)
        }

        return maxDuration
    }

    private static func makeVideoInstruction(
        composition: AVMutableComposition,
        layout: StripCompositeRenderLayout,
        duration: CMTime
    ) -> AVVideoCompositionInstruction {
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)

        var layerInstructions: [AVVideoCompositionLayerInstruction] = []
        let tracks = composition.tracks(withMediaType: .video)

        for (index, track) in tracks.enumerated() {
            guard index < layout.slotCount else { continue }
            let targetFrame = layout.slotFrame(at: index)
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            let transform = videoTransform(for: track, in: targetFrame)
            layerInstruction.setTransform(transform, at: .zero)
            layerInstructions.append(layerInstruction)
        }

        instruction.layerInstructions = layerInstructions
        return instruction
    }

    private static func videoTransform(for track: AVAssetTrack, in frame: CGRect) -> CGAffineTransform {
        let preferred = track.preferredTransform
        let rawRect = CGRect(origin: .zero, size: track.naturalSize).applying(preferred)
        let normalizedOrigin = CGPoint(x: -rawRect.origin.x, y: -rawRect.origin.y)
        let orientedSize = CGSize(width: abs(rawRect.width), height: abs(rawRect.height))

        let scale = max(frame.width / orientedSize.width, frame.height / orientedSize.height)
        let scaledSize = CGSize(width: orientedSize.width * scale, height: orientedSize.height * scale)
        let x = frame.origin.x + (frame.width - scaledSize.width) / 2
        let y = frame.origin.y + (frame.height - scaledSize.height) / 2

        var transform = preferred
        transform = transform.concatenating(CGAffineTransform(translationX: normalizedOrigin.x, y: normalizedOrigin.y))
        transform = transform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
        transform = transform.concatenating(CGAffineTransform(translationX: x, y: y))
        return transform
    }

    private static func makeAnimationTool(
        layout: StripCompositeRenderLayout,
        backgroundData: Data,
        overlayData: Data
    ) -> AVVideoCompositionCoreAnimationTool {
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: layout.totalSize)

        let parentLayer = CALayer()
        parentLayer.frame = videoLayer.frame

        if let backgroundImage = UIImage(data: backgroundData)?.cgImage {
            let backgroundLayer = CALayer()
            backgroundLayer.contents = backgroundImage
            backgroundLayer.frame = videoLayer.frame
            backgroundLayer.contentsGravity = .resize
            backgroundLayer.contentsScale = 1
            parentLayer.addSublayer(backgroundLayer)
        }

        parentLayer.addSublayer(videoLayer)

        if let overlayImage = UIImage(data: overlayData)?.cgImage {
            let overlayLayer = CALayer()
            overlayLayer.contents = overlayImage
            overlayLayer.frame = videoLayer.frame
            overlayLayer.contentsGravity = .resize
            overlayLayer.contentsScale = 1
            parentLayer.addSublayer(overlayLayer)
        }

        return AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
    }

    private static func maxTime(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
        CMTimeCompare(lhs, rhs) >= 0 ? lhs : rhs
    }

    private static func minTime(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
        CMTimeCompare(lhs, rhs) <= 0 ? lhs : rhs
    }
}

private struct StripCompositePhotoRenderView: View {
    let images: [UIImage?]
    let layout: StripCompositeRenderLayout
    let footerText: String

    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            StripCompositeContentView(
                layout: layout,
                footerText: footerText,
                slotContent: { index in
                    if index < images.count, let image = images[index] {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.black.opacity(0.2)
                    }
                }
            )

            StripCompositeFrameOverlayView(layout: layout)
        }
        .background(theme.secondary.opacity(0.9))
        .frame(width: layout.totalSize.width, height: layout.totalSize.height)
    }
}

private struct StripCompositeBackgroundRenderView: View {
    let layout: StripCompositeRenderLayout
    let footerText: String

    @Environment(\.appTheme) private var theme

    var body: some View {
        StripCompositeContentView(
            layout: layout,
            footerText: footerText,
            slotContent: { _ in
                Color.black.opacity(0.05)
            }
        )
        .background(theme.secondary.opacity(0.9))
        .frame(width: layout.totalSize.width, height: layout.totalSize.height)
    }
}

private struct StripCompositeContentView<SlotContent: View>: View {
    let layout: StripCompositeRenderLayout
    let footerText: String
    let slotContent: (Int) -> SlotContent

    @Environment(\.appTheme) private var theme

    init(
        layout: StripCompositeRenderLayout,
        footerText: String,
        @ViewBuilder slotContent: @escaping (Int) -> SlotContent
    ) {
        self.layout = layout
        self.footerText = footerText
        self.slotContent = slotContent
    }

    var body: some View {
        VStack(spacing: layout.slotSpacing) {
            ForEach(0..<layout.slotCount, id: \.self) { index in
                slotContent(index)
                    .frame(width: layout.slotSize.width, height: layout.slotSize.height)
                    .clipped()
                    .background(theme.secondary.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: layout.slotCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: layout.slotCornerRadius, style: .continuous)
                            .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                    )
            }

            StripCompositeFooterView(text: footerText, height: layout.footerHeight)
        }
        .padding(.horizontal, layout.horizontalPadding)
        .padding(.vertical, layout.verticalPadding)
        .frame(width: layout.totalSize.width, height: layout.totalSize.height)
        .background(theme.secondary.opacity(0.9))
    }
}

private struct StripCompositeFooterView: View {
    let text: String
    let height: CGFloat

    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
                .fill(theme.secondary.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: height * 0.25, style: .continuous)
                        .stroke(theme.primary.opacity(0.4), lineWidth: 1)
                )

            Text(text)
                .font(footerFont(size: height * 0.3))
                .foregroundStyle(theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, height * 0.3)
        }
        .frame(height: height)
    }

    private func footerFont(size: CGFloat) -> Font {
        if theme.fontFamily == "system" {
            return .system(size: size, weight: .semibold, design: .rounded)
        }
        return .custom(theme.fontFamily, size: size)
    }
}

private struct StripCompositeFrameOverlayView: View {
    let layout: StripCompositeRenderLayout

    @Environment(\.appTheme) private var theme
    @Environment(\.themeAssets) private var assets

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.outerCornerRadius, style: .continuous)

        ZStack {
            if let frame = assets?.stripFrame {
                frame
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(shape)
            } else {
                defaultFrame(shape: shape)
            }
        }
        .frame(width: layout.totalSize.width, height: layout.totalSize.height)
    }

    @ViewBuilder
    private func defaultFrame(shape: RoundedRectangle) -> some View {
        ZStack {
            shape.strokeBorder(
                LinearGradient(
                    colors: [
                        theme.primary.opacity(0.9),
                        theme.accent.opacity(0.8),
                        theme.primary.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )

            shape
                .inset(by: 2)
                .strokeBorder(theme.accent.opacity(0.35), lineWidth: 1)

            shape
                .inset(by: 4)
                .strokeBorder(theme.secondary.opacity(0.6), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}
