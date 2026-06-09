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
    @State private var selectedContentType: ContentType = .movies
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var filteredArchive: [Movie] {
        if selectedContentType == .movies {
            return store.archive.filter { $0.isMovie }
        } else {
            return store.archive.filter { $0.isTV }
        }
    }
    
    // Statistics computed properties
    var totalCount: Int {
        filteredArchive.count
    }
    
    var averageRating: Double {
        let ratedItems = filteredArchive.compactMap { store.getRating(for: $0.id) }
        guard !ratedItems.isEmpty else { return 0 }
        return ratedItems.reduce(0, +) / Double(ratedItems.count)
    }
    
    var fiveStarCount: Int {
        filteredArchive.filter { movie in
            if let rating = store.getRating(for: movie.id) {
                return rating == 5.0
            }
            return false
        }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                AppGradient.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Statistics boxes
                    if !filteredArchive.isEmpty {
                        HStack(spacing: 12) {
                            // Total count
                            StatBoxView(
                                value: "\(totalCount)",
                                label: selectedContentType == .movies ? "Movies" : "TV Shows"
                            )
                            
                            // Average rating
                            StatBoxView(
                                value: String(format: "%.1f", averageRating),
                                label: "Average Rating"
                            )
                            
                            // Five star count
                            StatBoxView(
                                value: "\(fiveStarCount)",
                                label: "5 Stars"
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, -10)
                        .padding(.bottom, 16)
                    }
                    
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
                        if filteredArchive.isEmpty {
                            ContentUnavailableView {
                                Label(selectedContentType == .movies ? "No Watched Movies" : "No Watched TV Shows", 
                                      systemImage: "checkmark.circle")
                                    .foregroundStyle(AppTextColors.primary)
                            } description: {
                                Text("\(selectedContentType.rawValue) you mark as watched will appear here")
                                    .foregroundStyle(AppTextColors.secondary)
                            }
                            .padding(.top, 100)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(filteredArchive) { movie in
                                    Button {
                                        selectedMovie = movie
                                    } label: {
                                        ZStack(alignment: .topTrailing) {
                                            MoviePosterView(movie: movie, width: 110)
                                            
                                            // Always show rating badge with star
                                            if let rating = store.getRating(for: movie.id) {
                                                // User has rated this item - show the rating
                                                HStack(spacing: 2) {
                                                    Image(systemName: "star.fill")
                                                        .font(.system(size: 9))
                                                        .foregroundStyle(.yellow.opacity(0.8))
                                                    Text(String(format: "%.1f", rating))
                                                        .font(.system(size: 11, weight: .bold))
                                                        .foregroundStyle(.white)
                                                }
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.black.opacity(0.7))
                                                )
                                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                                .offset(x: 6, y: -6)
                                            } else {
                                                // No rating yet - show empty star to indicate they can rate
                                                Circle()
                                                    .fill(Color.black.opacity(0.7))
                                                    .frame(width: 28, height: 28)
                                                    .overlay {
                                                        Image(systemName: "star")
                                                            .font(.system(size: 12))
                                                            .foregroundStyle(.yellow.opacity(0.8))
                                                    }
                                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                                    .offset(x: 6, y: -6)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .id("\(movie.id)-\(store.getRating(for: movie.id) ?? 0)") // Force refresh when rating changes
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedMovie) { movie in
                MovieDetailView(movie: movie, isInWatchlist: false)
                    .environmentObject(store)
            }
        }
    }
}

struct StatBoxView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(AppTextColors.primary)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTextColors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview {
    ArchiveView()
        .environmentObject(MovieStore())
}
