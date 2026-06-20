//
//  MilestoneView.swift
//  The Watchlist
//
//  Created by Matt Rose on 10/06/2026.
//

import SwiftUI

struct MilestoneView: View {
    let milestone: Milestone
    let onDismiss: () -> Void
    
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Semi-transparent background that blocks interaction
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss on background tap
                    onDismiss()
                }
            
            // Confetti animation
            ConfettiView()
            
            VStack(spacing: 24) {
                // Popcorn icon
                Image(systemName: "popcorn.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTextColors.accent)
                
                // Achievement title
                Text(milestone.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTextColors.primary)
                    .multilineTextAlignment(.center)
                
                // Count display (only show for watch count milestones)
                if case .watchCount(let count, let contentType) = milestone.type {
                    Text("\(count) \(contentType == .movies ? "Movies" : "TV Shows") Watched!")
                        .font(.title2)
                        .foregroundStyle(AppTextColors.secondary)
                        .multilineTextAlignment(.center)
                } else if case .centuryClub = milestone.type {
                    Text("100 Total Items!")
                        .font(.title2)
                        .foregroundStyle(AppTextColors.secondary)
                        .multilineTextAlignment(.center)
                } else if case .cleanSlate = milestone.type {
                    Text("Watchlist Cleared!")
                        .font(.title2)
                        .foregroundStyle(AppTextColors.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Congratulations message
                Text(milestone.message)
                    .font(.body)
                    .foregroundStyle(AppTextColors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Continue button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppGradient.gold)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.5))
                    .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppGradient.gold.opacity(0.3), lineWidth: 1)
            )
            .padding(40)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .sensoryFeedback(.success, trigger: showConfetti)
        .onAppear {
            // Trigger confetti effect
            showConfetti = true
            
            // Animate in the card
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiShape()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .offset(x: piece.x, y: piece.y)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        
        for i in 0..<50 {
            // More spread out horizontal positions
            let xPosition = CGFloat.random(in: -50...(size.width + 50))
            
            let piece = ConfettiPiece(
                x: xPosition,
                y: size.height + 50, // Start from bottom
                size: CGFloat.random(in: 8...12),
                color: colors.randomElement()!
            )
            confettiPieces.append(piece)
            
            // Animate each piece with a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                animateConfetti(piece: piece, screenHeight: size.height, screenWidth: size.width)
            }
        }
    }
    
    private func animateConfetti(piece: ConfettiPiece, screenHeight: CGFloat, screenWidth: CGFloat) {
        guard let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) else { return }
        
        // Pop up first - much more varied heights
        withAnimation(.easeOut(duration: 0.8)) {
            confettiPieces[index].y = CGFloat.random(in: -200...screenHeight * 0.3)
        }
        
        // Then fall down slowly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 3.5)) {
                if let stillIndex = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                    confettiPieces[stillIndex].y = screenHeight + 50
                }
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
}

struct ConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
        }
    }
}

enum MilestoneType {
    case watchCount(Int, ContentType)  // Standard watching milestones
    case cleanSlate                     // Cleared entire watchlist
    case centuryClub                    // 100 total items combined
}

struct Milestone {
    let type: MilestoneType
    let count: Int
    let contentType: ContentType
    let title: String
    let emoji: String
    let message: String
    
    static func milestone(for count: Int, contentType: ContentType) -> Milestone? {
        if contentType == .movies {
            return movieMilestone(for: count)
        } else {
            return tvMilestone(for: count)
        }
    }
    
    static func cleanSlateMilestone() -> Milestone {
        return Milestone(
            type: .cleanSlate,
            count: 0,
            contentType: .movies, // Not really relevant for this type
            title: "Clean Slate",
            emoji: "✨",
            message: MilestoneMessages.cleanSlateMessage
        )
    }
    
    static func centuryClubMilestone() -> Milestone {
        return Milestone(
            type: .centuryClub,
            count: 100,
            contentType: .movies, // Not really relevant for this type
            title: "Century Club",
            emoji: "💯",
            message: MilestoneMessages.centuryClubMessage
        )
    }
    
