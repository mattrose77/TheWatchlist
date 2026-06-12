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
    @Published var topFourMovieIDs: [Int] = [] {
        didSet {
            saveTopFour()
        }
    }
    @Published var topFourTVIDs: [Int] = [] {
        didSet {
            saveTopFour()
        }
    }
    @Published var upNextQueueMovieIDs: [Int] = [] {
        didSet {
            saveUpNextQueue()
        }
    }
    @Published var upNextQueueTVIDs: [Int] = [] {
        didSet {
            saveUpNextQueue()
        }
    }
    @Published var isLoading = false
    @Published var selectedCategory: MovieCategory = .trending
    @Published var selectedContentType: ContentType = .movies
    @Published var currentMilestone: Milestone?
    
    private var achievedMilestones: Set<String> {
        get {
            let milestones = UserDefaults.standard.stringArray(forKey: "achieved_milestones") ?? []
            return Set(milestones)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "achieved_milestones")
        }
    }
    
    private let milestoneThresholds = [25, 50, 75, 100, 150, 200, 250, 300]
    
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
    
    private var topFourURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("topfour.json")
    }
    
    private var upNextQueueURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("upnextqueue.json")
    }
    
    init() {
        loadWatchlist()
        loadArchive()
        loadRatings()
        loadTopFour()
        loadUpNextQueue()
        performDataMigrationIfNeeded()
    }
    
    // MARK: - Data Migration
    
    /// Performs one-time data migration to ensure data integrity and forward compatibility
    private func performDataMigrationIfNeeded() {
        // V2 migration is complete, now check for V3
        migrateToV3IfNeeded()
        // V4 migration: Top Four data validation and cleanup
        migrateToV4IfNeeded()
    }
    
    /// Migration V3: Fix ratings that were lost during V2 migration
    /// This attempts to reload ratings data that may have failed to decode
    private func migrateToV3IfNeeded() {
        let migrationKey = "watchlist_migration_v3_complete"
        
        // Check if migration has already been completed
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            return
        }
        
        print("🔄 Starting migration V3: Ratings recovery")
        
        // Force reload ratings with improved error handling
        // The updated UserRating decoder will now handle old format
        if FileManager.default.fileExists(atPath: ratingsURL.path) {
            do {
                let data = try Data(contentsOf: ratingsURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let ratingsArray = try decoder.decode([UserRating].self, from: data)
                userRatings = Dictionary(uniqueKeysWithValues: ratingsArray.map { ($0.movieId, $0) })
                print("✅ Migration V3: Successfully recovered \(userRatings.count) ratings")
            } catch {
                print("⚠️ Migration V3: Could not decode ratings file: \(error)")
                // Keep existing userRatings dictionary as-is
            }
        } else {
            print("ℹ️ Migration V3: No existing ratings file found")
        }
        
        // Save ratings in new format to ensure consistency
        saveRatings()
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
        print("✅ Migration V3 complete")
    }
    
    /// Migration V4: Top Four data validation and schema versioning
    /// This migration:
    /// - Validates Top Four IDs exist in the archive
    /// - Removes stale/invalid IDs
    /// - Caps each list at 4 items
    /// - De-duplicates IDs
    /// - Ensures schema version is set
    private func migrateToV4IfNeeded() {
        let migrationKey = "watchlist_migration_v4_complete"
        
        // Check if migration has already been completed
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            return
        }
        
        print("🔄 Starting migration V4: Top Four validation")
        
        // Validate and clean up Top Four data
        // This is safe to run even if no Top Four file exists yet
        validateAndCleanTopFour()
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
        print("✅ Migration V4 complete")
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
    
    private func saveTopFour() {
        do {
            // Always save with current schema version
            let topFourData = TopFourData(movieIDs: topFourMovieIDs, tvIDs: topFourTVIDs, schemaVersion: 1)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(topFourData)
            try data.write(to: topFourURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("❌ Error saving Top Four: \(error)")
        }
    }
    
    private func loadTopFour() {
        // If file doesn't exist, start with empty arrays (safe for new installs and existing users)
        guard FileManager.default.fileExists(atPath: topFourURL.path) else {
            topFourMovieIDs = []
            topFourTVIDs = []
            return
        }
        
        do {
            let data = try Data(contentsOf: topFourURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let topFourData = try decoder.decode(TopFourData.self, from: data)
            
            // Validate and clean the data before assigning
            let archiveIDs = Set(archive.map { $0.id })
            
            let validMovieIDs = Array(topFourData.movieIDs
                .filter { archiveIDs.contains($0) }  // Only keep IDs that exist in archive
                .uniqued()                            // Remove duplicates
                .prefix(4))                           // Cap at 4 items
            
            let validTVIDs = Array(topFourData.tvIDs
                .filter { archiveIDs.contains($0) }  // Only keep IDs that exist in archive
                .uniqued()                            // Remove duplicates
                .prefix(4))                           // Cap at 4 items
            
            // Count how many IDs were cleaned up
            let movieIDsRemoved = topFourData.movieIDs.count - validMovieIDs.count
            let tvIDsRemoved = topFourData.tvIDs.count - validTVIDs.count
            
            if movieIDsRemoved > 0 {
                print("🧹 Cleaned up \(movieIDsRemoved) invalid movie ID(s) from Top Four")
            }
            
            if tvIDsRemoved > 0 {
                print("🧹 Cleaned up \(tvIDsRemoved) invalid TV show ID(s) from Top Four")
            }
            
            // Assign validated data
            topFourMovieIDs = validMovieIDs
            topFourTVIDs = validTVIDs
            
            // If data was cleaned, save the cleaned version immediately
            if movieIDsRemoved > 0 || tvIDsRemoved > 0 {
                saveTopFour()
            }
            
        } catch {
            print("⚠️ Error loading Top Four: \(error)")
            // Safe fallback: start with empty arrays
            topFourMovieIDs = []
            topFourTVIDs = []
        }
    }
    
    private func saveUpNextQueue() {
        do {
            let queueData = UpNextQueueData(movieIDs: upNextQueueMovieIDs, tvIDs: upNextQueueTVIDs, schemaVersion: 1)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(queueData)
            try data.write(to: upNextQueueURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("❌ Error saving Up Next Queue: \(error)")
        }
    }
    
    private func loadUpNextQueue() {
        guard FileManager.default.fileExists(atPath: upNextQueueURL.path) else {
            upNextQueueMovieIDs = []
            upNextQueueTVIDs = []
            return
        }
        
        do {
            let data = try Data(contentsOf: upNextQueueURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let queueData = try decoder.decode(UpNextQueueData.self, from: data)
            
            // Validate and clean the data before assigning
            let watchlistIDs = Set(watchlist.map { $0.id })
            
            let validMovieIDs = Array(queueData.movieIDs
                .filter { watchlistIDs.contains($0) }  // Only keep IDs that exist in watchlist
                .uniqued()                              // Remove duplicates
                .prefix(3))                             // Cap at 3 items
            
            let validTVIDs = Array(queueData.tvIDs
                .filter { watchlistIDs.contains($0) }  // Only keep IDs that exist in watchlist
                .uniqued()                              // Remove duplicates
                .prefix(3))                             // Cap at 3 items
            
            // Count how many IDs were cleaned up
            let movieIDsRemoved = queueData.movieIDs.count - validMovieIDs.count
            let tvIDsRemoved = queueData.tvIDs.count - validTVIDs.count
            
            if movieIDsRemoved > 0 {
                print("🧹 Cleaned up \(movieIDsRemoved) invalid movie ID(s) from Up Next Queue")
            }
            
            if tvIDsRemoved > 0 {
                print("🧹 Cleaned up \(tvIDsRemoved) invalid TV show ID(s) from Up Next Queue")
            }
            
            // Assign validated data
            upNextQueueMovieIDs = validMovieIDs
            upNextQueueTVIDs = validTVIDs
            
            // If data was cleaned, save the cleaned version immediately
            if movieIDsRemoved > 0 || tvIDsRemoved > 0 {
                saveUpNextQueue()
            }
            
        } catch {
            print("⚠️ Error loading Up Next Queue: \(error)")
            upNextQueueMovieIDs = []
            upNextQueueTVIDs = []
        }
    }
    
    /// Validates Top Four data and removes any invalid entries
    /// This ensures that:
    /// - Only items that exist in the archive are included
    /// - Each list is capped at 4 items
    /// - No duplicate IDs exist
    /// This method is idempotent and safe to call multiple times
    private func validateAndCleanTopFour() {
        let archiveIDs = Set(archive.map { $0.id })
        
        // Validate movies
        let validMovieIDs = Array(topFourMovieIDs
            .filter { archiveIDs.contains($0) }  // Only keep IDs that exist in archive
            .uniqued()                            // Remove duplicates
            .prefix(4))                           // Cap at 4 items
        
        // Validate TV shows
        let validTVIDs = Array(topFourTVIDs
            .filter { archiveIDs.contains($0) }  // Only keep IDs that exist in archive
            .uniqued()                            // Remove duplicates
            .prefix(4))                           // Cap at 4 items
        
        // Count how many IDs were cleaned up
        let movieIDsRemoved = topFourMovieIDs.count - validMovieIDs.count
        let tvIDsRemoved = topFourTVIDs.count - validTVIDs.count
        
        // Update arrays only if they changed
        if movieIDsRemoved > 0 {
            print("🧹 Cleaned up \(movieIDsRemoved) invalid movie ID(s) from Top Four")
            topFourMovieIDs = validMovieIDs
        }
        
        if tvIDsRemoved > 0 {
            print("🧹 Cleaned up \(tvIDsRemoved) invalid TV show ID(s) from Top Four")
            topFourTVIDs = validTVIDs
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
            // Remove from Up Next Queue if present
            removeFromUpNextQueue(movieID: movie.id)
            if !archive.contains(where: { $0.id == movie.id }) {
                archive.append(movie)
                // Check for milestone after adding
                checkForMilestone(movie: movie)
            }
        }
    }
    
    func addToArchive(_ movie: Movie) {
        guard !archive.contains(where: { $0.id == movie.id }) else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            // Remove from watchlist if it's there
            watchlist.removeAll { $0.id == movie.id }
            // Add to archive
            archive.append(movie)
            // Check for milestone after adding
            checkForMilestone(movie: movie)
        }
    }
    
    private func checkForMilestone(movie: Movie) {
        // Determine content type
        let contentType: ContentType = movie.isMovie ? .movies : .tv
        
        // Count items of this type
        let count = archive.filter { movie in
            contentType == .movies ? movie.isMovie : movie.isTV
        }.count
        
        // Check if this count is a milestone threshold
        guard milestoneThresholds.contains(count) else { return }
        
        // Create milestone key
        let milestoneKey = "\(contentType.rawValue)-\(count)"
        
        // Check if we've already achieved this milestone
        guard !achievedMilestones.contains(milestoneKey) else { return }
        
        // Create the milestone and show it
        if let milestone = Milestone.milestone(for: count, contentType: contentType) {
            // Mark as achieved
            var milestones = achievedMilestones
            milestones.insert(milestoneKey)
            achievedMilestones = milestones
            
            // Show the milestone with animation (delayed slightly to let the detail view dismiss)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.currentMilestone = milestone
                }
            }
        }
    }
    
    func dismissMilestone() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentMilestone = nil
        }
    }
    
    func removeFromWatchlist(_ movie: Movie) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            watchlist.removeAll { $0.id == movie.id }
            // Remove from Up Next Queue if present
            removeFromUpNextQueue(movieID: movie.id)
        }
    }
    
    func removeFromArchive(_ movie: Movie) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            archive.removeAll { $0.id == movie.id }
            // Remove from Top 4 if present
            removeFromTopFour(movieID: movie.id)
        }
    }
    
    // MARK: - Top Four Management
    
    func getTopFour(for contentType: ContentType) -> [Int] {
        return contentType == .movies ? topFourMovieIDs : topFourTVIDs
    }
    
    func setTopFour(_ ids: [Int], for contentType: ContentType) {
        if contentType == .movies {
            topFourMovieIDs = ids
        } else {
            topFourTVIDs = ids
        }
    }
    
    func addToTopFour(movieID: Int, for contentType: ContentType) {
        var current = getTopFour(for: contentType)
        guard !current.contains(movieID), current.count < 4 else { return }
        current.append(movieID)
        setTopFour(current, for: contentType)
    }
    
    func removeFromTopFour(movieID: Int) {
        // Remove from both lists
        topFourMovieIDs.removeAll { $0 == movieID }
        topFourTVIDs.removeAll { $0 == movieID }
    }
    
    func toggleTopFour(movieID: Int, for contentType: ContentType) {
        var current = getTopFour(for: contentType)
        if let index = current.firstIndex(of: movieID) {
            current.remove(at: index)
        } else if current.count < 4 {
            current.append(movieID)
        }
        setTopFour(current, for: contentType)
    }
    
    func getTopFourMovies(for contentType: ContentType) -> [Movie] {
        let ids = getTopFour(for: contentType)
        return ids.compactMap { id in
            archive.first { $0.id == id }
        }
    }
    
    // MARK: - Up Next Queue Management
    
    func getUpNextQueue(for contentType: ContentType) -> [Int] {
        return contentType == .movies ? upNextQueueMovieIDs : upNextQueueTVIDs
    }
    
    func setUpNextQueue(_ ids: [Int], for contentType: ContentType) {
        // Cap at 3 items and ensure no gaps
        let validIDs = Array(ids.prefix(3))
        if contentType == .movies {
            upNextQueueMovieIDs = validIDs
        } else {
            upNextQueueTVIDs = validIDs
        }
    }
    
    func addToUpNextQueue(movieID: Int, for contentType: ContentType) {
        var current = getUpNextQueue(for: contentType)
        // Don't add if already in queue or queue is full
        guard !current.contains(movieID), current.count < 3 else { return }
        // Add to the first empty slot (queue stays contiguous)
        current.append(movieID)
        setUpNextQueue(current, for: contentType)
    }
    
    func removeFromUpNextQueue(movieID: Int, for contentType: ContentType) {
        var current = getUpNextQueue(for: contentType)
        current.removeAll { $0 == movieID }
        setUpNextQueue(current, for: contentType)
    }
    
    /// Remove a movie from Up Next Queue across both content types
    /// This is called when a movie is removed from watchlist or marked as watched
    private func removeFromUpNextQueue(movieID: Int) {
        // Remove from both queues if present
        upNextQueueMovieIDs.removeAll { $0 == movieID }
        upNextQueueTVIDs.removeAll { $0 == movieID }
    }
    
    func getUpNextQueueMovies(for contentType: ContentType) -> [Movie] {
        let ids = getUpNextQueue(for: contentType)
        return ids.compactMap { id in
            watchlist.first { $0.id == id }
        }
    }
}
// MARK: - Top Four Data Structure

