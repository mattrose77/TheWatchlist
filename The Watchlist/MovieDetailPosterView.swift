//
//  MovieDetailPosterView.swift
//  The Watchlist
//
//  Created by Matt Rose on 03/06/2026.
//

import SwiftUI

struct MovieDetailPosterView: View {
    let movie: Movie
    let height: CGFloat
    
    @State private var loader: ImageLoader?
    
    var body: some View {
        Group {
            if let loader = loader, let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            } else if let loader = loader, loader.hasError {
                // Failed to load - show fallback with movie info
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: height)
                    .overlay {
                        VStack(spacing: 16) {
                            Image(systemName: "film")
                                .font(.system(size: 60))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Text(movie.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 40)
                            
                            Text("Poster unavailable")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            } else {
                // Loading state
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: height)
                    .overlay {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("Loading poster...")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            loader?.cancel()
        }
    }
    
    private func loadImage() {
        guard let url = movie.posterURL else {
            // No poster URL available
            loader = ImageLoader(url: URL(string: "about:blank")!)
            loader?.hasError = true
            return
        }
        
        let newLoader = ImageLoader(url: url)
        loader = newLoader
        newLoader.load()
    }
}
