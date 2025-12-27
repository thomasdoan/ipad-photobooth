//
//  CameraPreview.swift
//  fotoX
//
//  SwiftUI wrapper for camera preview layer
//

import SwiftUI
import AVFoundation

/// SwiftUI view that displays the camera preview
struct CameraPreview: UIViewRepresentable {
    let cameraController: CameraController
    let isReady: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = CameraPreviewUIView()
        
        if let previewLayer = cameraController.previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraController.previewLayer {
            // Add layer if it's not already added
            if previewLayer.superlayer == nil {
                uiView.layer.addSublayer(previewLayer)
            }
            
            // Update frame
            previewLayer.frame = uiView.bounds
        }
    }
}

/// Custom UIView that properly sizes the preview layer
class CameraPreviewUIView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update all sublayers to match view bounds (should just be the preview layer)
        layer.sublayers?.forEach { sublayer in
            sublayer.frame = bounds
        }
    }
}

/// Preview container with aspect ratio handling for 9:16 vertical video
struct CameraPreviewContainer: View {
    let cameraController: CameraController
    let aspectRatio: CGFloat
    
    init(cameraController: CameraController, aspectRatio: CGFloat = 9.0 / 16.0) {
        self.cameraController = cameraController
        self.aspectRatio = aspectRatio
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = calculateSize(in: geometry.size)
            
            CameraPreview(cameraController: cameraController, isReady: cameraController.previewLayer != nil)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
    
    private func calculateSize(in containerSize: CGSize) -> CGSize {
        let containerAspect = containerSize.width / containerSize.height
        
        if aspectRatio > containerAspect {
            // Fit to width
            let width = containerSize.width
            let height = width / aspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Fit to height
            let height = containerSize.height
            let width = height * aspectRatio
            return CGSize(width: width, height: height)
        }
    }
}

