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
}
