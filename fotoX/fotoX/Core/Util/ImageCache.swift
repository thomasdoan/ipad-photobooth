//
//  ImageCache.swift
//  fotoX
//
//  Simple image cache for theme assets
//

import SwiftUI

/// Actor-based image cache for thread-safe caching
actor ImageCache {
    static let shared = ImageCache()
    
    private var cache: [URL: UIImage] = [:]
    private var pendingTasks: [URL: Task<UIImage?, Never>] = [:]
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
    }
    
    /// Gets an image from cache or fetches it from the network
    func image(for url: URL) async -> UIImage? {
        // Return cached image if available
        if let cached = cache[url] {
            return cached
        }
        
        // If there's a pending task for this URL, wait for it
        if let pendingTask = pendingTasks[url] {
            return await pendingTask.value
        }
        
        // Create a new fetch task
        let task = Task<UIImage?, Never> {
            do {
                let (data, response) = try await session.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let image = UIImage(data: data) else {
                    return nil
                }
                
                return image
            } catch {
                return nil
            }
        }
        
        pendingTasks[url] = task
        let image = await task.value
        pendingTasks[url] = nil
        
        if let image = image {
            cache[url] = image
        }
        
        return image
    }
    
    /// Preloads images for the given URLs
    func preload(urls: [URL?]) async {
        let validURLs = urls.compactMap { $0 }
        await withTaskGroup(of: Void.self) { group in
            for url in validURLs {
                group.addTask {
                    _ = await self.image(for: url)
                }
            }
        }
    }
    
    /// Clears all cached images
    func clear() {
        cache.removeAll()
        pendingTasks.values.forEach { $0.cancel() }
        pendingTasks.removeAll()
    }
    
    /// Removes a specific image from the cache
    func remove(for url: URL) {
        cache[url] = nil
    }
}

/// SwiftUI view for async image loading with caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                content(Image(uiImage: loadedImage))
            } else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        guard let url = url, !isLoading else { return }
        isLoading = true
        loadedImage = await ImageCache.shared.image(for: url)
        isLoading = false
    }
}

