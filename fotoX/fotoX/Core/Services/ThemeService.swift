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
    let logoData: Data?
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
    func loadThemeAssets(for theme: AppTheme) async throws -> ThemeAssets {
        async let logoResult = loadImageWithData(from: theme.logoURL)
        async let background = loadImage(from: theme.backgroundURL)
        async let photoFrame = loadImage(from: theme.photoFrameURL)
        async let stripFrame = loadImage(from: theme.stripFrameURL)

        let (logo, logoData) = try await logoResult

        return try await ThemeAssets(
            logo: logo,
            logoData: logoData,
            background: background,
            photoFrame: photoFrame,
            stripFrame: stripFrame
        )
    }

    /// Loads the logo data directly from cache or network
    func loadLogoData(from url: URL?) async throws -> Data? {
        guard let url = url else { return nil }

        // Check cache first
        if let cachedData = cache[url] {
            return cachedData
        }

        // Fetch from network
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        // Cache the data
        cache[url] = data

        return data
    }
    
    /// Clears the image cache
    func clearCache() {
        cache.removeAll()
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

    /// Loads an image and its raw data from a URL
    private func loadImageWithData(from url: URL?) async throws -> (Image?, Data?) {
        guard let url = url else { return (nil, nil) }

        // Check cache first
        if let cachedData = cache[url],
           let uiImage = UIImage(data: cachedData) {
            return (Image(uiImage: uiImage), cachedData)
        }

        // Fetch from network
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return (nil, nil)
        }

        // Cache the data
        cache[url] = data

        guard let uiImage = UIImage(data: data) else {
            return (nil, data)
        }

        return (Image(uiImage: uiImage), data)
    }
}

