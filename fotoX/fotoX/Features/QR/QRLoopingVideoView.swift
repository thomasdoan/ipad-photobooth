//
//  QRLoopingVideoView.swift
//  fotoX
//
//  Auto-playing looping video view for QR screen composite video display
//

import SwiftUI
import AVKit
import UIKit

/// Displays a video that auto-plays on loop with no user controls
struct QRLoopingVideoView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeCoordinator() -> Coordinator {
        Coordinator(player: player)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed - player is managed externally
    }

    class Coordinator {
        private var loopObserver: NSObjectProtocol?

        init(player: AVPlayer) {
            // Set up looping - seek to start and play when video ends
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }

        deinit {
            if let observer = loopObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
