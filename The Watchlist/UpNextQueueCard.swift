//
//  UpNextQueueCard.swift
//  The Watchlist
//
//  Created by Matt Rose on 11/06/2026.
//

import SwiftUI

struct UpNextQueueCard: View {
    @EnvironmentObject var store: MovieStore
    let contentType: ContentType
    @State private var isEditMode = false
    @State private var showingPicker = false
    @State private var selectedSlotIndex: Int? = nil
    @State private var selectedMovieForDetail: Movie?
    @State private var hasAnimated = false
    
    private let goldColor = Color(hex: "E8B64C")
    private let brandGradient = LinearGradient(
        colors: [
            Color(hex: "0A1628"),
            Color(hex: "0E3D3A"),
            Color(hex: "1A6B5A")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var queueMovies: [Movie?] {
        let ids = store.getUpNextQueue(for: contentType)
        var movies: [Movie?] = []
        for id in ids {
            movies.append(store.watchlist.first { $0.id == id })
        }
        // Pad with nils to always have 3 slots
        while movies.count < 3 {
            movies.append(nil)
        }
        return movies
    }
    
    var hasAnyMovies: Bool {
        !store.getUpNextQueue(for: contentType).isEmpty
    }
    
    var allSlotsEmpty: Bool {
        store.getUpNextQueue(for: contentType).isEmpty
    }
    
    var captionText: String {
        if allSlotsEmpty {
            return "Pick the next three films you want to watch"
        } else if isEditMode {
            return "Tap a film to remove it"
        } else {
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium card
            VStack(spacing: 12) {
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
                            
                            Text("UP NEXT")
                                .font(.system(size: 11, weight: .bold, design: .default))
                                .tracking(2.4)
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
                    }
                    
                    Spacer()
                }
                
                // Edit button (top-right overlay)
                .overlay(alignment: .topTrailing) {
                    if hasAnyMovies {
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
                
                // Three poster slots
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        UpNextSlotView(
                            movie: queueMovies[index],
                            slotNumber: index + 1,
                            goldColor: goldColor,
                            isEditMode: isEditMode,
                            onTap: {
                                selectedSlotIndex = index
                                showingPicker = true
                                lightHaptic()
                            },
                            onMovieTap: {
                                if let movie = queueMovies[index] {
                                    selectedMovieForDetail = movie
                                    lightHaptic()
                                }
                            },
                            onRemove: {
                                if let movie = queueMovies[index] {
                                    store.removeFromUpNextQueue(movieID: movie.id, for: contentType)
                                    mediumHaptic()
                                }
                            }
                        )
                        .id("\(contentType.rawValue)-\(index)-\(queueMovies[index]?.id ?? -1)")
                        .opacity(hasAnimated ? 1 : 0)
                        .scaleEffect(hasAnimated ? 1 : 0.8)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7)
                                .delay(Double(index) * 0.08),
                            value: hasAnimated
                        )
                    }
                }
                .id(store.getUpNextQueue(for: contentType))
                
                // Caption text
                if !captionText.isEmpty {
                    Text(captionText)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hasAnimated = true
                }
            }
        }
        .sheet(isPresented: $showingPicker) {
            UpNextQueuePickerView(
                contentType: contentType,
                selectedSlotIndex: selectedSlotIndex ?? 0
            )
            .environmentObject(store)
        }
        .sheet(item: $selectedMovieForDetail) { movie in
            MovieDetailView(movie: movie, isInWatchlist: true)
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

struct UpNextSlotView: View {
    let movie: Movie?
    let slotNumber: Int
    let goldColor: Color
    let isEditMode: Bool
    let onTap: () -> Void
    let onMovieTap: () -> Void
    let onRemove: () -> Void
    
    @State private var loader: ImageLoader?
    
    private var slotWidth: CGFloat {
        85
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
            ZStack(alignment: .topLeading) {
                // Poster or empty slot
                if let movie = movie {
                    // Filled slot with poster
                    Group {
                        if let loader = loader, let image = loader.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: slotWidth, height: slotHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            // Loading or fallback
                            RoundedRectangle(cornerRadius: 12)
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
                    .shadow(
                        color: .black.opacity(0.3),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                    .onAppear {
                        loadImage(for: movie)
                    }
                    
                    // Position badge (top-left)
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1A6B5A").opacity(0.85))
                            .frame(width: 22, height: 22)
                        
                        Text("\(slotNumber)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: -6, y: -6)
                    
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
                        .offset(x: slotWidth - 16, y: -6)
                        .transition(.scale.combined(with: .opacity))
                    }
                } else {
                    // Empty slot
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                        .foregroundStyle(goldColor.opacity(0.55))
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.04))
                        )
                        .frame(width: slotWidth, height: slotHeight)
                        .overlay {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .stroke(goldColor.opacity(0.6), lineWidth: 1.5)
                                        .frame(width: 28, height: 28)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(goldColor.opacity(0.7))
                                }
                                
                                Text("Add movie")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
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
        
        VStack {
            UpNextQueueCard(contentType: .movies)
                .environmentObject(MovieStore())
            
            Spacer()
        }
        .padding(.top, 40)
    }
}
