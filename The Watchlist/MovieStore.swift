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
    @Published var watchlist: [Movie] = []
    @Published var archive: [Movie] = []
    @Published var isLoading = false
    @Published var selectedCategory: MovieCategory = .trending
    @Published var selectedContentType: ContentType = .movies
    
    let movieService = MovieService()
    
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
