// Encore/Views/Journal/ArtistHistoryView.swift
import SwiftUI

struct ArtistHistoryView: View {

    let artist: Artist

    @EnvironmentObject var journalStore: JournalStore

    private var entries: [JournalEntry] {
        journalStore.entries(forArtist: artist.id)
            .sorted { $0.dateAttended > $1.dateAttended }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Artist header
                artistHeader

                // Stats row
                if !entries.isEmpty {
                    statsRow
                }

                Divider()

                // Entry list
                if entries.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: DS.Spacing.cardGap) {
                        ForEach(entries) { entry in
                            entryRowWithFestival(entry: entry)
                        }
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
            .padding(.vertical, DS.Spacing.cardGap)
        }
        .background(Color.appBackground)
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var artistHeader: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sectionGap) {
            Text(artist.matchTier.rawValue.uppercased())
                .font(DS.Font.label)
                .foregroundColor(artist.matchTier.color)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(artist.matchTier.backgroundColor)
                .clipShape(Capsule())
            Text(artist.genres.joined(separator: "  ·  "))
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(entries.count)", label: "times seen")
            Divider().frame(height: 32)
            if let avg = journalStore.averageRating(for: artist.id) {
                statCell(value: String(format: "★ %.1f", avg), label: "avg rating")
            } else {
                statCell(value: "★ —", label: "avg rating")
            }
        }
        .padding(.vertical, 8)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DS.Font.stat)
                .foregroundColor(.appCTA)
            Text(label)
                .font(DS.Font.caps)
                .foregroundColor(.appTextMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func entryRowWithFestival(entry: JournalEntry) -> some View {
        let festivalName = Festival.mockFestivals.first(where: { $0.id == entry.festivalID })?.name ?? "Unknown Festival"
        return VStack(alignment: .leading, spacing: 0) {
            Text(festivalName)
                .font(DS.Font.caps)
                .foregroundColor(.appTextMuted)
                .tracking(0.6)
                .padding(.bottom, 4)
            JournalEntryRowView(entry: entry)
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.sectionGap) {
            Image(systemName: "book.closed")
                .font(.system(size: 32))
                .foregroundColor(Color.appTextMuted.opacity(0.3))
            Text("No entries for \(artist.name) yet.")
                .font(DS.Font.listItem)
                .foregroundColor(.appTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    let journal = JournalStore()
    journal.entries = JournalEntry.mockEntries
    return NavigationStack {
        ArtistHistoryView(artist: Artist.mockLineup[0])
            .environmentObject(journal)
    }
    .preferredColorScheme(.dark)
}
