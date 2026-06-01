//
//  SearchView.swift
//  The Watchlist
//
//  Created by Matt Rose on 22/05/2026.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var store: MovieStore
    @Environment(\.dismiss) var dismiss
    @State private var searchQuery = ""
    @State private var searchResults: [Movie] = []
    @State private var isSearching = false
    @State private var selectedMovie: Movie?
    @State private var searchContentType: ContentType = .movies
    
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
                
                VStack(spacing: 0) {
                    // Search content type picker
                    Picker("Search Type", selection: $searchContentType) {
                        ForEach(ContentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .onChange(of: searchContentType) { _, _ in
                        // Clear results when switching type
                        if !searchQuery.isEmpty {
                            performSearch()
                        }
                    }
                    
                    // Search results
                    ScrollView {
                        if isSearching {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 100)
                        } else if searchQuery.isEmpty {
                            ContentUnavailableView {
                                Label("Search for Movies & TV Shows", systemImage: "magnifyingglass")
                                    .foregroundStyle(AppTextColors.primary)
                            } description: {
                                Text("Enter a title to search")
                                    .foregroundStyle(AppTextColors.secondary)
                            }
                            .padding(.top, 100)
                        } else if searchResults.isEmpty {
                            ContentUnavailableView {
                                Label("No Results", systemImage: "film.slash")
                                    .foregroundStyle(AppTextColors.primary)
                            } description: {
                                Text("Try searching for something else")
                                    .foregroundStyle(AppTextColors.secondary)
                            }
                            .padding(.top, 100)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(searchResults) { movie in
                                    Button {
                                        selectedMovie = movie
                                    } label: {
                                        MoviePosterView(movie: movie, width: 110)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.black)
                }
            }
            .searchable(text: $searchQuery, prompt: "Search for movies or TV shows")
            .onChange(of: searchQuery) { _, newValue in
                if newValue.isEmpty {
                    searchResults = []
                } else {
                    performSearch()
                }
            }
            .sheet(item: $selectedMovie) { movie in
                BrowseMovieDetailView(movie: movie)
                    .environmentObject(store)
            }
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                searchResults = try await store.movieService.searchContent(
                    query: searchQuery,
                    type: searchContentType
                )
            } catch {
                print("Search error: \(error)")
                searchResults = []
            }
            isSearching = false
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(MovieStore())
}
