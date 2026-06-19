//
//  ProfileView.swift
//  The Watchlist
//
//  Created by Matt Rose on 19/06/2026.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var stats: ProfileStats
    @State private var selectedGenreId: Int?
    @State private var showingEditProfile = false
    @State private var selectedAchievement: AchievementInfo?
    @State private var showingAchievementDetail = false
    @AppStorage("userName") private var userName = "Add Name"
    
    init(archive: [Movie], ratings: [Int: UserRating]) {
        _stats = StateObject(wrappedValue: ProfileStats(archive: archive, ratings: ratings))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Header
                headerRow
                
                // 2. Identity row
                identityRow
                    .padding(.horizontal, 20)
                
                // 3. Watch-time hero card
                watchTimeCard
                    .padding(.horizontal, 20)
                
                // 4. Top genres section
                topGenresSection
                
                // 5. Achievements section
                achievementsSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .background(
            AppGradient.background
                .ignoresSafeArea()
        )
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingAchievementDetail) {
            if let achievement = selectedAchievement {
                AchievementDetailView(achievement: achievement)
                    .presentationDetents([.height(350)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Header Row
    
    private var headerRow: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("0D1A22"))
            }
            
            Spacer()
            
            Text("Profile")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "0D1A22"))
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Identity Row
    
    private var identityRow: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "0E3D3A"), // Teal brand gradient start
                        Color(hex: "1A6B5A")  // Teal brand gradient end
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                
                Text(String((userName == "Add Name" ? "A" : userName).prefix(1)).uppercased())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Name and handle
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "0D1A22"))
                
                Text("Member since 2026")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "0D1A22").opacity(0.6))
            }
            
            Spacer()
            
            // Edit pill
            Button(action: {
                showingEditProfile = true
            }) {
                Text("Edit")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "0D1A22"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                    )
            }
        }
    }
    
    // MARK: - Watch Time Card
    
    private var watchTimeCard: some View {
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
            
            // Progress bar for top genre
            if let topGenre = stats.topGenres.first {
                VStack(alignment: .leading, spacing: 8) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)
                            
                            // Fill
                            Capsule()
                                .fill(Color(hex: "E8B64C"))
                                .frame(width: geometry.size.width * (stats.topGenreSharePercent / 100.0), height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    // Genre label
                    Text("\(topGenre.name) · \(Int(stats.topGenreSharePercent))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(24)
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
    
    // MARK: - Top Genres Section
    
    private var topGenresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("Top Genres")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTextColors.primary)
                .padding(.horizontal, 20)
            
            // Genre pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stats.topGenres) { genre in
                        genrePill(for: genre)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Poster row for selected genre
            if let selectedId = selectedGenreId ?? stats.topGenres.first?.id {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(stats.moviesForGenre(genreId: selectedId)) { movie in
                            posterCard(for: movie)
                        }
                        
                        // "See all" tile
                        seeAllTile
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private func genrePill(for genre: GenreRank) -> some View {
        let isSelected = (selectedGenreId ?? stats.topGenres.first?.id) == genre.id
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedGenreId = genre.id
            }
        }) {
            HStack(spacing: 6) {
                Text(genre.name)
                    .font(.system(size: 14, weight: .semibold))
                
                Text("\(genre.count)")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color(hex: "0D1A22").opacity(0.2) : Color.white.opacity(0.2))
                    )
            }
            .foregroundColor(isSelected ? Color(hex: "0D1A22") : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "E8B64C") : Color(hex: "1A6B5A").opacity(0.3))
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? Color.clear : Color(hex: "1A6B5A").opacity(0.5),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
    
    private func posterCard(for movie: WatchedMovieForGenre) -> some View {
        ZStack(alignment: .bottom) {
            // Poster image
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
            .frame(width: 94, height: 134)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Title scrim (bottom)
            VStack {
                Spacer()
                
                Text(movie.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(width: 94, height: 134)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var seeAllTile: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "1A6B5A").opacity(0.3))
            .overlay(
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            )
            .frame(width: 60, height: 134)
    }
    
    // MARK: - Achievements Section
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTextColors.primary)
            
            // Row 1
            HStack(spacing: 16) {
                achievementBadge(
                    icon: "25.circle.fill",
                    title: "First 25",
                    description: "Watch 25 movies to unlock this achievement.",
                    unlocked: stats.hasFirst25Achievement,
                    color: Color(hex: "E8B64C")
                )
                
                achievementBadge(
                    icon: "film.fill",
                    title: stats.hasGenreBuffAchievement.genreName ?? "Genre Buff",
                    description: "Watch 10 or more movies in a single genre.",
                    unlocked: stats.hasGenreBuffAchievement.unlocked,
                    color: Color(hex: "1A6B5A")
                )
                
                achievementBadge(
                    icon: "film.stack.fill",
                    title: "Saga Done",
                    description: "Complete a movie saga by watching 3 or more films from the same franchise.",
                    unlocked: stats.hasSagaDoneAchievement,
                    color: Color(hex: "E8B64C")
                )
                
                achievementBadge(
                    icon: "50.circle.fill",
                    title: "50 Films",
                    description: "Watch 50 movies to unlock this achievement.",
                    unlocked: stats.has50FilmsAchievement,
                    color: Color(hex: "1A6B5A")
                )
            }
            
            // Row 2
            HStack(spacing: 16) {
                achievementBadge(
                    icon: "books.vertical.fill",
                    title: "Classics Scholar",
                    description: "Watch 10 or more movies released in 2000 or earlier.",
                    unlocked: stats.hasClassicsScholarAchievement,
                    color: Color(hex: "E8B64C")
                )
                
                achievementBadge(
                    icon: "star.fill",
                    title: "Critic's Choice",
                    description: "Rate 25 or more movies with your own ratings.",
                    unlocked: stats.hasCriticsChoiceAchievement,
                    color: Color(hex: "1A6B5A")
                )
                
                achievementBadge(
                    icon: "checkmark.seal.fill",
                    title: "Perfect Score",
                    description: "Give 10 movies a perfect 5-star rating.",
                    unlocked: stats.hasPerfectScoreAchievement,
                    color: Color(hex: "E8B64C")
                )
                
                achievementBadge(
                    icon: "hand.thumbsdown.fill",
                    title: "Harsh Critic",
                    description: "Rate at least one movie with 1 star or lower.",
                    unlocked: stats.hasHarshCriticAchievement,
                    color: Color(hex: "1A6B5A")
                )
            }
            
            // Row 3
            HStack(spacing: 16) {
                achievementBadge(
                    icon: "hare.fill",
                    title: "Speed Demon",
                    description: "Watch 10 or more movies under 90 minutes in runtime.",
                    unlocked: stats.hasSpeedDemonAchievement,
                    color: Color(hex: "E8B64C")
                )
                
                achievementBadge(
                    icon: "film.stack",
                    title: "Epic Viewer",
                    description: "Watch 5 or more movies over 3 hours long.",
                    unlocked: stats.hasEpicViewerAchievement,
                    color: Color(hex: "1A6B5A")
                )
                
                achievementBadge(
                    icon: "calendar.badge.clock",
                    title: "Decade Explorer",
                    description: "Watch at least one movie from 5 different decades.",
                    unlocked: stats.hasDecadeExplorerAchievement,
                    color: Color(hex: "E8B64C")
                )
                
                // Empty placeholder to maintain grid
                Color.clear
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func achievementBadge(icon: String, title: String, description: String, unlocked: Bool, color: Color) -> some View {
        Button(action: {
            selectedAchievement = AchievementInfo(
                icon: icon,
                title: title,
                description: description,
                unlocked: unlocked,
                color: color
            )
            showingAchievementDetail = true
        }) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    // Main circle
                    ZStack {
                        Circle()
                            .strokeBorder(
                                unlocked ? color : Color.white.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: unlocked ? [] : [4, 4])
                            )
                            .background(
                                Circle()
                                    .fill(unlocked ? color.opacity(0.2) : Color.clear)
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(unlocked ? color : .white.opacity(0.3))
                    }
                    
                    // Lock badge (top right)
                    if !unlocked {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "0D1A22"))
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .offset(x: 4, y: -4)
                    }
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTextColors.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 70)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Models

