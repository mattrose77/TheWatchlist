//
//  MovieService.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import Foundation
import Combine

enum ContentType: String, CaseIterable {
    case movies = "Movies"
    case tv = "TV Shows"
}

enum MovieCategory: String, CaseIterable {
    case trending = "Trending"
    case nowPlaying = "Now Playing"
    case upcoming = "Upcoming"
    case topRated = "Top Rated"
    case popular = "Popular"
    
    var availableForTV: Bool {
        switch self {
        case .nowPlaying, .upcoming:
            return false
        default:
            return true
        }
    }
    
    var availableForMovies: Bool {
        switch self {
        case .popular:
            return false
        default:
            return true
        }
    }
}

struct Video: Codable, Identifiable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
    let official: Bool
    
    var youtubeURL: URL? {
        guard site == "YouTube" else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
    
    var embedURL: URL? {
        guard site == "YouTube" else { return nil }
        return URL(string: "https://www.youtube.com/embed/\(key)")
    }
}

struct VideoResponse: Codable {
    let results: [Video]
}

@MainActor
class MovieService: ObservableObject {
    private let apiKey = "3e53f26a4303447ddc429900ac7ced1a"
    private let baseURL = "https://api.themoviedb.org/3"
    
    func fetchContent(type: ContentType, category: MovieCategory, pages: Int = 5) async throws -> [Movie] {
        var allMovies: [Movie] = []
        
        // Fetch multiple pages (default 5 pages = 100 movies)
        for page in 1...pages {
            let urlString: String
            
            if type == .movies {
                switch category {
                case .popular:
                    urlString = "\(baseURL)/movie/popular?api_key=\(apiKey)&language=en-US&page=\(page)"
                case .topRated:
                    urlString = "\(baseURL)/movie/top_rated?api_key=\(apiKey)&language=en-US&page=\(page)"
                case .nowPlaying:
                    urlString = "\(baseURL)/movie/now_playing?api_key=\(apiKey)&language=en-US&page=\(page)"
                case .upcoming:
                    urlString = "\(baseURL)/movie/upcoming?api_key=\(apiKey)&language=en-US&page=\(page)"
                case .trending:
                    urlString = "\(baseURL)/trending/movie/week?api_key=\(apiKey)&language=en-US&page=\(page)"
                }
            } else { // TV Shows
                switch category {
                case .popular:
                    urlString = "\(baseURL)/tv/popular?api_key=\(apiKey)&language=en-US&page=\(page)"
                case .topRated:
                    urlString = "\(baseURL)/tv/top_rated?api_key=\(apiKey)&language=en-US&page=\(page)"
                case .trending:
                    urlString = "\(baseURL)/trending/tv/week?api_key=\(apiKey)&language=en-US&page=\(page)"
                case .nowPlaying, .upcoming:
                    // These don't exist for TV, fallback to popular
                    urlString = "\(baseURL)/tv/popular?api_key=\(apiKey)&language=en-US&page=\(page)"
                }
            }
            
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MovieResponse.self, from: data)
            
            allMovies.append(contentsOf: response.results)
        }
        
        return allMovies
    }
    
    func fetchTrailer(for movieId: Int, contentType: ContentType) async throws -> Video? {
        let mediaType = contentType == .movies ? "movie" : "tv"
        let urlString = "\(baseURL)/\(mediaType)/\(movieId)/videos?api_key=\(apiKey)&language=en-US"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(VideoResponse.self, from: data)
        
        // Find the official trailer, or any trailer, or any video
        return response.results.first { $0.type == "Trailer" && $0.official }
            ?? response.results.first { $0.type == "Trailer" }
            ?? response.results.first
    }
    
    // Legacy methods for compatibility
    func fetchMovies(for category: MovieCategory) async throws -> [Movie] {
        return try await fetchContent(type: .movies, category: category)
    }
    
    func fetchPopularMovies() async throws -> [Movie] {
        return try await fetchContent(type: .movies, category: .popular)
    }
    
    // Search method
    func searchContent(query: String, type: ContentType) async throws -> [Movie] {
        let mediaType = type == .movies ? "movie" : "tv"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search/\(mediaType)?api_key=\(apiKey)&language=en-US&query=\(encodedQuery)&page=1"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(MovieResponse.self, from: data)
        
        return response.results
    }
}
