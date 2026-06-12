//
//  StarRatingView.swift
//  The Watchlist
//
//  Created by Matt Rose on 03/06/2026.
//

import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Double
    let maxRating: Int = 5
    let starSize: CGFloat
    let interactive: Bool
    
    @State private var dragLocation: CGFloat?
    
    init(rating: Binding<Double>, starSize: CGFloat = 40, interactive: Bool = true) {
        self._rating = rating
        self.starSize = starSize
        self.interactive = interactive
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<maxRating, id: \.self) { index in
                starImage(for: index)
                    .font(.system(size: starSize))
                    .foregroundStyle(starColor(for: index))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        interactive ? DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateRating(at: value.location.x, in: geometry.size.width)
                            }
                            .onEnded { _ in
                                dragLocation = nil
                            } : nil
                    )
            }
        )
    }
    
    private func starImage(for index: Int) -> Image {
        let filledAmount = rating - Double(index)
        
        if filledAmount >= 1.0 {
            return Image(systemName: "star.fill")
        } else if filledAmount >= 0.5 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
    
    private func starColor(for index: Int) -> Color {
        let filledAmount = rating - Double(index)
        
        if filledAmount > 0 {
            return AppTextColors.rating
        } else {
            return Color.white.opacity(0.3)
        }
    }
    
    private func updateRating(at x: CGFloat, in width: CGFloat) {
        // Calculate which star and half was tapped/dragged
        let starWidth = width / CGFloat(maxRating)
        let position = max(0, min(x, width))
        
        let starIndex = Int(position / starWidth)
        let remainder = (position.truncatingRemainder(dividingBy: starWidth)) / starWidth
        
        // Determine if it's a half or full star
        let halfStar = remainder >= 0.5 ? 0.5 : 0.0
        let newRating = Double(starIndex) + halfStar
        
        // Add haptic feedback
        if newRating != rating {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        rating = newRating
    }
}

struct RatingSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var rating: Double
    let movie: Movie
    let onSubmit: (Double) -> Void
    
    @State private var tempRating: Double = 0.0
    @State private var showStars = false
    
    var body: some View {
        ZStack {
            // Background - explicitly set
            LinearGradient(
                colors: [
                    Color(hex: "8FA89E"),
                    Color(hex: "8FA89E"),
                    Color(hex: "5C6B6B"),
                    Color(hex: "1a1a1a"),
                    Color(hex: "#0d0d0d")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                // Movie Info
                VStack(spacing: 12) {
                    if let posterURL = movie.posterURL {
                        AsyncImage(url: posterURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 120)
                        }
                    }
                    
                    Text("Rate this \(movie.isTV ? "show" : "movie")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTextColors.primary)
                    
                    Text(movie.title)
                        .font(.body)
                        .foregroundStyle(AppTextColors.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                }
                
                // Star Rating
                VStack(spacing: 10) {
                    StarRatingView(rating: $tempRating, starSize: 44, interactive: true)
                        .scaleEffect(showStars ? 1.0 : 0.5)
                        .opacity(showStars ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showStars)
                    
                    // Fixed height container for rating text to prevent layout shift
                    ZStack {
                        // Invisible placeholder to maintain height
                        Text(" ")
                            .font(.headline)
                            .opacity(0)
                        
                        // Visible rating text with transition
                        if tempRating > 0 {
                            Text(ratingText)
                                .font(.headline)
                                .foregroundStyle(AppTextColors.accent)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(height: 22) // Fixed height to prevent layout shift
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tempRating)
                }
                .padding(.top, 4)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        onSubmit(tempRating)
                        dismiss()
                    } label: {
                        Text(tempRating > 0 ? "Submit Rating" : "Skip Rating")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(tempRating > 0 ? AppGradient.green : AppGradient.buttonWhite)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppGradient.buttonWhiteBorder, lineWidth: 1)
                            )
                    }
                    .animation(.easeInOut(duration: 0.25), value: tempRating > 0)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppTextColors.secondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .padding(.top, 20)
        }
        .onAppear {
            tempRating = rating
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showStars = true
            }
        }
    }
    
    private var ratingText: String {
        switch tempRating {
        case 0.5: return "Terrible"
        case 1.0: return "Very Bad"
        case 1.5: return "Bad"
        case 2.0: return "Poor"
        case 2.5: return "Below Average"
        case 3.0: return "Average"
        case 3.5: return "Good"
        case 4.0: return "Great"
        case 4.5: return "Excellent"
        case 5.0: return "Masterpiece!"
        default: return ""
        }
    }
}

#Preview {
    RatingSheet(
        rating: .constant(0),
        movie: Movie(
            id: 1,
            title: "The Shawshank Redemption",
            overview: "Great movie",
            posterPath: "/9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg",
            releaseDate: "1994-09-23",
            voteAverage: 8.7
        ),
        onSubmit: { _ in }
    )
}
