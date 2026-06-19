//
//  MovieCollectionCarousel.swift
//  The Watchlist
//
//  Created by Matt Rose on 04/06/2026.
//

import SwiftUI

struct MovieCollectionCarousel: View {
    @EnvironmentObject var store: MovieStore
    let collection: CollectionDetails
    let currentMovieId: Int
    @Binding var selectedMovie: Movie?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "film.stack")
                        .foregroundStyle(AppTextColors.accent)
                        .font(.title3)
                    
                    Text(collection.name)
                        .font(.title2)
                        .bold()
                        .foregroundStyle(AppTextColors.primary)
                        .lineLimit(1)
                }
                
            }
            .padding(.horizontal, 75)
            
            // Horizontal Scroll of Collection Movies
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(collection.parts) { movie in
                        // Only show movies that have a poster and aren't the current movie
                        if movie.id != currentMovieId && movie.posterPath != nil {
                            CollectionMoviePoster(movie: movie)
                                .onTapGesture {
                                    selectedMovie = movie
                                }
                        }
                    }
                }
                .padding(.horizontal, 95)
            }
        }
        .padding(.vertical)
    }
}

struct CollectionMoviePoster: View {
    @EnvironmentObject var store: MovieStore
    let movie: Movie
    
    var isWatched: Bool {
        store.archive.contains(where: { $0.id == movie.id })
    }
    
    var isInWatchlist: Bool {
        store.watchlist.contains(where: { $0.id == movie.id })
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Poster Image
            AsyncImage(url: movie.posterURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "film")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 110, height: 165)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
            
            // Status Badge
            if isWatched {
                Circle()
                    .strokeBorder(.green, lineWidth: 2)
                    .background(Circle().fill(.black.opacity(0.4)))
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.green)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: -4, y: 4)
            } else if isInWatchlist {
                Circle()
                    .strokeBorder(.blue, lineWidth: 2)
                    .background(Circle().fill(.black.opacity(0.4)))
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: -4, y: 4)
            }
        }
        .frame(width: 110, height: 165)
    }
}

#Preview {
    let sampleCollection = CollectionDetails(
        id: 230,
        name: "The Godfather Collection",
        overview: "The saga of the Corleone family.",
        posterPath: "/9Baumh5cc9c1rbfTB7b1O6fY0b5.jpg",
        backdropPath: "/3WZTkpgscsNQu0c5YzqOTTmc71j.jpg",
        parts: [
            Movie(id: 238, title: "The Godfather", overview: "The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.", posterPath: "/3bhkrj58Vtu7enYsRolD1fZdja1.jpg", releaseDate: "1972-03-14", voteAverage: 8.7, mediaType: "movie"),
            Movie(id: 240, title: "The Godfather Part II", overview: "In the continuing saga of the Corleone crime family, a young Vito Corleone grows up in Sicily and in 1910s New York.", posterPath: "/hek3koDUyRQk7FIhPXsa6mT2Zc3.jpg", releaseDate: "1974-12-20", voteAverage: 8.6, mediaType: "movie"),
            Movie(id: 242, title: "The Godfather Part III", overview: "In the midst of trying to legitimize his business dealings in 1979 New York and Italy, aging mafia don Michael Corleone seeks to avow for his sins while taking a young protege under his wing.", posterPath: "/lm3pQ2QoQ16pextRsmnUbG2onES.jpg", releaseDate: "1990-12-25", voteAverage: 7.4, mediaType: "movie")
        ]
    )
    
    // Create a store with Godfather Part III in the archive (watched)
    let previewStore = MovieStore()
    previewStore.archive = [
        Movie(id: 242, title: "The Godfather Part III", overview: "In the midst of trying to legitimize his business dealings in 1979 New York and Italy, aging mafia don Michael Corleone seeks to avow for his sins while taking a young protege under his wing.", posterPath: "/lm3pQ2QoQ16pextRsmnUbG2onES.jpg", releaseDate: "1990-12-25", voteAverage: 7.4, mediaType: "movie")
    ]
    
    return MovieCollectionCarousel(collection: sampleCollection, currentMovieId: 238, selectedMovie: .constant(nil))
        .environmentObject(previewStore)
        .background(AppGradient.background)
}