struct AchievementInfo {
    let icon: String
    let title: String
    let description: String
    let unlocked: Bool
    let color: Color
}

// MARK: - Achievement Detail View

struct AchievementDetailView: View {
    let achievement: AchievementInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient (always present)
            LinearGradient(
                colors: [
                    Color(hex: "0A1628"),
                    Color(hex: "0E3D3A")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 24) {
                // Handle bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                
                // Achievement icon
                ZStack {
                    Circle()
                        .fill(achievement.unlocked ? achievement.color.opacity(0.2) : Color.white.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .strokeBorder(
                            achievement.unlocked ? achievement.color : Color.white.opacity(0.3),
                            style: StrokeStyle(lineWidth: 3, dash: achievement.unlocked ? [] : [6, 6])
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(achievement.unlocked ? achievement.color : .white.opacity(0.3))
                }
                
                // Title
                Text(achievement.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Status badge
                HStack(spacing: 6) {
                    Image(systemName: achievement.unlocked ? "checkmark.circle.fill" : "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(achievement.unlocked ? "Unlocked" : "Locked")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(achievement.unlocked ? Color(hex: "4CAF50") : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(achievement.unlocked ? Color(hex: "4CAF50").opacity(0.2) : Color.white.opacity(0.1))
                )
                
                // Description
                Text(achievement.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Preview

#Preview("Profile with Sample Data") {
    // Sample genres (note: Genre.displayName will show "Sci-Fi" for "Science Fiction")
    let actionGenre = Genre(id: 28, name: "Action")
    let sciFiGenre = Genre(id: 878, name: "Science Fiction")
    let dramaGenre = Genre(id: 18, name: "Drama")
    let comedyGenre = Genre(id: 35, name: "Comedy")
    let thrillerGenre = Genre(id: 53, name: "Thriller")
    
    // Sample archived movies
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
            genres: [actionGenre, sciFiGenre, thrillerGenre]
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
            genres: [actionGenre, dramaGenre, thrillerGenre]
        ),
        Movie(
            id: 3,
            title: "Interstellar",
            overview: "A team of explorers travel...",
            posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
            releaseDate: "2014-11-07",
            voteAverage: 8.6,
            mediaType: "movie",
            runtime: 169,
            genres: [sciFiGenre, dramaGenre]
        ),
        Movie(
            id: 4,
            title: "The Matrix",
            overview: "A computer hacker learns...",
            posterPath: "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg",
            releaseDate: "1999-03-31",
            voteAverage: 8.7,
            mediaType: "movie",
            runtime: 136,
            genres: [actionGenre, sciFiGenre]
        ),
        Movie(
            id: 5,
            title: "Pulp Fiction",
            overview: "The lives of two mob hitmen...",
            posterPath: "/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg",
            releaseDate: "1994-10-14",
            voteAverage: 8.9,
            mediaType: "movie",
            runtime: 154,
            genres: [thrillerGenre, dramaGenre]
        ),
        Movie(
            id: 6,
            title: "The Shawshank Redemption",
            overview: "Two imprisoned men bond...",
            posterPath: "/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg",
            releaseDate: "1994-09-23",
            voteAverage: 9.3,
            mediaType: "movie",
            runtime: 142,
            genres: [dramaGenre]
        ),
        Movie(
            id: 7,
            title: "Forrest Gump",
            overview: "The presidencies of Kennedy and Johnson...",
            posterPath: "/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg",
            releaseDate: "1994-07-06",
            voteAverage: 8.8,
            mediaType: "movie",
            runtime: 142,
            genres: [comedyGenre, dramaGenre]
        ),
        Movie(
            id: 8,
            title: "Blade Runner 2049",
            overview: "Officer K, a new blade runner...",
            posterPath: "/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg",
            releaseDate: "2017-10-04",
            voteAverage: 7.6,
            mediaType: "movie",
            runtime: 164,
            genres: [sciFiGenre, thrillerGenre]
        )
    ]
    
    // Sample ratings
    let sampleRatings: [Int: UserRating] = [
        1: UserRating(movieId: 1, rating: 5.0),
        2: UserRating(movieId: 2, rating: 5.0),
        3: UserRating(movieId: 3, rating: 4.5),
        4: UserRating(movieId: 4, rating: 5.0),
        5: UserRating(movieId: 5, rating: 4.5),
        6: UserRating(movieId: 6, rating: 5.0),
        7: UserRating(movieId: 7, rating: 4.0),
        8: UserRating(movieId: 8, rating: 4.0)
    ]
    
    return ProfileView(archive: sampleMovies, ratings: sampleRatings)
}

#Preview("Achievement Detail - Unlocked") {
    AchievementDetailView(
        achievement: AchievementInfo(
            icon: "25.circle.fill",
            title: "First 25",
            description: "Watch 25 movies to unlock this achievement.",
            unlocked: true,
            color: Color(hex: "E8B64C")
        )
    )
}

#Preview("Achievement Detail - Locked") {
    AchievementDetailView(
        achievement: AchievementInfo(
            icon: "50.circle.fill",
            title: "50 Films",
            description: "Watch 50 movies to unlock this achievement.",
            unlocked: false,
            color: Color(hex: "1A6B5A")
        )
    )
}
