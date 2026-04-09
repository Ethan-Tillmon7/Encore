import Foundation
import Combine

class LineupStore: ObservableObject {

    @Published var allSets: [FestivalSet] = FestivalSet.mockSets

    @Published var selectedDay: FestivalDay? = nil
    @Published var selectedTier: MatchTier? = nil
    @Published var searchText: String = ""

    @Published var isSpotifyConnected: Bool = false

    var filteredSets: [FestivalSet] {
        allSets
            .filter { set in
                if let day = selectedDay { return set.day == day }
                return true
            }
            .filter { set in
                if let tier = selectedTier { return set.artist.matchTier == tier }
                return true
            }
            .filter { set in
                guard !searchText.isEmpty else { return true }
                return set.artist.name.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { a, b in
                let scoreA = a.artist.spotifyMatchScore ?? -1
                let scoreB = b.artist.spotifyMatchScore ?? -1
                if scoreA != scoreB { return scoreA > scoreB }
                return a.artist.name < b.artist.name
            }
    }

    func connectSpotify() {
        // TODO: Implement Spotify OAuth (Phase 1)
        isSpotifyConnected = true
    }

    func disconnectSpotify() {
        isSpotifyConnected = false
        allSets = allSets.map { set in
            var updated = set
            updated.artist.spotifyMatchScore = nil
            updated.artist.playCountLastSixMonths = nil
            updated.artist.matchTier = .unknown
            return updated
        }
    }
}