/// Container for Top Four data with versioning support
struct TopFourData: Codable {
    /// Schema version for future migrations
    let schemaVersion: Int
    
    /// Movie IDs for Top 4 movies (max 4 items)
    let movieIDs: [Int]
    
    /// TV show IDs for Top 4 TV shows (max 4 items)
    let tvIDs: [Int]
    
    init(movieIDs: [Int], tvIDs: [Int], schemaVersion: Int = 1) {
        self.schemaVersion = schemaVersion
        self.movieIDs = movieIDs
        self.tvIDs = tvIDs
    }
    
    // Custom decoding to handle migration from old format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Schema version: default to 0 for data that predates versioning
        // Version 1 = first version with Top Four support
        schemaVersion = (try? container.decode(Int.self, forKey: .schemaVersion)) ?? 0
        
        // Top Four arrays: use empty arrays if they don't exist (safe for old data)
        // This ensures that users upgrading from versions without Top Four get empty arrays
        movieIDs = (try? container.decode([Int].self, forKey: .movieIDs)) ?? []
        tvIDs = (try? container.decode([Int].self, forKey: .tvIDs)) ?? []
    }
}

// MARK: - Up Next Queue Data Structure

/// Container for Up Next Queue data with versioning support
struct UpNextQueueData: Codable {
    /// Schema version for future migrations
    let schemaVersion: Int
    
    /// Movie IDs for Up Next Queue movies (max 3 items)
    let movieIDs: [Int]
    
    /// TV show IDs for Up Next Queue TV shows (max 3 items)
    let tvIDs: [Int]
    
    init(movieIDs: [Int], tvIDs: [Int], schemaVersion: Int = 1) {
        self.schemaVersion = schemaVersion
        self.movieIDs = movieIDs
        self.tvIDs = tvIDs
    }
    
    // Custom decoding to handle migration from old format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        schemaVersion = (try? container.decode(Int.self, forKey: .schemaVersion)) ?? 0
        movieIDs = (try? container.decode([Int].self, forKey: .movieIDs)) ?? []
        tvIDs = (try? container.decode([Int].self, forKey: .tvIDs)) ?? []
    }
}

// MARK: - Array Extensions

private extension Array where Element: Hashable {
    /// Returns an array with duplicate elements removed, preserving order
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}



