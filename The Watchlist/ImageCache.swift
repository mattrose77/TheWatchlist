//
//  ImageCache.swift
//  The Watchlist
//
//  Created by Matt Rose on 03/06/2026.
//

import SwiftUI

actor ImageCache {
    static let shared = ImageCache()
    
    private var cache: [URL: CacheEntry] = [:]
    private let maxCacheSize = 100 // Maximum number of images to keep in memory
    
    private struct CacheEntry {
        let image: UIImage
        let timestamp: Date
    }
    
    private init() {}
    
    func image(for url: URL) -> UIImage? {
        // Clean old entries if cache is too large
        if cache.count > maxCacheSize {
            cleanCache()
        }
        
        return cache[url]?.image
    }
    
    func cache(_ image: UIImage, for url: URL) {
        cache[url] = CacheEntry(image: image, timestamp: Date())
    }
    
    func remove(for url: URL) {
        cache[url] = nil
    }
    
    func clearAll() {
        cache.removeAll()
    }
    
    private func cleanCache() {
        // Remove oldest entries if cache exceeds max size
        let sortedEntries = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(cache.count - maxCacheSize)
        
        for (url, _) in entriesToRemove {
            cache.removeValue(forKey: url)
        }
    }
}

@Observable
class ImageLoader {
    var image: UIImage?
    var isLoading = false
    var hasError = false
    
    private let url: URL
    private var task: Task<Void, Never>?
    private let maxRetries = 3
    
    init(url: URL) {
        self.url = url
    }
    
    func load() {
        guard task == nil else { return }
        
        task = Task {
            isLoading = true
            hasError = false
            
            // Check cache first
            if let cachedImage = await ImageCache.shared.image(for: url) {
                await MainActor.run {
                    self.image = cachedImage
                    self.isLoading = false
                }
                return
            }
            
            // Try loading with retries
            var lastError: Error?
            for attempt in 0..<maxRetries {
                do {
                    if Task.isCancelled { return }
                    
                    // Add a small delay for retries
                    if attempt > 0 {
                        try await Task.sleep(for: .seconds(Double(attempt)))
                    }
                    
                    let (data, response) = try await URLSession.shared.data(from: url)
                    
                    if Task.isCancelled { return }
                    
                    // Verify response is valid
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode),
                          let uiImage = UIImage(data: data) else {
                        lastError = URLError(.badServerResponse)
                        continue
                    }
                    
                    // Cache the image
                    await ImageCache.shared.cache(uiImage, for: url)
                    
                    await MainActor.run {
                        self.image = uiImage
                        self.isLoading = false
                        self.hasError = false
                    }
                    return
                    
                } catch {
                    lastError = error
                    if Task.isCancelled { return }
                }
            }
            
            // All retries failed
            await MainActor.run {
                self.hasError = true
                self.isLoading = false
            }
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
    
    deinit {
        cancel()
    }
}
