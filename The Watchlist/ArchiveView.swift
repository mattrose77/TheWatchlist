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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                AppGradient.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content Type Picker (Movies / TV Shows)
                    Picker("Content Type", selection: $selectedContentType) {
                        ForEach(ContentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
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
