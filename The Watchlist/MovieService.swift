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

struct MovieCollection: Codable, Identifiable {
    let id: Int
    let name: String
    let posterPath: String?
    let backdropPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
}

struct CollectionDetails: Codable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let parts: [Movie]
    
    enum CodingKeys: String, CodingKey {
        case id, name, overview, parts
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
}

struct MovieDetails: Codable {
    let id: Int
    let title: String?
    let name: String?
    let belongsToCollection: MovieCollection?
    let runtime: Int?
    let credits: Credits?
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, runtime, credits
        case belongsToCollection = "belongs_to_collection"
    }
    
    var director: String? {
        // First try to find director specifically in the Directing department
        if let director = credits?.crew.first(where: { 
            $0.job.lowercased() == "director" && $0.department?.lowercased() == "directing"
        }) {
            return director.name
        }
        
        // Fallback: just find anyone with Director job title
        return credits?.crew.first(where: { $0.job.lowercased() == "director" })?.name
    }
}

struct Credits: Codable {
    let crew: [CrewMember]
}

struct CrewMember: Codable {
    let name: String
    let job: String
    let department: String?
    let order: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, job, department, order
    }
}

struct WatchProvider: Codable, Identifiable {
    let logoPath: String
    let providerId: Int
    let providerName: String
    let displayPriority: Int
    
    var id: Int { providerId }
    
    enum CodingKeys: String, CodingKey {
        case logoPath = "logo_path"
        case providerId = "provider_id"
        case providerName = "provider_name"
        case displayPriority = "display_priority"
    }
    
    var logoURL: URL? {
        // logoPath from TMDB includes the leading slash
        guard !logoPath.isEmpty else { return nil }
        let urlString = "https://image.tmdb.org/t/p/w92\(logoPath)"
        return URL(string: urlString)
    }
}

struct WatchProviderData: Codable {
    let link: String?
    let flatrate: [WatchProvider]?
    let buy: [WatchProvider]?
    let rent: [WatchProvider]?
    
    // Get only streaming providers (flatrate)
    var streamingProviders: [WatchProvider] {
        guard let flatrate = flatrate else { return [] }
        return flatrate.sorted { $0.displayPriority < $1.displayPriority }
    }
    
    // Get all unique providers (prioritize streaming)
    var allProviders: [WatchProvider] {
        var providers: [WatchProvider] = []
        var seenIds = Set<Int>()
        
        // Add streaming providers first
        if let flatrate = flatrate {
            for provider in flatrate {
                if !seenIds.contains(provider.providerId) {
                    providers.append(provider)
                    seenIds.insert(provider.providerId)
                }
            }
        }
        
        // Then buy options
        if let buy = buy {
            for provider in buy {
                if !seenIds.contains(provider.providerId) {
                    providers.append(provider)
                    seenIds.insert(provider.providerId)
                }
            }
        }
        
        // Finally rent options
        if let rent = rent {
            for provider in rent {
                if !seenIds.contains(provider.providerId) {
                    providers.append(provider)
                    seenIds.insert(provider.providerId)
                }
            }
        }
        
        return providers.sorted { $0.displayPriority < $1.displayPriority }
    }
}

struct WatchProviderResults: Codable {
    let results: [String: WatchProviderData]
    
    // Get UK providers
    var ukProviders: WatchProviderData? {
        return results["GB"]
    }
}

@MainActor
class MovieService: ObservableObject {
    private let apiKey = "3e53f26a4303447ddc429900ac7ced1a"
    private let baseURL = "https://api.themoviedb.org/3"
    
