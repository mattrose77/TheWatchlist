//
//  MilestoneMessages.swift
//  The Watchlist
//
//  Created by Matt Rose on 10/06/2026.
//

import Foundation

struct MilestoneMessages {
    
    // MARK: - Movie Milestone Messages
    
    static let movieMessages: [Int: [String]] = [
        25: [
            "Just getting started! 🍿",
            "You're gonna need a bigger watchlist!",
            "May the films be with you!"
        ],
        50: [
            "Here's looking at you, kid! 👀",
            "You had me at movie 50!",
            "Houston, we have a film buff!"
        ],
        75: [
            "I'll have what they're having! 🎬",
            "You're gonna need a bigger couch!",
            "To infinity and beyond... 75 down!"
        ],
        100: [
            "I love the smell of popcorn in the morning! 💯",
            "You can't handle the truth... you've watched 100!",
            "Elementary, my dear Watson, you're a legend!"
        ],
        150: [
            "You talking to me? Yeah, you! 150 movies! 🌟",
            "I'm king of the world... of movies!",
            "There's no place like your watchlist!"
        ],
        200: [
            "Why so serious? You've hit 200! 💎",
            "I'm going to make you an offer... 200 more!",
            "After all this time? Always watching!"
        ],
        250: [
            "You're gonna need a bigger trophy! 🏆",
            "I see dead people... wait, no, just your archive!",
            "Life is like a box of chocolates... 250 movies!"
        ],
        300: [
            "This is Sparta! No, this is 300 movies! 👑",
            "I'll be back... to watch even more!",
            "You've got the power! 300 films strong!"
        ]
    ]
    
    // MARK: - TV Show Milestone Messages
    
    static let tvMessages: [Int: [String]] = [
        25: [
            "Winter is coming... more shows! ❄️",
            "That's what she watched... 25 shows!",
            "How you doin' with 25 shows? 📺"
        ],
        50: [
            "D'oh! 50 shows already! 🍩",
            "Pivot! Pivot! To show number 50!",
            "I am the one who watches... 50 shows!"
        ],
        75: [
            "That's all folks... wait, no! 75 down! 🎯",
            "Bazinga! 75 shows conquered!",
            "Title of your sex tape: '75 Shows Watched!'"
        ],
        100: [
            "We were on a break... from reality! 100 shows! ☕",
            "Did I do that? Watch 100 shows?!",
            "How rude! You've watched 100 already!"
        ],
        150: [
            "Treat yo self to 150 shows! 🌟",
            "That's what I'm talking about! 150!",
            "Legendary! 150 shows in the books!"
        ],
        200: [
            "What is this, a crossover episode? 200 shows! 🎪",
            "I've made a huge mistake... watching only 200!",
            "Cool. Cool cool cool. 200 shows!"
        ],
        250: [
            "Clear eyes, full hearts, can't lose! 250 shows! 💫",
            "Save the cheerleader, watch 250 shows!",
            "The truth is out there... you've seen 250!"
        ],
        300: [
            "This is the way... to 300 shows! 🛡️",
            "Winter came, you watched 300 shows!",
            "I drink and I watch shows. 300 of them!"
        ]
    ]
    
    // MARK: - Get Random Message
    
    static func getMessage(for count: Int, contentType: ContentType) -> String {
        let messages: [String]?
        
        if contentType == .movies {
            messages = movieMessages[count]
        } else {
            messages = tvMessages[count]
        }
        
        // Return random message or fallback
        return messages?.randomElement() ?? "Congratulations on reaching \(count)!"
    }
}
