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
    
    let movie: Movie
    
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
                        AsyncImage(url: movie.posterURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                            case .empty:
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 500)
                                    .overlay {
                                        ProgressView()
                                    }
                            case .failure:
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 500)
                                    .overlay {
                                        Image(systemName: "film")
                                            .font(.system(size: 60))
                                            .foregroundStyle(.gray)
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
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
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(AppTextColors.rating)
                                Text(String(format: "%.1f", movie.voteAverage))
                                    .bold()
                                    .foregroundStyle(AppTextColors.primary)
                            }
                            
                            Text("•")
                                .foregroundStyle(AppTextColors.tertiary)
                            
                            Text(movie.year)
                                .foregroundStyle(AppTextColors.secondary)
                        }
                        .font(.title3)
                        
                        Text(movie.overview)
                            .font(.body)
                            .foregroundStyle(AppTextColors.secondary)
                            .multilineTextAlignment(.leading)
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
                                    .background(.blue.gradient)
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
                                store.markAsWatched(movie)
                                dismiss()
                            } label: {
                                Label("Mark as Watched", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.green.gradient)
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
            .task {
                await loadTrailer()
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
}

