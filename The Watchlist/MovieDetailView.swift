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
    
    @State private var showRatingSheet = false
    @State private var currentRating: Double = 0.0
    @State private var watchProviders: [WatchProvider] = []
    @State private var isLoadingWatchProviders = false
    @State private var collection: CollectionDetails?
    @State private var isLoadingCollection = false
    @State private var selectedCollectionMovie: Movie?
    @State private var isDescriptionExpanded = false
    @State private var fullMovieDetails: Movie?
    
    // Use full details if available, otherwise fall back to the passed movie
    private var displayMovie: Movie {
        fullMovieDetails ?? movie
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                AppGradient.background
                    .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 24) {
                    // Poster
                    MovieDetailPosterView(movie: displayMovie, height: 500)
                        .frame(maxWidth: 300)
                    
                    // Movie Info
                    VStack(spacing: 16) {
                        Text(displayMovie.title)
                            .font(.title)
                            .bold()
                            .foregroundStyle(AppTextColors.primary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 20) {
                            if displayMovie.voteAverage > 0.0 {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(AppTextColors.rating)
                                    Text(String(format: "%.1f", displayMovie.voteAverage))
                                        .bold()
                                        .foregroundStyle(AppTextColors.primary)
                                }
                            } else {
                                Text("Not Released")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTextColors.secondary)
                            }
                            
                            Text("•")
                                .foregroundStyle(AppTextColors.tertiary)
                            
                            Text(displayMovie.year)
                                .foregroundStyle(AppTextColors.secondary)
                            
                            // Show number of seasons for TV shows
                            if displayMovie.isTV, let seasons = displayMovie.numberOfSeasons {
                                Text("•")
                                    .foregroundStyle(AppTextColors.tertiary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "tv")
                                        .foregroundStyle(AppTextColors.accent)
                                    Text("\(seasons) \(seasons == 1 ? "Season" : "Seasons")")
                                        .foregroundStyle(AppTextColors.secondary)
                                }
                            }
                        }
                        .font(.title3)
                        
                        // User Rating Display
                        if let userRating = store.getRating(for: movie.id) {
                            VStack(spacing: 8) {
                                Text("Your Rating")
                                    .font(.caption)
                                    .foregroundStyle(AppTextColors.secondary)
                                
                                HStack(spacing: 4) {
                                    StarRatingView(rating: .constant(userRating), starSize: 20, interactive: false)
                                    Text(String(format: "%.1f", userRating))
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundStyle(AppTextColors.accent)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        
                        Text(displayMovie.overview)
                            .font(.body)
                            .foregroundStyle(AppTextColors.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(isDescriptionExpanded ? nil : 3)
                            .padding(.horizontal)
                        
                        // Show More / Show Less Button
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isDescriptionExpanded.toggle()
                            }
                        } label: {
                            Text(isDescriptionExpanded ? "Show Less" : "Show More")
                                .font(.subheadline)
                                .foregroundStyle(AppTextColors.secondary)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Collection Section
                    if let collection = collection {
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal)
                        
                        MovieCollectionCarousel(
                            collection: collection,
                            currentMovieId: movie.id,
                            selectedMovie: $selectedCollectionMovie
                        )
                    } else if isLoadingCollection {
                        VStack {
                            ProgressView()
                                .tint(AppTextColors.accent)
                            Text("Loading collection...")
                                .font(.caption)
                                .foregroundStyle(AppTextColors.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    
                    // Where to Watch Section
                    if !isLoadingWatchProviders {
                        WatchProvidersView(providers: watchProviders)
                    }
                    
                    // Action Buttons
                    if isInWatchlist {
                        // Movie is in watchlist - show watchlist actions
                        VStack(spacing: 12) {
                            Button {
                                showRatingSheet = true
                            } label: {
                                Label("Mark as Watched", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppGradient.green)
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
                                    .background(Color.white.opacity(0.1))
                                    .foregroundStyle(.red.opacity(0.9))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(.horizontal)
                    } else if store.archive.contains(where: { $0.id == movie.id }) {
                        // Movie is in archive - show archive actions
                        VStack(spacing: 12) {
                            // Add or Edit Rating Button
                            Button {
                                showRatingSheet = true
                            } label: {
                                if store.getRating(for: movie.id) != nil {
                                    Label("Edit Rating", systemImage: "star.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(AppGradient.gold.opacity(0.6))
                                        )
                                        .foregroundStyle(AppTextColors.primary)
                                } else {
                                    Label("Add Rating", systemImage: "star")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(AppGradient.gold.opacity(0.6))
                                        )
                                        .foregroundStyle(AppTextColors.primary)
                                }
                            }
                            
                            Button(role: .destructive) {
                                store.removeFromArchive(movie)
                                // Also remove rating
                                store.userRatings.removeValue(forKey: movie.id)
                                dismiss()
                            } label: {
                                Label("Remove from Archive", systemImage: "trash")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .foregroundStyle(.red.opacity(0.9))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Movie is neither in watchlist nor archive - show both options
                        VStack(spacing: 12) {
                            Button {
                                store.addToWatchlist(movie)
                                dismiss()
                            } label: {
                                Label("Add to Watchlist", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppGradient.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            Button {
                                showRatingSheet = true
                            } label: {
                                Label("Mark as Watched", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppGradient.green)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
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
            .sheet(isPresented: $showRatingSheet) {
                RatingSheet(
                    rating: $currentRating,
                    movie: movie,
                    onSubmit: { rating in
                        if rating > 0 {
                            store.setRating(rating, for: movie)
                        }
                        
                        let isInArchive = store.archive.contains(where: { $0.id == movie.id })
                        
                        if isInWatchlist {
                            // Movie is in watchlist - move it to archive
                            store.markAsWatched(movie)
                            dismiss()
                        } else if !isInArchive {
                            // Movie is not in watchlist and not in archive - add directly to archive
                            store.addToArchive(movie)
                            dismiss()
                        }
                        // If it's already in archive, just update the rating (no dismiss)
                        // The sheet will dismiss itself, but we don't close the detail view
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                currentRating = store.getRating(for: movie.id) ?? 0.0
            }
            .task {
                await loadWatchProviders()
                await loadCollection()
                await loadTVShowDetails()
            }
            .sheet(item: $selectedCollectionMovie) { collectionMovie in
                // Check both watchlist and archive to determine the correct state
                let isInWatchlist = store.watchlist.contains(where: { $0.id == collectionMovie.id })
                
                MovieDetailView(movie: collectionMovie, isInWatchlist: isInWatchlist)
                    .environmentObject(store)
            }
        }
    }
    
    private func loadCollection() async {
        // Only load collections for movies, not TV shows
        guard movie.isMovie else { return }
        
        isLoadingCollection = true
        defer { isLoadingCollection = false }
        
        do {
            // First, fetch movie details to check if it belongs to a collection
            let movieDetails = try await store.movieService.fetchMovieDetails(movieId: movie.id)
            
            if let collectionInfo = movieDetails.belongsToCollection {
                // Fetch the full collection details
                let fetchedCollection = try await store.movieService.fetchCollection(collectionId: collectionInfo.id)
                
                // Only show collection if it has more than one movie
                if fetchedCollection.parts.count > 1 {
                    collection = fetchedCollection
                }
            }
        } catch {
            print("Error loading collection: \(error)")
        }
    }
    
    private func loadWatchProviders() async {
        isLoadingWatchProviders = true
        defer { isLoadingWatchProviders = false }
        
        do {
            let contentType: ContentType = movie.isTV ? .tv : .movies
            if let providerData = try await store.movieService.fetchWatchProviders(
                for: movie.id,
                contentType: contentType
            ) {
                watchProviders = providerData.streamingProviders
            }
        } catch {
            print("Error loading watch providers: \(error)")
        }
    }
    
    private func loadTVShowDetails() async {
        // Only fetch details for TV shows that don't already have season info
        guard movie.isTV, movie.numberOfSeasons == nil else { return }
        
        do {
            let tvShowDetails = try await store.movieService.fetchTVShowDetails(tvShowId: movie.id)
            fullMovieDetails = tvShowDetails
        } catch {
            print("Error loading TV show details: \(error)")
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

