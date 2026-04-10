// Encore/Stores/JournalStore.swift
import Foundation
import Combine

class JournalStore: ObservableObject {
    @Published var entries: [JournalEntry] = []

    func entries(for artistID: UUID) -> [JournalEntry] {
        entries.filter { $0.artistID == artistID }
    }

    func entries(for festivalID: UUID) -> [JournalEntry] {
        entries.filter { $0.festivalID == festivalID }
    }

    func upsert(_ entry: JournalEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
        } else {
            entries.append(entry)
        }
    }

    func delete(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    func hasSeenArtist(_ artistID: UUID) -> Bool {
        entries.contains { $0.artistID == artistID }
    }

    func averageRating(for artistID: UUID) -> Double? {
        let rated = entries(for: artistID).compactMap(\.rating)
        guard !rated.isEmpty else { return nil }
        return Double(rated.reduce(0, +)) / Double(rated.count)
    }
}
