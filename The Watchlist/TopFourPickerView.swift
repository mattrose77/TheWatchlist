//
//  TopFourPickerView.swift
//  The Watchlist
//
//  Created by Matt Rose on 11/06/2026.
//

import SwiftUI

struct TopFourPickerView: View {
    @EnvironmentObject var store: MovieStore
    @Environment(\.dismiss) var dismiss
    
    let contentType: ContentType
    let selectedSlotIndex: Int
    
    @State private var searchText = ""
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private var watchedItems: [Movie] {
        store.archive.filter { movie in
            contentType == .movies ? movie.isMovie : movie.isTV
        }.sorted { movie1, movie2 in
            // Sort by rating, then by title
            let rating1 = store.getRating(for: movie1.id) ?? 0
            let rating2 = store.getRating(for: movie2.id) ?? 0
            if rating1 != rating2 {
                return rating1 > rating2
            }
            return movie1.title < movie2.title
        }
    }
    
    private var filteredItems: [Movie] {
        if searchText.isEmpty {
            return watchedItems
        } else {
            return watchedItems.filter { movie in
                movie.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var topFourIDs: [Int] {
        store.getTopFour(for: contentType)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppGradient.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.5))
                        
                        TextField("Search watched items", text: $searchText)
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                    )
                    .padding()
                    
                    if filteredItems.isEmpty {
                        ContentUnavailableView {
                            Label(searchText.isEmpty ? "No Watched Items" : "No Results",
                                  systemImage: "film")
                                .foregroundStyle(AppTextColors.primary)
                        } description: {
                            Text(searchText.isEmpty ? 
                                 "Watch some \(contentType.rawValue.lowercased()) first" :
                                 "Try a different search term")
                                .foregroundStyle(AppTextColors.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(filteredItems) { movie in
                                    TopFourPickerPoster(
                                        movie: movie,
                                        isSelected: topFourIDs.contains(movie.id),
                                        rating: store.getRating(for: movie.id),
                                        onTap: {
                                            toggleSelection(for: movie)
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Choose Favourite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func toggleSelection(for movie: Movie) {
        var current = store.getTopFour(for: contentType)
        
        if let index = current.firstIndex(of: movie.id) {
            // Already selected - remove it
            current.remove(at: index)
            store.setTopFour(current, for: contentType)
            mediumHaptic()
        } else if current.count < 4 {
            // Add to the list
            current.append(movie.id)
            store.setTopFour(current, for: contentType)
            
            // Check if this is slot #1 (first item) for stronger haptic
            if current.count == 1 {
                strongHaptic()
            } else {
                lightHaptic()
            }
        }
    }
    
    private func lightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func mediumHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func strongHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}

struct TopFourPickerPoster: View {
    let movie: Movie
    let isSelected: Bool
    let rating: Double?
    let onTap: () -> Void
    
    @State private var loader: ImageLoader?
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Poster
                Group {
                    if let loader = loader, let image = loader.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 120)
                            .overlay {
                                if let loader = loader, loader.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "film")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                .onAppear {
                    loadImage()
                }
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(hex: "F5C518"))
                        .background(
                            Circle()
                                .fill(.black.opacity(0.3))
                                .frame(width: 28, height: 28)
                        )
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func loadImage() {
        guard let url = movie.posterURL else {
            loader = ImageLoader(url: URL(string: "about:blank")!)
            loader?.hasError = true
            return
        }
        
        let newLoader = ImageLoader(url: url)
        loader = newLoader
        newLoader.load()
    }
}

#Preview {
    TopFourPickerView(contentType: .movies, selectedSlotIndex: 0)
        .environmentObject(MovieStore())
}
