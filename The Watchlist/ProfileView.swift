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
    @State private var expandedGenreId: Int?
    @AppStorage("userName") private var userName = "Add Name"
    @AppStorage("userAvatar") private var userAvatar = ""
    
    init(archive: [Movie], ratings: [Int: UserRating]) {
        _stats = StateObject(wrappedValue: ProfileStats(archive: archive, ratings: ratings))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Header
                headerRow
                
                VStack(spacing: 24) {
                    // 2. Identity row
                    identityRow
                        .padding(.horizontal, 20)
                    
                    // 3. Stats carousel (watch time + longest/shortest)
                    StatsCarouselView(stats: stats)
                        .padding(.horizontal, 20)
                }
                
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
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailView(achievement: achievement)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
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
                if !userAvatar.isEmpty {
                    // Show emoji avatar
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 64, height: 64)
                    
                    Text(userAvatar)
                        .font(.system(size: 32))
                } else {
                    // Show gradient with initial
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
            if let selectedId = selectedGenreId ?? stats.topGenres.first?.id,
               let selectedGenre = stats.topGenres.first(where: { $0.id == selectedId }) {
                let allMovies = stats.moviesForGenre(genreId: selectedId)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(allMovies) { movie in
                            posterCard(for: movie)
                        }
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
                
                achievementBadge(
                    icon: "sparkles",
                    title: "Clean Slate",
                    description: "Clear your entire watchlist by watching or removing all items.",
                    unlocked: stats.hasCleanSlateAchievement,
                    color: Color(hex: "1A6B5A")
                )
            }
            
            // Row 4
            HStack(spacing: 16) {
                achievementBadge(
                    icon: "100",
                    title: "Century Club",
                    description: "Reach 100 total items across your watchlist and archive combined.",
                    unlocked: stats.hasCenturyClubAchievement,
                    color: Color(hex: "E8B64C")
                )
                
                // Empty placeholders to maintain grid
                Color.clear
                    .frame(maxWidth: .infinity)
                
                Color.clear
                    .frame(maxWidth: .infinity)
                
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
                        
                        // Custom text for "100" since 100.circle.fill doesn't exist
                        if icon == "100" {
                            Text("100")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(unlocked ? color : .white.opacity(0.3))
                        } else {
                            Image(systemName: icon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(unlocked ? color : .white.opacity(0.3))
                        }
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

struct AchievementInfo: Identifiable {
    let id = UUID()
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
                    
                    // Custom text for "100" since 100.circle.fill doesn't exist
                    if achievement.icon == "100" {
                        Text("100")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(achievement.unlocked ? achievement.color : .white.opacity(0.3))
                    } else {
                        Image(systemName: achievement.icon)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(achievement.unlocked ? achievement.color : .white.opacity(0.3))
                    }
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

// MARK: - Genre Movies View

struct GenreMoviesView: View {
    let genre: GenreRank
    let movies: [WatchedMovieForGenre]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "0D1A22"))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(genre.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "0D1A22"))
                        
                        Text("\(genre.count) movies")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "0D1A22").opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Invisible spacer to balance the chevron
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Horizontal scroll view with all posters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(movies) { movie in
                            posterCard(for: movie)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                
                Spacer()
            }
            .background(
                AppGradient.background
                    .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
    }
    
    private func posterCard(for movie: WatchedMovieForGenre) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            Text(movie.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTextColors.primary)
                .lineLimit(2)
                .frame(width: 94, alignment: .leading)
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
    
    // Sample archived movies (with more drama films)
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
        ),
        Movie(
            id: 9,
            title: "The Godfather",
            overview: "The aging patriarch of an organized crime dynasty...",
            posterPath: "/3bhkrj58Vtu7enYsRolD1fZdja1.jpg",
            releaseDate: "1972-03-14",
            voteAverage: 8.7,
            mediaType: "movie",
            runtime: 175,
            genres: [dramaGenre]
        ),
        Movie(
            id: 10,
            title: "Schindler's List",
            overview: "The true story of Oskar Schindler...",
            posterPath: "/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg",
            releaseDate: "1993-12-15",
            voteAverage: 8.6,
            mediaType: "movie",
            runtime: 195,
            genres: [dramaGenre]
        ),
        Movie(
            id: 11,
            title: "12 Angry Men",
            overview: "The defense and the prosecution...",
            posterPath: "/ow3wq89wM8qd5X7hWKxiRfsFf9C.jpg",
            releaseDate: "1957-04-10",
            voteAverage: 8.5,
            mediaType: "movie",
            runtime: 96,
            genres: [dramaGenre]
        ),
        Movie(
            id: 12,
            title: "Fight Club",
            overview: "A ticking-time-bomb insomniac...",
            posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
            releaseDate: "1999-10-15",
            voteAverage: 8.4,
            mediaType: "movie",
            runtime: 139,
            genres: [dramaGenre]
        ),
        Movie(
            id: 13,
            title: "Good Will Hunting",
            overview: "Will Hunting, a janitor at MIT...",
            posterPath: "/bABCBKYBK7A5G1x0FzoeoNfuj2.jpg",
            releaseDate: "1997-12-05",
            voteAverage: 8.2,
            mediaType: "movie",
            runtime: 126,
            genres: [dramaGenre]
        ),
        Movie(
            id: 14,
            title: "The Green Mile",
            overview: "A supernatural tale set on death row...",
            posterPath: "/velWPhVMQeQKcxggNEU8YmIo52R.jpg",
            releaseDate: "1999-12-10",
            voteAverage: 8.5,
            mediaType: "movie",
            runtime: 189,
            genres: [dramaGenre]
        ),
        Movie(
            id: 15,
            title: "A Beautiful Mind",
            overview: "John Nash, a brilliant mathematician...",
            posterPath: "/zwzWCmH72OSC9NA0ipoqw5Zjya8.jpg",
            releaseDate: "2001-12-21",
            voteAverage: 7.9,
            mediaType: "movie",
            runtime: 135,
            genres: [dramaGenre]
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
        8: UserRating(movieId: 8, rating: 4.0),
        9: UserRating(movieId: 9, rating: 5.0),
        10: UserRating(movieId: 10, rating: 5.0),
        11: UserRating(movieId: 11, rating: 4.5),
        12: UserRating(movieId: 12, rating: 4.5),
        13: UserRating(movieId: 13, rating: 4.0),
        14: UserRating(movieId: 14, rating: 4.5),
        15: UserRating(movieId: 15, rating: 4.0)
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
#Preview("Genre Movies View") {
    let sampleGenre = GenreRank(id: 18, name: "Drama", count: 12)
    let sampleMovies: [WatchedMovieForGenre] = [
        WatchedMovieForGenre(
            id: 6,
            title: "The Shawshank Redemption",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/q6y0Go1tsGEsmtFryDOJo3dEmqu.jpg"),
            rating: 9.3
        ),
        WatchedMovieForGenre(
            id: 9,
            title: "The Godfather",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg"),
            rating: 8.7
        ),
        WatchedMovieForGenre(
            id: 10,
            title: "Schindler's List",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg"),
            rating: 8.6
        ),
        WatchedMovieForGenre(
            id: 11,
            title: "12 Angry Men",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/ow3wq89wM8qd5X7hWKxiRfsFf9C.jpg"),
            rating: 8.5
        ),
        WatchedMovieForGenre(
            id: 12,
            title: "Fight Club",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg"),
            rating: 8.4
        ),
        WatchedMovieForGenre(
            id: 3,
            title: "Interstellar",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"),
            rating: 8.6
        ),
        WatchedMovieForGenre(
            id: 14,
            title: "The Green Mile",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/velWPhVMQeQKcxggNEU8YmIo52R.jpg"),
            rating: 8.5
        ),
        WatchedMovieForGenre(
            id: 13,
            title: "Good Will Hunting",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/bABCBKYBK7A5G1x0FzoeoNfuj2.jpg"),
            rating: 8.2
        ),
        WatchedMovieForGenre(
            id: 5,
            title: "Pulp Fiction",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg"),
            rating: 8.9
        ),
        WatchedMovieForGenre(
            id: 7,
            title: "Forrest Gump",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg"),
            rating: 8.8
        ),
        WatchedMovieForGenre(
            id: 15,
            title: "A Beautiful Mind",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/zwzWCmH72OSC9NA0ipoqw5Zjya8.jpg"),
            rating: 7.9
        ),
        WatchedMovieForGenre(
            id: 2,
            title: "The Dark Knight",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg"),
            rating: 9.0
        )
    ]
    
    return GenreMoviesView(genre: sampleGenre, movies: sampleMovies)
}