    private static func movieMilestone(for count: Int) -> Milestone? {
        switch count {
        case 25:
            return Milestone(
                type: .watchCount(25, .movies),
                count: 25,
                contentType: .movies,
                title: "Popcorn Enthusiast",
                emoji: "🍿",
                message: MilestoneMessages.getMessage(for: 25, contentType: .movies)
            )
        case 50:
            return Milestone(
                type: .watchCount(50, .movies),
                count: 50,
                contentType: .movies,
                title: "Film Buff",
                emoji: "🎬",
                message: MilestoneMessages.getMessage(for: 50, contentType: .movies)
            )
        case 75:
            return Milestone(
                type: .watchCount(75, .movies),
                count: 75,
                contentType: .movies,
                title: "Cinema Connoisseur",
                emoji: "🎭",
                message: MilestoneMessages.getMessage(for: 75, contentType: .movies)
            )
        case 100:
            return Milestone(
                type: .watchCount(100, .movies),
                count: 100,
                contentType: .movies,
                title: "Movie Marathon Master",
                emoji: "🏆",
                message: MilestoneMessages.getMessage(for: 100, contentType: .movies)
            )
        case 150:
            return Milestone(
                type: .watchCount(150, .movies),
                count: 150,
                contentType: .movies,
                title: "Silver Screen Legend",
                emoji: "⭐",
                message: MilestoneMessages.getMessage(for: 150, contentType: .movies)
            )
        case 200:
            return Milestone(
                type: .watchCount(200, .movies),
                count: 200,
                contentType: .movies,
                title: "Diamond Cinephile",
                emoji: "💎",
                message: MilestoneMessages.getMessage(for: 200, contentType: .movies)
            )
        case 250:
            return Milestone(
                type: .watchCount(250, .movies),
                count: 250,
                contentType: .movies,
                title: "Hollywood Historian",
                emoji: "🎞️",
                message: MilestoneMessages.getMessage(for: 250, contentType: .movies)
            )
        case 300:
            return Milestone(
                type: .watchCount(300, .movies),
                count: 300,
                contentType: .movies,
                title: "Platinum Film Critic",
                emoji: "🏅",
                message: MilestoneMessages.getMessage(for: 300, contentType: .movies)
            )
        default:
            return nil
        }
    }
    
    private static func tvMilestone(for count: Int) -> Milestone? {
        switch count {
        case 25:
            return Milestone(
                type: .watchCount(25, .tv),
                count: 25,
                contentType: .tv,
                title: "Binge Beginner",
                emoji: "📺",
                message: MilestoneMessages.getMessage(for: 25, contentType: .tv)
            )
        case 50:
            return Milestone(
                type: .watchCount(50, .tv),
                count: 50,
                contentType: .tv,
                title: "Series Streamer",
                emoji: "🎯",
                message: MilestoneMessages.getMessage(for: 50, contentType: .tv)
            )
        case 75:
            return Milestone(
                type: .watchCount(75, .tv),
                count: 75,
                contentType: .tv,
                title: "Episode Expert",
                emoji: "📡",
                message: MilestoneMessages.getMessage(for: 75, contentType: .tv)
            )
        case 100:
            return Milestone(
                type: .watchCount(100, .tv),
                count: 100,
                contentType: .tv,
                title: "TV Titan",
                emoji: "📺",
                message: MilestoneMessages.getMessage(for: 100, contentType: .tv)
            )
        case 150:
            return Milestone(
                type: .watchCount(150, .tv),
                count: 150,
                contentType: .tv,
                title: "Season Specialist",
                emoji: "🌟",
                message: MilestoneMessages.getMessage(for: 150, contentType: .tv)
            )
        case 200:
            return Milestone(
                type: .watchCount(200, .tv),
                count: 200,
                contentType: .tv,
                title: "Streaming Legend",
                emoji: "💎",
                message: MilestoneMessages.getMessage(for: 200, contentType: .tv)
            )
        case 250:
            return Milestone(
                type: .watchCount(250, .tv),
                count: 250,
                contentType: .tv,
                title: "Broadcast Master",
                emoji: "🎪",
                message: MilestoneMessages.getMessage(for: 250, contentType: .tv)
            )
        case 300:
            return Milestone(
                type: .watchCount(300, .tv),
                count: 300,
                contentType: .tv,
                title: "Television Virtuoso",
                emoji: "👑",
                message: MilestoneMessages.getMessage(for: 300, contentType: .tv)
            )
        default:
            return nil
        }
    }
}

#Preview {
    MilestoneView(
        milestone: Milestone(
            type: .watchCount(25, .movies),
            count: 25,
            contentType: .movies,
            title: "Popcorn Enthusiast",
            emoji: "🍿",
            message: MilestoneMessages.getMessage(for: 25, contentType: .movies)
        ),
        onDismiss: {}
    )
}
