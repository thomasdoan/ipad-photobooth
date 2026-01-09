//
//  StripVideoCompositor.swift
//  fotoX
//

import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Metal

final class StripVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    let timeRange: CMTimeRange
    let renderSize: CGSize
    let trackIDs: [CMPersistentTrackID]
    let trackTransforms: [CMPersistentTrackID: CGAffineTransform]
    let slotFrames: [CMPersistentTrackID: CGRect]
    let slotMasks: [CMPersistentTrackID: CIImage]
    let backgroundImage: CIImage
    let overlayImage: CIImage

    var enablePostProcessing: Bool = false
    var containsTweening: Bool = false
    var requiredSourceTrackIDs: [NSValue]?
    var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid

    init(
        timeRange: CMTimeRange,
        renderSize: CGSize,
        trackIDs: [CMPersistentTrackID],
        trackTransforms: [CMPersistentTrackID: CGAffineTransform],
        slotFrames: [CMPersistentTrackID: CGRect],
        slotCornerRadius: CGFloat,
        backgroundImage: CIImage,
        overlayImage: CIImage,
        requiredSourceTrackIDs: [NSValue]
    ) {
        self.timeRange = timeRange
        self.renderSize = renderSize
        self.trackIDs = trackIDs
        self.trackTransforms = trackTransforms
        self.slotFrames = slotFrames
        self.slotMasks = Self.makeSlotMasks(frames: slotFrames, cornerRadius: slotCornerRadius)
        self.backgroundImage = backgroundImage
        self.overlayImage = overlayImage
        self.requiredSourceTrackIDs = requiredSourceTrackIDs
    }

    private static func makeSlotMasks(
        frames: [CMPersistentTrackID: CGRect],
        cornerRadius: CGFloat
    ) -> [CMPersistentTrackID: CIImage] {
        var masks: [CMPersistentTrackID: CIImage] = [:]
        for (trackID, frame) in frames {
            let filter = CIFilter.roundedRectangleGenerator()
            filter.extent = frame
            filter.radius = Float(cornerRadius)
            filter.color = CIColor(red: 1, green: 1, blue: 1, alpha: 1)
            if let mask = filter.outputImage {
                masks[trackID] = mask
            } else {
                let fallback = CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: 1))
                    .cropped(to: frame)
                masks[trackID] = fallback
            }
        }
        return masks
    }
}

enum StripVideoCompositorError: Error {
    case invalidInstruction
    case outputBufferUnavailable
    case renderFailed
}

final class StripVideoCompositor: NSObject, AVVideoCompositing {
    private let renderQueue = DispatchQueue(label: "StripVideoCompositor.renderQueue")
    private var shouldCancelRequests = false
    private let ciContext: CIContext
    private let colorSpace = CGColorSpaceCreateDeviceRGB()

    override init() {
        if let device = MTLCreateSystemDefaultDevice() {
            ciContext = CIContext(mtlDevice: device)
        } else {
            ciContext = CIContext()
        }
        super.init()
    }

    var sourcePixelBufferAttributes: [String: Any]? {
        [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
    }

    var requiredPixelBufferAttributesForRenderContext: [String: Any] {
        [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
    }

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        // No cached render state needed; per-request context is used.
    }

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        renderQueue.async { [weak self] in
            self?.handle(request)
        }
    }

    func cancelAllPendingVideoCompositionRequests() {
        renderQueue.sync {
            shouldCancelRequests = true
        }
        renderQueue.async { [weak self] in
            self?.shouldCancelRequests = false
        }
    }

    private func handle(_ request: AVAsynchronousVideoCompositionRequest) {
        if shouldCancelRequests {
            request.finishCancelledRequest()
            return
        }

        guard let instruction = request.videoCompositionInstruction as? StripVideoCompositionInstruction else {
            request.finish(with: StripVideoCompositorError.invalidInstruction)
            return
        }

        guard let outputBuffer = request.renderContext.newPixelBuffer() else {
            request.finish(with: StripVideoCompositorError.outputBufferUnavailable)
            return
        }

        guard let outputImage = compositeImage(for: request, instruction: instruction) else {
            request.finish(with: StripVideoCompositorError.renderFailed)
            return
        }

        ciContext.render(
            outputImage,
            to: outputBuffer,
            bounds: CGRect(origin: .zero, size: instruction.renderSize),
            colorSpace: colorSpace
        )
        request.finish(withComposedVideoFrame: outputBuffer)
    }

    private func compositeImage(
        for request: AVAsynchronousVideoCompositionRequest,
        instruction: StripVideoCompositionInstruction
    ) -> CIImage? {
        var composited = instruction.backgroundImage

        for trackID in instruction.trackIDs {
            guard let sourceBuffer = request.sourceFrame(byTrackID: trackID) else { continue }
            guard let transform = instruction.trackTransforms[trackID],
                  let slotFrame = instruction.slotFrames[trackID] else { continue }

            let sourceImage = CIImage(cvPixelBuffer: sourceBuffer)
            let transformed = sourceImage.transformed(by: transform)
            let cropped = transformed.cropped(to: slotFrame)
            let masked = applyMask(to: cropped, mask: instruction.slotMasks[trackID], slotFrame: slotFrame)
            composited = masked.composited(over: composited)
        }

        composited = instruction.overlayImage.composited(over: composited)
        return composited.cropped(to: CGRect(origin: .zero, size: instruction.renderSize))
    }

    private func applyMask(to image: CIImage, mask: CIImage?, slotFrame: CGRect) -> CIImage {
        guard let mask else { return image }
        let clear = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: slotFrame)
        return image.applyingFilter(
            "CIBlendWithAlphaMask",
            parameters: [
                kCIInputBackgroundImageKey: clear,
                kCIInputMaskImageKey: mask
            ]
        )
    }
}
