// Encore/Models/GenreTaxonomy.swift
import Foundation

// MARK: - GenreCategory

/// One top-level genre bucket and the sub-genres that belong to it.
/// Used by FestivalDiscoveryStore for hierarchical filter logic
/// and by the genre picker UI to render a two-level selection tree.
struct GenreCategory: Identifiable, Hashable {
    let id: String          // stable key, same as lowercased name
    let name: String        // display name: "Rock", "Electronic", …
    let icon: String        // SF Symbol name
    let subcategories: [String]
}

// MARK: - GenreTaxonomy

enum GenreTaxonomy {

    static let categories: [GenreCategory] = [
        GenreCategory(
            id: "rock",
            name: "Rock",
            icon: "guitars.fill",
            subcategories: [
                "Alternative", "Indie Rock", "Heavy Metal", "Post-Punk",
                "Hard Rock", "Classic Rock", "Shoegaze", "Grunge",
                "Math Rock", "Psychedelic Rock", "Garage Rock"
            ]
        ),
        GenreCategory(
            id: "electronic",
            name: "Electronic",
            icon: "waveform",
            subcategories: [
                "EDM", "House", "Techno", "Dubstep", "UK Garage",
                "Drum & Bass", "Ambient", "Synthwave", "Indie Electronic",
                "Dance-punk", "Trance", "Bass Music", "Future Bass"
            ]
        ),
        GenreCategory(
            id: "hip-hop",
            name: "Hip-Hop",
            icon: "mic.fill",
            subcategories: [
                "Rap", "Trap", "R&B", "Boom Bap", "Conscious Rap",
                "Drill", "Neo-Soul", "Cloud Rap"
            ]
        ),
        GenreCategory(
            id: "folk",
            name: "Folk & Americana",
            icon: "music.note",
            subcategories: [
                "Country", "Bluegrass", "Singer-Songwriter", "Indie Folk",
                "Celtic", "Southern Gothic", "Appalachian"
            ]
        ),
        GenreCategory(
            id: "pop",
            name: "Pop",
            icon: "sparkles",
            subcategories: [
                "Indie Pop", "Synth-pop", "Art Pop", "K-Pop",
                "Dance Pop", "Dream Pop", "Chamber Pop"
            ]
        ),
        GenreCategory(
            id: "soul",
            name: "Soul & Funk",
            icon: "heart.fill",
            subcategories: [
                "Soul", "Funk", "Gospel", "Disco", "Motown"
            ]
        ),
        GenreCategory(
            id: "jazz",
            name: "Jazz & Blues",
            icon: "music.quarternote.3",
            subcategories: [
                "Jazz", "Blues", "Soul Jazz", "Bebop",
                "Fusion", "Desert Blues"
            ]
        ),
        GenreCategory(
            id: "world",
            name: "World",
            icon: "globe.americas.fill",
            subcategories: [
                "Afrobeats", "Latin", "Reggae", "Tuareg Rock",
                "African", "Caribbean", "Cumbia"
            ]
        ),
        GenreCategory(
            id: "experimental",
            name: "Experimental",
            icon: "waveform.path",
            subcategories: [
                "Noise", "Avant-garde", "Art Rock", "Experimental Rock",
                "Ambient", "Electroacoustic"
            ]
        ),
        GenreCategory(
            id: "jam",
            name: "Jam & Bluegrass",
            icon: "banjo",
            subcategories: [
                "Jam Band", "Progressive Bluegrass", "Newgrass", "Psychedelic Jam"
            ]
        ),
    ]

    // MARK: - Helpers

    /// Returns the parent GenreCategory for any genre string (top-level or sub).
    static func category(for genre: String) -> GenreCategory? {
        let lower = genre.lowercased()
        return categories.first { cat in
            cat.name.lowercased() == lower ||
            cat.subcategories.contains { $0.lowercased() == lower }
        }
    }

    /// All top-level names: ["Rock", "Electronic", …]
    static var topLevelNames: [String] {
        categories.map(\.name)
    }

    /// Every genre string in the taxonomy (top-level + all subs), deduplicated.
    static var allGenreStrings: [String] {
        var seen = Set<String>()
        return categories.flatMap { [$0.name] + $0.subcategories }
            .filter { seen.insert($0).inserted }
    }

    /// Whether `genre` belongs to (or is) the given top-level category name.
    static func genre(_ genre: String, isUnder categoryName: String) -> Bool {
        guard let cat = categories.first(where: { $0.name.lowercased() == categoryName.lowercased() }) else {
            return false
        }
        let lower = genre.lowercased()
        return cat.name.lowercased() == lower ||
               cat.subcategories.contains { $0.lowercased() == lower }
    }
}
