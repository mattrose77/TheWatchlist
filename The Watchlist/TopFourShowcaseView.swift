//
//  TopFourShowcaseView.swift
//  The Watchlist
//
//  Created by Matt Rose on 11/06/2026.
//

import SwiftUI

struct TopFourShowcaseView: View {
    @EnvironmentObject var store: MovieStore
    let contentType: ContentType
    @State private var showingPicker = false
    @State private var selectedSlotIndex: Int? = nil
    @State private var isEditMode = false
    @State private var hasAnimated = false
    @State private var selectedMovieForDetail: Movie? = nil
    
    private let goldColor = Color(hex: "F5C518")
    private let brandGradient = LinearGradient(
        colors: [
            Color(hex: "0A1628"),
            Color(hex: "0E3D3A"),
            Color(hex: "1A6B5A")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var topFourMovies: [Movie?] {
        let ids = store.getTopFour(for: contentType)
        var movies: [Movie?] = []
        for id in ids {
            movies.append(store.archive.first { $0.id == id })
        }
        // Pad with nils to always have 4 slots
        while movies.count < 4 {
            movies.append(nil)
        }
        return movies
    }
    
    var hasAnyPicks: Bool {
        !store.getTopFour(for: contentType).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium card
            VStack(spacing: 15) {
                // Header
                HStack {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 12) {
                            // Left decorative lines
                            HStack(spacing: 3) {
                                Rectangle()
                                    .fill(goldColor)
                                    .frame(width: 2, height: 14)
                                Rectangle()
                                    .fill(goldColor)
                                    .frame(width: 1, height: 14)
                            }
                            
                            Text("THE TOP FOUR")
                                .font(.system(size: 11, weight: .bold, design: .default))
                                .tracking(3.5)
                                .foregroundStyle(goldColor)
                            
                            // Right decorative lines
                            HStack(spacing: 3) {
                                Rectangle()
                                    .fill(goldColor)
                                    .frame(width: 2, height: 14)
                                Rectangle()
                                    .fill(goldColor)
                                    .frame(width: 1, height: 14)
                            }
                        }
                        
                        if !hasAnyPicks {
                            Text("Pick your four favourites")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    
                    Spacer()
                }
                
                // Edit button (top-right overlay)
                .overlay(alignment: .topTrailing) {
                    if hasAnyPicks {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isEditMode.toggle()
                            }
                        } label: {
                            Text(isEditMode ? "Done" : "Edit")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, -4)
                    }
                }
                
                // Four poster slots
                HStack(alignment: .top, spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        let currentMovie = topFourMovies[index]
                        TopFourSlotView(
                            movie: currentMovie,
                            slotNumber: index + 1,
                            goldColor: goldColor,
                            isEditMode: isEditMode,
                            onTap: {
                                selectedSlotIndex = index
                                showingPicker = true
                                lightHaptic()
                            },
                            onMovieTap: {
                                if let movie = currentMovie {
                                    selectedMovieForDetail = movie
                                    lightHaptic()
                                }
                            },
                            onRemove: {
                                if let movie = currentMovie {
                                    store.removeFromTopFour(movieID: movie.id)
                                    mediumHaptic()
                                }
                            }
                        )
                        .id("slot-\(index)-\(currentMovie?.id ?? 0)")
                        .opacity(hasAnimated ? 1 : 0)
                        .scaleEffect(hasAnimated ? 1 : 0.8)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7)
                                .delay(Double(index) * 0.1),
                            value: hasAnimated
                        )
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(16)
            .background(brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            .padding(.bottom, 18)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hasAnimated = true
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            TopFourPickerView(
                contentType: contentType,
                selectedSlotIndex: selectedSlotIndex ?? 0
            )
            .environmentObject(store)
        }
        .sheet(item: $selectedMovieForDetail) { movie in
            MovieDetailView(movie: movie, isInWatchlist: false)
                .environmentObject(store)
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
}

struct TopFourSlotView: View {
    let movie: Movie?
    let slotNumber: Int
    let goldColor: Color
    let isEditMode: Bool
    let onTap: () -> Void
    let onMovieTap: () -> Void
    let onRemove: () -> Void
    
    @State private var loader: ImageLoader?
    
    private var isNumberOne: Bool {
        slotNumber == 1
    }
    
    private var slotWidth: CGFloat {
        76
    }
    
    private var slotHeight: CGFloat {
        slotWidth * 1.5
    }
    
    var body: some View {
        Button(action: {
            if movie == nil {
                onTap()
            } else if !isEditMode {
                onMovieTap()
            }
        }) {
            ZStack(alignment: .topTrailing) {
                // Poster or empty slot
                if let movie = movie {
                    // Filled slot with poster
                    Group {
                        if let loader = loader, let image = loader.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: slotWidth, height: slotHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            // Loading or fallback
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: slotWidth, height: slotHeight)
                                .overlay {
                                    if let loader = loader, loader.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "film")
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(goldColor, lineWidth: 2)
                    )
                    .shadow(
                        color: goldColor.opacity(0.4),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
                    .onAppear {
                        loadImage(for: movie)
                    }
                    
                    // Remove badge (top-right) - only visible in edit mode
                    if isEditMode {
                        Button(action: onRemove) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 22, height: 22)
                                
                                Image(systemName: "minus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .offset(x: 6, y: -6)
                        .transition(.scale.combined(with: .opacity))
                    }
                } else {
                    // Empty slot
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: slotWidth, height: slotHeight)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func loadImage(for movie: Movie) {
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
    ZStack {
        AppGradient.background
            .ignoresSafeArea()
        
        TopFourShowcaseView(contentType: .movies)
            .environmentObject(MovieStore())
    }
}
