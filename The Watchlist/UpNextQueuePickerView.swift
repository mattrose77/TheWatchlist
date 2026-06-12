//
//  UpNextQueuePickerView.swift
//  The Watchlist
//
//  Created by Matt Rose on 11/06/2026.
//

import SwiftUI

struct UpNextQueuePickerView: View {
    @EnvironmentObject var store: MovieStore
    @Environment(\.dismiss) var dismiss
    
    let contentType: ContentType
    let selectedSlotIndex: Int
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // Get watchlist items excluding those already in the queue
    var availableMovies: [Movie] {
        let queueIDs = Set(store.getUpNextQueue(for: contentType))
        return store.watchlist
            .filter { movie in
                // Filter by content type
                let matchesType = contentType == .movies ? movie.isMovie : movie.isTV
                // Exclude items already in queue
                let notInQueue = !queueIDs.contains(movie.id)
                return matchesType && notInQueue
            }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                AppGradient.background
                    .ignoresSafeArea()
                
                if availableMovies.isEmpty {
                    // Empty state
                    ContentUnavailableView {
                        Label("No Available \(contentType.rawValue)", systemImage: "film.stack")
                            .foregroundStyle(AppTextColors.primary)
                    } description: {
                        Text("All items from your watchlist are already in the queue")
                            .foregroundStyle(AppTextColors.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(availableMovies) { movie in
                                Button {
                                    // Add to queue at the first empty slot
                                    store.addToUpNextQueue(movieID: movie.id, for: contentType)
                                    
                                    // Haptic feedback
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                    // Dismiss the sheet
                                    dismiss()
                                } label: {
                                    MoviePosterView(movie: movie, width: 100)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Add to Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTextColors.primary)
                }
            }
        }
    }
}

#Preview {
    UpNextQueuePickerView(contentType: .movies, selectedSlotIndex: 0)
        .environmentObject(MovieStore())
}
