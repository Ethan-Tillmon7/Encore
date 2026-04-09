import Foundation
import SwiftUI

// MARK: - Match Tier

enum MatchTier: String, CaseIterable, Codable, Identifiable {
    case mustSee       = "Must-see"
    case worthChecking = "Worth checking out"
    case explore       = "Explore"
    case unknown       = "Unknown"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .mustSee:       return .appCTA
        case .worthChecking: return .appAccent
        case .explore:       return .appTeal
        case .unknown:       return .appTextMuted
        }
    }

    // Used for badge/pill backgrounds in detail and conflict views
    var backgroundColor: Color { color.opacity(0.18) }

    // Used for timetable grid set blocks (same value, distinct semantic purpose)
    var blockFill: Color   { color.opacity(0.18) }
    var blockBorder: Color { color.opacity(0.32) }
}

// MARK: - Artist

struct Artist: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var genres: [String]
    var spotifyMatchScore: Int?    // 0–100, nil = Spotify not connected
    var playCountLastSixMonths: Int?
    var matchTier: MatchTier
    var soundsLike: [String]       // "sounds like X" tags for unknowns
    var stageName: String          // primary stage assignment
    var isHeadliner: Bool

    // Convenience: formatted Spotify string
    var spotifyLabel: String? {
        guard let score = spotifyMatchScore else { return nil }
        if let plays = playCountLastSixMonths {
            return "\(score)% match · \(plays) plays last 6 mo"
        }
        return "\(score)% match"
    }
}
