//
//  VideoPlayerManagerTests.swift
//  fotoXTests
//
//  Tests for AVPlayer lifecycle management.
//

import AVFoundation
import Foundation
import Testing
@testable import fotoX

@MainActor
struct VideoPlayerManagerTests {
    
    @Test("Starting a new player releases the previous player's item")
    func playReleasesPreviousItem() {
        let manager = VideoPlayerManager()
        let firstURL = URL(fileURLWithPath: "/dev/null")
        let secondURL = URL(fileURLWithPath: "/dev/null")
        
        let firstPlayer = manager.play(id: "first", url: firstURL)
        #expect(firstPlayer.currentItem != nil)
        
        let secondPlayer = manager.play(id: "second", url: secondURL)
        #expect(secondPlayer.currentItem != nil)
        #expect(firstPlayer.currentItem == nil)
    }
    
    @Test("Stopping a player clears its current item")
    func stopClearsCurrentItem() {
        let manager = VideoPlayerManager()
        let url = URL(fileURLWithPath: "/dev/null")
        
        let player = manager.play(id: "single", url: url)
        #expect(player.currentItem != nil)
        
        manager.stop(id: "single")
        #expect(player.currentItem == nil)
    }
}
