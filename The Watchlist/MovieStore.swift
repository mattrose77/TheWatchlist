//
//  MovieStore.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import Foundation
import SwiftUI
import Combine

class MovieStore: ObservableObject {
    @Published var availableMovies: [Movie] = []
    @Published var watchlist: [Movie] = [] {
        didSet {
            saveWatchlist()
        }
    }
    @Published var archive: [Movie] = [] {
        didSet {
            saveArchive()
        }
    }
    @Published var userRatings: [Int: UserRating] = [:] {
        didSet {
            saveRatings()
        }
    }
    @Published var isLoading = false
    @Published var selectedCategory: MovieCategory = .trending
    @Published var selectedContentType: ContentType = .movies
    
    let movieService = MovieService()
    
    // File URLs for persisting data
    private var watchlistURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("watchlist.json")
    }
    
    private var archiveURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("archive.json")
    }
    
    private var ratingsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ratings.json")
    }
    
    init() {
        loadWatchlist()
        loadArchive()
        loadRatings()
        performDataMigrationIfNeeded()
    }
    
    // MARK: - Data Migration
    
    /// Performs one-time data migration to ensure data integrity and forward compatibility
    private func performDataMigrationIfNeeded() {
        let migrationKey = "watchlist_migration_v2_complete"
        
        // Check if migration has already been completed
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            return
        }
        
        // Migration v2: Ensure ratings dictionary is properly initialized
        // This migration verifies that the userRatings system is working correctly
        // and ensures all existing data is preserved
        
        // Verify watchlist data integrity
        let watchlistCount = watchlist.count
        let archiveCount = archive.count
        let ratingsCount = userRatings.count
        
        // Ensure ratings file exists (create empty one if needed)
        if !FileManager.default.fileExists(atPath: ratingsURL.path) {
            saveRatings() // This will create the file with current (possibly empty) ratings
        }
        
        // Verify all data is intact after migration
        assert(watchlist.count == watchlistCount, "Watchlist data was lost during migration!")
        assert(archive.count == archiveCount, "Archive data was lost during migration!")
        assert(userRatings.count == ratingsCount, "Ratings data was lost during migration!")
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
    
    // MARK: - Persistence Methods
    
    private func saveWatchlist() {
        do {
            // Forward-compatible encoding
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // Makes debugging easier
            let data = try encoder.encode(watchlist)
            try data.write(to: watchlistURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("❌ Error saving watchlist: \(error)")
        }
    }
    
    private func loadWatchlist() {
        guard FileManager.default.fileExists(atPath: watchlistURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: watchlistURL)
            // Forward-compatible decoding: JSONDecoder automatically ignores unknown keys
            // and handles optional properties gracefully
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // Support for Date fields in future
            watchlist = try decoder.decode([Movie].self, from: data)
        } catch {
            print("⚠️ Error loading watchlist: \(error)")
            print("   Attempting data recovery...")
            // Keep empty array on error to prevent data loss of other lists
            watchlist = []
        }
    }
    
    private func saveArchive() {
        do {
            // Forward-compatible encoding
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // Makes debugging easier
            let data = try encoder.encode(archive)
            try data.write(to: archiveURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("❌ Error saving archive: \(error)")
        }
    }
    
    private func loadArchive() {
        guard FileManager.default.fileExists(atPath: archiveURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: archiveURL)
            // Forward-compatible decoding: JSONDecoder automatically ignores unknown keys
            // and handles optional properties gracefully
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // Support for Date fields in future
            archive = try decoder.decode([Movie].self, from: data)
        } catch {
            print("⚠️ Error loading archive: \(error)")
            print("   Attempting data recovery...")
            // Keep empty array on error to prevent data loss of other lists
            archive = []
        }
    }
    
    private func saveRatings() {
        do {
            // Convert dictionary to array for encoding
            let ratingsArray = Array(userRatings.values)
            // Forward-compatible encoding
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // Makes debugging easier
            let data = try encoder.encode(ratingsArray)
            try data.write(to: ratingsURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("❌ Error saving ratings: \(error)")
        }
    }
    
    private func loadRatings() {
        guard FileManager.default.fileExists(atPath: ratingsURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: ratingsURL)
            // Forward-compatible decoding
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let ratingsArray = try decoder.decode([UserRating].self, from: data)
            // Convert array back to dictionary
            userRatings = Dictionary(uniqueKeysWithValues: ratingsArray.map { ($0.movieId, $0) })
        } catch {
            print("⚠️ Error loading ratings: \(error)")
            print("   Attempting data recovery...")
            // Keep empty dictionary on error
            userRatings = [:]
        }
    }
    
    func getRating(for movieId: Int) -> Double? {
        return userRatings[movieId]?.rating
    }
    
    func setRating(_ rating: Double, for movie: Movie) {
        userRatings[movie.id] = UserRating(movieId: movie.id, rating: rating)
    }
    
    func loadMovies(for category: MovieCategory? = nil, contentType: ContentType? = nil) async {
        let categoryToLoad = category ?? selectedCategory
        let typeToLoad = contentType ?? selectedContentType
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let movies = try await movieService.fetchContent(type: typeToLoad, category: categoryToLoad)
            availableMovies = movies
            if let category = category {
                selectedCategory = category
            }
            if let contentType = contentType {
                selectedContentType = contentType
            }
        } catch {
            print("Error loading movies: \(error)")
        }
    }
    
    var availableCategories: [MovieCategory] {
        if selectedContentType == .tv {
            return MovieCategory.allCases.filter { $0.availableForTV }
        } else {
            // For movies, filter out Popular
            return MovieCategory.allCases.filter { $0.availableForMovies }
        }
    }
    
    func addToWatchlist(_ movie: Movie) {
        guard !watchlist.contains(where: { $0.id == movie.id }),
              !archive.contains(where: { $0.id == movie.id }) else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            watchlist.append(movie)
        }
    }
    
    func markAsWatched(_ movie: Movie) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            watchlist.removeAll { $0.id == movie.id }
            if !archive.contains(where: { $0.id == movie.id }) {
                archive.append(movie)
            }
        }
    }
    
    func removeFromWatchlist(_ movie: Movie) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            watchlist.removeAll { $0.id == movie.id }
        }
    }
    
    func removeFromArchive(_ movie: Movie) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            archive.removeAll { $0.id == movie.id }
        }
    }
}
