//
//  ContentView.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = MovieStore()
    
    var body: some View {
        ZStack {
            // Background gradient
            AppGradient.background
                .ignoresSafeArea()
            
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
                        Label("Archive", systemImage: "checkmark.circle.fill")
                    }
            }
            .environmentObject(store)
        }
    }
}

#Preview {
    ContentView()
}
