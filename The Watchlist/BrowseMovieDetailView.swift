//
//  BrowseMovieDetailView.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import SwiftUI

struct BrowseMovieDetailView: View {
    @EnvironmentObject var store: MovieStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State private var trailer: Video?
    @State private var isLoadingTrailer = false
    @State private var showRatingSheet = false
    @State private var currentRating: Double = 0.0
    @State private var collection: CollectionDetails?
    @State private var isLoadingCollection = false
    @State private var selectedCollectionMovie: Movie?
    @State private var movieWithDetails: Movie?
    @State private var watchProviders: [WatchProvider] = []
    @State private var isLoadingWatchProviders = false
    
    let movie: Movie
    
    var displayMovie: Movie {
        movieWithDetails ?? movie
    }
    
    var isInWatchlist: Bool {
        store.watchlist.contains(where: { $0.id == movie.id })
    }
    
    var isInArchive: Bool {
        store.archive.contains(where: { $0.id == movie.id })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                AppGradient.background
                    .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 24) {
                    // Poster with Play Button Overlay
                    ZStack(alignment: .center) {
                        MovieDetailPosterView(movie: movie, height: 500)
                        
                        // Play Button Overlay
                        if let trailer = trailer {
                            Button {
                                if let youtubeURL = trailer.youtubeURL {
                                    openURL(youtubeURL)
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.black.opacity(0.7))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.white)
                                        .offset(x: 3)
                                }
                            }
                            .shadow(color: .black.opacity(0.3), radius: 10)
                        } else if isLoadingTrailer {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.7))
                                    .frame(width: 80, height: 80)
                                
                                ProgressView()
                                    .tint(.white)
                            }
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
                            if movie.voteAverage > 0.0 {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(AppTextColors.rating)
                                    Text(String(format: "%.1f", movie.voteAverage))
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
                            
                            Text(movie.year)
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
                        
                        Text(movie.overview)
                            .font(.body)
                            .foregroundStyle(AppTextColors.secondary)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
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
                            .padding(.horizontal)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if isInWatchlist {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Added to Watchlist")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
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
                            .disabled(isInArchive)
                        }
                        
                        if isInArchive {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Already Watched")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
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
                            .disabled(isInWatchlist)
                        }
                    }
                    .padding(.horizontal)
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
                        store.markAsWatched(movie)
                        dismiss()
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .task {
                await loadTrailer()
                await loadTVShowDetails()
                await loadCollection()
                await loadWatchProviders()
            }
            .onAppear {
                currentRating = store.getRating(for: movie.id) ?? 0.0
            }
            .sheet(item: $selectedCollectionMovie) { collectionMovie in
                BrowseMovieDetailView(movie: collectionMovie)
                    .environmentObject(store)
            }
        }
    }
    
    private func loadTrailer() async {
        isLoadingTrailer = true
        defer { isLoadingTrailer = false }
        
        do {
            trailer = try await store.movieService.fetchTrailer(
                for: movie.id,
                contentType: store.selectedContentType
            )
        } catch {
            print("Error loading trailer: \(error)")
        }
    }
    
    private func loadTVShowDetails() async {
        // Only load TV show details for TV shows
        guard movie.isTV else { return }
        
        do {
            // Fetch the full TV show details to get number of seasons
            let tvShowDetails = try await store.movieService.fetchTVShowDetails(tvShowId: movie.id)
            movieWithDetails = tvShowDetails
        } catch {
            print("Error loading TV show details: \(error)")
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
            if let providerData = try await store.movieService.fetchWatchProviders(
                for: movie.id,
                contentType: store.selectedContentType
            ) {
                watchProviders = providerData.streamingProviders
            }
        } catch {
            print("Error loading watch providers: \(error)")
        }
    }
}

