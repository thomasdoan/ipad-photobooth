//
//  QRLoopingVideoView.swift
//  fotoX
//
//  Auto-playing looping video view for QR screen composite video display.
//  Note: Looping behavior is handled by VideoPlayerManager (single source of truth).
//

import SwiftUI
import AVKit
import UIKit

/// Displays a video that auto-plays on loop with no user controls.
/// Looping is managed by `VideoPlayerManager.replaceItem()` - this view only handles presentation.
@MainActor
struct QRLoopingVideoView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .clear
        return controller
    }
    

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player {
            controller.player = player
        }
    }
}
