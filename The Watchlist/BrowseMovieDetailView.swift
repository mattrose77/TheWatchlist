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
            // Check if we have a backdrop
            if displayMovie.backdropURL != nil {
                // New layout with backdrop
                backdropHeaderView
            } else {
                // Original layout without backdrop
                ZStack {
                    // Background gradient
                    AppGradient.background
                        .ignoresSafeArea()
                    
                    ScrollView {
                        originalLayoutView
                    }
                }
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
                    Task {
                        if rating > 0 {
                            store.setRating(rating, for: movie)
                        }
                        await store.markAsWatched(movie)
                        dismiss()
                    }
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
    
    // MARK: - Backdrop Header View (New Layout)
    private var backdropHeaderView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Backdrop image with gradient overlay
                AsyncImage(url: displayMovie.backdropURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black, location: 0.0),
                                    .init(color: .black, location: 0.5),
                                    .init(color: .clear, location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                }
                .frame(maxWidth: .infinity)
                
                // Poster with Play Button Overlay and Title Section
                HStack(alignment: .top, spacing: 12) {
                    // Poster - overlapping the backdrop
                    ZStack(alignment: .center) {
                        MovieDetailPosterView(movie: displayMovie, height: 160)
                        
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
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white)
                                        .offset(x: 2)
                                }
                            }
                            .shadow(color: .black.opacity(0.3), radius: 10)
                        } else if isLoadingTrailer {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.7))
                                    .frame(width: 50, height: 50)
                                
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .frame(width: 107)
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    .padding(.leading, 60)
                    .offset(y: -30) // Overlap the backdrop
                    
                    // Title and Metadata - on the gradient background
                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayMovie.title)
                            .font(displayMovie.title.count > 25 ? .body : .title3)
                            .bold()
                            .foregroundStyle(AppTextColors.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.trailing, 40)
                        
                        // Metadata
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                if displayMovie.voteAverage > 0.0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(AppTextColors.rating)
                                            .font(.caption)
                                        Text(String(format: "%.1f", displayMovie.voteAverage))
                                            .bold()
                                            .foregroundStyle(AppTextColors.primary)
                                    }
                                }
                            }
                            .font(.subheadline)
                            
                            // Release date
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(AppTextColors.accent)
                                    .font(.caption)
                                Text(displayMovie.year)
                                    .foregroundStyle(AppTextColors.secondary)
                            }
                            .font(.subheadline)
                            
                            // Runtime for movies / Seasons for TV
                            if displayMovie.isMovie, let formattedRuntime = displayMovie.formattedRuntime {
                                HStack(spacing: 3) {
                                    Image(systemName: "clock")
                                        .foregroundStyle(AppTextColors.accent)
                                        .font(.caption)
                                    Text(formattedRuntime)
                                        .foregroundStyle(AppTextColors.secondary)
                                }
                                .font(.subheadline)
                            }
                            
                            if displayMovie.isTV, let seasons = displayMovie.numberOfSeasons {
                                HStack(spacing: 3) {
                                    Image(systemName: "tv")
                                        .foregroundStyle(AppTextColors.accent)
                                        .font(.caption)
                                    Text("\(seasons) \(seasons == 1 ? "Season" : "Seasons")")
                                        .foregroundStyle(AppTextColors.secondary)
                                }
                                .font(.subheadline)
                            }
                            
                            // Director
                            if let director = displayMovie.director {
                                HStack(spacing: 3) {
                                    Image(systemName: "video")
                                        .foregroundStyle(AppTextColors.accent)
                                        .font(.caption)
                                    Text(director)
                                        .foregroundStyle(AppTextColors.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: displayMovie.title.count > 25 ? -12 : 0)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                    .frame(height: 5)
                
                // Rest of the content
                VStack(spacing: 20) {
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
                    
                    // Overview
                    Text(displayMovie.overview)
                        .font(.body)
                        .foregroundStyle(AppTextColors.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 85)
                    
                    Spacer()
                        .frame(height: 10)
                    
                    // Collection Section
                    if let collection = collection {
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal, 20)
                        
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
                            .padding(.horizontal, 70)
                    }
                    
                    // Action Buttons
                    actionButtons
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppGradient.background)
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Original Layout View (No Backdrop)
    private var originalLayoutView: some View {
        VStack(spacing: 24) {
            // Poster with Play Button Overlay
            ZStack(alignment: .center) {
                MovieDetailPosterView(movie: displayMovie, height: 500)
                
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
                Text(displayMovie.title)
                    .font(displayMovie.title.count > 25 ? .title2 : .title)
                    .bold()
                    .foregroundStyle(AppTextColors.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                
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
                    
                    // Show runtime for movies
                    if displayMovie.isMovie, let formattedRuntime = displayMovie.formattedRuntime {
                        Text("•")
                            .foregroundStyle(AppTextColors.tertiary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundStyle(AppTextColors.accent)
                            Text(formattedRuntime)
                                .foregroundStyle(AppTextColors.secondary)
                        }
                    }
                    
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
            }
            
            // Action Buttons
            actionButtons
        }
        .padding()
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
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
        .frame(maxWidth: 300)
    }
    
    private func loadTrailer() async {
        isLoadingTrailer = true
        defer { isLoadingTrailer = false }
        
        do {
            let contentType: ContentType = movie.isTV ? .tv : .movies
            trailer = try await store.movieService.fetchTrailer(
                for: movie.id,
                contentType: contentType
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
            
            // Store the runtime and director if available and we don't already have full details
            if movieWithDetails == nil {
                var updatedMovie = movie
                if let runtime = movieDetails.runtime {
                    updatedMovie.runtime = runtime
                }
                if let director = movieDetails.director {
                    updatedMovie.director = director
                }
                movieWithDetails = updatedMovie
            }
            
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
}

