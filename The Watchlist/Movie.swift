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
    let releaseDate: String?
    let voteAverage: Double
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
    }
    
    // Memberwise initializer for testing and previews
    init(id: Int, title: String, overview: String, posterPath: String?, releaseDate: String?, voteAverage: Double) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
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
        
        // TV shows use "first_air_date" instead of "release_date"
        if let releaseDateValue = try? container.decode(String.self, forKey: .releaseDate) {
            releaseDate = releaseDateValue
        } else if let firstAirDateValue = try? container.decode(String.self, forKey: .firstAirDate) {
            releaseDate = firstAirDateValue
        } else {
            releaseDate = nil
        }
        
        voteAverage = try container.decode(Double.self, forKey: .voteAverage)
    }
    
    // Encoder for when we need to save data
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(overview, forKey: .overview)
        try container.encodeIfPresent(posterPath, forKey: .posterPath)
        try container.encodeIfPresent(releaseDate, forKey: .releaseDate)
        try container.encode(voteAverage, forKey: .voteAverage)
    }
    
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var year: String {
        guard let releaseDate = releaseDate else { return "N/A" }
        return String(releaseDate.prefix(4))
    }
}

struct MovieResponse: Codable {
    let results: [Movie]
}
