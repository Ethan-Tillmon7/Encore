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
    static let mockCrew: Crew = {
        // Reference mockSets by index so IDs stay in sync:
        //  [2] Japanese Breakfast · Fri  [4] Hozier · Fri
        //  [5] LCD Soundsystem · Sat     [6] ODESZA · Sat
        //  [8] Wet Leg · Sun             [9] Ethel Cain · Sun
        let sets = FestivalSet.mockSets
        return Crew(
            id: UUID(),
            name: "Bonnaroo Squad",
            inviteCode: "BONROO",
            members: [
                CrewMember(id: UUID(), name: "You",    colorHex: "8B5CF6",
                           scheduledSetIDs: [],
                           isOnline: true,  lastSeenStage: nil),
                CrewMember(id: UUID(), name: "Colin",   colorHex: "10B981",
                           scheduledSetIDs: [sets[5].id, sets[2].id],  // LCD, Japanese Breakfast
                           isOnline: true,  lastSeenStage: "Which Stage · 4 min ago"),
                CrewMember(id: UUID(), name: "Stanley", colorHex: "F59E0B",
                           scheduledSetIDs: [sets[5].id, sets[9].id],  // LCD, Ethel Cain
                           isOnline: false, lastSeenStage: "This Tent · 12 min ago"),
                CrewMember(id: UUID(), name: "Paxton",  colorHex: "EF4444",
                           scheduledSetIDs: [sets[6].id, sets[8].id],  // ODESZA, Wet Leg
                           isOnline: true,  lastSeenStage: "Which Stage · 1 min ago"),
            ]
        )
    }()
}

extension Festival {
    private static func date(year: Int, month: Int, day: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        return Calendar.current.date(from: c) ?? Date()
    }

