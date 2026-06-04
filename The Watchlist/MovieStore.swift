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
    }
    
    // MARK: - Persistence Methods
    
    private func saveWatchlist() {
        do {
            let data = try JSONEncoder().encode(watchlist)
            try data.write(to: watchlistURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Error saving watchlist: \(error)")
        }
    }
    
    private func loadWatchlist() {
        guard FileManager.default.fileExists(atPath: watchlistURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: watchlistURL)
            watchlist = try JSONDecoder().decode([Movie].self, from: data)
        } catch {
            print("Error loading watchlist: \(error)")
        }
    }
    
    private func saveArchive() {
        do {
            let data = try JSONEncoder().encode(archive)
            try data.write(to: archiveURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Error saving archive: \(error)")
        }
    }
    
    private func loadArchive() {
        guard FileManager.default.fileExists(atPath: archiveURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: archiveURL)
            archive = try JSONDecoder().decode([Movie].self, from: data)
        } catch {
            print("Error loading archive: \(error)")
        }
    }
    
    private func saveRatings() {
        do {
            // Convert dictionary to array for encoding
            let ratingsArray = Array(userRatings.values)
            let data = try JSONEncoder().encode(ratingsArray)
            try data.write(to: ratingsURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Error saving ratings: \(error)")
        }
    }
    
    private func loadRatings() {
        guard FileManager.default.fileExists(atPath: ratingsURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: ratingsURL)
            let ratingsArray = try JSONDecoder().decode([UserRating].self, from: data)
            // Convert array back to dictionary
            userRatings = Dictionary(uniqueKeysWithValues: ratingsArray.map { ($0.movieId, $0) })
        } catch {
            print("Error loading ratings: \(error)")
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
