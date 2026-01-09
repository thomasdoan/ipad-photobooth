//
//  VideoPlayerManager.swift
//  fotoX
//
//  Manages AVPlayer lifecycle to avoid eager allocation and leaks.
//

import AVFoundation

@MainActor
final class VideoPlayerManager {
    private struct ManagedPlayer {
        let player: AVPlayer
        var currentURL: URL?
        var endObserver: NSObjectProtocol?
    }

    private var players: [String: ManagedPlayer] = [:]
    private var activeID: String?

    func play(id: String, url: URL, fromStart: Bool = false) -> AVPlayer {
        let player = prepare(id: id, url: url)
        setActive(id: id)
        if fromStart {
            player.seek(to: .zero)
        }
        player.play()
        return player
    }

    func pause(id: String) {
        players[id]?.player.pause()
    }

    func stop(id: String) {
        guard var managed = players[id] else { return }
        tearDown(&managed)
        players[id] = nil
        if activeID == id {
            activeID = nil
        }
    }

    func stopAll() {
        let keys = Array(players.keys)
        for key in keys {
            stop(id: key)
        }
        activeID = nil
    }

    private func prepare(id: String, url: URL) -> AVPlayer {
        var managed = players[id] ?? ManagedPlayer(player: AVPlayer(), currentURL: nil, endObserver: nil)
        if managed.currentURL != url || managed.player.currentItem == nil {
            replaceItem(for: &managed, url: url)
        }
        players[id] = managed
        return managed.player
    }

    private func setActive(id: String) {
        guard activeID != id else { return }
        let keys = Array(players.keys)
        for key in keys where key != id {
            stop(id: key)
        }
        activeID = id
    }

    private func replaceItem(for managed: inout ManagedPlayer, url: URL) {
        tearDown(&managed)
        let item = AVPlayerItem(url: url)
        managed.player.replaceCurrentItem(with: item)
        managed.player.actionAtItemEnd = .pause
        managed.currentURL = url
        managed.endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak player = managed.player] _ in
            player?.seek(to: .zero)
        }
    }

    private func tearDown(_ managed: inout ManagedPlayer) {
        managed.player.pause()
        managed.player.currentItem?.cancelPendingSeeks()
        managed.player.currentItem?.asset.cancelLoading()
        managed.player.replaceCurrentItem(with: nil)
        if let observer = managed.endObserver {
            NotificationCenter.default.removeObserver(observer)
            managed.endObserver = nil
        }
        managed.currentURL = nil
    }
}
