//
//  ProfileStats.swift
//  The Watchlist
//
//  Created by Matt Rose on 19/06/2026.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Supporting Models

/// Represents a genre with its count for ranking purposes
struct GenreRank: Identifiable {
    let id: Int
    let name: String
    let count: Int
}

/// Represents a watched movie for display in genre sections
struct WatchedMovieForGenre: Identifiable {
    let id: Int
    let title: String
    let posterURL: URL?
    let rating: Double
}

// MARK: - ProfileStats

/// Observable object that calculates and provides profile statistics
@MainActor
class ProfileStats: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var totalWatchTime: Int = 0 // in minutes
    @Published private(set) var titlesCount: Int = 0
    @Published private(set) var topGenres: [GenreRank] = []
    @Published private(set) var moviesByGenre: [Int: [WatchedMovieForGenre]] = [:]
    
    // MARK: - Private Properties
    
    private let archive: [Movie]
    private let ratings: [Int: UserRating]
    
    // MARK: - Initialization
    
    init(archive: [Movie], ratings: [Int: UserRating]) {
        self.archive = archive
        self.ratings = ratings
        calculateStats()
    }
    
    // MARK: - Computed Properties
    
    /// Formatted watch time string (e.g., "24h" or "156h")
    var formattedWatchTime: String {
        let hours = totalWatchTime / 60
        return "\(hours)h"
    }
    
    /// Percentage share of the top genre
    var topGenreSharePercent: Double {
        guard let topGenre = topGenres.first, titlesCount > 0 else { return 0 }
        return (Double(topGenre.count) / Double(titlesCount)) * 100.0
    }
    
    // MARK: - Achievements
    
    /// User has watched 25 or more titles
    var hasFirst25Achievement: Bool {
        titlesCount >= 25
    }
    
    /// User has watched 50 or more films
    var has50FilmsAchievement: Bool {
        titlesCount >= 50
    }
    
    /// User has watched 10+ movies in a single genre
    var hasGenreBuffAchievement: (unlocked: Bool, genreName: String?) {
        if let topGenre = topGenres.first, topGenre.count >= 10 {
            return (true, topGenre.name)
        }
        return (false, nil)
    }
    
    /// User has watched a complete saga (franchise with 3+ movies)
    var hasSagaDoneAchievement: Bool {
        // Check if user has watched multiple movies from the same franchise
        // For simplicity, we'll check if they have 3+ movies with similar titles
        let titleGroups = Dictionary(grouping: archive) { movie -> String in
            // Extract potential franchise name (first word or two)
            let components = movie.title.components(separatedBy: " ")
            if components.count >= 2 {
                return components[0...1].joined(separator: " ")
            }
            return components.first ?? movie.title
        }
        
        // Check if any group has 3+ movies
        return titleGroups.values.contains { $0.count >= 3 }
    }
    
    /// User has watched 10+ movies released in 2000 or earlier
    var hasClassicsScholarAchievement: Bool {
        let classicsCount = archive.filter { movie in
            guard let releaseDateString = movie.releaseDate else { return false }
            
            // Parse year from release date (format: "YYYY-MM-DD")
            let yearString = String(releaseDateString.prefix(4))
            guard let year = Int(yearString) else { return false }
            
            return year <= 2000
        }.count
        
        return classicsCount >= 10
    }
    
    /// User has rated 25+ movies
    var hasCriticsChoiceAchievement: Bool {
        ratings.count >= 25
    }
    
    /// User has given 10 movies a 5-star rating
    var hasPerfectScoreAchievement: Bool {
        let perfectRatings = ratings.values.filter { $0.rating >= 5.0 }.count
        return perfectRatings >= 10
    }
    
    /// User has rated a movie 1 star or lower
    var hasHarshCriticAchievement: Bool {
        ratings.values.contains { $0.rating <= 1.0 }
    }
    
    /// User has watched 10+ movies under 90 minutes runtime
    var hasSpeedDemonAchievement: Bool {
        let shortMoviesCount = archive.filter { movie in
            guard let runtime = movie.runtime else { return false }
            return runtime < 90
        }.count
        
        return shortMoviesCount >= 10
    }
    
    /// User has watched 5+ movies over 3 hours long
    var hasEpicViewerAchievement: Bool {
        let epicMoviesCount = archive.filter { movie in
            guard let runtime = movie.runtime else { return false }
            return runtime >= 180
        }.count
        
        return epicMoviesCount >= 5
    }
    
    /// User has watched at least one movie from 5 different decades
    var hasDecadeExplorerAchievement: Bool {
        var decades = Set<Int>()
        
        for movie in archive {
            guard let releaseDateString = movie.releaseDate else { continue }
            
            // Parse year from release date (format: "YYYY-MM-DD")
            let yearString = String(releaseDateString.prefix(4))
            guard let year = Int(yearString) else { continue }
            
            // Calculate decade (e.g., 1995 -> 1990, 2003 -> 2000)
            let decade = (year / 10) * 10
            decades.insert(decade)
        }
        
        return decades.count >= 5
    }
    
    // MARK: - Data Methods
    
    /// Returns movies for a specific genre
    func moviesForGenre(genreId: Int) -> [WatchedMovieForGenre] {
        return moviesByGenre[genreId] ?? []
    }
    
    // MARK: - Private Methods
    
    private func calculateStats() {
        // Calculate total watch time and titles count
        var totalMinutes = 0
        var genreCounts: [Int: (name: String, count: Int)] = [:]
        var moviesPerGenre: [Int: [WatchedMovieForGenre]] = [:]
        
        for movie in archive {
            // Count titles
            titlesCount += 1
            
            // Add runtime
            if let runtime = movie.runtime, runtime > 0 {
                totalMinutes += runtime
            }
            
            // Count genres
            if let genres = movie.genres {
                for genre in genres {
                    if genreCounts[genre.id] != nil {
                        genreCounts[genre.id]?.count += 1
                    } else {
                        genreCounts[genre.id] = (name: genre.displayName, count: 1)
                    }
                    
                    // Build movies per genre
                    let watchedMovie = WatchedMovieForGenre(
                        id: movie.id,
                        title: movie.title,
                        posterURL: movie.posterURL,
                        rating: ratings[movie.id]?.rating ?? movie.voteAverage
                    )
                    
                    if moviesPerGenre[genre.id] != nil {
                        moviesPerGenre[genre.id]?.append(watchedMovie)
                    } else {
                        moviesPerGenre[genre.id] = [watchedMovie]
                    }
                }
            }
        }
        
        totalWatchTime = totalMinutes
        
        // Sort genres by count and take top 5
        let sortedGenres = genreCounts.sorted { $0.value.count > $1.value.count }
        topGenres = sortedGenres.prefix(5).map { genreId, info in
            GenreRank(id: genreId, name: info.name, count: info.count)
        }
        
        // Sort movies within each genre by rating (highest first)
        for (genreId, movies) in moviesPerGenre {
            moviesPerGenre[genreId] = movies.sorted { $0.rating > $1.rating }
        }
        
        moviesByGenre = moviesPerGenre
    }
}
