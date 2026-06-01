//
//  MoviePosterView.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import SwiftUI

struct MoviePosterView: View {
    let movie: Movie
    let width: CGFloat
    
    var body: some View {
        AsyncImage(url: movie.posterURL) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: width, height: width * 1.5)
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: width * 1.5)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
            case .failure:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: width, height: width * 1.5)
                    .overlay {
                        Image(systemName: "film")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
            @unknown default:
                EmptyView()
            }
        }
    }
}
