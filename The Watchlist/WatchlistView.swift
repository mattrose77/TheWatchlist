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
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                AppGradient.background
                    .ignoresSafeArea()
                
                ScrollView {
                if store.watchlist.isEmpty {
                    ContentUnavailableView {
                        Label("No Movies Yet", systemImage: "popcorn")
                            .foregroundStyle(AppTextColors.primary)
                    } description: {
                        Text("Browse movies and add them to your watchlist")
                            .foregroundStyle(AppTextColors.secondary)
                    }
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.watchlist) { movie in
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
            .navigationTitle("Watchlist")
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