    // MARK: - Coachella 2025 lineup (Indio, CA)
    private static let coachellaLineup: [Artist] = [
        Artist(id: UUID(), name: "Lady Gaga",     genres: ["Pop", "Dance Pop", "Electronic"],      spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: [],                        stageName: "Coachella Stage", isHeadliner: true),
        Artist(id: UUID(), name: "Green Day",     genres: ["Rock", "Punk Rock", "Alternative"],    spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: [],                        stageName: "Coachella Stage", isHeadliner: true),
        Artist(id: UUID(), name: "Post Malone",   genres: ["Hip-Hop", "Trap", "Pop"],              spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: [],                        stageName: "Coachella Stage", isHeadliner: true),
        Artist(id: UUID(), name: "Charli XCX",    genres: ["Pop", "Synth-pop", "Dance Pop"],       spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Rina Sawayama", "MUNA"], stageName: "Outdoor Theatre", isHeadliner: false),
        Artist(id: UUID(), name: "Rüfüs Du Sol",  genres: ["Electronic", "House", "Indie Electronic"], spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Lane 8", "ODESZA"], stageName: "Sahara Stage",    isHeadliner: false),
        Artist(id: UUID(), name: "The Marías",    genres: ["Indie Pop", "Dream Pop", "R&B"],       spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Clairo", "Snail Mail"],  stageName: "Mojave Stage",    isHeadliner: false),
    ]

    // MARK: - Lollapalooza 2025 lineup (Chicago, IL)
    private static let lollaLineup: [Artist] = [
        Artist(id: UUID(), name: "SZA",           genres: ["R&B", "Soul", "Pop"],                  spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: [],                           stageName: "Grant Park Main Stage", isHeadliner: true),
        Artist(id: UUID(), name: "Tyler, the Creator", genres: ["Hip-Hop", "Rap", "Alternative"], spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: [],                           stageName: "Grant Park Main Stage", isHeadliner: true),
        Artist(id: UUID(), name: "Sabrina Carpenter", genres: ["Pop", "Dance Pop"],               spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Olivia Rodrigo", "Dua Lipa"], stageName: "Grant Park Main Stage", isHeadliner: true),
        Artist(id: UUID(), name: "Fisher",        genres: ["Electronic", "House", "Techno"],       spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Chris Lake", "Skrillex"],   stageName: "Perry Stage",           isHeadliner: false),
        Artist(id: UUID(), name: "Dominic Fike",  genres: ["Indie Pop", "R&B", "Alternative"],    spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Rex Orange County"],        stageName: "Lake Stage",            isHeadliner: false),
    ]

    // MARK: - Outside Lands 2025 lineup (San Francisco, CA)
    private static let outsideLandsLineup: [Artist] = [
        Artist(id: UUID(), name: "Chappell Roan",    genres: ["Pop", "Synth-pop", "Art Pop"],          spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Carly Rae Jepsen", "Robyn"], stageName: "Lands End Stage", isHeadliner: true),
        Artist(id: UUID(), name: "Vampire Weekend",  genres: ["Indie Rock", "Alternative", "Indie Pop"], spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["MGMT", "Rostam"],          stageName: "Sutro Stage",     isHeadliner: false),
        Artist(id: UUID(), name: "Tame Impala",      genres: ["Psychedelic Rock", "Indie Rock", "Electronic"], spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Unknown Mortal Orchestra"], stageName: "Lands End Stage", isHeadliner: true),
        Artist(id: UUID(), name: "Parcels",          genres: ["Funk", "Indie Pop", "Disco"],            spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Daft Punk", "Jungle"],      stageName: "Twin Peaks Stage", isHeadliner: false),
        Artist(id: UUID(), name: "Wet Leg",          genres: ["Indie Rock", "Post-Punk"],               spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Snail Mail", "Soccer Mommy"], stageName: "Panhandle Stage", isHeadliner: false),
    ]

    // MARK: - Electric Forest 2025 lineup (Rothbury, MI)
    private static let electricForestLineup: [Artist] = [
        Artist(id: UUID(), name: "Pretty Lights",   genres: ["Electronic", "Dubstep", "Drum & Bass"], spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Bassnectar", "Gramatik"],   stageName: "Forest Stage",   isHeadliner: true),
        Artist(id: UUID(), name: "Griz",            genres: ["Electronic", "Funk", "Soul"],            spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Lettuce", "STS9"],          stageName: "Ranch Arena",    isHeadliner: false),
        Artist(id: UUID(), name: "Twiddle",         genres: ["Jam Band", "Folk", "Rock"],              spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Phish", "Umphrey's McGee"], stageName: "Sherwood Court", isHeadliner: false),
        Artist(id: UUID(), name: "Vulfpeck",        genres: ["Funk", "Soul", "R&B"],                   spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Snarky Puppy", "Kaytranada"], stageName: "Ranch Arena",  isHeadliner: false),
        Artist(id: UUID(), name: "Goose",           genres: ["Jam Band", "Psychedelic Rock", "Electronic"], spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Phish", "Dead & Co."], stageName: "Forest Stage",  isHeadliner: true),
    ]

    // MARK: - Glastonbury 2025 lineup (Somerset, UK)
    private static let glastonburyLineup: [Artist] = [
        Artist(id: UUID(), name: "Coldplay",     genres: ["Rock", "Alternative", "Indie Rock"],      spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: [],                            stageName: "Pyramid Stage",    isHeadliner: true),
        Artist(id: UUID(), name: "Dua Lipa",     genres: ["Pop", "Dance Pop", "Electronic"],          spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: [],                            stageName: "Pyramid Stage",    isHeadliner: true),
        Artist(id: UUID(), name: "Burna Boy",    genres: ["Afrobeats", "Reggae", "Hip-Hop"],          spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Wizkid", "Davido"],           stageName: "West Holts Stage", isHeadliner: false),
        Artist(id: UUID(), name: "Four Tet",     genres: ["Electronic", "Ambient", "House"],          spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Caribou", "Floating Points"], stageName: "Park Stage",       isHeadliner: false),
        Artist(id: UUID(), name: "Nick Cave & the Bad Seeds", genres: ["Rock", "Post-Punk", "Art Rock"], spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["The National", "PJ Harvey"], stageName: "Pyramid Stage", isHeadliner: false),
    ]

    // MARK: - ACL 2025 lineup (Austin, TX)
    private static let aclLineup: [Artist] = [
        Artist(id: UUID(), name: "Billie Eilish",  genres: ["Pop", "Indie Pop", "Alternative"],      spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: [],                                stageName: "Samsung Stage",  isHeadliner: true),
        Artist(id: UUID(), name: "Sturgill Simpson", genres: ["Country", "Americana", "Rock"],       spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Waylon Jennings", "Kris Kristofferson"], stageName: "Google Stage", isHeadliner: false),
        Artist(id: UUID(), name: "Khruangbin",     genres: ["Funk", "Soul", "World"],                 spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Cymande", "Lee Fields"],          stageName: "Austin Ventures Stage", isHeadliner: false),
        Artist(id: UUID(), name: "Omar Apollo",    genres: ["R&B", "Indie Pop", "Soul"],              spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: ["Frank Ocean", "Daniel Caesar"],   stageName: "Honda Stage",    isHeadliner: false),
        Artist(id: UUID(), name: "Hozier",         genres: ["Folk", "Soul", "Alternative"],           spotifyMatchScore: nil, playCountLastSixMonths: nil, matchTier: .unknown, soundsLike: [],                                stageName: "Samsung Stage",  isHeadliner: true),
    ]

    // MARK: - All mock festivals

    static let mockFestivals: [Festival] = [
        // ── Bonnaroo (indices 0–2, preserved for JournalEntry mock refs) ──
        Festival(
            id: UUID(),
            name: "Bonnaroo 2023",
            slug: "bonnaroo-2023",
            location: "Manchester, TN",
            latitude: 35.4868, longitude: -86.0506,
            startDate: date(year: 2023, month: 6, day: 15),
            endDate:   date(year: 2023, month: 6, day: 18),
            status: .past,
            isCamping: true,
            genres: ["Rock", "Electronic", "Folk", "Hip-Hop"],
            imageColorHex: "FF6B35",
            lineup: [],
            sets: []
        ),
        Festival(
            id: UUID(),
            name: "Bonnaroo 2025",
            slug: "bonnaroo-2025",
            location: "Manchester, TN",
            latitude: 35.4868, longitude: -86.0506,
            startDate: date(year: 2025, month: 6, day: 12),
            endDate:   date(year: 2025, month: 6, day: 15),
            status: .active,
            isCamping: true,
            genres: ["Rock", "Electronic", "Folk", "Soul"],
            imageColorHex: "8B5CF6",
            lineup: Artist.mockLineup,
            sets: FestivalSet.mockSets
        ),
        Festival(
            id: UUID(),
            name: "Bonnaroo 2026",
            slug: "bonnaroo-2026",
            location: "Manchester, TN",
            latitude: 35.4868, longitude: -86.0506,
            startDate: date(year: 2026, month: 6, day: 11),
            endDate:   date(year: 2026, month: 6, day: 14),
            status: .upcoming,
            isCamping: true,
            genres: ["Rock", "Electronic", "Pop", "Indie"],
            imageColorHex: "10B981",
            lineup: [],
            sets: []
        ),

        // ── Additional festivals for discovery ──
        Festival(
            id: UUID(),
            name: "Coachella 2025",
            slug: "coachella-2025",
            location: "Indio, CA",
            latitude: 33.6823, longitude: -116.2381,
            startDate: date(year: 2025, month: 4, day: 11),
            endDate:   date(year: 2025, month: 4, day: 20),
            status: .past,
            isCamping: false,
            genres: ["Pop", "Electronic", "Rock", "Hip-Hop"],
            imageColorHex: "F59E0B",
            lineup: coachellaLineup,
            sets: []
        ),
        Festival(
            id: UUID(),
            name: "Lollapalooza 2025",
            slug: "lollapalooza-2025",
            location: "Chicago, IL",
            latitude: 41.8719, longitude: -87.6215,
            startDate: date(year: 2025, month: 8, day: 1),
            endDate:   date(year: 2025, month: 8, day: 4),
            status: .past,
            isCamping: false,
            genres: ["Rock", "Electronic", "Hip-Hop", "Pop"],
            imageColorHex: "EF4444",
            lineup: lollaLineup,
            sets: []
        ),
        Festival(
            id: UUID(),
            name: "Outside Lands 2025",
            slug: "outside-lands-2025",
            location: "San Francisco, CA",
            latitude: 37.7694, longitude: -122.5107,
            startDate: date(year: 2025, month: 8, day: 8),
            endDate:   date(year: 2025, month: 8, day: 10),
            status: .past,
            isCamping: false,
            genres: ["Indie Rock", "Electronic", "Pop", "Folk"],
            imageColorHex: "06B6D4",
            lineup: outsideLandsLineup,
            sets: []
        ),
        Festival(
            id: UUID(),
            name: "Electric Forest 2025",
            slug: "electric-forest-2025",
            location: "Rothbury, MI",
            latitude: 43.5039, longitude: -86.3443,
            startDate: date(year: 2025, month: 6, day: 26),
            endDate:   date(year: 2025, month: 6, day: 29),
            status: .past,
            isCamping: true,
            genres: ["Electronic", "Jam Band", "Folk", "Funk"],
            imageColorHex: "84CC16",
            lineup: electricForestLineup,
            sets: []
        ),
        Festival(
            id: UUID(),
            name: "Glastonbury 2025",
            slug: "glastonbury-2025",
            location: "Pilton, Somerset, UK",
            latitude: 51.1527, longitude: -2.7213,
            startDate: date(year: 2025, month: 6, day: 25),
            endDate:   date(year: 2025, month: 6, day: 29),
            status: .past,
            isCamping: true,
            genres: ["Rock", "Pop", "Electronic", "World"],
            imageColorHex: "A78BFA",
            lineup: glastonburyLineup,
            sets: []
        ),
        Festival(
            id: UUID(),
            name: "ACL Fest 2025",
            slug: "acl-fest-2025",
            location: "Austin, TX",
            latitude: 30.2500, longitude: -97.7469,
            startDate: date(year: 2025, month: 10, day: 3),
            endDate:   date(year: 2025, month: 10, day: 12),
            status: .upcoming,
            isCamping: false,
            genres: ["Rock", "Country", "Folk", "R&B", "Electronic"],
            imageColorHex: "FB923C",
            lineup: aclLineup,
            sets: []
        ),
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
            wouldSeeAgain: .yes,
            artistName: "Hozier",
            festivalName: "Bonnaroo 2023"
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
            wouldSeeAgain: .yes,
            artistName: "Japanese Breakfast",
            festivalName: "Bonnaroo 2023"
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
            wouldSeeAgain: .yes,
            artistName: "LCD Soundsystem",
            festivalName: "Bonnaroo 2023"
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
