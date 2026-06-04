//
//  WelcomeView.swift
//  The Watchlist
//
//  Created by Matt Rose on 01/06/2026.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var hasSeenWelcome: Bool
    @State private var animateIcon = false
    @State private var animateText = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Background gradient
            AppGradient.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon
                Image(systemName: "popcorn.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, AppGradient.gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateIcon ? 1.0 : 0.5)
                    .opacity(animateIcon ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateIcon)
                
                // Welcome Text
                VStack(spacing: 16) {
                    Text("Welcome to")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTextColors.secondary)
                    
                    Text("The Watchlist")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTextColors.primary)
                    
                    Text("Your personal cinema companion.\nDiscover movies, track what you want to watch, and celebrate what you've seen.")
                        .font(.body)
                        .foregroundStyle(AppTextColors.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }
                .opacity(animateText ? 1.0 : 0)
                .offset(y: animateText ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateText)
                
                Spacer()
                
                // Get Started Button
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        hasSeenWelcome = true
                    }
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppGradient.gold, AppGradient.midRed],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppGradient.gold.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 32)
                .opacity(animateButton ? 1.0 : 0)
                .offset(y: animateButton ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateButton)
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            animateIcon = true
            animateText = true
            animateButton = true
        }
    }
}

#Preview("Welcome Screen") {
    WelcomeView(hasSeenWelcome: .constant(false))
}
#Preview("After Button Tap") {
    WelcomeView(hasSeenWelcome: .constant(true))
}

