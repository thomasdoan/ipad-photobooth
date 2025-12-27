//
//  ThemeService.swift
//  fotoX
//
//  Service for loading and caching theme assets
//

import Foundation
import SwiftUI

/// Cached theme assets (images)
struct ThemeAssets: Sendable {
    let logo: Image?
    let background: Image?
    let photoFrame: Image?
    let stripFrame: Image?
}

/// Service for loading and caching theme images
actor ThemeService {
    private let session: URLSession
    private var cache: [URL: Data] = [:]

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
    }

    /// Loads all theme assets (logo, background, frames)
    /// Bundled assets take precedence over URL-based assets
    func loadThemeAssets(for theme: AppTheme) async throws -> ThemeAssets {
        async let logo = loadAsset(bundledName: theme.logoAsset, url: theme.logoURL)
        async let background = loadAsset(bundledName: theme.backgroundAsset, url: theme.backgroundURL)
        async let photoFrame = loadAsset(bundledName: theme.photoFrameAsset, url: theme.photoFrameURL)
        async let stripFrame = loadAsset(bundledName: theme.stripFrameAsset, url: theme.stripFrameURL)

        return try await ThemeAssets(
            logo: logo,
            background: background,
            photoFrame: photoFrame,
            stripFrame: stripFrame
        )
    }

    /// Clears the image cache
    func clearCache() {
        cache.removeAll()
    }

    /// Loads an asset, preferring bundled assets over URL-based ones
    private func loadAsset(bundledName: String?, url: URL?) async throws -> Image? {
        // First try to load from bundled assets
        if let bundledName = bundledName, !bundledName.isEmpty {
            if let bundledImage = loadBundledImage(named: bundledName) {
                return bundledImage
            }
        }

        // Fall back to URL loading
        return try await loadImage(from: url)
    }

    /// Loads an image from the app's asset catalog or bundle
    private nonisolated func loadBundledImage(named name: String) -> Image? {
        // Try asset catalog first
        if let uiImage = UIImage(named: name) {
            return Image(uiImage: uiImage)
        }

        // Try bundle resources (for PNG files in the bundle)
        if let path = Bundle.main.path(forResource: name, ofType: "png"),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }

        // Try without extension (in case name already includes it)
        if let path = Bundle.main.path(forResource: name, ofType: nil),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }

        return nil
    }

    /// Loads an image from a URL, using cache if available
    private func loadImage(from url: URL?) async throws -> Image? {
        guard let url = url else { return nil }

        // Check cache first
        if let cachedData = cache[url],
           let uiImage = UIImage(data: cachedData) {
            return Image(uiImage: uiImage)
        }

        // Fetch from network
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        // Cache the data
        cache[url] = data

        guard let uiImage = UIImage(data: data) else {
            return nil
        }

        return Image(uiImage: uiImage)
    }
}

