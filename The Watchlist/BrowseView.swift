//
//  BrowseView.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var store: MovieStore
    @State private var selectedMovie: Movie?
    @State private var showingSearch = false
    
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
                // Content Type Picker (Movies / TV Shows) with Search Button
                HStack(spacing: 12) {
                    Picker("Content Type", selection: $store.selectedContentType) {
                        ForEach(ContentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundStyle(AppTextColors.primary)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 35)
                .padding(.bottom, 4)
                .onChange(of: store.selectedContentType) { oldValue, newValue in
                    Task {
                        // Always reset to Trending when switching content type
                        await store.loadMovies(for: .trending, contentType: newValue)
                    }
                }
                
                // Horizontal Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.availableCategories, id: \.self) { category in
                            CategoryChip(
                                title: category.rawValue,
                                isSelected: store.selectedCategory == category
                            ) {
                                Task {
                                    await store.loadMovies(for: category)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
                .background(Color.clear)
                
                // Movies Grid
                ScrollView {
                    if store.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if store.availableMovies.isEmpty {
                        ContentUnavailableView {
                            Label("No Content Available", systemImage: "film")
                                .foregroundStyle(AppTextColors.primary)
                        } description: {
                            Text("Unable to load content. Please try again later.")
                                .foregroundStyle(AppTextColors.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(store.availableMovies) { movie in
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
            .task {
                if store.availableMovies.isEmpty {
                    await store.loadMovies()
                }
            }
            .sheet(item: $selectedMovie) { movie in
                BrowseMovieDetailView(movie: movie)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
                    .environmentObject(store)
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.2))
                )
                .foregroundStyle(isSelected ? AppTextColors.primary : AppTextColors.secondary)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    BrowseView()
        .environmentObject(MovieStore())
}
