//
//  StatsCarouselView.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/06/2026.
//

import SwiftUI

struct StatsCarouselView: View {
    let stats: ProfileStats
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed card container
            ZStack {
                // Background (always visible)
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "0A1628"),
                                Color(hex: "0E3D3A"),
                                Color(hex: "1A6B5A")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Swipeable content inside
                TabView(selection: $currentPage) {
                    // Page 1: Total Watch Time (existing card content)
                    watchTimeContent
                        .tag(0)
                    
                    // Page 2: Longest vs Shortest
                    longestShortestContent
                        .tag(1)
                    
                    // Page 3: Favorite Decade
                    favoriteDecadeContent
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .frame(height: calculateCardHeight())
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            // Page indicators inside the card
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "0A1628"),
                            Color(hex: "0E3D3A"),
                            Color(hex: "1A6B5A")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
    
    // MARK: - Calculate Card Height
    
    private func calculateCardHeight() -> CGFloat {
        // Different heights for different pages
        if currentPage == 0 {
            // Page 1: Watch time with genres
            // Top padding (30) + Label (12) + spacing (16) + time text (48) + spacing (16) + bottom padding (50)
            let baseHeight: CGFloat = 30 + 12 + 16 + 48 + 16 + 50
            
            if !stats.topGenres.isEmpty {
                // Add genre progress bar (6) + spacing (12) + genre rows (21 each)
                let genreHeight: CGFloat = 6 + 12 + CGFloat(stats.topGenres.count * 21)
                return baseHeight + genreHeight
            } else {
                return baseHeight
            }
        } else if currentPage == 1 {
            // Page 2: Longest vs Shortest
            // Top padding (30) + Label (12) + spacing (16) + Title (11) + spacing (12) + Poster (120) + spacing (12) + Runtime (20) + bottom padding (35)
            return 30 + 12 + 16 + 11 + 12 + 120 + 12 + 20 + 35
        } else {
            // Page 3: Favorite Decade
            // Top padding (30) + Label (12) + spacing (16) + Decade (60) + spacing (12) + Count (16) + spacing (16) + Posters (75) + spacing (12) + Tagline (14) + bottom padding (35)
            return 30 + 12 + 16 + 60 + 12 + 16 + 16 + 75 + 12 + 14 + 35
        }
    }
    
    // MARK: - Watch Time Content (Page 1)
    
