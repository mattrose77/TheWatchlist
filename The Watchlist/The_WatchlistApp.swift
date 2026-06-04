//
//  The_WatchlistApp.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import SwiftUI

@main
struct The_WatchlistApp: App {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    
    var body: some Scene {
        WindowGroup {
            if hasSeenWelcome {
                ContentView()
            } else {
                WelcomeView(hasSeenWelcome: $hasSeenWelcome)
            }
        }
    }
}
