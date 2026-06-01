//
//  AppGradient.swift
//  The Watchlist
//
//  Created by Matt Rose on 22/05/2026.
//

import SwiftUI

/// Centralized color and gradient definitions for the app
struct AppGradient {
    // MARK: - Hex Color Codes
    
    /// Bright gold color at the top of the gradient
    static let topBrightGold = Color(hex: "8FA89E")
    
    /// Gold color
    static let gold = Color(hex: "8FA89E")
    
    /// Mid red color
    static let midRed = Color(hex: "5C6B6B")
    
    /// Deep red color
    static let deepRed = Color(hex: "1a1a1a")
    
    /// Black color at the bottom of the gradient
    static let bottomBlack = Color(hex: "#0d0d0d")
    
    // MARK: - Gradient Definition
    
    /// Main app background gradient (bright gold → gold → mid red → deep red → black)
    static let background = LinearGradient(
        colors: [topBrightGold, gold, midRed, deepRed, bottomBlack],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Text Colors

/// Centralized text color definitions for the app
struct AppTextColors {
    // MARK: - Primary Text Colors
    
    /// Main text color (bright white for high contrast)
    static let primary = Color(hex: "FFFFFF")
    
    /// Secondary text color (softer white for less important text)
    static let secondary = Color(hex: "E0E0E0")
    
    /// Tertiary text color (muted gray for subtle text)
    static let tertiary = Color(hex: "A0A0A0")
    
    // MARK: - Accent Text Colors
    
    /// Gold accent text (matches gradient gold)
    static let accent = Color(hex: "E8C96A")
    
    /// Warning/alert text color
    static let warning = Color(hex: "FF6B6B")
    
    /// Success text color
    static let success = Color(hex: "4CAF50")
    
    // MARK: - Rating Text Color
    
    /// Star rating text color (yellow/gold)
    static let rating = Color(hex: "FFD700")
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: Hex color string (e.g., "8B5CF6" or "#8B5CF6")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
// MARK: - Preview

#Preview("Gradient & Colors") {
    ZStack {
        // Background gradient
        AppGradient.background
            .ignoresSafeArea()
        
        VStack(spacing: 30) {
            // Title
            Text("App Gradient & Colors")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(AppTextColors.primary)
            
            // Gradient color swatches
            VStack(alignment: .leading, spacing: 12) {
                Text("Gradient Colors:")
                    .font(.headline)
                    .foregroundStyle(AppTextColors.primary)
                
                HStack(spacing: 12) {
                    ColorSwatch(color: AppGradient.topBrightGold, name: "Bright Gold")
                    ColorSwatch(color: AppGradient.gold, name: "Gold")
                }
                HStack(spacing: 12) {
                    ColorSwatch(color: AppGradient.midRed, name: "Mid Red")
                    ColorSwatch(color: AppGradient.deepRed, name: "Deep Red")
                }
                HStack(spacing: 12) {
                    ColorSwatch(color: AppGradient.bottomBlack, name: "Black")
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
            
            // Text color examples
            VStack(alignment: .leading, spacing: 12) {
                Text("Text Colors:")
                    .font(.headline)
                    .foregroundStyle(AppTextColors.primary)
                
                Text("Primary Text - #FFFFFF")
                    .foregroundStyle(AppTextColors.primary)
                
                Text("Secondary Text - #E0E0E0")
                    .foregroundStyle(AppTextColors.secondary)
                
                Text("Tertiary Text - #A0A0A0")
                    .foregroundStyle(AppTextColors.tertiary)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(AppTextColors.rating)
                    Text("Rating - #FFD700")
                        .foregroundStyle(AppTextColors.rating)
                }
                
                Text("Accent - #E8C96A")
                    .foregroundStyle(AppTextColors.accent)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding()
    }
}

struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            Text(name)
                .font(.caption2)
                .foregroundStyle(AppTextColors.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

