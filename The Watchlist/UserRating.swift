//
//  UserRating.swift
//  The Watchlist
//
//  Created by Matt Rose on 03/06/2026.
//

import Foundation

struct UserRating: Codable {
    let movieId: Int
    let rating: Double // 0.0 to 5.0, in 0.5 increments
    let date: Date
    
    init(movieId: Int, rating: Double, date: Date = Date()) {
        self.movieId = movieId
        self.rating = max(0, min(5, rating)) // Clamp between 0 and 5
        self.date = date
    }
    
    // Custom decoding to handle migration from old format without date
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        movieId = try container.decode(Int.self, forKey: .movieId)
        rating = try container.decode(Double.self, forKey: .rating)
        
        // If date doesn't exist (old format), use a default date
        if let decodedDate = try? container.decode(Date.self, forKey: .date) {
            date = decodedDate
        } else {
            // Use a placeholder date for migrated ratings
            date = Date(timeIntervalSince1970: 0)
        }
    }
}