    func fetchContent(type: ContentType, category: MovieCategory, pages: Int = 5) async throws -> [Movie] {
        var seenIDs = Set<Int>()
        var allMovies: [Movie] = []
        let mediaTypeString = type == .movies ? "movie" : "tv"
        
        // Get the start of today for date comparison (ignoring time)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Fetch multiple pages (default 5 pages = 100 movies)
        for page in 1...pages {
            let urlString: String
            
            if type == .movies {
                switch category {
                case .popular:
                    urlString = "\(baseURL)/movie/popular?api_key=\(apiKey)&language=en-US&page=\(page)&include_adult=false"
                case .topRated:
                    urlString = "\(baseURL)/movie/top_rated?api_key=\(apiKey)&language=en-US&page=\(page)&include_adult=false"
                case .nowPlaying:
                    urlString = "\(baseURL)/movie/now_playing?api_key=\(apiKey)&language=en-US&page=\(page)&include_adult=false"
                case .upcoming:
                    urlString = "\(baseURL)/movie/upcoming?api_key=\(apiKey)&language=en-US&page=\(page)&include_adult=false"
                case .trending:
                    urlString = "\(baseURL)/trending/movie/week?api_key=\(apiKey)&language=en-US&page=\(page)&include_adult=false"
                }
            } else { // TV Shows
                switch category {
                case .popular:
                    urlString = "\(baseURL)/tv/popular?api_key=\(apiKey)&language=en-US&page=\(page)&include_adult=false"
                case .topRated:
                    urlString = "\(baseURL)/tv/top_rated?api_key=\(apiKey)&language=en-US&page=\(page)&include_adult=false"
                case .trending:
                    urlString = "\(baseURL)/trending/tv/week?api_key=\(apiKey)&language=en-US&page=\(page)&include_adult=false"
                case .nowPlaying, .upcoming:
                    // These don't exist for TV, fallback to popular
                    urlString = "\(baseURL)/tv/popular?api_key=\(apiKey)&language=en-US&page=\(page)&include_adult=false"
                }
            }
            
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MovieResponse.self, from: data)
            
            // Set the mediaType for each movie and filter out items without posters and duplicates
            let moviesWithType = response.results.compactMap { movie -> Movie? in
                // Skip movies without poster images
                guard movie.posterPath != nil else { return nil }
                
                // Skip duplicates
                guard !seenIDs.contains(movie.id) else { return nil }
                seenIDs.insert(movie.id)
                
                // For upcoming movies, only include movies with future release dates
                if category == .upcoming {
                    // If no release date, keep it (might be TBA)
                    guard let releaseDateString = movie.releaseDate else {
                        var updatedMovie = movie
                        updatedMovie.mediaType = mediaTypeString
                        return updatedMovie
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    if let releaseDate = dateFormatter.date(from: releaseDateString) {
                        let releaseDateStartOfDay = calendar.startOfDay(for: releaseDate)
                        // Only include movies releasing tomorrow or later
                        guard releaseDateStartOfDay > today else { return nil }
                    }
                }
                
                var updatedMovie = movie
                updatedMovie.mediaType = mediaTypeString
                return updatedMovie
            }
            
            allMovies.append(contentsOf: moviesWithType)
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
    
    // Search method - fetches multiple pages for better results
    func searchContent(query: String, type: ContentType, pages: Int = 3) async throws -> [Movie] {
        let mediaType = type == .movies ? "movie" : "tv"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        
        var seenIDs = Set<Int>()
        var allResults: [Movie] = []
        
        // Fetch multiple pages for more comprehensive results
        for page in 1...pages {
            let urlString = "\(baseURL)/search/\(mediaType)?api_key=\(apiKey)&language=en-US&query=\(encodedQuery)&page=\(page)&include_adult=false"
            
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MovieResponse.self, from: data)
            
            // Set the mediaType for each result and filter out items without posters and duplicates
            let resultsWithType = response.results.compactMap { movie -> Movie? in
                // Skip movies without poster images
                guard movie.posterPath != nil else { return nil }
                
                // Skip duplicates
                guard !seenIDs.contains(movie.id) else { return nil }
                seenIDs.insert(movie.id)
                
                var updatedMovie = movie
                updatedMovie.mediaType = mediaType
                return updatedMovie
            }
            
            allResults.append(contentsOf: resultsWithType)
            
            // If we got fewer than 20 results, we've reached the end
            if response.results.count < 20 {
                break
            }
        }
        
        return allResults
    }
    
    // Fetch movie details to check if it belongs to a collection
    func fetchMovieDetails(movieId: Int) async throws -> MovieDetails {
        let urlString = "\(baseURL)/movie/\(movieId)?api_key=\(apiKey)&language=en-US&append_to_response=credits"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let details = try JSONDecoder().decode(MovieDetails.self, from: data)
        
        return details
    }
    
    // Fetch all movies in a collection
    func fetchCollection(collectionId: Int) async throws -> CollectionDetails {
        let urlString = "\(baseURL)/collection/\(collectionId)?api_key=\(apiKey)&language=en-US"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let collection = try JSONDecoder().decode(CollectionDetails.self, from: data)
        
        return collection
    }
    
    // Fetch TV show details to get number of seasons
    func fetchTVShowDetails(tvShowId: Int) async throws -> Movie {
        let urlString = "\(baseURL)/tv/\(tvShowId)?api_key=\(apiKey)&language=en-US"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        var tvShow = try JSONDecoder().decode(Movie.self, from: data)
        
        // Ensure mediaType is set
        tvShow.mediaType = "tv"
        
        return tvShow
    }
    
    // Fetch watch providers (where to watch)
    func fetchWatchProviders(for movieId: Int, contentType: ContentType) async throws -> WatchProviderData? {
        let mediaType = contentType == .movies ? "movie" : "tv"
        let urlString = "\(baseURL)/\(mediaType)/\(movieId)/watch/providers?api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WatchProviderResults.self, from: data)
        
        return response.ukProviders
    }
}
