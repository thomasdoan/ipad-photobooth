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
    let cameraController: any CameraControlling
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
    let cameraController: any CameraControlling
    let aspectRatio: CGFloat

    init(cameraController: any CameraControlling, aspectRatio: CGFloat = 9.0 / 16.0) {
        self.cameraController = cameraController
        self.aspectRatio = aspectRatio
    }

    var body: some View {
        GeometryReader { geometry in
            let size = calculateSize(in: geometry.size)

            Group {
                if cameraController.isSimulator {
                    SimulatorPreviewView()
                } else {
                    CameraPreview(cameraController: cameraController, isReady: cameraController.previewLayer != nil)
                }
            }
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

/// Animated preview view for simulator mode
struct SimulatorPreviewView: View {
    @State private var gradientStart = UnitPoint.topLeading
    @State private var gradientEnd = UnitPoint.bottomTrailing

    private let colors: [Color] = [
        .blue.opacity(0.8),
        .purple.opacity(0.8),
        .pink.opacity(0.8)
    ]

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: colors,
                startPoint: gradientStart,
                endPoint: gradientEnd
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    gradientStart = .bottomTrailing
                    gradientEnd = .topLeading
                }
            }

            // Grid overlay to simulate camera view
            GridPattern()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)

            // Simulator badge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("SIMULATOR")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                    Spacer()
                }
                .padding(.bottom, 40)
            }

            // Center viewfinder
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 120, height: 120)

            // Crosshair
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: 30)
                Spacer().frame(height: 60)
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: 30)
            }
            .frame(height: 120)

            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 30, height: 2)
                Spacer().frame(width: 60)
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 30, height: 2)
            }
            .frame(width: 120)
        }
    }
}

/// Grid pattern shape for camera viewfinder effect
struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 60

        // Vertical lines
        var x: CGFloat = spacing
        while x < rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += spacing
        }

        // Horizontal lines
        var y: CGFloat = spacing
        while y < rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += spacing
        }

        return path
    }
}

