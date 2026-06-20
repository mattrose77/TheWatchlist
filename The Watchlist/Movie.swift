//
//  Movie.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import Foundation

struct Movie: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    var backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    var mediaType: String? // "movie" or "tv"
    var numberOfSeasons: Int? // For TV shows only
    var runtime: Int? // Runtime in minutes (for movies only)
    var director: String? // Director name (for movies only)
    var genreIds: [Int]? // Genre IDs from TMDB
    var genres: [Genre]? // Genre objects with id and name
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case mediaType = "media_type"
        case numberOfSeasons = "number_of_seasons"
        case runtime
        case director
        case genreIds = "genre_ids"
        case genres
    }
    
    // Memberwise initializer for testing and previews
    init(id: Int, title: String, overview: String, posterPath: String?, backdropPath: String? = nil, releaseDate: String?, voteAverage: Double, mediaType: String? = nil, numberOfSeasons: Int? = nil, runtime: Int? = nil, director: String? = nil, genreIds: [Int]? = nil, genres: [Genre]? = nil) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.mediaType = mediaType
        self.numberOfSeasons = numberOfSeasons
        self.runtime = runtime
        self.director = director
        self.genreIds = genreIds
        self.genres = genres
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        
        // TV shows use "name" instead of "title"
        if let titleValue = try? container.decode(String.self, forKey: .title) {
            title = titleValue
        } else if let nameValue = try? container.decode(String.self, forKey: .name) {
            title = nameValue
        } else {
            title = "Unknown"
        }
        
        overview = try container.decode(String.self, forKey: .overview)
        posterPath = try? container.decode(String.self, forKey: .posterPath)
        backdropPath = try? container.decode(String.self, forKey: .backdropPath)
        
        // TV shows use "first_air_date" instead of "release_date"
        if let releaseDateValue = try? container.decode(String.self, forKey: .releaseDate) {
            releaseDate = releaseDateValue
        } else if let firstAirDateValue = try? container.decode(String.self, forKey: .firstAirDate) {
            releaseDate = firstAirDateValue
        } else {
            releaseDate = nil
        }
        
        voteAverage = try container.decode(Double.self, forKey: .voteAverage)
        mediaType = try? container.decode(String.self, forKey: .mediaType)
        numberOfSeasons = try? container.decode(Int.self, forKey: .numberOfSeasons)
        runtime = try? container.decode(Int.self, forKey: .runtime)
        director = try? container.decode(String.self, forKey: .director)
        genreIds = try? container.decode([Int].self, forKey: .genreIds)
        genres = try? container.decode([Genre].self, forKey: .genres)
    }
    
    // Encoder for when we need to save data
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(overview, forKey: .overview)
        try container.encodeIfPresent(posterPath, forKey: .posterPath)
        try container.encodeIfPresent(backdropPath, forKey: .backdropPath)
        try container.encodeIfPresent(releaseDate, forKey: .releaseDate)
        try container.encode(voteAverage, forKey: .voteAverage)
        try container.encodeIfPresent(mediaType, forKey: .mediaType)
        try container.encodeIfPresent(numberOfSeasons, forKey: .numberOfSeasons)
        try container.encodeIfPresent(runtime, forKey: .runtime)
        try container.encodeIfPresent(director, forKey: .director)
        try container.encodeIfPresent(genreIds, forKey: .genreIds)
        try container.encodeIfPresent(genres, forKey: .genres)
    }
    
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var backdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(backdropPath)")
    }
    
    var year: String {
        guard let releaseDate = releaseDate else { return "N/A" }
        return String(releaseDate.prefix(4))
    }
    
    var isTV: Bool {
        return mediaType == "tv"
    }
    
    var isMovie: Bool {
        return mediaType == "movie" || mediaType == nil // Default to movie if not specified
    }
    
    var formattedRuntime: String? {
        guard let runtime = runtime, runtime > 0 else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

struct MovieResponse: Codable {
    let results: [Movie]
}
// MARK: - Genre

struct Genre: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    
    /// Display name with shortened versions for better UI
    var displayName: String {
        switch name {
        case "Science Fiction":
            return "Sci-Fi"
        default:
            return name
        }
    }
}


