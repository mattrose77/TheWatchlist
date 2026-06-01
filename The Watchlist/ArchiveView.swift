//
//  ArchiveView.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import SwiftUI

struct ArchiveView: View {
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
                if store.archive.isEmpty {
                    ContentUnavailableView {
                        Label("No Watched Movies", systemImage: "checkmark.circle")
                            .foregroundStyle(AppTextColors.primary)
                    } description: {
                        Text("Movies you mark as watched will appear here")
                            .foregroundStyle(AppTextColors.secondary)
                    }
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.archive) { movie in
                            Button {
                                selectedMovie = movie
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    MoviePosterView(movie: movie, width: 110)
                                    
                                    Circle()
                                        .fill(.green.gradient)
                                        .frame(width: 24, height: 24)
                                        .overlay {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10))
                                                .bold()
                                                .foregroundStyle(.white)
                                        }
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        .offset(x: 6, y: -6)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            }
            .navigationTitle("Archive")
            .sheet(item: $selectedMovie) { movie in
                MovieDetailView(movie: movie, isInWatchlist: false)
                    .environmentObject(store)
            }
        }
    }
}

#Preview {
    ArchiveView()
        .environmentObject(MovieStore())
}
