//
//  MovieDetailView.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import SwiftUI

struct MovieDetailView: View {
    @EnvironmentObject var store: MovieStore
    @Environment(\.dismiss) var dismiss
    
    let movie: Movie
    let isInWatchlist: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                AppGradient.background
                    .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 24) {
                    // Poster
                    AsyncImage(url: movie.posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                        case .empty:
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 500)
                                .overlay {
                                    ProgressView()
                                }
                        case .failure:
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 500)
                                .overlay {
                                    Image(systemName: "film")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.gray)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: 300)
                    
                    // Movie Info
                    VStack(spacing: 16) {
                        Text(movie.title)
                            .font(.title)
                            .bold()
                            .foregroundStyle(AppTextColors.primary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 20) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(AppTextColors.rating)
                                Text(String(format: "%.1f", movie.voteAverage))
                                    .bold()
                                    .foregroundStyle(AppTextColors.primary)
                            }
                            
                            Text("•")
                                .foregroundStyle(AppTextColors.tertiary)
                            
                            Text(movie.year)
                                .foregroundStyle(AppTextColors.secondary)
                        }
                        .font(.title3)
                        
                        Text(movie.overview)
                            .font(.body)
                            .foregroundStyle(AppTextColors.secondary)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
                    }
                    
                    // Action Buttons
                    if isInWatchlist {
                        VStack(spacing: 12) {
                            Button {
                                store.markAsWatched(movie)
                                dismiss()
                            } label: {
                                Label("Mark as Watched", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.green.gradient)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            Button(role: .destructive) {
                                store.removeFromWatchlist(movie)
                                dismiss()
                            } label: {
                                Label("Remove from Watchlist", systemImage: "trash")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundStyle(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        Button(role: .destructive) {
                            store.removeFromArchive(movie)
                            dismiss()
                        } label: {
                            Label("Remove from Archive", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#Preview("Watchlist Movie") {
    MovieDetailView(
        movie: Movie(
            id: 1,
            title: "The Shawshank Redemption",
            overview: "Framed in the 1940s for the double murder of his wife and her lover, upstanding banker Andy Dufresne begins a new life at the Shawshank prison, where he puts his accounting skills to work for an amoral warden. During his long stretch in prison, Dufresne comes to be admired by the other inmates -- including an older prisoner named Red -- for his integrity and unquenchable sense of hope.",
            posterPath: "/9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg",
            releaseDate: "1994-09-23",
            voteAverage: 8.7
        ),
        isInWatchlist: true
    )
    .environmentObject(MovieStore())
}

#Preview("Archive Movie") {
    MovieDetailView(
        movie: Movie(
            id: 2,
            title: "The Dark Knight",
            overview: "Batman raises the stakes in his war on crime. With the help of Lt. Jim Gordon and District Attorney Harvey Dent, Batman sets out to dismantle the remaining criminal organizations that plague the streets. The partnership proves to be effective, but they soon find themselves prey to a reign of chaos unleashed by a rising criminal mastermind known to the terrified citizens of Gotham as the Joker.",
            posterPath: "/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
            releaseDate: "2008-07-18",
            voteAverage: 9.0
        ),
        isInWatchlist: false
    )
    .environmentObject(MovieStore())
}

