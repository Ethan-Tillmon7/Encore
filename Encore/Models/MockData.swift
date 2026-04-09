import Foundation

// MARK: - Mock Data
// Realistic Bonnaroo-style lineup for development & SwiftUI previews.

extension Artist {
    static let mockLineup: [Artist] = [
        Artist(id: UUID(), name: "LCD Soundsystem", genres: ["Electronic", "Dance-punk"], spotifyMatchScore: 96, playCountLastSixMonths: 142, matchTier: .mustSee, soundsLike: [], stageName: "Which Stage", isHeadliner: true),
        Artist(id: UUID(), name: "Hozier", genres: ["Folk", "Soul", "Alternative"], spotifyMatchScore: 91, playCountLastSixMonths: 88, matchTier: .mustSee, soundsLike: [], stageName: "What Stage", isHeadliner: true),
        Artist(id: UUID(), name: "ODESZA", genres: ["Electronic", "Indie electronic"], spotifyMatchScore: 87, playCountLastSixMonths: 63, matchTier: .mustSee, soundsLike: [], stageName: "Which Stage", isHeadliner: false),
        Artist(id: UUID(), name: "Japanese Breakfast", genres: ["Indie rock", "Art pop"], spotifyMatchScore: 84, playCountLastSixMonths: 47, matchTier: .worthChecking, soundsLike: [], stageName: "This Tent", isHeadliner: false),
        Artist(id: UUID(), name: "Maggie Rogers", genres: ["Pop", "Indie folk"], spotifyMatchScore: 79, playCountLastSixMonths: 55, matchTier: .worthChecking, soundsLike: [], stageName: "What Stage", isHeadliner: false),
        Artist(id: UUID(), name: "Jungle", genres: ["Funk", "Soul", "Electronic"], spotifyMatchScore: 72, playCountLastSixMonths: 31, matchTier: .worthChecking, soundsLike: [], stageName: "Which Stage", isHeadliner: false),
        Artist(id: UUID(), name: "Sylvan Esso", genres: ["Electronic", "Indie pop"], spotifyMatchScore: 65, playCountLastSixMonths: 22, matchTier: .explore, soundsLike: ["Bon Iver", "Purity Ring"], stageName: "That Tent", isHeadliner: false),
        Artist(id: UUID(), name: "MUNA", genres: ["Synth-pop", "Indie pop"], spotifyMatchScore: 58, playCountLastSixMonths: 11, matchTier: .explore, soundsLike: ["Chvrches", "Robyn"], stageName: "This Tent", isHeadliner: false),
        Artist(id: UUID(), name: "Wet Leg", genres: ["Indie rock", "Post-punk"], spotifyMatchScore: 52, playCountLastSixMonths: 8, matchTier: .explore, soundsLike: ["Snail Mail", "Soccer Mommy"], stageName: "Other Stage", isHeadliner: false),
        Artist(id: UUID(), name: "Ethel Cain", genres: ["Art pop", "Southern gothic"], spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Lana Del Rey", "Weyes Blood"], stageName: "That Tent", isHeadliner: false),
        Artist(id: UUID(), name: "Yves Tumor", genres: ["Experimental rock", "Art pop"], spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["FKA twigs", "Prince"], stageName: "This Tent", isHeadliner: false),
        Artist(id: UUID(), name: "Mdou Moctar", genres: ["Tuareg rock", "Desert blues"], spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Tinariwen", "Omara Moctar"], stageName: "Other Stage", isHeadliner: false),
    ]
}

extension FestivalSet {
    // Convenience: build a date on a given day at hour:minute
    private static func setTime(dayOffset: Int, hour: Int, minute: Int = 0) -> Date {
        var comps = DateComponents()
        comps.year = 2025; comps.month = 6; comps.day = 12 + dayOffset
        comps.hour = hour; comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }

    static let mockSets: [FestivalSet] = {
        let lineup = Artist.mockLineup
        return [
            // Thursday
            FestivalSet(id: UUID(), artist: lineup[6], stageName: "That Tent",   day: .thursday, startTime: setTime(dayOffset: 0, hour: 21),     endTime: setTime(dayOffset: 0, hour: 22, minute: 15)),
            FestivalSet(id: UUID(), artist: lineup[7], stageName: "This Tent",   day: .thursday, startTime: setTime(dayOffset: 0, hour: 22),     endTime: setTime(dayOffset: 0, hour: 23)),
            // Friday
            FestivalSet(id: UUID(), artist: lineup[3], stageName: "This Tent",   day: .friday,   startTime: setTime(dayOffset: 1, hour: 20),     endTime: setTime(dayOffset: 1, hour: 21, minute: 15)),
            FestivalSet(id: UUID(), artist: lineup[4], stageName: "What Stage",  day: .friday,   startTime: setTime(dayOffset: 1, hour: 21),     endTime: setTime(dayOffset: 1, hour: 22, minute: 30)),
            FestivalSet(id: UUID(), artist: lineup[1], stageName: "What Stage",  day: .friday,   startTime: setTime(dayOffset: 1, hour: 23),     endTime: setTime(dayOffset: 2, hour: 0, minute: 30)),
            // Saturday — LCD and ODESZA conflict!
            FestivalSet(id: UUID(), artist: lineup[0], stageName: "Which Stage", day: .saturday, startTime: setTime(dayOffset: 2, hour: 22),     endTime: setTime(dayOffset: 3, hour: 0)),
            FestivalSet(id: UUID(), artist: lineup[2], stageName: "Which Stage", day: .saturday, startTime: setTime(dayOffset: 2, hour: 22, minute: 30), endTime: setTime(dayOffset: 3, hour: 0, minute: 30)),
            FestivalSet(id: UUID(), artist: lineup[5], stageName: "Which Stage", day: .saturday, startTime: setTime(dayOffset: 2, hour: 20),     endTime: setTime(dayOffset: 2, hour: 21, minute: 30)),
            // Sunday
            FestivalSet(id: UUID(), artist: lineup[8], stageName: "Other Stage", day: .sunday,   startTime: setTime(dayOffset: 3, hour: 19),     endTime: setTime(dayOffset: 3, hour: 20)),
            FestivalSet(id: UUID(), artist: lineup[9], stageName: "That Tent",   day: .sunday,   startTime: setTime(dayOffset: 3, hour: 21),     endTime: setTime(dayOffset: 3, hour: 22, minute: 15)),
        ]
    }()
}

extension Crew {
    static let mockCrew = Crew(
        id: UUID(),
        name: "Bonnaroo Squad",
        inviteCode: "BONROO",
        members: [
            CrewMember(id: UUID(), name: "You", colorHex: "8B5CF6", scheduledSetIDs: [], isOnline: true, lastSeenStage: nil),
            CrewMember(id: UUID(), name: "Alex", colorHex: "10B981", scheduledSetIDs: [], isOnline: true, lastSeenStage: "What Stage · 4 min ago"),
            CrewMember(id: UUID(), name: "Jordan", colorHex: "F59E0B", scheduledSetIDs: [], isOnline: false, lastSeenStage: "This Tent · 12 min ago"),
            CrewMember(id: UUID(), name: "Casey", colorHex: "EF4444", scheduledSetIDs: [], isOnline: true, lastSeenStage: "Which Stage · 1 min ago"),
        ]
    )
}