    private var watchTimeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Label with icon
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "E8B64C"))
                
                Text("TOTAL WATCH TIME")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "E8B64C"))
                    .tracking(0.5)
            }
            
            // Total time
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(stats.formattedWatchTime)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text("across \(stats.titlesCount) titles")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Multi-genre progress bar
            if !stats.topGenres.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Progress bar with multiple colors
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            ForEach(Array(stats.topGenres.enumerated()), id: \.element.id) { index, genre in
                                // Calculate the total count for normalization
                                let totalCount = stats.topGenres.reduce(0) { $0 + $1.count }
                                let normalizedPercentage = Double(genre.count) / Double(totalCount)
                                let width = geometry.size.width * normalizedPercentage
                                
                                Rectangle()
                                    .fill(genreColor(for: index))
                                    .frame(width: width, height: 6)
                            }
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 6)
                    
                    // Genre labels with percentages
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(stats.topGenres.enumerated()), id: \.element.id) { index, genre in
                            genrePercentageRow(genre: genre, index: index)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 30)
        .padding(.bottom, 50)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    // Helper function to get color for each genre
    private func genreColor(for index: Int) -> Color {
        let colors = [
            Color(hex: "E8B64C"), // Gold
            Color(hex: "FF6B6B"), // Red
            Color(hex: "4ECDC4"), // Cyan
            Color(hex: "95E1D3"), // Mint
            Color(hex: "F38181")  // Pink
        ]
        return colors[index % colors.count]
    }
    
    // Helper view for genre percentage row
    @ViewBuilder
    private func genrePercentageRow(genre: GenreRank, index: Int) -> some View {
        let totalGenreCount = stats.topGenres.reduce(0) { $0 + $1.count }
        let exactPercentage = (Double(genre.count) / Double(totalGenreCount)) * 100.0
        let percentage = calculatePercentage(exactPercentage: exactPercentage, index: index, totalGenreCount: totalGenreCount)
        
        HStack(spacing: 8) {
            Circle()
                .fill(genreColor(for: index))
                .frame(width: 8, height: 8)
            
            Text(genre.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Text("\(percentage)%")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // Helper function to calculate percentage, ensuring total adds to 100%
    private func calculatePercentage(exactPercentage: Double, index: Int, totalGenreCount: Int) -> Int {
        if index == stats.topGenres.count - 1 {
            // Last item: calculate remainder to ensure 100% total
            let sumSoFar = calculateSumOfPreviousPercentages(totalGenreCount: totalGenreCount)
            return 100 - sumSoFar
        } else {
            return Int(exactPercentage.rounded())
        }
    }
    
    // Helper function to calculate sum of previous percentages
    private func calculateSumOfPreviousPercentages(totalGenreCount: Int) -> Int {
        let previousGenres = stats.topGenres.prefix(stats.topGenres.count - 1)
        return previousGenres.reduce(0) { sum, genre in
            let pct = (Double(genre.count) / Double(totalGenreCount)) * 100.0
            return sum + Int(pct.rounded())
        }
    }
    
    // MARK: - Longest vs Shortest Content (Page 2)
    
    private var longestShortestContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Label with icon
            HStack(spacing: 6) {
                Image(systemName: "film.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "E8B64C"))
                
                Text("MOVIE RUNTIMES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "E8B64C"))
                    .tracking(0.5)
            }
            
            // Longest vs Shortest comparison
            HStack(spacing: 12) {
                // Longest movie
                if let longest = stats.longestMovie {
                    movieRuntimeCard(
                        title: "LONGEST",
                        movie: longest,
                        icon: "hare.fill"
                    )
                } else {
                    emptyMovieCard(title: "LONGEST")
                }
                
                // VS divider
                Text("VS")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: 30)
                
                // Shortest movie
                if let shortest = stats.shortestMovie {
                    movieRuntimeCard(
                        title: "SHORTEST",
                        movie: shortest,
                        icon: "hare.fill"
                    )
                } else {
                    emptyMovieCard(title: "SHORTEST")
                }
            }
            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
        }
        .padding(.horizontal, 24)
        .padding(.top, 30)
        .padding(.bottom, 35)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    // Helper view for individual movie runtime card
    @ViewBuilder
    private func movieRuntimeCard(title: String, movie: Movie, icon: String) -> some View {
        VStack(spacing: 12) {
            // Title
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
            
            // Poster
            AsyncImage(url: movie.posterURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(hex: "0D1A22").opacity(0.3))
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color(hex: "0D1A22").opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white.opacity(0.5))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 80, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Runtime
            if let runtime = movie.formattedRuntime {
                Text(runtime)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // Empty state for when no movies are available
    @ViewBuilder
    private func emptyMovieCard(title: String) -> some View {
        VStack(spacing: 12) {
            // Title
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)
            
            // Empty poster
            Rectangle()
                .fill(Color(hex: "0D1A22").opacity(0.3))
                .overlay(
                    Image(systemName: "film")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 24))
                )
                .frame(width: 80, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Empty runtime
            Text("--")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Favorite Decade Content (Page 3)
    
    private var favoriteDecadeContent: some View {
        VStack(spacing: 16) {
            // Label with icon
            HStack(spacing: 6) {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "E8B64C"))
                
                Text("FAVORITE DECADE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "E8B64C"))
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let decadeInfo = stats.favoriteDecade {
                // Decade number (big and bold)
                Text(formattedDecade(decadeInfo.decade))
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                
                // Count
                Text("\(decadeInfo.count) movies watched")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                // Random movie posters
                HStack(spacing: 8) {
                    ForEach(decadeInfo.movies) { movie in
                        AsyncImage(url: movie.posterURL) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color(hex: "0D1A22").opacity(0.3))
                                    .overlay(
                                        ProgressView()
                                            .tint(.white)
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color(hex: "0D1A22").opacity(0.3))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(size: 12))
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 50, height: 75)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                
                // Tagline
                Text(tagline(for: decadeInfo.decade))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
            } else {
                // Empty state
                Text("No decade data available")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 40)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 30)
        .padding(.bottom, 35)
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    // Helper function to get tagline for each decade
    private func tagline(for decade: Int) -> String {
        switch decade {
        case 1950:
            return "Back when movies were in black & white... and so was everything else!"
        case 1960:
            return "Groovy, baby!"
        case 1970:
            return "Disco balls and film reels"
        case 1980:
            return "Totally radical!"
        case 1990:
            return "The golden age of VHS"
        case 2000:
            return "Y2K didn't stop the movies"
        case 2010:
            return "The streaming era begins"
        case 2020:
            return "You're up to date!"
        default:
            return "A timeless classic era!"
        }
    }
    
    // Helper function to format decade (e.g., 1970 -> "70's")
    private func formattedDecade(_ decade: Int) -> String {
        let yearString = String(decade)
        // Get last two digits (e.g., 1970 -> 70)
        let lastTwo = String(yearString.suffix(2))
        return "\(lastTwo)'s"
    }
}

// MARK: - Preview

#Preview("Stats Carousel") {
    let actionGenre = Genre(id: 28, name: "Action")
    let sciFiGenre = Genre(id: 878, name: "Science Fiction")
    let dramaGenre = Genre(id: 18, name: "Drama")
    
    let sampleMovies: [Movie] = [
        Movie(
            id: 1,
            title: "Inception",
            overview: "A thief who steals corporate secrets...",
            posterPath: "/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg",
            releaseDate: "2010-07-16",
            voteAverage: 8.4,
            mediaType: "movie",
            runtime: 148,
            genres: [actionGenre, sciFiGenre]
        ),
        Movie(
            id: 2,
            title: "The Dark Knight",
            overview: "Batman faces the Joker...",
            posterPath: "/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
            releaseDate: "2008-07-18",
            voteAverage: 9.0,
            mediaType: "movie",
            runtime: 152,
            genres: [actionGenre, dramaGenre]
        ),
        Movie(
            id: 3,
            title: "Toy Story",
            overview: "A short film...",
            posterPath: "/uXDfjJbdP4ijW5hWSBrPrlKpxab.jpg",
            releaseDate: "1995-11-22",
            voteAverage: 8.0,
            mediaType: "movie",
            runtime: 81,
            genres: [actionGenre]
        ),
        Movie(
            id: 4,
            title: "The Godfather",
            overview: "The aging patriarch...",
            posterPath: "/3bhkrj58Vtu7enYsRolD1fZdja1.jpg",
            releaseDate: "1972-03-14",
            voteAverage: 8.7,
            mediaType: "movie",
            runtime: 175,
            genres: [dramaGenre]
        )
    ]
    
    let sampleRatings: [Int: UserRating] = [
        1: UserRating(movieId: 1, rating: 5.0),
        2: UserRating(movieId: 2, rating: 5.0),
        3: UserRating(movieId: 3, rating: 4.0),
        4: UserRating(movieId: 4, rating: 5.0)
    ]
    
    let stats = ProfileStats(archive: sampleMovies, ratings: sampleRatings)
    
    return ZStack {
        AppGradient.background
            .ignoresSafeArea()
        
        StatsCarouselView(stats: stats)
            .padding(.horizontal, 20)
    }
}
