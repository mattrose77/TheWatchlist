//
//  WatchlistView.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import SwiftUI

struct WatchlistView: View {
    @EnvironmentObject var store: MovieStore
    @State private var selectedMovie: Movie?
    @State private var selectedContentType: ContentType = .movies
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var filteredWatchlist: [Movie] {
        // Get queue IDs for the selected content type
        let queueIDs = Set(store.getUpNextQueue(for: selectedContentType))
        
        if selectedContentType == .movies {
            return store.watchlist.filter { $0.isMovie && !queueIDs.contains($0.id) }
        } else {
            return store.watchlist.filter { $0.isTV && !queueIDs.contains($0.id) }
        }
    }
    
    var hasQueueItems: Bool {
        !store.getUpNextQueue(for: selectedContentType).isEmpty
    }
    
    var hasWatchlistItems: Bool {
        if selectedContentType == .movies {
            return store.watchlist.contains { $0.isMovie }
        } else {
            return store.watchlist.contains { $0.isTV }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                AppGradient.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header with Title Centered
                    Text("Watchlist")
                        .font(.headline)
                        .foregroundStyle(Color(hex: "0D1A22"))
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    
                    // Content Type Picker (Movies / TV Shows)
                    Picker("Content Type", selection: $selectedContentType) {
                        ForEach(ContentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Up Next Queue Card - only show if watchlist has items
                            if hasWatchlistItems {
                                UpNextQueueCard(contentType: selectedContentType)
                                    .environmentObject(store)
                            }
                            
                            // Watchlist Grid
                            if filteredWatchlist.isEmpty {
                                if hasQueueItems {
                                    // All items are in the queue
                                    ContentUnavailableView {
                                        Label("All in Queue", 
                                              systemImage: "list.bullet")
                                            .foregroundStyle(AppTextColors.primary)
                                    } description: {
                                        Text("All your \(selectedContentType.rawValue.lowercased()) are in the Up Next queue")
                                            .foregroundStyle(AppTextColors.secondary)
                                    }
                                    .padding(.top, 100)
                                } else {
                                    // No items at all
                                    ContentUnavailableView {
                                        Label(selectedContentType == .movies ? "No Movies Yet" : "No TV Shows Yet", 
                                              systemImage: "popcorn")
                                            .foregroundStyle(AppTextColors.primary)
                                    } description: {
                                        Text("Browse \(selectedContentType.rawValue.lowercased()) and add them to your watchlist")
                                            .foregroundStyle(AppTextColors.secondary)
                                    }
                                    .padding(.top, 100)
                                }
                            } else {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(filteredWatchlist) { movie in
                                        Button {
                                            selectedMovie = movie
                                        } label: {
                                            MoviePosterView(movie: movie, width: 110)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .sheet(item: $selectedMovie) { movie in
                MovieDetailView(movie: movie, isInWatchlist: true)
                    .environmentObject(store)
            }
        }
    }
}

#Preview {
    WatchlistView()
        .environmentObject(MovieStore())
}
