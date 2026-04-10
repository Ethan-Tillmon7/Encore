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

extension Festival {
    private static func date(year: Int, month: Int, day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        return Calendar.current.date(from: c) ?? Date()
    }

    static let mockFestivals: [Festival] = [
        Festival(
            id: UUID(),
            name: "Bonnaroo 2023",
            location: "Manchester, TN",
            startDate: date(year: 2023, month: 6, day: 15),
            endDate:   date(year: 2023, month: 6, day: 18),
            status: .past,
            genres: ["Rock", "Electronic", "Folk", "Hip-Hop"],
            imageColorHex: "FF6B35",
            lineup: [],
            sets: []
        ),
        Festival(
            id: UUID(),
            name: "Bonnaroo 2025",
            location: "Manchester, TN",
            startDate: date(year: 2025, month: 6, day: 12),
            endDate:   date(year: 2025, month: 6, day: 15),
            status: .active,
            genres: ["Rock", "Electronic", "Folk", "Soul"],
            imageColorHex: "8B5CF6",
            lineup: Artist.mockLineup,
            sets: FestivalSet.mockSets
        ),
        Festival(
            id: UUID(),
            name: "Bonnaroo 2026",
            location: "Manchester, TN",
            startDate: date(year: 2026, month: 6, day: 11),
            endDate:   date(year: 2026, month: 6, day: 14),
            status: .upcoming,
            genres: ["Rock", "Electronic", "Pop", "Indie"],
            imageColorHex: "10B981",
            lineup: [],
            sets: []
        )
    ]
}

extension JournalEntry {
    private static func date2023(month: Int, day: Int, hour: Int = 20) -> Date {
        var c = DateComponents()
        c.year = 2023; c.month = month; c.day = day; c.hour = hour
        return Calendar.current.date(from: c) ?? Date()
    }

    static let mockEntries: [JournalEntry] = [
        JournalEntry(
            id: UUID(),
            artistID: Artist.mockLineup[1].id,   // Hozier
            festivalID: Festival.mockFestivals[0].id,
            setID: UUID(),
            dateAttended: date2023(month: 6, day: 16, hour: 22),
            rating: 5,
            notes: "Absolutely transcendent. The crowd was electric from the first note of Work Song. Cherry Wine as an encore had people in tears.",
            highlights: ["Best energy", "Emotional moment", "Perfect setlist"],
            wouldSeeAgain: .yes
        ),
        JournalEntry(
            id: UUID(),
            artistID: Artist.mockLineup[3].id,   // Japanese Breakfast
            festivalID: Festival.mockFestivals[0].id,
            setID: UUID(),
            dateAttended: date2023(month: 6, day: 17, hour: 20),
            rating: 4,
            notes: "Michelle Zauner was in peak form. Loved the Soft Sounds era material. Crowd was smaller but super attentive.",
            highlights: ["Great crowd", "Discovered a new fave"],
            wouldSeeAgain: .yes
        ),
        JournalEntry(
            id: UUID(),
            artistID: Artist.mockLineup[0].id,   // LCD Soundsystem
            festivalID: Festival.mockFestivals[0].id,
            setID: UUID(),
            dateAttended: date2023(month: 6, day: 18, hour: 23),
            rating: 5,
            notes: "Dance Yrself Clean opening was a religious experience. Set went for almost 2 hours. Daft Punk Is Playing At My House had the whole field losing it.",
            highlights: ["Best energy", "Surprise guest", "Perfect setlist"],
            wouldSeeAgain: .yes
        )
    ]
}

extension PackingItem {
    static let bonnarooDefaults: [PackingItem] = [
        PackingItem(id: UUID(), name: "Sunscreen", isPacked: false, category: "Gear"),
        PackingItem(id: UUID(), name: "Rain poncho", isPacked: false, category: "Clothing"),
        PackingItem(id: UUID(), name: "Portable charger", isPacked: false, category: "Gear"),
        PackingItem(id: UUID(), name: "Reusable water bottle", isPacked: false, category: "Gear"),
        PackingItem(id: UUID(), name: "Earplugs", isPacked: false, category: "Gear"),
        PackingItem(id: UUID(), name: "Comfortable shoes", isPacked: false, category: "Clothing"),
        PackingItem(id: UUID(), name: "Cash", isPacked: false, category: "Docs"),
        PackingItem(id: UUID(), name: "ID + ticket", isPacked: false, category: "Docs"),
        PackingItem(id: UUID(), name: "Tent + sleeping bag", isPacked: false, category: "Gear"),
        PackingItem(id: UUID(), name: "Headlamp", isPacked: false, category: "Gear"),
    ]
}
