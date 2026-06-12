//
//  ContentView.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = MovieStore()
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    
    var body: some View {
        ZStack {
            // Background gradient
            AppGradient.background
                .ignoresSafeArea()
            
            if hasSeenWelcome {
                TabView {
                    BrowseView()
                        .tabItem {
                            Label("Browse", systemImage: "film")
                        }
                    
                    WatchlistView()
                        .tabItem {
                            Label("Watchlist", systemImage: "popcorn.fill")
                        }
                    
                    ArchiveView()
                        .tabItem {
                            Label("Watched", systemImage: "checkmark.circle.fill")
                        }
                }
                .environmentObject(store)
            } else {
                WelcomeView(hasSeenWelcome: $hasSeenWelcome)
            }
            
            // Milestone overlay
            if let milestone = store.currentMilestone {
                MilestoneView(milestone: milestone) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        store.dismissMilestone()
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: store.currentMilestone != nil)
                .zIndex(100)
            }
        }
    }
}

#Preview {
    ContentView()
}
