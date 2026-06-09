//
//  WatchProvidersView.swift
//  The Watchlist
//
//  Created by Matt Rose on 20/05/2026.
//

import SwiftUI

struct WatchProvidersView: View {
    let providers: [WatchProvider]
    let maxDisplay: Int = 3
    
    // Allowed UK provider names
    private let allowedProviders = [
        "Apple TV",
        "Apple TV Plus",
        "Amazon Prime Video",
        "Prime Video",
        "Netflix",
        "Disney Plus",
        "Disney+",
        "NOW",
        "Paramount Plus",
        "Hayu",
        "BritBox",
        "All 4",
        "BBC iPlayer",
        "ITV",
        "Channel 5",
        "HBO Max"
    ]
    
    // Excluded provider names (don't show these)
    private let excludedProviders = [
        "Sky Store",
        "Sky Go",
        "Sky Cinema",
        "Amazon Video",
        "Apple iTunes",
        "Google Play Movies",
        "YouTube",
        "Rakuten TV",
        "Chili",
        "Microsoft Store"
    ]
    
    // Filter to only show allowed UK providers and exclude specific ones
    private var filteredProviders: [WatchProvider] {
        var seenProviderTypes = Set<String>()
        var result: [WatchProvider] = []
        
        // Sort by display priority first to ensure we get the "best" provider
        let sortedProviders = providers.sorted { $0.displayPriority < $1.displayPriority }
        
        for provider in sortedProviders {
            // First check if it's explicitly excluded
            let isExcluded = excludedProviders.contains { excluded in
                provider.providerName.localizedCaseInsensitiveContains(excluded) ||
                excluded.localizedCaseInsensitiveContains(provider.providerName)
            }
            
            guard !isExcluded else { continue }
            
            // Then check if it's in the allowed list
            let isAllowed = allowedProviders.contains { allowed in
                provider.providerName.localizedCaseInsensitiveContains(allowed) ||
                allowed.localizedCaseInsensitiveContains(provider.providerName)
            }
            
            guard isAllowed else { continue }
            
            // Determine the provider type for deduplication
            var providerType: String? = nil
            
            if provider.providerName.localizedCaseInsensitiveContains("Apple") {
                providerType = "Apple"
            } else if provider.providerName.localizedCaseInsensitiveContains("Netflix") {
                providerType = "Netflix"
            } else if provider.providerName.localizedCaseInsensitiveContains("Prime") ||
                      provider.providerName.localizedCaseInsensitiveContains("Amazon") {
                providerType = "Prime"
            } else if provider.providerName.localizedCaseInsensitiveContains("Disney") {
                providerType = "Disney"
            } else if provider.providerName.localizedCaseInsensitiveContains("NOW") {
                providerType = "NOW"
            } else if provider.providerName.localizedCaseInsensitiveContains("Paramount") {
                providerType = "Paramount"
            } else if provider.providerName.localizedCaseInsensitiveContains("Hayu") {
                providerType = "Hayu"
            } else if provider.providerName.localizedCaseInsensitiveContains("BritBox") {
                providerType = "BritBox"
            } else if provider.providerName.localizedCaseInsensitiveContains("All 4") {
                providerType = "All4"
            } else if provider.providerName.localizedCaseInsensitiveContains("iPlayer") {
                providerType = "iPlayer"
            } else if provider.providerName.localizedCaseInsensitiveContains("ITV") {
                providerType = "ITV"
            } else if provider.providerName.localizedCaseInsensitiveContains("Channel 5") ||
                      provider.providerName.localizedCaseInsensitiveContains("My5") {
                providerType = "My5"
            } else if provider.providerName.localizedCaseInsensitiveContains("HBO") {
                providerType = "HBO"
            }
            
            // If we've identified a provider type, check if we've already seen it
            if let type = providerType {
                if seenProviderTypes.contains(type) {
                    continue // Skip this duplicate
                }
                seenProviderTypes.insert(type)
            }
            
            result.append(provider)
            
            // Stop when we reach maxDisplay
            if result.count >= maxDisplay {
                break
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "play.tv")
                    .foregroundStyle(AppTextColors.accent)
                    .imageScale(.medium)
                Text("Where to Watch")
                    .font(.headline)
                    .foregroundStyle(AppTextColors.primary)
            }
            
            if !filteredProviders.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 30, maximum: 42), spacing: 8)
                ], spacing: 8) {
                    ForEach(filteredProviders) { provider in
                        ProviderLogoView(provider: provider)
                    }
                }
            } else {
                // Cool message when no streaming options available
                HStack(spacing: 8) {
                    Image(systemName: "tv.slash")
                        .font(.subheadline)
                        .foregroundStyle(AppTextColors.tertiary)
                    
                    Text("Not available on streaming")
                        .font(.subheadline)
                        .foregroundStyle(AppTextColors.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

struct ProviderLogoView: View {
    let provider: WatchProvider
    @State private var loader: ImageLoader?
    
    // Clean up provider name
    var displayName: String {
        var name = provider.providerName
        
        // Simplify to standard names
        if name.localizedCaseInsensitiveContains("Apple TV Plus") || name.localizedCaseInsensitiveContains("Apple TV+") {
            return "Apple TV+"
        }
        
        if name.localizedCaseInsensitiveContains("Disney Plus") || name.localizedCaseInsensitiveContains("Disney+") {
            return "Disney+"
        }
        
        if name.localizedCaseInsensitiveContains("NOW") {
            return "NOW"
        }
        
        if name.localizedCaseInsensitiveContains("Netflix") {
            return "Netflix"
        }
        
        if name.localizedCaseInsensitiveContains("Prime Video") || name.localizedCaseInsensitiveContains("Amazon Prime") {
            return "Prime Video"
        }
        
        if name.localizedCaseInsensitiveContains("Paramount") {
            return "Paramount+"
        }
        
        if name.localizedCaseInsensitiveContains("iPlayer") {
            return "BBC iPlayer"
        }
        
        if name.localizedCaseInsensitiveContains("ITV") {
            return "ITVX"
        }
        
        if name.localizedCaseInsensitiveContains("Channel 5") || name.localizedCaseInsensitiveContains("My5") {
            return "My5"
        }
        
        if name.localizedCaseInsensitiveContains("All 4") {
            return "All 4"
        }
        
        return name
    }
    
    var body: some View {
        Group {
            if let loader = loader, let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else if let loader = loader, loader.hasError {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: "play.circle")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 30, height: 30)
                    .overlay {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(.white)
                    }
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        .onAppear {
            loadImage()
        }
        .onDisappear {
            loader?.cancel()
        }
    }
    
    private func loadImage() {
        guard let url = provider.logoURL else {
            print("⚠️ No logo URL for provider: \(provider.providerName)")
            print("   Logo path: \(provider.logoPath)")
            let newLoader = ImageLoader(url: URL(string: "about:blank")!)
            newLoader.hasError = true
            loader = newLoader
            return
        }
        
        print("🔍 Loading logo for \(provider.providerName)")
        print("   URL: \(url.absoluteString)")
        
        let newLoader = ImageLoader(url: url)
        loader = newLoader
        newLoader.load()
    }
}

#Preview {
    ZStack {
        AppGradient.background
            .ignoresSafeArea()
        
        WatchProvidersView(providers: [
            WatchProvider(
                logoPath: "/path/to/logo.jpg",
                providerId: 1,
                providerName: "Netflix",
                displayPriority: 1
            ),
            WatchProvider(
                logoPath: "/path/to/logo.jpg",
                providerId: 2,
                providerName: "Disney+",
                displayPriority: 2
            ),
            WatchProvider(
                logoPath: "/path/to/logo.jpg",
                providerId: 3,
                providerName: "Apple TV+",
                displayPriority: 3
            )
        ])
        .padding()
    }
}
